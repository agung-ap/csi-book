# Chapter 3. An in-depth tour of message properties

### This chapter covers

- Message properties and their impact on message delivery
- Using message properties to create a contract with publishers and consumers

In [chapter 1](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-1/ch01), I detailed how I set out to decouple member login events from database writes that were causing delays for members logging into a website. The advantages of doing so quickly became clear to our entire engineering organization, and using a loosely coupled architecture for database writes took on a life of its own. Over time, we began to leverage this architecture in new applications we were developing. No longer were we just processing member login events, we were using this architecture for account deletions, email message generation, and any application event that could be performed asynchronously. Events were being published through the message bus to consumer applications, each performing its own unique task. At first we put little thought into what the message contained and how it was formatted, but it soon became apparent that standardization was needed.

With the different message types and no standardization of message format, it became difficult to predict how a specific message type would be serialized and what data a particular message type would contain. Developers would publish messages in a format that made sense for their application and their application alone. Although they accomplished their own tasks, this mindset was shortsighted. We began to observe that messages could be reused across multiple applications, and the arbitrary formatting decisions were becoming problematic. In an effort to ease the growing pains around these and related issues, we paid more attention to describing the message being sent, both in documentation and as part of the message itself.

To provide a consistent method for self-describing our messages, we looked to AMQP’s `Basic.Properties`, a data structure that’s passed along with every message published via AMQP into RabbitMQ. Leveraging `Basic.Properties` opened the doors to more intelligent consumers—consumer applications that could automatically deserialize messages, validate the origin of a message and its type prior to processing, and much more. In this chapter we’ll look at `Basic.Properties` in depth, covering each property and its intended use.

### 3.1. Using properties properly

You’ll recall from [chapter 2](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-2/ch02) that when you’re publishing a message with RabbitMQ, your message is composed of three low-level frame types from the AMQP specification: the `Basic.Publish` method frame, the content header frame, and the body frame. These three frame types work together in sequence to get your messages where they’re supposed to go and to ensure that they’re intact when they get there ([figure 3.1](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-3/ch03fig01)).

