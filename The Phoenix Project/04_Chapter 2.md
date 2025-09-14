# Chapter 2

## • Tuesday, September 2

*“How’d it go in there?” *Stacy asks kindly, looking up from her keyboard.

I just shake my head. “I can’t believe it. He just talked me into taking a new job I don’t want. How did that happen?”

“He can be very persuasive,” she says. “For what it’s worth, he’s one-of-a-kind. I’ve worked for him for nearly ten years, and I’ll follow him anywhere. Anything I can help with to make your job easier?”

Thinking for a moment, I ask, “There’s an urgent payroll issue that needs to be fixed. Dick Landry is on floor three, right?”

“Here you go,” she says, before I’ve finished asking my question, handing me a Post-it note with all of Dick’s contact information. Office location, phone numbers, and everything.

Grateful, I smile at her. “Thanks a lot—you are fantastic!”

I dial Dick’s cell phone on my way to the elevator. “Dick here,” he answers gruffly, still typing in the background.

“This is Bill Palmer. Steve just made me the new VP of IT Operations, and he asked me to—”

“Congratulations,” he interrupts. “Now look, my people found a huge payroll irregularity. When can you get to my office?”

“Right away,” I reply. I hear the click of him ending the call. I’ve had warmer welcomes.

On the third floor, I walk through Finance and Accounting, surrounded by pinstriped shirts and starched collars. I find Dick at his desk, still on the phone with someone. When he sees me, he puts his hand over the mouthpiece. “You from IT?” he asks gruffly.

When I nod, he says into the phone, “Look, I gotta run. Someone who’s supposedly going to help is finally here. I’ll call you back.” Without waiting for an answer, he hangs up the phone.

I’ve never actually seen someone who routinely hangs up on people. I brace myself for a conversation that is likely to be short on any comforting “let’s get to know each other” foreplay.

As if in a hostage situation, I slowly raise my hands, showing Dick the printed e-mail. “Steve just told me about the payroll outage. What’s the best way for me to get some situational awareness here?”

“We’re in deep kimchi,” Dick responds. “In yesterday’s payroll run, all of the records for the hourly employees went missing. We’re pretty sure it’s an IT issue. This screwup is preventing us from paying our employees, violating countless state labor laws, and, no doubt, the union is going to scream bloody murder.”

He mutters under his breath for a moment. “Let’s go see Ann, my Operations Manager. She’s been pulling her hair out since yesterday afternoon.”

Walking quickly to keep up, I nearly run into him when he stops and peers through a conference room window. He opens the door. “How’s it going in here, Ann?”

There are two well-dressed women in the room: one, around forty-five years old, studies the whiteboard, filled with flowcharts and a lot of tabulated numbers, and the other, in her early thirties, types on a laptop. Spreadsheets are strewn all over the large conference room table. The older woman gestures with an open marker at what appears to be a list of potential failure causes.

Something about the way they dress, and their concerned and irritated expressions, makes me think they were recruited from a local accounting firm. Ex-auditors. Good to have them on our side, I suppose.

Ann shakes her head in exhausted frustration. “Not much progress, I’m afraid. We’re almost certain this is an IT systems failure in one of the upstream timekeeping systems. All of the hourly factory worker records got screwed up in the last upload—”

Dick interrupts her. “This is Bill from IT. He’s been assigned to fix this mess or die trying, is what I think he said.”

I say, “Hi, guys. I’ve just been made the new head of IT Operations. Can you start from the beginning and tell me what you know about the problem?”

Ann walks over to the flowchart on the whiteboard. “Let’s start with the information flow. Our financial system gets payroll data from all our various divisions in different ways. We roll up all the numbers for salaried and hourly personnel, which includes wages and taxes. Sounds easy, but it’s extremely complex, because each state has different tax tables, labor laws, and so forth.

“To make sure something doesn’t get screwed up,” she continues, “we make sure the summarized numbers match the detailed numbers from each division.”

As I hurriedly jot down some notes, she continues, “It’s a pretty clunky and manual process. It works most of the time, but yesterday we discovered that the general ledger upload for hourly production staff didn’t come through. All of the hourlies had zeroes for their hours worked and amount due.

“We’ve had so many problems with this particular upload,” she says, obviously frustrated, “that IT gave us a program that we use to do manual corrections, so we don’t have to bother them anymore.”

I wince. I don’t like finance personnel manually changing payroll data outside the payroll application. It’s error-prone and dangerous. Someone could copy that data onto a USB drive or e-mail it outside of the organization, which is how organizations lose sensitive data.

“Did you say all the numbers for salaried employees are okay?” I ask.

“That’s right,” she replies.

“But hourly employees are all zeroes,” I confirm.

