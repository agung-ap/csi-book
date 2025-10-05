# Chapter 9. Scaling: Hardware, Infrastructure, and Resource Management

Deploying and managing LLMs presents unique challenges and opportunities in the realm of infrastructure and resource management. LLMs, as you’ve seen throughout this book, are computationally intensive, requiring substantial hardware, storage, and network resources to operate efficiently. Whether you’re leveraging LLMs as a cloud-based service, deploying pretrained models in on-premises data centers, or training your own models from scratch, your infrastructure decisions will influence their performance, scalability, and cost-effectiveness.

Effective resource management for LLMs involves optimizing compute power, memory, and storage. In this chapter, we will explore the key components of infrastructure for LLMs, including hardware requirements and deployment strategies. We’ll also discuss best practices for optimizing resource use, managing costs, and maintaining reliability in production environments. This chapter will help you understand the trade-offs involved in managing resources for large-scale AI applications.

# Choosing the Right Approach

Selecting the appropriate method for using LLMs depends on the requirements of the application that you want to use it for. For startups or small-scale applications, using models directly from the cloud may be the quickest and most cost-effective solution. For enterprises with specialized requirements or high workloads, deploying LLMs on cloud infrastructure can help you find an appropriate balance between flexibility and scalability. Finally, for organizations with strict data privacy or latency requirements, local deployment offers unmatched control and security, though at the cost of higher operational complexity.

By carefully evaluating the trade-offs of each approach, your organization can align its LLM deployment strategy with its technical and business objectives, ensuring efficient and effective use of these transformative AI technologies.

Regardless of the solution you choose, my suggestion is to always begin with a third-party API-based approach; that is, start by using models directly from the cloud. One of the major issues I’ve observed in real-world deployments is figuring out whether the LLM is a good solution to a given problem. Using a third-party, API-based approach will allow you to answer that question in a prototype before committing a large number of resources to infrastructure.

# Scaling and Resource Allocation

To maintain performance, cost-effectiveness, and reliability in your LLM-based application, you’ll have to manage your resources well. Overallocating resources, especially those in high demand, such as the required GPUs and memory bandwidth to run AI systems, will lead to unnecessary expenses. Underallocating resources will expose you to risks of system crashes and poor user experiences.

Most training failures come from running out of memory and not compute. I call this the “iceberg problem” where the visible tip is the failure, but the real hidden issue is memory inefficiency beneath. Most people don’t realize that the real miss-out is when the suboptimal memory use goes unnoticed and under-utilized. Thus, people leave a lot of performance on the table. If you’re hitting memory walls, don’t reach for more hardware just yet. When used correctly, methods like sharding, activation checkpointing, dynamic batching, model offloading, etc., can easily make your 24 GB consumer GPU behave like a 48 GB A100.

The two main components of resource allocation are *monitoring* and *automating deployments*. You need to monitor in order to know when you are over- or underallocating resources. Then, once you have this information, you need to be able to react quickly. While it’s possible to live with manual deployments, the costs will likely become prohibitive over time. This is especially true if the demand for your service varies a lot, which could happen if your service achieves sudden success or expands to different geographical regions whose usage patterns reflect different time zones.

# Monitoring

Monitoring enables you to understand your application’s behavior, optimize resource usage, and maintain high availability and performance under varying workloads. A successful monitoring approach revolves around tracking key performance indicators (KPIs) using the appropriate monitoring tools, then developing appropriate procedures to implement changes when needed.

Key metrics for monitoring include:

Latency*Latency *measures the response time for user queries and is shown to directly impact user satisfaction. Your goal is to minimize latency.

Throughput*Throughput*, or the number of requests processed in a period of time (usually per second), indicates the system’s capacity to handle demand and is critical to understand how your system is performing during peak loads.

Resource utilization metrics*Resource utilization metrics* such as CPU, GPU, memory, disk I/O, and network bandwidth provide insights into which resources are and are not well allocated.

