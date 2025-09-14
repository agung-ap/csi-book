# Chapter 9. Using alternative protocols

### This chapter covers

- The advantages of and how to use the MQTT protocol
- How to use STOMP-based applications with RabbitMQ
- How to communicate directly from a web browser using Web STOMP
- How to publish messages to RabbitMQ over HTTP using statelessd

While AMQP 0-9-1 is designed to be a robust protocol that supports the needs of most applications that communicate with RabbitMQ, there are specific use cases where there are better choices. For example, the high-latency, unreliable networking of mobile devices can be problematic for AMQP. In contrast, AMQP’s state-based protocol may be too complicated for some application environments where client applications aren’t able to maintain long-running connections but need to publish at a high velocity. Additionally, some applications may already contain support for messaging, but not using the AMQP protocol. In each of these scenarios, RabbitMQ’s ecosystem of applications and plugins enables it to continue to be the centerpiece in your messaging architecture.

In this chapter, we’ll look at a few alternatives to the standard AMQP 0-9-1 protocol: the MQTT protocol, which is ideal for mobile applications; STOMP, a simpler alternative to AMQP; Web STOMP, designed for use in web browsers; and statelessd for high-velocity message publishing.

### 9.1. MQTT and RabbitMQ

The MQ Telemetry Transport (MQTT) protocol is a lightweight messaging protocol that’s growing in popularity for mobile applications, and support for it is distributed with RabbitMQ as a plugin. Created as a publish-subscribe pattern-based protocol, MQTT was originally invented in 1999 by Andy Stanford-Clark of IBM and Arien Nipper of Eurotech. MQTT was designed for messaging on resource-constrained devices and in low-bandwidth environments, without sacrificing reliable messaging constraints. Although it’s not as feature-rich as AMQP, the explosive growth of mobile applications has resulted in MQTT’s growing popularity in recent years.

