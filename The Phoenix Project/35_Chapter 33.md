# Chapter 33

## • Tuesday , November 11

*By the next day, Brent is back on Unicorn,* and one of the level 3 engineers has joined Dick’s team somewhere in the snowy Midwest. Within hours, I get copied on an e-mail from Sarah:

From: Sarah Moulton

To: Bob Strauss

Cc: Dick Landry, Steve Masters, Bill Palmer

Date: November 11, 7:24 AM

Subject: Someone is undermining Project Talon

Bob, I’ve discovered that Bill Palmer, the acting VP of IT Operations, stole the critical resource for Project Talon.

Bill, I’m deeply concerned with your recent actions. Please explain to us why you ordered Brent to return home? This is absolutely intolerable. The board has instructed us to explore strategic options.

I demand that Brent rejoin the Talon team as soon as possible. Please confirm you understand this message.

Sarah

Genuinely alarmed that I’m being called out on an e-mail to the company chairman, I call Steve, who is obviously furious at Sarah’s apparent change in loyalties. After swearing under his breath, he assures me that he’ll handle this and that I am to continue as planned.

At the daily Unicorn stand-up meeting, William doesn’t look happy. “The good news is that as of last night, we’ve generated our first customer promotion report and it appears to be working correctly. But the code is running fifty times slower than we expected. One of the clustering algorithms isn’t parallelizing like we thought it would, so the prediction runs are already taking more than twenty-four hours, even for our small customer data set test.”

Grumbles and groans go around the room.

One of the developers says, “Can’t we just use brute force? Just throw more hardware at the problem. With enough compute servers, we can bring the run times down.”

“Are you kidding me?” Wes says, with exasperation. “We only budgeted for twenty of the fastest servers we could find. You’d need over a thousand servers to get the run times down to where we need. That’s over $1 million in unbudgeted capital!”

I purse my lips. Wes is right. Phoenix is way over budget as it is, and we’re talking about a large enough amount of money that it’ll be impossible to get this approved, especially given our financial condition.

“We don’t need any new hardware,” the developer replies. “We’ve invested all this effort to create compute images that we can deploy. Why not send them out to the cloud? We could spin up hundreds or thousands of compute instances as we need them, tear them down when we’re done, and just pay for the compute time we use.”

Wes looks at Brent, who says, “It’s possible. We’re already using virtualization for most of our environments. It shouldn’t be very difficult to convert them so that they run on a cloud computing provider.”

After a moment, he adds, “You know, that would be fun. I’ve always wanted to try something like this.”

Brent’s excitement is contagious.

We start assigning tasks to investigate its feasibility. Brent teams up with the developer who had suggested the idea to do a quick prototype, to see whether it is even possible.

Maggie, who has taken such an interest in Unicorn that she’s routinely attending the daily stand-ups, volunteers to look into pricing and will call her peers in the industry to see if any of them have done this before and to get any recommended vendors.

One of John’s security engineers interrupts, “Sending our customer data to the cloud may have some risks like accidental disclosure of private data or someone unauthorized hacking into those compute servers.”

“Good thinking,” I say. “Can you list your top risks we should be thinking about, and prepare a list of potential countermeasures and controls?”

He smiles in response, happy to be asked. One of the developers volunteers to work with him.

By the end of the meeting, I’m surprised at the unanticipated payoffs of automating our deployment process. The developers can more quickly scale the application, and potentially few changes would be required from us.

Despite this, I’m extremely dubious of all this cloud computing hullabaloo. People treat it as if it’s some sort of magical elixir that instantaneously reduces costs. In my mind, it’s just another form of outsourcing.

But if it solves a problem we’re having, I’m willing to give it a try. I remind Wes to keep an open mind, as well.

---

*A week later, once again, *it’s demo time. We’re all standing in the Unicorn team area. It’s the end of the sprint, and the Development lead is eager to show off what the team has accomplished.

“I can hardly believe how much we got done,” he starts off. “Because of all the deployment automation, getting compute instances running in the cloud wasn’t as hard as we thought. In fact, it’s working so well that we’re considering turning all the in-house Unicorn production systems into test systems and using the cloud for all our production systems.

“We start the recommendations reporting run every evening and spin up hundreds of compute instances until we’re done, and then we turn them off. We’ve been doing this for the past four days, and it’s working well—really well.”

Brent has a wide smile on this face, as does the rest of the team.

Next up is usually the product manager, but this time Maggie is presenting instead. She’s obviously taking more than just casual interest in this project.

She pulls up a PowerPoint slide on the projector. “These are the Unicorn promotions generated for my customer account. As you can see, it’s looked at my buying history and is letting me know that snow tires and batteries are fifteen percent off. I actually went to our website and purchased both, because I need them. The company just made money, because those are all items that we have excess inventory and high profit margins.”

I smile. Now that’s brilliant.

“And, here are the Unicorn promotions for Wes,” she continues, going to the next slide, with a smile. “Looks like you got a discount on racing brake pads and fuel additives. That of any interest to you?”

Wes smiles. “Not bad!”

Maggie explains that all these offers are already in the Phoenix system, and it was just waiting for the promotion functionality to finally get them to the customers.

She continues, “Here’s my proposal: I’d like to do an e-mail campaign to one percent of our customers, to see what happens. Thanksgiving is in one week. If we could do a couple of trials and everything goes well, we’ d go full blast on Black Friday, which is the busiest shopping day of the year.”

“Sounds like a good plan,” I say. “Wes, is there any reason why we shouldn’t do this?”

Wes shakes his head. “From an Ops perspective, I can’t think of any. All the hard work has already been done. If Chris, William, and Marketing have confidence that the code is working, I say go for it.”

