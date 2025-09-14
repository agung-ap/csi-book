# Chapter 4. Performance trade-offs in publishing

### This chapter covers

- Message delivery guarantees in RabbitMQ
- Publisher vs. performance trade-offs

Message publishing is one of the core activities in a messaging-based architecture, and there are many facets to message publishing in RabbitMQ. Many of the message-publishing options available to your applications can have a large impact on your application’s performance and reliability. Although any message broker is measured by its performance and throughput, reliable message delivery is of paramount concern. Imagine what would happen if there were no guarantees when you used an ATM to deposit money into your bank account. You’d deposit money with no certainty that your account balance would increase. This would inevitably be a problem for you and for your bank. Even in non-mission-critical applications, messages are published for an intended purpose, and silently dropping them could easily create problems.

Although not every system has such hard requirements around message delivery guarantees as banking applications do, it’s important for software like RabbitMQ to ensure the messages it receives are delivered. The AMQP specification provides for transactions in message publishing, and for the optional persistence of messages, to provide a higher level of reliable messaging than normal message publishing provides on its own. RabbitMQ has additional functionality, such as delivery confirmations, that provide different levels of message delivery guarantees for you to choose from, including highly available (HA) queues that span multiple servers. In this chapter you’ll learn about the performance and publishing guarantee trade-offs involved in using these functionalities and how to find out if RabbitMQ is silently throttling your message publisher.

### 4.1. Balancing delivery speed with guaranteed delivery

When it comes to RabbitMQ, the *Goldilocks Principle* applies to the different levels of guarantees in message delivery. Abstracted as a takeaway from the “Story of the Three Bears,” the Goldilocks Principle describes where something is *just right*. In the case of reliable message delivery, you should apply this principle to the trade-offs encountered when using the delivery guarantee mechanisms in RabbitMQ. Some of the features may be too slow for your application, such as the ability to ensure messages survive the reboot of a RabbitMQ server. On the other hand, publishing messages without asking for additional guarantees is much faster, though it may not provide a safe enough environment for mission-critical applications ([figure 4.1](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-4/ch04fig01)).

