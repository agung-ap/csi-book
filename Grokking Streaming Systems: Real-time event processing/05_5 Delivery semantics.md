# 5 [](/book/grokking-streaming-systems/chapter-5/)Delivery semantics

### In this chapter

- introducing delivery semantics and their impact
- at-most-once delivery semantic
- at-least-once delivery semantic
- exactly-once delivery semanticdelivery semantics.

“There’s never enough time to do it right, but there’s always enough time to do it over.”

—Jack Bergman

Computers are pretty good at performing accurate calculations. However, when computers work together in a distributed system, like many streaming systems, accuracy becomes a little bit more (I mean, a lot more) complicated. Sometimes, we may not want 100% accuracy because other more important requirements need to be met. “Why would we want wrong answers?” you might ask. This is a great question, and it is the one that we need to ask when designing a streaming system. In this chapter, we are going to discuss an important topic related to accuracy in streaming systems: *delivery semantics*.

## [](/book/grokking-streaming-systems/chapter-5/)The latency requirement of the fraud detection system

In the previous[](/book/grokking-streaming-systems/chapter-5/) chapter, the[](/book/grokking-streaming-systems/chapter-5/) team built a credit card fraud detection system which can make a decision within 20 milliseconds for each transaction and store the result in a database. Now, let’s ask an important question when building any distributed system: what if any failure happens?

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/05_01.png)

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/05_02.png)

## [](/book/grokking-streaming-systems/chapter-5/)Revisit the fraud detection job

We are going[](/book/grokking-streaming-systems/chapter-5/) to use[](/book/grokking-streaming-systems/chapter-5/) the fraud detection system from the previous chapter as our example in this chapter to discuss the topic of delivery semantics. So let’s look at the system and the fraud detection job briefly to refresh your memory first.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/05_03.png)

The fraud detection job has multiple analyzers working in parallel to process the transactions that enter the card network. The fraud scores from these analyzers are sent to an aggregator to calculate the final results for each transaction, and the results are written to the database for the transaction presenter.

The 20-millisecond latency threshold is critical. If the decision is not made in time, the transaction presenter won’t be able to provide the answer for the transaction to the bank, which would be bad. Ideally, we would like the job to run smoothly and meet the latency requirement all the time. But, you know, stuff happens.

## [](/book/grokking-streaming-systems/chapter-5/)About accuracy

We make lots[](/book/grokking-streaming-systems/chapter-5/) of tradeoffs[](/book/grokking-streaming-systems/chapter-5/) in distributed systems. A challenge in any streaming system is to reliably process events. Streaming frameworks can help keep the job running reliably as often as possible, but you need to know what you really need. We are used to seeing accurate results with computers; hence, it is important to understand that accuracy is not absolute in streaming systems. When necessary, it might need to be sacrificed.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/05_04.png)

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/05_05.png)

Don’t panic! In the next few pages we will look at solutions with these types of results.

## [](/book/grokking-streaming-systems/chapter-5/)Partial result

A partial result[](/book/grokking-streaming-systems/chapter-5/) is a result[](/book/grokking-streaming-systems/chapter-5/)[](/book/grokking-streaming-systems/chapter-5/) of incomplete data; hence, we can’t guarantee its accuracy. The following figure is an example of partial result when the average ticket analyzer has temporary issues.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/05_06.png)

It’s common in streaming systems to make tradeoffs.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/05_07.png)

## [](/book/grokking-streaming-systems/chapter-5/)A new streaming job to monitor system usage

Now that we[](/book/grokking-streaming-systems/chapter-5/) have[](/book/grokking-streaming-systems/chapter-5/) seen the requirements of the fraud detection job, to better understand different delivery semantics, we want to introduce another job that has different requirements to compare. The fraud detection system has been a hit in the credit card processing business. With the speed of system operations, other credit card companies are becoming interested in this idea, and with interest increasing, the team decided to add another streaming job into the system to help monitor system usage. The job tracks key information, such as how many transactions have been processed.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/05_08.png)

## [](/book/grokking-streaming-systems/chapter-5/)The new system usage job

The new system[](/book/grokking-streaming-systems/chapter-5/) usage job[](/book/grokking-streaming-systems/chapter-5/) is used[](/book/grokking-streaming-systems/chapter-5/) internally to monitor the current load of the system. We can start with two critical numbers that we are interested in first:

-  How many transactions have been processed? This number is important for us to understand the trend of the overall amount of data the fraud detection job is processing.
-  How many suspicious transactions have been detected? This number could be helpful for us to understand the number of new records created in the result database.

The counting logic is in the `SystemUsageAnalyzer` operator:

