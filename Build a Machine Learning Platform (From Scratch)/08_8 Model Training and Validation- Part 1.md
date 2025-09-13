# 8 Model Training and Validation: Part 1

### This chapter covers

- Developing the Model Training and Validation components
- Capturing metrics and artifacts in tracking frameworks
- Adding the Model Training and Validation components to pipelines
- Different methods to access training and evaluation data

In the previous chapter, we've laid the groundwork to download the identity card dataset that includes the images and labels, process them into a format that YOLO expects, then divided them up into train, test and validation splits. Through that process, you've also learnt how to create your first Kubeflow components and pipelines.

The next step, and arguably the most fun, is model training and evaluation. In this chapter, we'll carry on extending the data preparation pipeline from the previous chapter and bolt on training and evaluation components. In your initial project, you'll develop an ID card object detection system utilizing the popular YOLO (You Only Look Once) algorithm. Having mastered this concept, you'll then apply similar techniques to design a movie recommendation system.

## 8.1 Training an Object Detection Model

When we left off at the previous chapter, we had six lists, containing the cross product of either train, test, validation splits of either file names of images or file names of lists. These lists should then be passed to the training component that we will outline in this chapter. The training component then:

1. Downloads each of the files in each of the lists into the appropriate folder
1. Configures the dataset. This involves setting the path to the dataset, and paths to each of the splits containing the image, and also matching the data with corresponding labels.
1. Performs the actual training and evaluation of the model

The Ultralytics YOLO library that we are using does quite a bit of the heavy lifting of the model training and evaluation, and you'll soon see. However, this is not the main focus, and it's important to note that the code could be customized to any way you want.

### 8.1.1 Downloading with MinIO

Before we develop the component, we'll need to create a helper function that will sit within the component that downloads a file located at a source (S3) URL into a local destination path.

The function in the following listing does exactly that. The first two arguments are the source bucket and object. The source bucket would be provided as a pipeline parameter (more on that later on), while the source object would be the path name of the file. The MinIO client is passed in too, which means that we need to initialize the MinIO client. Lastly, we pass in the download path to save the file.

##### Listing 8.1 Functions to download from MinIO.

```
def download_from_minio(source_bucket, source_object, minio_client, download_path):
        try:
            # Download the file from MinIO
            minio_client.fget_object(source_bucket, source_object, download_path) #A
        except S3Error as err:
            print(f"Error downloading {source_object}: {err}")
```

In order to use the function, we'll need to initialize a MinIO client. This should be familiar from the previous chapter. We point the client to the MinIO service running on the Kiubeflow cluster, and pass in the access and secret keys:

##### Listing 8.2 Initializing a MinIO client

```
minio_client = Minio(
        'minio-service.kubeflow:9000'
        access_key='minio', 
        secret_key='minio123',
        secure=False
    )
```

Once we have the client, here's an example of how we can use the `download_from_minio`function:

##### Listing 8.3 Downloading a file from MinIO

```
import os
 
source_object = "dataset/labels/HA15_22.txt"
download_path = f"/dataset/train/images/{os.path.basename(source_object)}"
download_from_minio(source_bucket, source_object, minio_client, download_path)
```

We will use this function later on to download all the images and labels. Now, let's turn to training the model.

### 8.1.2 Training YOLO on a Custom Dataset

YOLO doesn't detect identity cards by default. But fret not! Training a custom dataset on YOLO isn't very hard, as you shall soon see. First, we'll have to create a configuration file that contains information to where our images and labels are located. We'll also include the (only) label that we want YOLO to learn. After that, we'll begin training the model. Let's dive right in.

#### Configuring the Dataset

To prepare the dataset for YOLO, we need to create a YAML file. Thankfully, the scheme is straightforward. Before turning the configuration into a YAML file, we start with a dictionary with the following keys and values:

##### Listing 8.4 Data Configuration that YOLO expects

```
data = {
        'path': '/dataset/',
        'train': 'train/images',
        'val': 'val/images',
        'test': 'test/images',
        'names': {
            0: 'id_card' #A
        }
    }
```

For our purposes, we only require one label: 'id_card'. If we wanted to detect other objects, we would then add other classes to this list. Note that for YOLOv8, we only need to specify the image paths.

For YOLOv8, labels for a specific stage are expected to be in an adjacent directory to the associated images. For example, the labels for the training set are expected to be in 'train/labels After defining the data configuration, we'll need to write it out to a YAML file:

##### Listing 8.5 Writing the Data Configuration to YAML

```
file_path = 'custom_data.yaml'
    try:
        with open(file_path, 'w') as file:
            yaml.dump(data, file) #A
        print("YAML file has been written successfully.")
    except Exception as e:
        print(f"Error writing YAML file: {e}")
```

