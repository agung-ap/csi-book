# 2 [](/book/grokking-streaming-systems/chapter-2/)Hello, streaming systems!

### In this chapter

- learning what events are in streaming systems
- understanding the different streaming components
- assembling a job from streaming components
- running your code

“First, solve the problem. Then, write the code.”

—John Johnson

## [](/book/grokking-streaming-systems/chapter-2/)The chief needs a fancy tollbooth

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/02_01.png)

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/02_02.png)

## [](/book/grokking-streaming-systems/chapter-2/)It started as HTTP requests, and it failed

As technology has quickly advanced over the years, most of the manual parts of tollbooths have been replaced with IoT (Internet of Things) devices. When a vehicle enters the bridge, the system is notified of the vehicle type by the IoT sensor. The first version of the system is to count the total number of vehicles by type (cars, vans, trucks, and so on) that have crossed the bridge. The chief would like the result to be updated in real time, so every time a new vehicle passes, the corresponding count should be updated immediately[](/book/grokking-streaming-systems/chapter-2/).

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/02_03.png)

AJ, Miranda, and Sid, as usual, started out with the tried and true backend service design that used HTTP requests to transfer data. But it failed.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/02_04.png)

Traffic increased for the holidays. The system took on a load that it couldn’t handle. The latency of the requests caused the system to fall behind, leading to inaccurate up-to-date results for the chief and a headache for AJ and Miranda.

## [](/book/grokking-streaming-systems/chapter-2/)AJ and Miranda take time to reflect

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/02_05.png)

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/02_06.png)

## [](/book/grokking-streaming-systems/chapter-2/)AJ ponders about streaming systems

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/02_07.png)

Without getting too far into the details of networking and packet exchanges, there is a difference in how streaming systems communicate over systems that use the http backend service architecture. The main difference in the backend service design is that a client will send a request, wait for the service to do some calculations, then get a response. In streaming systems, a client will send a request and not wait for the request to be processed before sending another. Without the need to wait for data to be processed, systems can react much more quickly.

Still a little[](/book/grokking-streaming-systems/chapter-2/) unclear? We will get you more details step by step as we continue in this chapter.

## [](/book/grokking-streaming-systems/chapter-2/)Comparing backend service and streaming

Backend service: A synchronous model

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/02_08.png)

Streaming: An asynchronous model

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/02_09.png)

## [](/book/grokking-streaming-systems/chapter-2/)How a streaming system could fit

At a high level[](/book/grokking-streaming-systems/chapter-2/), AJ gets[](/book/grokking-streaming-systems/chapter-2/) rid of the request/response model and decouples the process into two steps. The diagram below shows how a streaming system would fit in the scenario of counting vehicles that cross the bridge. We will cover the details in the rest of the chapter.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/02_10.png)

## [](/book/grokking-streaming-systems/chapter-2/)Queues: A foundational concept

Before moving forward[](/book/grokking-streaming-systems/chapter-2/), let’s take[](/book/grokking-streaming-systems/chapter-2/) a particular[](/book/grokking-streaming-systems/chapter-2/) look at[](/book/grokking-streaming-systems/chapter-2/) a data structure: a *queue*. It is heavily used in all streaming systems.

Traditional distributed systems typically communicate via the *request/response* model—also known as the synchronous model. With streaming systems this is not the case, as the request/response model introduces unneeded latency when working with *real-time* data (technically speaking, *near real-time* could be more accurate, but streaming systems are often considered to be *real-time* systems). At a high level, distributed streaming systems keep a long running connection to components across the system to reduce data transfer time. This long running connection is for continually transferring data, which allows the streaming systems to react to events as they occur.

All distributed systems have some form of process running under the hood to transfer data for you. Among all the options, a queue is very useful to simplify the architecture for streaming use cases:

-  Queues can help decouple modules in a system so that each part can run at its own pace without worrying about the dependencies and synchronization.
-  Queues can help systems process events in order, since they are a FIFO (first in first out) data structure.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/02_11.png)

However, using queues to order continually transferring data is not all rainbows and sunshine. There can be many unexpected pitfalls when guaranteeing how data is processed. We will cover this topic in chapter 5.

## [](/book/grokking-streaming-systems/chapter-2/)Data transfer via queues

