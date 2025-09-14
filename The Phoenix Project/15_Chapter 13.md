# Chapter 13

## • Monday, September 15

*By Monday, the Phoenix crisis is a public fiasco.* We made it onto the front-page news of all the technology sites. There are rumors that someone from *The Wall Street Journal* was trying to get Steve for an on-the-record interview.

I start with a jolt when I think I hear Steve mention my name.

Completely disoriented, I look around and realize that I’m at work and that I must have fallen asleep while waiting for the Phoenix status meeting to start. I sneak a peek at my watch. 11:04 a.m.

I have to look at my phone to figure out that it’s Monday.

For a moment, I wonder where my Sunday went, but seeing Steve red-faced, and addressing the entire room makes me pay attention.

“—don’t care one bit whose fault this is. You can bet your ass that this won’t ever happen again on my watch. But right now, I don’t give two shits about the future—we are massively screwing our customers and shareholders. All I want to hear about is how we’re going to dig ourselves out of this hole and restore normal business operations.”

He turns and points at Sarah saying, “And you are not off the hook until every one of your store managers says that they can transact normally. Manual card swipes? What are we, in some Third World country?”

Sarah replies calmly, “I totally understand how unacceptable this is. I’m making sure my entire staff knows that they are accountable and responsible.”

“No,” Steve responds quickly and gravely. “You are ultimately accountable and responsible. Do not forget that.”

My heart actually lightens for a moment, as I wonder whether Steve has broken free of Sarah’s spell.

Turning his attention back to the entire room he says gravely, “When the store managers say that we’re no longer operating on life support, I need fifteen minutes from each and every person who had a hand in this. I expect you to clear your calendar. No excuses.

“That means you, Sarah, Chris, Bill, Kirsten, Ann. And even you, John,” he says, pointing at people as he names them.

Way to go, John. You picked a great time to finally get noticed by Steve.

He continues, “I’ll be back in two hours after I get on a phone call with another journalist because of this mess!”

His door slam shakes the walls.

Sarah breaks the silence. “Well, you all heard Steve. Not only do we need to get the POS systems up, but we must also get the Phoenix usability issues fixed. The press is having a heyday with the clunkiness of the ordering interface and everything timing out.”

“Are you out of your mind?” I say, leaning forward. “We are keeping Phoenix alive by sheer heroics. Wes wasn’t joking when he said that we’re proactively rebooting all the front-end servers every hour. We can’t introduce any more instabilities. I propose code rollouts only twice a day and restricting all code changes to those affecting performance.”

To my surprise, Chris immediately chimes in, “I agree. William, what do you think?”

William nods. “Absolutely. I suggest we announce to the developers that all code commits must have a defect number that corresponds to a performance problem. Anything that doesn’t will get rejected.”

Chris says, “That good enough for you, Bill?”

Pleased with the solution, I say, “Perfect.”

Although Wes and Patty seem simultaneously pleased and taken aback by this sudden cooperation from Development, Sarah is not pleased. She says, “I don’t agree. We’ve got to be able to respond to the market, and the market is telling us that Phoenix is too hard to use. We can’t afford to screw this up.”

Chris replies, “Look, the time for usability testing and validation was months ago. If we didn’t get it right the first time, we’re not going to get it right without some real work. Have your product managers work on their revised mockups and proposals. We’ll try to get it in as soon as we can after the crisis is over.”

I affirm his position, saying, “I agree.”

“You raise some good points. I approve,” she says, apparently realizing that she wasn’t going to win this argument.

I’m not sure Sarah is actually in a position to approve anything. But, luckily, the discussion turns quickly to how to regain POS functionality.

I revise my opinion of Chris upward a couple of notches. I still think he was a willing accomplice of Sarah’s, but maybe I’ll give him the benefit of the doubt.

---

*Leaving the Phoenix war room, *I see the room across the hallway where Ann and her team handle problem orders. I’m overcome by a sudden curiosity, genuinely wanting to see how they’re doing.

I knock and walk in, still chewing a stale bagel from the meeting. Since Saturday, there has been an endless supply of pizzas, pastries, Jolt colas, and coffee to keep all the troops at their tasks.

Before me is a scene of frenetic activity: There are tables covered with piles of incoming faxes from the stores and twelve people walk from one to the next. Each fax is a problem order waiting to be routed to an army of finance and customer service representatives who have been press-ganged into service. Their job was to either deduplicate or reverse every one of these transactions.