With this data configuration YAML file, we can then proceed to train the model!

### 8.1.3 Training the Model

The moment of truth! This is where we put our YOLO model to work. In this code snippet, we're using the Ultralytics library to train our custom YOLO model.

##### Listing 8.6 Writing the Data Configuration to YAML

```
from ultralytics import YOLO
 
model = YOLO('yolov8n.pt') #A
results = model.train( #B
    data='custom_data.yaml',
    imgsz=640,
    epochs=epochs,
    batch=batch,
    name='yolov8n_custom',
    project=project_path) #C
```

In this listing, we're using the YOLO class from ultralytics to initialize and download a pre-trained mode. We then use the `train` method to execute the model training loop.

The `train` method takes several important arguments that we will describe in more detail below:

- `data`: This is the path to our custom data configuration file, which defines the training dataset.
- `imgsz`: This is the size of the input images in pixels. A larger value can help improve accuracy but may also increase computation time.
- `epochs`: We're passing this variable from our pipeline definition, which controls how many iterations we'll run through the training data.
- `batch`: Another variable from our pipeline definition, which determines the number of samples used in each iteration.
- `name`: This is the name we want to give our trained model.
- `project`: This is where all the artifacts generated during model training will be collected. When running this code as a Kubeflow component, this path will be used to store the model weights, plots of confusion matrices and recall and precision curves, and samples of inferences for both train and validation datasets

As the model trains, it generates various inferences during each epoch, which are automatically captured and stored in the project path. This allows us to monitor the model's progress and evaluate its performance at every stage of training. Here's an example:

![Figure 8.1 Examples of inferences during training that are captured automatically](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/08__image001.png)

YOLOv8 comes with a range of pre-trained models, each designed for specific use cases (Figure 8.2). Smaller models like YOLOv8n are ideal for edge devices or real-time applications due to their faster processing speeds and reduced memory requirements. In contrast, larger models offer more accurate results but require more computational resources.

#### Why Model Architecture Matters

When selecting a model for your project, it's essential to consider the trade-off between performance and resource constraints. By choosing the right YOLOv8 model, you can optimize your application's speed, memory usage, and accuracy. For instance:

- If you're developing an AI-powered camera for surveillance, you may prioritize faster processing speeds and reduced memory requirements.
- If you're building a self-driving car system, you may opt for more accurate results despite the increased computational demands.

In either case, understanding the characteristics of YOLOv8 models can help you make informed decisions about which model to use and how to optimize your project's performance.

![Figure 8.2 YOLOv8 in various model sizes along with performance metrics.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/08__image002.png)

For our use case, we'll start with the `nano` version of the model. This has a few advantages:

1. Conserve compute resources: We're minimizing the computational power required to train and run the model, which is especially important if we're working with limited hardware or budget.
1. Test feasibility: By using a smaller model, we can quickly assess whether it's possible to achieve decent results without investing too much time and resources into training a larger model.
1. Iterate and refine: If the nano version doesn't quite meet your expectations, you can use the insights gained from this experiment to inform the development of a larger model that better meets our needs.

#### Hyperparameters in YOLO

When working with YOLOv8 (or any model for that matter), it's essential to understand the various hyperparameters at your disposal. While we'll focus on a subset of these settings in this context, it's crucial to grasp what each parameter does and its default values (where applicable). Ultimately, the choice of which parameters to expose within the training component depends on your specific needs and requirements. Here's a useful starting point:

| <br>      <br>      <br>        Key <br>       <br> | <br>      <br>      <br>        Value <br>       <br> | <br>      <br>      <br>        Description <br>       <br> | <br>      <br>      <br>        Adjustment Considerations <br>       <br> |
| --- | --- | --- | --- |
| <br>     <br>       model <br> | <br>     <br>       None <br> | <br>     <br>       path to model file, i.e. yolov8n.pt, yolov8n.yaml <br> | <br>     <br>       Choose a suitable model architecture and weights based on your specific use case. <br> |
| <br>     <br>       data <br> | <br>     <br>       None <br> | <br>     <br>       path to data file, i.e. coco128.yaml <br> | <br>     <br>       Ensure that the dataset is relevant to your problem, well-annotated, and sufficient for training a robust model. <br> |
| <br>     <br>       epochs <br> | <br>     <br>       20 <br> | <br>     <br>       number of epochs to train for <br> | <br>     <br>       Adjust based on your computational resources and desired level of accuracy. More epochs generally lead to better results but increased processing time. <br> |
| <br>     <br>       batch <br> | <br>     <br>       4 <br> | <br>     <br>       number of images per batch (-1 for AutoBatch) <br> | <br>     <br>       Increase the batch size for faster processing, but be mindful of GPU memory constraints and potential decreased performance due to reduced gradient updates. <br> |
| <br>     <br>       imgsz <br> | <br>     <br>       640 <br> | <br>     <br>       size of input images as integer <br> | <br>     <br>       Choose an image size that balances between object detection accuracy and computational efficiency, depending on your specific use case (e.g., high-resolution images for precise object localization). <br> |
| <br>     <br>       save <br> | <br>     <br>       True <br> | <br>     <br>       save train checkpoints and predict results <br> | <br>      <br>      <br>          <br>       <br> |
| <br>     <br>       project <br> | <br>     <br>       None <br> | <br>     <br>       project name <br> | <br>      <br>      <br>          <br>       <br> |
| <br>     <br>       name <br> | <br>     <br>       None <br> | <br>     <br>       experiment name <br> | <br>      <br>      <br>          <br>       <br> |
| <br>     <br>       exist_ok <br> | <br>     <br>       False <br> | <br>     <br>       whether to overwrite existing experiment (unless you have a very good reason, this is a safe default) <br> | <br>      <br>      <br>          <br>       <br> |
| <br>     <br>       pretrained <br> | <br>     <br>       True <br> | <br>     <br>       (bool or str) whether to use a pretrained model (bool) or a model to load weights from (str) <br> | <br>     <br>       Choose whether to start with a pre-trained model or start from scratch based on your specific use case and available computational resources. Pre-training can provide a good starting point for your model but may require adjustments to achieve optimal performance. <br> |
| <br>     <br>       optimizer <br> | <br>     <br>       'auto' <br> | <br>     <br>       optimizer to use, choices=[SGD, Adam, Adamax, AdamW, NAdam, RAdam, RMSProp, auto] <br> | <br>     <br>       Choose an optimizer that balances between convergence speed and stability, depending on your specific use case (e.g., fast convergence for real-time applications). For 'auto', optimizer selection is dynamic and based on the total number of iterations your training is set to run. <br>      <br>     <br>       Training runs with > 10,000 iterations uses SGD and anything less, AdamW is selected. <br>      <br>      <br>      <br>          <br>       <br> |
| <br>     <br>       verbose <br> | <br>     <br>       False <br> | <br>     <br>       whether to print verbose output <br> | <br>      <br>      <br>          <br>       <br> |
| <br>     <br>       val <br> | <br>     <br>       True <br> | <br>     <br>       validate/test during training <br>      <br>      <br>      <br>          <br>       <br> | <br>      <br>      <br>          <br>       <br> |

### 8.1.4 Creating the Training Component

Now that we have all the ingredients, it's time to put everything together into a single training component. We start with the function signature. The input arguments come from a mixture of pipeline parameters (`epochs`, `batch`, `source_bucket`, `project_path`) and outputs from the split dataset component from the dataset preparation steps.

##### Listing 8.7 Training component taking in parameters and file paths

```
from kfp.components import InputPath, OutputPath
 
def train_model(epochs: int,
                batch: int,
                source_bucket: str,
                x_train_file: InputPath(str), #A
                y_train_file: InputPath(str), #A
                x_test_file: InputPath(str), #A
                y_test_file: InputPath(str), #A
                x_val_file: InputPath(str), #A
                y_val_file: InputPath(str), #A
                yolo_model_name: str,
                project_path: OutputPath(str)): #B
```

Note how the `project_path` is defined as an `OutputPath`. Once training completes, the artifacts would be available in the Output Artifacts section in each Kubeflow Pipeline Run:

![Figure 8.3 Output artifacts can be downloaded from the UI.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/08__image003.png)

Clicking on the link downloads all the model artifacts. We shall use this later to download the trained model weights and test it out locally. Before we do that, let's continue with defining the reset of the `train_model` function.

The next part involves creating local directories to store the images and labels, followed by invoking `download_from_minio` when iterating through the list of input files:

##### Listing 8.8 Downloading images and labels from MinIO