```
class SystemUsageAnalyzer extends Operator {
  private int transactionCount = 0;
  private int fraudTransactionCount = 0;
  
  public void apply(Event event, EventCollector collector) {
    String id = ((TransactionEvent)event).getTransactionId();
    transactionCount++;                      #1

    Thread.sleep(20);                        #2
    
    
    boolean fraud = fraudStore.getItem(id);  #3

    if (fraud) {
      fraudTransactionCount++;               #4
    }

    collector.emit(new UsageEvent(
    transactionCount, fraudTransactionCount));
  }
}
<span class="fm-combinumeral1">#1</span> Count the transaction.
<span class="fm-combinumeral1">#2</span> Pause for 20 milliseconds for the fraud detection job to finish its process.
<span class="fm-combinumeral1">#3</span> Read the detection result of the transaction from database. This operation may fail if the database is not available, and an exception will be thrown.
<span class="fm-combinumeral1">#4</span> Count the fraud transaction if the result is true.
```

The operator looks very simple:

-  For every transaction, the value of `transactionCount` increases by one.
-  If the transaction is a detected fraud transaction, the value of `fraudTransactionCount` increases by one.

However, the `getItem`() call in the function could fail. How the job behaves when failures happen is a key difference between different *delivery semantics*.

## [](/book/grokking-streaming-systems/chapter-5/)The requirements of the new system usage job

Before worrying about[](/book/grokking-streaming-systems/chapter-5/) the failures, we[](/book/grokking-streaming-systems/chapter-5/) have a few more things to talk about. First, let’s look at the requirements of the job. As an internal tool, the latency and accuracy requirements can be quite different from the fraud detection job:

-  *Latency—*The 20-millisecond latency requirement of the fraud detection job is not necessary in the system usage job, since the results are not used by the presenter service to generate decisions for the banks. We humans can’t read the results that quickly anyway. Moreover, a small delay when something goes wrong could be totally acceptable.
-  *Accuracy—*On the other hand, accurate results could be important for us to make the right decision.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/05_09.png)

We will walk you through the most common delivery semantics to get you started in your stream-processing journey. Along the way we will discuss the different ways you can use streaming systems to guarantee how transactions will be processed and why you would want to use them.

## [](/book/grokking-streaming-systems/chapter-5/)New concepts: (The number of) times delivered and times processed

To understand what[](/book/grokking-streaming-systems/chapter-5/) delivery[](/book/grokking-streaming-systems/chapter-5/) semantics[](/book/grokking-streaming-systems/chapter-5/) really means, the[](/book/grokking-streaming-systems/chapter-5/) concepts[](/book/grokking-streaming-systems/chapter-5/) of *times processed* and *times delivered* will[](/book/grokking-streaming-systems/chapter-5/) be very helpful:

-  Times processed can refer to the number of times an event was processed by a component.
-  Times delivered can refer to the number of times the result was generated by a component.

The two numbers are the same in most cases, but not always. For example, in the flow chart of the logic in the `SystemUsageAnalyzer` operator below, it is possible that the *get detection result* step can fail if the database is having issues. When the step fails, the event is processed once (but not successfully), and no result is generated. As a result, the times processed would be 1, and the times delivered would be 0. You may also consider times delivered as times *successfully processed*.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/05_10.png)

## [](/book/grokking-streaming-systems/chapter-5/)New concept: Delivery semantics

Here comes the[](/book/grokking-streaming-systems/chapter-5/)[](/book/grokking-streaming-systems/chapter-5/) key topic[](/book/grokking-streaming-systems/chapter-5/) of this[](/book/grokking-streaming-systems/chapter-5/) chapter: *delivery semantics*, also known as *delivery guarantees* or *delivery assurances*. It is a very important concept to understand for streaming jobs before we move on to more advanced topics.

Delivery semantics concerns how streaming engines will guarantee the delivery (or successful processing) of events in your streaming jobs. There are three main buckets of delivery semantics to choose from. Let’s introduce them briefly here and look at them one by one in more detail later.

-  *At-most-once—*Streaming jobs guarantee that every event will be processed no more than one time, with no guarantees of being successfully processed at all.
-  *At-least-once—*Streaming jobs guarantee that every event will be successfully processed at least one time with no guarantees about the number of times it is processed.
-  *Exactly-once—*Streaming jobs guarantee that every event will be successfully processed once and only once (at least it looks this way). In some frameworks, it is also called *effectively-once*. If you feel that this is too good to be true because exactly-once is extremely hard to achieve in distributed systems, or the two terms seem to be controversial, you are definitely not alone. We will talk about what exactly-once really is later in its own section.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/05_11.png)

## [](/book/grokking-streaming-systems/chapter-5/)Choosing the right semantics

You may ask[](/book/grokking-streaming-systems/chapter-5/) whether it is true that exactly-once is the go-to semantic for everything. The advantage is pretty obvious: the results are guaranteed to be accurate, and the correct answer is better than an incorrect answer.

With exactly-once, the streaming engine will do everything for you and there is nothing to worry about. What are the other two options for? Why do we need to learn about them? The fact is, all of them are useful because different streaming systems have different requirements.

Here is a simple table for the tradeoffs to begin with. We will revisit the table later after more discussion.

