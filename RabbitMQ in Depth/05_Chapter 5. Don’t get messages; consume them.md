# Chapter 5. Don’t get messages; consume them

### This chapter covers

- Consuming messages
- Tuning consumer throughput
- When consumers and queues are exclusive
- Specifying a quality of service for your consumers

Having gone deep into the world of message publishers in the last chapter, it’s now time to talk about consuming the messages your publishers are sending. Consumer applications can be dedicated applications with the sole purpose of receiving messages and acting on them, or receiving messages may be a very small part of a much bigger application. For example, if you’re implementing an RPC pattern with RabbitMQ, the application publishing an RPC request is also consuming the RPC reply ([figure 5.1](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-5/ch05fig01)).

![Figure 5.1. An RPC publisher that publishes a message to RabbitMQ and waits as a consumer for the RPC reply from the RPC consumer](https://drek4537l1klr.cloudfront.net/roy/Figures/05fig01_alt.jpg)

With so many patterns available for implementing messaging in your applications, it’s only appropriate that RabbitMQ has various settings for finding the right balance between performance and reliable messaging. Deciding how your applications will consume messages is the first step in finding this balance, and it starts off with one easy choice: Do you *get* messages, or do you *consume* messages? In this chapter you’ll learn

- Why you should avoid getting messages in favor of consuming them
- How to balance message delivery guarantees with delivery performance
- How to use RabbitMQ’s per-queue settings to automatically delete queues, limit the age of messages, and more

### 5.1. Basic.Get vs. Basic.Consume

RabbitMQ implements two different AMQP RPC commands for retrieving messages from a queue: `Basic.Get` and `Basic.Consume`. As the title of this chapter implies, `Basic.Get` is not the ideal way to retrieve messages from the server. In the simplest terms, `Basic.Get` is a polling model, whereas `Basic.Consume` is a push model.

#### 5.1.1. Basic.Get

When your application uses a `Basic.Get` request to retrieve messages, it must send a new request each time it wants to receive a message, even if there are multiple messages in the queue. If the queue you’re retrieving a message from has a message pending when issuing a `Basic.Get`, RabbitMQ responds with a `Basic.GetOk` RPC response ([figure 5.2](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-5/ch05fig02)).

![Figure 5.2. If there’s a message available when you issue a Basic.Get RPC request, RabbitMQ replies with a Basic.GetOk reply and the message.](https://drek4537l1klr.cloudfront.net/roy/Figures/05fig02.jpg)

If there are no messages pending in the queue, it will reply with `Basic.GetEmpty`, indicating that there are no messages in the queue ([figure 5.3](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-5/ch05fig03)).

![Figure 5.3. If no messages are available when you issue a Basic.Get request, RabbitMQ replies with Basic.GetEmpty.](https://drek4537l1klr.cloudfront.net/roy/Figures/05fig03_alt.jpg)

When using `Basic.Get`, your application should evaluate the RPC response from RabbitMQ to determine if a message has been received. For most long-running processes that are receiving messages from RabbitMQ, this isn’t an efficient way to receive and process messages.

Consider the code in the “5.1.1 Basic.Get Example” notebook. After it connects to RabbitMQ and opens the channel, it infinitely loops while requesting messages from RabbitMQ.

```
12345678910111213import rabbitpy

with rabbitpy.Connection() as connection:                       1
    with connection.channel() as channel:                       2
        queue = rabbitpy.Queue(channel, 'test-messages')        3
        queue.declare()                                         4
        while True:                                             5
            message = queue.get()                               6
            if message:                                         7
                message.pprint()
                message.ack()                                   8
                if message.body == 'stop':                      9
                    break
```

- ***1* Connects to RabbitMQ**
- ***2* Opens a channel on the connection**
- ***3* Creates a new instance of a queue object to interact with RabbitMQ**
- ***4* Declares the queue on the RabbitMQ server**
- ***5* Loops infinitely, attempting to get messages**
- ***6* Gets a message from RabbitMQ**
- ***7* Evaluates whether a message was returned**
- ***8* Acknowledges the message**
- ***9* If the message body is “stop”, exits the loop**

Although this is the simplest way of interacting with RabbitMQ to retrieve your messages, in most cases the performance will be underwhelming at best. In simple message velocity tests, using `Basic.Consume` is at least twice as fast as using `Basic.Get`. The most obvious reason for the speed difference is that with `Basic.Get`, each message delivered carries with it the overhead of the synchronous communication with RabbitMQ, consisting of the client application sending a request frame and RabbitMQ sending the reply. A potentially less obvious reason to avoid `Basic.Get`, yet one with more impact on throughput, is that due to the ad hoc nature of `Basic.Get`, RabbitMQ can’t optimize the delivery process in any way because it never knows when an application is going to ask for a message.

#### 5.1.2. Basic.Consume

In contrast, by consuming messages with the `Basic.Consume` RPC command, you’re registering your application with RabbitMQ and telling it to send messages asynchronously to your consumer as they become available. This is commonly referred to as a publish-subscribe pattern, or pub-sub. Instead of the synchronous conversation with RabbitMQ that occurs when using `Basic.Get`, consuming messages with `Basic.Consume` means your application automatically receives messages from RabbitMQ as they become available until the client issues a `Basic.Cancel` ([figure 5.4](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-5/ch05fig04)).

![Figure 5.4. When a client issues a Basic.Consume, RabbitMQ sends messages to it as they become available until the client issues a Basic.Cancel.](https://drek4537l1klr.cloudfront.net/roy/Figures/05fig04_alt.jpg)

Consuming messages from RabbitMQ also requires one less step in your code when you receive a message. As illustrated in the following example, when your application receives a message from RabbitMQ as a consumer, it doesn’t need to evaluate the message to determine whether the value is a message or an empty response (`Basic.GetEmpty`). But like with `Basic.Get`, your application still needs to acknowledge the message to let RabbitMQ know the message has been processed. This code is contained in the “5.1.2 Basic.Consume Example” notebook.

```
123456import rabbitpy

for message in rabbitpy.consume('amqp://guest:guest@localhost:5672/%2f',   1
                                'test-messages'):
    message.pprint() 
    message.ack()                                                          2
```

- ***1* Iterates through the messages in the test-messages queue**
- ***2* Acknowledges receipt of the message**

##### Note

You might have noticed that the code in the preceding example is shorter than that in previous examples. This is because rabbitpy has shorthand methods that encapsulate much of the logic required to connect to RabbitMQ and use channels.

##### Consumer-tag

When your application issues `Basic.Consume`, a unique string is created that identifies the application on the open channel with RabbitMQ. This string, called a consumer tag, is sent to your application with each message from RabbitMQ.

The consumer tag can be used to cancel any future receipt of messages from RabbitMQ by issuing a `Basic.Cancel` RPC command. This is especially useful if your application consumes from multiple queues at the same time, because each message received contains the consumer tag it’s being delivered for in its method frame. Should your application need to perform different actions for messages received from different queues, it can use the consumer tag used in the `Basic.Consume` request to identify how it should process a message. However, in most cases, the consumer tag is handled under the covers by the client library, and you don’t need to worry about it.

In the “5.1.2 Consumer with Stop” notebook, the following consumer code will listen for messages until it receives a message with the message body that only contains the word “stop”.

```
123456789import rabbitpy

with rabbitpy.Connection() as connection:                            1
    with connection.channel() as channel:                            2
        for message in rabbitpy.Queue(channel, 'test-messages'):     3
            message.pprint()                                         4
            message.ack()                                            5
            if message.body == 'stop':                          6
                break
```

- ***1* Connects to RabbitMQ**
- ***2* Opens a channel on the connection**
- ***3* Iterates through the messages in the queue as a consumer**
- ***4* Pretty-prints the message attributes**
- ***5* Acknowledges the message**
- ***6* Evaluates the message body, breaking if it’s “stop”**

Once you have the consumer running, you can publish messages to it using the code in the “5.1.2 Message Publisher” notebook in a new browser tab:

```
1234567import rabbitpy

for iteration in range(10):                                       1
    rabbitpy.publish('amqp://guest:guest@localhost:5672/%2f',     2
                     '', 'test-messages', 'go')
rabbitpy.publish('amqp://guest:guest@localhost:5672/%2f',         4
                 '', 'test-messages', 'stop')
```

- ***1* Loops 10 times**
- ***2* Publishes the same message to RabbitMQ**
- ***3* Publishes the stop message to RabbitMQ**

When you run the publisher, the running code in the “5.1 Consumer with Stop Example” notebook will stop once it receives the stop message by exiting the `Queue.consume_messages` iterator. A few things are happing under the covers in the rabbitpy library when you exit the iterator. First, the library sends a `Basic.Cancel` command to RabbitMQ. Once the `Basic.CancelOk` RPC response is received, if RabbitMQ has sent any messages to your client that weren’t processed, rabbitpy will send a negative acknowledgment command (`Basic.Nack`) and instruct RabbitMQ to requeue the messages.

Choosing between the synchronous `Basic.Get` and the asynchronous `Basic.Consume` is the first of several choices you’ll need to make when writing your consumer application. Like the trade-offs involved when publishing messages, the choices you make for your application can directly impact message delivery guarantees and performance.

### 5.2. Performance-tuning consumers

As when publishing messages, there are trade-offs in consuming messages that balance throughput with message delivery guarantees. As [figure 5.5](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-5/ch05fig05) points out, there are several options that can be used to speed message delivery from RabbitMQ to your application. Also as when publishing messages, RabbitMQ offers fewer guarantees for message delivery with the faster delivery throughput options.

![Figure 5.5. Consumer-tuning performance scale](https://drek4537l1klr.cloudfront.net/roy/Figures/05fig05_alt.jpg)

In this section you’ll learn how you can tune RabbitMQ’s message delivery throughput to consumers by toggling the requirements for message acknowledgments, how to adjust RabbitMQ’s message preallocation thresholds, and how to assess the impact transactions have when used with a consumer.

#### 5.2.1. Using no-ack mode for faster throughput

When consuming messages, your application registers itself with RabbitMQ and asks for messages to be delivered as they become available. Your application sends a `Basic.Consume` RPC request, and with it, there’s a `no-ack` flag. When enabled, this flag tells RabbitMQ that your consumer won’t acknowledge the receipt of messages and that RabbitMQ should just send them as quickly as it is able.

The following example in the “5.2.1 No-Ack Consumer” notebook demonstrates how to consume messages without having to acknowledge them. By passing `True` as an argument to the `Queue.consumer` method, rabbitpy sends a `Basic.Consume` RPC request with `no_ack=True`.

```
1234567import rabbitpy

with rabbitpy.Connection() as connection:                             1
    with connection.channel() as channel:                             2
        queue = rabbitpy.Queue(channel, 'test-messages')              3
        for message in queue.consume_messages(no_ack=True):           4
            message.pprint()                                          5
```

- ***1* Connects to RabbitMQ**
- ***2* Opens a channel on the connection**
- ***3* Creates a queue object to consume with**
- ***4* Consumes messages with no_ack=True**
- ***5* Pretty-prints the message attributes**

Consuming messages with `no_ack=True` is the fastest way to have RabbitMQ deliver messages to your consumer, but it’s also the least reliable way to send messages. To understand why this is, it’s important to consider each step a message must go through prior to being received by your consumer application ([figure 5.6](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-5/ch05fig06)).

![Figure 5.6. There are multiple data buffers that receive the message data prior to your consumer application.](https://drek4537l1klr.cloudfront.net/roy/Figures/05fig06_alt.jpg)

When RabbitMQ sends a message over an open connection, it’s communicating to the client via a TCP socket connection. If this connection is open and writable, RabbitMQ assumes that everything is in proper working order and that the message was delivered. Should there be a network issue when RabbitMQ tries to write to the socket to deliver the message, the operating system will raise a socket error letting RabbitMQ know there was a problem. If no errors are raised, RabbitMQ assumes the message has been delivered. A message acknowledgment, sent via a `Basic.Ack` RPC response, is one way for a client to let RabbitMQ know that it has successfully received and, in most cases, processed the message. But if you turn off message acknowledgments, RabbitMQ will send another message without waiting, if one is available. In fact, RabbitMQ will continue to send messages, if they’re available, to your consumer until the socket buffers are filled.

##### Increasing receive socket buffers in Linux

To increase the number of receive socket buffers in Linux operating systems, the `net.core.rmem_default` and `net.core.rmem_max` values should be increased from their default 128 KB values. A 16 MB (16777216) value should be adequate for most environments. Most distributions have you change this value in /etc/sysctl.conf, though you could set the value manually by issuing the following commands:

```
12echo 16777216 > /proc/sys/net/core/rmem_default
echo 16777216 > /proc/sys/net/core/rmem_max
```

It’s because RabbitMQ isn’t waiting for an acknowledgment that this method of consuming messages can often provide the highest throughput. For messages that are disposable, this is an ideal way to create the highest possible message velocity, but it’s not without major risks. Consider what would happen if a consumer application crashed with a hundred 1 KB messages in the operating system’s socket receive buffer. RabbitMQ believes that it has already sent these messages, and it will receive no indication of how many messages were to be read from the operating system when the application crashed and the socket closed. The exposure your application faces depends on message size and quantity in combination with the size of the socket receive buffer in your operating system.

If this method of consuming messages doesn’t suit your application architecture but you want faster message throughput than a single message delivery and subsequent acknowledgment can provide, you’ll want to look at controlling the quality of service prefetch settings on your consumer’s channel.

#### 5.2.2. Controlling consumer prefetching via quality of service settings

The AMQP specification calls for channels to have a quality of service (QoS) setting where a consumer can ask for a prespecified number of messages to be received prior to the consumer acknowledging receipt of the messages. The QoS setting allows RabbitMQ to more efficiently send messages by specifying how many messages to preallocate for the consumer.

Unlike a consumer with acknowledgments disabled (`no_ack=True)`, if your consumer application crashes before it can acknowledge the messages, all the prefetched messages will be returned to the queue when the socket closes.

At the protocol level, sending a `Basic.QoS` RPC request on a channel specifies the quality of service. As part of this RPC request, you can specify whether the QoS setting is for the channel it’s sent on or all channels open on the connection. The `Basic.QoS` RPC request can be sent at any time, but as illustrated in the following code from the “5.2.2 Specifying QoS” notebook, it’s usually performed prior to a consumer issuing the `Basic.Consume` RPC request.

```
12345678import rabbitpy

with rabbitpy.Connection() as connection:                             1
    with connection.channel() as channel:                             2
        channel.prefetch_count(10)                                    3
        for message in rabbitpy.Queue(channel, 'test-messages'):      4
            message.pprint()                                          5
            message.ack()                                             6
```

- ***1* Connects to RabbitMQ**
- ***2* Opens a channel on the connection**
- ***3* Specifies the QoS prefetch count of 10 messages**
- ***4* Iterates through the messages in the queue as a consumer**
- ***5* Pretty-prints the message attributes**
- ***6* Acknowledges the message**

##### Note

Although the AMQP specification calls for both a prefetch count and a prefetch size for the `Basic.QoS` method, the prefetch size is ignored if the `no-ack` option is set.

##### Calibrating your prefetch values to an optimal level

It’s also important to realize that over-allocating the prefetch count can have a negative impact on message throughput. Multiple consumers on the same queue will receive messages in a round-robin fashion from RabbitMQ, but it’s important to benchmark prefetch count performance in high-velocity consumer applications. The benefit of particular settings can vary based on the message composition, consumer behavior, and other factors such as operating system and language.

In [figure 5.7](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-5/ch05fig07), a simple message was benchmarked with a single consumer, showing that in these circumstances, a prefetch count value of 2,500 was the best setting for peak message velocity.

![Figure 5.7. Simple benchmark results for consuming with no QoS set and different prefetch count values](https://drek4537l1klr.cloudfront.net/roy/Figures/05fig07_alt.jpg)

##### Acknowledging multiple messages at once

One of the nice things about using the QoS setting is that you don’t need to acknowledge each message received with a `Basic.Ack` RPC response. Instead, the `Basic.Ack` RPC response has an attribute named `multiple`, and when it’s set to `True` it lets RabbitMQ know that your application would like to acknowledge all previous unacknowledged messages. This is demonstrated in the following example from the “5.2.2 Multi-Ack Consumer” notebook.

```
123456789101112import rabbitpy

with rabbitpy.Connection() as connection:                             1
    with connection.channel() as channel:                             2
        channel.prefetch_count (10)                                   3
        unacknowledged = 0                                            4
        for message in rabbitpy.Queue(channel, 'test-messages')       5
            message.pprint()                                          6
            unacknowledged += 1                                       7
            if unacknowledged == 10:                          8
                message.ack(all_previous=True)                9
                unacknowledged = 0                            10
```

- ***1* Connects to RabbitMQ**
- ***2* Opens a channel on the connection**
- ***3* Specifies a QoS prefetch count of 10 messages**
- ***4* Initializes an unacknowledged message counter**
- ***5* Consumes messages from RabbitMQ messages**
- ***6* Pretty-prints the message attributes message counter**
- ***7* Increments the unacknowledged message counter**
- ***8* Checks to see if the unacknowledged message count matches the prefetch_count**
- ***9* Acknowledges all previous unacknowledged messages**
- ***10* Resets the unacknowledged message counter**

Acknowledging multiple messages at the same time allows you to minimize the network communications required to process your messages, improving message throughput ([figure 5.8](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-5/ch05fig08)). It is worth noting that this type of acknowledgment carries with it some level of risk. Should you successfully process some messages and your application dies prior to acknowledging them, all the unacknowledged messages will return to the queue to be processed by another consumer process.

![Figure 5.8. Acknowledging multiple messages at the same time improves throughput.](https://drek4537l1klr.cloudfront.net/roy/Figures/05fig08_alt.jpg)

As with publishing messages, the Goldilocks principle applies to consuming messages—you need to find the sweet spot between acceptable risk and peak performance. In addition to QoS, you should consider transactions as a way to improve message delivery guarantees for your application. The source code for these benchmarks is available on the book’s website at [http://www.manning.com/roy](http://www.manning.com/roy).

#### 5.2.3. Using transactions with consumers

Like when publishing messages into RabbitMQ, transactions allows your consumer applications to commit and roll back batches of operations. Transactions (AMQP `TX` class) can have a negative impact on message throughput with one exception. If you aren’t using QoS settings, you may actually see a slight performance improvement when using transactions to batch your message acknowledgments ([figure 5.9](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-5/ch05fig09)).

![Figure 5.9. Message velocities when using transactions compared to non-transactional message velocities](https://drek4537l1klr.cloudfront.net/roy/Figures/05fig09_alt.jpg)

As with specific QoS settings, you should benchmark your consumer application performance as part of your evaluation in determining whether transactions should play a role in your consumer application. Whether you’re using them to batch message acknowledgments or to ensure that you can roll back RPC responses when consuming messages, knowing the true performance impact of transactions will help you find the proper balance between message delivery guarantees and message throughput.

##### Note

Transactions don’t work for consumers with acknowledgments disabled.

### 5.3. Rejecting messages

Acknowledging messages is a great way to ensure that RabbitMQ knows the consumer has received and processed a message before it discards it, but what happens when a problem is encountered, either with the message or while processing the message? In these scenarios, RabbitMQ provides two mechanisms for kicking a message back to the broker: `Basic.Reject` and `Basic.Nack` ([figure 5.10](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-5/ch05fig10)). In this section we’ll cover the difference between the two, as well as dead-letter exchanges, a RabbitMQ-specific extension to the AMQP specification that can help identify systemic problems with batches of rejected messages.

![Figure 5.10. A consumer can acknowledge, reject, or negatively acknowledge a message. Basic.Nack allows for multiple messages to be rejected at once, whereas Basic.Reject allows just one message to be rejected at a time.](https://drek4537l1klr.cloudfront.net/roy/Figures/05fig10_alt.jpg)

#### 5.3.1. Basic.Reject

`Basic.Reject` is an AMQP-specified RPC response to a delivered message that informs the broker that the message couldn’t be processed. Like `Basic.Ack`, it carries with it the delivery tag created by RabbitMQ to uniquely identify the message on the channel on which your consumer is communicating with RabbitMQ. When a consumer rejects a message, you can instruct RabbitMQ to either discard the message or to requeue the message with the `requeue` flag. When the `requeue` flag is enabled, RabbitMQ will put the message back into the queue to be processed again.

I often use this feature in writing consumer applications that communicate with other services, such as databases or remote APIs. Instead of writing logic in my consumer for retrying on failure due to a remote exception, such as a disconnected database cursor or failure to contact a remote API, I simply catch the exception and reject the message with `requeue` set to `True`. This allows me to simplify my code paths in a consumer, and when used in conjunction with a stats program such as Graphite, I can see trends in exception behavior by watching the requeue velocity.

The following example, from the “5.3.1 Message Rejection” notebook, demonstrates how when a message is requeued, the `redelivered` flag is set in the message, informing the message’s next consumer that it had been previously delivered. I’ve used this functionality to implement a “two-strikes and you’re out” policy. A malformed message may cause havoc in a consumer, but if you’re uncertain whether the problem is due to the message or something else in the consumer, inspecting the `redelivered` flag is a good way to determine if you should reject the message to be requeued or discarded when an error is encountered.

```
1234567import rabbitpy

for message in rabbitpy.consume('amqp://guest:guest@localhost:5672/%2f',   1
                                'test-messages'):
    message.pprint()                                                       2
    print('Redelivered: %s' % message.redelivered)                         3
    message.reject(True)                                                   4
```

- ***1* Iterates over messages as a consumer**
- ***2* Pretty-prints the message attributes**
- ***3* Prints out the redelivered attribute of the message**
- ***4* Rejects the message and requeues the message to be consumed again**

Like `Basic.Ack`, using `Basic.Reject` releases the hold on a message after it has been delivered without `no-ack` enabled. Although you can confirm the receipt or processing of multiple messages at once with `Basic.Ack`, you can’t reject multiple messages at the same time using `Basic.Reject`—that’s where `Basic.Nack` comes in.

#### 5.3.2. Basic.Nack

`Basic.Reject` allows for a single message to be rejected, but if you are using a workflow that leverages `Basic.Ack`’s multiple mode, you may want to leverage the same type of functionality when rejecting messages. Unfortunately, the AMQP specification doesn’t provide for this behavior. The RabbitMQ team saw this as a shortcoming in the specification and implemented a new RPC response method called `Basic.Nack`. Short for “negative acknowledgment,” the similarity of the `Basic.Nack` and `Basic.Reject` response methods may be understandably confusing upon first inspection. To summarize, the `Basic.Nack` method implements the same behavior as the `Basic.Reject` response method but it adds the missing multiple argument to complement the `Basic.Ack` multiple behavior.

##### Warning

As with any proprietary RabbitMQ extension to the AMQP protocol, `Basic.Nack` isn’t guaranteed to exist in other AMQP brokers such as QPID or ActiveMQ. In addition, generic AMQP clients that don’t have the RabbitMQ-specific protocol extensions won’t support it.

#### 5.3.3. Dead letter exchanges

RabbitMQ’s dead-letter exchange (DLX) feature is an extension to the AMQP specification and is an optional behavior that can be tied to rejecting a delivered message. This feature is helpful when trying to diagnose why there are problems consuming certain messages.

For example, one type of consumer application I’ve written takes XML-based messages and turns them into PDF files using a standard markup language called XSL:FO. By combining the XSL:FO document and the XML from the message, I was able to use Apache’s FOP application to generate a PDF file and subsequently file it electronically. The process worked pretty well, but every now and then it would fail. By using a dead-letter exchange on the queue, I was able to inspect the failing XML documents and manually run them against the XSL:FO document to troubleshoot the failures. Without the dead-letter exchange, I would have had to add code to my consumer that wrote out the XML document to some place where I could then manually process it via the command line. Instead, I was able to interactively run my consumer by pointing it at a different queue, and I was able to figure out that the problem was related to how Unicode characters were being treated when the message publisher was generating the document.

Although it may sound like a special type of exchange in RabbitMQ, a dead-letter exchange is a normal exchange. Nothing special is required or performed when creating it. The only thing that makes an exchange a dead-letter exchange is the declared use of the exchange for rejected messages when creating a queue. Upon rejecting a message that isn’t requeued, RabbitMQ will route the message to the exchanged specified in the queue’s `x-dead-letter-exchange` argument ([figure 5.11](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-5/ch05fig11)).

![Figure 5.11. A rejected message can be routed as a dead-letter message through another exchange.](https://drek4537l1klr.cloudfront.net/roy/Figures/05fig11_alt.jpg)

##### Note

Dead-letter exchanges aren’t the same as the alternate exchanges discussed in [chapter 4](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-4/ch04). An expired or rejected message is delivered via a dead-letter exchange, whereas an alternate exchange routes messages that otherwise couldn’t be routed by RabbitMQ.

Specifying a dead-letter exchange when declaring a queue is fairly trivial. Simply pass in the exchange name as the `dead_letter_exchange` argument when creating the rabbitpy `Queue` object or as the `x-dead-letter-exchange` argument when issuing the `Queue.Declare` RPC request. Custom arguments allow you to specify arbitrary key/value pairs that are stored with the queue definition. You’ll learn more about them in section 5.4.6. The following example is in the “5.3.3 Specifying a Dead Letter Exchange” notebook.

```
12345678import rabbitpy

with rabbitpy.Connection() as connection:                                  1
    with connection.channel() as channel:                                  2
        rabbitpy.Exchange(channel, 'rejected-messages').declare()          3
        queue = rabbitpy.Queue(channel, 'dlx-example',                     4
                               dead_letter_exchange='rejected-messages')  
        queue.declare()                                                    5
```

- ***1* Connects to RabbitMQ**
- ***2* Opens a channel on the connection**
- ***3* Declares the dead-letter exchange**
- ***4* Creates the rabbitpy Queue object**
- ***5* Declares the “example” queue with the “rejected-messages” dead-letter exchange**

In addition to the exchange, the dead-lettering functionality allows you to override the routing key with a prespecified value. This allows you to use the same exchange for your dead-lettered messages as your non-dead-lettered messages but to ensure that the dead-lettered messages aren’t delivered to the same queue. Setting the prespecified routing key requires an additional argument, `x-dead-letter-routing-key`, to be specified when declaring the queue.

##### Note

Per the AMQP standard, all queue settings in RabbitMQ are immutable, meaning they can’t be changed after a queue has been declared. In order to change the dead-letter exchange for a queue, you’d have to delete it and redeclare it.

There are many ways dead-letter exchanges can be leveraged in your application architecture. From providing a safe place to store malformed messages to more directly integrating workflow concepts such as processing rejected credit card authorizations, the dead-letter exchange feature is very powerful, yet it’s often overlooked due to its secondary placement as a custom argument for a queue.

### 5.4. Controlling queues

There are many different use cases for consumer applications. For some applications, it’s acceptable for multiple consumers to listen to the same queue, and for others a queue should only have a single consumer. A chat application may create a queue per room or user, where the queues are considered temporary, whereas a credit card processing application may create one durable queue that’s always present. With such a wide set of use cases, it’s difficult to provide for every option that may be desired when dealing with queues. Surprisingly RabbitMQ provides enough flexibility for almost any use case when creating queues.

When defining a queue, there are multiple settings that determine a queue’s behavior. Queues can do the following, and more:

- Auto-delete themselves
- Allow only one consumer to consume from them
- Automatically expire messages
- Keep a limited number of messages
- Push old messages off the stack

It’s important to realize that per the AMQP specification, a queue’s settings are immutable. Once you’ve declared a queue, you can’t change any of the settings you used to create it. To change queue settings, you must delete the queue and re-create it.

To explore the various settings available for creating a queue, let’s first explore options for temporary queues, starting with queues that delete themselves.

#### 5.4.1. Temporary queues

##### Automatically deleting queues

Like a briefcase from *Mission Impossible*, RabbitMQ provides for queues that will delete themselves once they’ve been used and are no longer needed. Like a dead drop from a spy movie, queues that automatically delete themselves can be created and populated with messages. Once a consumer connects, retrieves the messages, and disconnects, the queue will be removed.

Creating an auto-delete queue is as easy as setting the `auto_delete` flag to `True` in the `Queue.Declare` RPC request, as in this example from the “5.4.1 Auto-Delete Queue” IPython notebook.

```
1234567import rabbitpy

with rabbitpy.Connection() as connection:                     1
    with connection.channel() as channel:                     2
        queue = rabbitpy.Queue(channel, 'ad-example',         3
                               auto_delete=True)
        queue.declare()                                       4
```

- ***1* Connects to RabbitMQ**
- ***2* Opens a channel on the connection**
- ***3* Creates the rabbitpy Queue object**
- ***4* Declares the “ad-example” queue with auto_delete set to True**

It’s important to note that any number of consumers can consume from an automatically deleting queue; the queue will only delete itself when there are no more consumers listening to it. It’s a fun use case to think of automatically deleting queues as a form of spy craft, but that’s not the only use of automatically deleting queues.

One use case is a chat style application where each queue represents a user’s inbound chat buffer. If a user’s connection is severed, it’s not unreasonable for such an application to expect that the queue and any unread messages should be deleted.

Another example use is with RPC-style applications. For an application that sends RPC requests to consumers and expects the responses to be delivered by RabbitMQ, creating a queue that deletes itself when the application terminates or disconnects allows RabbitMQ to automatically clean up after the application. In this use case, it’s important that the RPC reply queue be only consumable by the application that’s publishing the original RPC request.

##### Allowing only a single consumer

Without the `exclusive` setting enabled on a queue, RabbitMQ allows for very promiscuous consumer behavior. It sets no restrictions on the number of consumers that can connect to a queue and consume from it. In fact, it encourages multiple consumers by implementing a round-robin delivery behavior to all consumers who are able to receive messages from the queue.

There are certain scenarios, such as the RPC reply queue in an RPC workflow, where you’ll want to ensure that only a single consumer is able to consume the messages in a queue. Enabling the exclusive use of a queue involves passing an argument during queue creation, and, like the `auto_delete` argument, enabling `exclusive` queues automatically removes the queue once the consumer has disconnected. This is demonstrated in the following example from the “5.4.1 Exclusive Queue” notebook.

![](https://drek4537l1klr.cloudfront.net/roy/Figures/096fig01_alt.jpg)

A queue that’s declared as `exclusive` may only be consumed by the same connection and channel that it was declared on, unlike queues that are declared with `auto_delete` set to `True`, which can have any number of consumers from any number of connections. An exclusive queue will also automatically be deleted when the channel that the queue was created on is closed, which is similar to how a queue that has `auto-delete` set will be removed once there are no more consumers subscribed to it. Unlike an `auto_delete` queue, you can consume and cancel the consumer for an `exclusive` queue as many times as you like, until the channel is closed. It’s also important to note that the auto-deletion of an `exclusive` queue occurs without regard to whether a `Basic.Consume` request has been issued, unlike an `auto-delete` queue.

##### Automatically expiring queues

While we’re on the subject of queues that are automatically deleted, RabbitMQ allows for an optional argument when declaring a queue that will tell RabbitMQ to delete the queue if it has gone unused for some length of time. Like exclusive queues that delete themselves, automatically expiring queues are easy to imagine for RPC reply queues.

Suppose you have a time-sensitive operation and you don’t want to wait around indefinitely for an RPC reply. You could create an RPC reply queue that has an expiration value, and when that queue expires the queue is deleted. Using a passive queue declare, you can poll for the presence of the queue and act when you either see there are messages pending or when the queue no longer exists.

Creating an automatically expiring queue is as simple as declaring a queue with an `x-expires` argument with the queue’s time to live (TTL) specified in milliseconds, as is demonstrated in this example from the “5.4.1 Expiring Queue” notebook.

```
1234567891011121314import rabbitpy
import time

with rabbitpy.Connection() as connection:                         1
    with connection.channel() as channel:                         2
        queue = rabbitpy.Queue(channel, 'expiring-queue', 
                               arguments={'x-expires': 1000})     3
        queue.declare()                                           4
        messages, consumers = queue.declare(passive=True)         5
        time.sleep(2)                                             6
        try:
            messages, consumers = queue.declare(passive=True)     7
        except rabbitpy.exceptions.AMQPNotFound:                  8
            print('The queue no longer exists')
```

- ***1* Connects to RabbitMQ**
- ***2* Opens a channel on the connection**
- ***3* Creates an object to interact with the queue**
- ***4* Declares the “expiring-queue” queue, which will expire after 1 second of being idle**
- ***5* Uses a passive queue declare to get the message and consumer counts for the queue**
- ***6* Sleeps for 2 seconds**
- ***7* Uses a passive queue declare to get the message and consumer counts for the queue**
- ***8* Catches the AMQPNotFound exception for the expired queue**

There are some strict rules around automatically expiring queues:

- The queue will only expire if it has no consumers. If you have a queue with connected consumers, it will only be automatically removed once they issue a `Basic.Cancel` or disconnect.
- The queue will only expire if there has been no `Basic.Get` request for the TTL duration. Once a single `Basic.Get` request has been made of a queue with an expiration value, the expiration setting is nullified and the queue won’t be automatically deleted.
- As with any other queue, the settings and arguments declared with an `x-expires` argument can’t be redeclared or changed. If you were able to redeclare the queue, extending the expiration by the value of the `x-expires` argument, you’d be violating a hard-set rule in the AMQP specification that a client must not attempt to redeclare a queue with different settings.
- RabbitMQ makes no guarantees about how promptly it will remove the queue post expiration.

#### 5.4.2. Permanent queues

##### Queue durability

When declaring a queue that should persist across server restarts, the `durable` flag should be set to `True`. Often queue durability is confused with message persistence. As we discussed in the previous chapter, messages are stored on disk when a message is published with the `delivery-mode` property set to `2`. The `durable` flag, in contrast, instructs RabbitMQ that you want the queue to be configured until a `Queue.Delete` request is called.

Whereas RPC-style applications generally want queues that come and go with consumers, durable queues are very handy for application workflows where multiple consumers connect to the same queue, and the routing and message flow don’t change dynamically. The “5.4.2 Durable Queue” notebook demonstrates how a durable queue is declared.

```
12345678import rabbitpy

with rabbitpy.Connection() as connection:                    1
    with connection.channel() as channel:                    2
        queue = rabbitpy.Queue(channel, 'durable-queue', 
                               durable=True)                 3
        if queue.declare():                                  4
            print('Queue declared')
```

- ***1* Connects to RabbitMQ**
- ***2* Opens a channel on the connection**
- ***3* Creates an object to interact with the queue**
- ***4* Declares the durable queue**

##### Auto-expiration of messages in a queue

With non-mission-critical messages, sometimes it’s better to have them automatically go away if they hang around too long without being consumed. Whether you’re accounting for stale data that should be removed after its usefulness has expired or you want to make sure that you can recover easily should a consumer application die with a high-velocity queue, per-message TTL settings allow for server-side constraints on the maximum age of a message. Queues declared with both a dead-letter exchange and a TTL value will result in the dead-lettering of messages in the queue at time of expiration.

In contrast to the expiration property of a message, which can vary from message to message, the `x-message-ttl` queue setting enforces a maximum age for all messages in the queue. This is demonstrated in the following example from the “5.4.2 Queue with Message TTL” notebook.

```
1234567import rabbitpy

with rabbitpy.Connection() as connection:                          1
    with connection.channel() as channel:                          2
        queue = rabbitpy.Queue(channel, 'expiring-msg-queue', 
                               arguments={'x-message-ttl': 1000})  3
         queue.declare()                                           4
```

- ***1* Connects to RabbitMQ**
- ***2* Opens a channel on the connection**
- ***3* Creates an object to interact with the queue**
- ***4* Declares the queue**

Using per-message TTLs with queues provides inherent value for messages that may have different value to different consumers. For some consumers, a message may hold transactional value that has monetary value, and it must be applied to a customer’s account. Creating a queue that automatically expires messages would prevent a real-time dashboard listening on a queue from receiving stale information.

##### Maximum length queues

As of RabbitMQ 3.1.0, queues may be declared with a maximum size. If you set the `x-max-length` argument on a queue, once it reaches the maximum size, RabbitMQ will drop messages from the front of the queue as new messages are added. In a chat room with a scroll-back buffer, a queue declared with an `x-max-length` will ensure that a client asking for the *n* most recent messages always has them available.

Like the per message expiration setting and the dead-letter settings, the maximum length setting is set as a queue argument and can’t be changed after declaration. Messages that are removed from the front of the queue can be dead-lettered if the queue is declared with a dead-letter exchange. The following example shows a queue with a predefined maximum length. You’ll find it in the “5.4.2 Queue with a Maximum Length” notebook.

```
1234567import rabbitpy

with rabbitpy.Connection() as connection:                  1
    with connection.channel() as channel:                  2
        queue = rabbitpy.Queue(channel, 'max-length-queue', 
                               arguments={'x-max-length': 1000})   3
         queue.declare()                                           4
```

- ***1* Connects to RabbitMQ**
- ***2* Opens a channel on the connection**
- ***3* Creates an object to interact with the queue**
- ***4* Declares the queue with a maximum length of 1000 messages**

#### 5.4.3. Arbitrary queue settings

As the RabbitMQ team implements new features that extend the AMQP specification with regard to queues, queue arguments are used to carry the setting for each feature set. Queue arguments are used for highly available queues, dead-letter exchanges, message expiration, queue expiration, and queues with a maximum length.

The AMQP specification defines queue arguments as a table where the syntax and semantics of the values are to be determined by the server. RabbitMQ has reserved arguments, listed in [table 5.1](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-5/ch05table01), and it ignores any other arguments passed in. Arguments can be any valid AMQP data type and can be used for whatever purpose you like. Personally, I have found arguments to be a very useful way to set per-queue monitoring settings and thresholds.

##### Table 5.1. Reserved queue arguments

| Argument name | Purpose |
| --- | --- |
| x-dead-letter-exchange | An exchange to which non-requeued rejected messages are routed |
| x-dead-letter-routing-key | An optional routing key for dead-lettered messages |
| x-expires | Queue is removed after the specified number of milliseconds |
| x-ha-policy | When creating HA queues, specifies the mode for enforcing HA across nodes |
| x-ha-nodes | The nodes that an HA queue is distributed across (see [section 4.1.6](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-4/ch04lev2sec6)) |
| x-max-length | The maximum message count for a queue |
| x-message-ttl | Message expiration in milliseconds, enforced at the queue level |
| x-max-priority | Enables priority sorting of a queue with a maximum priority value of 255 (RabbitMQ versions 3.5.0 and greater) |

### 5.5. Summary

Performance-tuning your RabbitMQ consumer applications requires benchmarking and consideration of the trade-offs between fast throughput and guaranteed delivery (much like tuning for publishing messages). When setting out to write consumer applications, consider the following questions in order to find the sweet spot for your application:

- Do you need to ensure that all messages are received, or can they be discarded?
- Can you receive messages and then acknowledge or reject them as a batch operation?
- If not, can you use transactions to improve performance by automatically batching your individual operations?
- Do you really need transactional commit and rollback functionality in your consumers?
- Does your consumer need exclusive access to the messages in the queues it’s consuming from?
- What should happen when your consumer encounters an error? Should the message be discarded? Requeued? Dead-lettered?

These questions provide the starting points for creating a solid messaging architecture that helps enforce the contract between your publishing and consuming applications.

Now that you have the basics of publishing and consuming under your belt, we’ll examine how you can put them into practice with several different messaging patterns and use cases in the next chapter.
