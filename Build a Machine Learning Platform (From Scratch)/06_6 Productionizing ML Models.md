# 6 Productionizing ML Models

### This chapter covers

- Deploy ML models as a service using the BentoML deployment manager
- Track data drift using Evidently

In the last chapter, we learnt how to orchestrate ML pipelines in Kubeflow. Kubeflow pipelines are a powerful tool that can help you build, scale and manage machine learning pipelines.

This chapter delves into the crucial post-training phases of a machine learning model's life cycle: deployment and monitoring. We explore how to efficiently serve models as APIs using BentoML, a powerful platform that simplifies the deployment process and reduces reliance on complex infrastructure setup. Additionally, we tackle the challenge of data drift – a common phenomenon that can degrade model performance over time. We introduce Evidently, a tool designed to detect and analyze data drift, enabling us to take corrective actions and maintain model accuracy in real-world scenarios.

Through practical examples and step-by-step guides, this chapter equips you with the knowledge and tools to confidently deploy and monitor your models, ensuring their long-term effectiveness and value.

## 6.1 Bento ML As A Deployment Platform

In the last chapter, we deployed the income classifier model in a batch pipeline. In this section, we will deploy the model as an API endpoint using BentoML. In Chapter 3 we deployed our hello-joker application as a Fast API endpoint. To do this we had to build a Docker image, set up multiple Kubernetes manifests, and add some monitoring logic into our code. To automate the deployment, we had to set up the CI and CD.

Setting all of this can be time-consuming and not all data scientists in the team would have the necessary skills to set these up. In comes BentoML which acts as an end-to-end solution for streamlining the deployment process. It does so by packing all our modeling application requirements into a Bento and deploying it. Bento refers to the file archive which acts as a unified distribution format for machine learning applications, think of it as a Japanese bento box which instead of delicious food has our ML application.

Please set up BentoML in your Kubernetes cluster by following the instructions in Appendix A.

While bento is the format in which we will package our application, its deployment and monitoring will be handled by Yatai. Yatai is the component in the BentoML framework that lets us deploy, operate, and scale Machine Learning services on Kubernetes. It comes with a UI from which we can deploy, scale, and monitor our applications. In this section, we will deploy our income classifier as an API endpoint using BentoML. This consists of two steps

1. Building a Bento of our application
1. Deploying the Bento using Yatai

We will build a Bento in our local system and push it to Yatai, which will take care of containerizing and deploying the Bento (Figure 6.1).

![Figure 6.1 BentoML process to deploy the model as a service. We build a Bento and push it to the container registry. Yatai builds an image and deploys it.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/06__image001.png)

### 6.1.1 Building A Bento

Bento as specified above is a unified file format which holds our ML application. This is very similar to a Docker container. To build a Bento we need to do the following.

1. Register a model in BentoML local store. In our case it is moving model from MLflow to BentoML.
1. Initialize and define a service which defines the API endpoint of our application. The service holds a runner object which performs the actually inference and can be scaled horizontally.
1. Define the bentofile.yaml which holds the Bento requirements and environment variables
1. Build and push the Bento to Yatai by using predefined BentoML commands.

#### Registering Model

The Bento container consists of a data science model, feature retrieval logic, and model predictions. We first need to store our model in a Bento format. Our model is currently located in MLflow. Bento natively integrates with MLflow so we can port over models logged with MLflow Tracking to BentoML for high-performance model serving. We will first download our model from MLflow to our local BentoML store. To do so, we will run download_model.py. BentoML provides us with `bentoml.mlflow.import_model` method which pulls the model from MLflow to our local BentoML store. We have to provide this method with the model name and MLflow model URI which include the name of the model and its stage.

##### Listing 6.1 Downloading model from MLflow to local bento store

```
import mlflow
import bentoml
 
mlflow.set_tracking_uri("http://mlflow.dev.jago.data:5000/")    #A
model_name = "random-forest-classifier"
model_stage = "Staging"
bentoml.mlflow.import_model(
"random-forest-classifier", model_uri=f"models:/{model_name}/{model_stage}"
)    #B
```

We can see our model when we run the BentoML models list command on our terminal. It gives us the model name and tag, module refers to the source of this model which is MLflow. We can also see the model size and its time of creation.

```
bentoml models list
Tag                                        Module           Size       Creation Time       random-forest-classifier:7hrh6ndohg3mtktg  bentoml.mlflow   36.87 MiB  2023-10-07 12:42:57
```

#### Initializing Service And Runner

Now that we have our model we need to set up our service. Serving is one of the core building blocks of BentoML.

A Service allows us to define the serving logic of our model. In our case, the serving logic is to retrieve the features from Feast and perform model inference. We will write this serving logic in `service.py`. We first initialize a BentoML service object and a runner.

A runner represents a unit of computation that can be executed on a remote Python worker and scales independently. A runner allows the `bentoml.Service` to parallelize multiple instances of a `bentoml.Runnable` class, each on its own Python worker. When a Bento API Server is launched, a group of runner worker processes will be created, and `run` method calls made from `bentoml.Service` will be scheduled among those runner workers.

In our case, our runner will perform model prediction. So to initialize our service we first need to set up a runner.

