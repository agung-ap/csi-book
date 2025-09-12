# Chapter 16. Efficient Data Storage

In this chapter, we’ll look at the challenges that must be addressed to effectively store and retrieve your observability data when you need it most. Speed is a common concern with data storage and retrieval, but other functional constraints impose key challenges that must be addressed at the data layer. At scale, the challenges inherent to observability become especially pronounced. We will lay out the functional requirements necessary to enable observability workflows. Then we will examine real-life trade-offs and possible solutions by using the implementation of Honeycomb’s proprietary Retriever data store as inspiration.

You will learn about the various considerations required at the storage and retrieval layers to ensure speed, scalability, and durability for your observability data. You will learn about a columnar data store and why it is particularly well suited for observability data, how querying workloads must be handled, and considerations for making data storage durable and performant. The solutions presented in this chapter are not the only possible solutions to the various trade-offs you may encounter. However, they’re presented as real-world examples of achieving the necessary results when building an observability solution.

# The Functional Requirements for Observability

When you’re experiencing an outage in production, every second counts. Queries against your observability data must return results as quickly as possible. If you submit a query and can get a cup of coffee while you wait for results to return, you’re fighting a losing battle with a tool unfit for production (see [“Debugging from First Principles”](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch08.html#debugging_from_first_principles)). Getting results within seconds is what makes observability a useful investigative practice that lets you iterate quickly until you find meaningful results.

As covered in [Part II](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/part02.html#fundamentals_of_observability), events are the building blocks of observability, and traces are a collection of interrelated events (or trace spans). Finding meaningful patterns within those events requires an ability to analyze high-cardinality and high-dimensionality data. Any field within any event (or within any trace span) must be queryable. Those events cannot be pre-aggregated since, in any given investigation, you won’t know in advance which fields may be relevant. All telemetry data must be available to query in pre-aggregate resolution, regardless of its complexity, or you risk hitting investigative dead ends.

Further, because you don’t know which dimensions in an event may be relevant, you cannot privilege the data-retrieval performance of any particular dimension over others (they must all be equally fast). Therefore, all possible data needed must be indexed (which is typically prohibitively expensive), or data retrieval must always be fast without indexes in place.

Typically, in observability workflows, users are looking to retrieve data in specific time ranges. That means the only exception to privileged data is the dimension of time. It is imperative that queries return all data recorded within specific time intervals, so you must ensure that it is indexed appropriately. A TSDB would seem to be the obvious choice here, but as you’ll see later in this chapter, using one for observability presents its own set of incompatible constraints.

Because your observability data is used to debug production issues, it’s imperative to know whether the specific actions you’ve taken have resolved the problem. Stale data can cause engineers to waste time on red herrings or make false conclusions about the current state of their systems. Therefore, an efficient observability system should include not just historical data but also fresh data that reflects the current state in close to real time. No more than seconds should elapse between when data is received into the system and when it becomes available to query.

Lastly, that data store must also be durable and reliable. You cannot lose the observability data needed during your critical investigations. Nor can you afford to delay your critical investigations because any given component within your data store failed. Any mechanisms you employ to retrieve data must be fault-tolerant and designed to return fast query results despite the failure of any underlying workers. The durability of your data store must also be able to withstand failures that occur within your own infrastructure. Otherwise, your observability solution may also be inoperable while you’re attempting to debug why the production services it tracks are inoperable.

Given these functional requirements necessary to enable real-time debugging workflows, traditional data storage solutions are often inadequate for observability. At a small enough scale, data performance within these parameters can be more easily achieved. In this chapter, we’ll examine how these problems manifest when you go beyond single-node storage solutions.

## Time-Series Databases Are Inadequate for Observability

At its core, observability data consists of structured events representing information about a program’s execution. As seen in [Chapter 5](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch05.html#structured_events_are_the_building_bloc), these structured events are essentially collections of key-value pairs. In the case of tracing, the structured events can be related to one another in order to visualize parent-child relationships between trace spans. Some of those fields may be “known” (or predictable), given the auto-instrumentation use case seen in [Chapter 7](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch07.html#instrumentation_with_opentelemetry). However, the most valuable data will be custom to your particular application. That custom data is often generated ad hoc, meaning that the schema used to store it is often dynamic or flexible.

As discussed in [Chapter 9](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch09.html#how_observability_and_monitoring_come_t), time-series data (metrics) aggregates system performance into simple measures. Metrics aggregate all underlying events over a particular time window into one simple and decomposable number with an associated set of tags. This allows for a reduction in the volume of data sent to a telemetry backend data store and improves query performance but limits the number of answers that can later be derived from that data. While some metrics data structures (like those used to generate histograms) may be slightly more sophisticated, they still essentially bucket similar value ranges together and record counts of events sharing similar values (see [Figure 16-1](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch16.html#a_prototypical_tsdb_showing_a_limited_a)).

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492076438/files/assets/oben_1601.png)

###### Figure 16-1. A prototypical TSDB showing a limited amount of cardinality and dimensionality: tags for HTTP method and status code, bucketed by timestamp

Traditionally, a *time-series database* (TSDB) is used to store aggregated metrics. Time-series data storage mechanisms aim to amortize the cost of additional traffic by ensuring that new combinations of aggregations and tags are rare; a high overhead is associated with creating a record (or database row) for each unique time series, but appending a numeric measurement to a time series that already exists has a low cost. On the query side, the predominant resource cost in a TSDB is finding which time series matches a particular expression; scanning the set of results is inexpensive since millions of events can be reduced into a small number of time-windowed counts.

In an ideal world, you could simply switch to recording structured events utilizing the same TSDB. However, the functional observability requirement to surface meaningful patterns within high-cardinality and high-dimensionality data makes using a TSDB prohibitive. Although you could convert each dimension to a tag name, and each value to the tag’s value, this will create a new time series for each unique combination of tag values (see [Figure 16-2](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch16.html#the_explosion_of_that_same_tsdb_when_a)).

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492076438/files/assets/oben_1602.png)

###### Figure 16-2. The explosion of that same TSDB when a high-cardinality index, `userid`, is added

The cost of creating new time series amortizes to 0 across measurements only if the same tags are reused and incremented often. But each structured event is often *unique* and will cause the overhead of row creation to be linear with the number of events received. This problem of *cardinality explosion* thus makes TSDBs unsuitable for storing structured events. We need a different solution.

## Other Possible Data Stores

At first pass, storing structured sets of key-value pairs may appear similar to other workloads that can be addressed by general-purpose storage NoSQL databases, like MongoDB or Snowflake. However, while the ingress of event telemetry data (or event ingestion) is well suited to those databases, the egress patterns for that data (or event querying) are dramatically different from traditional workloads because of the functional requirements for observability.

That iterative analysis approach (described in [Chapter 8](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch08.html#analyzing_events_to_achieve_observabili)) requires the ability to understand more than one dimension at a time, regardless of the number of possible values each of those dimensions contains. In other words, you must be able to query on data with arbitrary dimensionality and cardinality. A NoSQL database is likely to be slow for these kinds of arbitrary queries, unless the query utilizes only specific fields that are already indexed. But pre-indexing doesn’t allow you to arbitrarily slice and dice; you’re limited to slicing and dicing along one dimension at a time, and only the dimensions you remembered to index or pre-aggregate up front. And if each value is unique, it will take up as much space in the index as in the original table, resulting in a collection of indices larger than the original data if we index every column. So trying to tune a NoSQL database to optimize its queries won’t work. What if instead of trying to make a subset of queries fast, we tried to make *all* queries possible to complete within a reasonable amount of time?

At Facebook, the Scuba system effectively solved the problem of real-time observability querying through consumption of huge amounts of RAM in order to allow full table accesses.[1](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch16.html#ch01fn12) However, it made the performance trade-off of using system memory for storage to speed up querying. That implementation decision made Scuba economically infeasible for mass adoption beyond the walls of Facebook. As of the time of this writing, 1 terabyte of RAM costs approximately $4,000, whereas 1 TB of SSD costs approximately $100. If attempting to use Scuba as a data store, an organization would be limited to querying only the amount of data available in RAM. For most large organizations with a reasonably sized infrastructure, that constraint would limit the time window for queryable telemetry data to minutes rather than hours or days.

Perhaps we can look to other data stores that are used to store event-like data—namely, telemetry backends for tracing solutions. At the time of this writing, a few open source implementations of large-scale storage engines exist, mostly [interoperable with the Jaeger tracing frontend](https://www.jaegertracing.io/docs/1.17/features/#multiple-storage-backends): Apache Cassandra, Elasticsearch/OpenSearch, ScyllaDB, and InfluxDB. These allow ingestion and durable storage of tracing data using a schema, but they are not necessarily purpose-built for tracing specifically. Grafana Tempo is an example of a newer implementation purpose-built for tracing, but it is not necessarily built for the functional querying requirements of observability, as we will see throughout this chapter. Perhaps the best open source approach in the long term is to adopt a columnar store such as [ClickHouse](https://clickhouse.com/) or [Apache Druid](https://druid.apache.org/) with extensions to optimize for tracing, as [SigNoz](https://signoz.io/docs/architecture) has done. At the time of writing, Polar Signals just announced [ArcticDB](https://www.polarsignals.com/blog/posts/2022/05/04/introducing-arcticdb), an open source columnar store for profiling and other observability data.

In the next section, we will examine the technical requirement to both store and query trace data so that it meets the functional requirements of observability. While anything is technically possible, the chapter will look at implementations that are financially feasible at scale so that you can store your event data and derive insights beyond what is possible from just examining individual traces.

## Data Storage Strategies

Conceptually, wide events and the trace spans they represent can be thought of as a table with rows and columns. Two strategies can be used to store a table: row-based storage and column-based storage. For the observability domain, *rows* pertain to individual telemetry events, and *columns* pertain to the fields or attributes of those events.

In *row-based storage*, each row of data is kept together (as in [Figure 16-3](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch16.html#a_row_storecomma_indicating_sharding_of)), with the assumption that the entire row will be fetched at once. In *column-based storage*, columns of data are kept together, disaggregated from their rows. Each approach has trade-offs. To illustrate these trade-offs, we will use the time-tested [Dremel](https://oreil.ly/TtCUa), ColumnIO, and Google’s [Bigtable](https://oreil.ly/uILVW) as exemplars of the broader computational and storage models, rather than focus on specific open source telemetry stores used in practice today. In fact, the [Dapper tracing system](https://oreil.ly/cW1Px) was originally built on the Bigtable data store.

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492076438/files/assets/oben_1603.png)

###### Figure 16-3. A row store, indicating sharding of contiguous rows kept together as a single unit (a tablet) for lookup and retrieval

Bigtable uses a row-based approach, meaning that the retrieval of individual traces and spans is fast because the data is serialized and the primary key is indexed (e.g., by time). To obtain one row (or scan a few contiguous rows), a Bigtable server needs to retrieve only one set of files with their metadata (a *tablet*). To function efficiently for tracing, this approach requires Bigtable to maintain a list of rows sorted by a primary row key such as trace ID or time. Row keys that arrive out of strict order require the server to insert them at the appropriate position, causing additional sorting work at write time that is not required for the nonsequential read workload.

As a mutable data store, Bigtable supports update and deletion semantics and dynamic repartitioning. In other words, data in Bigtable has flexibility in data processing at the cost of complexity and performance. Bigtable temporarily manages updates to data as an in-memory mutation log plus an ongoing stack of overlaid files containing key-value pairs that override values set lower in the stack. Periodically, once enough of these updates exist, the overlay files must be “compacted” back into a base immutable layer with a process that rewrites records according to their precedence order. That compaction process is expensive in terms of disk I/O operations.

For observability workloads, which are effectively write-once read-many, the compaction process presents a performance quandary. Because newly ingested observability data must be available to query within seconds, with Bigtable the compaction process would either need to run constantly, or you would need to read through each of the stacked immutable key-value pairs whenever a query is submitted. It’s impractical to perform analysis of arbitrary fields without performing a read of all columns for the row’s tablet to reproduce the relevant fields and values. It’s similarly impractical to have compaction occur after each write.

Bigtable optionally allows you to configure *locality groups* per set of columns in a column family that can be stored separately from other column families. But examining data from even a single column from within a locality group still reads the entire locality group, while discarding most of the data, slowing the query and wasting CPU and I/O resources. You can add indices on selected columns or break out locality groups by predicted access patterns, but this workaround contradicts the observability requirement of arbitrary access. Sparse data within a locality group’s columns is inexpensive within Bigtable since columns exist only within the locality group, but locality groups as a whole should not be empty because of their overhead.

Taken to the extreme limit of adding an index on each column or storing each column in a separate locality group, the cost adds up.[2](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch16.html#ch01fn13) Notably, the Google Dapper backend paper notes that attempts to generate indexes in Bigtable on just three fields (service, host, and timestamp) for the Dapper Depots produced data that was 76% the size of the trace data itself.[3](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch16.html#ch01fn14) Therefore, if you could entirely eliminate the need for indexing, you’d have a more practical approach to storing distributed traces.

Independent of strategies like Bigtable, when using a column-based approach, it is possible to quickly examine only the desired subset of data. Incoming data is partitioned into columns (as in [Figure 16-4](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch16.html#column_store_showing_data_broken_down_b)), with a synthetic `id` column providing a primary key for each row. Each column file with a mapping from primary key to the value for that column is stored separately. Thus, you can independently query and access the data from each column.

However, the column-based approach does not guarantee that any given row’s data is stored in any particular order. To access the data for one row, you may need to scan an arbitrary quantity of data, up to the entire table. The Dremel and ColumnIO storage models attempt to solve this problem by breaking tables down with manual, coarse sharding (e.g., having separate tables for `tablename.20200820`, `tablename.20200821`, etc.) and leaving it to you, the user, to identify and join together tables at query time. This becomes immensely painful to manage at large data volume; the shards either become too large to efficiently query, or are broken into such numerous small shards (`tablename.20200820-000123`) that a human being has trouble constructing the query with the right shards.

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492076438/files/assets/oben_1604.png)

###### Figure 16-4. Column store showing data broken down by column rather than by row, with each set of columns able to be independently accessed, but with a full row scan necessitating pulling each column file

Neither the row-based or column-based approach is entirely adequate to meet the functional needs for observability. To address the trade-offs of both row and columnar storage, a hybrid approach—utilizing the best of both worlds—can meet the types of tracing workloads needed for observability. A hybrid approach would allow you to efficiently perform partial scans of both rows and columns. Remember that, for observability workloads, it is more important for query results to return fast than it is for them to be perfect.

To illustrate how you might practically achieve such a balance, we will examine the architecture of Honeycomb’s storage engine that represents one way to achieve those functional requirements.

# Case Study: The Implementation of Honeycomb’s Retriever

In this section, we explain the implementation of Honeycomb’s columnar data store (aka Retriever) to show how you can meet the functional requirements for observability with a similar design. This reference architecture is not the only way to achieve these functional requirements; as stated earlier, you could build an observability backend using ClickHouse or Druid as a foundation. However, we hope to illustrate concrete implementation and operational trade-offs that you would not otherwise see in an abstract discussion of a theoretical model.

## Partitioning Data by Time

Earlier, when we discussed the challenges of row-based versus column-based storage, we suggested a hybrid approach of partitioning the search space by timestamp to reduce the search space. However, time in a distributed system is never perfectly consistent, and the timestamp of a trace span could be the *start* rather than end time of a span, meaning data could arrive seconds or minutes behind the current time. It would not make sense to reach back into already saved bytes on disk to insert records in the middle, as that would incur costs to rewrite the data. How exactly should you perform that partitioning instead to make it efficient and viable in the face of out-of-order data arrival?

One optimization you can make is assuming that events are likely to arrive in close proximity to the timestamps at which they were actually generated, and that you can correct out-of-order arrival at read time. By doing this, you can continue to treat files storing incoming data as append-only, significantly simplifying the overhead at write time.

With Retriever, newly arriving trace spans for a particular tenant are inserted at the end of the currently active set of storage files (*segment*) for that tenant. To be able to query the right segments at read time, Retriever tracks the oldest and newest event timestamp for the current segment (creating a window that can potentially overlap with other segments’ windows). Segments eventually do need to end and be finalized, so you should pick appropriate thresholds. For instance, when one hour has elapsed, more than 250,000 records have been written, or when it has written more than 1 GB, Retriever finalizes the current segment as read-only and records the final oldest and newest timestamps of that segment in the metadata.

If you have adopted this windowed segment pattern, at read time you can utilize the metadata with timestamp windows of each segment to fetch only the segments containing the relevant timestamps and tenant data sets for the query you wish to perform (as shown in [Figure 16-5](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch16.html#segments_selected_for_querying_are_thos)). Typically, an observability workload is looking for data in a specific time range when queries are performed (e.g., “now to two hours ago,” or “2021-08-20 00:01 UTC to 2021-09-20 23:59 UTC”). Any other time range is extraneous to the query and, with this implementation, you don’t need to examine data for irrelevant segments that lack an overlap with the query time.

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492076438/files/assets/oben_1605.png)

###### Figure 16-5. Segments selected for querying are those that overlap at least in part with the query window; segments that start and end before or after the query window are excluded from analysis.

The advantage of this segment partitioning by time is twofold:

- Individual events do not need to be sorted and put into a strict order by event timestamp, as long as the start and end timestamp of each segment is stored as metadata and events arrive with a consistent lag.

- The contents of each segment are append-only artifacts that can be frozen as is once finished rather than needing to be built as mutable overlays/layers and compacted periodically.

The segment-partitioning approach has one potential weakness: when backfilled data is intermingled with current data (for instance, if a batch job finishes and reports timestamps from hours or days ago), each segment written will have metadata indicating it spans a broad time window covering not just minutes, but potentially hours’ or days’ worth of time. In this case, segments will need to be scanned for any query in that wide window, rather than being scanned for data in only the two narrower windows of time—the current time, and the time around when the backfilled events happened. Although the Retriever workload has not necessitated this to date, you could layer on more sophisticated segment partitioning mechanisms if it became a significant problem.

## Storing Data by Column Within Segments

As with the pure Dremel-like column-based approach outlined earlier, the next logical way to break down data after time has been taken out of the equation is by decomposing events into their constituent fields, and storing the contents of each field together with the same field across multiple events. This leads to a layout on disk of one append-only file per field per segment, plus a special timestamp index field (since every event must have a timestamp). As events arrive, you can append an entry to each corresponding file in the currently active segment for the columns they reference.

Once you have performed the filtering by segment timestamp described in the preceding section, you can restrict the amount of data that you access upon query to only the relevant columns specified in the query by accessing the appropriate columns’ own files. To be able to reconstruct the source rows, each row is assigned a timestamp and relative sequence within the segment. Each column file exists on disk as an array holding, alternately, sequence numbers for each row and the column’s value for each row (according to the sequence).

For instance, this source collection of rows (which we’ve supposed is ordered by time of arrival) might be transformed as follows:

```
Row 0: { "timestamp": "2020-08-20 01:31:20.123456",
 "trace.trace_id": "efb8d934-c099-426e-b160-1145a87147e2", "field1": null, ... }
Row 1: { "timestamp": "2020-08-20 01:30:32.123456",
 "trace.trace_id": "562eb967-9171-424f-9d89-046f019b4324", "field1": "foo", ... }
Row 2: { "timestamp": "2020-08-20 01:31:21.456789",
 "trace.trace_id": "178cdf06-dbc5-4c0d-b6b7-5383218e1f6d", "field1": "foo", ... }
Row 3: { "timestamp": "2020-08-20 01:31:21.901234",
 "trace.trace_id": "178cdf06-dbc5-4c0d-b6b7-5383218e1f6d", "field1": "bar", ... }

Timestamp index file
idx value
0 "2020-08-20 01:31:20.123456"
1 "2020-08-20 01:30:32.123456" (note: timestamps do not need to be chronological)
2 "2020-08-20 01:31:21.456789"
3 "2020-08-20 01:31:21.901234"
[...]

Raw segment column file for column `field1`
(note there is neither a row index nor value for missing/null values of a column)
idx value
1 "foo"
2 "foo"
3 "bar"
[...]
```

Given the tendency of columns to either be null or to contain repeated values that may have been seen before, you could use dictionary-based compression, sparse encoding, and/or run-length encoding to reduce the amount of space that each value takes when serializing the entire column.[4](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch16.html#ch01fn15) This benefits your backend in terms of the amount of data that must be tiered across your backend storage, as well as the amount of time that it takes to retrieve and scan that data:

```
compacted timestamp index file:
["2020-08-20 01:31:20.123456",
 "2020-08-20 01:30:32.123456",
 "2020-08-20 01:31:21.456789",
 "2020-08-20 01:31:21.901234",
 ...]

compacted segment column file, with dictionary, for column `example`
dictionary: {
  1: "foo",
  2: "bar",
  ...
}

presence:
[Bitmask indicating which rows have non-null values]

data from non-null row indices:
[1, 1, 2, ...]
```

Once a column is compacted, it (or the segment as a whole, consisting of a collection of column files) is then compressed with a standard algorithm such as LZ4 in order to further reduce the space it takes when archived.

In a column store, the cost of creating and tracking a column gets amortized against all of the values written to it; its analogue in the metrics world is the row/set of tags whose cost is amortized across all values. So, it is performant to create new columns whenever you might occasionally have non-null values, but it is not performant to create one-time-use columns that have only a single row with a non-null value.

In practice, this means that you don’t need to worry about manually adding new attributes/key names to your spans/events when writing your code, but you don’t want to programmatically create a column named `timestamp_2021061712345` that gets used once to write `true` and is never written to again; instead, use `timestamp` as the column value and `2021061712345` as the key.

## Performing Query Workloads

Performing a query by using a column store designed similarly to Retriever consists of six steps:

1. Identify all segments that potentially overlap with the time range of the query, using the start/end time of the query and start/end time of each eligible segment.

1. Independently, for each matching segment: for the columns used for the filters of the query (e.g., `WHERE`) or used for the output (e.g., used as a `SELECT` or `GROUP`), scan the relevant column files. To perform a scan, track the current offset you are working on. Evaluate the timestamp of the row at the current offset first to validate whether the row falls within the time range of the query. If not, advance to the next offset and try again.

1. For rows that fall within the time bound, scan the value at that offset for each column used as an input or output, emitting output values into the reconstructed row where the input filters match. Increment all offsets for all open column files to the next row once the row is processed. Individual rows can be processed and then discarded, minimizing the amount of data held in RAM to just a single value rather than the entire file for the column’s values in the segment.

Note that an implicit `GROUP` is performed on `timestamp` where there’s the need for subwindows within the original time range (e.g., reporting 24 five-minute windows for the past two hours of data).

1. Aggregate within the segment. For each `GROUP`, merge `SELECT`ed values from step 3. For instance, `COUNT` simply collects the number of matching rows for each `GROUP` value, while `SUM(example)` might add all identified values for a column `example` for each `GROUP` value. After each segment is analyzed, its file handle can be unloaded.

1. Aggregate across segments by sending results to a single worker for each `GROUP`. Merge the aggregated values for each `GROUP` for each segment, and aggregate them into a single value (or set of values per time granularity bucket) for the time range.

1. Sort the groups and pick the top *K* groups to include in the graph. A default value of *K* should be used to avoid transmitting thousands of matching groups as a complete result set, unless the user requests it.

We can work through here in pseudocode, calculating `SUM`, `COUNT`, `AVG`, `MAX`, etc. based on keeping a cumulative sum or highest value seen to date—for instance, on the value of the field `x` grouped by fields `a` and `b`, where `y` is greater than zero:

```
groups := make(map[Key]Aggregation)
for _, s := range segments {
  for _, row := range fieldSubset(s, []string{"a", "b", "x", "y"}))
    if row["y"] > 0 {
      continue
    }
    Key := Key{A: row["a"], B: row["b"]}
    aggr := groups[Key]
    aggr.Count++
    aggr.Sum += row["x"]
    if aggr.Max < row["x"] {
      aggr.Max = row["x"]
    }
    groups[Key] = aggr
  }
}
for k := range groups {
  groups[k].Avg = groups[k].Sum / groups[k].Count
}
```

For production use, this code would need to be generalized to support encoding arbitrarily many groups, arbitrary filters, and computing aggregations across multiple values, but it gives an idea as to how to compute aggregations in an efficiently parallelizable way. Algorithms such as quantile estimation with [t-digest](https://arxiv.org/abs/1902.04023) and [HyperLogLog](https://hal.archives-ouvertes.fr/hal-00406166) are required for calculating more complex aggregations such as p99 (for the 99th percentile of a set of numerical values) and `COUNT DISTINCT` (for the number of unique values in a column). You can further explore these sophisticated algorithms by referring to the academic literature.

In this fashion, you are able to performantly solve the problems of high cardinality and high dimensionality. No dimension (aside from timestamp) is privileged over any other dimension. It is possible to filter by an arbitrarily complex combination of one or more fields, because the filter is processed ad hoc at read time across all relevant data. Only the relevant columns are read for the filter and processing steps, and only the relevant values corresponding to a matching row ID are plucked out of each column’s data stream for emitting values.

There is no need for pre-aggregation or artificial limits on the complexity of data. Any field on any trace span can be queried. A finite cost is associated with ingesting and unpacking each record into constituent columns at write time, and the computational cost of reading remains reasonable.

## Querying for Traces

Retrieving traces is a specific, degenerate kind of query against this columnar store. To look for root spans, you query for spans `WHERE trace.parent_id` is `null`. And looking for all spans with a given `trace_id` to assemble a trace waterfall is a query for `SELECT timestamp, duration, name, trace.parent_id, trace.span_id WHERE trace.trace_id = "guid"`.

With the column storage design, it is possible to get insights on traces and to decompose traces into individual spans that can be queried across multiple traces. This design makes it feasible for Retriever to query for the duration of a span relative to other similar spans in other traces.

In other solutions that are more limited in cardinality, `trace.trace_id` might be special-cased and used as an index/lookup, with all spans associated with a given trace stored together. While this does give higher performance for visualizing individual traces, and creates a special case path to avoid the cardinality explosion of every `trace_id` being unique, it suffers in terms of inflexibility to decompose traces into their constituent spans for analysis.

## Querying Data in Real Time

As established in functional requirements for observability, data must be accessible in real time. Stale data can cause operators to waste time on red herrings, or make false conclusions about the current state of their systems. Because a good observability system should include not just historical data but also blend in fresh-off-the-presses data, you cannot wait for segments to be finalized, flushed, and compressed before making them eligible for querying.

In the implementation of Retriever, we ensure that open column files are always queryable and that the query process can force a flush of partial files for reading, even if they have not yet been finalized and compressed. In a different implementation, another possible solution could be to allow querying data structures in RAM for segment files that have not yet been finalized and compressed. Another possible solution (with significantly higher overhead) could be to forcibly flush data every few seconds, regardless of the amount of data that has arrived. This last solution could be the most problematic at scale.

The first solution allows for separation of concerns between the ingestion and query processes. The query processor can operate entirely via files on disk. The ingestion process can focus only on creating the files on disk without having to also maintain shared state. We found this to be an elegant approach appropriate to the needs of our Retriever.

## Making It Affordable with Tiering

Depending on the volume of data managed, using different tiers of data storage can result in pretty significant cost savings. Not all data is queried equally often. Typically, observability workflows are biased toward querying newer data, especially in the case of incident investigation. As you’ve seen, data must be available for querying within seconds of ingestion.

The most recent minutes of data may need to live on the local SSD of a query node while it is being serialized. But older data can and should be offloaded to a more economical and elastic data store. In the implementation of Retriever, closed segment directories older than a certain age are compacted (e.g., by rewriting with a bitmask of present/absent entries and/or being compressed) and uploaded to a longer-term durable network file store. Retriever uses Amazon S3, but you could use a different solution like Google Cloud Storage. Later, when that older data is needed again for querying, it can be fetched back from S3 into memory of the process doing computation, unpacked in memory if it was a collection of sparse files, and the column scan performed upon each matching column and segment.

## Making It Fast with Parallelism

Speed is another functional requirement for observability workflows: query results must return within seconds to drive iterative investigation. And this should hold true regardless of whether queries are retrieving 30 minutes of data or an entire week of data. Users must often compare current state to historical baselines to have an accurate idea of whether behavior is anomalous.

When performing queries against data in a cloud file storage system in a map-reduce-style pattern with serverless computation, we have found that performance can be faster than executing that same query against serial data in local SSDs with a single query engine worker. What matters to end users is the speed at which query results return, not where the data is stored.

Fortunately, using the approaches seen in earlier sections, you can independently compute the result of a query for each segment. There’s no need to process segments serially, as long as a reduction step takes the output of the query for each segment and merges the results together.

If you have already tiered data onto a durable network file store—S3 in our case—there is no contention upon a single query worker holding the bytes on disk. Your cloud provider has already taken on the burden of storing files in a distributed manner that is unlikely to have single points of congestion.

Therefore, a combination of a [mapper-reducer-style approach](https://oreil.ly/ivNPL) and serverless technology enables us to get distributed, parallelized, and fast query results for Retriever without having to write our own job management system. Our cloud provider manages a pool of serverless workers, and we simply need to provide a list of inputs to map. Each Lambda (or serverless) function is a mapper that processes one or more segment directories independently, and feeds its results through a collection of intermediate merges to a central reduce worker to compute the final results.

But serverless functions and cloud object storage aren’t 100% reliable. In practice, the latency at the tails of the distribution of invocation time can be significant orders of magnitude higher than the median time. That last 5% to 10% of results may take tens of seconds to return, or may *never* complete. In the Retriever implementation, we use impatience to return results in a timely manner. Once 90% of the requests to process segments have completed, the remaining 10% are re-requested, without canceling the still-pending requests. The parallel attempts race each other, with whichever returns first being used to populate the query result. Even if it is 10% more expensive to always retry the slowest 10% of subqueries, a different read attempt against the cloud provider’s backend will likely perform faster than a “stuck” query blocked on S3, or network I/O that may never finish before it times out.

For Retriever, we’ve figured out this method to mitigate blocked distributed performance so that we always return query results within seconds. For your own implementation, you will need to experiment with alternative methods in order to meet the need of observability workloads.

## Dealing with High Cardinality

What happens if someone attempts to group results by a high-cardinality field? How can you still return accurate values without running out of memory? The simplest solution is to fan out the reduce step by assigning reduce workers to handle only a proportional subset of the possible groups. For instance, you could follow the pattern [Chord does](https://doi.org/10.1145/964723.383071) by creating a hash of the group and looking up the hash correspondence in a ring covering the keyspace.

But in the worst case of hundreds of thousands of distinct groups, you may need to limit the number of returned groups by the total amount of memory available across all your reducers, estimate which groups are most likely to survive the `ORDER BY`/`LIMIT` criterion supplied by the user, or simply abort a query that returns too many groups. After all, a graph that is 2,000 pixels tall will not be very useful with a hundred thousand unique lines smudged into a blur across it!

## Scaling and Durability Strategies

For small volumes of data, querying a single small-throughput data stream across arbitrarily long time windows is more easily achievable. But larger data sets require scaling out horizontally, and they must be kept durable against data loss or temporary node unavailability. Fundamental limits exist on how fast any one worker, no matter how powerful, can process incoming trace spans and wide events. And your system must be able to tolerate individual workers being restarted (e.g., either for hardware failure or maintenance reasons).

In the Retriever implementation, we use streaming data patterns for scalability and durability. We’ve opted not to reinvent the wheel and leverage existing solutions where they make sense. Apache Kafka has a streaming approach that enables us to keep an ordered and durable data buffer that is resilient to producers restarting, consumers restarting, or intermediary brokers restarting.

###### Note

See [Kafka: The Definitive Guide](https://www.oreilly.com/library/view/kafka-the-definitive/9781492043072) by Gwen Shapira et al. (O’Reilly) for more information on Kafka.

For example, a row stored at index 1234567 in a given topic and partition will always precede the row stored at index 1234568 in Kafka. That means two consumers that must read data starting at index 1234567 will always receive the same records in the same order. And two producers will never conflict over the same index—each producer’s committed rows will be written in a fixed order.

When receiving incoming telemetry, you should use a lightweight, stateless receiver process to validate the incoming rows and produce each row to one selected Kafka topic and partition. Stateful indexing workers then can consume the data in order from each Kafka partition. By separating the concerns of receipt and serialization, you’ll be able to restart receiver workers or storage workers at will without dropping or corrupting data. The Kafka cluster needs to retain data only as long as the maximum duration that would be needed for replay in a disaster-recovery scenario—hours to days, but not weeks.

To ensure scalability, you should create as many Kafka partitions as necessary for your write workload. Each partition produces its own set of segments for each set of data. When querying, it is necessary to query all matching segments (based on time and data set) regardless of which partition produced them, since a given incoming trace span could have gone through any eligible partition. Maintaining a list of which partitions are eligible destinations for each tenant data set will enable you to query only the relevant workers; however, you will need to combine the results from workers performing the query on different partitions by performing a final result-merging step on a leader node for each query.

To ensure redundancy, more than one ingestion worker can consume from any given Kafka partition. Since Kafka ensures consistent ordering and the ingestion process is deterministic, parallel ingestion workers consuming a single partition must produce identical output in the form of serialized segment files and directories. Therefore, you can select one ingestion worker from each set of consumers to upload finalized segments to S3 (and spot-check that the output is identical on its peer).

If a given ingestion worker process needs to be restarted, it can checkpoint its current Kafka partition index and resume serializing segment files from that point once it is restarted. If an ingestion node needs to be entirely replaced, it can be started with a data snapshot and Kafka offset taken from an earlier healthy node and replay forward from that point.

In Retriever, we’ve separated the concerns of ingesting and serializing data from those of querying data. If you split the observability data workloads into separate processes that share only the filesystem, they no longer need to maintain shared data structures in RAM and can have greater fault tolerance. That means whenever you encounter a problem with the serialization process, it can only delay ingestion, rather than prevent querying of older data. This has the added benefit of also meaning that a spike in queries against the query engine will not hold up ingestion and serialization of data.

In this fashion, you can create a horizontally scalable version of the column storage system that allows for fast and durable querying across arbitrary cardinality and dimensionality. As of November 2021, Retriever operates as a multitenant cluster consisting of approximately 1,000 vCPU of receiver workers, 100 vCPU of Kafka brokers, and 1,000 vCPU of Retriever ingest + query engine workers, plus 30,000 peak concurrent Lambda executions. This cluster serves queries against approximately 700 TB of columnar data in 500 million compressed segment archives spanning two months of historical data. It ingests over 1.5 million trace spans per second with a maximum lag of milliseconds until they are queryable. It does this while delivering tens of read queries per second with a median latency of 50 ms and a p99 of 5 seconds.[5](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch16.html#idm45204353243888)

## Notes on Building Your Own Efficient Data Store

Observability workloads require a unique set of performance characteristics to ingest telemetry data and make it queryable in useful ways throughout the course of investigating any particular issue. A challenge for any organization seeking to build its own observability solution will be to set up an appropriate data abstraction that enables the type of iterative investigative work for open-ended exploration, to identify any possible problem. You must address the functional requirements necessary for observability in order to use your telemetry data to solve hard problems.

If your problems are too hard to solve, you probably have the [wrong data abstraction](https://sandimetz.com/blog/2016/1/20/the-wrong-abstraction). Building on the correct data abstraction allows for making the best trade-offs for solving a given data domain. For the problem of observability and tracing, a distributed hybrid columnar store segmented by time is one approach that meets all of the critical requirements of speed, cost, and reliability. While previous generation data stores struggle to meet the demands of arbitrary cardinality and dimensionality and of tracing, the Retriever data store at Honeycomb exemplifies one approach that can solve the problem.

We hope the lessons we have learned serve you well in understanding the underlying architecture of a modern observability backend, or in solving your own observability problems should you need an in-house solution. We also urge you to not suffer through the headaches of maintaining an Elasticsearch or Cassandra cluster that is not as suitable for this purpose as a dedicated column store.

# Conclusion

Numerous challenges exist when it comes to effectively storing and performantly retrieving your observability data in ways that support real-time debugging workflows. The functional requirements for observability necessitate queries that return results as quickly as possible, which is no small feat when you have billions of rows of ultrawide events, each containing thousands of dimensions, all of which must be searchable, many of which may be high-cardinality data, and when none of those fields are indexed or have privileged data retrieval over others. You must be able to get results within seconds, and traditional storage systems are simply not up to performing this task. In addition to being performant, your data store must also be fault-tolerant and production worthy.

We hope that the case study of Honeycomb’s Retriever implementation helps you better understand the various trade-offs that must be made at the data layer and possible solutions for managing them. Retriever is not the only way to implement solutions to these challenges, but it does present a thorough example of how they can be addressed. Other publicly available data stores we’re aware of that could properly handle an observability workload include Google Cloud BigQuery, ClickHouse, and Druid. However, these data stores are less operationally tested for observability-specific workloads and may require custom work to support the automated sharding required. At scale, the challenges inherent to managing observability become especially pronounced. For smaller, single-node storage solutions, you may be less likely to struggle with some of the trade-offs outlined.

Now that we’ve looked at how very large volumes of telemetry data are stored and retrieved, the next chapter examines how the network transmission of very large volumes of telemetry data can be managed via telemetry pipelines.

[1](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch16.html#ch01fn12-marker) Lior Abraham et al., [“Scuba: Diving into Data at Facebook”](https://oreil.ly/j2OZy), Proceedings of the VLDB Endowment 6.11 (2013): 1057–1067.

[2](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch16.html#ch01fn13-marker) Google, [“Schema Design Best Practices”](https://oreil.ly/8cFn6), Google Cloud Bigtable website.

[3](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch16.html#ch01fn14-marker) Benjamin H. Sigelman et al., “Dapper, a Large-Scale Distributed Systems Tracing Infrastructure,” Google Technical Report (April 2010).

[4](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch16.html#ch01fn15-marker) Terry Welch et. al., “A Technique for High-Performance Data Compression,” *Computer* 17, no. 6 (1984): 8–19.

[5](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch16.html#idm45204353243888-marker) This may not seem impressive, until you realize routine queries scan hundreds of millions of records!
