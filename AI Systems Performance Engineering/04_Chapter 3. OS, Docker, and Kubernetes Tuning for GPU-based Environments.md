# Chapter 3. OS, Docker, and Kubernetes Tuning for GPU-based Environments

# A Note for Early Release Readers

With Early Release ebooks, you get books in their earliest form—the author’s raw and unedited content as they write—so you can take advantage of these technologies long before the official release of these titles.

This will be the 3rd chapter of the final book.

If you’d like to be actively involved in reviewing and commenting on this draft, please reach out to the editor at *arufino@oreilly.com*.

Even with highly optimized GPU code and libraries, system-level bottlenecks can limit performance in large-scale AI training. The fastest GPU is only as good as the environment feeding it data and instructions. In this chapter, we explore how to tune the operating system and container runtime to let GPUs reach their full potential.

In this chapter, we begin by exploring the foundational GPU software stack. We then dive into key CPU and memory optimizations such as NUMA affinity and huge pages. These ensure that data flows efficiently from storage through the CPU to the GPU. In parallel, we discuss critical GPU driver settings like persistence mode, Multi-Process Service, and Multi-Instance GPU partitions. These help maintain maximum GPU utilization by reducing overhead and synchronizing resources effectively.

Using solutions like the NVIDIA Container Toolkit, Container Runtime, Kubernetes Topology Manager, and the Kubernetes GPU Operator, you can create a unified and highly-optimized software stack for GPU environments. These solutions enable efficient resource allocation and workload scheduling across single-node and multi-node GPU environments - and ensures GPU capabilities are fully utilized.

Along the way, you’ll build intuition for why these optimizations matter. In essence, they minimize latency, maximize throughput, and ensure your GPUs are constantly fed with data and operating at their peak performance. The result is a robust, scalable system delivers significant performance gains for both training and inference workloads.

# Operating System

The operating system is the foundation that everything runs on. GPU servers usually run a Linux distribution such as Ubuntu and Red Hat with an OS kernel configured to support the specific hardware. The NVIDIA driver installs kernel modules that allow the OS to interface with GPUs by creating device files like `/dev/nvidia0`. The OS also manages CPU scheduling, memory allocation, networking, and storage. All of which need to be tuned for better GPU usage.

The OS needs to be configured not to interfere with GPU tasks. For instance, by default Linux might be overly aggressive in swapping memory or might not be aware of Non-Uniform Memory Access (NUMA) when scheduling threads. Both can hurt GPU performance. Part of our job is to adjust those OS settings to create a smooth runway for the GPUs.

A GPU-focused server might also want to run additional daemons, or background processes, such as the NVIDIA Persistence Daemon to keep GPUs initialized, the Fabric Manager on systems with NVSwitch to manage the GPU interconnect topology, and NVIDIA Data Center GPU Manager (DCGM) for monitoring GPU system health metrics.

# GPU Driver and Software Stack

Running a multi-petaFLOP GPU cluster involves more than just writing high-level PyTorch, TensorFlow, or JAX code. There is a whole software stack underpinning GPU operations, and each layer can affect performance. At the base is the NVIDIA GPU driver which interfaces between the Linux OS and the GPU hardware. The driver manages low-level GPU operations including memory allocation on the device, task scheduling on GPU cores, and partitioning the GPU for multi-tenant usage.

## GPU Driver

The GPU driver turns on the GPUs’ features and keeps the hardware fed with work. It’s important to keep the driver up-to-date as new driver versions often provide performance improvements and additional support for the latest CUDA features. Tools like `nvidia-smi` come with the driver and allow you to monitor temperatures, measure utilization, query error-correcting code (ECC) memory status, and enable different GPU modes like persistence mode.

## CUDA Toolkit and Runtime

On top of the driver sits the CUDA runtime and libraries called the CUDA Toolkit. The toolkit includes the CUDA compiler, `nvcc`, used to compile CUDA C++ kernels as we will see in the next chapter. When compiled, CUDA programs link against the CUDA runtime (`cudart`). The CUDA runtime communicates directly with the NVIDIA driver to launch work and allocate memory on the GPU.

Additionally, the CUDA toolkit provides many optimized neural-network libraries including cuDNN for neural network primitives, cuBLAS for linear algebra, and NCCL for multi-GPU communication. These CUDA libraries provide high-performance building blocks for your higher-level code so that you don’t have to reinvent primitives like matrix multiply, for example, from scratch. We will cover CUDA programming and optimizations in more detail in upcoming chapters.

It’s important to understand your GPU’s compute capability (CC) and to ensure that you’re using the latest version of the CUDA Toolkit that matches this compute capability. The CUDA toolkit will perform just-in-time compilation of your GPU kernels, optimize your code for the specific GPU architecture, and upgrade your code to the latest hardware.

###### Tip

An important feature of GPU programming is that the generated PTX (a.k.a assembly code for GPUs) is backward-compatible with older NVIDIA GPU hardware and forward-compatible with newer hardware. This is a big selling point of the NVIDIA programming model, and it’s something that Jensen Huang, NVIDIA’s CEO, reiterates with every new hardware release.

## C++ and Python CUDA Libraries

While most of the CUDA toolkit libraries are C++ based, more and more Python-based libraries are emerging from NVIDIA that are prefixed with “Cu” and built upon the C++ toolkit. For instance, CuTile and CuPyNumeric are Python libraries launched in early 2025. They are targeted at lowering the barrier to entry for Python developers to build applications for NVIDIA GPUs using CUDA.

CuTile is a Python library designed to simplify working with large matrices on GPUs by breaking them into smaller, more manageable sub-matrices called “tiles”. It provides a high-level, tile-based abstraction that makes it easier to perform block-wise computations, optimize memory access patterns, and efficiently schedule GPU kernels. By dividing a large matrix into tiles, CuTile helps developers take full advantage of the GPU’s parallelism without needing to manage low-level details manually. This approach can lead to improved cache usage and overall better performance in applications that require intensive matrix computations.

CuPyNumeric is a drop-in replacement for the popular `numpy` Python library that utilizes the GPU. It provides nearly the same functions, methods, and behaviors as NumPy, so developers can often switch to it with minimal changes to their code. Under the hood, CuPyNumeric leverages CUDA to perform operations in parallel on the GPU. This leads to significant performance gains for compute-intensive tasks such as large-scale numerical computations, matrix operations, and data analysis. By offloading work to the GPU, CuPyNumeric accelerates computation and improves efficiency for applications handling massive datasets. Its goal is to lower the barrier for Python developers to harness GPU power without having to learn a completely new interface, making it a powerful drop-in alternative to NumPy for high-performance computing.

## PyTorch and Higher-Level AI Frameworks

Some popular Python-based frameworks built on CUDA are PyTorch, TensorFlow, JAX, and Keras. These frameworks provide high-level interfaces for deep learning while leveraging the power of NVIDIA GPUs. This book primarily focuses on PyTorch.

When you perform operations on PyTorch tensors using GPUs, they are moved from the CPU to the GPU in what appears to be a single, Python call. However, this single call is actually translated into a series of calls to the CUDA runtime utilizing various CUDA libraries. When you perform matrix multiplications, for example, PyTorch delegates these tasks to libraries such as cuBLAS. cuBLAS is part of the CUDA Toolkit and optimized for GPU execution. Behind the scenes, PyTorch ensures that operations like forward and backward passes are executed using low-level, optimized CUDA functions and libraries.

In short, PyTorch abstracts away the complexity of direct CUDA programming, allowing you to write intuitive Python code that ultimately calls highly optimized CUDA routines, delivering both ease of development and high performance. We will discuss CUDA programming and optimizations in chapters 4 and 5 - as well as PyTorch optimizations in Chapter 6.

All of these components – OS, GPU Driver, CUDA Toolkit, CUDA libraries, and PyTorch – must work together to create the ideal GPU-based development environment. When a researcher submits a training job, the scheduler reserves nodes, the OS provides the GPU devices and memory allocations using the NVIDIA driver, the container provides the correct software environment including the optimized, hardware-aware CUDA libraries. The user code (e.g. PyTorch, TensorFlow, JAX) uses these CUDA libraries which ultimately communicate with the driver and hardware.

