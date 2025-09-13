# 9 Model Training and Validation: Part 2

### This chapter covers

- Storing and retrieving datasets with VolumOps
- Using MLFLow and Tensorboard to track and visualize training
- Importance of lineage and experiment tracking

We left off in the last chapter after creating a simple pipeline to train the image detection model and talked a bit about storing and retrieving datasets. We also tried out the model locally to get a feel of how it works and to sort out obvious flaws. In this chapter, we take this a step further and implement steps to improve the robustness of the training pipeline and more importantly to bring visibility into the training process. As we build more models and the number of stakeholders in the model lifecycle increase, it becomes more important to have traceability and asynchronous observability in the training process. We also dive into Tensorboard that enables visibility into the model training part and then switch focus to MLFLow that enables lineage and model versioning. While not strictly necessary to train a model, this chapter dives into concepts that help us deliver models to production more comfortably and repeatedly with deterministic results.

Let's first start off with diving into a different way of accessing data within a pipeline, the VolumeOp.

## 9.1 Storing Data with VolumeOp

So far, we have used stream reads and direct connections to minio to access the datasets. The `VolumeOp` is another way to manage data volumes within a Kubeflow Pipeline and allows us to define and handle data volumes required by pipeline components directly in the pipeline code.

#### Refactoring the Pipeline with VolumeOp

The way we've been handling data in the pipeline so far isn't ideal. In particular:

- The full dataset is downloaded in the "Download dataset component
- The training, validation, and test dataset split are re-downloaded in the "Train model" component
- The validation dataset split is re-downloaded in the "Validate model" component

#### Efficient Dataset Management

When working with large datasets, it's crucial to manage them efficiently. Ideally, the dataset should only be downloaded once and then accessed through a persistent volume. This approach ensures that the dataset is readily available for training and testing without requiring repeated downloads.

However, MinIO isn't a traditional POSIX filesystem, making it challenging to treat it like a normal file system where files can be easily copied or moved around. To overcome this hurdle, we're introducing `VolumeOp`, which enables us to manipulate the dataset in a more flexible way:

![Figure 9.1 All the components depend on VolumeOp called "create-pvc".](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/09__image001.png)

By using VolumeOp, we can create components that depend on a single `VolumeOp`. This allows us to manage our dataset in a more efficient and scalable manner, ensuring seamless access to our data throughout the training process.

In the next few sections, we'll take you step-by-step in refactoring this pipeline to make use of `VolumeOp`. In the process, you'll start to see how the code gets simplified along the way.

### 9.1.1 Creating a VolumeOp

Creating a `VolumeOp` is quite similar to creating a component. We start at the pipeline definition followed by creating the `VolumeOp`. You specify a name, a resource name, followed by the mode. Most storage classes support "Read Write Once", so this is a safe option. Finally, you can specify the size of the volume:

##### Listing 9.1. VolumeOp to create a Pipeline PVC

```
@dsl.pipeline(name="YOLO Object Detection Pipeline")
def pipeline(epochs: int = 1,
             batch: int = 8,
             random_state: int = 42,
             yolo_model_name: str = "yolov8n_custom"):
 
    volume_op = dsl.VolumeOp(             #A
        name="Create PVC",                
        resource_name="pipeline-pvc",      
        modes=dsl.VOLUME_MODE_RWO,        #B
        size="20Gi",                      #C
    )    
    # more to come...
```

Next, we'll see how a downstream component uses the `VolumeOp`, starting with `download_op`.

### 9.1.2 Download Op using VolumeOp

In order to make use of VolumeOp, you'll need to use `.apply()`followed by `mount_pvc()`. The function takes in the name of the previously created VolumeOp, along with the mount point. This mount point will be referenced when we're writing to the volume.

##### Listing 9.2. Mounting the PVC in `download_op`.

```
from kfp.onprem import mount_pvc                                            #A
 
def pipeline(...):
    volume_op = ...
 
    download_op = download_task().apply(mount_pvc(                          #B 
        volume_op.outputs["name"], 'local-storage', '/mnt/pipeline'))       #B
 
    # more to come...
```

What's more interesting is how the definition of `download_dataset(),`the function used to create the component, changes. We've been able to vastly simplify the function. The MinIO code is no longer needed as we now just download the dataset into the volume created by `VolumeOp`:

##### Listing 9.3 Using the volume mount point to download the dataset.

```
def download_dataset(output_dir: str = "DATASET"):
    # Imports go here...
    url = "https://manning.box.com/shared/static/34dbdkmhahuafcxh0yhiqaf05rqnzjq9.gz"
 
    downloaded_file = "DATASET.gz"
 
    response = requests.get(url, stream=True)
    file_size = int(response.headers.get("Content-Length", 0))
    progress_bar = tqdm(total=file_size, unit="B", unit_scale=True)
 
    with open(downloaded_file, 'wb') as file:
        for chunk in response.iter_content(chunk_size=1024):
            progress_bar.update(len(chunk))
            file.write(chunk)
 
    with tarfile.open(downloaded_file, 'r:gz') as tar:
        tar.extractall(os.path.join("/", "mnt", "pipeline", output_dir)) # A
```

Now let's see how to do dataset splitting now that we have `VolumeOp`.

### 9.1.3 Splitting the Dataset Directly

To enable mounting of volumes for the `split_dataset_op` is similar to what you've just seen:

##### Listing 9.4. Mounting the volume in `split_dataset_op`.

```
def pipeline(...):
      # ...
    split_dataset_op = split_dataset_task(
        random_state=random_state
    ).apply(mount_pvc(
        volume_op.outputs["name"], 'local-storage', '/mnt/pipeline') #A
    ).after(download_op)
```

The pipeline code for `split_dataset_op` has simplified too. Instead of writing the file names of the images and labels the various splits, we take a more direct approach by moving the files into the various folders within the volume:

##### Listing 9.5 Simplified `split_dataset` function with VolumeOp.