BentoML provides a method `bentoml.mlflow.get(model_name).to_runner()` which converts our MLflow model to a runner. We then create an `svc` object by using `bentoml.Service`. We give the service an appropriate name and specify the newly created runner. We can specify more than one runner if needed, this is useful in cases where we have multiple models in the background to run inferences (useful in model comparison). We however have only one runner called `income_clf_runner`.

Once our runner and svc objects are defined we need to do some service initialization. This involves setting up the feature store and retrieving the column list from MLflow for dummyfying our features. We write this logic under an initialization function called initialize. We first set up our MLflow client and retrieve the column list. We also set up the feature store object by providing MinIO information such as access key, hostname, secret key, name of the bucket that holds our feature registry, and the copy of feature_store.yaml. We then store this column list and the feature store object in BentoML service context, context.state acts as a dictionary where we can store these values and then retrieve them later in the application when we need it. To ensure the function initialize runs during startup we annotate the function with @svc.on_startup. We retrieve all the environmental configurations from a .env file which is loaded using the `python-dotenv` module.

##### Listing 6.2 Initializing BentoML service

```
income_clf_runner = bentoml.mlflow.get("random-forest-classifier:latest").to_runner()    #A
full_input_spec = JSON(pydantic_model=IncomeClassifierUsers)
svc = bentoml.Service(
    "income_classifier_service",
    runners=[income_clf_runner],
)    #B
 
 
@svc.on_startup
async def initialise(context: bentoml.Context):
    config = dotenv_values(ENV_FILE_NAME)    #C
    os.environ["FEAST_S3_ENDPOINT_URL"] = config["FEAST_S3_ENDPOINT_URL"]
 
    mlflow_client = MlflowClient(config["MLFLOW_HOST"])    #D
    mlflow.set_tracking_uri(config["MLFLOW_HOST"])
    for model in mlflow_client.search_model_versions(
        f"name='{config['MLFLOW_MODEL_NAME']}'"
    ):
        if model.current_stage == config["MLFLOW_MODEL_STAGE"]:
            model_run_id = model.run_id
    mlflow.artifacts.download_artifacts(
        f"runs:/{model_run_id}/column_list/column_list.pkl", dst_path="column_list"
    )    #E
    with open("column_list/column_list.pkl", "rb") as f:
        col_list = pickle.load(f)
    feature_store = DataStore(
        config["MINIO_HOST"],
        config["MINIO_ACCESS_KEY"],
        config["MINIO_SECRET_KEY"],
        config["FEATURE_REGISTRY_BUCKET_NAME"],
        config["FEATURE_REGSITRY_FILE_NAME"],
    )    #F
    context.state["store"] = feature_store.init_feast_store()    #G
    context.state["col_list"] = col_list
```

#### Defining The Service

We then proceed to define the service. The input to the service is a user_id (or in feast terms the entity). We specify this in the IncomeClassifierUsers and wrap it with bentoml.io JSON to define the API input. This input along with the BentoML context are the parameters of our predict function. We load the inputs into a dictionary and use feature_store.get_online_features to retrieve the features for the user. We then map the feature columns to the dummyfied columns by using the col_list. We finally map the output of the model to its appropriate label (0 = <=50K and 1= >50k) using the OutputMapper. The API returns the `income_category` along with the `user_id`.

##### Listing 6.3 Defining the service endpoint

```
full_input_spec = JSON(pydantic_model=IncomeClassifierUsers)
@svc.api(input=full_input_spec, output=JSON(), route="/predict")
def predict(inputs: IncomeClassifierUsers, ctx: bentoml.Context) -> Dict[str, Any]:
    input_dict = inputs.dict()    #A
    feature_df = (
        ctx.state["store"]
        .get_online_features(features=FEATURE_LIST, entity_rows=[input_dict])
        .to_df()
    )    #B
    feature_df.drop(columns=["user_id"], inplace=True)
    data_mapper = InputMapper(feature_df, ctx.state["col_list"])
    input_df = data_mapper.generate_pandas_dataframe()    #C
    output_mapper = OutputMapper(income_clf_runner.predict.run(input_df)[0])    #D
    return {
        "income_category": output_mapper.map_prediction(),
        "user_id": input_dict["user_id"],
    }    #E
```

We have now successfully defined the service, if we want to run it in our local environment, we can run `bentoml serve` command. This will launch the application on port 3000.

```
bentoml serve service:svc
2023-10-19T18:56:53+0800 [INFO] [cli] Environ for worker 0: set CPU thread count to 12
2023-10-19T18:56:53+0800 [INFO] [cli] Prometheus metrics for HTTP BentoServer from "service:svc" can be accessed at http://localhost:3000/metrics.
2023-10-19T18:56:54+0800 [INFO] [cli] Starting production HTTP BentoServer from "service:svc" listening on http://0.0.0.0:3000 (Press CTRL+C to quit)
```

#### Define Bentofile.yaml

With the service defined and running on our local, it's time to package (or bentofy) our application. To package our application we will need to write a `bentofile.yaml`. This is similar to a Dockerfile but simpler.

We first define the service which points to the svc object created in service.py, `service:svc` refers to (file name of service:name of service object). We can also add labels if required. These labels are meta data in a key value format. In this case we have added a label for the application owner. We then specify the files to be included in the Bento. We need all the Python files along with the production.env file which holds the configuration variables for our application.

By default, BentoML automatically locks all package versions, as well as all packages in their dependency graph, to the version found in the current build environment. If we have already specified a version for all packages, we can optionally disable this behavior by setting the lock_packages field to False. We then list all the packages needed by our application under `packages`.

