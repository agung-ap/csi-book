# 8 [](/book/grokking-streaming-systems/chapter-8/)Join operations

### In this chapter

- correlating different types of events in real time
- when to use inner and outer joins
- applying windowed joins

“An SQL query goes into a bar, walks up to two tables, and asks, can I join you?”

—Anonymous

If you have ever used any SQL (structured query language) database, most likely you have used, or at least learned about, the *join* clause. In the streaming world, the join operation may not be as essential as it is in the database world, but it is still a very useful concept. In this chapter, we are going to learn how join works in a streaming context. We will use the join clause in databases to introduce the calculation and then talk about the details in streaming systems. If you are familiar with the clause, please feel free to skip the introduction pages.

## [](/book/grokking-streaming-systems/chapter-8/)Joining emission data on the fly

Well what do[](/book/grokking-streaming-systems/chapter-8/) you know? The chief got lucky and fell into an opportunity of tracking the emissions of cars in Silicon Valley, California. Nice, right?

Well, with every great opportunity comes challenges. The team is going to need to find a way to join events from vehicles in specific city locations along with the vehicles’ estimated emission rates on the fly. How will they do it? Let’s check it out.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/08_01.png)

## [](/book/grokking-streaming-systems/chapter-8/)The emissions job version 1

They have already implemented a first version of the emissions job. The interesting part of the job is the data store to the right of the emission resolver. It is a static lookup table used by the emission resolver to search for the emission data of each vehicle. Note that we assume that the vehicles with the same make, model, and year have the same emissions in this system[](/book/grokking-streaming-systems/chapter-8/).

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/08_02.png)

## [](/book/grokking-streaming-systems/chapter-8/)The emission resolver

The key component[](/book/grokking-streaming-systems/chapter-8/) in this[](/book/grokking-streaming-systems/chapter-8/) job is the emission resolver. It takes a vehicle event, looks up the emission data for the vehicle in the data store, and emits an emission event, which contains the zone and emission data. Note that the output emission event contains data from two sources: the incoming vehicle event and the table.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/08_03.png)

This operator can be considered a very basic *join* operator, which combines data from different data sources based on related data between them (vehicle make, model, and year). However, the emission data is from a table instead of a stream. Join operators in streaming jobs take it one step further by providing real-time data.

## [](/book/grokking-streaming-systems/chapter-8/)Accuracy becomes an issue

The job works[](/book/grokking-streaming-systems/chapter-8/) OK in general[](/book/grokking-streaming-systems/chapter-8/), and it generates real-time emission data successfully. However, one important factor in the equation is missing: temperature (you know, CO2 emission varies under different temperatures, and there are different seasons in California too). As a result, the emissions per zone reported by the system are not accurate enough. It is too late to add a temperature sensor to the devices installed on each vehicle now, so it becomes the team’s challenge to solve in a different way.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/08_04.png)

## [](/book/grokking-streaming-systems/chapter-8/)The enhanced emissions job

The team added[](/book/grokking-streaming-systems/chapter-8/) another data[](/book/grokking-streaming-systems/chapter-8/) source to bring current temperature events into the job for more accurate reporting. The temperature events are joined with the vehicle events using the zone id. The output *emission events* are then emitted to the emission resolver.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/08_05.png)

## [](/book/grokking-streaming-systems/chapter-8/)Focusing on the join

The major changes in the new version are:[](/book/grokking-streaming-systems/chapter-8/)

-  The extra data source that accepts temperature events into the job
-  The event joiner that combines two streams into one

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/08_06.png)

The temperature event source works like normal sources, which are responsible for accepting data into stream jobs. The key change is the newly added event joiner operator, which has two incoming event streams and one outgoing event stream. Events arrive in real time, and it is really rare for the events from the streams to be perfectly synchronized with each other. How should we make different types of events work together in the join operator? Let’s dig into it.

## [](/book/grokking-streaming-systems/chapter-8/)What is a join again?

It’s probably natural[](/book/grokking-streaming-systems/chapter-8/) to think[](/book/grokking-streaming-systems/chapter-8/) of SQL when someone refers to a join operator. After all, *join* is a term that comes from the relational database world.

A join is an SQL clause where you take a certain number of fields from one table and combine them with another set of fields from another table, or tables, to produce consolidated data. The diagram below shows the join operator in terms of relational databases; the streaming join is discussed in the following pages.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/08_07.png)

```
SELECT v.time, v.make, v.model, v.year, t.zone, t.temperature
FROM vehicle_events v
INNER JOIN temperature t on v.zone = t.zone;
```

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/08_08.png)

## [](/book/grokking-streaming-systems/chapter-8/)How the stream join works

How can we[](/book/grokking-streaming-systems/chapter-8/) make joins[](/book/grokking-streaming-systems/chapter-8/) on data that is constantly moving and being updated? The key is to convert the temperature events into a table.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/08_09.png)

