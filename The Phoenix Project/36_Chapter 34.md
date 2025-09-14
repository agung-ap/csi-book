# Chapter 34

## • Friday, November 28

*By midday Thursday,* right in the middle of Thanksgiving, we knew we were in trouble. The overnight Unicorn e-mail promotion was an incredible success. The response rate was unprecedentedly high, with traffic to our website surging to record levels, which kept bringing down our e-commerce systems.

We initiated an emergency Sev 1 call, putting in all sorts of emergency measures to maintain our ability to take orders, including putting more servers into rotation and turning off computationally-intensive features.

Ironically, one of the developers suggested turning off all the real-time recommendations, which we had worked so hard to build. Why recommend more products to buy, he argued, if customers can’t even complete a transaction?

Maggie quickly agreed, but it still took the developers two hours to change and deploy. Now, this feature can be disabled with a configuration setting, so we can do it in minutes next time around, instead of requiring a full code rollout.

Now that’s what I call designing for IT Operations! It’s getting easier and easier to manage the code in production.

We also kept optimizing database queries and moving the largest site graphics to a third-party content distribution network, offloading more traffic from our servers. By late Thanksgiving afternoon, the customer experience had improved to something tolerable.

The real trouble began the following morning. Although it is an official company holiday, I’ve called everyone one of my staff back into the office.

Wes, Patty, Brent, and Maggie are here for the noon meeting. Chris is here, but has apparently decided that being called in today demanded a different dress code. He’s wearing a garish Hawaiian shirt and jeans and has brought in coffee and doughnuts for everyone.

Maggie convened the meeting a couple of minutes ago. “This morning, our store managers opened up their locations for Black Friday. From the moment they opened the doors, people poured in, waving around printouts of their Unicorn promotion e-mails. In-store traffic today is at record levels. The problem is that the promoted items are now almost completely gone. Our store managers started panicking because customers were leaving angry and empty-handed.

“When store managers try to issue rain checks or get an item shipped to the customer, they’re having to manually key in the order from our warehouse. It’s taking them at least fifteen minutes per order, which is resulting in long lines at the stores and more frustrated customers.”

Just then, the speakerphone on the table beeps. “Sarah dialing in. Who’s on the line?”

Maggie rolls her eyes, and several other people mutter to one another. Sarah’s attempts to undermine Unicorn are well known now. Maggie has to take two minutes to announce everyone on the call and catch her up.

“Thank you,” Sarah says. “I’ll remain on the call. Please continue.”

Maggie thanks her politely and begins brainstorming on how to solve the problems.

An hour later, we generated twenty actions we’ll be tackling all weekend long. We’ll be putting up a web page for store personnel where they can type in the coupon promotion code, which will automate the cross-shipment from our warehouses. In addition, we’ll create a new form on the customer account web page where they can get items delivered directly to them.

It’s a long list.

By Monday morning, the situation has stabilized. Which is good, because we have our weekly Unicorn meeting with Steve.

Chris, Wes, Patty, and John are here. Unlike our previous meetings, Sarah is here, too. She sits with her arms crossed, occasionally uncrossing them to tap out messages to someone on her iPhone.

Steve says to all of us with a wide smile, “I want to congratulate you for all your hard work. It has paid off beyond my wildest expectations. Thanks to Unicorn, both in-store and web sales are breaking records, resulting in record weekly revenue. At the current run rate, Marketing estimates that we’ll hit profitability this quarter. It will be our first profitable quarter since the middle of last year.

“My heartiest congratulations to you all,” he says.

Everyone except Sarah smiles at the news.

“That’s only half the story, Steve,” Chris says. “The Unicorn team is kicking butt. They’ve moved from doing deployments every two weeks to every week, and we’re now experimenting with doing daily deployments. Because the batch size is so much smaller, we can make small changes very quickly. We’re now doing A/B testing all the time. In short, we’ve never been able to respond to the market this quickly, and I’m sure there are more rabbits we can pull out of this hat.”

