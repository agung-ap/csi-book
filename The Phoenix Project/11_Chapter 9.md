# Chapter 9

## • Tuesday, September 9

*I’m in the most ruthless budget meeting* I’ve ever attended. Dick sits in the back of the room, listening attentively and occasionally officiating. We all defer to him, as he’ll create the first cut of the annual plan. Sarah sits next to him, tapping away on her iPhone.

I finally pick up the phone. It must be a genuine emergency. It’s been vibrating almost nonstop for the past minute.

I read, “Sev 1 incident: credit card processing systems down. All stores impacted.”

Holy crap.

I know I’ve got to leave this meeting, despite knowing that everyone will try to steal my budget. I stand up, struggling with the large laptop, trying to keep more pieces from falling off. I almost make it out when Sarah says, “Another problem, Bill?”

I grimace. “Nothing that we can’t handle.”

In reality, any Sev 1 outage automatically qualifies as a very big problem, but I don’t want to give her any ammunition.

When I get to the NOC, I grab the seat next to Patty, who is coordinating the call. “Everyone, Bill just joined us. To catch you up, we have confirmed that the order entry systems are down and we have declared a Sev 1 incident. We were just trying to establish what changed.”

She pauses, looking at me. “And, I’m not confident we actually know.”

I prompt everyone, “Patty asked a pretty simple question. So, what were all the changes made today that could have led to this outage?”

There is an awkward silence that stretches on as people either look down or look around at one another suspiciously. Everyone is avoiding eye contact.

I’m about to say something when I hear, “This is Chris. I told Patty this before, and I’m telling you again now, none of my developers changed anything. So cross us off your hit list. It was probably a database change.”

Someone at the end of the table says angrily, “What? We didn’t make any changes—well, not on anything that could have impacted the order entry systems. Are you sure it wasn’t an operating system patch gone wrong again?”

Someone two seats over then sits up and says heatedly, “Absolutely not. We don’t have any updates scheduled to hit those systems for another three weeks. I’d bet fifty bucks it was a networking change—their changes are always causing problems.”

Slapping both hands over his eyes, Wes shouts, “For crying out loud, guys!”

Looking exasperated and resigned, he says to someone across the table, “You need to defend your honor, too? Everyone might as well have a turn.”

Sure enough, the Networking lead across the table from him holds up both hands, looking hurt and aggrieved. “You know, it really isn’t fair that Networking keeps getting blamed for outages. We didn’t have any changes scheduled for today.”

“Prove it,” the database manager challenges.

The Networking lead turns bright red, his voice cracking. “This is bullshit! You’re asking me to prove that we didn’t do anything. How the hell do you prove a negative? Besides, I’m guessing the problem is a bad firewall change. Most of the outages in the last couple of weeks were caused by one of them.”

I know I should probably put an end to this madness. Instead, I force myself to lean back in my chair and keep observing, one hand covering my mouth to hide my angry scowl and to keep me from saying something rash.

Patty looks exasperated and turns to me. “No one from John’s team is present on the call. His team handles all the firewall changes. Let me try getting a hold of him.”

I hear the sounds of loud tapping on a keyboard from the speakerphone, and then a voice says, “Umm, can someone try it now?”

There are sounds of multiple people typing on laptop keyboards, as they try to access the order entry systems.

“Hold it!” I say loudly, jumping halfway out of my chair, pointing at the speakerphone. “Who just said that?”

An awkward silence lengthens.

“It’s me, Brent.”

Oh, man.

I force myself to sit down again and take a long, deep breath. “Brent, thanks for the initiative, but, in a Sev 1 incident, we need to announce and discuss any actions before taking them. The last thing we want to do is to make things worse and complicate establishing root cause—”

Before I can finish, someone at the other end of the table interrupts from behind his laptop, “Hey, the systems are back up again. Good work, Brent.”

Oh, come on.

I press my lips together in frustration.

