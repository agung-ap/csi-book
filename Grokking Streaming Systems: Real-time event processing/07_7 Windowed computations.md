# 7 [](/book/grokking-streaming-systems/chapter-7/)Windowed computations

### In this chapter

- standard windowing strategies
- time stamps in events
- windowing watermark and late events

“The attention span of a computer is only as long as its power cord.”

—Unknown

In the previous chapters, we built a streaming job to detect fraudulent credit card transactions. There could be many analyzers that use different models, but the basic idea is to compare the transaction with the previous activities on the same card. Windowing is designed for this type of work, and we are going to learn the windowing support in streaming systems in this chapter.

## [](/book/grokking-streaming-systems/chapter-7/)Slicing up real-time data

As the popularity[](/book/grokking-streaming-systems/chapter-7/) of the[](/book/grokking-streaming-systems/chapter-7/) team’s new product has grown so has the attention of new types of hackers. A group of hackers has started a new scheme involving gas stations.

Here’s how it works: They capture an innocent victim’s card information and duplicate it from multiple new physical credit cards. From there, the attackers will send the newly created fraudulent cards out to others in the group and orchestrate spending money on the same credit card from multiple locations across the world at the same time to purchase gas. They hope that by charging the card all at once, the card holder will not notice the charges until it’s too late. The result is free gas. Why do they go to a global scale to try and get free tanks of gas? We can consider this a mystery.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/07_01.png)

How do we prevent this scam?

For the purposes of this book, we are going to use round numbers for easy math calculations. We will also assume that the fastest anyone can travel is 500 miles per hour on a plane. Luckily, the team has already thought of this type of scam.

## [](/book/grokking-streaming-systems/chapter-7/)Breaking down the problem in detail

We have two[](/book/grokking-streaming-systems/chapter-7/) problems[](/book/grokking-streaming-systems/chapter-7/) that we are trying to solve here. First, we are looking for large jumps of distance within a single credit card. Second, we are looking for large jumps in card usage across multiple credit cards. In the first scenario, we will be looking to mark specific card transactions as fraudulent; in the second one, we will be looking to flag merchants (gas stations) as under attack by these menacing gas thieves.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/07_02.png)

```
Here’s our formula:final double maxMilesPerHour = 500;
final double distanceInMiles = 2000;
final double hourBetweenSwipes = 2;
if (distanceInMiles > hourBetweenSwipe * maxMilesPerHour) {
 // mark this transaction as potentially fraudulent
}
```

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/07_03.png)

## [](/book/grokking-streaming-systems/chapter-7/)Breaking down the problem in detail (continued)

This hacker group in particular likes to create massive worldwide attacks—all filling up cars with gas. It’s important to look at the behaviors of the entire credit card system as well as one credit card in the system. When these large-scale gas station attacks happen, we need some way to block stores from processing any credit cards that are being attacked to further enhance the security of the system. Study the diagram below that uses a few US cities as examples for locations from which a card could be charged.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/07_04.png)

We have two ways to prevent this type of scam:

-  We can block individual credit cards from being charged.
-  We can block gas stations from processing any credit cards.

But what tools do we have in our streaming systems to help us detect fraudulent activity?

## [](/book/grokking-streaming-systems/chapter-7/)Two different contexts

To address our two different ways of preventing fraud, let’s look at the graph from a previous page to further show how we can split up the context. Remember that the windowed proximity analyzer looks for fraud within the context of single credit cards, and the new analyzer works within the context of stores.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/07_05.png)

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/07_06.png)

## [](/book/grokking-streaming-systems/chapter-7/)Windowing in the fraud detection job

Most of the analyzer components in the fraud detection job use some type of *window* (we will discuss this next) to compare the current transaction against the previous ones. In this chapter, we are going to focus on the *windowed proximity analyzer*, which detects individual credit cards being swapped in different locations. For the gas stations, we are going to leave it to our smart readers.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/07_07.png)

## [](/book/grokking-streaming-systems/chapter-7/)What exactly are windows?

Since the credit card[](/book/grokking-streaming-systems/chapter-7/) transactions[](/book/grokking-streaming-systems/chapter-7/) are constantly[](/book/grokking-streaming-systems/chapter-7/) running through the system, it can be challenging to create cut-off points or segments of data to process. After all, how do you choose an end to something that is potentially infinite, such as a data stream?

