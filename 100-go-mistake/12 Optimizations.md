# 12 Optimizations

This chapter covers:
* Delving into the concept of mechanical sympathy
* Understanding heap vs. stack and reducing allocations
* Using standard Go diagnostics tooling
* Understanding how the garbage collector works
* Running Go inside Docker and Kubernetes

Before we begin this chapter, a disclaimer: in most contexts, writing readable, clear code is better than writing code that is optimized but more complex and difficult to understand. Optimization generally comes with a price, and we advocate that you follow this famous quote from software engineer Wes Dyer:

> Make it correct, make it clear, make it concise, make it fast, in that order.

That doesn’t mean optimizing an application for speed and efficiency is prohibited. For example, we can try to identify code paths that need to be optimized because there’s a need to do so, such as making our customers happy or reducing our costs. Throughout this chapter, we discuss common optimization techniques; some are specific to Go, and some aren’t. We also discuss methods to identify bottlenecks so we don’t work blindly.

## 12.1 #91: Not understanding CPU caches

*Mechanical sympathy* is a term coined by Jackie Stewart, a three-time F1 world champion:

> You don’t have to be an engineer to be a racing driver, but you do have to have mechanical sympathy.

In a nutshell, when we understand how a system is designed to be used, be it an F1 car, an airplane, or a computer, we can align with the design to gain optimal performance. Throughout this section, we discuss concrete examples where a mechanical sympathy for how CPU caches work can help us optimize Go applications.

### 12.1.1 CPU architecture

First, let’s understand the fundamentals of CPU architecture and why CPU caches are important. We will take as an example the Intel Core i5-7300.

Modern CPUs rely on caching to speed up memory access, in most cases via three caching levels: L1, L2, and L3. On the i5-7300, here are the sizes of these caches:

* L1: 64 KB
* L2: 256 KB
* L3: 4 MB

The i5-7300 has two physical cores but four logical cores (also called *virtual cores* or *threads*). In the Intel family, dividing a physical core into multiple logical cores is called Hyper-Threading.

Figure 12.1 gives an overview of the Intel Core i5-7300 (`Tn` stands for *thread n*). Each physical core (core 0 and core 1) is divided into two logical cores (thread 0 and thread 1). The L1 cache is split into two sub-caches: L1D for data and L1I for instructions (each 32 KB). Caching isn’t solely related to data—when a CPU executes an application, it can also cache some instructions with the same rationale: to speed up overall execution.

