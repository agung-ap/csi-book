# Chapter 7. ConfigMaps and Secrets: configuring applications

### **This chapter covers**

- Changing the main process of a container
- Passing command-line options to the app
- Setting environment variables exposed to the app
- Configuring apps through ConfigMaps
- Passing sensitive information through Secrets

Up to now you haven’t had to pass any kind of configuration data to the apps you’ve run in the exercises in this book. Because almost all apps require configuration (settings that differ between deployed instances, credentials for accessing external systems, and so on), which shouldn’t be baked into the built app itself, let’s see how to pass configuration options to your app when running it in Kubernetes.

## 7.1. Configuring containerized applications

Before we go over how to pass configuration data to apps running in Kubernetes, let’s look at how containerized applications are usually configured.

If you skip the fact that you can bake the configuration into the application itself, when starting development of a new app, you usually start off by having the app configured through command-line arguments. Then, as the list of configuration options grows, you can move the configuration into a config file.

Another way of passing configuration options to an application that’s widely popular in containerized applications is through environment variables. Instead of having the app read a config file or command-line arguments, the app looks up the value of a certain environment variable. The official MySQL container image, for example, uses an environment variable called `MYSQL_ROOT_PASSWORD` for setting the password for the root super-user account.

But why are environment variables so popular in containers? Using configuration files inside Docker containers is a bit tricky, because you’d have to bake the config file into the container image itself or mount a volume containing the file into the container. Obviously, baking files into the image is similar to hardcoding configuration into the source code of the application, because it requires you to rebuild the image every time you want to change the config. Plus, everyone with access to the image can see the config, including any information that should be kept secret, such as credentials or encryption keys. Using a volume is better, but still requires you to make sure the file is written to the volume before the container is started.

If you’ve read the previous chapter, you might think of using a `gitRepo` volume as a configuration source. That’s not a bad idea, because it allows you to keep the config nicely versioned and enables you to easily rollback a config change if necessary. But a simpler way allows you to put the configuration data into a top-level Kubernetes resource and store it and all the other resource definitions in the same Git repository or in any other file-based storage. The Kubernetes resource for storing configuration data is called a ConfigMap. We’ll learn how to use it in this chapter.

Regardless if you’re using a ConfigMap to store configuration data or not, you can configure your apps by

- Passing command-line arguments to containers
- Setting custom environment variables for each container
- Mounting configuration files into containers through a special type of volume

We’ll go over all these options in the next few sections, but before we start, let’s look at config options from a security perspective. Though most configuration options don’t contain any sensitive information, several can. These include credentials, private encryption keys, and similar data that needs to be kept secure. This type of information needs to be handled with special care, which is why Kubernetes offers another type of first-class object called a Secret. We’ll learn about it in the last part of this chapter.

## 7.2. Passing command-line arguments to containers

In all the examples so far, you’ve created containers that ran the default command defined in the container image, but Kubernetes allows overriding the command as part of the pod’s container definition when you want to run a different executable instead of the one specified in the image, or want to run it with a different set of command-line arguments. We’ll look at how to do that now.

### 7.2.1. Defining the command and arguments in Docker

The first thing I need to explain is that the whole command that gets executed in the container is composed of two parts: the *command* and the *arguments*.

##### Understanding ENTRYPOINT and CMD

In a Dockerfile, two instructions define the two parts:

- `ENTRYPOINT` defines the executable invoked when the container is started.
- `CMD` specifies the arguments that get passed to the `ENTRYPOINT`.

Although you can use the `CMD` instruction to specify the command you want to execute when the image is run, the correct way is to do it through the `ENTRYPOINT` instruction and to only specify the `CMD` if you want to define the default arguments. The image can then be run without specifying any arguments

```bash
$ docker run <image>
```

or with additional arguments, which override whatever’s set under `CMD` in the Dockerfile:

```bash
$ docker run <image> <arguments>
```

##### Understanding the difference between the shell and exec forms

But there’s more. Both instructions support two different forms:

- `shell` form—For example, `ENTRYPOINT node app.js.`
- `exec` form—For example, `ENTRYPOINT ["node", "app.js"]`.

The difference is whether the specified command is invoked inside a shell or not.

In the `kubia` image you created in [chapter 2](/book/kubernetes-in-action/chapter-2/ch02), you used the `exec` form of the `ENTRYPOINT` instruction:

```dockerfile
ENTRYPOINT ["node", "app.js"]
```

This runs the node process directly (not inside a shell), as you can see by listing the processes running inside the container:

```bash
$ docker exec 4675d ps x
  PID TTY      STAT   TIME COMMAND
    1 ?        Ssl    0:00 node app.js
   12 ?        Rs     0:00 ps x
```

If you’d used the `shell` form (`ENTRYPOINT node app.js`), these would have been the container’s processes:

```bash
$ docker exec -it e4bad ps x
  PID TTY      STAT   TIME COMMAND
    1 ?        Ss     0:00 /bin/sh -c node app.js
    7 ?        Sl     0:00 node app.js
   13 ?        Rs+    0:00 ps x
```

As you can see, in that case, the main process (`PID 1`) would be the `shell` process instead of the node process. The node process (`PID 7`) would be started from that shell. The `shell` process is unnecessary, which is why you should always use the `exec` form of the ENTRYPOINT instruction.

##### Making the interval configurable in your fortune image

Let’s modify your fortune script and image so the delay interval in the loop is configurable. You’ll add an `INTERVAL` variable and initialize it with the value of the first command-line argument, as shown in the following listing.

##### Listing 7.1. Fortune script with interval configurable through argument: fortune-args/fortuneloop.sh

```
#!/bin/bash
trap "exit" SIGINT
INTERVAL=$1
echo Configured to generate new fortune every $INTERVAL seconds
mkdir -p /var/htdocs
while :
do
  echo $(date) Writing fortune to /var/htdocs/index.html
  /usr/games/fortune > /var/htdocs/index.html
  sleep $INTERVAL
done
```

You’ve added or modified the lines in bold font. Now, you’ll modify the Dockerfile so it uses the `exec` version of the `ENTRYPOINT` instruction and sets the default interval to 10 seconds using the `CMD` instruction, as shown in the following listing.

##### Listing 7.2. Dockerfile for the updated `fortune` image: fortune-args/Dockerfile

```dockerfile
FROM ubuntu:latest
RUN apt-get update ; apt-get -y install fortune
ADD fortuneloop.sh /bin/fortuneloop.sh
ENTRYPOINT ["/bin/fortuneloop.sh"]                 #1
CMD ["10"]                                         #2
```

You can now build and push the image to Docker Hub. This time, you’ll tag the image as `args` instead of `latest`:

```bash
$ docker build -t docker.io/luksa/fortune:args .
$ docker push docker.io/luksa/fortune:args
```

You can test the image by running it locally with Docker:

```bash
$ docker run -it docker.io/luksa/fortune:args
Configured to generate new fortune every 10 seconds
Fri May 19 10:39:44 UTC 2017 Writing fortune to /var/htdocs/index.html
```

---

##### Note

You can stop the script with Control+C.

---

And you can override the default sleep interval by passing it as an argument:

```bash
$ docker run -it docker.io/luksa/fortune:args 15
Configured to generate new fortune every 15 seconds
```

Now that you’re sure your image honors the argument passed to it, let’s see how to use it in a pod.

### 7.2.2. Overriding the command and arguments in Kubernetes

In Kubernetes, when specifying a container, you can choose to override both `ENTRYPOINT` and `CMD`. To do that, you set the properties `command` and `args` in the container specification, as shown in the following listing.

##### Listing 7.3. A pod definition specifying a custom command and arguments

```yaml
kind: Pod
spec:
  containers:
  - image: some/image
    command: ["/bin/command"]
    args: ["arg1", "arg2", "arg3"]
```

In most cases, you’ll only set custom arguments and rarely override the command (except in general-purpose images such as `busybox`, which doesn’t define an `ENTRYPOINT` at all).

---

##### Note

The `command` and `args` fields can’t be updated after the pod is created.

---

The two Dockerfile instructions and the equivalent pod spec fields are shown in [table 7.1](/book/kubernetes-in-action/chapter-7/ch07table01).

##### Table 7.1. Specifying the executable and its arguments in Docker vs Kubernetes[(view table figure)](https://drek4537l1klr.cloudfront.net/luksa/HighResolutionFigures/table_7-1.png)

Docker

Kubernetes

Description

ENTRYPOINTcommandThe executable that’s executed inside the containerCMDargsThe arguments passed to the executable##### Running the fortune pod with a custom interval

To run the fortune pod with a custom delay interval, you’ll copy your fortune-pod.yaml into fortune-pod-args.yaml and modify it as shown in the following listing.

##### Listing 7.4. Passing an argument in the pod definition: fortune-pod-args.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: fortune2s
spec:
  containers:
  - image: luksa/fortune:args
    args: ["2"]
    name: html-generator
    volumeMounts:
    - name: html
      mountPath: /var/htdocs
...
```

You added the `args` array to the container definition. Try creating this pod now. The values of the array will be passed to the container as command-line arguments when it is run.

The array notation used in this listing is great if you have one argument or a few. If you have several, you can also use the following notation:

```
args:
    - foo
    - bar
    - "15"
```

---

##### Tip

You don’t need to enclose string values in quotations marks (but you must enclose numbers).

---

Specifying arguments is one way of passing config options to your containers through command-line arguments. Next, you’ll see how to do it through environment variables.

## 7.3. Setting environment variables for a container

As I’ve already mentioned, containerized applications often use environment variables as a source of configuration options. Kubernetes allows you to specify a custom list of environment variables for each container of a pod, as shown in [figure 7.1](/book/kubernetes-in-action/chapter-7/ch07fig01). Although it would be useful to also define environment variables at the pod level and have them be inherited by its containers, no such option currently exists.

---

##### Note

Like the container’s command and arguments, the list of environment variables also cannot be updated after the pod is created.

---

![Figure 7.1. Environment variables can be set per container.](https://drek4537l1klr.cloudfront.net/luksa/Figures/07fig01.jpg)

##### Making the interval in your fortune image configurable through an- n environment variable

Let’s see how to modify your fortuneloop.sh script once again to allow it to be configured from an environment variable, as shown in the following listing.

##### Listing 7.5. Fortune script with interval configurable through env var: fortune-env/fortuneloop.sh

```
#!/bin/bash
trap "exit" SIGINT
echo Configured to generate new fortune every $INTERVAL seconds
mkdir -p /var/htdocs
while :
do
  echo $(date) Writing fortune to /var/htdocs/index.html
  /usr/games/fortune > /var/htdocs/index.html
  sleep $INTERVAL
done
```

All you had to do was remove the row where the `INTERVAL` variable is initialized. Because your “app” is a simple bash script, you didn’t need to do anything else. If the app was written in Java you’d use `System.getenv("INTERVAL")`, whereas in Node.JS you’d use `process.env.INTERVAL`, and in Python you’d use `os.environ['INTERVAL']`.

### 7.3.1. Specifying environment variables in a container definition

After building the new image (I’ve tagged it as `luksa/fortune:env` this time) and pushing it to Docker Hub, you can run it by creating a new pod, in which you pass the environment variable to the script by including it in your container definition, as shown in the following listing.

##### Listing 7.6. Defining an environment variable in a pod: fortune-pod-env.yaml

```yaml
kind: Pod
spec:
 containers:
 - image: luksa/fortune:env
   env:
   - name: INTERVAL
     value: "30"
   name: html-generator
...
```

As mentioned previously, you set the environment variable inside the container definition, not at the pod level.

---

##### Note

Don’t forget that in each container, Kubernetes also automatically exposes environment variables for each service in the same namespace. These environment variables are basically auto-injected configuration.

---

### 7.3.2. Referring to other environment variables in a variable’s value

In the previous example, you set a fixed value for the environment variable, but you can also reference previously defined environment variables or any other existing variables by using the `$(VAR)` syntax. If you define two environment variables, the second one can include the value of the first one as shown in the following listing.

##### Listing 7.7. Referring to an environment variable inside another one

```
env:
- name: FIRST_VAR
  value: "foo"
- name: SECOND_VAR
  value: "$(FIRST_VAR)bar"
