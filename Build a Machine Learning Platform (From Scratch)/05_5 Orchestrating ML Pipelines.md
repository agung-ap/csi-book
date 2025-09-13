# 5 Orchestrating ML Pipelines

### This chapter covers

- Building batch pipeline for model inference using Kubeflow pipelines

In the last chapter, we discussed how MLFlow and Feast can be used to make machine learning experiments more reliable. In this chapter, we extend that by orchestrating ML pipelines in Kubeflow. Kubeflow pipelines are a powerful tool that can help you build, deploy, and manage machine learning pipelines.

We start by diving into why orchestration is important and the capabilities of kubeflow pipelines. We then move into building reusable components that can then be combined together to create a pipeline. Through the chapter we will build components to handle an example income classification task. We will then put all the components together and form a cohesive pipeline that classifies income data.

## 5.1 Kubeflow Pipeline, The Task Orchestrator

Most machine learning inference pipelines have a common structure, we need to retrieve data from somewhere (object store, data warehouse, file system), pre-process that data, retrieve or load a model, and then perform inference. The inferences are then written to a database or uploaded to some cloud storage. A pipeline needs to run periodically, and we may need to provide some runtime parameters to it like date/time, feature table name, etc. All of this is possible using Kubeflow pipelines.

Kubeflow pipelines help us in building ML pipelines, it provides an SDK in the form of a friendly Python package - kfp which we can use to define our pipelines.

In this section, we will first define the pipeline steps (or components) and we will then combine all the components to arrive at a Kubeflow pipeline. Let us start with the components.

### 5.1.1 Kubeflow Components

In the last chapter, we were able to train a model and register the necessary features in the feature store. Now it's time to perform model inference. We will create a Kubeflow pipeline that will do the following:

1. Read data from MinIO which has a list of user IDs
1. Retrieve features for the list of User IDs
1. Retrieve the model and perform inference
1. Write the data back to MinIO

Each of the aforementioned tasks can be converted into a Kubeflow pipeline component. A component is a reusable and composable unit of work within a machine learning (ML) workflow. These components encapsulate individual tasks or steps that perform specific actions, such as data preprocessing, model training, evaluation, deployment, and more. By breaking down a workflow into components, we can create modular and maintainable ML pipelines. In the upcoming sub-sections, we will build these components and combine them to form our pipeline.

#### Read Data Component

Each Kubeflow component is executed in a single Kubernetes Pod (Chapter 3.2.3). A Kubernetes pod needs a container to execute. So, to build our component, we need to build an image with our component source code. Let us start by building the read data component. We start with `read_data.py` which holds instructions on how to read data from MinIO. This is a normal Python file where we first define the MinIO client by using the host, access key, and secret key. We then use the client to retrieve our user ID file and convert it into a Pandas dataframe.

##### Listing 5.1 Read data component

```
123456789101112131415161718192021222324from kfp.components import OutputPath
import argparse
from minio import Minio
import pandas as pd
from pathlib import Path
 
def get_data(
    minio_host: str,
    access_key: str,
    secret_key: str,
    bucket_name: str,
    file_name: str,
    data_output_path: OutputPath(),
):
    client = Minio(
        minio_host,
        access_key=access_key,
        secret_key=secret_key,
    )
    obj = client.get_object(
        bucket_name,
        file_name,
    )
    df = pd.read_csv(obj)
```

This Pandas dataframe output needs to be written somewhere so that it can be retrieved or used by the next component. This is where we need to use the Kubeflow component, `OutputPath`. The `OutputPath` is a location in the pipeline artifact store (In Our Case MinIO) where we will store this file. When we write it to the `OutputPath` we can also reuse this file in the successive components of a pipeline. To do so we first need to create the output path directory using mkdir and then write the dataframe to the output path directory.

```
12Path(data_output_path).parent.mkdir(parents=True, exist_ok=True)
df.to_pickle(data_output_path)
```

