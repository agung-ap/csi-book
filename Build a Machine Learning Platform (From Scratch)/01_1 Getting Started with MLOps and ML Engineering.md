# 1 Getting Started with MLOps and ML Engineering

### This chapter covers

- Machine Learning life cycle
- Why MLOps is hard
- MLOps + Machine Learning Engineering == MLE
- Building a Machine Learning Platform
- Building Machine Learning Systems

Welcome fellow or aspiring Machine Learning Engineer (MLE)! Machine Learning Operations (MLOps) is still very much a nascent field. Executing successful Machine Learning projects is hard, and you might have heard that most Machine Learning projects end up as failures. Part of the reason for this is due to the sheer complexity, as you shall soon see, due to the many moving pieces.

For the purposes of the book, when we are talking about a Machine Learning Engineer, we're referring to a person that has both ML operations and engineering experience, and this book is going to cover both. This means you'll learn how to:

- Build an ML Platform
- Build and Deploy ML Pipelines
- Extend the ML Platform using various tools depending on use cases
- Implement different kinds of ML services using the ML life cycle as a mental model
- Deploy ML services that are reliable and scalable

These are what we do day-to-day, therefore instead of having a clean separation of both topics, we'd address both, but not call out each of them explicitly as MLOps or ML Engineering specifically.

In this chapter, we will introduce the Machine Learning life cycle. The goal of the ML life cycle is to make sure our ML models perform well and are useful. Then we'll dig into what exactly makes MLOps hard, which when reframed, are the skills we look for when hiring for MLEs.

MLOps often gets confused with DevOps, and MLOps often gets conflated with ML Engineering. We'll clear up the confusion but this book covers quite a bit of both! The reality is that across multiple organizations, there is often no clear-cut definition of what an MLE should do.

It is not uncommon to be the first MLE hire, whether at a startup or at a new-ish company. This presents an exciting (and intimidating) opportunity because often the first order of things is to set up an ML Platform. This book will take you on a journey to set one up. As we progress through the book, we will extend and expand the ML Platform.

Once we have the ML Platform up and running, the next order of business is creating ML systems. We'll give an overview of the two projects that we'll build from scratch. While every company and domain is different, across different projects we see a lot of similarities.

## 1.1 The ML Life Cycle

While every ML project differs, the steps in which ML models are developed and deployed are largely similar. Compared to software projects where stability is often prioritized, ML projects tend to be more iterative in nature. We have yet to encounter an ML project where the first deployment was the end of it.

### 1.1.1 Experimentation Phase

Most ML projects are a series of continuous experiments involving a lot of trial and error as it often requires repeated experimentation because finding the right approach depends on understanding complex data and adjusting models to effectively tackle real-world challenges. Figure 1.1 illustrates a typical workflow during this experimental part of the ML life cycle. While the arrows here are pointing in a single direction, there's a lot of iteration going on in almost every step. For example, say you're in between the model training and model evaluation step. If the model evaluation metrics are not up to par, you might consider another model architecture, or even go back further and check that you have sufficient high quality data.

![Figure 1.1 The experimentation phase of the ML life cycle](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/01__image001.png)