We finally specify the environment variables of our application under env. The ENV_NAME variable is used to point to the right configuration file to be used by the application. AWS environment variables are used by Feast when it retrieves the features from the MinIO.

##### Listing 6.4 bentofile.yaml to package our application

```
service: "service:svc"    #A
labels:
  owner: ml-engineering-team
include:    #B
  - "*.py"
  - "production.env"
python:
  lock_packages: false
  packages:    #C
   - minio==7.1.16
   - mlflow==2.6.0
   - pandas==1.5.3
   - pydantic==1.10.12
   - boto3>=1.17.0,<2
   - google-cloud-storage
   - feast[redis]==0.34
docker:
  env:    #D
    - ENV_NAME=production
    - AWS_ACCESS_KEY_ID=minio
    - AWS_SECRET_ACCESS_KEY=minio123
```

#### Build And Push Bento

We have now defined our service and our bentofile.yaml. To build the Bento we will use the `bentoml build` command:

```
bentoml build -f bento/bentofile.yaml
ENV_NAME=production
AWS_ACCESS_KEY_ID=minio
AWS_SECRET_ACCESS_KEY=minio123
██████╗ ███████╗███╗   ██╗████████╗ ██████╗ ███╗   ███╗██╗
██╔══██╗██╔════╝████╗  ██║╚══██╔══╝██╔═══██╗████╗ ████║██║
██████╔╝█████╗  ██╔██╗ ██║   ██║   ██║   ██║██╔████╔██║██║
██╔══██╗██╔══╝  ██║╚██╗██║   ██║   ██║   ██║██║╚██╔╝██║██║
██████╔╝███████╗██║ ╚████║   ██║   ╚██████╔╝██║ ╚═╝ ██║███████╗
╚═════╝ ╚══════╝╚═╝  ╚═══╝   ╚═╝    ╚═════╝ ╚═╝     ╚═╝╚══════╝
Successfully built Bento(tag="income_classifier_service:2umhoidopolz3ktg").
Possible next steps:
 * Containerize your Bento with `bentoml containerize`:
    $ bentoml containerize income_classifier_service:2umhoidopolz3ktg  [or bentoml build --containerize]
 * Push to BentoCloud with `bentoml push`:
    $ bentoml push income_classifier_service:2umhoidopolz3ktg [or bentoml build --push]
```

We can list the newly created bento by running `bentoml list`, this gives us the name of the newly created bento, along with its size and the model size. The size refers to the size of the application whereas the model size is the size of the model.

```
bentoml list
Tag                                           Size        Model Size  Creation Time       
income_classifier_service:2umhoidopolz3ktg    20.14 KiB   36.87 MiB   2023-10-07 20:34:23
```

Once the Bento is built and saved in the local bento store. We now have to push this Bento to a remote Bento store so that it can be pulled by Yatai and deployed as an application in our Kubernetes cluster. To push the Bento we first need to port forward to the Yatai service.

```bash
kubectl --namespace yatai-system port-forward svc/yatai 8080:80
```

We then proceed to login to Yatai using an API token (Please refer to Appendix A for API token)

```
bentoml yatai login --api-token <api_token> --endpoint http://127.0.0.1:8080
Overriding existing cloud context config: default
Successfully logged in to Cloud for Varun Mallya in default
```

Once logged in we can push our Bento using `bentoml push` command, it will automatically push the latest income classifier bento. This includes both the model as well as the application.

```
bentoml push income_classifier_service
╭─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮
│ Successfully pushed model "random-forest-classifier:7hrh6ndohg3mtktg"                                                                                                                       │
│ Successfully pushed bento "income_classifier_service:2umhoidopolz3ktg"                                                                                                                      │
╰─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯
 Pushing Bento "income_classifier_service:2umhoidopolz3ktg" ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 100.0% • 71.7/71.7 kB • 442.5 MB/s • 0:00:00
Uploading model "random-forest-classifier:7hrh6ndohg3mtktg" ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 100.0% • 38.7/38.7 MB • 10.2 MB/s  • 0:00:00
```

With the bento build and pushed to the remote bento store, we can now login to Yatai from our browser and go ahead with deployment.

### 6.1.2 Deploying a Bento

Once the Bento is pushed to Yatai we need to deploy it. First let us verify that the model and the Bento have been pushed over to their respective remote stores.

To locate the models in the remote model store we click on the Models tab in the sidebar, this lists the models pushed. We can see our random-forest-classifier model is listed here (Figure 6.2).

![Figure 6.2 Yatai UI Models tab which displays the models registered in the BentoML model registry.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/06__image003.png)

To check if our Bento was pushed, we will look under the Bentos tab (Figure 6.3), where we can see our income classifier service bento.

![Figure 6.3 Yatai UI Bentos tab displays the bentos which have been pushed over to the bento registry.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/06__image005.png)

Now that we have confirmed our model and Bento exist, we can proceed to deploy our application. To do so, click on the Deployments tab in the sidebar followed by the Create button (Figure 6.4).

![Figure 6.4 Create a deployment by clicking on Create button](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/06__image007.png)

We can then specify the name of our deployment and the name of the bento along with its tag (Figure 6.5).

![Figure 6.5 Create a deployment by providing the name of the Bento and its version.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/06__image009.png)