“Yep,” she again replies.

Interesting. I ask, “Why do you think the payroll run failed when it was working before? Have you had problems like this in the past?”

She shrugs. “Nothing like this has happened before. I have no idea what could have caused it—no major changes were scheduled for this pay period. I’ve been asking the same questions, but until we hear from the IT guys, we’re stuck dead in the water.”

“What is our backup plan,” I ask, “if things are so hosed that we can’t get the hourly employee data in time?”

“For crying out loud,” Dick says. “It’s in that e-mail you’re holding. The deadline for electronic payments is 5 p.m., today. If we can’t hit that window, we may have to FedEx bales of paper checks to each of our facilities for them to distribute to employees!”

I frown at this scenario and so does the rest of the finance team.

“That won’t work,” Ann says, clicking a marker on her teeth. “We’ve outsourced our payroll processing. Each pay period, we upload the payroll data to them, which they then process. In the worst case, maybe we download the previous payroll run, modify it in a spreadsheet, and then re-upload it?

“But because we don’t know how many hours each employee worked, we don’t know how much to pay them!” she continues. “We don’t want to overpay anyone, but that’s better than accidentally underpaying them.”

It’s obvious that plan B is fraught with problems. We’ d basically be guessing at people’s paychecks, as well as paying people who were terminated, and not paying people who were newly hired.

To get Finance the data they need, we may have to cobble together some custom reports, which means bringing in the application developers or database people.

But that’s like throwing gasoline on the fire. Developers are even worse than networking people. Show me a developer who isn’t crashing production systems, and I’ll show you one who can’t fog a mirror. Or more likely, is on vacation.

Dick says, “These are two lousy options. We could delay our payroll run until we have the correct data. But we can’t do this—even if we’re only a day late, we’ll have the union stepping in. So, that leaves Ann’s proposal of paying our employees something, even if it’s the incorrect amount. We’ d have to adjust everyone’s paycheck in the next pay period. But now we have a financial reporting error that we’ve got to go back and fix.”

He pinches the bridge of his nose and continues to ramble. “We’ll have a bunch of odd journal entries in our general ledger, just when our auditors are here for our SOX-404 audits. When they see this, they’ll *never* leave.

“Oh, man. A financial reporting error?” Dick mutters. “We’ll need approval from Steve. We’re going to have auditors camped out here until the cows come home. No one’ll ever get any real work done again.”

SOX-404 is short for the Sarbanes-Oxley Act of 2002, which Congress enacted in response to the accounting failures at Enron, WorldCom, and Tyco. It means the CEO and CFO have to personally sign their names, attesting that their company’s financial statements are accurate.

Everyone longs for the days when we didn’t spend half our time talking to auditors, complying with each new regulatory requirement *du jour*.

I look at my notes and then at the clock. Time is running out.

“Dick, based on what I’ve heard, I recommend that you continue to plan for the worst and we fully document plan B, so we can pull it off without further complications. Furthermore, I request that we wait until 3 p.m. before making a decision. We may be still able to get all the systems and data back.”

When Ann nods, Dick says, “Okay, you’ve got four hours.”

I say, “Rest assured that we understand the urgency of the situation and that you’ll be apprised of how it’s going as soon as I find out myself.”

“Thanks, Bill,” Ann says. Dick remains silent as I turn around and walk out the door.

I feel better, now that I’ve seen the problem from the business perspective. It’s now time to get under the covers and find out what broke the complex payroll machinery.

While walking down the stairs, I dig out my phone and scan my e-mails. My feeling of calm focus disappears when I see that Steve hasn’t sent out an announcement of my promotion. Wes Davis and Patty McKee, who until today were my peers, still have no idea that I’m now their new boss.

Thanks, Steve.

When I enter Building 7, it hits me. Our building is the ghetto of the entire Parts Unlimited campus.

It was built in the 1950s, and last remodeled in the 1970s, obviously built for utility, not aesthetics. Building 7 used to be our large brake-pad manufacturing factory until it was converted into data center and office space. It looks old and neglected.

The security guard says cheerfully, “Hello, Mr. Palmer. How is the morning going so far?”

For a moment, I’m tempted to ask him to wish me luck, so he can get paid the correct amount this week. Of course, I merely return his friendly greeting.

I’m headed toward the Network Operations Center, or as we call it, the NOC, where Wes and Patty are most likely to be. They’re now my two primary managers.

Wes is Director of Distributed Technology Operations. He has technical responsibility for over a thousand Windows servers, as well as the database and networking teams. Patty is the Director of IT Service Support. She owns all the level 1 and 2 help desk technicians who answer the phones around the clock, handling break-fix issues and support requests from the business. She also owns some of the key processes and tools that the entire IT Operations organization relies upon, like the trouble ticketing system, monitoring, and running the change management meetings.

