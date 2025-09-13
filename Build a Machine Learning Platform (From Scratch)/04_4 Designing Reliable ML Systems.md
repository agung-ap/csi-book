# 4 Designing Reliable ML Systems

### This chapter covers

- Tooling for ML Platform
- Track ML experiments using MLflow experiment tracker
- Store the models created in MLflow model registry
- Register model features in Feast feature store

In the last chapter, we learned about DevOps tooling that helped us to automate and deploy applications reliably and at scale. In the next three chapters, we will use this knowledge as a base to design and build our ML platform.

In particular, we explore individual components of the ML platform discussed in Chapter 1( Section 1.3). We will learn about different tooling/applications that help us in tracking our data science experiments, storing the model features, and aiding in pipeline orchestration and model deployment. Our goal would be to show a fully functional mini ML platform with these tools while highlighting interactions between them.

We will start our ML journey the way most data scientists do - By understanding the data. We will perform some EDA, split our dataset into training and testing sets, and run multiple models to get the one that performs best. The initial stages of a data science project are mostly exploratory, and we experiment with different features, model hyperparameters, and frameworks.

To keep track of all our experiments in an organized manner we will use an experiment tracker MLflow. MLflow will help us select the best model once we have arrived at a model whose performance meets our expected criteria. We will then place this model in the MLflow model registry along with all of its dependencies, such that we can reproduce the experiment, collaborate with other data scientists or MLE, or load the model when it's time for deployment.

During experimentation, we may generate new features via feature engineering which helps in improving our model performance. These features need to be registered too as they will be necessary during model deployment and will also aid in collaboration with other members of the team. For this purpose, we use a feature store called Feast which acts as a storage interface for our features and also provides an interface to access these features for model training or generating predictions.

Once we have our features and model in their respective locations, we will focus on model deployment. We will deploy our model for batch and real-time use cases. For batch use cases, we will generate predictions using Kubeflow Pipeline orchestrator. For real-time use cases, we deploy the model as an API endpoint using BentoML as a deployment manager. We will also address issues that are encountered by models in productions where the model performance degrades with time due to shifts in the data distribution. We will use Evidently data drift monitoring tool to keep track of our feature data distribution.

All of these tools discussed above are important components of the ML Platform. We can now revisit the ML Platform diagram in Chapter 1. With these tools in their right place, it would now look like Figure 4.1.

![Figure 4.1 MLPlatform example displaying experiment tracking, model registry, feature store, model deployment, and drift detection.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/04__image001.png)

We will utilize this ML platform to build a simple binary classifier that is used to classify income bands <=50k and >50k. We will use the MLOps tooling described above to build and deploy this model. Although the example is straightforward, the lessons learned can still be applied to more complicated projects. In this chapter, we will focus on experiment tracking and feature store.

## 4.1 MLflow For Experiment Tracking

When we build our models, it is important to track the different parameters that can vary in our model-building journey. These parameters can include the training/testing data, the model weights, and the accuracy metrics of the model. It's important to track these parameters for multiple reasons:

- **Reproducibility**: As data scientists we may need to share our work with our peers. Keeping track of the parameters will help us in reproducing the experiments and replicating our results.
- **Model Selection**: More often than not, we will build multiple models for our ML use cases. These models will have different architectures and different performance metrics. Tracking of parameters helps us in ensuring we have the ability to choose the best model.
- **Performance Tracking**: The model we select may need to be retrained with fresh training data. If we keep track of our parameters, we can then compare the performance of our retrained models with our earlier iterations.

So how do we track our parameters? We could use a version control system and commit our parameters. If we wish to recreate a certain scenario, we could open that commit and re-run the code. This however requires us to commit periodically and tag the commits appropriately if we wish to retrieve them in the future. We could store all our parameters in a file and use it to recreate and track our experiments. However, sharing a file with our Jupyter Notebook means we also have to explain to our fellow data scientists how to use the file in case they wish to reproduce the experiment on their machine. To overcome these issues, we will use MLflow, MLflow provides a tracking server that helps us keep track of our experiment parameters.

The tracking server offers a centralized and expandable platform for managing and following machine learning experiments. MLflow tracking server keeps track of experiment parameters, including model hyperparameters, metrics, and artifacts (such as models, and graph plots), while the model is being developed. Multiple users and teams can track, compare, and replicate experiments cooperatively by using the tracking server.

Let us now start our model-building journey from a development environment most data scientists use - Jupyter Notebook. The iterative and exploratory nature of data analysis and machine learning tasks are well-suited to the flexible and interactive environment that Jupyter Notebooks offer. We will perform some simple exploratory data analysis on our income data and build a few models for classifying income. We'll also include some MLflow tracking logic, which will make it easier for us to replicate and keep track of our experiments.

### 4.1.1 Data Exploration

