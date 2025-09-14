# Chapter 3

## • Tuesday, September 2

*I follow Patty and Wes* as they walk past the NOC, into the sea of cubicles. We end up in a giant workspace created by combining six cubicles. A large table sits against one wall with a keyboard and four LCD monitors, like a Wall Street trading desk. There are piles of servers everywhere, all with blinking lights. Each portion of the desk is covered by more monitors, showing graphs, login windows, code editors, Word documents, and countless applications I don’t recognize.

Brent types away in a window, oblivious to everything around him. From his phone, I hear the NOC conference line. He obviously doesn’t seem worried that the loud speakerphone might bother his neighbors.

“Hey, Brent. You got a minute?” Wes asks loudly, putting a hand on his shoulder.

“Can it wait?” Brent replies without even looking up. “I’m actually kind of busy right now. Working the SAN issue, you know?”

Wes grabs a chair. “Yeah, that’s what we’re here to talk about.”

When Brent turns around, Wes continues, “Tell me again about last night. What made you conclude that the SAN upgrade caused the payroll run failure?”

Brent rolls his eyes, “I was helping one of the SAN engineers perform the firmware upgrade after everybody went home. It took way longer than we thought—nothing went according to the tech note. It got pretty hairy, but we finally finished around seven o’ clock.

“We rebooted the SAN, but then all the self-tests started failing. We worked it for about fifteen minutes, trying to figure out what went wrong. That’s when we got the e-mails about the payroll run failing. That’s when I said, ‘Game Over.’

“We were just too many versions behind. The SAN vendor probably never tested the upgrade path we were going down. I called you, telling you I wanted to pull the plug. When you gave me the nod, we started the rollback.

“That’s when the SAN crashed,” he says, slumping in his chair. “It not only took down payroll but a bunch of other servers, too.”

“We’ve been meaning to upgrade the SAN firmware for years, but we never got around to it,” Wes explains, turning to me. “We came close once, but then we couldn’t get a big enough maintenance window. Performance has been getting worse and worse, to the point where a bunch of critical apps were being impacted. So finally, last night, we decided to just bite the bullet and do the upgrade.”

I nod. Then, my phone rings.

It’s Ann, so I put her on speakerphone.

“As you suggested, we looked at the data we pulled from the payroll database yesterday. The last pay period was fine. But for this pay period, all the Social Security numbers for the factory hourlies are complete gibberish. And all their hours worked and wage fields are zeroes, too. No one has ever seen anything like this before.”

“Just one field is gibberish?” I ask, raising my eyebrows in surprise. “What do you mean by ‘gibberish’? What’s in the fields?”

She tries to describe what she’s seeing on her screen. “Well, they’re not numbers or letters. There’s some hearts and spades and some squiggly characters… And there’s a bunch of foreign characters with umlauts… And there are no spaces. Is that important?”

When Brent snickers as he hears Ann trying to read line noise aloud, I give him a stern glance. “I think we’ve got the picture,” I say. “This is a very important clue. Can you send the spreadsheet with the corrupted data to me?”

She agrees. “By the way, are a bunch of databases down now? That’s funny. They were up last night.”

Wes mutters something under his breath, silencing Brent before he can say anything.

“Umm, yes. We’re aware of the problem and we’re working it, too,” I deadpan.

When we hang up, I breathe a sigh of relief, taking a moment to thank whatever deity protects people who fight fires and fix outages.

“Only one field corrupted in the database? Come on, guys, that definitely doesn’t sound like a SAN failure.” I say. “Brent, what else was going on yesterday, besides the SAN upgrade, that could have caused the payroll run to fail?”

Brent slouches in his chair, spinning it around while he thinks. “Well, now that you mention it… A developer for the timekeeping application called me yesterday with a strange question about the database table structure. I was in the middle of working on that Phoenix test VM, so I gave him a really quick answer so I could get back to work. You don’t suppose he did something to break the app, do you?”

Wes turns quickly to the speakerphone dialed into the NOC conference call that has been on this whole time and unmutes the phone. “Hey, guys, it’s Wes here. I’m with Brent and Patty, as well as with our new boss, Bill Palmer. Steve Masters has put him charge of all of IT Ops. So listen up, guys.”

My desire for an orderly announcement of my new role seems less and less likely.

Wes continues, “Does anyone know anything about a developer making any changes to the timekeeping application in the factories? Brent says he got a call from someone who asked about changing some database tables.”

From the speakerphone, a voice pipes up, “Yeah, I was helping someone who was having some connectivity issues with the plants. I’m pretty sure he was a developer maintaining the timekeeping app. He was installing some security application that John needed to get up and running this week. I think his name was Max. I still have his contact information around here somewhere… He said he was going on vacation today, which is why the work was so urgent.”