```
def split_dataset(random_state: int):
    import os
    import glob
    import shutil
 
    images = list(glob.glob(                                                        #A
        os.path.join("/", "mnt", "pipeline", "DATASET", "DATA", "images", "**")))   #A
    labels = list(glob.glob(                                                        #B
        os.path.join("/", "mnt", "pipeline", "DATASET", "DATA", "labels", "**")))   #B
 
    from sklearn.model_selection import train_test_split
 
    train_ratio = 0.75
    validation_ratio = 0.15
    test_ratio = 0.10
 
    x_train, x_test, y_train, y_test = ...
    x_val, x_test, y_val, y_test = ...
 
    for splits in ["train", "test", "val"]:
        for x in ["images", "labels"]:
            os.makedirs(
        os.path.join("/", "mnt", "pipeline", "DATASET", "DATA", splits, x)) #C
 
    def move_files(objects, split, category):
        for source_object in objects:
            src = source_object.strip()
            dest = os.path.join(
"/", "mnt", "pipeline", "DATASET", "DATA", split, category,     #D
                  os.path.basename(source_object))              
            shutil.move(src, dest)                                               #D    
 
    move_files(x_train, "train", "images")                                       #E
    move_files(y_train, "train", "labels")
    # Same with "test" and "val"
    #...
```

### 9.1.4 Simplifying Model Training

This shouldn't come as a surprise: by mounting the volume in `train_model_op` using the `mount_pvc` function, we've significantly simplified our model training process. By leveraging `VolumeOp` to manage our dataset, we no longer need to manually download files from MinIO or worry about data configuration YAML file paths.

##### Listing 9.6 Mounting the volume in `train_model_op`.

```
def pipeline(...):
      # ...
    train_model_op = train_model_task(
        epochs=epochs,
        batch=batch,
        yolo_model_name=yolo_model_name
    ).apply(mount_pvc(                                                     #A
            volume_op.outputs["name"], 'local-storage', '/mnt/pipeline')   #A
    ).after(split_dataset_op)
```

Meanwhile, the function for `train_model` has been substantially simplified. In particular, the function signature no longer takes six `InputPath`arguments, and the MinIO code to download the files is gone. Note that we've also updated the path when creating the data configuration YAML file. What's left is code for creating the YAML file along with training the model:

##### Listing 9.7 Simplified `train_model` using the volume.

```
def train_model(epochs: int,
                batch: int,
                yolo_model_name: str,
                data_yaml_path: OutputPath(str)):
 
    data = {
        'path': '/mnt/pipeline/DATASET/DATA',                            #A
         # ...
    }
 
    # Code to create YAML file...
 
    model = YOLO('yolov8n.pt')
 
    results = model.train(
        data=data_yaml_full_path,
        project="/mnt/pipeline",                                           #B
       ...
   )
```

### 9.1.5 Simplifying Model Validation

It is the same story with model validation. Starting with the pipeline code:

##### Listing 9.8 Mounting the volume in `validate_model_op`

```
def pipeline(...):
      # ...
    validate_model_op = validate_model_task(
        data_yaml=train_model_op.outputs['data_yaml'],                     #A
        yolo_model_name=yolo_model_name,
    ).apply(
        mount_pvc(                                                         #B
            volume_op.outputs["name"], 'local-storage', '/mnt/pipeline'))  #B
```

The MinIO related code has also been removed. The `weights_path` has been constructed using the mount point as the root, which is then used to initialize the model:

##### Listing 9.9 Simplified `validate_model` using the volume.

```
def validate_model(data_yaml_path: InputPath(str),
                   yolo_model_name: str,
                   mlpipeline_metrics_path: OutputPath("Metrics")):
 
    weights_path = os.path.join(
        /", "mnt", "pipeline", yolo_model_name, "weights", "best.pt")      #A
    print(f"Loading weights at: {weights_path}")
 
    model = YOLO(weights_path) #B
 
    metrics = model.val(data=os.path.join(data_yaml_path, "data.yaml"))
    metrics_dict = {...}
 
    with open(mlpipeline_metrics_path, "w") as f:
        json.dump(metrics_dict, f)
```

As you can clearly see, using VolumeOp allowed us to vastly remove a lot of code, and also made storing data a whole lot simpler! There's also another cool use of VolumeOp, and that's tracking model training runs.

## 9.2 Tracking Training with TensorBoard

Often for long training runs, you'll want to be able to track the progress of model training. You might be familiar with TensorBoard, a visualization tool to visualize different aspects of your model training, from things like model graphs for loss and accuracy all the way to the model architecture.

YOLOv8, although not written using TensorFlow, also comes with support for TensorBoard. Kubeflow comes built-in with support for TensorBoard. However, in order to get that working with our object detection pipeline, we'll have to do a bit of work.

Currently, the YOLOv8 library creates logs that TensorBoard can consume in the `project` directory. What we'll do now is instead of using an OutputPath, where we let Kubeflow implicitly create a path, we pass in a `VolumeOp`, define a mount point, and then use that mount point as the `project`.

#### Launching a New Tensorboard

