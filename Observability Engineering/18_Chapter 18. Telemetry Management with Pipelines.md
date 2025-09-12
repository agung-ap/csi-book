# Chapter 18. Telemetry Management with Pipelines

This chapter is contributed by Suman Karumuri, senior staff software engineer at Slack, and Ryan Katkov, director of engineering at Slack

##### A Note from Charity, Liz, and George

In this part of the book, we’ve unpacked observability concepts that are most acutely felt at scale but that can be helpful at any scale for a variety of reasons. In the previous chapter, we looked at what happens when the typical trickle of observability data instead becomes a flood and how to reduce that volume with sampling. In this chapter, we’ll look at a different way to manage large volumes of telemetry data: with pipelines.

Beyond data volume, *telemetry pipelines* can help manage application complexity. In simpler systems, the telemetry data from an application can be directly sent to the appropriate data backend. In more-complex systems, you may need to route telemetry data to many backend systems in order to isolate workloads, meet security and compliance needs, satisfy different retention requirements, or for a variety of other reasons. When you add data volume on top of that, managing the many-to-many relationship between telemetry producers and consumers of that data can be extraordinarily complex. Telemetry pipelines help you abstract away that complexity.

This chapter, written by Suman Karumuri and Ryan Katkov, details Slack’s use of telemetry pipelines to manage its observability data. Similar to the other guest-contributed chapter in this book, [Chapter 14](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch14.html#observability_and_the_software_supply_c), Slack’s application infrastructure is a wonderful example of elegantly tackling issues of complexity and scale in ways that surface helpful concepts to engineers using observability at any scale. We’re delighted to be able to share these lessons with you in the context of this book.

The rest of this chapter is told from the perspective of Suman and Ryan.

In this chapter, we will go over how telemetry pipelines can benefit your organization’s observability capabilities, describe the basic structure and components of a telemetry pipeline, and show concrete examples of how Slack uses a telemetry pipeline, using mainly open source software components. Slack has been using this pattern in production for the past three years, scaling up to millions of events per second.

Establishing a telemetry management practice is key for organizations that want to focus on observability adoption and decrease the amount of work a developer needs to do to make their service sufficiently observable. A strong telemetry management practice lays the foundation for a consolidated instrumentation framework and creates a consistent developer experience, reducing complexity and churn, especially when it comes to introducing new telemetry from new software.

At Slack, we generally look for these characteristics when we envision an ideal telemetry system: we want the pipeline to be able to collect, route, and enrich data streams coming from applications and services. We are also opinionated about the components that operate as part of a stream, and we make available a consistent set of endpoints or libraries. Finally, we use a prescribed common event format that applications can leverage quickly to realize value.

As an organization grows, observability systems tend to evolve from a simple system in which applications and services produce events directly to the appropriate backend, to more-complex use cases. If you find yourself needing greater security, workload isolation, retention requirement enforcement, or a greater degree of control over the quality of your data, then telemetry management via pipelines can help you address those needs. At a high level, a pipeline consists of components between the application and the backend in order to process and route your observability data.

By the end of this chapter, you’ll understand how and when to design a telemetry pipeline as well as the fundamental building blocks necessary to manage your growing observability data needs.

# Attributes of Telemetry Pipelines

Building telemetry pipelines can help you in several ways. In this section, you will learn about the attributes commonly found in telemetry pipelines and how they can help you.

## Routing

At its simplest, the primary purpose of a telemetry pipeline is to *route* data from where it is generated to different backends, while centrally controlling the configuration of what telemetry goes where. Statically configuring these routes at the source to directly send the data to the data store is often not desirable because often you want to route the data to different backends without needing application changes, which are often burdensome in larger-scale systems.

For example, in a telemetry pipeline, you might like to route a trace data stream to a tracing backend, and a log data stream to a logging backend. In addition, you may also want to tee a portion of the same trace data stream to an Elasticsearch cluster so you can do real-time analytics on it. Having flexibility through routing and translation helps increase the value of the data stream because different tools may provide different insights on a data set.

## Security and Compliance

You may also want to route the telemetry data to different backends for *security* reasons. You may want only certain teams to access the telemetry data. Some applications may log data containing sensitive personally identifiable information (PII), and allowing broad access to this data may lead to compliance violations.

Your telemetry pipeline may need features to help enforce legal compliance for entities such as the General Data Protection Regulation (GDPR) and the Federal Risk and Authorization Management Program (FedRAMP). Such features may limit where the telemetry data is stored and who has access to the telemetry data, as well as enforce retention or deletion life cycles.

Slack is no stranger to compliance requirements, and we enforce those requirements through a combination of pattern matching and redaction, and a service that detects and alerts on the existence of sensitive information or PII. In addition to those components, we provide tooling to allow self-service deletion of data that is out of compliance.

## Workload Isolation

*Workload isolation* allows you to protect the reliability and availability of data sets in critical scenarios. Partitioning your telemetry data across multiple clusters allows you to isolate workloads from one another. For example, you may wish to separate an application that produces a high volume of logs from an application that produces a very low volume of log data. By putting the logs of these applications in the same cluster, an expensive query against the high-volume log can frequently slow cluster performance, negatively affecting the experience for other users on the same cluster. For lower-volume logs such as host logs, having a higher retention period for this data may be desirable, as it may provide historical context. By isolating workloads, you gain flexibility and reliability.

## Data Buffering

Observability backends will not be perfectly reliable and can experience outages. Such outages are not typically measured in the SLOs of a service that relies on that observability backend. It is entirely possible for a service to be available but your observability backend to be unavailable for unrelated reasons, impairing visibility into the service itself. In those cases, to prevent a gap in your telemetry data, you may want to temporarily *buffer* the data onto a local disk on a node, or leverage a message queue system such as Kafka or RabbitMQ, which will allow messages to be buffered and replayed.

Telemetry data can have large spikes in volume. Natural patterns like users using the service more or an outage on a critical database component failure often lead to errors in all infrastructure components, leading to a higher volume of emitted events and a cascading failure. Adding a buffer would smooth the data ingestion to the backend. This also improves the reliability of data ingestion into the backend since it is not being saturated by those spikes in volume.

A buffer also acts as an intermediate step to hold data, especially when further processing is desired before sending the data to the backend. Multiple buffers can be used—for example, combining a local disk buffer on the application with a dead-letter queue to protect timeliness of data during volume spikes.

We use Kafka extensively at Slack to achieve this goal of buffering data, and our clusters retain up to three days of events to ensure data consistency after a backend recovers from an outage. In addition to Kafka, we use a limited on-disk buffer in our producer component, allowing our ingestion agents to buffer events if a Kafka cluster becomes unavailable or saturated. End to end, the pipeline is designed to be resilient during service disruptions, minimizing data loss.

## Capacity Management

Often for capacity planning or cost-control reasons, you may want to assign quotas for categories of telemetry and enforce with rate limiting, sampling, or queuing.

### Rate limiting

Since the telemetry data is often produced in relationship to natural user requests, the telemetry data from applications tend to follow unpredictable patterns. A telemetry pipeline can smooth these data spikes for the backend by sending the telemetry to the backend at only a constant rate. If there is more data than this rate, the pipeline can often hold data in memory until the backend can consume it.

If your systems consistently produce data at a higher rate than the backend can consume, your telemetry pipeline can use *rate limits* to mitigate impacts. For instance, you could employ a hard rate limit and drop data that is over the rate limit, or ingest the data under a soft rate limit but aggressively sample the data until a hard rate limit is hit, allowing you to protect availability. It can be considered acceptable to make this trade-off in cases where the event data is redundant, so while you drop events, you will not experience a loss of signal.

### Sampling

As discussed in [Chapter 17](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch17.html#cheap_and_accurate_enough_sampling), your ingestion component can utilize moving average *sampling*, progressively increasing sample rates as volume increases to preserve signal and avoid saturating backends downstream in the pipeline.

### Queuing

You can prioritize ingesting recent data over older data to maximize utility to developers. This feature is especially useful during log storms in logging systems. *Log storms* happen when the system gets more logs than its designed capacity.

For instance, a large-scale incident like a critical service being down would cause clients to report a higher volume of errors and would overwhelm the backend. In this case, prioritizing fresh logs is more important than catching up with old logs, since fresh logs indicate the current state of the system, whereas older logs tell you the state of the system at a past time, which becomes less relevant the further you are from the incident. A backfill operation can tidy up the historical data afterward, when the system has spare capacity.

## Data Filtering and Augmentation

In the case of metrics (e.g., Prometheus), an engineer may accidentally add a high-cardinality field like user ID or an IP address, leading to *cardinality explosion*. Typically, metrics systems are not designed to handle high-cardinality fields, and a pipeline can provide a mechanism to handle them. This could be something as simple as dropping the time series containing high-cardinality fields. To reduce impact of a cardinality explosion, advanced approaches include pre-aggregating the data in the high-cardinality field(s), or dropping data with invalid data (like incorrect or malformed timestamps).

In the case of logs, you would want to filter PII data, filter security data like security tokens, or sanitize URLs since often the logging system is not meant to store sensitive data. For trace data, you might like to additionally sample high-value traces or drop low-value spans from making it to the backend system.

In addition to filtering data, the telemetry pipeline can also be used to enrich the telemetry data for better usability. Often this includes adding additional metadata that is available outside the process, like region information or Kubernetes container information; resolving IPs to their hostnames to enhance usability; or augmenting log and trace data with GeoIP information.

## Data Transformation

A robust telemetry pipeline may be expected to ingest a cornucopia of data types such as unstructured logs, structured logs in various formats, metrics time-series points, or events in the form of trace spans. In addition to being type-aware, the pipeline may provide APIs, either externally, or internally, in various wire formats. The functionality to transform those data types becomes a key component of a pipeline.

While it can be computationally expensive, the benefits of translating each data point into a common event format outweighs the costs associated with the compute needed to process the data. Such benefits include maximum flexibility around technology selection, minimal duplication of the same event in different formats, and the ability to further enrich the data.

Telemetry backends typically have discrete and unique APIs, and no standard pattern exists. Being able to support an external team’s needs for a particular backend can be valuable and as simple as writing a plug-in in a preprocessing component to translate a common format into a format that the backend can ingest.

Slack has several real-world examples of this transformation. We transform various trace formats (e.g., Zipkin and Jaeger) into our common SpanEvent format. This common format also has the benefit of being directly writable to a data warehouse and is easily queried by common big data tools such as Presto and can support joins or aggregations. Such tracing data sets in our data warehouse support long-tail analytics and can drive powerful insights.

## Ensuring Data Quality and Consistency

The telemetry data gathered from applications can potentially have data-quality issues. A common approach to ensure data quality is to drop data with a timestamp field that is too far into the past or too far into the future.

For example, misconfigured devices that report data with incorrect timestamps pollute the overall data quality of the system. Such data should be corrected by replacing the malformed timestamp with a timestamp at ingestion time or dropped. In one real-world case, mobile devices with Candy Crush installed would often report timestamps far in the future as users manually altered the system time on the device in order to gain rewards in-game. If dropping the data is not an option, the pipeline should provide an alternative location to store that data for later processing.

To use logs as an example, the pipeline can perform useful operations such as the following:

- Convert unstructured logs to structured data by extracting specific fields

- Detect and redact or filter any PII or sensitive data in the log data

- Convert IP addresses to geographic latitude/longitude fields through the use of geolocation databases such as MaxMind

- Ensure the schema of the log data, to ensure that the expected data exists and that specific fields are of specific types

- Filter low-value logs from being sent to the backend

For trace data in particular at Slack, one way we ensure data consistency is by using simple data-filtering operations like filtering low-value spans from making it to the backend, increasing the overall value of the data set. Other examples of ensuring quality include techniques like tail sampling, in which only a small subset of the reported traces are selected for storage in the backend system based on desirable attributes, such as higher reported latency.

# Managing a Telemetry Pipeline: Anatomy

In this section, we cover the basic components and architecture of a functional telemetry pipeline. Simply stated, a *telemetry pipeline* is a chain of receiver, buffer, processor and exporter components, all in a series.

The following are details of these key components of a telemetry pipeline:

- A *receiver* collects data from a source.

A receiver can collect the data directly from applications like a Prometheus scraper. Alternatively, a receiver can also ingest data from a buffer.

A receiver can expose an HTTP API to which applications can push their data.

A receiver can also write to a buffer to ensure data integrity during disruptions.

- A *buffer* is a store for the data, often for a short period of time.

A buffer holds the data temporarily until it can be consumed by a backend or downstream application.

Often a buffer is a pub-sub system like Kafka or Amazon Kinesis.

An application can also push the data directly to a buffer. In such cases, a buffer also acts as a source of the data for a receiver.

- A *processor* often takes the data from a buffer, applies a transformation to it, and then persists the data back to a buffer.

- An *exporter* is a component that acts as a sink for the telemetry data. An exporter often takes the data from a buffer and writes that data to a telemetry backend.

In simple setups, a telemetry pipeline consists of the pattern of receiver → buffer → exporter, often for each type of telemetry backend, as shown in [Figure 18-1](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch18.html#a_receivercomma_buffercomma_and_exporte).

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492076438/files/assets/oben_1801.png)

###### Figure 18-1. A receiver, buffer, and exporter as frequently used in simple telemetry pipelines

However, a complex setup can have a chain of receiver → buffer → receiver → buffer → exporter, as shown in [Figure 18-2](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch18.html#an_advanced_example_of_a_telemetry_pipe).

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492076438/files/assets/oben_1802.png)

###### Figure 18-2. An advanced example of a telemetry pipeline with a processor

A receiver or the exporter in a pipeline is often responsible for only one of the possible operations—like capacity planning, routing, or data transformation for the data. [Table 18-1](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch18.html#roles_of_the_rece) shows a sample of operations that can be performed on various types of telemetry data.

| Telemetry data type | Receiver | Exporter or processor |
| --- | --- | --- |
| Trace data | <br><br>Gather trace data in different formats (e.g., Zipkin/Jaeger/AWS X-Ray, OTel)<br>Gather data from different services (e.g., from all Slack mobile clients)<br><br> | <br><br>Ingest data into various trace backends<br>Perform tail sampling of the data<br>Drop low-value traces<br>Extract logs from traces<br>Route trace data to various backends for compliance needs<br>Filter data<br><br> |
| Metrics data | Identify and scrape targets | <br><br>Relabel metrics<br>Downsample metrics<br>Aggregate metrics<br>Push data to multiple backends<br>Detect high-cardinality tags or time series<br>Filter high-cardinality tags or metrics<br><br> |
| Logs data | <br><br>Gather data from different services<br>Endpoint for collecting logs pushed from different services<br><br> | <br><br>Parse log data into semistructured or structured logs<br>Filter PII and sensitive data from logs<br>Push data to multiple backends for GDPR reasons<br>Route infrequently queried or audit logs to flat files, and high-value logs or frequent queries to an indexed system<br><br> |

In open source systems, a receiver may also be called a *source,* and an exporter is usually called a *sink*. However, this naming convention obscures the fact that these components can be chained.

Data transformations and filtering rules often differ depending on the type of the telemetry data, necessitating isolated pipelines.

# Challenges When Managing a Telemetry Pipeline

Running a pipeline at scale comes with a set of challenges that are well-known to us at Slack, and we have outlined them in this section. At a smaller scale, telemetry pipelines are fairly simple to set up and run. They typically involve configuring a process such as the OpenTelemetry Collector to act as a receiver and exporter.

At a larger scale, these pipelines would be processing hundreds of streams. Keeping them up and running can be an operational challenge, as it requires ensuring the performance, correctness, reliability and availability of the pipeline. While a small amount of software engineering work is involved, a large part of the work running the pipeline reliably involves control theory.

## Performance

Since applications can produce data in any format and the nature of the data they produce can change, keeping the pipeline performant can be a challenge. For example, if an application generates a lot of logs that are expensive to process in a logging pipeline, the log pipeline becomes slower and needs to be scaled up. Often slowness in one part of the pipeline may cause issues in other parts of the pipeline—like spiky loads, which, in turn, can destabilize the entire pipeline.

## Correctness

Since the pipeline is made up of multiple components, determining whether the end-to-end operation of the pipeline is correct can be difficult. For example, in a complex pipeline, it can be difficult to know whether the data you are writing is transformed correctly or to ensure that the data being dropped is the only type of data being dropped. Further, since the data format of the incoming data is unknown, debugging the issues can be complex. You must, therefore, monitor for errors and data-quality issues in the pipeline.

## Availability

Often the backends or various components of the pipeline can be unreliable. As long as the software components and sinks are designed to ensure resiliency and availability, you can withstand disruptions in the pipeline.

## Reliability

As part of a reliable change management practice, we ensure pipeline availability when making software changes or configuration changes. It can be challenging to deploy a new version of a component and maintain pipeline end-to-end latency and saturation at acceptable levels.

Reliably managing flows requires a good understanding of the bottlenecks in the processing pipeline, or capacity planning. A saturated component can be a bottleneck that slows the entire pipeline. Once the bottleneck is identified, you should ensure that sufficient resources are allocated to the bottleneck or that the component is performing sufficiently well to keep up with the volume. In addition to capacity planning, the pipeline should have good monitoring to identify how much the rates of flows vary among components of the pipeline.

Reprocessing the data and backfilling is often one of the most complex and time-consuming parts of managing a data pipeline. For example, if you fail to filter some PII data from logs in the pipeline, you need to delete the data from your log search system and backfill the data. While most solutions work well in a normal case, they are not very equipped to deal with backfilling large amounts of historical data. In this case, you need to ensure that you have enough historical data in the buffer to reprocess the data.

## Isolation

If you colocate logs or metrics from a high-volume system customer and a low-volume customer located in the same cluster, availability issues may occur if a high volume of logs causes saturation of the cluster. So, the telemetry pipeline should be set up such that these streams can be isolated from each other and possibly written to different backends.

## Data Freshness

In addition to being performant, correct, and reliable, a telemetry pipeline should also operate at or near real time. Often the end-to-end latency between the production of data and it being available for consumption is in the order of seconds, or tens of seconds in the worst case. However, monitoring the pipeline for data freshness can be a challenge since you need to have a known data source that produces the data at a consistent pace.

Host metrics, such as Prometheus, can be used because they are typically scraped at a consistent interval. You can use those intervals to measure the data freshness of your logs. For logs or traces, a good, consistent data source is often not available. In those cases, it could be valuable for you to add a synthetic data source.

At Slack, we add synthetic logs to our log streams at a fixed rate of *N* messages per minute. This data is ingested into our sinks, and we periodically query these known logs to understand the health and freshness of the pipeline. For example, we produce 100 synthetic log messages per minute from a data source to our largest log cluster (100 GB per hour log data). Once this data is ingested, we monitor and query these logs every 10 seconds, to see whether our pipeline is ingesting the data in real time. We set our freshness SLO on the number of times we receive all the messages in a given minute in the last five minutes.

Care should be taken to ensure that the synthetic data has an unique value or is filtered out so it doesn’t interfere with users querying for normal logs. We also make sure that the synthetic log is emitted from multiple areas in our infrastructure, to ensure monitoring coverage throughout our telemetry pipeline.

# Use Case: Telemetry Management at Slack

Slack’s telemetry management program has evolved organically to adapt to various observability use cases at Slack. To handle these use cases, the system consists of open source components and Murron, in-house software written in Go. In this section, we describe the discrete components of the pipeline and how they serve different departments within Slack.

## Metrics Aggregation

Prometheus is the primary system for metrics at Slack. Our backend was first written in PHP and later in Hack. Since PHP/Hack use a process per request model, the Prometheus pull model wouldn’t work because it does not have the process context and has only the host context. Instead, Slack uses a custom Prometheus library to emit metrics per request to a local daemon written in Go.

These per request metrics are collected and locally aggregated over a time window by that daemon process. The daemon process also exposes a metrics endpoint, which is scraped by our Prometheus servers, as shown in [Figure 18-3](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch18.html#aggregation_of_metrics_from_a_per_reque). This allows us to collect metrics from our PHP/Hack application servers.

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492076438/files/assets/oben_1803.png)

###### Figure 18-3. Aggregation of metrics from a per-request process application

Outside of PHP/Hack, Slack also runs applications in Go or Java that expose metric endpoints, and their metrics are able to be scraped by Prometheus directly.

## Logs and Trace Events

Murron is an in-house Go application that forms the backbone of our log and trace event pipeline at Slack. Murron consists of three types of components: a receiver, a processor and an exporter. A *receiver* receives the data from a source (over HTTP, gRPC API, and in several formats like JSON, Protobuf, or custom binary formats) and sends it to a buffer like Kafka or another ingestor. A processor transforms the messages, which contain log or trace data, from one format to another. A consumer consumes the messages from Kafka and sends them to various sinks like Prometheus, Elasticsearch, or an external vendor.

The core primitive in Murron is a *stream* that is used to define the telemetry pipeline. A stream consists of a *receiver* that receives messages containing logs or trace data from the application, a *processor* to process the messages, and a *buffer* (such as a Kafka topic) for these messages. In addition, for each stream we can also define *exporters,* which consume the messages from a buffer and route them to appropriate backends after processing, if desired (see [Figure 18-4](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch18.html#slack_telemetry_pipeline_with_receivers)).

To facilitate routing and custom processing, Murron wraps all the messages received in a custom envelope message. This envelope message contains information like the name of the stream this message belongs to, which is used to route messages within several Murron components. In addition, the envelope message contains additional metadata about the message like hostname, Kubernetes container information, and the name of the process. This metadata is used to augment the message data later in the pipeline.

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492076438/files/assets/oben_1804.png)

###### Figure 18-4. Slack telemetry pipeline with receivers, buffers, and exporters for trace data

In the OpenTelemetry specification, a trace data structure is a directed acyclic graph of linked events called *spans*. These data structures are often wrapped in a higher-level tracing API to produce traces, and the data is accessed via a Trace UI on the consumption side. This hidden structure prevents us from querying raw trace data in a way that would make the traces suitable for a wide variety of use cases.

To enable natural adoption through ease of use, we implemented a new simplified span format called a *SpanEvent* that is easier to produce and consume. A typical SpanEvent consists of the following fields: an ID, timestamp, duration, parent ID, trace ID, name, type, tags, and a special span type field. Like a trace, a causal graph is a directed acyclic graph of SpanEvents. Giving engineers the ability to easily produce and analyze traces outside of traditional instrumentation opens up a lot of new avenues, such as instrumenting CI/CD systems, as described in [Chapter 11](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch11.html#observability_driven_development).

To support the causal graph model, we have built custom tracing libraries for languages like PHP/Hack, JavaScript, Swift, and Kotlin. In addition to those libraries, we leverage open source tracing libraries for Java and Go.

Our Hack applications are instrumented with an [OpenTracing-compatible tracer](https://opentracing.io/); we discussed OpenTracing in [“Open Instrumentation Standards”](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch07.html#open_instrumentation_standards). Our mobile and desktop clients trace their code and emit SpanEvents using either a high-level tracer or a low-level span-creation API. These generated SpanEvents are sent to Wallace over HTTP as JSON or Protobuf-encoded events.

Wallace, based on Murron, is a receiver and processor that operates independently from our core cloud infrastructure, so we can capture client and service errors even when Slack’s core infrastructure is experiencing a full site outage. Wallace validates the span data it receives and forwards those events to another Murron receiver that writes the data to our buffer, Kafka (see [Figure 18-5](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch18.html#slackapostrophes_tracing_infrastructure)).

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492076438/files/assets/oben_1805.png)

###### Figure 18-5. Slack’s tracing infrastructure, with applications in pink (light gray in print), receivers and exporters in blue (medium gray)

Our internal Java and Go applications use the open source instrumentation libraries from Zipkin and Jaeger, respectively. To capture the spans from these applications, Wallace exposes receivers for both types of span data. These receivers, called *trace adapters*, translate the reported spans into our SpanEvent format and write them to Wallace, which in turn forwards them to a Murron receiver that writes the data to Kafka.

The trace data written to Kafka is consumed primarily by three exporters based on Murron and Secor, which is an open source project maintained by Pinterest:

Elasticsearch exporterA Murron exporter reads our SpanEventsfrom Kafka and sends them to Elasticsearch, an event store that allows us to display events on a dashboard (in our case, we primarily use Grafana) and set custom alerts on those events.Data warehouse exporterWe use Secor, an open source project by Pinterest, to transform the data from Kafka and upload it to Amazon S3 to be ingested into our Presto data warehouse.Honeycomb exporterFinally, a Murron exporter consumesevents from Kafka, filters out low-value spans, transforms the data into a custom event format specific to Honeycomb, and routes it to different data sets to be queried in Honeycomb.By using those exporters, we gain almost immediate access to our trace data with an end-to-end latency on the order of seconds. We use Honeycomb and Grafana (via Elasticsearch) to visualize this data and run simple analytics, which plays an important role in making our traces useful for triage.

By comparison, our data warehouse has a typical landing time of two hours. We use Presto, which supports complex analytical queries over longer time ranges via SQL. We typically store 7 days of events in Elasticsearch, and Honeycomb supports up to 60 days of events, but our Presto backend, Hive, can store the data for up to two years. This enables our engineers to visualize long-term trends beyond the capabilities of Honeycomb and Elasticsearch.

Murron manages over 120 streams of data at a volume of several million messages per second. All of this data is buffered through over 200 Kafka topics across 20 clusters.

# Open Source Alternatives

Our telemetry pipeline has organically evolved over several years and consists of a mix of open source components and in-house software. From the previous section, an astute reader would have noticed that some of our software has overlapping capabilities and that we could benefit from consolidating systems. The observability telemetry pipeline space has matured quite a bit, and several newer, viable options exist now, compared to three years ago. In this section, we will look at other open source alternatives.

In the early days of observability, no specific tools existed for setting up a telemetry pipeline. Most engineers used tools like rsyslog and wrote custom tools or used third-party vendor tools to ship data to a backend. Over time, teams recognized the gap and developed tools like Facebook’s [Scribe](https://github.com/facebookarchive/scribe), which introduced the basic ideas of routing logs to various backends by using streams. For reliably delivering the logs when the downstream system was down, Scribe introduced ideas like local disk persistence, which would persist the logs to local disk when the downstream system couldn’t keep up with the log volume or was unresponsive. Facebook’s Scribe also established the ideas of chaining multiple instances together and forming a telemetry management pipeline at scale.

In later years, telemetry pipelines have evolved to more full-fledged systems that allowed for features like advanced log parsing and field manipulation, as well as advanced rate limiting or dynamic sampling capability. With the rise of modern pub/sub systems like Kinesis/Kafka, most telemetry pipelines included support to use them as a source of data and to buffer intermediate data in a pipeline. In the logging vertical, popular services like timber, [Logstash](https://www.elastic.co/logstash)/Filebeat, Fluentd, and rsyslog are available to transport logs to receivers. For metrics use cases, projects like [Prometheus Pushgateway](https://github.com/prometheus/pushgateway), and [M3 Aggregator](https://m3db.io/docs/how_to/m3aggregator) were built to aggregate metrics. For trace data, tools like [Refinery](https://docs.honeycomb.io/manage-data-volume/refinery) were built to further filter, sample, and process trace data. Those tools are designed to be modular, allowing plug-ins to be developed that add support for receivers and exporters to send and receive data from and to a myriad of systems.

As more and more data is passed through these telemetry pipelines, their efficiency and reliability have become increasingly important. As a result, modern systems are being written in more efficient languages like C (Fluent Bit), Go (Cribl) and Rust ([Vector](https://vector.dev/)). If we are to process terabytes of data per second, infrastructure efficiency of the telemetry pipeline becomes very important.

# Managing a Telemetry Pipeline: Build Versus Buy

For historical reasons, Slack uses a mix of open source and in-house software in its telemetry pipeline management. These days, these reasons have less meaning, as a multitude of open source alternatives exist and can be used to easily form the basis of your telemetry pipeline. These open source tools are usually modular in nature and can be easily extended to add additional functionality for your custom use cases. Given the wide availability of tools, it does not make economic sense to spend engineering resources developing in-house software to make up the basis of your telemetry management pipeline.

Open source software, naturally, is free, but the cost of maintaining and operating a telemetry pipeline should be taken into consideration. Vendors exist on the other side of the build-versus-buy equation and promise to simplify the operational burden as well as provide a strong user experience. Simplification and ease of use is an attractive proposition and may make economic sense, depending on the maturity of your organization. This balance will shift over time as your organization grows, so keep that in mind when selecting your approach. For more considerations when deciding whether to build or to buy, see [Chapter 15](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch15.html#build_versus_buy_and_return_on_investme).

# Conclusion

You can get started today by using several off-the-shelf services in conjunction with one another. You may be tempted to write a new system from scratch, but we recommend adapting an open source service. Smaller pipelines can run on autopilot, but as the organization grows, managing a telemetry pipeline becomes a complex endeavor and introduces several challenges.

As you build out your telemetry management system, try to build for the current needs of the business and anticipate—but don’t implement for—new needs. For example, you may want to add compliance features sometime down the road, or you may want to introduce advanced enrichment or filtering. Keeping the pipeline modular and following the producer, buffer, processor and exporter model will keep your observability function running smoothly, while providing value to your business.
