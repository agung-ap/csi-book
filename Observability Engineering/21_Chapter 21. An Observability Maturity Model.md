# Chapter 21. An Observability Maturity Model

Spreading a culture of observability is best achieved by having a plan that measures progress and prioritizes target areas of investment. In this chapter, we go beyond the benefits of observability and its tangible technical steps by introducing the Observability Maturity Model as a way to benchmark and measure progress. You will learn about the key capabilities an organization can measure and prioritize as a way of driving observability adoption.

# A Note About Maturity Models

In the early 1990s, the Software Engineering Institute at Carnegie Mellon University popularized the [Capability Maturity Model](https://oreil.ly/zc9DP) as a way to evaluate the ability of various vendors to deliver effectively against software development projects. The model defines progressive stages of maturity and a classification system used to assign scores based on how well a particular vendor’s process matches each stage. Those scores are then used to influence purchasing decisions, engagement models, and other activities.

Since then, maturity models have become somewhat of a darling for the software marketing industry. Going well beyond scoping purchasing decisions, maturity models are now used as a generic way to model organizational practices. To their credit, maturity models can be helpful for an organization to profile its capabilities against its peers or to target a set of desired practices. However, maturity models are not without their limitations.

When it comes to measuring organizational practices, the performance level of a software engineering team has no upper bound. Practices, as opposed to procedures, are an evolving and continuously improving state of the art. They’re never done and perfect, as reaching the highest level of a maturity model seems to imply. Further, that end state is a static snapshot of an ideal future reflecting only what was known when the model was created, often with the biases of its authors baked into its many assumptions. Objectives shift, priorities change, better approaches are discovered, and—more to the point—each approach is unique to individual organizations and cannot be universally scored.

When looking at a maturity model, it’s important to always remember that no one-size-fits-all model applies to every organization. Maturity models can, however, be useful as starting points against which you can critically and methodically weigh your own needs and desired outcomes to create an approach that’s right for you. Maturity models can help you identify and quantify tangible and measurable objectives that are useful in driving long-term initiatives. It is critical that you create hypotheses to test the assumptions of any maturity model within your own organization and evaluate which paths are and aren’t viable given your particular constraints. Those hypotheses, and the maturity model itself, should be continuously improved over time as more data becomes available.

# Why Observability Needs a Maturity Model

When it comes to developing and operating software, practices that drive engineering teams toward a highly productive state have rarely been formalized and documented. Instead, they are often passed along informally from senior engineers to junior engineers based on the peculiar history of individual company cultures. That institutional knowledge sharing has given rise to certain identifiable strains of engineering philosophy or collections of habits with monikers that tag their origin (e.g., “the Etsy way,” “the Google way,” etc.). Those philosophies are familiar to others with the same heritage and have become heretical to those without.

Collectively, we authors have over six decades of experience watching engineering teams fail and succeed, and fail all over again. We’ve seen organizations of all shapes, sizes, and locations succeed in forming high-performing teams, given they adopt the right culture and focus on essential techniques. Software engineering success is not limited to those fortunate enough to live in Silicon Valley or those who have worked at FAANG companies (Facebook, Amazon, Apple, Netflix, and Google). It shouldn’t matter where teams are located, or what companies their employees have worked at previously.

As mentioned throughout this book, production software systems present sociotechnical challenges. While tooling for observability can address the technical challenges in software systems, we need to consider other factors beyond the technical. The Observability Maturity Model considers the context of engineering organizations, their constraints, and their goals. Technical and social features of observability contribute to each of the identified team characteristics and capabilities in the model.

To make a maturity model broadly applicable, it must be agnostic to an organization’s pedigree or the tools it uses. Instead of mentioning any specific software solutions or technical implementation details, it must instead focus on the costliness and benefits of the journey in human terms: “How will you know if you are weak in this area?” “How will you know if you’re doing well in this area and should prioritize improvements elsewhere?”

Based on our experiences watching teams adopt observability, we’d seen common qualitative trends like their increased confidence interacting with production and ability to spend more time working on new product features. To quantify those perceptions, we surveyed a spectrum of teams in various phases of observability adoption and teams that hadn’t yet started or were not adopting observability. We found that teams that adopt observability were three times as likely to feel confident in their ability to ensure software quality in production, compared to teams that had not adopted observability.[1](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch21.html#ch01fn18) Additionally, those teams that hadn’t adopted observability spent over half their time toiling away on work that did not result in releasing new product features.

Those patterns are emergent properties of today’s modern and complex sociotechnical systems. Analyzing capabilities like ensuring software quality in production and time spent innovating on features exposes both the pathologies of group behavior and their solutions. Adopting a practice of observability can help teams find solutions to problems that can’t be solved by individuals “just writing better code,” or, “just doing a better job.” Creating a maturity model for observability ties together the various capabilities outlined throughout this book and can serve as a starting point for teams to model their own outcome-oriented goals that guide adoption.

# About the Observability Maturity Model

We originally developed the *Observability Maturity Model* (*OMM*) based on the following goals for an engineering organization:[2](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch21.html#ch01fn19)

Sustainable systems and quality of life for engineersThis goal may seem aspirational to some, but the reality is that engineer quality of life and the sustainability of systems are closely entwined. Systems that are observable are easier to own and maintain, improving the quality of life for an engineer who owns those systems. Engineers spending more than half of their time working on things that don’t deliver customer value (toil) report higher rates of burnout, apathy, and lower engineering team morale. Observable systems reduce toil and that, in turn, creates higher rates of employee retention and reduces the time and money teams need to spend on finding and training new engineers.Delivering against business needs by increasing customer satisfactionObservability enables engineering teams to better understand customers’ interactions with the services they develop. That understanding allows engineers to home in on customer needs and deliver the performance, stability, and functionality that will delight their customers. Ultimately, observability is about operating your business successfully.The framework described here is a starting point. With it, organizations have the structure and tools to begin asking themselves questions, and the context to interpret and describe their own situation—both where they are now and what they should aim for.

The quality of your observability practice depends on technical and social factors. Observability is not a property of the computer system alone or the people alone. Too often, discussions of observability are focused only on the technicalities of instrumentation, storage, and querying, and not on what they can enable a team to do. The OMM approaches improving software delivery and operations as a sociotechnical problem.

If team members feel unsafe applying their tooling to solve problems, they won’t be able to achieve results. Tooling quality depends on factors such as the ease of adding instrumentation, the granularity of data ingested, and whether it can answer any arbitrary questions that humans pose. The same tooling need not be used to address each capability, nor does strength of tooling in addressing one capability necessarily translate to an aptitude in addressing all other suggested capabilities.

# Capabilities Referenced in the OMM

The capabilities detailed in this section are directly impacted by the quality of your observability practice. The OMM list is not exhaustive but is intended to represent the breadth of potential business needs. The capabilities listed and their associated business outcomes overlap with many of the principles necessary to create production excellence.

###### Note

For more on production excellence, we recommend the 2019 InfoQ blog post [“Sustainable Operations in Complex Systems with Production Excellence”](https://oreil.ly/fWiPD) by Liz Fong-Jones.

*There is no singular and correct order or prescriptive way of doing these things.* Instead, every organization faces an array of potential journeys. At each step, focus on what you’re hoping to achieve. Make sure you will get appropriate business impact from making progress in that area right now, as opposed to doing it later.

It’s also important to understand that building up these capabilities is a pursuit that is never “done.” There’s always room for continuous improvement. Pragmatically speaking, however, once organizational muscle memory exists such that these capabilities are second nature, and they are systematically supported as part of your culture, that’s a good indication of having reached the upper levels of maturity. For example, prior to CI systems, code was often checked in without much thought paid to bundling in tests. Now, engineers in any modern organization practicing CI/CD would never think of checking in code without bundled tests. Similarly, observability practices must become second nature for development teams.

## Respond to System Failure with Resilience

*Resilience* is the adaptive capacity of a team, together with the system it supports, that enables it to restore service and minimize impact to users. Resilience refers not only to the capabilities of an isolated operations team or to the robustness and fault tolerance in its software. Resilience must also measure both the technical outcomes and social outcomes of your emergency response process in order to measure its maturity.

###### Note

For more on resilience engineering, we recommend John Allspaw’s 2019 talk [“Amplifying Sources of Resilience”](https://oreil.ly/gDN3S), delivered at QCon London.

Measuring technical outcomes can, at first approximation, take the form of examining the amount of time it takes to restore service and the number of people who become involved when the system experiences a failure. For example, the DORA 2018 [Accelerate State of DevOps Report](https://oreil.ly/H0Pn5) defines elite performers as those whose MTTR is less than one hour, and low performers as those with a MTTR that is between one week and one month.

Emergency response is a necessary part of running a scalable, reliable service. But emergency response may have different meanings to different teams. One team might consider a satisfactory emergency response to mean “power cycle the box,” while another might interpret that to mean “understand exactly how the auto-remediation that restores redundancy in data striped across multiple disks broke, and mitigate future risk.” There are three distinct areas to measure: the amount of time it takes to detect issues, to initially mitigate those issues, and to fully understand what happened and address those risks.

But the more important dimension that team managers need to focus on is the people operating that service. Is the on-call rotation sustainable for your team so that staff remain attentive, engaged, and retained? Does a systematic plan exist for educating and involving everyone responsible for production in an orderly and safe manner, or is every response an all-hands-on-deck emergency, no matter the experience level? If your service requires many people to be on call or context switching to handle break/fix scenarios, that’s time and energy they are not spending generating business value by delivering new features. Over time, team morale will inevitably suffer if a majority of engineering time is devoted to toil, including break/fix work.

### If your team is doing well

- System uptime meets your business goals and is improving.

- On-call response to alerts is efficient, and alerts are not ignored.

- On-call duty is not excessively stressful, and engineers are not hesitant to take additional shifts as needed.

- Engineers can handle incident workload without working extra hours or feeling unduly stressed.

### If your team is doing poorly

- The organization is spending a lot of additional time and money staffing on-call rotations.

- Incidents are frequent and prolonged.

- Those on call suffer from alert fatigue or aren’t alerted about real failures.

- Incident responders cannot easily diagnose issues.

- Some team members are disproportionately pulled into emergencies.

### How observability is related

Alerts are relevant, focused, and actionable (thereby reducing alert fatigue). A clear relationship exists between the error budget and customer needs. When incident investigators respond, context-rich events make it possible to effectively troubleshoot incidents when they occur. The ability to drill into high-cardinality data and quickly aggregate results on the fly supports pinpointing error sources and faster incident resolution. Preparing incident responders with the tools they need to effectively debug complex systems reduces the stress and drudgery of being on call. Democratization of troubleshooting techniques by easily sharing past investigation paths helps distribute incident resolution skills across a team, so anyone can effectively respond to incidents as they occur.

## Deliver High-Quality Code

*High-quality code* is measured by more than how well it is understood and maintained, or how often bugs are discovered in a sterile lab environment (e.g., a CI test suite). While code readability and traditional validation techniques are useful, they do nothing to validate how that code actually behaves during the chaotic conditions inherent to running in production systems. The code must be adaptable to changing business needs, rather than brittle and fixed in features. Thus, code quality must be measured by validating its operation and extensibility as it matters to your customers and your business.

### If your team is doing well

- Code is stable, fewer bugs are discovered in production, and fewer outages occur.

- After code is deployed to production, your team focuses on customer solutions rather than support.

- Engineers find it intuitive to debug problems at any stage, from writing code in development to troubleshooting incidents in production at full release scale.

- Isolated issues that occur can typically be fixed without triggering cascading failures.

### If your team is doing poorly

- Customer support costs are high.

- A high percentage of engineering time is spent fixing bugs instead of working on new features.

- Team members are often reluctant to deploy new features because of perceived risk.

- It takes a long time to identify an issue, construct a way to reproduce the failure case, and repair it.

- Developers have low confidence in their code’s reliability after it has shipped.

### How observability is related

Well-monitored and tracked code makes it easy to see when and how a process is failing, and easy to identify and fix vulnerable spots. High-quality observability allows using the same tooling to debug code on one machine as on 10,000. A high level of relevant, context-rich telemetry means engineers can watch code in action during deployments, be alerted rapidly, and repair issues before they become visible to users. When bugs do appear, validating that they have been fixed is easy.

## Manage Complexity and Technical Debt

*Technical debt* is not necessarily a bad thing. Engineering organizations are constantly faced with choices between short-term gain and longer-term outcomes. Sometimes the short-term win is the right decision if a specific plan exists to address the debt, or to otherwise mitigate the negative aspects of the choice. With that in mind, code with high technical debt prioritizes quick solutions over more architecturally stable options. When unmanaged, these choices lead to longer-term costs, as maintenance becomes expensive and future revisions become dependent on costs.

### If your team is doing well

- Engineers spend the majority of their time making forward progress on core business goals.

- Bug fixing and other reactive work takes up a minority of the team’s time.

- Engineers spend very little time disoriented or trying to find where in the codebase they need to plumb through changes.

### If your team is doing poorly

- Engineering time is wasted rebuilding things when their scaling limits are reached or edge cases are hit.

- Teams are distracted by fixing the wrong thing or picking the wrong way to fix something.

- Engineers frequently experience uncontrollable ripple effects from a localized change.

- People are afraid to make changes to the code, aka the “haunted graveyard” effect.[3](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch21.html#ch01fn20)

### How observability is related

Observability enables teams to understand the end-to-end performance of their systems and debug failures and slowness without wasting time. Troubleshooters can find the right breadcrumbs when exploring an unknown part of their system. Tracing behavior becomes easily possible. Engineers can identify the right part of the system to optimize rather than taking random guesses of where to look, and they can change code when attempting to find performance bottlenecks.

## Release on a Predictable Cadence

The value of software development reaches users only after new features and optimizations are released. The process begins when a developer commits a change set to the repository, includes testing and validation and delivery, and ends when the release is deemed sufficiently stable and mature to move on. Many people think of continuous integration and deployment as the nirvana end-stage of releasing. But CI/CD tools and processes are just the basic building blocks needed to develop a robust release cycle. Every business needs a predictable, stable, frequent *release cadence* to meet customer demands and remain competitive in their market.[4](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch21.html#ch01fn21)

### If your team is doing well

- The release cadence matches business needs and customer expectations.

- Code gets into production shortly after being written. Engineers can trigger deployment of their own code after it’s been peer reviewed, satisfies controls, and is checked in.

- Code paths can be enabled or disabled instantly, without needing a deployment.

- Deployments and rollbacks are fast.

### If your team is doing poorly

- Releases are infrequent and require lots of human intervention.

- Lots of changes are shipped at once.

- Releases have to happen in a particular order.

- The sales team has to gate promises on a particular release train.

- Teams avoid deploying on certain days or times of year. They are hesitant because poorly managed release cycles have frequently interfered with quality of life during nonbusiness hours.

### How observability is related

Observability is how you understand the build pipeline as well as production. It shows you any performance degradation in tests or errors during the build-and-release process. Instrumentation is how you know whether the build is good, whether the feature you added is doing what you expected it to, and whether anything else looks weird; instrumentation lets you gather the context you need to reproduce any error.

Observability and instrumentation are also how you gain confidence in your release. If it’s properly instrumented, you should be able to break down by old and new build ID and examine them side by side. You can validate consistent and smooth production performance between deployments, or you can see whether your new code is having its intended impact and whether anything else looks suspicious. You can also drill down into specific events—for example, to see which dimensions or values a spike of errors all have in common.

## Understand User Behavior

Product managers, product engineers, and systems engineers all need to understand the impact that their software has on users. It’s how we reach product-market fit as well as how we feel purpose and impact as engineers. When users have a bad experience with a product, it’s important to understand what they were trying to do as well as the outcome.

### If your team is doing well

- Instrumentation is easy to add and augment.

- Developers have easy access to key performance indicators (KPIs) for customer outcomes and system utilization/cost, and can visualize them side by side.

- Feature flagging or similar makes it possible to iterate rapidly with a small subset of users before fully launching.

- Product managers can get a useful view of customer feedback and behavior.

- Product-market fit is easier to achieve.

### If your team is doing poorly

- Product managers don’t have enough data to make good decisions about what to build next.

- Developers feel that their work doesn’t have impact.

- Product features grow to excessive scope, are designed by committee, or don’t receive customer feedback until late in the cycle.

- Product-market fit is not achieved.

### How observability is related

Effective product management requires access to relevant data. Observability is about generating the necessary data, encouraging teams to ask open-ended questions, and enabling them to iterate. With the level of visibility offered by event-driven data analysis and the predictable cadence of releases both enabled by observability, product managers can investigate and iterate on feature direction with a true understanding of how well their changes are meeting business goals.

# Using the OMM for Your Organization

The OMM can be a useful tool for reviewing your organization’s capabilities when it comes to utilizing observability effectively. The model provides a starting point for measuring where your team capabilities are lacking and where they excel. When creating a plan for your organization to adopt and spread a culture of observability, it is useful to prioritize capabilities that most directly impact the bottom line for your business and improve your performance.

It’s important to remember that creating a mature observability practice is not a linear progression and that these capabilities do not exist in a vacuum. Observability is entwined in each capability, and improvements in one capability can sometimes contribute to results in others. The way that process unfolds is unique to the needs of each organization, and where to start depends on your current areas of expertise.

*Wardley mapping* is a technique that can help you figure out how these capabilities relate in priority and interdependency with respect to your current organizational abilities. Understanding which capabilities are most critical to your business can help prioritize and unblock the steps necessary to further your observability adoption journey.

As you review and prioritize each capability, you should identify clear owners responsible for driving this change within your teams. Review those initiatives with those owners and ensure that you develop clear outcome-oriented measures relevant to the needs of your particular organization. It’s difficult to make progress unless you have clear ownership, accountability, and sponsorship in terms of financing and time. Without executive sponsorship, a team may be able to make small incremental improvements within its own silo. However, it is impossible to reach a mature high-performing state if the entire organization is unable to demonstrate these capabilities and instead relies on a few key individuals, no matter how advanced and talented those individuals may be.

# Conclusion

The Observability Maturity Model provides a starting point against which your organization can measure its desired outcomes and create its own customized adoption path. The key capabilities driving high-performing teams that have matured their observability practice are measured along these axes:

- How they respond to system failure with resilience

- How easily they can deliver high-quality code

- How well they manage complexity and technical debt

- How predictable their software release cadence is

- How well they can understand user behavior

The OMM is a synthesis of qualitative trends we’ve noticed across organizations adopting observability paired with quantitative analysis from surveying software engineering professionals. The conclusions represented in this chapter reflect research studies conducted in 2020 and 2021. It’s important to remember that maturity models are static snapshots of an ideal future generalized well enough to be applicable across an entire industry. The maturity model itself will evolve as observability adoption continues to spread.

Similarly, observability practices will also evolve, and the path toward maturity will be unique to your particular organization. However, this chapter provides the basis for your organization to create its own pragmatic approach. In the next chapter, we’ll conclude with a few additional tips on where to go from here.

[1](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch21.html#ch01fn18-marker) Honeycomb, “Observability Maturity Report,” [2020 edition](https://hny.co/wp-content/uploads/2020/04/observability-maturity-report-4-2-2020-1-1-1.pdf) and [2021 edition](https://hny.co/wp-content/uploads/2021/06/Observability_Maturity_Report.pdf).

[2](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch21.html#ch01fn19-marker) Charity Majors and Liz Fong-Jones, [“Framework for an Observability Maturity Model”](https://hny.co/wp-content/uploads/2019/06/Framework-for-an-Observability-Maturity-Model.pdf), Honeycomb, June 2019.

[3](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch21.html#ch01fn20-marker) Betsy B. Beyer et al., [“Invent More, Toil Less”](https://oreil.ly/4bfLc), *;login:* 41, no. 3 (Fall 2016).

[4](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch21.html#ch01fn21-marker) Darragh Curran, [“Shipping Is Your Company’s Heartbeat”](https://oreil.ly/3PFX8), Intercom, last modified August 18, 2021.
