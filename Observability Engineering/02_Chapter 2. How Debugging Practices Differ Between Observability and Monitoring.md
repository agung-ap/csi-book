# Chapter 2. How Debugging Practices Differ Between Observability and Monitoring

In the previous chapter, we covered the origins and common use of the metrics data type for debugging. In this chapter, we’ll more closely examine the specific debugging practices associated with traditional monitoring tools and how those differ from the debugging practices associated with observability tools.

Traditional monitoring tools work by checking system conditions against known thresholds that indicate whether previously known error conditions are present. That is a fundamentally reactive approach because it works well only for identifying previously encountered failure modes.

In contrast, observability tools work by enabling iterative exploratory investigations to systematically determine where and why performance issues may be occurring. Observability enables a proactive approach to identifying any failure mode, whether previously known or unknown.

In this chapter, we focus on understanding the limitations of monitoring-based troubleshooting methods. First, we unpack how monitoring tools are used within the context of troubleshooting software performance issues in production. Then we examine the behaviors institutionalized by those monitoring-based approaches. Finally, we show how observability practices enable teams to identify both previously known and unknown issues.

# How Monitoring Data Is Used for Debugging

The *Oxford English Dictionary* defines *monitoring* as observing and checking the progress or quality of (something) over a period of time, to keep under systematic review. Traditional monitoring systems do just that by way of metrics: they check the performance of an application over time; then they report an aggregate measure of performance over that interval. Monitoring systems collect, aggregate, and analyze metrics to sift through known patterns that indicate whether troubling trends are occurring.

This monitoring data has two main consumers: machines and humans. Machines use monitoring data to make decisions about whether a detected condition should trigger an alert or a recovery should be declared. A *metric* is a numerical representation of system state over the particular interval of time when it was recorded. Similar to looking at a physical gauge, we might be able to glance at a metric that conveys whether a particular resource is over- or underutilized at a particular moment in time. For example, CPU utilization might be at 90% right now.

But is that behavior changing? Is the measure shown on the gauge going up or going down? Metrics are typically more useful in aggregate. Understanding the trending values of metrics over time provides insights into system behaviors that affect software performance. Monitoring systems collect, aggregate, and analyze metrics to sift through known patterns that indicate trends their humans want to know about.

If CPU utilization continues to stay over 90% for the next two minutes, someone may have decided that’s a condition they want to be alerted about. For clarity, it’s worth noting that to the machines, a metric is just a number. System state in the metrics world is very binary. Below a certain number and interval, the machine will not trigger an alert. Above a certain number and interval, the machine will trigger an alert. Where exactly that threshold lies is a human decision.

When monitoring systems detect a trend that a human identified as important, an alert is sent. Similarly, if CPU utilization drops below 90% for a preconfigured timespan, the monitoring system will determine that the error condition for the triggered alert no longer applies and therefore declare the system recovered. It’s a rudimentary system, yet so many of our troubleshooting capabilities rely on it.

The way humans use that same data to debug issues is a bit more interesting. Those numerical measurements are fed into TSDBs, and a graphical interface uses that database to source graphical representations of data trends. Those graphs can be collected and assembled into progressively more complicated combinations, known as *dashboards*.

Static dashboards are commonly assembled one per service, and they’re a useful starting point for an engineer to begin understanding particular aspects of the underlying system. This is the original intent for dashboards: to provide an overview of how a set of metrics is tracking and to surface noteworthy trends. However, dashboards are a poor choice for discovering new problems with debugging.

When dashboards were first built, we didn’t have many system metrics to worry about. So it was relatively easy to build a dashboard that showed the critical data anyone should know about for any given service. In modern times, storage is cheap, processing is powerful, and the data we can collect about a system seems virtually limitless. Modern services typically collect so many metrics that it’s impossible to fit them all into the same dashboard. Yet that doesn’t stop many engineering teams from trying to fit those all into a singular view. After all, that’s the promise of the dashboard!

To make everything fit in a dashboard, metrics are often aggregated and averaged. These aggregate values may convey a specific condition—for example, mean CPU across your cluster is above 90%. But these aggregated measures no longer provide meaningful visibility into what’s happening in their corresponding underlying systems—they don’t tell you which processes are responsible for that condition. To mitigate that problem, some vendors have added filters and drill-downs to their dashboarding interfaces that allow you to dive deeper and narrow down visualizations in ways that improve their function as a debugging tool.

However, your ability to troubleshoot effectively using dashboards is limited by your ability to pre-declare conditions that describe what you might be looking for. In advance, you need to specify that you want the ability to break down values along a certain small set of dimensions. That has to be done in advance so that your dashboarding tool can create the indexes necessary on those columns to allow the type of analysis you want. That indexing is also strictly stymied by groups of data with high cardinality. You can’t just load a dashboard with high cardinality data across multiple graphs if you’re using a metrics-based tool.