Now we’re getting somewhere.

A developer jamming in an urgent change so he could go on vacation—possibly as part of some urgent project being driven by John Pesche, our Chief Information Security Officer.

Situations like this only reinforce my deep suspicion of developers: They’re often carelessly breaking things and then disappearing, leaving Operations to clean up the mess.

The only thing more dangerous than a developer is a developer conspiring with Security. The two working together gives us means, motive, and opportunity.

I’m guessing our CISO probably strong-armed a Development manager to do something, which resulted in a developer doing something else, which broke the payroll run.

Information Security is always flashing their badges at people and making urgent demands, regardless of the consequences to the rest of the organization, which is why we don’t invite them to many meetings. The best way to make sure something doesn’t get done is to have them in the room.

They’re always coming up with a million reasons why anything we do will create a security hole that alien space-hackers will exploit to pillage our entire organization and steal all our code, intellectual property, credit card numbers, and pictures of our loved ones. These are potentially valid risks, but I often can’t connect the dots between their shrill, hysterical, and self-righteous demands and actually improving the defensibility of our environment.

“Okay, guys,” I say decisively. “The payroll run failure is like a crime scene and we’re Scotland Yard. The SAN is no longer a suspect, but unfortunately, we’ve accidentally maimed it during our investigation. Brent, you keep working on the injured SAN—obviously, we’ve got to get it up and running soon.

“Wes and Patty, our new persons of interest are Max and his manager,” I say. “Do whatever it takes to find them, detain them, and figure out what they did. I don’t care if Max is on vacation. I’m guessing he probably messed up something, and we need to fix it by 3 p.m.”

I think for a moment. “I’m going to find John. Either of you want to join me?”

Wes and Patty argue over who will help interrogate John. Patty says adamantly, “It should be me. I’ve been trying to keep John’s people in line for years. They never follow our process, and it always causes problems. I’d love to see Steve and Dick rake him over the coals for pulling a stunt like this.”

It is apparently a convincing argument, as Wes says, “Okay, he’s all yours. I almost feel sorry for him now.”

I suddenly regret my choice of words. This isn’t a witch hunt, and I’m not looking for retribution. We still need a timeline of all relevant events leading up to the failure.

Jumping to inappropriate conclusions caused the SAN failure last night. We won’t make these kinds of mistakes again. Not on my watch.

As Patty and I call John, I squint at the phone number on Patty’s screen, wondering if it’s time to heed my wife’s advice to get glasses. Yet another reminder that forty is just around the corner.

I dial the number, and a voice answers in one ring, “John here.”

I quickly tell him about the payroll and SAN failure and then ask, “Did you make any changes to the timekeeping application yesterday?”

He says, “That sounds bad, but I can assure you that we didn’t make any changes to your midrange systems. Sorry I can’t be of more help.”

I sigh. I thought that by now either Steve or Laura would have sent out the announcement of my promotion. I seem destined to explain my new role in every interaction I have.

I wonder if it would be easier if I just sent out the announcement myself.

I repeat the abridged story of my hasty promotion yet again. “Wes, Patty, and I heard that you were working with Max to deploy something urgent yesterday. What was it?”

“Luke and Damon are gone?” John sounds surprised. “I never thought that Steve would actually fire both of them over a compliance audit finding. But who knows? Maybe things are finally starting to change around here. Let this be a lesson to you, Bill. You Operations people can’t keep dragging your feet on security issues anymore! Just some friendly advice…

“Speaking of which, I’m suspicious about how the competition keeps getting the jump on us,” he continues. “As they say, once is coincidence. Twice is happenstance. Third must be enemy action. Maybe our salespeople’s e-mail systems have been hacked. That would sure explain why we’re losing so many deals.”

John continues to talk, but my mind is still stuck at his suggestion that Luke and Damon may have been fired over something security related. It’s possible—John routinely deals with some pretty powerful people, like Steve and the board as well as the internal and external auditors.

However, I’m certain Steve didn’t mention either John or Information Security as reasons for their departure—only the need to focus on Phoenix.

I look at Patty questioningly. She just rolls her eyes and then twirls her finger around her ear. Clearly, she thinks John’s theory is crazy.

“Has Steve given you any insights on the new org structure?” I ask out of genuine curiosity—John is always complaining that information security was always prioritized too low. He’s been lobbying to become a peer of the CIO, saying it would resolve an inherent conflict of interest. To my knowledge, he hadn’t succeeded.

It’s no secret that Luke and Damon sidelined John as much as possible, so he couldn’t interfere with people who did real work. John still managed to show up at meetings, despite their best efforts.