Before launching the Tensorboard, make sure that you have created a Pipeline Run and that at least the "create-pvc" operation has completed (there's a green checkmark):

![Figure 9.2 Make sure the VolumeOp has completed before launching Tensorboard.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/09__image002.png)

Once that's done, in the Kubeflow sidebar, select "Tensorboards" then click on "New Tensorboard":

![Figure 9.3 Creating a new Tensorboard in Kubeflow.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/09__image003.png)

This will bring up the following dialog box:

- Fill in a name for the Tensorboard. Here, we've used "yolo-object-detection:
- Select "PVC" in the radio select button
- For the PVC name, select the PVC name. In order to select the right one, the PVC name's prefix will match the one in any component. You can check this by clicking on any one of the components that's running/already ran:

![Figure 9.4 The name of the pipeline shows up when you click on the component.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/09__image004.png)

- Leave the "Mount Path" empty.

Once done, select the "CREATE" button:

![Figure 9.5 Creating a new Tensorboard and pointing to an existing pipeline PVC.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/09__image005.png)

After a while, Kubeflow will spin up a Tensorboard instance. Once you see the green checkmark, and the "CONNECT'' button becomes ungreyed, you can then click on "CONNECT":

![Figure 9.6 A successful Tensorboard instantiation.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/09__image006.png)

#### Tracking Training with TensorBoard

Long training runs can be tedious to monitor without proper visualization tools. That's where TensorBoard comes in – a powerful tool for visualizing various aspects of your model training.

Although YOLOv8 isn't built using TensorFlow, it still supports integration with TensorBoard. And, since Kubeflow comes pre-configured with support for TensorBoard, we can easily leverage this feature in our object detection pipeline – but only if we take a few extra steps.

#### Exploring YOLOv8's Default Graphs

Once connected to TensorBoard, you can explore various graphs provided by default with YOLOv8, such as the ones shown below:

![Figure 9.7 A selection of graphs made available by the YOLOv8 library.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/09__image007.png)

These mAP (mean Average Precision) graphs provide valuable insights into how well your object detection model is performing. By tracking these metrics, you can:

- Monitor model performance: Keep an eye on how your model's accuracy and precision change over time.
- Identify trends and patterns: Analyze the graphs to spot any correlations between hyperparameters, data quality, or other factors that might be affecting your model's performance.
- Optimize model training: Use these insights to adjust hyperparameters, experiment with different architectures, or fine-tune your model for better results.

By visualizing these metrics in TensorBoard, you'll gain a deeper understanding of how your object detection pipeline is performing and make data-driven decisions to improve it.

In addition to tracking metrics, TensorBoard also allows us to visualize our model architecture. This graph provides a clear representation of the flow of data through our YOLOv8 object detection model.

#### Understanding Model Complexity

By visualizing the model architecture, we can gain a deeper understanding of how it's processing inputs and making predictions. This is particularly useful when working with complex models like YOLOv8, which involves multiple layers and connections:

![Figure 9.8 Viewing the model architecture from Tensorboard](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/09__image008.png)

## 9.3 Movie recommender project

Now let's switch over to the second project to explore concepts in experiment and model management and columnar data management. In the previous chapter, we started the conversation around data and its management for the movie recommender where we created a data pipeline that saves data as parquet files. We don't specifically dive into data exploration, but in a normal workflow, there is extensive analysis and modeling that is done in an experimental setting ( like a notebook for example ) before we reach here. Since this book deals primarily with the scaffolding for ML, we choose to skip this part.

As of now, we have collected some data and have saved them to a MinIO bucket on our cluster. We have then split the data into train, test and validation splits. Finally, we have also run some rudimentary quality analysis on this data and are ready to begin using this data. In normal settings, this would be something like querying one or more data sources upstream, applying transformations to clean and process the data and save them to a data lake. All of this can be achieved with the foundations you now have.

In this section, we will build up on this and now focus on training a model. We will build components to check the quality of the incoming data, train a model with this data, define metrics for validating the model and finally try out the trained model in a notebook to give us some recommendations for movie night. We will also take a look at using MLFlow to log experiments and track model versions. While you can do this with Kubeflow, like in the object detection example, MLFlow provides an alternative and is a good tool to have in your team's toolkit.

##### NOTE

It's always a good idea to validate your assumptions about data just before using it. Although validation is done during the date creation process, re-validating the same assumptions before using the data to train or evaluate models makes sure that the data ingest and transform pipelines can be separated from the training and evaluation pipelines.

### 9.3.1 Reading data from MinIO and quality assurance.

We start with writing a component for checking the quality of data in the minio bucket. For now, we will re-use the component from the previous chapter, but we will update it with a few checks for our training needs. Specifically, we will look for proper schema and validating the data types. Although this seems simplistic, these checks catch the majority of issues that can creep in production and provide us with a repository of checks that we can add to as we discover more issues with the data. As with everything in ML operations, identifying quality issues is also an iterative process.

Unlike the previous example, here we try to read the data directly from minio. This approach is slightly faster to start training since there are no large copies required at the beginning of the training run and also helps us with not managing the shared volumeOp. Just to reiterate, both approaches of either copying in the whole dataset to a common shared volume at the beginning or reading directly from the minio bucket are both valid and heavily depend on the type of data in use.

##### NOTE

The problem with downloading data to a local drive is that it consumes more storage space and takes a while to download, leading to longer startup delays for training runs and increased storage costs. While we will delete the data at the end of the training run, this approach can be improved by directly reading data from a minio bucket. The catch here is that the dataloader components need to be re-written to handle the minio object store. This approach is also memory and network intensive during the training and is often slower compared to a local read.

In the beginning, we run the data quality assessment. Running simple QA scripts is enough to begin with, we can swap this component out for a more sophisticated suite like Evidently or other data quality platforms.

##### Listing 9.10 Data quality check

```
def check_dataset(bucket:str = 'datasets', dataset:str = 'ml-25m'):
    from pyarrow import fs, parquet
    print("Running QA")
    minio = fs.S3FileSystem(
        endpoint_override='http://minio-service.kubeflow:9000',
         access_key='minio',
         secret_key='minio123',
         scheme='http')
    train_parquet = minio.open_input_file(f'{bucket}/{dataset}/train.parquet.gzip')
    df = parquet.read_table(train_parquet).to_pandas()
    assert set(['user_id', 'item_id', 'rating']).issubset(df.columns), f'Unable to find a required column. Found {df.columns}'
    print('QA passed!')
```

##### NOTE

Set the env variable TTL_SECONDS_AFTER_WORKFLOW_FINISH set in ml-pipeline-persistenceagent pod to clear old VolumeOps.

### 9.3.2 Model training component

For the recommender model, we choose a simple matrix factorization model written in pytorch. While this model wouldn’t win any awards, it is simple enough to quickly train a model, and using a more capable framework like pytorch makes models easier to work with later.

##### Listing 9.11 Model training code

```
def train_model(model_embedding_factors=20, model_learning_rate=1e-3,model_hidden_dims=256, model_dropout_rate=0.2,
                optimizer_step_size=10, optimizer_gamma=0.1,
                training_epochs=30,
                train_batch_size=64, test_batch_size=64, shuffle_training_data=True, shuffle_testing_data=True):
    import torch
    from torch.autograd import Variable
    from torch.utils.data import DataLoader
    
    class MatrixFactorization(torch.nn.Module):  #A
        def __init__(self, n_users, n_items, n_factors, hidden_dim, dropout_rate):
            super().__init__()
            self.n_items = n_items
            self.user_factors = torch.nn.Embedding(n_users+1, 
                                               n_factors,
                                               sparse=False)
            self.item_factors = torch.nn.Embedding(n_items+1, 
                                               n_factors,
                                               sparse=False)
        
            self.linear = torch.nn.Linear(in_features=n_factors, out_features=hidden_dim)
            self.linear2 = torch.nn.Linear(in_features=hidden_dim, out_features=1)
            self.dropout = torch.nn.Dropout(p=dropout_rate)
            self.relu = torch.nn.ReLU()
        
        def forward(self, user, item):
            user_embedding = self.user_factors(user)
            item_embedding = self.item_factors(item)
            embeddding_vector = torch.mul(user_embedding, item_embedding)
            x = self.relu(self.linear(embeddding_vector))
            x = self.dropout(x)
            rating = self.linear2(x)
            return rating
    
    dataset_map = get_datasets_local(split=['train', 'test'])
```

```
The model is a simple Matrix factorization model that has embeddings for users and items and two hidden layers. We will not dive into the math of this model here, but resources are available online.
 
    model = MatrixFactorization(dataset_map['n_users'], dataset_map['n_items'], n_factors=model_embedding_factors, hidden_dim=model_hidden_dims, dropout_rate=model_dropout_rate)
 
    optimizer = torch.optim.SGD(model.parameters(), lr=model_learning_rate)
    scheduler = torch.optim.lr_scheduler.StepLR(optimizer, step_size=optimizer_step_size, gamma=optimizer_gamma)
    loss_func = torch.nn.L1Loss()
    train_dataloader = DataLoader(dataset_map['train'], batch_size=train_batch_size, shuffle=shuffle_training_data)
    test_dataloader = DataLoader(dataset_map['test'], batch_size=test_batch_size, shuffle=shuffle_testing_data)
 
        for train_iter in range(training_epochs):
            print(train_iter)
            model.train()
            t_loss = 0
            t_count = 0
            for row, col, rating in train_dataloader:
                prediction = model(row, col)
                loss = loss_func(prediction, rating.unsqueeze(1))
                t_loss += loss
                t_count += 1
 
                # Backpropagate
                loss.backward()
 
                # Update the parameters
                optimizer.step()
                optimizer.zero_grad()
            scheduler.step()
            model.eval()
            te_loss = 0
            te_count = 0
            print('Evaluating')
            with torch.no_grad():
                for row, col,rating in test_dataloader:
                    prediction = model(row, col)
                    loss = loss_func(prediction, rating.unsqueeze(1))
                    te_loss += loss
                    te_count += 1
            print(f"Test loss: {te_loss/te_count}")
            print(f"Train loss: {t_loss/t_count}")
```

The training loop is also fairly simple with a batched input and a testing loop that runs for every iteration. To make the training faster, you can run the test once every 5 iterations or so.

### 9.3.3 Metrics for evaluation

Now that we have a trained model, we need to define some metrics. As mentioned in chapter 2, evaluation metrics are usually derived from the business goals and should ideally be well defined before creating a model to achieve objectivity and better alignment with stakeholders. It also helps ML teams communicate across functions how good ( or bad ) the model is using a few concise numbers.

In our case, we set out to create a recommendation engine for movies. In most cases, this means that we need to evaluate how relevant a list of recommendations is for a given user and also how many correct recommendations are provided for a given user. We picked three rudimentary evaluation criteria, precision, recall and root mean squared error (RMS).

RMS is a measure of the error of predicted ratings, which means that for a perfect prediction, this value must be zero. Therefore, lower RMS values indicate better accuracy of a given model in providing recommendations.

Precision is a measure of how relevant a set of recommendations is for a given user, in other words, how good the set of recommendations are. In statistical terms, precision is the number of true positive predictions divided by the sum of true positive and false positive predictions. We consider the top 50 recommendations by the model to calculate precision. A high value of precision is desired.

Recall is a measure of how many relevant items are present in a list of recommendations. Intuitively, recall can be thought of as a measure of the quantity of valid recommendations. Statistically, recall is defined as the total number of true positives divided by the sum of false negatives and true positives. As with precision, we consider the top 50 recommendations for calculating recall. A high recall is desired.

##### NOTE

Metrics are the most important part of an evaluation workflow. Ideally, we have a few metrics that measure different aspects of performance and are validated for being properly descriptive. In our example, we use toy metrics as an example but in your production workflow, a lot of care must be put into designing and evaluating metrics to make sure they align with the business requirements. Remember, a model’s performance is judged by these few numbers and an improper selection here can cause us to discard the model that works perfectly or artificially inflate a poor model’s worth.

##### Listing 9.12 Model evaluation code

```
def validate_model(recommendation_model, top_k=50, threshold=3, val_batch_size=32):
    # https://pureai.substack.com/p/recommender-systems-with-pytorch
    from collections import defaultdict
    import torch
    from sklearn.metrics import mean_squared_error
 
    def calculate_precision_recall(user_ratings, k, threshold):
        user_ratings.sort(key=lambda x: x[0], reverse=True)
        n_rel = sum(x >= threshold for _, x in user_ratings)
        n_rec_k = sum(x >= threshold for x, _ in user_ratings[:k])
        n_rel_and_rec_k = sum((x >= threshold) and (y >= threshold) for y, x in user_ratings[:k])
 
        precision = n_rel_and_rec_k / n_rec_k if n_rec_k != 0 else 1
        recall = n_rel_and_rec_k / n_rel if n_rel != 0 else 1
        return precision, recall
 
    user_ratings_comparison = defaultdict(list)
 
    dataset_map = get_datasets_local(split=['val'])
    val_dataloader = DataLoader(dataset_map['val'], batch_size=val_batch_size, shuffle=True)
 
    y_pred = []
    y_true = []
 
    recommendation_model.eval()
 
    with torch.no_grad():
        for users, movies, ratings in val_dataloader:
            output = recommendation_model(users, movies)
 
            y_pred.append(output.sum().item() / len(users))
            y_true.append(ratings.sum().item() / len(users))
 
            for user, pred, true in zip(users, output, ratings):
                user_ratings_comparison[user.item()].append((pred[0].item(), true.item()))
 
    user_precisions = dict()
    user_based_recalls = dict()
 
    k = top_k
 
    for user_id, user_ratings in user_ratings_comparison.items():
        precision, recall = calculate_precision_recall(user_ratings, k, threshold)
        user_precisions[user_id] = precision
        user_based_recalls[user_id] = recall
 
 
    average_precision = sum(prec for prec in user_precisions.values()) / len(user_precisions)
    average_recall = sum(rec for rec in user_based_recalls.values()) / len(user_based_recalls)
    rms = mean_squared_error(y_true, y_pred, squared=False)
 
    print(f"precision_{k}: {average_precision:.4f}")
    print(f"recall_{k}: {average_recall:.4f}")
    print(f"rms: {rms:.4f}")
```

### 9.3.4 Experiment tracking with MLFlow

Now that we have the model training loop and defined metrics to judge how well our model performs, let's discuss a core tenet of ML, experiment tracking. To illustrate the importance of tracking, let's try a toy sample training job with the default parameters and see how well it performs on our metrics.

Test run parameters: 6400 random data samples, train and test batch size of 64, trained for 30 epochs. All other parameters kept default.

| <br>      <br>      <br>        Precision @ 50 <br>       <br> | <br>      <br>      <br>        Recall for top 50 results <br>       <br> | <br>      <br>      <br>        RMS <br>       <br> |
| --- | --- | --- |
| <br>     <br>       0.7533 <br> | <br>     <br>       0.6316 <br> | <br>     <br>       0.2904 <br> |

While the model is okay, how about if we change some hyperparameters and retry that? Let's try modifying the learning rate to see how well the model performs.

Test run parameters: 6400 random data samples, train and test batch size of 64, learning rate of 1e-2, trained for 30 epochs. All other parameters kept default.

| <br>      <br>      <br>        Precision @ 50 <br>       <br> | <br>      <br>      <br>        Recall for top 50 results <br>       <br> | <br>      <br>      <br>        RMS <br>       <br> |
| --- | --- | --- |
| <br>     <br>       0.7422 <br> | <br>     <br>       0.8649 <br> | <br>     <br>       0.2836 <br> |

That run performed slightly worse than before, so let's track back and restore the parameters. But what was the original learning rate and set of hyperparameters? Was the optimizer the same?

Admittedly, this is a bit of a simple example, and we can answer the questions by undoing the changes on our codebase. The problem becomes apparent when we scale this up and consider the case when many experiments run in multiple large teams across multiple days and months. How would we keep track of all of them across time and team members? We could maintain a large spreadsheet, but there is no guarantee that the experiment someone conducts is accurately logged and we have a full set of hyperparameters to reproduce a run. This problem is even worse when a model performs a certain way in production and to arrive at the root cause, we need to replicate the training regime and parameters or as is often the case, in case of evolving datasets, the training dataset version.

Enter experiment tracking frameworks. You have had a small taste of model comparison and training run monitoring with Tensorboard in the previous project and now we will use a new framework for monitoring multiple runs across time, MLFlow. While tensorboard focused on understanding the training process itself, MLFlow excels at logging and indexing the model hyperparameters, training dataset version, model training code version and finally even logging the model. In our experience, using Tensorboard for model training analysis and MLFLow for experiment tracking and model versioning is often the best recipe. While MLFlow does offer some training metrics and comparisons between experiments, this comes up a bit short when compared to the rich visualization and ecosystem that Tensorboard provides. On the other hand, MLFLow offers strong experiment indexing and search functions and combined with the model registry is much better suited for tracking experiments in large teams.

##### NOTE

Uploading artifacts to MLFlow from our training code is a bit more complex than it initially appears. In its normal operational mode, the training environment needs to have independent access to the model artifact storage location. For example, if we use S3 as the model storage layer, the training environment must have the credentials setup for S3 access. To overcome this, we can run the MLFlow tracking server in proxied access mode where model storage is routed through the MLFlow tracking server and the training code only communicates with the tracking server. This is the most convenient set up for most use cases but does introduce the bottleneck of a single endpoint serving large file uploads. If you have set up your training nodes correctly, it's often better for performance for the training code to communicate directly with the storage backends and only communicate the metadata to the tracking server.

Let's start with integrating MLFLow into our training and evaluation codebases.

##### Listing 9.13 Model training code with MLFlow tracking

```
def train_model(mlflow_experiment_name='recommender', mlflow_run_id=None, mlflow_tags={},
                hot_reload_model_run_id=None,
                model_embedding_factors=20, model_learning_rate=1e-3,model_hidden_dims=256, model_dropout_rate=0.2,
                optimizer_step_size=10, optimizer_gamma=0.1,
                training_epochs=30,
                train_batch_size=64, test_batch_size=64, shuffle_training_data=True, shuffle_testing_data=True):
    import torch
    from torch.autograd import Variable
    from torch.utils.data import DataLoader
    import mlflow #A
    from torchinfo import summary #A
    from mlflow.models import infer_signature #A
    input_params = {}
    for k, v in locals().items():  #A
        if k == 'input_params':
            continue
        input_params[k] = v
 
    
    class MatrixFactorization(torch.nn.Module):
 
   . . .
    
    if hot_reload_model_run_id is not None: #B
        model_uri = f"runs:/{hot_reload_model_run_id}/model" #B
        model = mlflow.pytorch.load_model(model_uri) #B
    else:
        model = MatrixFactorization( . . .
 . . .
 
    # Create a new MLflow Experiment
    mlflow.set_experiment(mlflow_experiment_name) #A
 
    with mlflow.start_run(run_id=mlflow_run_id): #A
        for k,v in input_params.items():
            if 'mlflow_' not in k:
                mlflow.log_param(k, v) #A
        mlflow.log_param("loss_function", loss_func.__class__.__name__) #A
        mlflow.log_param("optimizer", "SGD")  #A
        mlflow.log_params({'n_user': dataset_map['n_users'], 'n_items': dataset_map['n_items']})  #A
    
        for k,v in mlflow_tags.items():
            mlflow.set_tag(k, v) #A
 
        with open("model_summary.txt", "w") as f:
            f.write(str(summary(model)))
        mlflow.log_artifact("model_summary.txt") #C
 
        model_signature = None
 
        for train_iter in range(training_epochs):
            print(train_iter)
            model.train()
            t_loss = 0
            t_count = 0
            for row, col, rating in train_dataloader:
                # Predict and calculate loss
                #try:
                prediction = model(row, col)
                if model_signature is None:
                    model_signature = infer_signature({'user': row.cpu().detach().numpy(), 'movie': col.cpu().detach().numpy()}, prediction.cpu().detach().numpy()) #C
 
                loss = loss_func(prediction, rating.unsqueeze(1))
 . . .
            mlflow.log_metric("avg_training_loss", f"{(t_loss/t_count):3f}", step=train_iter) #A
            scheduler.step()
            model.eval()
. . .
            with torch.no_grad():
                for row, col,rating in test_dataloader:
                    prediction = model(row, col)
                    loss = loss_func(prediction, rating.unsqueeze(1))
                    te_loss += loss
                    te_count += 1
            mlflow.log_metric("avg_testing_loss", f"{(te_loss/te_count):3f}", step=train_iter) #A
            print(f"Test loss: {te_loss/te_count}")
            print(f"Train loss: {t_loss/t_count}")
 
        mlflow.pytorch.log_model(model, "model", signature=model_signature) #C
```

The annotations show all the new lines we have added to add some interesting functionality to our code. To start with, we log all input hyperparameters and metrics like the type of optimizer used in the current experiment. Finally, you would also notice that we log some metrics like the average train/test losses for the training run. We also add the ability to load a previously trained model from mlflow so that we can warm restart a training. We also go over some code to show how to log artifacts like a model summary, infer a model's input / output signature and finally log a model to MLFLow with the signature so that we can load the model directly from MLFLow without the need for additional documentation.

Adding MLFlow to the mix in the training code brings some enormous benefits right off the bat. Traceability of hyper parameters enables us to move faster without having to worry about manually remembering to keep track of all our experiments and parameters. We can directly save to and retrieve the model from a central server now, moving the burden of the model storage infrastructure away from a developer. The ability to warm-start training from a previous run is also enabled by a central storage concept. Finally, having detailed documentation of a model including its inputs, outputs and model architecture means that even if we do need to go back to analyze models or quickly run an inference to test a theory, all developers need only look at MLFLow.

At this point, you might already be seeing the inherent benefits of auto-tracking the experiments, but let's take it a step further and integrate the tracking code into model validation. This enables us to separate the model training and evaluation workflows making the evaluation component more portable.

##### Listing 9.14 Model validation code with MLFlow tracking

```
def validate_model(model_run_id, top_k=50, threshold=3, val_batch_size=32):
    # https://pureai.substack.com/p/recommender-systems-with-pytorch
    from collections import defaultdict
    import torch
    import mlflow.pytorch
    import mlflow
    from sklearn.metrics import mean_squared_error
 
    model_uri = f"runs:/{model_run_id}/model" #A
    recommendation_model = mlflow.pytorch.load_model(model_uri) #A
 
    . . .
 
    average_precision = sum(prec for prec in user_precisions.values()) / len(user_precisions)
    average_recall = sum(rec for rec in user_based_recalls.values()) / len(user_based_recalls)
    rms = mean_squared_error(y_true, y_pred, squared=False)
   . . .
    mlflow.log_metric(f"precision_{k}", average_precision, run_id=model_run_id) #B
    mlflow.log_metric(f"recall_{k}", average_recall, run_id=model_run_id) #B
    mlflow.log_metric("rms", rms, run_id=model_run_id) #B
```

In the code above we load the model directly from MLFLow, without the need for the original model class or downloading the weights manually. MLFlow manages all the runs on the central server making it easy for us to reference model weights and metrics all from an API call. The method takes a run id as input so that it can retrieve the model from MLFLow directly to perform inference. The run id can be taken from MLFlow directly or from the outputs of the training method as specified above.

We also log metrics to an experiment in the above code. The interesting thing to note here is that although the experiment is completed, we can still log metrics to it.

Now that we have integrated MLFlow into our code, let's try running it. You will see that as soon as you begin the training loop, there is a new run created under the experiments tab and it has a bunch of interesting fields. Clicking on the run gives further details on the run itself like the training parameters and progression of metrics through the training runs. Wait for a bit to let the training complete and now you should see the models that are logged as well with even some sample code to run the model.

To truly see where MLFlow shines, let's edit some hyperparameters and run a few more experiments. Let's repeat our previous example of editing the learning rate to 1e-2. First, run the training with the defaults and evaluate the metrics. Then, modify the learning rate and repeat the process.

Once you run both experiments, select multiple experiments and hit compare. The effects of changing hyperparameters on the model metrics and what set of parameters appear to work well are now easily accessible. We can even tag and add descriptions to the runs to make sure that the larger team understands the context of the experiments and to make a group of runs searchable with tags. This is really helpful when conducting large scale experiments ( as with Khatib or other hyper parameter search tools ) and to collaborate with a team on running experiments and quickly explaining the comparison between models to stakeholders. Having a dashboard with model performance also provides a single pane of glass for the organization to see the experiments and not having to wait on a data scientist or ML engineer to provide information on how a model is performing. In our experience, this asynchronous mode of communicating the models is often the best as status updates are inherently enabled by linking to this dashboard. The dashboard in figure 8.24 shows a comparison of two model metrics and performance that enables stakeholders to quickly analyze models in a single pane.

![Figure 9.9 Example of a model dashboard and metrics on MLFlow](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/09__image009.png)

### 9.3.5 Model registry with MLFlow

Now that we have the experiments indexed and available in MLFlow, let's take a look at the next capability that MLFlow provides, model management. We have already seen how MLFlow enables us to log the trained models, but we can take it one step further and manage the entire lifecycle of a model in MLFlow. This capability is especially powerful in a highly automated MLOps setup where the end-to-end model training and deployment is automated, but having a manual checkpoint on model promotion from dev to production to staging is often necessary. A model registry also serves as a single source of all models and provides an API for working with them, making management and complex tasks like model serving simpler. Finally, model registries enable teams to deploy models to production while being confident of the model lineage by having strong traceability baked into them.

To begin with, we need to understand how models are handled in MLFlow. During experiments, models are logged with their hyperparameters and code as part of an experiment run. In a normal setting, we can have quite a lot of experiments for a given problem from both manual testing as well as automated methods like hyperparameter search. Once a model satisfies certain criteria, it is then registered under a unique alias like dev.ml_components.recommender in the model registry. A model that is registered has a unique name, versions and can have aliases and other metadata associated with it. Once a model satisfies production criteria, it can then be copied into another model called something like prod.ml_components.recommender. As you can imagine, this production model will also have multiple versions over time and we will use a model alias to point to a specific version denoting its status as being actively used. This workflow enables good lineage tracking as well specific quality gates where we can introduce different criteria to promote models. Finally, it also enables fast rollbacks by changing the alias of the version in production.

The first way of registering a model is via the web UI. The interface provides an easy way of manually registering a logged model. Try creating a model called ‘staging’ with the mlflow UI. Refer to the appendix for details on how to create a model.

Now that we have created a staging model placeholder, let's write a component that will register a model to a named stage in MLFlow. In this component we can take the stage name as an input parameter so that the component can be reused.

##### Listing 9.15 Model promotion to staging

```
def promote_model_to_staging(
new_model_run_id, 
registered_model_name='recommender_production', 
rms_threshold=0.0, 
precision_threshold=-0.3, 
recall_threshold=-0.2):
    import mlflow.pytorch
    import mlflow
    from mlflow import MlflowClient
    from mlflow.exceptions import RestException
    client = MlflowClient()
    current_staging = None
    try:
        current_staging = client.get_model_version_by_alias(registered_model_name, "staging")
    except RestException:
        print("No staging model found. Auto upgrade current run to staging.")
    
    if current_staging.run_id == new_model_run_id:
        print("Input run is already the current staging.")
        return
    if current_staging is not None:
        current_staging_model_data = client.get_run(current_staging.run_id).data.to_dictionary()
        staging_model_metrics = current_staging_model_data['metrics']
 
        new_model_data = client.get_run(new_model_run_id).data.to_dictionary()
        new_model_metrics = new_model_data['metrics']
 
        if (new_model_metrics['rms'] - staging_model_metrics['rms']) > rms_threshold:
            return
 
        if (new_model_metrics['precision_50'] - staging_model_metrics['precision_50']) < precision_threshold:
            return
        
        if (new_model_metrics['recall_50'] - staging_model_metrics['recall_50']) < recall_threshold:
            return
 
    result = mlflow.register_model(f"runs:/{new_model_run_id}/model", "recommender_production") #A
    client.set_registered_model_alias("recommender_production", "staging", result.version) #A
```

The example above only compares the newly trained model with the current staging model. The idea is that promotion to production must be a manual process with reviews in some cases, but if an organization prefers a highly automated setup, we can add some empirical model tests and promote a model directly to production similar to above. The designations of production and staging are merely aliases in the model registry and work exactly the same way. In the next chapter, we will use these tags to retrieve models while creating the inference engine, thereby completing the chain from data to inference.

The other way of promoting a model is to use the API which closely follows the UI experience. Documentation of the process is available on MLFLow’s official docs.

### 9.3.6 Creating a pipeline from components

As with the previous chapter, let's now compile the functions into components and connect them to create a pipeline. We won't go into much detail about this pipeline since we spent a good amount of time discussing the components.

##### Listing 9.16 Full pipeline - compiling components

```
import kfp
import kfp.components as comp
check_dataset_op = comp.create_component_from_func(check_dataset, output_component_file='qa_component.yaml', packages_to_install=["pyarrow", "pandas"])
Validate_model_op = comp.create_component_from_func(validate_model, output_component_file='model_validation_component.yaml', base_image="huggingface/transformers-pytorch-cpu", packages_to_install=["pyarrow", "pandas", "mlflow"])
promote_model_to_staging_op = comp.create_component_from_func(promote_model_to_staging, output_component_file='model_promotion_component.yaml', packages_to_install=["mlflow"])
 
train_model_op = comp.create_component_from_func(train_model, output_component_file='train_component.yaml', base_image="huggingface/transformers-pytorch-cpu", packages_to_install=["boto3", "pyarrow", "pyyaml", "mlflow"])
import kfp.dsl as dsl
client = kfp.Client()
@dsl.pipeline(
name='Model training pipeline',
description='A pipeline to train models on the movielens dataset for recommenders')
def training_pipeline(
minio_bucket:str='datasets',
dataset: str ='ml-25m',
mlflow_experiment='recommender',
trainig_batch_size: int = 64,
testing_batch_size: int = 64,
training_learning_rate:float = 0.001,
training_factors: int = 20,
training_dims: int = 256,
training_dropout: float = 0.2,
training_epochs: int = 30,
optimizer_step_size: float= 10.0,
optimizer_gamma: float = 0.1,
shuffle_training_data: int = 1,
shuffle_testing_data: int = 1,
validation_top_k:int = 50,
validation_threshold: float = 3.0,
validation_batch_size:int = 32,
registered_model_name: str = 'recommender_production',
registration_rms_threshold: float = 0.0,
registration_precision_threshold: float = -0.3,
registraion_recall_threshold: float = -0.2):
    
qa = check_dataset_op(bucket = minio_bucket, dataset = dataset)
    
training_op = train_model_op(
        mlflow_experiment_name=mlflow_experiment,
        hot_reload_model_run_id=None,
        model_embedding_factors=training_factors,
        model_learning_rate=training_learning_rate,
        model_hidden_dims=training_dims,
        model_dropout_rate=training_dropout,
        optimizer_step_size=optimizer_step_size,
        optimizer_gamma=optimizer_gamma,
        training_epochs=training_epochs,
        train_batch_size=trainig_batch_size,
        test_batch_size=testing_batch_size,
        shuffle_training_data=shuffle_training_data,
        shuffle_testing_data=shuffle_testing_data).after(qa)

validate_model(
        model_run_id=training_op.output, 
        top_k=validation_top_k, 
        threshold=validation_threshold, 
        val_batch_size=validation_batch_size).after(training_op)

promote_model_to_staging(
        new_model_run_id=training_op.output,
        registered_model_name=registered_model_name,
        rms_threshold=registration_rms_threshold,
        precision_threshold=registration_precision_threshold,
        recall_threshold=registraion_recall_threshold).after(validate_model)

kfp.compiler.Compiler().compile(
    pipeline_func=training_pipeline,
    package_path='dataPrep_pipeline.yaml')
```

Listing 8.32 must be quite familiar to you by now. We compile all the functions into components and combine the components into a pipeline. We then compile this pipeline and use mlflow and minio to manage the models and data. This pipeline has a lot of inputs since it does quite a few things. You can break this up and use a pipeline to trigger another pipeline. In kubeflow, pipelines themselves can be components that are combined together.

### 9.3.7 Local inference in a notebook

Now that we have a trained model and assuming we have promoted one to production, let's give this model a spin! We will write a quick script to reference the model from the run and pass in a user to generate some recommendations.

##### Listing 9.17 Inference in a notebook

```
import torch
import mlflow
from mlflow import MlflowClient
import pandas as pd
import os
class RecommendationSystem:
    def __init__(self, registered_model_name, device='cpu'):
        client = MlflowClient()
        current_prod = client.get_model_version_by_alias(registered_model_name, "prod") #A
        model_uri = f"runs:/{current_prod.run_id}/model" #A
        self.model = mlflow.pytorch.load_model(model_uri) #A
        self.device = device
        self.model.to(self.device)
        self.movie_map = self.generate_map('/Users/shanoop/Downloads/ml-25m')
    
    def generate_map (self, path):
        names = ['movie_id', 'title', 'genres']
        ratings_df = pd.read_csv(os.path.join(path, 'movies.csv'), names=names, index_col=False, skiprows=1)
        return ratings_df
    
    def movieID_to_name(self, ids):
        movies = self.movie_map.loc[self.movie_map['movie_id'].isin(ids)]
        return movies
 
    def recommend(self, user_id, top_k=10, ranked_movies=None):
         user_id = torch.tensor([user_id], dtype=torch.long).to(self.device)
all_items = torch.arange(1, self.model.n_items + 1, dtype=torch.long).to(self.device)
        
        # Remove already ranked movies from the list of all items
        if ranked_movies is not None:
            ranked_movies = torch.tensor(ranked_movies, dtype=torch.long).to(self.device)
            unrated_items = all_items[~torch.isin(all_items, ranked_movies)]
        else:
            unrated_items = all_items
        user_ids = user_id.repeat(len(unrated_items))
        # Predict ratings for all unrated items
        with torch.no_grad():
            self.model.eval()
            predictions = self.model(user_ids, unrated_items).squeeze()
        
        # Get the item with the highest predicted rating
        top_n_indices = torch.topk(predictions, top_k).indices
        recommended_items = unrated_items[top_n_indices].cpu().numpy()
        return self.movieID_to_name(recommended_items.tolist())
```

The code in listing 8.33 is very similar to the validation code. Thanks to the model registry APIs, we don't need the model definition or class. Since we have logged the input and output tensors as well as named them with their dimensions, the end user can easily infer using the model. This will come into play a bit more in the next chapter when we use BentoML and inference frameworks to automatically generate inference servers from the model definitions directly from MLFLow!

Try out the model and see what recommendations it gives for a specific user! In our experiments the model predicted the following movies for user 50.

![Figure 9.10 Recommendations from a trained model](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/09__image010.png)

Looking at the viewing history, we can see that the user is indeed a fan of children’s movies and drama

![Figure 9.11 Example of movies viewed by user 50](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/09__image011.png)

We can see how a fairly simple model can deliver passable results and can continue to improve by itself when part of the larger MLOps workflow. Assuming automated data collection and training runs like we have set up so far, the model will continue to see more data and generalize better over time. Of course, model performance will be capped at some point and will need an architecture change to have further gains, but our infrastructure set up so far should go a long way in making this whole process simpler. In fact, the code base has an alternate model that uses a slightly different approach to combining the embeddings for users and movies. Try giving it a spin and comparing with the previous model.

Let's take a minute to appreciate how far we have come. You are now equipped to create pipelines to handle data and perform ETL on it and store the cleaned data in a store ( we used minio, but any other destination also follows the same method ). We then created a pipeline to train a model on the data, parameterized it and implemented monitoring using Tensorboard and MLFlow for the training process. We also looked at MLFLow that helps act as a central repository for models and experiments and leveraged it to build complex pipelines that implement validation, inference and moving the models through different lifecycle stages, with an API. We also discussed VolumeOps that help speed up training especially for larger data like images by sharing a volume among all components. You now have the skills to implement automated pipelines that take in raw data at one end and provide trained models at the other. This is a fairly large milestone, so congrats on making it this far!

In the next section, we'll learn how to serve the object detection model with BentoML, a promising open-source platform for enabling robust and scalable production-ready machine learning services and workflow. See you in the next chapter!

## 9.4 Summary

- A VolumeOp is usually a better way to handle large datasets within a training pipeline and overcomes the drawback of having to download the full dataset everytime a training is run.
- Like models, the extended training artifacts are important to track. These include metrics, hyperparameter sets and validation examples. Well kept lineage helps debug issues in production faster.
- MLFLow and Tensorboard help track experiments and training runs. While they both appear to do the same thing, MLFLow is best used for multiple experiment tracking and artifact storage while Tensorboard offers more introspective capabilities for a single run.
- Having a central tracking, model and experiment tracking system like MLFlow provides organizational benefits in addition to the easier workflow for developers. A single window helps keep the stakeholders, project management and developers in sync with respect to model capabilities and performance.
- Evaluation metrics are key in model development since they judge the model’s performance. These can also evolve over the course of a model's lifetime so evaluation frameworks must support iterative improvement.
- Manual evaluation of a model is important. Although good metrics can predict performance, it is faster to debug model issues manually in the beginning and build upon the metrics to better represent performance. This means that the model registry must be easily accessible and model download simple. Using registries like MLFLow that provide an API to download the model helps here.