In front of me, four finance people are sitting at another table, their fingers flying across ten-key calculators and open laptops. They’re manually tabulating the orders, trying to calculate the scale of the disaster and doing reconciliations to catch any mistakes.

On the wall, they’re keeping track of the totals. So far, five thousand customers have had either duplicate payments or missing orders, and there are an estimated twenty-five thousand more transactions that still need to be investigated.

I shake my head in disbelief. Steve is right. We massively screwed the customers this time. It’s downright embarrassing.

On the other hand, I have to respect the operation the Finance people have put in place to handle the mess. It looks organized, with people doing what needs to get done.

A voice next to me says, “Another Phoenix trainwreck, huh?”

It’s John, taking in the scene like me. He’s not saying “I told you so,” but almost. With him, of course, is his ever-present black three-ring binder.

John smacks his face with his palm. “If this were happening to our competitor, I’d be laughing my ass off. I told Chris over and over about this possibility, but he wouldn’t listen. We’re paying for it now.”

He walks up to one of the tables and starts looking over people’s shoulders. I see his body suddenly tense as he picks a pile of papers up. He flips through the papers, his face ashen.

He returns to where I’m standing, and whispers, “Bill, we’ve got a major problem. Outside. Now.”

“Look at this order slip,” he hisses as we stand outside. “Do you see the problem here?”

I look at the page. It’s a scanned order slip, slanted and low-resolution. It’s for a purchase of various auto parts, and the dollar amount seems reasonable at $53.

I say, “Why don’t you just tell me?”

John points to a handwritten number scrawled by the scanned credit card and customer signature. “That three-digit number is the CVV2 code on the back of the credit card. That’s there to prevent credit card fraud. Under the Payment Card Industry rules, we are not allowed to store or transmit anything on track 2 of the magnetic card stripe. Even possessing this is an automatic cardholder data breach and an automatic fine. Maybe even front-page news.”

Oh, no. Not again.

He continues, as if reading my mind, “Yeah, but worse this time. Instead of just being on the local news, imagine Steve being splashed on the front page of every market where we have customers and stores. And then flying to DC to be grilled by senators, on behalf of all their outraged constituents.”

He continues, “This is really serious. Bill, we’ve got to destroy all of this information immediately.”

I shake my head, saying, “No way. We’ve got to process every one of those orders, so that we don’t charge or even double-charge our customers. We’re obligated to do this, otherwise we’re taking money from them that we’ll eventually need to return.”

John puts his hand on my shoulder, “That may seem important, but that’s only the tip of the iceberg. We’re already in deep shit because Phoenix leaked cardholder data. This may be just as bad. We get fined according to the number of cardholders affected.”

He gestures at all the papers, saying, “This could more than double our fines. And you think our audits are bad now? This will make them ten times more painful, because they’ll classify us as a Level 1 merchant for the rest of eternity. They may even raise our transaction fees from three percent to—who knows how high? That could halve our retail store profit margins and—”

He stops mid-sentence and opens up his three-ring binder to a calendar. “Oh, shit! The PCI auditors are on-site *today* doing a business process walk-through. They’re on the second floor, interviewing the order administration staff about our operations. They’re even supposed to use this conference room!”

“You’ve got to be kidding me,” I say as the feeling of panic starts to set in, which amazes me considering that it’s been three days of constant adrenaline.

I turn to look through the window of the conference door and see very clearly all the finance people handling all the customer problem orders. Shit.

“Look,” I say, “I know that sometimes people think you’re not on our side, but I really need your help. You’ve got to keep the auditors off this floor. Maybe even out of this building. I’ll put up some curtains on the windows, or maybe even barricade the door.”

John looks at me and then nods. “Okay, I’ll handle the auditors. But I still don’t think you fully understand. As the custodians of cardholder data, we cannot allow hundreds of people to have access to it. The risk of theft and fraud is too high. We’ve got to destroy the data immediately.”

I can’t help but laugh for a moment at the endless stream of problems.

Forcing myself to focus, I say slowly, “Okay, I’ll make sure the Finance people understand this and handle it. Maybe we can get them all scanned and shipped to an offshore firm for them to enter.”

“No, no, no. That’s even worse!” he says. “Remember, we’re not allowed to transmit it, let alone send it to a third party. Understand? Look, just so we can claim plausible deniability, I’m going to pretend I didn’t hear that just now. You’ve got to figure out how to destroy all this prohibited data!”