On the same page we can also specify additional configurations such as number of replicas for the deployment and the required cpu and memory requirements of the pod. We can also provide similar configurations for the Runners under the runners tab (Figure 6.6).

![Figure 6.6 Additional configurations for the deployment such as resource limits and replica count.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/06__image011.png)

After providing the necessary configurations we can go ahead and click on the submit button to create our deployment. In the deployments page click on the newly created deployment. Yatai then internally builds a Docker image by running a Kubernetes job, in our case it launches a job called yatai-bento-image-builder-income-classifier (Figure 6.7).

![Figure 6.7 Yatai running a job to containerarize the application and build an image.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/06__image013.png)

Once the job completes, we will be able to see new pods spawning for our income-classifier-application. Once they are ready, we should be able to see it in the Yatai UI under the replicas tab. We can see two categories of Pods, API and runner pods. The API pod is the front end of your application. This pod receives the requests from users and other applications. The runner pod acts as a backend for our application and holds our models and performs inference. The API pod communicates with the runner pod for getting the predictions. We can scale both of them independently while configuring the deployment. We can see one pod launched of type API server and two pods of type runner (Figure 6.8).

![Figure 6.8 Yatai successfully launched a deployment with an API server and runner pods.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/06__image015.png)

These pods are launched under the Yatai namespace and can be by running a kubectl get command which lists all the income classifier pods.

```bash
kubectl get pod -n yatai | grep income-classifier-service
income-classifier-service-5cfb889666-8bc9d            2/2     Running   0          12m
income-classifier-service-runner-0-7df4c46b58-dz99k   2/2     Running   0          12m
income-classifier-service-runner-0-7df4c46b58-fz2k4   2/2     Running   0          12m
```

BentoML also generates an ingress service which can be used to communicate with the service. To retrieve the ingress, we will use the kubectl get ingress command

```bash
kubectl get ingress -n yatai | grep income
income-classifier-service    nginx    income-classifier-service-yatai.10.65.0.40.sslip.io   10.65.0.40   80      17m
```

If we connect to that endpoint using our browser, we will be greeted with a Swagger doc. A Swagger document is a machine-readable specification for documenting and describing RESTful APIs. Swagger doc of our application can be used for testing the application endpoint /predict (Figure 6.9).

![Figure 6.9 Swagger doc for the deployed service with the /predict endpoint](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/06__image017.png)

We can trigger a request to the /predict endpoint with a suitable user id and get the response (Figure 6.10)

![Figure 6.10 A sample request and its prediction.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/06__image019.png)

BentoML application also comes with a /metrics endpoint which can be scraped by Prometheus for the purpose of observability. This includes the standard metrics such as number of requests per second and latency of requests (Figure 6.11).

![Figure 6.11 Default metrics made available at /metrics endpoint by BentoML.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/06__image021.png)

