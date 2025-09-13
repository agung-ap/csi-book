# Chapter 4. Messaging Considerations and Patterns

In the previous chapters we explored two very different approaches to
broker-based messaging and how they handle concerns such as throughput,
high availability and transactionality. In this chapter we are going to
focus on the other half of a messaging system—the client logic. We
will discuss some of the mechanical complexities that message-based
systems need to address and some patterns that can be applied to deal
with them. To round out the discussion, we will discuss how to reason
about messaging products in general and how they apply to your
application logic.

# Dealing with Failure

A system based on messaging must be able to deal with failures in a
graceful way. Failures come in many forms at various parts of the
application.

## Failures When Sending

When producing messages, the primary failure that needs to be considered
is a broker outage. Client libraries usually provide logic around
reconnection and resending of unacknowledged messages in the event that
the broker becomes unavailable.

Reconnection involves cycling through the set of known addresses for a
broker, with delays in-between. The exact details vary between client
libraries.

While a broker is unavailable, the application thread performing the
send may be blocked from performing any additional work if the send
operation is synchronous. This can be problematic if that thread is
reacting to outside stimuli, such as responding to a web service
request.

If all of the threads in a web server’s thread pool are suspended while
they are attempting to communicate with a broker, the server will begin
rejecting requests back to upstream systems, typically with
`HTTP 503 Service Unavailable`. This situation is referred to as
*back-pressure*, and is nontrivial to address.