| Delivery semantics | At-most-once | At-least-once | Exactly-once |
| --- | --- | --- | --- |
| Accuracy | <br>      <br>       No accuracy guarantee because of missing events  <br> | <br>      <br>       No accuracy guarantee because of duplicated events  <br> | <br>      <br>       (Looks like) accurate results are guaranteed  <br> |
| Latency (when errors happen) | <br>      <br>       Tolerant to failures; no delay when errors happen  <br> | <br>      <br>       Sensitive to failures; potential delay when errors happen  <br> | <br>      <br>       Sensitive to failures; potential delay when errors happen  <br> |
| Complexity | <br>      <br>       Very simple  <br> | <br>      <br>       Intermediate (depends on the implementation)  <br> | <br>      <br>       Complex  <br> |

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/05_12.png)

Let’s continue to learn how the delivery semantics are actually handled in streaming systems. Then, you should be able to understand the tradeoffs better. Note that in the real world, each framework could have its own architecture and handle delivery semantics very differently. We will try to explain in a framework agnostic manner.

## [](/book/grokking-streaming-systems/chapter-5/)At-most-once

Let’s start from[](/book/grokking-streaming-systems/chapter-5/) the simplest[](/book/grokking-streaming-systems/chapter-5/) semantic: *at-most-once*. Inside the jobs with this semantic, events are not tracked. Engines will do their best to process each event successfully, but if any error occurs along the way, the engines will forget the events and carry on processing others. The diagram below shows how events are handled in the Streamwork engine for at-most-once jobs.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/05_13.png)

Since the engines don’t track events, the whole job can run very efficiently without much overhead. And since the job will just continue running without the need of recovering from the issues, the latency and higher throughput won’t be affected by the errors. In addition, the job will also be easier to maintain because of the simplicity. On the other hand, the effect of losing events when the system is having issues is that the results could be temporarily inaccurate.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/05_14.png)

## [](/book/grokking-streaming-systems/chapter-5/)The fraud detection job

Let’s look back[](/book/grokking-streaming-systems/chapter-5/) at the[](/book/grokking-streaming-systems/chapter-5/) fraud[](/book/grokking-streaming-systems/chapter-5/) detection[](/book/grokking-streaming-systems/chapter-5/) job with the at-most-once semantic. The fraud detection job is responsible for adding up fraud scores on each transaction that enters the card network, and it must generate the results within 20 milliseconds.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/05_15.png)

The good

With the at-most-once guarantee, the system is simpler and processes transactions with lower latency. When something goes wrong in the system, such as a transaction failing to process or transport, or any instance is temporarily unavailable, the affected events will simply be dropped and the score aggregator will just process with the available data, so the critical latency requirement is met.

Low resource and maintenance costs is the other main motivation to choose the at-most-once semantic. For example, if you have a huge amount of data to process in real time with limited resources, the at-most-once semantic could be worth your consideration.

The bad

Now, it is time to talked about the catch: inaccuracy. It is definitely an important factor when choosing the at-most-once semantic. At-most-once is suitable for the cases in which temporary inaccuracy is acceptable. It is important to ask yourself this question when you consider this option: what is the impact when the results are inaccurate temporarily?

The hope

If you want the advantages of at-most-once as well as accurate results, don’t lose hope yet. Although it might be too much to expect everything at the same time, there are still a few things we can do to overcome this limitation (to some extent). We will talk about these practical techniques at the end of this chapter, but for now, let’s move on and look at the other two delivery semantics.

## [](/book/grokking-streaming-systems/chapter-5/)At-least-once

No matter how[](/book/grokking-streaming-systems/chapter-5/) convenient[](/book/grokking-streaming-systems/chapter-5/) the at-most-once semantic is, the flaw is obvious: there is no guarantee that each event will be reliably processed. This is just not acceptable in many cases. Another flaw is that, since the events have been dropped without any trace, there is not much we can do to improve the accuracy.

Next comes the next delivery semantic—at-least-once—which can be helpful for overcoming the flaws discussed previously. With at-least-once, the streaming engines will guarantee that events will be processed at least one time. A side effect of at-least-once is that events may be processed more than one time. The diagram below shows how events are handled in the Streamwork engine for at-least-once jobs.

Note that tracking events and making sure each of them is successfully processed might sound easy, but it’s not a trivial task in distributed systems. We will look into it in the next few pages.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/05_16.png)

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/05_17.png)

## [](/book/grokking-streaming-systems/chapter-5/)At-least-once with acknowledging

A typical approach[](/book/grokking-streaming-systems/chapter-5/) to support[](/book/grokking-streaming-systems/chapter-5/) the at-least-once delivery[](/book/grokking-streaming-systems/chapter-5/) semantic is that[](/book/grokking-streaming-systems/chapter-5/) each component within a streaming job acknowledges that it has successfully processed an event or experienced a failure. Streaming frameworks usually supply a tracking mechanism for you with a new process *acknowledger*. This acknowledger is responsible for tracking the *current* and *completed* processes for each event. When all processes are completed, and there is no *current* process left for an event, it will report a *success* or *fail* message back to the data source. Let’s look at our system usage job running with the at-least-once semantic below.