Take a minute[](/book/grokking-streaming-systems/chapter-2/) or two to understand the diagram below. It shows two components and the intermediate queue of events between them, as well as the queues to the upstream and the downstream components. This transferring of data from one component to the next creates the concept of a *stream,* or continuously flowing data.

##### Process and thread

In computers, a *process* is the execution of a program, and a *thread* is an execution entity within a process. The major difference between them is that multiple threads in the same process share the same memory space, while processes have their own memory spaces. Both of them can be used to execute the data operation processes in the diagram that follows. Streaming systems might choose either one (or a combination of both) according to their requirements and considerations. In this book, to avoid confusion, *process* is the chosen term (unless explicitly stated otherwise) to represent independent sequence of execution no matter which one is really in the implementation.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/02_12.png)

## [](/book/grokking-streaming-systems/chapter-2/)Our streaming framework (the start of it)

During the initial[](/book/grokking-streaming-systems/chapter-2/) planning[](/book/grokking-streaming-systems/chapter-2/) phases[](/book/grokking-streaming-systems/chapter-2/) for writing this book, several discussions took place on how to teach streaming concepts without tight coupling to a specific streaming technology for its examples. After all, it’s known that technology is advancing every day, and keeping the book up to date with ever-changing technology would have been extremely challenging. We feel that a lightweight framework, which we creatively named the *Streamwork*, will help introduce the basic concepts in streaming systems in a framework-agnostic way.

The Streamwork framework has an overly simplified engine that runs locally on your laptop. It can be used to build and run simple streaming jobs, which can hopefully be helpful for you to learn the concepts. It is limited in terms of functionality that is supported in widely used streaming frameworks, such as Apache Heron, Apache Storm, or Apache Flink, which stream data in real time across multiple physical machines, but it should be easier to understand.

One of the most interesting aspects (in our opinion) of working with computer systems is that there’s not a single *correct* way to solve all problems. In terms of functionality, streaming frameworks, including our Streamwork framework, are similar to each other, as they share the common concepts, but internally, the implementations could be very different because of considerations and tradeoffs.

##### Think about it!

It would be a lot of work to build streaming systems from scratch. Frameworks take care of the heavy lifting, so we can focus on the business logic. However, sometimes it is important to know how frameworks work internally.

## [](/book/grokking-streaming-systems/chapter-2/)The Streamwork framework overview

Generally, streaming frameworks[](/book/grokking-streaming-systems/chapter-2/) have two responsibilities:

-  Provide an application programing interface (API) for users to hook up customer logic and build the job
-  Provide an engine to execute the streaming job

We will see the API later. It should be understood that the goal of this book is not to teach you how to use the Streamwork API. The framework is used only as a framework-agnostic tool. Let’s look at the engine first. The following diagram attempts to describe at a high level all of the moving pieces in the Streamwork framework. It should be understood that there is another process that starts each of the executors, and each executor starts a data source or a component. Each executor is standalone and does not stop or start other executors.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/02_13.png)

The framework is very simple in this chapter. However, all the components mentioned are comparable to real streaming frameworks components. The Streamwork framework will evolve in later chapters when more functionality is added.

## [](/book/grokking-streaming-systems/chapter-2/)Zooming in on the Streamwork engine

We are going to zoom in to show in detail how executors apply user logic on events.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/02_14.png)

## [](/book/grokking-streaming-systems/chapter-2/)Core streaming concepts

There are five[](/book/grokking-streaming-systems/chapter-2/) key concepts[](/book/grokking-streaming-systems/chapter-2/) in most streaming[](/book/grokking-streaming-systems/chapter-2/) systems: *event*, *job*, *source*, *operator*, and *stream*. Keep[](/book/grokking-streaming-systems/chapter-2/) in mind[](/book/grokking-streaming-systems/chapter-2/) that these concepts[](/book/grokking-streaming-systems/chapter-2/) apply to[](/book/grokking-streaming-systems/chapter-2/) most[](/book/grokking-streaming-systems/chapter-2/) streaming[](/book/grokking-streaming-systems/chapter-2/) systems with[](/book/grokking-streaming-systems/chapter-2/) a one-to-one[](/book/grokking-streaming-systems/chapter-2/)[](/book/grokking-streaming-systems/chapter-2/) mapping[](/book/grokking-streaming-systems/chapter-2/).

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/02_15.png)

