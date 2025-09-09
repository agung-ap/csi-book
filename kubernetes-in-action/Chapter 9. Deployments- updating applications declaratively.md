# Chapter 9. Deployments: updating applications declaratively

### **This chapter covers**

- Replacing pods with newer versions
- Updating managed pods
- Updating pods declaratively using Deployment resources
- Performing rolling updates
- Automatically blocking rollouts of bad versions
- Controlling the rate of the rollout
- Reverting pods to a previous version

You now know how to package your app components into containers, group them into pods, provide them with temporary or permanent storage, pass both secret and non-secret config data to them, and allow pods to find and talk to each other. You know how to run a full-fledged system composed of independently running smaller components—microservices, if you will. Is there anything else?

Eventually, you’re going to want to update your app. This chapter covers how to update apps running in a Kubernetes cluster and how Kubernetes helps you move toward a true zero-downtime update process. Although this can be achieved using only ReplicationControllers or ReplicaSets, Kubernetes also provides a Deployment resource that sits on top of ReplicaSets and enables declarative application updates. If you’re not completely sure what that means, keep reading—it’s not as complicated as it sounds.

## 9.1. Updating applications running in pods

Let’s start off with a simple example. Imagine having a set of pod instances providing a service to other pods and/or external clients. After reading this book up to this point, you likely recognize that these pods are backed by a ReplicationController or a ReplicaSet. A Service also exists through which clients (apps running in other pods or external clients) access the pods. This is how a basic application looks in Kubernetes (shown in [figure 9.1](/book/kubernetes-in-action/chapter-9/ch09fig01)).