We then define the main block in our read_data.py file so that we can pass the arguments to our `get_data` function, we use argparse for defining our arguments. Take note that we are also passing `data_output_path` as an argument.

##### Listing 5.2 Main block of read data component

```
123456789101112131415161718192021def main():
    parser = argparse.ArgumentParser(description="Arguments for fetching data from url")
    parser.add_argument("--minio_host", type=str)
    parser.add_argument("--access_key", type=str)
    parser.add_argument("--secret_key", type=str)
    parser.add_argument("--bucket_name", type=str)
    parser.add_argument("--file_name", type=str)
    parser.add_argument("--data_output_path", type=str)
    args = parser.parse_args()
 
    get_data(
        minio_host=args.minio_host,
        access_key=args.access_key,
        secret_key=args.secret_key,
        bucket_name=args.bucket_name,
        file_name=args.file_name,
        data_output_path=args.data_output_path,
    )
 
if __name__ == "__main__":
    main()
```

We now have our Python Code which can read data from MinIO and write it to the pipeline artifact store. We need to containerize this code and we do that by building a Docker image, for which we have to write a Dockerfile. The Dockerfile starts with the base image python 3.10, We set a working directory /app and install build-essential along with cleaning up our temp directories. We then copy over our requirements.txt to a location in the working directory and install those requirements. This requirement includes all the dependencies that are needed by our component. We then copy our source code into the working directory.

##### Listing 5.3 Component Dockerfile

```
123456789101112FROM python:3.10-slim-buster
WORKDIR /app
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
    build-essential \
    && apt-get clean && rm -rf /tmp/* /var/tmp/*
 
COPY requirements.txt /app/requirements.txt
RUN pip3 install --upgrade pip
RUN pip3 install --no-cache-dir -r requirements.txt
ENV PYTHONPATH "/app"
COPY . /app
```

Our directory structure would now look like this. We have defined our `read_data.py` components under src/read_data. Our Dockerfile is present in the root of the directory.

```
├── Dockerfile
└── src
    └── read_data
        └── read_data.py
```

We will then build our Docker image by using the Docker build command and replace the Docker ID with your Docker ID.

```bash
docker build . -t <docker_id>/read-minio-data:latest
```

We will then push this Docker image to the container registry by using the Docker push command.

```bash
docker push <docker_id>/read-minio-data:latest
```

We have now written our component code and containerized it. The next step is to define the Kubeflow component specification file. This is similar to defining a Kubernetes object in this case the object is a Kubeflow component object. Like all Kubernetes objects, we start with a yaml file which will hold the component definition.

`read_data component.yaml` will start with a name and description of the component. We then specify the inputs and outputs of the components along with their data types. Take note of that in the component.yaml we have defined the `data_output_path` under outputs with the data type `OutputPath`. We then specify the Docker image file name and the command we need to run to read data. In this case, the command is executing the Python file `read_data.py`. We also provide the necessary arguments for the component’s execution, the values for these arguments are retrieved from pre-defined inputs and outputs.

##### Listing 5.4 Read component definition file

```
name: Read Data From Minio
description: Fetches data from MinIO
inputs:    #A
- {name: minio_host, type: String}
- {name: access_key, type: String}
- {name: secret_key, type: String}
- {name: bucket_name, type: String}
- {name: file_name, type: String}
outputs:    #B
- {name: data_output_path, type: OutputPath}
implementation:
    container:
      image: 'varunmallya/read-minio-data:latest'    #C
      command: [python3, /app/src/read_data/read_data.py,
                --minio_host, {inputValue: minio_host},
                --access_key, {inputValue: access_key},
                --secret_key, {inputValue: secret_key},
                --bucket_name, {inputValue: bucket_name},
                --file_name, {inputValue: file_name},
                --data_output_path, {outputPath: data_output_path}    #D
      ]
```

