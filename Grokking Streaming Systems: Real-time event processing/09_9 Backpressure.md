# 9 [](/book/grokking-streaming-systems/chapter-9/)Backpressure

### In this chapter

- an introduction to backpressure
- when backpressure is triggered
- how backpressure works in local and distributed systems

“Never trust a computer you can’t throw out a window.”

—Steve Wozniak

*Be prepared for unexpected events* is a critical rule when building any distributed systems, and streaming systems are not exceptions. In this chapter, we are going to learn a widely supported failure handling mechanism in streaming systems: *backpressure*. It is very useful for protecting a streaming system from breaking down under some unusual scenarios.

## [](/book/grokking-streaming-systems/chapter-9/)Reliability is critical

In chapter 4, the[](/book/grokking-streaming-systems/chapter-9/) team built[](/book/grokking-streaming-systems/chapter-9/) a stream processing system to process transactions and detect credit card fraud. It works well, and customers are happy so far. However, the chief has a concern—a very good one.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/09_01.png)

## [](/book/grokking-streaming-systems/chapter-9/)Review the system

Before moving forward, let’s review the structure of the system to refresh our memory.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/09_02.png)

## [](/book/grokking-streaming-systems/chapter-9/)Streamlining streaming jobs

The reason streaming[](/book/grokking-streaming-systems/chapter-9/) systems are increasingly being used is the need for on-demand data, and on-demand data can be unpredictable sometimes. Components in a streaming system or a dependent external system, such as the score database in the diagram, might not be able to handle the traffic, and they also might have their own issues occasionally. Let’s look at a few potential issues that could arise in the fraud detection system.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/09_03.png)

After all, failure handling is an important topic in all distributed systems, and our fraud detection system is no different. Things can go wrong, and some safety nets are important for preventing problems from arising.

#####  Noodle on it

What if instances fall behind or crash?

## [](/book/grokking-streaming-systems/chapter-9/)New concepts: Capacity, utilization, and headroom

Familiarize yourself with[](/book/grokking-streaming-systems/chapter-9/) these[](/book/grokking-streaming-systems/chapter-9/) related[](/book/grokking-streaming-systems/chapter-9/) concepts, which[](/book/grokking-streaming-systems/chapter-9/) will[](/book/grokking-streaming-systems/chapter-9/) be[](/book/grokking-streaming-systems/chapter-9/) helpful in discussing backpressure:

-  *Capacity* is the maximum number of events an instance can handle. In the real world, capacity is not that straightforward to measure; hence, CPU and memory utilization are often used to estimate the number. Keep in mind that in a streaming system, the number of events that various instances can handle could be very different.
-  *Capacity utilization* is a ratio (in the form of a percentage) of the actual number of events being processed to the capacity. Generally speaking, higher capacity utilization means higher resource efficiency.
-  *Capacity headroom* is the opposite of capacity utilization—the ratio represents the extra events an instance can handle on top of the current traffic. In most cases, an instance with more headroom could be more resilient to unexpected data or issues, but its efficiency is lower because more resources are allocated but not fully used.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/09_04.png)

## [](/book/grokking-streaming-systems/chapter-9/)More about utilization and headroom

In real-world systems, something[](/book/grokking-streaming-systems/chapter-9/) unexpected[](/book/grokking-streaming-systems/chapter-9/) could[](/book/grokking-streaming-systems/chapter-9/) occasionally[](/book/grokking-streaming-systems/chapter-9/) happen, causing the capacity utilization to spike. For example:

-  The incoming events could suddenly spike from time to time.
-  Hardware could fail, such as a computer restarting because of a power issue, and the network performance might be poor when bandwidth is occupied by something else.

It is important to take these potential issues into consideration when building distributed systems. A resilient job should be able to handle these temporary issues by itself. In streaming systems, with enough headroom, the job should be running fine without any user intervention.

However, headroom can’t be unlimited (plus, it is not free). When utilization capacity reaches 100%, the instance becomes *busy,* and backpressure is the next front line.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/09_05.png)

-  In a streaming job, the headroom could be different from one instance to another. Generally speaking, the headroom of a component is the minimal headroom of all the instances of the component; and the headroom of a job is the minimal headroom of all the instances in the job. Ideally, the capacity utilization of all the instances in a job should be at a similar level.
-  For critical systems, like the fraud detection system, it’s a good practice to have enough headroom on every instance, so the job is more tolerant to unexpected issues.

