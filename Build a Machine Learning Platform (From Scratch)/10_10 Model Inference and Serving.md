# 10 Model Inference and Serving

### This chapter covers

- Introducing BentoML for Model Serving
- Building model servers with BentoML
- Observability and Monitoring in BentoML
- Packaging and Deploying BentoML Services
- Using BentoML and MLFlow together
- Using only MLFLow for model lifecycles
- Alternatives to BentoML and MLFlow

Now that we have a working model training and validation pipeline, it's time to make the model available as a service. In this chapter, we will explore how to seamlessly serve your object detection model and movie recommendation model using BentoML, a powerful framework designed to build and serve machine learning models at scale.

You'll have the opportunity to deploy the two models you trained in the previous chapter, gaining hands-on experience with real-world deployment scenarios. We'll start by building and deploying the service locally, then progress to creating a container that encapsulates a service for deployment, integrating it seamlessly into your ML workflow.

Self-service model deployment offers several advantages for engineers developing MLOps:

1. Early Validation: Gain confidence upfront that your model is deployable, allowing for quick identification and resolution of potential issues.
1. Resource Optimization: Experiment with more powerful hardware on Kubernetes clusters, potentially surpassing the limitations of local development environments. In other cases, the final deployment could include steps to test and optimize for resource constrained environments and hardware setups like embedded devices.
1. Reduced Bottlenecks: Eliminate waiting times associated with relying on Machine Learning Engineers (MLEs) for model deployment, accelerating the iterative development process.
1. Reducing errors: Manual deployments are prone to error and is often not repeatable.
1. Enhanced Collaboration: Bridge the gap between development and operations, fostering better communication between Data Scientists and MLEs.

It's important to note that while self-service deployment empowers model developers, it does not eliminate the need for model deployment engineers in production environments. Instead, it enables Data Scientists to deploy models to non-production environments, facilitating thorough testing and validation before handoff to MLEs for production deployment.

By the end of this chapter, you'll have a solid understanding of how to leverage BentoML for model serving, enabling you to quickly transition from model development to deployment. This knowledge will not only enhance your workflow but also improve collaboration with MLEs and other stakeholders in your ML projects.

## 10.1 Model Deployment is Hard

Traditional software deployment is already a complex process, involving numerous elements such as version control, various testing methodologies (unit, integration, performance, etc.), continuous integration, and continuous deployment. However, when we introduce machine learning model deployment into this mix, we encounter an additional complexity unique to machine learning that demands careful consideration:

1. Inference Patterns: Understanding how the served model will be consumed is crucial. Will it be used for batch predictions, real-time inference, or both?
1. ModelScalability: ML models often need to handle varying workloads, requiring robust scaling solutions.
1. Performance Monitoring and Logging: Implementing comprehensive monitoring and logging for ML models is essential for tracking performance, detecting drift, and debugging issues.
1. Continuous Learning: Establishing pipelines for retraining models and automatically deploying improved versions is a key challenge in ML systems.
1. Data Dependencies: ML models often rely on specific data formats or preprocessing steps, which need to be replicated in the serving environment.
1. Hardware Requirements: Some models may require specialized hardware (e.g., GPUs) for efficient inference, adding complexity to deployment infrastructure.
1. Model Versioning: Managing multiple versions of models, including rollback capabilities, is crucial for maintaining system reliability.
1. Explainability and Interpretability: Deploying models in production often requires mechanisms to explain model decisions, especially in regulated industries.
1. Resource Management: Balancing computational resources between model serving and other application components can be challenging.
1. Security and Privacy: Ensuring that deployed models don't leak sensitive information and are protected against adversarial attacks is critical.

While software engineering principles provide a foundation for addressing these challenges, machine learning introduces unique considerations that require specialized knowledge and tools. The intersection of software engineering and data science in ML deployment necessitates collaboration between Data Scientists and Machine Learning Engineers to create robust, scalable, and maintainable ML systems.

## 10.2 BentoML: Simplifying Model Deployment

BentoML is a powerful framework designed to bridge the gap between model development and deployment, addressing many of the complexities we've discussed. Here's how BentoML helps tackle these challenges:

1. Unified Model Serving: BentoML provides a standardized way to package and serve models regardless of the framework used (e.g., PyTorch, TensorFlow, scikit-learn), simplifying the transition from development to deployment.
1. Flexible Inference Patterns: It supports both real-time API serving and batch inference out of the box, accommodating various use cases.
1. Scalability: BentoML integrates seamlessly with container orchestration platforms like Kubernetes, enabling easy scaling of model serving workloads.
1. Built-in Monitoring and Logging: The framework includes monitoring and logging capabilities, making it easier to track model performance and debug issues in production.
1. Model Management: BentoML offers version control for models, allowing you to manage multiple model versions and facilitate easy rollbacks if needed.
1. Reproducible Builds: By packaging the model, its dependencies, and the serving logic together, BentoML ensures consistency between development and production environments.
1. Adaptive Micro-batching: BentoML can automatically batch incoming requests for improved throughput, optimizing resource utilization.
1. API Layer Abstraction: It provides a high-level API for defining model serving logic, reducing the boilerplate code needed for deployment.
1. Resource Optimization: The framework allows fine-grained control over resource allocation, helping to balance between performance and cost.
1. Ecosystem Integration: BentoML integrates with popular MLOps tools and platforms, fitting seamlessly into existing ML workflows.