We have now defined our component which is ready to be used in a Kubeflow pipeline.To build this component we did the following

1. We started by writing what the component does in a Python file.
1. Containerized it using Docker
1. Wrote a component specification in component.yaml.

Our directory structure with the component specification looks like this:

```
├── Dockerfile
├── components
│   └── read_data
│       └── component.yaml
└── src
    └── read_data
        └── read_data.py
```

We will now define the other components of the pipeline similarly, the component code goes under src directory, and the component definition yaml goes under the component directory. The next component will be the feature retrieval component.

#### Feature Retrieval Component

The feature retrieval component will be used to retrieve features from the Feature store. We will start by writing the Python code for this in `retrieve_features.py`. We initialize the feature store object by downloading the feature_store.yaml file from MinIO. We then retrieve the historical features using `get_historical_features` which needs an entity data frame and a list of features, both of which are inputs to the components. The entity_df data type is InputPath which indicates to Kubeflow that it is a placeholder for our input file and the component can read it during a pipeline run.

##### Listing 5.5 Feature retrieval component

```
def get_features(
    minio_host: str,
    access_key: str,
    secret_key: str,
    bucket_name: str,
    file_name: str,
    entity_df_path: InputPath(),
    feature_list: str,
    data_output_path: OutputPath(),
):
    store = init_feature_store(
        minio_host, access_key, secret_key, bucket_name, file_name
    )    #A
    feature_list = feature_list.split(",")    #B
    entity_df = pd.read_pickle(entity_df_path)    #C
    feature_df = store.get_historical_features(
        entity_df=entity_df,
        features=feature_list,
    ).to_df()
    Path(data_output_path).parent.mkdir(parents=True, exist_ok=True)
    feature_df.to_pickle(data_output_path)    #D
```

We supply the arguments to this function via the main block. We then proceed to containerize it by building and pushing the image to the container registry. The Dockerfile does not need any modifications as we are just copying the new file (retrieve_features.py) into the working directory. However, we do need to update the requirements.txt with the dependencies for Feast. We can name the Docker image as retrieve-feast-features.

The last step is defining the component.yaml. We specify the inputs and outputs of the component after naming it and giving it an appropriate description. Under container, we specify the image name and command. The `entity_df_path` data type is an OutputPath but it is listed under `inputs`. When we use this input for the command’s argument, we specify it as `inputPath` to indicate that the file path would be an input.

##### Listing 5.6 Feature retrieval component definition file

```
name: Retrieve Features From Feast
description: Retrieves Features from Feast where the feature_store yaml is stored in MinIO
inputs:
- {name: minio_host, type: String}
- {name: access_key, type: String}
- {name: secret_key, type: String}
- {name: bucket_name, type: String}
- {name: file_name, type: String}
- {name: entity_df_path, type: OutputPath}    #A
- {name: feature_list, type: String}
 
outputs:
- {name: data_output_path, type: OutputPath}    #B
implementation:
    container:
      image: 'varunmallya/retrieve-feast-features:latest'
      command: [python3, /app/src/retrieve_features/retrieve_features.py,
                --minio_host, {inputValue: minio_host},
                --access_key, {inputValue: access_key},
                --secret_key, {inputValue: secret_key},
                --bucket_name, {inputValue: bucket_name},
                --file_name, {inputValue: file_name},
                --entity_df_path, {inputPath: entity_df_path},    #C
                --feature_list, {inputValue: feature_list},
                --data_output_path, {outputPath: data_output_path}    #D
      ]
```

This component will give us our features, after which we are in a position to run predictions. For this, we will need our next component, the inference component.

#### Inference Component

The next step after retrieving features is to generate predictions using the income classifier model. But where is our model? The model is defined in the MLflow model registry. This component should retrieve the model from MLflow and generate predictions using the features obtained from the last component. We will write the code that holds this logic in a Python file (`run_inference.py`). The MLflow client is initialized and is used to retrieve the model URI. This URI is then used to retrieve the model. An appropriate MLflow method depending on the model’s framework (sklearn, xgboost, tensorflow etc) is used to load the model. Once loaded we run the`model.predict_proba` to retrieve predictions which are written to a separate column. The whole file is then written to the output path.

