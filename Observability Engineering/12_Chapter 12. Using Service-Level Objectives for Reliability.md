# Chapter 12. Using Service-Level Objectives for Reliability

While observability and traditional monitoring can coexist, observability unlocks the potential to use more sophisticated and complementary approaches to monitoring. The next two chapters will show you how practicing observability and service-level objectives (SLOs) together can improve the reliability of your systems.

In this chapter, you will learn about the common problems that traditional threshold-based monitoring approaches create for your team, how distributed systems exacerbate those problems, and how using an SLO-based approach to monitoring instead solves those problems. We’ll conclude with a real-world example of replacing traditional threshold-based alerting with SLOs. And in [Chapter 13](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch13.html#acting_on_and_debugging_slo_based_alert), we’ll examine how observability makes your SLO-based alerts actionable and debuggable.

Let’s begin with understanding the role of monitoring and alerting and the previous approaches to them.

# Traditional Monitoring Approaches Create Dangerous Alert Fatigue

In monitoring-based approaches, alerts often measure the things that are easiest to measure. Metrics are used to track simplistic system states that might indicate a service’s underlying process(es) may be running poorly or may be a leading indicator of troubles ahead. These states might, for example, trigger an alert if CPU is above 80%, or if available memory is below 10%, or if disk space is nearly full, or if more than *x* many threads are running, or any set of other simplistic measures of underlying system conditions.

While such simplistic “potential-cause” measures are easy to collect, they don’t produce meaningful alerts for you to act upon. Deviations in CPU utilization may also be indicators that a backup process is running, or a garbage collector is doing its cleanup job, or that any other phenomenon may be happening on a system. In other words, those conditions may reflect any number of system factors, not just the problematic ones we really care about. Triggering alerts from these measures based on the underlying hardware creates a high percentage of false positives.

Experienced engineering teams that own the operation of their software in production will often learn to tune out, or even suppress, these types of alerts because they’re so unreliable. Teams that do so regularly adopt phrases like “Don’t worry about that alert; we know the process runs out of memory from time to time.”

Becoming accustomed to alerts that are prone to false positives is a known problem and a dangerous practice. In other industries, that problem is known as *normalization of deviance*: a term coined during the [investigation of the Challenger disaster](https://pubmed.ncbi.nlm.nih.gov/25742063). When individuals in an organization regularly shut off alarms or fail to take action when alarms occur, they eventually become so desensitized about the practice deviating from the expected response that it no longer feels wrong to them. Failures that are “normal” and disregarded are, at best, simply background noise. At worst, they lead to disastrous oversights from cascading system failures.

In the software industry, the poor signal-to-noise ratio of monitoring-based alerting often leads to *alert fatigue*—and to gradually paying less attention to all alerts, because so many of them are false alarms, not actionable, or simply not useful. Unfortunately, with monitoring-based alerting, that problem is often compounded when incidents occur. Post-incident reviews often generate action items that create new, more important alerts that, presumably, would have alerted in time to prevent the problem. That leads to an even larger set of alerts generated during the next incident. That pattern of alert escalation creates an ever-increasing flood of alerts and an ever-increasing cognitive load on responding engineers to determine which alerts matter and which don’t.

That type of dysfunction is so common in the software industry that many monitoring and incident-response tool vendors proudly offer various solutions labeled “AIOps” to group, suppress, or otherwise try to process that alert load for you (see [“This Misleading Promise of AIOps”](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch08.html#this_misleading_promise_of_aiops) Engineering teams have become so accustomed to alert noise that this pattern is now seen as normal. If the future of running software in production is doomed to generate so much noise that it must be artificially processed, it’s safe to say the situation has gone well beyond a normalization of deviance. Industry vendors have now productized that deviance and will happily sell you a solution for its management.

Again, we believe that type of dysfunction exists because of the limitations imposed by using metrics and monitoring tools that used to be the best choice we had to understand the state of production systems. As an industry, we now suffer a collective Stockholm Syndrome that is just the tip of the dysfunction iceberg when it comes to the many problems we encounter today as a result. The complexity of modern system architectures along with the higher demands for their resilience have pushed the state of these dysfunctional affairs away from tolerable and toward no longer acceptable.

Distributed systems today require an alternative approach. Let’s examine why approaches to monitoring a monolith break down at scale and what we can do differently.

# Threshold Alerting Is for Known-Unknowns Only

Anticipating failure modes is much easier in self-contained systems than in distributed systems. So, adding monitoring that expects each of those known failure modes to occur seems logical. Operations teams supporting self-contained production systems can write specific monitoring checks for each precise state.

However, as systems become more complex, they create a combinatorial explosion of potential failure modes. Ops teams accustomed to working with less complex systems will rely on their intuition, best guesses, and memories of past outages to predict any possible system failures they can imagine. While that approach with traditional monitoring may work at smaller scales, the explosion of complexity in modern systems requires teams to write and maintain hundreds, or even thousands, of precise state checks to look for every conceivable scenario.

That approach isn’t sustainable. The checks aren’t maintainable, often the knowledge isn’t transferable, and past historical behavior doesn’t necessarily predict failures likely to occur in the future. The traditional monitoring mindset is often about preventing failure. But in a distributed system with hundreds or thousands of components serving production traffic, *failure is inevitable*.

Today, engineering teams regularly distribute load across multiple disparate systems. They split up, shard, horizontally partition, and replicate data across geographically distributed systems. While these architectural decisions optimize for performance, resiliency, and scalability, they can also make systemic failures impossible to detect or predict. Emergent failure modes can impact your users long before the coarse synthetic probes traditionally used as indicators will tell you. Traditional measurements for service health suddenly have little value because they’re so irrelevant to the behavior of the system as a whole.

Traditional system metrics often miss unexpected failure modes in distributed systems. An abnormal number of running threads on one component might indicate garbage collection is in progress, or it might also indicate slow response times might be imminent in an upstream service. It’s also possible that the condition detected via system metrics might be entirely unrelated to service slowness. Still, that system operator receiving an alert about that abnormal number of threads in the middle of the night won’t know which of those conditions is true, and it’s up to them to divine that correlation.

Further, distributed systems design for resilience with loosely coupled components. With modern infrastructure tooling, it’s possible to automatically remediate many common issues that used to require waking up an engineer. You probably already use some of the current and commonplace methods for building resilience into your systems: autoscaling, load balancing, failover, and so forth. Automation can pause further rollout of a bad release or roll it back. Running in an active-active configuration or automating the process of promoting passive to active ensures that an AZ failure will cause damage only transiently. Failures that get automatically remediated *should not trigger alarms*. (Anecdotally, some teams may do just that in an attempt to build valuable “intuition” about the inner workings of a service. On the contrary, that noise only serves to starve the team of time they could be building intuition about the inner workings of service components that don’t have auto-remediation.)

That’s not to say that you shouldn’t debug auto-remediated failures. You should absolutely debug those failures *during normal business hours*. The entire point of alerts is to bring attention to an emergency situation that simply cannot wait. Triggering alerts that wake up engineers in the middle of the night to notify them of transient failures simply creates noise and leads to burnout. Thus, we need a strategy to define the urgency of problems.

In a time of complex and interdependent systems, teams can easily reach fatigue from the deluge of alerts that may, but probably don’t, reliably indicate a problem with the way customers are currently using the services your business relies on. Alerts for conditions that aren’t tied directly to customer experience will quickly become nothing more than background noise. Those alerts are no longer serving their intended purpose and, more nefariously, actually serve the opposite purpose: they distract your team from paying attention to the alerts that really do matter.

If you expect to run a reliable service, your teams must remove any unreliable or noisy alerts. Yet many teams fear removing those unnecessary distractions. Often the prevailing concern is that by removing alerts, teams will have no way of learning about service degradation. But it’s important to realize that these types of traditional alerts are helping you detect only *known-unknowns*: problems you know could happen but are unsure may be happening at any given time. That alert coverage provides a false sense of security because it does nothing to prepare you for dealing with new and novel failures, or the *unknown-unknowns*.

Practitioners of observability are looking for these unknown-unknowns, having outgrown those systems in which only a fixed set of failures can ever occur. While reducing your unknowns to only known-unknowns might be closer to achievable for legacy self-contained software systems with few components, that’s certainly not the case with modern systems. Yet, organizations hesitate to remove many of the old alerts associated with traditional monitoring.

Later in this chapter, we’ll look at ways to feel confident when removing unhelpful alerts. For now, let’s define the criteria for an alert to be considered helpful. The Google SRE book indicates that a good alert must reflect urgent user impact, must be actionable, must be novel, and must require investigation rather than rote action.[1](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch12.html#ch01fn9)

We’ll define our alerting criteria to be a two-part subset. First, it must be a reliable indicator that the user experience of your service is in a degraded state. Second, the alert must be solvable. There must be a systematic (but not pure rote automatable) way to debug and take action in response to the alert that does not require a responder to divine the right course of action. If those two conditions are not true, any alert you have configured is no longer serving its intended purpose.

# User Experience Is a North Star

To echo the words of the Google SRE book again, potential-cause alerts have poor correlation to real problems, but symptom-of-user-pain alerts better allow you to understand user impacts and the state of the system as experienced by customers.

How, then, do you focus on setting up alerts to detect failures that impact user experience? This is where a departure from traditional monitoring approaches becomes necessary. The traditional metrics-based monitoring approach relies on using static thresholds to define optimal system conditions. Yet the performance of modern systems—even at the infrastructure level—often changes shape dynamically under different workloads. Static thresholds simply aren’t up to the task of monitoring impact on user experience.

Setting up traditional alerting mechanisms to monitor user experience means that system engineers must choose arbitrary constants that predict when that experience is poor. For example, these alerts might be implemented to trigger when “10 users have experienced slow page-load times,” or “the 95th percentile of requests have persisted above a certain number of milliseconds.” In a metrics-based approach, system engineers are required to divine which exact static measures indicate that unacceptable problems are occurring.

Yet system performance varies significantly throughout the day as different users, in different time zones, interact with your services in different ways. During slow traffic times, when you may have hundreds of concurrent sessions, 10 users experiencing slow page-load times might be a significant metric. But that significance drops sharply at peak load times when you may have tens of thousands of concurrent sessions running.

Remember that in distributed systems, failure is inevitable. Small transient failures are always occurring without you necessarily noticing. Common examples include a failed request that later succeeds on a retry; a critical process that initially fails, but its completion is merely delayed until it gets routed to a newly provisioned host; or a service that becomes unresponsive until its requests are routed to a backup service. The additional latency introduced by these types of transient failures might blend into normal operations during peak traffic, but p95 response times would be more sensitive to individual data points during periods of low traffic.

In a similar vein, these examples also illustrate the coarseness of time-based metrics. Let’s say p95 response time is being gauged in five-minute intervals. Every five minutes, performance over the trailing five-minute interval reports a value that triggers an alert if it exceeds a static threshold. If that value exceeds the threshold, the entire five-minute interval is considered bad (and conversely, any five-minute interval that didn’t exceed the threshold is considered good). Alerting on that type of metric results in high rates of both false positives and false negatives. It also has a level of granularity that is insufficient to diagnose exactly when and where a problem may have occurred.

Static thresholds are too rigid and coarse to reliably indicate degraded user experience in a dynamic environment. They lack context. Reliable alerts need a finer level of both granularity and reliability. This is where SLOs can help.

# What Is a Service-Level Objective?

*Service-level objectives* (*SLOs*) are internal goals for measurement of service health. Popularized by the [Google SRE book](https://landing.google.com/sre/sre-book/chapters/service-level-objectives), SLOs are a key part of setting external service-level agreements between service providers and their customers. These internal measures are typically more stringent than externally facing agreements or availability commitments. With that added stringency, SLOs can provide a safety net that helps teams identify and remediate issues before external user experience reaches unacceptable levels.

###### Note

We recommend Alex Hidalgo’s book, [Implementing Service Level Objectives](https://www.oreilly.com/library/view/implementing-service-level/9781492076803) (O’Reilly), for a deeper understanding of the subject.

Much has been written about the use of SLOs for service reliability, and they are not unique to the world of observability. However, using an SLO-based approach to monitoring service health requires having observability built into your applications. SLOs can be, and sometimes are, implemented in systems without observability. But the ramifications of doing so can have severe unintended consequences.

## Reliable Alerting with SLOs

SLOs quantify an agreed-upon target for service availability, based on critical end-user journeys rather than system metrics. That target is measured using service-level indicators (SLIs), which categorize the system state as good or bad. Two kinds of SLIs exist: *time-based measures* (such as “99th percentile latency less than 300 ms over each 5-minute window”), and *event-based measures* (such as “proportion of events that took less than 300 ms during a given rolling time window”).

Both attempt to express the impact to end users but differ on whether data about the incoming user traffic has been pre-aggregated by time bucket. We recommend setting SLIs that use event-based measures as opposed to time-based measures, because event-based measures provide a more reliable and more granular way to quantify the state of a service. We discuss the reasons for this in the next chapter.

Let’s look at an example of how to define an event-based SLI. You might define a good customer experience as being a state when “a user should be able to successfully load your home page and see a result quickly.” Expressing that with an SLI means qualifying events and then determining whether they meet our conditions. In this example, your SLI would do the following:

- Look for any event with a request path of */home*.

- Screen qualifying events for conditions in which the event duration < 100 ms.

- If the event duration < 100 ms *and* was served successfully, consider it OK.

- If the event duration > 100 ms, consider that event an error even if it returned a success code.

Any event that is an error would spend some of the error budget allowed in your SLO. We’ll closely examine patterns for proactively managing SLO error budgets and triggering alerts in the next chapter. For now, we’ll summarize by saying that given enough errors, your systems could alert you to a potential breach of the SLO.

SLOs narrow the scope of your alerts to consider only symptoms that impact what the users of our service experience. If an underlying condition is impacting “a user loading our home page and seeing it quickly,” an alert should be triggered, because someone needs to investigate why. However, there is no correlation as to *why* and *how* the service might be degraded. We simply know that something is wrong.

In contrast, traditional monitoring relies on a cause-based approach: a previously known cause is detected (e.g., an abnormal number of threads), signaling that users might experience undesirable symptoms (slow page-load times). That approach fuses the “what” and “why” of a situation in an attempt to help pinpoint where investigation should begin. But, as you’ve seen, there’s a lot more to your services than just the known states of up, down, or even slow. Emergent failure modes can impact your users long before coarse synthetic probes will tell you. Decoupling “what” from “why” is one of the most important distinctions in writing good monitoring with maximum signal and minimum noise.

The second criteria for an alert to be helpful is that it must be *actionable*. A system-level potential-cause alert that the CPU is high tells you nothing about whether users are impacted and whether you should take action. In contrast, SLO-based alerts are symptom based: they tell you that something is wrong. They are actionable because now it is up to the responder to determine why users are seeing an impact and to mitigate. However, if you cannot sufficiently debug your systems, resolving the problem will be challenging. That’s where a shift to observability becomes essential: debugging in production must be safe and natural.

In an SLO-based world, you need observability: the ability to ask novel questions of your systems without having to add new instrumentation. As you’ve seen throughout this book, observability allows you to debug from first principles. With rich telemetry you can start wide and then filter to reduce the search space. That approach means you can respond to determine the source of any problem, regardless of how novel or emergent the failure may be.

In self-contained, unchanging systems with a long-lived alert set, it’s possible to have a large collection of alerts that correspond to all known failures. Given the resources and time, it’s also theoretically possible to mitigate and even prevent all of those known failures (so why haven’t more teams done that already?). The reality is that no matter how many known failures you automatically fix, the emergent failure modes that come with modern distributed systems can’t be predicted. There’s no going back in time to add metrics around the parts of your system that happened to break unexpectedly. When anything can break at any time, you need data for everything. Note that’s *data* for everything and not *alerts* for everything. Having alerts for everything is not feasible. As we’ve seen, the software industry as a whole is already drowning in the noise.

Observability is a requirement for responding to novel, emergent failure modes. With observability, you can methodically interrogate your systems by taking one step after another: ask one question and examine the result, then ask another, and so on. No longer are you limited by traditional monitoring alerts and dashboards. Instead, you can improvise and adapt solutions to find any problem in your system.

Instrumentation that provides rich and meaningful telemetry is the basis for that approach. Being able to quickly analyze that telemetry data to validate or falsify hypotheses is what empowers you to feel confidence in removing noisy, unhelpful alerts. Decoupling the “what” from the “why” in your alerting is possible when using SLO-based alerts in tandem with observability.

When most alerts are not actionable, that quickly leads to alert fatigue. To eliminate that problem, it’s time to delete all of your unactionable alerts.

Still not sure you can convince your team to remove all of those unhelpful alerts? Let’s look at a real example of what it takes to drive that sort of culture change.

## Changing Culture Toward SLO-Based Alerts: A Case Study

Just having queryable telemetry with rich context, on its own, might not be enough for your team to feel confident deleting all of those existing unhelpful alerts. That was our experience at Honeycomb. We’d implemented SLOs, but our team didn’t quite fully trust them yet. SLO alerts were being routed to a low-priority inbox, while the team continued to rely on traditional monitoring alerts. That trust wasn’t established until we had a few incidents of SLO-based alerts flagging issues *long before* traditional alerts provided any useful signal.

To illustrate how this change occurred, let’s examine an incident from the end of 2019. Liz had developed our SLO feature and was paying attention to SLO alerts while the rest of the team was focused on traditional alerts. In this outage, the Shepherd service that ingests all of our incoming customer data had its SLO begin to burn and sent an alert to the SLO test channel. The service recovered fairly quickly: a 1.5% brownout had occurred for 20 minutes. The SLO error budget had taken a ding because that burned most of the 30-day budget. However, the problem appeared to go away by itself.

Our on-call engineer was woken up by the SLO alert at 1:29 a.m. his time. Seeing that the service was working, he blearily decided it was probably just a blip. The SLO alert triggered, but traditional monitoring that required consecutive probes in a row to fail didn’t detect a problem. When the SLO alert triggered a fourth time, at 9:55 a.m., this was undeniably not a coincidence. At that time, the engineering team was willing to declare an incident even though traditional monitoring had still not detected a problem.

While investigating the incident, another engineer thought to check the process uptime ([Figure 12-1](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch12.html#a_heatmap_showing_uptime_of_a_crashing)). In doing so, they discovered a process had a memory leak. Each machine in the cluster had been running out of memory, failing in synchrony, and restarting. Once that problem was identified, it was quickly correlated with a new deployment, and we were able to roll back the error. The incident was declared resolved at 10:32 a.m.

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492076438/files/assets/oben_1201.png)

###### Figure 12-1. A heatmap showing uptime of a crashing fleet, restarting together around 18:30, and the memory profile showing leaking and triggering an out of memory condition

At this point, we have to acknowledge that many engineers who are reading this story might challenge that traditional cause-based alerting would have worked well enough in this case. Why not alert on memory and therefore get alerts when the system runs out of memory (OOM)? There are two points to consider when addressing that challenge.

First, at Honeycomb, our engineers had long since been trained out of tracking OOMs. Caching, garbage collection, and backup processes all opportunistically used—and occasionally used up—system memory. “Ran out of memory” turned out to be common for our applications. Given our architecture, even having a process crash from time to time turned out not to be fatal, so long as all didn’t crash at once. For our purposes, tracking those individual failures had not been useful at all. We were more concerned with the availability of the cluster as a whole.

Given that scenario, traditional monitoring alerts did not—and never would have—noticed this gradual degradation at all. Those simple coarse synthetic probes could detect only a total outage, not one out of 50 probes failing and then recovering. In that state, machines were still available, so the service was up, and most data was making it through.

Second, even if it were somehow possible to introduce enough complicated logic to trigger alerts when only a certain notable number of specific types of OOMs were detected, we would have needed to predict this exact failure mode, well in advance of this one bespoke issue ever occurring, in order to devise the right incantation of conditions on which to trigger a useful alert. That theoretical incantation might have detected this one bespoke issue this one time, but would likely most often exist just to generate noise and propagate alert fatigue.

Although traditional monitoring never detected the gradual degradation, the SLO hadn’t lied: users were seeing a real effect. Some incoming customer data had been dropped. It burned our SLO budget almost entirely from the start ([Figure 12-2](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch12.html#the_slo_error_budget_burned_en_dashfive)).

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492076438/files/assets/oben_1202.png)

###### Figure 12-2. The SLO error budget burned –566% by the time the incident was over; compliance dropped to 99.97% (from the target of 99.995%). The boxed areas on the timeline show events marked as bad—and that they occurred fairly uniformly at fairly regular intervals until corrected.

By that stage, if the team had started treating SLO-based alerts as primary alerting, we would have been less likely to look for external and transient explanations. We would have instead moved to actually fix the issue, or at least roll back the latest deploy. SLOs proved their ability to detect brownouts and prompt the appropriate response.

That incident changed our culture. Once SLO burn alerts had proven their value, our engineering team had as much respect for SLO-based alerts as they did for traditional alerts. After a bit more time relying on SLO-based alerts, our team became increasingly comfortable with the reliability of alerting purely on SLO data.

At that point, we deleted all of our traditional monitoring alerts that were based on percentages of errors for traffic in the past five minutes, the absolute number of errors, or lower-level system behavior. We now rely on SLO-based alerts as our primary line of defense.

# Conclusion

In this chapter, we provided a high-level overview of SLOs as a more effective alerting strategy than traditional threshold monitoring. Alert fatigue, prevalent in the software industry, is enabled by the potential-cause-based approach taken by traditional monitoring solutions.

Alert fatigue can be solved by focusing on creating only helpful alerts that meet two criteria. First, they must trigger as reliable indicators only that the user experience of your service is in a degraded state. Second, they must be actionable. Any alert that does not meet that criteria is no longer serving its purpose and should be deleted.

SLOs decouple the “what” and “why” behind incident alerting. Focusing on symptom-of-pain-based alerts means that SLOs can be reliable indicators of customer experience. When SLOs are driven by event-based measures, they have a far lesser degree of false positives and false negatives. Therefore, SLO-based alerts can be a productive way to make alerting less disruptive, more actionable, and more timely. They can help differentiate between systemic problems and occasional sporadic failures.

On their own, SLO-based alerts can tell you there is pain, but not why it is happening. For your SLO-based alerts to be actionable, your production systems must be sufficiently debuggable. Having observability in your systems is critical for success when using SLOs.

In the next chapter, we’ll delve into the inner workings of SLO burn budgets and examine how they’re used in more technical detail.

[1](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch12.html#ch01fn9-marker) Betsy Beyer et al., [“Tying These Principles Together”](https://oreil.ly/vRbQf), in *Site Reliability Engineering* (Sebastopol, CA: O’Reilly, 2016), 63–64.