“What? I have no clue what’s going on,” he says in an aggrieved tone, my question apparently striking a nerve. “I’m being kept in the dark, like usual. I’ll probably be the last to find out, too, if history is any guide. Until you told me, I thought I was still reporting to Luke. And now that he’s gone, I don’t know who I’m reporting to. You got a call from Steve?”

“This is all above my pay grade—I’m as much in the dark as you are,” I respond, playing it dumb. Quickly changing the subject, I ask, “What can you tell us about the timekeeping app change?”

“I’ll call Steve and find out what’s going on. He’s probably forgotten Information Security even exists,” he continues, making me wonder whether we’ll ever be able to talk about payroll.

To my relief, he finally says, “Okay, yeah, you were asking about Max. We had an urgent audit issue around storage of PII—that is, personally identifiable information like SSNs—that’s Social Security numbers, obviously, birthdays, and so forth. European Union law and now many US state laws prohibit us from storing that kind of data. We got a huge audit finding around this. I knew it was up to my team to save this company from itself and prevent us from getting dinged again. That would be front-page news, you know?”

He continues, “We found a product that tokenized this information, so we no longer have to store the SSNs. It was supposed to be deployed almost a year ago, but it never got done, despite all my badgering. Now we’re out of time. The Payment Card Industry auditors, that’s PCI for short, are here later this month, so I fast-tracked the work with the timekeeping team to get it done.”

I stare at my phone, speechless.

On the one hand, I’m ecstatic because we’ve found the smoking gun in John’s hand. John’s mention of the SSN field matches Ann’s description of the corrupted data.

On the other hand: “Let me see if I’ve got this right…” I say slowly. “You deployed this tokenization application to fix an audit finding, which caused the payroll run failure, which has Dick and Steve climbing the walls?”

John responds hotly, “First, I am quite certain the tokenization security product didn’t cause the issue. It’s inconceivable. The vendor assured us that it’s safe, and we checked all their references. Second, Dick and Steve have every reason to be climbing the walls: Compliance is not optional. It’s the law. My job is to keep them out of orange jumpsuits, and so I did what I had to do.”

“ ‘Orange jumpsuits?’ ”

“Like what you wear in prison,” he says. “My job is to keep management in compliance with all relevant laws, regulations, and contractual obligations. Luke and Damon were reckless. They cut corners that severely affected our audit and security posture. If it weren’t for my actions, we’ d probably all be in jail by now.”

I thought we were talking about a payroll failure, not being thrown in jail by some imaginary police force.

“John, we have processes and procedures for how you introduce changes into production,” Patty says. “You went around them, and, once again, you’ve caused a big problem that we’re having to repair. Why didn’t you follow the process?”

“Ha! Good one, Patty,” John snorts. “I did follow the process. You know what your people told me? That the next possible deployment window was in four months. Hello? The auditors are on-site next week!”

He says adamantly, “Getting trapped in your bureaucratic process was simply not an option. If you were in my shoes, you’d do the same thing.”

Patty reddens. I say calmly, “According to Dick, we have fewer than four hours to get the timekeeping app up. Now that we know there was a change that affected SSNs, I think we have what we need.”

I continue, “Max, who helped with the deployment, is on vacation today. Wes or Brent will be contacting you to learn more about this tokenization product you deployed. I know you’ll provide them with whatever help they need. This is important.”

When John agrees, I thank him for his time. “Wait, one more question. Why do you believe that this product didn’t cause the failure? Did you test the change?”

There’s a short silence on the phone before John replies, “No, we couldn’t test the change. There’s no test environment. Apparently, you guys requested a budget years ago, but…”

I should have known.

“Well, that’s good news,” Patty says after John hangs up. “It may not be easy to fix, but at least we finally know what’s going on.”

“Was John’s tokenization change in the change schedule?” I ask.

She laughs humorlessly. “That’s what I’ve been trying to tell you. John rarely goes through our change process. Nor do most people, for that matter. It’s like the Wild West out here. We’re mostly shooting from the hip.”

She says defensively. “We need more process around here and better support from the top, including IT process tooling and training. Everyone thinks that the real way to get work done is to just do it. That makes my job nearly impossible.”

In my old group, we were always disciplined about doing changes. No one made changes without telling everyone else, and we’ d bend over backward to make sure our changes wouldn’t screw someone else up.

I’m not used to flying this blind.

“We don’t have time to do interrogations every time something goes wrong,” I say, exasperated. “Get me a list of all the changes made in the past, say, three days. Without an accurate timeline, we won’t be able to establish cause and effect, and we’ll probably end up causing another outage.”

