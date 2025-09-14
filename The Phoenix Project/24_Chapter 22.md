# Chapter 22

## • Monday, September 29

*The Monday following the audit meeting,* John disappeared. There is a betting pool in the NOC speculating whether he suffered a nervous breakdown, was fired, is just hiding, or worse.

I see Wes and some of his engineers, all laughing loudly, presumably at John’s expense.

I clear my throat to get Wes’ attention. When he walks over, I turn around so that my back is to the NOC, shielding everyone from hearing what I’m telling Wes. “Do me a favor? Don’t fan the rumor mill about John. Remember what Steve was trying to impress upon us at the off-site? We need to build a mutually respectful and trusted working relationship with him.”

Wes’ smile disappears and after a moment, he finally says, “Yeah, I know. I’m just kidding, okay?”

“Good,” I say, nodding. “Okay, enough of that. Follow me. I need to talk to you and Patty about the monitoring project.” We go to her office, where she’s sitting at her desk, typing away in a project management application, full of Gantt charts.

“Got a half hour?” I ask her.

When she nods, we gather around her conference table. I say, “I talked with Erik on Friday before the audit meeting. Here’s what I learned.”

I tell them how Erik validated that we can release the monitoring project and how important this project is to further elevate Brent. I then try to explain the thought process of how we can determine which projects we can safely release, based on whether they have any dependencies on Brent.

“Wait a second. Bill of resources and routings?” Wes says, suddenly looking very dubious. “Bill, I don’t need to remind you that we’re not running a factory here. This is IT work. We use our brains to get things done, not our hands. I know Erik has said a couple of smart things here and there, but come on… This sounds like some sort of consultant parlor trick.”

“Look, I’m having trouble getting my head around this, too,” I say. “But can you really say that the conclusions we’re making based on his thinking are wrong? Do you think it’s unsafe to release the monitoring project?”

Patty wrinkles her forehead. “We know that IT work can be projects or changes. And in many of the projects, there are many tasks or subprojects that show up over and over again. Like setting up a server. It’s recurring work. I guess you could call that a subassembly.”

She stands up, walks to the whiteboard, and draws some boxes. “Let’s use the example of configuring a server. It involves procurement, installing the OS and applications on it according to some specification, and then getting it racked and stacked. Then we validate that it’s been built correctly. Each of these steps are typically done by different people. Maybe each step is like a work center, each with its own machines, methods, men, and measures.”

With less certainty, she continues, “But I’m not sure if I know what the machine would be.”

I smile as Patty scrawls on the board. She’s making some leaps that I haven’t been able to make. I don’t know where she’ll end up, but I think she’s on the right track.

“Maybe the machine,” I speculate, “is the tools necessary to do the work? The virtualization management consoles, terminal sessions, and maybe the virtual disk space that we attach to it?”

Patty shakes her head. “Maybe. The consoles and terminals sound like they could be the machine. And I think disk space, the applications, license keys, and so forth are all actually inputs or the raw materials needed to create the outputs.”

She stares at the whiteboard. At last, she says, “I suspect that until we do a couple of these, we’ll just be stumbling in the dark. I’m starting to think that this whole work center notion actually describes IT work pretty well. For this server setup example, we know that it’s a work center that gets hit by almost every business and IT project. If we nail this down, we’ll actually be able to provide better estimates to Kirsten and all her project managers.”

“Give me a break, guys,” Wes says. “First, our work is not repetitive. Second, it requires a lot of knowledge, unlike the people who just assemble parts or tighten screws. We hire very smart people with experience. Trust me. We can’t standardize our work like manufacturing does.”

I consider Wes’ point. “Last week, I think I would have agreed with you, Wes. But I watched one of the final assembly work centers on the manufacturing floor for fifteen minutes last week. I was overwhelmed with everything that was going on. Frankly, I could barely keep up with it. Despite trying to make everything repetitive and repeatable, they still had to do an incredible amount of improvisation and problem solving just to hit their daily production goals. They’re doing a whole lot more than tightening screws. They’re performing heroics every day, using every bit of experience and smarts they have.”

I say adamantly, “They really earned my respect. If it weren’t for them, we all wouldn’t even have jobs. I think we have a lot to learn from plant floor management.”