## [](/book/grokking-streaming-systems/chapter-9/)New concept: Backpressure

When the capacity[](/book/grokking-streaming-systems/chapter-9/) utilization[](/book/grokking-streaming-systems/chapter-9/) reaches[](/book/grokking-streaming-systems/chapter-9/) 100%, things become more interesting. Let’s dive into it using the fraud detection job as an example.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/09_06.png)

When the instance becomes busy and can’t catch up with the incoming traffic, its incoming queue is going to grow and run out of memory eventually. The issue will then propagate to other components, and the whole system is going to stop working. Backpressure is the mechanism to protect the system from crashing.

*Backpressure,* by definition, is a pressure that is opposite to the data flowing direction—from downstream instances to upstream instances. It occurs when an instance cannot process events at the speed of the incoming traffic, or, in other words, when the capacity utilization reaches 100%. The goal of the *backwards* pressure is to slow down the incoming traffic when the traffic is more than the system can handle.

## [](/book/grokking-streaming-systems/chapter-9/)Measure capacity utilization

Backpressure should trigger[](/book/grokking-streaming-systems/chapter-9/) when[](/book/grokking-streaming-systems/chapter-9/) the capacity utilization reaches 100%, but capacity and capacity utilization are not very easy to measure or estimate. There are many factors that determine the limit of how many events an instance can handle, such as the resource, the hardware, and the data. CPU and memory usage is useful but not very reliable for reflecting capacity, either. We need a better way; luckily, there is one.

We have learned that a running streaming system is composed of processes and event queues connecting them. The event queues are responsible for transferring events between the instances, like the conveyor belts between workers in an assembly line. When the capacity utilization of an instance reaches 100%, the processing speed can’t catch up with the incoming traffic. As a result, the number of events in the incoming queue of the instance starts to accumulate. Therefore, the length of the incoming queue for an instance can be used to detect whether the instance has reached its capacity.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/09_07.png)

Normally, the length of the queue should go up and down within a relatively stable range. If it keeps growing, it is very likely the instance has been too busy to handle the traffic.

In the next few pages, we will discuss backpressure in more detail with our local Streamwork engine first to get some basic ideas, then we will move to more general distributed frameworks.

Note that backpressure is especially useful for the temporary issues, such as instances restarting, maintenance of the dependent systems, and sudden spikes of events from sources. The streaming system will handle them gracefully by temporarily slowing down and resuming afterwards without user intervention. Therefore, it is very important to understand what backpressure can and cannot do, so when system issues happen, you have things under control without being panicky.

## [](/book/grokking-streaming-systems/chapter-9/)Backpressure in the Streamwork engine

Let’s start from[](/book/grokking-streaming-systems/chapter-9/) our own Streamwork engine first, since it is more straightforward. As a local system, the Streamwork engine doesn’t have complicated logic for backpressure. However, the information could be helpful for us to learn backpressure in real frameworks next.

In the Streamwork engine, *blocking queues* (queues that can suspend the threads that try to append more events when the queue is full or take elements when the queue is empty) are used to connect processes. The lengths of the queues are not unlimited. There is a maximum capacity for each queue, and the capacity is the key for backpressure. When an instance can’t process events fast enough, the consuming rate of the queue in front of it would be lower than the insertion rate. The queue will start to grow and become *full* eventually. Afterward, the insertion will be blocked until an event is consumed by the downstream instance. As the result, the insertion rate will be slowed down to the same as the event processing speed of the downstream instance.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/09_08.png)

## [](/book/grokking-streaming-systems/chapter-9/)Backpressure in the Streamwork engine: Propagation

Slowing down the[](/book/grokking-streaming-systems/chapter-9/) event dispatcher isn’t the end of the story. After the event dispatcher is slowed down, the same thing will happen to the queue between it and the upstream instances. When this queue is full, all the instances of the upstream component will be affected. In the diagram below, we need to zoom in a little more than normal to see the blocking queue in front of the event dispatcher that is shared by all the upstream instances.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/09_09.png)

