# Chapter 2. First steps with Docker and Kubernetes

### **This chapter covers**

- Creating, running, and sharing a container image with Docker
- Running a single-node Kubernetes cluster locally
- Setting up a Kubernetes cluster on Google Kubernetes Engine
- Setting up and using the `kubectl` command-line client
- Deploying an app on Kubernetes and scaling it horizontally

Before you start learning about Kubernetes concepts in detail, let’s see how to create a simple application, package it into a container image, and run it in a managed Kubernetes cluster (in Google Kubernetes Engine) or in a local single-node cluster. This should give you a slightly better overview of the whole Kubernetes system and will make it easier to follow the next few chapters, where we’ll go over the basic building blocks and concepts in Kubernetes.

## 2.1. Creating, running, and sharing a container image

As you’ve already learned in the previous chapter, running applications in Kubernetes requires them to be packaged into container images. We’ll do a basic introduction to using Docker in case you haven’t used it yet. In the next few sections you’ll

1. Install Docker and run your first “Hello world” container
1. Create a trivial Node.js app that you’ll later deploy in Kubernetes
1. Package the app into a container image so you can then run it as an isolated container
1. Run a container based on the image
1. Push the image to Docker Hub so that anyone anywhere can run it

### 2.1.1. Installing Docker and running a Hello World container

First, you’ll need to install Docker on your Linux machine. If you don’t use Linux, you’ll need to start a Linux virtual machine (VM) and run Docker inside that VM. If you’re using a Mac or Windows and install Docker per instructions, Docker will set up a VM for you and run the Docker daemon inside that VM. The Docker client executable will be available on your host OS, and will communicate with the daemon inside the VM.