We have now been able to deploy the application using BentoML. During which we did not write a Dockerfile, did not set up any Kubernetes manifests, nor did we write any logic for creating a /metrics endpoint. BentoML took care of that as long as we provided a bentofile.yaml. BentoML is a great tool for standardizing ML deployments, and we can find more information about this tool at [https://docs.bentoml.com/en/latest/](https://docs.bentoml.com/en/latest/).

In the last couple of sections, we have deployed the income classifier application in a batch and in real-time fashion. However, for data science applications, there is a risk that performance can degrade over time while a model is deployed. One possible cause for degradation is when the input data to a model deviates from the data that was used to train and validate the model, or data drift. We will learn about data drift monitoring in our next section.

## 6.2 Evidently For Data Drift Monitoring

In the previous sections, we have deployed a model in production as a batch pipeline and as an endpoint. Let’s say that initially our model performed well, but after a few months, performance started to decay. After a careful analysis, it was found that some of the features being referenced by the model deviated from what was learned during training, causing data drift. Data drift is a problem that frequently arises in machine learning and data science. It is the phenomenon where the performance and accuracy of a machine learning model decline over time as the statistical parameters of the data used to train the model change. This may occur for a number of reasons, including as modifications to the target variable, shifts in the data's properties, or modifications to the underlying data distribution.

Most models are trained on historical data, assuming consistent relationships between input and output variables. We also assume that the distribution of the input variables does not change significantly enough to affect the predictions. But in the real world, given enough time, the above assumptions may not hold. In the real world, the data might drift from the historical data we trained our model on, resulting in poor model performance. Therefore, it is very important to detect data drift in production and take corrective action.

Data drift can be caused by multiple reasons -

- **Label Drift**: In supervised learning, label drift happens as the target variable (ground truth) evolves over time. For example, the definition of what is considered defective may alter if you're training a model to find defective goods in a manufacturing process.
- **Prior Probability Shift**: Prior probability for classes in classification issues are subject to shift. For example, a fraud detection system's percentage of positive and negative cases may fluctuate over time.
- **Covariate Shift**: This happens when the data's distribution of the input features shifts with time. For example, factors like demographics, location, or behavior patterns may change over time if you're developing a model to anticipate client behavior (Figure 6.12).
- **Sudden Drift**: Some data drifts can be sudden and unexpected, like a sudden change in customer behavior due to external factors (e.g., a pandemic or a significant market event).

![Figure 6.12 An example of covariate shift for one of the features. The distribution in 2021 is different from the distribution in 2018.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/06__image023.png)

Evidently is a tool that helps in detecting data drift; it works well for both real-time and batch cases. It does so by means of statistical tests which run on the historical and inference data. These tests assist us in determining whether the statistical characteristics of the data have significantly changed over time. Some examples of these tests include -

- **Kolmogorov-Smirnov Test (KS Test)**: The KS test is used to compare the cumulative distribution functions (CDFs) of two datasets. It can help us determine if the distribution of a feature in our data has changed significantly over time. If the p-value from the KS test is below a certain threshold (e.g., 0.05), it suggests data drift.
- **Chi-Square Test**: The chi-square test can be used to check the independence of categorical variables. If we have categorical features, we can use this test to detect if the distribution of categories has changed over time.
- **Wasserstein distance**: Also known as Earth Mover's Distance, It measures the dissimilarity between probability distributions of a baseline dataset representing "normal" data behavior and a current dataset collected at a later point in time. A larger Wasserstein distance indicates more significant drift, suggesting that the two datasets have changed substantially, while a smaller distance signifies less drift, implying greater similarity between the datasets

Evidently decides which test is best suited for our data and applies it to detect drift. We can even specify explicitly which test we want or even write one of our own.

### 6.2.1 Data Drift Detection Report And Dashboard

Evidently provides a simple Python SDK which helps us in detecting both drift types. To detect drift, we need to provide Evidently with a reference dataset (historical data) and a current dataset (the data we wish to predict for). We can generate a drift report by using just these two datasets.

A report in general consists of different metrics. A Metric is a core component of Evidently. We can combine multiple Metrics in a report. A Metric can be a single metric (DatasetMissingValuesMetric(), for instance, delivers the proportion of missing features). It may also be a mix of metrics (DatasetSummaryMetric(), for instance, computes a number of descriptive statistics for the dataset). Metrics exist on the dataset level and on the column level. Each metric has its own visual render. Some metrics return only a value which can be displayed as a stat.

Below is a RegressionQualityMetric (Figure 6.13) which measures the performance of a regression model with respect to reference dataset and current dataset. It displays the mean error (ME), mean absolute error(MAE) and mean absolute percentage error(MAPE) performance metrics of the model with respect to reference and current datasets.

![Figure 6.13 Regression Model report which displays mean error, mean absolute error and mean absolute percentage error. For each metric it also displays the standard deviation to estimate the stability of the performance.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/06__image025.png)

Other metrics return rich visualizations which can be rendered as a plot (Figure 6.14).

![Figure 6.14 An example of column level metric which displays the column histogram plot. We can select the range and check how many values fall in the range for both reference and current dataset.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/06__image027.png)

We also have metric presets. A pre-built report is called a Metric Preset. It aggregates measurements for a specific use case. Think of it as a template. For instance, there is a Preset to check for Data Drift, Data Quality, or Regression Performance (DataDriftPreset, DataQualityPreset, and RegressionPreset).

A data drift report is shown below (Figure 6.15). Each row of the data drift report compares the distribution of a feature in the reference dataset (Reference Distribution column) to the same feature in the inference dataset(Current Distribution column). The report specifies which test was used under the Start Test column and also the p-value or drift score of each test outcome under the Drift Score column. Every statistical test comes with a drift score. The test being used in our case was Wasserstein distance the score returned from this test can vary from 0 to infinity. Evidently’s default threshold for identifying drift detection for this test is 0.1, i.e. if the drift score is greater than >0.1 then Evidently will classify it as drift detected.

![Figure 6.15 An example of Evidently data drift report. Each row compares the distribution between the reference and inference datasets. Also informs us of the statistical test used and the corresponding drift score.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/06__image029.png)

This report was generated by this three-liner. In the first line we define a report object with a metric preset as `DataDriftPreset`. `DataDriftPreset` generates a default data drift report which looks at every column and runs a statistical test comparing the reference dataframe to the current dataframe. Once we define the report we can run it by providing the reference and current data as parameters. Finally we save it as a html by using the `save_html` method.

##### Listing 6.5 Generating a datadrift report using DataDriftPreset

```
report = Report(metrics=[
    DataDriftPreset(), 
])    #A
report.run(reference_data=reference_data,current_data=current_data)    #B
report.save_html(“drift_report.html”)    #C
```

Reports are generated from snapshots of data, and this data can be obtained from a daily batch job or an API. While reports are helpful in giving the state of model performance at any given time, if we wish to track model performance over a given period of time, we will have to generate reports at multiple time intervals and compare them. To make this process a bit simpler Evidently provides us with dashboarding tools for monitoring purposes. The dashboard is a web-based dashboard deployed on a UI that can be launched on our local system by running `evidently ui` command, which launches a server on port 8000.

```
evidently ui
INFO:     Started server process [56161]
INFO:     Waiting for application startup.
Anonimous usage reporting is enabled. To disable it, set env variable DO_NOT_TRACK to any value
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
```

If we use our browser to access this endpoint, we will get the Evidently UI with no projects listed under projects list (Figure 6.16).

![Figure 6.16 Evidently UI with no listed projects.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/06__image031.png)

Let us build a dashboard for our income classifier model and display it on the above UI. To build a dashboard we first need to create a workspace and project. Think of a workspace as a directory to keep all our data snapshots and projects as sub-directories to organize these logs further. For example, we can have a workspace directory called workspace with two projects project_1 and project_2. Each project has two data snapshots snapshot_1.json and snapshot_2.json.

```
workspace
├── project_1
│   ├── snapshot_1.json
│   └── snapshot_2.json
└── project_2
    ├── snapshot_1.json
    └── snapshot_2.json
```

We will create a workspace and project by running the below script. We connect to our UI using RemoteWorkspace which acts as a client for the UI. Within this workspace, we create a project called `Income Classifier` and we provide a suitable description to this project.

##### Listing 6.6 Pointing to a remote workspace and creating a project

```
from evidently.ui.remote import RemoteWorkspace
ws = RemoteWorkspace("http://localhost:8000")    #A
project = ws.create_project(
    name="Income Classifier",
    description="Used to classify users into multiple income bands",
)    #B
```

On running this script we can see our project under the project list (Figure 6.17).

![Figure 6.17 Evidently UI with our income classifier project](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/06__image033.png)

When we click this link we will see an empty dashboard. To build a dashboard we need to design our panels. Panels are components of a dashboard. Panels are the rendered visualization of the report metrics. When we add a panel, we must specify its type and properties, such as width and title. One example of panel type is DashboardPanelCounter, which is used to display a single stat. We also have DashboardPanelPlot which displays any measurement as a line plot, bar plot, scatter plot, or histogram.

A panel that is common for most dashboards is the panel that displays the title of the dashboard. To build this we will use a panel of the type `DashboardPanelCounter` and just display the title of the panel and not provide it with any numerical value. Filters allow you to choose a subset of snapshots from which to display values on the panel, we are not setting any filter for our use case, agg refers to the data aggregation that must be performed As our panel is only displaying a text we will set it to None. The title refers to the panel heading.

##### Listing 6.7 Creating a title panel for the data drift dashboard

```
title_panel = DashboardPanelCounter(
            filter=ReportFilter(metadata_values={}, tag_values=[]),
            agg=CounterAgg.NONE,
            title="Income Classifier Batch Data Drift Dashboard",
        )    #A
```

We can have another panel that displays the percentage of drifted columns. As it's a single value, we will use a `DashbaordPanelCounter`, but this time we will provide it a value. To specify a value we need to create a `PanelValue` object and specify the `metric_id` which is the name of the metric, `field_path` corresponds to the result in the metric object which corresponds to the value of interest. In our case, we wish to retrieve the `share_of_drifted_columns` value. We also specify a label for this stat by specifying the legend. We can also specify an optional text for the counter. We wish to see the most recent value of the percentage of drifted columns for which we use `CounterAgg.LAST` aggregation. Size is used to control the panel width, 1 is for half width and 2 is for full width.

##### Listing 6.8 Creating a panel to display percentage of drifted columns

```
percentage_of_drifted_columns_panel = DashboardPanelCounter(
            title="Share of Drifted Features",
            filter=ReportFilter(metadata_values={}, tag_values=[]),
            value=PanelValue(
                metric_id="DatasetDriftMetric",
                field_path="share_of_drifted_columns",
                legend="share",
            ),
            text="share",
            agg=CounterAgg.LAST,
            size=1,
        )   #A
```

We can then add this panel to the project dashboard by running the below script. We add both the panels and save these changes by using `project.save()`. Saving is important otherwise the changes won't be updated on the UI.

```
project.dashboard.add_panel(title_panel)
project.dashboard.add_panel(percentage_of_drifted_columns_panel)
project.save()
```

If we now refresh our UI, we will see an empty dashboard with two panels (Figure 6.18). The dashboard's title is displayed in the first panel. In the second panel, it complains that there is no data because we haven't run any report yet which generates the snapshot data for the panel.

![Figure 6.18 Empty income classifier dashboard.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/06__image035.png)

In the next couple of sections, we will populate this dashboard for both batch and real-time use cases. In Appendix A we have provided instructions for deploying Evidently UI in the Kubernetes cluster and we will also add some more panels to our income classifier dashboard. Please set it up before proceeding to the next section.

### 6.2.2 Data drift detection Kubeflow pipeline component

Data drift monitoring batch jobs are useful for applications such as model validation and data quality monitoring. For the batch use case, we will build another Kubeflow pipeline component for populating the income classifier data drift dashboard. This component will be used by the inference pipeline we built in section 5.1.2, it will be placed between feature retrieval and the run inference component. If a drift is detected between the new feature data and the training (reference data), we will stop the pipeline execution.

We will write our component code as usual in a Python file (`detect_drift.py`). The MLflow client is initialized and is used to retrieve the run ID of the model. This run holds the information of the reference dataset (logged in MLflow section 4.1.2), and we use this to download the file from MinIO. We also initialize the Evidently workspace so that we can add the report data to the dashboard. Our inference data is the data retrieved from Feast. We will obtain this from the previous task (retreive_features_task). We initialize the report by defining all the metrics, the metrics used in the report should correspond to the ones used in our dashboard. Using the reference and current dataset we will generate a report by running `report.run`.

##### Listing 6.9 Kubeflow pipeline component for detecting data drift

```
def detect_drift(
    model_name: str,
    model_stage: str,
    mlflow_host: str,
    minio_host: str,
    access_key: str,
    secret_key: str,
    reference_dataset_name: str,
    feature_dataset_path: InputPath(),
    evidently_workspace_url: str,
    evidently_ui_project_id: str,
):
    mlflow.set_tracking_uri(mlflow_host)
    mlflow_client = MlflowClient(mlflow_host)    #A
    evidently_workspace = RemoteWorkspace(evidently_workspace_url)    #B
 
    for model in mlflow_client.search_model_versions(f"name='{model_name}'"):
        if model.current_stage == model_stage:
            model_run_id = model.run_id
 
    run = mlflow.get_run(model_run_id)
    for dataset_input in run.inputs.dataset_inputs:
        for tag in dataset_input.tags:
            if tag.value == reference_dataset_name:
                dataset_source = json.loads(dataset_input.dataset.source)["uri"]
    
    bucket_name = dataset_source.split("/")[0]
    object_name = "/".join(dataset_source.split("/")[1:])
    file_path = object_name.split("/")[-1]
    download_file_from_minio(
        minio_host, access_key, secret_key, bucket_name, object_name, file_path
    )    #C
    reference_df = pd.read_csv(file_path)
    feature_df = pd.read_pickle(feature_dataset_path)    #D
    report = Report(
        metrics=[
            DatasetDriftMetric(),
            DatasetMissingValuesMetric(),
            ColumnDriftMetric(column_name="Education"),
            ColumnSummaryMetric(column_name="Education"),
            ColumnDriftMetric(column_name="Marital-Status"),
            ColumnSummaryMetric(column_name="Marital-Status"),
            ColumnDriftMetric(column_name="Native_country"),
            ColumnSummaryMetric(column_name="Native_country"),
            ColumnDriftMetric(column_name="Occupation"),
            ColumnSummaryMetric(column_name="Occupation"),
            ColumnDriftMetric(column_name="Race"),
            ColumnSummaryMetric(column_name="Race"),
            ColumnDriftMetric(column_name="Relationship"),
            ColumnSummaryMetric(column_name="Relationship"),
            ColumnDriftMetric(column_name="Sex"),
            ColumnSummaryMetric(column_name="Sex"),
            ColumnDriftMetric(column_name="Workclass"),
            ColumnSummaryMetric(column_name="Workclass"),
        ],
    )    #E
    report.run(reference_data=reference_df, current_data=feature_df)    #F
    evidently_workspace.add_report(evidently_ui_project_id, report)    #G
```

We can then place this component in the income classifier inference pipeline. We then create a component.yaml with the inputs and outputs of the data drift component (similar fashion as section 5.1.1). We then load this component in the pipeline. Our complete pipeline execution would look like (Figure 6.19)

![Figure 6.19 Successful run of the Kubeflow inference pipeline with detect data drift component.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/06__image037.png)

We can then take a look at our dashboard to see the report where all panels are no longer empty but have some data. Based on the Share of Drifted Features panel we can see that for our current batch of data, none of the columns have drifted significantly. We can also see the drift score of each individual column (Figure 6.20)

![Figure 6.20 An Evidently dashboard showing columns exhibiting data drift.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/06__image039.png)

This dashboard will be updated after every run of the pipeline. We can even filter the data with time to see how the data drift stats change with time. Next, we will modify our BentoML service such that it will update the dashboard of the Income Classifier Real-time project.

### 6.2.3 Data drift detection for model deployed as API

Real-time monitoring of data drift may be required for some applications such as fraud detection and recommendation systems. Real-time decision-making, reactivity to changing data, and the accuracy of predictive models are crucial for these applications. We will demonstrate this for our income classifier application deployed using BentoML.

It's not a good idea to run drift detection statistical tests for every new request that hits the predict endpoint. This is because when we compare the reference datasets with only a single request the results won't be accurate, instead what we must do is compare the reference dataset with a microbatch. The exact size of the microbatch varies from application to application. Keeping that in mind let us now modify our BentoML application with the aim of enabling real-time ( or in this case micro-batch) drift detection.

To enable microbatching, we have to initialize the MonitoringService object under service startup. The main objectives of monitoring service are to keep track of the current micro batch of data and run the report when the batch reaches a certain size. It also moves the window and ensures only the most recent data data is in the window evicting older data with each subsequent request. For example, let’s say we want a sample of size 100 to compare against the reference dataset. When the app starts, we will store 100 samples which may correspond to 100 API calls to a predict endpoint. We would compare it to the reference dataset and check for data drift only once we have 100 samples. From there, we would take the most recent 100 samples by dropping the least recent sample from our set for every subsequent API call.

We can see that it appends new rows of data to the current window. It does this till the number of new rows exceeds the window size when it does we trigger a report and add it to the workspace. We also drop data from the window when its size has exceeded the window size.

##### Listing 6.10 Defining the MonitoringService to run drift reports periodically

```
class MonitoringService:
    def __init__(
        self,
        report: Report,
        reference: pandas.DataFrame,
        workspace: Workspace,
        project_id: str,
        window_size: int,
    ):
        self.window_size = int(window_size)
        self.report = report
        self.new_rows = 0
        self.reference = reference
        self.workspace = workspace
        self.project_id = project_id
        self.current = pandas.DataFrame()
 
    def iterate(self, new_rows: pandas.DataFrame):
        rows_count = new_rows.shape[0]
 
        self.current = self.current.append(new_rows, ignore_index=True)    #A
        self.new_rows += rows_count
        current_size = self.current.shape[0]
        if self.new_rows < self.window_size < current_size:    #B
            self.current.drop(
                index=list(range(0, current_size - self.window_size)),
                inplace=True,
            )
            self.current.reset_index(drop=True, inplace=True)
        if current_size < self.window_size:    #C
            logger.info(
                f"Not enough data for measurement: {current_size} of {self.window_size}."
                f" Waiting more data"
            )
            return
        self.report.timestamp = datetime.datetime.now()
 
        self.report.run(
            reference_data=self.reference,
            current_data=self.current,
        )    #D
        self.workspace.add_report(project_id=self.project_id, report=self.report)    #E
```

We initialize `MonitoringServicing` under our initialize function of BentoML which runs on application startup. To initialize it we provide it with the reference dataset by retrieving it from MLflow. We define the report structure to set up the RemoteWorkspace and retrieve the project ID and window size from the .env files. We can set the window size to an appropriate size, for our testing purposes we have set it to 50.

##### Listing 6.11 Kubeflow pipeline component for detecting data drift

```
for dataset_input in run.inputs.dataset_inputs:
        for tag in dataset_input.tags:
            if tag.value == config["REFERENCE_DATASET_NAME"]:
                dataset_source = json.loads(dataset_input.dataset.source)["uri"]
                
    bucket_name = dataset_source.split("/")[0]
    object_name = "/".join(dataset_source.split("/")[1:])
    file_path = object_name.split("/")[-1]
    download_file_from_minio(
        minio_host=config["MINIO_HOST"],
        access_key=config["MINIO_ACCESS_KEY"],
        secret_key=config["MINIO_SECRET_KEY"],
        bucket_name=bucket_name,
        object_name=object_name,
        file_path=file_path,
    )
    reference_dataframe = pd.read_csv("feature_df-82b3d3db0f8045a5bb5e419fe6c12941.csv")
 
    evidently_workspace = RemoteWorkspace(config["EVIDENTLY_WORKSPACE_URL"])    #A
    context.state["evidently_workspace"] = evidently_workspace
    global SERVICE
    SERVICE = MonitoringService(
        report=data_drift_report,
        reference=reference_dataframe,
        workspace=evidently_workspace,
        project_id=config["EVIDENTLY_PROJECT_ID"],
        window_size=config["EVIDENTLY_REPORT_WINDOW_SIZE"],
    )    #B
```

Under the predict function, we need to use the iterate method of the Monitoring service to run the report and keep track of the current dataset window size.

```
SERVICE.iterate(feature_df)
```

We can then deploy our application by running bentoml build and push commands. To verify if we can monitor drift for our application, we can trigger a few hundred requests for our application by running the `generate_mock_request.py`. It simply calls our endpoint with a different user_id. Once our application receives more than 50 requests, our first report will be generated. From there on we will generate a report for every subsequent request, in each case the size of the current data would be 50 as we will remove the oldest request data from our window. Each of these report snapshots would be visible on our dashboard (Figure 6.21).

The structure of the dashboard is the same as the one for batch, but the number of data points would be more for the real-time use case. For our window size of 50, the share of drifted features metric is near 0.875 i.e 87% of our columns have drifted. We can even see this metric with respect to time as now we are sending multiple snapshots periodically. This number however seems odd as we are retrieveing our current data from the training dataset itself, and ideally there should be no drift. This can be attributes to the sample size of 50 and it might be worthwhile to go back and revise thresholds to ensure drift alerts are triggered only when actual drift occurs. Please feel free to try with larger window sizes.

![Figure 6.21 Evidently dashboard for real time use case. A data point for the report is generated for every window size/snapshot.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/06__image041.png)

While recognizing data drift is an important first step, it's also crucial to take the necessary steps to address the drift and its possible effects on our application. We can follow some of these steps when we encounter data drift.

- **Investigate drift**: Start by examining the type and severity of data drift. Find out if it matters and if it affects the fairness or accuracy of your models and forecasts. Further statistical testing and in-depth data analysis may be required.
- **Upstream data pipelines and preprocessing**: If the source of data drift is changes caused by changes in the upstream data processing pipelines, we may have to either fix the pipeline if it has any issues or spend some time in data cleaning procedures to ensure data quality and consistency.
- **Model Retraining**: We may have to retrain our machine learning models with the latest data if data drift has a substantial impact on model performance.
- **Update Feature Selection**: If the drift is related to changes in feature importance, revisit the feature selection process. It may be necessary to add, remove, or modify features to improve model performance and adapt to changing data patterns.

Monitoring data drift is not just a procedure; it is a commitment to the continued success of operations that are data-centric.

## 6.3 Summary

- Tools like BentoML empower data science teams by reducing the technical barriers to deployment, fostering collaboration between data scientists and engineers, and accelerating the path from model development to real-world impact.
- While the tools offer a streamlined deployment process, understanding the underlying technologies (Docker, Kubernetes) empowers data scientists to customize and fine-tune deployments for specific needs.
- Integrating data drift monitoring into ML pipelines allows for early detection of performance degradation, enabling timely interventions and preventing costly mistakes.
- Monitoring data drift is important for preserving the precision and efficiency of ML systems. By recognizing and correcting changes in data distributions over time, the risk of model deterioration and flawed decision making can be avoided.
- Data drift detection tools like Evidently help us identify shifts in data patterns over time, helping maintain model accuracy, compliance, and data quality in machine learning applications.
