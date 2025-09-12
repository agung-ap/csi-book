# Chapter 1. What Is Observability?

In the software development industry, the subject of observability has garnered a lot of interest and is frequently found in lists of hot new topics. But, as things seem to inevitably go when a hot new topic sees a surging level of interest in adoption, complex ideas become all too ripe for misunderstanding without a deeper look at the many nuances encapsulated by a simple topical label. This chapter looks at the mathematical origins of the term “observability” and examines how software development practitioners adapted it to describe characteristics of production software systems.

We also look at why the adaptation of observability for use in production software systems is necessary. Traditional practices for debugging the internal state of software applications were designed for legacy systems that were much simpler than those we typically manage today. As systems architecture, infrastructure platforms, and user expectations have continued to evolve, the tools we use to reason about those components have not. By and large, the debugging practices developed decades ago with nascent monitoring tools are still the same as those used by many engineering teams today—even though the systems they manage are infinitely more complex. Observability tools were born out of sheer necessity, when traditional tools and debugging methods simply were not up to the task of quickly finding deeply hidden and elusive problems.

This chapter will help you understand what “observability” means, how to determine if a software system is observable, why observability is necessary, and how observability is used to find problems in ways that are not possible with other approaches.

# The Mathematical Definition of Observability

The term “observability” was coined by engineer Rudolf E. Kálmán in 1960. It has since grown to mean many different things in different communities. Let’s explore the landscape before turning to our own definition for modern software systems.