Note that each of these steps can be quite involved. This is why each of these steps are assembled into an orchestrated pipeline (You'll learn how to do this in the upcoming chapters). Having an orchestrated pipeline builds in automation from the get-go, which frees you from making potential mistakes that might be hard to track. When we get to the Dev/Staging/Production phase in Section 1.2, we will then fully automate the entire pipeline.

#### Problem Formulation

The very first question you should ask in any potential Machine Learning project is whether you should be using Machine Learning at all. Sometimes simple heuristics work, and as tempting as it is, suppress the urge to reach for that proverbial ML sledgehammer. On the other hand, while simple heuristics can offer efficient solutions, ML becomes necessary when dealing with complex, high-dimensional data where patterns are intricate and non-linear, demanding a more sophisticated approach for accurate analysis and prediction.

Therefore, if after thinking long and hard, the team (comprised of business/product and technical folks) decides that a Machine Learning model is the way to go, then the very first step would be to identify what problem the ML model is going to solve. For example, an Optical Character Recognition (OCR) model extracts identification numbers from identity cards. For Fraud Detection, it's being able to pick up fraudulent transactions in a timely manner while minimizing false positives.

#### Data Collection & Preparation

Then, you'll need to figure out where the data is going to come from because you'll need this for training and evaluating the model. In the case of OCR, you'll need images of valid identity cards. You might even consider generating synthetic data if real ones are difficult to come by. Once you have amassed enough training data (and this depends on several factors such as problem domain, what the model was fine-tuned on, etc), you need to label them with annotations.

In our OCR example, this means getting annotators to draw a bounding box around the parts where you care about, i.e. the identification number, and then inputting the identification numbers by hand. If all this sounds laborious, it is! For Fraud Detection, this could mean labeling transactions as fraudulent when customers complain, but also getting a domain expert to comb through the current dataset, or even possibly developing synthetic data with the help of that domain expert.

Once the labeled data is read, they'll need to be organized into training, validation, and test datasets.

#### Data Versioning

ML projects consist of both data and code. Changing code changes the behavior of the software. In ML, changing the data also does the same thing. Data versioning enables reproducibility. You want to be 100% sure that your model performs as expected given the same data and code.

Code is straightforward to version. Versioning data, on the other hand, is a different beast altogether. Data comes in different forms (images, CSV files, Pandas DataFrames, etc) and the ML community has not settled on a tool that has the same ubiquity as Git.

#### Model Training

Model training is the process of feeding the machine learning model lots of data, and as the model is trained, the model parameters (or weights) get tuned in order to minimize the error between what was predicted by the model and the actual value.

Once an engineer has defined the dataset and strategy for training, model training can be automated. Having automation from the get-go means that Data Scientists can easily spin up multiple experiments at one go, and ensure that experiments are reproducible because parameters, and artifacts (trained model, data, etc) are tracked.

People new to ML would often think this takes up most of the time. In our experience, the reverse is true.

The focus of this book isn't going to be model training, though we'll definitely train some interesting models as we progress along the project.

#### Model Evaluation

As the model trains, as a sanity check, you'll want to evaluate the performance of your model against a dataset that's not part of the training set. This gives a reasonable measure of how your model might do against unseen data (with caveats!). There's a wide variety of metrics that can be used like precision, recall, AUC, etc.

#### Model Validation

If your model passes evaluation, the next step is to ensure the model performs as expected. Oftentimes, this means that validation is performed by people other than the ones who built the model.

### 1.1.2 Dev/Staging/Production Phase

The distinction between the Experiment Phase and the Production Phase is critical as it marks the shift from exploring and refining models to deploying them in real-world settings. Understanding this transition is crucial because while experimentation might never be truly over, the focus shifts from pure exploration to maintaining and continuously improving the model's performance in the production environment, where considerations such as scalability, robustness, and real-time performance become paramount.

Recognizing this shift helps in splitting responsibilities and resources needed for both phases, ensuring the smooth deployment and maintenance of ML models.

Once you're at this stage, you'd have a working model. However, there is still a lot of work to do! For starters, we have not yet deployed the model. But before we get ahead of ourselves, Figure 1.2 shows what this stage would look like:

![Figure 1.2 The dev/staging/production phase of the ML life cycle](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/01__image003.png)

At first glance, this looks quite similar to Figure 1.1. Pieces like Data Versioning, Model Training, Model Evaluation, and Model Validation feature in both figures. During the experimentation phase, you would have an orchestrated pipeline that is more or less automated. In this phase, you'll want to make it completely automated.

A trigger can come from continuous integration (CI), or some form of programmatic invocation. This then kickstarts the pipeline steps in succession. What's new here is that at the end is Model Deployment. The result from this step is a deployed ML Service usually in the format of a REST API. Oftentimes, you also want to set up some sort of performance monitoring. In more sophisticated use cases, if performance metrics fall below a certain threshold, the trigger fires off again and the entire process repeats.

#### Model Deployment

Once you have a trained model that performs reasonably well, the next logical step is to deploy it so that customers can start using it. At some organizations, this is where hand-off to "IT" or "DevOps"/"MLOps" happen. However, we've seen a lot of benefits in getting the Data Scientists involved too.

One of the simplest ways of model deployment is slapping on a REST API that performs model inference. The next step would then be containerization with something like Docker, then deploying it on a cloud platform like AWS or GCP. However, deployment doesn't mean the job is done. You'll need to perform load testing to ensure the service can handle the expected load. You might also need to think about auto-scaling should your service encounter spiky loads. Each model deployment needs to be versioned too, and you'll need strategies for rolling back in case things go wrong.

#### Model Monitoring

ML models often don't survive first contact. Usually when your model hits production and encounters live data, it will not perform as well as during model evaluation. Therefore, you'll need to have mechanisms to measure the performance of your model once it hits production. There are two major classes of things that should be monitored. There are performance metrics that measure things like requests per second (RPS), counting HTTP status codes, etc. For ML projects, it is also important to measure things like data and model drift, because they can adversely affect model performance if left unchecked.

#### Model Retraining

Even the most robust models might need model retraining from time to time. How do you know when a model should be retrained? As with so many complex questions, it depends.

However, when models need to be retrained, they should be as automated as possible. If you have automated pipelines during model training, you're already off to a great start. However, that's not all. You'll also want to automate model deployment too so that once a new model gets trained, it can also be automatically deployed. Model retraining can either be triggered via a fixed schedule (like every month), or it could be triggered whenever some thresholds are met (like the number of approvals for a loan has suddenly decreased sharply).

## 1.2 Skills Needed for MLOps

The primary domains of MLOps include Software Engineering, Data Science, and DevOps, focusing on data management, model training, model deployment, and model monitoring. In industry, experience in all of these domains is valuable, and building a team with expertise that crosses those domains leads to success.

![Figure 1.3 MLOps is a mix of different skill sets](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/01__image005.png)

In this book, we will walk you through real examples that will demonstrate successful applications of each domain. Here's what you'll need to know coming in:

At the very core, she must be a decent software engineer who has successfully deployed a wide range of non-trivial software systems. This could range anything from mobile applications all the way to enterprise systems. She must be adept at debugging (as things will most definitely go wrong!) and know where to identify performance gaps and fix them.

The next prerequisite is the understanding of Machine Learning and Data Science. While this is organization-specific, the Machine Learning Engineer doesn't need to be an expert in Machine Learning algorithms nor know things like the nitty-gritty details of back-propagation. However, she must be comfortable working with common ML frameworks like Tensorflow/PyTorch/Scikit-Learn and be unfazed in picking up new and unfamiliar ones.

Knowing how to build Machine Learning models is one thing, understanding the Machine Learning life-cycle and appreciating its complexities and challenges are another. Most Machine Learning practitioners would agree that data-related challenges are often the trickiest, getting adequate training data of decent quality being the most notable. This requires a certain measure of Data Engineering skills.

A large part of MLOps is automation. Automation reduces mistakes and enables quicker iteration, and therefore faster feedback. Automation is also crucial in MLOps because experiment reproducibility becomes very important because you'd want your model to perform the same across dev/staging/production environments, but it becomes critical when your ML model is subjected to regulatory compliance and auditing. Ultimately, reproducible results lead to trust.

There are a lot more skills that MLEs are expected to know or pick up, but this is a good start.

### 1.2.1 Prerequisites

If all you've read so far sounds daunting, we certainly empathize. This is exactly why we've written this book! Much like the famous quote about eating an elephant, the best way to handle complexity is to tackle a little piece at a time. The problems that you encounter can often be broken down into manageable pieces. In other words, this range of skills is not needed all at once, nor do you need to know everything.

In order to prepare you for the upcoming chapters, we'll take a whirlwind tour of MLOps tools, but more importantly, we'll take you through the bare basics of Kubernetes. If you are already familiar with Kubernetes, then feel free to skim or skip it altogether. We think that this is valuable to say Data Scientists who want to get started quickly without being bogged down by unnecessary detail. These skills will equip you to set up your own ML platform, which will then enable you to build ML systems on top of it.

## 1.3 Building a Machine Learning Platform

The purpose of the ML Platform is to enable ML practitioners to develop and deploy Machine Learning services. This means that it has tools to handle all the essential parts of the Machine Learning life cycle. More often than not, an ML Platform is not a single piece of software. Instead, it's a kitchen sink of loosely related software. What we've seen is that as teams mature and use cases get increasingly complex, different tools will get adopted that will need to be integrated into the Machine Learning Platform.

![Figure 1.4 An example of a Machine Learning Platform architecture denoted by the dotted lines.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/01__image007.png)

Figure 1.4 presents an example of an ML Platform architecture. Outside of the dotted line boundary lies where most of your other data systems sit. They could be the data warehouse/lake, batch/streaming processors, different data sources, and so on. These are not ML platform specific therefore we won't delve into too much detail, although we will cover a little about data processors like Spark and Flink because they are at the periphery of the ML platform.

*Within *the dotted lines is where the fun begins. In this book, you'll learn how to build a Machine Learning Platform from scratch. First, you will set up Kubeflow, an open-source ML platform on Kubernetes. One of the core components of Kubeflow is Kubeflow Pipelines, which provides the *pipeline orchestration* piece.

The next major piece is the *Feature Store*, which we briefly cover in Section 1.4.2 and will feature (pun intended!) heavily in the Movie Recommender project. Another major piece of the ML platform is the model registry, which we also cover in the same section.

Don't worry if this seems too overwhelming! We'll then walk you through installing Kubeflow, followed by introducing the various features of Kubeflow, starting with Jupyter Notebooks and then Kubeflow Pipelines. Next, you'll learn how to grow the ML Platform. This will be driven by use cases where Kubeflow falls short. For example, Kubeflow doesn't come with a *Feature Store*, an integral piece of software that stores curated features to train and serve machine learning features.

##### There is no one-size fit all ML Platform Architecture!

While we present an ML platform architecture, and even though we've been using this successfully in our respective organizations, there is no one-size fit all solution! The approach we're taking in this book is to grow your ML platform *incrementally*, and this is what we heartily recommend when you embark on your MLE journey especially if you're building it from scratch. Once you get experience putting an ML platform together by following through this book, you'll be in a much better position to build your own ML platform that would fit the needs of your team and your organization.

### 1.3.1 Build vs Buy

In your organization, you might have already settled on an ML platform from a vendor like SageMaker (if you're on Amazon Web Services) or VertexAI (if you're on Google Cloud), and wondering if you really need to go through the pain of setting up an ML Platform.

We think it's extremely valuable to go through setting up an ML Platform from scratch at least once, as you progress through the various chapters, grow the ML Platform by integrating it with various open-source libraries. We think that learning how to put together an ML platform and customize it to your own needs is an important skill to have and something that is not often covered anywhere else.

By the end of the exercise, you will gain a much deeper understanding of how the various tools in the ML platform work together, and also overcome limitations when you encounter them.

##### A Word About Tool Choices

Developers can be extremely opinionated when it comes to tool choices, and in the ML space, there is no lack of tools. You shouldn't treat any of the tools we recommend as gospel. We heartily encourage you to try any tool for a couple of days with a proof of concept to see if the tool is a good fit for the problem that you're trying to solve. Very often you'll come across a limitation that's a dealbreaker early on that you otherwise might not have encountered without prior experimentation.

On the other hand, these tool choices are open-source, enjoy good community support, and most importantly, have worked well for us in a production setting. Of course, there have been numerous occasions where we have had to make certain customization here and there, but that's just part of being an MLE.

### 1.3.2 Tools Used In This Book

It is not an exaggeration to say that the MLOps landscape is inundated with tools. We have stuck to what we think are the more stable choices and the ones which we have had the most success using. While your mileage may vary, we still think this serves as a good starting point. The following lists the major tools that you'll come across as you work through the project. We'll go into detail about each of them later on, but it's useful to get an overview of these.

#### ML Pipeline Automation

In order to implement the MLOps life cycle, you'll need tools for ML pipeline automation to glue all the stages together. For this book, we will use Kubeflow pipelines. In Kubeflow pipelines, each stage in the ML life cycle is represented by what is called a **pipeline component**. Each pipeline component could potentially take data from a previous component, and pass data along to downstream components once it completes its task.

![Figure 1.5 An automated pipeline being executed in Kubeflow.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/01__image009.png)

#### Feature Store

Feature Stores have come to be an indispensable part of ML platforms. One of the core benefits of having a feature store is for Data Scientists and Data Analysts alike to share features, thereby saving time having to recreate features. These features can be used both for model training and model serving. We will use Feature Stores for the second project where we deal with tabular data.

Feature Stores come into play in the Data Collection and Preparation phase. Figure 1.6 shows how Feature Stores take in data that has already been transformed, whether it's simple data operations all the way to complex data manipulations requiring multiple joins across multiple sources. This transformed data is then ingested by the Feature Store.

Under the hood, most Feature Stores contain a:

- Feature Server to serve features whether by REST or even gRPC
- Feature Registry to catalog all the features available
- FEature Storage as the persistence layer for features
**
**3
**

**

![Figure 1.6 Feature Stores take in transformed data (features) as input, and have facilities to store, catalog, and serve features.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/01__image011.png)

The Feature Store serves features in two modes: *Offline *mainly for model training/batch inference, and Online for real-time inference.

There is another big benefit of feature stores when you can serve features offline versus online, and that is to prevent *training-serving skew*. This phenomenon happens when there might be a discrepancy during the training phase versus what is seen during inference. How could this happen? One example could be a difference in the data transformations occurring during training compared to what is done during inference. This is a very easy thing to overlook and Feature Stores very neatly solves this pain point. We will explore Feature Stores more in the coming chapters where you'll learn to exploit them in your ML projects.

#### Model Registry

The outputs of a model training run include not only the trained model but also artifacts such as images of plots, metadata, hyperparameters used for training, and so on. In order to ensure reproducibility, each training run needs to capture all the things mentioned above.

One of the use cases that a model registry enables is to promote models from staging to production. You can even have it set up such that the ML service serves the ML model from the model registry. We will explore the ML registry in depth once we dive into the respective project chapters.

![Figure 1.7 The model registry captures metadata, parameters, artifacts, and the ML model and in turn exposes a model endpoint.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/01__image013.png)

#### Model Deployment

Model deployment is integrating it into a production environment (this could be your dev/staging environment too) where it can receive input and return an output. In essence, model deployment is making your model available for others to consume.

Model deployment is very much engineering-centric. You have to think about portability (usually solved with containerization), scalability (with Kubernetes, you can potentially scale the ML service with multiple replicas), performance (would the model benefit from GPUs/better CPUs and more RAM), and reliability. Ideally, you'll want to automate this as much as possible using CI/CD. For example, each time code changes, you'd want CI/CD to build and deploy a new ML model.

![Figure 1.8 Model deployment consists of the container registry, CI/CD, and automation working in concert to deploy ML services.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/01__image015.png)

The figure demonstrates how automated model deployment can be set up. A trigger to CI/CD would automatically build the Docker container for the ML service, and push it to the container registry. After that, the Kubernetes deployment manifests can be created that reference the Docker image that has just been built. Applying these manifests would then result in the updated ML service being deployed. Of course, we're leaving out quite a bit of detail here, but you'll see how all these fall into place once we get to the model deployment sections of the respective projects.

## 1.4 Building Machine Learning Systems

Now that you've laid a solid foundation with an ML Platform, it's now time for the good stuff - Solving actual business problems with ML Systems. Here, we present two flavors of ML projects we often encounter: One dealing with images and another dealing with tabular data.

It is highly like that either or none of the projects match the problems that you are handling in your organization, but we're willing to bet if you look past the superficial differences, you'll find a lot of commonalities that can be applied to your project, which is the entire point of introducing the projects. As you work through the projects, imagine that we are in a pair-programming setting or in a room thinking through system design.

We'll work through each of the essential parts of the ML life cycle and finish off with the more operational side of things, namely monitoring (both the data and model), and model explainability.

### 1.4.1 Introducing the ML Projects

One of the core aims of this book is to provide you with as close to a real-life experience in building ML systems from start to finish. To that end, we'll present you with two projects. In them, we'll take you through the full ML life cycle, from data preparation to monitoring and finally model retirement. The projects aim to give you a breadth of experience across common ML flavors and while we may not cover every kind of ML project, we believe that the projects we've selected are a good representation of ML problems in the real world.

Certain tools we will reuse (such as Kubeflow pipelines), while in other instances, we'll consider the challenges and shortcomings of the previously introduced tool, and offer an alternative. Each project will follow the ML project life-cycle and progressively introduce the different tools as our use cases grow. The projects are also designed to reinforce the following observations

- ML projects are seldom linear and instead highly iterative. Sometimes, you'll have to revisit previous steps, reconsider assumptions and rethink models. For example, when a model doesn't do as well as expected during training, it might be that you have to revisit the data preparation step. We'll try to bake in scenarios like that too, so you'll get to experience for yourself which parts need to be tweaked and how to do it.
- Project requirements change over time as the project naturally evolves. This usually means reconsidering the current solution and being creative in exploring other tools and techniques.
- The core MLOps concepts are vital in almost any type, domain or stage of a large scale ML project. Depending on the context, some steps may be skipped or combined with others, but thinking along the lines of these core concepts helps provide structure to large ML projects and in our experience provides a good engineering framework.

These projects are inspired by some of the ones we've encountered at our work, albeit a slightly stripped-down version. However, the steps and the thought process are almost identical, and we're confident that you'd be able to apply them to your projects too.

#### Project 1: Building an OCR System

OCR is a very common use case for ML systems. In this project, we'll start with the problem statement of detecting identification cards. We'll figure out how to build out a dataset and then train an image detector that can detect identification cards. Next, we'll use an open-source library to build out an initial implementation, then fine-tune it with a labeled dataset. Finally, we'll deploy it as a service.

#### Project 2: Movie recommender

The second project will be a movie recommendation service. While the steps and core ideas remain the same as the OCR example, tabular data has some interesting nuances and tooling requirements. Tabular data also makes it easier to illustrate some concepts like feature stores, drift detection, model testing, and observability. Tabular data also has the advantage of being already in a numerical ( or can be easily converted to a numerical feature ) format.

Before we dive into building the ML platform and building/deploying these projects on it, let us learn more about core MLOps concepts in the next chapter.

## 1.5 Summary

- The Machine Learning (ML) life cycle is an iterative process that involves several steps in developing and deploying ML models.
- The first step is to identify the problem the ML model is going to solve, followed by collecting and preparing the data to train and evaluate the model. Data versioning enables reproducibility, and model training is automated using a pipeline.
- Once the model is trained, it is evaluated for performance against a dataset that was not part of the training set. After model training, the next logical step is to deploy the model so that customers can use it.
- Model monitoring and retraining are critical steps to maintain the model's performance and detect data and model drifts that can negatively affect performance.
- The ML life cycle is an iterative process that may require re-evaluating the problem and data collection and preparation steps.
- MLOps and ML Engineering draw from several skills ranging from software engineering, DevOps, Data Science, and Data Engineering
- We're going to use Kubeflow Pipelines for ML pipeline automation and introduce the model registry (MLFlow) and feature store (Feast) as we progress through the projects
- We'll tackle two different kinds of ML systems: OCR and Movie recommender. We will use this ML life cycle as a framework as we build out both of these projects.