Using windows in streaming systems allows developers to slice up the endless stream of events into chunks for processing. Note that the slicing can be either *time-based* (temporal) or *event count-based* in most cases. We are going to use time-based windows in context later, since they fit our scenarios better.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/07_08.png)

## [](/book/grokking-streaming-systems/chapter-7/)Looking closer into the window

What we’ve done[](/book/grokking-streaming-systems/chapter-7/) with streaming systems so far in this book has been on a per-event, or individual, basis. This method works well for many cases, but it could have some limitations as you start to get into more complex problems. In many other cases, it can be useful to group events via some type of interval to process. Check out the diagrams below to learn a little more about the very basic concept of windowing.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/07_09.png)

## [](/book/grokking-streaming-systems/chapter-7/)New concept: Windowing strategy

After understanding what[](/book/grokking-streaming-systems/chapter-7/) windowing[](/book/grokking-streaming-systems/chapter-7/) is, let’s look at how the events are grouped together using a *windowing strategy*. We are going to walk you through three different types of windowing strategies and discuss their differences in the windowed proximity analyzer. The three types of windowing strategies are:

-  Fixed window
-  Sliding window
-  Session window

Often, there is no hard requirement for choosing a *windowing strategy* (how the events are grouped). You will need to talk with other technologists and product owners on your team to make the best decision for the specific problem you are trying to solve.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/07_10.png)

## [](/book/grokking-streaming-systems/chapter-7/)Fixed windows

The first and[](/book/grokking-streaming-systems/chapter-7/) most basic[](/book/grokking-streaming-systems/chapter-7/) window[](/book/grokking-streaming-systems/chapter-7/) is *fixed window*. Fixed windows are also referred to as *tumbling windows*. Events received from the beginning to the end of each window are grouped as a batch to be processed together. For example, when a *fixed one-minute time window* (also known as a *minutely window*) is configured, all the events within the same one-minute window will be grouped together to be processed. Fixed windows are simple and straightforward, and they are very useful in many scenarios. The question is: do they work for the windowed proximity analyzer?

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/07_11.png)

## [](/book/grokking-streaming-systems/chapter-7/)Fixed windows in the windowed proximity analyzer

Here is an example[](/book/grokking-streaming-systems/chapter-7/) of using[](/book/grokking-streaming-systems/chapter-7/) a fixed[](/book/grokking-streaming-systems/chapter-7/) window to look for repeated charges from the same card. To keep things simple, we are just using minutely windows to see what each group of events would look like. The goal is to find out repeated transactions from each card within each one-minute window. We will worry about the other things, such as the 500-miles-per-hour max distance logic later.

It’s important to note that using a fixed time window only means the time interval is fixed. It’s possible to get more or fewer events in each window based on the number of events flowing through the job.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/07_12.png)

## [](/book/grokking-streaming-systems/chapter-7/)Detecting fraud with a fixed time window

Let’s look at[](/book/grokking-streaming-systems/chapter-7/) how the[](/book/grokking-streaming-systems/chapter-7/) card proximity[](/book/grokking-streaming-systems/chapter-7/) analyzer would behave using fixed time windows. The amount of transactions per window has been limited to only a few, so we can learn the concepts of windowing most easily.

If you look closely at this diagram, it will hopefully be more clear how fixed time windows would affect potential fraud scores. By running fixed time windows, you are just cutting off other transactions that run through the system, even if they are only a second outside of the window. Do you think this is the windowing type we should use to most accurately detect fraud?

The answer is that a fixed time window is not ideal for our problem. If two transactions on the same card are a just few seconds apart, but they fall into two different fixed windows, such as the two transactions from the card ....6789, we won’t be able to run the card proximity function on them.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/07_13.png)

## [](/book/grokking-streaming-systems/chapter-7/)Fixed windows: Time vs. count

Before moving forward[](/book/grokking-streaming-systems/chapter-7/) to the next[](/book/grokking-streaming-systems/chapter-7/) windowing[](/book/grokking-streaming-systems/chapter-7/) strategy, let’s[](/book/grokking-streaming-systems/chapter-7/) take[](/book/grokking-streaming-systems/chapter-7/) a look[](/book/grokking-streaming-systems/chapter-7/) at two types of fixed windows first:

-  Time windows are defined by an unchanging interval of time.
-  Count windows are defined by an unchanging interval of number of events processed.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/07_14.png)

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/07_15.png)

## [](/book/grokking-streaming-systems/chapter-7/)Sliding windows