![Figure 9.1. The basic outline of an application running in Kubernetes](https://drek4537l1klr.cloudfront.net/luksa/Figures/09fig01.jpg)

Initially, the pods run the first version of your application—let’s suppose its image is tagged as `v1`. You then develop a newer version of the app and push it to an image repository as a new image, tagged as `v2`. You’d next like to replace all the pods with this new version. Because you can’t change an existing pod’s image after the pod is created, you need to remove the old pods and replace them with new ones running the new image.

You have two ways of updating all those pods. You can do one of the following:

- Delete all existing pods first and then start the new ones.
- Start new ones and, once they’re up, delete the old ones. You can do this either by adding all the new pods and then deleting all the old ones at once, or sequentially, by adding new pods and removing old ones gradually.

Both these strategies have their benefits and drawbacks. The first option would lead to a short period of time when your application is unavailable. The second option requires your app to handle running two versions of the app at the same time. If your app stores data in a data store, the new version shouldn’t modify the data schema or the data in such a way that breaks the previous version.

How do you perform these two update methods in Kubernetes? First, let’s look at how to do this manually; then, once you know what’s involved in the process, you’ll learn how to have Kubernetes perform the update automatically.

### 9.1.1. Deleting old pods and replacing them with new ones

You already know how to get a ReplicationController to replace all its pod instances with pods running a new version. You probably remember the pod template of a ReplicationController can be updated at any time. When the ReplicationController creates new instances, it uses the updated pod template to create them.

If you have a ReplicationController managing a set of `v1` pods, you can easily replace them by modifying the pod template so it refers to version `v2` of the image and then deleting the old pod instances. The ReplicationController will notice that no pods match its label selector and it will spin up new instances. The whole process is shown in [figure 9.2](/book/kubernetes-in-action/chapter-9/ch09fig02).

![Figure 9.2. Updating pods by changing a ReplicationController’s pod template and deleting old Pods](https://drek4537l1klr.cloudfront.net/luksa/Figures/09fig02_alt.jpg)

This is the simplest way to update a set of pods, if you can accept the short downtime between the time the old pods are deleted and new ones are started.

### 9.1.2. Spinning up new pods and then deleting the old ones

If you don’t want to see any downtime and your app supports running multiple versions at once, you can turn the process around and first spin up all the new pods and only then delete the old ones. This will require more hardware resources, because you’ll have double the number of pods running at the same time for a short while.

This is a slightly more complex method compared to the previous one, but you should be able to do it by combining what you’ve learned about ReplicationControllers and Services so far.

##### Switching from the old to the new version at once

Pods are usually fronted by a Service. It’s possible to have the Service front only the initial version of the pods while you bring up the pods running the new version. Then, once all the new pods are up, you can change the Service’s label selector and have the Service switch over to the new pods, as shown in [figure 9.3](/book/kubernetes-in-action/chapter-9/ch09fig03). This is called a *blue-green deployment*. After switching over, and once you’re sure the new version functions correctly, you’re free to delete the old pods by deleting the old ReplicationController.

---

##### Note

You can change a Service’s pod selector with the `kubectl set selector` command.

---

![Figure 9.3. Switching a Service from the old pods to the new ones](https://drek4537l1klr.cloudfront.net/luksa/Figures/09fig03_alt.jpg)

##### Performing a rolling update

Instead of bringing up all the new pods and deleting the old pods at once, you can also perform a rolling update, which replaces pods step by step. You do this by slowly scaling down the previous ReplicationController and scaling up the new one. In this case, you’ll want the Service’s pod selector to include both the old and the new pods, so it directs requests toward both sets of pods. See [figure 9.4](/book/kubernetes-in-action/chapter-9/ch09fig04).

![Figure 9.4. A rolling update of pods using two ReplicationControllers](https://drek4537l1klr.cloudfront.net/luksa/Figures/09fig04_alt.jpg)

Doing a rolling update manually is laborious and error-prone. Depending on the number of replicas, you’d need to run a dozen or more commands in the proper order to perform the update process. Luckily, Kubernetes allows you to perform the rolling update with a single command. You’ll learn how in the next section.

## 9.2. Performing an automatic rolling update with a ReplicationController

Instead of performing rolling updates using ReplicationControllers manually, you can have `kubectl` perform them. Using `kubectl` to perform the update makes the process much easier, but, as you’ll see later, this is now an outdated way of updating apps. Nevertheless, we’ll walk through this option first, because it was historically the first way of doing an automatic rolling update, and also allows us to discuss the process without introducing too many additional concepts.

### 9.2.1. Running the initial version of the app

Obviously, before you can update an app, you need to have an app deployed. You’re going to use a slightly modified version of the kubia NodeJS app you created in [chapter 2](/book/kubernetes-in-action/chapter-2/ch02) as your initial version. In case you don’t remember what it does, it’s a simple web-app that returns the pod’s hostname in the HTTP response.

##### Creating the v1 app

You’ll change the app so it also returns its version number in the response, which will allow you to distinguish between the different versions you’re about to build. I’ve already built and pushed the app image to Docker Hub under `luksa/kubia:v1`. The following listing shows the app’s code.

##### Listing 9.1. The `v1` version of our app: v1/app.js

```javascript
const http = require('http');
const os = require('os');

console.log("Kubia server starting...");
var handler = function(request, response) {
  console.log("Received request from " + request.connection.remoteAddress);
  response.writeHead(200);
  response.end("This is v1 running in pod " + os.hostname() + "\n");
};
var www = http.createServer(handler);
www.listen(8080);
```

##### Running the app and exposing it through a service using a single YAML file

To run your app, you’ll create a ReplicationController and a `LoadBalancer` Service to enable you to access the app externally. This time, rather than create these two resources separately, you’ll create a single YAML for both of them and post it to the Kubernetes API with a single `kubectl create` command. A YAML manifest can contain multiple objects delimited with a line containing three dashes, as shown in the following listing.

##### Listing 9.2. A YAML containing an RC and a Service: kubia-rc-and-service-v1.yaml

```yaml
apiVersion: v1
kind: ReplicationController
metadata:
  name: kubia-v1
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
---
apiVersion: v1
kind: Service
metadata:
  name: kubia
spec:
  type: LoadBalancer
  selector:
    app: kubia
  ports:
  - port: 80
    targetPort: 8080
```

The YAML defines a ReplicationController called `kubia-v1` and a Service called `kubia`. Go ahead and post the YAML to Kubernetes. After a while, your three `v1` pods and the load balancer should all be running, so you can look up the Service’s external IP and start hitting the service with `curl`, as shown in the following listing.

##### Listing 9.3. Getting the Service’s external IP and hitting the service in a loop with `curl`

```bash
$ kubectl get svc kubia
NAME      CLUSTER-IP     EXTERNAL-IP       PORT(S)         AGE
kubia     10.3.246.195   130.211.109.222   80:32143/TCP    5m
$ while true; do curl http://130.211.109.222; done
This is v1 running in pod kubia-v1-qr192
This is v1 running in pod kubia-v1-kbtsk
This is v1 running in pod kubia-v1-qr192
This is v1 running in pod kubia-v1-2321o
...
```

---

##### Note

If you’re using Minikube or any other Kubernetes cluster where load balancer services aren’t supported, you can use the Service’s node port to access the app. This was explained in [chapter 5](../Text/05.html#ch05).

---

### 9.2.2. Performing a rolling update with kubectl

Next you’ll create version 2 of the app. To keep things simple, all you’ll do is change the response to say, “This is v2”:

```
response.end("This is v2 running in pod " + os.hostname() + "\n");
```

This new version is available in the image `luksa/kubia:v2` on Docker Hub, so you don’t need to build it yourself.

---

##### **Pushing updates to the same image tag**

Modifying an app and pushing the changes to the same image tag isn’t a good idea, but we all tend to do that during development. If you’re modifying the `latest` tag, that’s not a problem, but when you’re tagging an image with a different tag (for example, tag `v1` instead of `latest`), once the image is pulled by a worker node, the image will be stored on the node and not pulled again when a new pod using the same image is run (at least that’s the default policy for pulling images).

That means any changes you make to the image won’t be picked up if you push them to the same tag. If a new pod is scheduled to the same node, the Kubelet will run the old version of the image. On the other hand, nodes that haven’t run the old version will pull and run the new image, so you might end up with two different versions of the pod running. To make sure this doesn’t happen, you need to set the container’s `imagePullPolicy` property to `Always`.

You need to be aware that the default `imagePullPolicy` depends on the image tag. If a container refers to the `latest` tag (either explicitly or by not specifying the tag at all), `imagePullPolicy` defaults to `Always`, but if the container refers to any other tag, the policy defaults to `IfNotPresent`.

When using a tag other than `latest`, you need to set the `imagePullPolicy` properly if you make changes to an image without changing the tag. Or better yet, make sure you always push changes to an image under a new tag.

---

Keep the `curl` loop running and open another terminal, where you’ll get the rolling update started. To perform the update, you’ll run the `kubectl rolling-update` command. All you need to do is tell it which ReplicationController you’re replacing, give a name for the new ReplicationController, and specify the new image you’d like to replace the original one with. The following listing shows the full command for performing the rolling update.

##### Listing 9.4. Initiating a rolling-update of a ReplicationController using `kubectl`

```bash
$ kubectl rolling-update kubia-v1 kubia-v2 --image=luksa/kubia:v2
Created kubia-v2
Scaling up kubia-v2 from 0 to 3, scaling down kubia-v1 from 3 to 0 (keep 3
     pods available, don't exceed 4 pods)
...
```

Because you’re replacing ReplicationController `kubia-v1` with one running version 2 of your kubia app, you’d like the new ReplicationController to be called `kubia-v2` and use the `luksa/kubia:v2` container image.

When you run the command, a new ReplicationController called `kubia-v2` is created immediately. The state of the system at this point is shown in [figure 9.5](/book/kubernetes-in-action/chapter-9/ch09fig05).

![Figure 9.5. The state of the system immediately after starting the rolling update](https://drek4537l1klr.cloudfront.net/luksa/Figures/09fig05_alt.jpg)

The new ReplicationController’s pod template references the `luksa/kubia:v2` image and its initial desired replica count is set to 0, as you can see in the following listing.

##### Listing 9.5. Describing the new ReplicationController created by the rolling update

```bash
$ kubectl describe rc kubia-v2
Name:       kubia-v2
Namespace:  default
Image(s):   luksa/kubia:v2                                           #1
Selector:   app=kubia,deployment=757d16a0f02f6a5c387f2b5edb62b155
Labels:     app=kubia
Replicas:   0 current / 0 desired                                    #2
...
```

##### Understanding the steps performed by kubectl before the rolling update commences

`kubectl` created this ReplicationController by copying the `kubia-v1` controller and changing the image in its pod template. If you look closely at the controller’s label selector, you’ll notice it has been modified, too. It includes not only a simple `app=kubia` label, but also an additional `deployment` label which the pods must have in order to be managed by this ReplicationController.

You probably know this already, but this is necessary to avoid having both the new and the old ReplicationControllers operating on the same set of pods. But even if pods created by the new controller have the additional `deployment` label in addition to the `app=kubia` label, doesn’t this mean they’ll be selected by the first ReplicationController’s selector, because it’s set to `app=kubia`?

Yes, that’s exactly what would happen, but there’s a catch. The rolling-update process has modified the selector of the first ReplicationController, as well:

```bash
$ kubectl describe rc kubia-v1
Name:       kubia-v1
Namespace:  default
Image(s):   luksa/kubia:v1
Selector:   app=kubia,deployment=3ddd307978b502a5b975ed4045ae4964-orig
```

Okay, but doesn’t this mean the first controller now sees zero pods matching its selector, because the three pods previously created by it contain only the `app=kubia` label? No, because `kubectl` had also modified the labels of the live pods just before modifying the ReplicationController’s selector:

```bash
$ kubectl get po --show-labels
NAME            READY  STATUS   RESTARTS  AGE  LABELS
kubia-v1-m33mv  1/1    Running  0         2m   app=kubia,deployment=3ddd...
kubia-v1-nmzw9  1/1    Running  0         2m   app=kubia,deployment=3ddd...
kubia-v1-cdtey  1/1    Running  0         2m   app=kubia,deployment=3ddd...
```

If this is getting too complicated, examine [figure 9.6](/book/kubernetes-in-action/chapter-9/ch09fig06), which shows the pods, their labels, and the two ReplicationControllers, along with their pod selectors.

![Figure 9.6. Detailed state of the old and new ReplicationControllers and pods at the start of a rolling update](https://drek4537l1klr.cloudfront.net/luksa/Figures/09fig06_alt.jpg)

`kubectl` had to do all this before even starting to scale anything up or down. Now imagine doing the rolling update manually. It’s easy to see yourself making a mistake here and possibly having the ReplicationController kill off all your pods—pods that are actively serving your production clients!

##### Replacing old pods with new ones by scaling the two ReplicationControllers

After setting up all this, `kubectl` starts replacing pods by first scaling up the new controller to 1. The controller thus creates the first `v2` pod. `kubectl` then scales down the old ReplicationController by 1. This is shown in the next two lines printed by `kubectl`:

```
Scaling kubia-v2 up to 1
Scaling kubia-v1 down to 2
```

Because the Service is targeting all pods with the `app=kubia` label, you should start seeing your `curl` requests redirected to the new `v2` pod every few loop iterations:

```
This is v2 running in pod kubia-v2-nmzw9      #1
This is v1 running in pod kubia-v1-kbtsk
This is v1 running in pod kubia-v1-2321o
This is v2 running in pod kubia-v2-nmzw9      #1
...
```

[Figure 9.7](/book/kubernetes-in-action/chapter-9/ch09fig07) shows the current state of the system.

![Figure 9.7. The Service is redirecting requests to both the old and new pods during the rolling update.](https://drek4537l1klr.cloudfront.net/luksa/Figures/09fig07_alt.jpg)

As `kubectl` continues with the rolling update, you start seeing a progressively bigger percentage of requests hitting `v2` pods, as the update process deletes more of the `v1` pods and replaces them with those running your new image. Eventually, the original ReplicationController is scaled to zero, causing the last `v1` pod to be deleted, which means the Service will now be backed by `v2` pods only. At that point, `kubectl` will delete the original ReplicationController and the update process will be finished, as shown in the following listing.

##### Listing 9.6. The final steps performed by `kubectl rolling-update`

```
...
Scaling kubia-v2 up to 2
Scaling kubia-v1 down to 1
Scaling kubia-v2 up to 3
Scaling kubia-v1 down to 0
Update succeeded. Deleting kubia-v1
replicationcontroller "kubia-v1" rolling updated to "kubia-v2"
```

You’re now left with only the `kubia-v2` ReplicationController and three `v2` pods. All throughout this update process, you’ve hit your service and gotten a response every time. You have, in fact, performed a rolling update with zero downtime.

### 9.2.3. Understanding why kubectl rolling-update is now obsolete

At the beginning of this section, I mentioned an even better way of doing updates than through `kubectl rolling-update`. What’s so wrong with this process that a better one had to be introduced?

Well, for starters, I, for one, don’t like Kubernetes modifying objects I’ve created. Okay, it’s perfectly fine for the scheduler to assign a node to my pods after I create them, but Kubernetes modifying the labels of my pods and the label selectors of my ReplicationController`s` is something that I don’t expect and could cause me to go around the office yelling at my colleagues, “Who’s been messing with my controllers!?!?”

But even more importantly, if you’ve paid close attention to the words I’ve used, you probably noticed that all this time I said explicitly that the `kubectl` client was the one performing all these steps of the rolling update.

You can see this by turning on verbose logging with the `--v` option when triggering the rolling update:

```bash
$ kubectl rolling-update kubia-v1 kubia-v2 --image=luksa/kubia:v2 --v 6
```

---

##### Tip

Using the `--v 6` option increases the logging level enough to let you see the requests `kubectl` is sending to the API server.

---

Using this option, `kubectl` will print out each HTTP request it sends to the Kubernetes API server. You’ll see PUT requests to

```
/api/v1/namespaces/default/replicationcontrollers/kubia-v1
```

which is the RESTful URL representing your `kubia-v1` ReplicationController resource. These requests are the ones scaling down your ReplicationController, which shows that the `kubectl` client is the one doing the scaling, instead of it being performed by the Kubernetes master.

---

##### Tip

Use the verbose logging option when running other `kubectl` commands, to learn more about the communication between `kubectl` and the API server.

---

But why is it such a bad thing that the update process is being performed by the client instead of on the server? Well, in your case, the update went smoothly, but what if you lost network connectivity while `kubectl` was performing the update? The update process would be interrupted mid-way. Pods and ReplicationControllers would end up in an intermediate state.

Another reason why performing an update like this isn’t as good as it could be is because it’s imperative. Throughout this book, I’ve stressed how Kubernetes is about you telling it the desired state of the system and having Kubernetes achieve that state on its own, by figuring out the best way to do it. This is how pods are deployed and how pods are scaled up and down. You never tell Kubernetes to add an additional pod or remove an excess one—you change the number of desired replicas and that’s it.

Similarly, you will also want to change the desired image tag in your pod definitions and have Kubernetes replace the pods with new ones running the new image. This is exactly what drove the introduction of a new resource called a Deployment, which is now the preferred way of deploying applications in Kubernetes.

## 9.3. Using Deployments for updating apps declaratively

A Deployment is a higher-level resource meant for deploying applications and updating them declaratively, instead of doing it through a ReplicationController or a ReplicaSet, which are both considered lower-level concepts.

When you create a Deployment, a ReplicaSet resource is created underneath (eventually more of them). As you may remember from [chapter 4](/book/kubernetes-in-action/chapter-4/ch04), ReplicaSets are a new generation of ReplicationControllers, and should be used instead of them. Replica-Sets replicate and manage pods, as well. When using a Deployment, the actual pods are created and managed by the Deployment’s ReplicaSets, not by the Deployment directly (the relationship is shown in [figure 9.8](/book/kubernetes-in-action/chapter-9/ch09fig08)).

![Figure 9.8. A Deployment is backed by a ReplicaSet, which supervises the deployment’s pods.](https://drek4537l1klr.cloudfront.net/luksa/Figures/09fig08.jpg)

You might wonder why you’d want to complicate things by introducing another object on top of a ReplicationController or ReplicaSet, when they’re what suffices to keep a set of pod instances running. As the rolling update example in [section 9.2](/book/kubernetes-in-action/chapter-9/ch09lev1sec2) demonstrates, when updating the app, you need to introduce an additional ReplicationController and coordinate the two controllers to dance around each other without stepping on each other’s toes. You need something coordinating this dance. A Deployment resource takes care of that (it’s not the Deployment resource itself, but the controller process running in the Kubernetes control plane that does that; but we’ll get to that in [chapter 11](/book/kubernetes-in-action/chapter-11/ch11)).

Using a Deployment instead of the lower-level constructs makes updating an app much easier, because you’re defining the desired state through the single Deployment resource and letting Kubernetes take care of the rest, as you’ll see in the next few pages.

### 9.3.1. Creating a Deployment

Creating a Deployment isn’t that different from creating a ReplicationController. A Deployment is also composed of a label selector, a desired replica count, and a pod template. In addition to that, it also contains a field, which specifies a deployment strategy that defines how an update should be performed when the Deployment resource is modified.

##### Creating a Deployment manifest

Let’s see how to use the `kubia-v1` ReplicationController example from earlier in this chapter and modify it so it describes a Deployment instead of a ReplicationController. As you’ll see, this requires only three trivial changes. The following listing shows the modified YAML.

##### Listing 9.7. A Deployment definition: kubia-deployment-v1.yaml

```yaml
apiVersion: apps/v1beta1
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
```

---

##### Note

You’ll find an older version of the Deployment resource in `extensions/ v1beta1`, and a newer one in `apps/v1beta2` with different required fields and different defaults. Be aware that `kubectl explain` shows the older version.

---

Because the ReplicationController from before was managing a specific version of the pods, you called it `kubia-v1`. A Deployment, on the other hand, is above that version stuff. At a given point in time, the Deployment can have multiple pod versions running under its wing, so its name shouldn’t reference the app version.

##### Creating the Deployment resource

Before you create this Deployment, make sure you delete any ReplicationControllers and pods that are still running, but keep the `kubia` Service for now. You can use the `--all` switch to delete all those ReplicationControllers like this:

```bash
$ kubectl delete rc --all
```

You’re now ready to create the Deployment:

```bash
$ kubectl create -f kubia-deployment-v1.yaml --record
deployment "kubia" created
```

---

##### Tip

Be sure to include the `--record` command-line option when creating it. This records the command in the revision history, which will be useful later.

---

##### Displaying the status of the deployment rollout

You can use the usual `kubectl get deployment` and the `kubectl describe deployment` commands to see details of the Deployment, but let me point you to an additional command, which is made specifically for checking a Deployment’s status:

```bash
$ kubectl rollout status deployment kubia
deployment kubia successfully rolled out
```

According to this, the Deployment has been successfully rolled out, so you should see the three pod replicas up and running. Let’s see:

```bash
$ kubectl get po
NAME                     READY     STATUS    RESTARTS   AGE
kubia-1506449474-otnnh   1/1       Running   0          14s
kubia-1506449474-vmn7s   1/1       Running   0          14s
kubia-1506449474-xis6m   1/1       Running   0          14s
```

##### Understanding how Deployments create ReplicaSets, which then create the pods

Take note of the names of these pods. Earlier, when you used a ReplicationController to create pods, their names were composed of the name of the controller plus a randomly generated string (for example, `kubia-v1-m33mv`). The three pods created by the Deployment include an additional numeric value in the middle of their names. What is that exactly?

The number corresponds to the hashed value of the pod template in the Deployment and the ReplicaSet managing these pods. As we said earlier, a Deployment doesn’t manage pods directly. Instead, it creates ReplicaSets and leaves the managing to them, so let’s look at the ReplicaSet created by your Deployment:

```bash
$ kubectl get replicasets
NAME               DESIRED   CURRENT   AGE
kubia-1506449474   3         3         10s
```

The ReplicaSet’s name also contains the hash value of its pod template. As you’ll see later, a Deployment creates multiple ReplicaSets—one for each version of the pod template. Using the hash value of the pod template like this allows the Deployment to always use the same (possibly existing) ReplicaSet for a given version of the pod template.

##### Accessing the pods through the service

With the three replicas created by this ReplicaSet now running, you can use the Service you created a while ago to access them, because you made the new pods’ labels match the Service’s label selector.

Up until this point, you probably haven’t seen a good-enough reason why you should use Deployments over ReplicationControllers. Luckily, creating a Deployment also hasn’t been any harder than creating a ReplicationController. Now, you’ll start doing things with this Deployment, which will make it clear why Deployments are superior. This will become clear in the next few moments, when you see how updating the app through a Deployment resource compares to updating it through a ReplicationController.

### 9.3.2. Updating a Deployment

Previously, when you ran your app using a ReplicationController, you had to explicitly tell Kubernetes to perform the update by running `kubectl rolling-update`. You even had to specify the name for the new ReplicationController that should replace the old one. Kubernetes replaced all the original pods with new ones and deleted the original ReplicationController at the end of the process. During the process, you basically had to stay around, keeping your terminal open and waiting for `kubectl` to finish the rolling update.

Now compare this to how you’re about to update a Deployment. The only thing you need to do is modify the pod template defined in the Deployment resource and Kubernetes will take all the steps necessary to get the actual system state to what’s defined in the resource. Similar to scaling a ReplicationController or ReplicaSet up or down, all you need to do is reference a new image tag in the Deployment’s pod template and leave it to Kubernetes to transform your system so it matches the new desired state.

##### Understanding the available deployment strategies

How this new state should be achieved is governed by the deployment strategy configured on the Deployment itself. The default strategy is to perform a rolling update (the strategy is called `RollingUpdate`). The alternative is the `Recreate` strategy, which deletes all the old pods at once and then creates new ones, similar to modifying a ReplicationController’s pod template and then deleting all the pods (we talked about this in [section 9.1.1](/book/kubernetes-in-action/chapter-9/ch09lev2sec1)).

The `Recreate` strategy causes all old pods to be deleted before the new ones are created. Use this strategy when your application doesn’t support running multiple versions in parallel and requires the old version to be stopped completely before the new one is started. This strategy does involve a short period of time when your app becomes completely unavailable.

The `RollingUpdate` strategy, on the other hand, removes old pods one by one, while adding new ones at the same time, keeping the application available throughout the whole process, and ensuring there’s no drop in its capacity to handle requests. This is the default strategy. The upper and lower limits for the number of pods above or below the desired replica count are configurable. You should use this strategy only when your app can handle running both the old and new version at the same time.

##### Slowing down the rolling update for demo purposes

In the next exercise, you’ll use the `RollingUpdate` strategy, but you need to slow down the update process a little, so you can see that the update is indeed performed in a rolling fashion. You can do that by setting the `minReadySeconds` attribute on the Deployment. We’ll explain what this attribute does by the end of this chapter. For now, set it to 10 seconds with the `kubectl patch` command.

```bash
$ kubectl patch deployment kubia -p '{"spec": {"minReadySeconds": 10}}'
"kubia" patched
```

---

##### Tip

The `kubectl patch` command is useful for modifying a single property or a limited number of properties of a resource without having to edit its definition in a text editor.

---

You used the patch command to change the spec of the Deployment. This doesn’t cause any kind of update to the pods, because you didn’t change the pod template. Changing other Deployment properties, like the desired replica count or the deployment strategy, also doesn’t trigger a rollout, because it doesn’t affect the existing individual pods in any way.

##### Triggering the rolling update

If you’d like to track the update process as it progresses, first run the `curl` loop again in another terminal to see what’s happening with the requests (don’t forget to replace the IP with the actual external IP of your service):

```bash
$ while true; do curl http://130.211.109.222; done
```

To trigger the actual rollout, you’ll change the image used in the single pod container to `luksa/kubia:v2`. Instead of editing the whole YAML of the Deployment object or using the `patch` command to change the image, you’ll use the `kubectl set image` command, which allows changing the image of any resource that contains a container (ReplicationControllers, ReplicaSets, Deployments, and so on). You’ll use it to modify your Deployment like this:

```bash
$ kubectl set image deployment kubia nodejs=luksa/kubia:v2
deployment "kubia" image updated
```

When you execute this command, you’re updating the `kubia` Deployment’s pod template so the image used in its `nodejs` container is changed to `luksa/kubia:v2` (from `:v1`). This is shown in [figure 9.9](/book/kubernetes-in-action/chapter-9/ch09fig09).

![Figure 9.9. Updating a Deployment’s pod template to point to a new image](https://drek4537l1klr.cloudfront.net/luksa/Figures/09fig09_alt.jpg)

---

##### **Ways of modifying Deployments and other resources**

Over the course of this book, you’ve learned several ways how to modify an existing object. Let’s list all of them together to refresh your memory.

##### Table 9.1. Modifying an existing resource in Kubernetes[(view table figure)](https://drek4537l1klr.cloudfront.net/luksa/HighResolutionFigures/table_9-1.png)

Method

What it does

kubectl editOpens the object’s manifest in your default editor. After making changes, saving the file, and exiting the editor, the object is updated. Example: kubectl edit deployment kubiakubectl patchModifies individual properties of an object. Example: kubectl patch deployment kubia -p '{"spec": {"template": {"spec": {"containers": [{"name": "nodejs", "image": "luksa/kubia:v2"}]}}}}'kubectl applyModifies the object by applying property values from a full YAML or JSON file. If the object specified in the YAML/JSON doesn’t exist yet, it’s created. The file needs to contain the full definition of the resource (it can’t include only the fields you want to update, as is the case with kubectl patch). Example: kubectl apply -f kubia-deployment-v2.yamlkubectl replaceReplaces the object with a new one from a YAML/JSON file. In contrast to the apply command, this command requires the object to exist; otherwise it prints an error. Example: kubectl replace -f kubia-deployment-v2.yamlkubectl set imageChanges the container image defined in a Pod, ReplicationController’s template, Deployment, DaemonSet, Job, or ReplicaSet. Example: kubectl set image deployment kubia nodejs=luksa/kubia:v2All these methods are equivalent as far as Deployments go. What they do is change the Deployment’s specification. This change then triggers the rollout process.

---

If you’ve run the `curl` loop, you’ll see requests initially hitting only the `v1` pods; then more and more of them hit the v2 pod`s` until, finally, all of them hit only the remaining `v2` pods, after all `v1` pods are deleted. This works much like the rolling update performed by `kubectl`.

##### Understanding the awesomeness of Deployments

Let’s think about what has happened. By changing the pod template in your Deployment resource, you’ve updated your app to a newer version—by changing a single field!

The controllers running as part of the Kubernetes control plane then performed the update. The process wasn’t performed by the `kubectl` client, like it was when you used `kubectl rolling-update`. I don’t know about you, but I think that’s simpler than having to run a special command telling Kubernetes what to do and then waiting around for the process to be completed.

---

##### Note

Be aware that if the pod template in the Deployment references a ConfigMap (or a Secret), modifying the ConfigMap will not trigger an update. One way to trigger an update when you need to modify an app’s config is to create a new ConfigMap and modify the pod template so it references the new ConfigMap.

---

The events that occurred below the Deployment’s surface during the update are similar to what happened during the `kubectl rolling-update`. An additional ReplicaSet was created and it was then scaled up slowly, while the previous ReplicaSet was scaled down to zero (the initial and final states are shown in [figure 9.10](/book/kubernetes-in-action/chapter-9/ch09fig10)).

![Figure 9.10. A Deployment at the start and end of a rolling update](https://drek4537l1klr.cloudfront.net/luksa/Figures/09fig10_alt.jpg)

You can still see the old ReplicaSet next to the new one if you list them:

```bash
$ kubectl get rs
NAME               DESIRED   CURRENT   AGE
kubia-1506449474   0         0         24m
kubia-1581357123   3         3         23m
```

Similar to ReplicationControllers, all your new pods are now managed by the new ReplicaSet. Unlike before, the old ReplicaSet is still there, whereas the old Replication-Controller was deleted at the end of the rolling-update process. You’ll soon see what the purpose of this inactive ReplicaSet is.

But you shouldn’t care about ReplicaSets here, because you didn’t create them directly. You created and operated only on the Deployment resource; the underlying ReplicaSets are an implementation detail. You’ll agree that managing a single Deployment object is much easier compared to dealing with and keeping track of multiple ReplicationControllers.

Although this difference may not be so apparent when everything goes well with a rollout, it becomes much more obvious when you hit a problem during the rollout process. Let’s simulate one problem right now.

### 9.3.3. Rolling back a deployment

You’re currently running version `v2` of your image, so you’ll need to prepare version 3 first.

##### Creating version 3 of your app

In version 3, you’ll introduce a bug that makes your app handle only the first four requests properly. All requests from the fifth request onward will return an internal server error (HTTP status code 500). You’ll simulate this by adding an `if` statement at the beginning of the handler function. The following listing shows the new code, with all required changes shown in bold.

##### Listing 9.8. Version 3 of our app (a broken version): v3/app.js

```javascript
const http = require('http');
const os = require('os');

var requestCount = 0;

console.log("Kubia server starting...");

var handler = function(request, response) {
  console.log("Received request from " + request.connection.remoteAddress);
  if (++requestCount >= 5) {
    response.writeHead(500);
    response.end("Some internal error has occurred! This is pod " + os.hostname() + "\n");
    return;
  }
  response.writeHead(200);
  response.end("This is v3 running in pod " + os.hostname() + "\n");
};

var www = http.createServer(handler);
www.listen(8080);
```

As you can see, on the fifth and all subsequent requests, the code returns a 500 error with the message “Some internal error has occurred...”

##### Deploying version 3

I’ve made the `v3` version of the image available as `luksa/kubia:v3`. You’ll deploy this new version by changing the image in the Deployment specification again:

```bash
$ kubectl set image deployment kubia nodejs=luksa/kubia:v3
deployment "kubia" image updated
```

You can follow the progress of the rollout with `kubectl rollout status`:

```bash
$ kubectl rollout status deployment kubia
Waiting for rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for rollout to finish: 1 old replicas are pending termination...
deployment "kubia" successfully rolled out
```

The new version is now live. As the following listing shows, after a few requests, your web clients start receiving errors.

##### Listing 9.9. Hitting your broken version 3

```bash
$ while true; do curl http://130.211.109.222; done
This is v3 running in pod kubia-1914148340-lalmx
This is v3 running in pod kubia-1914148340-bz35w
This is v3 running in pod kubia-1914148340-w0voh
...
This is v3 running in pod kubia-1914148340-w0voh
Some internal error has occurred! This is pod kubia-1914148340-bz35w
This is v3 running in pod kubia-1914148340-w0voh
Some internal error has occurred! This is pod kubia-1914148340-lalmx
This is v3 running in pod kubia-1914148340-w0voh
Some internal error has occurred! This is pod kubia-1914148340-lalmx
Some internal error has occurred! This is pod kubia-1914148340-bz35w
Some internal error has occurred! This is pod kubia-1914148340-w0voh
```

##### Undoing a rollout

You can’t have your users experiencing internal server errors, so you need to do something about it fast. In [section 9.3.6](/book/kubernetes-in-action/chapter-9/ch09lev2sec11) you’ll see how to block bad rollouts automatically, but for now, let’s see what you can do about your bad rollout manually. Luckily, Deployments make it easy to roll back to the previously deployed version by telling Kubernetes to undo the last rollout of a Deployment:

```bash
$ kubectl rollout undo deployment kubia
deployment "kubia" rolled back
```

This rolls the Deployment back to the previous revision.

---

##### Tip

The `undo` command can also be used while the rollout process is still in progress to essentially abort the rollout. Pods already created during the rollout process are removed and replaced with the old ones again.

---

##### Displaying a Deployment’s rollout history

Rolling back a rollout is possible because Deployments keep a revision history. As you’ll see later, the history is stored in the underlying ReplicaSets. When a rollout completes, the old ReplicaSet isn’t deleted, and this enables rolling back to any revision, not only the previous one. The revision history can be displayed with the `kubectl rollout history` command:

```bash
$ kubectl rollout history deployment kubia
deployments "kubia":
REVISION    CHANGE-CAUSE
2           kubectl set image deployment kubia nodejs=luksa/kubia:v2
3           kubectl set image deployment kubia nodejs=luksa/kubia:v3
```

Remember the `--record` command-line option you used when creating the Deployment? Without it, the `CHANGE-CAUSE` column in the revision history would be empty, making it much harder to figure out what’s behind each revision.

##### Rolling back to a specific Deployment revision

You can roll back to a specific revision by specifying the revision in the `undo` command. For example, if you want to roll back to the first version, you’d execute the following command:

```bash
$ kubectl rollout undo deployment kubia --to-revision=1
```

Remember the inactive ReplicaSet left over when you modified the Deployment the first time? The ReplicaSet represents the first revision of your Deployment. All Replica-Sets created by a Deployment represent the complete revision history, as shown in [figure 9.11](/book/kubernetes-in-action/chapter-9/ch09fig11). Each ReplicaSet stores the complete information of the Deployment at that specific revision, so you shouldn’t delete it manually. If you do, you’ll lose that specific revision from the Deployment’s history, preventing you from rolling back to it.

![Figure 9.11. A Deployment’s ReplicaSets also act as its revision history.](https://drek4537l1klr.cloudfront.net/luksa/Figures/09fig11_alt.jpg)

But having old ReplicaSets cluttering your ReplicaSet list is not ideal, so the length of the revision history is limited by the `revisionHistoryLimit` property on the Deployment resource. It defaults to two, so normally only the current and the previous revision are shown in the history (and only the current and the previous ReplicaSet are preserved). Older ReplicaSets are deleted automatically.

---

##### Note

The `extensions/v1beta1` version of Deployments doesn’t have a default `revisionHistoryLimit`, whereas the default in version `apps/v1beta2` is 10.

---

### 9.3.4. Controlling the rate of the rollout

When you performed the rollout to `v3` and tracked its progress with the `kubectl rollout status` command, you saw that first a new pod was created, and when it became available, one of the old pods was deleted and another new pod was created. This continued until there were no old pods left. The way new pods are created and old ones are deleted is configurable through two additional properties of the rolling update strategy.

##### Introducing the maxSurge and maxUnavailable properties of the rol- lling update strategy

Two properties affect how many pods are replaced at once during a Deployment’s rolling update. They are `maxSurge` and `maxUnavailable` and can be set as part of the `rollingUpdate` sub-property of the Deployment’s `strategy` attribute, as shown in the following listing.

##### Listing 9.10. Specifying parameters for the `rollingUpdate` strategy

```
spec:
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
    type: RollingUpdate
```

What these properties do is explained in [table 9.2](/book/kubernetes-in-action/chapter-9/ch09table02).

##### Table 9.2. Properties for configuring the rate of the rolling update[(view table figure)](https://drek4537l1klr.cloudfront.net/luksa/HighResolutionFigures/table_9-2.png)

Property

What it does

maxSurgeDetermines how many pod instances you allow to exist above the desired replica count configured on the Deployment. It defaults to 25%, so there can be at most 25% more pod instances than the desired count. If the desired replica count is set to four, there will never be more than five pod instances running at the same time during an update. When converting a percentage to an absolute number, the number is rounded up. Instead of a percentage, the value can also be an absolute value (for example, one or two additional pods can be allowed).maxUnavailableDetermines how many pod instances can be unavailable relative to the desired replica count during the update. It also defaults to 25%, so the number of available pod instances must never fall below 75% of the desired replica count. Here, when converting a percentage to an absolute number, the number is rounded down. If the desired replica count is set to four and the percentage is 25%, only one pod can be unavailable. There will always be at least three pod instances available to serve requests during the whole rollout. As with maxSurge, you can also specify an absolute value instead of a percentage.Because the desired replica count in your case was three, and both these properties default to 25%, `maxSurge` allowed the number of all pods to reach four, and `maxUnavailable` disallowed having any unavailable pods (in other words, three pods had to be available at all times). This is shown in [figure 9.12](/book/kubernetes-in-action/chapter-9/ch09fig12).

![Figure 9.12. Rolling update of a Deployment with three replicas and default maxSurge and maxUnavailable](https://drek4537l1klr.cloudfront.net/luksa/Figures/09fig12_alt.jpg)

##### Understanding the maxUnavailable property

The `extensions/v1beta1` version of Deployments uses different defaults—it sets both `maxSurge` and `maxUnavailable` to `1` instead of `25%`. In the case of three replicas, `maxSurge` is the same as before, but `maxUnavailable` is different (1 instead of 0). This makes the rollout process unwind a bit differently, as shown in [figure 9.13](/book/kubernetes-in-action/chapter-9/ch09fig13).

![Figure 9.13. Rolling update of a Deployment with the maxSurge=1 and maxUnavailable=1](https://drek4537l1klr.cloudfront.net/luksa/Figures/09fig13_alt.jpg)

In this case, one replica can be unavailable, so if the desired replica count is three, only two of them need to be available. That’s why the rollout process immediately deletes one pod and creates two new ones. This ensures two pods are available and that the maximum number of pods isn’t exceeded (the maximum is four in this case—three plus one from `maxSurge`). As soon as the two new pods are available, the two remaining old pods are deleted.

This is a bit hard to grasp, especially since the `maxUnavailable` property leads you to believe that that’s the maximum number of unavailable pods that are allowed. If you look at the previous figure closely, you’ll see two unavailable pods in the second column even though `maxUnavailable` is set to 1.

It’s important to keep in mind that `maxUnavailable` is relative to the desired replica count. If the replica count is set to three and `maxUnavailable` is set to one, that means that the update process must always keep at least two (3 minus 1) pods available, while the number of pods that aren’t available can exceed one.

### 9.3.5. Pausing the rollout process

After the bad experience with version 3 of your app, imagine you’ve now fixed the bug and pushed version 4 of your image. You’re a little apprehensive about rolling it out across all your pods the way you did before. What you want is to run a single `v4` pod next to your existing `v2` pods and see how it behaves with only a fraction of all your users. Then, once you’re sure everything’s okay, you can replace all the old pods with new ones.

You could achieve this by running an additional pod either directly or through an additional Deployment, ReplicationController, or ReplicaSet, but you do have another option available on the Deployment itself. A Deployment can also be paused during the rollout process. This allows you to verify that everything is fine with the new version before proceeding with the rest of the rollout.

##### Pausing the rollout

I’ve prepared the `v4` image, so go ahead and trigger the rollout by changing the image to `luksa/kubia:v4`, but then immediately (within a few seconds) pause the rollout:

```bash
$ kubectl set image deployment kubia nodejs=luksa/kubia:v4
deployment "kubia" image updated

$ kubectl rollout pause deployment kubia
deployment "kubia" paused
```

A single new pod should have been created, but all original pods should also still be running. Once the new pod is up, a part of all requests to the service will be redirected to the new pod. This way, you’ve effectively run a canary release. A canary release is a technique for minimizing the risk of rolling out a bad version of an application and it affecting all your users. Instead of rolling out the new version to everyone, you replace only one or a small number of old pods with new ones. This way only a small number of users will initially hit the new version. You can then verify whether the new version is working fine or not and then either continue the rollout across all remaining pods or roll back to the previous version.

##### Resuming the rollout

In your case, by pausing the rollout process, only a small portion of client requests will hit your `v4` pod, while most will still hit the `v3` pods. Once you’re confident the new version works as it should, you can resume the deployment to replace all the old pods with new ones:

```bash
$ kubectl rollout resume deployment kubia
deployment "kubia" resumed
```

Obviously, having to pause the deployment at an exact point in the rollout process isn’t what you want to do. In the future, a new upgrade strategy may do that automatically, but currently, the proper way of performing a canary release is by using two different Deployments and scaling them appropriately.

##### Using the pause feature to prevent rollouts

Pausing a Deployment can also be used to prevent updates to the Deployment from kicking off the rollout process, allowing you to make multiple changes to the Deployment and starting the rollout only when you’re done making all the necessary changes. Once you’re ready for changes to take effect, you resume the Deployment and the rollout process will start.

---

##### Note

If a Deployment is paused, the `undo` command won’t undo it until you resume the Deployment.

---

### 9.3.6. Blocking rollouts of bad versions

Before you conclude this chapter, we need to discuss one more property of the Deployment resource. Remember the `minReadySeconds` property you set on the Deployment at the beginning of [section 9.3.2](/book/kubernetes-in-action/chapter-9/ch09lev2sec7)? You used it to slow down the rollout, so you could see it was indeed performing a rolling update and not replacing all the pods at once. The main function of `minReadySeconds` is to prevent deploying malfunctioning versions, not slowing down a deployment for fun.

##### Understanding the applicability of minReadySeconds

The `minReadySeconds` property specifies how long a newly created pod should be ready before the pod is treated as available. Until the pod is available, the rollout process will not continue (remember the `maxUnavailable` property?). A pod is ready when readiness probes of all its containers return a success. If a new pod isn’t functioning properly and its readiness probe starts failing before `minReadySeconds` have passed, the rollout of the new version will effectively be blocked.

You used this property to slow down your rollout process by having Kubernetes wait 10 seconds after a pod was ready before continuing with the rollout. Usually, you’d set `minReadySeconds` to something much higher to make sure pods keep reporting they’re ready after they’ve already started receiving actual traffic.

Although you should obviously test your pods both in a test and in a staging environment before deploying them into production, using `minReadySeconds` is like an airbag that saves your app from making a big mess after you’ve already let a buggy version slip into production.

With a properly configured readiness probe and a proper `minReadySeconds` setting, Kubernetes would have prevented us from deploying the buggy `v3` version earlier. Let me show you how.

##### Defining a readiness probe to prevent our v3 version from being rolled out fully

You’re going to deploy version `v3` again, but this time, you’ll have the proper readiness probe defined on the pod. Your Deployment is currently at version `v4`, so before you start, roll back to version `v2` again so you can pretend this is the first time you’re upgrading to `v3`. If you wish, you can go straight from `v4` to `v3`, but the text that follows assumes you returned to `v2` first.

Unlike before, where you only updated the image in the pod template, you’re now also going to introduce a readiness probe for the container at the same time. Up until now, because there was no explicit readiness probe defined, the container and the pod were always considered ready, even if the app wasn’t truly ready or was returning errors. There was no way for Kubernetes to know that the app was malfunctioning and shouldn’t be exposed to clients.

To change the image and introduce the readiness probe at once, you’ll use the `kubectl apply` command. You’ll use the following YAML to update the deployment (you’ll store it as `kubia-deployment-v3-with-readinesscheck.yaml`), as shown in the following listing.

##### Listing 9.11. Deployment with a readiness probe: kubia-deployment-v3-with-readinesscheck.yaml

```yaml
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: kubia
spec:
  replicas: 3
  minReadySeconds: 10
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
    type: RollingUpdate
  template:
    metadata:
      name: kubia
      labels:
        app: kubia
    spec:
      containers:
      - image: luksa/kubia:v3
        name: nodejs
        readinessProbe:
          periodSeconds: 1
          httpGet:
            path: /
            port: 8080
```

##### Updating a Deployment with kubectl apply

To update the Deployment this time, you’ll use `kubectl apply` like this:

```bash
$ kubectl apply -f kubia-deployment-v3-with-readinesscheck.yaml
deployment "kubia" configured
```

The `apply` command updates the Deployment with everything that’s defined in the YAML file. It not only updates the image but also adds the readiness probe definition and anything else you’ve added or modified in the YAML. If the new YAML also contains the `replicas` field, which doesn’t match the number of replicas on the existing Deployment, the apply operation will also scale the Deployment, which isn’t usually what you want.

---

##### Tip

To keep the desired replica count unchanged when updating a Deployment with `kubectl apply`, don’t include the `replicas` field in the YAML.

---

Running the `apply` command will kick off the update process, which you can again follow with the `rollout status` command:

```bash
$ kubectl rollout status deployment kubia
Waiting for rollout to finish: 1 out of 3 new replicas have been updated...
```

Because the status says one new pod has been created, your service should be hitting it occasionally, right? Let’s see:

```bash
$ while true; do curl http://130.211.109.222; done
This is v2 running in pod kubia-1765119474-jvslk
This is v2 running in pod kubia-1765119474-jvslk
This is v2 running in pod kubia-1765119474-xk5g3
This is v2 running in pod kubia-1765119474-pmb26
This is v2 running in pod kubia-1765119474-pmb26
This is v2 running in pod kubia-1765119474-xk5g3
...
```

Nope, you never hit the `v3` pod. Why not? Is it even there? List the pods:

```bash
$ kubectl get po
NAME                     READY     STATUS    RESTARTS   AGE
kubia-1163142519-7ws0i   0/1       Running   0          30s
kubia-1765119474-jvslk   1/1       Running   0          9m
kubia-1765119474-pmb26   1/1       Running   0          9m
kubia-1765119474-xk5g3   1/1       Running   0          8m
```

Aha! There’s your problem (or as you’ll learn soon, your blessing)! The pod is shown as not ready, but I guess you’ve been expecting that, right? What has happened?

##### Understanding how a readiness probe prevents bad versions from being rolled out

As soon as your new pod starts, the readiness probe starts being hit every second (you set the probe’s interval to one second in the pod spec). On the fifth request the readiness probe began failing, because your app starts returning HTTP status code 500 from the fifth request onward.

As a result, the pod is removed as an endpoint from the service (see [figure 9.14](/book/kubernetes-in-action/chapter-9/ch09fig14)). By the time you start hitting the service in the `curl` loop, the pod has already been marked as not ready. This explains why you never hit the new pod with `curl`. And that’s exactly what you want, because you don’t want clients to hit a pod that’s not functioning properly.

![Figure 9.14. Deployment blocked by a failing readiness probe in the new pod](https://drek4537l1klr.cloudfront.net/luksa/Figures/09fig14_alt.jpg)

But what about the rollout process? The `rollout status` command shows only one new replica has started. Thankfully, the rollout process will not continue, because the new pod will never become available. To be considered available, it needs to be ready for at least 10 seconds. Until it’s available, the rollout process will not create any new pods, and it also won’t remove any original pods because you’ve set the `maxUnavailable` property to 0.

The fact that the deployment is stuck is a good thing, because if it had continued replacing the old pods with the new ones, you’d end up with a completely non-working service, like you did when you first rolled out version 3, when you weren’t using the readiness probe. But now, with the readiness probe in place, there was virtually no negative impact on your users. A few users may have experienced the internal server error, but that’s not as big of a problem as if the rollout had replaced all pods with the faulty version 3.

---

##### Tip

If you only define the readiness probe without setting `minReadySeconds` properly, new pods are considered available immediately when the first invocation of the readiness probe succeeds. If the readiness probe starts failing shortly after, the bad version is rolled out across all pods. Therefore, you should set `minReadySeconds` appropriately.

---

##### Configuring a deadline for the rollout

By default, after the rollout can’t make any progress in 10 minutes, it’s considered as failed. If you use the `kubectl describe` deployment command, you’ll see it display a `ProgressDeadlineExceeded` condition, as shown in the following listing.

##### Listing 9.12. Seeing the conditions of a Deployment with `kubectl describe`

```bash
$ kubectl describe deploy kubia
Name:                   kubia
...
Conditions:
  Type          Status  Reason
  ----          ------  ------
  Available     True    MinimumReplicasAvailable
  Progressing   False   ProgressDeadlineExceeded         #1
```

The time after which the Deployment is considered failed is configurable through the `progressDeadlineSeconds` property in the Deployment spec.

---

##### Note

The `extensions/v1beta1` version of Deployments doesn’t set a deadline.

---

##### Aborting a bad rollout

Because the rollout will never continue, the only thing to do now is abort the rollout by undoing it:

```bash
$ kubectl rollout undo deployment kubia
deployment "kubia" rolled back
```

---

##### Note

In future versions, the rollout will be aborted automatically when the time specified in `progressDeadlineSeconds` is exceeded.

---

## 9.4. Summary

This chapter has shown you how to make your life easier by using a declarative approach to deploying and updating applications in Kubernetes. Now that you’ve read this chapter, you should know how to

- Perform a rolling update of pods managed by a ReplicationController
- Create Deployments instead of lower-level ReplicationControllers or ReplicaSets
- Update your pods by editing the pod template in the Deployment specification
- Roll back a Deployment either to the previous revision or to any earlier revision still listed in the revision history
- Abort a Deployment mid-way
- Pause a Deployment to inspect how a single instance of the new version behaves in production before allowing additional pod instances to replace the old ones
- Control the rate of the rolling update through `maxSurge` and `maxUnavailable` properties
- Use `minReadySeconds` and readiness probes to have the rollout of a faulty version blocked automatically

In addition to these Deployment-specific tasks, you also learned how to

- Use three dashes as a separator to define multiple resources in a single YAML file
- Turn on `kubectl`’s verbose logging to see exactly what it’s doing behind the curtains

You now know how to deploy and manage sets of pods created from the same pod template and thus share the same persistent storage. You even know how to update them declaratively. But what about running sets of pods, where each instance needs to use its own persistent storage? We haven’t looked at that yet. That’s the subject of our next chapter.
