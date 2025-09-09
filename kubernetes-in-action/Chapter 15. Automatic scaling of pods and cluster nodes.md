# Chapter 15. Automatic scaling of pods and cluster nodes

### **This chapter covers**

- Configuring automatic horizontal scaling of pods based on CPU utilization
- Configuring automatic horizontal scaling of pods based on custom metrics
- Understanding why vertical scaling of pods isn’t possible yet
- Understanding automatic horizontal scaling of cluster nodes

Applications running in pods can be scaled out manually by increasing the `replicas` field in the ReplicationController, ReplicaSet, Deployment, or other scalable resource. Pods can also be scaled vertically by increasing their container’s resource requests and limits (though this can currently only be done at pod creation time, not while the pod is running). Although manual scaling is okay for times when you can anticipate load spikes in advance or when the load changes gradually over longer periods of time, requiring manual intervention to handle sudden, unpredictable traffic increases isn’t ideal.

Luckily, Kubernetes can monitor your pods and scale them up automatically as soon as it detects an increase in the CPU usage or some other metric. If running on a cloud infrastructure, it can even spin up additional nodes if the existing ones can’t accept any more pods. This chapter will explain how to get Kubernetes to do both pod and node autoscaling.

The autoscaling feature in Kubernetes was completely rewritten between the 1.6 and the 1.7 version, so be aware you may find outdated information on this subject online.

## 15.1. Horizontal pod autoscaling

Horizontal pod autoscaling is the automatic scaling of the number of pod replicas managed by a controller. It’s performed by the Horizontal controller, which is enabled and configured by creating a HorizontalPodAutoscaler (HPA) resource. The controller periodically checks pod metrics, calculates the number of replicas required to meet the target metric value configured in the HorizontalPodAutoscaler resource, and adjusts the `replicas` field on the target resource (Deployment, ReplicaSet, Replication-Controller, or StatefulSet).

### 15.1.1. Understanding the autoscaling process

The autoscaling process can be split into three steps:

- Obtain metrics of all the pods managed by the scaled resource object.
- Calculate the number of pods required to bring the metrics to (or close to) the specified target value.
- Update the `replicas` field of the scaled resource.

Let’s examine all three steps next.

##### Obtaining pod metrics

The Autoscaler doesn’t perform the gathering of the pod metrics itself. It gets the metrics from a different source. As we saw in the previous chapter, pod and node metrics are collected by an agent called *cAdvisor*, which runs in the Kubelet on each node, and then aggregated by the cluster-wide component called Heapster. The horizontal pod autoscaler controller gets the metrics of all the pods by querying Heapster through REST calls. The flow of metrics data is shown in [figure 15.1](/book/kubernetes-in-action/chapter-15/ch15fig01) (although all the connections are initiated in the opposite direction).

