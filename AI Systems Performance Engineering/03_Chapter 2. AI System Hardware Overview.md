# Chapter 2. AI System Hardware Overview

# A Note for Early Release Readers

With Early Release ebooks, you get books in their earliest form—the author’s raw and unedited content as they write—so you can take advantage of these technologies long before the official release of these titles.

This will be the 2nd chapter of the final book.

If you’d like to be actively involved in reviewing and commenting on this draft, please reach out to the editor at *arufino@oreilly.com*.

Imagine condensing a supercomputer’s worth of AI hardware into a single rack. NVIDIA’s latest architecture does exactly that. In this chapter, we dive into how NVIDIA fused CPUs and GPUs into powerful “superchips” and then wired dozens of them together with ultra-fast interconnects to create an AI supercomputer-in-a-box. We’ll explore the fundamental hardware building blocks – the Grace CPU and Blackwell GPU – and see how their tight integration and enormous memory pool make life easier for AI engineers.

Then we’ll expand outward to the networking fabric that links 72 of these GPUs as if they were one machine. Along the way, we’ll highlight the leaps in compute performance, memory capacity, and efficiency that give this system its superpowers. By the end, you’ll appreciate how this cutting-edge hardware enables training and serving multi-trillion-parameter models that previously seemed impossible.

# The CPU and GPU “Superchip”

NVIDIA’s approach to scaling AI starts at the level of a single, combined CPU+GPU “superchip” module. Beginning with the Hopper generation, NVIDIA started packaging an ARM-based CPU together with one or more GPUs in the same unit, tightly linking them with a high-speed interface. The result is a single module that behaves like a unified computing engine.