##### The acknowledger

Some of you may ask: why don’t we send the acknowledgment message back to the source directly? The main reason is related to the single responsibility principle. The source is responsible for bridging the streaming job with the outside world, and we would like to keep it simple.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/05_18.png)

After the source component emits an event, it will keep it in a buffer first. After it receives a *success* message from the acknowledger, it will remove the event from the buffer, since the event has been successfully processed. If the source component receives a *fail* message for the event, it will *replay* that event by emitting it into the job again.

## [](/book/grokking-streaming-systems/chapter-5/)Track events

Let’s get closer[](/book/grokking-streaming-systems/chapter-5/) and see[](/book/grokking-streaming-systems/chapter-5/) how events[](/book/grokking-streaming-systems/chapter-5/) are tracked with an example. The engine will wrap the core event in some metadata as it leaves the data source. One of these pieces of meta-data is an event id that is used for tracking the event through the job. Components would report to the acknowledger after the process is completed.

Note that the downstream components are included in acknowledgment data, so the acknowledger knows that it needs to wait for the tracking data from all the downstream components before marking the process *fully processed*.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/05_19.png)

## [](/book/grokking-streaming-systems/chapter-5/)Handle event processing failures

In another case, if[](/book/grokking-streaming-systems/chapter-5/) the event[](/book/grokking-streaming-systems/chapter-5/) fails to[](/book/grokking-streaming-systems/chapter-5/) process in any component, the acknowledger will notify the source component to resend.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/05_20.png)

## [](/book/grokking-streaming-systems/chapter-5/)Track early out events

The last case[](/book/grokking-streaming-systems/chapter-5/) we need[](/book/grokking-streaming-systems/chapter-5/) to take[](/book/grokking-streaming-systems/chapter-5/) a look at is when not all events go through all the components. Some events may finish their journey earlier. This is why the downstream component information in the acknowledgment message is important. For example, if the transaction is not valid and won’t need to be written to storage, the system usage analyzer will be the last stop of the event, and the process will be completed there.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/05_21.png)

## [](/book/grokking-streaming-systems/chapter-5/)Acknowledging code in components

If you are[](/book/grokking-streaming-systems/chapter-5/) wondering[](/book/grokking-streaming-systems/chapter-5/) how the[](/book/grokking-streaming-systems/chapter-5/) engine[](/book/grokking-streaming-systems/chapter-5/) will know how a component will pass or fail an event, that is good! Below we have snippets of code that will be implemented in the `SystemUsageAnalyzer` and the `UsageWriter` components.

```
class SystemUsageAnalyzer extends Operator {
  public void apply(Event event, EventCollector collector) {
    if (isValidEvent(event.data)) {
      if (analyze(event.data) == SUCCESSFUL) {
        collector.emit(event);                       #1
        collector.ack(event.id);    
      } else {
        //signal this event as failure
        collector.fail(event.id);                    #2
      }
    } else {
      // signal this event as successful
      collector.ack(event.id);                       #3
    }
  }
}



class UsageWriter extends Operator {
  public void apply(Event event, EventCollector collector) {
    if (database.write(event) == SUCCESSFUL) {
      //signal this event as successful
      collector.ack(event.id);                       #4
    } else {
      // signal this event as unsuccessful
      collector.fail(event.id);                      #5
    }
  }
}
<span class="fm-combinumeral1">#1</span> An acknowledgment will be sent out when an event is emitted to acknowledge the event as successful.
<span class="fm-combinumeral1">#2</span> Analyzing failed. Acknowledge this event as unsuccessful.
<span class="fm-combinumeral1">#3</span> The event should be skipped. Acknowledge this event as successful, so the source component won’t replay it.
<span class="fm-combinumeral1">#4</span> No need to emit the event out. Manually acknowledge this event as successful.
<span class="fm-combinumeral1">#5</span> The database is having issues writing. Acknowledge this event as unsuccessful.
```

## [](/book/grokking-streaming-systems/chapter-5/)New concept: Checkpointing

Acknowledging works fine[](/book/grokking-streaming-systems/chapter-5/) for[](/book/grokking-streaming-systems/chapter-5/) the at-least-once semantic, but[](/book/grokking-streaming-systems/chapter-5/) it has[](/book/grokking-streaming-systems/chapter-5/) some drawbacks.

-  The acknowledgment logic (aka code change) is needed.
-  The order of events processing could be different from the input, which could cause issues. For example, if we have three events [A, B, C] to process, and the processing job has a failure when processing event A, another copy of event A will be replayed later by the source, and eventually four events, [A (failed), B, C, A], are emitted into the job, and event A is successfully processed after B and C.