Apparently, even undisciplined mobs can get lucky, too.

“Patty, wrap this up,” I say. “I need to see you and Wes in your office immediately.” I stand up and leave.

I remain standing in Patty’s office until I have both of their attention. “Let me make myself clear. For Sev 1 incidents, we cannot fly by the seat of our pants. Patty, from now on, as the person leading a Sev 1 incident call, I need you to start the call presenting a timeline of all relevant events, especially changes.

“I’m holding you responsible for having that information close-at-hand, which should be easy since you also control the change process. That information comes from you, not all the yahoos on the conference call. Is that clear?”

Patty looks back at me, obviously frustrated. I resist the urge to soften my words. I know she’s been working hard, and I’ve been piling even more onto her lately.

“Yeah, totally clear,” she says wearily. “I’ll work on documenting that process and will institute it as quickly as I can.”

“Not good enough,” I say. “I want you to host practice incident calls and fire drills every two weeks. We need to get everyone used to solving problems in a methodical way and to have the timeline available before we go into that meeting. If we can’t do this during a prearranged drill, how can we expect people to do it during an emergency?”

Seeing the discouraged expression on her face, I put my hand on her shoulder. “Look, I appreciate all the work you’re doing lately. It’s important work, and I don’t know what we’ d do without you.”

Next, I turn to Wes. “Impress upon Brent immediately that during emergencies, everyone must discuss changes they’re thinking about, let alone the ones they actually implement. I can’t prove it, but I’m guessing Brent caused the outage, and when he realized it, he undid the change.”

Wes is about to respond, but I cut him off.

“Put a stop to this,” I say forcefully, pointing at him. “No more unauthorized changes, and no more undisclosed changes during outages. Can you get your people under control or not?”

Wes looks surprised and studies my face for a moment. “Yeah, I’m on it, boss.”

---

*Wes and I spend nearly every waking hour *late Tuesday and early Wednesday in the Phoenix war room. The deployment is only three days away. As each day goes by, the worse it looks.

It’s a relief to head back to the Change Coordination Room.

As I walk in, most of the CAB is here. The messy pile of index cards is gone. Instead, they’re either hanging on one of the whiteboards on the wall or neatly organized on the table in the front of the room, labeled “Pending Changes.”

“Welcome to our change management meeting,” Patty begins. “As you can see on the board, all of the standard changes have been scheduled. Today, we’ll review and schedule all the high- and medium-risk changes. We’ll then look at the change schedule to make any needed adjustments—I won’t give away anything right now, but I think you’ll see something that requires our attention.”

She picks up the first pile of cards. “The first high-risk change is to a firewall, submitted by John, scheduled for Friday.” She then reads out the people who have been consulted and signed off on the proposed change.

She prompts Wes and me, “Bill and Wes, do you approve this to go on the board as a Friday change?”

I’m satisfied that there have been enough eyes on this, so I nod.

Wes says, “Same for me. Hey, not bad. Twenty-three seconds to approve our first change. We beat our previous best time by fifty-nine minutes!”

There is scattered applause. Patty doesn’t disappoint as she goes through the remaining eight high-risk changes, taking even less time for those. There is more applause, while one of her staff posts the cards on the board.

Patty picks up the medium-risk change stack. “There were 147 standard changes submitted. I want to commend everyone for following the process and talking with the people that needed to be consulted. Ninety of those changes are ready to be scheduled, and have been posted. I’ve printed them out for everyone to review.”

Turning to Wes and me, she says, “I sampled ten percent of these, and, for the most part, they look good. I’ll keep track of problem trends, just in case some of these need more scrutiny going forward. Unless there are any objections, I think we’re done with the medium-risk changes. There’s actually a more pressing problem that we need to address.”

When Wes says, “No objections from me,” I nod for Patty to proceed, who merely gestures to the boards.

I think I see what’s wrong, but I stay quiet. One of the leads points to one of the boxes and says, “How many changes are scheduled for Friday?”