In his 1960 paper, Kálmán introduced a characterization he called *observability* to describe mathematical control systems.[1](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch01.html#ch01fn1) In [control theory](https://w.wiki/4wHw), observability is defined as a measure of how well internal states of a [system](https://w.wiki/55Pc) can be inferred from knowledge of its external outputs.

This definition of observability would have you study observability and controllability as mathematical duals, along with sensors, linear algebra equations, and formal methods. This traditional definition of observability is the realm of mechanical engineers and those who manage physical systems with a specific end state in mind.

If you are looking for a mathematical and process engineering oriented textbook, you’ve come to the wrong place. Those books definitely exist, and any mechanical engineer or control systems engineer will inform you (usually passionately and at great length) that observability has a formal meaning in traditional systems engineering terminology. However, when that same concept is adapted for use with squishier virtual software systems, it opens up a radically different way of interacting with and understanding the code you write.

# Applying Observability to Software Systems

Kálmán’s definition of observability can be applied to modern software systems. When adapting the concept of observability to software, we must also layer additional considerations that are specific to the software engineering domain. For a software application to have observability, you must be able to do the following:

-

Understand the inner workings of your application

-

Understand any system state your application may have gotten itself into, even new ones you have never seen before and couldn’t have predicted

-

Understand the inner workings and system state solely by observing and interrogating with external tools

-

Understand the internal state *without* shipping any new custom code to handle it (because that implies you needed prior knowledge to explain it)

A good litmus test for determining whether those conditions are true is to ask yourself the following questions:

-

Can you continually answer open-ended questions about the inner workings of your applications to explain any anomalies, without hitting investigative dead ends (i.e., the issue might be in a certain group of things, but you can’t break it down any further to confirm)?

-

Can you understand what any particular user of your software may be experiencing at any given time?

-

Can you quickly see any cross-section of system performance you care about, from top-level aggregate views, down to the single and exact user requests that may be contributing to any slowness (and anywhere in between)?

-

Can you compare any arbitrary groups of user requests in ways that let you correctly identify which attributes are commonly shared by all users who are experiencing unexpected behavior in your application?

-

Once you do find suspicious attributes within one individual user request, can you search across all user requests to identify similar behavioral patterns to confirm or rule out your suspicions?

-

Can you identify which system user is generating the most load (and therefore slowing application performance the most), as well as the 2nd, 3rd, or 100th most load-generating users?

-

Can you identify which of those most-load-generating users only recently started impacting performance?

-

If the 142nd slowest user complained about performance speed, can you isolate their requests to understand why exactly things are slow for that specific user?

-

If users complain about timeouts happening, but your graphs show that the 99th, 99.9th, even 99.99th percentile requests are fast, can you find the hidden timeouts?

-

Can you answer questions like the preceding ones without first needing to predict that you might need to ask them someday (and therefore set up specific monitors in advance to aggregate the necessary data)?

-

Can you answer questions like these about your applications even if you have never seen or debugged this particular issue before?

-

Can you get answers to questions like the preceding ones quickly, so that you can iteratively ask a new question, and another, and another, until you get to the correct source of issues, without losing your train of thought (which typically means getting answers within seconds instead of minutes)?

-

Can you answer questions like the preceding ones even if that particular issue has never happened before?

-

Do the results of your debugging investigations often surprise you by revealing new, perplexing, and bizarre findings, or do you generally find only the issues you suspected that you might find?

-

Can you quickly (within minutes) isolate any fault in your system, no matter how complex, deeply buried, or hidden within your stack?

Meeting all of the preceding criteria is a high bar for many software engineering organizations to clear. If you can clear that bar, you, no doubt, understand why observability has become such a popular topic for software engineering teams.

Put simply, our definition of “observability” for software systems is a measure of how well you can understand and explain any state your system can get into, no matter how novel or bizarre. You must be able to comparatively debug that bizarre or novel state across all dimensions of system state data, and combinations of dimensions, in an ad hoc iterative investigation, without being required to define or predict those debugging needs in advance. If you can understand any bizarre or novel state *without needing to ship new code*, you have observability.

We believe that adapting the traditional concept of observability for software systems in this way is a unique approach with additional nuances worth exploring. For modern software systems, observability is not about the data types or inputs, nor is it about mathematical equations. It is about how people interact with and try to understand their complex systems. Therefore, observability requires recognizing the interaction between both people and technology to understand how those complex systems work together.

If you accept that definition, many additional questions emerge that demand answers:

-

How does one gather that data and assemble it for inspection?

-

What are the technical requirements for processing that data?

-

What team capabilities are necessary to benefit from that data?

We will get to these questions and more throughout the course of this book. For now, let’s put some additional context behind observability as it applies to software.

The application of observability to software systems has much in common with its control theory roots. However, it is far less mathematical and much more practical. In part, that’s because software engineering is a much younger and more rapidly evolving discipline than its more mature mechanical engineering predecessor. Production software systems are much less subject to formal proofs. That lack of rigor is, in part, a betrayal from the scars we, as an industry, have earned through operating the software code we write in production.

As engineers attempting to understand how to bridge the gap between theoretical practices encoded in clinical tests and the impacts of what happens when our code runs at scale, we did not go looking for a new term, definition, or functionality to describe how we got there. It was the circumstances of managing our systems and teams that led us to evolving our practices away from concepts, like monitoring, that simply no longer worked. As an industry, we need to move beyond the current gaps in tooling and terminology to get past the pain and suffering inflicted upon us by outages and a lack of more proactive solutions.

Observability is the solution to that gap. Our complex production software systems are a mess for a variety of both technical and social reasons. So it will take both social and technical solutions to dig us out of this hole. Observability alone is not the entire solution to all of our software engineering problems. But it does help you clearly see what’s happening in all the obscure corners of your software, where you are otherwise typically stumbling around in the dark and trying to understand things.

Imagine you wake up one Saturday morning with grand plans to make brunch for the entire extended family. You have multiple dishes in mind, including a complex recipe for cheese souffle, a list of everyone’s known allergens and food sensitivities, and a tight timeline—Grandma has to make it to the airport by noon. This is a nontrivial challenge on its own. Now imagine you can’t find your glasses (and that you’re as near-sighted as we are). When it comes to solving practical and time-sensitive problems in software engineering, observability is a darn good place to start.

# Mischaracterizations About Observability for Software

Before proceeding, we need to address another definition of “observability,” the definition popularly being promoted by software-as-a-service (SaaS) developer tool vendors. These vendors insist that “observability” has no special meaning whatsoever—that it is simply another synonym for “telemetry,” indistinguishable from “monitoring.” Proponents of this definition relegate observability to being another generic term for understanding how software operates. You will hear this contingent explain away observability as “three pillars” of things they can sell you that they already do today: metrics, logs, and traces.[2](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch01.html#ch01fn2)

It is hard to decide which is worse about this definition: its redundancy (why exactly do we need another synonym for “telemetry”?) or its epistemic confusion (why assemble a list of one data type, one anti-data type slash mess of strings, and one…way of visualizing things in order by time?). Regardless, the logical flaw of this definition becomes clear when you realize its proponents have a vested interest in selling you the tools and mindsets built around the siloed collection and storage of data with their existing suite of metrics, logging, and tracing tools. The proponents of this definition let their business models constrain how they think about future possibilities.

In fairness, we—the authors of this book—are also vendors in the observability space. However, this book is not created to sell you on our tools. We have written this book to explain how and why we adapted the original concept of observability to managing modern software systems. You can apply the concepts in this book, regardless of your tool choices, to practice building production software systems with observability. Observability is not achieved by gluing together disparate tools with marketing. You don’t have to adopt one specific tool to get observability in your software systems. *Rather, we believe that observability requires evolving the way we think about gathering the data needed to debug effectively.* We believe that, as an industry, it is time to evolve the practices we use to manage modern software systems.

# Why Observability Matters Now

Now that we’re on the same page about what observability does and doesn’t mean in the context of modern software systems, let’s talk about why this shift in approach matters now. In short, the traditional approach of using metrics and monitoring of software to understand what it’s doing falls drastically short. This approach is fundamentally reactive. It may have served the industry well in the past, but modern systems demand a better methodology.

For the past two or three decades, the space between hardware and its human operators has been regulated by a set of tools and conventions most call “monitoring.” Practitioners have, by and large, inherited this set of tools and conventions and accepted it as the best approach for understanding that squishy virtual space between the physical and their code. And they have accepted this approach despite the knowledge that, in many cases, its inherent limitations have taken them hostage late into many sleepless nights of troubleshooting. Yet, they still grant it feelings of trust, and maybe even affection, because that captor is the best they have.

With monitoring, software developers can’t fully see their systems. They squint at the systems. They try, in vain, to size them up and to predict all the myriad ways they could possibly fail. Then they watch—they monitor—for those known failure modes. They set performance thresholds and arbitrarily pronounce them “good” or “bad.” They deploy a small robot army to check and recheck those thresholds on their behalf. They collect their findings into dashboards. They then organize themselves around those robots into teams, rotations, and escalations. When those robots tell them performance is bad, they alert themselves. Then, over time, they tend to those arbitrary thresholds like gardeners: pruning, tweaking, and fussing over the noisy signals they grow.

## Is This Really the Best Way?

For decades, that’s how developers and operators have done it. Monitoring has been the de facto approach for so long that they tend to think of it as *the only way* of understanding their systems, instead of just *one way*. Monitoring is such a default practice that it has become mostly invisible. As an industry, we generally don’t question whether *we should* do it, but *how*.

The practice of monitoring is grounded in many  unspoken assumptions about systems (which we’ll detail next). But as systems continue to evolve—as they become more abstract and more complex, and as their underlying components begin to matter less and less—those assumptions become less true. As developers and operators continue to adopt modern approaches to deploying software systems (SaaS dependencies, container orchestration platforms, distributed systems, etc.), the cracks in those assumptions become more evident.

More people, therefore, are finding themselves slamming into the wall of inherent limitations and realizing that monitoring approaches simply do not work for the new modern world. Traditional monitoring practices are catastrophically ineffective for understanding systems. The assumptions of metrics and monitoring are now falling short. To understand why they fail, it helps to examine their history and intended context.

## Why Are Metrics and Monitoring Not Enough?

In 1988, by way of the Simple Network Management Protocol (SNMPv1 as defined in RFC 1157), the foundational substrate of monitoring was born: the metric. A *metric* is a single number, with tags optionally appended for grouping and searching those numbers. Metrics are, by their very nature, disposable and cheap. They have a predictable storage footprint. They’re easy to aggregate along regular time-series buckets. And, thus, the metric became the base unit for a generation or two of telemetry—the data we gather from remote endpoints for automatic transmission to monitoring systems.

Many sophisticated apparatuses have been built atop the metric: time-series databases (TSDBs), statistical analyses, graphing libraries, fancy dashboards, on-call rotations, ops teams, escalation policies, and a plethora of ways to digest and respond to what that small army of robots is telling you.

But an upper bound exists to the complexity of the systems you can understand with metrics and monitoring tools. And once you cross that boundary, the change is abrupt. What worked well enough last month simply does not work anymore. You begin falling back to low-level commands like `strace`, `tcpdump`, and hundreds of `print` statements to answer questions about how your system is behaving on a daily basis.

It’s hard to calculate exactly when that tipping point will be reached. Eventually, the sheer number of possible states the system could get itself into will outstrip your team’s ability to pattern-match based on prior outages. Too many brand-new, novel states are needing to be understood constantly. Your team can no longer guess which dashboards should be created to display the innumerable failure modes.

Monitoring and metrics-based tools were built with certain assumptions about your architecture and organization, assumptions that served in practice as a cap on complexity. These assumptions are usually invisible until you exceed them, at which point they cease to be hidden and become the bane of your ability to understand what’s happening. Some of these assumptions might be as follows:

-

Your application is a monolith.

-

There is one stateful data store (“the database”), which you run.

-

Many low-level system metrics are available (e.g., resident memory, CPU load average).

-

The application runs on containers, virtual machines (VMs), or bare metal, which you control.

-

System metrics and instrumentation metrics are the primary source of information for debugging code.

-

You have a fairly static and long-running set of nodes, containers, or hosts to monitor.

-

Engineers examine systems for problems only after problems occur.

-

Dashboards and telemetry exist to serve the needs of operations engineers.

-

Monitoring examines “black-box” applications in much the same way as local applications.

-

The focus of monitoring is uptime and failure prevention.

-

Examination of correlation occurs across a limited (or small) number of dimensions.

When compared to the reality of modern systems, it becomes clear that traditional monitoring approaches fall short in several ways. The reality of modern systems is as follows:

-

Your application has many services.

-

There is polyglot persistence (i.e., many databases and storage systems).

-

Infrastructure is extremely dynamic, with capacity flicking in and out of existence elastically.

-

Many far-flung and loosely coupled services are managed, many of which are not directly under your control.

-

Engineers actively check to see how changes to production code behave, in order to catch tiny issues early, before they create user impact.

-

Automatic instrumentation is insufficient for understanding what is happening in complex systems.

-

Software engineers own their own code in production and are incentivized to proactively instrument their code and inspect the performance of new changes as they’re deployed.

-

The focus of reliability is on how to tolerate constant and continuous degradation, while building resiliency to user-impacting failures by utilizing constructs like error budget, quality of service, and user experience.

-

Examination of correlation occurs across a virtually unlimited number of dimensions.

The last point is important, because it describes the breakdown that occurs between the limits of correlated knowledge that one human can be reasonably expected to think about and the reality of modern system architectures. So many possible dimensions are involved in discovering the underlying correlations behind performance issues that no human brain, and in fact no schema, can possibly contain them.

With observability, comparing high-dimensionality and high-cardinality data becomes a critical component of being able to discover otherwise hidden issues buried in complex system architectures.

# Debugging with Metrics Versus Observability

Beyond that tipping point of system complexity, it’s no longer possible to fit a model of the system into your mental cache. By the time you try to reason your way through its various components, your mental model is already likely to be out-of-date.

As an engineer, you are probably used to debugging via intuition. To get to the source of a problem, you likely feel your way along a hunch or use a fleeting reminder of an outage long past to guide your investigation. However, the skills that served you well in the past are no longer applicable in this world. The intuitive approach works only as long as most of the problems you encounter are variations of the same few predictable themes you’ve encountered in the past.[3](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch01.html#ch01fn3)

Similarly, the metrics-based approach of monitoring relies on having encountered known failure modes in the past. Monitoring helps detect when systems are over or under predictable thresholds that someone has previously deemed an anomaly. But what happens when you *don’t know that type of anomaly is even possible*?

Historically, the majority of problems that software engineers encounter have been variants of somewhat predictable failure modes. Perhaps it wasn’t known that your software could fail in quite the manner that it did, but if you reasoned about the situation and its components, discovering a novel bug or failure mode didn’t require a logical leap. Most software developers rarely encounter truly unpredictable leaps of logic because they haven’t typically had to deal with the type of complexity that makes those leaps commonplace (until now, most of the complexity for developers has been bundled up inside the monolithic app).

Every application has an inherent amount of irreducible complexity. The only question is: who will have to deal with it—the user, the application developer, or the platform developer?

Larry Tesler

Modern distributed systems architectures notoriously fail in novel ways that no one is able to predict and that no one has experienced before. This condition happens often enough that an entire set of assertions has been coined about the [false assumptions](https://w.wiki/56wa) that programmers new to distributed computing often make. Modern distributed systems are also made accessible to application developers as *abstracted infrastructure platforms*. As users of those platforms, application developers are now left to deal with an inherent amount of irreducible complexity that has landed squarely on their plates.

The previously submerged complexity of application code subroutines that interacted with one another inside the hidden random access memory internals of one physical machine have now surfaced as service requests between hosts. That newly exposed complexity then hops across multiple services, traversing an unpredictable network many times over the course of a single function. When modern architectures started to favor decomposing monoliths into microservices, software engineers lost the ability to step through their code with traditional debuggers. Meanwhile, their tools have yet to come to grips with that seismic shift.

In short: we blew up the monolith. Now every request has to hop the network multiple times, and every software developer needs to be better versed in systems and operations just to get their daily work done.

Examples of this seismic shift can be seen with the trend toward containerization, the rise of container orchestration platforms, the shift to microservices, the common use of polyglot persistence, the introduction of the service mesh, the popularity of ephemeral autoscaling instances, serverless computing, lambda functions, and any other myriad SaaS applications in a software developer’s typical tool set. Stringing these various tools together into a modern system architecture means that a request may perform 20 to 30 hops after it reaches the edge of things you control (and likely multiply that by a factor of two if the request includes database queries).

In modern cloud native systems, the hardest thing about debugging is no longer understanding how the code runs but *finding where in your system* the code with the problem even lives. Good luck looking at a dashboard or a service map to see which node or service is slow, because distributed requests in these systems often loop back on themselves. Finding performance bottlenecks in these systems is incredibly challenging. When something gets slow, *everything gets slow*. Even more challenging, because cloud native systems typically operate as platforms, the code may live in a part of the system that this team doesn’t even control.

In a modern world, debugging with metrics requires you to connect dozens of disconnected metrics that were recorded over the course of executing any one particular request, across any number of services or machines, to infer what might have occurred over the various hops needed for its fulfillment. The helpfulness of those dozens of clues depends entirely upon whether someone was able to predict, in advance, if that measurement was over or under the threshold that meant this action contributed to creating a previously unknown anomalous failure mode that had never been previously encountered.

By contrast, debugging with observability starts with a very different substrate: a deep context of what was happening when this action occurred. Debugging with observability is about preserving as much of the context around any given request as possible, so that you can reconstruct the environment and circumstances that triggered the bug that led to a novel failure mode. Monitoring is for the known-unknowns, but observability is for the unknown-unknowns.

## The Role of Cardinality

In the context of databases, *cardinality* refers to the uniqueness of data values contained in a set. *Low cardinality* means that a column has a lot of duplicate values in its set. *High cardinality* means that the column contains a large percentage of completely unique values. A column containing a single value will always have the lowest possible cardinality. A column containing unique IDs will always have the highest possible cardinality.

For example, in a collection of a hundred million user records, you can assume that any universally unique identifier (UUID) will have the highest possible cardinality. Another example of high cardinality might be a public-key signature. First Name and Last Name would have high cardinality, though lower than UUIDs since some names repeat. A field like Gender would have low-cardinality if the schema were written 50 years ago, but given more recent understanding of gender, perhaps no longer. A field like Species would have the lowest possible cardinality—presuming all of your users are humans.

Cardinality matters for observability, because *high-cardinality information is almost always the most useful* in identifying data for debugging or understanding a system. Consider the usefulness of sorting by fields such as user IDs, shopping cart IDs, request IDs, or any other myriad IDs like instances, container, hostname, build number, spans, and so forth. Being able to query against unique IDs is the best way to pinpoint individual needles in any given haystack. You can always downsample a high-cardinality value into something with lower cardinality (for example, bucketing last names by prefix), but you can never do the reverse.

Unfortunately, metrics-based tooling systems can deal with only low-cardinality dimensions at any reasonable scale. Even if you have only merely hundreds of hosts to compare, with metrics-based systems, you can’t use the hostname as an identifying tag without hitting the limits of your cardinality key-space.

These inherent limitations place unintended restrictions on the ways that data can be interrogated. When debugging with metrics, for every question you may want to ask of your data, you have to decide—*in advance*, before a bug occurs—what you need to inquire about so that its value can be recorded when that metric is written.

This has two big implications. First, if during the course of investigation, you decide that an additional question must be asked to discover the source of a potential problem, that cannot be done after the fact. You must first go set up the metrics that might answer that question and wait for the problem to happen again. Second, because answering that additional question requires another set of metrics, most metrics-based tooling vendors will charge you for recording that data. Your cost increases linearly with every new way you decide to interrogate your data to find hidden issues you could not have possibly predicted in advance.

## The Role of Dimensionality

While *cardinality* refers to the uniqueness of the values within your data, *dimensionality* refers to the number of keys within that data. In observable systems, telemetry data is generated as an arbitrarily wide structured event (see [Chapter 8](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch08.html#analyzing_events_to_achieve_observabili)). These events are described as “wide” because they can and should contain hundreds or even thousands of key-value pairs (or dimensions). The wider the event, the richer the context captured when the event occurred, and thus the more you can discover about what happened when debugging it later.

Imagine that you have an event schema that defines six high-cardinality dimensions per event: `time`, `app`, `host`, `user`, `endpoint`, and `status`. With those six dimensions, you can create queries that analyze any combination of dimensions to surface relevant patterns that may be contributing to anomalies. For example, you could retrieve, “all of the 502 errors that occurred in the last half hour for host `foo`,” or, “all of the 403 errors generated by requests to the `/export` endpoint made by user `bar`,” or, “all of the timeouts that occurred with requests sent to the `/payments` endpoint by application `baz` and which host they came from.”

With just six basic dimensions, you can examine a useful set of conditions to determine what might be happening in your application system. Now imagine that instead of just six dimensions, you could examine hundreds or thousands of dimensions that contain any detail, value, counter, or string that seems like it might be helpful to your debugging purposes at some point in the future. For example, you could include dimensions that look something like this:

```
app.api_key
app.batch
app.batch_num_data_sets
app.batch_total_data_points
app.dataset.id
app.dataset.name
app.dataset.partitions
app.dataset.slug
app.event_handler
app.raw_size_bytes
app.sample_rate
app.team.id
…
response.content_encoding
response.content_type
response.status_code
service_name
trace.span_id
trace.trace_id
```

With many more dimensions available, you can examine events to make highly sophisticated correlations between any group of service requests (see [Chapter 8](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch08.html#analyzing_events_to_achieve_observabili)). The more highly dimensional your data is, the more likely you will be able to find hidden or elusive patterns in application behavior. In modern systems, where the permutations of failures that can occur are effectively limitless, capturing only a few basic dimensions in your telemetry data is insufficient.

You must gather incredibly rich detail about everything happening at the intersection of users, code, and your systems. High-dimensionality data provides greater context about how those intersections unfold. In later chapters, we cover how high-dimensionality data (which often contains high-cardinality data) is analyzed in order to reveal where the issues you care about in a system are happening and why.

# Debugging with Observability

Instead of limiting the cardinality and dimensionality of telemetry data, observability tools encourage developers to gather rich telemetry for every possible event that could occur, passing along the full context of any given request and storing it for possible use at some point down the line. Observability tools are specifically designed to query against high-cardinality, high-dimensionality data.

Therefore, for debugging, you can interrogate your event data in any number of arbitrary ways. With observability, you iteratively investigate conditions you care about by exploring your data to see what it can reveal about the state of your system. You ask a question that you did not need to predict in advance to find answers or clues that will lead you to ask the next question, and the next, and the next. You repeat that pattern again and again until you find the needle in the proverbial haystack that you’re looking for. A key function of observable systems is the ability to explore your system in open-ended ways.

The explorability of a system is measured by how well you can ask any question and inspect its corresponding internal state. *Explorability* means you can iteratively investigate and eventually understand any state your system has gotten itself into—even if you have never seen that state before—without needing to predict what those states might be in advance. Again, observability means that you can understand and explain any state your system can get into—no matter how novel or bizarre—without shipping new code.

The reason monitoring worked so well for so long is that systems tended to be simple enough that engineers could reason about exactly where they might need to look for problems and how those problems might present themselves. For example, it’s relatively simple to connect the dots that when sockets fill up, CPU would overload, and the solution is to add more capacity by scaling application node instances, or by tuning your database, or so forth. Engineers could, by and large, predict the majority of possible failure states up front and discover the rest the hard way once their applications were running in production.

However, monitoring creates a fundamentally reactive approach to system management. You can catch failure conditions that you predicted and knew to check for. If you know to expect it, you check for it. For every condition you don’t know to look for, you have to see it first, deal with the unpleasant surprise, investigate it to the best of your abilities, possibly reach a dead end that requires you to see that same condition multiple times before properly diagnosing it, and then you can develop a check for it. In that model, engineers are perversely incentivized to have a strong aversion to situations that could cause unpredictable failures. This is partially why some teams are terrified of deploying new code (more on that topic later).

One subtle additional point: hardware/infrastructure problems are simple compared to the ones generated by your code or your users. The shift from “most of my problems are component failures” to “most of my questions have to do with user behavior or subtle code bugs and interactions” is why even people with monoliths and simpler architectures may pursue the shift from monitoring to observability.

# Observability Is for Modern Systems

A production software system is observable to the extent that you can understand new internal system states without having to make arbitrary guesses, predict those failure modes in advance, or ship new code to understand that state. In this way, we extend the control theory concept of observability to the field of software engineering.

In its software engineering context, observability does provide benefits for those on more traditional architectures or monolithic systems. It’s *always* helpful to be able to trace your code and see where the time is being spent, or to reproduce behavior from a user’s perspective. This capability can certainly save teams from having to discover unpredictable failure modes in production no matter what your architecture is like. But it is with modern distributed systems that the scalpel and searchlight afforded by observability tooling becomes absolutely nonnegotiable.

In distributed systems, the ratio of somewhat predictable failure modes to novel and never-before-seen failure modes is heavily weighted toward the bizarre and unpredictable. Those unpredictable failure modes happen so commonly, and repeat rarely enough, that they outpace the ability for most teams to set up appropriate and relevant enough monitoring dashboards to easily show that state to the engineering teams responsible for ensuring the continuous uptime, reliability, and acceptable performance of their production applications.

We wrote this book with these types of modern systems in mind. Any system consisting of many components that are loosely coupled, dynamic in nature, and difficult to reason about are a good fit for realizing the benefits of observability versus traditional management approaches. If you manage production software systems that fit that description, this book describes what observability can mean for you, your team, your customers, and your business. We also focus on the human factors necessary to develop a practice of observability in key areas of your engineering processes.

# Conclusion

Although the term *observability* has been defined for decades, its application to software systems is a new adaptation that brings with it several new considerations and characteristics. Compared to their simpler early counterparts, modern systems have introduced such additional complexity that failures are harder than ever to predict, detect, and troubleshoot.

To mitigate that complexity, engineering teams must now be able to constantly gather telemetry in flexible ways that allow them to debug issues without first needing to predict how failures may occur. Observability enables engineers to slice and dice that telemetry data in flexible ways that allow them to get to the root of any issues that occur in unparalleled ways.

Observability is often mischaracterized as being achieved when you have “three pillars” of different telemetry data types, so we aren’t fans of that model. However, if we must have three pillars of observability, then what they should be is tooling that supports high cardinality, high-dimensionality, and explorability. Next, we’ll examine how observability differs from the traditional systems monitoring approach.

[1](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch01.html#ch01fn1-marker) Rudolf E. Kálmán, [“On the General Theory of Control Systems”](https://oreil.ly/u7BM4), *IFAC Proceedings Volumes* 1, no. 1 (August 1960): 491–502.

[2](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch01.html#ch01fn2-marker) Sometimes these claims include time spans to signify “discrete occurrences of change” as a fourth pillar of a generic synonym for “telemetry.”

[3](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch01.html#ch01fn3-marker) For a more in-depth analysis, see Pete Hodgson’s blog post [“Why Intuitive Troubleshooting Has Stopped Working for You”](https://oreil.ly/JXx0c).
