# Chapter 11. Observability-Driven Development

As a practice, observability fundamentally helps engineers improve their understanding of how the code they’ve written is experienced by end users (typically, in production). However, that should not imply that observability is applicable only after software is released to production. Observability can, and should, be an early part of the software development life cycle. In this chapter, you will learn about the practice of observability-driven development.

We will start by exploring test-driven development, how it is used in the development cycle, and where it can fall short. Then we’ll look at how to use observability in a method similar to test-driven development. We’ll examine the ramifications of doing so, look at various ways to debug your code, and more closely examine the nuances of how instrumentation helps observability. Finally, we’ll look at how observability-driven development can shift observability [left](https://w.wiki/56wf) and help speed up software delivery to production.

# Test-Driven Development

Today’s gold standard for testing software prior to its release in production is [test-driven development](https://w.wiki/Lnw) (TDD). TDD is arguably one of the more successful practices to take hold across the software development industry within the last two decades. TDD has provided a useful framework for shift-left testing that catches, and prevents, many potential problems long before they reach production. Adopted across wide swaths of the software development industry, TDD should be credited with having uplifted the quality of code running production services.

TDD is a powerful practice that provides engineers a clear way to think about software operability. Applications are defined by a deterministic set of repeatable tests that can be run hundreds of times per day. If these repeatable tests pass, the application must be running as expected. Before changes to the application are produced, they start as a set of new tests that exist to verify that the change would work as expected. A developer can then begin to write new code in order to ensure the test passes.

TDD is particularly powerful because tests run the same way every time. Data typically doesn’t persist between test runs; it gets dropped, erased, and re-created from scratch for each run. Responses from underlying or remote systems are stubbed or mocked. With TDD, developers are tasked with creating a specification that precisely defines the expected behaviors for an application in a controlled state. The role of tests is to identify any unexpected deviations from that controlled state so that engineers can then deal with them immediately. In doing so, TDD removes guesswork and provides consistency.

But that very consistency and isolation also limits TDD’s revelations about what is happening with your software in production. Running isolated tests doesn’t reveal whether customers are having a good experience with your service. Nor does passing those tests mean that any errors or regressions could be quickly and directly isolated and fixed before releasing that code back into production.

Any reasonably experienced engineer responsible for managing software running in production can tell you that production environments are anything but consistent. Production is full of interesting deviations that your code might encounter out in the wild but that have been excised from tests because they’re not repeatable, don’t quite fit the specification, or don’t go according to plan. While the consistency and isolation of TDD makes your code tractable, it does not prepare your code for the interesting anomalies that should be surfaced, watched, stressed, and tested because they ultimately shape your software’s behavior when real people start interacting with it.

Observability can help you write and ship better code even before it lands in source control—because it’s part of the set of tools, processes, and culture that allows engineers to find bugs in their code quickly.

# Observability in the Development Cycle

Catching bugs cleanly, resolving them swiftly, and preventing them from becoming a backlog of technical debt that weighs down the development process relies on a team’s ability to find those bugs quickly. Yet, software development teams often hinder their ability to do so for a variety of reasons.

For example, consider that in some organizations, software engineers aren’t responsible for operating their software in production. These engineers merge their code into main, cross their fingers in hopes that this change won’t be one that breaks production, and essentially wait to get paged if a problem occurs. Sometimes they get paged soon after deployment. The deployment is then rolled back, and the triggering changes can be examined for bugs. But more likely, problems aren’t detected for hours, days, weeks, or months after the code is merged. By that time, it becomes extremely difficult to pick out the origin of the bug, remember the context, or decipher the original intent behind why that code was written or why it shipped.

Quickly resolving bugs critically depends on being able to examine the problem *while the original intent is still fresh in the original author’s head*. It will never again be as easy to debug a problem as it was right after it was written and shipped. It only gets harder from there; speed is key. (In older deployment models, you might have merged your changes, waited for a release engineer to perform the release at an unknown time, and then waited for operations engineers on the front line to page a software engineer to fix it—and likely not even the engineer who wrote it in the first place.) The more time that elapses between when a bug is inadvertently shipped and when the code containing that bug is examined for problems, the more time that’s wasted across many humans by several orders of magnitude.

At first glance, the links between observability and writing better software may not be clear. But it is this need for debugging quickly that deeply intertwines the two.

# Determining Where to Debug

Newcomers to observability often make the mistake of thinking that observability is a way to debug your code, similar to using highly verbose logging. While it’s possible to debug your code using observability tools, that is not their primary purpose. Observability operates on the order of *systems*, not on the order of *functions*. Emitting enough detail at the line level to reliably debug code would emit so much output that it would swamp most observability systems with an obscene amount of storage and scale. Paying for a system capable of doing that would be impractical, because it could cost from one to ten times as much as your system itself.

Observability is not for debugging your code logic. *Observability is for figuring out where in your systems to find the code you need to debug.* Observability tools help you by swiftly narrowing down where problems may be occurring. From which component did an error originate? Where is latency being introduced? Where did a piece of this data get munged? Which hop is taking up the most processing time? Is that wait time evenly distributed across all users, or is it experienced by only a subset? Observability helps your investigation of problems pinpoint likely sources.

Often, observability will also give you a good idea of what might be happening in or around an affected component, indicate what the bug might be, or even provide hints as to where the bug is happening: in your code, the platform’s code, or a higher-level architectural object.

Once you’ve identified where the bug lives and some qualities about how it arises, observability’s job is done. From there, if you want to dive deeper into the code itself, the tool you want is a good old-fashioned debugger (for example, the GNU Debugger, GDB) or a newer generation profiler. Once you suspect how to reproduce the problem, you can spin up a local instance of the code, copy over the full context from the service, and continue your investigation. While they are related, the difference between an observability tool and a debugger is an order of scale; like a telescope and a microscope, they may have some overlapping use cases, but they are primarily designed for different things.

This is an example of different paths you might take with debugging versus observability:

- You see a spike in latency. You start at the edge; group by endpoint; calculate average, 90th-, and 99th-percentile latencies; identify a cadre of slow requests; and trace one of them. It shows the timeouts begin at `service3`. You copy the context from the traced request into your local copy of the `service3` binary and attempt to reproduce it in the debugger or profiler.

- You see a spike in latency. You start at the edge; group by endpoint; calculate average, 90th-, and 99th-percentile latencies; and notice that exclusively write endpoints are suddenly slower. You group by database destination host, and note that the slow queries are distributed across some, but not all, of your database primaries. For those primaries, this is happening only to ones of a certain instance type or in a particular AZ. You conclude the problem is not a code problem, but one of infrastructure.

# Debugging in the Time of Microservices

When viewed through this lens, it becomes clear why the rise of microservices is tied so strongly to the rise of observability. Software systems used to have fewer components, which meant they were easier to reason about. An engineer could think their way through all possible problem areas by using only low-cardinality tagging. Then, to understand their code logic, they simply always used a debugger or IDE. But once monoliths started being decomposed into many distributed microservices, the debugger no longer worked as well because it couldn’t hop the network.

###### Note

As a historical aside, the phrase “`strace` for microservices” was an early attempt to describe this new style of understanding system internals before the word “observability” was adapted to fit the needs of introspecting production software systems.

Once service requests started traversing networks to fulfill their functions, all kinds of additional operational, architectural, infrastructural, and other assorted categories of complexity became irrevocably intertwined with the logic bugs we unintentionally shipped and inflicted on ourselves.

In monolithic systems, it’s obvious to your debugger if a certain function slows immediately after code is shipped that modified that function. Now, such a change could manifest in several ways. You might notice that a particular service is getting slower, or a set of dependent services is getting slower, or you might start seeing a spike in timeouts—or the only manifestation might be a user complaining. Who knows.

And regardless of how it manifests, it is likely still incredibly unclear according to your monitoring tooling whether that slowness is being caused by any of the following:

- A bug in your code

- A particular user changing their usage pattern

- A database overflowing its capacity

- Network connection limits

- A misconfigured load balancer

- Issues with service registration or service discovery

- Some combination of the preceding factors

Without observability, all you may see is that all of the performance graphs are either spiking or dipping at the same time.

# How Instrumentation Drives Observability

Observability helps pinpoint the origins of problems, common outlier conditions, which half a dozen or more things must all be true for the error to occur, and so forth. Observability is also ideal for swiftly identifying whether problems are restricted to a particular build ID, set of hosts, instance types, container versions, kernel patch versions, database secondaries, or any number of other architectural details.

However, a necessary component of observability is the creation of useful instrumentation. *Good instrumentation drives observability.* One way to think about how instrumentation is useful is to consider it in the context of pull requests. Pull requests should never be submitted or accepted without first asking yourself, “How will I know if this change is working as intended?”

A helpful goal when developing instrumentation is to create reinforcement mechanisms and shorter feedback loops. In other words, tighten the loop between shipping code and feeling the consequences of errors. This is also known as *putting the software engineers on call*.

One way to achieve this is to automatically page the person who just merged the code being shipped. For a brief period of time, maybe 30 minutes to 1 hour, if an alert is triggered in production, the alert gets routed to that person. When an engineer experiences their own code in production, their ability (and motivation) to instrument their code for faster isolation and resolution of issues naturally increases.

This feedback loop is not punishment; rather, it is *essential* to code ownership. You cannot develop the instincts and practices needed to ship quality code if you are insulated from the feedback of your errors. Every engineer should be expected to instrument their code such that they can answer these questions as soon as it’s deployed:

- Is your code doing what you expected it to do?

- How does it compare to the previous version?

- Are users actively using your code?

- Are any abnormal conditions emerging?

A more advanced approach is to enable engineers to test their code against a small subset of production traffic. With sufficient instrumentation, the best way to understand how a proposed change will work in production is to measure how it will work by deploying it to production. That can be done in several controlled ways. For example, that can happen by deploying new features behind a feature flag and exposing it to only a subset of users. Alternatively, a feature could also be deployed directly to production and have only select requests from particular users routed to the new feature. These types of approaches shorten feedback loops to mere seconds or minutes, rather than what are usually substantially longer periods of time waiting for the release.

If you are capturing sufficient instrumentation detail in the context of your requests, you can systematically start at the edge of any problem and work your way to the correct answer every single time, with no guessing, intuition, or prior knowledge needed. This is one revolutionary advance that observability has over monitoring systems, and it does a lot to move operations engineering back into the realm of science, not magic and intuition.

# Shifting Observability Left

While TDD ensures that developed software adheres to an isolated specification, *observability-driven development* ensures that software works in the messy reality that is a production environment. Now software is strewn across a complex infrastructure, at any particular point in time, experiencing fluctuating workloads, with certain users doing unpredictable things.

Building instrumentation into your software early in the development life cycle allows your engineers to more readily consider and more quickly see the impact that small changes truly have in production. By focusing on just adherence to an isolated specification, teams inadvertently create conditions that block their visibility into the chaotic playground where that software comes into contact with messy and unpredictable people problems. As you’ve seen in previous chapters, traditional monitoring approaches reveal only an aggregate view of measures that were developed in response to triggering alerts for known issues. Traditional tooling provides little ability to accurately reason about what happens in complex modern software systems.

Resulting from the inability to accurately reason about how production operates, teams will often approach production as a glass castle—a beautiful monument to their collective design over time, but one they’re afraid to disturb because any unforeseen movement could shatter the entire structure. By developing the engineering skills to write, deploy, and use good telemetry and observability to understand behaviors in production, teams gain an ability to reason about what really happens in production. As a result, they become empowered to reach further and further into the development life cycle to consider the nuances of detecting unforeseen anomalies that could be roaming around their castles unseen.

Observability-driven development allows engineering teams to turn their glass castles into interactive playgrounds. Production environments aren’t immutable but full of action, and engineers should be empowered to confidently walk into any game and score a win. But that happens only when observability isn’t considered solely the domain of SREs, infrastructure engineers, or operations teams. Software engineers must adopt observability and work it into their development practices in order to unwind the cycle of fear they’ve developed over making any changes to production.

# Using Observability to Speed Up Software Delivery

When software engineers bundle telemetry along with new features headed for production, they can shorten the time between the commit and a feature being released to end users. Patterns like using feature flags and progressive delivery (see [Chapter 4](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch04.html#how_observability_relates_to_devopscomm)) that decouple deployments from releases enable engineers to observe and understand the performance of their new feature as it is slowly released to production.

A common perception in the software industry is that a trade-off usually occurs between speed and quality: you can release software quickly or you can release high-quality software, but not both. A key finding of *Accelerate: Building and Scaling High Performing Technology Organizations* was that this inverse relationship is a myth.[1](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch11.html#ch01fn8) For elite performers, speed and quality go up in tandem and reinforce each other. When speed gets faster, failures become smaller, happen less often, and—when they do happen—are easier to recover from. Conversely, for teams that move slowly, failures tend to happen more often and take substantially longer to recover.

When engineers treat production as a glass castle where they hesitate to tread, they will instinctively and comfortably roll back deployments at the slightest sign of any potential issues. Because they lack the controls to make small tweaks, tune settings, gracefully degrade services, or progressively deploy changes in response to problems they intimately understand, they will instead take their foot off the gas and halt any further deployments or further changes while they roll back the current change they don’t fully understand. That’s the opposite reaction to what would be most helpful in this situation.

The key metric for the health and effectiveness of an engineering team can be best captured by a single metric: the time elapsed from when code is written to when it is in production. Every team should be tracking this metric and working to improve it.

Observability-driven development in tandem with feature flags and progressive delivery patterns can equip engineering teams with the tools they need to stop instinctively rolling back deployments and instead dig in to further investigate what’s really happening whenever issues occur during release of a new feature.

However, this all hinges on your team’s ability to release code to production on a relatively speedy cadence. If that is not how your team currently operates, here are a few ways you can help speed up code delivery to production:

- Ship a single coherent bundle of changes one at a time, one merge by one engineer. The single greatest cause of deployments that break “something” and take hours or days to detangle and roll back is the batching of many changes by many people over many days.

- Spend real engineering effort on your deployment process and code. Assign experienced engineers to own it (not the intern). Make sure everyone can understand your deployment pipelines and that they feel empowered to continuously improve them. Don’t let them be the sole province of a single engineer or team. Instead, get everyone’s usage, buy-in, and contributions. For more tips on making your pipelines understandable for everyone, see [Chapter 14](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch14.html#observability_and_the_software_supply_c).

# Conclusion

Observability can, and should, be used early in the software development life cycle. Test-driven development is a useful tool for examining how your code runs against a defined specification. Observability-driven development is a useful tool for examining how your code behaves in the chaotic and turbulent world of production.

For software engineers, a historical lack of being able to understand how production actually works has created a mindset that treats production like a glass castle. By properly observing the behavior of new features as they are released to production, you can change that mindset so that production instead becomes an interactive playground where you can connect with the way end users experience the software you write.

Observability-driven development is essential to being able to achieve a high-performing software engineering team. Rather than presuming that observability is the sole domain of SREs, infrastructure engineers, and ops teams, all software engineers should embrace observability as an essential part of their practices.

[1](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch11.html#ch01fn8-marker) Nicole Forsgren et al., [Accelerate: Building and Scaling High Performing Technology Organizations](https://oreil.ly/vgne4) (Portland, OR: IT Revolution Press, 2018).
