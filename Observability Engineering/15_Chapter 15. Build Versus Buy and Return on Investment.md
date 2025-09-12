# Chapter 15. Build Versus Buy and Return on Investment

So far in this book, we’ve examined both the technical fundamentals of observability and the social steps necessary to initiate the practice. In this part of the book, we will examine the considerations necessary when implementing observability at scale. We’ll focus on the functional requirements that are necessary to achieve the observability workflows described in earlier parts.

At a large enough scale, the question many teams will grapple with is whether they should build or buy an observability solution. Observability can seem relatively inexpensive on the surface, especially for smaller deployments. As user traffic grows, so too does the infrastructure footprint and volume of events your application generates. When dealing with substantially more observability data and seeing a much larger bill from a vendor, teams will start to consider whether they can save more by simply building an observability solution themselves.

Alternatively, some organizations consider building an observability solution when they perceive that a vendor’s ability to meet their specific needs is inadequate. Why settle for less than you need when software engineers can build the exact thing you want? As such, we see a variety of considerations play into arguments on whether the right move for any given team is to build a solution or buy one.

This chapter unpacks those considerations for teams determining whether they should build or buy an observability solution. It also looks at both quantifiable and unquantifiable factors when considering return on investment (ROI). The build-versus-buy choice is also not binary; in some situations, you may want to both buy *and* build.

We’ll start by examining the true costs for buying and building. Then we’ll consider circumstances that may necessitate one or the other. We’ll also look at ways to potentially strike a balance between building everything yourself or just using a vendor solution. The recommendations in this chapter are most applicable to larger organizations, but the advice applies to teams weighing this decision at any scale.

# How to Analyze the ROI of Observability

First, let’s acknowledge that this book is written by employees of an observability software vendor. Clearly, we have our own sets of biases. That said, we can still unpack this problem methodically and start by quantifying costs.

No one-size-fits-all answer can indicate how much observability will cost you. But some broad generalizations can be made. The easiest place to start is with the factor that is most visible: the bill that you get from a commercial observability vendor. In a vendor relationship, it’s easier to see the financial costs because they’re right there in a line item.

When you first begin investigating observability vendor solutions (especially those from incumbent monitoring and APM solutions that simply apply an observability label onto their decades-old traditional tools), the total price can give you sticker shock. The sticker is shocking in part because new users compare that price to open source and “free” alternatives that they presumably could just build themselves. However, people are generally not accustomed to considering the price of their own time. When it takes an hour to spin up some infrastructure and configure software, it feels like a DIY solution is essentially free.

In reality, the costs of ongoing maintenance—the time burned for context switching, the opportunity cost of all those engineers devoting time to something of no core business value, all those hours being siphoned away by that free solution—are almost always underestimated. In practice, even when you think you’ve accounted for the underestimation, you’ll likely still underestimate. As humans, our gut feelings are wildly, even charmingly, optimistic on the matter of maintenance costs. As a starting point, this is both understandable and forgivable.

Even when you do proceed beyond that starting point, sometimes the urge to build a solution yourself is a matter of encountering a budgetary mismatch. Getting approval to spend money on buying software may be harder than getting engineers you already employ to spend time building and supporting an in-house alternative. However, organizations that fall into this category are often reluctant to admit just how much that free effort is truly costing their business. Overcoming a budgetary mismatch may prompt an initial decision to build, but over the long term, that decision will present substantial costs to an organization that aren’t usually being tracked after the initial decision to build is made.

To analyze the ROI of building or buying observability tools, first you must start by truly understanding the costs of both decisions. Calculating total cost of ownership (TCO) requires factoring in many considerations to be exact, but you can use general guidelines to get started.

# The Real Costs of Building Your Own

Let’s start with opportunity costs. Resources are finite, and every choice to spend dollars or time impacts what your business will be able to accomplish. *Opportunity cost* is the value of the next-best alternative when a decision is made. By choosing to go the route you did, what did you give up in return?