From mobile applications to smart cars and home automation, MQTT’s mainstream use has grabbed technology news headlines in recent years. Facebook uses MQTT for real-time messaging and notifications in their mobile applications. In 2013, the Ford Motor Company teamed up with IBM to implement smart car technology using IBM’s MessageSight product line based on MQTT for the Ford Evo concept cars. Commercial home-automation products may be somewhat down the road, but there are numerous open source and open-standard-based home-automation systems using MQTT, such as the FunTechHouse project at [www.fun-tech.se/FunTechHouse/](http://www.fun-tech.se/FunTechHouse/). Also in 2013, MQTT, like AMQP 1.0 the year before, was accepted as an open standard through OASIS, a non-profit organization that works to encourage the development and adoption of open standards. This has provided MQTT with an open, vendor-neutral home for its further development and stewardship.

Should you consider MQTT as a protocol for your messaging architecture? Quite possibly, but you should look at the benefits and drawbacks first: Will your architecture benefit from MQTT’s Last Will and Testament (LWT) feature? (LWT enables clients to specify a message that should be published if the client is unintentionally disconnected.) Or you may run into limitations with MQTT’s maximum message size of 256 MB. Even with RabbitMQ’s MQTT plugin transparently translating between MQTT and AMQP for your applications, to properly evaluate MQTT, as with AMQP, a good understanding of the protocol’s communication process is quite helpful.

#### 9.1.1. The MQTT protocol

There are some commonalities between the AMQ and MQTT protocols. After all, most messaging protocols share many of the same concerns, such as supporting connection negotiation, including authentication and message publishing. Under the covers, however, the protocols are structured differently. Instead of having protocol level constructs like AMQP’s exchanges and queues, MQTT is limited to publishers and subscribers. Of course, this limitation has less impact if you’re using RabbitMQ, because MQTT messages published into RabbitMQ are treated like messages published via AMQP, and subscribers are treated like AMQP consumers.

Although RabbitMQ supports MQTT out of the box, there are differences in messages published via MQTT and AMQP that underscore the value proposition of each protocol. As a lightweight protocol, MQTT is better for constrained hardware without reliable network connections, whereas AMQP is designed to be more flexible but requires more robust and reliable network environments. If you don’t account for these differences, your applications may encounter interoperability problems when using both protocols in the same messaging architecture. In this section, we’ll consider the anatomy of an MQTT message and what impact it can have on your message architecture and applications.

##### Message structure

At the base of MQTT is a message structure referred to as command message, much like AMQP’s low-level frames. Command messages are the low-level data structure that encapsulates the data in MQTT messages ([figure 9.1](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-9/ch09fig01)).

![Figure 9.1. Anatomy of an MQTT command message](https://drek4537l1klr.cloudfront.net/roy/Figures/09fig01_alt.jpg)

An MQTT command message has a fixed two-byte header that describes the message. Marshaled in the first header byte are four values:

1. The message type—A four-bit value that indicates the action for a message, similar to an AMQP method frame. Examples of message types include `CONNECT`, `PUBLISH`, and `SUBSCRIBE`.
1. The DUP flag—A single bit indicating whether the message is a redelivery, without regard to whether a client or server is redelivering the message.
1. The QoS flag—A two-bit value used to indicate the quality of service for a message. In MQTT, the QoS specifies whether a message must be delivered once at most, at least once, or exactly once.
1. The Retain flag—A single-bit flag indicating to the server whether a message should be retained when it has been published to all current subscribers. An MQTT broker will only retain the last message with the Retain flag set, providing a mechanism for new subscribers to always receive the last good message. Suppose you’re using MQTT for a mobile application. Should the application lose its connection to the RabbitMQ server, getting the last good message via the Retain feature allows your app to know the last good message, which will help it resynchronize state when it reconnects.

The second byte of the MQTT message header carries the size of the message payload. MQTT messages have a maximum payload size of 256 MB. In contrast, the maximum message size in AMQP is 16 exabytes, and RabbitMQ limits message size to 2 GB. MQTT’s maximum message size is something to consider when creating your messaging architecture, as you’ll need to create your own protocol on top of MQTT for splitting up payloads larger than 256 MB into individual messages, and then reconstruct them on the subscriber end.

##### Note

According to Maslow’s Law, if all you have is a hammer, everything looks like a nail. It’s very easy to use a protocol like MQTT or AMQP as a hammer for inter-application communication. But for different types of data, there can be better tools. For example, sending large messages such as video or image content over MQTT can be problematic for mobile applications. Although MQTT excels at sending smaller messages such as application-state data, you might want to consider HTTP 1.1 when you want a mobile or embedded device application to upload videos or photos. When using MQTT for small messages, it can outperform HTTP, but when it comes to transferring things like files, HTTP will be faster. It may be easy to overlook HTTP, but it supports chunked file uploads, which is perfect for large media transferred on less than reliable networks. Most mature client libraries will support this feature without your having to create an extra layer to manage such features, as you would with MQTT.

##### Variable headers

In the message payload of some MQTT command messages is binary packed data containing message details in a data structure referred to as *variable headers*. The format of variables can vary from command message to command message. For example, the variable headers of a `CONNECT` message contain data allowing for connection negotiation, whereas the variables of a `PUBLISH` message contain the topic to publish the message to and a unique identifier. In the case of a `PUBLISH` command message, the payload contains the variable headers and the opaque application-level message ([figure 9.2](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-9/ch09fig02)).

![Figure 9.2. Message payload of a PUBLISH command message](https://drek4537l1klr.cloudfront.net/roy/Figures/09fig02_alt.jpg)

For values in variable headers that aren’t fixed in size, such as the topic name, the values are prefixed with two bytes that indicate the size of the value ([figure 9.3](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-9/ch09fig03)). This structure allows servers and clients alike to read and decode messages as they’re being streamed across the socket instead of having to wait for all of a message to be read prior to decoding.

![Figure 9.3. Structure of the topic-name field of a PUBLISH command message’s variable headers](https://drek4537l1klr.cloudfront.net/roy/Figures/09fig03_alt.jpg)

All values in the variable fields are specified to be UTF-8 encoded strings, and they allow for a 32 KB length. It’s important to remember that any values in the variable headers of a `PUBLISH` message subtract from the maximum message size for the message itself. For example, if you use the topic name `my/very/long/topic` to publish to, you’ve used up 23 available bytes from the message payload, so your message content can only be 268,435,433 bytes in length.

#### 9.1.2. Publishing via MQTT

MQTT’s topic names can provide a powerful routing tool for your messages. In fact, they’re very similar in concept to the routing keys that are used in RabbitMQ’s topic exchange, and when routing MQTT messages in RabbitMQ, the topic exchange is exclusively used. MQTT topic strings are namespaced using the forward slash (`/`) symbol as a delimiter when a message is published. To illustrate how MQTT can be used with RabbitMQ, let’s start with an example MQTT publisher publishing a message that will be consumed over AMQP.

##### Creating the message destination

To create a queue for the MQTT published message to be routed to, the following example from the “7.1.2 Setup” IPython notebook creates a queue named `mqtt-messages` and binds it to the `amq.topic` exchange using the routing key `#`.

```
1234567import rabbitpy

with rabbitpy.Connection() as connection:
    with connection.channel() as channel:
        queue = rabbitpy.Queue(channel, 'mqtt-messages')          1
        queue.declare()                                           2
        queue.bind('amq.topic', '#')                              3
```

- ***1* Creates a rabbitpy Queue object**
- ***2* Declares the mqtt-messages queue**
- ***3* Binds the queue to the amq.topic exchange**

The `amq.topic` exchange is the default exchange that MQTT clients publish to, and when they’re published, the MQTT plugin will automatically change forward-slash characters in the MQTT topic name value to periods for the AMQP routing key.

Run the notebook in the IPython Notebook Server, and once it’s been run, we’ll create a Python-based MQTT publisher.

##### Writing the MQTT publisher

For interacting with MQTT via Python, mosquitto ([https://pypi.python.org/pypi/mosquitto](https://pypi.python.org/pypi/mosquitto)) is a popular choice. It’s an asynchronous library meant to be run via a blocking I/O loop, but we’ll fake it with some inline operations that allow it to communicate with RabbitMQ. The following example code is in the “7.1.2 MQTT Publisher” notebook and starts by importing the mosquitto library:

```
import mosquitto
```

With the library imported, a mosquitto client class should be created with a unique name for the client connection. In this case we’ll just use the value `rmqid-test`, but for production using the string representation of the operating system’s process ID is a good idea:

```
client = mosquitto.Mosquitto('rmqid-test')
```

The client class has a `connect` method where you can pass in the connection information for the MQTT server. The `connect` method accepts multiple arguments, including the `hostname`, `port`, and `keepalive` values. In this example, only the hostname is specified, using the default values for `port` and `keepalive`.

```
client.connect('localhost')
```

The library will return a `0` if it connects successfully. A return value that’s greater than `0` indicates there was a problem connecting to the server.

With a connected client, you can now publish a message, passing in the topic name, message content, and a QoS value of `1`, indicating that the message should be published at least once, expecting an acknowledgment from RabbitMQ.

```
client.publish('mqtt/example', 'hello world from MQTT via Python', 1)
```

Because you’re not running a blocking I/O loop, you need to instruct the client to process I/O events. Invoke the `client.loop()` method to process I/O events that should return a `0`, indicating success:

```
client.loop()
```

Now you can disconnect from RabbitMQ and run the `client.loop` method to process any other I/O events.

```
12client.disconnect()
client.loop()
```

When you run this notebook, you should successfully publish a message that has been placed in the mqtt-messages queue you previously declared. Let’s validate that it’s there with rabbitpy.

##### Getting an MQTT-published message via AMQP

The “7.1.2 Confirm MQTT Publish” notebook contains the following code for fetching a message from the `mqtt-messages` queue using `Basic.Get`, and it uses the `Message.pprint()` method to print the content of the message.

```
12345678import rabbitpy

message = rabbitpy.get(queue_name='mqtt-messages')           1
if message:                                                  2
    message.pprint(True)                                     3
    message.ack()                                            4
else:
    print('No message in queue')                             5
```

- ***1* Fetches a message from RabbitMQ using Basic.Get**
- ***2* Evaluates if a message was retrieved**
- ***3* Prints the message, including properties**
- ***4* Acknowledges the message**
- ***5* If no message, lets user know**

When you run the code, you should see the AMQP message from RabbitMQ that was transparently mapped from MQTT semantics to AMQP semantics.

```
123456789101112131415161718192021222324Exchange: amq.topic

Routing Key: mqtt.example

Properties:

{'app_id': '',
 'cluster_id': '',
 'content_encoding': '',
 'content_type': '',
 'correlation_id': '',
 'delivery_mode': None,
 'expiration': '',
 'headers': {'x-mqtt-dup': False, 'x-mqtt-publish-qos': 1},
 'message_id': '',
 'message_type': '',
 'priority': None,
 'reply_to': '',
 'timestamp': None,
 'user_id': ''}

Body:

'hello world from MQTT via Python'
```

The routing key is no longer `mqtt/example` like the topic name that was published, but this is the message that was published. RabbitMQ replaced the forward slash with a period to match the topic exchange semantics. Also note that the AMQP message properties headers table contains two values—`x-mqtt-dup` and `x-mqtt-publish-qos`—containing the values of the MQTT `PUBLISH` message header values.

Now that you’ve validated the publisher, let’s explore what the MQTT subscriber experience is like with RabbitMQ.

#### 9.1.3. MQTT subscribers

When connecting to RabbitMQ via MQTT to subscribe for messages, RabbitMQ will create a new queue. The queue will be named using the format `mqtt-subscriber-[NAME]qos[N]`, where `[NAME]` is the unique client name and `[N]` is the QoS level set on the client connection. For example, a queue named `mqtt-subscriber-facebookqos0` would be created for a subscriber named `facebook` with a QoS setting of `0`. Once a queue is created for a subscription request, it will be bound to the topic exchange using the AMQP period-delimited routing-key semantics.

Subscribers can bind to topics with string matching or pattern matching using semantics similar to AMQP topic-exchange routing-key bindings. The pound symbol (`#`) is for multilevel matching in both AMQP and MQTT. But when publishing with MQTT clients, the plus symbol (`+`) is used for single-level matching in a routing key, instead of using an asterisk (`*`). For example, if you were to publish new image messages over MQTT using the topic names of `image/new/profile` and `image/new/gallery`, MQTT subscribers could receive all image messages by subscribing to `image/#`, all new image messages by subscribing to `image/new/+`, and only new profile images by subscribing to `image/new/profile`.

The following example, from the “7.1.3 MQTT Subscriber” notebook, will connect to RabbitMQ via the MQTT protocol, set itself up as a subscriber, and loop until a single message is received. Once the message is received, it will unsubscribe and disconnect from RabbitMQ. To start, the `mosquitto` and `os` libraries are included:

```
12import mosquitto
import os
```

You can use Python’s standard library `os` module to get the process ID of the subscriber, which allows you to create a unique MQTT client name when creating the new `mosquitto` client. You may want a more random or robust method of naming your subscriber to prevent duplicate client names in production code, but using the process ID should work for this example.

```
client = mosquitto.Mosquitto('Subscriber-%s' % os.getpid())
```

Now you can define a few callback methods that will be invoked by the `mosquitto` library during each phase of execution. To start off, you can create a callback that’s invoked when the client connects:

```
123456def on_connect(mosq, obj, rc):
    if rc == 0:
        print('Connected')
    else:
        print('Connection Error')
client.on_connect = on_connect
```

When an MQTT message is delivered, the `mosquitto` client invokes the `on_message` callback. This callback prints information about the message, and then the client will unsubscribe.

```
1234567def on_message(mosq, obj, msg):
    print('Topic: %s' % msg.topic)
    print('QoS: %s' % msg.qos)
    print('Retain: %s' % msg.retain)
    print('Payload: %s' % msg.payload)
    client.unsubscribe('mqtt/example')
client.on_message = on_message
```

The final callback is invoked when the client is unsubscribed, and it will disconnect the client from RabbitMQ.

```
1234def on_unsubscribe(mosq, obj, mid):
    print("Unsubscribe with mid %s received." % mid)
    client.disconnect()
client.on_unsubscribe = on_unsubscribe
```

With all of the callbacks defined, you can connect to RabbitMQ and subscribe to the topic:

```
12client.connect("127.0.0.1")
client.subscribe("mqtt/example", 0)
```

Finally, you can invoke the I/O event loop by calling `client.loop()` and specifying a timeout of 1 second. The following code will do this, looping until `client.loop()` no longer returns 1 because it has been disconnected from RabbitMQ.

```
12while client.loop(timeout=1) == 0:
    pass
```

Once you open the notebook, you can run all of the cells at once by clicking on the Cell dropdown and choosing Run All. Click over to the “7.1.2 MQTT Publisher” tab and choose Cell > Run All, publishing a new message. In the subscriber tab you should now see output like what’s shown in [figure 9.4](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-9/ch09fig04).

![Figure 9.4. Output of the “MQTT Subscriber” IPython notebook](https://drek4537l1klr.cloudfront.net/roy/Figures/09fig04_alt.jpg)

As you can see, the period-delimited routing key has been transformed back into the forward-slash delimited topic name `mqtt/example`. With the bidirectional transformation from MQTT topic name to AMQP routing key, RabbitMQ successfully bridges the protocols in a transparent and native way for either type of client connecting. In doing so, not only does RabbitMQ create a compelling platform for MQTT applications but it makes for a much more robust messaging platform than brokers that are protocol-specific.

#### 9.1.4. MQTT plugin configuration

With the basics of MQTT out of the way, you may find that you want to customize the MQTT behaviors to match various aspects of your RabbitMQ cluster, such as providing MQTT-specific authentication credentials or queue-specific configuration for subscribers. To change these and other configuration values, you’ll need to edit the main RabbitMQ configuration file, rabbitmq.config.

RabbitMQ’s configuration file is typically located at /etc/rabbitmq/rabbit.config in UNIX-based systems. Where most configuration files use a data serialization format, the rabbitmq.config file uses the code format of native Erlang data structures. Almost like a JSON array of objects, the RabbitMQ configuration contains a top-level stanza for RabbitMQ itself and then a stanza for each plugin that you wish to configure. In the following snippet, RabbitMQ’s AMQP listening port is set to 5672 and the MQTT plugin listening port is set to 1883.

```
[{rabbit,        [{tcp_listeners,    [5672]}]},
 {rabbitmq_mqtt, [{tcp_listeners,    [1883]}]}].
```

Many of the default settings, such as the virtual host and default username and password for the MQTT plugin, mirror the defaults for RabbitMQ. Unlike with AMQP, MQTT clients aren’t able to select which virtual host to use. Although this behavior may change in future versions, currently the only way to change the virtual host used by MQTT clients is by changing the default value of the forward slash using the `vhost` directive in the MQTT configuration stanza from `/` to the desired value:

```
[{rabbitmq_mqtt, [{vhost, <<"/">}]}]
```

Although MQTT does provide a facility for authentication, there may be use cases where this isn’t desired. For those cases, the MQTT plugin has a default username and password combination of `guest` and `guest`. These defaults are changed with the `default_user` and `default_pass` configuration directives. If you’d like to require authentication for MQTT clients, you can disable the default user behavior by setting the `allow_anonymous` configuration directive to `false`.

##### Tip

Your MQTT application architecture may require different settings for different types of MQTT clients. Using a RabbitMQ cluster is one way around the limitation imposed by a single virtual host and the default username and password settings. By having different per-node configurations, you can share MQTT messages in a RabbitMQ cluster, with each node accepting MQTT connections configured with different default settings. There’s no requirement for uniform configuration across RabbitMQ cluster nodes.

[Table 9.1](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-9/ch09table01) describes each of the MQTT plugin configuration directives and their default values. These values directly impact the behavior of the MQTT plugin with regard to MQTT clients and message routing.

##### Table 9.1. MQTT plugin configuration options

| Directive | Type | Description | Default value |
| --- | --- | --- | --- |
| allow_anonymous | Boolean | Enable MQTT clients to connect without authentication. | true |
| default_user | String | The username to use when an MQTT client doesn’t present authentication credentials. | guest |
| default_password | String | The password to use when an MQTT client doesn’t present authentication credentials. | guest |
| exchange | String | The topic exchange to use when publishing MQTT messages. | amq.topic |
| prefetch | Integer | The AMQP QoS prefetch count setting for MQTT listener queues. | 10 |
| ssl_listeners | Array | TCP ports to listen on for MQTT over SSL connections. If specified, the top-level rabbit stanza of the configuration file must contain the ssl_options configuration stanza. | [] |
| subscription_ttl | Integer | The duration to keep a subscriber queue, in milliseconds, after a subscriber unexpectedly disconnects. | 1800000 |
| tcp_listeners | Array | TCP ports to listen on for MQTT connections. | 1833 |
| tcp_listen_options | Array | An array of configuration directives for altering the TCP behavior of the MQTT plugin. | See [table 9.2](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-9/ch09table02) |

Some directives, such as `exchange`, `prefetch`, and `vhost`, are more likely to be candidates for change in your environment, whereas others like the `tcp_listen_options` should be tweaked carefully.

[Table 9.2](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-9/ch09table02) describes the `tcp_listen_options` directives specified by the RabbitMQ documentation and their effect on the TCP connection behavior for MQTT clients and the MQTT plugin. These values are a subset of those the Erlang TCP API provides for TCP socket tweaking. For more detailed information on what other directives are available, consult the Erlang `gen_tcp` documentation at [http://erlang.org/doc/man/gen_tcp.html](http://erlang.org/doc/man/gen_tcp.html). Due to the way RabbitMQ configuration works, the values specified in the configuration file are transparently passed to the Erlang `gen_tcp:start_link` in the `listen_option` parameter. In a majority of use cases, the default values specified by the MQTT plugin shouldn’t be changed; they are the tested and optimized values recommended by the RabbitMQ team.

##### Table 9.2. `tcp_listen_options` for the MQTT plugin

| Directive | Type | Description | Default value |
| --- | --- | --- | --- |
| binary | Atom | Indicates that the socket is a binary TCP socket. Do not remove. | N/A |
| packet | Atom | Tweaks how the Erlang kernel handles TCP data prior to handing off to RabbitMQ. For more information see the Erlang gen_tcp documentation. | raw |
| reuseaddr | Boolean | Instructs the operating system to allow RabbitMQ to reuse the listening socket if it wants to, even if the socket is busy. | true |
| backlog | Integer | Specifies how many pending client connections can exist before refusing new connections. Pending client connections are new TCP socket connections that RabbitMQ hasn’t processed yet. | 10 |
| nodelay | Boolean | Indicates whether a TCP socket should use the Nagle algorithm, waiting to aggregate low-level TCP data for more efficient data transmission. By default this is false, allowing for faster MQTT messaging in most cases by sending TCP data when RabbitMQ wants to, instead of buffering smaller message packets and sending them grouped together. | true |

To review, MQTT is a powerful tool for lightweight messaging in the ever-evolving world of mobile computing and embedded devices. If you’re considering RabbitMQ as the centerpiece of a messaging architecture that includes mobile devices, you should strongly consider the use of MQTT and the RabbitMQ MQTT plugin. Not only does it provide transparent translation of MQTT semantics into RabbitMQ’s AMQP worldview, it transparently translates AMQP semantics for MQTT clients, simplifying the development required for a unified message bus. Although the configuration shortcomings prevent complex MQTT ecosystems on an individual node, there’s an effort underway to expand the MQTT plugin to provide dynamic virtual host and exchange use. In the meantime, multiple RabbitMQ nodes in a cluster may be leveraged to create more complex MQTT topologies.

If your messaging architecture won’t benefit from MQTT but you’d still like a more lightweight solution than AMQP for communicating with RabbitMQ, perhaps STOMP is for you.

### 9.2. STOMP and RabbitMQ

Originally named TMPP, the Streaming Text Oriented Message Protocol (STOMP) was first specified in 2005 by Brian McCallister. Loosely modeled after HTTP, STOMP leverages an easy-to-read, text-based protocol. Initially implemented in Apache ActiveMQ and designed with simplicity in mind, STOMP now enjoys support in numerous message broker implementations and has client libraries in most popular programming languages.

The specification of STOMP 1.2 was released in 2012 and it’s supported by RabbitMQ, along with both of the previous versions. STOMP support is provided by a plugin that’s distributed as part of the core RabbitMQ package. Like with AMQP and MQTT, understanding the STOMP protocol can help shape your opinion on its use in your application or environment.

#### 9.2.1. The STOMP protocol

Designed to allow for stream-based processing, STOMP frames are UTF-8 text that consist of a command and the payload for the command, terminated with a null (0x00) byte. Unlike the binary AMQP and MQTT protocols, STOMP is human-readable and doesn’t require binary bit-packed information to define STOMP message frames and their content.

For example, the following snippet is a STOMP frame for connecting to a message broker. It uses `^@`, control-@ in ASCII, to represent the null byte at the end of a frame.

```
CONNECT
accept-version:1.2
host:rabbitmq-node

^@
```

In this example, the `CONNECT` command tells the receiving broker that the client would like to connect. It’s followed by two header fields, `accept-version` and `host`, that instruct the broker about the connection the client would like to negotiate. Finally, a blank line is followed by the null byte, indicating the end of the `CONNECT` frame.

If the request is successful, the broker will return a `CONNECTED` frame to the client. This frame is very similar to the `CONNECT` frame:

```
CONNECTED
version:1.2

^@
```

Much like AMQP, STOMP commands are RPC-style requests of the message broker, and some will have replies for the client. The standard set of STOMP commands covers similar concepts as AMQP and MQTT, including connection negotiation, publishing messages, and subscribing to receive messages from a message broker. If you’d like more information on the protocol itself, the specifications are available on the STOMP protocol page at [https://stomp.github.io/](https://stomp.github.io/).

To illustrate how you can leverage STOMP with RabbitMQ, let’s start with a simple message publisher.

#### 9.2.2. Publishing messages

When publishing messages with STOMP, the generic concept of a destination is used to describe where a message should be sent. When using RabbitMQ, a STOMP destination is one of the following:

- A queue automatically created by the STOMP plugin when a message is published or when a client sends a subscription request
- A queue created by normal means, such as an AMQP client or via the management API
- The combination of an exchange and routing key
- The automatically mapped `amq.topic` exchange using the STOMP `topic` destination
- A temporary queue when using `reply-to` headers in a STOMP `SEND` command

Each of these destinations is delimited by a forward slash separating out the destination type, in most cases, and additional information specifying the exchange, routing key, or queue.

To illustrate the use of message destinations and publishing, let’s start by sending a message to a STOMP queue using the stomp.py Python library.

##### Note

The STOMP plugin acts as a translation or proxy layer in RabbitMQ itself. As such, it acts as an AMQP client, creating an AMQP channel and issuing AMQP RPC requests to RabbitMQ itself. STOMP publishers are subject to the same rate limiting and connection blocking that AMQP publishers are limited to, except there are no semantics in the STOMP protocol to let your publisher know that it’s being blocked or throttled.

##### Sending to a STOMP-defined queue

Sending a message via STOMP is very similar to sending a message via MQTT or AMQP. To send a message directly to a queue, use a destination string with a format of `/queue/<queue-name>`.

In the following example, we’ll use the destination `/queue/stomp-messages`. Sending the message to this destination will publish messages into the `stomp-messages` queue using RabbitMQ’s default exchange behavior. If the queue doesn’t exist, the queue will automatically be created. The example code is in the “7.2.2 STOMP Publisher” notebook.

```
import stomp

conn = stomp.Connection()
conn.start()
conn.connect()
conn.send(body='Example Message', destination='/queue/stomp-messages')
conn.disconnect()
```

When the queue is created by the STOMP plugin, it will be created using default argument values by issuing the `Queue.Declare` RPC request internally. This means that if you have an existing queue in the RabbitMQ server that was created using default values, you can still publish to it using the STOMP queue destination. If you have a queue that was created with a message TTL or other custom arguments, you’ll need to use an AMQP-defined queue destination instead.

##### Sending to an AMQP-defined queue

The STOMP plugin has an extended destination syntax that’s specific to RabbitMQ’s implementation of STOMP, allowing for AMQP-defined queues with custom settings to be published to. To achieve this, you first need to create a queue with a maximum length, using the rabbitpy library in the “7.2.2 Queue Declare” notebook.

```
import rabbitpy

with rabbitpy.Connection() as connection:
    with connection.channel() as channel:
        queue = rabbitpy.Queue(channel, 'custom-queue', 
                               arguments={'x-max-length': 10})
        queue.declare()
```

Now that the queue is declared, you’ll need to use the AMQP-defined queue destination syntax. By creating a destination string using the `/amq/queue/<queue-name>` format, the STOMP plugin will be able to route the message to the `custom-queue` queue. This example is in the “7.2.2 Custom Queue” notebook.

```
import stomp

conn = stomp.Connection()
conn.start()
conn.connect()
conn.send(body='Example Message', destination='/amq/queue/custom-queue')
conn.disconnect()
```

The problem with sending to queues directly is that you don’t enjoy the benefit that AMQP messages receive by using the various exchange types and routing keys. Fortunately, the STOMP plugin allows for specially formatted destination strings, which achieve that purpose.

##### Sending to an exchange

To send a message to an exchange using a routing key with the RabbitMQ STOMP plugin, you use the `/exchange/<exchange-name>/<routing-key>` format. This allows you to publish via STOMP as flexibly as you would be able to using AMQP.

The following example from the “7.2.2 Exchange and Queue Declare” notebook will set things up so you can publish a STOMP message through a custom exchange.

```
import rabbitpy

with rabbitpy.Connection() as connection:
    with connection.channel() as channel:
        exchange = rabbitpy.Exchange(channel, 'stomp-routing')
        exchange.declare()
        queue = rabbitpy.Queue(channel, 'bound-queue', 
                               arguments={'x-max-length': 10})
        queue.declare()
        queue.bind(exchange, 'example')
```

With an exchange and queue declared, and the queue bound to the exchange, it’s time to publish a message to the new queue. The following example is from the “7.2.2 Exchange Publishing” notebook.

```
import stomp

conn = stomp.Connection()
conn.start()
conn.connect()
conn.send(body='Example Message', 
          destination='/exchange/stomp-routing/example')
conn.disconnect()
```

With this example under your belt, the flexibility of exchange routing should be apparent. But you can benefit from the flexibility of topic exchange routing without having to declare an exchange or use the longer exchange destination string. Instead, you can send your messages using a STOMP topic destination string.

##### Sending to a STOMP topic

Topic destination strings, like queue destination strings, use a common format recognized by all message brokers that support the STOMP protocol. By formatting a destination string using a format of `/topic/<routing-key>`, messages sent to RabbitMQ via STOMP will be routed through the `amq.topic` exchange to all queues bound to the routing key.

Instead of creating a new queue, you can bind the previously created `bound-queue` queue to the `amq.topic` exchange using a routing key of `#` to receive all messages sent to that exchange. The following example code to bind the queue is in the “7.2.2 Bind Topic” notebook.

```
import rabbitpy

with rabbitpy.Connection() as connection:
    with connection.channel() as channel:
        queue = rabbitpy.Queue(channel, 'bound-queue')
        queue.bind('amq.topic', '#')
```

With the queue bound, you can now publish via STOMP by sending a message to the `/topic/routing.key` routing key using the example from the “7.2.2 Topic Publishing” notebook.

```
import stomp

conn = stomp.Connection()
conn.start()
conn.connect()
conn.send(body='Example Message', 
          destination='/exchange/stomp-routing/example')
conn.disconnect()
```

Between the queue, amq queue, exchange, and topic destination strings, a large portion of message-publishing use cases are covered. But STOMP adds one nice feature that replicates some of the work we did in [chapter 6](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-6/ch06). If you publish a message via STOMP and set a `reply-to` header value, the STOMP plugin will automatically create an RPC reply queue for your publisher to consume messages from.

##### Using temporary reply queues

When your messaging architecture calls for RPC behavior between your publishers and consumers, if you use STOMP there is convenient behavior built into the RabbitMQ STOMP plugin. By setting the `reply-to` header when you send a message via STOMP, the reply queue will automatically be created, setting both the exclusive and auto-delete flags on the queue so that the publishing STOMP connection is the only connection that can consume messages from the reply queue. In addition, the reply queue will automatically be deleted from RabbitMQ should your publishing application be disconnected.

The following example from the “7.2.2 Reply-To” notebook demonstrates how to set the `reply-to` header. We’ll be covering how to consume messages via STOMP in the next section of this chapter, so for now we’ll let the reply queue be automatically removed once the message is published.

```
import stomp

conn = stomp.Connection()
conn.start()
conn.connect()
conn.send(body='Example Message', 
          destination='/exchange/stomp-routing/example',
          headers={'reply-to': 'my-reply-queue'})
conn.disconnect()
```

A major take-away from setting the `reply-to` header is that STOMP messages can have arbitrary message headers. These header values are most analogous to AMQP message properties.

##### AMQP message properties via STOMP

STOMP message headers allow you to pass arbitrary message header values to a message broker. This functionality is what enables the reply-to functionality of auto-creation of reply queues for publishers. Although arbitrary message header values can be useful for your applications, if you’re considering a mixed protocol environment that leverages both STOMP and AMQP, you’ll want to consider a more limited set of message headers that will be available in both protocols. If you use message headers that map to the AMQP message property names, the STOMP plugin will automatically map the header values to AMQP message properties.

The following example, from the “7.2.2 Send with Message Headers” notebook, sets message headers that will be converted to AMQP message properties.

```
import stomp
import time

conn = stomp.Connection()
conn.start()
conn.connect()

conn.send(body='Example message with Headers', 
          destination='/queue/stomp-messages', 
          headers={'app-id': '7.2.2 Example', 
                   'priority': 5,
                   'reply-to': 'reply-to-example',
                   'timestamp': int(time.time())})
conn.disconnect()
```

If you set STOMP message headers that don’t map to AMQP message properties, the AMQP `headers` message property will be populated with those values. As you might expect, when you consume messages with AMQP message properties populated, those values will come through as STOMP message header values.

There’s one exception to this behavior—the `message-id` AMQP message property. This value is automatically set as part of the STOMP protocol and shouldn’t be manually set when sending a message to RabbitMQ using the STOMP protocol.

Publishing messages to RabbitMQ using STOMP has a little more overhead than doing so via AMQP, but there are some nice features of doing so, such as automatic queue creation and auto-creation of reply-to queues. By leveraging the different destination string formats, your messages can be sent directly to a queue or published to an exchange just like with AMQP message publishing. The STOMP plugin automatically maps AMQP semantics into STOMP messages, and STOMP semantics into AMQP messages.

To see this automatic mapping in action, you can consume the messages published in the previous examples. In the next section, we’ll consume messages via STOMP subscribers, including messages with header values.

#### 9.2.3. Consuming messages

Similar to MQTT, STOMP clients are considered subscribers instead of consumers. But because RabbitMQ is first and foremost an AMQP broker, the STOMP plugin treats STOMP subscribers as AMQP consumers that get their messages from RabbitMQ queues. What happens in most cases when you subscribe via STOMP is that a queue will be created for messages to be consumed from.

One of the neater features of the STOMP plugin is that all of the destination string types for sending messages via STOMP exist for subscribing to messages in STOMP. In this section you’ll leverage destination strings in a STOMP subscriber to do the following:

- Consume messages from an automatically created queue
- Consume messages from a predefined AMQP queue
- Consume messages by subscribing to an exchange
- Consume messages by subscribing to a STOMP topic

When sending a message via STOMP, you can set a reply-to header that will automatically create an exclusive auto-delete queue for the STOMP connection. In contrast, consuming the reply-to messages is handled the same way as consuming messages when subscribing to a STOMP-defined queue.

Let’s start by subscribing to the same queue we sent messages to in the last section, the `stomp-messages` queue.

##### Subscribing to a STOMP-defined queue

STOMP-defined queues are queues that are created by RabbitMQ when messages are published using the `/queue/<queue-name>` formatted destination string. In the previous section, we published messages into RabbitMQ using the STOMP `send` command in the “7.2.2 Stomp Publisher” notebook. In the following example from the “7.2.3 Queue Subscriber” notebook, you’ll consume those messages, printing out the message body for each message sent. Because the subscriber code is a bit more complex, let’s step through it in sections.

First, you’ll import all of the Python libraries required to run the subscriber:

```
import stomp
import pprint
import time
```

The Python stomp.py library requires a `ConnectionListener` object to process messages received from a message broker. This object should contain an `on_message` method that will be invoked whenever the subscriber receives a message. In this example, you’ll print out headers if there are any, and the message. In addition, you only want to receive one message and then quit. In the demo listener, you’ll add a flag named `can_stop` that will let the example know when to stop.

```
class Listener(stomp.ConnectionListener):

    can_stop = False
    def on_message(self, headers, message):
        if headers:
            print('\nHeaders:\n')
            pprint.pprint(headers)
        print('\nMessage Body:\n')
        print(message)
        self.can_stop = True
```

With the `Listener` class defined, you can create an instance of the object, a STOMP connection, set the connections listener object, start the connection, and then connect to RabbitMQ:

```
listener = Listener()

conn = stomp.Connection()
conn.set_listener('', listener)
conn.start()
conn.connect()
```

Once a connection is established, the `Connection.subscribe` method sends a STOMP subscription request to RabbitMQ that will automatically acknowledge any received messages.

```
conn.subscribe('/queue/stomp-messages', id=1, ack='auto')
```

To ensure that the code waits until a message is received, you’ll loop, sleeping one second at a time until `Listener.can_stop` is set to `True`:

```
while not listener.can_stop:
    time.sleep(1)
```

Finally, once a message is received, you disconnect from the connection:

```
conn.disconnect()
```

Run the code until you receive the message with defined message headers, from the “7.2.2 Send with Message Headers” notebook. Once it’s received, you should see output similar to [figure 9.5](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-9/ch09fig05).

![Figure 9.5. Output from the “7.2.3 Queue Subscriber” IPython notebook](https://drek4537l1klr.cloudfront.net/roy/Figures/09fig05_alt.jpg)

What you’ll notice is that the AMQP message properties are merged with the STOMP message headers, including `content-length` and `destination`. If there are any values in the AMQP message properties of a message that’s received, they too will be flattened down into the headers that are received as part of a STOMP message.

Like when sending a STOMP message, if you send to a queue destination for a queue that was declared via AMQP using custom arguments, the subscription will fail and you won’t receive any messages. Fortunately, the RabbitMQ team added the AMQ queue destination string format for such scenarios.

##### Subscribing to an AMQP-defined queue

If you need to intermix STOMP subscribers and AMQP consumers that consume from the same queue with custom arguments, or if you need a single STOMP subscriber that receives messages from a queue with custom arguments, you can use the `/amq/queue/<queue-name>` destination format when using your STOMP subscriber.

##### Subscribing to an exchange or topic

Another neat feature of the STOMP plugin is that it allows you to subscribe to an exchange using the `/exchange/<exchange-name>/<binding-key>` format. When you do so, an exclusive, temporary queue will be created and bound for your subscriber that will automatically be removed when your subscriber disconnects. Your subscriber will then be transparently created as a consumer of the queue and receive any messages that are routed to it.

Similarly, if you subscribe to using the `/topic/<binding-key>` format, an exclusive, temporary queue will be created for your subscriber, and it will be automatically bound using the binding key specified. As the binding key is for a topic exchange, it can use the period-delimited namespace with `#` and `*` wildcard semantics, just like when binding a queue using AMQP. Once the temporary queue is created and bound, your subscriber will be set up to receive any messages routed to it.

STOMP subscribers connected to RabbitMQ are proxied into AMQP consumers in the STOMP plugin. By leveraging the various destination string formats, you can bypass the steps required to consume messages via AMQP, but at a cost. The slight overhead of bridging STOMP communications to AMQP will allow your STOMP subscribers to automatically create and bind queues without any additional action required on the part of your code. In addition, by using the AMQ queue destination string, your STOMP subscribers can consume messages from queues shared with AMQP consumers. Of course, with the simplicity of the STOMP protocol, there are some things that the STOMP plugin must do via configuration to successfully support both STOMP and AMQP. In the next section you’ll learn how to configure the STOMP plugin to change client behaviors and connection parameters.

#### 9.2.4. Configuring the STOMP plugin

The STOMP plugin is configured in the core rabbitmq.config file. Like the MQTT plugin, it has its own stanza in the configuration file and uses an Erlang data-structure format. Changes to this file aren’t immediate and require a restart of the RabbitMQ broker.

As the following snippet shows, the top-level configuration of the STOMP plugin is placed in the `rabbitmq_stomp` configuration section.

```
[{rabbit,         [{tcp_listeners,    [5672]}]},
 {rabbitmq_stomp, [{tcp_listeners,    [61613]}]}].
```

[Table 9.3](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-9/ch09table03) details the configuration options for the STOMP plugin.

##### Table 9.3. STOMP plugin configuration options

| Directive | Type | Description | Default value |
| --- | --- | --- | --- |
| default_user | String | The username to use when a STOMP client doesn’t present authentication credentials. | [{login, "guest", passcode, "guest"}] |
| implicit_connect | Integer | Allows for STOMP connections to not send the CONNECT frames upon connection. If enabled, a CONNECTED frame won’t be sent upon connection. | False |
| ssl_listeners | Array | TCP ports to listen on for STOMP over SSL connections. If specified, the top-level rabbit stanza of the configuration file must contain the ssl_options configuration stanza. | [] |
| ssl_cert_login | Boolean | Allows for SSL certificate-based authentication. | False |
| tcp_listeners | Array | TCP ports to listen on for STOMP connections. | [61613] |

#### 9.2.5. Using STOMP in the web browser

Bundled with RabbitMQ is the Web STOMP plugin. Leveraging the SockJS library, Web STOMP is a RabbitMQ-specific extension that adds a websocket-compatible HTTP server that allows web browsers to communicate directly with RabbitMQ. The Web STOMP plugin listens, by default, to port 15670 and supports the entire STOMP protocol, with one small exception—the STOMP heartbeat feature. Due to the nature of SockJS, the library used by Web STOMP to communicate with RabbitMQ, heartbeats can’t be used.

Web STOMP is enabled in the Vagrant virtual machine and includes examples that show you how it can be used. To see multiple examples demonstrating the Web STOMP library and service, visit http://localhost:15670/web-stomp-examples/.

Before you run out and implement Web STOMP as a solution for your application, consider the security implications of opening up your RabbitMQ server to the internet, just as you would with any other application or service. It may make sense to isolate RabbitMQ Web STOMP servers as standalone clusters or servers that bridge to your main servers using tools like the Shovel and Federation plugins to mitigate the impact of malicious or abusive clients. For more information on Web STOMP, visit the plugin page at [www.rabbitmq.com/web-stomp.html](http://www.rabbitmq.com/web-stomp.html).

The STOMP protocol is a human-readable, text-based streaming protocol designed to be simple and easy to implement. Although binary protocols such as AMQP and MQTT may be more efficient on the wire, using less data to transfer the same message, the STOMP protocol has some advantages, especially when using the STOMP plugin with RabbitMQ. The queue creation and binding behaviors require less code on your end, but they also come at a cost. The proxied AMQP connections created by the STOMP plugin that are used to communicate the translated STOMP data with RabbitMQ have overhead that direct AMQP connections do not have.

As with the various options that are available to you in publishing and consuming AMQP messages, I highly recommend that you benchmark the use of STOMP with RabbitMQ prior to using it in production. Each protocol has its advantages and disadvantages, and in some cases, neither is ideal.

In the next section, we’ll cover statelessd, a web application used for high-performance, stateless publishing into RabbitMQ. It was created for scenarios where both the AMQP and STOMP protocols carry too much protocol overhead for single-transaction, fire-and-forget publishing.

### 9.3. Stateless publishing via HTTP

In some scenarios, AMQP, MQTT, STOMP, and other stateful protocols are expensive for environments with high message velocities that can’t maintain long-running connections to RabbitMQ. Because these protocols have a bit of overhead related to connecting prior to being able to take message-related actions, they can be less than ideal, from a performance perspective, for short-lived connections. It was this realization that led to the development of statelessd, an HTTP-to-AMQP publishing proxy that enables high-performance, fire-and-forget message publishing for client applications without requiring the overhead of connection state management.

#### 9.3.1. How statelessd came to be

Sometime in mid-2008 we started to build out our asynchronous messaging architecture at MeetMe.com (then myYearbook.com) as a way to decouple database writes from our PHP-based web application. Initially we built this architecture using Apache ActiveMQ, a Java-based message broker service with support for the STOMP protocol. As foundationally important as memcached was to the success of our database-read scaling, messaging, STOMP, and ActiveMQ allowed us to create consumer applications that fundamentally changed how we thought about database writes, constraining workloads, and scaling out computationally expensive workloads.

As our traffic grew, we encountered scaling issues with ActiveMQ and started to evaluate other brokers. At the time, RabbitMQ showed a lot of promise and supported the same STOMP protocol we used with ActiveMQ. As we migrated to RabbitMQ, we found it to be a good choice for our environment, but it introduced new issues.

One of the things we immediately discovered when we started using RabbitMQ was that the stateful AMQ protocol was very expensive for our PHP application stack. We found that PHP couldn’t maintain the state of open connections and channels across client requests. Every request that a PHP application processed required a new connection to RabbitMQ in order to publish any messages that needed to be sent.

Don’t get me wrong, the amount of time required to create an AMQP connection with RabbitMQ isn’t terribly substantial and can be measured in milliseconds. But when you’re publishing tens of thousands of messages per second, usually once or twice per web request, you’re turning over tens of thousands of connections to RabbitMQ per second. To address this we eventually created statelessd, an HTTP-to-AMQP publishing gateway. This application needed to accept a high velocity of HTTP requests while managing the connection stack required for our message publishing. In addition, it couldn’t be a bottleneck for performance and needed to reliably get messages into RabbitMQ.

After releasing statelessd as open source, we found that we weren’t unique in facing this issue. In 2013, the folks over at Weebly created a statelessd clone named Hare ([https://github.com/Weebly/Hare](https://github.com/Weebly/Hare)) that’s written in Go.

#### 9.3.2. Using statelessd

Designed to require as little overhead as possible, statelessd expects that clients publishing messages through it via HTTP will use native HTTP conventions to convey all the information required to publish native AMQP messages. The first part of the path in the HTTP URI contains the virtual host in RabbitMQ that a message should be published to. Additionally, the exchange and routing key to be used are path components in the request:

```
http://host[:port]/<virtual-host>/<exchange>/<routing-key>
```

For the username and password, HTTP Basic Authentication headers are used. When a request comes in, the statelessd daemon will look to see if the combination of the RabbitMQ username, password, and virtual host exists in its stack of open connections. If it does, the daemon will use that open connection to publish the message posted down to it, returning a “request processed, no content returned” (204) status to the client.

Because statelessd is generally run in a controlled environment where authentication issues are very rare, a design tradeoff for optimum request efficiency was made. If the connection isn’t established, statelessd will internally buffer the message, start an asynchronous process to connect to RabbitMQ, and return a 204 status to the client. Once the connection is established, any buffered messages for the specific combination of credentials will be sent. Should there be a problem connecting, the combination of credentials will be marked as bad, and any subsequent requests will receive a 424 or “request failed due to the nature of a previous request” error.

Statelessd requests use HTTP `POST` to send standard form-encoded key/value pairs that carry the body and properties of the message to be published. Valid keys for statelessd requests include body, the value of the actual message body itself, and the standard AMQP message property names, with the dash character replaced with an underscore. For example, to set the `message-id` property, the payload of the request should include a value assigned to the `message_id` key. For a full list of the valid keys in a statelessd request payload, refer to the documentation at [https://github.com/gmr/statelessd](https://github.com/gmr/statelessd).

#### 9.3.3. Operational architecture

Statelessd is designed to be run on the same server as the RabbitMQ servers that messages should be published to. It’s a Python-based daemon that’s usually configured to have a backend process running for each CPU core on the server. Each backend process has its own HTTP port that it listens on. These processes are aggregated and can be proxied by a single port using a reverse proxy server like Nginx ([figure 9.6](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-9/ch09fig06)), providing a scale-out solution that has benchmarked up to hundreds of thousands of messages per second per server.

![Figure 9.6. Statelessd operational architecture](https://drek4537l1klr.cloudfront.net/roy/Figures/09fig06_alt.jpg)

If you need to run statelessd on multiple servers, each server’s Nginx instance can be added to a load balancer, distributing the publishing requests across multiple servers in a cluster. Statelessd includes a URL endpoint for gathering statistical data that can be used to compare message-throughput rates between a cluster of statelessd nodes and RabbitMQ servers. Refer to the statelessd documentation at [https://github.com/gmr/statelessd](https://github.com/gmr/statelessd) for information on installing and configuring statelessd.

#### 9.3.4. Publishing messages via statelessd

To publish a message to RabbitMQ, any standard HTTP library should do. For this example, we’ll use the Python library named `requests`. Prior to publishing a message, you should create and bind a queue to publish messages to. The following code from the “7.4.4 Queue Setup” notebook does just that.

```
import rabbitpy

with rabbitpy.Connection() as connection:
    with connection.channel() as channel:
        queue = rabbitpy.Queue(channel, 'statelessd-messages')
        queue.declare()
        queue.bind('amq.topic', '#')
```

With the queue declared, all that’s left is to publish a message. Statelessd should already be running in the Vagrant virtual machine, so running the following code from “7.4.4 Publish Message” will publish a message to the “statelessd-messages” queue.

```
import requests

payload = {'body': 'from statelessd', 'app_id': 'example'}
response = requests.post('http://localhost:8900/%2f/amq.topic/example',
                          auth=('guest', 'guest'),
                          data=payload)
```

To verify that the message is published, navigate to the RabbitMQ management interface at http://localhost:15672/#/queues/%2F/statelessd-messages.

Now that you’ve published a message through statelessd, it’s worth reiterating that statelessd solves a specific use case for publishing messages to RabbitMQ. As you think about where it may fit into your messaging architecture, consider the goals and performance of statelessd. It was designed to enable high-velocity publishing from many different publishing applications. It doesn’t support the full AMQP protocol and doesn’t support many of the more advanced publishing features in RabbitMQ, like Publisher Confirms or transactional publishing. It isn’t for every project, but it’s worth keeping in the back of your mind for projects were it does add tremendous value.

### 9.4. Summary

RabbitMQ goes beyond the AMQP goal of vendor and platform neutrality by supporting additional protocols such as STOMP and MQTT. In addition, there’s a vibrant ecosystem of plugins and applications that allow applications to speak to RabbitMQ in different ways. For example, instead of using a protocol like AMQP for mobile applications that may be prone to network interruptions and slow transfer speeds, use MQTT, a protocol designed for such a task. Applications like Hare and statelessd exist to allow for more efficient message publishing.

Additionally, here’s a list of plugins that add additional protocol support to RabbitMQ:

- rabbithub—Adds PubSubHubBub support to RabbitMQ ([https://github.com/tonyg/rabbithub](https://github.com/tonyg/rabbithub))
- udp_exchange—Uses UDP to publish messages to RabbitMQ ([https://github.com/tonyg/udp-exchange](https://github.com/tonyg/udp-exchange))
- rabbitmq-smtp—An SMTP-to-AMQP gateway for RabbitMQ ([https://github.com/rabbitmq/rabbitmq-smtp](https://github.com/rabbitmq/rabbitmq-smtp))
- rabbitmq-xmpp—An XMPP-to-AMQP gateway for RabbitMQ ([https://github.com/tonyg/rabbitmq-xmpp](https://github.com/tonyg/rabbitmq-xmpp))

These examples demonstrate the variety of messaging protocols that can be used with RabbitMQ. Although the rabbitmq-smtp plugin may have limited use cases compared to the Web STOMP plugin, your application may have unique requirements, and I encourage you to make sure you’re using the right tool for the job when it comes to communicating with RabbitMQ.
