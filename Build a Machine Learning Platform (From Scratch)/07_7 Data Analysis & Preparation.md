# 7 Data Analysis & Preparation

### This chapter covers

- Introducing the Captone Projects
- Building and launching images for Kubeflow notebooks
- Using Kubeflow notebooks for data analysis
- Data passing in Kubeflow Pipelines
- Writing Kubeflow components that pass data
- Developing the Data Preparation pipeline for Object Detection, including downloading the dataset and splitting it into train, validation, and test

This chapter kicks off with two capstone projects: one centered on detecting identity cards and the other on recommending movies. As we progress, upcoming chapters will explore different stages of the ML pipeline—model training, evaluation, and serving. Our focus on practical application means that we'll heavily integrate these concepts into a tangible project within the pipeline. Through concrete real-world implementations, our aim is to solidify the relevance and understanding of these discussed concepts within our ongoing project.

#### Capstone Project 1: Identity Card Detection

The landscape of Machine Learning is ever-evolving, with new developments surfacing every other week. During the era when Deep Learning took center stage, innovations like new versions of YOLO (You Only Look Once) and ResNet became the talk of the town.

Both YOLO and ResNet are deep convolutional networks (CNNs). YOLO is an object detection algorithm that can detect and classify objects in images in real-time while ResNet (also a CNN) can be used to train very deep networks using skip connections, which enables the network to pick up intricate details at very high accuracy. Nowadays (at least at this time of writing), Large Language Models (LLMs) have taken center stage.

While there are constantly new architectures and techniques that capture the limelight, the success of these techniques often lie with arguably the least sexy but the most important part of Machine Learning: Data Preparation. "Garbage in, garbage out" isn't just a line that grumpy ML engineers mutter. Rather, it captures the fundamental truth that the quality and integrity of your input data ultimately shapes the reliability and efficacy of your machine learning model and their results.

This first project will use Kubeflow to detect identification cards. This project will take you through building an object detection pipeline with Kubeflow, and understanding that the success of machine learning techniques hinges greatly on data preparation, the focus of this chapter.

#### Capstone Project 2: Movie Recommendations

The second project builds a movie recommendation system with the MovieLens dataset, which we'll introduce later in the chapter. This chapter will focus on the data preparation part of the project as in the object detection project and introduce some concepts specific to tabular data handling. We will build 6 components and combine them into a data preparation pipeline.

Chapters 1 through 5 have led to this point, and this chapter is when we start to apply what you've learnt and at the same time pick up some new things along the way! We'll assume that you'll have a working Kubeflow setup, along with a powerful enough machine to execute the pipelines.

## 7.1 Data analysis

Data analysis presents some unique constraints on ML workflows and infrastructure. On the one hand, we need the analysis and experimentation systems to run as close to the datasets as possible so that even massive datasets can be processed.

On the other hand, we also need ad-hoc interactive access to expensive compute resources like GPUs and machines with large resources that can be spun up and down depending on a user’s requirement. For example, you might want to spin up a Jupyter notebook to inspect the results of an object detection model for your training dataset, even possibly loading up the model in the notebook and performing some ad-hoc inference.

Finally, it is also highly preferred to conduct experiments in an environment that closely mimics the deployment environment while also enabling robust versioning and CI/CD practices.

At first glance, this laundry list of requirements seems like it needs an entire team to manage. In conventional workflows this might be true, and even if it was possible, we might need bespoke engineering and maintenance.

Enter Kubeflow notebooks.

Kubeflow notebooks aim to solve all of the problems above while providing developers with the familiar interface of jupyter notebooks, VS code or R studio in a web browser. They run natively on the same kubeflow cluster as our pipelines and, as we will see later, can use the same base image as our pipelines, ensuring that the environment is as close as possible to the deployment environment. We will also build our notebook images as part of the same CI pipeline as we use to build our pipeline and deployment containers, further cementing robust version controls.

The game plan here is to first dive into a sample kubeflow notebook and explore. We will walk through launching a simple notebook, understand how notebooks are configured under the hood and change some defaults. Finally, we get into what makes an image compatible with kubeflow notebooks and how to add layers to a base image to run it as a notebook.

### 7.1.1 Launching a notebook server in Kubeflow

In the kubeflow UI, navigate to the notebooks section and click on create a new notebook (Fig 7.1.). Pay attention to the namespace you use when creating a notebook as this often limits things like volume mounts.

![Figure 7.1 Click on new notebook to launch a Kubeflow notebook](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/07__image001.png)

The image section is where you choose the image to spin up on the cluster. For now, we will pick a sample image, but we will revisit this menu later to customize it and add custom images. The resource menus behave exactly like limits and requests in Kubernetes, so be careful of setting memory limits too low, especially when testing.

Next, if the cluster has GPU or accelerator (such as TPU, or Tensor Processing Unit) resources, choose the required number. Note, these resources are usually expensive, and notebooks block other pods from occupying the same resources unless overprovisioning is somehow enabled. If you want to make these resources available to notebooks, make sure that the notebooks have lifecycle rules that stop the pods when not in use. We will also talk about this later.

![Figure 7.2 Image configuration options for name, namespace, image and resources](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/07__image003.png)

### 7.1.2 Workspace and data volumes

When creating a notebook, kubeflow automatically mounts the workspace volume under /home/jovyan (we will discuss changing this later). This provides a persistent store for storing things like environments or config files. You can also optionally mount data volumes which are Persistent Volumes (PV) on the cluster.

Workspace volumes are usually created according to the default storage class of the cluster at startup whereas data volumes are usually pre-existing Persistent Volume Claims, or PVCs, that are mounted at runtime.

In case you're not familiar with a PVC: It is a request for storage resources made by a containerized application running on a Kubernetes cluster. It allows the application to access and use storage volumes that are dynamically provisioned and managed by the underlying infrastructure.

The exception to this is when a pre-existing workspace volume is selected (as is the case when you want to change the running container but persist workspace data).

![Figure 7.3 Configuration options for adding a workspace and data volumes to the notebook](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/07__image005.png)

### 7.1.3 Configurations and affinity / tolerations

Configurations refer to PodDefaults that are present in the namespace. For example, assume we have a podDefault as below to inject some environment variables at runtime into a pod. Note the environment variables under the keyword `env`. Pod defaults store environment variables as explicit name-value pairs.

##### Listing 7.1 Pod Default Example

```yaml
apiVersion: kubeflow.org/v1alpha1
kind: PodDefault
metadata:
  annotations:
  name: add-proxy-vars
  namespace: contiflow
spec:
  desc: add proxy variables
  env:
    - name: http_proxy
      value: http://192.168.1.1:3128
    - name: https_proxy
      value: http://192.168.1.1:3128
    - name: no_proxy
      value: >-
     .svc,.local,127.0.0.0/8,localhost,.conti.de,192.168.1.1,192.168.1.2,192.168.1.3,10.0.0.0/8
    - name: MLFLOW_TRACKING_URI
      value: http://mlflow.kubeflow.svc.cluster.local:5000
  selector:
    matchLabels:
      add-proxy-vars: 'true'
```

We can see that the PodDefault resource is named `add-proxy-vars` which as we see later can also be added to the UI config so that it shows up for the user to pick. If selected while launching the notebook, the `podDefaults` are automatically applied and in our case, it will auto-inject the env vars `MLFLOW_TRACKING_URI`. This particular environment variable is quite special as we will see in later chapters. You can extend this to authentication credentials, special setup or even mounting certain volumes.This is often an easier way to let users pick volume mounts because the paths and PVC names can be easily controlled on the cluster level.

Affinity and tolerations operate similarly to their counterparts in Kubernetes. Affinity selectors attract a pod to nodes with corresponding affinity annotations, while tolerations allow a pod to be assigned to nodes with specific taints, actively pushing away pods lacking the necessary toleration definition. The most common use case of affinity and tolerations is to control access to nodes that have special resources on them like GPUs.

Enable or disable shared memory according to your needs (specific AI frameworks and methods like distributed training or memory cached data loaders benefit from shared memory) and hit launch to schedule the pod on a node. If you watch the kubernetes cluster while the notebook is being scheduled, you will notice the workspace drive being provisioned, the affinity and tolerations working to schedule the pod on a node, and the node pulling the image. If you look closely, you can also see an istio-sidecar container in the pod alongwith the main container and an init container. Kubeflow abstracts away most of the networking for the notebook so that the user can get experimenting without worrying about it.

On the cluster, try listing the CRDs under kubeflow.org:

```bash
kubectl get crd -o=name | grep kubeflow.org
```

You should see a Notebook resource and our newly created notebook as a resource there:

