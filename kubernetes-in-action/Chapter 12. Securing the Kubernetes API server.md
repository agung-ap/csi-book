# Chapter 12. Securing the Kubernetes API server

### **This chapter covers**

- Understanding authentication
- What ServiceAccounts are and why they’re used
- Understanding the role-based access control (RBAC) plugin
- Using Roles and RoleBindings
- Using ClusterRoles and ClusterRoleBindings
- Understanding the default roles and bindings

In [chapter 8](/book/kubernetes-in-action/chapter-8/ch08) you learned how applications running in pods can talk to the API server to retrieve or change the state of resources deployed in the cluster. To authenticate with the API server, you used the ServiceAccount token mounted into the pod. In this chapter, you’ll learn what ServiceAccounts are and how to configure their permissions, as well as permissions for other subjects using the cluster.

## 12.1. Understanding authentication

In the previous chapter, we said the API server can be configured with one or more authentication plugins (and the same is true for authorization plugins). When a request is received by the API server, it goes through the list of authentication plugins, so they can each examine the request and try to determine who’s sending the request. The first plugin that can extract that information from the request returns the username, user ID, and the groups the client belongs to back to the API server core. The API server stops invoking the remaining authentication plugins and continues onto the authorization phase.

Several authentication plugins are available. They obtain the identity of the client using the following methods:

- From the client certificate
- From an authentication token passed in an HTTP header
- Basic HTTP authentication
- Others

The authentication plugins are enabled through command-line options when starting the API server.

### 12.1.1. Users and groups

An authentication plugin returns the username and group(s) of the authenticated user. Kubernetes doesn’t store that information anywhere; it uses it to verify whether the user is authorized to perform an action or not.

##### Understanding users

Kubernetes distinguishes between two kinds of clients connecting to the API server:

- Actual humans (users)
- Pods (more specifically, applications running inside them)

Both these types of clients are authenticated using the aforementioned authentication plugins. Users are meant to be managed by an external system, such as a Single Sign On (SSO) system, but the pods use a mechanism called *service accounts*, which are created and stored in the cluster as ServiceAccount resources. In contrast, no resource represents user accounts, which means you can’t create, update, or delete users through the API server.

