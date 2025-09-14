# Chapter 27

## • Tuesday, October 21

*I’m in a conference room* with Patty, Wes, Chris, and John to share the progress Patty and I have made.

I begin by stating, “We interviewed Ron and Maggie, the business process owners on Dick’s company measurements slide. I’ve spent some time thinking about what we’ve learned.”

I dig out my notes and walk to the whiteboard, writing out, “Parts Unlimited desired business outcomes: increase revenue, increase market share, increase average order size, restore profitability, increase return on assets.”

Then I draw the following table:

![table](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781457191350/files/image/table-ch27.jpg)

Pointing at the whiteboard, I say, “The first column names the business capabilities and processes needed to achieve Dick’s desired outcomes; the second column lists the IT systems that those business processes rely upon; the third column lists what can go wrong with either the IT systems or data; and in the fourth column, we’ll write down the countermeasures to prevent those bad things from happening, or at a minimum, detect and respond.”

For the next half hour, I walk them through the table and all the grievances. “Apparently, for the things that Dick cares about most, IT matters.” I say, deadpan. Wes says, “Come on. I’m not the smartest guy in the room by any stretch. But, if we’re so important, why are they trying to outsource all of us? Face it, we’ve been moved from one foster home to another for decades.”

None of us have a good answer.

“You know, I really like Bill’s third column: ‘business risk due to IT,’ ” John says. “By describing what could go wrong in IT that prevents the business outcome from being achieved, we’re helping the business process owners get their bonuses. This should be *very* persuasive. We may even be thanked by the business for doing all this work, which would be a refreshing change.”

“I agree. Nice job, Bill,” Chris says, finally. “But what’s the solution?”

I say, “Anyone have any ideas?”

Surprisingly, John speaks up first. “Seems pretty obvious to me. We need to come with the controls to mitigate the risks in your third column. We then show this table to Ron and Maggie, and make sure they believe that our countermeasures help them achieve their objectives. If they buy it, we work with them to integrate IT into their performance measures…

“That example Erik gave you is perfect. They integrated ‘compliance with vehicle maintenance procedures’ as a leading indicator for ‘on-time delivery’ and ‘customer retention.’ We need to do the same.”

We roll up our sleeves and get to work.

For the phone and MRP systems, we quickly establish that the predictive measures include compliance with the change management process, supervision and review of production changes, completion of scheduled maintenance, and elimination of all known single points of failure.

When we tackle ‘customer needs and wants,” we get stuck.

It’s John who gets us rolling again. “Here, the objective isn’t system availability, it’s the integrity of data, which, incidentally, form two of the three legs of the ‘confidentiality, integrity, and availability triangle’ or CIA.” He asks Chris, “So, what’s causing the data integrity issues?”

Chris snorts in disgust. “Phoenix fixes a bunch of them, but we still have issues. Most of them are caused upstream, because the Marketing people keep putting in malformed inventory SKUs. Marketing needs to get their crap together, too.”

So for ‘marketing needs and wants,’ our proposed measurements include ability for Phoenix to support weekly and eventually daily reporting, percentage of valid SKUs created by Marketing, and so forth.

By the end of the day, we’ve generated a slide deck that Patty and I will take back to Ron and Maggie, which we’ll then present to Dick.

“Now that, my friends, is a solid proposal,” Wes says, proudly. With a loud laugh, he says, “Even a monkey could follow the dots we just connected!”

Over the next day, Patty and I get great feedback from Ron and Maggie, and they commit to supporting our proposal with Dick. When Ron learns that we still haven’t been granted budget for our monitoring project, he calls up Dick right in front of us, leaving him a heated voicemail, demanding to know why he’s dragging his feet.

With all this enthusiastic support, I figure our Thursday meeting with Dick will be a slam dunk.

---

*“All you’ve told me *is that you’re completely asleep at the wheel!” Dick says sternly, obviously unimpressed by what I’ve presented. Suddenly, I’m reminded of how Steve didn’t even look at the spreadsheets I had prepared for him when I asked him to prioritize Phoenix and the audit finding work.

But Dick isn’t being dismissive. He’s actually angry. “You’re telling me something a nutless monkey could have figured out. You didn’t know these measurements were important? At every town hall meeting, Steve repeats them over and over. It’s in our company newsletters, it’s what Sarah talks about in every one of her strategy briefings. How could you all miss something so important?”

I see Chris and Patty fidget on either side of me as we sit across the table from Dick. Erik is standing by the window, leaning against the wall.

I have a flashback to when I was Marine sergeant, holding the flag on parade. Out of nowhere, a colonel appeared, growling at me in front of my entire unit, “That’s an out of regulation watch band, Sergeant Palmer!” I could have died on the spot from embarrassment, because I knew I had screwed up.

