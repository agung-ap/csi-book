# Chapter 8. Accessing pod metadata and other resources from applications

### **This chapter covers**

- Using the Downward API to pass information into containers
- Exploring the Kubernetes REST API
- Leaving authentication and server verification to `kubectl proxy`
- Accessing the API server from within a container
- Understanding the ambassador container pattern
- Using Kubernetes client libraries

Applications often need information about the environment they’re running in, including details about themselves and that of other components in the cluster. You’ve already seen how Kubernetes enables service discovery through environment variables or DNS, but what about other information? In this chapter, you’ll see how certain pod and container metadata can be passed to the container and how easy it is for an app running inside a container to talk to the Kubernetes API server to get information about the resources deployed in the cluster and even how to create or modify those resources.

## 8.1. Passing metadata through the Downward API

In the previous chapter you saw how you can pass configuration data to your applications through environment variables or through `configMap` and `secret` volumes. This works well for data that you set yourself and that is known before the pod is scheduled to a node and run there. But what about data that isn’t known up until that point—such as the pod’s IP, the host node’s name, or even the pod’s own name (when the name is generated; for example, when the pod is created by a ReplicaSet or similar controller)? And what about data that’s already specified elsewhere, such as a pod’s labels and annotations? You don’t want to repeat the same information in multiple places.

Both these problems are solved by the Kubernetes Downward API. It allows you to pass metadata about the pod and its environment through environment variables or files (in a `downwardAPI` volume). Don’t be confused by the name. The Downward API isn’t like a REST endpoint that your app needs to hit so it can get the data. It’s a way of having environment variables or files populated with values from the pod’s specification or status, as shown in [figure 8.1](/book/kubernetes-in-action/chapter-8/ch08fig01).

