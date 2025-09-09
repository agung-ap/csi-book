# Chapter 4. Replication and other controllers: deploying managed pods

### **This chapter covers**

- Keeping pods healthy
- Running multiple instances of the same pod
- Automatically rescheduling pods after a node fails
- Scaling pods horizontally
- Running system-level pods on each cluster node
- Running batch jobs
- Scheduling jobs to run periodically or once in the future

As you’ve learned so far, pods represent the basic deployable unit in Kubernetes. You know how to create, supervise, and manage them manually. But in real-world use cases, you want your deployments to stay up and running automatically and remain healthy without any manual intervention. To do this, you almost never create pods directly. Instead, you create other types of resources, such as ReplicationControllers or Deployments, which then create and manage the actual pods.

When you create unmanaged pods (such as the ones you created in the previous chapter), a cluster node is selected to run the pod and then its containers are run on that node. In this chapter, you’ll learn that Kubernetes then monitors those containers and automatically restarts them if they fail. But if the whole node fails, the pods on the node are lost and will not be replaced with new ones, unless those pods are managed by the previously mentioned ReplicationControllers or similar. In this chapter, you’ll learn how Kubernetes checks if a container is still alive and restarts it if it isn’t. You’ll also learn how to run managed pods—both those that run indefinitely and those that perform a single task and then stop.

## 4.1. Keeping pods healthy

One of the main benefits of using Kubernetes is the ability to give it a list of containers and let it keep those containers running somewhere in the cluster. You do this by creating a Pod resource and letting Kubernetes pick a worker node for it and run the pod’s containers on that node. But what if one of those containers dies? What if all containers of a pod die?

As soon as a pod is scheduled to a node, the Kubelet on that node will run its containers and, from then on, keep them running as long as the pod exists. If the container’s main process crashes, the Kubelet will restart the container. If your application has a bug that causes it to crash every once in a while, Kubernetes will restart it automatically, so even without doing anything special in the app itself, running the app in Kubernetes automatically gives it the ability to heal itself.

But sometimes apps stop working without their process crashing. For example, a Java app with a memory leak will start throwing OutOfMemoryErrors, but the JVM process will keep running. It would be great to have a way for an app to signal to Kubernetes that it’s no longer functioning properly and have Kubernetes restart it.

We’ve said that a container that crashes is restarted automatically, so maybe you’re thinking you could catch these types of errors in the app and exit the process when they occur. You can certainly do that, but it still doesn’t solve all your problems.

For example, what about those situations when your app stops responding because it falls into an infinite loop or a deadlock? To make sure applications are restarted in such cases, you must check an application’s health from the outside and not depend on the app doing it internally.

### 4.1.1. Introducing liveness probes

Kubernetes can check if a container is still alive through *liveness probes*. You can specify a liveness probe for each container in the pod’s specification. Kubernetes will periodically execute the probe and restart the container if the probe fails.

---

##### Note

Kubernetes also supports *readiness probes*, which we’ll learn about in the next chapter. Be sure not to confuse the two. They’re used for two different things.

---

Kubernetes can probe a container using one of the three mechanisms:

- An *HTTP GET* probe performs an HTTP GET request on the container’s IP address, a port and path you specify. If the probe receives a response, and the response code doesn’t represent an error (in other words, if the HTTP response code is 2xx or 3xx), the probe is considered successful. If the server returns an error response code or if it doesn’t respond at all, the probe is considered a failure and the container will be restarted as a result.
- A *TCP Socket* probe tries to open a TCP connection to the specified port of the container. If the connection is established successfully, the probe is successful. Otherwise, the container is restarted.
- An *Exec* probe executes an arbitrary command inside the container and checks the command’s exit status code. If the status code is 0, the probe is successful. All other codes are considered failures.

### 4.1.2. Creating an HTTP-based liveness probe

Let’s see how to add a liveness probe to your Node.js app. Because it’s a web app, it makes sense to add a liveness probe that will check whether its web server is serving requests. But because this particular Node.js app is too simple to ever fail, you’ll need to make the app fail artificially.

To properly demo liveness probes, you’ll modify the app slightly and make it return a 500 Internal Server Error HTTP status code for each request after the fifth one—your app will handle the first five client requests properly and then return an error on every subsequent request. Thanks to the liveness probe, it should be restarted when that happens, allowing it to properly handle client requests again.

You can find the code of the new app in the book’s code archive (in the folder Chapter04/kubia-unhealthy). I’ve pushed the container image to Docker Hub, so you don’t need to build it yourself.

You’ll create a new pod that includes an HTTP GET liveness probe. The following listing shows the YAML for the pod.

##### Listing 4.1. Adding a liveness probe to a pod: kubia-liveness-probe.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kubia-liveness
spec:
  containers:
  - image: luksa/kubia-unhealthy
    name: kubia
    livenessProbe:
      httpGet:
        path: /
        port: 8080
```

The pod descriptor defines an `httpGet` liveness probe, which tells Kubernetes to periodically perform HTTP GET requests on path `/` on port `8080` to determine if the container is still healthy. These requests start as soon as the container is run.

After five such requests (or actual client requests), your app starts returning HTTP status code 500, which Kubernetes will treat as a probe failure, and will thus restart the container.

### 4.1.3. Seeing a liveness probe in action

To see what the liveness probe does, try creating the pod now. After about a minute and a half, the container will be restarted. You can see that by running `kubectl get`:

```bash
$ kubectl get po kubia-liveness
NAME             READY     STATUS    RESTARTS   AGE
kubia-liveness   1/1       Running   1          2m
```

The `RESTARTS` column shows that the pod’s container has been restarted once (if you wait another minute and a half, it gets restarted again, and then the cycle continues indefinitely).

---

#### **Obtaining the application log of a crashed container**

In the previous chapter, you learned how to print the application’s log with `kubectl logs`. If your container is restarted, the `kubectl logs` command will show the log of the current container.

When you want to figure out why the previous container terminated, you’ll want to see those logs instead of the current container’s logs. This can be done by using the `--previous` option:

```bash
$ kubectl logs mypod --previous
```

---

You can see why the container had to be restarted by looking at what `kubectl describe` prints out, as shown in the following listing.

##### Listing 4.2. A pod’s description after its container is restarted

```bash
$ kubectl describe po kubia-liveness
Name:           kubia-liveness
...
Containers:
  kubia:
    Container ID:       docker://480986f8
    Image:              luksa/kubia-unhealthy
    Image ID:           docker://sha256:2b208508
    Port:
    State:              Running                                         #1
      Started:          Sun, 14 May 2017 11:41:40 +0200                 #1
    Last State:         Terminated                                      #2
      Reason:           Error                                           #2
      Exit Code:        137                                             #2
      Started:          Mon, 01 Jan 0001 00:00:00 +0000                 #2
      Finished:         Sun, 14 May 2017 11:41:38 +0200                 #2
    Ready:              True
    Restart Count:      1                                               #3
    Liveness:           http-get http://:8080/ delay=0s timeout=1s
                        period=10s #success=1 #failure=3
    ...
Events:
... Killing container with id docker://95246981:pod "kubia-liveness ..."
    container "kubia" is unhealthy, it will be killed and re-created.
```

You can see that the container is currently running, but it previously terminated because of an error. The exit code was `137`, which has a special meaning—it denotes that the process was terminated by an external signal. The number `137` is a sum of two numbers: `128+x`, where `x` is the signal number sent to the process that caused it to terminate. In the example, `x` equals `9`, which is the number of the `SIGKILL` signal, meaning the process was killed forcibly.

The events listed at the bottom show why the container was killed—Kubernetes detected the container was unhealthy, so it killed and re-created it.

---

##### Note

When a container is killed, a completely new container is created—it’s not the same container being restarted again.

---

### 4.1.4. Configuring additional properties of the liveness probe

You may have noticed that `kubectl describe` also displays additional information about the liveness probe:

```
Liveness: http-get http://:8080/ delay=0s timeout=1s period=10s #success=1
          ➥  #failure=3
