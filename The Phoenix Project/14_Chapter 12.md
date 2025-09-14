# Chapter 12

## • Friday, September 12

*It’s 7:30 p.m. on Friday,* two hours after the Phoenix deployment was scheduled to start. And things are not going well. I’m starting to associate the smell of pizza with the futility of a death march.

The entire IT Operations team was assembled in preparation for the deployment at 4 p.m. But there was nothing to do because we hadn’t received anything from Chris’ team; they were still making last minute changes.

It’s not a good sign when they’re still attaching parts to the space shuttle at liftoff time.

At 4:30 p.m., William had stormed into the Phoenix war room, livid and disgusted that no one could get all of the Phoenix code to run in the test environment. Worse, the few parts of Phoenix that were running were failing critical tests.

William started sending back critical bug reports to the developers, many of whom had already gone home for the day. Chris had to call them back in, and William’s team had to wait for the developers to send them new versions.

My team wasn’t just sitting around, twiddling our thumbs. Instead, we were frantically working with William’s team to try to get all of Phoenix to come up in the test environment. Because if they couldn’t get things running in a test environment, we wouldn’t have a prayer of being able to deploy and run it in production.

My gaze shifts from the clock to the conference table. Brent and three other engineers are huddling with their QA counterparts. They’ve been working frantically since 4 p.m., and they already look haggard. Many have laptops open to Google searches, and others are systematically fiddling with settings for the servers, operating systems, databases, and the Phoenix application, trying to figure out how to bring everything up, which the developers had assured them was possible.

One of the developers had actually walked in a couple of minutes ago and said, “Look, it’s running on my laptop. How hard can it be?”

Wes started swearing, while two of our engineers and three of William’s engineers started poring through the developer’s laptop, trying to figure out what made it different from the test environment.

In another area of the room, an engineer is talking heatedly to somebody on the phone, “Yes, we copied the file that you gave us… Yes, it’s version 1.0.13… What do you mean it’s the wrong version… What? When did you change that?… Copy it now and try again… Okay, look, but I’m telling you this isn’t going to work… I think it’s a networking problem… What do you mean we need to open up a firewall port? Why the hell didn’t you tell us this two hours ago?”

He then slams the phone down hard, and then pounds the table with his fist, yelling, “Idiots!”

Brent looks up from the developer laptop, rubbing his eyes with fatigue. “Let me guess. The front-end can’t talk to the database server because someone didn’t tell us we need to open a firewall port?”

The engineer nods with exhausted fury, and says, “I cannot freaking believe this. I was on the phone with that jackass for twenty minutes, and it never occurred to him that it wasn’t a code problem. This is FUBAR.”

I continue to listen quietly, but I’m nodding in agreement at his prognosis. In the Marines, we used the term FUBAR.”

Watching tempers fray, I look at my watch: 7:37 p.m.

It’s time to get a management gut check from my team. I round up Wes and Patty and look around for William. I find him staring over the shoulder of one of his engineers. I ask him to join us.

He looks puzzled for a moment, because we don’t normally interact, but he nods and follows us to my office.

---

*“Okay, guys, *tell me what you think of this situation,” I ask.

Wes speaks up first, “Those guys are right. This is FUBAR. We’re still getting incomplete releases from the developers. In the past two hours, I’ve already seen two instances when they’ve forgotten to give us several critical files, which guaranteed that the code wouldn’t run. And as you’ve seen, we still don’t know how to configure the test environment so that Phoenix actually comes up cleanly.”

He shakes his head again. “Based on what I’ve seen in the last half hour, I think we’ve actually moved backward.”

Patty just shakes her head with disgust and waves her hand, adding nothing.

I say to William, “I know we haven’t worked much together, but I’d really like to know what you think. How’s it looking from your perspective?”

He looks down, exhaling slowly and then says, “I honestly have no idea. The code is changing so fast that we’re having problems keeping up. If I were a betting man, I’d say Phoenix is going to blow up in production. I’ve talked with Chris a couple of times about stopping the release, but he and Sarah ran right over me.”

I ask him, “What do you mean by you ‘can’t keep up’?”

“When we find problems in our testing, we send it back to Development to have them fix it,” he explains. “Then they’ll send back a new release. The problem is that it takes about a half hour to get everything set up and running, and then another three hours to execute the smoke test. In that time, we’ll have probably gotten three more releases from Development.”

