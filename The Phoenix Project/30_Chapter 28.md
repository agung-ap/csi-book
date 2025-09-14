# Chapter 28

## • Monday, October 27

*On my drive into work,* I have to turn on my seat heaters months earlier than usual.

I hope this winter won’t be as awful as last year. Paige’s relatives, the most skeptical people I’ve ever met, have started wondering whether there actually might be something to this global climate change thing, after all.

When I get to my office, I take my laptop out of my bag, smiling at how quickly it powers on. As I write up a report for Steve on how far we’ve come in the last six weeks, I don’t put in anything about my new laptop, but I want to.

To me, the laptop represents everything my team has achieved together. I’m incredibly proud of them. Life feels different now. The number of Sev 1 outages this month is down by more than two-thirds. Incident recovery time is down, too, probably by more than half.

The insight we’ve gained from that first strange meeting with Dick and John tells me that we’re hot on the trail of understanding how we can really help the business win.

Opening up my e-mail, I see a note from Kirsten. All her project managers are gushing about how projects are flowing so much faster. The number of tasks waiting for Brent and the rest of IT Operations is way down. In fact, if I’m reading the report correctly, Brent is almost caught up.

On the project front, we’re in fantastic shape—especially with Phoenix.

There’s another Phoenix deployment scheduled for Friday. It’s only a bunch of defect fixes, with no major functionality added or changed, so it should be much better than last time. We’ve completed all of our deliverables on time, but as usual, there are still a million details that still need to be worked out.

I’m grateful that my team can stay so focused on Phoenix, because we’ve stabilized our infrastructure. When the inevitable outages and incidents do occur, we’re operating like a well-oiled machine. We’re building a body of tribal knowledge that’s helping us fix things faster than ever, and, when we do need to escalate, it’s controlled and orderly.

Because of our ever-improving production monitoring of the infrastructure and applications, more often than not, we know about the incidents before the business does.

Our project backlog has been cut way down, partially from eradicating dumb projects from our queue. And John has delivered. We’ve cut a bunch of unneeded security projects from our audit preparation and remediation work, replacing them with preventive security projects that my entire team is helping with. By modifying our development and deployment processes, we’re hardening and securing both the applications and production infrastructure in a meaningful and systematic way. And we’re gaining confidence that those defects will never happen again in the future.

Our change management meetings are going more smoothly and regularly than ever. We not only have visibility into what our teams are doing, but work is really flowing.

More than ever, people know exactly what they should be working on. People are getting satisfaction out of fixing things. I’m hearing that people are feeling happier and more upbeat, because they can actually do their jobs.

It’s strange how much more clearly I see the IT world now and how differently it looks to me than even a couple of months ago.

Patty’s experiments with establishing kanbans around Brent are a success. We’re also finding instances of work going backward to Brent, because we didn’t understand or didn’t sufficiently specify some task or outcome, requiring Brent to translate or fix it.

When this happens now, we quickly jump on it to make sure that it doesn’t happen again.

And it’s not just Brent’s work that we’re improving. By reducing the number of projects in flight, we’re keeping clear lanes of work, so work can go from one work center to the other quickly, getting completed in record time.

We’ve all but emptied our ticketing system of outdated work. In one case, we even found a ticket that Wes put in over ten years ago as a junior engineer, referring to some task for a machine that has been long since decommissioned. Now we have confidence that all work in the system is important and actually has a prayer of being completed.

We are no longer the Bates Motel of work.

Against my staff’s expectations, we keep bumping up the number of projects we think we can handle concurrently. Because we have a better idea of what our flows of work are, and managing carefully which ones are allowed to go to Brent, we’re finding that we can keep releasing more projects without impacting our existing commitments.

I no longer think of Erik as a raving madman, but he’s eccentric, for sure. Now that I’ve seen the results with my own eyes in my own organization, I know that IT Operations work is very similar to plant work. Erik has stated repeatedly that our improvements to date are only the tip of the iceberg.

Erik says that we are starting to master the First Way: We’re curbing the handoffs of defects to downstream work centers, managing the flow of work, setting the tempo by our constraints, and, based on our results from audit and from Dick, we’re understanding better than we ever have what is important versus what is not.

At the end, I led the retrospective portion, where we self-assessed how we did and the areas that we should improve. When someone mentioned that we should start inviting people from Development when we do our outage postmortem root cause analysis meetings, I realized that we are now also well on our way to understanding Erik’s Third Way, as well.

As Erik keeps reminding me, a great team performs best when they practice. Practice creates habits, and habits create mastery of any process or skill. Whether it’s calisthenics, sports training, playing a musical instrument, or in my experience, the endless drilling we did in the Marines. Repetition, especially for things that require teamwork, creates trust and transparency.

Last week, as I sat through our latest biweekly outage drill, I was very impressed. We were getting very good at this.

I feel certain that if the payroll failure that happened on my first day of the job happened now, we could complete the entire payroll run—not just the salaried staff, but the hourly staff, as well.

John quickly got the approval from Dick and Steve to have an outsourcer to take over the cafeteria POS systems and replace it with something commercially supported.