Luckily, there is another option to support the at-least-once semantic (with tradeoffs, like everything else in the distributed systems): *checkpointing*. It is an important technique in streaming systems to achieve *fault tolerance* (i.e., the system continues operating properly after the failures). Because there are many pieces involved, it is a little messy to explain checkpointing in detail in streaming systems. So let’s try a different way. Although the concept of checkpointing sounds technical, it is, in fact, very likely that you have experienced it in real life if you have ever played video games. If you haven’t played any, that’s OK. You can also think of any text editor software (or maybe you want to try a video game now).

Now, let’s play an adventure game fighting all kinds of zombies and saving the world. It is not very common that you will complete the game nonstop from the beginning to the end, unless you are like a superhero and never fail. Most of us will fail occasionally (or more than occasionally). Hopefully, you have saved your progress so you can reload the game and resume where you were instead of starting over from the very beginning. In some games, the progress might be saved automatically at critical points. Now, imagine that you live in the universe of the game. Your time should be continuous without interruption, even though in real life you have been rolled back a few (or many) times to earlier states. The operation of saving a game is very much like checkpointing.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/05_22.png)

## [](/book/grokking-streaming-systems/chapter-5/)New concept: State

If you play[](/book/grokking-streaming-systems/chapter-5/) video games, you[](/book/grokking-streaming-systems/chapter-5/) know[](/book/grokking-streaming-systems/chapter-5/) how important[](/book/grokking-streaming-systems/chapter-5/) saved data is. I can’t imagine how I can finish any game (or any work) without that functionality. A more formal definition of *checkpoint* is a piece of data, typically persisted in storage, that can be used by an instance to restore to a previous state. We will now cover another related concept: *state*.

Let’s go back to the zombie universe and see what data would be needed to restore and continue the adventure. The data could be very different from game to game, but we should be able to imagine that the following data will be needed in the saved games:

-  The current score and levels of skills
-  The equipment you have
-  The tasks that have been finished

One key property that makes the data important is that it changes along with the game-play. The data that doesn’t change when you are working hard to save the world, such as the map and the appearance of the zombies, doesn’t need to be included in the saved games.

Now, let’s go back to the definition of *state* in streaming systems: the internal data inside each instance that changes when events are processed. For example, in the system usage job, each instance of the system usage analyzer keeps track of the count of transactions it has processed. This count changes when a new transaction is processed, and it is one piece of information in the state. When the instance is restarted, the count needs to be recovered.

While the concepts of checkpointing and state are not complicated, we need to understand that checkpointing is not a trivial task in distributed systems like in streaming systems. There could be hundreds or thousands of instances working together to process events at the same time. It is the engine’s responsibility to manage the checkpointing of all the instances and make sure they are all synchronized. We will leave it here and come back to this topic later in chapter 10.

## [](/book/grokking-streaming-systems/chapter-5/)Checkpointing in the system usage job for the at-least-once semantic

Before introducing checkpointing[](/book/grokking-streaming-systems/chapter-5/) for at-least-once, we[](/book/grokking-streaming-systems/chapter-5/) need[](/book/grokking-streaming-systems/chapter-5/) to introduce a useful[](/book/grokking-streaming-systems/chapter-5/) component[](/book/grokking-streaming-systems/chapter-5/) between[](/book/grokking-streaming-systems/chapter-5/) the API gateway[](/book/grokking-streaming-systems/chapter-5/) and the system usage job: an *event log*. Note that the term is used for the purposes of this book and is not widely used, but it shouldn’t be hard to get. An event log is a queue of events in which each event is tracked with an offset (or a timestamp). The *reader* (or *consumer*) can jump to a specific offset and start loading data from there. In real life, events might be organized in multiple *partitions*, and offsets are managed independently in each partition, but let’s keep things simple here and assume there is only one offset and one transaction source instance.

With an event log in front of the transaction source component, every minute (or other interval) the source instance creates a checkpoint with the current state—the current offset it is working on. When the job is restarted, the engine will identify the right offset for the instance to jump to (a *rollback*) and start processing events from that point. Note that the events processed by the instance from the checkpointing time to the restart time will be processed again, but it is OK under the at-least-once semantic.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/05_23.png)

## [](/book/grokking-streaming-systems/chapter-5/)Checkpointing and state manipulation functions

Checkpointing is very[](/book/grokking-streaming-systems/chapter-5/) powerful. Many[](/book/grokking-streaming-systems/chapter-5/) things are happening when a job is running with checkpointing enabled. A few major points include:

-  Periodically, each source instance needs to create the checkpoint with their current states.
-  The checkpoints need be saved into a (hopefully fault-tolerant) storage system.
-  The streaming job needs to restart itself automatically when a failure is detected.
-  The job needs to identify the latest checkpoints, and each restarted source instance needs to load its checkpoint file and recover its previous state.
-  We don’t have unlimited storage, so older checkpoints need to be cleaned up to save resources.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/05_24.png)

After looking at all the points above, don’t panic! It is true that the whole checkpointing mechanism is a bit complicated, and there are many things happening to make it work. Luckily, most of these are handled by the streaming frameworks, and the stream job owners need to worry about only one thing: the state. More specifically, the two state manipulation functions:

-  Get the current state of the instance. The function will be invoked periodically.
-  Initialize the instance with a state object loaded from a checkpoint. The function will be invoked during the startup of the streaming job.

As long as the two functions above are provided, the streaming framework will do all the dirty work behind the scenes, such as packing the states in a checkpoint, saving it on disk, and using a checkpoint to initialize instances.

## [](/book/grokking-streaming-systems/chapter-5/)State handling code in the transaction source component

The following is[](/book/grokking-streaming-systems/chapter-5/) a code[](/book/grokking-streaming-systems/chapter-5/) example[](/book/grokking-streaming-systems/chapter-5/) of the[](/book/grokking-streaming-systems/chapter-5/) `TransactionSource` component[](/book/grokking-streaming-systems/chapter-5/) with the[](/book/grokking-streaming-systems/chapter-5/) Streamwork framework:

-  The base class is changed from `Source` to `StatefulSource`.
-  With this new base class, a new `getState`() function is introduced to extract the state of the instance and return to the engine.
-  Another change is that the `setupInstance`() function takes an additional `State` object to set up the instance after it is constructed, which didn’t exist for the stateless operators.

```
public abstract class Source extends Component {                 #1
  public abstract void setupInstance(int instance);
  public abstract void getEvents(EventCollector eventCollector);
}

public abstract class StatefulSource extends Component {         #1
  public abstract void setupInstance(int instance, State state); #2
  public abstract void getEvents(EventCollector eventCollector);
  public abstract State getState();                              #3
}

class TransactionSource extends StatefulSource {
  MessageQueue queue;
  int offset = 0;
  ......
  public void setupInstance(int instance, State state) {
    SourceState mstate = (SourceState)state;
    if (mstate != null) {
      offset = mstate.offset;                                    #4
      log.seek(offset);
    }
  }
  
  public void getEvents(Event event, EventCollector eventCollector) {
    Transaction transaction = log.pull();
    eventCollector.add(new TransactionEvent(transaction));
    offset++;                                                    #5
  }
  
public State getState() {
    SourceState state = new SourceState();
    State.offset = offset;
    return new state;                                            #6
  }
}
<span class="fm-combinumeral1">#1</span> <code class="codechar">Source</code> and <code class="codechar">StatefulSource</code> classes
<span class="fm-combinumeral1">#2</span> A new state object is used to set up the instance.
<span class="fm-combinumeral1">#3</span> This new function is used to extract the state of the instance.
<span class="fm-combinumeral1">#4</span> The data in the state object is used to set up the instance.
<span class="fm-combinumeral1">#5</span> The offset value changes when a new event is pulled from the event log and emitted to the downstream components.
<span class="fm-combinumeral1">#6</span> The state object of the instance contains the current data offset in the event log.
```

## [](/book/grokking-streaming-systems/chapter-5/)Exactly-once or effectively-once?

For the system[](/book/grokking-streaming-systems/chapter-5/) usage job, neither[](/book/grokking-streaming-systems/chapter-5/) at-most-one nor[](/book/grokking-streaming-systems/chapter-5/) the[](/book/grokking-streaming-systems/chapter-5/) at-least-once semantics[](/book/grokking-streaming-systems/chapter-5/) are ideal because[](/book/grokking-streaming-systems/chapter-5/) accurate results are not guaranteed, but we need them to make the right decision. To achieve this goal, we can choose the last semantic: *exactly-once*, which guarantees that each event is successfully processed once and only once. Hence, the results are accurate.

First, let’s discuss what we mean by *exactly-once*. It is critical to understand the fact that every event is *not* really processed or successfully processed exactly one time like the name suggests. The real meaning is that if you look at the job as a black box—in other words, if you look only at the input and the output and ignore how the job really works internally, it *looks like* each event is processed successfully once and only once. However, if we dive into the system internally, it is possible for each event to be processed more than one time. Now, if you look at the topic of this chapter it is *delivery semantics* instead of *process semantics*. Subtle, right?

When the semantic was briefly introduced earlier in this chapter, we mentioned that it is called *effectively-once* in some frameworks. Technically, effectively-once could be a more accurate term, but exactly-once is widely used; thus, we decided to use the term exactly-once as the standard in this book, so you won’t be confused in the future.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/05_25.png)

If you still feel that the *looks like* (or *effectively*) part is tricky, it is totally understandable. To help you understand better what it really is, let’s steer away and talk a little about an interesting concept next: *idempotency*. Hopefully, it will be helpful in giving you a better idea about what we mean by *effectively*.

A real exactly-once is extremely difficult in distributed systems—for real.

## [](/book/grokking-streaming-systems/chapter-5/)Bonus concept: Idempotent operation

