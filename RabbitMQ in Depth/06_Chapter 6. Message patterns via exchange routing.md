# Chapter 6. Message patterns via exchange routing

### This chapter covers

- The four basic types of exchanges available through RabbitMQ, plus a plugin exchange
- Which type of exchange is appropriate for your application architecture
- How the use of exchange-to-exchange routing can add numerous routing options for your messages

Perhaps RabbitMQ’s greatest strength is the flexibility it offers for routing messages to different queues based upon routing information provided by the publisher. Whether it’s sending messages to a single queue, multiple queues, exchanges, or another external source provided by an exchange plugin, RabbitMQ’s routing engine is both extremely fast and highly flexible. Although your initial application may not need complex routing logic, starting with the right type of exchange can have a dramatic impact on your application architecture.

In this chapter, we’ll take a look at four basic types of exchanges and the types of architectures that can benefit from them:

- Direct exchange
- Fanout exchange
- Topic exchange
- Headers exchange

We’ll start with some simple message routing using the *direct exchange*. From there, we’ll use a *fanout exchange* to send images to both a facial-recognition consumer and an image-hashing consumer. A *topic exchange* will allow us to selectively route messages based upon wildcard matching in the routing key, and a *headers exchange* presents an alternative approach to message routing using the message itself. I’ll dispel the myth that certain exchanges aren’t as performant as others, and then I’ll show you how exchange-to-exchange binding can open up an *Inception*-like reality, but for message routing, not dreams. Finally, we’ll cover the *consistent-hashing exchange*, a plugin exchange type that should help if your consumer throughput needs to grow beyond the capabilities of multiple consumers sharing a single queue.

### 6.1. Simple message routing using the direct exchange

The direct exchange is useful when you’re going to deliver a message with a specific target, or a set of targets. Any queue that’s bound to an exchange with the same routing key that’s being used to publish a message will receive the message. RabbitMQ uses string equality when checking the binding and doesn’t allow any type of pattern matching when using a direct exchange ([figure 6.1](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-6/ch06fig01)).