##### Listing 5.7 Inference component

```
def perform_inference(
    model_name: str,
    model_type: str,
    model_stage: str,
    mlflow_host: str,
    input_data_path: InputPath(),
    data_output_path: OutputPath(),
):
    mlflow.set_tracking_uri(mlflow_host)
    mlflow_client = MlflowClient(mlflow_host)    #A
    for model in mlflow_client.search_model_versions(f"name='{model_name}'"):    #B
        if model.current_stage == model_stage:
            model_run_id = model.run_id
    input_data = pd.read_pickle(input_data_path)    #C
    if model_type == "sklearn":    #D
        model = mlflow.sklearn.load_model(
            model_uri=f"models:/{model_name}/{model_stage}" 
        )
    elif model_type == "xgboost":
        model = mlflow.xgboost.load_model(
            model_uri=f"models:/{model_name}/{model_stage}"
        )
    elif model_type == "tensorflow":
        model = mlflow.tensorflow.load_model(
            model_uri=f"models:/{model_name}/{model_stage}"
        )
    else:
        raise NotImplementedError
 
    predicted_classes = [x[1] for x in model.predict_proba(input_data)]    #E
    input_data["Predicted_Income_Class"] = predicted_classes
    Path(data_output_path).parent.mkdir(parents=True, exist_ok=True)
    input_data.to_pickle(data_output_path)    #F
```

We will name this Docker image run-inference and build and push it to the container registry that holds this code. We can now define our component.yaml with the appropriate inputs and outputs. Again keep note of the data types of input and output paths of data. When defining the inputs and outputs of the component, the path will be of type OutputPath i.e `input_data_path` and `data_output_path` are both of type `OutputPath`. However, when defining these inputs and outputs in the command we must use `inputPath` `(--input_data_path`, {`inputPath: input_data_path`}) and outputPath (`--data_output_path`, {`outputPath: data_output_path`}) for input and output data respectively.

##### Listing 5.8 Inference component definition file

```
name: Model Inference
description: Run model inference after retreving model from MLflow
inputs:
- {name: model_name, type: String}
- {name: model_type, type: String}
- {name: model_stage, type: String}
- {name: mlflow_host, type: String}
- {name: input_data_path, type: OutputPath}
 
outputs:
- {name: data_output_path, type: OutputPath}
implementation:
    container:
      image: 'varunmallya/run-inference:latest'
      command: [python3, /app/src/run_inference/run_inference.py,
                --model_name, {inputValue: model_name},
                --model_type, {inputValue: model_type},
                --model_stage, {inputValue: model_stage},
                --mlflow_host, {inputValue: mlflow_host},
                --input_data_path, {inputPath: input_data_path},
                --data_output_path, {outputPath: data_output_path}
      ]
```

Our predictions are finally written back to MinIO by using the write data component.

#### Write Data Component

Similar to the read data component, we will initialize the MinIO client and write a parquet file to a MinIO bucket. We write the code in write_data.py.

##### Listing 5.9 Write component

```
from kfp.components import OutputPath, InputPath
import argparse
from minio import Minio
import pandas as pd
from pathlib import Path
 
def write_data(
    minio_host: str,
    access_key: str,
    secret_key: str,
    bucket_name: str,
    file_name: str,
    input_data_path: InputPath(),
):
    client = Minio(
        endpoint=minio_host, access_key=access_key, secret_key=secret_key, secure=False
    )
    input_data = pd.read_pickle(input_data_path)
    input_data.to_parquet(file_name, index=False)
    client.fput_object(bucket_name, file_name, file_name)
```