Another widely supported[](/book/grokking-streaming-systems/chapter-7/) windowing[](/book/grokking-streaming-systems/chapter-7/) strategy[](/book/grokking-streaming-systems/chapter-7/) is[](/book/grokking-streaming-systems/chapter-7/) a *sliding window.* Sliding windows are similar to fixed time windows but different in that they also have a defined *slide interval*. A new window is created every slide interval instead of when the previous window ends. The window interval and slide interval allow windows to overlap, and because of this, each event can be included into more than one window. Technically, we can say that a fixed window is a special case of sliding window in which the window interval equals the slide interval.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/07_16.png)

## [](/book/grokking-streaming-systems/chapter-7/)Sliding windows: Windowed proximity analyzer

We could use[](/book/grokking-streaming-systems/chapter-7/) a sliding[](/book/grokking-streaming-systems/chapter-7/) window[](/book/grokking-streaming-systems/chapter-7/) to look for repeated charges from the same card in overlapping windows of time. The diagram below shows one-minute sliding windows with 30-second slide intervals. When using sliding windows it’s important to understand that an event may be included in more than one window.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/07_17.png)

## [](/book/grokking-streaming-systems/chapter-7/)Detecting fraud with a sliding window

Sliding windows[](/book/grokking-streaming-systems/chapter-7/) differ[](/book/grokking-streaming-systems/chapter-7/) from fixed[](/book/grokking-streaming-systems/chapter-7/) windows, as they overlap each other based on the specified interval. The slide provides a nice mechanism for a more evenly distributed aggregation of events to determine whether a transaction is to be marked as fraudulent or not. Sliding windows help with the lopping off of events, as we saw in fixed windows.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/07_18.png)

As the window slides, the data elements it can make operations on changes. The gradual slide or advance of what data it can reference offers a more gradual and consistent view of data.

##### Pop Quiz!

Do you think the overlap on sliding windows would be better or worse for calculating averages? Why?

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/07_19.png)

## [](/book/grokking-streaming-systems/chapter-7/)Session windows

The last windowing[](/book/grokking-streaming-systems/chapter-7/) strategy we would like to cover before jumping into the implementation is the *session window*. A session represents a period of activity separated by a defined gap of inactivity, and it can be used to group events. Typically, session windows are key-specific, instead of global for all events like the fixed and sliding windows.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/07_20.png)

## [](/book/grokking-streaming-systems/chapter-7/)Session windows (continued)

Session windows are[](/book/grokking-streaming-systems/chapter-7/) typically[](/book/grokking-streaming-systems/chapter-7/) defined[](/book/grokking-streaming-systems/chapter-7/) with[](/book/grokking-streaming-systems/chapter-7/) a timeout, which is the max duration for a session to stay open. We can imagine there is a timer for each key. If there are no events under the key received before the timer times out, the session window will be closed. Next time, when an event under the key is received, a new session will be started. In the diagram below, let’s take look at the transactions from two cards (session windows are typically key specific, and the key here is the card number). Note that the threshold for the gap of inactivity is 10 minutes.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/07_21.png)

## [](/book/grokking-streaming-systems/chapter-7/)Detecting fraud with session windows

Session windows are[](/book/grokking-streaming-systems/chapter-7/) relatively[](/book/grokking-streaming-systems/chapter-7/) less[](/book/grokking-streaming-systems/chapter-7/) straightforward than fixed and sliding windows. Let’s try to see how session windows can potentially be used in the fraud detection job. We don’t have an analyzer with this model in the current design; however, it could be a good one to consider and a good example to demonstrate one use case of session windows.

When someone is shopping in a mall, typically they spend some time looking and comparing first. After some time, finally a purchase is made with a credit card. Afterwards, the shopper may visit another store and repeat the pattern or take a break (you know, shopping can be strenuous). Either way, it is likely that there will be a period of time where the card is not swiped.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/07_22.png)

Therefore, if we look at the two card transaction timelines above, the timeline to the left looks more legitimate than the one to the right, because only one or two transactions happen in each short period of time (session window), and there are gaps between the purchases. In the timeline to the right, the card has been charged many times continuously without a reasonable gap.

## [](/book/grokking-streaming-systems/chapter-7/)Summary of windowing strategies

