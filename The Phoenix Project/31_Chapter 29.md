# Chapter 29

## • Monday, November 3

*At 7:10 a.m. the following Monday,* Chris, Wes, Patty, and John are again all seated with me in the boardroom. While we’re waiting for Steve, we talk about the aftermath of the second Phoenix deployment.

Erik is in the back of the room. In front of him is a bowl, an emptied instant oatmeal packet, and a French press full of greenish water, with leaves floating in it.

Seeing my puzzled expression, he says, “Yerba maté. My favorite drink from South America. I never travel without it.”

Steve walks through the door, still talking on his cell phone. “Look, Ron, for the last time, no! No more discounts—even if they were our last remaining customer. We’ve got to hold the line somewhere. Got it?”

He hangs up, exasperated, and finally sits down at the head of the table, muttering, “Sorry I’m late.” He opens up his folder, taking a moment to study something inside it.

“Despite how the Phoenix deployment went over the weekend, I’m extremely proud of everything you’ve have done over the last couple of weeks. Many people have told me about how pleased they are with IT. Even Dick,” he says incredulously. “He’s told me about how you’re helping to improve our key company performance measures, and he thinks it will be a game changer.”

He smiles. “I am very proud to be a part of this team that is obviously working together better than ever, trusting one another, and getting incredible results.”

He turns to John. “By the way, Dick has also told me that with your help, they’ve established that the financial restatement won’t be material.” Breaking into a smile, he says, “Thank God. I won’t be on the cover of *Fortune* magazine wearing handcuffs, after all.”

Just then, Sarah knocks on the door and enters the room.

“Good morning, Steve,” she says, as she walks in primly, sitting down besides Erik. “I take it you wanted to see me about my new marketing initiatives?”

“You mean, the unauthorized shifts of work you’re running inside the IT factory, like some unscrupulous Chinese plant manager?” Erik asks.

Sarah looks Erik up and down, obviously sizing him up.

Steve indicates to John to present his findings. When he concludes, Steve says sternly, “Sarah, I issued a clear statement. No one is allowed to start any new IT initiatives, internal or external, without my explicit approval. Please explain your actions.”

Sarah picks up her iPhone and angrily taps away for a couple of moments. Putting it down, she says, “Our competitors are kicking our ass. We need every advantage we can get. To achieve the stated objectives that you’ve laid out, I can’t wait for IT. I’m *sure* they’re working very hard, doing their best with what they have and what they know—but it’s not enough. We need to be nimble, and sometimes we need to buy instead of build.”

Wes rolls his eyes.

I respond, “I know that IT hasn’t always been able to deliver what you’ve needed in the past, and I know Marketing and Sales have gotten burned. We want the business to win as much as you do. The problem is that some of your creative initiatives are jeopardizing other important company commitments, such as complying with state laws and regulations on data privacy, as well as our need to stay focused on Phoenix.

“What you’re proposing could lead to more data integrity problems in our order entry and inventory management system. Dick, Ron, and Maggie have made it clear that we must get this data cleaned up and keep it clean. Nothing is more important to understand customer needs and wants, have the right product portfolio, retain our customers, and ultimately increase our revenue and market share.”

I add, “Supporting those projects also requires an incredible amount of work. We’ d need to give your vendors access to our production databases, explain how we’ve set them up, do a bunch of firewall changes, and probably over a hundred other steps. It’s not just as easy as signing an invoice.”

She looks back at me scathingly. This is the most livid I’ve seen her.

Clearly, she doesn’t like me quoting Dick’s company objectives to her, using it to deny her what she wants.

It occurs to me that I might have just made a dangerous enemy.

She addresses the room, “Since Bill seems to understand the business so much better than I do, why doesn’t he tell all of us what he proposes?”

“Sarah, no one understands better what your area of the business needs than you. You’re absolutely entitled to go outside of the company to fulfill those needs if we can’t deliver, as long as we make the decision understanding how it might jeopardize another part of the enterprise,” I say as reasonably as I can. “How about you, Chris, and I meet regularly to see how we can help with your upcoming initiatives?”