We also write a component definition file, the input to the component is the run inference component’s output

##### Listing 5.10 Write component definition file

```
name: Write Data To Minio
description: Writes data back to MinIO
inputs:
- {name: minio_host, type: String}
- {name: access_key, type: String}
- {name: secret_key, type: String}
- {name: bucket_name, type: String}
- {name: file_name, type: String}
- {name: input_data_path, type: OutputPath}
 
implementation:
    container:
      image: 'varunmallya/write-minio-data:latest'
      command: [python3, /app/src/write_data/write_data.py,
                --minio_host, {inputValue: minio_host},
                --access_key, {inputValue: access_key},
                --secret_key, {inputValue: secret_key},
                --bucket_name, {inputValue: bucket_name},
                --file_name, {inputValue: file_name},
                --input_data_path, {inputPath: input_data_path}
      ]
```

We have now defined all the components necessary for our basic inference pipeline. The complete directory structure now looks like

```
── Dockerfile
├── components
│   ├── read_data
│   │   └── component.yaml
│   ├── retrieve_features
│   │   └── component.yaml
│   ├── run_inference
│   │   └── component.yaml
│   └── write_data
│       └── component.yaml
├── requirements.txt
└── src
    ├── read_data
    │   └── read_data.py
    ├── retrieve_features
    │   └── retrieve_features.py
    ├── run_inference
    │   └── run_inference.py
    └── write_data
        └── write_data.py
```

The pipelines interaction with MinIO, Feast and MLFlow can be seen in the below figure (Figure 5.1)

![Figure 5.1 Kubeflow pipeline interactions with MinIO, Feast and MLFlow. All of the intermediate datasets are stored in MinIO to be retrieved by subsequent steps. The model and features are retrieved from MinIO and Feast respectively.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/05__image001.png)

These components are generic enough to be used for multiple pipelines, which helps us standardize ML workflows across the team and the organization.

While designing components we should keep the following points in mind

- **Modularity** - We should try our best to ensure they follow the single responsibility principle. Which states that it should perform only one function. This promotes code reusability and makes it easier to maintain and update individual components. In our example we separated inference task and write data task.
- **Component Inputs and Outputs**: Each component's inputs and outputs should be specified in detail. Define the inputs and outputs that the component requires, such as the data or artifacts that it generates. We specify the input and outputs in the component.yaml of each of our components.
- **Parameterization**: Allow for parameterization of components. Parameters can be used to customize the behavior of a component without modifying its code. This is especially useful for hyperparameters, file paths, and configuration settings. In our example we have set parameters for mlflow_host, bucket_name and minio_host instead of hardcoding these values, such that they can be used in other environments too.
- **Documentation**: Clearly describe each component's function, inputs, outputs, and usage in the documentation. Include illustrations and usage instructions to help other team members comprehend and efficiently use the component.

Well-designed components help us in multiple ways.

- **Reusability**: Components can be utilized in different pipelines after being defined. As a result, development practices become more effective because there is less duplication of code and work. Teams can keep a collection of standardized parts that can be used on numerous projects.
- **Collaboration**: This is made possible by components amongst data scientists, machine learning engineers, and subject matter experts. The ability for different team members to work on distinct pipeline components enables concurrent development and specialization in diverse machine learning domains.
- **Testing**: Components can be tested separately, streamlining debugging. The complexity of troubleshooting within a complete pipeline is reduced by isolating problems to certain components, which makes it simpler to recognize and fix faults.

In the next section, we will integrate all our components into a Kubeflow pipeline.

### 5.1.2 Income Classifier Pipeline

A Kubeflow pipeline describes the entire ML workflow. The components are represented in a directed acyclic graph (DAG). A DAG has that edges have direction, meaning they go from one node to another, and there are no cycles, which means there are no closed loops in the graph. We can specify a order in which tasks are executed and enforce dependencies between tasks if needed i.e a task will run only when its dependent tasks have completed. We will build a Kubeflow pipeline using the previously defined components.

