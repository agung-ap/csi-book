# Chapter 7. Scaling RabbitMQ with clusters

### This chapter covers

- Cluster management
- How queue location can impact performance
- The steps involved in setting up a cluster
- What to do when nodes crash

As a message broker, RabbitMQ is perfect for standalone applications. But suppose your application needs additional delivery guarantees that only highly available queues will satisfy. Or maybe you want to use RabbitMQ as a central messaging hub for many applications. RabbitMQ’s built-in clustering capabilities provide a robust, cohesive environment that can span multiple servers.

I’ll start by describing the features and behaviors of RabbitMQ clusters, and then you’ll set up a two-node RabbitMQ cluster in the Vagrant virtual machine (VM) environment. In addition, you’ll learn how queue placement is important for a performant cluster and how to set up HA queues. You’ll also learn how RabbitMQ’s clustering works at a low level and what server resources are most important to ensure cluster performance and stability. Closing out the chapter, you’ll learn how to recover from crashes and node failures.

### 7.1. About clusters

A RabbitMQ cluster creates a seamless view of RabbitMQ across two or more servers. In a RabbitMQ cluster, runtime state containing exchanges, queues, bindings, users, virtual hosts, and policies are available to every node. Because of this shared runtime state, every node in a cluster can bind, publish, or delete an exchange that was created when connected to the first node ([figure 7.1](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-7/ch07fig01)).

