# Chapter 32

## • Monday, November 10

*The next two weeks fly by* with the SWAT team activities taking up much of my time, as well as Wes’ and Patty’s.

It’s been over a decade since I’ve had daily interactions with developers. I had forgotten how quirky they can be. To me, they seem more like indie musicians than engineers.

In my day, developers wore pocket protectors—not vintage T-shirts and sandals—and carried slide rules, not skateboards.

In many ways, most of these guys are my temperamental opposites. I like people who create and follow processes, people who value rigor and discipline. These guys shun process in favor of whim and whimsy.

But thank goodness they’re here.

I know that stereotyping an entire profession isn’t fair. I know that all these diverse skills are vital if we want to succeed. The challenge is how to pull all of us together, so that we’re working toward the same goal.

The first challenge: to name the SWAT team project. We couldn’t keep calling it “mini-Phoenix,” so we eventually had to spend an hour debating names.

My guys wanted to call it “Cujo” or “Stiletto.” But the developers wanted to call it “Unicorn.”

Unicorn? Like rainbows and Care Bears?

And against all my expectations, “Unicorn” wins the vote.

Developers. I’ll never understand them.

Regardless of my distaste for the name, Project Unicorn was shaping up amazingly well. With the objective of doing whatever it takes to deliver effective customer recommendations and promotions, we started with a clean code base that was completely decoupled from the Phoenix behemoth.

It was amazing to see how this team tackled obstacles. One of the first challenges was to start analyzing the customer purchase data, which was the first brick wall. Even touching the production databases meant linking to their libraries, and any changes to them would require convincing the architecture team to approve it.

Since the entire company could be out of business by that time, the developers and Brent decided to create a completely new database, using open source tools, with data copied from not only Phoenix but also the order entry and inventory management systems.

By doing this, we could develop, test, and even run in operations without impacting Phoenix or other business critical applications. And by decoupling ourselves from the other projects, we could make all the changes we needed to without putting other projects at risk. At the same time, we wouldn’t get bogged down in the processes that we didn’t need to be a part of.

I wholeheartedly approved and applauded this approach. However, a small part of me wondered how we’re going to manage the inevitable sprawl, if every project could spawn a new database on a whim. I remind myself to ensure that we standardize what types of databases we can put into production to ensure that we have the right skills to support these long-term.

In the meantime, Brent worked with William’s team to create the build procedures and automated mechanisms that could simultaneously create the Dev, QA, and Production environments. We were all astonished that within the three-week sprint, perhaps for the first time in memory, all the developers were using exactly the same operating system, library versions, databases, database settings, and so forth.

“This is unbelievable,” one of the developers said at the sprint retrospective, held at the end of each sprint. “For Phoenix, it takes us three or four weeks for new developers to get builds running on their machine, because we’ve never assembled the complete list of the gazillion things you need installed in order for it to compile and run. But now all we have to do is check out the virtual machine that Brent and team built, and they’re all ready to go.”

Similarly, we were all amazed that we had a QA environment available that matched Dev so early in the project. That, too, was unprecedented. We needed to make a bunch of adjustments to reflect that the Dev systems had considerably less memory and storage than QA, and QA had less than those in Production. But the vast majority of the environments were identical and could be modified and spun up in minutes.

Automated code deployments weren’t quite working yet, nor was the migration of code among the environments, but William’s team had demoed enough of those capabilities that we all had confidence that they’d have it nailed down soon.

On top of that, the developers had hit their feature sprint goals ahead of schedule. They generated reports showing “customers who bought this product bought these other products.” The reports were taking hundreds of times longer than expected, but they promised that they could improve performance.

Because of our rapid progress, we decided to shrink the sprint interval to two weeks. By doing this, we could reduce our planning horizon, to make and execute decisions more frequently, as opposed to sticking to a plan made almost a month ago.

Phoenix continues to operate on a plan written over three years ago. I try not to think about that too much.

Our progress seemed to be improving exponentially. We’re planning and executing faster than ever, and the velocity gap between Unicorn and Phoenix keeps getting larger. The Phoenix teams are taking notice and starting to borrow practices left and right and getting results that we hadn’t thought possible.

Unicorn momentum seems unstoppable and now has a life of its own. I doubt we could have made them stop and go back to the old way, even if we wanted to.

---

*While I’m in the middle *of a budgeting meeting, Wes calls. “We’ve got a big problem.”

Stepping out of the room, I say, “What’s up?”

“No one has been able to find Brent for the last two days. You have any idea where he is?” he asks.

“No,” I reply. “Wait, what do you mean you can’t find him? Is he okay? You’ve tried his cell phone, right?”

Wes doesn’t bother hiding his exasperation. “Of course I called his cell phone! I’ve been leaving voicemails for him hourly. Everyone is trying to find him. We’ve got work up the wazoo, and his team mates are starting to freak out that—holy crap, it’s Brent calling… Hang on…“

I hear him pick up his desk phone, saying, “Where the hell have you been? Everyone is looking for you! No… No… Des Moines? What are you doing there? Nobody told me… A secret mission for Dick and Sarah? What the fuck—”

