# Chapter 5. AI System Optimization Case Studies

# A Note for Early Release Readers

With Early Release ebooks, you get books in their earliest form—the author’s raw and unedited content as they write—so you can take advantage of these technologies long before the official release of these titles.

This will be the 5th chapter of the final book.

If you’d like to be actively involved in reviewing and commenting on this draft, please reach out to the editor at *arufino@oreilly.com*.

This chapter brings together a range of case studies that show how combining advanced hardware with smart software techniques improves the performance and cost efficiency of large language models (LLMs). The studies illustrate that by embracing new numerical precision modes on modern GPUs such as using 8-bit floating point on Hopper or 4-bit on Blackwell, engineers can significantly boost the speed of training without losing accuracy.

They also reveal that thoughtful software designs can overcome inherent hardware limits. One example is the development of algorithms that overlap computation with data transfers so that even very large models can be trained on systems with lower memory bandwidth. Another major insight is that systems that unite powerful CPUs and GPUs on the same chip - linking them with very high speed interconnects - reduce delays in moving data and improve throughput considerably.

The case studies further show that intelligent scheduling frameworks and open source tools can double the effective performance on existing hardware by optimizing how work is distributed across devices. They also demonstrate that artificial intelligence itself can assist in fine tuning low level GPU code to create kernels that run faster than those produced by manual efforts. In a broader context, these examples reveal that algorithmic innovations, even in core operations such as matrix multiplication, can yield performance gains similar to those achieved by acquiring new hardware.

Together these learnings suggest that successful improvements in model training and inference depend on a close coordination between hardware capabilities and software techniques. This coordinated approach reduces training time and operating cost - as well as enables the efficient deployment of larger models on smaller systems, paving the way for future advances in artificial intelligence.

# OpenAI’s Journey to Train GPT 4.5 with New Hardware at Ultra-Scale