The first incarnation was the Grace-Hopper (GH200) superchip which pairs one Grace CPU with one Hopper GPU. Next is the Grace-Blackwell (GB200) superchip, which pairs one Grace CPU with two Blackwell GPUs on the same package. Essentially, the Grace CPU sits in the center of the module, flanked by two Blackwell GPU dies, all wired together as one coherent unit as shown in [Figure 2-1](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch02.html#ch02_figure_1_1744914895521480).

![A close-up of a computer chip  AI-generated content may be incorrect.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9798341627772/files/assets/ch02_figure_1_1744914895521480.png)

###### Figure 2-1. NVIDIA Grace-Blackwell Superchip module, containing one Grace CPU (center) and two Blackwell B200 GPUs (top) on a single module with shared memory address space.

What’s the advantage of fusing a CPU and GPUs together? In a single word - memory! In a traditional system, the CPU and GPU have separate memory pools and communicate over a relatively slow bus (like PCIe), which means data has to be copied back and forth. NVIDIA’s superchip eliminates that barrier by connecting the CPU and GPUs with a custom high-speed bus called NVLink-C2C (chip-to-chip) link that runs at about 900 GB/s of bandwidth between the Grace CPU and each GPU.

NVLink-C2C’s interconnect speed is orders of magnitude faster than typical PCIe. And, importantly, it is cache-coherent. Cache coherency means the CPU and GPU share a unified memory address space and always see the same data values. In practice, the Grace CPU and Blackwell GPUs on a superchip can all access each other’s memory directly as if it were one huge memory pool. The GPU can read or write data stored in the CPU’s memory and vice versa without needing explicit copies. This unified memory architecture is often called Extended GPU Memory (EGM) by NVIDIA, and it effectively blurs the line between “CPU memory” and “GPU memory.”

Each Grace-Blackwell superchip carries a tremendous amount of memory. The Grace CPU comes with hundreds of gigabytes of LPDDR5X DRAM attached, and each Blackwell GPU has its own high-speed HBM stacks. In the GB200 superchip, the Grace CPU provides 480 GB of memory and the two Blackwell GPUs together contribute 384 GB of HBM3e memory (192 GB per GPU). That’s a total of 864 GB of memory accessible by the GPUs and CPU in a unified address space.

To put it simply, each superchip has nearly a terabyte of fast, unified memory at its disposal. This is a game-changer for giant AI models. In older systems, a single GPU might be limited to <100 GB of memory, which meant models larger than that had to be partitioned or offloaded to slower storage. Here, a GPU can seamlessly utilize the CPU’s memory as an extension.

If a neural network layer or a large embedding table doesn’t fit in the GPU’s local HBM, it can reside in the CPU’s memory and the GPU will still be able to work with it across NVLink-C2C. From a programmer’s perspective, the hardware takes care of data movement. One simply needs to allocate the memory and use it. The unified memory and coherence mean the days of manually shuttling tensors between CPU and GPU memory are largely over.

Of course, GPU memory is still much faster and closer to the GPU cores than CPU memory – you can think of the CPU memory as a large but somewhat slower extension. Accessing data in LPDDR5X isn’t as quick as HBM on the GPU. It’s on the order of 10× lower bandwidth and higher latency. A smart runtime will keep the most frequently used data in the 192 GB of HBM and use the CPU’s 480 GB for overflow or less speed-critical data.

The key point is that overflow no longer requires going out to SSD or across a network. The GPU can fetch from CPU RAM at perhaps 900 GB/s (half-duplex 450 GB/s each way), which while slower than HBM, is vastly faster than fetching from NVMe storage. This flexibility is invaluable. It means that a model that is, say, 500 GB in size (too large for a single GPU’s HBM) could still be placed entirely within one superchip module (192 GB in HBM + the rest in CPU memory) and run without partitioning the model across multiple GPUs. The GPU would just transparently pull the extra data from CPU memory when needed.

In essence, memory size ceases to be a hard limit for fitting ultra-large models, as long as the total model fits within the combined CPU+GPU memory of the superchip. Many researchers have faced the dreaded “out of memory” errors when models don’t fit on a GPU – this architecture is designed to push that boundary out dramatically.

## NVIDIA Grace CPU

The Grace CPU itself is no sloth. It’s a high-core-count (72 cores) ARM CPU custom-built by NVIDIA for bandwidth and efficiency. Its job in the superchip is to handle general-purpose tasks, preprocess and feed data to the GPUs, and manage the mountain of memory attached to it. It runs at a modest clock speed but makes up for it with huge memory bandwidth – roughly 0.5 TB/s to its LPDDR5X memory – and lots of cache including tens of MB of L3 cache.

The philosophy is that the CPU should never become a bottleneck when shoveling data to the GPUs. It can stream data from storage or perform on-the-fly data transformations like tokenization or data augmentation - feeling the GPUs through NVLink-C2C very efficiently. If part of your workload is better on the CPU, the Grace cores can tackle that and make the results immediately accessible by the GPUs.

This is a harmonious coupling in which the CPU extends the GPU’s capabilities in areas where GPUs are weaker like random memory accesses or control-heavy code. And the GPUs accelerate the number-crunching where CPUs can’t keep up. The low-latency link between the CPU and GPUs means they can trade tasks without the usual overhead. For example, launching a GPU kernel from the CPU can happen much faster than on a traditional system, since the command doesn’t have to traverse a slow PCIe bus. The CPU and GPU are essentially on the same board. This should feel similar to calling a fast local function vs. a slower remote function.

Now let’s talk about the Blackwell GPU, the brute-force engine of the superchip.

## NVIDIA Blackwell GPU

Blackwell is NVIDIA’s codename for this GPU generation, and it represents a significant leap over the previous Hopper (H100) GPUs in both compute horsepower and memory. Each Blackwell B200 GPU in a GB200 superchip isn’t a single chip but actually a multi-chip module (MCM) with two GPU dies sitting on one package.

This is the first time NVIDIA’s flagship data center GPU has used a chiplet approach. This effectively splits what would be one enormous GPU into two sizable dies and links them together. Why do this? Because a single monolithic die is limited by manufacturing, there’s a limit to how large you can make a chip on silicon. By combining two physical dies into a single GPU, NVIDIA can double the total transistor budget for the GPU.

In Blackwell’s case, each die has about 104 billion transistors, so the combined GPU module has around 208 billion transistors. This is an astonishing amount of electrical complexity and sophistication. These two dies communicate via a specialized, high-speed, die-to-die interconnect that runs at 10 TB/s bandwidth between them allowing the two dies to function as one unified GPU to the software layer running on top of it.

From the system’s perspective, a Blackwell “GPU” is one single device with a large pool of memory (192 GB HBM) and a ton of execution units, but under the hood its two chips working in tandem. NVIDIA’s software and scheduling ensure that work is balanced across the two dies, and memory accesses are coherent. This allows developers to largely ignore this complexity as they appear as one GPU as NVIDIA intended.

Each Blackwell GPU module has 192 GB of HBM3e memory divided across the two dies (96 GB each). This doubles the 96 GB from the previous-generation Hopper H100 GPU and gives much more headroom for model parameters, activations, and input data. The memory is also faster as Blackwell’s HBM3e has an aggregate bandwidth of roughly 8 TB/s per GPU. For comparison, the Hopper H100 delivered about 3.35 TB/s, so Blackwell’s memory subsystem is about 2.4× more throughput by design.

Feeding data at 8 terabytes per second means the GPU cores are kept busy crunching on huge matrices without frequently stalling to wait for data. NVIDIA also beefed up on-chip caching as Blackwell has a total of 100 MB of L2 cache (50 MB on each die). This cache is a small but ultra-fast memory on the GPU that holds recently used data. By doubling the L2 cache size compared to H100’s 50 MB L2 cache, Blackwell can keep more of the neural network weights or intermediate results on-chip, avoiding extra trips out to HBM. This again helps ensure the GPU’s compute units are seldom starved for data.

## NVIDIA GPU Tensor Cores and Transformer Engine

Speaking of compute units, Blackwell introduces enhancements specifically aimed at AI workloads. Central to this is NVIDIA’s Tensor Core technology and the Transformer Engine. Tensor Cores are specialized units within each streaming multiprocessor (SM) of the GPU that can perform matrix multiplication operations at very high speed.

Tensor Cores were present in prior generations, but Blackwell’s Tensor Cores support even more numerical formats, including extremely low-precision ones like 8-bit and 4-bit floating point. The idea behind lower precision is simple. By using fewer bits to represent numbers, you can perform more operations at the same time - not to mention your memory goes further since less bits are used to represent the same numbers. This, of course, assumes that your algorithm can tolerate a little loss in numerical precision. These days, a lot of AI algorithms are designed with low-precision numerical formats in mind.

NVIDIA pioneered the Transformer Engine (TE) to automatically adjust and use mixed precision in deep learning where critical layers use higher precision (FP16 or BF16) and less-critical layers use FP8. TE automatically optimizes the balance of precision with the goal of maintaining the model’s accuracy at the lower precision.

In the Hopper generation, the Transformer Engine first introduced FP8 support which doubled the throughput versus FP16. Blackwell takes it one step further by introducing an even-lower precision called FP4, a 4-bit floating-point format that uses half the number of bits of FP8 to represent a number. FP4 is so tiny that it can potentially double the compute throughput of FP8.

In fact, one Blackwell GPU can achieve about 9 PFLOPS (9 quadrillion operations per second) of compute using FP4 Tensor Core operations. This is roughly double its FP8 rate, and about 4× its FP16 rate. To put that in perspective, the earlier H100 GPU peaked around 1 PFLOP in FP16, so Blackwell can be on the order of 2–2.5× faster in FP16 and much more when leveraging FP8/FP4. [Figure 2-2](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch02.html#ch02_figure_2_1744914895521515) shows the relative speedup of FP8 and FP4 relative to FP16.

![A graph with different colored bars  AI-generated content may be incorrect.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9798341627772/files/assets/ch02_figure_2_1744914895521515.png)

###### Figure 2-2. Relative speedup of FP8 and FP4 compared to FP16.

An entire NVL72 rack (72 GPUs) has a theoretical Tensor Core throughput over 1.4 exaFLOPS (that’s 1.4×10^18) in 4-bit precision. This is a mind-boggling number that puts this single rack in the realm of the world’s fastest supercomputers - albeit at low FP4 precision. Even if real-world workloads don’t always hit that peak, the capability is there, which is astonishing.

Blackwell boasts version 2 of the NVIDIA Transformer Engine (TE). This is the magic sauce that makes using FP8 and FP4 practical. It dynamically selects the precision for each layer of a neural network during training or inference, trying to use the lowest precision that will still preserve model accuracy. For example, the TE might keep the first layers of a neural net in FP16 since early layers can be sensitive to noise. But, based on heuristics, it could decide to use FP8 or FP4 for later layers that are more tolerant - or for giant embedding matrices where high precision isn’t as critical.

All of this happens under the hood in NVIDIA’s libraries. As a user, you just enable mixed precision and let it go. The result is a huge speedup that essentially comes “for free.” Many large language models (LLMs) today train in FP8 for this reason, effectively doubling training speed compared to FP16 - and with negligible accuracy loss. Blackwell was built to make FP8 and FP4 not just theoretical options but everyday tools.

In fact, tests show that Blackwell delivers nearly 5× higher AI throughput using FP4 vs FP16 in some cases. These formats slash memory usage as well. Using FP4 halves the memory needed per parameter compared to FP8, meaning you can pack an even larger model into the GPU’s memory.

NVIDIA has effectively bet on AI’s future being in lower precision arithmetic, and has given Blackwell the ability to excel at it. This is especially critical for inference serving of massive models, where throughput (tokens per second) and latency are paramount.

To illustrate the generational leap forward from Hopper to Blackwell, NVIDIA reported an H100-based system could only generate about 3 to 5 tokens per second per GPU for a large 1.8-trillion parameter mixture-of-experts (MoE) model - with over 5 seconds of latency for the first token. This is too slow for interactive use.

The Blackwell-based system (NVL72) ran the same model with around 150 tokens per second per GPU, and cut first-token latency down to ~50 milliseconds. That is roughly a 30× throughput improvement and a huge reduction in latency, turning an impractical model into one that can respond virtually in real-time.

This dramatic speedup came from raw FLOPs, the combination of faster GPUs, lower precision (FP4) usage, and the NVLink interconnect keeping the GPUs fed with data. It underscores how a holistic design that spans across both compute and communication can translate into real-world performance gains.

In essence, Blackwell GPUs are more powerful, smarter, and better fed with data than their predecessors. They chew through math faster, thanks to Tensor Cores, Transformer Engine, and low precision. Additionally, the system architecture ensures that data is made available quickly thanks to huge memory bandwidth, large caches, and NVLink.

Before moving on, let’s quickly discuss the hierarchy inside the GPU, as this is useful to understand performance tuning later.

## Streaming Multiprocessors, Threads, and Warps

Each Blackwell GPU, like its predecessors, consists of many Streaming Multiprocessors (SMs). Think of these like the “cores” of the GPU as shown in [Figure 2-3](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch02.html#ch02_figure_3_1744914895521540).

![A computer graphics showing different types of computer graphics  AI-generated content may be incorrect.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9798341627772/files/assets/ch02_figure_3_1744914895521540.png)

###### Figure 2-3. Comparing CPU cores to GPU cores. ([https://www.cudocompute.com/blog/nvidia-gb200-everything-you-need-to-know](https://www.cudocompute.com/blog/nvidia-gb200-everything-you-need-to-know), [modal.com](https://modal.com/gpu-glossary/device-hardware/streaming-multiprocessor#:~:text=Streaming%20Multiprocessors%20,performance%20CPUs)).

Each SM contains a bunch of arithmetic units (for FP32, INT32, etc.), Tensor Cores for matrix math, load/store units for memory operations, and some special function units for things like transcendental math. The GPU also has its own small pool of super-fast memory including registers, shared memory, and L1 cache.

The SM executes threads in groups of 32 called warps where each warp contains 32 threads. It can execute many active warps in parallel to help cover latency if a thread is waiting on data from memory. Consider an SM having dozens of warps (hundreds of threads) in flight concurrently. If one warp is waiting on a memory fetch, another warp can run. This is called latency hiding. We will revisit latency hiding throughout the book. This is a very important performance-optimization tool to have in your tuning toolbox.

A high-end GPU like Blackwell will have on the order of 140 SMs. Each SM is capable of running thousands of threads concurrently. This is how we get tens of thousands of active threads onto a single GPU. All those SMs share a large 100 MB L2 cache, as we mentioned earlier, and share the memory controllers that connect to the HBM. The memory hierarchy contains registers (per thread) → shared memory/L1 cache (per SM) → L2 cache (on GPU, shared by all SMs) → HBM memory (off-chip) as shown in [Figure 2-4](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch02.html#ch02_figure_4_1744914895521561).

![A diagram of a computer hardware system  AI-generated content may be incorrect.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9798341627772/files/assets/ch02_figure_4_1744914895521561.png)

###### Figure 2-4. GPU memory hierarchy

For best performance, data needs to stay as high in that hierarchy as possible. If every operation went out to HBM 0 even at 8 TB/s, the GPU would stall too often due to the increased latency of accessing off-chip memory. By keeping reusable data in SM local memory or L2 cache, the GPU can achieve enormous throughput. The Blackwell architecture’s doubling of cache and bandwidth is aimed exactly at keeping the GPU beast fed and happy.

As performance engineers, we’ll see many examples where a kernel’s performance is bound by compute as well memory traffic and throughput. NVIDIA clearly designed Blackwell so that, for many AI workloads, the balance between FLOPs and memory bandwidth is well-matched. Roughly speaking, the balance is on the order of 2–3 FLOPs of compute per byte of memory bandwidth in FP4 mode. This is a reasonable ratio for dense linear algebra operations. This means the GPUs will often be busy computing rather than waiting on data, given well-optimized code, of course. Note that certain operations like huge reductions or random memory accesses can still be memory-bound, but the updated GPU, memory, and interconnect hardware make this a bit less of an issue.

# Ultra-Scale Networking Treating Many GPUs as One

Packing two GPUs and a CPU into a superchip gives us an incredibly powerful node – but NVIDIA didn’t stop at one node. The next challenge is connecting many of these superchips together to scale out to even larger model training.

The flagship configuration using GB200 superchips is what NVIDIA calls the NVL72 system, essentially an AI supercomputer contained in a single rack. NVL72 stands for a system with 72 Blackwell GPUs - and 36 Grace CPUs - all interconnected via NVLink.

The GB200 NVL72 is built as 18 compute nodes (each 1U in size), where each node contains two GB200 superchips for a total of 4 Blackwell GPUs + 2 Grace CPUs per compute node as shown in [Figure 2-5](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch02.html#ch02_figure_5_1744914895521591).

![A close-up of a computer chip  AI-generated content may be incorrect.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9798341627772/files/assets/ch02_figure_5_1744914895521591.png)

###### Figure 2-5. A 1U compute tray within the GB200 NVL72 rack with two Grace-Blackwell superchips where each superchip module has one Grace CPU and two Blackwell GPU dies.The NVL72 has 18 of these trays linked together (Source: [developer.nvidia.com](https://developer.nvidia.com/blog/nvidia-gb200-nvl72-delivers-trillion-parameter-llm-training-and-real-time-inference/#:~:text=The%20GB200%20compute%20tray%20is,7%20TB%20of%20fast%20memory)).

By connecting 18 compute nodes together, the GB200 NVL72 links 72 Blackwell GPUs (18 nodes * 4 GPUs) and 36 Grace CPUs (18 nodes * 2 CPUs) together to form a powerful, unified CPU-GPU cluster. The remarkable thing about NVL72 is that every GPU can talk to any other GPU at very high speed as if all 72 were on the same motherboard. NVIDIA achieved this using a combination of NVLink 5 connections on the GPUs and dedicated switch silicon called NVSwitch.

## NVLink and NVSwitch

Each Blackwell GPU has 18 NVLink 5 ports where each port can support 100 GB/s of data transferred bidirectionally or 50 GB/s in a single direction. Combined, a single GPU can shuffle up to 1.8 TB/s (18 NVLink ports * 100 GB/s) of data with its peers via NVLink. This is double the per-GPU NVLink bandwidth of the previous generation as the Hopper H100 uses NVLink 4 which runs at half of the bidirectional 900 GB/s speed of NVLink 5.

The GPUs are cabled in a network through NVSwitch chips. NVSwitch is essentially a switching chip similar to a network switch, but it’s built specifically for NVLink. This means any GPU can reach any other GPU via a single hop through one of the NVSwitch chips with full bandwidth. [Figure 2-6](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch02.html#ch02_figure_6_1744914895521612) shows an NVLink Switch tray used in NVL72.

![A close-up of a device  AI-generated content may be incorrect.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9798341627772/files/assets/ch02_figure_6_1744914895521612.png)

###### Figure 2-6. One NVLink Switch tray from NVL72. (Source: [developer.nvidia.com](https://developer.nvidia.com/blog/nvidia-gb200-nvl72-delivers-trillion-parameter-llm-training-and-real-time-inference/#:~:text=Fifth,System))

Each switch tray contains two NVSwitch chips (the large chips visible), and multiple high-speed ports (the blue cables represent NVLink connections). In the NVL72 rack, 9 such switch trays, shown in [Figure 2-7](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch02.html#ch02_figure_7_1744914895521633), provide the fabric that fully connects the 72 Blackwell GPUs.

![A grey rectangular object with a black background  AI-generated content may be incorrect.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9798341627772/files/assets/ch02_figure_7_1744914895521633.png)

###### Figure 2-7. NVSwitch System of 9 trays inside an NVL72 rack

Each switch tray contains two NVSwitch chips for a total of 18 NVSwitch chips in the system. The network is arranged as a full crossbar such that every GPU is connected to every NVSwitch, and every NVSwitch to every GPU, providing a high-bandwidth path between any pair of GPUs.

Concretely, each GPU uses its 18 NVLink ports to connect to the 18 NVSwitch chips (one link to each switch). This means any GPU can reach any other GPU in at most two hops (GPU → NVSwitch → GPU), with enormous bandwidth along the way.

The bandwidth across the whole 72-GPU network, called the aggregate bisection bandwidth, is about 130 TB/s inside the rack. For perspective, that is many times higher than even a top-end InfiniBand cluster of similar scale. The design basically turns the entire rack into one giant shared-memory machine.

## Multi-GPU Programming

From a programming model standpoint, one GPU can directly perform a memory load from another GPU’s HBM memory over NVLink, or even from a Grace CPU in another node, and get the data in a matter of microseconds. In other words, the GPUs can operate in a globally shared memory space across the rack, very much like how cores inside a single server share memory. This is why the NVL72 is often described as “one big GPU” or “an AI supercomputer in a rack”.

Software libraries like RDMA (remote direct memory access) abstract away the complexities of this global shared-memory space by providing simple programming interfaces such as atomic operations across GPUs. Distributed training and inference workloads need to synchronize and exchange information frequently across many GPUs. Traditionally, the GPUs are in different compute nodes and racks so the synchronization happens over relatively-slow network links like InfiniBand and Ethernet. This is often the bottleneck when scaling across many GPUs to support large AI models.

With the GB200 NVL72 system, those exchanges happen over NVLink and NVSwitch at a blistering pace. This means you can scale your training job or inference cluster up to 72 GPUs with minimal communication overhead. And since the GPUs spend far less time waiting for data from each other, overall throughput scales near-linearly up to 72 GPUs. By contrast, consider scaling the same job across an similarly-sized 72-GPU H100 cluster of 9 separate compute servers (each with 8 Hopper H100 GPUs). This configuration requires InfiniBand which will create network bottlenecks that greatly reduce the cluster’s scaling efficiency.

Let’s analyze and compare the GB200 NVL72 and 72-GPU H100 clusters using concrete numbers. Within a single NVL72 rack, GPU-to-GPU bandwidth is on the order of 100 GB/s+, and latency is on the order of 1–2 microseconds for a small message. Across a conventional InfiniBand network, bandwidth per GPU might be more like 20–80 GB/s - depending on how many NICs and their speed - and latency is likely 5–10 microseconds or more. The NVL72 network offers both higher throughput (2× or more per GPU) and lower latency (3-5x more) than the best InfiniBand networks for node-to-node GPU communication. In practical terms, an all-reduce collective operation which aggregates gradients across GPUs might consume 20–30% of iteration time on an InfiniBand-linked H100 cluster, but only take a 2-3% on the NVLink-connected NVL72 cluster.

This was demonstrated in a real-world test by NVIDIA which showed a single NVL72-based system gave about a 4× speedup over a similar H100-based cluster, largely thanks to communication efficiencies. The takeaway is that within a single NVL72 rack, communication is so fast that communication-bottlenecks become low-priority as they are almost completely eliminated. Whereas communication in traditional InfiniBand and Ethernet clusters is often the primary bottleneck and needs careful optimization and tuning at the software level.

In summary, one should design and implement software that exploits the NVL72 configuration by keeping as much of the workload’s communication inside the rack (“intra-rack”) as possible to take advantage of the high speed NVLink and NVSwitch hardware. Only go use the slower, InfiniBand-or-Ethernet-based communication between racks (“inter-rack”) when absolutely necessary to scale beyond the NVL72’s compute and memory resources.

## In-Network Aggregations with NVIDIA SHARP

Another hardware-enabled optimization is [NVIDIA SHARP](https://developer.nvidia.com/blog/advancing-performance-with-nvidia-sharp-in-network-computing/) which stands for Scalable Hierarchical Aggregation and Reduction Protocol. SHARP is integrated directly into NVSwitch hardware and capable of performing aggregations (e.g. all-reduce, all-gather, and broadcast) directly in the network hardware itself. The NVSwitch fabric combines partial results without the data needing to funnel through the GPUs. By offloading collective communication operations from the GPUs and CPUs to the switch hardware itself, SHARP dramatically boosts efficiency, lowers latency, and reduces the volume of data traversing the network.

SHARP’s increased efficiency means that during distributed training, the heavy lifting of aggregating gradients or synchronizing parameters is handled by the NVSwitch’s dedicated SHARP engines. The result is much-more efficient scaling across both intra-rack and inter-rack configurations. SHARP enables near-linear performance improvements even as the number of GPUs grows. This in-network computing capability is especially critical for training ultra-large models, where every microsecond saved on collective operations can translate into substantial overall speedups.

## Multi-Rack and Storage Communication

Next, let’s discuss how an NVL72 rack talks to another NVL72 - or to an external storage system like a shared file system. As we have shown, inside the NVL72 rack, NVLink covers all GPU-to-GPU traffic. But outside the rack, it relies on more traditional networking hardware.

Each compute node in NVL72 is equipped with high-speed Network Interface Cards and a Data Processing Unit (DPU). In the GB200 NVL72 reference design, each node has four ConnectX InfiniBand NICs and one BlueField-3 DPU. Each of the four InfiniBand NICs runs at 400 Gb/s each. Combined, these NICs send and receive data on the order of 1.6 Tbit/s (1600 Gbit/s) to the outside world as shown in [Figure 2-8](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch02.html#ch02_figure_8_1744914895521653).

![Diagram shows an NVIDIA HGX Grace Hopper Superchip with Infiniband networking system. There is hardware coherency within each Grace Hopper Superchip. Each Superchip is connected with a BlueField 3 DPU through PCIe, which are then connected at 100 GB/s total bandwidth with NVIDIA Quantum-2 InfiniBand NDR400 Switches.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9798341627772/files/assets/ch02_figure_8_1744914895521653.png)

###### Figure 2-8. InfiniBand and BlueField DPU NICs

Across the 18 computes nodes in a single rack, the total outside-rack throughput is nearly 30 Tbit/s (1.6 Tbit/s * 18 compute nodes) of aggregate networking capacity when fully utilized. The key is that NVIDIA anticipates multi-rack deployments called “AI factories.” – so they’ve made sure the NVL72 can plug into a larger network fabric via these 4 NICs per node.

###### Tip

NVIDIA also offers an Ethernet-based solution using Spectrum switches with RDMA over Converged Ethernet (RoCE) as an alternative for interconnect, called Spectrum-X.

The BlueField-3 DPU in each node helps offload networking tasks like RDMA, TCP/IP, and NVMe storage access. This makes sure the Grace CPU isn’t bogged down managing network interrupts. The DPU essentially serves as a smart network controller, moving data directly between NICs and GPU memory using NVIDIA’s RDMA software called GPUDirect which does not require CPU involvement. This is especially useful when streaming large datasets from a storage server as the DPU can handle the transfer and deposit data directly into GPU memory while the CPU focuses on other tasks like data preprocessing.

When scaling out to multiple NVL72 racks, NVIDIA uses Quantum-series InfiniBand switches. Multiple NVL72 racks can be interconnected using these InfiniBand switches to form a large cluster of NVL72 racks as shown in [Figure 2-9](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch02.html#ch02_figure_9_1744914895521673).

![Diagram shows an NVIDIA HGX Grace Hopper with NVLink Switch System . There is hardware coherency within each Grace Hopper Superchip. Each Grace Hopper Superchip within a cluster of up to 256 Grace Hopper Superchips is connected with each other via the NVLink Switch System. Each Superchip is also connected with a BlueField 3 DPU through PCIe, which are then connected at 100 GB/s total bandwidth with NVIDIA Quantum-2 InfiniBand NDR400 Switches.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9798341627772/files/assets/ch02_figure_9_1744914895521673.png)

###### Figure 2-9. Scaling out NVL72 cluster with InfiniBand

For example, an 8-rack NVL72 cluster totaling 576 GPUs can be built with a second tier of InfiniBand switches, though the performance for cross-rack InfiniBand communication will be lower than the NVLink/NVSwitch communication within a single rack.

## Pre-Integrated Rack Appliance

Because NVL72 is such a complex system, NVIDIA delivers it as a pre-integrated rack “appliance” in a single cabinet. It comes assembled with all 18 compute nodes, all 9 NVSwitch units, internal NVLink cabling, power distribution, and a cooling system. The idea is that an organization can order this as a unit that is ready to go when it arrives. One simply connects the rack to facility power, hooks up the water cooling interfaces, connects the InfiniBand cables to your network, and turns it on! There is no need to individually cable 72 GPUs with NVLink as NVIDIA has already done this inside the rack for you. Even the liquid cooling setup is self-contained as we’ll discuss soon.

This appliance approach accelerates deployment and ensures that the system is built correctly and validated by NVIDIA. The rack also includes its NVIDIA Base Command Manager cluster-management software - as well as SLURM and Kubernetes for cluster-job scheduling and orchestration. In other words, the NVL72 rack is designed to be dropped-in to your environment and .

## Co-Packaged Optics: Future of Networking Hardware

As networking data throughput rates climb to 800 Gbit/s and beyond, the traditional approach of pluggable optical modules starts to hit power and signal limits. This burns a lot of power as it converts electrical signals to optical at the switch. NVIDIA is addressing this by integrating co-packaged optics (CPO) into its networking gear.

With co-packaged optics, the optical transmitters are integrated right next to the switch silicon. This drastically shortens electrical pathways, enabling even higher bandwidth links between racks, reduces power draw, and improves overall communication efficiency. NVIDIA is integrating CPO into its Quantum-3 InfiniBand switches scheduled for late 2025 or 2026.

In practical terms, technologies like CPO are paving the way to connect hundreds and thousands of racks (“AI factories”) into a single unified fabric in which inter-rack bandwidth is no longer the bottleneck. Such optical networking advancements are crucial to the high-performance, inter-rack bandwidth needed to ensure that the network can keep up with the GPUs at ultra-scale.

To summarize, inside an NVL72 rack, NVIDIA uses NVLink and NVSwitch to create a blazingly fast, all-to-all connected network between 72 GPUs. These interconnects are so fast and uniform that the GPUs effectively behave like one unit. Beyond the rack, high-speed NICs (e.g. InfiniBand or Ethernet) connect the rack to other racks or to storage, with DPUs to manage data movement efficiently.

The NVL72 is an immensely powerful standalone system and a basic building block for larger AI supercomputers. NVIDIA partners with cloud providers like CoreWeave, Lambda Labs, AWS, Google Cloud, Azure, and Equinix to offer NVL72-based racks that companies can rent or deploy quickly.

The concept of an AI factory, a large-scale AI data center composed of multiple such racks, is now becoming reality. NVIDIA’s hardware and network roadmap is squarely aimed at enabling the AI factory vision. In short, the NVL72 shows how far co-design can go as the GPU, networking, and physical-rack hardware are built hand-in-hand to scale to thousands and millions of GPUs as seamlessly and efficiently as possible.

# Compute Density and Power Requirements

The NVL72 rack is incredibly dense in terms of compute, which means it draws a very high amount of power for a single rack. A fully loaded NVL72 can consume up to about 120 kW of power under max load. This is NVIDIA’s previous generation AI rack which consumed around 50–60 kW. Packing 72 bleeding-edge GPUs - and all the supporting hardware - into one rack pushes the limits of what data center infrastructure can handle.

To supply 120 kW to the NVL72 rack, you can’t just use a single standard power feed. Data centers will typically provision multiple high-capacity circuits to feed this kind of power. For instance, one might push two separate power feeds into the rack for redundancy where each feed is capable of 60 kW. Under normal operation, the load is balanced between the feeds. And if one feed fails, the system could shed some load or throttle the GPUs to stay within the remaining feed’s capacity. This kind of redundancy is important to protect against a blown circuit halting your multi-month training job.

Within the rack, power is distributed to the power supplies of each 1U compute node. The power is converted from AC to DC for the local electronics. Each compute node in the NVL72 contains 2 Grace-Blackwell superships which together consume on the order of 5-6 kW. With 18 compute nodes, the total power consumed is about 100 kW. The NVSwitch trays, network switches, and cooling pumps account for approximately 20 kW for a total of 120 kW consumed by the entire NVL72 rack.

The current used at typical data center voltages (e.g. 415 V 3-phase AC) is massive, so everything is engineered for high amperage. Operators have to carefully plan to host such a rack which often requires dedicated power distribution units (PDUs) and careful monitoring. Power transients are also a consideration as 72 GPUs, when ramping from idle to full power, could rapidly draw tens of kW of power in just milliseconds. A good design will include capacitors or sequencing to avoid large voltage drops.

The system might stagger the GPU boost clocks by tiny intervals, so they don’t all spike at exactly the same microsecond, smoothing out the surge. These are the kind of electrical engineering details that go into making a 120 kW rack manageable.

It’s not far-fetched to call this NVL72 rack, at the cutting edge of high-density compute, a mini power substation. 8 of these racks combined for 572 GPUs would draw nearly 1 MW of power (8 racks * 120 kW per rack) which is the entire capacity of a small data center! The silver lining is that although 120 kW is a lot in one rack, you are also getting a lot of work done per watt. In fact, if one NVL72 replaces several racks of older equipment, the overall efficiency is better. But you definitely need the infrastructure to support that concentrated power draw. And any facility hosting the NVL72 racks must ensure they have adequate power capacity and cooling as we will discuss next.

## Liquid Cooling vs. Air Cooling

Cooling 120 kW in one rack is beyond the reach of traditional air cooling. Blowing air over 72 GPUs that each can dissipate 1000+ watts would require hurricane-like airflow and would be extremely loud and inefficient - not to mention the hot air exhaust would be brutal. As such, liquid cooling is the only practical solution for the NVL72 rack running at this power density.

The NVL72 is a fully liquid-cooled system. Each Grace-Blackwell superchip module and each NVSwitch chip has a cold plate attached. A cold plate is a metal plate with internal tubing that sits directly on the component. A water-based coolant liquid flows through the tubing to carry away heat. All these cold plates are linked by hoses, manifolds, and pumps that circulate the coolant throughout the system.

Typically, the rack will have quick-disconnect couplings for each node so you can slide a server in or out without spilling the coolant. The rack then has supply and return connections to the external facility’s chilled water system. Often, there’s a heat exchanger called a Cooling Distribution Unit (CDU) either built into the rack or immediately next to it. The CDU transfers heat from the rack’s internal coolant loop to the data center’s water loop.

The facility provides chilled water at 20-30°C. The water absorbs the heat through the heat exchanger. The warmed-up water is then pumped back into the chillers or cooling towers to be cooled again. In modern designs, they might even run warm water cooling in which chilled water comes into the system at 30°C and leaves at 45°C. The water can then be cooled by evaporative cooling towers without active refrigeration which improves overall efficiency. The point is, water or a liquid coolant, can carry far more heat per unit of flow than air, so liquid cooling is vastly more effective when running at high watts in small spaces.

By keeping the GPU and CPU temperatures much lower than they would be with air, liquid cooling reduces thermal GPU throttling. The GPUs can sustain their maximum clocks without hitting temperature limits. Also, running chips cooler improves reliability and even efficiency since power leakage is lower when running at lower temperatures.

The NVL72 keeps GPU temps in the 50-70°C range under load which is excellent for such power-hungry devices. The cold plates and coolant loops have been engineered very carefully to allow each GPU to dump 1000 W and each CPU to dump 500 W into the system. In addition, the coolant flow rate has to be sufficient to remove that heat quickly. A rough estimate shows on the order of 10+ liters per minute of water flowing through the system to dissipate 120 kW of power with a reasonable temperature increase.

The system undoubtedly has sensors and controls for coolant temperature, pressure, and leak detection. If a leak is detected from its drip or pressure-loss sensors, the system can shut down or isolate that section quickly. It’s recommended to use self-sealing connections - and perhaps a secondary containment tray - to minimize the risk of leaking fluids.

This level of liquid cooling in racks was once exotic, but it is now the standard for these large scale AI clusters. Companies like Meta, Google, and Amazon are all adopting liquid cooling for their AI clusters because air cooling simply cannot support the large amount of power drawn from these systems.

So while an NVL72 requires more facility complexity including liquid-cooling loops, many data centers are now built with liquid cooling in mind. The NVL72 rack, with its built-in internal liquid cooling, can be connected directly to the cooling loop.

One side effect of the internal liquid cooling is the weight of the rack. The NVL72 rack weighs on the order of 3000 lbs (1.3–1.4 metric tons) when filled with hardware and coolant. This is extremely heavy for a rack as it’s roughly the weight of a small car, but concentrated on a few square feet of floor. Data centers with raised floors have to check that the floor can support this load measured in pounds per square foot. Often, high-density racks are placed on reinforced slabs or supported by additional struts. Moving such a rack requires special equipment such as forklifts. This is all part of the deployment consideration as you’re installing an AI supercomputer which comes with its unique physical and logistical challenges.

NVIDIA also integrates management and safety features in the form of a rack management controller that oversees things like coolant pumps, valve positions, power usage, and monitors every node’s status. Administrators can interface with it to do things like update firmware across all nodes, or to shutdown the system safely.

All these considerations illustrate that the NVL72 was co-designed with data center infrastructure in mind. NVIDIA worked on the compute architecture in tandem with system engineers who figured out power delivery and cooling, and in tandem with facility engineers who specified how to install and run these things. It’s not just about fast chips - it’s about delivering a balanced, usable system.

The payoff for this complexity is huge. By pushing the limits of power and cooling, NVIDIA managed to concentrate an enormous amount of compute into a single rack. That translates to unprecedented compute-per-square-foot and compute-per-watt. Yes, 120 kW is a lot of power, but per GPU or per TFLOP, it’s actually efficient compared to spreading the same GPUs across multiple racks with less efficient cooling.

# Performance Monitoring and Utilization in Practice

When you have a machine this powerful and expensive, you want to make sure you’re getting the most out of it. Operating an NVL72 effectively requires careful monitoring of performance, utilization, and power. NVIDIA provides tools like DCGM (Data Center GPU Manager) that can track metrics on each GPU for things like GPU utilization %, memory usage, temperature, and NVLink throughput.

As a performance engineer, you’d keep an eye on these during training runs and inference workloads. Ideally, you want your GPUs to be near 100% utilized most of the time during a training job. If you see GPUs at 50% utilization, that means something is keeping them idle for half the time. Perhaps there is a data loading bottleneck or a synchronization issue.

Similarly, you can monitor the NVLink usage. If your NVLink links are saturating frequently, communication is likely the culprit. The BlueField DPUs and NICs have their own statistics that are monitored to ensure that you’re not saturating your storage links when reading data. Modern systems like the NVL72 expose this telemetry.

Power monitoring is also crucial. At ~120 kW, even a small inefficiency or misconfiguration can waste a lot of power and money. The system likely lets you monitor power draw per node or per GPU. Administrators might cap the power or clocks of GPUs if full performance isn’t needed, to save energy.

NVIDIA GPUs allow setting power limits. For instance, if you’re running a smaller job that doesn’t need every last drop of performance, you could dial down GPU clocks to improve efficiency - measured in performance per watt - and still meet your throughput requirement. This could save kilowatts of power in the process. Over weeks of training, this can translate to significant savings and cost efficiency.

# Sharing and Scheduling

Another aspect is sharing and scheduling workloads on the NVL72. Rarely will every single job need all 72 GPUs. You might have multiple teams or multiple experiments running on subsets of GPUs. Using a cluster scheduler like SLURM or Kubernetes with NVIDIA’s plugins, you can carve out say 8 GPUs for one user, 16 GPUs for another user, and 48 GPUs for yet another user - all within the same rack.

Furthermore, NVIDIA’s Multi-Instance GPU (MIG) feature lets you split a single physical GPU into smaller GPUs partitioned at the hardware level. For example, one Blackwell GPU with 192 GB of GPU memory could be split into smaller chunks to run many small inference jobs concurrently. For instance, the 192 GB of GPU memory can be split into four 24 GB partitions and two 48 GB partitions (4 * 24 + 2 * 48 = 192 GB). Similarly, the GPU’s SMs can be split into partitions along with the GPU HBM memory.

In practice, with such a large GPU, MIG might be used for inference scenarios where you want to serve many models on one GPU. The presence of the BlueField DPU also enables secure multi-tenancy as the DPU can act as a firewall and virtual switch. This isolates network traffic for different jobs and users. This means an organization could safely let different departments or even external clients use partitions of the system without interfering with each other - similar to how cloud providers partition a big server for multiple customers with secure multi-tenant isolation.

From a cost perspective, a system like NVL72 is a multi-million dollar asset, and it could consume tens of thousands of dollars in electricity per month. So you really want to do as much useful work, or goodput, as possible. If it sits idle, that’s a lot of capital and operational cost wasted. This is why monitoring utilization over time is important. You might track GPU-hours used vs. available hours.

If you find that the system is underutilized, you might want to consolidate workloads or offer it to additional teams for more projects. Some organizations implement a chargeback model where internal teams use their own budget to pay per GPU-hour of usage. This encourages efficient use and accounts for electricity and depreciation costs. Such transparency ensures that people value the resource. After all, 1 hour on all 72 GPUs could be, say, 72 GPU-hours which might cost hundreds of dollars worth of electricity and amortized hardware cost.

# ROI of Upgrading Your Hardware

One might ask if it’s worth investing in this bleeding-edge hardware. When analyzing the return on investment (ROI), the answer often comes down to performance per dollar. If NVL72 can do the work of, say, four older-generation racks, it might actually save money long-term, both in hardware and power. Earlier in the chapter, we discussed how one Blackwell GPU could replace 2–3 Hopper GPUs in terms of throughput. This means if you upgrade, you might need fewer total GPUs for the same work.

Let’s analyze a quick case study. Suppose you currently have a hundred H100 GPUs handling your workload. You could potentially handle it with 50 Blackwell GPUs because each is more than twice as fast (or more using FP8/FP4). So you’d buy fifty instead of one hundred GPUs. And even if each Blackwell costs more than an H100, buying half as many could be cost-neutral or better. Power-wise, one hundred H100s might draw 70 kW whereas fifty Blackwells might draw 50 kW for the same work. This is a notable power savings.

Over a year, that power difference saves tens of thousands of dollars. Additionally, fewer GPUs means fewer servers to maintain, which means less overhead in CPUs, RAM, and networking for those servers provides even further savings. All told, an upgrade to new hardware can pay for itself in 1–2 years in some cases, if you have enough workload to keep it busy.

The math obviously depends on exact prices and usage patterns, but the point is that the ROI for adopting the latest AI hardware can be very high for large-scale deployments. Besides the tangible ROI, there are soft benefits like using a single powerful system instead of many smaller ones can simplify your system architecture. This simplification improves operational efficiency by lowering power consumption and reducing network complexity.

For example, not having to split models across multiple older GPUs due to memory limits can simplify software and reduce engineering complexity. Also, having the latest hardware ensures you can take advantage of the newest software optimizations and keep up with competitors who also upgrade. Nobody wants to be left training and serving models at half the speed of rivals. Upgrading will improve your performance while simultaneously enabling larger models, faster iterations, and quicker responses.

Running an NVL72 effectively is as much a software and management challenge as it is a hardware feat. The hardware gives you incredible potential, but it’s up to the engineers to harness the full power of the hardware by monitoring performance, keeping utilization high, and scheduling jobs smartly.

The good news is NVIDIA provides a rich software stack to monitor and improve performance including drivers, profilers, container runtimes, and cluster orchestration tools. Throughout the rest of the book, we’ll see how to optimize software to fully utilize systems like the GB200 NVL72. For now, the takeaway is that when you’re given an AI system with exaflop-scale performance in a box, you need equally advanced strategies to make every flop and every byte count.

# A Glimpse into the Future: NVIDIA’s Roadmap

At the time of writing, the Grace-Blackwell NVL72 platform represents the state-of-the-art in AI hardware. But NVIDIA is, of course, already preparing the next leaps. It’s worth briefly looking at NVIDIA’s hardware roadmap for the coming few years, because it shows a clear pattern of scaling. NVIDIA intends to continue doubling down on performance, memory, and integration.

## Blackwell Ultra and Grace-Blackwell Ultra (Late 2025)

In March 2025, NVIDIA announced an enhanced version of Blackwell called the Blackwell “Ultra” (B300) and corresponding Grace-Blackwell Ultra superchip (GB300). These Ultra versions are planned for late 2025, and they will be a drop-in upgrade to the NVL72 architecture. Each Blackwell Ultra GPU is expected to have about 50% more performance than the current B200, and also increase memory from 192 GB to 288 GB per GPU.

A GB300 superchip module would have 1 Grace CPU + 2 Blackwell Ultra GPUs with a total of 576 GB total HBM GPU memory (2 * 288 GB = 576 GB) plus the Grace CPU’s 480GB of DDR memory. That’s over 1 TB of memory per Grace-Blackwell Ultra superchip module. A 72 GPU rack of these superchips will have around 20 TB of combined GPU and CPU memory.

The intra-rack NVLink and NVSwitch networks in the GB300 NVL72 Ultra are based on the same NVLink 5 generation as the GB200 NVL72. The GB300 NVL72 Ultra delivers on the order of 1.1+ exaFLOPS of FP4 performance per rack – nudging it even further into the exascale regime.

The GB300 NVL72 Ultra Power and cooling draws 120 kW and uses liquid cooling, but the benefit is more compute and memory in the same footprint as the GB200 NVL72. NVIDIA claims a 1.5× improvement at the rack level for generative AI workloads relative to GB200, thanks to the beefier GPUs and the generous usage of FP4 precision. NVIDIA is targeting use cases like real-time AI agents and multi-modal models that demand maximum throughput. Essentially, the GB300 is an evolutionary upgrade as it uses the same architecture, but has more of everything including more SMs, more memory, and faster clocks.

## Vera-Rubin Supership (2026)

Codenamed after scientists Vera Rubin, the Vera-Rubin superchip (VR200) is the next major architecture step expected in 2026. Vera is the ARM-based CPU successor to the Grace CPU, and Rubin is the GPU architecture successor to Blackwell. NVIDIA continues the superchip concept by combining one Vera CPU with two Rubin GPUs in a single module (VR200) similar to the Grace-Blackwell (GB200) configuration.

The Vera CPU is expected to use TSMC’s 3nm semiconductor process with more CPU cores and faster memory such as of LPDDR6 or some form of GPU-like high-bandwidth memory (HBM) designed for CPUs. This could push CPU memory bandwidth toward 1 TB/s. The Rubin GPU is expected to use HBM4 memory with bandwidth per GPU jumping to maybe 13–14 TB/s.

NVLink is also expected to move to its 6th generation NVLink 6 which would double the CPU-to-GPU and GPU-to-GPU link bandwidth. There’s also speculation that Vera-Rubin could allow more nodes per rack - or more racks per NVLink domain - to scale beyond the 576 GPU limit of the 8-rack GB200 NVL72 cluster, but the details are not confirmed as of this writing.

The bottom line is that the Vera-Rubin generation is yet another ~2× jump in most metrics including more cores, more memory, more bandwidth, and more TFLOPS. Rubin GPUs might increase SM counts significantly to around 200 SMs per die. This is up from 140-ish in Blackwell. This could further add efficiency improvements. They could also integrate new features like second-generation FP4 or even experimental 2-bit precisions, though that’s just speculation at this point.

Another especially interesting possibility is that, because Rubin’s expected 288 GB HBM RAM is still a bottleneck for large AI models, NVIDIA might incorporate some second-tier memory for GPUs directly in the GPU module. For instance, they may place some LPDDR memory directly on the base of the GPU module to act as an even larger, but slower, memory pool for the GPU - separate from Vera’s CPU DDR memory. If this happens, a single GPU module could have >500 GB (256 GB HBM + 256 GB LPDDR) of total cache-coherent, unified memory. This would further blur the line between CPU and GPU memory, as GPUs would have a multi-tier memory hierarchy of their own. Whether this happens in Rubin or not, it’s a direction to keep an eye on.

Overall, a Vera-Rubin rack might deliver maybe 1.5× to 2× the performance of a GB200 NVL72 running at similar - or slightly higher power. It might also increase total memory per rack significantly - perhaps 20+ TB of HBM across 72 Rubin GPUs (288 GB HBM per GPU * 72 GPUs) plus tens of TB of CPU memory. NVLink 6 within the rack would yield even less communication overhead, making 72 or more GPUs behaving as a single, tightly coupled unit.

## Rubin Ultra and Vera-Rubin Ultra (2027)

Following the pattern, an “Ultra” version of Rubin (R300) and Vera-Rubing is expected to arrive a year after the original release. One report suggests that NVIDIA might move to a 4-die GPU module by then. This would combine two dual-die Rubin packages and put them together to yield a quad-die Rubin GPU. This hypothetical R300 GPU module would have 4 GPU dies on one package and likely 16 HBM stacks totaling 1 TB of HBM memory on a single R300 GPU module. The 4 dies together would roughly double the cores of the dual-die B300 module. This could provide nearly 100 PFLOPS of FP4 per GPU module!

Now, how do you integrate such modules? Possibly they would reduce the number of modules per rack but increase GPUs per module. In particular, they might have 144 of those dies across the rack which could be 36 modules of 4 dies each, or something equivalent. There is also mention of an NVL576 configuration implying 576 GPUs in one NVLink domain. By 2027, each rack could be pushing 3-4 exaFLOPs of compute performance and a combined 165 TB of GPU HBM RAM (288 GB HBM per Rubin GPU * 576 GPUs). While these numbers are speculative, the trajectory toward ultra-scale AI systems with a massive number of exaFLOPs for compute and terabytes for GPU HBM RAM is clear.

## Feynmann GPU (2028) and Doubling Something Every Year

NVIDIA has code-named the post-Rubin generation as Feynmann which is scheduled for a 2028 release. Details are scarce, but the Fenmann GPU will likely move to an even finer 2nm TSMC process node. It will likely use HBM5 and include even more DDR memory inside the module. And perhaps it will double the number of dies from 4 to 8.

By 2028, it’s expected that inference demands will surely dominate AI workloads - especially as reasoning continues to evolve in AI models. Reasoning requires a lot more inference-time computation than previous, non-reasoning models. As such, chip designs will likely optimize for inference efficiency at scale which might include more novel precisions, more on-chip memory, and on-package optical links to improve NVLink’s throughput even further.

NVIDIA seems to be doubling something every generation, every year if possible. One year they double memory, another year they double the number of dies, another year they double interconnect bandwidth, and so on. Over a few years, the compound effect of this doubling is huge. Indeed, from 2024 to 2027, one will notice NVIDIA’s aggressive upward curve by doubling from 72 GPUs → 144 dies, double NVLink throughput from 900 GB/s → 1.8 TB/s, and doubling memory per GPU from 192 GB → 288 GB.

NVIDIA repeatedly talks about “AI factories” where the racks are the production lines for AI models. NVIDIA envisions offering a rack as-a-service through its partners so companies can rent a slice of a supercomputer rather than building everything themselves. This trend will likely continue as the cutting-edge hardware will be delivered as integrated pods that you can deploy. And each generation allows you to swap in new pods to double your capacity, increase your performance, and reduce your cost.

For us as performance engineers, what matters is that the hardware will keep unlocking new levels of scale. Models that are infeasible today might become routine in a few years. It also means we’ll have to continually adapt our software to leverage things like new precision formats, larger memory pools, and improved interconnects. This is an exciting time as the advancement of frontier models is very much tied to these hardware innovations.

# Key Takeaways

The following innovations collectively enable NVIDIA’s hardware to handle ultra-large AI models with unprecedented speed, efficiency, and scalability.

Integrated Superchip Architecture.Nvidia fuses ARM-based CPUs (Grace) with GPUs (Hopper/Blackwell) into a single “superchip,” which creates a unified memory space. This design simplifies data management by eliminating the need for manual data transfers between CPU and GPU.

Unified Memory Architecture.The unified memory architecture and coherent interconnect reduce the programming complexity. Developers can write code without worrying about explicit data movement, which accelerates development and helps focus on improving AI algorithms.

Ultra-Fast Interconnects.Using NVLink (including NVLink-C2C and NVLink 5) and NVSwitch, the system achieves extremely high intra-rack bandwidth and low latency. This means GPUs can communicate nearly as if they were parts of one large processor, which is critical for scaling AI training and inference.

High-Density, Ultra-Scale System (NVL72).The NVL72 rack integrates 72 GPUs in one compact system. This consolidated design supports massive models by combining high compute performance with an enormous unified memory pool, enabling tasks that would be impractical on traditional setups.

Advanced Cooling and Power Management.Operating at around 120 kW per rack, NVL72 relies on sophisticated liquid cooling and robust power distribution systems. These are essential for managing the high-density, high-performance components and ensuring reliable operation.

Significant Performance and Efficiency Gains.Compared to previous generations such as the Hopper H100, Blackwell GPUs offer roughly 2 - 2.5× improvements in compute and memory bandwidth. This leads to dramatic enhancements in training and inference speeds - up to 30× faster inference in [some cases](https://developer.nvidia.com/blog/nvidia-gb200-nvl72-delivers-trillion-parameter-llm-training-and-real-time-inference/) - as well as potential cost savings through reduced GPU counts.

Future-Proof Roadmap.Nvidia’s development roadmap (including Blackwell Ultra, Vera-Rubin, Vera-Rubin Ultra, and Feynman) promises continual doubling of key parameters like compute throughput and memory bandwidth. This trajectory is designed to support ever-larger AI models and more complex workloads in the future.

# Conclusion

The NVIDIA NVL72 system - with its Grace-Blackwell superchips, NVLink fabric, and advanced cooling – exemplifies the cutting edge of AI hardware design. In this chapter, we’ve seen how every component is co-designed to serve the singular goal of accelerating AI workloads. The CPU and GPU are fused into one unit to eliminate data transfer bottlenecks and provide a gigantic unified memory.

Dozens of GPUs are wired together with an ultra-fast network so they behave like one colossal GPU with minimal communication delay. And the memory subsystem is expanded and accelerated to feed the voracious appetite of the GPU cores. Even the power delivery and thermal management are pushed to new heights to allow this density of computing.

The result is a single rack that delivers performance previously only seen in multi-rack supercomputers. NVIDIA took the entire computing stack – chips, boards, networking, cooling – and optimized it end-to-end to allow training and serving massive AI models at ultra-scale.

But such hardware innovations come with challenges as you need specialized facilities, careful planning for power and cooling, and sophisticated software to utilize it fully. But the payoff is immense. Researchers can now experiment with models of unprecedented scale and complexity without waiting weeks or months for results.

A model that might have taken a month to train on older infrastructure might train in a few days on NVL72. Inference tasks that were barely interactive (seconds per query) are now a real-time (milliseconds) reality. This opens the door for AI applications that were previously impractical such as multi-trilion parameter interactive AI assistants and agents.

NVIDIA’s rapid roadmap suggests that this is just the beginning. The Grace-Blackwell architecture will evolve into Vera-Rubin and Feynmann and beyond. As NVIDIA’s CEO, Jensen Huang, describes, “AI is advancing at light speed, and companies are racing to build AI factories that can scale to meet the demand.”

The NVL72 and its successors are the core of the AI factory. It’s the heavy machinery that will churn through mountains of data to produce incredible AI capabilities. As performance engineers, we stand on the shoulders of this hardware innovation. It gives us a tremendous raw capability as our role is to harness this innovation by developing software and algorithms that make the most of the hardware’s potential.

In the next chapter, we will transition from hardware to software. We’ll explore how to optimize the operating systems, drivers, and libraries on systems like NVL72 to ensure that none of this glorious hardware goes underutilized. In later chapters, we’ll look at memory management and distributed training/inference algorithms that complement the software architecture.

The theme for this book is co-design. Just as the hardware was co-designed for AI, our software and methods must be co-designed to leverage the hardware. With a clear understanding of the hardware fundamentals now, we’re equipped to dive into software strategies to improve AI system performance. The era of AI supercomputing is here, and it’s going to be a thrilling ride leveraging it to its fullest.

Let’s dive in!