When there is a fan-in in front of this component, which means there are multiple direct upstream components for the downstream component, all these components will be affected because the events are blocked to the same blocking queue.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/09_10.png)

## [](/book/grokking-streaming-systems/chapter-9/)Our streaming job during a backpressure

Let’s look at how the fraud detection job is affected by backpressure with our Streamwork engine when one score aggregator instance has trouble catching up with the incoming traffic. At the beginning, only the score aggregator runs at a lower speed. Later, the upstream analyzers will be slowed down because of the backpressure. Eventually, the backpressure will bog down all your processing power, and you’ll be stuck with an underperforming job until the issue goes away.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/09_11.png)

## [](/book/grokking-streaming-systems/chapter-9/)Backpressure in distributed systems

Overall, it is[](/book/grokking-streaming-systems/chapter-9/) fairly straightforward[](/book/grokking-streaming-systems/chapter-9/) in a local[](/book/grokking-streaming-systems/chapter-9/) system[](/book/grokking-streaming-systems/chapter-9/) to detect and handle backpressure with blocking queues. However, in distributed systems, things are more complicated. Let’s discuss these potential complications in two steps:

1.  Detecting busy instances
1.  Backpressure state

Detecting busy instances

As the first step, it is important to detect busy instances, so the systems can react proactively. We mentioned in chapter 2 that the event queue is a widely used data structure in streaming systems to connect the processes. Although normally unbounded queues are used, monitoring the size of the queues is a convenient way to tell whether an instance can keep up with the incoming traffic. More specifically, there are at least two different units of length we can use to set the threshold:

-  The number of events in the queue
-  The memory size of the events in the queue

When the number of events or the memory size reaches the threshold, there is likely an issue with the connected instance. The engine declares a backpressure state.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/09_12.png)

Backpressure state

After a backpressure[](/book/grokking-streaming-systems/chapter-9/) state is[](/book/grokking-streaming-systems/chapter-9/) declared, similar to the Streamwork engine, we would want to slow down the incoming events. However, this task could often be much more complicated in distributed systems than in local systems, because the instances could be running on different computers or even different locations. Therefore, streaming frameworks typically stop the incoming events instead of slowing them down to give the busy instance room to breathe temporarily by:

-  Stopping the instances of the upstream components, or
-  Stopping the instances of the sources

Although much less popular, we would also like to cover another option later in this chapter: dropping events. This option may sound undesirable, but it could be useful when end-to-end latency is more critical and losing events is acceptable. Basically, between the two options, there is a tradeoff between accuracy and latency.

The two options are explained in the diagram below. We’ve added a source instance to help with explanations, and left out the details of some intermediate queues and event dispatchers for brevity.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/09_13.png)

Backpressure handling: Stopping the sources

Performing a stop[](/book/grokking-streaming-systems/chapter-9/) at the source component is probably the most straightforward way to relieve backpressure in distributed systems. It allows us to drain the incoming events to the slow instance as well as all other instances in a streaming job, which could be desirable when it is likely that there are multiple busy instances.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/09_14.png)

Backpressure handling: Stopping the upstream components

Stopping the incoming event could also be implemented at the component level. This would be a more fine-grained way (to some extent) than the previous implementation. The hope is that only specific components or instances are stopped instead of all of them and that the backpressure can be relieved before it is propagated widely. If the issue stays long enough, eventually the source component will still be stopped. Note that this option can be relatively more complicated to implement in distributed systems and has higher overhead[](/book/grokking-streaming-systems/chapter-9/).

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/09_15.png)

Relieving backpressure

After a job[](/book/grokking-streaming-systems/chapter-9/) is in a backpressure state for a while and the busy instance has recovered (hopefully), the next important question is: what is the end of a backpressure state, so the traffic can be resumed?

The solution shouldn’t be a surprise, as it is very similar to the detection step: monitoring the size of the queues. Opposite to the detection in which we check whether the queue is *too full*, this time we check whether the queue is *empty enough*, which means the number of events in it has decreased to be below a low threshold, and it has enough room for new events now.

Note that relieving doesn’t mean the slow instance has recovered. Instead, it simply means there is room in the queue for more events.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/09_16.png)