```

In this case, the `SECOND_VAR`’s value will be `"foobar"`. Similarly, both the `command` and `args` attributes you learned about in [section 7.2](/book/kubernetes-in-action/chapter-7/ch07lev1sec2) can also refer to environment variables like this. You’ll use this method in [section 7.4.5](/book/kubernetes-in-action/chapter-7/ch07lev2sec11).

### 7.3.3. Understanding the drawback of hardcoding environment variables

Having values effectively hardcoded in the pod definition means you need to have separate pod definitions for your production and your development pods. To reuse the same pod definition in multiple environments, it makes sense to decouple the configuration from the pod descriptor. Luckily, you can do that using a ConfigMap resource and using it as a source for environment variable values using the `valueFrom` instead of the `value` field. You’ll learn about this next.

## 7.4. Decoupling configuration with a ConfigMap

The whole point of an app’s configuration is to keep the config options that vary between environments, or change frequently, separate from the application’s source code. If you think of a pod descriptor as source code for your app (and in microservices architectures that’s what it really is, because it defines how to compose the individual components into a functioning system), it’s clear you should move the configuration out of the pod description.

### 7.4.1. Introducing ConfigMaps

Kubernetes allows separating configuration options into a separate object called a ConfigMap, which is a map containing key/value pairs with the values ranging from short literals to full config files.

An application doesn’t need to read the ConfigMap directly or even know that it exists. The contents of the map are instead passed to containers as either environment variables or as files in a volume (see [figure 7.2](/book/kubernetes-in-action/chapter-7/ch07fig02)). And because environment variables can be referenced in command-line arguments using the `$(ENV_VAR)` syntax, you can also pass ConfigMap entries to processes as command-line arguments.

![Figure 7.2. Pods use ConfigMaps through environment variables and configMap volumes.](https://drek4537l1klr.cloudfront.net/luksa/Figures/07fig02.jpg)

Sure, the application can also read the contents of a ConfigMap directly through the Kubernetes REST API endpoint if needed, but unless you have a real need for this, you should keep your app Kubernetes-agnostic as much as possible.

Regardless of how an app consumes a ConfigMap, having the config in a separate standalone object like this allows you to keep multiple manifests for ConfigMaps with the same name, each for a different environment (development, testing, QA, production, and so on). Because pods reference the ConfigMap by name, you can use a different config in each environment while using the same pod specification across all of them (see [figure 7.3](/book/kubernetes-in-action/chapter-7/ch07fig03)).

![Figure 7.3. Two different ConfigMaps with the same name used in different environments](https://drek4537l1klr.cloudfront.net/luksa/Figures/07fig03_alt.jpg)

### 7.4.2. Creating a ConfigMap

Let’s see how to use a ConfigMap in one of your pods. To start with the simplest example, you’ll first create a map with a single key and use it to fill the `INTERVAL` environment variable from your previous example. You’ll create the ConfigMap with the special `kubectl create configmap` command instead of posting a YAML with the generic `kubectl create -f` command.

##### Using the kubectl create configmap command

You can define the map’s entries by passing literals to the `kubectl` command or you can create the ConfigMap from files stored on your disk. Use a simple literal first:

```bash
$ kubectl create configmap fortune-config --from-literal=sleep-interval=25
configmap "fortune-config" created
```

---

##### Note

ConfigMap keys must be a valid DNS subdomain (they may only contain alphanumeric characters, dashes, underscores, and dots). They may optionally include a leading dot.

---

This creates a ConfigMap called `fortune-config` with the single-entry `sleep-interval =25` ([figure 7.4](/book/kubernetes-in-action/chapter-7/ch07fig04)).

![Figure 7.4. The fortune-config ConfigMap containing a single entry](https://drek4537l1klr.cloudfront.net/luksa/Figures/07fig04.jpg)

ConfigMaps usually contain more than one entry. To create a ConfigMap with multiple literal entries, you add multiple `--from-literal` arguments:

```bash
$ kubectl create configmap myconfigmap
➥   --from-literal=foo=bar --from-literal=bar=baz --from-literal=one=two
```

Let’s inspect the YAML descriptor of the ConfigMap you created by using the `kubectl get` command, as shown in the following listing.

##### Listing 7.8. A ConfigMap definition

```bash
$ kubectl get configmap fortune-config -o yaml
apiVersion: v1
data:
  sleep-interval: "25"                                  #1
kind: ConfigMap                                         #2
metadata:
  creationTimestamp: 2016-08-11T20:31:08Z
  name: fortune-config                                  #3
  namespace: default
  resourceVersion: "910025"
  selfLink: /api/v1/namespaces/default/configmaps/fortune-config
  uid: 88c4167e-6002-11e6-a50d-42010af00237
```

Nothing extraordinary. You could easily have written this YAML yourself (you wouldn’t need to specify anything but the name in the `metadata` section, of course) and posted it to the Kubernetes API with the well-known

```bash
$ kubectl create -f fortune-config.yaml
```

##### Creating a ConfigMap entry from the contents of a file

ConfigMaps can also store coarse-grained config data, such as complete config files. To do this, the `kubectl create configmap` command also supports reading files from disk and storing them as individual entries in the ConfigMap:

```bash
$ kubectl create configmap my-config --from-file=config-file.conf
```

When you run the previous command, kubectl looks for the file `config-file.conf` in the directory you run `kubectl` in. It will then store the contents of the file under the key `config-file.conf` in the ConfigMap (the filename is used as the map key), but you can also specify a key manually like this:

```bash
$ kubectl create configmap my-config --from-file=customkey=config-file.conf
```

This command will store the file’s contents under the key `customkey`. As with literals, you can add multiple files by using the `--from-file` argument multiple times.

##### Creating a ConfigMap from files in a directory

Instead of importing each file individually, you can even import all files from a file directory:

```bash
$ kubectl create configmap my-config --from-file=/path/to/dir
```

In this case, `kubectl` will create an individual map entry for each file in the specified directory, but only for files whose name is a valid ConfigMap key.

##### Combining different options

When creating ConfigMaps, you can use a combination of all the options mentioned here (note that these files aren’t included in the book’s code archive—you can create them yourself if you’d like to try out the command):

```bash
$ kubectl create configmap my-config
➥   --from-file=foo.json                     #1
➥   --from-file=bar=foobar.conf              #2
➥   --from-file=config-opts/                 #3
➥   --from-literal=some=thing                #4
```

Here, you’ve created the ConfigMap from multiple sources: a whole directory, a file, another file (but stored under a custom key instead of using the filename as the key), and a literal value. [Figure 7.5](/book/kubernetes-in-action/chapter-7/ch07fig05) shows all these sources and the resulting ConfigMap.

![Figure 7.5. Creating a ConfigMap from individual files, a directory, and a literal value](https://drek4537l1klr.cloudfront.net/luksa/Figures/07fig05_alt.jpg)

### 7.4.3. Passing a ConfigMap entry to a container as an environment variable

How do you now get the values from this map into a pod’s container? You have three options. Let’s start with the simplest—setting an environment variable. You’ll use the `valueFrom` field I mentioned in [section 7.3.3](/book/kubernetes-in-action/chapter-7/ch07lev2sec6). The pod descriptor should look like the following listing.

##### Listing 7.9. Pod with `env var` from a config map: fortune-pod-env-configmap.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: fortune-env-from-configmap
spec:
  containers:
  - image: luksa/fortune:env
    env:
    - name: INTERVAL
      valueFrom:
        configMapKeyRef:
          name: fortune-config
          key: sleep-interval
...
```

You defined an environment variable called `INTERVAL` and set its value to whatever is stored in the `fortune-config` ConfigMap under the key `sleep-interval`. When the process running in the `html-generator` container reads the `INTERVAL` environment variable, it will see the value `25` (shown in [figure 7.6](/book/kubernetes-in-action/chapter-7/ch07fig06)).