“I’m very busy,” she says. “I can’t spend a whole day meeting with you and Chris. I’ve got an entire department to run, you know.”

To my relief, Steve interjects. “Sarah, you will make the time. I look forward to hearing how those meetings go and how you resolve your two unauthorized IT initiatives. Are we clear?”

She says in a huff, “Yes. I’m just trying to do what’s right for Parts Unlimited. I’ll do the best with what I have, but I’m not optimistic about the outcome. You’re really tying my hands here.”

Sarah stands up. “By the way, I had a conversation with Bob Strauss yesterday. I don’t think your leash is as long as you think it is. Bob says we need to be looking at strategic options, like splitting up the company. I think he’s right.”

As she leaves, slamming the door behind her, Erik says wryly, “Well, I’m sure we’ve seen the last of *her*…”

---

*Steve looks at the door *for a moment and then turns to me. “Let’s go to the last item on today’s agenda. Bill, you’re concerned that we’re going the wrong way with Phoenix—that not only are things going to get worse, but we may never achieve the desired business outcomes. That is extremely troubling.”

I shrug my shoulders. “Now you know everything I know. I was actually hoping that Erik could give us some insights.”

Erik looks up, wiping his mustache with a napkin. “Insights? To me, the answer to your problem is obvious. The First Way is all about controlling the flow of work from Development to IT Operations. You’ve improved flow by freezing and throttling the project releases, but your batch sizes are still way too large. The deployment failure on Friday is proof. You also have way too much WIP still trapped inside the plant, and the worst kind, too. Your deployments are causing unplanned recovery work downstream.”

He continues, “Now you must prove that you can master the Second Way, creating constant feedback loops from IT Operations back into Development, designing quality into the product at the earliest stages. To do that, you can’t have nine-month-long releases. You need much faster feedback.

“You’ll never hit the target you’re aiming at if you can fire the cannon only once every nine months. Stop thinking about Civil War era cannons. Think antiaircraft guns.”

He stands up to throw his bowl of oatmeal in the wastebasket. Then he peers in the wastebasket and fishes his spoon back out.

Turning around, he says, “In any system of work, the theoretical ideal is single-piece flow, which maximizes throughput and minimizes variance. You get there by continually reducing batch sizes.

“You’re doing the exact opposite by lengthening the Phoenix release intervals and increasing the number of features in each release. You’ve even lost the ability to control variance from one release to the next.”

He pauses. “That’s ridiculous, given all the investments you’ve made virtualizing your production systems. You still do deployments like they’re physical servers. As Goldratt would say, you’ve deployed an amazing technology, but because you haven’t changed the way you work, you haven’t actually diminished a limitation.”

I look around at everyone, confirming that no one understands what Erik is talking about, either. I say, “The last Phoenix release was caused by a production change to the database server that didn’t get replicated in the upstream environments. I was about to agree with Chris. We should pause deployments until we can figure out how to keep all the environments synchronized. That means slowing down the releases, right?”

Remaining standing, Erik snorts. “Bill, that is simultaneously one of the smartest things I’ve heard all month—and one of the dumbest.”

I don’t react as Erik looks at one of the drawings on the boardroom wall. Pointing at it, he says, “Wilbur, what kind of engine is this?”

Wes grimaces and says, “That’s a 1,300 cc engine for a 2007 Suzuki Hayabusa dragster motorcycle. And by the way, it’s ‘Wes.’ Not ‘Wilbur.’ My name hasn’t changed since last time.”

“Yes, of course,” Erik responds. “Dragster motorcycles are great fun to watch. This one probably goes over 230 miles per hour. How many gears does this racer have?”

Without pausing, Wes responds, “Six. Constant mesh, with a #532 chain drive.”

“Does that include the reverse gear?” Erik asks.

“That model doesn’t have a reverse gear,” Wes replies quickly.

Erik nods as he looks more closely at the drawing on the wall, saying, “Interesting, isn’t it? No reverse gear. So why should your flow of work have a reverse gear?”