To install Docker, follow the instructions at [http://docs.docker.com/engine/installation/](http://docs.docker.com/engine/installation/) for your specific operating system. After completing the installation, you can use the Docker client executable to run various Docker commands. For example, you could try pulling and running an existing image from Docker Hub, the public Docker registry, which contains ready-to-use container images for many well-known software packages. One of them is the `busybox` image, which you’ll use to run a simple `echo "Hello world"` command.

##### Running a Hello World container

If you’re unfamiliar with busybox, it’s a single executable that combines many of the standard UNIX command-line tools, such as `echo`, `ls`, `gzip`, and so on. Instead of the `busybox` image, you could also use any other full-fledged OS container image such as Fedora, Ubuntu, or other similar images, as long as it includes the `echo` executable.

How do you run the `busybox` image? You don’t need to download or install anything. Use the `docker run` command and specify what image to download and run and (optionally) what command to execute, as shown in the following listing.

##### Listing 2.1. Running a Hello world container with Docker

```bash
$ docker run busybox echo "Hello world"
Unable to find image 'busybox:latest' locally
latest: Pulling from docker.io/busybox
9a163e0b8d13: Pull complete
fef924a0204a: Pull complete
Digest: sha256:97473e34e311e6c1b3f61f2a721d038d1e5eef17d98d1353a513007cf46ca6bd
Status: Downloaded newer image for docker.io/busybox:latest
Hello world
```

This doesn’t look that impressive, but when you consider that the whole “app” was downloaded and executed with a single command, without you having to install that app or anything else, you’ll agree it’s awesome. In your case, the app was a single executable (busybox), but it might as well have been an incredibly complex app with many dependencies. The whole process of setting up and running the app would have been exactly the same. What’s also important is that the app was executed inside a container, completely isolated from all the other processes running on your machine.

##### Understanding what happens behind the scenes

[Figure 2.1](/book/kubernetes-in-action/chapter-2/ch02fig01) shows exactly what happened when you performed the `docker run` command. First, Docker checked to see if the `busybox:latest` image was already present on your local machine. It wasn’t, so Docker pulled it from the Docker Hub registry at [http://docker.io](http://docker.io). After the image was downloaded to your machine, Docker created a container from that image and ran the command inside it. The `echo` command printed the text to STDOUT and then the process terminated and the container stopped.

![Figure 2.1. Running echo “Hello world” in a container based on the busybox container image](https://drek4537l1klr.cloudfront.net/luksa/Figures/02fig01_alt.jpg)

##### Running other images

Running other existing container images is much the same as how you ran the `busybox` image. In fact, it’s often even simpler, because you usually don’t need to specify what command to execute, the way you did in the example (`echo "Hello world"`). The command that should be executed is usually baked into the image itself, but you can override it if you want. After searching or browsing through the publicly available images on [http://hub.docker.com](http://hub.docker.com) or another public registry, you tell Docker to run the image like this:

```bash
$ docker run <image>
```

##### Versioning container images

All software packages get updated, so more than a single version of a package usually exists. Docker supports having multiple versions or variants of the same image under the same name. Each variant must have a unique tag. When referring to images without explicitly specifying the tag, Docker will assume you’re referring to the so-called *latest* tag. To run a different version of the image, you may specify the tag along with the image name like this:

```bash
$ docker run <image>:<tag>
```

### 2.1.2. Creating a trivial Node.js app

Now that you have a working Docker setup, you’re going to create an app. You’ll build a trivial Node.js web application and package it into a container image. The application will accept HTTP requests and respond with the hostname of the machine it’s running in. This way, you’ll see that an app running inside a container sees its own hostname and not that of the host machine, even though it’s running on the host like any other process. This will be useful later, when you deploy the app on Kubernetes and scale it out (scale it horizontally; that is, run multiple instances of the app). You’ll see your HTTP requests hitting different instances of the app.

Your app will consist of a single file called app.js with the contents shown in the following listing.

##### Listing 2.2. A simple Node.js app: app.js

```javascript
const http = require('http');
const os = require('os');

console.log("Kubia server starting...");

var handler = function(request, response) {
  console.log("Received request from " + request.connection.remoteAddress);
  response.writeHead(200);
  response.end("You've hit " + os.hostname() + "\n");
};

var www = http.createServer(handler);
www.listen(8080);
```

It should be clear what this code does. It starts up an HTTP server on port 8080. The server responds with an HTTP response status code `200 OK` and the text `"You've hit <hostname>"` to every request. The request handler also logs the client’s IP address to the standard output, which you’ll need later.

---

##### Note

The returned hostname is the server’s actual hostname, not the one the client sends in the HTTP request’s `Host` header.

---

You could now download and install Node.js and test your app directly, but this isn’t necessary, because you’ll use Docker to package the app into a container image and enable it to be run anywhere without having to download or install anything (except Docker, which does need to be installed on the machine you want to run the image on).

### 2.1.3. Creating a Dockerfile for the image

To package your app into an image, you first need to create a file called Dockerfile, which will contain a list of instructions that Docker will perform when building the image. The Dockerfile needs to be in the same directory as the app.js file and should contain the commands shown in the following listing.

##### Listing 2.3. A Dockerfile for building a container image for your app

```dockerfile
FROM node:7
ADD app.js /app.js
ENTRYPOINT ["node", "app.js"]
```

The `FROM` line defines the container image you’ll use as a starting point (the base image you’re building on top of). In your case, you’re using the `node` container image, tag `7`. In the second line, you’re adding your app.js file from your local directory into the root directory in the image, under the same name (app.js). Finally, in the third line, you’re defining what command should be executed when somebody runs the image. In your case, the command is `node app.js`.

---

##### **Choosing a base image**

You may wonder why we chose this specific image as your base. Because your app is a Node.js app, you need your image to contain the `node` binary executable to run the app. You could have used any image that contains that binary, or you could have even used a Linux distro base image such as `fedora` or `ubuntu` and installed Node.js into the container at image build time. But because the `node` image is made specifically for running Node.js apps, and includes everything you need to run your app, you’ll use that as the base image.

---

### 2.1.4. Building the container image

Now that you have your Dockerfile and the app.js file, you have everything you need to build your image. To build it, run the following Docker command:

```bash
$ docker build -t kubia .
```

[Figure 2.2](/book/kubernetes-in-action/chapter-2/ch02fig02) shows what happens during the build process. You’re telling Docker to build an image called `kubia` based on the contents of the current directory (note the dot at the end of the build command). Docker will look for the Dockerfile in the directory and build the image based on the instructions in the file.

![Figure 2.2. Building a new container image from a Dockerfile](https://drek4537l1klr.cloudfront.net/luksa/Figures/02fig02_alt.jpg)

##### Understanding how an image is built

The build process isn’t performed by the Docker client. Instead, the contents of the whole directory are uploaded to the Docker daemon and the image is built there. The client and daemon don’t need to be on the same machine at all. If you’re using Docker on a non-Linux OS, the client is on your host OS, but the daemon runs inside a VM. Because all the files in the build directory are uploaded to the daemon, if it contains many large files and the daemon isn’t running locally, the upload may take longer.

---

##### Tip

Don’t include any unnecessary files in the build directory, because they’ll slow down the build process—especially when the Docker daemon is on a remote machine.

---

During the build process, Docker will first pull the base image (node:7) from the public image repository (Docker Hub), unless the image has already been pulled and is stored on your machine.

##### Understanding image layers

An image isn’t a single, big, binary blob, but is composed of multiple layers, which you may have already noticed when running the busybox example (there were multiple `Pull complete` lines—one for each layer). Different images may share several layers, which makes storing and transferring images much more efficient. For example, if you create multiple images based on the same base image (such as `node:7` in the example), all the layers comprising the base image will be stored only once. Also, when pulling an image, Docker will download each layer individually. Several layers may already be stored on your machine, so Docker will only download those that aren’t.

You may think that each Dockerfile creates only a single new layer, but that’s not the case. When building an image, a new layer is created for each individual command in the Dockerfile. During the build of your image, after pulling all the layers of the base image, Docker will create a new layer on top of them and add the app.js file into it. Then it will create yet another layer that will specify the command that should be executed when the image is run. This last layer will then be tagged as `kubia:latest`. This is shown in [figure 2.3](/book/kubernetes-in-action/chapter-2/ch02fig03), which also shows how a different image called `other:latest` would use the same layers of the Node.js image as your own image does.

![Figure 2.3. Container images are composed of layers that can be shared among different images.](https://drek4537l1klr.cloudfront.net/luksa/Figures/02fig03_alt.jpg)

When the build process completes, you have a new image stored locally. You can see it by telling Docker to list all locally stored images, as shown in the following listing.

##### Listing 2.4. Listing locally stored images

```bash
$ docker images
REPOSITORY   TAG      IMAGE ID           CREATED             VIRTUAL SIZE
kubia        latest   d30ecc7419e7       1 minute ago        637.1 MB
...
```

##### Comparing building images with a Dockerfile vs. manually

Dockerfiles are the usual way of building container images with Docker, but you could also build the image manually by running a container from an existing image, executing commands in the container, exiting the container, and committing the final state as a new image. This is exactly what happens when you build from a Dockerfile, but it’s performed automatically and is repeatable, which allows you to make changes to the Dockerfile and rebuild the image any time, without having to manually retype all the commands again.

### 2.1.5. Running the container image

You can now run your image with the following command:

```bash
$ docker run --name kubia-container -p 8080:8080 -d kubia
```

This tells Docker to run a new container called `kubia-container` from the `kubia` image. The container will be detached from the console (`-d` flag), which means it will run in the background. Port 8080 on the local machine will be mapped to port 8080 inside the container (`-p 8080:8080` option), so you can access the app through http://localhost:8080.

If you’re not running the Docker daemon on your local machine (if you’re using a Mac or Windows, the daemon is running inside a VM), you’ll need to use the hostname or IP of the VM running the daemon instead of localhost. You can look it up through the `DOCKER_HOST` environment variable.

##### Accessing your app

Now try to access your application at http://localhost:8080 (be sure to replace localhost with the hostname or IP of the Docker host if necessary):

```bash
$ curl localhost:8080
You've hit 44d76963e8e1
```

That’s the response from your app. Your tiny application is now running inside a container, isolated from everything else. As you can see, it’s returning `44d76963e8e1` as its hostname, and not the actual hostname of your host machine. The hexadecimal number is the ID of the Docker container.

##### Listing all running containers

Let’s list all running containers in the following listing, so you can examine the list (I’ve edited the output to make it more readable—imagine the last two lines as the continuation of the first two).

##### Listing 2.5. Listing running containers

```bash
$ docker ps
CONTAINER ID  IMAGE         COMMAND               CREATED        ...
44d76963e8e1  kubia:latest  "/bin/sh -c 'node ap  6 minutes ago  ...

...  STATUS              PORTS                    NAMES
...  Up 6 minutes        0.0.0.0:8080->8080/tcp   kubia-container
```

A single container is running. For each container, Docker prints out its ID and name, the image used to run the container, and the command that’s executing inside the container.

##### Getting additional information about a container

The `docker ps` command only shows the most basic information about the containers. To see additional information, you can use `docker inspect`:

```bash
$ docker inspect kubia-container
```

Docker will print out a long JSON containing low-level information about the container.

### 2.1.6. Exploring the inside of a running container

What if you want to see what the environment is like inside the container? Because multiple processes can run inside the same container, you can always run an additional process in it to see what’s inside. You can even run a shell, provided that the shell’s binary executable is available in the image.

##### Running a shell inside an existing container

The Node.js image on which you’ve based your image contains the bash shell, so you can run the shell inside the container like this:

```bash
$ docker exec -it kubia-container bash
```

This will run `bash` inside the existing `kubia-container` container. The `bash` process will have the same Linux namespaces as the main container process. This allows you to explore the container from within and see how Node.js and your app see the system when running inside the container. The `-it` option is shorthand for two options:

- `-i`, which makes sure STDIN is kept open. You need this for entering commands into the shell.
- `-t`, which allocates a pseudo terminal (TTY).

You need both if you want the use the shell like you’re used to. (If you leave out the first one, you can’t type any commands, and if you leave out the second one, the command prompt won’t be displayed and some commands will complain about the `TERM` variable not being set.)

##### Exploring the container from within

Let’s see how to use the shell in the following listing to see the processes running in the container.

##### Listing 2.6. Listing processes from inside a container

```
root@44d76963e8e1:/# ps aux
USER  PID %CPU %MEM    VSZ   RSS TTY STAT START TIME COMMAND
root    1  0.0  0.1 676380 16504 ?   Sl   12:31 0:00 node app.js
root   10  0.0  0.0  20216  1924 ?   Ss   12:31 0:00 bash
root   19  0.0  0.0  17492  1136 ?   R+   12:38 0:00 ps aux
```

You see only three processes. You don’t see any other processes from the host OS.

##### Understanding that processes in a container run in the host operating system

If you now open another terminal and list the processes on the host OS itself, you will, among all other host processes, also see the processes running in the container, as shown in [listing 2.7](/book/kubernetes-in-action/chapter-2/ch02ex07).

---

##### Note

If you’re using a Mac or Windows, you’ll need to log into the VM where the Docker daemon is running to see these processes.

---

##### Listing 2.7. A container’s processes run in the host OS

```bash
$ ps aux | grep app.js
USER  PID %CPU %MEM    VSZ   RSS TTY STAT START TIME COMMAND
root  382  0.0  0.1 676380 16504 ?   Sl   12:31 0:00 node app.js
```

This proves that processes running in the container are running in the host OS. If you have a keen eye, you may have noticed that the processes have different IDs inside the container vs. on the host. The container is using its own PID Linux namespace and has a completely isolated process tree, with its own sequence of numbers.

##### The container’s filesystem is also isolated

Like having an isolated process tree, each container also has an isolated filesystem. Listing the contents of the root directory inside the container will only show the files in the container and will include all the files that are in the image plus any files that are created while the container is running (log files and similar), as shown in the following listing.

##### Listing 2.8. A container has its own complete filesystem

```
root@44d76963e8e1:/# ls /
app.js  boot  etc   lib    media  opt   root  sbin  sys  usr
bin     dev   home  lib64  mnt    proc  run   srv   tmp  var
```

It contains the app.js file and other system directories that are part of the `node:7` base image you’re using. To exit the container, you exit the shell by running the `exit` command and you’ll be returned to your host machine (like logging out of an ssh session, for example).

---

##### Tip

Entering a running container like this is useful when debugging an app running in a container. When something’s wrong, the first thing you’ll want to explore is the actual state of the system your application sees. Keep in mind that an application will not only see its own unique filesystem, but also processes, users, hostname, and network interfaces.

---

### 2.1.7. Stopping and removing a container

To stop your app, you tell Docker to stop the `kubia-container` container:

```bash
$ docker stop kubia-container
```

This will stop the main process running in the container and consequently stop the container, because no other processes are running inside the container. The container itself still exists and you can see it with `docker ps -a`. The `-a` option prints out all the containers, those running and those that have been stopped. To truly remove a container, you need to remove it with the `docker rm` command:

```bash
$ docker rm kubia-container
```

This deletes the container. All its contents are removed and it can’t be started again.

### 2.1.8. Pushing the image to an image registry

The image you’ve built has so far only been available on your local machine. To allow you to run it on any other machine, you need to push the image to an external image registry. For the sake of simplicity, you won’t set up a private image registry and will instead push the image to Docker Hub ([http://hub.docker.com](http://hub.docker.com)), which is one of the publicly available registries. Other widely used such registries are Quay.io and the Google Container Registry.

Before you do that, you need to re-tag your image according to Docker Hub’s rules. Docker Hub will allow you to push an image if the image’s repository name starts with your Docker Hub ID. You create your Docker Hub ID by registering at [http://hub.docker.com](http://hub.docker.com). I’ll use my own ID (`luksa`) in the following examples. Please change every occurrence with your own ID.

##### Tagging an image under an additional tag

Once you know your ID, you’re ready to rename your image, currently tagged as `kubia`, to `luksa/kubia` (replace `luksa` with your own Docker Hub ID):

```bash
$ docker tag kubia luksa/kubia
```

This doesn’t rename the tag; it creates an additional tag for the same image. You can confirm this by listing the images stored on your system with the `docker images` command, as shown in the following listing.

##### Listing 2.9. A container image can have multiple tags

```bash
$ docker images | head
REPOSITORY        TAG      IMAGE ID        CREATED             VIRTUAL SIZE
luksa/kubia       latest   d30ecc7419e7    About an hour ago   654.5 MB
kubia             latest   d30ecc7419e7    About an hour ago   654.5 MB
docker.io/node    7.0      04c0ca2a8dad    2 days ago          654.5 MB
...
```

As you can see, both `kubia` and `luksa/kubia` point to the same image ID, so they’re in fact one single image with two tags.

##### Pushing the image to Docker Hub

Before you can push the image to Docker Hub, you need to log in under your user ID with the `docker login` command. Once you’re logged in, you can finally push the `yourid/kubia` image to Docker Hub like this:

```bash
$ docker push luksa/kubia
```

##### Running the image on a different machine

After the push to Docker Hub is complete, the image will be available to everyone. You can now run the image on any machine running Docker by executing the following command:

```bash
$ docker run -p 8080:8080 -d luksa/kubia
```

It doesn’t get much simpler than that. And the best thing about this is that your application will have the exact same environment every time and everywhere it’s run. If it ran fine on your machine, it should run as well on every other Linux machine. No need to worry about whether the host machine has Node.js installed or not. In fact, even if it does, your app won’t use it, because it will use the one installed inside the image.

## 2.2. Setting up a Kubernetes cluster

Now that you have your app packaged inside a container image and made available through Docker Hub, you can deploy it in a Kubernetes cluster instead of running it in Docker directly. But first, you need to set up the cluster itself.

Setting up a full-fledged, multi-node Kubernetes cluster isn’t a simple task, especially if you’re not well-versed in Linux and networking administration. A proper Kubernetes install spans multiple physical or virtual machines and requires the networking to be set up properly, so that all the containers running inside the Kubernetes cluster can connect to each other through the same flat networking space.

A long list of methods exists for installing a Kubernetes cluster. These methods are described in detail in the documentation at [http://kubernetes.io](http://kubernetes.io). We’re not going to list all of them here, because the list keeps evolving, but Kubernetes can be run on your local development machine, your own organization’s cluster of machines, on cloud providers providing virtual machines (Google Compute Engine, Amazon EC2, Microsoft Azure, and so on), or by using a managed Kubernetes cluster such as Google Kubernetes Engine (previously known as Google Container Engine).

In this chapter, we’ll cover two simple options for getting your hands on a running Kubernetes cluster. You’ll see how to run a single-node Kubernetes cluster on your local machine and how to get access to a hosted cluster running on Google Kubernetes Engine (GKE).

A third option, which covers installing a cluster with the `kubeadm` tool, is explained in [appendix B](/book/kubernetes-in-action/appendix-b/app02). The instructions there show you how to set up a three-node Kubernetes cluster using virtual machines, but I suggest you try it only after reading the first 11 chapters of the book.

Another option is to install Kubernetes on Amazon’s AWS (Amazon Web Services). For this, you can look at the `kops` tool, which is built on top of `kubeadm` mentioned in the previous paragraph, and is available at [http://github.com/kubernetes/kops](http://github.com/kubernetes/kops). It helps you deploy production-grade, highly available Kubernetes clusters on AWS and will eventually support other platforms as well (Google Kubernetes Engine, VMware, vSphere, and so on).

### 2.2.1. Running a local single-node Kubernetes cluster with Minikube

The simplest and quickest path to a fully functioning Kubernetes cluster is by using Minikube. Minikube is a tool that sets up a single-node cluster that’s great for both testing Kubernetes and developing apps locally.

Although we can’t show certain Kubernetes features related to managing apps on multiple nodes, the single-node cluster should be enough for exploring most topics discussed in this book.

##### Installing Minikube

Minikube is a single binary that needs to be downloaded and put onto your path. It’s available for OSX, Linux, and Windows. To install it, the best place to start is to go to the Minikube repository on GitHub ([http://github.com/kubernetes/minikube](http://github.com/kubernetes/minikube)) and follow the instructions there.

For example, on OSX and Linux, Minikube can be downloaded and set up with a single command. For OSX, this is what the command looks like:

```bash
$ curl -Lo minikube https://storage.googleapis.com/minikube/releases/
➥  v0.23.0/minikube-darwin-amd64 && chmod +x minikube && sudo mv minikube
➥  /usr/local/bin/
```

On Linux, you download a different release (replace “darwin” with “linux” in the URL). On Windows, you can download the file manually, rename it to minikube.exe, and put it onto your path. Minikube runs Kubernetes inside a VM run through either VirtualBox or KVM, so you also need to install one of them before you can start the Minikube cluster.

##### Starting a Kubernetes cluster with Minikube

Once you have Minikube installed locally, you can immediately start up the Kubernetes cluster with the command in the following listing.

##### Listing 2.10. Starting a Minikube virtual machine

```bash
$ minikube start
Starting local Kubernetes cluster...
Starting VM...
SSH-ing files into VM...
...
Kubectl is now configured to use the cluster.
```

Starting the cluster takes more than a minute, so don’t interrupt the command before it completes.

##### Installing the Kubernetes client (kubectl)

To interact with Kubernetes, you also need the `kubectl` CLI client. Again, all you need to do is download it and put it on your path. The latest stable release for OSX, for example, can be downloaded and installed with the following command:

```bash
$ curl -LO https://storage.googleapis.com/kubernetes-release/release
➥  /$(curl -s https://storage.googleapis.com/kubernetes-release/release
➥  /stable.txt)/bin/darwin/amd64/kubectl
➥  && chmod +x kubectl
➥  && sudo mv kubectl /usr/local/bin/
```

To download `kubectl` for Linux, replace `darwin` in the URL with `linux`. For Windows, replace it with `windows` and add `.exe` at the end.

---

##### Note

If you’ll be using multiple Kubernetes clusters (for example, both Minikube and GKE), refer to [appendix A](../Text/A.html#app01) for information on how to set up and switch between different `kubectl` contexts.

---

##### Checking to see the cluster is up and kubectl can talk to it

To verify your cluster is working, you can use the `kubectl cluster-info` command shown in the following listing.

##### Listing 2.11. Displaying cluster information

```bash
$ kubectl cluster-info
Kubernetes master is running at https://192.168.99.100:8443
KubeDNS is running at https://192.168.99.100:8443/api/v1/proxy/...
kubernetes-dashboard is running at https://192.168.99.100:8443/api/v1/...
```

This shows the cluster is up. It shows the URLs of the various Kubernetes components, including the API server and the web console.

---

##### Tip

You can run `minikube ssh` to log into the Minikube VM and explore it from the inside. For example, you may want to see what processes are running on the node.

---

### 2.2.2. Using a hosted Kubernetes cluster with Google Kubernetes Engine

If you want to explore a full-fledged multi-node Kubernetes cluster instead, you can use a managed Google Kubernetes Engine (GKE) cluster. This way, you don’t need to manually set up all the cluster nodes and networking, which is usually too much for someone making their first steps with Kubernetes. Using a managed solution such as GKE makes sure you don’t end up with a misconfigured, non-working, or partially working cluster.

##### Setting up a Google Cloud project and downloading the necessary client binaries

Before you can set up a new Kubernetes cluster, you need to set up your GKE environment. Because the process may change, I’m not listing the exact instructions here. To get started, please follow the instructions at [https://cloud.google.com/container-engine/docs/before-you-begin](https://cloud.google.com/container-engine/docs/before-you-begin).

Roughly, the whole procedure includes

1. Signing up for a Google account, in the unlikely case you don’t have one already.
1. Creating a project in the Google Cloud Platform Console.
1. Enabling billing. This does require your credit card info, but Google provides a 12-month free trial. And they’re nice enough to not start charging automatically after the free trial is over.)
1. Enabling the Kubernetes Engine API.
1. Downloading and installing Google Cloud SDK. (This includes the *gcloud* command-line tool, which you’ll need to create a Kubernetes cluster.)
1. Installing the `kubectl` command-line tool with `gcloud components install kubectl`.

---

##### Note

Certain operations (the one in step 2, for example) may take a few minutes to complete, so relax and grab a coffee in the meantime.

---

##### Creating a Kubernetes cluster with three nodes

After completing the installation, you can create a Kubernetes cluster with three worker nodes using the command shown in the following listing.

##### Listing 2.12. Creating a three-node cluster in GKE

```bash
$ gcloud container clusters create kubia --num-nodes 3
➥  --machine-type f1-micro
Creating cluster kubia...done.
Created [https://container.googleapis.com/v1/projects/kubia1-
     1227/zones/europe-west1-d/clusters/kubia].
kubeconfig entry generated for kubia.
NAME   ZONE   MST_VER MASTER_IP     TYPE     NODE_VER NUM_NODES STATUS
kubia  eu-w1d 1.5.3   104.155.92.30 f1-micro 1.5.3    3         RUNNING
```

You should now have a running Kubernetes cluster with three worker nodes as shown in [figure 2.4](/book/kubernetes-in-action/chapter-2/ch02fig04). You’re using three nodes to help better demonstrate features that apply to multiple nodes. You can use a smaller number of nodes, if you want.

![Figure 2.4. How you’re interacting with your three-node Kubernetes cluster](https://drek4537l1klr.cloudfront.net/luksa/Figures/02fig04_alt.jpg)

##### Getting an overview of your cluster

To give you a basic idea of what your cluster looks like and how to interact with it, see [figure 2.4](/book/kubernetes-in-action/chapter-2/ch02fig04). Each node runs Docker, the Kubelet and the kube-proxy. You’ll interact with the cluster through the `kubectl` command line client, which issues REST requests to the Kubernetes API server running on the master node.

##### Checking if the cluster is up by listing cluster nodes

You’ll use the `kubectl` command now to list all the nodes in your cluster, as shown in the following listing.

##### Listing 2.13. Listing cluster nodes with `kubectl`

```bash
$ kubectl get nodes
NAME                      STATUS  AGE  VERSION
gke-kubia-85f6-node-0rrx  Ready   1m    v1.5.3
gke-kubia-85f6-node-heo1  Ready   1m    v1.5.3
gke-kubia-85f6-node-vs9f  Ready   1m    v1.5.3
```

The `kubectl get` command can list all kinds of Kubernetes objects. You’ll use it constantly, but it usually shows only the most basic information for the listed objects.

---

##### Tip

You can log into one of the nodes with `gcloud compute ssh <node-name>` to explore what’s running on the node.

---

##### Retrieving additional details of an object

To see more detailed information about an object, you can use the `kubectl describe` command, which shows much more:

```bash
$ kubectl describe node gke-kubia-85f6-node-0rrx
```

I’m omitting the actual output of the `describe` command, because it’s fairly wide and would be completely unreadable here in the book. The output shows the node’s status, its CPU and memory data, system information, containers running on the node, and much more.

In the previous `kubectl describe` example, you specified the name of the node explicitly, but you could also have performed a simple `kubectl describe node` without typing the node’s name and it would print out a detailed description of all the nodes.

---

##### Tip

Running the `describe` and `get` commands without specifying the name of the object comes in handy when only one object of a given type exists, so you don’t waste time typing or copy/pasting the object’s name.

---

While we’re talking about reducing keystrokes, let me give you additional advice on how to make working with `kubectl` much easier, before we move on to running your first app in Kubernetes.

### 2.2.3. Setting up an alias and command-line completion for kubectl

You’ll use `kubectl` often. You’ll soon realize that having to type the full command every time is a real pain. Before you continue, take a minute to make your life easier by setting up an alias and tab completion for `kubectl`.

##### Creating an alias

Throughout the book, I’ll always be using the full name of the `kubectl` executable, but you may want to add a short alias such as `k`, so you won’t have to type `kubectl` every time. If you haven’t used aliases yet, here’s how you define one. Add the following line to your `~/.bashrc` or equivalent file:

```
alias k=kubectl
```

---

##### Note

You may already have the `k` executable if you used `gcloud` to set up the cluster.

---

##### Configuring tab completion for kubectl

Even with a short alias such as `k`, you’ll still need to type way more than you’d like. Luckily, the `kubectl` command can also output shell completion code for both the bash and zsh shell. It doesn’t enable tab completion of only command names, but also of the actual object names. For example, instead of having to write the whole node name in the previous example, all you’d need to type is

```bash
$ kubectl desc<TAB> no<TAB> gke-ku<TAB>
```

To enable tab completion in bash, you’ll first need to install a package called `bash-completion` and then run the following command (you’ll probably also want to add it to `~/.bashrc` or equivalent):

```bash
$ source <(kubectl completion bash)
```

But there’s one caveat. When you run the preceding command, tab completion will only work when you use the full `kubectl` name (it won’t work when you use the `k` alias). To fix this, you need to transform the output of the `kubectl completion` command a bit:

```bash
$ source <(kubectl completion bash | sed s/kubectl/k/g)
```

---

##### Note

Unfortunately, as I’m writing this, shell completion doesn’t work for aliases on MacOS. You’ll have to use the full `kubectl` command name if you want completion to work.

---

Now you’re all set to start interacting with your cluster without having to type too much. You can finally run your first app on Kubernetes.

## 2.3. Running your first app on Kubernetes

Because this may be your first time, you’ll use the simplest possible way of running an app on Kubernetes. Usually, you’d prepare a JSON or YAML manifest, containing a description of all the components you want to deploy, but because we haven’t talked about the types of components you can create in Kubernetes yet, you’ll use a simple one-line command to get something running.

### 2.3.1. Deploying your Node.js app

The simplest way to deploy your app is to use the `kubectl run` command, which will create all the necessary components without having to deal with JSON or YAML. This way, we don’t need to dive into the structure of each object yet. Try to run the image you created and pushed to Docker Hub earlier. Here’s how to run it in Kubernetes:

```bash
$ kubectl run kubia --image=luksa/kubia --port=8080 --generator=run/v1
replicationcontroller "kubia" created
```

The `--image=luksa/kubia` part obviously specifies the container image you want to run, and the `--port=8080` option tells Kubernetes that your app is listening on port 8080. The last flag (`--generator`) does require an explanation, though. Usually, you won’t use it, but you’re using it here so Kubernetes creates a *ReplicationController* instead of a *Deployment*. You’ll learn what ReplicationControllers are later in the chapter, but we won’t talk about Deployments until [chapter 9](/book/kubernetes-in-action/chapter-9/ch09). That’s why I don’t want `kubectl` to create a Deployment yet.

As the previous command’s output shows, a ReplicationController called `kubia` has been created. As already mentioned, we’ll see what that is later in the chapter. For now, let’s start from the bottom and focus on the container you created (you can assume a container has been created, because you specified a container image in the `run` command).

##### Introducing Pods

You may be wondering if you can see your container in a list showing all the running containers. Maybe something such as `kubectl get containers`? Well, that’s not exactly how Kubernetes works. It doesn’t deal with individual containers directly. Instead, it uses the concept of multiple co-located containers. This group of containers is called a Pod.

A pod is a group of one or more tightly related containers that will always run together on the same worker node and in the same Linux namespace(s). Each pod is like a separate logical machine with its own IP, hostname, processes, and so on, running a single application. The application can be a single process, running in a single container, or it can be a main application process and additional supporting processes, each running in its own container. All the containers in a pod will appear to be running on the same logical machine, whereas containers in other pods, even if they’re running on the same worker node, will appear to be running on a different one.

To better understand the relationship between containers, pods, and nodes, examine [figure 2.5](/book/kubernetes-in-action/chapter-2/ch02fig05). As you can see, each pod has its own IP and contains one or more containers, each running an application process. Pods are spread out across different worker nodes.

![Figure 2.5. The relationship between containers, pods, and physical worker nodes](https://drek4537l1klr.cloudfront.net/luksa/Figures/02fig05_alt.jpg)

##### Listing pods

Because you can’t list individual containers, since they’re not standalone Kubernetes objects, can you list pods instead? Yes, you can. Let’s see how to tell `kubectl` to list pods in the following listing.

##### Listing 2.14. Listing pods

```bash
$ kubectl get pods
NAME          READY     STATUS    RESTARTS   AGE
kubia-4jfyf   0/1       Pending   0          1m
```

This is your pod. Its status is still `Pending` and the pod’s single container is shown as not ready yet (this is what the `0/1` in the `READY` column means). The reason why the pod isn’t running yet is because the worker node the pod has been assigned to is downloading the container image before it can run it. When the download is finished, the pod’s container will be created and then the pod will transition to the `Running` state, as shown in the following listing.

##### Listing 2.15. Listing pods again to see if the pod’s status has changed

```bash
$ kubectl get pods
NAME          READY     STATUS    RESTARTS   AGE
kubia-4jfyf   1/1       Running   0          5m
```

To see more information about the pod, you can also use the `kubectl describe pod` command, like you did earlier for one of the worker nodes. If the pod stays stuck in the Pending status, it might be that Kubernetes can’t pull the image from the registry. If you’re using your own image, make sure it’s marked as public on Docker Hub. To make sure the image can be pulled successfully, try pulling the image manually with the `docker pull` command on another machine.

##### Understanding what happened behind the scenes

To help you visualize what transpired, look at [figure 2.6](/book/kubernetes-in-action/chapter-2/ch02fig06). It shows both steps you had to perform to get a container image running inside Kubernetes. First, you built the image and pushed it to Docker Hub. This was necessary because building the image on your local machine only makes it available on your local machine, but you needed to make it accessible to the Docker daemons running on your worker nodes.

![Figure 2.6. Running the luksa/kubia container image in Kubernetes](https://drek4537l1klr.cloudfront.net/luksa/Figures/02fig06_alt.jpg)

When you ran the `kubectl` command, it created a new ReplicationController object in the cluster by sending a REST HTTP request to the Kubernetes API server. The ReplicationController then created a new pod, which was then scheduled to one of the worker nodes by the Scheduler. The Kubelet on that node saw that the pod was scheduled to it and instructed Docker to pull the specified image from the registry because the image wasn’t available locally. After downloading the image, Docker created and ran the container.

The other two nodes are displayed to show context. They didn’t play any role in the process, because the pod wasn’t scheduled to them.

---

##### Definition

The term scheduling means assigning the pod to a node. The pod is run immediately, not at a time in the future as the term might lead you to believe.

---

### 2.3.2. Accessing your web application

With your pod running, how do you access it? We mentioned that each pod gets its own IP address, but this address is internal to the cluster and isn’t accessible from outside of it. To make the pod accessible from the outside, you’ll expose it through a Service object. You’ll create a special service of type `LoadBalancer`, because if you create a regular service (a `ClusterIP` service), like the pod, it would also only be accessible from inside the cluster. By creating a `LoadBalancer`-type service, an external load balancer will be created and you can connect to the pod through the load balancer’s public IP.

##### Creating a Service object

To create the service, you’ll tell Kubernetes to expose the ReplicationController you created earlier:

```bash
$ kubectl expose rc kubia --type=LoadBalancer --name kubia-http
service "kubia-http" exposed
```

---

##### Note

We’re using the abbreviation `rc` instead of `replicationcontroller`. Most resource types have an abbreviation like this so you don’t have to type the full name (for example, `po` for `pods`, `svc` for `services`, and so on).

---

##### Listing services

The `expose` command’s output mentions a service called `kubia-http`. Services are objects like Pods and Nodes, so you can see the newly created Service object by running the `kubectl get services` command, as shown in the following listing.

##### Listing 2.16. Listing Services

```bash
$ kubectl get services
NAME         CLUSTER-IP     EXTERNAL-IP   PORT(S)         AGE
kubernetes   10.3.240.1     <none>        443/TCP         34m
kubia-http   10.3.246.185   <pending>     8080:31348/TCP  4s
```

The list shows two services. Ignore the `kubernetes` service for now and take a close look at the `kubia-http` service you created. It doesn’t have an external IP address yet, because it takes time for the load balancer to be created by the cloud infrastructure Kubernetes is running on. Once the load balancer is up, the external IP address of the service should be displayed. Let’s wait a while and list the services again, as shown in the following listing.

##### Listing 2.17. Listing services again to see if an external IP has been assigned

```bash
$ kubectl get svc
NAME         CLUSTER-IP     EXTERNAL-IP   PORT(S)         AGE
kubernetes   10.3.240.1     <none>        443/TCP         35m
kubia-http   10.3.246.185   104.155.74.57 8080:31348/TCP  1m
```

Aha, there’s the external IP. Your application is now accessible at http://104.155.74.57:8080 from anywhere in the world.

---

##### Note

Minikube doesn’t support `LoadBalancer` services, so the service will never get an external IP. But you can access the service anyway through its external port. How to do that is described in the next section’s tip.

---

##### Accessing your service through its external IP

You can now send requests to your pod through the service’s external IP and port:

```bash
$ curl 104.155.74.57:8080
You've hit kubia-4jfyf
```

Woohoo! Your app is now running somewhere in your three-node Kubernetes cluster (or a single-node cluster if you’re using Minikube). If you don’t count the steps required to set up the whole cluster, all it took was two simple commands to get your app running and to make it accessible to users across the world.

---

##### Tip

When using Minikube, you can get the IP and port through which you can access the service by running `minikube service kubia-http`.

---

If you look closely, you’ll see that the app is reporting the name of the pod as its hostname. As already mentioned, each pod behaves like a separate independent machine with its own IP address and hostname. Even though the application is running in the worker node’s operating system, to the app it appears as though it’s running on a separate machine dedicated to the app itself—no other processes are running alongside it.

### 2.3.3. The logical parts of your system

Until now, I’ve mostly explained the actual physical components of your system. You have three worker nodes, which are VMs running Docker and the Kubelet, and you have a master node that controls the whole system. Honestly, we don’t know if a single master node is hosting all the individual components of the Kubernetes Control Plane or if they’re split across multiple nodes. It doesn’t really matter, because you’re only interacting with the API server, which is accessible at a single endpoint.

Besides this physical view of the system, there’s also a separate, logical view of it. I’ve already mentioned Pods, ReplicationControllers, and Services. All of them will be explained in the next few chapters, but let’s quickly look at how they fit together and what roles they play in your little setup.

##### Understanding how the ReplicationController, the Pod, and the Ser- rvice fit together

As I’ve already explained, you’re not creating and working with containers directly. Instead, the basic building block in Kubernetes is the pod. But, you didn’t really create any pods either, at least not directly. By running the `kubectl run` command you created a ReplicationController, and this ReplicationController is what created the actual Pod object. To make that pod accessible from outside the cluster, you told Kubernetes to expose all the pods managed by that ReplicationController as a single Service. A rough picture of all three elements is presented in [figure 2.7](/book/kubernetes-in-action/chapter-2/ch02fig07).

![Figure 2.7. Your system consists of a ReplicationController, a Pod, and a Service.](https://drek4537l1klr.cloudfront.net/luksa/Figures/02fig07_alt.jpg)

##### Understanding the pod and its container

The main and most important component in your system is the pod. It contains only a single container, but generally a pod can contain as many containers as you want. Inside the container is your Node.js process, which is bound to port 8080 and is waiting for HTTP requests. The pod has its own unique private IP address and hostname.

##### Understanding the role of the ReplicationController

The next component is the `kubia` ReplicationController. It makes sure there’s always exactly one instance of your pod running. Generally, ReplicationControllers are used to replicate pods (that is, create multiple copies of a pod) and keep them running. In your case, you didn’t specify how many pod replicas you want, so the Replication-Controller created a single one. If your pod were to disappear for any reason, the Replication-Controller would create a new pod to replace the missing one.

##### Understanding why you need a service

The third component of your system is the `kubia-http` service. To understand why you need services, you need to learn a key detail about pods. They’re ephemeral. A pod may disappear at any time—because the node it’s running on has failed, because someone deleted the pod, or because the pod was evicted from an otherwise healthy node. When any of those occurs, a missing pod is replaced with a new one by the Replication-Controller, as described previously. This new pod gets a different IP address from the pod it’s replacing. This is where services come in—to solve the problem of ever-changing pod IP addresses, as well as exposing multiple pods at a single constant IP and port pair.

When a service is created, it gets a static IP, which never changes during the lifetime of the service. Instead of connecting to pods directly, clients should connect to the service through its constant IP address. The service makes sure one of the pods receives the connection, regardless of where the pod is currently running (and what its IP address is).

Services represent a static location for a group of one or more pods that all provide the same service. Requests coming to the IP and port of the service will be forwarded to the IP and port of one of the pods belonging to the service at that moment.

### 2.3.4. Horizontally scaling the application

You now have a running application, monitored and kept running by a ReplicationController and exposed to the world through a service. Now let’s make additional magic happen.

One of the main benefits of using Kubernetes is the simplicity with which you can scale your deployments. Let’s see how easy it is to scale up the number of pods. You’ll increase the number of running instances to three.

Your pod is managed by a ReplicationController. Let’s see it with the `kubectl get` command:

```bash
$ kubectl get replicationcontrollers
NAME        DESIRED    CURRENT   AGE
kubia       1          1         17m
```

---

##### **Listing all the resource types with kubectl get**

You’ve been using the same basic `kubectl get` command to list things in your cluster. You’ve used this command to list Node, Pod, Service and Replication-Controller objects. You can get a list of all the possible object types by invoking `kubectl get` without specifying the type. You can then use those types with various `kubectl` commands such as `get`, `describe`, and so on. The list also shows the abbreviations I mentioned earlier.

---

The list shows a single ReplicationController called `kubia`. The `DESIRED` column shows the number of pod replicas you want the ReplicationController to keep, whereas the `CURRENT` column shows the actual number of pods currently running. In your case, you wanted to have a single replica of the pod running, and exactly one replica is currently running.

##### Increasing the desired replica count

To scale up the number of replicas of your pod, you need to change the desired replica count on the ReplicationController like this:

```bash
$ kubectl scale rc kubia --replicas=3
replicationcontroller "kubia" scaled
```

You’ve now told Kubernetes to make sure three instances of your pod are always running. Notice that you didn’t instruct Kubernetes what action to take. You didn’t tell it to add two more pods. You only set the new desired number of instances and let Kubernetes determine what actions it needs to take to achieve the requested state.

This is one of the most fundamental Kubernetes principles. Instead of telling Kubernetes exactly what actions it should perform, you’re only declaratively changing the desired state of the system and letting Kubernetes examine the current actual state and reconcile it with the desired state. This is true across all of Kubernetes.

##### Seeing the results of the scale-out

Back to your replica count increase. Let’s list the ReplicationControllers again to see the updated replica count:

```bash
$ kubectl get rc
NAME        DESIRED    CURRENT   READY   AGE
kubia       3          3         2       17m
```

Because the actual number of pods has already been increased to three (as evident from the `CURRENT` column), listing all the pods should now show three pods instead of one:

```bash
$ kubectl get pods
NAME          READY     STATUS    RESTARTS   AGE
kubia-hczji   1/1       Running   0          7s
kubia-iq9y6   0/1       Pending   0          7s
kubia-4jfyf   1/1       Running   0          18m
```

As you can see, three pods exist instead of one. Two are already running, one is still pending, but should be ready in a few moments, as soon as the container image is downloaded and the container is started.

As you can see, scaling an application is incredibly simple. Once your app is running in production and a need to scale the app arises, you can add additional instances with a single command without having to install and run additional copies manually.

Keep in mind that the app itself needs to support being scaled horizontally. Kubernetes doesn’t magically make your app scalable; it only makes it trivial to scale the app up or down.

##### Seeing requests hit all three pods when hitting the service

Because you now have multiple instances of your app running, let’s see what happens if you hit the service URL again. Will you always hit the same app instance or not?

```bash
$ curl 104.155.74.57:8080
You've hit kubia-hczji
$ curl 104.155.74.57:8080
You've hit kubia-iq9y6
$ curl 104.155.74.57:8080
You've hit kubia-iq9y6
$ curl 104.155.74.57:8080
You've hit kubia-4jfyf
```

Requests are hitting different pods randomly. This is what services in Kubernetes do when more than one pod instance backs them. They act as a load balancer standing in front of multiple pods. When there’s only one pod, services provide a static address for the single pod. Whether a service is backed by a single pod or a group of pods, those pods come and go as they’re moved around the cluster, which means their IP addresses change, but the service is always there at the same address. This makes it easy for clients to connect to the pods, regardless of how many exist and how often they change location.

##### Visualizing the new state of your system

Let’s visualize your system again to see what’s changed from before. [Figure 2.8](/book/kubernetes-in-action/chapter-2/ch02fig08) shows the new state of your system. You still have a single service and a single Replication-Controller, but you now have three instances of your pod, all managed by the ReplicationController. The service no longer sends all requests to a single pod, but spreads them across all three pods as shown in the experiment with `curl` in the previous section.

![Figure 2.8. Three instances of a pod managed by the same ReplicationController and exposed through a single service IP and port.](https://drek4537l1klr.cloudfront.net/luksa/Figures/02fig08_alt.jpg)

As an exercise, you can now try spinning up additional instances by increasing the ReplicationController’s replica count even further and then scaling back down.

### 2.3.5. Examining what nodes your app is running on

You may be wondering what nodes your pods have been scheduled to. In the Kubernetes world, what node a pod is running on isn’t that important, as long as it gets scheduled to a node that can provide the CPU and memory the pod needs to run properly.

Regardless of the node they’re scheduled to, all the apps running inside containers have the same type of OS environment. Each pod has its own IP and can talk to any other pod, regardless of whether that other pod is also running on the same node or on a different one. Each pod is provided with the requested amount of computational resources, so whether those resources are provided by one node or another doesn’t make any difference.

##### Displaying the pod IP and the pod’s node when listing pods

If you’ve been paying close attention, you probably noticed that the `kubectl get pods` command doesn’t even show any information about the nodes the pods are scheduled to. This is because it’s usually not an important piece of information.

But you can request additional columns to display using the `-o wide` option. When listing pods, this option shows the pod’s IP and the node the pod is running on:

```bash
$ kubectl get pods -o wide
NAME          READY   STATUS    RESTARTS   AGE   IP         NODE
kubia-hczji   1/1     Running   0          7s    10.1.0.2   gke-kubia-85...
```

##### Inspecting other details of a pod with kubectl describe

You can also see the node by using the `kubectl describe` command, which shows many other details of the pod, as shown in the following listing.

##### Listing 2.18. Describing a pod with `kubectl describe`

```bash
$ kubectl describe pod kubia-hczji
Name:        kubia-hczji
Namespace:   default
Node:        gke-kubia-85f6-node-vs9f/10.132.0.3       #1
Start Time:  Fri, 29 Apr 2016 14:12:33 +0200
Labels:      run=kubia
Status:      Running
IP:          10.1.0.2
Controllers: ReplicationController/kubia
Containers:  ...
Conditions:
  Type       Status
  Ready      True
Volumes: ...
Events: ...
```

This shows, among other things, the node the pod has been scheduled to, the time when it was started, the image(s) it’s running, and other useful information.

### 2.3.6. Introducing the Kubernetes dashboard

Before we wrap up this initial hands-on chapter, let’s look at another way of exploring your Kubernetes cluster.

Up to now, you’ve only been using the `kubectl` command-line tool. If you’re more into graphical web user interfaces, you’ll be glad to hear that Kubernetes also comes with a nice (but still evolving) web dashboard.

The dashboard allows you to list all the Pods, ReplicationControllers, Services, and other objects deployed in your cluster, as well as to create, modify, and delete them. [Figure 2.9](/book/kubernetes-in-action/chapter-2/ch02fig09) shows the dashboard.

![Figure 2.9. Screenshot of the Kubernetes web-based dashboard](https://drek4537l1klr.cloudfront.net/luksa/Figures/02fig09_alt.jpg)

Although you won’t use the dashboard in this book, you can open it up any time to quickly see a graphical view of what’s deployed in your cluster after you create or modify objects through `kubectl`.

##### Accessing the dashboard when running Kubernetes in GKE

If you’re using Google Kubernetes Engine, you can find out the URL of the dashboard through the `kubectl cluster-info` command, which we already introduced:

```bash
$ kubectl cluster-info | grep dashboard
kubernetes-dashboard is running at https://104.155.108.191/api/v1/proxy/
➥  namespaces/kube-system/services/kubernetes-dashboard
```

If you open this URL in a browser, you’re presented with a username and password prompt. You’ll find the username and password by running the following command:

```bash
$ gcloud container clusters describe kubia | grep -E "(username|password):"
  password: 32nENgreEJ632A12                                               #1
  username: admin                                                          #1
```

##### Accessing the dashboard when using Minikube

To open the dashboard in your browser when using Minikube to run your Kubernetes cluster, run the following command:

```bash
$ minikube dashboard
```

The dashboard will open in your default browser. Unlike with GKE, you won’t need to enter any credentials to access it.

## 2.4. Summary

Hopefully, this initial hands-on chapter has shown you that Kubernetes isn’t a complicated platform to use, and you’re ready to learn in depth about all the things it can provide. After reading this chapter, you should now know how to

- Pull and run any publicly available container image
- Package your apps into container images and make them available to anyone by pushing the images to a remote image registry
- Enter a running container and inspect its environment
- Set up a multi-node Kubernetes cluster on Google Kubernetes Engine
- Configure an alias and tab completion for the `kubectl` command-line tool
- List and inspect Nodes, Pods, Services, and ReplicationControllers in a Kubernetes cluster
- Run a container in Kubernetes and make it accessible from outside the cluster
- Have a basic sense of how Pods, ReplicationControllers, and Services relate to one another
- Scale an app horizontally by changing the ReplicationController’s replica count
- Access the web-based Kubernetes dashboard on both Minikube and GKE
