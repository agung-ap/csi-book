# Chapter 31

## • Monday, November 3

*It’s 12:13 p.m. when I walk* into the SWAT team kick-off meeting. My hair is dripping wet and my shirt is soaked from my ride back in Erik’s convertible. Chris is talking. “—and so Steve has authorized this small team to deliver the promotion functionality and do whatever it takes to make a positive impact on the holiday shopping season.”

Chris turns to me and points to the back of the room. “I went ahead and ordered lunch for everyone to kick this off. Go ahead and—what happened to you?”

I wave away his question. Looking at where he’s pointing, I’m pleasantly surprised to see a turkey sandwich lunch box still at the back. Grabbing it, I take a seat and try to gauge the temperature of everyone in the room, especially Brent.

Brent responds, “Explain again why I’m here?”

“That’s what we’re here to figure out,” Wes says earnestly. “You know as much as we do. One of the potential board members insisted that you be a part of this team. Quite frankly, he’s been right enough times that I trust him, even if I have no freaking idea why.”

Patty chimes in. “Well, he gave us a couple of clues. He said that the problems we need to focus on are the deployment process and the way we’re building the environments. He seems to think we must be doing something fundamentally wrong because of all the chaos resulting from each Phoenix deployment.”

As I unwrap my sandwich I say, “I just came back from a meeting with him. He showed me a bunch of stuff and explained how they do single-minute exchanges of die at Toyota. He thinks we need to build the capability to do ten deploys per day. He not only insists this is possible but also that it supports the feature deployment cycles the business needs, not just to survive, but to win in the marketplace.”

Surprisingly, Chris speaks out the most fiercely. “*What*? Why in the world would we need to do ten deploys a day? Our sprint intervals are three weeks long. We don’t have anything to deploy ten times a day!”

Patty shakes her head. “Are you sure? What about bug fixes? What about performance enhancements when the site grinds to a halt, like what’s happened during the last two major launches? Wouldn’t you love to do these types of changes in production routinely, without having to break all the rules to do some sort of emergency change?”

Chris thinks for a couple of moments before responding. “Interesting. I would normally call those types of fixes a patch or a minor release. But you’re right—those are deployments, too. It would be great if we could roll out fixes more quickly, but come on, *ten deploys a day?*”

Thinking about what Erik said, I add, “How about enabling Marketing to make their own changes to content or business rules or enabling faster experimentation and A/B split testing, to see what offers work best?”

Wes puts both of his hands on the table. “Mark my words, folks. It can’t be done. We’re dealing with the laws of physics here. Forget about how long it currently takes, which requires over one week of preparation and over eight hours to do the actual deployment! You can only put bits down on the disk so fast.”

That’s exactly what I would have said before the plant tour with Erik. I say earnestly, “Look, maybe you’re right, but humor me for a second: Just how many steps are there in the entire end-to-end deployment process? Are we talking about twenty steps, two hundred, or two thousand?”

Wes scratches his head for a moment before he says, “What do you think, Brent? I would have thought about a hundred steps…”

“Really?” Brent responds. “I would have thought it was more like twenty steps.”

William interjects, “I’m not sure where you’re starting to count, but if we begin at the point where Development commits code and we label it as a ‘release candidate,’ I can probably come up with a hundred steps, even before we hand it to IT Operations.”

Uh-oh.

Wes interrupts, “No, no, no. Bill said ‘deployment steps.’ Let’s not open up a can of—”

As Wes talks, I think about Erik challenging me to think like a plant manager as opposed to a work center supervisor. I suddenly realize that he probably meant that I needed to span the departmental boundaries of Development and IT Operations.

“You guys are both correct,” I say, interrupting Wes and William. “William, would you mind writing down all the steps on the whiteboard? I’d suggest starting at ‘code committed,’ and keep going until the handoff to our group.”

He nods and walks to the whiteboard and starts drawing boxes, discussing the steps as he goes. Over the next ten minutes, he proves that there are likely over one hundred steps, including the automated tests run in the Dev environment, creating a QA environment that matches Dev, deploying code into it, running all the tests, deploying and migrating into a fresh staging environment that matches QA, load testing, and finally the baton being passed to IT Operations.

When William is finished, there are thirty boxes on the board.

Looking over at Wes, I see that rather than looking irritated, he actually appears deep in thought, rubbing his chin while looking at the diagram.

I indicate to Brent and Wes that one of them should continue where William left off.