Error ratesMonitoring error rates, including server errors and application-specific issues like exceeding token limits or LLM safety responses, can help you identify issues before they become big problems.

CostMonitor cost to make sure your application is economically viable, especially for resource-intensive LLMs.

Cloud environments offer numerous native monitoring tools for these metrics that are tailored to their respective platforms, like AWS CloudWatch, Azure Monitor, and Google Cloud Operations Suite. These comprehensive tools enable you to track both standard and custom metrics, such as model-specific data like token usage or inference times.

Application performance-monitoring platforms like Datadog, New Relic, and AppDynamics go a step further by visualizing application dependencies, providing detailed insights into bottlenecks and potential failures. Model-specific platforms like Weights & Biases and MLflow allow you to monitor LLM behavior, track fine-tuning iterations, and compare deployments.

For logging, centralized systems like the ELK Stack or Fluentd are valuable for capturing detailed application logs, query specifics, and system warnings; distributed tracing tools like OpenTelemetry or Jaeger let you trace requests across services to pinpoint latency hotspots.

A good monitoring architecture will have at least three layers:

Client layerThe client layer allows you to capture user-side performance and satisfaction metrics, often by asking users to rate an answer using a thumbs-up or a thumbs-down.

Application layerThe application layer can focus on API performance, tracking throughput, processing times, and error rates.

Infrastructure layerThe infrastructure layer can monitor the underlying resources that host the LLM and your application, measuring CPU, GPU, memory, storage, and I/O performance.

Finally, you can treat the model as a separate fourth layer, depending on the kind of granularity you want. This is especially desirable for LLM-based applications. This *model layer* can track inference times, token usage, token caching, and other model-specific metrics, such as perplexity.

Real-time alerting can help automate issue detection. By setting thresholds for metrics like latency, resource utilization, and error rates, you can receive alerts by email or SMS when a specific metric falls below expected levels. It’s also a good idea to implement *synthetic monitoring* by automatically sending your application some requests for which you know the expected answer and measuring the output.

When a threshold fails, you can set scripts to trigger automatically; for example, starting a new virtual machine if a current one hits some CPU- or memory-level threshold. You can also automatically run scripts to reduce downtime during common issues, such as restarting services periodically or scaling resources up or down based on anticipated demand.