This case study follows OpenAI’s [journey](https://www.youtube.com/watch?v=6nJZopACRuQ) building GPT 4.5, highlighting the challenges, processes, and lessons learned along the way. The project began nearly two years before the training run, with teams from machine learning and infrastructure working together on what was expected to be a 10× improvement over GPT 4. Early on, the team ran de-risking experiments on a new, much larger compute cluster built for extreme-scale training. Their collaborative planning set the stage for tackling issues as they arose during the actual run.

As the training progressed, the teams continuously made adjustments and monitored resource use on hardware they were still learning to master. In the early stages, failure rates were high due to unforeseen hardware faults, network issues, and software bugs in simple, well-tested functions like `sum()` which, when combined with custom code on a rare code path, could cause catastrophic errors in such a massive system. Fixing these issues became a shared effort that blurred the lines between ML research and systems engineering, highlighting that even small details matter at scale.

A key takeaway was that scaling these training runs isn’t only about adding more compute. It requires a delicate balance between long-term planning and rapid problem solving, ensuring that every fix improves both data efficiency and model intelligence. The teams discovered that through co-designing, choices made for model design (e.g. scaling laws and pre-training objectives), had a direct impact on infrastructure needs (e.g. multi-cluster orchestration and network reliability) and vice-versa. Even with careful upfront planning, some degree of unpredictability remained, and the process demanded persistent monitoring and agile, cross-team collaboration.

Ultimately, the GPT 4.5 training run became a blueprint for hyper-scale training, where incremental improvements in code design, error resolution, and system orchestration coalesced into a model that met its ambitious performance goals and provided a roadmap for the next generation of AI models. This case study reveals that real progress is measured by continually learning from and overcoming unforeseen challenges. Through persistence, teamwork, and continuous iteration, the researchers and engineers transformed every hurdle into an opportunity to refine their processes. This proved that breakthroughs in AI systems performance are achieved by powerful hardware, intelligent, and adaptive engineering practices.

# DeepSeek Scales to 671-Billion Parameter Model Despite Hardware Constraints

Sometimes innovation is born from necessity. In 2024, a Chinese organization, DeepSeek, found itself constrained to using only NVIDIA’s H800 GPUs due to U.S. export restrictions. The H800 is a bandwidth-limited variant of the Hopper GPU, meaning it has a significantly reduced memory bandwidth and lower-speed NVLink interconnect compared to the H100. In practice, while the H100 offers close to 3 TB/s of memory bandwidth along with enhanced inter-GPU communication, the H800’s limited throughput meant that data transfers were slower, which threatened to bottleneck distributed training jobs.

DeepSeek set out to train a massive 671-billion-parameter mixture-of-experts (MoE) language model, called DeepSeek-V3, in this heavily constrained environment. This model uses 64 experts - each a smaller 37B-parameter network. With this architecture, only a fraction of the model is activated at any given time, which helps manage computational loads even with the compact H800 setup.

To work around the environment limitations, DeepSeek implemented a novel DualPipe parallelism algorithm that carefully overlapped computation and communication to mask the H800’s inherent weaknesses. By designing custom CUDA kernels to bypass some of the default NCCL communication collectives, DeepSeek was able to coordinate data transfers in tandem with ongoing computations, thus keeping the GPUs efficiently utilized despite their reduced interconnect bandwidth.

This innovative engineering paid off as DeepSeek-V3 was trained to completion at an estimated cost of only $5.6M in GPU time. This is a fraction of what many had assumed was necessary for a model of this scale using a more capable cluster.

Benchmark evaluations have shown that DeepSeek-V3’s performance matches or even exceeds that of OpenAI’s GPT-4 on several key metrics, including natural language understanding, reading comprehension, and reasoning tasks. These comparisons were based on standardized tests used across the industry, indicating that an open MoE model can rival the best closed models despite using less-capable hardware.

Building on the DeepSeek-V3 model, the team then created DeepSeek-R1—its specialized reasoning model built similarly to OpenAI’s O1 and O3 series. Instead of relying heavily on costly human feedback loops for fine-tuning, DeepSeek pioneered a “cold start” strategy that used minimal supervised data, instead emphasizing reinforcement learning techniques to embed chain-of-thought reasoning directly into R1. This approach reduced training cost and time and underscored that smart software and algorithm design can overcome hardware bottlenecks.

The lessons learned are that large, sparsely activated MoE models can be effectively scaled even on limited memory and compute budgets. Novel training schedules and low-level communication/computation overlap optimizations can overcome hardware limitations, as demonstrated by the enormous ROI of DeepSeek’s efforts.

The ROI is clear as DeepSeek’s unconventional approach brought about huge efficiencies and created a series of powerful models at much lower training cost and time. By extracting every ounce of performance from the H800 GPU - even under the constraints of reduced communication bandwidth - the team delivered GPT-4-level model performance for millions of dollars less. Additionally, DeepSeek saved even more money by not requiring as much human-labeled data during R1’s fine-tuning stage for reasoning.

In short, smart software and algorithm design overcame brute-force hardware limitations. This enabled DeepSeek to develop large-scale AI models on a tight cost and hardware budget.

# MobileEye Improves GPU Performance Using FP8 Precision with PyTorch

When the NVIDIA H100 Hopper GPU was released, the AI engineering team at MobileEye [upgraded](https://medium.com/data-science/pytorch-native-fp8-fedc06f1c9f7#:~:text=As%20the%20results%20demonstrate%2C%20the,and%20size%20of%20the%20model) their PyTorch training pipeline to leverage Hopper’s support for 8-bit floating point (FP8) math. By using Hopper new Tensor Cores and Transformer Engine for mixed FP16/FP8 precision, they boosted matrix operation performance without losing model accuracy. After manually trying various batch sizes and precisions, MobileEye chose to use PyTorch’s `torch.compile` for aggressive kernel fusion at FP8 precision on the H100 which provided a 47% speedup relative to their bfloat16 baseline as shown in [Figure 5-1](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch05.html#ch10_figure_1_1744914898457598).

![A table with numbers and letters  AI-generated content may be incorrect.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9798341627772/files/assets/ch10_figure_1_1744914898457598.png)

###### Figure 5-1. 47% improvement in average step time using PyTorch compile for kernel fusion at FP8 precision (Source: [PyTorch Native FP8 Data Types. Accelerating PyTorch Training Workloads… | by Chaim Rand | TDS Archive | Medium](https://medium.com/data-science/pytorch-native-fp8-fedc06f1c9f7#:~:text=As%20the%20results%20demonstrate%2C%20the,and%20size%20of%20the%20model)).

The lesson learned was that achieving software speedups on new GPU generations requires careful hardware-software coordination to adjust to newer hardware features and precisions such as Transformer Engine, Tensor Cores, and FP8 precision. In this case, the team at MobileEye used the PyTorch compiler to automatically optimize their PyTorch code for the new FP8 precision supported by the Hopper GPU hardware.

The return on investment (ROI) was clear. With only a few weeks of engineering effort needed to try different combinations and eventually use the PyTorch compiler, the team nearly doubled their training throughput and reduced their training time by half for their Vision Transformer (ViT) model.

This case underscores that embracing new precision formats and compiler optimizations can unlock the performance promised by cutting-edge GPUs. This yields faster results and takes advantage of the full capabilities of the hardware.

# Boost Performance with Open Source NVIDIA Dynamo Inference Server

Pure hardware speed, alone, isn’t the only path to performance. Intelligent software-level optimizations can create force-multiplying efficiencies across an AI fleet of compute nodes and racks. NVIDIA’s open-source [Dynamo](https://github.com/ai-dynamo/) inference framework proves this point.

NVIDIA’s Dynamo inference server is a [low-latency](https://nvidianews.nvidia.com/news/nvidia-dynamo-open-source-library-accelerates-and-scales-ai-reasoning-models#:~:text=NVIDIA%20Dynamo%20is%20fully%20open,Perplexity%2C%20Together%20AI%20and%20VAST) distributed serving platform for LLMs. It sits on top of engines such as TensorRT-LLM, vLLM, SGLang, and PyTorch - and efficiently coordinates work across many GPUs and compute nodes.

In one internal [test](https://nvidianews.nvidia.com/news/nvidia-dynamo-open-source-library-accelerates-and-scales-ai-reasoning-models#:~:text=NVIDIA%20Dynamo%20is%20fully%20open,Perplexity%2C%20Together%20AI%20and%20VAST), a team at NVIDIA deployed the Llama language model on Hopper H100 GPUs using Dynamo and immediately saw a 2x throughput increase compared to their custom request-scheduling code. Doubling throughput performance with Dynamo means that an AI service could respond to user queries with the same speed using only half the hardware. This directly translates to cost savings and additional headroom to scale the number of end users even higher.

With the same number of GPUs, Dynamo’s dynamic batching, GPU load balancing, and disaggregated inference serving allowed the system to handle twice as many tokens per second. Disaggregated inference serving separates the memory-intensive KV-Cache prefill phase from the compute-intensive token-generating decode phase.

Once the KV-Cache is populated across the cluster, Dynamo routes incoming requests to the GPU node that already contains the KV-Cache data needed for that specific request. This avoids redundant computations and keeps GPUs busy with useful work.

Moreover, Dynamo can seamlessly allocate different models and stages (prefill or decode) to different GPUs as request load increases and decreases. This ensures that no GPU sits idle while others are overloaded - even across multiple compute nodes and racks.

The lesson learned is that, with ultra-scale inference, the bottlenecks often lie in networking and coordination. Software like NVIDIA’s Dynamo inference framework can unlock performance gains on top of even the best hardware.

The ROI here of this experiment is that organizations can essentially get a free 2x performance by using open source NVIDIA Dynamo on their existing infrastructure. This case study shows a dramatic increase in throughput - and lower per-query and per-user cost - without buying new GPUs.

In summary, better algorithms for inference scheduling created direct business value. This makes serving large-scale LLMs more cost-efficient and achievable for organizations of all sizes - large and small.

# Efficient Inference with vLLM: High Throughput at Lower Cost

Another real-world challenge in serving LLMs is maximizing utilization of each GPU. A research team at Berkeley originally achieved this goal with their open-source library called vLLM, which, underwhelmingly, stands for “virtual large-language model”. vLLM rethinks how LLM inference servers perform batching and memory-management operations - especially for massive, memory-hungry LLMs and large request inputs.

Traditional model-inference serving engines often leave GPUs underutilized - and cause a massive amount of memory movement - as thousands of independent inference requests accumulate. In such cases, GPU cores can stall waiting for new tokens to be generated.

To address this, vLLM initially introduced two key innovations called PagedAttention and continuous batching. PagedAttention is a smart memory management scheme for paging the attention caches. Continuous batching refers to intelligently packing input requests together to balance overall latency and throughput of the inference system.

PagedAttention is analogous to operating system level memory paging, treating GPU memory as if it were virtual memory. This strategy dynamically reallocates idle portions of the key-value cache, ensuring that no memory is left unused between inference requests, ultimately enabling a more efficient batching of incoming requests and reducing latency.

Continuous batching refers to the method where incoming queries are automatically grouped together as they arrive. This allows the system to form a maximally-sized batch without relying on a predetermined time window. This on-the-fly grouping maximizes GPU efficiency and ensures that the inference process consistently achieves high throughput while keeping latency low.

The vLLM project is well-adopted and well-supported. It’s integrated into many application backends, and included in core cloud-based inference services. The project continues to evolve and benefits from many algorithmic and kernel optimizations - and even supports accelerators beyond just NVIDIA GPUs.

The lessons learned for performance engineers are to look beyond GPU FLOPs and consider how workload patterns affect efficiency. By reducing memory fragmentation and better-combining input requests, for example, vLLM squeezes out significantly more useful work, or goodput, from the same hardware.

The ROI of adopting vLLM is clear for any AI service with spiky or concurrent request loads. Higher throughput per dollar on the same hardware avoids expensive hardware upgrades. Importantly, NVIDIA recognized the value of such software-level optimizations with its release of the Dynamo serving framework. Dynamo natively supports vLLM as a backend. This allows organizations to combine vLLM’s algorithmic and GPU-level optimizations with the cluster-level routing and cache management optimizations of NVIDIA Dynamo.

This case study reminds us that open-source innovations can deliver huge performance leaps. vLLM can increase throughput out of the box without any additional configuration. This translates to lower operating costs, higher request capacities, and better user experiences for the same hardware and model deployment.

# DeepMind’s AlphaTensor: AI-Discovered Algorithms Boosting GPU Performance

Not all AI optimization happens at the code level. Sometimes, the optimizations go deeper into the realm of algorithms and math. A groundbreaking [example](https://deepmind.google/discover/blog/discovering-novel-algorithms-with-alphatensor/#:~:text=Algorithms%20in%20this%20rich%20space,flexibility%20in%20optimising%20arbitrary%20objectives) comes from DeepMind’s AlphaTensor project from 2022 in which AI was used to discover new general matrix multiply (GEMM) algorithms.

GEMMs are core operations that underpin almost all model training and inference workloads. Even a slight improvement in GEMM efficiency can have a huge impact across the entire AI field. AlphaTensor formalized the search for fast algorithms as a single-player game using reinforcement learning to explore many different possibilities.

The astonishing result was that it found formulas for multiplying matrices that proved better than any human-derived method in existence at the time. For instance, it rediscovered Strassen’s famous [sub-quadratic algorithm](https://en.wikipedia.org/wiki/Strassen_algorithm) for 2×2 matrices as shown in [Figure 5-2](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch05.html#ch10_figure_2_1744914898457640), but also improved it for larger matrix sizes.

![A screenshot of a computer game  AI-generated content may be incorrect.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9798341627772/files/assets/ch10_figure_2_1744914898457640.png)

###### Figure 5-2. Strassen’s sub-quadratic algorithm for multiplying 2x2 matrices. (Source: https://en.wikipedia.org/wiki/Strassen_algorithm)

But the real proof came when those algorithms were tested on actual hardware. AlphaTensor discovered a method specific to the NVIDIA Volta V100 GPU generation which multiplied large matrices 10–20% faster than the standard GPU library could at the time. A 10–20% speedup in GEMM performance is huge. It’s like gaining an extra 10–20% in free compute for every model’s forward and backward pass. Such gains typically come from a new hardware generation - or months of low-level CUDA tuning. Yet, in this case, the AI found a better way mathematically in a relatively-short amount of time.

The lesson learned is that there may still be untapped efficiency left to discover in fundamental algorithmic and mathematical operations that human engineers consider novel. The AI can sift through many thousands and millions of variations of algorithms that humans could never try in a reasonable amount of time. For performance engineers, AlphaTensor’s success suggests that algorithmic innovation is not over. In the future, an AI might hand us a new toolkit of faster algorithms for fundamental operations like convolutions, sorting, or Attention.

The ROI in this case is somewhat indirect but very impactful. By incorporating AlphaTensor’s matrix multiply algorithm into a GPU library, any large-scale training job or inference workload would see an instantaneous boost in speed. This could influence everything from graphics rendering to LLM performance to scientific computing. AlphaTensor demonstrated that a 15% speed improvement - over thousands of training iterations on hundreds of GPUs - translates to massive time and energy savings. It’s a return that pays back every time you run the code. Moreover, this speedup was achieved without additional hardware – only smarter software.

For the ultra-scale performance engineer, the takeaway is to remain open to AI-driven optimizations at all levels of the stack. Even the most fundamental, well-optimized operations like GEMMs might leave room for improvement. Letting an AI explore the optimization space - without human bias - can yield high dividends by slashing run-times across the board.

# NVIDIA’s AI-Assisted GPU Kernel Optimizations with DeepSeek-R1

Optimizing low-level GPU code has long been an art reserved for expert humans called “CUDA Ninjas”, but it’s been shown that AI is capable of performing these expert tasks. NVIDIA engineers [experimented](https://developer.nvidia.com/blog/automating-gpu-kernel-generation-with-deepseek-r1-and-inference-time-scaling/#:~:text=generates%20the%20GPU%20code%20,R1%20model) with the powerful DeepSeek-R1 reasoning model to see if it could generate a high-performance CUDA kernel for the complex Attention mechanism that rivaled high-performance, hand-tuned implementations.

Being a reasoning model, DeepSeek-R1 uses an “inference-time” scaling strategy in which, instead of performing one quick pass through the model before generating a response, it refines its output over a period of time - the longer it’s given, the better. Reasoning models like DeepSeek-R1 are fine-tuned to think longer and iterate on their answer. Much like a human who takes time to think through their answer before spitting out a response.

In this experiment, NVIDIA deployed R1 on an H100 and gave it 15 minutes to generate an optimized Attention kernel code. They inserted a verifier program into the generator loop so that each time R1 proposed a kernel, the verifier checked the correctness of the generated kernel code and measured the code’s efficiency. This feedback loop provided guidance for an improved prompt to use for the next kernel-code iteration. The loop continued until the code met strict criteria as shown in [Figure 5-3](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch05.html#ch10_figure_3_1744914898457667).

![A diagram of a process  AI-generated content may be incorrect.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9798341627772/files/assets/ch10_figure_3_1744914898457667.png)

###### Figure 5-3. Inference-time scaling with DeepSeek-R1 on the NVIDIA Hopper platform (Source: [Automating GPU Kernel Generation with DeepSeek-R1 and Inference Time Scaling | NVIDIA Technical Blog](https://developer.nvidia.com/blog/automating-gpu-kernel-generation-with-deepseek-r1-and-inference-time-scaling/#:~:text=DeepSeek,on%20the%20NVIDIA%20Hopper%20platform))

The following prompt was used:

```
Please write a GPU attention kernel to support relative position encodings. Implement the relative positional encoding on the fly within the kernel. The complete code should be returned, including the necessary modifications.

Use the following function to compute the relative positional encoding:

def relative_positional(score, b, h, q_idx, kv_idx):
    return score + (q_idx - kv_idx)
    
When implementing the kernel, keep in mind that a constant scaling factor 1.44269504 should be applied to the relative positional encoding due to qk_scale = sm_scale * 1.44269504. The PyTorch reference does not need to scale the relative positional encoding, but in the GPU kernel, use:

qk = qk * qk_scale + rel_pos * 1.44269504

Please provide the complete updated kernel code that incorporates these changes, ensuring that the relative positional encoding is applied efficiently within the kernel operations.
```

The outcome was remarkable. Not only did the AI produce a functionally-correct CUDA kernel for Attention, it also [achieved](https://developer.nvidia.com/blog/automating-gpu-kernel-generation-with-deepseek-r1-and-inference-time-scaling/#:~:text=Image%3A%20A%20bar%20chart%20showing,attention%20kernels%20with%20flex%20attention) a 1.1-2.1× speedup over the built-in PyTorch “FlexAttention” kernel optimized by NVIDIA. [Figure 5-4](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch05.html#ch10_figure_4_1744914898457695) shows the performance comparison between the generated kernel and PyTorch’s optimized Flex Attention across various Attention patterns including causal masks and long-document masks.

###### Figure 5-4. Performance of automatically generated and optimized Attention kernels compared to PyTorch’s Flex Attention (Source: [Automating GPU Kernel Generation with DeepSeek-R1 and Inference Time Scaling | NVIDIA Technical Blog](https://developer.nvidia.com/blog/automating-gpu-kernel-generation-with-deepseek-r1-and-inference-time-scaling/#:~:text=Image%3A%20A%20bar%20chart%20showing,attention%20kernels%20with%20flex%20attention))

![A graph of a graph with green and orange bars  AI-generated content may be incorrect.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9798341627772/files/assets/ch10_figure_4_1744914898457695.png)

###### Figure 5-4.

Even more impressively, the AI generated kernels that were verifiably accurate on 100% of basic test cases and 96% of complex cases using Stanford’s [KernelBench](https://scalingintelligence.stanford.edu/blogs/kernelbench/) suite. This essentially matches the reliability of a human engineer.

The lesson learned is that giving an LLM the proper tools to verify, critique, and refine its outputs can dramatically improve code quality. Intuitively, this workflow is equivalent to how a human engineer profiles, debugs, and improves their own code repeatedly. What started as a rough code draft generated by the model evolved into a production-quality kernel in just 15 minutes. This illustrates a powerful paradigm for AI-assisted performance tuning.

The ROI is game-changing as even NVIDIA’s top CUDA engineers might spend hours or days to hand-craft and test a new type of Attention kernel variant. With this AI-assisted optimization approach, an AI can generate a comparably-efficient, low-level CUDA kernel in a fraction of the time. This frees engineers to focus on higher-level AI system optimizations opportunities and edge cases that may be tricky for an AI to detect and fix.

While some human oversight was still needed, this experiment showed a viable path to reduce development costs for GPU-optimized software with significant runtime performance speedups. For AI systems performance engineers, this type of AI assistance hints that future workflows may involve partnering with AI co-pilots to rapidly co-design optimizations across hardware, software, and algorithms. The AI co-pilot is a force-multiplier for human productivity. Think of these co-pilots as pre-trained and fine-tuned AI interns capable of reasoning through complex problems using their vast knowledge of CUDA tips and tricks derived from existing code bases.

# Sakana.ai’s Agent: LLMs That Write 100× Faster GPU Kernels

In 2025, A company called Sakana.ai pushed the concept of AI-written GPU code even further by aiming to automate a broad range of kernel optimization tasks. They [developed](https://sakana.ai/ai-cuda-engineer/) an autonomous agent called The AI CUDA Engineer that takes standard PyTorch operations and converts them into highly optimized CUDA kernels. Under the hood, the AI CUDA Engineer uses LLMs along with evolutionary strategies to iteratively refine kernel code. This strategy creates better and better solutions over multiple iterations and evolutionary generations as shown in [Figure 5-5](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch05.html#ch10_figure_5_1744914898457718).

![A diagram of a process  AI-generated content may be incorrect.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9798341627772/files/assets/ch10_figure_5_1744914898457718.png)

###### Figure 5-5. High-Level Overview of The AI CUDA Engineer Agentic Framework (Source: [https://sakana.ai/ai-cuda-engineer/](https://sakana.ai/ai-cuda-engineer/))

The results reported by Sakana are striking. Their AI-generated kernels showed speedups ranging from 10× up to 100× versus the equivalent PyTorch operations. In some cases, the AI CUDA Engineer’s generated CUDA kernels were 5× faster than the best CUDA kernels already used in production libraries. Notably, the AI CUDA Engineer successfully translated 230 out of 250 targeted PyTorch ops, showing a highly-generalized approach.

The lessons learned are that a combination of LLMs for high-level code generation 0 and algorithmic optimizations for fine-tuning and testing different code variations - can uncover performance tricks that even experienced code ninjas might miss. For example, Sakana’s agent might experiment with unconventional thread block sizes or use shared memory in creative ways that aren’t obvious. This could yield big gains for certain operations.

Another example is a complicated sequence of tensor operations in PyTorch that normally would launch many small GPU kernels and suffer from devastating memory bottlenecks. Sakana’s AI CUDA Engineer agent could easily detect this and fuse the tensor operations together into a single kernel in a small amount of time - much quicker than fusing these together manually. These types of AI-generated enhancements can create orders-of-magnitude performance improvements in AI systems.

The ROI of such an AI-code assistant is enormous if properly embraced and integrated into a company’s development workflow. Instead of manually and laboriously optimizing each neural network layer or operation by hand, the AI CUDA Engineer can automatically produce an optimized kernel on the order of minutes or hours depending on the complexity and novelty of the implementation. This means faster time-to-market for new model architectures and improved inference/training speed - without hiring an army of rare CUDA experts.

In essence, Sakana demonstrated a path to scale expert-level AI performance engineering by using AI. Their small upfront investment in an AI agent yielded compounding returns as many kernels were optimized 10–100× with almost-no human effort.

# Predibase’s Reinforcement Learning Approach to Generating Optimized GPU Kernels

Another startup, Predibase, demonstrated automated GPU programming by taking a slightly different approach using reinforcement learning. They asked an even-bolder question: Is it possible to train a language model to be a full OpenAI Triton programmer using many examples of PyTorch code? Remember that OpenAI Triton is a Python-like GPU programming language (and compiler) that simplifies GPU programming. The task was to see if the AI could generate efficient Triton code that replaces PyTorch code - and runs much faster on GPUs.

In their [experiment](https://predibase.com/blog/teaching-ai-to-write-gpu-code-a-deep-dive-into-reinforcement-fine-tuning#:~:text=Can%20we%20teach%20a%20LLM,accurate%20and%20optimized%20Triton%2FCUDA%20kernels), Predibase used a cluster of H100 GPUs and fine-tuned a modestly-sized LLM using a bunch of PyTorch-to-Triton code samples that translated high-level PyTorch functions into efficient Triton kernels. However, because there wasn’t a large enough dataset of “PyTorch-to-Triton” examples available at the time to use for supervised fine-tuning (SFT), they created a reward function and used a method called Reinforcement Fine-Tuning (RFT) to guide the model to continuously generate better code using reinforcement learning.

With Predibase’s reinforcement-learning (RL) approach, the AI would first generate a candidate kernel. The system would then automatically compile and test the kernel for correctness and speed. The model received a positive reward if the kernel ran without errors, produced the right results, and ran faster than the baseline kernel.

Through many iterations of this RL-based trial-and-error approach, the model steadily improved. Within a few days of training using merely 13 example problems to start, the AI went from knowing nothing about Triton to producing correct, optimized Triton-based kernel code for various GPU operations. While Predibase hadn’t published specific speedup numbers at the time of this writing, they noted that the model learned to output working Triton kernels in as little as 1000 training steps. Additionally, the model continued to optimize the performance as training continued.

This outcome shows that an AI can optimize its own code by testing, observing feedback, and making adjustments. This is similar to how engineers iteratively refine their code. Reinforcement learning can align AI-generated code with real-world performance metrics by rewarding both correctness and speed. This prompts the AI to explore optimizations like using warp-level parallelism or minimizing global memory access to improve overall performance.

The lesson learned and ROI from Predibase’s demonstration is that this type of AI assistance is compelling because it automates performance optimization at the kernel-code level, potentially reducing the need for manual tuning. Instead of engineers manually creating custom kernels for new models, a trained AI assistant can generate multiple variants and select the best one. This shortens development cycles and allows engineers to focus on exploring new model architectures, for example, so that companies of all sizes can achieve cutting-edge, frontier model performance.

This approach also suggests a future where higher-level languages and frameworks, such as Triton and Python, may replace CUDA for GPU programming. Such methods lower the barrier to GPU programming and, in the long-term, could lead to an automated pipeline where an AI agent continuously writes and improves computational kernels, becoming an essential tool for performance engineers.

# NVIDIA Grace-Hopper (GH200) Superchip Performance Compared to Hopper (H100)

The NVIDIA GH200 Grace Hopper Superchip represents an impressive convergence of advanced hardware design and innovative software techniques that have redefined LLMl inference. This case study unfolds from two distinct experiments from [NVIDIA](https://developer.nvidia.com/blog/leading-mlperf-inference-v3-1-results-gh200-grace-hopper-superchip-debut) and [Baseten](https://lambda.ai/blog/partner-spotlight-testing-llama-3.3-70b-inference-performance-on-nvidia-gh200-with-baseten).

Remember that the GH200 superchip unifies a Hopper H100 GPU and an ARM based Grace CPU on a single module with a remarkable 900 GB per second NVLink C2C interconnect instead of a traditional PCIe Gen5 connection. This design offers nearly 7x the bandwidth of conventional PCIe - and dramatically reduces the data transfer delays between the CPU and the GPU.

The journey began in late 2023 with NVIDIA’s focus on the MLPerf inference benchmarks using the GPT-J model that contains 6 billion parameters and used for basic generative AI tasks. Engineers at NVIDIA [demonstrated](https://developer.nvidia.com/blog/leading-mlperf-inference-v3-1-results-gh200-grace-hopper-superchip-debut) that the tightly coupled design of the GH200 reduced CPU to GPU data transfer overhead from 22% to a mere 3% of total inference time. This improvement allowed the GPU to concentrate on computational work and resulted in a 17% boost in throughput per GPU compared to the performance of the H100 system paired with an Intel Xeon CPU over a PCIe link. This result emphasized that memory bandwidth and efficient interconnects can be just as important as raw GPU compute power when running complex inference workloads.

In another phase of the NVIDIA [experiment](https://developer.nvidia.com/blog/leading-mlperf-inference-v3-1-results-gh200-grace-hopper-superchip-debut), the emphasis shifted toward overcoming the high memory demands inherent in the Transformer model’s memory-hungry Attention mechanism. The NVIDIA team applied an innovative mixed precision approach. The strategy involved a combination of 8-bit and 16-bit precision using the Transformer Engine in Hopper. In this case, they used an 8-bit compressed version of GPT-J’s Attention KV-cache. This compression nearly doubled the effective cache capacity of the 96 GB HBM GPU RAM and allowed for much larger batch sizes during inference. At the same time, the Tensor Cores remained fully active. The outcome was that a single GH200 delivered the highest performance per accelerator in MLPerf tests at the time.

Another [experiment](https://lambda.ai/blog/partner-spotlight-testing-llama-3.3-70b-inference-performance-on-nvidia-gh200-with-baseten) conducted by Baseten in early 2025 explored the challenges of serving extremely LLMs that exceed the confines of the GPU’s HBM memory. They ran the tests with a 70-billion parameter Llama 3.3 model served using one GH200 superchip configured with 96 GB of HBM. The H100 based system had to offload roughly 75 GB of model data to the host CPU memory using the much slower PCIe interconnect. Whereas the GH200 system only needed to offload 60 GB to the CPU memory using its fast NVLink C2C connection.

The performance difference was remarkable. The GH200 achieved a generation rate of 4.33 tokens per second compared to 0.57 tokens per second on the H100 system. This improvement represented a roughly 7.6x increase in throughput and led to an 8x reduction in the cost per generated token. The efficiency gains were driven by a combination of a 21% higher memory bandwidth as well as the integrated CPU memory serving as an extension of the GPU memory without experiencing the typical bottlenecks associated with PCIe.

The final insight is the importance of choosing hardware that is well matched to the specific characteristics of the workload. Certain workloads that fit entirely into the H100’s 80 GB of HBM memory do not benefit significantly from the unified CPU and GPU design of the GH200. In these cases, only a modest performance improvement of around 2% was observed. In contrast, when workloads demanded larger memory footprints and extensive data exchange between the CPU and GPU the GH200 outperformed the H100.

This serves as a reminder that expensive hardware investments should be matched to workloads that can fully utilize the advanced memory and interconnect capabilities available in systems like the GH200. Organizations are encouraged to test their specific workloads in cloud instances provided by AWS, GCP, Azure, CoreWeave, or Lambda Labs before making any large capital investment. This way they can deploy the best configuration for their specific workload and use cases.

The case study brings together concepts that intertwine hardware innovation and software optimization in a manner that fundamentally changes the approach to LLM inference. By increasing memory throughput, optimizing data transfers, and supporting mixed-precision formats, the GH200 delivers significant improvements in throughput and cost efficiency. This demonstrated impressive technical advancements and provided clear guidance for organizations aiming to serve larger models on smaller clusters at lower operational costs.

# High-Speed Inference with the Grace-Blackwell NVL72 Rack System

NVIDIA’s Blackwell GPU architecture came with unprecedented inference speed for large models. In early MLPerf tests, servers packed with Blackwell-based GPUs shattered [records](https://developer.nvidia.com/blog/nvidia-blackwell-delivers-massive-performance-leaps-in-mlperf-inference-v5-0/#:~:text=Additionally%2C%20in%20this%20round%2C%20Blackwell,FP8%E2%80%93while%20meeting%20benchmark%20accuracy%20requirements). NVIDIA then combined its ARM-based Grace CPU with their Blackwell GPU to create the Grace-Blackwell superchip.

Next, NVIDIA connected 36 Grace-Blackwell superships (each with 1 Grace CPU and 2 Blackwell GPUs) into a single ultra-dense rack deployment called the GB200 NVL72. These superchips are linked by 5th-generation NVLink switches for fast data sharing. With this system, NVIDIA [achieved](https://developer.nvidia.com/blog/nvidia-blackwell-delivers-massive-performance-leaps-in-mlperf-inference-v5-0/#:~:text=Additionally%2C%20in%20this%20round%2C%20Blackwell,FP8%E2%80%93while%20meeting%20benchmark%20accuracy%20requirements) 3.4× higher throughput per GPU when running the 405-billion parameter Llama 3.1 model on the GB200 NVL72 compared to the previous-gen Hopper-based systems.

Blackwell’s improvements, like a second-generation Transformer Engine and new FP4 precision, were key. By leveraging FP4 data types for quantized inference, the Blackwell-based GB200 NVL72 system doubled math throughput per GPU relative to FP8 precision.

Crucially, accuracy stayed within target ranges for the benchmark, so this performance vs. precision trade-off was essentially neutral. At the system level, the gains compounded. The GB200 NVL72 rack delivered up to 30× more throughput on Llama 405 inference tasks vs. a similar Hopper-based cluster as shown in [Figure 5-6](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch05.html#ch10_figure_6_1744914898457752).

![A graph with green bars  AI-generated content may be incorrect.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9798341627772/files/assets/ch10_figure_6_1744914898457752.png)

###### Figure 5-6. NVIDIA’s Grace-Blackwell “GB200 NVL72” supercluster (dark green) delivered up to 30× higher LLM inference throughput than the previous generation (light green), thanks to 9× more GPUs and big per-GPU speedups (Source: [NVIDIA Blackwell Delivers Massive Performance Leaps in MLPerf Inference v5.0 | NVIDIA Technical Blog](https://developer.nvidia.com/blog/nvidia-blackwell-delivers-massive-performance-leaps-in-mlperf-inference-v5-0/)).

This was due to a number of factors including the per-GPU speedup, faster NVLink/NVSwitch interconnects, and the sheer scale of 72 GPUs working together in close proximity. At the time, the GB200 NVL72 set a new industry standard for latency and throughput at scale with “the 405” as Llama’s 405-billion parameter models are sometimes called.

###### Tip

Mark Zuckerberg, CEO of Meta, casually refers to the Llama 405-billion-parameter model as “The 405” in reference to how California residents [refer](https://www.pbssocal.org/shows/lost-la/the-5-the-101-the-405-why-southern-californians-love-saying-the-before-freeway-numbers) to their freeways. Specifically, [Californians](https://www.youtube.com/watch?v=dCer2e0t8r8) prepend “the” before the freeway number (e.g. “the 405” freeway.)

Additionally, it’s worth noting that even a smaller 8-GPU Blackwell server, called the DGX B200, showed 3.1× higher throughput on a Llama-70B chat model compared to a similar 8-GPU Hopper server. This is a testament to Blackwell’s architectural advantages - even at equal GPU count.

The lesson learned for AI systems performance engineers is that new hardware features like FP4 Tensor Cores - and increased NVLink bandwidth between GPUs - can yield order-of-magnitude gains when combined with larger degrees of model parallelism enabled by designs like the GB200 NVL72.

Upgrading from Hopper to Blackwell achieved immediate return-on-investment as Hopper-based GPU inference responses took 6 seconds vs. 2 seconds on a Blackwell GPU. As such, a cluster of Blackwell-based GPUs could handle many more users with the same hardware. Investing in the Grace-Blackwell platform yielded incremental improvements and a dramatic step-function increase in serving capability. This is a competitive edge for any AI provider dealing with ever-growing model sizes and user demand.

# Faster Experiments and Insights for Trillion-Parameter LLMs with Grace-Blackwell Clusters

NVIDIA’s reference design for training trillion-parameter models is the GB200 NVL72 Grace-Blackwell rack. This is a powerful server rack that unites 72 Blackwell GPUs and 36 Grace CPUs in one memory-coherent domain.

[Benchmarks](https://developer.nvidia.com/blog/nvidia-blackwell-delivers-massive-performance-leaps-in-mlperf-inference-v5-0/#:~:text=The%20Blackwell%20platform%20is%20available,connected%20using%20NVLink%20and%20NVSwitch) indicate that, for enormous 405-billion parameter models, the GB200 NVL72 can train enormous models faster than previous generations. An independent analysis by Adrian Cockcroft, a distinguished technologist renowned for his transformative work in cloud computing and system architecture, [found](https://adrianco.medium.com/deep-dive-into-nvidia-blackwell-benchmarks-where-does-the-4x-training-and-30x-inference-0209f1971e71#:~:text=There%20are%20three%20generations%20of,been%20as%20impressive%2C%20and%20users) a 4× speedup to be plausible when comparing a fully equipped Grace-Blackwell configuration against a high-end Hopper-based cluster.

The key contributors to this performance boost include Blackwell’s higher FLOPs per-GPU, Grace’s added CPU memory capacity, faster NVLink-C2C interconnects, and the sheer scale of the single-rack system. In practical terms, if a model previously took 10 days to train on a cluster of Hopper GPUs, the new Blackwell cluster could finish in about 2–3 days. This dramatically accelerates time to insight and increases the rate of experimentation.

The lesson learned for AI systems engineers is that scaling is not always linear with respect to the amount of hardware thrown at the problem. Scaling efficiently requires eliminating bottlenecks at every level. The Grace-Blackwell design tackles several bottlenecks at once including faster GPUs, faster matrix operations on dedicated Tensor Cores, more memory per GPU for larger batch sizes, and an improved NVLink and NVSwitch architecture to link dozens of GPUs with low latency. All of this yields better scaling efficiency. Training jobs and inference servers that used to struggle to fully utilize 72 H100 GPUs now achieve near-linear scaling efficiency on 72 Grace-Blackwell GPUs in the NVL72 configuration because the communication overhead is so much lower.

The ROI when using Grace-Blackwell for training workloads is measured by faster training runs and quicker experiments. Consider an enterprise training a 500-billion-parameter LLM on their specific datasets. With the GB200 NVL72 systems, that can reduce training time from 4 weeks to 1 week, for example. This can be transformative as models reach production faster and use less energy per insight gained.

Thus, although the upfront cost of a GB200 cluster is hefty, organizations see value in the form of accelerated R&D and potentially lower cost when measured per model trained and insight gained. In sum, this case demonstrates the ROI of adopting next-generation hardware for large-scale LLM training including faster experiment results and better throughput per dollar. This enables organizations and research labs to push the AI frontier without breaking the bank.

# HPE’s Grace-Blackwell Supercomputer for the Trillion-Parameter Era

In early 2025, Hewlett Packard Enterprise [shipped](https://www.hpe.com/us/en/newsroom/press-release/2025/02/hpe-announces-shipment-of-its-first-nvidia-grace-blackwell-system.html#:~:text=HOUSTON%20%E2%80%93%C2%A0%20FEBRUARY%2013%2C%202025%C2%A0,to%20optimize%20efficiency%20and%20performance) its first NVIDIA Grace-Blackwell system called the HPE Cray XD. This is their implementation of the GB200 NVL72 rack specification. This marks one of the first real-world deployments of this technology outside of NVIDIA’s own labs. The HPE Cray XD rack-scale system is built for organizations that need to train and serve models at the 1-trillion parameter scale using a single, unified memory space.

HPE emphasizes that such systems offer lower cost per token training and best-in-class throughput for ultra-scale models ([HPE announces shipment of its first NVIDIA Grace Blackwell system | HPE](https://www.hpe.com/us/en/newsroom/press-release/2025/02/hpe-announces-shipment-of-its-first-nvidia-grace-blackwell-system.html#:~:text=%E2%80%9CAI%20service%20providers%20and%20large,leading%20services%20expertise.%E2%80%9D)). This means that even though the absolute cost of their rack is high, the efficiency - in terms of tokens processed per second per dollar invested - is significantly higher when models are at the trillion-scale. The target users are cloud AI service providers and large enterprise research groups.

The lessons learned by the HPE engineers who first used the HPE Cray XD are that, with all 72 GPUs in one domain, debugging and optimizing parallel training jobs became easier than on a traditional 8-GPU-per-node cluster as there were fewer moving pieces in terms of network communication patterns. However, they also learned about failure modes unique to the NVL72 system such as faults in the NVLink/NVSwitch fabric. This type of failure could impact many GPUs at once with the NVL72 rack design. Previously, a bad InfiniBand link would affect only one node.

For the pioneering customers of these systems, the ROI of embracing the NVL72 rack design is a competitive advantage. HPE and its customers can now fit massive models into memory and can train much quicker than their competitors. Additionally, by delivering the Cray XD as a single integrated solution, their customer’s time-to-value is significantly accelerated. Organizations can now spin up a 1-exaFLOP AI supercomputer and get to work within days instead of months or years. The fast time-to-deployment allows HPE’s customers to purchase a turnkey solution for giant AI models. This de-risks their investment, speeds up their time to ROI, and yields massive AI system performance breakthroughs.

# Training and Serving a 100-Trillion-Parameter Model

Envision a (not-so-distant) future where an AI research lab attempts something extraordinary like training a dense 100-trillion-parameter transformer. This is roughly 100× larger than today’s large models which are measured in the tens or hundreds of billions of parameters. How could one possibly accomplish this with Grace-Blackwell (GB200) superclusters?

In this hypothetical scenario, the lab assembles a training cluster composed of multiple GB200 NVL72 units – say 8 racks, for a total of 576 Blackwell GPUs and 288 Grace CPUs networked together. Even using Blackwell’s hefty 192 GB of HBM RAM per GPU, a single 100-trillion model would barely load into the collective GPU HBM RAM of the 8-rack system - even at a reduced 8-bit precision.

For example, at 8-bit precision, 100 trillion parameters would require 100 TB or 100,000 GB. 100,000 GB / 192 GB HBM per GPU = 520 GPUs. We only have 576 in an 8-rack system, so the model would load, but it would be impossible to train entirely in GPU HBM RAM as training requires additional gradients, activations, and optimizer states which add significant overhead - beyond the capacity of a single rack.

Since a 100-trillion-parameter model won’t fit into an 8-NVL72 rack ultra-cluster. As such, the team will need to leverage the massive pool of Grace CPU memory to spillover memory from the GPU as needed. This requires that the system stream weights in and out of CPU RAM over the NVLink 5 interconnect within a rack, or InfiniBand between racks. Of course, you would want to avoid as much cross-rack communication as possible.

One would almost certainly want to employ tensor and pipeline parallelism to divide the massive network across GPUs. Another option is to split the model across For example, with pipeline parallelism, each GB200 rack would be responsible for 1/8 of the layers. However, this will require inter-rack communication between the layers - slowing down both inference and training.

Remember that within a rack, the 72 GPUs are all interconnected at full NVLink bandwidth and handle their portion of the model with high-speed coordination. However, between racks, slower InfiniBand links connect the NVLink domains. The engineers, mindful of the hierarchy, design an efficient, pipelined, and parallel compute/communication schedule. For example, as one rack finishes computing its layers for a given batch, it passes the intermediate results (activations) to the next rack’s layers for processing. At the same time, the first rack starts computing the next batch - and so on.

By combining data, pipeline, and tensor parallelism (3D parallelism) one ensures that all GPUs are kept busy despite the inter-rack communication delays. To further reduce strain, one would quantize activations down to FP8 during transit - and apply efficient all-reduce gradient-update algorithms so that cross-rack synchronization is minimized at each step. This avoids the dreaded stop-the-world synchronization barrier for distributed training.

One would also consider a mixture-of-experts (MoE) approach by dividing the 100-trillion-parameter model into 100 separate 10-trillion-parameter expert models. This would mean at any given token, only a subset of the experts (racks) are active. This would significantly cut the computation and communication per step.

Using MoEs, however, adds the additional challenge of gating the network, routing tokens to the correct experts, and ensuring a balanced load on experts. Techniques like dynamic expert scaling could be used so that all racks are utilized evenly to avoid network hotspots - even as different experts are activated.

On the software side, an orchestration layer such as NVIDIA Dynamo - working with the TensorRT-LLM or vLLM serving engine – would be required to coordinate work across the large number of GPUs in the system. It might assign micro-batches to different pipeline stages, handle the GPU failures by remapping the GPUs, and optimize the reuse of the massive KV-cache across the cluster.

Serving inference for a 100-trillion-parameter model would be a massive undertaking. The team might use Dynamo’s disaggregation to host the model’s weights in CPU memory and only bring the necessary experts/layers into GPU memory as needed for a given query. In this case, the system would need to aggregate together a response using the partial results computed on different racks.

The team would also lean heavily on 4-bit weight quantization for inference using Blackwell’s FP4 support to shrink the active model footprint to around 50 TB. This is still huge, but within the realm of a multi-rack system’s capabilities.

The lessons from this thought experiment highlight which ultra-scale performance tips are needed including hierarchical parallelism, aggressive quantization and sparsity, and sophisticated scheduling. Otherwise, this is an intractable problem. Both the model’s internal neural-network architecture - and the physical cluster network - must be co-designed such that every latency and bandwidth consideration is a first-class concern.

The hypothetical ROI for successfully training a 100-trillion-parameter model would be groundbreaking. Such a model could exhibit unparalleled capabilities, achieve leaps in accuracy, or handle extremely complex artificial general intelligence (AGI) or artificial super intelligence (ASI) tasks.

However, the costs and risks are very high. Training might cost tens or hundreds of millions of dollars in GPU compute time. The engineering must ensure that each of the 576 GPUs is utilized to its maximum the entire time. Any inefficiency could waste compute hours and money. Techniques proven at relatively-small scale - such as those used by DeepSeek to train their V3 model on a limited-capability NVIDIA H800’s training cluster - would be mandatory at this 100 trillion parameter scale.

If done right, the payoff is a first-of-its-kind AI system and a place in the history books. If done poorly, one could burn through a fortune with little to show. Thus, this hypothetical case underscores the reality for performance engineers - at extreme scale, planning, optimizing, profiling, and iterating are the only way to make the impossible possible. The idea is to efficiently convert ultra-scale hardware investments into unprecedented AI capabilities.

# Key Takeaways

Co-Designed Hardware and Software Optimizations.Performance improvements in LLMs are truly achieved by breakthroughs coming from tightly integrated hardware and software co-designed innovations.

Numerical Precision Advances.Using newer numerical precision modes like 8-bit on Hopper and 4-bit on Blackwell can significantly increase training speed without sacrificing accuracy. This shows how even small changes in how numbers are represented can lead to big performance wins.

Overlap of Computation and Data Transfer.Several case studies highlight how algorithms that overlap computation with data transfers help offset hardware constraints such as lower memory bandwidth.

Advanced Scheduling and Batching.Intelligent scheduling frameworks and dynamic batching techniques used in NVIDIA Dynamo and vLLM maximize GPU utilization and enable existing hardware to achieve higher throughput.

Compiler and Kernel Innovations.Techniques such as aggressive kernel fusion in PyTorch and AI-generated GPU kernels demonstrate that software innovations can unlock performance gains that rival or surpass the improvements expected from new hardware.

Cross-Team Collaboration is Important.Hyper-scale training is as much about agile, cross-team collaboration and iterative troubleshooting as it is about raw compute power. The OpenAI case study serves as a blueprint for balancing long-term planning with rapid problem solving.

Clever Software and Algorithms can Workaround Hardware Limitations.Despite being constrained to lower-bandwidth GPUs (NVIDIA H800), DeepSeek succeeded in training a 671-billion parameter mixture-of-experts model through custom parallelism techniques (DualPipe) and smart algorithm design. This demonstrates cost-effective innovations driven by hardware limitations.

Leverage Compilers When Possible.By leveraging new Tensor Cores and the PyTorch compiler for FP8 precision, MobileEye nearly doubled its training throughput, illustrating that embracing new precision formats and compiler optimizations can deliver major efficiency gains.

Self-Optimizing Algorithms.Deepmind’s AlphaTensor showcased how AI can discover new, more efficient GEMM algorithms. This improved performance by 10–20% without additional hardware.

Embrace AI-Assisted Coding and Optimizing.Nvidia’s experiments with DeepSeek-R1, Sakana.ai’s AI CUDA Engineer, and Predibase’s RL approach prove that LLMs can be used not only for high-level tasks but also for generating, testing, and refining low-level GPU code, delivering orders-of-magnitude improvements in speed with dramatically reduced engineering time.

Unified CPU-GPU Superchips Reduce Bottlenecks.Advanced systems like NVIDIA’s GH200 Grace-Hopper and Grace-Blackwell platforms show that integrating CPUs and GPUs on the same chip and linking them via high-speed interconnects can reduce data transfer bottlenecks and improve throughput. This kind of integration can also dramatically lower the cost per generated token in inference tasks.

Design for Rack-Scale and Ultra-Scale Infrastructure.Deployments such as the GB200 NVL72 rack system and HPE’s Grace-Blackwell supercomputer underline that moving from traditional clusters to highly integrated systems can yield huge improvements in throughput and significant reductions in latency.

Consider Strategies for 100-Trillion-Parameter Models.Training models with 100 trillion parameters will require a blend of aggressive quantization, multi-dimensional parallelism (data, pipeline, tensor, expert, and sequence), and careful orchestration of inter-rack communication. This stresses that future AI scaling depends on both hardware capabilities and the ingenuity of software-level scheduling.

Strive for Both Cost Efficiency and Throughput Improvements.Many of the case studies emphasize that software improvements and AI-driven kernel optimizations can yield a free boost in performance. These enhancements lower the cost of training and inference, allowing organizations to serve more users or experiment with larger models without proportionately increasing their hardware investment.

Increase Time-to-Insight and Productivity.Faster training cycles and more efficient inference enable organizations to bring advanced AI products to market sooner. This is critical in an era where time-to-insight is as valuable as the raw performance improvements.

# Conclusion

The journey through these case studies narrates a pivotal era in AI systems performance engineering marked by the seamless integration of NVIDIA’s groundbreaking GPU and CPU architectures including the rack-scale Grace-Hopper and Grace-Blackwell systems of today - as well as the Vera-Rubin and Feynmann systems of tomorrow. By fusing the CPU and GPU into a superchip module, NVIDIA has redefined the capabilities of LLMs and achieved unprecedented levels of efficiency and scalability.

Central to these advancements is the GB200 NVL72 system which connects 72 GPUs into a unified processing unit and delivers extreme throughput in real-time for trillion-parameter LLM inference. This performance is facilitated by the second-generation Transformer Engine, supporting FP4 and FP8 precisions, and the fifth-generation NVLink, providing 130 terabytes per second of low-latency GPU communication. Software breakthroughs complement these hardware innovations. For example, software for inference - like NVIDIA Dynamo and vLLM improve dynamic scheduling and resource allocation algorithms - enhance processing speed and increase energy efficiency.

These case studies underscore the importance of a co-design approach, where hardware capabilities and software strategies are developed in tandem to meet the demands of ultra-scale AI models. This collaborative strategy has resulted in significant reductions in training durations, lower inference latencies, and decreased operational costs, delivering substantial returns on investment.

AI-driven CUDA coding agents - demonstrated by organizations such as NVIDIA, Sakana.ai, and Predibase - highlight how AI can be used to optimize AI. Together, humans and AI agents can work together to create substantial performance gains.

In a rapidly evolving landscape where even modest performance enhancements can yield significant competitive advantages, these case studies provide a comprehensive roadmap for future advancements in AI systems performance engineering. They illustrate that through the strategic integration of advanced hardware and intelligent software solutions, the deployment of trillion-parameter and mluti-trillion-parameter AI models is both feasible and very much achievable. This paves the way for the next generation of AI applications and research initiatives.