I listen to him for a couple of moments with some amusement as Wes attempts to get to the bottom of the situation with Brent. Finally I hear him say, “Hang on a second. Let me find out what Bill wants to do…” as he picks up his cell phone again.

“Okay, you must have heard some of that, right?” he says to me.

“Tell him I’m calling him right now.”

After I hang up, I dial up Brent, wondering what Sarah has done now.

“Hi, Bill,” I hear him say.

“Mind telling me what’s going on and why you’re in Des Moines?” I ask politely.

“Nobody from Dick’s office told you?” he asks. When I don’t say anything, he continues, “Dick and the finance team rushed me out the door yesterday morning to be a part of a task force to create a plan to split up the company. Apparently, this is a top priority project, and they need to figure out what the implications to all the IT systems are.”

“And why did Dick put you on the team?” I ask.

“I don’t know,” he replies. “Trust me, I don’t want to be here. I hate airplanes. They should have one of their business analysts doing this, but maybe it’s because I know the most about how the major systems connect to one another, where they all reside, all the services they depend on… By the way, I can tell you right now that splitting up the company will be a complete nightmare.”

I remember when I led the acquisition integration team when we acquired the large retailer. That was a huge project. Splitting the company up may be even more difficult.

If this is going to impact every one of the hundreds of applications we support, Brent is probably right. It will take years.

IT is everywhere, so it’s not like cutting off a limb. It’s more like splitting up the nervous system of the company.

Remembering that Dick and Sarah yanked one of my key resources away from me without even asking, I say slowly and deliberately, “Brent, listen carefully: Your most important priority is to find out what your Unicorn teammates need and get it to them. Miss your flight if you have to. I’ll make some phone calls, but there’s a good chance that my assistant Ellen will book you a return flight home tonight. Do you understand?”

“You want me to deliberately miss my flight,” he says.

“Yes.”

“What will I tell Dick and Sarah?” he asks, uncertainly.

I think for a moment. “Tell them I need you on an emergency call, and that you’ll catch up with them.”

“Okay…” he says. “What’s going on here?”

“It’s simple, Brent,” I explain. “Unicorn is the one last hope we have of hitting our quarterly number. One more blown quarter, and the board will surely split the company apart, and you’ll be able to help the task force then. But if we hit our numbers, we have a shot at keeping the company together. That’s why Unicorn is our absolute highest priority. Steve was very clear on this.”

Brent says dubiously, “Okay. Just tell me where to go, and I’ll be there. I’ll leave you to argue with the mucky-mucks.” He is clearly annoyed by the mixed signals being sent to him.

But not nearly as annoyed as I am.

I call Steve’s assistant Stacy and tell her I’m on my way.

---

*As I make my trek *to Building 2 to find Steve, I call Wes.

“You did what?” he chortles. “Just great. You’re now in the middle of a political battle with Steve on one side and Dick and Sarah on the other. And, quite frankly, I’m not sure you chose the winning side.”

After a moment, he says, “You really think Steve is going to back us up on this one?”

I suppress a sigh. “I sure hope so. If we don’t get Brent back full-time, Unicorn is sunk. And that probably means that we’ll get a new CEO, get outsourced, and also figure out how to split up the company. That sound like a fun job to you?”

I hang up and walk into Steve’s office. He smiles wanly and says, “Good morning. Stacy says you have some bad news for me.”

As I tell him what I learned during my phone call with Brent, I’m surprised to see his face turn scarlet. I would have thought he knew about all of this, given that he’s the CEO.

Obviously not.

After a moment, he finally says, “The board assured me that they wouldn’t go further down the company breakup path until we see how this quarter turns out. I suppose they ran out of patience.”

He continues, “So tell me what the impact is to Unicorn if Brent gets reassigned.”

“I’ve talked with Chris, Wes, and Patty,” I reply. “Project Unicorn would be completely sunk. I’m a skeptical guy by nature, but I really think Unicorn is going to work. With Thanksgiving only two weeks away, Brent owns a significant portion of getting the capabilities we need built. And by the way, many of the breakthroughs we’re making are starting to be copied by the Phoenix team, which is fantastic.”

To underscore my point, I say with finality, “Without Brent, we will not be able to hit any of the sales and profit goals that we’ve tied to Unicorn. No chance.”

Pursing his lips, Steve asks, “And what happens if you backfill Brent with your next best guy?”

I relay to Steve what Wes told me, which mirrored my own thinking. “Brent is very unique. Unicorn needs someone who has the respect of the developers, has enough deep experience with almost every sort of IT infrastructure we have, and can describe what the developers need to build so that we can actually manage and operate in production. Those skills are rare, and we don’t have anyone else that can rotate into this special role right now.”

“And what if you assign your next best person to Dick’s task force?” he asks.

“I’d guess that the breakup planning won’t be as accurate but could still get completed just fine,” I reply.

Steve leans back in his chair, saying nothing.

Finally he says, “Get Brent back here. I’ll handle the rest.”