If we ignore the executors and only look at user-defined objects, we get a new diagram to the right, which is a cleaner (more abstract) view of the streaming system without any details. This diagram (we call it a *logical plan*) is a high-level abstraction that shows the components and structure in the system and how data can logically flow through them. From this diagram, we can see how the source object and the operator object are connected via a stream to form a streaming job. It should be known that a stream is nothing more than a continuous transfer of data from one component to another.

## [](/book/grokking-streaming-systems/chapter-2/)More details of the concepts

The diagram below[](/book/grokking-streaming-systems/chapter-2/) shows the five key concepts, *event*, *job*, *source*, *operator*, and *stream*, with more details.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/02_16.png)

We will cover how the concepts are used in a streaming system as we walk through the different parts of your first streaming job. For now, make sure the five key concepts are crystal clear.

## [](/book/grokking-streaming-systems/chapter-2/)The streaming job execution flow

With the concepts[](/book/grokking-streaming-systems/chapter-2/) we have[](/book/grokking-streaming-systems/chapter-2/) learned in the last two pages, you can now visualize this vehicle count streaming job of two components and one stream between them to look like the image on the right.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/02_17.png)

-  The sensor reader brings data in from the sensor and stores the events in a queue. It is the source.
-  The vehicle counter is responsible for counting vehicles that pass through the stream. It is an operator.
-  The continuous moving of data from the source to the operator is the stream of vehicle events.

The sensor reader is the start of the job, and the vehicle counter is the end of the job. The edge that connects the sensor reader (source) and the vehicle counter (operator) represents the stream of vehicle types (events) flowing from the sensor reader to the vehicle counter.

In this chapter, we are going to dive into the system above. It will run on your local computer with two terminals: one accepts user input (the left column), and the other one shows the outputs of the job (the right column).

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/02_18.png)

## [](/book/grokking-streaming-systems/chapter-2/)Your first streaming job

Creating a streaming[](/book/grokking-streaming-systems/chapter-2/) job using[](/book/grokking-streaming-systems/chapter-2/) the Streamwork[](/book/grokking-streaming-systems/chapter-2/) API[](/book/grokking-streaming-systems/chapter-2/) is straightforward[](/book/grokking-streaming-systems/chapter-2/) with[](/book/grokking-streaming-systems/chapter-2/) the following steps:

1.  Create an event class.
1.  Build a source.
1.  Build an operator.
1.  Connect the components.

Your first streaming job: Create your event class

An *event* is a single[](/book/grokking-streaming-systems/chapter-2/) piece of data in a stream to be processed by a job. In the Streamwork framework, the API class `Event` is responsible for storing or wrapping user data. Other streaming systems will have a similar concept.

In your job, each event represents a single vehicle type. To keep things simple for now, each vehicle type is just a string like `car` and `truck`. We will use `VehicleEvent` as the name of the event class, which is extended from the `Event` class in the API. Each `VehicleEvent` object holds vehicle information that can be retrieved via the `getData()` function.

```
public class VehicleEvent extends Event {
  private final String vehicle; #1
  
  public VehicleEvent(String vehicle) {
    this.vehicle = vehicle;     #2
  }
  
  @Override
  public String getData() {
    return vehicle;             #3
  }
}

<span class="fm-combinumeral1">#1</span> Gets vehicle data stored in the event
<span class="fm-combinumeral1">#2</span> The constructor that takes <code class="codechar">vehicle</code> as a string and stores it
<span class="fm-combinumeral1">#3</span> The internal string for vehicles
```

Your first streaming job: The data source

A *source* is the[](/book/grokking-streaming-systems/chapter-2/) component[](/book/grokking-streaming-systems/chapter-2/) that brings data from the outside world into a streaming system. The earth icon is a representation of data that would be outside of your job. In your streaming job the sensor reader accepts vehicle type data from a local port into the system.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/02_19.png)

All streaming frameworks have an API that gives you the ability to write the logic that only you care about for data sources. All data source APIs have some type of *lifecycle hook* that will be called to accept data in from the outside world. This is where your code would be executed by the framework.