![Figure 12.1 The i5-7300 has three levels of caches, two physical cores, and four logical cores.](https://drek4537l1klr.cloudfront.net/harsanyi/Figures/CH12_F01_Harsanyi.png)

The closer a memory location is to a logical core, the faster accesses are (see http://mng.bz/o29v):

* L1: about 1 ns
* L2: about 4 times slower than L1
* L3: about 10 times slower than L1

The physical location of the CPU caches can also explain these differences. L1 and L2 are called *on-die*, meaning they belong to the same piece of silicon as the rest of the processor. Conversely, L3 is *off-die*, which partly explains the latency differences compared to L1 and L2.

For main memory (or RAM), average accesses are between 50 and 100 times slower than L1. We can access up to 100 variables stored on L1 for the price of a single access to the main memory. Therefore, as Go developers, one avenue for improvement is making sure our applications use CPU caches.

### 12.1.2 Cache line

The concept of cache lines is crucial to understand. But before presenting what they are, let’s understand why we need them.

When a specific memory location is accessed (for example, by reading a variable), one of the following is likely to happen in the near future:

* The same location will be referenced again.
* Nearby memory locations will be referenced.

The former refers to temporal locality, and the latter refers to spatial locality. Both are part of a principle called *locality of reference*.

For example, let’s look at the following function that computes the sum of an `int64` slice:

```go
func sum(s []int64) int64 {
    var total int64
    length := len(s)
    for i := 0; i < length; i++ {
        total += s[i]
    }
    return total
}
```

In this example, temporal locality applies to multiple variables: `i`, `length`, and `total`. Throughout the iteration, we keep accessing these variables. Spatial locality applies to code instructions and the slice `s`. Because a slice is backed by an array allocated contiguously in memory, in this case, accessing `s[0]` means also accessing `s[1]`, `s[2]`, and so on.

Temporal locality is part of why we need CPU caches: to speed up repeated accesses to the same variables. However, because of spatial locality, the CPU copies what we call a *cache line* instead of copying a single variable from the main memory to a cache.

A cache line is a contiguous memory segment of a fixed size, usually 64 bytes (8 `int64` variables). Whenever a CPU decides to cache a memory block from RAM, it copies the memory block to a cache line. Because memory is a hierarchy, when the CPU wants to access a specific memory location, it first checks in L1, then L2, then L3, and finally, if the location is not in those caches, in the main memory.

Let’s illustrate fetching a memory block with a concrete example. We call the `sum` function with a slice of 16 `int64` elements for the first time. When `sum` accesses `s[0]`, this memory address isn’t in the cache yet. If the CPU decides to cache this variable (we also discuss this decision later in the chapter), it copies the whole memory block; see figure 12.2.

![Figure 12.2 Accessing s[0] makes the CPU copy the 0x000 memory block.](https://drek4537l1klr.cloudfront.net/harsanyi/Figures/CH12_F02_Harsanyi.png)

At first, accessing `s[0]` results in a cache miss because the address isn’t in the cache. This kind of miss is called a *compulsory miss*. However, if the CPU fetches the 0x000 memory block, accessing elements from 1 to 7 results in a cache hit. The same logic applies when `sum` accesses `s[8]` (see figure 12.3).

![Figure 12.3 Accessing s[8] makes the CPU copy the 0x100 memory block.](https://drek4537l1klr.cloudfront.net/harsanyi/Figures/CH12_F03_Harsanyi.png)

Again, accessing `s8` results in a compulsory miss. But if the `0x100` memory block is copied into a cache line, it will also speed up accesses for elements 9 to 15. In the end, iterating over the 16 elements results in 2 compulsory cache misses and 14 cache hits.

> ##### CPU caching strategies
>
> You may wonder about the exact strategy when a CPU copies a memory block. For example, will it copy a block to all the levels? Only to L1? In this case, what about L2 and L3?
>
> We have to know that different strategies exist. Sometimes caches are inclusive (for example, L2 data is also present in L3), and sometimes caches are exclusive (for example, L3 is called a *victim cache* because it contains only data evicted from L2).
>
> In general, these strategies are hidden by CPU vendors and not necessarily useful to know. So, we won’t delve deeper into these questions.

Let’s look at a concrete example to illustrate how fast CPU caches are. We will implement two functions that compute a total while iterating over a slice of `int64` elements. In one case we will iterate over every two elements, and in the other case over every eight elements:

```go
func sum2(s []int64) int64 {
    var total int64
    for i := 0; i < len(s); i+=2 {
        total += s[i]
    }
    return total
}

func sum8(s []int64) int64 {
    var total int64
    for i := 0; i < len(s); i += 8 {
        total += s[i]
    }
    return total
}
```

> 1.  Iterates over every two elements
> 2.  Iterates over every eight elements

Both functions are the same except for the iteration. If we benchmark these two functions, our gut feeling may be that the second version will be about four times faster because we have to increment over four times fewer elements. However, running a benchmark shows that `sum8` is only about 10% faster on my machine: still faster, but only 10%.

The reason is related to cache lines. We saw that a cache line is usually 64 bytes, containing up to eight `int64` variables. Here, the running time of these loops is dominated by memory accesses, not increment instruction. Three out of four accesses result in a cache hit in the first case. Therefore, the execution time difference for these two functions isn’t significant. This example demonstrates why the cache line matters and that we can easily be fooled by our gut feeling if we lack mechanical sympathy—in this case, for how CPUs cache data.

Let’s keep discussing locality of reference and see a concrete example of using spatial locality.

### 12.1.3 Slice of structs vs. struct of slices

This section looks at an example that compares the execution time of two functions. The first takes as an argument a slice of structs and sums all the `a` fields:

```go
type Foo struct {
    a int64
    b int64
}

func sumFoo(foos []Foo) int64 {
    var total int64
    for i := 0; i < len(foos); i++ {
        total += foos[i].a
    }
    return total
}
```

> 1.  Receives a slice of Foo
> 2.  Iterates over each Foo and sums each a field

`sumFoo` receives a slice of `Foo` and increments `total` by reading each `a` field.

The second function also computes a sum. But this time, the argument is a struct containing slices:

```go
type Bar struct {
    a []int64
    b []int64
}

func sumBar(bar Bar) int64 {
    var total int64
    for i := 0; i < len(bar.a); i++ {
        total += bar.a[i]
    }
    return total
}
```

> 1.  a and b are now slices.
> 2.  Receives a single struct
> 3.  Iterates over each element of a
> 4.  Increments the total

`sumBar` receives a single `Bar` struct that contains two slices: `a` and `b`. It iterates over each element of `a` to increment `total`.

Do we expect any difference in terms of speed for these two functions? Before running a benchmark, let’s visually look at the differences in memory in figure 12.4. Both cases have the same amount of data: 16 `Foo` elements in the slice and 16 elements in the slices of `Bar`. Each black bar represents an `int64` that is read to compute the sum, whereas each gray bar represents an `int64` that is skipped.

![Figure 12.4 A struct of slices is more compact and therefore requires fewer cache lines to iterate over.](https://drek4537l1klr.cloudfront.net/harsanyi/Figures/CH12_F04_Harsanyi.png)

In the case of `sumFoo`, we receive a slice of structs containing two fields, `a` and `b`. Therefore, we have a succession of `a` and `b` in memory. Conversely, in the case of `sumBar`, we receive a struct containing two slices, `a` and `b`. Therefore, all the elements of `a` are allocated contiguously.

This difference doesn’t lead to any memory compaction optimization. But the goal of both functions is to iterate over each `a`, and doing so requires four cache lines in one case and only two cache lines in the other.

If we benchmark these two functions, `sumBar` is faster (about 20% on my machine). The main reason is a better spatial locality that makes the CPU fetch fewer cache lines from memory.

This example demonstrates how spatial locality can have a substantial impact on performance. To optimize an application, we should organize data to get the most value out of each individual cache line.

However, is using spatial locality enough to help the CPU? We are still missing one crucial characteristic: predictability.

### 12.1.4 Predictability

Predictability refers to the ability of a CPU to anticipate what the application will do to speed up its execution. Let’s see a concrete example where a lack of predictability negatively impacts application performance.

Again, let’s look at two functions that sum a list of elements. The first iterates over a linked list and sums all the values:

```go
type node struct {
    value int64
    next  *node
}

func linkedList(n *node) int64 {
    var total int64
    for n != nil {
        total += n.value
        n = n.next
    }
    return total
}
```

> 1.  Linked list data structure
> 2.  Iterates over each node
> 3.  Increments total

This function receives a linked list, iterates over it, and increments a total.

On the other side, let’s again take the `sum2` function that iterates over a slice, one element out of two:

```go
func sum2(s []int64) int64 {
    var total int64
    for i := 0; i < len(s); i+=2 {
        total += s[i]
    }
    return total
}
```

> 1.  Iterates over every two elements

Let’s assume that the linked list is allocated contiguously: for example, by a single function. On a 64-bit architecture, a word is 64 bits long. Figure 12.5 compares the two data structures that the functions receive (linked list or slice); the darker bars represent the `int64` elements we use to increment the total.

![Figure 12.5 In memory, linked lists and slices are compacted in a similar manner.](https://drek4537l1klr.cloudfront.net/harsanyi/Figures/CH12_F05_Harsanyi.png)

In both examples, we face similar compaction. Because a linked list is a succession of values and 64-bit pointer elements, we increment the sum using one element out of two. Meanwhile, the `sum2` example reads only one element out of two.

The two data structures have the same spatial locality, so we may expect a similar execution time for these two functions. But the function iterating on the slice is significantly faster (about 70% on my machine). What’s the reason?

To understand this, we have to discuss the concept of striding. Striding relates to how CPUs work through data. There are three different types of strides (see figure 12.6):

* *Unit stride*—All the values we want to access are allocated contiguously: for example, a slice of `int64` elements. This stride is predictable for a CPU and the most efficient because it requires a minimum number of cache lines to walk through the elements.
* *Constant stride*—Still predictable for the CPU: for example, a slice that iterates over every two elements. This stride requires more cache lines to walk through data, so it’s less efficient than a unit stride.
* *Non-unit stride*—A stride the CPU can’t predict: for example, a linked list or a slice of pointers. Because the CPU doesn’t know whether data is allocated contiguously, it won’t fetch any cache lines.

![Figure 12.6 The three types of strides](https://drek4537l1klr.cloudfront.net/harsanyi/Figures/CH12_F06_Harsanyi.png)

For `sum2`, we face a constant stride. However, for the linked list, we face a non-unit stride. Even though we know the data is allocated contiguously, the CPU doesn’t know that. Therefore, it can’t predict how to walk through the linked list.

Because of the different stride and similar spatial locality, iterating over a linked list is significantly slower than a slice of values. We should generally favor unit strides over constant strides because of the better spatial locality. But a non-unit stride cannot be predicted by the CPU regardless of how the data is allocated, leading to negative performance impacts.

So far, we have discussed that CPU caches are fast but significantly smaller than the main memory. Therefore, a CPU needs a strategy to fetch a memory block to a cache line. This policy is called *cache placement policy* and can significantly impact performance.

### 12.1.5 Cache placement policy

In mistake #89, “Writing inaccurate benchmarks,” we discussed an example with a matrix in which we had to compute the total sum of the first eight columns. At that point, we didn’t explain why changing the overall number of columns impacted the benchmark results. It might sound counterintuitive: because we need to read only the first eight columns, why does changing the total number of columns affect the execution time? Let’s take a look in this section.

As a reminder, the implementation is the following:

```go
func calculateSum512(s [][512]int64) int64 {
    var sum int64
    for i := 0; i < len(s); i++ {
        for j := 0; j < 8; j++ {
            sum += s[i][j]
        }
    }
    return sum
}

func calculateSum513(s [][513]int64) int64 {
    // Same implementation as calculateSum512
}
```

> 1.  Receives a matrix of 512 columns
> 2.  Receives a matrix of 513 columns

We iterate over each row, summing the first eight columns each time. When these two functions are benchmarked each time with a new matrix, we don’t observe any difference. However, if we keep reusing the same matrix, `calculateSum513` is about 50% faster on my machine. The reason lies in CPU caches and how a memory block is copied to a cache line. Let’s examine this to understand this difference.

When a CPU decides to copy a memory block and place it into the cache, it must follow a particular strategy. Assuming an L1D cache of 32 KB and a cache line of 64 bytes, if a block is placed randomly into L1D, the CPU will have to iterate over 512 cache lines in the worst case to read a variable. This kind of cache is called *fully associative*.

To improve how fast an address can be accessed from a CPU cache, designers work on different policies regarding cache placement. Let’s skip the history and discuss today’s most widely used option: *set-associative cache*, which relies on cache partitioning.

For the sake of clarity in the following figures, we will work with a reduced version of the problem:

* We will assume an L1D cache of 512 bytes (8 cache lines).
* The matrix is composed of 4 rows and 32 columns, and we will read only the first 8 columns.

Figure 12.7 shows how this matrix can be stored in memory. We will use the binary representation for the memory block addresses. Also, the gray blocks represent the first 8 `int64` elements we want to iterate over. The remaining blocks are skipped during the iteration.

![Figure 12.7 The matrix stored in memory, and an empty cache for the execution](https://drek4537l1klr.cloudfront.net/harsanyi/Figures/CH12_F07_Harsanyi.png)

Each memory block contains 64 bytes and hence 8 `int64` elements. The first memory block starts at 0x0000000000000, the second begins at 0001000000000 (512 in binary), and so on. We also show the cache that can hold 8 lines.

> NOTE
>
> We will see in mistake #94, “Not being aware of data alignment,” that a slice doesn’t necessarily start at the beginning of a block.

With the set-associative cache policy, a cache is partitioned into sets. We assume the cache is two-way set associative, meaning each set contains two lines. A memory block can belong to only one set, and the placement is determined by its memory address. To understand this, we have to dissect the memory block address into three parts:

* The *block offset* is based on the block size. Here a block size is 512 bytes, and 512 equals 2^9. Therefore, the first 9 bits of the address represent the block offset (bo).
* The *set index* indicates the set to which an address belongs. Because the cache is two-way set associative and contains 8 lines, we have 8 / 2 = 4 sets. Furthermore, 4 equals 2^2, so the next two bits represent the set index (si).
* The rest of the address consists of the tag bits (tb). In figure 12.7, we represent an address using 13 bits for simplicity. To compute tb, we use 13 – bo – si. This means the two remaining bits represent the tag bits.

Let’s say the function starts and tries to read `s[0][0]`, which belongs to address 0000000000000. Because this address isn’t present in the cache yet, the CPU calculates its set index and copies it to the corresponding cache set (figure 12.8).

![Figure 12.8 Memory address 0000000000000 is copied into set 0.](https://drek4537l1klr.cloudfront.net/harsanyi/Figures/CH12_F08_Harsanyi.png)

As discussed, 9 bits represent the block offset: it’s the minimum common prefix for each memory block address. Then, 2 bits represent the set index. With address 0000000000000, si equals 00. Hence, this memory block is copied to set 0.

When the function reads from `s[0][1]` to `s[0][7]`, the data is already in the cache. How does the CPU know about it? The CPU calculates the starting address of the memory block, computes the set index and the tag bits, and then checks whether 00 is present in set 0.

Next the function reads `s[0][8]`, and this address isn’t cached yet. So the same operation occurs to copy memory block 0100000000000 (figure 12.9).

![Figure 12.9 Memory address 0100000000000 is copied into set 0.](https://drek4537l1klr.cloudfront.net/harsanyi/Figures/CH12_F09_Harsanyi.png)

This memory has a set index equal to 00, so it also belongs to set 0. The cache line is copied to the next available line in set 0. Then, again, reading from `s[1][1]` to `s[1][7]` results in cache hits.

Now things are getting interesting. The function reads `s[2][0]`, and this address isn’t present in the cache. The same operation is performed (figure 12.10).

![Figure 12.10 Memory address 1000000000000 replaces an existing cache line in set 0.](https://drek4537l1klr.cloudfront.net/harsanyi/Figures/CH12_F10_Harsanyi.png)

The set index is again equal to 00. However, set 0 is full—what does the CPU do? Copy the memory block to another set? No. The CPU replaces one of the existing cache lines to copy memory block 1000000000000.

The cache replacement policy depends on the CPU, but it’s usually a pseudo-LRU policy (a real LRU [least recently used] would be too complex to handle). In this case, let’s say it replaces our first cache line: 0000000000000. This situation is repeated when iterating on row 3: memory address 1100000000000 also has a set index equal to 00, resulting in replacing an existing cache line.

Now, let’s say the benchmark executes the function with a slice pointing to the same matrix starting at address 0000000000000. When the function reads `s[0][0]`, the address isn’t in the cache. This block was already replaced.

Instead of using CPU caches from one execution to another, the benchmark will lead to more cache misses. This type of cache miss is called a *conflict miss*: a miss that wouldn’t occur if the cache wasn’t partitioned. All the variables we iterate belong to a memory block whose set index is 00. Therefore, we use only one cache set instead of having a distribution across the entire cache.

In this example, this stride is called a *critical stride*: it leads to accessing memory addresses with the same set index that are hence stored to the same cache set.

Let’s come back to our real-world example with the two functions `calculateSum512` and `calculateSum513`. The benchmark was executed on a 32 KB eight-way set-associative L1D cache: 64 sets total. Because a cache line is 64 bytes, the critical stride equals 64 × 64 bytes = 4 KB. Four KB of `int64` types represent 512 elements. Therefore, we reach a critical stride with a matrix of 512 columns, so we have a poor caching distribution. Meanwhile, if the matrix contains 513 columns, it doesn’t lead to a critical stride. This is why we observed such a massive difference between the two benchmarks.

In summary, we have to be aware that modern caches are partitioned. Depending on the striding, in some cases only one set is used, which may harm application performance and lead to conflict misses. This kind of stride is called a critical stride. For performance-intensive applications, we should avoid critical strides to get the most out of CPU caches.