Bingo.

Patty flashes a small smile and says, “173.”

On the board, it’s now very obvious that nearly half the changes were scheduled for Friday. Of the remaining, half are scheduled for Thursday with the rest sprinkled earlier in the week.

She continues, “I’m not suggesting that 173 changes happening on Friday is bad, but I’m worried about change collisions and resource-availability conflicts. Friday is also the day Phoenix is being deployed.

“If I were air traffic control,” she continues, “I’d say that the airspace is dangerously overcrowded. Anyone willing to change their flight plans?”

Someone says, “I’ve got three that I’d like to do today, if no one minds. I don’t want to be anywhere near the airport when Phoenix comes in for a landing.”

“Yeah, well, lucky you,” Wes mutters. “Some of us have to be here on Friday. I can already see the flames pouring out of the wings…”

Two other engineers ask for their changes to be moved earlier in the week. Patty has them go to the board to move their change cards, verifying that it wouldn’t interfere with other changes already scheduled.

Fifteen minutes later, the distribution of the cards on the change board is much more even. I’m less happy that everyone is moving their changes as far away from Friday as possible, like woodland creatures running away from a forest fire.

Watching the change cards being moved around, something else starts to bother me. It’s not just the images of carnage and mayhem around Phoenix. Instead, it has something to do with Erik and the MRP-8 plant. I keep staring at the cards.

Patty interrupts my concentration. “—Bill, that concludes what we needed to get through. All the changes for the week are approved and scheduled.”

As I try to reorient myself, Wes says, “You’ve done a really great job organizing this, Patty. You know I was one of your louder critics. But…” He gestures at the board, “All this is just terrific.”

There is a murmur of agreement, and Patty flushes visibly. “Thanks. We’re still in our first week of having a real change process, and this is the broadest participation we’ve ever had. But before we start patting ourselves on the back, how about we make it to a second week, okay?”

I say, “Absolutely. Thanks for all the time you’re putting into this, Patty. Keep up the great work.”

When the meeting adjourns, I stay behind, staring at the change board.

Several times during this meeting, something flickered at the edge of my mind. Was it something that Erik said that I dismissed earlier? Something to do with work?

Last Thursday, Wes and Patty did a manual inventory of all our projects, coming up with nearly a hundred projects. It was manually generated by interviewing all the line workers. Those projects certainly represent two categories of work: business projects and internal IT projects.

Looking at all the change cards on the wall, I realize that I’m looking at another collection of work that we once again manually generated. According to Patty, it’s 437 discrete pieces of…work…that we’re doing this week.

I realize that changes are the third category of work.

When Patty’s people moved around the change cards, from Friday to earlier in the week, they were changing our *work schedule*. Each of those change cards defined the work that my team was going to be doing that day.

Sure, each of these changes is much smaller than an entire project, but it’s still work. But what is the relationship between changes and projects? Are they equally important?

And can it really be that before today, none of these changes were being tracked somewhere, in some sort of system? For that matter, where did all these changes come from?

If changes are a type of work different than projects, does that mean that we’re actually doing more than just the hundred projects? How many of these changes are to support one of the hundred projects? If it’s not supporting one of those, should we really be working on it?

If we had exactly the amount of resources to take on all our project work, does this mean we might not have enough cycles to implement all these changes?

I debate with myself whether I’m on the verge of some large and meaningful insight. Erik asked me what my organization’s equivalent to the job release desk on the plant floor. Does change management have anything to do with it?

Suddenly I laugh out loud at the absurd number of questions I’ve just asked myself. I feel like a one-man debate club. Or that Erik tricked me into doing some philosophical navel-gazing.

Thinking for a moment, I decide there’s value in knowing that changes represent yet another category of work but don’t know why.

I’ve now identified three of the four categories of work. For a brief moment, I wonder what the fourth category of work is.