One possibility for ensuring that an unreachable broker does not exhaust
an application’s resource pool is to implement the
circuit breaker pattern around messaging code ([Figure 4-1](https://learning.oreilly.com/library/view/understanding-message-brokers/9781492049296/ch04.html#circuit_breaker)). At a high level, a circuit breaker is a
piece of logic around a method call that is used to prevent threads from
accessing a remote resource, such as a broker, in response to
application-defined exceptions.

![Circuit Breaker](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492049296/files/assets/umbk_0401.png)

###### Figure 4-1. [Circuit breaker](https://www.martinfowler.com/bliki/CircuitBreaker.html)

A circuit breaker has three states:

ClosedTraffic calls are routed into the method as normal.

OpenAn error state around the resource has been detected;
subsequent method calls are routed to alternative logic, such as the
formatting of an immediate error message.

Half-OpenTriggered after a period of time to allow threads to
retest the protected reource. From here, the circuit breaker will
either be closed, allowing application logic to continue as normal, or
reopened.

Circuit breaker implementations vary in terms of functionality and can
take into consideration concerns such as timeouts and error thresholds.
In order for message sends to work correctly with circuit breakers, the
client library must be configured to throw an exception at some point if
it cannot send. It should not attempt to reconnect infinitely.

Asynchronous sends, such as those performed by Kafka, are not in
themselves a workaround for this issue. An asynchronous send will
involve messages being placed into a finite in-memory buffer that is
periodically sent by a background thread to the broker. In the case of
Kafka’s client library, if this buffer becomes full before the client is
able to reconnect, then any subsequent sends will be blocked (i.e.,
become synchronous). At this time the application thread will wait for
some period until eventually the operation is abandoned and a
`TimeoutException` is thrown. At best, asynchronous sends will delay the
exhaustion of an application’s thread pool.

## Failures When Consuming

In consumption there are two different types of failures:

PermanentThe message that you are consuming will never be able to
be processed.

TemporaryThe message would normally be processed, but this is not
possible at this time.

### Permanent failures

Permanent failures are usually caused by an incorrectly formed payload
or, less commonly, by an illegal state within the entity that a message
refers to (e.g., the betting account that a withdrawal is coming from
being suspended or canceled). In both cases, the failure is related to
the application, and if at all possible, this is where it should be
handled. Where this is not possible, the client will often fall back
to broker redelivery.

JMS-based message brokers provide a redelivery mechanism that is used
with transactions. Here, messages are redispatched for processing by the
consumer when an exception is thrown. When messages are redelivered, the
broker keeps track of this by updating two message headers:

-

`JMSRedelivered` set to `true` to indicate redelivery

-

`JMSXDeliveryCount` incremented with each delivery

Once the delivery count exceeds a preconfigured threshold, the message
is sent to a *dead-letter queue* or DLQ. DLQs have a tendency to be
used as a dumping ground in most message-based systems and are rarely
given much thought. If left unconsumed, these queues can prevent the
cleanup of journals and ultimately cause brokers to run out of disk
space.

So what should you do with these queues? Messages from a DLQ can be
quite valuable as they may indicate corner cases that your application
had not considered or actions requiring human intervention to correct.
As such they should be drained to either a log file or some form of
database for periodic inspection.

As previously discussed, Kafka provides no mechanism for transactional
consumption and therefore no built-in mechanism for message redelivery
on error. It is the responsibility of your client code to provide
redelivery logic and send messages to dead-letter topics if needed.

### Temporary failures

Temporary failures in message consumption fall into one of two
categories:

GlobalAffecting all messages. This includes situations
such as a consumer’s backend system being unavailable.

LocalThe current message cannot be processed, but other messages on the queue
can. An example of this is a database record relating to a message being
locked and therefore temporarily not being updateable.

Failures of this type are by their nature transient and will likely
correct themselves over time. As such, the way they need to be handled
in significantly different ways to handle permanent failures. A message that cannot
be processed now is not necessarily illegitimate and should not end up
on a DLQ. Going back to our deposit example, not being able to credit a
payment to an account does not mean that the payment should just be
ignored.

There are a couple of options that you may want to consider on a case by case basis, depending on the capabilities of your messaging system:

-

If the problem is *local*, perform retries within the message consumer
itself until the situation corrects itself. There will always be a point
at which you give up. Consider escalating the message for human
intervention within the application itself.

-

If the situation is *global*, then relying on a redelivery mechanism that eventually pushes
messages into a DLQ will result in a succession of perfectly-legitimate
messages being drained from the source queue and effectively being
discarded. In production systems, this type of situation is
characterized by DLQs accumulating messages in bursts. One solution to
this situation is to turn off consumption altogether until the situation
is rectified through the use of the Kill Switch pattern ([Figure 4-2](https://learning.oreilly.com/library/view/understanding-message-brokers/9781492049296/ch04.html#kill_switch_sequence_diagram)).

A Kill Switch operates by catching exceptions related to transient
issues and pausing consumption. The message currently being processed
should either be rolled back if using a transaction, or held onto by the
consuming thread. In both cases, it should be possible to reprocess the
message later.

![Kill Switch sequence diagram](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492049296/files/assets/umbk_0402.png)

###### Figure 4-2. Kill Switch sequence diagram

The consumer should trigger a background checker task to periodically
determine whether the issue has gone away. If the issue is a web service
outage, the check might be a poll of a URL that simply acknowledges that
the service is up. If the issue is a database outage, then the check
might consist of a dummy SQL query being run (e.g., `SELECT 1 FROM DUAL`
on Oracle). If the check operation succeeds, then the checker task
reactivates the message consumer and terminates itself.

# Preventing Duplicate Messages with Idempotent Consumption

Previously we discussed that systems based on queues must deal with the
possibility of duplicate messages. In the event of a consumer system
going offline unexpectedly, there may be a situation where messages were
processed but had not yet been acknowledged. This applies regardless of
whether you are using a transaction-capable broker and did not yet
commit, or in the case of Kafka did not move the consumed offset
forward. In both cases, when the client is restarted, these
unacknowledged messages will be reprocessed.

Duplication may also occur when a system that is upstream of a broker
reissues the same payloads. Consider the scenario where a system has its
inputs reloaded into it after an outage involving data loss. The replay
of the data into the system causes a side effect of sending messages
into a queue. The messages are technically different from those that
were sent in the past (they have different message IDs or offsets), but
they trigger the same consumer logic multiple times.

To avoid processing the message multiple times, the consumption logic
needs to be made *idempotent*. The Idempotent Consumer pattern acts like
a stateful filter that allows logic wrapped by it to be executed only
once. Two elements are needed to implement this:

-

A way to uniquely identify each message by a business key.

-

A place to store previously seen keys. This is referred to as an
idempotent repository. Idempotent repositories are containers for a
durable set of keys that will survive restarts of the consumer and can
be implemented in database tables, journals, or similar.

Consider the following JSON message which credits an account:

```json
{
    "timestamp" : "20170206150030",
    "accountId" : "100035765",
    "amount" : "100"
}
```

When a message arrives, the consumer needs to uniquely identify it. As
discussed earlier, built-in surrogate keys such as a message ID or
offset are not adequate to protect from upstream replays. In the message
above, a good candidate for this key is a combination of the `timestamp`
and `account` fields of the message, as it is unlikely that two deposits
for the same account happen at the same time.

The idempotent repository is checked to see whether it contains the key,
and if it does not, the logic wrapped by it is executed, otherwise it is
skipped. They key is stored in the idempotent repository according to
one of two strategies:

EagerlyBefore the wrapped logic is executed. In this case, the
consumer needs to remove the key if the wrapped logic throws an error.

LazilyAfter the logic is executed. In this situation, you run the
risk of duplicate processing if the key is not stored due to a system
crash.

In addition to timings, when developing idempotent repositories you need
to be aware that they may be accessed by multiple consumer
instances at the same time.

###### Note

The Apache Camel project is a Java-based integration framework
that includes an implementation of numerous integration patterns,
including the
[Idempotent Consumer](https://camel.apache.org/idempotent-consumer.html).
The project’s documentation provides a good starting point for
implementing this pattern in other environments. It includes many
idempotent repository implementations for storing keys in files,
databases, in-memory data grids, and even Kafka topics.

# What to Consider When Looking at Messaging Technologies

Message brokers are a tool, and you should aim to use the right one for
the job. As with any technology, it is difficult to make objective
decisions unless you know what questions to ask. Your choice of
messaging technology must first and foremost be led by your use cases.

What sort of a system are you building? Is it message-driven, with clear
relationships between producers and consumers, or event-driven where
consumers subscribe to streams of events? A basic queue-based system is
enough for the former, while there are numerous options for the latter
involving persistent and non-persistent messaging, the choice of which
will depend on whether or not you care about missing messages.

If you need to persist messages, then you need to consider how that
persistence is performed. What sorts of storage options does the product
support? Do you need a shared filesystem, or a database? Your operating
environment will feed back into your requirements. There is no point
looking at a messaging system designed for independent commodity servers
with dedicated disks if you are forced to use a storage area network
(SAN).

Broker storage is closely related to the high availability mechanism. If you
are targeting a cloud deployment, then highly available shared resources
such as a network filesystem will likely not be available. Look at
whether the messaging system supports native replication at the level of
the broker or its storage engine, or whether it requires a third-party
mechanism such as a replicated filesystem. High availability also needs
to be considered over the entire software to hardware stack—a highly
available broker is not really highly available if both master and slave
can be taken offline by a filesystem or drive failure.

What sort of message ordering guarantees does your application require?
If there is an ordering relationship between messages, then what sort of
support does the system provide for sending these related messages to a
single consumer?

Are certain consumers in your applications only interested in subsets of
the overall message stream? Does the system support filtering messages
for individual consumers, or do you need to build an external filter
that drops unwanted messages from the stream?

Where is the system going to be deployed? Are you targeting a private
data center, cloud, or a combination of the two? How many sites do you
need to pass messages between? Is the flow unidirectional, in which
case replication might be enough, or do you have more complex routing
requirements? Does the messaging system support routing or
store-and-forward networking? Is the replication handled by an external
process? If so, how is that process made highly available?

For a long time, marketing in this field was driven by performance
metrics, but what does it matter if a broker can push thousands of
messages per second if your total load is going to be much lower than
that? Get an understanding of what your real throughput is likely to be
before being swayed by numbers. Large message volumes per day can
translate to relatively small numbers per second. Consider your traffic
profile—are the messages going to be a constant 24-hour stream, or
will the bulk of traffic fall into a smaller timeframe? Average numbers
are not particularly useful—you will get peaks and troughs. Consider
how the system will behave on the largest volumes.

Perform load tests to get a good understanding of how the system will
work with your use cases. A good load test should verify system
performance with:

-

Estimated message volumes and sizes—use sample payloads wherever
possible.

-

Expected number of producers, consumer, and destinations.

-

The actual hardware that the system will run on. This is not always
possible, but as we discussed, it will have a substantial impact on
performance.

If you are intending to send large messages, check how the system deals
with them. Do you need some form of additional external storage outside
of the messaging system, such as when using the Claim Check pattern? Or
is there some form of built-in support for streaming? If streaming very
large content like video, do you need persistence at all?

Do you need low latency? If so, how low? Different business domains will
have different views on this. Intermediary systems such as brokers add
processing time between production and consumption—perhaps you should
consider brokerless options such as ZeroMQ or an AMQP routing setup?

Consider the interaction between messaging counterparties. Are you going
to be performing request-response over messaging? Does the messaging
system support the sorts of constructs that are required, i.e., message
headers, temporary destinations, and selectors?

Are you intending on spanning protocols? Do you have C++ servers that
need to communcate with web clients? What support does the messaging
system provide for this?

The list goes on…transactions, compression, encryption, duration of
message storage (possibly impacted by local legislation), and commercial
support options.

It might initially seem overwhelming, but if you start looking at the
problem from the point of view of your use cases and deployment
environment, the thought process behind this exercise will
steer you naturally.
