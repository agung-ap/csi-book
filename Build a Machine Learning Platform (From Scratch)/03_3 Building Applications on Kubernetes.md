# 3 Building Applications on Kubernetes

### This chapter covers

- Setting up the DevOps side of the Machine Learning Platform
- Dev Ops tooling for containerizing applications
- Using a container orchestrator for deploying the applications
- Automating container builds and deployment
- Enabling monitoring of deployments to keep track of application performance

Setting up or interacting with a machine learning platform is one of a machine learning engineer's primary duties. Machine learning platforms may be of any shape or size depending on the organization where they are implemented, but most platforms share a large number of characteristics. The components of an ML platform have been thoroughly discussed in chapters one and two; in the next three chapters, we will concentrate on how to lay the foundation for such a platform.

If you have no prior exposure to this ubiquitous technology, you're in luck! We will start with the basics and gradually build up your knowledge. By the end of this chapter, you will be able to understand and use Docker, Kubernetes, and other DevOps tools to deploy and manage your applications.

The deployment and servicing of models is one of the most important aspects of a machine learning platform. It provides methods for deploying trained models into real-world settings where they may make real-time predictions based on new incoming data. Containerization technologies are frequently used to achieve this, allowing models to be encased into separate environments for consistent and scalable deployment.

These containers that hold our application then need to be deployed in various environments which can include an on-premise cluster or on the cloud. We have to ensure that our machine learning containers have enough resources allocated to them to perform optimally. They must have the ability to scale up in the face of increasing load. If any of the containers fail due to underlying infrastructure, they need to be replaced by another running container. All of these should be automated and monitored, and any issues encountered by the application should be proactively identified and mitigated before they escalate.

To perform all the above we need to familiarize ourselves with some common industry tooling. Containerization is made possible by the Docker platform. It allows us to package an application and its dependencies, including libraries and runtime, into a single container. We then proceed to deploy this container in Kubernetes which takes care of resource management, scaling, and spawning new containers when required. These deployments have to be automated using Continuous Integration (CI) and Continuous Deployment (CD) tooling for which we use Gitlab CI and Argo CD. Once deployed the applications have to be monitored by a monitoring system that keeps track of application-specific metrics and also provides a UI to visualize these metrics. For the monitoring system we use Prometheus and Grafana is the dashboard used to visualize the metrics.

There are multiple alternatives to these tools, some of which may be better suited for your organization. The tools themselves are a means to an end and as long as the end goal of having an automated ML platform is met, one is free to use any tools. In this chapter, we will explore more on the DevOps tooling which helps us in automation and monitoring. In chapter four and five we will expand to MLOps tooling such as feature store, machine learning pipelines, experiment tracking, and drift monitoring.

We will be working on a single application throughout this chapter, the code for which is available the book's code repository.. This Fast API application exposes a single endpoint that displays a random joke. We will start by containerizing the application and then deploying it to a container orchestrator platform. We will then focus on automation and monitoring.

![](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/03__image001.png)

Let us start with containerization.

## 3.1 Docker

Say we are building an object detection application on our local workstation, and our application is dependent on Python libraries like TensorFlow, Numpy, and OpenCV and also other libraries such as CMake. When we have to deploy this application on the cloud, we need to ensure that these dependencies are installed there too, a problem that is compounded when our production environment Linux distribution is different from our local distribution. Docker helps in solving this problem by ensuring that the container we build locally runs equally well on our production environment.

Docker is a tool that helps us in application delivery. It does this through means of containerization. Containerization is the process in which an application is packaged up along with its dependencies, ensuring that it runs in almost any computing environment. Think of a container as a literal container that holds your source code and its dependencies, Docker service provides us with a way in which this container can be run.

Let's discuss containerization using the analogy of actual shipping containers. Imagine yourself as the logistics manager in charge of transporting various goods to various countries around the globe. Each item must be delivered securely, be transportable conveniently, and be able to be loaded and unloaded from various modes of transportation (trucks, ships, trains) quickly.

Customary Shipping (No Docker):

- Each product comes in a distinctive package with particular dimensions and handling instructions.
- Transporting several goods gets complicated and necessitates individual planning for each one.
- Because different products have varied shapes and sizes, loading and unloading them onto various modes of transportation requires time and effort.
- When products don't work well with the available transportation modes, compatibility problems arise.

Docker Shipping (With Docker):

- Instead of using different packaging for each product, you place each product inside a standardized shipping container.
- Each container is a self-contained unit that holds the product and any necessary handling instructions.
- Containers have a consistent size and shape, making them easy to load onto trucks, ships, and trains without modifications.
- You can transport a variety of products by placing them in different containers, ensuring they fit seamlessly.
- Loading and unloading containers are streamlined and efficient since they all follow the same standard.

In this analogy:

Products represent different applications or services.

Packaging and Handling Instructions represent the dependencies, libraries, and configurations needed for each application.

Shipping Containers represent Docker containers that encapsulate an application along with its dependencies.

Just like Docker containers, standardized shipping containers simplify logistics, ensure products are well-encapsulated, and make transportation across different modes and locations seamless. Similarly, Docker containers package applications along with their dependencies in a consistent and isolated manner, making them easily deployable and manageable across various environments.

### 3.1.1 Write application code

Let us build a docker container for a Fast API application. FastAPI is web framework for building APIs with Python. It can be particularly useful in the context of machine learning for building APIs that serve machine learning models. For now we will use it to deploy an application which displays a random joke. All our source code lies in a simple main.py and the requirements are listed in requirements.txt. The application directory structure looks like this, the code for main.py is specified in Listing 3.1.

```
├── requirements.txt
├── main.py
```

##### Listing 3.1 Fast API app which prints a random joke

```
from fastapi import FastAPI
import pyjokes
app = FastAPI()
@app.get("/")
async def root():
    random_joke = get_joke(“en”,”neutral”)
    return {"random_joke": random_joke}
```

We can run this locally by running this command on our terminal

```
uvicorn main:app --host 0.0.0.0 --port 8083
```

If we curl the endpoint we get

```
curl localhost:8083
{"random_joke":"If you play a Windows CD backwards, you'll hear satanic chanting ... worse still, if you play it forwards, it installs Windows."}
```