![Figure 8.1. The Downward API exposes pod metadata through environment variables or files.](https://drek4537l1klr.cloudfront.net/luksa/Figures/08fig01_alt.jpg)

### 8.1.1. Understanding the available metadata

The Downward API enables you to expose the pod’s own metadata to the processes running inside that pod. Currently, it allows you to pass the following information to your containers:

- The pod’s name
- The pod’s IP address
- The namespace the pod belongs to
- The name of the node the pod is running on
- The name of the service account the pod is running under
- The CPU and memory requests for each container
- The CPU and memory limits for each container
- The pod’s labels
- The pod’s annotations

Most of the items in the list shouldn’t require further explanation, except perhaps the service account and CPU/memory requests and limits, which we haven’t introduced yet. We’ll cover service accounts in detail in [chapter 12](/book/kubernetes-in-action/chapter-12/ch12). For now, all you need to know is that a service account is the account that the pod authenticates as when talking to the API server. CPU and memory requests and limits are explained in [chapter 14](/book/kubernetes-in-action/chapter-14/ch14). They’re the amount of CPU and memory guaranteed to a container and the maximum amount it can get.

Most items in the list can be passed to containers either through environment variables or through a `downwardAPI` volume, but labels and annotations can only be exposed through the volume. Part of the data can be acquired by other means (for example, from the operating system directly), but the Downward API provides a simpler alternative.

Let’s look at an example to pass metadata to your containerized process.

### 8.1.2. Exposing metadata through environment variables

First, let’s look at how you can pass the pod’s and container’s metadata to the container through environment variables. You’ll create a simple single-container pod from the following listing’s manifest.

##### Listing 8.1. Downward API used in environment variables: downward-api-env.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: downward
spec:
  containers:
  - name: main
    image: busybox
    command: ["sleep", "9999999"]
    resources:
      requests:
        cpu: 15m
        memory: 100Ki
      limits:
        cpu: 100m
        memory: 4Mi
    env:
    - name: POD_NAME
      valueFrom:
        fieldRef:
          fieldPath: metadata.name
    - name: POD_NAMESPACE
      valueFrom:
        fieldRef:
          fieldPath: metadata.namespace
    - name: POD_IP
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
    - name: NODE_NAME
      valueFrom:
        fieldRef:
          fieldPath: spec.nodeName
    - name: SERVICE_ACCOUNT
      valueFrom:
        fieldRef:
          fieldPath: spec.serviceAccountName
    - name: CONTAINER_CPU_REQUEST_MILLICORES
      valueFrom:
        resourceFieldRef:
          resource: requests.cpu
          divisor: 1m
    - name: CONTAINER_MEMORY_LIMIT_KIBIBYTES
      valueFrom:
        resourceFieldRef:
          resource: limits.memory
          divisor: 1Ki
```

When your process runs, it can look up all the environment variables you defined in the pod spec. [Figure 8.2](/book/kubernetes-in-action/chapter-8/ch08fig02) shows the environment variables and the sources of their values. The pod’s name, IP, and namespace will be exposed through the `POD_NAME`, `POD_IP`, and `POD_NAMESPACE` environment variables, respectively. The name of the node the container is running on will be exposed through the `NODE_NAME` variable. The name of the service account is made available through the `SERVICE_ACCOUNT` environment variable. You’re also creating two environment variables that will hold the amount of CPU requested for this container and the maximum amount of memory the container is allowed to consume.

![Figure 8.2. Pod metadata and attributes can be exposed to the pod through environment variables.](https://drek4537l1klr.cloudfront.net/luksa/Figures/08fig02_alt.jpg)

For environment variables exposing resource limits or requests, you specify a divisor. The actual value of the limit or the request will be divided by the divisor and the result exposed through the environment variable. In the previous example, you’re setting the divisor for CPU requests to `1m` (one milli-core, or one one-thousandth of a CPU core). Because you’ve set the CPU request to `15m`, the environment variable `CONTAINER_CPU_REQUEST_MILLICORES` will be set to `15`. Likewise, you set the memory limit to `4Mi` (4 mebibytes) and the divisor to `1Ki` (1 Kibibyte), so the `CONTAINER_MEMORY_LIMIT_KIBIBYTES` environment variable will be set to `4096`.

The divisor for CPU limits and requests can be either `1`, which means one whole core, or `1m`, which is one millicore. The divisor for memory limits/requests can be `1` (byte), `1k` (kilobyte) or `1Ki` (kibibyte), `1M` (megabyte) or `1Mi` (mebibyte), and so on.

After creating the pod, you can use `kubectl exec` to see all these environment variables in your container, as shown in the following listing.

##### Listing 8.2. Environment variables in the downward pod

```bash
$ kubectl exec downward env
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
HOSTNAME=downward
CONTAINER_MEMORY_LIMIT_KIBIBYTES=4096
POD_NAME=downward
POD_NAMESPACE=default
POD_IP=10.0.0.10
NODE_NAME=gke-kubia-default-pool-32a2cac8-sgl7
SERVICE_ACCOUNT=default
CONTAINER_CPU_REQUEST_MILLICORES=15
KUBERNETES_SERVICE_HOST=10.3.240.1
KUBERNETES_SERVICE_PORT=443
...
```

All processes running inside the container can read those variables and use them however they need.

### 8.1.3. Passing metadata through files in a downwardAPI volume

If you prefer to expose the metadata through files instead of environment variables, you can define a `downwardAPI` volume and mount it into your container. You must use a `downwardAPI` volume for exposing the pod’s labels or its annotations, because neither can be exposed through environment variables. We’ll discuss why later.

As with environment variables, you need to specify each metadata field explicitly if you want to have it exposed to the process. Let’s see how to modify the previous example to use a volume instead of environment variables, as shown in the following listing.

##### Listing 8.3. Pod with a `downwardAPI` volume: downward-api-volume.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: downward
  labels:
    foo: bar
  annotations:
    key1: value1
    key2: |
      multi
      line
      value
spec:
  containers:
  - name: main
    image: busybox
    command: ["sleep", "9999999"]
    resources:
      requests:
        cpu: 15m
        memory: 100Ki
      limits:
        cpu: 100m
        memory: 4Mi
    volumeMounts:
    - name: downward
      mountPath: /etc/downward
  volumes:
  - name: downward
    downwardAPI:
      items:
      - path: "podName"
        fieldRef:
          fieldPath: metadata.name
      - path: "podNamespace"
        fieldRef:
          fieldPath: metadata.namespace
      - path: "labels"

        fieldRef:

          fieldPath: metadata.labels

      - path: "annotations"
        fieldRef:
          fieldPath: metadata.annotations
      - path: "containerCpuRequestMilliCores"
        resourceFieldRef:
          containerName: main
          resource: requests.cpu
          divisor: 1m
      - path: "containerMemoryLimitBytes"
        resourceFieldRef:
          containerName: main
          resource: limits.memory
          divisor: 1
```

Instead of passing the metadata through environment variables, you’re defining a volume called `downward` and mounting it in your container under /etc/downward. The files this volume will contain are configured under the `downwardAPI.items` attribute in the volume specification.

Each item specifies the `path` (the filename) where the metadata should be written to and references either a pod-level field or a container resource field whose value you want stored in the file (see [figure 8.3](/book/kubernetes-in-action/chapter-8/ch08fig03)).

![Figure 8.3. Using a downwardAPI volume to pass metadata to the container](https://drek4537l1klr.cloudfront.net/luksa/Figures/08fig03_alt.jpg)

Delete the previous pod and create a new one from the manifest in the previous listing. Then look at the contents of the mounted `downwardAPI` volume directory. You mounted the volume under /etc/downward/, so list the files in there, as shown in the following listing.

##### Listing 8.4. Files in the `downwardAPI` volume

```bash
$ kubectl exec downward ls -lL /etc/downward
-rw-r--r--   1 root   root   134 May 25 10:23 annotations
-rw-r--r--   1 root   root     2 May 25 10:23 containerCpuRequestMilliCores
-rw-r--r--   1 root   root     7 May 25 10:23 containerMemoryLimitBytes
-rw-r--r--   1 root   root     9 May 25 10:23 labels
-rw-r--r--   1 root   root     8 May 25 10:23 podName
-rw-r--r--   1 root   root     7 May 25 10:23 podNamespace
```

---

##### Note

As with the `configMap` and `secret` volumes, you can change the file permissions through the `downwardAPI` volume’s `defaultMode` property in the pod spec.

---

Each file corresponds to an item in the volume’s definition. The contents of files, which correspond to the same metadata fields as in the previous example, are the same as the values of environment variables you used before, so we won’t show them here. But because you couldn’t expose labels and annotations through environment variables before, examine the following listing for the contents of the two files you exposed them in.

##### Listing 8.5. Displaying labels and annotations in the `downwardAPI` volume

```bash
$ kubectl exec downward cat /etc/downward/labels
foo="bar"

$ kubectl exec downward cat /etc/downward/annotations
key1="value1"
key2="multi\nline\nvalue\n"
kubernetes.io/config.seen="2016-11-28T14:27:45.664924282Z"
kubernetes.io/config.source="api"
```

As you can see, each label/annotation is written in the `key=value` format on a separate line. Multi-line values are written to a single line with newline characters denoted with `\n`.

##### Updating labels and annotations

You may remember that labels and annotations can be modified while a pod is running. As you might expect, when they change, Kubernetes updates the files holding them, allowing the pod to always see up-to-date data. This also explains why labels and annotations can’t be exposed through environment variables. Because environment variable values can’t be updated afterward, if the labels or annotations of a pod were exposed through environment variables, there’s no way to expose the new values after they’re modified.

##### Referring to container-level metadata in the volume specification

Before we wrap up this section, we need to point out one thing. When exposing container-level metadata, such as a container’s resource limit or requests (done using `resourceFieldRef`), you need to specify the name of the container whose resource field you’re referencing, as shown in the following listing.

##### Listing 8.6. Referring to container-level metadata in a `downwardAPI` volume

```
spec:
  volumes:
  - name: downward
    downwardAPI:
      items:
      - path: "containerCpuRequestMilliCores"
        resourceFieldRef:
          containerName: main                    #1
          resource: requests.cpu
          divisor: 1m
```

The reason for this becomes obvious if you consider that volumes are defined at the pod level, not at the container level. When referring to a container’s resource field inside a volume specification, you need to explicitly specify the name of the container you’re referring to. This is true even for single-container pods.

Using volumes to expose a container’s resource requests and/or limits is slightly more complicated than using environment variables, but the benefit is that it allows you to pass one container’s resource fields to a different container if needed (but both containers need to be in the same pod). With environment variables, a container can only be passed its own resource limits and requests.

##### Understanding when to use the Downward API

As you’ve seen, using the Downward API isn’t complicated. It allows you to keep the application Kubernetes-agnostic. This is especially useful when you’re dealing with an existing application that expects certain data in environment variables. The Downward API allows you to expose the data to the application without having to rewrite the application or wrap it in a shell script, which collects the data and then exposes it through environment variables.

But the metadata available through the Downward API is fairly limited. If you need more, you’ll need to obtain it from the Kubernetes API server directly. You’ll learn how to do that next.

## 8.2. Talking to the Kubernetes API server

We’ve seen how the Downward API provides a simple way to pass certain pod and container metadata to the process running inside them. It only exposes the pod’s own metadata and a subset of all of the pod’s data. But sometimes your app will need to know more about other pods and even other resources defined in your cluster. The Downward API doesn’t help in those cases.

As you’ve seen throughout the book, information about services and pods can be obtained by looking at the service-related environment variables or through DNS. But when the app needs data about other resources or when it requires access to the most up-to-date information as possible, it needs to talk to the API server directly (as shown in [figure 8.4](/book/kubernetes-in-action/chapter-8/ch08fig04)).

![Figure 8.4. Talking to the API server from inside a pod to get information about other API objects](https://drek4537l1klr.cloudfront.net/luksa/Figures/08fig04.jpg)

Before you see how apps within pods can talk to the Kubernetes API server, let’s first explore the server’s REST endpoints from your local machine, so you can see what talking to the API server looks like.

### 8.2.1. Exploring the Kubernetes REST API

You’ve learned about different Kubernetes resource types. But if you’re planning on developing apps that talk to the Kubernetes API, you’ll want to know the API first.

To do that, you can try hitting the API server directly. You can get its URL by running `kubectl cluster-info`:

```bash
$ kubectl cluster-info
Kubernetes master is running at https://192.168.99.100:8443
```

Because the server uses HTTPS and requires authentication, it’s not simple to talk to it directly. You can try accessing it with `curl` and using `curl`’s `--insecure` (or `-k`) option to skip the server certificate check, but that doesn’t get you far:

```bash
$ curl https://192.168.99.100:8443 -k
Unauthorized
```

Luckily, rather than dealing with authentication yourself, you can talk to the server through a proxy by running the `kubectl proxy` command.

##### Accessing the API server through kubectl proxy

The `kubectl proxy` command runs a proxy server that accepts HTTP connections on your local machine and proxies them to the API server while taking care of authentication, so you don’t need to pass the authentication token in every request. It also makes sure you’re talking to the actual API server and not a man in the middle (by verifying the server’s certificate on each request).

Running the proxy is trivial. All you need to do is run the following command:

```bash
$ kubectl proxy
Starting to serve on 127.0.0.1:8001
```

You don’t need to pass in any other arguments, because `kubectl` already knows everything it needs (the API server URL, authorization token, and so on). As soon as it starts up, the proxy starts accepting connections on local port 8001. Let’s see if it works:

```bash
$ curl localhost:8001
{
  "paths": [
    "/api",
    "/api/v1",
    ...
```

Voila! You sent the request to the proxy, it sent a request to the API server, and then the proxy returned whatever the server returned. Now, let’s start exploring.

##### Exploring the Kubernetes API through the kubectl proxy

You can continue to use `curl`, or you can open your web browser and point it to http://localhost:8001. Let’s examine what the API server returns when you hit its base URL more closely. The server responds with a list of paths, as shown in the following listing.

##### Listing 8.7. Listing the API server’s REST endpoints: http://localhost:8001

```bash
$ curl http://localhost:8001
{
  "paths": [
    "/api",
    "/api/v1",                  #1
    "/apis",
    "/apis/apps",
    "/apis/apps/v1beta1",
    ...
    "/apis/batch",              #2
    "/apis/batch/v1",           #2
    "/apis/batch/v2alpha1",     #2
    ...
```

These paths correspond to the API groups and versions you specify in your resource definitions when creating resources such as Pods, Services, and so on.

You may recognize the `batch/v1` in the `/apis/batch/v1` path as the API group and version of the Job resources you learned about in [chapter 4](/book/kubernetes-in-action/chapter-4/ch04). Likewise, the `/api/v1` corresponds to the `apiVersion: v1` you refer to in the common resources you created (Pods, Services, ReplicationControllers, and so on). The most common resource types, which were introduced in the earliest versions of Kubernetes, don’t belong to any specific group, because Kubernetes initially didn’t even use the concept of API groups; they were introduced later.

---

##### Note

These initial resource types without an API group are now considered to belong to the core API group.

---

##### Exploring the batch API group’s REST endpoint

Let’s explore the Job resource API. You’ll start by looking at what’s behind the `/apis/batch` path (you’ll omit the version for now), as shown in the following listing.

##### Listing 8.8. Listing endpoints under `/apis/batch`: http://localhost:8001/apis/batch

```bash
$ curl http://localhost:8001/apis/batch
{
  "kind": "APIGroup",
  "apiVersion": "v1",
  "name": "batch",
  "versions": [
    {
      "groupVersion": "batch/v1",             #1
      "version": "v1"                         #1
    },
    {
      "groupVersion": "batch/v2alpha1",       #1
      "version": "v2alpha1"                   #1
    }
  ],
  "preferredVersion": {                       #2
    "groupVersion": "batch/v1",               #2
    "version": "v1"                           #2
  },
  "serverAddressByClientCIDRs": null
}
```

The response shows a description of the `batch` API group, including the available versions and the preferred version clients should use. Let’s continue and see what’s behind the `/apis/batch/v1` path. It’s shown in the following listing.

##### Listing 8.9. Resource types in `batch/v1`: http://localhost:8001/apis/batch/v1

```bash
$ curl http://localhost:8001/apis/batch/v1
{
  "kind": "APIResourceList",              #1
  "apiVersion": "v1",
  "groupVersion": "batch/v1",             #1
  "resources": [                          #2
    {
      "name": "jobs",                     #3
      "namespaced": true,                 #3
      "kind": "Job",                      #3
      "verbs": [                          #4
        "create",                         #4
        "delete",                         #4
        "deletecollection",               #4
        "get",                            #4
        "list",                           #4
        "patch",                          #4
        "update",                         #4
        "watch"                           #4
      ]
    },
    {
      "name": "jobs/status",              #5

      "namespaced": true,
      "kind": "Job",
      "verbs": [                          #6
        "get",                            #6
        "patch",                          #6
        "update"                          #6
      ]
    }
  ]
}
```

As you can see, the API server returns a list of resource types and REST endpoints in the `batch/v1` API group. One of those is the Job resource. In addition to the `name` of the resource and the associated `kind`, the API server also includes information on whether the resource is `namespaced` or not, its short name (if it has one; Jobs don’t), and a list of `verbs` you can use with the resource.

The returned list describes the REST resources exposed in the API server. The `"name": "jobs"` line tells you that the API contains the `/apis/batch/v1/jobs` endpoint. The `"verbs"` array says you can retrieve, update, and delete Job resources through that endpoint. For certain resources, additional API endpoints are also exposed (such as the `jobs/status` path, which allows modifying only the status of a Job).

##### Listing all Job instances in the cluster

To get a list of Jobs in your cluster, perform a GET request on path `/apis/batch/ v1/jobs`, as shown in the following listing.

##### Listing 8.10. List of Jobs: http://localhost:8001/apis/batch/v1/jobs

```bash
$ curl http://localhost:8001/apis/batch/v1/jobs
{
  "kind": "JobList",
  "apiVersion": "batch/v1",
  "metadata": {
    "selfLink": "/apis/batch/v1/jobs",
    "resourceVersion": "225162"
  },
  "items": [
    {
      "metadata": {
        "name": "my-job",
        "namespace": "default",
        ...
```

You probably have no Job resources deployed in your cluster, so the items array will be empty. You can try deploying the Job in Chapter08/my-job.yaml and hitting the REST endpoint again to get the same output as in [listing 8.10](/book/kubernetes-in-action/chapter-8/ch08ex10).

##### Retrieving a specific Job instance by name

The previous endpoint returned a list of all Jobs across all namespaces. To get back only one specific Job, you need to specify its name and namespace in the URL. To retrieve the Job shown in the previous listing (`name: my-job`; `namespace: default`), you need to request the following path: `/apis/batch/v1/namespaces/default/jobs/ my-job`, as shown in the following listing.

##### Listing 8.11. Retrieving a resource in a specific namespace by name

```bash
$ curl http://localhost:8001/apis/batch/v1/namespaces/default/jobs/my-job
{
  "kind": "Job",
  "apiVersion": "batch/v1",
  "metadata": {
    "name": "my-job",
    "namespace": "default",
    ...
```

As you can see, you get back the complete JSON definition of the `my-job` Job resource, exactly like you do if you run:

```bash
$ kubectl get job my-job -o json
```

You’ve seen that you can browse the Kubernetes REST API server without using any special tools, but to fully explore the REST API and interact with it, a better option is described at the end of this chapter. For now, exploring it with `curl` like this is enough to make you understand how an application running in a pod talks to Kubernetes.

### 8.2.2. Talking to the API server from within a pod

You’ve learned how to talk to the API server from your local machine, using the `kubectl proxy`. Now, let’s see how to talk to it from within a pod, where you (usually) don’t have `kubectl`. Therefore, to talk to the API server from inside a pod, you need to take care of three things:

- Find the location of the API server.
- Make sure you’re talking to the API server and not something impersonating it.
- Authenticate with the server; otherwise it won’t let you see or do anything.

You’ll see how this is done in the next three sections.

##### Running a pod to try out communication with the API server

The first thing you need is a pod from which to talk to the API server. You’ll run a pod that does nothing (it runs the `sleep` command in its only container), and then run a shell in the container with `kubectl exec`. Then you’ll try to access the API server from within that shell using `curl`.

Therefore, you need to use a container image that contains the `curl` binary. If you search for such an image on, say, Docker Hub, you’ll find the `tutum/curl` image, so use it (you can also use any other existing image containing the `curl` binary or you can build your own). The pod definition is shown in the following listing.

##### Listing 8.12. A pod for trying out communication with the API server: curl.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: curl
spec:
  containers:
  - name: main
    image: tutum/curl
    command: ["sleep", "9999999"]
```

After creating the pod, run `kubectl exec` to run a bash shell inside its container:

```bash
$ kubectl exec -it curl bash
root@curl:/#
```

You’re now ready to talk to the API server.

##### Finding the API server’s address

First, you need to find the IP and port of the Kubernetes API server. This is easy, because a Service called `kubernetes` is automatically exposed in the default namespace and configured to point to the API server. You may remember seeing it every time you listed services with `kubectl get svc`:

```bash
$ kubectl get svc
NAME         CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes   10.0.0.1     <none>        443/TCP   46d
```

And you’ll remember from [chapter 5](/book/kubernetes-in-action/chapter-5/ch05) that environment variables are configured for each service. You can get both the IP address and the port of the API server by looking up the `KUBERNETES_SERVICE_HOST` and `KUBERNETES_SERVICE_PORT` variables (inside the container):

```
root@curl:/# env | grep KUBERNETES_SERVICE
KUBERNETES_SERVICE_PORT=443
KUBERNETES_SERVICE_HOST=10.0.0.1
KUBERNETES_SERVICE_PORT_HTTPS=443
```

You may also remember that each service also gets a DNS entry, so you don’t even need to look up the environment variables, but instead simply point `curl` to https://kubernetes. To be fair, if you don’t know which port the service is available at, you also either need to look up the environment variables or perform a DNS SRV record lookup to get the service’s actual port number.

The environment variables shown previously say that the API server is listening on port 443, which is the default port for HTTPS, so try hitting the server through HTTPS:

```
root@curl:/# curl https://kubernetes
curl: (60) SSL certificate problem: unable to get local issuer certificate
...
If you'd like to turn off curl's verification of the certificate, use
  the -k (or --insecure) option.
```

Although the simplest way to get around this is to use the proposed `-k` option (and this is what you’d normally use when playing with the API server manually), let’s look at the longer (and correct) route. Instead of blindly trusting that the server you’re connecting to is the authentic API server, you’ll verify its identity by having `curl` check its certificate.

---

##### Tip

Never skip checking the server’s certificate in an actual application. Doing so could make your app expose its authentication token to an attacker using a man-in-the-middle attack.

---

##### Verifying the server’s identity

In the previous chapter, while discussing Secrets, we looked at an automatically created Secret called `default-token-xyz`, which is mounted into each container at /var/run/secrets/kubernetes.io/serviceaccount/. Let’s see the contents of that Secret again, by listing files in that directory:

```
root@curl:/# ls /var/run/secrets/kubernetes.io/serviceaccount/
ca.crt    namespace    token
```

The Secret has three entries (and therefore three files in the Secret volume). Right now, we’ll focus on the ca.crt file, which holds the certificate of the certificate authority (CA) used to sign the Kubernetes API server’s certificate. To verify you’re talking to the API server, you need to check if the server’s certificate is signed by the CA. `curl` allows you to specify the CA certificate with the `--cacert` option, so try hitting the API server again:

```
root@curl:/# curl --cacert /var/run/secrets/kubernetes.io/serviceaccount
             ➥  /ca.crt https://kubernetes
Unauthorized
```

---

##### Note

You may see a longer error description than “Unauthorized.”

---

Okay, you’ve made progress. `curl` verified the server’s identity because its certificate was signed by the CA you trust. As the `Unauthorized` response suggests, you still need to take care of authentication. You’ll do that in a moment, but first let’s see how to make life easier by setting the `CURL_CA_BUNDLE` environment variable, so you don’t need to specify `--cacert` every time you run `curl`:

```
root@curl:/# export CURL_CA_BUNDLE=/var/run/secrets/kubernetes.io/
             ➥  serviceaccount/ca.crt
```

You can now hit the API server without using `--cacert`:

```
root@curl:/# curl https://kubernetes
Unauthorized
```

This is much nicer now. Your client (`curl`) trusts the API server now, but the API server itself says you’re not authorized to access it, because it doesn’t know who you are.

##### Authenticating with the API server

You need to authenticate with the server, so it allows you to read and even update and/or delete the API objects deployed in the cluster. To authenticate, you need an authentication token. Luckily, the token is provided through the default-token Secret mentioned previously, and is stored in the `token` file in the `secret` volume. As the Secret’s name suggests, that’s the primary purpose of the Secret.

You’re going to use the token to access the API server. First, load the token into an environment variable:

```
root@curl:/# TOKEN=$(cat /var/run/secrets/kubernetes.io/
             ➥  serviceaccount/token)
```

The token is now stored in the `TOKEN` environment variable. You can use it when sending requests to the API server, as shown in the following listing.

##### Listing 8.13. Getting a proper response from the API server

```
root@curl:/# curl -H "Authorization: Bearer $TOKEN" https://kubernetes
{
  "paths": [
    "/api",
    "/api/v1",
    "/apis",
    "/apis/apps",
    "/apis/apps/v1beta1",
    "/apis/authorization.k8s.io",
    ...
    "/ui/",
    "/version"
  ]
}
```

---

##### **Disabling role-based access control (RBAC)**

If you’re using a Kubernetes cluster with RBAC enabled, the service account may not be authorized to access (parts of) the API server. You’ll learn about service accounts and RBAC in [chapter 12](/book/kubernetes-in-action/chapter-12/ch12). For now, the simplest way to allow you to query the API server is to work around RBAC by running the following command:

```bash
$ kubectl create clusterrolebinding permissive-binding \
  --clusterrole=cluster-admin \
  --group=system:serviceaccounts
```

This gives all service accounts (we could also say all pods) cluster-admin privileges, allowing them to do whatever they want. Obviously, doing this is dangerous and should never be done on production clusters. For test purposes, it’s fine.

---

As you can see, you passed the token inside the `Authorization` HTTP header in the request. The API server recognized the token as authentic and returned a proper response. You can now explore all the resources in your cluster, the way you did a few sections ago.

For example, you could list all the pods in the same namespace. But first you need to know what namespace the `curl` pod is running in.

##### Getting the namespace the pod is running in

In the first part of this chapter, you saw how to pass the namespace to the pod through the Downward API. But if you’re paying attention, you probably noticed your `secret` volume also contains a file called namespace. It contains the namespace the pod is running in, so you can read the file instead of having to explicitly pass the namespace to your pod through an environment variable. Load the contents of the file into the NS environment variable and then list all the pods, as shown in the following listing.

##### Listing 8.14. Listing pods in the pod’s own namespace

```
root@curl:/# NS=$(cat /var/run/secrets/kubernetes.io/
             ➥  serviceaccount/namespace)
root@curl:/# curl -H "Authorization: Bearer $TOKEN"
             ➥  https://kubernetes/api/v1/namespaces/$NS/pods
{
  "kind": "PodList",
  "apiVersion": "v1",
  ...
```

And there you go. By using the three files in the mounted `secret` volume directory, you listed all the pods running in the same namespace as your pod. In the same manner, you could also retrieve other API objects and even update them by sending `PUT` or `PATCH` instead of simple `GET` requests.

##### Recapping how pods talk to Kubernetes

Let’s recap how an app running inside a pod can access the Kubernetes API properly:

- The app should verify whether the API server’s certificate is signed by the certificate authority, whose certificate is in the ca.crt file.
- The app should authenticate itself by sending the `Authorization` header with the bearer token from the `token` file.
- The `namespace` file should be used to pass the namespace to the API server when performing CRUD operations on API objects inside the pod’s namespace.

---

##### Definition

CRUD stands for Create, Read, Update, and Delete. The corresponding HTTP methods are `POST`, `GET`, `PATCH`/`PUT,` and `DELETE`, respectively.

---

All three aspects of pod to API server communication are displayed in [figure 8.5](/book/kubernetes-in-action/chapter-8/ch08fig05).

![Figure 8.5. Using the files from the default-token Secret to talk to the API server](https://drek4537l1klr.cloudfront.net/luksa/Figures/08fig05_alt.jpg)

### 8.2.3. Simplifying API server communication with ambassador containers

Dealing with HTTPS, certificates, and authentication tokens sometimes seems too complicated to developers. I’ve seen developers disable validation of server certificates on way too many occasions (and I’ll admit to doing it myself a few times). Luckily, you can make the communication much simpler while keeping it secure.

Remember the `kubectl proxy` command we mentioned in [section 8.2.1](/book/kubernetes-in-action/chapter-8/ch08lev2sec4)? You ran the command on your local machine to make it easier to access the API server. Instead of sending requests to the API server directly, you sent them to the proxy and let it take care of authentication, encryption, and server verification. The same method can be used inside your pods, as well.

##### Introducing the ambassador container pattern

Imagine having an application that (among other things) needs to query the API server. Instead of it talking to the API server directly, as you did in the previous section, you can run `kubectl proxy` in an ambassador container alongside the main container and communicate with the API server through it.

Instead of talking to the API server directly, the app in the main container can connect to the ambassador through HTTP (instead of HTTPS) and let the ambassador proxy handle the HTTPS connection to the API server, taking care of security transparently (see [figure 8.6](/book/kubernetes-in-action/chapter-8/ch08fig06)). It does this by using the files from the default token’s `secret` volume.

![Figure 8.6. Using an ambassador to connect to the API server](https://drek4537l1klr.cloudfront.net/luksa/Figures/08fig06_alt.jpg)

Because all containers in a pod share the same loopback network interface, your app can access the proxy through a port on localhost.

##### Running the curl pod with an additional ambassador container

To see the ambassador container pattern in action, you’ll create a new pod like the `curl` pod you created earlier, but this time, instead of running a single container in the pod, you’ll run an additional ambassador container based on a general-purpose `kubectl-proxy` container image I’ve created and pushed to Docker Hub. You’ll find the Dockerfile for the image in the code archive (in /Chapter08/kubectl-proxy/) if you want to build it yourself.

The pod’s manifest is shown in the following listing.

##### Listing 8.15. A pod with an ambassador container: curl-with-ambassador.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: curl-with-ambassador
spec:
  containers:
  - name: main
    image: tutum/curl
    command: ["sleep", "9999999"]
  - name: ambassador
    image: luksa/kubectl-proxy:1.6.2
```

The pod spec is almost the same as before, but with a different pod name and an additional container. Run the pod and then enter the main container with

```bash
$ kubectl exec -it curl-with-ambassador -c main bash
root@curl-with-ambassador:/#
```

Your pod now has two containers, and you want to run `bash` in the `main` container, hence the `-c main` option. You don’t need to specify the container explicitly if you want to run the command in the pod’s first container. But if you want to run a command inside any other container, you do need to specify the container’s name using the `-c` option.

##### Talking to the API server through the ambassador

Next you’ll try connecting to the API server through the ambassador container. By default, `kubectl proxy` binds to port 8001, and because both containers in the pod share the same network interfaces, including loopback, you can point `curl` to `localhost:8001`, as shown in the following listing.

##### Listing 8.16. Accessing the API server through the ambassador container

```
root@curl-with-ambassador:/# curl localhost:8001
{
  "paths": [
    "/api",
    ...
  ]
}
```

Success! The output printed by `curl` is the same response you saw earlier, but this time you didn’t need to deal with authentication tokens and server certificates.

To get a clear picture of what exactly happened, refer to [figure 8.7](/book/kubernetes-in-action/chapter-8/ch08fig07). `curl` sent the plain HTTP request (without any authentication headers) to the proxy running inside the ambassador container, and then the proxy sent an HTTPS request to the API server, handling the client authentication by sending the token and checking the server’s identity by validating its certificate.

![Figure 8.7. Offloading encryption, authentication, and server verification to kubectl proxy in an ambassador container](https://drek4537l1klr.cloudfront.net/luksa/Figures/08fig07_alt.jpg)

This is a great example of how an ambassador container can be used to hide the complexities of connecting to an external service and simplify the app running in the main container. The ambassador container is reusable across many different apps, regardless of what language the main app is written in. The downside is that an additional process is running and consuming additional resources.

### 8.2.4. Using client libraries to talk to the API server

If your app only needs to perform a few simple operations on the API server, you can often use a regular HTTP client library and perform simple HTTP requests, especially if you take advantage of the `kubectl-proxy` ambassador container the way you did in the previous example. But if you plan on doing more than simple API requests, it’s better to use one of the existing Kubernetes API client libraries.

##### Using existing client libraries

Currently, two Kubernetes API client libraries exist that are supported by the API Machinery special interest group (SIG):

- *Golang client*—[https://github.com/kubernetes/client-go](https://github.com/kubernetes/client-go)
- *Python*—[https://github.com/kubernetes-incubator/client-python](https://github.com/kubernetes-incubator/client-python)

---

##### Note

The Kubernetes community has a number of Special Interest Groups (SIGs) and Working Groups that focus on specific parts of the Kubernetes ecosystem. You’ll find a list of them at [https://github.com/kubernetes/community/blob/master/sig-list.md](https://github.com/kubernetes/community/blob/master/sig-list.md).

---

In addition to the two officially supported libraries, here’s a list of user-contributed client libraries for many other languages:

- *Java client by Fabric8*—[https://github.com/fabric8io/kubernetes-client](https://github.com/fabric8io/kubernetes-client)
- *Java client by Amdatu*—[https://bitbucket.org/amdatulabs/amdatu-kubernetes](https://bitbucket.org/amdatulabs/amdatu-kubernetes)
- *Node.js client by tenxcloud*—[https://github.com/tenxcloud/node-kubernetes-client](https://github.com/tenxcloud/node-kubernetes-client)
- *Node.js client by GoDaddy*—[https://github.com/godaddy/kubernetes-client](https://github.com/godaddy/kubernetes-client)
- *PHP*—[https://github.com/devstub/kubernetes-api-php-client](https://github.com/devstub/kubernetes-api-php-client)
- *Another PHP client*—[https://github.com/maclof/kubernetes-client](https://github.com/maclof/kubernetes-client)
- *Ruby*—[https://github.com/Ch00k/kubr](https://github.com/Ch00k/kubr)
- *Another Ruby client*—[https://github.com/abonas/kubeclient](https://github.com/abonas/kubeclient)
- *Clojure*—[https://github.com/yanatan16/clj-kubernetes-api](https://github.com/yanatan16/clj-kubernetes-api)
- *Scala*—[https://github.com/doriordan/skuber](https://github.com/doriordan/skuber)
- *Perl*—[https://metacpan.org/pod/Net::Kubernetes](https://metacpan.org/pod/Net::Kubernetes)

These libraries usually support HTTPS and take care of authentication, so you won’t need to use the ambassador container.

##### An example of interacting with Kubernetes with the Fabric8 Java client

To give you a sense of how client libraries enable you to talk to the API server, the following listing shows an example of how to list services in a Java app using the Fabric8 Kubernetes client.

##### Listing 8.17. Listing, creating, updating, and deleting pods with the Fabric8 Java client

```
import java.util.Arrays;
import io.fabric8.kubernetes.api.model.Pod;
import io.fabric8.kubernetes.api.model.PodList;
import io.fabric8.kubernetes.client.DefaultKubernetesClient;
import io.fabric8.kubernetes.client.KubernetesClient;

public class Test {
  public static void main(String[] args) throws Exception {
    KubernetesClient client = new DefaultKubernetesClient();

    // list pods in the default namespace
    PodList pods = client.pods().inNamespace("default").list();
    pods.getItems().stream()
      .forEach(s -> System.out.println("Found pod: " +
               s.getMetadata().getName()));

    // create a pod
    System.out.println("Creating a pod");
    Pod pod = client.pods().inNamespace("default")
      .createNew()
      .withNewMetadata()
        .withName("programmatically-created-pod")
      .endMetadata()
      .withNewSpec()
        .addNewContainer()
          .withName("main")
          .withImage("busybox")
          .withCommand(Arrays.asList("sleep", "99999"))
        .endContainer()
      .endSpec()
      .done();
    System.out.println("Created pod: " + pod);

    // edit the pod (add a label to it)
    client.pods().inNamespace("default")
      .withName("programmatically-created-pod")
      .edit()
      .editMetadata()
        .addToLabels("foo", "bar")
      .endMetadata()
      .done();
    System.out.println("Added label foo=bar to pod");

    System.out.println("Waiting 1 minute before deleting pod...");
    Thread.sleep(60000);

    // delete the pod
    client.pods().inNamespace("default")
      .withName("programmatically-created-pod")
      .delete();
    System.out.println("Deleted the pod");
  }
}
```

The code should be self-explanatory, especially because the Fabric8 client exposes a nice, fluent Domain-Specific-Language (DSL) API, which is easy to read and understand.

##### Building your own library with Swagger and OpenAPI

If no client is available for your programming language of choice, you can use the Swagger API framework to generate the client library and documentation. The Kubernetes API server exposes Swagger API definitions at /swaggerapi and OpenAPI spec at /swagger.json.

To find out more about the Swagger framework, visit the website at [http://swagger.io](http://swagger.io).

##### Exploring the API with Swagger UI

Earlier in the chapter I said I’d point you to a better way of exploring the REST API instead of hitting the REST endpoints with `curl`. Swagger, which I mentioned in the previous section, is not just a tool for specifying an API, but also provides a web UI for exploring REST APIs if they expose the Swagger API definitions. The better way of exploring REST APIs is through this UI.

Kubernetes not only exposes the Swagger API, but it also has Swagger UI integrated into the API server, though it’s not enabled by default. You can enable it by running the API server with the `--enable-swagger-ui=true` option.

---

##### Tip

If you’re using Minikube, you can enable Swagger UI when starting the cluster: `minikube start --extra-config=apiserver.Features.Enable-SwaggerUI=true`

---

After you enable the UI, you can open it in your browser by pointing it to:

```
http(s)://<api server>:<port>/swagger-ui
```

I urge you to give Swagger UI a try. It not only allows you to browse the Kubernetes API, but also interact with it (you can `POST` JSON resource manifests, `PATCH` resources, or `DELETE` them, for example).

## 8.3. Summary

After reading this chapter, you now know how your app, running inside a pod, can get data about itself, other pods, and other components deployed in the cluster. You’ve learned

- How a pod’s name, namespace, and other metadata can be exposed to the process either through environment variables or files in a `downwardAPI` volume
- How CPU and memory requests and limits are passed to your app in any unit the app requires
- How a pod can use `downwardAPI` volumes to get up-to-date metadata, which may change during the lifetime of the pod (such as labels and annotations)
- How you can browse the Kubernetes REST API through `kubectl proxy`
- How pods can find the API server’s location through environment variables or DNS, similar to any other Service defined in Kubernetes
- How an application running in a pod can verify that it’s talking to the API server and how it can authenticate itself
- How using an ambassador container can make talking to the API server from within an app much simpler
- How client libraries can get you interacting with Kubernetes in minutes

In this chapter, you learned how to talk to the API server, so the next step is learning more about how it works. You’ll do that in [chapter 11](/book/kubernetes-in-action/chapter-11/ch11), but before we dive into such details, you still need to learn about two other Kubernetes resources—Deployments and StatefulSets. They’re explained in the next two chapters.
