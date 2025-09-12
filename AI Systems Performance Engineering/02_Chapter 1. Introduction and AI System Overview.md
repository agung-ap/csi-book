# Chapter 1. Introduction and AI System Overview

# A Note for Early Release Readers

With Early Release ebooks, you get books in their earliest form—the author’s raw and unedited content as they write—so you can take advantage of these technologies long before the official release of these titles.

This will be the 1st chapter of the final book.

If you’d like to be actively involved in reviewing and commenting on this draft, please reach out to the editor at *arufino@oreilly.com*.

In late 2024, a small startup in China called DeepSeek.AI stunned the AI community by training a frontier large language model without access to the latest, state-of-the-art NVIDIA GPUs at the time. Due to export restrictions, DeepSeek’s engineers could not obtain top-tier NVIDIA A100 or H100 accelerators, so they resorted to locally available, less-capable NVIDIA chips.

Despite these limitations, DeepSeek.AI trained their DeepSeek-R1 model and achieved reasoning capabilities near the performance of leading frontier models that were trained on the most capable NVIDIA chips at the time. This case underscores that practitioners and researchers skilled in AI systems performance engineering can get the most out of their available hardware - no matter the constraints.

For example, DeepSeek’s engineers treated communication bandwidth as a *scarce resource*, optimizing every byte over the wire to achieve what many thought impossible on that infrastructure. They scaled out to thousands of these constrained GPUs - connected with limited-bandwidth interconnects - using novel software and algorithmic optimizations to overcome these limitations.

Contrast DeepSeek’s approach with the “brute force” path taken by the largest AI frontier labs in the U.S. and Europe. These labs continue to pursue larger compute clusters and larger models. Model sizes have exploded from millions to billions, and now to trillions of parameters. And while each 10× increase in scale has unlocked qualitatively new capabilities, they require tremendous cost and resources.

