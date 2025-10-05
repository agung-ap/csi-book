# Chapter 3. Container Networking Basics

Now that we’ve discussed networking basics and Linux networking, we’ll discuss how networking is implemented in
containers. Like networking, containers have a long history. This chapter will review the history,
discuss various options for running containers, and explore the networking setup available. The industry, for now, has settled on Docker as the container runtime standard. Thus, we’ll dive into the Docker networking
model, explain how the CNI differs from the Docker network model, and end the chapter with
examples of networking modes with Docker containers.

# Introduction to Containers

In this section, we will discuss the evolution of running applications that has led us to containers. Some,
rightfully, will talk about containers as not being real. They are yet another abstraction of the underlying technology
in the OS kernel. Being technically right misses the point of the technology and leads us nowhere down the road of solving the hard problem that is application management and deployment.

## Applications

Running applications has always had its challenges. There are many ways to serve applications nowadays: in the cloud,
on-prem, and, of course, with containers. Application developers and system administrators face many issues, such as dealing with different versions of libraries, knowing how to complete deployments, and having old versions of the application itself. For the longest time, developers of applications had to deal with
these issues. Bash scripts and deployment tools all have their drawbacks and issues. Every new company has its way of
deploying applications, so every new developer has to learn these techniques. Separation of duties, permissions controls,
and maintaining system stability require system administrators to limit access to developers for deployments.
Sysadmins also manage multiple applications on the same host machine to drive up that machine’s
efficiency, thus creating contention between developers wanting to deploy new features and system administrators
wanting to maintain the whole ecosystem’s stability.