## [](/book/grokking-streaming-systems/chapter-8/)Stream join is a different kind of fan-in

In chapter 4, we[](/book/grokking-streaming-systems/chapter-8/) discussed[](/book/grokking-streaming-systems/chapter-8/) the fraud[](/book/grokking-streaming-systems/chapter-8/) detection scenario where we aggregated the fraud scores from the upstream analyzers to help determine whether a transaction was fraudulent or not. Is the score aggregator the same type of operator?

The answer is no. In the score aggregator, all the incoming streams have the same event type. The operator doesn’t need to know which stream each event is from, and it just applies the same logic. In the event joiner, the events in the two incoming streams are quite different and handled differently in the operator. The score aggregator is a merge operator, and the event joiner is a join operator. They are both *fan-in* operators.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/08_10.png)

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/08_11.png)

## [](/book/grokking-streaming-systems/chapter-8/)Vehicle events vs. temperature events

Note that in[](/book/grokking-streaming-systems/chapter-8/) the join[](/book/grokking-streaming-systems/chapter-8/)[](/book/grokking-streaming-systems/chapter-8/) operator, the[](/book/grokking-streaming-systems/chapter-8/) temperature[](/book/grokking-streaming-systems/chapter-8/) events are converted into the temporary temperature table, but the vehicle events are processed as a stream. Why convert the temperature events instead of the vehicle events? Why not convert both streams into tables? These questions can be important when you build your own systems.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/08_12.png)

First, one outgoing event is expected for each incoming vehicle event. So it makes sense to keep the vehicle events flowing through the operator like a stream. Secondly, it could be more complicated to manage vehicle events as the lookup table. There are many more vehicles than zones in the system, so it would be much more expensive to keep the vehicle events in a temporary in-memory table. Furthermore, only the latest temperature for each zone is important for us, but the vehicle event needs to managed (adding and removing) more carefully, since every event counts.

Anyway, let’s put the vehicle events into a table and then join them with the stream of temperature events. There will be multiple rows for each zone in the table, and the results will be event batches instead of individual events.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/08_13.png)

## [](/book/grokking-streaming-systems/chapter-8/)Table: A materialized view of streaming

We are going[](/book/grokking-streaming-systems/chapter-8/) to be[](/book/grokking-streaming-systems/chapter-8/) a little more abstract here: what is the relationship between the temperature events and the temperature table? Understanding their relationship could be helpful for us to understand what makes the temperature events special and make better decisions when building new streaming systems.

One important fact about temperature data is that, at any moment, we only need to keep the latest temperature for each zone. This is because we only care about the *latest* temperature of each zone instead of the individual changes or the temperature history. The diagram belows shows the changes of the temperature table before and after two temperature events are received and processed.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/08_14.png)

Each temperature event is used to update the table to the latest data. Therefore, each event can be considered a *change* of the data in the table, and the stream of the events is a *change log*.

On the other end, when a join happens, the lookup is performed on the temperature table. At any moment, the temperature table is the result after all the events up to the specific point of time have been applied. Hence, the table is considered a *materialized view* of the temperature events. An interesting effect of a materialized view is that the event interval is not that important anymore. In the example, the interval of temperature events for each zone is 10 minutes, but the system would work the same way whether the interval is one second or one hour.

## [](/book/grokking-streaming-systems/chapter-8/)Vehicle events are less efficient to be materialized

On the other hand, compared to the temperature events, the vehicle events are less efficient to be materialized. Vehicles move around the city all the time, and every single vehicle event for the same vehicle needs to be included in the join instead of the latest one. As a result, the vehicle events table is basically *a list of pending vehicle events* to be processed. Plus, the number of vehicles is likely to be much greater than the number of zones normally. In conclusion, compared to the temperature events, the vehicle events are more complicated and less efficient to be materialized[](/book/grokking-streaming-systems/chapter-8/).

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/08_15.png)

The diagram above shows the vehicle events are *appended* into the table instead of being used to update rows. While there are some things we can do to improve the efficiency, such as adding an extra `count` column and aggregating rows that have the same `make`, `model`, `year`, and `zone` instead of simply appending to the end of the table, it is quite clear that the temperature events are much more convenient to be materialized than the vehicle events. In real-world problems, this property could be an important factor to help decide how the streams should be handled if a join operator is involved.

## [](/book/grokking-streaming-systems/chapter-8/)Data integrity quickly became an issue

The emissions job[](/book/grokking-streaming-systems/chapter-8/) worked[](/book/grokking-streaming-systems/chapter-8/) great to help keep track of emissions throughout the area the team planned for. But guess what? People use applications in ways they weren’t meant to be used.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/08_16.png)