A Kubeflow pipeline similar to the components is a Python file which we will name as income-classifier-pipeline.py. We will first define all the components by using kfp provided `load_component_from_file` function which will create the component object. This function expects the path to the component file. This results in three components named `fetch_data_op`, `retrieve_features_op` and `run_inference_op`.

##### Listing 5.11 Income classifier Kubeflow pipeline

```
import kfp.dsl as dsl
from kfp.compiler import Compiler
import kfp.components as comp
fetch_data_op = comp.load_component_from_file(
    "components/read_data/component.yaml"
)  # A
retrieve_features_op = comp.load_component_from_file(
    "components/retrieve_features/component.yaml"
)
run_inference_op = comp.load_component_from_file(
    "components/run_inference/component.yaml"
)
 
write_data_op = comp.load_component_from_file("components/write_data/component.yaml")
@dsl.pipeline(
    name="income-classifier-pipeline",
    description="A Kubeflow pipeline to classify income categories",
)
```

Once the components are defined we define the pipeline function - `income_classifier_pipeline`. This function’s parameters are the pipeline parameters. These are the parameters whose values can be modified during runtime.

```
def income_classifier_pipeline(
    minio_host: str = "",
    access_key: str = "",
    secret_key: str = "",
    entity_df_bucket: str = "",
    entity_df_filename: str = "",
    feature_store_bucket_name: str = "",
    feature_store_config_file_name: str = "",
    feature_list: str = "",
    model_name: str = "",
    model_type: str = "",
    model_stage: str = "",
    mlflow_host: str = "",
    output_bucket: str = "",
    output_file_name: str = "",
):
```

We then proceed to use our pre-defined components to define our task. This is simply populating the input fields of the component, and these input values are retrieved from the pipeline parameters. For example, in fetch data component requires MinIO specifications along with the entity dataframe location. All of this is passed via the pipeline parameters. The three components will have three tasks respectively - `fetch_data_task`, `retrieve_features_task`, and `run_inference_task`. But what about component interconnectivity? How does the output of the fetch data component become the input of the retrieve feature component? Kfp provides a simple way to do this: we simply use `task.output`to retrieve the output of the task which can then be fed to the input. For example, the `retrieve_features_task` has an input called `entity_df_path` which is the output of `fetch_data_task` or as specified in the pipeline `fetch_data_task`.`output`. By doing this, Kubeflow understands that the retrieve_features_task depends on fetch_data_task completion. The same goes for the `run_inference_task` which depends on the completion of `retrieve_features_task` where `input_data_path` is the output of `retrieve_features_task`.

```
fetch_data_task = fetch_data_op(
        minio_host=minio_host,
        access_key=access_key,
        secret_key=secret_key,
        bucket_name=entity_df_bucket,
        file_name=entity_df_filename,
    ) 
 
    retrieve_features_task = retrieve_features_op(
        minio_host=minio_host,
        access_key=access_key,
        secret_key=secret_key,
        bucket_name=feature_store_bucket_name,
        file_name=feature_store_config_file_name,
        entity_df_path=fetch_data_task.   , 
        feature_list=feature_list,
    )
 
    run_inference_task = run_inference_op(
        model_name=model_name,
        model_type=model_type,
        model_stage=model_stage,
        mlflow_host=mlflow_host,
        input_data_path=retrieve_features_task.output,
    )
    run_inference_task.container.set_image_pull_policy("Always")
 
    write_data_task = write_data_op(
        minio_host=minio_host,
        access_key=access_key,
        secret_key=secret_key,
        bucket_name=output_bucket,
        file_name=output_file_name,
        input_data_path=run_inference_task.output,
    )
```

We can also define some default values for the pipeline parameters as part of the parameter definition. Once we have our pipeline function in place, we would need to compile it to a yaml file which can be fed to Kubeflow. Kfp provides a compiler that will translate our pipeline function into a yaml called`income_classifier_pipeline.yaml`.

