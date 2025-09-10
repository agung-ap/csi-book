# 6 [](/book/grokking-streaming-systems/chapter-6/)Streaming systems review and a glimpse ahead

### In this chapter

- a review of the concepts we’ve learned
- an introduction of more advanced concepts to be covered in the chapters in part 2

“Technology makes it possible for people to gain control over everything, except over technology.”

—John Tudor

After learning the basic concepts in streaming systems in the previous chapters, it is time to take a small break and review them in this chapter. We will also take a peek at the content in the later chapters and get ready for the new adventure.

## [](/book/grokking-streaming-systems/chapter-6/)Streaming system pieces

A *job* is an[](/book/grokking-streaming-systems/chapter-6/) application[](/book/grokking-streaming-systems/chapter-6/) that loads[](/book/grokking-streaming-systems/chapter-6/) incoming data[](/book/grokking-streaming-systems/chapter-6/) and processes[](/book/grokking-streaming-systems/chapter-6/) it. All streaming[](/book/grokking-streaming-systems/chapter-6/) jobs[](/book/grokking-streaming-systems/chapter-6/) have four different pieces: *event*, *stream*, *source*, and *operator*. Note that these concepts may or may not be named in a similar fashion in different frameworks.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/06_01.png)

## [](/book/grokking-streaming-systems/chapter-6/)Parallelization and event grouping

Processing events one[](/book/grokking-streaming-systems/chapter-6/) by one[](/book/grokking-streaming-systems/chapter-6/) is usually[](/book/grokking-streaming-systems/chapter-6/) not acceptable[](/book/grokking-streaming-systems/chapter-6/) in[](/book/grokking-streaming-systems/chapter-6/) the real world. *Parallelization* is critical for solving problems on a large scale (i.e., it can handle more load). When using parallelization, it is necessary to understand how to route events with a *grouping strategy*.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/06_02.png)

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/06_03.png)

## [](/book/grokking-streaming-systems/chapter-6/)DAGs and streaming jobs

A *DAG*, or directed[](/book/grokking-streaming-systems/chapter-6/) acyclic[](/book/grokking-streaming-systems/chapter-6/) graph, is used[](/book/grokking-streaming-systems/chapter-6/) to represent[](/book/grokking-streaming-systems/chapter-6/) the logical[](/book/grokking-streaming-systems/chapter-6/) structure of a streaming job and how data flows through it. In more complicated streaming jobs like the fraud detection system, one component can have multiple upstream components (*fan-in*) and/or downstream components (*fan-out*).

DAGs are useful for representing streaming jobs.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/06_04.png)

## [](/book/grokking-streaming-systems/chapter-6/)Delivery semantics (guarantees)

After understanding the[](/book/grokking-streaming-systems/chapter-6/) basic[](/book/grokking-streaming-systems/chapter-6/) pieces of streaming jobs, we stepped back and looked at the problems to solve again. What are the requirements? What is important for the problem? Throughput, latency, and/or accuracy?

After the requirements are clear, *delivery semantics* need to be configured accordingly. There are three delivery semantics to choose from:

-  *At-most-once*—Streaming jobs will process events with no guarantees of being successfully processed at all.
-  *At-least-once*—Streaming jobs guarantee that every event will be successfully processed at least once, but there is no guarantee how many times each event will be processed.
-  *Exactly-once*—Streaming jobs guarantee that, it *looks like* each event is processed once and only once. It is also known as *effectively-once*.

The exactly-once guarantees accurate results, but there are some costs that can’t be ignored, such as latency and complexity. It is important to understand what requirements are essential for each streaming job in order to choose the right option.

## [](/book/grokking-streaming-systems/chapter-6/)Delivery semantics used in the credit card fraud detection system

In chapter 5, a new system usage job was added into the credit card fraud detection system. It gives a real-time view of the usage of the whole system. The fraud detect job and the new job have different requirements:[](/book/grokking-streaming-systems/chapter-6/)

-  Latency is more important for the original fraud detection job.
-  Accuracy is more important for the new system usage job.

As a result, different delivery semantics are chosen for them accordingly.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/06_05.png)

## [](/book/grokking-streaming-systems/chapter-6/)Which way to go from here

The chapters up until now have covered the core concepts of streaming systems. These concepts should get you started building streaming jobs for many purposes in a framework of your choosing.

