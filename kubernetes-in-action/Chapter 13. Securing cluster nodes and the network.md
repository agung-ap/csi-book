# Chapter 13. Securing cluster nodes and the network

### **This chapter covers**

- Using the node’s default Linux namespaces in pods
- Running containers as different users
- Running privileged containers
- Adding or dropping a container’s kernel capabilities
- Defining security policies to limit what pods can do
- Securing the pod network

In the previous chapter, we talked about securing the API server. If an attacker gets access to the API server, they can run whatever they like by packaging their code into a container image and running it in a pod. But can they do any real damage? Aren’t containers isolated from other containers and from the node they’re running on?

Not necessarily. In this chapter, you’ll learn how to allow pods to access the resources of the node they’re running on. You’ll also learn how to configure the cluster so users aren’t able to do whatever they want with their pods. Then, in the last part of the chapter, you’ll also learn how to secure the network the pods use to communicate.

## 13.1. Using the host node’s namespaces in a pod

Containers in a pod usually run under separate Linux namespaces, which isolate their processes from processes running in other containers or in the node’s default namespaces.

For example, we learned that each pod gets its own IP and port space, because it uses its own network namespace. Likewise, each pod has its own process tree, because it has its own PID namespace, and it also uses its own IPC namespace, allowing only processes in the same pod to communicate with each other through the Inter-Process Communication mechanism (IPC).

### 13.1.1. Using the node’s network namespace in a pod

Certain pods (usually system pods) need to operate in the host’s default namespaces, allowing them to see and manipulate node-level resources and devices. For example, a pod may need to use the node’s network adapters instead of its own virtual network adapters. This can be achieved by setting the `hostNetwork` property in the pod spec to `true`.

In that case, the pod gets to use the node’s network interfaces instead of having its own set, as shown in [figure 13.1](/book/kubernetes-in-action/chapter-13/ch13fig01). This means the pod doesn’t get its own IP address and if it runs a process that binds to a port, the process will be bound to the node’s port.

