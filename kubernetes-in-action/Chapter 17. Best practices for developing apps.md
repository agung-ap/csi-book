# Chapter 17. Best practices for developing apps

### **This chapter covers**

- Understanding which Kubernetes resources appear in a typical application
- Adding post-start and pre-stop pod lifecycle hooks
- Properly terminating an app without breaking client requests
- Making apps easy to manage in Kubernetes
- Using init containers in a pod
- Developing locally with Minikube

We’ve now covered most of what you need to know to run your apps in Kubernetes. We’ve explored what each individual resource does and how it’s used. Now we’ll see how to combine them in a typical application running on Kubernetes. We’ll also look at how to make an application run smoothly. After all, that’s the whole point of using Kubernetes, isn’t it?

Hopefully, this chapter will help to clear up any misunderstandings and explain things that weren’t explained clearly yet. Along the way, we’ll also introduce a few additional concepts that haven’t been mentioned up to this point.

## 17.1. Bringing everything together

Let’s start by looking at what an actual application consists of. This will also give you a chance to see if you remember everything you’ve learned so far and look at the big picture. [Figure 17.1](/book/kubernetes-in-action/chapter-17/ch17fig01) shows the Kubernetes components used in a typical application.

![Figure 17.1. Resources in a typical application](https://drek4537l1klr.cloudfront.net/luksa/Figures/17fig01_alt.jpg)

A typical application manifest contains one or more Deployment and/or StatefulSet objects. Those include a pod template containing one or more containers, with a liveness probe for each of them and a readiness probe for the service(s) the container provides (if any). Pods that provide services to others are exposed through one or more Services. When they need to be reachable from outside the cluster, the Services are either configured to be `LoadBalancer` or `NodePort`-type Services, or exposed through an Ingress resource.

The pod templates (and the pods created from them) usually reference two types of Secrets—those for pulling container images from private image registries and those used directly by the process running inside the pods. The Secrets themselves are usually not part of the application manifest, because they aren’t configured by the application developers but by the operations team. Secrets are usually assigned to Service-Accounts, which are assigned to individual pods.

The application also contains one or more ConfigMaps, which are either used to initialize environment variables or mounted as a `configMap` volume in the pod. Certain pods use additional volumes, such as an `emptyDir` or a `gitRepo` volume, whereas pods requiring persistent storage use `persistentVolumeClaim` volumes. The Persistent-VolumeClaims are also part of the application manifest, whereas StorageClasses referenced by them are created by system administrators upfront.

In certain cases, an application also requires the use of Jobs or CronJobs. DaemonSets aren’t normally part of application deployments, but are usually created by sysadmins to run system services on all or a subset of nodes. HorizontalPodAutoscalers are either included in the manifest by the developers or added to the system later by the ops team. The cluster administrator also creates LimitRange and ResourceQuota objects to keep compute resource usage of individual pods and all the pods (as a whole) under control.

After the application is deployed, additional objects are created automatically by the various Kubernetes controllers. These include service Endpoints objects created by the Endpoints controller, ReplicaSets created by the Deployment controller, and the actual pods created by the ReplicaSet (or Job, CronJob, StatefulSet, or Daemon-Set) controllers.

Resources are often labeled with one or more labels to keep them organized. This doesn’t apply only to pods but to all other resources as well. In addition to labels, most resources also contain annotations that describe each resource, list the contact information of the person or team responsible for it, or provide additional metadata for management and other tools.

At the center of all this is the Pod, which arguably is the most important Kubernetes resource. After all, each of your applications runs inside it. To make sure you know how to develop apps that make the most out of their environment, let’s take one last close look at pods—this time from the application’s perspective.

## 17.2. Understanding the pod’s lifecycle

We’ve said that pods can be compared to VMs dedicated to running only a single application. Although an application running inside a pod is not unlike an application running in a VM, significant differences do exist. One example is that apps running in a pod can be killed any time, because Kubernetes needs to relocate the pod to another node for a reason or because of a scale-down request. We’ll explore this aspect next.

### 17.2.1. Applications must expect to be killed and relocated

Outside Kubernetes, apps running in VMs are seldom moved from one machine to another. When an operator moves the app, they can also reconfigure the app and manually check that the app is running fine in the new location. With Kubernetes, apps are relocated much more frequently and automatically—no human operator reconfigures them and makes sure they still run properly after the move. This means application developers need to make sure their apps allow being moved relatively often.

##### Expecting the local IP and hostname to change

When a pod is killed and run elsewhere (technically, it’s a new pod instance replacing the old one; the pod isn’t relocated), it not only has a new IP address but also a new name and hostname. Most stateless apps can usually handle this without any adverse effects, but stateful apps usually can’t. We’ve learned that stateful apps can be run through a StatefulSet, which ensures that when the app starts up on a new node after being rescheduled, it will still see the same host name and persistent state as before. The pod’s IP will change nevertheless. Apps need to be prepared for that to happen. The application developer therefore should never base membership in a clustered app on the member’s IP address, and if basing it on the hostname, should always use a StatefulSet.

##### Expecting the data written to disk to disappear

Another thing to keep in mind is that if the app writes data to disk, that data may not be available after the app is started inside a new pod, unless you mount persistent storage at the location the app is writing to. It should be clear this happens when the pod is rescheduled, but files written to disk will disappear even in scenarios that don’t involve any rescheduling. Even during the lifetime of a single pod, the files written to disk by the app running in the pod may disappear. Let me explain this with an example.

Imagine an app that has a long and computationally intensive initial startup procedure. To help the app come up faster on subsequent startups, the developers make the app cache the results of the initial startup on disk (an example of this would be the scanning of all Java classes for annotations at startup and then writing the results to an index file). Because apps in Kubernetes run in containers by default, these files are written to the container’s filesystem. If the container is then restarted, they’re all lost, because the new container starts off with a completely new writable layer (see [figure 17.2](/book/kubernetes-in-action/chapter-17/ch17fig02)).

![Figure 17.2. Files written to the container’s filesystem are lost when the container is restarted.](https://drek4537l1klr.cloudfront.net/luksa/Figures/17fig02_alt.jpg)

Don’t forget that individual containers may be restarted for several reasons, such as because the process crashes, because the liveness probe returned a failure, or because the node started running out of memory and the process was killed by the OOMKiller. When this happens, the pod is still the same, but the container itself is completely new. The Kubelet doesn’t run the same container again; it always creates a new container.

##### Using volumes to preserve data across container restarts

When its container is restarted, the app in the example will need to perform the intensive startup procedure again. This may or may not be desired. To make sure data like this isn’t lost, you need to use at least a pod-scoped volume. Because volumes live and die together with the pod, the new container will be able to reuse the data written to the volume by the previous container ([figure 17.3](/book/kubernetes-in-action/chapter-17/ch17fig03)).

![Figure 17.3. Using a volume to persist data across container restarts](https://drek4537l1klr.cloudfront.net/luksa/Figures/17fig03_alt.jpg)

Using a volume to preserve files across container restarts is a great idea sometimes, but not always. What if the data gets corrupted and causes the newly created process to crash again? This will result in a continuous crash loop (the pod will show the `CrashLoopBackOff` status). If you hadn’t used a volume, the new container would start from scratch and most likely not crash. Using volumes to preserve files across container restarts like this is a double-edged sword. You need to think carefully about whether to use them or not.

### 17.2.2. Rescheduling of dead or partially dead pods

If a pod’s container keeps crashing, the Kubelet will keep restarting it indefinitely. The time between restarts will be increased exponentially until it reaches five minutes. During those five minute intervals, the pod is essentially dead, because its container’s process isn’t running. To be fair, if it’s a multi-container pod, certain containers may be running normally, so the pod is only partially dead. But if a pod contains only a single container, the pod is effectively dead and completely useless, because no process is running in it anymore.

You may find it surprising to learn that such pods aren’t automatically removed and rescheduled, even if they’re part of a ReplicaSet or similar controller. If you create a ReplicaSet with a desired replica count of three, and then one of the containers in one of those pods starts crashing, Kubernetes will not delete and replace the pod. The end result is a ReplicaSet with only two properly running replicas instead of the desired three ([figure 17.4](/book/kubernetes-in-action/chapter-17/ch17fig04)).

![Figure 17.4. A ReplicaSet controller doesn’t reschedule dead pods.](https://drek4537l1klr.cloudfront.net/luksa/Figures/17fig04_alt.jpg)

You’d probably expect the pod to be deleted and replaced with another pod instance that might run successfully on another node. After all, the container may be crashing because of a node-related problem that doesn’t manifest itself on other nodes. Sadly, that isn’t the case. The ReplicaSet controller doesn’t care if the pods are dead—all it cares about is that the number of pods matches the desired replica count, which in this case, it does.

If you’d like to see for yourself, I’ve included a YAML manifest for a ReplicaSet whose pods will keep crashing (see file replicaset-crashingpods.yaml in the code archive). If you create the ReplicaSet and inspect the pods that are created, the following listing is what you’ll see.

##### Listing 17.1. ReplicaSet and pods that keep crashing

```bash
$ kubectl get po
NAME                  READY     STATUS             RESTARTS   AGE
crashing-pods-f1tcd   0/1       CrashLoopBackOff   5          6m     #1
crashing-pods-k7l6k   0/1       CrashLoopBackOff   5          6m
crashing-pods-z7l3v   0/1       CrashLoopBackOff   5          6m

$ kubectl describe rs crashing-pods
Name:           crashing-pods
Replicas:       3 current / 3 desired                                #2
Pods Status:    3 Running / 0 Waiting / 0 Succeeded / 0 Failed       #3

$ kubectl describe po crashing-pods-f1tcd
Name:           crashing-pods-f1tcd
Namespace:      default
Node:           minikube/192.168.99.102
Start Time:     Thu, 02 Mar 2017 14:02:23 +0100
Labels:         app=crashing-pods
Status:         Running                                              #4
```

In a way, it’s understandable that Kubernetes behaves this way. The container will be restarted every five minutes in the hope that the underlying cause of the crash will be resolved. The rationale is that rescheduling the pod to another node most likely wouldn’t fix the problem anyway, because the app is running inside a container and all the nodes should be mostly equivalent. That’s not always the case, but it is most of the time.

### 17.2.3. Starting pods in a specific order

One other difference between apps running in pods and those managed manually is that the ops person deploying those apps knows about the dependencies between them. This allows them to start the apps in order.

##### Understanding how pods are started

When you use Kubernetes to run your multi-pod applications, you don’t have a built-in way to tell Kubernetes to run certain pods first and the rest only when the first pods are already up and ready to serve. Sure, you could post the manifest for the first app and then wait for the pod(s) to be ready before you post the second manifest, but your whole system is usually defined in a single YAML or JSON containing multiple Pods, Services, and other objects.

The Kubernetes API server does process the objects in the YAML/JSON in the order they’re listed, but this only means they’re written to etcd in that order. You have no guarantee that pods will also be started in that order.

But you *can* prevent a pod’s main container from starting until a precondition is met. This is done by including an init containers in the pod.

##### Introducing Init Containers

In addition to regular containers, pods can also include init containers. As the name suggests, they can be used to initialize the pod—this often means writing data to the pod’s volumes, which are then mounted into the pod’s main container(s).

A pod may have any number of init containers. They’re executed sequentially and only after the last one completes are the pod’s main containers started. This means init containers can also be used to delay the start of the pod’s main container(s)—for example, until a certain precondition is met. An init container could wait for a service required by the pod’s main container to be up and ready. When it is, the init container terminates and allows the main container(s) to be started. This way, the main container wouldn’t use the service before it’s ready.

Let’s look at an example of a pod using an init container to delay the start of the main container. Remember the `fortune` pod you created in [chapter 7](/book/kubernetes-in-action/chapter-7/ch07)? It’s a web server that returns a fortune quote as a response to client requests. Now, let’s imagine you have a `fortune-client` pod that requires the `fortune` Service to be up and running before its main container starts. You can add an init container, which checks whether the Service is responding to requests. Until that’s the case, the init container keeps retrying. Once it gets a response, the init container terminates and lets the main container start.

##### Adding an Init Container to a pod

Init containers can be defined in the pod spec like main containers but through the `spec.initContainers` field. You’ll find the complete YAML for the fortune-client pod in the book’s code archive. The following listing shows the part where the init container is defined.

##### Listing 17.2. An init container defined in a pod: fortune-client.yaml

```
spec:
  initContainers:                                                        #1
  - name: init
    image: busybox
    command:
    - sh
    - -c
    - 'while true; do echo "Waiting for fortune service to come up...";  #2
    ➥  wget http://fortune -q -T 1 -O /dev/null >/dev/null 2>/dev/null   #2
    ➥  && break; sleep 1; done; echo "Service is up! Starting main       #2
    ➥  container."'
```

When you deploy this pod, only its init container is started. This is shown in the pod’s status when you list pods with `kubectl get`:

```bash
$ kubectl get po
NAME             READY     STATUS     RESTARTS   AGE
fortune-client   0/1       Init:0/1   0          1m
```

The `STATUS` column shows that zero of one init containers have finished. You can see the log of the init container with `kubectl logs`:

```bash
$ kubectl logs fortune-client -c init
Waiting for fortune service to come up...
```

When running the `kubectl logs` command, you need to specify the name of the init container with the `-c` switch (in the example, the name of the pod’s init container is `init`, as you can see in [listing 17.2](/book/kubernetes-in-action/chapter-17/ch17ex02)).

The main container won’t run until you deploy the `fortune` Service and the `fortune-server` pod. You’ll find them in the fortune-server.yaml file.

##### Best practices for handling inter-pod dependencies

You’ve seen how an init container can be used to delay starting the pod’s main container(s) until a precondition is met (making sure the Service the pod depends on is ready, for example), but it’s much better to write apps that don’t require every service they rely on to be ready before the app starts up. After all, the service may also go offline later, while the app is already running.

The application needs to handle internally the possibility that its dependencies aren’t ready. And don’t forget readiness probes. If an app can’t do its job because one of its dependencies is missing, it should signal that through its readiness probe, so Kubernetes knows it, too, isn’t ready. You’ll want to do this not only because it prevents the app from being added as a service endpoint, but also because the app’s readiness is also used by the Deployment controller when performing a rolling update, thereby preventing a rollout of a bad version.

### 17.2.4. Adding lifecycle hooks

We’ve talked about how init containers can be used to hook into the startup of the pod, but pods also allow you to define two lifecycle hooks:

- *Post-start* hooks
- *Pre-stop* hooks

These lifecycle hooks are specified per container, unlike init containers, which apply to the whole pod. As their names suggest, they’re executed when the container starts and before it stops.

Lifecycle hooks are similar to liveness and readiness probes in that they can either

- Execute a command inside the container
- Perform an HTTP GET request against a URL

Let’s look at the two hooks individually to see what effect they have on the container lifecycle.

##### Using a post-start container lifecycle hook

A post-start hook is executed immediately after the container’s main process is started. You use it to perform additional operations when the application starts. Sure, if you’re the author of the application running in the container, you can always perform those operations inside the application code itself. But when you’re running an application developed by someone else, you mostly don’t want to (or can’t) modify its source code. Post-start hooks allow you to run additional commands without having to touch the app. These may signal to an external listener that the app is starting, or they may initialize the application so it can start doing its job.

The hook is run in parallel with the main process. The name might be somewhat misleading, because it doesn’t wait for the main process to start up fully (if the process has an initialization procedure, the Kubelet obviously can’t wait for the procedure to complete, because it has no way of knowing when that is).

But even though the hook runs asynchronously, it does affect the container in two ways. Until the hook completes, the container will stay in the `Waiting` state with the reason `ContainerCreating`. Because of this, the pod’s status will be `Pending` instead of `Running`. If the hook fails to run or returns a non-zero exit code, the main container will be killed.

A pod manifest containing a post-start hook looks like the following listing.

##### Listing 17.3. A pod with a post-start lifecycle hook: post-start-hook.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-poststart-hook
spec:
  containers:
  - image: luksa/kubia
    name: kubia
    lifecycle:
      postStart:
        exec:
          command:
          - sh
          - -c
          - "echo 'hook will fail with exit code 15'; sleep 5; exit 15"
```

In the example, the `echo`, `sleep`, and `exit` commands are executed along with the container’s main process as soon as the container is created. Rather than run a command like this, you’d typically run a shell script or a binary executable file stored in the container image.

Sadly, if the process started by the hook logs to the standard output, you can’t see the output anywhere. This makes debugging lifecycle hooks painful. If the hook fails, you’ll only see a `FailedPostStartHook` warning among the pod’s events (you can see them using `kubectl describe pod`). A while later, you’ll see more information on why the hook failed, as shown in the following listing.

##### Listing 17.4. Pod’s events showing the exit code of the failed command-based hook

```
FailedSync   Error syncing pod, skipping: failed to "StartContainer" for
             "kubia" with PostStart handler: command 'sh -c echo 'hook
             will fail with exit code 15'; sleep 5 ; exit 15' exited
             with 15: : "PostStart Hook Failed"
```

The number `15` in the last line is the exit code of the command. When using an HTTP GET hook handler, the reason may look like the following listing (you can try this by deploying the post-start-hook-httpget.yaml file from the book’s code archive).

##### Listing 17.5. Pod’s events showing the reason why an HTTP GET hook failed

```
FailedSync   Error syncing pod, skipping: failed to "StartContainer" for
             "kubia" with PostStart handler: Get
             http://10.32.0.2:9090/postStart: dial tcp 10.32.0.2:9090:
             getsockopt: connection refused: "PostStart Hook Failed"
```

---

##### Note

The post-start hook is intentionally misconfigured to use port 9090 instead of the correct port 8080, to show what happens when the hook fails.

---

The standard and error outputs of command-based post-start hooks aren’t logged anywhere, so you may want to have the process the hook invokes log to a file in the container’s filesystem, which will allow you to examine the contents of the file with something like this:

```bash
$ kubectl exec my-pod cat logfile.txt
```

If the container gets restarted for whatever reason (including because the hook failed), the file may be gone before you can examine it. You can work around that by mounting an `emptyDir` volume into the container and having the hook write to it.

##### Using a pre-stop container lifecycle hook

A pre-stop hook is executed immediately before a container is terminated. When a container needs to be terminated, the Kubelet will run the pre-stop hook, if configured, and only then send a `SIGTERM` to the process (and later kill the process if it doesn’t terminate gracefully).

A pre-stop hook can be used to initiate a graceful shutdown of the container, if it doesn’t shut down gracefully upon receipt of a `SIGTERM` signal. They can also be used to perform arbitrary operations before shutdown without having to implement those operations in the application itself (this is useful when you’re running a third-party app, whose source code you don’t have access to and/or can’t modify).

Configuring a pre-stop hook in a pod manifest isn’t very different from adding a post-start hook. The previous example showed a post-start hook that executes a command, so we’ll look at a pre-stop hook that performs an HTTP GET request now. The following listing shows how to define a pre-stop HTTP GET hook in a pod.

##### Listing 17.6. A pre-stop hook YAML snippet: pre-stop-hook-httpget.yaml

```
lifecycle:
      preStop:                #1
        httpGet:              #1
          port: 8080          #2
          path: shutdown      #2
```

The pre-stop hook defined in this listing performs an HTTP GET request to [http://POD_IP:8080/shutdown](http://POD_IP:8080/shutdown) as soon as the Kubelet starts terminating the container. Apart from the `port` and `path` shown in the listing, you can also set the fields `scheme` (HTTP or HTTPS) and `host`, as well as `httpHeaders` that should be sent in the request. The `host` field defaults to the pod IP. Be sure not to set it to localhost, because localhost would refer to the node, not the pod.

In contrast to the post-start hook, the container will be terminated regardless of the result of the hook—an error HTTP response code or a non-zero exit code when using a command-based hook will not prevent the container from being terminated. If the pre-stop hook fails, you’ll see a `FailedPreStopHook` warning event among the pod’s events, but because the pod is deleted soon afterward (after all, the pod’s deletion is what triggered the pre-stop hook in the first place), you may not even notice that the pre-stop hook failed to run properly.

---

##### Tip

If the successful completion of the pre-stop hook is critical to the proper operation of your system, verify whether it’s being executed at all. I’ve witnessed situations where the pre-stop hook didn’t run and the developer wasn’t even aware of that.

---

##### Using a pre-stop hook because your app doesn’t receive the SIGTERM signal

Many developers make the mistake of defining a pre-stop hook solely to send a `SIGTERM` signal to their apps in the pre-stop hook. They do this because they don’t see their application receive the `SIGTERM` signal sent by the Kubelet. The reason why the signal isn’t received by the application isn’t because Kubernetes isn’t sending it, but because the signal isn’t being passed to the app process inside the container itself. If your container image is configured to run a shell, which in turn runs the app process, the signal may be eaten up by the shell itself, instead of being passed down to the child process.

In such cases, instead of adding a pre-stop hook to send the signal directly to your app, the proper fix is to make sure the shell passes the signal to the app. This can be achieved by handling the signal in the shell script running as the main container process and then passing it on to the app. Or you could not configure the container image to run a shell at all and instead run the application binary directly. You do this by using the exec form of `ENTRYPOINT` or `CMD` in the Dockerfile: `ENTRYPOINT ["/mybinary"]` instead of `ENTRYPOINT /mybinary`.

A container using the first form runs the `mybinary` executable as its main process, whereas the second form runs a shell as the main process with the `mybinary` process executed as a child of the shell process.

##### Understanding that lifecycle hooks target containers, not pods

As a final thought on post-start and pre-stop hooks, let me emphasize that these lifecycle hooks relate to containers, not pods. You shouldn’t use a pre-stop hook for running actions that need to be performed when the pod is terminating. The reason is that the pre-stop hook gets called when the container is being terminated (most likely because of a failed liveness probe). This may happen multiple times in the pod’s lifetime, not only when the pod is in the process of being shut down.

### 17.2.5. Understanding pod shutdown

We’ve touched on the subject of pod termination, so let’s explore this subject in more detail and go over exactly what happens during pod shutdown. This is important for understanding how to cleanly shut down an application running in a pod.

Let’s start at the beginning. A pod’s shut-down is triggered by the deletion of the Pod object through the API server. Upon receiving an HTTP DELETE request, the API server doesn’t delete the object yet, but only sets a `deletionTimestamp` field in it. Pods that have the `deletionTimestamp` field set are terminating.

Once the Kubelet notices the pod needs to be terminated, it starts terminating each of the pod’s containers. It gives each container time to shut down gracefully, but the time is limited. That time is called the termination grace period and is configurable per pod. The timer starts as soon as the termination process starts. Then the following sequence of events is performed:

1. Run the pre-stop hook, if one is configured, and wait for it to finish.
1. Send the `SIGTERM` signal to the main process of the container.
1. Wait until the container shuts down cleanly or until the termination grace period runs out.
1. Forcibly kill the process with `SIGKILL`, if it hasn’t terminated gracefully yet.

The sequence of events is illustrated in [figure 17.5](/book/kubernetes-in-action/chapter-17/ch17fig05).

![Figure 17.5. The container termination sequence](https://drek4537l1klr.cloudfront.net/luksa/Figures/17fig05_alt.jpg)

##### Specifying the termination grace period

The termination grace period can be configured in the pod spec by setting the `spec.terminationGracePeriodSeconds` field. It defaults to 30, which means the pod’s containers will be given 30 seconds to terminate gracefully before they’re killed forcibly.

---

##### Tip

You should set the grace period to long enough so your process can finish cleaning up in that time.

---

The grace period specified in the pod spec can also be overridden when deleting the pod like this:

```bash
$ kubectl delete po mypod --grace-period=5
```

This will make the Kubelet wait five seconds for the pod to shut down cleanly. When all the pod’s containers stop, the Kubelet notifies the API server and the Pod resource is finally deleted. You can force the API server to delete the resource immediately, without waiting for confirmation, by setting the grace period to zero and adding the `--force` option like this:

```bash
$ kubectl delete po mypod --grace-period=0 --force
```

Be careful when using this option, especially with pods of a StatefulSet. The StatefulSet controller takes great care to never run two instances of the same pod at the same time (two pods with the same ordinal index and name and attached to the same Persistent-Volume). By force-deleting a pod, you’ll cause the controller to create a replacement pod without waiting for the containers of the deleted pod to shut down. In other words, two instances of the same pod might be running at the same time, which may cause your stateful cluster to malfunction. Only delete stateful pods forcibly when you’re absolutely sure the pod isn’t running anymore or can’t talk to the other members of the cluster (you can be sure of this when you confirm that the node that hosted the pod has failed or has been disconnected from the network and can’t reconnect).

Now that you understand how containers are shut down, let’s look at it from the application’s perspective and go over how applications should handle the shutdown procedure.

##### Implementing the proper shutdown handler in your application

Applications should react to a `SIGTERM` signal by starting their shut-down procedure and terminating when it finishes. Instead of handling the `SIGTERM` signal, the application can be notified to shut down through a pre-stop hook. In both cases, the app then only has a fixed amount of time to terminate cleanly.

But what if you can’t predict how long the app will take to shut down cleanly? For example, imagine your app is a distributed data store. On scale-down, one of the pod instances will be deleted and therefore shut down. In the shut-down procedure, the pod needs to migrate all its data to the remaining pods to make sure it’s not lost. Should the pod start migrating the data upon receiving a termination signal (through either the `SIGTERM` signal or through a pre-stop hook)?

Absolutely not! This is not recommended for at least the following two reasons:

- A container terminating doesn’t necessarily mean the whole pod is being terminated.
- You have no guarantee the shut-down procedure will finish before the process is killed.

This second scenario doesn’t happen only when the grace period runs out before the application has finished shutting down gracefully, but also when the node running the pod fails in the middle of the container shut-down sequence. Even if the node then starts up again, the Kubelet will not restart the shut-down procedure (it won’t even start up the container again). There are absolutely no guarantees that the pod will be allowed to complete its whole shut-down procedure.

##### Replacing critical shut-down procedures with dedicated shut-down procedure pods

How do you ensure that a critical shut-down procedure that absolutely must run to completion does run to completion (for example, to ensure that a pod’s data is migrated to other pods)?

One solution is for the app (upon receipt of a termination signal) to create a new Job resource that would run a new pod, whose sole job is to migrate the deleted pod’s data to the remaining pods. But if you’ve been paying attention, you’ll know that you have no guarantee the app will indeed manage to create the Job object every single time. What if the node fails exactly when the app tries to do that?

The proper way to handle this problem is by having a dedicated, constantly running pod that keeps checking for the existence of orphaned data. When this pod finds the orphaned data, it can migrate it to the remaining pods. Rather than a constantly running pod, you can also use a CronJob resource and run the pod periodically.

You may think StatefulSets could help here, but they don’t. As you’ll remember, scaling down a StatefulSet leaves PersistentVolumeClaims orphaned, leaving the data stored on the PersistentVolume stranded. Yes, upon a subsequent scale-up, the Persistent-Volume will be reattached to the new pod instance, but what if that scale-up never happens (or happens after a long time)? For this reason, you may want to run a data-migrating pod also when using StatefulSets (this scenario is shown in [figure 17.6](/book/kubernetes-in-action/chapter-17/ch17fig06)). To prevent the migration from occurring during an application upgrade, the data-migrating pod could be configured to wait a while to give the stateful pod time to come up again before performing the migration.

![Figure 17.6. Using a dedicated pod to migrate data](https://drek4537l1klr.cloudfront.net/luksa/Figures/17fig06_alt.jpg)

## 17.3. Ensuring all client requests are handled properly

You now have a good sense of how to make pods shut down cleanly. Now, we’ll look at the pod’s lifecycle from the perspective of the pod’s clients (clients consuming the service the pod is providing). This is important to understand if you don’t want clients to run into problems when you scale pods up or down.

It goes without saying that you want all client requests to be handled properly. You obviously don’t want to see broken connections when pods are starting up or shutting down. By itself, Kubernetes doesn’t prevent this from happening. Your app needs to follow a few rules to prevent broken connections. First, let’s focus on making sure all connections are handled properly when the pod starts up.

### 17.3.1. Preventing broken client connections when a pod is starting up

Ensuring each connection is handled properly at pod startup is simple if you understand how Services and service Endpoints work. When a pod is started, it’s added as an endpoint to all the Services, whose label selector matches the pod’s labels. As you may remember from [chapter 5](/book/kubernetes-in-action/chapter-5/ch05), the pod also needs to signal to Kubernetes that it’s ready. Until it is, it won’t become a service endpoint and therefore won’t receive any requests from clients.

If you don’t specify a readiness probe in your pod spec, the pod is always considered ready. It will start receiving requests almost immediately—as soon as the first kube-proxy updates the `iptables` rules on its node and the first client pod tries to connect to the service. If your app isn’t ready to accept connections by then, clients will see “connection refused” types of errors.

All you need to do is make sure that your readiness probe returns success only when your app is ready to properly handle incoming requests. A good first step is to add an HTTP GET readiness probe and point it to the base URL of your app. In many cases that gets you far enough and saves you from having to implement a special readiness endpoint in your app.

### 17.3.2. Preventing broken connections during pod shut-down

Now let’s see what happens at the other end of a pod’s life—when the pod is deleted and its containers are terminated. We’ve already talked about how the pod’s containers should start shutting down cleanly as soon they receive the `SIGTERM` signal (or when its pre-stop hook is executed). But does that ensure all client requests are handled properly?

How should the app behave when it receives a termination signal? Should it continue to accept requests? What about requests that have already been received but haven’t completed yet? What about persistent HTTP connections, which may be in between requests, but are open (when no active request exists on the connection)? Before we can answer those questions, we need to take a detailed look at the chain of events that unfolds across the cluster when a Pod is deleted.

##### Understanding the sequence of events occurring at pod deletion

In [chapter 11](/book/kubernetes-in-action/chapter-11/ch11) we took an in-depth look at what components make up a Kubernetes cluster. You need to always keep in mind that those components run as separate processes on multiple machines. They aren’t all part of a single big monolithic process. It takes time for all the components to be on the same page regarding the state of the cluster. Let’s explore this fact by looking at what happens across the cluster when a Pod is deleted.

When a request for a pod deletion is received by the API server, it first modifies the state in etcd and then notifies its watchers of the deletion. Among those watchers are the Kubelet and the Endpoints controller. The two sequences of events, which happen in parallel (marked with either A or B), are shown in [figure 17.7](/book/kubernetes-in-action/chapter-17/ch17fig07).

![Figure 17.7. Sequence of events that occurs when a Pod is deleted](https://drek4537l1klr.cloudfront.net/luksa/Figures/17fig07_alt.jpg)

In the A sequence of events, you’ll see that as soon as the Kubelet receives the notification that the pod should be terminated, it initiates the shutdown sequence as explained in [section 17.2.5](/book/kubernetes-in-action/chapter-17/ch17lev2sec5) (run the pre-stop hook, send `SIGTERM`, wait for a period of time, and then forcibly kill the container if it hasn’t yet terminated on its own). If the app responds to the `SIGTERM` by immediately ceasing to receive client requests, any client trying to connect to it will receive a Connection Refused error. The time it takes for this to happen from the time the pod is deleted is relatively short because of the direct path from the API server to the Kubelet.

Now, let’s look at what happens in the other sequence of events—the one leading up to the pod being removed from the `iptables` rules (sequence B in the figure). When the Endpoints controller (which runs in the Controller Manager in the Kubernetes Control Plane) receives the notification of the Pod being deleted, it removes the pod as an endpoint in all services that the pod is a part of. It does this by modifying the Endpoints API object by sending a REST request to the API server. The API server then notifies all clients watching the Endpoints object. Among those watchers are all the kube-proxies running on the worker nodes. Each of these proxies then updates the `iptables` rules on its node, which is what prevents new connections from being forwarded to the terminating pod. An important detail here is that removing the `iptables` rules has no effect on existing connections—clients who are already connected to the pod will still send additional requests to the pod through those existing connections.

Both of these sequences of events happen in parallel. Most likely, the time it takes to shut down the app’s process in the pod is slightly shorter than the time required for the `iptables` rules to be updated. The chain of events that leads to `iptables` rules being updated is considerably longer (see [figure 17.8](/book/kubernetes-in-action/chapter-17/ch17fig08)), because the event must first reach the Endpoints controller, which then sends a new request to the API server, and then the API server must notify the kube-proxy before the proxy finally modifies the `iptables` rules. A high probability exists that the `SIGTERM` signal will be sent well before the `iptables` rules are updated on all nodes.

![Figure 17.8. Timeline of events when pod is deleted](https://drek4537l1klr.cloudfront.net/luksa/Figures/17fig08_alt.jpg)

The end result is that the pod may still receive client requests after it was sent the termination signal. If the app closes the server socket and stops accepting connections immediately, this will cause clients to receive “Connection Refused” types of errors (similar to what happens at pod startup if your app isn’t capable of accepting connections immediately and you don’t define a readiness probe for it).

##### Solving the problem

Googling solutions to this problem makes it seem as though adding a readiness probe to your pod will solve the problem. Supposedly, all you need to do is make the readiness probe start failing as soon as the pod receives the `SIGTERM`. This is supposed to cause the pod to be removed as the endpoint of the service. But the removal would happen only after the readiness probe fails for a few consecutive times (this is configurable in the readiness probe spec). And, obviously, the removal then still needs to reach the kube-proxy before the pod is removed from `iptables` rules.

In reality, the readiness probe has absolutely no bearing on the whole process at all. The Endpoints controller removes the pod from the service Endpoints as soon as it receives notice of the pod being deleted (when the `deletionTimestamp` field in the pod’s spec is no longer `null`). From that point on, the result of the readiness probe is irrelevant.

What’s the proper solution to the problem? How can you make sure all requests are handled fully?

It’s clear the pod needs to keep accepting connections even after it receives the termination signal up until all the kube-proxies have finished updating the `iptables` rules. Well, it’s not only the kube-proxies. There may also be Ingress controllers or load balancers forwarding connections to the pod directly, without going through the Service (`iptables`). This also includes clients using client-side load-balancing. To ensure none of the clients experience broken connections, you’d have to wait until all of them somehow notify you they’ll no longer forward connections to the pod.

That’s impossible, because all those components are distributed across many different computers. Even if you knew the location of every one of them and could wait until all of them say it’s okay to shut down the pod, what do you do if one of them doesn’t respond? How long do you wait for the response? Remember, during that time, you’re holding up the shut-down process.

The only reasonable thing you can do is wait for a long-enough time to ensure all the proxies have done their job. But how long is long enough? A few seconds should be enough in most situations, but there’s no guarantee it will suffice every time. When the API server or the Endpoints controller is overloaded, it may take longer for the notification to reach the kube-proxy. It’s important to understand that you can’t solve the problem perfectly, but even adding a 5- or 10-second delay should improve the user experience considerably. You can use a longer delay, but don’t go overboard, because the delay will prevent the container from shutting down promptly and will cause the pod to be shown in lists long after it has been deleted, which is always frustrating to the user deleting the pod.

##### Wrapping up this section

To recap—properly shutting down an application includes these steps:

- Wait for a few seconds, then stop accepting new connections.
- Close all keep-alive connections not in the middle of a request.
- Wait for all active requests to finish.
- Then shut down completely.

To understand what’s happening with the connections and requests during this process, examine [figure 17.9](/book/kubernetes-in-action/chapter-17/ch17fig09) carefully.

![Figure 17.9. Properly handling existing and new connections after receiving a termination signal](https://drek4537l1klr.cloudfront.net/luksa/Figures/17fig09_alt.jpg)

Not as simple as exiting the process immediately upon receiving the termination signal, right? Is it worth going through all this? That’s for you to decide. But the least you can do is add a pre-stop hook that waits a few seconds, like the one in the following listing, perhaps.

##### Listing 17.7. A pre-stop hook for preventing broken connections

```
lifecycle:
      preStop:
        exec:
          command:
          - sh
          - -c
          - "sleep 5"
```

This way, you don’t need to modify the code of your app at all. If your app already ensures all in-flight requests are processed completely, this pre-stop delay may be all you need.

## 17.4. Making your apps easy to run and manage in Kubernetes

I hope you now have a better sense of how to make your apps handle clients nicely. Now we’ll look at other aspects of how an app should be built to make it easier to manage in Kubernetes.

### 17.4.1. Making manageable container images

When you package your app into an image, you can choose to include the app’s binary executable and any additional libraries it needs, or you can package up a whole OS filesystem along with the app. Way too many people do this, even though it’s usually unnecessary.

Do you need every single file from an OS distribution in your image? Probably not. Most of the files will never be used and will make your image larger than it needs to be. Sure, the layering of images makes sure each individual layer is downloaded only once, but even having to wait longer than necessary the first time a pod is scheduled to a node is undesirable.

Deploying new pods and scaling them should be fast. This demands having small images without unnecessary cruft. If you’re building apps using the Go language, your images don’t need to include anything else apart from the app’s single binary executable file. This makes Go-based container images extremely small and perfect for Kubernetes.

---

##### Tip

Use the `FROM scratch` directive in the Dockerfile for these images.

---

But in practice, you’ll soon see these minimal images are extremely difficult to debug. The first time you need to run a tool such as `ping`, `dig`, `curl`, or something similar inside the container, you’ll realize how important it is for container images to also include at least a limited set of these tools. I can’t tell you what to include and what not to include in your images, because it depends on how you do things, so you’ll need to find the sweet spot yourself.

### 17.4.2. Properly tagging your images and using imagePullPolicy wisely

You’ll also soon learn that referring to the `latest` image tag in your pod manifests will cause problems, because you can’t tell which version of the image each individual pod replica is running. Even if initially all your pod replicas run the same image version, if you push a new version of the image under the `latest` tag, and then pods are rescheduled (or you scale up your Deployment), the new pods will run the new version, whereas the old ones will still be running the old one. Also, using the `latest` tag makes it impossible to roll back to a previous version (unless you push the old version of the image again).

It’s almost mandatory to use tags containing a proper version designator instead of `latest`, except maybe in development. Keep in mind that if you use mutable tags (you push changes to the same tag), you’ll need to set the `imagePullPolicy` field in the pod spec to `Always`. But if you use that in production pods, be aware of the big caveat associated with it. If the image pull policy is set to `Always`, the container runtime will contact the image registry every time a new pod is deployed. This slows down pod startup a bit, because the node needs to check if the image has been modified. Worse yet, this policy prevents the pod from starting up when the registry cannot be contacted.

### 17.4.3. Using multi-dimensional instead of single-dimensional labels

Don’t forget to label all your resources, not only Pods. Make sure you add multiple labels to each resource, so they can be selected across each individual dimension. You (or the ops team) will be grateful you did it when the number of resources increases.

Labels may include things like

- The name of the application (or perhaps microservice) the resource belongs to
- Application tier (front-end, back-end, and so on)
- Environment (development, QA, staging, production, and so on)
- Version
- Type of release (stable, canary, green or blue for green/blue deployments, and so on)
- Tenant (if you’re running separate pods for each tenant instead of using namespaces)
- Shard for sharded systems

This will allow you to manage resources in groups instead of individually and make it easy to see where each resource belongs.

### 17.4.4. Describing each resource through annotations

To add additional information to your resources use annotations. At the least, resources should contain an annotation describing the resource and an annotation with contact information of the person responsible for it.

In a microservices architecture, pods could contain an annotation that lists the names of the other services the pod is using. This makes it possible to show dependencies between pods. Other annotations could include build and version information and metadata used by tooling or graphical user interfaces (icon names, and so on).

Both labels and annotations make managing running applications much easier, but nothing is worse than when an application starts crashing and you don’t know why.

### 17.4.5. Providing information on why the process terminated

Nothing is more frustrating than having to figure out why a container terminated (or is even terminating continuously), especially if it happens at the worst possible moment. Be nice to the ops people and make their lives easier by including all the necessary debug information in your log files.

But to make triage even easier, you can use one other Kubernetes feature that makes it possible to show the reason why a container terminated in the pod’s status. You do this by having the process write a termination message to a specific file in the container’s filesystem. The contents of this file are read by the Kubelet when the container terminates and are shown in the output of `kubectl describe pod`. If an application uses this mechanism, an operator can quickly see why the app terminated without even having to look at the container logs.

The default file the process needs to write the message to is /dev/termination-log, but it can be changed by setting the `terminationMessagePath` field in the container definition in the pod spec.

You can see this in action by running a pod whose container dies immediately, as shown in the following listing.

##### Listing 17.8. Pod writing a termination message: termination-message.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-termination-message
spec:
  containers:
  - image: busybox
    name: main
    terminationMessagePath: /var/termination-reason
    command:
    - sh
    - -c
    - 'echo "I''ve had enough" > /var/termination-reason ; exit 1'
```

When running this pod, you’ll soon see the pod’s status shown as `CrashLoopBackOff`. If you then use `kubectl describe`, you can see why the container died, without having to dig down into its logs, as shown in the following listing.

##### Listing 17.9. Seeing the container’s termination message with `kubectl describe`

```bash
$ kubectl describe po
Name:           pod-with-termination-message
...
Containers:
...
    State:      Waiting
      Reason:   CrashLoopBackOff
    Last State: Terminated
      Reason:   Error
      Message:  I've had enough                          #1
      Exit Code:        1
      Started:          Tue, 21 Feb 2017 21:38:31 +0100
      Finished:         Tue, 21 Feb 2017 21:38:31 +0100
    Ready:              False
    Restart Count:      6
```

As you can see, the “`I've had enough"` message the process wrote to the file /var/termination-reason is shown in the container’s `Last State` section. Note that this mechanism isn’t limited only to containers that crash. It can also be used in pods that run a completable task and terminate successfully (you’ll find an example in the file termination-message-success.yaml).

This mechanism is great for terminated containers, but you’ll probably agree that a similar mechanism would also be useful for showing app-specific status messages of running, not only terminated, containers. Kubernetes currently doesn’t provide any such functionality and I’m not aware of any plans to introduce it.

---

##### Note

If the container doesn’t write the message to any file, you can set the `terminationMessagePolicy` field to `FallbackToLogsOnError`. In that case, the last few lines of the container’s log are used as its termination message (but only when the container terminates unsuccessfully).

---

### 17.4.6. Handling application logs

While we’re on the subject of application logging, let’s reiterate that apps should write to the standard output instead of files. This makes it easy to view logs with the `kubectl logs` command.

---

##### Tip

If a container crashes and is replaced with a new one, you’ll see the new container’s log. To see the previous container’s logs, use the `--previous` option with `kubectl logs`.

---

If the application logs to a file instead of the standard output, you can display the log file using an alternative approach:

```bash
$ kubectl exec <pod> cat <logfile>
```

This executes the `cat` command inside the container and streams the logs back to kubectl, which prints them out in your terminal.

##### Copying log and other files to and from a container

You can also copy the log file to your local machine using the `kubectl cp` command, which we haven’t looked at yet. It allows you to copy files from and into a container. For example, if a pod called `foo-pod` and its single container contains a file at `/var/log/ foo.log`, you can transfer it to your local machine with the following command:

```bash
$ kubectl cp foo-pod:/var/log/foo.log foo.log
```

To copy a file from your local machine into the pod, specify the pod’s name in the second argument:

```bash
$ kubectl cp localfile foo-pod:/etc/remotefile
```

This copies the file localfile to /etc/remotefile inside the pod’s container. If the pod has more than one container, you specify the container using the `-c containerName` option.

##### Using centralized logging

In a production system, you’ll want to use a centralized, cluster-wide logging solution, so all your logs are collected and (permanently) stored in a central location. This allows you to examine historical logs and analyze trends. Without such a system, a pod’s logs are only available while the pod exists. As soon as it’s deleted, its logs are deleted also.

Kubernetes by itself doesn’t provide any kind of centralized logging. The components necessary for providing a centralized storage and analysis of all the container logs must be provided by additional components, which usually run as regular pods in the cluster.

Deploying centralized logging solutions is easy. All you need to do is deploy a few YAML/JSON manifests and you’re good to go. On Google Kubernetes Engine, it’s even easier. Check the Enable Stackdriver Logging checkbox when setting up the cluster. Setting up centralized logging on an on-premises Kubernetes cluster is beyond the scope of this book, but I’ll give you a quick overview of how it’s usually done.

You may have already heard of the ELK stack composed of ElasticSearch, Logstash, and Kibana. A slightly modified variation is the EFK stack, where Logstash is replaced with FluentD.

When using the EFK stack for centralized logging, each Kubernetes cluster node runs a FluentD agent (usually as a pod deployed through a DaemonSet), which is responsible for gathering the logs from the containers, tagging them with pod-specific information, and delivering them to ElasticSearch, which stores them persistently. ElasticSearch is also deployed as a pod somewhere in the cluster. The logs can then be viewed and analyzed in a web browser through Kibana, which is a web tool for visualizing ElasticSearch data. It also usually runs as a pod and is exposed through a Service. The three components of the EFK stack are shown in the following figure.

![Figure 17.10. Centralized logging with FluentD, ElasticSearch, and Kibana](https://drek4537l1klr.cloudfront.net/luksa/Figures/17fig10_alt.jpg)

---

##### Note

In the next chapter, you’ll learn about Helm charts. You can use charts created by the Kubernetes community to deploy the EFK stack instead of creating your own YAML manifests.

---

##### Handling multi-line log statements

The FluentD agent stores each line of the log file as an entry in the ElasticSearch data store. There’s one problem with that. Log statements spanning multiple lines, such as exception stack traces in Java, appear as separate entries in the centralized logging system.

To solve this problem, you can have the apps output JSON instead of plain text. This way, a multiline log statement can be stored and shown in Kibana as a single entry. But that makes viewing logs with `kubectl logs` much less human-friendly.

The solution may be to keep outputting human-readable logs to standard output, while writing JSON logs to a file and having them processed by FluentD. This requires configuring the node-level FluentD agent appropriately or adding a logging sidecar container to every pod.

## 17.5. Best practices for development and testing

We’ve talked about what to be mindful of when developing apps, but we haven’t talked about the development and testing workflows that will help you streamline those processes. I don’t want to go into too much detail here, because everyone needs to find what works best for them, but here are a few starting points.

### 17.5.1. Running apps outside of Kubernetes during development

When you’re developing an app that will run in a production Kubernetes cluster, does that mean you also need to run it in Kubernetes during development? Not really. Having to build the app after each minor change, then build the container image, push it to a registry, and then re-deploy the pods would make development slow and painful. Luckily, you don’t need to go through all that trouble.

You can always develop and run apps on your local machine, the way you’re used to. After all, an app running in Kubernetes is a regular (although isolated) process running on one of the cluster nodes. If the app depends on certain features the Kubernetes environment provides, you can easily replicate that environment on your development machine.

I’m not even talking about running the app in a container. Most of the time, you don’t need that—you can usually run the app directly from your IDE.

##### Connecting to backend services

In production, if the app connects to a backend Service and uses the `BACKEND_SERVICE_HOST` and `BACKEND_SERVICE_PORT` environment variables to find the Service’s coordinates, you can obviously set those environment variables on your local machine manually and point them to the backend Service, regardless of if it’s running outside or inside a Kubernetes cluster. If it’s running inside Kubernetes, you can always (at least temporarily) make the Service accessible externally by changing it to a `NodePort` or a `LoadBalancer`-type Service.

##### Connecting to the API server

Similarly, if your app requires access to the Kubernetes API server when running inside a Kubernetes cluster, it can easily talk to the API server from outside the cluster during development. If it uses the ServiceAccount’s token to authenticate itself, you can always copy the ServiceAccount’s Secret’s files to your local machine with `kubectl cp`. The API server doesn’t care if the client accessing it is inside or outside the cluster.

If the app uses an ambassador container like the one described in [chapter 8](/book/kubernetes-in-action/chapter-8/ch08), you don’t even need those Secret files. Run `kubectl proxy` on your local machine, run your app locally, and it should be ready to talk to your local `kubectl proxy` (as long as it and the ambassador container bind the proxy to the same port).

In this case, you’ll need to make sure the user account your local `kubectl` is using has the same privileges as the ServiceAccount the app will run under.

##### Running inside a container even during development

When during development you absolutely have to run the app in a container for whatever reason, there is a way of avoiding having to build the container image every time. Instead of baking the binaries into the image, you can always mount your local filesystem into the container through Docker volumes, for example. This way, after you build a new version of the app’s binaries, all you need to do is restart the container (or not even that, if hot-redeploy is supported). No need to rebuild the image.

### 17.5.2. Using Minikube in development

As you can see, nothing forces you to run your app inside Kubernetes during development. But you may do that anyway to see how the app behaves in a true Kubernetes environment.

You may have used Minikube to run examples in this book. Although a Minikube cluster runs only a single worker node, it’s nevertheless a valuable method of trying out your app in Kubernetes (and, of course, developing all the resource manifests that make up your complete application). Minikube doesn’t offer everything that a proper multi-node Kubernetes cluster usually provides, but in most cases, that doesn’t matter.

##### Mounting local files into the minikube VM and then into your containers

When you’re developing with Minikube and you’d like to try out every change to your app in your Kubernetes cluster, you can mount your local filesystem into the Minikube VM using the `minikube mount` command and then mount it into your containers through a `hostPath` volume. You’ll find additional instructions on how to do that in the Minikube documentation at [https://github.com/kubernetes/minikube/tree/master/docs](https://github.com/kubernetes/minikube/tree/master/docs).

##### Using the Docker daemon inside the minikube VM to build your images

If you’re developing your app with Minikube and planning to build the container image after every change, you can use the Docker daemon inside the Minikube VM to do the building, instead of having to build the image through your local Docker daemon, push it to a registry, and then have it pulled by the daemon in the VM. To use Minikube’s Docker daemon, all you need to do is point your `DOCKER_HOST` environment variable to it. Luckily, this is much easier than it sounds. All you need to do is run the following command on your local machine:

```bash
$ eval $(minikube docker-env)
```

This will set all the required environment variables for you. You then build your images the same way as if the Docker daemon was running on your local machine. After you build the image, you don’t need to push it anywhere, because it’s already stored locally on the Minikube VM, which means new pods can use the image immediately. If your pods are already running, you either need to delete them or kill their containers so they’re restarted.

##### Building images locally and copying them over to the minikube VM directly

If you can’t use the daemon inside the VM to build the images, you still have a way to avoid having to push the image to a registry and have the Kubelet running in the Minikube VM pull it. If you build the image on your local machine, you can copy it over to the Minikube VM with the following command:

```bash
$ docker save <image> | (eval $(minikube docker-env) && docker load)
```

As before, the image is immediately ready to be used in a pod. But make sure the `imagePullPolicy` in your pod spec isn’t set to `Always`, because that would cause the image to be pulled from the external registry again and you’d lose the changes you’ve copied over.

##### Combining Minikube with a proper Kubernetes cluster

You have virtually no limit when developing apps with Minikube. You can even combine a Minikube cluster with a proper Kubernetes cluster. I sometimes run my development workloads in my local Minikube cluster and have them talk to my other workloads that are deployed in a remote multi-node Kubernetes cluster thousands of miles away.

Once I’m finished with development, I can move my local workloads to the remote cluster with no modifications and with absolutely no problems thanks to how Kubernetes abstracts away the underlying infrastructure from the app.

### 17.5.3. Versioning and auto-deploying resource manifests

Because Kubernetes uses a declarative model, you never have to figure out the current state of your deployed resources and issue imperative commands to bring that state to what you desire. All you need to do is tell Kubernetes your desired state and it will take all the necessary actions to reconcile the cluster state with the desired state.

You can store your collection of resource manifests in a Version Control System, enabling you to perform code reviews, keep an audit trail, and roll back changes whenever necessary. After each commit, you can run the `kubectl apply` command to have your changes reflected in your deployed resources.

If you run an agent that periodically (or when it detects a new commit) checks out your manifests from the Version Control System (VCS), and then runs the `apply` command, you can manage your running apps simply by committing changes to the VCS without having to manually talk to the Kubernetes API server. Luckily, the people at Box (which coincidently was used to host this book’s manuscript and other materials) developed and released a tool called `kube-applier`, which does exactly what I described. You’ll find the tool’s source code at [https://github.com/box/kube-applier](https://github.com/box/kube-applier).

You can use multiple branches to deploy the manifests to a development, QA, staging, and production cluster (or in different namespaces in the same cluster).

### 17.5.4. Introducing Ksonnet as an alternative to writing YAML/JSON manifests

We’ve seen a number of YAML manifests throughout the book. I don’t see writing YAML as too big of a problem, especially once you learn how to use `kubectl explain` to see the available options, but some people do.

Just as I was finalizing the manuscript for this book, a new tool called Ksonnet was announced. It’s a library built on top of Jsonnet, which is a data templating language for building JSON data structures. Instead of writing the complete JSON by hand, it lets you define parameterized JSON fragments, give them a name, and then build a full JSON manifest by referencing those fragments by name, instead of repeating the same JSON code in multiple locations—much like you use functions or methods in a programming language.

Ksonnet defines the fragments you’d find in Kubernetes resource manifests, allowing you to quickly build a complete Kubernetes resource JSON manifest with much less code. The following listing shows an example.

##### Listing 17.10. The `kubia` Deployment written with Ksonnet: kubia.ksonnet

```
local k = import "../ksonnet-lib/ksonnet.beta.1/k.libsonnet";

local container = k.core.v1.container;
local deployment = k.apps.v1beta1.deployment;

local kubiaContainer =                              #1
  container.default("kubia", "luksa/kubia:v1") +    #1
  container.helpers.namedPort("http", 8080);        #1

deployment.default("kubia", kubiaContainer) +       #2
deployment.mixin.spec.replicas(3)                   #2
```

The kubia.ksonnet file shown in the listing is converted to a full JSON Deployment manifest when you run the following command:

```bash
$ jsonnet kubia.ksonnet
```

The power of Ksonnet and Jsonnet becomes apparent when you realize you can define your own higher-level fragments and make all your manifests consistent and duplication-free. You’ll find more information on using and installing Ksonnet and Jsonnet at [https://github.com/ksonnet/ksonnet-lib](https://github.com/ksonnet/ksonnet-lib).

### 17.5.5. Employing Continuous Integration and Continuous Delivery (CI/CD)

We’ve touched on automating the deployment of Kubernetes resources two sections back, but you may want to set up a complete CI/CD pipeline for building your application binaries, container images, and resource manifests and then deploying them in one or more Kubernetes clusters.

You’ll find many online resources talking about this subject. Here, I’d like to point you specifically to the Fabric8 project ([http://fabric8.io](http://fabric8.io)), which is an integrated development platform for Kubernetes. It includes Jenkins, the well-known, open-source automation system, and various other tools to deliver a full CI/CD pipeline for DevOps-style development, deployment, and management of microservices on Kubernetes.

If you’d like to build your own solution, I also suggest looking at one of the Google Cloud Platform’s online labs that talks about this subject. It’s available at [https://github.com/GoogleCloudPlatform/continuous-deployment-on-kubernetes](https://github.com/GoogleCloudPlatform/continuous-deployment-on-kubernetes).

## 17.6. Summary

Hopefully, the information in this chapter has given you an even deeper insight into how Kubernetes works and will help you build apps that feel right at home when deployed to a Kubernetes cluster. The aim of this chapter was to

- Show you how all the resources covered in this book come together to represent a typical application running in Kubernetes.
- Make you think about the difference between apps that are rarely moved between machines and apps running as pods, which are relocated much more frequently.
- Help you understand that your multi-component apps (or microservices, if you will) shouldn’t rely on a specific start-up order.
- Introduce init containers, which can be used to initialize a pod or delay the start of the pod’s main containers until a precondition is met.
- Teach you about container lifecycle hooks and when to use them.
- Gain a deeper insight into the consequences of the distributed nature of Kubernetes components and its eventual consistency model.
- Learn how to make your apps shut down properly without breaking client connections.
- Give you a few small tips on how to make your apps easier to manage by keeping image sizes small, adding annotations and multi-dimensional labels to all your resources, and making it easier to see why an application terminated.
- Teach you how to develop Kubernetes apps and run them locally or in Minikube before deploying them on a proper multi-node cluster.

In the next and final chapter, we’ll learn how you can extend Kubernetes with your own custom API objects and controllers and how others have done it to create complete Platform-as-a-Service solutions on top of Kubernetes.

Build it yourself with a liveProject!Creating and Managing Cloud Native Services in KubernetesPurchase this related liveProject and you'll boost the resilience and scalability of a Kubernetes-based app with modern cloud native practices. Are you ready?view liveProject![Creating and Managing Cloud Native Services in Kubernetes](https://images.manning.com/264/352/resize/liveProject/7/7ca5981-d753-46ba-bddc-6f49268a474d/CreatingandManagingCloudNativeServicesinKubernetes.jpg)
