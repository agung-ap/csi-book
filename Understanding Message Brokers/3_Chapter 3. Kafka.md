# Chapter 3. Kafka

Kafka was designed at LinkedIn to get around some of the limitations of
traditional message brokers, and to avoid the need to set up different
message brokers for different point-to-point setups, as described in
[“Scaling Up and Out”](https://learning.oreilly.com/library/view/understanding-message-brokers/9781492049296/ch02.html#scaling-up-and-out). LinkedIn’s use cases were
predominantly based around ingesting very large volumes of data such as
page clicks and access logs in a unidirectional way, while allowing
multiple systems to consume that data without affecting the performance
of producers or other consumers. In effect, Kafka’s reason for being is
to enable the sort of messaging architecture that the Universal Data
Pipeline describes.

Given this end goal, other requirements naturally emerged. Kafka had to:

-

Be extremely fast

-

Allow massive message throughput

-

Support publish-subscribe as well as point-to-point

-

Not slow down with the addition of consumers; both queue and topic
performance degrades in ActiveMQ as the number of consumers rise on a
destination

-

Be horizontally scalable; if a single broker that persists messages
can only do so at the maximum rate of the disk, it makes sense that to
exceed this you need to go beyond a single broker instance

-

Permit the retention and replay of messages

In order to achieve all of this, Kafka adopted an architecture that
redefined the roles and responsibilities of messaging clients and
brokers. The JMS model is very broker-centric, where the broker is
responsible for the distribution of messages, and clients only have to
worry about sending and receiving messages. Kafka, on the other hand, is
client-centric, with the client taking over many of the functions of a
traditional broker, such as fair distribution of related messages to
consumers, in return for an extremely fast and scalable broker. To
people coming from a traditional messaging background, working with
Kafka requires a fundamental shift in perspective.

This engineering direction resulted in a messaging infrastructure that
is capable of many orders of magnitude higher throughput than a regular
broker. As we will see, this approach comes with trade-offs than meant
that Kafka is not suitable for certain types of workloads and
installations.

# Unified Destination Model

To enable the requirements outlined above, Kafka unified both
publish-subscribe and point-to-point messaging under a single
destination type—the *topic*. This is confusing for people coming from a
messaging background where the word topic refers to a broadcast
mechanism from which consumption is nondurable, Kafka topics should be
considered a hybrid destination type, as defined in the
introduction to this book.

###### Note

For the remainder of this chapter, unless we explicitly state
otherwise, the term “topic” will refer to a Kafka topic.

In order to fully understand how topics behave and the guarantees that
they provide, we need to first consider how they are implemented within
Kafka.

*Each topic in Kafka has its own journal.*

Producers that send messages to Kafka append to this journal, and
consumers read from the journal through the use of pointers, which are
continually moved forward. Periodically, Kafka removes the oldest parts
of the journal, regardless of whether the messages contained within have
been read or not. It is a central part of Kafka’s design that the broker
is not concerned with whether its messages are consumed—that
responsibility belongs to the client.

###### Note

The terms “journal” and “pointer” do not appear in
[the Kafka documentation](https://kafka.apache.org/documentation.html).
These well-known terms are used here in order to aid understanding.

This model is completely different from ActiveMQ’s, where the messages
from all queues are stored in the same journal, and the broker marks
messages as deleted once they have been consumed.

Let’s now drill down a bit and consider the topic’s journal in greater
depth.

A Kafka journal is composed of multiple partitions ([Figure 3-1](https://learning.oreilly.com/library/view/understanding-message-brokers/9781492049296/ch03.html#kafka_partitions)). Kafka provides
strong ordering guarantees in each partition. This means that messages
written into a partition in a particular order will be read in the same
order. Each partition is implemented as a rolling log file that
contains a *subset* of all of the messages sent into the topic by its
producers. A topic created has a single partition by default. This idea
of partitioning is central to Kafka’s ability to scale horizontally.

![Kafka Partitions](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492049296/files/assets/umbk_0301.png)

###### Figure 3-1. Kafka partitions

When a producer sends a message into a Kafka topic, it decides which
partition the message is to be sent to. We will look at this in more
detail later.

# Consuming Messages

A client that wants to consume messages controls a named pointer, called
a *consumer group*, that points to a message *offset* in a partition.
The offset is an incrementally numbered position that starts at 0 at the
beginning of the partition. This consumer group, referenced in the API
through a user-defined `group_id`, corresponds to a *single logical
consumer or system*.

Most systems that use messaging consume from a destination via multiple
instances and threads in order to process messages in parallel. As such,
there will typically be many consumer instances sharing the same
consumer group.

The problem of consumption can be broken down as follows:

-

A topic has multiple partitions

-

Many consumer groups can consume from a topic at the same time

-

A consumer group can have many separate instances

This is a nontrivial, many-to-many problem. To understand how Kafka
addresses the relationship between consumer groups, consumer instances,
and partitions, we will consider a series of progressively more complex
consumption scenarios.

## Consumers and Consumer Groups

Let us take as a starting point a topic with a single partition ([Figure 3-2](https://learning.oreilly.com/library/view/understanding-message-brokers/9781492049296/ch03.html#consumer_reading_from_a_partition)).

![Consumer reading from a partition](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492049296/files/assets/umbk_0302.png)

###### Figure 3-2. Consumer reading from a partition

When a consumer instance connects with its own `group_id` to this topic,
it is assigned a partition to consume from and an offset in that
partition. The position of this offset is configurable within the client
as either pointing to the latest position (the newest message) or the
earliest (the oldest message). The consumer polls for messages from the
topic, which results in reading them sequentially from the log.

The offset position is regularly committed back to Kafka and stored as
messages on an internal topic in `__consumer_offsets`. The consumed
messages are not deleted in any way, unlike a regular broker, and the
client is free to rewind the offset to reprocess messages that it has
already seen.

When a second logical consumer connects with a different `group_id`, it
controls a second pointer that is independent of the first ([Figure 3-3](https://learning.oreilly.com/library/view/understanding-message-brokers/9781492049296/ch03.html#consumer_groups)). As such, a
Kafka topic acts like a queue where a single consumer exists, and like a
regular pub-sub topic where multiple consumers are subscribed, with the
added advantage that all messages are persisted and can be processed
multiple times.

![Two consumers in different consumer groups reading from the same partition](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492049296/files/assets/umbk_0303.png)

###### Figure 3-3. Two consumers in different consumer groups reading from the same partition

## Consumers Within a Consumer Group

Where a single consumer instance reads from a partition, it has full
control of the pointer and processes the messages, as described in the
previous section.

If multiple consumer instances were to connect with the same `group_id`
to a topic with one partition, the instance that connected *last* will
be assigned control of the pointer, and it will receive all of the
messages from that point onward ([Figure 3-4](https://learning.oreilly.com/library/view/understanding-message-brokers/9781492049296/ch03.html#two_consumers_same_partition)).

![Two consumers in the same consumer group reading from the same partition](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492049296/files/assets/umbk_0304.png)

###### Figure 3-4. Two consumers in the same consumer group reading from the same partition

This mode of processing where consumer instances outnumber partitions
can be thought of as a type of exclusive-consumer. It can be useful if
you want active-passive (or hot-warm) clustering of your consumer
instances, though having multiple consumers processing in parallel
(active-active, or hot-hot) is much more typical that having consumers
on standby.

###### Note

The distribution behavior outlined above can be quite surprising
when compared with how a regular JMS queue behaves. In that model,
messages sent on a queue would be shared evenly between the two
consumers.

Most often, when we create multiple consumer instances we do so in order
to process messages in parallel, either to increase the rate of
consumption or the resiliency of consumer process. Since only one
consumer instance can read at a time from a partition, how is this
achieved in Kafka?

One way to do this is to use a single consumer instance to consume all
of the messages and hand these to a pool of threads. While this
approach increases processing throughput, it adds to the complexity of
the consumer logic and does nothing to assist in the resiliency of the
consuming system. If the single consumer instance goes offline, due to a
power failure or similar event, then consumption stops.

The canonical way to address this problem in Kafka is to use more
partitions.

# Partitioning

Partitions are the primary mechanism for parallelizing consumption and
scaling a topic beyond the throughput limits of a single broker
instance. To get a better understanding of this, let’s now consider the
situation where there exists a topic with two partitions, and a single
consumer subscribes to that topic ([Figure 3-5](https://learning.oreilly.com/library/view/understanding-message-brokers/9781492049296/ch03.html#one_consumer_multiple_partitions)).

![One consumer reading from multiple partitions](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492049296/files/assets/umbk_0305.png)

###### Figure 3-5. One consumer reading from multiple partitions

In this scenario, the consumer is assigned control of the pointers
corresponding to its `group_id` in both partitions, and proceeds to
consume messages from both.

When an additional consumer is added to this topic for the same
`group_id`, Kafka will reallocate one of the partitions from the first
to the second consumer. Each consumer instance will then consume from a
single topic partition ([Figure 3-6](https://learning.oreilly.com/library/view/understanding-message-brokers/9781492049296/ch03.html#two_consumers_different_partitions)).

In order to enable parallel processing of messages in parallel from 20
threads, you would therefore need a *minimum* of 20 partitions. Any
fewer partitions, and you would be left with consumers that are not
allocated anything to work on, as described in our exclusive-consumer
discussion earlier.

![Two consumers in the same group reading from different partitions](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492049296/files/assets/umbk_0306.png)

###### Figure 3-6. Two consumers in the same group reading from different partitions

This scheme greatly reduces the complexity of a Kafka broker’s work as
compared with the message distribution required to support a JMS queue.
There is no bookkeeping of:

-

Which consumer should get the next message based on round-robin
distribution, the current capacity of prefetch buffers, or
previous messages (as per-JMS message groups).

-

Which messages have gone to which consumers and need to be
redelivered in the event of failure.

All that a Kafka broker has to do is sequentially feed messages to a
consumer as the latter asks for them.

However, the requirements for parallelizing consumption and replaying
failed messages do not go away—the responsibility for them is simply
transferred from the broker to the client. This means that they need to
be considered within your code.

# Sending Messages

The responsibility for deciding which partition to send a message to is
assigned to the producer of that message. To understand the mechanism by
which this is done, we first need to consider what it is that we are
actually sending.

While in JMS, we make use of a message construct with metadata (headers
and properties) and a body containing the payload; in Kafka the message
is a *key-value pair*. The payload of the message is sent as the value.
The key, on the other hand, is used primarily for partitioning purposes
and should contain a *business-specific key* in order to place related
messages on the same partition.

In [Chapter 2](https://learning.oreilly.com/library/view/understanding-message-brokers/9781492049296/ch02.html#activemq) we discussed a use case from online betting
where related events need to be processed in order by a single consumer:

1.

A user account is set up.

1.

Money is deposited into the account.

1.

A bet is placed that withdraws money from the account.

If each event is a message sent to a topic, then the natural key in this
case would be the account ID.

When a message is sent using the Kafka Producer API, it is handed to a
partitioning function that, given the message and the current state of
the Kafka cluster, returns a partition ID to which the message should be
sent. This function is implemented through the `Partitioner`
interface in Java.

This interface looks as follows:

```
interface Partitioner {
    int partition(String topic,
            Object key,   byte[] keyBytes,
            Object value, byte[] valueBytes,
            Cluster cluster);
}
```

The default implementation of the Partitioner uses a general-purpose
hashing algorithm over the key, or round-robin if no key is provided, to
determine the partition. This default works well in the majority of
cases. There will, however, be times when you want to write your own.

## Writing Your Own Partitioning Strategy

Let’s consider an example where you want to send metadata along with a
message payload. The payload is an instruction to perform a deposit into
a betting account. A deposit instruction is something that we would like
to ensure is not modified in transit, and want the confidence that only
trusted upstream systems can initiate the instruction. In such a case,
the sending and receiving systems agree to use a signature to verify the
authenticity of the message.

In regular JMS, we would simply define a `signature` message property
and append it to the message. However, Kafka does not provide us with a
mechanism to transmit metadata—only a key and a value.

Since the value is the bank transfer payload whose integrity we want to
preserve, we are left with no alternative other than defining a data
structure for use within the key. Assuming that we need an account ID
for partitioning, as all messages relating to an account must be
processed in order, we come up with the following JSON structure:

```json
{
    "signature": "541661622185851c248b41bf0cea7ad0",
    "accountId": "10007865234"
}
```

As the `signature` value is going to vary on a per-payload basis, the
default hashing `Partitioner` strategy is not going to reliably group
related messages. We would therefore need to write our own strategy that
will parse this key and partition on the `accountId` value.

###### Note

Kafka includes checksums to detect corruption of messages in
storage and has a comprehensive set of security features. Even so,
industry-specific requirements such as the one above do occasionally
appear.

A custom partitioning strategy needs to ensure that all related messages
end up in the same partition. While this seems straightforward, the
requirement may be complicated by the importance of the ordering of
related messages and how fixed the number of partitions in a topic is.

The number of partitions in a topic can change over time, as they can be
added to if the traffic goes beyond what was initially expected. As
such, message keys may need to be associated with the partition that
they were initially sent to, implying a piece of state that needs to be
shared across producer instances.

Another factor to consider is the evenness of the distribution of
messages among partitions. Typically, keys are not evenly distributed
across messages, and hash functions are not guaranteed to distribute
messages fairly for a small set of keys.

It is important to note that however you decide to partition the
messages, the partitioner itself may need to be reused.

Consider the requirement to replicate data between Kafka clusters in
different geographical locations. Kafka comes with a standalone
command-line tool called MirrorMaker for this purpose, used to
consume messages from one cluster and produce them into another.

MirrorMaker needs to understand the keys of the topic being replicated
in order to maintain relative ordering between messages as it replicates
between clusters, as the number of partitions for that topic may not be
the same in the two clusters.

Custom partitioning strategies are relatively rare, as the defaults of
hashing or round-robin work for the majority of use cases. If, however,
you require strong ordering guarantees or need to move metadata outside
of payloads, then partitioning is something that you will need to
consider in closer detail.

Kafka’s scalability and performance benefits come from moving some of
the responsibilities of a traditional broker onto the client. In this
case, the decision around distribution of potentially related messages
to multiple consumers running in parallel.

###### Note

JMS-based brokers also need to deal with these sorts of
requirements. Interestingly, the mechanism of sending related messages
to the same consumer—implemented via JMS Message Groups, a form of
sticky load-balancing—also requires the sender to mark messages as
related. In the JMS case, the broker is responsible for sending that
group of related messages to a single consumer out of many, and
transferring the ownership of the group if the consumer goes down.

# Producer Considerations

Partitioning is not the only thing that needs to be considered when
sending messages. Let us consider the `send()` methods on the `Producer`
class in the Java API:

```
Future<RecordMetadata> send(ProducerRecord<K,V> record);
Future<RecordMetadata> send(ProducerRecord<K,V> record,
                            Callback callback);
```

The immediate thing to note is that both methods return a `Future`,
which indicates that the send operation is not performed immediately.
What happens is that the message (`ProducerRecord`) is written into a
send buffer for each active partition and transmitted on to the broker
by a background thread within the Kafka client library. While this makes
the operation incredibly fast, it does mean that a naively written
application could lose messages if its process goes down.

As always there is a way of making the sending operation more reliable
at the cost of performance. The size of this buffer can be tuned to be
0, and the sending application thread can be forced to wait until the
transmission of the message to the broker has been completed, as
follows:

```
RecordMetadata metadata = producer.send(record).get();
```

# Consumption Revisited

The consumption of messages has additional complexities that need to be
reasoned about. Unlike the JMS API, which can trigger a message listener
in reaction to the arrival of a message, Kafka’s `Consumer` interface is
polling only. Let’s take a closer look at the `poll()` method used for
this purpose:

```
ConsumerRecords<K,V> poll(long timeout);
```

The method’s return value is a container structure containing multiple
`ConsumerRecord` objects from potentially multiple partitions. The
`ConsumerRecord` itself is a holder object for a key-value pair, with
associated metadata such as which partition it came from.

As discussed in [Chapter 2](https://learning.oreilly.com/library/view/understanding-message-brokers/9781492049296/ch02.html#activemq), we need to constantly keep in mind
what happens to messages once they are either successfully processed or
not, such as if the client is unable to process a message or if it
terminates. In JMS, this was handled through the acknowledgement mode.
The broker would either delete a successfully processed message or
redeliver an unprocessed or failed one (assuming transactions were in
play). Kafka works quite differently. Messages are not deleted on the
broker once consumed, and the responsibility for working out what
happens on failure lies with the consuming code itself.

As we have discussed, a consumer group is associated with an offset in
the log. The position in the log associated with that offset corresponds
to the next message to be handed out in response to a `poll()`. What is
critical in consumption is the timing around when that offset is
incremented.

Going back to the consumption model discussed earlier, the processing of
a message has three phases:

1.

Fetch a message for consumption.

1.

Process the message.

1.

Acknowledge the message.

The Kafka consumer comes with the configuration option
`enable.auto.commit`. This is a commonly used default setting, as is
usually the case with settings containing the word “auto.”

Before Kafka 0.10, a client using this setting would send the offset of
the last consumed message on the next `poll()` after processing. This
meant that any messages that were fetched ran the possibility of being
reprocessed if the client processed the messages, but terminated
unexpectedly before calling `poll()`. As the broker does not keep any
state around how many times a message is consumed, the next consumer to
fetch that same message would have no idea that anything untoward had
happened. This behavior was pseudo-transactional; an offset was
committed only if the message processing was successful, but if the
client terminated, the broker would send the same message again to
another client. This behavior corresponded an *at-least-once* message
delivery guarantee.

In Kafka 0.10, the client code was changed so that the commit became
something that the client library would trigger periodically, as defined
by the `auto.commit.interval.ms` setting. This behavior sits somewhere
between the JMS `AUTO_ACKNOWLEDGE` and `DUPS_OK_ACKNOWLEDGE` modes. When
using auto commit, messages could be acknowledged regardless of whether
they were actually processed—this might occur in the instance of a
slow consumer. If the consumer terminated, messages would be fetched by
the next consumer from the committed position, leading to the possibility
of missing messages. In this instance, Kafka didn’t lose messages, the
consuming code just didn’t process them.

This mode also has the same potential as in 0.9: messages may have been
processed, but in the event of failure, the offset may not have been
committed, leading to potential duplicate delivery. The more messages
you retrieve during a `poll()`, the greater this problem is.

As discussed in [“Consuming Messages from a Queue”](https://learning.oreilly.com/library/view/understanding-message-brokers/9781492049296/ch02.html#consuming-messages-from-a-queue), there is no such thing
as once-only message delivery in a messaging system once you take
failure modes into account.

In Kafka, there are two ways to commit the offset: automatically, and
manually. In both cases, you may process the messages multiple times if
you have processed the message but failed before commiting. You may also
not process the message at all if the commit happened in the background
and your code terminated before it got around to processing (a
possibility in Kafka 0.9 and earlier).

Controlling the offset commit process manually is enabled in the Kafka
consumer API by setting the `enable.auto.commit` to `false`, and calling
one of the following methods explicitly:

```
void commitSync();
void commitAsync();
```

If you care about at-least-once processing, you would commit the offset
manually via `commitSync()`, executed immediately after your processing
of messages.

These methods prevent messages from being acknowledged before being
processed, but do nothing to address the potential for duplicate
processing, while at the same time giving the impression of
transactionality. Kafka is nontransactional. There is no way for a
client to:

-

Roll back a failed message automatically. Consumers must deal with
exceptions thrown due to bad payloads and backend outages themselves, as
they cannot rely on the broker redelivering messages.

-

Send messages to multiple topics within the same atomic operation. As
we will soon see, control of different topics and partitions may lie
with many different machines in a Kafka cluster that do not coordinate
transactions on sending. There is some work going on at the time of
writing to enable this via
[KIP-98](https://cwiki.apache.org/confluence/display/KAFKA/KIP-98+-+Exactly+Once+Delivery+and+Transactional+Messaging).

-

Tie the consumption of a message from one topic to the sending of
another message on another topic. Again, Kafka’s architecture depends on
many independent machines working as a single bus, and no attempt is
made to hide this. For instance, there is no API construct that would
enable the tying together of a `Consumer` and `Producer` in a
transaction; in JMS this is mediated by the `Session` from which
`MessageProducer`s and `MessageConsumer`s are created.

So if we cannot rely on transactions, how do we ensure semantics closer
to those provided by a traditional messaging system?

If there is a possibility that the consumer’s offset is incremented
before the message has been processed, such as during a consumer crash,
then there is no way for a consumer to know if its consumer group has
missed messages when it is assigned a partition. As such, one strategy
is to rewind the offset to a previous position. The Kafka Consumer API
provides the following methods to enable this:

```
void seek(TopicPartition partition, long offset);
void seekToBeginning(Collection<TopicPartition> partitions);
```

The `seek()` method can be used with the `offsetsForTimes​(Map<TopicPartition,Long> timestampsToSearch)` method to
rewind to a state at some specific point in the past.

Implicity, using this approach means that it is highly likely that some
messages that were previously processed will be consumed and processed
all over again. To get around this we can use idempotent consumption, as
described in [Chapter 4](https://learning.oreilly.com/library/view/understanding-message-brokers/9781492049296/ch04.html#messaging-considerations-and-patterns), to keep track of previously seen messages
and discard duplicates.

Alternatively, your consumer code can be simple where some
message loss or duplication is acceptable. When we consider the sorts of
use cases that Kafka is typically used for, namely movement of log
events, metrics, tracking clicks, and so on, we find that the loss of
individual messages is not likely to have a meaningful impact on the
surrounding applications. In such cases, defaults may be perfectly
acceptable. On the other hand, if your application needs to transmit
payments, you may care deeply about each individual message. It all
comes down to context.

As a personal observation, as the rate of messages rises, the less
valuable any individual message is going to be. For high-volume
messages, their value typically lies in considering them in an aggregate
form.

# High Availability

Kafka’s approach to high availability is significantly different from
that of ActiveMQ. Kafka is designed around horizontally scalable
clusters in which all broker instances accept and distribute messages at
the same time.

A Kafka cluster is made up of multiple broker instances running on
separate servers. Kafka has been designed to run on commodity standalone
hardware, with each node having its own dedicated storage. The use of
storage area networks (SANs) is discouraged as many compute nodes may
compete for time slices of the storage and create contention.

Kafka is an *always-on* system. A lot of large Kafka users never take
their clusters down, and the software always provides an upgrade path
via a rolling restart. This is managed by guaranteeing compatibility
with the previous version for messages and inter-broker communication.

Brokers are connected to a cluster of
[ZooKeeper](http://zookeeper.apache.org/) servers which acts as a registry
of configuration information and is used to coordinate the roles of
each broker. ZooKeeper is itself a distributed system, that provides
high availability through replication of information in a *quorum*
setup.

At its most basic, a topic is created on the Kafka cluster with the
following properties:

-

Number of partitions. As discussed earlier, the exact value used here
depends upon the desired degree of parallel consumption.

-

Replication factor. This defines how many broker instances in the
cluster should contain the logs for this partition.

Using ZooKeepers for coordination, Kafka attempts to fairly distribute
new partitions among the brokers in the cluster. This is performed by
one instance that serves the role of a Controller.

At runtime, *for each topic partition*, the Controller assigns the roles
of a *leader* (master) and *followers* (slaves) to the brokers. The
broker acting as leader for a given partition is responsible for
accepting all messages sent to it by producers, and distributing
messages to consumers. As messages are sent into a topic partition, they
are replicated to all broker nodes acting as followers for that
partition. Each node that contains the logs for the partition is refered
to as a *replica*. A broker may act as a leader for some partitions and
as a follower for others.

A follower that contains all of the messages held by the leader is
referred to as being an *in-sync replica*. Should the broker acting as
leader for a partition go offline, any broker that is up-to-date or
in-sync for that partition may take over as leader. This is an
incredibly resilient design.

Part of the producer’s configuration is an `acks` setting, which will
dictate how long many replicas must acknowledge receipt of the message
before the application thread continues when it is sent: `0`, `1`, or
`all`. If set to `all`, on receipt of a message, the leader will send
confirmation back to the producer once it has received acknowledgements
of the write from a number of replicas (including itself), defined by the
topic’s `min.insync.replicas` setting (`1` by default). If a message
cannot be successfully replicated, then the producer will raise an
exception to the application (`NotEnoughReplicas` or
`NotEnoughReplicasAfterAppend`).

A typical configuration is to create a topic with a replication factor
of 3 (1 leader, 2 followers for each partition) and set
`min.insync.replicas` to 2. That way the cluster will tolerate one of
the brokers managing a topic partition going offline with no impact on
client applications.

This brings us back to the now-familiar performance versus reliability
trade-off. Replication comes at the cost of additional time waiting for
acknowledgments from followers; although as it is performed in parallel,
replication to a minimum of three nodes has similar performance as that of two
(ignoring the increased network bandwidth usage).

Using this replication scheme, Kafka cleverly avoids the need to ensure
that every message is physically written to disk via a `sync()`
operation. Each message sent by a producer will be written to the
partition’s log, but as discussed in [Chapter 2](https://learning.oreilly.com/library/view/understanding-message-brokers/9781492049296/ch02.html#activemq), a write to a
file is initially performed into an operating system buffer. If that
message is replicated to another Kafka instance and resides in its
memory, loss of the leader does not mean that the message itself was
lost—the in-sync replica can take over.

Avoiding the need to `sync()` means that Kafka can accept messages at
the rate at which it can write into memory. Conversely, the longer it
can avoid flushing its memory to disk, the better. For this reason it is
not unusual to see Kafka brokers assigned 64 GB of memory or more. This
use of memory means that a single Kafka instance can easily operate at
speeds many thousands of times faster than a traditional message broker.

Kafka can also be configured to `sync()` batches of messages. As
everything in Kafka is geared around batching, this actually performs
quite well for many use cases and is a useful tool for users that
require very strong guarantees. Much of Kafka’s raw performance comes
from messages that are sent to the broker as batches, and from having
those messages read from the broker in sequential blocks via
[zero-copy](http://www.linuxjournal.com/article/6345). The latter is a big
win from a performance and resource perspective, and is only possible due
to the use of the underlying journal data structure, which is laid out
per partition.

Much higher performance is possible across a Kafka cluster than through
the use of a single Kafka broker, as a topic’s partitions may be
horizontally scaled over many separate machines.

# Summary

In this chapter we looked at how Kafka’s architecture reimagines the
relationship between clients and brokers to provide an incredibly
resilient messaging pipeline with many times greater throughput than a
regular message broker. We discussed the functionality that it trades
off to achieve this, and examined in brief the application architectures
that it enables. In the next chapter we will look at common concerns
that messaging-based applications need to deal with and discuss
strategies for addressing them. We will complete the chapter by
outlining how to reason about messaging technologies in general so
that you can evaluate their suitability to your use cases.
