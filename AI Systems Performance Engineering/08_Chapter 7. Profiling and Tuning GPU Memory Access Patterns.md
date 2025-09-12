# Chapter 7. Profiling and Tuning GPU Memory Access Patterns

# A Note for Early Release Readers

With Early Release ebooks, you get books in their earliest form—the author’s raw and unedited content as they write—so you can take advantage of these technologies long before the official release of these titles.

This will be the 7th chapter of the final book.

If you’d like to be actively involved in reviewing and commenting on this draft, please reach out to the editor at *arufino@oreilly.com*.

As AI models grow in size and complexity, a GPU’s memory system often becomes the bottleneck that stands between theoretical compute capability and real-world performance. As you saw in Chapter 5, modern NVIDIA GPUs combine thousands of simple, throughput-optimized cores with powerful mixed-precision specialized function unit (SFU) accelerators like Tensor Cores and the Transformer Engine, high-bandwidth memory (HBM), coherent CPU-GPU unified memory, on-chip shared memory and caches, and specialized direct-memory access (DMA) data transfer engines like the Tensor Memory Accelerator (TMA).

In this chapter, you’ll see various CUDA C++ and PyTorch optimization techniques to align data structures for efficient memory access, eliminate redundant data loads, and overlap data transfers with computation using hard-war.

Through concrete before-and-after examples of matrix multiplies, tensor operations, and more, you’ll see how small changes in memory access patterns, tiling strategies, and asynchronous data transfers can reduce wasted bandwidth, boost arithmetic efficiency, and transform kernels from memory-bound to compute-bound.

By the end of this chapter, you’ll know how to write CUDA kernels that can better harness the GPU’s memory hierarchy and hardware-optimized data transfer engines.

# Avoid Warp Divergence

Remember that GPUs execute threads in groups of 32 (warps) in Single Instruction, Multiple Thread (SIMD) fashion. This means if threads within the same warp take different control flow paths typically due to an `if/else` or a loop with varying number of iterations. In these cases, the warp must execute each branch sequentially, with threads that do not take a particular branch being masked off (idle) during each execution. This phenomenon is known as warp branch divergence.

Warp divergence reduces the parallel efficiency of the warp since, when threads diverge down one path (`if` statement), the masked-out threads remain idle while the other threads execute. Then, vice versa, during the execution of the other divergent path (`else` statement).

A profiler will show symptoms of divergence as low “Warp Execution Efficiency”. This measures the average percentage of threads in a warp that are active. A warp execution efficiency of 30% means, on average, only 30% of the threads are doing useful work at any time. The rest were inactive due to divergence.

When you profile a kernel with divergent branches, the profiler will flag a high percentage of “predicated‑off” instructions. These are instructions that are fetched and issued, but do no work because their lane mask is disabled. You’ll also see an inflated “dynamic instruction” count compared to the data you actually processed. Together, those two numbers tell you that every warp is walking down all sides of your conditionals in turn, and serially.

For instance, one subset of threads, or “lanes”, executes path A while the rest of the threads sit idle. Subsequently, the idle threads become active threads and execute path B. The result is a doubling of your instruction traffic and a serious reduction in your warp’s effective throughput, or goodput since each inactive set of threads still fetches and issues instructions - even though they’re masked out.

This is somewhat easy to spot in source code as any per‑thread conditional, whether it’s a threshold check, a sparse‐data loop, or a data‑dependent filter, will trigger this serialized, repeated execution. To reclaim performance, you must eliminate or flatten those divergent branches. You can make the condition uniform across the warp, pull it out of tight loops, or replace it with arithmetic or lookup‐table techniques so that all 32 threads execute the same instruction stream and perform useful work. Let’s look at an example to make things more clear.

Consider a kernel that thresholds an array using `if (x[i] > 0) y[i] = x[i]; else y[i] = 0;`. If half the values are positive and half are not, then most warps will have some threads take the `if` branch and some take the `else` branch. The warp will first execute the `if` branch instructions for the threads when the condition is true. It will simply mask out the other threads. It then runs again and executes the `else` branch for the remaining threads. So this took 2 sets of instructions to accomplish one logical set of operations. This decreases efficiency by 50%.

There are a few strategies to reduce the impact of divergence such as changing the data layout, partitioning/regrouping data, and turning the branch into a conditional assignment (a.k.a “predication”), shuffling, warp voting, using multiple kernels, and compacting streams. Let’s take a look at each of these, then we’ll show a complete example of one of them to make things more concrete.

Use predication to eliminate branchesSometimes the divergent branch can be turned into straight-line code using arithmetic or bit tricks. In our threshold example above, one can compute `y[i] = max(x[i], 0)` without a branch. GPUs have predicated instructions that will always execute, but will only write results for threads where a condition holds. The compiler may do this automatically for simple constructs, or one can explicitly use device intrinsics. Another technique is to use our favorite: bit logic! For instance, `mask = (x[i] > 0)` (which is either 0 or 1), then `y[i] = mask * x[i]`. This way, both “paths” are executed for all threads but in a way that has no control divergence.

Data layout or partitioningIf it’s possible, one can regroup the input data so that threads within the same warp will follow similar execution paths. For instance, it might be possible to sort or separate the data upfront such that warps handle mostly homogeneous cases - either all true or all false. This isn’t always feasible but can be very effective.

Warp-vote parallel algorithmsWarp intrinsics (`__ballot_sync`, `__any_sync`, `__all_sync`), cooperative-groups’ `warp.ballot/any/all`, and device-side vote masks (`%WarpVote`) let a warp collectively decide, or vote, which lanes need “special” work. The warp then dynamically delegates, re-partitions, and compacts that work into one (or a few) lanes instead of diverging all 32 threads. This avoids per-lane branch divergence but introduces some potential load-imbalance trade-offs that you should profile for impact. We cover these details in the next chapter.

Separate into multiple kernels or stream compactionAnother approach is to separate the work into multiple kernel launches such that one kernel handles the `if` case and another handles the `else` case. You can use a prefix sum or compaction to distribute threads to the different kernels. This avoids divergence at the cost of launching more kernels and adding logic to distribute data between the kernels. This might be worth it if divergence is a big issue and the divergent sections are large enough in instruction count.

Let’s show an example using the first technique, predication, described above to eliminate branches. In the example below, if some threads in a warp satisfy `X[i] > threshold` and others do not, the warp will diverge. This is a clear example of a kernel that will cause warp branch divergence.

**Before Example (CUDA C++):**

```
// threshold_naive.cu
__global__ void threshold_naive(const float* X, float* Y, float threshold, int N) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < N) {
        if (X[i] > threshold) {
            Y[i] = X[i];    // branch 1
        } else {
            Y[i] = 0.0f;    // branch 2
        }
    }
}
```

This results in the warp executing both branches sequentially. One execution will run with the assignment `Y[i]=X[i]` for one subset of threads, and the other execution will run with `Y[i]=0` for the other subset of threads. The “warp execution efficiency” will be low - approximately 50% if half of the threads take each path.

**After Example (CUDA C++):** Here is a divergence-reduced approach using predication. In this version, we use the ternary operator which the compiler is likely to translate into a predicated move instruction (`SEL`/`MOV` based on condition) rather than an actual branch.

```
// threshold_predicated.cu
__global__ void threshold_predicated(const float* X, float* Y, float threshold, int N) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < N) {
        float x = X[i];
        // Use a conditional move or multiplication by boolean
        float val = (x > threshold) ? x : 0.0f;
        Y[i] = val;
    }
}
```

In this case, all threads execute the same instruction sequence of computing `val`, then storing it. This avoids warp divergence because the control flow is uniform across the warp. But threads for which the condition is false will just set `val=0`. The result is that warp execution efficiency stays high since all threads follow one path.

###### Tip

In simple cases, the CUDA NVCC compiler likely generated a predicated move for the ternary operator, as expected. In PTX/assembly, you would see the PTX `@p` predicate syntax to guard the write without splitting into separate warp paths..

**After Example (PyTorch):** In PyTorch, the threshold operation can be done via vectorized operations as follows.

```bash
# threshold_op.py
import torch
X = torch.randn(N, device='cuda')
Y = torch.maximum(X, torch.zeros_like(X))  # equivalent to Y = X > 0 ? X : 0
torch.cuda.synchronize()
```

The `torch.maximum` with 0 will execute on the GPU without branching since it uses elementwise max, which is implemented in a vectorized manner. Libraries like PyTorch ensure these elementwise ops are divergence-free at the warp level by using predication or bitwise tricks under the hood.

###### Tip

As you’ll see in Chapter 9, you can use just-in-time (JIT) compilation to automatically fuse pointwise operations and run them as a single kernel that better-matches the performance of the manual CUDA C++ example above. More on this in the upcoming chapter.

```bash
# jit_threshold_op.py
import torch
 
# In PyTorch 2.7+, we can JIT‐compile and fuse this operation for even higher throughput
@torch.compile(fullgraph=True)
def threshold_op(X):
    return torch.maximum(X, torch.zeros_like(X))
 
X = torch.randn(N, device='cuda')
Y = threshold_op(X)
torch.cuda.synchronize()
```

Under the hood, these types of elementwise functions compile down to SIMD‐style predication or bitwise select operations on GPUs. This ensures that every thread in a warp follows the same instruction stream and avoids the serialization penalties of divergent control flow.

Overall, reducing warp divergence improves the warp’s efficiency and yields substantial speedups in which divergence was a major issue. [Table 7-1](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch07.html#ch07_table_1_1750957019428784) shows the results of reducing warp divergence by replacing branches with predicated operations.

| Metric | NCU Counter Name | Before | After |
| --- | --- | --- | --- |
| <br>                Kernel Execution Time<br> | <br>                <br>                  `gpu__time_elapsed.avg`<br>                <br> | <br>                30 ms<br> | <br>                15 ms (–50 %)<br> |
| <br>                Dynamic Instruction Count<br> | <br>                <br>                  `smsp__inst_executed.sum`<br>                <br> | <br>                600 M instructions<br> | <br>                300 M instructions (–50 %)<br> |
| <br>                Avg. Warp Branch-Resolving Stall Latency<br> | <br>                <br>                  `smsp__average_warp_latency_issue_stalled_branch_resolving`<br>                <br> | <br>                200 cycles<br> | <br>                100 cycles (–50 %)<br> |
| <br>                Warp Execution Efficiency<br> | <br>                <br>                  `smsp__warp_execution_efficiency.avg.pct`<br>                <br> | <br>                50%<br> | <br>                99%<br> |
| <br>                Predicated-off Threads (%)<br> | <br>                <br>                  `smsp__thread_inst_executed_pred_off.avg.pct`<br>                <br> | <br>                50%<br> | <br>                0%<br> |

By replacing the two‐path branches with a single predicated `max()` operation, we saw dramatic improvements across all key Nsight Compute metrics. The kernel execution time measured by `gpu__time_elapsed.avg` dropped from 30ms to 15ms, effectively doubling throughput.

Warp Execution Efficiency climbed to nearly 100% since all threads in each warp stayed active with useful work. And the profiler further reports a 0% predicated-off ratio, indicating that no lanes were ever masked off under the predicated `max()` approach. This confirms that nearly all reconvergence overhead has been eliminated.

At the same time, the dynamic instruction count (`smsp__inst_executed.sum`) dropped by 50% from 600 million to 300 million instructions, since each warp no longer spent cycles executing both sides of the branch serially. The average warp branch-resolving stall latency (`smsp__average_warp_latency_issue_stalled_branch_resolving`) also halved, from 200 cycles down to 100 cycles.

###### Tip

If your kernel contains multiple divergence points or if each divergent branch carries heavier work, removing those branches can compound these gains—potentially yielding more than a 2× speedup per branch eliminated.

Note that predication isn’t free. Some threads still compute values (e.g. `val = x`) and their results are never used. If each branch carries substantial work, computing both sides for every thread can actually cost more than a mild divergence.

In simple cases like our threshold example, predication wins, but you should always benchmark. Try both branch-based and predicated versions under Nsight Compute’s Warp Execution Efficiency metric. If efficiency is low and each branch is light, predication will likely help.

If a branch is heavy, allowing some divergence - or using a separate kernel - may be the better path. Ultimately, minimizing divergence is crucial for SIMT performance, so structure your algorithms to keep warps on a single path when possible, and isolate any remaining divergent logic into its own kernel or warp-sized region.

###### Tip

CUDA compilers will often apply simple predication automatically for you, but it’s still worth hand-tuning and profiling for performance-critical kernels.

# Coalesced vs. Uncoalesced Global Memory Access

The memory access pattern of your code can greatly impact performance. Global memory accesses are fastest when threads in a warp access contiguous memory addresses that the hardware can combine into fewer, larger transactions. If threads access scattered or misaligned addresses, the device cannot coalesce, or combine, these accesses and take advantage of hardware support for *lookahead reads* and *128-byte cache lines* as defined by the hardware. This results in many more memory transactions retrieving unused data which quickly eats up memory bandwidth.

On a GPU with multi-terabyte per second memory throughput, such as Blackwell’s 8 TB/s, uncoalesced access leaves most of that bandwidth unused. Blackwell’s 8 TB/s HBM3e memory throughput (across 8 stacks) can deliver enormous performance. However, uncoalesced memory access keeps us far from peak performance due to excess memory transactions and stalls as shown in Figure 7-1.

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9798341627772/files/assets/image-to-come.png)