*Idempotent operation* seems[](/book/grokking-streaming-systems/chapter-5/) like a[](/book/grokking-streaming-systems/chapter-5/) loaded[](/book/grokking-streaming-systems/chapter-5/) term, right? It is a computational and mathematical term that means no matter how many times a function is given a quantity, the output will always be the same. Another way to think about it is: making multiple identical calls to the operation has the *same effect* as making a single call. Clear as mud? No worries. Let’s get into one example in the context of a credit card class.

Let’s look at two methods of the class: `setCardBalance()` and `charge()`.

-  The `setCardBalance()` function sets the card balance to a new value specified as the parameter.
-  The `charge()` function adds the new amount to the balance.

```
class CreditCard {
  double balance;
  public void setCardBalance(double balance) { #1
    this.balance = balance;
  }
  public void charge(float amount) {           #2
    balance += amount;
  }
}
<span class="fm-combinumeral1">#1</span> The results would be the same no matter how many times (more than 0 times though) the <code class="codechar">setCardBalance()</code> function is called with the same parameter.
<span class="fm-combinumeral1">#2</span> The balance (state) would change every time the <code class="codechar">charge()</code> function is called with the same parameter.
```

One interesting property of the `setCardBalance()` function is that after it is called once, the state of the credit card object (the card balance) is set to the new value. If the function is then invoked the second time, the balance will still set to the new value again, but the state (the balance) is the same as before. By looking at the card balance, it looks like the function is only called one time because you can’t tell if it is called once or more than once. In other words, the function might be called once or more than once, but it is *effectively once*, since the effect is the same. Because of this behavior, the `setCardBalance()` function is an idempotent operation.

As a comparison, the `charge()` function is not an idempotent operation. When it is invoked once, the balance will increase by the amount. If the call is repeated for the second time by mistake, the balance will increase again, and the card object will be in a wrong state. Therefore, since the function is not idempotent, it really needs to be called *exactly once* for the state to be correct.

The *exactly-once* semantic in streaming systems works like the `setCardBalance()` function above. From the states of all the instances in the job, it looks like each event is processed exactly one time, but internally, the event might be processed more than once by each component.

## [](/book/grokking-streaming-systems/chapter-5/)Exactly-once, finally

After learning the[](/book/grokking-streaming-systems/chapter-5/) real meaning[](/book/grokking-streaming-systems/chapter-5/) of the semantic and the concept of the idempotent operation, plus knowing the power of returning the accurate results, are you more interested in how exactly-once works now? Exactly-once may sound fancy, but it is really not that complicated. Typically, the exactly-once semantic is supported with checkpointing, which is very similar to the at-least-once support. The difference is that checkpoints are created for both sources and operators, so they can all travel back in time together during a rollback. Note that checkpoints are needed only for the operators with internal states. Checkpoints are not needed for the operators without internal states because there is nothing to recover during a rollback.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/05_26.png)

Does it sound simple so far? Don’t celebrate yet. The state of a source instance is just an offset. But the state of an operator instance could be much more complicated, since it is specific to the logic. For operators, the state could be a simple number, a list, a map, or a complicated data structure. Although streaming engines are responsible for managing the checkpoints data normally, it is important to understand the cost behind the scenes.

## [](/book/grokking-streaming-systems/chapter-5/)State handling code in the system usage analyzer component

With the Streamwork framework[](/book/grokking-streaming-systems/chapter-5/), to make[](/book/grokking-streaming-systems/chapter-5/) the `SystemUsageAnalyzer` component[](/book/grokking-streaming-systems/chapter-5/) handle[](/book/grokking-streaming-systems/chapter-5/) the creation[](/book/grokking-streaming-systems/chapter-5/) and usage of instance state, the changes are similar to the `TransactionSource` we have seen earlier.

-  The base class is changed from `Operator` to `StatefulOperator`.
-  The `setupInstance()` function takes an extra state parameter.
-  A new `getState()` function is added.

```
public abstract class Operator extends Component {
  public abstract void setupInstance(int instance);
  public abstract void getEvents(EventCollector eventCollector);
  public abstract GroupingStrategy getGroupingStrategy();
}

public abstract class StatefulOperator extends Component {
  public abstract void setupInstance(int instance, State state); #1
  public abstract void apply(Event event, EventCollector eventCollector);
  public abstract GroupingStrategy getGroupingStrategy();
  public abstract State getState();                              #2
}

class SystemUsageAnalyzer extends StatefulOperator {
  int transactionCount;
  public void setupInstance(int instance, State state) {
    AnalyzerState mstate = (AnalyzerState)state;
    transactionCount = state.count;                              #3
    ……
  }
  
  
  public void apply(Event event, EventCollector eventCollector) {
    transactionCount++;
    eventCollector.add(transactionCount);                        #4
  }
  
  public State getState() {
    AnalyzerState state = new AnalyzerState();
    State.count = transactionCount;                              #5
    return state;
  }
}
<span class="fm-combinumeral1">#1</span> A new state object is used to set up the instance.
<span class="fm-combinumeral1">#2</span> This new function is used to extract the state of the instance.
<span class="fm-combinumeral1">#3</span> When an instance is constructed, a state object is used to initialize the instance.
<span class="fm-combinumeral1">#4</span> The count variable changes when events are processed.
<span class="fm-combinumeral1">#5</span> A new state object is created to store instance data periodically.
```

