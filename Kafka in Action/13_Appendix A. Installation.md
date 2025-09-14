# [](https://livebook.manning.com/book/kafka-in-action/appendix-a/)[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)Appendix A. Installation

[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)Despite having a sophisticated feature set, the Apache Kafka installation process is straightforward. Let’s look at setup concerns first.

## [](https://livebook.manning.com/book/kafka-in-action/appendix-a/)A.1 Operating system (OS) requirements

[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)Linux is the most likely home for Kafka, and that seems to be where many user support forums continue to focus their questions and answers. We’ve used macOS with Bash (a default terminal before macOS Catalina) or zsh (the default terminal since macOS Catalina). Though it’s totally fine to run Kafka on Microsoft® Windows® for development, it’s not recommended in a production environment [1].

##### NOTE

[](https://livebook.manning.com/book/kafka-in-action/appendix-a/) In a later section, we also explain installation using Docker ([http://docker.com](http://docker.com/)). [](https://livebook.manning.com/book/kafka-in-action/appendix-a/)

## [](https://livebook.manning.com/book/kafka-in-action/appendix-a/)A.2 Kafka versions

[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)Apache Kafka is an active Apache Software Foundation project, and over time, the versions of Kafka are updated. Kafka releases have, in general, taken backward compatibility seriously. If you want to use a new version, do so and update any parts of the code marked as deprecated.

##### TIP

[](https://livebook.manning.com/book/kafka-in-action/appendix-a/) Generally, Apache ZooKeeper and Kafka should not run on one physical server in a production environment if you want fault tolerance. For this book, we wanted to make sure you focus on learning Kafka features instead of managing multiple servers while you’re learning. [](https://livebook.manning.com/book/kafka-in-action/appendix-a/)

## [](https://livebook.manning.com/book/kafka-in-action/appendix-a/)A.3 Installing Kafka on your local machine

[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)When some of the authors started using Kafka, one of the more straightforward options was to create a cluster on a single node by hand. Michael Noll, in the article “Running a Multi-Broker Apache Kafka 0.8 Cluster on a Single Node,” laid out the steps in a clear manner, as reflected in this section’s setup steps [2].

[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)Although written in 2013, this setup option is still a great way to see the details involved and changes needed that might be missed in a more automated local setup. Docker setup is also an option for local setup, provided later in this appendix if you feel more comfortable with that.

[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)From our personal experience, you can install Kafka on a workstation with the following minimum requirements (however your results may vary from our preferences). Then use the instructions in the following sections to install Java and Apache Kafka (which includes ZooKeeper) on your workstation:

-  [](https://livebook.manning.com/book/kafka-in-action/appendix-a/)Minimum number of CPUs (physical or logical): 2
-  [](https://livebook.manning.com/book/kafka-in-action/appendix-a/)Minimum amount of RAM: 4 GB
-  [](https://livebook.manning.com/book/kafka-in-action/appendix-a/)Minimum hard drive free space: 10 GB

### [](https://livebook.manning.com/book/kafka-in-action/appendix-a/)A.3.1 Prerequisite: Java

[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)Java is a prerequisite that you should install first. For the examples in this book, we use the Java Development Kit (JDK) version 11. You can download Java versions from [https://jdk.dev/download/](https://jdk.dev/download/). We recommend using the SDKMAN CLI at [http://sdkman.io](http://sdkman.io/) to install and manage Java versions on your machine. [](https://livebook.manning.com/book/kafka-in-action/appendix-a/)[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)

### [](https://livebook.manning.com/book/kafka-in-action/appendix-a/)A.3.2 Prerequisite: ZooKeeper

[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)At the time of writing, Kafka also requires ZooKeeper, which is bundled with the Kafka download. Even with the reduced dependency on ZooKeeper from the client side in recent versions, Kafka needs a running installation of ZooKeeper to work. The Apache Kafka distribution includes a compatible version of ZooKeeper; you don’t need to download and install it separately. The required scripts to start and stop ZooKeeper are also included in the Kafka distribution. [](https://livebook.manning.com/book/kafka-in-action/appendix-a/)[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)

### [](https://livebook.manning.com/book/kafka-in-action/appendix-a/)A.3.3 Prerequisite: Kafka download

[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)At the time of this book’s publication, Kafka version 2.7.1 (the version used in our examples) was a recent release. The Apache® project has mirrors, and you can search for the version to download in that way. To be automatically redirected to the nearest mirror, use this URL: [http://mng.bz/aZo7](http://mng.bz/aZo7).

[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)After downloading the file, take a look at the actual binary filename. It might seem a little confusing at first. For example, kafka_2.13-2.7.1 means the Kafka version is 2.7.1 (the information after the hyphen).

[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)To get the most out of the examples in this book while still making things easy to get started, we recommend that you set up a three-node cluster on a single machine. This is not a recommended strategy for production, however, but it will allow you to understand critical concepts without the overhead of spending a lot of time on the setup.

##### NOTE

[](https://livebook.manning.com/book/kafka-in-action/appendix-a/) Why bother to use a three-node cluster? Kafka’s various parts as a distributed system lend themselves to more than one node. Our examples simulate a cluster without the need for different machines in the hope of clarifying what you are learning.

[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)After you install Kafka, you need to configure a three-node cluster. First, you need to unpack the binary and locate the bin directory.

[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)Listing A.1 shows [](https://livebook.manning.com/book/kafka-in-action/appendix-a/)[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)the `tar` command used to unpack the JAR file, but you might need to use unzip or another tool, depending on your downloaded compression format [3]. It’s a good idea to include the Kafka scripts bin directory in your `$PATH` environment variable. In this case, the commands are available without specifying a full path to them.

##### [](https://livebook.manning.com/book/kafka-in-action/appendix-a)Listing A.1 Unpacking the Kafka binary

```
1234$ tar -xzf kafka_2.13-2.7.1.tgz
$ mv kafka_2.13-2.7.1 ~/
$ cd ~/kafka_2.13-2.7.1
$ export PATH=$PATH:~/kafka_2.13-2.7.1/bin
```

##### NOTE

[](https://livebook.manning.com/book/kafka-in-action/appendix-a/) For Windows users, you’ll find the .bat scripts under the bin/windows folder with the same names as the shell scripts used in the following examples. You can use Windows Subsystem for Linux 2 (WSL2) and run the same commands as you would use on Linux [1]. [](https://livebook.manning.com/book/kafka-in-action/appendix-a/)[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)

### [](https://livebook.manning.com/book/kafka-in-action/appendix-a/)A.3.4 Starting a ZooKeeper server

[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)The examples in this book use a single, local ZooKeeper server. The command in listing A.2 starts a single ZooKeeper server [2]. Note that you’ll want to start ZooKeeper before you begin any Kafka brokers. [](https://livebook.manning.com/book/kafka-in-action/appendix-a/)[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)

##### [](https://livebook.manning.com/book/kafka-in-action/appendix-a)Listing A.2 Starting ZooKeeper

```
12$ cd ~/kafka_2.13-2.7.1
$ bin/zookeeper-server-start.sh config/zookeeper.properties
```

### [](https://livebook.manning.com/book/kafka-in-action/appendix-a/)A.3.5 Creating and configuring a cluster by hand

[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)The next step is to create and configure a three-node cluster. To create your Kafka cluster, you’ll set up three servers (brokers): `server0`, `server1`, and `server2`. We will modify the property files for each server [2].

[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)Kafka comes with a set of predefined defaults. Run the commands in listing A.3 to create configuration files for each server in your cluster [2]. We will use the default server.properties file as a starting point. Then run the command in listing A.4 to open each configuration file and change the properties file [2].

##### [](https://livebook.manning.com/book/kafka-in-action/appendix-a)Listing A.3 Creating multiple Kafka brokers

```bash
$ cd ~/kafka_2.13-2.7.1                                  #1
$ cp config/server.properties config/server0.properties
$ cp config/server.properties config/server1.properties
$ cp config/server.properties config/server2.properties
```

##### NOTE

[](https://livebook.manning.com/book/kafka-in-action/appendix-a/) In our examples, we use vi as our text editor, but you can edit these files with a text editor of your choice.

##### [](https://livebook.manning.com/book/kafka-in-action/appendix-a)Listing A.4 Configure server 0

```bash
$ vi config/server0.properties           #1
 
broker.id=0
listeners=PLAINTEXT://localhost:9092
log.dirs= /tmp/kafkainaction/kafka-logs-0
 
$ vi config/server1.properties           #2
 
broker.id=1
listeners=PLAINTEXT://localhost:9093
log.dirs= /tmp/kafkainaction/kafka-logs-1
 
$ vi config/server2.properties           #3
broker.id=2
listeners=PLAINTEXT://localhost:9094
log.dirs= /tmp/kafkainaction/kafka-logs-2
```

##### NOTE

[](https://livebook.manning.com/book/kafka-in-action/appendix-a/) Each Kafka broker runs on its port and uses a separate log directory. It is also critical that each configuration file has a unique ID for each broker because each broker uses its own ID to register itself as a member of the cluster. You will usually see your broker IDs start at 0, following a zero-based array-indexing scheme.

[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)After this, you can start each broker using the built-in scripts that are part of the initial installation (along with the configuration files that you updated in listing A.4). If you want to observe the Kafka broker output in the terminal, we recommend starting each process in a separate terminal tab or window and leaving them running. The following listing starts Kafka in a console window [2].

##### [](https://livebook.manning.com/book/kafka-in-action/appendix-a)Listing A.5 Starting Kafka in a console window

```bash
$ cd ~/kafka_2.13-2.7.1                                  #1
$ bin/kafka-server-start.sh config/server0.properties
$ bin/kafka-server-start.sh config/server1.properties
$ bin/kafka-server-start.sh config/server2.properties
```

##### TIP

[](https://livebook.manning.com/book/kafka-in-action/appendix-a/) If you close a terminal or your process hangs, do not forget about running the `jps` command [4]. That command will help you find the Java processes you might need to kill.

[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)Listing A.6 shows an example from one author’s machine where you can get the brokers’ PIDs and ZooKeeper’s JVM process [](https://livebook.manning.com/book/kafka-in-action/appendix-a/)[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)label (`QuorumPeerMain`) in the output from the three brokers and the ZooKeeper instance. The process ID numbers for each instance are on the left and will likely be different each time you run the start scripts.

##### [](https://livebook.manning.com/book/kafka-in-action/appendix-a)Listing A.6 `jps` output for ZooKeeper and three brokers

```
Kafka              #1
Kafka              #1
Kafka              #1
QuorumPeerMain     #2
```

[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)Now that you know how to configure a local installation manually, let’s look at using the Confluent Platform. Confluent Inc. ([https://www.confluent.io/](https://www.confluent.io/)) offers the Confluent Platform, a platform based on Apache Kafka. [](https://livebook.manning.com/book/kafka-in-action/appendix-a/)[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)

## [](https://livebook.manning.com/book/kafka-in-action/appendix-a/)A.4 Confluent Platform

[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)The Confluent Platform (find more at [https://www.confluent.io/](https://www.confluent.io/)) is an enterprise-ready packaging option that complements Apache Kafka with essential development capabilities. It includes packages for Docker, Kubernetes, Ansible, and various others. Confluent actively develops and supports Kafka clients for C++, C#/.NET, Python, and Go. It also includes the Schema Registry, which we talk about in chapters 3 and 11. Further, the Confluent Platform Community Edition includes ksqlDB. You learn about stream processing with ksqlDB in chapter 12.

[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)Confluent also provides a fully managed, cloud-native Kafka service, which might come in handy for later projects. A managed service provides Apache Kafka experience without requiring knowledge on how to run it. This is a characteristic that keeps developers focused on what matters, which is coding. The Confluent version 6.1.1 download includes Apache Kafka version 2.7.1, which is used throughout this book. You can follow easy installation steps from official Confluent documentation at [http://mng.bz/g1oV](http://mng.bz/g1oV).

### [](https://livebook.manning.com/book/kafka-in-action/appendix-a/)A.4.1 Confluent command line interface (CLI)

[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)Confluent, Inc. also has command line tools to quickly start and manage its Confluent Platform from the command line. A README.md on [https://github.com/confluentinc/confluent-cli](https://github.com/confluentinc/confluent-cli) contains more details on the script usage and can be installed with instructions from [http://mng.bz/RqNR](http://mng.bz/RqNR). The CLI is helpful in that it starts multiple parts of your product as needed. [](https://livebook.manning.com/book/kafka-in-action/appendix-a/)[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)

### [](https://livebook.manning.com/book/kafka-in-action/appendix-a/)A.4.2 Docker

[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)Apache Kafka doesn’t provide official Docker images at this time, but Confluent does. Those images are tested, supported, and used by many developers in production. In the repository of examples for this book, you’ll find a docker-compose.yaml file with preconfigured Kafka, ZooKeeper, and other components. To get all the components up and running, issue the command `docker-compose` `up` `-d` in the directory with the YAML file as the following listing shows.

##### NOTE

[](https://livebook.manning.com/book/kafka-in-action/appendix-a/) If you are unfamiliar with Docker or don’t have it installed, check out the official documentation at [https://www.docker.com/get-started](https://www.docker.com/get-started). You’ll find instructions on installation at that site as well.

##### [](https://livebook.manning.com/book/kafka-in-action/appendix-a)Listing A.7 filename.sh for a Docker image

```bash
$ git clone \                                      #1
  https://github.com/Kafka-In-Action-Book/Kafka-In-Action-Source-Code.git
$ cd ./Kafka-In-Action-Source-Code
$ docker-compose up -d                             #2
 
Creating network "kafka-in-action-code_default" with the default driver
Creating Zookeeper... done                         #3
Creating broker2   ... done
Creating broker1   ... done
Creating broker3   ... done
Creating schema-registry ... done
Creating ksqldb-server   ... done
Creating ksqldb-cli      ... done
 
$ docker ps --format "{{.Names}}: {{.State}}"      #4
 
ksqldb-cli: running
ksqldb-server: running
schema-registry: running
broker1: running
broker2: running
broker3: running
zookeeper: running
```

## [](https://livebook.manning.com/book/kafka-in-action/appendix-a/)A.5 How to work with the book examples

[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)You can use any IDE to open and run companion code for this book. Here are a few suggestions for you:

-  [](https://livebook.manning.com/book/kafka-in-action/appendix-a/)IntelliJ IDEA Community Edition ([https://www.jetbrains.com/idea/download/](https://www.jetbrains.com/idea/download/))
-  [](https://livebook.manning.com/book/kafka-in-action/appendix-a/)Apache Netbeans ([https://netbeans.org](https://netbeans.org/))
-  [](https://livebook.manning.com/book/kafka-in-action/appendix-a/)VS Code for Java ([https://code.visualstudio.com/docs/languages/java](https://code.visualstudio.com/docs/languages/java))
-  [](https://livebook.manning.com/book/kafka-in-action/appendix-a/)Eclipse STS ([https://spring.io/tools](https://spring.io/tools))

### [](https://livebook.manning.com/book/kafka-in-action/appendix-a/)A.5.1 Building from the command line

[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)If you want to build from the command line, a few more steps are needed. The Java 11 examples in this book are built with Maven 3.6.3. You should be able to create the JAR for each chapter when running from the root of the chapter directory in the folder that contains the pom.xml file and issuing either `./mvnw verify` or `./mvnw --projects KafkaInAction_Chapter2 verify` from the root project level.

[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)We use the Maven Wrapper tool ([http://mng.bz/20yo](http://mng.bz/20yo)), so if you don’t have Maven installed, either of the previous commands will download and run Maven for you. To run a specific class, you will need to supply a Java class that contains a `main` method as an argument after the path to your JAR. The following listing demonstrates how to run a generic Java class from chapter 2.

##### NOTE

[](https://livebook.manning.com/book/kafka-in-action/appendix-a/) You must use a JAR that has been built with all the dependencies to run the command successfully. [](https://livebook.manning.com/book/kafka-in-action/appendix-a/)[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)

##### [](https://livebook.manning.com/book/kafka-in-action/appendix-a)Listing A.8 Running the chapter 2 producer from the command line

```
java -cp target/chapter2-jar-with-dependencies.jar \
 replace.with.full.package.name.HelloWorldProducer
```

## [](https://livebook.manning.com/book/kafka-in-action/appendix-a/)A.6 Troubleshooting

[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)[](https://livebook.manning.com/book/kafka-in-action/appendix-a/)All of the source code for this book is at [https://github.com/Kafka-In-Action-Book/Kafka-In-Action-Source-Code](https://github.com/Kafka-In-Action-Book/Kafka-In-Action-Source-Code). If you have problems running this book’s examples, here are some general tips for troubleshooting:

-  [](https://livebook.manning.com/book/kafka-in-action/appendix-a/)Make sure you have a cluster started *before* running the code and command line examples in this book.
-  [](https://livebook.manning.com/book/kafka-in-action/appendix-a/)If you do not shut down your cluster correctly, you might have an old process holding on to a port that you want to use the next time you attempt to start up. You can use tools like `jps` or `lsof` to help identify which processes are running and which might need to be killed.
-  [](https://livebook.manning.com/book/kafka-in-action/appendix-a/)You should start inside your installation directory when you run commands, unless otherwise noted. If you are more comfortable with the command line, you can complete your setups, such as adding environment variables and aliases.
-  [](https://livebook.manning.com/book/kafka-in-action/appendix-a/)If you are having trouble with commands not being found, check the setup for your installation directory. Do you have the files marked as executable? Does a command like `chmod -R 755` help? Is the installation bin folder part of your `PATH` variable? If nothing else works, using the absolute path to the command should.
-  [](https://livebook.manning.com/book/kafka-in-action/appendix-a/)Check the source code for each chapter for a Commands.md file. This is a file that includes most commands used throughout a specific chapter. Look for the README.md files for more notes as well. [](https://livebook.manning.com/book/kafka-in-action/appendix-a/)

## [](https://livebook.manning.com/book/kafka-in-action/appendix-a/)References

1.  [](https://livebook.manning.com/book/kafka-in-action/appendix-a/)J. Galasyn. “How to Run Confluent on Windows in Minutes.” Confluent blog (March 26, 2021). [https://www.confluent.io/blog/set-up-and-run-kafka-on-windows-and-wsl-2/](https://www.confluent.io/blog/set-up-and-run-kafka-on-windows-and-wsl-2/) (accessed June 11, 2021).
1.  [](https://livebook.manning.com/book/kafka-in-action/appendix-a/)M. G. Noll. “Running a Multi-Broker Apache Kafka 0.8 Cluster on a Single Node.” (March 13, 2013). [https://www.michael-noll.com/blog/2013/03/13/running-a-multi-broker-apache-kafka-cluster-on-a-single-node/](https://www.michael-noll.com/blog/2013/03/13/running-a-multi-broker-apache-kafka-cluster-on-a-single-node/) (accessed July 20, 2021).
1.  [](https://livebook.manning.com/book/kafka-in-action/appendix-a/)“Apache Kafka Quickstart.” Apache Software Foundation (n.d.). [https://kafka.apache.org/quickstart](https://kafka.apache.org/quickstart) (accessed August 22, 2021).
1.  [](https://livebook.manning.com/book/kafka-in-action/appendix-a/)README.md. Confluent Inc. GitHub (n.d.). [https://github.com/confluentinc/customer-utilities](https://github.com/confluentinc/customer-utilities) (accessed August 21, 2021).