Requiring the foresight to define necessary conditions puts the onus of data discovery on the user. Any efforts to discover new system insights throughout the course of debugging are limited by conditions you would have had to predict prior to starting your investigation. For example, during the course of your investigation, you might discover that it’s useful to group CPU utilization by instance type. But you can’t do that because you didn’t add the necessary labels in advance.

In that respect, using metrics to surface new system insights is an inherently reactive approach. Yet, as a whole, the software industry has seemingly been conditioned to rely on dashboards for debugging despite these limitations. That reactiveness is a logical consequence of metrics being the best troubleshooting tool the industry had available for many years. Because we’re so accustomed to that limitation as the default way troubleshooting is done, the impact that has on our troubleshooting behavior may not be immediately clear at a glance.

## Troubleshooting Behaviors When Using Dashboards

The following scenario should be familiar to engineers responsible for managing production services. If you’re such an engineer, put yourself in these shoes and use that perspective to examine the assumptions that you also make in your own work environment. If you’re not an engineer who typically manages services in production, examine the following scenario for the types of limitations described in the previous section.

It’s a new morning, and your workday is just getting started. You walk over to your desk, and one of the first things you do is glance at a collection of readily displayed dashboards. Your dashboarding system aspires to be a “single pane of glass,” behind which you can quickly see every aspect of your application system, its various components, and their health statuses. You also have a few dashboards that act as high-level summaries to convey important top-line business metrics—so you can see, for example, whether your app is breaking any new traffic records, if any of your apps have been removed from the App Store overnight, and a variety of other critical conditions that require immediate attention.

You glance at these dashboards to seek familiar conditions and reassure yourself that you are free to start your day without the distraction of firefighting production emergencies. The dashboard displays a collection of two to three dozen graphs. You don’t know what many of those graphs actually show. Yet, over time, you’ve developed confidence in the predictive powers that these graphs give you. For example, if the graph at the bottom of this screen turns red, you should drop whatever you’re doing and immediately start investigating before things get worse.

Perhaps you don’t know what all the graphs actually measure, but they pretty reliably help you predict where the problems are happening in the production service you’re intimately familiar with. When the graphs turn a certain way, you almost acquire a psychic power of prediction. If the left corner of the top graph dips while the bottom-right graph is growing steadily, a problem exists with your message queues. If the box in the center is spiking every five minutes and the background is a few shades redder than normal, a database query is acting up.

Just then, as you’re glancing through the graphs, you notice a problem with your caching layer. Nothing on the dashboard clearly says, “Your primary caching server is getting hot.” But you’ve gotten to know your system so well that by deciphering patterns on the screen, you can immediately leap into action to do things that are not at all clearly stated by the data available. You’ve seen this type of issue before and, based on those past scars, you know that this particular combination of measures indicates a caching problem.

Seeing that pattern, you quickly pull up the dashboard for the caching component of your system to confirm your suspicion. Your suspicion is confirmed, and you jump right into fixing the problem. Similarly, you can do this with more than a handful of patterns. Over time, you’ve learned to divine the source of problems by reading the tea leaves of your particular production service.

## The Limitations of Troubleshooting by Intuition

Many engineers are intimately familiar with this troubleshooting approach. Ask yourself, just how much intuition do you rely on when hopping around various components of your system throughout the course of investigating problems? Typically, as an industry, we value that intuition, and it has provided us with much benefit throughout the years. Now ask yourself: if you were placed in front of those same dashboarding tools, but with an entirely different application, written in a different language, with a different architecture, could you divine those same answers? When the lower-left corner turns blue, would you know what you were supposed to do or if it was even necessary to take action?

Clearly, the answer to that question is no. The expressions of various system problems as seen through dashboards is quite different from app stack to app stack. Yet, as an industry, this is our primary way of interacting with systems. Historically, engineers have relied on static dashboards that are densely populated with data that is an interpretive layer or two away from the data needed to make proper diagnoses when things go wrong. But we start seeing the limitations of their usefulness when we discover novel problems. Let’s consider a few examples.

### Example 1: Insufficient correlation

An engineer adds an index and wants to know if that achieved their goal of faster query times. They also want to know whether any other unexpected consequences occurred. They might want to ask the following questions:

- Is a particular query (which is known to be a pain point) scanning fewer rows than before?

- How often is the new index getting chosen by the query planner, and for which queries?

- Are write latencies up overall, on average, or at the 95th/99th percentiles?

- Are queries faster or slower when they use this index than their previous query plan?

- What other indexes are also used along with the new index (assuming index intersection)?

- Has this index made any other indexes obsolete, so we can drop those and reclaim some write capacity?