![Figure 4.1. Performance will suffer when using each delivery guarantee mechanism, and even more so when they’re used in combination.](https://drek4537l1klr.cloudfront.net/roy/Figures/04fig01_alt.jpg)

In RabbitMQ, each mechanism designed to create delivery guarantees will come with some impact on performance. On their own, you may not notice a significant difference in throughput, but when they’re used in combination there can be a significant impact on message throughput. Only by performing your own performance benchmarks can you determine the acceptable trade-off of performance versus guaranteed delivery.

When creating application architectures using RabbitMQ, you should keep the Goldilocks Principle in mind. The following questions can help find the right balance between high performance and message safety for a solution that’s *just right*.

- How important is it that messages are guaranteed to be enqueued when published?
- Should a message be returned to a publisher if it can’t be routed?
- If a message can’t be routed, should it be sent somewhere else where it can later be reconciled?
- Is it okay if messages are lost when a RabbitMQ server crashes?
- Should RabbitMQ confirm that it has performed all requested routing and persistence tasks to a publisher when it processes a new message?
- Should a publisher be able to batch message deliveries and then receive confirmation from RabbitMQ that all requested routing and persistence tasks have been applied to all of the messages in the batch?
- If you’re batching the publishing of messages that require confirmation of routing and persistence, is there a need for true atomic commits to the destination queues for a message?
- Are there acceptable trade-offs in reliable delivery that your publishers can use to achieve higher performance and message throughput?
- What other aspects of message publishing will impact message throughput and performance?

In this section we’ll cover how these questions relate to RabbitMQ and what techniques and functionality your applications can employ to implement just the right level of reliable delivery and performance. Over the course of this chapter, you’ll be presented with the options that RabbitMQ provides for finding the right balance of performance and delivery guarantees. You can pick and choose what makes the most sense for your environment and your application, as there’s no one right solution. You could choose to combine mandatory routing with highly available queues, or you may choose transactional publishing along with delivery mode 2, persisting your messages to disk. If you’re flexible in how you approach your application development process, I recommend trying each of the different techniques on its own and in combination with others until you find a balance that you’re comfortable with—something that’s just right.

#### 4.1.1. What to expect with no guarantees

In a perfect world, RabbitMQ reliably delivers messages without any additional configuration or steps. Simply publish your message via `Basic.Publish` with the correct exchange and routing information, and your message will be received and sent to the proper queue. There are no network issues, server hardware is reliable and does not crash, and operating systems never have issues that will impact the runtime state of the RabbitMQ broker. Rounding out a utopian application environment, your consumer applications will never face performance constraints by interacting with services that may slow their processing. Queues never back up and messages are processed as quickly as they’re published. Publishing isn’t throttled in any way.

Unfortunately, in a world where Murphy’s Law is a rule of thumb, the things that would never occur in a perfect world occur regularly.

In non-mission-critical applications, normal message publishing doesn’t have to handle every possible point of failure; finding the right balance will get you most of the way toward reliable and predictable uptime. In a closed-loop environment where you don’t have to worry about network or hardware failures and you don’t have to worry about consumers not consuming quickly enough, RabbitMQ’s architecture and feature set demonstrate a level of reliable messaging that’s good enough for most non-mission-critical applications. For example, Graphite, the popular, highly scalable graphing system originally developed by Orbitz, has an AMQP interface for submitting your statistical data into Graphite. Individual servers running metric collection services, such as collectd, gather information about their runtime states and publish messages on a per-minute basis ([figure 4.2](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-4/ch04fig02)).

![Figure 4.2. Web server collectd’s statistic-gathering daemons publish monitoring data to RabbitMQ for delivery to Graphite and Rocksteady consumers.](https://drek4537l1klr.cloudfront.net/roy/Figures/04fig02_alt.jpg)

These messages carry information such as the CPU load, memory, and network utilization of the server. Graphite has a collector service called carbon that consumes these messages and stores the data in its internal data store. In most environments, this data isn’t considered mission-critical, even though it may be very important in the overall operational management of the network. If data for a given minute isn’t received by carbon and stored in Graphite, it wouldn’t be a failure on the same level as, say, a financial transaction. Missing sample data may in fact indicate a problem with a server or process that publishes the data to Graphite, and that can be used by systems like Rocksteady to trigger events in Nagios or other similar applications to alert to the problem.

When publishing data like this, you need to be aware of the trade-offs. Delivering the monitoring data without additional publishing guarantees requires fewer configuration options, has lower processing overhead, and is simpler than making sure the messages will be delivered. In this case, *just right* is a simple setup with no additional message delivery guarantees. The collectd process is able to fire and forget the messages it sends. If it’s disconnected from RabbitMQ, it will try to reconnect the next time it needs to send stats data. Likewise, the consumer applications will reconnect when they’re disconnected and go back to consuming from the same queues they were consuming from before.

This works well under most circumstances, until Murphy’s Law comes into play and something goes wrong. If you’re looking to make sure your messages are always delivered, RabbitMQ can change gears and go from good enough to mission critical.

#### 4.1.2. RabbitMQ won’t accept non-routable messages with mandatory set

If you needed the server monitoring data to always be routed to RabbitMQ prior to collectd moving on, all collectd would need to do is tell RabbitMQ that the message being published is `mandatory`. The `mandatory` flag is an argument that’s passed along with the `Basic.Publish` RPC command and tells RabbitMQ that if a message isn’t routable, it should send the message back to the publisher via a `Basic.Return` RPC ([figure 4.3](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-4/ch04fig03)). The `mandatory` flag can be thought of as turning on fault detection mode; it will only cause RabbitMQ to notify you of failures, not successes. Should the message route correctly, your publisher won’t be notified.

![Figure 4.3. When an unroutable message is published with mandatory=True, RabbitMQ returns it via the Basic.Return RPC call to the client.](https://drek4537l1klr.cloudfront.net/roy/Figures/04fig03_alt.jpg)

To publish a message with the `mandatory` flag, you simply pass in the argument after passing in the exchange, routing key, message, and properties, as shown in the following example. To trigger the expected exception for the unroutable message, you can use the same exchange as in [chapter 2](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-2/ch02). When the message is published, there’s no bound destination and an exception should be raised when it’s executed. The code is in the “4.1.2 Publish Failure” notebook.

```
12345678910111213141516import datetime
import rabbitpy

# Connect to the default URL of amqp://guest:guest@localhost:15672/%2F

with rabbitpy.Connection() as connection:                                 1
    with connection.channel() as channel:                                 2
        body = 'server.cpu.utilization 25.5 1350884514'                   3
        message = rabbitpy.Message(channel,                               4
                                   body,                          
                                   {'content_type': 'text/plain',
                                   ' timestamp': datetime.datetime.now(),
                                    'message_type': 'graphite metric'})
        message.publish('chapter2-example',                               5
                        'server-metrics',             
                        mandatory=True)
```

- ***1* Connects to RabbitMQ using the connection as a context manager**
- ***2* Opens a channel to communicate on as a context manager**
- ***3* Creates the message body to deliver**
- ***4* Creates the message to publish, passing the channel, body, and properties**
- ***5* Publishes the message with mandatory turned on**

When you execute this example, you should receive an exception similar to the following one. RabbitMQ can’t route the message because there’s no queue bound to the exchange and routing key.

```
12rabbitpy.exceptions.MessageReturnedException:
       (312, 'NO_ROUTE', 'chapter2-example')
```

##### Note

In the previous example, a new way of invoking the `Connection` and `Channel` objects is used: Both objects are created as a context manager. In Python, if an object is a context manager, it will automatically handle the shutdown of the object instance when you exit the scope or indentation level that you use the object in. In the case of rabbitpy, when you exit the scope, it will correctly close the channel and connection, without you having to explicitly call `Channel.close` or `Connection.close` respectively.

The `Basic.Return` call is an asynchronous call from RabbitMQ, and it may happen at any time after the message is published. For example, when collectd is publishing statistical data to RabbitMQ, it may publish multiple data points before receiving the `Basic.Return` call, should a publish fail. If the code isn’t set up to listen for this call, it will fall on deaf ears, and collectd will never know that the message wasn’t published correctly. This would be problematic if you wanted to ensure the delivery of messages to the proper queues.

In the rabbitpy library, `Basic.Return` calls are automatically received by the client library and will raise a `MessageReturnedException` upon receipt at the channel scope. In the following example, the same message will be sent to the same exchange using the same routing key. The code for publishing the message has been slightly refactored to wrap the channel scope in a `try`/`except` block. When the exception is raised, the code will print the message ID and return the reason extracted from the `reply-text` attribute of the `Basic.Return` frame. You’ll still be publishing to the `chapter2-example` exchange, but you’ll now intercept the exception being raised. This example is in the “4.1.2 Handling Basic.Return” notebook.

```
12345678910111213141516import datetime
import rabbitpy

connection = rabbitpy.Connection()                                1
try:
    with connection.channel() as channel:                         2
        properties = {'content_type': 'text/plain',               3
                      'timestamp': datetime.datetime.now(), 
                      'message_type': 'graphite metric'}
        body = 'server.cpu.utilization 25.5 1350884514'           4
        message = rabbitpy.Message(channel, body, properties)     5
        message.publish('chapter2-example',                       6
                        'server-metrics',
                        mandatory=True)
except rabbitpy.exceptions.MessageReturnedException as error:     7
    print('Publish failure: %s' % error)                          8
```

- ***1* Connects to RabbitMQ on localhost port 5672 as guest**
- ***2* Opens channel to communicate on**
- ***3* Creates message properties**
- ***4* Creates message body**
- ***5* Creates message object combining channel, body, and properties**
- ***6* Publishes message**
- ***7* Catches the exception as a variable called error**
- ***8* Prints exception information**

When you execute this example, instead of the exception from the previous example, you should see a friendlier message, like this:

```
Message was returned by RabbitMQ: (312) NO_ROUTE for exchange chapter2-example
```

With other libraries, you may have to register a callback method that will be invoked if the `Basic.Return` RPC call is received from RabbitMQ when your message is published. In an asynchronous programming model where you are actually processing the `Basic.Return` message itself, you’ll receive a `Basic.Return` method frame, the content header frame, and the body frame, just as if you were consuming messages. If this seems too complex, don’t worry. There are other ways to simplify the process and deal with message routing failures. One is by using *Publisher Confirms* in RabbitMQ.

##### Note

The rabbitpy library and the examples in this section only use up to three arguments when sending a `Basic.Publish` command. This is in contrast to the AMQP specification, which includes an additional argument, the `immediate` flag. The `immediate` flag directs a broker to issue a `Basic.Return` if the message can’t be immediately routed to its destination. This flag is deprecated as of RabbitMQ 2.9 and will raise an exception and close the channel if used.

#### 4.1.3. Publisher Confirms as a lightweight alternative to transactions

The Publisher Confirms feature in RabbitMQ is an enhancement to the AMQP specification and is only supported by client libraries that support RabbitMQ-specific extensions. Although storing messages on disk is an important step in preventing message loss, doing so doesn’t create a contract between the publisher and RabbitMQ server that assures the publisher that a message was delivered. Prior to publishing any messages, a message publisher must issue a `Confirm.Select` RPC request to RabbitMQ and wait for a `Confirm.SelectOk` response to know that delivery confirmations are enabled. At that point, for each message that a publisher sends to RabbitMQ, the server will respond with an acknowledgement response (`Basic.Ack`) or a negative acknowledgement response (`Basic.Nack`), either including an integer value specifying the offset of the message that it is confirming ([figure 4.4](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-4/ch04fig04)). The confirmation number references the message by the order in which it was received after the `Confirm.Select` RPC request.

![Figure 4.4. The sequence of messages sent to and from RabbitMQ for delivery confirmations](https://drek4537l1klr.cloudfront.net/roy/Figures/04fig04_alt.jpg)

A `Basic.Ack` request is sent to a publisher when a message that it has published has been directly consumed by consumer applications on all queues it was routed to, or when the message was enqueued and persisted if requested. If a message can’t be routed, the broker will send a `Basic.Nack` RPC request indicating the failure. It’s then up to the publisher to decide what to do with the message.

In the following example, contained in the “4.1.3 Publisher Confirms” notebook, the publisher enables Publisher Confirms and then evaluates the response from the `Message.publish` call.

```
1234567891011121314import rabbitpy

with rabbitpy.Connection() as connection:                               1
    with connection.channel() as channel:                               2
        exchange = rabbitpy.Exchange(channel, 'chapter4-example')       3
        exchange.declare()                                              4
        channel.enable_publisher_confirms()                             5
        message = rabbitpy.Message(channel,                             6
                                   'This is an important message',    
                                   {'content_type': 'text/plain',
                                    'message_type': 'very important'})

        if message.publish('chapter4-example', 'important.message'):    7
            print('The message was confirmed')
```

- ***1* Connects to RabbitMQ**
- ***2* Opens the channel to communicate on**
- ***3* Creates an exchange object for declaring the exchange**
- ***4* Declares the exchange**
- ***5* Enables Publisher Confirms with RabbitMQ**
- ***6* Creates the rabbitpy Message object to publish**
- ***7* Publishes the message, evaluating the response for confirmation**

As you can see, it’s fairly easy to use Publisher Confirms in rabbitpy. In other libraries, you’ll most likely need to create a callback handler that will asynchronously respond to the `Basic.Ack` or `Basic.Nack` request. There are benefits to each style: rabbitpy’s implementation is easier, but it’s slower because it will block until the confirmation is received.

##### Note

Regardless of whether you use Publisher Confirms or not, if you publish to an exchange that doesn’t exist, the channel you’re publishing on will be closed by RabbitMQ. In rabbitpy, this will cause a `rabbitpy.exceptions.RemoteClosedChannelException` exception to be raised.

Publisher Confirms don’t work in conjunction with transactions and is considered a lightweight and more performant alternative to the AMQP TX process (discussed in [section 4.1.5](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-4/ch04lev2sec5)). In addition, as an asynchronous response to the `Basic.Publish` RPC request, there are no guarantees made as to when the confirmations will be received. Therefore, any application that has enabled Publisher Confirms should be able to receive a confirmation at any point after sending the message.

#### 4.1.4. Using alternate exchanges for unroutable messages

Alternate exchanges are another extension to the AMQ model, created by the RabbitMQ team as a way to handle unroutable messages. An alternate exchange is specified when declaring an exchange for the first time, and it specifies a preexisting exchange in RabbitMQ that the new exchange will route messages to, should the exchange not be able to route them ([figure 4.5](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-4/ch04fig05)).

![Figure 4.5. When an unroutable message is published to an exchange that has an alternate exchange defined, it will then be routed to the alternate exchange.](https://drek4537l1klr.cloudfront.net/roy/Figures/04fig05_alt.jpg)

##### Note

If you set the `mandatory` flag for a message when sending it to an exchange with an alternate exchange, a `Basic.Return` won’t be issued to the publisher if the intended exchange can’t route the message normally. The act of sending an unroutable message to the alternate exchange satisfies the conditions for a published message when the `mandatory` flag is `true`. It’s also important to realize that RabbitMQ’s message routing patterns are applied to alternate exchanges just like any other exchange. If a queue isn’t bound to receive the message with its original routing key, it won’t be enqueued, and the message will be lost.

To use an alternate exchange, you must first set up the exchange that unroutable messages will be sent to. Then, when setting up the primary exchange you’ll be publishing messages to, add the `alternate-exchange` argument to the `Exchange.Declare` command. This process is demonstrated in the following example, which goes one step further to create a message queue that will store any unroutable messages. This example is in the “4.1.4 Alternate-Exchange Example” notebook.

```
123456789101112131415161718192021import rabbitpy

with rabbitpy.Connection() as connection:                         1
    with connection.channel() as channel:                         2
        my_ae = rabbitpy.Exchange(channel,                        3
                               'my-ae',
                               exchange_type='fanout')   
        my_ae.declare()                                           4

        args = {'alternate-exchange': my_ae.name}                 5

        exchange = rabbitpy.Exchange(channel,                     6
                                     'graphite', 
                                     exchange_type='topic', 
                                     arguments=args) 
        exchange.declare()                                        7

        queue = rabbitpy.Queue(channel, 'unroutable-messages')    8
        queue.declare()                                           9
        if queue.bind(my_ae, '#'):                                10
            print('Queue bound to alternate-exchange')
```

- ***1* Connects to RabbitMQ**
- ***2* Opens a channel to communicate on**
- ***3* Creates a rabbitpy Exchange object for the alternate exchange**
- ***4* Declares the exchange on the RabbitMQ server**
- ***5* Defines the dict that specifies the alternate exchange for the graphite exchange**
- ***6* Creates the rabbitpy Exchange object for the graphite exchange, passing in the args dict**
- ***7* Declares the graphite exchange**
- ***8* Creates a rabbitpy Queue object**
- ***9* Declares the queue on the RabbitMQ server**
- ***10* Binds the queue to the alternate exchange**

When declaring the alternate exchange, a `fanout` exchange type was selected, whereas the `graphite` exchange uses a `topic` exchange. A `fanout` exchange delivers messages to all the queues it knows about; a `topic` exchange can selectively route messages based upon parts of a routing key. These two exchange types are discussed in detail in [chapter 5](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-5/ch05). Once the two exchanges are declared, the `unroutable-messages` queue is bound to the alternate exchange. Any messages that are subsequently published to the `graphite` exchange and that can’t be routed will end up in the `unroutable-messages` queue.

#### 4.1.5. Batch processing with transactions

Before there were delivery confirmations, the only way you could be sure a message was delivered was through transactions. The AMQP transaction, or `TX,` class provides a mechanism by which messages can be published to RabbitMQ in batches and then committed to a queue or rolled back. The following example, contained in the “4.1.5 Transactional Publishing” notebook, shows that writing code that takes advantage of transactions is fairly trivial.

```
12345678910111213141516171819import rabbitpy

with rabbitpy.Connection() as connection:                             1
    with connection.channel() as channel:                             2

        tx = rabbitpy.Tx(channel)                                     3
        tx.select()                                                   4

        message = rabbitpy.Message(channel,                           5
                                   'This is an important message',    
                                   {'content_type': 'text/plain',
                                    'delivery_mode': 2,               
                                    'message_type': 'important'}) 
        message.publish('chapter4-example', 'important.message')      6
        try:
            if tx.commit():                                           7
                print('Transaction committed')             
        except rabbitpy.exceptions.NoActiveTransactionError:          8
            print('Tried to commit without active transaction')
```

- ***1* Connects to RabbitMQ**
- ***2* Opens a channel to communicate over**
- ***3* Creates a new instance of the rabbitpy.Tx object**
- ***4* Starts the transaction**
- ***5* Creates the message to publish**
- ***6* Publishes message**
- ***7* Commits transaction**
- ***8* Catches a TX exception if it’s raised**

The transactional mechanism provides a method by which a publisher can be notified of the successful delivery of a message to a queue on the RabbitMQ broker. To begin a transaction, the publisher sends a `TX.Select` RPC request to RabbitMQ, and RabbitMQ will respond with a `TX.SelectOk` response. Once the transaction has been opened, the publisher may send one or more messages to RabbitMQ ([figure 4.6](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-4/ch04fig06)).

![Figure 4.6. A publisher begins a transaction by sending a TX.Select command, publishes messages, and commits the messages with a TX.Commit command.](https://drek4537l1klr.cloudfront.net/roy/Figures/04fig06_alt.jpg)

When RabbitMQ is unable to route a message due to an error, such as a non-existent exchange, it will return the message with a `Basic.Return` response prior to sending a `TX.CommitOk` response. Publishers wishing to abort a transaction should send a `TX.Rollback` RPC request and wait for a `TX.RollbackOk` response from the broker prior to continuing.

##### RabbitMQ and atomic transactions

Atomicity ensures that all actions in a transaction are complete as part of committing the transaction. In AMQP, this means your client won’t receive the `TX.CommitOk` response frame until all actions in the transaction are complete. Unfortunately for those looking for true atomicity, RabbitMQ only implements atomic transactions when every command issued affects a single queue. If more than one queue is impacted by any of the commands in the transaction, the commit won’t be atomic.

Although RabbitMQ will perform atomic transactions if all of the commands in a transaction only impact the same queue, publishers generally don’t have much control over whether the message is delivered to more than one queue. With RabbitMQ’s advanced routing methods, it’s easy to imagine an application starting off with atomic commits when publishing to a single queue, but then someone may add an additional queue bound to the same routing key. Any publishing transactions with that routing key would no longer be atomic.

It’s also worth pointing out that true atomic transactions with persisted messages using `delivery-mode 2` can cause performance issues for publishers. If RabbitMQ is waiting on an I/O-bound server for the write to complete prior to sending the `TX.CommitOk` frame, your client could be waiting longer than if the commands weren’t wrapped in a transaction in the first place.

As implemented, transactions in RabbitMQ allow for batch-like operations in delivery confirmation, allowing publishers more control over the sequence in which they confirm delivery with RabbitMQ. If you’re considering transactions as a method of delivery confirmation, consider using Publisher Confirms as a lightweight alternative—it’s faster and can provide both positive and negative confirmation.

In many cases, however, it’s not publishing confirmation that is required but rather a guarantee that messages won’t be lost while they’re sitting in a queue. This is where HA queues come into play.

#### 4.1.6. Surviving node failures with HA queues

As you look to strengthen the contract between publishers and RabbitMQ to guarantee message delivery, don’t overlook the important role that highly available queues (HA queues) can play in mission-critical messaging architectures. HA queues—an enhancement the RabbitMQ team created that’s not part of the AMQP specification—is a feature that allows queues to have redundant copies across multiple servers.

HA queues require a clustered RabbitMQ environment and can be set up in one of two ways: using AMQP or using the web-based management interface. In [chapter 8](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-8/ch08), we’ll revisit HA queues and use the management interface to define policies for HA queues, but for now we’ll focus on using AMQP.

In the following example, you’ll set up a new queue that spans every node in a RabbitMQ cluster using arguments passed to the `Queue.Declare` AMQP command. This code is in the “4.1.6 HA-Queue Declaration” notebook.

```
123456789101112import rabbitpy

connection = rabbitpy.Connection()                                     1
try:
    with connection.channel() as channel:                              2
        queue = rabbitpy.Queue(channel,                                3
                               'my-ha-queue',               
                               arguments={'x-ha-policy': 'all'})
        if queue.declare():                                            4
            print('Queue declared')
except rabbitpy.exceptions.RemoteClosedChannelException as error:      5
    print('Queue declare failed: %s' % error)
```

- ***1* Connects to RabbitMQ on localhost as guest**
- ***2* Opens a channel to communicate over**
- ***3* Creates a new instance of the Queue object, passing in the HA policy**
- ***4* Declares the queue**
- ***5* Catches any exception raised on error**

When a message is published into a queue that’s set up as an HA queue, it’s sent to each server in the cluster that’s responsible for the HA queue ([figure 4.7](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-4/ch04fig07)). Once a message is consumed from any node in the cluster, all copies of the message will be immediately removed from the other nodes.

![Figure 4.7. A message published into an HA queue is stored on each server that’s configured for it.](https://drek4537l1klr.cloudfront.net/roy/Figures/04fig07_alt.jpg)

HA queues can span every server in a cluster, or only individual nodes. To specify individual nodes, instead of passing in an argument of `x-ha-policy: all`, pass in an `x-ha-policy` of `nodes` and then another argument, `x-ha-nodes` containing a list of the nodes the queue should be configured on. The following example is in the “4.1.6 Selective HA Queue Declaration” notebook.

```
12345678910111213141516import rabbitpy

connection = rabbitpy.Connection()                1
try:
    with connection.channel() as channel:         2
        arguments = {'x-ha-policy': 'nodes',                         3
                     'x-ha-nodes': ['rabbit@node1',
                                    'rabbit@node2',
                                    'rabbit@node3']}
        queue = rabbitpy.Queue(channel,                              4
                               'my-2nd-ha-queue',               
                               arguments=arguments)
        if queue.declare():                                          5
            print('Queue declared')
except rabbitpy.exceptions.RemoteClosedChannelException as error:    6
    print('Queue declare failed: %s' % error)
```

- ***1* Connects to RabbitMQ**
- ***2* Opens a channel to communicate over**
- ***3* Specifies the HA policy the queue should use**
- ***4* Creates a new instance of the Queue object, passing in the HA policy and node list**
- ***5* Declares the queue**
- ***6* Catches the exception if RabbitMQ closes the channel**

##### Note

Even if you don’t have `node1`, `node2`, or `node3` defined, RabbitMQ will allow you to define the queue, and if you were to publish a message that’s routed to `my-2nd-ha-queue`, it would be delivered. In the event that one or more of the nodes listed do exist, the message would live on those servers instead.

HA queues have a single primary server node, and all the other nodes are secondary. Should the primary node fail, one of the secondary nodes will take over the role of primary node. Should a secondary node be lost in an HA queue configuration, the other nodes would continue to operate as they were, sharing the state of operations that take place across all configured nodes. When a lost node is added back, or a new node is added to the cluster, it won’t contain any messages that are already in the queue across the existing nodes. Instead, it will receive all new messages and only be in sync once all the previously published messages are consumed.

#### 4.1.7. HA queues with transactions

HA queues operate like any other queue with regard to protocol semantics. If you’re using transactions or delivery confirmations, RabbitMQ won’t send a successful response until the message has been confirmed to be in all active nodes in the HA queue definition. This can create a delay in responding to your publishing application.

#### 4.1.8. Persisting messages to disk via delivery-mode 2

You learned earlier how to use alternate exchanges for messages that weren’t able to be routed. Now it’s time to add another level of delivery guarantee for them. If the RabbitMQ broker dies for any reason prior to consuming the messages, they’ll be lost forever unless you tell RabbitMQ when publishing the message that you want the messages persisted to disk while they’re in its care.

As you learned in [chapter 3](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-3/ch03), `delivery-mode` is one of the message properties specified as part of AMQP’s `Basic.Properties` definition. If a message has `delivery-mode` set to `1`, which is the default, RabbitMQ is instructed that it doesn’t need to store the message to disk and that it may keep it in memory at all times. Thus, if RabbitMQ is restarted, the non-persisted messages won’t be available when RabbitMQ is back up and running.

On the other hand, if `delivery-mode` is set to `2`, RabbitMQ will ensure that the message is stored to disk. Referred to as *message persistence*, storing the message to disk ensures that if the RabbitMQ broker is restarted for any reason, the message will still be in the queue once RabbitMQ is running again.

##### Note

In addition to `delivery-mode` of `2`, for messages to truly survive a restart of a RabbitMQ broker, your queues must be declared as *durable* when they’re created. Durable queues will be covered in detail in [chapter 5](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-5/ch05).

For servers that don’t have sufficient I/O performance, message persistence can cause dramatic performance issues. Similar to a high-velocity web application’s database server, a high-velocity RabbitMQ instance must go to disk often with persistent messages.

For most dynamic web applications, the read-to-write ratio for OLTP databases is heavily read-biased ([figure 4.8](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-4/ch04fig08)). This is especially true for content sites like Wikipedia. In their case, there are millions of articles, many of which are actively being either created or updated, but the majority of users are reading the content, not writing it.

![Figure 4.8. Although it’s not always the case, most web applications read more from a database than write to it when generating web pages.](https://drek4537l1klr.cloudfront.net/roy/Figures/04fig08_alt.jpg)

When persisting messages in RabbitMQ, you can expect a fairly heavy write bias ([figure 4.9](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-4/ch04fig09)). In a high-throughput messaging environment, RabbitMQ writes persisted messages to disk and keeps track of them by reference until they’re no longer in any queue. Once all of the references for a message are gone, RabbitMQ will then remove the message from disk. When doing high-velocity writes, it’s not uncommon to experience performance issues on under-provisioned hardware, because in most cases the disk write cache is much smaller than the read cache. In most operating systems, the kernel will use free RAM to buffer pages read from disk, whereas the only components caching writes to disk are the disk controller and the disks. Because of this, it’s important to correctly size your hardware needs when using persisted messages. An undersized server that’s tasked with a heavy write workload can bring a whole RabbitMQ server to a crawl.

![Figure 4.9. RabbitMQ stores a persisted message once and keeps track of its references across all queues it’s stored in. If possible, disk reads will be avoided and the message will be removed from disk once all references are gone.](https://drek4537l1klr.cloudfront.net/roy/Figures/04fig09_alt.jpg)

In I/O-bound servers, the operating system will block processes on I/O operations while the data is transferred to and from the storage device via the operating system. When the RabbitMQ server is trying to perform I/O operations, such as saving a message to disk, and the operating system kernel is blocked while waiting for the storage device to respond, there’s little RabbitMQ can do but wait. If the RabbitMQ broker is waiting too often for the operating system to respond to read and write requests, message throughput will be greatly depressed ([figure 4.10](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-4/ch04fig10)).

![Figure 4.10. When a message is received with the delivery-mode property set to 2, RabbitMQ must write the message to disk.](https://drek4537l1klr.cloudfront.net/roy/Figures/04fig10_alt.jpg)

##### Hardware provisioning for persisted messages in RabbitMQ

To properly provision hardware for RabbitMQ servers that will be persisting messages, you can apply the same rules you would for an OLTP database.

RAM is king; beyond sizing the RAM on the server for your normal messaging workload, consider additional RAM for the operating system, to keep disk pages in the kernel disk cache. This will improve the response time of reads for messages that have already been read from disk.

The more spindles the better; although SSDs may be changing the paradigm a bit, the concept still applies. The more hard drives you have available, the better your write throughput will be. Because the system can spread the write workload across all of the disks in a RAID setup, the amount of time each physical device is blocked will be greatly reduced.

Find an appropriately sized RAID card with battery backup that has large amounts of read and write cache. This will allow the writes to be buffered by the RAID card and allow for temporary spikes in write activity that otherwise would be blocked by physical device limitations.

Although message persistence is one of the most important ways to guarantee that your messages will ultimately be delivered, it’s also one of the most costly. Poor disk performance can greatly degrade your RabbitMQ message publishing velocity. In extreme scenarios, I/O delays caused by improperly provisioned hardware can cause messages to be lost. Simply stated, if RabbitMQ can’t respond to publishers or consumers because the operating system is blocking on I/O, your messages can’t be published or delivered.

### 4.2. When RabbitMQ pushes back

In the AMQP specification, assumptions were made about publishers that weren’t favorable for server implementations. Prior to version 2.0 of RabbitMQ, if your publishing application started to overwhelm RabbitMQ by publishing messages too quickly, it would send the `Channel.Flow` RPC method ([figure 4.11](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-4/ch04fig11)) to instruct your publisher to block and not send any more messages until another `Channel.Flow` command was received.

![Figure 4.11. When RabbitMQ asked for Channel.Flow, there were no guarantees publishers were listening.](https://drek4537l1klr.cloudfront.net/roy/Figures/04fig11.jpg)

This proved to be a fairly ineffective method of slowing abusive or “impolite” publishers who weren’t required to respect the `Channel.Flow` command. If a publisher continued to publish messages, RabbitMQ could eventually be overwhelmed, causing performance and throughput issues, possibly even causing the broker to crash. Before RabbitMQ 3.2, the RabbitMQ team deprecated the use of `Channel.Flow`, replacing it with a mechanism called TCP Backpressure to address the issue. Instead of politely asking the publisher to stop, RabbitMQ would stop accepting low-level data on the TCP socket ([figure 4.12](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-4/ch04fig12)). This method works well to protect RabbitMQ from being overwhelmed by a single publisher.

![Figure 4.12. RabbitMQ applies TCP Backpressure to stop impolite publishers from oversaturating it.](https://drek4537l1klr.cloudfront.net/roy/Figures/04fig12.jpg)

Internally, RabbitMQ uses the notion of credits to manage when it’s going to push back against a publisher. When a new connection is made, the connection is allotted a predetermined amount of credits it can use. Then, as each RPC command is received by RabbitMQ, a credit is decremented. Once the RPC request has been internally processed, the connection is given the credit back. A connection’s credit balance is evaluated by RabbitMQ to determine if it should read from a connection’s socket. If a connection is out of credits, it’s simply skipped until it has enough credits.

As of RabbitMQ 3.2, the RabbitMQ team extended the AMQP specification, adding notifications that are sent when the credit thresholds are reached for a connection, notifying a client that its connection has been blocked. `Connection.Blocked` and `Connection.Unblocked` are asynchronous methods that can be sent at any time to notify the client when RabbitMQ has blocked the publishing client and when that block has been removed. Most major client libraries implement this functionality; you should check with the specific client library you’re using to see how your application should determine the connection state. In the next section you’ll see how to perform this check with rabbitpy and how the management API can be leveraged for versions of RabbitMQ prior to 3.2 to check if a connection’s channels are blocked.

##### Note

Ultimately, TCP Backpressure and connection blocking aren’t issues you should run into every day, and they could be an indication that the server hardware you have RabbitMQ on is not properly sized. If you find that this is becoming an issue, it’s time to evaluate your scaling strategy and perhaps implement some of the concepts covered in [chapter 8](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-8/ch08).

#### 4.2.1. Checking the connection status with rabbitpy

Whether you’re using a version of RabbitMQ that supports the `Connection.Blocked` notification or not, the rabbitpy library wraps up this functionality into one easy-to-use API. When connected to a version of RabbitMQ that supports `Connection.Blocked` notifications, rabbitpy will receive the notification and will set an internal flag stating that the connection is blocked.

When you use the following example from the “4.2.1 Connection Blocked” notebook, the output should report that the connection isn’t blocked.

```
1234import rabbitpy

connection = rabbitpy.Connection()                             1
print('Connection is Blocked? %s' % connection.blocked)        2
```

- ***1* Connects to RabbitMQ**
- ***2* Checks to see if the client is blocked**

#### 4.2.2. Using the management API for connection status

If you’re using a version of RabbitMQ prior to 3.2, your application can poll for the status of its connection using the web-based management API. Doing this is fairly straightforward, but if it’s used too frequently, it can cause unwanted load on the RabbitMQ server. Depending on the size of your cluster and the number of queues you have, this API request can take multiple seconds to return.

The API provides RESTful URL endpoints for querying the status of a connection, channel, queue, or just about any other externally exposed object in RabbitMQ. In the management API, the blocked status applies to a channel in a connection, not to the connection itself. There are multiple fields available when querying the status of a channel: `name`, `node`, `connection_details`, `consumer_count`, and `client_flow_blocked`, to name a few. The `client_flow_blocked` flag indicates whether RabbitMQ is applying TCP Backpressure to the connection.

To get the status of a channel, you must first construct the appropriate name for it. A channel’s name is based upon the connection name and its channel ID. To construct the connection name you need the following:

- The local host IP address and outgoing TCP port
- The remote host IP address and TCP port

The format is `"LOCAL_ADDR: PORT -> REMOTE_ADDDR: PORT"`. Expanding on that, the format for the name of a channel is `"LOCAL_ADDR: PORT -> REMOTE_ADDDR: PORT (CHANNEL_ID)"`.

The API endpoint for querying RabbitMQ’s management API for channel status is http://host:port/api/channels/[CHANNEL_NAME]. When queried, the management API will return the result as a JSON-serialized object. The following is an abbreviated example of what the API returns for a channel status query:

```
1234567891011121314151617181920{
    "connection_details": {...},
    "publishes": [...],
    "message_stats": {...},
    "consumer_details": [],
    "transactional": false,
    "confirm": false,
    "consumer_count": 0,
    "messages_unacknowledged": 0,
    "messages_unconfirmed": 0,
    "messages_uncommitted": 0,
    "acks_uncommitted": 0,
    "prefetch_count": 0,
    "client_flow_blocked": false,
    "node": "rabbit@localhost",
    "name": "127.0.0.1:45250 -> 127.0.0.1:5672 (1)",
    "number": 1,
    "user": "guest",
    "vhost": "guest"
}
```

In addition to the `channel_flow_blocked` field, the management API returns rate and state information about the channel.

### 4.3. Summary

One of the major steps in creating your application architecture is defining the role and behavior of publishers. Questions you should be asking yourself include the following:

- Should publishers request that messages are persisted to disk?
- What guarantees do the various components of my application need that a message published will be a message received?
- What will happen in my environment if my application is blocked by TCP Backpressure or when the connection is blocked while publishing messages to RabbitMQ?
- How important are my messages? Can I sacrifice delivery guarantees for higher message throughput?

By asking yourself these questions, you’ll be well on the way to creating an application architecture that’s just right. RabbitMQ provides a large amount of flexibility—perhaps too much in some instances. But by taking advantage of its customization capabilities, you’re empowered to make trade-offs between performance and high reliability and to decide what the right level of metadata is for your messages. Which properties you use and what mechanisms you use for reliable delivery are better decided by you than anyone else, and RabbitMQ will be a solid foundation for whatever you choose.
