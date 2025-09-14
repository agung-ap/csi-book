# Chapter 6

## • Friday, September 5

*In another one of the endless Phoenix status meetings,* I realize that the developers are even more behind than we feared. As Wes had predicted, more and more work is being deferred to the next release, including almost all of the testing.

This means that we’ll be the ones finding the problems when they blow up in production, instead of the Quality Assurance (QA) Department.

Great.

During a lull in the discussion, I look down at my phone and see an e-mail from Patty. She wants to meet about resourcing, promising some eye-opening surprises.

I open the attached spreadsheet, seeing an encouraging level of detail, but on my minuscule phone screen, I can’t make heads or tails of it. I reply to Patty that I’m on the way and ask her to have Wes meet me there.

When I arrive, I’m surprised to see that Wes has set up a projector, displaying a spreadsheet on the wall. I’m excited that we’re meeting to analyze the situation, instead of just reacting to the daily fires.

I grab a seat. “Okay, whatcha got for me?”

Wes starts. “Patty did a great job putting this together. What we found was—well, it was interesting.”

Patty explains, “We did our interviews, collected the data, and then did our analysis. Right now, these numbers are only for our key resources. We’re already seeing something troubling.”

She points at a row in the spreadsheet. “First, we have a lot of projects. Kirsten says she’s officially managing about thirty-five major business projects, each of which we have commitments to. Internal to IT Operations, we’ve already identified over seventy projects, and that number keeps growing with each person we interview.”

“Wait,” I say, genuinely startled, sitting upright in my chair. “We have 150 IT Operations people, right? If you’ve already found over 105 projects, that’s 1.5 people per project. Doesn’t that seem like a lot to you?”

Wes replies, “Totally. And we know that the project count is low. So by the end, it’ll probably be more like one person per project. That’s insane.”

I ask, “How big are these internal projects?”

Wes switches tabs on the spreadsheet, showing the list of projects they’ve inventoried, along with the estimated number of man-weeks. “Consolidate and upgrade e-mail server,” “Upgrade thirty-five instances of Oracle databases,” “Install supported Lemming database server,” “Virtualize and migrate primary business applications,” and so on.

I groan. While some projects are small, most seem like major undertakings, estimated at three man-years or more.

When Patty sees the expression on my face, she says, “That was my reaction, too. We’re on the hook for a huge number of projects. So, let’s look at what our capacity is. This is a little harder, since we can’t just assign random people to any given project.”

She continues, “When we looked at who was assigned to each project and what their other commitments and availability were, here’s what we found.”

When Wes flips to another spreadsheet tab, my heart drops.

“Grim, huh?” says Wes. “Most of our resources are going to Phoenix. And look at the next line: Compliance is the next largest project. And even if we only worked on compliance, it would consume most of our key resources for an entire year! And that includes Brent, by the way.”

Incredulous, I say, “You’re kidding. If we put all our projects on hold except for the audit findings, our key resources would be tied up for an entire year?”

“Yep,” Patty says, nodding. “It’s hard to believe, but it just shows you how much work is in that stack of audit findings.”

I look down at the table, speechless.

If someone had shown me these figures during my first conversation with Steve, I would have run from the room, screaming like a little boy.

It’s not too late, I think, smiling at the image.

With practiced calm, I say, “Okay, knowing is always better than not knowing. Keep going.”

Wes looks back at the spreadsheet. “The third largest item is incident and break-fix work. Right now, it’s probably consuming seventy-five percent of our staff’s time. And because these often involve critical business systems, incidents will take priority over everything else, including Phoenix and fixing audit findings.

“By the way, did you know that yesterday, when we were talking with Brent, we had to reschedule the interview twice because he had to go help fix an outage? So there we were interrupting him from Phoenix work, only to be interrupted by an outage!” he says, laughing.

I start to laugh, but then stop abruptly. “Wait. What outage? Why didn’t I hear about it? We can’t keep running our organization like this!”

“Well, it was another SAN issue, but nothing critical,” Wes replies. “A drive went bad a couple of months ago, so the SAN was running with no redundancy. When another drive failed, the entire volume went down. Brent had to help restore some of the databases when we got the SAN back up.”