By leveraging BentoML, data scientists and ML engineers can focus more on model development and less on the intricacies of deployment infrastructure. It provides a streamlined path from experimentation to production.

In the following sections, we'll dive deeper into how to use BentoML to package and serve your models and demonstrate its practical benefits in simplifying the deployment process.

## 10.3 A Whirlwind Tour of BentoML

In Chapter 5, we've touched a bit about installing BentoML and Yatai.

This section we will take the YOLOv8 model trained in the previous chapter, and deploy it as a machine learning service using the BentoML Service.

First and foremost, install BentoML. As for this time of writing, the latest version is 1.1.6:

```
pip install bentoml==1.1.6
```

Check that BentoML has been installed correctly:

```
% bentoml -v
bentoml, version 1.1.6
```

If you are following along with the project, then everything is in the `serving` directory. Otherwise, feel free to create an empty project of your own.

### 10.3.1 BentoML Service and Runners

Before we dive into the code, it is important to understand a little about how a BentoML service is put together, and what the main components are. Figure 10.1 gives a high level overview of how an inference request is handled in BentoML.

![Figure 10.1 BentoML Service architecture showing API Server distributing requests to multiple Runners.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/10__image001.png)

A BentoML service is an abstraction that wraps one or more API servers, and one or more *type*s of Runners, where more than one runner can exist at a time. The API Server is an HTTP Server that listens for incoming requests on a specified port. Notice that we can implement multiple API servers. This offers a few advantages:

- Horizontal Scaling: Depending on the resources available, we can add multiple instances of the API server so that the BentoML service can handle an increased load and concurrent requests. This is especially important when the demand for inference might vary over time.
- Load balancing: Having multiple API instances mean that incoming requests can be distributed among instances, preventing any one instance from being the bottleneck.
- Parallel Processing: Since multiple API servers can handle requests in parallel, this can lead to improved throughput.