```
customresourcedefinition.apiextensions.k8s.io/notebooks.kubeflow.org
```

This is where you should edit if any change is required after launching a notebook server. Be warned though: a change triggers a re-deployment, causing all non persistent data to be removed when the container restarts.

![Figure 7.4 Affinity and tolerations group configurations](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/07__image007.png)

### 7.1.4 Customizing the menu

As a cluster admin, you may perhaps want to change the options presented to the users of kubeflow notebooks. A common use case is to customize the list of images presented to the user so as to have reproducible environments that are similar to the deployment environment. To change default values, customize options and add new images to the list of available images in the menu for notebooks, we need to edit a configmap. This configmap is used by the notebook controller to present options to the user and is located in the kubeflow namespace and usually starts with `jupyter-web-app-config`. You can use:

```bash
kubectl get cm -n kubeflow | grep jupyter-web-app-config
```

to find out the exact name of the configmap.

Taking a look inside, we notice that each option is configured with a default value key and a readOnly tag that makes an option non-editable by the user launching the notebook. Let's talk about some interesting options here.

#### Customizing images shown to the user

If you were to edit the aforementioned `jupyter-web-app-config`, this is a snippet of what you'll see:

##### Listing 7.2 Jupyter Web App configmap

```yaml
apiVersion: v1
data:
  spawner_ui_config.yaml: >
    spawnerFormDefaults:
      image:
        # The container Image for the user's Jupyter Notebook
        value: kubeflownotebookswg/jupyter-scipy:v1.6.1
        # The list of available standard container Images
        options:
            - asia.gcr.io/kubeflow-notebook-servers/jupyter-tensorflow:2.6.0
            - asia.gcr.io/kubeflow-notebook-servers/jupyter-pytorch:1.9.0
      imageGroupOne:
        - kubeflownotebookswg/codeserver-python:v1.6.1
      imageGroupTwo:
        - kubeflownotebookswg/rstudio-tidyverse:v1.6.1
```

The very first field in `spawnerFormDefaults` concerns the images to be used. The images are grouped and the first set of entries under image configures the jupyter option. Image group one and two refer to the codeserver and R studio options respectively. Under each group, the value field denotes the default option and the options field lists the options presented in the drop down menu for a user. This gives us an easy but quite powerful way to integrate the images listed with an automatic CD pipeline by adding or deleting images listed here as part of a deployment workflow. Below the image groups, additional options exist that can for example, make the image field in the UI non-editable, thereby limiting users to only the images listed.

#### Affinity and tolerations groups

As discussed above, affinity and tolerations work together to locate a pod on specific nodes of a cluster. For the purposes of discussion here, we will talk about affinity configs, but tolerations are similar and work with node taints.

For kubeflow notebooks, affinity configs work the same way as you would define affinity for a normal pod in kubernetes. As in other config settings, this option can be made read-only with a default config to limit where users can launch notebooks. To make the behavior a bit more dynamic, we can display a list of options to the user. Let's take for example the case where some nodes in our cluster have a more powerful CPU than others. To help the user choose the best node for their workflow, we can set two affinity configs called `small-cpu` and `xl-cpu`. The specific nodes in our example will have corresponding labels.

##### Listing 7.3 Node affinity configmap

```
affinityConfig:
    value: ""
    options:
      - configKey: "small-cpu-selector"
        displayName: "small-cpu-node"
        affinity:
          nodeAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
              nodeSelectorTerms:
                - matchExpressions:
                    - key: "compute"
                      operator: "In"
                      values:
                       - "small"
      - configKey: "xl-cpu-selector"
        displayName: "xl-cpu-node"
        affinity:
          nodeAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
              nodeSelectorTerms:
                - matchExpressions:
                    - key: "compute"
                      operator: "In"
                      values:
                       - "xl"
```

With this config, the user will now be presented with two options for the cpu selection. Combining this with the default value means that we can configure notebook pods to be scheduled by default to the nodes with smaller CPUs and reserve the more powerful CPUs for notebooks that need them. Setting them as affinity configs means that if the nodes with less powerful CPUs are full, the powerful nodes can still accept pods. If you need to restrict access to the nodes with powerful CPUs, combine affinity configs with node taints and toleration configs.

### 7.1.5 Creating a custom Kubeflow notebook image

Now that we have an idea about customizing the interface, the next question is how to run a custom image in a kubeflow notebook. To understand the process, it's best to understand what goes into making a custom kubeflow notebook and what layers are required.

![Figure 7.5 Overview of the layers in a custom Kubeflow notebook image.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/07__image009.png)

At its core, a custom image is a set of dependencies for the codeserver / jupyter runtimes, the runtimes themselves and configuration files to launch the notebook server to enable compatibility with kubeflow. A multistage docker file is provided in the project repository that takes in a base image as argument and can build out a codeserver or jupyter image. Please note, when deploying this to your organization, remember to take a look at the Dockerfile and make changes to optimize the image size.

Kubeflow notebooks are probably the most familiar interface for a data scientist or ML engineer coming from a local development workflow and therefore provides an easy path to transition teams to Kubeflow and a modern ML workflow. Combining a custom image with the flexibility offered by Kubeflow to launch notebooks and run experiments, offers a seamless experience for the user in a modern Git based workflow.

Now that we have gone into the details of notebooks, let's look at the next important tool we have to enable experiments, structured ETL and most importantly build repeatable, reproducible and observable ML workflows, Kubeflow Pipelines.

## 7.2 Data Passing

Understanding data passing in Kubeflow Pipelines is crucial because it plays a foundational part in building components that work together as part of the machine learning workflow.

However, each of these components run in isolation. That is, each component in a Kubeflow pipeline runs in a separate Kubernetes pod. This means that they must have some mechanism to pass and share data. This is one of the things that often trips newcomers and seasoned people alike! In this section, we will go through the basics of data passing and give you some pointers so that you can adapt each scenario to your specific use case.

### 7.2.1 Scenario 1: Passing Simple Values to Downstream Components

Let's start with the first scenario of passing simple values to downstream components. Here we have three simple functions that we will turn into Kubeflow components, then combine them up into a pipeline.

##### Listing 7.4 Functions to turn in Kubeflow Components.

```
def generate_joke() -> str:
  import pyjokes                                         #A
  return pyjokes.get_joke()  
 
def count_words(input: str) -> int:
  return len(input.split())
 
def output_result(count: int) -> str:
  return f"Word count: {count}"
```

The idea for the pipeline is the following: First, the `generate_joke` function uses the PyJokes library to generate some jokes. This text is then passed to the word counter function which outputs the number of words. Finally, the return result of that (i.e. the number of words) is then passed to the final component that prints out the result. Now let's see how this would look as a Kubeflow pipeline.

One of the most important things to remember is that all `import` statements should go within the function definition, such that the dependencies are encapsulated and easy to package as a Docker container for execution within a Kubeflow Pipeline. This is exactly what we did with the `import pyjokes` statement in Listing 7.4.

##### Listing 7.5 Kubeflow components and pipeline definition.

```
import kfp
import kfp.components as comp
import kfp.dsl as dsl
 
joke_generator_op = comp.create_component_from_func(            #A
    generate_joke,                                         #A
    packages_to_install=["pyjokes"],                       #B
    output_component_file="joke_generator_component.yaml", #C
)
 
word_counter_op = comp.create_component_from_func(
    count_words,
    output_component_file="word_counter_component.yaml",
)
 
output_op = comp.create_component_from_func(
    output_result,
    output_component_file="output_result_component.yaml",
)
 
@dsl.pipeline(name="simple pipeline demonstrating data passing")         #D
def pipeline():
    joke_generator_task = joke_generator_op()                            #E
    word_counter_task = word_counter_op(joke_generator_task.output)      #E
    output_task = output_op(word_counter_task.output)                    #E
```

We use the `create_component_from_func` to create Kubeflow components from the functions.

##### Rules for Package Management in Kubeflow Components

Each Kubeflow component runs within a Docker container image that is executed on a Kubernetes Pod. In order to run custom packages, then one of the following must be satisfied:

1. The package must be installed on the container image. You can do this via the `base_image` parameter of the `kfp.components.create_component_from_func(func)` function. For lightweight components, the image needs to have python 3.5+. The default is the python image corresponding to the current python environment.
1. The package must be defined using the packages_to_install parameter of the `kfp.components.create_component_from_func(func)` function. We've just done this with `pyjokes`.
1. Your function must install the package. For example, your function can use the subprocess module to run a command like `pip install` that installs a package. However, this is less explicit than the above method and one that we seldom use.