![Figure 13.1. A pod with hostNetwork: true uses the node’s network interfaces instead of its own.](https://drek4537l1klr.cloudfront.net/luksa/Figures/13fig01_alt.jpg)

You can try running such a pod. The next listing shows an example pod manifest.

##### Listing 13.1. A pod using the node’s network namespace: pod-with-host-network.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-host-network
spec:
  hostNetwork: true
  containers:
  - name: main
    image: alpine
    command: ["/bin/sleep", "999999"]
```

After you run the pod, you can use the following command to see that it’s indeed using the host’s network namespace (it sees all the host’s network adapters, for example).

##### Listing 13.2. Network interfaces in a pod using the host’s network namespace

```bash
$ kubectl exec pod-with-host-network ifconfig
docker0   Link encap:Ethernet  HWaddr 02:42:14:08:23:47
          inet addr:172.17.0.1  Bcast:0.0.0.0  Mask:255.255.0.0
          ...

eth0      Link encap:Ethernet  HWaddr 08:00:27:F8:FA:4E
          inet addr:10.0.2.15  Bcast:10.0.2.255  Mask:255.255.255.0
          ...

lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          ...

veth1178d4f Link encap:Ethernet  HWaddr 1E:03:8D:D6:E1:2C
          inet6 addr: fe80::1c03:8dff:fed6:e12c/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
...
```

When the Kubernetes Control Plane components are deployed as pods (such as when you deploy your cluster with `kubeadm`, as explained in [appendix B](/book/kubernetes-in-action/appendix-b/app02)), you’ll find that those pods use the `hostNetwork` option, effectively making them behave as if they weren’t running inside a pod.

### 13.1.2. Binding to a host port without using the host’s network namespace

A related feature allows pods to bind to a port in the node’s default namespace, but still have their own network namespace. This is done by using the `hostPort` property in one of the container’s ports defined in the `spec.containers.ports` field.

Don’t confuse pods using `hostPort` with pods exposed through a `NodePort` service. They’re two different things, as explained in [figure 13.2](/book/kubernetes-in-action/chapter-13/ch13fig02).

![Figure 13.2. Difference between pods using a hostPort and pods behind a NodePort service.](https://drek4537l1klr.cloudfront.net/luksa/Figures/13fig02_alt.jpg)

The first thing you’ll notice in the figure is that when a pod is using a `hostPort`, a connection to the node’s port is forwarded directly to the pod running on that node, whereas with a `NodePort` service, a connection to the node’s port is forwarded to a randomly selected pod (possibly on another node). The other difference is that with pods using a `hostPort`, the node’s port is only bound on nodes that run such pods, whereas `NodePort` services bind the port on all nodes, even on those that don’t run such a pod (as on node 3 in the figure).

It’s important to understand that if a pod is using a specific host port, only one instance of the pod can be scheduled to each node, because two processes can’t bind to the same host port. The Scheduler takes this into account when scheduling pods, so it doesn’t schedule multiple pods to the same node, as shown in [figure 13.3](/book/kubernetes-in-action/chapter-13/ch13fig03). If you have three nodes and want to deploy four pod replicas, only three will be scheduled (one pod will remain Pending).

![Figure 13.3. If a host port is used, only a single pod instance can be scheduled to a node.](https://drek4537l1klr.cloudfront.net/luksa/Figures/13fig03_alt.jpg)

Let’s see how to define the `hostPort` in a pod’s YAML definition. The following listing shows the YAML to run your `kubia` pod and bind it to the node’s port 9000.

##### Listing 13.3. Binding a pod to a port in the node’s port space: kubia-hostport.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kubia-hostport
spec:
  containers:
  - image: luksa/kubia
    name: kubia
    ports:
    - containerPort: 8080
      hostPort: 9000
      protocol: TCP
```

After you create this pod, you can access it through port 9000 of the node it’s scheduled to. If you have multiple nodes, you’ll see you can’t access the pod through that port on the other nodes.

---

##### Note

If you’re trying this on GKE, you need to configure the firewall properly using `gcloud compute firewall-rules`, the way you did in [chapter 5](../Text/05.html#ch05).

---

The `hostPort` feature is primarily used for exposing system services, which are deployed to every node using DaemonSets. Initially, people also used it to ensure two replicas of the same pod were never scheduled to the same node, but now you have a better way of achieving this—it’s explained in [chapter 16](/book/kubernetes-in-action/chapter-16/ch16).

### 13.1.3. Using the node’s PID and IPC namespaces

Similar to the `hostNetwork` option are the `hostPID` and `hostIPC` pod spec properties. When you set them to `true`, the pod’s containers will use the node’s PID and IPC namespaces, allowing processes running in the containers to see all the other processes on the node or communicate with them through IPC, respectively. See the following listing for an example.

##### Listing 13.4. Using the host’s PID and IPC namespaces: pod-with-host-pid-and-ipc.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-host-pid-and-ipc
spec:
  hostPID: true
  hostIPC: true
  containers:
  - name: main
    image: alpine
    command: ["/bin/sleep", "999999"]
```

You’ll remember that pods usually see only their own processes, but if you run this pod and then list the processes from within its container, you’ll see all the processes running on the host node, not only the ones running in the container, as shown in the following listing.

##### Listing 13.5. Processes visible in a pod with `hostPID: true`

```bash
$ kubectl exec pod-with-host-pid-and-ipc ps aux
PID   USER     TIME   COMMAND
    1 root       0:01 /usr/lib/systemd/systemd --switched-root --system ...
    2 root       0:00 [kthreadd]
    3 root       0:00 [ksoftirqd/0]
    5 root       0:00 [kworker/0:0H]
    6 root       0:00 [kworker/u2:0]
    7 root       0:00 [migration/0]
    8 root       0:00 [rcu_bh]
    9 root       0:00 [rcu_sched]
   10 root       0:00 [watchdog/0]
...
```

By setting the `hostIPC` property to `true`, processes in the pod’s containers can also communicate with all the other processes running on the node, through Inter-Process Communication.

## 13.2. Configuring the container’s security context

Besides allowing the pod to use the host’s Linux namespaces, other security-related features can also be configured on the pod and its container through the `security-Context` properties, which can be specified under the pod spec directly and inside the spec of individual containers.

##### Understanding what’s configurable in the security context

Configuring the security context allows you to do various things:

- Specify the user (the user’s ID) under which the process in the container will run.
- Prevent the container from running as root (the default user a container runs as is usually defined in the container image itself, so you may want to prevent containers from running as root).
- Run the container in privileged mode, giving it full access to the node’s kernel.
- Configure fine-grained privileges, by adding or dropping capabilities—in contrast to giving the container all possible permissions by running it in privileged mode.
- Set SELinux (Security Enhanced Linux) options to strongly lock down a container.
- Prevent the process from writing to the container’s filesystem.

We’ll explore these options next.

##### Running a pod without specifying a security context

First, run a pod with the default security context options (by not specifying them at all), so you can see how it behaves compared to pods with a custom security context:

```bash
$ kubectl run pod-with-defaults --image alpine --restart Never
➥   -- /bin/sleep 999999
pod "pod-with-defaults" created
```

Let’s see what user and group ID the container is running as, and which groups it belongs to. You can see this by running the `id` command inside the container:

```bash
$ kubectl exec pod-with-defaults id
uid=0(root) gid=0(root) groups=0(root), 1(bin), 2(daemon), 3(sys), 4(adm), 6(disk), 10(wheel), 11(floppy), 20(dialout), 26(tape), 27(video)
```

The container is running as user ID (`uid`) `0`, which is `root`, and group ID (`gid`) `0` (also `root`). It’s also a member of multiple other groups.

---

##### Note

What user the container runs as is specified in the container image. In a Dockerfile, this is done using the `USER` directive. If omitted, the container runs as root.

---

Now, you’ll run a pod where the container runs as a different user.

### 13.2.1. Running a container as a specific user

To run a pod under a different user ID than the one that’s baked into the container image, you’ll need to set the pod’s `securityContext.runAsUser` property. You’ll make the container run as user `guest`, whose user ID in the alpine container image is `405`, as shown in the following listing.

##### Listing 13.6. Running containers as a specific user: pod-as-user-guest.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-as-user-guest
spec:
  containers:
  - name: main
    image: alpine
    command: ["/bin/sleep", "999999"]
    securityContext:
      runAsUser: 405
```

Now, to see the effect of the `runAsUser` property, run the `id` command in this new pod, the way you did before:

```bash
$ kubectl exec pod-as-user-guest id
uid=405(guest) gid=100(users)
```

As requested, the container is running as the `guest` user.

### 13.2.2. Preventing a container from running as root

What if you don’t care what user the container runs as, but you still want to prevent it from running as root?

Imagine having a pod deployed with a container image that was built with a `USER daemon` directive in the Dockerfile, which makes the container run under the `daemon` user. What if an attacker gets access to your image registry and pushes a different image under the same tag? The attacker’s image is configured to run as the root user. When Kubernetes schedules a new instance of your pod, the Kubelet will download the attacker’s image and run whatever code they put into it.

Although containers are mostly isolated from the host system, running their processes as root is still considered a bad practice. For example, when a host directory is mounted into the container, if the process running in the container is running as root, it has full access to the mounted directory, whereas if it’s running as non-root, it won’t.

To prevent the attack scenario described previously, you can specify that the pod’s container needs to run as a non-root user, as shown in the following listing.

##### Listing 13.7. Preventing containers from running as root: pod-run-as-non-root.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-run-as-non-root
spec:
  containers:
  - name: main
    image: alpine
    command: ["/bin/sleep", "999999"]
    securityContext:
      runAsNonRoot: true
```

If you deploy this pod, it gets scheduled, but is not allowed to run:

```bash
$ kubectl get po pod-run-as-non-root
NAME                 READY  STATUS
pod-run-as-non-root  0/1    container has runAsNonRoot and image will run
                            ➥   as root
```

Now, if anyone tampers with your container images, they won’t get far.

### 13.2.3. Running pods in privileged mode

Sometimes pods need to do everything that the node they’re running on can do, such as use protected system devices or other kernel features, which aren’t accessible to regular containers.

An example of such a pod is the kube-proxy pod, which needs to modify the node’s `iptables` rules to make services work, as was explained in [chapter 11](/book/kubernetes-in-action/chapter-11/ch11). If you follow the instructions in [appendix B](/book/kubernetes-in-action/appendix-b/app02) and deploy a cluster with `kubeadm`, you’ll see every cluster node runs a kube-proxy pod and you can examine its YAML specification to see all the special features it’s using.

To get full access to the node’s kernel, the pod’s container runs in privileged mode. This is achieved by setting the `privileged` property in the container’s `security-Context` property to `true`. You’ll create a privileged pod from the YAML in the following listing.

##### Listing 13.8. A pod with a privileged container: pod-privileged.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-privileged
spec:
  containers:
  - name: main
    image: alpine
    command: ["/bin/sleep", "999999"]
    securityContext:
      privileged: true
```

Go ahead and deploy this pod, so you can compare it with the non-privileged pod you ran earlier.

If you’re familiar with Linux, you may know it has a special file directory called /dev, which contains device files for all the devices on the system. These aren’t regular files on disk, but are special files used to communicate with devices. Let’s see what devices are visible in the non-privileged container you deployed earlier (the `pod-with-defaults` pod), by listing files in its /dev directory, as shown in the following listing.

##### Listing 13.9. List of available devices in a non-privileged pod

```bash
$ kubectl exec -it pod-with-defaults ls /dev
core             null             stderr           urandom
fd               ptmx             stdin            zero
full             pts              stdout
fuse             random           termination-log
mqueue           shm              tty
```

The listing shows all the devices. The list is fairly short. Now, compare this with the following listing, which shows the device files your privileged pod can see.

##### Listing 13.10. List of available devices in a privileged pod

```bash
$ kubectl exec -it pod-privileged ls /dev
autofs              snd                 tty46
bsg                 sr0                 tty47
btrfs-control       stderr              tty48
core                stdin               tty49
cpu                 stdout              tty5
cpu_dma_latency     termination-log     tty50
fd                  tty                 tty51
full                tty0                tty52
fuse                tty1                tty53
hpet                tty10               tty54
hwrng               tty11               tty55
...                 ...                 ...
```

I haven’t included the whole list, because it’s too long for the book, but it’s evident that the device list is much longer than before. In fact, the privileged container sees all the host node’s devices. This means it can use any device freely.

For example, I had to use privileged mode like this when I wanted a pod running on a Raspberry Pi to control LEDs connected it.

### 13.2.4. Adding individual kernel capabilities to a container

In the previous section, you saw one way of giving a container unlimited power. In the old days, traditional UNIX implementations only distinguished between privileged and unprivileged processes, but for many years, Linux has supported a much more fine-grained permission system through kernel *capabilities*.

Instead of making a container privileged and giving it unlimited permissions, a much safer method (from a security perspective) is to give it access only to the kernel features it really requires. Kubernetes allows you to add capabilities to each container or drop part of them, which allows you to fine-tune the container’s permissions and limit the impact of a potential intrusion by an attacker.

For example, a container usually isn’t allowed to change the system time (the hardware clock’s time). You can confirm this by trying to set the time in your `pod-with-defaults` pod:

```bash
$ kubectl exec -it pod-with-defaults -- date +%T -s "12:00:00"
date: can't set date: Operation not permitted
```

If you want to allow the container to change the system time, you can `add` a capability called `CAP_SYS_TIME` to the container’s `capabilities` list, as shown in the following listing.

##### Listing 13.11. Adding the `CAP_SYS_TIME` capability: pod-add-settime-capability.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-add-settime-capability
spec:
  containers:
  - name: main
    image: alpine
    command: ["/bin/sleep", "999999"]
    securityContext:
      capabilities:
        add:
        - SYS_TIME
```

---

##### Note

Linux kernel capabilities are usually prefixed with `CAP_.` But when specifying them in a pod spec, you must leave out the prefix.

---

If you run the same command in this new pod’s container, the system time is changed successfully:

```bash
$ kubectl exec -it pod-add-settime-capability -- date +%T -s "12:00:00"
12:00:00

$ kubectl exec -it pod-add-settime-capability -- date
Sun May  7 12:00:03 UTC 2017
```

---

##### Warning

If you try this yourself, be aware that it may cause your worker node to become unusable. In Minikube, although the system time was automatically reset back by the Network Time Protocol (NTP) daemon, I had to reboot the VM to schedule new pods.

---

You can confirm the node’s time has been changed by checking the time on the node running the pod. In my case, I’m using Minikube, so I have only one node and I can get its time like this:

```bash
$ minikube ssh date
Sun May  7 12:00:07 UTC 2017
```

Adding capabilities like this is a much better way than giving a container full privileges with `privileged: true`. Admittedly, it does require you to know and understand what each capability does.

---

##### Tip

You’ll find the list of Linux kernel capabilities in the Linux man pages.

---

### 13.2.5. Dropping capabilities from a container

You’ve seen how to add capabilities, but you can also drop capabilities that may otherwise be available to the container. For example, the default capabilities given to a container include the `CAP_CHOWN` capability, which allows processes to change the ownership of files in the filesystem.

You can see that’s the case by changing the ownership of the /tmp directory in your `pod-with-defaults` pod to the `guest` user, for example:

```bash
$ kubectl exec pod-with-defaults chown guest /tmp
$ kubectl exec pod-with-defaults -- ls -la / | grep tmp
drwxrwxrwt    2 guest    root             6 May 25 15:18 tmp
```

To prevent the container from doing that, you need to drop the capability by listing it under the container’s `securityContext.capabilities.drop` property, as shown in the following listing.

##### Listing 13.12. Dropping a capability from a container: pod-drop-chown-capability.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-drop-chown-capability
spec:
  containers:
  - name: main
    image: alpine
    command: ["/bin/sleep", "999999"]
    securityContext:
      capabilities:
        drop:
        - CHOWN
```

By dropping the `CHOWN` capability, you’re not allowed to change the owner of the /tmp directory in this pod:

```bash
$ kubectl exec pod-drop-chown-capability chown guest /tmp
chown: /tmp: Operation not permitted
```

You’re almost done exploring the container’s security context options. Let’s look at one more.

### 13.2.6. Preventing processes from writing to the container’s filesystem

You may want to prevent the processes running in the container from writing to the container’s filesystem, and only allow them to write to mounted volumes. You’d want to do that mostly for security reasons.

Let’s imagine you’re running a PHP application with a hidden vulnerability, allowing an attacker to write to the filesystem. The PHP files are added to the container image at build time and are served from the container’s filesystem. Because of the vulnerability, the attacker can modify those files and inject them with malicious code.

These types of attacks can be thwarted by preventing the container from writing to its filesystem, where the app’s executable code is normally stored. This is done by setting the container’s `securityContext.readOnlyRootFilesystem` property to `true`, as shown in the following listing.

##### Listing 13.13. A container with a read-only filesystem: pod-with-readonly-filesystem.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-readonly-filesystem
spec:
  containers:
  - name: main
    image: alpine
    command: ["/bin/sleep", "999999"]
    securityContext:
      readOnlyRootFilesystem: true
    volumeMounts:
    - name: my-volume
      mountPath: /volume
      readOnly: false
  volumes:
  - name: my-volume
    emptyDir:
```

When you deploy this pod, the container is running as root, which has write permissions to the `/` directory, but trying to write a file there fails:

```bash
$ kubectl exec -it pod-with-readonly-filesystem touch /new-file
touch: /new-file: Read-only file system
```

On the other hand, writing to the mounted volume is allowed:

```bash
$ kubectl exec -it pod-with-readonly-filesystem touch /volume/newfile
$ kubectl exec -it pod-with-readonly-filesystem -- ls -la /volume/newfile
-rw-r--r--    1 root     root       0 May  7 19:11 /mountedVolume/newfile
```

As shown in the example, when you make the container’s filesystem read-only, you’ll probably want to mount a volume in every directory the application writes to (for example, logs, on-disk caches, and so on).

---

##### Tip

To increase security, when running pods in production, set their container’s `readOnlyRootFilesystem` property to `true`.

---

##### Setting security context options at the pod level

In all these examples, you’ve set the security context of an individual container. Several of these options can also be set at the pod level (through the `pod.spec.security-Context` property). They serve as a default for all the pod’s containers but can be overridden at the container level. The pod-level security context also allows you to set additional properties, which we’ll explain next.

### 13.2.7. Sharing volumes when containers run as different users

In [chapter 6](/book/kubernetes-in-action/chapter-6/ch06), we explained how volumes are used to share data between the pod’s containers. You had no trouble writing files in one container and reading them in the other.

But this was only because both containers were running as root, giving them full access to all the files in the volume. Now imagine using the `runAsUser` option we explained earlier. You may need to run the two containers as two different users (perhaps you’re using two third-party container images, where each one runs its process under its own specific user). If those two containers use a volume to share files, they may not necessarily be able to read or write files of one another.

That’s why Kubernetes allows you to specify supplemental groups for all the pods running in the container, allowing them to share files, regardless of the user IDs they’re running as. This is done using the following two properties:

- `fsGroup`
- `supplementalGroups`

What they do is best explained in an example, so let’s see how to use them in a pod and then see what their effect is. The next listing describes a pod with two containers sharing the same volume.

##### Listing 13.14. `fsGroup` & `supplementalGroups`: pod-with-shared-volume-fsgroup.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-shared-volume-fsgroup
spec:
  securityContext:
    fsGroup: 555
    supplementalGroups: [666, 777]
  containers:
  - name: first
    image: alpine
    command: ["/bin/sleep", "999999"]
    securityContext:
      runAsUser: 1111
    volumeMounts:
    - name: shared-volume
      mountPath: /volume
      readOnly: false
  - name: second
    image: alpine
    command: ["/bin/sleep", "999999"]
    securityContext:
      runAsUser: 2222
    volumeMounts:
    - name: shared-volume
      mountPath: /volume
      readOnly: false
  volumes:
  - name: shared-volume
    emptyDir:
```

After you create this pod, run a shell in its first container and see what user and group IDs the container is running as:

```bash
$ kubectl exec -it pod-with-shared-volume-fsgroup -c first sh
/ $ id
uid=1111 gid=0(root) groups=555,666,777
```

The `id` command shows the container is running with user ID `1111`, as specified in the pod definition. The effective group ID is `0(root)`, but group IDs `555`, `666`, and `777` are also associated with the user.

In the pod definition, you set `fsGroup` to `555`. Because of this, the mounted volume will be owned by group ID `555`, as shown here:

```
/ $ ls -l / | grep volume
drwxrwsrwx    2 root     555              6 May 29 12:23 volume
```

If you create a file in the mounted volume’s directory, the file is owned by user ID `1111` (that’s the user ID the container is running as) and by group ID `555`:

```
/ $ echo foo > /volume/foo
/ $ ls -l /volume
total 4
-rw-r--r--    1 1111     555              4 May 29 12:25 foo
```

This is different from how ownership is otherwise set up for newly created files. Usually, the user’s effective group ID, which is `0` in your case, is used when a user creates files. You can see this by creating a file in the container’s filesystem instead of in the volume:

```
/ $ echo foo > /tmp/foo
/ $ ls -l /tmp
total 4
-rw-r--r--    1 1111     root             4 May 29 12:41 foo
```

As you can see, the `fsGroup` security context property is used when the process creates files in a volume (but this depends on the volume plugin used), whereas the `supplementalGroups` property defines a list of additional group IDs the user is associated with.

This concludes this section about the configuration of the container’s security context. Next, we’ll see how a cluster administrator can restrict users from doing so.

## 13.3. Restricting the use of security-related features in pods

The examples in the previous sections have shown how a person deploying pods can do whatever they want on any cluster node, by deploying a privileged pod to the node, for example. Obviously, a mechanism must prevent users from doing part or all of what’s been explained. The cluster admin can restrict the use of the previously described security-related features by creating one or more PodSecurityPolicy resources.

### 13.3.1. Introducing the PodSecurityPolicy resource

PodSecurityPolicy is a cluster-level (non-namespaced) resource, which defines what security-related features users can or can’t use in their pods. The job of upholding the policies configured in PodSecurityPolicy resources is performed by the PodSecurity-Policy admission control plugin running in the API server (we explained admission control plugins in [chapter 11](/book/kubernetes-in-action/chapter-11/ch11)).

---

##### Note

The PodSecurityPolicy admission control plugin may not be enabled in your cluster. Before running the following examples, ensure it’s enabled. If you’re using Minikube, refer to the next sidebar.

---

When someone posts a pod resource to the API server, the PodSecurityPolicy admission control plugin validates the pod definition against the configured PodSecurityPolicies. If the pod conforms to the cluster’s policies, it’s accepted and stored into etcd; otherwise it’s rejected immediately. The plugin may also modify the pod resource according to defaults configured in the policy.

---

##### **Enabling RBAC and PodSecurityPolicy admission control in Minikube**

I’m using Minikube version v0.19.0 to run these examples. That version doesn’t enable either the PodSecurityPolicy admission control plugin or RBAC authorization, which is required in part of the exercises. One exercise also requires authenticating as a different user, so you’ll also need to enable the basic authentication plugin where users are defined in a file.

To run Minikube with all these plugins enabled, you may need to use this (or a similar) command, depending on the version you’re using:

```bash
$ minikube start --extra-config apiserver.Authentication.PasswordFile.
➥  BasicAuthFile=/etc/kubernetes/passwd --extra-config=apiserver.
➥  Authorization.Mode=RBAC --extra-config=apiserver.GenericServerRun
➥  Options.AdmissionControl=NamespaceLifecycle,LimitRanger,Service
➥  Account,PersistentVolumeLabel,DefaultStorageClass,ResourceQuota,
➥  DefaultTolerationSeconds,PodSecurityPolicy
```

The API server won’t start up until you create the password file you specified in the command line options. This is how to create the file:

```bash
$ cat <<EOF | minikube ssh sudo tee /etc/kubernetes/passwd
password,alice,1000,basic-user
password,bob,2000,privileged-user
EOF
```

You’ll find a shell script that runs both commands in the book’s code archive in Chapter13/minikube-with-rbac-and-psp-enabled.sh.

---

##### Understanding what a PodSecurityPolicy can do

A PodSecurityPolicy resource defines things like the following:

- Whether a pod can use the host’s IPC, PID, or Network namespaces
- Which host ports a pod can bind to
- What user IDs a container can run as
- Whether a pod with privileged containers can be created
- Which kernel capabilities are allowed, which are added by default and which are always dropped
- What SELinux labels a container can use
- Whether a container can use a writable root filesystem or not
- Which filesystem groups the container can run as
- Which volume types a pod can use

If you’ve read this chapter up to this point, everything but the last item in the previous list should be familiar. The last item should also be fairly clear.

##### Examining a sample PodSecurityPolicy

The following listing shows a sample PodSecurityPolicy, which prevents pods from using the host’s IPC, PID, and Network namespaces, and prevents running privileged containers and the use of most host ports (except ports from 10000-11000 and 13000-14000). The policy doesn’t set any constraints on what users, groups, or SELinux groups the container can run as.

##### Listing 13.15. An example PodSecurityPolicy: pod-security-policy.yaml

```yaml
apiVersion: extensions/v1beta1
kind: PodSecurityPolicy
metadata:
  name: default
spec:
  hostIPC: false
  hostPID: false
  hostNetwork: false
  hostPorts:
  - min: 10000
    max: 11000
  - min: 13000
    max: 14000
  privileged: false
  readOnlyRootFilesystem: true
  runAsUser:

    rule: RunAsAny

  fsGroup:

    rule: RunAsAny

  supplementalGroups:

    rule: RunAsAny

  seLinux:

    rule: RunAsAny

  volumes:

  - '*'
```

Most of the options specified in the example should be self-explanatory, especially if you’ve read the previous sections. After this PodSecurityPolicy resource is posted to the cluster, the API server will no longer allow you to deploy the privileged pod used earlier. For example

```bash
$ kubectl create -f pod-privileged.yaml
Error from server (Forbidden): error when creating "pod-privileged.yaml":
pods "pod-privileged" is forbidden: unable to validate against any pod
security policy: [spec.containers[0].securityContext.privileged: Invalid
value: true: Privileged containers are not allowed]
```

Likewise, you can no longer deploy pods that want to use the host’s PID, IPC, or Network namespace. Also, because you set `readOnlyRootFilesystem` to `true` in the policy, the container filesystems in all pods will be read-only (containers can only write to volumes).

### 13.3.2. Understanding runAsUser, fsGroup, and supplementalGroups policies

The policy in the previous example doesn’t impose any limits on which users and groups containers can run as, because you’ve used the `RunAsAny` rule for the `run-As-User`, `fsGroup`, and `supplementalGroups` fields. If you want to constrain the list of allowed user or group IDs, you change the rule to `MustRunAs` and specify the range of allowed IDs.

##### Using the MustRunAs rule

Let’s look at an example. To only allow containers to run as user ID `2` and constrain the default filesystem group and supplemental group IDs to be anything from `2–10` or `20–30` (all inclusive), you’d include the following snippet in the PodSecurityPolicy resource.

##### Listing 13.16. Specifying IDs containers must run as: psp-must-run-as.yaml

```
runAsUser:
    rule: MustRunAs
    ranges:
    - min: 2                #1
      max: 2                #1
  fsGroup:
    rule: MustRunAs
    ranges:
    - min: 2                #2
      max: 10               #2
    - min: 20               #2
      max: 30               #2
  supplementalGroups:
    rule: MustRunAs
    ranges:
    - min: 2                #2
      max: 10               #2
    - min: 20               #2
      max: 30               #2
```

If the pod spec tries to set either of those fields to a value outside of these ranges, the pod will not be accepted by the API server. To try this, delete the previous PodSecurity-Policy and create the new one from the psp-must-run-as.yaml file.

---

##### Note

Changing the policy has no effect on existing pods, because Pod-Security-Policies are enforced only when creating or updating pods.

---

##### Deploying a pod with runAsUser outside of the policy’s range

If you try deploying the pod-as-user-guest.yaml file from earlier, which says the container should run as user ID `405`, the API server rejects the pod:

```bash
$ kubectl create -f pod-as-user-guest.yaml
Error from server (Forbidden): error when creating "pod-as-user-guest.yaml"
: pods "pod-as-user-guest" is forbidden: unable to validate against any pod
security policy: [securityContext.runAsUser: Invalid value: 405: UID on
container main does not match required range.  Found 405, allowed: [{2 2}]]
```

Okay, that was obvious. But what happens if you deploy a pod without setting the `runAs-User` property, but the user ID is baked into the container image (using the `USER` directive in the Dockerfile)?

##### Deploying a pod with a container image with an out-of-range user id

I’ve created an alternative image for the Node.js app you’ve used throughout the book. The image is configured so that the container will run as user ID 5. The Dockerfile for the image is shown in the following listing.

##### Listing 13.17. Dockerfile with a USER directive: kubia-run-as-user-5/Dockerfile

```dockerfile
FROM node:7
ADD app.js /app.js
USER 5                                #1
ENTRYPOINT ["node", "app.js"]
```

I pushed the image to Docker Hub as `luksa/kubia-run-as-user-5`. If I deploy a pod with that image, the API server doesn’t reject it:

```bash
$ kubectl run run-as-5 --image luksa/kubia-run-as-user-5 --restart Never
pod "run-as-5" created
```

Unlike before, the API server accepted the pod and the Kubelet has run its container. Let’s see what user ID the container is running as:

```bash
$ kubectl exec run-as-5 -- id
uid=2(bin) gid=2(bin) groups=2(bin)
```

As you can see, the container is running as user ID `2`, which is the ID you specified in the PodSecurityPolicy. The PodSecurityPolicy can be used to override the user ID hardcoded into a container image.

##### Using the MustRunAsNonRoot rule in the runAsUser field

For the `runAsUser` field an additional rule can be used: `MustRunAsNonRoot`. As the name suggests, it prevents users from deploying containers that run as root. Either the container spec must specify a `runAsUser` field, which can’t be zero (zero is the root user’s ID), or the container image itself must run as a non-zero user ID. We explained why this is a good thing earlier.

### 13.3.3. Configuring allowed, default, and disallowed capabilities

As you learned, containers can run in privileged mode or not, and you can define a more fine-grained permission configuration by adding or dropping Linux kernel capabilities in each container. Three fields influence which capabilities containers can or cannot use:

- `allowedCapabilities`
- `defaultAddCapabilities`
- `requiredDropCapabilities`

We’ll look at an example first, and then discuss what each of the three fields does. The following listing shows a snippet of a PodSecurityPolicy resource defining three fields related to capabilities.

##### Listing 13.18. Specifying capabilities in a PodSecurityPolicy: psp-capabilities.yaml

```yaml
apiVersion: extensions/v1beta1
kind: PodSecurityPolicy
spec:
  allowedCapabilities:
  - SYS_TIME
  defaultAddCapabilities:
  - CHOWN
  requiredDropCapabilities:
  - SYS_ADMIN
  - SYS_MODULE
  ...
```

---

##### Note

The `SYS_ADMIN` capability allows a range of administrative operations, and the `SYS_MODULE` capability allows loading and unloading of Linux kernel modules.

---

##### Specifying which capabilities can be added to a container

The `allowedCapabilities` field is used to specify which capabilities pod authors can add in the `securityContext.capabilities` field in the container spec. In one of the previous examples, you added the `SYS_TIME` capability to your container. If the Pod-Security-Policy admission control plugin had been enabled, you wouldn’t have been able to add that capability, unless it was specified in the PodSecurityPolicy as shown in [listing 13.18](/book/kubernetes-in-action/chapter-13/ch13ex18).

##### Adding capabilities to all containers

All capabilities listed under the `defaultAddCapabilities` field will be added to every deployed pod’s containers. If a user doesn’t want certain containers to have those capabilities, they need to explicitly drop them in the specs of those containers.

The example in [listing 13.18](/book/kubernetes-in-action/chapter-13/ch13ex18) enables the automatic addition of the `CAP_CHOWN` capability to every container, thus allowing processes running in the container to change the ownership of files in the container (with the `chown` command, for example).

##### Dropping capabilities from a container

The final field in this example is `requiredDropCapabilities`. I must admit, this was a somewhat strange name for me at first, but it’s not that complicated. The capabilities listed in this field are dropped automatically from every container (the PodSecurityPolicy Admission Control plugin will add them to every container’s `security-Context.capabilities.drop` field).

If a user tries to create a pod where they explicitly add one of the capabilities listed in the policy’s `requiredDropCapabilities` field, the pod is rejected:

```bash
$ kubectl create -f pod-add-sysadmin-capability.yaml
Error from server (Forbidden): error when creating "pod-add-sysadmin-
capability.yaml": pods "pod-add-sysadmin-capability" is forbidden: unable
to validate against any pod security policy: [capabilities.add: Invalid
value: "SYS_ADMIN": capability may not be added]
```

### 13.3.4. Constraining the types of volumes pods can use

The last thing a PodSecurityPolicy resource can do is define which volume types users can add to their pods. At the minimum, a PodSecurityPolicy should allow using at least the `emptyDir`, `configMap`, `secret`, `downwardAPI`, and the `persistentVolumeClaim` volumes. The pertinent part of such a PodSecurityPolicy resource is shown in the following listing.

##### Listing 13.19. A PSP snippet allowing the use of only certain volume types: psp-volumes.yaml

```yaml
kind: PodSecurityPolicy
spec:
  volumes:
  - emptyDir
  - configMap
  - secret
  - downwardAPI
  - persistentVolumeClaim
```

If multiple PodSecurityPolicy resources are in place, pods can use any volume type defined in any of the policies (the union of all `volumes` lists is used).

### 13.3.5. Assigning different PodSecurityPolicies to different users and groups

We mentioned that a PodSecurityPolicy is a cluster-level resource, which means it can’t be stored in and applied to a specific namespace. Does that mean it always applies across all namespaces? No, because that would make them relatively unusable. After all, system pods must often be allowed to do things that regular pods shouldn’t.

Assigning different policies to different users is done through the RBAC mechanism described in the previous chapter. The idea is to create as many policies as you need and make them available to individual users or groups by creating ClusterRole resources and pointing them to the individual policies by name. By binding those ClusterRoles to specific users or groups with ClusterRoleBindings, when the PodSecurityPolicy Admission Control plugin needs to decide whether to admit a pod definition or not, it will only consider the policies accessible to the user creating the pod.

You’ll see how to do this in the next exercise. You’ll start by creating an additional PodSecurityPolicy.

##### Creating a PodSecurityPolicy allowing privileged containers to be deployed

You’ll create a special PodSecurityPolicy that will allow privileged users to create pods with privileged containers. The following listing shows the policy’s definition.

##### Listing 13.20. A PodSecurityPolicy for privileged users: psp-privileged.yaml

```yaml
apiVersion: extensions/v1beta1
kind: PodSecurityPolicy
metadata:
  name: privileged
spec:
  privileged: true
  runAsUser:
    rule: RunAsAny
  fsGroup:
    rule: RunAsAny
  supplementalGroups:
    rule: RunAsAny
  seLinux:
    rule: RunAsAny
  volumes:
  - '*'
```

After you post this policy to the API server, you have two policies in the cluster:

```bash
$ kubectl get psp
NAME         PRIV    CAPS   SELINUX    RUNASUSER   FSGROUP    ...
default      false   []     RunAsAny   RunAsAny    RunAsAny   ...
privileged   true    []     RunAsAny   RunAsAny    RunAsAny   ...
```

---

##### Note

The shorthand for `PodSecurityPolicy` is `psp`.

---

As you can see in the `PRIV` column, the `default` policy doesn’t allow running privileged containers, whereas the `privileged` policy does. Because you’re currently logged in as a cluster-admin, you can see all the policies. When creating pods, if any policy allows you to deploy a pod with certain features, the API server will accept your pod.

Now imagine two additional users are using your cluster: Alice and Bob. You want Alice to only deploy restricted (non-privileged) pods, but you want to allow Bob to also deploy privileged pod`s`. You do this by making sure Alice can only use the default PodSecurityPolicy, while allowing Bob to use both.

##### Using RBAC to assign different PodSecurityPolicies to different users

In the previous chapter, you used RBAC to grant users access to only certain resource types, but I mentioned that access can be granted to specific resource instances by referencing them by name. That’s what you’ll use to make users use different PodSecurityPolicy resources.

First, you’ll create two ClusterRoles, each allowing the use of one of the policies. You’ll call the first one `psp-default` and in it allow the `use` of the `default` PodSecurityPolicy resource. You can use `kubectl create clusterrole` to do that:

```bash
$ kubectl create clusterrole psp-default --verb=use
➥   --resource=podsecuritypolicies --resource-name=default
clusterrole "psp-default" created
```

---

##### Note

You’re using the special verb `use` instead of `get`, `list`, `watch`, or similar.

---

As you can see, you’re referring to a specific instance of a PodSecurityPolicy resource by using the `--resource-name` option. Now, create another ClusterRole called `psp-privileged`, pointing to the `privileged` policy:

```bash
$ kubectl create clusterrole psp-privileged --verb=use
➥   --resource=podsecuritypolicies --resource-name=privileged
clusterrole "psp-privileged" created
```

Now, you need to bind these two policies to users. As you may remember from the previous chapter, if you’re binding a ClusterRole that grants access to cluster-level resources (which is what PodSecurityPolicy resources are), you need to use a Cluster-RoleBinding instead of a (namespaced) RoleBinding.

You’re going to bind the `psp-default` ClusterRole to all authenticated users, not only to Alice. This is necessary because otherwise no one could create any pods, because the Admission Control plugin would complain that no policy is in place. Authenticated users all belong to the `system:authenticated` group, so you’ll bind the ClusterRole to the group:

```bash
$ kubectl create clusterrolebinding psp-all-users
➥  --clusterrole=psp-default --group=system:authenticated
clusterrolebinding "psp-all-users" created
```

You’ll bind the `psp-privileged` ClusterRole only to Bob:

```bash
$ kubectl create clusterrolebinding psp-bob
➥  --clusterrole=psp-privileged --user=bob
clusterrolebinding "psp-bob" created
```

As an authenticated user, Alice should now have access to the `default` PodSecurityPolicy, whereas Bob should have access to both the `default` and the `privileged` PodSecurityPolicies. Alice shouldn’t be able to create privileged pods, whereas Bob should. Let’s see if that’s true.

##### Creating additional users for kubectl

But how do you authenticate as Alice or Bob instead of whatever you’re authenticated as currently? The book’s [appendix A](/book/kubernetes-in-action/appendix-a/app01) explains how `kubectl` can be used with multiple clusters, but also with multiple contexts. A context includes the user credentials used for talking to a cluster. Turn to [appendix A](/book/kubernetes-in-action/appendix-a/app01) to find out more. Here we’ll show the bare commands enabling you to use `kubectl` as Alice or Bob.

First, you’ll create two new users in `kubectl`’s config with the following two commands-:

```bash
$ kubectl config set-credentials alice --username=alice --password=password
User "alice" set.
$ kubectl config set-credentials bob --username=bob --password=password
User "bob" set.
```

It should be obvious what the commands do. Because you’re setting username and password credentials, `kubectl` will use basic HTTP authentication for these two users (other authentication methods include tokens, client certificates, and so on).

##### Creating pods as a different user

You can now try creating a privileged pod while authenticating as Alice. You can tell `kubectl` which user credentials to use by using the `--user` option:

```bash
$ kubectl --user alice create -f pod-privileged.yaml
Error from server (Forbidden): error when creating "pod-privileged.yaml":
     pods "pod-privileged" is forbidden: unable to validate against any pod
     security policy: [spec.containers[0].securityContext.privileged: Invalid
     value: true: Privileged containers are not allowed]
```

As expected, the API server doesn’t allow Alice to create privileged pods. Now, let’s see if it allows Bob to do that:

```bash
$ kubectl --user bob create -f pod-privileged.yaml
pod "pod-privileged" created
```

And there you go. You’ve successfully used RBAC to make the Admission Control plugin use different PodSecurityPolicy resources for different users.

## 13.4. Isolating the pod network

Up to now in this chapter, we’ve explored many security-related configuration options that apply to individual pods and their containers. In the remainder of this chapter, we’ll look at how the network between pods can be secured by limiting which pods can talk to which pods.

Whether this is configurable or not depends on which container networking plugin is used in the cluster. If the networking plugin supports it, you can configure network isolation by creating NetworkPolicy resources.

A NetworkPolicy applies to pods that match its label selector and specifies either which sources can access the matched pods or which destinations can be accessed from the matched pods. This is configured through ingress and egress rules, respectively. Both types of rules can match only the pods that match a pod selector, all pods in a namespace whose labels match a namespace selector, or a network IP block specified using Classless Inter-Domain Routing (CIDR) notation (for example, 192.168.1.0/24).

We’ll look at both ingress and egress rules and all three matching options.

---

##### Note

Ingress rules in a NetworkPolicy have nothing to do with the Ingress resource discussed in [chapter 5](../Text/05.html#ch05).

---

### 13.4.1. Enabling network isolation in a namespace

By default, pods in a given namespace can be accessed by anyone. First, you’ll need to change that. You’ll create a `default-deny` NetworkPolicy, which will prevent all clients from connecting to any pod in your namespace. The NetworkPolicy definition is shown in the following listing.

##### Listing 13.21. A `default-deny` NetworkPolicy: network-policy-default-deny.yaml

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
spec:
  podSelector:
```

When you create this NetworkPolicy in a certain namespace, no one can connect to any pod in that namespace.

---

##### Note

The CNI plugin or other type of networking solution used in the cluster must support NetworkPolicy, or else there will be no effect on inter-pod connectivity.

---

### 13.4.2. Allowing only some pods in the namespace to connect to a server pod

To let clients connect to the pods in the namespace, you must now explicitly say who can connect to the pods. By who I mean which pods. Let’s explore how to do this through an example.

Imagine having a PostgreSQL database pod running in namespace `foo` and a web-server pod that uses the database. Other pods are also in the namespace, and you don’t want to allow them to connect to the database. To secure the network, you need to create the NetworkPolicy resource shown in the following listing in the same namespace as the database pod.

##### Listing 13.22. A NetworkPolicy for the Postgres pod: network-policy-postgres.yaml

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: postgres-netpolicy
spec:
  podSelector:
    matchLabels:
      app: database
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: webserver
    ports:
    - port: 5432
```

The example NetworkPolicy allows pods with the `app=webserver` label to connect to pods with the `app=database` label, and only on port 5432. Other pods can’t connect to the database pods, and no one (not even the webserver pods) can connect to anything other than port 5432 of the database pods. This is shown in [figure 13.4](/book/kubernetes-in-action/chapter-13/ch13fig04).

![Figure 13.4. A NetworkPolicy allowing only some pods to access other pods and only on a specific port](https://drek4537l1klr.cloudfront.net/luksa/Figures/13fig04_alt.jpg)

Client pods usually connect to server pods through a Service instead of directly to the pod, but that doesn’t change anything. The NetworkPolicy is enforced when connecting through a Service, as well.

### 13.4.3. Isolating the network between Kubernetes namespaces

Now let’s look at another example, where multiple tenants are using the same Kubernetes cluster. Each tenant can use multiple namespaces, and each namespace has a label specifying the tenant it belongs to. For example, one of those tenants is Manning. All their namespaces have been labeled with `tenant: manning`. In one of their namespaces, they run a Shopping Cart microservice that needs to be available to all pods running in any of their namespaces. Obviously, they don’t want any other tenants to access their microservice.

To secure their microservice, they create the NetworkPolicy resource shown in the following listing.

##### Listing 13.23. NetworkPolicy for the shopping cart pod(s): network-policy-cart.yaml

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: shoppingcart-netpolicy
spec:
  podSelector:
    matchLabels:
      app: shopping-cart
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          tenant: manning
    ports:
    - port: 80
```

This NetworkPolicy ensures only pods running in namespaces labeled as `tenant: manning` can access their Shopping Cart microservice, as shown in [figure 13.5](/book/kubernetes-in-action/chapter-13/ch13fig05).

![Figure 13.5. A NetworkPolicy only allowing pods in namespaces matching a namespaceSelector to access a specific pod.](https://drek4537l1klr.cloudfront.net/luksa/Figures/13fig05_alt.jpg)

If the shopping cart provider also wants to give access to other tenants (perhaps to one of their partner companies), they can either create an additional NetworkPolicy resource or add an additional ingress rule to their existing NetworkPolicy.

---

##### Note

In a multi-tenant Kubernetes cluster, tenants usually can’t add labels (or annotations) to their namespaces themselves. If they could, they’d be able to circumvent the `namespaceSelector`-based ingress rules.

---

### 13.4.4. Isolating using CIDR notation

Instead of specifying a pod- or namespace selector to define who can access the pods targeted in the NetworkPolicy, you can also specify an IP block in CIDR notation. For example, to allow the `shopping-cart` pods from the previous section to only be accessible from IPs in the 192.168.1.1 to .255 range, you’d specify the ingress rule in the next listing.

##### Listing 13.24. Specifying an IP block in an ingress rule: network-policy-cidr.yaml

```
ingress:
  - from:
    - ipBlock:                    #1
        cidr: 192.168.1.0/24      #1
```

### 13.4.5. Limiting the outbound traffic of a set of pods

In all previous examples, you’ve been limiting the inbound traffic to the pods that match the NetworkPolicy’s pod selector using ingress rules, but you can also limit their outbound traffic through egress rules. An example is shown in the next listing.

##### Listing 13.25. Using egress rules in a NetworkPolicy: network-policy-egress.yaml

```
spec:
  podSelector:                #1
    matchLabels:              #1
      app: webserver          #1
  egress:                     #2
  - to:                       #3
    - podSelector:            #3
        matchLabels:          #3
          app: database       #3
```

The NetworkPolicy in the previous listing allows pods that have the `app=webserver` label to only access pods that have the `app=database` label and nothing else (neither other pods, nor any other IP, regardless of whether it’s internal or external to the cluster).

## 13.5. Summary

In this chapter, you learned about securing cluster nodes from pods and pods from other pods. You learned that

- Pods can use the node’s Linux namespaces instead of using their own.
- Containers can be configured to run as a different user and/or group than the one defined in the container image.
- Containers can also run in privileged mode, allowing them to access the node’s devices that are otherwise not exposed to pods.
- Containers can be run as read-only, preventing processes from writing to the container’s filesystem (and only allowing them to write to mounted volumes).
- Cluster-level PodSecurityPolicy resources can be created to prevent users from creating pods that could compromise a node.
- PodSecurityPolicy resources can be associated with specific users using RBAC’s ClusterRoles and ClusterRoleBindings.
- NetworkPolicy resources are used to limit a pod’s inbound and/or outbound traffic.

In the next chapter, you’ll learn how computational resources available to pods can be constrained and how a pod’s quality of service is configured.
