# Chapter 5. Kubernetes Networking Abstractions

Previously, we covered a swath of networking fundamentals and how traffic in Kubernetes gets from A to B. In
this chapter, we will discuss networking abstractions in Kubernetes, primarily service discovery and load balancing.
Most notably, this is the chapter on services and ingresses. Both resources are notoriously complex, due to the large
number of options, as they attempt to solve numerous use cases. They are the most visible part of the Kubernetes
network stack, as they define basic network characteristics of workloads on Kubernetes. This is where developers
interact with the networking stack for their applications deployed on Kubernetes.

This chapter will cover fundamental examples of Kubernetes networking abstractions and the details on\f how they work.
To follow along, you will need the following tools:

-

Docker

-

KIND

-

Linkerd

You will need to be familiar with the `kubectl exec` and `Docker exec` commands. If you are not, our code repo will
have any and all the commands we discuss, so don’t worry too much. We will also make use of `ip` and `netns` from
Chapters [2](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch02.html#linux_networking) and [3](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch03.html#container_networking_basics). Note that most of these tools are for debugging and showing implementation details; you will not
necessarily need them during normal operations.

Docker, KIND, and Linkerd installs are available on their respective sites, and we’ve provided more information in the
book’s code repository as well.

###### Tip

`kubectl` is a key tool in this chapter’s examples, and it’s the standard for operators to interact with clusters and their networks.
You should be familiar with the `kubectl create`, `apply`, `get`,
`delete`, and `exec` commands.
Learn more in the [Kubernetes documentation](https://oreil.ly/H8bTU) or run `kubectl [command] --help`.

This chapter will explore these Kubernetes networking abstractions:

-

StatefulSets

-

Endpoints

-

Endpoint slices

-

Services

-

NodePort

-

Cluster

-

Headless

-

External

-

LoadBalancer

-

Ingress

-

Ingress controller

-

Ingress rules

-

Service meshes

-

Linkerd

To explore these abstractions, we will deploy the examples to our Kubernetes cluster with the following steps:

1.

Deploy a KIND cluster with ingress enabled.

1.

Explore StatefulSets.

1.

Deploy Kubernetes services.

1.

Deploy an ingress controller.

1.

Deploy a Linkerd service mesh.

These abstractions are at the heart of what the Kubernetes API provides to developers and administrators to
programmatically control the flow of communications into and out of the cluster. Understanding and mastering how to deploy
these abstractions is crucial for the success of any workload inside a cluster. After working through these examples, you
will understand which abstractions to use in certain situations for your applications.

With the KIND cluster configuration YAML, we can use KIND to create that cluster with the command in the next section. If this is
the first time running it, it will take some time to download all the Docker images for the working and control plane
Docker images.

###### Note

The following examples assume that you still have the local KIND cluster running from the previous chapter, along with
the Golang web server and the `dnsutils` images for testing.

# StatefulSets

StatefulSets are a workload abstraction in Kubernetes to manage pods like you would a deployment. Unlike a
deployment, StatefulSets add the following features for applications that require them:

-

Stable, unique network identifiers

-

Stable, persistent storage

-

Ordered, graceful deployment and scaling

-

Ordered, automated rolling updates

The deployment resource is better suited for applications that do not have these requirements
(for example, a service that stores data in an external database).

Our database for the Golang minimal web server uses a StatefulSet. The database has a service, a ConfigMap for the
Postgres username, a password, a test database name, and a StatefulSet for the containers running Postgres.

Let’s deploy it now:

```bash
kubectl apply -f database.yaml
service/postgres created
configmap/postgres-config created
statefulset.apps/postgres created
```

Let’s examine the DNS and network ramifications of using a StatefulSet.

To test DNS inside the cluster, we can use the `dnsutils` image; this image is `gcr
.io/kubernetes-e2e-test-images/dnsutils:1.3` and is used for Kubernetes testing:

```bash
kubectl apply -f dnsutils.yaml

pod/dnsutils created

kubectl get pods
NAME       READY   STATUS    RESTARTS   AGE
dnsutils   1/1     Running   0          9s
```

With the replica configured with two pods, we see the StatefulSet deploy `postgres-0` and `postgres-1`, in that order, a
feature of StatefulSets with IP address 10.244.1.3 and 10.244.2.3, respectively:

```bash
kubectl get pods -o wide
NAME         READY   STATUS    RESTARTS   AGE   IP           NODE
dnsutils     1/1     Running   0          15m   10.244.3.2   kind-worker3
postgres-0   1/1     Running   0          15m   10.244.1.3   kind-worker2
postgres-1   1/1     Running   0          14m   10.244.2.3   kind-worker
```

Here is the name of our headless service, Postgres, that the client can use for queries to return the endpoint IP
addresses:

```bash
kubectl get svc postgres
NAME       TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
postgres   ClusterIP                    <none>        5432/TCP   23m
```

Using our `dnsutils` image, we can see that the DNS names for the StatefulSets will return those IP addresses along
with the cluster IP address of the Postgres service:

```bash
kubectl exec dnsutils -- host postgres-0.postgres.default.svc.cluster.local.
postgres-0.postgres.default.svc.cluster.local has address 10.244.1.3

kubectl exec dnsutils -- host postgres-1.postgres.default.svc.cluster.local.
postgres-1.postgres.default.svc.cluster.local has address 10.244.2.3

kubectl exec dnsutils -- host postgres
postgres.default.svc.cluster.local has address 10.105.214.153
```

StatefulSets attempt to mimic a fixed group of persistent machines. As a generic solution for stateful workloads,
specific behavior may be frustrating in specific use cases.

A common problem that users encounter is an update requiring manual intervention to fix when using `.spec
.updateStrategy.type: RollingUpdate`, and `.spec.podManagementPolicy: OrderedReady`, both of which are default settings.
With these settings, a user must manually intervene if an updated pod never becomes ready.

Also, StatefulSets require a service, preferably headless, to be responsible for the network identity of the pods, and
end users are responsible for creating this service.

Statefulsets have many configuration options, and many third-party alternatives exist (both generic stateful workload
controllers and software-specific workload
controllers).

StatefulSets offer functionality for a specific use case in Kubernetes. They should not be used for everyday
application deployments. Later in this section, we will discuss more appropriate networking abstractions for
run-of-the-mill deployments.

In our next section, we will explore endpoints and endpoint slices, the backbone of Kubernetes services.

# Endpoints

Endpoints help identify what pods are running for the service it powers. Endpoints are created and managed by
services. We will discuss services on their own later, to avoid covering too many new things at once. For now, let’s
just say that a service contains a standard label selector (introduced in [Chapter 4](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch04.html#kubernetes_networking_introduction)), which defines which pods are
in the endpoints.

In [Figure 5-1](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch05.html#img-endpoints), we can see traffic being directed to an endpoint on node 2, pod 5.

![Kubernetes Endpoints](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0501.png)

###### Figure 5-1. Endpoints in a service

Let’s discuss how this endpoint is created and maintained in the cluster.

Each endpoint contains a list of ports (which apply to all pods)
and two lists of addresses: ready and unready:

```yaml
apiVersion: v1
kind: Endpoints
metadata:
  labels:
    name: demo-endpoints
subsets:
- addresses:
  - ip: 10.0.0.1
- notReadyAddresses:
  - ip: 10.0.0.2
  ports:
  - port: 8080
    protocol: TCP
```

Addresses are listed in `.addresses` if they are passing pod readiness checks.
Addresses are listed in `.notReadyAddresses` if they are not.
This makes endpoints a *service discovery* tool,
where you can watch an `Endpoints` object to see the health and addresses of all pods:

```bash
kubectl get endpoints clusterip-service
NAME                ENDPOINTS
clusterip-service   10.244.1.5:8080,10.244.2.7:8080,10.244.2.8:8080 + 1 more...
```

We can get a better view of all the addresses with `kubectl describe`:

```bash
kubectl describe endpoints clusterip-service
Name:         clusterip-service
Namespace:    default
Labels:       app=app
Annotations:  endpoints.kubernetes.io/last-change-trigger-time:
2021-01-30T18:51:36Z
Subsets:
  Addresses:          10.244.1.5,10.244.2.7,10.244.2.8,10.244.3.9
  NotReadyAddresses:  <none>
  Ports:
    Name     Port  Protocol
    ----     ----  --------
    <unset>  8080  TCP

Events:
  Type     Reason                  Age   From                 Message
  ----     ------                  ----  ----                 -------
```

Let’s remove the app label and see how Kubernetes responds. In a separate terminal, run this command. This will allow
us to see changes to the pods in real time:

```bash
kubectl get pods -w
```

In another separate terminal, let’s do the same thing with endpoints:

```bash
kubectl get endpoints -w
```

We now need to get a pod name to remove from the `Endpoints` object:

```bash
kubectl get pods -l app=app -o wide
NAME                  READY   STATUS   RESTARTS  AGE  IP           NODE
app-5586fc9d77-7frts  1/1     Running  0         19m  10.244.1.5   kind-worker2
app-5586fc9d77-mxhgw  1/1     Running  0         19m  10.244.3.9   kind-worker3
app-5586fc9d77-qpxwk  1/1     Running  0         20m  10.244.2.7   kind-worker
app-5586fc9d77-tpz8q  1/1     Running  0         19m  10.244.2.8   kind-worker
```

With `kubectl label`, we can alter the pod’s `app-5586fc9d77-7frts` `app=app` label:

```bash
kubectl label pod app-5586fc9d77-7frts app=nope --overwrite
pod/app-5586fc9d77-7frts labeled
```

Both watch commands on endpoints and pods will see some changes for the same reason: removal of the label on the pod.
The endpoint controller will notice a change to the pods with the label `app=app` and so did the deployment controller.
So Kubernetes did what Kubernetes does: it made the real state reflect the desired state:

```bash
kubectl get pods -w
NAME                   READY   STATUS             RESTARTS   AGE
app-5586fc9d77-7frts   1/1     Running            0          21m
app-5586fc9d77-mxhgw   1/1     Running            0          21m
app-5586fc9d77-qpxwk   1/1     Running            0          22m
app-5586fc9d77-tpz8q   1/1     Running            0          21m
dnsutils               1/1     Running            3          3h1m
postgres-0             1/1     Running            0          3h
postgres-1             1/1     Running            0          3h
app-5586fc9d77-7frts   1/1     Running            0          22m
app-5586fc9d77-7frts   1/1     Running            0          22m
app-5586fc9d77-6dcg2   0/1     Pending            0          0s
app-5586fc9d77-6dcg2   0/1     Pending            0          0s
app-5586fc9d77-6dcg2   0/1     ContainerCreating  0          0s
app-5586fc9d77-6dcg2   0/1     Running            0          2s
app-5586fc9d77-6dcg2   1/1     Running            0          7s
```

The deployment has four pods, but our relabeled pod still exists: `app-5586fc9d77-7frts`:

```bash
kubectl get pods
NAME                   READY   STATUS    RESTARTS   AGE
app-5586fc9d77-6dcg2   1/1     Running   0          4m51s
app-5586fc9d77-7frts   1/1     Running   0          27m
app-5586fc9d77-mxhgw   1/1     Running   0          27m
app-5586fc9d77-qpxwk   1/1     Running   0          28m
app-5586fc9d77-tpz8q   1/1     Running   0          27m
dnsutils               1/1     Running   3          3h6m
postgres-0             1/1     Running   0          3h6m
postgres-1             1/1     Running   0          3h6m
```

The pod `app-5586fc9d77-6dcg2` now is part of the deployment and endpoint object with IP address `10.244.1.6`:

```bash
kubectl get pods app-5586fc9d77-6dcg2 -o wide
NAME                  READY  STATUS   RESTARTS  AGE   IP           NODE
app-5586fc9d77-6dcg2  1/1    Running  0         3m6s  10.244.1.6   kind-worker2
```

As always, we can see the full picture of details with `kubectl describe`:

```bash
kubectl describe endpoints clusterip-service
Name:         clusterip-service
Namespace:    default
Labels:       app=app
Annotations:  endpoints.kubernetes.io/last-change-trigger-time:
2021-01-30T19:14:23Z
Subsets:
  Addresses:          10.244.1.6,10.244.2.7,10.244.2.8,10.244.3.9
  NotReadyAddresses:  <none>
  Ports:
    Name     Port  Protocol
    ----     ----  --------
    <unset>  8080  TCP

Events:
  Type     Reason                  Age   From                 Message
  ----     ------                  ----  ----                 -------
```

For large deployments, that endpoint object can become very large, so much so that it can actually slow down changes
in the cluster. To solve that issue, the Kubernetes maintainers have come up with endpoint slices.

# Endpoint Slices

You may be asking, how are they different from endpoints? This is where we *really* start to get into the weeds of
Kubernetes networking.

In a typical cluster, Kubernetes runs `kube-proxy` on every node. `kube-proxy` is responsible for the per-node portions
of making services work, by handling routing and *outbound* load balancing to all the pods in a service. To do that,
`kube-proxy` watches all endpoints in the cluster so it knows all applicable pods that all services should route to.

Now, imagine we have a *big* cluster, with thousands of nodes, and tens of thousands of pods. That means thousands of
kube-proxies are watching endpoints. When an address changes in an `Endpoints` object (say, from a rolling update,
scale up, eviction, health-check failure, or any number of reasons), the updated `Endpoints` object is pushed to all
listening kube-proxies. It is made worse by the number of pods, since more pods means larger `Endpoints` objects,
and more frequent changes. This eventually becomes a strain on `etcd`, the Kubernetes API server, and the network itself.
Kubernetes scaling limits are complex and depend on specific criteria, but endpoints watching is a common problem in
clusters that have thousands of nodes. Anecdotally, many Kubernetes users consider endpoint watches to be the
ultimate bottleneck of cluster size.

This problem is a function of `kube-proxy`’s design  and the expectation that any pod should be immediately able to
route to any service with no notice. Endpoint slices are an approach that allows `kube-proxy`’s fundamental design to
continue, while drastically reducing the watch bottleneck in large clusters where large services are used.

Endpoint slices have similar contents to `Endpoints` objects but also include an array of endpoints:

```yaml
apiVersion: discovery.k8s.io/v1beta1
kind: EndpointSlice
metadata:
  name: demo-slice-1
  labels:
    kubernetes.io/service-name: demo
addressType: IPv4
ports:
  - name: http
    protocol: TCP
    port: 80
endpoints:
  - addresses:
      - "10.0.0.1"
    conditions:
      ready: true
```

The meaningful difference between endpoints and endpoint slices is not the schema, but how Kubernetes treats them.
With “regular” endpoints, a Kubernetes service creates one endpoint for all pods in the service.
A service creates *multiple* endpoint slices, each containing a *subset* of pods; [Figure 5-2](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch05.html#img-endpointslice) depicts this subset.
The union of all endpoint slices for a service contains all pods in the service.
This way, an IP address change (due to a new pod, a deleted pod,
or a pod’s health changing) will result in a much smaller data transfer to watchers.
Because Kubernetes doesn’t have a transactional API,
the same address may appear temporarily in multiple slices.
Any code consuming endpoint slices (such as `kube-proxy`) must be able to account for this.

The maximum number of addresses in an endpoint slice is set using the `--max-endpoints-per-slice`
`kube-controller-manager` flag.
The current default is 100, and the maximum is 1000.
The endpoint slice controller attempts to fill existing endpoint slices before creating new ones,
but does not rebalance endpoint slice.

The endpoint slice controller mirrors endpoints to endpoint slice, to allow systems to continue writing endpoints
while treating endpoint slice as the source of truth. The exact future of this behavior, and endpoints in general,
has not been finalized (however, as a v1 resource, endpoints would be sunset with substantial notice).
There are four exceptions that will prevent mirroring:

-

There is no corresponding service.

-

The corresponding service resource selects pods.

-

The `Endpoints` object has the label `endpointslice.kubernetes.io/skip-mirror: true`.

-

The `Endpoints` object has the annotation `control-⁠⁠plane.alpha.kubernetes​​.io/leader`.

![EndpointsVSliice](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0502.png)

###### Figure 5-2. `Endpoints` versus `EndpointSlice` objects

You can fetch all endpoint slices for a specific service
by fetching endpoint slices filtered to the desired name in `.metadata.labels."kubernetes.io/service-name"`.

###### Warning

Endpoint slices have been in beta state since Kubernetes 1.17.
This is still the case in Kubernetes 1.20, the current version at the time of writing.
Beta resources typically don’t see major changes, and eventually graduate to stable APIs,
but that is not guaranteed.
If you directly use endpoint slices,
be aware that a future Kubernetes release may make a breaking change without much warning,
or the behaviors described here may change.

Let’s see some endpoints running in the cluster with `kubectl get endpointslice`:

```bash
kubectl get endpointslice
NAME                      ADDRESSTYPE   PORTS   ENDPOINTS
clusterip-service-l2n9q   IPv4          8080    10.244.2.7,10.244.2.8,10.244.1.5
+ 1 more...
```

If we want more detail about the endpoint slices `clusterip-service-l2n9q`, we can use `kubectl describe` on it:

```bash
kubectl describe endpointslice clusterip-service-l2n9q
Name:         clusterip-service-l2n9q
Namespace:    default
Labels:
endpointslice.kubernetes.io/managed-by=endpointslice-controller.k8s.io
kubernetes.io/service-name=clusterip-service
Annotations:  endpoints.kubernetes.io/last-change-trigger-time:
2021-01-30T18:51:36Z
AddressType:  IPv4
Ports:
  Name     Port  Protocol
  ----     ----  --------
  <unset>  8080  TCP
Endpoints:
  - Addresses:  10.244.2.7
    Conditions:
      Ready:    true
    Hostname:   <unset>
    TargetRef:  Pod/app-5586fc9d77-qpxwk
    Topology:   kubernetes.io/hostname=kind-worker
  - Addresses:  10.244.2.8
    Conditions:
      Ready:    true
    Hostname:   <unset>
    TargetRef:  Pod/app-5586fc9d77-tpz8q
    Topology:   kubernetes.io/hostname=kind-worker
  - Addresses:  10.244.1.5
    Conditions:
      Ready:    true
    Hostname:   <unset>
    TargetRef:  Pod/app-5586fc9d77-7frts
    Topology:   kubernetes.io/hostname=kind-worker2
  - Addresses:  10.244.3.9
    Conditions:
      Ready:    true
    Hostname:   <unset>
    TargetRef:  Pod/app-5586fc9d77-mxhgw
    Topology:   kubernetes.io/hostname=kind-worker3
Events:         <none>
```

In the output, we see the pod powering the endpoint slice from `TargetRef`. The `Topology` information gives us the hostname
of the worker node that the pod is deployed to. Most importantly, the `Addresses` returns the IP address of the
endpoint object.

Endpoints and endpoint slices are important to understand because they identify the pods responsible for the services,
no matter the type deployed. Later in the chapter, we’ll review how to use endpoints and labels for troubleshooting. Next,
we will investigate all the Kubernetes service types.

# Kubernetes Services

A service in Kubernetes is a load balancing abstraction within a cluster.  There are four types of services,
specified by the `.spec.Type` field. Each type offers a different form of load balancing or discovery, which we will
cover individually. The four types are: ClusterIP, NodePort, LoadBalancer, and ExternalName.

Services use a standard pod selector to match pods.
The service includes all matching pods.
Services create an endpoint (or endpoint slice) to handle pod discovery:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: demo-service
spec:
  selector:
    app: demo
```

We will use the Golang minimal web server for all the service examples. We have added functionality to the
application to display the host and pod IP addresses in the REST request.

[Figure 5-3](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch05.html#img-pod-connection) outlines our pod networking status as a single pod in a cluster. The networking objects we are about
to explore will expose our app pods outside the cluster in some instances and in others allow us to scale our
application to meet demand. Recall from Chapters [3](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch03.html#container_networking_basics) and [4](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch04.html#kubernetes_networking_introduction) that containers running inside pods share a network
namespace. In addition, there is also a pause container that is created for each pod. The pause container manages the namespaces for the pod.

###### Note

The pause container is the parent container for all running  containers in the pod. It holds and shares all the namespaces for the pod. You can read more about the pause container in Ian Lewis’ [blog post](https://oreil.ly/n51eq).

![Pod on Host](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0503.png)

###### Figure 5-3. Pod on host

Before we deploy the services, we must first deploy the web server that the services will be routing traffic to, if
we have not already:

```bash
kubectl apply -f web.yaml
deployment.apps/app created

kubectl get pods -o wide
NAME                  READY  STATUS    RESTARTS  AGE  IP           NODE
app-9cc7d9df8-ffsm6   1/1    Running   0         49s  10.244.1.4   kind-worker2
dnsutils              1/1    Running   0         49m  10.244.3.2   kind-worker3
postgres-0            1/1    Running   0         48m  10.244.1.3   kind-worker2
postgres-1            1/1    Running   0         48m  10.244.2.3   kind-worker
```

Let’s look at each type of service starting with NodePort.

## NodePort

A NodePort service provides a simple way for external software,  such as a load balancer, to route traffic to the pods. The software only needs to be aware of node IP addresses, and the service’s port(s). A NodePort service exposes a fixed port
on all nodes, which routes to applicable pods. A NodePort service uses the `.spec.ports.[].nodePort` field to specify
the port to open on all nodes, for the corresponding port on pods:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: demo-service
spec:
  type: NodePort
  selector:
    app: demo
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30000
```

The `nodePort` field can be left blank, in which case Kubernetes  automatically selects a unique port.
The `--service-node-port-range` flag in
`kube-controller-manager` sets the valid range for ports, 30000–32767.
Manually specified ports must be within this range.

Using a NodePort service, external users can connect to the nodeport on any node and be routed to a pod on a node
that has a pod backing that service; [Figure 5-4](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch05.html#img-node-port-traffic) demonstrates this. The service directs traffic to node 3, and
`iptables` rules forward the traffic to node 2 hosting the pod. This is a bit inefficient, as a typical connection will
be routed to a pod on another node.

![Node Port Traffic Flow](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0504.png)

###### Figure 5-4. NodePort traffic flow

[Figure 5-4](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch05.html#img-node-port-traffic) requires us to discuss an attribute of services, externalTrafficPolicy. ExternalTrafficPolicy indicates
how a service will route external traffic to either node-local or cluster-wide endpoints. `Local` preserves the client
source IP and avoids a second hop for LoadBalancer and NodePort type services but risks potentially imbalanced
traffic spreading. Cluster obscures the client source IP and may cause a second hop to another node but should
have good overall load-spreading. A `Cluster` value means that for each worker node, the `kube-proxy iptable` rules are
set up to route the traffic to the pods backing the service anywhere in the cluster, just like we have shown in
[Figure 5-4](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch05.html#img-node-port-traffic).

A `Local` value means the `kube-proxy iptable` rules are set up only on the worker nodes with relevant pods running to
route the traffic local to the worker node. Using `Local` also allows application developers to preserve the source IP
of the user request. If you set externalTrafficPolicy to the value `Local`, `kube-proxy` will proxy requests only to
node-local endpoints and will not forward traffic to other nodes. If there are no local endpoints, packets sent to
the node are dropped.

Let’s scale up the deployment of our web app for some more testing:

```bash
kubectl scale deployment app --replicas 4
deployment.apps/app scaled

 kubectl get pods -l app=app -o wide
NAME                  READY   STATUS      IP           NODE
app-9cc7d9df8-9d5t8   1/1     Running     10.244.2.4   kind-worker
app-9cc7d9df8-ffsm6   1/1     Running     10.244.1.4   kind-worker2
app-9cc7d9df8-srxk5   1/1     Running     10.244.3.4   kind-worker3
app-9cc7d9df8-zrnvb   1/1     Running     10.244.3.5   kind-worker3
```

With four pods running, we will have one pod at every node in the cluster:

```bash
kubectl get pods -o wide -l app=app
NAME                   READY   STATUS     IP           NODE
app-5586fc9d77-7frts   1/1     Running    10.244.1.5   kind-worker2
app-5586fc9d77-mxhgw   1/1     Running    10.244.3.9   kind-worker3
app-5586fc9d77-qpxwk   1/1     Running    10.244.2.7   kind-worker
app-5586fc9d77-tpz8q   1/1     Running    10.244.2.8   kind-worker
```

Now let’s deploy our NodePort service:

```bash
kubectl apply -f services-nodeport.yaml
service/nodeport-service created

kubectl describe svc nodeport-service
Name:                     nodeport-service
Namespace:                default
Labels:                   <none>
Annotations:              Selector:  app=app
Type:                     NodePort
IP:                       10.101.85.57
Port:                     echo  8080/TCP
TargetPort:               8080/TCP
NodePort:                 echo  30040/TCP
Endpoints:                10.244.1.5:8080,10.244.2.7:8080,10.244.2.8:8080
+ 1 more...
Session Affinity:         None
External Traffic Policy:  Cluster
Events:                   <none>
```

To test the NodePort service, we must retrieve the IP address of a worker node:

```bash
kubectl get nodes -o wide
NAME                 STATUS   ROLES   INTERNAL-IP OS-IMAGE
kind-control-plane   Ready    master  172.18.0.5  Ubuntu 19.10
kind-worker          Ready    <none>  172.18.0.3  Ubuntu 19.10
kind-worker2         Ready    <none>  172.18.0.4  Ubuntu 19.10
kind-worker3         Ready    <none>  172.18.0.2  Ubuntu 19.10
```

Communication external to the cluster will use a `NodePort` value of 30040 opened on each worker and the node worker’s IP address.

We can see that our pods are reachable on each host in the cluster:

```bash
kubectl exec -it dnsutils -- wget -q -O-  172.18.0.5:30040/host
NODE: kind-worker2, POD IP:10.244.1.5

kubectl exec -it dnsutils -- wget -q -O-  172.18.0.3:30040/host
NODE: kind-worker, POD IP:10.244.2.8

kubectl exec -it dnsutils -- wget -q -O-  172.18.0.4:30040/host
NODE: kind-worker2, POD IP:10.244.1.5
```

It’s important to consider the limitations as well. A NodePort deployment will fail if it cannot allocate the
requested port. Also, ports must be tracked across all applications using a NodePort service.
Using manually selected ports raises the issue of port collisions (especially when applying a workload to multiple
clusters, which may not have the same NodePorts free).

Another downside of using the NodePort service type is that the load balancer
or client software must be aware of the node IP addresses.
A static configuration (e.g., an operator manually copying node IP addresses) may become too outdated over time (especially on a cloud provider) as IP addresses change or nodes are replaced.
A reliable system automatically populates node IP addresses, either by watching which
machines have been allocated to the cluster
or by listing nodes from the Kubernetes API itself.

NodePorts are the earliest form of services. We will see that other service types use NodePorts as a base structure
in their architecture. NodePorts should not be used by themselves, as clients would need to know the IP addresses of
hosts and the node for connection requests. We will see how NodePorts are used to enable load balancers later in the
chapter when we discuss cloud networks.

Next up is the default type for services, ClusterIP.

## ClusterIP

The IP addresses of pods share the life cycle of the pod and thus are not reliable for clients to use for
requests. Services help overcome this pod networking design. A ClusterIP service provides an internal load
balancer with a single IP address that maps to all matching (and ready) pods.

The service’s IP address must be within the CIDR set in `service-cluster-ip-range`, in the API server.
You can specify a valid IP address manually, or leave `.spec.clusterIP` unset to have one assigned automatically.
The ClusterIP service address is a virtual IP address that is  routable only internally.

`kube-proxy` is responsible for making the ClusterIP service address route to all applicable pods. In “normal” configurations, `kube-proxy` performs L4 load balancing,
which may not be sufficient. For example, older pods may see more load, due to accumulating more long-lived
connections from clients. Or, a few clients making many requests may cause the load to be distributed unevenly.

A particular use case example for ClusterIP is when a workload requires a load balancer within the same cluster.

In [Figure 5-5](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch05.html#img-clusterip), we can see a ClusterIP service deployed. The service name is App with a selector, or App=App1.
There are two pods powering this service. Pod 1 and Pod 5 match the selector for the service.

![Cluster IP](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0505.png)

###### Figure 5-5. Cluster IP example service

Let’s dig into an example on the command line with our KIND cluster.

We will deploy a ClusterIP service for use with our Golang web server:

```bash
kubectl apply -f service-clusterip.yaml
service/clusterip-service created

kubectl describe svc clusterip-service
Name:              clusterip-service
Namespace:         default
Labels:            app=app
Annotations:       Selector:  app=app
Type:              ClusterIP
IP:                10.98.252.195
Port:              <unset>  80/TCP
TargetPort:        8080/TCP
Endpoints:         <none>
Session Affinity:  None
Events:            <none>
```

The ClusterIP service name is resolvable in the network:

```bash
kubectl exec dnsutils -- host clusterip-service
clusterip-service.default.svc.cluster.local has address 10.98.252.195
```

Now we can reach the host API endpoint with the Cluster IP address `10.98.252.195`, with the service name `clusterip-service`; or directly with the pod IP address `10.244.1.4` and port 8080:

```bash
kubectl exec dnsutils -- wget -q -O- clusterip-service/host
NODE: kind-worker2, POD IP:10.244.1.4

kubectl exec dnsutils -- wget -q -O- 10.98.252.195/host
NODE: kind-worker2, POD IP:10.244.1.4

kubectl exec dnsutils -- wget -q -O- 10.244.1.4:8080/host
NODE: kind-worker2, POD IP:10.244.1.4
```

The ClusterIP service is the default type for services. With that default status, it is warranted that we should
explore what the ClusterIP service abstracted for us. If you recall from Chapters [2](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch02.html#linux_networking) and [3](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch03.html#container_networking_basics), this list is similar to
what is set up with the Docker network, but we now also have `iptables` for the service across all nodes:

-

View the VETH pair and match with the pod.

-

View the network namespace and match with the pod.

-

Verify the PIDs on the node and match the pods.

-

Match services with `iptables` rules.

To explore this, we need to know what worker node the pod is deployed to, and that is `kind-worker2`:

```bash
kubectl get pods -o wide --field-selector spec.nodeName=kind-worker2 -l app=app
NAME                  READY   STATUS    RESTARTS   AGE     IP           NODE
app-9cc7d9df8-ffsm6   1/1     Running   0          7m23s   10.244.1.4   kind-worker2
```

###### Note

The container IDs and names will be different for you.

Since we are using KIND, we can use `docker ps` and `docker exec` to get information out of the running worker node
`kind-worker-2`:

```bash
docker ps
CONTAINER ID  COMMAND                  PORTS                      NAMES
df6df0736958  "/usr/local/bin/entr…"                               kind-worker2
e242f11d2d00  "/usr/local/bin/entr…"                               kind-worker
a76b32f37c0e  "/usr/local/bin/entr…"                               kind-worker3
07ccb63d870f  "/usr/local/bin/entr…"   0.0.0.0:80->80/tcp,         kind-control-plane
                                       0.0.0.0:443->443/tcp,
                                       127.0.0.1:52321->6443/tcp
```

The `kind-worker2` container ID is `df6df0736958`; KIND was *kind* enough to label each container with names, so we can
reference each worker node with its name `kind-worker2`:

Let’s see the IP address and route table information of our pod, `app-9cc7d9df8-ffsm6`:

```bash
kubectl exec app-9cc7d9df8-ffsm6 ip r
default via 10.244.1.1 dev eth0
10.244.1.0/24 via 10.244.1.1 dev eth0 src 10.244.1.4
10.244.1.1 dev eth0 scope link src 10.244.1.4
```

Our pod’s IP address is `10.244.1.4` running on interface `eth0@if5` with `10.244.1.1` as its default route. That
matches interface 5 on the pod `veth45d1f3e8@if5`:

```bash
kubectl exec app-9cc7d9df8-ffsm6 ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default
qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: tunl0@NONE: <NOARP> mtu 1480 qdisc noop state DOWN
group default qlen 1000
    link/ipip 0.0.0.0 brd 0.0.0.0
3: ip6tnl0@NONE: <NOARP> mtu 1452 qdisc noop state DOWN group default qlen 1000
    link/tunnel6 :: brd ::
5: eth0@if5: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP
group default
    link/ether 3e:57:42:6e:cd:45 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 10.244.1.4/24 brd 10.244.1.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::3c57:42ff:fe6e:cd45/64 scope link
       valid_lft forever preferred_lft forever
```

Let’s check the network namespace as well, from the `node ip a` output:

```bash
docker exec -it kind-worker2 ip a
<trimmerd>
5: veth45d1f3e8@if5: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue
state UP group default
    link/ether 3e:39:16:38:3f:23 brd <>
    link-netns cni-ec37f6e4-a1b5-9bc9-b324-59d612edb4d4
    inet 10.244.1.1/32 brd 10.244.1.1 scope global veth45d1f3e8
       valid_lft forever preferred_lft forever
```

`netns list` confirms that the network namespaces match our pods, interface to the host interface,
`cni-ec37f6e4-a1b5-9bc9-b324-59d612edb4d4`:

```bash
docker exec -it kind-worker2 /usr/sbin/ip netns list
cni-ec37f6e4-a1b5-9bc9-b324-59d612edb4d4 (id: 2)
cni-c18c44cb-6c3e-c48d-b783-e7850d40e01c (id: 1)
```

Let’s see what processes run inside that network namespace. For that we will use `docker exec`
to run commands inside the node `kind-worker2` hosting the pod and its network namespace:

```bash
docker exec -it kind-worker2 /usr/sbin/ip netns pid
 cni-ec37f6e4-a1b5-9bc9-b324-59d612edb4d4
4687
4737
```

Now we can `grep` for each process ID and inspect what they are doing:

```bash
docker exec -it kind-worker2 ps aux | grep 4687
root      4687  0.0  0.0    968     4 ?        Ss   17:00   0:00 /pause

docker exec -it kind-worker2 ps aux | grep 4737
root      4737  0.0  0.0 708376  6368 ?        Ssl  17:00   0:00 /opt/web-server
```

`4737` is the process ID of our web server container running on  `kind-worker2`.

`4687` is our pause container holding onto all our namespaces.

Now let’s see what will happen to the `iptables` on the worker node:

```bash
docker exec -it kind-worker2 iptables -L
Chain INPUT (policy ACCEPT)
target                  prot opt source     destination
/* kubernetes service portals */
KUBE-SERVICES           all  --  anywhere   anywhere    ctstate NEW
/* kubernetes externally-visible service portals */
KUBE-EXTERNAL-SERVICES  all  --  anywhere   anywhere    ctstate NEW
KUBE-FIREWALL           all  --  anywhere   anywhere

Chain FORWARD (policy ACCEPT)
target        prot opt source     destination
/* kubernetes forwarding rules */
KUBE-FORWARD  all  --  anywhere   anywhere
/* kubernetes service portals */
KUBE-SERVICES all  --  anywhere   anywhere             ctstate NEW

Chain OUTPUT (policy ACCEPT)
target          prot opt source               destination
/* kubernetes service portals */
KUBE-SERVICES   all  --  anywhere             anywhere             ctstate NEW
KUBE-FIREWALL   all  --  anywhere             anywhere

Chain KUBE-EXTERNAL-SERVICES (1 references)
target     prot opt source               destination

Chain KUBE-FIREWALL (2 references)
target     prot opt source    destination
/* kubernetes firewall for dropping marked packets */
DROP       all  --  anywhere  anywhere   mark match 0x8000/0x8000

Chain KUBE-FORWARD (1 references)
target  prot opt source    destination
DROP    all  --  anywhere  anywhere    ctstate INVALID
/*kubernetes forwarding rules*/
ACCEPT  all  --  anywhere  anywhere     mark match 0x4000/0x4000
/*kubernetes forwarding conntrack pod source rule*/
ACCEPT  all  --  anywhere  anywhere     ctstate RELATED,ESTABLISHED
/*kubernetes forwarding conntrack pod destination rule*/
ACCEPT  all  --  anywhere  anywhere     ctstate RELATED,ESTABLISHED

Chain KUBE-KUBELET-CANARY (0 references)
target     prot opt source               destination

Chain KUBE-PROXY-CANARY (0 references)
target     prot opt source               destination

Chain KUBE-SERVICES (3 references)
target     prot opt source               destination
```

That is a lot of tables being managed by Kubernetes.

We can dive a little deeper to examine the `iptables` responsible for the services we deployed.
Let’s retrieve the IP address of the `clusterip-service` deployed.
We need this to find the matching `iptables` rules:

```bash
kubectl get svc clusterip-service
NAME                TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
clusterip-service   ClusterIP   10.98.252.195    <none>        80/TCP     57m
```

Now use the clusterIP of the service, `10.98.252.195`, to find our `iptables` rule:

```bash
docker exec -it  kind-worker2 iptables -L -t nat | grep 10.98.252.195
/* default/clusterip-service: cluster IP */
KUBE-MARK-MASQ  tcp  -- !10.244.0.0/16        10.98.252.195 tcp dpt:80
/* default/clusterip-service: cluster IP */
KUBE-SVC-V7R3EVKW3DT43QQM  tcp  --  anywhere  10.98.252.195 tcp dpt:80
```

List all the rules on the chain `KUBE-SVC-V7R3EVKW3DT43QQM`:

```bash
docker exec -it  kind-worker2 iptables -t nat -L KUBE-SVC-V7R3EVKW3DT43QQM
Chain KUBE-SVC-V7R3EVKW3DT43QQM (1 references)
target     prot opt source               destination
/* default/clusterip-service: */
KUBE-SEP-THJR2P3Q4C2QAEPT  all  --  anywhere             anywhere
```

The `KUBE-SEP-` will contain the endpoints for the services, `KUBE-SEP-THJR2P3Q4C2QAEPT`.

Now we can see what the rules for this chain are in `iptables`:

```bash
docker exec -it kind-worker2 iptables -L KUBE-SEP-THJR2P3Q4C2QAEPT -t nat
Chain KUBE-SEP-THJR2P3Q4C2QAEPT (1 references)
target          prot opt source          destination
/* default/clusterip-service: */
KUBE-MARK-MASQ  all  --  10.244.1.4      anywhere
/* default/clusterip-service: */
DNAT            tcp  --  anywhere        anywhere    tcp to:10.244.1.4:8080
```

`10.244.1.4:8080` is one of the service endpoints, aka a pod backing the service, which is confirmed with the output
of `kubectl get ep clusterip-service`:

```bash
kubectl get ep clusterip-service
NAME                ENDPOINTS                         AGE
clusterip-service   10.244.1.4:8080                   62m

kubectl describe ep clusterip-service
Name:         clusterip-service
Namespace:    default
Labels:       app=app
Annotations:  <none>
Subsets:
  Addresses:          10.244.1.4
  NotReadyAddresses:  <none>
  Ports:
    Name     Port  Protocol
    ----     ----  --------
    <unset>  8080  TCP

Events:  <none>
```

Now, let’s explore the limitations of the ClusterIP service. The ClusterIP service is for internal traffic to the cluster, and it
suffers the same issues as endpoints do. As the service size grows, updates to it will slow.
In [Chapter 2](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch02.html#linux_networking), we discussed how to mitigate that by using IPVS over `iptables` as the proxy mode for `kube-proxy`.
We will discuss later in this chapter how to get traffic into the cluster using ingress and the other service type
LoadBalancer.

ClusterIP is the default type of service, but there are several other specific types of services such as headless and
ExternalName. ExternalName is a specific type of services that helps with reaching services outside the cluster.
We briefly touched on headless services with StatefulSets, but let’s review those services in depth now.

## Headless

A headless service isn’t a formal type of service (i.e., there is no `.spec.type: Headless`).
A headless service is a service with `.spec.clusterIP: "None"`.
This is distinct from merely *not setting* a cluster IP address,
which makes Kubernetes automatically assign a cluster IP address.

When ClusterIP is set to None, the service does not support any load balancing functionality.
Instead, it only provisions an `Endpoints` object
and points the service DNS record at all pods that are selected and ready.

A headless service provides a generic way to watch endpoints,
without needing to interact with the Kubernetes API.
Fetching DNS records is much simpler than integrating with the Kubernetes API,
and it may not be possible with third-party
software.

Headless services allow developers to deploy multiple copies of a pod in a deployment. Instead of a single IP
address returned, like with the ClusterIP service, all the IP addresses of the endpoint are returned in the query. It then is up to the client to pick which one to use. To see this in action, let’s scale up the deployment of our web app:

```bash
kubectl scale deployment app --replicas 4
deployment.apps/app scaled

 kubectl get pods -l app=app -o wide
NAME                  READY   STATUS      IP           NODE
app-9cc7d9df8-9d5t8   1/1     Running     10.244.2.4   kind-worker
app-9cc7d9df8-ffsm6   1/1     Running     10.244.1.4   kind-worker2
app-9cc7d9df8-srxk5   1/1     Running     10.244.3.4   kind-worker3
app-9cc7d9df8-zrnvb   1/1     Running     10.244.3.5   kind-worker3
```

Now let’s deploy the headless service:

```bash
kubectl apply -f service-headless.yml
service/headless-service created
```

The DNS query will return all four of the pod IP addresses. Using our `dnsutils` image, we can verify that is the case:

```bash
kubectl exec dnsutils -- host -v -t a headless-service
Trying "headless-service.default.svc.cluster.local"
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 45294
;; flags: qr aa rd; QUERY: 1, ANSWER: 4, AUTHORITY: 0, ADDITIONAL: 0

;; QUESTION SECTION:
;headless-service.default.svc.cluster.local. IN A

;; ANSWER SECTION:
headless-service.default.svc.cluster.local. 30 IN A 10.244.2.4
headless-service.default.svc.cluster.local. 30 IN A 10.244.3.5
headless-service.default.svc.cluster.local. 30 IN A 10.244.1.4
headless-service.default.svc.cluster.local. 30 IN A 10.244.3.4

Received 292 bytes from 10.96.0.10#53 in 0 ms
```

The IP addresses returned from the query also match the endpoints for the service. Using `kubectl describe` for the endpoint  confirms that:

```bash
kubectl describe endpoints headless-service
Name:         headless-service
Namespace:    default
Labels:       service.kubernetes.io/headless
Annotations:  endpoints.kubernetes.io/last-change-trigger-time:
2021-01-30T18:16:09Z
Subsets:
  Addresses:          10.244.1.4,10.244.2.4,10.244.3.4,10.244.3.5
  NotReadyAddresses:  <none>
  Ports:
    Name     Port  Protocol
    ----     ----  --------
    <unset>  8080  TCP

Events:  <none>
```

Headless has a specific use case and is not typically used for deployments. As we mentioned in [“StatefulSets”](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch05.html#statefulsets), if developers need to let the client decide which endpoint to use, headless is the appropriate type of service to deploy. Two examples of headless services are clustered databases and applications that have client-side load-balancing logic built into the code.

Our next example is ExternalName, which aids in migrations of services external to the cluster. It also offers other DNS advantages inside cluster DNS.

## ExternalName Service

ExternalName is a special type of service that does not have selectors and uses DNS names instead.

When looking up the host `ext-service.default.svc.cluster.local`,
the cluster DNS service returns a CNAME record of `database.mycompany.com`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: ext-service
spec:
  type: ExternalName
  externalName: database.mycompany.com
```

If developers are migrating an application into Kubernetes but its dependencies are staying external to the cluster, ExternalName service allows them to define a DNS record internal to the cluster no matter where the service actually runs.

DNS will try the search as shown in the following example:

```bash
kubectl exec -it dnsutils -- host -v -t a github.com
Trying "github.com.default.svc.cluster.local"
Trying "github.com.svc.cluster.local"
Trying "github.com.cluster.local"
Trying "github.com"
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 55908
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 0

;; QUESTION SECTION:
;github.com.                    IN      A

;; ANSWER SECTION:
github.com.             30      IN      A       140.82.112.3

Received 54 bytes from 10.96.0.10#53 in 18 ms
```

As an example, the ExternalName service allows developers to map a service to a DNS name.

Now if we deploy the external service like so:

```bash
kubectl apply -f service-external.yml
service/external-service created
```

The A record for github.com is returned from the `external-service` query:

```bash
kubectl exec -it dnsutils -- host -v -t a external-service
Trying "external-service.default.svc.cluster.local"
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 11252
;; flags: qr aa rd; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 0

;; QUESTION SECTION:
;external-service.default.svc.cluster.local. IN A

;; ANSWER SECTION:
external-service.default.svc.cluster.local. 24 IN CNAME github.com.
github.com.             24      IN      A       140.82.112.3

Received 152 bytes from 10.96.0.10#53 in 0 ms
```

The CNAME for the external service returns github.com:

```bash
kubectl exec -it dnsutils -- host -v -t cname external-service
Trying "external-service.default.svc.cluster.local"
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 36874
;; flags: qr aa rd; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 0

;; QUESTION SECTION:
;external-service.default.svc.cluster.local. IN CNAME

;; ANSWER SECTION:
external-service.default.svc.cluster.local. 30 IN CNAME github.com.

Received 126 bytes from 10.96.0.10#53 in 0 ms
```

Sending traffic to a headless service via a DNS record is possible but inadvisable. DNS is a notoriously poor way to load balance,
as software takes very different (and often simple or unintuitive)
approaches to A or AAAA DNS records that return multiple IP addresses. For example, it is common for software to always choose the first IP address in the response and/or cache and reuse the same IP address indefinitely. If you need to be able to send traffic to the service’s DNS address, consider a (standard) ClusterIP or LoadBalancer service.

The “correct” way to use a headless service is to query the service’s A/AAAA DNS record and use that data in a server-side or client-side load balancer.

Most of the services we have been discussing are for internal traffic management for the cluster network.
In our next sections, will be reviewing how to route requests into the cluster
with service type LoadBalancer and ingress.

## LoadBalancer

LoadBalancer service exposes services external to the cluster network. They combine the NodePort service behavior with an external integration, such as a cloud provider’s load balancer.
Notably, LoadBalancer services handle L4 traffic (unlike ingress, which handles L7 traffic), so they will work for any TCP or UDP service, provided the load balancer selected supports L4 traffic.

Configuration and load balancer options are extremely dependent on the cloud provider.
For example, some will support `.spec.loadBalancerIP` (with varying setup required), and some will ignore it:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: demo-service
spec:
  selector:
    app: demo
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
  clusterIP: 10.0.5.1
  type: LoadBalancer
```

Once the load balancer has been provisioned, its IP address will be written to
`.status.loadBalancer.ingress.ip`.

LoadBalancer services are useful for exposing TCP or UDP services to the outside world. Traffic will come into the
load balancer on its public IP address and TCP port 80, defined by `spec.ports[*].port`  and routed to the
cluster IP address, `10.0.5.1`, and then to container target port 8080, `spec.ports[*].targetPort`. Not shown in the
example is the `.spec.ports[*].nodePort`; if not specified, Kubernetes will pick one for the service.

###### Tip

The service’s `spec.ports[*].targetPort` must match your pod’s container applications
`spec.container[*].ports.containerPort`, along with the protocol. It’s like missing a semicolon in Kubernetes networking
otherwise.

In [Figure 5-6](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch05.html#loadbalancer), we can see how a LoadBalancer type builds on the other service types. The cloud load balancer will determine
how to distribute traffic; we will discuss that in depth in the next chapter.

![LoadBalancer service](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0506.png)

###### Figure 5-6. LoadBalancer service

Let’s continue to extend our Golang web server example with a LoadBalancer service.

Since we are running on our local machine and not in a service provider like AWS, GCP, or Azure, we can use MetalLB as
an example for our LoadBalancer service. The MetalLB project aims to allow users to deploy bare-metal load balancers for
their clusters.

This example has been modified from the [KIND example deployment](https://oreil.ly/h8xIt).

Our first step is to deploy a separate namespace for MetalLB:

```bash
kubectl apply -f mlb-ns.yaml
namespace/metallb-system created
```

MetalLB members also require a secret for joining the LoadBalancer cluster; let’s deploy one now for them to use in our cluster:

```bash
kubectl create secret generic -n metallb-system memberlist
--from-literal=secretkey="$(openssl rand -base64 128)"
secret/memberlist created
```

Now we can deploy MetalLB!

```bash
kubectl apply -f ./metallb.yaml
podsecuritypolicy.policy/controller created
podsecuritypolicy.policy/speaker created
serviceaccount/controller created
serviceaccount/speaker created
clusterrole.rbac.authorization.k8s.io/metallb-system:controller created
clusterrole.rbac.authorization.k8s.io/metallb-system:speaker created
role.rbac.authorization.k8s.io/config-watcher created
role.rbac.authorization.k8s.io/pod-lister created
clusterrolebinding.rbac.authorization.k8s.io/metallb-system:controller created
clusterrolebinding.rbac.authorization.k8s.io/metallb-system:speaker created
rolebinding.rbac.authorization.k8s.io/config-watcher created
rolebinding.rbac.authorization.k8s.io/pod-lister created
daemonset.apps/speaker created
deployment.apps/controller created
```

As you can see, it deploys many objects, and now we wait for the deployment to finish. We can monitor the deployment of
resources with the `--watch` option in the `metallb-system` namespace:

```bash
kubectl get pods -n metallb-system --watch
NAME                          READY   STATUS              RESTARTS   AGE
controller-5df88bd85d-mvgqn   0/1     ContainerCreating   0          10s
speaker-5knqb                 1/1     Running             0          10s
speaker-k79c9                 1/1     Running             0          10s
speaker-pfs2p                 1/1     Running             0          10s
speaker-sl7fd                 1/1     Running             0          10s
controller-5df88bd85d-mvgqn   1/1     Running             0          12s
```

To complete the configuration, we need to provide MetalLB with a range of IP addresses it controls.
This range has to be on the Docker KIND network:

```bash
docker network inspect -f '{{.IPAM.Config}}' kind
[{172.18.0.0/16  172.18.0.1 map[]} {fc00:f853:ccd:e793::/64  fc00:f853:ccd:e793::1 map[]}]
```

`172.18.0.0/16` is our Docker network running locally.

We want our LoadBalancer IP range to come from this subclass. We
can configure MetalLB, for instance,
to use `172.18.255.200` to `172.18.255.250` by creating the ConfigMap.

The ConfigMap would look like this:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 172.18.255.200-172.18.255.250
```

Let’s deploy it so we can use MetalLB:

```bash
kubectl apply -f ./metallb-configmap.yaml
```

Now we deploy a load balancer for our web app:

```bash
kubectl apply -f services-loadbalancer.yaml
service/loadbalancer-service created
```

For fun let’s scale the web app deployment to 10, if you have the resources for it:

```bash
kubectl scale deployment app --replicas 10

 kubectl get pods -o wide
NAME                  READY  STATUS    RESTARTS  AGE   IP           NODE
app-7bdb9ffd6c-b5x7m  2/2    Running   0         26s   10.244.3.15  kind-worker
app-7bdb9ffd6c-bqtf8  2/2    Running   0         26s   10.244.2.13  kind-worker2
app-7bdb9ffd6c-fb9sf  2/2    Running   0         26s   10.244.3.14  kind-worker
app-7bdb9ffd6c-hrt7b  2/2    Running   0         26s   10.244.2.7   kind-worker2
app-7bdb9ffd6c-l2794  2/2    Running   0         26s   10.244.2.9   kind-worker2
app-7bdb9ffd6c-l4cfx  2/2    Running   0         26s   10.244.3.11  kind-worker2
app-7bdb9ffd6c-rr4kn  2/2    Running   0         23m   10.244.3.10  kind-worker
app-7bdb9ffd6c-s4k92  2/2    Running   0         26s   10.244.3.13  kind-worker
app-7bdb9ffd6c-shmdt  2/2    Running   0         26s   10.244.1.12  kind-worker3
app-7bdb9ffd6c-v87f9  2/2    Running   0         26s   10.244.1.11  kind-worker3
app2-658bcd97bd-4n888 1/1    Running   0         35m   10.244.2.6   kind-worker3
app2-658bcd97bd-mnpkp 1/1    Running   0         35m   10.244.3.7   kind-worker
app2-658bcd97bd-w2qkl 1/1    Running   0         35m   10.244.3.8   kind-worker
dnsutils              1/1    Running   1         75m   10.244.1.2   kind-worker3
postgres-0            1/1    Running   0         75m   10.244.1.4   kind-worker3
postgres-1            1/1    Running   0         75m   10.244.3.4   kind-worker
```

Now we can test the provisioned load balancer.

With more replicas deployed for our app behind the load balancer, we need the external IP of the load balancer,
`172.18.255.200`:

```bash
kubectl get svc loadbalancer-service
NAME                   TYPE           CLUSTER-IP     EXTERNAL-IP
PORT(S)        AGE
loadbalancer-service   LoadBalancer   10.99.24.220   172.18.255.200
80:31276/TCP   52s


kubectl get svc/loadbalancer-service -o=jsonpath='{.status.loadBalancer.ingress[0].ip}'
172.18.255.200
```

Since Docker for Mac or Windows does not expose the KIND network to the host, we cannot directly reach the
`172.18.255.200` LoadBalancer IP on the Docker private network.

We can simulate it by attaching a Docker container to the KIND network and cURLing the load balancer as a workaround.

###### Tip

If you would like to read more about this issue, there is a great [blog post](https://oreil.ly/6rTKJ).

We will use another great networking Docker image called `nicolaka/netshoot` to run locally,
attach to the KIND Docker network, and send requests to our MetalLB load balancer.

If we run it several times, we can see the load balancer is doing its job of routing traffic to different pods:

```bash
docker run --network kind -a stdin -a stdout -i -t nicolaka/netshoot
curl 172.18.255.200/host
NODE: kind-worker, POD IP:10.244.2.7

docker run --network kind -a stdin -a stdout -i -t nicolaka/netshoot
curl 172.18.255.200/host
NODE: kind-worker, POD IP:10.244.2.9

docker run --network kind -a stdin -a stdout -i -t nicolaka/netshoot
curl 172.18.255.200/host
NODE: kind-worker3, POD IP:10.244.3.11

docker run --network kind -a stdin -a stdout -i -t nicolaka/netshoot
curl 172.18.255.200/host
NODE: kind-worker2, POD IP:10.244.1.6

docker run --network kind -a stdin -a stdout -i -t nicolaka/netshoot
curl 172.18.255.200/host
NODE: kind-worker, POD IP:10.244.2.9
```

With each new request, the metalLB service is sending requests to different pods. LoadBalancer, like other services, uses
selectors and labels for the pods, and we can see that in the `kubectl describe endpoints loadbalancer-service`. The pod IP
addresses match our results from the cURL commands:

```bash
kubectl describe endpoints loadbalancer-service
Name:         loadbalancer-service
Namespace:    default
Labels:       app=app
Annotations:  endpoints.kubernetes.io/last-change-trigger-time:
2021-01-30T19:59:57Z
Subsets:
  Addresses:
  10.244.1.6,
  10.244.1.7,
  10.244.1.8,
  10.244.2.10,
  10.244.2.7,
  10.244.2.8,
  10.244.2.9,
  10.244.3.11,
  10.244.3.12,
  10.244.3.9
  NotReadyAddresses:  <none>
  Ports:
    Name          Port  Protocol
    ----          ----  --------
    service-port  8080  TCP

Events:  <none>
```

It is important to remember that LoadBalancer services require specific integrations and will not work without cloud
provider support, or manually installed software such as MetalLB.

They are not (normally) L7 load balancers, and therefore cannot intelligently handle HTTP(S) requests. There is a one-to-one mapping of load balancer to workload, which means that all requests sent to that load balancer must be handled
by the same workload.

###### Tip

While it’s not a network service, it is important to mention the Horizontal Pod Autoscaler service, which that will scale pods in a replication controller, deployment, ReplicaSet, or StatefulSet based on CPU utilization.

We can scale our application to the demands of the users, with no need for configuration changes on anyone’s part.
Kubernetes and the LoadBalancer service take care of all of that for developers, systems, and network administrators.

We will see in the next chapter how we can take that even further using cloud services for autoscaling.

## Services Conclusion

Here are some troubleshooting tips if issues arise with the endpoints or services:

-

Removing the label on the pod allows it to continue to run while also updating the endpoint and service.
The endpoint controller will remove that unlabeled pod from the endpoint objects, and the deployment
will deploy another pod; this will allow you to troubleshoot issues with that specific unlabeled pod
but not adversely affect the service to end customers.
I’ve used this one countless times during development, and we did so in the previous section’s examples.

-

There are two probes that communicate the pod’s health to the Kubelet and the rest of the Kubernetes environment.

-

It is also easy to mess up the YAML manifest, so make sure to compare ports on the service and pods and make sure they match.

-

We discussed network policies in [Chapter 3](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch03.html#container_networking_basics), which can also stop pods from communicating with each other and services. If your cluster network is using network policies, ensure that they are set up appropriately for application traffic flow.

-

Also remember to use diagnostic tools like the `dnsutils` pod; the `netshoot` pods on the cluster network are helpful
debugging tools.

-

If endpoints are taking too long to come up in the cluster,
there are several options that can be configured on the Kubelet to control how fast it responds to change in the Kubernetes environment:

`--kube-api-qps`

Sets the query-per-second rate the Kubelet will use
when communicating with the Kubernetes API server; the default is 5.

`--kube-api-burst`

Temporarily allows API queries to burst to this number; the default is 10.

`--iptables-sync-period`

This is the maximum interval of how often `iptables` rules are refreshed (e.g., 5s, 1m, 2h22m). This must be greater than 0; the default is 30s.

`--ipvs-sync-period duration`

This is the maximum interval of how often IPVS rules are refreshed.
This must be greater than 0; the efault is 30s.

-

Increasing these options for larger clusters is recommended, but also remember this increases the resources on both
the Kubelet and the API server, so keep that in mind.

These tips can help alleviate issues and are good to be aware of as the number of services and pods grow in the cluster.

The various types of services exemplify how powerful the network  abstractions are in Kubernetes. We have dug deep into how these work for each layer of the tool chain. Developers looking to deploy applications to Kubernetes now have the knowledge to pick and choose which services are right for their use cases. No longer will network administrators have to manually update load balancers with IP addresses, with Kubernetes managing that for them.

We have just scratched the surface of what is possible with services. With each new version of Kubernetes, there are
options to tune and configurations to run services. Test each service for your use cases and ensure you are using
the appropriate services to optimize your
applications on the Kubernetes network.

The LoadBalancer service type is the only one that allows for traffic into the cluster, exposing HTTP(S) services
behind a load balancer for external users to connect to. Ingresses support path-based routing, which allows different HTTP paths to be served by different services. The next section will discuss ingress and how it is an alternative to managing connectivity into the cluster resources.

# Ingress

Ingress is a Kubernetes-specific L7 (HTTP) load balancer, which is accessible externally, contrasting with L4
ClusterIP service, which is internal to the cluster. This is the typical choice for exposing an HTTP(S) workload to
external users. An ingress can be a single entry point into an API or a microservice-based architecture. Traffic can
be routed to services based on HTTP information in the request.  Ingress is a configuration spec (with multiple
implementations) for routing HTTP traffic to Kubernetes services. [Figure 5-7](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch05.html#img-ingress) outlines the ingress components.

![Ingress](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0507.png)

###### Figure 5-7. Ingress architecture

To manage traffic in a cluster with ingress, there are two components required: the controller and
rules. The controller manages ingress pods, and the rules deployed define how the traffic is routed.

# Ingress Controllers and Rules

We call ingress implementations ingress *controllers*.
In Kubernetes, a controller is software that is responsible for managing a typical resource type
and making reality match the desired state.

There are two general kinds of controllers: external load balancer controllers and internal load balancer
controllers. External load balancer controllers create a load balancer that exists “outside” the cluster, such as a
cloud provider product. Internal load balancer controllers deploy a load balancer that runs within the cluster and
do not directly solve the problem of routing consumers to the load balancer. There are a myriad of ways that cluster
administrators run internal load balancers, such as running the load balancer on a subset of special nodes, and
routing traffic somehow to those nodes. The primary motivation for choosing an internal load balancer is cost
reduction. An internal load balancer for ingress can route traffic for multiple ingress objects, whereas an external
load balancer controller typically needs one load balancer per ingress. As most cloud providers charge by load
balancer, it is cheaper to support a single cloud load balancer that does fan-out within the cluster, than
many cloud load balancers. Note that this incurs operational overhead and increased latency and compute costs, so be
sure the money you’re saving is worth it. Many companies have a bad habit of optimizing on inconsequential cloud
spend line items.

Let’s look at the spec for an ingress controller. Like LoadBalancer services, most of the spec is universal, but
various ingress controllers have different features and accept different configs. We’ll start with the basics:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: basic-ingress
spec:
  rules:
  - http:
      paths:
      # Send all /demo requests to demo-service.
      - path: /demo
        pathType: Prefix
        backend:
          service:
            name: demo-service
            port:
              number: 80
  # Send all other requests to main-service.
  defaultBackend:
    service:
      name: main-service
      port:
        number: 80
```

The previous example is representative of a typical ingress. It sends traffic to `/demo` to one service and all other
traffic to another. Ingresses have a “default backend” where requests are routed if no rule matches. This can be
configured in many ingress controllers in the controller configuration itself (e.g., a generic 404 page), and many
support the `.spec.defaultBackend` field. Ingresses support multiple ways to specify a path. There are currently three:

ExactMatches the specific path and only the given path (including trailing `/` or lack thereof).

PrefixMatches all paths that start with the given path.

ImplementationSpecificAllows for custom semantics from the current ingress controller.

When a request matches multiple paths, the most specific match is chosen.
For example, if there are rules for `/first` and `/first/second`,
any request starting with `/first/second` will go to the backend for `/first/second`.
If a path matches an exact path and a prefix path, the request will go to the backend for the exact rule.

Ingresses can also use hostnames in rules:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: multi-host-ingress
spec:
  rules:
  - host: a.example.com
    http:
      paths:
      - pathType: Prefix
        path: "/"
        backend:
          service:
            name: service-a
            port:
              number: 80
  - host: b.example.com
    http:
      paths:
      - pathType: Prefix
        path: "/"
        backend:
          service:
            name: service-b
            port:
              number: 80
```

In this example, we serve traffic to `a.example.com` from one service and traffic to `b.example.com` from another.
This is comparable to virtual hosts in web servers. You may want to use host rules to use a single load balancer and IP
to serve multiple unique domains.

Ingresses have basic TLS support:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: demo-ingress-secure
spec:
  tls:
  - hosts:
      - https-example.com
    secretName: demo-tls
  rules:
  - host: https-example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: demo-service
            port:
              number: 80
```

The TLS config references a Kubernetes secret by name, in `.spec.tls.[*].secretName`. Ingress controllers expect the
TLS certificate and key to be provided in `.data."tls.crt"` and `.data."tls.key"` respectively, as shown here:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: demo-tls
type: kubernetes.io/tls
data:
  tls.crt: cert, encoded in base64
  tls.key: key, encoded in base64
```

###### Tip

If you don’t need to manage traditionally issued certificates by hand, you can use [cert-manager](https://oreil.ly/qkN0h) to automatically fetch and update certs.

We mentioned earlier that ingress is simply a spec, and drastically different implementations exist. It’s possible to use multiple ingress controllers in a single cluster, using `IngressClass` settings. An ingress class represents an ingress controller, and therefore a specific ingress implementation.

###### Warning

Annotations in Kubernetes must be strings. Because `true` and `false` have distinct nonstring meanings, you cannot set an annotation to `true` or `false` without quotes. `"true"` and `"false"` are both valid.
This is a [long-running bug](https://oreil.ly/76uSI), which is often encountered when setting a default priority class.

`IngressClass` was introduced in Kubernetes 1.18.
Prior to 1.18, annotating ingresses with `kubernetes.io/ingress.class` was a common convention but relied on all installed ingress controllers to support it. Ingresses can pick an ingress class by setting the class’s name in `.spec.ingressClassName`.

###### Warning

If more than one ingress class is set as default, Kubernetes will not allow you to create an ingress with no ingress class or remove the ingress class from an existing ingress. You can use admission control to prevent multiple ingress classes from being marked as default.

Ingress only supports HTTP(S) requests, which is insufficient if your service uses a different protocol (e.g., most
databases use their own protocols). Some ingress controllers, such as the NGINX ingress controller, do support TCP
and UDP, but this is not the norm.

Now on to deploying an ingress controller so we can add ingress rules to our Golang web server example.

When we deployed our KIND cluster, we had to add several options to allow us to deploy an ingress controller:

-

extraPortMappings allow the local host to make requests to the ingress controller over ports 80/443.

-

Node-labels only allow the ingress controller to run on a specific node(s) matching the label selector.

There are many options to choose from with ingress controllers. The Kubernetes system does not start or have a default
controller like it does with other pieces. The Kubernetes community does support AWS, GCE, and Nginx ingress
controllers. [Table 5-1](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch05.html#brief_list_of_ingress_controller_options) outlines several options for ingress.

| Name | Commercial support | Engine | Protocol support | SSL termination |
| --- | --- | --- | --- | --- |
| Ambassador ingress controller | Yes | Envoy | gRPC, HTTP/2, WebSockets | Yes |
| Community ingress Nginx | No | NGINX | gRPC, HTTP/2, WebSockets | Yes |
| NGINX Inc. ingress | Yes | NGINX | HTTP, Websocket, gRPC | Yes |
| HAProxy ingress | Yes | HAProxy | gRPC, HTTP/2, WebSockets | Yes |
| Istio Ingress | No | Envoy | HTTP, HTTPS, gRPC, HTTP/2 | Yes |
| Kong ingress controller for Kubernetes | Yes | Lua on top of Nginx | gRPC, HTTP/2 | Yes |
| Traefik Kubernetes ingress | Yes | Traefik | HTTP/2, gRPC, and WebSockets | Yes |

Some things to consider when deciding on the ingress for your clusters:

-

Protocol support: Do you need more than TCP/UDP, for example gRPC integration or WebSocket?

-

Commercial support: Do you need commercial support?

-

Advanced features: Are JWT/oAuth2 authentication or circuit breakers requirements for your
applications?

-

API gateway features: Do you need some API gateway functionalities such as rate-limiting?

-

Traffic distribution: Does your application require support for specialized traffic distribution like canary A/B testing or mirroring?

For our example, we have chosen to use the Community version of the NGINX ingress controller.

###### Tip

For more ingress controllers to choose from, [kubernetes.io](https://oreil.ly/Lzn5q) maintains a list.

Let’s deploy the NGINX ingress controller into our KIND cluster:

```bash
kubectl apply -f ingress.yaml
namespace/ingress-nginx created
serviceaccount/ingress-nginx created
configmap/ingress-nginx-controller created
clusterrole.rbac.authorization.k8s.io/ingress-nginx created
clusterrolebinding.rbac.authorization.k8s.io/ingress-nginx created
role.rbac.authorization.k8s.io/ingress-nginx created
rolebinding.rbac.authorization.k8s.io/ingress-nginx created
service/ingress-nginx-controller-admission created
service/ingress-nginx-controller created
deployment.apps/ingress-nginx-controller created
validatingwebhookconfiguration.admissionregistration.k8s.io/
ingress-nginx-admission created
serviceaccount/ingress-nginx-admission created
clusterrole.rbac.authorization.k8s.io/ingress-nginx-admission created
clusterrolebinding.rbac.authorization.k8s.io/ingress-nginx-admission created
role.rbac.authorization.k8s.io/ingress-nginx-admission created
rolebinding.rbac.authorization.k8s.io/ingress-nginx-admission created
job.batch/ingress-nginx-admission-create created
job.batch/ingress-nginx-admission-patch created
```

As with all deployments, we must wait for the controller to be ready before we can use it. With the following command, we can
verify if our ingress controller is ready for use:

```bash
kubectl wait --namespace ingress-nginx \
>   --for=condition=ready pod \
>   --selector=app.kubernetes.io/component=controller \
>   --timeout=90s
pod/ingress-nginx-controller-76b5f89575-zps4k condition met
```

The controller is deployed to the cluster, and now we’re ready to write ingress rules for our application.

### Deploy ingress rules

Our YAML manifest defines several ingress rules to use with our Golang web server example:

```bash
kubectl apply -f ingress-rule.yaml
ingress.extensions/ingress-resource created

kubectl get ingress
NAME               CLASS    HOSTS   ADDRESS   PORTS   AGE
ingress-resource   <none>   *                 80      4s
```

With `describe` we can see all the backends that map to the ClusterIP service and the pods:

```bash
kubectl describe ingress
Name:             ingress-resource
Namespace:        default
Address:
Default backend:  default-http-backend:80 (<error:
endpoints "default-http-backend" not found>)
Rules:
  Host        Path  Backends
  ----        ----  --------
  *
              /host  clusterip-service:8080 (
10.244.1.6:8080,10.244.1.7:8080,10.244.1.8:8080)
Annotations:  kubernetes.io/ingress.class: nginx
Events:
  Type    Reason  Age   From                      Message
  ----    ------  ----  ----                      -------
  Normal  Sync    17s   nginx-ingress-controller  Scheduled for sync
```

Our ingress rule is only for the `/host` route and will route requests to our
`clusterip-service:8080` service.

We can test that with cURL to http://localhost/host:

```
curl localhost/host
NODE: kind-worker2, POD IP:10.244.1.6
curl localhost/healthz
```

Now we can see how powerful ingresses are; let’s deploy a second deployment and ClusterIP service.

Our new deployment and service will be used to answer the requests for `/data`:

```bash
kubectl apply -f ingress-example-2.yaml
deployment.apps/app2 created
service/clusterip-service-2 configured
ingress.extensions/ingress-resource-2 configured
```

Now both the `/host` and `/data` work but are going to separate services:

```
curl localhost/host
NODE: kind-worker2, POD IP:10.244.1.6

curl localhost/data
Database Connected
```

Since ingress works on layer 7, there are many more options to route traffic with, such as host header and URI path.

For more advanced traffic routing and release patterns, a service mesh is required to be deployed
in the cluster network. Let’s dig into that next.

# Service Meshes

A new cluster with the default options has some limitations. So, let’s get an understanding for what those limitations
are and how a service mesh can resolve some of those limitations. A *service mesh* is an API-driven infrastructure
layer for handling service-to-service communication.

From a security point of view, all traffic inside the cluster is unencrypted between pods, and each
application team that runs a service must configure monitoring separately for each service. We have discussed the
service types, but we have not discussed how to update deployments of pods for them. Service meshes support more than
the basic deployment type; they support rolling updates and re-creations, like Canary does. From a developer’s perspective, injecting faults
into the network is useful, but also not directly supported in default Kubernetes network deployments. With service
meshes, developers can add fault testing, and instead of just killing pods, you can use service meshes to inject
delays—again, each application would have to build in fault testing or circuit breaking.

There are several pieces of functionality that a service mesh enhances or provides in a default Kubernetes cluster
network:

Service DiscoveryInstead of relying on DNS for service discovery, the service mesh manages service discovery,
and removes the need for it to be implemented in each individual application.

Load BalancingThe service mesh adds more advanced load balancing algorithms such as least request, consistent
hashing, and zone aware.

Communication ResiliencyThe service mesh can increase communication resilience for applications by not having to
implement retries, timeouts, circuit breaking,  or rate limiting in application code.

SecurityA service mesh can provide the folllowing:
* End-to-end encryption with mTLS between services
* Authorization policies, which authorize what services can communicate with each other, not just at the layer 3 and 4 levels like in Kubernetes network polices.

ObservabilityService meshes add in observability by enriching the layer 7 metrics and adding tracing and alerting.

Routing ControlTraffic shifting and mirroring in the cluster.

APIAll of this can be controlled via an API provided by the service mesh
implementation.

Let’s walk through several components of a service mesh in [Figure 5-8](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch05.html#img-service-mesh).

![Service mesh Components](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0508.png)

###### Figure 5-8. Service mesh components

Traffic is handled differently depending on the component or destination of traffic. Traffic into and out of the cluster
is managed by the gateways. Traffic between the frontend, backend, and user service is all encrypted with Mutual
TLS (mTLS) and is handled by the service mesh. All the traffic to the frontend, backend, and user pods in the service mesh is
proxied by the sidecar proxy deployed within the pods. Even if the control plane is down and updates cannot be made to the mesh, the service and application traffic are not affected.

There are several options to use when deploying a service mesh; here are highlights of just a few:

-

Istio

-

Uses a Go control plane with an Envoy proxy.

-

This is a Kubernetes-native solution that was initially released by Lyft.

-

Consul

-

Uses HashiCorp Consul as the control plane.

-

Consul Connect uses an agent installed on every node as a DaemonSet, which communicates
with the Envoy sidecar proxies that handle routing and forwarding of traffic.

-

AWS App Mesh

-

Is an AWS-managed solution that implements its own control plane.

-

Does not have mTLS or traffic policy.

-

Uses the Envoy proxy for the data plane.

-

Linkerd

-

Also uses Go for the control plane with the Linkerd proxy.

-

No traffic shifting and no distributed tracing.

-

Is a Kubernetes-only solution, which results in fewer moving pieces and means that Linkerd has less complexity overall.

It is our opinion that the best use case for a service mesh is mTLS between services. Other higher-level use cases for developers include circuit breaking and fault testing for APIs. For network administrators, advanced routing policies and algorithms can be deployed with service meshes.

Let’s look at a service mesh example. The first thing you need to do if you haven’t already is [install the Linkerd CLI](https://oreil.ly/jVaPm).

Your choices are cURL, bash, or brew if you’re on a Mac:

```
curl -sL https://run.linkerd.io/install | sh

OR

brew install linkerd

linkerd version
Client version: stable-2.9.2
Server version: unavailable
```

This preflight checklist will verify that our cluster can run Linkerd:

```bash
linkerd check --pre
kubernetes-api
--------------
√ can initialize the client
√ can query the Kubernetes API

kubernetes-version
------------------
√ is running the minimum Kubernetes API version
√ is running the minimum kubectl version

pre-kubernetes-setup
--------------------
√ control plane namespace does not already exist
√ can create non-namespaced resources
√ can create ServiceAccounts
√ can create Services
√ can create Deployments
√ can create CronJobs
√ can create ConfigMaps
√ can create Secrets
√ can read Secrets
√ can read extension-apiserver-authentication configmap
√ no clock skew detected

pre-kubernetes-capability
-------------------------
√ has NET_ADMIN capability
√ has NET_RAW capability

linkerd-version
---------------
√ can determine the latest version
√ cli is up-to-date

Status check results are √
```

The Linkerd CLI tool can install Linkerd for us onto our KIND cluster:

```bash
linkerd install | kubectl apply -f -
namespace/linkerd created
clusterrole.rbac.authorization.k8s.io/linkerd-linkerd-identity created
clusterrolebinding.rbac.authorization.k8s.io/linkerd-linkerd-identity created
serviceaccount/linkerd-identity created
clusterrole.rbac.authorization.k8s.io/linkerd-linkerd-controller created
clusterrolebinding.rbac.authorization.k8s.io/linkerd-linkerd-controller created
serviceaccount/linkerd-controller created
clusterrole.rbac.authorization.k8s.io/linkerd-linkerd-destination created
clusterrolebinding.rbac.authorization.k8s.io/linkerd-linkerd-destination created
serviceaccount/linkerd-destination created
role.rbac.authorization.k8s.io/linkerd-heartbeat created
rolebinding.rbac.authorization.k8s.io/linkerd-heartbeat created
serviceaccount/linkerd-heartbeat created
role.rbac.authorization.k8s.io/linkerd-web created
rolebinding.rbac.authorization.k8s.io/linkerd-web created
clusterrole.rbac.authorization.k8s.io/linkerd-linkerd-web-check created
clusterrolebinding.rbac.authorization.k8s.io/linkerd-linkerd-web-check created
clusterrolebinding.rbac.authorization.k8s.io/linkerd-linkerd-web-admin created
serviceaccount/linkerd-web created
customresourcedefinition.apiextensions.k8s.io/serviceprofiles.linkerd.io created
customresourcedefinition.apiextensions.k8s.io/trafficsplits.split.smi-spec.io
created
clusterrole.rbac.authorization.k8s.io/linkerd-linkerd-proxy-injector created
clusterrolebinding.rbac.authorization.k8s.io/linkerd-linkerd-proxy-injector
created
serviceaccount/linkerd-proxy-injector created
secret/linkerd-proxy-injector-k8s-tls created
mutatingwebhookconfiguration.admissionregistration.k8s.io
 /linkerd-proxy-injector-webhook-config created
clusterrole.rbac.authorization.k8s.io/linkerd-linkerd-sp-validator created
clusterrolebinding.rbac.authorization.k8s.io/linkerd-linkerd-sp-validator
created
serviceaccount/linkerd-sp-validator created
secret/linkerd-sp-validator-k8s-tls created
validatingwebhookconfiguration.admissionregistration.k8s.io
 /linkerd-sp-validator-webhook-config created
clusterrole.rbac.authorization.k8s.io/linkerd-linkerd-tap created
clusterrole.rbac.authorization.k8s.io/linkerd-linkerd-tap-admin created
clusterrolebinding.rbac.authorization.k8s.io/linkerd-linkerd-tap created
clusterrolebinding.rbac.authorization.k8s.io/linkerd-linkerd-tap-auth-delegator
created
serviceaccount/linkerd-tap created
rolebinding.rbac.authorization.k8s.io/linkerd-linkerd-tap-auth-reader created
secret/linkerd-tap-k8s-tls created
apiservice.apiregistration.k8s.io/v1alpha1.tap.linkerd.io created
podsecuritypolicy.policy/linkerd-linkerd-control-plane created
role.rbac.authorization.k8s.io/linkerd-psp created
rolebinding.rbac.authorization.k8s.io/linkerd-psp created
configmap/linkerd-config created
secret/linkerd-identity-issuer created
service/linkerd-identity created
service/linkerd-identity-headless created
deployment.apps/linkerd-identity created
service/linkerd-controller-api created
deployment.apps/linkerd-controller created
service/linkerd-dst created
service/linkerd-dst-headless created
deployment.apps/linkerd-destination created
cronjob.batch/linkerd-heartbeat created
service/linkerd-web created
deployment.apps/linkerd-web created
deployment.apps/linkerd-proxy-injector created
service/linkerd-proxy-injector created
service/linkerd-sp-validator created
deployment.apps/linkerd-sp-validator created
service/linkerd-tap created
deployment.apps/linkerd-tap created
serviceaccount/linkerd-grafana created
configmap/linkerd-grafana-config created
service/linkerd-grafana created
deployment.apps/linkerd-grafana created
clusterrole.rbac.authorization.k8s.io/linkerd-linkerd-prometheus created
clusterrolebinding.rbac.authorization.k8s.io/linkerd-linkerd-prometheus created
serviceaccount/linkerd-prometheus created
configmap/linkerd-prometheus-config created
service/linkerd-prometheus created
deployment.apps/linkerd-prometheus created
secret/linkerd-config-overrides created
```

As with the ingress controller and MetalLB, we can see that a lot of components are installed in our cluster.

Linkerd can validate the installation with the `linkerd check` command.

It will validate a plethora of checks for the Linkerd install, included but not limited to the Kubernetes API version,
controllers, pods, and configs to run Linkerd, as well as all the services, versions, and APIs needed to run Linkerd:

```bash
linkerd check
kubernetes-api
--------------
√ can initialize the client
√ can query the Kubernetes API

kubernetes-version
------------------
√ is running the minimum Kubernetes API version
√ is running the minimum kubectl version

linkerd-existence
-----------------
√ 'linkerd-config' config map exists
√ heartbeat ServiceAccount exists
√ control plane replica sets are ready
√ no unschedulable pods
√ controller pod is running
√ can initialize the client
√ can query the control plane API

linkerd-config
--------------
√ control plane Namespace exists
√ control plane ClusterRoles exist
√ control plane ClusterRoleBindings exist
√ control plane ServiceAccounts exist
√ control plane CustomResourceDefinitions exist
√ control plane MutatingWebhookConfigurations exist
√ control plane ValidatingWebhookConfigurations exist
√ control plane PodSecurityPolicies exist

linkerd-identity
----------------
√ certificate config is valid
√ trust anchors are using supported crypto algorithm
√ trust anchors are within their validity period
√ trust anchors are valid for at least 60 days
√ issuer cert is using supported crypto algorithm
√ issuer cert is within its validity period
√ issuer cert is valid for at least 60 days
√ issuer cert is issued by the trust anchor

linkerd-webhooks-and-apisvc-tls
-------------------------------
√ tap API server has valid cert
√ tap API server cert is valid for at least 60 days
√ proxy-injector webhook has valid cert
√ proxy-injector cert is valid for at least 60 days
√ sp-validator webhook has valid cert
√ sp-validator cert is valid for at least 60 days

linkerd-api
-----------
√ control plane pods are ready
√ control plane self-check
√ [kubernetes] control plane can talk to Kubernetes
√ [prometheus] control plane can talk to Prometheus
√ tap api service is running

linkerd-version
---------------
√ can determine the latest version
√ cli is up-to-date

control-plane-version
---------------------
√ control plane is up-to-date
√ control plane and cli versions match

linkerd-prometheus
------------------
√ prometheus add-on service account exists
√ prometheus add-on config map exists
√ prometheus pod is running

linkerd-grafana
---------------
√ grafana add-on service account exists
√ grafana add-on config map exists
√ grafana pod is running

Status check results are √
```

Now that everything looks good with our install of Linkerd, we can add our application to the service mesh:

```bash
kubectl -n linkerd get deploy
NAME                     READY   UP-TO-DATE   AVAILABLE   AGE
linkerd-controller       1/1     1            1           3m17s
linkerd-destination      1/1     1            1           3m17s
linkerd-grafana          1/1     1            1           3m16s
linkerd-identity         1/1     1            1           3m17s
linkerd-prometheus       1/1     1            1           3m16s
linkerd-proxy-injector   1/1     1            1           3m17s
linkerd-sp-validator     1/1     1            1           3m17s
linkerd-tap              1/1     1            1           3m17s
linkerd-web              1/1     1            1           3m17s
```

Let’s pull up the Linkerd console to investigate what we have just deployed. We can start the console with `linkerd dashboard &`.

This will proxy the console to our local machine available at `http://localhost:50750`:

```bash
linkerd viz install | kubectl apply -f -
linkerd viz dashboard
Linkerd dashboard available at:
http://localhost:50750
Grafana dashboard available at:
http://localhost:50750/grafana
Opening Linkerd dashboard in the default browser
```

###### Tip

If you’re having issues with reaching the dashboard, you can run `linkerd viz check` and find more help in the Linkerd
[documentation](https://oreil.ly/MqgAp).

We can see all our deployed objects from the previous exercises in [Figure 5-9](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch05.html#linkerd-dashboards).

Our ClusterIP service is not part of the Linkerd service mesh. We will need to use the proxy injector to add our service
to the mesh. It accomplishes this by watching for a specific annotation that can be added either with Linkerd `inject` or
by hand to the pod’s spec.

![Linkderd Dashboard](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0509.png)

###### Figure 5-9. Linkerd dashboard

Let’s remove some older exercises’ resources for clarity:

```bash
kubectl delete -f ingress-example-2.yaml
deployment.apps "app2" deleted
service "clusterip-service-2" deleted
ingress.extensions "ingress-resource-2" deleted

kubectl delete pods app-5586fc9d77-7frts
pod "app-5586fc9d77-7frts" deleted

kubectl delete -f ingress-rule.yaml
ingress.extensions "ingress-resource" deleted
```

We can use the Linkerd CLI to inject the proper annotations into our deployment spec, so that will become part of the
mesh.

We first need to get our application manifest, `cat web.yaml`, and use Linkerd to inject the annotations, `linkerd
inject -`, then apply them back to the Kubernetes API with `kubectl apply -f -`:

```bash
cat web.yaml | linkerd inject - | kubectl apply -f -

deployment "app" injected

deployment.apps/app configured
```

If we describe our app deployment, we can see that Linkerd has injected new annotations for us,
`Annotations:  linkerd.io/inject: enabled`:

```bash
kubectl describe deployment app
Name:                   app
Namespace:              default
CreationTimestamp:      Sat, 30 Jan 2021 13:48:47 -0500
Labels:                 <none>
Annotations:            deployment.kubernetes.io/revision: 3
Selector:               app=app
Replicas:               1 desired | 1 updated | 1 total | 1 available |
0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:       app=app
  Annotations:  linkerd.io/inject: enabled
  Containers:
   go-web:
    Image:      strongjz/go-web:v0.0.6
    Port:       8080/TCP
    Host Port:  0/TCP
    Liveness:   http-get http://:8080/healthz delay=5s timeout=1s period=5s
    Readiness:  http-get http://:8080/ delay=5s timeout=1s period=5s
    Environment:
      MY_NODE_NAME:             (v1:spec.nodeName)
      MY_POD_NAME:              (v1:metadata.name)
      MY_POD_NAMESPACE:         (v1:metadata.namespace)
      MY_POD_IP:                (v1:status.podIP)
      MY_POD_SERVICE_ACCOUNT:   (v1:spec.serviceAccountName)
      DB_HOST:                 postgres
      DB_USER:                 postgres
      DB_PASSWORD:             mysecretpassword
      DB_PORT:                 5432
    Mounts:                    <none>
  Volumes:                     <none>
Conditions:
 Type           Status  Reason
 ----           ------  ------
 Available      True    MinimumReplicasAvailable
 Progressing    True    NewReplicaSetAvailable
OldReplicaSets:  <none>
NewReplicaSet:   app-78dfbb4854 (1/1 replicas created)
Events:
 Type   Reason            Age   From                   Message
 ----   ------            ----  ----                   -------
 Normal ScalingReplicaSet 4m4s  deployment-controller  Scaled down app-5586fc9d77
 Normal ScalingReplicaSet 4m4s  deployment-controller  Scaled up app-78dfbb4854
 Normal Injected          4m4s  linkerd-proxy-injector Linkerd sidecar injected
 Normal ScalingReplicaSet 3m54s deployment-controller  Scaled app-5586fc9d77
```

If we navigate to the app in the dashboard, we can see that our deployment is part of the Linkerd service mesh now, as
shown in [Figure 5-10](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch05.html#app-dashboards).

![App Linkderd Dashboard](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0510.png)

###### Figure 5-10. Web app deployment linkerd dashboard

The CLI can also display our stats for us:

```
linkerd stat deployments -n default
NAME  MESHED  SUCCESS    RPS LATENCY_P50 LATENCY_P95 LATENCY_P99 TCP_CONN
app      1/1  100.00% 0.4rps         1ms         1ms         1ms              1
```

Again, let’s scale up our deployment:

```bash
kubectl scale deploy app --replicas 10
deployment.apps/app scaled
```

In [Figure 5-11](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch05.html#app-stats), we navigate to the web browser and open [this link](https://oreil.ly/qQx9T) so we can watch the stats in real time. Select the
default namespaces, and in Resources select our deployment/app. Then click “start for the web” to start displaying the metrics.

In a separate terminal let’s use the `netshoot` image, but this time running inside our KIND cluster:

```bash
kubectl run tmp-shell --rm -i --tty --image nicolaka/netshoot -- /bin/bash
If you don't see a command prompt, try pressing enter.
bash-5.0#
```

![App Stats Dashboard](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0511.png)

###### Figure 5-11. Web app dashboard

Let’s send a few hundred queries and see the stats:

```
bash-5.0#for i in `seq 1 100`;
do curl http://clusterip-service/host && sleep 2;
done
```

In our terminal we can see all the liveness and readiness probes as well as our `/host` requests.

`tmp-shell` is our `netshoot` bash terminal with our `for` loop running.

`10.244.2.1`, `10.244.3.1`, and `10.244.2.1` are the Kubelets of the hosts running our probes for us:

```
linkerd viz stat deploy
NAME   MESHED   SUCCESS     RPS  LATENCY_P50  LATENCY_P95  LATENCY_P99  TCP_CONN
app       1/1   100.00%  0.7rps          1ms          1ms          1ms         3
```

Our example showed the observability functionality for a service mesh only. Linkerd, Istio,
and the like have many more options available for developers and network administrators to control,
monitor, and troubleshoot services running inside their cluster network. As with the ingress controller,
there are many options and features available. It is up to you and your teams to decide what
functionality and features are important for your networks.

# Conclusion

The Kubernetes networking world is feature rich with many options for teams to deploy, test, and manage with their Kubernetes cluster. Each new addition will add complexity and overhead to the cluster operations. We have given developers, network administrators, and system administrators a view into the abstractions that Kubernetes offers.

From internal traffic to external traffic to the cluster, teams  must choose what abstractions work best for their workloads. This is no small task, and now you are armed with the knowledge to begin those discussions.

In our next chapter, we take our Kubernetes services and network learnings to the cloud! We will explore the network
services offered by each cloud provider and how they are integrated into their Kubernetes managed service offering.
