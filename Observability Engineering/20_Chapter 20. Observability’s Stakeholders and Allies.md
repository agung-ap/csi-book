# Chapter 20. Observability’s Stakeholders and Allies

Most of this book has focused on introducing the practice of observability to software engineering teams. But when it comes to organization-wide adoption, engineering teams cannot, and should not, go forward alone. Once you’ve instrumented rich wide events, your telemetry data set contains a treasure trove of information about your services’ behavior in the marketplace.

Observability’s knack for providing fast answers to any arbitrary question means it can also fill knowledge gaps for various nonengineering stakeholders across your organization. A successful tactic for spreading a culture of observability is to build allies in engineering-adjacent teams by helping them address those gaps. In this chapter, you’ll learn about engineering-adjacent use cases for observability, which teams are likely adoption allies, and how helping them can help you build momentum toward making observability a core part of organizational practices.

# Recognizing Nonengineering Observability Needs

Engineering teams have a constellation of tools, practices, habits, goals, aspirations, responsibilities, and requirements that combine in ways that deliver value to their customers. Some engineering teams may focus more on software development, while others may be more operationally focused. While different engineering teams have different specializations, creating an excellent customer experience for people using your company’s software is never “someone else’s job.” That’s a shared responsibility, and it’s everyone’s job.

Observability can be thought of similarly. As you’ve seen in this book, observability is a lens that quickly shows you the discrepancies between how you *think* your software should behave, or how you *declare* that your software should behave (in code, documentation, knowledge bases, blog posts, etc.), and how it *actually* behaves in the hands of real users. With observability, you can understand, at any given point in time, your customers’ experience of using your software in the real world. It’s everyone’s job to understand and improve that experience.

The need for observability is recognized by engineering teams for a variety of reasons. Functional gaps may exist for quite some time before they’re recognized, and a catalytic event may spur the need for change—often, a critical outage. Or perhaps the need is recognized more proactively, such as realizing that the constant firefighting that comes with chasing elusive bugs is stifling a development team’s ability to innovate. In either case, a supporting business case exists that drives an observability adoption initiative.

Similarly, when it comes to observability adoption for nonengineering teams, you must ask yourself which business cases it can support. Which business cases exist for understanding, at any given point in time, your customers’ experience using your software in the real world? Who in your organization needs to understand and improve customer experience?

Let’s be clear: not every team will specialize in observability. Even among engineering teams that do specialize in it, some will do far more coding and instrumentation than others. But almost everyone in your company has a stake in being able to query your observability data to analyze details about the current state of production.

Because observability allows you to arbitrarily slice and dice data across various dimensions, you can use it to understand the behaviors of individual users, groups of users, or the entire system. Those views can be compared, contrasted, or further mined to answer any combination of questions that are extremely relevant to nonengineering business units in your organization.

Some business use cases that are supported by observability might include:

- Understanding the adoption of new features. Which customers are using your newly shipped features? Does that match the list of customers who expressed interest in it? In what ways do usage patterns of active feature users differ from those who tried it but later abandoned the experience?

- Finding successful product usage trends for new customers. Does the sales team understand which combination of features seems to resonate with prospects who go on to become customers? Do you understand the product usage commonalities in users that failed to activate your product? Do those point to friction that needs to be eroded somehow?

- Accurately relaying service availability information to both customers and internal support teams via up-to-date service status pages. Can you provide templated queries so that support teams can self-serve when users report outages?

- Understanding both short-term and long-term reliability trends. Is reliability improving for users of your software? Does the shape of that reliability graph match other sources of data, like customer complaints? Are you experiencing fewer outages or more? Are those outages recovering more slowly?

- Resolving issues proactively. Are you able to find and resolve customer-impacting issues before they are reported by a critical mass of customers via support tickets? Are you proactively resolving issues, or are you relying on customers to find them for you?

- Shipping features to customers more quickly and reliably. Are deployments to production being closely watched to spot performance anomalies and fix them? Can you decouple deployments from releases so that shipping new features is less likely to cause widespread outages?