Let us first explore our income data by loading it and retrieving some basic descriptive stats by using Panda’s `describe` and info. Our data consists of only categorical variables (variables with a fixed number of values), which include workclass, education, marital status, occupation, relationship, race, sex, and native country. We then have our target variable which holds a binary value of <=50k or >50k.

Pandas `info` specifies that we have about 30,000 rows and `describe` sheds light on how many unique values are present in each category and specifies the most frequent category (specified by top) along with its frequency.

##### Listing 4.1 Generating descriptive stats for income data

```
df=pd.read_csv('../data/income_data.csv', index_col=False)
print(df.head() ,'\n') #A
print(df.info(), '\n')    #B
print(df.describe(), '\n')    #C
           Workclass   Education       Marital-Status          Occupation  \
0          State-gov   Bachelors        Never-married        Adm-clerical   
1   Self-emp-not-inc   Bachelors   Married-civ-spouse     Exec-managerial   
2            Private     HS-grad             Divorced   Handlers-cleaners   
3            Private        11th   Married-civ-spouse   Handlers-cleaners   
4            Private   Bachelors   Married-civ-spouse      Prof-specialty   
 
     Relationship    Race      Sex  Native_country  Target  
0   Not-in-family   White     Male   United-States   <=50K  
1         Husband   White     Male   United-States   <=50K  
2   Not-in-family   White     Male   United-States   <=50K  
3         Husband   Black     Male   United-States   <=50K  
4            Wife   Black   Female            Cuba   <=50K  
 
       Workclass Education       Marital-Status       Occupation Relationship  \
count      30162     30162                30162            30162        30162   
unique         7        16                    7               14            6   
top      Private   HS-grad   Married-civ-spouse   Prof-specialty      Husband   
freq       22286      9840                14065             4038        12463   
 
          Race    Sex  Native_country  Target  
count    30162  30162           30162   30162  
unique       5      2              41       2  
top      White   Male   United-States   <=50K  
freq     25933  20380           27504   22654   
<class 'pandas.core.frame.DataFrame'>
RangeIndex: 30162 entries, 0 to 30161
Data columns (total 9 columns):
 #   Column          Non-Null Count  Dtype 
---  ------          --------------  ----- 
 0   Workclass       30162 non-null  object
 1   Education       30162 non-null  object
 2   Marital-Status  30162 non-null  object
 3   Occupation      30162 non-null  object
 4   Relationship    30162 non-null  object
 5   Race            30162 non-null  object
 6   Sex             30162 non-null  object
 7   Native_country  30162 non-null  object
...
dtypes: object(9)
memory usage: 2.1+ MB
```

Let us now generate some plots to compare the distribution of the categorical variables with respect to the target variable. We will also save the plots in a directory `categorical_variable_plots`.

##### Listing 4.2 Comparing distribution categorical variable vs target variable

```
if not os.path.exists("categorical_variable_plots"):
        os.makedirs("categorical_variable_plots")    
for i in df.iloc[:,:-1].select_dtypes(include='object').columns:
        print(f'Variable {i}  \n ')
        print(df[i].value_counts())
        plot = ggplot(df)+ geom_bar(aes(x=df[i], fill=df.Target), position='fill')+ theme_bw() + labs(title=f'Variable {i} ~ Target')+ coord_flip()
        print(plot)    #A
        plot.save(f"categorical_variable_plots/Variable {i}")    #B
```

An example plot is shown in Figure 4.2:

![Figure 4.2 A plot comparing the workclass categories distribution with the target variable. For example self-employed people are more likely to be earning greater than 50k.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/04__image003.png)

### 4.1.2 MLflow Tracking

Mlflow tracking can help us save these plots to a tracking server. To start with that we must first install Mlflow.

```
pip install mlflow==2.6.0
```

Then we must start a local tracking server by running the command which will create a local tracking server at port 5000. This command needs to be run outside the notebook.

```
mlflow ui
[2023-09-22 13:50:58 +0800] [16047] [INFO] Starting gunicorn 21.2.0
[2023-09-22 13:50:58 +0800] [16047] [INFO] Listening at: http://127.0.0.1:5000
```

After starting the tracking server, we will proceed to initialize MLflow. This needs to be done once in our Jupyter notebook. We set the tracking server and specify an experiment name under which we want to store our parameters. An experiment name can be thought of as a project under which we want to track our parameters. We name our experiment as `income-classifier`.

```
mlflow.set_tracking_uri("http://localhost:5000")
mlflow.set_experiment("income-classifier")
```

We will now save our plots to the tracking server by adding two lines of code, the for loop is placed under a mlflow start run block. A single execution of a machine learning experiment or training procedure is referred to as a "run". Each run is associated with a unique identifier known as run ID and captures key parameters like metrics, model hyperparameters, and artifacts. In the below example, we are specifying the run name explicitly by using `uuid.uuid4()`which generates a unique name for each run. If we don't specify it MLFlow by default would generate an ID of its own. We just wanted to separate our EDA MLFlow runs from model-building runs`.` All the runs are in turn captured under an MLflow experiment. Artifacts can be model files, datasets, or even plots. In the below example, we save the plots by running `mlflow.log_artifacts` and specify the name of the directory where we store the plots.