The `packages_to_install` parameter is used to specify a list of Python packages that need to be installed within the component's execution environment. These packages are essential for the proper functioning of the `generate_joke` function. As long as the functionality is not part of the Python core libraries, it should be included.

Then, we create the Kubeflow pipeline. Here, you'll notice that we have introduced a new concept: the **output**.

Recall that the first two functions, `generate_joke` and `count_words`, both of which return values. This value is represented by the `output` attribute by the generated component. What's interesting is what happens under the hood:

Listing 7.5 is a snippet of a specification for a Kubeflow pipeline. The `templates` section defines each step in the pipeline. We've only shown `count-words` here for brevity. Within each template, you'll see the `container`, `args`,`image` (it's located near the end of the file) which should be familiar to you as Docker concepts.

Another familiar Docker concept is the `command`, which refers to the command that is executed when a container is started from an image. This command defines the initial process that runs inside the container. In many cases, this is not explicitly defined. However, the Kubeflow Pipeline SDK explicitly defines the command (and it occupies most of the file!).

The first part of the command (`sh -ec |`) runs a shell script. Within that shell script, it does the following:

It creates a temporary file path using mktemp then writes the content of the script itself (`"$0"`) to the temporary file. The Python 3 script is executed taking the temporary file path as an argument ("`$program_path" "$@`") as arguments.

The second part of the command is the actual Python code:

The count_words function is exactly the code we've defined earlier that takes an input and counts the number of words in it. `_serialize_int` is a generated function to serialize integer values as strings.

The argparse module is used to parse command-line arguments, including "`--input`" and "`----output-paths.`", including passing arguments to the `count_words` function. Finally, the output is serialized and written to specified output files.

##### Listing 7.6 Kubeflow Pipeline SDK creates files by code injection.

```
spec:  
  entrypoint: simple-pipeline-demonstrating-data-passing  
  templates:  
  - name: count-words  
    container:                           
      args: [--input, '{{inputs.parameters.generate-joke-Output}}', '----output-paths',  
        /tmp/outputs/Output/data]  
      command:  
      - sh                                                                            #A 
      - -ec                                                                           #A  
      - |                                                                             #A 
        program_path=$(mktemp)                                                        #A 
        printf "%s" "$0" > "$program_path"                                            #A 
        python3 -u "$program_path" "$@"                                               #A                      
      - |  
        def count_words(input):  
            return len(input.split())  
  
        def _serialize_int(int_value: int) -> str:                                    #B
            if isinstance(int_value, str):                                            #B
                return int_value                                                      #B
            if not isinstance(int_value, int):                                        #B
                raise TypeError('Value "{}" has type "{}" instead of int.'.format(    #B
                    str(int_value), str(type(int_value))))                            #B
            return str(int_value)                                                     #B
  
        import argparse                                                                #C
        _parser = argparse.ArgumentParser(prog='Count words', description='')          #C
        _parser.add_argument("--input", dest="input", type=str, required=True,         #C
                              default=argparse.SUPPRESS)                               #C
        _parser.add_argument("----output-paths", dest="_output_paths",                 #C
                               type=str, nargs=1)                                      #C
        _parsed_args = vars(_parser.parse_args())                                      #C
        _output_files = _parsed_args.pop("_output_paths", [])                          #C
        _outputs = count_words(**_parsed_args)                                         #C
  
        _outputs = [_outputs]                                                          #C
        _output_serializers = [                                                        #C
            _serialize_int,                                                            #C
        ]                                                                              #C
  
        import os                                                                      #D
        for idx, output_file in enumerate(_output_files):                              #D
            try:                                                                       #D
                os.makedirs(os.path.dirname(output_file))                              #D
            except OSError:                                                            #D
                pass                                                                   #D
            with open(output_file, 'w') as f:                                          #D
                f.write(_output_serializers[idx](_outputs[idx]))                       #D
      image: python:3.7   
    inputs:  
      parameters:  
      - {name: generate-joke-Output}  
    outputs:  
      parameters:  
      - name: count-words-Output  
        valueFrom: {path: /tmp/outputs/Output/data}
```

This is slightly advanced so if this goes completely over your head, it is completely fine. What Kubeflow does to enable data passing to work in a little sneaky code injection. In order to see which code is injected, look for the `count_words` definition, mentally subtract that away, then every other Python code that remains is the injected code.

Some helper functions are added which capture the output of the variable and store it in a dictionary. The code for this is visible once the pipeline is compiled and you can inspect the resulting YAML.

This approach of passing simple values works great for simple functions and simple values. But what happens if you need to pass larger values, say a huge dataset in the orders of several hundred gigabytes? That's covered in the next section. Onward!

### 7.2.2 Scenario 2: Passing Paths for Larger Data

We'd argue that for most cases, you'd want your components to be processing large amounts of data, whether it is data preparation or model training. Once again, the main thing to remember is that the component is executed within the context of a Kubernetes Pod. Why is this important? Each Pod would have a predefined memory limit. If this memory limit is exceeded, for example, if processing a large amount of data takes too much RAM, then the Pod would be killed with the dreaded `OOMKilled` error.

One recommendation therefore is that you use a file or directory to store data and pass the path of that file or directory between functions instead of the raw value if you can. Here's an example to illustrate what we mean, with the familiar joke generating example we've used before, but spiced up a little with an argument for the number of jokes along with the output file path:

##### Listing 7.7 Using OutputPath in a component to write results to a file.

```
def generate_joke(num_of_jokes: int, output_file_path: comp.OutputPath(str)):  #A
  import pyjokes  
 
  with open(output_file_path, 'w') as f:                                       #B
    for line in [pyjokes.get_joke() for _ in range(num_of_jokes)]:  
      f.write(line) 
  
def count_words(input_file_path: comp.InputPath(str)) -> int:  #C
  with(input_file_path, 'r') as f:  
    return len(f.read().split())  
  
def output_result(count: int) -> str:  
  return f"Word count: {count}"
```

Here, we have almost the same three functions, with some modifications.

First, `generate_joke` now has another argument, `output_file_path`. The type is an `OutputPath` which comes from the Kubeflow components package. Then, the output result of the function is written to the output file path. Secondly, the function signature no longer returns anything. Previously it was a `str`, but now we're writing to a file instead.

For the `count_words` function, instead of taking the raw string from before, it now takes an `input_file_path`, unsurprisingly called `InputPath` from the same components package. Just like how you would read from a normal path that's defined as a string in Python, the mechanism of reading the contents of the input path is the same.

Here's the definition of the pipeline:

##### Listing 7.8 Data passing with three components.

```
@dsl.pipeline(name="simple pipeline demonstrating data passing")  
def pipeline():  
    large_joke_generator_task = joke_generator_op(num_of_jokes=42)  
    word_counter_task = word_counter_op(large_joke_generator_task.output) #A
    output_task = output_op(word_counter_task.output) #B
```

We have omitted the definitions of the components since that is exactly the same as before. What's interesting here is how the `input_file_path` is passed. Recall that the input argument of the word counter is `input_file_path`. However, in the input argument of the Kubeflow component, it expects it to be called `input` and not `input_file_path`. You might be scratching your head because this might be a little confusing. Fear not, that's coming up in the next section.

### 7.2.3 Rules for Input and Output Pipeline Parameters

This section covers rules for input and output Kubeflow pipeline parameters.This includes:

- InputFile
- InputPath
- OutputFile
- OutputPath

#### Rule 1: Trailing _path

If an argument name ends with `_path` and the argument is either an `InputPath` or `OutputPath`, the *parameter name* is the argument name with the trailing `_path` removed. For example, an argument named `file_to_download_path`resolves into `file_to_download`.

#### Rule 2: Trailing _file

If an argument name ends with `_file` and the argument is either an `InputFile` or an `OutputFile`, the _parameter name_ is the argument name with the trailing `_file` removed. For example, an argument named `customer_names_file`resolves into `customer_names`.

##### Pop Quiz! What about input_file_path?

In this case, the previous two rules kick in and it would be truncated to be called input. In fact, we've been using input_file_path in the various examples!

#### Rule 3: Single Output

If you return a single (small) value from your component using the `return` statement, the output parameter is named `output`. Since both `large_joke_generator_task` and `word_counter` task have only a single output, we can therefore reference the return value with `<task_function>.output`:

##### Listing 7.9 `.output` represents the output of a single-value component.

```
@dsl.pipeline(name="simple pipeline demonstrating data passing")  
def pipeline():  
    large_joke_generator_task = joke_generator_op(num_of_jokes=42)  #A
    word_counter_task = word_counter_op(large_joke_generator_task.output) #A
    output_task = output_op(word_counter_task.output)
```

#### Rule 4 : Multiple Outputs

If you return several small values from your component by returning a `NamedTuple` from the `collections`module. This is very useful for creating simple and lightweight data structures that are similar to a class, but without the overhead of defining a full-fledged class.

The difference between `NamedTuple`and the usual Python tuples is that the former has a method to access the attributes via its name. See [https://docs.python.org/3/library/collections.html#collections.namedtuple](https://docs.python.org/3/library/collections.html#collections.namedtuple) for more information.

The Kubeflow Pipelines SDK uses the tuple’s field names as the output parameter names, which are the perfect use case for `NamedTuple`. The final rule is useful when you want to pass several small values. In this case, you should return a named tuple, and the tuples field names become the output parameter names.

This will be useful (you'll see this soon when we write a component to split datasets) when the component generates multiple outputs. Here's a rough sketch of how a component like that could look:

##### Listing 7.10 Data passing with multiple outputs.

```
def data_prep(train_images_output_path: OutputPath(str),
              train_labels_output_path: OutputPath(str), 
              test_images_output_path: OutputPath(str),  
              test_labels_output_path: OutputPath(str)): 
  
    with open(train_images_output_path, "w") as f:                     #A
        f.writelines(line + '\n' for line in x_train)
    # ... 
def train_and_eval(epochs: int,
                   train_images_path: InputPath(str),
                   train_labels_path: InputPath(str),
                   test_images_path: InputPath(str),
                   test_labels_path: InputPath(str))
  # function body omitted...
 
data_prep_op = comp.create_component_from_func(data_prep)
train_and_eval_op = comp.create_component_from_func(train_and_eval)
 
def pipeline():
  data_prep_task = data_prep_op()
  train_and_eval_task = train_and_eval_op(
    epochs=5,
    train_images_path=data_prep_task.outputs["train_images_output"], #B
    train_labels_path=data_prep_task.outputs["train_labels_output"], 
    test_images_path=data_prep_task.outputs["test_images_output"],  
    test_labels_path=data_prep_task.outputs["test_labels_output"],   
  )
```

There is a direct relation between the input arguments (e.g. `train_images_path`) of the upstream component, `train_and_eval`. The output is written to `train_images_path`. However, based on the naming rules you've just learnt, this will be resolved to train_images. Since we're dealing with multiple outputs here, we use train_images as the key: `data_prep_task.outputs["train_images_output"]`.

## 7.3 Project: Data Preparation

We are going to lay the foundations of the training pipelines for the two capstone projects, starting with the data preparation stage. This stage is going to split into two parts: Downloading the dataset and splitting it up into training, test, and validation datasets respectively. Each stage maps to one Kubeflow component. Both of these components will be assembled into a single, executable pipeline.

By the end of this chapter, you will have learned to create your very first Kubeflow pipeline, but more importantly, you'll learn techniques on creating composable and well-defined Kubeflow components, and also know how to customize Kubeflow components for your own needs.

### 7.3.1 Data preparation: Object detection

Let's run through the blocks we need to build out first for the object detection example. The movie recommender is similar, so we won't rehash the same components but only discuss some differences to keep in mind.

##### Follow along with the project's code on GitHub:

The full source code for the project used in this section is in: [https://github.com/practical-mlops/object-detection-project](https://github.com/practical-mlops/object-detection-project)

#### Background: What YOLO Expects

There is no one standard dataset format for training object detectors. In our case, in order to train a YOLOv8 model, we must format our dataset accordingly. We have actually done the hard work of converting the dataset to the Ultralytics YOLO format. In general though, this is something that either you or a Data Scientist would have to take care of.

##### Listing 7.11 Configuration file for training YOLOv8 with a custom dataset.

```
path: /home/jovyan/data/  # dataset root dir
train: "train/images"
val: "val/images"
test: "test/images"
names:
  0: id_card
```

The format for the configuration file is quite straightforward. The first line specifies the fully-qualified path to the root directory of where the dataset resides. It assumes that the data is already split three ways: training, validation and test.

For each of these, you'd have to specify where the images are. The labels are assumed to be in a corresponding folder called `labels`. For example, for the training dataset, it should be in `train/labels`:

##### Listing 7.12 Directory structure that YOLOv8 expects.

```
:~/data$ ls train/ val/ test/ 
test/:
images  labels
 
train/:
images  labels 
 
val/:
images  labels
```

Finally, the last field, `names`, specifies the class index along with the class label. Here, class is the category of the object that we want to detect. Class numbers are zero-indexed. In our case, there's only one object that we are interested in – the identity card, which we use `id_card` to represent. The naming convention for images and labels is simple: The label for `images/id0042.png`is `labels/id0042.txt`.

This background information is useful because we will soon build a component that has to split the dataset. Different implementations often lead to different configuration files, folder structure and naming conventions, so it's always wise to consult the relevant documentation before starting.

There are a number of methods to create a Kubeflow component. Here, we present the most common one, using a Python function. In this section, we will build out two components, one to download data and another to split the dataset, and then finally we will assemble them into a pipeline. To begin with, let's talk about the datasets that we will be using for our projects.

#### MIDV-500 : Dataset used for Object Detection Examples

![Figure 7.6 MIDV-500 dataset. Source: https://github.com/fcakyon/midv500](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/07__image011.png)

The dataset comprises 500 video clips encompassing 50 distinct identity document types, including ID cards, passports and driving licenses. For our purposes, we've filtered the dataset to keep only ID cards.

#### Dataset Download Component

In this section, we will walk through the step-by-step process of setting up your very first Kubeflow component to download the dataset from a remote location. This is the process that we're going to follow:

1. Download the data from a remote location. In a production system, this component gets the data from a database, a datalake or by mining an existing data store for interesting data. For our projects, we will download the data from open-source repositories.
1. Uncompress and pre-process data. Here, we uncompress the data from our downloads and prepare it for ingesting into our dataset. In a production workflow, this step could also include things like data validation and logging.
1. Store the data. We will use minio for our datastore. Minio comes pre-packaged with Kubeflow and offers an S3 like interface for access, making it easy to integrate into automation and scripts. In our project, we will create a bucket on Minio first and then copy data we pre-processed in step 2 into it. Minio also provides some versioning which we can leverage on later for version control. Please note, versioning might need to be enabled and has some specific quirks in Minio. Consult the documentation here [https://min.io/docs/minio/linux/administration/object-management/object-versioning.html](https://min.io/docs/minio/linux/administration/object-management/object-versioning.html)
1. Once we have the above steps ready, we can now begin to think about splitting them into components and testing them out in single component pipelines.

#### Step 1: Download Data from Remote Location

Our journey begins with acquiring the essential data for the object detection project. We'll fetch data from a remote location using the book's Box URL. This location hosts the necessary data files that contain images and their corresponding labels. In Python, this is straightforward to implement:

##### Listing 7.13 Downloading the dataset (with a progress bar)

```
import requests
from tqdm import tqdm                                                              #A
 
# ~ 10GB
url = "https://manning.box.com/shared/static/34dbdkmhahuafcxh0yhiqaf05rqnzjq9.gz" #B
downloaded_file = "DATASET.gz"
 
response = requests.get(url, stream=True)                       #C
file_size = int(response.headers.get("Content-Length", 0))      #C
progress_bar = tqdm(total=file_size, unit="B", unit_scale=True) #C
 
with open(downloaded_file, 'wb') as file: 
    for chunk in response.iter_content(chunk_size=1024): #D
        # Update the progress bar with the size of the downloaded chunk #D
        progress_bar.update(len(chunk)) #D
        file.write(chunk) #E
```

The code above effectively downloads the dataset from the specified URL, displays a progress bar to visualize the download progress, and saves the downloaded file to the specified directory with the specified name. This is particularly useful when dealing with large files to provide a better user experience and monitor the download progress.

#### Step 2: Uncompress the Tar File

The dataset is in one file instead of thousands of little files. This was done to save space and facilitate efficient transfer. In this case, the data arrives as a Tar file. To access and use the data, you'll need to uncompress the Tar file. This process is straightforward in Python:

##### Listing 7.14 Un-taring the downloaded dataset.

```
import tarfile
 
output_dir = "DATASET"
with tarfile.open(downloaded_file, 'r:gz') as tar: #A
    tar.extractall(output_dir)                     #B
```

Here, we use the `tarfile` module to open a compressed tar archive file (`downloaded_file`) for reading with the `r:gz` mode, which indicates that the file is to be read as a gzip-compressed tar archive. Inside the `with` block, the `tar.extractall(output_dir)` statement is used to extract all the files from the archive into the specified `output_dir` directory. This code assumes that the variable `output_dir` holds the path to the directory where the extracted files should be placed.

#### Step 3: Create a MinIO Bucket & Copy Data

Now that your data is ready for use, it's time to set up a MinIO bucket. MinIO is an S3-compatible object store that seamlessly integrates with Kubeflow. This bucket serves as a storage space for your data and models throughout the pipeline.

##### Listing 7.15 Initializing a MinIO client and creating a bucket.

```
import boto3
minio_client = boto3.client(                           #A
    's3',                                              #A
    endpoint_url='http://minio-service.kubeflow:9000', #A
    aws_access_key_id='minio',                         #A
    aws_secret_access_key='minio123')                  #A
try:
    minio_client.create_bucket(Bucket=bucket_name) #B
except Exception as e:
    # Bucket already created.
    pass
```

We use the popular `boto3` library to create a client connection to an S3-compatible object storage service, which in this case is MinIO. The `boto3.client()` function is used to create the client. The `endpoint_url` parameter specifies the URL of the MinIO service.

The provided URL indicates that MinIO is accessible at `http://minio-service.kubeflow:9000`, which is the default for most Kubeflow installations.The `aws_access_key_id` and `aws_secret_access_key` parameters are set to the credentials used to authenticate with MinIO. In this case, they are set to `'minio'` and `'minio123'` respectively, which are also the defaults with Kubeflow.

##### Change your passwords in production!

It should go without saying that using the default passwords, along with using them in cleartext is bad practice! In production, you should use something like Vault, which uses a Kubernetes sidecar to inject passwords into the running Pod.

Once the client has been initialized successfully, we'll create a bucket. The method throws an exception if it already has been created so we wrap it in a `try`/`catch` block to handle this.

With your MinIO bucket in place, the next step is to transfer the contents of the uncompressed Tar file into the bucket, using again the MinIO Python API to perform the upload. By storing your data in the MinIO bucket, you ensure that it's readily accessible to various components of your Kubeflow pipeline.

##### Listing 7.16 Uploading images and labels to MinIO.

```
import os 
for f in ["images", "labels"]:
    local_dir_path = os.path.join(output_dir, "DATA", f)
    files = os.listdir(local_dir_path)
    for file in files:
        local_path = os.path.join(local_dir_path, file) #A
        s3_path = os.path.join(bucket_name, f, file) #B
        minio_client.upload_file(local_path, bucket_name, s3_path) #C
```

The code iterates over the list of directories named `images` and `labels`. For each file in the directory, we construct a `local_path` and a `s3_path`, representing the source and upload destination respectively. The file is then uploaded using the `upload_file` method.

#### Step 4: Turning this into a Kubeflow Component

At this point you might be wondering that while the above steps seem to make sense, how then does it get turned into a Kubeflow component. Great question, astute reader! First, we'll turn everything you've seen so far into a function:

##### Listing 7.17 Import statements should go within the function definition.

```
def download_dataset(bucket_name: str):
    import boto3            #A
    import os               #A
    import requests         #A
    import tarfile          #A
    from tqdm import tqdm   #A
    # ... The rest of the code goes here
```

As mentioned before, one of the most common ways of defining a Kubeflow component is to use a Python function, such as `download_dataset`. Note again that all the import statements are placed within the function definition. This is so that dependencies are encapsulated and easy to package into a Docker container.

Here's how to create the Kubeflow component:

##### Listing 7.18 Using external Python libraries in Kubeflow Components.

```
import kfp.comp as comp
from data_preparation.download_dataset import download_dataset #A
 
download_task = comp.create_component_from_func(
    download_dataset, #B
    packages_to_install=["requests", "boto3", "tqdm"]) #C
```

The `create_component_from_func()` function is used to create a reusable component from a Python function. In this case, the function `download_dataset` is being converted into a component. Just as in the `generate_jokes` component, the `packages_to_install` parameter is used to specify a list of Python packages that need to be installed within the component's execution environment.

#### Bonus step: Using the Component in a Pipeline

Let's just skip ahead a bit just to see how we can use this in a pipeline. In this case, we're simply building a single-component pipeline.

##### Listing 7.19 Building a single-component Kubeflow pipeline.

```
import kfp                    #A
import kfp.components as comp #A
import kfp.dsl as dsl         #A
 
from data_preparation.download_dataset import download_dataset
 
download_task = comp.create_component_from_func(
    download_dataset,
    packages_to_install=["requests", "boto3", "tqdm"])
 
@dsl.pipeline(name="YOLOv8 Object Detection Pipeline") #B
def pipeline():
    download_op = download_task(bucket_name="dataset") #C
 
if __name__ == '__main__':
    kfp.compiler.Compiler().compile(        #D
        pipeline_func=pipeline,             #D
        package_path='pipeline.yaml')       #D
```

First, we'll import all the necessary Kubeflow Pipeline modules we need. Then, using the `@dsl.pipeline` decorator, we define a `pipeline()` function. Inside this pipeline definition, the `download_op` operation is created by invoking the `download_task` component.

##### _op and _task naming pattern

In this book's example and subsequent examples, you would notice a naming pattern where:

```
<function_name>_op = <function_name>_task()
```

While this is not mandatory, it helps adopt a consistent naming convention and helps when other Kubeflow developers work on the same code.

Finally, when this script is executed, the Kubeflow Pipeline compile is invoked which takes in the pipeline definition and outputs a `pipeline.yaml` file which contains the pipeline definition in YAML.

##### What does `pipeline.yaml` look like?

We encourage you to take a look at the generated pipeline.yaml file. Can you roughly work out how the various components are defined and put together? Are there parts of it that are surprising? Can you get a hint of how Kubeflow components work under the hood, especially file creation? Spend a bit of time poring through the code and you'd realize it's not magical at all!

#### Passing data between components

Here's a little thought experiment. Let's look at the pipeline definition we have so far now:

```
def pipeline():
  download_op = download_task(bucket_name="dataset")
```

Now we have not implemented the `split_dataset` component yet, but how would you pass in the downloaded dataset from `download_op` and pass it to `split_dataset_op`? For example:

```
def pipeline():
  download_op = download_task(bucket_name="dataset")
  split_dataset_op = split_dataset_task(data=download_op.output)
```

Your initial reaction might be to make a copy of it and pass it to the downstream component. However, given that the dataset is 10GB, if you have 5 components, downloading 50GB of the same data doesn't seem like a smart solution.

The other alternative is the pass in the *path* of the data. In this case, the path to the MinIO bucket. In order for that to happen, we have to make two modifications, one to the function signature and another to the function definition of `download_dataset`:

##### Listing 7.20 How to write to OutputPath.

```
from kfp.components import OutputPath
 
def download_dataset(bucket_name: str, output_file: OutputPath(str)): #A
    # ... previous code unchanged.
    
    # Write the output file path to the output_file
    with open(output_file, 'w') as file:
        file.write(os.path.join(bucket_name)) #B
```

The code extends the `download_dataset` function to accept an additional parameter `output_file` of type `OutputPath(str)`. This parameter is used to specify the location where the function should write the output file path and is specific to Kubeflow Pipelines.

Behind the scenes, the SDK handles the file creation and storage of this output value. There are a few rules regarding data passing which we will go through soon, but as a best practice, for large files, it is better to have it point to a remote location rather than the actual files. This is because you avoid loading the contents of the file in memory, which could potentially cause out of memory errors (the dreaded OOMKilled) if the file size exceeds the allocated memory size of the pod. In this case, we are writing the name of the bucket to a file so that we can pass this along to the next component.

Note that while there is now another parameter (`output_file: OutputPath(str)`), it doesn't change how the component is invoked. In other words, you would still call it with a single parameter, because remember, the SDK handles the creation of the file behind the scenes.

We'll cover the dataset splitting component next, and then you'll see how that component receives input.

#### Dataset splitting Component

This section covers dataset splitting and demonstrates how to install custom Python packages that your Kubeflow components might require. You'll get more practice with using `OutputPath` as a way to pass data around. After that, with the data splitting component completed, we'll combine them into a single pipeline. This is what we want to achieve:

![Figure 7.7 The Data Preparation Pipeline](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/07__image013.png)

The first component downloads the dataset from a remote location to a MinIO bucket. The output is a list of the downloaded files. The path of this list is passed over to the second component. This component reads that file, and splits the labels and images file names into train, test and validation respectively. Therefore, a total of six files. Finally, we pick two files (out of a possible 6) and output its contents to do a sanity check.

#### Step 1: Dataset Splitting for YOLO and installing Custom Packages

With your dataset securely stored in the MinIO bucket, the next crucial step is to divide it into training, testing, and validation sets.

In some cases, you may need specialized tools or libraries that are not included by default in your Kubeflow components. We'll illustrate how to install custom Python packages into your components, enabling you to leverage the full spectrum of resources available for your project. This flexibility empowers you to tailor your pipeline to the unique requirements of your machine learning project.

In this instance, we will use the very convenient helper function `train_test_split` in Scikit Learn to carry out the dataset splitting, where you'll be able to achieve dataset splitting in just a single line of code.

First, set up the function signature and imports:

##### Listing 7.21 Using Multiple OutputPaths and inner imports.

```
from kfp.components import OutputPath
 
def split_dataset(bucket_name: str,
                  random_state: int,
                  x_train_file: OutputPath(str), #A
                  y_train_file: OutputPath(str), #A
                  x_test_file: OutputPath(str),  #A
                  y_test_file: OutputPath(str),  #A
                  x_val_file: OutputPath(str),   #A
                  y_val_file: OutputPath(str)):  #A
 
    from minio import Minio                               
    from minio.error import S3Error
    from sklearn.model_selection import train_test_split
    # more code to follow ...
```

The code starts by importing the necessary libraries and classes. Notably, it imports `OutputPath` from `kfp.components`, which is used to specify output paths for the resulting datasets. Recall from the Data Passing section that Kubeflow Pipelines injects some code that creates these files in the background, which you subsequently write to within the function.

The function also imports the required modules from the `minio` library to interact with a Minio object storage service and the `train_test_split` function from `sklearn` to split the dataset.

The next step defines an inner function. Recall that component functions need to be self contained. Therefore, any helper functions have to be defined within. This helper function lists MinIO objects based on the prefix. This is very useful for an object store that doesn't have the traditional folder structure that is in conventional file systems.

##### Listing 7.22 Listing by prefix for separate retrieval of images and labels.

```
def split_dataset(...):
    # previous code here...
    def list_objects_with_prefix(minio_client, bucket_name, prefix):           #A
        try:
            objects = minio_client.list_objects(bucket_name, prefix=prefix, recursive=True)
            return [obj.object_name for obj in objects]
        except S3Error as err:
            print(f"Error listing objects with prefix '{prefix}' in '{bucket_name}': {err}")
 
    minio_client = Minio(
        'minio-service.kubeflow:9000',
        access_key='minio',
        secret_key='minio123',
        secure=False
    )
 
    images = list_objects_with_prefix(minio_client, bucket_name, prefix=f"{bucket_name}/images") #B
    labels = list_objects_with_prefix(minio_client, bucket_name, prefix=f"{bucket_name}/labels") #B
```

The next step is where the actual splitting takes place. Given we have the list of `images` and `labels`, we can use the `train_test_split` provided by Scikit Learn to split `images` and `labels` into train, test and validation datasets respectively. By default, `train_test_split` splits into two partitions, so we have to apply a little creativity and math to further split into three partitions:

##### Listing 7.23 Splitting the dataset into 75/10/15% for Train/Test/Val.

```
def split_dataset(...,
    train_ratio = 0.75
    validation_ratio = 0.15
    test_ratio = 0.10
):
    # previous code here...
 
    x_train, x_test, y_train, y_test = train_test_split( #A
        images, labels,                                    
        test_size=1 - train_ratio,                       #B
        random_state=random_state)
 
    # test is now 10% of the initial data set
    # validation is now 15% of the initial data set
    x_val, x_test, y_val, y_test = train_test_split(     #B
        x_test, y_test,
        test_size=test_ratio / (test_ratio + validation_ratio),
        random_state=random_state)
```

Finally, we just need to write the filenames of all the datasets. Note here that we do not need to write the actual files, just the paths. We also output the lengths of the dataset splits at the end, just so that we can get some visual feedback:

##### Listing 7.24 Writing filenames is more efficient than file writing.

```
def split_dataset(...):
    # previous code here...
    with open(x_train_file, "w") as f: #A
        f.writelines(line + '\n' for line
 in x_train) #A
 
    with open(y_train_file, "w") as f: #B
        f.writelines(line + '\n' for line in y_train) #B
 
    # Similar with testing and validation...
```

#### Step 2: Outputting File Contents from Input Files

Let's build a throwaway component, but very useful to ensure that everything is working fine. This component will take the output path from the dataset splitting component and output the contents of the file.

##### Listing 7.25 A component that prints out the contents given the file path

```
from kfp.components import InputPath
 
def output_file_contents(file_path: InputPath(str)):
    print(f"Printing contents of :{file_path}")
 
    with open(file_path, 'r') as f:
        print(f.read())
```

Note that this component only takes in a single file path. In the next step. this component will be used multiple times since the `split_dataset` component has multiple outputs.

#### Full Pipeline from components

Now that you have a component for downloading the dataset, uncompressing it and splitting it, and printing the results of each output, it's time to bring everything together into a pipeline.

You start with creating the `download_task` component as part of your Kubeflow object detection pipeline. You'll need to ensure that you also provide a comprehensive list of Python package dependencies that need to be installed using `packages_to_install`. This holds true for the other two components within the pipeline; a consistent pattern ensures that all the required dependencies are correctly resolved.

Once all the components have been defined, you'll then need to assemble the pipeline. This involves initializing each of the components and specifying how they fit together to achieve the desired workflow.

It is important to be careful when passing in arguments to the various components. Mistakes in this stage can lead to unexpected behavior and errors in your pipeline.

Keep in mind that there isn't an inherent data dependency between the `download_op` and `split_dataset_op` components. Therefore, it's your responsibility to explicitly define the order of execution. Failure to do so would result in Kubeflow attempting to run both components simultaneously, potentially causing conflicts or errors in your pipeline execution. Taking care of these details ensures the reliability and efficiency of your Kubeflow object detection pipeline.

##### Listing 7.26 Creating the full data preparation pipeline.

```
import kfp
import kfp.components as comp
import kfp.dsl as dsl
 
from data_preparation.download_dataset import download_dataset
from data_preparation.split_dataset import split_dataset
 
download_task = comp.create_component_from_func(      #A
    download_dataset,                                 #A
    packages_to_install=["requests", "boto3", "tqdm"])#A
 
split_dataset_task = comp.create_component_from_func(
    split_dataset,
    packages_to_install=["minio", "scikit-learn"])
 
output_file_contents_task = comp.create_component_from_func(output_file_contents)
 
@dsl.pipeline(name="Simple pipeline")
def pipeline(random_state=42):                     #B
    download_op = download_task(bucket_name="dataset")              #C
    split_dataset_op = split_dataset_task(bucket_name="dataset", 
                                          random_state=random_state).after(download_op) #D
    _ = output_file_contents_task(split_dataset_op.outputs['x_val')
    _ = output_file_contents_task(split_dataset_op.outputs['y_val')
 
if __name__ == '__main__':
    kfp.compiler.Compiler().compile(
        pipeline_func=pipeline,
        package_path='dataprep_pipeline.yaml')
```

Compile the pipeline by running the entire script:

```
% python data_prep_pipeline.py
```

If there are no errors, a `dataprep_pipeline.yaml` file would be generated.

#### Upload and Run pipeline

In the Kubeflow UI, click on the "Upload pipeline" button on the top-right hand corner:

![Figure 7.8 The Pipelines screen lists all the uploaded pipelines and also lets you upload new pipelines.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/07__image015.png)

If you have uploaded other pipelines, you'll also see them all listed here.

#### Navigate to the folder containing the compiled data preparation pipeline in Step 3 (d`ataprep_pipeline.yaml)`:

![Figure 7.9 Pipelines can either be zip files or YAML. In this case, we're selecting a YAML file.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/07__image017.png)

Once you've clicked on "Upload", you will see the graphical representation of the pipeline:

![Figure 7.10 After a successful upload, you can see the pipeline.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/07__image019.png)

Once you have successfully uploaded the pipeline, you'll get a graphical representation of the pipeline. This is useful to also check that all the pipeline components are connected as expected.

The next step is to execute the pipeline. In Kubeflow parlance, that is creating a *run*. Click on "Create run". Most of the fields would be already populated, execute for "Experiment". If you have not created an experiment, now is a perfect time to do so.

Experiments in Kubeflow are a way of grouping pipeline runs together with. Note that experiments can contain pipeline runs from different kinds of pipelines.

![Figure 7.11 The Run details page is mostly populated automatically. You'll have to choose the experiment.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/07__image021.png)

There are other options in this Run details page. For example, you can create a Recurring run (instead of the default One-off). This is useful for pipelines that need to be run repeatedly where the workloads are predictable.

If you refer back to the function signature of the pipeline:

```
@dsl.pipeline(name="Simple pipeline")
def pipeline(random_state=42):
  ...
```

You'll realize that the fields here are automatically created and populated.

Click on Start. Each node on the Graph will slowly get populated as each component initializes and gets executed. On my machine, the entire process takes around thirty minutes to complete. If everything goes well, you will see:

![Figure 7.12 A completely executed Kubeflow pipeline. Seeing this gives us warm fuzzy feelings every time (and a sigh of relief).](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/07__image023.png)

##### Viewing logs during the execution of the component

It is very useful to add logging information for components, especially the ones that take a long time to execute. Having some form of visual feedback and progress lets you detect early on if things go wrong. When you click on each executed (in blue) or completed (in green) component, you will see the logs generated. For example, if you were to click on the Output file contents components, you should see the file contents being listed.

##### Log management in production

While useful in debugging, verbose logging and/or progress bars can write a lot of logs and will use up disk space very quickly, especially in recurring runs. If your minio data store is on a kubernetes node, this will create diskPressure events on that node which in turn causes kubernetes to drain a node of pods and stop scheduling new pods onto it.

Be sure to have a look at the minio buckets where the run logs are stored and clean them up as is needed. For production setups, it is highly recommended to have an automated log rotation and archival strategy to mitigate this!

![Figure 7.13 Clicking each component reveals the side menu. Clicking on the logs tab lets you see all the output. If the component is running, the output is in real-time.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/07__image025.png)

### 7.3.2 Data preparation: Movie recommender

For the movie recommendation the steps to follow are largely the same. We will however, try a few new things here, including using parquet files to store our tabular data (more on why in the coming chapters), running pipelines from Kubeflow notebooks, and we will add a simple QA block to make sure our pipeline run has produced the required data.

##### Follow along with the project's code on GitHub:

The full source code for the project used in this section is in: [https://github.com/practical-mlops/movie-recommender-project](https://github.com/practical-mlops/movie-recommender-project)

#### MovieLens 25M : Dataset used for Recommender examples

For the movie recommender project, we will be using the popular MovieLens 25M Dataset. The dataset is from group lens, a research lab within University of Minnesota, Twin Cities, focusing on research into recommender systems and online interactions. The dataset has 25 million ratings and one million tag applications applied to 62,000 movies by 162,000 users. Please make sure that you read and comply with the terms of license on the MovieLens website before using the dataset.

[https://grouplens.org/datasets/movielens/](https://grouplens.org/datasets/movielens/)

#### The plan

In the example code provided, we will leverage kubeflow notebooks to build out our pipeline. The idea here is to show you that this iterative process is often easier in an interactive environment and can be easier to debug, build, and even push the pipeline to the cluster. We will build out 6 components and then assemble them into a complete pipeline. In real life deployments, a lot of these components would be combined so as to reduce the overhead of shuttling data. Here, however, we are using them to mainly demonstrate how Kubeflow handles data shuttling and what quality of life conveniences it affords us. The components we will be building out are

1. Dataset download component
1. Data unzip component
1. CSV to Parquet conversion component
1. Dataset split component
1. Minio upload component
1. Quality assurance component

To give you a sneak preview, our finished pipeline will look like the figure below.

![Figure 7.14 The pipeline we are going to build out in this section](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/07__image027.png)

#### Dataset Download

As in the object detection example before, the first step is to download the data from the MovieLens website. This component is exactly the same as the initial dataset download component.

##### Listing 7.27 Dataset download function with single output

```
from kfp.components import OutputPath
def download_ml25m_data(output_path: comp.OutputPath(str)):
    import requests
    from tqdm import tqdm
    url = 'https://files.grouplens.org/datasets/movielens/ml-25m.zip'
    response = requests.get(url, stream=True, verify=False)
    file_size = int(response.headers.get("Content-Length", 0))
    progress_bar = tqdm(total=file_size, unit="B", unit_scale=True)
    print(output_path)
    with open(output_path, 'wb') as file: 
        for chunk in response.iter_content(chunk_size=1024*2):
            # Update the progress bar with the size of the downloaded chunk
            progress_bar.update(len(chunk))
            file.write(chunk)
```

Here, the data is downloaded from the grouplens webpage and is then directly written to the output_path. In this case, the `output` attribute of the pipeline op will point directly to the zip file.

#### Dataset Unzip

For the unzip, we only really use two files ( for now ) from the dataset, so we will write a component to only extract them from the zip file.

##### Listing 7.28 Unzip function with multiple outputs

```
def unzip_data(input_path: comp.InputPath(str), ratings_output_path: comp.OutputPath(str), movies_output_path: comp.OutputPath(str)):
    import zipfile
    with zipfile.ZipFile(input_path, 'r') as z:
        with open(ratings_output_path, 'wb') as f:
            f.write(z.read('ml-25m/ratings.csv'))
        with open(movies_output_path, 'wb') as f:
            f.write(z.read('ml-25m/movies.csv'))
```

Here, there is one input file (the downloaded zip file path) and two output files. Again, we write directly onto the output paths meaning that the outputs point directly at extracted csv files. As mentioned before, referring to the outputs in the main pipeline is with a key in the outputs dictionary that has naming considerations, namely that the trailing _path is ignored (refer section 7.2.3 for the full list) and so will look like this.

```
unzip_folder.outputs['ratings_output']
unzip_folder.outputs['movies_output']
```

Another change you may have noticed is that the attribute is now `outputs` instead of `output`.

#### Parquet conversion

This is the first component that is unique to the movie recommender. Since we are dealing with tabular data, it makes sense that we use a data format that is optimized for columnar data. Parquet is a good choice here and also has some advantages over a simple CSV including the ability to shard files to improve lookup, smaller size and in certain cases higher performance due to the columnar storage format.

In this component, we will simply use pandas and a library called fastparquet to convert the CSV files into parquet format. The files are not sharded or optimized in any way and is only intended to be a demonstration for this conversion.

##### Listing 7.29 Parquet conversion with single input and output

```
def csv_to_parquet(inputFile: comp.InputPath(str), output_path: comp.OutputPath(str)):
    import pandas as pd
    df = pd.read_csv(inputFile, index_col=False)
    df.to_parquet(output_path, compression='gzip')
```

Like the components before, this component reads a file directly pointed to by the `inputFile` and writes to `output_path`.

##### File names when using InputPath or OutputPath

The `output_path` is not named by us and we don't care too much about the name since we only want to read this in the next component. Make sure any operations that use file names use the concept of writing files to directories as shown in the object detection example. If you print out an InputPath or OutputPath in your pipeline code, you will notice that it points to /tmp/<file_or_folder_name>. Under the hood, argo zips up this path and uploads them to a minio bucket to provide data persistence between components. In the next component that uses the data, the files/folders are downloaded to /tmp and unzipped for use.

We also do some reuse here by using the same component to convert the CSV files of movies and the ratings in parallel.

#### Data split

Dataset splitting follows the same pattern as splitting in the object detection example. The only real difference is how this example uses a parquet file as the input and a folder as the output path which in turn consists of three parquet files. This is another way to use `OutputPath` and highlights the flexibility afforded by the Kubeflow pipelines SDK.

##### Listing 7.30 Data split component with single input and output folder

```
def split_dataset(input_parquet: comp.InputPath(str), dataset_path: comp.OutputPath(str), random_state: int = 42):
    from sklearn.model_selection import train_test_split
    import os
    import pandas as pd
    train_ratio = 0.75
    validation_ratio = 0.15
    test_ratio = 0.10
    ratings_df = pd.read_parquet(input_parquet)
 
    # train is now 75% of the entire data set
    train, test = train_test_split(
        ratings_df,                                    
        test_size=1 - train_ratio,
        random_state=random_state)
 
    # test is now 10% of the initial data set
    # validation is now 15% of the initial data set
    val, test = train_test_split(   
        test,
        test_size=test_ratio / (test_ratio + validation_ratio),
        random_state=random_state)
    os.mkdir(dataset_path)
    train.to_parquet(os.path.join(dataset_path, 'train.parquet.gzip'), compression='gzip')
    test.to_parquet(os.path.join(dataset_path, 'test.parquet.gzip'), compression='gzip')
    val.to_parquet(os.path.join(dataset_path, 'val.parquet.gzip'), compression='gzip')
```

#### Data upload

This step is also the same as the object detection example. However, we tweak the upload code slightly so that the component is able to upload both files and folders.

##### Listing 7.31 Data upload function that can take in an input path or a file

```
def put_to_minio(inputFile: comp.InputPath(str), upload_file_name:str='', bucket: str='datasets', dataset_name:str = 'ml-25m'):
    import boto3
    import os
    minio_client = boto3.client(                          
        's3',                                              
        endpoint_url='http://minio-service.kubeflow:9000',
        aws_access_key_id='minio',
        aws_secret_access_key='minio123') 
    try:
        minio_client.create_bucket(Bucket=bucket_name)
    except Exception as e:
        # Bucket already created.
        Pass
    if os.path.isdir(inputFile):                            #A
        for file in os.listdir(inputFile):                        #A
            s3_path = os.path.join(dataset_name, file)                #A
            minio_client.upload_file(os.path.join(inputFile, file), bucket, s3_path)  #A
    else:
        if upload_file_name == '':                            #B
            _, file = os.path.split(inputFile)                    #B
        else:                                    #B
            file = upload_file_name                        #B
        s3_path = os.path.join(dataset_name, file)                    #B
        minio_client.upload_file(inputFile, bucket, s3_path)                #B
```

The code above highlights the nuance we talked about in the parquet conversion step where the OutputPath was not named by us, but by Kubeflow. This is why we have an extra input parameter upload_file_name to rename this file from /tmp/data to the filename we want it to have. This component is re-used for uploading both the train/test/validation splits folder and the movies parquet file.

#### Data quality assessment

The last component does some rudimentary QA on the outputs. It verifies if the 4 files we expect are present and then also checks if the length of the training dataset is about 75% of the full dataset as we expected. You can and should add more validation to your data prep pipelines in production. Like we mentioned in an earlier chapter, it is important to validate all assumptions now.

The QA component is also interesting in another way. The data access here is done via pyarrow, an alternative high performance data processing framework. We will use pyarrow in later chapters to stream data directly without downloading to our training processes. Here, however, we use pyarrow to open the parquet files and convert them into pandas dataframes which are then validated. This is also meant as a demo and in production, you would probably stick with one framework to read and process parquet files. While downstream components might be designed to catch these, it's almost always better to detect them early in the generation phase so that any mistakes can be fixed here rather than doing a debug retrospectively.

##### Listing 7.32 Data QA using pyarrow to read files directly from Minio

```
def qa_data(bucket:str = 'datasets', dataset:str = 'ml-25m'):
    import os
    from pyarrow import fs, parquet
    print("Running QA")
    minio = fs.S3FileSystem(
        endpoint_override='http://minio-service.kubeflow:9000',
         access_key='minio',
         secret_key='minio123',
         scheme='http')
    train_parquet = minio.open_input_file(f'{bucket}/{dataset}/train.parquet.gzip')
    df = parquet.read_table(train_parquet).to_pandas()
    assert df.shape[1] == 4
    assert df.shape[0] >= 0.75 * 25 * 1e6
    print('QA passed!')
```

##### Validate all assumptions concerning data in production!

Although the example here is a bit simplistic, it helps guard against one of the most common forms of data error, size mismatch and missing files. Make sure that all assumptions about the data including size, schema and content are validated in generation pipelines like here.

#### Full Pipeline from components

First we compile the individual components as before.

##### Listing 7.33 Compiling functions to components

```
download_op = comp.create_component_from_func(download_ml25m_data, output_component_file='download_ml25m_component.yaml', packages_to_install=["requests", "tqdm"])
unzip_op = comp.create_component_from_func(unzip_data, output_component_file='unizip_data.yaml')
csv_to_parquet_op = comp.create_component_from_func(csv_to_parquet, output_component_file='csv_to_paraquet.yaml', packages_to_install=["pandas", "fastparquet"])
split_dataset_op = comp.create_component_from_func(split_dataset, output_component_file='split_dataset.yaml', packages_to_install=["scikit-learn", "pandas", "fastparquet"])
upload_to_minio_op = comp.create_component_from_func(put_to_minio, output_component_file='put_to_minio.yaml', packages_to_install=["boto3"])
qa_component_op = comp.create_component_from_func(qa_data, output_component_file='qa_component.yaml', packages_to_install=["pyarrow", "pandas"])
```

And then we compile the components into a pipeline. Take special note of how the QA component is made to run only after both uploads to Minio are complete.

##### Listing 7.34 Combining individual components into a pipeline

```
import kfp.dsl as dsl
@dsl.pipeline(
  name='Data prep pipeline',
  description='A pipeline that retrieves data from movielens and ingests it into parquet files on minio'
)
def dataprep_pipeline(minio_bucket:str='datasets', random_init:int=42):
    download_dataset = download_op()
    unzip_folder = unzip_op(download_dataset.output)
    ratings_parquet_op = csv_to_parquet_op(unzip_folder.outputs['ratings_output'])
    movies_parquet_op = csv_to_parquet_op(unzip_folder.outputs['movies_output'])
    split_op = split_dataset_op(ratings_parquet_op.output,random_state=random_init)
    u1 = upload_to_minio_op(movies_parquet_op.output, upload_file_name='movies.parquet.gzip', bucket=minio_bucket)
    u2 = upload_to_minio_op(split_op.output, bucket=minio_bucket)
    qa_component_op(bucket=minio_bucket).after(u1).after(u2)                #A
 
# Compile the pipeline into a pipeline yaml file
kfp.compiler.Compiler().compile(
    pipeline_func=dataprep_pipeline,
    package_path='dataPrep_pipeline.yaml')
```

The object detection example leveraged on the web UI to upload the pipeline and run it. Here, we will switch things up a bit and use the Kubeflow SDK to upload the pipeline and run it. To upload the pipeline, use the client object from `kfp`.

```
client = kfp.Client()
```

The neat thing here is that since we are running this entire process in a notebook on the Kubeflow cluster, we do not need to set any credentials or point the client constructor to an endpoint. All this handled seamlessly with the environment variables injected when the notebook started up.

To upload the pipeline,

```
pipeline = client.pipeline_uploads.upload_pipeline('dataPrep_pipeline.yaml', name='ml-25m-processing')
```

##### UIDs and Kubeflow

All pipelines on Kubeflow are identified with a unique UUID which is needed when the pipeline is to be called or deleted via the SDK. To run a pipeline, you also need a job name ( a unique name that is mainly for helping the user identify a run ) and an experiment ID. Experiments are logical groups of pipeline runs and can be created from either from the web UI or with the SDK.

Now that you have uploaded the pipeline, check the web UI. You should see our shiny new pipeline there!

#### Running the pipeline

To start the pipeline run, you can use the Kubeflow SDK. However, if you do have a multi-user setup, you need to add a service account credential so that RBAC controls are satisfied. More on how to here ([https://www.kubeflow.org/docs/components/pipelines/v1/sdk/connect-api/#multi-user-mode](https://www.kubeflow.org/docs/components/pipelines/v1/sdk/connect-api/#multi-user-mode))

For now, let's start a run from the familiar UI and follow along.

![Figure 7.15 The successfully run pipeline](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/07__image029.png)

## 7.4 Summary

- ML workflows demand close proximity to datasets for processing while necessitating ad-hoc access to specialized resources like GPUs.
- Kubeflow notebooks offer Jupyter-like interfaces within the same cluster as pipelines, ensuring environment consistency with deployment settings.
- These notebooks streamline versioning and CI/CD practices by sharing base images and integrating into CI pipelines, simplifying management and ensuring robust controls.
- Kubeflow components can be created using `kfp.create_component_from_func`.
- Understanding the data passing rules in Kubeflow components, and the different scenarios for data passing between components, including the results for input and output of pipeline parameters and naming conventions like training `_path` and `_file`, are essential building Kubeflow components.
- When building components using functions, `import` statements should be defined within the function definition. Third-party dependencies can be installed by specifying the `packages_to_install` parameter in `kfp.create_component_from_func.`
- Combining these Kubeflow components form a Kubeflow pipeline, which is specified using the `@dsl.pipeline` decorator.
- Once the pipeline is compiled, a YAML file is produced. This YAML file contains boilerplate code that not only contains the individual function definitions, but also code that handles argument parsing and serialization of input/output parameters.
- The YAML file can be uploaded and executed from the Kubeflow UI or via the SDK. You can also check on the progress by viewing the real-time generated logs from the UI.
- Leveraging Kubeflow components, this chapter outlines the assembly of a object detector pipeline, employing various steps from dataset download to splitting the dataset into train/test/validation.
- It also outlines the assembly of a movie recommender system pipeline, employing various steps from dataset download to quality assurance checks.
- Using parquet file storage and conversion techniques, the chapter demonstrates efficient data handling methods, including CSV to Parquet conversion and dataset splitting for model training.
- Next chapter will work on creating the components and pipelines for training the object detection and movie recommender models. We will make use of the data from pipelines developed in this chapter and add some features to the data preparation components to reflect learnings we have from our training experiments.
