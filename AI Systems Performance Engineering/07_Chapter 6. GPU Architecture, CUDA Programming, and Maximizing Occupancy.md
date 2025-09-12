# Chapter 6. GPU Architecture, CUDA Programming, and Maximizing Occupancy

# A Note for Early Release Readers

With Early Release ebooks, you get books in their earliest form—the author’s raw and unedited content as they write—so you can take advantage of these technologies long before the official release of these titles.

This will be the 6th chapter of the final book.

If you’d like to be actively involved in reviewing and commenting on this draft, please reach out to the editor at *arufino@oreilly.com*.

In this chapter, we’ll start by reviewing the Single-Instruction, Multiple-Thread (SIMT) execution model and how warps, thread blocks, and grids map your GPU-based algorithms onto Streaming Multiprocessors (SMs).

You’ll then see a brief CUDA programming refresher that includes a review of the GPU memory hierarchy such as registers, shared/L1, L2 cache, and global HBM.

We’ll wrap with a discussion of roofline model analysis and the difference between compute-bound and memory-bound kernels. This will give us the basis to explore optimizations that utilize the full performance of GPU-based AI systems.

# Understanding GPU Architecture

Unlike CPU cores, which optimize for low-latency single-thread performance, GPU SMs use simpler cores and rely on multithreading to hide memory-access and pipeline latencies. GPUs are throughput‐optimized processors built to run thousands of threads in parallel.