For instance, OpenAI’s GPT-3 (175B parameters, 2020) cost on the order of $4 million to train and GPT-4 (2023) required an estimated $78 million. Google’s Gemini Ultra (2023) soared to a staggering ~$191 million. [Figure 1-1](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch01.html#ch01_figure_1_1744914894403021) illustrates this ballooning of training expenses – from under $10M around 2019 to well over $100M by 2023 for state-of-the-art models.

![A poster of a training cost  AI-generated content may be incorrect.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9798341627772/files/assets/ch01_figure_1_1744914894403021.png)

###### Figure 1-1. The cost to train cutting-edge AI models has skyrocketed (Source: [posts.voronoiapp.com](https://posts.voronoiapp.com/technology/The-Training-Costs-of-AI-Models-Over-Time-1334#:~:text=The%20cost%20of%20training%20AI,4%20last%20year))

DeepSeek claims that their DeepSeek-R1 model was trained for only [$6 million](https://www.forbes.com/sites/markminevich/2025/02/06/the-6-million-ai-bombshell-how-deepseek-shook-wall-street-and-ai-leadership/) in compute – an order of magnitude lower than models like GPT-4 and Gemini – while matching performance of rival models that cost orders-of-magnitude more money.

While there was some doubt as to the validity of the $6 million claim, the announcement briefly shocked the U.S. financial market including NVIDIA’s stock which dropped 17% on the news, amid concerns that [less NVIDIA hardware](https://www.voronoiapp.com/innovation/DeepSeek-R1-Upsets-AI-Market-With-Low-Prices-3846) would be needed in the future. While this market reaction was a bit overblown, it underscores the significant financial impact of such AI efficiency breakthroughs on the global financial markets.

Beyond model training, DeepSeek boasts significant inference efficiency gains through novel hardware-aware algorithmic improvements to the Transformer architecture which powers most modern, frontier large-language models. DeepSeek has clearly demonstrated that clever AI systems performance engineering optimizations can upend the economics of ultra-scale AI model training and inference.

The takeaway is a profound realization that, at these scales, every bit of performance squeezed out of our systems could translate to millions, or even billions, of money saved. Every bottleneck eliminated can have an outsized impact on training throughput and inference latency. This, in turn, reduces cost and increases overall end-user happiness. In short, AI systems performance engineering isn’t just about speed – it’s about making the previously impossible both possible and affordable.

In [Chapter 1](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch01.html#ch01_introduction_and_ai_system_overview_1744914894413851), we embark on an in-depth exploration of the AI Systems Performance Engineer — a role that has become pivotal in the era of large-scale artificial intelligence. This chapter serves as a comprehensive guide to understanding the multifaceted responsibilities and the critical impact of this profession on modern AI systems.

We begin by tracing the evolution of AI workloads, highlighting the transition from traditional computing paradigms to the demands of contemporary AI applications. This context sets the stage for appreciating the necessity of specialized performance engineering in AI.

The chapter then dives into the core competencies required for an AI Systems Performance Engineer. We examine the technical proficiencies essential for the role, including a deep understanding of hardware architectures, software optimization techniques, and system-level integration. Additionally, we discuss the importance of soft skills such as problem-solving, communication, and collaboration, which are vital for navigating the interdisciplinary nature of AI projects.

A significant portion of the chapter is dedicated to the practical aspects of the role. We explore how performance engineers analyze system bottlenecks, implement optimization strategies, and ensure the scalability and reliability of AI systems. Real-world scenarios and case studies are presented to illustrate these concepts, providing tangible examples of challenges and solutions encountered in the field.

Furthermore, we discuss the tools and methodologies commonly employed by performance engineers, offering insights into performance testing, monitoring, and benchmarking practices. This includes an overview of industry-standard tools and how they are applied to assess and enhance system performance.

By the end of [Chapter 1](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch01.html#ch01_introduction_and_ai_system_overview_1744914894413851), readers will have a thorough understanding of the AI Systems Performance Engineer’s role, the skills required to excel in this position, and the critical importance of performance engineering in the successful deployment and operation of AI systems. This foundational knowledge sets the stage for the subsequent chapters, where we delve deeper into specific techniques, technologies, and best practices that define excellence in AI performance engineering.

# The AI Systems Performance Engineer

AI Systems Performance Engineer is a specialized role focused on optimizing the performance of AI models *and* the underlying systems they run on. These engineers ensure that AI training and inference pipelines run fast, cost-efficiently, and with maximum performance. As the scale increases, the AI Systems Performance Engineer becomes even more critical.

AI Systems Performance Engineers command top salaries, and for good reason. Our work has a clear impact on the bottom line. We blend expertise across hardware, software, and algorithms. We must understand low-level OS considerations, memory hierarchies, networking fundamentals, and multiple languages like Python and C++.

On any given day, an AI Systems Performance Engineer might be examining low-level GPU kernel efficiency, optimizing OS thread scheduling, analyzing memory access patterns, increasing network throughput efficiency, or debugging distributed training algorithms. Key responsibilities of an AI Systems Performance Engineer include benchmarking, profiling, debugging, optimizing, scaling, and managing resources efficiently.

## Benchmarking and Profiling

Benchmarking and profiling** **involves measuring latency, throughput, memory usage, and other performance metrics for AI models under various workloads. To identify bottlenecks, we must iteratively use profiling tools such as NVIDIA Nsight and PyTorch profiler to track performance over time as we make controlled enhancements. It’s important to set up automated performance tests to catch regressions early

Debugging and optimizing requires that we trace performance issues to their root cause whether it’s a suboptimal CUDA kernel, an unnecessary communication overhead, or an imbalance in our training or inference workload.

In one case, we may want to use more-efficient matrix operations that take advantage of the latest Transformer Engine hardware. In another case, we can improve the software framework by configuring a higher-degree of parallelism for our “embarrassingly-parallel” inference workload. In yet another case, we may try to improve the Attention algorithm by implementing better memory management and reducing the amount of memory moved in and out of GPU RAM relative to the number of GPU computations required.

Even minor code tweaks yield major wins. For example, maybe a data preprocessing step written in Python is holding up an entire training pipeline. Reimplementing it in C++ or using a GPU-optimized vectorization library like NVIDIA’s CuPyNumeric library could remove that bottleneck

## Scaling Distributed Training and Inference

Scaling small research workloads to larger production workloads on ultra-scale clusters will ensure that as we move from 8 GPUs to 80,000 GPUs, the system will scale with minimal efficiency loss. This requires that you optimize communication between GPUs on a single node - as well as across 1000’s of nodes - for collective reduction/aggregation operations like all-reduce which is used extensively during model training.

You may want to place data cleverly across nodes using data parallelism. Or you may need to redesign the workload to use tensor parallelism or pipeline parallelism because the model is so large that it doesn’t fit onto a single GPU. Perhaps you are using an Mixture of Experts (MoE) model and can take advantage of expert parallelism.

AI Systems Performance Engineers often need to implement distributed communication strategies to allow models to train on tens of thousands of GPUs without incurring excessive overhead.

## Managing Resources Efficiently

It’s important to optimize how models utilize resources like CPU cores, GPU memory, interconnect bandwidth, and storage I/O This can involve everything from ensuring GPUs are fed with data at full throttle, to pinning threads on specific CPU cores to avoid context-switch overhead, to orchestrating memory usage so that we don’t run out of GPU RAM in the middle of training/inferencing with a large model.

## Cross-Team Collaboration

Cross-team collaboration is absolutely critical for AI Systems Performance Engineers. It’s important to work hand-in-hand with researchers, data scientists, application developers, and infrastructure teams Improving performance might require modifying model code which involves coordination with researchers. Or you may want to deploy a new GPU driver to improve efficiency which requires the infrastructure team. The performance engineer sits at the intersection of these multi-disciplinary domains and speaks the language of AI, computer science, and systems engineering.

## Transparency and Reproducibility

In performance engineering, it’s vital to measure everything and trust data, not assumptions. By publishing your work, others can learn, reproduce, and build upon your findings.

One notable aspect of DeepSeek’s story is how openly they shared their infrastructure optimizations. During DeepSeek’s Open-Source Week in February 2025, they released a suite of open source Github repositories including FlashMLA, DeepGEMM, DeepEP/DualPipe, and Fire-Flyer File System (3FS)**. **Each project was production-tested and aimed at squeezing the most performance from their hardware.

FlashMLA is their optimized Attention CUDA kernel. DeepGEMM provides an FP8-optimized matrix multiplication library that outperforms many vendor kernels on both dense and sparse operations DeepEP is their highly-tuned communication library for Mixture-of-Experts models. And 3FS is their high-performance distributed filesystem reminding us that every layer needs to be optimized - including the filesystem - to get the most performance out of our AI system.

By open-sourcing these [projects](https://github.com/deepseek-ai/open-infra-index/blob/main/README.md#:~:text=%E2%9C%85%20DualPipe%20,communication%20overlap%20in%20V3%2FR1%20training) on Github, DeepSeek not only demonstrated the credibility of their claims by allowing others to reproduce their results, but also contributed back to the community. It allows others to benchmark, reproduce, and learn from their methods whether it’s overlapping communication with DeepEP/DualPipe pipeline parallelism or saturating SSD and RDMA bandwidth with 3FS

Experimental transparency and reproducibility are critical in moving the field of AI performance engineering forward. It’s easy to fall into the trap of anecdotal “vibe” optimizations (“we did X and things felt faster”). Instead, I’m advocating for a rigorous, scientific approach that develops hypotheses, measures the results with reproducible benchmarks, adjusts to improve the results, reruns the benchmarks, and shares all of the results at every step.

Open efforts like DeepSeek’s [Open-Infra Index](https://github.com/deepseek-ai/open-infra-index) provide valuable baselines and tools. They catalog real-world performance data on various AI hardware setups and encourage apples-to-apples comparisons. We’ll leverage some of these open benchmarks to illustrate points in later chapters. For instance, when discussing GPU kernel optimizations, we will reference DeepSeek’s published profiles showing how their custom kernels achieved near-peak memory bandwidth utilization on NVIDIA GPUs

# Towards 100-Trillion-Parameter Models

100 trillion parameter models is an aspirational milestone for AI. 100 trillion is roughly the [number of synaptic connections](http://pmc.ncbi.nlm.nih.gov/) in the human brain’s neocortex Achieving a model of this size is theoretically possible, but it demands an extraordinary amount of resources - and money. Scaling to 100-trillion-parameter models by brute force would be impractical for all but the absolute wealthiest organizations.

A naive back-of-the-envelope calculation suggests that training a dense 100-trillion-parameter model might require on the order of 10^29 floating-point operations (FLOPs). Even with an exascale computer, executing 10^29 FLOPs would take thousands of GPU-years if done naively. In practical terms, if we used a state-of-the-art AI supercomputer delivering ~1.4 exaFLOPS (10^18 FLOPs) of 8-bit compute performance, a single training run could span on the order of 3,000 years. Clearly, new approaches are needed to make 100-trillion-parameter training feasible.

###### Tip

While the optimizations discussed in this book can be applied to smaller models and cluster sizes, I will continue to revisit the 100-trillion-parameter model to enforce the idea that we can’t just throw hardware at the scaling problem.

Such explosive growth in training cost is driving a search for new AI systems and software engineering techniques to increase performance, reduce cost, and make extreme-scale AI feasible with limited compute resources, power constraints, and money. Researchers are always exploring novel techniques to reduce the effective compute requirements.

One prominent idea is to use sparsity and, specifically, MoE models. Sparse models like MoE’s are in contrast to traditional dense models like the common GPT-series large-language models (LLMs) made popular by OpenAI. In fact, it’s rumored that OpenAI’s proprietary GPT-series and O-series reasoning models are multi-trillion-parameter models based on the MoE architecture.

Sparse models like MoE’s only activate parts of the model for each input token. By routing each input token through only a subset of its many internal “experts,” the FLOPs per token stays roughly constant even as total parameters grow Such sparse models prove that scaling to multi-trillion–parameter models is done without an equivalent explosion in computation cost. Additionally, since these models use less active parameters during inference, request-response latencies are typically much lower for MoE models compared to their dense equivalents. These are crucial insights toward training and serving 100-trillion-parameter-scale models.

DeepSeek-R1 is a great example of MoE efficiency. Despite having a massive 671 billion parameters in total, only 37 billion parameters are activated per input token. This makes DeepSeek-R1 much more resource-efficient than a similarly-sized dense large-language model. Another example is Google’s [Switch Transformer](https://arxiv.org/pdf/2101.03961) MoE from 2022. This 1.6-trillion-parameter MoE model achieved the same accuracy as a dense model with only a fraction of the computation. It was trained 7× faster than a comparable dense approach

In addition to massive compute requirements, memory is also a major bottleneck. For example, a 100-trillion-parameter model would require approximately 200 TB of GPU memory to load the model if each parameter is stored as in 16-bit (2-byte) precision. This is 3 orders of magnitude (1000x) compared to the 288 GB of GPU RAM on a single NVIDIA Blackwell GPU. So to just load the 100 trillion model weights would require close to 700 Blackwell GPUs - and that’s without performing any calculations with the model weights, accepting any inference request data, etc. If a typical GPU server has 8 GPUs, this would require approximately 100 GPU servers just to load the model!

Additionally, loading training data also becomes extremely difficult since feeding such a model with data fast enough to keep all of those GPUs busy is non-trivial. In particular, communication overhead between the GPUs grows significantly as the 100-trillion parameter model is partitioned across 700 GPUs. Training a single model could consume millions of GPU-hours and megawatt-hours of energy. This is an enormous amount of cost - and energy consumption - to scale out large enough to train and serve a 100-trillion parameter model.

The era of 100-trillion-parameter AI will force us to completely rethink system design to make training and deployment practical at this scale. Hardware, algorithms, and software all need to co-evolve to meet this new frontier.

# NVIDIA’s “AI Supercomputer in a Rack”

To meet the challenges of ultra-scale computing, NVIDIA has built a new class of AI supercomputers specifically aimed at trillion-parameter-scale workloads. One example is the NVIDIA GB200 NVL72 - an AI supercomputer condensed into a single data center rack. NVIDIA refers to the NVL72 as an “AI supercomputer in a rack” – and for good reason.

At a high level, the GB200 NVL72 rack integrates 36 Grace-Blackwell superchips with a specialized networking fabric called NVLink. Each Grace-Blackwell superchip is a combination of 1 ARM-based NVIDIA Grace CPU with 2 NVIDIA Blackwell GPUs for a total of 72 Blackwell GPUs (hence, the “NVL72” in the name!).

This entire NVL72 rack behaves like one giant accelerator to the user. More details are provided on the compute, memory, and interconnect hardware details of this supercomputer in [Chapter 2](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch02.html#ch02_ai_system_hardware_overview_1744914895538857). For now, let’s analyze the overall performance specifications of this AI supercomputer as a whole in the context of modern generative AI models.

Each NVL72 rack delivers 1.44 exaFLOPS of AI compute in low-precision (4-bit) mode and provides 13.5 TB of ultra-fast high-bandwidth memory (HBM) spread across the 72 GPUs. In simpler terms, it’s a self-contained 120 kW AI training and inference AI supercomputer that can train and serve trillion-parameter models - as well as fit into a single rack in your data center. And by combining these racks together to form ultra-scale clusters, you can support massive multi-trillion parameter models. Even better, you can provision these racks and rack-clusters with a few clicks (and quite a few dollars!) using your favorite cloud provider including AWS, GCP, Azure, CoreWeave, and Lambda Labs.

###### Tip

While this book focuses heavily on the Grace-Blackwell generation of NVIDIA chips, the optimization principles discussed are derived from many previous generations of NVIDIA hardware. And these optimizations will continue to apply and evolve to many future NVIDIA chip generations to come including Vera-Rubin (2026), Feynman (2028), and beyond.

Throughout the book, you will learn how each generation’s innovation in compute, memory, networking, and storage will contribute to more AI scaling in the form of ultra-scale clusters, multi-trillion-parameter models, high throughput training jobs, and extreme-low-latency model inference servers. These innovations are fueled by hardware-aware algorithms that enforce the principles of mechanical sympathy and hardware-software co-design discussed in the next section.

# Mechanical Sympathy: Hardware-Software Co-Design

*Mechanical sympathy *is a term originally coined by racer/engineer Martin Thompson (drawing an analogy to racecar drivers who intimately understand their car’s mechanics). In computing, it refers to writing software that is deeply aware of the hardware it runs on. In the AI context, it means co-designing algorithms hand-in-hand with hardware capabilities to maximize performance.

Real-world experience has shown that even minor tweaks in GPU kernels or memory access patterns can yield outsized gains. A classic example is FlashAttention, a novel algorithm that reimplements the Transformer attention mechanism in a hardware-aware way.

FlashAttention “tiles” GPU computations which minimizes the number of reads and writes issued to the GPU’s memory. FlashAttention dramatically reduces memory movement and speeds up attention computation. Replacing the default Transformer attention mechanism/algorithm with FlashAttention yields a 2–4× speedup in training and inference for long sequences, while also reducing the overall memory footprint Such a change eliminates what used to be a major bottleneck (Attention) down to a fraction of overall runtime. FlashAttention became the default in many libraries almost overnight because it let models handle longer sequences faster and more cheaply. Since FlashAttention, many new Attention algorithms have emerged including DeepSeek’s Multi-Headed Latent Attention (MLA).

DeepSeek’s MLA algorithm - implemented as an NVIDIA GPU kernel and open-sourced in 2025 - is another example of hardware-software co-design, or mechanical sympathy. Similar to FlashAttention, MLA restructures the Attention computations to better utilize NVIDIA’s memory hierarchy and dedicated GPU “tensor cores.” These algorithmic optimizations adapted MLA to the strengths of the China-constrained NVIDIA GPUs and achieved higher throughput at a fraction of the cost using FlashAttention.

This entire book is effectively a study in mechanical sympathy. We will see countless cases where new hardware features - or hardware constraints as in the case of DeepSeek - inspire novel new software and algorithmic techniques. Conversely, we’ll see where new software algorithms encourage new hardware innovations

For instance, the rise of Transformer models and reduced-precision quantization (e.g. FP8/FP4) led NVIDIA to add specialized hardware like the Transformer Engine and dedicated reduced-precision Tensor Cores for faster matrix-math computation units. These hardware innovations, in turn, enable researchers to explore novel numeric optimizers and neural-network architectures. This, then, pushes hardware designers even further which then unlocks even newer algorithms, etc. It’s a virtuous cycle!

Another example is NVIDIA’s Blackwell** **GPU which includes an improved exponential computation unit specifically designed to accelerate the softmax operation in the Transformer’s Attention algorithm. The softmax had become a bottleneck on previous GPUs even though it’s critical to the Attention mechanism.

This tight interplay – GPUs and AI algorithms co-evolving – is the heart of mechanical sympathy in AI. These co-design innovations can only happen with close collaboration between the hardware companies (e.g. NVIDIA and ARM), AI research labs (e.g. OpenAI and Anthropic), and AI Systems Performance Engineers (e.g. us!)

# Measuring “Goodput” Useful Throughput

When operating clusters of hundreds, thousands, or millions of GPUs, it’s important to understand how much of the theoretical hardware capability is actually performing useful work. Traditional throughput metrics like FLOPs/s and device utilization are misleadingly high as much of the time is likely spent on stalled communication, idling computation, or failed job restarts. This is where the concept of “goodput” comes in - as described by Meta in a [paper](https://arxiv.org/pdf/2410.21680) titled, “Revisiting Reliability in Large-Scale Machine Learning Research Clusters”.

###### Tip

NVIDIA calls the theoretical hardware maximum the “speed of light” as you may have seen in NVIDIA blogs, documentation, webinars, and conference talks.

In simple terms, goodput measures useful work completed per unit time, discounting everything that doesn’t directly contribute to model training or inference. It’s effectively the end-to-end efficiency of the system from the perspective of productive training. Goodput can be normalized by the cluster’s maximum possible throughput to yield a 0–1 efficiency ratio.

Meta’s AI infrastructure team highlighted the importance of goodput by revealing that their large-scale GPU clusters measured only about 25–30% of peak compute throughput as useful training work, or goodput. In other words, while the cluster appeared to be 100% utilized, 70-75% of the compute was lost due to overheads like communication delays, suboptimal parallelization, waiting for data, or recovering from failures. Additionally, Meta’s [analysis](https://arxiv.org/pdf/2410.21680) showed that, at scale, issues like job preemptions, network hotspots, and unrecoverable faults were major contributors to lost goodput

For example, imagine a training job that could theoretically process 1,000 samples/second on ideal hardware, but due to poor input pipeline and synchronization, it only achieves 300 samples/second of actual training throughput. We’d say that the job is running at 30% goodput. The remaining 70% capacity is essentially wasted.

Identifying these gaps and closing them is a core part of our work. For instance, if GPUs are waiting on data loading from storage, we might introduce caching or async prefetch. If they’re idling during the gradient synchronization step of our model training process, we likely want to overlap the GPU computation (e.g. calculating the gradients) with the communication between GPUs (e.g. synchronizing the gradients). Our goal is to turn wasted, inefficient cycles into useful work.

This gap between theoretical and realized performance is the value proposition of the AI Systems Performance Engineer role. Our mission is to drive that goodput number as high as possible – ideally increasing it closer to 100% – by attacking inefficiencies and reducing cost at every level of the stack including hardware, software, and algorithms.

###### Tip

This cost savings is why AI Systems Performance Engineers earn top dollar in the industry today. We pay for ourselves many times over - especially at scale!

By focusing on goodput, we are optimizing what truly matters - the amount of useful training done per dollar of cost and per joule of power. Goodput is the ultimate metric of success – more so than raw FLOPs or device utilization – because it encapsulates how well hardware, software, and algorithms are harmonized toward the end goal of training AI models faster and cheaper.

Improving goodput requires a deep understanding of the interactions between the hardware (e.g. CPUs, GPUs, network topologies, memory hierarchies, storage layouts), software (e.g. operating system configurations, paged memory, I/O utilization) and algorithms (e.g. Transformer architecture variants, Attention mechanism alternatives, different caching and batching strategies).

This broad and deep understanding of multiple disciplines - including hardware, software, and algorithms - is why AI Systems Performance Engineers are so scarce today. This is also why I’m writing this book! Next is the roadmap and methodology that maps out the rest of this book.

# Book Roadmap and Methodology

How will we approach the optimization of 100-trillion-parameter AI systems? This book is organized to take you from the hardware fundamentals up through the software stack and algorithmic techniques - with an emphasis on hands-on analysis at each level. Here is a breakdown of the rest of the book.

## Part I: AI System Hardware, OS, CUDA, and PyTorch Optimizations

We begin with an understanding of the hardware foundation. Understanding the hardware capabilities and limitations is crucial before we can discuss software and algorithm optimizations.

[Chapter 2](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch02.html#ch02_ai_system_hardware_overview_1744914895538857) provides an in-depth look at NVIDIA AI System hardware including the GB200 NVL72 “AI supercomputer in a rack” which combines Grace-Blackwell superchip design with the NVLink network to create performance/power characteristics of an AI supercomputer.

[Chapter 3](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch03.html#ch03_os_docker_and_kubernetes_tuning_for_gpu_based_en_1744914896592538) will then cover OS-level optimizations for GPU-based AI systems. These optimizations include CPU and memory pinning. [Chapter 4](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch04.html#ch04_distributed_communication_and_i_o_optimizations_1744914897560204) discusses Docker-container and Kubernetes-orchestration considerations as well as network I/O and storage configurations for GPU environments.

Chapters 5 and 6 discuss NVIDIA CUDA programming fundamentals and CUDA-kernel optimizations that are essential for developing novel hardware-aware algorithms. Such popular algorithms include FlashAttention and DeepSeek’s MLA. These algorithms target the resource-intensive Attention mechanism of the Transformer architecture which dominates today’s generative AI workloads.

Chapter 7 discusses PyTorch-specific optimizations including the PyTorch compiler and OpenAI’s Python-based Triton compiler (and language). These compilers lower the barrier for developing novel CUDA kernels as they don’t require a deep understanding of C++ typically required to develop CUDA kernels.

## Part II: Scalable, Distributed Model Training And Inference Strategies

With NVIDIA hardware and CUDA software context in hand, we’ll dive into distributed communication optimizations including training and serving ultra-large models efficiently. We’ll examine strategies to minimize communication such as overlapping computation with communication - a pattern that applies to many layers of the AI system stack.

Chapter 8 discusses distributed parallelization techniques for model training including data parallelism, tensor parallelism, pipeline parallelism, sequence parallelism, and mixture-of-experts. We will show how multi-trillion-parameter models are split and trained across many GPUs efficiently. And we will discuss techniques for memory optimization during ultra-scale model training including gradient checkpointing, sharding optimizer states, and offloading to larger CPU memory. These techniques are vital when model sizes exceed the physical GPU hardware limits.

Chapter 9 focuses on software and algorithmic innovations for high-throughput, low-latency model inference. We discuss the most popular model-serving engines including vLLM, NVIDIA TensorRT-LLM, and NVIDIA Dynamo. We’ll also look at leveraging the Grace CPU in the NVL72 for preprocessing, co-running smaller “draft” models for high-performance inference algorithms such as speculative decoding, and efficient request routing and batching to maximize overall throughput of the inference system. We will also explore model compression and acceleration techniques such as 4-bit quantization, knowledge distillation to teach smaller “student” models from wiser “teacher” models, sparsity and pruning, and using specialized TensorRT kernels.

## Part III: Ultra-Scale Case Studies, Emerging Trends, and Optimization Cheat Sheet

In the final part of the book, we will present various performance optimization case studies and emerging trends. Additionally, we present an optimization “Cheat Sheet” to summarize the high-level performance and cost optimization tips and tricks covered in this book.

[Chapter 5](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch05.html#ch10_ai_system_optimization_case_studies_1744914898472877) provides case studies for optimizing massive AI clusters at scale. The case studies include training and serving multi-billion and multi-trillion parameter models efficiently.

[Chapter 8](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch08.html#ch11_future_trends_in_ultra_scale_ai_systems_performanc_1744914899766060) covers emerging trends in this broad field of AI systems performance engineering. Such trends include training-efficiency improvements, optical interconnects for multi-rack scaling, better algorithms for sparse models, among others. This helps to paint a picture of where 100-trillion-parameter-scale AI systems are headed.

[Chapter 9](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch09.html#ch12_ai_systems_performance_checklist_175_items_1744914900647754) presents a checklist of common performance-optimization and cost-saving tips and tricks to apply to your own AI system. This is a summary of actionable efficiency gains discussed in this book.

The book implements a hands-on and empirical methodology to apply performance optimizations. We will frequently analyze actual runs, case studies, benchmark results, and profiling data to understand bottlenecks and verify improvements. By the end of the book, you should grasp the principles of optimizing ultra-large AI systems - as well as gain some practical experience with tools to apply those optimizations on ultra-scale, mutii-GPU, multi-node, and multi-rack AI systems like the NVIDIA GB200 NVL72 AI supercomputer in a rack - or similar AI systems now and in the future.

# Key Takeaways

The following qualities collectively define the role of the AI Systems Performance Engineer, whose expertise in merging deep technical knowledge with strategic, profile-driven optimizations transforms raw hardware into cost-effective, high-performance AI solutions.

Measure Goodput.Look beyond raw FLOPs or utilization. Instead, measure how much of the compute is actually doing useful work (e.g. forward/backprop) vs. waiting on data and other overhead. Strive to improve useful work.

Optimization Beats Brute Force.More hardware isn’t a silver bullet. Clever software and system optimizations can bridge the gap when hardware is limited, enabling results that would otherwise require far more expensive infrastructure We saw this with DeepSeek’s achievement – skillful engineering outperformed brute-force spending.

Strive for an Order-of-Magnitude Impact.At scale, even a small-percentage efficiency gain can save millions of dollars. Conversely, inefficiencies such as redundant computations or poor data pipelines can silently increase costs.

Use a Profile-Driven Approach.Use data and profiling tools to guide optimizations. Use profilers to identify the true bottlenecks – whether it’s compute utilization, memory bandwidth, memory latency, cache misses, or communication/network delays Then apply targeted optimizations for that bottleneck

Maintain a Holistic View.Improving AI systems performance spans hardware including the GPU, CPU, memory, and network - as well as software such as algorithms and libraries. A weakness in any layer can bottleneck the whole. The best performance engineers consider hardware-software co-design: sometimes algorithm changes can alleviate hardware limits, and sometimes new hardware features enable new algorithms.

Stay Informed on the Latest Hardware.Modern AI hardware is evolving rapidly. New capabilities such as unified CPU-GPU memory, faster interconnects, or novel numerical-precision formats can change the optimal strategies. A good engineer keeps an eye on these and updates their mental models accordingly to eliminate bottlenecks quickly.

# Conclusion

This introductory analysis underscores that optimizations are not optional at large scale - they are absolutely necessary**. **It is the difference between a system that works and one that is utterly impractical Traditional approaches, whether in hardware or algorithms, break down at this scale. To push forward, we need both advanced hardware and smart software techniques.

It’s clear that AI models are pushing physical resource limits. Hardware is racing to keep up with new model architectures and algorithms. And performance engineers are the ones in the driver’s seat to ensure that all this expensive machinery is actually delivering results.

We have demonstrated that the role of an AI Systems Performance Engineering is gaining more and more importance. Simply throwing money and hardware at the problem is not enough. We need to co-optimize everything – model architectures, algorithms, hardware, and system design – to push toward the next leaps in AI capability.

As AI Systems Performance Engineers, our job is multi-disciplinary, complex, and dynamic. We will dive into GPU profiling one day, network topology the next day, and perhaps algorithmic complexity the following day. This is a role for a “full-stack” performance geek who loves to squeeze out every drop of available performance from both hardware and software.

In essence, an AI Systems Performance Engineer’s mantra is “mechanical sympathy”. We deeply understand the machinery - both hardware and software - so that we can tailor efficient solutions that exploit the entire stack’s performance capabilities to the fullest.

The challenge on the horizon is monumental. For instance, consider the lofty goal of training and serving a 100-trillion-parameter model. A naïve back-of-the-envelope calculation shows that training such a model would require on the order of 10^29 FLOPs. Even running on an exascale supercomputer at 10^18 FLOPs/sec, you would need to train for several-thousand GPU-years just for a single pass through an average-sized language-based dataset.

In the coming chapters, we will demonstrate how to break down the components of an AI system from processors to memory to interconnects to software frameworks - and learn how to optimize each component in a principled way. We’ll study concrete case studies where making small changes brings about huge performance and cost improvements. Doing so, we will help create a mental model for reasoning about performance optimization along multiple dimensions.

By the end of this journey, you as a reader and practitioner will be equipped with knowledge of today’s best practices as well as an engineering mindset to tackle tomorrow’s challenges You will have an arsenal of techniques to push AI systems to their limits - now and in the future. For AI systems performance engineers, the mandate is clear. We must learn from these innovations and be ready to apply aggressive optimizations at every level of the stack.

Now, with the context established, let’s dive into the hardware components of modern AI systems including the CPUs, GPUs, memory technologies, network fabrics, and storage mechanisms. By studying the components that underpin contemporary AI supercomputers, you will learn the fundamentals that provide the foundation of subsequent deep dives into optimization techniques in later chapters.