![Figure 6.1. Using a direct exchange, messages published by publisher 1 will be routed to queue 1 and queue 2, whereas messages published by publisher 2 will be routed to queues 2 and 3.](https://drek4537l1klr.cloudfront.net/roy/Figures/06fig01_alt.jpg)

As illustrated in [figure 6.1](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-6/ch06fig01), multiple queues can be bound to a direct exchange using the same routing key. Every queue bound with the same routing key will receive all of the messages published with that routing key.

The direct exchange type is built into RabbitMQ and doesn’t require any additional plugins. Creating a direct exchange is as simple as declaring an exchange type as “direct,” as demonstrated in this snippet in the “6.1 Direct Exchange” notebook.

```
1234567import rabbitpy

with rabbitpy.Connection() as connection:                              1
    with connection.channel() as channel:                              2
        exchange = rabbitpy.Exchange(channel, 'direct-example',        3
                                     exchange_type='direct')
        exchange.declare()                                             4
```

- ***1* Connects to RabbitMQ**
- ***2* Opens a channel on the connection**
- ***3* Creates a rabbitpy.Exchange object**
- ***4* Declares the exchange**

Because of its simplicity, the direct exchange is a good choice for routing reply messages used in RPC messaging patterns. Writing decoupled applications using RPC is an excellent way to create highly scalable applications with different components that are provisioned across multiple servers.

This architecture is the basis for our first example. You’ll write an RPC worker that consumes images to perform facial recognition and then publishes them back to the publishing application. In computationally complex processes such as image or video processing, leveraging remote RPC workers is a great way to scale an application. If this application were running in the cloud, for example, the application publishing the request could live on small-scale virtual machines, and the image processing worker could make use of larger hardware—or, if the workload supported it, on GPU-based processing.

To get started building the example application, you’ll write the worker, a single purpose image-processing consumer.

#### 6.1.1. Creating the application architecture

Suppose you wanted to implement a web-based API service that processes photos uploaded by mobile phones. The pattern illustrated in [figure 6.1](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-6/ch06fig01) can be implemented as a lightweight, highly scalable, asynchronous front-end web application by leveraging a technology like the Tornado web framework ([http://tornadoweb.org](http://tornadoweb.org/)) or Node.js ([http://nodejs.org](http://nodejs.org/)). When the front-end application starts up, it will create a queue in RabbitMQ using a name that’s unique to that process for RPC responses.

As illustrated in [figure 6.2](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-6/ch06fig02), the request process begins when a mobile client application uploads the image and your application receives the content. The application then creates a message with a unique ID that identifies the remote request. When publishing the image to the exchange, the response queue name will be set in the `reply-to` field in the message’s properties and the request ID will be placed in the `correlation-id` field. The body of the message will contain only the opaque binary data of the image.

![Figure 6.2. A simple RPC pattern where a publisher sends a request using a direct exchange and a worker consumes the message, publishing the result to be consumed by the original publisher](https://drek4537l1klr.cloudfront.net/roy/Figures/06fig02_alt.jpg)

We discussed some low-level frame structures in [chapter 2](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-2/ch02). Let’s review the frames required to create such an RPC request ([figure 6.3](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-6/ch06fig03)).

![Figure 6.3. The low-level frame structure for an RPC message carrying a 385,911 byte image](https://drek4537l1klr.cloudfront.net/roy/Figures/06fig03_alt.jpg)

In [figure 6.3](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-6/ch06fig03), the `reply-to` and `correlation-id` field values are carried in the `Content-Headers` property payload. The image that’s being sent as the message body is split up into three chunks, sent in AMQP body frames. RabbitMQ’s maximum frame size of 131,072 bytes means that any message body that exceeds that size must be chunked at the AMQP protocol level. Because there are 7 bytes of overhead that must be taken into account, each body frame may only carry 131,065 bytes of the opaque binary image data.

Once the message is published and routed, a consumer subscribed to the work queue consumes it, as you learned in [chapter 5](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-5/ch05). This consumer can do the heavy lifting and perform the blocking, computationally expensive, or I/O intensive operations that the front-end web application wouldn’t be able to perform without blocking other clients. Instead, by offloading the computationally or I/O intensive tasks to a consumer, an asynchronous front end is free to process other client requests while it’s waiting for a response from the RPC worker. Once a worker has completed its processing of the image, the result of the RPC request is sent back to the web front end, enabling it to send a reply to the remote mobile client, completing the client’s original request.

We won’t write the full web application in the following listings, but we will write a simple consumer that will attempt to detect faces in images that are published to it and then return the same image to the publisher with boxes drawn around the detected faces. To demonstrate how the publishing side operates, we’ll write a publisher that will dispatch work requests for every image located in a prespecified directory. As you can see in [figure 6.4](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-6/ch06fig04), the abbreviated workflow you’ll be implementing is most of the application; it’s just missing the web application.

![Figure 6.4. The abbreviated application flow implemented in this section](https://drek4537l1klr.cloudfront.net/roy/Figures/06fig04_alt.jpg)

With the structure outlined, we now need to do a bit of preparation before we get to the code.

##### Declaring the exchanges

Before writing the consumer and publisher, you need to declare a few exchanges. In the following code, the URL to connect to isn’t specified, so the application will connect to RabbitMQ using the default URL of amqp://guest:guest@localhost:5672/%2F. Once connected, it will then declare an exchange to route RPC requests through and an exchange to route RPC replies through. The following code to declare the direct RPC exchange is in the “6.1 RPC Exchange Declaration” notebook.

```
12345678import rabbitpy

with rabbitpy.Connection() as connection:                                 1
    with connection.channel() as channel:                                 2
        for exchange_name in ['rpc-replies', 'direct-rpc-requests']:      3
            exchange = rabbitpy.Exchange(channel, exchange_name,          4
                                         exchange_type='direct')
            exchange.declare()                                            5
```

- ***1* Connects to RabbitMQ**
- ***2* Opens a channel on the connection**
- ***3* Iterates through the exchange names to be created**
- ***4* Creates the exchange object**
- ***5* Declares the exchange**

Unlike previous examples for declaring an exchange, this code declares multiple exchanges instead of just one. To limit the amount of code required to perform this task, a Python `list` or array of exchange names is iterated upon. For each iteration of the loop, a rabbitpy `Exchange` object is created, and then the exchange is declared with RabbitMQ.

Once you’ve declared the RPC exchanges for the RPC workflow, go ahead and move on to creating the RPC worker.

#### 6.1.2. Creating the RPC worker

We’ll create the RPC worker as a consumer application that will receive messages containing image files and perform image recognition on them using the excellent OpenCV ([http://opencv.org](http://opencv.org/)), drawing a box around each face in the photo. Once an image has been processed, the new image will be published back through RabbitMQ, using the routing information provided in the original message’s properties ([figure 6.5](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-6/ch06fig05)).

![Figure 6.5. A photo processed by the RPC facial recognition worker](https://drek4537l1klr.cloudfront.net/roy/Figures/06fig05_alt.jpg)

The RPC consumer is a more complex example than those we’ve looked at so far, so it deserves a bit more than a single code listing. To keep us from getting sidetracked by the details of facial recognition, all of the code that performs the facial recognition is imported as a module named `detect` in the `ch6` Python package. In addition, the `ch6.utils` module provides functionality to manage the image file on disk, for the consumer’s use. The consumer code is in the “6.1.2 RPC Worker” notebook.

##### Importing the proper libraries

To start building the facial recognition consumer, you must first import the Python packages or modules required by the application. These include the modules from the previously mentioned `ch6` package, `rabbitpy`, `os`, and `time`.

```
12345import os
import rabbitpy
import time
from ch6 import detect
from ch6 import utils
```

The `os` package is used to remove the image file from disk and get the current process ID, whereas the `time` package supplies timing information while providing processing information to the system console.

##### Connecting, declaring, and binding a queue

With the imports out of the way, you can use rabbitpy to connect to RabbitMQ and open a channel:

```
12connection = rabbitpy.Connection()
channel = connection.channel()
```

As with previous consumer examples, a `rabbitpy.Queue` object is required to declare, bind, and consume from the RabbitMQ queue that will receive the messages. Unlike previous examples, this queue is temporary and exclusive to a single instance of the consumer application. To let RabbitMQ know that the queue should go away as soon as the consumer application does, the `auto_delete` flag is set to `True` and the `durable` flag is set to `False`. To let RabbitMQ know that no other consumer should be able to access the messages in the queue, the `exclusive` flag is set to `True`. If another consumer should attempt to consume from the queue, RabbitMQ will prevent the consumer from doing so, and it will send it an AMQP `Channel.Close` frame.

To create a meaningful name for the queue, an easily identifiable string name is created, including the operating system’s process ID for the Python consumer application.

```
12345queue_name = 'rpc-worker-%s' % os.getpid()
queue = rabbitpy.Queue(channel, queue_name,
                       auto_delete=True,
                       durable=False,
                       exclusive=True)
```

##### Note

If you omit a queue name when creating the queue, RabbitMQ will automatically create a queue name for you. You should recognize these queues in the RabbitMQ management interface as they follow a pattern similar to `amq.gen-oCv2kwJ2H0KYxIunVI-xpQ`.

Once the `Queue` object has been created, the AMQP `Queue.Declare` RPC request is issued to RabbitMQ. That’s followed by the AMQP `Queue.Bind` RPC request to bind the queue to the proper exchange, using the `detect-faces` routing key, so you only get messages sent as facial recognition RPC requests from the publisher you’ll write in the next section.

```
1234if queue.declare():
    print('Worker queue declared')
if queue.bind('direct-rpc-requests', 'detect-faces'):
    print('Worker queue bound')
```

##### Consuming the RPC requests

With the queue created and bound, the application is ready to consume messages. To consume messages from RabbitMQ, the consumer will use the `rabbitpy.Queue.consume_messages` iterator method that also acts as a Python context manager. A Python context manager is a language construct that’s invoked by the `with` statement. For an object to provide context manager support, it defines magic methods (`__enter__` and `__exit__`) that execute when a code block is entered or exited using the `with` statement.

Using a content manager allows rabbitpy to deal with sending the `Basic.Consume` and the `Basic.Cancel` AMQP RPC requests so you can focus on your own code:

```
for message in queue.consume_messages():
```

As you iterate through each message that RabbitMQ delivers, you’ll have a look at the message’s `timestamp` property in order to display how long the message was sitting in the queue before the consumer received it. The publishing code will automatically set this value on every message, providing a source of information outside of RabbitMQ that details when the message was first created and published.

Because rabbitpy will automatically transform the `timestamp` property into a Python `datetime` object, the consumer needs to transform the value back into a UNIX epoch to calculate the number of seconds since the message was published:

```
1234duration = (time.time() –
            int(message.properties['timestamp'].strftime('%s')))
print('Received RPC request published %.2f seconds ago' % 
      duration)
```

##### Processing an image message

Next, to perform the facial recognition, the message body containing the image file must be written to disk. Because these files are only needed for a short time, the image will be written out as a temporary file. The `content-type` of the message is also passed in, so the proper file extension can be used when naming the file.

```
12temp_file = utils.write_temp_file(message.body,
                              message.properties['content_type'])
```

With the file written to the filesystem, the consumer can now perform the facial recognition using the `ch6.detect.faces` method. The method returns the path to a new file on disk that contains the original image with the detected faces in box overlays:

```
result_file = detect.faces(temp_file)
```

##### Sending the result back

Now that the hard work is done, it’s time to publish the result of the RPC request back to the original publisher. To do so, you must first construct the properties of the response message, which will contain the `correlation-id` of the original message, so the publisher knows which image to correlate with the response. In addition, the `headers` property is used to set the timestamp for when the message was first published. This will allow the publisher to gauge total time from request to response, which could be used for monitoring purposes.

```
1234567properties = {'app_id': 'Chapter 6 Listing 2 Consumer',
              'content_type': message.properties['content_type'],
              'correlation_id':
                 message.properties['correlation_id'],
              'headers': {
                  'first_publish':
                      message.properties['timestamp']}}
```

With the response properties defined, the result file with the image is read from disk, and both the original temp file and the result file are removed from the filesystem:

```
123body = utils.read_image(result_file)
os.unlink(temp_file)
os.unlink(result_file)
```

Finally, it’s time to create and publish the response message and then acknowledge the original RPC request message so that RabbitMQ can remove it from the queue:

```
123response = rabbitpy.Message(channel, body, properties)
response.publish('rpc-replies', message.properties['reply_to'])
message.ack()
```

##### Running the consumer application

With the consumer code done, it’s time to run the consumer application. Like with previous examples, you can select Cell > Run All to bypass having to run each cell independently. Note that the last cell of this application in the IPython notebook will keep running until you stop it. You’ll know it’s running when the Kernel Busy indicator is displayed ([figure 6.6](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-6/ch06fig06)). You can leave this browser tab open and go back to the IPython dashboard for the next section.

![Figure 6.6. The IPython notebook running the RPC worker](https://drek4537l1klr.cloudfront.net/roy/Figures/06fig06_alt.jpg)

#### 6.1.3. Writing a simple RPC publisher

You now have a running RPC consumer application that will receive messages, perform facial recognition on them, and return the result. It’s time to write an application that can publish messages to it. In this sample use case, our goal is to move blocking and slow processes to external consumers so that a high-performance, asynchronous web application can receive requests and process them without blocking other requests while the processing is taking place.

Because it’s outside the scope of this book to write a full asynchronous web application, the publisher code will simply publish the RPC request message and display the RPC response message once it has been received. Also, the images used for this example are already in the Vagrant virtual machine and are all in the public domain.

##### Specifying the imported libraries

To get started, you must first import the requisite Python packages and modules to perform the task at hand. In the case of the publisher, all of the same packages and modules are used, with the exception of the `ch6.detect` module.

```
1234import os
import rabbitpy
import time
from ch6 import utils
```

Similar to the consumer’s use of the `os` package, the publisher uses the `os.getpid()` method to create a uniquely named response queue from which the publisher will retrieve processed images. Like the consumer’s request queue, the publisher’s response queue will have `auto_delete` and `exclusive` set to `True` and `durable` set to `False`.

```
queue_name = 'response-queue-%s' % os.getpid()
response_queue = rabbitpy.Queue(channel, 
                                queue_name,
                                auto_delete=True,
                                durable=False,
                                exclusive=True)
```

##### Declaring and binding the exchange

Once the response queue’s `rabbitpy.Queue` object has been created, it will also need to be declared and bound, but this time to the `rpc-replies` exchange, using its name for the routing key:

```
if response_queue.declare():
    print('Response queue declared')
if response_queue.bind('rpc-replies', queue_name):
    print('Response queue bound')
```

With the queue declared and bound, it’s time to iterate through the images that are available.

##### Iterating through the available images

To iterate through the images, the `ch6.utils` module provides a function named `get_images()` that returns a list of images on disk that should be published. The method is wrapped with the Python `enumerate` iterator function, which will return a tuple of the current index of the value in the list and its associated value. A tuple is a common data structure. In Python, it’s an immutable sequence of objects.

```
for img_id, filename in enumerate(utils.get_images()):
```

Inside this control block, you’ll construct the message and publish to RabbitMQ. But before the publisher creates the message, let’s have it print out information that tells you about the image being published for processing:

```
print('Sending request for image #%s: %s' % (img_id, filename))
```

##### Constructing the request message

Creating the message is a fairly straightforward one-liner. The `rabbitpy.Message` object is constructed, with the first argument passed in being the channel, and then it uses the `ch6.utils.read_image()` method to read the raw image data from disk and passes it in as the message body argument.

Finally, the message properties are created. The `content-type` for the message is set using the `ch6.utils.mime_time()` method, which returns the mime type for the image. The `correlation-id` property is set using the `img_id` value provided by the enumerate iterator function. In an asynchronous web application, this might be a connection ID for the client or a socket file descriptor number. Finally the message’s `reply_to` property is set to the publisher’s response queue name. The rabbitpy library automatically sets the `timestamp` property if it’s omitted by setting the `opinionated` flag to `True`.

```
message = rabbitpy.Message(channel,
                           utils.read_image(filename),
                           {'content_type':
                                utils.mime_type(filename),
                            'correlation_id': str(img_id),
                            'reply_to': queue_name},
                           opinionated=True)
```

With the message object created, it’s time to publish it to the `direct-rpc-requests` exchange using the `detect-faces` routing key:

```
message.publish('direct-rpc-requests', 'detect-faces')
```

As soon as this is run, the message is sent and should quickly be received by the RPC consumer application.

##### Waiting for a reply

In an asynchronous web application, the application would handle another client request while waiting for a response from the RPC consumer. For the purposes of this example, we’ll create a blocking application instead of an asynchronous server. Instead of consuming the response queue and performing other work asynchronously, our publisher will use the `Basic.Get` AMQP RPC method to check whether a message is in the queue and receive it, as follows:

```
message = None
while not message:
    time.sleep(0.5)
    message = response_queue.get()
```

##### Acknowledging the message

Once a message is received, the publisher should acknowledge so RabbitMQ can remove it from the queue:

```
message.ack()
```

##### Processing the response

If you’re like me, you’ll want to know how long the facial recognition and message routing took, so add a line that prints out the total duration from original publishing until the response is received. In complex applications, the message properties can be used to carry metadata like this, that’s used for everything from debugging information to data that’s used for monitoring, trending, and analytics.

```
duration = (time.time() - 
         time.mktime(message.properties['headers']['first_publish']))
print('Facial detection RPC call for image %s duration %.2f sec' % 
      (message.properties['correlation_id'], duration))
```

This code that prints out the duration uses the `first_publish` timestamp value set in the message properties header table that was set by the consumer. That way you know the full round-trip time from initial RPC request publishing to the receipt of the RPC reply.

Finally, you can display the image in the IPython notebook using the `ch6.utils.display_image()` function:

```
utils.display_image(message.body,
                    message.properties['content_type'])
```

##### Closing up

With the main publisher code block complete, the following lines close the channel and connection and should no longer be indented by four spaces:

```
channel.close()
connection.close()
```

##### Testing the whole application

It’s time to test. Open up “6.1.3 RPC Publisher” in the IPython notebook and click the Run Code play button to fire off the messages and see the results ([figure 6.7](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-6/ch06fig07)).

![Figure 6.7. The RPC publisher receiving results from the consumer](https://drek4537l1klr.cloudfront.net/roy/Figures/06fig07_alt.jpg)

As you may have noticed, the facial recognition code isn’t perfect, but it performs pretty well for a low-powered virtual machine. To improve the quality of the facial recognition, additional algorithms can be employed to look for a quorum of results from each algorithm. Such work is way too slow for a real-time web app, but not for an army of RPC consumer applications on specialty hardware. Fortunately, RabbitMQ provides multiple ways to route the same message to different queues. In the next section, we’ll tap the messages sent by the RPC publisher without impacting the already established workflow. To achieve this, we’ll use a fanout exchange instead of a direct exchange for RPC requests.

### 6.2. Broadcasting messages via the fanout exchange

Where a direct exchange allows for queues to receive targeted messages, a fanout exchange doesn’t discriminate. All messages published through a fanout exchange are delivered to all queues in the fanout exchange. This provides significant performance advantages because RabbitMQ doesn’t need to evaluate the routing keys when delivering messages, but the lack of selectivity means all applications consuming from queues bound to a fanout exchange should be able to consume messages delivered through it.

Suppose that, in addition to detecting faces, you wanted to create tools so your mobile application could identify spammers in real time. Using a fanout exchange that the web application publishes to when it performs a facial recognition RPC request, you could bind the RPC consumer queues and any other consumer applications you’d like to act on the messages. The facial recognition consumer would be the only consumer to provide RPC replies to the web application, but your other consumer applications could perform other types of analysis on the images published, for internal purposes only ([figure 6.8](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-6/ch06fig08)).

![Figure 6.8. Adding another consumer that receives the same message as the RPC consumer by using a fanout exchange](https://drek4537l1klr.cloudfront.net/roy/Figures/06fig08_alt.jpg)

In my experience, spammers often use the same images when registering for a service or submitting content to the service. One way to mitigate spam attacks is to fingerprint images and keep a database of image fingerprints identified as spam, taking action when a new image is uploaded with the same fingerprint. In the following code examples, we’ll use an RPC request message that triggers the facial recognition consumer to fingerprint images.

#### 6.2.1. Modifying the facial detection consumer

In the examples that follow, we’ll build upon the examples in [section 6.1](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-6/ch06lev1sec1), making some small modifications and adding a new image-hashing consumer that will create a hash of an image when the RPC request is made.

To get started, you first need to create the fanout exchange. The following snippet is from the “6.2.1 Fanout Exchange Declaration” notebook.

```
import rabbitpy

with rabbitpy.Connection() as connection:                              1
    with connection.channel() as channel:                              2
        exchange = rabbitpy.Exchange(channel, 
                                    'fanout-rpc-requests',             3
                                     exchange_type='fanout')
        exchange.declare()                                             4
```

- ***1* Connects to RabbitMQ**
- ***2* Opens a channel on the connection**
- ***3* Creates the fanout exchange object**
- ***4* Declares the exchange**

In addition, the original consumer code from [section 6.1](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-6/ch06lev1sec1) needs a slight modification in how the queue is bound. Instead of binding to the `direct-rpc-requests` exchange with a routing key, the consumer will need to bind to `fanout-rpc-requests` without a routing key. The change is already made in the “6.2.1 RPC Worker” notebook, and it changes this line:

```
if queue.bind('direct-rpc-requests', 'detect-faces'):
```

to use the new fanout exchange:

```
if queue.bind('fanout-rpc-requests'):
```

The only modification you need to make to the publisher code is to change the exchange that’s being published to. Again, the code is already modified in the IPython notebook as “6.2.1 RPC Publisher,” and changes this line:

```
message.publish('direct-rpc-requests', 'detect-faces')
```

to use the new exchange as follows:

```
message.publish('fanout-rpc-requests')
```

Before you publish and consume the messages, let’s write the image-hashing or fingerprinting consumer.

#### 6.2.2. Creating a simple image-hashing consumer

For the sake of simplicity, the consumer will use a simple binary hashing algorithm, MD5. There are much more sophisticated algorithms that do a much better job of creating image hashes, allowing for variations in cropping, resolution, and bit depth, but the point of this example is to illustrate RabbitMQ exchanges, not cool image-recognition algorithms.

##### Importing the base libraries and connecting to RabbitMQ

To get started, the consumer in the “6.2.2 Hashing Consumer” notebook shares much of the same code as the RPC consumer. Most notably, though, instead of importing `ch6.detect`, this consumer imports Python’s `hashlib` package:

```
import os
import hashlib
import rabbitpy
```

Similar to the RPC publisher and worker previously discussed, the image-hashing consumer will need to connect to RabbitMQ and create a channel:

```
connection = rabbitpy.Connection()
channel = connection.channel()
```

##### Creating and binding a queue to work off of

Once the channel is open, you can create a queue that’s automatically removed when the consumer goes away and that’s exclusive to this consumer:

```
queue_name = 'hashing-worker-%s' % os.getpid()
queue = rabbitpy.Queue(channel, queue_name,
                       auto_delete=True,
                       durable=False,
                       exclusive=True)

if queue.declare():
    print('Worker queue declared')
if queue.bind('fanout-rpc-requests'):
    print('Worker queue bound')
```

##### Hashing the images

The consumer is very straightforward. It will iterate through each message received and create a hashlib.md5 object, passing in the binary message data. It will then print a line with the hash. The output line could just as easily be a database insert or an RPC request to compare the hash against the database of existing hashes. Finally, the message is acknowledged and the consumer will wait for the next message to be delivered.

```
for message in queue.consume_messages():
    hash_obj = hashlib.md5(message.body)
    print('Image with correlation-id of %s has a hash of %s' % 
          (message.properties['correlation_id'], 
           hash_obj.hexdigest()))
message.ack()
```

##### Note

For storing a materialized set of hashes, Redis ([http://redis.io](http://redis.io/)) is an excellent choice of database. It provides quick, in-memory data structures for hash lookups and can provide very quick responses to inquiries with this type of data.

##### Testing the new workflow

With the new consumer written and the other applications modified, it’s time to test things out. Open the “6.2.2 Hashing Consumer,” “6.2.1 RPC Worker,” and “6.2.1 RPC Publisher” notebooks in their own tabs in your web browser. Start by running all the cells in the “6.2.2 Hashing Consumer” notebook, then all the cells in the “6.2.1 RPC Worker” notebook, and finally send the images to kick off the process by running all the cells in the “6.2.1 RPC Publisher” notebook. You should see the same responses to the RPC publisher and consumer applications as when you ran the examples in the previous section. In addition, you should now have output similar to [figure 6.9](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-6/ch06fig09) in your “6.2.2 Hashing Consumer” application output.

![Figure 6.9. Example output of the hashing consumer in an IPython notebook](https://drek4537l1klr.cloudfront.net/roy/Figures/06fig09_alt.jpg)

Fanout exchanges provide a great way to allow every consumer access to the fire hose of data. This can be a double-edged sword, however, because consumers can’t be selective about the messages they receive. For example, let’s say you wanted a single exchange that allowed different types of RPC requests to be routed through it but that performs common tasks, such as auditing each RPC request without regard to type. In such a scenario, a topic exchange would allow your RPC worker consumers to bind to routing keys specific to their task and for request audit consumers to bind with wildcard matching to all messages or a subset of them.

### 6.3. Selectively routing messages with the topic exchange

Like direct exchanges, topic exchanges will route messages to any queue bound with a matching routing key. But by using a period-delimited format, queues may bind to routing keys using wildcard-based pattern matching. By using the asterisk (`*`) and pound (`#`) characters, you can match specific parts of the routing key or even multiple parts at the same time. An asterisk will match all characters up to a period in the routing key, and the pound character will match all characters that follow, including any subsequent periods.

[Figure 6.10](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-6/ch06fig10) shows a topic exchange routing key with three parts that you can use for new profile images that have been uploaded. The first part indicates the message should be routed to consumers that know how to act on image-related messages. The second part indicates that the message contains a new image, and the third contains additional data that can be used to route the message to queues for consumers that are specific to profile-related functionality.

![Figure 6.10. A topic exchange routing key with three parts](https://drek4537l1klr.cloudfront.net/roy/Figures/06fig10.jpg)

If we were to build out upon the image-upload process, creating a messaging-based architecture for managing all of the image-related tasks on the website, the following routing keys could describe a few of the messages that would be published.

- `image.new.profile`—For messages containing a new profile image
- `image.new.gallery`—For messages containing a new photo gallery image
- `image.delete.profile`—For messages with metadata for deleting a profile image
- `image.delete.gallery`—For messages with metadata for deleting a gallery image
- `image`.`resize`—For messages requesting the resizing of an image

In the preceding example routing keys, the semantic importance of the routing key should clearly stand out, describing the intent or content of the message. By using semantically named keys for messages routed through the topic exchange, a single message can be routed by subsections of the routing key, delivering the message to task-specific queues. In [figure 6.11](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-6/ch06fig11), the topic exchange determines which consumer application queues will receive a message based on how they were bound to the exchange.

![Figure 6.11. Messages are selectively routed to different queues based on the composition of their routing keys.](https://drek4537l1klr.cloudfront.net/roy/Figures/06fig11_alt.jpg)

A topic exchange is excellent for routing a message to queues so that single-purpose consumers can perform different actions with it. In [figure 6.11](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-6/ch06fig11), the queue for the facial-detection RPC worker is bound to `image.new.profile`, behaving as if it were bound to a direct exchange, receiving only new profile image requests. The queue for the image-hashing consumer is bound to `image.new.#`, and will receive new images regardless of origin. A consumer that maintains a materialized user directory could consume from a queue bound to `#.profile` and receive all messages ending in `.profile` to perform its materialization tasks. Image-deletion messages would be published to a queue bound to `image.delete.*`, allowing a single consumer to remove all images uploaded to the site. Finally, an auditing consumer bound to `image.#` would receive every image-related message so it could log information to help with troubleshooting or behavioral analysis.

Single-purpose consumers leveraging architecture like this can be both easier to maintain and to scale, compared to a monolithic application performing the same actions on messages delivered to a single queue. A monolithic application increases operational and code complexity. Consider how a modular approach to writing consumer code simplifies what would otherwise be complex actions, such as moving hardware, increasing processing throughput by adding new consumers, or even just adding or removing application functionality. With a single-purpose, modular approach using a topic exchange, appropriate new functionality can be composed of a new consumer and queue without impacting the workflow and processing of other consumer applications.

##### Note

It can be useful to create routing keys that are semantically relevant to the message, describing either its intent or content. Instead of thinking about the message and its routing key as an application-specific detail, a generic, event-based approach to messaging encourages message reusability. Reduced code complexity and reduced message throughput are key benefits when developers are able to reuse existing messages in their applications. Along with virtual hosts and exchanges, routing keys should be able to provide enough semantic data about messages for any number of applications to use them without any awkward namespace-related issues.

The use of a topic exchange instead of a direct exchange is demonstrated in the “6.3 Topic Exchange Declaration,” “6.3 RPC Publisher,” and “6.3 RPC Worker” notebooks. The only major difference in these notebooks, as compared to the notebooks from [section 6.1](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-6/ch06lev1sec1), is the exchange type that’s declared and the routing key that’s used. Running these examples should demonstrate that there’s little difference between using the topic and direct exchanges when you’re matching on the full routing key. But by using the topic exchange, you’ll be able to perform partial pattern matching on the routing key for any other purpose in the future without having to change your messaging architecture.

Using a topic exchange with namespaced routing keys is a good choice for future-proofing your applications. Even if the pattern matching in routing is overkill for your needs at the start, a topic exchange (used with the right queue bindings) can emulate the behavior of both direct and fanout exchanges. To emulate the direct exchange behavior, bind queues with the full routing key instead of using pattern matching. Fanout exchange behavior is even easier to emulate, as queues bound with `#` as the routing key will receive all messages published to a topic exchange. With such flexibility, it’s easy to see why the topic exchange can be a powerful tool in your messaging-based architecture.

RabbitMQ has another built-in exchange type that allows similar flexibility in routing but also allows messages to be self-describing as part of the routing process, doing away with the need for structured routing keys. The headers exchange uses a completely different routing paradigm than the direct and topic exchanges, offering an alternative view of message routing.

### 6.4. Selective routing with the headers exchange

The fourth built-in exchange type is the headers exchange. It allows for arbitrary routing in RabbitMQ by using the `headers` table in the message properties. Queues that are bound to the headers exchange use the `Queue.Bind` arguments parameter to pass in an array of key/value pairs to route on and an `x-match` argument. The `x-match` argument is a string value that’s set to `any` or `all`. If the value is `any`, messages will be routed if any of the `headers` table values match any of the binding values. If the value of `x-match` is `all`, all values passed in as `Queue.Bind` arguments must be matched. This doesn’t preclude the message from having additional key/value pairs in the `headers` table.

To demonstrate how the headers exchange is used, we’ll modify the RPC worker and publisher examples from [section 6.1](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-6/ch06lev1sec1), moving the routing key to `headers` table values. Unlike using a topic exchange, the message itself will contain the values that compose the routing criteria.

Before we modify the RPC publisher and worker to use the headers exchange, let’s first declare the headers exchange. The following example creates a headers exchange named `headers-rpc-requests;` it’s in the “6.4 Headers Exchange Declaration” notebook.

```
import rabbitpy

with rabbitpy.Connection() as connection:                             1
    with connection.channel() as channel:                             2
        exchange = rabbitpy.Exchange(channel,        
                                     'headers-rpc-requests',          3
                                     exchange_type=' headers')
        exchange.declare()                                            4
```

- ***1* Connects to RabbitMQ**
- ***2* Opens a channel on the connection**
- ***3* Creates the exchange object**
- ***4* Declares the exchange**

With the exchange declared, let’s examine the changes to the RPC publisher code contained in the “6.4 RPC Publisher” notebook. There are two primary changes. The first is in constructing the message that will be published. In this example, the message’s `headers` property is being populated:

```
message = rabbitpy.Message(channel,
                           utils.read_image(filename),
                           {'content_type': utils.mime_type(filename),
                            'correlation_id': str(img_id),
                            'headers': {'source': 'profile',
                                        'object': 'image'
                                        'action': 'new'},
                            'reply_to': queue_name})
```

You can see that three values are being set: A value is assigned to the source, object, and action entries in the `headers` property. These are the values that will be routed on when the messages are published. Because we’ll be routing on these values, there’s no need for a routing key, so the `message.publish()` call is changed to only name the headers exchange the message will be routed through:

```
message.publish('headers-rpc-requests')
```

Before you run the code in this notebook, let’s examine the changes to the RPC worker in the “6.4 RPC Worker” notebook and run the code there to start the consumer. The primary change is with the `Queue.Bind` call. Instead of binding to a routing key, the `Queue.Bind` call specifies the type of match required to route images to the queue and each attribute that will be matched on:

```
if queue.bind('headers-rpc-requests',
              arguments={'x-match': 'all',
                         'source': 'profile',
                         'object': 'image', 
                         'action': 'new'}):
```

The value of the `x-match` argument is specified as `all`, indicating that the values of `source`, `object`, and `action` in the message headers must all match the values specified in the binding arguments. If you now run the “6.4 RPC Worker” notebook and then the “6.4 RPC Publisher” notebook, you should see the same results you saw with both the direct and topic exchange examples.

Is the extra metadata in the message properties worth the flexibility that the headers exchange offers? Although the headers exchange does create additional flexibility with the `any` and `all` matching capabilities, it comes with additional computational overhead in routing. When using the headers exchange, all of the values in the `headers` property have to be sorted by key name prior to evaluating the values when routing the message. Conventional wisdom is that the headers exchange is significantly slower than the other exchange types due to the additional computational complexity. But in benchmarking for this chapter, I found that there was no significant difference between any of the built-in exchanges with regard to performance when using the same quantity of values in the `headers` property.

##### Note

If you’re interested in the internal behavior RabbitMQ employs for sorting the headers table, check the `rabbit_misc` module in the rabbit-server Git repository for the `sort_field_table` function. The code is available on GitHub: [https://github.com/rabbitmq/rabbitmq-server/blob/master/src/rabbit_misc.erl](https://github.com/rabbitmq/rabbitmq-server/blob/master/src/rabbit_misc.erl).

### 6.5. Exchange performance benchmarking

It’s worth noting that the use of the `headers` property directly impacts the performance of message publishing regardless of the exchange type it’s being published into ([figure 6.12](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-6/ch06fig12)).

![Figure 6.12. Overall publishing velocity by exchange type and header table size](https://drek4537l1klr.cloudfront.net/roy/Figures/06fig12_alt.jpg)

As you can see, performance across the four built-in exchange types is relatively consistent. This benchmark shows that when comparing the same message with the same message headers, you won’t see a dramatic difference in message publishing velocity, regardless of the exchange type.

What about a more ideal test case for the topic and the headers exchanges? [Figure 6.13](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-6/ch06fig13) compares the publishing velocity for the same message body with an empty `headers` table for the topic exchange and the routing key values in the `headers` property for the headers exchange. In this scenario, it’s clear that the topic exchange is more performant than the headers exchange when doing an apples-to-apples comparison of only publishing the baseline requirements to route the message.

![Figure 6.13. Publishing velocity of the headers and topic exchanges](https://drek4537l1klr.cloudfront.net/roy/Figures/06fig13_alt.jpg)

If you use the `headers` property, it appears your overall message-publishing velocity won’t be dramatically impacted by choosing the headers exchange, unless you end up with a fairly large table of values in the `headers` property. But this performance penalty applies to all of the built-in exchange types.

Now that you have a good idea of the capabilities of the built-in exchange types and how they perform in comparison to each other, it’s time to learn how you can leverage multiple types of exchanges for a single message published to RabbitMQ.

### 6.6. Going meta: exchange-to-exchange routing

If you don’t think you’ve been presented with enough message-routing flexibility and find that your application needs a little of one exchange type and a little of another for the exact same message, you’re in luck. The RabbitMQ team added a very flexible mechanism in RabbitMQ that’s not in the AMQP specification, allowing you to route messages through any combination of exchanges. The mechanism for exchange-to-exchange binding is very similar to queue binding, but instead of binding a queue to an exchange, you bind an exchange to another exchange using the `Exchange.Bind` RPC method.

When using exchange-to-exchange binding, the routing logic that’s applied to a bound exchange is the same as it would be if the bound object were a queue. Any exchange can be bound to another exchange, including all of the built-in exchange types. This functionality allows you to chain exchanges in all sorts of imaginative ways. Do you want to route messages using namespaced keys through a topic exchange and then distribute them based upon the properties header table? If so, an exchange-to-exchange binding is the tool for you ([figure 6.14](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-6/ch06fig14)).

![Figure 6.14. A small example of the flexibility that exchange-to-exchange binding offers](https://drek4537l1klr.cloudfront.net/roy/Figures/06fig14_alt.jpg)

In the following example from the “6.6 Exchange Binding” notebook, a consistent-hashing exchange named `distributed-events` is bound to a topic exchange named `events` to distribute messages routed with the `any` routing key among the queues bound to the consistent-hashing exchange.

```
import rabbitpy

with rabbitpy.Connection() as connection:                               1
    with connection.channel() as channel:                               2
        tpc = rabbitpy.Exchange(channel, 'events', 
                                exchange_type='topic')                  3
        tpc.declare()                                                   4
        xch = rabbitpy.Exchange(channel, 'distributed-events',          5
                                exchange_type='x-consistent-hash')      6
        xch.declare()                                                   7
        xch.bind(foo, '#')      #H
```

- ***1* Connects to RabbitMQ**
- ***2* Opens a channel on the connection**
- ***3* Creates a topic exchange**
- ***4* Declares the topic exchange**
- ***5* Creates a consistent-hashing exchange**
- ***6* Declares the consistent-hashing exchange**
- ***7* Binds the consistent-hashing exchange to the topic exchange, using a wildcard match**

As a tool, exchange-to-exchange bindings create a huge amount of flexibility in the messaging patterns available to you. But with that flexibility comes extra complexity and overhead. Before you go crazy with super-complex exchange-to-exchange binding patterns, remember that simple architectures are easier to maintain and diagnose when things go wrong. If you’re considering using exchange-to-exchange bindings, you should make sure that you have a use case for the functionality that warrants the extra complexity and overhead.

### 6.7. Routing messages with the consistent-hashing exchange

The consistent-hashing exchange, a plugin that’s distributed with RabbitMQ, distributes data among the queues that are bound to it. It can be used to load-balance the queues that receive messages published into it. You can use it to distribute messages to queues on different physical servers in a cluster or to queues with single consumers, providing the potential for faster throughput than if RabbitMQ were distributing messages to multiple consumers in a single queue. When using databases or other systems that can directly integrate with RabbitMQ as a consumer, the consistent-hashing exchange can provide a way to shard out data without having to write middleware.

##### Note

If you’re considering using the consistent-hashing exchange to improve consumer throughput, you should benchmark the difference between multiple consumers on a single queue and single consumers on multiple queues before deciding which is right for your environment.

The consistent-hashing exchange uses a consistent-hashing algorithm to pick which queue will receive which message, with all queues being potential destinations. Instead of queues being bound with a routing key or header values, they’re bound with an integer-based weight that’s used as part of the algorithm for determining message delivery. Consistent-hashing algorithms are commonly used in clients for network-based caching systems like memcached and in distributed database systems like Riak and Cassandra, and in PostgreSQL (when using the PL/Proxy sharding methodology). For data sets or in the case of messages with a high level of entropy in the string values for routing, the consistent-hashing exchange provides a fairly uniform method of distributing data. With two queues bound to a consistent-hashing exchange, each with an equal weight, the distribution of messages will be approximately split in half ([figure 6.15](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-6/ch06fig15)).

![Figure 6.15. Messages published into the consistent-hashing exchange are distributed among the bound queues.](https://drek4537l1klr.cloudfront.net/roy/Figures/06fig15_alt.jpg)

When selecting a destination for a message, there’s no explicit effort made to ensure an even distribution of the messages. The consistent-hashing exchange doesn’t round-robin the messages, but rather deterministically routes messages based upon a hash value of the routing key or a message properties header-type value. But a queue with a higher weight than any other queue should receive a higher percentage of the messages published into the exchange. Of course, the distribution of messages across multiple queues assumes that you’re publishing messages with different routing keys or header table values. The differences in those values provide the entropy required to distribute the messages. Five messages sent with the same routing key would all end up in the same queue.

In our image-processing RPC system, it’s likely that images will need to be stored in some fashion to be served to other HTTP clients. At some point in dealing with the scaling demands of image storage, it’s common to need to use a distributed storage solution. In the following examples, we’ll employ the consistent-hashing exchange to distribute messages across four queues that could be used to store the images on four different storage servers.

By default, the routing key is the value that’s hashed for distributing the messages. For an image, one possible routing key value is a hash of the image itself, similar to the hash that’s generated in the “6.2.2 Hashing Consumer” notebook. If you intend to distribute messages via hashes of the routing key values, nothing special is required when declaring the exchange. This is demonstrated in the “6.7 A Consistent-Hashing Exchange that Routes on a Routing Key” notebook.

```
import rabbitpy

with rabbitpy.Connection() as connection:                                1
    with connection.channel() as channel:                                2
        exchange = rabbitpy.Exchange(channel, 'image-storage',           3
                                     exchange_type='x-consistent-hash')
        exchange.declare()                                               4
```

- ***1* Connects to RabbitMQ**
- ***2* Opens a channel on the connection**
- ***3* Creates the consistent-hash exchange object**
- ***4* Declares the exchange**

Alternatively, you could hash on a value in the headers property table. To route this way, you must pass a `hash-header` value in when declaring the exchange. The `hash-header` value contains the single key in the `headers` table that will contain the value to hash the message with. This is demonstrated in the following code snippet from the “6.7 A Consistent-Hashing Exchange that Routes on a Header” notebook.

```
import rabbitpy

with rabbitpy.Connection() as connection:                                1
    with connection.channel() as channel:                                2
        exchange = rabbitpy.Exchange(channel, 'image-storage',           3
                                     exchange_type='x-consistent-hash',
                                     arguments={'hash-header':
                                                    'image-hash'})
        exchange.declare()                                               4
```

- ***1* Connects to RabbitMQ**
- ***2* Opens a channel on the connection**
- ***3* Creates the consistent-hash exchange object that hashes on the headers table value for key**
- ***4* Declares exchange**

When binding a queue to the consistent-hash exchange, you enter the weight of the queue for the hashing algorithm as a string value. For example, if you’d like to declare a queue with a weight of 10, you’d pass in the string value of 10 as the binding key in the `Queue.Bind` AMQP RPC request. Using the image storage example, suppose that your servers for storing the images each have different storage capacities. You could use the weight value to prefer larger servers over smaller ones. You could even specify the weights as the capacity size in gigabytes or terabytes to try to balance the distribution as closely as possible. The following example, from the “6.7 Creating Multiple Bound Queues” notebook, will create four queues named `q0`, `q1`, `q2`, and `q3` and bind all of them equally against an exchange named `image-storage`.

```
import rabbitpy

with rabbitpy.Connection() as connection:                               1
    with connection.channel() as channel:                               2
        for queue_num in range(4):                                      3
            queue = rabbitpy.Queue (channel, 'server%s' % queue_num)    4
            queue.declare()                                             5
            queue.bind('image-storage', '10')                           6
```

- ***1* Connects to RabbitMQ**
- ***2* Opens a channel on the connection**
- ***3* Iterates 4 times**
- ***4* Creates a numbered queue name**
- ***5* Declares the queue**
- ***6* Binds the queue with a weight of 10**

It’s important to note that, because of the way the consistent-hashing algorithm works, should you change the number of queues that are bound to the exchange, the distribution of messages will most likely change. If a message with a specific routing key or header table value always goes into `q0,` and you add a new queue named `q4`, it may end up in any of the five queues, and messages with the same routing key will consistently go to that queue until the number of queues changes again.

To further illustrate how the distribution of data with a consistent-hashing exchange works, the following code, from the “6.7 Simulated Image Publisher” notebook, publishes 100,000 messages to the `image-storage` exchange. The routing keys are MD5 hashes of the current time and message number concatenated, because providing 100,000 images would be a bit excessive for this example. The results of the distribution are shown in the bar graph in [figure 6.16](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-6/ch06fig16).

```
import datetime
import hashlib
import rabbitpy

with rabbitpy.Connection() as connection:                                1
    with connection.channel() as channel:                                2
        for iteration in range(100000):                                  3
            timestamp = datetime.datetime.now().isoformat()              4
            hash_value = hashlib.md5('%s:%s' % (timestamp, iteration))   5
            msg = rabbitpy.Message(channel, 'Image # %i' % iteration,    6
                                    {'headers': 
                                     {'image-hash': 
                                      str(hash_value.hexdigest()}})
            msg.publish('image-storage')                                 7
```

- ***1* Connects to RabbitMQ**
- ***2* Opens a channel on the connection**
- ***3* Iterates 100,000 times**
- ***4* Gets a string value for the current date and time**
- ***5* Creates an MD5 hash object**
- ***6* Creates a rabbitpy Message object**
- ***7* Publishes the message with the MD5 hash as the routing key**

![Figure 6.16. The distribution of 100,000 messages with fairly random hashes](https://drek4537l1klr.cloudfront.net/roy/Figures/06fig16_alt.jpg)

As you can see, the distribution is close but not exact. This is because the decision of where to place the queue is determined by the value used in routing, and it can’t truly load-balance messages in a round-robin way without very specific routing key values being crafted to ensure this behavior. If you’re looking to load-balance your messages among multiple queues but don’t want to use the consistent hashing approach, take a look at John Brisbin’s random exchange ([https://github.com/jbrisbin/random-exchange](https://github.com/jbrisbin/random-exchange)). Instead of looking at the routing key to distribute the message among the queues, it uses random number generation. Given RabbitMQ’s plugin flexibility, it wouldn’t be surprising if a true round-robin exchange were to surface in the future. If this is something that interests you, perhaps it’s something you’ll be able to write.

If you’re looking to leverage a consistent-hashing exchange to increase throughput, you should look before you leap, as it’s not typically required to increase performance or message throughput. But if you need to perform tasks like distributing subsets of messages across data centers or RabbitMQ clusters, the consistent-hashing exchange can be a valuable tool.

### 6.8. Summary

By now you should have a good understanding of the various routing mechanisms built into RabbitMQ. If you need to come back for reference, [table 6.1](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-6/ch06table01) contains a quick summary of the exchanges and their descriptions. Each exchange type offers distinct functionality that can be leveraged in your applications to ensure that messages are routed to the proper consumers as quickly as possible.

##### Table 6.1. Summary of exchange types

| Name | Plugin | Description |
| --- | --- | --- |
| Direct | No | Routes to bound queues based upon the value of a routing key. Performs equality matches only. |
| Fanout | No | Routes to all bound queues regardless of the routing key presented with a message. |
| Topic | No | Routes to all bound queues using routing key pattern matching and string equality. |
| Headers | No | Routes messages to bound queues based upon the values in the message properties headers table. |
| Consistent-hashing | Yes | Behaves like a fanout exchange but routes to bound queues, distributing messages based on the hashed value of a routing key or message properties header value. |

Remember that messages can often be reused in ways that aren’t initially evident when creating your architecture, so I recommend incorporating as much flexibility as possible when creating your messaging architecture. By using topic exchanges with namespaced semantic routing keys, you can easily tap into the flow of messages, a task that may be more difficult than if you use a direct exchange as your main routing mechanism. Topic exchanges should be able to provide almost the same level of flexibility that the headers exchange allows for, without the protocol lock-in of having to have AMQP message properties for routing.

At their core, exchanges are simply routing mechanisms for the messages that flow through RabbitMQ. A wide variety of exchange plugins exist, from exchanges that store messages in databases, like the Riak exchange ([https://github.com/jbrisbin/riak-exchange](https://github.com/jbrisbin/riak-exchange)), to exchanges with a memory, like the Message History exchange ([https://github.com/videlalvaro/rabbitmq-recent-history-exchange](https://github.com/videlalvaro/rabbitmq-recent-history-exchange)).

In the next chapter you’ll learn how to join two or more RabbitMQ servers into a cohesive messaging cluster, providing a way to scale out your messaging throughput and add stronger message guarantees using highly available queues.
