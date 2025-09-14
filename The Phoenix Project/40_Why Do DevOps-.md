# Why Do DevOps?

The competitive advantage this capability creates is enormous, enabling faster feature time to market, increased customer satisfaction, market share, employee productivity, and happiness, as well as allowing organizations to win in the marketplace. Why? Because technology has become the dominant value creation process and an increasingly important (and often the primary) means of customer acquisition within most organizations.

In contrast, organizations that require weeks or months to deploy software are at a significant disadvantage in the marketplace.

![table](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781457191350/files/image/table-resourceWhy.jpg)

One of the hallmarks of high-performers in any field is that they always “accelerate from the rest of the herd.” In other words, the best always get better.

This constant and relentless improvement in performance is happening in the DevOps space, too. In 2009, ten deploys per day was considered fast. Now that is considered merely average. In 2012, Amazon went on record stating that they were doing, on average, 23,000 deploys per day.

## Business Value of Adopting DevOps Principles

In the 2012 Puppet Labs “State of DevOps Report”,[3](https://learning.oreilly.com/library/view/the-phoenix-project/9781457191350/48-resourceNotes.xhtml#note-3) we were able to benchmark 4,039 IT organizations, with the goal of better understanding the health and habits of organizations at all stages of DevOps adoption.

The first surprise was how much the high-performing organizations using DevOps practices were outperforming their non-high-performing peers in agility metrics:

- 30× more frequent code deployments
- 8,000× faster code deployment lead time

And reliability metrics:

- 2× the change success rate
- 12× faster MTTR

In other words, they were more agile. They were deploying code thirty times more frequently, and the time required to go from “code committed” to “successfully running in production” was eight thousand times faster. High performers had lead times measured in minutes or hours, while lower performers had lead times measured in weeks, months, or even quarters.

Not only were the organizations doing more work, but they had far better outcomes: when the high performers deployed changes and code, they were twice as likely to be completed successfully (i.e., without causing a production outage or service impairment), and when the change failed and resulted in an incident, the time required to resolve the incident was twelve times faster.

This study was especially exciting because it showed empirically that the core, chronic conflict can be broken: high performers are deploying features more quickly, while providing world-class levels of reliability, stability, and security, enabling them to out-experiment their competitors in the marketplace. An even more astonishing fact: delivering these high levels of reliability actually *requires* that changes be made frequently!

In the 2014 study,[4](https://learning.oreilly.com/library/view/the-phoenix-project/9781457191350/48-resourceNotes.xhtml#note-4) we also found that not only did these high performers have better IT performance, they had significantly better organizational performance as well: they were two times more likely to exceed profitability, market share, and productivity goals, and there are hints that they have significantly better performance in the capital markets, as well (as Erik predicted in the last chapter, when he wanted to create the hedge fund).

## What It Feels Like to Live in A DevOps World

Imagine living in a DevOps world, where product owners, Development, QA, IT Operations, and InfoSec work together relentlessly to help each other and the overall organization win. They are enabling fast flow of planned work into production (e.g., performing tens, hundreds, or even thousands of code deploys per day), while preserving world-class stability, reliability, availability, and security.

Instead of the upstream Development groups causing chaos for those in the downstream work centers (e.g., QA, IT Operations, and InfoSec), Development is spending twenty percent of its time helping ensure that work flows smoothly through the entire value stream, speeding up automated tests, improving deployment infrastructure, and ensuring that all applications create useful production telemetry.

Why? Because everyone needs fast feedback loops to prevent problematic code from going into production and to enable code to quickly be deployed into production, so that any production problems are quickly detected and corrected.

Everyone in the value stream shares a culture that not only values each other’s time and contributions but also relentlessly injects pressure into the system of work to enable organizational learning and improvement. Everyone dedicates time to putting those lessons into practice and paying down technical debt. Everyone values nonfunctional requirements (e.g., quality, scalability, manageability, security, operability) as much as features. Why? Because nonfunctional requirements are just as important in achieving business objectives, too.

We have a high-trust, collaborative culture, where everyone is responsible for the quality of their work. Instead of approval and compliance processes, the hallmark of a low-trust, command-and-control management culture, we rely on peer review to ensure that everyone has confidence in the quality of their code.

Furthermore, there is a hypothesis-driven culture, requiring everyone to be a scientist, taking no assumptions for granted and doing nothing without measuring. Why? Because we know that our time is valuable. We don’t spend years building features that our customers don’t actually want, deploying code that doesn’t work, or fixing something that isn’t actually the problem. All these factors contribute to our ability to release exciting features to the marketplace that delight our customers and help our organization win.

Paradoxically, performing code deployments becomes boring and routine. Instead of being performed only at night or on weekends, full of stress and chaos, we are deploying code throughout the business day, without most people even noticing. And because code deployments happen in the middle of the afternoon instead of on weekends, for the first time in decades, IT Operations is working during normal business hours, like everyone else.

Just how did code deployment become routine? Because developers are constantly getting fast feedback on their work: when they write code, automated unit, acceptance, and integration tests are constantly being run in production-like environments, giving us continual assurance that the code and environment will operate as designed, and that we are always in a deployable state. And when the code is deployed, pervasive production metrics demonstrate to everyone that it is working, and the customer is getting value.

Even our highest-stakes feature releases have become routine. How? Because at product launch time, the code delivering the new functionality is already in production. Months prior to the launch, Development has been deploying code into production, invisible to the customer, but enabling the feature to be run and tested by internal staff.

At the culminating moment when the feature goes live, no new code is pushed into production. Instead, we merely change a feature toggle or configuration setting. The new feature is slowly made visible to small segments of customers, automatically rolled back if something goes wrong.

Only when we have confidence that the feature is working as designed do we expose it to the next segment of customers, rolled out in a manner that is controlled, predictable, reversible, and low stress. We repeat until everyone is using the feature.

By doing this, we not only significantly reduce deployment risk, but we increase the likelihood of achieving the desired business outcomes, as well. Because we can do deployments quickly, we can do experiments in production, testing our business hypotheses for every feature we build. We can iteratively test and refine our features in production, using feedback from our customers for months, and maybe even years.

It is no wonder that we are out-experimenting our competition and winning in the marketplace.

All this is made possible by DevOps, a new way that Development, Test, and IT Operations work together, along with everyone else in the IT value stream.

## DevOps Is the Manufacturing Revolution of Our Age

The principles behind DevOps work patterns are the same principles that transformed manufacturing. Instead of optimizing how raw materials are transformed into finished goods in a manufacturing plant, DevOps shows how we optimize the IT value stream, converting business needs into capabilities and services that provide value for our customers.

During the 1980s, there was a very well-known core, chronic conflict in manufacturing:

- Protect sales commitments
- Control manufacturing costs

In order to protect sales commitments, the product sales force wanted lots of inventory on hand, so that customers could always get products when they wanted it. However, in order to reduce costs, plant managers wanted to reduce inventory levels and work in process (WIP).

Because one can’t simultaneously increase and decrease the inventory levels at the plant, sales managers and plant managers were locked in a chronic conflict.

They were able to break the conflict by adopting Lean principles, such as reducing batch sizes, reducing work in process, and shortening and amplifying feedback loops. This resulted in dramatic increases in plant productivity, product quality, and customer satisfaction.[5](https://learning.oreilly.com/library/view/the-phoenix-project/9781457191350/48-resourceNotes.xhtml#note-5)

In the 1980s, average order lead times[6](https://learning.oreilly.com/library/view/the-phoenix-project/9781457191350/48-resourceNotes.xhtml#note-6) were six weeks, with less than seventy percent of orders being shipped on time. By 2005, average product lead times had dropped to less than three weeks, with more than ninety-five percent of orders being shipped on time. Organizations that were not able to replicate these performance breakthroughs lost market share, if not went out of business entirely.[7](https://learning.oreilly.com/library/view/the-phoenix-project/9781457191350/48-resourceNotes.xhtml#note-7)