Note that the API supported by the Streamwork framework is a low-level API to show you how things work internally. Nowadays, most frameworks support higher level APIs, such as functional and declarative APIs. With these new types of APIs, reusable components are designed, so users don’t need to worry about the details. You should be able to tell the difference when you start using one in the future.

## [](/book/grokking-streaming-systems/chapter-5/)Comparing the delivery semantics again

All the delivery[](/book/grokking-streaming-systems/chapter-5/) semantics[](/book/grokking-streaming-systems/chapter-5/)[](/book/grokking-streaming-systems/chapter-5/) have their own use cases. Now that we have seen all the delivery semantics, let’s compare the differences again (in an overly simplified manner) in one place. We can see from the table that follows it is clear that different delivery semantics have different pros and cons. Sometimes, none of them are perfect for your use case. In those cases, then, you will have to understand the tradeoffs and make the decision accordingly. You may also need to change from one to another when requirements change.

Regarding decisions and tradeoffs, a reasonable concern for people considering choosing at-most-once and at-least-once for benefits like latency and efficiency is that accuracy is not guaranteed. There is a popular technique to avoid this problem that could be helpful to make people feel better: *lambda architecture*. With lambda architecture, a companion batch process is running on the same data to generate accurate results with higher end-to-end latency. Since we have a lot to digest in this chapter, we will talk about it later in more detail in chapter 10.

| Delivery semantics | At-most-once | At-least-once | Exactly-once |
| --- | --- | --- | --- |
| Accuracy | <br>      <br>       No accuracy guarantee because of missing events  <br> | <br>      <br>       No accuracy guarantee because of duplicated events  <br> | <br>      <br>       (Looks like) accurate results are guaranteed  <br> |
| Latency (when errors happen) | <br>      <br>       Tolerant to failures; no delay when errors happen  <br> | <br>      <br>       Sensitive to failures; potential delay when errors happen  <br> | <br>      <br>       Sensitive to failures; potential delay when errors happen  <br> |
| Complexity/ resource usage | <br>      <br>       Very simple and light weight  <br> | <br>      <br>       Intermediate (depends on the implementation)  <br> | <br>      <br>       Complex and heavyweight  <br> |
| Maintenance burden | <br>      <br>       Low  <br> | <br>      <br>       Intermediate  <br> | <br>      <br>       High  <br> |
| Throughput | <br>      <br>       High  <br> | <br>      <br>       Intermediate  <br> | <br>      <br>       Low  <br> |
| Code | <br>      <br>       No code change is needed  <br> | <br>      <br>       Some code change is needed  <br> | <br>      <br>       More code change is needed  <br> |
| Dependency | <br>      <br>       No external dependencies  <br> | <br>      <br>       No external dependencies (with acknowledging)  <br> | <br>      <br>       Need external storage to save checkpoints  <br> |

## [](/book/grokking-streaming-systems/chapter-5/)Summary

In this chapter, we[](/book/grokking-streaming-systems/chapter-5/) discussed[](/book/grokking-streaming-systems/chapter-5/) an important[](/book/grokking-streaming-systems/chapter-5/) new concept[](/book/grokking-streaming-systems/chapter-5/) in streaming systems: delivery[](/book/grokking-streaming-systems/chapter-5/) semantics or delivery guarantees. Three types of semantics you can choose for your streaming jobs are:

-  *At-most-once*—Each event is guaranteed to be processed no more than once, which means it could be skipped when any failure happens in the streaming jobs.
-  *At-least-once*—Events are guaranteed to be processed by the stream jobs, but it is possible that some events will be processed more than once in the face of failures.
-  *Exactly-once*—With this semantic, from the results, it looks like each event is processed only once. It is also known as effectively-once.

We discussed the pros and cons of each of these semantics in this chapter and briefly talked about an important technique to support at-least-once and exactly-once in streaming systems: checkpointing. The goal is for you be able to choose the most suitable delivery semantics for your own use cases.

## [](/book/grokking-streaming-systems/chapter-5/)Exercises

1.  Which delivery semantic would you choose if you were building the following jobs, and why?

-  Find out the most popular hashtags on Twitter.
-  Import records from a data stream to a database.

1.  In this chapter, we have looked at the system usage analyzer component in the system usage job and modified it to be an idempotent operation. What is the usage writer component? Is it an idempotent operation or not?

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/05_27.png)

## [](/book/grokking-streaming-systems/chapter-5/)Up next ...

From chapter 2 through chapter 5,[](/book/grokking-streaming-systems/chapter-5/) quite a few concepts have been introduced. They are the most common and basic concepts you need when you start building streaming systems. In the next chapter, we are going to take a small break and review what we have learned so far. Then, we will jump into more advanced topics like windowing and join operations.