```
Compiler().compile(
    income_classifier_pipeline,
    "income_classifier_pipeline.yaml",
)
```

The `income_classifier_pipeline.yaml` can then be uploaded to the Kubeflow pipeline UI. To do so login to Kubeflow, click on Pipelines in the sidebar, and then click the upload pipeline button (Figure 5.2)

![Figure 5.2 Kubeflow pipeline UI which lists out all the pipelines in our account.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/05__image003.png)

We then need to enter the pipeline details which include the name and description. We then need to specify the file path of our compiled i`ncome_classifier_pipeline.yaml`. To create the pipeline, we then click on create (Figure 5.3)

![Figure 5.3 Kubeflow pipeline UI to create a pipeline. Need to provide a pipeline name and upload the pipeline yaml file.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/05__image005.png)

This gives us the pipeline visualization (Figure 5.4). To run this pipeline we need to

1. Create an experiment
1. Create a run

![Figure 5.4 Pipeline visualized by the Kubeflow pipeline UI after we upload it.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/05__image007.png)

A Kubeflow pipeline experiment is used to manage and track machine learning workflow runs, facilitating the organization, monitoring, and comparison of different runs of Kubeflow pipelines. A Kubeflow run on the other hand is an instance of the execution of a Kubeflow pipeline. Runs of a pipeline should preferably be grouped under one experiment for easy tracking.

First, we create an experiment by clicking the Create Experiment button (Figure 5.5) and providing the experiment name and description(optional).

![Figure 5.5 Create an experiment in Kubeflow, by providing a name and experiment description.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/05__image009.png)

Once an experiment is created, we proceed to create a run of the pipeline by clicking on the create run button. Here we need to specify the runtime parameters of the pipeline along with the experiment name. We can then start a run by clicking on the Start Run button (Figure 5.6).

![Figure 5.6 Create a pipeline run by providing all the pipeline arguments.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/05__image011.png)

Once we click on the Start Run button, we can see the progress of a run in the Kubeflow pipeline UI (Figure 5.7).

![Figure 5.7 A successful Kubeflow pipeline run.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/05__image013.png)

We successfully built and ran the income classifier pipeline. Kubeflow Pipelines is a great tool for managing and executing machine learning workflows in a Kubernetes-based environment. In order to improve reproducibility, scalability, and cooperation in data science and machine learning projects, it offers a structured and organized way to design, schedule, and track complicated ML pipelines. By defining workflows as code, Kubeflow Pipelines allows data scientists and machine learning engineers to automate, streamline, and orchestrate tasks, from data preprocessing to model deployment. Teams can systematically experiment with various configurations, hyperparameters, and data sets thanks to the ability to design experiments and keep track of many runs within them.

Kubeflow pipelines work well for batch inferences. For real-time inference and deploying models in production, we will look at our next tool which is BentoML. Onward to the next chapter!

## 5.2 Summary

- Orchestration is the process of running multiple complex pipelines while making sure that the pipeline steps have the data and the compute needed. The kubeflow platform offers kubeflow pipelines as a solution.
- A component is a reusable and composable unit of work within a machine learning (ML) workflow. These components encapsulate individual tasks or steps that perform specific actions, such as data preprocessing, model training, evaluation, deployment, and more.
- While designing components, care should be taken to keep them as independent and generic as possible, allowing for reusability, easier development, testing, and maintenance of individual pipeline stages.
- Larger workflows can be broken down into smaller components. This approach helps create modular and easily maintainable ML pipelines from shared components.
- Kubeflow Pipelines and task orchestrators can be used to automate, sequence, and manage machine learning workflows, ensuring the efficient execution of data preprocessing, model training, and deployment tasks. It offers SDKs to build up individual components, connecting components to a pipeline as well as pipeline deployment and execution.