```
def train_model(epochs: int,
                batch: int,
                source_bucket: str,
                x_train_file: InputPath(str),
                y_train_file: InputPath(str),
                x_test_file: InputPath(str),
                y_test_file: InputPath(str),
                x_val_file: InputPath(str),
                y_val_file: InputPath(str),
                yolo_model_name: str,
                project_path: OutputPath(str)):
 
    from minio import Minio
    from minio.error import S3Error
    from tqdm import tqdm
    import os
    import yaml
 
    def download_from_minio(source_bucket, source_object, minio_client, download_path):
        # ...
 
    minio_client = ...
 
    # Create local directories.
    for splits in ["train", "test", "val"]:
        for x in ["images", "labels"]:
            os.makedirs(f"/dataset/{splits}/{x}", exist_ok=True) #A
 
    Xs = [x_train_file, x_test_file, x_val_file]
    Ys = [y_train_file, y_test_file, y_val_file]
 
    for i, splits in enumerate(["train", "test", "val"]):
        # Download image
        with open(Xs[i], "r") as f:
            for source_object in tqdm(f.readlines()):
                source_object = source_object.strip()
                download_path = f"/dataset/{splits}/images/{os.path.basename(source_object)}" 
                download_from_minio(source_bucket, source_object, minio_client, download_path)                                 #B
 
        # Download label
        with open(Ys[i], "r") as f:
            for source_object in f.readlines():
                source_object = source_object.strip()
                download_path = f"/dataset/{splits}/labels/{os.path.basename(source_object)}"
                download_from_minio(source_bucket, source_object, minio_client, download_path)  #C
```

With the files downloaded to the respective paths, the next step is to create the configuration for the dataset. We'll need to ensure that the directory specified by data_yaml_path exists, and if it doesn't, it creates it.

Note that just because we've passed in `data_yaml_path` as an `OutputPath(str)` doesn't mean the folder would exist. The resulting file is passed into the model initialization followed by the actual model training:

##### Listing 8.9 Creating a custom data configuration file and model training

```
def train_model(epochs: int,
    batch: int,
    source_bucket: str,
    yolo_model_name: str,
    ...,
    project_path: OutputPath(str),
    data_yaml_path: OutputPath(str)):                     #A
 
    # previous code ...
    data = {...}
 
    data_yaml_full_path = os.path.join(data_yaml_path, "data.yaml") 
    from pathlib import Path
    Path(data_yaml_path).mkdir(parents=True, exist_ok=True) #B
 
    try:
        with open(data_yaml_full_path, 'w') as file:  
            yaml.dump(data, file)
        print("YAML file has been written successfully.")
    except Exception as e:
        print(f"Error writing YAML file: {e}")
 
    from ultralytics import YOLO
 
    model = YOLO('yolov8n.pt')
 
    results = model.train(...)
```

As a gentle reminder, you are free to include whatever parameters you deem fit for the training component.

Selecting and tuning hyperparameters is an iterative process, so we usually start with the smallest set possible. During experimentation, we can identify opportunities to achieve a more optimal model for our use case by altering hyperparameters from prior training jobs.

For example, if your first trained model does not appear to converge, we can change the learning rate, batch size, or number of epochs to improve performance. This approach allows us to grow the list of parameters as use cases and needs evolve.

Finally, creating the component is exactly the same as we've seen before, but with a slight (and very important!) twist:

As developers, because of muscle memory, we're often tempted to simplify our workflow by installing all dependencies via `requirements.txt`. However, this approach can lead to "dependency hell" - a complex web of package versions that can cause frustration and slow down our development process, and this is often the case for ML libraries. For example, some dependencies require Tensorflow, while another dependency requires a specific version of PyTorch, which conflicts with the previously installed version of OpenCV... you get the idea.

To avoid these issues, it's worth considering the use of pre-packaged Docker containers like Ultralytics' base image. By leveraging these pre-built images, we can save time and effort by not having to manually install dependencies, reducing the likelihood of errors and version conflicts. This approach allows us to focus on building our project without worrying about the underlying infrastructure. So, to make already complicated lives slightly simpler, we'll use `base_image` to use the Ultralytics Docker image and include the remaining dependencies via specifying `packages_to_install`:

##### Listing 8.10 Creating the model training component

```
train_model_task = comp.create_component_from_func(
train_model,                                               base_image="ultralytics/ultralytics:8.0.194-cpu", #A
         packages_to_install=["minio", "tqdm", "pyyaml"])
```

Under the hood, this has the effect of pulling the Ultralytics base image (along with all the dependencies), then running `pip install minio tqdm pyyaml` after. That way, you'll just have to keep track of a much smaller set of dependencies.

### 8.1.5 Creating the Validation Component

As we move forward in our workflow, it's essential to validate our models to ensure they're performing as expected. This step is crucial for understanding how well our models are doing and identifying areas for improvement.

One key concept to grasp here is *outputting metrics*, which is a feature offered by Kubeflow pipelines. By leveraging these facilities, we can gain valuable insights into the performance of our models and make data-driven decisions to refine them. This can come in form of:

- Markdown
- Plots
- Raw values

Before we do the actual validation, just as we did for the training component, we'll need to download the validation dataset from MinIO.

##### Listing 8.11 Downloading the validation dataset