I walk past rows upon rows of cubicles, the same as every other building. However, unlike Buildings 2 and 5, I see peeling paint and dark stains seeping through the carpet.

This part of the building was built on top of what used to be the main assembly floor. When they converted it, they couldn’t get all the machine oil cleaned up. No matter how much sealant we put down to coat the floors, oil still has a tendency to seep through the carpet.

I make a note to put in a budget request to replace the carpets and paint the walls. In the Marines, keeping the barracks neat and tidy was not only for aesthetics but also for safety.

Old habits die hard.

I hear the NOC before I see it. It’s a large bullpen area, with long tables set up along one wall, displaying the status of all the various IT services on large monitors. The level 1 and 2 help desk people sit at the three rows of workstations.

It’s not exactly like mission control in *Apollo 13*, but that’s how I explain it to my relatives.

When something hits the fan, you need all the various stakeholders and technology managers to communicate and coordinate until the problem is resolved. Like now. At the conference table, fifteen people are in the midst of a loud and heated discussion, huddled around one of the classic gray speakerphones that resembles a UFO.

Wes and Patty are sitting next to each other at the conference table, so I walk behind them to listen in. Wes leans back in his chair with his arms crossed over his stomach. They don’t get all the way across. At six feet three inches tall and over 250 pounds, he casts a shadow on most people. He seems to be in constant motion and has a reputation of saying whatever is on his mind.

Patty is the complete opposite. Where Wes is loud, outspoken, and shoots from the hip, Patty is thoughtful, analytical, and a stickler for processes and procedures. Where Wes is large, combative, and sometimes even quarrelsome, Patty is elfin, logical, and levelheaded. She has a reputation for loving processes more than people and is often in the position of trying to impose order on the chaos in IT.

She’s the face of the entire IT organization. When things go wrong in IT, people call Patty. She’s our professional apologist, whether it’s services crashing, web pages taking too long to load, or, as in today’s case, missing or corrupted data.

They also call Patty when they need their work done—like upgrading a computer, changing a phone number, or deploying a new application. She does all of the scheduling, so people are always lobbying her to get their work done first. She’ll then hand it off to people who do the work. For the most part, they live in either my old group or in Wes’ group.

Wes pounds the table, saying, “Just get the vendor on the phone and tell them that unless they get a tech down here pronto, we’re going to the competition. We’re one of their largest customers! We should probably have abandoned that pile of crap by now, come to think of it.”

He looks around and jokes, “You know the saying, right? The way you can tell a vendor is lying is when their lips are moving.”

One of the engineers across from Wes says, “We have them on the phone right now. They say it’ll be at least four hours before their SAN field engineer is on-site.”

I frown. Why are they talking about the SAN? Storage area networks provide centralized storage to many of our most critical systems, so failures are typically global: It won’t be just one server that goes down; it’ll be hundreds of servers that go down all at once.

While Wes starts arguing with the engineer, I try to think. Nothing about this payroll run failure sounds like a SAN issue. Ann suggested that it was probably something in the timekeeping applications supporting each plant.

“But after we tried to rollback the SAN, it stopped serving data entirely,” another engineer says. “Then the display started displaying everything in kanji! Well, we think it was kanji. Whatever it was, we couldn’t make heads or tails of those little pictures. That’s when we knew we needed to get the vendor involved.”

Although I’m joining late, I’m convinced we’re totally on the wrong track.

I lean in to whisper to Wes and Patty, “Can I get a minute with you guys in private?”

Wes turns and, without giving me his full attention, says loudly, “Can’t it wait? In case you haven’t noticed, we’re in the middle of a huge issue here.”

I put my hand firmly on his shoulder. “Wes, this is really important. It’s about the payroll failure and concerns a conversation I just had with Steve Masters and Dick Landry.”

He looks surprised. Patty is already out of her chair. “Let’s use my office,” she says, leading the way.

Following Patty into her office, I see a photo on her wall of her daughter, who I’d guess is eleven years old. I’m amazed at how much she looks like Patty—fearless, incredibly smart, and formidable—in a way that is a bit scary in such a cute little girl.

In a gruff voice, Wes says, “Okay, Bill, what’s so important that you think is worth interrupting a Sev 1 outage in progress?”

That’s not a bad question. Severity 1 outages are serious business-impacting incidents that are so disruptive, we typically drop everything to resolve them. I take a deep breath. “I don’t know if you’ve heard, but Luke and Damon are no longer with the company. The official word is that they’ve decided to take some time off. More than that, I don’t know.”

