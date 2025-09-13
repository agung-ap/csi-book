# Chapter 2. ActiveMQ

ActiveMQ is best described as a classical messaging system. It was
written in 2004, filling a need for an open source message broker. At
the time if you wanted to use messaging within your applications, the
only choices were expensive commercial products.

ActiveMQ was designed to implement the Java Message Service (JMS)
specification. This decision was made in order to fill the requirement
for a JMS-compliant messaging implementation in the Apache Geronimo
project—an open source J2EE application server.

A messaging system (or message-oriented middleware, as it is sometimes
called) that implements the JMS specification is composed of the
following constructs:

BrokerThe centralized piece of middleware that distributes messages.

ClientA piece of software that exchanges messages using a
broker. This in turn is made up of the following artifacts:

-

Your code, which uses the JMS API.

-

The JMS API—a set of interfaces for interacting with the broker
according to guarantees laid out in the JMS specification.

-

The system’s client library, which provides the implementation of the
API and communicates with the broker.

The client and broker communicate with each other through an application
layer protocol, also known as a *wire protocol* ([Figure 2-1](https://learning.oreilly.com/library/view/understanding-message-brokers/9781492049296/ch02.html#jms_overview)). The JMS specification
left the details of this protocol up to individual implementations.

![JMS overview](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492049296/files/assets/umbk_0201.png)

###### Figure 2-1. JMS overview

JMS uses the term *provider* to describe the vendor’s implementation of
the messaging system underlying the JMS API, which comprises the
broker as well as its client libraries.

The choice to implement JMS had far-reaching consequences on the
implementation decisions taken by the authors of ActiveMQ. The
specification itself set out clear guidelines about the responsibilities
of a messaging client and the broker that it communicates with,
favoring to place obligation for the distribution and delivery of
messages on the broker. The client’s primary obligation is to interact
with the destination (queue or topic) of the messages it sends. The
specification itself focused on making the API interaction with the
broker relatively simple.

This direction impacted heavily on the performance of ActiveMQ, as we
will see later on. Adding to the complexities of the broker, the
compatibility suite for the specification provided by Sun Microsystems
had numerous corner cases, with their own performance impacts, that all
had to be fulfilled in order for ActiveMQ to be considered
JMS-compliant.

# Connectivity

While the API and expected behavior were well defined by JMS, the
actual protocol for communication between the client and the broker was
deliberately left out of the JMS specification, so that existing brokers
could be made JMS-compatible. As such, ActiveMQ was free to define its
own wire protocol—OpenWire. OpenWire is used by the ActiveMQ JMS
client library implementation, as well as its .Net and C++ counterparts—NMS and CMS—which are sub-projects of ActiveMQ, hosted at the Apache
Software Foundation.

Over time, support for other wire protocols was added into ActiveMQ,
which increased its interoperability options from other languages and
environments:

AMQP 1.0The Advanced Message Queuing Protocol (ISO/IEC 19464:2014) should not be confused with its 0.X predecessors, which are
implemented in other messaging systems, in particular within RabbitMQ,
which uses 0.9.1. AMQP 1.0 is a general purpose binary protocol for the
exchange of messages between two peers. It does not have the notion of
clients or brokers, and includes features such as flow control,
transactions, and various qualities of service (at-most-once,
at-least-once, and exactly-once).

STOMPSimple/Streaming Text Oriented Messaging Protocol, an
easy-to-implement protocol that has dozens of client implementations
across various languages.

XMPPExtensible Messaging and Presence Protocol. Originally called
Jabber, this XML-based protocol was originally designed for chat
systems, but has been extended beyond its initial use cases to include
publish-subscribe messaging.

MQTTA lightweight, publish-subscribe protocol (ISO/IEC 20922:2016)
used for Machine-to-Machine (M2M) and Internet of Things (IoT)
applications.

ActiveMQ also supports the layering of the above protocols over
WebSockets, which enables full duplex communication between applications
in a web browser and destinations in the broker.

With this in mind, these days when we talk about ActiveMQ, we no longer
refer exclusively to a communications stack based on the JMS/NMS/CMS
libraries and the OpenWire protocol. It is becoming quite common to
mix and match languages, platforms, and external libraries that are best
suited to the application at hand. It is possible, for example, to have a
JavaScript application running in a browser using the
[Eclipse Paho](http://www.eclipse.org/paho/) MQTT library to send messages
to ActiveMQ over Websockets, and have those messages consumed by a C++
server process that uses AMQP via the
[Apache Qpid Proton](http://qpid.apache.org/proton/index.html) library.
From this perspective, the messaging landscape is becoming much more
diverse.

Looking to the future, AMQP in particular is going to feature much more
heavily than it has to date as components that are neither clients nor
brokers become a more familiar part of the messaging landscape. The
[Apache Qpid
Dispatch Router](http://qpid.apache.org/components/dispatch-router/index.html), for example, acts as a message router that clients
connect to directly, allowing different destinations to be handled by
distinct brokers, as well as providing a sharding facility.

When dealing with third-party libraries and external components, you need
to be aware that they are of variable quality and may not be compatible
with the features provided within ActiveMQ. As a very simple example, it
is not possible to send messages to a queue via MQTT (without a bit of
routing configured within the broker). As such, you will need to spend
some time working through the options to determine the messaging stack
most appropriate for your application requirements.

# The Performance-Reliability Trade-off

Before we dive into the details of how point-to-point messaging in
ActiveMQ works, we need to talk a bit about something that all
data-intensive systems need to deal with: the trade-off between
performance and reliability.

Any system that accepts data, be it a message broker or a database,
needs to be instructed about how that data should be handled if the system fails. Failure can take many forms, but for the
sake of simplicity, we will narrow it down to a situation where the
system loses power and immediately shuts down. In a situation such as
this, we need to reason about what happened to the data that the system
had. If the data (in this case, messages) was in memory
or a volatile piece of hardware, such as a cache, then that data will be
lost. However, if the data had been sent to nonvolatile storage, such
as a disk, then it will once again be accessible when the system is
brought back online.

From that perspective, it makes sense that if we do not want to lose
messages if a broker goes down, then we need to write them to persistent
storage. The cost of this particular decision is unfortunately quite
high.

Consider that the difference between writing a megabyte of data to disk
is between 100 to 1000 times slower than writing it to memory. As such,
it is up to the application developer to make a decision as to whether
the price of message reliability is worth the associated performance
cost. Decisions such as these need to be made on a use case basis.

The performance-reliability trade-off is based on a spectrum of choices.
The higher the reliability, the lower the performance. If you decide to
make the system less reliable, say by keeping messages in memory only,
your performance will increase significantly. The JMS defaults that
ActiveMQ comes tuned with out of the box favor reliability. There are
numerous mechanisms that allow you to tune the broker, and your
interaction with it, to the position on this spectrum that best
addresses your particular messaging use cases.

This trade-off applies at the level of individual brokers. However an
individual broker is tuned, it is possible to scale messaging beyond
this point through careful consideration of message flows and
separation of traffic out over multiple brokers. This can be achieved by
giving certain destinations their own brokers, or by partitioning the
overall stream of messages either at the application level or through
the use of an intermediary component. We will look more closely at how
to consider broker topologies later on.

# Message Persistence

ActiveMQ comes with a number of pluggable strategies for persisting
messages. These take the form of persistence adapters, which can be
thought of as engines for the storage of messages. These include
disk-based options such as KahaDB and LevelDB, as well as the
possibility of using a database via JDBC. As the former are most
commonly used, we will focus our discussion on those.

When persistent messages are received by a broker, they are first written
to disk into a *journal*. A journal is an append-only disk-based data
structure made up of multiple files. Incoming messages are serialized
into a protocol-independent object representation by the broker and are
then marshaled into a binary form, which is then written to the end of
the journal. The journal contains a log of all incoming messages, as
well as details of those messages that have been acknowledged as
consumed by the client.

Disk-based persistence adapters maintain index files which keep track
of where the next messages to be dispatched are positioned within the
journal. When all of the messages from a journal file have been
consumed, it will either be deleted or archived by a background worker
thread within ActiveMQ. If this journal is corrupted during a broker
failure, then ActiveMQ will rebuild it based on the information within
the journal files.

Messages from all queues are written in the same journal files, which
means that if a single message is unconsumed, the entire file (usually
either 32 MB or 100 MB in size by default, depending on the persistence
adapter) cannot be cleaned up. This can cause problems with running out
of disk space over time.

###### Warning

Classical message brokers are not intended as a long-term
storage mechanism—consume your messages!

Journals are an extremely efficient mechanism for the storage and
subsequent retrieval of messages, as the disk access for both operations
is sequential. On conventional hard drives this minimizes the amount of
disk seek activity across cylinders, as the heads on a disk simply keep
reading or writing over the sectors on the spinning disk platter.
Likewise on SSDs, sequential access is much faster than random access, as
the former makes better use of the drive’s memory pages.

# Disk Performance Factors

There are a number of factors that will determine the speed at which a
disk can operate. To understand these, let us consider the way that we
write to disk through a simplified mental model of a pipe ([Figure 2-2](https://learning.oreilly.com/library/view/understanding-message-brokers/9781492049296/ch02.html#pipe_model)).

![Pipe model of disk performance](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492049296/files/assets/umbk_0202.png)

###### Figure 2-2. Pipe model of disk performance

A pipe has three dimensions:

LengthThis corresponds with the *latency* that is expected for a
single operation to complete. On most local disks this is pretty good,
but can become a major limiting factor in cloud environments where the
local disk is actually across a network. For example, at the time of
writing (April 2017) Amazon guarantees that writes to their EBS storage
devices will be performed in “under 2 ms.” If we are performing writes
sequentially, then this gives a maximum throughput limit of 500 writes
per second.

WidthThis will dictate the carrying capacity or *bandwidth* of a
single operation. Filesystem caches exploit this property by combining
many small writes into a smaller set of larger write operations
performed against the disk.

The carrying capacity over a period of timeThis idea, visualized as the number of things that can be in the pipe at the same time, is expressed by a metric called *IOPS* (input/output operations per second). IOPS is commonly used by storage manufacturers
and cloud providers as a performance measurement. A hard disk will have
different IOPS values in different contexts: whether the workload is
mostly made up of reads, writes, or a combination of the two; and whether
those operations are sequential, random-access, or mixed. The IOPS
measurements that are most interesting from a broker perspective are
sequential reads and writes, as these correspond to reading and writing
journal logs.

The maximum throughput of a message broker will be defined by *the first
of these limits to be hit*, and the tuning of a broker largely
depends on how the interaction with the disks is performed. This is not
just a factor of how the broker is configured, for instance, but also
depends on how the producers are interacting with the broker. As with
anything performance-related, it is necessary to test the broker under a
representative workload (i.e., as close to real messages as possible)
and on the actual storage setup that will be used in production. This is
done in order to get an understanding of how the system will behave
in reality.

# The JMS API

Before we go into the details of how ActiveMQ exchanges messages with
clients, we first need to examine the JMS API. The API defines a set of
programming interfaces used by client code:

ConnectionFactoryThis is the top-level interface used for
establishing connections with a broker. In a typical messaging
application, there exists a single instance of this interface. In
ActiveMQ this is the `ActiveMQConnectionFactory`. At a high level, this
construct is instructed with the location of the message broker, as well
as the low-level details of how it should communicate with it. As
implied by the name, a `ConnectionFactory` is the mechanism by which
`Connection` objects are created.

ConnectionThis is a long lived object that is roughly analogous
to a TCP connection—once established, it typically lives for the
lifetime of the application until it is shut down. A connection is
thread-safe and can be worked with by multiple threads at the same
time. `Connection` objects allow you to create `Session` objects.

SessionThis is a thread’s handle on communication with a broker.
Sessions are not thread-safe, which means that they cannot be accessed
by multiple threads at the same time. A `Session` is the main
transactional handle through which the programmer may commit and roll
back messaging operations, if it is running in transacted mode. Using
this object, you create `Message`, `MessageConsumer`, and
`MessageProducer` objects, as well as get handles on `Topic` and `Queue`
objects.

MessageProducerThis interface allows you to send a message to a
destination.

MessageConsumerThis interface allows the developer to receive
messages. There are two mechanisms for retrieving a message:

-

Registering a `MessageListener`. This is a message handler interface implemented by you that will sequentially process any messages
pushed by the broker using a single thread.

-

Polling for messages using the `receive()` method.

MessageThis is probably the most important construct as it is
the one that carries your data. Messages in JMS are composed of two
aspects:

-

Metadata about the message. A message contains headers and
properties. Both of these can be thought of as entries in a map. Headers
are well-known entries, specified by the JMS specification and
accessible directly via the API, such as `JMSDestination` and
`JMSTimestamp`. Properties are arbitrary pieces of information about the
message that you set to simplify message
processing or routing, without the need to read the message payload
itself. You may, for instance, set an `AccountID` or `OrderType` header.

-

The body of the message. A number of different message
types can be created from a `Session`, based on the type of content
that will be sent in the body, the most common being
`TextMessage` for strings and `BytesMessage` for binary data.

# How Queues Work: A Tale of Two Brains

A useful, though imprecise, model of how ActiveMQ works is that of two
halves of a brain. One part is responsible for accepting messages from
producers, and the other dispatches those messages to consumers. In
reality, the relationship is much more complex for performance
optimization purposes, but the model is adequate for a basic
understanding.

## Producing Messages into a Queue

Let’s consider the interaction that occurs when a message is sent. [Figure 2-3](https://learning.oreilly.com/library/view/understanding-message-brokers/9781492049296/ch02.html#producing_messages_to_jms) shows us a simplified model of the process by which
messages are accepted by the broker; it does not match perfectly to the
behavior in every case, but is good enough to get a baseline
understanding.

![Producing messages to JMS](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492049296/files/assets/umbk_0203.png)

###### Figure 2-3. Producing messages to JMS

Within the client application, a thread has gotten a handle on a
`MessageProducer`. It has created a `Message` with the intended message
payload and invokes `MessageProducer.send("orders",` `message)`, with the
target destination of the message being a queue. As the programmer did
not want to lose the message if the broker went down, the
`JMSDeliveryMode` header of the message was set to `PERSISTENT` (the
default behavior).

At this point (1) the sending thread calls into the client library and
marshals the message into OpenWire format. The message is then sent over
to the broker.

Within the broker, a receiving thread accepts the message off the wire
and unmarshals it into an internal object representation. The message
object is then passed to the persistence adapter, which marshals the
message using the Google Protocol Buffers format and writes it to
storage (2).

Once the message has been written to storage, the persistence adapter
needs to get a confirmation that the message has actually been written
(3). This is typically the slowest part of the entire interaction; more
on this later.

Once the broker is satisfied that the message has been stored, it
responds with an acknowledgement back to the client (4). The client
thread that originally invoked the `send()` operation is then free to
continue performing its processing.

This waiting for acknowledgement of persistent messages is fundamental
to the guarantee that the JMS API provides—if you want the message to
be persisted, you presumably also care about whether the message was
accepted by the broker in the first place. There are a number of reasons
why this might not be possible, for instance, a memory or storage limit
being reached. Instead of crashing, the broker will either pause the
send operation, causing the producer to wait until there are enough
system resources to process the message (a process called Producer Flow
Control), or it will send a negative acknowledgement back to the
producer, triggering an exception to be thrown. The exact behavior is
configurable on a per-broker basis.

There is a substantial amount of I/O interaction happening in this
simple operation, with two network operations between the producer and
the broker, one storage operation, and a confirmation step. The storage
operation could be a simple disk write or another network hop to a
storage server.

This raises an important point about message brokers: they are
extremely I/O intensive and very sensitive to the underlying
infrastructure, in particular, disks.

Let’s take a closer look at the confirmation step (3) in the above
interaction. If the persistence adapter is file based, then storing a
message involves a write to the filesystem. If this is the case, then
why would we need a confirmation that a write has been completed? Surely
the act of completing a write means that a write has occurred?

Not quite. As tends to be the case with these things, the closer you
look at a something, the more complex it turns out to be. The culprit in
this particular case is *caches*.

# Caches, Caches Everywhere

When an operating system process, such as a broker, writes to disk, it
interacts with the filesystem. The filesystem is a process that
abstracts away the details of interacting with the underlying storage
medium by providing an API for file operations, such as `OPEN`, `CLOSE`,
`READ`, and `WRITE`. One of those functions is to *minimize the amount of
writes* by buffering data written to it by operating system processes
into blocks that can be written out to disk at the same time. Filesystem writes, which seem to interact with disks, are actually written to
this *buffer cache*.

Incidentally, this is why your computer complains when you remove a USB
stick without safely ejecting it—those files you copied may not
actually have been written!

Once data makes it beyond the buffer cache, it hits the next level of
caching, this time at the hardware level—the *disk drive controller
cache*. These are of particular note on RAID-based systems, and serve a
similar function as caching at the operating system level: to minimize
the amount of interactions that are needed with the disks themselves.
These caches fall into two categories:

write-throughWrites are passed to the disk on arrival.

write-backWrites are only performed against the disks once the
buffer has reached a certain threshold.

Data held in these caches can easily be lost when a power failure
occurs, as the memory used by them is typically *volatile*. More
expensive cards have battery backup units (BBUs) which maintain power
to the caches until the overall system can have power restored, at
which point the data is written to disk.

The last level of caches is on the disks themselves. *Disk caches* exist
on hard disks (both standard hard drives and SSDs) and can be
write-through or write-back. Most commercial drives use caches that are
write-back and volatile, again meaning that data can be lost in the
event of a power failure.

Going back to the message broker, the confirmation step is needed to
make sure that the data has actually made it all the way down to the
disk. Unfortunately, it is up to the filesystem to interact with these
hardware buffers, so all that a process such as ActiveMQ can do is to
send the filesystem a signal that it wants all system buffers to
synchronize with the underlying device. This is achieved by the broker
calling `java.io.FileDescriptor.sync()`, which in turn triggers the
`fsync()` POSIX operation.

This syncing behavior is a JMS requirement to ensure that all messages
that are marked as persistent are actually saved to disk, and is
therefore performed after the receipt of each message or set of related
messages in a transaction. As such, the speed with which the disk can
`sync()` is of critical importance to the performance of the broker.

# Internal Contention

The use of a single journal for all queues adds an additional
complication. At any given time, there may be multiple producers all
sending messages. Within the broker, there are multiple threads that
receive these messages from the inbound socket connections. Each
thread needs to persist its message to the journal. As it is not
possible for multiple threads to write to the same file at the same
time because the writes would conflict with each other, the writes need to
be queued up through the use of a mutual exclusion mechanism. We call
this *thread contention*.

Each message must be fully written and synced before the next message
can be processed. This limitation impacts all queues in the broker at
the same. So the performance of how quickly a message can be accepted is
the write time to disk, plus any time waiting on other threads to
complete their writes.

ActiveMQ includes a write buffer into which receiving threads write
their messages while they are waiting for the previous write to
complete. The buffer is then written in one operation the next time the
message is available. Once completed, the threads are then notified. In
this way, the broker maximizes the use of the storage bandwidth.

To minimize the impact of thread contention, it is possible to assign
sets of queues to their own journals through the use of the mKahaDB
adapter. This approach reduces the wait times for writes, as at any one
time threads will likely be writing to different journals and will not
need to compete with each other for exclusive access to any one journal
file.

# Transactions

The advantage of using a single journal for all queues is that from the
broker authors’ perspective it is much simpler to implement
transactions.

Let us consider an example where multiple messages are sent from a
producer to multiple queues. Using a transaction means that the entire
set of sends must be treated as a single atomic operation. In this
interaction, the ActiveMQ client library is able to make some
optimizations which greatly increase send performance.

In the operation shown in [Figure 2-4](https://learning.oreilly.com/library/view/understanding-message-brokers/9781492049296/ch02.html#producing_messages_within_a_transaction), the producer sends three messages, all to different
queues. Instead of the normal interaction with the broker, where each
message is acknowledged, the client sends all three messages asynchronously,
that is, without waiting for a response. These messages are held in
memory by the broker. Once the operation is completed, the producer
tells its session to commit, which in turn causes the broker to perform
a single large write with a single sync operation.

![Producing messages within a transaction](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492049296/files/assets/umbk_0204.png)

###### Figure 2-4. Producing messages within a transaction

This type of operation sees ActiveMQ using two optimizations for a
performance increase:

-

A removal of the wait time before the next send is possible in the
producer

-

Combining many small disk operations into one larger one—this makes
use of the width dimension of our pipe model of disks

If you were to compare this with a situation where each queue was stored
in its own journal, then the broker would need to ensure some form of
transactional coordination between each of the writes.

# Consuming Messages from a Queue

The process of message consumption begins when a consumer expresses a
demand for messages, either by setting up a `MessageListener` to process
messages as they arrive or by making calls to the
`MessageConsumer.receive()` method ([Figure 2-5](https://learning.oreilly.com/library/view/understanding-message-brokers/9781492049296/ch02.html#consuming_messages_via_jms)).

![Consuming messages via JMS](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492049296/files/assets/umbk_0205.png)

###### Figure 2-5. Consuming messages via JMS

When ActiveMQ is aware of a consumer, it pages messages from storage
into memory for distribution (1). These messages are then *dispatched*
to the consumer (2), often in multiples to minimize the amount of
network communication. The broker keeps track of which messages have
been dispatched and to which consumer.

The messages that are received by the consumer are not immediately
processed by the application code, but are placed into an area of memory
known as the *prefetch buffer*. The purpose of this buffer is to even
out message flow so that the broker can feed the consumer messages as
they become available for dispatch, while the consumer can consume them
in an orderly fashion, one at a time.

At some point after arriving in the prefetch buffer, messages are
consumed by the application logic (X), and an acknowledgement of
consumption is sent back to the broker (3). The time ordering between
the processing of the message and its acknowledgement is configurable
through a setting on the JMS Session called the *acknowledgement mode*,
which we will discuss in a little while.

Once a message acknowledgement is received by the broker, the message is
removed from memory and deleted from the message store (4). The term
“deletion” is somewhat misleading, as in reality a record of the
acknowledgement is written into the journal and a pointer within the
index is incremented. The actual deletion of the journal file containing
the message will be garbage collected by a background thread based on
this information.

The behavior described above is a simplification to aid
understanding. In reality, ActiveMQ does not simply page from disk, but
instead uses a cursor mechanism between the receiving part of the broker
and the dispatching part in order to minimize interaction with the
broker’s storage wherever possible. Paging, as described above, is one of
the modes used in this mechanism. Cursors can be viewed as an
application-level cache which needs to be kept synchronized with the
broker’s storage. The coherency protocol involved is a large part of
what makes ActiveMQ’s dispatching mechanism much more complex than that
of Kafka, which is described in the next chapter.

## Acknowledgement Modes and Transactions

The various acknowledgement modes that specify the order between
consumption and acknowledgement have a substantial impact on what logic
needs to be implemented in the client. They are as follows:

AUTO_ACKNOWLEDGEThis is the most commonly used mode, probably
because it has the word `AUTO` in it. This mode causes the client
library to acknowledge the message *at the same time* as the message is
consumed via a call to `receive()`. This means that if the business
logic triggered by the message throws an exception, the message is lost,
as it has already been deleted on the broker. If message consumption is
via a listener, then the message will only be acknowledged when the
listener is successfully completed.

CLIENT_ACKNOWLEDGEAn acknowledgement will only be sent when the
consumer code calls the `Message.acknowledge()` method explicitly.

DUPS_OK_ACKNOWLEDGEHere, acknowledgements will be buffered up in
the consumer before all being sent at the same time to reduce the amount
of network traffic. However, should the client system shut down, then
the acknowledgements will be lost and the messages will be
re-dispatched and processed a second time. The code must therefore deal
with the likelihood of duplicate messages.

Acknowledgement modes are supplemented by a transactional consumption
facility. When a `Session` is created, it may be flagged as being
transacted. This means that it is up to the programmer to explicitly
call `Session.commit()` or `Session.rollback()`. On the consumption
side, transactions expand the range of interactions that the code can
perform as a single atomic operation. For example, it is possible to
consume and process multiple messages as a single unit, or to consume a
message from one queue and then send to another queue using the same
`Session`.

## Dispatch and Multiple Consumers

So far we have discussed the behavior of message consumption with a
single consumer. Let’s now consider how this model applies to multiple
consumers.

When more than one consumer subscribes to a queue, the default
behavior of the broker is to dispatch messages in a round-robin fashion
to consumers that have space in their prefetch buffers. The messages
will be dispatched in the order that they arrived on the queue—this is
the only first in, first out (FIFO) guarantee provided.

When a consumer shuts down unexpectedly, any messages that had been
dispatched to it but had not yet been acknowledged will be re-dispatched
to another available consumer.

This raises an important point: even where consumer transactions are
being used, there is no guarantee that a message will not be processed
multiple times.

Consider the following processing logic within a consumer:

1.

A message is consumed from a queue; a transaction starts.

1.

A web service is invoked with the contents of the message.

1.

The transaction is committed; an acknowledgement is sent to the
broker.

If the client terminates between step 2 and step 3, then the
consumption of the message has already affected some other system
through the web service call. Web service calls are HTTP requests, and
as such are not transactional.

This behavior is true of all queueing systems—even when
transactional, they cannot guarantee that the processing of their
messages will not be free of side effects. Having looked at the
processing of messages in details, we can safely say that:

*There is no such thing as
[exactly-once
message delivery](http://bravenewgeek.com/you-cannot-have-exactly-once-delivery/).*

Queues provide an *at-least-once* delivery guarantee, and sensitive
pieces of code should always consider the possibility of receiving
duplicate messages. Later on we will discuss how a messaging client can
apply idempotent consumption to keep track of previously seen messages
and discard duplicates.

## Message Ordering

Given a set of messages that arrive in the order `[A, B, C, D]`, and two
consumers `C1` and `C2`, the normal distribution of messages will be as
follows:

```
C1: [A, C]
C2: [B, D]
```

Since the broker has no control over the performance of consumer
processes, and since the order of processing is concurrent, it is
non-deterministic. If `C1` is slower than `C2`, the original set of
messages could be processed as `[B, D, A, C]`.

This behavior can be surprising to newcomers, who expect that messages
will be processed in order, and who design their messaging application
on this basis. The requirement for messages that were sent by the same
sender to be processed in order relative to each other, also known as
*causal ordering* is quite common.

Take as an example the following use case taken from online betting:

1.

A user account is set up.

1.

Money is deposited into the account.

1.

A bet is placed that withdraws money from the account.

It makes sense, therefore, that the messages must be processed in the
order that they were sent for the overall account state to make sense.
Strange things could happen if the system tried to remove money from an
account that had no funds. There are, of course, ways to get
around this.

The *exclusive consumer* model involves dispatching all messages from a
queue to a single consumer. Using this approach, when multiple
application instances or threads connect to a queue, they subscribe with
a specific destination option: `my.queue?consumer.exclusive=true`. When
an exclusive consumer is connected, it receives all of the messages.
When a second consumer connects, it receives no messages until the first
one disconnects. This second consumer is effectively a warm-standby,
while the first consumer will now receive messages in the exact same
order as they were written to the journal—in causal order.

The downside of this approach is that while the processing of messages
is sequential, it is a performance bottleneck as all messages must be
processed by a single consumer.

To address this type of use case in a more intelligent way, we need to
re-examine the problem. Do *all* of the messages need to be processed in
order? In the betting use case above, only the messages related to a
single account need to be sequentially processed. ActiveMQ provides a
mechanism for dealing with this situation, called *JMS message groups*.

Message groups are a type of partitioning mechanism that allows
producers to categorize messages into groups that will be sequentially
processed according to a business key. This business key is set into a
message property named `JMSXGroupID`.

The natural key to use in the betting use case would be the account ID.

To illustrate how dispatch works, consider a set of messages that arrive
in the following order:

```
[(A, Group1), (B, Group1), (C, Group2), (D, Group3), (E, Group2)]
```

When a message is processed by the dispatching mechanism in ActiveMQ, and
it sees a `JMSXGroupID` that has not previously been seen, that key is
assigned to a consumer on a round-robin basis. From that point on, all
messages with that key will be sent to that consumer.

Here, the groups will be assigned between two consumers, `C1` and `C2`,
as follows:

```
C1: [Group1, Group3]
C2: [Group2]
```

The messages will be dispatched and processed as follows:

```
C1: [(A, Group1), (B, Group1), (D, Group3)]
C2: [(C, Group2), (E, Group2)]
```

If a consumer fails, then any groups assigned to it will be reallocated
between the remaining consumers, and any unacknowledged messages will be
redispatched accordingly. So while we can guarantee that all related
messages will be processed in order, we cannot say that they will be
processed by the same consumer.

# High Availability

ActiveMQ provides high availability through a master-slave scheme based
on shared storage. In this arrangement, two or more (though usually two)
brokers are set up on separate servers with their messages being
persisted to a message store located at an external location. The message
store cannot be used by multiple broker instances at the
same time, so its secondary function is to act as a locking mechanism to
determine which broker gets exclusive access ([Figure 2-6](https://learning.oreilly.com/library/view/understanding-message-brokers/9781492049296/ch02.html#broker_a_master_broker_b_slave)).

![Broker A is master while Broker B is in standby as slave](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492049296/files/assets/umbk_0206.png)

###### Figure 2-6. Broker A is master while Broker B is in standby as slave

The first broker to connect to the store (Broker A) takes on the role of
the master and opens its ports to messaging traffic. When a second
broker (Broker B) connects to the store, it attempts to acquire the
lock, and as it is unable to, pauses for a short period before
attempting to acquire the lock again. This is known as holding back in a
slave state.

It the meantime, the client alternates between the addresses of two
brokers in an attempt to connect to an inbound port, known as the
transport connector. Once a master broker is available, the client
connects to its port and can produce and consume messages.

When Broker A, which has held the role of the master, fails due to a
process outage ([Figure 2-7](https://learning.oreilly.com/library/view/understanding-message-brokers/9781492049296/ch02.html#broker_a_terminates_broker_b_master)), the following events occur:

1.

The client is disconnected, and immediately attempts to reconnect by
alternating between the addresses of the two brokers.

1.

The lock within the message is released. The timing of this varies
between store implementations.

1.

Broker B, which has been in slave mode periodically attempting to
acquire the lock, finally succeeds and takes over the role of the
master, opening its ports.

1.

The client connects to Broker B and continues its work.

![Broker A terminates, losing connection to store; Broker B takes over as master](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492049296/files/assets/umbk_0207.png)

###### Figure 2-7. Broker A terminates, losing connection to store; Broker B takes over as master

###### Note

Logic to alternate between multiple broker addresses is not
guaranteed to be built into the the client library, as it is with the
JMS/NMS/CMS implementations. If a library provides only reconnection to
a single address, then it may be necessary to place the broker pair
behind a load balancer, which also needs to be made highly available.

The primary disadvantage of this approach is that it requires multiple
physical servers to facilitate a single logical broker. In this scenario,
one broker server out of the two is idle, waiting for its partner to
fail before it can commence work.

The approach also has the additional complexity of requiring that the
broker’s underlying storage, whether it is a shared network file system
or a database, is also highly available. This brings additional hardware
and administration costs to a broker setup. It is tempting in this
scenario to reuse existing highly available storage installations used
by other parts of your infrastructure, such as a database, but this is a
mistake.

It is important to remember that the disk is the main limiter on overall
broker performance. If the disk itself is used concurrently by a process
other than the message broker, then the disk interaction of that process
is likely to slow down broker writes and therefore the rate at which
messages can flow through the system. These sorts of slowdowns are
difficult to diagnose, and the only way that they can be worked around
is to separate the two processes onto different storage volumes.

In order to ensure consistent broker performance, dedicated and
exclusive storage is required.

# Scaling Up and Out

At some point in a project’s lifetime, it may hit up against a
performance limit of the message broker. These limits are typically down
to resources, in particular the interaction of ActiveMQ with its
underlying storage. These problems are usually due to the volume of
messages or conflicts in messaging throughput between destinations,
such as where one queue floods the broker at a peak time.

There are a number of ways to extract more performance out of a broker
infrastructure:

-

Do not use persistence unless you need to. Some use cases tolerate
message loss on failure, especially ones when one system feeds full
snapshot state to another over a queue, either periodically or on
request.

-

Run the broker on faster disks. In the field, significant differences
in write throughput have been seen between standard HDDs and
memory-based alternatives.

-

Make better use of disk dimensions. As shown in the pipe model of disk
interaction outlined earlier, it is possible to get better throughput by
using transactions to send groups of messages, thereby combining
multiple writes into a larger one.

-

Use traffic partitioning. It is possible to get better throughput by
splitting destinations over one of the following:

-

Multiple disks within the one broker, such as by using the mKahaDB
persistance adapter over multiple directories with each mounted to a
different disk.

-

Multiple brokers, with the partitioning of traffic performed manually
by the client application. ActiveMQ does not provide any native features
for this purpose.

One of the most common causes of broker performance issues is simply
trying to do too much with a single instance. Typically this arises in
situations where the broker is naively shared by multiple applications
without consideration of the broker’s existing load or understanding of
capacity. Over time a single broker is loaded more and more until it no
longer behaves adequately.

The problem is often caused at the design phase of a project where a
systems architect might come up with a diagram such as [Figure 2-8](https://learning.oreilly.com/library/view/understanding-message-brokers/9781492049296/ch02.html#conceptual_view).

![Conceptual view of a messaging infrastructure](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492049296/files/assets/umbk_0208.png)

###### Figure 2-8. Conceptual view of a messaging infrastructure

The intent is for multiple applications to communicate with each other
asynchronously via ActiveMQ. The intent is not refined further, and the
diagram then forms the basis of a physical broker installation. This
approach has a name—the Universal Data Pipeline.

This misses a fundamental analysis step between the conceptual design
above and the physical implementation. Before going off to build a
concrete setup, we need to perform an analysis that will be then used
to inform a physical design. The first step of this process should be to
identify which systems communicate with each other—a simple boxes and
arrows diagram will suffice ([Figure 2-9](https://learning.oreilly.com/library/view/understanding-message-brokers/9781492049296/ch02.html#message_flows_between_systems)).

![Sketch of message flows between systems](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492049296/files/assets/umbk_0209.png)

###### Figure 2-9. Sketch of message flows between systems

Once this is established, you can drill down into the details to answer
questions such as:

-

How many queues and topics are being used?

-

What sorts of message volumes are expected over each?

-

How big are the messages on each destination? Large messages can cause
issues in the paging process, leading to memory limits being hit and
blocking the broker.

-

Are the message flows going to be uniform over the course of the day,
or are there bursts due to batch jobs? Large bursts on one less-used
queue might interfere with timely disk writes for high-throughput
destinations.

-

Are the systems in the same data center or different ones? Remote
communication implies some form of broker networking.

The idea is to identify individual messaging use cases that can be combined or
split out onto separate brokers ([Figure 2-10](https://learning.oreilly.com/library/view/understanding-message-brokers/9781492049296/ch02.html#identifying_individual_brokers)). Once broken down in this manner, the
use cases can be simulated in conjunction with each other using
ActiveMQ’s Performance Module to identify any issues.

![Identifying individual brokers](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492049296/files/assets/umbk_0210.png)

###### Figure 2-10. Identifying individual brokers

Once the appropriate number of logical brokers is identified, you can
then work out how to implement these at the physical level through high availability
setups and broker networks.

# Summary

In this chapter we have examined the mechanics by which ActiveMQ
receives and distributes messages. We discussed features that are
enabled by this architecture, including sticky load-balancing of related
messages and transactions. In doing so we introduced a set of concepts
common to all messaging systems, including wire protocols and journals.
We also looked in some detail at the complexities of writing to disk
and how brokers can make use of techniques such as batching writes in
order to increase performance. Finally, we examined how ActiveMQ can be
made highly available, and how it can be scaled beyond the capacity of
an individual broker.

In the next chapter we will take a look at Apache Kafka and how its
architecture reimagines the relationship between clients and brokers to
provide an incredibly resilient messaging pipeline with many times
greater throughput than a regular message broker. We will discuss the
functionality that it trades off to achieve this, and examine in brief
the application architectures that it enables.