I smirk at the reference to smoke tests, a term circuit designers use. The saying goes, “If you turn the circuit board on and no smoke comes out, it’ll probably work.”

He shakes his head and says, “We have yet to make it through the smoke test. I’m concerned that we no longer have sufficient version control—we’ve gotten so sloppy about keeping track of version numbers of the entire release. Each time they fix something, they’re usually breaking something else. So, they’re sending single files over instead of the entire package.”

He continues, “It’s so chaotic right now that even if by some miracle Phoenix does pass the smoke test, I’m pretty sure we wouldn’t be able to replicate it, because there are too many moving parts.”

Taking off his glasses, he says with finality, “This is probably going to be an all-nighter for everyone. I think there’s genuine risk that we won’t have anything up and running at 8 a.m. tomorrow, when the stores open. And that’s a big problem.”

That is a huge understatement. If the release isn’t finished by 8 a.m., the point of sale systems in the stores used to check out customers won’t work. And that means we won’t be able to complete customer transactions.

Wes is nodding. “William is right. We’re definitely going to be here all night. And performance is worse than even I thought it would be. We’re going to need at least another twenty servers to spread the load, and I don’t know where we can find so many on such short notice. I have some people scrambling to find any spare hardware. Maybe we’ll even have to cannibalize servers in production.”

“Is it too late to stop the deployment?” I ask. “When exactly is the point of no return?”

“That’s a very good question.” Wes answers slowly. “I’d have to check with Brent, but I think we could stop the deployment now with no issues. But when we start converting the database so it can take orders from both the in-store POS systems and Phoenix, we are committed. At this rate, I don’t think that will be for a couple of hours yet.”

I nod. I’ve heard what I’ve needed to hear.

“Guys, I’m going to send out an e-mail to Steve, Chris, and Sarah to see if I can delay the deployment. And then I’m going to find Steve. Maybe I can get us one more week. But, hell, even getting one more day would be a win. Any thoughts?”

Wes, Patty, and William all just shake their heads glumly, saying nothing.

I turn to Patty. “Go work with William to figure out how we can get some better traffic coordination in the releases. Get over to where the developers are and play air traffic controller, and make sure everything is labeled and versioned on their side. And then let Wes and team know what’s coming over. We need better visibility and someone to keep people following process over there. I want a single entry point for code drops, controlled hourly releases, documentation… Get my drift?”

She says, “It would be my pleasure. I’ll head up to the Phoenix war room for starters. I’ll kick down the door if that’s what it takes and say, ‘We’re here to help…’ ”

I give them all a nod of thanks and head to my laptop to write my e-mail.

From: Bill Palmer

To: Steve Masters

Cc: Chris Anderson, Wes Davis, Patty McKee, Sarah Moulton, William Mason

Date: September 12, 7:45 PM

Priority: Highest

Subject: URGENT: Phoenix deployment in major trouble—my recommendation: 1 week delay

Steve,

First off, let me state that I want Phoenix in production as much as anyone else. I understand how important it is to the company.

However, based on what I’ve seen, I believe we will not have Phoenix up by the tomorrow 8 AM deadline. There is SIGNIFICANT RISK that this may even impact the in-store POS systems.

After discussions with William I recommend that we delay the Phoenix launch by one week to increase the likelihood that Phoenix achieves its goals and avert what I believe will be a NEAR-CERTAIN disaster.

I think we’re looking at problems on the scale of the “November 1999 Thanksgiving Toys R Us” train-wreck, meaning multiday outages and performance problems that potentially put customer and order data at risk.

Steve, I will be calling you in just a couple of minutes.

Regards,

Bill

---

*I take a moment *to collect my thoughts and call Steve, who answers on the first ring.

“Steve, it’s Bill. I just sent out an e-mail to you, Sarah, and Chris. I cannot overstate how badly this rollout has gone so far. This is going to bite us in the ass. Even William agrees. My team is now extremely concerned that the rollout will not complete in time for the stores to open at 8 a.m. Eastern time tomorrow. That could disrupt the stores’ ability to take sales, as well as probably cause multiday outages to the website.

