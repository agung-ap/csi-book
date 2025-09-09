# Chapter 18. Extending Kubernetes

### **This chapter covers**

- Adding custom objects to Kubernetes
- Creating a controller for the custom object
- Adding custom API servers
- Self-provisioning of services with the Kubernetes Service Catalog
- Red Hat’s OpenShift Container Platform
- Deis Workflow and Helm

You’re almost done. To wrap up, we’ll look at how you can define your own API objects and create controllers for those objects. We’ll also look at how others have extended Kubernetes and built Platform-as-a-Service solutions on top of it.

## 18.1. Defining custom API objects

Throughout the book, you’ve learned about the API objects that Kubernetes provides and how they’re used to build application systems. Currently, Kubernetes users mostly use only these objects even though they represent relatively low-level, generic concepts.

As the Kubernetes ecosystem evolves, you’ll see more and more high-level objects, which will be much more specialized than the resources Kubernetes supports today. Instead of dealing with Deployments, Services, ConfigMaps, and the like, you’ll create and manage objects that represent whole applications or software services. A custom controller will observe those high-level objects and create low-level objects based on them. For example, to run a messaging broker inside a Kubernetes cluster, all you’ll need to do is create an instance of a Queue resource and all the necessary Secrets, Deployments, and Services will be created by a custom Queue controller. Kubernetes already provides ways of adding custom resources like this.

### 18.1.1. Introducing CustomResourceDefinitions

To define a new resource type, all you need to do is post a CustomResourceDefinition object (CRD) to the Kubernetes API server. The CustomResourceDefinition object is the description of the custom resource type. Once the CRD is posted, users can then create instances of the custom resource by posting JSON or YAML manifests to the API server, the same as with any other Kubernetes resource.

---

##### Note

Prior to Kubernetes 1.7, custom resources were defined through ThirdPartyResource objects, which were similar to CustomResourceDefinitions, but were removed in version 1.8.

---

Creating a CRD so that users can create objects of the new type isn’t a useful feature if those objects don’t make something tangible happen in the cluster. Each CRD will usually also have an associated controller (an active component doing something based on the custom objects), the same way that all the core Kubernetes resources have an associated controller, as was explained in [chapter 11](/book/kubernetes-in-action/chapter-11/ch11). For this reason, to properly show what CustomResourceDefinitions allow you to do other than adding instances of a custom object, a controller must be deployed as well. You’ll do that in the next example.

##### Introducing the example CustomResourceDefinition

Let’s imagine you want to allow users of your Kubernetes cluster to run static websites as easily as possible, without having to deal with Pods, Services, and other Kubernetes resources. What you want to achieve is for users to create objects of type Website that contain nothing more than the website’s name and the source from which the website’s files (HTML, CSS, PNG, and others) should be obtained. You’ll use a Git repository as the source of those files. When a user creates an instance of the Website resource, you want Kubernetes to spin up a new web server pod and expose it through a Service, as shown in [figure 18.1](/book/kubernetes-in-action/chapter-18/ch18fig01).

