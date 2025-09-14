# Chapter 3 Specific Notes

* Close all ZooKeeper and Kafka brokers you have open. 


### Download for Confluent Open Source
* Note that the book text uses a specific Confluent version and might or might not reflect the below instructions

* https://www.confluent.io/previous-versions
  Select the «Download Community Tarball» version 6.1.1 or above and unzip that archive.
* install Confluent CLI using https://docs.confluent.io/current/cli/installing.html as a reference if needed
* 
install JDBC connector with `confluent-hub` command: e. g. 

      confluent-hub install confluentinc/kafka-connect-jdbc:10.2.0 (command referenced from https://www.confluent.io/hub/confluentinc/kafka-connect-jdbc)

  and follow prompts

### Updates to related files

Refer to https://github.com/Kafka-In-Action-Book/Kafka-In-Action-Source-Code/blob/master/KafkaInAction_Chapter3/Commands.md in the section called "File Contents" for related file updates needed and other sections for more commands.

## Java example commands

 * Use JDK 11
 * Apache Kafka and Confluent Schema Registry should be up and running. Make sure you start the `confluent local services connect start` before you try and run the examples if they require it to be running.

```bash
> ./mvnw verify 
> java -cp target/chapter3-jar-with-dependencies.jar org.kafkainaction.consumer.<Change to class with a Main Method>

``` 

## Helpful Command References from the chapter
* https://docs.confluent.io/3.1.2/connect/quickstart.html
* https://docs.confluent.io/kafka-connect-jdbc/current/source-connector/index.html