The API server performs some input parsing and validation (we'll go into details later on). Once that's done, the input arguments are handed to the *Runner*.

A Runner is a computational unit that wraps a machine learning model. The Runner is the one that performs the actual inference based on the input data passed in by the API server.

This model is very neat because it allows BentoML to support various execution environments, whether it's running a BentoML Sevice locally, on Kubernetes, or on clouds. Each Runner runs in its own Python worker, and BentoML exploits this so that multiple instances of Runners can execute in parallel. There are more interesting capabilities that Runners enable, but this is good enough for now.

Now that we've gotten the nomenclature out of the way, let's go straight into the code. We want to build a BentoML service that has multiple API servers along with multiple Yolo V8 runners, as illustrated by Figure 10.2:

![Figure 10.2 BentoML Service architecture with multiple API Servers and Runners.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/10__image002.png)

The API server will expose two endpoints:

- `/inference`: This takes an input image, and outputs the results in JSON format. For example:

```
[
  {
    "name": "id_card",
    "class": 0,
    "confidence": 0.5838027000427246,
    "box": {
      "x1": 1.8923637866973877,
      "y1": 146.94198608398438,
      "x2": 243.37542724609375,
      "y2": 338.2261657714844
    }
  }
]
```

- `/render`: This takes an input image, and outputs the image that contains the bounding box, label, and probability. Figure 10.3 provides an example:

![Figure 10.3 Sample output of YoloV8 object detection on a driver's license image.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/10__image003.png)

These two endpoints provide flexibility in how users can interact with your object detection model. The `/inference` endpoint is ideal for programmatic access and integration with other systems, while the `/render` endpoint offers a visual representation of the model's output, which can be useful for debugging, demonstrations, or quick visual checks.

By structuring your BentoML service with these endpoints, you're creating a versatile and user-friendly interface for your object detection model. This approach allows for both machine-to-machine communication through the JSON output and human-friendly visual output, catering to different use cases and user needs.

In the next section, we'll walk through the process of implementing this service and running it on your local machine. This hands-on experience will help solidify your understanding of BentoML's components and give you a practical foundation for deploying more complex services in the future.

## 10.4 Executing a BentoML Service Locally

Now it's time to roll up our sleeves and get hands-on with BentoML. We will guide you through the process of creating a BentoML service and running it locally. You will learn how to package your object detection model and expose it as a REST API for local testing and development.

When building a BentoML service, we start with the Runner.

### 10.4.1 Loading a Model with BentoML Runner

Create a `service.py` file that will contain both the service and runner implementation. Create the `YOLOv8Runnable` class that inherits from `bentoml.Runnable`:

```
import bentoml
from ultralytics import YOLO
class YOLOv8Runnable(bentoml.Runnable):
   def __init__(self):
       self.model = YOLO("yolov8_custom.pt")
```

The YOLO model is initialized within the constructor and assigned to the model attribute. To keep things simple, the `yolov8_custom.pt`model weights are from the previous chapter, and should be placed in the same directory as `service.py`.

##### Initializing models in BentoML Runners

The method we've demonstrated here - initializing the model directly in the Runner's constructor - is just one of several ways to load models in BentoML. While it's straightforward and suitable for many use cases, you might be wondering about more dynamic approaches, such as fetching models on-demand or switching between different versions.

These are excellent considerations, especially for production environments where flexibility and version control are crucial. BentoML offers more advanced model management capabilities through its Model Registry feature. This powerful concept allows for dynamic model loading, versioning, and seamless updates.

However, to keep our current focus on the basics of setting up a BentoML service, we'll explore the Model Registry in depth in a subsequent section.

For now, let's continue with our simple setup, which is perfect for understanding the core concepts and getting a working service up and running quickly. As we progress, keep in mind that there are more sophisticated ways to manage your models, and we'll build upon this knowledge to explore those methods later.

Let's implement the first method, `invocation`:

```
import bentoml
import json
from ultralytics import YOLO
 
class YOLOv8Runnable(bentoml.Runnable):
 
   def __init__(self):
       self.model = YOLO("yolov8_custom.pt")
 
   @bentoml.Runnable.method(batchable=False)     #A
   def inference(self, input_img):               #B
       results = self.model(input_img)[0]        #C
       return json.loads(results[0].tojson())    #D
```

The first thing to notice here is the `bentoml.Runnable.method`decorator. This creates a RunnableMethod that allows the method to be executed remotely. This means that the method can be invoked remotely, from a client or another service, and its execution is handled by the BentoML service. Here, the inference method takes in a single image, then passes it to the model.

Invoking the model function with the image performs the inference. By default, it returns a list, given that it is possible to pass multiple images to the method. However, we're only interested in sending in one image, therefore we return only the first entry. Finally, the results are turned into a JSON *string*. This means that you will need the `json.loads` method to turn the result in JSON.

The `bentoml.Runner` method is used to create a Runner instance using the previously defined `YOLOv8Runnable`class as input. It is advisable to provide a name here since the default naming by BentoML (lowercased classname) may not be easily recognizable when the runner is executed.

```
import bentoml
 
yolo_v8_runner = bentoml.Runner(YOLOv8Runnable, name="yolov8_runnable")        #A
svc = bentoml.Service("yolo_v8", runners=[yolo_v8_runner])                     #B
```

Once the runnable is created, it's time to initialize the BentoML service using `bentoml.Service`, and passing a list of runners, which in our case, is only `yolo_v8_runner.`As you can probably imagine, we can pass in multiple runners to the service that enable multistage workflows that we will dive into a bit later.

Before we get too ahead of ourselves, let's take a look at putting together the BentoML service before learning how to use multiple runners. Since we've created the service instance, here's how to create an endpoint:

```
from bentoml.io import Image                                    #A
from bentoml.io import JSON                                     #A
 
@svc.api(input=Image(), output=JSON())                          #A
async def invocation(input_img):                                #B
   return await yolo_v8_runner.inference.async_run([input_img]) #C
```

The `@svc.api(input=Image(), output=JSON())` decorator is used to define the API endpoint. It specifies that the API takes an image (`Image()`), and the output is expected in JSON format (`JSON()`).

`async def invocation(input_img)` defines an asynchronous function named `invocation`. Note the `async`keyword here. This function will be the actual implementation of the API endpoint. It takes an `input_img` parameter representing the input image.

The most interesting line is:

```
await yolo_v8_runner.inference.async_run([input_img])
```

You're passing it a list containing the input image (`input_img`) into the `async_run` method. This method starts the object detection process on the image in the background. The `await` keyword ensures your code waits until the prediction finishes before proceeding.

#### Why is the `await` keyword needed?

The `await` keyword is crucial when working with asynchronous functions in Python. Here's why:

- Asynchronous Execution: The `async_run` method initiates the object detection process asynchronously, allowing it to run in the background without blocking the main execution flow.
- Handling Promises: `async_run` returns a promise of a future result, not the result itself. The `await` keyword is used to wait for this promise to resolve.
- Preventing Errors: Without `await`, the code would continue execution immediately, potentially trying to use results that aren't yet available, leading to errors.
- Maintaining Responsiveness: In a web application context, using `await` allows the server to handle other requests while waiting for the current operation to complete.

Let's illustrate this with a real-world example:

Imagine you're building a web application for real-time object detection in images:

1. User uploads an image
1. Your code calls yolo_v8_runner.inference.async_run([input_img])

**Scenario 1: Using ****await**

The following code pauses at `await`, allowing the server to handle other requests. Once the detection is complete, execution resumes, and the result is processed.

```
async def process_image(input_img): 
  result = await yolo_v8_runner.inference.async_run([input_img])   
  return process_result(result)
```

**Scenario 2: Without await  **

On the other hand, without `await`, the code continues immediately without waiting for the detection to complete. `process_result(result)` will likely fail because `result` is a promise that the detection output will be returned later, not the actual detection output.

```
def process_image(input_img):
    result = yolo_v8_runner.inference.async_run([input_img])
    return process_result(result)
```

By using `await`, you ensure that your code waits for the asynchronous operation to complete before proceeding, preventing errors and maintaining a responsive application.

#### Multiple BentoML Runners

When would you use multiple BentoML runners? Imagine you have a service that requires some pre-processing of the image before you perform the inference, like converting it to grayscale, before sending it to the object detector. Then, the service might look like:

```
svc = bentoml.Service("object_detector", runners=[grayscale_converter, object_detector])
```

Another use case would be, say for example, that you want to test two versions of the object detector model at the same time by passing in the references for `object_detector_1` and `object_detector_2` into the runners argument:

```
svc = bentoml.Service("object_detectors", 
                      runners=[grayscale_converter, object_detector_1, object_detector_2])
```

How would you use this in a service? Here's an example of how this could work.

```
@svc.api(input=Image(), output=JSON())
async def predict(input_image: PIL.Image.Image) -> str:
    model_input = await grayscale_converter.async_run(input_image)
 
    results = await asyncio.gather(
        object_detector_1.async_run(model_input),
        object_detector_2.async_run(model_input),
    )
 
    return {"results": { "model_a": results[0], "model_b": results[1]
```

This code demonstrates how to create a BentoML service that uses multiple models for object detection. Here's an explanation of what the code is doing:

1. Service Definition: The `@svc.api` decorator defines an API endpoint for the service. It specifies that the input is an image and the output is JSON.
1. Asynchronous Processing: The `predict` function is defined as asynchronous (`async def`), allowing for non-blocking operations.
1. Input Preprocessing: `grayscale_converter.async_run(input_image)` converts the input image to grayscale asynchronously. This preprocessed image is then used as input for both object detectors.
1. Parallel Model Inference: `asyncio.gather()` is used to run both object detectors (`object_detector_1` and `object_detector_2`) concurrently on the grayscale image. This parallel processing can improve overall performance.
1. Result Aggregation: The results from both models are collected and structured into a dictionary. Each model's output is assigned to a key ("`model_a`" and "model_b").
1. JSON Response: The function returns a JSON-serializable dictionary containing the results from both models.

This approach allows for efficient, parallel processing of a single input through multiple models, providing a comprehensive object detection result in a single API call. It showcases BentoML's capability to handle complex, multi-model workflows in a scalable manner.

#### Implementing the /render endpoint

It is also very useful to have the labels and bounding boxes drawn for us. Let's implement the other endpoint that will allow us to download the result of the image directly. We'll call this endpoint `render`.

```
class YOLOv8Runnable(bentoml.Runnable):
 
   def __init__(self):
       # same as before
 
@bentoml.Runnable.method(batchable=False)
def render(self, input_img):
   result = self.model(input_img, save=True, project=os.getcwd()) 
   return PIL.Image.open(os.path.join(result[0].save_dir, result[0].path))
```

If you pass in save=True, the library saves the result of the inference to a local folder:

```
result = self.model(input_img, save=True, project=os.getcwd())
```

`result` contains the output path of the image containing the drawn bounding boxes and classes, along with other interesting metadata (useful if you want to use the other modes such as segmentation masking):

```
[ultralytics.engine.results.Results object with attributes:
 
boxes: ultralytics.engine.results.Boxes object
keypoints: None
masks: None
names: {0: 'id_card'}
orig_img: array([[[14, 44, 79],
        [17, 44, 79],
        [18, 44, 79],
        ...,
        [45, 59, 72],
        [44, 58, 67],
        [44, 56, 66]]], dtype=uint8)
orig_shape: (461, 258)
path: 'image0.jpg' # this image has the overlays…
probs: None
save_dir: '/opt/homebrew/runs/detect/predict15'
speed: {'preprocess': 2.254009246826172, 'inference': 20.57194709777832, 'postprocess': 4.968881607055664}]
```

We then use save_dir and path to construct the path to return the resulting image:

```
return PIL.Image.open(os.path.join(result[0].save_dir, result[0].path))
```

Serve the model again (bentoml serve service.py), head over to `http://0.0.0.0:3000`, and under the `/render` entry, upload a test image. If everything went OK, you'll see that a *Download File* link appearing in the 200 server response, as seen in Figure 10.4:

![Figure 10.4 Interface showing successful image inference via the /render endpoint.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/10__image004.png)

Click on the link and you'll see the result of your hard work, something like Figure 10.5, with the ID card surrounded by the bounding box, with the class (id_card) and probability (0.58):

![Figure 10.5 Sample output of YoloV8 object detection on a driver's license image.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/10__image005.png)

Excellent! You have successfully implemented the `/render`endpoint, which allows users to directly download the result of the image with the labels and bounding boxes drawn. This is a very useful feature that enhances the user experience and makes it easier to visualize the model's predictions.

By leveraging the `save=True` parameter, you were able to save the result of the inference to a local folder. You then used the `save_dir` and `path` attributes from the result object to construct the path and return the resulting image using `PIL.Image.open()`.

With the `/render` endpoint in place, users can now easily upload a test image through the BentoML API server and receive a downloadable link to the processed image with the bounding boxes and labels clearly visible.

Now, let's take your service to the next level by exploring the concept of observability endpoints. Observability is crucial for monitoring and understanding the behavior and performance of your deployed model. In the next section, we will dive into how you can add observability endpoints to your BentoML service, enabling you to gain valuable insights and ensure the robustness of your object detection system.

#### Observability Endpoints: Ensuring Service Health and Reliability

When building non-trivial services for Kubernetes, implementing health checks and liveness/readiness probes is considered a best practice for ensuring observability and effective pod management. These endpoints play a crucial role in monitoring the health and status of your pods and identifying potential issues.

Health checks in Kubernetes are used to understand the overall health and status of a pod. They provide insights into whether the pod is functioning as expected and can handle incoming requests. Liveness probes, on the other hand, periodically call the `/healthz`endpoint to determine if the pod is alive and ready to run the main process. If the liveness probe fails, Kubernetes may restart the pod to resolve any issues.

Similarly, readiness probes periodically call the `/readyz` endpoint to assess whether the pod is ready to receive traffic. A pod is considered ready when it is both alive and operational, meaning it can handle incoming requests effectively. These observability endpoints not only help in monitoring the pod's health but also aid in troubleshooting. For instance, if your pod fails to initialize properly, the `/healthz` endpoint would indicate a failure, allowing you to investigate and resolve the issue promptly.

Now, you might be wondering how to implement these observability endpoints in your newly created BentoML service. The good news is that BentoML already takes care of this for you! Out of the box, BentoML provides built-in support for health checks and liveness/readiness probes, ensuring that your service is properly monitored and managed within a Kubernetes environment (Figure 10.6):

![Figure 10.6 BentoML's built-in observability endpoints for Kubernetes environments.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/10__image006.png)

Even better, it also comes with Prometheus metrics (Figure 10.7). As you might recall, Prometheus metrics are a standardized format for monitoring and measuring system performance, providing time-series data about various aspects of an application or infrastructure, which can be collected, stored, and analyzed by Prometheus, a popular open-source monitoring system.

![Figure 10.7 Sample Prometheus metrics output from a BentoML service.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/10__image007.png)

BentoML's built-in support for health checks and liveness/readiness probes is a very convenient and time-saving feature for developers building machine learning services. By providing these observability endpoints out of the box, BentoML eliminates the need for repetitive implementation and allows you to focus on what truly matters: the business logic and core functionality of your service. This reduces the chances of introducing errors and ensures that your service adheres to best practices for Kubernetes deployments.

The observability features in BentoML go beyond mere convenience. They promote reliability, scalability, and maintainability by enabling proper monitoring and management of your service within a Kubernetes environment. With these endpoints in place, you can have confidence that your service will be resilient and responsive to changes in demand or infrastructure.

## 10.5 Building Bentos: Packaging Your Service for Deployment

In BentoML, a deployment-ready package of your machine learning service is aptly called Bento. Bentos encapsulate all the necessary components, including the trained model, service code, and dependencies, making it easy to distribute and deploy your service across different environments. To create a Bento, you need to define a build configuration file called `bentofile.yaml`, which specifies the service file, included files, and the base Docker image to use for containerization:

```
service: "service.py:svc"
include:
 - "service.py"
 - "yolov8_custom.pt"
docker:
 base_image: "ultralytics/ultralytics:8.0.203-cpu"
```

Now in the terminal, run:

```
% bentoml build
```

If everything was successful, you will see:

![Figure 10.8 BentoML build success message and suggested next steps](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/10__image008.png)

##### Identifying Model versions

When you build a Bento using the bentoml build command, BentoML automatically generates a unique identifier for that specific version of your service. This identifier, known as the Bento Tag, follows the format service_name:version_label. For example, in the previous section, the Bento was tagged as "yolo_v8:3jghhcfxvwsrnbsb”. We will discuss these tags in more detail a bit later.

The image shows a successful build output, which includes:

1. A confirmation message:

```
"Successfully built Bento(tag="yolo_v8:3jghhcfxvwsrnbsb")"
```

1. Suggested next steps:

We don't need to push to BentoCloud, so it's safe to ignore for now. Let's follow the first suggested next step and containerize the Bento:

```
% bentoml containerize yolo_v8:3jghhcfxvwsrnbsb
```

What you'll see next is an output like:

```bash
[1] building 4 targets...
[+] Building 2.5s (15/15) FINISHED
 => [internal] load build definition from Dockerfile                                                                                                             
 => => transferring dockerfile: 655B                                                                                                                              
 => [internal] load .dockerignore                                                                                                                                 
 => => transferring context: 2B                                                                                                                                   
 => [internal] load metadata for docker.io/ultralytics/ultralytics:8.0.203-cpu                                                                                    
 => [1/9] FROM docker.io/ultralytics/ultralytics:8.0.203-cpu@sha256:172a0f3f0d2f9dda4a7234909d78df829127460b1a7f5fa6bfef4e02a15ff0b9                              
 => [internal] load build context                                                                                                                                 
 => => transferring context: 1.98kB                                                                                                                               
 => CACHED [2/9] WORKDIR /home/bentoml                                                                                                                            
 => CACHED [3/9] COPY ./src/bentoml_bundle_config.yml /home/bentoml/bentofile.yaml                                                                                
 => CACHED [4/9] COPY ./src/entrypoint.sh /home/bentoml/entrypoint.sh                                                                                             
 => CACHED [5/9] COPY ./src/containerize_utils.py /home/bentoml/containerize_utils.py                                                                             
 => CACHED [6/9] RUN pip3 install bentoml==1.1.6 --no-cache-dir                                                                                                   
 => CACHED [7/9] COPY ./src/ /home/bentoml/src                                                                                                                    
 => CACHED [8/9] RUN pip3 install -r /home/bentoml/src/requirements.txt --no-cache-dir                                                                            
 => CACHED [9/9] RUN bentoml build --build-ctx /home/bentoml/src                                                                                                  
 => exporting to image                                                                                                                                            
 => => exporting layers                                                                                                                                           
 => => writing image sha256:9345c3e5d58bcfb479bdc22c81c81afe18f379e74d304a8b1da5ee93e38b63d5                                                                      
 => => naming to docker.io/library/yolo_v8:3jghhcfxvwsrnbsb                                                                                                       
 
Use 'docker scan' to run Snyk tests against images to find vulnerabilities and learn how to fix them
Successfully built Bento(tag="yolo_v8:3jghhcfxvwsrnbsb") docker image.
```

Containerizing your Bento is a powerful way to ensure portability and consistency across different environments. By packaging your service along with its dependencies into a container image, you can easily deploy it to various platforms and infrastructures without worrying about compatibility issues. Containerization also enables scalability and efficient resource utilization, making it an ideal choice for production deployments.

#### Bento Tags: Versioning and Managing your Bentos

As you continue to develop and enhance your machine learning services, it becomes crucial to have a robust versioning and management system in place. BentoML provides a feature called Bento Tags that allows you to label and organize your Bentos effectively. Bento Tags help you keep track of different versions of your service, making it easier to manage and deploy the desired version in various environments.

Remember the `bentoml build` command before and how in the example the model was tagged as "`yolo_v8:3jghhcfxvwsrnbsb`" automatically? This is an example of the tags feature. You could supply the last argument without the tag, i.e. just `yolo_v8`instead of `yolo_v8:3jghhcfxvwsrnbsb`. However, just like how you would treat Docker tags, it is best practice to be always explicit.

Bento Tags serve multiple purposes:

1. Versioning: Track and manage different iterations of your model and service code.
1. Deployment: Ensure consistent deployment of the correct version across environments.
1. Reproducibility: Provide a unique identifier for each Bento, promoting reproducibility and debugging.

To test that the Bento has been successfully containerized, execute the command as suggested by the last line in the output:

```bash
% docker run --rm -p 3000:3000 yolo_v8:3jghhcfxvwsrnbsb
```

You'll get output like:

```
[2023-06-22 13:49:54 +0000] [1] [INFO] Starting gunicorn 20.1.0 [2023-06-22 13:49:54 +0000] [1] [INFO] Listening at: http://0.0.0.0:3000 (1) [2023-06-22 13:49:54 +0000] [1] [INFO] Using worker: sync [2023-06-22 13:49:54 +0000] [8] [INFO] Booting worker with pid: 8 [2023-06-22 13:49:54 +0000] [9] [INFO] Booting worker with pid: 9
```

If you were to access `http://0.0.0.0:3000` you will see the familiar API page:

![Figure 10.9 BentoML web interface showing the deployed YOLOv8 service endpoints and documentation.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/10__image009.png)

Try out the APIs to be sure that everything is working as it should be. Test the `/invocation` and `/render` endpoints with sample images and verify that the results are accurate and consistent with your expectations. If the APIs are functioning correctly, you can be confident that your Bento has been successfully containerized and is ready for deployment.

Containerizing your Bento with BentoML provides a convenient and efficient way to package and distribute your machine learning service. By encapsulating your service and its dependencies into a container image, you can ensure consistency and portability across different environments. Docker's widespread adoption and extensive ecosystem make it an ideal choice for containerization, enabling you to deploy your Bento seamlessly on various platforms and infrastructures.

With the successful containerization of your YOLOv8 Bento, you have achieved a significant milestone in the deployment process. BentoML's intuitive APIs and streamlined workflow have made it easier to build, package, and deploy your machine learning service. However, it's worth noting that BentoML is not the only option available for serving and deploying machine learning models.

### 10.5.1 BentoML and MLFlow inference

So far we have used BentoML to deploy local models and develop inference services for them. We can extend these capabilities of BentoML by combining the MLFLow model registry features we built in the previous chapter.

![Figure 10.10 Logical flow of using MLFlow and BentoML together](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/10__image010.png)

Although BentoML and MLFlow can be used separately to deploy models, the combination is often a better user experience for development and testing. As we discussed earlier, model development is iterative and therefore easing the process of deployment and inference is key in making the process simple. MLFlow offers powerful tracking and experimentation features that are usually more important for the data scientists and model developers while BentoML offers an easier deployment and monitoring experience that eases the operational overheads on the deployment and operations engineers.

Since we already talked about a pure BentoML experience with the YoloV8 model earlier in this chapter, we will extend this with models registered in MLFlow for the recommender project.

As a quick refresher, in the previous chapter, we trained a model and registered it in MLFLow’s experiment tracking system. A model was then evaluated together with other models and the best performing one was tagged as production.

To begin with, let's create a simple inference service like we did for object detection, but instead of using a local image, let's pull from MLflow instead.

##### Listing 10.1 Using MLFLow and BentoML in an inference service

```
import bentoml
import mlflow
import torch
import numpy as np
from mlflow import MlflowClient
 
@bentoml.service(
    resources={"cpu": "2"},
    traffic={"timeout": 10},
)
class RecommenderRunnable:
    def __init__(self, registered_model_name='recommender_production', device='cpu'):
        mlflow.set_tracking_uri(uri="http://mlflow:8080")                               #A
        client = MlflowClient()                                                         #A
        current_prod = client.get_model_version_by_alias(registered_model_name, "prod") #A
        model_uri = f"runs:/{current_prod.run_id}/model"                                #A
        bentoml.mlflow.import_model("recommender", model_uri)                           #A
        bento_model = bentoml.mlflow.get("recommender:latest")                          #A
        mlflow_model_path = bento_model.path_of(bentoml.mlflow.MLFLOW_MODEL_FOLDER)

        self.model = mlflow.pytorch.load_model(mlflow_model_path)
        self.device = device
        self.model.to(self.device)
        self.model.eval()
    
    @bentoml.api                                      #B
    def predict(self, user_id: int, top_k: int=10, ranked_movies:np.ndarray=None) -> np.ndarray:
        user_id = torch.tensor([user_id], dtype=torch.long).to(self.device)
        all_items = torch.arange(1, self.model.n_items + 1, dtype=torch.long).to(self.device)

        if ranked_movies is not None:                           #A
            ranked_movies = torch.tensor(ranked_movies, dtype=torch.long).to(self.device) 
            unrated_items = all_items[~torch.isin(all_items, ranked_movies)]
        else:
            unrated_items = all_items
        
        user_ids = user_id.repeat(len(unrated_items))
        
        with torch.no_grad():
            predictions = self.model(user_ids, unrated_items).squeeze()              #C
        
        top_n_indices = torch.topk(predictions, top_k).indices                      #D
        recommended_items = unrated_items[top_n_indices].cpu().numpy()
        
        return recommended_items
```

The previous code highlights changes to the code we made to pull models from MLFlow and involve changes mostly in the initialization of the service class. We first query MLFlow to get the model URI of the latest registered model with the alias `prod.`This is then downloaded locally and then the api serves it as we saw before. It is important to note that in a pipeline, we could remove the mlflow client since the URI would be an input parameter or a variable received from the previous step.

To build this into a service, we use the bentofile as below

##### Listing 10.2 Sample bentofile to create the inference service

```
service: "service:RecommenderRunnable"
labels:
  owner: mlops
  stage: demo
include:
  - "*.py"
python:
  requirements_txt: './requirements.txt'
```

Use `bentoml build` to create a bento out of our service and then `bentoml serve recommender_runnable:latest` to run the local inference server.

At this point, you should have a fully running bento on your local machine. Test it out by sending inference requests with the same arguments we did in the previous chapter as API calls to /predict to verify that the model is running and providing a response as expected.

Now that we have verified the model is serving as expected, we can containerize the model with `bentoml containerize recommender_runnable:latest`and we now have a fully deployable model server! Wasn't that fast?

Let's take a minute to consider how bentoML helped us here. By creating a simple service file and a bento definition file, we could create a fully fledged model server in a few commands. Without bentoML, this process would have required us to write a custom api server, create monitoring, health and liveliness endpoints all while handling complex ML specific issues like batching and GPU devices. BentoML also provides documentation out of the box that enables users to quickly look up input schemas and expected outputs, facilitating collaboration in organizations without blocking developer’s time to write detailed documentation.

Combining MLFLow and Bentos also shows how powerful this setup can be. We can have automated pipelines that create models, test them and then deploy them to an inference service. In our experience, the real advantage lies in the ease at which we can spin up a model server to test a model in staging on a local developer machine and then containerize a modified service. This enables interesting workflows like running AB tests with a main model from the automated pipelines and another model that perhaps employs a different data processing step to see how it works in production. As we keep saying, iteration is key in MLOps and this combined tooling is one that we have observed to provide the most advantages in cross functional organizations and teams. Finally, the BentoML ecosystem provides Yatai, a robust model serving framework designed to work well and scale on kubernetes clusters. BentoML and Yatai seamlessly integrate with each other and built bentos can be pushed to Yatai to spin up model servers. This is another reason we like BentoML since Yatai provides central storage and inference services.

## 10.6 Using only MLFLow to create an inference service

Although using BentoML and MLFlow together has its advantages, it still requires two tools and switching between them. Alternatively, we could use just MLFlow as well to create an inference service and stay within the MLFlow ecosystem.

To deploy a model using MLflow, you typically follow these steps:

1. Train and log your model using MLflow's tracking APIs.
1. Register the trained model in the MLflow model registry.
1. Use MLflow's built-in deployment tools to serve the model as a REST endpoint. MLflow supports various deployment options, including local serving, Docker containerization, and deployment to cloud platforms.

![Figure 10.11 Logical flow of using only MLFlow for the entire model lifecycle](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/10__image011.png)

We have already performed steps 1 and 2 in the previous chapter and we will go into step 3 here. To do this locally, we can simply run the following bash script.

```
#!/usr/bin/env sh
 
# Set environment variable for the tracking URL where the Model Registry resides
export MLFLOW_TRACKING_URI=http://mlflow:5000
 
# Serve the production model from the model registry
mlflow models serve -m "models:/recommender_production@prod"
```

This may be easier to spin up and run experiments within certain cases. To complete the workflow, we can also create a docker container that implements a model server with the command below which can later be deployed to run the inference services at scale.

```bash
mlflow models build-docker -m models:/recommender_production@prod -n recommender_service --enable-mlserver
```

While we mentioned that BentoML and MLFlow together worked for our use case, just using MLFlow can also be a valid deployment strategy. The model server also enables health and inference endpoints under /health and /invocations respectively. MLflow's deployment process is relatively straightforward and does not require Kubernetes knowledge, making it a good choice for teams that prioritize simplicity and ease of use. If the system requirements call for fine grained deployment options that can be deployed to a wide variety of environments with monitoring, using BentoML alongside MLFlow would be a better architecture.

## 10.7 KServe: An Alternative to BentoML

KServe, which comes with Kubeflow, provides a set of tools and abstractions for deploying, serving, and managing ML models as Kubernetes microservices. Like BentoML, KServe is ML-framework agnostic, allowing you to work with various machine learning frameworks seamlessly.

The workflow in KServe differs from BentoML. To deploy a model using KServe, you need to follow these steps:

1. You first create a Kubernetes namespace for your service. (e.g. `kubectl create ns pytorch-yolo`)
1. Then, you'll need to create an InferenceService, which is a custom resource definition of KServe that is the core abstraction for deploying and serving ML models. (Note this is just an example)

```bash
kubectl apply -n pytorch-yolo -f - <<EOF
apiVersion: "serving.kserve.io/v1beta1"
kind: "InferenceService"
metadata:
  name: "pytorch-yolo"
spec:
  predictor:
    model:
      modelFormat:
        name: sklearn
      storageUri: "gs://yolov8/models/pytorch/1.0/model"
EOF
```

1. The InferenceService will take a while to initialize. Once done, and assuming DNS has been configured correctly, the service will be assigned a URL.
1. From there, the service is ready to be consumed.

Kserve requires a fair bit of kubernetes knowledge and depending on the maturity of the organization might be restrictive to deploy models to test for a developer. Kserve is native to the kubeflow ecosystem and therefore is more scalable out of the box than using vanilla MLFlow or BentoML containers.

In summary, here are the key differences between KServe, MLFlow and BentoML:

| <br>      <br>      <br>        Feature <br>       <br> | <br>      <br>      <br>        KServe <br>       <br> | <br>      <br>      <br>        BentoML <br>       <br> | <br>      <br>      <br>        MLFlow <br>       <br> |
| --- | --- | --- | --- |
| <br>     <br>       Focus <br> | <br>     <br>       Model-serving orchestration <br> | <br>     <br>       Simplified model deployment and serving <br> | <br>     <br>       End-to-end ML lifecycle management <br>       <br>        <br> |
| <br>     <br>       Framework Support <br> | <br>     <br>       Framework agnostic <br> | <br>     <br>       Framework agnostic <br> | <br>     <br>       Framework agnostic <br> |
| <br>     <br>       Cloud Platform Support <br> | <br>     <br>       Platform agnostic <br> | <br>     <br>       Platform agnostic <br> | <br>     <br>       Platform agnostic <br> |
| <br>     <br>       Kubernetes-Centric <br> | <br>     <br>       Yes <br> | <br>     <br>       No <br> | <br>     <br>       No <br> |
| <br>     <br>       Ease-of-use <br> | <br>     <br>       Lower (More configuration and knowledge of Kubernetes needed) <br> | <br>     <br>       Higher (Easier to use API and abstractions that does not require Kubernetes knowledge) <br> | <br>     <br>       Higher (Simple APIs and deployment options) <br> |
| <br>     <br>       Experiment Tracking <br> | <br>     <br>       No <br> | <br>     <br>       No <br> | <br>     <br>       Yes <br> |

Choosing the right tool depends on your specific needs and requirements. If you have a Kubernetes-centric environment and require fine-grained control over model serving, KServe might be a good fit. However, if ease of use and quick deployment are your top priorities, BentoML and MLflow offer more straightforward approaches.

In our experience, BentoML stands out for its simplicity and developer-friendly APIs, allowing data scientists to get started quickly without requiring deep Kubernetes knowledge. MLflow, on the other hand, provides a comprehensive platform for managing the entire ML lifecycle, including experiment tracking and model versioning, making it a valuable tool for teams that prioritize end-to-end ML workflow management.

Ultimately, the choice between KServe, BentoML, and MLflow depends on your team's expertise, infrastructure setup, and the specific requirements of your machine learning projects.

As you embark on your model deployment journey, remember to evaluate your specific requirements and select the tool that aligns with your team's skills and project goals. With the insights gained from this chapter, you are well-equipped to build robust, scalable, and maintainable machine learning services.

## 10.8 Summary

- Model deployment introduces unique challenges, and understanding inference patterns, scalability, monitoring, and resource management is crucial.
- BentoML simplifies model deployment by providing a unified framework for packaging and serving models, allowing you to focus on the core functionality of your service.
- Building a BentoML service involves defining a Runner, creating a Service with API endpoints, and leveraging BentoML's intuitive APIs and decorators for input/output handling and async execution.
- BentoML provides built-in support for observability, including health checks, liveness/readiness probes, and Prometheus metrics, ensuring proper monitoring and management within a Kubernetes environment.
- Packaging your BentoML service into a Bento enables easy distribution and deployment across different environments, while Bento Tags provide a robust versioning and management system.
- Using MLFlow and BentoML provides a lot of advantages. Mlflow provides the lineage and tracking for models and bentoML seamlessly enables serving models in a registry.
- We can also use MLFlow by itself for the entire lifecycle. This might be preferable for smaller organizations where simplicity is preferred over feature sets.
- When selecting a model serving tool, consider alternatives like KServe and others with unique strengths. Choose based on ease of use, Kubernetes compatibility, and desired control level. BentoML shines for its simplicity and developer-friendly APIs.