![Figure 3.1. The three components of a message published into RabbitMQ](https://drek4537l1klr.cloudfront.net/roy/Figures/03fig01_alt.jpg)

The message properties contained in the header frame are a predefined set of values specified by the `Basic.Properties` data structure ([figure 3.2](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-3/ch03fig02)). Some properties, such as `delivery-mode`, have well-defined meanings in the AMQP specification, whereas others, such as `type`, have no exact specification.

![Figure 3.2. Basic.Properties, including the deprecated cluster-id property from AMQP-0-8](https://drek4537l1klr.cloudfront.net/roy/Figures/03fig02_alt.jpg)

In some cases, RabbitMQ uses well-defined properties to implement specific behaviors with regard to the message. An example of this is the previously mentioned `delivery-mode` property. The value of `delivery-mode` will tell RabbitMQ if it’s allowed to keep the message in memory when the message is placed in a queue or if it must store the message to disk first.

##### Tip

Although it’s advisable to use message properties to describe your message, you should ensure that all data needed by applications consuming messages is contained in the message body. Should you eventually venture to bridging protocols, such as MQTT with RabbitMQ, you’ll want to make sure your messages don’t lose meaning when AMQP-specific message semantics aren’t available.

As we went through the message standardization process, the AMQP message properties provided a useful starting point for defining and carrying metadata about a message. That metadata, in turn, allows the reader to create strict contracts between publishers and consumers. Many of the attributes, from the `content-type` and message type (`type`) to the `timestamp` and application ID (`app-id`), have proven to be very useful not just for consistency in the engineering process but in day-to-day operational use. In short, by using message properties, you can create self-describing messages, similar to how XML is considered self-describing data markup.

In this chapter, we’ll look at each of the basic properties outlined in [figure 3.2](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-3/ch03fig02):

- Using the `content-type` property to let consumers know how to interpret the message body
- Using `content-encoding` to indicate that the message body may be compressed or encoded in some special way
- Populating `message-id` and `correlation-id` to uniquely identify messages and message responses, tracking the message through your workflow
- Leveraging the `timestamp` property to reduce message size and create a canonical definition of when a message was created
- Expiring messages with the `expiration` property
- Telling RabbitMQ to write your messages to disk-backed or in-memory queues using `delivery-mode`
- Using `app-id` and `user-id` to help track down troublesome publishers
- Using the `type` property to define a contract with publishers and consumers
- Routing reply messages when implementing a pattern using the `reply-to` property
- Using the `headers` table property for free-form property definitions and RabbitMQ routing

We’ll also touch on why you’ll want to avoid using the `priority` property and on what happened to the `cluster-id` property and why you can’t use it.

I’ll discuss the properties in the order of this list, but I’ve also included a handy table at the end of the chapter listing each property in alphabetical order along with its data type, an indication of whether it’s used by a broker or application, and instructions for its use.

##### Note

When I use the term “contract” with regard to messaging, I’m referring to a specification for the format and contents of a message. In programming, the term is often used to describe the predefined specification of APIs, objects, and systems. Contract specifications often contain precise information about the data transmitted and received, such as the data type, its format, and any conditions that should be applied to it.

### 3.2. Creating an explicit message contract with content-type

As I quickly found, it’s easy to come up with new uses for messages that are published through RabbitMQ. Our initial consumer applications were written in Python, but soon messages were being consumed by applications written in PHP, Java, and C.

When messages are not self-describing about their payload format, your applications are more likely to break due to the use of implicit contracts, which are inherently error-prone. By using self-describing messages, programmers and consumer applications don’t need to guess how to deserialize the data received by messages or if deserialization is even necessary.

The `Basic.Properties` data structure specifies the `content-type` property for conveying the format of the data in the message body ([figure 3.3](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-3/ch03fig03)).

![Figure 3.3. The content-type property is the first property in Basic.Properties.](https://drek4537l1klr.cloudfront.net/roy/Figures/03fig03_alt.jpg)

Like in the various standardized HTTP specifications, `content-type` conveys the MIME type of the message body. If your application is sending a JSON-serialized data value, for example, setting the `content-type` property to `application/json` will allow for yet-to-be-developed consumer applications to inspect the message type upon receipt and correctly decode the message.

##### Thoughts on self-describing messages and message content

It’s wise to use a standard serialization format such as JSON, Msgpack ([http://msgpack.org/](http://msgpack.org/)), or XML. These formats allow for any number of consumer applications to be written in just about any programming language. Because the data is self-describing in these formats, it’s easier to write future consumer applications and it’s easier to decode messages on the wire outside of your core application.

In addition, by specifying the serialization format in the `content-type` property, you can future-proof your consumer applications. When consumers can automatically recognize the serialization formats that they support and can selectively process messages, you don’t have to worry about what happens when a new serialization format is used and routed to the same queues.

If you’re using a framework for your consumer code, you may want to make it smart about how it deals with the messages it receives. By having the framework preprocess the message prior to handing it off to your consumer code, message bodies can automatically be deserialized and loaded into native data structures in your programming language. For example, in Python your framework could detect the message serialization type from the `content-type` header and, using this information, it could automatically deserialize the message body and place the contents into a `dict`, `list`, or other native data type. This would ultimately reduce the complexity of your code in the consumer application.

### 3.3. Reducing message size with gzip and content-encoding

Messages sent over AMQP aren’t compressed by default. This can be problematic with overly verbose markup such as XML, or even with large messages using less markup-heavy formats like JSON or YAML. Your publishers can compress messages prior to publishing them and decompress them upon receipt, similarly to how web pages can be compressed on the server with gzip and the browser can decompress them on the fly prior to rendering.

To make this process explicit, AMQP specifies the `content-encoding` property ([figure 3.4](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-3/ch03fig04)).

![Figure 3.4. The content-encoding property indicates whether special encodings have been applied to the message body.](https://drek4537l1klr.cloudfront.net/roy/Figures/03fig04_alt.jpg)

It’s preferable not to change the contract of the message being published and consumed in production, thus minimizing any potential effects on preexisting code. But if message size is impacting overall performance and stability, using the `content-encoding` header will allow your consumers to prequalify messages, ensuring they can decode whatever format the message body is sent as.

##### Note

Don’t confuse `content-encoding` with `content-type`. Like in the HTTP specification, `content-encoding` is used to indicate some level of encoding beyond the `content-type`. It’s a modifier field that’s often used to indicate that the content of the message body has been compressed using gzip or some other form of compression. Some AMQP clients automatically set the `content-encoding` value to UTF-8, but this is incorrect behavior. The AMQP specification states that `content-encoding` is for storing the MIME content encoding.

To draw a parallel, MIME email markup uses a `content-encoding` field to indicate the encoding for each of the different parts of the email. In email, the most common encoding types are Base64 and Quoted-Printable. Base64 encoding is used to ensure binary data transferred in the message doesn’t violate the text-only SMTP protocol. For example, if you’re creating an HTML-based email message with embedded images, the embedded images are likely to be Base64 encoded.

Unlike SMTP, however, AMQP is a binary protocol. The content in the message body is transferred as is and isn’t encoded or transformed in the message marshaling and remarshaling process. Without regard to format, any content may be passed without concern of violating the protocol.

##### Leveraging consumer frameworks

If you’re using a framework to write your consumer code, it can use the `content-encoding` property to automatically decode messages upon receipt. By preprocessing, deserializing, and decompressing messages prior to calling your consumer code, the logic and code in a consumer application can be simplified. Your consumer-specific code will be able to focus on the task of processing the message body.

We’ll discuss consumer frameworks in more detail in [chapter 5](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-5/ch05).

Combined with the `content-type` property, the `content-encoding` property empowers consumer applications to operate in an explicit contract with the publishers. This allows you to write future-proof code, hardening it against unexpected errors caused by changes in message format. For example, at some point in your application’s lifetime you may find that bzip2 compression is better for your message content. If you code your consumer applications to examine the `content-encoding` property, they can then reject messages that they can’t decode. Consumers that only know how to decompress using zlib or deflate would reject the new bzip2 compressed messages, leaving them in a queue for other consumer applications that can decompress bzip2 messages.

### 3.4. Referencing messages with message-id and correlation-id

In the AMQP specification, `message-id` and `correlation-id` are specified “for application use” and have no formally defined behavior ([figure 3.5](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-3/ch03fig05)). This means that as far as the specification is concerned, you can use them for whatever purpose you like. Both fields allow for up to 255 bytes of UTF-8 encoded data and are stored as uncompressed values embedded in the `Basic.Properties` data structure.

![Figure 3.5. The message-id and correlation-id properties can be used to track individual messages and response messages as they flow through your systems.](https://drek4537l1klr.cloudfront.net/roy/Figures/03fig05_alt.jpg)

#### 3.4.1. Message-id

Some message types, such as a login event, aren’t likely to need a unique message ID associated with them, but it’s easy to imagine types of messages that would, such as sales orders or support requests. The `message-id` property enables the message to carry data in the header that uniquely identifies it as it flows through the various components in a loosely coupled system.

#### 3.4.2. Correlation-id

Although there’s no formal definition for the `correlation-id` in the AMQP specification, one use is to indicate that the message is a response to another message by having it carry the `message-id` of the related message. Another option is to use it to carry a transaction ID or other similar data that the message is referencing.

### 3.5. Born-on dating: the timestamp property

One of the more useful fields in `Basic.Properties` is the `timestamp` property ([figure 3.6](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-3/ch03fig06)). Like `message-id` and `correlation-id`, `timestamp` is specified as “for application use.” Even if your message doesn’t use it, the `timestamp` property is very helpful when you’re trying to diagnose any type of unexpected behavior in the flow of messages through RabbitMQ. By using the `timestamp` property to indicate when a message was created, consumers can gauge performance in message delivery.

![Figure 3.6. The timestamp property can carry an epoch value to specify when the message was created.](https://drek4537l1klr.cloudfront.net/roy/Figures/03fig06_alt.jpg)

Is there a service level agreement (SLA) that your processes need to enforce? By evaluating the `timestamp` from the message properties, your consumer applications can decide whether they will process a message, discard it, or even publish an alert message to a monitoring application to let someone know that the age of a message is exceeding a desired value.

The timestamp is sent as a Unix epoch or integer-based timestamp indicating the number of seconds since midnight on January 1, 1970. For example, February 2, 2002, at midnight would be represented as the integer value 1329696000. As an encoded integer value, the timestamp only takes up 8 bytes of overhead in the message. Unfortunately there’s no time zone context for the timestamp, so it’s advisable to use UTC or another consistent time zone across all of your messages. By standardizing on the time zone up front, you’ll avoid any future problems that may result from your messages traveling across time zones to geographically distributed RabbitMQ brokers.

### 3.6. Automatically expiring messages

The `expiration` property tells RabbitMQ when it should discard a message if it hasn’t been consumed. Although the `expiration` property ([figure 3.7](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-3/ch03fig07)) existed in both the 0-8 and 0-9-1 versions of the AMQP specification, it wasn’t supported in RabbitMQ until the release of version 3.0. In addition, the specification of the expiration property is a bit odd; it’s specified “for implementation use, no formal behavior,” meaning RabbitMQ can implement its use however it sees fit. One final oddity is that it’s specified as a short string, allowing for up to 255 characters, whereas the other property that represents a unit of time, `timestamp`, is an integer value.

![Figure 3.7. To use the expiration property in RabbitMQ, set the string value to a Unix epoch timestamp designating the maximum value for which the message is still valid.](https://drek4537l1klr.cloudfront.net/roy/Figures/03fig07_alt.jpg)

Because of the ambiguity in the specification, the `expiration` value is likely to have different implications when using different message brokers or even different versions of the same message broker. To auto-expire messages in RabbitMQ using the `expiration` property, it must contain a Unix epoch or integer-based timestamp, but stored as a string. Instead of storing an ISO-8601 formatted timestamp such as `"2002-02-20T00:00:00-00"`, you must set the string value to the equivalent value of `"1329696000"`.

When using the `expiration` property, if a message is published to the server with an expiration timestamp that has already passed, the message will not be routed to any queues, but instead will be discarded.

It’s also worth noting that RabbitMQ has other functionality to expire your messages only under certain circumstances. In declaring a queue, you can pass an `x-message-ttl` argument along with the queue definition. This value should also be a Unix epoch timestamp, but it uses millisecond precision (`value*1000`) as an integer value. This value instructs the queue to automatically discard messages once the specified time has passed. The `x-message-ttl` queue argument and the merits of its use will be discussed in more detail in [chapter 5](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-5/ch05).

### 3.7. Balancing speed with safety using delivery-mode

The `delivery-mode` property is a byte field that indicates to the message broker that you’d like to persist the message to disk prior to it being delivered to any awaiting consumers ([figure 3.8](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-3/ch03fig08)). In RabbitMQ, persisting a message means that it will remain in the queue until it’s consumed, even if the RabbitMQ server is restarted. The `delivery-mode` property has two possible values: `1` for a non-persisted message and `2` for a persisted message.

![Figure 3.8. The delivery-mode property instructs RabbitMQ whether it must store the message on disk when placing it in a queue or if it may keep the message only in memory.](https://drek4537l1klr.cloudfront.net/roy/Figures/03fig08_alt.jpg)

##### Note

When you’re first learning the various terms and settings in RabbitMQ, message persistence can often be confused with the `durable` setting in a queue. A queue’s durability attribute indicates to RabbitMQ whether the definition of a queue should survive a restart of the RabbitMQ server or cluster. Only the `delivery-mode` of a message will indicate to RabbitMQ whether a message should be persisted or not. A queue may contain persisted and non-persisted messages. Queue durability is discussed in [chapter 4](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-4/ch04).

As illustrated in [figure 3.9](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-3/ch03fig09), specifying your message as a non-persisted message will allow RabbitMQ to use memory-only queues.

![Figure 3.9. Publishing messages to memory-only queues](https://drek4537l1klr.cloudfront.net/roy/Figures/03fig09_alt.jpg)

Because memory IO is inherently faster than disk IO, specifying `delivery-mode` as 1 will deliver your messages with as little latency as possible. In my web application login use case, the choice of delivery mode may be easier than in other use cases. Although it’s desirable not to lose any login events if a RabbitMQ server fails, it’s usually not a hard requirement. If member login event data is lost, it’s not likely the business will suffer. In that case, we’d use `delivery-mode:1`. But if you’re using RabbitMQ to publish financial transaction data, and your application architecture is focused on guaranteed delivery instead of message throughput, you can enable persistence by specifying `delivery-mode:2`. As illustrated in [figure 3.10](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-3/ch03fig10), when specifying a delivery mode of 2, messages are persisted to a disk-backed queue.

![Figure 3.10. Publishing messages to disk-backed queues](https://drek4537l1klr.cloudfront.net/roy/Figures/03fig10_alt.jpg)

Although this provides some guarantee that messages won’t be lost in the event of a message broker crash, it comes with potential performance and scaling concerns. The `delivery-mode` property has such a significant impact on delivery and performance that it’s covered in more detail in [chapter 4](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-4/ch04).

### 3.8. Validating message origin with app-id and user-id

The `app-id` and `user-id` properties provide another level of information about a message and have many potential uses ([figure 3.11](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-3/ch03fig11)). As with other properties that can be used to specify a behavioral contract in the message, these two properties can carry information that your consumer applications can validate prior to processing.

![Figure 3.11. The user-id and app-id properties are the last of the Basic.Properties values, and they can be used to identify the message source.](https://drek4537l1klr.cloudfront.net/roy/Figures/03fig11_alt.jpg)

#### 3.8.1. app-id

The `app-id` property is defined in the AMQP specification as a “short-string,” allowing for up to 255 UTF-8 characters. If your application has an API-centric design with versioning, you could use the `app-id` to convey the specific API and version that were used to generate the message. As a method of enforcing a contract between publisher and consumer, examining the `app-id` prior to processing allows the application to discard the message if it’s from an unknown or unsupported source.

Another possible use for `app-id` is in gathering statistical data. For example, if you’re using messages to convey login events, you could set the `app-id` property to the platform and version of the application triggering the login event. In an environment where you may have web-based, desktop, and mobile client applications, this would be a great way to transparently both enforce a contract and extract data to keep track of logins by platform, without ever inspecting the message body. This is especially handy if you want to have single-purposed consumers allowing for a stats-gathering consumer listening to the same messages as your login processing consumer. By providing the `app-id` property, the stats-gathering consumer wouldn’t have to deserialize or decode the message body.

##### Tip

When trying to track down the source of rogue messages in your queues, enforcing the use of `app-id` can make it easier to trace back the source of the bad messages. This is especially useful in larger environments where many applications share the same RabbitMQ infrastructure, and a new publisher may erroneously use the same exchange and routing key as an existing publishing application.

#### 3.8.2. user-id

In the use case of user authentication, it may seem obvious to use the `user-id` property to identify the user who has logged in, but in most cases this isn’t advisable. RabbitMQ checks every message published with a value in the `user-id` property against the RabbitMQ user publishing the message, and if the two values don’t match, the message is rejected. For example, if your application is authenticating with RabbitMQ as the user “www”, and the `user-id` property is set to “linus”, the message will be rejected.

Of course, if your application is something like a chat room or instant messaging service, you may very well want a user in RabbitMQ for every user of your application, and you would indeed want to use `user-id` to identify the actual user logging into your application.

### 3.9. Getting specific with the message type property

The 0-9-1 version of the AMQP specification defines the `Basic.Properties type` property as the “message type name,” saying that it’s for application use and has no formal behavior ([figure 3.12](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-3/ch03fig12)). Although the `routing-key` value, in combination with the `exchange`, may often convey as much information about the message as is needed to determine the content of a message, the `type` property adds another tool your applications can use to determine how to process a message.

![Figure 3.12. The type property is a free-form string value that can be used to define the message type.](https://drek4537l1klr.cloudfront.net/roy/Figures/03fig12_alt.jpg)

##### When self-describing serialization formats aren’t fast enough

The `type` property can be very useful when creating self-describing messages, especially when the message body isn’t serialized in a self-describing data format. Self-describing formats like JSON and XML are considered by some to be too verbose. They can also carry unnecessary overhead on the wire or in memory, as well as being slower to serialize and deserialize in some languages. If any of these concerns ring true to you, you can choose a serialization format like Apache Thrift ([http://thrift.apache.org/](http://thrift.apache.org/)) or Google’s Protobuf ([https://code.google.com/p/protobuf/](https://code.google.com/p/protobuf/)). Unlike MessagePack ([http://msgpack.org/](http://msgpack.org/)), these binary encoded message formats aren’t self-describing and require an external definition file for serialization and deserialization. This external dependency and the lack of self-description allows for smaller payloads on the wire but has tradeoffs of its own.

When trying to create self-describing AMQP messages that allow for an enforceable contract between publisher and consumer, a message payload that isn’t self-describing requires the message payload to be deserialized prior to determining whether the message is OK for the consumer to process. In this case, the `type` property can be used to specify the record type or the external definition file, enabling the consumer to reject messages it can’t process if it doesn’t have access to the proper .thrift or .proto file required to process the message.

In my example of publishing member login events, when it came time to store the events in a data warehouse, we found it useful to carry the message type with the message. To prepare the events for storage in the data warehouse, they’re first stored in a temporary location, and then a batch process reads them and stores them in the database. Because this is a very generic process, a single consumer performs the extract phase of the extract-transform-load (ETL) process using a generic queue to process all the messages. The ETL queue consumer processes multiple types of messages and uses the `type` property to decide which system, table, or cluster to store the extracted data in.

##### Note

ETL processing is a standard practice where OLTP data is extracted and eventually loaded into a data warehouse for reporting purposes. If you’d like to learn more about ETL processing, Wikipedia has a very good article describing each phase, ETL performance, common challenges, and related subjects ([http://en.wikipedia.org/wiki/Extract,_transform,_load](http://en.wikipedia.org/wiki/Extract,_transform,_load)).

### 3.10. Using reply-to for dynamic workflows

In a confusing and terse definition in the AMQP specification, the `reply-to` property has no formally defined behavior and is also specified for application use ([figure 3.13](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-3/ch03fig13)). Unlike the previously mentioned proprieties, it has a caveat: `reply-to` may be used to designate a private response queue for replies to a message. Although the exact definition of a private response queue isn’t stated in the AMQP specification, this property could easily carry either a specific queue name or a routing key for replies in the same exchange through which the message was originally published.

![Figure 3.13. The reply-to property has no formal definition but can carry a routing key or queue name value that can be used for replies to the message.](https://drek4537l1klr.cloudfront.net/roy/Figures/03fig13_alt.jpg)

##### Warning

There’s a caveat in the 0-9-1 version of the AMQP specification for `reply-to` that states it “may hold the name of a private response queue, when used in request messages.” There’s enough ambiguity in the definition of this property that it should be used with caution. Although it’s not likely that future versions of RabbitMQ will enforce routability of response messages at publishing time, it’s better to be safe than sorry. Given RabbitMQ’s behavior with regard to the `user-id` property and the ambiguity of the specification with regard to this property, it wouldn’t be unreasonable for RabbitMQ to deny publishing of a message if response messages wouldn’t be routable due to information in the `reply-to` property.

### 3.11. Custom properties using the headers property

The `headers` property is a key/value table that allows for arbitrary, user-defined keys and values ([figure 3.14](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-3/ch03fig14)). Keys can be ASCII or Unicode strings that have a maximum length of 255 characters. Values can be any valid AMQP value type.

![Figure 3.14. The headers property allows for arbitrary key/value pairs in the message properties.](https://drek4537l1klr.cloudfront.net/roy/Figures/03fig14_alt.jpg)

Unlike the other properties, the `headers` property allows you to add whatever data you’d like to the headers table. It also has another unique feature: RabbitMQ can route messages based upon the values populated in the `headers` table instead of relying on the routing key. Routing messages via the `headers` property is covered in [chapter 6](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-6/ch06).

### 3.12. The priority property

As of RabbitMQ 3.5.0, the `priority` field has been implemented as per the AMQP specification. It’s defined as an integer with possible values of 0 through 9 to be used for message prioritization in queues. As specified, if a message with a priority of 9 is published, and subsequently a message with a priority of 0 is published, a newly connected consumer would receive the message with the priority of 0 before the message with a priority of 9. Interestingly, RabbitMQ implements the `priority` field as an unsigned byte, so priorities could be anywhere from 0 to 255, but the priority should be limited to 0 through 9 to maintain interoperability with the specification. See [figure 3.15](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-3/ch03fig15).

![Figure 3.15. The priority property can be used to designate priority in queues for the message.](https://drek4537l1klr.cloudfront.net/roy/Figures/03fig15_alt.jpg)

### 3.13. A property you can’t use: cluster-id/reserved

There’s only one more property to call to your attention, and only for the purpose of letting you know that you can’t use it. You most likely noticed the `cluster-id` property that’s crossed out in the previous figures ([figure 3.16](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-3/ch03fig16)).

![Figure 3.16. The cluster-id property was renamed as reserved in AMQP 0-9-1 and must not be used.](https://drek4537l1klr.cloudfront.net/roy/Figures/03fig16_alt.jpg)

The `cluster-id` property was defined in AMQP 0-8 but was subsequently removed, and RabbitMQ never implemented any sort of behavior around it. AMQP 0-9-1 renamed it to `reserved` and states that it must be empty. Although RabbitMQ currently doesn’t enforce the specification requiring it to be empty, you’re better off avoiding it altogether.

### 3.14. Summary

By using `Basic.Properties` properly, your messaging architecture can create strict behavioral contracts between publishers and consumers. In addition, you’ll be able to future-proof your messages for integration projects that you may not have considered in your initial application and message specifications.

[Table 3.1](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-3/ch03table01) provides a quick overview of these properties. You can come back and reference it as you’re figuring out the appropriate use of properties in your applications.

##### Table 3.1. Properties made available by `Basic.Properties`, including their type, whether the broker or application can use them, and either the specified use or suggestions for use.

| Property | Type | For use by | Suggested or specified use |
| --- | --- | --- | --- |
| app-id | short-string | Application | Useful for defining the application publishing the messages. |
| content-encoding | short-string | Application | Specify whether your message body is encoded in some special way, such as zlib, deflate, or Base64. |
| content-type | short-string | Application | Specify the type of the message body using mime-types. |
| correlation-id | short-string | Application | If the message is in reference to some other message or uniquely identifiable item, the correlation-id is a good way to indicate what the message is referencing. |
| delivery-mode | octet | RabbitMQ | A value of 1 tells RabbitMQ it can keep the message in memory; 2 indicates it should also write it to disk. |
| expiration | short-string | RabbitMQ | An epoch or Unix timestamp value as a text string that indicates when the message should expire. |
| headers | table | Both | A free-form key/value table that you can use to add additional metadata about your message; RabbitMQ can route based upon this if desired. |
| message-id | short-string | Application | A unique identifier such as a UUID that your application can use to identify the message. |
| priority | octet | RabbitMQ | A property for priority ordering in queues. |
| timestamp | timestamp | Application | An epoch or Unix timestamp value that can be used to indicate when the message was created. |
| type | short-string | Application | A text string your application can use to describe the message type or payload. |
| user-id | short-string | Both | A free-form string that, if used, RabbitMQ will validate against the connected user and drop messages if they don’t match. |

Beyond using properties for self-describing messages, these properties can carry valuable metadata about your message that will allow you to create sophisticated routing and transactional mechanisms, without having to pollute the message body with contextual information that pertains to the message. When evaluating the message for delivery, RabbitMQ will leverage specific properties, such as the `delivery-mode` and the `headers` table, to ensure that your messages are delivered how and where you specify. But these values are just the tip of the iceberg when it comes to making sure your message delivery is bulletproof.