But today, I’m certain I understand the mission, and for the company to succeed I need Dick to understand what I’ve just learned. But how?

Erik clears his throat, and says to Dick, “I agree a nutless monkey should have figured this out. So, Dick, explain why on that little measurement spreadsheet of yours, you list four levels of management for each of your measurements but nowhere are there any IT managers listed. Why?”

Not waiting for Dick to respond, he continues, “Every week, IT people get dragged into fire drills at the last minute by managers trying to achieve those measurements—just like Brent was pulled in to help launch Sarah’s latest sales promotion.” Erik pauses and says, “Quite frankly, I think you’re just as much of a nutless monkey as Bill.”

Dick grunts but doesn’t seem perturbed. He finally says, “Maybe so, Erik. You know, five years ago, we used to have our CIO attend our quarterly business reviews, but he never opened his mouth except to tell us that everything we proposed was impossible. After a year of that, Steve stopped inviting him.”

Dick turns back to me. “Bill, you’re telling me that everyone could do everything right in the business, but because of these IT issues, we would all still miss these objectives?”

“Yes, sir,” I say. “The operational risks posed by IT need to be managed just like any other business risk. In other words, they’re not IT risks. They’re business risks.”

Again, Dick grunts. He slumps in his chair, rubbing his eyes. “Shit. How the hell are we supposed to write an IT outsourcing contract if we don’t even know what the business needs?” he says, slamming his hand on the table.

He then asks, “Well, what’s your proposal? You’ve got one, I presume?”

I sit upright and begin the pitch that I’ve rehearsed so many times with the team. “I’d like three weeks with each of the business process owners on that spreadsheet. We need to get the business risks posed by IT better defined and agreed upon and then propose to you a way to integrate those risks into leading indicators of performance. Our goal is not just to improve business performance but to get earlier indicators of whether we’re going to achieve them or not, so we can take appropriate action.

“Furthermore,” I continue. “I’d like to schedule a single topic meeting with you and Chris about Phoenix,” then explaining my concerns how Phoenix as defined should not even have been approved.

I continue, “We’re going way too slowly, with too much WIP and too many features in flight. We need to make our releases smaller and shorter and deliver cash back faster, so we can beat the internal hurdle rate. Chris and I have some ideas, but it will look very different than our current plan of record.”

He remains silent. Then decisively, he declares, “Yes on both of your proposals. I’ll assign Ann to help. You need the best talent in the company.”

Out of the corner of my eye, I see Chris and Patty smile.

“Thank you, sir. We’ll make it so,” I say, standing up and pushing everyone out of the room, before Dick changes his mind.

As we walk out of his office, Erik claps his hand on my shoulder. “Not bad, kid. Congratulations on being well on your way to mastering the First Way. Now help John get there, because you’re going to have your hands full tackling the Second Way.”

Confused, I ask, “Why? What’s going to happen?”

“You’ll find out soon enough,” Erik says with a chuckle.

---

*On Friday, John convenes a meeting *with Wes, Patty, and me, promising some fantastic news. He says effusively, “You guys did fantastic work linking IT to Dick’s operational objectives. I’ve finally learned how we dodged the audit bullet, and I’m pretty sure we can do something equally fantastic to reduce our audit and compliance workload.”

“Doing less audit work?” Wes says, looking up, putting his phone down. “I’m all ears!”

He has my attention, too. If there were some way to get audit off our backs without another Bataan Death March, it would be nothing short of a miracle.

He turns toward Wes and Patty. “I needed to figure out how we escaped all the findings from the internal and external auditors. At first, I thought it was just the audit partner bending over backward to retain us as a client. But that wasn’t it at all…

“I got in front of everyone from the Parts Unlimited team who was at that meeting, trying to figure out who had the magic bullet. To my surprise, it wasn’t Dick or our corporate counsel. Ten meetings later, I finally found Faye, a Financial Analyst who works for Ann in Finance.

“Faye has a technical background. She spent four years in IT,” he says, as he hands out papers to each of us. “She created these SOX-404 control documents for the finance team. It shows the end-to-end information flow for the main business processes in each financially significant account. She documented where money or assets entered the system and traced it all the way to the general ledger.

“This is pretty standard, but she took it one step further: She didn’t look at any of the IT systems until she understood exactly where in the process material errors could occur *and* where they would be detected. She found that most of the time, we would detect it in a manual reconciliation step where account balances and values from one source were compared to another, usually on a weekly basis.

“When this happens,” he says, with awe and wonder in his voice, “she knew the upstream IT systems should be out of scope of the audit.”