Why does this issue happen, and how we can address the issue? We will need to look into different types of join operators.

## [](/book/grokking-streaming-systems/chapter-8/)What’s the problem with this join operator?

The key to this join operator is obtaining the temperature for a given `zone`. Let’s take a look at a table-centric representation of the operator below. In the diagram, each vehicle event is represented as a row in the table, but keep in mind that the vehicle events are processed one by one like a stream. Another important thing to keep in mind is that the the temperature table is dynamic, and the temperature values could change when new temperature events come in.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/08_17.png)

Now, the data integrity issue is caused by a special case: the zone 7 in the last vehicle event is not in the temperature table. What should we do now? To answer this question, we need to discuss two new concepts first: *inner join* and *outer join*.

## [](/book/grokking-streaming-systems/chapter-8/)Inner join

Inner join processes[](/book/grokking-streaming-systems/chapter-8/) only vehicle[](/book/grokking-streaming-systems/chapter-8/) events that have matching `zone` in the temperature table.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/08_18.png)

If you look carefully at the above result of the join operator, you will see that there is no row in the result associated with `zone` `7`. This is because inner joins only return rows of data that have matching values, and there is no `zone` `7` in the temperature table.

With inner join, emission in these unknown zones will be missed, since the vehicle events are dropped. Is this a desirable behavior?

## [](/book/grokking-streaming-systems/chapter-8/)Outer join

Outer joins differ[](/book/grokking-streaming-systems/chapter-8/) from[](/book/grokking-streaming-systems/chapter-8/) inner, as they *include* the matching and non-matching rows on a specified column or data. Therefore, no event will be missing, although there could be some incomplete events in the result.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/08_19.png)

With the outer join we have a chance to handle the special case later.

The team decided to do an outer join to capture non-matching rows and handle them later.

## [](/book/grokking-streaming-systems/chapter-8/)The inner join vs. outer join

Vehicle events that[](/book/grokking-streaming-systems/chapter-8/) have no[](/book/grokking-streaming-systems/chapter-8/) matching[](/book/grokking-streaming-systems/chapter-8/) data in[](/book/grokking-streaming-systems/chapter-8/) the temperature table are handled differently with inner and outer joins. Inner joins only return results that have matching values on both sides, but outer joins return results whether or not there is matching data.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/08_20.png)

## [](/book/grokking-streaming-systems/chapter-8/)Different types of joins

If you are[](/book/grokking-streaming-systems/chapter-8/) familiar[](/book/grokking-streaming-systems/chapter-8/) with the join clause in databases, you will remember that there are a few different types of outer joins: *full outer joins* (or *full joins*), *left outer joins* (or *left joins*), and *right outer joins* (or *right joins*). All join operators are included in the diagrams that follow to illuminate the differences in the context of an SQL database.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/08_21.png)

## [](/book/grokking-streaming-systems/chapter-8/)Outer joins in streaming systems

Now we know[](/book/grokking-streaming-systems/chapter-8/) the inner[](/book/grokking-streaming-systems/chapter-8/) and outer[](/book/grokking-streaming-systems/chapter-8/) joins[](/book/grokking-streaming-systems/chapter-8/) in SQL[](/book/grokking-streaming-systems/chapter-8/) databases. Overall, things are pretty similar in the streaming world. One difference is that, in many cases (such as the CO2 emission job), events in one of the incoming streams are processed *one by one,* while the other streams are materialized into tables to be joined. Usually, the special stream is treated as the *left stream*, and the streams to be materialized are the *right streams*. Therefore, the join used in the event joiner is a left outer join

With left outer join, the team can identify the vehicles that are moving outside of the planned area and improve the data integrity issue by filling in the average temperature into the resulting vehicle-temperature events instead of dropping them. The results are more accurate now.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/08_22.png)

Note that in more complicated (hence, interesting) cases, there could be more than one *right* stream, and different types of joins can be applied to them.

## [](/book/grokking-streaming-systems/chapter-8/)A new issue: Weak connection

After fixing the[](/book/grokking-streaming-systems/chapter-8/) data integrity issue, the team noticed another problem a few weeks later: some values in the temperature table look strange. After investigating, they found the root cause: one sensor has connection issues, and sometimes it reports temperature successfully every few hours instead of every 10 minutes. The issue can be fixed by repairing the device and its connection, but at the same time, can we make the system more resilient to the connection issues?

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/08_23.png)

In general, streaming systems have to account for the possibility that some of their event sources might be unreliable.

## [](/book/grokking-streaming-systems/chapter-8/)Windowed joins

A new concept[](/book/grokking-streaming-systems/chapter-8/) can[](/book/grokking-streaming-systems/chapter-8/) be very helpful for making the job handle the unreliable connection issue: *windowed joins*. The name explains itself well: a windowed join is an operator that combines both windowing and join. In the previous chapter, we discussed windowed computation in detail. The details are not required here, so don’t worry if you picked this chapter to read first.