Here, one important fact to keep in mind is that backpressure is a *passive* mechanism designed for protecting the slow instance and the whole system from more serious problems (like crashing). It doesn’t really address any problem in the slow instance and make it run faster. As a result, backpressure could be triggered again if the slow instance still can’t catch up after the incoming events are resumed. We are going to take a closer look at the thresholds for detecting and relieving backpressure first and then discuss the problem afterward.

## [](/book/grokking-streaming-systems/chapter-9/)New concept: Backpressure watermarks

The sizes of[](/book/grokking-streaming-systems/chapter-9/) the intermediate[](/book/grokking-streaming-systems/chapter-9/) queues are examined and compared with the thresholds for the declaration and relieving of the backpressure state. Let’s take a closer look at these two thresholds together with a new concept: *backpressure watermarks*. They are typically the configurations provided by streaming frameworks:

-  Backpressure watermarks represent the high and low utilizations of the intermediate queues between the processes.
-  When the size of the data in a queue is higher than the high backpressure watermark, backpressure state should be declared if it hasn’t been already.
-  When a backpressure is present, and the size of the data in the queue that triggered backpressure is lower than the low backpressure watermark, the backpressure can be relieved. Note that it is not ideal for this low backpressure watermark to be zero because that means the previously busy instance won’t have work to do between the relieving of backpressure and new events reaching the queue.

The data sizes in the queues go up and down when a job is processing events. Ideally, the numbers are always between the low and high backpressure watermarks, so the events are processed in full speed.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/09_17.png)

## [](/book/grokking-streaming-systems/chapter-9/)Another approach to handle lagging instances: Dropping events

Backpressure is useful[](/book/grokking-streaming-systems/chapter-9/) for protecting[](/book/grokking-streaming-systems/chapter-9/) systems and keeping things running. It works well in most cases, but in some special cases you also have another option: simply dropping events.

In this approach, when a lagging instance is detected, instead of stopping and resuming the incoming events, the system would just discard the new events emitted into the incoming queue of the instance.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/09_18.png)

The option might sound scary because the results will be inaccurate. You are definitely right about that. If you remember the delivery semantics we talked about in chapter 5, you will notice that this option should only be used in the *at-most-once* cases.

However, it may not be as scary as it sounds. The results are inaccurate *only* when an instance can’t catch up with the traffic, which should be rare if the system is configured correctly. In other words, the results should be accurate *almost* all the time. We have mentioned a few times that backpressure is a self-protection mechanism for the extreme scenarios to prevent the systems from crashing. The backpressure state is not an ideal state for streaming jobs. If it happens too often to your streaming job, you should take another look at the system and try to find the root causes and address them.

## [](/book/grokking-streaming-systems/chapter-9/)Why do we want to drop events?

Why would we[](/book/grokking-streaming-systems/chapter-9/) ever want to throw away an event in a system? You are not alone if you are wondering. Well, that’s a question to definitely ask yourself when designing your jobs: are you willing to trade away accuracy for end-to-end latency in case any instance fails to catch up with the work load?

Let’s take social media platforms as an example and track the number of user interactions, such as *likes*, in real time. With the second option, the count is always the latest, although it is not 100% accurate. In the case that 1 instance in 100 is affected, we can expect the error to be less than 1%. If backpressure is applied to stop events, the count will be accurate, but you won’t get the latest count during the backpressure state, because the system is slowed down. After the backpressure state is relieved, it also needs time to catch up to the latest events. In the case that the issue is permanent, you won’t have the latest count until the issue is addressed, which could likely be worse than the < 1% error. Basically, with the dropping events approach, you get a *more real-time* system with *likely accurate enough* results.

Back to the fraud detection job—the deadline is critical to us. Pausing the data processing for a few minutes and missing the deadline until the backpressure is addressed would not be acceptable to us. Comparatively speaking, it may be more desirable to keep the process going without delay, although the accuracy is sacrificed slightly. Engineers should definitely be notified, so the underlying issue is investigated and fixed as soon as possible. Monitoring the number of dropped events is critical for us to understand the current state and the accuracy level of the results.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/09_19.png)

## [](/book/grokking-streaming-systems/chapter-9/)Backpressure could be a symptom when the underlying issue is permanent