![Figure 7.1. Cross-node publishing of messages in a cluster](https://drek4537l1klr.cloudfront.net/roy/Figures/07fig01_alt.jpg)

RabbitMQ’s cohesive clusters create a compelling way to scale RabbitMQ. In addition, clusters provide a mechanism that allows you to create a structured architecture for your publishers and consumers. In larger cluster environments, it’s not uncommon to have nodes dedicated to specific tasks or queues. For example, you might have cluster nodes that act strictly as publishing front ends and others that are strictly used for queues and consumers. If you’re looking to create fault tolerance in your RabbitMQ environment, clusters provide an excellent way to create HA queues. HA queues span multiple cluster nodes and share a synchronized queue state, including message data. Should any node with an HA queue fail, the other nodes in the cluster will still contain the messages and queue state. When the failed node rejoins the cluster, the newly rejoined node will fully synchronize once any messages that were added while the node was down are consumed.

Despite the advantages of using RabbitMQ’s built-in clustering, it’s important to recognize the limitations and downsides of RabbitMQ clustering. First, clusters are designed for low-latency environments. You should never create RabbitMQ clusters across a WAN or internet connection. State synchronization and cross-node message delivery demand low-latency communication that can only be achieved on a LAN. You can run RabbitMQ in cloud environments such as Amazon EC2, but not across availability zones. To synchronize RabbitMQ messages in high-latency environments, you’ll want to look at the Shovel and Federation tools outlined in the next chapter.

Another important issue to consider with RabbitMQ clusters is cluster size. The work and overhead of maintaining the shared state of a cluster is directly proportionate to the number of nodes in the cluster. For example, using the management API to gather statistical data in a large cluster can take considerably longer than in a single node. Such actions can only be as fast as the slowest node to respond. Conventional wisdom in the RabbitMQ community calls for an upper bound of 32 to 64 nodes in a cluster. Remember, as you add a node to a cluster, you’re adding complexity to the synchronization of the cluster. Each node in a cluster must know about every other node in the cluster. This non-linear complexity can slow down cross-node message delivery and cluster management. Fortunately, even with this complexity, the RabbitMQ management UI can handle large clusters.

#### 7.1.1. Clusters and the management UI

The RabbitMQ management UI is built to perform all of the same actions on a cluster that it performs with a single node, and it’s a great tool for understanding your RabbitMQ clusters once they’ve been created. The Overview page of the management UI contains top-level information about a RabbitMQ cluster and its nodes ([figure 7.2](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-7/ch07fig02)).

![Figure 7.2. The management interface, highlighting cluster status with a single node](https://drek4537l1klr.cloudfront.net/roy/Figures/07fig02_alt.jpg)

In the highlighted area of [figure 7.2](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-7/ch07fig02), cluster nodes are listed with columns that describe their general health and state. As you add nodes to a cluster, they’ll be added to the table. In larger clusters, this table may take more time to refresh, as each time the API is called to gather the information, each node in the cluster is queried for updated information prior to returning a response.

But before we go too deep into the management UI with regard to clusters, it’s important to understand the types of nodes in a RabbitMQ cluster.

#### 7.1.2. Cluster node types

There are multiple node types with different behavior in a RabbitMQ cluster. When a node is added to a cluster, it carries with it one of two primary designations: disk node or RAM node.

Disk nodes store the runtime state of a cluster to both RAM and disk. In RabbitMQ, runtime state includes the definition of exchanges, queues, bindings, virtual hosts, users, and policies. Because of this, in clusters with large amounts of runtime state, disk I/O may be more of an issue with disk nodes than with RAM nodes.

RAM nodes only store the runtime state information in an in-memory database.

##### Node types and message persistence

Designation of a disk node or a RAM node doesn’t control the behavior of persistent message storage. When a message is marked as persistent in the `delivery-mode` message property, the message will be written to disk regardless of the node type. Because of this, it’s important to consider the impact that disk I/O may have on your RabbitMQ cluster nodes. If you require persisted messages, you should provide a disk subsystem that can handle the write velocity required by the queues that live on your cluster nodes.

##### Node types and crash behavior

If a node or cluster crashes, disk nodes will be used to reconstruct the runtime state of the cluster as they’re started and rejoin the cluster. RAM nodes, on the other hand, won’t contain any runtime state data when they join a cluster. Upon rejoining a cluster, other nodes in the cluster will send it information such as queue definitions.

You should always have at least one disk node when creating a cluster, and in some cases more. Having more than one disk node in a cluster can provide more resilience in the event of hardware failures. But having multiple disk nodes can be a double-edged sword in some failure scenarios. If you have multiple node failures in a cluster with two disk nodes that don’t agree about the shared state of the cluster, you’ll have problems trying to recover the cluster to its previous state. If this happens, shutting down the entire cluster and restarting the nodes in order can help. Start the disk node with the most correct state data, and then add the other nodes. Later in this chapter we’ll discuss additional strategies for troubleshooting and recovering clusters.

##### The stats node

If you use the rabbitmq-management plugin, there’s an additional node type that only works in conjunction with disk nodes: the stats node. The stats node is responsible for gathering all of the statistical and state data from each node in a cluster. Only one node in a cluster can be the stats node at any given time. A good strategy for larger cluster setups is to have a dedicated management node that’s your primary disk node and the stats node, and to have at least one more disk node to provide failover capabilities ([figure 7.3](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-7/ch07fig03)).

![Figure 7.3. A cluster with a secondary disk node and two RAM-only nodes](https://drek4537l1klr.cloudfront.net/roy/Figures/07fig03.jpg)

Depending on the frequency and use of the management API and the quantity of resources used in RabbitMQ, there can be a high CPU cost for running the management API. Running a dedicated management node ensures that message delivery doesn’t slow statistics gathering, and statistics gathering doesn’t impact message delivery rates.

In a cluster topology setup with two disk nodes, if the primary node fails, the stats node designation will be transferred to the secondary disk node. Should the primary disk node come back up, it will not regain the stats node designation unless the secondary disk node with the stats node designation stops or leaves the cluster.

The stats node plays an important part in managing your RabbitMQ clusters. Without the rabbitmq-management plugin and a stats node, it can be difficult to get cluster-wide visibility of performance, connections, queue depths, and operational issues.

#### 7.1.3. Clusters and queue behavior

A message published into any cluster node will be properly routed to a queue without regard to where that queue exists in the cluster. When a queue is declared, it’s created on the cluster node the `Queue.Declare` RPC request was sent to. Which node a queue is declared on can have an impact on message throughput and performance. A node with too many queues, publishers, and consumers can be slower than if the queues, publishers, and consumers were balanced across nodes in a cluster. In addition to not evenly distributing resource utilization, not considering the location of a queue in a cluster can have an impact on both publishing and consuming.

##### Publishing considerations

You might recognize [figure 7.4](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-7/ch07fig04), which is slightly modified from a figure in [chapter 4](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-4/ch04). When publishing to a cluster, this scale becomes even more important than on a single RabbitMQ server.

![Figure 7.4. Performance of delivery guarantee options in RabbitMQ](https://drek4537l1klr.cloudfront.net/roy/Figures/07fig04_alt.jpg)

As you move from left to right on the scale, the amount of cross-cluster communication between nodes is amplified. If you’re publishing messages on one node that are routed to queues on another, the two nodes will have to coordinate on a delivery guarantee method.

For example, consider [figure 7.5](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-7/ch07fig05), which illustrates the logical steps for messages published across nodes while using publisher confirmations.

![Figure 7.5. Multi-node publishing with consumer confirmations](https://drek4537l1klr.cloudfront.net/roy/Figures/07fig05_alt.jpg)

Although the steps outlined in [figure 7.5](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-7/ch07fig05) wouldn’t greatly reduce message throughput, you should consider the complexity of confirmation behavior when creating your messaging architecture using clusters. Benchmark the various methods with publishers and consumers on the various nodes, and see what works best for you. Throughput might not be the best indicator of the successful implementation of a messaging architecture; poor performance can surely have a negative impact.

As with a single node, publishing is only one side of the coin when it comes to message throughput. Clusters can have an impact on message throughput for consumers too.

##### Node-specific consumers

To improve message throughput in a cluster, RabbitMQ tries to route newly published messages to pre-existing consumers whenever possible. But in queues with a backlog of messages, new messages are published across the cluster into the nodes where the queues are defined. In this scenario, performance can suffer when you connect a consumer to a node that’s different than the node where the queue is defined ([figure 7.6](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-7/ch07fig06)).

![Figure 7.6. Cross-cluster node message consuming](https://drek4537l1klr.cloudfront.net/roy/Figures/07fig06_alt.jpg)

In this scenario, messages are published into a queue located on node 2, and a consumer is connected to node 1. When messages are retrieved from the queue for the consumer connected to node 1, they must first travel through the cluster to node 1 before being delivered to the consumer. If you consider where the queue lives when connecting a consumer, you can reduce the overhead required to send the message to the consumer. Instead of having messages travel through the cluster to your consumers, the node where the queue lives can directly deliver messages to consumers connected to it ([figure 7.7](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-7/ch07fig07)).

![Figure 7.7. By connecting to the same node that a queue lives on, consumers can see improved throughput.](https://drek4537l1klr.cloudfront.net/roy/Figures/07fig07_alt.jpg)

By considering queue locality and connecting to the appropriate node for consumers and publishers alike, you can reduce cross-cluster communication and improve overall message throughput. High-velocity publishers and consumers will see the greatest impact on directly connecting to the appropriate nodes for their queues. That is, of course, unless you’re using HA queues.

##### Highly available queues

It should be no surprise that using HA queues can come with a performance penalty. When placing a message in a queue or consuming a message from a queue, RabbitMQ must coordinate among all the nodes that the HA queue lives on. The more nodes an HA queue lives on, the more coordination there is among nodes.

In large clusters, you should consider just how many nodes your queue should use prior to declaring it. If you’re asking for all nodes on a 24-node cluster, you’re likely creating a lot of work for RabbitMQ with very little reward. Because HA queues have a copy of each message on each node, you should ask yourself if you need more than two or three nodes to ensure that you don’t lose any messages.

### 7.2. Cluster setup

A RabbitMQ cluster requires two or more nodes. In this section, you’ll set up a cluster using two Vagrant VMs. The Vagrant configuration you downloaded in the appendix (while doing the setup for [chapter 2](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-2/ch02)) has a configuration for both VMs used in the following examples. The primary VM you’ve used to this point will be the first server in the cluster, and you’ll use the secondary VM definition in Vagrant for this chapter.

To start the process of setting up a cluster, you’ll boot the secondary VM and log into it via a secure shell.

#### 7.2.1. Virtual machine setup

Change to the location where you unzipped the rmqid-vagrant.zip file when setting up the environment for the book. Start the second VM by telling Vagrant to start the VM:

```
vagrant up secondary
```

This will start a second VM that you’ll use to set up and experiment with RabbitMQ clustering. When it has finished setting up the VM, you should see output similar to [figure 7.8](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-7/ch07fig08).

![Figure 7.8. Output of vagrant up secondary](https://drek4537l1klr.cloudfront.net/roy/Figures/07fig08_alt.jpg)

With the VM running, you can now open a secure shell by running the following Vagrant command in the same directory:

```
vagrant ssh secondary
```

You should now be connected into the second VM as the `vagrant` user. You’ll need to run your commands as the root user, however, so switch to the root user with the following command:

```
sudo su –
```

When you run this command, the prompt you see in the secure shell should change from `vagrant@secondary:~$` to `root@secondary:~#` indicating that you’re now logged in as the root user in the VM. As the root user, you’ll have permission to run the `rabbitmqctl` script to communicate with the local RabbitMQ server instance on the box.

Now it’s time to set up the cluster.

#### 7.2.2. Adding nodes to the cluster

There are two ways to add nodes to a cluster with RabbitMQ.

The first involves editing the rabbitmq.config configuration file and defining each node in a cluster. This method is preferred if you’re using an automated configuration management tool, such as Chef ([www.getchef.com](http://www.getchef.com/)) or Puppet ([www.puppetlabs.com](http://www.puppetlabs.com/)) and you have a well-defined cluster from the outset. Before you create a cluster via the rabbitmq.config file, it’s useful to create one manually.

Alternatively, you can add and remove nodes from a cluster in an ad hoc manner by using the `rabbitmqctl` command-line tool. This method provides a less rigid structure for learning about RabbitMQ cluster behavior and is good to know for troubleshooting degraded clusters. You’ll use `rabbitmqctl` to create a cluster between the VMs in this section, but prior to doing so, you should know something about Erlang cookies and their impact on RabbitMQ clustering.

##### Erlang cookies

To communicate between nodes, RabbitMQ uses the built-in, multi-node communication mechanisms in Erlang. To secure this multi-node communication, Erlang and the RabbitMQ process have a shared secret file called a *cookie*. The Erlang cookie file for RabbitMQ is contained in the RabbitMQ data directory. On *NIX platforms, the file is usually at /var/lib/rabbitmq/.erlang.cookie, though this can vary by distribution and package. The cookie file contains a short string and should be the same on every node in a cluster. If the cookie file isn’t the same on each node in the cluster, the nodes won’t be able to communicate with each other.

The cookie file will be created the first time you run RabbitMQ on any given server, or if the file is missing. When setting up a cluster, you should ensure that RabbitMQ isn’t running and you overwrite the cookie file with the shared cookie file prior to starting RabbitMQ again. The Chef cookbooks that set up the Vagrant VMs for this book have already set up the Erlang cookie to match on both machines. That means you can get started creating a cluster using `rabbitmqctl`.

##### Note

Using `rabbitmqctl` is an easy way to add and remove nodes in a cluster. It can also be used to change a node from a disk node to a RAM node and back. `rabbitmqctl` is a wrapper to an Erlang application that communicates with RabbitMQ. As such, it also needs access to the Erlang cookie. When you run the command as root, it knows where to look for the cookie file and will use it if it can. If you have trouble using `rabbitmqctl` in your production environment, make sure the user you’re running `rabbitmqctl` as either has access to the RabbitMQ Erlang cookie, or has a copy of the file in its home directory.

##### Creating ad hoc clusters

With RabbitMQ running on the node, and you logged in as the root user, you can now add the secondary VM node, creating a cluster with the primary VM node.

To do so, you must first tell RabbitMQ on the secondary node to stop using `rabbitmqctl`. You won’t be stopping the RabbitMQ server process itself, but using `rabbitmq` to instruct RabbitMQ to halt internal processes in Erlang that allow it to process connections. Run the following command in the terminal:

```
rabbitmqctl stop_app
```

You should see output similar to the following:

```
12Stopping node rabbit@secondary ...
...done.
```

Now that the process has stopped, you need to erase the state in this RabbitMQ node, making it forget any runtime configuration data or state that it has. To do this, you’ll instruct it to reset its internal database:

```
rabbitmqctl reset
```

You should see a response similar to this:

```
Resetting node rabbit@secondary ...
...done.
```

Now you can join it to the primary node and form the cluster:

```
rabbitmqctl join_cluster rabbit@primary
```

This should return with the following output:

```
Clustering node rabbit@secondary with rabbit@primary ...
...done.
```

Finally, start the server again using the following command:

```
rabbitmqctl start_app
```

You should see the output that follows:

```
Starting node rabbit@secondary ...
...done.
```

Congratulations! You now have a running RabbitMQ cluster with two nodes. If you open the management UI in your browser at http://localhost:15672 you should see an Overview page similar to [figure 7.9](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-7/ch07fig09).

![Figure 7.9. A two-node RabbitMQ cluster](https://drek4537l1klr.cloudfront.net/roy/Figures/07fig09_alt.jpg)

##### Configuration-based clusters

Creating a cluster using the configuration file can be a little trickier. When you set up the cluster using `rabbitmqctl`, you issued the `reset` command to the server, telling it to forget all of its state and internal data. With configuration-file-based clusters, you can’t do this, as RabbitMQ attempts to join a node to the cluster when the server starts. If you install RabbitMQ and the server starts before you create the configuration file that has the cluster definition in it, the node will fail to join the cluster.

If you’re using a configuration management tool, one way around this is to create the /etc/rabbitmq.config file prior to installing RabbitMQ. The new installation shouldn’t overwrite the pre-existing configuration file. During this same phase of configuration, it’s a good idea to write the Erlang cookie file that’s shared across all nodes of the cluster.

Defining a cluster in configuration is straightforward. In the /etc/rabbitmq.config file, there’s a stanza named `cluster_nodes` that carries the list of nodes in the cluster and indicates whether the node is a disk node or a RAM node. The following configuration snippet would be used to define the VM cluster you previously created:

```
[{rabbit,
  [{cluster_nodes, {['rabbit@primary', 'rabbit@secondary'], disc}}]
}].
```

If you were to use this configuration on both nodes, they’d both be set up as disk nodes in the cluster. If you wanted to make the secondary node a RAM node, you could change the configuration, substituting the `disc` keyword with `ram`:

```
[{rabbit,
  [{cluster_nodes, {['rabbit@primary', 'rabbit@secondary'], ram}}]
}].
```

A downside to configuration-based clusters is that because they’re defined in the configuration file, adding and removing nodes requires updating the configuration of all nodes in the cluster prior to a node being added or removed. It’s also worth noting that cluster information is ultimately stored as state data in the disk nodes in a cluster. Defining the cluster in the configuration file tells RabbitMQ nodes to join a cluster the first time they start up. This means that if you change your topology or configuration, it won’t impact that node’s membership in a cluster.

### 7.3. Summary

Clustering in RabbitMQ is a powerful way to scale your messaging architecture and create redundancy in your publishing and consuming endpoints. Although RabbitMQ’s cohesive cluster topology allows for publishing and consuming from any node in a cluster, publishers and consumers should consider the location of the queues they’re working with to achieve the highest throughput.

For LAN environments, clusters provide a solid platform for the growth of your messaging platform, but clusters aren’t meant for high-latency networks such as WANs and the internet. To connect RabbitMQ nodes across WANs or the internet, RabbitMQ comes with two plugins that we’ll discuss in the next chapter.