###### Figure 7-1. TO COME: Comparing uncoalesced vs. coalesced memory access pattern. (Note: each arrow = 32 byte transaction on Blackwell, label transaction size and show that 4 transactions cover 128 B. Visually distinguish unused vs. used bytes in each memory transaction (e.g., shading or color-coding the wasted portions of a 128-byte line).

In the uncoalesced case, each thread in a warp loads from scattered addresses. This results in many separate memory transactions. Even with contiguous thread addresses, misalignment to the GPU’s 128-byte L2 cache lines. For example, if a warp’s first thread starts at an address that isn’t 128-byte aligned, the warp’s memory request will cross a cache-line boundary, resulting in two 128-byte transactions instead of one.

This can force excess 32-byte transactions per request. Whereas, in the coalesced case, threads load from consecutive addresses combined into a single wide transaction.

In kernel code, this problem typically appears as *strided* or irregular indexing such that each thread reaches into different cache lines. When a kernel’s threads fetch data with strided or irregular indices, the GPU issues many small, uncoalesced global‐memory transactions rather than a handful of full‐width loads.

In Nsight Compute, you’ll see the uncoalesced memory transactions easily. First, the `smsp__gld_efficiency.avg.pct_of_peak_sustained` counter will drop which signals that only a fraction of each cache line is producing useful data. The `dram__transactions.read.sum` total will increase as many tiny reads are being issued. And `dram__sectors.read.avg.per_request` will spike well above 1 which indicates that you’re wasting bandwidth by fetching mostly unused bytes. Meanwhile `dram__throughput.avg.pct_of_peak_sustained` stays below the HBM3e limit. This confirms that your warp is spending cycles stalled on memory rather than driving the ALUs.

To break out of this memory‐bound regime, you can reorganize your data so that each warp’s 32 threads load contiguous elements. Either index the array with `input[idx]` where `idx = blockIdx.x*blockDim.x + threadIdx.x`, or switch to a structure‐of‐arrays (SoA) layout so that thread `i` always touches element `i`.

Once you make the change, the hardware will automatically combine the warp’s global memory loads into fewer, wider transactions with more usable (less wasted) data being returned. The Nsight Compute counters will immediately show improvement.

Let’s demonstrate this with an example. The following before-and-after code demonstrates how restructuring global memory accesses from a strided pattern to a contiguous pattern produces a significant performance gain.

**Before Example (C++): Uncoalesced Strided Access**. In this example, each thread copies from an input array with a stride of 2, causing misaligned memory accesses.

```
#include <cuda_runtime.h>
#include <iostream>
 
__global__ void uncoalescedCopy(const float* __restrict__ in, float* __restrict__ out, int n, int stride) {
    // n = 1048576, stride = 2
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx < n) {
        // Loads from in[] with a stride, causing multiple memory segments to be fetched
        out[idx] = in[idx * stride];
    }
}
 
int main() {
    const int n = 1 << 20;
    const int stride = 2;
    float *h_in = new float[n * stride], *h_out = new float[n];
    for (int i = 0; i < n * stride; ++i) {
        h_in[i] = static_cast<float>(i);
    }
 
    float *d_in, *d_out;
    cudaMalloc(&d_in,  n * stride * sizeof(float));
    cudaMalloc(&d_out, n * sizeof(float));
    cudaMemcpy(d_in, h_in, n * stride * sizeof(float), cudaMemcpyHostToDevice);
 
    dim3 block(256);
    dim3 grid((n + block.x - 1) / block.x);
    uncoalescedCopy<<<grid, block>>>(d_in, d_out, n, stride);
    cudaDeviceSynchronize();
 
    cudaFree(d_in);
    cudaFree(d_out);
    delete[] h_in;
    delete[] h_out;
    return 0;
}
```

The CUDA C++ kernel above issues global loads at addresses separated by a stride > 1 which is, by definition, non-contiguous. This causes each warp to generate multiple small transactions instead of a single wide transaction.

**Before Example (PyTorch)**. In PyTorch, an analogous situation can be created using a strided index for a gather operation.

```
import torch
 
def uncoalesced_copy(input_tensor, stride):
    # Generate indices with a fixed stride to gather
    idx = torch.arange(0, input_tensor.numel(), stride, device='cuda', dtype=torch.long)
    # index_select uses a gather kernel that issues uncoalesced loads
    return torch.index_select(input_tensor, 0, idx)
 
# Usage
n, stride = 1 << 20, 2
inp = torch.arange(n * stride, device='cuda', dtype=torch.float32)
out = uncoalesced_copy(inp, stride)
```

This PyTorch snippet uses `torch.index_select` with a strided index pattern, which causes the underlying GPU gather kernel to perform uncoalesced loads. Each thread loads a value from `inp` that is far apart in memory from the value loaded by the next thread which prevents coalescing.

After running the above C++ and PyTorch code on a GPU, we measure performance metrics. In the uncoalesced version, each warp’s memory request is broken into 8 separate 32-byte sectors on average. Since each 128-byte cache line fetch is split into 4 separate 32-byte sectors (more on this number 4 in a bit), the access pattern spans two lines per warp to retrieve the 8 separate 32-byte sectors.

In the unoptimized version, each warp’s uncoalesced loads break a single logical request into up to eight separate 32-byte sectors, ballooning transaction counts and starving the memory pipeline. As a result, Nsight Compute reports only about **210 GB/s** of sustained DRAM throughput.

Now, let’s optimize this by coalescing the memory accesses and making threads read contiguous elements so each warp issues fewer, larger transactions.

**After Example (C++): Coalesced Access**. By simply removing the stride (or setting it to 1), each thread copies a contiguous element. This alignment of thread accesses allows the hardware to coalesce memory requests into full 128-byte transactions.

```
#include <cuda_runtime.h>
#include <iostream>
 
__global__ void coalescedCopy(const float* __restrict__ in, float* __restrict__ out, int n) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx < n) {
        // Contiguous load: threads copy neighboring elements
        out[idx] = in[idx];
    }
}
 
int main() {
    const int n = 1 << 20;
    float *h_in = new float[n], *h_out = new float[n];
    for (int i = 0; i < n; ++i) {
        h_in[i] = static_cast<float>(i);
    }
 
    float *d_in, *d_out;
    cudaMalloc(&d_in,  n * sizeof(float));
    cudaMalloc(&d_out, n * sizeof(float));
    cudaMemcpy(d_in, h_in, n * sizeof(float), cudaMemcpyHostToDevice);
 
    dim3 block(256), grid((n + 255) / 256);
    coalescedCopy<<<grid, block>>>(d_in, d_out, n);
    cudaDeviceSynchronize();
 
    cudaFree(d_in);
    cudaFree(d_out);
    delete[] h_in; 
    delete[] h_out;
    return 0;
}
```

###### Tip

In PyTorch, a coalesced version would simply do something like `out = inp.clone()`, which copies contiguous elements efficiently. In fact, `clone()` on a contiguous tensor uses a vectorized memory copy under the hood, analogous to our coalesced kernel. As such, we leave out the coalesced PyTorch implementation for brevity since it’s already built-in.