Backpressure is an[](/book/grokking-streaming-systems/chapter-9/) important mechanism in streaming systems for handling temporary issues, such as instance crashing and sudden spikes of the incoming traffic, to avoid more serious problems. The streaming systems can resume a normal state automatically after the underlying issue is gone without user intervention. In other words, with backpressure, the stream systems are more resilient to unexpected issues, which is generally desirable in distributed systems. In theory, it would be ideal if backpressure never happened in a streaming system, but as you well know, life is not perfect, and it never will be. Backpressure is a necessary safety net.

While we hope that the issue is temporary and backpressure can handle it for us, it all depends on the underlying situation. It is totally possible that the instance won’t recover by itself and owners’ interventions will be required to take care of the root cause. In these cases, permanent backpressure becomes a symptom. Typically, there are two permanent cases that should be treated differently:

-  The instance simply stops working, and backpressure will never be relieved,
-  The instance is still working, but it can’t catch up with the incoming traffic. Backpressure will be triggered again soon after it is relieved.

Instance stops working, so backpressure won’t be relieved

In this case, no events will be consumed from the queue, and the backpressure state will never be relieved at all. This is relatively straightforward to handle: fixing the instance. Restarting the instance could be an immediate remediation step, but it could be important to figure out the root cause and address accordingly. Often, the issue leads to bugs to be fixed.

Instance can’t catch up, and backpressure will be triggered again

It is more interesting when an instance can’t catch up with the traffic. In this case, the data processing can resume temporarily after the data in the queue has been drained, but backpressure will be declared again soon. Let’s take a closer look at this case.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/09_20.png)

## [](/book/grokking-streaming-systems/chapter-9/)Stopping and resuming may lead to thrashing if the issue is permanent

Now, let’s take[](/book/grokking-streaming-systems/chapter-9/) a look[](/book/grokking-streaming-systems/chapter-9/) at an effect that we will term *thrashing*. If the underlying issue is permanent, when the job declares a state of backpressure, the events in the queues are drained by all instances; then, as soon as the backpressure state is relieved, as new data events flood the instance once again, the state is declared again shortly. Thrashing is a cycle of declaring and relieving backpressure.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/09_21.png)

Thrashing is expected if the situation doesn’t change. If the same instance still can’t catch up with the traffic, the data size in the queue will increase again until it reaches the high watermark and triggers a backpressure again. And after the next time the backpressure is relieved, it is likely to happen again. The number of events in the incoming queue of the instance looks like the chart above. To recover from a thrashing, we need to find the root cause and address it.

## [](/book/grokking-streaming-systems/chapter-9/)Handle thrashing

If you see the thrashing, you will likely need to consider why the instance doesn’t process fast enough. For example, is there an internal issue that makes the instance slow down, or is it time to scale up your system? Typically, this kind of issue comes from two sources—the traffic and the components:

-  The event traffic from the source might have increased permanently to a level that is more than the job can handle. In this case, it is likely the job needs to be scaled up to handle the new traffic. More specifically, the parallelisms (the number of instances of a specific component—read chapter 3 for more details) of the slow components in the job may need to be increased as the first step.
-  The processing speed of some components could be slower than before for some reason. You might need to look into the components and see if there is something to optimize or tune. Note that the dependencies used by the components should be taken into consideration as well. It is not rare that some dependencies can run slower when the pattern of traffic changes.

It is important to understand the data and the system

Backpressure occurs when an instance can’t process events at the speed of the incoming traffic. It is a powerful mechanism to protect the system from crashing, but it is important for you, the owner of the systems, to understand the data and the systems and figure out what causes backpressure to be triggered. Many issues might happen in real-world systems, and we can’t cover all of them in this book. Nevertheless, we hope that understanding the basic concepts will be helpful for you to start your investigation in the right direction.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/09_22.png)

## [](/book/grokking-streaming-systems/chapter-9/)Summary

In this chapter, we discussed a widely supported mechanism: backpressure. More specifically:

-  When and why backpressure happens
-  How stream frameworks detect issues and handle them with backpressure
-  Stopping incoming traffic or dropping events—how they work and the tradeoffs
-  What we can do if the underlying issues don’t go away.

Backpressure is an important mechanism in stream systems. We hope and believe that understanding the details about it could be helpful for you to maintain and improve your systems.