Exasperated, I shout, “Dang it, Wes. That was completely preventable! Get one of your junior guys to look at the logs every day for drive failures. Maybe even have him visually inspect the drives and count all the blinking lights. It’s called preventive maintenance for a reason! We need Brent on Phoenix, not piddly shit like this!”

Wes says defensively, “Hey, it’s actually a little more complicated than that. We put in the order for replacement drives, but they’ve been stuck in Procurement for weeks. We had to get one of our vendors to give it to us on credit. This wasn’t our fault.”

I lose my temper. “Wes, listen to me. I DON’T CARE! I don’t care about Procurement. I don’t care how nice your inept vendors are. I need you to do your job. Make sure this doesn’t happen again!”

I take a deep breath. I realize my frustration is not because of the drive failure, but because we’re continually unable to stay focused on the things that matter most to the company.

“Look, let’s put this aside for now,” I say, looking back at Wes. “I’m serious about getting someone to look at that SAN daily, though. Set up a meeting sometime next week for you, me, and Patty to get to the bottom of these outages. We’ve got to figure out how to bring down the amount of break-fix work so we can get project work done. If we can’t get Phoenix work done, it’s jeopardizing the company.”

“Yeah, I got it. I’ll try to get it in before the Phoenix rollout.” Wes says, nodding sullenly. “And I’ll get on that SAN issue this afternoon.”

“Okay, back to the spreadsheet,” I say.

Patty observes glumly, “You’re right. The one consistent theme in the interviews was that everyone struggles to get their project work done. Even when they do have time, they struggle to prioritize all their commitments. People in the business constantly ask our staff to do things for them. Especially Marketing.”

“Sarah?” I ask.

“Sure, but it’s not only her,” she replies. “Practically every executive in the company is guilty of going directly to their favorite IT person, either asking a favor or pressuring them to get something done.”

“How do we change the game here and get resourced to do all these projects properly?” I ask. “What should we be asking Steve for?”

Wes scrolls down his spreadsheet. “Based on our rough numbers, we’ll probably need to hire seven people: three database administrators, two server engineers, one network engineer, and one virtualization engineer. Of course, you know that it’ll take time to find these people and then another six to twelve months before they’re fully productive.”

Of course, I knew that new hires aren’t productive right away. But it was still dispiriting to hear Wes point out that real help was still a long way off, even if Steve approved the headcount.

---

*Later that day, *as I’m walking to our second CAB meeting, I feel hopeful. If we can get our old change process going, we might be able to quickly resolve one of the largest audit issues and get some operational wins, as well.

I’m also pleased at how well Patty and Wes are working together.

As I near the conference room, I hear loud voices arguing.

“—then Patty got that engineer fired for doing his job. He was one of our best networking people. That wasn’t your call to make!”

No mistake. That’s Wes hollering. Then I hear Patty reply heatedly, “What? You signed off on that termination! Why is this suddenly my fault?”

I knew it was too good to be true.

I then hear John say, “That was the right call. We’re going into our third year of a repeat audit finding around change controls. That goes in front of the audit committee. Next time around, it probably won’t be just an engineer getting fired, if you get my drift.”

Wait. Who invited John to this meeting?

Before John can make things any worse, I quickly step through the door and say cheerfully, “Good afternoon, everyone! Are we ready to review some changes?”

Fourteen people turn to look at me. Most of the technical leads from the various groups are sitting at the table. Wes is standing up behind his chair, fuming, while Patty is standing in the front of the room, arms crossed.

John sits in the back of the room, with his three-ring binder open, very much an unwanted guest.

Using both hands, I set down my antique laptop. It hits the table with a thud and a clatter as the battery falls off, the tape no longer holding it in place, and then I hear a scratching sound as the disk drive spins down.

Wes’ angry expression disappears momentarily. “Wow, boss, nice gear. What is that, a Kaypro II? I haven’t seen one of those in about thirty years. Let me know if you need an 8-inch floppy to load CP/M on it—I’ve got one in my attic at home.”

Two of the engineers snicker and point. I smile briefly at Wes, grateful for the comic relief.

Remaining standing, I say to everyone, “Let me tell you why I assembled all of you here. Given the urgency of Phoenix, you can bet your ass that I wouldn’t waste your time if I didn’t think this was important.”