Each GPU comprises many Streaming Multiprocessors (SMs) which are roughly analogous to CPU cores but streamlined for parallelism. Each SM can track up to 64 warps (32‐thread groups) on Blackwell. Within a Blackwell SM, four independent warp schedulers, each capable of issuing two independent instructions per cycle (e.g., one arithmetic and one memory operation) from different warps. In the best case, one warp from each scheduler can issue an instruction concurrently each cycle, allowing four warps to execute in parallel per cycle. This further boosts throughput when instruction mixing is utilized as shown in [Figure 6-1](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch06.html#ch06_figure_1_1750957012543986).

![A diagram of a computer processor

AI-generated content may be incorrect.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9798341627772/files/assets/ch06_figure_1_1750957012543986.png)

###### Figure 6-1. Blackwell SMs contain four independent warp schedulers, each capable of issuing one warp instruction per cycle (with dual-issue of one math + one memory operation per scheduler).

In short, GPUs excel at data-parallel workloads including large matrix multiplies, convolutions, and other operations where the same instruction applies to many elements. Developers write kernels directly in CUDA C++, or indirectly through high-level frameworks (e.g., PyTorch). Before diving into kernel development and memory-access optimizations, let’s review the CUDA thread hierarchy and key terminology that underpins all of these practices.

## Threads, Warps, Blocks, and Grids

CUDA structures parallel work into a three-level hierarchy—threads, thread blocks (Cooperative Thread Arrays or CTAs), and grids—to balance programmability with massive throughput. At the lowest level, each thread executes your kernel code. You group threads into CTAs (up to 1,024 threads each on modern GPUs), and CTAs form a grid when you launch the kernel as seen in [Figure 6-2](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch06.html#ch06_figure_2_1750957012544025).

![A diagram of a process

AI-generated content may be incorrect.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9798341627772/files/assets/ch06_figure_2_1750957012544025.png)

###### Figure 6-2. Threads, thread blocks, and grids

By sizing your grid appropriately, you can scale to millions of threads without changing your kernel logic. CUDA’s runtime (and frameworks like PyTorch) handle scheduling and distribution across all SMs.

Within each CTA, threads share data via low-latency on-chip shared memory and synchronize with `__syncthreads()`. Because each barrier incurs overhead, you should minimize synchronization points while still enabling fine-grained data reuse. Meanwhile, the GPU hardware hides long-latency events such as global-memory loads, cache fills, and pipeline stalls by rapidly switching among warps.

Each CTA is subdivided into warps of 32 threads that execute in lock-step under the SIMT model. Keeping more warps in flight, known as *high occupancy*, ensures that when one warp stalls, another is ready to run. This keeps the GPU’s compute units busy.

However, high occupancy must be balanced against per-thread resource limits including registers and shared memory, and hardware contexts. Spilling registers to slower memory can create new stalls. Profiling occupancy alongside register and shared-memory usage helps you choose a block size that maximizes throughput without triggering resource contention.

CTAs execute independently and in no guaranteed order. This allows the GPU scheduler to dispatch them across all SMs and fully exploit hardware parallelism. This grid–block–warp hierarchy guarantees that your CUDA kernels will run unmodified on future GPU architectures with more SMs and threads.

On Blackwell, you can further group CTAs into Thread Block Clusters (CTA Clusters) that share a Distributed Shared Memory (DSM) address space. DSM is a hardware feature that links the shared-memory banks of all SMs into a CTA cluster over a fast on-chip interconnect. It unifies the shared-memory regions of all blocks in a CTA cluster such that threads in different blocks can read, write, and atomically update each other’s shared buffers at on-chip speeds - and without occupying global memory bandwidth. We’ll cover CTA Clusters and DSM in [Chapter 7](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch07.html#ch07_profiling_and_tuning_gpu_memory_access_patterns_1750957019445498). Here, our focus remains on intra-block shared-memory optimizations.

Throughput also hinges on warp execution efficiency. Threads in a warp must follow the same control-flow path and perform coalesced memory accesses. If some threads diverge such that one branch takes the `if` path and others take the `else` path, the warp serializes execution, processing each branch path sequentially. This is called *warp divergence.*

By masking inactive lanes and running extra passes to cover each branch, warp divergence multiplies the overall execution time by the number of branches. We’ll dive deeper into warp divergence in [Chapter 7](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch07.html#ch07_profiling_and_tuning_gpu_memory_access_patterns_1750957019445498) - as well as ways to detect, profile, and mitigate it.

###### Tip

Divergence is only an issue for threads within a single warp. Different warps can follow different branches with no performance penalty.

It’s worth highlighting that one of CUDA’s cornerstone strengths is its forward and backward compatibility. Kernels you write today will compile and run unmodified on future GPU generations. And when you’re ready, you can improve your kernels to take advantage of new hardware features for additional performance. This stability underpins the vast CUDA ecosystem and lets you target both legacy and cutting-edge hardware from a single codebase.

## Choosing Threads-per-Block and Blocks-per-Grid Sizes

A critical aspect of GPU performance is choosing an appropriate block and grid size when launching a kernel. The hardware executes threads in warps of 32, so typically you want your block dimensions to be multiples of 32 to fully utilize whole warps. For instance, using 256 threads per block, or 8 warps (256 threads per block / 32 threads per warp = 8 warps per block) is common.

If a block size of 33 threads is chosen, it will occupy 2 warps since each warp consists of only 32 threads. This leaves one warp mostly empty and only 1/32th utilized. This wastes parallelism opportunities since every warp occupies a scheduler slot whether it’s actively running 32 threads or just 1 thread.

Blackwell, like all recent NVIDIA GPUs, uses 32 threads per warp, so non-multiple-of-32 block sizes underutilize a warp’s 32 available *lanes*, or *slots*. As such, it’s recommended to choose block sizes that are multiples of 32 to fully utilize each warp’s capacity. This way, no warp is left partially empty. Every cycle on all 32 threads of the warp can be doing useful work.

Additionally, different GPU generations have different hardware limits including maximum threads per SM and the number of registers per SM. This naturally limits the size of our blocks if we want to maintain good performance. For instance, too large a block might require too many registers which will cause *register spilling* and decrease the kernel’s performance.

A large block might also require too much shared memory which is finite in GPU hardware. Specifically, Blackwell provides only 228 KB per SM of shared memory available for user-allocated data. And this is shared with other kernels running concurrently on each SM.

These hardware limits affect how many blocks/warps can be active on an SM at once. This is a measurement of occupancy, as we introduced earlier.* *Smaller blocks might enable higher occupancy if they allow more concurrent warps to run concurrently on the SM.

It’s important to understand the hardware limits for your GPU generation. [Table 6-1](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch06.html#ch06_table_1_1750957012550785) shows a few key GPU limits for the Blackwell B200 GPU. The rest of the limits are available on NVIDIA’s [website](https://docs.nvidia.com/cuda/blackwell-tuning-guide/index.html). Other GPU generations will have different limits, so be sure to check the exact specifications for your system.

| <br>                  Resource<br> | <br>                  Hardware Limit<br> | <br>                  Notes<br> |
| --- | --- | --- |
| <br>                  Warp size<br> | <br>                  32 threads<br> | <br>                  The fundamental SIMT execution unit is 32 threads (a warp). <br>                  Always use a multiple of 32 to avoid waste.<br> |
| <br>                  Max threads per block<br> | <br>                  1024 threads<br> | <br>                  <br>                    `blockDim.x * blockDim.y * blockDim.z ≤ 1024.`<br>                  <br> |
| <br>                  Max warps per block<br> | <br>                  32 warps<br> | <br>                  (1024 threads / 32 threads-per-warp) = 32 warps max per block<br> |

We already discussed the warp size limit of 32 threads which encourages us to choose block dimensions that are multiples of 32 threads to create “full warps” and avoid underutilized warps. Note that each block can have up to 1024 threads and, correspondingly, a block can contain only 32 warps. These limits affect your occupancy since, once a block is scheduled, each SM can host a limited number of warps and blocks simultaneously.

Additionally, there are per-SM limits for the different GPU generations. The Blackwell SM-resident limits, as they are commonly called, are shown in [Table 6-2](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch06.html#ch06_table_2_1750957012550819).

| Resource (per SM) | Hardware Limit | Notes |
| --- | --- | --- |
| <br>                  Max resident warps per SM<br> | <br>                  64 warps<br> | <br>                  Hardware can keep up to 64 warps in flight (64 × 32 threads = 2048 threads). <br>                  Note: This limit has held since Volta and remains true for Blackwell.<br> |
| <br>                  Max resident threads per SM<br> | <br>                  2,048 threads<br> | <br>                  Equals 64 warps × 32 threads/warp.If each block uses 1024 threads, then at most 2 such blocks (64 warps) can reside on one SM concurrently. <br>                  Using smaller blocks (e.g. 256 threads) allows more blocks to reside on the SM (up to 8 blocks × 256 = 2,048 threads), which can increase occupancy and help hide latency – though too many tiny blocks can add scheduling overhead.<br> |
| <br>                  Max active blocks per SM<br> | <br>                  32 blocks<br> | <br>                  At most 32 thread blocks can be simultaneously resident on one SM (if blocks are smaller, more can fit up to this limit).<br> |

Here, we see that the maximum number of concurrent warps per SM on Blackwell is 64. This hasn’t changed for recent GPU generations, so occupancy considerations carry over. Maximum active blocks on an SM is 32 and, correspondingly, maximum resident threads per SM is 2,048 threads. CUDA grids also have maximum dimensions as shown in [Table 6-3](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch06.html#ch06_table_3_1750957012550839).

| Grid Dimension | Limit | Notes |
| --- | --- | --- |
| <br>                  Max blocks in X, Y, or Z<br> | <br>                  65,535 per dimension<br> | <br>                  A 3D grid can be as large as 65,535 × 65,535 × 65,535 blocks.<br> |
| <br>                  Max concurrent grids (kernels)<br> | <br>                  128 grids<br> | <br>                  Up to 128 kernels can execute concurrently on one device (i.e., 128 grids resident at once).<br> |

While it’s good to know the theoretical grid limits, you will typically be bound by the thread/block/per-SM limits shown previously. If you ever need more than 65,535 blocks in one dimension, you can launch a 2D or 3D grid to split your work across multiple kernel launches (multi-launch). We show an example of this in a later section. In practice, it’s rare to hit the grid size limit before hitting other resource limits.

# CUDA Programming Refresher

In CUDA C++, you define parallel work by writing kernels. These are special functions annotated with `__global__` that execute on the GPU device. When you invoke a kernel from the CPU (host) code, you use the `<<< >>>` “chevron” syntax to specify how many threads should run - and how they’re organized - using two configuration parameters: `blocksPerGrid` for the number of thread blocks and `threadsPerBlock` for the number of threads within each block.

Below is a simple example that demonstrates the key components of a CUDA kernel and kernel launch. This kernel simply doubles every element in the input array in-place so no additional memory is created - just the input array. Behind the scenes, CUDA compiles the `__global__` function into GPU device code that can be executed by thousands or millions of lightweight threads in parallel.

```
//-------------------------------------------------------
// Kernel: myKernel running on the device (GPU)
//   - input : device pointer to float array of length N
//   - N   : total number of elements in the input
//-------------------------------------------------------
__global__ void myKernel(float* input, int N) {
    // Compute a unique global thread index
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
 
    // Only process valid elements
    if (idx < N) {
        input[idx] *= 2.0f;
    }
}
 
// This code runs on the host (CPU)
int main() {
    // 1) Problem size: one million floats
    const int N = 1'000'000;
 
    // Allocate input array of size N on the host (h_)    float* h_input = new float[N];
    // Initialize host data (for example, all ones)
    for (int i = 0; i < N; ++i) {
        h_input[i] = 1.0f;
    }
 
    // Allocate device memory for input on the device (d_)
    float* d_input = nullptr;
    cudaMalloc(&d_input, N * sizeof(float));
 
    // Copy data from the host to the device using cudaMemcpyHostToDevice
    cudaMemcpy(d_input, h_input, N * sizeof(float), cudaMemcpyHostToDevice);
 
    // 2) Tune launch parameters
    const int threadsPerBlock = 256; // multiple of 32
    const int blocksPerGrid = (N + threadsPerBlock - 1) / threadsPerBlock; // 3,907 for N = 1,000,000
 
    // Launch myKernel across blocksPerGrid number of blocks
    // Each block has threadsPerBlock number of threads
    // Pass a reference to the d_input device array
    myKernel<<<blocksPerGrid, threadsPerBlock>>>(d_input, N);
    // Wait for the kernel to finish running on the device
    cudaDeviceSynchronize();
 
    // When finished, copy the results (stored in d_input) from the device back to the host (stored in h_input) using cudaMemcpyDeviceToHost
    cudaMemcpy(h_input, d_input, N * sizeof(float), cudaMemcpyDeviceToHost);
 
    // Cleanup: Free memory on the device and host
    cudaFree(d_input);
    delete[] h_input;
 
    return 0; // return 0 for success!
```

Here, the full data flow is shown: allocate memory on the host (`h_input)`, copy data from the host (`h_input`) to device (`d_input`) using `cudaMemcpy` with `cudaMemcpyHostToDevice`, run the kernel on the device with `d_input,` synchronize to ensure the kernel has finished executing on the device, transfer the results (`d_input)` from device to host (`h_input`) with `cudaMemcpyDeviceToHost`, then clean up memory on the device and host. This gives you a simple, complete template to start building your own CUDA kernels.

Here, we are passing kernel input arguments, `d_input` and `N`, which are accessible inside the kernel function for processing. The processing is shared, in parallel, across many threads. This is by design.

###### Tip

You can pass additional, advanced, CUDA-specific parameters to your kernel at launch time with `<<< >>>` including shared memory size (and many others) but the two core launch parameters, `blocksPerGrid` and `threadsPerBlock`, are the foundation of any CUDA kernel invocation. In the next section, we will discuss how to best choose these launch parameter values.

You might be wondering why we have to pass `N`, the size of the input array. This seems redundant since the kernel should be able to inspect the size of the array. However, this is the core difference between a GPU CUDA kernel function and a typical CPU function: a CUDA kernel function is designed to work inside of a single thread, alongside thousands of other threads, on a partition of the input data. As such, `N`, defines the size of the partition that this particular kernel will process.

Combined with the built-in kernel variables `blockIdx, blockDim` (1 in this case since we’re passing a 1 dimensional input array) and `threadIdx`, the kernel calculates the specific `idx` into the input array. This unique `idx` lets the kernel process every element of the input array cleanly and uniquely, in parallel, across many threads running across many different SMs simultaneously.

Note the bounds check `if (idx < N)`. This is needed to avoid out-of-range access (bounds-check) since N may not be an exact multiple of the block size. For instance, consider a scenario in which the input array is size 63, so `N = 63`. The warp scheduler will likely assign 2 warps (32 threads each) to process the 63 elements in the input array.

The first warp will run 32 instances of the kernel simultaneously to process elements 0-31 and never exceed `N = 63`. That’s straightforward. The second warp, running in parallel with the first warp, will expect to process elements 32-64. However, it will stop when it reaches `N = 63`.

Without the `if (idx < N)` bounds check, the second warp will try to process `idx = 64` and it will throw an illegal memory access error (e.g. `cudaErrorIllegalAddress`). The bounds check ensures that every thread either works on a valid input element - or exits immediately if its `idx` is out of range.

###### Tip

CUDA kernels execute asynchronously on the device without per‐thread exceptions; instead, any illegal operation (out-of-bounds access, misaligned access, etc.) sets a global fault flag for the entire launch. The host driver only checks that flag when you next call a synchronization or another CUDA API function, so errors surface lazily (e.g. as `cudaErrorIllegalAddress` or a generic launch failure). This design keeps the GPU’s pipelines and interconnects fully occupied but requires you to explicitly synchronize and poll for errors on the host—usually via `cudaGetLastError()` and `cudaDeviceSynchronize()` immediately after kernel launches—to catch faults as soon as they occur.

You will see a bounds check in a lot of CUDA kernels. If you don’t see it, you should understand why it’s not there. It’s likely there in some fashion - or the CUDA kernel developer can somehow guarantee the illegal memory access error will never happen.

And finally, we get to the actual kernel logic. After computing its unique index `idx` into the input array, this kernel (running separately on thousands of threads in parallel across many SMs), multiplies the value at index `idx` in the input array by 2. It then updates the value (in-place) in the input array. In this specific kernel, no additional memory is needed except the temporary `idx` variable of type `int`.

## Configuring Launch Parameters: Blocks Per Grid and Threads Per Block

We want to choose launch parameters to help us avoid partially-filled warps during kernel execution. The choice of `threadsPerBlock` is driven by the number of threads in a warp (32), the per-SM resource limits (registers/shared memory), and the need to hide latency. Setting `threadsPerBlock=256` is a good starting point as it’s a multiple of the 32-thread warp size and it hides latency well. It’s also occupancy-friendly and resource-balanced.

Multiple of 32 threadsChoosing a block size that is a multiple of 32 threads helps to avoid empty warp slots. Otherwise those under-filled warps occupy scarce scheduler resources - without contributing useful work.

Latency hidingHundreds of threads per SM are needed to hide DRAM and instruction‐latency stalls. If you launch, say, 8 blocks of 256 threads on an SM with 2,048 threads of capacity, you can keep the pipeline busy without oversubscribing.

OccupancyWith 256 `threadsPerBlock`, for example, you only need 4 warps per block. This tends to give good occupancy without running out of registers or shared memory per block.

Resource-balanced256 is small enough that you rarely exceed the 1024-thread-per-block limit. And it’s large enough that you’re not leaving too many warps idle when threads in other warps stall.

Starting with `threadsPerBlock=256`, you can tune up or down (128, 512, etc.) based on your kernel’s register and shared-memory requirements - as well as occupancy characteristics.

For `blocksPerGrid`, you can base this on the number of `N` input elements and the value of `threadsPerBlock`. For instance, the `blocksPerGrid` is commonly set to `(N + threadsPerBlock - 1) / threadsPerBlock` to round up so that you cover all elements if `N` is not an exact multiple of `threadsPerBlock`. This is a common choice that guarantees every input element is covered by a thread. Here is the code that shows the calculation.

```
// simple_kernel.cu
 
//-------------------------------------------------------
// Kernel: myKernel running on the device (GPU)
//   - input : device pointer to float array of length N
//   - N   : total number of elements in the input
//-------------------------------------------------------
__global__ void myKernel(float* input, int N) {
    // Compute a unique global thread index
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
 
    // Only process valid elements
    if (idx < N) {
        input[idx] *= 2.0f;
    }
}
 
// This code runs on the host (CPU)
int main() {
    // 1) Problem size: one million floats
    const int N = 1'000'000;
 
    // Allocate input array of size N on the host (h_)    float* h_input = new float[N];
    // Initialize host data (for example, all ones)
    for (int i = 0; i < N; ++i) {
        h_input[i] = 1.0f;
    }
 
    // Allocate device memory for input on the device (d_)
    float* d_input = nullptr;
    cudaMalloc(&d_input, N * sizeof(float));
 
    // Copy date from the host to the device using cudaMemcpyHostToDevice 
    cudaMemcpy(d_input, h_input, N * sizeof(float), cudaMemcpyHostToDevice);
 
    // 2) Tune launch parameters
    const int threadsPerBlock = 256; // multiple of 32
    const int blocksPerGrid = (N + threadsPerBlock - 1) / threadsPerBlock; // 3,907, in this case
 
    // Launch myKernel across blocksPerGrid number of blocks
    // Each block has threadsPerBlock number of threads
    // Pass a reference to the d_input device array
    myKernel<<<blocksPerGrid, threadsPerBlock>>>(d_input, N);
    // Wait for the kernel to finish running on the device
    cudaDeviceSynchronize();
 
    // When finished, copy the results (stored in d_input) from the device back to the host (stored in h_input) using cudaMemcpyDeviceToHost
    cudaMemcpy(h_input, d_input, N * sizeof(float), cudaMemcpyDeviceToHost);
 
    // Cleanup: Free memory on the device and host
    cudaFree(d_input);
    delete[] h_input;
 
    return 0; // return 0 for success!
```

This is the same kernel as above, but calculate the `blocksPerGrid` and `threadsPerBlock` dynamically based on the size of `N`. Note the familiar `if (idx < N)` bounds check. This ensures that any “extra” threads in the final block that fall outside of `N` will simply do nothing - and not cause an illegal memory address error.

Next, let’s explore multi-dimensional inputs like 2D images and 3D volumes.

## 2D and 3D Kernel Inputs

When your input data naturally lives in 2 dimensions (e.g. images), you can launch a 2D grid of 2D blocks. For example, here’s a kernel that processes a 2 dimensional 1024×1024 matrix using a 16×16 dimensional thread block for a total of 256 threads.

```
// 2d_kernel.cu
 
#include <cuda_runtime.h>
#include <iostream>
 
//-------------------------------------------------------
// Kernel: my2DKernel running on the device (GPU)
//   - input  : device pointer to float array of size width×height
//   - width  : number of columns
//   - height : number of rows
//-------------------------------------------------------
__global__ void my2DKernel(float* input, int width, int height) {
    // Compute 2D thread coordinates
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;
 
    // Only process valid pixels
    if (x < width && y < height) {
        int idx = y * width + x;
        input[idx] *= 2.0f;
    }
}
 
int main() {
    // Image dimensions
    const int width  = 1024;
    const int height = 1024;
    const int N      = width * height;
 
    // 1) Allocate and initialize host image
    float* h_image = new float[N];
    for (int i = 0; i < N; ++i) {
        h_image[i] = 1.0f;  // e.g., initialize all pixels to 1.0f for this simple example
    }
 
    // 2) Allocate device image and copy data to device
    float* d_image = nullptr;
    cudaMalloc(&d_image, N * sizeof(float));
    cudaMemcpy(d_image, h_image, N * sizeof(float), cudaMemcpyHostToDevice);
 
    // 3) Configure and launch the 2D kernel
    dim3 threadsPerBlock2D(16, 16);  // 256 threads per block
    dim3 blocksPerGrid2D((width  + threadsPerBlock2D.x - 1) / threadsPerBlock2D.x,
                         (height + threadsPerBlock2D.y - 1) / threadsPerBlock2D.y);
 
    // 4) launch the kernel
    my2DKernel<<<blocksPerGrid2D, threadsPerBlock2D>>>(d_image, width, height);
 
    // 5) wait for kernel to finish
    cudaDeviceSynchronize();  
 
    // 6) Copy results back to host
    cudaMemcpy(h_image, d_image, N * sizeof(float), cudaMemcpyDeviceToHost);
 
    // 7) Verify a sample element
    std::cout << "h_image[0] = " << h_image[0] << std::endl;
 
    // 8) Cleanup
    cudaFree(d_image);
    delete[] h_image;
 
    return 0;
```

Here, again, is the full kernel (device) and invocation (host) code. This same pattern generalizes to 3D by using `dim3(x, y, z)` for both `blocksPerGrid` and `threadsPerBlock`, letting you map volumetric data directly onto the GPU’s thread hierarchy.

## Asynchronous Memory Allocation and Memory Pools

Standard `cudaMalloc`/`cudaFree` calls, as shown in the previous examples, are synchronous and relatively expensive. They require a full device synchronization (relatively slow) and involve OS-level calls like `mmap`/`ioctl` to manage GPU memory. This OS-level interaction incurs kernel-space context switches and driver overhead which makes them relatively slow compared to purely device-side operations. As such, it’s recommended to use the asynchronous versions, `cudaMallocAsync` and `cudaFreeAsync`, for more-efficient memory allocations on the GPU.

By default, the CUDA runtime maintains a global pool of GPU memory. When you free memory asynchronously, it goes back into the pool for potential reuse in subsequent allocations. `cudaMallocAsync` and `cudaFreeAsync` use the CUDA memory pool under the hood.

A memory pool recycles freed memory buffers and avoids repeated OS calls to allocate new memory. This helps to reduce memory fragmentation over time by reusing previously-freed blocks instead of creating new ones for each iteration in a long-running training loop, for instance. Memory pools are enabled by default in many high-performance libraries and runtimes such as PyTorch.

In fact, PyTorch uses a custom memory caching allocator, configured with `PYTORCH_CUDA_ALLOC_CONF`. The PyTorch memory caching allocator is similar in spirit to CUDA’s memory pool: it reuses GPU memory and avoids the cost of calling the synchronous `cudaMalloc` operation for every new PyTorch tensor created during each iteration of a long-running training loop, for instance.

In CUDA applications that perform frequent, fine-grained allocations, it’s far more efficient to use the asynchronous pool-based routines - `cudaMallocAsync` and `cudaFreeAsync` - rather than the traditional synchronous `cudaMalloc`/`cudaFree`, which incur full-device synchronization and even OS-level calls. To take advantage of stream-local memory pools, you first create a dedicated CUDA stream:

```
cudaStream_t stream1;
cudaStreamCreate(&stream1);
```

###### Tip

Using explicit CUDA streams is a best practice for overlapping transfers, kernels, and memory operations. Think of each stream as an isolated channel that enforces ordering among its own operations. We’ll explore multi-stream overlap techniques in more detail in [Chapter 7](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch07.html#ch07_profiling_and_tuning_gpu_memory_access_patterns_1750957019445498).

Then, whenever you need a buffer of `N` floats, you allocate and free it on that stream:

```
float* d_buf = nullptr;
cudaMallocAsync(&d_buf, N * sizeof(float), stream1);
 
// ... launch kernels into stream1 that use d_buf ...
myKernel<<<blocksPerGrid, threadsPerBlock, 0, stream1>>>(d_buf, N);
 
// Free is deferred until all work in stream1 completes—
cudaFreeAsync(d_buf, stream1);
```

Because `cudaFreeAsync` only waits for `stream1` to finish, there is no expensive global `cudaDeviceSynchronize` and no implicit synchronization with other streams. The result is dramatically lower allocation overhead when your code issues thousands - or millions - of allocate/free cycles, reducing fragmentation and smoothing out latency spikes.

You can further tune the behavior of each stream’s memory pool—for example, by setting `cudaMemPoolTrimThreshold` to control when unused allocations are returned to the OS, balancing total GPU memory footprint against fragmentation. For simple, one-time buffers, a blocking `cudaMalloc`/`cudaFree` may suffice. In more complex, long-running loops where you repeatedly allocate and free memory, however, switching to `cudaMallocAsync`/`cudaFreeAsync` on dedicated streams and leveraging their pools will yield more consistent performance and higher throughput.

###### Tip

Adjust memory-pool parameters like `cudaMemPoolTrimThreshold` to tune release thresholds and strike the right trade-off between a minimal memory footprint and low fragmentation.

## Understanding GPU Memory Hierarchy

So far, we’ve been discussing memory allocations broadly at a high level and typically from global memory. These allocations come from a stream’s memory pool - including the default stream 0 memory pool.

In reality, however, the GPU provides a multi-level memory hierarchy including registers, shared memory, caches, and a specialized tensor memory on Blackwell GPUs. The memory hierarchy levels, common in CPUs as well, help balance capacity and speed.

For instance, global memory (HBM or DRAM) is large, off-chip, and relatively slow. Registers are tiny, on-chip, and extremely fast. L1 Cache, L2 Cache, and shared memory are somewhere in between.

The benefit of caching and shared memory are that they hide the relatively-long latency of accessing the large off‑chip memory stores. [Table 6-4](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch06.html#ch06_table_4_1750957012550858) shows the different levels of memory and their characteristics for the Blackwell B200 GPU. A description of each level of the memory hierarchy follows.

| Level | Scope | Capacity | Latency | Bandwidth (approx.) |
| --- | --- | --- | --- | --- |
| <br>                  Registers<br> | <br>                  Per thread (on SM)<br> | <br>                  64 K 32-bit registers per SM <br>                  (max 255 per thread)<br> | <br>                  ~0 cycles (register reads/writes are free)<br> | <br>                  Tens of TB/s per SM (register‐file ports)<br> |
| <br>                  Shared Memory & L1 Cache<br> | <br>                  Per SM<br> | <br>                  228 KB shared (allocable) + remainder as L1/data cache<br> | <br>                  ~20–30 cycles (L1/shared benchmarks)<br> | <br>                  TB/s per SM (bank-conflict-free)<br> |
| <br>                  Constant Memory Cache<br> | <br>                  Per SM<br> | <br>                  ~8 KB cache for 64 KB `__constant__` space<br> | <br>                  ~1 cycle (warp‐broadcast)<br> | <br>                  TB/s-scale (broadcast throughput)<br> |
| <br>                  L2 Cache<br> | <br>                  GPU-wide (all SMs)<br> | <br>                  126 MB total<br> | <br>                  ~200 cycles (V100/A100 benchmarks)<br> | <br>                  Tens of TB/s aggregate (~5× HBM)<br> |
| <br>                  Local Memory<br> | <br>                  Per thread (spills to DRAM)<br> | <br>                  Unlimited (backed by global memory)<br> | <br>                  100s–>1 000 cycles (DRAM‐like)<br> | <br>                  ~8 TB/s (HBM3e)<br> |
| <br>                  Global Memory (HBM or DRAM)<br> | <br>                  Device-wide (off-chip DRAM)<br> | <br>                  Up to 192 GB per GPU <br> | <br>                  100s–>1 000 cycles (global-memory latency)<br> | <br>                  ~8 TB/s total<br> |

Here, you can see why maximizing data reuse in registers, shared memory, and L1/L2 cache - and minimizing reliance on global memory and local memory (backed by global memory) - is essential for high-throughput GPU kernels. Next, is a bit more detail about each of these levels of the hierarchy.

RegistersOn Blackwell, every thread begins its journey at the **register file**, a tiny on-SM SRAM array that holds each thread’s local variables with essentially zero added latency. Each SM houses 64 K 32-bit registers (256 KB total), but the hardware exposes at most 255 registers per thread.

Because reads and writes complete in a single cycle and contend with almost nothing else, register bandwidth can reach tens of terabytes per second per SM. However, if your kernel needs more registers—either through many thread-local variables or compiler temporaries—the overflow spills into **local memory**, mapped to off-chip DRAM, and incurs hundreds to over a thousand cycles of latency.

Shared memory and L1 data cacheOne step up is a unified L1/data cache & shared-memory block. This is 256 KB of on-SM SRAM per SM that you can dynamically split between user-managed shared memory (up to 228 KB per block via `cudaFuncSetAttribute(cudaFuncAttributePreferredSharedMemoryCarveout)`) and automatic L1/texture caching.

Accesses here cost roughly 20–30 cycles, but if you design your thread blocks to avoid bank conflicts you can achieve terabytes-per-second throughput. Behind the scenes, Blackwell also dedicates a second 256 KB per-SM buffer, TMEM, to feed tensor cores; it remains invisible to CUDA code yet transparently accelerates matrix-multiply operations without changing your kernels.

Constant memory cacheFor tiny, read-only tables, Blackwell provides a per-SM constant memory cache of about 8 KB fronting the 64 KB `__constant__` space. When all 32 threads in a warp load the same address, this cache broadcasts the value in a single cycle.

Divergent reads serialize across lanes. It’s perfect for sharing small lookup tables for rotary positional encodings, ALiBi slopes, LayerNorm γ/β vectors, and embedding quantization scales. These are shared across every thread without global-memory traffic.

L2 cacheBeyond on-chip SRAM sits the L2 cache, a 126 MB GPU-wide buffer that glues all SMs to off-chip HBM3e. With latencies near 200 cycles and aggregate bandwidth in the tens of terabytes per second, L2 absorbs spill-over from L1.

L2 lets data fetched by one thread block be reused by others without revisiting DRAM. To maximize L2’s benefits, structure your global loads into 128-byte, coalesced transactions that map cleanly to cache lines. We’ll show how to do this in a bit.

Global memory (HBM or DRAM)The global memory tier, local spill space and HBM, live off-chip. Any spilled registers or oversized automatic arrays reside in local memory, paying full DRAM latency (hundreds to >1 000 cycles) despite HBM3e’s ~8 TB/s bandwidth.

For Blackwell, the HBM3e tier provides up to 192 GB of device-wide storage at ~8 TB/s total. However, its high latency makes it the slowest link in the chain.

By carefully orchestrating data through registers, shared/L1, constant cache, and L2. Using tools like Nsight Compute to track spills and cache hit rates, you can keep your kernels operating as close as possible to the on-chip peaks of this hierarchy.

###### Tip

The Blackwell B200 GPU consists of two GPU dies on one package, each connected to 4 HBM3e stacks for a total of 8 HBM3e stacks. An ultra-fast 10 TB/s interconnect called NVLink-HBI (High-Bandwidth Interface) links the dies, so they behave as a single unified GPU with a combined 192 GB HBM memory pool. From a developer’s perspective, however, HBM memory access is uniform across this combined address space

Modern GPUs like Blackwell allow kernel developers to exploit the memory hierarchy by using L2 caches and unified L1/shared memory to buffer and coalesce accesses to HBM as we’ll soon see.

In summary, it’s important to understand the GPU’s memory hierarchy and target each level appropriately. By doing so, you can structure your CUDA kernels to maximize data locality, hide memory-access latency, increase occupancy, and fully leverage Blackwell’s massive parallel compute capabilities as we’ll explore in a bit. But, first, let’s discuss NVIDIA’s unified memory which has become even more critical to understand given the unified CPU-GPU superchip designs of Grace Hopper and Grace Blackwell.

## Unified Memory

Unified Memory (also known as CUDA Managed Memory) gives you a single, coherent address space that spans both CPU and GPU, so you no longer have to juggle separate host and device buffers or issue explicit `cudaMemcpy` calls. Under the hood, the CUDA runtime backs every `cudaMallocManaged()` allocation with pages that can migrate on-demand over whatever interconnect links your CPU and GPU.

While accessing unified memory is super developer-friendly, it can cause unwanted on-demand page migrations between the CPU and the GPU. This will introduce hidden latency and execution stalls. For example, if a GPU thread accesses data that currently resides in CPU memory, the GPU will page-fault and wait while that data is transferred over the NVLink-C2C interconnect. Unified Memory performance depends greatly on the underlying hardware.

On traditional PCIe or early NVLink systems, those migrations travel at relatively low bandwidth - often making on-fault transfers slower than a manual `cudaMemcpy`. But on Grace Hopper and Grace Blackwell superchips, the NVLink-C2C fabric delivers up to ~900 GB/s between the CPU’s HBM and the GPU’s HBM3e. As such, page-fault–driven migrations come far closer to device-native speed - although they still carry non-zero latency.

That said, any unexpected page-fault during a kernel launch will stall the GPU while the runtime moves the needed page into place. To avoid those “surprise” stalls, you can prefetch memory in advance as shown here.

```
cudaMemPrefetchAsync(ptr, size, gpuId, stream);
```

This hints to the driver to move the specified range onto the target GPU (or CPU) before you launch your kernel, turning costly first-touch migrations into overlappable, asynchronous transfers. You can also give memory advice as seen here.

```
cudaMemAdvise(ptr, size, cudaMemAdviseSetPreferredLocation, gpuId);
cudaMemAdvise(ptr, size, cudaMemAdviseSetReadMostly, gpuId);
```

You can use `PreferredLocation` to tell the driver where you’ll mostly use the data, and `ReadMostly` when it’s largely read-only. You can also call the following to let a second GPU map those pages without triggering migrations at launch.

```
cudaMemAdvise(ptr, size, cudaMemAdviseSetAccessedBy, otherGpuId);
```

By default, any CUDA stream or device kernel can trigger a page fault on a managed allocation. This can cause unexpected migrations and implicit synchronizations. If you know a certain buffer will be used only in one stream/GPU at a time, attaching it to that stream allows migrations to overlap with operations in other streams. Calling the following ties that memory range to the specified stream.

```
cudaStreamAttachMemAsync(stream, ptr, 0, cudaMemAttachSingle);
```

In this case, only operations in that stream will fault and migrate its pages. This prevents other streams from accidentally stalling on it.

As such, attaching a range to a particular stream defers its migrations so they overlap with only that stream’s work. This avoids cross-stream synchronization.

###### Tip

In multi-GPU systems without NVLink-C2C, you can also use `cudaMemcpyPeerAsync()` or a prefetch to a specific device to pin data in the nearest NUMA-local GPU memory, preventing slow remote accesses.

In short, explicitly prefetching managed memory and providing memory advice can eliminate most of the “surprise” stalls from Unified Memory. Instead of the GPU pausing to fetch data on-demand, the data is already where it needs to be when the kernel runs.

With techniques like proactive prefetching, targeted memory advice, and stream attachment, Unified Memory can deliver performance very close to manual `cudaMemcpy` while preserving the simplicity of a unified address space.

## Maintaining High Occupancy and GPU Utilization

GPUs sustain performance by running many warps concurrently so that when one warp stalls waiting for data, another warp can run. This ability to rapidly switch between warps allows a GPU to hide memory latency. As we described earlier, the fraction of an SM’s capacity actually occupied by active warps is called occupancy.

If occupancy is low (just a few active warps), an SM may sit idle while one warp is waiting on memory. This leads to poor SM utilization. On Blackwell, achieving high occupancy is a bit easier given its large register file (64K registers per SM) which can support many warps without spilling.

###### Tip

As you’ll see in the GPU Memory Hierarchy section, each thread in a warp can use up to 255 registers. Make sure to use your profiling tools to check achieved occupancy - and adjust your kernel’s block size and register usage accordingly.

Conversely, high occupancy (many active warps per SM) will keep the GPU compute units busy since, while one warp waits on memory access, others will swap in to the SM and execute. This masks the long memory access delays. This is often referred to as *hiding latency*.

Let’s show an example that improves occupancy and ultimately GPU utilization, throughput, and overall kernel performance. This is one of the most fundamental rules of CUDA performance optimization: launch enough parallel work to fully occupy the GPU.

If your achieved occupancy (the fraction of hardware thread slots in use) is well below the GPU’s limit and performance is poor, the first remedy is to increase parallelism – use more blocks or threads so that occupancy approaches the 80–100% range on modern GPUs.

Conversely, if occupancy is already moderate-to-high but the kernel is bottlenecked by memory throughput, pushing it to 100% may not help. You generally need just enough warps to hide latency, and beyond that the bottleneck might lie elsewhere (e.g. memory bandwidth).

To illustrate the impact of occupancy, consider a very simple operation: adding two vectors of length N (computing C = A + B). We’ll examine two kernel implementations: addSequential and addParallel. `addSequential` uses a single thread (or a single warp) to add all N elements in a loop. `addParallel` uses many threads so that the additions are done concurrently across the array.

In the sequential version, one GPU thread handles the entire workload serially as shown here.

```
// addSequential.cu
#include <cuda_runtime.h>
 
const int N = 1'000'000;
 
// Single thread does all N additions
__global__ void addSequential(const float* A,
                              const float* B,
                                    float* C,
                              int N)
{
    if (blockIdx.x == 0 && threadIdx.x == 0) {
        for (int i = 0; i < N; ++i) {
            C[i] = A[i] + B[i];
        }
    }
}
 
int main()
{
    // Allocate and initialize host
    float *h_A = new float[N], *h_B = new float[N], *h_C = new float[N];
    for (int i = 0; i < N; ++i) {
        h_A[i] = float(i);
        h_B[i] = float(i * 2);
    }
 
    // Allocate device
    float *d_A, *d_B, *d_C;
    cudaMalloc(&d_A, N * sizeof(float));
    cudaMalloc(&d_B, N * sizeof(float));
    cudaMalloc(&d_C, N * sizeof(float));
 
    // Copy inputs to device
    cudaMemcpy(d_A, h_A, N * sizeof(float), cudaMemcpyHostToDevice);
    cudaMemcpy(d_B, h_B, N * sizeof(float), cudaMemcpyHostToDevice);
 
    // Launch: one thread
    addSequential<<<1,1>>>(d_A, d_B, d_C, N);
 
    // Ensure completion before exit
    cudaDeviceSynchronize();
 
    // Cleanup
    cudaFree(d_A);
    cudaFree(d_B);
    cudaFree(d_C);
    delete[] h_A;
    delete[] h_B;
    delete[] h_C;
    return 0;
}
```

In this single-threaded version, the GPU’s vast resources are mostly idle. Only one warp, or even one thread within the warp, is doing work while all others sit idle. The result is very poor occupancy and, ultimately, low performance.

One must be also careful to avoid indirectly executing inefficient GPU code in high-level libraries and frameworks like PyTorch. For instance, the naive PyTorch code below mistakenly performs element-wise operations using a Python for-loop that issues N separate add operations on the GPU one after another.

```bash
# add_sequential.py
import torch
 
N = 1_000_000
A = torch.arange(N, dtype=torch.float32, device='cuda')
B = 2 * A
C = torch.empty_like(A)
 
# Ensure all previous work is done
torch.cuda.synchronize()
 
# Naive, Sequential GPU operations - DO NOT DO THIS
for i in range(N):
    C[i] = A[i] + B[i]  # This launches N tiny GPU operations serially
 
torch.cuda.synchronize()
```

This code effectively uses the GPU like a scalar, non-parallel processor. It achieves very low occupancy similar to the native `addSequential` CUDA C++ code above.

Let’s optimize the CUDA kernel and PyTorch code to implement a parallel version of the vector add operation. In the CUDA C++ code below, we launch enough threads to cover all elements (`<<< (N+255)/256, 256 >>>)` so that 256 threads per block process N elements in parallel across however many blocks are needed.

```
// addParallel.cu
#include <cuda_runtime.h>
 
const int N = 1'000'000;
 
// One thread per element
__global__ void addParallel(const float* __restrict__ A,
                            const float* __restrict__ B,
                                  float* __restrict__ C,
                            int N)
{
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx < N) {
        C[idx] = A[idx] + B[idx];
    }
}
 
int main()
{
    // Allocate and initialize host
    float *h_A = new float[N], *h_B = new float[N], *h_C = new float[N];
    for (int i = 0; i < N; ++i) {
        h_A[i] = float(i);
        h_B[i] = float(i * 2);
    }
 
    // Allocate device
    float *d_A, *d_B, *d_C;
    cudaMalloc(&d_A, N * sizeof(float));
    cudaMalloc(&d_B, N * sizeof(float));
    cudaMalloc(&d_C, N * sizeof(float));
 
    // Copy inputs to device
    cudaMemcpy(d_A, h_A, N * sizeof(float), cudaMemcpyHostToDevice);
    cudaMemcpy(d_B, h_B, N * sizeof(float), cudaMemcpyHostToDevice);
 
    // Configure and launch: many threads
    int threads = 256;
    int blocks  = (N + threads - 1) / threads;
    addParallel<<<blocks, threads>>>(d_A, d_B, d_C, N);
 
    // Ensure completion before exit
    cudaDeviceSynchronize();
 
    // Cleanup
    cudaFree(d_A);
    cudaFree(d_B);
    cudaFree(d_C);
    delete[] h_A;
    delete[] h_B;
    delete[] h_C;
    return 0;
}
```

With a sufficiently large N, the difference in GPU utilization is dramatic as you’ll see in the profiling results below.

Now let’s optimize the PyTorch code which launches a single vectorized kernel (`A + B`) that engages many threads on the GPU concurrently like the optimized `addParallel` CUDA C++ above. Here is the parallel version of the PyTorch code.

```bash
# add_parallel.py
import torch
 
N = 1_000_000
A = torch.arange(N, dtype=torch.float32, device='cuda')
B = 2 * A
 
torch.cuda.synchronize()
 
# Proper parallel approach using vectorized operation
# Launches a single GPU kernel that adds all elements in parallel
C = A + B 
 
torch.cuda.synchronize()
```

###### Tip

In practice, high-level frameworks like PyTorch will do the right thing when you use vectorized tensor operations. Just be aware that introducing Python-level loops around GPU operations will serialize work and negatively impact performance. Avoid them if possible. Unless you are writing something novel, there is almost always an optimized PyTorch-native implementation available.

To quantify the performance impact of using a parallel versus sequential implementation, [Table 6-5](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch06.html#ch06_table_5_1750957012550875) shows the results of adding two vectors of length N = 1,000,000. Here, we use Nsight Systems and Nsight Compute to measure the total kernel execution time, GPU utilization, occupancy, and warp execution efficiency metrics for the two approaches.

| Metric | <br>                  `addSequential`<br> | <br>                  `addParallel`<br> |
| --- | --- | --- |
| <br>                  Kernel Execution Time (ms)<br> | <br>                  48.21<br> | <br>                  2.17<br> |
| <br>                  GPU Utilization<br> | <br>                  1.5%<br> | <br>                  95%<br> |
| <br>                  Achieved Occupancy<br> | <br>                  1.3%<br> | <br>                  38.7%<br> |
| <br>                  Warp Execution Efficiency<br> | <br>                  3.1%<br> | <br>                  100%<br> |

###### Tip

Different profiling tools may label these metrics differently. For example, Nsight Systems reports overall “GPU Utilization,” while Nsight Compute provides a per-kernel “SM Active %” metric – but both reflect how fully the GPU’s SMs were occupied by active warps.

As expected, moving from a single-thread, single-warp implementation to a fully parallel, multi-warp implementation improves occupancy from 1.3% to ~38.7% on average. This reduces the runtime by about 22× from 48.21ms down to 2.17ms.

In the sequential case, only one warp, and just 1 thread, is doing work on a single SM. This is why we see a low 1.5% GPU’s utilization. Whereas in the parallel case, many SMs are running multiple active warps. This increases warp execution efficiency from 3.1% to 100% since all 32 threads in a warp are doing useful work during each instruction. This improves GPU utilization from 1.5% to 100%.

This example shows why sufficient parallelism is critical on GPUs. No matter how fast each thread is, you need lots of threads to leverage the GPU’s throughput potential.

Remember that the GPU is a throughput-optimized processor that interacts with CPUs to launch the CUDA kernel - as well as the memory subsystem to load data from caches, shared memory, and global memory. As such, GPU performance greatly benefits from hiding these latencies.

When written properly, kernels will instruct the GPU to interleave memory loads and computations (e.g. additions) from different warps in parallel. This helps to hide memory latency across the warps.

The parallel kernel running within multiple warps, in particular, benefits from warp-level latency hiding. While one warp is waiting for a memory load, another warp can be executing the add computation, while yet another could be fetching the next data, etc. We’ll explore many techniques to hide memory latency in the upcoming chapters.

In the sequential kernel, there are no other warps to run while one is waiting, so the hardware pipelines often sit idle. Figure 6-3 illustrates this concept: in the sequential version, the timeline is one long series of operations with idle gaps during memory waits; in the parallel version, those gaps are filled by other warps’ work, so the GPU is busy continuously.

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9798341627772/files/assets/image-to-come.png)

###### Figure 6-3. TO COME: In the sequential version, the timeline is one long series of operations with idle gaps during memory waits; in the parallel version, those gaps are filled by other warps’ work, so the GPU is busy continuously.

The key takeaway is to first ensure enough parallel work to fully occupy the GPU. High occupancy—enough warps to cover latency—maximizes throughput and minimizes idle stalls. In our example, parallelizing boosted GPU utilization to ~95%.

Once sufficient threads are launched, the next step is optimizing how efficiently each warp executes, through instruction-level parallelism and other per-thread improvements. But note: even at 100% occupancy, performance can still suffer if the workload is memory bound—that is, limited by slow memory access rather than compute.

A well-known example of a memory bound workload is the “decode” phase of a large language model (LLM). During decode, the LLM needs to move a large amount of data (model weights, or parameters) from global HBM memory into the GPU registers and shared memory.

Since modern LLMs contain 100’s of billions of parameters (multiplied by, let’s say 8 bits per parameter, or 1 byte) the models can be many 100’s of gigabytes in size. Moving this much data in and out of the GPU can easily saturate the memory bandwidth.

###### Tip

GPU FLOPs are outpacing memory bandwidth. For instance, Blackwell’s HBM3e delivers ~8 TB/s, but compute capability and model sizes are growing even faster. As such, optimizing memory movement is absolutely critical to avoid memory‐bound bottlenecks in modern AI workloads.

## Tuning Occupancy with Launch Bounds

In some cases, simply using more threads isn’t enough – especially if each thread uses a lot of resources (registers or shared memory). We can guide the compiler to optimize for occupancy by using CUDA’s `__launch_bounds__` kernel annotation.

This annotation lets us specify two parameters for a kernel: (1) the maximum number of threads per block we will launch, and (2) the minimum number of thread blocks we want to keep resident on each SM. For example:

```
__global__ __launch_bounds__(256, 4)
void myKernel(...) { /* ... */ }
```

Here we promise never to launch `myKernel` with more than 256 threads per block, and we request that the GPU try to keep at least 4 blocks active per SM. These hints influence the compiler’s register allocation and inlining decisions: it will limit each thread’s register usage such that up to 256 threads can fit in one block *and* at least 4 blocks (4×256 = 1024 threads) can be active per SM.

In practice, using `__launch_bounds__` often causes the compiler to cap per-thread register usage (and to sometimes restrict unrolling or inlining) to avoid spilling and to allow higher occupancy. We are essentially trading a bit of per-thread performance (not using every last register or unrolling to the max) in exchange for steadier warp throughput by keeping more warps in flight.

**Increasing occupancy must be balanced against per-thread resources. **You want to avoid register spilling (which occurs if you force too many threads such that they run out of registers and spill to local memory, causing slow memory accesses).

You can also determine an optimal launch configuration at runtime using the CUDA Occupancy API. For example, `cudaOccupancyMaxPotentialBlockSize()` will calculate the block size that produces the highest occupancy for a given kernel, considering its register and shared memory usage. Essentially, `cudaOccupancyMaxPotentialBlockSize` can autotune your block size for optimal occupancy, as shown below:

```
int minGridSize = 0, bestBlockSize = 0;
cudaOccupancyMaxPotentialBlockSize(
    &minGridSize, &bestBlockSize,
    myKernel,
    /* dynamicSmemBytes = */ 0,
    /* blockSizeLimit = */ 0 );
    
// bestBlockSize now contains the number of threads per block that maximizes occupancy
myKernel<<<minGridSize, bestBlockSize>>>(...);
```

This API computes how many threads per block would likely maximize occupancy given the kernel’s resource usage. We can then use `bestBlockSize` (and the suggested grid size) for our kernel launch.

When applied, the compiler’s heuristics are usually good, but `__launch_bounds__` and occupancy calculators give you explicit control when needed. Use them when you *know* your kernel can trade some per-thread resource usage for more active warps. This helps prevent under-occupying SMs due to heavy threads.

###### Tip

The trade-off between registers and occupancy is important. Using fewer registers per thread – or capping them via launch bounds – allows more warps to be resident, which improves latency hiding. However, using too few registers can force the compiler to spill data to local memory, hurting performance. Finding the sweet spot often requires experimentation. Nsight Compute’s “Registers Per Thread” and “Occupancy” metrics can guide you here.

# Roofline Model: Compute-Bound or Memory-Bound Workloads

A roofline model is a useful visualization that charts two hardware-imposed performance ceilings: one horizontal line at the processor’s peak floating-point rate, and one diagonal line set by the peak memory bandwidth. Together, these form a “roofline” envelope that reveals whether a given kernel is limited by computation (compute-bound) or by data movement (memory-bound).

Where these lines intersect is called the *ridge point*. This corresponds to the “arithmetic intensity” threshold at which a kernel transitions from being memory‑bound (left of the ridge) to compute‑bound (right of the ridge). Arithmetic intensity is measured as the number of FLOPs performed per byte transferred between off‑chip global memory and the GPU.

Let’s consider a simple example to illustrate why arithmetic intensity matters. Suppose a kernel loads two 32-bit floats (8 bytes total), adds them (1 FLOP), and writes back one 32-bit float result (4 bytes). In this case, the algorithm carries out 1 FLOP for 12 bytes of memory traffic, yielding an arithmetic intensity of 0.083 FLOP/byte (1 FLOP / 12 bytes ≈ 0.083 FLOP per byte).

Compare this to Blackwell’s ridge point of 16 FLOPs per byte (16 FLOPs = 130 TFLOP/s ÷ 8 TB/s). The kernel’s ridge point of 0.083 is orders of magnitude to the left (memory-bound side) of the roofline.

Now compare this to the Blackwell GPU’s ridge point with roughly 130 TFLOP/s of FP32 peak and 8 TB/s of HBM3e bandwidth. The ridge point (peak FLOPs ÷ peak bytes) works out to about 16 FLOPs/byte.

Our float-add example achieves only 0.083 FLOP/byte – more than 100× below that threshold – so it cannot keep the ALUs busy. This kernel would sit firmly in the memory‑bound regime, meaning performance is dominated by memory stalls rather than compute.

Figure 6-4 shows the roofline model for Blackwell including both its peak compute performance (horizontal line at 130 TFLOP/s) and peak memory bandwidth (diagonal line corresponding to 8 TB/s). The ridge point for Blackwell is at the intersection point, 16 FLOPs/byte. Our example kernel is far to the left, 0.083 FLOP/byte, which is far to the left under the memory-bound “roof.”

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9798341627772/files/assets/image-to-come.png)

###### Figure 6-4. TO COME: Roofline model for the Blackwell GPU showing our kernel.

To make this kernel less memory-bound (and thus more compute-bound), you can increase its arithmetic intensity by doing more work per byte of data. This will move the kernel to the right which pushes performance up toward the compute roofline.

One simple way to make the kernel less memory bound is to use lower-precision data. For instance, if you used 16-bit floats (FP16) instead of 32-bit (FP32), you’d halve the bytes transferred per operation and instantly double the FLOP/byte intensity.

Modern GPUs also support dedicated 8-bit floating point (FP8) Tensor Cores. Blackwell also introduced native support for 4-bit floating point (FP4) Tensor Cores for certain AI workloads. These further reduce the bytes per operation and increase the FLOP/byte intensity even more.

For example, Blackwell supports FP8 tensor cores (1 byte per value) which doubles throughput and halves memory use relative to FP16. It also supports FP4 (half a byte per value) for some workloads like model inference.

A single 128-byte memory transaction can carry 32 FP32 values, 64 FP16, 128 FP8, or 256 FP4 values. Moreover, Blackwell features a dedicated [decompression engine](https://docs.nvidia.com/multi-node-nvlink-systems/multi-node-tuning-guide/overview.html) for AI model weights. This means models can be stored compressed in HBM, even beyond FP4 compression, and the hardware will decompress on the fly. This effectively increases the usable memory bandwidth further when reading those weights.

As such, Blackwell has an architecture advantage for memory-bound workloads like Transformer-based token generation. Weights are stored in a compressed 4-bit or 2-bit scheme - and decompressed by hardware at load time and cast to FP16/FP32 for higher-precision aggregations and computations. This shows how lower precision can reduce the amount of data transferred, increase arithmetic intensity for your kernel, and improve overall memory throughput for your workload.

For memory bound workloads, the goal is to push the kernel’s operational point to the right on the roofline to increase its arithmetic intensity. By moving closer to a compute-bound regime, your kernel can better exploit the GPU’s full floating-point horsepower.

###### Tip

Transformer-based models (e.g. large language models) can be both compute-bound and memory-bound in different phases. For example, attention layers (prefill phase) are typically memory-bound, while matrix multiplications (decode phase) are often compute-bound. We will discuss this more in Chapter 10 when we dive deep into mode inference.

When a kernel is memory-bound, Nsight Compute will report very high DRAM bandwidth utilization, `dram__throughput.avg.pct_of_peak_sustained`, alongside low achieved compute metrics such as low ALU utilization or `sm__sass_average_active_cycles`. This indicates that warps spend most of their time stalled on memory accesses.

To drill into what’s happening, it’s best to use Nsight Compute for per-kernel counters including latencies, cache hit rates, warp issue stalls. You can then use Nsight Systems for a holistic timeline view showing GPU idle gaps, overlap with CPU work, and PCIe/NVLink transfers. Together they give you both the “why” (which stalls and which resources), and the “when” (how those stalls fit into your application’s overall execution.)

The key is to iteratively profile and identify memory hotspots using metrics from both Nsight Compute and Nsight Systems. You should add NVTX ranges around suspect code, zoom in on timeline behavior, and use the feedback to optimize.

For instance, you can use NVTX to label regions as “memory copy” or “kernel execution” and see them in the Nsight Systems timeline. This is incredibly useful to confirm overlapping host-device transfers with compute as discussed earlier. For instance, to verify you can mark the start/end of both the `cudaMemcpyAsync` and kernel calls with NVTX markers. Nsight Systems will show these NVTX ranges on a timeline, making it easy to see overlap in the timeline. The copies (HtoD, DtoH) will overlap with kernel execution on the GPU.

If you expect overlap, but see the copies and kernels running sequentially versus parallel, then something like an unwanted default-stream synchronization or a missing pinned-memory buffer is likely preventing true overlap.

###### Tip

Without using pinned (page-locked) memory, the `cudaMemcpyAsync` transfer cannot overlap with kernel execution. This is a common performance issue.

When you suspect a kernel is starved for data, start by running it under Nsight Compute and Nsight Systems. In Nsight Compute you’ll see the Global Load Efficiency metric drop. This signals that your DRAM requests aren’t being satisfied quickly enough. At the same time, the Nsight Systems timeline will reveal idle stretches between kernel launches as the GPU waits on data transfers.

Once you’ve applied the memory-hierarchy optimizations from this chapter, those idle gaps will all but disappear, Nsight Compute will show Memory Pipe Utilization % climbing toward its peak. You’ll also see a corresponding jump in end-to-end kernel throughput.

###### Tip

Always measure after each change. Profiling tools will confirm if an optimization actually reduces memory stalls or not.

# Key Takeaways

SIMT Execution ModelGpus execute threads in warps (32 threads) under the Single-Instruction, Multiple-Thread model, with each warp issuing instructions in lock-step. High occupancy—keeping many warps in flight—hides memory and pipeline latency.

Thread Hierarchy: Threads → Blocks → GridsThreads are grouped into CTAs (up to 1,024 threads), and CTAs form a grid to scale across millions of threads without code changes. Synchronization (`__syncthreads()` or cooperative-groups) enables data reuse in shared memory but incurs overhead, so minimize barriers.

Occupancy vs.Resource Limits.Choose block sizes as multiples of 32 to avoid under-filled warps and maximize scheduler utilization. Be mindful of per-SM limits on registers, shared memory (228 KB on Blackwell), resident warps (64), and active blocks (32).

CUDA Kernel Launch ParametersStart with `threadsPerBlock = 256` (8 warps) for a balance of occupancy and resource use; compute `blocksPerGrid = (N + threadsPerBlock – 1) / threadsPerBlock` to cover all elements. Tune these values based on profiling feedback (register/register spilling, shared-memory usage, achieved occupancy).

Asynchronous Memory Management.Prefer `cudaMallocAsync`/`cudaFreeAsync` on dedicated streams and leverage CUDA memory pools to avoid global synchronizations and OS-level overhead. PyTorch’s caching allocator follows a similar pattern for efficient tensor allocations.

GPU Memory HierarchyRegisters → L1/Shared → L2 → Global (HBM3e) → Host: each level trades capacity for latency/bandwidth. Maximize data reuse in registers and shared/L1 cache.

Unified Memory ConsiderationsCuda Managed Memory simplifies programming but can incur implicit page-migrations; use `cudaMemPrefetchAsync` and memory advice to avoid surprise stalls.

Roofline Model AnalysisArithmetic intensity (FLOPs per byte) determines whether a kernel is memory-bound or compute-bound. Use lower precision (FP16/FP8/FP4 and hardware decompression) to boost FLOP/byte ratio and push kernels toward the compute roofline. Profile with Nsight Compute (per-kernel metrics) and Nsight Systems (timeline) to identify and eliminate memory stalls.

# Conclusion

This chapter has laid the groundwork for high-performance CUDA development by demystifying the GPU’s SIMT model, thread hierarchy, and multi-level memory system. You’ve learned how to choose launch parameters that maximize occupancy, manage GPU memory asynchronously, and apply roofline analysis to distinguish compute-bound from memory-bound kernels.

Armed with these fundamentals and profiling techniques, you’re ready to dive into targeted optimizations by overlapping data movement with computation, exploiting shared memory, and tuning precision. This will harness the full power of modern GPUs in your AI workloads.