```
from kfp.components import OutputPath
 
def validate_model(project_path: InputPath(str),
                   data_yaml_path: InputPath(str),
                   yolo_model_name: str,
                   source_bucket: str,
                   x_val_file: InputPath(str),
                   y_val_file: InputPath(str),
                   mlpipeline_metrics_path: OutputPath("Metrics")):
    import os
    from minio import S3Error, Minio
    from tqdm import tqdm
 
    def download_from_minio(source_bucket, source_object, minio_client, download_path):
        # ... exactly the same as before.
 
    minio_client = Minio(...)
 
    # Create local directories.
    for x in ["images", "labels"]:
        os.makedirs(f"/dataset/val/{x}", exist_ok=True)
 
    X = x_val_file
    Y = y_val_file
 
    with open(X, "r") as f:
        for source_object in tqdm(f.readlines()):
            source_object = source_object.strip()
            download_path = f"/dataset/val/images/{os.path.basename(source_object)}"
            download_from_minio(source_bucket, source_object, #A 
                                minio_client, download_path)  #A
 
    # Download label
    with open(Y, "r") as f:
        for source_object in f.readlines():
            source_object = source_object.strip()
            download_path = f"/dataset/val/labels/{os.path.basename(source_object)}"
            download_from_minio(source_bucket, source_object, #A
                                minio_client, download_path)  #A
```

When working with the Ultralytics YOLO library, model validation becomes a straightforward process with just one line of code: `model.val()`. While not all libraries may offer such convenience, it's essential to remember that collecting and analyzing model validation metrics is crucial for making informed decisions about your models. By doing so, you can gain valuable insights into your model's performance and identify areas for improvement.

In the next step, we construct the path to our model weights by combining the `project_path` and `yolo_model_name`. Once we have this path, we load the model and pass in the path to the data configuration file. This file should already be downloaded from the previous step, containing the necessary information for accessing the validation dataset.

##### Listing 8.12 Loading the model weights

```
def validate_model(project_path: InputPath(str),                     #A
                   data_yaml_path: InputPath(str),
                   yolo_model_name: str,                             #A
                   source_bucket: str,
                   x_val_file: InputPath(str),
                   y_val_file: InputPath(str),
                   mlpipeline_metrics_path: OutputPath("Metrics")):
 
    from ultralytics import YOLO
    import json
    import os
 
    weights_path = os.path.join(project_path, yolo_model_name, "weights", "best.pt") #B
    print(f"Loading weights at: {weights_path}")
 
    model = YOLO(weights_path) #C
 
    metrics = model.val(
        data=os.path.join(data_yaml_path, "data.yaml")
    )
```

As we continue with our workflow, we'll create `metrics_dict` in a format the Kubeflow expects. This involves constructing a dictionary with a single key-value pair, "`metrics`," which maps to a list of metric objects.

Each metric object is a dictionary within the list. It has three key-value pairs:

- `name`: This is a string representing the name of the metric.
- `numberValue`: This value leverages the supported metrics from the ultralytics package, which provides out-of-the-box utilities for YOLO and potentially other models.
- `format`: This is a string specifying the format of the value. In this case, it's `RAW`or `PERCENTAGE`.

Once we've constructed the dictionary, we write it to `mlpipeline_metrics_path`, which has the type `OutputPath("Metrics")`. This allows us to output our metrics in a format that can be easily consumed by Kubeflow pipelines for further analysis and visualization.

##### Listing 8.13 Loading the model weights

```
def validate_model(project_path: InputPath(str),
                   data_yaml_path: InputPath(str),
                   yolo_model_name: str,
                   source_bucket: str,
                   x_val_file: InputPath(str),
                   y_val_file: InputPath(str),
                   mlpipeline_metrics_path: OutputPath("Metrics")): #A
 
    # ...
    metrics_dict = {                                
        "metrics": [
            {
                "name": "map50-95",               #B
                "numberValue": metrics.box.map,   #B
                "format": "RAW",                  #B
            },
            {
                "name": "map50",
                "numberValue": metrics.box.map50,
                "format": "RAW",
            },
            {
                "name": "map75",
                "numberValue": metrics.box.map75,
                "format": "RAW",
            }]
    }
 
    with open(mlpipeline_metrics_path, "w") as f: #C
        json.dump(metrics_dict, f)                #C
```

#### Data passing between components with OutputPath and InputPath

While developing this example, I stumbled onto a hair-pulling bug that took way too long for me to figure out. Let's focus on `project_path`. Consider the following:

```
train_model_op = train_model_task(...)
validate_model_op = validate_model_task(
    project_path=train_model_op.outputs['project'],
    ...)
```

where the function signature for train_model is what we've seen before:

```
def train_model(project_path: OutputPath(str), ...):
```

Followed by validate_model:

```
def validate_model(project_path: OutputPath(str), ...):
```