I pause. “Let’s start the monitoring project as soon as we can. The sooner we start, the sooner we’ll get the benefits. We need to protect each of our resources as if they were all Brents, so let’s get this done.”

“There’s one more thing,” Patty says. “I keep thinking about the lanes of work we’re trying to create. I’d like to test some of these concepts with the incoming service requests, like account add/change/deletes, password resets, and—you know—laptop replacements.”

She looks uncomfortably at my giant laptop, which is in even worse shape than when I first got it three weeks ago. I’ve had to put even more duct tape on it to keep it from falling apart, due to some further damage I caused when I used my car keys to pry it open. And now, half the paint on the screen lid has flaked off.

“Oh, for crying out loud,” Wes groans, looking at it, genuinely embarrassed. “I can’t believe we haven’t gotten you a replacement. We don’t suck *that* much. Patty, I’ll find someone for you to dedicate to the laptop and desktop backlog.”

“Fantastic,” Patty replies. “I have a little experiment in mind that I’d like to try out.”

Not wanting to get in the way, I say, “Make it so.”

---

*When I get to the office on the following Monday, *Patty is waiting for me. “You have a second?” she asks, obviously eager to show me something.

Next thing I know, I’m standing in Patty’s Change Coordination Room. I immediately spot on the back wall a new board. On it: index cards arranged in four rows.

The rows are labeled “Move worker office,” “Add/change/delete account,” “Provision new desktop/laptop,” and “Reset password.”

Each row has been divided up into three columns, labeled “Ready,” “Doing,” and “Done.”

Interesting. This looks vaguely familiar. “What is this? Another change board?”

Patty breaks out into a grin and says, “It’s a kanban board. After our last meeting, I went to MRP-8 myself. I was so curious about this work center notion that I had to see it in action. I managed to find one of the supervisors that I’ve worked with before, and he spent an hour with me showing how they managed the flow of work.”

Patty explains that a kanban board, among many other things, is one of the primary ways our manufacturing plants schedule and pull work through the system. It makes demand and WIP visible, and is used to signal upstream and downstream stations.

“I’m experimenting with putting kanbans around our key resources. Any activities they work on must go through the kanban. Not by e-mail, instant message, telephone, or whatever.

“If it’s not on the kanban board, it won’t get done,” she says. “And more importantly, if it is on the kanban board, it will get done quickly. You’d be amazed at how fast work is getting completed, because we’re limiting the work in process. Based on our experiments so far, I think we’re going to be able to predict lead times for work and get faster throughput than ever.”

That Patty is now sounding a bit like Erik is both unsettling and exciting.

“What I’ve done,” she continues, “is take some of our most frequent service requests, documented exactly what the steps are and what resources can execute them, and timed how long each operation takes. Here’s the result.”

She hands me a piece of paper proudly.

It’s titled, “Laptop replacement queue.” On it is a list of everyone who’s requested either a new or replacement laptop or desktop along with when they submitted the request and the projected date they’ll receive it. They’re sorted by the oldest requests first.

I’m apparently fourteenth in line, with my laptop projected to arrive four days from now.

“You actually believe this schedule?” I say, trying to be skeptical. However, it really would be fantastic if we could actually publish this to everyone, and be able to hit those dates.

“We worked on this all weekend long,” she replies. “Based on the trials we’ve done since Friday, we’re pretty confident that we understand the time required go from start to finish. We’ve even figured out how to save a bunch of steps by changing where we’re doing disk mirroring. Between you and me, based on the time savings we’re generating, I think that we’ll beat these dates.”

She shakes her head. “You know, I did a quick poll of people we’ve issued laptops to. It usually takes fifteen turns to finally get them configured correctly. I’m tracking that now, and trying to drive this down to three. We’re putting in checklists everywhere, especially when we do handoffs within the team. It’s really making a difference. Error rates are way down.”

I smile and say, “This is important. Getting executives and workers the tools they need to do their jobs is one of our primary responsibilities. I’m not saying I don’t believe you, but let’s keep these time estimates to ourselves for now. If you can generate a week’s track record of hitting the dates, then let’s start publishing this to all the requesters and their managers, okay?”

