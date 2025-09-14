# Chapter 10. Database integrations

### This chapter covers

- Publishing AMQP messages from PostgreSQL
- Making RabbitMQ listen to PostgreSQL notifications
- Using the InfluxDB storage exchange to store messages

Using RabbitMQ to decouple write operations against OLTP databases is a common way to achieve great data warehousing and event-stream processing techniques. When you publish messages with serialized data that will be written to the database, a simple consumer application can act as the bridge between events and your database. But it’s possible to skip the consumer step altogether and use a RabbitMQ plugin, such as the InfluxDB storage exchange, and automatically store messages in your database, directly from RabbitMQ.

The integration of RabbitMQ with an external database doesn’t stop there. Another powerful pattern is for your database to directly publish messages to RabbitMQ. This can be achieved by using extensions or plugins in the database, or by having a RabbitMQ plugin that acts as a database client, publishing messages whenever database events occur.

##### Note

Both of these patterns of database integration can simplify operational complexity, reducing the need for external consumer applications to perform the same type of work. But this simplification comes at a price. With your database and RabbitMQ more tightly coupled, failure scenarios can become more complex. For example, what happens if your database server becomes slow or unresponsive when RabbitMQ is trying to insert records into it? It’s important to answer questions like this by testing your integrations for failure scenarios and determining proper troubleshooting and recovery steps prior to production use.

This chapter explores both these patterns of database integration with RabbitMQ. First you’ll learn how the PostgreSQL pg_amqp extension can be employed to publish messages using stored procedures. Then you’ll learn how you can achieve the same type of behavior using PostgreSQL’s `LISTEN`/`NOTIFY` functionality with the PostgreSQL LISTEN exchange. We’ll then move from the relational world to the NoSQL world, and you’ll see how the InfluxDB storage exchange can be leveraged to store messages as time-series data as they’re published into RabbitMQ.

### 10.1. The pg_amqp PostgreSQL extension