Now that our application works as expected, we wish to containerize it. To build a docker container, we first need to install Docker desktop ([https://docs.docker.com/desktop/install/linux-install/](https://docs.docker.com/desktop/install/linux-install/)). For most platforms, installation is achieved by following the GUI installer.

### 3.1.2 Write Dockerfile

The next step in *dockerization* is writing a Dockerfile. Think of a Dockerfile as a list of instructions to build and deploy your application. From our shipping analogy, the container manifest here would refer to the Dockerfile. An example Dockerfile for our Fast API application (and most basic Python applications) would look something like this (Listing 3.2)

Every Docker file starts with a FROM which is a reference to a base image. Think of it as a foundation on which we add our application-specific *layers*. Think of a layer as each incremental instruction that we add in a Dockerfile. In our case, we are creating a directory called app which is our working directory by using the WORKDIR command. We are then updating index files and installing the necessary packages by using the RUN command. The RUN command is used to run basic command line instructions. This is followed by copying and installing our Python requirements from which COPY is used. We then copy our application files into the working directory. We then specify a build argument through means of ARG. These arguments are passed during build time and in our case, we are using it to set an environment variable called ENVIRONMENT by using the ENV command. Finally, we make a script called entrypoint.sh executable and define our entrypoint. ENTRYPOINT is the default command that is executed when we run the Docker image.

##### Listing 3.2 An example Dockerfile for Python applications

```dockerfile
FROM python:3.10-slim-buster    #A
WORKDIR /app    #B
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
                       build-essential \
                       && apt-get clean && rm -rf /tmp/* /var/tmp/*
COPY requirements.txt /app/requirements.txt    #C
RUN pip3 install --upgrade pip    #C
RUN pip3 install --no-cache-dir -r requirements.txt    #C
COPY . /app    #D
EXPOSE 8083
ENV PYTHONPATH "/app"    #E
ARG environment    #E
ENV ENVIRONMENT $environment    #E
RUN chmod +x /app/entrypoint.sh    #F
ENTRYPOINT ["/app/entrypoint.sh"]    #F
```

The entrypoint.sh hosts the script which will act as the command that runs our Docker container.

##### Listing 3.3 Entrypoint sh example

```
#!/bin/sh
uvicorn main:app --host 0.0.0.0 --port 8083
```

Our application directory structure with the Dockerfile would now look like this. We have our Dockerfile and entrypoint.sh.

```
├── Dockerfile
├── entrypoint.sh
├── main.py
└── requirements.txt
```

### 3.1.3 Building And Pushing Docker Image

Now that we have our packaging instructions in the Dockerfile we need to fill the container (or start packaging). The process of filling the container in the Docker world refers to building an image. Think of an image as a package that is ready to be shipped to your deploy environment. We build a docker image by running the command

```bash
docker build . -t hello-joker:v1
```

The docker image name is hello-joker and the tag is v1. An image tag can correspond to the image version or a git commit ID. Once the image is built we should be able to see the list of local images by running

```bash
docker images
```

which will list our image. This specifies the repository which is the Docker image name, the tag which represents the Docker image tag. Docker also generates a unique image ID. We can even see its time of creation and the size of the image.

```
REPOSITORY     TAG    IMAGE ID       CREATED          SIZE
hello-joker   v1    5004e994efa5   20 minutes ago   361MB
```

When we have built an image we have just created a lightweight, standalone, and executable package that includes all the necessary dependencies, libraries, and configurations to run a specific application. Running an image involves creating an instance of a Docker image. A container is a runnable instance of a Docker image, and it encapsulates the application and its dependencies in an isolated environment. To run an image we use the Docker run command, which will launch the application. -p publishes the container port 8083 to host port 8081. I.e. the service is available at localhost:8081. The -it flag enables both interactive mode which is useful for running interactive processes, such as a shell session inside the container or an application that expects user input. In this case if we wish to terminate the application we can just type ctrl+c to stop the application.

```bash
docker run -it hello-joker:v1 -p 8081:8083
INFO:     Started server process [7]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:80 (Press CTRL+C to quit)
```

If we curl the endpoint again at port 8081 we get

```
curl localhost:8081
{"random_joke":"Why did the QA cross the road? To ruin everyone's day."}
```

We would like to track and save these image versions in a manner similar to how we track and store our code in Git as our application code evolves. This is enabled by the container registry. A container registry is a centralized repository for storing and managing container images. Orchestrators like Kubernetes pull the image from the container registry and run your application. A Docker hub is an example of a container registry. We have cloud-provided container registries like Google container registry GCR or elastic container registry provided by AWS.

![Figure 3.1 Process of building the docker image from the local desktop and pushing it to the container registry, from where a server retrieves the image and runs it as a container.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/03__image003.png)

Now that we have built the image and tested the image locally, we can push it to a container registry. For this we will use the Docker hub to store our image. First, we need to register in Docker hub by creating an account here [https://hub.docker.com/signup](https://hub.docker.com/signup). We must then proceed to click on create a registry, give it the name of the image hello-joker, and set visibility to the public. Then proceed to login to the Docker hub from your local by running

```bash
docker login
```

Enter our credentials and proceed to push the image to the container registry.

```bash
docker push hello-joker:v1
```

Docker CLI provides multiple commands that one can use to check the running containers, check logs etc. Additional Docker commands and Dockerfile references can be found at [https://docs.docker.com/reference/](https://docs.docker.com/reference/).

In the next section we will pull the image from the container registry and deploy it on a container orchestrator.

## 3.2 Kubernetes

Kubernetes is a container orchestration tool. What does that mean though? We recently learned about Docker containers, but how do we deploy those containers to environments outside of the development environment? We can of course run the containers with a simple docker run command. But what if a container goes down because of say memory requirements (the infamous Out of Memory (OOM) error. Who will help us to bring it back up, who will schedule the container on a server? The answer is Kubernetes (lovingly called K8s).

### 3.2.1 Kubernetes Architecture Overview

Imagine we have a server/node on which we have installed Kubernetes. On this node we deploy our containers. If the node goes down, then our application also goes down. To overcome this we need more than one node so that there is some form of resilience. This results in a cluster that can consist of two or more nodes, and on all of these nodes we have installed Kubernetes. Having multiple nodes also helps us in scaling our application in case of high load. But who manages this cluster? Who monitors the containers and schedules the container to another node in case of node failure? This is where we need to set up another node called *master* whose main job is to monitor the *worker* nodes and their workload. A Kubernetes setup consists of both master and worker nodes. Each of these nodes has certain services running on them which help in container orchestration.

Services running on master node

- API server
- Etcd key-value store
- Scheduler
- Controller

Services running on worker node

- Container runtime
- Kubelet

An API server is a component that accepts requests from users and applications. It acts as a frontend for Kubernetes and is responsible for interacting with command line interfaces, users, and other services. It acts as an interface that accepts Kubernetes commands, and these can be to schedule, scale up, or even delete a deployment.

Etcd key-value store is a distributed data store that is used to store information about the cluster. This involves information about all the nodes in the cluster, their status, and their configurations. In short, etcd provides Kubernetes with a single source of truth about the status of the system.

The scheduler is responsible for scheduling containers of the nodes. A new container would be scheduled on a node by the scheduler based on resources required by the application (CPU, memory) and resources available on a node. It matches the container with a suitable node.

The controller is the component responsible for orchestration. When an application container goes down the controller is the one who decides to launch a new container.

The controller runtime is the software used to run our application container. In our case it is docker, as we used the docker service to build our containers.

Kubelet is the software or agent which runs on the nodes. Its main role is to ensure that the containers are running on the nodes as expected.

Between the master and worker nodes. The container runtime along with Kubelet is installed on the worker node. The Kubelet service communicates with the master, informing it of the health of the node and the containers, and also performs any action requested by the master on the worker node. API server, Etcd key-value store, scheduler, and container are installed on the master node.

![Figure 3.2 User interacts with the API server in the master node to pass a command, the master node in turn communicates with the worker nodes to execute it. All of this is achieved by the components installed on the node.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/03__image005.png)

### 3.2.2 Kubectl

Kubectl (also called kube control) is the command line utility used to interact with the Kubernetes cluster. It can be used to list down nodes in a cluster, get their status, deploy applications, and many other operations.

For example

```bash
kubectl get nodes
```

lists down the different nodes in the cluster, it specifies the name, status (ready or not), a role or node label (additional metadata), age of the node, and the version of K8s.

```
NAME                    STATUS   ROLES    AGE     VERSION
gke-data-54f8762d-r7bz  Ready    <none>   8d      v1.24.14-gke.1200
gke-data-5glf8762d-r7bz Ready    <none>   8d      v1.24.14-gke.1200
gke-data-7d9b880a-jljzk Ready    <none>   4d17h   v1.24.14-gke.1200
```

We can even retrieve cluster information by running

```bash
kubectl cluster-info
```

Or run the application in Kubernetes by using the

```bash
kubectl run <application_name> –image <docker_image_name>
```

These are just a few examples of the many tasks you can perform with Kubectl. It's an essential tool for managing and interacting with Kubernetes clusters, whether you're deploying, scaling, monitoring, or debugging your applications. In the upcoming sections, we will provide more examples of Kubectl commands. Please install Kubernetes and Kubectl in your local system to test out these commands. Instructions are provided in Appendix A.

### 3.2.3 Kubernetes Objects

#### Pods

In section 1.1 we were successfully able to build a Docker image for a Fast API application. It's time to deploy this application container in a Kubernetes cluster. This container however won’t be deployed as a Docker container, instead, it would be encapsulated as a Kubernetes object called pod. A Pod is the smallest unit in the Kubernetes world, it is one instance of your application deployed on the cluster. We scale up the number of pods when our application load increases.

A pod can host multiple containers, these containers share the same network and storage space. Multi-container pods are mainly set up when one of the containers is a utility container and lives and dies with the main container. An example of such a utility container can be a container that performs logging for the main application or performs some file processing. These containers are like different rooms in an apartment, each with its purpose. They share the same resources, making it easy for them to communicate and work together.

Let us create a pod for our hello-joker application. Kubernetes object definitions are written in a YAML file. To learn about YAML file format please refer to Appendix B. Let us start writing the pod definition in a YAML file.

All Kubernetes objects have four main parent keys.

1. API Version
1. Kind
1. Metadata
1. Spec

The API version aids Kubernetes in deciphering the settings and configuration we provide for a given resource. It guarantees consistency and compatibility as Kubernetes develops and adds new capabilities. Each Kubernetes resource type, such as pods, has its API version.

Kind specifies the type of object, it can be Pod, Deployment, Replicaset, Service, etc. In our case, it's a Pod.

Metadata specifies the information about the pod itself. It's where we specify the name of the pod and can also label the pods if required. Labels are widely used for selecting and organizing resources when defining other Kubernetes objects such as services, and deployments.

The spec is used to list down the contents of the pod. At a minimum, it includes the image name and the container name. For our Fast API application, we also need to specify the port the container should listen to for traffic.

The complete pod.yaml for our fast API application would look something like this

##### Listing 3.4 Pod.yaml file to create a pod

```yaml
apiVersion: v1    #A
kind: Pod    #B
metadata:
  name: joker    #C
spec:
  containers:
  - name: hello-joker    #D
    image: <docker_hub_repo>:hello-joker:v1    #E
    ports:
    - containerPort: 80    #F
```

We can create this pod by running the Kubectl create command. The Kubectl create command creates a Kubernetes object.

```bash
kubectl create –file pod.yaml
```

Which gives us the output

```
pod/joker created
```

If we wish to know how many pods are running we can run the Kubectl get pod

```bash
kubectl get pod
```

We should see the following output. Name refers to the name of the pod, Ready is the ratio of the number of running containers in a pod/ total container in a pod. Status gives us the state of the pod; it's in a running state and hence the status is Running. Restarts indicate the number of times the pod has restarted. Age is simply the time since the pod has been started.

```
NAME    READY   STATUS    RESTARTS      AGE
joker    1/1     Running   0             3m34s
```

Let us intentionally change the image name to a non-existent name hello-joker:v1 in pod.yaml. We can now apply this change using Kubectl apply, which will create and replace the pod.

```bash
kubectl apply –file pod.yaml
```

This will give us the output

```
pod/joker configured
```

When we run Kubectl get we will see that our pod status is ErrImagePull. As the name suggests the pod encountered some error when pulling the image. This was expected as the image does not exist. Also note that the ready is 0/1, which means that no container in the pod is running.

```
NAME    READY   STATUS    RESTARTS      AGE
joker    0/1     ErrImagePull   0           44s
```

We can rectify this by fixing our image name and applying those changes using Kubectl apply.

To retrieve more information about the pod we can run the Kubectl describe command which gives us more information about the pod.

```bash
kubectl describe pod joker
```

This gives us information about the pod, such as its name, the container image name, the state of the pod, the node on which the pod is running, the pod IP, and the events the pod has encountered. We can see the list of events which includes the process of pulling the image and starting the container once the image has been pulled. This command can be used for debugging the pod if an error occurs.

To read the pod logs we need to run Kubectl logs command

```bash
kubectl logs joker
```

Which gives us the container logs.

```
INFO:     Started server process [7]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:80 (Press CTRL+C to quit)
```

Let us test this pod by hitting the endpoint so that it returns a joke. But how to access this from our local system? We can do that by running the Kubectl port-forward command. The Kubectl port-forward command is especially useful for debugging, testing, and accessing services that are not exposed externally via a Kubernetes service. We need to specify the pod name and the host port: this is the port on our local system where the application would be available, and the container port is the port in the container where the application is expecting traffic.

```bash
kubectl port-forward <pod_name> <host_port>:<container_port>
```

For us, it would be

```bash
kubectl port-forward joker 8080:80
```

keep note that the host port could be any free available port on your local system. If we then proceed to our browser and type `http://localhost:8080`, we should be seeing a random joke.

```json
{"random_joke":"How do you know whether a person is a Vim user? Don't worry, they'll tell you."}
```

Finally, if we wish to delete the pod we can do so by running the Kubectl delete command

```bash
kubectl delete pod joker
```

Which gives us the output

```
pod "joker" deleted
```

In the above section, we were able to create a pod, update the pod, check the events during the pod lifecycle, retrieve pod logs, test it out, and finally delete the pod. Kubernetes pods serve as the fundamental building blocks of containerized applications within the Kubernetes ecosystem. In the upcoming sections, we will learn how to scale these pods and how to ensure another pod is scheduled by Kubernetes in case of node failure or an error.

#### Replicaset

What if we need to scale the number of pods or ensure at least one pod of our application is running? We may do this either for high availability or because we have too many requests to our app that our one pod cannot handle. We do that using a Replicaset.

Replicaset is a Kubernetes object which is used to monitor pods and replicate them if necessary. To create a replicaset, we start by defining the common four properties of the Kubernetes object: API version, kind, metadata and spec. The API version is apps/v1, kind is replicaset, metadata includes the name and label of the replicaset. Spec has three child properties: template, replicas, and selector. The template is the pod template that we wish to replicate. Replicas refers to the number of pod replicas we want. The selector informs the replicaset about what pods to replicate and monitor. This is done by matching the labels of the pod we defined. But why should we specify the selector when we have already provided the replicaset with a pod template? The reason is that a replicaset can monitor pods that were created before its existence. We provide the pod template in case a pod goes down or the pod number does not match the number of intended replicas, in which case the replicaset can create a new pod from the template provided.

Let us create a replicaset using our Joker application pod as a template. The template follows the pod template we had seen earlier. The number of replicas is set to three and the selector asks the replicaset to replicate pods that match the labels app: fast-api.

##### Listing 3.5 Replicaset.yaml file to create a Replicaset

```yaml
apiVersion: apps/v1    #A
kind: Replicaset    #B
metadata:
  name: joker-replicaset    #C
  labels:
      app: fast-api    #D
spec:
  template:    #E
    metadata:
      name: joker    
      labels:
          app: fast-api    #F
    spec:
      containers:
      - name: hello-joker
        image: varunmallya/hello-joker:v1
        ports:
        - containerPort: 8083
  replicas: 3    #G
  selector:
    matchLabels:    #H
      app: fast-api
```

We create replicaset by running

```bash
kubectl create -f replicaset.yaml
```

This spins up three pods of the Joker application. Take note that the name of the pod is the name of the replicaset with suffixed hashes. The names of the hashes are not fixed and will vary each time we try to create the replicaset.

```
NAME                              READY   STATUS    RESTARTS      AGE
joker-replicaset-nznl4            1/1     Running   0             16s
joker-replicaset-vqdcx            1/1     Running   0             16s
joker-replicaset-zxmf9            1/1     Running   0             16s
```

Let us try deleting one of the pods to see if the replicaset spins up a pod to ensure the number of running replicas is three

```bash
kubectl delete pod joker-replicaset-nznl4
```

We will see that a new pod is launched by the replicaset almost instantaneously

```
NAME                              READY   STATUS    RESTARTS      AGE
joker-replicaset-m7hvk            1/1     Running   0             59s
joker-replicaset-vqdcx            1/1     Running   0             6m26s
joker-replicaset-zxmf9            1/1     Running   0             6m26s
```

If we wish to scale this replicaset, we can run Kubectl scale command, we will scale the number of replicas to 4

```bash
kubectl scale ReplicaSet joker-replicaset --replicas=4
```

We can see that four replicas will now be made available

```
NAME                              READY   STATUS    RESTARTS      AGE
joker-replicaset-lkwjb            1/1     Running   0             5m29s
joker-replicaset-m7hvk            1/1     Running   0             39m
joker-replicaset-sr4vr            1/1     Running   0             17s
joker-replicaset-vqdcx            1/1     Running   0             44m
```

We can also verify if replicaset can monitor a pod that was created before its existence. To do this we will first delete the replicaset by running

```bash
kubectl delete ReplicaSet joker-replicaset
```

We will then spin a single pod of our joker application

```bash
kubectl create -f pod.yaml
```

Let us now recreate our replicaset and check how many new pods are created by the replicaset. Our replicaset expects three pods of the Joker. We can see that the replicaset has launched two new pods of type joker which, along with the original pod, fulfills the criteria.

```
NAME                              READY   STATUS    RESTARTS      AGE
joker                             1/1     Running   0             3m46s
joker-replicaset-49c62            1/1     Running   0             3m19s
joker-replicaset-976ph            1/1     Running   0             3m19s
```

ReplicaSets react to changing conditions by continuously monitoring and altering the number of replicas, ensuring that the desired state of the application is maintained even in the face of node failures or fluctuating traffic loads. We were able to create, modify, and delete a replicaset. We also learned that replicasets can be used to take into account pods that were created before their existence.

#### Deployments

Kubernetes deployment handles operations like scaling up or down and upgrading container images to make sure that the actual state of the application matches the desired state. This is very similar to Replicasets, but there are a few differences between the two. Deployments support rolling updates. This means when we wish to update our application container image with a newer version of the image, we can do it gradually, bringing one pod down and replacing it with a newer one. In the process, if the newer pod encounters some errors, the update will be paused. This approach is better than bringing all the pods of the old version down before replacing them with the pods running the new version as it ensures no impact to the users. Kubernetes deployment also supports rollback, which means if we find some issues with the newer version of the application we can also choose to rollback to a previous properly functioning version.

Deployments are higher-level abstractions that provide declarative updates to applications. Deployments manage ReplicaSets which inturn manage pods which hold the application container. Deployment also provide additional features like rolling updates and rollbacks.

![Figure 3.3 When we create a Deployment, it creates a ReplicaSet, which, in turn, manages the creation and scaling of Pods based on a specified Pod template. The Pod holds the application container.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/03__image007.png)

Let us create a Deployment for our Joker application. YAML syntax-wise it's the same as a Replicaset with just one change: we modify the property kind’s value from ReplicaSet to Deployment.

##### Listing 3.6 Deployment.yaml file to create a Deployment

```yaml
apiVersion: apps/v1    #A
kind: Deployment    #B
metadata:
  name: joker-deployment    #C
  labels:
      app: fast-api
spec:
  template:    #D
    metadata:
      name: joker
      labels:
          app: fast-api
    spec:
      containers:
      - name: hello-joker
        image: varunmallya/hello-joker:v1
        ports:
        - containerPort: 8083
  replicas: 3
  selector:
    matchLabels:
      app: fast-api
```

We create the deployment using the Kubectl create command.

```bash
kubectl create -f deployment.yaml
```

Which give us

```
deployment.apps/joker-deployment created
```

We can list deployments by running

```bash
kubectl get deployments
```

In the output the name refers to the name of the deployment, Ready indicates the number of pods up/ number of pods desired. Up-to-date refers to the number of pods that are running the intended application version. Available specifies how many pods are available to be used and age gives the time since the deployment has been up.

```
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
joker-deployment   3/3     3            3           12m
```

Let us see how pods are updated by a deployment. For this let us modify the application image tag to a v2.

```
containers:
      - name: hello-joker
        image: varunmallya/hello-joker:v2
```

And update the deployment by running

```bash
kubectl apply -f deployment.yaml
```

We can then see the deployment events by running the kubectl describe command. The events show that pods are scaled up one pod at a time. Joker-deployment-5d7fd8d75f is the old deployment and joker-deployment-5c6f544ccd is the new deployment. The old deployment initially starts with three replicas and the new deployment spins up one pod, after which the old deployment scales down to two and the new deployment scales to 2 replicas, and so on.

```bash
kubectl describe deployment joker-deployment
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  40m   deployment-controller  Scaled up replica set joker-deployment-5d7fd8d75f to 3
  Normal  ScalingReplicaSet  104s  deployment-controller  Scaled up replica set joker-deployment-5c6f544ccd to 1
  Normal  ScalingReplicaSet  96s   deployment-controller  Scaled down replica set joker-deployment-5d7fd8d75f to 2
  Normal  ScalingReplicaSet  96s   deployment-controller  Scaled up replica set joker-deployment-5c6f544ccd to 2
  Normal  ScalingReplicaSet  86s   deployment-controller  Scaled down replica set joker-deployment-5d7fd8d75f to 1
  Normal  ScalingReplicaSet  86s   deployment-controller  Scaled up replica set joker-deployment-5c6f544ccd to 3
  Normal  ScalingReplicaSet  78s   deployment-controller  Scaled down replica set joker-deployment-5d7fd8d75f to 0
```

Let us update the deployment with an image that does not exist. We see another entry to the above events table. The new deployment is scaled up by only one pod. This is because the Kubernetes deployment realises there was an image pull error when that pod was being created and hence it does not proceed to scale it to three. It also does not scale down the older version of the application, as a result, it ensures there are three pods of the application running.

```
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  50m   deployment-controller  Scaled up replica set joker-deployment-5d7fd8d75f to 3
  Normal  ScalingReplicaSet  11m   deployment-controller  Scaled up replica set joker-deployment-5c6f544ccd to 1
  Normal  ScalingReplicaSet  11m   deployment-controller  Scaled down replica set joker-deployment-5d7fd8d75f to 2
  Normal  ScalingReplicaSet  11m   deployment-controller  Scaled up replica set joker-deployment-5c6f544ccd to 2
  Normal  ScalingReplicaSet  11m   deployment-controller  Scaled down replica set joker-deployment-5d7fd8d75f to 1
  Normal  ScalingReplicaSet  11m   deployment-controller  Scaled up replica set joker-deployment-5c6f544ccd to 3
  Normal  ScalingReplicaSet  10m   deployment-controller  Scaled down replica set joker-deployment-5d7fd8d75f to 0
  Normal  ScalingReplicaSet  36s   deployment-controller  Scaled up replica set joker-deployment-54fdcf5bb5 to 1
```

We can see the deployment status by again running Kubectl get. We can see that only one pod is up to date with the new version (the pod with image failed error) but three pods of the older version of the application are still running.

```
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
joker-deployment   3/3     1            3           69m
```

We can undo this deployment by running kubectl rollout undo deployment command.

```bash
kubectl rollout undo deployment/joker-deployment
```

This ensures our deployment version is rolled back by one version. Hence it will get rid of the one pod with the version that had errors and our deployment now has three up-to-date pods.

```
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
joker-deployment   3/3     3            3           3h34m
```

Finally, we can delete a deployment by running

```bash
kubectl delete deployment joker-deployment
```

We learned how to create, update, roll back, and delete a deployment. Most stateless applications like our joker application or the machine learning inference modeling services that will be deployed in the successive chapters, will be done using Kubernetes deployment.

### 3.2.4 Networking And Services

In the previous section, we learned how to deploy applications on Kubernetes. But how does one make the application available to users/other applications? How does one hit our Fast API joker endpoint to get a random joke? We had earlier connected to the pod by using the Kubectl port-forward command, this however is only for testing purposes, as one cannot expect a regular user to perform port forwarding every time they need to access a website. Kubernetes services enable us to expose our applications to users and other applications. They enable efficient networking and connectivity within a Kubernetes cluster.

Kubernetes services also allow applications within the Kubernetes cluster to communicate with each other. Imagine we have a front-end application that needs to communicate with a back-end application. Both applications are deployed in Kubernetes. The front-end application will communicate with the external users and the back-end application through means of services.

![Figure 3.4 User interacts with service 1 to access the front-end application. The front-end application talks to the back-end application via service 2. Services here act as an abstraction.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/03__image009.png)

Keep note that pods have their own IP address, and a pod can communicate with other pods. However, we do know that pods can be restarted, deleted, and spun up with every new deployment. This dynamic and frequently transient nature of pods is decoupled from the stable requirements of other components and external users by an abstraction layer offered by Kubernetes services.

There are different types of Kubernetes services:

- Node Port
- Cluster IP
- Load Balancer

#### Node Port

Node port services are used to make the application running on the pod available on a port of the node it is running in. When we create a NodePort service, Kubernetes assigns a specific port on each node to the service. This port will be used to forward traffic to the pods belonging to the service. The allocated NodePort allows external clients, like users or other services, to access our application through the cluster's nodes. For example, if the allocated NodePort is 33000, an external client can reach your service by connecting to http://<node_IP>:33000. If the cluster is scaled up or down, the NodePort service remains available on all nodes, regardless of which nodes the pods are running on. This ensures consistent access even when pods move around due to scaling or node failures.

Let us create a NodePort service for our Joker application. Like all Kubernetes objects, we will create a yaml file and list the four common properties. The API version is v1, kind is Service, metadata includes the name of the service and specifies the type, port information of the service, and a selector. Under ports, we have listed three types of ports

- Target port
- Port
- Node port

Target port is the port on the pod where the application is available. Port is the service port that communicates with the target port. Node port is the port on which a user can access the service, a node port value can lie between 30000 to 32767. Similar to deployment and replicaset, we need to specify a selector that matches the labels of the pod we want the service to interact with.

![Figure 3.5 User queries the node port which speaks to the service port. The service port queries the target port in a pod.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/03__image011.png)

Having all this information let's define the node-port-service.yaml.

##### Listing 3.7 Nodeport.yaml file to create a Nodeport service

```yaml
apiVersion: v1    #A
kind: Service    #B
metadata:    #C
  name: joker-nodeport-service
spec:
  type: NodePort    #D
  ports:
    - targetPort: 8083    #E
      port: 80    #F
      nodePort: 30420    #G
  selector:
      app: fast-api    #H
```

We can create it by running

```bash
kubectl create -f node-port-service.yaml
```

We can then see the service by running

```bash
kubectl get service
```

Here the name and type specify the name and type of the service. Cluster IP is the internal IP of the service, External IP is the IP address that can be used to communicate with services deployed in the cluster from outside the cluster. In our case, it is empty as we will be using the Node’s IP as the host address. The ports signify the <service_port>:<node_port>/protocol. Age signifies the time since the service was created.

```
NAME                        TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
joker-nodeport-service      NodePort       10.65.67.224   <none>        80:30420/TCP     19m
```

To test out the service we need to retrieve the node IP first. That is done by running the kubectl get nodes command. The -o wide gives us additional information like the external IP of the node.

```bash
kubectl get nodes -o wide | grep -v EXTERNAL-IP | awk '{print $1, $7}'
```

This gives us the output which lists the node name and its external IP address.

```
gke-dev-04b53695-tkxx 35.189.23.46 
gke-dev-06b596589-bkfx 35.190.23.67
gke-dev-089596589-dkjn 35.67.23.46
gke-dev-55969b6509-mkig 35.69.230.43
```

We can use the external IP of any node along with the node port to access our service. Let us use the external IP of the first node to test it out

```
curl http:/35.189.23.46:30420
{"random_joke":"What does pyjokes have in common with Adobe Flash? It gets updated all the time, but never gets any better."}
```

Our application is available at node port 30420 and we are able to retrieve our random joke by hitting it. Keep in mind we can use any node IP, Kubernetes takes care of routing our request to the right service and pod. This shows us how the node port service acts as an abstraction layer for our application.

To delete the service we run

```bash
kubectl delete service joker-nodeport-service
```

#### Cluster IP

For accessing pods located in the same Kubernetes cluster, a ClusterIP service in Kubernetes provides an internal, cluster-level IP address. When you wish to enable communication between various components of your application without making it accessible to the outside network, we utilize this kind of service. An example of this is when the front-end application wishes to talk with the backend application, both of which run in the Kubernetes cluster and the communication is completely internal.

Kubernetes assigns an IP address from the cluster's internal IP range to the service when we create a ClusterIP service. This IP address is not reachable from outside the cluster and is only usable within it. Traffic load balancing to the pods that fit the service's selector is handled by the ClusterIP service. Traffic is evenly distributed across these pods by the service IP, which routes traffic to them. Within the cluster, the IP address of the ClusterIP service can be used as a DNS name to access the service's related pods. The service name and ClusterIP are mapped by Kubernetes through the use of DNS records.

Let us create a Cluster IP service for our Joker application. The cluster-ip-service.yaml is very similar to the node-port-service.yaml with two differences: the type is ClusterIP and there is no need to specify nodePort under the ports section.

##### Listing 3.8 cluster-ip-service.yaml file to create a ClusterIP service

```yaml
apiVersion: v1    #A
kind: Service    #B
metadata:
  name: joker-nodeport-service
spec:
  type: ClusterIP   #C
  ports:    #D
    - targetPort: 8083
      port: 80
  selector:
      app: fast-api    #E
```

We create the cluster ip service by running

```bash
kubectl create -f cluster-ip-service.yaml
```

We can see the service by running kubectl get service command which gives us

```
NAME                        TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
joker-cluster-ip-service    ClusterIP      10.65.75.100   <none>        80/TCP           9s
```

Take note that there is no node port.

We can test this out by calling this service from another pod. Let us run a single pod called test-pod of image curl images/curl which is a docker image with curl pre-installed.

```bash
kubectl run test-pod --image=curlimages/curl
```

We then access the shell terminal of this pod by running the kubectl exec command. The -it stands for interactive

```bash
kubectl exec -it test-pod sh
```

We will now curl the service ip and port from this shell

```
~ $ curl http://10.65.75.100:80
{"random_joke":"There are two ways to write error-free programs; only the third one works."}
```

We can also curl the service name which acts as the hostname

```
~ $ curl http://joker-cluster-ip-service:80
{"random_joke":"How many programmers does it take to change a lightbulb? None, that's a hardware problem."}
```

The ClusterIP service serves as a link between several Kubernetes environment components using a cluster-scoped IP address.

#### Load Balancer

The LoadBalancer service type uses an external load balancer to expose a collection of pods to the outside world or other services within the cluster. This service type is frequently employed when it's necessary to split up incoming traffic among several pods to increase performance, redundancy, and high availability.

LoadBalancer services create an external load balancer that resides outside the Kubernetes cluster. This load balancer receives incoming traffic and distributes it across the pods associated with the service. When we create a load balancer service, Kubernetes talks to the cloud provider to assign the load balancer an external IP address. Clients who are located outside of the cluster can access your application using this IP address. The external load balancer routes incoming traffic to the nodes and pods in the service. This routing ensures even distribution of traffic and efficient utilization of resources. The LoadBalancer service's external IP address enables external clients, such as users or other services, to access your application. It offers a solitary point of access to the pods included in your service.

![Figure 3.6 External load balancer routing traffic via load balancer service to pods.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/03__image013.png)

Let us create a LoadBalancer service for the Joker application. Loadbalancer-service.yaml is similar to the cluster ip service with only the type being LoadBalancer

##### Listing 3.9 load-balancer-service.yaml file to create a LoadBalancer service

```yaml
apiVersion: v1    #A
kind: Service    #B
metadata:
  name: joker-load-balancer-service
spec:
  type: LoadBalancer    #C
  ports:    #D
    - port: 80
      targetPort: 8083
  selector:
    app: fast-api   #E
```

We create it using the kubectl create command

```bash
kubectl create -f loadbalancer-service.yaml
```

When we retrieve the service details using kubectl get command we can see

```
NAME                          TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)          AGE
joker-load-balancer-service   LoadBalancer   10.65.77.13    34.101.34.188   80:30729/TCP     3m7s
```

We can see that the load balancer service has an external IP associated with it. We can also access this IP from our local terminal via curl we can see our joke

```
curl http://34.101.34.188:80 
{"random_joke":"Java: Write once, run away."}
```

LoadBalancer services are typically used for exposing services to external clients or networks. They are suitable for public-facing web applications, APIs, and services that require direct external access.

Let us summarize the difference between the three service types in the below table.

| <br>      <br>      <br>        Cluster IP <br>       <br> | <br>      <br>      <br>        Node Port <br>       <br> | <br>      <br>      <br>        Load Balancer <br>       <br> |
| --- | --- | --- |
| <br>     <br>       Accessible only within the cluster <br> | <br>     <br>       Accessible externally using the Node's IP and a specified port <br> | <br>     <br>       Externally accessible through a cloud provider's load balancer. <br> |
| <br>     <br>       Internal communication within the cluster. <br> | <br>     <br>       Development or testing scenarios where external access is needed without a complex setup. <br> | <br>     <br>       Production scenarios where external access and automatic load balancing are required. <br> |
| <br>     <br>       Simplest configuration <br> | <br>     <br>       Requires specifying a static port, and the service is accessible externally on that port. <br> | <br>     <br>       Involves external load balancer provisioning and additional cloud provider-specific configurations. <br> |

Two of the most frequent Kubernetes objects are deployments and services. We can now deploy applications on Kubernetes and make them accessible to other services or users by having this expertise.

### 3.2.5 Other Objects

Apart from Kubernetes Deployments and Services, other Kubernetes objects help us ensure a production-grade deployment. The complete list of objects is beyond the scope of this book but we wanted to cover three more objects

- Namespaces
- Config Maps
- Secrets

#### Namespaces

Namespaces are a way to create virtual clusters within a physical cluster. They provide a scope for names, allowing us to organize and manage resources in a more isolated and manageable manner. Namespaces are particularly useful in large and complex Kubernetes environments where multiple teams or applications share the same physical cluster but need separation and resource management. Namespaces provide a form of resource isolation within a single Kubernetes cluster. Each namespace has its own set of resources, such as pods, services, replicasets, and more. This isolation helps prevent naming conflicts and allows different teams or applications to work independently.

By default, Kubernetes starts with a "default" namespace. If you don't specify a namespace, resources are created in the default namespace. All the resources we created in the earlier sections were created in the default namespace. However, we can create additional namespaces if and when required.

Let us create a new namespace called funny and deploy our Joker application there. To create a namespace we use the kubectl create namespace command

```bash
kubectl create namespace funny
```

We can list down the namespaces by running, this gives us the name of the namespace and its age

```bash
kubectl get namespaces
NAME                                  STATUS        AGE
default                               Active        86d
funny                    Active        6m
```

To get the pods deployed in this namespace we run

```bash
kubectl get pod -n funny
```

As we have not deployed anything in this namespace we get

```
No resources found in funny namespace.
```

Let us deploy our Joker application in the funny namespace. To do so we just need to add the namespace attribute under metadata of the deployment.yaml.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: joker-deployment
  namespace: funny  
  labels:
      app: fast-api
..
```

After creating this deployment by running

```bash
kubectl create -f deployment-with-namespace.yaml
```

We can re-run kubectl get command in the funny namespace and we can see that three pods have been created

```
NAME                                READY   STATUS    RESTARTS   AGE
joker-deployment-5d7fd8d75f-cjxh7   1/1     Running   0          6m52s
joker-deployment-5d7fd8d75f-rhx4q   1/1     Running   0          6m53s
joker-deployment-5d7fd8d75f-xrqqh   1/1     Running   0          6m55s
```

We can create services similarly by specifying the namespace under the service’s metadata in cluster-ip-service.yaml. Let us create a cluster IP service in the funny namespace.

```bash
kubectl create -f service-with-namespace.yaml
```

We list the services in the namespace by using -n flag

```bash
kubectl get services -n funny
NAME                       TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
joker-cluster-ip-service   ClusterIP   10.65.77.208   <none>        80/TCP    5s
```

Services within a namespace can refer to each other by their name. However, if we wish to call a service from a different namespace we need to follow the following DNS convention - <service-name>.<namespace-name>.svc.cluster.local

Let us try calling the cluster IP service we created in the funny namespace from our test pod in the default namespace. We do so by sshing into the test-pod (using kubectl exec -it) and running

```
curl http://joker-cluster-ip-service.funny.svc.cluster.local:80
{"random_joke":"If you put a million monkeys at a million keyboards, one of them will eventually write a Java program. The rest of them will write Perl."}
```

Kubernetes namespaces become an essential tool for preserving clarity and order as applications scale. They encourage the tidy categorization of resources, isolating various teams, projects, or settings without worrying about naming conflicts. As a result, complexity is controlled in the ecosystem.

#### ConfigMaps

ConfigMaps are Kubernetes objects that allow us to manage configuration data separately from our application code. They provide a way to store key-value pairs, environment variables, and even configuration files centrally. ConfigMaps help decouple configuration from application logic, making it easier to manage and update configuration settings without modifying the application code or containers.

These configurations include settings like database URL, API endpoints among others.

An example of such a config map is shown below. API version is v1, kind is ConfigMap, under metadata we specify the name of the configmap. Instead of spec we have data under which we can specify key-value pairs that might get used in an application.

##### Listing 3.10 config-map.yaml file to create a ConfigMap

```yaml
apiVersion: v1    #A
kind: ConfigMap    #B
metadata:
  name: test-configmap     #C
data:    #D
  database-url: "cloudsql-proxy.prod.company.data"
  api-key: "AJNKJNKCEKK390”
```

We can list configmaps by running

```bash
kubectl get configmaps
```

It returns the configmap name, under data, we have the number of key-value pairs the config map holds

```
NAME                                   DATA   AGE
test-configmap                         2      26m
```

We can retrieve data in a configmap by using kubectl describe

```bash
kubectl describe configmap test-configmap
Name:         test-configmap
Namespace:    default
Labels:       <none>
Annotations:  <none>
Data
====
api-key:
----
AJNKJNKCEKK390
database-url:
----
cloudsql-proxy.prod.company.data
```

#### Secrets

Secrets are Kubernetes objects that provide a secure way to manage sensitive information such as passwords, API tokens, and other confidential data. Secrets provide a higher level of security by encoding the data at rest.

Sensitive information is often base64 encoded when you generate a secret to handle special characters and binary data. This encoding allows the sensitive information to be represented in a text-friendly format within YAML files. Base64 encoding is an encoding, not an encryption, which is a crucial distinction to make. One could easily decode this information if required. For stronger security, consider encrypting sensitive information outside of Kubernetes using industry-standard encryption tools or dedicated secret management solutions such as Vault.

There are multiple types of Kubernetes secrets, some of which are

- Opaque
- Docker Registry
- TLS

Opaque is for arbitrary key-value pairs, Docker registry is used for docker authentications, TLS is for TLS certificates and private keys.

An example of a secret is shown below. The API version is v1, kind is Secret, metadata, as usual, specifies the name of the secret, type specifies the type of secret. Under data we specify the base 64 encoded values of datbase_username and database_password. To base64 encode a value we run the following command

```
echo -n "db_username" | base64
```

Giving us

```
ZGJfcGFzc3dvcmQ=
```

Once we have the base64 encoded values for the username and password we can create the secret

##### Listing 3.11 secrets.yaml file to create a Secret

```yaml
apiVersion: v1    #A
kind: Secret     #B
metadata:
  name: test-secret    #C
type: Opaque    #D
data:
  database_username: ZGJfdXNlcm5hbWU=
  database_password: ZGJfcGFzc3dvcmQ=
```

We then create the secret by running

```bash
kubectl create -f secret.yaml
```

We can retrieve the secret by running kubectl get secret command

The output is similar to config map but there is an additional type column that specifies the type of secret

```
NAME                      TYPE                                  DATA   AGE
test-secret              Opaque                                2      4s
```

If we wish to know the secret values we have to use kubectl to describe

```bash
kubectl describe secret test-secret
```

This gives us the number of bytes used to store the database_password and database_username but its values are not shown

```
Name:         test-secret
Namespace:    default
Labels:       <none>
Annotations:  <none>
Type:  Opaque
Data
====
database_password:  11 bytes
database_username:  8 bytes
```

To retrieve the values and decode them we run the below command. –template is used to specify the path of the variable and base64 -d is used to decode it.

```bash
kubectl get secrets/test-secret --template={{.data.database_username}} | base64 -D
```

Gives us

```
db_username
```

We now know how to define the secrets and configmap, but how do we use it in our application? We use the variables defined in the config map as environment variables. We do that by specifying the environment variables in the pod and retrieving the values from the configmap. Environment variables are defined in the pod using env property, values are retrieved by using valueFrom and we specify the configmap name and the key under configMapKeyRef. For secrets instead of configMapKeyRef we use secretKeyRef.

Let use the variable database-url and api-key defined in test-configmap in a pod. We define two environment variables DATABASE_URL and API_KEY. The values for these environment variables are being retrieved from test-configmap using configmapKeyRef.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-using-configmap
spec:
  containers:
    - name: container-using-configmap
      image: ubuntu
      env:
        - name: DATABASE_URL
          valueFrom:
            configMapKeyRef:
              name: test-configmap
              key: database-url
        - name: API_KEY
          valueFrom:
            configMapKeyRef:
              name: test-configmap
              key: api-key
```

We can also use our variables defined in secret test-secret. In this case we use secretKeyRef under valueFrom.

```
env:
        - name: DATABASE_USERNAME
          valueFrom:
            configMapKeyRef:
              name: test-secret
              key: database-username
        - name: DATABASE_PASSWORD
          valueFrom:
            configMapKeyRef:
              name: test-secret
              key:  database-password
```

We have now covered pods, replicasets, deployments,services, namespaces, configmaps and secrets. There are many other Kubernetes objects which we can find in the Kubernetes documentation. The ones we described above however can help us in deploying most of the basic applications.

The strength and efficiency of Kubernetes as a platform for container orchestration are largely dependent on its objects. They are essential to making it possible for effective containerized application management, deployment, scaling, and communication.

### 3.2.6 Helm charts

When an application gets deployed, more often than not it's not just a single Kubernetes deployment that needs to be deployed to the cluster. It's a combination of deployment, configmap, secrets, services and other Kubernetes objects. Managing the relations between all the objects can get quite complicated. If we wish to modify a certain object or upgrade it we need to modify its individual file. Kubernetes does not look at our application as a whole. It examines each individual object to make sure it is functioning as it should. Therefore, we require a method of packaging all of these objects for our application.

Helm is a Kubernetes package manager that makes it easier to deploy and maintain applications. It ensures all the necessary objects of our application are installed in the respective location in the cluster while also ensuring they are customizable. Helm makes it simpler to define, install, upgrade, and manage complicated Kubernetes applications by using a concept known as "charts" to package applications. A chart is a combination of object templates and values. An object template is the Kubernetes object yaml file where certain properties are customizable. In the case of pods or deployment, the property can be the image name or the requested CPU or memory. All of these customizable values are modified in the values file. The values file (typically called values.xaml) can be used to customize hundreds of Kubernetes objects, making it easier to manage the application.

![Figure 3.7 service_template.yaml defines the Kubernetes service, the type of service and port is obtained from values.yaml. The template and values form the core of a Helm chart.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/03__image015.png)

Similar to Dockerhub which hosts Docker images for multiple applications we have the Artifacthub which acts as a repository for Helm charts of many commonly used applications. Let us install Helm and use some popular Helm commands that help us install and update applications in Kubernetes.

In Linux we run

```
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod +x get_helm.sh
./get_helm.sh
```

In Mac OS we can use HomeBrew to install Helm by running

```
brew install helm
```

Once installed we can verify the installation by running the Helm version

```
helm version
version.BuildInfo{Version:"v3.7.2", GitCommit:"663a896f4a815053445eec4153677ddc24a0a361", GitTreeState:"clean", GoVersion:"go1.17.3"}
```

We can now proceed to install an application using Helm. As an example let us try setting up Redis using Helm. Redis is a popular open-source in-memory key-value store. A Redis helm chart is available in the Artifacthub. To install Redis we need to first add a chart repository. This is the chart repository in which Helm will look for the Helm charts

```
helm repo add bitnami https://charts.bitnami.com/bitnami
```

Once we add the repo the next step would be to search for the Redis chart we wish to install this can be done by running

```
helm search repo redis
```

We get the list of charts with Redis in their names. Name refers to the chart name, app version refers to the Redis version.

```
NAME                                 CHART VERSION    APP VERSION    DESCRIPTION
bitnami/redis                         17.3.11          7.0.5          Redis(R) is an open source, advanced key-value ...
bitnami/redis-cluster               8.2.7            7.0.5          Redis(R) is an open source, scalable, distribut...
```

Once we know the charts exist we update our repo by running the Helm repo update. This is done to ensure we have the latest charts. We create a new namespace called redis-setup by running kubectl create ns redis-setup. After which we can install the chart using Helm install, we can ask Helm to generate a release name for us by using –generate-name flag.

```bash
helm repo update
kubectl create namespace redis-setup
helm install bitnami/redis --generate-name —-namespace redis-setup
```

This will install Redis and it also provides us with a release name and a revision number. This is the first release hence the revision number is one. It also provides the chart information such as name and version along with the application version.

```
NAME: redis-1692770110
LAST DEPLOYED: Wed Aug 23 13:55:24 2023
NAMESPACE: redis-setup
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
CHART NAME: redis
CHART VERSION: 17.3.11
APP VERSION: 7.0.5
```

We can see that Redis is running in the namespace redis-setup by running

```bash
kubectl get pod -n redis-setup
NAME                          READY   STATUS    RESTARTS   AGE
redis-1692770110-master-0     1/1     Running   0          7m40s
redis-1692770110-replicas-0   1/1     Running   0          7m40s
redis-1692770110-replicas-1   1/1     Running   0          6m57s
redis-1692770110-replicas-2   1/1     Running   0          6m18s
```

We can list all the different Helm releases by running Helm list. It provides us with information about the release name, and the status of deployment, along with the chart and application version.

```
helm list -n redis-setup
NAME                NAMESPACE      REVISION    UPDATED                                 STATUS      CHART            APP VERSION
redis-1692770110    redis-setup    1           2023-08-23 13:55:24    deployed    redis-17.3.11    7.0.5
```

Finally, if we wish to uninstall the Helm release we can run helm uninstall.

```
helm uninstall redis-1692770110 -n redis-setup
release "redis-1692770110" uninstalled
```

If we wish to download a chart but not install it. We can do that by using helm pull. We are untarring the chart directory using –untar.

```
helm pull –untar  bitnami/redis
```

Under redis we can see the chart directories and files. Chart.lock and Chart.yaml are to specify the chart dependencies. The charts directory holds the dependent charts.img and README.md are for Redis chart documentation. The directory of concern for most projects and us would be the templates directory. The templates directory holds the template of Kubernetes objects required to install Redis. Values.yaml is used to hold the configurable values of the templates, whereas the values.schema.json is used to validate the values one adds in values.yaml.

```
├── Chart.lock
├── Chart.yaml
├── README.md
├── charts
├── img
├── templates
├── values.schema.json
└── values.yaml
```

Let us now create a similar chart for our joker-application. We do that by running

```
helm create hello-joker
```

This creates a directory called hello-joker with the chart files. This includes Chart.yaml, an empty charts directory (no dependencies). The templates directory contains Kubernetes objects such as deployment.yaml, service.yaml and other objects.

```
├── Chart.yaml
├── charts
├── templates
└── values.yaml
```

We can configure our application to be a deployment with three replicas and a service of type Nodeport by modifying the values.yaml. We can see multiple configurations in the values.yaml file. We must modify only those configurations for deployments and services. This involves the replicaCount, image-related information, and specifying the service type and port.

```
replicaCount: 3
image:
  repository: varunmallya/hello-joker
  pullPolicy: IfNotPresent
  tag: v1
..
service:
  type: NodePort
  port: 8080
```

Once the values are modified we can try installing this chart in namespace funny by using the Helm install command

```
helm install hello-joker –generate-name -n funny
```

We can see the services and deployments in the namespace by running kubectl get all. The get all command returns all objects in the specified namespace. We have a service, three pods, a deployment, and a replicaset in the funny namespace. We were able to install this by running a single helm install command.

```bash
kubectl get all -n funny
NAME                                          READY   STATUS    RESTARTS   AGE
pod/hello-joker-1692835125-59bb5b9985-c8hg7   1/1     Running   0          29m
pod/hello-joker-1692835125-59bb5b9985-twnqr   1/1     Running   0          29m
pod/hello-joker-1692835125-59bb5b9985-x9q5h   1/1     Running   0          29m
 
NAME           TYPE       CLUSTER-IP   EXTERNAL-IP   PORT(S)          AGE
service/hello-joker-1692835125   NodePort   10.65.75.5  <none> 8080:31410/TCP   29m
 
NAME                                     READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/hello-joker-1692835125   3/3     3            3           29m
 
NAME                                                DESIRED   CURRENT   READY   AGE
replicaset.apps/hello-joker-1692835125-59bb5b9985   3         3         3       29m
```

We are now familiar with the basics of Helm which will help us in deploying our ML applications and other applications that will be used for monitoring and deploying other ML tooling. Helm charts offer a seamless path towards simplified management, versioning, and sharing of complicated applications by bundling applications, configurations, and dependencies into a single, coherent unit.

### 3.2.7 Conclusion

We should now be able to containerize our applications using Docker and deploy them on Kubernetes. Kubernetes is a vast topic to cover and requires its own book (Kubernetes in Action is one such book), however, the topics presented above should be a good starting point.

As a container orchestrator, Kubernetes not only enables us to automate deployments but also helps us as machine learning engineers to set up complicated applications with ease. When it comes to deploying and managing machine learning (ML) workloads, Kubernetes has several benefits to offer. Its properties are especially well suited for ML applications because of their dynamic and resource-intensive nature. Workloads for machine learning frequently demand a lot of computing power. Kubernetes makes it possible to scale and manage resources effectively, ensuring that ML models have access to the necessary computing power for training and inferring.

Machine learning workload deployment, scalability, and management are made simpler by Kubernetes. Data science and engineering teams can concentrate on creating models and fostering innovation as a result of its characteristics, which improve resource efficiency, flexibility, and maintainability.

## 3.3 Continuous Integration And Deployment

In the previous sections, we were able to build an image and deploy it on Kubernetes. We however did the image building and deployment manually. An application code changes frequently during its lifetime, multiple people will interact with the application’s code, and allowing manual deployments for applications in production can cause multiple issues. It’s possible that we can specify the wrong image tag and end up deploying the wrong application version. Additionally, it is conceivable for a user's local deployment attempt to overwrite the most recent deployment, which would cause the program to stop functioning properly. It would be better if we could automate this process by using a Continuous Integration (CI) and Continuous Deployment (CD) job. Continuous Integration (CI) and Continuous Deployment (CD) are widely adopted industry practices in software development. They are key components of modern software development and release workflows. One might have heard of these terms in software engineering landscape. The same principles can also be applied for deploying ML applications.

The CI job would test, build, and update a helm chart. Whereas a CD job would deploy the updated helm chart with the newly built image tag. The CD tool would also monitor the deployed application and ensure it matches the image tag of the most recently built image. This is useful in those cases where if someone unintentionally deploys an older version of an application, the CD tool that has been monitoring that deployment can correct it and replace it with the newly built deployment. This ensures a single source of truth for our deployed application. For the CI job, we would use Gitlab CI and for the CD job, we would be using Argo CD.

### 3.3.1 Gitlab CI

One of the main goals of CI is to automate software deployment, preferably after running certain unit/integration tests. This helps us to both deploy and identify bugs faster. A CI job more often than not is triggered after every commit to a Git repo. Gitlab is one of the popular Git repositories which many organizations use. It provides an easy way in which a CI job can be written.

We can do a lot with CI jobs. One of the most common use cases for CI is testing code, building Docker images, and triggering deployments. Python offers various packages for unit testing of code. We have already seen how Docker images are built in section 1.1 of this chapter. In most cases, a deployment is only triggered by building a new image.

We will be automating the build of our Fast API application which responds with random jokes. We will first move the code over to a Gitlab repo.

To set up the Gitlab CI project we need to sign up by going here - [https://about.gitlab.com/free-trial/](https://about.gitlab.com/free-trial/). Please enter the provided details and and name the group and project of your first project as learn-mlops and gitlab-ci-example respectively

![Figure 3.8 Create a Project In Gitlab by specifying a project and group name](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/03__image017.png)

Then proceed to push our repo to GitLab by running

##### Listing 3.12 Pushing project repo to Gitlab

```
rm -rf .git
git init --initial-branch=main    #A
git remote add origin git@gitlab.com:youraccount/project_name.git    #B
git add .    #C
git commit -m "Initial commit"    #D
git push -u origin main     #E
```

Let us take a closer look at the CI job for our Fast API Python application (Listing 3.12). The CI job is specified in .gitlab-ci.yml. The CI job would test the Python application, build the Docker image and push the Docker image to Docker hub, and update the Helm chart with the newly built image tag. Ensure you have set up your Docker and Docker hub before trying this (See section 1.1).

The CI has three stages: test, build, and update. Think of a stage as a step in a pipeline. These stages are listed under the stages node of the .gitlab-ci.yaml. Each stage has a job, and all the jobs in a stage run concurrently. The job under the test stage called test_code is running the unit tests, we build a docker image under the build stage’s job called build_image and update our helm chart in the update stage’s job update_helm_chart. Under each job, we specify the scripts that need to run and we can also specify the Docker image we would want these scripts to be executed. All Gitlab-CI jobs have predefined variables available when running the CI job. These variables include CI_PROJECT_DIR, and CI_COMMIT_SHA (a complete list is available at [https://docs.gitlab.com/ee/ci/variables/predefined_variables.html](https://docs.gitlab.com/ee/ci/variables/predefined_variables.html)). CI_PROJECT_DIR refers to the root directory of the Git repository, and CI_COMMIT_SHA refers to the Git commit ID that triggered the CI job. We can also define our environment variables such as DOCKER_PASSWORD, and DOCKER_USERNAME under CI/CD variables which are accessible under project settings> CI/CD > variables. This is useful when we have to store some credentials for login purposes or any other build environment arguments.

![Figure 3.9 Creating Gitlab CI variables by accessing Project Settings > CI/CD and clicking on variables](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/03__image019.png)

We also need to create an access token so that we can push the updated helm chart back to our repo. An access token helps us to programmatically Git push the updated Helm chart. We would use it in the update stage of the Gitlab CI job. To create an access token we need to access user settings followed by Access Tokens from the navigation bar and then add a new token, the scopes should be set to API. Copy the value of the token before refreshing the page as the token won't be available afterwards.

![Figure 3.10 Click on the user profile pic to access user settings. Then proceed to access token > Add new token to create access token.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/03__image021.png)

The script of the test_code job of stage test runs pytest to run unit tests of the application. We then have the script of the build_image job of the build stage which builds and pushes the Docker image to our personal Dockerhub container registry, the image tag is the shortened Git commit ID obtained from the predefined CI_COMMIT_SHA variable. This is followed by the script of update_helm_chart job of the update stage where we update the helm chart image tag by using a command line utility called yq ([https://github.com/mikefarah/yq](https://github.com/mikefarah/yq)) which modifies the values.yaml file. We clone the repo, modify the yaml, and push the updated yaml back to the repository. We make use of the environment variables like GITLAB_USER_EMAIL, GITLAB_USER_NAME, and GITLAB_ACCESS_TOKEN which we defined under CI/CD variables.

If the test_code job fails then the CI job does not proceed to the next stages, it will instead notify the CI owner informing them of the CI failure.

Whenever we push code changes in the repo the CI job would run. We can test this out by making a small code change and pushing it to our Gitlab repo.

##### Listing 3.13 Gitlab CI Example

```bash
image: docker:20.10.16
variables:
  DOCKER_TLS_CERTDIR: "/certs"
stages:    #B
  - test
  - build
  - update
services:    #C
  - docker:20.10.16-dind    #A
test_code:    #D
    stage: test
    image:
      name: python:3.10
    script:
      - echo "testing code"
      - pip install -r $CI_PROJECT_DIR/requirements.txt
      - pytest $CI_PROJECT_DIR/
 
build_image:    #E
    stage: build
    script:
      - echo "building docker image"
      - cd $CI_PROJECT_DIR
      - echo ${CI_COMMIT_SHA:0:8}
      - docker build . -t varunmallya/hello-joker:${CI_COMMIT_SHA:0:8}
      - docker login -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD}
      - docker push varunmallya/hello-joker:${CI_COMMIT_SHA:0:8}
 update_helm_chart:    #F
    stage: update
    image:
      name: python:3.10
    script:
      - apt-get update && apt-get install git
      - git clone https://${GITLAB_USER_NAME}:${GITLAB_ACCESS_TOKEN}@gitlab.com/learn-mlops/gitlab-ci-example.git    #G
      - cd $CI_PROJECT_DIR
      - wget https://github.com/mikefarah/yq/releases/download/v4.2.0/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq    #H
      - git config --global user.email "${GITLAB_USER_EMAIL}"
      - git config --global user.name "${GITLAB_USER_NAME}"
      - yq e -i ".image.tag |= \"${CI_COMMIT_SHA:0:8}\""  hello-joker/values.yaml    #I
      - git add hello-joker/values.yaml
      - git commit -m "[skip ci]Update helm chart ${CI_COMMIT_SHA:0:8}"    #J
      - git push https://${GITLAB_USER_NAME}:${GITLAB_ACCESS_TOKEN}@gitlab.com/learn-mlops/gitlab-ci-example.git HEAD:main    #K
```

Our project directory structure would look like this with .gitlab-ci.yaml. The test_main.py consists of the unit tests for our application.

```
├── Dockerfile
├── entrypoint.sh
├── main.py
├── test_main.py
└── hello-joker
├── .gitlab-ci.yaml
└── requirements.txt
```

We can test the Gitlab CI job locally by using the Gitlab runner. First, we install Gitlab runner by running the installation commands given below.

For Ubuntu/Debian, replace arch with your Linux kernel architecture

```
curl -LJO "https://gitlab-runner-downloads.s3.amazonaws.com/latest/deb/gitlab-runner_${arch}.deb"
dpkg -i gitlab-runner_<arch>.deb
```

In Mac OS

```
brew install gitlab-runner
```

Then we can test the individual jobs by running

```
gitlab-runner exec shell test_code
```

This will run pytest in our local shell. We can trigger the pipeline in Gitlab CI by clicking on the CI/CD -> Pipeline and Run Pipeline tab on the project home page and then clicking on Run Pipeline

![Figure 3.11 Running Gitlab CI pipeline by clicking on run pipeline and monitoring pipeline status in the UI](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/03__image023.png)

Using Gitlab CI we were able to automate testing, building and pushing of Docker images, and updating the Helm Chart. The updated Helm chart would be monitored by our CD tool which would do the actual deployment.

### 3.3.2 Argo CD

ArgoCD, apart from being a continuous delivery tool, also helps to ensure that our git repo code and our code running in production are synced. This is done by continuously monitoring the Git repo and our deployed application. If we push a new commit to our Git repo, Argo CD ensures that this change is pushed over to production. If anyone changes the application in production, Argo CD will check the Git repo to ensure these changes are consistent with the changes in the repo. If not the changes will rollback to whatever is there in Git. Our code in Git is the only source of truth for Argo CD.

![Figure 3.12 Argo CD ensures that the manifests in Git and the ones deployed in K8s match.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/03__image025.png)

To set up Argo CD follow the steps given in appendix A.

Once set up we then log in to Argo CD click on Settings -> Repositories and add our repo, ensuring the connection method is via https. Add the necessary information like username and password etc.

![Figure 3.13 Setting up Git repo in Argo by using https authentication.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/03__image027.png)

Our CD job should deploy the Helm chart our CI job was updated in the previous section. Argo CD is given the repo location to our Helm chart and this Helm chart serves as its source of truth. We do this by clicking on the home page followed by Applications -> New App. Enter the application name, and set the project name as default. Set up Repository URL, target revision can be a branch or by default is set to HEAD. Path specifies the location in the repository which has the Helm chart. Select the cluster URL and namespace. If the namespace does not exist, create it, we have created a namespace called online-ml-svc. Then click on Create, wait for some time and then click on Sync. Once the application is synced we should see something like this

![Figure 3.14 Joker application which has synced in Argo CD. We can see the status is healthy and synced.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/03__image029.png)

Test it out by port forwarding to the fast API service.

```bash
kubectl port-forward svc/fast-api-app -n online-ml-svc 8081:8080
```

Access locahost:8081 from your browser and you should see a random joke

```json
{"random_joke":"Unix is user friendly. It's just very particular about who its friends are."}
```

Now that the application is deployed, let us try modifying the service type from Cluster Ip to LoadBalancer.

```bash
kubectl edit svc fast-api-app -n online-ml-svc
```

Set type to

```
type: LoadBalancer
```

You will now see that the application is out of sync. If you click on the svc fast api and click on diff you will see that the difference between live manifest and expected manifest is the type of service.

Hence we can see that Argo-CD continuously keeps track of the deployed resources and ensures that the git repo manifests are the only source of truth. If we enable auto sync Argo CD would automatically sync with the manifests in the git repository.

By using CI/CD tools we were able to automate the deployment steps of our application and ensure that our application in production has one source of truth: our Git repo. Gitlab CI and Argo CD documentation provides more information on writing CI and CD jobs respectively.

## 3.4 Prometheus And Grafana

Any application deployed in production needs to be monitored. Logging is what most of us are familiar with when we try to monitor our application run. Logs are very useful when we wish to debug any of our application logic. However what if we wish to answer questions like how many requests our endpoint received in the last 1 hour. What percentage of our requests had a response time of less than 2 seconds? To answer questions like this we need to collect metrics. Metrics are used to track the performance of an application, These metrics are usually visualised in a dashboard and we can also set up alerts if necessary. Some of the most common alerts for a web application include an alert to see if the application is up or down, an alert if the 95th percentile response time is more than a threshold, an alert if the number of requests to a service drops below a certain threshold, etc. Think of metrics as an extension of logging, as we develop our application we will add logs to monitor certain conditions similarly we also add metrics to answer the above questions.

Prometheus is a monitoring tool that throws light on our applications and gives us higher visibility. It has three main components -

- A time series database where metrics are indexed by time, which makes metric retrieval easier
- A worker who performs scraping of the metrics and stores them in the time series database
- A UI component for visualizing metrics
- An alert manager which can be used to route alerts to a different channel (email, push notification etc)

The Prometheus UI is a tool that we can use to quickly check if our metrics are being scraped or not from our service but it's not that useful if we wish to build any dashboards as such. For that, we would want to use another open-source tool called Grafana.

Grafana is a dashboarding tool mainly used to track application metrics. It integrates well with Prometheus and many other data sources. Grafana provides us with text boxes to input a query, if Prometheus is our data source we would write queries that would retrieve data from Prometheus’s time series database and visualize the results in a pretty-looking chart.

To make metrics available to Prometheus we have to set up an endpoint in our application from which the Prometheus worker can scrape metrics. Prometheus is a pull-based metrics system; we have predefined language-specific packages to define metrics.

The applications we wish to monitor would have an endpoint such as /metrics or something similar. A Prometheus worker would scrape this metric and store it in the time series database. We would normally use Grafana to visualize this data by writing queries in a Prometheus-based query language called PromQL. If we wish to set up some alerts we would do that by modifying the config of the alert manager through which we can route alerts to the necessary channels such as email.

![Figure 3.15 Application 1 and Application 2 are exposing an endpoint for metrics. Prometheus is scraping those metrics. These metrics are visualized by Grafana. Alertmanager uses those metrics to check if any alerts need to be triggered to a channel, in this case, its an Email.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/03__image031.png)

We can install Prometheus and Grafana utilizing Helm charts. To install both we need to run certain helm commands

##### Listing 3.14 Installing Prometheus And Grafana

```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts    #A
helm upgrade -i prometheus prometheus-community/prometheus -namespace prometheus --create-namespace    #B
helm repo add grafana https://grafana.github.io/helm-charts    #C
helm repo update    #D
helm install grafana grafana/grafana  -namespace grafana --create-namespace  -set persistence.enabled=true  -set adminPassword='adminpassword' -set datasources."datasources\.yaml".apiVersion=1   -set datasources."datasources\.yaml".datasources[0].name=Prometheus  -set datasources."datasources\.yaml".datasources[0].type=prometheus    -set datasources."datasources\.yaml".datasources[0].url=http://prometheus-server.prometheus.svc.cluster.local     -set datasources."datasources\.yaml".datasources[0].access=proxy     -set datasources."datasources\.yaml".datasources[0].isDefault=true    #D
```

When we install Grafana we are also setting up the Prometheus data source along with the admin password which can be used to login to Grafana.

Now that we have set up Grafana. Let us extend our Fast APi joker application with a metrics endpoint for Prometheus to scrape metrics from and create a simple chart in Grafana where we can visualize a metric.

We would be using a utility called exporter to make basic metrics such as response times and number of requests available at /metrics endpoint. For Fast APi there are pre-built exporters like starlette_exporter which can be configured to expose the basic metrics. We add the starlette exporter provided Prometheus Middleware to our app and prepare /metrics endpoint for handling metrics.

##### Listing 3.15 Fast API app with Prometheus metrics available at /metrics endpoint

```
from fastapi import FastAPI
from starlette_exporter import PrometheusMiddleware, handle_metrics
import pyjokes
 
app = FastAPI()
app.add_middleware(PrometheusMiddleware)    #A
app.add_route("/metrics", handle_metrics)    #B
 
@app.get("/")
async def root():
    random_joke = pyjokes.get_joke("en","neutral")
    return {"random_joke": random_joke}
```

Adding two lines of code we were able to set up basic monitoring for our application. When you run this code locally you can hit /metrics endpoint and see the names of Prometheus metrics there along with their values.

The metric by the name starlette_requests_total is of type counter and is basically used to count. In this case, it is counting the number of requests. A counter value can only go up. Then we have a metric-type gauge that can go both up and down, useful for measuring memory consumption. For measuring the 95th percentile of response time we could use the metric of type histogram. Histograms mainly work as counters but we have pre-defined buckets (or bins) in which we count, similar to how a histogram works. Using these counts we can report important response time metrics.

![Figure 3.16 Prometheus Metrics available at /metrics endpoint](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/03__image033.png)

We can even define our own custom metrics for this, we just need to use the Prometheus client library. We can set up a counter by defining it first

```
TEST_COUNTER = Counter("test","a simple test_counter")
```

Then we can increment this counter value in our application by calling its inc method

```
TEST_COUNTER.inc()
```

After defining our metrics we can ensure they are working as expected by calling the local /metrics endpoint. However, we must make these metrics available in Prometheus so that we can visualize them in Grafana. To do so, we need to dockerize and deploy this application in our K8s cluster where we have already deployed Prometheus and Grafana.

Prometheus uses a service called service discovery to check for any new applications from where metrics can be scraped from, by default we have to specify three annotations in our pod.

```
annotations:
        prometheus.io/scrape: 'true'
        prometheus.io/path: '/metrics'
        prometheus.io/port: '80
```

Once we deploy this application we could see if Prometheus can retrieve these application metrics by visiting the Prometheus UI. We click on Status -> Targets.

![Figure 3.17 Prometheus targets](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/03__image035.png)

We can see that Prometheus can scrape the metrics. We can even try out a simple query in the UI. We just copy one of the metrics in the graph expression input field.

![Figure 3.18 Writing Prometheus Query in the Prometheus UI. It will return the metrics values based on the query. An easy way to check if the metrics are being scraped and if the values are as expected.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/03__image037.png)

We should be able to see the metric along with its value.

Let us visualize this metric in Grafana as a time series plot. For this we have to log in to Grafana. Create a new dashboard followed by an empty panel. Here we select the time chart, by default it should be a time series. We would want to get a time series chart of the number of requests seen in the last 10 minutes. We can retrieve this by running a PromQL query. Sum by is used to group the time series based on the HTTP response code, increase is used to calculate the increase in the time series in the range vector. Sum by and Increase are examples of PromQL functions. Other functions are available at [https://prometheus.io/docs/prometheus/latest/querying/functions/#increase](https://prometheus.io/docs/prometheus/latest/querying/functions/#increase)

```
sum by (response_code) (increase(starlette_requests_total{app_name="starlette",method="GET",path="/"}[10m]))
```

This chart would look something like this

![Figure 3.19 Time series chart in Grafana which shows the number of requests seen in the last ten minutes. Only one line is seen here as there was only one HTTP status code for all responses.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/03__image039.png)

We can now store metrics in Prometheus and visualize it in Grafana. Prometheus documentation ([https://prometheus.io/docs/introduction/overview/](https://prometheus.io/docs/introduction/overview/)) contains examples of PromQL, it also describes ways in which batch jobs can push metrics if required, using Prometheus pushgateway. Grafana documentation sheds more light on building dashboards and the different types of charts we can create. Grafana can also interact with other data sources apart from Prometheus. The information for which can be found at [https://grafana.com/docs/grafana/latest/](https://grafana.com/docs/grafana/latest/).

## 3.5 Summary

- Having a working knowledge of some DevOps tooling that deals with automation, deployment, and monitoring is important while working on an ML Platform.
- Docker can be used to containerize applications which can then be deployed in any environment.
- Kubernetes acts as a container orchestrator which helps to manage containers in a production.
- Automating container builds and deployments using CI/CD tooling reduces manual errors, accelerates development cycles, and ensures that changes are consistently tested and deployed.
- Monitoring applications helps in maintaining the reliability and performance of our applications deployed in production.
- Tools serve as a means to an end. The effectiveness of tools depends on how well they are selected, integrated, and used to support the larger aims and aspirations of the organizations.