With coalesced access, or no stride, each warp’s threads access adjacent addresses. In this case, the hardware coalesces each warp’s loads into the minimum number of 128-byte transactions - just 4 per warp versus 8 in the uncoalesced case. [Table 7-2](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch07.html#ch07_table_2_1750957019428817) shows the dramatic improvements resulting from this optimization.

| Metric | Before (Uncoalesced) | After (Coalesced) |
| --- | --- | --- |
| <br>                DRAM Throughput (GB/s)<br> | <br>                210 GB/s<br> | <br>                780 GB/s<br> |
| <br>                Global Memory Load Efficiency (gld_efficiency)<br> | <br>                23%<br> | <br>                99%<br> |
| <br>                Avg. Sectors per Request (per warp)<br> | <br>                8.0 (out of 8 max)<br> | <br>                4.0 (optimal)<br> |
| <br>                Warp State Efficiency<br> | <br>                62%<br> | <br>                99%<br> |
| <br>                Kernel Execution Time (ms)<br> | <br>                4.8 ms<br> | <br>                1.3 ms<br> |

After fixing our data layout and coalescing the global memory accesses, the kernel’s achieved DRAM throughput rises from 210 GB/s to 780 GB/s, or about 3.7× higher. The increased memory bandwidth improves the kernel execution time by 3.7×, as well, from 4.8 ms to 1.3 ms, freeing up SM resources to execute more warps in parallel and driving higher GPU utilization.

Global Load Efficiency soars from 23% to 99%, meaning nearly every byte fetched now carries useful data. At the same time, Average Sectors Per Request collapses to 4.0.

###### Tip

4.0 average sectors per request is this hardware’s optimal coalescing granularity because each warp issues one 128-byte load that the memory controller splits into exactly 4 32-byte sectors per request.

In the unoptimized case, warps often spanned 256 bytes or more, forcing two full 128-byte transactions, or 8.0 32-byte sectors per request. Hitting an average of 4.0 32-byte sectors per request confirms that each warp now performs a single fully coalesced 128-byte transaction with no wasted sectors. And since warps spend less time stalling on memory, the warp state efficiency improves from 62% to 99%.

In summary, by aligning each warp’s threads on successive addresses, the GPU’s memory controller can service each warp with a few large transactions instead of dozens of tiny ones. This boosts the global load efficiency (fraction of each transaction that returns useful data) to near 100% and raises warp state efficiency by keeping warps busy instead of idle.

And with that, you’ve seen how coalescing reshapes your thread-to-address mapping so an entire warp’s loads line up on the GPU’s 128-byte segments. However, even a fully coalesced warp still issues 32 individual 4-byte reads under the hood, one per thread, forcing the hardware to stitch them back together into each 128-byte transaction.

To eliminate that last layer of inefficiency, we turn to vectorized memory access: having each thread fetch a wider, aligned chunk (e.g. a 16-byte `float4`) in a single instruction so that a coalesced warp issues exactly four 128-byte transactions, not 32. Let’s dive into how to pack your per-thread loads into CUDA’s built-in vector types.

# Vectorized Memory Access

Efficient global‐memory access on Blackwell relies on matching your loads to the GPU’s native 128-byte transaction size. When each thread reads only a 4-byte float, a 32-thread warp still has to stitch together 32 4-byte requests to fill one 128-byte line.

This inefficiency leads to as many as 32 separate 32-byte sectors (or more if misaligned) which throttles the memory pipeline. Nsight Compute captures this waste in the Average Sectors Per Request metric, which can climb toward 32 when your accesses are purely scalar and fragmented, and you’ll see Global Load Efficiency drop as bandwidth goes underutilized.

The fix is to bundle each thread’s work into a larger, naturally aligned vector that maps cleanly onto those 128-byte transactions. CUDA’s built-in `float4` type does exactly that: it packs four 4-byte floats into a 16-byte struct guaranteed by the compiler to be 16-byte aligned. For illustration purposes, it looks something like the following code.

```
struct float4 {
    float x;  // 4 bytes
    float y;  // 4 bytes
    float z;  // 4 bytes
    float w;  // 4 bytes
};
```

When all 32 threads in a warp issue a `float4` load, they together fetch 32 × 16 bytes = 512 bytes of contiguous data, which the Blackwell memory controller then splits into exactly four 128-byte transactions (512 bytes ÷ 128 bytes per transaction = 4 transactions). This matches the ideal “4.0 sectors per request” coalescing pattern we established earlier when discussing coalseced memory access.

Compared to the unoptimized case which might require two full 128-byte transactions (eight 32-byte sectors) per warp, vectorized `float4` loads deliver an 8× reduction in sectors per warp. They also replace 4 scalar load instructions with a single 16-byte vector load per thread. This reduces instruction count by 4×.

As a result of this vectorized memory access optimization, Global Load Efficiency soars toward 100%, Average Sectors Per Request collapses to 4.0, and your observed DRAM throughput often approaches the GPU’s 8 TB/s envelope. You’ll also see higher IPC, since each load does four times the work.

To guarantee these benefits, your data pointers must be aligned to the vector size. CUDA’s `cudaMalloc()` defaults to 256-byte alignment, but you can reinforce smaller alignments with a compiler hint:

```
ptr = (float4*)__builtin_assume_aligned(ptr, 16);
```

If you ever define a larger vector type, say a custom `float8` for 32-byte loads, you must ensure 32-byte alignment using `__align__(32)` or `__builtin_assume_aligned(ptr, 32)`. This ensures that each access falls on a natural boundary and avoids split transactions.

It’s worth noting that CUDA doesn’t provide a built-in `float8`. However, you can define your own struct of 8 floats and enforce 32-byte alignment using `__align__(32)` or `__builtin_assume_aligned(ptr, 32)`.

With that in place, each thread’s vector load touches 32 bytes at once, so a 32-thread warp fetches 32 × 32 bytes = 1,024 bytes in total. The Blackwell controller then splits each 128-byte request into four 32-byte sectors which is the hardware’s perfect coalescing granularity of 4.0 Average Sectors Per Request.

###### Tip

When implementing `float8` in this manner, the number of 128-byte transactions per warp increases to 8 as you now issue 1,024 ÷ 128 = 8 full-width 128-byte loads instead of 4. But each of these requests remains fully coalesced. Ensuring strict 32-byte alignment avoids any split sectors and keeps every vector load efficient.

Let’s see an example of scalar versus vectorized memory access in a simple vector copy kernel.

**Before Example (C++): Scalar Copy** – Each thread copies one float:

```
#include <cuda_runtime.h>
 
__global__ void copyScalar(const float* __restrict__ in, float* __restrict__ out, int N) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx < N) {
        // Scalar load: 4-byte copy per thread
        out[idx] = in[idx];
    }
}
 
int main() {
    const int N = 1 << 20;
    float *h_in = new float[N], *h_out = new float[N];
    for (int i = 0; i < N; ++i) h_in[i] = float(i);
 
    float *d_in, *d_out;
    cudaMalloc(&d_in, N * sizeof(float));
    cudaMalloc(&d_out, N * sizeof(float));
    cudaMemcpy(d_in, h_in, N * sizeof(float), cudaMemcpyHostToDevice);
 
    dim3 block(256), grid((N + 255) / 256);
    copyScalar<<<grid, block>>>(d_in, d_out, N);
    cudaDeviceSynchronize();
 
    cudaFree(d_in); cudaFree(d_out);
    delete[] h_in; delete[] h_out;
    return 0;
}
```

**Before Example (PyTorch)** – A scalar element-wise copy in PyTorch could be done with a Python loop for illustration:

```
import torch
 
def copy_scalar(inp: torch.Tensor) -> torch.Tensor:
    out = torch.empty_like(inp)
    flat_in = inp.view(-1)
    flat_out = out.view(-1)
    for i in range(flat_in.numel()):
        # Each iteration issues a 4-byte load on the GPU
        flat_out[i] = flat_in[i]
    return out
 
# Usage
N = 1 << 20
inp = torch.arange(N, device='cuda', dtype=torch.float32)
out = copy_scalar(inp)
```

In the scalar version, each thread performs a single 4-byte load/store. A warp of 32 threads will only partially utilize each 128-byte transaction, leading to many transactions for a given amount of data. Next, let’s optimize by using vector loads.

**After Example (C++): Vectorized Copy** – Each thread copies a `float4` (16 bytes):

```
#include <cuda_runtime.h>
// Define a vector type matching CUDA's float4
struct float4 { float x, y, z, w; };
 
__global__ void copyVector(const float4* __restrict__ in, float4* __restrict__ out, int N4) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx < N4) {
        // Vectorized load/store: 16-byte copy per thread
        out[idx] = in[idx];
    }
}
 
int main() {
    const int N  = 1 << 20;
    const int N4 = N / 4;
    float4 *h_in  = new float4[N4];
    float4 *h_out = new float4[N4];
    for (int i = 0; i < N4; ++i) {
        // initialize 4 floats at a time
        h_in[i] = { float(4*i+0), float(4*i+1), float(4*i+2), float(4*i+3) };
    }
 
    float4 *d_in, *d_out;
    cudaMalloc(&d_in,  N4 * sizeof(float4));
    cudaMalloc(&d_out, N4 * sizeof(float4));
    cudaMemcpy(d_in, h_in, N4 * sizeof(float4), cudaMemcpyHostToDevice);
 
    dim3 block(256), grid((N4 + 255) / 256);
    copyVector<<<grid, block>>>(d_in, d_out, N4);
    cudaDeviceSynchronize();
 
    cudaFree(d_in); cudaFree(d_out);
    delete[] h_in; delete[] h_out;
    return 0;
}
```

Here we reinterpret the arrays as `float4` (we created a custom struct for clarity, but `<cuda_runtime.h>` also provides a built-in `float4` type). We launch N/4 threads, and each thread copies one `float4`. This means each thread handles 4 floats, and each warp handles 128 floats total in 4 transactions.

**After Example (PyTorch)** – We can simulate vectorized copy by using a tensor view and clone:

```
import torch
 
def copy_vectorized(inp: torch.Tensor) -> torch.Tensor:
    # Reshape into groups of 4 floats for bulk copy
    vec = inp.view(-1, 4)
    # clone() on a reshaped tensor will issue one float4 (16 B) copy per thread internally
    # (effectively a float4 per thread under the hood)
    out_vec = vec.clone()
    return out_vec.view(-1)
 
# Usage
N = 1 << 20
inp = torch.arange(N, device='cuda', dtype=torch.float32)
out = copy_vectorized(inp)
```

Calling `clone()` on the reshaped tensor causes PyTorch to perform a contiguous copy of 16-byte chunks (effectively one `float4` per thread in the internal CUDA kernel), instead of copying element by element.

###### Tip

PyTorch’s `channels_last` memory format, often used with convolutional layers, naturally aligns data to 16-byte vector boundaries. But here we explicitly reshape and clone for clarity.

By using `float4` vector loads (naturally 16-byte aligned), each thread now loads 16 bytes at once. A warp thus issues exactly 4 full 128‑byte transactions instead of 32 separate 4‑byte transactions. This shows far better utilization of memory bandwidth as shown in the results Table 67-3.

| Metric | Before (Scalar) | After (Vectorized) |
| --- | --- | --- |
| <br>                Global Load Efficiency<br> | <br>                28%<br> | <br>                97%<br> |
| <br>                Avg. Sectors per Request<br> | <br>                31.8<br> | <br>                4.0<br> |
| <br>                DRAM Throughput (GB/s)<br> | <br>                210 GB/s<br> | <br>                780 GB/s<br> |
| <br>                Kernel execution time<br> | <br>                4.2 ms<br> | <br>                1.2 ms (3.5x improvement)<br> |

These metrics confirm the improvement. Global load efficiency jumped from 28% to 97% (~3.5×) and DRAM throughput increased from 210 GB/s to 780 GB/s (~3.7×), trimming the overall kernel runtime by ~3.5×.

This optimization trimmed the kernel execution runtime by roughly 3.5× from 4.2 ms down to 1.2 ms. Global Load Efficiency jumps from 28% (scalar) to 97% (vectorized), meaning that almost every fetched 128-byte transaction is now used. The average sectors per request drops from 31.8 (out of 32) to the ideal 4.0 which represents an 8× reduction in per-warp memory transactions. This happens because each warp now issues exactly one 128-byte transaction per request, across 4.0 32-bit segments, instead of nearly one transaction per thread.

The 8× reduction in memory requests, combined with replacing 4 scalar load instructions with 1 vector load, is what increases global load efficiency from 28% to 97% and boosts sustained DRAM throughput from 200 GB/s to 780 GB/s. In this case, warps are doing far fewer memory operations and get more data with each operation, so they spend much less time waiting on memory and more time executing useful work. The end result is a significantly faster kernel.

Let’s quickly compare coalesced global memory access from the previous section to vectorized memory access discussed here. Coalescing makes sure threads in a warp all hit one big contiguous block. Vectorizing makes sure each thread fetches a wide chunk that exactly maps onto those big blocks. The differences are summarized in [Table 7-4](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch07.html#ch07_table_4_1750957019428855).

| Aspect | Coalescing (Inter-thread) | Vectorizing (Intra-thread) |
| --- | --- | --- |
| <br>                Granularity<br> | <br>                Threads ↔ Contiguous memory addresses<br> | <br>                Per-thread ↔ Vector loads<br> |
| <br>                Typical fix<br> | <br>                Contiguous indexing (stride = 1)<br> | <br>                Use `float4`/`float8` types<br> |
| <br>                Transactions/warp<br> | <br>                4 × 32 B → 128 B (if aligned)<br> | <br>                4 × 128 B (512 B) → 4×128 B<br> |
| <br>                Instruction count change<br> | <br>                Same number of loads<br> | <br>                1 vector load instead of 4 scalars<br> |
| <br>                Benefit<br> | <br>                Fewer scattered transactions<br> | <br>                Perfectly sized, fewer transactions<br> |

By combining both strategies, you ensure that warps hit contiguous blocks such that each thread fetches a wide, aligned vector. This helps you push your kernel’s memory bandwidth utilization to its peak and unlock the full power of your GPU.

# Avoid Shared-Memory Bank Conflicts

On modern NVIDIA GPUs including Blackwell, shared memory is divided into 32 banks x 4 bytes each = 128-byte per cycle bandwidth per SM. If multiple threads in a warp access the same bank, a *bank conflict* occurs. This forces the memory accesses to serialize which negates the speed advantage of shared memory.

In code, bank conflicts often occur when threads access a shared memory array with a stride that causes them to fall into the same bank. A classic example is a naive matrix transpose using a 32×32 shared memory tile. If 32 threads each read `tile[i][threadIdx.x]` such that the same column index `(threadIdx.x)` is read across different rows (`i`), all 32 threads in the warp will each access memory addresses that lie in the same shared-memory bank, causing a 32-way bank conflict as shown in Figure 7-2.

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9798341627772/files/assets/image-to-come.png)

###### Figure 7-2.  TO COME: (Bank conflicts) shows a 32-bank diagram matching Blackwell’s SM (Include an annotation that each bank can serve one thread per cycle – highlight how two threads hitting the same bank serialize.)

Specifically, during a matrix transpose, you are reading down the same column of a row-major tile by holding the column index constant (`threadIdx.x`) and varying the row index (`i`) across threads. And because each row is 128 bytes apart in memory (32 columns × 4 bytes per column = 128 bytes), the accessed memory addresses will differ by exact multiples of 128 bytes.

Remember that shared-memory banks are interleaved every 128 bytes (32 banks * 4 bytes per bank = 128 bytes), so access memory addresses offset by 128 bytes will always land back in bank 0 - hence, the full 32-way bank conflict.

Another common pitfall is using a stride equal to the number of memory banks, 32 in this case. For instance, If you stride your index by exactly 32 floats, each 4 bytes, then every thread’s address ends up differing by multiples of 128 bytes. In this case, all threads map to bank 0 as shown in the code below.

```
// Allocate a shared buffer big enough for several warps (warpCount)
__shared__ float arr[32 * warpCount]; 
 
// Each thread reads from arr[threadIdx.x * 32]
float x = arr[threadIdx.x * 32];
```

Here, `threadIdx.x * 32` in floats becomes `(threadIdx.x * 32 * 4)` bytes. Because `32 * 4 = 128`, every thread’s memory-load address is `threadIdx.x * 128` bytes . And `threadIdx.x * 128 mod 128 = 0` for all threads. They all hit bank 0 simultaneously, creating a 32-way bank conflict.

When this happens, the hardware must serialize what should have been 32 parallel reads into a sequence of single-bank accesses. In Nsight Compute you’ll see a flood of `shared_ld_bank_conflict` events and a Shared Memory Efficiency metric that drops. At the same time, the shared‐memory throughput is a fraction of its expected bandwidth. In Nsight Systems you’ll see warps are waiting on long bank-conflict stalls rather than doing useful work.

Bank conflicts force what should be parallel on-chip shared-memory accesses to replay one-by-one, wiping out any speedup you expected from buffering and often yielding disappointing, lower-than-anticipated performance. If your kernel isn’t accelerating as it should, bank conflicts are a likely culprit.

###### Tip

Always choose your stride and data layout so that threads in the same warp hit different banks and avoid that serializing bottleneck.

The solution is to adjust data layouts in shared memory to avoid conflicts. A common technique is *padding* shared arrays so that each row, or each memory access pattern, maps to different banks. For instance, if you have a 32×32 shared tile, you can declare it as `[32][33]` by adding one extra padding column so that each row now occupies 33 floats. This extra 1 element offset means that when thread `k` of a warp accesses `tile[i][k]`, successive rows start at addresses that shift across shared-memory banks. This keeps all threads from hitting the same bank.

By changing the stride to 33, no two threads in a warp will contend for the same 128-byte segment when accessing a given column. This eliminates what would have been a 32-way bank conflict.

The padding adds a negligible overhead, ~3% more memory for a 32-wide tile, but it completely eliminates the conflicts which greatly improves performance. And remember that Blackwell has >200 KB shared memory per SM. A 3% memory overhead is only 1 KB for a 32×32 tile. This is worth the performance increase.

Let’s show an example of removing shared-memory bank conflicts for a simple transpose kernel. In this example, each thread accesses shared memory addresses that fall into the same shared-memory bank as other threads. This causes the memory access to serialize, prevents parallelism, and shows slow performance. Here is the native implementation of the transpose kernel that incurs bank conflicts.

**Before Example (C++): Naive Transpose with Bank Conflicts**

```
#include <cuda_runtime.h>
#define TILE_DIM 32
 
__global__ void transposeNaive(const float *idata, float *odata, int width) {
    __shared__ float tile[TILE_DIM][TILE_DIM];
    int x = blockIdx.x * TILE_DIM + threadIdx.x;
    int y = blockIdx.y * TILE_DIM + threadIdx.y;
 
    // Write input element into shared memory (coalesced write)
    tile[threadIdx.x][threadIdx.y] = idata[y * width + x];
    __syncthreads();
 
    // Read from shared memory with transposed indices
    // This is a classic case of all threads in a warp 
    // hitting the same bank causing a bank conflict
    // (It's also not coalesced)
    odata[x * width + y] = tile[threadIdx.y][threadIdx.x];
}
 
int main() {
    const int N = 1024;
    size_t size = N * N * sizeof(float);
    float *h_idata = (float*)malloc(size);
    float *h_odata = (float*)malloc(size);
    // Initialize input h_idata...
    float *d_idata, *d_odata;
    cudaMalloc(&d_idata, size);
    cudaMalloc(&d_odata, size);
    cudaMemcpy(d_idata, h_idata, size, cudaMemcpyHostToDevice);
 
    dim3 block(TILE_DIM, TILE_DIM);
    dim3 grid(N / TILE_DIM, N / TILE_DIM);
    transposeNaive<<<grid, block>>>(d_idata, d_odata, N);
    cudaDeviceSynchronize();
 
    cudaFree(d_idata);
    cudaFree(d_odata);
    free(h_idata);
    free(h_odata);
    return 0;
}
```

In this kernel, the write into `tile` is coalesced such that each warp writes a full row of 32 floats to shared memory in a contiguous and conflict-free manner. However, the `tile` read is transposed since each thread reads a value where `threadIdx.y` is the row index and `threadIdx.x` is the column index.

As such, for a given warp, fixed `threadIdx.y` across threads 0–31, all threads access `tile[constant_row][varying_col]` meaning the same row index is used across different columns. This means all 32 addresses are in the same row of the `tile` array, which occupies a single memory bank segment and causes a 32-way bank conflict. As a result, those reads are serialized by a factor of 32.

###### Tip

Remember that Blackwell’s shared memory has** **32 banks. This number exactly matches the number of threads in a warp, 32. So if all threads index into the same bank, as happens when you fix the row and vary the column, you will always get a full 32-way conflict. This one-to-one correspondence means any misaligned access pattern at warp granularity will force every thread to serialize through the same bank - regardless of the GPU’s architectural advancements.

In this case, 32 threads attempt to read from 32 different addresses all in bank 0. This results in heavy serialization of memory accesses and poor performance. Let’s apply padding to remove the conflicts.

**After Example (C++): Padded Transpose (Avoiding Bank Conflicts)**

Here, we add a small padding, an extra unused column, so that each row of shared memory starts at a different bank modulo. This way, the bank-index collisions are eliminated by the offset.

```
#include <cuda_runtime.h>
#define TILE_DIM 32
#define PAD 1  // padding columns to avoid bank conflicts
 
__global__ void transposePadded(const float *idata, float *odata, int width) {
    // Each row is TILE_DIM+1 elements to shift bank mapping
    __shared__ float tile[TILE_DIM][TILE_DIM + PAD];
    int x = blockIdx.x * TILE_DIM + threadIdx.x;
    int y = blockIdx.y * TILE_DIM + threadIdx.y;
 
    tile[threadIdx.x][threadIdx.y] = idata[y * width + x];
    __syncthreads();
 
    odata[x * width + y] = tile[threadIdx.y][threadIdx.x];
}
```

*(The host code and setup are the same as in the naive version and omitted for brevity.)*

###### Tip

PyTorch itself doesn’t expose any high-level APIs for shared-memory padding so you would have to implement those manually in CUDA kernels and load them with `torch.utils.cpp_extension`). However, in practice, PyTorch relies on optimized libraries like cuDNN and cuBLAS which implement techniques under the hood to avoid bank conflicts and maximize throughput.