I continue, “First, the events that led to the SAN and payroll failure on Tuesday must not happen again. What started off as a medium-sized payroll failure snowballed into a massive friendly-fire SAN incident. Why? Because we are not talking to one another about what changes we’re planning or implementing. This is not acceptable.”

“Second, John is right. We spent yesterday morning with our auditors, discussing a bunch of deficiencies they found,” I continue. “Dick Landry is already crapping bricks because it could impact our quarterly financial statements. We need to tighten up our change controls, and as managers and technical leads, we must figure out how we can create a sustainable process that will prevent friendly-fire incidents and get the auditors off our back, while still being able to get work done. We are not leaving this room until we’ve created a plan to get there. Understood?”

When I’m satisfied that everyone has been properly cowed, I open it up for discussion. “So what’s preventing us from getting there?”

One of the technical leads quickly says, “I’ll start. That change management tool is impossible to use. There’s a million mandatory fields and most of the time, the drop down boxes for the ‘applications affected’ don’t even have what I need. It’s why I’ve stopped even putting in change requests.”

Another lead hollers out, “He’s not kidding. To follow Patty’s rules, I have to manually type in hundreds of server names in one of the text boxes. Most of the time, there’s not enough room in the field! A hundred server names are supposed to fit in a sixty-four-character text box? What idiot built that form?”

Again, more unkind laughter.

Patty is bright red. She shouts, “We need to use drop-down boxes so we can maintain data integrity! And I’d love to keep the application list up-to-date, but I don’t have the resources. Who’s going to keep the application catalog and change management database current? You think it just magically updates itself?”

“It’s not just the tool, Patty. It’s the entire broken process,” Wes asserts. “When my guys put in change requests, they have to wait a lifetime to get approvals, let alone get on the schedule. We have the business breathing down our neck to get crap done. We can’t wait for you to hem and haw, complaining that we didn’t fill out the form right.”

Patty snaps, “That’s crap, and you know it. Your people routinely break the rules. Like, say, when everyone marks all their change requests as an ‘urgent’ or ‘emergency change’. That field is only for actual emergencies!”

Wes retorts, “We have to do that, because marking them urgent is the only way to get your team to look at it! Who can wait three weeks for an approval?”

One of the lead engineers suggests, “Maybe we make another field called ‘extremely urgent?’ ”

I wait until the uproar quiets down. At this rate, we’re getting nowhere fast. Thinking furiously, I finally say, “Let’s take a ten-minute break.”

When we reconvene the meeting, I say, “We are not leaving this meeting without a list of authorized and scheduled changes that we’re implementing in the next thirty days.

“As you can see, my assistant has brought in a pile of blank index cards. I want each group to write down every change they’re planning, one change per index card. I want three pieces of information: who is planning the change, the system being changed, and a one-sentence summary.

“I’ve drawn a calendar on the whiteboard where we will eventually post approved changes according to their scheduled implementation,” I continue. “Those are the rules. Short and simple.”

Wes picks up a pack of cards, looking at them dubiously. “Really? Paper cards, in this day and age? How about we use that laptop of yours, which probably even predates paper?”

Everyone laughs, but not Patty. She looks angry, obviously not pleased with the direction things are going.

“This isn’t like any change management process I’ve ever seen,” John says. “But I’ll put my changes on the board, like the upcoming firewall updates and monitoring changes that’re scheduled for the next couple of days.”

Surprisingly, John’s willingness to jump in inspires others, who begin writing their planned changes on their cards.

Finally, Wes says, “Okay, let’s try it. Anything is better than using that busted change management tool.”

One of the leads holds up a handful of cards. “I’m done with all the database changes we’re planning to make.”

When I nod for him to proceed, he quickly reads one of the cards: “Execute the vendor-recommended database maintenance script on Octave server XZ577 to fix retail store POS performance issues. This affects the order entry database and applications. We’ d like to do this next Friday evening at 8:30 p.m.”

I nod, pleased with the clarity of his proposed change. But Wes says, “That’s not a change! That’s just running a database script. If you were changing the script, then we’ d have something to talk about. Next.”

The lead replies quickly, “No, it’s definitely a change. It temporarily changes some database settings, and we don’t know what production impact it could have. To me, it’s just as risky as a database configuration change.”

Is it a change or not? I can see both sides of the argument.