```

Beside the liveness probe options you specified explicitly, you can also see additional properties, such as `delay`, `timeout`, `period`, and so on. The `delay=0s` part shows that the probing begins immediately after the container is started. The `timeout` is set to only 1 second, so the container must return a response in 1 second or the probe is counted as failed. The container is probed every 10 seconds (`period=10s`) and the container is restarted after the probe fails three consecutive times (`#failure=3`).

These additional parameters can be customized when defining the probe. For example, to set the initial delay, add the `initialDelaySeconds` property to the liveness probe as shown in the following listing.

##### Listing 4.3. A liveness probe with an initial delay: kubia-liveness-probe-initial-delay.yaml

```
livenessProbe:
     httpGet:
       path: /
       port: 8080
     initialDelaySeconds: 15              #1
```

If you don’t set the initial delay, the prober will start probing the container as soon as it starts, which usually leads to the probe failing, because the app isn’t ready to start receiving requests. If the number of failures exceeds the failure threshold, the container is restarted before it’s even able to start responding to requests properly.

---

##### Tip

Always remember to set an initial delay to account for your app’s startup time.

---

I’ve seen this on many occasions and users were confused why their container was being restarted. But if they’d used `kubectl describe`, they’d have seen that the container terminated with exit code 137 or 143, telling them that the pod was terminated externally. Additionally, the listing of the pod’s events would show that the container was killed because of a failed liveness probe. If you see this happening at pod startup, it’s because you failed to set `initialDelaySeconds` appropriately.

---

##### Note