“Good idea,” she nods. “If necessary, I’ll e-mail everyone in IT to find out what they were doing, to catch things that weren’t on our schedule.”

“What do you mean, ‘e-mail everyone?’ There’s no system where people put in their changes? What about our ticketing system or the change-authorization system?” I ask, stunned. This is like Scotland Yard e-mailing everyone in London to find out who was near the scene of a crime.

“Dream on,” she says, looking at me like I’m a newbie, which I suppose I am. “For years, I’ve been trying to get people to use our change management process and tools. But just like John, no one uses it. Same with our ticketing system. It’s pretty hit-or-miss, too.”

Things are far worse than I thought.

“Okay, do what you need to do,” I finally say, unable to hide my frustration. “Make sure you hit all the developers supporting the timekeeping system as well as all the system administrators and networking people. Call their managers, and tell them it’s important that we know about any changes, regardless of how unimportant they may seem. Don’t forget John’s people, too.”

When Patty nods, I say, “Look, you’re the change manager. We’ve got to do better than this. We need better situational awareness, and that means we need some sort of functional change management process. Get everyone to bring in their changes so we can build a picture of what is actually going on out there.”

To my surprise, Patty looks dejected. “Look, I’ve tried this before. I’ll tell you what will happen. The Change Advisory Board, or CAB, will get together once or twice. And within a couple of weeks, people will stop attending, saying they’re too busy. Or they’ll just make the changes without waiting for authorization because of deadline pressures. Either way, it’ll fizzle out within a month.”

“Not this time,” I say adamantly. “Send out a meeting notice to all the technology leads and announce that attendance is not optional. If they can’t make it, they need to send a delegate. When is the next meeting?”

“Tomorrow,” she says.

“Excellent,” I say with genuine enthusiasm. “I’m looking forward to it.”

---

*When I finally get home, *it’s after midnight. After a long day of disappointments, I’m exhausted. Balloons are on the floor and a half-empty bottle of wine sits on the kitchen table. On the wall is a crayon poster saying, “Congratulations Daddy!”

When I called my wife, Paige, this afternoon telling her about my promotion, she was far happier than I was. She insisted on inviting the neighbors over to throw a little celebration. Coming home so late, I missed my own party.

At 2 p.m., Patty had successfully argued that of the twenty-seven changes made in the past three days, only John’s tokenization change and the SAN upgrade could be reasonably linked to the payroll failure. However, Wes and his team were still unable to restore SAN operations.

At 3 p.m., I had to tell Ann and Dick the bad news that we had no choice but to execute plan B. Their frustration and disappointment were all too evident.

It wasn’t until 7 p.m. when the timekeeping application was back up and 11 p.m. when the SAN was finally brought back online.

Not a great performance on my first day as VP of IT Operations.

Before I left work, I e-mailed Steve, Dick, and Ann a quick status report, promising to do whatever it takes to prevent this type of failure from happening again.

I go upstairs, finish brushing my teeth, and check my phone one last time before going to bed, being careful not to wake up Paige. I curse when I see an e-mail from our company PR manager, with a subject of “Bad news. We may be on the front page tomorrow…”

I sit on the bed, squinting to read the accompanying news story.

*Elkhart Grove Herald Times*

### Parts Unlimited flubs paychecks, local union leader calls failure ‘unconscionable’

Automotive parts supplier Parts Unlimited has failed to adequately compensate its workers, with some employees receiving no pay at all, according to a Parts Unlimited internal memo. The locally headquartered company admitted that it had failed to issue correct paychecks to some of its hourly factory workers and that others hadn’t received any compensation for their work. Parts Unlimited denies that the issue is connected to cash flow problems and instead attributes the error to a payroll system failure.

The once high-flying $4 billion company has been plagued by flagging revenue and growing losses in recent quarters. These financial woes, which some blame on a failure of upper management, have led to rampant job insecurity among local workers struggling to support their families.

According to the memo, whatever the cause of the payroll failure, employees might have to wait days or weeks to be compensated.

“This is just the latest in a long string of management execution missteps taken by the company in recent years,” according to Nestor Meyers Chief Industry Analyst Kelly Lawrence.

Parts Unlimited CFO Dick Landry did not return phone calls from the *Herald Times* requesting comment on the payroll issue, accounting errors and questions of managerial competency.

In a statement issued on behalf of Parts Unlimited, Landry expressed regret at the “glitch,” and vowed that the mistake would not be repeated.

The *Herald Times* will continue to post updates as the story progresses.

Too tired to do anything more, I turn off the lights, making a mental note to myself to find Dick tomorrow to apologize in person. I close my eyes and try to sleep.

An hour later I’m still staring at the ceiling, very much awake.
