# Chapter 6. Volumes: attaching disk storage to containers

### **This chapter covers**

- Creating multi-container pods
- Creating a volume to share disk storage between containers
- Using a Git repository inside a pod
- Attaching persistent storage such as a GCE Persistent Disk to pods
- Using pre-provisioned persistent storage
- Dynamic provisioning of persistent storage

In the previous three chapters, we introduced pods and other Kubernetes resources that interact with them, namely ReplicationControllers, ReplicaSets, DaemonSets, Jobs, and Services. Now, we’re going back inside the pod to learn how its containers can access external disk storage and/or share storage between them.

We’ve said that pods are similar to logical hosts where processes running inside them share resources such as CPU, RAM, network interfaces, and others. One would expect the processes to also share disks, but that’s not the case. You’ll remember that each container in a pod has its own isolated filesystem, because the file-system comes from the container’s image.

Every new container starts off with the exact set of files that was added to the image at build time. Combine this with the fact that containers in a pod get restarted (either because the process died or because the liveness probe signaled to Kubernetes that the container wasn’t healthy anymore) and you’ll realize that the new container will not see anything that was written to the filesystem by the previous container, even though the newly started container runs in the same pod.

In certain scenarios you want the new container to continue where the last one finished, such as when restarting a process on a physical machine. You may not need (or want) the whole filesystem to be persisted, but you do want to preserve the directories that hold actual data.

Kubernetes provides this by defining storage *volumes*. They aren’t top-level resources like pods, but are instead defined as a part of a pod and share the same lifecycle as the pod. This means a volume is created when the pod is started and is destroyed when the pod is deleted. Because of this, a volume’s contents will persist across container restarts. After a container is restarted, the new container can see all the files that were written to the volume by the previous container. Also, if a pod contains multiple containers, the volume can be used by all of them at once.

## 6.1. Introducing volumes

Kubernetes volumes are a component of a pod and are thus defined in the pod’s specification—much like containers. They aren’t a standalone Kubernetes object and cannot be created or deleted on their own. A volume is available to all containers in the pod, but it must be mounted in each container that needs to access it. In each container, you can mount the volume in any location of its filesystem.

### 6.1.1. Explaining volumes in an example

Imagine you have a pod with three containers (shown in [figure 6.1](/book/kubernetes-in-action/chapter-6/ch06fig01)). One container runs a web server that serves HTML pages from the /var/htdocs directory and stores the access log to /var/logs. The second container runs an agent that creates HTML files and stores them in /var/html. The third container processes the logs it finds in the /var/logs directory (rotates them, compresses them, analyzes them, or whatever).

