# Chapter 3. Lessons from Scaling Without Observability

So far, we’ve defined *observability* and how it differs from traditional monitoring. We’ve covered some of the limitations of traditional monitoring tools when managing modern distributed systems and how observability solves them. But an evolutionary gap remains between the traditional and modern world. What happens when trying to scale modern systems without observability?

In this chapter, we look at a real example of slamming into the limitations of traditional monitoring and architectures, along with why different approaches are needed when scaling applications. Coauthor Charity Majors shares her firsthand account on lessons learned from scaling without observability at her former company, [Parse](https://w.wiki/56wb). This story is told from her perspective.

# An Introduction to Parse

Hello, dear reader. I’m Charity, and I’ve been on call since I was 17 years old. Back then, I was racking servers and writing shell scripts at the University of Idaho. I remember the birth and spread of many notable monitoring systems: Big Brother, Nagios, RRDtool and Cacti, Ganglia, Zabbix, and Prometheus. I’ve used most—not quite all—of them. They were incredibly useful in their time. Once I got a handle on TSDBs and their interfaces, every system problem suddenly looked like a nail for the time-series hammer: set thresholds, monitor, rinse, and repeat.

During my career, my niche has been coming in as the first infrastructure engineer (or one of the first) to join an existing team of software engineers in order to help mature their product to production readiness. I’ve made decisions about how best to understand what’s happening in production systems many, many times.

That’s what I did at Parse. Parse was a mobile-backend-as-a-service (MBaaS) platform, providing mobile-app developers a way to link their apps to backend cloud storage systems, and APIs to backend systems. The platform enabled features like user management, push notifications, and integration with social networking services. In 2012, when I joined the team, Parse was still in beta. At that time, the company was using a bit of Amazon CloudWatch and, somehow, was being alerted by five different systems. I switched us over to using Icinga/Nagios and Ganglia because those were the tools I knew best.

Parse was an interesting place to work because it was so ahead of its time in many ways (we would go on to be acquired by Facebook in 2013). We had a microservice architecture before we had the name “microservices” and long before that pattern became a movement. We were using MongoDB as our data store and very much growing up alongside it: when we started, it was version 2.0 with a single lock per replica set. We were developing with Ruby on Rails and we had to monkey-patch Rails to support multiple database shards.

We had complex multitenant architectures with shared tenancy pools. In the early stages, we were optimizing for development speed, full stop.

I want to pause here to stress that optimizing for development speed was *the right thing to do*. With that decision, we made many early choices that we later had to undo and redo. But most start-ups don’t fail because they make the wrong tooling choices. And let’s be clear: most start-ups do fail. They fail because there’s no demand for their product, or because they can’t find product/market fit, or because customers don’t love what they built, or any number of reasons where time is of the essence. Choosing a stack that used MongoDB and Ruby on Rails enabled us to get to market quickly enough that we delighted customers, and they wanted a lot more of what we were selling.

Around the time Facebook acquired Parse, we were hosting over 60,000 mobile apps. Two and a half years later, when I left Facebook, we were hosting over a million mobile apps. But even when I first joined, in 2012, the cracks were already starting to show.

Parse officially launched a couple of months after I joined. Our traffic doubled, then doubled, and then doubled again. We were the darling of Hacker News, and every time a post about us showed up there, we’d get a spike of new sign-ups.

In August of 2012, one of our hosted apps moved into a top 10 spot in the iTunes Store for the first time. The app was marketing a death-metal band from Norway. The band used the app to livestream broadcasts. For the band, this was in the evening; for Parse, it was the crack of dawn. Every time the band livestreamed, Parse went down in seconds flat. We had a scaling problem.

# Scaling at Parse

At first, figuring out what was happening to our services was difficult. Our diagnosis was challenging because (thanks to our co-tenancy model) whenever something got slow, *everything* got slow, even if it had nothing to do with whatever was causing the problem.

Solving that collective set of problems took a lot of trial-and-error tinkering. We had to level up our MongoDB database administration skills. Then, finally, after a lot of work, we figured out the source of the problem. To mitigate that same problem again in the future, we wrote tooling that let us selectively throttle particular apps or rewrite/limit poorly structured queries on the fly. We also generated custom Ganglia dashboards for the user ID of this Norwegian death-metal band so that, in the future, we could swiftly tell whether it was to blame for an outage.

Getting there was tough. But we got a handle on it. We all heaved a collective sigh of relief, but that was only the beginning.

Parse made it easy for mobile-app developers to spin up new apps and quickly ship them to an app store. Our platform was a hit! Developers loved the experience. So, day after day, that’s what they did. Soon, we were seeing new Parse-hosted apps skyrocket to the top of the iTunes Store or the Android Market several times a week. Those apps would do things like use us to send push notifications, save game state, perform complex geolocation queries—the workload was utterly unpredictable. Millions of device notifications were being dumped onto the Parse platform at any time of the day or night, with no warning.

That’s when we started to run into many of the fundamental flaws in the architecture we’d chosen, the languages we were using, and the tools we were using to understand those choices. I want to reiterate: each choice was *the right thing to do*. We got to market fast, we found a niche, and we delivered. Now, we had to figure out how to grow into the next phase.

I’ll pause here to describe some of those decisions we made, and the impact they now had at this scale. When incoming API requests came in, they were load-balanced and handed off to a pool of Ruby on Rails HTTP workers known as [Unicorns](https://w.wiki/56wc). Our infrastructure was in Amazon Web Services (AWS), and all of our Amazon Elastic Compute Cloud (EC2) instances hosted a Unicorn primary, which would fork a couple of dozen Unicorn child processes; those then handled the API requests themselves. The Unicorns were configured to hold a socket open to multiple backends—MySQL for internal user data, Redis for push notifications, MongoDB for user-defined application data, Cloud Code for executing user-provided code in containers server-side, Apache Cassandra for Parse analytics, and so on.

It’s important to note here that Ruby is not a threaded language. So that pool of API workers was a fixed pool. Whenever any one of the backends got just a little bit slower at fulfilling requests, the pool would rapidly fill itself up with pending requests to that backend. Whenever a backend became very slow (or completely unresponsive), the pools would fill up within seconds—and all of Parse would go down.

At first, we attacked that problem by overprovisioning instances: our Unicorns ran at 20% utilization during their normal steady state. That approach allowed us to survive some of the gentler slowdowns. But at the same time, we also made the painful decision to undergo a complete rewrite from Ruby on Rails to Go. We realized that the only way out of this hellhole was to adopt a natively threaded language. It took us over two years to rewrite the code that had taken us one year to write. In the meantime, we were on the bleeding edge of experiencing all the ways that traditional operational approaches were fundamentally incompatible with modern architectural problems.

This was a particularly brutal time all around at Parse. We had an experienced operations engineering team doing all the “right things.” We were discovering that the best practices we all knew, which were born from using traditional approaches, simply weren’t up to the task of tackling problems in the modern distributed microservices era.

At Parse, we were all-in on infrastructure as code. We had an elaborate system of Nagios checks, PagerDuty alerts, and Ganglia metrics. We had tens of thousands of Ganglia graphs and metrics. But those tools were failing us because they were valuable only when we already knew what the problem was going to be—when we knew which thresholds were good and where to check for problems.

For instance, TSDB graphs were valuable when we knew which dashboards to carefully curate and craft—if we could predict which custom metrics we would need in order to diagnose problems. Our logging tools were valuable when we had a pretty good idea of what we were looking for—if we’d remembered to log the right things in advance, and if we knew the right regular expression to search for. Our application performance management (APM) tools were great when problems manifested as one of the top 10 bad queries, bad users, or bad endpoints that they were looking for.

But we had a whole host of problems that those solutions couldn’t help us solve. That previous generation of tools was falling short under these circumstances:

- Every other day, we had a brand-new user skyrocketing into the top 10 list for one of the mobile-app stores.

- Load coming from any of the users identified in any of our top 10 lists wasn’t the cause of our site going down.

- The list of slow queries were all just symptoms of a problem and not the cause (e.g., the read queries were getting slow because of a bunch of tiny writes, which saturated the lock collectively while individually returning almost instantly).

- We needed help seeing that our overall site reliability was 99.9%, but that 0.1% wasn’t evenly distributed across all users. That 0.1% meant that just one shard was 100% down, and it just happened to be the shard holding all data that belonged to a famed multibillion-dollar entertainment company with a mousey mascot.

- Every day, a new bot account might pop up and do things that would saturate the lock percentage on our MySQL primary.

These types of problems are all categorically different from the last generation of problems: the ones for which that set of tools was built. Those tools were built for a world where predictability reigned. In those days, production software systems had “the app”—with all of its functionality and complexity contained in one place—and “the database.” But now, scaling meant that we blew up those monolithic apps into many services used by many different tenants. We blew up the database into a diverse range of many storage systems.

At many companies, including Parse, our business models turned our products into platforms. We invited users to run any code they saw fit to run on our hosted services. We invited them to run any query they felt like running against our hosted databases. And in doing so, suddenly, all of the control we had over our systems evaporated in a puff of market dollars to be won.

In this era of services as platforms, our customers love how powerful we make them. That drive has revolutionized the software industry. And for those of us running the underlying systems powering those platforms, it meant that everything became massively—and exponentially—harder not just to operate and administer, but also to *understand*.

How did we get here, and when did the industry seemingly change overnight? Let’s look at the various small iterations that created such a seismic shift.

# The Evolution Toward Modern Systems

In the beginning—back in those early days of the dot-com era—there was “the app” and “the database.” They were simple to understand. They were either *up* or *down*. They were either slow or not slow. And we had to monitor them for aliveness and acceptable responsiveness thresholds.

That task was not always simple. But, operationally, it was straightforward. For quite some time, we even centered around a pinnacle of architectural simplicity. The most popular architectural pattern was the LAMP stack: Linux, Apache, MySQL, and PHP or Python. You’ve probably heard this before, and I feel obligated to say it again now: *if you can solve your problem with a LAMP stack (or equivalent), you probably should*.

When architecting a service, the first rule is to not *add unnecessary complexity*. You should carefully identify the problems you need to solve, and solve *only those problems*. Think carefully about the options you need to keep open, and keep those options open. Therefore, most of the time, you should choose [boring technology](https://mcfunley.com/choose-boring-technology). Don’t confuse boring with bad. Boring technology simply means that its edge cases and failure scenarios are well understood by many people.

However, with the demands of today’s users, more of us are discovering that many of the problems we need to solve cannot be solved by the humble-yet-mighty LAMP stack. This could be the case for a multitude of reasons. You might have higher reliability needs requiring resiliency guarantees that a LAMP stack can’t provide. Maybe you have too much data or data that’s too complex to be well served by a LAMP stack. Usually, we reach the edges of that simple architectural model in service of scale, reliability, or speed—that’s what drives us to shard, partition, or replicate our stacks.

The way we manage our code also matters. In larger or more complex settings, the monorepo creates organizational pressures that can drive technical change. Splitting up a code base can create clearer areas of ownership in ways that allow an organization to move more swiftly and autonomously than it could if everyone was contributing to The One Big App.

These types of needs—and more—are part of what has driven modern shifts in systems architecture that are clear and pronounced. On a technical level, these shifts include several primary effects:

- The decomposition of everything, from one to many

- The need for a variety of data stores, from one database to many storage systems

- A migration from monolithic applications toward many smaller microservices

- A variety of infrastructure types away from “big iron” servers toward containers, functions, serverless, and other ephemeral, elastic resources

These technical changes have also had powerful ripple effects at the human and organizational level: our systems are *sociotechnical*. The complexity introduced by these shifts at the social level (and their associated feedback loops) have driven further changes to the systems and the way we think about them.

Consider some of the prevalent social qualities we think of in conjunction with the computing era during the LAMP stack’s height of popularity. A tall organizational barrier existed between operations and development teams, and from time to time, code would get lobbed over that wall. Ops teams notoriously resisted introducing changes to production systems. Deploying changes led to unpredictable behavior that could often lead to downtime. So they’d prevent developers from ever directly touching production—tending closely to their uptime. In that type of “glass castle” approach, deployment freezes were a commonly used method for keeping production services stable.

In the LAMP stack era, that protective approach to production wasn’t entirely wrong either. Back then, much of the chaos in production systems was indeed inflicted when introducing bad code. When new code was deployed, the effects were pretty much binary: the site was up or it was down (maybe, sometimes if you were unlucky, it had a third state: inexplicably slow).

Very few architectural constructs (which are commonplace today) existed back then to control the side effects of dealing with bad code. There was no such thing as a graceful degradation of service. If developers introduced a bug to a small, seemingly trivial system component (for example, export functionality), it might crash the entire system every time someone used it. No mechanisms were available to temporarily disable those turns-out-not-so-trivial subcomponents. It wasn’t possible to fix just that one broken subsystem while the rest of the service ran unaffected. Some teams would attempt to add that sort of granular control to their monoliths. But that path was so fraught and difficult that most didn’t even try.

Regardless, many of those monolithic systems continued to get bigger. As more and more people tried to collaborate on the same paths, problems like lock contention, cost ceilings, and dynamic resource needs became showstoppers. The seismic shift from one to many became a necessity for these teams. Monoliths were quickly decomposed into distributed systems and, with that shift, came second-order effects:

- The binary simplicity of service availability as up or down shifted to complex availability heuristics to represent any number of partial failures or degraded availability.

- Code deployments to production that had relatively simple deployment schemes shifted toward progressive delivery.

- Deployments that immediately changed code paths and went live shifted to promotion schemes where code deployments were decoupled from feature releases (via feature flags).

- Applications that had one current version running in production shifted toward typically having multiple versions baking in production at any given time.

- Having an in-house operations team running your infrastructure shifted toward many critical infrastructure components being run by other teams at other companies abstracted behind an API, where they may not even be accessible to you, the developer.

- Monitoring systems that worked well for alerting against and troubleshooting previously encountered known failures shifted to being woefully inadequate in a distributed world, where unknown failures that had never been previously encountered (and may never be encountered again) were the new type of prevalent problem.

###### Note

*Progressive delivery*, a term coined by RedMonk cofounder James Governor, refers to a basket of skills and technologies concerned with controlled, partial deployment of code or changes made to production (for example, canarying, feature flags, blue/green deploys, and rolling deploys).

The tools and techniques needed to manage monolithic systems like the LAMP stack were radically ineffective for running modern systems. Systems with applications deployed in one “big bang” release are managed rather differently than microservices. With microservices, applications are often rolled out piece by piece, and code deployments don’t necessarily release features because feature flags now enable or disable code paths with no deployment required.

Similarly, in a distributed world, staging systems have become less useful or reliable than they used to be. Even in a monolithic world, replicating a production environment to staging was always difficult. Now, in a distributed world, it’s effectively impossible. That means debugging and inspection have become ineffective in staging, and we have shifted to a model requiring those tasks to be accomplished in production itself.

# The Evolution Toward Modern Practices

The technical and social aspects of our systems are interrelated. Given these sociotechnical systems, the emphasis on shifting our technology toward different performance models also requires a shift in the models that define the ways our teams perform.

Furthermore, these shifts are so interrelated that it’s impossible to draw a clean boundary between them. Many of the technology shifts described in the preceding section influenced how teams had to reorganize and change practices in order to support them.

In one area, however, a radical shift in social behavior is absolutely clear. The evolution toward modern distributed systems also brings with it third-order effects that change the relationship that engineers must have with their production environment:

- User experience can no longer be generalized as being the same for all service users. In the new model, different users of a service may be routed through the system in different ways, using different components, providing experiences that can vary widely.

- Monitoring alerts that look for edge cases in production that have system conditions exceeding known thresholds generate a tremendous number of false positives, false negatives, and meaningless noise. Alerting has shifted to a model in which fewer alerts are triggered, by focusing only on symptoms that directly impact user experience.

- Debuggers can no longer be attached to one specific runtime. Fulfilling service requests now requires hopping across a network, spanning multiple runtimes, often multiple times per individual request.

- Known recurring failures that require manual remediation and can be defined in a runbook are no longer the norm. Service failures have shifted from that model toward one in which known recurring failures can be recovered automatically. Failures that cannot be automatically recovered, and therefore trigger an alert, likely mean the responding engineer will be facing a novel problem.

These tertiary signals mean that a massive gravitational shift in focus is happening away from the importance of preproduction and toward the importance of being intimately familiar with production. Traditional efforts to harden code and ensure its safety *before* it goes to production are starting to be accepted as limiting and somewhat futile. Test-driven development and running tests against staging environments still have use. But they can never replicate the wild and unpredictable nature of how that code will be used in production.

As developers, we all have a fixed number of cycles we can devote to accomplishing our work. The limitation of the traditional approach is that it focuses on preproduction hardening first and foremost. Any leftover scraps of attention, if they even exist, are then given to focusing on production systems. If we want to build reliable services in production, that ordering must be reversed.

In modern systems, we *must* focus the bulk of our engineering attention and tooling on production systems, first and foremost. The leftover cycles of attention should be applied to staging and preproduction systems. There is value in staging systems. But it is secondary in nature.

Staging systems are not production. They can never replicate what is happening in production. The sterile lab environment of preproduction systems can never mimic the same conditions under which real paying users of your services will test that code in the real world. Yet many teams still treat production as a glass castle.

Engineering teams must reprioritize the value of production and change their practices accordingly. By not shifting production systems to their primary focus, these teams will be relegated to toiling away on production systems with subpar tooling, visibility, and observability. They will continue to treat production as a fragile environment where they hesitate to tread—instinctively and comfortably rolling back deployments at the slightest sight of potential issues—because they lack the controls to make small tweaks, tune settings, gently degrade services, or progressively deploy changes in response to problems they intimately understand.

The technological evolution toward modern systems also brings with it a social evolution that means engineering teams must change their relationship with production. Teams that do not change that relationship will more acutely suffer the pains of not doing so. The sooner that production is no longer a glass castle in modern systems, the sooner the lives of the teams responsible for those systems—and the experience of the customers using them—will improve.

# Shifting Practices at Parse

At Parse, we had to undergo those changes rather painfully as we worked to quickly scale. But those changes didn’t happen overnight. Our traditional practices were all we knew. Personally, I was following the well-known production system management path I had used at other companies many times before.

When novel problems happened, as with the Norwegian death-metal band, I would dive in and do a lot of investigation until the source of the problem was discovered. My team would run a retrospective to dissect the issue, write a runbook to instruct our future selves on how to deal with it, craft a custom dashboard (or two) that would surface that problem instantly next time, and then move on and consider the problem resolved.

That pattern works well for monoliths, where truly novel problems are rare. It worked well in the earliest days at Parse. But that pattern is completely ineffective for modern systems, where truly novel problems are likely to be the bulk of all the problems encountered. Once we started encountering a barrage of categorically different problems on a daily basis, the futility of that approach became undeniable. In that setting, all the time we spent on restrospectives, creating runbooks, and crafting custom dashboards was little more than wasted time. We would never see those same problems again.

The reality of this traditional approach is that so much of it involves guessing. In other systems, I had gotten so good at guessing what might be wrong that it felt almost effortless. I was intuitively in tune with my systems. I could eyeball a complex set of dashboards and confidently tell my team, “The problem is Redis,” even though Redis was represented nowhere on that screen. I took pride in that sort of technical intuition. It was fun! I felt like a hero.

I want to underline this aspect of hero culture in the software industry. In monolithic systems, with LAMP-stack-style operations, the debugger of last resort is generally the person who has been there the longest, who built the system from scratch. The engineer with the most seniority is the ultimate point of escalation. They have the most scar tissue and the largest catalog of outages in their mental inventory, and they are the ones who inevitably swoop in to save the day.

As a result, these heroes also can never take a real vacation. I remember being on my honeymoon in Hawaii, getting paged at 3 a.m. because MongoDB had somehow taken down the Parse API service. My boss, the CTO, was overwhelmingly apologetic. But the site was down. It had been down for over an hour, and no one could figure out why. So they paged me. Yes, I complained. But also, deep down, it secretly felt great. I was *needed*. I was necessary.

If you’ve ever been on call to manage a production system, you might recognize that pattern. Hero culture is terrible. It’s not good for the company. It’s not good for the hero (it leads to savage burnout). It’s horribly discouraging for every engineer who comes along later and feels they have no chance of ever being the “best” debugger unless a more senior engineer leaves. That pattern is completely unnecessary. But most important, it *doesn’t scale*.

At Parse, to address our scaling challenges, we needed to reinvest the precious time we were effectively wasting by using old approaches to novel problems. So many of the tools that we had at that time—and that the software industry still relies on—were geared toward pattern matching. Specifically, they were geared toward helping the expert-level and experienced engineer pattern-match previously encountered problems to newer variants on the same theme. I never questioned that because it was the best technology and process we had.

After Facebook acquired Parse in 2013, I came to discover Scuba, the data management system Facebook uses for most real-time analysis. This fast, scalable, distributed, in-memory database ingests millions of rows (events) per second. It stores live data completely in memory and aggregates it across hundreds of servers when processing queries. My experience with it was rough. I thought Scuba had an aggressively ugly, even hostile, user experience. But it did one thing extremely well that permanently changed my approach to troubleshooting a system: it let me slice and dice data, in near real time, on dimensions of infinitely high cardinality.

We started sending some of our application telemetry data sets into Scuba and began experimenting with its analytical capabilities. The time that it took us to discover the source of novel problems dropped dramatically. Previously, with the traditional pattern-matching approach, it would take us days—or possibly never?—to understand what was happening. With real-time analytics that could be arbitrarily sliced and diced along any dimension of high cardinality, that time dropped to mere minutes—possibly seconds.

We could investigate a novel problem by starting with the symptoms and following a “trail of breadcrumbs” to the solution, no matter where it led, no matter whether it was the first time we had experienced that problem. We didn’t have to be familiar with the problem in order to solve it. Instead, we now had an analytical and repeatable method for asking a question, getting answers, and using those answers to ask the next question until we got to the source. Troubleshooting issues in production meant starting with the data and relentlessly taking one methodical step after another until we arrived at a solution.

That newfound ability irrevocably shifted our practices. Rather than relying on intricate knowledge and a catalog of outages locked up in the mental inventory of individual engineers—inaccessible to their teammates—we now had data and a methodology that was visible and accessible by everyone in a shared tool. For the team, that meant we could follow each other’s footsteps, retrace each other’s paths, and understand what others were thinking. That ability freed us from the trap of relying on tools geared toward pattern matching.

With metrics and traditional monitoring tools, we could easily see performance spikes or notice that a problem might be occurring. But those tools didn’t allow us to arbitrarily slice, dice, and dig our way down our stack to identify the source of problems or see correlations among errors that we had no other possible way of discovering. Those tools also required us to predict what data might be valuable in advance of investigating a novel problem (as if we knew which questions we would need to ask before the novel problem ever presented itself). Similarly, with logging tools, we had to remember to log anything useful in advance—and know exactly what to search for when that was relevant to the investigation. With our APM tools, we could quickly see problems that our tool vendor predicted would be the most useful to know, but that did very little when novel problems were the norm.

Once we made that paradigm shift, the best debugger was no longer the person who had been there the longest. The best debugger became whoever was the most curious, the most persistent, and the most literate with our new analytical tools. This effectively democratized access to our system and the shared wisdom of its engineers.

By approaching every problem as novel, we could determine what was truly happening anytime an issue arose in production instead of simply pattern-matching it to the nearest analogous previous problem. That made it possible to effectively troubleshoot systems that presented the biggest challenges with a traditional approach.

We could now quickly and effectively diagnose problems with the following:

- Microservices and requests that spanned multiple runtimes.

- Polyglot storage systems, without requiring expertise in each.

- Multitenancy and running both server-side code and queries; we could easily drill down into individual user experiences to see exactly what was happening.

Even with our few remaining monolithic systems that used boring technology, where all possible problems were pretty well understood, we still experienced some gains. We didn’t necessarily discover anything new, but we were able to ship software more swiftly and confidently as a result.

At Parse, what allowed us to scale our approach was learning how to work with a system that was *observable*. By gathering application telemetry, at the right level of abstraction, aggregated around the user’s experience, with the ability to analyze it in real time, we gained magical insights. We removed the limitations of our traditional tools once we had the capability to ask any question, trace any sequence of steps, and understand any internal system state, simply by observing the outputs of our applications. We were able to modernize our practices once we had *observability*.

# Conclusion

This story, from my days at Parse, illustrates how and why organizations make a transition from traditional tools and monitoring approaches to scaling their practices with modern distributed systems and observability. I departed Facebook in 2015, shortly before it announced the impending shutdown of the Parse hosting service. Since then, many of the problems my team and I faced in managing modern distributed systems have only become more common as the software industry has shifted toward adopting similar technologies.

Liz, George, and I believe that shift accounts for the enthusiasm behind, and the rise in popularity of, observability. Observability is the solution to problems that have become prevalent when scaling modern systems. In further chapters, we’ll explore the many facets, impacts, and benefits that observability delivers.