Patty smiles in return. “I was thinking the same thing. Imagine what this will do to user satisfaction if we could tell them when they make the request how long the queue is, tell them to the day when they’ll get it, and actually hit the date, because we’re not letting our workers multitask or get interrupted!

“My plant supervisor friend also told me about the Improvement Kata they’ve adopted. Believe it or not, Erik helped them institute it many years ago. They have continual two-week improvement cycles, each requiring them to implement one small Plan-Do-Check-Act project to keep them marching toward the goal. You don’t mind that I’ve taken the liberty of adopting this practice in our group to keep us moving toward our own goals, right?”

Erik had mentioned this *kata* term and the continual two-week improvement cycles before. Once again, Patty is at least one step ahead of me.

“This is great work, Patty. Really, really well done.”

“Thanks,” she modestly responds, but she’s grinning from ear to ear. “I’m really excited by what I’m learning. For the first time, I’m seeing how we should be managing our work, and even for these simpler service desk tasks, I know it’s going to make a big difference.”

She points at the change board at the front of the room. “What I’m really looking forward to is to start using these techniques for more complex work. Once we figure out what our most frequently recurring tasks are, we need to create work centers and lanes of work, just like I did for my service requests. Maybe we can even get rid of some of this scheduling, and create kanban boards instead. Our engineers could then take any card from the Ready column, move them to Doing, until they’re Done!”

Unfortunately, I can’t visualize it. “Keep going. Just make sure you’re working with Wes on this, and that he’s onboard, okay?”

“Already on it,” she replies quickly. “In fact, I have a meeting with him later today to discuss putting a kanban around Brent, to further isolate him from our daily crises. I want to formalize how Brent gets work and increase our ability to standardize what he’s working on. It’ll give us a way to figure out where all of Brent’s work comes from, both on the upstream and downstream sides. And of course, it will give us one more line of defense from people doing drive-bys on Brent.”

I give her a thumbs-up, and get ready to leave. “Wait, the change board looks different. Why are the cards different colors?”

She looks at the board and says, “Oh, I haven’t told you? We’re color-coding the cards to help us get ready for when we lift the project freeze. We’ve got to have some way to make sure we’re working on the most important things. So, the purple cards are the changes supporting one of the top five business projects, otherwise, they’re yellow. The green cards are for internal IT improvement projects, and we’re experimenting with allocating twenty percent of our cycles just for those, as Erik recommended we do. At a glance, we can confirm that there’s the right balance of purple and green cards in work.”

She continues, “The pink sticky notes indicate the cards that are blocked somehow, which we’re therefore reviewing twice a day. We’re also putting all these cards back into our change tracking tool, so we’re putting the change IDs on each of the cards, too. It’s a bit tedious, but at least now part of the tracking is automated.”

“Wow, that’s…incredible,” I say, with genuine awe.

---

*Later that day, *I’m sitting down at another conference table with Wes and Patty to figure out how we’re going to turn the project faucet back on slowly enough so we can drink but don’t end up drowning.

“As Erik pointed out, we actually have two project queues that we need to sequence: business and internal projects,” Patty says, pointing to the thin stapled set of papers in front of us. “Let’s do the business projects first, because they’re easier. We have the top five most important projects identified, as ranked by all the project sponsors. Four of these will require some work from Brent. When the freeze lifts, we propose that we only release these five projects.”

“That was easy,” Wes laughs. “I can’t believe how much arguing, posturing, horse-trading, and backstabbing went on to get the top five projects identified. It was worse than Chicago politics!”

He’s right. But in the end, we got our prioritized list.

“Now to the hard part. We’re still struggling on how to prioritize our own seventy-three internal projects,” she says, her expression turning glum. “There’s still way too many. We’ve spent weeks with all the team leads trying to establish some sort of relative importance level, but that’s all we’ve done. Argue.”

She flips to the second page. “The projects seem to fall into the following categories: replacing fragile infrastructure, vendor upgrades, or supporting some internal business requirement. The rest are a hodgepodge of audit and security work, data center upgrade work, and so forth.”

I look at the second list, scratching my head. Patty is right. How does one objectively decide whether “consolidating and upgrading e-mail server” is more or less important than “upgrading thirty-five instances of SQL databases”?