By padding each shared-memory row with an extra element, making each row 33 floats long. Padding by 1 changes the indexing math so that `tile[row][col]` addresses differ in the lower 5 bits for each thread, rather than all threads sharing the same 5-bit bank index. This ensures each thread index maps to a different bank.

In the padded kernel, when a warp reads `tile[threadIdx.y][threadIdx.x]`, the addresses for threads 0–31 span multiple banks rather than all hitting bank 0. Now that each thread in the warp accesses distinct banks on reads, bank conflicts are eliminated entirely as shown in [Table 7-5](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch07.html#ch07_table_5_1750957019428871).

| Metric | Before (No Padding) | After (Padding) |
| --- | --- | --- |
| <br>                Shared Memory Load Bank Conflicts (sm__shared_bank_conflict)<br> | <br>                4.8 million<br> | <br>                0<br> |
| <br>                Shared Memory Utilization (% of peak)<br> | <br>                52%<br> | <br>                100%<br> |
| <br>                Warp Stall Fraction (memory)<br> | <br>                38%<br> | <br>                0.5%<br> |
| <br>                Kernel Execution Time (ms)<br> | <br>                4 ms<br> | <br>                1.3ms (3x improvement)<br> |

The Nsight Compute metrics above confirm the impact: shared memory load bank conflicts dropped to 0. Shared memory throughput, according to Nsight Compute, rose from 52% to 100% of peak after eliminating conflicts. The warp stall fraction, the percentage of cycles warps spend stalled on shared-memory reads, dropped from ~38% to near 0%.

Here, we have successfully eliminated bank conflicts and unlocked the full performance of the on-chip shared memory. This change improved the kernel’s execution time by about 3× from 4 ms to 1.3 ms since shared-memory accesses went from serialized to fully parallel.

This restores full parallelism for the shared memory accesses. The cost of padding, 1 extra float per 32, is trivial (~3% memory overhead) compared to the performance gain.

An effective alternative to padding is swizzling. Swizzling is a compile-time index transformation that “scrambles” the linear index used for shared memory so that sequential threads map to different banks. For example, one can XOR the index with a bit mask or use a modulo offset to achieve a conflict-free pattern.

Swizzling avoids the slight memory overhead of padding while still ensuring perfect bank parallelism. Padding is simpler to implement, but swizzling can achieve the same goal with zero memory overhead - and it’s fun to say!

###### Tip

NVIDIA’s CUTLASS library and other high-performance CUDA-based libraries use index swizzling in their tile iterators to ensure threads map to separate banks, avoid bank conflicts, and optimize shared memory usage.

In summary, when using shared memory, it’s important that threads in a warp access different memory banks in parallel rather than queueing up on the same bank. Techniques like padding and swizzling improve shared memory load/store efficiency, yielding higher throughput and better performance whenever shared memory is used.

Next, let’s explore a technique to avoid shared memory altogether and communicate directly between threads.

## Warp Shuffle Intrinsics: Avoid Shared Memory and Explicit Synchronization

The avoiding-bank-conflicts technique above assumes that we use shared memory for communication between threads. But what if we could avoid shared memory altogether - and its bank conflict issues?

NVIDIA GPUs support warp-synchronous primitives that allow threads in the same warp to exchange data through registers instead of shared memory. In fact, these primitives only work within a single warp such that threads exchange data with their 31 siblings. So no memory banks are involved for this intra-warp communication - and therefore no bank conflicts are possible.

The most common are the `__shfl_sync` intrinsics (shuffle). `__shfl_sync` lets you broadcast a value from one thread to all other threads in a warp. You can also perform warp-level reductions without ever writing to shared memory. And remember that these intrinsics let threads exchange values through registers (instead of shared memory) which completely eliminates shared-memory bank conflicts.

###### Tip

Modern GPUs will automatically broadcast a single shared-memory value if all threads access the [exact same memory address](https://forums.developer.nvidia.com/t/does-shared-memory-have-broadcast-behavior/74380). This will avoid a bank conflict in this special, single-address case. Warp shuffles, on the other hand, use broadcasting to avoid bank issues for the more general, arbitrary, multi-value pattern of data access.

Imagine you need to sum the 32 per-thread partial results within a single warp. The naive shared-memory approach would have each thread write its value into a shared array, call a synchronization barrier, and then read and accumulate all 32 entries. This risks bank conflicts and adds additional synchronization overhead.

With `__shfl_sync`, you can do a tree-style reduction entirely in registers. For example, let’s use a convenience variant called `__shfl_down_sync` to perform a butterfly-style reduction such that each thread reads the value held by another thread that is `offset` a number of lanes away as shown below.

```
unsigned mask = 0xffffffff;
float val = threadVal;  // each thread’s partial sum
 
// Perform a butterfly reduction: exchange values with increasingly distant lanes
for (int offset = 16; offset > 0; offset >>= 1) {
    float other = __shfl_down_sync(mask, val, offset);
    val += other;
}
 
// After the loop, lane 0 holds the warp’s total sum
```

Here, each `__shfl_down_sync` directly reads another lane’s register, halving the active threads each step, until lane 0 accumulates the full sum. Because all communication stays in registers, there’s no shared-memory traffic and thus zero bank conflicts or extra synchronizations.

In short, `__shfl_sync` and its variants perform operations entirely within the warp’s execution lanes. This avoids bank conflicts because no shared memory is used. And it’s often faster since it uses registers and cuts down on the number of shared-memory instructions.

Many high-performance warp-level reductions bypass shared memory entirely by using shuffle intrinsics, which exchange values directly through registers in just a few instructions and incur no bank conflicts. CUDA’s Cooperative Groups API builds on these primitives. This API provides calls like `thread_group.shuffle()` to simplify intra-warp communication.

Remember, however, that shuffles are limited to the 32 threads within a single warp. Whenever you need to pass data across warps you must still fall back on shared or global memory with proper synchronization.

In Chapters 7 and 8, we’ll explore cross-warp, or inter-warp, patterns like cooperative group (CG) synchronization primitives, multi-warp shuffle methods, and thread block clusters, or CTA clusters. All of these ultimately use the same hardware intrinsics under the hood. Mastering both intra-warp and inter-warp techniques is essential, because memory-related bottlenecks remain one of the most common causes of GPU performance issues.

# Tiling and Data Reuse Using Shared Memory

A common performance pitfall is repeatedly reading the same data from global memory. *Tiling* is a technique to avoid this by loading chunks of data into faster on-chip shared memory - and reusing those chunks across many threads.

For example, a naive matrix multiplication of size N×N might load each element of matrix A from HBM N times, once for each row of B it multiplies with. This results in N-1 redundant loads per element. And on Blackwell, which can easily execute tens of TFLOPs, redundant loads can waste memory bandwidth which could otherwise be feeding more math operations to the GPU SMs.

Tiling eliminates this waste by having each thread-block pull a small sub-matrix (a *tile*) of A and B into shared memory exactly once. It then reuses the cached values across all threads for multiple multiply-accumulate operations. In our example below, we’ll use a 32×32 tile, which is a common choice that fits well in shared memory.

Threads within a block can cooperatively load the tile into shared memory, then call `__syncthreads()` to synchronize the data. Then the threads perform parallel matrix-multiply computations using the data in shared memory. This amortizes the global memory access cost over many threads and computations. It’s worth noting that these tile loads are also arranged to be coalesced. Specifically, each warp loads a full 128-byte segment from global memory into shared memory - consistent with the coalescing example from earlier.

By reading each element from DRAM only once (into shared memory) and reusing it for many calculations, we dramatically reduce global memory traffic. Let’s illustrate this with an N×N matrix multiplication example. First, consider a naive implementation:

**Before Example (CUDA C++): Naive Matrix Multiply**. Each thread computes one element of the result matrix C, reading entire rows of A and columns of B from global memory for each output.

```
#include <cuda_runtime.h>
#include <iostream>
 
__global__ void naiveMatMul(const float* A, const float* B, float* C, int N) {
    int row = blockIdx.y * blockDim.y + threadIdx.y;
    int col = blockIdx.x * blockDim.x + threadIdx.x;
    if (row < N && col < N) {
        float sum = 0.0f;
        for (int k = 0; k < N; ++k) {
            // Each thread loads A[row, k] and B[k, col] 
            // from global memory for every k.
            // This is very memory heavy.
            sum += A[row * N + k] * B[k * N + col];
        }
        C[row * N + col] = sum;
    }
}
 
int main() {
    const int N = 1024;
    size_t bytes = N * N * sizeof(float);
    float *h_A = new float[N*N], *h_B = new float[N*N], *h_C = new float[N*N];
    for (int i = 0; i < N*N; ++i) { h_A[i] = 1.0f; h_B[i] = 1.0f; }
 
    float *d_A, *d_B, *d_C;
    cudaMalloc(&d_A, bytes);
    cudaMalloc(&d_B, bytes);
    cudaMalloc(&d_C, bytes);
    cudaMemcpy(d_A, h_A, bytes, cudaMemcpyHostToDevice);
    cudaMemcpy(d_B, h_B, bytes, cudaMemcpyHostToDevice);
 
    dim3 block(32, 32);
    dim3 grid((N + 31) / 32, (N + 31) / 32);
    naiveMatMul<<<grid, block>>>(d_A, d_B, d_C, N);
    cudaDeviceSynchronize();
 
    cudaFree(d_A); cudaFree(d_B); cudaFree(d_C);
    delete[] h_A; delete[] h_B; delete[] h_C;
    return 0;
}
```

This CUDA C++ kernel issues global loads for every multiplication inside the inner loop. Each thread reads `A[row, k]` and `B[k, col]` from DRAM for every k, causing massive redundant traffic. The result is a heavily memory-bound kernel with low SM utilization and frequent stalls waiting on global memory. Here is the PyTorch version.

**Before Example (PyTorch): Naive Matrix Multiply**

```
import torch
 
def naive_matmul(A, B):
    N = A.size(0)
    C = torch.zeros((N, N), device='cuda')
    for i in range(N):
        for j in range(N):
            # Each dot product loads A[i,:] and B[:,j] from global memory repeatedly
            C[i, j] = (A[i, :] * B[:, j]).sum()
    return C
 
# Usage
N = 1024
A = torch.ones((N, N), device='cuda', dtype=torch.float32)
B = torch.ones((N, N), device='cuda', dtype=torch.float32)
C = naive_matmul(A, B)
```

This PyTorch implementation above uses nested Python loops. While the innermost operations are offloaded to GPU as elementwise multiply and sum operations, it still triggers repeated global loads under the hood for each dot-product. This mimics the memory-bound behavior of the naive CUDA kernel since the GPU spends most cycles waiting on memory rather than computing multiplications.

###### Tip

The PyTorch code above is extremely slow on purpose to illustrate the extreme case of performing redundant global memory access loads inside of a loop. In practice, frameworks like PyTorch use optimized kernels for this type of operation.

Now, let’s apply tiling to improve this. We divide the matrices into 32×32 tiles. 32×32 is a convenient tile size since it aligns with a warp size of 32, it fits well in shared memory, and maps to a full warp of 32 threads reading each row. This allows each warp to collaboratively load and process one full row of a tile at a time.

As such, each thread block loads one 32×32 tile of A and one 32×32 tile of B into shared memory, performs the 32×32 matrix multiplies, and accumulates the results. This way, each element of A and B is loaded from HBM only once per tile instead of 32 times in the naive version.

**After Example (CUDA C++): Tiled Matrix Multiply.** Using shared memory to cache tiles.

```
#include <cuda_runtime.h>
#include <iostream>
#define TILE_SIZE 32
 
__global__ void tiledMatMul(const float* A, const float* B, float* C, int N) {
    __shared__ float sA[TILE_SIZE][TILE_SIZE];
    __shared__ float sB[TILE_SIZE][TILE_SIZE];
 
    int row = blockIdx.y * TILE_SIZE + threadIdx.y;
    int col = blockIdx.x * TILE_SIZE + threadIdx.x;
    float sum = 0.0f;
 
    // compute partial results using the tile
    // in shared memory
    for (int t = 0; t < N; t += TILE_SIZE) {
        // Cooperative load of a tile of A and B into shared memory
        sA[threadIdx.y][threadIdx.x] = A[row * N + (t + threadIdx.x)];
        sB[threadIdx.y][threadIdx.x] = B[(t + threadIdx.y) * N + col];
        __syncthreads();
 
        // Compute using the tile loaded in shared memory
        for (int k = 0; k < TILE_SIZE; ++k) {
            sum += sA[threadIdx.y][k] * sB[k][threadIdx.x];
        }
        __syncthreads();
    }
 
    if (row < N && col < N) {
        C[row * N + col] = sum;
    }
}
 
int main() {
    const int N = 1024;
    size_t bytes = N * N * sizeof(float);
    float *h_A = new float[N*N], *h_B = new float[N*N], *h_C = new float[N*N];
    for (int i = 0; i < N*N; ++i) { h_A[i] = 1.0f; h_B[i] = 1.0f; }
 
    float *d_A, *d_B, *d_C;
    cudaMalloc(&d_A, bytes);
    cudaMalloc(&d_B, bytes);
    cudaMalloc(&d_C, bytes);
    cudaMemcpy(d_A, h_A, bytes, cudaMemcpyHostToDevice);
    cudaMemcpy(d_B, h_B, bytes, cudaMemcpyHostToDevice);
 
    dim3 block(TILE_SIZE, TILE_SIZE);
    dim3 grid((N + TILE_SIZE - 1) / TILE_SIZE, (N + TILE_SIZE - 1) / TILE_SIZE);
    tiledMatMul<<<grid, block>>>(d_A, d_B, d_C, N);
 
    // synchronize the kernel with the device 
    // for timing accuracy
    cudaDeviceSynchronize();
 
    cudaFree(d_A); cudaFree(d_B); cudaFree(d_C);
    delete[] h_A; delete[] h_B; delete[] h_C;
    return 0;
}
```

In the tiled kernel above, each block cooperatively loads a 32×32 tile of A (into `sA`) and a 32×32 tile of B (into `sB`) from global memory. These loads happen in the first two lines inside the loop, and are followed by `__syncthreads()` to ensure the tile is fully loaded before use.

Then the block performs 32×32 multiply-accumulate operations using the shared memory tiles. This inner loop, running over `k` in steps of 32, reuses each loaded value 32×, yielding a 32× reduction in global memory reads for those elements.

After finishing all tile iterations, each thread writes its result to `C`. The result is a dramatic 8× reduction in global memory accesses per thread as you’ll see in a bit.

###### Tip

These examples are focused on memory access patterns and are using FP32 CUDA cores - not the reduced precision Tensor Cores. The upcoming chapters demonstrate the use of reduced precision computations (e.g. 16-bit, 8-bit, 4-bit) to improve performance even further.

**After Example (PyTorch): Tiled Matrix Multiply**

```
import torch
 
def tiled_matmul(A, B, tile_size=32):
    N = A.size(0)
    C = torch.zeros((N, N), device='cuda')
    for i in range(0, N, tile_size):
        for j in range(0, N, tile_size):
            C_block = torch.zeros((tile_size, tile_size), device='cuda')
            for k in range(0, N, tile_size):
                A_block = A[i:i+tile_size, k:k+tile_size]
                B_block = B[k:k+tile_size, j:j+tile_size]
                # torch.mm uses an optimized kernel (likely tiling internally)
                C_block += torch.mm(A_block, B_block)
            C[i:i+tile_size, j:j+tile_size] = C_block
    return C
 
# Usage
N = 1024
A = torch.ones((N, N), device='cuda', dtype=torch.float32)
B = torch.ones((N, N), device='cuda', dtype=torch.float32)
C = tiled_matmul(A, B)
```

This PyTorch version manually tiles the matrices and invokes `torch.mm` on each tile. PyTorch’s `torch.mm` leverages NVIDIA’s cuBLAS and CUTLASS which implement shared memory tiling and reuse internally at the C++ level.

The performance impact of tiling is significant. By structuring the computation in tiles and reusing data in on-chip memory, we reduce DRAM traffic and increase arithmetic intensity since each byte retrieved from memory is used for many more FLOPs.

Along with reduced memory transactions, we’ll also see higher SM occupancy. [Table 7-6](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch07.html#ch07_table_6_1750957019428888) shows a comparison of key metrics before and after applying shared-memory tiling.

| Metric | Before (Naive Kernel) | After (Tiled Kernel) | Notes |
| --- | --- | --- | --- |
| <br>                DRAM Throughput (GB/s)<br>                (dram__throughput.avg)<br> | <br>                780 GB/s<br> | <br>                210 GB/s<br> | <br>                Naive uses more bandwidth, but it’s wasteful. The tile implementation is lower because it’s more efficient.<br> |
| <br>                CTA Launch Efficiency (active CTAs %)<br>                (sm__cta_launch_efficiency.avg.pct_of_max)<br> | <br>                42%<br> | <br>                89%<br> | <br>                CTA Launch Efficiency measures the percentage of the GPU’s CTA (thread block) capacity that was used.<br> |
| <br>                Floating-Point Throughput (GFLOP/s)<br>                (sm__sass_average_ffma_ops.pct_of_peak_sustained)<br> | <br>                15 GFLOP/s<br> | <br>                170 GFLOP/s<br> | <br>                The absolute GFLOP/s numbers are low because the matrix size (N=1024) is small and the kernel is memory-limited.<br> |
| <br>                Global Load Transactions (billion)<br>                (dram__transactions.read.sum)<br> | <br>                9.8<br> | <br>                1.2<br> | <br>                Total number of 32-byte read transactions issued by the kernel. The decrease reflects the elimination of redundant loads thanks to shared-memory tiling.<br>                Each element is fetched once per tile instead of 32 times.<br> |
| <br>                Shared Memory Throughput (% of peak)<br> | <br>                52%<br> | <br>                99%<br> | <br>                Tiled kernel avoids bank conflicts on `sA` and `sB`*.*<br> |

Here, we see the impact of staging 32×32 tiles in shared memory such that each element is fetched only once from DRAM and reused across all threads in a block. Specifically, we reduced sustained DRAM bandwidth from 780 GB/s down to 210 GB/s for a nearly 4× improvement.

The optimized kernel transfers far less data from DRAM since it is reusing data from shared memory. This reduction indicates improved efficiency and increases arithmetic intensity (FLOPs per byte) as each byte moved from memory now produces much more work.

This improvement in arithmetic intensity shifts the kernel from memory-bound to compute-bound. Remember that this is ideal since, in a compute-bound regime, the kernel’s performance is gated by the GPU’s abundant floating-point throughput (FLOP/s) rather than its comparatively-scarce memory bandwidth. This lets us fully leverage the hardware’s computational horsepower.

The sustained FLOP rate jumps from 15 GFLOP/s to 170 GFLOP/s for a nearly 11× gain. This is because shared-memory tiling boosts arithmetic intensity by reusing each loaded element across the warp.

As a result, global load transactions fall from 9.8 billion to 1.2 billion, a roughly 8× reduction since each tile’s data is fetched once and reused by all 32 threads instead of redundantly reloading it per thread. This 32× reuse of each element eliminates redundant loads - and is exactly what drives the massive throughput improvements.

Finally, the tiled (optimized) kernel accesses `sA` and `sB` in such a way that avoids shared memory-bank conflicts. This ensures Shared Memory Throughput of nearly 100%.

###### Tip

The optimized kernel’s 170 GFLOP/s is far below Blackwell’s 130 TFLOP/s FP32 peak because we only worked on 32 × 32 tiles at a time. What matters is the 11× improvement in FLOP/s. This proves that we addressed the memory bottleneck. On larger matrices, or with more compute per tile, you’d see the optimized kernel creeping closer to that 130 TFLOP/s ceiling.

Overall, we shifted this kernel from memory-bound to compute-bound which was the goal. We successfully relieved memory pressure, freed up the memory bus for other useful work, and achieved higher compute throughput.

We also see an increase from 42% to 89% in CTA Launch Efficiency, the fraction of cycles a warp scheduler issued instructions. This metric nearly doubles because the tiled kernel keeps the SMs busy more consistently.

This allows more blocks to run concurrently on the SMs. Specifically, this metric measures the fraction of cycles during which a warp scheduler issues at least one warp instruction and is actively scheduling work. Higher CTA efficiency indicates better SM utilization.

By introducing shared memory tiling, we increased per-thread work without increasing per-thread resource usage beyond available registers and shared memory. This helped our kernel achieve higher occupancy and utilization which is important on GPUs like Blackwell that have ample registers per thread to exploit.

###### Tip

Recall that each thread can use up to 255 registers. Our tiling kernel implementation stays within this limit, avoids register spilling, and preserves high performance.

We can compare the arithmetic intensity of the naive and tiled kernels by examining their sustained FLOP rates and average DRAM bandwidth. The naive version ran at 15 GFLOPs/s while moving 10 GB/s of data on average, or 1.5 FLOPs per byte. The tiled implementation, by contrast, sustained 170 GFLOPs/s while moving 21 GB/s on average, or 8 FLOPs/byte). That rise from 1.5 to 8 FLOPs per byte highlights how tiling eliminates redundant global loads and boosts the ratio of useful computation to data transferred. This shifts the kernel from memory-bound closer toward compute-bound.

It might be tempting to increase the tile size further, say 64×64, to reduce memory traffic even more. For instance, Blackwell’s 256 KB shared memory could accommodate a 64×64 tile of floats (16 KB each for A and B).

Choosing a larger tile can increase data reuse, but it also consumes more on-chip resources such as shared memory and registers. This leaves less capacity for additional blocks on each SM.

A reduction in concurrent blocks from using a larger tile size can lower occupancy and actually hurt performance if you exceed the hardware’s limits. In practice, your tile dimensions must fit within the GPU’s shared-memory and register budgets to maintain high occupancy and throughput.

###### Tip

NVIDIA’s Warp Matrix Multiply-Accumulate (WMMA) APIs use relatively small, warp-level tiles (for example, 16×16 for FP16) to balance on-chip resource use and occupancy effectively.

For a Blackwell GPU with ~228 KB of allocatable shared memory per SM, a 64×64 tile (~16 KB per input matrix tile) might still fit, but doubling the tile dimensions squares the reuse factor while quadrupling shared memory usage. There are diminishing returns and possible trade-offs.

It is recommended to experiment with different tile dimensions to balance on-chip reuse against resource limits. A 32×32 tile is a solid starting point on modern NVIDIA GPUs, but depending on your shared-memory and register usage you may find that a slightly smaller or larger tile delivers better throughput.

###### Tip

Libraries like CUTLASS also include profilers that automate this exploration, letting you find the optimal tile size for your kernel and hardware.

In short, we transformed a naive, global-memory-only matrix multiplication into a tiled implementation that uses shared memory. This enabled cooperative data reuse, reduced the number of DRAM transactions, and boosted arithmetic intensity. Both the CUDA C++ and PyTorch implementations benefited from this tiling technique.

It’s worth noting that the tiling techniques we applied manually are exactly what high-performance GPU libraries do under the hood. NVIDIA’s CUTLASS library, for instance, provides templated components to implement general matrix multiplies (GEMMs) with multiple layers of tiling. These CUTLASS components load fragments of matrices into registers and shared memory and computing partial results much like our 32×32 tile example above.

In fact, NVIDIA’s optimized cuBLAS and cuDNN libraries use similar blocking strategies at the thread, warp, and block levels to achieve near-peak throughput. NVIDIA even launched a Python-first API in early 2025 called cuTile that lets programmers describe these tile shapes in a more convenient Pythonic way. This lowers the barrier to using these tiling optimizations - and reduces the amount of boilerplate code.

The key idea is that reusing data in registers/shared memory as much as possible before going back to DRAM is fundamental, and libraries encapsulate this. So whenever possible, leverage these highly-optimized libraries (or refer to them) for performant tiling patterns.

For instance, if you use `torch.mm` in PyTorch or `cublasSgemm` in your code, under the covers it’s doing exactly this kind of tiling and memory coalescing. This is why our PyTorch example saw the same benefits automatically.

In practice, you would use high-performance libraries like cuBLAS and PyTorch’s `torch.matmul` which already implement tiling and other optimizations in C++. In production code, directly using `torch.mm` or `torch.matmul` would produce the same benefits - and possibly more, thanks to highly tuned kernels.

###### Tip

While you can definitely reuse existing tiling libraries and frameworks. However, understanding how they work, as we’ve done here, is invaluable for when you need to diagnose performance issues and possibly write your own custom kernels for specialized situations that these libraries and frameworks don’t cover. Just don’t forget to give back to the community as they’ve given you a lot!

Having covered global memory coalescing and tiling, with notes on existing optimized libraries, we next look at another on-chip consideration: shared memory bank conflicts.

# Read-Only Data Caches

When all threads read the same values or a thread re-reads data that does not change, failing to use the GPU’s caching mechanisms can bottleneck performance. For example, consider a large lookup table such as an embedding vector in an NLP model, that is read-only during inference. Many threads might need to access this vector in parallel. A naive implementation might fetch from global memory each time, even though the data is immutable and could be cached on-chip.

Note that the read-only cache we refer to here is different from the constant memory cache discussed previously in the GPU memory hierarchy section. It’s a large cache for immutable data, separate from the tiny 64 KB constant memory cache. The constant memory cache, on the other hand, is too small for big arrays. Modern architectures rely on the larger L1/read-only cache for such data, rather than trying to squeeze it into the 64 KB constant memory cache.

On modern GPUs, global loads are automatically cached in L2, and often L1. However, there is also a special read-only data cache accessible using the `__ldg()` intrinsic or simply by using `const __restrict__` qualified pointers when defining your function argument.

###### Tip

On modern CUDA compilers, marking a pointer `const __restrict__` is usually sufficient for the hardware to use the read-only cache automatically since the `__ldg()` intrinsic is internally applied.

This lets the compiler/hardware route unchanging data through a dedicated read-only L1 cache, which has lower latency - especially for broadcast accesses - and doesn’t evict other cached data.

A common performance pitfall is forgetting to tell the compiler that a buffer is truly read-only, which means it won’t emit the `LDG` (load-global) instructions or route those loads into the fast read-only cache. Instead, every access becomes a plain global load resulting in redundant DRAM traffic and spurious cache misses.

When you profile such a kernel, you’ll spot the same addresses fetched repeatedly from off-chip memory, see no `__ldg()` operations in the instruction stream, observe a surprisingly low L2 hit rate for that array, and measure elevated DRAM throughput reminiscent of an uncached workload.

The solution is to leverage the read-only path by marking data as `const __restrict__` , or by explicitly using the `__ldg()` intrinsic to load it. This tells the hardware that the data will not be modified, allowing it to be cached in the specialized read-only cache which sits alongside L1 and has lower latency for broadcast loads.

When a warp issues a constant‐cache load (`__constant__` or uniform `__ldg()` in older GPUs), the hardware can service all 32 lanes with a single transaction if they hit the same address. By broadcasting that value to every thread, it uses only one cycle instead of doing 32 separate loads. This warp-wide broadcast reduces both latency and memory bandwidth usage for uniform data like lookup tables, coefficients, etc. This lets you fetch a shared constant, for free essentially, once per warp rather than 32 times per warp (1 per thread).

As an example of caching benefits using the standard read-only cache, suppose we have a kernel that, for each thread, looks up a value from a table of size T=1024 and writes it to an output. This simulates an embedding-lookup pattern.

**Before Example (C++): Uncached Lookup**. Consider each lookup going to global memory directly.

```
#include <cuda_runtime.h>
#define T 1024
 
__global__ void naiveLookup(const float* table, float* out, int N) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx < N) {
        // __ldg not used here, each access goes to 
        // global memory without using read-only cache
        int t = idx % T;
        out[idx] = table[t];
    }
}
 
int main() {
    const int N = 1 << 20;
    float *h_table = new float[T], *h_out = new float[N];
    for (int i = 0; i < T; ++i) h_table[i] = float(i);
 
    float *d_table, *d_out;
    cudaMalloc(&d_table, T * sizeof(float));
    cudaMalloc(&d_out, N * sizeof(float));
    cudaMemcpy(d_table, h_table, T * sizeof(float), cudaMemcpyHostToDevice);
 
    dim3 block(256), grid((N + 255) / 256);
    naiveLookup<<<grid, block>>>(d_table, d_out, N);
    cudaDeviceSynchronize();
 
    cudaFree(d_table);
    cudaFree(d_out);
    delete[] h_table; delete[] h_out;
    return 0;
}
```

**Before Example (PyTorch)** – A similar effect in PyTorch via a Python loop:

```
import torch
 
def naive_lookup(table: torch.Tensor, N: int) -> torch.Tensor:
    out = torch.empty(N, device='cuda')
    flat_tbl = table.view(-1)
    for i in range(N):
        # Each iteration results in a global memory load (no caching hint)
        out[i] = flat_tbl[i % T]
    return out
 
# Usage
T = 1024
N = 1 << 20
table = torch.arange(T, dtype=torch.float32, device='cuda')
out = naive_lookup(table, N)
```

In these naive versions, each lookup of `table[t]` likely hits in L2 after the first use (since L2 will cache it), but there is no use of the specialized read-only cache. The hardware may still treat it as normal global data, which could evict other useful data or not take full advantage of broadcast caching if multiple threads read the same `table[t]` in a warp.

Now we optimize the kernel by marking the table as `const __restrict__`. This will hint to the hardware that it should use the read-only cache path.

**After Example (C++): Using **`const __restrict__` **to access the read-only cache.**

```
#include <cuda_runtime.h>
#define T 1024
 
__global__ void ldgLookup(const float* __restrict__ table, float* out, int N) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx < N) {
        int t = idx % T;
        // Compiler will turn this into an LDG load from the read-only cache for faster loads
        out[idx] = table[t];
    }
}
 
 
int main() {
    const int N = 1 << 20;
    float *h_table = new float[T], *h_out = new float[N];
    for (int i = 0; i < T; ++i) h_table[i] = float(i);
 
    float *d_table, *d_out;
    cudaMalloc(&d_table, T * sizeof(float));
    cudaMalloc(&d_out, N * sizeof(float));
    cudaMemcpy(d_table, h_table, T * sizeof(float), cudaMemcpyHostToDevice);
 
    dim3 block(256), grid((N + 255) / 256);
    ldgLookup<<<grid, block>>>(d_table, d_out, N);
    cudaDeviceSynchronize();
 
    cudaFree(d_table);
    cudaFree(d_out);
    delete[] h_table; delete[] h_out;
    return 0;
}
```

In a PyTorch setting, you could implement the same trick by writing a small CUDA extension with `torch.utils.cpp_extension` that declares your embedding table pointer as `const __restrict__`. However, we’ve left that out here for brevity.

In short, by marking the table `const __restrict__`, you signal to the compiler and hardware that these values never change, so every load is automatically steered through the SM’s read‐only data cache (the LDG path) rather than going all the way to DRAM.

That simple qualifier transformation shifts your embedding‐lookup traffic into low-latency, high-bandwidth on-chip cache, yielding much higher cache-hit rates and far fewer global‐memory transactions. [Table 7-7](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch07.html#ch07_table_7_1750957019428902) presents Nsight Compute measurements before and after this change. The metrics show a jump in read-only cache utilization and a corresponding fall in DRAM bandwidth usage.

| <br>                Metric<br> | <br>                Before (No `__restrict__`)<br> | <br>                After (`__restrict__` used)<br> |
| --- | --- | --- |
| <br>                Global Load Efficiency<br> | <br>                52%<br> | <br>                97%<br> |
| <br>                DRAM Throughput (GB/s)<br> | <br>                600 GB/s<br> | <br>                200 GB/s<br> |
| <br>                L2 Read Throughput (GB/s)<br> | <br>                1,500 GB/s<br> | <br>                1,800 GB/s<br> |
| <br>                SM Active %<br> | <br>                45%<br> | <br>                93%<br> |
| <br>                Kernel Execution Time (ms)<br> | <br>                2.5 ms<br> | <br>                1.0 ms<br> |

After marking our lookup table with `const __restrict__` and letting the compiler steer loads into the read-only cache, the kernel’s execution time improved by 2.5× by dropping from 2.5 ms to 1.0 ms. This is because the SMs spent far less time stalled waiting on DRAM. In fact, the SM Active % rose from 45% to 93%, showing that nearly every cycle a warp was doing useful work instead of idling on memory stalls.

Under the hood, this change shifted roughly two-thirds of our memory traffic off of the DRAM bus and onto on-chip caches. DRAM throughput fell from 600 GB/s down to 200 GB/s, while L2 read throughput climbed from 1,500 GB/s to 1,800 GB/s as more requests were satisfied by the larger, lower-latency L2 cache. At the same time, Global Load Efficiency jumped from 52% to 97%, confirming that nearly every cache line we fetched carried useful data.

###### Tip

Nsight Systems reports overall “GPU Utilization” on its timeline, whereas Nsight Compute exposes “SM Active %” per kernel. Both of these metrics measure the utilization of your GPU.

Because so much of our traffic now lives in multi-level caches instead of traveling off-chip, the compute units remain fed with data and arithmetic intensity skyrockets. This memory–compute balance is what moves a kernel from the memory-bound to the compute-bound regime.

Beyond the L1 and L2 hierarchies, NVIDIA GPUs also offer texture memory (read-only) and surface memory (read/write) with their own dedicated caches optimized for 2D and 3D spatial locality. By binding an array to a `cudaTextureObject_t` and using `tex1Dfetch` or `tex2D` fetches, you let the hardware exploit image-style access patterns, adjacent threads in (x,y) fetching neighboring pixels, with high cache hit rates and built-in features like wrapping and interpolation. Surface memory behaves similarly but allows writes, which can be invaluable for algorithms that both read and write spatial data.

In summary, mark read-only data as `const __restrict__` to tap into the low-latency read-only cache, cutting DRAM traffic and lifting SM activity. Consider texture or surface memory whenever your access pattern has 2D/3D locality that a regular cache might not handle optimally. Together, these techniques collapse memory stalls, boost cache utilization, and unlock substantial performance gains for memory-bound kernels.

# Asynchronous Memory Prefetching and Tensor Memory Accelerator

In earlier sections we saw how coalescing dozens of 4-byte loads into a single 128-byte transaction dramatically improved global-load efficiency and cut wasted sectors per request. Yet even a perfectly coalesced load still stalls a warp for the full DRAM round-trip.

On Blackwell, for instance, a full DRAM round-trip can be on the order of 800 cycles before any computation can begin. To hide that latency, we need to overlap data transfer with compute.

CUDA’s Pipeline API together with the Tensor Memory Accelerator (TMA) hardware engine take this idea to the thread-block level. Instead of having each warp use the SM’s load and store (LD/ST) units to fetch data from global memory, you can invoke the TMA engine to asynchronously fetch an entire tile from global memory into shared memory as shown here.

```
cuda::memcpy_async(pipe, sharedBuf, globalPtr + offset, bytes, cuda::pipeline_scope::cta);
pipeline_commit(pipe);
```

Here, `cuda::memcpy_async` starts the transfer using TMA’s on-chip direct-memory access (DMA) engine. And while TMA handles the bulk copy, including coalescing, strided transfers, and even multi-dimensional transfers, the kernel computes the previous tile. This is called *double-buffering*, or *ping-ponging*.

By implementing double-buffering with TMA, the SM’s load/store units are now free to do real work because TMA’s DMA engine moves data for us in the background. In effect, data movement becomes asynchronous such that, while TMA streams in the next tile of data, the SM’s warps compute on the previous tile. This overlap is what hides the 800-cycle DRAM latency.

Specifically, TMA is capable of 1D–5D bulk copies, and arbitrary strides, between global and shared memory without blocking the SM instruction pipeline. By offloading these transfers from the SM to TMA, your kernel issues far fewer load/store instructions, eliminates extra synchronization, and lets the warp schedulers spend almost every cycle on useful computation instead of waiting on memory.

Below is a pseudo-code snippet showing how to initiate an asynchronous copy from global to shared memory using the CUDA C++ Pipeline API and the TMA hardware engine.

```
#include <cuda/pipeline>
#include <cuda_runtime.h>
 
#define TILE_SIZE 1024  // example tile size
// User-provided compute function operating on a shared-memory tile
__device__ void processTile(const float* tile);
 
__global__ void kernelWithTMA(const float* __restrict__ global_ptr,
                              int nTiles) {
    // Two ping-pong buffers in shared memory
    __shared__ float tile0[TILE_SIZE];
    __shared__ float tile1[TILE_SIZE];
    float* tiles[2] = { tile0, tile1 };
 
    size_t bytes = TILE_SIZE * sizeof(float);
    // Block-scoped pipeline for TMA
    auto pipe = cuda::pipeline<cuda::thread_scope::block>();
 
    // Prime pipeline with the first async copy into tile0
    pipe.producer_acquire();
    cuda::memcpy_async(pipe,
                       tiles[0],
                       global_ptr + 0 * TILE_SIZE,
                       bytes,
                       cuda::pipeline_scope::cta);
    pipe.producer_commit();
 
    // Loop over the remaining tiles
    for (int t = 1; t < nTiles; ++t) {
        // Wait for the previous copy to finish, then compute on it
        pipe.consumer_wait();
        processTile(tiles[(t - 1) & 1]);
        pipe.consumer_release();
 
        // Enqueue the next async copy into the alternate buffer
        pipe.producer_acquire();
        cuda::memcpy_async(pipe,
                           tiles[t & 1],
                           global_ptr + t * TILE_SIZE,
                           bytes,
                           cuda::pipeline_scope::cta);
        pipe.producer_commit();
    }
 
    // Final wait and compute on the last tile
    pipe.consumer_wait();
    processTile(tiles[(nTiles - 1) & 1]);
    pipe.consumer_release();
}
```

Immediately after kernel launch, each block allocates two shared-memory tiles (`tile0`, `tile1`) and constructs a block-scoped pipeline so all CTA threads coordinate their asynchronous DMA as shown here.

```
auto pipe = cuda::pipeline<cuda::thread_scope::block>();
```

To prime the pipeline, we submit an asynchronous copy via the Tensor Memory Accelerator (TMA), which coalesces even strided or multi-dimensional transfers and streams `bytes` from global memory into `tiles[0]` in the background as seen here.

```
pipe.producer_acquire();
cuda::memcpy_async(pipe,
                   tiles[0],
                   global_ptr + 0 * TILE_SIZE,
                   bytes,
                   cuda::pipeline_scope::cta);
pipe.producer_commit();
```

Before using that data, we do the following to ensure we block just long enough for the TMA to finish the copy.

```
pipe.consumer_wait();
processTile(tiles[0]);
pipe.consumer_release();
```

The, inside the main loop, we alternate buffers using `pipe.consumer_wait()` + `processTile()` on the previous tile, `pipe.consumer_release()`, `pipe.producer_acquire()` + new `cuda::memcpy_async()` into the other tile, and `pipe.producer_commit()`. Then we repeat!

By ping-ponging between `tile0` and `tile1`, each new `memcpy_async` overlaps `processTile` on the previous buffer. The SM’s load/store units stay free for computation, while the TMA engine moves data in parallel. This eliminates redundant global loads, removes extra synchronization, and keeps warps busy instead of stalled on memory.

In short, asynchronous prefetching from global memory to shared memory is a powerful way to hide memory latency behind compute. Instead of each thread fetching data from global memory right when it’s needed - and stalling until it arrives, threads can pre-load upcoming data into fast on-chip shared memory while simultaneously doing computations on previously loaded data.

This is especially powerful in memory-bound loops or tensor computations. For instance, Blackwell’s TMA can stream in the next batch of data for a matrix multiply while the current tile is being processed - exactly the pattern we’ll demonstrate.

We’ve effectively traded dozens of random global reads for one coalesced global copy plus many fast shared-memory loads. This is an excellent trade given the orders-of-magnitude latency and bandwidth gap between DRAM and on-chip SRAM.

By applying asynchronous prefetch with TMA to our strided-access kernel, we not only match the coalescing efficiency of our manual optimization but also overlap communication with compute, hiding nearly all of the DRAM latency. [Table 7-8](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch07.html#ch07_table_8_1750957019428919) summarizes key Nsight Compute metrics before and after the TMA-based double buffering implementation.

| <br>                Metric<br> | <br>                Before (No Prefetch)<br> | <br>                After (Async Prefetch)<br> |
| --- | --- | --- |
| <br>                Global Load Efficiency<br> | <br>                23%<br> | <br>                99%<br> |
| <br>                Avg. Sectors per Request<br> | <br>                6.4<br> | <br>                4.0<br> |
| <br>                Global Memory Throughput<br> | <br>                210 GB/s<br> | <br>                780 GB/s<br> |
| <br>                Warp State Efficiency<br> | <br>                62%<br> | <br>                100%<br> |
| <br>                Kernel Execution Time<br> | <br>                18 ms<br> | <br>                7 ms<br> |

Here, we see Warp State Efficiency rises to 100% which shows that warps are never idle waiting for data. This confirms that TMA + double-buffering successfully keeps the GPU busy with active warps.

We also see that Global Load Efficiency jumps from 23% to 99%, meaning nearly every byte fetched is useful. Average Sectors per Request falls from 6.4 to the ideal 4.0. And remember that 4.0 sectors per request corresponds to one fully coalesced 128-byte transaction per warp, which is the hardware’s ideal.

DRAM Throughput increases from 210 GB/s to 780 GB/s (3.7×). And the combined effect is a 2.6× speedup from 18 ms to 7 ms.

These results confirm that offloading bulk copies from the SM to TMA - and ping-ponging between shared-memory buffers - fully unleashes Blackwell’s massive HBM bandwidth and hides memory latency behind useful work.

NVIDIA’s CUDA `pipeline` API plus TMA is a textbook example of hardware-software co-design. The Pipeline API specifically exposes TMA’s capabilities - and the TMA hardware supports exactly the asynchronous, coalesced, multi-dimensional copies that `cuda::memcpy_async` needs.

The API and the TMA DMA engine were developed hand‐in‐hand so you can express high-level pipeline operations that map one-to-one onto the hardware’s transfer capabilities. This allows the efficient overlap of memory movement with compute to boost performance.

###### Tip

For almost all cases, you should write your CUDA kernels with the highest-level and most-recent APIs available including `cuda::memcpy_async`. These libraries are constantly improving and will transparently leverage the latest hardware features like TMA, for instance, when you upgrade - without requiring code changes.

In summary, when memory access limits your kernel’s performance, offload and overlap data movement by combining careful tiling, double-buffering, and TMA-driven asynchronous prefetching. By staging tiles in shared memory and using `cuda::memcpy_async` alongside `pipeline_commit`/`pipeline_wait_prior`, you hand off coalesced, multi-dimensional DMA transfers to the Tensor Memory Accelerator, freeing the SM’s load/store units to keep the computation pipeline full. On Blackwell’s massive-bandwidth HBM3e fabric, these techniques are essential to hide DRAM latency, sustain peak throughput, and turn memory-bound kernels into near-compute-bound workhorses.

# Key Takeaways

Optimizing memory access patterns on GPUs – through coalescing, data reuse, and asynchronous transfers – can shift a kernel from being memory-bound to approaching the hardware’s peak capabilities. Small code changes to better align with GPU architecture (such as proper thread grouping, using shared memory, avoiding bank conflicts) can yield massive performance gains. Below are the key takeaways from this chapter.

Global-Memory CoalescingCoalescing is achieved when each warp’s accesses fall within as few 128-byte cache lines as possible. Arrange your data and thread indices so that each warp’s threads read consecutive 4-byte words, letting the hardware fuse them into a few 128-byte transactions. Coalesced memory loads maximize effective DRAM bandwidth, or Global Load Efficiency, and minimize Average Sectors Per Request down to the optimal 4.0 value.

Vectorized Loads/StoresUse built-in vector types like `float4` (16 B, 16-byte aligned) so each thread moves multiple elements in one instruction. This cuts memory transactions per warp by 8× (and instruction count by 4×) and lands you exactly at the GPU’s ideal “4.0 sectors per request.” Be mindful of alignment: ensure your arrays are allocated with at least 16-byte alignment for `float4`, which `cudaMalloc` does by default using 256-byte alignment, typically. Misaligned vector accesses will forfeit these benefits.

Bank-Conflict AvoidancePad your shared-memory arrays (e.g. make rows 33 floats wide for 32-thread warps) so that no two threads hit the same bank in the same cycle. Removing bank conflicts restores full shared-memory throughput. Try swizzling for a slightly more memory-efficient implementation than padding.

Shared-Memory Tiling & Data ReuseStage working sets in on-chip shared memory (e.g. tiling a matrix in 32×32 blocks) so each element is fetched once from DRAM but used many times on the SM. This raises arithmetic intensity and shifts kernels toward being compute-bound.

Read-Only Data CacheMark small, static lookup tables or coefficients as `const __restrict__` (or use `__ldg()`) so the compiler routes loads through the dedicated 64 KB read-only cache. Uniform broadcasts cost ~1–2 cycles instead of DRAM’s hundreds.

Overlap Host–GPU Copies with StreamsAllocate your host buffers as page-locked (“pinned”) memory, and use `cudaMemcpyAsync` on multiple streams to overlap H2D/D2H transfers with kernel execution. Pinned memory plus streams enables true DMA and hides PCIe/NVLink interconnect latency. Even on modern GPU systems with NVLink-C2C (900 GB/s throughput), overlapping CPU–GPU transfers with compute is essential to fully utilize the GPU.

Asynchronous Prefetch with TMA + Pipeline APIUse the C++ Pipeline API (`cuda::memcpy_async`, `pipeline_commit`, `pipeline_wait_prior`) to drive the Tensor Memory Accelerator (TMA) DMA engine. This offloads coalesced, strided (even multi-dimensional) copies into shared memory and overlaps them with computation via double-buffering, freeing the SM’s load/store units entirely.

Profile to Guide YouRely on Nsight Compute metrics like Global Load Efficiency, Avg Sectors/Request, Shared Memory Bank Conflicts, SM Active %, Warp Stall reasons, etc. Also, review Nsight Systems timelines to pinpoint bottlenecks and verify each optimization moved the needle.

## Conclusion

With your memory-access pipeline now firing on all cylinders with coalesced global loads, conflict-free tiling, vectorized fetches, read-only caching, and TMA-driven prefetching, you’ve removed the biggest data-movement bottlenecks and freed the SMs to run at full speed.

Throughout this chapter we’ve relied on Nsight Compute and Nsight Systems to expose exactly where warps were starving for data. We also used them to confirm, step by step, that each optimization really did reduce stalls, collapse wasted transactions, and boost sustained bandwidth. Those tools remain your north star whenever you tune a new kernel.

In [Chapter 7](https://learning.oreilly.com/library/view/ai-systems-performance/9798341627772/ch07.html#ch07_profiling_and_tuning_gpu_memory_access_patterns_1750957019445498), we’ll pick up where this chapter leaves off and show you how to drive the GPU’s compute engines themselves: tiling and pipeline patterns for Tensor Cores and SFUs, warp-specialization with cooperative groups, and mixed-precision strategies that squeeze every FLOP out of the hardware.

In Chapter 8, we’ll turn our attention to the overall orchestration of those kernels including CUDA stream hierarchies, CUDA Graphs, dynamic parallelism, and multi-GPU coordination. This way, you can schedule and launch work in a way that keeps every compute lane busy and every byte of HBM fully utilized.