![Figure 18.1. Each Website object should result in the creation of a Service and an HTTP server Pod.](https://drek4537l1klr.cloudfront.net/luksa/Figures/18fig01_alt.jpg)

To create the Website resource, you want users to post manifests along the lines of the one shown in the following listing.

##### Listing 18.1. An imaginary custom resource: imaginary-kubia-website.yaml

```yaml
kind: Website
metadata:
  name: kubia
spec:
  gitRepo: https://github.com/luksa/kubia-website-example.git
```

Like all other resources, your resource contains a `kind` and a `metadata.name` field, and like most resources, it also contains a `spec` section. It contains a single field called `gitRepo` (you can choose the name)—it specifies the Git repository containing the website’s files. You’ll also need to include an `apiVersion` field, but you don’t know yet what its value must be for custom resources.

If you try posting this resource to Kubernetes, you’ll receive an error because Kubernetes doesn’t know what a Website object is yet:

```bash
$ kubectl create -f imaginary-kubia-website.yaml
error: unable to recognize "imaginary-kubia-website.yaml": no matches for
➥  /, Kind=Website
```

Before you can create instances of your custom object, you need to make Kubernetes recognize them.

##### Creating a CustomResourceDefinition object

To make Kubernetes accept your custom Website resource instances, you need to post the CustomResourceDefinition shown in the following listing to the API server.

##### Listing 18.2. A CustomResourceDefinition manifest: website-crd.yaml

```yaml
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: websites.extensions.example.com
spec:
  scope: Namespaced
  group: extensions.example.com
  version: v1
  names:

    kind: Website

    singular: website

    plural: websites
```

After you post the descriptor to Kubernetes, it will allow you to create any number of instances of the custom Website resource.

You can create the CRD from the website-crd.yaml file available in the code archive:

```bash
$ kubectl create -f website-crd-definition.yaml
customresourcedefinition "websites.extensions.example.com" created
```

I’m sure you’re wondering about the long name of the CRD. Why not call it Website? The reason is to prevent name clashes. By adding a suffix to the name of the CRD (which will usually include the name of the organization that created the CRD), you keep CRD names unique. Luckily, the long name doesn’t mean you’ll need to create your Website resources with `kind: websites.extensions.example.com`, but as `kind: Website`, as specified in the `names.kind` property of the CRD. The `extensions.example.com` part is the API group of your resource.

You’ve seen how creating Deployment objects requires you to set `apiVersion` to `apps/v1beta1` instead of `v1`. The part before the slash is the API group (Deployments belong to the `apps` API group), and the part after it is the version name (`v1beta1` in the case of Deployments). When creating instances of the custom Website resource, the `apiVersion` property will need to be set to `extensions.example.com/v1`.

##### Creating an instance of a custom resource

Considering what you learned, you’ll now create a proper YAML for your Website resource instance. The YAML manifest is shown in the following listing.

##### Listing 18.3. A custom Website resource: kubia-website.yaml

```yaml
apiVersion: extensions.example.com/v1
kind: Website
metadata:
  name: kubia
spec:
  gitRepo: https://github.com/luksa/kubia-website-example.git
```

The `kind` of your resource is Website, and the `apiVersion` is composed of the API group and the version number you defined in the CustomResourceDefinition.

Create your Website object now:

```bash
$ kubectl create -f kubia-website.yaml
website "kubia" created
```

The response tells you that the API server has accepted and stored your custom Website object. Let’s see if you can now retrieve it.

##### Retrieving instances of a custom resource

List all the websites in your cluster:

```bash
$ kubectl get websites
NAME      KIND
kubia     Website.v1.extensions.example.com
```

As with existing Kubernetes resources, you can create and then list instances of custom resources. You can also use `kubectl describe` to see the details of your custom object, or retrieve the whole YAML with `kubectl get`, as in the following listing.

##### Listing 18.4. Full Website resource definition retrieved from the API server

```bash
$ kubectl get website kubia -o yaml
apiVersion: extensions.example.com/v1
kind: Website
metadata:
  creationTimestamp: 2017-02-26T15:53:21Z
  name: kubia
  namespace: default
  resourceVersion: "57047"
  selfLink: /apis/extensions.example.com/v1/.../default/websites/kubia
  uid: b2eb6d99-fc3b-11e6-bd71-0800270a1c50
spec:
  gitRepo: https://github.com/luksa/kubia-website-example.git
```

Note that the resource includes everything that was in the original YAML definition, and that Kubernetes has initialized additional metadata fields the way it does with all other resources.

##### Deleting an instance of a custom object

Obviously, in addition to creating and retrieving custom object instances, you can also delete them:

```bash
$ kubectl delete website kubia
website "kubia" deleted
```

---

##### Note

You’re deleting an instance of a Website, not the Website CRD resource. You could also delete the CRD object itself, but let’s hold off on that for a while, because you’ll be creating additional Website instances in the next section.

---

Let’s go over everything you’ve done. By creating a CustomResourceDefinition object, you can now store, retrieve, and delete custom objects through the Kubernetes API server. These objects don’t do anything yet. You’ll need to create a controller to make them do something.

In general, the point of creating custom objects like this isn’t always to make something happen when the object is created. Certain custom objects are used to store data instead of using a more generic mechanism such as a ConfigMap. Applications running inside pods can query the API server for those objects and read whatever is stored in them.

But in this case, we said you wanted the existence of a Website object to result in the spinning up of a web server serving the contents of the Git repository referenced in the object. We’ll look at how to do that next.

### 18.1.2. Automating custom resources with custom controllers

To make your Website objects run a web server pod exposed through a Service, you’ll need to build and deploy a Website controller, which will watch the API server for the creation of Website objects and then create the Service and the web server Pod for each of them.

To make sure the Pod is managed and survives node failures, the controller will create a Deployment resource instead of an unmanaged Pod directly. The controller’s operation is summarized in [figure 18.2](/book/kubernetes-in-action/chapter-18/ch18fig02).

![Figure 18.2. The Website controller watches for Website objects and creates a Deployment and a Service.](https://drek4537l1klr.cloudfront.net/luksa/Figures/18fig02.jpg)

I’ve written a simple initial version of the controller, which works well enough to show CRDs and the controller in action, but it’s far from being production-ready, because it’s overly simplified. The container image is available at docker.io/luksa/ website-controller:latest, and the source code is at [https://github.com/luksa/k8s-website-controller](https://github.com/luksa/k8s-website-controller). Instead of going through its source code, I’ll explain what the controller does.

##### Understanding what the Website Controller does

Immediately upon startup, the controller starts to watch Website objects by requesting the following URL:

```
http://localhost:8001/apis/extensions.example.com/v1/websites?watch=true
```

You may recognize the hostname and port—the controller isn’t connecting to the API server directly, but is instead connecting to the `kubectl proxy` process, which runs in a sidecar container in the same pod and acts as the ambassador to the API server (we examined the ambassador pattern in [chapter 8](/book/kubernetes-in-action/chapter-8/ch08)). The proxy forwards the request to the API server, taking care of both TLS encryption and authentication (see [figure 18.3](/book/kubernetes-in-action/chapter-18/ch18fig03)).

![Figure 18.3. The Website controller talks to the API server through a proxy (in the ambassador container).](https://drek4537l1klr.cloudfront.net/luksa/Figures/18fig03_alt.jpg)

Through the connection opened by this HTTP GET request, the API server will send watch events for every change to any Website object.

The API server sends the `ADDED` watch event every time a new Website object is created. When the controller receives such an event, it extracts the Website’s name and the URL of the Git repository from the Website object it received in the watch event and creates a Deployment and a Service object by posting their JSON manifests to the API server.

The Deployment resource contains a template for a pod with two containers (shown in [figure 18.4](/book/kubernetes-in-action/chapter-18/ch18fig04)): one running an nginx server and another one running a gitsync process, which keeps a local directory synced with the contents of a Git repo. The local directory is shared with the nginx container through an `emptyDir` volume (you did something similar to that in [chapter 6](/book/kubernetes-in-action/chapter-6/ch06), but instead of keeping the local directory synced with a Git repo, you used a `gitRepo` volume to download the Git repo’s contents at pod startup; the volume’s contents weren’t kept in sync with the Git repo afterward). The Service is a `NodePort` Service, which exposes your web server pod through a random port on each node (the same port is used on all nodes). When a pod is created by the Deployment object, clients can access the website through the node port.

![Figure 18.4. The pod serving the website specified in the Website object](https://drek4537l1klr.cloudfront.net/luksa/Figures/18fig04.jpg)

The API server also sends a `DELETED` watch event when a Website resource instance is deleted. Upon receiving the event, the controller deletes the Deployment and the Service resources it created earlier. As soon as a user deletes the Website instance, the controller will shut down and remove the web server serving that website.

---

##### Note

My oversimplified controller isn’t implemented properly. The way it watches the API objects doesn’t guarantee it won’t miss individual watch events. The proper way to watch objects through the API server is to not only watch them, but also periodically re-list all objects in case any watch events were missed.

---

##### Running the controller as a pod

During development, I ran the controller on my local development laptop and used a locally running `kubectl proxy` process (not running as a pod) as the ambassador to the Kubernetes API server. This allowed me to develop quickly, because I didn’t need to build a container image after every change to the source code and then run it inside Kubernetes.

When I’m ready to deploy the controller into production, the best way is to run the controller inside Kubernetes itself, the way you do with all the other core controllers. To run the controller in Kubernetes, you can deploy it through a Deployment resource. The following listing shows an example of such a Deployment.

##### Listing 18.5. A Website controller Deployment: website-controller.yaml

```yaml
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: website-controller
spec:
  replicas: 1
  template:
    metadata:
      name: website-controller
      labels:
        app: website-controller
    spec:
      serviceAccountName: website-controller
      containers:
      - name: main
        image: luksa/website-controller
      - name: proxy
        image: luksa/kubectl-proxy:1.6.2
```

As you can see, the Deployment deploys a single replica of a two-container pod. One container runs your controller, whereas the other one is the ambassador container used for simpler communication with the API server. The pod runs under its own special ServiceAccount, so you’ll need to create it before you deploy the controller:

```bash
$ kubectl create serviceaccount website-controller
serviceaccount "website-controller" created
```

If Role Based Access Control (RBAC) is enabled in your cluster, Kubernetes will not allow the controller to watch Website resources or create Deployments or Services. To allow it to do that, you’ll need to bind the `website-controller` ServiceAccount to the `cluster-admin` ClusterRole, by creating a ClusterRoleBinding like this:

```bash
$ kubectl create clusterrolebinding website-controller
➥  --clusterrole=cluster-admin
➥  --serviceaccount=default:website-controller
clusterrolebinding "website-controller" created
```

Once you have the ServiceAccount and ClusterRoleBinding in place, you can deploy the controller’s Deployment.

##### Seeing the controller in action

With the controller now running, create the `kubia` Website resource again:

```bash
$ kubectl create -f kubia-website.yaml
website "kubia" created
```

Now, let’s check the controller’s logs (shown in the following listing) to see if it has received the watch event.

##### Listing 18.6. Displaying logs of the Website controller

```bash
$ kubectl logs website-controller-2429717411-q43zs -c main
2017/02/26 16:54:41 website-controller started.
2017/02/26 16:54:47 Received watch event: ADDED: kubia: https://github.c...
2017/02/26 16:54:47 Creating services with name kubia-website in namespa...
2017/02/26 16:54:47 Response status: 201 Created
2017/02/26 16:54:47 Creating deployments with name kubia-website in name...
2017/02/26 16:54:47 Response status: 201 Created
```

The logs show that the controller received the `ADDED` event and that it created a Service and a Deployment for the `kubia-website` Website. The API server responded with a `201 Created` response, which means the two resources should now exist. Let’s verify that the Deployment, Service and the resulting Pod were created. The following listing lists all Deployments, Services and Pods.

##### Listing 18.7. The Deployment, Service, and Pod created for the `kubia-website`

```bash
$ kubectl get deploy,svc,po
NAME                        DESIRED   CURRENT   UP-TO-DATE   AVAILABLE  AGE
deploy/kubia-website        1         1         1            1          4s
deploy/website-controller   1         1         1            1          5m

NAME                CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
svc/kubernetes      10.96.0.1      <none>        443/TCP        38d
svc/kubia-website   10.101.48.23   <nodes>       80:32589/TCP   4s

NAME                                     READY     STATUS    RESTARTS   AGE
po/kubia-website-1029415133-rs715        2/2       Running   0          4s
po/website-controller-1571685839-qzmg6   2/2       Running   1          5m
```

There they are. The `kubia-website` Service, through which you can access your website, is available on port `32589` on all cluster nodes. You can access it with your browser. Awesome, right?

Users of your Kubernetes cluster can now deploy static websites in seconds, without knowing anything about Pods, Services, or any other Kubernetes resources, except your custom Website resource.

Obviously, you still have room for improvement. The controller could, for example, watch for Service objects and as soon as the node port is assigned, write the URL the website is accessible at into the `status` section of the Website resource instance itself. Or it could also create an Ingress object for each website. I’ll leave the implementation of these additional features to you as an exercise.

### 18.1.3. Validating custom objects

You may have noticed that you didn’t specify any kind of validation schema in the Website CustomResourceDefinition. Users can include any field they want in the YAML of their Website object. The API server doesn’t validate the contents of the YAML (except the usual fields like `apiVersion`, `kind`, and `metadata`), so users can create invalid Website objects (without a `gitRepo` field, for example).

Is it possible to add validation to the controller and prevent invalid objects from being accepted by the API server? It isn’t, because the API server first stores the object, then returns a success response to the client (`kubectl`), and only then notifies all the watchers (the controller is one of them). All the controller can really do is validate the object when it receives it in a watch event, and if the object is invalid, write the error message to the Website object (by updating the object through a new request to the API server). The user wouldn’t be notified of the error automatically. They’d have to notice the error message by querying the API server for the Website object. Unless the user does this, they have no way of knowing whether the object is valid or not.

This obviously isn’t ideal. You’d want the API server to validate the object and reject invalid objects immediately. Validation of custom objects was introduced in Kubernetes version 1.8 as an alpha feature. To have the API server validate your custom objects, you need to enable the `CustomResourceValidation` feature gate in the API server and specify a JSON schema in the CRD.

### 18.1.4. Providing a custom API server for your custom objects

A better way of adding support for custom objects in Kubernetes is to implement your own API server and have the clients talk directly to it.

##### Introducing API server aggregation

In Kubernetes version 1.7, you can integrate your custom API server with the main Kubernetes API server, through API server aggregation. Initially, the Kubernetes API server was a single monolithic component. From Kubernetes version 1.7, multiple aggregated API servers will be exposed at a single location. Clients can connect to the aggregated API and have their requests transparently forwarded to the appropriate API server. This way, the client wouldn’t even be aware that multiple API servers handle different objects behind the scenes. Even the core Kubernetes API server may eventually end up being split into multiple smaller API servers and exposed as a single server through the aggregator, as shown in [figure 18.5](/book/kubernetes-in-action/chapter-18/ch18fig05).

![Figure 18.5. API server aggregation](https://drek4537l1klr.cloudfront.net/luksa/Figures/18fig05_alt.jpg)

In your case, you could create an API server responsible for handling your Website objects. It could validate those objects the way the core Kubernetes API server validates them. You’d no longer need to create a CRD to represent those objects, because you’d implement the Website object type into the custom API server directly.

Generally, each API server is responsible for storing their own resources. As shown in [figure 18.5](/book/kubernetes-in-action/chapter-18/ch18fig05), it can either run its own instance of etcd (or a whole etcd cluster), or it can store its resources in the core API server’s etcd store by creating CRD instances in the core API server. In that case, it needs to create a CRD object first, before creating instances of the CRD, the way you did in the example.

##### Registering a custom API server

To add a custom API server to your cluster, you’d deploy it as a pod and expose it through a Service. Then, to integrate it into the main API server, you’d deploy a YAML manifest describing an APIService resource like the one in the following listing.

##### Listing 18.8. An `APIService` YAML definition

```yaml
apiVersion: apiregistration.k8s.io/v1beta1
kind: APIService
metadata:
  name: v1alpha1.extensions.example.com
spec:
  group: extensions.example.com
  version: v1alpha1
  priority: 150
  service:
    name: website-api
    namespace: default
```

After creating the APIService resource from the previous listing, client requests sent to the main API server that contain any resource from the `extensions.example.com` API group and version `v1alpha1` would be forwarded to the custom API server pod(s) exposed through the `website-api` Service.

##### Creating custom clients

While you can create custom resources from YAML files using the regular `kubectl` client, to make deployment of custom objects even easier, in addition to providing a custom API server, you can also build a custom CLI tool. This will allow you to add dedicated commands for manipulating those objects, similar to how `kubectl` allows creating Secrets, Deployments, and other resources through resource-specific commands like `kubectl create secret` or `kubectl create deployment`.

As I’ve already mentioned, custom API servers, API server aggregation, and other features related to extending Kubernetes are currently being worked on intensively, so they may change after the book is published. To get up-to-date information on the subject, refer to the Kubernetes GitHub repos at [http://github.com/kubernetes](http://github.com/kubernetes).

## 18.2. Extending Kubernetes with the Kubernetes Service Catalog

One of the first additional API servers that will be added to Kubernetes through API server aggregation is the Service Catalog API server. The Service Catalog is a hot topic in the Kubernetes community, so you may want to know about it.

Currently, for a pod to consume a service (here I use the term generally, not in relation to Service resources; for example, a database service includes everything required to allow users to use a database in their app), someone needs to deploy the pods providing the service, a Service resource, and possibly a Secret so the client pod can use it to authenticate with the service. That someone is usually the same user deploying the client pod or, if a team is dedicated to deploying these types of general services, the user needs to file a ticket and wait for the team to provision the service. This means the user needs to either create the manifests for all the components of the service, know where to find an existing set of manifests, know how to configure it properly, and deploy it manually, or wait for the other team to do it.

But Kubernetes is supposed to be an easy-to-use, self-service system. Ideally, users whose apps require a certain service (for example, a web application requiring a backend database), should be able to say to Kubernetes. “Hey, I need a PostgreSQL database. Please provision one and tell me where and how I can connect to it.” This will soon be possible through the Kubernetes Service Catalog.

### 18.2.1. Introducing the Service Catalog

As the name suggests, the Service Catalog is a catalog of services. Users can browse through the catalog and provision instances of the services listed in the catalog by themselves without having to deal with Pods, Services, ConfigMaps, and other resources required for the service to run. You’ll recognize that this is similar to what you did with the Website custom resource.

Instead of adding custom resources to the API server for each type of service, the Service Catalog introduces the following four generic API resources:

- A ClusterServiceBroker, which describes an (external) system that can provision services
- A ClusterServiceClass, which describes a type of service that can be provisioned
- A ServiceInstance, which is one instance of a service that has been provisioned
- A ServiceBinding, which represents a binding between a set of clients (pods) and a ServiceInstance

The relationships between those four resources are shown in the [figure 18.6](/book/kubernetes-in-action/chapter-18/ch18fig06) and explained in the following paragraphs.

![Figure 18.6. The relationships between Service Catalog API resources.](https://drek4537l1klr.cloudfront.net/luksa/Figures/18fig06_alt.jpg)

In a nutshell, a cluster admin creates a ClusterServiceBroker resource for each service broker whose services they’d like to make available in the cluster. Kubernetes then asks the broker for a list of services that it can provide and creates a ClusterServiceClass resource for each of them. When a user requires a service to be provisioned, they create an ServiceInstance resource and then a ServiceBinding to bind that Service-Instance to their pods. Those pods are then injected with a Secret that holds all the necessary credentials and other data required to connect to the provisioned ServiceInstance.

The Service Catalog system architecture is shown in [figure 18.7](/book/kubernetes-in-action/chapter-18/ch18fig07).

![Figure 18.7. The architecture of the Service Catalog](https://drek4537l1klr.cloudfront.net/luksa/Figures/18fig07_alt.jpg)

The components shown in the figure are explained in the following sections.

### 18.2.2. Introducing the Service Catalog API server and Controller Manager

Similar to core Kubernetes, the Service Catalog is a distributed system composed of three components:

- Service Catalog API Server
- etcd as the storage
- Controller Manager, where all the controllers run

The four Service Catalog–related resources we introduced earlier are created by posting YAML/JSON manifests to the API server. It then stores them into its own etcd instance or uses CustomResourceDefinitions in the main API server as an alternative storage mechanism (in that case, no additional etcd instance is required).

The controllers running in the Controller Manager are the ones doing something with those resources. They obviously talk to the Service Catalog API server, the way other core Kubernetes controllers talk to the core API server. Those controllers don’t provision the requested services themselves. They leave that up to external service brokers, which are registered by creating ServiceBroker resources in the Service Catalog API.

### 18.2.3. Introducing Service Brokers and the OpenServiceBroker API

A cluster administrator can register one or more external ServiceBrokers in the Service Catalog. Every broker must implement the OpenServiceBroker API.

##### Introducing the OpenServiceBroker API

The Service Catalog talks to the broker through that API. The API is relatively simple. It’s a REST API providing the following operations:

- Retrieving the list of services with `GET /v2/catalog`
- Provisioning a service instance (`PUT /v2/service_instances/:id`)
- Updating a service instance (`PATCH /v2/service_instances/:id`)
- Binding a service instance (`PUT /v2/service_instances/:id/service_bindings/:binding_id`)
- Unbinding an instance (`DELETE /v2/service_instances/:id/service_bindings/:binding_id`)
- Deprovisioning a service instance (`DELETE /v2/service_instances/:id`)

You’ll find the OpenServiceBroker API spec at [https://github.com/openservicebrokerapi/servicebroker](https://github.com/openservicebrokerapi/servicebroker).

##### Registering brokers in the Service Catalog

The cluster administrator registers a broker by posting a ServiceBroker resource manifest to the Service Catalog API, like the one shown in the following listing.

##### Listing 18.9. A ClusterServiceBroker manifest: database-broker.yaml

```yaml
apiVersion: servicecatalog.k8s.io/v1alpha1
kind: ClusterServiceBroker
metadata:
  name: database-broker
spec:
  url: http://database-osbapi.myorganization.org
```

The listing describes an imaginary broker that can provision databases of different types. After the administrator creates the ClusterServiceBroker resource, a controller in the Service Catalog Controller Manager connects to the URL specified in the resource to retrieve the list of services this broker can provision.

After the Service Catalog retrieves the list of services, it creates a ClusterServiceClass resource for each of them. Each ClusterServiceClass resource describes a single type of service that can be provisioned (an example of a ClusterServiceClass is “PostgreSQL database”). Each ClusterServiceClass has one or more service plans associated with it. These allow the user to choose the level of service they need (for example, a database ClusterServiceClass could provide a “Free” plan, where the size of the database is limited and the underlying storage is a spinning disk, and a “Premium” plan, with unlimited size and SSD storage).

##### Listing the available services in a cluster

Users of the Kubernetes cluster can retrieve a list of all services that can be provisioned in the cluster with `kubectl get serviceclasses`, as shown in the following listing.

##### Listing 18.10. List of ClusterServiceClasses in a cluster

```bash
$ kubectl get clusterserviceclasses
NAME                KIND
postgres-database   ClusterServiceClass.v1alpha1.servicecatalog.k8s.io
mysql-database      ServiceClass.v1alpha1.servicecatalog.k8s.io
mongodb-database    ServiceClass.v1alpha1.servicecatalog.k8s.io
```

The listing shows ClusterServiceClasses for services that your imaginary database broker could provide. You can compare ClusterServiceClasses to StorageClasses, which we discussed in [chapter 6](/book/kubernetes-in-action/chapter-6/ch06). StorageClasses allow you to select the type of storage you’d like to use in your pods, while ClusterServiceClasses allow you to select the type of service.

You can see details of one of the ClusterServiceClasses by retrieving its YAML. An example is shown in the following listing.

##### Listing 18.11. A ClusterServiceClass definition

```bash
$ kubectl get serviceclass postgres-database -o yaml
apiVersion: servicecatalog.k8s.io/v1alpha1
bindable: true
brokerName: database-broker                                 #1
description: A PostgreSQL database
kind: ClusterServiceClass
metadata:
  name: postgres-database
  ...
planUpdatable: false
plans:
- description: A free (but slow) PostgreSQL instance        #2
  name: free                                                #2
  osbFree: true                                             #2
  ...
- description: A paid (very fast) PostgreSQL instance       #3
  name: premium                                             #3
  osbFree: false                                            #3
  ...
```

The ClusterServiceClass in the listing contains two plans—a `free` plan, and a `premium` plan. You can see that this ClusterServiceClass is provided by the `database-broker` broker.

### 18.2.4. Provisioning and using a service

Let’s imagine the pods you’re deploying need to use a database. You’ve inspected the list of available ClusterServiceClasses and have chosen to use the `free` plan of the `postgres-database` ClusterServiceClass.

##### Provisioning a ServiceInstance

To have the database provisioned for you, all you need to do is create a Service-Instance resource, as shown in the following listing.

##### Listing 18.12. A ServiceInstance manifest: database-instance.yaml

```yaml
apiVersion: servicecatalog.k8s.io/v1alpha1
kind: ServiceInstance
metadata:
  name: my-postgres-db
spec:
  clusterServiceClassName: postgres-database
  clusterServicePlanName: free
  parameters:
    init-db-args: --data-checksums
```

You created a ServiceInstance called `my-postgres-db` (that will be the name of the resource you’re deploying) and specified the ClusterServiceClass and the chosen plan. You’re also specifying a parameter, which is specific for each broker and ClusterServiceClass. Let’s imagine you looked up the possible parameters in the broker’s documentation.

As soon as you create this resource, the Service Catalog will contact the broker the ClusterServiceClass belongs to and ask it to provision the service. It will pass on the chosen ClusterServiceClass and plan names, as well as all the parameters you specified.

It’s then completely up to the broker to know what to do with this information. In your case, your database broker will probably spin up a new instance of a PostgreSQL database somewhere—not necessarily in the same Kubernetes cluster or even in Kubernetes at all. It could run a Virtual Machine and run the database in there. The Service Catalog doesn’t care, and neither does the user requesting the service.

You can check if the service has been provisioned successfully by inspecting the `status` section of the my-postgres-db ServiceInstance you created, as shown in the following listing.

##### Listing 18.13. Inspecting the status of a ServiceInstance

```bash
$ kubectl get instance my-postgres-db -o yaml
apiVersion: servicecatalog.k8s.io/v1alpha1
kind: ServiceInstance
...
status:
  asyncOpInProgress: false
  conditions:
  - lastTransitionTime: 2017-05-17T13:57:22Z
    message: The instance was provisioned successfully    #1
    reason: ProvisionedSuccessfully                       #1
    status: "True"
    type: Ready                                           #2
```

A database instance is now running somewhere, but how do you use it in your pods? To do that, you need to bind it.

##### Binding a ServiceInstance

To use a provisioned ServiceInstance in your pods, you create a ServiceBinding resource, as shown in the following listing.

##### Listing 18.14. A ServiceBinding: my-postgres-db-binding.yaml

```yaml
apiVersion: servicecatalog.k8s.io/v1alpha1
kind: ServiceBinding
metadata:
  name: my-postgres-db-binding
spec:
  instanceRef:
    name: my-postgres-db
  secretName: postgres-secret
```

The listing shows that you’re defining a ServiceBinding resource called `my-postgres-db-binding`, in which you’re referencing the `my-postgres-db` service instance you created earlier. You’re also specifying a name of a Secret. You want the Service Catalog to put all the necessary credentials for accessing the service instance into a Secret called `postgres-secret`. But where are you binding the ServiceInstance to your pods? Nowhere, actually.

Currently, the Service Catalog doesn’t yet make it possible to inject pods with the Service-Instance’s credentials. This will be possible when a new Kubernetes feature called PodPresets is available. Until then, you can choose a name for the Secret where you want the credentials to be stored in and mount that Secret into your pods manually.

When you submit the ServiceBinding resource from the previous listing to the Service Catalog API server, the controller will contact the Database broker once again and create a binding for the ServiceInstance you provisioned earlier. The broker responds with a list of credentials and other data necessary for connecting to the database. The Service Catalog creates a new Secret with the name you specified in the Service-Binding resource and stores all that data in the Secret.

##### Using the newly created Secret in client pods

The Secret created by the Service Catalog system can be mounted into pods, so they can read its contents and use them to connect to the provisioned service instance (a PostgreSQL database in the example). The Secret could look like the one in the following listing.

##### Listing 18.15. A Secret holding the credentials for connecting to the service instance

```bash
$ kubectl get secret postgres-secret -o yaml
apiVersion: v1
data:
  host: <base64-encoded hostname of the database>     #1
  username: <base64-encoded username>                 #1
  password: <base64-encoded password>                 #1
kind: Secret
metadata:
  name: postgres-secret
  namespace: default
  ...
type: Opaque
```

Because you can choose the name of the Secret yourself, you can deploy pods before provisioning or binding the service. As you learned in [chapter 7](/book/kubernetes-in-action/chapter-7/ch07), the pods won’t be started until such a Secret exists.

If necessary, multiple bindings can be created for different pods. The service broker can choose to use the same set of credentials in every binding, but it’s better to create a new set of credentials for every binding instance. This way, pods can be prevented from using the service by deleting the ServiceBinding resource.

### 18.2.5. Unbinding and deprovisioning

Once you no longer need a ServiceBinding, you can delete it the way you delete other resources:

```bash
$ kubectl delete servicebinding my-postgres-db-binding
servicebinding "my-postgres-db-binding" deleted
```

When you do this, the Service Catalog controller will delete the Secret and call the broker to perform an unbinding operation. The service instance (in your case a PostgreSQL database) is still running. You can therefore create a new ServiceBinding if you want.

But if you don’t need the database instance anymore, you should delete the Service-Instance resource also:

```bash
$ kubectl delete serviceinstance my-postgres-db
serviceinstance "my-postgres-db " deleted
```

Deleting the ServiceInstance resource causes the Service Catalog to perform a deprovisioning operation on the service broker. Again, exactly what that means is up to the service broker, but in your case, the broker should shut down the PostgreSQL database instance that it created when we provisioned the service instance.

### 18.2.6. Understanding what the Service Catalog brings

As you’ve learned, the Service Catalog enables service providers make it possible to expose those services in any Kubernetes cluster by registering the broker in that cluster. For example, I’ve been involved with the Service Catalog since early on and have implemented a broker, which makes it trivial to provision messaging systems and expose them to pods in a Kubernetes cluster. Another team has implemented a broker that makes it easy to provision Amazon Web Services.

In general, service brokers allow easy provisioning and exposing of services in Kubernetes and will make Kubernetes an even more awesome platform for deploying your applications.

## 18.3. Platforms built on top of Kubernetes

I’m sure you’ll agree that Kubernetes is a great system by itself. Given that it’s easily extensible across all its components, it’s no wonder companies that had previously developed their own custom platforms are now re-implementing them on top of Kubernetes. Kubernetes is, in fact, becoming a widely accepted foundation for the new generation of Platform-as-a-Service offerings.

Among the best-known PaaS systems built on Kubernetes are Deis Workflow and Red Hat’s OpenShift. We’ll do a quick overview of both systems to give you a sense of what they offer on top of all the awesome stuff Kubernetes already offers.

### 18.3.1. Red Hat OpenShift Container Platform

Red Hat OpenShift is a Platform-as-a-Service and as such, it has a strong focus on developer experience. Among its goals are enabling rapid development of applications, as well as easy deployment, scaling, and long-term maintenance of those apps. OpenShift has been around much longer than Kubernetes. Versions 1 and 2 were built from the ground up and had nothing to do with Kubernetes, but when Kubernetes was announced, Red Hat decided to rebuild OpenShift version 3 from scratch—this time on top of Kubernetes. When a company such as Red Hat decides to throw away an old version of their software and build a new one on top of an existing technology like Kubernetes, it should be clear to everyone how great Kubernetes is.

Kubernetes automates rollouts and application scaling, whereas OpenShift also automates the actual building of application images and their automatic deployment without requiring you to integrate a Continuous Integration solution into your cluster.

OpenShift also provides user and group management, which allows you to run a properly secured multi-tenant Kubernetes cluster, where individual users are only allowed to access their own Kubernetes namespaces and the apps running in those namespaces are also fully network-isolated from each other by default.

##### Introducing additional resources available in OpenShift

OpenShift provides some additional API objects in addition to all those available in Kubernetes. We’ll explain them in the next few paragraphs to give you a good overview of what OpenShift does and what it provides.

The additional resources include

- Users & Groups
- Projects
- Templates
- BuildConfigs
- DeploymentConfigs
- ImageStreams
- Routes
- And others

##### Understanding Users, Groups, and Projects

We’ve said that OpenShift provides a proper multi-tenant environment to its users. Unlike Kubernetes, which doesn’t have an API object for representing an individual user of the cluster (but does have ServiceAccounts that represent services running in it), OpenShift provides powerful user management features, which make it possible to specify what each user can do and what they cannot. These features pre-date the Role-Based Access Control, which is now the standard in vanilla Kubernetes.

Each user has access to certain Projects, which are nothing more than Kubernetes Namespaces with additional annotations. Users can only act on resources that reside in the projects the user has access to. Access to the project is granted by a cluster administrator.

##### Introducing Application Templates

Kubernetes makes it possible to deploy a set of resources through a single JSON or YAML manifest. OpenShift takes this a step further by allowing that manifest to be parameterizable. A parameterizable list in OpenShift is called a *Template*; it’s a list of objects whose definitions can include placeholders that get replaced with parameter values when you process and then instantiate a template (see [figure 18.8](/book/kubernetes-in-action/chapter-18/ch18fig08)).

![Figure 18.8. OpenShift templates](https://drek4537l1klr.cloudfront.net/luksa/Figures/18fig08_alt.jpg)

The template itself is a JSON or YAML file containing a list of parameters that are referenced in resources defined in that same JSON/YAML. The template can be stored in the API server like any other object. Before a template can be instantiated, it needs to be processed. To process a template, you supply the values for the template’s parameters and then OpenShift replaces the references to the parameters with those values. The result is a processed template, which is exactly like a Kubernetes resource list that can then be created with a single POST request.

OpenShift provides a long list of pre-fabricated templates that allow users to quickly run complex applications by specifying a few arguments (or none at all, if the template provides good defaults for those arguments). For example, a template can enable the creation of all the Kubernetes resources necessary to run a Java EE application inside an Application Server, which connects to a back-end database, also deployed as part of that same template. All those components can be deployed with a single command.

##### Building images from source using BuildConfigs

One of the best features of OpenShift is the ability to have OpenShift build and immediately deploy an application in the OpenShift cluster by pointing it to a Git repository holding the application’s source code. You don’t need to build the container image at all—OpenShift does that for you. This is done by creating a resource called Build-Config, which can be configured to trigger builds of container images immediately after a change is committed to the source Git repository.

Although OpenShift doesn’t monitor the Git repository itself, a hook in the repository can notify OpenShift of the new commit. OpenShift will then pull the changes from the Git repository and start the build process. A build mechanism called *Source To Image* can detect what type of application is in the Git repository and run the proper build procedure for it. For example, if it detects a pom.xml file, which is used in Java Maven-formatted projects, it runs a Maven build. The resulting artifacts are packaged into an appropriate container image, and are then pushed to an internal container registry (provided by OpenShift). From there, they can be pulled and run in the cluster immediately.

By creating a BuildConfig object, developers can thus point to a Git repo and not worry about building container images. Developers have almost no need to know anything about containers. Once the ops team deploys an OpenShift cluster and gives developers access to it, those developers can develop their code, commit, and push it to a Git repo, the same way they used to before we started packaging apps into containers. Then OpenShift takes care of building, deploying, and managing apps from that code.

##### Automatically deploying newly built images with DeploymentConfigs

Once a new container image is built, it can also automatically be deployed in the cluster. This is enabled by creating a DeploymentConfig object and pointing it to an ImageStream. As the name suggests, an ImageStream is a stream of images. When an image is built, it’s added to the ImageStream. This enables the DeploymentConfig to notice the newly built image and allows it to take action and initiate a rollout of the new image (see [figure 18.9](/book/kubernetes-in-action/chapter-18/ch18fig09)).

![Figure 18.9. BuildConfigs and DeploymentConfigs in OpenShift](https://drek4537l1klr.cloudfront.net/luksa/Figures/18fig09_alt.jpg)

A DeploymentConfig is almost identical to the Deployment object in Kubernetes, but it pre-dates it. Like a Deployment object, it has a configurable strategy for transitioning between Deployments. It contains a pod template used to create the actual pods, but it also allows you to configure pre- and post-deployment hooks. In contrast to a Kubernetes Deployment, it creates ReplicationControllers instead of ReplicaSets and provides a few additional features.

##### Exposing Services externally using Routes

Early on, Kubernetes didn’t provide Ingress objects. To expose Services to the outside world, you needed to use `NodePort` or `LoadBalancer`-type Services. But at that time, OpenShift already provided a better option through a Route resource. A Route is similar to an Ingress, but it provides additional configuration related to TLS termination and traffic splitting.

Similar to an Ingress controller, a Route needs a Router, which is a controller that provides the load balancer or proxy. In contrast to Kubernetes, the Router is available out of the box in OpenShift.

##### Trying out OpenShift

If you’re interested in trying out OpenShift, you can start by using Minishift, which is the OpenShift equivalent of Minikube, or you can try OpenShift Online Starter at [https://manage.openshift.com](https://manage.openshift.com), which is a free multi-tenant, hosted solution provided to get you started with OpenShift.

### 18.3.2. Deis Workflow and Helm

A company called Deis, which has recently been acquired by Microsoft, also provides a PaaS called Workflow, which is also built on top of Kubernetes. Besides Workflow, they’ve also developed a tool called Helm, which is gaining traction in the Kubernetes community as a standard way of deploying existing apps in Kubernetes. We’ll take a brief look at both.

##### Introducing Deis Workflow

You can deploy Deis Workflow to any existing Kubernetes cluster (unlike OpenShift, which is a complete cluster with a modified API server and other Kubernetes components). When you run Workflow, it creates a set of Services and ReplicationControllers, which then provide developers with a simple, developer-friendly environment.

Deploying new versions of your app is triggered by pushing your changes with `git push deis master` and letting Workflow take care of the rest. Similar to OpenShift, Workflow also provides a source to image mechanism, application rollouts and rollbacks, edge routing, and also log aggregation, metrics, and alerting, which aren’t available in core Kubernetes.

To run Workflow in your Kubernetes cluster, you first need to install the Deis Workflow and Helm CLI tools and then install Workflow into your cluster. We won’t go into how to do that here, but if you’d like to learn more, visit the website at [https://deis.com/workflow](https://deis.com/workflow). What we’ll explore here is the Helm tool, which can be used without Workflow and has gained popularity in the community.

##### Deploying resources through Helm

Helm is a package manager for Kubernetes (similar to OS package managers like `yum` or `apt` in Linux or `homebrew` in MacOS).

Helm is comprised of two things:

- A `helm` CLI tool (the client).
- Tiller, a server component running as a Pod inside the Kubernetes cluster.

Those two components are used to deploy and manage application packages in a Kubernetes cluster. Helm application packages are called Charts. They’re combined with a Config, which contains configuration information and is merged into a Chart to create a Release, which is a running instance of an application (a combined Chart and Config). You deploy and manage Releases using the `helm` CLI tool, which talks to the Tiller server, which is the component that creates all the necessary Kubernetes resources defined in the Chart, as shown in [figure 18.10](/book/kubernetes-in-action/chapter-18/ch18fig10).

![Figure 18.10. Overview of Helm](https://drek4537l1klr.cloudfront.net/luksa/Figures/18fig10_alt.jpg)

You can create charts yourself and keep them on your local disk, or you can use any existing chart, which is available in the growing list of helm charts maintained by the community at [https://github.com/kubernetes/charts](https://github.com/kubernetes/charts). The list includes charts for applications such as PostgreSQL, MySQL, MariaDB, Magento, Memcached, MongoDB, OpenVPN, PHPBB, RabbitMQ, Redis, WordPress, and others.

Similar to how you don’t build and install apps developed by other people to your Linux system manually, you probably don’t want to build and manage your own Kubernetes manifests for such applications, right? That’s why you’ll want to use Helm and the charts available in the GitHub repository I mentioned.

When you want to run a PostgreSQL or a MySQL database in your Kubernetes cluster, don’t start writing manifests for them. Instead, check if someone else has already gone through the trouble and prepared a Helm chart for it.

Once someone prepares a Helm chart for a specific application and adds it to the Helm chart GitHub repo, installing the whole application takes a single one-line command. For example, to run MySQL in your Kubernetes cluster, all you need to do is clone the charts Git repo to your local machine and run the following command (provided you have Helm’s CLI tool and Tiller running in your cluster):

```bash
$ helm install --name my-database stable/mysql
```

This will create all the necessary Deployments, Services, Secrets, and PersistentVolumeClaims needed to run MySQL in your cluster. You don’t need to concern yourself with what components you need and how to configure them to run MySQL properly. I’m sure you’ll agree this is awesome.

---

##### Tip

One of the most interesting charts available in the repo is an OpenVPN chart, which runs an OpenVPN server inside your Kubernetes cluster and allows you to enter the pod network through VPN and access Services as if your local machine was a pod in the cluster. This is useful when you’re developing apps and running them locally.

---

These were several examples of how Kubernetes can be extended and how companies like Red Hat and Deis (now Microsoft) have extended it. Now go and start riding the Kubernetes wave yourself!

## 18.4. Summary

This final chapter has shown you how you can go beyond the existing functionalities Kubernetes provides and how companies like Dies and Red Hat have done it. You’ve learned how

- Custom resources can be registered in the API server by creating a Custom-ResourceDefinition object.
- Instances of custom objects can be stored, retrieved, updated, and deleted without having to change the API server code.
- A custom controller can be implemented to bring those objects to life.
- Kubernetes can be extended with custom API servers through API aggregation.
- Kubernetes Service Catalog makes it possible to self-provision external services and expose them to pods running in the Kubernetes cluster.
- Platforms-as-a-Service built on top of Kubernetes make it easy to build containerized applications inside the same Kubernetes cluster that then runs them.
- A package manager called Helm makes deploying existing apps without requiring you to build resource manifests for them.

Thank you for taking the time to read through this long book. I hope you’ve learned as much from reading it as I have from writing it.