##### Listing 4.3 Saving the plots in MLflow

```
with mlflow.start_run(run_name=f"eda-{uuid.uuid4()}"):    #A
    for i in df.iloc[:,:-1].select_dtypes(include='object').columns:
        print(f'Variable {i}  \n ')
        print(df[i].value_counts())
 
        plot = ggplot(df)+ geom_bar(aes(x=df[i], fill=df.Target), position='fill')+ theme_bw() + labs(title=f'Variable {i} ~ Target')+ coord_flip()
        print(plot)
        if not os.path.exists("categorical_variable_plots"):
            os.makedirs("categorical_variable_plots")
        plot.save(f"categorical_variable_plots/Variable {i}")
        mlflow.log_artifacts("categorical_variable_plots")    #B
```

If we now head over to the browser at `http://localhost:5000`, we can see the MLflow UI (Figure 4.3). We will see there are two experiments listed in the sidebar. One is the default experiment and the other is the experiment created by us to store our plots.

![Figure 4.3 MLflow UI - On the left we have the list of experiments which shows our newly created income-classifier experiment. After starting a MLflow run and saving the plots we can see a new entry under Run Name.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/04__image005.png)

We can click on the experiment and the newly created run, and we will proceed to the individual run page. This includes run description, any datasets generated from the run, model parameters, and metrics along with artifacts. The generated plots can be seen under the artifacts tab of the run (Figure 4.4).

![Figure 4.4 All the plots are present under artifacts. Run artifacts can include plots, files, and any object that can be saved on a disk.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/04__image007.png)

Let us proceed to the next step of building a model i.e., generating our dataset into test and training sets. For this, we first have to convert the categorical variables to dummy variables or boolean indicator variables. We do that using `pd.get_dummies`. We also encode our <=50k and > 50k to 0 and 1 by using one hot encoding. We also store our column names, which can be used later for performing inference. Finally, we split the dataset using the `train_test_split` function provided by Sklearn.

##### Listing 4.4 Converting categorical to dummy using one hot encoding

```
target=df.Target
feature_df=df.drop('Target', axis=1)
encoder=OneHotEncoder(sparse=False, drop='if_binary')    #A
target=encoder.fit_transform(np.array(target).reshape(-1,1))    
dummyfied_df=pd.get_dummies(feature_df, drop_first=True, sparse=False, dtype=float)    #B
col_list = dummyfied_df.columns.to_list()
with open('column_list.pkl', 'wb') as f:
     pickle.dump(col_list, f)    #C
X_train,X_test,y_train, y_test=train_test_split(dummyfied_df, target, train_size=0.80, shuffle=True)    #D
```

We need to save these datasets in an external location. This location is tracked by MLflow and allows us to load the dataset when needed for reproducibility or debugging. We will store our dataset in a MinIO bucket, keeping in mind we can choose any object store of our choice (GCS, S3).

The MinIO instance we are using is the same one used by Kubeflow. We will be running the Kubectl port forward to create a connection between our local workstation and the Minio instance.

```bash
kubectl port-forward svc/minio-service -n kubeflow 9000:9000
```

We can then connect to Minio from our browser login with the default username and password minio/minio123. Then proceed to create a new bucket by clicking on the bottom left button on the screen. We create a bucket called `mlflow-datasets`. In this bucket, we will store our datasets.

Now that we have set up our object storage and generated our train test datasets, let us build some models with MLflow tracking enabled. This means we will keep track of model parameters, the datasets, and the model metrics. We will build three models: a simple decision tree, a random forest model, and an XGboost model. Let us start with the decision tree model first.

We will first save our training, test and reference datasets in MinIO and log those paths in MLflow Reference datasets are the features dataset which include all the features for all users. This includes users in both training and testing. We need to convert our Pandas dataframe into an MLflow dataframe using `mlflow.data.from_pandas`. This method needs two parameters: the pandas dataframe and the external path of the dataframe. It creates an MLflow dataframe which can then be logged by MLflow log input. MLflow logs the metadata of the dataframe which includes the column information (name and type) and the number of rows. Then we proceed to fit the model and retrieve all the model accuracy and AUC metrics. We log those metrics using `mlflow.log_metric` by specifying the metric name and its value. We even log the model and its parameters by using`sklearn.log_model` and log_params respectively. MLflow provides support to multiple modeling libraries like Scikit learn, XGboost, Tensorflow, Pytorch and allows easy saving and loading of models.

##### Listing 4.5 Training a model with MLflow logging