A general-purpose OS supports as many types of applications as possible, so its kernel includes all
kinds of drivers, protocol libraries, and schedulers. [Figure 3-1](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch03.html#img-begining) shows one machine, with one operating system, but there
are many ways to deploy an application to that host. Application deployment is a problem all organizations must solve.

![neku 0301](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0301.png)

###### Figure 3-1. Application server

From a networking perspective, with one operating system, there is one TCP/IP stack. That single stack creates issues
with port conflicts on the host machine. System administrators host multiple applications on the same machine to
increase the machine’s utilization, and each application will have to run on its port. So now, the system
administrators, the application developers, and the network engineers have to coordinate all of this together. More tasks to add to the deployment checklist are creating troubleshooting guides and dealing with all the IT requests.  Hypervisors are a
way to increase one host machine’s efficiency and remove the one operating system/networking
stack issues.

## Hypervisor

A hypervisor emulates hardware resources, CPU, and memory from a host machine to create guest operating systems or
virtual machines. In 2001, VMware released its x86 hypervisor; earlier versions included IBM’s z/Architecture and
FreeBSD jails. The year 2003 saw the release of Xen, the first open source hypervisor, and in 2006 Kernel-based Virtual
Machine (KVM) was released. A hypervisor allows system administrators to share the underlying hardware with multiple
guest operating systems; [Figure 3-2](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch03.html#img-hypervisor) demonstrates this. This resource sharing increases the host machine’s efficiency,
alleviating one of the sysadmins issues.

Hypervisors also gave each application development team a separate networking stack, removing the port conflict
issues on shared systems. For example, team A’s Tomcat application can run on port 8080, while team B’s can also run on port
8080 since each application can now have its guest operating system with a separate network stack. Library
versions, deployment, and other issues remain for the application developer. How can they package and
deploy everything their application needs while maintaining the efficiency introduced by the hypervisor and virtual
machines? This concern led to the development of containers.

![neku 0302](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0302.png)

###### Figure 3-2. Hypervisor

## Containers

In [Figure 3-3](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch03.html#img-containers), we see the benefits of the containerization of applications; each container is independent.
Application developers can use whatever they need to run their application without relying on underlying libraries or host
operating systems. Each container also has its own network stack. The container allows developers to package and
deploy applications while maintaining efficiencies for the host machine.

![neku 0303](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0303.png)

###### Figure 3-3. Containers running on host OS

With any technology comes a history of changes, competitors, and innovations, and containers are no different.
The following is a list of terms that can be confusing when learning about containers. First,
we list the distinction between container runtimes, discuss each runtime’s functionality, and show
how they relate to Kubernetes.  The functionality of container runtimes breaks down to “high level” and
“low level”:

ContainerA running container image.

ImageA container image is the file that  is pulled down from a registry server and used locally as a mount point when
starting a container.

Container engineA container engine accepts user requests via command-line options to pull images and run a container.

Container runtimeThe container runtime is the low-level piece of software in a container engine that deals with
running a container.

Base imageA starting point for container images; to reduce build image sizes and complexity, users can start with a
base image and make incremental changes on top of it.

Image layerRepositories are often referred to as images or container images, but actually they are made up of one
or more layers. Image layers in a repository are connected in a parent-child relationship. Each image layer
represents changes between itself and the parent layer.

Image formatContainer engines have their own container image format, such as LXD, RKT, and Docker.

RegistryA registry stores container images and allows for users to upload, download, and update container images.

RepositoryRepositories can be equivalent to a container image. The important distinction is that repositories
are made up of layers and  metadata about the image; this is the manifest.

TagA tag is a user-defined name for different versions of a container image.

Container hostThe container host is the system that runs the container with a container engine.

Container orchestrationThis is what Kubernetes does! It dynamically schedules container workloads for a cluster of
container hosts.

###### Note

Cgroups and namespaces are Linux primitives to create containers; they are discussed in the next section.

An example of “low-level” functionality is creating cgroups and namespaces for containers, the bare minimum to run one.
Developers require more than that when working with containers. They need to build and
test containers and deploy them; these are considered a “high-level” functionality. Each container runtime
offers various levels of functionality. The following is a list of high and low functionality:

Low-level container runtime functionality-

Creating containers

-

Running containers

High-level container runtime functionality-

Formatting container images

-

Building container images

-

Managing container images

-

Managing instances of containers

-

Sharing container images

Over the next few pages, we will discuss runtimes that implement the previous functionality. Each of the following projects has its
strengths and weaknesses to provide high- and low-level functionality. Some are good to know about for historical
reasons but no longer exist or have merged with other projects:

Low-level container runtimesLXCC API for creating Linux containers

runCCLI for OCI-compliant containers

High-level container runtimescontainerdContainer runtime split off from Docker, a graduated CNCF project

CRI-OContainer runtime interface using the Open Container Initiative (OCI) specification, an incubating CNCF
project

DockerOpen source container platform

lmctfyGoogle containerization platform

rktCoreOS container specification

### OCI

OCI promotes common, minimal, open standards, and specifications for container technology.

The idea for creating a formal specification for container image formats and runtimes allows a
container to be portable across all major operating systems and platforms to ensure no undue technical
barriers. The three values guiding the OCI project are as follows:

ComposableTools for managing containers should have clean interfaces. They should also not be bound to specific
projects, clients, or frameworks and should work across all platforms.

DecentralizedThe format and runtime should be well specified and developed by the community, not one organization. Another goal of the OCI project is independent implementations of tools to run the same container.

MinimalistThe OCI spec strives to do several things well, be minimal and stable, and enable innovation and
experimentation.

Docker donated a draft for the base format and runtime. It also donated code for a reference implementation to the OCI. Docker took the contents of the libcontainer project, made it run independently of Docker, and donated it to the OCI project. That codebase is runC, which can be found on [GitHub](https://oreil.ly/A49v0).

Let’s discuss several early container initiatives and their capabilities. This section will end with where Kubernetes
is with container runtimes and how they work together.

### LXC

Linux Containers, LXC, was created in 2008. LXC combines cgroups and namespaces to provide an isolated environment for
running applications. LXC’s goal is to create an environment as close as possible to a standard Linux without the
need for a separate kernel. LXC has separate components: the `liblxc` library, several programming language bindings,
Python versions 2 and 3, Lua, Go, Ruby, Haskell, a set of standard tools, and container templates.

### runC

runC is the most widely used container runtime developed initially as part of Docker and
was later extracted as a separate tool and library. runC is a command-line tool for running applications
packaged according to the OCI format and is a compliant implementation of the OCI spec.
runC uses `libcontainer`, which is the same container library powering a Docker engine installation. Before
version 1.11, the Docker engine was used to manage volumes, networks, containers, images, etc. Now, the Docker
architecture has several components, and the runC features include the
following:

-

Full support for Linux namespaces, including user namespaces

-

Native support for all security features available in Linux

-

SELinux, AppArmor, seccomp, control groups, capability drop, `pivot_root`, UID/GID dropping, etc.

-

Native support of Windows 10 containers

-

Planned native support for the entire hardware manufacturer’s ecosystem

-

A formally specified configuration format, governed by the OCI under the Linux Foundation

### containerd

containerd is a high-level runtime that was split off from Docker. containerd is a background service that
acts as an API facade for various container runtimes and OSs. containerd has various components that provide it with
high-level functionality. containerd is a service for Linux and Windows that manages its host system’s complete
container life cycle, image transfer, storage, container execution, and network attachment. containerd’s client CLI
tool is `ctr`, and it is for development and debugging purposes for direct communication with containerd.
containerd-shim is the component that allows for daemonless containers. It resides as the parent of the container’s
process to facilitate a few things. containerd allows the runtimes, i.e., runC, to exit after it starts the container.
This way, we do not need the long-running runtime processes for containers. It also keeps the standard I/O and
other file descriptors open for the container if containerd and Docker die. If the shim does not run, then the pipe’s
parent side would be closed, and the container would exit. containerd-shim also allows the container’s exit status to
be reported back to a higher-level tool like Docker without having the container process’s actual parent do it.

### lmctfy

Google started lmctfy as its open source Linux container technology in 2013. lmctfy is a high-level
container runtime that provides the ability to create and delete containers but is no longer actively maintained and was
porting over to libcontainer, which is now containerd. lmctfy provided an API-driven configuration without
developers worrying about the details of cgroups and namespace internals.

### rkt

rkt started at CoreOS as an alternative to Docker in 2014. It is written in Go, uses pods as its basic compute unit,
and allows for a self-contained environment for applications. rkt’s native image format was the App Container
Image (ACI), defined in the App Container spec; this was deprecated in favor of the OCI format and specification
support. It supports the CNI specification and can run Docker images and OCI images. The rkt
project was archived in February 2020 by the maintainers.

### Docker

Docker, released in 2013, solved many of the problems that developers had running containers
end to end. It has all this functionality for developers to create, maintain, and deploy containers:

-

Formatting container images

-

Building container images

-

Managing container images

-

Managing instances of containers

-

Sharing container images

-

Running containers

[Figure 3-4](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch03.html#img-docker-eng) shows us the architecture of the Docker engine and its various components. Docker began as a monolith
application, building all the previous functionality into a single binary known as the *Docker engine*. The engine
contained the Docker client or CLI that allows developers to build, run, and push containers and images. The Docker server
runs as a daemon to manage the data volumes and networks for running containers. The client communicates to the
server through the Docker API. It uses containerd to manage the container life cycle, and it uses runC to spawn the container
process.

![neku 0304](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0304.png)

###### Figure 3-4. Docker engine

In the past few years, Docker has broken apart this monolith into separate components. To run a container,
the Docker engine creates the image and passes it to containerd. containerd calls containerd-shim, which uses runC to run
the container. Then, containerd-shim allows the runtime (runC in this case) to exit after it starts the container. This way, we
can run daemonless containers because we do not need the long-running runtime processes for containers.

Docker provides a separation of concerns for application developers and system administrators. It allows the developers
to focus on building their apps, and system admins focus on deployment. Docker provides a fast development cycle; to
test new versions of Golang for our web app, we can update the base image and run tests against it.
Docker provides application portability between running on-premise, in the cloud, or in any other data center. Its
motto is to build, ship, and run anywhere. A new container can quickly be provisioned for scalability and run
more apps on one host machine, increasing that machine’s efficiency.

### CRI-O

CRI-O is an OCI-based implementation of the Kubernetes CRI, while the OCI is a set of
specifications that container runtime engines must implement. Red Hat started the CRI
project in 2016 and in 2019 contributed it to the CNCF. CRI is a plugin interface that enables Kubernetes, via `Kubelet`, to communicate with any container runtime that satisfies the CRI interface. CRI-O development began in 2016
after the
Kubernetes project introduced CRI, and CRI-O 1.0 was released in 2017.  The CRI-O is a lightweight CRI
runtime made as a Kubernetes-specific high-level runtime built on gRPC and Protobuf over a UNIX socket. [Figure 3-5](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch03.html#cri-place)
points out where the CRI fits into the whole picture with the Kubernetes architecture. CRI-O provides stability in
the Kubernetes project, with a commitment to passing Kubernetes tests.

![neku 0305](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0305.png)

###### Figure 3-5. CRI about Kubernetes

There have been many companies, technologies, and innovations in the container space. This section has been a brief history
of that. The industry has landed on making sure the container landscape remains an open OCI project for all to use across
various ways to run containers. Kubernetes has helped shaped this effort as well with the adaption of the
CRI-O interface. Understanding the components of the container is vital to all administrators of container
deployments and developers using containers. A recent example of this importance is in Kubernetes 1.20, where dockershim
support will be deprecated. The Docker runtime utilizing the dockershim for administrators is deprecated, but developers
can still use Docker to build OCI-compliant containers to run.

###### Note

The first CRI implementation was the dockershim, which provided a layer of abstraction in front of the
Docker engine.

Now we will dive deeper into the container technology that powers them.

# Container Primitives

No matter if you are using Docker or containerd, runC starts and manages the actual containers for them. In this
section, we will review what runC takes care of for developers from a container perspective. Each of our
containers has Linux primitives known as *control groups* and *namespaces*. [Figure 3-6](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch03.html#namespaces) shows an example of what
this looks like; cgroups control access to resources in the kernel for our containers, and namespaces are individual
slices of resources to manage separately from the root namespaces, i.e., the host.

![neku 0306](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0306.png)

###### Figure 3-6. Namespaces and control groups

To help solidify these concepts, let’s dig into control groups and namespaces a bit
further.

## Control Groups

In short, a cgroup is a Linux kernel feature that limits, accounts for, and isolates resource usage.
Initially released in Linux 2.6.24, cgroups allow administrators to control different CPU
systems and memory for particulate processes. Cgroups are provided through pseudofilesystems and are maintained by the
core kernel code in cgroups. These separate subsystems maintain various cgroups in the kernel:

CPUThe process can be guaranteed a minimum number of CPU shares.

MemoryThese set up memory limits for a process.

Disk I/OThis and other devices are controlled via the device’s cgroup subsystem.

NetworkThis is maintained by the `net_cls` and marks packets leaving the cgroup.

`lscgroup` is a command-line tool that lists all the cgroups currently in the system.

runC will create the cgroups for the container at creation time. A cgroup controls how much of a resource a container
can use, while namespaces control what processes inside the container can see.

## Namespaces

Namespaces are features of the Linux kernel that isolate and virtualize system resources of a collection of
processes. Here are examples of virtualized resources:

PID namespaceProcesses ID, for process isolation

Network namespaceManages network interfaces and a separate networking stack

IPC namespaceManages access to interprocess communication (IPC) resources

Mount namespaceManages filesystem mount points

UTS namespaceUNIX time-sharing; allows single hosts to have different host and domain names for different
processes

UID namespacesUser ID; isolates process ownership with separate user and group assignments

A process’s user and group IDs can be different inside and outside a user’s namespace.  A process can
have an unprivileged user ID outside a user namespace while at the same time having a user ID of 0 inside the
container user namespace. The process has root privileges for execution inside the user namespace but is unprivileged
for operations outside the namespace.

[Example 3-1](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch03.html#namespace_single) is an example of how to inspect the namespaces for a process. All information for a process is on
the `/proc` filesystem in Linux. PID 1’s PID namespace is `4026531836`, and listing all the namespaces shows that
the PID namespace IDs match.

##### Example 3-1. Namespaces of a single process

```
vagrant@ubuntu-xenial:~$ sudo ps -p 1 -o pid,pidns
  PID      PIDNS
    1 4026531836

vagrant@ubuntu-xenial:~$ sudo ls -l /proc/1/ns
total 0
lrwxrwxrwx 1 root root 0 Dec 12 20:41 cgroup -> cgroup:[4026531835]
lrwxrwxrwx 1 root root 0 Dec 12 20:41 ipc -> ipc:[4026531839]
lrwxrwxrwx 1 root root 0 Dec 12 20:41 mnt -> mnt:[4026531840]
lrwxrwxrwx 1 root root 0 Dec 12 20:41 net -> net:[4026531957]
lrwxrwxrwx 1 root root 0 Dec 12 20:41 pid -> pid:[4026531836]
lrwxrwxrwx 1 root root 0 Dec 12 20:41 user -> user:[4026531837]
lrwxrwxrwx 1 root root 0 Dec 12 20:41 uts -> uts:[4026531838]
```

[Figure 3-7](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch03.html#containers) shows that effectively these two Linux primitives allow application developers to control and manage
their applications separate from the hosts and other applications either in containers or by running natively on the host.

![neku 0307](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0307.png)

###### Figure 3-7. Cgroups and namespaces powers combined

The following examples use Ubuntu 16.04 LTS Xenial Xerus. If you want to follow along on your system, more
information can be found in this book’s code repo. The repo contains the tools and configurations for building the
Ubuntu VM and Docker containers. Let’s get started with setting up and testing our namespaces.

## Setting Up Namespaces

[Figure 3-8](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch03.html#root-container-namespaces) outlines a basic container network setup. In the following pages, we will walk through all the Linux
commands that the low-level runtimes complete for container network creation.

![neku 0308](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0308.png)

###### Figure 3-8. Root network namespace and container network namespace

The following steps show how to create the networking setup shown in [Figure 3-8](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch03.html#root-container-namespaces):

1.

Create a host with a root network namespace.

1.

Create a new network namespace.

1.

Create a veth pair.

1.

Move one side of the veth pair into a new network namespace.

1.

Address side of the veth pair inside the new network namespace.

1.

Create a bridge interface.

1.

Address the bridge interface.

1.

Attach the bridge to the host interface.

1.

Attach one side of the veth pair to the bridge interface.

1.

Profit.

The following are all the Linux commands needed to create the network namespace, bridge, and veth pairs and wire them together:

```bash
$ echo 1 > /proc/sys/net/ipv4/ip_forward
$ sudo ip netns add net1
$ sudo ip link add veth0 type veth peer name veth1
$ sudo ip link set veth1 netns net1
$ sudo ip link add veth0 type veth peer name veth1
$ sudo ip netns exec net1 ip addr add 192.168.1.101/24 dev veth1
$ sudo ip netns exec net1 ip link set dev veth1 up
$ sudo ip link add br0 type bridge
$ sudo ip link set dev br0 up
$ sudo ip link set enp0s3 master br0
$ sudo ip link set veth0 master br0
$ sudo ip netns exec net1  ip route add default via 192.168.1.100
```

Let’s dive into an example and outline each command.

The `ip` Linux command sets up and controls the network namespaces.

###### Note

You can find more information about `ip` on its [man page](https://oreil.ly/jBKL7).

In [Example 3-2](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch03.html#example0302), we have used Vagrant and VirtualBox to create a fresh installation of Ubuntu for our testing purposes.

##### Example 3-2. Ubuntu testing virtual machine

```bash
$ vagrant up
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Importing base box 'ubuntu/xenial64'...
==> default: Matching MAC address for NAT networking...
==> default: Checking if box 'ubuntu/xenial64' version '20200904.0.0' is up to date...
==> default: Setting the name of the VM:
advanced_networking_code_examples_default_1600085275588_55198
==> default: Clearing any previously set network interfaces...
==> default: Available bridged network interfaces:
1) en12: USB 10/100 /1000LAN
2) en5: USB Ethernet(?)
3) en0: Wi-Fi (Wireless)
4) llw0
5) en11: USB 10/100/1000 LAN 2
6) en4: Thunderbolt 4
7) en1: Thunderbolt 1
8) en2: Thunderbolt 2
9) en3: Thunderbolt 3
==> default: When choosing an interface, it is usually the one that is
==> default: being used to connect to the internet.
==> default:
    default: Which interface should the network bridge to? 1
==> default: Preparing network interfaces based on configuration...
    default: Adapter 1: nat
    default: Adapter 2: bridged
==> default: Forwarding ports...
    default: 22 (guest) => 2222 (host) (adapter 1)
==> default: Running 'pre-boot' VM customizations...
==> default: Booting VM...
==> default: Waiting for machine to boot. This may take a few minutes...
    default: SSH address: 127.0.0.1:2222
    default: SSH username: vagrant
    default: SSH auth method: private key
    default: Warning: Connection reset. Retrying...
    default:
    default: Vagrant insecure key detected. Vagrant will automatically replace
    default: this with a newly generated keypair for better security.
    default:
    default: Inserting generated public key within guest...
    default: Removing insecure key from the guest if it's present...
    default: Key inserted! Disconnecting and reconnecting using new SSH key...
==> default: Machine booted and ready!
==> default: Checking for guest additions in VM...
==> default: Configuring and enabling network interfaces...
==> default: Mounting shared folders...
    default: /vagrant =>
    /Users/strongjz/Documents/code/advanced_networking_code_examples
```

Refer to the book
repo for the Vagrantfile to reproduce this.

###### Note

[Vagrant](https://oreil.ly/o8Qo0) is a local virtual machine manager created by HashiCorp.

After Vagrant boots our virtual machine, we can use Vagrant to `ssh` into this VM:

```
$± |master U:2 ?:2 ✗| → vagrant ssh
Welcome to Ubuntu 16.04.7 LTS (GNU/Linux 4.4.0-189-generic x86_64)

vagrant@ubuntu-xenial:~$
```

*IP forwarding* is an operating system’s ability to accept incoming network packets on one interface, recognize them for
another, and pass them on to that network accordingly. When enabled, IP forwarding allows a Linux machine to receive
incoming packets and forward them. A Linux machine acting as an ordinary host would not need to have IP forwarding
enabled because it generates and receives IP traffic for its purposes. By default, it is turned off; let’s
enable it on our Ubuntu instance:

```
vagrant@ubuntu-xenial:~$ sysctl net.ipv4.ip_forward
net.ipv4.ip_forward = 0
vagrant@ubuntu-xenial:~$ sudo echo 1 > /proc/sys/net/ipv4/ip_forward
vagrant@ubuntu-xenial:~$  sysctl net.ipv4.ip_forward
net.ipv4.ip_forward = 1
```

With our install of the Ubuntu instance, we can see that we do not have any additional network namespaces, so let’s create one:

```
vagrant@ubuntu-xenial:~$ sudo ip netns list
```

`ip netns` allows us to control the namespaces on the server. Creating one is as easy as typing `ip netns add net1`:

```
vagrant@ubuntu-xenial:~$ sudo ip netns add net1
```

As we work through this example, we can see the network namespace we just created:

```
vagrant@ubuntu-xenial:~$ sudo ip netns list
net1
```

Now that we have a new network namespace for our container, we will need a veth pair for communication between the root
network namespace and the container network namespace `net1`.

`ip` again allows administrators to create the veth pairs with a straightforward command. Remember from [Chapter 2](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch02.html#linux_networking) that
veth comes in pairs and acts as a conduit between network namespaces, so packets from one end are automatically forwarded
to the other.

```
vagrant@ubuntu-xenial:~$ sudo ip link add veth0 type veth peer name veth1
```

###### Tip

Interfaces 4 and 5 are the veth pairs in the command output. We can also see which are paired with each other,
`veth1@veth0` and `veth0@veth1`.

The `ip link list` command verifies the veth pair creation:

```
vagrant@ubuntu-xenial:~$ ip link list
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state
UNKNOWN mode DEFAULT group default qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc
pfifo_fast state UP mode DEFAULT group default qlen 1000
    link/ether 02:8f:67:5f:07:a5 brd ff:ff:ff:ff:ff:ff
3: enp0s8: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc
pfifo_fast state UP mode DEFAULT group default qlen 1000
    link/ether 08:00:27:0f:4e:0d brd ff:ff:ff:ff:ff:ff
4: veth1@veth0: <BROADCAST,MULTICAST,M-DOWN> mtu 1500 qdisc
noop state DOWN mode DEFAULT group default qlen 1000
    link/ether 72:e4:03:03:c1:96 brd ff:ff:ff:ff:ff:ff
5: veth0@veth1: <BROADCAST,MULTICAST,M-DOWN> mtu 1500 qdisc
noop state DOWN mode DEFAULT group default qlen 1000
    link/ether 26:1a:7f:2c:d4:48 brd ff:ff:ff:ff:ff:ff
vagrant@ubuntu-xenial:~$
```

Now let’s move `veth1` into the new network namespace created previously:

```
vagrant@ubuntu-xenial:~$ sudo ip link set veth1 netns net1
```

`ip netns exec` allows us to verify the network
namespace’s configuration. The output verifies that `veth1` is now in the network namespace `net`:

```
vagrant@ubuntu-xenial:~$ sudo ip netns exec net1 ip link list
4: veth1@if5: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state
DOWN mode DEFAULT group default qlen 1000
    link/ether 72:e4:03:03:c1:96 brd ff:ff:ff:ff:ff:ff link-netnsid 0
```

Network namespaces are entirely separate TCP/IP stacks in the Linux kernel. Being a new interface and in a new network
namespace, the veth interface will need IP addressing in order to carry packets from the `net1` namespace to the root
namespace and beyond the host:

```
vagrant@ubuntu-xenial:~$ sudo ip netns exec
net1 ip addr add 192.168.1.100/24 dev veth1
```

As with host networking interfaces, they will need to be “turned on”:

```
vagrant@ubuntu-xenial:~$ sudo ip netns exec net1 ip link set dev veth1 up
```

The state has now transitioned to `LOWERLAYERDOWN`. The status `NO-CARRIER` points in the right direction. Ethernet
needs a cable to be connected; our upstream veth pair is not on yet either. The `veth1` interface
is up and addressed but effectively still “unplugged”:

```
vagrant@ubuntu-xenial:~$ sudo ip netns exec net1 ip link list veth1
4: veth1@if5: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500
qdisc noqueue state LOWERLAYERDOWN mode DEFAULT
group default qlen 1000 link/ether 72:e4:03:03:c1:96
brd ff:ff:ff:ff:ff:ff link-netnsid 0
```

Let’s turn up the `veth0` side of the pair now:

```
vagrant@ubuntu-xenial:~$ sudo ip link set dev veth0 up
vagrant@ubuntu-xenial:~$ sudo ip link list
5: veth0@if4: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500
qdisc noqueue state UP mode DEFAULT group default qlen 1000
link/ether 26:1a:7f:2c:d4:48 brd ff:ff:ff:ff:ff:ff link-netnsid 0
```

Now the veth pair inside the `net1` namespace is `UP`:

```
vagrant@ubuntu-xenial:~$ sudo ip netns exec net1 ip link list
4: veth1@if5: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500
qdisc noqueue state UP mode DEFAULT group default qlen 1000
link/ether 72:e4:03:03:c1:96 brd ff:ff:ff:ff:ff:ff link-netnsid 0
```

Both sides of the veth pair report up; we need to connect the root namespace veth side to the bridge interface. Make
sure to select the interface you’re working with, in this case `enp0s8`; it may be different for others:

```
vagrant@ubuntu-xenial:~$ sudo ip link add br0 type bridge
vagrant@ubuntu-xenial:~$ sudo ip link set dev br0 up
vagrant@ubuntu-xenial:~$ sudo ip link set enp0s8 master br0
vagrant@ubuntu-xenial:~$ sudo ip link set veth0 master br0
```

We can see that the enp0s8 and veth0 report are part of the bridge `br0` interface, `master br0 state up`.

Next, let’s test connectivity to our network namespace:

```
vagrant@ubuntu-xenial:~$ ping 192.168.1.100 -c 4
PING 192.168.1.100 (192.168.1.100) 56(84) bytes of data.
From 192.168.1.10 icmp_seq=1 Destination Host Unreachable
From 192.168.1.10 icmp_seq=2 Destination Host Unreachable
From 192.168.1.10 icmp_seq=3 Destination Host Unreachable
From 192.168.1.10 icmp_seq=4 Destination Host Unreachable

--- 192.168.1.100 ping statistics ---
4 packets transmitted, 0 received, +4 errors, 100% packet loss, time 6043ms
```

Our new network namespace does not have a default route, so it does not know where to route our packets for the `ping`
requests:

```bash
$ sudo ip netns exec net1
ip route add default via 192.168.1.100
$ sudo ip netns exec net1 ip r
default via 192.168.1.100 dev veth1
192.168.1.0/24 dev veth1  proto kernel  scope link  src 192.168.1.100
```

Let’s try that again:

```bash
$ ping 192.168.2.100 -c 4
PING 192.168.2.100 (192.168.2.100) 56(84) bytes of data.
bytes from 192.168.2.100: icmp_seq=1 ttl=64 time=0.018 ms
bytes from 192.168.2.100: icmp_seq=2 ttl=64 time=0.028 ms
bytes from 192.168.2.100: icmp_seq=3 ttl=64 time=0.036 ms
bytes from 192.168.2.100: icmp_seq=4 ttl=64 time=0.043 ms

--- 192.168.2.100 ping statistics ---
packets transmitted, 4 received, 0% packet loss, time 2997ms
```

```bash
$ ping 192.168.2.101 -c 4
PING 192.168.2.101 (192.168.2.101) 56(84) bytes of data.
bytes from 192.168.2.101: icmp_seq=1 ttl=64 time=0.016 ms
bytes from 192.168.2.101: icmp_seq=2 ttl=64 time=0.017 ms
bytes from 192.168.2.101: icmp_seq=3 ttl=64 time=0.016 ms
bytes from 192.168.2.101: icmp_seq=4 ttl=64 time=0.021 ms

--- 192.168.2.101 ping statistics ---
packets transmitted, 4 received, 0% packet loss, time 2997ms
rtt min/avg/max/mdev = 0.016/0.017/0.021/0.004 ms
```

Success! We have created the bridge interface and veth pairs, migrated one to the new network namespace, and tested
connectivity. [Example 3-3](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch03.html#Namespace-Recap) is a recap of all the commands we ran to accomplish that.

##### Example 3-3. Recap network namespace creation

```bash
$ echo 1 > /proc/sys/net/ipv4/ip_forward
$ sudo ip netns add net1
$ sudo ip link add veth0 type veth peer name veth1
$ sudo ip link set veth1 netns net1
$ sudo ip link add veth0 type veth peer name veth1
$ sudo ip netns exec net1 ip addr add 192.168.1.101/24 dev veth1
$ sudo ip netns exec net1 ip link set dev veth1 up
$ sudo ip link add br0 type bridge
$ sudo ip link set dev br0 up
$ sudo ip link set enp0s3 master br0
$ sudo ip link set veth0 master br0
$ sudo ip netns exec net1  ip route add default via 192.168.1.100
```

For a developer not familiar with all these commands, that is a lot to remember and very easy to bork up! If the
bridge information is incorrect, it could take down an entire part of the network with network loops. These issues
are ones that system administrators would like to avoid, so they prevent developers from making those types of
networking changes on the system. Fortunately, containers help remove the developers’ strain to remember all
these commands and alleviate system admins’ fear of giving devs access to run those commands.

These  commands  are  all  needed  just  for  the  network  namespace  for  *every*  container  creation  and  deletion.  The
namespace  creation  in  [Example 3-3](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch03.html#Namespace-Recap) is  the  container runtime’s job. Docker manages this for us, in its way. The CNI project standardizes the network creation for all systems. The CNI, much like the
OCI, is a way for developers to standardize and prioritize specific tasks for managing parts of the container’s life
cycle.  In later sections, we will discuss CNI.

# Container Network Basics

The previous section showed us all the commands needed to create namespaces for our networking. Let’s
investigate how Docker does this for us. We also only used the bridge mode; there several other modes for container
networking.  This section will deploy several Docker containers and examine their networking and explain how containers
communicate externally to the host and with each other.

Let’s start by discussing the several network “modes” used when working with
containers:

NoneNo networking disables networking for the container.  Use this mode when the container does not need network
access.

BridgeIn bridge networking, the container runs in a private network internal to the host. Communication with other
containers in the network is open. Communication with services outside the host goes through Network Address Translation
(NAT) before exiting the host. Bridge mode is the default mode of networking when the `--net` option is not specified.

HostIn host networking, the container shares the same IP address and the network namespace as that of the host.
Processes running inside this container have the same network capabilities as services running directly on the host.
This mode is useful if the container needs access to network resources on the hosts. The container loses the benefit
of network segmentation with this mode of networking. Whoever is deploying the containers will have to manage and
contend with the ports of services running this node.

###### Warning

The host networking driver works only on Linux hosts. Docker Desktop for Mac and Windows, or Docker EE for Windows
Server, does not support host networking mode.

MacvlanMacvlan uses a parent interface. That interface can be a host interface such as
eth0, a subinterface, or even a bonded host adapter that bundles Ethernet interfaces into a single logical
interface. Like all Docker networks, Macvlan networks are segmented from each other, providing access within a
network, but not between networks. Macvlan allows a physical interface to have multiple MAC and IP addresses
using Macvlan subinterfaces. Macvlan has four types: Private, VEPA, Bridge (which Docker default uses), and
Passthrough. With a bridge,  use NAT for external connectivity. With Macvlan, since hosts are directly mapped to
the physical network, external connectivity can be done using the same DHCP server and switch that the host uses.

###### Warning

Most cloud providers block Macvlan networking. Administrative access to networking equipment is needed.

IPvlanIPvlan is similar to Macvlan, with a significant difference: IPvlan does not assign MAC addresses to
created subinterfaces. All subinterfaces share the parent’s interface MAC address but use different IP addresses.
IPvlan has two modes, L2 or L3. In IPvlan, L2, or layer 2, mode is analog to the Macvlan bridge mode.  IPvlan L3, or
layer 3, mode masquerades as a layer 3 device between the subinterfaces and parent interface.

OverlayOverlay allows for the extension of the same network across hosts in a container cluster. The overlay
network virtually sits on top of the underlay/physical networks. Several open source projects create these
overlay networks, which we will discuss later in the chapter.

CustomCustom bridge networking is the same as bridge networking but uses a bridge explicitly created for that
container. An example of using this would be a container that runs on a database bridge network. A separate container
can have an interface on the default and database bridge, enabling it to communicate with both networks as needed.

Container-defined networking allows a container to share the address and network configuration of another container.
This sharing enables process isolation between containers, where each container runs one service but where services
can still communicate with one another on `127.0.0.1`.

To test all these modes, we need to continue to use a Vagrant Ubuntu host but now with Docker
installed. Docker for Mac and Windows does not support host networking mode, so we must use Linux for this example.
You can do this with the provisioned machine in [Example 1-1](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch01.html#minmal_web_server_in_go)  or use the Docker Vagrant version in the book’s code repo.
The Ubuntu Docker install directions are as follows if you want to do it
manually:

```bash
$ vagrant up
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Importing base box 'ubuntu/xenial64'...
==> default: Matching MAC address for NAT networking...
==> default: Checking if box
'ubuntu/xenial64' version '20200904.0.0' is up to date...
==> default: Setting the name of the VM:
advanced_networking_code_examples_default_1600085275588_55198
==> default: Clearing any previously set network interfaces...
==> default: Available bridged network interfaces:
1) en12: USB 10/100 /1000LAN
2) en5: USB Ethernet(?)
3) en0: Wi-Fi (Wireless)
4) llw0
5) en11: USB 10/100/1000 LAN 2
6) en4: Thunderbolt 4
7) en1: Thunderbolt 1
8) en2: Thunderbolt 2
9) en3: Thunderbolt 3
==> default: When choosing an interface, it is usually the one that is
==> default: being used to connect to the internet.
==> default:
    default: Which interface should the network bridge to? 1
==> default: Preparing network interfaces based on configuration...
    default: Adapter 1: nat
    default: Adapter 2: bridged
==> default: Forwarding ports...
    default: 22 (guest) => 2222 (host) (adapter 1)
==> default: Running 'pre-boot' VM customizations...
==> default: Booting VM...
==> default: Waiting for machine to boot. This may take a few minutes...
    default: SSH address: 127.0.0.1:2222
    default: SSH username: vagrant
    default: SSH auth method: private key
    default: Warning: Connection reset. Retrying...
    default:
    default: Vagrant insecure key detected. Vagrant will automatically replace
    default: this with a newly generated keypair for better security.
    default:
    default: Inserting generated public key within guest...
    default: Removing insecure key from the guest if it's present...
    default: Key inserted! Disconnecting and reconnecting using new SSH key...
==> default: Machine booted and ready!
==> default: Checking for guest additions in VM...
==> default: Configuring and enabling network interfaces...
==> default: Mounting shared folders...
    default: /vagrant =>
    /Users/strongjz/Documents/code/advanced_networking_code_examples
    default: + sudo docker run hello-world
    default: Unable to find image 'hello-world:latest' locally
    default: latest: Pulling from library/hello-world
    default: 0e03bdcc26d7:
    default: Pulling fs layer
    default: 0e03bdcc26d7:
    default: Verifying Checksum
    default: 0e03bdcc26d7:
    default: Download complete
    default: 0e03bdcc26d7:
    default: Pull complete
    default: Digest:
    sha256:4cf9c47f86df71d48364001ede3a4fcd85ae80ce02ebad74156906caff5378bc
    default: Status: Downloaded newer image for hello-world:latest
    default:
    default: Hello from Docker!
    default: This message shows that your
    default: installation appears to be working correctly.
    default:
    default: To generate this message, Docker took the following steps:
    default:  1. The Docker client contacted the Docker daemon.
    default:  2. The Docker daemon pulled the "hello-world" image
    default: from the Docker Hub.
    default:     (amd64)
    default:  3. The Docker daemon created a new container from that image
    default: which runs the executable that produces the output you are
    default: currently reading.
    default:  4. The Docker daemon streamed that output to the Docker
    default: client, which sent it to your terminal.
    default:
    default: To try something more ambitious, you can run an Ubuntu
    default: container with:
    default:  $ docker run -it ubuntu bash
    default:
    default: Share images, automate workflows, and more with a free Docker ID:
    default:  https://hub.docker.com
    default:
    default: For more examples and ideas, visit:
    default:  https://docs.docker.com/get-started
```

Now that we have the host up, let’s begin investigating the different networking setups we have to work with in
Docker. [Example 3-4](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch03.html#docker_networks) shows that Docker creates three network types during the install: bridge, host, and none.

##### Example 3-4. Docker networks

```bash
vagrant@ubuntu-xenial:~$ sudo docker network ls
NETWORK ID          NAME                DRIVER              SCOPE
1fd1db59c592        bridge              bridge              local
eb34a2105b0f        host                host                local
941ce103b382        none                null                local
vagrant@ubuntu-xenial:~$
```

The default is a Docker bridge, and a container gets attached to it and provisioned with an IP address in the `172.17.0.0/16`
default subnet. [Example 3-5](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch03.html#docker_bridge_interfaces) is a view of Ubuntu’s default interfaces and the Docker install that creates the `docker0`
bridge interface for the host.

##### Example 3-5. Docker bridge interface

```
vagrant@ubuntu-xenial:~$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc
noqueue state UNKNOWN group default qlen 1 
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
    valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
    valid_lft forever preferred_lft forever
2: enp0s3:
<BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group
default qlen 1000 
    link/ether 02:8f:67:5f:07:a5 brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global enp0s3
    valid_lft forever preferred_lft forever
    inet6 fe80::8f:67ff:fe5f:7a5/64 scope link
    valid_lft forever preferred_lft forever
3: enp0s8:
<BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group
default qlen 1000 
    link/ether 08:00:27:22:0e:46 brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.19/24 brd 192.168.1.255 scope global enp0s8
    valid_lft forever preferred_lft forever
    inet 192.168.1.20/24 brd 192.168.1.255 scope global secondary enp0s8
    valid_lft forever preferred_lft forever
    inet6 2605:a000:160d:517:a00:27ff:fe22:e46/64 scope global mngtmpaddr dynamic
    valid_lft 604600sec preferred_lft 604600sec
    inet6 fe80::a00:27ff:fe22:e46/64 scope link
    valid_lft forever preferred_lft forever
4: docker0:
<NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group
default 
    link/ether 02:42:7d:50:c7:01 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
    valid_lft forever preferred_lft forever
    inet6 fe80::42:7dff:fe50:c701/64 scope link
    valid_lft forever preferred_lft forever
```

![1](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/1.png)

This is the loopback interface.

![2](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/2.png)

enp0s3 is our NAT’ed virtual box interface.

![3](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/3.png)

enp0s8 is the host interface; this is on the same network as our host and uses DHCP to get the `192.168.1.19`
address of default Docker bridge.

![4](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/4.png)

The default Docker container interface uses bridge mode.

[Example 3-6](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch03.html#docker_bridge) started a busybox container with the `docker run` command and requested that the Docker returns the
container’s IP address. Docker default NATed address is `172.17.0.0/16`, with our busybox container getting `172.17.0.2`.

##### Example 3-6. Docker bridge

```bash
vagrant@ubuntu-xenial:~$ sudo docker run -it busybox ip a
Unable to find image 'busybox:latest' locally
latest: Pulling from library/busybox
df8698476c65: Pull complete
Digest: sha256:d366a4665ab44f0648d7a00ae3fae139d55e32f9712c67accd604bb55df9d05a
Status: Downloaded newer image for busybox:latest
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
    valid_lft forever preferred_lft forever
7: eth0@if8: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue
    link/ether 02:42:ac:11:00:02 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.2/16 brd 172.17.255.255 scope global eth0
    valid_lft forever preferred_lft forever
```

The host networking in [Example 3-7](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch03.html#docker_host_networking) shows that the container shares the same network namespace as the host. We can
see that the interfaces are the same as that of the host; enp0s3, enp0s8, and docker0 are present in the container
`ip a` command
output.

##### Example 3-7. Docker host networking

```bash
vagrant@ubuntu-xenial:~$ sudo docker run -it --net=host busybox ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
    valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
    valid_lft forever preferred_lft forever`
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast qlen 1000
    link/ether 02:8f:67:5f:07:a5 brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global enp0s3
    valid_lft forever preferred_lft forever
    inet6 fe80::8f:67ff:fe5f:7a5/64 scope link
    valid_lft forever preferred_lft forever
3: enp0s8: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast qlen 1000
    link/ether 08:00:27:22:0e:46 brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.19/24 brd 192.168.1.255 scope global enp0s8
    valid_lft forever preferred_lft forever
    inet 192.168.1.20/24 brd 192.168.1.255 scope global secondary enp0s8
    valid_lft forever preferred_lft forever
    inet6 2605:a000:160d:517:a00:27ff:fe22:e46/64 scope global dynamic
    valid_lft 604603sec preferred_lft 604603sec
    inet6 fe80::a00:27ff:fe22:e46/64 scope link
    valid_lft forever preferred_lft forever
4: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue
    link/ether 02:42:7d:50:c7:01 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
    valid_lft forever preferred_lft forever
    inet6 fe80::42:7dff:fe50:c701/64 scope link
    valid_lft forever preferred_lft forever
```

From the veth bridge example previously set up, let’s see how much simpler it is when Docker manages that
for us. To view this, we need a process to keep the container running. The following command
starts up a busybox container and drops into an `sh` command line:

```bash
vagrant@ubuntu-xenial:~$ sudo docker run -it --rm busybox /bin/sh
/#
```

We have a loopback interface, `lo`, and an Ethernet interface `eth0` connected to veth12, with a Docker default IP
address of `172.17.0.2`. Since our previous command only outputted an `ip a` result and the container exited
afterward, Docker reused the IP address `172.17.0.2` for the running busybox container:

```
/# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
    valid_lft forever preferred_lft forever
11: eth0@if12: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue
    link/ether 02:42:ac:11:00:02 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.2/16 brd 172.17.255.255 scope global eth0
    valid_lft forever preferred_lft forever
```

Running the `ip r` inside the container’s network namespace, we can see that the container’s route table is automatically
set up as well:

```
/ # ip r
default via 172.17.0.1 dev eth0
172.17.0.0/16 dev eth0 scope link  src 172.17.0.2
```

If we open a new terminal and `vagrant ssh` into our Vagrant Ubuntu instance and run the `docker ps` command, it
shows all the information in the running busybox container:

```bash
vagrant@ubuntu-xenial:~$ sudo docker ps
CONTAINER ID        IMAGE       COMMAND
3b5a7c3a74d5        busybox     "/bin/sh"

CREATED         STATUS        PORTS     NAMES
47 seconds ago  Up 46 seconds           competent_mendel
```

We can see the veth interface Docker set up for the container `veth68b6f80@if11` on the same host’s
networking namespace. It is a member of the bridge for `docker0` and is turned on `master docker0
state UP`:

```
vagrant@ubuntu-xenial:~$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group
default qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
    valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
    valid_lft forever preferred_lft forever
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP
group default qlen 1000
    link/ether 02:8f:67:5f:07:a5 brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global enp0s3
    valid_lft forever preferred_lft forever
    inet6 fe80::8f:67ff:fe5f:7a5/64 scope link
    valid_lft forever preferred_lft forever
3: enp0s8: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP
group default qlen 1000
    link/ether 08:00:27:22:0e:46 brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.19/24 brd 192.168.1.255 scope global enp0s8
    valid_lft forever preferred_lft forever
    inet 192.168.1.20/24 brd 192.168.1.255 scope global secondary enp0s8
    valid_lft forever preferred_lft forever
    inet6 2605:a000:160d:517:a00:27ff:fe22:e46/64 scope global mngtmpaddr dynamic
    valid_lft 604745sec preferred_lft 604745sec
    inet6 fe80::a00:27ff:fe22:e46/64 scope link
    valid_lft forever preferred_lft forever
4: docker0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP
group default
    link/ether 02:42:7d:50:c7:01 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
    valid_lft forever preferred_lft forever
    inet6 fe80::42:7dff:fe50:c701/64 scope link
    valid_lft forever preferred_lft forever
12: veth68b6f80@if11: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue
master docker0 state UP group default
    link/ether 3a:64:80:02:87:76 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet6 fe80::3864:80ff:fe02:8776/64 scope link
    valid_lft forever preferred_lft forever
```

The Ubuntu host’s route table shows Docker’s routes for reaching containers running on the host:

```
vagrant@ubuntu-xenial:~$ ip r
default via 192.168.1.1 dev enp0s8
10.0.2.0/24 dev enp0s3  proto kernel  scope link  src 10.0.2.15
172.17.0.0/16 dev docker0  proto kernel  scope link  src 172.17.0.1
192.168.1.0/24 dev enp0s8  proto kernel  scope link  src 192.168.1.19
```

By default, Docker does not add the network namespaces it creates to `/var/run` where `ip netns list` expects newly
created network namespaces. Let’s work through how we can see those namespaces now. Three steps are required to list the
Docker network namespaces from the `ip` command:

1.

Get the running container’s PID.

1.

Soft link the network namespace from `/proc/PID/net/` to `/var/run/netns`.

1.

List the network namespace.

`docker ps` outputs the container ID needed to inspect the running PID on the host PID namespace:

```bash
vagrant@ubuntu-xenial:~$ sudo docker ps
CONTAINER ID        IMAGE               COMMAND
1f3f62ad5e02        busybox             "/bin/sh"

CREATED             STATUS              PORTS NAMES
11 minutes ago      Up 11 minutes       determined_shamir
```

`docker inspect` allows us to parse the output and get the host’s process’s PID. If we run `ps -p` on the host
PID namespace, we can see it is running `sh`, which tracks our `docker run` command:

```bash
vagrant@ubuntu-xenial:~$ sudo docker inspect -f '{{.State.Pid}}' 1f3f62ad5e02
25719
vagrant@ubuntu-xenial:~$ ps -p 25719
  PID TTY          TIME CMD
25719 pts/0    00:00:00 sh
```

`1f3f62ad5e02` is the container ID, and `25719` is the PID of the busybox container running `sh`, so now we can create a
symbolic link for the container’s network namespace created by Docker to where `ip` expects with the following command:

```bash
$ sudo ln -sfT /proc/25719/ns/net /var/run/netns/1f3f62ad5e02
```

###### Note

When using the container ID and process ID from the examples, keep in mind they will be different on your systems.

Now the `ip netns exec` commands return the same IP address, `172.17.0.2`, that the `docker exec` command
does:

```
vagrant@ubuntu-xenial:~$ sudo ip netns exec 1f3f62ad5e02 ip a
1: lo:
<LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
13: eth0@if14:
<BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 02:42:ac:11:00:02 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 172.17.0.2/16 brd 172.17.255.255 scope global eth0
       valid_lft forever preferred_lft forever
```

We can verify with `docker exec` and run `ip an` inside the busybox container. The IP address, MAC address, and
network interfaces all match the output:

```bash
vagrant@ubuntu-xenial:~$ sudo docker exec 1f3f62ad5e02 ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
13: eth0@if14: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue
    link/ether 02:42:ac:11:00:02 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.2/16 brd 172.17.255.255 scope global eth0
       valid_lft forever preferred_lft forever
```

Docker starts our container; creates the network namespace, the veth pair, and the docker0 bridge (if it does not already
exist); and then attaches them all for every container creation and deletion, in a single command! That is powerful from an
application developer’s perspective. There’s no need to remember all those Linux commands and possibly break the networking on
a host. This discussion has mostly been about a single host. How Docker coordinates container communication between hosts in
a cluster is discussed in the next section.

## Docker Networking Model

Libnetwork is Docker’s take on container networking, and its design philosophy is in the container networking
model (CNM). Libnetwork implements the CNM and works in three components: the sandbox,
endpoint, and network. The sandbox implements the management of the Linux network namespaces for all containers
running on the host. The network component is a collection of endpoints on the same network. Endpoints are hosts on
the network. The network controller manages all of this via APIs in the Docker engine.

On the endpoint, Docker uses `iptables` for network isolation. The container publishes a port to be accessed externally. Containers do not receive a public IPv4 address; they receive a private RFC 1918 address. Services running on a
container must be exposed port by port, and container ports have to be mapped to the host port so conflicts are
avoided. When Docker starts, it creates a virtual bridge interface, `docker0`, on the host machine and assigns it a random
IP address from the private 1918 range. This bridge passes packets between two connected devices, just like a physical
bridge does. Each new container gets one interface automatically attached to the `docker0` bridge; [Figure 3-9](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch03.html#docker-bridge)
represents this and is similar to the approach we demonstrated in the previous sections.

![neku 0309](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0309.png)

###### Figure 3-9. Docker bridge

The CNM maps the network modes to drives we have already discussed. Here is a list of the networking
mode and the Docker engine equivalent:

BridgeDefault Docker bridge (see [Figure 3-9](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch03.html#docker-bridge), and our previous examples show this)

Custom or RemoteUser-defined bridge, or allows users to create or use their plugin

OverlayOverlay

NullNo networking options

Bridge networks are for containers running on the same host. Communicating with containers running on different hosts
can use an overlay network. Docker uses the concept of local and global drivers. Local drivers, a bridge, for example,
are host-centric and do not do cross-node coordination. That is the job of global drivers such as Overlay. Global
drivers rely on libkv, a key-value store abstraction, to coordinate across machines.  The CNM does not provide the
key-value store, so external ones like Consul, etcd, and Zookeeper are needed.

The next section will discuss in depth the technologies enabling overlay networks.

## Overlay Networking

Thus far, our examples have been on a single host, but production applications at scale do not run on a
single host. For applications running in containers on separate nodes to communicate, several issues need to be
solved, such as how to coordinate routing information between hosts, port conflicts, and IP address management, to name a few. One
technology that helps with routing between hosts for containers is a VXLAN. In [Figure 3-10](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch03.html#vxlan-hosts), we can see a layer 2 overlay network created with a VXLAN running over the physical L3 network.

We briefly discussed VXLANs in [Chapter 1](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch01.html#networking_introduction), but a more in-depth explanation of how the data transfer works to enable
the container-to-container communication is warranted here.

![neku 0310](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0310.png)

###### Figure 3-10. VXLAN tunnel

A VXLAN is an extension of the VLAN protocol creating 16 million unique identifiers. Under IEEE 802.1Q, the maximum
number of VLANs on a given Ethernet network is 4,094. The transport protocol over a  physical data center network is
IP plus UDP. VXLAN defines a MAC-in-UDP encapsulation scheme where the original layer 2 frame has a VXLAN header
added wrapped in a UDP IP packet. [Figure 3-11](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch03.html#docker-overlay-advance) shows the IP packet encapsulated in the UDP packet and its headers.

A VXLAN packet is a MAC-in-UDP encapsulated packet. The layer 2 frame has a VXLAN header added to it and is placed in a
UDP-IP packet. The VXLAN identifier is 24 bits. That is how a VXLAN can support 16 million segments.

[Figure 3-11](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch03.html#docker-overlay-advance) is a more detailed version of [Chapter 1](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch01.html#networking_introduction). We have the VXLAN tunnel endpoints, VTEPs, on both
hosts, and they are attached to the host’s bridge interfaces with the containers attached to the bridge. The VTEP performs data frame
encapsulation and decapsulation. The VTEP peer interaction ensures that the data gets
forwarded to the relevant destination container addresses. The data leaving the containers is encapsulated with
VXLAN information and transferred over the VXLAN tunnels to be de-encapsulated by the peer VTEP.

Overlay networking enables cross-host communication on the network for containers. The CNM still has other issues
that make it incompatible with Kubernetes.  The Kubernetes maintainers decided to use the CNI
project started at CoreOS. It is simpler than CNM, does not require daemons, and is designed to be cross-platform.

![neku 0311](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0311.png)

###### Figure 3-11. VXLAN tunnel detailed

## Container Network Interface

CNI is the software interface between the container runtime and the
network implementation. There are many options to choose from when implementing a CNI; we will discuss a few notable
ones. CNI started at CoreOS as part of the rkt project; it is now a CNCF project. The
CNI project consists of a specification and libraries for developing plugins to configure network interfaces in Linux
containers. CNI is concerned with a container’s network connectivity by allocating resources when the container gets
created and removing them when deleted. A CNI plugin is responsible for associating a network interface to the
container network namespace and making any necessary changes to the host. It then assigns the IP to the interface and
sets up the routes for it. [Figure 3-12](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch03.html#cni) outlines the CNI architecture. The container runtime uses a configuration file for
the host’s network information; in Kubernetes, the Kubelet also uses this configuration file. The CNI and container
runtime communicate with each other and apply commands to the configured CNI plugin.

![neku 0312](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0312.png)

###### Figure 3-12. CNI architecture

There are several open source projects that implement CNI plugins with various features and functionality. Here is an
outline of several:

CiliumCilium is open source software for securing network connectivity between application containers. Cilium
is an L7/HTTP-aware CNI and can enforce network policies on L3–L7 using an identity-based security model decoupled from
network addressing. A Linux technology eBPF powers it.

FlannelFlannel is a simple way to configure a layer 3 network fabric designed for Kubernetes. Flannel focuses
on networking. Flannel
uses the Kubernetes cluster’s existing `etcd` datastore to store its state information to avoid providing a dedicated one.

CalicoAccording to Calico, it “combines flexible networking capabilities with run-anywhere security enforcement to provide
a solution with native Linux kernel performance and true cloud-native scalability.” It has full network policy
support and works well in conjunction with other CNIs. Calico does not use an overlay network. Instead, Calico
configures a layer 3 network that uses the BGP routing protocol to route packets between hosts. Calico can also
integrate with Istio, a service mesh, to interpret and enforce policy for workloads within the cluster, both at the
service mesh and the network infrastructure layers.

AWSAWS has its open source implementation of a CNI, the AWS VPC CNI. It provides high throughput and availability by
being directly on the AWS network. There is low latency using this CNI by providing little overhead because of no
additional overlay network and minimal network jitter running on the AWS network. Cluster and network administrators
can apply existing AWS VPC networking and security best practices for building Kubernetes networks on AWS. They can
accomplish those best practices because the AWS CNI includes the capability to use native AWS services like VPC flow
logs for analyzing network events and patterns, VPC routing policies for traffic management, and security groups and
network access control lists for network traffic isolation. We will discuss more about the AWS VPC CNI in [Chapter 6](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#kubernetes_and_cloud_networking).

###### Note

The Kubernetes.io website offers a [list of the CNI options available](https://oreil.ly/imDMP).

There are many more options for a CNI, and it is up to the cluster administrator, network admins, and application
developers to best decide which CNI solves their business use cases. In later chapters, we will walk through use cases
and deploy several to help admins make a decision.

In our next section, we will walk through container connectivity examples using the Golang web server and Docker.

# Container Connectivity

Like we experimented with in the previous chapter, we will use the Go minimal web server to walk through the concept of container
connectivity. We will explain what is happening at the container level when we deploy the web server as a container on
our Ubuntu host.

The following are the two networking scenarios we will walk through:

-

Container to container on the Docker host

-

Container to container on separate hosts

The Golang web server is hardcoded to run on port 8080, `http.ListenAndServe("0.0.0.0:8080", nil)`, as we can see in
[Example 3-8](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch03.html#minimal_web_server_in_go).

##### Example 3-8. Minimal web server in Go

```
package main

import (
	"fmt"
	"net/http"
)

func hello(w http.ResponseWriter, _ *http.Request) {
	fmt.Fprintf(w, "Hello")
}

func main() {
	http.HandleFunc("/", hello)
	http.ListenAndServe("0.0.0.0:8080", nil)
}
```

To provision our minimal Golang web server, we need to create it from a Dockerfile. [Example 3-9](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch03.html#dockerfile_for_golang_minimal_webserver) displays our Golang
web server’s Dockerfile. The Dockerfile contains instructions to specify what to do when building the image. It begins with
the `FROM` instruction and specifies what the base image should be. The `RUN` instruction specifies a command to execute.
Comments start with `#`. Remember, each line in a Dockerfile creates a new layer if it changes the image’s state.
Developers need to find the right balance between having lots of layers created for the image and the readability of
the Dockerfile.

##### Example 3-9. Dockerfile for Golang minimal web server

```dockerfile
FROM golang:1.15 AS builder 
WORKDIR /opt 
COPY web-server.go . 
RUN CGO_ENABLED=0 GOOS=linux go build -o web-server . 

FROM golang:1.15 
WORKDIR /opt 
COPY --from=0 /opt/web-server . 
CMD ["/opt/web-server"]
```

![1](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/1.png)

Since our web server is written in Golang, we can compile our Go server in a container to reduce the image’s size
to only the compiled Go binary. We start by using the Golang base image with version 1.15 for our web server.

![2](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/2.png)

`WORKDIR` sets the working directory for all the subsequent commands to run from.

![3](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/3.png)

`COPY` copies the `web-server.go` file that defines our application as the working directory.

![4](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/4.png)

`RUN` instructs Docker to compile our Golang application in the builder container.

![5](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/5.png)

Now to run our application, we define `FROM` for the application base image, again as `golang:1.15`; we can
further minimize the final size of the image by using other minimal images like alpine.

![6](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/6.png)

Being a new container, we again set the working directory to `/opt`.

![7](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/7.png)

`COPY` here will copy the compiled Go binary from the builder container into the application container.

![8](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/8.png)

`CMD` instructs Docker that the command to run our application is to start our web server.

There are some Dockerfile best practices that developers and admins should adhere to when containerizing their
applications:

-

Use one `ENTRYPOINT` per Dockerfile. The `ENTRYPOINT`
or `CMD` tells Docker what process starts inside the running container, so there should be only one running process;
containers are all about process isolation.

-

To cut down on the container layers, developers should combine
similar commands into one using & & and \. Each new command in the Dockerfile adds a layer to the Docker
container image, thus increasing its storage.

-

Use the caching system to improve the containers’ build times. If there is no change to
a layer, it should be at the top of the Dockerfile. Caching is part of the reason that the order of statements is
essential. Add files that are least likely to change first and the ones most likely to change last.

-

Use multistage builds to reduce the size of the final image drastically.

-

Do not install unnecessary tools or packages. Doing this will reduce the containers’ attack surface and size,
reducing network transfer times from the registry to the hosts running the containers.

Let’s build our Golang web server and review the Docker commands to do so.

`docker build` instructs Docker to build our images from the Dockerfile instructions:

```bash
$ sudo docker build .
Sending build context to Docker daemon   4.27MB
Step 1/8 : FROM golang:1.15 AS builder
1.15: Pulling from library/golang
57df1a1f1ad8: Pull complete
71e126169501: Pull complete
1af28a55c3f3: Pull complete
03f1c9932170: Pull complete
f4773b341423: Pull complete
fb320882041b: Pull complete
24b0ad6f9416: Pull complete
Digest:
sha256:da7ff43658854148b401f24075c0aa390e3b52187ab67cab0043f2b15e754a68
Status: Downloaded newer image for golang:1.15
 ---> 05c8f6d2538a
Step 2/8 : WORKDIR /opt
 ---> Running in 20c103431e6d
Removing intermediate container 20c103431e6d
 ---> 74ba65cfdf74
Step 3/8 : COPY web-server.go .
 ---> 7a36ec66be52
Step 4/8 : RUN CGO_ENABLED=0 GOOS=linux go build -o web-server .
 ---> Running in 5ea1c0a85422
Removing intermediate container 5ea1c0a85422
 ---> b508120db6ba
Step 5/8 : FROM golang:1.15
 ---> 05c8f6d2538a
Step 6/8 : WORKDIR /opt
 ---> Using cache
 ---> 74ba65cfdf74
Step 7/8 : COPY --from=0 /opt/web-server .
 ---> dde6002760cd
Step 8/8 : CMD ["/opt/web-server"]
 ---> Running in 2bcb7c8f5681
Removing intermediate container 2bcb7c8f5681
 ---> 72fd05de6f73
Successfully built 72fd05de6f73
```

The Golang minimal web server for our testing has the container ID `72fd05de6f73`, which is not friendly to read, so
we can use the `docker tag` command to give it a friendly name:

```bash
$ sudo docker tag 72fd05de6f73 go-web:v0.0.1
```

`docker images` returns the list of locally available images to run. We have one from the test on the Docker installation and
the busybox we have been using to test our networking setup. If a container is not available locally, it is downloaded
from the registry; network load times impact this, so we need to have as small an image
as
possible:

```bash
$ sudo docker images
REPOSITORY      TAG         IMAGE ID          SIZE
<none>          <none>      b508120db6ba      857MB
go-web          v0.0.1      72fd05de6f73      845MB
golang          1.15        05c8f6d2538a      839MB
busybox         latest      6858809bf669      1.23MB
hello-world     latest      bf756fb1ae65      13.3kB
```

`docker ps` shows us the running containers on the host. From our network namespace example, we still have one running
busybox container:

```bash
$ sudo docker ps
CONTAINER ID IMAGE    COMMAND      STATUS          PORTS NAMES
1f3f62ad5e02 busybox  "/bin/sh"    Up 11 minutes   determined_shamir
```

`docker logs` will print out any logs that the container is producing from standard out; currently, our busybox image
is not printing anything out for us to see:

```bash
vagrant@ubuntu-xenial:~$ sudo docker logs 1f3f62ad5e02
vagrant@ubuntu-xenial:~$
```

`docker exec` allows devs and admins to execute commands inside the Docker container. We did this previously while
investigating the Docker networking setups:

```bash
vagrant@ubuntu-xenial:~$ sudo docker exec 1f3f62ad5e02 ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue qlen 1
link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
inet 127.0.0.1/8 scope host lo
valid_lft forever preferred_lft forever
7: eth0@if8: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue
link/ether 02:42:ac:11:00:02 brd ff:ff:ff:ff:ff:ff
inet 172.17.0.2/16 brd 172.17.255.255 scope global eth0
valid_lft forever preferred_lft forever
vagrant@ubuntu-xenial:~$
```

###### Note

You can find more commands for the Docker CLI in the
[documentation](https://oreil.ly/xWkad).

In the previous section, we built the Golang web server as a container. To test the connectivity, we will also
employ the `dnsutils` image used by end-to-end testing for Kubernetes. That image is available from the Kubernetes
project at `gcr.io/kubernetes-e2e-test-images/dnsutils:1.3`.

The image name will copy the Docker images from the Google container registry to our local
Docker filesystem:

```bash
$ sudo docker pull gcr.io/kubernetes-e2e-test-images/dnsutils:1.3
1.3: Pulling from kubernetes-e2e-test-images/dnsutils
5a3ea8efae5d: Pull complete
7b7e943444f2: Pull complete
59c439aa0fa7: Pull complete
3702870470ee: Pull complete
Digest: sha256:b31bcf7ef4420ce7108e7fc10b6c00343b21257c945eec94c21598e72a8f2de0
Status: Downloaded newer image for gcr.io/kubernetes-e2e-test-images/dnsutils:1.3
gcr.io/kubernetes-e2e-test-images/dnsutils:1.3
```

Now that our Golang application can run as a container, we can explore the container networking scenarios.

## Container to Container

Our first walk-through is the communication between two containers running on the same host. We begin by starting the
`dnsutils` image and getting in a shell:

```bash
$ sudo docker run -it gcr.io/kubernetes-e2e-test-images/dnsutils:1.3 /bin/sh
/ #
```

The default Docker network setup gives the `dnsutils` image connectivity to the
internet:

```
/ # ping google.com -c 4
PING google.com (172.217.9.78): 56 data bytes
bytes from 172.217.9.78: seq=0 ttl=114 time=39.677 ms
bytes from 172.217.9.78: seq=1 ttl=114 time=38.180 ms
bytes from 172.217.9.78: seq=2 ttl=114 time=43.150 ms
bytes from 172.217.9.78: seq=3 ttl=114 time=38.140 ms

--- google.com ping statistics ---
packets transmitted, 4 packets received, 0% packet loss
round-trip min/avg/max = 38.140/39.786/43.150 ms
/ #
```

The Golang web server starts with the default Docker bridge; in a separate SSH connection, then our Vagrant host, we
start the Golang web server with the following command:

```bash
$ sudo docker run -it -d -p 80:8080 go-web:v0.0.1
a568732bc191bb1f5a281e30e34ffdeabc624c59d3684b93167456a9a0902369
```

The `-it` options are for interactive processes (such as a shell); we must use `-it` to allocate a
TTY for the container process. `-d` runs the container in detached mode; this allows us to continue to use the
terminal and outputs the full Docker container ID. The `-p` is probably the essential option in terms of the network;
this one creates the port connections between the host and the containers. Our Golang web server runs on port 8080 and
exposes that port on port 80 on the host.

`docker ps` verifies that we now have two containers running: the Go web server container with port 8080 exposed on
the host port 80 and the shell running inside our `dnsutils` container:

```bash
vagrant@ubuntu-xenial:~$ sudo docker ps
CONTAINER ID  IMAGE           COMMAND          CREATED       STATUS
906fd860f84d  go-web:v0.0.1  "/opt/web-server" 4 minutes ago Up 4 minutes
25ded12445df  dnsutils:1.3   "/bin/sh"         6 minutes ago Up 6 minutes

PORTS                   NAMES
0.0.0.0:8080->8080/tcp  frosty_brown
                        brave_zhukovsky
```

Let’s use the `docker inspect` command to get the Docker IP address of the Golang web server container:

```bash
$ sudo docker inspect
-f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
906fd860f84d
172.17.0.2
```

On the `dnsutils` image, we can use the Docker network address of the Golang web server `172.17.0.2` and the
container port `8080`:

```
/ # wget 172.17.0.2:8080
Connecting to 172.17.0.2:8080 (172.17.0.2:8080)
index.html           100% |*******************************************|
                     5   0:00:00 ETA
/ # cat index.html
Hello/ #
```

Each container can reach the other over the `docker0` bridge and the container ports because they are on the same
Docker host and the same network. The Docker host has routes to the container’s IP address to reach the container on
its IP address and port:

```
vagrant@ubuntu-xenial:~$ curl 172.17.0.2:8080
Hello
```

But it does not for the Docker IP address and host port from the `docker run`
command:

```
vagrant@ubuntu-xenial:~$ curl 172.17.0.2:80
curl: (7) Failed to connect to 172.17.0.2 port 80: Connection refused
vagrant@ubuntu-xenial:~$ curl 172.17.0.2:8080
Hello
```

Now for the reverse, using the loopback interface, we demonstrate that the host can reach the web server only on the host
port exposed, 80, not the Docker port, 8080:

```
vagrant@ubuntu-xenial:~$ curl 127.0.0.1:8080
curl: (7) Failed to connect to 127.0.0.1 port 8080: Connection refused
vagrant@ubuntu-xenial:~$ curl 127.0.0.1:80
Hellovagrant@ubuntu-xenial:~$
```

Now back on the `dnsutils`, the same is true: the `dnsutils` image on the Docker network, using the Docker IP address of
the Go web container, can use only the Docker port, 8080, not the exposed host port 80:

```
/ # wget 172.17.0.2:8080 -qO-
Hello/ #
/ # wget 172.17.0.2:80 -qO-
wget: can't connect to remote host (172.17.0.2): Connection refused
```

Now to show it is an entirely separate stack, let’s try the `dnsutils` loopback address and both the Docker port and
the exposed host port:

```
/ # wget localhost:80 -qO-
wget: can't connect to remote host (127.0.0.1): Connection refused
/ # wget localhost:8080 -qO-
wget: can't connect to remote host (127.0.0.1): Connection refused
```

Neither works as expected; the `dnsutils` image has a separate network stack and does not share the Go web server’s
network namespace. Knowing why it does not work is vital in Kubernetes to understand since pods are a collection of
containers that share the same network namespace. Now we will examine how two containers communicate on two separate hosts.

## Container to Container Separate Hosts

Our previous example showed us how a container network runs on a local system, but how can two containers across the
network on separate hosts communicate? In this example, we will deploy containers on separate hosts and
investigate that and how it differs from being on the same host.

Let’s start a second Vagrant Ubuntu host, `host-2`, and SSH into it as we did with our Docker host. We can see that
our IP address is different from the Docker host running our Golang web server:

```
vagrant@host-2:~$ ifconfig enp0s8
enp0s8    Link encap:Ethernet  HWaddr 08:00:27:f9:77:12
          inet addr:192.168.1.23  Bcast:192.168.1.255  Mask:255.255.255.0
          inet6 addr: fe80::a00:27ff:fef9:7712/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:65630 errors:0 dropped:0 overruns:0 frame:0
          TX packets:2967 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:96493210 (96.4 MB)  TX bytes:228989 (228.9 KB)
```

We can access our web server from the Docker host’s IP address, `192.168.1.20`, on port 80 exposed in the
`docker run` command options. Port 80 is exposed on the Docker host but not reachable on container port 8080 with
the host IP address:

```
vagrant@ubuntu-xenial:~$ curl 192.168.1.20:80
Hellovagrant@ubuntu-xenial:~$
vagrant@host-2:~$ curl 192.168.1.20:8080
curl: (7) Failed to connect to 192.168.1.20 port 8080: Connection refused
vagrant@ubuntu-xenial:~$
```

The same is true if `host-2` tries to reach the container on the containers’ IP address, using either the Docker port or
the host port. Remember, Docker uses the private address range, `172.17.0.0/16`:

```
vagrant@host-2:~$ curl 172.17.0.2:8080 -t 5
curl: (7) Failed to connect to 172.17.0.2 port 8080: No route to host
vagrant@host-2:~$ curl 172.17.0.2:80 -t 5
curl: (7) Failed to connect to 172.17.0.2 port 80: No route to host
vagrant@host-2:~$
```

For the host to route to the Docker IP address, it uses an overlay network or some external routing outside Docker.
Routing is also external to Kubernetes; many CNIs help with this issue, and this is explored when looking at deploy
clusters in [Chapter 6](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#kubernetes_and_cloud_networking).

The previous examples used the Docker default network bridge with exposed ports to the hosts. That is how `host-2`
was able to communicate to the Docker container running on the Docker host. This chapter only scratches the surface of
container networks. There are many more abstractions to explore, like ingress and egress traffic to the entire
cluster, service discovery, and routing internal and external to the cluster. Later chapters will continue to
build on these container networking basics.

# Conclusion

In this introduction to container networking, we worked through how containers have evolved to help with application
deployment and advance host efficiency by allowing and segmenting multiple applications on a host. We have walked
through the myriad history of containers with the various projects that have come and gone. Containers are powered
and managed with namespaces and cgroups, features inside the Linux kernel. We walked through the abstractions that
container runtimes maintain for application developers and learned how to deploy them ourselves. Understanding those Linux kernel abstractions is essential to deciding which CNI to deploy and its trade-offs and benefits. Administrators now have a base understanding of how container runtimes manage the Linux networking abstractions.

We have completed the basics of container networking! Our knowledge has expanded from using a simple network stack to
running different unrelated stacks inside our containers. Knowing about namespaces, how ports are exposed, and
communication flow empowers administrators to troubleshoot networking issues quickly and prevent downtime of their
applications running in a Kubernetes cluster. Troubleshooting port issues or testing if a port is open on the host,
on the container, or across the network is a must-have skill for any network engineer and indispensable for developers to
troubleshoot their container issues. Kubernetes is built on these basics and abstracts them for developers.
The next chapter will review how Kubernetes creates those abstractions and integrates them into the Kubernetes networking
model.