“It’s not too late to stop this train wreck,” I implore. “Failure means that we’ll have problems taking orders from anyone, whether they’re in the stores or on the Internet. Failure could mean jeopardizing and screwing up order data and customer records, which means losing customers. Delaying by a week would just mean disappointing customers, but at least they’ll come back!”

Steve breathes into the phone and then replies, “It sounds bad, but at this point, we don’t have a choice. We have to keep going. Marketing already bought weekend newspaper ads announcing the availability of Phoenix. They’re bought, paid for, and being delivered to homes across the country. Our partners are all lined up and ready to go.”

Flabbergasted, I say, “Steve, just how bad does it have to be for you to delay this release? I’m telling you that we could be taking a reckless level of risk in this rollout!”

He pauses for several moments. “Tell you what. If you can convince Sarah to postpone the rollout, let’s talk. Otherwise, keep pushing.”

“Are you kidding me? She’s the one who’s created this kamikaze mess.”

Before I can stop myself, I hang up on Steve. For a brief moment, I consider calling him back to apologize.

As much as I hate to, I feel like I owe the company one last try to stop this insanity. Which means talking to Sarah in person.

*Back in the Phoenix war room *it’s stuffy and rank from too many people sweating from tension and fear. Sarah is sitting by herself, typing away on her laptop.

I call out to her, “Sarah, can we talk?”

She gestures to the chair next to her, saying, “Sure. What’s up?”

When I say in a lowered voice, “Let’s talk in the hallway.”

As we walk out together in silence, I ask her, “From up here, how does it look like the release is going?”

She says noncommittally, “You know how these things go when we’re trying to be nimble, right? There’s always unforeseen things when it comes to technology. If you want to make omelets, you’ve got to be willing to break some eggs.”

“I think it’s a bit worse than your usual rollout. I trust you saw my e-mail, right?”

She merely says, “Yes, of course. And you saw my reply?”

Shit.

I say, “No. But, before you explain, I wanted to make sure you understood the implications and the risks we’re posing to the business.” And then I repeat almost word for word what I told Steve just minutes before.

Not surprisingly, Sarah is unimpressed. As soon as I stop talking, she says, “We’ve all been busting ass getting Phoenix this far. Marketing is ready, Development is ready. Everyone is ready but you. I’ve told you before, but apparently, you’re not listening: Perfection is the enemy of good. We’ve got to keep going.”

Marveling at this colossal waste of time, I just shake my head and say, “No, lack of competence is the enemy of good. Mark my words. We’re going to be picking up the pieces for days, if not weeks, because of your dumb decisions.”

As I storm back into the NOC, I read Sarah’s e-mail, which makes me even more furious. I resist the urge to reply and add fuel to the fire. I also resist the emotional desire to delete it—I may need it to cover my ass later.

From: Sarah Moulton

To: Bill Palmer, Steve Masters

Cc: Chris Anderson, Wes Davis, Patty McKee, William Mason

Date: September 12, 8:15 PM

Priority: Highest

Subject: Re: URGENT: Phoenix deployment in major trouble—my recommendation: 1 week delay

Everyone is ready but you. Marketing, Dev, Project Management all have given this project their all. Now it’s your turn.

WE MUST GO!

Sarah

*Suddenly, I panic *for a brief moment that I haven’t told Paige anything for hours. I send her a quick text message:

*Night keeps getting worse. Am here for at least a couple more hrs. Will catch u in am. Love you. Wish me luck, darling.*

I feel a tap on my shoulder and turn around to see Wes. “Boss. We’ve got a very serious problem.”

The expression on his face is enough to make me scared. I quickly stand up and follow him to the other side of the room.

“Remember when we hit the point of no return around 9 p.m.? I’ve been tracking the progress of the Phoenix database conversion, and it’s thousands of times slower than we thought it would be. It was supposed to complete hours ago, but it’s only ten percent complete. That means all the data won’t be converted until Tuesday. We are totally screwed.”

Maybe I’m more tired than I thought but I’m not following him. I say, “Why is this a problem?”

Wes tries again, “That script needs to complete before the POS systems can come up. We can’t stop the script and we can’t restart it. Apparently, there’s nothing we can do to make it go faster. I think we can hack Phoenix so that it can run, but I don’t know about the in-store POS systems—we don’t have any to test with in the lab.”

