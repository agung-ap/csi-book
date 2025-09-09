# 8 Concurrency: Foundations

### This chapter covers
* Understanding concurrency and parallelism
* Why concurrency isn’t always faster
* The impacts of CPU-bound and I/O-bound workloads
* Using channels vs. mutexes
* Understanding the differences between data races and race conditions
* Working with Go contexts

In recent decades, CPU vendors have stopped focusing only on clock speed. Instead, modern CPUs are designed with multiple cores and hyperthreading (multiple logical cores on the same physical core). Therefore, to leverage these architectures, concurrency has become critical for software developers. Even though Go provides *simple* primitives, this doesn’t necessarily mean that writing concurrent code has become easy. This chapter discusses fundamental concepts related to concurrency; chapter 9 will then focus on practice.

## 8.1 #55: Mixing up concurrency and parallelism

Even after years of concurrent programming, developers may not clearly understand the differences between concurrency and parallelism. Before delving into Go-specific topics, it’s first essential to understand these concepts so we share a common vocabulary. This section illustrates with a real-life example: a coffee shop.

In this coffee shop, one waiter is in charge of accepting orders and preparing them using a single coffee machine. Customers give their orders and then wait for their coffee (see figure 8.1).

##### Figure 8.1 A simple coffee shop
![Figure 8.1 A simple coffee shop](https://drek4537l1klr.cloudfront.net/harsanyi/Figures/CH08_F01_Harsanyi.png)

If the waiter is having a hard time serving all the customers and the coffee shop wants to speed up the overall process, one idea might be to have a second waiter and a second coffee machine. A customer in the queue would wait for a waiter to be available (figure 8.2).

##### Figure 8.2 Duplicating everything in the coffee shop
![Figure 8.2 Duplicating everything in the coffee shop](https://drek4537l1klr.cloudfront.net/harsanyi/Figures/CH08_F02_Harsanyi.png)

In this new process, every part of the system is independent. The coffee shop should serve consumers twice as fast. This is a *parallel* implementation of a coffee shop.

If we want to scale, we can keep duplicating waiters and coffee machines over and over. However, this isn’t the only possible coffee shop design. Another approach might be to split the work done by the waiters and have one in charge of accepting orders and another one who grinds the coffee beans, which are then brewed in a single machine. Also, instead of blocking the customer queue until a customer is served, we could introduce another queue for customers waiting for their orders (think about Starbucks) (figure 8.3).

##### Figure 8.3 Splitting the role of the waiters
![Figure 8.3 Splitting the role of the waiters](https://drek4537l1klr.cloudfront.net/harsanyi/Figures/CH08_F03_Harsanyi.png)

With this new design, we don’t make things parallel. But the overall structure is affected: we split a given role into two roles, and we introduce another queue. Unlike parallelism, which is about doing the same thing multiple times at once, *concurrency* is about structure.

Assuming one thread represents the waiter accepting orders and another represents the coffee machine, we have introduced yet another thread to grind the coffee beans. Each thread is independent but has to coordinate with others. Here, the waiter thread accepting orders has to communicate which coffee beans to grind. Meanwhile, the coffee-grinding threads must communicate with the coffee machine thread.

What if we want to increase throughput by serving more customers per hour? Because grinding beans takes longer than accepting orders, a possible change could be to hire another coffee-grinding waiter (figure 8.4).

##### Figure 8.4 Hiring another waiter to grind coffee beans
![Figure 8.4 Hiring another waiter to grind coffee beans](https://drek4537l1klr.cloudfront.net/harsanyi/Figures/CH08_F04_Harsanyi.png)

Here, the structure remains the same. It is still a three-step design: accept, grind, brew coffee. Hence, there are no changes in terms of concurrency. But we are back to adding parallelism, here for one particular step: the order preparation.

Now, let’s assume that the part slowing down the whole process is the coffee machine. Using a single coffee machine introduces contentions for the coffee-grinding threads as they both wait for a coffee machine thread to be available. What could be a solution? Adding more coffee machine threads (figure 8.5).

##### Figure 8.5 Adding more coffee machines
![Figure 8.5 Adding more coffee machines](https://drek4537l1klr.cloudfront.net/harsanyi/Figures/CH08_F05_Harsanyi.png)

Instead of a single coffee machine, we have increased the level of parallelism by introducing more machines. Again, the structure hasn’t changed; it remains a three-step design. But throughput should increase because the level of contention for the coffee-grinding threads should decrease.

With this design, we can notice something important: *concurrency enables parallelism*. Indeed, concurrency provides a structure to solve a problem with parts that may be parallelized.

> Concurrency is about dealing with lots of things at once. Parallelism is about doing lots of things at once.
>
> —Rob Pike

In summary, concurrency and parallelism are different. Concurrency is about structure, and we can change a sequential implementation into a concurrent one by introducing different steps that separate concurrent threads can tackle. Meanwhile, parallelism is about execution, and we can use it at the step level by adding more parallel threads. Understanding these two concepts is fundamental to being a proficient Go developer.

The next section discusses a prevalent mistake: believing that concurrency is always the way to go. 

## 8.2 #56: Thinking concurrency is always faster

A misconception among many developers is believing that a concurrent solution is always faster than a sequential one. This couldn’t be more wrong. The overall performance of a solution depends on many factors, such as the efficiency of our structure (concurrency), which parts can be tackled in parallel, and the level of contention among the computation units. This section reminds us about some fundamental knowledge of concurrency in Go; then we will see a concrete example where a concurrent solution isn’t necessarily faster.

### 8.2.1 Go scheduling

A thread is the smallest unit of processing that an OS can perform. If a process wants to execute multiple actions simultaneously, it spins up multiple threads. These threads can be

* *Concurrent*—Two or more threads can start, run, and complete in overlapping time periods, like the waiter thread and the coffee machine thread in the previous section.
* *Parallel*—The same task can be executed multiple times at once, like multiple waiter threads.

The OS is responsible for scheduling the thread’s processes optimally so that

* All the threads can consume CPU cycles without being starved for too much time.
* The workload is distributed as evenly as possible among the different CPU cores.

> **NOTE**
>
> The word *thread* can also have a different meaning at a CPU level. Each physical core can be composed of multiple logical cores (the concept of hyperthreading), and a logical core is also called a thread. In this section, when we use the word *thread*, we mean the unit of processing, not a logical core.

A CPU core executes different threads. When it switches from one thread to another, it executes an operation called *context switching*. The active thread consuming CPU cycles was in an *executing* state and moves to a *runnable* state, meaning it’s ready to be executed pending an available core. Context switching is considered an expensive operation because the OS needs to save the current execution state of a thread before the switch (such as the current register values).

As Go developers, we can’t create threads directly, but we can create goroutines, which can be thought of as application-level threads. However, whereas an OS thread is context-switched on and off a CPU core by the OS, a goroutine is context-switched on and off an OS thread by the Go runtime. Also, compared to an OS thread, a goroutine has a smaller memory footprint: 2 KB for goroutines from Go 1.4. An OS thread depends on the OS, but, for example, on Linux/x86-32, the default size is 2 MB (see http://mng.bz/DgMw). Having a smaller size makes context switching faster.

> **NOTE**
>
> Context switching a goroutine versus a thread is about 80% to 90% faster, depending on the architecture.

Let’s now discuss how the Go scheduler works to overview how goroutines are handled. Internally, the Go scheduler uses the following terminology (see http://mng.bz/N611):

* *G*—Goroutine
* *M*—OS thread (stands for *machine*)
* *P*—CPU core (stands for *processor*)

Each OS thread (M) is assigned to a CPU core (P) by the OS scheduler. Then, each goroutine (G) runs on an M. The `GOMAXPROCS` variable defines the limit of Ms in charge of executing user-level code simultaneously. But if a thread is blocked in a system call (for example, I/O), the scheduler can spin up more Ms. As of Go 1.5, `GOMAXPROCS` is by default equal to the number of available CPU cores.

A goroutine has a simpler lifecycle than an OS thread. It can be doing one of the following:

* *Executing*—The goroutine is scheduled on an M and executing its instructions.
* *Runnable*—The goroutine is waiting to be in an executing state.
* *Waiting*—The goroutine is stopped and pending something completing, such as a system call or a synchronization operation (such as acquiring a mutex).

There’s one last stage to understand about the implementation of Go scheduling: when a goroutine is created but cannot be executed yet; for example, all the other Ms are already executing a G. In this scenario, what will the Go runtime do about it? The answer is queuing. The Go runtime handles two kinds of queues: one local queue per P and a global queue shared among all the Ps.

Figure 8.6 shows a given scheduling situation on a four-core machine with `GOMAXPROCS` equal to `4`. The parts are the logical cores (Ps), goroutines (Gs), OS threads (Ms), local queues, and global queue.

First, we can see five Ms, whereas `GOMAXPROCS` is set to `4`. But as we mentioned, if needed, the Go runtime can create more OS threads than the `GOMAXPROCS` value.

##### Figure 8.6 An example of the current state of a Go application executed on a four-core machine. Goroutines that aren’t in an executing state are either runnable (pending being executed) or waiting (pending a blocking operation).
![Figure 8.6 An example of the current state of a Go application executed on a four-core machine. Goroutines that aren’t in an executing state are either runnable (pending being executed) or waiting (pending a blocking operation).](https://drek4537l1klr.cloudfront.net/harsanyi/Figures/CH08_F06_Harsanyi.png)

P0, P1, and P3 are currently busy executing Go runtime threads. But P2 is presently idle as M3 is switched off P2, and there’s no goroutine to be executed. This isn’t a good situation because six runnable goroutines are pending being executed, some in the global queue and some in other local queues. How will the Go runtime handle this situation? Here’s the scheduling implementation in pseudocode (see http://mng.bz/lxY8):

```
runtime.schedule() {
    // Only 1/61 of the time, check the global runnable queue for a G.
    // If not found, check the local queue.
    // If not found,
    //     Try to steal from other Ps.
    //     If not, check the global runnable queue.
    //     If not found, poll network.
}
```

Every sixty-first execution, the Go scheduler will check whether goroutines from the global queue are available. If not, it will check its local queue. Meanwhile, if both the global and local queues are empty, the Go scheduler can pick up goroutines from other local queues. This principle in scheduling is called *work stealing*, and it allows an underutilized processor to actively look for another processor’s goroutines and *steal* some.

One last important thing to mention: prior to Go 1.14, the scheduler was cooperative, which meant a goroutine could be context-switched off a thread only in specific blocking cases (for example, channel send or receive, I/O, waiting to acquire a mutex). Since Go 1.14, the Go scheduler is now preemptive: when a goroutine is running for a specific amount of time (10 ms), it will be marked preemptible and can be context-switched off to be replaced by another goroutine. This allows a long-running job to be forced to share CPU time.

Now that we understand the fundamentals of scheduling in Go, let’s look at a concrete example: implementing a merge sort in a parallel manner. 

### 8.2.2 Parallel merge sort

First, let’s briefly review how the merge sort algorithm works. Then we will implement a parallel version. Note that the objective isn’t to implement the most efficient version but to support a concrete example showing why concurrency isn’t always faster.

The merge sort algorithm works by breaking a list repeatedly into two sublists until each sublist consists of a single element and then merging these sublists so that the result is a sorted list (see figure 8.7). Each split operation splits the list into two sublists, whereas the merge operation merges two sublists into a sorted list.

##### Figure 8.7 Applying the merge sort algorithm repeatedly breaks each list into two sublists. Then the algorithm uses a merge operation such that the resulting list is sorted.
![Figure 8.7 Applying the merge sort algorithm repeatedly breaks each list into two sublists. Then the algorithm uses a merge operation such that the resulting list is sorted.](https://drek4537l1klr.cloudfront.net/harsanyi/Figures/CH08_F07_Harsanyi.png)

Here is the sequential implementation of this algorithm. We don’t include all of the code as it’s not the main point of this section:

```go
func sequentialMergesort(s []int) {
    if len(s) <= 1 {
        return
    }
 
    middle := len(s) / 2
    sequentialMergesort(s[:middle])
    sequentialMergesort(s[middle:])
    merge(s, middle)
}
 
func merge(s []int, middle int) {
    // ...
}
```
> 1. First half
> 2. Second half
> 3. Merges the two halves

This algorithm has a structure that makes it open to concurrency. Indeed, as each `sequentialMergesort` operation works on an independent set of data that doesn’t need to be fully copied (here, an independent view of the underlying array using slicing), we could distribute this workload among the CPU cores by spinning up each `sequentialMergesort` operation in a different goroutine. Let’s write a first parallel implementation:

```go
func parallelMergesortV1(s []int) {
    if len(s) <= 1 {
        return
    }
 
    middle := len(s) / 2
 
    var wg sync.WaitGroup
    wg.Add(2)
 
    go func() {
        defer wg.Done()
        parallelMergesortV1(s[:middle])
    }()
 
    go func() {
        defer wg.Done()
        parallelMergesortV1(s[middle:])
    }()
 
    wg.Wait()
    merge(s, middle)
}
```
> 1. Spins up the first half of the work in a goroutine
> 2. Spins up the second half of the work in a goroutine
> 3. Merges the halves

In this version, each half of the workload is handled in a separate goroutine. The parent goroutine waits for both parts by using `sync.WaitGroup`. Hence, we call the `Wait` method before the merge operation.

> **NOTE**
>
> If you’re not yet familiar with `sync.WaitGroup`, we will look at it in more detail in mistake #71, “Misusing sync.WaitGroup.” In a nutshell, it allows us to wait for *n* operations to complete: usually goroutines, as in the previous example.

We now have a parallel version of the merge sort algorithm. Therefore, if we run a benchmark to compare this version against the sequential one, the parallel version should be faster, correct? Let’s run it on a four-core machine with 10,000 elements:

```
Benchmark_sequentialMergesort-4       2278993555 ns/op
Benchmark_parallelMergesortV1-4      17525998709 ns/op
```

Surprisingly, the parallel version is almost an order of magnitude slower. How can we explain this result? How is it possible that a parallel version that distributes a workload across four cores is slower than a sequential version running on a single machine? Let’s analyze the problem.

If we have a slice of, say, 1,024 elements, the parent goroutine will spin up two goroutines, each in charge of handling a half consisting of 512 elements. Each of these goroutines will spin up two new goroutines in charge of handling 256 elements, then 128, and so on, until we spin up a goroutine to compute a single element.

If the workload that we want to parallelize is too small, meaning we’re going to compute it too fast, the benefit of distributing a job across cores is destroyed: the time it takes to create a goroutine and have the scheduler execute it is much too high compared to directly merging a tiny number of items in the current goroutine. Although goroutines are lightweight and faster to start than threads, we can still face cases where a workload is too small.

> **NOTE**
>
> We will discuss how to recognize when an execution is poorly parallelized in mistake #98, “Not using Go diagnostics tooling.”

So what can we conclude from this result? Does it mean the merge sort algorithm cannot be parallelized? Wait, not so fast.

Let’s try another approach. Because merging a tiny number of elements within a new goroutine isn’t efficient, let’s define a threshold. This threshold will represent how many elements a half should contain in order to be handled in a parallel manner. If the number of elements in the half is fewer than this value, we will handle it sequentially. Here’s a new version:

```go
const max = 2048
 
func parallelMergesortV2(s []int) {
    if len(s) <= 1 {
        return
    }
 
    if len(s) <= max {
        sequentialMergesort(s)
    } else {
        middle := len(s) / 2
 
        var wg sync.WaitGroup
        wg.Add(2)
 
        go func() {
            defer wg.Done()
            parallelMergesortV2(s[:middle])
        }()
 
        go func() {
            defer wg.Done()
            parallelMergesortV2(s[middle:])
        }()
 
        wg.Wait()
        merge(s, middle)
    }
}
```
> 1. Defines the threshold
> 2. Calls our initial sequential version
> 3. If bigger than the threshold, keeps the parallel version

If the number of elements in the `s` slice is smaller than `max`, we call the sequential version. Otherwise, we keep calling our parallel implementation. Does this approach impact the result? Yes, it does:

```
Benchmark_sequentialMergesort-4       2278993555 ns/op
Benchmark_parallelMergesortV1-4      17525998709 ns/op
Benchmark_parallelMergesortV2-4       1313010260 ns/op
```

Our v2 parallel implementation is more than 40% faster than the sequential one, thanks to this idea of defining a threshold to indicate when parallel should be more efficient than sequential.

> **NOTE**
>
> Why did I set the threshold to 2,048? Because it was the optimal value for this specific workload on my machine. In general, such magic values should be defined carefully with benchmarks (running on an execution environment similar to production). It’s also pretty interesting to note that running the same algorithm in a programming language that doesn’t implement the concept of goroutines has an impact on the value. For example, running the same example in Java using threads means an optimal value closer to 8,192. This tends to illustrate how goroutines are more efficient than threads.

We have seen throughout this chapter the fundamental concepts of scheduling in Go: the differences between a thread and a goroutine and how the Go runtime schedules goroutines. Meanwhile, using the parallel merge sort example, we illustrated that concurrency isn’t always necessarily faster. As we have seen, spinning up goroutines to handle minimal workloads (merging only a small set of elements) demolishes the benefit we could get from parallelism.

So, where should we go from here? We must keep in mind that concurrency isn’t always faster and shouldn’t be considered the default way to go for all problems. First, it makes things more complex. Also, modern CPUs have become incredibly efficient at executing sequential code and predictable code. For example, a superscalar processor can parallelize instruction execution over a single core with high efficiency.

Does this mean we shouldn’t use concurrency? Of course not. However, it’s essential to keep these conclusions in mind. If we’re not sure that a parallel version will be faster, the right approach may be to start with a simple sequential version and build from there using profiling (mistake #98, “Not using Go diagnostics tooling”) and benchmarks (mistake #89, “Writing inaccurate benchmarks”), for example. It can be the only way to ensure that a concurrency is worth it.

The following section discusses a frequently asked question: when should we use channels or mutexes?

## 8.3 #57: Being puzzled about when to use channels or mutexes

Given a concurrency problem, it may not always be clear whether we can implement a solution using channels or mutexes. Because Go promotes sharing memory by communication, one mistake could be to always force the use of channels, regardless of the use case. However, we should see the two options as complementary. This section clarifies when we should favor one option over the other. The goal is not to discuss every possible use case (that would probably take an entire chapter) but to give general guidelines that can help us decide.

First, a brief reminder about channels in Go: channels are a communication mechanism. Internally, a channel is a pipe we can use to send and receive values and that allows us to *connect* concurrent goroutines. A channel can be either of the following:

* *Unbuffered*—The sender goroutine blocks until the receiver goroutine is ready.
* *Buffered*—The sender goroutine blocks only when the buffer is full.

Let’s get back to our initial problem. When should we use channels or mutexes? We will use the example in figure 8.8 as a backbone. Our example has three different goroutines with specific relationships:

* G1 and G2 are parallel goroutines. They may be two goroutines executing the same function that keeps receiving messages from a channel, or perhaps two goroutines executing the same HTTP handler at the same time.
* On the other hand, G1 and G3 are concurrent goroutines, as are G2 and G3. All the goroutines are part of an overall concurrent structure, but G1 and G2 perform the first step, whereas G3 does the next step.

##### Figure 8.8 Goroutines G1 and G2 are parallel, whereas G2 and G3 are concurrent.
![Figure 8.8 Goroutines G1 and G2 are parallel, whereas G2 and G3 are concurrent.](https://drek4537l1klr.cloudfront.net/harsanyi/Figures/CH08_F08_Harsanyi.png)

In general, parallel goroutines have to *synchronize*: for example, when they need to access or mutate a shared resource such as a slice. Synchronization is enforced with mutexes but not with any channel types (not with buffered channels). Hence, in general, synchronization between parallel goroutines should be achieved via mutexes.

Conversely, in general, concurrent goroutines have to *coordinate and orchestrate*. For example, if G3 needs to aggregate results from both G1 and G2, G1 and G2 need to signal to G3 that a new intermediate result is available. This coordination falls under the scope of communication—therefore, channels.

Regarding concurrent goroutines, there’s also the case where we want to transfer the ownership of a resource from one step (G1 and G2) to another (G3); for example, if G1 and G2 are enriching a shared resource and at some point, we consider this job as complete. Here, we should use channels to signal that a specific resource is ready and handle the ownership transfer.

Mutexes and channels have different semantics. Whenever we want to share a state or access a shared resource, mutexes ensure exclusive access to this resource. Conversely, channels are a mechanic for signaling with or without data (`chan` `struct{}` or not). Coordination or ownership transfer should be achieved via channels. It’s important to know whether goroutines are parallel or concurrent because, in general, we need mutexes for parallel goroutines and channels for concurrent ones.

Let’s now discuss a widespread issue regarding concurrency: race problems. 

## 8.4 #58: Not understanding race problems

Race problems can be among the hardest and most insidious bugs a programmer can face. As Go developers, we must understand crucial aspects such as data races and race conditions, their possible impacts, and how to avoid them. We will go through these topics by first discussing data races versus race conditions and then examining the Go memory model and why it matters.

### 8.4.1 Data races vs. race conditions

Let’s first focus on data races. A data race occurs when two or more goroutines simultaneously access the same memory location and at least one is writing. Here is an example where two goroutines increment a shared variable:

```go
i := 0
 
go func() {
    i++
}()
 
go func() {
    i++
}()
```
> 1. Increments i

If we run this code using the Go race detector (`-race` option), it warns us that a data race has occurred:

```
==================
WARNING: DATA RACE
Write at 0x00c00008e000 by goroutine 7:
  main.main.func2()
 
Previous write at 0x00c00008e000 by goroutine 6:
  main.main.func1()
==================
```

The final value of `i` is also unpredictable. Sometimes it can be `1`, and sometimes `2`.

What’s the issue with this code? The `i++` statement can be decomposed into three operations:

1. Read `i`.
2. Increment the value.
3. Write back to `i`.

If the first goroutine executes and completes before the second one, here’s what happens.

| **Goroutine 1** | **Goroutine 2** | **Operation** | **`i`** |
| :--- | :--- | :--- | :--- |
| | | | 0 |
| Read | | <- | 0 |
| Increment | | | 0 |
| Write back | | -> | 1 |
| | Read | <- | 1 |
| | Increment | | 1 |
| | Write back | -> | 2 |

The first goroutine reads, increments, and writes the value `1` back to `i`. Then the second goroutine performs the same set of actions but starts from `1`. Hence, the final result written to `i` is `2`.

However, there’s no guarantee that the first goroutine will either start or complete before the second one in the previous example. We can also face the case of an interleaved execution where both goroutines run concurrently and compete to access `i`. Here’s another possible scenario.

| **Goroutine 1** | **Goroutine 2** | **Operation** | **`i`** |
| :--- | :--- | :--- | :--- |
| | | | 0 |
| Read | | <- | 0 |
| | Read | <- | 0 |
| Increment | | | 0 |
| | Increment | | 0 |
| Write back | | -> | 1 |
| | Write back | -> | 1 |
