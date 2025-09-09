# Chapter 10. StatefulSets: deploying replicated stateful applications

### **This chapter covers**

- Deploying stateful clustered applications
- Providing separate storage for each instance of a replicated pod
- Guaranteeing a stable name and hostname for pod replicas
- Starting and stopping pod replicas in a predictable order
- Discovering peers through DNS SRV records

You now know how to run both single-instance and replicated stateless pods, and even stateful pods utilizing persistent storage. You can run several replicated web-server pod instances and you can run a single database pod instance that uses persistent storage, provided either through plain pod volumes or through Persistent-Volumes bound by a PersistentVolumeClaim. But can you employ a ReplicaSet to replicate the database pod?

## 10.1. Replicating stateful pods

ReplicaSets create multiple pod replicas from a single pod template. These replicas don’t differ from each other, apart from their name and IP address. If the pod template includes a volume, which refers to a specific PersistentVolumeClaim, all replicas of the ReplicaSet will use the exact same PersistentVolumeClaim and therefore the same PersistentVolume bound by the claim (shown in [figure 10.1](/book/kubernetes-in-action/chapter-10/ch10fig01)).

![Figure 10.1. All pods from the same ReplicaSet always use the same PersistentVolumeClaim and PersistentVolume.](https://drek4537l1klr.cloudfront.net/luksa/Figures/10fig01_alt.jpg)

Because the reference to the claim is in the pod template, which is used to stamp out multiple pod replicas, you can’t make each replica use its own separate Persistent-VolumeClaim. You can’t use a ReplicaSet to run a distributed data store, where each instance needs its own separate storage—at least not by using a single ReplicaSet. To be honest, none of the API objects you’ve seen so far make running such a data store possible. You need something else.

### 10.1.1. Running multiple replicas with separate storage for each

How does one run multiple replicas of a pod and have each pod use its own storage volume? ReplicaSets create exact copies (replicas) of a pod; therefore you can’t use them for these types of pods. What can you use?

##### Creating pods manually

You could create pods manually and have each of them use its own PersistentVolumeClaim, but because no ReplicaSet looks after them, you’d need to manage them manually and recreate them when they disappear (as in the event of a node failure). Therefore, this isn’t a viable option.

##### Using one ReplicaSet per pod instance

Instead of creating pods directly, you could create multiple ReplicaSets—one for each pod with each ReplicaSet’s desired replica count set to one, and each ReplicaSet’s pod template referencing a dedicated PersistentVolumeClaim (as shown in [figure 10.2](/book/kubernetes-in-action/chapter-10/ch10fig02)).

![Figure 10.2. Using one ReplicaSet for each pod instance](https://drek4537l1klr.cloudfront.net/luksa/Figures/10fig02.jpg)

Although this takes care of the automatic rescheduling in case of node failures or accidental pod deletions, it’s much more cumbersome compared to having a single ReplicaSet. For example, think about how you’d scale the pods in that case. You couldn’t change the desired replica count—you’d have to create additional ReplicaSets instead.

Using multiple ReplicaSets is therefore not the best solution. But could you maybe use a single ReplicaSet and have each pod instance keep its own persistent state, even though they’re all using the same storage volume?

##### Using multiple directories in the same volume

A trick you can use is to have all pods use the same PersistentVolume, but then have a separate file directory inside that volume for each pod (this is shown in [figure 10.3](/book/kubernetes-in-action/chapter-10/ch10fig03)).

![Figure 10.3. Working around the shared storage problem by having the app in each pod use a different file directory](https://drek4537l1klr.cloudfront.net/luksa/Figures/10fig03_alt.jpg)

Because you can’t configure pod replicas differently from a single pod template, you can’t tell each instance what directory it should use, but you can make each instance automatically select (and possibly also create) a data directory that isn’t being used by any other instance at that time. This solution does require coordination between the instances, and isn’t easy to do correctly. It also makes the shared storage volume the bottleneck.

### 10.1.2. Providing a stable identity for each pod

In addition to storage, certain clustered applications also require that each instance has a long-lived stable identity. Pods can be killed from time to time and replaced with new ones. When a ReplicaSet replaces a pod, the new pod is a completely new pod with a new hostname and IP, although the data in its storage volume may be that of the killed pod. For certain apps, starting up with the old instance’s data but with a completely new network identity may cause problems.

Why do certain apps mandate a stable network identity? This requirement is fairly common in distributed stateful applications. Certain apps require the administrator to list all the other cluster members and their IP addresses (or hostnames) in each member’s configuration file. But in Kubernetes, every time a pod is rescheduled, the new pod gets both a new hostname and a new IP address, so the whole application cluster would have to be reconfigured every time one of its members is rescheduled.

##### Using a dedicated service for each pod instance

A trick you can use to work around this problem is to provide a stable network address for cluster members by creating a dedicated Kubernetes Service for each individual member. Because service IPs are stable, you can then point to each member through its service IP (rather than the pod IP) in the configuration.

This is similar to creating a ReplicaSet for each member to provide them with individual storage, as described previously. Combining these two techniques results in the setup shown in [figure 10.4](/book/kubernetes-in-action/chapter-10/ch10fig04) (an additional service covering all the cluster members is also shown, because you usually need one for clients of the cluster).

![Figure 10.4. Using one Service and ReplicaSet per pod to provide a stable network address and an individual volume for each pod, respectively](https://drek4537l1klr.cloudfront.net/luksa/Figures/10fig04.jpg)

The solution is not only ugly, but it still doesn’t solve everything. The individual pods can’t know which Service they are exposed through (and thus can’t know their stable IP), so they can’t self-register in other pods using that IP.

Luckily, Kubernetes saves us from resorting to such complex solutions. The proper clean and simple way of running these special types of applications in Kubernetes is through a StatefulSet.

## 10.2. Understanding StatefulSets

Instead of using a ReplicaSet to run these types of pods, you create a StatefulSet resource, which is specifically tailored to applications where instances of the application must be treated as non-fungible individuals, with each one having a stable name and state.

### 10.2.1. Comparing StatefulSets with ReplicaSets

To understand the purpose of StatefulSets, it’s best to compare them to ReplicaSets or ReplicationControllers. But first let me explain them with a little analogy that’s widely used in the field.

##### Understanding stateful pods with the pets vs. cattle analogy

You may have already heard of the pets vs. cattle analogy. If not, let me explain it. We can treat our apps either as pets or as cattle.

---

##### Note

StatefulSets were initially called PetSets. That name comes from the pets vs. cattle analogy explained here.

---

We tend to treat our app instances as pets, where we give each instance a name and take care of each instance individually. But it’s usually better to treat instances as cattle and not pay special attention to each individual instance. This makes it easy to replace unhealthy instances without giving it a second thought, similar to the way a farmer replaces unhealthy cattle.

Instances of a stateless app, for example, behave much like heads of cattle. It doesn’t matter if an instance dies—you can create a new instance and people won’t notice the difference.

On the other hand, with stateful apps, an app instance is more like a pet. When a pet dies, you can’t go buy a new one and expect people not to notice. To replace a lost pet, you need to find a new one that looks and behaves exactly like the old one. In the case of apps, this means the new instance needs to have the same state and identity as the old one.

##### Comparing StatefulSets with ReplicaSets or ReplicationControllers

Pod replicas managed by a ReplicaSet or ReplicationController are much like cattle. Because they’re mostly stateless, they can be replaced with a completely new pod replica at any time. Stateful pods require a different approach. When a stateful pod instance dies (or the node it’s running on fails), the pod instance needs to be resurrected on another node, but the new instance needs to get the same name, network identity, and state as the one it’s replacing. This is what happens when the pods are managed through a StatefulSet.

A StatefulSet makes sure pods are rescheduled in such a way that they retain their identity and state. It also allows you to easily scale the number of pets up and down. A StatefulSet, like a ReplicaSet, has a desired replica count field that determines how many pets you want running at that time. Similar to ReplicaSets, pods are created from a pod template specified as part of the StatefulSet (remember the cookie-cutter analogy?). But unlike pods created by ReplicaSets, pods created by the StatefulSet aren’t exact replicas of each other. Each can have its own set of volumes—in other words, storage (and thus persistent state)—which differentiates it from its peers. Pet pods also have a predictable (and stable) identity instead of each new pod instance getting a completely random one.

### 10.2.2. Providing a stable network identity

Each pod created by a StatefulSet is assigned an ordinal index (zero-based), which is then used to derive the pod’s name and hostname, and to attach stable storage to the pod. The names of the pods are thus predictable, because each pod’s name is derived from the StatefulSet’s name and the ordinal index of the instance. Rather than the pods having random names, they’re nicely organized, as shown in the next figure.

![Figure 10.5. Pods created by a StatefulSet have predictable names (and hostnames), unlike those created by a ReplicaSet](https://drek4537l1klr.cloudfront.net/luksa/Figures/10fig05_alt.jpg)

##### Introducing the governing Service

But it’s not all about the pods having a predictable name and hostname. Unlike regular pods, stateful pods sometimes need to be addressable by their hostname, whereas stateless pods usually don’t. After all, each stateless pod is like any other. When you need one, you pick any one of them. But with stateful pods, you usually want to operate on a specific pod from the group, because they differ from each other (they hold different state, for example).

For this reason, a StatefulSet requires you to create a corresponding governing headless Service that’s used to provide the actual network identity to each pod. Through this Service, each pod gets its own DNS entry, so its peers and possibly other clients in the cluster can address the pod by its hostname. For example, if the governing Service belongs to the `default` namespace and is called `foo`, and one of the pods is called `A-0`, you can reach the pod through its fully qualified domain name, which is `a-0.foo.default.svc.cluster.local`. You can’t do that with pods managed by a ReplicaSet.

Additionally, you can also use DNS to look up all the StatefulSet’s pods’ names by looking up SRV records for the `foo.default.svc.cluster.local` domain. We’ll explain SRV records in [section 10.4](/book/kubernetes-in-action/chapter-10/ch10lev1sec4) and learn how they’re used to discover members of a StatefulSet.

##### Replacing lost pets

When a pod instance managed by a StatefulSet disappears (because the node the pod was running on has failed, it was evicted from the node, or someone deleted the pod object manually), the StatefulSet makes sure it’s replaced with a new instance—similar to how ReplicaSets do it. But in contrast to ReplicaSets, the replacement pod gets the same name and hostname as the pod that has disappeared (this distinction between ReplicaSets and StatefulSets is illustrated in [figure 10.6](/book/kubernetes-in-action/chapter-10/ch10fig06)).

![Figure 10.6. A StatefulSet replaces a lost pod with a new one with the same identity, whereas a ReplicaSet replaces it with a completely new unrelated pod.](https://drek4537l1klr.cloudfront.net/luksa/Figures/10fig06_alt.jpg)

The new pod isn’t necessarily scheduled to the same node, but as you learned early on, what node a pod runs on shouldn’t matter. This holds true even for stateful pods. Even if the pod is scheduled to a different node, it will still be available and reachable under the same hostname as before.

##### Scaling a StatefulSet

Scaling the StatefulSet creates a new pod instance with the next unused ordinal index. If you scale up from two to three instances, the new instance will get index 2 (the existing instances obviously have indexes 0 and 1).

The nice thing about scaling down a StatefulSet is the fact that you always know what pod will be removed. Again, this is also in contrast to scaling down a ReplicaSet, where you have no idea what instance will be deleted, and you can’t even specify which one you want removed first (but this feature may be introduced in the future). Scaling down a StatefulSet always removes the instances with the highest ordinal index first (shown in [figure 10.7](/book/kubernetes-in-action/chapter-10/ch10fig07)). This makes the effects of a scale-down predictable.

![Figure 10.7. Scaling down a StatefulSet always removes the pod with the highest ordinal index first.](https://drek4537l1klr.cloudfront.net/luksa/Figures/10fig07_alt.jpg)

Because certain stateful applications don’t handle rapid scale-downs nicely, StatefulSets scale down only one pod instance at a time. A distributed data store, for example, may lose data if multiple nodes go down at the same time. For example, if a replicated data store is configured to store two copies of each data entry, in cases where two nodes go down at the same time, a data entry would be lost if it was stored on exactly those two nodes. If the scale-down was sequential, the distributed data store has time to create an additional replica of the data entry somewhere else to replace the (single) lost copy.

For this exact reason, StatefulSets also never permit scale-down operations if any of the instances are unhealthy. If an instance is unhealthy, and you scale down by one at the same time, you’ve effectively lost two cluster members at once.

### 10.2.3. Providing stable dedicated storage to each stateful instance

You’ve seen how StatefulSets ensure stateful pods have a stable identity, but what about storage? Each stateful pod instance needs to use its own storage, plus if a stateful pod is rescheduled (replaced with a new instance but with the same identity as before), the new instance must have the same storage attached to it. How do Stateful-Sets achieve this?

Obviously, storage for stateful pods needs to be persistent and decoupled from the pods. In [chapter 6](/book/kubernetes-in-action/chapter-6/ch06) you learned about PersistentVolumes and PersistentVolumeClaims, which allow persistent storage to be attached to a pod by referencing the Persistent-VolumeClaim in the pod by name. Because PersistentVolumeClaims map to PersistentVolumes one-to-one, each pod of a StatefulSet needs to reference a different PersistentVolumeClaim to have its own separate PersistentVolume. Because all pod instances are stamped from the same pod template, how can they each refer to a different PersistentVolumeClaim? And who creates these claims? Surely you’re not expected to create as many PersistentVolumeClaims as the number of pods you plan to have in the StatefulSet upfront? Of course not.

##### Teaming up pod templates with volume claim templates

The StatefulSet has to create the PersistentVolumeClaims as well, the same way it’s creating the pods. For this reason, a StatefulSet can also have one or more volume claim templates, which enable it to stamp out PersistentVolumeClaims along with each pod instance (see [figure 10.8](/book/kubernetes-in-action/chapter-10/ch10fig08)).

![Figure 10.8. A StatefulSet creates both pods and PersistentVolumeClaims.](https://drek4537l1klr.cloudfront.net/luksa/Figures/10fig08_alt.jpg)

The PersistentVolumes for the claims can either be provisioned up-front by an administrator or just in time through dynamic provisioning of PersistentVolumes, as explained at the end of [chapter 6](/book/kubernetes-in-action/chapter-6/ch06).

##### Understanding the creation and deletion of PersistentVolumeClaims

Scaling up a StatefulSet by one creates two or more API objects (the pod and one or more PersistentVolumeClaims referenced by the pod). Scaling down, however, deletes only the pod, leaving the claims alone. The reason for this is obvious, if you consider what happens when a claim is deleted. After a claim is deleted, the PersistentVolume it was bound to gets recycled or deleted and its contents are lost.

Because stateful pods are meant to run stateful applications, which implies that the data they store in the volume is important, deleting the claim on scale-down of a Stateful-Set could be catastrophic—especially since triggering a scale-down is as simple as decreasing the `replicas` field of the StatefulSet. For this reason, you’re required to delete PersistentVolumeClaims manually to release the underlying PersistentVolume.

##### Reattaching the PersistentVolumeClaim to the new instance of the same pod

The fact that the PersistentVolumeClaim remains after a scale-down means a subsequent scale-up can reattach the same claim along with the bound PersistentVolume and its contents to the new pod instance (shown in [figure 10.9](/book/kubernetes-in-action/chapter-10/ch10fig09)). If you accidentally scale down a StatefulSet, you can undo the mistake by scaling up again and the new pod will get the same persisted state again (as well as the same name).

![Figure 10.9. StatefulSets don’t delete PersistentVolumeClaims when scaling down; then they reattach them when scaling back up.](https://drek4537l1klr.cloudfront.net/luksa/Figures/10fig09_alt.jpg)

### 10.2.4. Understanding StatefulSet guarantees

As you’ve seen so far, StatefulSets behave differently from ReplicaSets or ReplicationControllers. But this doesn’t end with the pods having a stable identity and storage. StatefulSets also have different guarantees regarding their pods.

##### Understanding the implications of stable identity and storage

While regular, stateless pods are fungible, stateful pods aren’t. We’ve already seen how a stateful pod is always replaced with an identical pod (one having the same name and hostname, using the same persistent storage, and so on). This happens when Kubernetes sees that the old pod is no longer there (for example, when you delete the pod manually).

But what if Kubernetes can’t be sure about the state of the pod? If it creates a replacement pod with the same identity, two instances of the app with the same identity might be running in the system. The two would also be bound to the same storage, so two processes with the same identity would be writing over the same files. With pods managed by a ReplicaSet, this isn’t a problem, because the apps are obviously made to work on the same files. Also, ReplicaSets create pods with a randomly generated identity, so there’s no way for two processes to run with the same identity.

##### Introducing StatefulSet’s at-most-one semantics

Kubernetes must thus take great care to ensure two stateful pod instances are never running with the same identity and are bound to the same PersistentVolumeClaim. A StatefulSet must guarantee *at-most-one* semantics for stateful pod instances.

This means a StatefulSet must be absolutely certain that a pod is no longer running before it can create a replacement pod. This has a big effect on how node failures are handled. We’ll demonstrate this later in the chapter. Before we can do that, however, you need to create a StatefulSet and see how it behaves. You’ll also learn a few more things about them along the way.

## 10.3. Using a StatefulSet

To properly show StatefulSets in action, you’ll build your own little clustered data store. Nothing fancy—more like a data store from the Stone Age.

### 10.3.1. Creating the app and container image

You’ll use the kubia app you’ve used throughout the book as your starting point. You’ll expand it so it allows you to store and retrieve a single data entry on each pod instance.

The important parts of the source code of your data store are shown in the following listing.

##### Listing 10.1. A simple stateful app: kubia-pet-image/app.js

```javascript
...
const dataFile = "/var/data/kubia.txt";
...
var handler = function(request, response) {
  if (request.method == 'POST') {
    var file = fs.createWriteStream(dataFile);                     #1
    file.on('open', function (fd) {                                #1
      request.pipe(file);                                          #1
      console.log("New data has been received and stored.");       #1
      response.writeHead(200);                                     #1
      response.end("Data stored on pod " + os.hostname() + "\n");  #1
    });
  } else {
    var data = fileExists(dataFile)                                #2
      ? fs.readFileSync(dataFile, 'utf8')                          #2
      : "No data posted yet";                                      #2
    response.writeHead(200);                                       #2
    response.write("You've hit " + os.hostname() + "\n");          #2
    response.end("Data stored on this pod: " + data + "\n");       #2
  }
};

var www = http.createServer(handler);
www.listen(8080);
```

Whenever the app receives a POST request, it writes the data it receives in the body of the request to the file `/`var/data/kubia.txt. Upon a GET request, it returns the hostname and the stored data (contents of the file). Simple enough, right? This is the first version of your app. It’s not clustered yet, but it’s enough to get you started. You’ll expand the app later in the chapter.

The Dockerfile for building the container image is shown in the following listing and hasn’t changed from before.

##### Listing 10.2. Dockerfile for the stateful app: kubia-pet-image/Dockerfile

```dockerfile
FROM node:7
ADD app.js /app.js
ENTRYPOINT ["node", "app.js"]
```

Go ahead and build the image now, or use the one I pushed to docker.io/luksa/kubia-pet.

### 10.3.2. Deploying the app through a StatefulSet

To deploy your app, you’ll need to create two (or three) different types of objects:

- PersistentVolumes for storing your data files (you’ll need to create these only if the cluster doesn’t support dynamic provisioning of PersistentVolumes).
- A governing Service required by the StatefulSet.
- The StatefulSet itself.

For each pod instance, the StatefulSet will create a PersistentVolumeClaim that will bind to a PersistentVolume. If your cluster supports dynamic provisioning, you don’t need to create any PersistentVolumes manually (you can skip the next section). If it doesn’t, you’ll need to create them as explained in the next section.

##### Creating the persistent volumes

You’ll need three PersistentVolumes, because you’ll be scaling the StatefulSet up to three replicas. You must create more if you plan on scaling the StatefulSet up more than that.

If you’re using Minikube, deploy the PersistentVolumes defined in the Chapter10/persistent-volumes-hostpath.yaml file in the book’s code archive.

If you’re using Google Kubernetes Engine, you’ll first need to create the actual GCE Persistent Disks like this:

```bash
$ gcloud compute disks create --size=1GiB --zone=europe-west1-b pv-a
$ gcloud compute disks create --size=1GiB --zone=europe-west1-b pv-b
$ gcloud compute disks create --size=1GiB --zone=europe-west1-b pv-c
```

---

##### Note

Make sure to create the disks in the same zone that your nodes are running in.

---

Then create the PersistentVolumes from the persistent-volumes-gcepd.yaml file, which is shown in the following listing.

##### Listing 10.3. Three PersistentVolumes: persistent-volumes-gcepd.yaml

```yaml
kind: List
apiVersion: v1
items:
- apiVersion: v1
  kind: PersistentVolume
  metadata:
    name: pv-a
  spec:
    capacity:
      storage: 1Mi
    accessModes:
      - ReadWriteOnce
    persistentVolumeReclaimPolicy: Recycle
    gcePersistentDisk:

      pdName: pv-a

      fsType: nfs4

- apiVersion: v1
  kind: PersistentVolume
  metadata:
    name: pv-b
 ...
```

---

##### Note

In the previous chapter you specified multiple resources in the same YAML by delimiting them with a three-dash line. Here you’re using a different approach by defining a `List` object and listing the resources as items of the object. Both methods are equivalent.

---

This manifest creates PersistentVolumes called `pv-a`, `pv-b`, and `pv-c`. They use GCE Persistent Disks as the underlying storage mechanism, so they’re not appropriate for clusters that aren’t running on Google Kubernetes Engine or Google Compute Engine. If you’re running the cluster elsewhere, you must modify the PersistentVolume definition and use an appropriate volume type, such as NFS (Network File System), or similar.

##### Creating the governing Service

As explained earlier, before deploying a StatefulSet, you first need to create a headless Service, which will be used to provide the network identity for your stateful pods. The following listing shows the Service manifest.

##### Listing 10.4. Headless service to be used in the StatefulSet: kubia-service-headless.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: kubia
spec:
  clusterIP: None
  selector:
    app: kubia
  ports:
  - name: http
    port: 80
```

You’re setting the `clusterIP` field to `None`, which makes this a headless Service. It will enable peer discovery between your pods (you’ll need this later). Once you create the Service, you can move on to creating the actual StatefulSet.

##### Creating the StatefulSet manifest

Now you can finally create the StatefulSet. The following listing shows the manifest.

##### Listing 10.5. StatefulSet manifest: kubia-statefulset.yaml

```yaml
apiVersion: apps/v1beta1
kind: StatefulSet
metadata:
  name: kubia
spec:
  serviceName: kubia
  replicas: 2
  template:
    metadata:
      labels:
        app: kubia
    spec:
      containers:
      - name: kubia
        image: luksa/kubia-pet
        ports:
        - name: http
          containerPort: 8080
        volumeMounts:
        - name: data
          mountPath: /var/data
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      resources:
        requests:
          storage: 1Mi
      accessModes:
      - ReadWriteOnce
```

The StatefulSet manifest isn’t that different from ReplicaSet or Deployment manifests you’ve created so far. What’s new is the `volumeClaimTemplates` list. In it, you’re defining one volume claim template called `data`, which will be used to create a PersistentVolumeClaim for each pod. As you may remember from [chapter 6](/book/kubernetes-in-action/chapter-6/ch06), a pod references a claim by including a `persistentVolumeClaim` volume in the manifest. In the previous pod template, you’ll find no such volume. The StatefulSet adds it to the pod specification automatically and configures the volume to be bound to the claim the StatefulSet created for the specific pod.

##### Creating the StatefulSet

You’ll create the StatefulSet now:

```bash
$ kubectl create -f kubia-statefulset.yaml
statefulset "kubia" created
```

Now, list your pods:

```bash
$ kubectl get po
NAME      READY     STATUS              RESTARTS   AGE
kubia-0   0/1       ContainerCreating   0          1s
```

Notice anything strange? Remember how a ReplicationController or a ReplicaSet creates all the pod instances at the same time? Your StatefulSet is configured to create two replicas, but it created a single pod.

Don’t worry, nothing is wrong. The second pod will be created only after the first one is up and ready. StatefulSets behave this way because certain clustered stateful apps are sensitive to race conditions if two or more cluster members come up at the same time, so it’s safer to bring each member up fully before continuing to bring up the rest.

List the pods again to see how the pod creation is progressing:

```bash
$ kubectl get po
NAME      READY     STATUS              RESTARTS   AGE
kubia-0   1/1       Running             0          8s
kubia-1   0/1       ContainerCreating   0          2s
```

See, the first pod is now running, and the second one has been created and is being started.

##### Examining the generated stateful pod

Let’s take a closer look at the first pod’s spec in the following listing to see how the StatefulSet has constructed the pod from the pod template and the PersistentVolumeClaim template.

##### Listing 10.6. A stateful pod created by the StatefulSet

```bash
$ kubectl get po kubia-0 -o yaml
apiVersion: v1
kind: Pod
metadata:
  ...
spec:
  containers:
  - image: luksa/kubia-pet
    ...
    volumeMounts:
    - mountPath: /var/data                 #1
      name: data                           #1
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: default-token-r2m41
      readOnly: true
  ...
  volumes:
  - name: data                             #2
    persistentVolumeClaim:                 #2
      claimName: data-kubia-0              #3
  - name: default-token-r2m41
    secret:
      secretName: default-token-r2m41
```

The PersistentVolumeClaim template was used to create the PersistentVolumeClaim and the volume inside the pod, which refers to the created PersistentVolumeClaim.

##### Examining the generated PersistentVolumeClaims

Now list the generated PersistentVolumeClaims to confirm they were created:

```bash
$ kubectl get pvc
NAME           STATUS    VOLUME    CAPACITY   ACCESSMODES   AGE
data-kubia-0   Bound     pv-c      0                        37s
data-kubia-1   Bound     pv-a      0                        37s
```

The names of the generated PersistentVolumeClaims are composed of the name defined in the `volumeClaimTemplate` and the name of each pod. You can examine the claims’ YAML to see that they match the template.

### 10.3.3. Playing with your pods

With the nodes of your data store cluster now running, you can start exploring it. You can’t communicate with your pods through the Service you created because it’s headless. You’ll need to connect to individual pods directly (or create a regular Service, but that wouldn’t allow you to talk to a specific pod).

You’ve already seen ways to connect to a pod directly: by piggybacking on another pod and running `curl` inside it, by using port-forwarding, and so on. This time, you’ll try another option. You’ll use the API server as a proxy to the pods.

##### Communicating with pods through the API server

One useful feature of the API server is the ability to proxy connections directly to individual pods. If you want to perform requests against your `kubia-0` pod, you hit the following URL:

```
<apiServerHost>:<port>/api/v1/namespaces/default/pods/kubia-0/proxy/<path>
```

Because the API server is secured, sending requests to pods through the API server is cumbersome (among other things, you need to pass the authorization token in each request). Luckily, in [chapter 8](/book/kubernetes-in-action/chapter-8/ch08) you learned how to use `kubectl proxy` to talk to the API server without having to deal with authentication and SSL certificates. Run the proxy again:

```bash
$ kubectl proxy
Starting to serve on 127.0.0.1:8001
```

Now, because you’ll be talking to the API server through the `kubectl` proxy, you’ll use localhost:8001 rather than the actual API server host and port. You’ll send a request to the `kubia-0` pod like this:

```bash
$ curl localhost:8001/api/v1/namespaces/default/pods/kubia-0/proxy/
You've hit kubia-0
Data stored on this pod: No data posted yet
```

The response shows that the request was indeed received and handled by the app running in your pod `kubia-0`.

---

##### Note

If you receive an empty response, make sure you haven’t left out that last slash character at the end of the URL (or make sure `curl` follows redirects by using its `-L` option).

---

Because you’re communicating with the pod through the API server, which you’re connecting to through the `kubectl` proxy, the request went through two different proxies (the first was the `kubectl` proxy and the other was the API server, which proxied the request to the pod). For a clearer picture, examine [figure 10.10](/book/kubernetes-in-action/chapter-10/ch10fig10).

![Figure 10.10. Connecting to a pod through both the kubectl proxy and API server proxy](https://drek4537l1klr.cloudfront.net/luksa/Figures/10fig10_alt.jpg)

The request you sent to the pod was a GET request, but you can also send POST requests through the API server. This is done by sending a POST request to the same proxy URL as the one you sent the GET request to.

When your app receives a POST request, it stores whatever’s in the request body into a local file. Send a POST request to the `kubia-0` pod:

```bash
$ curl -X POST -d "Hey there! This greeting was submitted to kubia-0."
➥  localhost:8001/api/v1/namespaces/default/pods/kubia-0/proxy/
Data stored on pod kubia-0
```

The data you sent should now be stored in that pod. Let’s see if it returns the stored data when you perform a GET request again:

```bash
$ curl localhost:8001/api/v1/namespaces/default/pods/kubia-0/proxy/
You've hit kubia-0
Data stored on this pod: Hey there! This greeting was submitted to kubia-0.
```

Okay, so far so good. Now let’s see what the other cluster node (the `kubia-1` pod) says:

```bash
$ curl localhost:8001/api/v1/namespaces/default/pods/kubia-1/proxy/
You've hit kubia-1
Data stored on this pod: No data posted yet
```

As expected, each node has its own state. But is that state persisted? Let’s find out.

##### Deleting a stateful pod to see if the rescheduled pod is reattach- hed to the same storage

You’re going to delete the `kubia-0` pod and wait for it to be rescheduled. Then you’ll see if it’s still serving the same data as before:

```bash
$ kubectl delete po kubia-0
pod "kubia-0" deleted
```

If you list the pods, you’ll see that the pod is terminating:

```bash
$ kubectl get po
NAME      READY     STATUS        RESTARTS   AGE
kubia-0   1/1       Terminating   0          3m
kubia-1   1/1       Running       0          3m
```

As soon as it terminates successfully, a new pod with the same name is created by the StatefulSet:

```bash
$ kubectl get po
NAME      READY     STATUS              RESTARTS   AGE
kubia-0   0/1       ContainerCreating   0          6s
kubia-1   1/1       Running             0          4m
$ kubectl get po
NAME      READY     STATUS    RESTARTS   AGE
kubia-0   1/1       Running   0          9s
kubia-1   1/1       Running   0          4m
```

Let me remind you again that this new pod may be scheduled to any node in the cluster, not necessarily the same node that the old pod was scheduled to. The old pod’s whole identity (the name, hostname, and the storage) is effectively moved to the new node (as shown in [figure 10.11](/book/kubernetes-in-action/chapter-10/ch10fig11)). If you’re using Minikube, you can’t see this because it only runs a single node, but in a multi-node cluster, you may see the pod scheduled to a different node than before.

![Figure 10.11. A stateful pod may be rescheduled to a different node, but it retains the name, hostname, and storage.](https://drek4537l1klr.cloudfront.net/luksa/Figures/10fig11_alt.jpg)

With the new pod now running, let’s check to see if it has the exact same identity as in its previous incarnation. The pod’s name is the same, but what about the hostname and persistent data? You can ask the pod itself to confirm:

```bash
$ curl localhost:8001/api/v1/namespaces/default/pods/kubia-0/proxy/
You've hit kubia-0
Data stored on this pod: Hey there! This greeting was submitted to kubia-0.
```

The pod’s response shows that both the hostname and the data are the same as before, confirming that a StatefulSet always replaces a deleted pod with what’s effectively the exact same pod.

##### Scaling a StatefulSet

Scaling down a StatefulSet and scaling it back up after an extended time period should be no different than deleting a pod and having the StatefulSet recreate it immediately. Remember that scaling down a StatefulSet only deletes the pods, but leaves the PersistentVolumeClaims untouched. I’ll let you try scaling down the StatefulSet yourself and confirm this behavior.

The key thing to remember is that scaling down (and up) is performed gradually—similar to how individual pods are created when the StatefulSet is created initially. When scaling down by more than one instance, the pod with the highest ordinal number is deleted first. Only after the pod terminates completely is the pod with the second highest ordinal number deleted.

##### Exposing stateful pods through a regular, non-headless Service

Before you move on to the last part of this chapter, you’re going to add a proper, non-headless Service in front of your pods, because clients usually connect to the pods through a Service rather than connecting directly.

You know how to create the Service by now, but in case you don’t, the following listing shows the manifest.

##### Listing 10.7. A regular Service for accessing the stateful pods: kubia-service-public.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: kubia-public
spec:
  selector:
    app: kubia
  ports:
  - port: 80
    targetPort: 8080
```

Because this isn’t an externally exposed Service (it’s a regular `ClusterIP` Service, not a `NodePort` or a `LoadBalancer`-type Service), you can only access it from inside the cluster. You’ll need a pod to access it from, right? Not necessarily.

##### Connecting to cluster-internal services through the API server

Instead of using a piggyback pod to access the service from inside the cluster, you can use the same proxy feature provided by the API server to access the service the way you’ve accessed individual pods.

The URI path for proxy-ing requests to Services is formed like this:

```
/api/v1/namespaces/<namespace>/services/<service name>/proxy/<path>
```

Therefore, you can run `curl` on your local machine and access the service through the `kubectl` proxy like this (you ran `kubectl proxy` earlier and it should still be running):

```bash
$ curl localhost:8001/api/v1/namespaces/default/services/kubia-
➥  public/proxy/
You've hit kubia-1
Data stored on this pod: No data posted yet
```

Likewise, clients (inside the cluster) can use the `kubia-public` service for storing to and reading data from your clustered data store. Of course, each request lands on a random cluster node, so you’ll get the data from a random node each time. You’ll improve this next.

## 10.4. Discovering peers in a StatefulSet

We still need to cover one more important thing. An important requirement of clustered apps is peer discovery—the ability to find other members of the cluster. Each member of a StatefulSet needs to easily find all the other members. Sure, it could do that by talking to the API server, but one of Kubernetes’ aims is to expose features that help keep applications completely Kubernetes-agnostic. Having apps talk to the Kubernetes API is therefore undesirable.

How can a pod discover its peers without talking to the API? Is there an existing, well-known technology you can use that makes this possible? How about the Domain Name System (DNS)? Depending on how much you know about DNS, you probably understand what an A, CNAME, or MX record is used for. Other lesser-known types of DNS records also exist. One of them is the SRV record.

##### Introducing SRV records

SRV records are used to point to hostnames and ports of servers providing a specific service. Kubernetes creates SRV records to point to the hostnames of the pods backing a headless service.

You’re going to list the SRV records for your stateful pods by running the `dig` DNS lookup tool inside a new temporary pod. This is the command you’ll use:

```bash
$ kubectl run -it srvlookup --image=tutum/dnsutils --rm
➥  --restart=Never -- dig SRV kubia.default.svc.cluster.local
```

The command runs a one-off pod (`--restart=Never`) called `srvlookup`, which is attached to the console (`-it`) and is deleted as soon as it terminates (`--rm`). The pod runs a single container from the `tutum/dnsutils` image and runs the following command:

```
dig SRV kubia.default.svc.cluster.local
```

The following listing shows what the command prints out.

##### Listing 10.8. Listing DNS SRV records of your headless Service

```
...
;; ANSWER SECTION:
k.d.s.c.l. 30 IN  SRV     10 33 0 kubia-0.kubia.default.svc.cluster.local.
k.d.s.c.l. 30 IN  SRV     10 33 0 kubia-1.kubia.default.svc.cluster.local.

;; ADDITIONAL SECTION:
kubia-0.kubia.default.svc.cluster.local. 30 IN A 172.17.0.4
kubia-1.kubia.default.svc.cluster.local. 30 IN A 172.17.0.6
...
```

---

##### Note

I’ve had to shorten the actual name to get records to fit into a single line, so `kubia.d.s.c.l` is actually `kubia.default.svc.cluster.local`.

---

The `ANSWER SECTION` shows two `SRV` records pointing to the two pods backing your headless service. Each pod also gets its own `A` record, as shown in `ADDITIONAL SECTION`.

For a pod to get a list of all the other pods of a StatefulSet, all you need to do is perform an SRV DNS lookup. In Node.js, for example, the lookup is performed like this:

```
dns.resolveSrv("kubia.default.svc.cluster.local", callBackFunction);
```

You’ll use this command in your app to enable each pod to discover its peers.

---

##### Note

The order of the returned SRV records is random, because they all have the same priority. Don’t expect to always see `kubia-0` listed before `kubia-1`.

---

### 10.4.1. Implementing peer discovery through DNS

Your Stone Age data store isn’t clustered yet. Each data store node runs completely independently of all the others—no communication exists between them. You’ll get them talking to each other next.

Data posted by clients connecting to your data store cluster through the `kubia-public` Service lands on a random cluster node. The cluster can store multiple data entries, but clients currently have no good way to see all those entries. Because services forward requests to pods randomly, a client would need to perform many requests until it hit all the pods if it wanted to get the data from all the pods.

You can improve this by having the node respond with data from all the cluster nodes. To do this, the node needs to find all its peers. You’re going to use what you learned about StatefulSets and SRV records to do this.

You’ll modify your app’s source code as shown in the following listing (the full source is available in the book’s code archive; the listing shows only the important parts).

##### Listing 10.9. Discovering peers in a sample app: kubia-pet-peers-image/app.js

```javascript
...
const dns = require('dns');

const dataFile = "/var/data/kubia.txt";
const serviceName = "kubia.default.svc.cluster.local";
const port = 8080;
...

var handler = function(request, response) {
  if (request.method == 'POST') {
    ...
  } else {
    response.writeHead(200);
    if (request.url == '/data') {
      var data = fileExists(dataFile)
        ? fs.readFileSync(dataFile, 'utf8')
        : "No data posted yet";
      response.end(data);
    } else {
      response.write("You've hit " + os.hostname() + "\n");
      response.write("Data stored in the cluster:\n");
      dns.resolveSrv(serviceName, function (err, addresses) {         #1
        if (err) {
          response.end("Could not look up DNS SRV records: " + err);
          return;
        }
        var numResponses = 0;
        if (addresses.length == 0) {
          response.end("No peers discovered.");
        } else {
          addresses.forEach(function (item) {                         #2
            var requestOptions = {
              host: item.name,
              port: port,
              path: '/data'
            };
            httpGet(requestOptions, function (returnedData) {         #2
              numResponses++;
              response.write("- " + item.name + ": " + returnedData);
              response.write("\n");
              if (numResponses == addresses.length) {
                response.end();
              }
            });
          });
        }
      });
    }
  }
};
...
```

[Figure 10.12](/book/kubernetes-in-action/chapter-10/ch10fig12) shows what happens when a GET request is received by your app. The server that receives the request first performs a lookup of SRV records for the headless `kubia` service and then sends a GET request to each of the pods backing the service (even to itself, which obviously isn’t necessary, but I wanted to keep the code as simple as possible). It then returns a list of all the nodes along with the data stored on each of them.

![Figure 10.12. The operation of your simplistic distributed data store](https://drek4537l1klr.cloudfront.net/luksa/Figures/10fig12_alt.jpg)

The container image containing this new version of the app is available at docker.io/ luksa/kubia-pet-peers.

### 10.4.2. Updating a StatefulSet

Your StatefulSet is already running, so let’s see how to update its pod template so the pods use the new image. You’ll also set the replica count to 3 at the same time. To update the StatefulSet, use the `kubectl edit` command (the `patch` command would be another option):

```bash
$ kubectl edit statefulset kubia
```

This opens the StatefulSet definition in your default editor. In the definition, change `spec.replicas` to `3` and modify the `spec.template.spec.containers.image` attribute so it points to the new image (`luksa/kubia-pet-peers` instead of `luksa/kubia-pet`). Save the file and exit the editor to update the StatefulSet. Two replicas were running previously, so you should now see an additional replica called `kubia-2` starting. List the pods to confirm:

```bash
$ kubectl get po
NAME      READY     STATUS              RESTARTS   AGE
kubia-0   1/1       Running             0          25m
kubia-1   1/1       Running             0          26m
kubia-2   0/1       ContainerCreating   0          4s
```

The new pod instance is running the new image. But what about the existing two replicas? Judging from their age, they don’t seem to have been updated. This is expected, because initially, StatefulSets were more like ReplicaSets and not like Deployments, so they don’t perform a rollout when the template is modified. You need to delete the replicas manually and the StatefulSet will bring them up again based on the new template:

```bash
$ kubectl delete po kubia-0 kubia-1
pod "kubia-0" deleted
pod "kubia-1" deleted
```

---

##### Note

Starting from Kubernetes version 1.7, StatefulSets support rolling updates the same way Deployments and DaemonSets do. See the StatefulSet’s `spec.updateStrategy` field documentation using `kubectl explain` for more information.

---

### 10.4.3. Trying out your clustered data store

Once the two pods are up, you can see if your shiny new Stone Age data store works as expected. Post a few requests to the cluster, as shown in the following listing.

##### Listing 10.10. Writing to the clustered data store through the service

```bash
$ curl -X POST -d "The sun is shining" \
➥  localhost:8001/api/v1/namespaces/default/services/kubia-public/proxy/
Data stored on pod kubia-1

$ curl -X POST -d "The weather is sweet" \
➥  localhost:8001/api/v1/namespaces/default/services/kubia-public/proxy/
Data stored on pod kubia-0
```

Now, read the stored data, as shown in the following listing.

##### Listing 10.11. Reading from the data store

```bash
$ curl localhost:8001/api/v1/namespaces/default/services
➥  /kubia-public/proxy/
You've hit kubia-2
Data stored on each cluster node:
- kubia-0.kubia.default.svc.cluster.local: The weather is sweet
- kubia-1.kubia.default.svc.cluster.local: The sun is shining
- kubia-2.kubia.default.svc.cluster.local: No data posted yet
```

Nice! When a client request reaches one of your cluster nodes, it discovers all its peers, gathers data from them, and sends all the data back to the client. Even if you scale the StatefulSet up or down, the pod servicing the client’s request can always find all the peers running at that time.

The app itself isn’t that useful, but I hope you found it a fun way to show how instances of a replicated stateful app can discover their peers and handle horizontal scaling with ease.

## 10.5. Understanding how StatefulSets deal with node failures

In [section 10.2.4](/book/kubernetes-in-action/chapter-10/ch10lev2sec6) we stated that Kubernetes must be absolutely sure that a stateful pod is no longer running before creating its replacement. When a node fails abruptly, Kubernetes can’t know the state of the node or its pods. It can’t know whether the pods are no longer running, or if they still are and are possibly even still reachable, and it’s only the Kubelet that has stopped reporting the node’s state to the master.

Because a StatefulSet guarantees that there will never be two pods running with the same identity and storage, when a node appears to have failed, the StatefulSet cannot and should not create a replacement pod until it knows for certain that the pod is no longer running.

It can only know that when the cluster administrator tells it so. To do that, the admin needs to either delete the pod or delete the whole node (doing so then deletes all the pods scheduled to the node).

As your final exercise in this chapter, you’ll look at what happens to StatefulSets and their pods when one of the cluster nodes gets disconnected from the network.

### 10.5.1. Simulating a node’s disconnection from the network

As in [chapter 4](/book/kubernetes-in-action/chapter-4/ch04), you’ll simulate the node disconnecting from the network by shutting down the node’s `eth0` network interface. Because this example requires multiple nodes, you can’t run it on Minikube. You’ll use Google Kubernetes Engine instead.

##### Shutting down the node’s network adapter

To shut down a node’s `eth0` interface, you need to `ssh` into one of the nodes like this:

```bash
$ gcloud compute ssh gke-kubia-default-pool-32a2cac8-m0g1
```

Then, inside the node, run the following command:

```bash
$ sudo ifconfig eth0 down
```

Your `ssh` session will stop working, so you’ll need to open another terminal to continue.

##### Checking the node’s status as seen by the Kubernetes master

With the node’s network interface down, the Kubelet running on the node can no longer contact the Kubernetes API server and let it know that the node and all its pods are still running.

After a while, the control plane will mark the node as `NotReady`. You can see this when listing nodes, as the following listing shows.

##### Listing 10.12. Observing a failed node’s status change to `NotReady`

```bash
$ kubectl get node
NAME                                   STATUS     AGE       VERSION
gke-kubia-default-pool-32a2cac8-596v   Ready      16m       v1.6.2
gke-kubia-default-pool-32a2cac8-m0g1   NotReady   16m       v1.6.2
gke-kubia-default-pool-32a2cac8-sgl7   Ready      16m       v1.6.2
```

Because the control plane is no longer getting status updates from the node, the status of all pods on that node is `Unknown`. This is shown in the pod list in the following listing.

##### Listing 10.13. Observing the pod’s status change after its node becomes `NotReady`

```bash
$ kubectl get po
NAME      READY     STATUS    RESTARTS   AGE
kubia-0   1/1       Unknown   0          15m
kubia-1   1/1       Running   0          14m
kubia-2   1/1       Running   0          13m
```

As you can see, the `kubia-0` pod’s status is no longer known because the pod was (and still is) running on the node whose network interface you shut down.

##### Understanding what happens to pods whose status is unknown

If the node were to come back online and report its and its pod statuses again, the pod would again be marked as `Running`. But if the pod’s status remains unknown for more than a few minutes (this time is configurable), the pod is automatically evicted from the node. This is done by the master (the Kubernetes control plane). It evicts the pod by deleting the pod resource.

When the Kubelet sees that the pod has been marked for deletion, it starts terminating the pod. In your case, the Kubelet can no longer reach the master (because you disconnected the node from the network), which means the pod will keep running.

Let’s examine the current situation. Use `kubectl describe` to display details about the `kubia-0` pod, as shown in the following listing.

##### Listing 10.14. Displaying details of the pod with the unknown status

```bash
$ kubectl describe po kubia-0
Name:        kubia-0
Namespace:   default
Node:        gke-kubia-default-pool-32a2cac8-m0g1/10.132.0.2
...
Status:      Terminating (expires Tue, 23 May 2017 15:06:09 +0200)
Reason:      NodeLost
Message:     Node gke-kubia-default-pool-32a2cac8-m0g1 which was
             running pod kubia-0 is unresponsive
```

The pod is shown as `Terminating`, with `NodeLost` listed as the reason for the termination. The message says the node is considered lost because it’s unresponsive.

---

##### Note

What’s shown here is the control plane’s view of the world. In reality, the pod’s container is still running perfectly fine. It isn’t terminating at all.

---

### 10.5.2. Deleting the pod manually

You know the node isn’t coming back, but you need all three pods running to handle clients properly. You need to get the `kubia-0` pod rescheduled to a healthy node. As mentioned earlier, you need to delete the node or the pod manually.

##### Deleting the pod in the usual way

Delete the pod the way you’ve always deleted pods:

```bash
$ kubectl delete po kubia-0
pod "kubia-0" deleted
```

All done, right? By deleting the pod, the StatefulSet should immediately create a replacement pod, which will get scheduled to one of the remaining nodes. List the pods again to confirm:

```bash
$ kubectl get po
NAME      READY     STATUS    RESTARTS   AGE
kubia-0   1/1       Unknown   0          15m
kubia-1   1/1       Running   0          14m
kubia-2   1/1       Running   0          13m
```

That’s strange. You deleted the pod a moment ago and `kubectl` said it had deleted it. Why is the same pod still there?

---

##### Note

The `kubia-0` pod in the listing isn’t a new pod with the same name—this is clear by looking at the `AGE` column. If it were new, its age would be merely a few seconds.

---

##### Understanding why the pod isn’t deleted

The pod was marked for deletion even before you deleted it. That’s because the control plane itself already deleted it (in order to evict it from the node).

If you look at [listing 10.14](/book/kubernetes-in-action/chapter-10/ch10ex14) again, you’ll see that the pod’s status is `Terminating`. The pod was already marked for deletion earlier and will be removed as soon as the Kubelet on its node notifies the API server that the pod’s containers have terminated. Because the node’s network is down, this will never happen.

##### Forcibly deleting the pod

The only thing you can do is tell the API server to delete the pod without waiting for the Kubelet to confirm that the pod is no longer running. You do that like this:

```bash
$ kubectl delete po kubia-0 --force --grace-period 0
warning: Immediate deletion does not wait for confirmation that the running
     resource has been terminated. The resource may continue to run on the
     cluster indefinitely.
pod "kubia-0" deleted
```

You need to use both the `--force` and `--grace-period 0` options. The warning displayed by `kubectl` notifies you of what you did. If you list the pods again, you’ll finally see a new `kubia-0` pod created:

```bash
$ kubectl get po
NAME          READY     STATUS              RESTARTS   AGE
kubia-0       0/1       ContainerCreating   0          8s
kubia-1       1/1       Running             0          20m
kubia-2       1/1       Running             0          19m
```

---

##### Warning

Don’t delete stateful pods forcibly unless you know the node is no longer running or is unreachable (and will remain so forever).

---

Before continuing, you may want to bring the node you disconnected back online. You can do that by restarting the node through the GCE web console or in a terminal by issuing the following command:

```bash
$ gcloud compute instances reset <node name>
```

## 10.6. Summary

This concludes the chapter on using StatefulSets to deploy stateful apps. This chapter has shown you how to

- Give replicated pods individual storage
- Provide a stable identity to a pod
- Create a StatefulSet and a corresponding headless governing Service
- Scale and update a StatefulSet
- Discover other members of the StatefulSet through DNS
- Connect to other members through their host names
- Forcibly delete stateful pods

Now that you know the major building blocks you can use to have Kubernetes run and manage your apps, we can look more closely at how it does that. In the next chapter, you’ll learn about the individual components that control the Kubernetes cluster and keep your apps running.
