# 3 [](/book/grokking-streaming-systems/chapter-3/)Parallelization and data grouping

### In this chapter

- parallelization
- data parallelism and task parallelism
- event grouping

“Nine people can’t make a baby in a month.”

—Frederick P. Brooks

In the previous chapter, AJ and Miranda tackled keeping a real-time count of traffic driving over the bridge using a streaming job. The system she built is fairly limited in processing heavy amounts of traffic. Can you imagine going through a bridge and tollbooth with only one lane during rush hour? Yikes! In this chapter, we are going to learn a basic technique to solve a fundamental challenge in most distributed systems. This challenge is scaling streaming systems to increase throughput of a job or, in other words, process more data.

## [](/book/grokking-streaming-systems/chapter-3/)The sensor is emitting more events

In the previous[](/book/grokking-streaming-systems/chapter-3/) chapter, AJ[](/book/grokking-streaming-systems/chapter-3/) tackled keeping a real-time count of traffic driving over the chief’s bridge using a streaming job. Detecting traffic with one sensor emitting traffic events was acceptable for collecting the traffic data. Naturally, the chief wants to make more money, so he opted to build more lanes on the bridge. In essence, he is asking for the streaming job to scale in the number of traffic events it can process at one time.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/03_01.png)

A typical solution in computer systems to achieve higher throughput is to spread out the calculations onto multiple processes, which is called parallelization.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/03_02.png)

Similarly, in streaming systems, the calculation can be spread out to multiple instances. You can imagine with our vehicle count example that having multiple lanes on the bridge and having more tollbooths could be very helpful for accepting and processing more traffic and reducing waiting time.

## [](/book/grokking-streaming-systems/chapter-3/)Even in streaming, real time is hard

Increasing lanes[](/book/grokking-streaming-systems/chapter-3/) caused[](/book/grokking-streaming-systems/chapter-3/) the job to fall behind

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/03_03.png)

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/03_04.png)

## [](/book/grokking-streaming-systems/chapter-3/)New concepts: Parallelism is important

Parallelization is a common technique in computer systems. The idea is that a time-consuming problem can often be broken into smaller sub-tasks that can be executed concurrently. Then, we can have more computers working on the problem cooperatively to reduce the total execution time greatly.

Why it’s important

Let’s use the[](/book/grokking-streaming-systems/chapter-3/) streaming job in the previous chapter as an example. If there are 100 vehicle events waiting in a queue to be processed, the single vehicle counter would have to process all of them one by one. In the real world, there could be millions of events every second for a streaming system to process. Processing these events one by one is not acceptable in many cases, and parallelization is critical for solving large-scale problems.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/03_05.png)

## [](/book/grokking-streaming-systems/chapter-3/)New concepts: Data parallelism

It is not fast[](/book/grokking-streaming-systems/chapter-3/) enough[](/book/grokking-streaming-systems/chapter-3/) to solve[](/book/grokking-streaming-systems/chapter-3/) the counting problem with one computer. Luckily, the chief has multiple computers on hand—because what tollbooth IT operation center doesn’t? It is a reasonable idea to assign each vehicle event to a different computer, so all the computers can work on the calculation in parallel. This way you would process all vehicles in one step instead of processing them one by one in 100 steps. In other words, the throughput is 100 times greater. When there is more data to process, more computers instead of one *bigger* computer can be used to solve the problem faster. This is called horizontal scaling.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/03_06.png)

##### A quick note

It should be noted that modern day CPUs have internal instruction pipelines to improve processing performance dramatically. For this case (and the rest of the book), we will keep the calculations simple and ignore this type of optimization whenever we refer to parallelization.

## [](/book/grokking-streaming-systems/chapter-3/)New concepts: Data execution independence

Say the phrase[](/book/grokking-streaming-systems/chapter-3/) *data execution independence* out[](/book/grokking-streaming-systems/chapter-3/) loud, and think about what it could mean. This is quite a fancy term, but it isn’t as complex as you think.

Data execution independence, in regards to streaming, means the end result is the same no matter the order of the calculations or executions being performed across data elements. For example, in the case of multiplying each element in the queue by 4, they will have the same result whether they are done at the same time or one after another. This independence would allow for the use of data parallelism.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/03_07.png)

## [](/book/grokking-streaming-systems/chapter-3/)New concepts: Task parallelism

Data parallelism[](/book/grokking-streaming-systems/chapter-3/) is critical for many big data systems as well as general distributed systems because it allows developers to solve problems more efficiently with more computers. In addition to data parallelism, there is another type of parallelization: *task parallelism*, also known as function parallelism. In contrast to data parallelism, which involves running the same task on different data, task parallelism focuses on running different tasks on the same data.