It was a fascinating exercise for Wes, Patty, and me to work with John to put together the outsourcing requirements for the cafeteria POS systems. As part of the due diligence process, we were going to hear from all the prospective outsourcers all the dogmas we used to believe before all our interactions with Erik. It will be interesting to see if we can retrain them.

It seems to me that if anyone is managing IT without talking about the Three Ways, they are managing IT on dangerously faulty assumptions.

As I’m pondering this, my phone rings. It’s John.

When I answer, he says, “My team discovered something troubling today. To prevent unauthorized black market IT activities from cropping up, we’ve started routinely reviewing all the proposed projects coming into Kirsten’s Project Management Office. We also search all the corporate credit cards for recurring charges that might be for online or cloud services—which is just another form of unauthorized IT. Some people are going around the project freeze. You have time to talk?”

“Let’s meet in ten minutes,” I say. “Don’t leave me hanging. Who’s trying to backdoor the system?”

I hear John laugh on the other end of the line. “Sarah. Who else?”

---

*I invite Wes and Patty *to the impromptu meeting but only Patty can make it.

John starts presenting what he found. Sarah’s group has four instances of using outside vendors and online services. Two are relatively innocuous but the others are more serious: she has contracted a vendor for a $200,000 project to do customer data mining and another vendor to plug into all our POS systems to get sales data for customer analytics.

“The first problem is that both projects violate the data privacy policy that we’ve given our customers,” John says. “We repeatedly promise that we will not share data with partners. Whether we change that policy or not is, of course, a business decision. But make no mistake, if we go ahead with the customer data mining initiative, we’re out of compliance with our own privacy policy. We may even be breaking several state privacy regulations that expose us to some liability.”

This doesn’t sound good, but John’s tone of voice suggests there’s worse to come. “The second problem is that Sarah’s vendor uses the same database technology that we used for our cafeteria POS system, which we know is virtually impossible to secure and maintain support for in production, if and when it becomes a part of daily operations.”

I feel my face get red hot. It’s not just about another cafeteria POS system that we’ll need to retrofit for production. It’s because applications like this contribute to our inaccurate sales order entry and inventory management data. We have too many cooks in the kitchen and no one accountable for maintaining the integrity of the data.

“Look, I don’t care about Sarah’s project management and invoicing tools—if it makes them more productive, let them use it,” I say. “It’s probably safe as long as it doesn’t interface with an existing business system, store confidential data, affect financial reporting, or whatever. But if it does, then we need to be involved and at least confirm that it doesn’t impact any of our existing commitments.”

“I agree,” John says, “Want me to take the first stab at that outsourced IT service policy document?”

“Perfect,” I say. But with less certainty, I continue, “Although, what’s the right way to handle Sarah? I feel completely out of my league. Steve constantly protects her. How do we convey to him the potential mayhem she’s causing with her unauthorized projects?”

Making sure John’s office door is closed, I say to John and Patty “Guys, help me out. What does Steve see in her? How does she get away with so much crap? Over the past couple of weeks, I see how hard-nosed Steve can be, but Sarah routinely gets away with murder. Why?”

Patty snorts. “If Steve were a woman, I’d say that he’s attracted to dangerous men. A bunch of us have speculated about this for years. I’ve had a theory, which I must say, was pretty much validated in our last off-site.”

When she sees John and me both conspiratorially leaning forward, she smiles. “Steve prides himself on being an operations guy, and he’s admitted several times in company meetings that he doesn’t have a flair for strategy. I think that’s why he loved working with his old boss and our new chairman Bob so much. For a decade, Bob was the strategy guy, and all Steve had to do was execute the vision.

“For years, Steve searched for a strategy person to be his right-hand man. He went through quite a few people, even setting a couple executives against each other in this awful, drawn out competition. Pretty Machiavellian,” she continues. “And Sarah won. The word on the street was that there was a lot of backstabbing and underhanded tactics, but I suppose that’s what it takes to come out on top. Evidently, she has mastered how to whisper the right things in his ear, reinforcing his paranoia and aspirations.”

Patty’s explanation is so much more sophisticated than anything I’ve come up with. In fact, it sounds strikingly similar to what Paige would speculate when I got that distant, angry look at dinnertime.

John says awkwardly, “Umm, you don’t think there’s anything between them, do you? Like, anything…untoward?”

I raise my eyebrows. I wondered about that, too.

Patty just bursts out laughing. “I’m a pretty good judge of people. Both my parents were psychologists. I’d eat both of their diplomas if that were true.”

Seeing the expression on my face, she laughs even harder. “Look, not even Wes believes that, and there’s no one better at manufacturing drama than him. Sarah’s *scared to death* of Steve! You ever notice that when someone is talking, Sarah is always still looking at Steve, trying to gauge his reaction? It’s freakish, actually.”

She continues, “Steve has a blind spot for Sarah’s shortcomings, because she has something he needs and admires, which is the ability to come up with creative strategies, regardless of whether the strategy is good or bad. On the other hand, because Sarah is so insecure, she’ll do whatever it takes to not look bad.