The insights you derive from monitoring will be invaluable in optimizing your system. For instance, *autoscaling* mechanisms can adjust compute resources dynamically, based on workload demands. *Horizontal scaling* can accommodate more requests by adding instances, while *vertical scaling* increases the capacity of existing nodes. *Caching* frequently accessed responses reduces latency and lessens the workload on the model, while *batching* low-priority queries enhances efficiency. Furthermore, techniques like model distillation and quantization (discussed in [Chapter 5](https://learning.oreilly.com/library/view/llmops/9781098154196/ch05.html#ch05_model_domain_adaptation_for_llm_based_applications_1748896666813361)) can optimize the model itself, balancing performance with resource consumption.

Monitoring is not a one-time setup but a continuous process of observability and refinement. Observability tools allow you to identify workload patterns, predict resource needs, and analyze trends in user interactions to refine both your infrastructure and your model’s performance. Advanced testing techniques, such as A/B and shadow testing, let you validate new deployments in a controlled manner, minimizing risks while introducing improvements. These are discussed in the ​next section.

# A/B Testing and Shadow Testing for LLMs

As described in [Chapter 7](https://learning.oreilly.com/library/view/llmops/9781098154196/ch07.html#ch07_evaluation_for_llms_1748896751667823), A/B testing is a widely used method for evaluating the performance of different versions of a system. In the LLM context, A/B testing involves deploying two versions of the LLM—often referred to as the “champion” (the existing model) and the “challenger” (the new model)—to determine which performs better under real-world conditions using the metrics described previously.

In contrast, *shadow testing* provides a safer, less intrusive way to evaluate a new model without directly affecting users. In this approach, the challenger model runs in the background, “shadowing” the champion model by processing the same inputs (or a fraction of them, for cost savings) but without influencing the live application’s outputs. This allows teams to collect performance data, identify potential issues, and fine-tune the challenger model before making it available to users. Shadow testing is particularly useful for testing LLMs in high-stakes or sensitive applications, such as customer service or healthcare, where introducing a flawed model could lead to significant negative consequences. Again, the better defined your metrics are, the more accurately you can see whether the new model performs better or worse than the existing one.

One caveat: in shadow testing, the users don’t see the output of the new model, so you can only collect their interactions with or feedback about the existing (champion) model. This makes A/B testing ideal for situations where user feedback is essential to evaluating performance, whereas shadow testing is better suited for testing infrastructure and ensuring a model’s reliability and safety *before* deployment.

# Automatic Infrastructure Provisioning and Management

Deploying and managing infrastructure for LLMs requires significant resources, whether in cloud architectures or on premises. Automatic infrastructure provisioning can help you optimize resource utilization, ensure scalability, and reduce operational overhead by dynamically adjusting your infrastructure to meet your model’s computational demands during training, fine-tuning, and inference based on monitoring signals.

## Provisioning and Management in Cloud Architectures

The major​ cloud platforms offer tools for automatic infrastructure provisioning and management, including scalable compute instances, GPU and TPU support, managed storage, and networking solutions tailored for AI workloads. Tools like AWS CloudFormation, Azure Resource Manager (ARM), and Google Cloud Deployment Manager allow you to deploy *infrastructure as code* (IaC) and define infrastructure requirements like products, versions, and features in declarative YAML or JSON templates. These templates automate resource provisioning to keep environments consistent across multiple deployments.

One of the most significant advantages of cloud architectures is their ability to scale resources automatically based on demand. Services like AWS Auto Scaling, Azure Virtual Machine Scale Sets (VMSS), and Google Cloud Platform (GCP) Autoscaler can dynamically increase or decrease the number of compute instances based on predefined metrics, such as CPU usage, memory consumption, and GPU utilization. Linking one of these tools to your monitoring setup can really help you manage costs and latency. This elasticity is particularly useful for LLM inference, which consumes expensive resources quickly. You can also use your monitoring metrics to automatically scale down resources that are not being used and quickly scale up when needed.

Cloud providers also offer cost-saving options like AWS Spot Instances, Azure Spot VMs, and GCP preemptible VMs, which let you take advantage of unused capacity at a lower price. These are ideal for noncritical workloads, such as batch processing or distributed LLM training. However, because these instances can be interrupted, it’s critical to integrate their provisioning with your monitoring infrastructure to manage fault tolerance and job retries.

Finally, as we noted earlier, cloud-based monitoring tools like AWS CloudWatch, Azure Monitor, and GCP Operations Suite can track resource utilization, detect anomalies, and trigger automated actions. You can combine them with automation tools like AWS Lambda, Azure Functions, or GCP Cloud Functions to enable *self-healing *architectures. For example, if a GPU instance fails during an LLM training job, a function can automatically provision a replacement instance, then restart the job. These tools are very configurable. While you’re likely to use many preconfigured metrics as they are (such as those for CPU and memory usage), you should still configure custom metrics for your specific use case.

## Provisioning and Management on Owned Hardware

For organizations that choose to deploy LLMs on hardware they own themselves, whether on premises or in private clouds, automatic provisioning and management present unique challenges and opportunities. These setups often rely on virtualization technologies (like VMware, Proxmox, or Hyper-V) and containerization platforms (like Kubernetes or Docker Swarm) to orchestrate resources effectively.

Deploying LLMs on owned hardware often involves deciding between “bare metal” servers and virtualized environments. Bare metal offers better performance and is well suited for resource-intensive tasks like LLM training or fine-tuning, especially when paired with high-end GPUs like NVIDIA A100s or H100s. However, virtualization provides greater flexibility, allowing multiple workloads to share resources. Tools like Kubernetes node pools can allocate GPU resources to pods dynamically, optimizing resource utilization across LLM workloads.

Just as in cloud environments, on-premises deployments can leverage IaC tools like Terraform, Ansible, and Chef to automate infrastructure provisioning. These tools enable the consistent configuration of servers, networking, and storage, ensuring reproducibility across environments. For example, you could use Terraform to define GPU-enabled nodes and Ansible to configure ML frameworks like PyTorch or TensorFlow on those nodes.

On-premises deployments require robust monitoring to track resource usage and performance. You can use open source tools like Prometheus and Grafana to visualize metrics, while workload schedulers like SLURM (Simple Linux Utility for Resource Management) and Kubernetes help allocate compute resources efficiently. For inference tasks, edge deployments may also benefit from low-latency scheduling algorithms to prioritize real-time requests.

Scaling on-premises infrastructure is more challenging than in the cloud, since it requires purchasing and provisioning additional hardware. Hybrid approaches—combining owned hardware with cloud resources—can address this limitation. For example, you might train your LLM using local GPUs but offload inference or testing workloads to the cloud during peak demand. However, hybrid architectures also present challenges; for example, your LLMOps engineer will need to configure the endpoints and parameters for when to send requests to different endpoints, as well as implement monitoring and automatic failure recovery. [Table 9-1](https://learning.oreilly.com/library/view/llmops/9781098154196/ch09.html#ch09_table_1_1748896826210123) compares several aspects of managing* *LLMs in the cloud versus on premises.

| Aspect | Cloud architectures | Owned hardware |
| --- | --- | --- |
| Scalability | <br>			Highly scalable with autoscaling tools<br> | <br>			Limited by hardware availability<br> |
| Up-front costs | <br>			Low up-front costs; pay-as-you-go model<br> | <br>			High up-front costs for hardware acquisition<br> |
| Operational costs | <br>			Variable costs based on usage<br> | <br>			Fixed costs for power, cooling, and maintenance<br> |
| Performance | <br>			High for training/inference with cloud GPUs<br> | <br>			High for specific workloads with bare metal<br> |
| Flexibility | <br>			Easy to provision and reconfigure resources<br> | <br>			Requires manual or automated reconfiguration<br> |
| Control | <br>			Limited to cloud provider’s offerings<br> | <br>			Full control over hardware and software stack<br> |

## Best Practices for Automatic Infrastructure Management

Combining the flexibility of cloud platforms with the control of owned hardware allows organizations to leverage the best of both worlds. A few best practices to implement are:

Cloud burstingWith this common strategy, additional workloads are handled by the cloud during peak demand.

Using automation pipelinesUse IaC and CI/CD pipelines to automate deployment and updates. For instance, Jenkins or GitHub Actions can automate resource provisioning, LLM deployment, and inference tasks.

Optimizing for cost and performanceWhether in the cloud or on premises, monitoring tools and scheduling algorithms can help you balance cost and performance. Use the cost simulators provided by your cloud platform or benchmark tests for owned hardware to plan your deployments.

Designing for high availability and redundancyEnsure that critical LLM applications are fault tolerant by deploying resources across multiple zones (in the cloud) or using redundant hardware (on premises). Implement automated failover mechanisms to minimize downtime.

## Scaling Law and the Compute-Optimal Argument

The [compute-optimal argument](https://oreil.ly/dLHHa) is a principle in ML model training that addresses the trade-off between model size (number of parameters) and the amount of data used for training, emphasizing finding a balance between these factors to optimize use of available computational power.

This principle was formalized by DeepMind’s Chinchilla scaling law, discussed in [Chapter 5](https://learning.oreilly.com/library/view/llmops/9781098154196/ch05.html#ch05_model_domain_adaptation_for_llm_based_applications_1748896666813361), which revealed that many earlier LLMs, such as GPT-3, were undertrained relative to their size. These models used a disproportionate amount of compute to scale their number of parameters but didn’t implement a corresponding increase in the volume of training data. This imbalance resulted in suboptimal performance because the models had a vast number of parameters but weren’t exposed to enough training data to find the optimal weights for those parameters.

The practical implication here is that, when allocating computational resources to train an LLM, you have to balance the model’s size with the amount of training data. That’s where the compute-optimal argument comes in. For instance, rather than building a massive model but training it with inadequate data, it may be a more effective use of resources to create a smaller model and train it more thoroughly on the same dataset.

A major benefit of training models with a compute-optimal balance is that they tend to require less retraining or fine-tuning for downstream tasks than overly large, undertrained models require. More modern default models like GPT-4 and newer versions of Claude and Gemini do apply the compute-optimal principle, making them better at general tasks and decreasing the need for custom fine-tuning.

Let’s work through a concrete example.

The Chinchilla scaling law suggests that for a compute budget *C*, the relationship between a model’s number of parameters *N* and the training data it uses *D* (measured in tokens) is:

C∝N×DHere, the ∝ symbol means to “proportional to.”

Additionally:

D∝NThis means that *D* should scale approximately linearly with *N*. The optimal proportion between tokens and parameters is between 15 and 25; that is, the number of tokens should be between 15 and 25 times the number of ​parameters.

Suppose you have a compute budget of C=1023 floating-point operations (FLOPs) and you want to train an LLM. Let’s explore two scenarios for that compute budget.

### Scenario 1: Overprioritize model size

Overprioritize model size by training a 200-billion-parameter model on 300 billion tokens of data:

N=200×109D=300×109Here, your *D*/*N* is 1.5 tokens per parameter, falling below the compute-optimal zone specified by the Chinchilla scaling law.

The compute required for training is proportional to *N × D*, and the exact proportionality *k* is unknown:

C=k×N×DSubstituting *N* and *D*, we obtain:

C=k×(200×109)×(300×109)=k×6×104×1018=6×1022This fits within the compute budget of 1023 FLOPS.

### Scenario 2: Compute-optimal strategy

Use the compute-optimal strategy and train a smaller model of 50 billion parameters on 1 trillion (a thousand billion) tokens:

N=50×109D=1,000×109Here, your *D*/*N* is 20.

The compute required for training is:

C=k×(50×109)×(1,000×109)=k×5×104×1018=5×1022Not only does that fit within the compute budget of 1023 FLOPS, but the *D*/*N* of 20 tokens per parameter also falls within the compute-optimal zone. This finding indicates that training a smaller model with more data will lead to better performance per unit of compute.

Scenario 2 is a better solution, because it ensures that every parameter has sufficient exposure to training data, reducing overfitting and utilizing resources ​appropriately.

# Optimizing LLM Infrastructure

Deploying and managing LLMs efficiently requires infrastructure, of course, but optimizing it also requires software that takes advantage of that infrastructure. To meet the demands of LLM training and inference, techniques such as compilers; parallel and distributed computing; and frameworks like CUDA (Nvidia’s Compute Unified Device Architecture), NCCL (NVIDIA Collective Communications Library), ZeRO (Zero Redundancy Optimizer), DeepSpeed, TF-Replicator, and Horovod play critical roles. Another key aspect of optimization is fault tolerance and backup systems. In an ideal situation, all your resources would go toward enhancing performance, but in practice, some need to be used to ensure that your system can continue to operate (overhead costs).

*Compilers* translate high-level code into machine instructions optimized for specific hardware architectures. For LLM workloads, which demand high computational efficiency, you need specialized compilers such as NVIDIA’s NVCC (for CUDA), TensorFlow’s XLA, or PyTorch’s TorchScript. These compilers focus on achieving three types of optimizations: kernel fusion, precision scaling, and hardware utilization. Let’s look at each type in turn.

## Kernel Fusion

*Kernel fusion *is a technique where multiple computational operations are combined into a single GPU kernel to reduce memory traffic and execution overhead. In deep-learning workflows, operations like matrix multiplications, element-wise additions, and activations often occur sequentially. Without kernel fusion, these operations would each involve separate memory read/write operations, “going out of the core” to save intermediate results and then “going out of the core” again to read these intermediate results. The repeated need to access global memory leads to latency and inefficiency. Compilers thus identify opportunities to combine (or *fuse*) these operations. The benefits of fusing include:

Reduced memory accessIntermediate results are stored in faster, low-latency GPU registers or shared memory, rather than being written back to global memory.

Minimized kernel launch overheadEach kernel launch has a computational overhead. Fused kernels require fewer launches, speeding up execution.

Improved cache efficiencyFusion allows related operations to share data in memory more effectively, reducing cache misses.

For example, a typical deep-learning evaluation sequence like `ReLU(Wx + b)`, where `W` and `b` are the weights and biases, can be fused into a single kernel that computes the matrix multiplication (`Wx`), adds the bias (`+b`), and applies the activation function (`ReLU`) without having to write each intermediate step in the global memory outside of the GPU.

## Precision Scaling

Deep-learning workloads often involve numerical computations that don’t require high precision. *Precision scaling* enables models to use lower-precision formats like 16-bit floating point (FP16) or brain floating point (BF16) instead of the traditional 32-bit floating point (FP32) format. Compilers help by:

Automating mixed-precision trainingCompilers like NVIDIA’s APEX (for PyTorch) and TensorFlow’s Mixed Precision API automatically downscale certain operations to FP16 while maintaining critical operations (such as gradient accumulation) in FP32. This ensures numerical stability while reducing memory usage and speeding computation.

Leveraging specialized hardwareModern GPUs (like NVIDIA’s A100 or H100) include tensor cores optimized for lower precision. Compilers can translate high-level operations into instructions that specifically use these lower-precision cores, significantly speeding up matrix multiplications and other tensor operations while freeing up the higher-precision cores for operations that require them.

Enhancing memory efficiencyBy reducing precision, models can consume less memory, which lets you use larger batch sizes or train on hardware with lower memory capacity.

## Hardware Utilization

Efficient hardware utilization ensures that GPUs or other accelerators operate at their full potential, maximizing computational throughput. Modern hardware can include specialized units such as tensor cores, matrix multiplication units, and vector processors. Compilers map operations like general matrix multiplication to these specialized units, leveraging their high throughput and freeing more general resources for other tasks.

*Instruction-level parallelism* is another way AI-specialized compilers can optimize hardware utilization. They can generate code that exploits parallelism at multiple levels, including at the thread level (using thousands of GPU threads) and the vector level.

*AI-specialized compilers* know how memory is organized in modern GPUs and AI servers, so their memory hierarchies are especially efficient. They optimize the code to use shared memory, registers, and caches effectively and reduce reliance on the slower global memory.

# Parallel and Distributed Computing for LLMs

Large-scale LLMs require parallel and distributed computing to manage their immense computational and memory demands. Techniques like *data parallelism*, *model parallelism*, and *pipeline parallelism* distribute the workload across multiple processors or nodes to use hardware resources efficiently. The building blocks of these techniques are the CUDA and NCCL frameworks.

NVIDIA’s CUDA is the cornerstone of GPU-based acceleration, providing APIs for high-performance parallel computing. It lets developers write code that directly utilizes GPUs’ processing power, which is critical for LLM tasks like matrix multiplication, attention mechanisms, and gradient computations. Even very small language models depend on CUDA to run with acceptable performance.

The NCCL complements CUDA by optimizing communication among multiple GPUs. It provides primitives for data movement, such as `all-reduce`, `all-gather`, and `broadcast`, ensuring minimal latency and high bandwidth. This is particularly important in distributed training, where model gradients frequently need to be synchronized between GPUs. As models grow, they tend to require multiple GPUs, and NCCL provides APIs that let different GPUs communicate.

## Data Parallelism

*Data parallelism* involves splitting training dataset into chunks, each corresponding to a device (such as a GPU or TPU). Each device processes its own chunk in parallel during a training iteration. You then place an identical copy of the model on each device, which computes the gradients for its chunk of data. Next, the gradients are averaged and synchronized across devices, using communication primitives like `all-reduce`, and the averaged gradients are applied to update the model’s parameters on each device.

## Model Parallelism

*Model parallelism* divides the model itself across multiple devices, making each device responsible for a portion of the model, such as a few layers (or operations). This is useful when the model is too large to fit on a single device. You then pass the input through the model sequentially, moving intermediate outputs between devices as needed; this is called a *forward pass*. Next, in a *backward pass*, you compute the gradients for each layer in reverse order. This helps to synchronize across devices for gradient flow. Finally, parameters are updated, either independently on each device or via a central parameter server.

Model parallelism optimizes memory but at the cost of throughput; while one device works on an input, the other devices wait.

## Pipeline Parallelism

*Pipeline parallelism* also divides the model, assigning different layers to different devices, much like in model parallelism. However, in pipeline parallelism, the data batches are broken up into smaller pieces so that as many devices as possible are occupied at any given time. This requires additional communication but reduces idle compute time.

[Figure 9-1](https://learning.oreilly.com/library/view/llmops/9781098154196/ch09.html#ch09_figure_1_1748896826206032) shows an example of implementing pipeline parallelism with four devices and breaking the batch data into four micro-batches.

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098154196/files/assets/llmo_0901.png)

###### Figure 9-1. Implementing pipeline parallelism

Pipeline parallelism is very effective in speeding up the training of models with a smaller hardware footprint, but it used to be hard to implement. In 2022, Meta released Pipeline Parallelism for PyTorch, or [PiPPy](https://oreil.ly/g5EZ3). PiPPy was merged into the main PyTorch distribution as the `torch.distributed.pipelining` subpackage and no longer requires a separate installation.

# Advanced Frameworks: ZeRO and DeepSpeed

Developed by Microsoft, ZeRO minimizes memory overhead during training by partitioning model states (like parameters, gradients, and optimizer states) across devices. This lets you train models with tens or even hundreds of billions of parameters without requiring GPUs with excessive memory capacities.

Built on top of ZeRO, DeepSpeed is a deep-learning optimization library that makes training large models more efficient. It provides features like mixed-precision training, gradient accumulation, and memory optimization, significantly reducing training time and cost.

[Table 9-2](https://learning.oreilly.com/library/view/llmops/9781098154196/ch09.html#table0902) summarizes when to use each technique mentioned.

| Technique | The problem it solves | How it works | Trade-off |
| --- | --- | --- | --- |
| Sharding | Model too big for one GPU | Split model weights/layers across multiple GPUs | Increased complexity in syncing and communication |
| Activation checkpointing | High memory use during backprop | Save only key activations and recompute the rest later | Extra compute time |
| Dynamic  <br>batching | Wasted compute on small requests | Group inputs on the fly to maximize GPU use | Slight response delay |
| Model  <br>offloading | GPU can’t hold entire model | Move unused parts to CPU or disk; fetch when needed | Slower due to transfer time |
| Mixed precision training | Activations and weights take too much space | Use lower-precision (e.g., FP16) instead of FP32 | Slight loss in numerical accuracy (often negligible) |
| Quantization | Models are too large for deployment | Compress weights to 8-bit or lower | Potential accuracy loss if not careful |
| Gradient accumulation | Batch size too big for GPU | Split one big batch into smaller chunks and accumulate gradients | Slower iteration time |
| Zero Redundancy Optimizer (ZeRO) | Redundant optimizer state across GPUs | Partition optimizer state and gradients across devices | Complexity and comm overhead |
| Operator fusion | Too many small intermediate tensors | Combine multiple ops into one to reduce memory ops | Needs compiler/tooling support |
| Paged attention (for inference) | Memory spikes from long contexts | Stream key–value cache in and out like virtual memory | Requires smart scheduling |

## Backup and Failsafe Processes for LLM Applications

In LLM applications, the LLMOps engineer is usually responsible for managing backups. Failures do happen, due to hardware malfunctions, software issues, or even malicious activity. LLM engineers can mitigate risk with robust backup and failsafe strategies to ensure continuity and minimize downtime.

The name of these activities can be misleading. Having a well-documented, regularly tested restore strategy is just as important as having good backups. It’s far too common for longtime practitioners to have “war stories” of occasions when backups were done for years but never tested and that, when actually required, did not work.

Which artifacts the LLMOps engineer backs up will vary, depending on the stage of the model and application lifecycle. During development, the most common artifacts to back up are the training data and intermediate model weights (model checkpoints), as well as the files describing the training as infrastructure as code. Datasets for training and model checkpoints tend to be very large, while the IaC files tend to be small.

As the application moves to production, the IaC files representing the production architecture should be backed up, as well as user data (such as query logs and personalizations) and performance metrics. LLMs depend on large datasets, and losing preprocessed or fine-tuning data can be extremely costly. Backups safeguard the data from corruption or accidental deletion. Training LLMs is also computationally expensive, so backups of model checkpoints can make a big difference in the event of a failure or data corruption, preserving progress. Furthermore, many industries and jurisdictions have compliance standards that require data to be backed up for auditability and accountability.

## Types of Backup Strategies

Backup strategies for LLM applications fall into three basic categories: full, incremental, and differential. Let’s examine these more closely:

Full backupsFull backups capture an *entire* dataset or model at a specific point in time. While they require significant storage, they are comprehensive and straightforward to restore.

Incremental backups*Incremental backups* store only the changes made since the last (full or incremental) backup, to reduce storage requirements. To restore, you need the entire historical sequence of data; even a single missing data block will cause the restore to fail.

Differential backups*Differential backups *save the changes made since the last *full* backup, balancing storage efficiency and recovery speed. To restore, you need the latest full backup and the latest differential backup.

Your choice of backup strategy depends on a few factors. High-stakes applications require more frequent backups and redundancy and often less downtime as well. Restores for critical applications need to be fast and trouble-free, so frequent full backups are usually recommended.

Data volume is also an important factor. Incremental or differential backups can help minimize storage overhead for large datasets like those used in LLM applications, since making full copies daily consumes expensive time and storage.

In volatile systems where the data changes rapidly, such as active fine-tuning environments, frequent backups are a particularly good idea. If the data volume is small, these can even be full backups. For relatively static systems like deployed inference models, however, you can have a lower frequency of backups (for example, weekly).

## The Most Important Practice: Test Restores Regularly

Regardless of your backup strategy, it is *imperative* that you regularly test the restore process. For example, large backups are often placed in cold storage, which is a lot cheaper than hot storage. *Hot storage* is somewhat similar to having a folder on the cloud, in that you can access files immediately. *Cold storage *is more like keeping a disk in a warehouse—it takes a while to access the data, sometimes as long as a few days. An LLMOps engineer can go from hero to zero quickly by saying, “Don’t worry, I have all the data backed up; however, production will be down for two weeks while I retrieve it.”

# Conclusion

Managing LLM infrastructure and resources requires different approaches depending on whether you’re running them on custom cloud infrastructure or owned hardware. Your choice of deployment strategy should consider cost, scalability, data privacy, and operational complexity. Regardless of the choice of infrastructure, LLMOps engineers have to monitor and evaluate performance to ensure that their deployments remain efficient and reliable.

Scaling LLM infrastructure effectively requires advanced tools, like special compilers that optimize hardware usage, and techniques, such as balancing model size and training data to improve performance at a given cost. Understanding and implementing parallelism strategies lets you train and deploy even the largest models.

It’s crucial to have good backup strategies and to test restores regularly, identifying potential failure points. Integrating these best practices will help you deploy resilient, high-performance AI-driven applications that meet your customers’ demands.

# References

Hoffman, Jordan, et al. [“Training Compute-Optimal Large Language Models”](https://oreil.ly/dLHHa), arXiv, March 29, 2022.

Mueller, Z. R. [PiPPy](https://oreil.ly/g5EZ3), PyTorch, September 2024.