I nod emphatically. “I suspect we’ll want to follow the Unicorn model for any new applications we develop internally. It’s easier to scale, as well as easier to manage, than any application we’ve supported in the past. We’re setting up the processes and procedures so that we can deploy at whatever rate it takes to quickly respond to customers. In some cases, we’re even enabling developers to deploy the code. The developer will be able to push a button and within several minutes, the code will be in the testing environment or in production.”

“I can’t believe how far we’ve come in such a short time. I’m proud of all of you,” Steve says. “I want to commend you for truly working together and being worthy of one another’s trust.”

“Better late than never, I suppose,” Sarah says. “If we’re done congratulating ourselves, I’ve got a business wake-up call for you. Earlier this month, our largest retail competitor started partnering with their manufacturers to allow custom build-to-order kits. Sales of some our top selling items are already down twenty percent since they launched this offering.”

Angrily, she adds, “For years, I’ve been trying to get IT to build out the infrastructure to enable this capability, but all we heard was, ‘no, it can’t be done.’ Meanwhile, our competition has been able to work with any manufacturer who says yes.”

She adds, “That’s why Bob’s idea of splitting up the company has so much merit. We’re being shackled by the legacy manufacturing side of this business.”

What? Buying the retail firm was her idea! Maybe life would have been easier for everyone if she had just gone to work for a retailer.

Steve frowns. “This is the next agenda item. As SVP of Retail Operations, it’s Sarah’s prerogative to bring business needs and risks to this team.”

Wes snorts. To Sarah, he says, “You’re kidding, right? Do you understand what we just achieved with Unicorn, and how fast we did it? What you’re describing isn’t that difficult, compared to what we just pulled off.”

---

*The next day,* Wes walks in wearing an uncharacteristically glum face. “Uh, boss. I hate to say it, but I don’t think it can be done.”

When I ask him to explain, he says, “To do what our competitor is doing, we’ d have to completely rewrite our manufacturing resource planning system that supports all the plants. It’s an old mainframe application that we’ve used for decades. We outsourced it three years ago. Mostly because old people like you were going to retire soon.

“No offense,” he adds. “We laid off many of our mainframe people years ago—they were making salaries way above the norm. Some outsourcer convinced our CIO at the time that they had the gray-haired workforce that could keep our application on life-support until we retired it. Our plan was that we would replace with a newer ERP system, but obviously, we never got around to it.”

“Dammit, we’re the customer and they’re our supplier,” I say. “Tell them that we’re paying them not just to maintain the application but also to make any needed business changes. According to Sarah, we need this change. So find out how much they want to charge us and how long we’ll have to wait.”

“I did that,” Wes says, pulling out a ream of paper from under his arm. “Here’s the proposal they finally sent after I managed to get the stupid account manager out of the way so I could actually talk to one of the technical analysts.

“They want six months to gather the requirements, another nine months to develop and test, and if we’re lucky, we might be able to put it into production one year from now,” he continues. “The problem is, the resources we need aren’t available until June. So, we’re talking about eighteen months. Minimum. To even start the process, they would need $50K for the feasibility study and to secure a slot in their development schedule.”

Wes is bright red now, shaking his head. “That worthless account manager keeps insisting that the contract just won’t allow him to help us. Bastard. Obviously, his job is to make sure that everything that can be billed for is, and to dissuade us from doing anything not on the contract, like development.”

I exhale loudly, thinking through the implications. The constraint preventing us from going where we need to go is now outside our organization. But if it’s outside the organization, what can we possibly do? We can’t convince an outsourcer to change their priorities or their management practices as we’ve done.

Suddenly, a glimmer of an idea hits me.

“How many people do they have allocated to our account?” I ask.

“I don’t know,” Wes says. “I think there are six people assigned at thirty percent allocation. It probably depends on their role.”

“Get Patty in here, along with a copy of the contract, and let’s work through the math. And see if you can grab someone from Purchasing, too. I have an audacious proposal that I’d like to explore.”

---

*“Who outsourced the **MRP** application?” *Steve asks from behind his desk.

I’m sitting in Steve’s office with Chris, Wes, and Patty, with Sarah standing off to the side, whom I try to ignore.