A good way to think of task parallelism is to look at the streaming job you studied in chapter 2. The sensor reader and vehicle counter components keep running to process incoming events. When the vehicle counter component is processing (counting) an event, the sensor reader component is taking a different, new event at the same time. In other words, the two different tasks work concurrently. This means an event is emitted from the sensor reader, then it is processed by the vehicle counter component.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/03_08.png)

## [](/book/grokking-streaming-systems/chapter-3/)Data parallelism vs. task parallelism

Let’s recap:

-  Data parallelism represents[](/book/grokking-streaming-systems/chapter-3/) that the[](/book/grokking-streaming-systems/chapter-3/) same[](/book/grokking-streaming-systems/chapter-3/) task[](/book/grokking-streaming-systems/chapter-3/) is executed on different[](/book/grokking-streaming-systems/chapter-3/) event sets at the same time.
-  Task parallelism represents that different tasks are executed at the same time.

Data parallelism is widely used in distributed systems to achieve horizontal scaling. In these systems, it would be relatively easy to increase parallelization by adding more computers. Conversely, with task parallelism, it normally requires manual intervention to break the existing processes into multiple steps to increase parallelization.

Streaming systems are combinations of data parallelism and task parallelism. In a streaming system, data parallelism refers to creating multiple instances of each component, and task parallelism refers to breaking the whole process into different components to solve the problem. In the previous chapter, we have applied the task parallelism technique and broken the whole system into two components. In this chapter, we are going to learn how to apply the data parallelism technique and create multiple instances of each component.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/03_09.png)

In most cases, if you see the term *parallelization* or *parallelism* without the *data* or *task* in streaming systems, it typically refers to data parallelism. This is the convention we are going to apply in this book. Remember that both parallelisms are critical techniques in data processing systems.

## [](/book/grokking-streaming-systems/chapter-3/)Parallelism and concurrency

Is there a difference?

This paragraph could[](/book/grokking-streaming-systems/chapter-3/) easily[](/book/grokking-streaming-systems/chapter-3/) start a contentious tech uproar, potentially as easily as writing a paragraph to justify the use of tabs over spaces. During the planning sessions of this book, these concepts came up several times. Typically, these conversations would always end up with us asking ourselves which term to use.

*Parallelization* is the term we’ve decided to use when explaining how to modify your streaming jobs for performance and scale. More explicitly in the context of this book, parallelism refers to the number of instances of a specific component. Or you could say parallelism is the number of instances running to complete the same task. *Concurrency*, on the other hand, is a general word that refers to two or more things happening at the same time.

It should be noted that we are using threads in our streaming framework to execute different tasks, but in real-world streaming jobs you would typically be running multiple physical machines somewhere to support your job. In this case you could call it parallel computing. Some readers may question whether parallelization is the accurate word when we are only referring to code that is running on a single machine. This is yet another question we asked ourselves. Is this correct for us to write about? We have decided not to cover this question. After all, the goal of this book is that, by the end, you can comfortably talk about topics in streaming. Overall, just know that parallelization is a huge component of streaming systems, and it is important for you to get comfortable talking about the concepts and understanding the differences well.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/03_10.png)

## [](/book/grokking-streaming-systems/chapter-3/)Parallelizing the job

This is a good[](/book/grokking-streaming-systems/chapter-3/) time[](/book/grokking-streaming-systems/chapter-3/) to review the state of the last streaming job we studied. You should have a traffic event job that contains two components: a sensor reader and a vehicle counter. As a refresher, the job can be visualized as the below image.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/03_11.png)

This implementation has worked for the previous chapter. However, we will now introduce a new component we decided to call the event dispatcher. It will allow us to route data to different instances of a parallelized component. With the `eventDispatcher` the chapter 2 job structure will look like the following. The image below is an end result of reading through this chapter and working through the steps to build up the job. By the end of this chapter, you will have added two instances of each component and understand how the system will decide to send data to each instance.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/03_12.png)

## [](/book/grokking-streaming-systems/chapter-3/)Parallelizing components

The following image[](/book/grokking-streaming-systems/chapter-3/) shows[](/book/grokking-streaming-systems/chapter-3/) the end goal of how we want to parallelize the components in the streaming job. The event dispatcher will help us distribute the load across downstream instances.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/03_13.png)

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/03_14.png)

## [](/book/grokking-streaming-systems/chapter-3/)Parallelizing sources