“She simply doesn’t care about the body count she leaves in her wake, because she wants to be the next CEO of Parts Unlimited.” Patty says. “And apparently, Steve does too. He’s been grooming her as his successor for years.”

“What? She could be our next CEO?” I exclaim in shock, quickly wiping up the coffee I spit out onto John’s conference table.

“Wow, boss. You don’t hang out at the water cooler much, do you?” Patty says.

---

*It’s Phoenix deployment day, *and I’ve missed Halloween with my kids.

It’s already 11:40 p.m. As we’re standing once again around the NOC conference table, I have an unsettling feeling of déjà vu. I count fifteen people here, including Chris and William.

Most people are tensely huddled around the table with laptops open, pizza boxes and candy wrappers piled behind them. Several other people are at the whiteboard, pointing at checklists or diagrams.

It took three hours longer than scheduled to migrate Phoenix into the QA test environment and get all the tests to pass. Although this is much better than the previous deployment, I thought we’ d have fewer problems, given how hard we worked on improving the deployment process,

By 9:30 p.m., we were finally ready to do the migration into production. All the tests had finally passed, and Chris and William gave the thumbs-up to deploy. Wes, Patty, and I looked at the test reports, and gave the green light to start the deployment work.

Then all hell broke loose.

One of the critical database migration steps failed. We had only completed thirty percent of the deployment steps, and once again, we were dead in the water. Due to the database changes and the scripts already run, it wasn’t possible to roll back in the time remaining before the stores opened tomorrow morning.

Once again, we had to fight our way forward, trying to get to the next step so the deployment could resume.

Leaning against the wall, I watch everyone work, arms crossed, trying not to pace. It’s frustrating that once again we are grappling with another Phoenix deployment going bad, with potentially disastrous outcomes.

On the other hand, compared to last time, things are much calmer. While there is tension, and a lot of heated arguments, everyone is intensely focused on problem solving. We’ve already notified all the store managers about our progress, and they all have manual fallback procedures ready, just in case the POS systems are down when the stores open.

I see Wes say something to Brent, stand up to rub his forehead wearily, and then walk toward me. Chris and William also get up and follow him.

I meet them halfway. “Well?” I ask.

“Well,” Wes replies when he’s close enough to speak softly and be heard. “We’ve found our smoking gun. We just discovered that Brent made a change to the production database a couple of weeks ago to support a Phoenix business intelligence module. No one knew about it, let alone documented it. It conflicts with some of the Phoenix database changes, so Chris’ guys are going to need to do some recoding.”

“Shit,” I say. “Wait. Which Phoenix module?”

“It’s one of Sarah’s projects that we released after the project freeze was lifted,” he replies. “It was before we put the kanban around Brent. It was a database schema change that slipped through the cracks.”

I swear under my breath. Sarah *again*?

Chris has a pinched expression on his face. “This is going to be tricky. We’re going to have to rename a bunch of database columns, which will affect, who knows, maybe hundreds of files. And all the support scripts. This is going to be manual work and very error-prone.”

He turns to William. “What can we do to at least get some basic testing performed before we continue the deployment?”

William looks vaguely ill, wiping sweat from his face with his hands. “This is very, very…dicey… We can test, but we still may not find the errors until we hit those lines of code. That means we’re going to have failures in production, where the application just blows up. It may even take down the in-store POS systems, and that would be bad.”

He looks at his watch. “We’ve only got six hours to complete the work. Because we don’t have enough time to rerun all the tests, we’re going to have to take some shortcuts.”

We spend the next ten minutes sketching out a revised schedule that still completes by 6 a.m., enabling the stores to open normally with an hour to spare. As Chris and William head off to notify their teams, I indicate to Wes to remain behind.

“When we’re out of the woods,” I say, “we’ve got to figure out how to prevent this from happening again. There should be absolutely no way that the Dev and QA environments don’t match the production environment.”

“You’re right,“ Wes says, shaking his head in disbelief. “I don’t know how we’re going to do it. But you’ve got no argument from me.”

He looks behind him at Brent, incredulous. “Can you believe that Brent is at the center of all of this again?”

---

*Much later, *when the deployment is declared to be complete, everyone applauds. I look at my watch. It’s 5:42 a.m. on Saturday morning. The team spent the entire night working, completing the deployment twenty minutes early. That is, twenty minutes early according to the emergency schedule we hammered out. According to the original schedule, we finished almost six hours late.

William has confirmed that the test POS systems are working, as well as the e-commerce website and all the associated Phoenix modules.

Patty has started sending out notifications to all the store managers that the deployment was “successful.” She is attaching a list of known errors to look out for, an internal web page to get the latest Phoenix status, and instructions on how they can report any new problems. We’re keeping all the service desk people on standby, and both Chris and my teams are on-call to provide early life support. Basically, we’re all on standby to support the business.

With Wes and Patty handling the on-call schedule, I say “good job” to everyone and pack up my things. On my drive home, I wrack my brain, trying to think of how we can keep each Phoenix deployment from causing an emergency.