After thirty minutes of arguing, it’s still not clear that we know the definition of what a “change” should be.

Was rebooting a server a change? Yes, because we don’t want anyone rebooting servers willy-nilly, especially if it’s running a critical service.

How about turning off a server? Yes, for the same reason.

How about turning on a server? No, we all thought. That is, until someone came up with the example of turning on a duplicate DHCP server, which screwed up the entire enterprise network for twenty-four hours.

A half hour later, we finally write on the whiteboard: “a ‘change’ is any activity that is physical, logical, or virtual to applications, databases, operating systems, networks, or hardware that could impact services being delivered.”

I look at my watch, alarmed that we’ve been in the room for nearly ninety minutes, and we still haven’t even approved our first change. I push us to move faster, but at the end of our two-hour meeting, we’ve only posted five changes on the whiteboard.

Surprisingly, no one else seems frustrated except me. Everyone is vigorously engaged in the discussion, even Patty. Everyone is discussing risks of the proposed changes, even discovering that one change wasn’t necessary.

Encouraged, I say, “We’ll pick this up on Monday. Get all your cards to Patty as soon as you can. Patty, what’s the best way for us to process all the cards?”

She says tersely, “I’ll set up a basket later today. In the meantime, pile them up at the front of the table.”

When we adjourn, several people tell me on their way out, “Great meeting,” and “I wish we had more time to discuss changes,” and “I’m looking forward to Monday.”

Only Patty has remained behind, arms crossed. “We spent a lot of blood, sweat, and tears creating our old change management policy, and everyone still blew it off. What makes you think this will be any different?”

I shrug. “I don’t know. But we’ll keep trying things until we have a system that works, and I’m going to make sure everyone keeps helping us get there. It’s not just to satisfy the audit findings. We need some way to plan, communicate, and make our changes safely. I can guarantee you that if we don’t change the way we work, I’ll be soon out of a job.”

Pointing at her old policy document, she says, “We shouldn’t just throw all this work out the window. We spent weeks designing it and hundreds of thousands of dollars with consultants, changing our tools around.”

She tears up slightly. I remind myself of how long she’s been trying to get this process integrated into the organization.

“I know that there was a lot of good work put into all this process,” I say sympathetically. “Let’s face it, though. No one was actually following it, as the auditors pointed out. We also know that people were gaming the system, just trying to get their work done.”

I say sincerely, “We may be starting over, but we need all your experience and skills to make this work. It’s still your process, and I know this is absolutely critical to our success.”

“Okay,” she says, sighing in resignation. “I suppose I care more about our survival than whether we use our old process or not.”

Her expression changes. “How about I write up the outputs of the meeting and the new instructions for submitting requests for changes?”

---

*Later that afternoon, *I’m back in the Phoenix war room when Patty calls. I run out to the hallway. “What’s up?”

She sounds stressed. “We’ve got a problem. I was expecting we’ d have fifty changes for us to review next week. But we’re already up to 243 submitted changes. I keep getting e-mails from people saying to expect more cards over the weekend… I think we’re looking at over four hundred changes being made next week!”

Holy crap. Four hundred? How many of these four hundred changes are high risk, potentially affecting Phoenix, the payroll application, or worse?

I suddenly remember Rangemaster duty in the Marines. As Rangemaster, I was responsible for the safety of everyone on the firing range. I have a horrifying vision of a mob of four hundred unsupervised eighteen-year-olds jumping out of trucks, running to the firing range, firing their rifles into the air, hooting and hollering…

“Umm, at least people are following the process,” I say, laughing nervously.

I hear her laugh. “With all the change requests coming in, how are we going to get them all authorized by Monday? Should we put a temporary hold on changes until we get them all approved?”

“Absolutely not,” I say immediately. “The best way to kill everyone’s enthusiasm and support is to prevent them from doing what they need to do. I doubt we’ll get a second chance to get this right.

“Send out an e-mail telling everyone to submit any change for next week by Monday. Monday’s changes will not need to be authorized but changes for the remainder of the week will. No exceptions.”

I can hear Patty typing over the phone. “Got it. I’ll probably need to have some of my people help organize all of the change cards over the weekend. Frankly, I’m stunned by how many changes there are.”

So am I.

“Excellent,” I say, leaving my concerns unvoiced.
