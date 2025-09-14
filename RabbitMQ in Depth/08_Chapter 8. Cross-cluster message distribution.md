# Chapter 8. Cross-cluster message distribution

### This chapter covers

- Federated exchanges and queues
- How to set up multiple federated RabbitMQ nodes in Amazon Web Services
- Different patterns of use for RabbitMQ federation

Whether you’re looking to implement messaging across data centers, upgrade RabbitMQ, or provide transparent access to messages in different RabbitMQ clusters, you’ll want to take a look at the federation plugin. Distributed with RabbitMQ as a stock plugin, the federation plugin provides two different ways to get messages from one cluster to another. By using a federated exchange, messages published to an exchange in another RabbitMQ server or cluster are automatically routed to bound exchanges and queues on the downstream host. Alternatively, if your needs are more specific, federated queues provide a way to target the messages in a single queue instead of an exchange. In either scenario, the goal is to transparently relay messages from the upstream node where they were originally published to the downstream node ([figure 8.1](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-8/ch08fig01)).

![Figure 8.1. Messages are sent to the downstream node’s exchanges and queues from the upstream node.](https://drek4537l1klr.cloudfront.net/roy/Figures/08fig01.jpg)

### 8.1. Federating exchanges and queues

To figure out if federation has a place in your message topology, it helps to understand how federation works and what you can expect when you use the federation plugin. Provided as part of the core RabbitMQ distribution, the federation plugin provides flexible ways to transparently relay messages between nodes and clusters. The functionality of the plugin is divided into two main components: federated exchanges and federated queues.

Federated exchanges allow for messages published to an exchange on an upstream node to transparently be published to an exchange of the same name on the downstream node. Federated queues, on the other hand, allow for downstream nodes to act as consumers of shared queues on upstream nodes, providing the ability to round-robin messages across multiple downstream nodes.

Later in this chapter you’ll set up a test environment where you can experiment with both types of federation, but first let’s explore how each works.

#### 8.1.1. Federated exchanges

Suppose you’re tasked with adding the ability to do large-scale data processing of user behavior related to your pre-existing web application running in the cloud. The application is a large-scale, user-driven news site, like Reddit or Slashdot, and the application already uses a messaging-based topology where events are raised when the user takes actions on your site. When users log in, post articles, or leave comments, instead of directly writing the content to the database, messages are published to RabbitMQ and consumers perform the database writes ([figure 8.2](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-8/ch08fig02)).

![Figure 8.2. A web application with decoupled writes, prior to adding federation](https://drek4537l1klr.cloudfront.net/roy/Figures/08fig02_alt.jpg)

Because the web application’s database write operations are decoupled using RabbitMQ as the middleware between the application and the consumer that writes to the database, you can easily tap into the message stream to write the data to a data warehouse for analysis as well. One way you could go about this is to add a consumer local to the web application that writes to the data warehouse. But what do you do when the infrastructure and storage for your data warehouse is located elsewhere?

As we discussed in the last chapter, RabbitMQ’s built-in clustering capabilities require low-latency networks where network partitions are rare. The term *network partition* refers to nodes on a network being unable to communicate with each other. When you’re connecting over high-latency network connections, such as the internet, network partitions aren’t uncommon and should be accounted for. Fortunately, RabbitMQ has a bundled plugin for federating nodes that can be used in these very situations. The federation plugin allows for a downstream RabbitMQ server that federates messages from the pre-existing RabbitMQ server ([figure 8.3](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-8/ch08fig03)).

![Figure 8.3. The same web application with a federated downstream RabbitMQ server storing messages in the data warehouse](https://drek4537l1klr.cloudfront.net/roy/Figures/08fig03_alt.jpg)

When the federated server is set up, all you have to do is create policies that apply to the exchanges you need the messages from. If the upstream RabbitMQ server has an exchange called `events` that the login, article, and comment messages are published into, your downstream RabbitMQ server should create a federation policy matching that exchange name. When you create the exchange on the downstream RabbitMQ and bind a queue to it, the policy will tell RabbitMQ to connect to the upstream server and start publishing messages to the downstream queue.

Once RabbitMQ is publishing messages from the upstream server to the downstream queue, you don’t have to worry about what will happen if the internet connectivity is severed between the two. When connectivity is restored, RabbitMQ will dutifully reconnect to the main RabbitMQ cluster and start locally queuing all of the messages that were published by the website while the connection was down. After a bit of time, the downstream consumer should catch up, and you won’t need to lift a finger. Does this sound like magic? Perhaps, but there’s nothing magical about it under the covers.

An exchange with a federation policy on the host gets its own special process in RabbitMQ. When an exchange has a policy applied, it will connect to all of the upstream nodes defined in the policy and create a work queue where it can receive messages. The process for that exchange then registers as a consumer of the work queue and waits for messages to start arriving. Bindings on exchange in the downstream node are automatically applied to the exchange and work queue in the upstream node, causing the upstream RabbitMQ node to publish messages to the downstream consumer. When that consumer receives a message, it publishes the message to the local exchange, just as any other message publisher would. The messages, with a few extra headers attached, are routed to their proper destination ([figure 8.4](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-8/ch08fig04)).

![Figure 8.4. The federation plugin creates a work queue on the upstream RabbitMQ node.](https://drek4537l1klr.cloudfront.net/roy/Figures/08fig04_alt.jpg)

As you can see, federated exchanges provide a simple, reliable, and robust way to extend your RabbitMQ infrastructure across network latencies that RabbitMQ clustering doesn’t allow. Additionally, it allows you to bridge logically separated RabbitMQ clusters, such as two clusters in the same data center running different versions of RabbitMQ.

The federated exchange is a powerful tool that can cast a wide net in your messaging infrastructure, but what if your needs are more specific? Federated queues can also provide a more focused way of distributing messages across RabbitMQ clusters that even allows for round-robin behavior among multiple downstream nodes and RabbitMQ consumers.

#### 8.1.2. Federated queues

A newer addition to the federation plugin—*queue-based federation*—provides a way to scale out queue capacity. This is especially useful for messaging workloads where a particular queue may have heavy spikes of publishing activity and much slower or throttled consuming. When using a federated queue, message publishers use the upstream node or cluster, and messages are distributed to the same-named queue across all downstream nodes ([figure 8.5](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-8/ch08fig05)).

![Figure 8.5. The upstream “foo” queue has its messages load-balanced between two RabbitMQ servers using the federation plugin.](https://drek4537l1klr.cloudfront.net/roy/Figures/08fig05_alt.jpg)

Like the upstream queue, downstream queues can exist on a single node or as part of an HA queue in a cluster. The federation plugin ensures that downstream queues will only receive messages when the queues have consumers available for processing messages. By checking the consumer count for each queue and only binding to the upstream node when consumers are present, it prevents idle messages from collecting in consumerless queues.

As you go through the configuration-related examples later in this chapter, you’ll see that there’s very little difference between the configuration of federated queues and exchanges. In fact, the default configuration for federation targets both exchanges and queues.

### 8.2. Creating the RabbitMQ virtual machines

In the rest of this chapter, we’ll use free Amazon EC2 instances to set up multiple RabbitMQ servers that will use federation to transparently distribute messages without clustering. If you’d rather use your own cloud provider or pre-existing network and servers, the concepts remain the same. If you choose not to use Amazon Web Services (AWS) for the examples in this chapter, just create your own servers and try to match the environment setup as closely as possible. In either scenario, you should set up two RabbitMQ servers to work with the examples.

To set up the VMs on Amazon EC2, you’ll create the first instance, install and configure RabbitMQ, and then create an image of the instance, allowing you to create one or more copies of the server for experimentation. If you’re not providing your own virtual servers, you’ll need an AWS account. If you don’t already have one, you can create one for free at [http://aws.amazon.com](http://aws.amazon.com/).

#### 8.2.1. Creating the first instance

To begin, log into the AWS console and click Create Instance. You’ll be presented with a list of image templates for creating a VM. Select Ubuntu Server from the list ([figure 8.6](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-8/ch08fig06)). Once it’s selected, you’ll be presented with the next step, choosing the instance type. Select the general purpose t2.micro instance, which should be labeled as Free Tier Eligible.

![Figure 8.6. Selecting an AMI to launch an Amazon EC2 instance](https://drek4537l1klr.cloudfront.net/roy/Figures/08fig06_alt.jpg)

Once the instance type is selected, you’ll be presented with a configuration screen for the instance. You can leave the defaults selected on that screen and click the Next: Add Storage button. Leave the defaults on this screen as well, clicking on the Next: Tag Instance button. You don’t need to do anything on this screen either. Click Next: Configure Security Group, and you’ll be presented with the Security Group configuration. You’ll want to modify these settings so that you can communicate with RabbitMQ. Because this is just an example, you can open ports 5672 and 15672 to the internet without any source restrictions. Click the Add Rule button to allow for a new firewall rule to be defined, and create entries for each port with the Source set to Anywhere, as illustrated in [figure 8.7](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-8/ch08fig07).

![Figure 8.7. Configuring the Security Group’s firewall settings for RabbitMQ](https://drek4537l1klr.cloudfront.net/roy/Figures/08fig07_alt.jpg)

Once you’ve added the two rules, click the Review and Launch button. Once you’re on the review screen, click Launch. You’ll be presented with a dialog box allowing you to select an SSH key pair or create a new one. Select Create a New Key Pair from the first drop-down box, enter a name for it, and click Download Key Pair ([figure 8.8](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-8/ch08fig08)). You’ll want to save the key pair to an accessible location on your computer, as it will be used to SSH into the EC2 instance.

![Figure 8.8. Creating a new key pair for accessing the VM](https://drek4537l1klr.cloudfront.net/roy/Figures/08fig08_alt.jpg)

When you’ve downloaded the key pair, click the Launch Instance button. AWS will then begin the process of creating and starting your new VM instance. Navigate back to the EC2 dashboard, and you should see the new instance starting up or running ([figure 8.9](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-8/ch08fig09)).

![Figure 8.9. The EC2 dashboard with the newly created instance](https://drek4537l1klr.cloudfront.net/roy/Figures/08fig09_alt.jpg)

Once the new EC2 instance has started, it will have a public IP address and DNS. Make note of the IP address, as you’ll use it to connect to the VM to configure RabbitMQ.

##### Connecting to the EC2 instance

With the EC2 instance IP address and path to the SSH key pair in hand, you can now SSH into the VM and begin the process of setting up RabbitMQ. Connecting as the `ubuntu` user, you’ll need to specify the path to the SSH key pair. The following command references the file in the Downloads folder in my home directory.

```
ssh -i ~/Downloads/rabbitmq-in-depth.pem.txt ubuntu@[Public IP]
```

##### Note

If you’re in a Windows environment, there are several good applications for connecting over SSH to remote systems, including PuTTY (free, at [www.chiark.greenend.org.uk/~sgtatham/putty/](http://www.chiark.greenend.org.uk/~sgtatham/putty/)) and SecureCRT (commercial, [www.vandyke.com/products/securecrt/](http://www.vandyke.com/products/securecrt/)).

Once connected, you’ll be logged in as the `ubuntu` user, and you should see the MOTD banner, similar to the following:

```
1234567891011121314Welcome to Ubuntu 14.04.1 LTS (GNU/Linux 3.13.0-36-generic x86_64)

 * Documentation:  https://help.ubuntu.com/

  System information as of Sun Jan  4 23:36:53 UTC 2015

  System load: 0.0              Memory usage: 5%   Processes:       82

  Usage of /:  9.7% of 7.74GB   Swap usage:   0%   Users logged in: 0

Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.

ubuntu@ip-172-31-63-231:~$
```

Because there are a number of commands you need to issue as the `root` user, go ahead and switch users so you’re not typing the `sudo` command all of the time:

```
sudo su –
```

As the root user, you can now install the Erlang runtime and RabbitMQ on the first EC2 instance.

##### Installing Erlang and RabbitMQ

To install RabbitMQ and Erlang, you can use the official RabbitMQ and Erlang Solutions repositories. Although the main Ubuntu package repositories have support for both RabbitMQ and Erlang, it’s advisable to get the latest versions of both, and the distribution repositories can often be significantly out of date. To use the external repositories, you’ll need to add the package-signing keys and configuration for the external repositories.

First, add the RabbitMQ public key that enables Ubuntu to verify the file signatures of the packages being installed:

```
12apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 \
     --recv 6B73A36E6026DFCA
```

You’ll see output from the `apt-key` application stating that it imported the “RabbitMQ Release Signing Key <info@rabbitmq.com>.”

With the key imported to the database of trusted packaging keys, you can now add the official RabbitMQ package repository for Ubuntu. The following command will add a new file to the proper location, adding the RabbitMQ repository for use:

```
12echo "deb http://www.rabbitmq.com/debian/ testing main" \
     > /etc/apt/sources.list.d/rabbitmq.list
```

Now that the RabbitMQ repository has been configured, you’ll need to add the Erlang Solutions key to the trusted keys database:

```
12apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv \
     D208507CA14F4FCA
```

When `apt-key` has completed, you’ll see that it imported the “Erlang Solutions Ltd. <packages@erlang-solutions.com>” key.

Now add the Erlang Solutions Ltd. repository configuration:

```
12echo "deb http://packages.erlang-solutions.com/debian precise contrib" \
     > /etc/apt/sources.list.d/erlang-solutions.list
```

With the configuration and keys in place, the following command will synchronize the local database of packages and allow you to install RabbitMQ:

```
apt-get update
```

Now you can install Erlang and RabbitMQ. The `rabbitmq-server` package will automatically resolve the Erlang dependencies and install the proper packages.

```
apt-get install –y rabbitmq-server
```

Once the command has finished, you’ll have RabbitMQ up and running, but you’ll need to run a few more commands to enable the proper plugins and allow you to connect to both the AMQP port and the management interface.

##### Configuring RabbitMQ

RabbitMQ contains all of the functionality for both managing the server and using federation, but it’s not enabled by default. The first step in configuring the RabbitMQ instance is to enable the plugins that ship with RabbitMQ, which will allow you to set up and use its federation capabilities. To do so, use the `rabbitmq-plugins` command:

```
12rabbitmq-plugins enable rabbitmq_management rabbitmq_federation \
    rabbitmq_federation_management
```

As of RabbitMQ 3.4.0, this will automatically load the plugins without requiring a restart of the broker. But you’ll want to enable the default `guest` user to allow logins from IP addresses beyond `localhost`. To do so, you’ll need to create a RabbitMQ configuration file at /etc/rabbitmq/rabbitmq.config with the following content:

```
[{rabbit, [{loopback_users, []}]}].
```

You now need to restart RabbitMQ for the `loopback_users` setting to take effect:

```
service rabbitmq-server restart
```

To prevent confusion later when using both VMs, you can update the cluster name using the `rabbitmqctl` command. When you’re using the management interface, the cluster name is displayed in the top-right corner. To set the name via the command line, run the following command:

```
rabbitmqctl set_cluster_name cluster-a
```

You can now test that the installation and configuration worked. Open the management interface in your web browser using the IP address of the EC2 instance on port 15672 in this URL format: `http://[Public IP]:15672`. Once you log in as the `guest` user with the password “guest”, you should see the Overview screen ([figure 8.10](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-8/ch08fig10)).

![Figure 8.10. The RabbitMQ management UI Overview screen](https://drek4537l1klr.cloudfront.net/roy/Figures/08fig10_alt.jpg)

With the first instance created, you can leverage the Amazon EC2 dashboard to create an image from the running instance you just created, and use that image to launch a duplicate VM. The new image will make it easy to spin up new, pre-configured, standalone RabbitMQ servers for testing RabbitMQ’s federation capabilities.

#### 8.2.2. Duplicating the EC2 instance

Instead of duplicating the previous steps to create a standalone instance of RabbitMQ, let’s have Amazon do the work. To do so, you’ll need to tell EC2 to create a new image or AMI from the running VM instance you just created.

Navigate to the EC2 Instances dashboard in your web browser, and click on the running instance. When you do, a context-sensitive menu will pop up that allows you to perform commands on that instance. From that menu, navigate to Image > Create Image ([figure 8.11](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-8/ch08fig11)).

![Figure 8.11. Creating a new image based on the running instance](https://drek4537l1klr.cloudfront.net/roy/Figures/08fig11_alt.jpg)

Once you select Create Image, a pop-up dialog box will appear, allowing you to set options for creating the image. Give the image a name and leave the rest of the options alone. When you click on the Create Image button, the exiting VM will be shut down, and the disk image for the VM will be used to create a new AMI ([figure 8.12](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-8/ch08fig12)).

![Figure 8.12. The Create Image dialog box](https://drek4537l1klr.cloudfront.net/roy/Figures/08fig12_alt.jpg)

When the system has created the snapshot of the filesystem for the original VM, it will automatically be restarted, and the task of creating a new AMI will be queued in Amazon’s system. It will take a few minutes for the AMI to be available for use. You can check the status by clicking on the Images > AMIs option in the sidebar navigation ([figure 8.13](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-8/ch08fig13)).

![Figure 8.13. The AMI section of the EC2 dashboard](https://drek4537l1klr.cloudfront.net/roy/Figures/08fig13_alt.jpg)

Once your AMI is available, select it in the AMI dashboard, and then click the Launch button on the top button bar. This will start you at step two of creating the VM. You’ll go through all the steps you previously went through to create the original VM, but instead of creating a new security policy and SSH key pair, select the ones you created for the first VM.

When you’ve completed the steps to create the VM, navigate back to the EC2 Instances dashboard. Wait for the instance to become available, making note of its public IP address. One it’s running, you should be able to connect to its management interface via your web browser on port 15672 using the URL format http://[Public IP]:15672. Log in to the management interface and change the cluster name to “cluster-b” by clicking on the Change link at the top right corner and following the instructions on the page you’re sent to ([figure 8.14](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-8/ch08fig14)). This name change will make it easy to distinguish which server you’re logged in to when using the management interface.

![Figure 8.14. The cluster name is displayed in the top right of the management interface.](https://drek4537l1klr.cloudfront.net/roy/Figures/08fig14_alt.jpg)

With both EC2 instances up and running, you’re ready to set up federation between the two nodes. Although we’ve used Amazon EC2 in the same availability zone for both nodes in this example, federation is designed to work well in environments where network partitions can occur, allowing RabbitMQ to share messages across data centers and large geographic distances.

To get started, let’s use federation to copy messages from one node to another.

### 8.3. Connecting upstream

Whether you’re looking to leverage federation for cross-data-center delivery of messages or you’re using federation to seamlessly migrate your consumers and publishers to a new RabbitMQ cluster, you start in the same place: upstream configuration. Although the upstream node is responsible for delivering the messages to the downstream node, it’s the downstream node where the configuration takes place.

Federation configuration has two parts: the upstream configuration and a federation policy. First, the downstream node is configured with the information required for the node to make an AMQP connection to the upstream node. Then policies are created that apply upstream connections and configuration options to downstream exchanges or queues. A single RabbitMQ server can have many federation upstreams and many federation policies.

To start receiving messages from the upstream node, `cluster-a`, to the downstream node, `cluster-b`, you must first define the upstream in the RabbitMQ management interface.

#### 8.3.1. Defining federation upstreams

When installed, the federation management plugin adds two new Admin tabs to the RabbitMQ management interface: Federation Status and Federation Upstreams. Although the status screen will be blank until you create policies that configure exchanges or queues to use federation, the Federation Upstreams tab ([figure 8.15](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-8/ch08fig15)) is the first place you’ll go to start the configuration process.

![Figure 8.15. The Federation Upstreams tab in the Admin section of the management interface](https://drek4537l1klr.cloudfront.net/roy/Figures/08fig15_alt.jpg)

There are multiple options for adding a new upstream connection, but only the name and AMQP URI for the connection are required. In a production environment, you’ll likely want to configure the other options as well. If these options look familiar, it’s because they represent a combination of options available when defining a queue and when consuming messages. For your first upstream connection, leave them blank and let RabbitMQ use the default settings.

To define the connection information for the upstream node, enter the AMQP URI for the remote server. The AMQP URI specification allows for flexible configuration of the connection, including the ability to tweak the heartbeat interval, maximum frame size, connection port, username and password, and much more. The full specification for the AMQP URI syntax, including the available query parameters, is available on the RabbitMQ website at [www.rabbitmq.com/uri-spec.html](http://www.rabbitmq.com/uri-spec.html). Because the test environment we’re using is as simple as possible, you can use the defaults for everything but the hostname in the URL.

In your testing environment, the node representing `cluster-b` will act as the downstream node and connect to the node representing `cluster-a`. Open the management interface in your web browser and navigate to the Federation Upstreams tab in the Admin section. Expand the Add a New Upstream section and enter `cluster-a` as the name for the upstream. For the URI, enter `amqp://[Public IP]`, replacing `[Public IP]` with the IP address of the first node you set up in this chapter ([figure 8.16](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-8/ch08fig16)).

![Figure 8.16. Adding a new federation upstream](https://drek4537l1klr.cloudfront.net/roy/Figures/08fig16_alt.jpg)

The information you enter here defines a single connection to another RabbitMQ node. The connection won’t be used until a policy is created that references the upstream. When a policy is applied using the upstream, the federation plugin will connect to the upstream node. Should it be disconnected due to a routing error or some other network event, the default behavior is to try to reconnect once per second; you can change this behavior when defining the upstream in the Reconnect Delay field. If you want to change this after you’ve created an upstream, you must delete and recreate the upstream.

Once you’ve entered the name and URI, click Add Upstream to save the upstream configuration with RabbitMQ. After the upstream has been added, you can define the policy and test out exchange-based federation.

##### Note

Although the examples in this chapter use the management interface to create upstream nodes, you can also use the HTTP management API and the `rabbitmqctl` CLI application. For examples of using rabbitmqctl for adding upstreams, visit the federation plugin documentation at [http://rabbitmq.com](http://rabbitmq.com/).

#### 8.3.2. Defining a policy

Federation configuration is managed using RabbitMQ’s policy system, which provides a flexible way to dynamically configure the rules that tell the federation plugin what to do. When you create a policy, you first specify a policy name and a pattern. The pattern can either evaluate for direct string matching or it can specify a regular expression (regex) pattern to match against RabbitMQ objects. The pattern can be compared against exchanges, queues, or both exchanges and queues. Policies can also specify a priority that’s used to determine which policy should be applied to queues or exchanges that match multiple policies. When a queue or exchange is matched by multiple policies, the policy with the highest priority value wins. Finally, a policy has a definition table that allows for arbitrary key/value pairs to be specified.

For a first example, you’ll create a policy named `federation-test` that will do string-equality checking against an exchange named `test` ([figure 8.17](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-8/ch08fig17)). To tell the federation plugin that you want to federate the exchange from the `cluster-a` upstream, enter a key of `federation-upstream` with a value of `cluster-a` in the definition table. Once you’ve entered that information, click the Add Policy button to add it to the system.

![Figure 8.17. Adding a new policy using the cluster-a federation upstream node](https://drek4537l1klr.cloudfront.net/roy/Figures/08fig17_alt.jpg)

With the policy added, you’ll need to add the `test` exchange to both nodes. You can use the Exchanges tab of each management interface to add the exchange. To prevent the `cluster-b` node from trying to federate a non-existent exchange on the `cluster-a` node, declare the exchange on the `cluster-a` node first. You can use any of the built-in exchange types, but I recommend using a topic exchange for flexibility in experimenting. Whichever type you select, you should be consistent and use the same exchange type for the `test` exchange on both `cluster-a` and `cluster-b`.

Once you’ve added the exchange to both nodes, you’ll notice in the Exchanges tab of the management interface on the `cluster-b` node that the `test` exchange has a label matching the federation policy in the Features column ([figure 8.18](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-8/ch08fig18)). The label indicates that you successfully matched the policy to the exchange.

![Figure 8.18. The Exchanges table showing that the test exchange has the federation-test policy applied to it](https://drek4537l1klr.cloudfront.net/roy/Figures/08fig18_alt.jpg)

After verifying that the policy was applied correctly, check the federation status to make sure that the `cluster-b` node was able to connect properly to its upstream, `cluster-a`. Click on the Admin tab and then the Federation Status menu item on the right to see if everything was configured properly. If everything worked, you should see a table with a single entry, with `cluster-a` in the Upstream column. The State column should indicate the upstream is running ([figure 8.19](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-8/ch08fig19)).

![Figure 8.19. The Federation Status page indicates that the cluster-a upstream is running for the test exchange.](https://drek4537l1klr.cloudfront.net/roy/Figures/08fig19_alt.jpg)

Now that you’ve verified that RabbitMQ thinks everything is configured and running properly, you can test it by publishing messages on `cluster-a` and having them queued on `cluster-b`. To do so, create a test queue on `cluster-b` and bind it to the `test` exchange with a binding key of `demo`. This will set up the binding both locally on `cluster-b` and for the federation of messages to the test exchange on `cluster-a`.

Switch to the management interface for `cluster-a` and select the `test` exchange on the Exchanges tab. On the `test` exchange page, expand the Publish Message section. Enter the routing key `demo` and whatever content you’d like in the Payload field. When you click the Publish Message button, the message will be published to the `test` exchange on both `cluster-a` and `cluster-b`, and it should have been queued in your test queue on `cluster-b`.

Using the management interface for `cluster-b`, navigate to the Queues tab, and then select your test queue. Expand the Get Messages section and click the Get Message(s) button and you should see the message you published on `cluster-a` ([figure 8.20](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-8/ch08fig20)).

![Figure 8.20. The message published from cluster-a](https://drek4537l1klr.cloudfront.net/roy/Figures/08fig20_alt.jpg)

To help identify messages that were distributed via federation, the federation plugin adds an `x-received-from` field to the `headers` table in the message properties. The value of the field is a key/value table that includes the upstream `uri`, `exchange`, `cluster-name`, and a flag indicating if the message was `redelivered`.

#### 8.3.3. Leveraging upstream sets

In addition to defining individual upstream nodes, the federation plugin provides the ability to group multiple nodes together for use in a policy. This grouping functionality provides quite a bit of versatility in how you define your federation topology.

##### Providing redundancy

For example, imagine your upstream node is part of a cluster. You could create an upstream set that defines each node in the upstream cluster, allowing the downstream node to connect to every node in the cluster, ensuring that should any one node go down, messages published into the upstream cluster won’t be missed downstream ([figure 8.21](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-8/ch08fig21)).

![Figure 8.21. A cluster set can provide redundancy for communication with clustered upstream nodes.](https://drek4537l1klr.cloudfront.net/roy/Figures/08fig21.jpg)

If you’re using a federated exchange in a downstream cluster, should the node connecting to the upstream fail in the cluster, another node will automatically take over the role, connecting upstream.

##### Geographically distributed applications

A more complex scenario could involve a geographically distributed web application. Suppose you’re tasked with developing a service that records views of a banner advertisement. The goal is to serve the banner ad as quickly as possible, so the application is deployed to locations throughout the world, and DNS-based load balancing is employed to distribute the traffic to the closest data center for any given user. When the user views the advertisement, a message is published to a local RabbitMQ node that acts as a federation upstream node for a central processing system. The centralized RabbitMQ node has defined a federation upstream set that contains the RabbitMQ server in each geographically distributed location. As messages come into each location, they’re relayed to the central RabbitMQ server and processed by consumer applications ([figure 8.22](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-8/ch08fig22)).

![Figure 8.22. Geographically distributed upstreams in a set deliver messages to the downstream node.](https://drek4537l1klr.cloudfront.net/roy/Figures/08fig22_alt.jpg)

Because the client-like behavior of the federation plugin allows for connection failures, should any of the geographically distributed nodes go offline, the processing of traffic from the rest of the system isn’t impacted. Should it just be a regional routing issue, all of the queued messages from the disconnected upstream will be delivered once the downstream is able to reconnect.

##### Creating an upstream set

To create an upstream set, first define each upstream node either in the management interface or via the `rabbitmqctl` CLI application. Because there’s no interface for creating upstream sets in the federation management interface, you must use the `rabbitmqctl` command-line tool. As with any other use of `rabbitmqctl`, you must run it locally on the RabbitMQ node you wish to perform the configuration on and as a user that has access to RabbitMQ’s Erlang cookie, which was discussed in [section 7.2.2](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-7/ch07lev2sec5).

With your list of upstream nodes in hand, create a JSON string that contains the list of the names you used when creating the upstream definitions. For example, if you created upstreams named `a-rabbit1` and `a-rabbit2`, you’d create the following JSON snippet:

```
[{"upstream": " a-rabbit1"}, [{"upstream": " a-rabbit2"}]
```

Then, to define an upstream set named `cluster-a`, run the `rabbitmqctl` command `set_parameter`, which allows you to define a `federation-upstream-set` named `cluster-a`.

```
rabbitmqctl set_parameter federation-upstream-set cluster-a \
      '[{"upstream": " a-rabbit1"}, {"upstream: " a-rabbit2"}]'
```

Once the upstream set is defined, you can reference it by name when creating a federation policy by using the `federation-upstream-set` key to define the policy instead of using the `federation-upstream` key you used to reference an individual node.

It’s also worth noting that there’s an implicitly defined upstream set named `all` that doesn’t require any configuration. As you might expect, the `all` set will include every defined federation upstream.

#### 8.3.4. Bidirectional federated exchanges

The examples in this chapter have thus far covered distributing messages from an upstream exchange to a downstream exchange, but federated exchanges can be set up to be bidirectional.

In a bidirectional setup, messages can be published into either node, and using the default configuration, they’ll only be routed once on each node. This setting can be tweaked by the `max-hops` setting in the upstream configuration. The default value of `1` for `max-hops` prevents message loops where messages received from an upstream node are cyclically sent back to the same node. When you use a federated exchange where each node acts as an upstream and downstream node to each other, messages published into either node will be routed on each node, similar to how message routing behaves in a cluster ([figure 8.23](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-8/ch08fig23)).

![Figure 8.23. Messages published to either node of a bidirectional federated exchange will be routed on each node.](https://drek4537l1klr.cloudfront.net/roy/Figures/08fig23.jpg)

This type of federation behavior works well for creating a fault-tolerant, multi-data-center application structure. Instead of sharding data across data centers or locations, this type of federation allows for each location to receive the same messages for processing data.

Although this is a very powerful way to provide a highly available service, it also creates additional complexity. All of the complexities and concerns around multi-master databases become concerns when trying to keep a consistent view of data across locations using federation. Consensus management becomes very important to ensure that when data is acted upon it’s done so consistently across locations. Fortunately, federated exchanges can provide an easy way to achieve consensus messaging across locations. It’s also worth considering that this behavior isn’t limited to two nodes, but can be set up in a graph where all nodes connect to all other nodes ([figure 8.24](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-8/ch08fig24)). As in a two-node setup, setting `max-hops` to `1` for an upstream will prevent messages from cyclically republishing around the graph.

![Figure 8.24. More than two nodes in a graph-like setup for federated exchanges](https://drek4537l1klr.cloudfront.net/roy/Figures/08fig24.jpg)

It’s important to recognize that like any graph structure, the more nodes you add, the more complex things become. As with all aspects of implementing a message-oriented architecture, you should benchmark the performance of your architecture prior to production use. Fortunately, cloud service providers like Amazon have different availability zones, so it’s easy to build-out and test complex federation environments with RabbitMQ.

#### 8.3.5. Federation for cluster upgrades

One of the more difficult operational concerns with managing a RabbitMQ cluster is handling upgrades in a production environment where downtime is undesirable. There are multiple strategies for dealing with such a scenario.

If the cluster is large enough, you can move all traffic off a node, remove it from the cluster, and upgrade it. Then you could take another node offline, remove it from the cluster, upgrade it, and add it to a new cluster consisting of the node that was removed first. You continue to shuffle through your cluster like this, taking nodes offline one by one, until they’re all removed, upgraded, and re-added in reverse order. If your publishers and consumers handle reconnection gracefully, this approach can work, but it’s laborious. Alternatively, provided that you have the resources to set up a mirror of the cluster setup on a new version of the cluster, federation can provide a seamless way to migrate your messaging traffic from one cluster to another.

When using federation as a means to upgrade RabbitMQ, you start by rolling out the new cluster, creating the same runtime configuration on the new cluster, including virtual hosts, users, exchanges, and queues. Once you’ve set up and configured the new cluster, add the federation configuration, including the upstreams and policies to wildcard-match on all exchanges. Then you can start migrating your consumer applications, changing their connections from the old cluster to the new cluster ([figure 8.25](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-8/ch08fig25)).

![Figure 8.25. The second stage of using federation to upgrade a RabbitMQ cluster](https://drek4537l1klr.cloudfront.net/roy/Figures/08fig25_alt.jpg)

As you migrate the consumers off a queue, you should unbind the queue on the old cluster, but don’t delete it. Instead, you can create a temporary policy on the new cluster to federate that queue, moving the messages from the old cluster to the new one. It’s advisable to automate this process as much as possible, because you want to minimize the chance of duplicate messages being added to the new cluster’s queues due to using both the federated exchange and the federated queue.

Once you’ve finished moving all of the consumers off, and you’ve unbound the queues on the old cluster, you can migrate the publishers. When all of your publishers have been moved, you should be fully migrated to the upgraded RabbitMQ cluster. Of course, you may want to keep the federation going for a while to ensure that no rogue publishers are connecting to the old cluster when they’re not expected to do so. This will allow you to keep your application operating properly, and you can use the RabbitMQ logs on the old cluster nodes to monitor for connections and disconnections. Although the federation plugin may not have originally been intended for such a task, it proves to be the perfect tool for zero-downtime RabbitMQ upgrades.

### 8.4. Summary

The flexibility and power provided by the federation plugin is limited only by your imagination. Whether you’re looking to transparently migrate traffic from one RabbitMQ cluster to another, or you’d like to create a multi-data-center application that shares all messages across all nodes, the federation plugin is a reliable and efficient solution. As a scale-out tool, federated queues provide a way to greatly increase the capacity of a single queue by defining it on an upstream node and any number of downstream nodes. Combined with clustering and HA queues, federation not only allows for network partition tolerance between clusters, but also provides a fault-tolerance should nodes in either the upstream set or downstream clusters fail.

And failures do occasionally happen. In the next chapter you’ll learn multiple strategies for monitoring and alerting when things go wrong.