We have gone[](/book/grokking-streaming-systems/chapter-7/) through[](/book/grokking-streaming-systems/chapter-7/) the concepts[](/book/grokking-streaming-systems/chapter-7/) of three[](/book/grokking-streaming-systems/chapter-7/) different[](/book/grokking-streaming-systems/chapter-7/) windowing[](/book/grokking-streaming-systems/chapter-7/) strategies. Let’s put them together and compare the differences. Note that time-based windows are used in the comparison, but fixed and sliding windows can be event count-based as well.

-  *Fixed windows* (or tumbling windows) have fixed sizes, and a new window starts when the previous one closes. The windows don’t overlap with each other.
-  *Sliding windows* have the same fixed size, but a new one starts before the previous one closes. Therefore, the windows overlap with each other.
-  *Session windows* are typically tracked for each key. Each window is opened by activity and closed by a gap of inactivity.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/07_23.png)

## [](/book/grokking-streaming-systems/chapter-7/)Slicing an event stream into data sets

After all the[](/book/grokking-streaming-systems/chapter-7/) concepts, let’s[](/book/grokking-streaming-systems/chapter-7/) move[](/book/grokking-streaming-systems/chapter-7/) on to[](/book/grokking-streaming-systems/chapter-7/) the implementation-related topics. With windowing strategies, events are processed in small sets instead of isolated events now. Because of the difference, the `WindowedOperator` interface is slightly different from the regular `Operator` interface.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/07_24.png)

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/07_25.png)

## [](/book/grokking-streaming-systems/chapter-7/)Windowing: Concept or implementation

Fundamentally, a windowed[](/book/grokking-streaming-systems/chapter-7/) operator[](/book/grokking-streaming-systems/chapter-7/) is a mechanism to reorganize events as event sets, and streaming engines are typically responsible for managing the event sets. Compared to the jobs we have seen before this chapter, the streaming engines need more resources for windowed operators. The more events there are in each window, the more resource the streaming engines need. In other words, stream jobs are more efficient when the window sizes are small. However, real world problems are often not that ideal. C’est la vie.

Some of you may have already seen the issues with using windowed operators to implement the windowed proximity analyzer in the fraud detection job:

-  In this analyzer, we would like to track transactions far away from each other and compare the distance and the time between them. More specifically, if the distance is greater than 500 miles per hour times the time difference between two transactions in hours, the operator will mark the transaction as *likely fraudulent*. So do we need a multi-hour long sliding window? Hundreds of billions of transactions could be collected in this window, which could be expensive to track and process.
-  Things become more complicated when the 20-millisecond latency requirement is taken into consideration. With a sliding window, there is a *slide interval* to determine, and it needs to be short. If this interval is too long (for example, one second), most transactions (those that happened in the first 980 milliseconds in the second) are going to miss the 20-millisecond deadline.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/07_26.png)

In conclusion, the concepts are useful for us to choose the right strategy for the problem, but to implement the analyzer in the fraud detection job, we need to be more creative than simply relying on the frameworks. Note that this is not a rare case in real-world systems. Streaming frameworks are mainly designed for fast and lightweight jobs, but life is never perfect and simple.

## [](/book/grokking-streaming-systems/chapter-7/)Another look

Now let’s see how the team solves the challenge and stops the gas thieves. The first step is to understand how exactly the transactions are processed in the windowed proximity analyzer.

In this operator, we want to track the times and locations of transactions on each card and verify that the time and distance between any two transactions don’t violate the rule. However, “any two transactions in the window” isn’t really a necessary statement. The problem can be simplified if we look at it in a slightly different way: at any time when a new transaction comes in, we can compare the time and location of the transaction with *the previous transaction on the same card* and apply our equation. The past transactions on the card, before the previous one, and all the transactions on the other cards have no effect on the result and can be ignored.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/07_27.png)

Now since we have the equation already, the problem becomes pretty straightforward: how do we find the previous transaction on the same card?

You might be wondering: what about the sliding window? Good question, and let’s take another look at it too. The perimeter of the earth is about 25,000 miles, so 12,500 miles is the max distance between any two places on earth. Based on our 500 miles per hour traveling speed rule, a person can travel to any place on earth within about 25 hours. Therefore, transactions older than 25 hours don’t need to be calculated. The updated version of the problem to solve is: *how can we find out the previous transaction on the same card within the past 25 hours?*

## [](/book/grokking-streaming-systems/chapter-7/)Key–value store 101

After thinking about[](/book/grokking-streaming-systems/chapter-7/) the calculation[](/book/grokking-streaming-systems/chapter-7/) within[](/book/grokking-streaming-systems/chapter-7/) the windowed proximity analyzer operator, they decided to use a key–value store system to implement it. This is a very useful technique to build windowed operators without using the standard windowed operator support in streaming frameworks, so let’s talk about it here.