First, we are[](/book/grokking-streaming-systems/chapter-3/) only[](/book/grokking-streaming-systems/chapter-3/) going to parallelize the data sources in the streaming job from one to two. To simulate a parallelized source, this new job will need to listen on two different ports to accept your input. The ports we will use are 9990 and 9991. We have updated the engine to support parallelism, and the change in the job code is very straightforward:

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/03_15.png)

```
Stream bridgeStream = job.addSource(
  new SensorReader("sensor-reader", 2, 9990)
);
```

To run the job, you need to first create two input terminals and execute the command with different ports:

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/03_16.png)

Then, you can compile and execute the sample code in a separate *job* terminal:

```bash
$ mvn package
$ java -cp target/gss.jar \
 com.streamwork.ch03.job.ParallelizedVehicleCountJob1
```

At this point you should have three terminals open to run your job: input terminal 1, input terminal 2, and the job terminal. Input terminals 1 and 2 are where you will be typing vehicle events to be picked up by the streaming job. The next page will show some sample output.

##### Networking FYI

Due to limitations of networking, we cannot have more than one process, thread, or compute instance listening on the same port. Since we have two of the same sources running on the same machine for our learning purposes, we have to run the extra instance of source on a different port.

## [](/book/grokking-streaming-systems/chapter-3/)Viewing job output

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/03_17.png)

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/03_18.png)

## [](/book/grokking-streaming-systems/chapter-3/)Parallelizing operators

Running the new job

Now, let’s parallelize[](/book/grokking-streaming-systems/chapter-3/) the `VehicleCounter` operator:

```
bridgeStream.applyOperator(
  new VehicleCounter("vehicle-counter", 2));
```

Keep in mind[](/book/grokking-streaming-systems/chapter-3/) we are[](/book/grokking-streaming-systems/chapter-3/) using two parallelized sources, so we will need to execute the same `netcat` command as we did before in two separate terminals. For a refresher, each command tells Netcat to listen for connections on the ports specified in each command.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/03_19.png)

Then, you can compile and execute the sample code in a third, separate *job* terminal:

```bash
$ mvn package
$ java -cp gss.jar \
 com.streamwork.ch03.job.ParallelizedVehicleCountJob2
```

This job that runs will have two sources and operators. It can be represented by the diagram below. The job output follows.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/03_20.png)

## [](/book/grokking-streaming-systems/chapter-3/)Viewing job output

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/03_21.png)

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/03_22.png)

## [](/book/grokking-streaming-systems/chapter-3/)Events and instances

```
VehicleCounter :: instance 0 --> #1
  car: 1
  
… (Omitted for brevity)


VehicleCounter:: instance 1 -->  #2
  car: 1
  truck: 1

<span class="fm-combinumeral1">#1</span> A car is processed by VehicleCounter 0.
<span class="fm-combinumeral1">#2</span> Another car is processed by VehicleCounter 1.
```

If you take[](/book/grokking-streaming-systems/chapter-3/) a close[](/book/grokking-streaming-systems/chapter-3/) look[](/book/grokking-streaming-systems/chapter-3/) at the results of the vehicle counter instances, you will see that both of them receive a different car event. Depending on how the system is set to run this type of behavior, it may not be desirable for a streaming job. We will study the new concept of event grouping later to understand the behavior and how to improve the system. For now, just understand that any vehicle can be processed by either of the two tollbooth instances.

Another important concept you need to understand here is event ordering. Events have their order in a stream—after all, they all reside in queues, typically. How do you know if one event will be processed before another? Generally, two rules apply:

-  Within an instance, the processing order is *guaranteed* to be the same as the original order (the order in the incoming queue).
-  Across instances, there is *no guarantee* about the processing order. It is possible that a later event can be processed and/or finished earlier than another event that arrived earlier, if the two events are processed by different instances.

A more concrete example follows.

## [](/book/grokking-streaming-systems/chapter-3/)Event ordering

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/03_23.png)

Let’s look at[](/book/grokking-streaming-systems/chapter-3/) the four vehicle events that were entered in the input terminals. The first and third vehicles are `car` and `van`, and they are sent to `VehicleCounter` instance 0, while the second and the fourth events `truck` and `car` are routed to `VehicleCounter` instance 1.

In the Streamwork engine, the two operator instances are executed independently. Streaming engines normally guarantee that the first and the third vehicles are processed in their incoming order because they are processed in the same instance. However, there is no guarantee that the first vehicle `car` is processed before the second vehicle `truck`, or the second vehicle `truck` is processed before the third vehicle `van` because the two operator processes are independent of each other.