I run my fingers down the page, trying to see if anything jumps out at me. It’s the same list I saw during my first week on the job, and they still all look important.

Realizing that Wes and Patty have spent almost a week with this list, I try to elevate my thinking. There’s got to be some simple way to prioritize this list that doesn’t look like moving a bunch of boxes around.

Suddenly, I remember how Erik described the importance of preventive work, such as the monitoring project. I say, “I don’t care how important everyone *thinks* their project is. We need to know whether it increases our capacity at our constraint, which is *still* Brent. Unless the project reduces his workload or enables someone else to take it over, maybe we shouldn’t even be doing it. On the other hand, if a project doesn’t even require Brent, there’s no reason we shouldn’t just do it.”

I say assertively, “Give me three lists. One that requires Brent work, one that increases Brent’s throughput, and the last one is everything else. Identify the top projects on each list. Don’t spend too much time ordering them—I don’t want us spending days arguing. The most important list is the second one. We need to keep Brent’s capacity up by reducing the amount of unplanned work that hits him.”

“That sounds familiar,” Patty says. She digs up the list of fragile services that we created for the change management process. “We should make sure we have a project to replace or stabilize each one of these. And maybe we suspend indefinitely any infrastructure refresh project for anything that’s not fragile.”

“Now hang on a minute,” Wes says. “Bill, you said it yourself. Preventive work is important, but it always gets deferred. We’ve been trying to do some of these projects for years! This is our chance to get caught up.”

Patty says quickly, “Didn’t you hear what Erik told Bill? Improving something anywhere not at the constraint is an illusion. You know, no offense, but you sort of sound like John right now.”

Despite my best attempts, I still laugh.

Wes turns red for a moment, and then laughs loudly. “Ouch. Okay, you got me. But I’m just trying to do the right thing.”

“Doh!” he says, interrupting himself. “I did it again.”

We all laugh. It makes me wonder how John is doing. To the best of my knowledge, no one has seen him all day.

While Wes and Patty are scribbling notes, I scan the list of internal projects again. “Hey, why is there a project for upgrading the BART database even though it’s going to be decommissioned next year?”

Patty peers down at her list and then looks embarrassed. “Oh, jeez. I didn’t see that because we never reconciled the business and IT projects with each other. We’re going to have to scrub the lists one more time to find dependencies like this. I’m sure there are others.”

Patty thinks for a moment, “It’s strange. Even though we have so much data on projects, changes, and tickets, we’ve never organized and linked them all together this way before.

“Here’s another thing we can learn from manufacturing, I think,” she continues. “We’re doing what Manufacturing Production Control Departments do. They’re the people that schedule and oversee all of production to ensure they can meet customer demand. When they accept an order, they confirm there’s enough capacity and necessary inputs at each required work center, expediting work when necessary. They work with the sales manager and plant manager to build a production schedule so they can deliver on all their commitments.”

Again, Patty is way ahead of me. This answers one of the first questions that Erik tasked me with before I quit. I make a note for us to visit MRP-8 to see their production control processes.

I get a creeping suspicion that “managing the IT Operations production schedule” should be somewhere in my job description.

---

*Two days later, *I’m surprised to see a new laptop in my office. My old laptop has been disconnected and moved to the side.

I look at my clipboard, flipping back to the laptop/desktop replacement schedule that Patty gave me earlier this week.

Holy crap.

Patty had promised laptop delivery for Friday, and I’m receiving it two days early.

I log on to make sure it’s been configured properly. All the applications seem to be there, all my data have been transferred, e-mail is working, the network drives show up like before, and I can install new applications.

I feel tears of gratitude welling up when I see how fast my new laptop is. Grabbing Patty’s schedule, I go next door. “I love the new laptop. Two days ahead of schedule, even. Everyone ahead of me got their systems, too, right?”

Patty grins. “Yep. Every single one of them. A couple of the early ones we delivered had a few configuration errors or were missing something. We’ve corrected it in the work instructions, and we seem to be batting one hundred percent delivering correct systems for the past two days.”

“Great work, Patty!” I say, excitedly. “Go ahead and start publishing the schedule. I want to start showing this off!”