Are you in the business of building observability solutions? If the answer to that question is no, building a bespoke observability tool is likely a distraction from your company’s core objectives. Therefore, the opportunity cost of choosing to build one yourself is big.

The rarest naturally occurring element on Earth is astatine (atomic number 85 on the periodic table), with less than 1 gram present deep within the Earth’s crust at any given time. The second rarest element is unallocated engineering time. We kid, of course. But if you’re a product or an engineering manager, you’re probably “lolsobbing” at that joke (sorry, managers!). In any given company, endless competing demands clamor for engineering cycles. As leaders and engineers, it’s your job to filter out the noise and prioritize the most impactful needs requiring solutions that will move the business forward.

As software engineers, it’s your job to write code. The opportunity cost problem comes into play whenever that talent is applied toward every arbitrary challenge that you might encounter. When you see a problem, if your first and foremost inclination is to just write some code to fix it, you may not be considering opportunity costs. While coding is fast and cheap, maintaining that code is extremely time-consuming and costly. As fellow engineers, we know that often we are so preoccupied with whether we *can* do something that we don’t stop to think about whether we *should*.

To calculate opportunity costs, you must first calculate the financial costs of each option, quantify the benefits received with each, and compare the two. Let’s start with an example of calculating the costs of building your own.

## The Hidden Costs of Using “Free” Software

You could choose to build your own observability stack using open source components that you then assemble yourself. For simplicity, we’ll presume this is the case. (An alternative build option of creating every stack component from scratch would carry costs at least an order of magnitude higher.) To illustrate actual operating costs, we’ll use a real example.

We spoke to an engineering team manager who was considering investing in a commercial observability stack after having built an in-house ELK stack. We’d given him a quote that was about $80,000/month to provide observability for his organization. He immediately balked at the sticker shock of a nearly $1 million annual solution and pointed to the free ELK stack his team was running internally.

However, he wasn’t counting the cost of the dedicated hardware used to run that ELK cluster ($80,000/month). He also wasn’t counting the three extra engineers he had to recruit to help run it ($250,000 to $300,000 each, per year), plus all of the one-time costs necessary to get there, including recruiter fees (15% to 25% of annual earnings, or about $75,000 each), plus the less tangible (though still quantifiable) organizational time spent hiring and training them to become effective in their roles.

The seemingly free solution had been costing his company over $2 million each year, more than twice the cost of the commercial option. But he’d been spending that in ways that were less visible to the organization. Engineers are expensive, and recruiting them is hard. It seems especially wasteful to devote their talent to bespoke solutions in the name of saving a few dollars, when the reality is often much further from the truth.

Heidi Waterhouse, principal developer advocate at LaunchDarkly, muses that open source software is “free as in puppies, not free as in beer.” Indeed, in the preceding example, this engineering manager was spending twice as much to do non-mission-critical work that did not advance his company’s core competencies.

The first step to understanding ROI is to truly flesh out the hidden and less visible costs of running supposedly free software. This isn’t to say that you shouldn’t run open source software. It’s to say that, when you do, you should be fully aware of what it is really costing you.

## The Benefits of Building Your Own

In many organizations, the deciding factor comes down to justifying visible spending. When budgets and expectations are mismatched, justifying spending time and hiring additional developers to build and support an in-house solution is often easier than creating a new line item to pay to acquire software externally. While the true estimation of costs in those cases is misguided, building your own software provides an additional benefit that may balance the equation a bit.

Building your own software also builds in-house expertise. The very act of deciding to build your own custom approach means that it becomes someone’s job to deeply understand your organizational needs and turn those into a set of functional requirements. As you work with internal stakeholders to support their needs, you will learn how to bridge the gap between technology and your business.

When building your own observability solution, you will inherently need to internalize and implement many of the solutions detailed in this book—from the necessary data granularity provided by events, to automating the core analysis loop, to optimizing your data store to performantly return results against large quantities of unpredictable high-cardinality data. But you will deeply internalize those solutions as they’re implemented specifically to meet your organizational needs.