The surprised expressions on their faces confirm my suspicions. They didn’t know. I quickly relate the events of the morning. Patty shakes her head, uttering a tsk-tsk in disapproval.

Wes looks angry. He worked with Damon for many years. His face reddens. “So now we’re supposed to take orders from you? Look, no offense, pal, but aren’t you a little out of your league? You’ve managed the midrange systems, which are basically antiques, for years. You created a nice little cushy job for yourself up there. And you know what? You have absolutely no idea how to run modern distributed systems—to you, the 1990s is still the future!

“Quite frankly,” he says, “I think your head would explode if you had to live with the relentless pace and complexity of what I deal with every day.”

I exhale, while counting to three. “You want to talk to Steve about how you want my job? Be my guest. Let’s get the business what they need first and make sure that everyone gets paid on time.”

Patty responds quickly, “I know you weren’t asking me, but I agree that the payroll incident needs to be our focus.” She pauses and then says, “I think Steve made a good choice. Congratulations, Bill. When can we talk about a bigger budget?”

I flash her a small smile and a nod of thanks, returning my gaze to Wes.

A couple moments go by, and expressions I can’t quite decipher cross his face. Finally he relents, “Yeah, fine. And I will take you up on your offer to talk to Steve. He’s got a lot of explaining to do.”

I nod. Thinking about my own experience with Steve, I genuinely wish Wes luck if he actually decides to have a showdown with him.

“Thank you for your support, guys. I appreciate it. Now, what do we know about the failure—or failures? What’s all this about some SAN upgrade yesterday? Are they related?”

“We don’t know,” Wes shakes his head. “We were trying to figure that out when you walked in. We were in the middle of a SAN firmware upgrade yesterday when the payroll run failed. Brent thought the SAN was corrupting data, so he suggested we back out the changes. It made sense to me, but as you know, they ended up bricking it.”

Up until now, I’ve only heard “bricking” something in reference to breaking something small, like when a cell phone update goes bad. Using it to refer to a million-dollar piece of equipment where all our irreplaceable corporate data are stored makes me feel physically ill.

Brent works for Wes. He’s always in the middle of the important projects that IT is working on. I’ve worked with him many times. He’s definitely a smart guy but can be intimidating because of how much he knows. What makes it worse is that he’s right most of the time.

“You heard them,” Wes says, gesturing toward the conference table where the outage meeting continues unabated. “The SAN won’t boot, won’t serve data, and our guys can’t even read any of the error messages on the display because they’re in some weird language. Now we’ve got a bunch of databases down, including, of course, payroll.”

“To work the SAN issue, we had to pull Brent off of a Phoenix job we promised to get done for Sarah,” Patty says ominously. “There’s going to be hell to pay.”

“Uh-oh. What exactly did we promise her?” I ask, alarmed.

Sarah is the SVP of Retail Operations, and she also works for Steve. She has an uncanny knack for blaming other people for her screwups, especially IT people. For years, she’s been able to escape any sort of real accountability.

Although I’ve heard rumors that Steve is grooming her as his replacement, I’ve always discounted that as being totally impossible. I’m certain that Steve can’t be blind to her machinations.

“Sarah heard from someone that we were late getting a bunch of virtual machines over to Chris,” she replies. “We dropped everything to get on it. That is, until we had to drop everything to fix the SAN.”

Chris Allers, our VP of Application Development, is responsible for developing the applications and code that the business needs, which then get turned over to us to operate and maintain. Chris’ life is currently dominated by Phoenix.

I scratch my head. As a company, we’ve made a huge investment in virtualization. Although it looks uncannily like the mainframe operating environment from the 1960s, virtualization changed the game in Wes’ world. Suddenly, you don’t have to manage thousands of physical servers anymore. They’re now logical instances inside of one big-iron server or maybe even residing somewhere in the cloud.

Building a new server is now a right-click inside of an application. Cabling? It’s now a configuration setting. But despite the promise that virtualization was going to solve all our problems, here we are—still late in delivering a virtual machine to Chris.

“If we need Brent to work the SAN issue, keep him there. I’ll handle Sarah,” I say. “But if the payroll failure was caused by the SAN, why didn’t we see more widespread outages and failures?”

“Sarah is definitely going to be one unhappy camper. You know, suddenly I don’t want your job anymore,” Wes says with a loud laugh. “Don’t get yourself fired on your first day. They’ll probably come for me next!”

Wes pauses to think. “You know, you have a good point about the SAN. Brent is working the issue right now. Let’s go to his desk and see what he thinks.”

Patty and I both nod. It’s a good idea. We need to establish an accurate timeline of relevant events. And so far, we’re basing everything on hearsay.

That doesn’t work for solving crimes, and it definitely doesn’t work for solving outages.