The optimizations described in this chapter are designed to make each layer of this stack as efficient as possible. They will help the GPUs stay busy with actual useful training and inference work - instead of the GPU waiting on the CPU, waiting for memory or disk I/O, or waiting on other GPUs to synchronize. A well-tuned system ensures that models split across dozens of GPUs are not bottlenecked by I/O or OS overhead. System-level tuning is often overlooked in favor of model optimizations, but system-level optimizations can yield substantial performance gains. In some cases, you can get double-digit percentage improvements with small tweaks to your OS-level configuration. At the scale of a big AI project, this can save tens or hundreds of thousands of dollars in compute time.

# Configuring the CPUs and OS for GPU Environments

One of the most common reasons that GPUs don’t reach full utilization is that the CPU isn’t keeping them fed with useful work. In a typical training loop, the CPU is responsible for preparing the next batch of data including loading the data from disk, tokenizing the data, transforming it, etc. In addition, the CPU is responsible for dispatching GPU kernels and coordinating between threads and processes. If these CPU-side tasks are slow or if the OS schedules them poorly, the expensive GPU can find itself idle, twiddling its transistors, and waiting for the next task or batch of data. To avoid this, we need to optimize how the CPU and OS handle GPU workloads. This includes careful CPU affinity so the right CPU cores are working on the right data, proper memory-allocation strategies to avoid NUMA penalties, and other impactful OS-level settings to eliminate unnecessary delays as we’ll discuss next.

## NUMA Awareness and CPU Pinning

Modern server CPUs have dozens of cores and are often split into multiple Non-Uniform Memory Access nodes. A NUMA node is a logical grouping of CPUs, GPUs, NICs, and memory that are physically close to each other. Being aware of the system’s NUMA architecture is important for performance tuning. Accessing resources within a single NUMA node is faster than accessing resources in other NUMA nodes.