## [](/book/grokking-streaming-systems/chapter-3/)Event grouping

Up until now[](/book/grokking-streaming-systems/chapter-3/) your[](/book/grokking-streaming-systems/chapter-3/) parallelized[](/book/grokking-streaming-systems/chapter-3/) streaming[](/book/grokking-streaming-systems/chapter-3/) job[](/book/grokking-streaming-systems/chapter-3/) had vehicle counter instances that were getting events *randomly* (really, pseudorandomly) routed to the vehicle counter instances.

```
SensorReader:: instance 0 -->
  car                               #1
VehicleCounter :: instance 0 -->    #2
  car: 1
… (Omitted for brevity)
SensorReader:: instance 1 -->
  car                               #1
VehicleCounter:: instance 1 -->     #3
  car: 1
  van: 1
<span class="fm-combinumeral1">#1</span> The streaming job has no predictable behavior of how it will route data to either <code class="codechar">VehicleCounter 0</code> or <code class="codechar">VehicleCounter 1</code>.
<span class="fm-combinumeral1">#2</span> A car is processed by <code class="codechar">VehicleCounter 0</code>.
<span class="fm-combinumeral1">#3</span> Another car is processed by <code class="codechar">VehicleCounter 1</code>.
```

This pseudorandom routing is acceptable in many cases, but sometimes you may prefer to predictably route events to a specific downstream instance. This concept of directing events to instances is called event grouping. *Grouping* may not sound very intuitive, so let us try to explain a bit: all the events are divided into different groups, and each group is assigned a specific instance to process. There are several event grouping strategies. The two most commonly used are:

-  Shuffle grouping—Events are pseudorandomly distributed to downstream components,
-  Fields grouping—Events are predictably routed to the same downstream instances based on values in specified fields in the event.

Normally, event grouping is a functionality baked into streaming frameworks for reuse by developers. Flip through the next few pages to go a little deeper into how these two different grouping strategies work.

## [](/book/grokking-streaming-systems/chapter-3/)Shuffle grouping

*Shuffle grouping* defined[](/book/grokking-streaming-systems/chapter-3/) in few[](/book/grokking-streaming-systems/chapter-3/) words is the random distribution of data elements from a component to a downstream operator. It allows for a relatively even distribution of load to downstream operators.

Round robin is the way to perform a shuffle grouping in many frameworks. In this grouping strategy, downstream instances (aka the incoming queues) are picked in equal portions and in circular order. Compared to a shuffle grouping based on random numbers, the distribution can be more even, and the calculation can be more efficient. The implementation is similar to the diagram below. Note that in the diagram the two `truck` vehicles are counted by two different `VehicleCounter` instances.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/03_24.png)

## [](/book/grokking-streaming-systems/chapter-3/)Shuffle grouping: Under the hood

To make sure that events are routed evenly across instances, most streaming systems use the round robin method for choosing the next destination for their event[](/book/grokking-streaming-systems/chapter-3/).

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/03_25.png)

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/03_26.png)

## [](/book/grokking-streaming-systems/chapter-3/)Fields grouping

Shuffle grouping works well[](/book/grokking-streaming-systems/chapter-3/) for[](/book/grokking-streaming-systems/chapter-3/) many use cases. However, if you needed a way to predictably send elements, shuffle grouping won’t work. Fields grouping is a good candidate to assist with a predictable routing pattern for your data processing needs. It works by making a decision on where to route data based on fields out of the streamed event element (usually designated by the developer). Field grouping is also called group by or group by key in many scenarios.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/03_27.png)

In this chapter’s streaming job, we take each vehicle that comes in from the bridge and send them to either vehicle counter 0 or vehicle counter 1 based on the vehicle type, so the same type of vehicle is always routed to the same vehicle counter instance. By doing this, we keep the count of individual vehicle types by instance (and more accurately).

## [](/book/grokking-streaming-systems/chapter-3/)Fields grouping: Under the hood

To make sure[](/book/grokking-streaming-systems/chapter-3/) the same vehicle events are always assigned to the same group (routed to the same instance), typically a technique called hashing is used. Hashing is a widely used type of calculation that takes a large range of values (such as strings) and maps them onto a smaller set of values (such as integer numbers).

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/03_28.png)

The most important property of hashing is that for the same input, the result is always the same. After we get the hashing result (usually some large integer, such as 98216, called the *key*), we perform this calculation:

```
key % parallelism #1

<span class="fm-combinumeral1">#1</span> Divides the key by the parallelism and returns the remainder to decide which instance of the downstream operator the event will be assigned to. In the case that there are two instances, the event whose key is 98216 will be routed to the incoming queue of instance 0 because 98216 % 2 equals 0.
```

## [](/book/grokking-streaming-systems/chapter-3/)Event grouping execution

The event dispatcher[](/book/grokking-streaming-systems/chapter-3/) is a piece of the streaming system that sits between component executors and executes the event grouping process. It continuously pulls events from its designated incoming queue and places them on its designated outgoing queues based on the key returned from the grouping strategy. Keep in mind that all streaming systems have their own way of doing things. This overview is specific to the Streamwork framework we provided for you.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/03_29.png)

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/03_30.png)

## [](/book/grokking-streaming-systems/chapter-3/)Look inside the engine: Event dispatcher

The event dispatcher[](/book/grokking-streaming-systems/chapter-3/) is responsible for accepting events from the upstream component executor, applying the grouping strategy, and emitting the events to the downstream component.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/03_31.png)

## [](/book/grokking-streaming-systems/chapter-3/)Applying fields grouping in your job

By applying fields[](/book/grokking-streaming-systems/chapter-3/) grouping[](/book/grokking-streaming-systems/chapter-3/) to your[](/book/grokking-streaming-systems/chapter-3/) job, it[](/book/grokking-streaming-systems/chapter-3/) will be much easier to keep an aggregated count of different vehicle types, as each vehicle type will always be routed to the same instance. With the Streamwork API, it is easy to enable fields grouping:

```
bridgeStream.applyOperator(
  new VehicleCounter("vehicle-counter", 2, new FieldsGrouping()) #1
);
<span class="fm-combinumeral1">#1</span> Apply fields grouping.
```

The only thing you need to do is to add an extra parameter when you call the `applyOperator()` function, and the Streamwork engine will handle the rest for you. Remember that streaming frameworks help you focus on your business logic without worrying about how the engines are implemented. Different engines might have different ways to apply fields grouping. Typically, you may find the function with the name of `groupBy()` or `{operation}ByKey()` in different engines.

To run the example code, it is the same as before. First, you need to have two input terminals with the following commands running, so you can type in vehicle types.

Then, you can compile

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/03_32.png)

and execute the sample code in a third, separate *job* terminal:

```bash
$ mvn package
$ java -cp target/gss.jar \
 com.streamwork.ch03.job.ParallelizedVehicleCountJob3
```

## [](/book/grokking-streaming-systems/chapter-3/)Event ordering

If you run[](/book/grokking-streaming-systems/chapter-3/) the above commands, the job terminal will print an output similar to the following.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/03_33.png)

## [](/book/grokking-streaming-systems/chapter-3/)Comparing grouping behaviors

Let’s put the[](/book/grokking-streaming-systems/chapter-3/) shuffle and grouping job outputs side by side and view the differences in behavior with the same job input. It doesn’t really matter which terminal the input is from, so we combine them into one. See if you can identify the differences in how each job output differs.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/03_34.png)

## [](/book/grokking-streaming-systems/chapter-3/)Summary

In this chapter, we’ve[](/book/grokking-streaming-systems/chapter-3/) read about[](/book/grokking-streaming-systems/chapter-3/) the fundamentals of scaling streaming jobs. Scalability is one of the major challenges for all distributed systems, and parallelization is a fundamental technique for scaling them up. We’ve learned how to parallelize components in a streaming job and about the related concepts of data and task parallelisms. In streaming systems, if the term *parallelism* is used without *data* and *task*, it normally refers to data parallelism.

When parallelizing components, we also need to know how to control or predict the routing of events with event grouping strategies to get the expected results. We can achieve this predictability via shuffle grouping or fields grouping. In addition, we also looked into the Streamwork streaming engine to see how parallelization and event grouping are handled from a conceptual point of view to prepare for the next chapters and real-world streaming systems.

Parallelism and event grouping are critical because they are useful for solving a critical challenge in all distributed systems: throughput. If a bottleneck component can be identified in a streaming system, you can scale it horizontally by increasing its parallelism, and the system is capable of processing events at a faster speed.

## [](/book/grokking-streaming-systems/chapter-3/)Exercises

1.  Why is parallelization important?
1.  Can you think of any other grouping strategy? If you can think of one, can you implement it in Streamwork?
1.  The field grouping in the example is using the hash of the string. Can you implement a different field grouping that uses the first character instead? What are the advantages and disadvantages of this new grouping strategy?