A *key–value store* (also known as a *K–V store*) is a data storage system designed for storing and retrieving data objects with keys. It has been a very popular paradigm in the past decade. In case you are not familiar with the term, it works just like a dictionary in which each record can be uniquely identified by a specific key. Unlike the more traditional (and better known) relational databases, the records are totally independent from each other in key–value stores.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/07_28.png)

Why would we want storing systems that have fewer functions? The major advantages are performance and scalability. Because key–value stores don’t need to keep track of the relations between different records, rows, and columns, the internal calculations can be a lot simpler than the traditional databases. As a result, operations like reading and writing run much faster. And because the records are independent of each other, it is also much easier to distribute data on multiple servers and make it work together to provide a key–value store service that can handle a huge amount of data. The two advantages are important for the fraud detection system as well as many other data processing systems.

Another interesting feature supported by some key–value stores is *expiration*. An expiration time could be provided when a key–value pair is added into the store. When the expiration time comes, the key–value pair will be removed automatically from the system and the occupied resources will be freed. This feature is very convenient for windowed operators in streaming systems (more specifically, the “within the past 25 hours” part of our problem statement).

## [](/book/grokking-streaming-systems/chapter-7/)Implement the windowed proximity analyzer

With the help[](/book/grokking-streaming-systems/chapter-7/) of this[](/book/grokking-streaming-systems/chapter-7/) key–value store, streaming engines don’t need to keep and track all the events in the windows in memory. The responsibility has been returned to the system developers. The bad news is: the usage of a key–value store can be different from case to case. There is no simple formula to follow when implementing windowing strategies with key–value stores. Let’s take a look at the windowed proximity analyzer as an example.

In the analyzer, we need to compare the time and location of each transaction with the previous transaction on the same card. The current transaction is in the incoming event, and the previous transaction for each card needs to be kept in the key–value store. The key is the card id, and the value is the time and location (to keep it simple, in the source code that follows the whole event is stored as the value).

```
public class WindowedProximityAnalyzer implements Operator {                 #1
  final static double maxMilesPerHour = 500;
  final static double distanceInMiles = 2000;
  final static double hourBetweenSwipes = 2;
  final KVStore store;
  
  public setupInstance(int instance) {
    store = setupKVStore();                                                  #2
  }
  
  public void apply(Event event, EventCollector eventCollector) {
    TransactionEvent transaction = (TransactionEvent) event;
    TransactionEvent prevTransaction = kvStore.get(transaction.getCardId()); #3


    boolean result = false;
    if (prevTransaction != null) {
      double hourBetweenSwipe =
          transaction.getEventTime() - prevTransaction.getEventTime();
      double distanceInMiles = calculateDistance(transaction.getLocation(),
          prevTransaction.getLocation());
      if(distanceInMiles > hourBetweenSwipe * maxMilesPerHour) {
        // Mark this transaction as potentially fraudulent.
        result = true;                                                        #4
      }
    }

    eventCollector.emit(new AnazlyResult(event.getTransactionId(), result));
    kvStore.put(transaction.getCardId(), transaction);  }                     #5
}
<span class="fm-combinumeral1">#1</span> Operator instead of WindowedOperator is used here.
<span class="fm-combinumeral1">#2</span> Set up the key-value store.
<span class="fm-combinumeral1">#3</span> The previous transaction is loaded from the key-value store.
<span class="fm-combinumeral1">#4</span> Fraudulent transaction is detected.
<span class="fm-combinumeral1">#5</span> The current transaction is stored into the key-value store using the card id as the key. The previous value is replaced now.
```

## [](/book/grokking-streaming-systems/chapter-7/)Event time and other times for events

There is one[](/book/grokking-streaming-systems/chapter-7/) more concept[](/book/grokking-streaming-systems/chapter-7/) we will[](/book/grokking-streaming-systems/chapter-7/) cover[](/book/grokking-streaming-systems/chapter-7/) before wrapping up this chapter. In the code of the windowed proximity analyzer, there is one important piece we would like to zoom in and take a closer look at.

```
transaction.getEventTime();
```

