# Top DevOps Myths

Just as with any transformational and disruptive movement, DevOps can be misunderstood or mischaracterized. Here are some of the top DevOps myths:

### DevOps replaces Agile

DevOps is absolutely compatible with Agile. In fact, DevOps is the logical continuation of the Agile journey that was started in 2001, because we now know that the real definition of “done” is not when Development is done coding. Instead, code is only “done” when it has been fully tested and is operating in production as designed. (Note that Agile is not a prerequisite for adopting DevOps.)

### DevOps replaces ITIL

Although some may view DevOps as backlash to ITIL (the IT Infrastructure Library) or ITSM (IT Service Management), DevOps and ITIL are compatible, too. ITIL and ITSM remain the best codifications of the processes that underpin IT Operations, and actually describe many of the capabilities needed in order for IT Operations to support a DevOps-style work stream.

In order to accommodate the faster lead times and higher deployment frequencies associated with DevOps, many areas of the ITIL processes require automation, specifically around the change, configuration, and release processes.

Because we also require fast detection and recovery when service incidents occur, the ITIL disciplines of service design and incident and problem management remain as relevant as ever.

### DevOps means NoOps

DevOps is sometimes incorrectly interpreted to be NoOps (i.e., IT Operations is entirely eliminated). However, more precisely, DevOps will often put more responsibility on Development to do code deployments and maintain service levels. This merely means that Development is taking over many of the IT Operations and operations engineering functions.

In order to support fast lead times and enable developer productivity, DevOps does require many IT Operations tasks to become self-service. In other words, instead of Development opening up a work ticket and waiting for IT Operations to complete the work, many of these activities will be automated so that developers can do it themselves (e.g., get a production-like Dev environment, add a feature metric for production telemetry).

### DevOps is only for open source software

Although many of the DevOps success stories take place in organizations using software such as the LAMP stack,[10](https://learning.oreilly.com/library/view/the-phoenix-project/9781457191350/48-resourceNotes.xhtml#note-10) organizations are implementing DevOps patterns using Microsoft .NET, SAP, and even COBOL applications running on mainframes and HP LaserJet firmware.

DevOps principles are universal, and they are largely independent of the underlying technology being used. Some of the DevOps patterns have specific technology requirements (e.g., able to support automated testing, able to expose configurations that can be checked into version control), which are often more prevalent in open source software.

### DevOps is just “infrastructure as code” or automation

While many of the DevOps patterns shown in this book require automation, DevOps also requires shared goals and shared pain throughout the IT value stream. This goes far beyond just automation.

### DevOps is only for startups and unicorns

DevOps is applicable and relevant to any organization that must increase flow of planned work through Development, while maintaining quality, reliability, and security for the customer.

In fact, we claim that DevOps is even *more* important for the horses than for the unicorns. After all, as Richard Foster states, “Of the Fortune 500 companies in 1955, 87% are gone. In 1958, the Fortune 500 tenure was 61 years; now it’s only 18 years.”[11](https://learning.oreilly.com/library/view/the-phoenix-project/9781457191350/48-resourceNotes.xhtml#note-11) We know that the downward spiral happens to every IT organization. However, most enterprise IT organizations will come up with countless reasons why they cannot adopt DevOps, or why it is not relevant for them.

One of the primary objections from horses is that all the unicorns (e.g., Google, Amazon, Twitter, Etsy) were born that way. In other words, unicorns were born doing DevOps.

In actuality, virtually every DevOps unicorn was once a horse and had all the problems associated with being a horse.

- Amazon, up until 2001, ran on the OBIDOS content delivery system, which became so problematic and dangerous to maintain that Werner Vogels, Amazon CTO, transformed their entire organization and code to a service-oriented architecture.[12](https://learning.oreilly.com/library/view/the-phoenix-project/9781457191350/48-resourceNotes.xhtml#note-12)
- Twitter struggled to scale capacity on their front-end monolithic Ruby on Rails system in 2009, starting a multiyear project to progressively re-architect and replace it.[13](https://learning.oreilly.com/library/view/the-phoenix-project/9781457191350/48-resourceNotes.xhtml#note-13)
- LinkedIn, six months after their successful IPO in 2011, struggled with problematic deployments so painful that they launched Operation InVersion, a two-month feature freeze, allowing them to overhaul their compute environments, deployments, and architecture.[14](https://learning.oreilly.com/library/view/the-phoenix-project/9781457191350/48-resourceNotes.xhtml#note-14)
- Etsy, in 2009, according to Michael Rembetsy, “had to come to grips that they were living in a sea of their own engineering filth,” dealing with problematic software deployments and technical debt. They committed themselves to a cultural transformation.[15](https://learning.oreilly.com/library/view/the-phoenix-project/9781457191350/48-resourceNotes.xhtml#note-15)
- Facebook, in 2009, was at the breaking point for infrastructure operations, barely able to keep up with user growth, code deployments were becoming increasingly dangerous, and staff were continually firefighting. Jay Parikh and Pedro Canahuati started their transformation to make code safe to deploy again.[16](https://learning.oreilly.com/library/view/the-phoenix-project/9781457191350/48-resourceNotes.xhtml#note-16)

Simply put, all unicorns were once horses. DevOps is how any horse can became a unicorn, if they want to become one. And in fact, the list of enterprises adopting DevOps continues to grow:

- Financial services: BNY Mellon, Bank of America, World Bank, Paychex, Nationwide Insurance
- Retailers: The Gap, Nordstrom, REI, Macy’s, GameStop, Nordstrom, Target
- Higher education: Seton Hill University, Kansas State University, University of British Columbia
- Government agencies: UK.gov, Department of Homeland Security

Christopher Little states, “If there’s anything that all horses [enterprise IT organizations] hate, it’s hearing stories about unicorns [DevOps shops]. Which is strange, because horses and unicorns are probably the same species. Unicorns are just horses with horns.”