##### What is a lifecyle hook?

Lifecycle hooks in software frameworks are methods that are called in some type of repeatable pattern by the framework in which they reside. Typically, these methods allow developers to customize how their application behaves during a life cycle phase of a framework they are building their application in. In the case of the Streamwork framework we have a lifecycle hook (or method) called `getEvents``()`. It is called continuously by the framework to allow you to pull data in from the outside world. Lifecyle hooks allow developers to write the logic they care about and to let the framework take care of all the heavy lifting.

Your first streaming job: The data source (continued)

In your job the[](/book/grokking-streaming-systems/chapter-2/) sensor reader will be reading events from the sensor. In this exercise you will simulate the bridge sensor by creating the events yourself and sending them to the open port on your machine that the streaming job is listening to. The vehicle types you send to the port will be picked up by the sensor reader and emitted into the streaming job to show what it’s like to process an infinite (or unbounded) stream of events.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/02_20.png)

The Java code for the `SensorReader` class looks like:

```
public class SensorReader extends Source {
  private final BufferedReader reader;
  public SensorReader(String name, int port) {
    super(name);
    reader = setupSocketReader(port);
  }
  
  @Override
  public void getEvents(List<Event> eventCollector) {       #1
    String vehicle = reader.readLine();                     #2
    eventCollector.add(new VehicleEvent(vehicle));          #3
    System.out.println("SensorReader --> " + vehicle);
  }
}

<span class="fm-combinumeral1">#1</span> The lifecycle hook of the streaming system to execute user defined logic
<span class="fm-combinumeral1">#2</span> Read one vehicle type from input.
<span class="fm-combinumeral1">#3</span> Emit the string into the collector.
```

Your first streaming job: The operator

Operators are where[](/book/grokking-streaming-systems/chapter-2/) the user processing logic will occur. They are responsible for accepting events from upstream to process and generating output events; hence, they have both input and output. All of the data processing logic in your streaming systems will typically go into the operator components.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/02_21.png)

To keep your job simple, we have only one source and one operator in it. The current implementation of the vehicle counter is to just count the vehicles and then to log the current count in the system. Another, and potentially better, way to implement the system is for the vehicle counter to emit vehicles to a new stream. Then, logging the results can be done in an additional component that would follow after the vehicle counter. It is typical to have a component that has only one responsibility in a job.

By the way, Sid is the CTO. He is kind of old-fashioned sometimes, but he is very smart and interested in all kinds of new technologies.

Your first streaming job: The operator (continued)

Inside the `VehicleCounter` component, a `<vehicle,` `count>` map is used to store vehicle type counts in memory. It is updated accordingly when a new event is received.

In this streaming job, the vehicle counter is the operator that counts vehicle events. This operator is the end of the job, and it doesn’t create any output to the downstream operators.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/02_22.png)

```
public class VehicleCounter extends Operator {
  private final Map<String, Integer> countMap =
    new HashMap<String, Integer>();
        
  public VehicleCounter(String name) {
    super(name);
  }
  
  @Override
  public void apply(Event event,List<Event> collector) {
    String vehicle = ((VehicleEvent)event).getData();
    Integer count = countMap.getOrDefault(vehicle, 0); #1
    count += 1;                                        #2
    countMap.put(vehicle, count);                      #3
    System.out.println("VehicleCounter --> ");
    printCountMap();                                   #4
  }
}

<span class="fm-combinumeral1">#1</span> Retrieve the count from the map.
<span class="fm-combinumeral1">#2</span> Increase the count.
<span class="fm-combinumeral1">#3</span> Save the count back to the map.
<span class="fm-combinumeral1">#4</span> Print the current count.
```

Your first streaming job: Assembling the job

To assemble the[](/book/grokking-streaming-systems/chapter-2/) streaming[](/book/grokking-streaming-systems/chapter-2/) job, we[](/book/grokking-streaming-systems/chapter-2/) need to[](/book/grokking-streaming-systems/chapter-2/) add both the `SensorReader` source and the `VehicleCounter` operator and connect them. There are a few hooks in the `Job` and `Stream` classes we built for you:

-  `Job.addSource()` allows you to add a data source to the job.
-  `Stream.applyOperator()` allows you to add an operator to the stream.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/02_23.png)