For example, if a process running on a CPU in NUMA node 0 needs to access a GPU in NUMA node 1, it will need to send data across an inter-node link which will incur higher latency. In fact, memory access latency can nearly double when crossing to the other NUMA nodes as one [experiment](https://frankdenneman.nl/2022/09/21/sub-numa-clustering/#:~:text=Latency%20,9) showed. This experiment measured 80 ns for local NUMA node memory access versus 139 ms when accessing memory across NUMA nodes. This is a huge difference. By binding a process to a CPU on the same NUMA node as its GPU, we can avoid this extra overhead. The key idea is to keep CPU execution and memory access local to the GPU that it’s serving.

###### Tip

It’s worth noting that, by default, the Linux scheduler will not use a NUMA-aware scheduling algorithm.

To prevent this, it’s crucial to “pin” processes or threads to specific CPUs that are connected to the same NUMA node as the GPU. This type of CPU affinity is often called CPU pinning. Suppose you have 8 GPUs in a node, with 4 GPUs connected to NUMA node 0 and the other 4 to NUMA node 1. If you launch 8 training processes, one per GPU, you should bind each training process to a CPU core - or set of CPU cores - connected to the same NUMA node as the GPUs. In this case, GPUs 0-3’s are connected to NUMA node 0 and GPUs 4-7’s are connected to NUMA node 1’s cores as shown in [Figure 3-1](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch03.html#ch03_figure_1_1744914896569296).

![A diagram of a network  AI-generated content may be incorrect.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9798341627772/files/assets/ch03_figure_1_1744914896569296.png)

###### Figure 3-1. 8 GPUs in a node, with 4 GPUs connected to NUMA node 0 and the other 4 to NUMA node 1

This way, when a CPU process wants to feed data to GPU 5, it should be running on a CPU connected to NUMA node 1 since GPU 5 is connected to NUMA node 1. Linux provides tools to do this including `numactl --cpunodebind=<node>` which launches a process pinned to the given NUMA node. You can also use `taskset` to pin processes to specific core IDs. Here is an example using `numactl` to bind the `train.py` script to a CPU running in the same NUMA node 1 as GPU 5.

```
numactl --cpunodebind=1 --membind=1 python train.py --gpu 5 &
```

The `--membind` part in that command is also important. We will discuss NUMA-friendly memory allocation and memory pinning in the next section.

Many deep learning frameworks also let you set thread affinities programmatically. For instance, PyTorch’s `DataLoader` allows setting CPU affinities for CPU-based worker processes as shown here.

```
import os
import psutil
import torch
import torch.distributed as dist
from torch.nn.parallel import DistributedDataParallel as DDP
from torch.utils.data import DataLoader, Dataset
				
# Set CPU affinity for the main process (the DDP process)
def set_main_process_affinity():
    available_cpus = list(range(psutil.cpu_count()))
    rank = int(os.environ.get("RANK", "0"))
    # For demonstration, pin the main process to one specific CPU based on its rank
    main_affinity = [available_cpus[rank % len(available_cpus)]]
    process = psutil.Process(os.getpid())
    process.cpu_affinity(main_affinity)
    print(f"Main process (rank {rank}) pinned to CPU core(s): {main_affinity}")
				
# Set CPU affinity for each DataLoader worker
def worker_init_fn(worker_id):
    available_cpus = list(range(psutil.cpu_count()))
    rank = int(os.environ.get("RANK", "0"))
    # Example mapping: assign each worker a CPU based on the rank and worker ID
    assigned_cpu = available_cpus[(rank * 10 + worker_id) % len(available_cpus)]
    process = psutil.Process(os.getpid())
    process.cpu_affinity([assigned_cpu])
    print(f"DataLoader worker {worker_id} (rank {rank}) pinned to CPU core {assigned_cpu}")
				
# main() function that combines DDP with a DataLoader using the affinity settings
def main():
    # Initialize the distributed process group as required 
    ...
    
    # Set affinity for the main DDP process
    set_main_process_affinity()
    
    # Create your dataset (Fictitious dataset)
    dataset = Dataset()
    
    # Create DataLoader with the worker_init_fn to set affinity for each worker
    dataloader = DataLoader(
        dataset,
        batch_size=32,
        num_workers=4,
        pin_memory=True,
        worker_init_fn=worker_init_fn # set affinity
    )
    
    # Create and move your model to the current device (GPU)
    model = torch.nn.Linear(224 * 224 * 3, 10)  # Example model
    model = model.to("cuda")
    
    # Wrap the model in DistributedDataParallel (DDP)
    ddp_model = DDP(model, device_ids=[
torch.cuda.current_device()
])
    
    # Training loop 
    ...
```

The `set_main_process_affinity()` function assigns the main DDP process to a specific CPU core based on the process rank. The `worker_init_fn()` function is passed to the DataLoader so that each worker subprocess is pinned to a specific CPU core. This minimizes cross-NUMA traffic and can improve data preprocessing and transfer efficiency.

In practice, pinning can eliminate unpredictable CPU scheduling behavior. It ensures that a critical thread such as a data-loading thread for your GPU doesn’t suddenly get migrated by the OS to a core on a different NUMA node in the middle of training or inferencing. In practice, it’s possible to see 5-10% training throughput improvements just by eliminating cross-NUMA traffic and CPU core migrations. This also tends to reduce performance jitter and variance.

Many high-performance AI systems will also disable CPU hyper-threading to get more predictable performance per CPU core. Some even reserve a few cores exclusively for OS background tasks so that the remaining cores are dedicated exclusively to the training or inference workloads.

It’s important to note that for integrated CPU-GPU superchips like NVIDIA’s Grace-Blackwell, many of the traditional concerns about CPU-to-GPU data transfer are alleviated because the CPU and GPU share the same physical memory and are part of a unified architecture. This means that issues like cross-NUMA delays are minimized, and the data can flow more directly between the CPU and GPU.

###### Tip

It’s not a coincidence that NVIDIA tackled the CPU-to-GPU bottleneck in their hardware by combining the CPU and GPU onto a single superchip. Expect NVIDIA to keep addressing more and more bottlenecks through hardware innovations.

Even with the tightly-coupled CPU-GPU superchip architecture, it’s still important to optimize the stack by ensuring that the hardware and software are configured properly so that the integrated system operates at peak efficiency. Even in these tightly coupled architectures, you want to minimize any unnecessary delays in data handling to keep the GPU fully utilized. This includes configuring huge pages, using efficiency prefetching, and pinning memory as you will see in the next sections.

## NUMA-Friendly Memory Allocation and Memory Pinning

By default, a process will allocate memory from the NUMA node of the CPU it’s currently running on. So if you pin a process to NUMA node 0, its memory will naturally come from NUMA node 0’s local RAM which is ideal. However, if the OS scheduler migrates threads - or if some memory got allocated before you did the pinning - you could end up with the non-ideal scenario in which a process running in NUMA node 0 is using memory from NUMA node 1. In this case, every memory access has to hop to the other NUMA node, negating the benefit of CPU pinning.

To avoid this, the `numactl --membind` option forces memory allocation from a specific NUMA node. In code, there are also NUMA APIs or even environment variables that can influence this configuration. The general rule is to keep memory close to the CPU which is close to the GPU. That way the chain of data movement from memory to CPU to GPU is all within a single NUMA node. Here is the same example as before, but with `--membind=1` to force memory allocation from the preferred NUMA node that includes NUMA node 1.

```
numactl --cpunodebind=1 --membind=1 python train.py --gpu 5 &
```

Another aspect of memory for GPUs is called page pinning, page locking, or memory pinning. When transferring data to the GPU, pinned (page-locked) host memory can dramatically improve throughput. Normally, the OS can decide to swap memory pages in and out - or move them around as needed. However, if you allocate pinned memory, the OS guarantees those memory pages will stay in physical RAM and not be swapped out or moved. Memory pinning allows the GPU to perform direct memory access (DMA) transfers at high speed, without the overhead of the OS potentially getting in the way. Copying from pinned host CPU memory to a GPU is often 2–3× faster than from regular pageable CPU memory.

Deep learning frameworks provide options to use pinned memory for data loaders. For example, PyTorch’s `DataLoader` has a flag `pin_memory=True` which, when true, means the batches loaded will be placed in pinned RAM. This speeds up the `tensor.to(device)` operations because the CUDA driver doesn’t have to pin pages on the fly. It’s especially beneficial when you are using large batch sizes or reading a lot of data each iteration. Many practitioners have noticed that just turning on `pin_memory=True` in PyTorch can significantly improve performance by reducing data transfer bottlenecks.

###### Tip

The OS has a limit on how much memory a user can lock (pin). This is set with the `ulimit -l <max locked memory>` command. If you plan to use large pinned buffers, ensure this limit is high - or set to unlimited for your user - otherwise the allocation might fail. Typically, one sets it to unlimited for large AI workloads and HPC applications.

## Transparent Huge Pages

In addition to pinning memory and binding it to NUMA nodes, we should talk about Transparent Huge Pages (THP). Linux memory management typically uses 4 KB pages, but managing millions of tiny pages is inefficient when you have processes using tens or hundreds of gigabytes of memory as in the case of deep learning datasets, prefetched batches, model parameters, etc.

Huge pages - 2 MB or even 1 GB pages - can reduce the overhead of virtual memory management by making memory chunks bigger. The main benefits are fewer page faults and less pressure on the Translation Lookaside Buffer (TLB). The TLB is a cache that the CPU uses to map virtual addresses to physical ones. Fewer, larger pages means the TLB can cover more memory with the same number of entries, reducing misses.

It’s generally recommended that you enable huge pages for big-memory workloads. Linux uses THP, which tries to automatically use 2 MB pages whenever possible. It’s usually enabled by default in modern distributions using either `madvise` or `always` mode. You can check the setting by reading `/sys/kernel/mm/transparent_hugepage/enabled`.

For most deep learning training jobs, it’s beneficial to enable THP so that it’s transparent to your program. In this case, you don’t have to change code, but you’ll gain a boost in CPU efficiency. Note that the gains from huge pages aren’t massive in every case. You might see a few percent improvement in throughput due to fewer page faults. For extremely large memory usage scenarios, one can reserve explicit huge pages using `hugetlbfs`, the Linux pseudo-filesystem, for allocating 1 GB pages. However, this requires more manual setup and configuration. Enabling THP is an easier, simpler win. Once it’s on, the OS will back large allocations with 2 MB pages automatically, reducing kernel overhead.

Now, beyond CPU and memory pinning, there are a few other OS-level tweaks worth mentioning. These include thread scheduling, virtual memory management, filesystem caching, and CPU frequency settings.

## Scheduler and Interrupt Affinity

On a busy system, you want to make sure that important threads such as data-pipeline threads aren’t interrupted frequently. Linux by default uses the Completely Fair Scheduler (CFS) that works well for most cases. But if you have a very latency-sensitive thread that feeds the GPU with data, for example, you could consider using real-time first-in-first-out (FIFO) or round-robin (RR) priority scheduling for that thread. This would ensure the runs without being preempted by normal threads. However, use this with caution as real-time threads can starve other processes if not managed properly. In practice, however, if you’ve pinned your threads to dedicated cores, you often don’t need to mess with real-time thread priorities, but it’s worth keeping an eye on.

Another trick is to isolate cores entirely for your process using `cset` or kernel boot parameters like the `isolcpus` kernel option. In this case, the OS scheduler leaves those CPU cores for you to use as your program wishes.

Additionally, you can bind hardware interrupts to specific cores in a NUMA-aware manner to avoid cross-NUMA-node interrupts that could evict useful cache data on the other NUMA node. If your GPU or NIC running in a NUMA node 0 generates hardware interrupts, you’d like those to be handled by a core on the same NUMA node. Otherwise, a random core from another NUMA node has to communicate across NUMA nodes. Tools like `irqbalance` can be configured so that, let’s say, the interrupts from an InfiniBand card in NUMA node 0 are handled by a CPU core in NUMA node 0.

## Virtual Memory and Swapping

It goes without saying, but you should always try to avoid memory swapping. If any part of your process’s memory gets swapped to disk, you will see a catastrophic, multiple-orders-of-magnitude slowdown. GPU programs tend to allocate a lot of host memory for data caching. If the OS decides to swap some data out of memory and onto disk, the GPU will experience huge delays when it needs to access that data.

We recommend setting `vm.swappiness = 0` which tells Linux to avoid swapping except under extreme memory pressure. Also, ensure you have enough RAM for your workload or put limits to prevent overcommit. Another related setting is `ulimit -l` as mentioned earlier for pinned memory. If you want to prevent memory from swapping, you should set that limit high or you may experience excessive memory swapping. Again, typically one sets this limit to unlimited for large AI workloads that utilize a lot of memory.

## Filesystem Caching and Write-Back

A best practice for large training jobs is to write frequent checkpoints to disk in case you need to restart a failed job from a known good checkpoint. During checkpointing, however, huge bursts of data might fill up the OS page cache and cause stalls. Adjusting `vm.dirty_ratio` and `vm.dirty_background_ratio` can control how much data can be buffered before writes flush to disk. For instance, if you’re writing multi-gigabyte checkpoints, you might want to allow a lot of dirty cache to accumulate and flush in the background, so your training process doesn’t block on file writes. Another option is to perform checkpointing in a separate thread. A more recent option in PyTorch, is to write distributed checkpoint partitions from nodes across the cluster. In this case, the checkpoint partitions will be combined when the checkpoint is loaded after a failed-job restart.

## CPU Frequency and C-states

By default, many compute nodes will run CPUs in a power-saving mode which either downclocks a CPU or puts it to sleep when it’s idle. This helps save energy, reduce heat, and lower cost. During model training, the CPUs might not always be 100% utilized as the GPUs are churning through the final batches of its dataset. However, these power management features could cause extra latency when the system wakes the CPUs up again when new work arrives.

For maximum and consistent performance, AI systems often configure the CPU frequency governor to “performance” mode which keeps the CPU at max frequency all the time. This can be done via `cpupower frequency-set` or in BIOS.

Likewise, disabling deep C-states can keep cores from going into a low-power sleep state. CPU C-states are power-saving modes defined by the system’s ACPI specification. When a CPU core is idle, it can enter a C-state to save energy. The deeper the C-state, the more power is saved, but the longer it may take for the core to “wake up” when work arrives. Disabling deeper C-states can remove excessive latency spikes. C0 is active, everything above C0 represents a deeper state of sleep.

Essentially, we can trade a bit of extra power draw for more responsive CPU behavior. In a training scenario where GPUs are the big power consumers, a bit more CPU power usage is usually fine if it keeps the GPUs fed. For example, if a data loader thread sleeps waiting for data and the CPU goes into the deep C6 state in which significant portions of the CPU is powered down to maximize energy savings.

If the CPU enters a deeper sleep state, it might take a few microseconds to wake up. While this is not a long time, many microseconds can add up and can cause GPU bubbles if not managed properly. Bubbles are periods of time when the GPU is waiting for the CPU to resume data processing. By keeping the CPU ready, we reduce such hiccups. Many BIOSes for servers have a setting to disable C-states - or at least limit them.

To summarize CPU and OS tuning, you should bind your workload to the hardware topology**, **use NUMA to your advantage, and eliminate OS interference. Make sure to pin each GPU’s work to the nearest CPU cores and memory. It’s recommended to use huge pages and locked memory to speed up memory operations. You should always turn off anything that might introduce unpredictable latency such as excess context switching, frequency scaling, and memory-to-disk swapping.

The result should be that your CPUs deliver data to the GPUs as fast as the GPUs can consume it, without the OS scheduling things on the wrong core or taking CPU cycles away at the wrong time. On a well-tuned GPU server, you might notice that CPU usage isn’t extremely high since the GPUs are doing the heavy lifting, but CPU usage should be consistent and aligned with the GPUs. The CPUs stay active enough to prepare the next batch while the current one is processing. Each GPU’s utilization graph stays near the top, only dipping when absolutely necessary for synchronization points - and not because the GPU is waiting on data or stuck on a slow CPU.

# GPU Driver and Runtime Settings for Performance

We’ve optimized the CPU side, but there are also important settings for the GPU driver and runtime that can affect performance - especially in multi-GPU and multi-user scenarios. NVIDIA GPUs have a few knobs that, when tuned properly, can reduce overhead and improve how multiple workloads share a GPU. We’ll cover GPU persistence mode, the Multi-Process Service , Multi-Instance GPU partitions, and a couple of other considerations like clock settings, ECC memory, and out-of-memory behavior.

## GPU Persistence Mode

By default, if no application is using a GPU, the driver may put the GPU into a lower-power state and unload some of the driver’s context. The next time an application comes along and wants to use the GPU, there’s a cost to initialize it. This can take on the order of a second or two for the driver to spin everything up. The initialization overhead can negatively impact performance for workloads that periodically releases and re-acquires the GPU. For instance, consider a training cluster where jobs are starting and stopping frequently. Or a low-volume inference cluster that has to wake up the GPU every time a new inference request arrives. In both of these cases, the overhead will reduce overall workload performance.

Persistence mode is a setting enabled by `nvidia-smi -pm 1` that keeps the GPU driver loaded and the hardware in a ready state even when no application is active. Essentially, it requests that the system does not fully power down the GPU when idle. The GPU stays awake so the next job has zero startup delay.

On AI clusters, it’s common to just enable persistence mode on all GPUs at server boot time. This way, when a job begins, the GPUs are already initialized and can start processing immediately. It won’t make your actual compute any faster as it doesn’t speed up the math operations, but it shaves off job-startup latency and prevents cold start delays.

GPU persistence mode also helps with interactive usage as without persistence, the first CUDA call you make after some idle time might stall while the driver reinitializes the GPU. With persistence on, that call returns quickly. The only downside is a slightly higher idle power draw since the GPU stays in a higher readiness state, but for most data center GPUs that’s an acceptable trade-off for performance consistency. Once GPU persistence mode is set by an admin with `sudo` access, you can enjoy the benefits and move on to tackle other optimizations.

## Multi-Process Service

Normally, when multiple processes share a single GPU, the GPU’s scheduler time-slices between them. For example, if two Python processes each have some kernels to run on the same GPU, the GPU might execute one process’s kernel, then the other process’s kernel, and so on. If those kernels are short and there’s an idle gap between them, the GPU can end up underutilized as it’s doing “ping-pong” context switches and not overlapping the work.

NVIDIA’s Multi-Process Service (MPS) is a feature that creates a sort of umbrella under which multiple processes can run on the GPU concurrently and without strict time slicing. With MPS, the GPU can execute kernels from different processes at the same time as long as the GPU resources (streaming multiprocessors, tensor cores, etc.) are available. MPS essentially merges the contexts of the processes into one scheduler context. This way, you don’t pay the full cost of switching and idling between independent processes.

When is MPS useful? For model training, if you normally run one process per GPU, you might not use MPS. But if you have scenarios like running many inference jobs on one big GPU, MPS is a game changer. Imagine you have a powerful GPU or GPU cluster but your inference job - or set of multiple inference jobs - doesn’t fully use it. For instance, consider running four separate inference jobs on one 40 GB GPU, each using 5-10 GB and only 30% of GPU compute. By default, each inference job gets a timeslice so at any moment, only one job’s work is actually running on the GPU. That leaves the GPU 70% idle on average.

If you enable MPS for these inference jobs, the GPUs can interleave their work so that while one job is waiting on memory, another job’s kernel might fill the GPU, etc. The result is higher overall GPU utilization. In practice, if two processes each use 40% of a GPU, with MPS you might see the GPU at 80-90% utilization serving both. For instance, two training processes that each would take 1 hour on their own - on the same GPU, run sequentially - can run together under MPS and finish in a bit over 1 hour total in parallel instead of 2 hours sequentially. This 2× speedup is a result of merging the work of both training processes and keeping the GPU fully busy.

To visualize, imagine Process A and Process B each launching kernels periodically without MPS. The GPU schedule might look like A-B-A-B with gaps in between while each one waits as shown in [Figure 3-2](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch03.html#ch03_figure_2_1744914896569344).

![A screenshot of a computer  AI-generated content may be incorrect.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9798341627772/files/assets/ch03_figure_2_1744914896569344.png)

###### Figure 3-2. GPU alternates between running Process A’s kernels and Process B’s kernels and creates idle gaps in which one process is waiting while the other is active

With MPS, the schedule becomes more like A and B overlapping so that whenever A isn’t using some parts of the GPU, B’s work can use them simultaneously, and vice versa. This overlapping eliminates idle gaps as shown in [Figure 3-3](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch03.html#ch03_figure_3_1744914896569376).

![A screen shot of a computer  AI-generated content may be incorrect.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9798341627772/files/assets/ch03_figure_3_1744914896569376.png)

###### Figure 3-3. Eliminating scheduling gaps for processes A and B such that two processes that individually hit ~40-50% utilization, now achieve ~90% when combined with MPS.

Setting up MPS involves running an MPS control daemon (`nvidia-cuda-mps-control`) which then launches an MPS server process that brokers GPU access. On modern GPUs, MPS is more streamlined as clients (the processes) can talk directly to the hardware with minimal interference from the compute node itself. Typically, you start the MPS server on a node - often one per GPU or one per user - and then run your GPU jobs with an environment variable that connects them to MPS. All jobs under that server will share the GPU concurrently.

Another feature of MPS is the ability to set an active thread percentage per client. This limits how many streaming multiprocessors (GPU cores, essentially) a client can use. This can be useful if you want to guarantee quality of service (QoS) where two jobs, for example, each get at most 50% of the GPU’s execution resources. If not explicitly set, the jobs will just compete and use whatever GPU resources they can.

Note that MPS does not partition GPU memory, so all processes will share the full GPU memory space. MPS is mainly about compute sharing and scheduling. The issue is that one process could request a massive amount of GPU RAM, cause an out-of-memory (OOM) error on the GPU, and result in terminating all of the other processes running on the GPU. This is very disruptive. Also, if one program saturates the GPU 100% on its own, MPS won’t magically make it go faster as you can’t exceed 100% utilization. It’s only beneficial when individual jobs leave some slack that others can fill.

Another limitation of MPS is that, by default, all MPS clients must run as the same Unix user since they share a context. In multi-user clusters, this means MPS is usually set up at the scheduler level such that only one user’s jobs share a GPU at a time. Otherwise, you can configure a system-wide MPS that’s shared by all users, but understand that the jobs are not isolated from a security standpoint. Recent NVIDIA drivers have introduced the concept of multi-user MPS, but it’s less common in production as of this writing.

One specific alternative to MPS is a feature for time-slicing GPUs in Kubernetes. Time-slicing on Kubernetes allows the device plugin to schedule different pods on the same GPU by time. For instance, four GPUs would each get 25% of the time. It’s sort of an automated time-sharing algorithm that doesn’t require MPS. However, this doesn’t overlap execution, it just switches more rapidly than the default driver would. Time-slicing may be useful for interactive workloads where you prefer isolation at the cost of some idle time. For high throughput jobs, overlapping with MPS or splitting the GPU with a multi-instance GPU is usually better than fine-grained time slicing as discussed next.

## Multi-Instance GPU

Starting with the NVIDIA A100 Ampere generation, GPUs can be partitioned at the hardware level into multiple instances using multi-instance GPU (MIG). MIG allows a GPU to be sliced into as many as 7 smaller logical GPUs - each with its own dedicated portion of memory and compute units, or streaming multiprocessors (SMs). For example, a 192 GB Blackwell B200 GPU can be split into 7 instances of about 27 GB (192 GB / 7 instances) and 20 SMs (140 SM’s / 7 instances) each. Each instance acts like a separate GPU from the perspective of software since it has its own memory, its own streaming multiprocessors, and even separate engine contexts.

The benefit of MIG is strong isolation and guaranteed resources for each job. If you have multiple users or multiple services that only need, say, 10 GB of logical GPU memory each, you can pack them onto one physical GPU without them interfering with each other’s memory or compute. It’s a form of virtualization but done in hardware, so the overhead is very low - maybe a few percent – due to the loss of some flexibility. If one instance is idle, it can’t lend its resources to another as they are hard partitioned. Also, if you’re not using all MIG slices, you’re wasting resources by leaving them fragmented. It’s important to plan partition sizes to match your workloads.

One important operational note is that, in order to use MIG, you typically configure it at the system level - or at least at the node level. The GPU has to be put into MIG mode, the slices created, the node rebooted, and then the slices appear as separate devices to the system.

###### Tip

The Kubernetes device plugin will list MIG devices as resources like “nvidia.com/mig-2g.10gb” in the case of a 2 GPU slice of 10 GB.

Jobs can request MIG devices specifically, but you have to be careful to schedule in a way that uses all slices. For instance, if you have a 7-slice setup and a job only takes one slice, the other 6 should be packed with other jobs or you’re leaving a lot idle. It’s possible to configure certain nodes in your cluster to use MIG for small inference jobs, for example - and configure other nodes for non-MIG workloads for large training jobs.

For large-scale model training jobs and inference servers that span many GPUs, MIG is typically not useful since we want access to the full set of GPUs. On the other hand, for multi-tenant, small-model inference servers that can run smaller GPU partitions, MIG and its isolation features could be useful.

In summary, enable MIG only when you need to run multiple independent jobs on the same GPU with strong isolation. Do not use MIG for large-scale distributed training or inferencing that spans GPUs as you want access to the full power of the GPUs and their fast interconnects.

In our context of large Transformer-based model training and inferencing, we will leave MIG off. But it’s good to know that this feature exists. Perhaps a cluster might dynamically switch modes and run MIG during the day when lots of small training or inferencing experiments are happening, then turn MIG off at night to run big training jobs that use whole GPUs.

## GPU Clock Speeds and Error Correcting Code

NVIDIA GPUs have something called GPU Boost which automatically adjusts the core clock within power and thermal limits. Most of the time, you should let the GPU just do its thing. But some users like to lock the clocks for consistency so that the GPU always runs at a fixed maximum frequency. This way, run-to-run performance is stable and not subject to variations in power or temperature. This is extremely important - and a common issue - when performing benchmarks as later runs may be throttled due to excessive heat. If you are not aware of this, you may inadvertently interpret the poor results of later runs incorrectly as the GPUs may be throttled due to excessive heat caused by previous runs.

You can use `nvidia-smi -lgc` to lock the core clock and `-ac` to lock the memory clock. This can help ensure that the GPU runs at a consistent frequency, which is especially useful for benchmarking or when you need reproducible performance results. By locking the clocks, you prevent fluctuations that might occur due to the default auto-boost behavior, which can vary with thermal conditions or power availability.

Some people may choose to underclock the GPUs a bit to reduce the heat if they are planning to run very long jobs and want to avoid hitting the thermal slowdown during a benchmark run. However, unless you see variability in GPU performance due to thermal throttling, you usually don’t need to lock the clocks as data center GPUs often have power and temperature headroom - as well as proper air or liquid cooling. But locking the clocks is something to be aware of if you’re chasing the last bit of determinism and consistency. Typically, however, leaving the GPU in the default auto-boost mode is fine.

Error Correcting Code (ECC) memory on GPUs is another consideration. ECC ensures that if there’s a single-bit memory error caused by cosmic rays, for example, the memory can be corrected on the fly. And if there’s a double-bit error, the error is detected and will throw an error to the calling code. ECC is usually enabled by default on NVIDIA data center GPUs.

Disabling ECC can free up a small amount of memory since ECC requires extra bits for error checking. This might yield a marginal performance gain by reducing the overhead associated with on-the-fly error checking, but typically just a few percent. However, turning off ECC also removes critical memory-error protection, which can lead to system instability or undetected data corruption.

Moreover, on many of NVIDIA’s newer data center GPUs including Hopper and Blackwell, ECC is always enabled and cannot be disabled. This design choice helps ensure reliability and data integrity in demanding, high-performance computing environments.

For long training or inference jobs on huge models, a single memory error could crash the job completely or, even worse, silently corrupt your model without a warning. As such, it’s recommended to always keep ECC on for any serious AI workload. The only time you’d possibly consider turning it off is in a research setting where you are fine with taking the risk because you need that extra sliver of memory for your model to fit into your limited-memory GPU cluster.

Toggling ECC mode requires resetting the GPU and likely restarting jobs that are currently running on that GPU. So it’s not a toggle that you want to switch frequently. Keep ECC on for stability and reliability. The peace of mind outweighs the negligible speedup of turning ECC off.

## GPU Memory Oversubscription, Fragmentation, and Out-of-Memory Handling

Unlike CPU RAM, by default there is no such thing as GPU “swap” memory. If you try to allocate more GPU memory than available, you will get an unfriendly out-of-memory (OOM) error along with an even-unfriendlier process crash. There are a couple of mechanisms to mitigate this issue including allowing memory to grow dynamically, unified memory across CPU and GPU, and memory pools and caching allocators.

By default, some frameworks (e.g. TensorFlow) grab all of the available GPU memory at startup to avoid fragmentation and improve performance. If you don’t know this, it can be very bad in scenarios where you are sharing the GPU. PyTorch by default only allocates GPU memory as needed. And fortunately, TensorFlow has an option (`TF_FORCE_GPU_ALLOW_GROWTH=true`) to make it start small and dynamically grow the GPU memory usage as needed - similar to PyTorch. Neither PyTorch nor TensorFlow let you allocate more memory than the GPU has available, of course. But this lazy-allocation plays nicer in multi-tenant scenarios because two processes won’t both try to simultaneously allocate the maximum available GPU memory from the start.

CUDA’s Unified Memory system lets you allocate memory without predefining whether it resides on the CPU or GPU. The CUDA runtime handles moving pages as needed. Modern NVIDIA GPUs like Hopper and Blackwell include hardware support for on-demand paging using the Page Migration Engine (PME). PME automatically migrates memory pages between GPU memory and host CPU RAM when the GPU runs low on available memory. However, while PME provides flexibility, relying on it can introduce performance penalties compared to having enough GPU memory for your workload.

This GPU-to-CPU memory offloading can be slow, however, since CPU memory I/O is slower than GPU high-bandwidth memory (HBM) I/O as we learned in the previous chapter. This mechanism is mostly a convenience for practitioners trying to run models that don’t fit into GPU RAM. For performance-critical workloads, however, you generally want to avoid relying on unified memory oversubscription where possible. It’s there as a safety net instead of outright crashing your script, but your job will run slower when GPU memory is over-subscribed.

Libraries like PyTorch use a caching allocator so that when you free GPU memory, it doesn’t return the memory to the OS immediately. Instead, it keeps it to reuse for future allocations. This avoids memory fragmentation and the overhead of asking the OS to repeatedly allocate the same block of memory. You can enable PyTorch’s allocator using environment variables like `PYTORCH_CUDA_ALLOC_CONF` to set a max pool size.

If you run into the GPU OOM error, which you surely will at some point, it’s likely caused by memory fragmentation or excessive memory caching. You can try to clear the cache using PyTorch’s `torch.cuda.empty_cache()`, but it almost-always means your workload legitimately needs that much memory.

From an OS perspective, you use Linux cgroups or Docker’s options to enforce GPU memory limits for a given process. For example, with Docker you can run a container with `--gpus <device>:<mem_limit>` to artificially constrain how much GPU memory it can allocate for the container. This way, if a process tries to use more than, say, 10 GB, it will get killed or error out rather than affecting others. In multi-tenant nodes, this could be useful to isolate jobs. In a single-job-per-GPU situation, it’s not common to set a memory limit as you want to let the job use as much of the GPU memory as it can get.

In general, running out of GPU memory is something you can manage at the application level. For instance, you can reduce the data batch size, model weight precision, or even the model parameter count, if that’s an option. A best practice is to monitor GPU memory usage with `nvidia-smi` or NVML APIs during model training and inferencing. If you’re close to the memory limit, consider workarounds like reducing batch size, gradient checkpointing for training, or other techniques to lower memory usage.

Also, you should ensure that your CPU memory isn’t being swapped as this would indirectly hurt your GPU utilization and goodput because each time your GPU tries to fetch something from the CPU host, but the host memory page has been swapped to disk, your performance will be bottlenecked by the much-slower disk I/O. So it’s important to combine these memory-reduction best practices with the earlier advice about pinning memory, increasing the `ulimit`, and disabling swappiness, etc.

Finally, it’s recommended to always keep the GPU driver loaded instead of unloading the GPU driver between jobs. This is similar to GPU persistence mode, but at a deeper level. Some clusters are configured to unload the driver when no jobs are running in order to free OS kernel memory and for security. However, if you do that, the next job has to pay the cost of re-loading the GPU driver and, if MIG is used, re-configuring MIG slices. Usually, you want to keep the driver and any MIG configuration persistent across jobs. The only time you want to unload the GPU driver is for troubleshooting or upgrading the driver. As such, cluster admins often set up the system so that the NVIDIA driver modules are always present once the machine boots.

# Container Runtime Optimizations for GPUs

Many AI systems use orchestration tools and container runtimes to manage the software environment. Kubernetes and Docker are popular in AI infrastructure. Using containers ensures that all dependencies including CUDA and library versions are consistent. This avoids the “but it works on my machine” problem. Containers introduce a bit of complexity and a tiny amount of overhead, but with the right configuration, you can get near bare-metal performance for GPU workloads using containers.

A container running on a node is not a traditional virtual machine (VM). In contrast to VM’s, containers share the host OS kernel so that CPU and memory operations perform at near-native speed. Similarly, for GPU workloads, the container can directly use the host’s GPU driver and hardware with negligible overhead. This is enabled by NVIDIA’s Container Toolkit which allows Docker containers to directly use the GPUs on the host.

## NVIDIA Container Toolkit and CUDA Compatibility

One challenge when using containers with GPUs is making sure that the CUDA libraries inside the container match the driver on the host. NVIDIA solves this through their NVIDIA Container Toolkit and base Docker images. The host provides the NVIDIA driver which, remember, is tightly integrated with the kernel and hardware. Inside the container, you typically find the CUDA runtime libraries of a certain version.

The general rule is that the host’s NVIDIA driver version must be at least as [recent](https://docs.nvidia.com/cuda/cuda-toolkit-release-notes/index.html) as the minimum driver version required by the CUDA version inside the container. If you’re running a container with CUDA 12.8, your host must have an NVIDIA driver version of 570.124.06 or higher. If your host has an older driver version, a container with CUDA 12.8 may not work properly.

###### Tip

The simplest approach is to use NVIDIA’s official base Docker images from the NVIDIA GPU Cloud (NGC) or DockerHub image repositories. The images in these repositories are well tested and describe which NVIDIA driver version they need on the host. End Tip.

## NVIDIA Container Runtime

Alternatively, NVIDIA’s container runtime can actually inject the host driver libraries into the container at runtime, so you don’t even need to ship the NVIDIA driver inside the image. Instead, you just rely on the host’s driver. Again, this works because the container isn’t fully isolated like a traditional VM. Docker containers are allowed to use host devices, volumes, and libraries.

Your code inside the container sees, for instance, `libcudart.so` from the CUDA toolkit on the host. It invokes this library directly on the host so everything just works. If you were to mismatch and try to use a newer CUDA version in the container with an old driver on the host, you’ll likely get an error. It’s important to match the CUDA and driver versions.

The key takeaway is that there is no hypervisor or virtualization layer involved when using containers for GPUs. The container is sharing the host kernel and driver directly, so when a kernel launches on the GPU, it’s as if it launched from the host. This means you aren’t losing performance to Docker-based virtualization - unless you are using something like VMware or SR-IOV virtual GPUs which is a special scenario that requires some tuning. With Docker + NVIDIA, it’s basically the equivalent to bare metal performance.

## Avoiding Container Overlay Filesystem Overhead

The main difference when running in a Docker container versus running directly on the host might be in I/O. Containers often use a union filesystem that transparently overlays multiple underlying filesystems, like the host filesystem and the container filesystem, into a single, unified view.

In a union filesystem such as OverlayFS, files and directories from multiple sources will appear as if they belong to one filesystem. This mechanism is especially useful for containers, where the read-only filesystem from the base image layer is combined with a writable container layer.

There is some overhead when using an overlay filesystem, however. This extra latency arises because the filesystem must check multiple underlying layers - both read-only and writable - to determine which version of a file should be returned. The additional metadata lookups and the logic for merging these layers can add a small amount of overhead compared to reading from a single, simple filesystem.

Furthermore, when writing to the copy-on-write (CoW) mechanism used by the overlay. CoW means that when you modify a file in the read-only layer (e.g., the base image), the file must first be copied to the writable layer. The write then happens to the copied writable file - instead of the original, read-only file. As mentioned earlier, reading a modified file requires looking at both the read-only and writable layers to determine which is the correct version to return.

Model training often involves heavy I/O operations when reading datasets, loading a model, and writing model checkpoints. To work around this, you can mount a host directory - or network filesystem - into the container using bind mounts.

Bind mounts bypass the overlay and therefore perform similar to disk I/O directly on the host. If the host filesystem is something like an NVMe SSD or an NFS mount, you get the full performance of that underlying storage device. We purposely do not package a multi-terabyte dataset inside the image. Instead, we bring the data in through the mounts.

For example, if your training data is on `/data/dataset` on the host, you’d run the container with `-v /data/dataset:/mnt/dataset:ro` where “ro” means “read-only” mount. Then your training script reads from `/mnt/dataset`. This way, you’re reading directly from the host filesystem.

In fact, it’s a best practice to avoid heavy data reads/writes against the container’s writable layer. Instead, mount your data directory and output directory from the host into the container. You want to ensure that I/O is not bottlenecked by the overhead of the container’s copy-on-write mechanism.

## Reduce Image Size for Faster Container Startup

Container startup times can be quite a bit slower if the image is huge and needs to be pulled over the network. But in a typical long-running training loop, a startup time of a few minutes is negligible compared to the hours, days, or months of training time. It’s still worth keeping images reasonably slim by not including unnecessary build tools or temporary build files. This saves disk space and improves container startup time.

Some HPC centers prefer Singularity (Apptainer) over Docker, because it can run images in user space without a root daemon. It also uses the host filesystem directly and tends to have virtually zero overhead beyond what the OS already has.

In either case, Docker or Singularity (Apptainer), studies and benchmarks have shown that once properly configured, these container solutions measure only a couple percent difference between running a container and directly on the host. Essentially, if someone gave you a log of GPU utilization and throughput, it would be difficult to tell from the log alone whether the job ran in a container or not.

# Kubernetes for Topology-Aware Container Orchestration and Networking

Kubernetes is a popular container orchestrator used across a wide variety of use cases including AI training and inference. Similar to the NVIDIA Container Toolkit, NVIDIA supports a Kubernetes device plugin for their GPUs called the NVIDIA [GPU Operator](https://github.com/NVIDIA/gpu-operator). When you deploy a container on Kubernetes with this device plugin, Kubernetes takes care of making the GPUs available to the container. You simply request a GPU in your Kubernetes pod specification, and the device plugin mounts the `/dev/nvidia*` devices for you. The GPU Operator device plugin also mounts the driver libraries from the host into the container.

When using Kubernetes to orchestrate GPU-based containers, you want it to allocate resources to containers in a manner that is aware of the hardware topology including the NUMA node and network bandwidth configurations. However, by default, Kubernetes (K8s) is not topology aware. It treats each GPU as a resource but doesn’t know if GPU0 and GPU1 are on the same NUMA node or if they use the same NVLink interconnect. This could make a big difference.

Consider an 8-GPU server with two sets of 4 GPUs - each connected by NVLink. If you request 4 GPUs from Kubernetes for a job, it would be ideal if K8s gave you 4 GPUs that are all interconnected with NVLink as they can share data faster. However, if K8s picks 4 arbitrary GPUs spread anywhere in the system, your job might be allocated 2 GPUs from one rack and 2 GPUs from another rack. This will introduce slower multi-rack (e.g. InfiniBand or Ethernet) interconnects into the GPU-to-GPU routes which could reduce your inter-GPU bandwidth by half.

To avoid resource contention, you should try to either reserve the resources that you need or request the entire node for your job. For the container/pod placements, you should align pods with CPU affinities and NUMA nodes using the [Kubernetes Topology Manager](https://kubernetes.io/docs/tasks/administer-cluster/topology-manager/) component to bind the container’s CPUs to the same NUMA node as the GPUs that the container was allocated.

## Orchestrating Containers with Kubernetes Topology Manager

Fortunately, Kubernetes Topology Manager and Nvidia’s hardware-aware GPU Operator device plugin can provide detailed topology information. For example, they can detect that GPU 0 is connected to NUMA node 0, NVLink domain A, and PCIe bus Z. The Kubernetes scheduler can then use this information to allocate containers to GPUs in an optimal way for efficient processing and communication.

Topology-aware scheduling for GPUs is still evolving. In some environments, administrators may still be using node labels to explicitly mark GPU or node topology. This ensures that multi-GPU pods are placed on hosts where the GPUs share the same NVLink domain or NUMA node.

For our purposes, if you’re running multi-GPU jobs in Kubernetes, make sure to enable topology-aware scheduling. This typically involves configuring the Kubernetes Topology Manager policy to use options like “best-effort”, “restricted”, or in some cases “single-numa-node”.

Also, be sure to use the latest NVIDIA device plugin which supports packing multi-GPU pods onto GPUs that are connected to the same NUMA node. This setup helps ensure optimal performance by minimizing cross-NUMA-node communication and reducing latency in multi-node GPU workloads.

## Job Scheduling with Kubernetes and SLURM

In multi-node deployments, job schedulers are essential for maximizing resource utilization across all nodes. Commonly, SLURM is deployed for training clusters while Kubernetes is typically favored for inference clusters. However, hybrid solutions have emerged that integrate SLURM with Kubernetes. The open-source [Slinky](https://github.com/SlinkyProject) project and CoreWeave’s [SUNK](https://docs.coreweave.com/docs/products/sunk) product are examples of these integrated solutions to simplify cluster management across training and inference workloads..

These systems handle the allocation of GPUs to jobs and coordinate the launch of processes across nodes. If a training job requests 8 nodes with 8 GPUs per node, the scheduler will identify eligible nodes and start the job using tools like `mpirun` or container runtimes such as Docker, ensuring that each process is aware of all available GPUs in the job. Many clusters also rely on well-tested Docker repositories like NVIDIA’s NGC Docker repository to guarantee a consistent software environment - including GPU drivers, CUDA toolkits, PyTorch libraries, and other Python packages - across all nodes.

With SLURM, similar issues exist. SLURM has the concept of “generic resources” for GPUs, and you can define that certain GPUs are attached to certain NUMA nodes or NVLinks/NVSwitches. Then in your job request, you can ask for GPUs that are, say, connected to the same NUMA node. If not properly set, a scheduler might treat all GPUs as identical and provide non-ideal allocations for your multi-GPU container requests. Proper configuration can avoid unnecessary cross-NUMA-node and cross-NVLink GPU communication overhead.

## Slicing a GPU with Multi-Instance GPU

If you are using Nvidia’s Multi-Instance GPU (MIG) to slice a GPU into partitions, the scheduler needs to be aware of the slices. Kubernetes, for instance, will see each MIG instance as a resource like “nvidia.com/mig-3g.20gb”. You could request two of those, and then K8s would place your pod on a node that has at least two free MIG instances.

An administrative drawback with MIG is that switching a GPU between MIG mode and normal (non-MIG) mode requires rebooting the compute node to reset the GPU. So it’s not something the scheduler can easily do dynamically per job. Usually, you create MIG partitions in advance and leave the configuration running for some period of time. You can label one K8s node with “mig-enabled” and another as “mig-disabled” and let the scheduler place jobs/pods accordingly. This is more of an operational detail, but it’s good to know that MIG is a static partition and not a dynamic scheduler decision.

###### Tip

Persistence mode is recommended when using MIG so that the MIG configuration remains active on the GPU even if no jobs are running. This way, the GPU doesn’t have to keep re-building the slices before running each periodic job.

## Optimizing Network Communication for Kubernetes

When you run multi-node GPU workloads using containers with Kubernetes, the pods need to talk to each other. In Kubernetes, by default pods have their own IP and there might be an overlay network or network-address translation (NAT) between pods on different nodes. This can introduce complications and additional overhead.

Often, the simplest solution for GPU clusters is to use host networking for these performance-sensitive jobs. That means the container’s network is not isolated as it uses the host’s network interface directly. To enable this in Kubernetes, you set `hostNetwork: true` on the pod specification. In Docker, you could run with `--network=host`.

Using host networking allows a container to access the InfiniBand interconnect exactly as the host does - without any additional translation or firewall layers. This is particularly useful for MPI jobs because it eliminates the need to configure port mappings for every MPI rank.

However, if host networking is not an option due to security policies, you must ensure that your Kubernetes container network interface (CNI) and any overlay network can handle the required traffic. In such cases, you may need to open specific ports to support NCCL’s handshake and data exchange, using environment variables like `NCCL_PORT_RANGE` and `NCCL_SOCKET_IFNAME` to help establish connections.

When operating over an overlay network, it’s critical that latency remains low, operations run in kernel space, and that no user-space proxies throttle traffic between nodes—since these factors can significantly impact performance.

## Reducing Kubernetes Orchestration Jitter

Running an orchestrator like Kubernetes means there are some background processes running on every node (e.g. the Kubernetes “kubelet”), container runtime daemons, and (ideally) monitoring agents. While these services consume CPU and memory, the consumption is on the order of a few percent of a single core. So they won’t steal noticeable time from a GPU-based training job which uses these cores for data loading and pre-processing.

However, if the training job is running on a node that is also running an inference workload, you may experience some jitter. This is common in any multi-tenancy situation, though. If another container on the same machine unexpectedly uses a lot of CPU or I/O, it will affect your container - whether training or inference - by competing for the same resources.

###### Tip

Homogeneous workloads such as all training or all inference are much easier to debug and tune from a system’s perspective than a heterogeneous mix of both training and inference.

## Improving Resource Guarantees

To safeguard against resource contention, Kubernetes lets you define resource requests and limits for pods. For example, you can specify that your training job requires 16 CPU cores and 64GB of RAM. Kubernetes will then reserve those resources exclusively for your job and avoid scheduling other pods on the same CPUs.

These limits are enforced using Linux cgroups, so if your container exceeds its allocation, it can be throttled or even terminated by the OOM killer. It’s common practice to use resource requests - and optionally the CPU Manager feature to pin cores - to ensure that performance-critical jobs get exclusive access to the necessary CPU resources, so that other processes cannot steal CPU time from your reserved cores.

Another source of jitter is background kernel threads and interrupts as we discussed in [Chapter 2](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch02.html#ch02_ai_system_hardware_overview_1744914895538857) in the context of using IRQ affinity. Similarly with Kubernetes, if other pods are using the same network or disks as your job, the other pods might cause a lot of interrupts and extra kernel work on the compute nodes that host your job. This will cause jitter and affect your job’s performance.

Ideally, a GPU node is fully dedicated to your job. However, if it’s not, you should ensure that the node is carefully partitioned using Linux cgroup controllers for I/O and CPU so that other workloads don’t interfere.

Fortunately, Kubernetes supports CPU isolation which ensures that pods get the dedicated CPU cores and memory they request - and prevents other pods from being scheduled on the same CPU core as yours. This avoids extra overhead from context switching and resource contention.

###### Tip

In practice, performance-sensitive Kubernetes jobs should request all of the CPUs and GPUs of a given node so that nothing else interferes or contends with the jobs’ resources. Easier said than done, but this is the ideal job configuration from a performance and consistency standpoint.

## Memory Isolation and Avoiding the OOM Killer

Memory interference can also occur if not properly limited. Kubernetes provides first-class memory isolation support (using Linux cgroups). However, a greedy container, if unconstrained, could allocate too much memory on the host. This would cause the host to swap some of its memory to disk.

If an unbounded container uses too much memory on the host, the infamous Linux “OOM Killer” will start killing processes - and potentially your Kubernetes job - even if your job wasn’t the one using too much memory.

The OOM killer uses heuristics when deciding which pods to kill. Sometimes it decides to kill the largest running pod which is likely your large training or inference job holding lots of data in CPU RAM to feed the GPUs. To avoid this, you can purposely not set strict memory limits on training or inference containers. This way, they can use all available memory, if needed.

With proper monitoring and alerting, you can ensure the job doesn’t try to over-allocate beyond what you expect. If you do set a memory limit, make sure it’s above what you actually expect to use. This provides a bit of headroom to avoid getting killed by the OOM killer 3 days into a long-running training job.

## Dealing with I/O Isolation

As of this writing, Kubernetes does not offer native, first-class I/O isolation out-of-the-box, unfortunately. While Linux does support I/O controls via cgroup controllers, Kubernetes itself does not automatically enforce I/O limits in the same way it does for CPU and memory.

If you need to ensure that heavy I/O workloads on a GPU node don’t interfere with each other, you might need to manually configure I/O controls at the node level. This can involve adjusting the `blkio` weights or using other OS-level configurations to partition I/O resources. In short, while Kubernetes prevents CPU contention through scheduling and resource requests, I/O isolation usually requires additional, manual tuning of the underlying Linux system.

It’s important to note that, inside a container, some system settings are inherited from the host. For instance, if the host has CPU frequency scaling set to performance mode, the container will inherit that setting. But if the container is running in a virtualized environment such as a cloud instance, you might not be able to change these settings.

It’s a good idea to always ensure that the host machine is tuned since containers can’t change kernel parameters like hugepage settings or CPU governor limits. Usually, cluster admins set these parameters and settings through the base OS image. Or, in a Kubernetes environment, they might use something like the NVIDIA GPU Operator to set persistence mode and other `sysctl` knobs on each node.

# Key Takeaways

Below is a list of key takeaways from this chapter including optimizations across the operating system, driver, GPU, CPU, and container layers.

Data and Compute Locality is Critical.Ensure that data is stored and processed as close to the computation units as possible. Use local, high-speed storage such as NVMe or SSD caches to minimize latency and reduce reliance on remote filesystems or network I/O.

NUMA-Aware Configuration and CPU Affinity.Optimize CPU-to-GPU data flow by aligning processes and memory allocations within the same NUMA node. Pinning the CPU with tools like `numactl` and `taskset` prevents cross-node memory access, leading to lower latency and improved throughput.

Maximize GPU Driver and Runtime Efficiency.Fine-tune the GPU driver settings, such as enabling persistence mode to keep GPUs in a ready state. Consider features like Multi-Process Service (MPS) for overlapping work from multiple processes on a single GPU. For multi-tenant environments, explore Multi-Instance GPU (MIG) partitions to isolate workloads effectively.

Effective Data Prefetching and Batching.Keep the GPUs fed by prefetching data ahead of time and batching small I/O operations into larger, more efficient reads. Leverage prefetching mechanisms like PyTorch’s DataLoader `prefetch_factor` to load multiple batches in advance.

Data Loading with Pinned Memory.Combining data prefetching with memory pinning using PyTorch’s DataLoader `pin_memory=True` uses pinned CPU memory (page-locked, not swappable to disk) for faster, asynchronous data transfers to the GPU. As a result, data loading and model execution can overlap, idle times are reduced, and both CPU and GPU resources are continuously utilized.

Memory Transfer Optimization.Leverage techniques such as pinned, page-locked memory and huge pages to accelerate data transfers between the host and GPU. This helps reduce copy overhead and allows asynchronous transfers to overlap with computations.

Overlap Communication with Computation.Reduce the waiting time for data transfers by overlapping memory operations like gradient synchronization and data staging with ongoing GPU computations. This overlap helps maintain high GPU utilization and better overall system efficiency.

Scalable Networking Tuning.In multi-node environments, use RDMA-enabled networks (e.g., InfiniBand/Ethernet) and tune network settings such as TCP buffers, MTU, and interrupt affinities to maintain high throughput during distributed training and inference.

Use Containerization and Orchestration for Consistency.Use container runtimes like Docker with the NVIDIA Container Toolkit and orchestration platforms like Kubernetes with the NVIDIA GPU Operator device plugin to ensure that the entire software stack - including drivers, CUDA libraries, and application code - is consistent across nodes. These solutions help align CPU-GPU affinities and manage resource allocation based on hardware topology.

Eliminate Container Runtime Overhead.While containers increase reproducibility and ease of deployment, ensure that CPU and GPU affinities, host networking, and resource isolation are correctly configured to minimize any container overhead.

Use Orchestration and Scheduling Best Practices.Robust container orchestrators like Kubernetes are essential components for ensuring efficient resource allocation. Advanced scheduling techniques - such as the Kubernetes Topology Manager - help ensure that GPUs with fast interconnects are clustered together.

Strive for Flexibility through Dynamic Adaptability and Scaling.The orchestration layer distributes work and dynamically manages workload segmentation across nodes. This flexibility is crucial for both scaling up training tasks and ensuring efficient runtime in inference scenarios where data loads and request patterns vary widely.

Continuous and Incremental Tuning.System-level optimizations are not one-and-done. Regularly monitor performance metrics, adjust CPU affinities, batch sizes, and prefetch settings as workloads evolve, and use these small improvements cumulatively to achieve significant performance gains.

Reduce Bottlenecks Across the Stack.The ultimate goal is to ensure that all components from the OS and CPU to the GPU driver and runtime work in harmony. Eliminating bottlenecks in one layer such as CPU memory allocation or driver initialization unlocks the full potential of the GPUs, which directly translates to faster training, lower costs, and more efficient resource usage.

Together, these strategies work to minimize data transfer friction, reduce wait times, and ensure that your hardware is used to its fullest potential for efficient training and inference.

# Conclusion

This chapter has demonstrated that even the most advanced GPUs can be hindered by inefficiencies in their surrounding environment. A well-tuned operating system and GPU software stack form the unsung backbone of high-performance AI systems. By aligning data with compute through NUMA-aware pinning and local storage solutions, overlapping communication with computation, and fine-tuning both the host system and GPU drivers, you can dramatically reduce latency and boost throughput. A well-tuned operating system, container runtime, cluster orchestrator, and software stack form the backbone of high-performance AI systems.

Think of your entire system as a precision-engineered sports car where each component (CPU, memory, GPU, network, containers, orchestrators, and programming stack) must work seamlessly together to deliver maximum performance. Small tweaks, such as enabling persistence mode or optimizing CPU scheduling, may seem minor on their own, but when combined and scaled across a large GPU cluster, they can lead to substantial savings in time and cost. Whether you’re training massive Transformer models or running complex inference pipelines, these optimizations ensure that GPUs are consistently operating near their peak efficiency.

As the field evolves and models continue to grow, the importance of system-level tuning will only increase. The techniques discussed in this chapter empower performance engineers and system architects to leverage every bit of hardware potential. This enables faster iteration cycles and more cost-effective AI deployments. Ultimately, a deeply optimized system accelerates research and makes cutting-edge AI applications more accessible to a broader audience.

Finally, remember that while the hardware and software stack may seem like an unmanageable amount of interconnected knobs and switches, small tweaks can translate into significant savings in time and cost. By continuously monitoring performance metrics and incrementally refining each layer of the stack, you can transform potential bottlenecks into opportunities for efficiency gains. Let the data guide you and you will unlock the full potential of your AI system.