Those are just a few example questions, and they can ask more. However, what they have available is a dashboard and graphs for CPU load average, memory usage, index counters, and lots of other internal statistics for the host and running database. They cannot slice and dice or break down by user, query, destination or source IP, or anything like that. All they can do is eyeball the broad changes and hazard a sophisticated guess, mostly based on timestamps.

### Example 2: Not drilling down

An engineer discovers a bug that inadvertently expires data and wants to know if it’s affecting *all* the users or just some shards. Instead, what they have available in a dashboard is the ability to see disk space dropping suspiciously fast…on just one data shard. They briskly assume the problem is confined to that shard and move on, not realizing that disk space appeared to be holding steady on the other shard, thanks to a simultaneous import operation.

### Example 3: Tool-hopping

An engineer sees a spike in errors at a particular time. They start paging through dashboards, looking for spikes in other metrics at the same time, and they find some, but they can’t tell which are the cause of the error and which are the effects. So they jump over into their logging tool and start grepping for errors. Once they find the request ID of an error, they turn to their tracing tool and copy-paste the error ID into the tracing tool. (If that request isn’t traced, they repeat this over and over until they catch one that is.)

These monitoring tools can get better at detecting finer-grained problems over time—if you have a robust tradition of always running restrospectives after outages and adding custom metrics where possible in response. Typically, the way this happens is that the on-call engineer figures it out or arrives at a reasonable hypothesis, and also figures out exactly which metric(s) would answer the question if it exists. They ship a change to create that metric and begin gathering it. Of course, it’s too late now to see if your last change had the impact you’re guessing it did—you can’t go back in time and capture that custom metric a second time unless you can replay the whole exact scenario—but if it happens again, the story goes, next time you’ll know for sure.

The engineers in the preceding examples might go back and add custom metrics for each query family, for expiration rates per collection, for error rates per shards, etc. (They might go nuts and add custom metrics for every single query family’s lock usage, hits for each index, buckets for execution times, etc.—and then find out they doubled their entire monitoring budget the next billing period.)

## Traditional Monitoring Is Fundamentally Reactive

The preceding approach is entirely reactive, yet many teams accept this as the normal state of operations—that is simply how troubleshooting is done. At best, it’s a way of playing whack-a-mole with critical telemetry, always playing catch-up after the fact. It’s also quite costly, since metrics tools tend to price out custom metrics in a way that scales up linearly with each one. Many teams enthusiastically go all-in on custom metrics, then keel over when they see the bill, and end up going back to prune the majority of them.

Is your team one of those teams? To help determine that, watch for these indicators as you perform your work maintaining your production service throughout the week:

- When issues occur in production, are you determining where you need to investigate based on an actual visible trail of system information breadcrumbs? Or are you following your intuition to locate those problems? Are you looking in the place where you know you found the answer last time?

- Are you relying on your expert familiarity of this system and its past problems? When you use a troubleshooting tool to investigate a problem, are you exploratively looking for clues? Or are you trying to confirm a guess? For example, if latency is slow across the board and you have dozens of databases and queues that could be producing it, are you able to use data to determine where the latency is coming from? Or do you guess it must be your MySQL database, per usual, and then go check your MySQL graphs to confirm your hunch?

How often do you intuitively jump to a solution and then look for confirmation that it’s right and proceed accordingly—but actually miss the real issue because that confirmed assumption was only a symptom, or an effect rather than the cause?

- Are your troubleshooting tools giving you precise answers to your questions and leading you to direct answers? Or are you performing translations based on system familiarity to arrive at the answer you actually need?

- How many times are you leaping from tool to tool, attempting to correlate patterns between observations, relying on yourself to carry the context between disparate sources?

- Most of all, is the best debugger on your team always the person who has been there the longest? This is a dead giveaway that most of your knowledge about your system comes not from a democratized method like a tool, but through personal hands-on experience alone.

Guesses aren’t good enough. Correlation is not causation. A vast disconnect often exists between the specific questions you want to ask and the dashboards available to provide answers. You shouldn’t have to make a leap of faith to connect cause and effect.

It gets even worse when you consider the gravity-warping impact that confirmation bias can have. With a system like this, you can’t find what you don’t know to look for. You can’t ask questions that you didn’t predict you might need to ask, far in advance.

Historically, engineers have had to stitch together answers from various data sources, along with the intuitions they’ve developed about their systems in order to diagnose issues. As an industry, we have accepted that as the normal state of operations. But as systems have grown in complexity, beyond the ability for any one person or team to intuitively understand their various moving parts, the need to grow beyond this reactive and limiting approach becomes clear.

# How Observability Enables Better Debugging

As we’ve seen in the preceding section, monitoring is a reactive approach that is best suited for detecting known problems and previously identified patterns; this model centers around the concept of alerts and outages. Conversely, observability lets you explicitly discover the source of any problem, along any dimension or combination of dimensions, without needing to first predict where and how that problem might be happening; this model centers around questioning and understanding.