I explain our idea to Steve again. “Many years ago, we decided that this application wasn’t a critical part of the business, so we outsourced it to cut costs. Obviously, they didn’t view it as a core competency.”

“Well, it’s obviously a core competency now!” replies Steve. “Right now, that outsourcer is holding us hostage, preventing us from doing something that needs to be done. They’re more than just a roadblock. They’re now jeopardizing our future.”

I nod. “In short, we’ d like to break the outsourcing contract early, bringing those resources back into the company. We’re talking about approximately six people, some of whom are still onsite. To buy out the remainder of the contract two years early would be almost one million dollars, and we would regain complete control of the MRP application and underlying infrastructure. Everyone on this team believes this is the right thing to do, and we’ve even got the initial blessing from Dick’s team.”

I hold my breath. I just threw out a very a big number. It’s considerably bigger than the budget increase I asked for two months ago when I got thrown out of this office.

I quickly continue, “Chris believes that once this MRP application is back in-house, we could build an interface to Unicorn. We would then start building the manufacturing capability to move us from ‘build to inventory’ to ‘build to order,’ which would enable us to provide the custom kits as Sarah requested. If we execute everything flawlessly, and the integration with the order entry and inventory management systems goes as planned, we could match what our competitors are doing in about ninety days.”

Out of the corner of my eye, I can see the wheels turning furiously in Sarah’s head.

Steve doesn’t shoot down the idea down right away. “Okay, you have my attention. What are the top risks?”

Chris takes this one. “The outsourcer may have made big changes to the code base that we don’t know about, which would slow down the development schedule. But my personal belief is that this risk is minimal. Based on their behavior, I don’t think they made any significant changes to functionality.

“I’m not worried about the technical challenges,” he continues. “The MRP was not designed for large batch sizes and certainly not batch sizes of one that we’re talking about here. But I’m sure we can make something work short-term and figure out a long-term strategy as we go.”

When Chris finishes, Patty adds, “The outsourcer could also decide to make the transition back to us difficult, and there could be animosity from the affected engineers. There were a lot of hard feelings when we announced the contract—among other things, their pay was cut the instant they switched from being Parts Unlimited employees to being a vendor.”

She continues. “We should get John involved right away, because we’ll need to take away access from all the outsourcer staff that we’re not bringing back in.”

Wes laughs, saying, “I’d like to personally delete the login credentials of that jackass account manager. He’s a jerk.”

Steve is listening attentively. He then turns to Sarah and asks, “Your thoughts on the team’s proposal?”

She says nothing for several moments but eventually says imperiously, “I think we need to check with Bob Strauss and get full board approval before we undertake a project this big and risky. Given the previous performance of IT, this could jeopardize all of our manufacturing operations, which is more risk than I think we should take on. In short, I personally do not support this proposal.”

Steve studies Sarah, saying with a thin-lipped smile, “Remember that you work for me, not Bob. If you can’t work within that arrangement, I will need your immediate resignation.”

Sarah turns white, her jaw dropping, obviously realizing she’s badly misplayed her hand.

Struggling to regain her composure, she laughs nervously at Steve’s comment, but no one else joins in. I furtively look at my colleagues, and see that, like me, their eyes are wide, watching this drama unfold.

Steve continues, “On the contrary, thanks to IT, we may no longer need to consider all the onerous strategic options that you and Bob are preparing, but your point is well taken.”

To the rest of us, Steve says, “I’m assigning you one of Dick’s best people and our corporate counsel. They’ll help you flawlessly execute this project and make sure we use every trick in the book to get what we need from the outsourcer. I’ll make sure Dick gives this project his personal attention.”

Sarah’s eyes widen even further. “That’s an excellent idea, Steve. That would significantly reduce our risk here. I think Bob will really like it.”

The expression on Steve’s face suggests that his patience for her theatrics is nearly at an end.

He asks us if there’s anything else we need. When there isn’t, he excuses everyone but asks Sarah to remain behind.

As we leave, I sneak a peek behind us. Sarah is sitting down where I previously sat, nervously watching everyone file out. Catching her eye, I smile at her and close the door.