Brent gets up and starts drawing boxes to indicate the packaging of the code for deployment; preparing new server instances; loading and configuring the operating system, databases, and applications; making all the changes to the networks, firewalls, and load balancers; and then testing to make sure the deployment completed successfully.

I contemplate the entirety of the diagram, which surprisingly reminds me of the plant floor. Each of these steps is like a work center, each with different machines, men, methods, and measures. IT work is probably *much more complex* than manufacturing work. Not only is the work invisible, making it more difficult to track, but there are far more things that could go wrong.

Countless configurations need to be set correctly, systems need enough memory, all the files need to be put in the right place, and all code and the entire environment need to be operating correctly.

Even one small mistake could take everything down. Surely this meant that we needed even *more* rigor and discipline and planning than in manufacturing.

I can’t wait to tell Erik this.

Realizing the importance and enormity of the challenge in front of us, I walk to the whiteboard, and pick up the red marker. I say, “I’m going to put a big red star on each step where we had problems during previous launches.”

Starting to make marks on the whiteboard, I explain, “Because a fresh QA environment wasn’t available, we used an old version; because of all the test failures, we made code and environment changes to the QA environment, which never made it back into the Dev or Production environments; and because we never synchronized all the environments, we had the same problems the next time around, too.”

Leaving a trail of red stars, I start marching into Brent’s boxes. “Because we didn’t have correct deployment instructions, it took us five turns to get the packaging and deployment scripts right. This blew up in production because the environment was incorrectly built, which I’ve already brought up.”

Even though I didn’t do it on purpose, by the time I’m done, almost all of William and Brent’s boxes had red stars next to them.

Turning around, I see everyone’s dispirited faces as they take in what I’ve done. Realizing my potential mistake, I hurriedly add, “Look, my goal isn’t to blame anyone or say that we’re doing a crappy job. I’m merely trying to get down on paper exactly what we’re doing and get some objective measures of each step. Let’s fight the problem that’s on the whiteboard as a team and not blame one another, okay?”

Patty says, “You know, this reminds me of something that I’ve seen the plant floor guys use all the time. If one of them walked in, I’m guessing that they’d think we’re building a ‘value stream map.’ Mind if I add a couple of elements?”

I pass the whiteboard marker to her and sit down.

For each of the boxes, she asks how long each of these operations typically takes then jots the number on top of the box. Next, she asks whether this step is typically where work has to wait then draws a triangle before the box, indicating work in process.

Holy crap. To Patty, the similarity between our deployments and a plant line isn’t some academic question. She’s treating our deployment as if it actually was a plant line!

She’s using Lean tools and techniques that the manufacturing folks use to document and improve their processes.

Suddenly, I understand what Erik meant when he talked about the “deployment pipeline.” Even though you can’t see our work like in a manufacturing plant, it’s still a value stream.

I correct myself. It’s our value stream, and I’m confident that we’re on the brink of figuring out how to dramatically increase the flow of work through it.

After Patty finishes recording the durations of the steps, she redraws the boxes, using short labels to describe the process steps. On a separate whiteboard, she writes down two bullet points: “environments” and “deployment.”

Pointing to what she just wrote, she says, “With the current process, two issues keep coming up: At every stage of the deployment process, environments are never available when we need them, and even when they are, there’s considerable rework required to get them all synchronized with one another. Yes?”

Wes snorts, saying, “No reward for stating something *that* obvious, but you’re right.”

She continues, “The other obvious source of rework and long setup time is in the code packaging process, where IT Operations takes what Development checks into version control and then generates the deployment packages. Although Chris and his team do their best to document the code and configurations, something always falls through the cracks, which are only exposed when the code fails to run in the environment after deployment. Correct?”

This time, Wes doesn’t respond right away. Brent beats him, saying, “You’ve nailed it. William can probably relate to these problems: the release instructions are never up-to-date, so we’re always scrambling, trying to futz with it, having to rewrite the installer scripts and install it over and over again…”

“Yep,” William says, nodding adamantly.

“I’d suggest we focus on those two areas, then,” she says, looking at the board and then grabbing her seat again. “Any ideas?”

Brent says, “Maybe William and I can work together to build a deployment run book, to capture all the lessons learned from our mistakes?”

I nod, listening to everyone’s ideas, but none of them seem like the massive breakthrough we need. Erik had described the reduction of setup time for the door stamping process. He seemed to indicate that it was important. But why?