The following code matches the steps outlined in the previous image:

```
public static void main(String[] args) {
  Job job = new Job();                                #1
  Stream bridgeOut=job.addSource(new SensorReader()); #2
  
  bridgeOut.applyOperator(newVehicleCounter());       #3
  
  JobStarter starter = new JobStarter(job);
  starter.start();                                    #4
}

<span class="fm-combinumeral1">#1</span> Create the job object.
<span class="fm-combinumeral1">#2</span> Add the source object and get a stream.
<span class="fm-combinumeral1">#3</span> Apply the operator to the stream.
<span class="fm-combinumeral1">#4</span> Start the job.
```

## [](/book/grokking-streaming-systems/chapter-2/)Executing the job

All you need[](/book/grokking-streaming-systems/chapter-2/) to execute[](/book/grokking-streaming-systems/chapter-2/) the job[](/book/grokking-streaming-systems/chapter-2/) is[](/book/grokking-streaming-systems/chapter-2/) a[](/book/grokking-streaming-systems/chapter-2/) Mac, Linux, or[](/book/grokking-streaming-systems/chapter-2/) Windows machine with access to a *terminal* (*command prompt* on Windows). You will also need a few tools to compile and run the code: git, Java development kit (JDK) 11, Apache Maven, Netcat (or Nmap on Windows). After all the tools are installed successfully, you can pull the code down and compile it:

```bash
$ git clone https://github.com/nwangtw/GrokkingStreamingSystems.git
$ cd GrokkingStreamingSystems
$ mvn package
```

The `mvn` command above should generate the following file: `target/gss.jar.` Finally, to run the streaming job, you’ll need two terminals: one for running your job and the other for sending data for your job to ingest.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/02_24.png)

Open a new terminal (the input terminal), and run the following command. (Note that `nc` is the command on Mac and Linux; on Windows, it is `ncat`). This will start a small server at port 9990 that can be connected to from other applications. All user inputs in this terminal will be forwarded to the port.

```bash
$ nc -lk 9990
```

Then, in the original terminal (the job terminal) that you used to compile the job, run the job with the following command:

```bash
$ java -cp target/gss.jar com.streamwork.ch02.job.VehicleCountJob
```

## [](/book/grokking-streaming-systems/chapter-2/)Inspecting the job execution

After the job[](/book/grokking-streaming-systems/chapter-2/) is started, type `car` into the *input terminal,* and hit the return key, then the count will be printed in the *job terminal*.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/02_25.png)

Now if you continue typing in `truck` in the input terminal, the counts of `car` and `truck` will be printed in the job terminal.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/02_26.png)

You can keep typing in different type of vehicles (to make it more interesting, you can prepare a bunch of vehicles in a text editor first and copy/paste them into the input terminal), and the job will keep printing the running counts, as in the example below, until you shut down the job. This demonstrates that as soon as data enters the system your streaming job takes action on it without delay.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/02_27.png)

## [](/book/grokking-streaming-systems/chapter-2/)Look inside the engine

You have learned[](/book/grokking-streaming-systems/chapter-2/) how[](/book/grokking-streaming-systems/chapter-2/) the components and the job are created. You also observed how the job runs on your computer. During the job execution, you’ve hopefully noticed the events automatically move from the sensor reader object to the vehicle counter object without you needing to implement any additional logic. Fancy, right?

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/02_28.png)

Your job or components don’t run by themselves. They are driven by a streaming engine. Let’s take a look under the hood and inspect how your job is executed by the Streamwork engine. There are three moving parts (at the current state), and we are going to look into them one by one: *source executor*, *operator executor*, and *job starter*.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/02_29.png)

Look inside the engine: Source executors

In the Streamwork[](/book/grokking-streaming-systems/chapter-2/) we’ve built[](/book/grokking-streaming-systems/chapter-2/) for you, the source executor continuously runs data sources by executing over infinite loops that pull data in from the outside world to be placed on an outgoing queue within the streaming job. Even though there is a *yes* decision on *Exit*, yes will never be reached.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/02_30.png)

Look inside the engine: Operator executors