But they are definitely not all in streaming systems! As you move forward in your career and start to solve bigger, more complex problems, you are likely going to run into scenarios that will require more advanced knowledge of streaming systems. In the following chapters in part 2 of this book, a few more advanced topics will be discussed:

-  Windowed computations
-  Joining data in real time
-  Backpressure
-  Stateless and stateful computations

For the basic concepts we have studied in the previous chapters, order is important so far as each chapter built upon the previous. However, in the second part of the book each chapter is more standalone, so you can read the chapters either sequentially or in an order you prefer. To make it easier for you to choose which ones to read first, here is a glimpse ahead of what will be covered in each of the chapters.

## [](/book/grokking-streaming-systems/chapter-6/)Windowed computations

So far, we have[](/book/grokking-streaming-systems/chapter-6/) been[](/book/grokking-streaming-systems/chapter-6/) processing events one by one in our examples. However, in the fraud detection job, the analyzers rely on not only the *current* event but also on the information of when, where, and how a card was used *recently* to identify unauthorized card usages. For example, the windowed proximity analyzer identifies fraud by detecting credit cards charged in different locations in a short period of time. How can we build streaming systems to solve these types of problems?

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/06_06.png)

In streaming systems, to slice events into event sets to process, windowed computations will be needed. In chapter 7, we will study different windowing strategies in streaming systems with the windowed proximity analyzer in the fraud detection job.

In addition, windowed computation often has its limitations, and these limitations are important for this analyzer and many other real-world problems. In this chapter, we are also going to discuss a widely used technique: using key-value stores (dictionary-like database systems) to implement windowed operators.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/06_07.png)

In streaming systems, windowed operators process event sets instead of individual events.

## [](/book/grokking-streaming-systems/chapter-6/)Joining data in real time

In chapter 8, we will[](/book/grokking-streaming-systems/chapter-6/) build[](/book/grokking-streaming-systems/chapter-6/) a new[](/book/grokking-streaming-systems/chapter-6/) system to monitor the CO2 emission of all the vehicles in Silicon Valley in real time. Vehicles in the city report their models and locations every minute. These events will be *joined* with other data to generate a real-time CO2 emission map.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/06_08.png)

For people who have worked with databases before, *join* shouldn’t be a strange concept. It is used when you need to reference data across multiple tables. In streaming systems, there is a similar *join* operator with its own characteristics, and it will be discussed in chapter 8. Note that join is the type of stream fan-in we have mentioned (but skipped) in chapter 4.

## [](/book/grokking-streaming-systems/chapter-6/)Backpressure

After you have[](/book/grokking-streaming-systems/chapter-6/) a streaming[](/book/grokking-streaming-systems/chapter-6/) job running to process data, you will (hopefully not too soon) face a problem: computers are not reliable! Well, to be fair, computers are reliable mostly, but typically streaming systems might keep running for years, and many issues can come up.

The team got a request from the banks to review the fraud detection system and provide a report about the reliability of the system. More specifically, will the job stop working when there is any computer or network issue, and will the results be missing or inaccurate? It is a reasonable request, since a lot of money is involved. In fact, even without the request from the banks, it is an important question anyway, right?

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/06_09.png)

Backpressure is a common self-protection mechanism supported by most streaming frameworks. With backpressure, the processes will slow down temporarily and try to give the system a chance to recover from problems, such as temporary network issues or sudden traffic spikes overloading computers. In some cases, dropping events could be more desirable than slowing down. Backpressure is a useful tool for developers to build reliable systems. In chapter 9, we will see how streaming engines detect and handle issues with backpressure.

## [](/book/grokking-streaming-systems/chapter-6/)Stateless and stateful computations

Maintenance is important[](/book/grokking-streaming-systems/chapter-6/) for all[](/book/grokking-streaming-systems/chapter-6/) computer[](/book/grokking-streaming-systems/chapter-6/) systems. To reduce cost and improve reliability, Sid has decided to migrate the streaming jobs to new and more efficient hardwares. This will be a major maintenance task, and it is critical to proceed carefully to make sure everything works correctly.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/06_10.png)

A debt we have left behind in chapter 5, *delivery semantics,* is stateful component. We have discussed briefly what a stateful component is and how it is used in at-least-once and exactly-once delivery semantics. However, sometimes *less is more*. It is important to understand the tradeoffs to make better technical decisions when building and maintaining streaming systems.

In chapter 10, we will look into how stateful components work internally in greater detail. We will also talk about alternative options to avoid some of the costs and limitations.