In your company, understanding and improving customer experience should be everyone’s job. You can recognize a need for observability for nonengineering teams by asking yourself who cares about your application’s availability, the new features being shipped to customers, usage trends within your products, and customer experience of the digital services you offer.

The best way to further your organization-wide observability adoption initiative is to reach out to adjacent teams that could benefit from this knowledge. With observability, you can enable everyone in your organization, regardless of their technical ability, to work with that data comfortably and to feel comfortable talking about it in ways that enable them to make informed decisions about building better customer experiences.

In other words, democratize your observability data. Let everyone see what’s happening and how your software behaves in the hands of real users. Just as with any other team that is onboarded, you may have to provide initial guidance and tutoring to show them how to get answers to their questions. But soon you’ll discover that each adjacent team will bring its own unique set of perspectives and questions to the table.

Work with stakeholders on adjacent teams to ensure that their questions can be answered. If their questions can’t be answered today, could they be answered tomorrow by adding new custom instrumentation? Iterating on instrumentation with adjacent stakeholders will also help engineering teams get a better understanding of questions relevant to other parts of the business. This level of collaboration presents the kind of learning opportunities that help erode communication silos.

Similar to security and testability, observability must be approached as an ongoing practice. Teams practicing observability must make a habit of ensuring that any changes to code are bundled with proper instrumentation, just as they’re bundled with tests. Code reviews should ensure that the instrumentation for new code achieves proper observability standards, just as they ensure it also meets security standards. These reviews should also ensure that the needs of nonengineering business units are being addressed when instrumentation to support business functions is added to their codebase.

Observability requires ongoing care and maintenance, but you’ll know that you’ve achieved an adequate level of observability by looking for the cultural behaviors and key results outlined in this chapter.

# Creating Observability Allies in Practice

Now that you’ve learned how to recognize knowledge gaps where observability can help solve business problems, the next step is working with various stakeholders to show them how that’s done. Your observability adoption efforts will most likely start within engineering before spreading to adjacent teams (e.g., support) by the nature of shared responsibilities and workflows. With a relatively small bit of work, once your adoption effort is well underway, you can reach out to other stakeholders—whether in finance, sales, marketing, product development, customer success, the executive team, or others—to show them what’s possible to understand about customer use of your applications in the real world.

By showing them how to use observability data to further their own business objectives, you can convert passive stakeholders into allies with an active interest in your adoption project. Allies will help actively bolster and prioritize needs for your project, rather than passively observing or just staying informed of your latest developments.

No universal approach to how that’s done exists; it depends on the unique challenges of your particular business. But in this section, we’ll look at a few examples of creating organizational allies who support your adoption initiatives by applying observability principles to their daily work.

## Customer Support Teams

Most of this book has been about engineering practices used to debug production applications. Even when following a DevOps/SRE model, many sufficiently large organizations will have at least one separate team that handles frontline customer support issues including general troubleshooting, maintenance, and providing assistance with technical questions.

*Customer support teams* usually need to know about system issues before engineering/operations teams are ready to share information. When an issue first occurs, your customers notice. Generally, they’ll refresh their browser or retry their transactions long before calling support. During this buffer, auto-remediations come in handy. Ideally, issues are experienced as small blips by your customers. But when persistent issues occur, the engineer on call must be paged and mobilized to respond. In the meantime, it’s possible some customers are noticing more than just a blip.

With traditional monitoring, several minutes may pass before an issue is detected, the on-call engineer responds and triages an issue, an incident is declared, and a dashboard that the support team sees gets updated to reflect that a known issue is occurring within your applications. In the meantime, the support team may be hearing about customer issues manifesting in several ways and blindly piling up trouble tickets that must later be sifted through and manually resolved.