“Here’s what she showed the auditors,” John says, excitedly flipping to the second page. “Quote: ‘The control being relied upon to detect material errors is the manual reconciliation step, not in the upstream IT systems.’ I went through all of Faye’s papers, and in every case, the auditors agreed, withdrawing their IT finding.

“That’s why Erik called the pile of audit findings a ‘scoping error.’ He’s right. If the audit test plan was scoped correctly in the beginning, there wouldn’t have been any IT findings!” he concludes.

John looks around as Patty, Wes, and I stare blankly at him.

I say, “I’m not following. How does this relate to reducing the audit workload?”

“I’m rebuilding our compliance program from scratch, based upon our new understanding of precisely where we’re relying our controls,” John says. “That dictates what matters. It’s like having a magic set of glasses that can differentiate what controls are earth-shatteringly important versus those that have no value at all.”

“Yes!” I say. “Those ‘magic glasses’ helped us finally see what matters to Dick for company operations. It was right in front of us for years, but we never saw it.”

John nods and smiles broadly. He flips to the last page of the handout. “I’m proposing five things that could reduce our security-related workload by seventy-five percent.”

What he presents is breathtaking. His first proposal drastically reduces the scope of the SOX-404 compliance program. When he verbalizes so precisely why it’s safe to do, I realize that John too is also mastering the First Way, having truly achieved a “profound appreciation of the system.”

His second proposal requires that we find out how production vulnerabilities got there in the first place and that we ensure that they don’t happen again by modifying our deployment processes.

His third proposal requires that we flag all the systems in the scope for compliance audits in Patty’s change management process—so we can avoid changes that could jeopardize our audits—and that we create the on-going documentation that the auditors will ask for.

John looks around, seeing all of us staring at him in shocked silence. “Did I say something wrong?”

“No offense, John…” Wes says slowly. “But…uh… You feeling okay?”

I say, “John, I don’t think you’ll get any objections from my team on your proposals. I think they’re great ideas.” Wes and Patty vehemently nod in agreement.

Looking pleased, he continues, “My fourth proposal is to reduce the size of our PCI compliance program by getting rid of anything that stores or processes cardholder data, which is like toxic waste. Losing or mishandling it can be lethal, and it costs too much to protect.

“Let’s start with the asinine cafeteria point of sale system. I never want to do another security review of that piece of crap. Frankly, I don’t care who takes it, even if it’s Sarah’s cousin Vinnie. It’s gotta go.”

Patty has one hand covering her mouth, and even Wes’ jaw is on the table. Has John completely lost his mind? This proposal seems…potentially reckless.

Wes thinks for a moment, and changes his mind. “I love it! I wish we could have gotten rid of it years ago. We’ve spent months securing that system for those audits. It even went into scope for the SOX-404 audits because it talked to the payroll systems!”

Patty eventually nods. “I suppose no one would argue that the cafeteria POS is a core competency. It doesn’t help our business but can definitely hurt it. And it pulls scarce resources from Phoenix and our in-store POS systems, which are definitely part of our core competencies.”

“Okay, John, let’s do it. You’re batting four out of four,” I say, decisively. “But do you really think we can get rid of it in time to make a difference?”

“Yep,” John says, smiling confidently. “I’ve already talked with Dick and the legal team. We just need to find a suitable outsourcer and convince ourselves that they can be trusted to maintain and secure the systems and data. We can outsource the work but not the responsibility.”

Wes interjects hopefully, “Can you do something about getting Phoenix out of scope of the audits, too?”

“Over my dead body,” John says flatly, crossing his arms. “My fifth and last proposal is that we pay down all the technical debt in Phoenix, using all the time we’ve saved from my previous proposals. We know there’s a huge amount of risk in Phoenix: strategic risk, operational risk, huge security and compliance risk. Almost all of Dick’s key measures hinge on it.

“As Patty said, our order entry and inventory management systems *are* a core competency. We’re relying on it to give us a competitive edge, but with all the shortcuts we’ve taken with it, it’s like a powder keg waiting to blow up.”

Wes sighs, looking annoyed. *Bad old John is back*, his expression says.

I disagree. This John is far more complex and nuanced than the old John. In the span of a couple of minutes, he’s been willing to take bigger, almost reckless, risks from outsourcing our cafeteria POS systems to his unyielding and categorical insistence that we secure and harden Phoenix.

I like this new John.

“You’re absolutely right, John. We’ve got to pay down technical debt,” I say firmly. “How do you propose we do it?”

We quickly agree to pair up people in Wes’ and Chris’ group with John’s team, so that we can increase the bench of security expertise. By doing this, we will start integrating security into all of our daily work, no longer securing things after they’re deployed.

John thanks everyone, indicating that we’ve covered everything on his agenda. I look at my watch. We’re done thirty minutes early. This must be a new world record for the shortest time required to agree on anything security-related.
