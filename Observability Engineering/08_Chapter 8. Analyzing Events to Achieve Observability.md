# Chapter 8. Analyzing Events to Achieve Observability

In the first two chapters of this part, you learned about telemetry fundamentals that are necessary to create a data set that can be properly debugged with an observability tool. While having the right data is a fundamental requirement, observability is measured by what you can learn about your systems from that data. This chapter explores debugging techniques applied to observability data and what separates them from traditional techniques used to debug production systems.

We’ll start by closely examining common techniques for debugging issues with traditional monitoring and application performance monitoring tools. As highlighted in previous chapters, traditional approaches presume a fair amount of familiarity with previously known failure modes. In this chapter, that approach is unpacked a bit more so that it can then be contrasted with debugging approaches that don’t require the same degree of system familiarity to identify issues.

Then, we’ll look at how observability-based debugging techniques can be automated and consider the roles that both humans and computers play in creating effective debugging workflows. When combining those factors, you’ll understand how observability tools help you analyze telemetry data to identify issues that are impossible to detect with traditional tools.

This style of hypothesis-driven debugging—in which you form hypotheses and then explore the data to confirm or deny them—is not only more scientific than relying on intuition and pattern matching, but it also democratizes the act of debugging. As opposed to traditional debugging techniques, which favor those with the most system familiarity and experience to quickly find answers, debugging with observability favors those who are the most curious or the most diligent about checking up on their code in production. With observability, even someone with very little knowledge of the system should be able to jump in and debug an issue.

# Debugging from Known Conditions

Prior to observability, system and application debugging mostly occurred by building upon what you know about a system. This can be observed when looking at the way the most senior members of an engineering team approach troubleshooting. It can seem downright magical when they know which questions are the right ones to ask and instinctively know the right place to look. That magic is born from intimate familiarity with their application and systems.