Instead, with observability, support teams have a few options. The easiest and simplest is to glance at your SLO dashboards to see if any customer-impacting issues have been detected (see [Chapter 12](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch12.html#using_service_level_objectives_for_reli)). While this may be more granular than traditional monitoring and provide useful feedback sooner, it’s far from perfect. Modern systems are modular, resilient, and self-healing, which means that outages are rarely binary: they look less like your entire site being up or down, and more like your “shopping cart checkout breaking 50% of the time for Android users in Europe” or “only customers with our new ACL feature enabled see a partial failure.”

Enabling your support team members to debug issues reported by customers with observability can help them take a more proactive approach. How do transactions for this specific customer with customer ID 5678901 look right now? Have they been using the shopping cart feature on an Android device in Europe? Do they have access control lists (ACLs) enabled? The support team can quickly confirm or deny that support requests coming in are related to known issues and triage appropriately. Or, given a sufficient level of savvy and training with your observability tooling, the team can help identify new issues that may not be automatically detected—such as using an SLI with insufficient parameters.

## Customer Success and Product Teams

In product-led organizations, it’s increasingly common to find customer success teams. Whereas support is a reactive approach to assisting customers with issues, *customer success teams* take a more proactive approach to helping customers avoid problems by using your product effectively. This team often provides assistance with things like onboarding, planning, training, assisting with upgrades, and more.

Both customer support and customer success teams hear the most direct customer feedback in their day-to-day work. They know which parts of your applications people complain about the most. But are those loudest squeaky wheels actually the parts of the customer journey that matter for overall success?

For example, you may have recently released a new feature that isn’t seeing much uptake from customers. Why? Are users using this feature as a live demo and just kicking the proverbial tires? Or are they using it as part of your product’s workflow? When and how is that feature called, with which parameters? And in which sequence of events?

The type of event data captured by an observability solution is useful to understand product usage, which is immensely useful to product teams. Both product and customer success teams have a vested interest in understanding how your company’s software behaves when operated by real customers. Being able to arbitrarily slice and dice your observability data across any relevant dimensions to find interesting patterns means that its usefulness extends well beyond just supporting availability and resiliency concerns in production.

Further, when certain product features are deprecated and a sunset date is set, success teams with observability can see which users are still actively using features that will soon be retired. They can also gauge if new features are being adopted and proactively help customers who may be impacted by product retirement timelines, but who have prioritized dealing with other issues during monthly syncs.

Success teams can also learn which traits are likely to signal activation with new product features by analyzing current usage patterns. Just as you can find performance outliers in your data, you can use observability to find adoption outliers in your performance data. Arbitrarily slicing and dicing your data across any dimension means you can do things like comparing users who made a particular request, more than a particular number of times, against users who did not. What separates those users?

For example, you could discover that a main difference for users who adopt your new analytics feature is that they are also 10 times more likely to create custom reports. If your goal is to boost adoption of the analytics feature, the success team can respond by creating training material that shows customers why and how they would use analytics that include in-depth walk-throughs of creating custom reports. They can also measure the efficacy of that training before and after workshops to gauge whether it’s having the desired effect.

## Sales and Executive Teams

*Sales teams* are also helpful allies in your observability adoption efforts. Depending on how your company is structured, engineering and sales teams may not frequently interact in their daily work. But sales teams are one of the most powerful allies you can have in driving observability adoption. Sales teams have a vested interest in understanding and supporting product features that sell.

Anecdotally, the sales team will pass along reactions received during a pitch or a demo to build a collective understanding of what’s resonating in your product. Qualitative understandings are useful to spot trends and form hypotheses about how to further sales goals. But the types of quantitative analyses this team can pull from your observability data are useful to inform and validate sales execution strategy.

For example, which customers are using which features and how often? Which features are most heavily used and therefore need the highest availability targets? Which features are your strategic customers most reliant upon, when, and in which parts of their workflows? Which features are used most often in sales demos and should therefore always be available? Which features are prospects most interested in, have a wow-factor, and should always be performing fastest?

These types of questions, and more, can be answered with your observability data. The answers to these questions are helpful for sales, but they’re also core to key business decisions about where to make strategic investments.

*Executive stakeholders* want to definitively understand how to make the biggest business impacts, and observability data can help. What is the most important thing your digital business needs to do this year? For example, which engineering investments will drive impacts with sales?

A traditional top-down control-and-command approach to express strategic business goals for engineering may be something vague—for example, get as close to 100% availability as possible—yet it often doesn’t connect the dots on how or why that’s done. Instead, by using observability data to connect those dots, goals can be expressed in technical terms that drill down through user experience, architecture, product features, and the teams that use them. Defining goals clearly with a common cross-cutting language is what actually creates organizational alignment among teams. Where exactly are you making investments? Who will that impact? Is an appropriate level of engineering investment being made to deliver on your availability and reliability targets?

# Using Observability Versus Business Intelligence Tools

Some of you may have read the earlier sections and asked yourself whether a business intelligence (BI) tool could accomplish the same job. Indeed, the types of understanding of various moving parts of your company that we’re describing are a bit of a quasi-BI use case. Why would you not just use a BI tool for that?

It can be hard to generalize about BI tools, as they consist of online analytical processing (OLAP), mobile BI, real-time BI, operational BI, location intelligence, data visualization and chart mapping, tools for building dashboards, billing systems, ad hoc analysis and querying, enterprise reporting, and more. You name the data, and a tool somewhere is optimized to analyze it. It’s also hard to generalize characteristics of the data warehouses that power these tools, but we can at least say those are nonvolatile and time-variant, and contain raw data, metadata, and summary data.

But whereas BI tools are all very generalized, observability tools are hyper-specialized for a particular use case: understanding the intersection of code, infrastructure, users, and time. Let’s take a look at some of the trade-offs made by observability tooling.

## Query Execution Time

Observability tools need to be fast, with queries ranging from subsecond to low seconds. A key tenet of observability is explorability, since you don’t always know what you’re looking for. You spend less time running the same queries over and over, and more time following a trail of breadcrumbs. During an investigative flow, disruptions when you have to sit and wait for a minute or longer for results can mean you lose your entire train of thought.

In comparison, BI tools are often optimized to run reports, or to craft complex queries that will be used again and again. It’s OK if these take longer to run, because this data isn’t being used to react in real time, but rather to feed into other tools or systems. You typically make decisions about steering the business over time measured in weeks, months, or years, not minutes or seconds. If you’re making strategic business decisions every few seconds, something has gone terribly wrong.

## Accuracy

For observability workloads, if you have to choose, it’s better to return results that are fast as opposed to perfect (as long as they are very close to correct). For iterative investigations, you would almost always rather get a result that scans 99.5% of the events in one second than a result that scans 100% in one minute. This is a real and common trade-off that must be made in massively parallelized distributed systems across imperfect and flaky networks (see [Chapter 16](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch16.html#efficient_data_storage)).

Also (as covered in [Chapter 17](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch17.html#cheap_and_accurate_enough_sampling)), some form of dynamic sampling is often employed to achieve observability at scale. Both of these approaches trade a slight bit of accuracy for massive gains in performance. When it comes to BI tools and business data warehouses, both sampling and a “close to right” approach are typically verboten. When it comes to billing, for example, you will always want the accurate result no matter how long it takes.

## Recency

The questions you answer with observability tools have a strong recency bias, and the most important data is often the freshest. A delay of more than a few seconds between when something happened in production and when you can query for those results is unacceptable, especially when you’re dealing with an incident.

As data fades into months past, you tend to care about historical events more in terms of aggregates and trends, rather than granular individual requests. And when you do care about specific requests, taking a bit longer to find them is acceptable. But when data is fresh, you need query results to be raw, rich, and up-to-the-second current.

BI tools typically exist on the other end of that spectrum. It’s generally fine for it to take longer to process data in a BI tool. Often you can increase performance by caching more recent results, or by preprocessing, indexing, or aggregating older data. But generally, with BI tools, you want to retain the full fidelity of the data (practically) forever. With an observability tool, you would almost never search for something that happened five years ago, or even two years ago. Modern BI data warehouses are designed to store data forever and grow infinitely.

## Structure

Observability data is built from arbitrarily wide and structured data blobs: one event per request per service (or per polling interval in long-running batch processes). For observability needs (to answer any question about what’s happening at any time), you need to append as many event details as possible, to provide as much context as needed, so investigators can spy something that might be relevant in the future. Often those details quickly change and evolve as teams learn what data may be helpful. Defining a data schema up front would defeat that purpose.

Therefore, with observability workloads, schemas must be inferred after the fact or changed on the fly (just start sending a new dimension or stop sending it at any time). Indexes are similarly unhelpful (see [Chapter 16](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch16.html#efficient_data_storage)).

In comparison, BI tools often collect and process large amounts of unstructured data into structured, queryable form. BI data warehouses would be an ungovernable mess without structures and predefined schemas. You need consistent schemas in order to perform any kind of useful analysis over time. And BI workloads tend to ask similar questions in repeatable ways to power things like dashboards. BI data can be optimized with indexes, compound indexes, summaries, etc.

Because BI data warehouses are designed to grow forever, it is important that they have predefined schemas and grow at a predictable rate. Observability data is designed for rapid feedback loops and flexibility: it is typically most important under times of duress, when predictability is far less important than immediacy.

## Time Windows

Observability and BI tools both have the concept of a session, or trace. But observability tends to be limited to a time span measured in seconds, or minutes at most. BI tools can handle long-term journeys, or traces that can take days or weeks to complete. That type of trace longevity is not a use case typically supported by observability tools. With observability tools, longer-running processes (like import/export jobs or queues) are typically handled with a polling process, and not with a single trace.

## Ephemerality

Summarizing many of these points, debugging data is inherently more ephemeral than business data. You might need to retrieve a specific transaction record or billing record from two years ago with total precision, for example. In contrast, you are unlikely to need to know if the latency between service A and service B was high for a particular user request two years ago.

You may, however, want to know if the latency between service A and service B has increased over the last year or two, or if the 95% percentile latency has gone up over that time. That type of question is common, and it is actually best served not by either BI tools/data warehouses or by observability tools. Aggregate historical performance data is best served by our good old pal monitoring (see [Chapter 9](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch09.html#how_observability_and_monitoring_come_t)).

# Using Observability and BI Tools Together in Practice

BI tools come in many forms, often designed to analyze various business metrics that originate from financial, customer relationship management (CRM), enterprise resource planning (ERP), marketing funnel, or supply chain systems. Those metrics are crafted into dashboards and reports by many engineers. But, especially for tech-driven companies where application service experience is critical, there is often a need to drill further into details that BI systems are designed to provide.

The data granularity for BI tools is arbitrarily large, often reporting metrics per month or per week. Your BI tool can help you understand which feature was most used in the month of February. Your observability tool can provide much more granularity, down to the individual request level. Similar to the way observability and monitoring come together, business intelligence and observability come together by ensuring that you always have micro-level data available that can be used to build macro-level views of the world.

BI tools often lock you into being able to see only an overall super-big-picture representation of your business world by relying on aggregate metrics. Those views are helpful when visualizing overall business trends, but they’re not as useful when trying to answer questions about product usage or user behavior (detailed earlier in this chapter).

Sharing observability tools across departments is a great way to promote a single-domain language. Observability captures data at a level of abstraction—services and APIs—that can be comprehended by everyone from operations engineers to executives. With that sharing, engineers are encouraged to use business language to describe their domain models, and business people are exposed to the broad (and real) diversity of use cases present in their user base (beyond the few abstract composite user personas they typically see).

# Conclusion

With observability, you can understand customers’ experience of using your software in the real world. Because multiple teams in your business have a vested interest in understanding the customer experience and improving or capitalizing on it, you can use observability to help various teams within your organization better achieve their goals.

Beyond engineering teams, adjacent technical teams like product, support, and customer success can become powerful allies to boost your organization-wide observability adoption initiatives. Less technical teams, like sales and executives, can also become allies with a bit of additional support on your part. The teams outlined in this chapter as examples are by no means definitive. Hopefully, you can use this chapter as a primer to think about the types of business teams that can be better informed and can better achieve desired results by using the observability data you’re capturing. Helping additional business teams achieve their goals will create stakeholders and allies who can, in turn, help prioritize your observability adoption efforts.

In the next chapter, we’ll look at how you can gauge your organization’s overall progress on the observability adoption maturity curve.