![Figure 7.6. Passing a ConfigMap entry as an environment variable to a container](https://drek4537l1klr.cloudfront.net/luksa/Figures/07fig06_alt.jpg)

##### Referencing non-existing ConfigMaps in a pod

You might wonder what happens if the referenced ConfigMap doesn’t exist when you create the pod. Kubernetes schedules the pod normally and tries to run its containers. The container referencing the non-existing ConfigMap will fail to start, but the other container will start normally. If you then create the missing ConfigMap, the failed container is started without requiring you to recreate the pod.

---

##### Note

You can also mark a reference to a ConfigMap as optional (by setting `configMapKeyRef.optional: true`). In that case, the container starts even if the ConfigMap doesn’t exist.

---

This example shows you how to decouple the configuration from the pod specification. This allows you to keep all the configuration options closely together (even for multiple pods) instead of having them splattered around the pod definition (or duplicated across multiple pod manifests).

### 7.4.4. Passing all entries of a ConfigMap as environment variables at once

When your ConfigMap contains more than just a few entries, it becomes tedious and error-prone to create environment variables from each entry individually. Luckily, Kubernetes version 1.6 provides a way to expose all entries of a ConfigMap as environment variables.

Imagine having a ConfigMap with three keys called `FOO`, `BAR`, and `FOO-BAR`. You can expose them all as environment variables by using the `envFrom` attribute, instead of `env` the way you did in previous examples. The following listing shows an example.

##### Listing 7.10. Pod with env vars from all entries of a ConfigMap

```
spec:
  containers:
  - image: some-image
    envFrom:                      #1
    - prefix: CONFIG_             #2
      configMapRef:               #3
        name: my-config-map       #3
...
```

As you can see, you can also specify a prefix for the environment variables (`CONFIG_` in this case). This results in the following two environment variables being present inside the container: `CONFIG_FOO` and `CONFIG_BAR`.

---

##### Note

The prefix is optional, so if you omit it the environment variables will have the same name as the keys.

---

Did you notice I said two variables, but earlier, I said the ConfigMap has three entries (`FOO`, `BAR`, and `FOO-BAR`)? Why is there no environment variable for the `FOO-BAR` ConfigMap entry?

The reason is that `CONFIG_FOO-BAR` isn’t a valid environment variable name because it contains a dash. Kubernetes doesn’t convert the keys in any way (it doesn’t convert dashes to underscores, for example). If a ConfigMap key isn’t in the proper format, it skips the entry (but it does record an event informing you it skipped it).

### 7.4.5. Passing a ConfigMap entry as a command-line argument

Now, let’s also look at how to pass values from a ConfigMap as arguments to the main process running in the container. You can’t reference ConfigMap entries directly in the `pod.spec.containers.args` field, but you can first initialize an environment variable from the ConfigMap entry and then refer to the variable inside the arguments as shown in [figure 7.7](/book/kubernetes-in-action/chapter-7/ch07fig07).

![Figure 7.7. Passing a ConfigMap entry as a command-line argument](https://drek4537l1klr.cloudfront.net/luksa/Figures/07fig07_alt.jpg)

[Listing 7.11](/book/kubernetes-in-action/chapter-7/ch07ex11) shows an example of how to do this in the YAML.

##### Listing 7.11. Using ConfigMap entries as arguments: fortune-pod-args-configmap.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: fortune-args-from-configmap
spec:
  containers:
  - image: luksa/fortune:args
    env:
    - name: INTERVAL
      valueFrom:
        configMapKeyRef:
          name: fortune-config
          key: sleep-interval
    args: ["$(INTERVAL)"]
...
```

You defined the environment variable exactly as you did before, but then you used the `$(ENV_VARIABLE_NAME)` syntax to have Kubernetes inject the value of the variable into the argument.

### 7.4.6. Using a configMap volume to expose ConfigMap entries as files

Passing configuration options as environment variables or command-line arguments is usually used for short variable values. A ConfigMap, as you’ve seen, can also contain whole config files. When you want to expose those to the container, you can use one of the special volume types I mentioned in the previous chapter, namely a `configMap` volume.

A `configMap` volume will expose each entry of the ConfigMap as a file. The process running in the container can obtain the entry’s value by reading the contents of the file.

Although this method is mostly meant for passing large config files to the container, nothing prevents you from passing short single values this way.

##### Creating the ConfigMap

Instead of modifying your fortuneloop.sh script once again, you’ll now try a different example. You’ll use a config file to configure the Nginx web server running inside the `fortune` pod’s web-server container. Let’s say you want your Nginx server to compress responses it sends to the client. To enable compression, the config file for Nginx needs to look like the following listing.

##### Listing 7.12. An Nginx config with enabled gzip compression: my-nginx-config.conf

```
server {
  listen              80;
  server_name         www.kubia-example.com;

  gzip on;                                       #1
  gzip_types text/plain application/xml;         #1

  location / {
    root   /usr/share/nginx/html;
    index  index.html index.htm;
  }
}
```

Now delete your existing `fortune-config` ConfigMap with `kubectl delete configmap fortune-config`, so that you can replace it with a new one, which will include the Nginx config file. You’ll create the ConfigMap from files stored on your local disk.

Create a new directory called configmap-files and store the Nginx config from the previous listing into configmap-files/my-nginx-config.conf. To make the ConfigMap also contain the `sleep-interval` entry, add a plain text file called sleep-interval to the same directory and store the number 25 in it (see [figure 7.8](/book/kubernetes-in-action/chapter-7/ch07fig08)).

![Figure 7.8. The contents of the configmap-files directory and its files](https://drek4537l1klr.cloudfront.net/luksa/Figures/07fig08.jpg)

Now create a ConfigMap from all the files in the directory like this:

```bash
$ kubectl create configmap fortune-config --from-file=configmap-files
configmap "fortune-config" created
```

The following listing shows what the YAML of this ConfigMap looks like.

##### Listing 7.13. YAML definition of a config map created from a file

```bash
$ kubectl get configmap fortune-config -o yaml
apiVersion: v1
data:
  my-nginx-config.conf: |                            #1
    server {                                         #1
      listen              80;                        #1
      server_name         www.kubia-example.com;     #1

      gzip on;                                       #1
      gzip_types text/plain application/xml;         #1

      location / {                                   #1
        root   /usr/share/nginx/html;                #1
        index  index.html index.htm;                 #1
      }                                              #1
    }                                                #1
  sleep-interval: |                                  #2
    25                                               #2
kind: ConfigMap
...
```

---

##### Note

The pipeline character after the colon in the first line of both entries signals that a literal multi-line value follows.

---

The ConfigMap contains two entries, with keys corresponding to the actual names of the files they were created from. You’ll now use the ConfigMap in both of your pod’s containers.

##### Using the ConfigMap’s entries in a volume

Creating a volume populated with the contents of a ConfigMap is as easy as creating a volume that references the ConfigMap by name and mounting the volume in a container. You already learned how to create volumes and mount them, so the only thing left to learn is how to initialize the volume with files created from a ConfigMap’s entries.

Nginx reads its config file from /etc/nginx/nginx.conf. The Nginx image already contains this file with default configuration options, which you don’t want to override, so you don’t want to replace this file as a whole. Luckily, the default config file automatically includes all .conf files in the /etc/nginx/conf.d/ subdirectory as well, so you should add your config file in there. [Figure 7.9](/book/kubernetes-in-action/chapter-7/ch07fig09) shows what you want to achieve.

![Figure 7.9. Passing ConfigMap entries to a pod as files in a volume](https://drek4537l1klr.cloudfront.net/luksa/Figures/07fig09_alt.jpg)

The pod descriptor is shown in [listing 7.14](/book/kubernetes-in-action/chapter-7/ch07ex14) (the irrelevant parts are omitted, but you’ll find the complete file in the code archive).

##### Listing 7.14. A pod with ConfigMap entries mounted as files: fortune-pod-configmap-volume.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: fortune-configmap-volume
spec:
  containers:
  - image: nginx:alpine
    name: web-server
    volumeMounts:
    ...
    - name: config
      mountPath: /etc/nginx/conf.d
      readOnly: true
    ...
  volumes:
  ...
  - name: config
    configMap:
      name: fortune-config
  ...
```

This pod definition includes a volume, which references your `fortune-config` Config-Map. You mount the volume into the /etc/nginx/conf.d directory to make Nginx use it.

##### Verifying Nginx is using the mounted config file

The web server should now be configured to compress the responses it sends. You can verify this by enabling port-forwarding from localhost:8080 to the pod’s port 80 and checking the server’s response with `curl`, as shown in the following listing.

##### Listing 7.15. Seeing if nginx responses have compression enabled

```bash
$ kubectl port-forward fortune-configmap-volume 8080:80 &
Forwarding from 127.0.0.1:8080 -> 80
Forwarding from [::1]:8080 -> 80
$ curl -H "Accept-Encoding: gzip" -I localhost:8080
HTTP/1.1 200 OK
Server: nginx/1.11.1
Date: Thu, 18 Aug 2016 11:52:57 GMT
Content-Type: text/html
Last-Modified: Thu, 18 Aug 2016 11:52:55 GMT
Connection: keep-alive
ETag: W/"57b5a197-37"
Content-Encoding: gzip                           #1
```

##### Examining the mounted configMap volume’s contents

The response shows you achieved what you wanted, but let’s look at what’s in the /etc/nginx/conf.d directory now:

```bash
$ kubectl exec fortune-configmap-volume -c web-server ls /etc/nginx/conf.d
my-nginx-config.conf
sleep-interval
```

Both entries from the ConfigMap have been added as files to the directory. The `sleep-interval` entry is also included, although it has no business being there, because it’s only meant to be used by the `fortuneloop` container. You could create two different ConfigMaps and use one to configure the `fortuneloop` container and the other one to configure the `web-server` container. But somehow it feels wrong to use multiple ConfigMaps to configure containers of the same pod. After all, having containers in the same pod implies that the containers are closely related and should probably also be configured as a unit.

##### Exposing certain ConfigMap entries in the volume

Luckily, you can populate a `configMap` volume with only part of the ConfigMap’s entries—in your case, only the `my-nginx-config.conf` entry. This won’t affect the `fortuneloop` container, because you’re passing the `sleep-interval` entry to it through an environment variable and not through the volume.

To define which entries should be exposed as files in a `configMap` volume, use the volume’s `items` attribute as shown in the following listing.

##### Listing 7.16. A pod with a specific ConfigMap entry mounted into a file directory: fortune-pod-configmap-volume-with-items.yaml

```
volumes:
  - name: config
    configMap:
      name: fortune-config
      items:                             #1
      - key: my-nginx-config.conf        #2
        path: gzip.conf                  #3
```

When specifying individual entries, you need to set the filename for each individual entry, along with the entry’s key. If you run the pod from the previous listing, the /etc/nginx/conf.d directory is kept nice and clean, because it only contains the gzip.conf file and nothing else.

##### Understanding that mounting a directory hides existing files in that directory

There’s one important thing to discuss at this point. In both this and in your previous example, you mounted the volume as a directory, which means you’ve hidden any files that are stored in the /etc/nginx/conf.d directory in the container image itself.

This is generally what happens in Linux when you mount a filesystem into a nonempty directory. The directory then only contains the files from the mounted filesystem, whereas the original files in that directory are inaccessible for as long as the filesystem is mounted.

In your case, this has no terrible side effects, but imagine mounting a volume to the /etc directory, which usually contains many important files. This would most likely break the whole container, because all of the original files that should be in the /etc directory would no longer be there. If you need to add a file to a directory like /etc, you can’t use this method at all.

##### Mounting individual ConfigMap entries as files without hiding oth- her files in the directory

Naturally, you’re now wondering how to add individual files from a ConfigMap into an existing directory without hiding existing files stored in it. An additional `subPath` property on the `volumeMount` allows you to mount either a single file or a single directory from the volume instead of mounting the whole volume. Perhaps this is easier to explain visually (see [figure 7.10](/book/kubernetes-in-action/chapter-7/ch07fig10)).

![Figure 7.10. Mounting a single file from a volume](https://drek4537l1klr.cloudfront.net/luksa/Figures/07fig10_alt.jpg)

Say you have a `configMap` volume containing a myconfig.conf file, which you want to add to the /etc directory as someconfig.conf. You can use the `subPath` property to mount it there without affecting any other files in that directory. The relevant part of the pod definition is shown in the following listing.

##### Listing 7.17. A pod with a specific config map entry mounted into a specific file

```
spec:
  containers:
  - image: some/image
    volumeMounts:
    - name: myvolume
      mountPath: /etc/someconfig.conf      #1
      subPath: myconfig.conf               #2
```

The `subPath` property can be used when mounting any kind of volume. Instead of mounting the whole volume, you can mount part of it. But this method of mounting individual files has a relatively big deficiency related to updating files. You’ll learn more about this in the following section, but first, let’s finish talking about the initial state of a `configMap` volume by saying a few words about file permissions.

##### Setting the file permissions for files in a configMap volume

By default, the permissions on all files in a `configMap` volume are set to 644 (`-rw-r—r--`). You can change this by setting the `defaultMode` property in the volume spec, as shown in the following listing.

##### Listing 7.18. Setting file permissions: fortune-pod-configmap-volume-defaultMode.yaml

```
volumes:
  - name: config
    configMap:
      name: fortune-config
      defaultMode: "6600"           #1
```

Although ConfigMaps should be used for non-sensitive configuration data, you may want to make the file readable and writable only to the user and group the file is owned by, as the example in the previous listing shows.

### 7.4.7. Updating an app’s config without having to restart the app

We’ve said that one of the drawbacks of using environment variables or command-line arguments as a configuration source is the inability to update them while the process is running. Using a ConfigMap and exposing it through a volume brings the ability to update the configuration without having to recreate the pod or even restart the container.

When you update a ConfigMap, the files in all the volumes referencing it are updated. It’s then up to the process to detect that they’ve been changed and reload them. But Kubernetes will most likely eventually also support sending a signal to the container after updating the files.

---

##### Warning

Be aware that as I’m writing this, it takes a surprisingly long time for the files to be updated after you update the ConfigMap (it can take up to one whole minute).

---

##### Editing a ConfigMap

Let’s see how you can change a ConfigMap and have the process running in the pod reload the files exposed in the `configMap` volume. You’ll modify the Nginx config file from your previous example and make Nginx use the new config without restarting the pod. Try switching gzip compression off by editing the `fortune-config` ConfigMap with `kubectl edit`:

```bash
$ kubectl edit configmap fortune-config
```

Once your editor opens, change the `gzip on` line to `gzip off`, save the file, and then close the editor. The ConfigMap is then updated, and soon afterward, the actual file in the volume is updated as well. You can confirm this by printing the contents of the file with `kubectl exec`:

```bash
$ kubectl exec fortune-configmap-volume -c web-server
➥   cat /etc/nginx/conf.d/my-nginx-config.conf
```

If you don’t see the update yet, wait a while and try again. It takes a while for the files to get updated. Eventually, you’ll see the change in the config file, but you’ll find this has no effect on Nginx, because it doesn’t watch the files and reload them automatically.

##### Signaling Nginx to reload the config

Nginx will continue to compress its responses until you tell it to reload its config files, which you can do with the following command:

```bash
$ kubectl exec fortune-configmap-volume -c web-server -- nginx -s reload
```

Now, if you try hitting the server again with `curl`, you should see the response is no longer compressed (it no longer contains the `Content-Encoding: gzip` header). You’ve effectively changed the app’s config without having to restart the container or recreate the pod.

##### Understanding how the files are updated atomically

You may wonder what happens if an app can detect config file changes on its own and reloads them before Kubernetes has finished updating all the files in the `configMap` volume. Luckily, this can’t happen, because all the files are updated atomically, which means all updates occur at once. Kubernetes achieves this by using symbolic links. If you list all the files in the mounted `configMap` volume, you’ll see something like the following listing.

##### Listing 7.19. Files in a mounted `configMap` volume

```bash
$ kubectl exec -it fortune-configmap-volume -c web-server -- ls -lA
➥   /etc/nginx/conf.d
total 4
drwxr-xr-x  ... 12:15 ..4984_09_04_12_15_06.865837643
lrwxrwxrwx  ... 12:15 ..data -> ..4984_09_04_12_15_06.865837643
lrwxrwxrwx  ... 12:15 my-nginx-config.conf -> ..data/my-nginx-config.conf
lrwxrwxrwx  ... 12:15 sleep-interval -> ..data/sleep-interval
```

As you can see, the files in the mounted `configMap` volume are symbolic links pointing to files in the `..data` dir. The `..data` dir is also a symbolic link pointing to a directory called `..4984_09_04_something`. When the ConfigMap is updated, Kubernetes creates a new directory like this, writes all the files to it, and then re-links the `..data` symbolic link to the new directory, effectively changing all files at once.

##### Understanding that files mounted into existing directories don’t get updated

One big caveat relates to updating ConfigMap-backed volumes. If you’ve mounted a single file in the container instead of the whole volume, the file will not be updated! At least, this is true at the time of writing this chapter.

For now, if you need to add an individual file and have it updated when you update its source ConfigMap, one workaround is to mount the whole volume into a different directory and then create a symbolic link pointing to the file in question. The symlink can either be created in the container image itself, or you could create the symlink when the container starts.

##### Understanding the consequences of updating a ConfigMap

One of the most important features of containers is their immutability, which allows us to be certain that no differences exist between multiple running containers created from the same image, so is it wrong to bypass this immutability by modifying a ConfigMap used by running containers?

The main problem occurs when the app doesn’t support reloading its configuration. This results in different running instances being configured differently—those pods that are created after the ConfigMap is changed will use the new config, whereas the old pods will still use the old one. And this isn’t limited to new pods. If a pod’s container is restarted (for whatever reason), the new process will also see the new config. Therefore, if the app doesn’t reload its config automatically, modifying an existing ConfigMap (while pods are using it) may not be a good idea.

If the app does support reloading, modifying the ConfigMap usually isn’t such a big deal, but you do need to be aware that because files in the ConfigMap volumes aren’t updated synchronously across all running instances, the files in individual pods may be out of sync for up to a whole minute.

## 7.5. Using Secrets to pass sensitive data to containers

All the information you’ve passed to your containers so far is regular, non-sensitive configuration data that doesn’t need to be kept secure. But as we mentioned at the start of the chapter, the config usually also includes sensitive information, such as credentials and private encryption keys, which need to be kept secure.

### 7.5.1. Introducing Secrets

To store and distribute such information, Kubernetes provides a separate object called a Secret. Secrets are much like ConfigMaps—they’re also maps that hold key-value pairs. They can be used the same way as a ConfigMap. You can

- Pass Secret entries to the container as environment variables
- Expose Secret entries as files in a volume

Kubernetes helps keep your Secrets safe by making sure each Secret is only distributed to the nodes that run the pods that need access to the Secret. Also, on the nodes themselves, Secrets are always stored in memory and never written to physical storage, which would require wiping the disks after deleting the Secrets from them.

On the master node itself (more specifically in etcd), Secrets used to be stored in unencrypted form, which meant the master node needs to be secured to keep the sensitive data stored in Secrets secure. This didn’t only include keeping the etcd storage secure, but also preventing unauthorized users from using the API server, because anyone who can create pods can mount the Secret into the pod and gain access to the sensitive data through it. From Kubernetes version 1.7, etcd stores Secrets in encrypted form, making the system much more secure. Because of this, it’s imperative you properly choose when to use a Secret or a ConfigMap. Choosing between them is simple:

- Use a ConfigMap to store non-sensitive, plain configuration data.
- Use a Secret to store any data that is sensitive in nature and needs to be kept under key. If a config file includes both sensitive and not-sensitive data, you should store the file in a Secret.

You already used Secrets in [chapter 5](/book/kubernetes-in-action/chapter-5/ch05), when you created a Secret to hold the TLS certificate needed for the Ingress resource. Now you’ll explore Secrets in more detail.

### 7.5.2. Introducing the default token Secret

You’ll start learning about Secrets by examining a Secret that’s mounted into every container you run. You may have noticed it when using `kubectl describe` on a pod. The command’s output has always contained something like this:

```
Volumes:
  default-token-cfee9:
    Type:       Secret (a volume populated by a Secret)
    SecretName: default-token-cfee9
```

Every pod has a `secret` volume attached to it automatically. The volume in the previous `kubectl describe` output refers to a Secret called `default-token-cfee9`. Because Secrets are resources, you can list them with `kubectl get secrets` and find the `default-token` Secret in that list. Let’s see:

```bash
$ kubectl get secrets
NAME                  TYPE                                  DATA      AGE
default-token-cfee9   kubernetes.io/service-account-token   3         39d
```

You can also use `kubectl describe` to learn a bit more about it, as shown in the following listing.

##### Listing 7.20. Describing a Secret

```bash
$ kubectl describe secrets
Name:        default-token-cfee9
Namespace:   default
Labels:      <none>
Annotations: kubernetes.io/service-account.name=default
             kubernetes.io/service-account.uid=cc04bb39-b53f-42010af00237
Type:        kubernetes.io/service-account-token

Data
====
ca.crt:      1139 bytes                                   #1
namespace:   7 bytes                                      #1
token:       eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...      #1
```

You can see that the Secret contains three entries—`ca.crt`, `namespace`, and `token`—which represent everything you need to securely talk to the Kubernetes API server from within your pods, should you need to do that. Although ideally you want your application to be completely Kubernetes-agnostic, when there’s no alternative other than to talk to Kubernetes directly, you’ll use the files provided through this `secret` volume.

The `kubectl describe pod` command shows where the `secret` volume is mounted:

```
Mounts:
  /var/run/secrets/kubernetes.io/serviceaccount from default-token-cfee9
```

---

##### Note

By default, the `default-token` Secret is mounted into every container, but you can disable that in each pod by setting the `automountService-AccountToken` field in the pod spec to `false` or by setting it to `false` on the service account the pod is using. (You’ll learn about service accounts later in the book.)

---

To help you visualize where and how the default token Secret is mounted, see [figure 7.11](/book/kubernetes-in-action/chapter-7/ch07fig11).

![Figure 7.11. The default-token Secret is created automatically and a corresponding volume is mounted in each pod automatically.](https://drek4537l1klr.cloudfront.net/luksa/Figures/07fig11_alt.jpg)

We’ve said Secrets are like ConfigMaps, so because this Secret contains three entries, you can expect to see three files in the directory the `secret` volume is mounted into. You can check this easily with `kubectl exec`:

```bash
$ kubectl exec mypod ls /var/run/secrets/kubernetes.io/serviceaccount/
ca.crt
namespace
token
```

You’ll see how your app can use these files to access the API server in the next chapter.

### 7.5.3. Creating a Secret

Now, you’ll create your own little Secret. You’ll improve your fortune-serving Nginx container by configuring it to also serve HTTPS traffic. For this, you need to create a certificate and a private key. The private key needs to be kept secure, so you’ll put it and the certificate into a Secret.

First, generate the certificate and private key files (do this on your local machine). You can also use the files in the book’s code archive (the cert and key files are in the `fortune-https` directory):

```bash
$ openssl genrsa -out https.key 2048
$ openssl req -new -x509 -key https.key -out https.cert -days 3650 -subj
     /CN=www.kubia-example.com
```

Now, to help better demonstrate a few things about Secrets, create an additional dummy file called foo and make it contain the string `bar`. You’ll understand why you need to do this in a moment or two:

```bash
$ echo bar > foo
```

Now you can use `kubectl create secret` to create a Secret from the three files:

```bash
$ kubectl create secret generic fortune-https --from-file=https.key
➥   --from-file=https.cert --from-file=foo
secret "fortune-https" created
```

This isn’t very different from creating ConfigMaps. In this case, you’re creating a `generic` Secret called `fortune-https` and including two entries in it (https.key with the contents of the https.key file and likewise for the https.cert key/file). As you learned earlier, you could also include the whole directory with `--from-file=fortune-https` instead of specifying each file individually.

---

##### Note

You’re creating a generic Secret, but you could also have created a `tls` Secret with the `kubectl create secret tls` command, as you did in [chapter 5](../Text/05.html#ch05). This would create the Secret with different entry names, though.

---

### 7.5.4. Comparing ConfigMaps and Secrets

Secrets and ConfigMaps have a pretty big difference. This is what drove Kubernetes developers to create ConfigMaps after Kubernetes had already supported Secrets for a while. The following listing shows the YAML of the Secret you created.

##### Listing 7.21. A Secret’s YAML definition

```bash
$ kubectl get secret fortune-https -o yaml
apiVersion: v1
data:
  foo: YmFyCg==
  https.cert: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCekNDQ...
  https.key: LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFcE...
kind: Secret
...
```

Now compare this to the YAML of the ConfigMap you created earlier, which is shown in the following listing.

##### Listing 7.22. A ConfigMap’s YAML definition

```bash
$ kubectl get configmap fortune-config -o yaml
apiVersion: v1
data:
  my-nginx-config.conf: |
    server {
      ...
    }
  sleep-interval: |
    25
kind: ConfigMap
...
```

Notice the difference? The contents of a Secret’s entries are shown as Base64-encoded strings, whereas those of a ConfigMap are shown in clear text. This initially made working with Secrets in YAML and JSON manifests a bit more painful, because you had to encode and decode them when setting and reading their entries.

##### Using Secrets for binary data

The reason for using Base64 encoding is simple. A Secret’s entries can contain binary values, not only plain-text. Base64 encoding allows you to include the binary data in YAML or JSON, which are both plain-text formats.

---

##### Tip

You can use Secrets even for non-sensitive binary data, but be aware that the maximum size of a Secret is limited to 1MB.

---

##### Introducing the stringData field

Because not all sensitive data is in binary form, Kubernetes also allows setting a Secret’s values through the `stringData` field. The following listing shows how it’s used.

##### Listing 7.23. Adding plain text entries to a `Secret` using the `stringData` field

```yaml
kind: Secret
apiVersion: v1
stringData:
  foo: plain text
data:
  https.cert: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCekNDQ...
  https.key: LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFcE...
```

The `stringData` field is write-only (note: write-only, not read-only). It can only be used to set values. When you retrieve the Secret’s YAML with `kubectl get -o yaml`, the `stringData` field will not be shown. Instead, all entries you specified in the `stringData` field (such as the `foo` entry in the previous example) will be shown under `data` and will be Base64-encoded like all the other entries.

##### Reading a Secret’s entry in a pod

When you expose the Secret to a container through a `secret` volume, the value of the Secret entry is decoded and written to the file in its actual form (regardless if it’s plain text or binary). The same is also true when exposing the Secret entry through an environment variable. In both cases, the app doesn’t need to decode it, but can read the file’s contents or look up the environment variable value and use it directly.

### 7.5.5. Using the Secret in a pod

With your fortune-https Secret containing both the cert and key files, all you need to do now is configure Nginx to use them.

##### Modifying the fortune-config ConfigMap to enable HTTPS

For this, you need to modify the config file again by editing the ConfigMap:

```bash
$ kubectl edit configmap fortune-config
```

After the text editor opens, modify the part that defines the contents of the `my-nginx-config.conf` entry so it looks like the following listing.

##### Listing 7.24. Modifying the `fortune-config` ConfigMap’s data

```
...
data:
  my-nginx-config.conf: |
    server {
      listen              80;
      listen              443 ssl;
      server_name         www.kubia-example.com;
      ssl_certificate     certs/https.cert;           #1
      ssl_certificate_key certs/https.key;            #1
      ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;
      ssl_ciphers         HIGH:!aNULL:!MD5;

      location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
      }
    }
  sleep-interval: |
...
```

This configures the server to read the certificate and key files from /etc/nginx/certs, so you’ll need to mount the `secret` volume there.

##### Mounting the fortune-https Secret in a pod

Next, you’ll create a new fortune-https pod and mount the `secret` volume holding the certificate and key into the proper location in the `web-server` container, as shown in the following listing.

##### Listing 7.25. YAML definition of the `fortune-https` pod: fortune-pod-https.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: fortune-https
spec:
  containers:
  - image: luksa/fortune:env
    name: html-generator
    env:
    - name: INTERVAL
      valueFrom:
        configMapKeyRef:
          name: fortune-config
          key: sleep-interval
    volumeMounts:
    - name: html
      mountPath: /var/htdocs
  - image: nginx:alpine
    name: web-server
    volumeMounts:
    - name: html
      mountPath: /usr/share/nginx/html
      readOnly: true
    - name: config
      mountPath: /etc/nginx/conf.d
      readOnly: true
    - name: certs
      mountPath: /etc/nginx/certs/
      readOnly: true
    ports:
    - containerPort: 80
    - containerPort: 443
  volumes:
  - name: html
    emptyDir: {}
  - name: config
    configMap:
      name: fortune-config
      items:
      - key: my-nginx-config.conf
        path: https.conf
  - name: certs
    secret:
      secretName: fortune-https
```

Much is going on in this pod descriptor, so let me help you visualize it. [Figure 7.12](/book/kubernetes-in-action/chapter-7/ch07fig12) shows the components defined in the YAML. The `default-token` Secret, volume, and volume mount, which aren’t part of the YAML, but are added to your pod automatically, aren’t shown in the figure.

![Figure 7.12. Combining a ConfigMap and a Secret to run your fortune-https pod](https://drek4537l1klr.cloudfront.net/luksa/Figures/07fig12_alt.jpg)

---

##### Note

Like `configMap` volumes, `secret` volumes also support specifying file permissions for the files exposed in the volume through the `defaultMode` property.

---

##### Testing whether Nginx is using the cert and key from the Secret

Once the pod is running, you can see if it’s serving HTTPS traffic by opening a port-forward tunnel to the pod’s port 443 and using it to send a request to the server with `curl`:

```bash
$ kubectl port-forward fortune-https 8443:443 &
Forwarding from 127.0.0.1:8443 -> 443
Forwarding from [::1]:8443 -> 443
$ curl https://localhost:8443 -k
```

If you configured the server properly, you should get a response. You can check the server’s certificate to see if it matches the one you generated earlier. This can also be done with `curl` by turning on verbose logging using the `-v` option, as shown in the following listing.

##### Listing 7.26. Displaying the server certificate sent by Nginx

```bash
$ curl https://localhost:8443 -k -v
* About to connect() to localhost port 8443 (#0)
*   Trying ::1...
* Connected to localhost (::1) port 8443 (#0)
* Initializing NSS with certpath: sql:/etc/pki/nssdb
* skipping SSL peer certificate verification
* SSL connection using TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
* Server certificate:
*   subject: CN=www.kubia-example.com          #1
*   start date: aug 16 18:43:13 2016 GMT       #1
*   expire date: aug 14 18:43:13 2026 GMT      #1
*   common name: www.kubia-example.com         #1
*   issuer: CN=www.kubia-example.com           #1
```

##### Understanding secret volumes are stored in memory

You successfully delivered your certificate and private key to your container by mounting a `secret` volume in its directory tree at /etc/nginx/certs. The `secret` volume uses an in-memory filesystem (tmpfs) for the Secret files. You can see this if you list mounts in the container:

```bash
$ kubectl exec fortune-https -c web-server -- mount | grep certs
tmpfs on /etc/nginx/certs type tmpfs (ro,relatime)
```

Because tmpfs is used, the sensitive data stored in the Secret is never written to disk, where it could be compromised.

##### Exposing a Secret’s entries through environment variables

Instead of using a volume, you could also have exposed individual entries from the `secret` as environment variables, the way you did with the `sleep-interval` entry from the ConfigMap. For example, if you wanted to expose the `foo` key from your Secret as environment variable `FOO_SECRET`, you’d add the snippet from the following listing to the container definition.

##### Listing 7.27. Exposing a Secret’s entry as an environment variable

```
env:
    - name: FOO_SECRET
      valueFrom:                   #1
        secretKeyRef:              #1
          name: fortune-https      #2
          key: foo                 #3
```

This is almost exactly like when you set the INTERVAL environment variable, except that this time you’re referring to a Secret by using `secretKeyRef` instead of `configMapKeyRef`, which is used to refer to a ConfigMap.

Even though Kubernetes enables you to expose Secrets through environment variables, it may not be the best idea to use this feature. Applications usually dump environment variables in error reports or even write them to the application log at startup, which may unintentionally expose them. Additionally, child processes inherit all the environment variables of the parent process, so if your app runs a third-party binary, you have no way of knowing what happens with your secret data.

---

##### Tip

Think twice before using environment variables to pass your Secrets to your container, because they may get exposed inadvertently. To be safe, always use `secret` volumes for exposing Secrets.

---

### 7.5.6. Understanding image pull Secrets

You’ve learned how to pass Secrets to your applications and use the data they contain. But sometimes Kubernetes itself requires you to pass credentials to it—for example, when you’d like to use images from a private container image registry. This is also done through Secrets.

Up to now all your container images have been stored on public image registries, which don’t require any special credentials to pull images from them. But most organizations don’t want their images to be available to everyone and thus use a private image registry. When deploying a pod, whose container images reside in a private registry, Kubernetes needs to know the credentials required to pull the image. Let’s see how to do that.

##### Using a private image repository on Docker Hub

Docker Hub, in addition to public image repositories, also allows you to create private repositories. You can mark a repository as private by logging in at [http://hub.docker.com](http://hub.docker.com) with your web browser, finding the repository and checking a checkbox.

To run a pod, which uses an image from the private repository, you need to do two things:

- Create a Secret holding the credentials for the Docker registry.
- Reference that Secret in the `imagePullSecrets` field of the pod manifest.

##### Creating a Secret for authenticating with a Docker registry

Creating a Secret holding the credentials for authenticating with a Docker registry isn’t that different from creating the generic Secret you created in [section 7.5.3](/book/kubernetes-in-action/chapter-7/ch07lev2sec16). You use the same `kubectl create secret` command, but with a different type and options:

```bash
$ kubectl create secret docker-registry mydockerhubsecret \
  --docker-username=myusername --docker-password=mypassword \
  --docker-email=my.email@provider.com
```

Rather than create a `generic` secret, you’re creating a `docker-registry` Secret called `mydockerhubsecret`. You’re specifying your Docker Hub username, password, and email. If you inspect the contents of the newly created Secret with `kubectl describe`, you’ll see that it includes a single entry called `.dockercfg`. This is equivalent to the .dockercfg file in your home directory, which is created by Docker when you run the `docker login` command.

##### Using the docker-registry Secret in a pod definition

To have Kubernetes use the Secret when pulling images from your private Docker Hub repository, all you need to do is specify the Secret’s name in the pod spec, as shown in the following listing.

##### Listing 7.28. A pod definition using an image pull Secret: pod-with-private-image.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: private-pod
spec:
  imagePullSecrets:
  - name: mydockerhubsecret
  containers:
  - image: username/private:tag
    name: main
```

In the pod definition in the previous listing, you’re specifying the `mydockerhubsecret` Secret as one of the `imagePullSecrets`. I suggest you try this out yourself, because it’s likely you’ll deal with private container images soon.

##### Not having to specify image pull Secrets on every pod

Given that people usually run many different pods in their systems, it makes you wonder if you need to add the same image pull Secrets to every pod. Luckily, that’s not the case. In [chapter 12](/book/kubernetes-in-action/chapter-12/ch12) you’ll learn how image pull Secrets can be added to all your pods automatically if you add the Secrets to a ServiceAccount.

## 7.6. Summary

This wraps up this chapter on how to pass configuration data to containers. You’ve learned how to

- Override the default command defined in a container image in the pod definition
- Pass command-line arguments to the main container process
- Set environment variables for a container
- Decouple configuration from a pod specification and put it into a ConfigMap
- Store sensitive data in a Secret and deliver it securely to containers
- Create a `docker-registry` Secret and use it to pull images from a private image registry

In the next chapter, you’ll learn how to pass pod and container metadata to applications running inside them. You’ll also see how the default token Secret, which we learned about in this chapter, is used to talk to the API server from within a pod.