```
BUCKET_NAME = "mlflow-datasets"
with mlflow.start_run() as run:
    results=pd.DataFrame(index=['Roc Auc Score test', 'Accuracy score train', 'Accuracy Score test','time to fit'])
    tree=DecisionTreeClassifier()
    run_id = run.info.run_id
    feature_df_path = f"income-classifier-datasets/feature_df-{run_id}.csv"
    save_df_to_minio(feature_df,BUCKET_NAME,feature_df_path)
    train_df = pd.concat([X_train,pd.Series(y_train.ravel())],axis=1)
    train_df_path = f"income-classifier-datasets/train-{run_id}.csv"
    save_df_to_minio(train_df,BUCKET_NAME,train_df_path)    #A
    test_df = pd.concat([X_test,pd.Series(y_test.ravel())],axis=1)
    test_df_path = f"income-classifier-datasets/test-{run_id}.csv"
    save_df_to_minio(test_df,BUCKET_NAME,test_df_path)    
    training_dataset = mlflow.data.from_pandas(train_df, source=f"{BUCKET_NAME}/{train_df_path}")    #B
    test_dataset = mlflow.data.from_pandas(test_df, source=f"{BUCKET_NAME}/{test_df_path}")
    feature_dataset = mlflow.data.from_pandas(feature_df, source=f"{BUCKET_NAME}/{feature_df_path}")   
    mlflow.log_input(training_dataset,context="training")    #C
    mlflow.log_input(test_dataset,context="testing")
    mlflow.log_input(feature_dataset,context="reference")    
    tree.fit(X_train, y_train.ravel())    #D
    roc_auc_score_train = roc_auc_score(y_train==1, tree.predict_proba(X_train)[:,1])    #E
    roc_auc_score_test = roc_auc_score(y_test==1, tree.predict_proba(X_test)[:,1])
    training_accuracy = tree.score(X_train, y_train)
    test_accuracy = tree.score(X_test, y_test)
    mlflow.log_metric("roc_auc_score_train",roc_auc_score_train)    #F
    print(f'Roc Auc Score train: {roc_auc_score_train}  \n')
    mlflow.log_metric("roc_auc_score_test",roc_auc_score_test)
    print(f'Roc Auc Score test: {roc_auc_score_test}  \n')
    mlflow.log_metric("training_accuracy",training_accuracy)
    print(f'Accuracy train : {training_accuracy}')
    mlflow.log_metric("test_accuracy",test_accuracy)
    print(f'Accuracy test : {test_accuracy}')
    mlflow.sklearn.log_model(tree,"income-classifier")    #G
    mlflow.log_params(tree.get_params())    #H
```

This generates an MLflow run and saves our dataset in MInIO. If we click on our recently generated run, we can see all the information we logged under the respective tabs (Figure 4.5).

![Figure 4.5 The datasets, model parameters, model metrics, and artifacts can all be seen under their respective dropdowns.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/04__image009.png)

We similarly build a random forest model and log the dataset, metrics, model, and parameters. Another helpful feature of MLflow is the auto-log functionality. Autolog automates the logging of various machine learning metrics and artifacts during the training and evaluation of machine learning models. It simplifies the process of tracking experiments and model performance by automatically logging relevant information without requiring explicit manual logging code. For our XGboost model, we will track the parameters using autolog. By specifying one line `mlflow.xgboost.autolog()`, we can enable autolog. Autolog however, does not log our custom metrics, which we have to do explicitly. It also logs the training dataset as an array and not a dataframe. We are however free to use other log methods under autolog to log parameters of interest in our desired format.

##### Listing 4.6 Using MLflow auto logging functionality

```
with mlflow.start_run():
    mlflow.xgboost.autolog()    #A
    n_round=30
    dtrain= xgb.DMatrix(data=X_train, label=y_train.ravel())
    dtest= xgb.DMatrix(data=X_test, label=y_test.ravel())
    params={"objective":"binary:logistic",'colsample_bytree': 1,'learning_rate': 1,
                    'max_depth': 10 , 'subsample':1}
    model=xgb.train(params,dtrain, n_round)
    ax = xgb.plot_importance(model, max_num_features=10, importance_type='cover')
    fig = ax.figure
    fig.set_size_inches(10, 8)
    pred_train= model.predict(dtrain)
    pred_test=model.predict(dtest)
    model=xgb.train(params={"objective":"binary:hinge",'colsample_bytree': 1,'learning_rate': 1,
                    'max_depth': 10 , 'subsample':1}, dtrain=dtrain)
    pred_train= model.predict(dtrain)
    pred_test=model.predict(dtest)
    roc_auc_score_train = roc_auc_score(y_train==1, pred_train)
    roc_auc_score_test = roc_auc_score(y_test==1, pred_test)
    training_accuracy = accuracy_score(y_train, pred_train)
    test_accuracy = accuracy_score(y_test, pred_test)
    mlflow.log_metric("roc_auc_score_train",roc_auc_score_train)    #B
    print(f'Roc Auc Score train: {roc_auc_score_train}  \n')
    mlflow.log_metric("roc_auc_score_test",roc_auc_score_test)
    print(f'Roc Auc Score test: {roc_auc_score_test}  \n')
    mlflow.log_metric("training_accuracy",training_accuracy)
    print(f'Accuracy train : {training_accuracy}')
    mlflow.log_metric("test_accuracy",test_accuracy)
    print(f'Accuracy test : {test_accuracy}')
```