Exit code 137 signals that the process was killed by an external signal (exit code is 128 + 9 (SIGKILL). Likewise, exit code 143 corresponds to 128 + 15 (SIGTERM).

---

### 4.1.5. Creating effective liveness probes

For pods running in production, you should always define a liveness probe. Without one, Kubernetes has no way of knowing whether your app is still alive or not. As long as the process is still running, Kubernetes will consider the container to be healthy.

##### What a liveness probe should check

Your simplistic liveness probe simply checks if the server is responding. While this may seem overly simple, even a liveness probe like this does wonders, because it causes the container to be restarted if the web server running within the container stops responding to HTTP requests. Compared to having no liveness probe, this is a major improvement, and may be sufficient in most cases.

But for a better liveness check, you’d configure the probe to perform requests on a specific URL path (`/health`, for example) and have the app perform an internal status check of all the vital components running inside the app to ensure none of them has died or is unresponsive.

---

##### Tip

Make sure the `/health` HTTP endpoint doesn’t require authentication; otherwise the probe will always fail, causing your container to be restarted indefinitely.

---

Be sure to check only the internals of the app and nothing influenced by an external factor. For example, a frontend web server’s liveness probe shouldn’t return a failure when the server can’t connect to the backend database. If the underlying cause is in the database itself, restarting the web server container will not fix the problem. Because the liveness probe will fail again, you’ll end up with the container restarting repeatedly until the database becomes accessible again.

##### Keeping probes light

Liveness probes shouldn’t use too many computational resources and shouldn’t take too long to complete. By default, the probes are executed relatively often and are only allowed one second to complete. Having a probe that does heavy lifting can slow down your container considerably. Later in the book, you’ll also learn about how to limit CPU time available to a container. The probe’s CPU time is counted in the container’s CPU time quota, so having a heavyweight liveness probe will reduce the CPU time available to the main application processes.

---

##### Tip

If you’re running a Java app in your container, be sure to use an HTTP GET liveness probe instead of an Exec probe, where you spin up a whole new JVM to get the liveness information. The same goes for any JVM-based or similar applications, whose start-up procedure requires considerable computational resources.

---

##### Don’t bother implementing retry loops in your probes

You’ve already seen that the failure threshold for the probe is configurable and usually the probe must fail multiple times before the container is killed. But even if you set the failure threshold to 1, Kubernetes will retry the probe several times before considering it a single failed attempt. Therefore, implementing your own retry loop into the probe is wasted effort.

##### Liveness probe wrap-up

You now understand that Kubernetes keeps your containers running by restarting them if they crash or if their liveness probes fail. This job is performed by the Kubelet on the node hosting the pod—the Kubernetes Control Plane components running on the master(s) have no part in this process.

But if the node itself crashes, it’s the Control Plane that must create replacements for all the pods that went down with the node. It doesn’t do that for pods that you create directly. Those pods aren’t managed by anything except by the Kubelet, but because the Kubelet runs on the node itself, it can’t do anything if the node fails.

To make sure your app is restarted on another node, you need to have the pod managed by a ReplicationController or similar mechanism, which we’ll discuss in the rest of this chapter.

## 4.2. Introducing ReplicationControllers

A ReplicationController is a Kubernetes resource that ensures its pods are always kept running. If the pod disappears for any reason, such as in the event of a node disappearing from the cluster or because the pod was evicted from the node, the ReplicationController notices the missing pod and creates a replacement pod.

[Figure 4.1](/book/kubernetes-in-action/chapter-4/ch04fig01) shows what happens when a node goes down and takes two pods with it. Pod A was created directly and is therefore an unmanaged pod, while pod B is managed by a ReplicationController. After the node fails, the ReplicationController creates a new pod (pod B2) to replace the missing pod B, whereas pod A is lost completely—nothing will ever recreate it.

![Figure 4.1. When a node fails, only pods backed by a ReplicationController are recreated.](https://drek4537l1klr.cloudfront.net/luksa/Figures/04fig01_alt.jpg)

The ReplicationController in the figure manages only a single pod, but Replication-Controllers, in general, are meant to create and manage multiple copies (replicas) of a pod. That’s where ReplicationControllers got their name from.

### 4.2.1. The operation of a ReplicationController

A ReplicationController constantly monitors the list of running pods and makes sure the actual number of pods of a “type” always matches the desired number. If too few such pods are running, it creates new replicas from a pod template. If too many such pods are running, it removes the excess replicas.

You might be wondering how there can be more than the desired number of replicas. This can happen for a few reasons:

- Someone creates a pod of the same type manually.
- Someone changes an existing pod’s “type.”
- Someone decreases the desired number of pods, and so on.

I’ve used the term pod “type” a few times. But no such thing exists. Replication-Controllers don’t operate on pod types, but on sets of pods that match a certain label selector (you learned about them in the previous chapter).

##### Introducing the controller’s reconciliation loop

A ReplicationController’s job is to make sure that an exact number of pods always matches its label selector. If it doesn’t, the ReplicationController takes the appropriate action to reconcile the actual with the desired number. The operation of a Replication-Controller is shown in [figure 4.2](/book/kubernetes-in-action/chapter-4/ch04fig02).

![Figure 4.2. A ReplicationController’s reconciliation loop](https://drek4537l1klr.cloudfront.net/luksa/Figures/04fig02_alt.jpg)

##### Understanding the three parts of a ReplicationController

A ReplicationController has three essential parts (also shown in [figure 4.3](/book/kubernetes-in-action/chapter-4/ch04fig03)):

- A *label selector*, which determines what pods are in the ReplicationController’s scope
- A *replica count*, which specifies the desired number of pods that should be running
- A *pod template*, which is used when creating new pod replicas

![Figure 4.3. The three key parts of a ReplicationController (pod selector, replica count, and pod template)](https://drek4537l1klr.cloudfront.net/luksa/Figures/04fig03.jpg)

A ReplicationController’s replica count, the label selector, and even the pod template can all be modified at any time, but only changes to the replica count affect existing pods.

##### Understanding the effect of changing the controller’s label selec- ctor or pod template

Changes to the label selector and the pod template have no effect on existing pods. Changing the label selector makes the existing pods fall out of the scope of the Replication-Controller, so the controller stops caring about them. ReplicationControllers also don’t care about the actual “contents” of its pods (the container images, environment variables, and other things) after they create the pod. The template therefore only affects new pods created by this ReplicationController. You can think of it as a cookie cutter for cutting out new pods.

##### Understanding the benefits of using a ReplicationController

Like many things in Kubernetes, a ReplicationController, although an incredibly simple concept, provides or enables the following powerful features:

- It makes sure a pod (or multiple pod replicas) is always running by starting a new pod when an existing one goes missing.
- When a cluster node fails, it creates replacement replicas for all the pods that were running on the failed node (those that were under the Replication-Controller’s control).
- It enables easy horizontal scaling of pods—both manual and automatic (see horizontal pod auto-scaling in [chapter 15](/book/kubernetes-in-action/chapter-15/ch15)).

---

##### Note

A pod instance is never relocated to another node. Instead, the Replication-Controller creates a completely new pod instance that has no relation to the instance it’s replacing.

---

### 4.2.2. Creating a ReplicationController

Let’s look at how to create a ReplicationController and then see how it keeps your pods running. Like pods and other Kubernetes resources, you create a ReplicationController by posting a JSON or YAML descriptor to the Kubernetes API server.

You’re going to create a YAML file called kubia-rc.yaml for your Replication-Controller, as shown in the following listing.

##### Listing 4.4. A YAML definition of a ReplicationController: kubia-rc.yaml

```yaml
apiVersion: v1
kind: ReplicationController
metadata:
  name: kubia
spec:
  replicas: 3
  selector:
    app: kubia
  template:

    metadata:

      labels:

        app: kubia

    spec:

      containers:

      - name: kubia

        image: luksa/kubia

        ports:

        - containerPort: 8080
```

When you post the file to the API server, Kubernetes creates a new Replication-Controller named `kubia`, which makes sure three pod instances always match the label selector `app=kubia`. When there aren’t enough pods, new pods will be created from the provided pod template. The contents of the template are almost identical to the pod definition you created in the previous chapter.

The pod labels in the template must obviously match the label selector of the ReplicationController; otherwise the controller would create new pods indefinitely, because spinning up a new pod wouldn’t bring the actual replica count any closer to the desired number of replicas. To prevent such scenarios, the API server verifies the ReplicationController definition and will not accept it if it’s misconfigured.

Not specifying the selector at all is also an option. In that case, it will be configured automatically from the labels in the pod template.

---

##### Tip

Don’t specify a pod selector when defining a ReplicationController. Let Kubernetes extract it from the pod template. This will keep your YAML shorter and simpler.

---

To create the ReplicationController, use the `kubectl create` command, which you already know:

```bash
$ kubectl create -f kubia-rc.yaml
replicationcontroller "kubia" created
```

As soon as the ReplicationController is created, it goes to work. Let’s see what it does.

### 4.2.3. Seeing the ReplicationController in action

Because no pods exist with the `app=kubia` label, the ReplicationController should spin up three new pods from the pod template. List the pods to see if the ReplicationController has done what it’s supposed to:

```bash
$ kubectl get pods
NAME          READY     STATUS              RESTARTS   AGE
kubia-53thy   0/1       ContainerCreating   0          2s
kubia-k0xz6   0/1       ContainerCreating   0          2s
kubia-q3vkg   0/1       ContainerCreating   0          2s
```

Indeed, it has! You wanted three pods, and it created three pods. It’s now managing those three pods. Next you’ll mess with them a little to see how the Replication-Controller responds.

##### Seeing the ReplicationController respond to a deleted pod

First, you’ll delete one of the pods manually to see how the ReplicationController spins up a new one immediately, bringing the number of matching pods back to three:

```bash
$ kubectl delete pod kubia-53thy
pod "kubia-53thy" deleted
```

Listing the pods again shows four of them, because the one you deleted is terminating, and a new pod has already been created:

```bash
$ kubectl get pods
NAME          READY     STATUS              RESTARTS   AGE
kubia-53thy   1/1       Terminating         0          3m
kubia-oini2   0/1       ContainerCreating   0          2s
kubia-k0xz6   1/1       Running             0          3m
kubia-q3vkg   1/1       Running             0          3m
```

The ReplicationController has done its job again. It’s a nice little helper, isn’t it?

##### Getting information about a ReplicationController

Now, let’s see what information the `kubectl get` command shows for ReplicationControllers:

```bash
$ kubectl get rc
NAME      DESIRED   CURRENT   READY     AGE
kubia     3         3         2         3m
```

---

##### Note

We’re using `rc` as a shorthand for `replicationcontroller`.

---

You see three columns showing the desired number of pods, the actual number of pods, and how many of them are ready (you’ll learn what that means in the next chapter, when we talk about readiness probes).

You can see additional information about your ReplicationController with the `kubectl describe` command, as shown in the following listing.

##### Listing 4.5. Displaying details of a ReplicationController with `kubectl describe`

```bash
$ kubectl describe rc kubia
Name:           kubia
Namespace:      default
Selector:       app=kubia
Labels:         app=kubia
Annotations:    <none>
Replicas:       3 current / 3 desired                                    #1
Pods Status:    4 Running / 0 Waiting / 0 Succeeded / 0 Failed           #2
Pod Template:
  Labels:       app=kubia
  Containers:   ...
  Volumes:      <none>
Events:                                                                  #3
From                    Type      Reason           Message
----                    -------  ------            -------
replication-controller  Normal   SuccessfulCreate  Created pod: kubia-53thy
replication-controller  Normal   SuccessfulCreate  Created pod: kubia-k0xz6
replication-controller  Normal   SuccessfulCreate  Created pod: kubia-q3vkg
replication-controller  Normal   SuccessfulCreate  Created pod: kubia-oini2
```

The current number of replicas matches the desired number, because the controller has already created a new pod. It shows four running pods because a pod that’s terminating is still considered running, although it isn’t counted in the current replica count.

The list of events at the bottom shows the actions taken by the Replication-Controller—it has created four pods so far.

##### Understanding exactly what caused the controller to create a new pod

The controller is responding to the deletion of a pod by creating a new replacement pod (see [figure 4.4](/book/kubernetes-in-action/chapter-4/ch04fig04)). Well, technically, it isn’t responding to the deletion itself, but the resulting state—the inadequate number of pods.

![Figure 4.4. If a pod disappears, the ReplicationController sees too few pods and creates a new replacement pod.](https://drek4537l1klr.cloudfront.net/luksa/Figures/04fig04_alt.jpg)

While a ReplicationController is immediately notified about a pod being deleted (the API server allows clients to watch for changes to resources and resource lists), that’s not what causes it to create a replacement pod. The notification triggers the controller to check the actual number of pods and take appropriate action.

##### Responding to a node failure

Seeing the ReplicationController respond to the manual deletion of a pod isn’t too interesting, so let’s look at a better example. If you’re using Google Kubernetes Engine to run these examples, you have a three-node Kubernetes cluster. You’re going to disconnect one of the nodes from the network to simulate a node failure.

---

##### Note

If you’re using Minikube, you can’t do this exercise, because you only have one node that acts both as a master and a worker node.

---

If a node fails in the non-Kubernetes world, the ops team would need to migrate the applications running on that node to other machines manually. Kubernetes, on the other hand, does that automatically. Soon after the ReplicationController detects that its pods are down, it will spin up new pods to replace them.

Let’s see this in action. You need to `ssh` into one of the nodes with the `gcloud compute ssh` command and then shut down its network interface with `sudo ifconfig eth0 down`, as shown in the following listing.

---

##### Note

Choose a node that runs at least one of your pods by listing pods with the `-o wide` option.

---

##### Listing 4.6. Simulating a node failure by shutting down its network interface

```bash
$ gcloud compute ssh gke-kubia-default-pool-b46381f1-zwko
Enter passphrase for key '/home/luksa/.ssh/google_compute_engine':

Welcome to Kubernetes v1.6.4!
...

luksa@gke-kubia-default-pool-b46381f1-zwko ~ $ sudo ifconfig eth0 down
```

When you shut down the network interface, the `ssh` session will stop responding, so you need to open up another terminal or hard-exit from the `ssh` session. In the new terminal you can list the nodes to see if Kubernetes has detected that the node is down. This takes a minute or so. Then, the node’s status is shown as `NotReady`:

```bash
$ kubectl get node
NAME                                   STATUS     AGE
gke-kubia-default-pool-b46381f1-opc5   Ready      5h
gke-kubia-default-pool-b46381f1-s8gj   Ready      5h
gke-kubia-default-pool-b46381f1-zwko   NotReady   5h        #1
```

If you list the pods now, you’ll still see the same three pods as before, because Kubernetes waits a while before rescheduling pods (in case the node is unreachable because of a temporary network glitch or because the Kubelet is restarting). If the node stays unreachable for several minutes, the status of the pods that were scheduled to that node changes to `Unknown`. At that point, the ReplicationController will immediately spin up a new pod. You can see this by listing the pods again:

```bash
$ kubectl get pods
NAME          READY   STATUS    RESTARTS   AGE
kubia-oini2   1/1     Running   0          10m
kubia-k0xz6   1/1     Running   0          10m
kubia-q3vkg   1/1     Unknown   0          10m       #1
kubia-dmdck   1/1     Running   0          5s        #2
```

Looking at the age of the pods, you see that the `kubia-dmdck` pod is new. You again have three pod instances running, which means the ReplicationController has again done its job of bringing the actual state of the system to the desired state.

The same thing happens if a node fails (either breaks down or becomes unreachable). No immediate human intervention is necessary. The system heals itself automatically.

To bring the node back, you need to reset it with the following command:

```bash
$ gcloud compute instances reset gke-kubia-default-pool-b46381f1-zwko
```

When the node boots up again, its status should return to `Ready`, and the pod whose status was `Unknown` will be deleted.

### 4.2.4. Moving pods in and out of the scope of a ReplicationController

Pods created by a ReplicationController aren’t tied to the ReplicationController in any way. At any moment, a ReplicationController manages pods that match its label selector. By changing a pod’s labels, it can be removed from or added to the scope of a ReplicationController. It can even be moved from one ReplicationController to another.

---

##### Tip

Although a pod isn’t tied to a ReplicationController, the pod does reference it in the `metadata.ownerReferences` field, which you can use to easily find which ReplicationController a pod belongs to.

---

If you change a pod’s labels so they no longer match a ReplicationController’s label selector, the pod becomes like any other manually created pod. It’s no longer managed by anything. If the node running the pod fails, the pod is obviously not rescheduled. But keep in mind that when you changed the pod’s labels, the replication controller noticed one pod was missing and spun up a new pod to replace it.

Let’s try this with your pods. Because your ReplicationController manages pods that have the `app=kubia` label, you need to either remove this label or change its value to move the pod out of the ReplicationController’s scope. Adding another label will have no effect, because the ReplicationController doesn’t care if the pod has any additional labels. It only cares whether the pod has all the labels referenced in the label selector.

##### Adding labels to pods managed by a ReplicationController

Let’s confirm that a ReplicationController doesn’t care if you add additional labels to its managed pods:

```bash
$ kubectl label pod kubia-dmdck type=special
pod "kubia-dmdck" labeled

$ kubectl get pods --show-labels
NAME          READY   STATUS    RESTARTS   AGE   LABELS
kubia-oini2   1/1     Running   0          11m   app=kubia
kubia-k0xz6   1/1     Running   0          11m   app=kubia
kubia-dmdck   1/1     Running   0          1m    app=kubia,type=special
```

You’ve added the `type=special` label to one of the pods. Listing all pods again shows the same three pods as before, because no change occurred as far as the ReplicationController is concerned.

##### Changing the labels of a managed pod

Now, you’ll change the `app=kubia` label to something else. This will make the pod no longer match the ReplicationController’s label selector, leaving it to only match two pods. The ReplicationController should therefore start a new pod to bring the number back to three:

```bash
$ kubectl label pod kubia-dmdck app=foo --overwrite
pod "kubia-dmdck" labeled
```

The `--overwrite` argument is necessary; otherwise `kubectl` will only print out a warning and won’t change the label, to prevent you from inadvertently changing an existing label’s value when your intent is to add a new one.

Listing all the pods again should now show four pods:

```bash
$ kubectl get pods -L app
NAME         READY  STATUS             RESTARTS  AGE  APP
kubia-2qneh  0/1    ContainerCreating  0         2s   kubia        #1
kubia-oini2  1/1    Running            0         20m  kubia
kubia-k0xz6  1/1    Running            0         20m  kubia
kubia-dmdck  1/1    Running            0         10m  foo          #2
```

---

##### Note

You’re using the `-L app` option to display the `app` label in a column.

---

There, you now have four pods altogether: one that isn’t managed by your Replication-Controller and three that are. Among them is the newly created pod.

[Figure 4.5](/book/kubernetes-in-action/chapter-4/ch04fig05) illustrates what happened when you changed the pod’s labels so they no longer matched the ReplicationController’s pod selector. You can see your three pods and your ReplicationController. After you change the pod’s label from `app=kubia` to `app=foo`, the ReplicationController no longer cares about the pod. Because the controller’s replica count is set to 3 and only two pods match the label selector, the ReplicationController spins up pod `kubia-2qneh` to bring the number back up to three. Pod `kubia-dmdck` is now completely independent and will keep running until you delete it manually (you can do that now, because you don’t need it anymore).

![Figure 4.5. Removing a pod from the scope of a ReplicationController by changing its labels](https://drek4537l1klr.cloudfront.net/luksa/Figures/04fig05_alt.jpg)

##### Removing pods from controllers in practice

Removing a pod from the scope of the ReplicationController comes in handy when you want to perform actions on a specific pod. For example, you might have a bug that causes your pod to start behaving badly after a specific amount of time or a specific event. If you know a pod is malfunctioning, you can take it out of the ReplicationController’s scope, let the controller replace it with a new one, and then debug or play with the pod in any way you want. Once you’re done, you delete the pod.

##### Changing the ReplicationController’s label selector

As an exercise to see if you fully understand ReplicationControllers, what do you think would happen if instead of changing the labels of a pod, you modified the Replication-Controller’s label selector?

If your answer is that it would make all the pods fall out of the scope of the ReplicationController, which would result in it creating three new pods, you’re absolutely right. And it shows that you understand how ReplicationControllers work.

Kubernetes does allow you to change a ReplicationController’s label selector, but that’s not the case for the other resources that are covered in the second half of this chapter and which are also used for managing pods. You’ll never change a controller’s label selector, but you’ll regularly change its pod template. Let’s take a look at that.

### 4.2.5. Changing the pod template

A ReplicationController’s pod template can be modified at any time. Changing the pod template is like replacing a cookie cutter with another one. It will only affect the cookies you cut out afterward and will have no effect on the ones you’ve already cut (see [figure 4.6](/book/kubernetes-in-action/chapter-4/ch04fig06)). To modify the old pods, you’d need to delete them and let the Replication-Controller replace them with new ones based on the new template.

![Figure 4.6. Changing a ReplicationController’s pod template only affects pods created afterward and has no effect on existing pods.](https://drek4537l1klr.cloudfront.net/luksa/Figures/04fig06_alt.jpg)

As an exercise, you can try editing the ReplicationController and adding a label to the pod template. You can edit the ReplicationController with the following command:

```bash
$ kubectl edit rc kubia
```

This will open the ReplicationController’s YAML definition in your default text editor. Find the pod template section and add an additional label to the metadata. After you save your changes and exit the editor, `kubectl` will update the ReplicationController and print the following message:

```
replicationcontroller "kubia" edited
```

You can now list pods and their labels again and confirm that they haven’t changed. But if you delete the pods and wait for their replacements to be created, you’ll see the new label.

Editing a ReplicationController like this to change the container image in the pod template, deleting the existing pods, and letting them be replaced with new ones from the new template could be used for upgrading pods, but you’ll learn a better way of doing that in [chapter 9](/book/kubernetes-in-action/chapter-9/ch09).

---

##### **Configuring kubectl edit to use a different text editor**

You can tell `kubectl` to use a text editor of your choice by setting the `KUBE_EDITOR` environment variable. For example, if you’d like to use `nano` for editing Kubernetes resources, execute the following command (or put it into your `~/.bashrc` or an equivalent file):

```
export KUBE_EDITOR="/usr/bin/nano"
```

If the `KUBE_EDITOR` environment variable isn’t set, `kubectl edit` falls back to using the default editor, usually configured through the `EDITOR` environment variable.

---

### 4.2.6. Horizontally scaling pods

You’ve seen how ReplicationControllers make sure a specific number of pod instances is always running. Because it’s incredibly simple to change the desired number of replicas, this also means scaling pods horizontally is trivial.

Scaling the number of pods up or down is as easy as changing the value of the replicas field in the ReplicationController resource. After the change, the Replication-Controller will either see too many pods exist (when scaling down) and delete part of them, or see too few of them (when scaling up) and create additional pods.

##### Scaling up a ReplicationController

Your ReplicationController has been keeping three instances of your pod running. You’re going to scale that number up to 10 now. As you may remember, you’ve already scaled a ReplicationController in [chapter 2](/book/kubernetes-in-action/chapter-2/ch02). You could use the same command as before:

```bash
$ kubectl scale rc kubia --replicas=10
```

But you’ll do it differently this time.

##### Scaling a ReplicationController by editing its definition

Instead of using the `kubectl scale` command, you’re going to scale it in a declarative way by editing the ReplicationController’s definition:

```bash
$ kubectl edit rc kubia
```

When the text editor opens, find the `spec.replicas` field and change its value to `10`, as shown in the following listing.

##### Listing 4.7. Editing the RC in a text editor by running `kubectl edit`

```bash
# Please edit the object below. Lines beginning with a '#' will be ignored,
# and an empty file will abort the edit. If an error occurs while saving
# this file will be reopened with the relevant failures.
apiVersion: v1
kind: ReplicationController
metadata:
  ...
spec:
  replicas: 3           #1
  selector:
    app: kubia
  ...
```

When you save the file and close the editor, the ReplicationController is updated and it immediately scales the number of pods to 10:

```bash
$ kubectl get rc
NAME      DESIRED   CURRENT   READY     AGE
kubia     10        10        4         21m
```

There you go. If the `kubectl scale` command makes it look as though you’re telling Kubernetes exactly what to do, it’s now much clearer that you’re making a declarative change to the desired state of the ReplicationController and not telling Kubernetes to do something.

##### Scaling down with the kubectl scale command

Now scale back down to 3. You can use the `kubectl scale` command:

```bash
$ kubectl scale rc kubia --replicas=3
```

All this command does is modify the `spec.replicas` field of the ReplicationController’s definition—like when you changed it through `kubectl edit`.

##### Understanding the declarative approach to scaling

Horizontally scaling pods in Kubernetes is a matter of stating your desire: “I want to have *x* number of instances running.” You’re not telling Kubernetes what or how to do it. You’re just specifying the desired state.

This declarative approach makes interacting with a Kubernetes cluster easy. Imagine if you had to manually determine the current number of running instances and then explicitly tell Kubernetes how many additional instances to run. That’s more work and is much more error-prone. Changing a simple number is much easier, and in [chapter 15](/book/kubernetes-in-action/chapter-15/ch15), you’ll learn that even that can be done by Kubernetes itself if you enable horizontal pod auto-scaling.

### 4.2.7. Deleting a ReplicationController

When you delete a ReplicationController through `kubectl delete`, the pods are also deleted. But because pods created by a ReplicationController aren’t an integral part of the ReplicationController, and are only managed by it, you can delete only the ReplicationController and leave the pods running, as shown in [figure 4.7](/book/kubernetes-in-action/chapter-4/ch04fig07).

![Figure 4.7. Deleting a replication controller with --cascade=false leaves pods unmanaged.](https://drek4537l1klr.cloudfront.net/luksa/Figures/04fig07_alt.jpg)

This may be useful when you initially have a set of pods managed by a Replication-Controller, and then decide to replace the ReplicationController with a ReplicaSet, for example (you’ll learn about them next.). You can do this without affecting the pods and keep them running without interruption while you replace the Replication-Controller that manages them.

When deleting a ReplicationController with `kubectl delete`, you can keep its pods running by passing the `--cascade=false` option to the command. Try that now:

```bash
$ kubectl delete rc kubia --cascade=false
replicationcontroller "kubia" deleted
```

You’ve deleted the ReplicationController so the pods are on their own. They are no longer managed. But you can always create a new ReplicationController with the proper label selector and make them managed again.

## 4.3. Using ReplicaSets instead of ReplicationControllers

Initially, ReplicationControllers were the only Kubernetes component for replicating pods and rescheduling them when nodes failed. Later, a similar resource called a ReplicaSet was introduced. It’s a new generation of ReplicationController and replaces it completely (ReplicationControllers will eventually be deprecated).

You could have started this chapter by creating a ReplicaSet instead of a Replication-Controller, but I felt it would be a good idea to start with what was initially available in Kubernetes. Plus, you’ll still see ReplicationControllers used in the wild, so it’s good for you to know about them. That said, you should always create ReplicaSets instead of ReplicationControllers from now on. They’re almost identical, so you shouldn’t have any trouble using them instead.

You usually won’t create them directly, but instead have them created automatically when you create the higher-level Deployment resource, which you’ll learn about in [chapter 9](/book/kubernetes-in-action/chapter-9/ch09). In any case, you should understand ReplicaSets, so let’s see how they differ from ReplicationControllers.

### 4.3.1. Comparing a ReplicaSet to a ReplicationController

A ReplicaSet behaves exactly like a ReplicationController, but it has more expressive pod selectors. Whereas a ReplicationController’s label selector only allows matching pods that include a certain label, a ReplicaSet’s selector also allows matching pods that lack a certain label or pods that include a certain label key, regardless of its value.

Also, for example, a single ReplicationController can’t match pods with the label `env=production` and those with the label `env=devel` at the same time. It can only match either pods with the `env=production` label or pods with the `env=devel` label. But a single ReplicaSet can match both sets of pods and treat them as a single group.

Similarly, a ReplicationController can’t match pods based merely on the presence of a label key, regardless of its value, whereas a ReplicaSet can. For example, a ReplicaSet can match all pods that include a label with the key `env`, whatever its actual value is (you can think of it as `env=*`).

### 4.3.2. Defining a ReplicaSet

You’re going to create a ReplicaSet now to see how the orphaned pods that were created by your ReplicationController and then abandoned earlier can now be adopted by a ReplicaSet. First, you’ll rewrite your ReplicationController into a ReplicaSet by creating a new file called kubia-replicaset.yaml with the contents in the following listing.

##### Listing 4.8. A YAML definition of a ReplicaSet: kubia-replicaset.yaml

```yaml
apiVersion: apps/v1beta2
kind: ReplicaSet
metadata:
  name: kubia
spec:
  replicas: 3
  selector:
    matchLabels:
      app: kubia
  template:
    metadata:
      labels:
        app: kubia
    spec:
      containers:
      - name: kubia
        image: luksa/kubia
```

The first thing to note is that ReplicaSets aren’t part of the v1 API, so you need to ensure you specify the proper `apiVersion` when creating the resource. You’re creating a resource of type ReplicaSet which has much the same contents as the Replication-Controller you created earlier.

The only difference is in the selector. Instead of listing labels the pods need to have directly under the `selector` property, you’re specifying them under `selector.matchLabels`. This is the simpler (and less expressive) way of defining label selectors in a ReplicaSet. Later, you’ll look at the more expressive option, as well.

---

#### **About the API version attribute**

This is your first opportunity to see that the `apiVersion` property specifies two things:

- The API group (which is `apps` in this case)
- The actual API version (`v1beta2`)

You’ll see throughout the book that certain Kubernetes resources are in what’s called the core API group, which doesn’t need to be specified in the `apiVersion` field (you just specify the version—for example, you’ve been using `apiVersion: v1` when defining Pod resources). Other resources, which were introduced in later Kubernetes versions, are categorized into several API groups. Look at the inside of the book’s covers to see all resources and their respective API groups.

---

Because you still have three pods matching the `app=kubia` selector running from earlier, creating this ReplicaSet will not cause any new pods to be created. The ReplicaSet will take those existing three pods under its wing.

### 4.3.3. Creating and examining a ReplicaSet

Create the ReplicaSet from the YAML file with the `kubectl create` command. After that, you can examine the ReplicaSet with `kubectl get` and `kubectl describe`:

```bash
$ kubectl get rs
NAME      DESIRED   CURRENT   READY     AGE
kubia     3         3         3         3s
```

---

##### Tip

Use `rs` shorthand, which stands for `replicaset`.

---

```bash
$ kubectl describe rs
Name:           kubia
Namespace:      default
Selector:       app=kubia
Labels:         app=kubia
Annotations:    <none>
Replicas:       3 current / 3 desired
Pods Status:    3 Running / 0 Waiting / 0 Succeeded / 0 Failed
Pod Template:
  Labels:       app=kubia
  Containers:   ...
  Volumes:      <none>
Events:         <none>
```

As you can see, the ReplicaSet isn’t any different from a ReplicationController. It’s showing it has three replicas matching the selector. If you list all the pods, you’ll see they’re still the same three pods you had before. The ReplicaSet didn’t create any new ones.

### 4.3.4. Using the ReplicaSet’s more expressive label selectors

The main improvements of ReplicaSets over ReplicationControllers are their more expressive label selectors. You intentionally used the simpler `matchLabels` selector in the first ReplicaSet example to see that ReplicaSets are no different from Replication-Controllers. Now, you’ll rewrite the selector to use the more powerful `matchExpressions` property, as shown in the following listing.

##### Listing 4.9. A `matchExpressions` selector: kubia-replicaset-matchexpressions.yaml

```
selector:
   matchExpressions:
     - key: app                      #1
       operator: In                  #2
       values:                       #2
         - kubia                     #2
```

---

##### Note

Only the selector is shown. You’ll find the whole ReplicaSet definition in the book’s code archive.

---

You can add additional expressions to the selector. As in the example, each expression must contain a `key`, an `operator`, and possibly (depending on the operator) a list of `values`. You’ll see four valid operators:

- `In—`Label’s value must match one of the specified `values`.
- `NotIn—`Label’s value must not match any of the specified `values`.
- `Exists—`Pod must include a label with the specified key (the value isn’t important). When using this operator, you shouldn’t specify the `values` field.
- `DoesNotExist—`Pod must not include a label with the specified key. The `values` property must not be specified.

If you specify multiple expressions, all those expressions must evaluate to true for the selector to match a pod. If you specify both `matchLabels` and `matchExpressions`, all the labels must match and all the expressions must evaluate to true for the pod to match the selector.

### 4.3.5. Wrapping up ReplicaSets

This was a quick introduction to ReplicaSets as an alternative to ReplicationControllers. Remember, always use them instead of ReplicationControllers, but you may still find ReplicationControllers in other people’s deployments.

Now, delete the ReplicaSet to clean up your cluster a little. You can delete the ReplicaSet the same way you’d delete a ReplicationController:

```bash
$ kubectl delete rs kubia
replicaset "kubia" deleted
```

Deleting the ReplicaSet should delete all the pods. List the pods to confirm that’s the case.

## 4.4. Running exactly one pod on each node with DaemonSets

Both ReplicationControllers and ReplicaSets are used for running a specific number of pods deployed anywhere in the Kubernetes cluster. But certain cases exist when you want a pod to run on each and every node in the cluster (and each node needs to run exactly one instance of the pod, as shown in [figure 4.8](/book/kubernetes-in-action/chapter-4/ch04fig08)).

![Figure 4.8. DaemonSets run only a single pod replica on each node, whereas ReplicaSets scatter them around the whole cluster randomly.](https://drek4537l1klr.cloudfront.net/luksa/Figures/04fig08_alt.jpg)

Those cases include infrastructure-related pods that perform system-level operations. For example, you’ll want to run a log collector and a resource monitor on every node. Another good example is Kubernetes’ own kube-proxy process, which needs to run on all nodes to make services work.

Outside of Kubernetes, such processes would usually be started through system init scripts or the systemd daemon during node boot up. On Kubernetes nodes, you can still use systemd to run your system processes, but then you can’t take advantage of all the features Kubernetes provides.

### 4.4.1. Using a DaemonSet to run a pod on every node

To run a pod on all cluster nodes, you create a DaemonSet object, which is much like a ReplicationController or a ReplicaSet, except that pods created by a DaemonSet already have a target node specified and skip the Kubernetes Scheduler. They aren’t scattered around the cluster randomly.

A DaemonSet makes sure it creates as many pods as there are nodes and deploys each one on its own node, as shown in [figure 4.8](/book/kubernetes-in-action/chapter-4/ch04fig08).

Whereas a ReplicaSet (or ReplicationController) makes sure that a desired number of pod replicas exist in the cluster, a DaemonSet doesn’t have any notion of a desired replica count. It doesn’t need it because its job is to ensure that a pod matching its pod selector is running on each node.

If a node goes down, the DaemonSet doesn’t cause the pod to be created elsewhere. But when a new node is added to the cluster, the DaemonSet immediately deploys a new pod instance to it. It also does the same if someone inadvertently deletes one of the pods, leaving the node without the DaemonSet’s pod. Like a ReplicaSet, a DaemonSet creates the pod from the pod template configured in it.

### 4.4.2. Using a DaemonSet to run pods only on certain nodes

A DaemonSet deploys pods to all nodes in the cluster, unless you specify that the pods should only run on a subset of all the nodes. This is done by specifying the `node-Selector` property in the pod template, which is part of the DaemonSet definition (similar to the pod template in a ReplicaSet or ReplicationController).

You’ve already used node selectors to deploy a pod onto specific nodes in [chapter 3](/book/kubernetes-in-action/chapter-3/ch03). A node selector in a DaemonSet is similar—it defines the nodes the DaemonSet must deploy its pods to.

---

##### Note

Later in the book, you’ll learn that nodes can be made unschedulable, preventing pods from being deployed to them. A DaemonSet will deploy pods even to such nodes, because the unschedulable attribute is only used by the Scheduler, whereas pods managed by a DaemonSet bypass the Scheduler completely. This is usually desirable, because DaemonSets are meant to run system services, which usually need to run even on unschedulable nodes.

---

##### Explaining DaemonSets with an example

Let’s imagine having a daemon called `ssd-monitor` that needs to run on all nodes that contain a solid-state drive (SSD). You’ll create a DaemonSet that runs this daemon on all nodes that are marked as having an SSD. The cluster administrators have added the `disk=ssd` label to all such nodes, so you’ll create the DaemonSet with a node selector that only selects nodes with that label, as shown in [figure 4.9](/book/kubernetes-in-action/chapter-4/ch04fig09).

![Figure 4.9. Using a DaemonSet with a node selector to deploy system pods only on certain nodes](https://drek4537l1klr.cloudfront.net/luksa/Figures/04fig09_alt.jpg)

##### Creating a DaemonSet YAML definition

You’ll create a DaemonSet that runs a mock `ssd-monitor` process, which prints “SSD OK” to the standard output every five seconds. I’ve already prepared the mock container image and pushed it to Docker Hub, so you can use it instead of building your own. Create the YAML for the DaemonSet, as shown in the following listing.

##### Listing 4.10. A YAML for a DaemonSet: ssd-monitor-daemonset.yaml

```yaml
apiVersion: apps/v1beta2
kind: DaemonSet
metadata:
  name: ssd-monitor
spec:
  selector:
    matchLabels:
      app: ssd-monitor
  template:
    metadata:
      labels:
        app: ssd-monitor
    spec:
      nodeSelector:
        disk: ssd
      containers:
      - name: main
        image: luksa/ssd-monitor
```

You’re defining a DaemonSet that will run a pod with a single container based on the `luksa/ssd-monitor` container image. An instance of this pod will be created for each node that has the `disk=ssd` label.

##### Creating the DaemonSet

You’ll create the DaemonSet like you always create resources from a YAML file:

```bash
$ kubectl create -f ssd-monitor-daemonset.yaml
daemonset "ssd-monitor" created
```

Let’s see the created DaemonSet:

```bash
$ kubectl get ds
NAME          DESIRED  CURRENT  READY  UP-TO-DATE  AVAILABLE  NODE-SELECTOR
ssd-monitor   0        0        0      0           0          disk=ssd
```

Those zeroes look strange. Didn’t the DaemonSet deploy any pods? List the pods:

```bash
$ kubectl get po
No resources found.
```

Where are the pods? Do you know what’s going on? Yes, you forgot to label your nodes with the `disk=ssd` label. No problem—you can do that now. The DaemonSet should detect that the nodes’ labels have changed and deploy the pod to all nodes with a matching label. Let’s see if that’s true.

##### Adding the required label to your node(s)

Regardless if you’re using Minikube, GKE, or another multi-node cluster, you’ll need to list the nodes first, because you’ll need to know the node’s name when labeling it:

```bash
$ kubectl get node
NAME       STATUS    AGE       VERSION
minikube   Ready     4d        v1.6.0
```

Now, add the `disk=ssd` label to one of your nodes like this:

```bash
$ kubectl label node minikube disk=ssd
node "minikube" labeled
```

---

##### Note

Replace `minikube` with the name of one of your nodes if you’re not using Minikube.

---

The DaemonSet should have created one pod now. Let’s see:

```bash
$ kubectl get po
NAME                READY     STATUS    RESTARTS   AGE
ssd-monitor-hgxwq   1/1       Running   0          35s
```

Okay; so far so good. If you have multiple nodes and you add the same label to further nodes, you’ll see the DaemonSet spin up pods for each of them.

##### Removing the required label from the node

Now, imagine you’ve made a mistake and have mislabeled one of the nodes. It has a spinning disk drive, not an SSD. What happens if you change the node’s label?

```bash
$ kubectl label node minikube disk=hdd --overwrite
node "minikube" labeled
```

Let’s see if the change has any effect on the pod that was running on that node:

```bash
$ kubectl get po
NAME                READY     STATUS        RESTARTS   AGE
ssd-monitor-hgxwq   1/1       Terminating   0          4m
```

The pod is being terminated. But you knew that was going to happen, right? This wraps up your exploration of DaemonSets, so you may want to delete your `ssd-monitor` DaemonSet. If you still have any other daemon pods running, you’ll see that deleting the DaemonSet deletes those pods as well.

## 4.5. Running pods that perform a single completable task

Up to now, we’ve only talked about pods than need to run continuously. You’ll have cases where you only want to run a task that terminates after completing its work. ReplicationControllers, ReplicaSets, and DaemonSets run continuous tasks that are never considered completed. Processes in such pods are restarted when they exit. But in a completable task, after its process terminates, it should not be restarted again.

### 4.5.1. Introducing the Job resource

Kubernetes includes support for this through the Job resource, which is similar to the other resources we’ve discussed in this chapter, but it allows you to run a pod whose container isn’t restarted when the process running inside finishes successfully. Once it does, the pod is considered complete.

In the event of a node failure, the pods on that node that are managed by a Job will be rescheduled to other nodes the way ReplicaSet pods are. In the event of a failure of the process itself (when the process returns an error exit code), the Job can be configured to either restart the container or not.

[Figure 4.10](/book/kubernetes-in-action/chapter-4/ch04fig10) shows how a pod created by a Job is rescheduled to a new node if the node it was initially scheduled to fails. The figure also shows both a managed pod, which isn’t rescheduled, and a pod backed by a ReplicaSet, which is.

![Figure 4.10. Pods managed by Jobs are rescheduled until they finish successfully.](https://drek4537l1klr.cloudfront.net/luksa/Figures/04fig10_alt.jpg)

For example, Jobs are useful for ad hoc tasks, where it’s crucial that the task finishes properly. You could run the task in an unmanaged pod and wait for it to finish, but in the event of a node failing or the pod being evicted from the node while it is performing its task, you’d need to manually recreate it. Doing this manually doesn’t make sense—especially if the job takes hours to complete.

An example of such a job would be if you had data stored somewhere and you needed to transform and export it somewhere. You’re going to emulate this by running a container image built on top of the `busybox` image, which invokes the `sleep` command for two minutes. I’ve already built the image and pushed it to Docker Hub, but you can peek into its Dockerfile in the book’s code archive.

### 4.5.2. Defining a Job resource

Create the Job manifest as in the following listing.

##### Listing 4.11. A YAML definition of a Job: exporter.yaml

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: batch-job
spec:
  template:
    metadata:
      labels:
        app: batch-job
    spec:
      restartPolicy: OnFailure
      containers:
      - name: main
        image: luksa/batch-job
```

Jobs are part of the `batch` API group and `v1` API version. The YAML defines a resource of type Job that will run the `luksa/batch-job` image, which invokes a process that runs for exactly 120 seconds and then exits.

In a pod’s specification, you can specify what Kubernetes should do when the processes running in the container finish. This is done through the `restartPolicy` pod spec property, which defaults to `Always`. Job pods can’t use the default policy, because they’re not meant to run indefinitely. Therefore, you need to explicitly set the restart policy to either `OnFailure` or `Never`. This setting is what prevents the container from being restarted when it finishes (not the fact that the pod is being managed by a Job resource).

### 4.5.3. Seeing a Job run a pod

After you create this Job with the `kubectl create` command, you should see it start up a pod immediately:

```bash
$ kubectl get jobs
NAME        DESIRED   SUCCESSFUL   AGE
batch-job   1         0            2s

$ kubectl get po
NAME              READY     STATUS    RESTARTS   AGE
batch-job-28qf4   1/1       Running   0          4s
```

After the two minutes have passed, the pod will no longer show up in the pod list and the Job will be marked as completed. By default, completed pods aren’t shown when you list pods, unless you use the `--show-all` (or `-a)` switch:

```bash
$ kubectl get po -a
NAME              READY     STATUS      RESTARTS   AGE
batch-job-28qf4   0/1       Completed   0          2m
```

The reason the pod isn’t deleted when it completes is to allow you to examine its logs; for example:

```bash
$ kubectl logs batch-job-28qf4
Fri Apr 29 09:58:22 UTC 2016 Batch job starting
Fri Apr 29 10:00:22 UTC 2016 Finished succesfully
```

The pod will be deleted when you delete it or the Job that created it. Before you do that, let’s look at the Job resource again:

```bash
$ kubectl get job
NAME        DESIRED   SUCCESSFUL   AGE
batch-job   1         1            9m
```

The Job is shown as having completed successfully. But why is that piece of information shown as a number instead of as `yes` or `true`? And what does the `DESIRED` column indicate?

### 4.5.4. Running multiple pod instances in a Job

Jobs may be configured to create more than one pod instance and run them in parallel or sequentially. This is done by setting the `completions` and the `parallelism` properties in the Job spec.

##### Running job pods sequentially

If you need a Job to run more than once, you set `completions` to how many times you want the Job’s pod to run. The following listing shows an example.

##### Listing 4.12. A Job requiring multiple completions: multi-completion-batch-job.yaml

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: multi-completion-batch-job
spec:
  completions: 5
  template:
    <template is the same as in listing 4.11>
```

This Job will run five pods one after the other. It initially creates one pod, and when the pod’s container finishes, it creates the second pod, and so on, until five pods complete successfully. If one of the pods fails, the Job creates a new pod, so the Job may create more than five pods overall.

##### Running job pods in parallel

Instead of running single Job pods one after the other, you can also make the Job run multiple pods in parallel. You specify how many pods are allowed to run in parallel with the `parallelism` Job spec property, as shown in the following listing.

##### Listing 4.13. Running Job pods in parallel: multi-completion-parallel-batch-job.yaml

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: multi-completion-batch-job
spec:
  completions: 5
  parallelism: 2
  template:
    <same as in listing 4.11>
```

By setting `parallelism` to 2, the Job creates two pods and runs them in parallel:

```bash
$ kubectl get po
NAME                               READY   STATUS     RESTARTS   AGE
multi-completion-batch-job-lmmnk   1/1     Running    0          21s
multi-completion-batch-job-qx4nq   1/1     Running    0          21s
```

As soon as one of them finishes, the Job will run the next pod, until five pods finish successfully.

##### Scaling a Job

You can even change a Job’s `parallelism` property while the Job is running. This is similar to scaling a ReplicaSet or ReplicationController, and can be done with the `kubectl scale` command:

```bash
$ kubectl scale job multi-completion-batch-job --replicas 3
job "multi-completion-batch-job" scaled
```

Because you’ve increased `parallelism` from 2 to 3, another pod is immediately spun up, so three pods are now running.

### 4.5.5. Limiting the time allowed for a Job pod to complete

We need to discuss one final thing about Jobs. How long should the Job wait for a pod to finish? What if the pod gets stuck and can’t finish at all (or it can’t finish fast enough)?

A pod’s time can be limited by setting the `activeDeadlineSeconds` property in the pod spec. If the pod runs longer than that, the system will try to terminate it and will mark the Job as failed.

---

##### Note

You can configure how many times a Job can be retried before it is marked as failed by specifying the `spec.backoffLimit` field in the Job manifest. If you don’t explicitly specify it, it defaults to 6.

---

## 4.6. Scheduling Jobs to run periodically or once in the future

Job resources run their pods immediately when you create the Job resource. But many batch jobs need to be run at a specific time in the future or repeatedly in the specified interval. In Linux- and UNIX-like operating systems, these jobs are better known as cron jobs. Kubernetes supports them, too.

A cron job in Kubernetes is configured by creating a CronJob resource. The schedule for running the job is specified in the well-known cron format, so if you’re familiar with regular cron jobs, you’ll understand Kubernetes’ CronJobs in a matter of seconds.

At the configured time, Kubernetes will create a Job resource according to the Job template configured in the CronJob object. When the Job resource is created, one or more pod replicas will be created and started according to the Job’s pod template, as you learned in the previous section. There’s nothing more to it.

Let’s look at how to create CronJobs.

### 4.6.1. Creating a CronJob

Imagine you need to run the batch job from your previous example every 15 minutes. To do that, create a CronJob resource with the following specification.

##### Listing 4.14. YAML for a CronJob resource: cronjob.yaml

```yaml
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: batch-job-every-fifteen-minutes
spec:
  schedule: "0,15,30,45 * * * *"
  jobTemplate:
    spec:
      template:
        metadata:
          labels:
            app: periodic-batch-job
        spec:
          restartPolicy: OnFailure
          containers:
          - name: main
            image: luksa/batch-job
```

As you can see, it’s not too complicated. You’ve specified a schedule and a template from which the Job objects will be created.

##### Configuring the schedule

If you’re unfamiliar with the cron schedule format, you’ll find great tutorials and explanations online, but as a quick introduction, from left to right, the schedule contains the following five entries:

- Minute
- Hour
- Day of month
- Month
- Day of week.

In the example, you want to run the job every 15 minutes, so the schedule needs to be `"0,15,30,45 * * * *"`, which means at the 0, 15, 30 and 45 minutes mark of every hour (first asterisk), of every day of the month (second asterisk), of every month (third asterisk) and on every day of the week (fourth asterisk).

If, instead, you wanted it to run every 30 minutes, but only on the first day of the month, you’d set the schedule to `"0,30 * 1 * *"`, and if you want it to run at 3AM every Sunday, you’d set it to `"0 3 * * 0"` (the last zero stands for Sunday).

##### Configuring the Job template

A CronJob creates Job resources from the `jobTemplate` property configured in the CronJob spec, so refer to [section 4.5](/book/kubernetes-in-action/chapter-4/ch04lev1sec5) for more information on how to configure it.

### 4.6.2. Understanding how scheduled jobs are run

Job resources will be created from the CronJob resource at approximately the scheduled time. The Job then creates the pods.

It may happen that the Job or pod is created and run relatively late. You may have a hard requirement for the job to not be started too far over the scheduled time. In that case, you can specify a deadline by specifying the `startingDeadlineSeconds` field in the CronJob specification as shown in the following listing.

##### Listing 4.15. Specifying a `startingDeadlineSeconds` for a CronJob

```yaml
apiVersion: batch/v1beta1
kind: CronJob
spec:
  schedule: "0,15,30,45 * * * *"
  startingDeadlineSeconds: 15
  ...
```

In the example in [listing 4.15](/book/kubernetes-in-action/chapter-4/ch04ex15), one of the times the job is supposed to run is 10:30:00. If it doesn’t start by 10:30:15 for whatever reason, the job will not run and will be shown as Failed.

In normal circumstances, a CronJob always creates only a single Job for each execution configured in the schedule, but it may happen that two Jobs are created at the same time, or none at all. To combat the first problem, your jobs should be idempotent (running them multiple times instead of once shouldn’t lead to unwanted results). For the second problem, make sure that the next job run performs any work that should have been done by the previous (missed) run.

## 4.7. Summary

You’ve now learned how to keep pods running and have them rescheduled in the event of node failures. You should now know that

- You can specify a liveness probe to have Kubernetes restart your container as soon as it’s no longer healthy (where the app defines what’s considered healthy).
- Pods shouldn’t be created directly, because they will not be re-created if they’re deleted by mistake, if the node they’re running on fails, or if they’re evicted from the node.
- ReplicationControllers always keep the desired number of pod replicas running.
- Scaling pods horizontally is as easy as changing the desired replica count on a ReplicationController.
- Pods aren’t owned by the ReplicationControllers and can be moved between them if necessary.
- A ReplicationController creates new pods from a pod template. Changing the template has no effect on existing pods.
- ReplicationControllers should be replaced with ReplicaSets and Deployments, which provide the same functionality, but with additional powerful features.
- ReplicationControllers and ReplicaSets schedule pods to random cluster nodes, whereas DaemonSets make sure every node runs a single instance of a pod defined in the DaemonSet.
- Pods that perform a batch task should be created through a Kubernetes Job resource, not directly or through a ReplicationController or similar object.
- Jobs that need to run sometime in the future can be created through CronJob resources.