In the Streamwork, the[](/book/grokking-streaming-systems/chapter-2/) operator[](/book/grokking-streaming-systems/chapter-2/) executor[](/book/grokking-streaming-systems/chapter-2/) works in a similar way to the source executor. The only difference is that it has an incoming event queue to manage. Even though there is a *yes* decision on *Exit*, yes will never be reached.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/02_31.png)

Look inside the engine: Job starter

The `JobStarter` is responsible[](/book/grokking-streaming-systems/chapter-2/) for setting[](/book/grokking-streaming-systems/chapter-2/) up all[](/book/grokking-streaming-systems/chapter-2/) the moving parts (executors) in a job and the connections between them. Finally, it starts the executors to process data. After the executors are started, events start to flow through the components.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/02_32.png)

##### Remember!

Keep in mind that this is the architecture of a typical streaming engine, and an attempt to generalize how frameworks work at a high level. Different streaming frameworks may work in different ways.

## [](/book/grokking-streaming-systems/chapter-2/)Keep events moving

Let’s zoom[](/book/grokking-streaming-systems/chapter-2/) out[](/book/grokking-streaming-systems/chapter-2/) to look[](/book/grokking-streaming-systems/chapter-2/) at the whole[](/book/grokking-streaming-systems/chapter-2/) engine[](/book/grokking-streaming-systems/chapter-2/) and[](/book/grokking-streaming-systems/chapter-2/) its moving[](/book/grokking-streaming-systems/chapter-2/) parts, including[](/book/grokking-streaming-systems/chapter-2/) the[](/book/grokking-streaming-systems/chapter-2/) user[](/book/grokking-streaming-systems/chapter-2/)- defined components[](/book/grokking-streaming-systems/chapter-2/) of the actual job.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/02_33.png)

After our job is started, all the executors start running concurrently or, in other words, at the same time!

## [](/book/grokking-streaming-systems/chapter-2/)The life of a data element

Let’s discuss a[](/book/grokking-streaming-systems/chapter-2/) different[](/book/grokking-streaming-systems/chapter-2/) aspect of streaming systems and take a look at the life of a single event. When you input *car* and press the enter key in the input terminal, the event will travel through the streaming system, as explained in the following diagram.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/02_34.png)

## [](/book/grokking-streaming-systems/chapter-2/)Reviewing streaming concepts

Congratulations on finishing[](/book/grokking-streaming-systems/chapter-2/) your first[](/book/grokking-streaming-systems/chapter-2/) streaming[](/book/grokking-streaming-systems/chapter-2/) job! Now, let’s[](/book/grokking-streaming-systems/chapter-2/) take a[](/book/grokking-streaming-systems/chapter-2/) few minutes[](/book/grokking-streaming-systems/chapter-2/) to step[](/book/grokking-streaming-systems/chapter-2/) back[](/book/grokking-streaming-systems/chapter-2/) and review[](/book/grokking-streaming-systems/chapter-2/) the key[](/book/grokking-streaming-systems/chapter-2/) concepts[](/book/grokking-streaming-systems/chapter-2/) of streaming systems.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/02_35.png)

## [](/book/grokking-streaming-systems/chapter-2/)Summary

A streaming job[](/book/grokking-streaming-systems/chapter-2/) is a system that processes events in real time. Whenever an event happens, the job accepts it into the system and processes it. In this chapter, we have built a simple job that counts vehicles entering a bridge. The following concepts have been covered:

-  Streams and events
-  Components (sources and operators)
-  Streaming jobs

In addition, we looked into our simple streaming engine to see how your job is really executed. Although this engine is overly simplified, and it runs on your computer instead of a distributed environment, it demonstrates the moving parts inside a typical streaming engine.

## [](/book/grokking-streaming-systems/chapter-2/)Exercises

1.  What are the differences between a source and an operator?
1.  Find three examples in real life that can be simulated as streaming systems. (If you let us know, they might be used in the next edition of this book!)
1.  Download the source code and modify the `SensorReader` source to generate events automatically.
1.  Modify your `VehicleCounter` logic to calculate the collected fees in real time. You can decide how much to charge for each vehicle type.
1.  The `VehicleCounter` operator in the first job has two responsibilities: counting vehicles and printing the results, which is not ideal. Can you change the implementation and move the printing logic to a new operator?