“Having each group cobble an environment together obviously isn’t working. Whatever we do must take us a big step toward this ‘ten deploys a day’ target,” I say. “This implies that we need a significant amount of automation. Brent, what would it take for us to be able to create a common environment creation process, so we can simultaneously build the Dev, QA, and Production environments at the same time, and keep them synchronized?”

“Interesting idea,” Brent says, looking at the board. He stands up and draws three boxes labeled “Dev,” “QA,” and “Production.” And then underneath them, he draws another box labeled “Build Procedure” with arrows into each of the boxes above.

“That’s actually pretty brilliant, Bill,” he says. “If we had a common build procedure, and everyone used these tools to create their environments, the developers would actually be writing code in an environment that at least resembles the Production environment. That alone would be a huge improvement.”

He takes the marker cap out of his mouth. “To build the Phoenix environment, we use a bunch of scripts that we’ve written. With a bit of documentation and cleanup, I bet we could cobble together something usable in a couple of days.”

Turning to Chris, I say, “This seems promising. If we could standardize the environments and get these in daily use by Development, QA, and IT Operations, we could eliminate the majority of variance that’s causing so much grief in the deployment process.”

Chris seems excited. “Brent, if it’s okay with you and everyone else, I’d like to invite you to our team sprints, so that we can get environment creation integrated into the development process as early as possible. Right now, we focus mostly on having deployable code at the end of the project. I propose we change that requirement. At each three-week sprint interval, we not only need to have deployable code but also the exact environment that the code deploys into, and have that checked into version control, too.”

Brent smiles widely at the suggestion. Before Wes can respond, I say, “I completely agree. But before we go further, can we investigate the other issue that Patty highlighted? Even if we adopted Chris’ suggestions, there’s still the issue of the deployment scripts. If we had a magic wand, whenever we have a fresh QA environment, how should we deploy the code? Every time we deploy, we constantly ping-pong code, scripts, and God knows what else among groups.”

Patty chimes in. “On the manufacturing floor, whenever we see work go backward, that’s rework. When that happens, you can bet that the amount of documentation and information flow is going to be pretty poor, which means nothing is reproducible and that it’s going to get worse over time as we try to go faster. They call this ‘non-value-add’ activity or ‘waste.’ ”

Looking at the first whiteboard with all the boxes, she says, “If we redesign the process, we need to have the right people involved upfront. This is like the manufacturing engineering group ensuring that all parts are designed so that they are optimized for manufacturing and that the manufacturing lines are optimized for the parts, ideally in single-piece flow.”

I nod, smiling at the similarities between what Patty is recommending and what Erik suggested earlier today.

Turning to William and Brent, I say, “Okay, guys, you have the magic wand. You’re at the front of the line. Tell me how you’d design the manufacturing line so that work never goes backward, and the flow is moving forward quickly and efficiently.”

When they both give me a blank look, I say with some exasperation, “You have a *magic wand*. Use it!”

“How big is the magic wand?” William asks.

I repeat what I said to Maggie. “It’s a *very* powerful magic wand. It can do anything.”

William walks to the whiteboard and points at a box called “code commit.” “If I could wave this magic wand, I would change this step. Instead of getting source code or compiled code from Dev through source control, I want packaged code that’s ready to be deployed.”

“And you know,” he continues, “I want this so much, I’d happily volunteer to take over responsibility for package creation. I know exactly the person I’d assign, too. She would be responsible for the Dev handoff. When code is labeled ‘ready to test,’ we would then generate and commit the packaged code, which would trigger an automated deployment into the QA environment. And later, maybe even the Production environment, too.”

“Wow. You’d really do that?” Wes asks. “That would be really great. Let’s do it—unless Brent really wants to keep doing the packaging?”

“Are you kidding?” Brent asks, bursting out laughing. “I’ll buy whoever this person is drinks for the rest of the year! I love this idea. And I want to help build the new deployment tools. Like I said, I’ve got a bunch of tools that I’ve written that we can use as a starting point.”

I can feel the energy and excitement in the room. I’m amazed at how quickly we went from believing the ‘ten deploys a day’ target was a delusional fantasy, to wondering how close we can get.

Suddenly, Patty looks up and says, “Wait a second. This entire Phoenix module deals with customer purchase data, which has to be protected. Shouldn’t someone from John’s team be a part of this effort, as well?”

We all look at one another, agreeing that he needs to be involved. And once again, I marvel at how much we’ve changed as an organization.