![Figure 6.1. Three containers of the same pod without shared storage](https://drek4537l1klr.cloudfront.net/luksa/Figures/06fig01.jpg)

Each container has a nicely defined single responsibility, but on its own each container wouldn’t be of much use. Creating a pod with these three containers without them sharing disk storage doesn’t make any sense, because the content generator would write the generated HTML files inside its own container and the web server couldn’t access those files, as it runs in a separate isolated container. Instead, it would serve an empty directory or whatever you put in the /var/htdocs directory in its container image. Similarly, the log rotator would never have anything to do, because its /var/logs directory would always remain empty with nothing writing logs there. A pod with these three containers and no volumes basically does nothing.

But if you add two volumes to the pod and mount them at appropriate paths inside the three containers, as shown in [figure 6.2](/book/kubernetes-in-action/chapter-6/ch06fig02), you’ve created a system that’s much more than the sum of its parts. Linux allows you to mount a filesystem at arbitrary locations in the file tree. When you do that, the contents of the mounted filesystem are accessible in the directory it’s mounted into. By mounting the same volume into two containers, they can operate on the same files. In your case, you’re mounting two volumes in three containers. By doing this, your three containers can work together and do something useful. Let me explain how.

![Figure 6.2. Three containers sharing two volumes mounted at various mount paths](https://drek4537l1klr.cloudfront.net/luksa/Figures/06fig02.jpg)

First, the pod has a volume called `publicHtml`. This volume is mounted in the `WebServer` container at /var/htdocs, because that’s the directory the web server serves files from. The same volume is also mounted in the `ContentAgent` container, but at /var/html, because that’s where the agent writes the files to. By mounting this single volume like that, the web server will now serve the content generated by the content agent.

Similarly, the pod also has a volume called `logVol` for storing logs. This volume is mounted at /var/logs in both the `WebServer` and the `LogRotator` containers. Note that it isn’t mounted in the `ContentAgent` container. The container cannot access its files, even though the container and the volume are part of the same pod. It’s not enough to define a volume in the pod; you need to define a `VolumeMount` inside the container’s spec also, if you want the container to be able to access it.

The two volumes in this example can both initially be empty, so you can use a type of volume called `emptyDir`. Kubernetes also supports other types of volumes that are either populated during initialization of the volume from an external source, or an existing directory is mounted inside the volume. This process of populating or mounting a volume is performed before the pod’s containers are started.

A volume is bound to the lifecycle of a pod and will stay in existence only while the pod exists, but depending on the volume type, the volume’s files may remain intact even after the pod and volume disappear, and can later be mounted into a new volume. Let’s see what types of volumes exist.

### 6.1.2. Introducing available volume types

A wide variety of volume types is available. Several are generic, while others are specific to the actual storage technologies used underneath. Don’t worry if you’ve never heard of those technologies—I hadn’t heard of at least half of them. You’ll probably only use volume types for the technologies you already know and use. Here’s a list of several of the available volume types:

- `emptyDir`—A simple empty directory used for storing transient data.
- `hostPath`—Used for mounting directories from the worker node’s filesystem into the pod.
- `gitRepo`—A volume initialized by checking out the contents of a Git repository.
- `nfs`—An NFS share mounted into the pod.
- `gcePersistentDisk` (Google Compute Engine Persistent Disk), `awsElasticBlockStore` (Amazon Web Services Elastic Block Store Volume), `azureDisk` (Microsoft Azure Disk Volume)—Used for mounting cloud provider-specific storage.
- `cinder`, `cephfs`, `iscsi`, `flocker`, `glusterfs`, `quobyte`, `rbd`, `flexVolume`, `vsphere-Volume`, `photonPersistentDisk`, `scaleIO`—Used for mounting other types of network storage.
- `configMap`, `secret`, `downwardAPI`—Special types of volumes used to expose certain Kubernetes resources and cluster information to the pod.
- `persistentVolumeClaim`—A way to use a pre- or dynamically provisioned persistent storage. (We’ll talk about them in the last section of this chapter.)

These volume types serve various purposes. You’ll learn about some of them in the following sections. Special types of volumes (`secret`, `downwardAPI`, `configMap`) are covered in the next two chapters, because they aren’t used for storing data, but for exposing Kubernetes metadata to apps running in the pod.

A single pod can use multiple volumes of different types at the same time, and, as we’ve mentioned before, each of the pod’s containers can either have the volume mounted or not.

## 6.2. Using volumes to share data between containers

Although a volume can prove useful even when used by a single container, let’s first focus on how it’s used for sharing data between multiple containers in a pod.

### 6.2.1. Using an emptyDir volume

The simplest volume type is the `emptyDir` volume, so let’s look at it in the first example of how to define a volume in a pod. As the name suggests, the volume starts out as an empty directory. The app running inside the pod can then write any files it needs to it. Because the volume’s lifetime is tied to that of the pod, the volume’s contents are lost when the pod is deleted.

An `emptyDir` volume is especially useful for sharing files between containers running in the same pod. But it can also be used by a single container for when a container needs to write data to disk temporarily, such as when performing a sort operation on a large dataset, which can’t fit into the available memory. The data could also be written to the container’s filesystem itself (remember the top read-write layer in a container?), but subtle differences exist between the two options. A container’s filesystem may not even be writable (we’ll talk about this toward the end of the book), so writing to a mounted volume might be the only option.

##### Using an emptyDir volume in a pod

Let’s revisit the previous example where a web server, a content agent, and a log rotator share two volumes, but let’s simplify a bit. You’ll build a pod with only the web server container and the content agent and a single volume for the HTML.

You’ll use Nginx as the web server and the UNIX `fortune` command to generate the HTML content. The `fortune` command prints out a random quote every time you run it. You’ll create a script that invokes the `fortune` command every 10 seconds and stores its output in index.html. You’ll find an existing Nginx image available on Docker Hub, but you’ll need to either create the `fortune` image yourself or use the one I’ve already built and pushed to Docker Hub under `luksa/fortune`. If you want a refresher on how to build Docker images, refer to the sidebar.

---

##### **Building the fortune container image**

Here’s how to build the image. Create a new directory called fortune and then inside it, create a `fortuneloop.sh` shell script with the following contents:

```
#!/bin/bash
trap "exit" SIGINT
while :
do
  echo $(date) Writing fortune to /var/htdocs/index.html
  /usr/games/fortune > /var/htdocs/index.html
  sleep 10
done
```

Then, in the same directory, create a file called Dockerfile containing the following:

```dockerfile
FROM ubuntu:latest
RUN apt-get update ; apt-get -y install fortune
ADD fortuneloop.sh /bin/fortuneloop.sh
ENTRYPOINT /bin/fortuneloop.sh
```

The image is based on the `ubuntu:latest` image, which doesn’t include the `fortune` binary by default. That’s why in the second line of the Dockerfile you install it with `apt-get`. After that, you add the `fortuneloop.sh` script to the image’s `/bin` folder. In the last line of the Dockerfile, you specify that the `fortuneloop.sh` script should be executed when the image is run.

After preparing both files, build and upload the image to Docker Hub with the following two commands (replace `luksa` with your own Docker Hub user ID):

```bash
$ docker build -t luksa/fortune .
$ docker push luksa/fortune
```

---

##### Creating the pod

Now that you have the two images required to run your pod, it’s time to create the pod manifest. Create a file called fortune-pod.yaml with the contents shown in the following listing.

##### Listing 6.1. A pod with two containers sharing the same volume: fortune-pod.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: fortune
spec:
  containers:
  - image: luksa/fortune
    name: html-generator
    volumeMounts:
    - name: html
      mountPath: /var/htdocs
  - image: nginx:alpine
    name: web-server
    volumeMounts:
    - name: html
      mountPath: /usr/share/nginx/html
      readOnly: true
    ports:
    - containerPort: 80
      protocol: TCP
  volumes:

  - name: html

    emptyDir: {}
```

The pod contains two containers and a single volume that’s mounted in both of them, yet at different paths. When the `html-generator` container starts, it starts writing the output of the `fortune` command to the /var/htdocs/index.html file every 10 seconds. Because the volume is mounted at /var/htdocs, the index.html file is written to the volume instead of the container’s top layer. As soon as the `web-server` container starts, it starts serving whatever HTML files are in the /usr/share/nginx/html directory (this is the default directory Nginx serves files from). Because you mounted the volume in that exact location, Nginx will serve the index.html file written there by the container running the fortune loop. The end effect is that a client sending an HTTP request to the pod on port 80 will receive the current fortune message as the response.

##### Seeing the pod in action

To see the fortune message, you need to enable access to the pod. You’ll do that by forwarding a port from your local machine to the pod:

```bash
$ kubectl port-forward fortune 8080:80
Forwarding from 127.0.0.1:8080 -> 80
Forwarding from [::1]:8080 -> 80
```

---

##### Note

As an exercise, you can also expose the pod through a service instead of using port forwarding.

---

Now you can access the Nginx server through port 8080 of your local machine. Use `curl` to do that:

```bash
$ curl http://localhost:8080
Beware of a tall blond man with one black shoe.
```

If you wait a few seconds and send another request, you should receive a different message. By combining two containers, you created a simple app to see how a volume can glue together two containers and enhance what each of them does.

##### Specifying the medium to use for the emptyDir

The `emptyDir` you used as the volume was created on the actual disk of the worker node hosting your pod, so its performance depends on the type of the node’s disks. But you can tell Kubernetes to create the `emptyDir` on a tmpfs filesystem (in memory instead of on disk). To do this, set the `emptyDir`’s `medium` to `Memory` like this:

```
volumes:
  - name: html
    emptyDir:
      medium: Memory              #1
```

An `emptyDir` volume is the simplest type of volume, but other types build upon it. After the empty directory is created, they populate it with data. One such volume type is the `gitRepo` volume type, which we’ll introduce next.

### 6.2.2. Using a Git repository as the starting point for a volume

A `gitRepo` volume is basically an `emptyDir` volume that gets populated by cloning a Git repository and checking out a specific revision when the pod is starting up (but before its containers are created). [Figure 6.3](/book/kubernetes-in-action/chapter-6/ch06fig03) shows how this unfolds.

![Figure 6.3. A gitRepo volume is an emptyDir volume initially populated with the contents of a Git repository.](https://drek4537l1klr.cloudfront.net/luksa/Figures/06fig03_alt.jpg)

---

##### Note

After the `gitRepo` volume is created, it isn’t kept in sync with the repo it’s referencing. The files in the volume will not be updated when you push additional commits to the Git repository. However, if your pod is managed by a ReplicationController, deleting the pod will result in a new pod being created and this new pod’s volume will then contain the latest commits.

---

For example, you can use a Git repository to store static HTML files of your website and create a pod containing a web server container and a `gitRepo` volume. Every time the pod is created, it pulls the latest version of your website and starts serving it. The only drawback to this is that you need to delete the pod every time you push changes to the `gitRepo` and want to start serving the new version of the website.

Let’s do this right now. It’s not that different from what you did before.

##### Running a web server pod serving files from a cloned git repository

Before you create your pod, you’ll need an actual Git repository with HTML files in it. I’ve created a repo on GitHub at [https://github.com/luksa/kubia-website-example.git](https://github.com/luksa/kubia-website-example.git). You’ll need to fork it (create your own copy of the repo on GitHub) so you can push changes to it later.

Once you’ve created your fork, you can move on to creating the pod. This time, you’ll only need a single Nginx container and a single `gitRepo` volume in the pod (be sure to point the `gitRepo` volume to your own fork of my repository), as shown in the following listing.

##### Listing 6.2. A pod using a `gitRepo` volume: gitrepo-volume-pod.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: gitrepo-volume-pod
spec:
  containers:
  - image: nginx:alpine
    name: web-server
    volumeMounts:
    - name: html
      mountPath: /usr/share/nginx/html
      readOnly: true
    ports:
    - containerPort: 80
      protocol: TCP
  volumes:
  - name: html
    gitRepo:
      repository: https://github.com/luksa/kubia-website-example.git
      revision: master
      directory: .
```

When you create the pod, the volume is first initialized as an empty directory and then the specified Git repository is cloned into it. If you hadn’t set the directory to `.` (dot), the repository would have been cloned into the kubia-website-example subdirectory, which isn’t what you want. You want the repo to be cloned into the root directory of your volume. Along with the repository, you also specified you want Kubernetes to check out whatever revision the master branch is pointing to at the time the volume is created.

With the pod running, you can try hitting it through port forwarding, a service, or by executing the `curl` command from within the pod (or any other pod inside the cluster).

##### Confirming the files aren’t kept in sync with the git repo

Now you’ll make changes to the index.html file in your GitHub repository. If you don’t use Git locally, you can edit the file on GitHub directly—click on the file in your GitHub repository to open it and then click on the pencil icon to start editing it. Change the text and then commit the changes by clicking the button at the bottom.

The master branch of the Git repository now includes the changes you made to the HTML file. These changes will not be visible on your Nginx web server yet, because the `gitRepo` volume isn’t kept in sync with the Git repository. You can confirm this by hitting the pod again.

To see the new version of the website, you need to delete the pod and create it again. Instead of having to delete the pod every time you make changes, you could run an additional process, which keeps your volume in sync with the Git repository. I won’t explain in detail how to do this. Instead, try doing this yourself as an exercise, but here are a few pointers.

##### Introducing sidecar containers

The Git sync process shouldn’t run in the same container as the Nginx web server, but in a second container: a *sidecar container*. A sidecar container is a container that augments the operation of the main container of the pod. You add a sidecar to a pod so you can use an existing container image instead of cramming additional logic into the main app’s code, which would make it overly complex and less reusable.

To find an existing container image, which keeps a local directory synchronized with a Git repository, go to Docker Hub and search for “git sync.” You’ll find many images that do that. Then use the image in a new container in the pod from the previous example, mount the pod’s existing `gitRepo` volume in the new container, and configure the Git sync container to keep the files in sync with your Git repo. If you set everything up correctly, you should see that the files the web server is serving are kept in sync with your GitHub repo.

---

##### Note

An example in [chapter 18](../Text/18.html#ch18) includes using a Git sync container like the one explained here, so you can wait until you reach [chapter 18](../Text/18.html#ch18) and follow the step-by-step instructions then instead of doing this exercise on your own now.

---

##### Using a gitRepo volume with private Git repositories

There’s one other reason for having to resort to Git sync sidecar containers. We haven’t talked about whether you can use a `gitRepo` volume with a private Git repo. It turns out you can’t. The current consensus among Kubernetes developers is to keep the `gitRepo` volume simple and not add any support for cloning private repositories through the SSH protocol, because that would require adding additional config options to the `gitRepo` volume.

If you want to clone a private Git repo into your container, you should use a gitsync sidecar or a similar method instead of a `gitRepo` volume.

##### Wrapping up the gitRepo volume

A `gitRepo` volume, like the `emptyDir` volume, is basically a dedicated directory created specifically for, and used exclusively by, the pod that contains the volume. When the pod is deleted, the volume and its contents are deleted. Other types of volumes, however, don’t create a new directory, but instead mount an existing external directory into the pod’s container’s filesystem. The contents of that volume can survive multiple pod instantiations. We’ll learn about those types of volumes next.

## 6.3. Accessing files on the worker node’s filesystem

Most pods should be oblivious of their host node, so they shouldn’t access any files on the node’s filesystem. But certain system-level pods (remember, these will usually be managed by a DaemonSet) do need to either read the node’s files or use the node’s filesystem to access the node’s devices through the filesystem. Kubernetes makes this possible through a `hostPath` volume.

### 6.3.1. Introducing the hostPath volume

A `hostPath` volume points to a specific file or directory on the node’s filesystem (see [figure 6.4](/book/kubernetes-in-action/chapter-6/ch06fig04)). Pods running on the same node and using the same path in their `hostPath` volume see the same files.

![Figure 6.4. A hostPath volume mounts a file or directory on the worker node into the container’s filesystem.](https://drek4537l1klr.cloudfront.net/luksa/Figures/06fig04_alt.jpg)

`hostPath` volumes are the first type of persistent storage we’re introducing, because both the `gitRepo` and `emptyDir` volumes’ contents get deleted when a pod is torn down, whereas a `hostPath` volume’s contents don’t. If a pod is deleted and the next pod uses a `hostPath` volume pointing to the same path on the host, the new pod will see whatever was left behind by the previous pod, but only if it’s scheduled to the same node as the first pod.

If you’re thinking of using a `hostPath` volume as the place to store a database’s data directory, think again. Because the volume’s contents are stored on a specific node’s filesystem, when the database pod gets rescheduled to another node, it will no longer see the data. This explains why it’s not a good idea to use a `hostPath` volume for regular pods, because it makes the pod sensitive to what node it’s scheduled to.

### 6.3.2. Examining system pods that use hostPath volumes

Let’s see how a `hostPath` volume can be used properly. Instead of creating a new pod, let’s see if any existing system-wide pods are already using this type of volume. As you may remember from one of the previous chapters, several such pods are running in the `kube-system` namespace. Let’s list them again:

```bash
$ kubectl get pod s --namespace kube-system
NAME                          READY     STATUS    RESTARTS   AGE
fluentd-kubia-4ebc2f1e-9a3e   1/1       Running   1          4d
fluentd-kubia-4ebc2f1e-e2vz   1/1       Running   1          31d
...
```

Pick the first one and see what kinds of volumes it uses (shown in the following listing).

##### Listing 6.3. A pod using `hostPath` volumes to access the node’s logs

```bash
$ kubectl describe po fluentd-kubia-4ebc2f1e-9a3e --namespace kube-system
Name:           fluentd-cloud-logging-gke-kubia-default-pool-4ebc2f1e-9a3e
Namespace:      kube-system
...
Volumes:
  varlog:
    Type:       HostPath (bare host directory volume)
    Path:       /var/log
  varlibdockercontainers:
    Type:       HostPath (bare host directory volume)
    Path:       /var/lib/docker/containers
```

---

##### Tip

If you’re using Minikube, try the `kube-addon-manager-minikube` pod.

---

Aha! The pod uses two `hostPath` volumes to gain access to the node’s /var/log and the /var/lib/docker/containers directories. You’d think you were lucky to find a pod using a `hostPath` volume on the first try, but not really (at least not on GKE). Check the other pods, and you’ll see most use this type of volume either to access the node’s log files, kubeconfig (the Kubernetes config file), or the CA certificates.

If you inspect the other pods, you’ll see none of them uses the `hostPath` volume for storing their own data. They all use it to get access to the node’s data. But as we’ll see later in the chapter, `hostPath` volumes are often used for trying out persistent storage in single-node clusters, such as the one created by Minikube. Read on to learn about the types of volumes you should use for storing persistent data properly even in a multi-node cluster.

---

##### Tip

Remember to use `hostPath` volumes only if you need to read or write system files on the node. Never use them to persist data across pods.

---

## 6.4. Using persistent storage

When an application running in a pod needs to persist data to disk and have that same data available even when the pod is rescheduled to another node, you can’t use any of the volume types we’ve mentioned so far. Because this data needs to be accessible from any cluster node, it must be stored on some type of network-attached storage (NAS).

To learn about volumes that allow persisting data, you’ll create a pod that will run the MongoDB document-oriented NoSQL database. Running a database pod without a volume or with a non-persistent volume doesn’t make sense, except for testing purposes, so you’ll add an appropriate type of volume to the pod and mount it in the MongoDB container.

### 6.4.1. Using a GCE Persistent Disk in a pod volume

If you’ve been running these examples on Google Kubernetes Engine, which runs your cluster nodes on Google Compute Engine (GCE), you’ll use a GCE Persistent Disk as your underlying storage mechanism.

In the early versions, Kubernetes didn’t provision the underlying storage automatically—you had to do that manually. Automatic provisioning is now possible, and you’ll learn about it later in the chapter, but first, you’ll start by provisioning the storage manually. It will give you a chance to learn exactly what’s going on underneath.

##### Creating a GCE Persistent Disk

You’ll start by creating the GCE persistent disk first. You need to create it in the same zone as your Kubernetes cluster. If you don’t remember what zone you created the cluster in, you can see it by listing your Kubernetes clusters with the `gcloud` command like this:

```bash
$ gcloud container clusters list
NAME   ZONE            MASTER_VERSION  MASTER_IP       ...
kubia  europe-west1-b  1.2.5           104.155.84.137  ...
```

This shows you’ve created your cluster in zone `europe-west1-b`, so you need to create the GCE persistent disk in the same zone as well. You create the disk like this:

```bash
$ gcloud compute disks create --size=1GiB --zone=europe-west1-b mongodb
WARNING: You have selected a disk size of under [200GB]. This may result in
     poor I/O performance. For more information, see:
     https://developers.google.com/compute/docs/disks#pdperformance.
Created [https://www.googleapis.com/compute/v1/projects/rapid-pivot-
     136513/zones/europe-west1-b/disks/mongodb].
NAME     ZONE            SIZE_GB  TYPE         STATUS
mongodb  europe-west1-b  1        pd-standard  READY
```

This command creates a 1 GiB large GCE persistent disk called `mongodb`. You can ignore the warning about the disk size, because you don’t care about the disk’s performance for the tests you’re about to run.

##### Creating a pod using a gcePersistentDisk volume

Now that you have your physical storage properly set up, you can use it in a volume inside your MongoDB pod. You’re going to prepare the YAML for the pod, which is shown in the following listing.

##### Listing 6.4. A pod using a `gcePersistentDisk` volume: mongodb-pod-gcepd.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mongodb
spec:
  volumes:
  - name: mongodb-data
    gcePersistentDisk:
      pdName: mongodb
      fsType: ext4
  containers:
  - image: mongo
    name: mongodb
    volumeMounts:
    - name: mongodb-data
      mountPath: /data/db

    ports:
    - containerPort: 27017
      protocol: TCP
```

---

##### Note

If you’re using Minikube, you can’t use a GCE Persistent Disk, but you can deploy `mongodb-pod-hostpath.yaml`, which uses a `hostPath` volume instead of a GCE PD.

---

The pod contains a single container and a single volume backed by the GCE Persistent Disk you’ve created (as shown in [figure 6.5](/book/kubernetes-in-action/chapter-6/ch06fig05)). You’re mounting the volume inside the container at /data/db, because that’s where MongoDB stores its data.

![Figure 6.5. A pod with a single container running MongoDB, which mounts a volume referencing an external GCE Persistent Disk](https://drek4537l1klr.cloudfront.net/luksa/Figures/06fig05_alt.jpg)

##### Writing data to the persistent storage by adding documents to you- ur MongoDB database

Now that you’ve created the pod and the container has been started, you can run the MongoDB shell inside the container and use it to write some data to the data store.

You’ll run the shell as shown in the following listing.

##### Listing 6.5. Entering the MongoDB shell inside the `mongodb` pod

```bash
$ kubectl exec -it mongodb mongo
MongoDB shell version: 3.2.8
connecting to: mongodb://127.0.0.1:27017
Welcome to the MongoDB shell.
For interactive help, type "help".
For more comprehensive documentation, see
    http://docs.mongodb.org/
Questions? Try the support group
    http://groups.google.com/group/mongodb-user
...
>
```

MongoDB allows storing JSON documents, so you’ll store one to see if it’s stored persistently and can be retrieved after the pod is re-created. Insert a new JSON document with the following commands:

```
> use mystore
switched to db mystore
> db.foo.insert({name:'foo'})
WriteResult({ "nInserted" : 1 })
```

You’ve inserted a simple JSON document with a single property (`name: 'foo')`. Now, use the `find()` command to see the document you inserted:

```
> db.foo.find()
{ "_id" : ObjectId("57a61eb9de0cfd512374cc75"), "name" : "foo" }
```

There it is. The document should be stored in your GCE persistent disk now.

##### Re-creating the pod and verifying that it can read the data persi- isted by the previous pod

You can now exit the `mongodb` shell (type `exit` and press Enter), and then delete the pod and recreate it:

```bash
$ kubectl delete pod mongodb
pod "mongodb" deleted
$ kubectl create -f mongodb-pod-gcepd.yaml
pod "mongodb" created
```

The new pod uses the exact same GCE persistent disk as the previous pod, so the MongoDB container running inside it should see the exact same data, even if the pod is scheduled to a different node.

---

##### Tip

You can see what node a pod is scheduled to by running `kubectl get po -o wide`.

---

Once the container is up, you can again run the MongoDB shell and check to see if the document you stored earlier can still be retrieved, as shown in the following listing.

##### Listing 6.6. Retrieving MongoDB’s persisted data in a new pod

```bash
$ kubectl exec -it mongodb mongo
MongoDB shell version: 3.2.8
connecting to: mongodb://127.0.0.1:27017
Welcome to the MongoDB shell.
...
> use mystore
switched to db mystore
> db.foo.find()
{ "_id" : ObjectId("57a61eb9de0cfd512374cc75"), "name" : "foo" }
```

As expected, the data is still there, even though you deleted the pod and re-created it. This confirms you can use a GCE persistent disk to persist data across multiple pod instances.

You’re done playing with the MongoDB pod, so go ahead and delete it again, but hold off on deleting the underlying GCE persistent disk. You’ll use it again later in the chapter.

### 6.4.2. Using other types of volumes with underlying persistent storage

The reason you created the GCE Persistent Disk volume is because your Kubernetes cluster runs on Google Kubernetes Engine. When you run your cluster elsewhere, you should use other types of volumes, depending on the underlying infrastructure.

If your Kubernetes cluster is running on Amazon’s AWS EC2, for example, you can use an `awsElasticBlockStore` volume to provide persistent storage for your pods. If your cluster runs on Microsoft Azure, you can use the `azureFile` or the `azureDisk` volume. We won’t go into detail on how to do that here, but it’s virtually the same as in the previous example. First, you need to create the actual underlying storage, and then set the appropriate properties in the volume definition.

##### Using an AWS Elastic Block Store volume

For example, to use an AWS elastic block store instead of the GCE Persistent Disk, you’d only need to change the volume definition as shown in the following listing (see those lines printed in bold).

##### Listing 6.7. A pod using an `awsElasticBlockStore` volume: mongodb-pod-aws.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mongodb
spec:
  volumes:
  - name: mongodb-data
    awsElasticBlockStore:
      volumeId: my-volume
      fsType: ext4
  containers:
  - ...
```

##### Using an NFS volume

If your cluster is running on your own set of servers, you have a vast array of other supported options for mounting external storage inside your volume. For example, to mount a simple NFS share, you only need to specify the NFS server and the path exported by the server, as shown in the following listing.

##### Listing 6.8. A pod using an `nfs` volume: mongodb-pod-nfs.yaml

```
volumes:
  - name: mongodb-data
    nfs:                      #1
      server: 1.2.3.4         #2
      path: /some/path        #3
```

##### Using other storage technologies

Other supported options include `iscsi` for mounting an ISCSI disk resource, `glusterfs` for a GlusterFS mount, `rbd` for a RADOS Block Device, `flexVolume`, `cinder`, `cephfs`, `flocker`, `fc` (Fibre Channel), and others. You don’t need to know all of them if you’re not using them. They’re mentioned here to show you that Kubernetes supports a broad range of storage technologies and you can use whichever you prefer and are used to.

To see details on what properties you need to set for each of these volume types, you can either turn to the Kubernetes API definitions in the Kubernetes API reference or look up the information through `kubectl explain`, as shown in [chapter 3](/book/kubernetes-in-action/chapter-3/ch03). If you’re already familiar with a particular storage technology, using the `explain` command should allow you to easily figure out how to mount a volume of the proper type and use it in your pods.

But does a developer need to know all this stuff? Should a developer, when creating a pod, have to deal with infrastructure-related storage details, or should that be left to the cluster administrator?

Having a pod’s volumes refer to the actual underlying infrastructure isn’t what Kubernetes is about, is it? For example, for a developer to have to specify the hostname of the NFS server feels wrong. And that’s not even the worst thing about it.

Including this type of infrastructure-related information into a pod definition means the pod definition is pretty much tied to a specific Kubernetes cluster. You can’t use the same pod definition in another one. That’s why using volumes like this isn’t the best way to attach persistent storage to your pods. You’ll learn how to improve on this in the next section.

## 6.5. Decoupling pods from the underlying storage technology

All the persistent volume types we’ve explored so far have required the developer of the pod to have knowledge of the actual network storage infrastructure available in the cluster. For example, to create a NFS-backed volume, the developer has to know the actual server the NFS export is located on. This is against the basic idea of Kubernetes, which aims to hide the actual infrastructure from both the application and its developer, leaving them free from worrying about the specifics of the infrastructure and making apps portable across a wide array of cloud providers and on-premises datacenters.

Ideally, a developer deploying their apps on Kubernetes should never have to know what kind of storage technology is used underneath, the same way they don’t have to know what type of physical servers are being used to run their pods. Infrastructure-related dealings should be the sole domain of the cluster administrator.

When a developer needs a certain amount of persistent storage for their application, they can request it from Kubernetes, the same way they can request CPU, memory, and other resources when creating a pod. The system administrator can configure the cluster so it can give the apps what they request.

### 6.5.1. Introducing PersistentVolumes and PersistentVolumeClaims

To enable apps to request storage in a Kubernetes cluster without having to deal with infrastructure specifics, two new resources were introduced. They are Persistent-Volumes and PersistentVolumeClaims. The names may be a bit misleading, because as you’ve seen in the previous few sections, even regular Kubernetes volumes can be used to store persistent data.

Using a PersistentVolume inside a pod is a little more complex than using a regular pod volume, so let’s illustrate how pods, PersistentVolumeClaims, PersistentVolumes, and the actual underlying storage relate to each other in [figure 6.6](/book/kubernetes-in-action/chapter-6/ch06fig06).

![Figure 6.6. PersistentVolumes are provisioned by cluster admins and consumed by pods through PersistentVolumeClaims.](https://drek4537l1klr.cloudfront.net/luksa/Figures/06fig06_alt.jpg)

Instead of the developer adding a technology-specific volume to their pod, it’s the cluster administrator who sets up the underlying storage and then registers it in Kubernetes by creating a PersistentVolume resource through the Kubernetes API server. When creating the PersistentVolume, the admin specifies its size and the access modes it supports.

When a cluster user needs to use persistent storage in one of their pods, they first create a PersistentVolumeClaim manifest, specifying the minimum size and the access mode they require. The user then submits the PersistentVolumeClaim manifest to the Kubernetes API server, and Kubernetes finds the appropriate PersistentVolume and binds the volume to the claim.

The PersistentVolumeClaim can then be used as one of the volumes inside a pod. Other users cannot use the same PersistentVolume until it has been released by deleting the bound PersistentVolumeClaim.

### 6.5.2. Creating a PersistentVolume

Let’s revisit the MongoDB example, but unlike before, you won’t reference the GCE Persistent Disk in the pod directly. Instead, you’ll first assume the role of a cluster administrator and create a PersistentVolume backed by the GCE Persistent Disk. Then you’ll assume the role of the application developer and first claim the PersistentVolume and then use it inside your pod.

In [section 6.4.1](/book/kubernetes-in-action/chapter-6/ch06lev2sec7) you set up the physical storage by provisioning the GCE Persistent Disk, so you don’t need to do that again. All you need to do is create the Persistent-Volume resource in Kubernetes by preparing the manifest shown in the following listing and posting it to the API server.

##### Listing 6.9. A `gcePersistentDisk` PersistentVolume: mongodb-pv-gcepd.yaml

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mongodb-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
  - ReadWriteOnce
  - ReadOnlyMany
  persistentVolumeReclaimPolicy: Retain
  gcePersistentDisk:
    pdName: mongodb
    fsType: ext4
```

---

##### Note

If you’re using Minikube, create the PV using the mongodb-pv-hostpath.yaml file.

---

When creating a PersistentVolume, the administrator needs to tell Kubernetes what its capacity is and whether it can be read from and/or written to by a single node or by multiple nodes at the same time. They also need to tell Kubernetes what to do with the PersistentVolume when it’s released (when the PersistentVolumeClaim it’s bound to is deleted). And last, but certainly not least, they need to specify the type, location, and other properties of the actual storage this PersistentVolume is backed by. If you look closely, this last part is exactly the same as earlier, when you referenced the GCE Persistent Disk in the pod volume directly (shown again in the following listing).

##### Listing 6.10. Referencing a GCE PD in a pod’s volume

```
spec:
  volumes:
  - name: mongodb-data
    gcePersistentDisk:
      pdName: mongodb
      fsType: ext4
  ...
```

After you create the PersistentVolume with the `kubectl create` command, it should be ready to be claimed. See if it is by listing all PersistentVolumes:

```bash
$ kubectl get pv
NAME         CAPACITY   RECLAIMPOLICY   ACCESSMODES   STATUS      CLAIM
mongodb-pv   1Gi        Retain          RWO,ROX       Available
```

---

##### Note

Several columns are omitted. Also, `pv` is used as a shorthand for `persistentvolume`.

---

As expected, the PersistentVolume is shown as Available, because you haven’t yet created the PersistentVolumeClaim.

---

##### Note

PersistentVolumes don’t belong to any namespace (see [figure 6.7](#ch06fig07)). They’re cluster-level resources like nodes.

---

![Figure 6.7. PersistentVolumes, like cluster Nodes, don’t belong to any namespace, unlike pods and PersistentVolumeClaims.](https://drek4537l1klr.cloudfront.net/luksa/Figures/06fig07_alt.jpg)

### 6.5.3. Claiming a PersistentVolume by creating a PersistentVolumeClaim

Now let’s lay down our admin hats and put our developer hats back on. Say you need to deploy a pod that requires persistent storage. You’ll use the PersistentVolume you created earlier. But you can’t use it directly in the pod. You need to claim it first.

Claiming a PersistentVolume is a completely separate process from creating a pod, because you want the same PersistentVolumeClaim to stay available even if the pod is rescheduled (remember, rescheduling means the previous pod is deleted and a new one is created).

##### Creating a PersistentVolumeClaim

You’ll create the claim now. You need to prepare a PersistentVolumeClaim manifest like the one shown in the following listing and post it to the Kubernetes API through `kubectl create`.

##### Listing 6.11. A `PersistentVolumeClaim`: mongodb-pvc.yaml

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mongodb-pvc
spec:
  resources:
    requests:
      storage: 1Gi
  accessModes:
  - ReadWriteOnce
  storageClassName: ""
```

As soon as you create the claim, Kubernetes finds the appropriate PersistentVolume and binds it to the claim. The PersistentVolume’s capacity must be large enough to accommodate what the claim requests. Additionally, the volume’s access modes must include the access modes requested by the claim. In your case, the claim requests 1 GiB of storage and a `ReadWriteOnce` access mode. The PersistentVolume you created earlier matches those two requirements so it is bound to your claim. You can see this by inspecting the claim.

##### Listing PersistentVolumeClaims

List all PersistentVolumeClaims to see the state of your PVC:

```bash
$ kubectl get pvc
NAME          STATUS    VOLUME       CAPACITY   ACCESSMODES   AGE
mongodb-pvc   Bound     mongodb-pv   1Gi        RWO,ROX       3s
```

---

##### Note

We’re using `pvc` as a shorthand for `persistentvolumeclaim`.

---

The claim is shown as `Bound` to PersistentVolume `mongodb-pv`. Note the abbreviations used for the access modes:

- `RWO`—`ReadWriteOnce`—Only a single node can mount the volume for reading and writing.
- `ROX`—`ReadOnlyMany`—Multiple nodes can mount the volume for reading.
- `RWX`—`ReadWriteMany`—Multiple nodes can mount the volume for both reading and writing.

---

##### Note

`RWO`, `ROX`, and `RWX` pertain to the number of worker nodes that can use the volume at the same time, not to the number of pods!

---

##### Listing PersistentVolumes

You can also see that the PersistentVolume is now `Bound` and no longer `Available` by inspecting it with `kubectl get`:

```bash
$ kubectl get pv
NAME         CAPACITY   ACCESSMODES   STATUS   CLAIM                 AGE
mongodb-pv   1Gi        RWO,ROX       Bound    default/mongodb-pvc   1m
```

The PersistentVolume shows it’s bound to claim `default/mongodb-pvc`. The `default` part is the namespace the claim resides in (you created the claim in the default namespace). We’ve already said that PersistentVolume resources are cluster-scoped and thus cannot be created in a specific namespace, but PersistentVolumeClaims can only be created in a specific namespace. They can then only be used by pods in the same namespace.

### 6.5.4. Using a PersistentVolumeClaim in a pod

The PersistentVolume is now yours to use. Nobody else can claim the same volume until you release it. To use it inside a pod, you need to reference the PersistentVolumeClaim by name inside the pod’s volume (yes, the PersistentVolumeClaim, not the PersistentVolume directly!), as shown in the following listing.

##### Listing 6.12. A pod using a PersistentVolumeClaim volume: mongodb-pod-pvc.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mongodb
spec:
  containers:
  - image: mongo
    name: mongodb
    volumeMounts:
    - name: mongodb-data
      mountPath: /data/db
    ports:
    - containerPort: 27017
      protocol: TCP
  volumes:
  - name: mongodb-data
    persistentVolumeClaim:
      claimName: mongodb-pvc
```

Go ahead and create the pod. Now, check to see if the pod is indeed using the same PersistentVolume and its underlying GCE PD. You should see the data you stored earlier by running the MongoDB shell again, as shown in the following listing.

##### Listing 6.13. Retrieving MongoDB’s persisted data in the pod using the PVC and PV

```bash
$ kubectl exec -it mongodb mongo
MongoDB shell version: 3.2.8
connecting to: mongodb://127.0.0.1:27017
Welcome to the MongoDB shell.
...
> use mystore
switched to db mystore
> db.foo.find()
{ "_id" : ObjectId("57a61eb9de0cfd512374cc75"), "name" : "foo" }
```

And there it is. You‘re able to retrieve the document you stored into MongoDB previously.

### 6.5.5. Understanding the benefits of using PersistentVolumes and claims

Examine [figure 6.8](/book/kubernetes-in-action/chapter-6/ch06fig08), which shows both ways a pod can use a GCE Persistent Disk—directly or through a PersistentVolume and claim.

![Figure 6.8. Using the GCE Persistent Disk directly or through a PVC and PV](https://drek4537l1klr.cloudfront.net/luksa/Figures/06fig08_alt.jpg)

Consider how using this indirect method of obtaining storage from the infrastructure is much simpler for the application developer (or cluster user). Yes, it does require the additional steps of creating the PersistentVolume and the Persistent-VolumeClaim, but the developer doesn’t have to know anything about the actual storage technology used underneath.

Additionally, the same pod and claim manifests can now be used on many different Kubernetes clusters, because they don’t refer to anything infrastructure-specific. The claim states, “I need *x* amount of storage and I need to be able to read and write to it by a single client at once,” and then the pod references the claim by name in one of its volumes.

### 6.5.6. Recycling PersistentVolumes

Before you wrap up this section on PersistentVolumes, let’s do one last quick experiment. Delete the pod and the PersistentVolumeClaim:

```bash
$ kubectl delete pod mongodb
pod "mongodb" deleted
$ kubectl delete pvc mongodb-pvc
persistentvolumeclaim "mongodb-pvc" deleted
```

What if you create the PersistentVolumeClaim again? Will it be bound to the Persistent-Volume or not? After you create the claim, what does `kubectl get pvc` show?

```bash
$ kubectl get pvc
NAME           STATUS    VOLUME       CAPACITY   ACCESSMODES   AGE
mongodb-pvc    Pending                                         13s
```

The claim’s status is shown as `Pending`. Interesting. When you created the claim earlier, it was immediately bound to the PersistentVolume, so why wasn’t it bound now? Maybe listing the PersistentVolumes can shed more light on this:

```bash
$ kubectl get pv
NAME        CAPACITY  ACCESSMODES  STATUS    CLAIM               REASON AGE
mongodb-pv  1Gi       RWO,ROX      Released  default/mongodb-pvc        5m
```

The `STATUS` column shows the PersistentVolume as `Released`, not `Available` like before. Because you’ve already used the volume, it may contain data and shouldn’t be bound to a completely new claim without giving the cluster admin a chance to clean it up. Without this, a new pod using the same PersistentVolume could read the data stored there by the previous pod, even if the claim and pod were created in a different namespace (and thus likely belong to a different cluster tenant).

##### Reclaiming PersistentVolumes manually

You told Kubernetes you wanted your PersistentVolume to behave like this when you created it—by setting its `persistentVolumeReclaimPolicy` to `Retain`. You wanted Kubernetes to retain the volume and its contents after it’s released from its claim. As far as I’m aware, the only way to manually recycle the PersistentVolume to make it available again is to delete and recreate the PersistentVolume resource. As you do that, it’s your decision what to do with the files on the underlying storage: you can either delete them or leave them alone so they can be reused by the next pod.

##### Reclaiming PersistentVolumes automatically

Two other possible reclaim policies exist: `Recycle` and `Delete`. The first one deletes the volume’s contents and makes the volume available to be claimed again. This way, the PersistentVolume can be reused multiple times by different PersistentVolumeClaims and different pods, as you can see in [figure 6.9](/book/kubernetes-in-action/chapter-6/ch06fig09).

![Figure 6.9. The lifespan of a PersistentVolume, PersistentVolumeClaims, and pods using them](https://drek4537l1klr.cloudfront.net/luksa/Figures/06fig09_alt.jpg)

The `Delete` policy, on the other hand, deletes the underlying storage. Note that the `Recycle` option is currently not available for GCE Persistent Disks. This type of a PersistentVolume only supports the `Retain` or `Delete` policies. Other PersistentVolume types may or may not support each of these options, so before creating your own PersistentVolume, be sure to check what reclaim policies are supported for the specific underlying storage you’ll use in the volume.

---

##### Tip

You can change the PersistentVolume reclaim policy on an existing PersistentVolume. For example, if it’s initially set to `Delete`, you can easily change it to `Retain` to prevent losing valuable data.

---

## 6.6. Dynamic provisioning of PersistentVolumes

You’ve seen how using PersistentVolumes and PersistentVolumeClaims makes it easy to obtain persistent storage without the developer having to deal with the actual storage technology used underneath. But this still requires a cluster administrator to provision the actual storage up front. Luckily, Kubernetes can also perform this job automatically through dynamic provisioning of PersistentVolumes.

The cluster admin, instead of creating PersistentVolumes, can deploy a PersistentVolume provisioner and define one or more StorageClass objects to let users choose what type of PersistentVolume they want. The users can refer to the `StorageClass` in their PersistentVolumeClaims and the provisioner will take that into account when provisioning the persistent storage.

---

##### Note

Similar to PersistentVolumes, StorageClass resources aren’t namespaced.

---

Kubernetes includes provisioners for the most popular cloud providers, so the administrator doesn’t always need to deploy a provisioner. But if Kubernetes is deployed on-premises, a custom provisioner needs to be deployed.

Instead of the administrator pre-provisioning a bunch of PersistentVolumes, they need to define one or two (or more) StorageClasses and let the system create a new PersistentVolume each time one is requested through a PersistentVolumeClaim. The great thing about this is that it’s impossible to run out of PersistentVolumes (obviously, you can run out of storage space).

### 6.6.1. Defining the available storage types through StorageClass resources

Before a user can create a PersistentVolumeClaim, which will result in a new Persistent-Volume being provisioned, an admin needs to create one or more StorageClass resources. Let’s look at an example of one in the following listing.

##### Listing 6.14. A StorageClass definition: storageclass-fast-gcepd.yaml

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast
provisioner: kubernetes.io/gce-pd
parameters:
  type: pd-ssd
  zone: europe-west1-b
```

---

##### Note

If using Minikube, deploy the file storageclass-fast-hostpath.yaml.

---

The StorageClass resource specifies which provisioner should be used for provisioning the PersistentVolume when a PersistentVolumeClaim requests this StorageClass. The parameters defined in the StorageClass definition are passed to the provisioner and are specific to each provisioner plugin.

The StorageClass uses the Google Compute Engine (GCE) Persistent Disk (PD) provisioner, which means it can be used when Kubernetes is running in GCE. For other cloud providers, other provisioners need to be used.

### 6.6.2. Requesting the storage class in a PersistentVolumeClaim

After the StorageClass resource is created, users can refer to the storage class by name in their PersistentVolumeClaims.

##### Creating a PVC definition requesting a specific storage class

You can modify your `mongodb-pvc` to use dynamic provisioning. The following listing shows the updated YAML definition of the PVC.

##### Listing 6.15. A PVC with dynamic provisioning: mongodb-pvc-dp.yaml

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mongodb-pvc
spec:
  storageClassName: fast
  resources:
    requests:
      storage: 100Mi
  accessModes:
    - ReadWriteOnce
```

Apart from specifying the size and access modes, your PersistentVolumeClaim now also specifies the class of storage you want to use. When you create the claim, the PersistentVolume is created by the provisioner referenced in the `fast` StorageClass resource. The provisioner is used even if an existing manually provisioned PersistentVolume matches the PersistentVolumeClaim.

---

##### Note

If you reference a non-existing storage class in a PVC, the provisioning of the PV will fail (you’ll see a `ProvisioningFailed` event when you use `kubectl describe` on the PVC).

---

##### Examining the created PVC and the dynamically provisioned PV

Next you’ll create the PVC and then use `kubectl get` to see it:

```bash
$ kubectl get pvc mongodb-pvc
NAME          STATUS   VOLUME         CAPACITY   ACCESSMODES   STORAGECLASS
mongodb-pvc   Bound    pvc-1e6bc048   1Gi        RWO           fast
```

The `VOLUME` column shows the PersistentVolume that’s bound to this claim (the actual name is longer than what’s shown above). You can try listing PersistentVolumes now to see that a new PV has indeed been created automatically:

```bash
$ kubectl get pv
NAME           CAPACITY  ACCESSMODES  RECLAIMPOLICY  STATUS    STORAGECLASS
mongodb-pv     1Gi       RWO,ROX      Retain         Released
pvc-1e6bc048   1Gi       RWO          Delete         Bound     fast
```

---

##### Note

Only pertinent columns are shown.

---

You can see the dynamically provisioned PersistentVolume. Its capacity and access modes are what you requested in the PVC. Its reclaim policy is `Delete`, which means the PersistentVolume will be deleted when the PVC is deleted. Beside the PV, the provisioner also provisioned the actual storage. Your `fast` StorageClass is configured to use the `kubernetes.io/gce-pd` provisioner, which provisions GCE Persistent Disks. You can see the disk with the following command:

```bash
$ gcloud compute disks list
NAME                          ZONE            SIZE_GB  TYPE         STATUS
gke-kubia-dyn-pvc-1e6bc048    europe-west1-d  1        pd-ssd       READY
gke-kubia-default-pool-71df   europe-west1-d  100      pd-standard  READY
gke-kubia-default-pool-79cd   europe-west1-d  100      pd-standard  READY
gke-kubia-default-pool-blc4   europe-west1-d  100      pd-standard  READY
mongodb                       europe-west1-d  1        pd-standard  READY
```

As you can see, the first persistent disk’s name suggests it was provisioned dynamically and its type shows it’s an SSD, as specified in the storage class you created earlier.

##### Understanding how to use storage classes

The cluster admin can create multiple storage classes with different performance or other characteristics. The developer then decides which one is most appropriate for each claim they create.

The nice thing about StorageClasses is the fact that claims refer to them by name. The PVC definitions are therefore portable across different clusters, as long as the StorageClass names are the same across all of them. To see this portability yourself, you can try running the same example on Minikube, if you’ve been using GKE up to this point. As a cluster admin, you’ll have to create a different storage class (but with the same name). The storage class defined in the storageclass-fast-hostpath.yaml file is tailor-made for use in Minikube. Then, once you deploy the storage class, you as a cluster user can deploy the exact same PVC manifest and the exact same pod manifest as before. This shows how the pods and PVCs are portable across different clusters.

### 6.6.3. Dynamic provisioning without specifying a storage class

As we’ve progressed through this chapter, attaching persistent storage to pods has become ever simpler. The sections in this chapter reflect how provisioning of storage has evolved from early Kubernetes versions to now. In this final section, we’ll look at the latest and simplest way of attaching a PersistentVolume to a pod.

##### Listing storage classes

When you created your custom storage class called `fast`, you didn’t check if any existing storage classes were already defined in your cluster. Why don’t you do that now? Here are the storage classes available in GKE:

```bash
$ kubectl get sc
NAME                 TYPE
fast                 kubernetes.io/gce-pd
standard (default)   kubernetes.io/gce-pd
```

---

##### Note

We’re using `sc` as shorthand for `storageclass`.

---

Beside the `fast` storage class, which you created yourself, a `standard` storage class exists and is marked as default. You’ll learn what that means in a moment. Let’s list the storage classes available in Minikube, so we can compare:

```bash
$ kubectl get sc
NAME                 TYPE
fast                 k8s.io/minikube-hostpath
standard (default)   k8s.io/minikube-hostpath
```

Again, the `fast` storage class was created by you and a default `standard` storage class exists here as well. Comparing the `TYPE` columns in the two listings, you see GKE is using the `kubernetes.io/gce-pd` provisioner, whereas Minikube is using `k8s.io/ minikube-hostpath`.

##### Examining the default storage class

You’re going to use `kubectl get` to see more info about the standard storage class in a GKE cluster, as shown in the following listing.

##### Listing 6.16. The definition of the standard storage class on GKE

```bash
$ kubectl get sc standard -o yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  annotations:
    storageclass.beta.kubernetes.io/is-default-class: "true"     #1
  creationTimestamp: 2017-05-16T15:24:11Z
  labels:
    addonmanager.kubernetes.io/mode: EnsureExists
    kubernetes.io/cluster-service: "true"
  name: standard
  resourceVersion: "180"
  selfLink: /apis/storage.k8s.io/v1/storageclassesstandard
  uid: b6498511-3a4b-11e7-ba2c-42010a840014
parameters:                                                      #2
  type: pd-standard                                              #2
provisioner: kubernetes.io/gce-pd                                #3
```

If you look closely toward the top of the listing, the storage class definition includes an annotation, which makes this the default storage class. The default storage class is what’s used to dynamically provision a PersistentVolume if the PersistentVolumeClaim doesn’t explicitly say which storage class to use.

##### Creating a PersistentVolumeClaim without specifying a storage class

You can create a PVC without specifying the `storageClassName` attribute and (on Google Kubernetes Engine) a GCE Persistent Disk of type `pd-standard` will be provisioned for you. Try this by creating a claim from the YAML in the following listing.

##### Listing 6.17. PVC with no storage class defined: mongodb-pvc-dp-nostorageclass.yaml

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mongodb-pvc2
spec:
  resources:
    requests:
      storage: 100Mi
  accessModes:
    - ReadWriteOnce
```

This PVC definition includes only the storage size request and the desired access modes, but no storage class. When you create the PVC, whatever storage class is marked as default will be used. You can confirm that’s the case:

```bash
$ kubectl get pvc mongodb-pvc2
NAME          STATUS   VOLUME         CAPACITY   ACCESSMODES   STORAGECLASS
mongodb-pvc2  Bound    pvc-95a5ec12   1Gi        RWO           standard

$ kubectl get pv pvc-95a5ec12
NAME           CAPACITY  ACCESSMODES  RECLAIMPOLICY  STATUS    STORAGECLASS
pvc-95a5ec12   1Gi       RWO          Delete         Bound     standard

$ gcloud compute disks list
NAME                          ZONE            SIZE_GB  TYPE         STATUS
gke-kubia-dyn-pvc-95a5ec12    europe-west1-d  1        pd-standard  READY
...
```

##### Forcing a PersistentVolumeClaim to be bound to one of the pre-pro- ovisioned PersistentVolumes

This finally brings us to why you set `storageClassName` to an empty string in [listing 6.11](/book/kubernetes-in-action/chapter-6/ch06ex11) (when you wanted the PVC to bind to the PV you’d provisioned manually). Let me repeat the relevant lines of that PVC definition here:

```yaml
kind: PersistentVolumeClaim
spec:
  storageClassName: ""
```

If you hadn’t set the `storageClassName` attribute to an empty string, the dynamic volume provisioner would have provisioned a new PersistentVolume, despite there being an appropriate pre-provisioned PersistentVolume. At that point, I wanted to demonstrate how a claim gets bound to a manually pre-provisioned PersistentVolume. I didn’t want the dynamic provisioner to interfere.

---

##### Tip

Explicitly set `storageClassName` to `""` if you want the PVC to use a pre-provisioned PersistentVolume.

---

##### Understanding the complete picture of dynamic PersistentVolume provisioning

This brings us to the end of this chapter. To summarize, the best way to attach persistent storage to a pod is to only create the PVC (with an explicitly specified `storageClassName` if necessary) and the pod (which refers to the PVC by name). Everything else is taken care of by the dynamic PersistentVolume provisioner.

To get a complete picture of the steps involved in getting a dynamically provisioned PersistentVolume, examine [figure 6.10](/book/kubernetes-in-action/chapter-6/ch06fig10).

![Figure 6.10. The complete picture of dynamic provisioning of PersistentVolumes](https://drek4537l1klr.cloudfront.net/luksa/Figures/06fig10_alt.jpg)

## 6.7. Summary

This chapter has shown you how volumes are used to provide either temporary or persistent storage to a pod’s containers. You’ve learned how to

- Create a multi-container pod and have the pod’s containers operate on the same files by adding a volume to the pod and mounting it in each container
- Use the `emptyDir` volume to store temporary, non-persistent data
- Use the `gitRepo` volume to easily populate a directory with the contents of a Git repository at pod startup
- Use the `hostPath` volume to access files from the host node
- Mount external storage in a volume to persist pod data across pod restarts
- Decouple the pod from the storage infrastructure by using PersistentVolumes and PersistentVolumeClaims
- Have PersistentVolumes of the desired (or the default) storage class dynamically provisioned for each PersistentVolumeClaim
- Prevent the dynamic provisioner from interfering when you want the PersistentVolumeClaim to be bound to a pre-provisioned PersistentVolume

In the next chapter, you’ll see what mechanisms Kubernetes provides to deliver configuration data, secret information, and metadata about the pod and container to the processes running inside a pod. This is done with the special types of volumes we’ve mentioned in this chapter, but not yet explored.
