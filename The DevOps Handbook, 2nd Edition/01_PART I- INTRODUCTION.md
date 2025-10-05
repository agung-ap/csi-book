PART I: INTRODUCTION

In Part I of The DevOps Handbook, we will explore how the convergence of several important movements in management and technology set the stage for the DevOps movement. We describe value streams, how DevOps is the result of applying Lean principles to the technology value stream, and the Three Ways: Flow, Feedback, and Continual Learning and Experimentation.

Primary focuses within these chapters include:

•The principles of Flow, which accelerate the delivery of work from Development to Operations to our customers.

•The principles of Feedback, which enable us to create ever-safer systems of work.

•The principles of Continual Learning and Experimentation, which foster a high-trust culture and a scientific approach to organizational improvement and risk-taking as part of our daily work.

A Brief History

DevOps and its resulting technical, architectural, and cultural practices represent a convergence of many philosophical and management movements. While many organizations have developed these principles independently, understanding that DevOps resulted from a broad stroke of movements, a phenomenon described by John Willis (one of the co-authors of this book) as the “convergence of Dev and Ops,” shows an amazing progression of thinking and improbable connections. There are decades of lessons learned from manufacturing, high-reliability organizations, high-trust management models, and others that have brought us to the DevOps practices we know today.

DevOps is the outcome of applying the most trusted principles from the domain of physical manufacturing and leadership to the IT value stream. DevOps relies on bodies of knowledge from Lean, Theory of Constraints, the Toyota Production System, resilience engineering, learning organizations, safety culture, human factors, and many others. Other valuable contexts that DevOps draws from include high-trust management cultures, servant leadership, and organizational change management.

The result is world-class quality, reliability, stability, and security at ever-lower cost and effort and accelerated flow and reliability throughout the technology value stream, including Product Management, Development, QA, IT Operations, and Infosec.

While the foundation of DevOps can be seen as being derived from Lean, the Theory of Constraints, and the Toyota Kata movement, many also view DevOps as the logical continuation of the Agile software journey that began in 2001.

The Lean Movement

Techniques such as value stream mapping, kanban boards, and total productive maintenance were codified for the Toyota Production System in the 1980s. In 1997, the Lean Enterprise Institute started researching applications of Lean to other value streams, such as the service industry and healthcare.

Two of Lean’s central tenets include the deeply held belief that the manufacturing lead time required to convert raw materials into finished goods is the best predictor of quality, customer satisfaction, and employee happiness, and that one of the best predictors of short lead times is small batch sizes of work.

Lean principles focus on how to create value for the customer through systems thinking by creating constancy of purpose, embracing scientific thinking, creating flow and pull (versus push), assuring quality at the source, leading with humility, and respecting every individual.

The Agile Manifesto

The Agile Manifesto was created in 2001 at an invite-only event by seventeen experts in what was then known as “lightweight methods” in software development. They wanted to create a set of values and principles that captured the advantage of these more adaptive methods, compared to the prevailing software development processes such as waterfall development and methodologies such as the Rational Unified Process.

One key principle was to “deliver working software frequently, from a couple of weeks to a couple of months, with a preference to the shorter timescale,”[1](https://learning.oreilly.com/library/view/the-devops-handbook/9781098182281/56-Notes.xhtml#P1introEN1) emphasizing the desire for small batch sizes—incremental releases instead of large, big-bang releases. Other principles emphasized the need for small, self-motivated teams working in a high-trust management model.

Agile is credited for dramatically increasing the productivity and responsiveness of many development organizations. And interestingly, many of the key moments in DevOps history also occurred within the Agile community or at Agile conferences, as described below.

Agile Infrastructure and Velocity Movement

At the 2008 Agile conference in Toronto, Canada, Patrick Debois and Andrew Shafer held a “birds of a feather” session on applying Agile principles to infrastructure as opposed to application code. (In its early days, this was referred to as “Agile system administration.”) Although they were the only people who showed up, they rapidly gained a following of like-minded thinkers, including co-author John Willis.

Continuous Learning

Around the same time, a few academics started studying system administrators, how they applied engineering principles to their work, and how it impacted performance. The leading experts included a group from IBM Research, with ethnographies led by Dr. Eben Haber, Dr. Eser Kandogan, and Dr. Paul Maglio. This was extended to include behavioral quantitative studies led by co-author Dr. Nicole Forsgren in 2007–2009. Nicole went on to lead the research in the 2014–2019 State of DevOps Reports, the industry-standard research into practices and capabilities that drive software delivery and performance; these were published by Puppet and DORA.

Later, at the 2009 Velocity conference, John Allspaw and Paul Hammond gave the seminal “10 Deploys per Day: Dev and Ops Cooperation at Flickr” presentation, where they described how they created shared goals between Dev and Ops and used continuous integration practices to make deployment part of everyone’s daily work. According to firsthand accounts, everyone attending the presentation immediately knew they were in the presence of something profound and of historic significance.

Patrick Debois was so excited by Allspaw and Hammond’s idea that he created the first DevOpsDays in Ghent, Belgium, in 2009, where the term “DevOps” was coined.

The Continuous Delivery Movement

Building upon the development discipline of continuous build, test, and integration, Jez Humble and David Farley extended the concept to continuous delivery, which defined the role of a “deployment pipeline” to ensure that code and infrastructure are always in a deployable state and that all code checked into trunk can be safely deployed into production. This idea was first presented at the 2006 Agile conference and was also independently developed in 2009 by Tim Fitz in a blog post on his website titled “Continuous Deployment.”[*](https://learning.oreilly.com/library/view/the-devops-handbook/9781098182281/12-part-1-intro.xhtml#P1-intro_FN1)

Toyota Kata

In 2009, Mike Rother wrote Toyota Kata: Managing People for Improvement, Adaptiveness, and Superior Results, which framed his twenty-year journey to understand and codify the Toyota Production System. He had been one of the graduate students who flew with GM executives to visit Toyota plants and helped develop the Lean toolkit, but he was puzzled when none of the companies adopting these practices replicated the level of performance observed at the Toyota plants.

He concluded that the Lean community missed the most important practice of all, which he called the improvement kata.[2](https://learning.oreilly.com/library/view/the-devops-handbook/9781098182281/56-Notes.xhtml#P1introEN2) He explains that every organization has work routines, and the improvement kata requires creating structure for the daily, habitual practice of improvement work because daily practice is what improves outcomes. The constant cycle of establishing desired future states, setting target outcomes on a cadence, and the continual improvement of daily work is what guided improvement at Toyota.

Throughout the rest of Part I, we will look at value streams, how Lean principles can be applied to the technology value stream, and the Three Ways of Flow, Feedback, and Continual Learning and Experimentation.

| [*](https://learning.oreilly.com/library/view/the-devops-handbook/9781098182281/12-part-1-intro.xhtml#P1-intro_FNR1) | DevOps also extends and builds upon the practices of infrastructure as code, which was pioneered by Dr. Mark Burgess, Luke Kanies, and Adam Jacob. In infrastructure as code, the work of Operations is automated and treated like application code, so that modern development practices can be applied to the entire development stream. This further enabled fast deployment flow, including continuous integration (pioneered by Grady Booch and integrated as one of the key 12 practices of Extreme Programming), continuous delivery (pioneered by Jez Humble and David Farley), and continuous deployment (pioneered by Etsy, Wealthfront, and Eric Ries’s work at IMVU). |
| --- | --- |
