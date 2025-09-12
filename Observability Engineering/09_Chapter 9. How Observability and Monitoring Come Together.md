# Chapter 9. How Observability and Monitoring Come Together

So far in this book, we’ve examined the differentiating capabilities of observable systems, the technological components necessary for observability, and how observability fits into the technical landscape. Observability is fundamentally distinct from monitoring, and both serve different purposes. In this chapter, we examine how they fit together and the considerations for determining how both may coexist within your organization.

Many organizations have years—if not decades—of accumulated metrics data and monitoring expertise set up around their production software systems. As covered in earlier chapters, traditional monitoring approaches are adequate for traditional systems. But when managing modern systems, does that mean you should throw all that away and start fresh with observability tools? Doing that would be both cavalier and brash. The truth for most organizations is that their approach to coexisting approaches should be dictated by their adopted responsibilities.

This chapter explores how observability and monitoring come together by examining the strengths of each, the domains where they are best suited, and the ways they complement one another. Every organization is different, and a recipe for the coexistence of observability and monitoring cannot be universally prescribed. However, a useful guideline is that observability is best suited to understanding issues at the application level and that monitoring is best for understanding issues at the system level. By considering your workloads, you can figure out how the two come together best for you.

# Where Monitoring Fits

In [Chapter 2](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch02.html#how_debugging_practices_differ_between), we focused on differentiating observability and monitoring. That chapter mostly focuses on the shortcomings of monitoring systems and how observability fills in those gaps. But monitoring systems still continue to provide valuable insights. Let’s start by examining where traditional monitoring systems continue to be the right tool for the job.

The traditional monitoring approach to understanding system state is a mature and well-developed process. Decades of iterative improvement have evolved monitoring tools beyond their humble beginnings with simple metrics and round-robin databases (RRDs), toward TSDBs and elaborate tagging systems. A wealth of sophisticated options also exist to provide this service—from open source software solutions, to start-ups, to publicly traded companies.

Monitoring practices are well-known and widely understood beyond the communities of specialists that form around specific tools. Across the software industry, monitoring best practices exist that anyone who has operated software in production can likely agree upon.

For example, a widely accepted core tenet of monitoring is that a human doesn’t need to sit around watching graphs all day; the system should proactively inform its users when something is wrong. In this way, monitoring systems are reactive. They react to known failure states by alerting humans that a problem is occurring.

Monitoring systems and metrics have evolved to optimize themselves for that job. They automatically report whether known failure conditions are occurring or about to occur. They are optimized for reporting on unknown conditions about known failure modes (in other words, they are designed to detect *known-unknowns*).

The optimization of monitoring systems to find known-unknowns means that it’s a best fit for understanding the state of your systems, which change much less frequently and in more predictable ways than your application code. By *systems*, we mean your infrastructure, or your runtime, or counters that help you see when you’re about to slam up against an operating constraint.

As seen in [Chapter 1](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch01.html#what_is_observabilityquestion_mark), metrics and monitoring were created to examine hardware-level performance. Over time, they’ve been adapted to encompass a wider range of infrastructure and system-level concerns. Most readers of this book, who work in technology companies, should recognize that the underlying systems are not what matter to your business. At the end of the day, what matters to your business is how the applications you wrote perform in the hands of your customers. The only reason your business is concerned about those underlying systems is that they could negatively impact application performance.

For example, you want to know if CPU utilization is pegged on a virtual instance with a noisy neighbor because that tells you the latency you’re seeing isn’t an issue inside your code. Or if you see that physical memory is close to being exhausted across your entire fleet, that tells you an impending disaster probably originated from your code. Correlating system constraints with application performance matters, but system performance matters mostly as a warning signal or a way to rule out code-based issues.

Over time, metrics have also been adapted to creep into monitoring application-level concerns. But as you’ve seen throughout [Part I](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/part01.html#the_path_to_observability), these aggregate measures are far too coarse because they cannot be decomposed to show the performance of individual requests in your services. In the role of a warning signal, aggregate measures like metrics work well. But metrics aren’t, and never have been, a good way to indicate how the code you wrote behaves in the hands of individual users.

# Where Observability Fits

In contrast to monitoring, observability has different tenets and use cases. As seen in [Chapter 2](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch02.html#how_debugging_practices_differ_between), observability is more proactive. Its practices demand that engineers should always watch their code as it is deployed, and should spend time every day exploring their code in production, watching users use it, and looking around for outliers and curious trails to follow.

As covered in [Chapter 8](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch08.html#analyzing_events_to_achieve_observabili), the core analysis loop enables debugging from first principles and is tailored to discovering previously unknown failure modes (in other words, it is designed to detect *unknown-unknowns*). The optimization of observability to find unknown-unknowns means it’s a best fit for understanding the state of the code you write, which changes much more frequently than your systems (typically, every day) and in far less predictable ways.

Monitoring and observability tools have different best practices and different implementations, and they serve different purposes.

# System Versus Software Considerations

In more traditional settings, the distinction between systems and software was clear: bare-metal infrastructure was the system, and everything running inside that system was the software. Modern systems, and their many higher-order abstractions, have made that distinction somewhat less clear. Let’s start with some definitions.

For these purposes, *software* is the code you are actively developing that runs a production service delivering value to your customers. Software is what your business *wants* to run to solve a market problem.

*System* is an umbrella term for everything else about the underlying infrastructure and runtime that is necessary to run that service. Systems are what your business *needs* to run in order to support the software it *wants* to run. By that definition, the system (or infrastructure, as we could use the two terms interchangeably here) includes everything from databases (e.g., MySQL or MongoDB) to compute and storage (e.g., containers or virtual machines) to anything and everything else that has to be provisioned and set up before you can deploy and run your software.

The world of cloud computing has made these definitions somewhat difficult to nail down, so let’s drill down further. Let’s say that to run your software, you need to run underlying components like Apache Kafka, Postfix, HAProxy, Memcached, or even something like Jira. If you’re buying access to those components as a service, they don’t count as infrastructure for this definition; you’re essentially paying someone else to run it for you. However, if your team is responsible for installing, configuring, occasionally upgrading, and troubleshooting the performance of those components, that’s infrastructure you need to worry about.

Compared to software, everything in the system layer is a commodity that changes infrequently, is focused on a different set of users, and provides a different value. Software—the code you write for your customers to use—is a core differentiator for your business: it is the very reason your company exists today. Software, therefore, has a different set of considerations for how it should be managed. [Table 9-1](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch09.html#factors_that_vary_bet) provides a comparison.

| Factor | Your systems | Your software |
| --- | --- | --- |
| Rate of change | Package updates (monthly) | Repo commits (daily) |
| Predictability | High (stable) | Low (many new features) |
| Value to your business | Low (cost center) | High (revenue generator) |
| Number of users | Few (internal teams) | Many (your customers) |
| Core concern | Is the system or service healthy? | Can each request acquire the resources it needs for end-to-end execution in a timely and reliable manner? |
| Evaluation perspective | The system | Your customers |
| Evaluation criteria | Low-level kernel and hardware device drivers | Variables and API endpoint |
| Functional responsibility | Infrastructure operations | Software development |
| Method for understanding | Monitoring | Observability |

With infrastructure, only one perspective really matters: the perspective of the team responsible for its management. The important question to ask about infrastructure is whether the service it provides is essentially healthy. If it’s not, that team must quickly take action to restore the infrastructure to a healthy condition. The system may be running out of capacity, or an underlying failure may have occurred; a human should be alerted and respond to take action.

The conditions that affect infrastructure health change infrequently and are relatively easier to predict. In fact, well-established practices exist to predict (e.g., capacity planning) and automatically remediate (e.g., autoscaling) these types of issues. Because of its relatively predictable and slowly changing nature, aggregated metrics are perfectly acceptable to monitor and alert for system-level problems.

With application code, the perspective that matters most is that of your customers. The underlying systems may be essentially healthy, yet user requests may still be failing for any number of reasons. As covered in earlier chapters, distributed systems make these types of problems harder to detect and understand. Suddenly, the ability to use high-cardinality fields (user ID, shopping cart ID, etc.) as a way to observe a specific customer’s experience becomes critical. Especially in the modern world of continuous delivery, as new versions of your code are constantly being deployed, software concerns are always shifting and changing. Observability provides a way to ask appropriate questions that address those concerns in real time.

These two approaches are not mutually exclusive. Every organization will have considerations that fall more into one category than the other. Next, let’s look at ways those two approaches may coexist, depending on the needs of your organization.

# Assessing Your Organizational Needs

Just as systems and software are complementary, so too are the methods for understanding the way each behaves. Monitoring best helps engineers understand system-level concerns. Observability best helps engineers understand application-level concerns. Assessing your own organizational needs means understanding which concerns are most critical to your business.

Observability will help you deeply understand how software you develop and ship is performing when serving your customers. Code that is well instrumented for observability allows you to answer complex questions about user performance, see the inner workings of your software in production, and identify and swiftly remediate issues that are easy to miss when only examining aggregate performance.

If your company writes and ships software as part of its core business strategy, you need an observability solution. If, in addition to providing an overall level of acceptable aggregate performance, your business strategy also relies on providing excellent service to a particular subset of high-profile customers, your need for observability is especially emphasized.

Monitoring will help you understand how well the systems you run in support of that software are doing their job. Metrics-based monitoring tools and their associated alerts help you see when capacity limits or known error conditions of underlying systems are being reached.

If your company provides infrastructure to its customers as part of its core business strategy (e.g., an infrastructure-as-a-service, or IaaS, provider), you will need a substantial amount of monitoring—low-level Domain Name System (DNS) counters, disk statistics, etc. The underlying systems are business-critical for these organizations, and they need to be experts in these low-level systems that they expose to customers. However, if providing infrastructure is not a core differentiator for your business, monitoring becomes less critical. You may need to monitor only the high-level services and end-to-end checks, for the most part. Determining just how much less monitoring your business needs requires several considerations.

Companies that run a significant portion of their own infrastructure need more monitoring. Whether running systems on premises or with a cloud provider, this consideration is less about where that infrastructure lives and more about operational responsibility. Whether you provision virtual machines in the cloud or administer your own databases on premises, the key factor is whether your team takes on the burden of ensuring infrastructure availability and performance.

Organizations that take on the responsibility of running their own bare-metal systems need monitoring that examines low-level hardware performance. They need monitoring to inspect counters for Ethernet ports, statistics on hard drive performance, and versions of system firmware. Organizations that outsource hardware-level operations to an IaaS provider won’t need metrics and aggregates that perform at that level.

And so it goes, further up the stack. As more operational responsibility is shifted to a third party, so too are infrastructure monitoring concerns.

Companies that outsource most of their infrastructure to higher-level platform-as-a-service (PaaS) providers can likely get away with little, if any, traditional monitoring solutions. Heroku, AWS Lambda, and others essentially let you pay them to do the job of ensuring the availability and performance of the infrastructure that your business *needs to run*, so it can instead focus on the software it *wants to run*.

Today, your mileage may vary, depending on the robustness of your cloud provider. Presumably, the abstractions are clean enough and high-level enough that the experience of removing your dependence on infrastructure monitoring wouldn’t be terribly frustrating. But, in theory, all providers are moving to a model that enables that shift to occur.

## Exceptions: Infrastructure Monitoring That Can’t Be Ignored

This neat dividing line between monitoring for systems and observability for software has a few exceptions. As mentioned earlier, the evaluation perspective for determining how well your software performs is customer experience. If your software is performing slowly, your customers are experiencing it poorly. Therefore, a primary concern for evaluating customer experience is understanding anything that can cause performance bottlenecks. The exceptions to that neat dividing line are any metrics that directly indicate how your software is interacting with its underlying infrastructure.

From a software perspective, there’s little—if any—value in seeing the thousands of graphs for variables discovered in the */proc* filesystem by every common monitoring tool. Metrics about power management and kernel drivers might be useful for understanding low-level infrastructure details, but they get routinely and blissfully ignored (as they should) by software developers because they indicate little useful information about impact on software performance.

However, higher-order infrastructure metrics like CPU usage, memory consumption, and disk activity are indicative of physical performance limitations. As a software engineer, you should be closely watching these indicators because they can be early warning signals of problems triggered by your code. For instance, you want to know if the deployment you just pushed caused resident memory usage to triple within minutes. Being able to see sudden changes like a jump to twice as much CPU consumption or a spike in disk-write activity right after a new feature is introduced can quickly alert you to problematic code changes.

Higher-order infrastructure metrics may or may not be available, depending on how abstracted your underlying infrastructure has become. But if they are, you will certainly want to capture them as part of your approach to observability.

The connection between monitoring and observability here becomes one of correlation. When performance issues occur, you can use monitoring to quickly rule out or confirm systems-level issues. Therefore, it is useful to see systems-level metrics data side by side with your application-level observability data. Some observability tools (like Honeycomb and Lightstep) present that data in a shared context, though others may require you to use different tools or views to make those correlations.

## Real-World Examples

While observability is still a nascent category, a few patterns are emerging for the coexistence of monitoring and observability. The examples cited in this section represent the patterns we’ve commonly seen among our customers or within the larger observability community, but they are by no means exhaustive or definitive. These approaches are included to illustrate how the concepts described in this chapter are applied in the real world.

Our first example customer had a rich ecosystem of tools for understanding the behavior of their production systems. Prior to making a switch to observability, teams were using a combination of Prometheus for traditional monitoring, Jaeger for distributed tracing, and a traditional APM tool. They were looking to improve their incident response times by simplifying their existing multitool approach that required making correlations among data captured in three disparate systems.

Switching to an observability-based approach meant that they were able to consolidate needs and reduce their footprint to a monitoring system and an observability system that coexist. Software engineering teams at this organization report primarily using observability to understand and debug their software in production. The central operations team still uses Prometheus to monitor the infrastructure. However, software engineers report that they can still refer to Prometheus when they have questions about the resource usage impacts of their code. They also report that this need is infrequent and that they rarely need to use Prometheus to troubleshoot application bottlenecks.

Our second example customer is a relatively newer company that was able to build a greenfield application stack. Their production services primarily leverage serverless functions and SaaS platforms to power their applications, and they run almost no infrastructure of their own. Never having had any real infrastructure to begin with, they never started down the path of trying to make monitoring solutions work for their environment. They rely on application instrumentation and observability to understand and debug their software in production. They also export some of that data for longer-term aggregation and warehousing.

Lastly, our third example customer is a mature financial services company undergoing a digital transformation initiative. They have a large heterogeneous mix of legacy infrastructure and applications as well as greenfield applications that are managed across a variety of business units and engineering teams. Many of the older applications are still operating, but the teams that originally built and maintained them have long since disbanded or been reorganized into other parts of the company. Many applications are managed with a mix of metrics-based monitoring paired with dashboarding capabilities (provided by an all-in-one commercial vendor), along with various logging tools to search their unstructured logs.

The business would not realize much, if any, value from ripping out, rearchitecting, and replacing monitoring approaches that work well for stable and working services. Instead, greenfield applications are being developed for observability instead of using the former approach requiring a mix of monitoring, dashboards, and logging. When new applications use company infrastructure, software engineering teams also have access to infrastructure metrics to monitor resource usage impacts. However, some software engineering teams are starting to capture infrastructure metrics in their events in order to reduce their need to use a different system to correlate resource usage with application issues.

# Conclusion

The guiding principle for determining how observability and monitoring coexist within your organization should be dictated by the software and infrastructure responsibilities adopted within its walls. Monitoring is best suited to evaluating the health of your systems. Observability is best suited to evaluating the health of your software. Exactly how much of each solution will be necessary in any given organization depends on how much management of that underlying infrastructure has been outsourced to third-party (aka cloud) providers.

The most notable exceptions to that neat dividing line are higher-order infrastructure metrics on physical devices that directly impact software performance, like CPU, memory, and disk. Metrics that indicate consumption of these physical infrastructure constraints are critical for understanding the boundaries imposed by underlying infrastructure. If these metrics are available from your cloud infrastructure provider, they should be included as part of your approach to observability.

By illustrating a few common approaches to balancing monitoring and observability in complementary ways, you can see how the considerations outlined throughout this chapter are implemented in the real world by different teams. Now that we’ve covered the fundamentals of observability in depth, the next part of this book goes beyond technology considerations to also explore the cultural changes necessary for successfully adopting observability practices and driving that adoption across teams.