I get pissed off at John’s mention of plausible deniability, regardless of whether it was well intentioned or not. I take a deep breath and say to him, “Keep those auditors off this floor, and I’ll worry about the card imprints. Okay?”

He nods and says, “Roger. I’ll call you when I park the auditors somewhere safe.”

As I watch him walk quickly down the hallway to the stairway, I keep thinking to myself, “He’s only doing his job. He’s only doing his job.”

I swear under my breath and turn back around to look back at the conference room. And now I see the big printed sign hanging on the door, proclaiming “Phoenix POS Recovery War Room.”

Suddenly, I feel like I’m in the movie *Weekend at Bernie’s*, where some teenage boys keep trying to hide or disguise a dead body from a hit man. Then I wonder if this is more like the massive around-the-clock shredding operation that allegedly happened at the offices of Arthur Andersen, the audit firm investigated after Enron failed. Am I complicit in destroying important evidence?

What a mess. I shake my head, and walk back into the conference room to deliver the bad news.

---

*I finally get back down *to the NOC at 2:30 p.m., and survey the carnage as I make my way to my office. Seven extra tables have been set up to make more meeting spaces, and there are people assembled around each of them. Empty pizza boxes are piled up on many of the tables and in one corner of the room.

I take a seat behind my desk, sighing in relief. I spent almost an hour with Ann’s team on the cardholder data issue, and then another half hour arguing with them that this is really their problem, not mine. I told them that I could help, but that my team was too tied up trying to keep Phoenix running to take any more responsibility.

I realize with some amazement that this may have been the first time I’ve been able to say no to anyone in the company since I started in this role. I wonder if I could have done it if we weren’t the people almost single-handedly keeping our store order entry systems up.

As I ponder this, my phone rings. It’s John. I answer quickly, wanting an update on the auditor issue. “Hey, John. How’s it going?”

John replies, “Not terrible. I’ve got the auditors set up right next to me, here in Building 7. I’ve rearranged it so that all the interviews will be done here. They won’t go anywhere near the Phoenix war room, and I’ve told the Building 9 security people explicitly not to let them past the front desk.”

I chuckle at seeing John bend all the rules. “That’s great. Thanks for pulling all that together. Also, I think Ann could use your help figuring what exactly it takes to stay in compliance with the cardholder data regulations. I helped as best I could, but…”

John says, “No problem. I’m happy to assist.”

He hesitates for a couple of moments. “I hate to bring it up now, but you were supposed to give internal audit the SOX-404 response letter today. How is that coming along?”

I burst out in laughter. “John, our plan was to get that report done over the weekend after the Phoenix deployment. But, as you know, things didn’t quite go as planned. I doubt anyone has worked on it since Friday.”

In a very concerned voice, John says, “You know that the entire audit committee looks at this, right? If we blow this deadline, it’s like a red flag to everyone that we have severe control issues. This could drive up the length of the external audit, too.”

I say as reasonably as I can, “Trust me, if there was anything I could do, I would. But right now, my entire team has been working around-the-clock to support the Phoenix recovery efforts. Even if they completed the report, and all I had to do was bend over and pick it up, I couldn’t. We’re that far underwater.”

As I’m talking, I realize how liberating it is to state that my team is absolutely at capacity and that there aren’t any calories left over for any new tasks, and people actually believe me.

I hear John say, “You know, I could free two engineers up. Maybe they could help do some of the legwork around estimating the remediation effort? Or if you need it, we could even put them into the technical resource pool to help with recovery. They’re both very technical and experienced.”

My ears perk up. We’ve got everyone deployed doing all sorts of things that this emergency requires and most have pulled at least one all-nighter. Some are monitoring fragile services and systems, others are helping field phone calls from the store managers, others are helping QA build systems and write tests, some are helping Development reproduce problems.

I say immediately, “That would be incredibly helpful. Send Wes an e-mail with a couple of bullet points on each of your engineers. If he doesn’t have an urgent need for their skills, I’ll task them on generating the remediation estimates, as long as it doesn’t require interrupting anyone working Phoenix.”

“Okay, great,” John says. “I’ll send the info to Wes later today, and I’ll let you know what he and I decide to do.”

He signs off, and I consider the potential stroke of good fortune that someone could be working on the audit response.

I then wonder if the fatigue is getting to me. Something is really screwy in the world when I’m finding reasons to thank Development *and* Security in the same day.