Now, what happens if we were to change the type of project_path to a String?

```
def validate_model(project_path: str, ...):
```

The pipeline will compile without complaints. However, when you execute the pipeline, you will see that it fails at the Train model component:

![Figure 8.4 Train model fails with a type change in the input parameter.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/08__image004.png)

Along with a cryptic error message:

![Figure 8.5 Cryptic error message when input parameter's type is wrong.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/08__image005.png)

The `copy_file_range: is a directory` error message means that the destination specified in the copy operation is a directory, not a regular file. If we inspect the logs, there's a similar error message:

failed to copy /tmp/outputs/project/data to /var/run/argo/outputs/parameters//tmp/outputs/project/data: write /var/run/argo/outputs/parameters//tmp/outputs/project/data: copy_file_range: is a directory

Bottom line is, if ever you hit into a similar error, check the types of the parameters if you are using the same one for both output and input, and hopefully this saves you hours of hair pulling!

The final step in this section is to create the component. We'll still use the Ultraytics base image, and we'll require both `minio` and `tqdm` as package dependencies:

##### Listing 8.14 Creating the validate model component

```
validate_model_task = comp.create_component_from_func(
validate_model,
base_image="ultralytics/ultralytics:8.0.194-cpu", #A 
packages_to_install=["minio", "tqdm"])            #B
```

Now that we have all the ingredients, it's time to stitch everything together in a pipeline.

### 8.1.6 Creating the Pipeline

In the initial steps of our workflow, we create essential components from the two functions we defined earlier: `download_ task` and `split_dataset_task`. We then leverage these components to construct crucial parts of our pipeline.

To proceed, we use the `comp.create_component_from_func()` function to convert the train_model and validate_model functions into pipeline tasks. This process involves specifying specific details for each component:

##### Listing 8.15 Add the train and validate model components to the pipeline

```
download_task = ...
split_dataset_task = ...
 
train_model_task = comp.create_component_from_func(        #A 
          train_model,
 base_image="ultralytics/ultralytics:8.0.194-cpu",
          packages_to_install=["minio", "tqdm", "pyyaml"])
 
validate_model_task = comp.create_component_from_func(     #B
validate_model,
base_image="ultralytics/ultralytics:8.0.194-cpu",
packages_to_install=["minio", "tqdm"])
```

For the train_ model_task, we provide additional parameters such as:

- The base image ("`ultralytics/ultralytics:8.0.194-cpu`"), which will be used to create the container for this task.
- A list of packages to install (`["minio", "tqdm", "pyyaml"]`), which are required dependencies for this component.

For the validate_model_task, we also specify:

- The base image ("`ultralytics/ultralytics:8.0.194-cpu`"), similar to the previous task.
- A list of packages to install (`["minio", "tqdm"]`), which are required dependencies for this component.

The next step is to define the pipeline.

The arguments in the `@dsl.pipeline` decorator are used in the Kubeflow Pipelines user interface. The `name` argument sets the title of the pipeline in the UI while the `description` argument provides additional information about the pipeline, visible in the pipeline's details view.

This time, we'll also introduce a few more pipeline parameters, such as epochs, batch size, name of the YOLO model etc.

##### Listing 8.16 Additional parameters for the object detection pipeline

```
@dsl.pipeline(name="YOLO Object Detection Pipeline", 
              description="YOLO Object Detection Pipeline")
def pipeline(epochs: int = 1, ]
             batch: int = 8,  
             source_bucket="dataset",
             random_state=42,
             yolo_model_name="yolov8n_custom.pt"):
```

In this pipeline definition, we're setting up the data dependencies by passing the outputs from the `split_dataset_op` to the `train_model_op`. However, there's an important note to keep in mind. The `project_path` is being passed as an input to the `validate_model_op`, but the key in the output dictionary of the `train_model_op` is actually `project`, not `project_path`. This means that we need to use the correct key when accessing the project path.

This pipeline definition sets up a workflow that downloads data, splits it into training and validation datasets, trains a YOLO model using the training data, validates the trained model using the validation data, and outputs the model metrics. The `epochs`, `batch`, `source_bucket`, `random_state`, and `yolo_model_name` parameters can be adjusted to fine-tune the pipeline for specific use cases.

##### Listing 8.17 Connecting the train and validation components

```
def pipeline(...):
    download_op = download_task(...)
    split_dataset_op = split_dataset_task(...).after(download_op)
 
    train_model_op = train_model_task(
        epochs=epochs,
        batch=batch,
        source_bucket="dataset",
        x_train=split_dataset_op.outputs['x_train'],
        y_train=split_dataset_op.outputs['y_train'],
        ...,
        yolo_model_name=yolo_model_name,
    )
 
    validate_model_op = validate_model_task(
        project_path=train_model_op.outputs['project'],
        yolo_model_name=yolo_model_name,
    ).after(train_model_op)        #A
 
if __name__ == '__main__':
    kfp.compiler.Compiler().compile(
        pipeline_func=pipeline,
        package_path='pipeline.yaml',
    )
```

This goes back to the rules that govern Input and Output parameters covered in the previous chapter. What happens if you accidentally use `project_path` instead? You'll receive a `KeyError`, such as:

##### Listing 8.18 Remember the Input/Output parameter rules!

```
Traceback (most recent call last):
  File "/Users/benjamintan/workspace/object-detection-project/training_and_validation_pipeline.py", line 54, in <module>
    kfp.compiler.Compiler().compile(
...
    pipeline_func(*args_list, **kwargs_dict)
  File "/Users/benjamintan/workspace/object-detection-project/training_and_validation_pipeline.py", line 48, in pipeline
    project_path=train_model_op.outputs['project_path'],  
KeyError: 'project_path' #A
```

The next bit is to compile the pipeline, re-upload it, and execute the pipeline.

### 8.1.7 Executing the Pipeline

By now, you should know how to create a Kubeflow pipeline run. Notice that how the Run Parameters are pre-populated based on the default pipeline parameters you've defined earlier (Figure 8.6):

![Figure 8.6 Run parameters get populated based on the pipeline parameters.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/08__image006.png)

The resulting topology of the pipeline highlights the data dependencies between components:

![Figure 8.7 Topology of the newly uploaded pipeline.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/08__image007.png)

If you are using the dataset provided, one epoch takes around 1 hour on our Kubernetes cluster. Of course, your mileage may vary, but it's always good to get a sense of how long things will take. The Ultralytics library outputs quite a bit of information during model training such as:

1. Model architecture, including a mode summary that includes the total number of layers and parameters
1. Training setup, such as using pre-trained weights and which optimizer is used
1. Dataset information, such as number of images, number of corrupted images
1. Training progress, such as the current epoch, how much GPU memory is being used, loss metrics, evaluation metrics such as mAP (mean Average Precision)
1. Training speed, such as time per training step and the estimated time remaining

![Figure 8.8 Keep track of training progress with the logs.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/08__image008.png)

The following diagram is what all of us are waiting for, a successful execution of all the components. Notice once again the data dependencies being represented. There's a parameter (`source_bucket`) from the Split dataset component that is used in "Validate model" which is why there's a connection:

![Figure 8.9 Successful pipeline run with training and validation components](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/08__image009.png)

Clicking on the "Run output" tab lets you see the metrics:

![Figure 8.10 Metrics gets displayed as part of the Run output in the UI.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/08__image010.png)

Which is you can reference in the Output artifacts:

![Figure 8.11 Same metrics can be viewed in raw form under Output artifacts.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/08__image011.png)

Speaking of output artifacts, now it's a perfect time to put them to good use! In the next section, you'll download the artifacts generated during model training and load the trained YOLO model weights locally. Finally, if you go to the pipelines overview page, you'll see that the metrics are now listed.

![Figure 8.12 Metrics are now displayed with all the previous pipeline runs](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/08__image012.png)

In the next section, you'll learn how saving the model artifacts can be very useful. One use case for this is to load the trained model weights (done in Kubeflow) on your local machine.

### 8.1.8 Trying Out the Weights Locally

It is very important to convince yourself that the model works. Just like the proverb: Trust, but *verify*. We have had many encounters where models were handed to us to operationalize but much later on we discovered that they were not working.

Let's first try running the inference with a model that has not been trained to detect identity cards. Instead, we're using whatever objects that the generic pretrained YOLO model was trained with.

The following listing uses the default YOLO model. Looking at the file name (yolov8**n**) means that we're using the nano version, which is the same architecture as the model that we trained. We'll create a folder called `samples` and place a bunch of sample images, ideally ones that the model was not trained with as we would with any test set. For each image in the directory, we feed it into the model, and display the results. Press any key to go to the next image, assuming you have more than one in the directory.

##### Listing 8.19 Run inference with the default nano model

```
import glob
import cv2
from ultralytics import YOLO
 
model = YOLO("yolov8n.pt") #A
for file in glob.glob("samples/**.jpg"): #B
    result = model(cv2.imread(file))
    res_plotted = result[0].plot() #C
    cv2.imshow("result", res_plotted) #D
    cv2.waitKey(0)
```

Once you run the code, you'll see results such as:

![Figure 8.13 Detections without training on the default YOLO model.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/08__image013.png)

Right off the bat, you can observe a few things. The model:

- Was able to detect faces and classified them as person
- Classified the id card as a book, although with a low confidence

When examining the output of object detection models, you'll notice numeric values associated with each detected object. These numbers represent the model's confidence score for each detection, ranging from 0 to 1. A score closer to 1 indicates higher confidence, while a score closer to 0 suggests lower confidence.

For instance, in the image of the driver's license, we see a "book" detection with a confidence of 0.28, indicating relatively low certainty. In contrast, the larger "person" detection has a much higher confidence of 0.79, suggesting the model is quite sure about this identification. These confidence scores are crucial for understanding the reliability of each detection and can be used to filter out less certain predictions if needed for your specific application.

While it misclassified the card as a book, it still managed to wrap the bounding box correctly. Now, let's switch up the model weights to use the ones we've trained with the Kubeflow pipeline. When you have a successful pipeline run, go to the Output Artifacts section to download the Tar archive of named *project*:

![Figure 8.14 Project shows up as an output artifact that contains model training artifacts.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/08__image014.png)

Uncompress the archive and locate `best.pt`. Copy that file to a convenient location. Replace the location with `best.pt`and re-run the code:

##### Listing 8.20 Run with the best trained weights

```
import glob
import cv2
from ultralytics import YOLO
 
model = YOLO("weights/best.pt") #A
 
for file in glob.glob("samples/**.png"):
    result = model(cv2.imread(file))
    res_plotted = result[0].plot()
    cv2.imshow("result", res_plotted)
    cv2.waitKey(0)
```

To prove that model training does indeed work, here is the result from just one epoch of model training:

![Figure 8.15 Promising results even with just one epoch of training](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/08__image015.png)

While the results are certainly not perfect, it certainly is promising! The bounding box isn't great, but at least it wraps around most of the card. More importantly, it classified the identity correctly too!

Now, with a little bit more training (around 5 epochs), we were able to get much better results! Not only is the bounding box completely covering the identity card, but the confidence is also decent. This is because additional training allows us to refine our model's performance by fine-tuning its weights and biases.

#### Why More Epochs Matter

By adding more epochs to our training process, we can expect to see improvements in several key areas:

- Model accuracy: With more training data, our model becomes better at recognizing patterns and making accurate predictions.
- Confidence: As our model sees more examples of the target class (in this case, identity cards), it becomes more confident in its detections.
- Robustness: By exposing our model to a larger dataset, we can help it develop robustness against varying conditions, such as different lighting or angles.

In this case, adding just 5 epochs resulted in significant improvements. However, the exact number of epochs required will depend on the complexity of your dataset and the specific requirements of your project.

![Figure 8.16 Better detections with just a little bit more training](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/08__image016.png)

You might be wondering how many epochs you should set. Thankfully, the Ultralytics YOLO library will automatically store the best performing weights. Therefore, the best weights might be available at epoch 4 based on the model performance on the validation set, and if you set 10 epochs, then `best.pt` would refer to the weights created at epoch 4. Of course, the reverse is not true! If you set too low an epoch, `best.pt` might not be the best performing weights.

One last point: Once you have convinced yourself that the model works, you should then think about how to automate this. Right from the get-go, you should be able to think about how to programmatically ensure that for a given dataset, confidence should be above a certain threshold, and bounding box coordinates are reasonable too. You will not be able to put an exact value, hence you'll need to set a certain tolerance.

Until now, we have gone through most of the basics to train a model and try out the inference. In the next chapter, we will dive a bit more into making the training process a bit more production ready. We will take a look at VolumeOps, more efficient way to handle large datasets, spend some time investigating tensorboard for pipeline runs and finally into model registries and experiment tracking with MLFLow.

## 8.2 Summary

- Getting training data to a model can be solved in a few ways. Any method you choose must lend itself to version control and lineage.
- Kubeflow offers a few ways of accessing downloads that we have discussed in this chapter. Among others, we discussed direct downloads and stream reads.
- It is important to keep the requirements and acceptable limitations of the final model in mind while deciding on a model architecture. No matter how good the public metrics for a model are, if you do not understand the tradeoffs with respect to requirements, we will face problems down the road.
- Data access and passing is important to keep in mind while writing the training code. Always assuming local access is not the best idea while creating training codebases that need to be deployed into automated pipelines.
- Metrics and, more importantly, the visibility of metrics are a key criterion for success in large organizations and/or teams that employ training pipelines at scale. Having a convenient place like the kubeflow dashboard to quickly visualize pipeline metrics goes a long way in reducing feedback loops and promotes collaboration.
- An aspect of automation that is not often discussed is the ability to quickly run a sanity test on a given model’s output weights. Keeping this in mind while designing dataflows and model storage strategies helps ease debugging and dashboard workflows later on.