The results of autlogging can be seen under the run. Auto-logging logs the model, plots, and model parameters without explicit logging (Figure 4.6).

![Figure 4.6 Auto-logging logs the model parameters and datasets without explicit logging. We even get feature importance plots automatically.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/04__image011.png)

### 4.1.3 MLflow Model Registry

We have built three models: a decision tree, a random forest model, and an Xgboost model. How do we select the best model of these three and save it? Now that we have logged all the model metrics of interest, we can just query MLflow to get us the best model. Once we have identified the best model, we can save it in the MLflow model registry. Model registry is another component of MLflow, it is a repository for managing machine learning models throughout their lifecycle. It helps us to collaborate effectively, track model versions, and ensure model governance and reproducibility.

We can identify the best model and register the model in two ways: Using the MLflow UI and the MFlow client.

#### Using UI

We can directly query from MLflow UI by specifying the query in the MLflow search bar. The query metrics.roc_auc_score_test > 0.8 gives us all models with an AUC score of our test set greater than 0.8. We can also click on the chart view to get a chart of the metric for each run (Figure 4.7), we can then easily pick the model that has the highest score. Using this we find out that the random forest model has the best AUC score.

![Figure 4.7 Using the MLflow UI to query runs that have a test AUC score < 0.8. Displaying the results in a chart view.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/04__image013.png)

#### MLflow Client

We can also do this programmatically by using the MLflow client. The MLflow client provides a programmatic interface for managing and querying machine learning experiments, tracking metrics, and accessing various functionalities of MLflow. We will use the client to search for the best model and register it in the MLflow model registry. We use the MLflow client object to retrieve the experiment ID by running `get_experiment_by_name` and `search_runs` is used for the filter runs by using the same filter string as above and we order it by `roc_auc_score_test`. We then retrieve a model URI which is retrieved by run id and experiment name. Using the model URI, we can register the model in the model registry by using `register_model`, we specify the model URI and the model name.

##### Listing 4.7 Retreive MLflow runs and register the model

```
from mlflow import MlflowClient
mlflow_client = MlflowClient()
experiment_name = "income-classifier"
experiment = mlflow_client.get_experiment_by_name(experiment_name)
run_object = mlflow_client.search_runs(experiment_ids=experiment.experiment_id,filter_string="metrics.roc_auc_score_test > 0.8",max_results=1,order_by=["metrics.roc_auc_score_test DESC"])[0]    #A
model_uri = f"runs:/{run_object.info.run_id}/{experiment_name}"    #B
mlflow.register_model(model_uri, "random-forest-classifier")    #C
```

The model is now registered with the name of random-forest-classifier and can be retrieved at inference time or if we wish to reproduce the experiment. We can view it in the UI by clicking the Models tab on the top navigation bar (Figure 4.8). Similar to how we move code from the staging platform to the production platform after testing, the model can be promoted to the different stages of Staging and Production.

![Figure 4.8. MLflow registered models can be seen under the models tab of the UI. Our Random Forest model can be seen here.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/04__image015.png)