Let’s comparatively examine the differences between monitoring and observability across three axes: relying on institutional knowledge, finding hidden issues, and having confidence in diagnosing production issues. We provide more in-depth examples of how and why these differences occur in upcoming chapters. For now, we will make these comparative differences at a high level.

*Institutional knowledge* is unwritten information that may be known to some but is not commonly known by others within an organization. With monitoring-based approaches, teams often orient themselves around the idea that seniority is the key to knowledge: the engineer who has been on the team longest is often the best debugger on the team and the debugger of last resort. When debugging is derived from an individual’s experience deciphering previously known patterns, that predilection should be unsurprising.

Conversely, teams that practice observability are inclined in a radically different direction. With observability tools, the best debugger on the team is typically the engineer who is the most curious. Engineers practicing observability have the ability to interrogate their systems by asking exploratory questions, using the answers discovered to lead them toward making further open-ended inquiries (see [Chapter 8](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch08.html#analyzing_events_to_achieve_observabili)). Rather than valuing intimate knowledge of one particular system to provide an investigative hunch, observability rewards skilled investigative abilities that translate across different systems.

The impact of that shift becomes most evident when it comes to finding issues that are buried deep within complex systems. A reactive monitoring-based approach that rewards intuition and hunches is also prone to obscuring the real source of issues with confirmation bias. When issues are detected, they’re diagnosed based on how similar their behavioral pattern appears to previously known problems. That can lead to treating symptoms of a problem without ever getting to the actual source. Engineers guess at what might be occurring, jump to confirm that guess, and alleviate the symptom without ever fully investigating why it was happening in the first place. Worse, by introducing a fix for the symptom instead of its cause, teams will now have two problems to contend with instead of one.

Rather than leaning on expert foreknowledge, observability allows engineers to treat every investigation as new. When issues are detected, even if the triggering conditions appear similar to past problems, an engineer should be able to put one metaphorical foot in front of the other to follow the clues provided by breadcrumbs of system information. You can follow the data toward determining the correct answer—every time, step by step. That methodical approach means that any engineer can diagnose any issue without needing a vast level of system familiarity to reason about impossibly complex systems to intuitively divine a course of action. Further, the objectivity afforded by that methodology means engineers can get to the source of the specific problem they’re trying to solve rather than treating the symptoms of similar problems in the past.

The shift toward objective and methodological investigation also serves to increase the confidence of entire teams to diagnose production issues. In monitoring-based systems, humans are responsible for leaping from tool to tool and correlating observations between them, because the data is pre-aggregated and does not support flexible exploration. If they want to zoom in closer, or ask a new question, they must mentally carry the context when moving from looking at dashboards to reading logs. They must do so once more when moving from logs to looking at a trace, and back again. This context switching is error-prone, exhausting, and often impossible given the inherent incompatibilities and inconsistencies encountered when dealing with multiple sources of data and truth. For example, if you’re responsible for drawing correlations between units like TCP/IP packets and HTTP errors experienced by your app, or resource starvation errors and high memory-eviction rates, your investigation likely has such a high degree of conversion error built in that it might be equally effective to take a random guess.

Observability tools pull high-cardinality, high-dimensionality context from telemetry data into a single location where investigators can easily slice and dice to zoom in, zoom out, or follow breadcrumbs to find definitive answers. Engineers should be able to move through an investigation steadily and confidently, without the distraction of constant context switching. Further, by holding that context within one tool, implicit understandings that were often stitched together by experience and institutional knowledge instead become explicit data about your system. Observability allows critical knowledge to move out of the minds of the most experienced engineers and into a shared reality that can be explored by any engineer as needed. You will see how to unlock these benefits as we explore more detailed features of observability tools throughout this book.

# Conclusion

The monitoring-based debugging methods of using metrics and dashboards in tandem with expert knowledge to triage the source of issues in production is a prevalent practice in the software industry. In the previous era of elementary application architectures with limited data collection, an investigative practice that relies on the experience and intuition of humans to detect system issues made sense, given the simplicity of legacy systems. However, the complexity and scale of the systems underlying modern applications has quickly made that approach untenable.

Observability-based debugging methods offer a different approach. They are designed to enable engineers to investigate any system, no matter how complex, without leaning on experience or intimate system knowledge to generate a hunch. With observability tools, engineers can approach the investigation of any problem methodically and objectively. By interrogating their systems in an open-ended manner, engineers practicing observability can find the source of deeply hidden problems and confidently diagnose issues in production, regardless of their prior exposure to any given system.

Next, let’s look at a concrete experience that ties these concepts together by looking at past lessons learned from scaling an application without observability.