The silence lengthens when Steve finally says, “Look, Erik. Can you just say what you’re thinking? To you, this may be a fun game to play, but we’ve got a business to save.”

Erik looks at Steve closely, studying him. “Think like a plant manager. When you see work going upstream, what does it mean to you?”

He quickly responds, “The flow of work should ideally go in one direction only: forward. When I see work going backward, I think ‘waste.’ It might be because of defects, lack of specification, or rework… Regardless, it’s something we should fix.”

Erik nods. “Excellent. I believe that, too.”

He picks up his empty French press and spoon from the table, puts them into his suitcase and starts zipping it up. “The flow of work goes in one direction only: forward. Create a system of work in IT that does that. Remember, the goal is single-piece flow.”

He turns to me. “Incidentally, this will also solve the problem that you’ve been fretting about with Dick. An inevitable consequence of long release cycles is that you’ll never hit the internal rate of return targets, once you factor in the cost of labor. You must have faster cycle times. If Phoenix is preventing you from doing that, then figure out how to deliver the features some other way.

“Without being like Sarah, of course,” he says with a small smile. Picking up his suitcase, he adds, “To do this, you’ll need to put Brent at the very front of the line, just like Herbie in *The Goal*. Brent needs to be working at the earliest stages of the development process. Bill, you of all people should be able to figure this out.

“Good luck, guys,” he says, and we all watch as he closes the door behind him.

Steve finally says, “Anyone have any suggestions or proposals?”

Chris replies first. “As I shared earlier, even minor Phoenix bug fix releases are so problematic that we can’t afford to be doing them monthly. Despite what Erik said, I think we need to slow down our release schedule. I propose moving to one release every other month.”

“Unacceptable,” Steve says, shaking his head. “Last quarter, we missed almost every target we set by a mile. This will be our fifth consecutive quarterly miss—and that was after we lowered our expectations with Wall Street. All our hopes depend on completing Phoenix. You’re telling me that we’re going to have to wait even longer to get the features we need, while our competitors continue to pull away from us? Impossible.”

“It may be ‘impossible’ to you, but look at it from my perspective,” Chris says levelly. “I need my developers building new features. They can’t be constantly tied up with Bill’s team, dealing with deployment issues.”

Steve replies, “This quarter is make or break. We promised the world that we’ d get Phoenix out last month, but because of all the features we delayed, we’re not getting the sales benefits that we hoped for. Now we’re over a month through the quarter, with the holiday buying season in fewer than thirty days. We are out of time.”

Thinking this through, I force myself to accept that Chris is stating the reality he sees, and that it is based on facts. And the same goes for Steve.

I say to Chris, “If you say that the Phoenix team needs to slow down, you won’t get any argument from me. In the Marines, when you have a company of a hundred men with a man wounded, the first thing you lose is mobility.

“But we still need to figure out how to achieve what Steve needs,” I continue. “As Erik suggested, if we can’t do that inside the Phoenix framework, maybe we can do it outside of Phoenix. I propose we form a SWAT team by detaching a small squad from the main Phoenix team, telling them to figure out what features can help us hit our revenue goals as soon as possible. There’s not a lot of time, so we’ll need to select the features carefully. We’ll tell them that they’re allowed to break whatever rules required to get the job done.”

Chris considers this for a moment and finally nods. “Phoenix is all about helping customers buy things from us, faster and in larger quantities. The last two releases have all been putting down the groundwork to make that happen, but the features to really increase sales are still bogged down. We need to focus on generating good customer recommendations and enable Marketing to create promotions to sell profitable products that we have in inventory.”

“We have years of customer purchasing data and because of our branded credit cards, we know our customer demographics and preferences,” Steve interjects, leaning forward. “Marketing assures me that we can create some really compelling offers to our customers, if we could only get those features shipped.”

Chris, Wes, and Patty dive in to discuss this further, while John looks dubious. Eventually Wes says, “You know, this just may work.” When everyone nods, including John, I feel there’s a sense of excitement and possibility that was missing just minutes ago.