The idea of publishing messages directly from PostgreSQL when triggers are executed is neither new nor novel. It was as early as 2003 that the Slony replication system ([http://slony.info](http://slony.info/)) used PostgreSQL’s trigger functions to send event messages, implementing master-slave replication. In 2008, to create a loosely coupled replication system offering more flexibility than the existing replication systems, I created Golconde. Golconde ([https://code.google.com/p/golconde](https://code.google.com/p/golconde)) leveraged POST COMMIT triggers and PL/Python to send transactional data to other PostgreSQL servers via the STOMP messaging protocol. The latest versions of PostgreSQL use event messaging to stream transactional data to hot-standby PostgreSQL instances that act as read-only slaves with the ability to failover if a master becomes unresponsive.

Given this solid history of event-based replication for PostgreSQL, it seems only natural that someone would add flexible messaging capabilities to its ecosystem. In 2009, Theo Schlossnagle of OmniTI released pg_amqp, a PostgreSQL extension that exposes AMQP publishing via PostgreSQL functions. Although pg_amqp only exposes a subset of the AMQP 0-8 specification, it performs solidly when publishing messages from PostgreSQL’s trigger functions. The functionality exposed by pg_amqp is accessible just like any other PostgreSQL function and can be invoked in SQL statements and stored procedures alike. Pg_amqp exposes a simple AMQP with two methods for interacting with RabbitMQ: `amqp.publish` and `amqp.disconnect`. The `amqp.publish` method creates an AMQP message and delivers it using the `Basic.Publish` RPC method, just like any other AMQP publisher ([figure 10.1](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-10/ch10fig01)). Connections are automatically established and destroyed, but if you want to directly terminate a connection after publishing a message, you can invoke the `amqp.disconnect` function.

![Figure 10.1. pg_amqp.publish uses Basic.Publish to send a message to RabbitMQ.](https://drek4537l1klr.cloudfront.net/roy/Figures/10fig01_alt.jpg)

When you use pg_amqp, you’re invoking synchronous communication with RabbitMQ, and care should be taken to ensure that your use doesn’t impact your overall query velocity. As with any tightly coupled integration, benchmarking should be performed and failure scenarios should be tested prior to putting a system into production. For example, if you wrap your use of `amqp.publish` in a transaction, what happens if pg_amqp can’t connect to the RabbitMQ broker? Will your database transactions complete if there’s a publishing failure?

To find out, you must first install the pg_amqp extension.

#### 10.1.1. Installing the pg_amqp extension

There are two ways to install the pg_amqp extension: You can install it by downloading and compiling the source manually or by using the PostgreSQL Extension Network (PGXN) client. PGXN ([http://pgxn.org](http://pgxn.org/)) is a package repository for PostgreSQL extensions. PGXN-based installation is dramatically easier, but it doesn’t work with PostgreSQL 9.3 installations. Unless you’re using PostgreSQL 9.3 or later, I recommend that you start with the PGXN install and fall back to manual installation if that fails.

##### Note

Before you attempt to install pg_amqp, you should first ensure that you have fully installed PostgreSQL version 9.1 or greater, including the development files, because the extension is compiled as part of the installation process. In addition, you’ll need the tool chain for compiling PostgreSQL from source. If you need help installing PostgreSQL or the developer tool chain required for compiling PostgreSQL, you can find installation guides on the official Wiki at [https://wiki.postgresql.org/wiki/Detailed_installation_guides](https://wiki.postgresql.org/wiki/Detailed_installation_guides).

##### Installation via pgxn

To install the pg_amqp extension via PGXN, you first need to ensure that the PGXN client is installed on your system. It’s written in Python and can be installed with `easy_install`:

```
easy_install pgxnclient
```

With the `pgxnclient` application installed, you can now attempt to automatically install the extension. As a user with permission to write to PostgreSQL’s `lib` directory, run the following command:

```
pgxnclient install pg_amqp
```

If everything worked as expected, the command won’t have returned an error. But don’t worry if you encountered an error. Although the manual installation has more steps, it’s nearly as easy.

##### Manual Installation

The source code for pg_amqp is available on GitHub at [https://github.com/omniti-labs/pg_amqp](https://github.com/omniti-labs/pg_amqp). If you’re not familiar with Git, you can download the source code from [https://github.com/omniti-labs/pg_amqp/archive/v0.3.0.zip](https://github.com/omniti-labs/pg_amqp/archive/v0.3.0.zip) and extract it to a directory for compilation. The following code listing, written in BASH script, fixes the installation for PostgreSQL 9.3 or later systems and should be run in the top-level directory of the extracted source.

##### Listing 10.1. Compiling and installing pg_amqp

```
1234#!/bin/bash
LIBDIR=`pg_config --libdir`
INSTALLSH="$LIBDIR/pgxs/config/install-sh"
make && make INSTALL=$INSTALLSH install
```

Once you’ve successfully installed the pg_amqp extension, you’ll need to load it into a PostgreSQL database. For ease of illustration, the following example uses the default `postgres` superuser and `postgres` database; this is not required for use, though the user must be a superuser.

To load the extension, connect to the PostgreSQL database using `psql`:

```bash
$ psql -U postgres postgres
```

When you’ve connected, you should see output similar to the following:

```
1234psql (9.3.5)
Type "help" for help.

postgres=>
```

Now you can load the extension using the `CREATE EXTENSION` syntax:

```
postgres=> CREATE EXTENSION amqp;
```

If the extension was loaded successfully, you’ll receive a confirmation similar to the following:

```
CREATE EXTENSION
```

With the extension loaded, you can move on to configuring the extension and then publishing messages.

#### 10.1.2. Configuring the pg_amqp extension

The extension is configured by populating the `amqp.broker` table that was automatically created when you ran the `CREATE EXTENSION` query in the previous section. As shown in [table 10.1](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-10/ch10table01), `amqp.broker` contains the normal AMQP connection settings along with a `broker_id` field that’s used when invoking both the `amqp.publish` and `amqp.disconnect` functions.

##### Table 10.1. The `amqp.broker` table definition

| Column | Type | Modifiers |
| --- | --- | --- |
| broker_id | Integer | not null default nextval('broker_broker_id_seq') |
| host | Text | not null |
| port | Integer | not null default 5672 |
| vhost | Text |  |
| username | Text |  |
| password | Text |  |

If you’re running PostgreSQL locally and RabbitMQ in the Vagrant VM used in earlier chapters, you should be able to connect on `localhost`. The following SQL statement will configure pg_amqp by inserting a row into the table that connects to RabbitMQ on `localhost`, port `5672`, using the `/` virtual host and the `guest/guest` username and password combination. If the connection settings won’t work due to differences in your testing environment, adjust the SQL accordingly.

```
123INSERT INTO amqp.broker (host, port, vhost, username, password) 
  VALUES ('localhost', 5672, '/', 'guest', 'guest') 
  RETURNING broker_id;
```

When you execute the command, you’ll get the `broker_id` value back, confirming successful insertion into the table:

```
123456broker_id 
-----------
         1
(1 row)

INSERT 0 1
```

Remember the `broker_id` value because you’ll be using that to publish messages into RabbitMQ.

#### 10.1.3. Publishing a message via pg_amqp

With pg_amqp installed and configured, it’s nearly time to publish your first message. Before you do, you should set up a queue in the RabbitMQ management UI to receive the message. Open your web browser to http://localhost:15672/#/queues and create a queue named `pg_amqp-test`, as in [figure 10.2](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-10/ch10fig02).

![Figure 10.2. Creating the pg_amqp-test queue](https://drek4537l1klr.cloudfront.net/roy/Figures/10fig02_alt.jpg)

Once you’ve created the queue, you can test publishing to the queue from PostgreSQL via the default direct exchange using the queue name (`pg_amqp-test`) as the routing key. Using `psql` connected to the `postgres` database, issue the following query that passes the broker ID, exchange, routing key, and message:

```
12SELECT amqp.publish(1, '', 'pg_amqp-test', 
                    'Test message from PostgreSQL');
```

Once it’s submitted, you should receive confirmation that the query executed successfully:

```
1234publish 
---------
 t
(1 row)
```

Although PostgreSQL has said the message was published, a better validation would be to use the management UI to retrieve the published message. On the queue detail page at http://localhost:15672/#/queues/%2F/pg_amqp-test you can use the Get Messages section to retrieve and inspect the message. As shown in [figure 10.3](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-10/ch10fig03), once you click the Get Message(s) button, you should see the message that was published via the PostgreSQL `amqp.publish` function.

![Figure 10.3. Using the management UI to confirm the message was published](https://drek4537l1klr.cloudfront.net/roy/Figures/10fig03.jpg)

As you can see, publishing messages via pg_amqp is a fairly trivial exercise once you have it set up and configured. It’s worth noting that you can’t set the AMQP message properties as of version 0.3. Additionally, message publishing is wrapped in an AMQP transaction. Should you invoke the `amqp.publish` function in a PostgreSQL transaction and then roll back the transaction, the RabbitMQ transaction will be rolled back as well. In most cases, publish will be wrapped within a stored procedure, either along with other actions inside the stored procedure, or as a trigger function that’s executed on the `INSERT`, `UPDATE`, or `DELETE` of rows in a table.

##### Note

The management UI warns you that the Get Messages(s) operation is a destructive action. What it means by this is that the message is actually removed from the queue to display it, and if the Requeue option is set to Yes, it will republish the message back into the queue, so it will now be at the end of the queue instead of at the front.

##### Dealing with failure

You may have noticed that when you called the `amqp.publish` function, it returned a Boolean value. In the case of success, it returned a `t` or true, but what happens if it can’t connect to RabbitMQ? Issuing the same statement in a new transaction with a new connection attempt will return `f` or false and log a warning:

```
123456789postgres=# SELECT amqp.publish(1, '', 'pg_amqp-test', 
                    'Test message from PostgreSQL');

WARNING: amqp[localhost:5672] login socket/connect failed: Connection refused

 publish 
---------
 f
(1 row)
```

In this scenario it’s pretty easy to test for the result of the `amqp.publish` call, and if it’s false, you weren’t able to publish. But what if something happens inside a long-running transaction and RabbitMQ disconnects? In this scenario, the call will invoke true but log a warning that the AMQP transaction couldn’t be committed:

```
1234567postgres=# SELECT amqp.publish(1, '', 'pg_amqp-test', 
                    'Test message from PostgreSQL');
WARNING:  amqp could not commit tx mode on broker 1
 publish 
---------
 t
(1 row)
```

Unfortunately, as of version 0.3.0 of pg_amqp, you can’t catch this error, and if you’re not watching your PostgreSQL logs, you could be losing messages without knowing it. Although this is problematic behavior, it’s better than losing your database transaction. Like with all operational systems, monitoring is key. If you use a system like Splunk, you can create a job that periodically searches for AMQP errors in PostgreSQL’s logs. Alternatively, you could write your own app or plugin for systems like Nagios that scans the logs looking for such warnings.

### 10.2. Listening to PostgreSQL notifications

Although pg_amqp provides a convenient and fast way of publishing messages directly from PostgreSQL, it creates a tightly coupled integration between the server instances. Should your RabbitMQ cluster become unavailable for any reason, it could have an adverse impact on your PostgreSQL server. To avoid such tight coupling while retaining the direct integration, I created the PostgreSQL LISTEN exchange.

The PostgreSQL LISTEN exchange acts as a PostgreSQL client, listening for notifications issued in PostgreSQL by the `NOTIFY` SQL statement. PostgreSQL notifications are sent to a channel, a text value that clients subscribe to. This value is used in the PostgreSQL LISTEN exchange as the routing key for the published message. When notifications are sent on a channel that the LISTEN exchange has registered on, the notification will be turned into a message that’s then published using direct-exchange-like behavior ([figure 10.4](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-10/ch10fig04)).

![Figure 10.4. The LISTEN exchange acts as a PostgreSQL client, publishing notifications as messages.](https://drek4537l1klr.cloudfront.net/roy/Figures/10fig04_alt.jpg)

Of course, with any technology decision there are trade-offs. With pg_amqp, should PostgreSQL be unable to connect to RabbitMQ, the calls to `amqp.publish` will fail. With the LISTEN exchange, should the PostgreSQL connection fail, it can’t register for notifications and, in turn, it won’t publish any messages. You can watch for such a scenario by monitoring the throughput rate of the exchange using the RabbitMQ management API.

#### 10.2.1. Installing the PostgreSQL LISTEN exchange

The PostgreSQL LISTEN exchange can be downloaded from its GitHub project page at [https://github.com/AWeber/pgsql-listen-exchange](https://github.com/AWeber/pgsql-listen-exchange). In the README displayed on the project page are downloads of precompiled binary plugins for specific RabbitMQ versions. When you download and install the plugin, make sure you’re getting the latest version for your version of RabbitMQ.

The download is a zip file with two RabbitMQ plugins: the exchange and a PostgreSQL driver. The following code listing will download and install the plugin on an OS X system running RabbitMQ 3.3.5 installed via Homebrew. For other systems, you’ll need to alter the `RABBITMQ_DIR` assignment, specifying the correct path to the RabbitMQ base directory.

##### Listing 10.2. OS X installation script for the LISTEN exchange

```
12345678910#!/bin/bash
RABBITMQ_DIR=/usr/local/Cellar/rabbitmq/3.3.5/                         1
PLUGIN_DIR=$RABBITMQ_DIR/plugins/                                      2
cd /tmp                                                                3
curl -L -o pgsql-listen-exchange.zip http://bit.ly/1ndl8eK             4
unzip pgsql-listen-exchange.zip                                        5
rm pgsql-listen-exchange. zip                                          6
mv epgsql-1.4.1-rmq3.3.x-0.2.0-git3318bd5.ez $PLUGIN_DIR               7
mv pgsql_listen_exchange-3.3.x-0.2.0.ez $PLUGIN_DIR                    8
$RABBITMQ_DIR/sbin/rabbitmq-plugins enable pgsql_listen_exchange       9
```

- ***1* Sets the base directory for the RabbitMQ installation**
- ***2* Sets the plugin directory path**
- ***3* Changes to a temporary directory**
- ***4* Downloads the exchange from GitHub**
- ***5* Extracts the zip file**
- ***6* Removes the downloaded zip file**
- ***7* Moves the PostgreSQL driver to the plugin directory**
- ***8* Moves the LISTEN exchange plugin to the plugin directory**
- ***9* Enables the LISTEN exchange plugin**

##### Note

In Ubuntu and RedHat/CentOS systems, RabbitMQ is typically installed to a version-specific subdirectory under /usr/lib/rabbitmq. In Windows, RabbitMQ is typically installed to a version-specific directory under C:\Program Files\RabbitMQ. Precompiled binary plugins are platform independent and can be run on any platform that runs RabbitMQ.

To verify that the plugin has been installed correctly, navigate to the management UI’s Exchanges tab at http://localhost:15672/#/exchanges. In the Add a New Exchange section, you should see the `x-pgsql-listen` value in the Type drop-down list ([figure 10.5](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-10/ch10fig05)).

![Figure 10.5. Validating that the x-pgsql-listen option exists in the Type drop-down list](https://drek4537l1klr.cloudfront.net/roy/Figures/10fig05_alt.jpg)

After validating that the plugin was installed correctly, you can now move on to configuring the exchange. If you don’t see the option in the drop-down list, it’s possible that either the plugins weren’t copied to the appropriate directory or that you’re running an older version of Erlang than the plugins were compiled with. It’s recommended that you use Erlang R16 or later.

There are multiple ways to configure the plugin: by directly configuring the exchange with connection arguments passed in during exchange declaration, by configuring the exchange in the rabbitmq.config file, or via a policy that’s applied to the exchange. Policies provide the most flexible way of configuring the exchange and should be used until you have experience with the plugin and are confident about how it behaves.

#### 10.2.2. Policy-based configuration

To get started, navigate to the Admin tab of the management UI. From there, click Policies on the right side of the page ([figure 10.6](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-10/ch10fig06)).

![Figure 10.6. The management UI Policies page](https://drek4537l1klr.cloudfront.net/roy/Figures/10fig06_alt.jpg)

To create the policy required for connecting to PostgreSQL, specify a name for the policy, a regular expression pattern for matching the exchange name, and the PostgreSQL host, port, database name, user name, and optionally password. Additionally, you can narrow down the policy by specifying that it only applies to exchanges. [Figure 10.7](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-10/ch10fig07) shows a policy that will connect to PostgreSQL on `localhost`, port `5432`, using the `postgres` database and username.

![Figure 10.7. Declaring a policy for the notification exchange](https://drek4537l1klr.cloudfront.net/roy/Figures/10fig07_alt.jpg)

Once you click Add Policy, you’ll see the policy listed on the same page, as in [figure 10.8](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-10/ch10fig08).

![Figure 10.8. The policy added to the All Policies section](https://drek4537l1klr.cloudfront.net/roy/Figures/10fig08_alt.jpg)

When you add the policy, the connection information that you provide will be checked for type correctness but not validity. You won’t know if the connection information is valid until the exchange is created.

#### 10.2.3. Creating the exchange

With the policy created, navigate to the Exchanges tab of the management UI at http://localhost:15672/#/exchanges. Add a new exchange using the Add a New Exchange form at the bottom of the page. Name the exchange `notification` so that the policy will match, and set the exchange type to `x-pgsql-listen` ([figure 10.9](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-10/ch10fig09)).

![Figure 10.9. Adding the notification PostgreSQL LISTEN exchange](https://drek4537l1klr.cloudfront.net/roy/Figures/10fig09_alt.jpg)

Once you add the exchange, it will connect to PostgreSQL, but it won’t start listening for notifications. To have it start listening to exchanges, you must bind to the exchange with a routing key that matches the PostgreSQL notification channel string.

#### 10.2.4. Creating and binding a test queue

The last setup step for testing the LISTEN exchange is creating a test queue that your notifications will be sent to. If you navigate to the Queues tab of the management UI (http://localhost:15672/#/queues), you can create a queue with the Add a New Queue section. For the purposes of this test, call the queue `notification-test`. You don’t need to specify any custom attributes or change any of the default properties in the form when adding the queue.

Once you’ve added the queue, navigate to the queue’s page in the management UI at http://localhost:15672/#/queues/%2F/notification-test. In the Bindings section of the page, you can create a new binding to the `notification` exchange with a routing key of `example` ([figure 10.10](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-10/ch10fig10)).

![Figure 10.10. Binding the test queue to the notification exchange](https://drek4537l1klr.cloudfront.net/roy/Figures/10fig10_alt.jpg)

Once added, the exchange will connect to PostgreSQL and execute a `LISTEN` statement, registering for all notifications sent on the `example` channel. You’re now ready to send a test notification.

#### 10.2.5. Publishing via NOTIFY

To validate that the exchange setup is correct, you can now send a notification in PostgreSQL using the `NOTIFY` SQL statement. To do so, use `psql`, connecting as `postgres` to the `postgres` database:

```bash
$ psql -U postgres postgres
```

When you’ve connected, you can send the notification:

```
1234psql (9.3.5)
Type "help" for help.
postgres=# NOTIFY example, 'This is a test from PostgreSQL';
NOTIFY
```

With the notification sent, switch back to the RabbitMQ management UI to get the message from the `notification-test` queue in the Get Messages section ([figure 10.11](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-10/ch10fig11)).

![Figure 10.11. Getting the message from the notification-test queue](https://drek4537l1klr.cloudfront.net/roy/Figures/10fig11.jpg)

As you can see, the LISTEN exchange adds metadata about the message that’s not populated when using pg_amqp. The message properties specify the `app_id`, noting that the message originated from the pgsql-listen-exchange plugin. The `timestamp` is also shown, taken from the current local time of the RabbitMQ server. Additionally, `headers` are set that specify the PostgreSQL notification channel, database, server, and name of the source exchange.

Although this example was a plain text string, functions sending notifications can serialize data in a variety of formats, making notifications a versatile part of your application. Perhaps you want to use them for debugging complex stored procedures, making it easy to trace the state of data as it travels through your database. Or maybe you want to use them to update disparate systems in the cloud, using the exchange in combination with the RabbitMQ federation plugin. In either circumstance, the LISTEN exchange adds loosely coupled integration with PostgreSQL with very little overhead for either system.

### 10.3. Storing messages in InfluxDB

InfluxDB ([http://influxdb.com](http://influxdb.com/)) is an open source, distributed, time-series database written in Go. It’s very easy to set up for both Linux and OS X systems. It’s a compelling system for storing time-series data for analytical purposes, as it provides multiple easy-to-use protocols for populating data and a built-in web-based query interface for querying the data it stores. It’s quickly becoming an alternative to systems like Graphite because it provides more scalable storage that’s accessible via a cohesive, scale-out cluster.

Messages that are routed through the InfluxDB storage exchange are examined to determine whether they should be stored in InfluxDB. If the content type of a message is specified and it’s set to `application/json`, the message will be transformed into the proper format and stored in InfluxDB using the routing key as the InfluxDB event name. Additionally, if the `timestamp` is specified, it will automatically be mapped to the InfluxDB event time column.

#### 10.3.1. InfluxDB installation and setup

To get started with RabbitMQ and InfluxDB, you must first ensure that you have InfluxDB installed. There are detailed installation instructions on the project documentation page at [http://influxdb.com/docs/](http://influxdb.com/docs/). Pick the latest version from the documentation index, and then follow the installation instructions and the getting started instructions to check that the system is installed and set up correctly.

Alternatively, for learning about InfluxDB, the project provides a public playground server at [http://play.influxdb.org](http://play.influxdb.org/). If you’re using Windows or you don’t want to install a server locally on your computer, you can use the public playground with the InfluxDB storage exchange to test the integration. The examples in this section of the chapter will assume a local installation, but you should only need to change the connection and authentication information to use the public playground server.

If you’re setting up a local instance of InfluxDB, you’ll need to create both a database and a user for RabbitMQ. To do so, open your web browser to http://localhost:8083 and log in to the administration interface using the username `root` and the password `root` ([figure 10.12](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-10/ch10fig12)).

![Figure 10.12. Logging into the InfluxDB administration interface](https://drek4537l1klr.cloudfront.net/roy/Figures/10fig12_alt.jpg)

Once you log in for the first time, you’ll be prompted to create a database. For validating the InfluxDB storage exchange, create an exchange called `rabbitmq-test` ([figure 10.13](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-10/ch10fig13)).

![Figure 10.13. Creating the rabbitmq-test database](https://drek4537l1klr.cloudfront.net/roy/Figures/10fig13_alt.jpg)

Once you’ve created the database, it will appear in a list at the top of the web page. Click on `rabbitmq-test` in that list and you’ll be taken to a page where you can add a user for RabbitMQ that the plugin will use to authenticate to RabbitMQ ([figure 10.14](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-10/ch10fig14)). On that form, enter the username `rabbitmq` and the password `test`, and then click the Create button.

![Figure 10.14. Creating the rabbitmq user for the rabbitmq-test database](https://drek4537l1klr.cloudfront.net/roy/Figures/10fig14_alt.jpg)

Once you’ve created the user, it will show up in the Database Users table at the top of the page. Then you’re ready to install and configure the InfluxDB storage exchange.

#### 10.3.2. Installing the InfluxDB storage exchange

Installing and configuring the InfluxDB storage exchange is very similar to the process for the PostgreSQL LISTEN Exchange. The plugin can be downloaded from its GitHub project page at [https://github.com/aweber/influxdb-storage-exchange](https://github.com/aweber/influxdb-storage-exchange). The README displayed on the project page lists download links for precompiled binary plugins for specific RabbitMQ versions. When you download and install the plugin, make sure you’re getting the latest version for your version of RabbitMQ.

The download is a zip file with two RabbitMQ plugins: the exchange and an HTTP client library. The following code listing will download and install the plugin on an OS X system running RabbitMQ 3.3.5 installed via Homebrew. For other systems, you’ll need to alter the `RABBITMQ_DIR` assignment, specifying the correct path to the RabbitMQ base directory.

##### Listing 10.3. OS X installation script for the LISTEN exchange

```
12345678910#!/bin/bash
RABBITMQ_DIR=/usr/local/Cellar/rabbitmq/3.3.5/                         1
PLUGIN_DIR=$RABBITMQ_DIR/plugins/                                      2
cd /tmp                                                                3
curl -L -o influxdb-storage-exchange.zip http://bit.ly/1j7UvXf         4
unzip influxdb-storage-exchange.zip                                    5
rm influxdb-storage-exchange.zip                                       6
mv ibrowse-4.0.2-rmqv3.3.x-git7871e2e.ez $PLUGIN_DIR                   7
mv influxdb_storage_exchange-v3.3.x-0.1.1.ez $PLUGIN_DIR               8
$RABBITMQ_DIR/sbin/rabbitmq-plugins enable influxdb_storage_exchange   9
```

- ***1* Sets the base directory for the RabbitMQ installation**
- ***2* Sets the plugin directory path**
- ***3* Changes to a temporary directory**
- ***4* Downloads the exchange from GitHub**
- ***5* Extracts the zip file**
- ***6* Removes the downloaded zip file**
- ***7* Moves the HTTP driver to the plugin directory**
- ***8* Moves the exchange plugin to the plugin directory**
- ***9* Enables the InfluxDB storage exchange plugin**

##### Note

As a reminder, in Ubuntu and RedHat/CentOS systems, RabbitMQ is typically installed to a version-specific subdirectory under /usr/lib/rabbitmq. In Windows, RabbitMQ is typically installed to a version-specific directory under C:\Program Files\RabbitMQ. Precompiled binary plugins are platform independent and can be run on any platform that runs RabbitMQ.

To verify that the plugin has been installed correctly, navigate to the management UI Exchanges tab at http://localhost:15672/#/exchanges. In the Add a New Exchange section, you should see the `x-influxdb-storage` value in the Type drop-down list ([figure 10.15](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-10/ch10fig15)).

![Figure 10.15. Validating that the InfluxDB storage exchange is installed properly](https://drek4537l1klr.cloudfront.net/roy/Figures/10fig15_alt.jpg)

With the installation properly verified, you can now create an instance of the InfluxDB storage exchange.

#### 10.3.3. Creating a test exchange

Like the PostgreSQL LISTEN Exchange, the InfluxDB storage exchange can be configured by policy, by rabbitmq.config, or by passing custom arguments when declaring the exchange. For the various configuration options and variables used for each configuration method, check the README on GitHub at [https://github.com/aweber/influxdb-storage-exchange](https://github.com/aweber/influxdb-storage-exchange). To illustrate the difference between the policy-based configuration used with the PostgreSQL LISTEN exchange and argument-based configuration, the following example will use an argument-based configuration when creating the exchange.

First, navigate to the Exchanges tab of the RabbitMQ management UI at http://localhost:15672/#/exchanges and go to the Add a New Exchange section. Configuring the exchange with custom arguments is done with variables that have a prefix of `x-`, indicating that each of these arguments aren’t standard AMQP or RabbitMQ variables. You’ll need to configure the host, port, database name, user, and password for the InfluxDB connection. Each of these values is prefixed with `x-`, as illustrated in [figure 10.16](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-10/ch10fig16). Failure to prefix the variables with `x-` will cause the exchange to use the default values for each of the settings you provide.

![Figure 10.16. Adding a new InfluxDB exchange with argument-based configuration](https://drek4537l1klr.cloudfront.net/roy/Figures/10fig16_alt.jpg)

When you add the exchange, the parameters will be checked for type validity, but the connection information won’t be tested. Due to the immutable nature of AMQP exchanges, if you misconfigure the exchange, it will need to be deleted and re-added.

Messages published into the exchange will first be stored in InfluxDB and then routed to any queues or exchanges bound to the exchange using the topic exchange routing key behavior. Misconfigured exchanges won’t prevent messages from being routed through them, but they won’t be able to store the messages in InfluxDB.

With the exchange created, you can now test the exchange by publishing messages into it. If you’re using rabbitmq.config or policy-based configuration, you could leave the arguments empty and the values of either method would be applied to the exchange’s configuration.

#### 10.3.4. Testing the exchange

To test the proper integration of the exchange, navigate to the new exchange’s page in the RabbitMQ management UI at http://localhost:15672/#/exchanges/%2F/influx-test. In the Publish a Message section, specify a message that has a `content_type` of `application/json`, a valid `timestamp` value, and a well-formed JSON body ([figure 10.17](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-10/ch10fig17)).

![Figure 10.17. Publishing a JSON message to the InfluxDB storage exchange](https://drek4537l1klr.cloudfront.net/roy/Figures/10fig17_alt.jpg)

Because you didn’t bind a queue to the exchange, you’ll receive a warning that the message was published but not routed when you publish the message. That’s OK for this test because you only want to verify that the data point made it into InfluxDB.

To validate that the event was stored properly, open the administration interface in your web browser by navigating to http://localhost:8083 and logging in as `root` using the password `root`. As illustrated in [figure 10.18](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-10/ch10fig18), you’ll be presented with a list of databases. Click on the Explore Data link for the `rabbitmq-test` database.

![Figure 10.18. The InfluxDB administration interface showing a list of databases](https://drek4537l1klr.cloudfront.net/roy/Figures/10fig18_alt.jpg)

When you click on *Explore Data*, you’ll be taken to an interface where you can query the data. Entering the simple query `SELECT * FROM pageview` should return a single row, as illustrated in [figure 10.19](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-10/ch10fig19).

![Figure 10.19. Verifying that the row was inserted in the database](https://drek4537l1klr.cloudfront.net/roy/Figures/10fig19_alt.jpg)

If you don’t see your data as a result of the query, perhaps there was a typo in your message headers or the message. Ensure that the content type is specified and that it’s set to `application/json`. Additionally, ensure that the message you published is well-formed JSON. You can check your message body using [http://jsonlint.com](http://jsonlint.com/). Finally, validate that InfluxDB is running and that the configuration data provided when creating the exchange is accurate.

If everything worked as expected, the InfluxDB storage exchange demonstrates the flexibility and power that direct database integrations with RabbitMQ can create. If you use systems such as Sensu ([http://sensuapp.org](http://sensuapp.org/)) for monitoring your infrastructure, you now have a powerful way to transparently tap into your event stream and store it in a database for further analysis, or for providing the information in a dashboard using Grafana ([http://grafana.org](http://grafana.org/)).

### 10.4. Summary

Integrating databases with RabbitMQ reduces the operational overhead of running consumer or publisher applications outside of your database or RabbitMQ stack. Such simplification comes with a cost, however. Because RabbitMQ and your database are more tightly coupled, failure scenarios can become more complex.

In this chapter you learned how PostgreSQL can be used as a source of messages that are routed through RabbitMQ either by using the pg_amqp PostgreSQL extension or by using the PostgreSQL LISTEN exchange. Installing and using the InfluxDB storage exchange was detailed, demonstrating how messages published into RabbitMQ can be stored in a database by RabbitMQ itself.

The database integrations in this chapter are just the tip of the iceberg. There are other projects that directly integrate RabbitMQ with a database, such as the Riak exchange ([https://github.com/jbrisbin/riak-exchange](https://github.com/jbrisbin/riak-exchange)) and its counterpart, a project that implements Riak RabbitMQ commit hooks ([https://github.com/jbrisbin/riak-rabbitmq-commit-hooks](https://github.com/jbrisbin/riak-rabbitmq-commit-hooks)), publishing messages into RabbitMQ when write transactions occur in Riak. To see if there’s a plugin for your database of choice, check out the RabbitMQ Community Plugins page at [https://www.rabbitmq.com/community-plugins.html](https://www.rabbitmq.com/community-plugins.html) and the RabbitMQ Clients & Developer Tools page at [https://www.rabbitmq.com/devtools.html](https://www.rabbitmq.com/devtools.html).

Can’t find what you’re looking for? Perhaps you can contribute the next plugin providing database integration with RabbitMQ.