With windowed joins, the job works similarly to the original version: the vehicle events are handled one by one, and the temperature events are materialized into a lookup table. However, the materialization of the temperature events is based on a fixed time window instead of the continuous events. More specifically, temperature events are collected into a buffer first and materialized into an empty table as a batch every 30 minutes. If all the sensors report data successfully in the window, the calculation should work just fine. However, in case no temperature event is received from a sensor within the window, the corresponding row in the lookup table will be empty, and the event joiner can then estimate the current value from the neighbor zones. In the diagram below, the temperatures in zone 2 and 4 are used to estimate the temperature of zone 3. By using a windowed join, we can make sure all the temperature data in the table is up-to-date.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/08_24.png)

By changing from a continuous materialization to a window-based materialization, we sacrifice the latency of temperature changes a little (temperatures are updated every 30 minutes instead of 10 minutes), but in return, we get a more robust system that can detect and handle some unexpected issues automatically.

## [](/book/grokking-streaming-systems/chapter-8/)Joining two tables instead of joining a stream and table

Before wrapping up[](/book/grokking-streaming-systems/chapter-8/) the chapter, as an example, let’s take a look at the option in which both streams are converted to tables first and then the two tables are joined together using the CO2 emission monitor system. With this solution, the overall process in the component has two steps: materialization and join. First, the two incoming streams are materialized into two tables. Then, the join logic is applied on the tables, and the results are emitted out to the downstream components. Usually, windowing is used in the materialization step, and the join operation is very similar to the join clause in SQL databases. Note that a different windowing strategy can be applied to each incoming stream.

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/08_25.png)

Because the overall process is rather standard, developers can focus on the join calculation without worrying about handling streams differently. This could be an advantage when building more complicated join operators; hence, this option is important to know. On the other hand, the latency might not be ideal because the events are processed in small batches instead of continuously. Remember that it is up to the developers to choose the best option according to the requirements.

## [](/book/grokking-streaming-systems/chapter-8/)Revisiting the materialized view

We have discussed[](/book/grokking-streaming-systems/chapter-8/) that the[](/book/grokking-streaming-systems/chapter-8/) temperature[](/book/grokking-streaming-systems/chapter-8/) events are more efficient to be materialized than the vehicle events, and we have also discussed that, typically, the events in one special stream are processed one by one, and the other streams are materialized into temporary tables, but we can also materialize all streams and join the tables. I bet some curious readers will ask: can we join with the raw temperature events instead of the materialized view?

![](https://drek4537l1klr.cloudfront.net/fischerj/Figures/08_26.png)

Let’s try to keep all the temperature events as a list and avoid the temporary table. To avoid running out of memory, we will drop the temperature events that are older than 30 minutes. For each vehicle event, we need to search for the last temperature of the zone in the temperature list by comparing the zone id in the vehicle event with the zone id of each temperature in the list. The final results will be the same, but with a lookup table which could be a hash map, a binary search tree, or a simple array with the zone id as the index, the searching would be much more efficient. From the comparison, we can tell that the materialized view can be considered an *optimization*. In fact, the materialized view is a popular optimization pattern in many data processing applications.

The materialized view is a popular pattern to optimize data processing applications.

Since it is an optimization, we can be more creative about how to manage the events if there are ways to make the operator more efficient. For example, in the real world a lot more information, such as noise level and air quality, can be collected by these sensors. Because we only care about the real-time temperature in each zone in this job, we can drop all other information and only extract the temperature data from the events and put them into the temporary lookup table. In your systems, if it makes your jobs more efficient, you can also try to create multiple materialized views from a single stream or create one materialized view from multiple streams to build more efficient systems.

## [](/book/grokking-streaming-systems/chapter-8/)Summary

In this chapter, we[](/book/grokking-streaming-systems/chapter-8/) discussed[](/book/grokking-streaming-systems/chapter-8/) the other type of fan-in operator: join. Similar to merge operators, join operators have multiple incoming streams. However, instead of applying the same logic to all events from different streams, events from different streams are handled differently in join operators.

Similar to the join clause in SQL databases, there are different types of joins. Understanding the joins is important for solving the data integrity issue:

-  *Inner joins* only return results that have matching values in both tables.
-  *Outer joins* return results whether or not there is matching data in both tables. There are three types of outer joins: full outer joins (or full joins), left outer joins (or left joins), and right outer joins (or right joins).

In the CO2 emission monitoring system, the vehicle events are processed like a stream, and the temperature events are used as a lookup table. A table is a materialized view of a stream. At the end of the chapter, we also learned that windowing can be used together with join and a different option to build join operators: materializing all the incoming streams into tables and then joining them together.