![Figure 15.1. Flow of metrics from the pod(s) to the HorizontalPodAutoscaler(s)](https://drek4537l1klr.cloudfront.net/luksa/Figures/15fig01_alt.jpg)

This implies that Heapster must be running in the cluster for autoscaling to work. If you’re using Minikube and were following along in the previous chapter, Heapster should already be enabled in your cluster. If not, make sure to enable the Heapster add-on before trying out any autoscaling examples.

Although you don’t need to query Heapster directly, if you’re interested in doing so, you’ll find both the Heapster Pod and the Service it’s exposed through in the `kube-system` namespace.

---

##### **A look at changes related to how the Autoscaler obtains metrics**

Prior to Kubernetes version 1.6, the HorizontalPodAutoscaler obtained the metrics from Heapster directly. In version 1.8, the Autoscaler can get the metrics through an aggregated version of the resource metrics API by starting the Controller Manager with the `--horizontal-pod-autoscaler-use-rest-clients=true flag`. From version 1.9, this behavior will be enabled by default.

The core API server will not expose the metrics itself. From version 1.7, Kubernetes allows registering multiple API servers and making them appear as a single API server. This allows it to expose metrics through one of those underlying API servers. We’ll explain API server aggregation in the last chapter.

Selecting what metrics collector to use in their clusters will be up to cluster administrators. A simple translation layer is usually required to expose the metrics in the appropriate API paths and in the appropriate format.

---

##### Calculating the required number of pods

Once the Autoscaler has metrics for all the pods belonging to the resource the Autoscaler is scaling (the Deployment, ReplicaSet, ReplicationController, or StatefulSet resource), it can use those metrics to figure out the required number of replicas. It needs to find the number that will bring the average value of the metric across all those replicas as close to the configured target value as possible. The input to this calculation is a set of pod metrics (possibly multiple metrics per pod) and the output is a single integer (the number of pod replicas).

When the Autoscaler is configured to consider only a single metric, calculating the required replica count is simple. All it takes is summing up the metrics values of all the pods, dividing that by the target value set on the HorizontalPodAutoscaler resource, and then rounding it up to the next-larger integer. The actual calculation is a bit more involved than this, because it also makes sure the Autoscaler doesn’t thrash around when the metric value is unstable and changes rapidly.

When autoscaling is based on multiple pod metrics (for example, both CPU usage and Queries-Per-Second [QPS]), the calculation isn’t that much more complicated. The Autoscaler calculates the replica count for each metric individually and then takes the highest value (for example, if four pods are required to achieve the target CPU usage, and three pods are required to achieve the target QPS, the Autoscaler will scale to four pods). [Figure 15.2](/book/kubernetes-in-action/chapter-15/ch15fig02) shows this example.

![Figure 15.2. Calculating the number of replicas from two metrics](https://drek4537l1klr.cloudfront.net/luksa/Figures/15fig02_alt.jpg)

##### Updating the desired replica count on the scaled resource

The final step of an autoscaling operation is updating the desired replica count field on the scaled resource object (a ReplicaSet, for example) and then letting the Replica-Set controller take care of spinning up additional pods or deleting excess ones.

The Autoscaler controller modifies the `replicas` field of the scaled resource through the Scale sub-resource. It enables the Autoscaler to do its work without knowing any details of the resource it’s scaling, except for what’s exposed through the Scale sub-resource (see [figure 15.3](/book/kubernetes-in-action/chapter-15/ch15fig03)).

![Figure 15.3. The Horizontal Pod Autoscaler modifies only on the Scale sub-resource.](https://drek4537l1klr.cloudfront.net/luksa/Figures/15fig03_alt.jpg)

This allows the Autoscaler to operate on any scalable resource, as long as the API server exposes the Scale sub-resource for it. Currently, it’s exposed for

- Deployments
- ReplicaSets
- ReplicationControllers
- StatefulSets

These are currently the only objects you can attach an Autoscaler to.

##### Understanding the whole autoscaling process

You now understand the three steps involved in autoscaling, so let’s visualize all the components involved in the autoscaling process. They’re shown in [figure 15.4](/book/kubernetes-in-action/chapter-15/ch15fig04).

![Figure 15.4. How the autoscaler obtains metrics and rescales the target deployment](https://drek4537l1klr.cloudfront.net/luksa/Figures/15fig04_alt.jpg)

The arrows leading from the pods to the cAdvisors, which continue on to Heapster and finally to the Horizontal Pod Autoscaler, indicate the direction of the flow of metrics data. It’s important to be aware that each component gets the metrics from the other components periodically (that is, cAdvisor gets the metrics from the pods in a continuous loop; the same is also true for Heapster and for the HPA controller). The end effect is that it takes quite a while for the metrics data to be propagated and a rescaling action to be performed. It isn’t immediate. Keep this in mind when you observe the Autoscaler in action next.

### 15.1.2. Scaling based on CPU utilization

Perhaps the most important metric you’ll want to base autoscaling on is the amount of CPU consumed by the processes running inside your pods. Imagine having a few pods providing a service. When their CPU usage reaches 100% it’s obvious they can’t cope with the demand anymore and need to be scaled either up (vertical scaling—increasing the amount of CPU the pods can use) or out (horizontal scaling—increasing the number of pods). Because we’re talking about the horizontal pod autoscaler here, we’re only focusing on scaling out (increasing the number of pods). By doing that, the average CPU usage should come down.

Because CPU usage is usually unstable, it makes sense to scale out even before the CPU is completely swamped—perhaps when the average CPU load across the pods reaches or exceeds 80%. But 80% of *what*, exactly?

---

##### Tip

Always set the target CPU usage well below 100% (and definitely never above 90%) to leave enough room for handling sudden load spikes.

---

As you may remember from the previous chapter, the process running inside a container is guaranteed the amount of CPU requested through the resource requests specified for the container. But at times when no other processes need CPU, the process may use all the available CPU on the node. When someone says a pod is consuming 80% of the CPU, it’s not clear if they mean 80% of the node’s CPU, 80% of the pod’s guaranteed CPU (the resource request), or 80% of the hard limit configured for the pod through resource limits.

As far as the Autoscaler is concerned, only the pod’s guaranteed CPU amount (the CPU requests) is important when determining the CPU utilization of a pod. The Autoscaler compares the pod’s actual CPU consumption and its CPU requests, which means the pods you’re autoscaling need to have CPU requests set (either directly or indirectly through a LimitRange object) for the Autoscaler to determine the CPU utilization percentage.

##### Creating a HorizontalPodAutoscaler based on CPU usage

Let’s see how to create a HorizontalPodAutoscaler now and configure it to scale pods based on their CPU utilization. You’ll create a Deployment similar to the one in [chapter 9](/book/kubernetes-in-action/chapter-9/ch09), but as we’ve discussed, you’ll need to make sure the pods created by the Deployment all have the CPU resource requests specified in order to make autoscaling possible. You’ll have to add a CPU resource request to the Deployment’s pod template, as shown in the following listing.

##### Listing 15.1. Deployment with CPU requests set: deployment.yaml

```yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: kubia
spec:
  replicas: 3
  template:
    metadata:
      name: kubia
      labels:
        app: kubia
    spec:
      containers:
      - image: luksa/kubia:v1
        name: nodejs
        resources:
          requests:
            cpu: 100m
```

This is a regular Deployment object—it doesn’t use autoscaling yet. It will run three instances of the `kubia` NodeJS app, with each instance requesting 100 millicores of CPU.

After creating the Deployment, to enable horizontal autoscaling of its pods, you need to create a HorizontalPodAutoscaler (HPA) object and point it to the Deployment. You could prepare and post the YAML manifest for the HPA, but an easier way exists—using the `kubectl autoscale` command:

```bash
$ kubectl autoscale deployment kubia --cpu-percent=30 --min=1 --max=5
deployment "kubia" autoscaled
```

This creates the HPA object for you and sets the Deployment called `kubia` as the scaling target. You’re setting the target CPU utilization of the pods to 30% and specifying the minimum and maximum number of replicas. The Autoscaler will constantly keep adjusting the number of replicas to keep their CPU utilization around 30%, but it will never scale down to less than one or scale up to more than five replicas.

---

##### Tip

Always make sure to autoscale Deployments instead of the underlying ReplicaSets. This way, you ensure the desired replica count is preserved across application updates (remember that a Deployment creates a new ReplicaSet for each version). The same rule applies to manual scaling, as well.

---

Let’s look at the definition of the HorizontalPodAutoscaler resource to gain a better understanding of it. It’s shown in the following listing.

##### Listing 15.2. A HorizontalPodAutoscaler YAML definition

```bash
$ kubectl get hpa.v2beta1.autoscaling kubia -o yaml
apiVersion: autoscaling/v2beta1            #1
kind: HorizontalPodAutoscaler              #1
metadata:
  name: kubia                              #2
  ...
spec:
  maxReplicas: 5                           #3
  metrics:                                 #4
  - resource:                              #4
      name: cpu                            #4
      targetAverageUtilization: 30         #4
    type: Resource                         #4
  minReplicas: 1                           #3
  scaleTargetRef:                          #5

    apiVersion: extensions/v1beta1         #5

    kind: Deployment                       #5

    name: kubia                            #5

status:
  currentMetrics: []                       #6

  currentReplicas: 3                       #6

  desiredReplicas: 0                       #6
```

---

##### Note

Multiple versions of HPA resources exist: the new `autoscaling/v2beta1` and the old `autoscaling/v1`. You’re requesting the new version here.

---

##### Seeing the first automatic rescale event

It takes a while for cAdvisor to get the CPU metrics and for Heapster to collect them before the Autoscaler can take action. During that time, if you display the HPA resource with `kubectl get`, the `TARGETS` column will show `<unknown>`:

```bash
$ kubectl get hpa
NAME      REFERENCE          TARGETS           MINPODS   MAXPODS   REPLICAS
kubia     Deployment/kubia   <unknown> / 30%   1         5         0
```

Because you’re running three pods that are currently receiving no requests, which means their CPU usage should be close to zero, you should expect the Autoscaler to scale them down to a single pod, because even with a single pod, the CPU utilization will still be below the 30% target.

And sure enough, the autoscaler does exactly that. It soon scales the Deployment down to a single replica:

```bash
$ kubectl get deployment
NAME      DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
kubia     1         1         1            1           23m
```

Remember, the autoscaler only adjusts the desired replica count on the Deployment. The Deployment controller then takes care of updating the desired replica count on the ReplicaSet object, which then causes the ReplicaSet controller to delete two excess pods, leaving one pod running.

You can use `kubectl describe` to see more information on the HorizontalPod-Autoscaler and the operation of the underlying controller, as the following listing shows.

##### Listing 15.3. Inspecting a HorizontalPodAutoscaler with `kubectl describe`

```bash
$ kubectl describe hpa
Name:                             kubia
Namespace:                        default
Labels:                           <none>
Annotations:                      <none>
CreationTimestamp:                Sat, 03 Jun 2017 12:59:57 +0200
Reference:                        Deployment/kubia
Metrics:                          ( current / target )
  resource cpu on pods
  (as a percentage of request):   0% (0) / 30%
Min replicas:                     1
Max replicas:                     5
Events:
From                        Reason              Message
----                        ------              ---
horizontal-pod-autoscaler   SuccessfulRescale   New size: 1; reason: All
                                                metrics below target
```

---

##### Note

The output has been modified to make it more readable.

---

Turn your focus to the table of events at the bottom of the listing. You see the horizontal pod autoscaler has successfully rescaled to one replica, because all metrics were below target.

##### Triggering a scale-up

You’ve already witnessed your first automatic rescale event (a scale-down). Now, you’ll start sending requests to your pod, thereby increasing its CPU usage, and you should see the autoscaler detect this and start up additional pods.

You’ll need to expose the pods through a Service, so you can hit all of them through a single URL. You may remember that the easiest way to do that is with `kubectl expose`:

```bash
$ kubectl expose deployment kubia --port=80 --target-port=8080
service "kubia" exposed
```

Before you start hitting your pod(s) with requests, you may want to run the following command in a separate terminal to keep an eye on what’s happening with the HorizontalPodAutoscaler and the Deployment, as shown in the following listing.

##### Listing 15.4. Watching multiple resources in parallel

```bash
$ watch -n 1 kubectl get hpa,deployment
Every 1.0s: kubectl get hpa,deployment

NAME        REFERENCE          TARGETS    MINPODS   MAXPODS   REPLICAS  AGE
hpa/kubia   Deployment/kubia   0% / 30%   1         5         1         45m

NAME           DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deploy/kubia   1         1         1            1           56m
```

---

##### Tip

List multiple resource types with `kubectl get` by delimiting them with a comma.

---

If you’re using OSX, you’ll have to replace the `watch` command with a loop, manually run `kubectl get` periodically, or use `kubectl`’s `--watch` option. But although a plain `kubectl get` can show multiple types of resources at once, that’s not the case when using the aforementioned `--watch` option, so you’ll need to use two terminals if you want to watch both the HPA and the Deployment objects.

Keep an eye on the state of those two objects while you run a load-generating pod. You’ll run the following command in another terminal:

```bash
$ kubectl run -it --rm --restart=Never loadgenerator --image=busybox
➥  -- sh -c "while true; do wget -O - -q http://kubia.default; done"
```

This will run a pod which repeatedly hits the `kubia` Service. You’ve seen the `-it` option a few times when running the `kubectl exec` command. As you can see, it can also be used with `kubectl run`. It allows you to attach the console to the process, which will not only show you the process’ output directly, but will also terminate the process as soon as you press CTRL+C. The `--rm` option causes the pod to be deleted afterward, and the `--restart=Never` option causes `kubectl run` to create an unmanaged pod directly instead of through a Deployment object, which you don’t need. This combination of options is useful for running commands inside the cluster without having to piggyback on an existing pod. It not only behaves the same as if you were running the command locally, it even cleans up everything when the command terminates.

##### Seeing the Autoscaler scale up the deployment

As the load-generator pod runs, you’ll see it initially hitting the single pod. As before, it takes time for the metrics to be updated, but when they are, you’ll see the autoscaler increase the number of replicas. In my case, the pod’s CPU utilization initially jumped to 108%, which caused the autoscaler to increase the number of pods to four. The utilization on the individual pods then decreased to 74% and then stabilized at around 26%.

---

##### Note

If the CPU load in your case doesn’t exceed 30%, try running additional load-generators.

---

Again, you can inspect autoscaler events with `kubectl describe` to see what the autoscaler has done (only the most important information is shown in the following listing).

##### Listing 15.5. Events of a HorizontalPodAutoscaler

```
From    Reason              Message
----    ------              -------
h-p-a   SuccessfulRescale   New size: 1; reason: All metrics below target
h-p-a   SuccessfulRescale   New size: 4; reason: cpu resource utilization
                            (percentage of request) above target
```

Does it strike you as odd that the initial average CPU utilization in my case, when I only had one pod, was 108%, which is more than 100%? Remember, a container’s CPU utilization is the container’s actual CPU usage divided by its requested CPU. The requested CPU defines the minimum, not maximum amount of CPU available to the container, so a container may consume more than the requested CPU, bringing the percentage over 100.

Before we go on, let’s do a little math and see how the autoscaler concluded that four replicas are needed. Initially, there was one replica handling requests and its CPU usage spiked to 108%. Dividing 108 by 30 (the target CPU utilization percentage) gives 3.6, which the autoscaler then rounded up to 4. If you divide 108 by 4, you get 27%. If the autoscaler scales up to four pods, their average CPU utilization is expected to be somewhere in the neighborhood of 27%, which is close to the target value of 30% and almost exactly what the observed CPU utilization was.

##### Understanding the maximum rate of scaling

In my case, the CPU usage shot up to 108%, but in general, the initial CPU usage could spike even higher. Even if the initial average CPU utilization was higher (say 150%), requiring five replicas to achieve the 30% target, the autoscaler would still only scale up to four pods in the first step, because it has a limit on how many replicas can be added in a single scale-up operation. The autoscaler will at most double the number of replicas in a single operation, if more than two current replicas exist. If only one or two exist, it will scale up to a maximum of four replicas in a single step.

Additionally, it has a limit on how soon a subsequent autoscale operation can occur after the previous one. Currently, a scale-up will occur only if no rescaling event occurred in the last three minutes. A scale-down event is performed even less frequently—every five minutes. Keep this in mind so you don’t wonder why the autoscaler refuses to perform a rescale operation even if the metrics clearly show that it should.

##### Modifying the target metric value on an existing HPA object

To wrap up this section, let’s do one last exercise. Maybe your initial CPU utilization target of 30% was a bit too low, so increase it to 60%. You do this by editing the HPA resource with the `kubectl edit` command. When the text editor opens, change the `targetAverageUtilization` field to `60`, as shown in the following listing.

##### Listing 15.6. Increasing the target CPU utilization by editing the HPA resource

```
...
spec:
  maxReplicas: 5
  metrics:
  - resource:
      name: cpu
      targetAverageUtilization: 60     #1
    type: Resource
...
```

As with most other resources, after you modify the resource, your changes will be detected by the autoscaler controller and acted upon. You could also delete the resource and recreate it with different target values, because by deleting the HPA resource, you only disable autoscaling of the target resource (a Deployment in this case) and leave it at the scale it is at that time. The automatic scaling will resume after you create a new HPA resource for the Deployment.

### 15.1.3. Scaling based on memory consumption

You’ve seen how easily the horizontal Autoscaler can be configured to keep CPU utilization at the target level. But what about autoscaling based on the pods’ memory usage?

Memory-based autoscaling is much more problematic than CPU-based autoscaling. The main reason is because after scaling up, the old pods would somehow need to be forced to release memory. This needs to be done by the app itself—it can’t be done by the system. All the system could do is kill and restart the app, hoping it would use less memory than before. But if the app then uses the same amount as before, the Autoscaler would scale it up again. And again, and again, until it reaches the maximum number of pods configured on the HPA resource. Obviously, this isn’t what anyone wants. Memory-based autoscaling was introduced in Kubernetes version 1.8, and is configured exactly like CPU-based autoscaling. Exploring it is left up to the reader.

### 15.1.4. Scaling based on other and custom metrics

You’ve seen how easy it is to scale pods based on their CPU usage. Initially, this was the only autoscaling option that was usable in practice. To have the autoscaler use custom, app-defined metrics to drive its autoscaling decisions was fairly complicated. The initial design of the autoscaler didn’t make it easy to move beyond simple CPU-based scaling. This prompted the Kubernetes Autoscaling Special Interest Group (SIG) to redesign the autoscaler completely.

If you’re interested in learning how complicated it was to use the initial autoscaler with custom metrics, I invite you to read my blog post entitled “Kubernetes autoscaling based on custom metrics without using a host port,” which you’ll find online at [http://medium.com/@marko.luksa](http://medium.com/@marko.luksa). You’ll learn about all the other problems I encountered when trying to set up autoscaling based on custom metrics. Luckily, newer versions of Kubernetes don’t have those problems. I’ll cover the subject in a new blog post.

Instead of going through a complete example here, let’s quickly go over how to configure the autoscaler to use different metrics sources. We’ll start by examining how we defined what metric to use in our previous example. The following listing shows how your previous HPA object was configured to use the CPU usage metric.

##### Listing 15.7. HorizontalPodAutoscaler definition for CPU-based autoscaling

```
...
spec:
  maxReplicas: 5
  metrics:
  - type: Resource                   #1
    resource:
      name: cpu                      #2
      targetAverageUtilization: 30   #3
...
```

As you can see, the `metrics` field allows you to define more than one metric to use. In the listing, you’re using a single metric. Each entry defines the `type` of metric—in this case, a `Resource` metric. You have three types of metrics you can use in an HPA object:

- `Resource`
- `Pods`
- `Object`

##### Understanding the Resource metric type

The `Resource` type makes the autoscaler base its autoscaling decisions on a resource metric, like the ones specified in a container’s resource requests. We’ve already seen how to do that, so let’s focus on the other two types.

##### Understanding the Pods metric type

The `Pods` type is used to refer to any other (including custom) metric related to the pod directly. An example of such a metric could be the already mentioned Queries-Per-Second (QPS) or the number of messages in a message broker’s queue (when the message broker is running as a pod). To configure the autoscaler to use the pod’s QPS metric, the HPA object would need to include the entry shown in the following listing under its `metrics` field.

##### Listing 15.8. Referring to a custom pod metric in the HPA

```
...
spec:
  metrics:
  - type: Pods                    #1
    resource:
      metricName: qps             #2
      targetAverageValue: 100     #3
...
```

The example in the listing configures the autoscaler to keep the average QPS of all the pods managed by the ReplicaSet (or other) controller targeted by this HPA resource at `100`.

##### Understanding the Object metric type

The `Object` metric type is used when you want to make the autoscaler scale pods based on a metric that doesn’t pertain directly to those pods. For example, you may want to scale pods according to a metric of another cluster object, such as an Ingress object. The metric could be QPS as in [listing 15.8](/book/kubernetes-in-action/chapter-15/ch15ex08), the average request latency, or something else completely.

Unlike in the previous case, where the autoscaler needed to obtain the metric for all targeted pods and then use the average of those values, when you use an `Object` metric type, the autoscaler obtains a single metric from the single object. In the HPA definition, you need to specify the target object and the target value. The following listing shows an example.

##### Listing 15.9. Referring to a metric of a different object in the HPA

```yaml
...
spec:
  metrics:
  - type: Object
    resource:
      metricName: latencyMillis
      target:
        apiVersion: extensions/v1beta1
        kind: Ingress
        name: frontend
      targetValue: 20
  scaleTargetRef:

    apiVersion: extensions/v1beta1

    kind: Deployment

    name: kubia

...
```

In this example, the HPA is configured to use the `latencyMillis` metric of the `frontend` Ingress object. The target value for the metric is `20`. The horizontal pod autoscaler will monitor the Ingress’ metric and if it rises too far above the target value, the autoscaler will scale the `kubia` Deployment resource.

### 15.1.5. Determining which metrics are appropriate for autoscaling

You need to understand that not all metrics are appropriate for use as the basis of autoscaling. As mentioned previously, the pods’ containers’ memory consumption isn’t a good metric for autoscaling. The autoscaler won’t function properly if increasing the number of replicas doesn’t result in a linear decrease of the average value of the observed metric (or at least close to linear).

For example, if you have only a single pod instance and the value of the metric is X and the autoscaler scales up to two replicas, the metric needs to fall to somewhere close to X/2. An example of such a custom metric is Queries per Second (QPS), which in the case of web applications reports the number of requests the application is receiving per second. Increasing the number of replicas will always result in a proportionate decrease of QPS, because a greater number of pods will be handling the same total number of requests.

Before you decide to base the autoscaler on your app’s own custom metric, be sure to think about how its value will behave when the number of pods increases or decreases.

### 15.1.6. Scaling down to zero replicas

The horizontal pod autoscaler currently doesn’t allow setting the `minReplicas` field to 0, so the autoscaler will never scale down to zero, even if the pods aren’t doing anything. Allowing the number of pods to be scaled down to zero can dramatically increase the utilization of your hardware. When you run services that get requests only once every few hours or even days, it doesn’t make sense to have them running all the time, eating up resources that could be used by other pods. But you still want to have those services available immediately when a client request comes in.

This is known as idling and un-idling. It allows pods that provide a certain service to be scaled down to zero. When a new request comes in, the request is blocked until the pod is brought up and then the request is finally forwarded to the pod.

Kubernetes currently doesn’t provide this feature yet, but it will eventually. Check the documentation to see if idling has been implemented yet.

## 15.2. Vertical pod autoscaling

Horizontal scaling is great, but not every application can be scaled horizontally. For such applications, the only option is to scale them vertically—give them more CPU and/or memory. Because a node usually has more resources than a single pod requests, it should almost always be possible to scale a pod vertically, right?

Because a pod’s resource requests are configured through fields in the pod manifest, vertically scaling a pod would be performed by changing those fields. I say “would” because it’s currently not possible to change either resource requests or limits of existing pods. Before I started writing the book (well over a year ago), I was sure that by the time I wrote this chapter, Kubernetes would already support proper vertical pod autoscaling, so I included it in my proposal for the table of contents. Sadly, what seems like a lifetime later, vertical pod autoscaling is still not available yet.

### 15.2.1. Automatically configuring resource requests

An experimental feature sets the CPU and memory requests on newly created pods, if their containers don’t have them set explicitly. The feature is provided by an Admission Control plugin called InitialResources. When a new pod without resource requests is created, the plugin looks at historical resource usage data of the pod’s containers (per the underlying container image and tag) and sets the requests accordingly.

You can deploy pods without specifying resource requests and rely on Kubernetes to eventually figure out what each container’s resource needs are. Effectively, Kubernetes is vertically scaling the pod. For example, if a container keeps running out of memory, the next time a pod with that container image is created, its resource request for memory will be set higher automatically.

### 15.2.2. Modifying resource requests while a pod is running

Eventually, the same mechanism will be used to modify an existing pod’s resource requests, which means it will vertically scale the pod while it’s running. As I’m writing this, a new vertical pod autoscaling proposal is being finalized. Please refer to the Kubernetes documentation to find out whether vertical pod autoscaling is already implemented or not.

## 15.3. Horizontal scaling of cluster nodes

The Horizontal Pod Autoscaler creates additional pod instances when the need for them arises. But what about when all your nodes are at capacity and can’t run any more pods? Obviously, this problem isn’t limited only to when new pod instances are created by the Autoscaler. Even when creating pods manually, you may encounter the problem where none of the nodes can accept the new pods, because the node’s resources are used up by existing pods.

In that case, you’d need to delete several of those existing pods, scale them down vertically, or add additional nodes to your cluster. If your Kubernetes cluster is running on premises, you’d need to physically add a new machine and make it part of the Kubernetes cluster. But if your cluster is running on a cloud infrastructure, adding additional nodes is usually a matter of a few clicks or an API call to the cloud infrastructure. This can be done automatically, right?

Kubernetes includes the feature to automatically request additional nodes from the cloud provider as soon as it detects additional nodes are needed. This is performed by the Cluster Autoscaler.

### 15.3.1. Introducing the Cluster Autoscaler

The Cluster Autoscaler takes care of automatically provisioning additional nodes when it notices a pod that can’t be scheduled to existing nodes because of a lack of resources on those nodes. It also de-provisions nodes when they’re underutilized for longer periods of time.

##### Requesting additional nodes from the cloud infrastructure

A new node will be provisioned if, after a new pod is created, the Scheduler can’t schedule it to any of the existing nodes. The Cluster Autoscaler looks out for such pods and asks the cloud provider to start up an additional node. But before doing that, it checks whether the new node can even accommodate the pod. After all, if that’s not the case, it makes no sense to start up such a node.

Cloud providers usually group nodes into groups (or pools) of same-sized nodes (or nodes having the same features). The Cluster Autoscaler thus can’t simply say “Give me an additional node.” It needs to also specify the node type.

The Cluster Autoscaler does this by examining the available node groups to see if at least one node type would be able to fit the unscheduled pod. If exactly one such node group exists, the Autoscaler can increase the size of the node group to have the cloud provider add another node to the group. If more than one option is available, the Autoscaler must pick the best one. The exact meaning of “best” will obviously need to be configurable. In the worst case, it selects a random one. A simple overview of how the cluster Autoscaler reacts to an unschedulable pod is shown in [figure 15.5](/book/kubernetes-in-action/chapter-15/ch15fig05).

![Figure 15.5. The Cluster Autoscaler scales up when it finds a pod that can’t be scheduled to existing nodes.](https://drek4537l1klr.cloudfront.net/luksa/Figures/15fig05_alt.jpg)

When the new node starts up, the Kubelet on that node contacts the API server and registers the node by creating a Node resource. From then on, the node is part of the Kubernetes cluster and pods can be scheduled to it.

Simple, right? What about scaling down?

##### Relinquishing nodes

The Cluster Autoscaler also needs to scale down the number of nodes when they aren’t being utilized enough. The Autoscaler does this by monitoring the requested CPU and memory on all the nodes. If the CPU and memory requests of all the pods running on a given node are below 50%, the node is considered unnecessary.

That’s not the only determining factor in deciding whether to bring a node down. The Autoscaler also checks to see if any system pods are running (only) on that node (apart from those that are run on every node, because they’re deployed by a DaemonSet, for example). If a system pod is running on a node, the node won’t be relinquished. The same is also true if an unmanaged pod or a pod with local storage is running on the node, because that would cause disruption to the service the pod is providing. In other words, a node will only be returned to the cloud provider if the Cluster Autoscaler knows the pods running on the node will be rescheduled to other nodes.

When a node is selected to be shut down, the node is first marked as unschedulable and then all the pods running on the node are evicted. Because all those pods belong to ReplicaSets or other controllers, their replacements are created and scheduled to the remaining nodes (that’s why the node that’s being shut down is first marked as unschedulable).

---

##### **Manually cordoning and draining nodes**

A node can also be marked as unschedulable and drained manually. Without going into specifics, this is done with the following `kubectl` commands:

- `kubectl cordon <node>` marks the node as unschedulable (but doesn’t do anything with pods running on that node).
- `kubectl drain <node>` marks the node as unschedulable and then evicts all the pods from the node.

In both cases, no new pods are scheduled to the node until you uncordon it again with `kubectl uncordon <node>`.

---

### 15.3.2. Enabling the Cluster Autoscaler

Cluster autoscaling is currently available on

- Google Kubernetes Engine (GKE)
- Google Compute Engine (GCE)
- Amazon Web Services (AWS)
- Microsoft Azure

How you start the Autoscaler depends on where your Kubernetes cluster is running. For your `kubia` cluster running on GKE, you can enable the Cluster Autoscaler like this:

```bash
$ gcloud container clusters update kubia --enable-autoscaling \
  --min-nodes=3 --max-nodes=5
```

If your cluster is running on GCE, you need to set three environment variables before running `kube-up.sh`:

- `KUBE_ENABLE_CLUSTER_AUTOSCALER=true`
- `KUBE_AUTOSCALER_MIN_NODES=3`
- `KUBE_AUTOSCALER_MAX_NODES=5`

Refer to the Cluster Autoscaler GitHub repo at [https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler) for information on how to enable it on other platforms.

---

##### Note

The Cluster Autoscaler publishes its status to the `cluster-autoscaler-status` ConfigMap in the `kube-system` namespace.

---

### 15.3.3. Limiting service disruption during cluster scale-down

When a node fails unexpectedly, nothing you can do will prevent its pods from becoming unavailable. But when a node is shut down voluntarily, either by the Cluster Autoscaler or by a human operator, you can make sure the operation doesn’t disrupt the service provided by the pods running on that node through an additional feature.

Certain services require that a minimum number of pods always keeps running; this is especially true for quorum-based clustered applications. For this reason, Kubernetes provides a way of specifying the minimum number of pods that need to keep running while performing these types of operations. This is done by creating a PodDisruptionBudget resource.

Even though the name of the resource sounds complex, it’s one of the simplest Kubernetes resources available. It contains only a pod label selector and a number specifying the minimum number of pods that must always be available or, starting from Kubernetes version 1.7, the maximum number of pods that can be unavailable. We’ll look at what a PodDisruptionBudget (PDB) resource manifest looks like, but instead of creating it from a YAML file, you’ll create it with `kubectl create pod-disruptionbudget` and then obtain and examine the YAML later.

If you want to ensure three instances of your `kubia` pod are always running (they have the label `app=kubia`), create the PodDisruptionBudget resource like this:

```bash
$ kubectl create pdb kubia-pdb --selector=app=kubia --min-available=3
poddisruptionbudget "kubia-pdb" created
```

Simple, right? Now, retrieve the PDB’s YAML. It’s shown in the next listing.

##### Listing 15.10. A PodDisruptionBudget definition

```bash
$ kubectl get pdb kubia-pdb -o yaml
apiVersion: policy/v1beta1
kind: PodDisruptionBudget
metadata:
  name: kubia-pdb
spec:
  minAvailable: 3          #1
  selector:                #2
    matchLabels:           #2
      app: kubia           #2
status:
  ...
```

You can also use a percentage instead of an absolute number in the `minAvailable` field. For example, you could state that 60% of all pods with the `app=kubia` label need to be running at all times.

---

##### Note

Starting with Kubernetes 1.7, the PodDisruptionBudget resource also supports the `maxUnavailable` field, which you can use instead of `min-Available` if you want to block evictions when more than that many pods are unavailable.

---

We don’t have much more to say about this resource. As long as it exists, both the Cluster Autoscaler and the `kubectl drain` command will adhere to it and will never evict a pod with the `app=kubia` label if that would bring the number of such pods below three.

For example, if there were four pods altogether and `minAvailable` was set to three as in the example, the pod eviction process would evict pods one by one, waiting for the evicted pod to be replaced with a new one by the ReplicaSet controller, before evicting another pod.

## 15.4. Summary

This chapter has shown you how Kubernetes can scale not only your pods, but also your nodes. You’ve learned that

- Configuring the automatic horizontal scaling of pods is as easy as creating a Horizontal-PodAutoscaler object and pointing it to a Deployment, ReplicaSet, or ReplicationController and specifying the target CPU utilization for the pods.
- Besides having the Horizontal Pod Autoscaler perform scaling operations based on the pods’ CPU utilization, you can also configure it to scale based on your own application-provided custom metrics or metrics related to other objects deployed in the cluster.
- Vertical pod autoscaling isn’t possible yet.
- Even cluster nodes can be scaled automatically if your Kubernetes cluster runs on a supported cloud provider.
- You can run one-off processes in a pod and have the pod stopped and deleted automatically as soon you press CTRL+C by using `kubectl run` with the `-it` and `--rm` options.

In the next chapter, you’ll explore advanced scheduling features, such as how to keep certain pods away from certain nodes and how to schedule pods either close together or apart.