To capture this magic, managers urge their senior engineers to write detailed runbooks in an attempt to identify and solve every possible “root cause” they might encounter out in the wild. In [Chapter 2](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch02.html#how_debugging_practices_differ_between), we covered the escalating arms race of dashboard creation embarked upon to create just the right view that identifies a newly encountered problem. But that time spent creating runbooks and dashboards is largely wasted, because modern systems rarely fail in precisely the same way twice. And when they do, it’s increasingly common to configure an automated remediation that can correct that failure until someone can investigate it properly.

Anyone who has ever written or used a runbook can tell you a story about just how woefully inadequate they are. Perhaps they work to temporarily address technical debt: there’s one recurring issue, and the runbook tells other engineers how to mitigate the problem until the upcoming sprint when it can finally be resolved. But more often, especially with distributed systems, a long thin tail of problems that *almost never happen* are responsible for cascading failures in production. Or, five seemingly impossible conditions will align just right to create a large-scale service failure in ways that might happen only once every few years.

##### On the Topic of Runbooks

The assertion that time spent creating runbooks is largely wasted may seem a bit harsh at first. To be clear, there is a place for documentation meant to quickly orient your team with the needs of a particular service and its jumping-off points. For example, every service should have documentation that contains basic information including which team owns and maintains the service, how to reach the on-call engineer, escalation points, other services this service depends on (and vice versa), and links to good queries or dashboards to understand how this service is performing.

However, maintaining a living document that attempts to contain all possible system errors and resolutions is a futile and dangerous game. That type of documentation can quickly go stale, and *wrong documentation* is perhaps more dangerous than *no documentation*. In fast-changing systems, instrumentation itself is often the best possible documentation, since it combines intention (what are the dimensions that an engineer named and decided to collect?) with the real-time, up-to-date information of live status in production.

Yet engineers typically embrace that dynamic as just the way that troubleshooting is done—because that is how the act of debugging has worked for decades. First, you must intimately understand all parts of the system—whether through direct exposure and experience, documentation, or a runbook. Then you look at your dashboards and then you…intuit the answer? Or maybe you make a guess at the root cause, and then start looking through your dashboards for evidence to confirm your guess.

Even after instrumenting your applications to emit observability data, you might still be debugging from known conditions. For example, you could take that stream of arbitrarily wide events and pipe it to `tail -f` and `grep` it for known strings, just as troubleshooting is done today with unstructured logs. Or you could take query results and stream them to a series of infinite dashboards, as troubleshooting is done today with metrics. You see a spike on one dashboard, and then you start flipping through dozens of other dashboards, visually pattern-matching for other similar shapes.

It’s not just that you’re now collecting event data that enables you to debug unknown conditions. It’s the way you approach the act of instrumentation and debugging.

At Honeycomb, it took us quite some time to figure this out, even after we’d built our own observability tool. Our natural inclination as engineers is to jump straight to what we know about our systems. In Honeycomb’s early days, before we learned how to break away from debugging from known conditions, what observability helped us do was just jump to the right high-cardinality questions to ask.

If we’d just shipped a new frontend feature and were worried about performance, we’d ask, “How much did it change our CSS and JS asset sizes?” Having just written the instrumentation ourselves, we would know to figure that out by calculating maximum `css_asset_size` and `js_asset_size`, then breaking down performance by `build_id`. If we were worried about a new customer who was starting to use our services, we’d ask, “Are their queries fast?” Then we would just know to filter by `team_id` and calculate `p95` response time.

But what happens when you don’t know what’s wrong or where to start looking, and haven’t the faintest idea of what could be happening? When debugging conditions are completely unknown to you, *then* you must instead debug from first principles.

# Debugging from First Principles

As laid out in the previous two chapters, gathering telemetry data as events is the first step. Achieving observability also requires that you unlock a new understanding of your system by analyzing that data in powerful and objective ways. Observability enables you to debug your applications from first principles.

A [first principle](https://w.wiki/56we) is a basic assumption about a system that was not deduced from another assumption. In philosophy, a first principle is defined as the first basis from which a thing is known. To *debug from first principles* is basically a methodology to follow in order to understand a system scientifically. Proper science requires that you do not assume anything. You must start by questioning what has been proven and what you are absolutely sure is true. Then, based on those principles, you must form a hypothesis and validate or invalidate it based on observations about the system.

Debugging from first principles is a core capability of observability. While intuitively jumping straight to the answer is wonderful, it becomes increasingly impractical as complexity rises and the number of possible answers skyrockets. (And it *definitely* doesn’t scale…not everyone can or should have to be a systems wizard to debug their code.)

In Chapters [2](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch02.html#how_debugging_practices_differ_between) and [3](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch03.html#lessons_from_scaling_without_observabil), you saw examples of elusive issues that were incredibly difficult to diagnose. What happens when you don’t know a system’s architecture like the back of your hand? Or what happens when you don’t even know what data is being collected about this system? What if the source of an issue is multicausal: you’re wondering what went wrong, and the answer is “13 different things”?

The real power of observability is that you shouldn’t have to know so much in advance of debugging an issue. You should be able to systematically and scientifically take one step after another, to methodically follow the clues to find the answer, even when you are unfamiliar (or less familiar) with the system. The magic of instantly jumping to the right conclusion by inferring an unspoken signal, relying on past scar tissue, or making some leap of familiar brilliance is instead replaced by methodical, repeatable, verifiable process.

Putting that approach into practice is demonstrated with the core analysis loop.

## Using the Core Analysis Loop

Debugging from first principles begins when you are made aware that something is wrong (we’ll look at alerting approaches that are compatible with observability in [Chapter 12](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch12.html#using_service_level_objectives_for_reli)). Perhaps you received an alert, but this could also be something as simple as receiving a customer complaint: you know that something is slow, but you do not know what is wrong. [Figure 8-1](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch08.html#the_core_analysis_loop) is a diagram representing the four stages of the *core analysis loop*, the process of using your telemetry to form hypotheses and to validate or invalidate them with data, and thereby systematically arrive at the answer to a complex problem.

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492076438/files/assets/oben_0801.png)

###### Figure 8-1. The core analysis loop

The core analysis loop works like this:

1. Start with the overall view of what prompted your investigation: what did the customer or alert tell you?

1. Verify that what you know so far is true: is a notable change in performance happening somewhere in this system? Data visualizations can help you identify changes of behavior as a change in a curve somewhere in the graph.

1. Search for dimensions that might drive that change in performance. Approaches to accomplish that might include:

1. Examining sample rows from the area that shows the change: are there any outliers in the columns that might give you a clue?

1. Slicing those rows across various dimensions looking for patterns: do any of those views highlight distinct behavior across one or more dimensions? Try an experimental `group by` on commonly useful fields, like `status_code`.

1. Filtering for particular dimensions or values within those rows to better expose potential outliers.

1. Do you now know enough about what might be occurring? If so, you’re done! If not, filter your view to isolate this area of performance as your next starting point. Then return to step 3.

This is the basis of debugging from first principles. You can use this loop as a brute-force method to cycle through all available dimensions to identify which ones explain or correlate with the outlier graph in question, with no prior knowledge or wisdom about the system required.

Of course, that brute-force method could take an inordinate amount of time and make such an approach impractical to leave in the hands of human operators alone. An observability tool should automate as much of that brute-force analysis for you as possible.

## Automating the Brute-Force Portion of the Core Analysis Loop

The core analysis loop is a method to objectively find a signal that matters within a sea of otherwise normal system noise. Leveraging the computational power of machines becomes necessary in order to swiftly get down to the bottom of issues.

When debugging slow system performance, the core analysis loop has you isolate a particular area of system performance that you care about. Rather than manually searching across rows and columns to coax out patterns, an automated approach would be to retrieve the values of all dimensions, both inside the isolated area (the anomaly) and outside the area (the system baseline), diff them, and then sort by the difference. Very quickly, that lets you see a list of things that are different in your investigation’s areas of concern as compared to everything else.

For example, you might isolate a spike in request latency and, when automating the core analysis loop, get back a sorted list of dimensions and how often they appear within this area. You might see the following:

- `request.endpoint` with value `batch` is in 100% of requests in the isolated area, but in only 20% of the baseline area.

- `handler_route` with value `/1/markers/` is in 100% of requests in the isolated area, but only 10% of the baseline area.

- `request.header.user_agent` is populated in 97% of requests in the isolated area, but 100% of the baseline area.

At a glance, this tells you that the events in this specific area of performance you care about are different from the rest of the system in all of these ways, whether that be one deviation or dozens. Let’s look at a more concrete example of the core analysis loop by using Honeycomb’s BubbleUp feature.

With Honeycomb, you start by visualizing a heatmap to isolate a particular area of performance you care about. Honeycomb automates the core analysis loop with the BubbleUp feature: you point and click at the spike or anomalous shape in the graph that concerns you, and draw a box around it. BubbleUp computes the values of *all* dimensions both inside the box (the anomaly you care about and want to explain) and outside the box (the baseline), and then compares the two and sorts the resulting view by percent of differences, as shown in [Figure 8-2](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch08.html#a_honeycomb_heatmap_of_event_performanc).

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492076438/files/assets/oben_0802.png)

###### Figure 8-2. A Honeycomb heatmap of event performance during a real incident. BubbleUp surfaces results for 63 interesting dimensions and ranks the results by largest percentage difference.

In this example, we’re looking at an application with high-dimensionality instrumentation that BubbleUp can compute and compare. The results of the computation are shown in histograms using two primary colors: blue for baseline dimensions and orange for dimensions in the selected anomaly area (blue appears as dark gray in the print image, and orange as lighter gray). In the top-left corner (the top results in the sort operation), we see a field named `global.availability_zone` with a value of `us-east-1a` showing up in only 17% of baseline events, but in 98% of anomalous events in the selected area ([Figure 8-3](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch08.html#in_this_close_up_of_the_results_from_th)).

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492076438/files/assets/oben_0803.png)

###### Figure 8-3. In this close-up of the results from [Figure 8-2](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch08.html#a_honeycomb_heatmap_of_event_performanc), the orange bar (light gray in the print image) shows that `global.availability_zone` appears as `us-east-1a` in 98% of events in the selected area, and the blue bar (dark gray) shows that’s the case in only 17% of baseline events.

In this example, you can quickly see that slow-performing events are mostly originating from one particular availability zone (AZ) from our cloud infrastructure provider. The other information automatically surfaced also points out one particular virtual machine instance type that appears to be more affected than others. Other dimensions surfaced, but in this example the differences tended to be less stark, indicating that they were perhaps not as relevant to our investigation.

This information has been tremendously helpful: we now know the conditions that appear to be triggering slow performance. A particular type of instance in one particular AZ is much more prone to very slow performance than other infrastructure we care about. In that situation, the glaring difference pointed to what turned out to be an underlying network issue with our cloud provider’s entire AZ.

Not all issues are as immediately obvious as this underlying infrastructure issue. Often you may need to look at other surfaced clues to triage code-related issues. The core analysis loop remains the same, and you may need to slice and dice across dimensions until one clear signal emerges, similar to the preceding example. In this case, we contacted our cloud provider and were also able to independently verify the unreported availability issue when our customers also reported similar issues in the same zone. If this had instead been a code-related issue, we might decide to reach out to those users, or figure out the path they followed through the UI to see those errors, and fix the interface or the underlying system.

Note that the core analysis loop can be achieved only by using the baseline building blocks of observability, which is to say arbitrarily wide structured events. You cannot achieve this with metrics; they lack the broad context to let you slice and dice and dive in or zoom out in the data. You cannot achieve this with logs unless you have correctly appended all the request ID, trace ID, and other headers, and then done a great deal of postprocessing to reconstruct them into events—and then added the ability to aggregate them at read time and perform complex custom querying.

In other words: yes, an observability tool should automate much of the number crunching for you, but even the manual core analysis loop is unattainable without the basic building blocks of observability. The core analysis loop can be done manually to uncover interesting dimensions. But in this modern era of cheap computing resources, an observability tool should automate that investigation for you. Because debugging from first principles does not require prior familiarity with the system, that automation can be done simply and methodically, without the need to seed “intelligence” about the application being debugged.

That begs a question around how much intelligence should be applied to this number crunching. Is artificial intelligence and machine learning the inevitable solution to all our debugging problems?

# This Misleading Promise of AIOps

Since Gartner coined the term in 2017, *artificial intelligence for operations* (*AIOps*) has generated lots of interest from companies seeking to somehow automate common operational tasks. Delving deeply into[the misleading promise of AIOps](https://thenewstack.io/observability-and-the-misleading-promise-of-aiops) is beyond the scope of this book. But AIOps intersects observability, reducing alert noise and anomaly detection.

In [Chapter 12](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch12.html#using_service_level_objectives_for_reli), we unpack a simpler approach to alerting that makes the need for algorithms to reduce alert noise a moot point. The second intersection, anomaly detection, is the focus of this chapter, so we’ll unpack that in this section.

As seen earlier in this chapter, the concept behind using algorithms to detect anomalies is to select a baseline of “normal” events and compare those to “abnormal” events not contained within the baseline window. Selecting the window in which that’s done can be incredibly challenging for automated algorithms.

Similar to using BubbleUp to draw a box around the area you care about, AI must decide where to draw its own box. If a system behaved consistently over time, anomalies would be worrisome, unusual cases that could be easily detected. In an innovative environment with system behavior that changes frequently, it’s more likely that AI will draw a box of the wrong size. The box will be either too small—identifying a great deal of perfectly normal behavior as anomalies, or too large—miscategorizing anomalies as normal behavior. In practice, both types of mistakes will be made, and detection will be far too noisy or far too quiet.

This book is about the engineering principles needed to manage running production software on modern architectures with modern practices. Any reasonably competitive company in today’s world will have engineering teams frequently deploying changes to production. New feature deployments introduce changes in performance that didn’t previously exist: that’s an anomaly. Fixing a broken build: that’s an anomaly. Introducing service optimizations in production that change the performance curve: that’s an anomaly too.

AI technology isn’t magic. AI can help only if clearly discernible patterns exist and if the AI can be trained to use ever-changing baselines to model its predictions—a training pattern that, so far, has yet to emerge in the AIOps world.

In the meantime, there *is* an intelligence designed to reliably adapt its pattern recognition to ever-changing baselines by applying real-time context to a new problem set: human intelligence. Human intelligence and contextual awareness of a problem to be solved can fill in the gaps when AIOps techniques fall short. Similarly, that adaptive and contextual human intelligence lacks the processing speed achieved by applying algorithms over billions of rows of data.

It’s in observability and automating the core analysis loop that both *human and machine intelligence merge* to get the best of both worlds. Let computers do what they do best: churn through massive sets of data to identify patterns that might be interesting. Let the humans do what they do best: add cognitive context to those potentially interesting patterns that reliably sifts out the signals that matter from the noises that don’t.

Think of it like this: any computer can crunch the numbers and detect a spike, but only a human can attach meaning to that spike. Was it good or bad? Intended or not? With today’s technology, AIOps cannot reliably assign these value judgments for you.

Humans alone can’t solve today’s most complex software performance issues. But neither can computers or vendors touting AIOps as a magical silver bullet. Leveraging the strengths of humans and machines, in a combined approach, is the best and most pragmatic solution in today’s world. Automating the core analysis loop is a prime example of how that can be done.

# Conclusion

Collecting the right telemetry data is only the first step in the journey toward observability. That data must be analyzed according to first principles in order to objectively and correctly identify application issues in complex environments. The core analysis loop is an effective technique for fast fault localization. However, that work can be time-consuming for humans to conduct methodically as a system becomes increasingly complex.

When looking for the sources of anomalies, you can leverage compute resources to quickly sift through very large data sets to identify interesting patterns. Surfacing those patterns to a human operator, who can put them into the necessary context and then further direct the investigation, strikes an effective balance that best utilizes the strengths of machines and humans to quickly drive system debugging. Observability systems are built to apply this type of analysis pattern to the event data you’ve learned how to collect in the previous chapters.

Now that you understand both the types of data needed and the practice of analyzing that data to get fast answers with observability, the next chapter circles back to look at how observability practices and monitoring practices can coexist.