We won’t go into any details of how to manage users, but we will explore Service-Accounts in detail, because they’re essential for running pods. For more information on how to configure the cluster for authentication of human users, cluster administrators should refer to the Kubernetes Cluster Administrator guide at [http://kubernetes.io/docs/admin](http://kubernetes.io/docs/admin).

##### Understanding groups

Both human users and ServiceAccounts can belong to one or more groups. We’ve said that the authentication plugin returns groups along with the username and user ID. Groups are used to grant permissions to several users at once, instead of having to grant them to individual users.

Groups returned by the plugin are nothing but strings, representing arbitrary group names, but built-in groups have special meaning:

- The `system:unauthenticated` group is used for requests where none of the authentication plugins could authenticate the client.
- The `system:authenticated` group is automatically assigned to a user who was authenticated successfully.
- The `system:serviceaccounts` group encompasses all ServiceAccounts in the system.
- The `system:serviceaccounts:<namespace>` includes all ServiceAccounts in a specific namespace.

### 12.1.2. Introducing ServiceAccounts

Let’s explore ServiceAccounts up close. You’ve already learned that the API server requires clients to authenticate themselves before they’re allowed to perform operations on the server. And you’ve already seen how pods can authenticate by sending the contents of the file`/var/run/secrets/kubernetes.io/serviceaccount/token`, which is mounted into each container’s filesystem through a `secret` volume.

But what exactly does that file represent? Every pod is associated with a Service-Account, which represents the identity of the app running in the pod. The token file holds the ServiceAccount’s authentication token. When an app uses this token to connect to the API server, the authentication plugin authenticates the ServiceAccount and passes the ServiceAccount’s username back to the API server core. Service-Account usernames are formatted like this:

```
system:serviceaccount:<namespace>:<service account name>
```

The API server passes this username to the configured authorization plugins, which determine whether the action the app is trying to perform is allowed to be performed by the ServiceAccount.

ServiceAccounts are nothing more than a way for an application running inside a pod to authenticate itself with the API server. As already mentioned, applications do that by passing the ServiceAccount’s token in the request.

##### Understanding the ServiceAccount resource

ServiceAccounts are resources just like Pods, Secrets, ConfigMaps, and so on, and are scoped to individual namespaces. A default ServiceAccount is automatically created for each namespace (that’s the one your pods have used all along).

You can list ServiceAccounts like you do other resources:

```bash
$ kubectl get sa
NAME      SECRETS   AGE
default   1         1d
```

---

##### Note

The shorthand for `serviceaccount` is `sa`.

---

As you can see, the current namespace only contains the `default` ServiceAccount. Additional ServiceAccounts can be added when required. Each pod is associated with exactly one ServiceAccount, but multiple pods can use the same ServiceAccount. As you can see in [figure 12.1](/book/kubernetes-in-action/chapter-12/ch12fig01), a pod can only use a ServiceAccount from the same namespace.

![Figure 12.1. Each pod is associated with a single ServiceAccount in the pod’s namespace.](https://drek4537l1klr.cloudfront.net/luksa/Figures/12fig01_alt.jpg)

##### Understanding how ServiceAccounts tie into authorization

You can assign a ServiceAccount to a pod by specifying the account’s name in the pod manifest. If you don’t assign it explicitly, the pod will use the default ServiceAccount in the namespace.

By assigning different ServiceAccounts to pods, you can control which resources each pod has access to. When a request bearing the authentication token is received by the API server, the server uses the token to authenticate the client sending the request and then determines whether or not the related ServiceAccount is allowed to perform the requested operation. The API server obtains this information from the system-wide authorization plugin configured by the cluster administrator. One of the available authorization plugins is the role-based access control (RBAC) plugin, which is discussed later in this chapter. From Kubernetes version 1.6 on, the RBAC plugin is the plugin most clusters should use.

### 12.1.3. Creating ServiceAccounts

We’ve said every namespace contains its own default ServiceAccount, but additional ones can be created if necessary. But why should you bother with creating Service-Accounts instead of using the default one for all your pods?

The obvious reason is cluster security. Pods that don’t need to read any cluster metadata should run under a constrained account that doesn’t allow them to retrieve or modify any resources deployed in the cluster. Pods that need to retrieve resource metadata should run under a ServiceAccount that only allows reading those objects’ metadata, whereas pods that need to modify those objects should run under their own ServiceAccount allowing modifications of API objects.

Let’s see how you can create additional ServiceAccounts, how they relate to Secrets, and how you can assign them to your pods.

##### Creating a ServiceAccount

Creating a ServiceAccount is incredibly easy, thanks to the dedicated `kubectl create serviceaccount` command. Let’s create a new ServiceAccount called `foo`:

```bash
$ kubectl create serviceaccount foo
serviceaccount "foo" created
```

Now, you can inspect the ServiceAccount with the `describe` command, as shown in the following listing.

##### Listing 12.1. Inspecting a ServiceAccount with `kubectl describe`

```bash
$ kubectl describe sa foo
Name:               foo
Namespace:          default
Labels:             <none>

Image pull secrets: <none>             #1

Mountable secrets:  foo-token-qzq7j    #2

Tokens:             foo-token-qzq7j    #3
```

You can see that a custom token Secret has been created and associated with the ServiceAccount. If you look at the Secret’s data with `kubectl describe secret foo-token-qzq7j`, you’ll see it contains the same items (the CA certificate, namespace, and token) as the default ServiceAccount’s token does (the token itself will obviously be different), as shown in the following listing.

##### Listing 12.2. Inspecting the custom ServiceAccount’s Secret

```bash
$ kubectl describe secret foo-token-qzq7j
...
ca.crt:         1066 bytes
namespace:      7 bytes
token:          eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

##### Note

You’ve probably heard of JSON Web Tokens (JWT). The authentication tokens used in ServiceAccounts are JWT tokens.

---

##### Understanding a ServiceAccount’s mountable secrets

The token is shown in the `Mountable secrets` list when you inspect a ServiceAccount with `kubectl describe`. Let me explain what that list represents. In [chapter 7](/book/kubernetes-in-action/chapter-7/ch07) you learned how to create Secrets and mount them inside a pod. By default, a pod can mount any Secret it wants. But the pod’s ServiceAccount can be configured to only allow the pod to mount Secrets that are listed as mountable Secrets on the Service-Account. To enable this feature, the ServiceAccount must contain the following annotation: `kubernetes.io/enforce-mountable-secrets="true"`.

If the ServiceAccount is annotated with this annotation, any pods using it can mount only the ServiceAccount’s mountable Secrets—they can’t use any other Secret.

##### Understanding a ServiceAccount’s image pull Secrets

A ServiceAccount can also contain a list of image pull Secrets, which we examined in [chapter 7](/book/kubernetes-in-action/chapter-7/ch07). In case you don’t remember, they are Secrets that hold the credentials for pulling container images from a private image repository.

The following listing shows an example of a ServiceAccount definition, which includes the image pull Secret you created in [chapter 7](/book/kubernetes-in-action/chapter-7/ch07).

##### Listing 12.3. ServiceAccount with an image pull Secret: sa-image-pull-secrets.yaml

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-service-account
imagePullSecrets:
- name: my-dockerhub-secret
```

A ServiceAccount’s image pull Secrets behave slightly differently than its mountable Secrets. Unlike mountable Secrets, they don’t determine which image pull Secrets a pod can use, but which ones are added automatically to all pods using the Service-Account. Adding image pull Secrets to a ServiceAccount saves you from having to add them to each pod individually.

### 12.1.4. Assigning a ServiceAccount to a pod

After you create additional ServiceAccounts, you need to assign them to pods. This is done by setting the name of the ServiceAccount in the `spec.serviceAccountName` field in the pod definition.

---

##### Note

A pod’s ServiceAccount must be set when creating the pod. It can’t be changed later.

---

##### Creating a pod which uses a custom ServiceAccount

In [chapter 8](/book/kubernetes-in-action/chapter-8/ch08) you deployed a pod that ran a container based on the `tutum/curl` image and an ambassador container alongside it. You used it to explore the API server’s REST interface. The ambassador container ran the `kubectl proxy` process, which used the pod’s ServiceAccount’s token to authenticate with the API server.

You can now modify the pod so it uses the `foo` ServiceAccount you created minutes ago. The next listing shows the pod definition.

##### Listing 12.4. Pod using a non-default ServiceAccount: curl-custom-sa.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: curl-custom-sa
spec:
  serviceAccountName: foo
  containers:
  - name: main
    image: tutum/curl
    command: ["sleep", "9999999"]
  - name: ambassador
    image: luksa/kubectl-proxy:1.6.2
```

To confirm that the custom ServiceAccount’s token is mounted into the two containers, you can print the contents of the token as shown in the following listing.

##### Listing 12.5. Inspecting the token mounted into the pod’s container(s)

```bash
$ kubectl exec -it curl-custom-sa -c main
➥  cat /var/run/secrets/kubernetes.io/serviceaccount/token
eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
```

You can see the token is the one from the `foo` ServiceAccount by comparing the token string in [listing 12.5](/book/kubernetes-in-action/chapter-12/ch12ex05) with the one in [listing 12.2](/book/kubernetes-in-action/chapter-12/ch12ex02).

##### Using the custom ServiceAccount’s token to talk to the API server

Let’s see if you can talk to the API server using this token. As mentioned previously, the ambassador container uses the token when talking to the server, so you can test the token by going through the ambassador, which listens on `localhost:8001`, as shown in the following listing.

##### Listing 12.6. Talking to the API server with a custom ServiceAccount

```bash
$ kubectl exec -it curl-custom-sa -c main curl localhost:8001/api/v1/pods
{
  "kind": "PodList",
  "apiVersion": "v1",
  "metadata": {
    "selfLink": "/api/v1/pods",
    "resourceVersion": "433895"
  },
  "items": [
  ...
```

Okay, you got back a proper response from the server, which means the custom Service-Account is allowed to list pods. This may be because your cluster doesn’t use the RBAC authorization plugin, or you gave all ServiceAccounts full permissions, as instructed in [chapter 8](/book/kubernetes-in-action/chapter-8/ch08).

When your cluster isn’t using proper authorization, creating and using additional ServiceAccounts doesn’t make much sense, since even the default ServiceAccount is allowed to do anything. The only reason to use ServiceAccounts in that case is to enforce mountable Secrets or to provide image pull Secrets through the Service-Account, as explained earlier.

But creating additional ServiceAccounts is practically a must when you use the RBAC authorization plugin, which we’ll explore next.

## 12.2. Securing the cluster with role-based access control

Starting with Kubernetes version 1.6.0, cluster security was ramped up considerably. In earlier versions, if you managed to acquire the authentication token from one of the pods, you could use it to do anything you want in the cluster. If you google around, you’ll find demos showing how a *path traversal* (or *directory traversal*) attack (where clients can retrieve files located outside of the web server’s web root directory) can be used to get the token and use it to run your malicious pods in an insecure Kubernetes cluster.

But in version 1.8.0, the RBAC authorization plugin graduated to GA (General Availability) and is now enabled by default on many clusters (for example, when deploying a cluster with kubadm, as described in [appendix B](/book/kubernetes-in-action/appendix-b/app02)). RBAC prevents unauthorized users from viewing or modifying the cluster state. The default Service-Account isn’t allowed to view cluster state, let alone modify it in any way, unless you grant it additional privileges. To write apps that communicate with the Kubernetes API server (as described in [chapter 8](/book/kubernetes-in-action/chapter-8/ch08)), you need to understand how to manage authorization through RBAC-specific resources.

---

##### Note

In addition to RBAC, Kubernetes also includes other authorization plugins, such as the Attribute-based access control (ABAC) plugin, a Web-Hook plugin and custom plugin implementations. RBAC is the standard, though.

---

### 12.2.1. Introducing the RBAC authorization plugin

The Kubernetes API server can be configured to use an authorization plugin to check whether an action is allowed to be performed by the user requesting the action. Because the API server exposes a REST interface, users perform actions by sending HTTP requests to the server. Users authenticate themselves by including credentials in the request (an authentication token, username and password, or a client certificate).

##### Understanding actions

But what actions are there? As you know, REST clients send `GET`, `POST`, `PUT`, `DELETE`, and other types of HTTP requests to specific URL paths, which represent specific REST resources. In Kubernetes, those resources are Pods, Services, Secrets, and so on. Here are a few examples of actions in Kubernetes:

- Get Pods
- Create Services
- Update Secrets
- And so on

The verbs in those examples (get, create, update) map to HTTP methods (`GET`, `POST`, `PUT`) performed by the client (the complete mapping is shown in [table 12.1](/book/kubernetes-in-action/chapter-12/ch12table01)). The nouns (Pods, Service, Secrets) obviously map to Kubernetes resources.

An authorization plugin such as RBAC, which runs inside the API server, determines whether a client is allowed to perform the requested verb on the requested resource or not.

##### Table 12.1. Mapping HTTP methods to authorization verbs[(view table figure)](https://drek4537l1klr.cloudfront.net/luksa/HighResolutionFigures/table_12-1.png)

HTTP method

Verb for single resource

Verb for collection

GET, HEADget (and watch for watching)list (and watch)POSTcreaten/aPUTupdaten/aPATCHpatchn/aDELETEdeletedeletecollection---

##### Note

The additional verb `use` is used for PodSecurityPolicy resources, which are explained in the next chapter.

---

Besides applying security permissions to whole resource types, RBAC rules can also apply to specific instances of a resource (for example, a Service called `myservice`). And later you’ll see that permissions can also apply to non-resource URL paths, because not every path the API server exposes maps to a resource (such as the `/api` path itself or the server health information at `/healthz`).

##### Understanding the RBAC plugin

The RBAC authorization plugin, as the name suggests, uses user roles as the key factor in determining whether the user may perform the action or not. A subject (which may be a human, a ServiceAccount, or a group of users or ServiceAccounts) is associated with one or more roles and each role is allowed to perform certain verbs on certain resources.

If a user has multiple roles, they may do anything that any of their roles allows them to do. If none of the user’s roles contains a permission to, for example, update Secrets, the API server will prevent the user from performing `PUT` or `PATCH` requests on Secrets.

Managing authorization through the RBAC plugin is simple. It’s all done by creating four RBAC-specific Kubernetes resources, which we’ll look at next.

### 12.2.2. Introducing RBAC resources

The RBAC authorization rules are configured through four resources, which can be grouped into two groups:

- Roles and ClusterRoles, which specify which verbs can be performed on which resources.
- RoleBindings and ClusterRoleBindings, which bind the above roles to specific users, groups, or ServiceAccounts.

Roles define *what* can be done, while bindings define *who* can do it (this is shown in [figure 12.2](/book/kubernetes-in-action/chapter-12/ch12fig02)).

![Figure 12.2. Roles grant permissions, whereas RoleBindings bind Roles to subjects.](https://drek4537l1klr.cloudfront.net/luksa/Figures/12fig02_alt.jpg)

The distinction between a Role and a ClusterRole, or between a RoleBinding and a ClusterRoleBinding, is that the Role and RoleBinding are namespaced resources, whereas the ClusterRole and ClusterRoleBinding are cluster-level resources (not namespaced). This is depicted in [figure 12.3](/book/kubernetes-in-action/chapter-12/ch12fig03).

![Figure 12.3. Roles and RoleBindings are namespaced; ClusterRoles and ClusterRoleBindings aren’t.](https://drek4537l1klr.cloudfront.net/luksa/Figures/12fig03_alt.jpg)

As you can see from the figure, multiple RoleBindings can exist in a single name-space (this is also true for Roles). Likewise, multiple ClusterRoleBindings and Cluster-Roles can be created. Another thing shown in the figure is that although RoleBindings are namespaced, they can also reference ClusterRoles, which aren’t.

The best way to learn about these four resources and what their effects are is by trying them out in a hands-on exercise. You’ll do that now.

##### Setting up your exercise

Before you can explore how RBAC resources affect what you can do through the API server, you need to make sure RBAC is enabled in your cluster. First, ensure you’re using at least version 1.6 of Kubernetes and that the RBAC plugin is the only configured authorization plugin. There can be multiple plugins enabled in parallel and if one of them allows an action to be performed, the action is allowed.

---

##### Note

If you’re using GKE 1.6 or 1.7, you need to explicitly disable legacy authorization by creating the cluster with the `--no-enable-legacy-authorization` option. If you’re using Minikube, you also may need to enable RBAC by starting Minikube with `--extra-config=apiserver.Authorization.Mode=RBAC`

---

If you followed the instructions on how to disable RBAC in [chapter 8](/book/kubernetes-in-action/chapter-8/ch08), now’s the time to re-enable it by running the following command:

```bash
$ kubectl delete clusterrolebinding permissive-binding
```

To try out RBAC, you’ll run a pod through which you’ll try to talk to the API server, the way you did in [chapter 8](/book/kubernetes-in-action/chapter-8/ch08). But this time you’ll run two pods in different namespaces to see how per-namespace security behaves.

In the examples in [chapter 8](/book/kubernetes-in-action/chapter-8/ch08), you ran two containers to demonstrate how an application in one container uses the other container to talk to the API server. This time, you’ll run a single container (based on the `kubectl-proxy` image) and use `kubectl exec` to run `curl` inside that container directly. The proxy will take care of authentication and HTTPS, so you can focus on the authorization aspect of API server security.

##### Creating the namespaces and running the pods

You’re going to create one pod in namespace `foo` and the other one in namespace `bar`, as shown in the following listing.

##### Listing 12.7. Running test pods in different namespaces

```bash
$ kubectl create ns foo
namespace "foo" created
$ kubectl run test --image=luksa/kubectl-proxy -n foo
deployment "test" created
$ kubectl create ns bar
namespace "bar" created
$ kubectl run test --image=luksa/kubectl-proxy -n bar
deployment "test" created
```

Now open two terminals and use `kubectl exec` to run a shell inside each of the two pods (one in each terminal). For example, to run the shell in the pod in namespace `foo`, first get the name of the pod:

```bash
$ kubectl get po -n foo
NAME                   READY     STATUS    RESTARTS   AGE
test-145485760-ttq36   1/1       Running   0          1m
```

Then use the name in the `kubectl exec` command:

```bash
$ kubectl exec -it test-145485760-ttq36 -n foo sh
/ #
```

Do the same in the other terminal, but for the pod in the `bar` namespace.

##### Listing Services from your pods

To verify that RBAC is enabled and preventing the pod from reading cluster state, use `curl` to list Services in the `foo` namespace:

```
/ # curl localhost:8001/api/v1/namespaces/foo/services
User "system:serviceaccount:foo:default" cannot list services in the namespace "foo".
```

You’re connecting to `localhost:8001`, which is where the `kubectl proxy` process is listening (as explained in [chapter 8](/book/kubernetes-in-action/chapter-8/ch08)). The process received your request and sent it to the API server while authenticating as the default ServiceAccount in the `foo` namespace (as evident from the API server’s response).

The API server responded that the ServiceAccount isn’t allowed to list Services in the `foo` namespace, even though the pod is running in that same namespace. You’re seeing RBAC in action. The default permissions for a ServiceAccount don’t allow it to list or modify any resources. Now, let’s learn how to allow the ServiceAccount to do that. First, you’ll need to create a Role resource.

### 12.2.3. Using Roles and RoleBindings

A Role resource defines what actions can be taken on which resources (or, as explained earlier, which types of HTTP requests can be performed on which RESTful resources). The following listing defines a Role, which allows users to `get` and `list` Services in the `foo` namespace.

##### Listing 12.8. A definition of a `Role`: service-reader.yaml

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: foo
  name: service-reader
rules:
- apiGroups: [""]
  verbs: ["get", "list"]
  resources: ["services"]
```

---

##### Warning

The plural form must be used when specifying resources.

---

This Role resource will be created in the `foo` namespace. In [chapter 8](/book/kubernetes-in-action/chapter-8/ch08), you learned that each resource type belongs to an API group, which you specify in the `apiVersion` field (along with the version) in the resource’s manifest. In a Role definition, you need to specify the `apiGroup` for the resources listed in each rule included in the definition. If you’re allowing access to resources belonging to different API groups, you use multiple rules.

---

##### Note

In the example, you’re allowing access to all Service resources, but you could also limit access only to specific Service instances by specifying their names through an additional `resourceNames` field.

---

[Figure 12.4](/book/kubernetes-in-action/chapter-12/ch12fig04) shows the Role, its verbs and resources, and the namespace it will be created in.

![Figure 12.4. The service-reader Role allows getting and listing Services in the foo namespace.](https://drek4537l1klr.cloudfront.net/luksa/Figures/12fig04_alt.jpg)

##### Creating a Role

Create the previous Role in the `foo` namespace now:

```bash
$ kubectl create -f service-reader.yaml -n foo
role "service-reader" created
```

---

##### Note

The `-n` option is shorthand for `--namespace`.

---

Note that if you’re using GKE, the previous command may fail because you don’t have cluster-admin rights. To grant the rights, run the following command:

```bash
$ kubectl create clusterrolebinding cluster-admin-binding
➥  --clusterrole=cluster-admin --user=your.email@address.com
```

Instead of creating the `service-reader` Role from a YAML file, you could also create it with the special `kubectl create role` command. Let’s use this method to create the Role in the `bar` namespace:

```bash
$ kubectl create role service-reader --verb=get --verb=list
➥  --resource=services -n bar
role "service-reader" created
```

These two Roles will allow you to list Services in the `foo` and `bar` namespaces from within your two pods (running in the `foo` and `bar` namespace, respectively). But creating the two Roles isn’t enough (you can check by executing the `curl` command again). You need to bind each of the Roles to the ServiceAccounts in their respective namespaces.

##### Binding a Role to a ServiceAccount

A Role defines what actions can be performed, but it doesn’t specify who can perform them. To do that, you must bind the Role to a subject, which can be a user, a Service-Account, or a group (of users or ServiceAccounts).

Binding Roles to subjects is achieved by creating a RoleBinding resource. To bind the Role to the `default` ServiceAccount, run the following command:

```bash
$ kubectl create rolebinding test --role=service-reader
➥  --serviceaccount=foo:default -n foo
rolebinding "test" created
```

The command should be self-explanatory. You’re creating a RoleBinding, which binds the `service-reader` Role to the `default` Service-Account in namespace `foo`. You’re creating the RoleBinding in namespace `foo`. The RoleBinding and the referenced ServiceAccount and Role are shown in [figure 12.5](/book/kubernetes-in-action/chapter-12/ch12fig05).

![Figure 12.5. The test RoleBinding binds the default ServiceAccount with the service-reader Role.](https://drek4537l1klr.cloudfront.net/luksa/Figures/12fig05_alt.jpg)

---

##### Note

To bind a Role to a user instead of a ServiceAccount, use the `--user` argument to specify the username. To bind it to a group, use `--group`.

---

The following listing shows the YAML of the RoleBinding you created.

##### Listing 12.9. A RoleBinding referencing a Role

```bash
$ kubectl get rolebinding test -n foo -o yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: test
  namespace: foo
  ...
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role                           #1
  name: service-reader                 #1
subjects:
- kind: ServiceAccount                 #2
  name: default                        #2
  namespace: foo                       #2
```

As you can see, a RoleBinding always references a single Role (as evident from the `roleRef` property), but can bind the Role to multiple `subjects` (for example, one or more Service-Accounts and any number of users or groups). Because this RoleBinding binds the Role to the ServiceAccount the pod in namespace `foo` is running under, you can now list Services from within that pod.

##### Listing 12.10. Getting Services from the API server

```
/ # curl localhost:8001/api/v1/namespaces/foo/services
{
  "kind": "ServiceList",
  "apiVersion": "v1",
  "metadata": {
    "selfLink": "/api/v1/namespaces/foo/services",
    "resourceVersion": "24906"
  },
  "items": []                 #1
}
```

##### Including ServiceAccounts from other namespaces in a RoleBinding

The pod in namespace `bar` can’t list the Services in its own namespace, and obviously also not those in the `foo` namespace. But you can edit your RoleBinding in the `foo` namespace and add the other pod’s ServiceAccount, even though it’s in a different namespace. Run the following command:

```bash
$ kubectl edit rolebinding test -n foo
```

Then add the following lines to the list of `subjects`, as shown in the following listing.

##### Listing 12.11. Referencing a ServiceAccount from another namespace

```yaml
subjects:
- kind: ServiceAccount
  name: default
  namespace: bar
```

Now you can also list Services in the `foo` namespace from inside the pod running in the `bar` namespace. Run the same command as in [listing 12.10](/book/kubernetes-in-action/chapter-12/ch12ex10), but do it in the other terminal, where you’re running the shell in the other pod.

Before moving on to ClusterRoles and ClusterRoleBindings, let’s summarize what RBAC resources you currently have. You have a RoleBinding in namespace `foo`, which references the `service-reader` Role (also in the `foo` namespace) and binds the `default` ServiceAccounts in both the `foo` and the `bar` namespaces, as depicted in [figure 12.6](/book/kubernetes-in-action/chapter-12/ch12fig06).

![Figure 12.6. A RoleBinding binding ServiceAccounts from different namespaces to the same Role.](https://drek4537l1klr.cloudfront.net/luksa/Figures/12fig06_alt.jpg)

### 12.2.4. Using ClusterRoles and ClusterRoleBindings

Roles and RoleBindings are namespaced resources, meaning they reside in and apply to resources in a single namespace, but, as we saw, RoleBindings can refer to Service-Accounts from other namespaces, too.

In addition to these namespaced resources, two cluster-level RBAC resources also exist: ClusterRole and ClusterRoleBinding. They’re not namespaced. Let’s see why you need them.

A regular Role only allows access to resources in the same namespace the Role is in. If you want to allow someone access to resources across different namespaces, you have to create a Role and RoleBinding in every one of those namespaces. If you want to extend this to all namespaces (this is something a cluster administrator would probably need), you need to create the same Role and RoleBinding in each namespace. When creating an additional namespace, you have to remember to create the two resources there as well.

As you’ve learned throughout the book, certain resources aren’t namespaced at all (this includes Nodes, PersistentVolumes, Namespaces, and so on). We’ve also mentioned the API server exposes some URL paths that don’t represent resources (`/healthz` for example). Regular Roles can’t grant access to those resources or non-resource URLs, but ClusterRoles can.

A ClusterRole is a cluster-level resource for allowing access to non-namespaced resources or non-resource URLs or used as a common role to be bound inside individual namespaces, saving you from having to redefine the same role in each of them.

##### Allowing access to cluster-level resources

As mentioned, a ClusterRole can be used to allow access to cluster-level resources. Let’s look at how to allow your pod to list PersistentVolumes in your cluster. First, you’ll create a ClusterRole called `pv-reader`:

```bash
$ kubectl create clusterrole pv-reader --verb=get,list
➥  --resource=persistentvolumes
clusterrole "pv-reader" created
```

The ClusterRole’s YAML is shown in the following listing.

##### Listing 12.12. A ClusterRole definition

```bash
$ kubectl get clusterrole pv-reader -o yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:                                       #1
  name: pv-reader                               #1
  resourceVersion: "39932"                      #1
  selfLink: ...                                 #1
  uid: e9ac1099-30e2-11e7-955c-080027e6b159     #1
rules:
- apiGroups:                                    #2
  - ""                                          #2
  resources:                                    #2
  - persistentvolumes                           #2
  verbs:                                        #2
  - get                                         #2
  - list                                        #2
```

Before you bind this ClusterRole to your pod’s ServiceAccount, verify whether the pod can list PersistentVolumes. Run the following command in the first terminal, where you’re running the shell inside the pod in the `foo` namespace:

```
/ # curl localhost:8001/api/v1/persistentvolumes
User "system:serviceaccount:foo:default" cannot list persistentvolumes at the cluster scope.
```

---

##### Note

The URL contains no namespace, because PersistentVolumes aren’t namespaced.

---

As expected, the default ServiceAccount can’t list PersistentVolumes. You need to bind the ClusterRole to your ServiceAccount to allow it to do that. ClusterRoles can be bound to subjects with regular RoleBindings, so you’ll create a RoleBinding now:

```bash
$ kubectl create rolebinding pv-test --clusterrole=pv-reader
➥  --serviceaccount=foo:default -n foo
rolebinding "pv-test" created
```

Can you list PersistentVolumes now?

```
/ # curl localhost:8001/api/v1/persistentvolumes
User "system:serviceaccount:foo:default" cannot list persistentvolumes at the cluster scope.
```

Hmm, that’s strange. Let’s examine the RoleBinding’s YAML in the following listing. Can you tell what (if anything) is wrong with it?

##### Listing 12.13. A RoleBinding referencing a ClusterRole

```bash
$ kubectl get rolebindings pv-test -o yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pv-test
  namespace: foo
  ...
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole                      #1
  name: pv-reader                        #1
subjects:
- kind: ServiceAccount                   #2
  name: default                          #2
  namespace: foo                         #2
```

The YAML looks perfectly fine. You’re referencing the correct ClusterRole and the correct ServiceAccount, as shown in [figure 12.7](/book/kubernetes-in-action/chapter-12/ch12fig07), so what’s wrong?

![Figure 12.7. A RoleBinding referencing a ClusterRole doesn’t grant access to clusterlevel resources.](https://drek4537l1klr.cloudfront.net/luksa/Figures/12fig07_alt.jpg)

Although you can create a RoleBinding and have it reference a ClusterRole when you want to enable access to namespaced resources, you can’t use the same approach for cluster-level (non-namespaced) resources. To grant access to cluster-level resources, you must always use a ClusterRoleBinding.

Luckily, creating a ClusterRoleBinding isn’t that different from creating a Role-Binding, but you’ll clean up and delete the RoleBinding first:

```bash
$ kubectl delete rolebinding pv-test
rolebinding "pv-test" deleted
```

Now create the ClusterRoleBinding:

```bash
$ kubectl create clusterrolebinding pv-test --clusterrole=pv-reader
➥  --serviceaccount=foo:default
clusterrolebinding "pv-test" created
```

As you can see, you replaced `rolebinding` with `clusterrolebinding` in the command and didn’t (need to) specify the namespace. [Figure 12.8](/book/kubernetes-in-action/chapter-12/ch12fig08) shows what you have now.

![Figure 12.8. A ClusterRoleBinding and ClusterRole must be used to grant access to cluster-level resources.](https://drek4537l1klr.cloudfront.net/luksa/Figures/12fig08_alt.jpg)

Let’s see if you can list PersistentVolumes now:

```
/ # curl localhost:8001/api/v1/persistentvolumes
{
  "kind": "PersistentVolumeList",
  "apiVersion": "v1",
...
```

You can! It turns out you must use a ClusterRole and a ClusterRoleBinding when granting access to cluster-level resources.

---

##### Tip

Remember that a RoleBinding can’t grant access to cluster-level resources, even if it references a ClusterRoleBinding.

---

##### Allowing access to non-resource URLs

We’ve mentioned that the API server also exposes non-resource URLs. Access to these URLs must also be granted explicitly; otherwise the API server will reject the client’s request. Usually, this is done for you automatically through the `system:discovery` ClusterRole and the identically named ClusterRoleBinding, which appear among other predefined ClusterRoles and ClusterRoleBindings (we’ll explore them in [section 12.2.5](/book/kubernetes-in-action/chapter-12/ch12lev2sec9)).

Let’s inspect the `system:discovery` ClusterRole shown in the following listing.

##### Listing 12.14. The default `system:discovery ClusterRole`

```bash
$ kubectl get clusterrole system:discovery -o yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: system:discovery
  ...
rules:
- nonResourceURLs:      #1
  - /api                #1
  - /api/*              #1
  - /apis               #1
  - /apis/*             #1
  - /healthz            #1
  - /swaggerapi         #1
  - /swaggerapi/*       #1
  - /version            #1
  verbs:                #2
  - get                 #2
```

You can see this ClusterRole refers to URLs instead of resources (field `nonResource-URLs` is used instead of the `resources` field). The `verbs` field only allows the `GET` HTTP method to be used on these URLs.

---

##### Note

For non-resource URLs, plain HTTP verbs such as `post`, `put`, and `patch` are used instead of `create` or `update`. The verbs need to be specified in lowercase.

---

As with cluster-level resources, ClusterRoles for non-resource URLs must be bound with a ClusterRoleBinding. Binding them with a RoleBinding won’t have any effect. The `system:discovery` ClusterRole has a corresponding system:discovery Cluster-RoleBinding, so let’s see what’s in it by examining the following listing.

##### Listing 12.15. The default `system:discovery` ClusterRoleBinding

```bash
$ kubectl get clusterrolebinding system:discovery -o yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: system:discovery
  ...
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole                           #1
  name: system:discovery                      #1
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: Group                                 #2
  name: system:authenticated                  #2
- apiGroup: rbac.authorization.k8s.io
  kind: Group                                 #2
  name: system:unauthenticated                #2
```

The YAML shows the ClusterRoleBinding refers to the `system:discovery` ClusterRole, as expected. It’s bound to two groups, `system:authenticated` and `system:unauthenticated`, which makes it bound to all users. This means absolutely everyone can access the URLs listed in the ClusterRole.

---

##### Note

Groups are in the domain of the authentication plugin. When a request is received by the API server, it calls the authentication plugin to obtain the list of groups the user belongs to. This information is then used in authorization.

---

You can confirm this by accessing the `/api` URL path from inside the pod (through the `kubectl proxy`, which means you’ll be authenticated as the pod’s ServiceAccount) and from your local machine, without specifying any authentication tokens (making you an unauthenticated user):

```bash
$ curl https://$(minikube ip):8443/api -k
{
  "kind": "APIVersions",
  "versions": [
  ...
```

You’ve now used ClusterRoles and ClusterRoleBindings to grant access to cluster-level resources and non-resource URLs. Now let’s look at how ClusterRoles can be used with namespaced RoleBindings to grant access to namespaced resources in the Role-Binding’s namespace.

##### Using ClusterRoles to grant access to resources in specific namespaces

ClusterRoles don’t always need to be bound with cluster-level ClusterRoleBindings. They can also be bound with regular, namespaced RoleBindings. You’ve already started looking at predefined ClusterRoles, so let’s look at another one called `view`, which is shown in the following listing.

##### Listing 12.16. The default `view` ClusterRole

```bash
$ kubectl get clusterrole view -o yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: view
  ...
rules:
- apiGroups:
  - ""
  resources:                           #1
  - configmaps                         #1
  - endpoints                          #1
  - persistentvolumeclaims             #1
  - pods                               #1
  - replicationcontrollers             #1
  - replicationcontrollers/scale       #1
  - serviceaccounts                    #1
  - services                           #1
  verbs:                               #2
  - get                                #2
  - list                               #2
  - watch                              #2
...
```

This ClusterRole has many rules. Only the first one is shown in the listing. The rule allows getting, listing, and watching resources like ConfigMaps, Endpoints, Persistent-VolumeClaims, and so on. These are namespaced resources, even though you’re looking at a ClusterRole (not a regular, namespaced Role). What exactly does this Cluster-Role do?

It depends whether it’s bound with a ClusterRoleBinding or a RoleBinding (it can be bound with either). If you create a ClusterRoleBinding and reference the ClusterRole in it, the subjects listed in the binding can view the specified resources across all namespaces. If, on the other hand, you create a RoleBinding, the subjects listed in the binding can only view resources in the namespace of the RoleBinding. You’ll try both options now.

You’ll see how the two options affect your test pod’s ability to list pods. First, let’s see what happens before any bindings are in place:

```
/ # curl localhost:8001/api/v1/pods
User "system:serviceaccount:foo:default" cannot list pods at the cluster scope./ #
/ # curl localhost:8001/api/v1/namespaces/foo/pods
User "system:serviceaccount:foo:default" cannot list pods in the namespace "foo".
```

With the first command, you’re trying to list pods across all namespaces. With the second, you’re trying to list pods in the `foo` namespace. The server doesn’t allow you to do either.

Now, let’s see what happens when you create a ClusterRoleBinding and bind it to the pod’s ServiceAccount:

```bash
$ kubectl create clusterrolebinding view-test --clusterrole=view
➥  --serviceaccount=foo:default
clusterrolebinding "view-test" created
```

Can the pod now list pods in the `foo` namespace?

```
/ # curl localhost:8001/api/v1/namespaces/foo/pods
{
  "kind": "PodList",
  "apiVersion": "v1",
  ...
```

It can! Because you created a ClusterRoleBinding, it applies across all namespaces. The pod in namespace `foo` can list pods in the `bar` namespace as well:

```
/ # curl localhost:8001/api/v1/namespaces/bar/pods
{
  "kind": "PodList",
  "apiVersion": "v1",
  ...
```

Okay, the pod is allowed to list pods in a different namespace. It can also retrieve pods across all namespaces by hitting the /api/v1/pods URL path:

```
/ # curl localhost:8001/api/v1/pods
{
  "kind": "PodList",
  "apiVersion": "v1",
  ...
```

As expected, the pod can get a list of all the pods in the cluster. To summarize, combining a ClusterRoleBinding with a ClusterRole referring to namespaced resources allows the pod to access namespaced resources in any namespace, as shown in [figure 12.9](/book/kubernetes-in-action/chapter-12/ch12fig09).

![Figure 12.9. A ClusterRoleBinding and ClusterRole grants permission to resources across all namespaces.](https://drek4537l1klr.cloudfront.net/luksa/Figures/12fig09_alt.jpg)

Now, let’s see what happens if you replace the ClusterRoleBinding with a RoleBinding. First, delete the ClusterRoleBinding:

```bash
$ kubectl delete clusterrolebinding view-test
clusterrolebinding "view-test" deleted
```

Next create a RoleBinding instead. Because a RoleBinding is namespaced, you need to specify the namespace you want to create it in. Create it in the `foo` namespace:

```bash
$ kubectl create rolebinding view-test --clusterrole=view
➥  --serviceaccount=foo:default -n foo
rolebinding "view-test" created
```

You now have a RoleBinding in the `foo` namespace, binding the `default` Service-Account in that same namespace with the `view` ClusterRole. What can your pod access now?

```
/ # curl localhost:8001/api/v1/namespaces/foo/pods
{
  "kind": "PodList",
  "apiVersion": "v1",
  ...

/ # curl localhost:8001/api/v1/namespaces/bar/pods
User "system:serviceaccount:foo:default" cannot list pods in the namespace "bar".

/ # curl localhost:8001/api/v1/pods
User "system:serviceaccount:foo:default" cannot list pods at the cluster scope.
```

As you can see, your pod can list pods in the `foo` namespace, but not in any other specific namespace or across all namespaces. This is visualized in [figure 12.10](/book/kubernetes-in-action/chapter-12/ch12fig10).

![Figure 12.10. A RoleBinding referring to a ClusterRole only grants access to resources inside the RoleBinding’s namespace.](https://drek4537l1klr.cloudfront.net/luksa/Figures/12fig10_alt.jpg)

##### Summarizing Role, ClusterRole, RoleBinding, and ClusterRoleBinding combinations

We’ve covered many different combinations and it may be hard for you to remember when to use each one. Let’s see if we can make sense of all these combinations by categorizing them per specific use case. Refer to [table 12.2](/book/kubernetes-in-action/chapter-12/ch12table02).

##### Table 12.2. When to use specific combinations of role and binding types[(view table figure)](https://drek4537l1klr.cloudfront.net/luksa/HighResolutionFigures/table_12-2.png)

For accessing

Role type to use

Binding type to use

Cluster-level resources (Nodes, PersistentVolumes, ...)ClusterRoleClusterRoleBindingNon-resource URLs (/api, /healthz, ...)ClusterRoleClusterRoleBindingNamespaced resources in any namespace (and across all namespaces)ClusterRoleClusterRoleBindingNamespaced resources in a specific namespace (reusing the same ClusterRole in multiple namespaces)ClusterRoleRoleBindingNamespaced resources in a specific namespace (Role must be defined in each namespace)RoleRoleBindingHopefully, the relationships between the four RBAC resources are much clearer now. Don’t worry if you still feel like you don’t yet grasp everything. Things may clear up as we explore the pre-configured ClusterRoles and ClusterRoleBindings in the next section.

### 12.2.5. Understanding default ClusterRoles and ClusterRoleBindings

Kubernetes comes with a default set of ClusterRoles and ClusterRoleBindings, which are updated every time the API server starts. This ensures all the default roles and bindings are recreated if you mistakenly delete them or if a newer version of Kubernetes uses a different configuration of cluster roles and bindings.

You can see the default cluster roles and bindings in the following listing.

##### Listing 12.17. Listing all ClusterRoleBinding`s` and ClusterRole`s`

```bash
$ kubectl get clusterrolebindings
NAME                                           AGE
cluster-admin                                  1d
system:basic-user                              1d
system:controller:attachdetach-controller      1d
...
system:controller:ttl-controller               1d
system:discovery                               1d
system:kube-controller-manager                 1d
system:kube-dns                                1d
system:kube-scheduler                          1d
system:node                                    1d
system:node-proxier                            1d

$ kubectl get clusterroles
NAME                                           AGE
admin                                          1d
cluster-admin                                  1d
edit                                           1d
system:auth-delegator                          1d
system:basic-user                              1d
system:controller:attachdetach-controller      1d
...
system:controller:ttl-controller               1d
system:discovery                               1d
system:heapster                                1d
system:kube-aggregator                         1d
system:kube-controller-manager                 1d
system:kube-dns                                1d
system:kube-scheduler                          1d
system:node                                    1d
system:node-bootstrapper                       1d
system:node-problem-detector                   1d
system:node-proxier                            1d
system:persistent-volume-provisioner           1d
view                                           1d
```

The most important roles are the `view`, `edit`, `admin`, and `cluster-admin` ClusterRoles. They’re meant to be bound to ServiceAccounts used by user-defined pods.

##### Allowing read-only access to resources with the view ClusterRole

You already used the default `view` ClusterRole in the previous example. It allows reading most resources in a namespace, except for Roles, RoleBindings, and Secrets. You’re probably wondering, why not Secrets? Because one of those Secrets might include an authentication token with greater privileges than those defined in the `view` ClusterRole and could allow the user to masquerade as a different user to gain additional privileges (privilege escalation).

##### Allowing modifying resources with the edit ClusterRole

Next is the `edit` ClusterRole, which allows you to modify resources in a namespace, but also allows both reading and modifying Secrets. It doesn’t, however, allow viewing or modifying Roles or RoleBindings—again, this is to prevent privilege escalation.

##### Granting full control of a namespace with the admin ClusterRole

Complete control of the resources in a namespace is granted in the `admin` ClusterRole. Subjects with this ClusterRole can read and modify any resource in the namespace, except ResourceQuotas (we’ll learn what those are in [chapter 14](/book/kubernetes-in-action/chapter-14/ch14)) and the Namespace resource itself. The main difference between the `edit` and the `admin` Cluster-Roles is in the ability to view and modify Roles and RoleBindings in the namespace.

---

##### Note

To prevent privilege escalation, the API server only allows users to create and update Roles if they already have all the permissions listed in that Role (and for the same scope).

---

##### Allowing complete control with the cluster-admin ClusterRole

Complete control of the Kubernetes cluster can be given by assigning the `cluster-admin` ClusterRole to a subject. As you’ve seen before, the `admin` ClusterRole doesn’t allow users to modify the namespace’s ResourceQuota objects or the Namespace resource itself. If you want to allow a user to do that, you need to create a Role-Binding that references the `cluster-admin` ClusterRole. This gives the user included in the RoleBinding complete control over all aspects of the namespace in which the Role-Binding is created.

If you’ve paid attention, you probably already know how to give users complete control of all the namespaces in the cluster. Yes, by referencing the `cluster-admin` ClusterRole in a ClusterRoleBinding instead of a RoleBinding.

##### Understanding the other default ClusterRoles

The list of default ClusterRoles includes a large number of other ClusterRoles, which start with the `system:` prefix. These are meant to be used by the various Kubernetes components. Among them, you’ll find roles such as `system:kube-scheduler`, which is obviously used by the Scheduler, `system:node`, which is used by the Kubelets, and so on.

Although the Controller Manager runs as a single pod, each controller running inside it can use a separate ClusterRole and ClusterRoleBinding (they’re prefixed with `system: controller:`).

Each of these system ClusterRoles has a matching ClusterRoleBinding, which binds it to the user the system component authenticates as. The `system:kube-scheduler` ClusterRoleBinding, for example, assigns the identically named ClusterRole to the `system:kube-scheduler` user, which is the username the scheduler Authenticates as.

### 12.2.6. Granting authorization permissions wisely

By default, the default ServiceAccount in a namespace has no permissions other than those of an unauthenticated user (as you may remember from one of the previous examples, the `system:discovery` ClusterRole and associated binding allow anyone to make GET requests on a few non-resource URLs). Therefore, pods, by default, can’t even view cluster state. It’s up to you to grant them appropriate permissions to do that.

Obviously, giving all your ServiceAccounts the `cluster-admin` ClusterRole is a bad idea. As is always the case with security, it’s best to give everyone only the permissions they need to do their job and not a single permission more (*principle of least privilege*).

##### Creating specific ServiceAccounts for each pod

It’s a good idea to create a specific ServiceAccount for each pod (or a set of pod replicas) and then associate it with a tailor-made Role (or a ClusterRole) through a RoleBinding (not a ClusterRoleBinding, because that would give the pod access to resources in other namespaces, which is probably not what you want).

If one of your pods (the application running within it) only needs to read pods, while the other also needs to modify them, then create two different ServiceAccounts and make those pods use them by specifying the `serviceAccountName` property in the pod spec, as you learned in the first part of this chapter. Don’t add all the necessary permissions required by both pods to the default ServiceAccount in the namespace.

##### Expecting your apps to be compromised

Your aim is to reduce the possibility of an intruder getting hold of your cluster. Today’s complex apps contain many vulnerabilities. You should expect unwanted persons to eventually get their hands on the ServiceAccount’s authentication token, so you should always constrain the ServiceAccount to prevent them from doing any real damage.

## 12.3. Summary

This chapter has given you a foundation on how to secure the Kubernetes API server. You learned the following:

- Clients of the API server include both human users and applications running in pods.
- Applications in pods are associated with a ServiceAccount.
- Both users and ServiceAccounts are associated with groups.
- By default, pods run under the default ServiceAccount, which is created for each namespace automatically.
- Additional ServiceAccounts can be created manually and associated with a pod.
- ServiceAccounts can be configured to allow mounting only a constrained list of Secrets in a given pod.
- A ServiceAccount can also be used to attach image pull Secrets to pods, so you don’t need to specify the Secrets in every pod.
- Roles and ClusterRoles define what actions can be performed on which resources.
- RoleBindings and ClusterRoleBindings bind Roles and ClusterRoles to users, groups, and ServiceAccounts.
- Each cluster comes with default ClusterRoles and ClusterRoleBindings.

In the next chapter, you’ll learn how to protect the cluster nodes from pods and how to isolate pods from each other by securing the network.