You’ll learn how to make distributed tracing valuable for the needs of your own particular applications through numerous trials and many useful errors working with your own developer teams. You’ll learn exactly where metrics are serving your business and where they’re not by slamming headfirst into the limitations of their coarseness in the debugging loop. You’ll learn how to adjust error budget burn alert calculations for your implementation SLOs as you miss timely responses to production outages.

Over time, you will so deeply understand your own organizational challenges that you will build a team whose job it is to write instrumentation libraries and useful abstractions for your software engineering teams. This observability team will standardize on naming conventions across the organization, handle updates and upgrades gracefully, and consult with other engineering teams on how to instrument their code for maximum effectiveness. Over the years, as the observability team grows and your custom implementation becomes a battle-tested and mature application, the team may even be able to shift its focus away from new feature development and ongoing support to instead look for ways to simplify and reduce friction.

Observability is a competitive advantage for organizations.[1](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch15.html#ch01fn11) By building your own observability solution, you can develop a solution that is deeply ingrained in your own practices and culture and that leverages existing institutional knowledge. Rather than using generic prebuilt software designed to work with many workflows and implementations, you can customize your solution for deep integration with bespoke parts of your business, according to your own rules.

## The Risks of Building Your Own

The deep in-house expertise developed by building your own observability solution does not come without risks. The first and most obvious risk centers around product management expertise and bandwidth. Does the observability team have a product manager—whether by title or by function—whose job it is to interview users, determine use cases, manage feature development by the team, deliver a minimum viable product, gather feedback for iteration, and balance constraints against business needs to deliver against a roadmap of functionality the business needs?

Product-led organizations will have in-house product expertise that can make their in-house development of a custom observability product successful. Whether that product management expertise will be allocated away from core business objectives and toward building in-house tooling is another question. The biggest risk in building your own observability solution is whether the delivered product will meet the needs of your internal users very well.

This risk is somewhat mitigated when assembling a solution by piecing together various open source components. However, each of those components has its own designed user-experience and inherent workflow assumptions. As an engineering team building your own observability stack, your job will be to ease the friction among those components with integration libraries that enable the workflows needed by your own teams. Your job is to build a user interface that’s easy to use, or you run the risk of having low adoption.

When deciding to build your own observability solution, it’s critical to be realistic about both your organizational ability and your chances of developing something better than commercially available systems. Do you have the organizational expertise to deliver a system with the user interface, workflow flexibility, and speed required to encourage organizational-wide adoption? If you don’t, it’s entirely likely that you will have invested time, money, and lost business opportunities into a solution that never sees widespread adoption beyond those who are intimately familiar with its rough edges and workarounds.

Presuming your organization has the ability to deliver a better solution, another factor in considering your chances is time. Building out your own solutions and custom integrations takes time, which will delay your observability adoption initiatives. Can your business afford to wait several months to get a functional solution in place instead of getting started immediately with an already built commercial solution? This is like asking whether your business should wait to get operations underway while you first construct an office building. In some cases, considering longer-term impacts may require that approach. But often in business, reduced time to value is preferable.

Building your own observability product is not a one-and-done solution either. It requires ongoing support, and your custom-built software also needs to be maintained. Underlying third-party components in your stack will get software updates and patches. Organizational workflows and systems are constantly evolving. Introducing updates or enhancements in underlying components will require internal development efforts that must be accounted for. Unless those components and integrations stay current, custom solutions run the risk of becoming obsolete. You must also factor in the risks presented by ongoing support and maintenance.

An unfortunately common implementation pattern in many enterprises is to devote development effort toward building an initial version of internal tools and then moving on to the next project. As a result, it’s also common to see enterprises abandon their custom-built solutions once development has stalled, adoption is low, and the time and effort required to make it meet current requirements is not a high-enough priority when compared against competing interests.

# The Real Costs of Buying Software

Let’s start with the most obvious cost of buying software: financial costs. In a vendor relationship, this cost is the most tangible. You see the exact financial costs whenever your software vendor sends you a bill.

A reality is that software vendors must make money to survive, and their pricing scheme will factor in a certain level of profit margin. In other words, you will pay a vendor more to use their software than it costs them to build and operate it for you.

## The Hidden Financial Costs of Commercial Software

While it may be fair (and necessary) for vendors to set prices that help them recoup their cost to deliver a market-ready solution, what is considerably less fair is obscuring the real costs, avoiding transparency, or stacking in so many pricing dimensions that consumers cannot reasonably predict what their usage patterns will cost them in the future.

A common pattern to be on the lookout for uses pricing strategies that obscure TCO, such as per seat, per host, per service, per query, or per any other impossible-to-predict metering mechanism. Pay-as-you-go pricing may seem approachable at first—that is, until your usage of a particular tool explodes at a rate disproportionately more expensive than the revenue it helps you generate.

That’s not to say that pay-as-you-go pricing is unfair. It’s simply harder to project into the future. As a consumer, it’s up to you to avoid pricing schemes that disproportionately cost you more when using an observability tool for its intended purpose. You may initially opt for pricing that presents a lower barrier to entry, but inadvertently lock yourself into a ballooning budget with a tool you’ve learned to successfully use. You can avoid this by learning how to forecast hidden costs.

Will the size of your team change as your start-up becomes a more successful business? More than likely, yes. So it may seem reasonable to you to adopt a tool with a per seat licensing strategy: when your company is more profitable, you’ll be willing to pay more. Will your start-up significantly grow its number of hosts in the future? Possibly? Likely yes, but instance resizing may also be a factor. Will there be more services? Very few, perhaps. Maybe you’ll launch a few new products or features that necessitate more, but that’s difficult to say. What about the number of queries you run? Almost certainly yes, if this tool is successfully used. Will that growth be linear or exponential? What happens if you decide to decompose your monoliths into microservices? What happens if an adjacent team you didn’t account for also finds this tool useful?

The future is unpredictable. But when it comes to observability—regardless of how your production services change—you can (and should) predict how your usage will take shape when you’re adopting it successfully. Given the same set of observability data, the recommended practice is to analyze it with increasing curiosity. You should see exponential growth in data queries as a culture of observability spreads in your organization.

For example, observability is useful in your CI/CD build pipelines (see [Chapter 14](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch14.html#observability_and_the_software_supply_c)). As you’ll see in the next couple of chapters, analyzing observability data is also useful to product, support, finance, executive, or any number of business teams that stretch well beyond engineering. You will want to slice and dice your observability data in many ways, across many dimensions, to coax out any performance outliers that may be hiding in your application systems.

Therefore, you should avoid observability tools with pricing schemes that penalize adoption and curiosity. You will want to ensure that as many people in your company as possible have the ability to understand how your customers use your software, in as many ways as possible.

As a consumer, you should demand your vendors be transparent and help you calculate hidden costs and forecast usage patterns. Ask them to walk you through detailed cost estimates of both your starting point today and your likely usage patterns in the future. Be wary of any vendor unwilling to provide an exceptional level of detail about how their pricing will change as your business needs grow.

To factor in the hidden financial costs of commercial observability solutions, start with the real costs of using it as you do today. Then apply a logical rubric to that price: how much will that tool cost you if you want to ensure that as many people as possible have the ability to understand how your customers use your software, in as many arbitrary ways as possible? That will help you quantify the cost in terms of dollars spent.

## The Hidden Nonfinancial Costs of Commercial Software

A secondary hidden cost of commercial solutions is time. Yes, you will lower your time to value by buying a ready-made solution. But you should be aware of a hidden trap when going this route: vendor lock-in. Once you’ve made the choice to use this commercial solution, how much time and effort would be required from you to migrate to a different solution?

When it comes to observability, the most labor-intensive part of adoption comes by way of instrumenting your applications to emit telemetry data. Many vendors shortcut this time to adoption by creating proprietary agents or instrumentation libraries that are prebuilt to generate telemetry in proprietary ways their tools expect to see data. While some of those proprietary agents may be quicker to get started with, any time and effort devoted to making them work must be repeated when even considering evaluating a possible alternative observability solution.

The open source OpenTelemetry project (see [Chapter 7](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch07.html#instrumentation_with_opentelemetry)) solves this problem by providing an open standard that many observability tools support. OTel allows you to also shortcut time to value with proprietary tools by enabling the use of OTel distributions (or *distros*). OTel distros allow product vendors to layer boilerplate configurations and functionality on top of standard OTel libraries.

As a consumer, your strategy to avoid vendor lock-in should be to use native OTel functionality by default in your applications and rely on distros to handle vendor configuration. Should you wish to evaluate or migrate to a different tool, you can replace configurations with different distros or configure OTel exporters to send your data to multiple backends. Getting started with OTel will have an initial time cost (as would any instrumentation approach), but most of that time investment should be reusable should you wish to use other solutions in the future.

## The Benefits of Buying Commercial Software

The most obvious benefit of buying an observability solution is time to value. You don’t need to custom build a solution; you’re purchasing one that’s ready to go. In most cases, you can get started within minutes or hours and be well on your way to understanding production differently than you did without observability.

Part of the reason that fast on-ramping is possible with commercial solutions is that they generally have more streamlined user experience than open source solutions. Open source solutions are generally designed as building blocks that can be assembled as part of a toolchain you design yourself. Commercial software is often more opinionated: it tends to be a finished product with a specific workflow. Product designers work to streamline ease of use and maximize time to value. Commercial software *needs to be* incredibly faster and easier to learn and use than free alternatives. Otherwise, why would you pay for them?

Perhaps you’d also pay for commercial software because you offload maintenance and support to your vendor. You save time and effort. Rather than burning your own engineering cycles, you pay someone else to take on that burden for you. And you’ll enjoy better economies of scale. Often the choice to go commercial is all about increasing speed and lowering organizational risk, at the trade-off of cost.

But buying a commercial solution has one other, mostly overlooked, benefit. By purchasing tooling from a company whose core competency is focusing on a particular problem, you potentially gain a partner with years of expertise in solving that problem in a variety of ways. You can leverage this commercial relationship to tap into invaluable expertise in the observability domain that would otherwise take you years to build on your own.

## The Risks of Buying Commercial Software

That last benefit is also one of the bigger risks in buying commercial software. By shoving off responsibility to your vendor, you potentially risk not developing your own in-house observability expertise. By simply consuming a ready-made solution, your organization may not have the need to dive into your problem domain to understand how exactly observability applies to your particular business needs.

Commercial products are built for a wide audience. While they have opinionated designs, they’re also generally built to adapt to a variety of use cases. A commercial product is, by definition, not specifically built to accommodate your special needs. Features that are important to you may not be as important to your vendor. They may be slow to prioritize those features on their roadmap, and you may be left waiting for functionality that is critical for your business.

But there is a way to mitigate these risks and still develop in-house expertise when it comes to adopting observability tools.

# Buy Versus Build Is Not a Binary Choice

The choice to build or to buy is a false dichotomy when it comes to observability tools. Your choice is not limited to simply building or buying. A third option is to buy *and* to build. In fact, we authors recommend that approach for most organizations. You can minimize internal opportunity costs and build solutions that are specific to your organization’s unique needs. Let’s see what that looks like in practice by examining how an *observability team* should work in most organizations.

Buying a vendor solution doesn’t necessarily mean your company won’t need an observability team. Rather than having that team build your observability tooling from scratch or assemble open source components, the team can act as an intermediary integration point between the vendor and your engineering organization, with the explicit goal of making that interface seamless and friendly.

We already know from industry research that the key to success when outsourcing work is to carefully curate how that work makes its way back into the organization.[2](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch15.html#idm45204353886976) Outsourced contributions should be embedded within cross-functional teams that manage integrating that work back into the broader organization. That research specifically looks at contractual deliverables, but the same type of model applies to interacting with your vendors.

High-performing organizations use great tools. They know engineering cycles are scarce and valuable. So they train their maximum firepower on solving core business problems, and they equip engineers with best-of-breed tools that help them be radically more effective and efficient. They invest in solving bespoke problems (or building bespoke tools) only to the extent that they have become an obstacle to delivering that core business value.

Lower-performing engineering organizations settle for using mediocre tools, or they copy the old tools without questioning. They lack discipline and consistency around adoption and deprecation of tools meant to solve core business problems. Because they attempt to solve most problems themselves, they leak lost engineering cycles throughout the organization. They lack the focus to make strong impacts that deliver core business value.

Your observability team should write libraries and useful abstractions, standardize on naming schemes across the organization, handle updates and upgrades gracefully, and consult with other engineering teams on how to instrument their code for maximum effectiveness (see [“Use Case: Telemetry Management at Slack”](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch18.html#use_case_telemetry_management_at_slack)). They should manage vendor relationships, make decisions about when to adopt new technologies, and look for ways to simplify and reduce friction and costs.

For organizations that consider building their own observability stack because they can suit it to their specific needs, this is an especially effective approach. Using an observability team to build on top of an extensible vendor solution can minimize sunken costs that distract from delivering core business value. Rather than reinventing the wheel, your observability team can build integrations that mount that wheel to the fast-moving car you’ve already built.

The key to enabling that balance is to ensure that your team uses a product that has a well-developed API that lets them configure, manage, and run queries against your observability data. You should be able to get results programmatically and use those in your own customized workflows. Last-mile problem-solving requires substantially less investment and lets you build just the components you need while buying a vast majority of things your company doesn’t need to build. When seeking a commercial tool, you should look for products that give you the flexibility to manipulate and adapt your observability data as you see fit.

# Conclusion

This chapter presents general advice, and your own situation may, of course, be different. When making your own calculations around building or buying, you must first start by determining the real TCO of both options. Start with the more visibly quantifiable costs of both (time when considering building, and money when considering buying). Then be mindful of the hidden costs of each (opportunity costs and less visibly spent money when considering building, and future usage patterns and vendor lock-in when considering buying).

When considering building with open source tools, ensure that you weigh the full impact of hidden costs like recruiting, hiring, and training the engineers necessary to develop and maintain bespoke solutions (including their salaries and your infrastructure costs) in addition to the opportunity costs of devoting those engineers to running tools that are not delivering against core business value. When purchasing an observability solution, ensure that vendors give you the transparency to understand their complicated pricing schemes and apply logical rubrics when factoring in both system architecture and organizational adoption patterns to determine your likely future costs.

When adding up these less visible costs, the TCO for free solutions can be more adequately weighed against commercial solutions. Then you can also factor in the less quantifiable benefits of each approach to determine what’s right for you. Also remember that you can buy *and* build to reap the benefits of either approach.

Remember that, as employees for a software vendor, we authors have some implicit bias in this conversation. Even so, we believe the advice in this chapter is fair and methodical, and in alignment with our past experience as consumers of observability tooling rather than producers. Most of the time, the best answer for any given team focused on delivering business value is to buy an observability solution rather than building one themselves. However, that advice comes with the caveat that your team should be building an integration point enabling that commercial solution to be adapted to the needs of your business.

In the next chapter, should you decide to build your own observability solution, we will look at what it takes to optimize a data store for the needs of delivering against an observability workload.

[1](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch15.html#ch01fn11-marker) Dustin Smith, [“2021 Accelerate State of DevOps Report Addresses Burnout, Team Performance”](https://oreil.ly/h958I), Google Cloud Blog, September 21, 2021.

[2](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch15.html#idm45204353886976-marker) Nicole Forsgren et al., [Accelerate State of DevOps](https://oreil.ly/2Gqjz), DORA, 2019.