Everyone agrees. There are some issues that come up, but Maggie says her team is willing to work all night to make it happen.

I smile inwardly. For once, it won’t be just us staying up all night because something went really wrong. In fact, it’s the exact opposite. People are staying up all night because everything was going right.

---

*The following Monday,* it’s barely above freezing as I’m driving to work, but the sun is shining brightly. It looks like it’s going to be a great week for the upcoming Thanksgiving holiday. Throughout the weekend, I’m a bit startled to see commercials with Santa Claus in them.

When I get to my office, I throw my heavy coat over my chair. I turn when I hear Patty walk into my office and see that she has a broad smile on her face. “Did you hear the amazing news from Marketing?”

When I shake my head, she merely says, “Read the e-mail that Maggie just sent out.”

I flip open my laptop and read:

From: Maggie Lee

To: Chris Allers, Bill Palmer

Cc: Steve Masters, Wes Davis, Sarah Moulton

Date: November 24, 7:47 AM

Subject: First Unicorn promotion campaign: UNBELIEVABLE!

The Marketing team burned the midnight oil over the weekend and we were able to do a test campaign to one percent of our customers.

The results were STELLAR! Over twenty percent of the respondents went to our website, and over six percent purchased. These are incredibly high conversion rates—probably over 5× higher than any campaign we’ve done before.

We recommend doing a Unicorn promotion to all our customers on Thanksgiving Day. I’m working to get a dashboard up so everyone can see real-time results of the Unicorn campaigns.

Also, remember that all the items being promoted are high margin items, so the effects on our bottom line will be excellent.

PS: Bill, based on the results, we expect a huge surge in web traffic. Can we make sure the website won’t fall over?

Great work, all!

Maggie

“I love it,” I say to Patty. “Work with Wes to figure out what we need to do to handle the surge in traffic. We’ve only got three days to get this done, so we don’t have much time. We don’t want to screw this up and turn prospective customers into haters.”

She nods and is about to respond when her phone vibrates. An instant later, my phone vibrates, too. She quickly looks down and says, “The dragon lady strikes again.”

“I wish I had an ‘unsubscribe’ button for her e-mails,” Patty says as she walks out.

A half hour later, Steve sent out a congratulatory note to the entire Unicorn team, which everyone loved reading. More surprisingly, he also sent out a public reply to Sarah, demanding that she stop “stirring the pot and making trouble” and to “see me at your earliest convenience.”

That still didn’t stop all the public e-mails going back and forth among Sarah, Steve, and Bob. Seeing Sarah toadying up to our new chairman, Bob, was awkward and uncomfortable. It’s like Sarah didn’t even care how obvious she was being and all the bridges she was burning.

I walk into a meeting room to meet John about the resolution of all the SOX-404 and Unicorn security issues. He’s wearing a pin-striped Oxford shirt and a vest, complete with cufflinks. He looks like he just came out of a *Vanity Fair* photo shoot, and I guess he’s continuing to shave his head daily.

“I’m amazed at how quickly the Unicorn security fixes are being integrated,” he says. “Compared to the rest of Phoenix, fixing Unicorn security issues is a breeze. The cycle time is so short, we once put in a fix within an hour. More typically, we can get fixes in within a day or two. Compared to this, remediating Phoenix issues is like pulling our own teeth out, without any anesthesia. Normally, we’ d have to wait for a quarter for any meaningful changes to be made, and jumping through all the hoops required to get an emergency change order through was almost not worth the trouble.

“Really,” he continues, “patching is so easy, because we can rebuild anything in production with a touch of a button. If it breaks, we can build it again from scratch.”

I nod. “I’m amazed at the what we can do with the fast Unicorn cycle times, too. With Phoenix, we only rehearsed and practiced doing the deployments once per quarter. Just in the last five weeks, we’ve done over twenty Unicorn code and environment deployments. It almost feels routine. As you said, it’s the opposite of Phoenix.”

John says, “Most of the reservations I had about Unicorn don’t seem valid anymore. We’ve put in regular checks to make sure that the developers who have daily access to production only have read-only access, and we’re making good progress on integrating our security tests into the build procedures. I’m pretty confident that any changes that could affect data security or the authentication modules will get caught quickly.”

He leans back, crossing his arms behind his head. “I was scared shitless of how we’ d gain any sort of assurance about securing Unicorn. It’s partly because we’re so used to taking a month to turn around application security review. In an emergency, like in response to a high-priority audit, we could sometimes turn things around in a week.

“But the notion of having to keep up with ten deploys a day?” he continues. “Complete lunacy! But after being forced to automate our security testing, and integrating it into the same process that William uses for his automated QA testing, we’re testing every time a developer commits code. In many ways, we now have better visibility and code coverage than any of the other applications in the company!”

He adds, “You should know that we just closed out the last of the SOX-404 issues. We were able to prove to the auditors, thanks in large part to the new change control processes you put in, that all the current controls are sufficient, closing out the three-year repeat audit finding.”

With a smile, he adds, “Congratulations, Bill. You’ve done what none of your predecessors have been able to do, which is to finally get the auditors off our back!”

Much to my surprise, the short week goes smoothly. Before everyone leaves on Wednesday for the Thanksgiving holiday, the big Unicorn campaign is ready. Code performance is still ten times slower than we need, but we’re okay for now because we can just spin up hundreds of compute instances in the cloud.

We had a genuine showstopper when QA discovered that we were recommending items that were out of stock. That would have been disastrous, as customers would excitedly click on the promotion, only to find them listed as “backordered.” Incredibly, Development developed a fix within a day, and it was deployed within an hour.

It’s 6 p.m. and I pack up my stuff, looking forward to the long weekend. We’ve all earned it.
