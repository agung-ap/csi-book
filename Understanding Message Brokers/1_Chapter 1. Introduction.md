# Chapter 1. Introduction

Intersystem messaging is one of the more poorly understood areas of IT.
As a developer or architect you may be intimately familiar with various
application frameworks, and database options. It is likely, however,
that you have only a passing familiarity with how broker-based messaging
technologies work. If you feel this way, don’t worry—you’re
in good company.

People typically come into contact with messaging infrastructure in a very limited way. It is not uncommon to be pointed at a
system that was set up a long time ago, or to download a distribution
from the internet, drop it into a production-like environment, and start
writing code against it. Once the infrastructure is pushed to production,
the results can be mixed: message loss on failure, distribution not
working the way you had expected, or brokers “hanging” your producers or
not distributing messages to your consumers.

Does this sound in any way familiar?

A common scenario is that your messaging code will work fine—for a
while. Until it does not. This period lulls many into a false sense of
security, which leads to more code being written while holding on to
misconceptions about fundamental behavior of the technology. When
things start to go wrong you are left facing an uncomfortable truth:
that you did not really understand the underlying behavior of the
product or the trade-offs its authors chose to make, such as
performance versus reliability, or transactionality versus horizontal
scalability.

Without a high-level understanding of how brokers work, people make
seemingly sensible assertions about their messaging systems such as:

-

The system will never lose messages

-

Messages will be processed in order

-

Adding consumers will make the system go faster

-

Messages will be delivered exactly once

Unfortunately, some of the above statements are based on assumptions
that are applicable only in certain circumstances, while others are just
incorrect.

This book will teach you how to reason about broker-based messaging
systems by comparing and contrasting two popular broker technologies:
Apache ActiveMQ and Apache Kafka. It will outline the use cases and
design drivers that led to their developers taking very different
approaches to the same domain—the exchange of messages between systems
with a broker intermediary. We will go into these technologies from the
ground up, and highlight the impacts of various design choices along the
way. You will come away with a high-level understanding of both
products, an understanding of how they should and should not be used,
and an appreciation of what to look out for when considering other
messaging technologies in the future.

Before we begin, let’s go all the way back to basics.

# What Is a Messaging System, and Why Do We Need One?

In order for two applications to communicate with each other, they must
first define an interface. Defining this interface involves picking a
transport or protocol, such as HTTP, MQTT, or SMTP, and agreeing on the
shape of the messages to be exchanged between the two systems. This may
be through a strict process, such as by defining an XML schema for an
expense claim message payload, or it may be much less formal, for
example, an agreement between two developers that some part of an HTTP
request will contain a customer ID.

As long as the two systems agree on the shape of those messages and the
way in which they will send the messages to each other, it is then
possible for them to communicate with each other without concern for
how the other system is implemented. The internals of those systems,
such as the programming language or the application frameworks used, can
vary over time. As long as the contract itself is maintained, then
communication can continue with no change from the other side. The two
systems are effectively decoupled by that interface.

Messaging systems typically involve the introduction of an intermediary
between the two systems that are communicating in order to further
decouple the sender from the receiver or receivers. In doing so, the
messaging system allows a sender to send a message without knowing where
the receiver is, whether it is active, or indeed how many instances of
them there are.

Let’s consider a couple of analogies of the types of problems that a
messaging system addresses and introduce some basic terms.

## Point-to-Point

Alexandra walks into the post office to send a parcel to Adam. She
walks up to the counter and hands the teller the parcel. The teller
places the parcel behind the counter and gives Alexandra a receipt.
Adam does not need to be at home at the moment that the parcel is sent.
Alexandra trusts that the parcel will be delivered to Adam at some point
in the future, and is free to carry on with the rest of her day. At some
point later, Adam receives the parcel.

This is an example of the *point-to-point* messaging domain. The post
office here acts as a distribution mechanism for parcels, guaranteeing
that each parcel will be delivered once. Using the post office separates
the act of sending a parcel from the delivery of the parcel.

In classical messaging systems, the point-to-point domain is implemented
through *queues*. A queue acts as a first in, first out (FIFO) buffer
to which one or more consumers can subscribe. Each message is
delivered to only *one of the subscribed consumers*. Queues will
typically attempt to distribute the messages fairly among the
consumers. Only one consumer will receive a given message.

Queues are termed as being durable. *Durability* is a quality of service
that guarantees that the messaging system will retain messages in the
absence of any active subscribers until a consumer next
subscribes to the queue to take delivery of them.

Durability is often confused with *persistence*, and while the two terms
come across as interchangeable, they serve different functions.
Persistence determines whether a messaging system writes the message to
some form of storage between receiving and dispatching it to a consumer.
Messages sent to a queue may or may not be persistent.

Point-to-point messaging is used when the use case calls for a message
to be acted upon once only. Examples of this include depositing funds
into an account or fulfilling a shipping order. We will discuss later
on why the messaging system in itself is incapable of providing
once-only delivery and why queues can at best provide an
*at-least-once* delivery guarantee.

## Publish-Subscribe

Gabriella dials in to a conference call. While she is connected, she
hears everything that the speaker is saying, along with the rest of the
call participants. When she disconnects, she misses out on what is said.
On reconnecting, she continues to hear what is being said.

This is an example of the *publish-subscribe* messaging domain. The
conference call acts as a broadcast mechanism. The person speaking does
not care how many people are currently dialed into the call—the
system guarantees that anyone who is currently dialed in will hear what
is being said.

In classical messaging systems, the publish-subscribe messaging domain
is implemented through *topics*. A topic provides the same sort of
broadcast facility as the conference call mechanism. When a message is
sent into a topic, it is distributed to *all subscribed consumers*.

Topics are typically *nondurable*. Much like the listener who does not
hear what is said on the conference call when she disconnects, topic
subscribers miss any messages that are sent while they are offline. For
this reason, it can be said that topics provide an *at-most-once*
delivery guarantee for each consumer.

Publish-subscribe messaging is typically used when messages are
informational in nature and the loss of a single message is not
particularly significant. For example, a topic might transmit
temperature readings from a group of sensors once every second. A system
that subscribes to the topic that is interested in the current
temperature will not be concerned if it misses a message—another will
arrive shortly.

## Hybrid Models

A store’s website places order messages onto a message “queue.” A
fulfilment system is the primary consumer of those messages. In
addition, an auditing system needs to have copies of these order messages for
tracking later on. Both systems cannot miss messages, even if the
systems themselves are unavailable for some time. The website should not
be aware of the other systems.

Use cases often call for a hybrid of publish-subscribe and
point-to-point messaging, such as when multiple systems each want a copy
of a message and require both durability and persistence to prevent
message loss.

These cases call for a destination (the general term for queues and
topics) that distributes messages much like a topic, such that each
message is sent to a distinct system interested in those messages, but
where each system can define multiple consumers that consume the inbound
messages, much like a queue. The consumption type in this case is
*once-per-interested-party*. These hybrid destinations frequently
require durability, such that if a consumer disconnects, the messages
that are sent in the meantime are received once the consumer reconnects.

Hybrid models are not new and can be addressed in most messaging
systems, including both ActiveMQ (via virtual or composite destinations,
which compose topics and queues) and Kafka (implicitly, as a fundamental
design feature of its destination).

Now that we have some basic terminology and an understanding of why we
might want to use a messaging system, let’s jump into the details.