So what is *event time*? Are there other *times*? *Event time* is the time at which the event actually occurs. Most processes on the event don’t happen immediately. Instead, after the event has occurred, it is normally collected and sent to some backend systems later, and then even later it is really processed. All these things happen at different times, so yes, there are quite a few other times. Let’s use our simple traffic monitoring system as the example and look at the important times related to an event.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/07_29.png)

Among all the times, the most important ones for each event are *event time* and *processing time*. Event time for an event is like the birthday for a person. Processing time, on the other hand, is the time at which the event is being processed. In the fraud detection system, what we really care about is the time when the card is swiped, which is the *event time* of the transaction. Event time is typically included in the event objects so that all the calculations on the event have the same time to get the consistent results.

## [](/book/grokking-streaming-systems/chapter-7/)Windowing watermark

Event time is[](/book/grokking-streaming-systems/chapter-7/) used[](/book/grokking-streaming-systems/chapter-7/) in many[](/book/grokking-streaming-systems/chapter-7/) windowed computations, and it is important to understand the gap between event time and processing time. Because of the gap, the windowing strategies we have learned in this chapter aren’t as straightforward as they look.

If we look at the traffic monitor system as an example and configure the vehicle counter operator with simple fixed windows to count the number of vehicles detected in each minute, what would be the open and close times for each window? Note that the time for each event to arrive at the vehicle counter operator instances (the processing time) is a little *after* it is created in an IoT sensor (the event time). If the window is closed exactly when the end of the window comes, the events occurring near the end of the window on the IoT sensors will be missing because they haven’t been received by the counter instances yet. Note that they can’t be put into the next window because, based on the event time, they belong to the already-closed window.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/07_30.png)

The solution to avoid missing events is to keep the window open for a little longer and wait for the events to be received. This extra waiting time is commonly known as the *windowing watermark*.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/07_31.png)

If we look back at the implementation of the windowed proximity analyzer, the watermark is another reason the standard windowed operator is not ideal for the case. Leaving extra time before processing event sets would introduce extra latency and make the 20-millisecond latency requirement even more challenging to meet.

## [](/book/grokking-streaming-systems/chapter-7/)Late events

The windowing watermark[](/book/grokking-streaming-systems/chapter-7/) is critical[](/book/grokking-streaming-systems/chapter-7/) for avoiding[](/book/grokking-streaming-systems/chapter-7/) missing events and generating completed event sets to process. The concept should be easy to understand, but deciding the waiting time isn’t as easy.

For example, in the traffic monitoring system, our IoT sensors work very well. As a result, normally, all the vehicle events are collected successfully within one second. In this case, a one second windowing watermark could be reasonable.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/07_32.png)

However, the word *normally* might trigger an alert. Earlier in the book, we mentioned a few times that one major challenge in building any distributed system is failure handling. It is often a good habit to ask: what if it doesn’t work as expected? Even in a simple system like this one, events could be delayed to be later than one second if something goes wrong—for example, the sensor or the reader could slow down temporarily, or the network could be throttled if the connection is not stable. When this delay happens, the events received after the corresponding window has been closed are known as *late events*. What can we do about them?

Sometimes, dropping these late events could be an option, but in many other cases, it is important for these events to be handled correctly. Most real-world streaming frameworks provide mechanisms to handle these late events, but we will not go into more detail, as the handling is framework-specific. For now, the key takeaway is to keep these late events in mind and not forget about them.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/07_33.png)

## [](/book/grokking-streaming-systems/chapter-7/)Summary

Windowed computation is critical in streaming systems because it is the way to slice isolated events into event sets to process. In this chapter, we have discussed three standard windowing strategies widely supported by most streaming frameworks:

-  Fixed windows
-  Sliding windows
-  Session windows

The basic support in streaming frameworks has its own limitations and may not work in many scenarios. Therefore, in addition to the concepts and how the streaming frameworks handle the windowed operators, we have also learned how to use a key–value store to simulate a windowed operator and overcome the limitations.

At the end of the chapter, we also covered three related concepts that are important when solving real-world problems:

-  Different times related to each event, including event time versus processing time
-  Windowing watermarks
-  Late events

## [](/book/grokking-streaming-systems/chapter-7/)Exercise

1.  At the beginning of the chapter, we mentioned that we have two ways to prevent fraudulent credit card transactions:

-  We can block individual credit cards from being charged.
-  We can block gas stations from processing any credit cards.

Afterward, we focused on detecting issues on individual credit cards but haven’t paid much attention to the second option. The exercise for you is: how can we detect suspicious gas stations, so we can block them from processing credit cards?
