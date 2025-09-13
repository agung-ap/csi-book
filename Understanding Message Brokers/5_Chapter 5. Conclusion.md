# Chapter 5. Conclusion

In this book we examined two messaging technologies at a high level in
order to better understand their general characteristics. This was by no
means a comprehensive list of the pros and cons of each technology, but
instead an exercise in understanding how the design choices of each one
impact their feature sets, and an introduction into the high-level
mechanics of message delivery.

ActiveMQ represents a classic broker-centric design that handles a lot
of the complexity of message distribution on behalf of clients. It
provides a relatively simple setup that works for a broad range of
messaging use cases. In implementing the JMS API, it provides mechanisms
such as transactions and message redelivery on failure. ActiveMQ is
implemented through a set of Java libraries, and aside from providing a
standalone broker distribution, can be embedded within any JVM process,
such as an application server or IoT messaging gateway.

Kafka, on the other hand, is a distributed system. It provides a
functionally simpler broker that can be horizontally scaled out, giving
many orders of magnitude higher throughput. It provides massive
performance at the same time as fault tolerance through the use of
replication, avoiding the latency cost of synchronously writing each
message to disk.

ActiveMQ is a technology that focuses on ephemeral movement of data—once consumed, messages are deleted. When used properly, the amount of
storage used is low—queues consumed at the rate of message production
will trend toward empty. This means much smaller maximum disk requirements than
Kafka—gigabytes versus terabytes.

Kafka’s log-based design means that messages are not deleted when
consumed, and as such can be processed many times. This enables a
completely different category of applications to be built—ones which
can consider the messaging layer as a source of historical data and can
use it to build application state.

ActiveMQ’s requirements lead to a design that is limited by the
performance of its storage and relies on a high-availability
mechanism requiring multiple servers, of which some are not in use while
in slave mode. Where messages are physically located matters a lot more
than it does in Kafka. To provide horizontal scalability, you need to
wire brokers together into store-and-forward networks, then worry about
which one is responsible for messages at any given point in time.

Kafka requires a much more involved system involving a ZooKeeper cluster
and requires an understanding of how applications will make use of the
system (e.g., how many consumers will exist on each topic) before it is
configured. It relies upon the client code taking over the
responsibility of guaranteeing ordering of related messages, and correct
management of consumer group offsets while dealing with messages
failures.

Do not believe the myth of a magical messaging fabric—a system that
will solve all problems in all operating environments. As with any
technology area there are trade-offs, even within messaging systems in
the same general category. These trade-offs will quite often impact how
your applications are designed and written.

Your choices in this area should be led first and foremost by a good
understanding of your own use cases, desired design outcomes, and target
operating environment. Spend some time looking into the details of a
messaging product before jumping in. Ask questions:

-

How does this system distribute messages?

-

What are its connectivity options?

-

How can it be made highly available?

-

How do you monitor and maintain it?

-

What logic needs to be implemented within my application?

I hope that this book has given you an appreciation of some of the
mechanics and trade-offs of broker-based messaging systems, and will
help you to consider these products in an informed way. Happy messaging!