Holy crap.

I think twice before I ask, “Brent?”

He just shakes his head. “I had him look at it for a couple of minutes. He thinks that someone turned on database indexing too soon, which is slowing down the inserts. There’s nothing we can do about it now, though, without screwing up data. I put him back on the Phoenix deployment.”

“How is everything else going?” I ask, wanting a full assessment of the situation. “Any improvement on performance? Any update on the database maintenance tools?”

“Performance is still terrible,” he says. “I think there’s a huge memory leak, and that’s even without any users on it. My guys suspect we’re going to have to reboot a bunch of the servers every couple of hours just to keep it from blowing up. Damned developers…”

He continues, “We’ve scrounged up fifteen more servers, some of them new and some yanked from various corners of the company. And now, believe it or not, we don’t have enough space in the data center racks to deploy them. We have to do a big recabling and racking job, moving crap around. Patty just put a call out and brought in a whole bunch of her people to help with that.”

I feel my eyebrows hit my hairline in genuine surprise. And then I bend forward, laughing. I say, “Oh, dear God. We finally find servers to deploy, and now we can’t find space to put them in. Amazing. We just can’t get a break!”

Wes shakes his head. “You know, I’ve heard stories like this from my buddies. But this may turn out to be the mother of all deployment failures.”

He continues, “Here’s the most amazing part: We made a huge investment in virtualization, which was supposed to save us from things like this. But, when Development couldn’t fix the performance problems, they blamed the virtualization. So we had to move everything back onto physical servers!”

And to think that Chris proposed this aggressive rollout date because virtualization would save our asses.

I wipe my eyes and force myself to stop laughing. “And how about the database support tools the developers promised us?”

Wes immediately stops smiling. “Absolute garbage. Our guys are going to have to manually edit the database to correct all the errors Phoenix is generating. And we’re going to have to manually trigger replenishments. We’re still learning about how much of this type of manual work Phoenix is going to require. It’s going to be very error-prone and take a ton of people to do.”

I wince, thinking about how this will tie up even more of our guys, doing menial work that the broken application should be doing. Nothing worries auditors more than direct edits of data without audit trails and proper controls.

“You’re doing a great job here. Our top priority is finding out what the effect of the incomplete database conversion will be on the in-store POS system. Find someone who knows those things inside and out, and get their thoughts. If necessary, call someone on Sarah’s team who handles day-to-day retail operations. Bonus points if you can get your hands on a POS device and server we can log into to see what the impact is ourselves.”

“Got it,” Wes says, nodding. “I know just the person to put on this.”

I watch him head off and then look around, trying to figure out where I can be the most useful.

---

*The morning light is starting *to stream in from the windows, showing the accumulated mess of coffee cups, papers, and all sorts of other debris. In the corner, a developer is asleep under some chairs.

I had just run to the bathroom to wash my face and wipe the grime from my teeth. I feel a little fresher, but it’s been years since I’ve pulled an all-nighter.

Maggie Lee is the Senior Director of Retail Program Management and works for Sarah. She is kicking off the 7 a.m. emergency meeting, and there are nearly thirty people packed into the room. In a tired voice, she says, “It’s been a night of heroics, and I appreciate everyone doing what it takes to hit our Phoenix commitments.

“As you know, the reason for this emergency meeting is that something went wrong in the database conversion,” she continues. “That means all the in-store POS systems will be down, which means that the stores will not have working cash registers. That means manual tills and manual card swipes.”

She adds, “The good news is that the Phoenix website is up and running.” She gestures at me and says, “My thanks to Bill and the entire IT Operations crew for making this happen.”

Irritated, I say, “I’d far rather have those POS systems up instead of Phoenix. All hell is breaking loose in the NOC. All our phones have been lit up for the past hour, because people in the stores are all screaming that their systems aren’t responding. It’s like the Jerry Lewis Telethon down there. Like all of you, my voicemail has already filled up from the staff in our 120 stores. We’re going to need to pull in more people just to man the phones.”

A phone vibrates somewhere on the table, as if to punctuate my point.

“We need to get proactive here,” I say to Sarah. “We need to send out a summary to everyone in the stores, as quickly as possible outlining what’s happened and more specific instructions on how to conduct operations without the POS systems.”