In the above example, we deployed a local instance of MLflow, but a local instance does not enable collaboration. For this, we need to install MLflow in an environment that is accessible to all members of a team. This environment can be a cloud-based environment or on a Kubernetes cluster. We have provided instructions on how to install MLflow on the Kubernetes cluster in Appendix A. MLflow Tracking and Model Registry are the most commonly used components of MLflow. Take a look at the documentation at [https://mlflow.org/docs/latest/index.html](https://mlflow.org/docs/latest/index.html).

We have now built our first version of the model and registered it in the model registry. Before we productionize the model, we need to register our model features. In the upcoming section, we will use a feature store to register our features to ensure we get the appropriate features at the time of inference or retraining.

## 4.2 Feast As A Feature Store

Our income classifier features are luckily available in a single file. However, in realistic scenarios, our features would come from multiple tables or files, and we would have to write complex feature processing and joining logic to finally arrive at a dataset. Let us try simulating that with our current dataset. We will split our one file into three separate files (Figure 4.9), each file contains data from a single category of features: demographic, relationship, and occupation. The demographic features include sex, race, and native_country. Relationship features include marital status and relationship. Occupation includes workclass, education, and occupation. Each of these files will also contain the timestamp and user ID column.

![Figure 4.9 We split our single file into three files that represent three separate feature categories - demographic, relationship, and occupation.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/04__image017.png)

After defining our feature files, we need a way to retrieve the right features either during inference or at the time of retraining. What do we mean by the right features? Let's say for example we want to retrieve the features of a user (user_id) on the 22nd of May. We have recorded features at multiple timestamps for this user. We recorded them on the 7th of January, 20th May and 4th of December. The right features for the above case are the features that are the most recent to the 22nd of May i.e. the features recorded on the 21st of May. We need to incorporate this logic at the point of feature retrieval. We could write a script or an SQL query which will be another thing to maintain and debug or we could rely on a data abstraction layer provided by Feast the feature store. One of Feast’s main features is the ability to generate point-in-time correct feature sets so that data scientists can focus on feature engineering and not the joining logic.

These feature files can be moved over to a common location such as a MinIO bucket. We retrieve the features from this common location during both training and inference. A common process populates the feature set in MinIO; by doing so we decouple feature generation logic from our modeling logic. The other advantage of having a common location is the reusability and sharing of features across our team and organization. Feast enables us to make features accessible to other members of the team by providing a feature registry where we can register the features and query them when needed.

If we are building a real-time service, we would also expect our feature retrieval latency to be low. Feast ensures we can push our features from MinIO (an offline store) to a low-response latency database such as Redis (an online store).

Keeping all the above points in mind, let us take a look at the feature store design (Figure 4.10). We will have a feature computation process or pipeline that populates our feature sets in the offline store (data warehouse or object store). These datasets would be made available in the online store for real-time predictions by periodically pushing the features from the offline store to the online store. Feast calls this process materialization. At the heart of it, we have the feature registry which holds our feature definitions which include their location and names. We will also have an interface to easily retrieve the features from either the offline store or the online store. This would be the Feast Python SDK which provides methods to access data from both offline and online stores and also push or materialize data from the offline store to the online store. The offline features are used during model training and the online features are used by the model during inference.

Let us set up the Redis online store for Feast, and the datasets in MinIO. The instructions for this are provided in Appendix A.

![Figure 4.10 Feast feature store design involves a feature pipeline populating the offline store and periodically Feast materializes the offline features to the online store. Feature registry holds feature definitions along with online and offline store information. Feast SDK provides methods to retrieve features from online and offline stores which can be used for training and inference purposes.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/04__image019.png)

### 4.2.1 Registering Features

We will now register our features in Feast. To do so we need to register our entities. Entity refers to an identifier for which the features are collected. In our example, we are collecting our features for a user who has a unique user ID. The `user_id` is our entity. If we were recording features about products, product_id would be our entity. We will define our entities in entity.py.

In entity.py we define our user_id entity. We specify the name, description, and data type of the entity ( a string in our case)

##### Listing 4.8 Creating an Entity

```
from feast import Entity, ValueType
from feast.types import String
user = Entity(name="user_id", description="A user")    #A
```

We need to port-forward the MinIO service to our local so that Feast can register the feature source locations in the registry. We can port-forward the MinIO service to our local by running -

```bash
kubectl port-forward svc/minio-service 9000:9000 -n kubeflow
```

In this file, we will define each of our feature categories and their location in MinIO. For example, for our demographic features, we specify the source of files by specifying the file's path in MinIO as a s3 path. We also need to provide an s3 endpoint override which points to our port-forwarded MinIO service.

##### Listing 4.9 Defining the location of demographic feature file

```
demo_features_parquet_file_source = FileSource(
    file_format=ParquetFormat(),    #A
    path="s3://feature_data_sets/demographic_features.parquet",    #B
    s3_endpoint_override="http://localhost:9000",    #C
)
```

We then define our features using Feast’s FeatureView. A FeatureView is used to represent a logical grouping of features. We specify the name of the FeatureView and specify our entity name which is user. We then list down our features and specify a ttl (time to live). A ttl limits how far back Feast will look when generating historical datasets. While defining it we use `datetime timedelta` datatype to define it. For example, let’s say that we are generating the historical dataset for the 22nd of May and our ttl is two days. Feast will look back to data up to the 20th of May, any feature earlier than this would not be considered while generating the dataset. The reason for setting a limit would be to ensure we get the freshest features for our training and inference. We set our ttl to 365 days or one year because we want to ensure we get all the necessary features and are not limited by a small ttl. We then provide the source of this data which is the file source we defined above, and we can optionally specify some tags which help in feature readability and provide additional information about the features.

##### Listing 4.10 Defining the feature view

```
demo_features = FeatureView(
    name="demographic",
    entities=[user],    #A
    schema=[
        Field(name="Native_country", dtype=String),
        Field(name="Sex", dtype=String),
        Field(name="Race", dtype=String),
    ],    #B
    ttl=timedelta(days=365),    #C
    source=demo_features_parquet_file_source,    #D
    tags={
        "authors": "Benjamin Tan <benjamin.tan@abc.random.com, Varun Mallya <varun.mallya@abc.random.com",
        "description": "User Demographics",
        "used_by": "Income_Calculation_Team",
    },    #E
)
```

We do the same for other feature groups: relationship, and occupation. We then define our feature_store.yaml. This is our feature store config file, which lists the name of our feature registry project, the location of our registry, and the online and offline store configs. The registry can be thought of as a common location for all our feature and entity definitions; in our case it is a file called registry.db stored in the MinIO bucket feature-registry. Our offline store is of type Filestore, as our data are stored in files in MinIO. The online store is a Redis instance. We have to provide the connection string which holds the Redis IP along with the password.

##### Listing 4.11 Feature store configuration

```
project: my_feature_repo
registry: s3://feature-registry/registry.db    #A
provider: local    #B
offline_store:
  type: file    #C
online_store:
  type: redis    #D
  connection_string: "localhost:6379,password=lC1Xai2f2o"
```

Our feature repo folder would now look like this

```
├── entity.py
├── feature_store.yaml
├── features.py
```

We have now configured Feast and defined our features and entities, but we have not yet pushed any definitions to the feature registry. To do this we first need to port forward MinIO and Redis services to our local. This is necessary because we are going to register features and their sources, both offline and online. To port forward run

```bash
kubectl port-forward svc/minio-service 9000:9000 -n kubeflow
kubectl port-forward svc/redis-deployment-master 6379:6379 -n redis
```

After we do this we run the Feast apply command. The Feast `apply` command updates the feature registry with feature and entity definitions. The output of the command gives information on entities and feature views created. Deploying infrastructure signifies that Redis is set up to act as an online feature store.

```
feast apply
Created entity user_id
Created feature view relationship
Created feature view occupation
Created feature view demographic
Deploying infrastructure for relationship
Deploying infrastructure for occupation
Deploying infrastructure for demographic
```

### 4.2.2 Retrieving Features

Once our features are defined, we can retrieve them using the Feast SDK provided `get_historical_features`. This method needs two parameters. The first parameter is a Pandas dataframe which has our entity data, the user_id, and a timestamp. Keep in mind that the column names must be the entity name (user_id) and the timestamp column name must be event_timestamp. For our example let us consider the user "9f2ac416-06e1-44a0-87bd-d4787c85bf66” and the timestamp is 22nd May 2023. The second parameter is a list of features we need to retrieve for this user. If we wished to retrieve the feature Sex from the demographic feature view our feature list would look like

```
feature_list = ["demographic:Sex"]
```

We also need to specify the path of our feature_store.yaml file and initialize the feature store object. Once done we can retrieve our historical features.

##### Listing 4.12 Retrieving historical features

```
from datetime import datetime
import pandas as pd
from feast import FeatureStore
entity_df = pd.DataFrame.from_dict(
    {
        "user_id": ["9f2ac416-06e1-44a0-87bd-d4787c85bf66"],
        "event_timestamp": [
            datetime(2023, 1, 30, 10, 59, 42),
        ],
    }
)    #A
store = FeatureStore(repo_path=".")    #B
training_df = store.get_historical_features(
    entity_df=entity_df,
    features=[
        "demographic:Sex",
    ],
).to_df()    #C
print("----- Feature schema -----\n")
print(training_df.info())    #D
print("----- Example features -----\n")
print(training_df.head())    #E
```

The output of the above script gives us schema information about the training df. The training_df holds the demographic: Sex feature of one user with user_id 9f2ac416-06e1-44a0-87bd-d4787c85bf66.

```
----- Feature schema -----
 
<class 'pandas.core.frame.DataFrame'>
RangeIndex: 1 entries, 0 to 0
Data columns (total 3 columns):
 #   Column           Non-Null Count  Dtype              
---  ------           --------------  -----              
 0   user_id          1 non-null      object             
 1   event_timestamp  1 non-null      datetime64[ns, UTC]
 2   Sex              1 non-null      object             
dtypes: datetime64[ns, UTC](1), object(2)
memory usage: 152.0+ bytes
None
----- Example features -----
 
                                user_id           event_timestamp    Sex
0  9f2ac416-06e1-44a0-87bd-d4787c85bf66 2023-01-30 10:59:42+00:00   Male
```

Next let us try retrieving features from the online store. But before we do that, we need to push our data from the offline store to the online store. Feast provides a simple command to do this called`feast materialize`. We need to provide a start time (`START_TS`) and end time(`END_TS`) argument to the command. Feast will read all data between `START_TS` and `END_TS` from the offline store and write it to the online store.

```
START_TIME=”2022-09-16T00:00:00”
END_TIME=”2023-09-17T00:00:00”
feast materialize $START_TIME $END_TIME
relationship from 2022-09-16 00:00:00+08:00 to 2023-09-18 00:00:00+08:00:
100%|██████████████████████████████████████████████████████| 28066/28066 [00:01<00:00, 20350.45it/s]
occupation from 2022-09-16 00:00:00+08:00 to 2023-09-18 00:00:00+08:00:
100%|██████████████████████████████████████████████████████| 28066/28066 [00:01<00:00, 19162.95it/s]
demographic from 2022-09-16 00:00:00+08:00 to 2023-09-18 00:00:00+08:00:
100%|██████████████████████████████████████████████████████| 28066/28066 [00:01<00:00, 20267.80it/s]
```

Once our data is pushed we can use the `get_online_features`. This is similar to `get_historical_features` but it only retrieves the latest feature for a user_id.

##### Listing 4.13 Retrieving online features

```
from feast import FeatureStore
store = FeatureStore(repo_path=".")
online_features = store.get_online_features(
    features=[
        "demographic:Sex",    #A
    ],
    entity_rows=[{"user_id": "9f2ac416-06e1-44a0-87bd-d4787c85bf66"}],    #B
)
print(online_features.to_df())
```

We are now able to retrieve features from both the offline store and the online store. For cases where we wish to retrieve features for training or batch inference, we can use the `get_historical_features` and for use cases such as real-time inferences, we can use the `get_online_features`.

### 4.2.3 Feature Server

An additional option that Feast provides is a feature server. The feature server provides us with API endpoints that can be used to interact with the feature store. It is especially useful when our applications are written in programming languages that do not have a Feast SDK. To start a feature server on our local we can run the `feast serve` command:

```
feast serve
```

This launches a local server that can be used to retrieve features for a given user.

```
[2023-10-11 19:08:16 +0800] [12270] [INFO] Starting gunicorn 21.2.0
[2023-10-11 19:08:16 +0800] [12270] [INFO] Listening at: http://127.0.0.1:6566 (12270)
[2023-10-11 19:08:16 +0800] [12270] [INFO] Using worker: uvicorn.workers.UvicornWorker
[2023-10-11 19:08:16 +0800] [12278] [INFO] Booting worker with pid: 12278
[2023-10-11 19:08:18 +0800] [12278] [INFO] Started server process [12278]
[2023-10-11 19:08:18 +0800] [12278] [INFO] Waiting for application startup.
[2023-10-11 19:08:18 +0800] [12278] [INFO] Application startup complete.
[2023-10-11 19:08:32 +0800] [12270] [INFO] Handling signal: winch
```

We can then retrieve online features by running a curl command. We specify the list of features we want to retrieve and the user_id we wish to retrieve it for. The features are retrieved from the online feature store.

```
curl -X POST \
  "http://localhost:6566/get-online-features" \
  -d '{
    "features": [
     "demographic:Sex" 
 
    ],
    "entities": {
      "user_id": ["9f2ac416-06e1-44a0-87bd-d4787c85bf66"]
    }
  }'
```

This gives the following response. It specifies the feature and entity names along with their values.

```json
{
    "metadata": {
        "feature_names": [
            "user_id",
            "Sex"
        ]
    },
    "results": [
        {
            "values": [
                "9f2ac416-06e1-44a0-87bd-d4787c85bf66"
            ],
            "statuses": [
                "PRESENT"
            ],
            "event_timestamps": [
                "1970-01-01T00:00:00Z"
            ]
        },
        {
            "values": [
                " Male"
            ],
            "statuses": [
                "PRESENT"
            ],
            "event_timestamps": [
                "2023-01-24T06:52:20Z"
            ]
        }
    ]
}
```

### 4.2.4 Feast UI

Finally Feast also provides a simple UI which lists all the features and entities defined in our feature registry. This UI can be accessed by running the command feast ui:

```
feast ui
```

We can then access the Feast UI from our browser at `http://localhost:8888` (Figure 4.11). This UI gives us information about the features and entities registered in the registry. It also specifies the data sources of the features. We can even filter the feature view by tags (description and authors) which are displayed on the right side of the UI.

![Figure 4.11 Feast UI gives us an easy way to visualize the details of feature views and entities for all our projects.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/04__image021.png)

A feature store can significantly improve the efficiency, reliability, and maintainability of machine learning projects by providing a structured and centralized approach to feature management. Feast is one of the leading open-source feature stores available and has examples in their documentation ([https://docs.feast.dev/](https://docs.feast.dev/)) demonstrating integrations with other online and offline stores.

Now we have registered our model in MLflow and our features are registered in Feast. It's time to use our model and features for generating model predictions. In the next chapter, we will focus on pipeline orchestration to set up a batch inference pipeline using Kubeflow.

## 4.3 Summary

- An experiment tracker such as MLflow can be used for tracking model performance and hyperparameters during model training and evaluation
- MLflow Model Registry is a platform for managing, organizing, and versioning machine learning models, facilitating collaboration and deployment.
- Feast the feature store streamlines the management and sharing of curated, ready-to-use features for machine learning, enhancing model development and deployment.
- Feast enables point-in-time join to ensure the freshness of features at inference time
- Feast supports both historical feature retrieval using offline stores and low-latency retrieval using online stores.