Sarah momentarily looks blank, and then says, “That’s a good idea. How about you take a first cut at the e-mail, and we’ll take it from there?”

Dumbfounded, I say, “What? I’m not a store manager! How about your group takes the first cut, and Chris and I can make sure it’s accurate.”

Chris nods.

Sarah looks around the room. “Okay. We’ll get something together in the next couple of hours.”

“Are you kidding me?” I shout. “Stores on the East Coast start opening in less than an hour—we need to get something out there now!”

“I’ll take care of it,” says Maggie, raising her hand. She immediately opens up her laptop and starts typing.

As I squeeze my head between my hands to see if I can make my headache hurt less, I wonder how much worse this rollout could get.

---

*By 2 p.m. Saturday, *it’s pretty clear that the bottom is a lot further down than I thought possible.

All stores are now operating in total manual fallback mode. All sales are being processed by those manual credit card imprint machines, with the carbon paper imprints being stored in shoeboxes.

Store managers have had employees running to the local office supply stores to find more carbon paper slips for the card imprint machines, as well as to the bank, so they could give out correct change.

Customers using the Phoenix website are complaining about how it is either down or so slow as to be unusable. We have even managed to turn into a Twitter trending topic. All of our customers who had been excited to try our service started complaining about our big IT fail after seeing our TV and newspaper ads.

Those customers who were able to order online had a rude awakening when they went to the store to pick up their order. That’s when we discovered that Phoenix seemed to be randomly losing transactions, and in other cases, it was double- or triple-charging our customers’ credit cards.

Furious that we’ve potentially lost integrity of the sales order data, Ann from Finance drove in and her team has now set up *another* war room across the hallway, fielding calls from the stores to handle problem orders. By noon, there were piles of papers from hundreds of pissed off customers that were being faxed in from the stores.

To support Ann, Wes brought in even more engineers to create some tools for Ann’s staff to use, in order to process the ever-growing backlog of screwed up transactions.

As I walk past the NOC table for the third time, I decide that I’m too exhausted to be of use to anyone. It’s almost 2:30 p.m.

Wes is arguing with someone across the room, so I wait until he’s done. I say to him, “Let’s face up to the fact that this is going to be a multiday ordeal. How are you holding up?”

He yawns and replies, “I managed to get an hour of sleep. Wow, you look terrible. Go home and get a couple of hours yourself. I’ve got a handle on everything here. I’ll call you if anything comes up.”

Too tired to argue, I thank him and leave.

---

*I wake with a start *when I hear my cell phone ring. I bolt up and grab my phone. It’s 4:30 p.m. Wes is calling.

I shake my head to gain some semblance of alertness and then answer, “What’s up?”

I hear him say, “Bad news. In short, it’s all over Twitter that the Phoenix website is leaking customer credit card numbers. They’re even posting screenshots. Apparently, when you empty your shopping cart, the session crashes and displays the credit card number of the last successful order.”

I’ve already jumped out of bed and am heading to the bathroom to get showered. “Call John. He’s going to have kittens. There’s probably some protocol for this, involving tons of paperwork and maybe even law enforcement. And probably lawyers, too.”

Wes replies, “I already called him. He and his team are on the way in. And he is pissed. He sounded just like that dude from *Pulp Fiction*. He even quoted the line about the day of reckoning and striking people down with great vengeance and furious anger.”

I laugh. I love that scene with John Travolta and Samuel L. Jackson. It’s not how I would have typecast our mild-mannered CISO, but as they say, you always have to watch out for the quiet ones.

I take a quick shower. I run into the kitchen and grab a couple of sticks of the string cheese our son loves to eat. I take these with me in the car and start my drive back into the office.

When I get on the highway, I call Paige. She answers on the first ring, “Darling, where have you been? I’m at work and the kids are with my mom.”

I say, “I was actually at home for an hour. I fell asleep the instant I crawled into bed, but Wes just called. Apparently, the Phoenix application started showing the entire world people’s credit card numbers. It’s a huge security breach, so I’m driving back in right now.”

I hear her sigh disapprovingly. “You’ve been there for over ten years and you’ve never worked these kind of hours. I’m really not sure I like this promotion.”

“You and me both, honey…” I say.
