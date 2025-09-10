# 9 [](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)Making sustainable design decisions

### This chapter covers

- Sustainable decisions and what you need to make one
- Decision-making styles and the levels of buy-in
- Facilitating sustainable decisions

What is the most difficult decision you’ve had to make in your life? The answer to that question will be different for everyone. How did you approach this decision? That question might yield more similar answers. “I weighed my options,” “I asked for advice,” “I went with my gut feeling,” and so on. Making a decision clearly involves comparing things with each other, but what else does it entail?

We’ve spoken about ranking, cognitive bias, and conflict. All of these things happen when you’re trying to design your software solution in a collaborative setting. What is software design if not making decisions? We haven’t really spoken about what decisions are, so we’re going to do that in this chapter. We’ll dive a bit deeper into what a decision is, giving you a framework to reason about decisions in general. We’ll discuss software design–related decisions and how to improve the sustainability of those decisions by using Deep Democracy as a facilitator.[](/book/collaborative-software-design/chapter-9/)

## 9.1 Decisions, decisions, decisions

Decisions are everywhere. They take up a lot of our time. We lose sleep over them: “Did I make the right decision quitting my job?” We judge ourselves because of them: “What the hell was I thinking buying that car?” We judge other people because of them: “I honestly don’t understand why they bought that house; I wouldn’t have done that.” We have to live with the consequences of our decisions, or other people will have to live with them. Yet, most of us were never taught how to make decisions. We aren’t even taught what exactly a decision is.[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)

### 9.1.1 What is a decision anyway?

A *decision* is a conscious choice between two or more alternatives that involves an irrevocable allocation of resources.[1](/book/collaborative-software-design/chapter-9/footnote-003) There is a lot to unpack there. Let’s start with “a conscious choice.[](/book/collaborative-software-design/chapter-9/)”[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)

#### A conscious choice

A choice is the act of choosing between two or more possibilities. “The act of choosing” tells us that a decision isn’t a thing, but a process you have to go through and not just going through the motions, but consciously. This is sometimes referred to as *actional thought*. If you don’t think and act, there is no decision.[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)

The opposite of a conscious choice is a habit. The whole point of a habit is that you don’t have to decide what you’re going to do, but simply execute a set of actions. Introducing habits can take away a lot of mental bandwidth because making decisions takes up a lot of time. Of course, it pays off to examine your habits once in a while and decide which ones to keep and which ones are no longer use[](/book/collaborative-software-design/chapter-9/)ful.

#### Alternatives

If we know that a choice means the act of choosing between two or more possibilities, why do we explicitly say this again in the definition? Well because a possibility and an alternative aren’t exactly the same thing. *Alternatives* are a set of plans that you need to choose from. A *plan* is a set of intended actions you’ll take to reach the desired outcome of the decision. We’ll discuss alternatives a bit more in section 9.[](/book/collaborative-software-design/chapter-9/)1.3.[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)

#### Irrevocable allocation of resources

The definition also mentions “irrevocable allocation of resources.” *Resources* can be time, money, or energy. To have made a decision, you need to put time, money, or energy into it. Even more, the resources you put into the decision can’t be undone—they’re irrevocable. This means that there is a cost in being wrong. Undoing your decision will cost you time, money, or energy. This is important to determine whether or not a decision was made. If changing your decision costs you nothing, you didn’t make a decision. Think back on all those New Year’s resolutions—all those people stating that they decided this is the year they will go to the gym, start swimming, and so on. Most of those people don’t even get started with their New Year’s resolutions. Declaring that you’ve made a decision is cheap; actually making one requires you to put your money, uh, resource, where your mouth is![](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)

This also means that you can quantify the importance of a decision by the resources you need to allocate. How much do I stand to lose when I pick the wrong alternative? The more you stand to lose, the more up-front analysis you should do when making a decision. So, when you’re deciding on your software architecture, the design decisions that are hard to change in the future, you want to invest more time analyzing the decision. Yet, we’ve noticed that those decisions are often based on shiny new trends, familiarity, the loudest voice in the room, the highest paid person’s opinion (aka HIPPO), or the “run hard in the opposite direction” a[](/book/collaborative-software-design/chapter-9/)ttitude.

### 9.1.2 Decision vs. outcome

When we make a decision, we have a goal or objective in mind. The *outcome* of a decision is what actually happened and can be different from what we expected. When we’re executing our course of action, unforeseen consequences or events can happen that influence the outcome. The outcome can be better or worse than we expected; in other words, the quality of the decision is different from the quality of the outcome.[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)

Let’s take a look at two common architectural patterns: monolithic and microservices.[2](/book/collaborative-software-design/chapter-9/footnote-002) The decision to go with one or the other is often because of the run hard in the other direction attitude we mentioned earlier: the development team tried microservices and had a bad outcome, so they now go for a monolith, or vice versa. Imagine that you’re the architect on that team, and you have to decide between a monolithic or microservices approach. You decide to go for a monolithic approach. Two years down the road the monolith has turned into a big ball of mud (BBoM), and you need to put a lot of effort into restructuring it.[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)

People might argue that you should have gone for microservices, that your decision was bad. Is that true? It’s hard to answer that question because we don’t have enough context right now to understand it. What we do know is that people have a tendency to think about the quality of a decision in terms of the quality of the outcome. They will call something a bad decision, when it’s actually the result that’s bad, and vice versa. In the poker world, there is even a word for this: resulting. *Resulting* is the tendency to equate the quality of the decision with the quality of the outcome. [](/book/collaborative-software-design/chapter-9/)

It’s not uncommon that people don’t separate the quality of the decision from the quality of the outcome. “Of course, your monolith turned into a big ball of mud, they always do. They should have seen this coming and gone for microservices instead!” Reactions like this show the hindsight bias in action. The *hindsight bias* allows us to believe that past events were more predictable than they actually were. The person reacting like this forgets that microservices can also end up like that; [](/book/collaborative-software-design/chapter-9/)we call these Distributed BBoM. [](/book/collaborative-software-design/chapter-9/)

Whether to go for microservices or a monolithic approach depends on the context. This is why it’s important to not just document the alternative you picked when making the decision, but the entire decision and analysis. We’ll dig a bit deeper in how to do this [](/book/collaborative-software-design/chapter-9/)in chapter 11.

##### Exercise 9.1

Try to find an example from your personal or professional life, where you were confusing the quality of the decision with the quality of the outcome, that is, resulting. Do this for a decision where you had a bad outcome as well as one when there was a[](/book/collaborative-software-design/chapter-9/) good outcome.[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)

### 9.1.3 What you need to make a decision

You want to make good decisions because you want to avoid paying the cost of being wrong. To make good decisions, you need to understand the elements that need to be present when making a decision. There are three main components needed when making a decision (see figure 9.1):[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)

-  *Alternatives*—[](/book/collaborative-software-design/chapter-9/)What we can do
-  *Information*—What we know
-  *Preference*—What we want

![Figure 9.1 The key elements that are needed to make good decisions](https://drek4537l1klr.cloudfront.net/baas/Figures/CH09_F01_Baas.png)

Those three components are the input for making the decision. Every decision has a decision-maker. What comes out of a decision is the plan we’re going to execute. To take those components and turn them into a course of action, we need some logic to guide us. Let’s dig a bit deeper into all these elements, starting with the[](/book/collaborative-software-design/chapter-9/) decision-maker.

#### A decision-maker

The *decision-maker* is the person that has the authority and the permission to allocate the resources when an alternative has been chosen. The person has the authority when they have the explicit rank that allows them to allocate the resources. The more resources that need to be allocated, the higher the explicit rank of the decision-maker. By *permission*, we mean that everyone involved in the decision is in agreement that this is the decision that has to be made.[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)

It’s possible that the decision-maker isn’t involved in the decision analysis itself, but relies on a team of experts to analyze the decision for them. The experts report their findings to the decision-maker, including the best course of action according to their analysis. It’s still within the decision-maker’s power to pick a different course of action though. Another option you have as a decision-maker is to place the decision with the group that has to live with the consequences of the decision, but we’ll talk more about th[](/book/collaborative-software-design/chapter-9/)at in section 9.2.

#### Alternatives

We already explained in the previous section what an alternative is, but we haven’t dug too deep into it. Let’s do that now. First, the decision-maker has to believe that the alternatives available will lead to a different future. If all your alternatives have the same desired outcome, it doesn’t matter which one you pick. When it doesn’t matter which one you pick, you don’t have a decision to make.[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)

Second, the definition explicitly states that you need to choose between two or more alternatives. But what if there isn’t more than one alternative? Well, keeping things as they are is always an option, although under most circumstances, it isn’t the one we want. Still, there is a lot of value in making “keeping things as they are” a visible alternative. You can now compare this with the other alternative and make a conscious decision to keep thing[](/book/collaborative-software-design/chapter-9/)s the way they are.[](/book/collaborative-software-design/chapter-9/)

#### Information

The second input of a decision is *information*, which is what we know. Getting the right amount of knowledge to make an informed decision is very important. You don’t want the gathering of information to be overdone or underdone. How confident we feel about the information that is available to us is expressed in uncertainty. *Uncertainty* shows how much information we have available or how much we trust the information that we do have. As shown in figure 9.2, the more information we gather, the higher our co[](/book/collaborative-software-design/chapter-9/)nfidence will be.[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)

Don’t confuse uncertainty with risk, as they are two different things. We talk about *risk* when all possible outcomes are known, and we express the likelihood of those outcomes to happen in *probabilities*. When we flip a coin, we have two outcomes: heads or tails. We know there is a 50% chance that we get one or the other. Not all decisions we have to make have known outcomes because we don’t have all the information available at the point of making the decision.[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)

This is also why we try to postpone certain design decisions until a later moment during our design activities and simply express our uncertainty by adding hotspots during the collaborative modeling. The more information we have, the better we’ll be able to evaluate all the alternatives available to us. During collaboration, you can also see if you’re digging into the right hotspots. If the confidence level of participants isn’t changing, or only changing slightly with the information you’re gaining, you’re digging into the wrong pl[](/book/collaborative-software-design/chapter-9/)ace (see figure 9.3).

![Figure 9.2 Tracking the confidence of participants during collaborative modeling is a great way to know if the information they are getting out of the sessions is valuable. In this example, we show the confidence of Kala, one of the participants. The more she discovered about the domain, the higher her confidence was.](https://drek4537l1klr.cloudfront.net/baas/Figures/CH09_F02_Baas.png)

![Figure 9.3 If the confidence level of participants during collaborative modeling isn’t going up, try diving deeper into a different part of the EventStorm by picking a different hotspot.](https://drek4537l1klr.cloudfront.net/baas/Figures/CH09_F03_Baas.png)

[](/book/collaborative-software-design/chapter-9/)Uncertainty and the difficulty of a decision are intertwined with one another. To make a decision easier, you need to gain more information or get the right information. That way, the uncertainty goes down, and the decision is easier to make than it was before. A good heuristic to know which information you need to find is the following:

##### GUIDING HEURISTIC

Imagine you were talking to a clairvoyant and could ask them a single piece of information about the decision you’re trying to make. What piece of information would it be?

What makes a decision easy or hard is how well informed you feel about the decision you have to make. Picking your ice cream flavor can be labeled as an easy decision. Whether or not you want to invest money in a start-up is already a lot harder. Why is that? The knowledge readily available for those two decisions is different. I don’t have any knowledge that will help me assess whether or not a start-up is worth investing in, and most people don’t have that either. There is a lot of unc[](/book/collaborative-software-design/chapter-9/)ertainty involved here.

#### Preference

The people involved in making the decision will have a preference on the available alternatives. *Preferences* (what we want) are the criteria or values by which they will compare one alternative with another one. Basically, what consequences are acceptable according to our values? Do we care more about how much money it will cost or how much time we have to spend on executing the plan? Or do we care more about the eco-friendly alternatives? Preference means that certain alternatives are more desirable because the outcome of those are more desirable. If nobody cares about the consequences, and any future will do, there is no decision to be made.[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)

Making these preferences for each person involved in the decision visible is a good way to avoid conflict. We all have a different set of values we evaluate alternatives against. If we know by which values the people around us are evaluating the alternatives, we create better understanding. This isn’t an easy thing to do because a lot of people don’t fully understand their own preferences, which makes it difficult to communicate those to somebody else. As we mentioned in chapter 5, you can apply active listening: “I am scared that going for this design will create too many single points of failure in the system.” With Socratic questioning, you can try to find the preferences and challenge their assumptions: “Do you think any communication between different parts of the system are single points of failure?” This person believes that communication between different parts of the system creates single points of failure that have a possible risk attached to it. We can mitigate that risk, however, by finding more information on how to do this and seeing if the preference of this person changes when there is more information available about the alternatives.

Our preference will be influenced by the way information is presented to us, and we’ll present information in a more positive or negative light depending on our preference. If we emphasize the gains of a certain alternative more than our losses (or leave out the losses completely), we’ll prefer that alternative because it seems better. This is referred to as the *framing effect* in social sciences. So be careful how you share information and tradeoffs duri[](/book/collaborative-software-design/chapter-9/)ng the decision analysis![](/book/collaborative-software-design/chapter-9/)

#### Logic

The last element of a decision is logic. *Logic* is a process to derive which course of action we should take from what we can do (alternatives), what we want to do (preferences), and what we know (information). The process will lead us to a conclusion of the decision analysis. There are two possible paths you can take as a process:[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)

-  Perform a decision analysis.
-  Use heuristics.

Which one you pick depends on the effect of the decision. If you have to make a decision that involves millions of dollars and years to execute, you’ll do a deep decision analysis. The type of decisions you have to make when designing your software system aren’t the right fit for a decision analysis. That is why we use heuristics when designing software. During collaborative modeling, we use heuristics in two ways: design heuristics help us to generate alternatives, and guiding heuristics help us to [](/book/collaborative-software-design/chapter-9/)move forward in the process.

#### Problem statement

Now that we know all the key elements that need to be present when making a decision, we want to talk about what needs to happen before we start to analyze the decision. Before starting the analysis, it’s important to answer this question: What problem are we trying to solve? This is the *problem statement*. It doesn’t matter how well you analyze the decision if you’re solving the wrong problem.[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)

A problem statement that we often hear in software teams is “Our system is too coupled, we need to decouple the system.” When digging a bit further into it, we notice that it’s a communication problem, not a software problem. The system has loose coupling, and it doesn’t send out a lot of unnecessary messages to other services either. However, the teams communicate with each other through documentation only, and often that documentation is outdated. Even if you have a loosely coupled system, you’ll still need to communicate with other teams.

Another common mistake is stating the problem in terms of the solution. “Should we use EventSourcing?” isn’t a good problem statement. Whether or not to use EventSourcing isn’t the problem that we’re trying to solve, but a possible solution.

To come up with a good problem statement, it’s important to select the proper frame. The *frame* is the boundary we draw around the problem:

-  What are the constraints we have to live with?
-  What decisions do we need to make to solve the problem?
-  What decisions are out of scope for now?

Whenever we’re invited to consult with a company, we always check the frame. How much freedom do we have? Can we redesign the whole system? Are you willing to reorganize your teams? Are there any important feature deliveries you can’t miss? Who can we invite? Depending on those constraints, we know which decisions are in scope and which are out of scope right now. We try to find the correct frame. To have the correct frame, you need to do the following:

-  Identify the correct problem.
-  Clarify the problem, so everyone understands it.
-  Look at the problem from different perspectives.
-  Assess the business situation in regard to the problem.
-  Create the appropriate alternatives/options.

Identifying the correct problem isn’t easy. That’s why it’s important when designing software to first understand the problem you’re trying to solve, before you try to come up with alternative solutions for it. Domain-Driven Design tries to help with solving the right problem. If we think back on the principles mentioned in chapter 2, we can see there is much overlap with what you need to do to find the right frame. By using the concepts of problem and solution space, we explicitly focus first on finding the right frame, before we start designing toward a good architectural sol[](/book/collaborative-software-design/chapter-9/)ution for our software system.[](/book/collaborative-software-design/chapter-9/)

### 9.1.4 Reactive vs. proactive decisions

When you have to make a decision, there are two ways you could have reached this point. Something happened, and now you have to make a decision. This is called a *reactive decision* because you’re reacting to an event. Here are a couple of examples:[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)

-  You got fired, and now you need a new job.
-  Your house stops being for rent, and now you need a new place to live.

The second is a *proactive decision*. You want something to change, so you take charge and try to change it by making a decision. Here are two examples:

-  You’re starting to lose interest at work, so you want a new job.
-  Your rent is getting too high, so you want a new living space.

It might not seem important to know what kind of decision you’re making, but it is. Think about our first reactive example. Getting fired is something that will trigger other emotions than when you start to dislike your job and want to get a new one. The way you look at all the alternatives available to you will be influenced, consciously or unconsciously, by these emotions, so your preferences will be different. The time you can spend to make the decision will also be different. Even though it might not seem important, it has a big effect on the decision and its process.

A lot of development teams that we encounter are in a reactive decision-making mindset. The business makes a decision that affects the software system, and then the development teams have to react to that decision. Collaborative modeling helps software teams go from reactive decision-making to proactive decision-making. During collaborative modeling, you can discover business opportunities that would not be possible without software and pitch those to the domain experts. You can explore and design those opportu[](/book/collaborative-software-design/chapter-9/)nities together with the business.

### 9.1.5 Sustainability in software design

You might be thinking that this is all great and interesting, but my job is to solve problems. You’re correct in that—our end goal is to come up with a good software solution. But what makes a software solution good? Is it how well it fits the user needs? Or how easy it can be maintained? Maybe it’s about how well the software developers understand the code? Or how well teams can be structured around it? For us, it’s all of these and more. We refer to that as sustainability. To have sustainable software solutions, you need to make sustainable design decisions. *Sustainable design decisions* consider the sociotechnical effect of the alternatives. After designing and analyzing the alternatives, you pick the one that gives you the best sociotechnical tradeoff with the information available. You create a feedback loop in your design process to improve it along the way. Over time, you’ll find yourself making decisions in a similar way. This is when your decisions become sustainable.[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)

It’s important to understand that designing software isn’t a single decision that you have to make. It’s a series of smaller decisions that push your design in a certain direction, which becomes the solution. Decision-making is a subpart of the bigger problem-solving process. When you’re generating alternative designs, you’re solving the problem. Once you have a few alternatives, you analyze them and pick the one with the best tradeoff, which is decision-making. You need decision-making to make sustainable design decisions. This means you have to set up a decision-making process, and this process requires refinement:

-  How are we making decisions, autocratic or democratic?
-  What do we need to look out for?
-  How are we creating buy-in?
-  What are the relevant factors for us to base our decision-making style on?
-  Who can make decisions?
-  What do we do when not everyone is on board?

All of these are relevant questions that need to be addressed in your decision-making process. We’ll now d[](/book/collaborative-software-design/chapter-9/)ig a bit deeper into those questions.[](/book/collaborative-software-design/chapter-9/)

## 9.2 Decision-making styles and levels of buy-in

The decision-making process heavily affects the outcomes and the software design. Are we making decisions in isolation or together with a bigger group? How much space is there to provide input, feedback, and alternative suggestions to proposed decisions? These are complex questions to answer, and doing that consciously is crucial for sustainable design decisions that consider the sociotechnical effect of the alternatives. Decision-making style and levels of buy-in are aspects of the decision-making process that should be considered early on. This section will elaborate on two main decision-making styles, autocratic and democratic, and the levels of buy[](/book/collaborative-software-design/chapter-9/)-in that are related to these styles. [](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)

### 9.2.1 Autocracy vs. democracy

Decisions are crucial, and so is the style of decision-making. Both affect software design, and it’s important to understand how they do so. There are many different decision-making styles, but in this section, we’ll zoom in on two of them: *autocratic* (one person decides) and *democratic* (the entire group decides). [](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)

As mentioned in section 9.1, every decision involves a decision-maker, which is the person that has the authority and permission to allocate the resources when an alternative has been chosen. This means that both in democratic and autocratic decision-making, there is one decision-maker who has the “decision rights.” When it comes to these two different decision-making styles, the important difference is that with democratic decision-making, the decision-maker defers this right to a group of people, which doesn’t happen in autocratic decision-making.

Both styles are effective in different contexts, and they can help you think about communication strategies as you dive into a situation. When you make an autocratic decision, you’ll communicate differently than when you want to make a democratic decision—or hopefully you will. When a decision-making style matches the communication style, it helps group members understand their role and the influence they have on a decision, which reduces conflict and resistance. This also goes the other way, of course: when the decision-making style doesn’t match the communication style, it will lead to confusion, frustration, and potential conflict. In this section, we’ll dive into examples of both situations. Before we go there, let’s explore a little further on the difference between de[](/book/collaborative-software-design/chapter-9/)mocratic decisions and autocratic decisions.

#### Autocratic decision-making

Autocratic decision-making involves one person being in control and responsible for a decision. This means that there is no larger group involved or consulted in the decision-making, or, if there is, it’s to a very minimal extent. There is a very strong top-down approach in this decision-making style. An example here is an architect making all architectural design decisions and then handing those over to the development team who is responsible for implementation. None of the team members were involved with or consulted about the architectural choices, and their input isn’t included in the final decisions. [](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)

This autocratic decision-making style has both advantages and disadvantages, and its effectiveness depends on context. Following are some of the main advantages of autocratic decision-making we see are:

-  *Autocratic decision-making is fast decision-making.* When there is no bigger group involved and/or consulted, it takes less time to come to a decision. Decisions are made based on personal knowledge, experience, and perceptions of that particular situation. There is no time spent on discussing and defending the decision before it’s made, which saves a lot of time and potential money.
-  *Autocratic decision-making increases clarity around expectations.* When done right, the person making the final decisions will communicate clear expectations around what needs to be done, which means little to no confusion. The decision is based on personal knowledge, vision, and experience, which makes it less of a compromise and more straightforward. There is more clarity on who should be doing what, and people understand better what is expected of them.
-  *Autocratic decision-making lowers ambiguity.* The less people are involved in a decision, the less room there is for ambiguity, interpretation, and compromising. There is an obvious chain of command, and structure and direction are clear.

Following are the main disadvantages of solely autocratic decision-making:

-  *Autocratic decision-making neglects the wisdom of the group.* The bigger group holds a lot of wisdom and knowledge that would be valuable to make a decision. This combined wisdom can account for a higher quality decision. When making decisions in an autocratic way, that wisdom isn’t included, which means you’re potentially not making the best decision.
-  *Autocratic decision-making will most likely not lead to sustainable decisions.* Because not everyone is included in the decision, this can lead to resistance, meaning it can also trigger the resistance line discussed in chapter 8. If you aren’t managing the resistance line, it will increase resistant behavior and decrease buy-in even more. In addition, autocratic decisions often lack feedback loops, which can fuel the resistance line.
-  *Autocratic decision-making can decrease creativity.* Not being involved in a decision and getting clear instructions and expectations may vanish all forms of creativity. People might feel there is no room for them to think about alternative solutions, so they might not even try. Killing this creativity won’t lead to the desired outcome because you’re missing out on a lot of valuable input.
-  *Autocratic decision-making can negatively affect morale.* It can lead to distrust, resistance, and inefficiency, especially when people aren’t on board with the decision. People might feel like their input isn’t valuable, and they will start doing only the bare minimum to get the job done[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/). This won’t bring you high-quality results.

#### Democratic decision-making

In contrast to autocratic decision-making, democratic decision-making is more about shared responsibility and decision-making. As mentioned, there is still one person who has the decision right, but here, it’s deferred to a group of people. An example of democratic decision-making is an architect working together with all stakeholders on models, designs, and implementations of architectural decisions. Everyone involved needs to be on board with the decisions and be able to provide input, feedback, and perspectives to the decisions. [](/book/collaborative-software-design/chapter-9/)

Just like autocratic decision-making, democratic decision-making has both advantages and disadvantages, and effectiveness depends on context. Following are some of the main advantages of democratic decision-making:

-  *Democratic decision-making leads to commitment, participation, and engagement of group members.* Because everyone affected by the decision was included in the decision, people will feel more valued and willing to support the decision. People will have a stake in the success of the decision because they feel part of that decision. In other words, democratic decision-making will most likely lead to sustainable decisions because everyone was included and is on board with that decision.
-  *Democratic decision-making provides an opportunity to include the wisdom of the entire group.* This will create a shared sense of ownership and responsibility for the decision and making it into a reality.
-  *Democratic decision-making can positively affect morale.* Autonomy, creativity, commitment, and engagement as a result of being included in the decision can lead to higher satisfaction within groups. This can help people go an extra mile instead of doing the bare minimum for what’s needed.

Following are the main disadvantages of solely democratic decision-making:[](/book/collaborative-software-design/chapter-9/)

-  *Democratic decision-making can be a slow, time-consuming process.* Including everyone in a decision means you have to allocate time to consult every relevant stakeholder and domain expert. Properly creating a shared understanding about the decision at hand, what is asked from group members, how their input will be included, and the wisdom of the group members themselves can take a lot of time.
-  *Involving the right stakeholders can be challenging.* Who needs to be involved in which decision? Who decides which people get to be involved? Who decides which people have the right skills, expertise, and input to contribute to a decision? This can be very challenging when there is no full clarity on roles and/or context. When you don’t include the right people, you’re missing out on valuable wisdom after all, which is exactly what you want to avoid with this decision-making style.
-  *Democratic decision-making can increase ambiguity.* The more people are involved in a decision, the more mental models, assumptions, and interpretations are involved in that decision. This can increase ambiguity when it comes to language, meaning, and understanding. Managing and facilitating [](/book/collaborative-software-design/chapter-9/)this ambiguity is complex and time-consuming.

#### Autocratic or democratic, that’s the question

With this elaboration on the two styles, you might wonder which decision-making style is better. When it comes to making effective decisions, should you use autocratic or democratic decision-making? Our opinion—which might not be a surprise—is that it depends. We believe this isn’t an either/or situation but a both/and situation. Depending on the context, you have to decide which decision-making style is most suitable. It may even mean you have to go back and forth between the styles depending on the context and decisions that need to be made. [](/book/collaborative-software-design/chapter-9/)

Which style is best suitable in a certain situation depends on factors such as time, money, effect, deadlines, and pressure. If deadlines are approaching fast, and a project is already heavily over budget, autocratic decision-making might be more effective. At the same time, autocratic decisions can kick-start the resistance line, depending on how that autocratic decision was framed and made.

When you’re in a situation where decisions will have a big effect on a large group, and everyone agrees they need to spend significant time and money gathering input and commitment, go with democratic decision-making. In that last case, be sure to get a facilitator that can lead conversations and the decision-making process.

Let’s illustrate this with an example we’ve encountered multiple times: deciding which technology to use. This decision has quite an effect and depends on several factors. Following the company strategy, the development team of this company needed to grow. They were aiming to hire a significant number of new employees to realize the technological goals the company envisioned. This also meant that the existing team was facing some changes in structure, way of working, and preferred technologies. After all, if you want to attract and recruit a lot of new people, you have to match market trends when it comes to technologies. Using a rare technology will make recruitment extremely challenging. In other words, it’s not about choosing the best technology from a technical point of view, but about choosing what’s best for the team and company. A classic sociotechnical decision needs to be made.

So, the architect was left with a decision to make: given the goals and strategy we set out, which technology are we going to use? Factors such as effect, pressure, and deadlines were considered, and eventually it turned out to be a partly democratic and partly autocratic decision. Let us explain how that works.

[](/book/collaborative-software-design/chapter-9/)The architect could have made a fully autocratic decision here: “This is the technology we’re going to use.” However, this might lead to resistance within the team and might not be the best technology for the team. On the other hand, the pressure was on, and deadlines were approaching fast. The architect decided to create a proposal for the team with a list of two choices. The alternatives were based on the growth ambitions of the company, market trends, and recruitment opportunities, as well as existing knowledge within the current team. These alternatives were discussed with the team, and the architect clearly explained how the presented alternatives were arrived at. It was now up to the team to decide which of these alternatives was the best fit with the team. The architect gave autocratic boundaries by providing alternatives to choose from, and the team was able to make a democratic decision within these boundaries about what would be best for the team.

This is a good example of how you can consider several factors when choosing a decision-making style. Note that it doesn’t have to be an either/or choice. You can mix autocratic and democratic when that suits the needs of the group. What went well here was the transparency around the decision-making process by setting clear boundaries and being straightforward about where the group could influence the decision.

To summarize, when a decision or decisions need to be made, analyze the situation based on relevant factors such as time and effect, and then choose your decision-making style. The important thing is to be clear about what you ended up choosing. It’s very frustrating when it seems like decisions are being made in a democratic way, but, in reality, there is one person making all final decisions in an autocratic way. People need to know and have clarity about their role and the level of influence they have on decisions. We[](/book/collaborative-software-design/chapter-9/)’ll dive into this further in the next section.[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)

### 9.2.2 Creating buy-in on decisions

All stakeholders need to actively support and participate in implementing the course of action following a decision. We call this creating *buy-in*. If you don’t put effort into creating this buy-in, you can stumble upon resistance in the process. You want this buy-in to make sure people are on board and willing and able to do what’s required of them in the actions following a decision. If people aren’t given any buy-in, they might start to slow down by asking a lot of questions and questioning the decision in general, for example. Other forms of resistance could be people refraining from actions that need to be taken, making regular sarcastic jokes, and gossiping about[](/book/collaborative-software-design/chapter-9/) the decision and potentially about stakeholders. [](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)

#### Levels of buy-in

One of the main reasons people start resisting is related to the way the buy-in is being framed. Often, decision-makers feel uncomfortable putting a decision in the right level. If these levels are applied in a right and consistent manner, it will help make sustainable decisions. In the Lewis Deep Democracy method,[3](/book/collaborative-software-design/chapter-9/footnote-001) there are four levels of buy-in that you can create when making a decision:[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)

-  *Idea*—You have an idea, but nothing has been done yet. If the idea is ill received, you’re more than happy to let it go. It’s an open question, and everyone is allowed to influence it. You’re looking for a group of people who want to help you generate and analyze options.
-  *Suggestion*—You have clear intentions, you’ve investigated options, and you have a preference on one of the options, but other insights are welcome.
-  *Proposal*—You have a concrete worked-out plan for an option, and only serious objections can influence the decision.
-  *Command*—You have made the decision and want to inform others of the decision and their responsibilities.

It’s important to make clear to the stakeholders which level of buy-in they have. Nothing is more frustrating for people than when you frame the decision in a different buy-in than it actually is. The most common misframing happens around commands; the person in charge of the decision doesn’t always feel comfortable to frame a command as it is. Commands can have a negative association and lead to resistance as people may feel they have nothing to say or add to a decision.

Let’s illustrate this misframing with an example. A few companies back for one of the coauthors, the team lead wanted to introduce more homogeneity in the codebase by introducing a code formatter. They made a suggestion: “We’ll start using tool *xyz* under the default settings; what do you think? I would love to hear your thoughts on code formatting and what you think is the best way to do it.” Everyone was very interested of course, including the coauthor. They created their optimal settings and scheduled a meeting with the team lead. During the meeting, it became very clear that the decision to use the tool under default settings had been made, and nothing would change their mind. The coauthor in question became annoyed and frustrated toward the team lead. The coauthor understood and agreed with the team lead’s decision when listening to their arguments, but, at the same time, they felt resentment toward the team lead because they had wasted the coauthor’s time by pretending that this was anything other than a command. So, the coauthor didn’t use the new formatter, and they weren’t the only one with a similar reaction.

Imagine the team lead had said this: “I want to improve the homogeneity in the codebase. We’ll start using the formatter xyz. I want to avoid endless discussions on what the best settings are, so we’ll use the default settings. It will take some time getting used to the new code style, so in nine months, we’ll evaluate if the default settings aren’t causing readability problems for the team. Is there anything you need to go along with this decision?” Framing it this way, the majority of people would probably have agreed with it, and used that tool for nine months under default settings. By that time, they would have adapted to the new style of the code and been able to evaluate the readability. But because the team lead had presented this as a suggestion, they had created resentment that resulted in resistance (not using the tool) and were[](/book/collaborative-software-design/chapter-9/) unable to achieve their goal of improving homogeneity.

#### Levels of buy-in and decision-making style

[](/book/collaborative-software-design/chapter-9/)These four levels of buy-in relate to autocratic and democratic decision-making styles we discussed in section 9.2.1. There isn’t a one-to-one relationship between the styles and the levels, but they do correlate with each other. Autocratic decision-making creates little buy-in, where democratic decision-making creates lots of buy-in. Autocratic implies more commands because decisions have been made by one person and it’s more about informing others about that decision than including their feedback and/or input. Democratic implies mainly ideas because it’s about open questions, and everyone is allowed to provide input before decisions are made. Figure 9.4 visualizes the lev[](/book/collaborative-software-design/chapter-9/)els of buy-in related to the decision-making style. [](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)

It’s usually best to define the decision-making style first: Does this decision require autocratic or democratic decision-making, and why? Consider relevant factors, and decide what best fits the situation at hand. This will guide you in the levels of buy-in. Whatever you decide, always be clear about that level. Making it explicit in terms of what people can expect and what you expect of others will remove ambiguity and prevent frustration and resistance.

Another concept that we need to take into consideration when talking about democratic decision-making and creating buy-in is *giving consent*. Giving consent means that a smaller group of people is given consent to make a decision. This foundational step is crucial for setting clear expectations and boundaries in decision-making. The entire group decides collectively that a subgroup of people can make the decision. This is especially helpful from an efficiency perspective. Some design decisions can be picked up by a subgroup after being given consent, and they can bring that decision back to the group. Doing this still creates relatively hig[](/book/collaborative-software-design/chapter-9/)h buy-in, as it’s a form of democratic decision-making. [](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)

![Figure 9.4 Levels of buy-in plotted on the spectrum of democratic and autocratic decision-making styles](https://drek4537l1klr.cloudfront.net/baas/Figures/CH09_F04_Baas.png)

### 9.2.3 Buy-in on software design decisions

Software design decisions can also require buy-in from stakeholders. One way to create that buy-in is collaborative modeling. All relevant stakeholders can work on a shared model that includes all input and perspectives that are needed to make the best decisions possible. Using collaborative modeling won’t automatically create buy-in for the stakeholders. With collaborative modeling, you visualize the proposed solutions of the stakeholders. Because all the stakeholders that need buy-in are in the room, you make it easier to evaluate those solutions and gather feedback on them. [](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)

At the end of a session, you can still pick a solution that not everyone is on board with. This is why it’s important to ask what the stakeholder needs to go along with the solution that they didn’t decide on and see what you can add to the decision. Again, clarity is crucial here.

##### GUIDING HEURISTIC

After a decision is made, always ask the following: “We’re going with this decision, so what do you need to go along with it?” And decide what can be added in the decision to get these people to go along with it.

This is a very powerful question that is hardly ever being asked. From our experience, this question can lead to increased buy-in because it provides an opportunity for people to be heard and express concerns. It won’t change the course of the decision, but it will clarify what individuals need to go along with that decision. Often, we find these needs aren’t huge and impossible, but rather practical and realistic needs that can be added to the decision rather easily. For example, a need to create a clear storyline and communication that can be shared with other stakeholders within the organization, a need to have regular check-in moments to stay aligned and focused, or a need to get a one-on-one meeting with the architects to ask clarifying questions and better understand the decision.

We like to weave in the Lewis Deep Democracy method[4](/book/collaborative-software-design/chapter-9/footnote-000) in our facilitation to come to consensus-driven, sustainable decisions. Our biggest motivation for doing so is that after the decision is made, there will be less resistance and hassle because all relevant stakeholders were involved in that decision. When we have plenty of time and can make fully democratic decisions, we include all the steps. If time is short or we lack buy-in from the decision maker, we might only incorporate step 4. Remember, we prefer to weave this method into our flow, adapting it to our facilitation style without always explicitly mentioning Deep Democracy. It’s not about strictly following the steps but about the outcome of reaching sustainable design decisions. The Lewis Deep Democracy method describes five steps for sustainable decision-making:[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)

1.  *Gain all points of view.* The first step is to make sure that everyone has the opportunity to express their opinion on the decision that needs to be made. It’s up to you as a facilitator to create the space to make this possible.
1.  *Find the unspoken alternative point of view.* Have you ever been in a meeting where everyone just agrees? Yeah, so have we. At least we thought everyone agreed at the time. However, more often than not, the disagreement just surfaces much later. That is normal because not everyone feels comfortable speaking up. It’s better though for disagreement to surface as fast as possible, so go hunting for it.
1.  *Spread the alternative point of view.* When somebody is brave enough to speak up when they disagree (and even when they have no problem disagreeing), it’s important that they don’t feel alone in their disagreement. That is what step 3 is all about: spreading the disagreement from a single person to more by making their point of view relatable. After going through several rounds of steps 1 to 3, it’s time to vote and see how the group is divided. We only do this if we believe one option will likely have a majority or if we sense that taking a stance might surface more unspoken perspectives. Clearly present all alternatives and remind everyone that they can only vote for one. Also, let them know that an option needs more than half the votes to gain a majority. If no majority is reached, we return to steps 1 to 3, repeating this process up to three times before moving on to step 5.
1.  *Add the perspective of the minority group to gain a unanimous vote.* Excellent, we have a majority vote, and the decision has been made. Wrong! It’s now time to focus on the minority. Ignoring the minority is a good way to create resistance or push a conflict into the shadows until it comes out as demons. If 40% disagrees with what was chosen, we have a majority *and* a problem. Even if just a single person disagrees, it’s better to understand where they are coming from and resolve the disagreement before it causes conflict down the line. Ask them what it will take to come along with the chosen option. Incorporate the minority needs into the decision, and then vote on each one until you reach unanimous agreement on the improved decision that now includes the needs of the minority.
1.  *No unanimous vote? Go Fishing!* The last step is optional. When you can’t reach a unanimous vote, it’s a sign that there are still things left to be said before everyone can agree. It’s time to start fishing for those unspoken alternative points of view again.

In section 9.3, we’ll elaborate on how weaved in these steps in our facilitation by describing one of the sessions we had at BigScreen.[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)

## 9.3 Facilitating sustainable design decisions

In this section, we’ll return to the end of the design EventStorming we talked about in chapter 8. Then, we’ll go into the domain message flow modeling session conducted after the design EventStorming discussed in the previous chapter and briefly mentioned in chapter 3. From that design EventStorming, we developed three potential bounded context design alternatives. Although we facilitated conflict resolution within the group during the design EventStorming session, resolving the dysfunctional conflict between Jack and Rose, they still could not reach a consensus on the optimal approach for the bounded context design. The conflict had become functional, enabling Jack and Rose to listen to each other. Nevertheless, if we don’t carefully facilitate [](/book/collaborative-software-design/chapter-9/)the group’s decision-m[](/book/collaborative-software-design/chapter-9/)aking process, we could quickly reenter the -isms conflict stage.[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)

### 9.3.1 Moving toward a majority vote

In chapter 8, we already demonstrated how we weaved in the first three steps of the Lewis Deep Democracy method. However, we didn’t label them as such. Now that you know what these steps are, we want to show you what those steps look like during collaborative modeling. But first, let’s review a session from a two-day workshop at another company to illustrate what can happen when minority needs aren’t included in the decision-making process.[](/book/collaborative-software-design/chapter-9/)

#### Facilitating the first 3 steps of the method

The workshop was with a variety of stakeholders and two software teams to break down their current BBoM system. Our approach involved using EventStorming and domain message flow modeling. We consistently improved our alternative design options for possible bounded contexts throughout the session until we had a few distinct designs. By using this method, we were able to gather the necessary information needed to make a well-informed design decision. [](/book/collaborative-software-design/chapter-9/)

EventStorming and other collaboration tools are great because they prompt you to weave in step 1 to 3 almost unconsciously. The points of view you’re looking for are the mental models of the participants they wrote down on stickies at the start. Then by asking questions such as the following about events that are contradictory, you dig deeper for alternative points of view: “You said you always pick all the items first before assembling them, but the night shift mentioned partial assembly due to stock shortage. Can you think of a situation in which the day shift partially assembled something?”

To discover which of the designs of the session was the best option for stakeholders and teams, we gathered everyone’s opinions and wrote them down per design. We used the lilac-colored sticky notes for all the cons and green for the pros, and added the tradeoffs for both designs. This is again the first three steps of the Deep Democracy method.

When we were altering a design, we tried to spread the alternative point view by asking questions on the adaptation:

-  Why do you want to change this design?
-  Who agrees this is an important need for the design?
-  Is there anyone who thinks there is a similar need not present in the design right now?

[](/book/collaborative-software-design/chapter-9/)That is what step 3 means: making someone’s opinion relatable. When someone is expressing a less popular opinion, they often feel uncomfortable or alone in their point of view. This triggers the resistance line that we want to avoid.

As you may have noticed, this is an iterative process. When you’re designing, you can’t think: “Okay, so now first step 1, then step 2, and so on.” Designing your software system is iterative, so we have to adapt the method. As a facilitator, we have to make sure that steps 1–3 all get enough attention and are included in your collaborative modeling session.

At some point, it was time to pick one of the designs. That is when we vote. We asked the group how comfortable they were in picking one of the designs, and everyone felt confident enough to vote. Out of the 14 participants, a majority of 9 voted for one of the designs, and we all agreed that this was the best option for the teams.

We were excited to move forward with it—or so we thought. When the team started to implement the design in code, we noticed a lot of merge requests with comments popping up such as “This isn’t what we decided” and “This is the better route to go, let’s stay agile and adapt.” It was clear to us from the resistance behavior we observed that not everyone was on the same page when it came to the design decision we had made. So, even if you analyze the decision correctly, find alternatives, gain all the information we need for the decision, and determine all preferences to the group, you can have a minority who are stuck with a decision they didn’t make. For them, that feels similar to an autocratic decision, and that will definitely trigger the resistance line.

##### GUIDING HEURISTIC

Ask people who didn’t vote for the majority alternative what it takes for them to go along with the decision.

We forgot to ask the five people who didn’t vote for that design what it would take for them to go along with the decision. We forgot step 4, getting to a unanimous vote! This is something that happens a lot in companies. The majority wins, and the minority is simply neglected. That is a recipe for conflict. As mentioned, it’s important to ask the group that voted against the design why they disagreed and what they need to do to go along with the majority. We want to include those needs into the decision and vote again. That vote has to [](/book/collaborative-software-design/chapter-9/)be unanimous because we want everyone to go along with the decision.[](/book/collaborative-software-design/chapter-9/)

#### Facilitating role fluidity

Now let’s go back to the design EventStorming session from the previous chapter and see how we did better at BigScreen. From the design EventStorming, we ended up with two alternative bounded context d[](/book/collaborative-software-design/chapter-9/)esigns: Back-Office Separated (as the left decision) and Payments Separated (as the right decision) (figure 9.5).[](/book/collaborative-software-design/chapter-9/)

![Figure 9.5 The bounded context designs after the design EventStorming. Both designs started to evolve and include wisdom from the group. The left design, Back-Office Separated, started to split Visitor Reservations from Ticketing to choreograph a reservation from a paid ticket. Payments Separated, on the right, started to move toward more orchestration where Ticketing goes to Payments to finalize a ticket.](https://drek4537l1klr.cloudfront.net/baas/Figures/CH09_F05_Baas.png)

[](/book/collaborative-software-design/chapter-9/)Next, we used an adaptation of the Small Group Diverge and Converge collaboration style (chapter 4) to analyze the two designs in figure 9.5. We did this to create understanding between the two camps of what a person feels they need that pushes their preference to one of those two designs. We paired up participants so they could interview each other on the problems their preferred design solved. To form pairs, we asked participants to choose their preferred design and then partner with someone who favored the opposing design. We wanted to create relatability and move away from two sides of the conflict.

The interviewer’s task was to extract the underlying design heuristic from the conversation. They documented [](/book/collaborative-software-design/chapter-9/)the design heuristics on index cards, following Rebecca Wirfs-Brock’s Question-Heuristic-Answer (QHE) format ([https://wirfs-brock.com/rebecca/blog/2019/04/13/writing/](https://wirfs-brock.com/rebecca/blog/2019/04/13/writing/)). The problem the interviewee mentioned was turned into a question on the index card, and the heuristic was extracted from the way the design solved that problem. Exercises like these are beneficial for two reasons:[](/book/collaborative-software-design/chapter-9/)

-  They help to make design decisions more tangible by extracting key heuristics.
-  They promote role fluidity by encouraging active listening and understanding of each other’s needs.

After two rounds, we asked everyone to group the QHE card by the design it was extracted from. We then let everyone read all the cards and asked them what was something that surprised them or that they didn’t expect. On both sides, there was the following question: “How can we split up our teams?” As you might have noticed before, the current development team consists of 15 people, and they are getting in each other’s way when they code.

##### GUIDING HEURISTIC

Begin by establishing a shared understanding of the problem or need that requires solving before moving on to discussing potential solutions.

Both teams had the same question using the same design as mentioned, but they used them in different ways. As depicted in figure 9.5, the left design isolated the planning and scheduling, while the right design singled out the payments. Once it was clear that everyone shared similar requirements, this facilitated stronger connections among the group members. Consequently, a new [](/book/collaborative-software-design/chapter-9/)kind of discussion emerged, focusing on each design’s bounded context.

#### Facilitation to a unanimous vote

[](/book/collaborative-software-design/chapter-9/)This discussion began with a question to Jack’s group about their rationale for setting payments as an independent domain. Jack explained that his work often involved conversations with colleagues from operations and finance to determine the most effective way to manage payments, making these departments key stakeholders in the payment domain. He further clarified that these discussions were typically initiated in response to problems raised by the operations teams regarding customer complaints about payment failures.[](/book/collaborative-software-design/chapter-9/)

##### DESIGN HEURISTIC

Align bounded context around parts of the domain where different domain expertise is present. With domain expertise, we don’t mean specific people but different knowledge and skills.

In many instan ces, these problems were mainly bugs caused by modifications in the rules for seat allocation, as requested by the finance team for optimizing revenue. For a while, finance wanted to change the way they calculated ticket prices, and the easiest way to experiment with that was making changes to the price calculation for seat allocations. These changes could lead to unexpected responses from the system. As a result, payment processes might fail due to these bugs. By setting Payments as a separate boundary, the rules for seat allocation could be disassociated from executing the payments.

During a discussion following Jack’s presentation, Caledon from the left design team suggested breaking the payment function into two parts: seat allocation and payment processing, as shown in figure 9.6. He reasoned that this division would make more sense, as in paying and pricing are two distinct business problems, needing both their own bounded context to solve those in. He came up with the idea because of the term he had heard Jack use, payments and pricing constraints. Thus, Caledon suggested, also shown in figure 9.6, to rename the Payments domain to Pricing and Payments. Jack expressed his reser[](/book/collaborative-software-design/chapter-9/)vations, unsure if a more detailed division might complicate things.

![Figure 9.6 Caledon’s suggestion to further split up the Payments bounded context into two and renaming the Payments domain to Pricing and Payments](https://drek4537l1klr.cloudfront.net/baas/Figures/CH09_F06_Baas.png)

[](/book/collaborative-software-design/chapter-9/)The team agreed to vote on the matter. The team was faced with two options: maintain the current design or adopt Caledon’s proposed alteration to the design. Everyone was allowed to vote once, and majority rule was to be implemented. The team understood and proceeded with the vote. First, we asked who was in favor of option 1, maintaining the current design. Three participants, including Jack, raised their hands in agreement. Next, those in favor of the second option, further division, were asked to vote. Fifteen participants voted for this choice.

As a result, the team chose to further divide the domain Payments as Caledon had suggested. We asked the essential question—What would it take for them to go along?—to those who hadn’t voted for this decision. Jack was the first to respond. While not against the choice, Jack felt that if they were considering further divisions, it was only fair to examine the Back-Office Separated design for potential divisions too.

This example highlights that individuals might not opt for something they prefer due to some underlying problem. In Jack’s case, it was the fact that his design had been improved, but Rose’s design hadn’t been given the same exploration. It had nothing to do with the improvement itself. It’s good to remember that these underlying problems may not be evident at the time of decision-making, only surfacing after a choice has been made. Collaborative modeling sessions often favor the extroverted, quick decision-makers, leaving the more analytical thinkers to catch up during voting or even after the session. This is a broad generalization, but it illustrates why individuals may cling to the status quo.

By asking people what would convince them to go along with a decision, we can glean more information and better understand their preferences. Th[](/book/collaborative-software-design/chapter-9/)is is a valuable trick for making more inclusive and informed choices.[](/book/collaborative-software-design/chapter-9/)

#### Switching collaborative modeling tools to gain more insights

Rose, who had initially proposed the design, also disagreed with the decision. We asked her what it would take for her to go along with the decision, and she hesitated. As facilitators, we must be cautious not to make hasty assumptions and instead use our active listening skills to create a supportive environment. It’s vital to exercise situational awareness, especially when contentious topics arise. We risk falling back into conflict and encountering resistant behavior, particularly from Rose, if we don’t approach the situation delicately.[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)

After a brief pause, Rose confessed she was a bit unsure if there is anything that she needs to go along. We could have easily brushed this off and moved forward, but we felt a tension—which could mean more shadows and that we hadn’t provided a safe space for her to genuinely express her needs. When we reflected on that tension we remembered that the entire session she was very vocal about her design and about what was going wrong, and now she is quiet. We might have observed edge behavior, and it’s up to us to help her at this point express what she needs to say. So, we respond with, “You are a bit unsure?” and let the silence sink in again.

Rose then answered that she feared that further dividing the bounded context would require a significant increase in communication. When asked why she saw this as a problem, she explained that more communication could overcomplicate things. She and the team were used to a single-model approach that facilitated consistent transactions and simplified changes due to its singular codebase. Splitting into separate bounded contexts, she argued, could make it difficult to adapt to unforeseen changes, necessitating alterations in both boundaries and their intercommunication. And not having the experience to write code in that way makes it even more difficult and a risk for the project.

You might ask yourself now, why are we putting so much effort into the dialogue with Rose despite having already reached a decision. This dialogue was valuable to the group as it provided additional insights into the group’s dynamics and preferences. We turned on the flashlight and let shadows out in the consciousness of the group. Understanding Rose’s perspective might influence our current decision and is far more cost-effective at this stage than during implementation. Moreover, this dialogue reassured Rose that her views were acknowledged and valued. This attentiveness to individual needs is integral to sustainable decision-making.

Continuing the dialogue, Rose expressed concerns about increased complexity due to further splitting. In our role as software designers, this problem presented a design challenge we needed to address. Designing bounded contexts requires us to consider essential complexity, which we can’t reduce, only manage. Smaller bounded contexts are easier to manage because they contain less of this essential domain complexity, but the essential complexity increases between bounded contexts. To fully understand the effect of the size of our designed bounded context, we can use domain message flow modeling. This is why we repeatedly emphasize the need for using multiple collaborative modeling tools; each offers a unique perspective on the problem at hand.

Our initial plan for the next session was to use Example Mapping on one of the bounded contexts, with domain message flow modeling later in the process. However, we felt we needed to address Rose’s concerns first, mostly because if Rose has this concern, role theory (chapter 8) teaches us that others will have that concern as well. So, when we asked the group who else had the worry that the communication between bounded contexts can become too complex, most raised their hands. With the group’s approval, we proposed conducting domain message flow modeling in the next session, postponing Example Mapping to a later date. We would model both options for the right group’s design and do the same for the left design as if similar concerns arose.

Here, you can see us use a more autocratic decision-making style. We did a proposal in this case to address Rose’s worries and tried to make it more comfortable for her to get along with the decision. It’s important to notice that we tried to include everyone’s needs that we knew so far. That is why we used a proposal, so if something might be in the unconscious of the group that we don’t know of, we can adjust if needed. Autocratic decision-making isn’t bad, as long as you include the wisdom of the group and connect it to their needs!

When we asked if anyone disagreed with our proposal or if they needed anything else to support it, no one in the group disagreed or needed anything further. We then moved on to the left des[](/book/collaborative-software-design/chapter-9/)ign, which was also divided into two options. That division on the left side also improved the option Caledon gave for the right design, as shown in Figure 9.7.[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)

![Figure 9.7 All bounded context design that we ended up with at the end of our design EventStorming session. The left and the right design both offer another alternative that further split up the bounded context from the domain split.](https://drek4537l1klr.cloudfront.net/baas/Figures/CH09_F07_Baas.png)

### 9.3.2 Go fishing!

So far, we’ve managed to achieve unanimous agreement on the choices or decisions we need to make. But what if that’s not possible? What if there are more than two options without one having the majority? Or what happens when we don’t get a unanimous vote for the needs we added from the minority? We encountered that exact scenario in the follow-up session we did with domain message flow modeling.[](/book/collaborative-software-design/chapter-9/)

During that session we split up into three groups, each doing a domain message flow modeling on one of the designs from figure 9.7 with the same use case scenario: purchasing tickets when they are available. We only did three teams because both left designs will look similar doing that use case. Y[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)ou can see the first outcome of the domain message flow in figure 9.8.

![Figure 9.8 The outcomes from each group for a domain message flow modeling with the use case purchasing a ticket when available. We chose the same use case because it gives us insights to compare each design. Generally, you would model multiple different scenarios to show what actually would happen for that design in each scenario.](https://drek4537l1klr.cloudfront.net/baas/Figures/CH09_F08a_Baas.png)

We asked each group to extract their design heuristics, and one competing heuristics between the designs emerged: orchestration versus choreography ([https://mng.bz/VxDx](https://mng.bz/VxDx)), which are two ways you could implement the business process of ticket purchasing.

The left design employed choreography. Here, the visitor reservations system broadcasts an event that the ticketing system recognizes, prompting it to create tickets and send an email to the customer. In this setup, the Visitor Reservations bounded context has no knowledge of the Ticketing bounded context, leading to a loosely coupled architecture. However, this design doesn’t have centralized management for the ticket purchase process. The process is distributed between the two bounded contexts, which would necessitate some form of monitoring or another bounded context to keep track of the status for each ticket purchase.

On the other hand, the right design used orchestration in the ticket purchasing process. The Ticketing bounded context manages the entire process. This is easier to maintain, but when the Ticketing bounded context is offline, the whole process halts. It also results in more interdependence between each bounded context because the ticketing system needs to be aware of the other context.

As the group engaged in a discussion about the designs, two main topics were addressed. The first topic was about the differences in splitting the business process into subprocesses and placing them in separate boundaries. The majority of the group felt the left design was more cohesive because the key business process of purchasing a ticket was confined to specific subprocesses and, thus, teams, and it didn’t cross boundaries.

The second topic revolved around the debate between choreography and orchestration. Most group members seemed to prefer orchestration over choreography. They appreciated the reactivity of choreography, but given the team’s lack of experience with reactive programming and their existing monolith’s heavy reliance on synchronous calls, the preference leaned toward orchestration. From this discussion, someone suggested revising the left design t[](/book/collaborative-software-design/chapter-9/)o use orchestration rather than choreography, as shown in figure 9.9.

![](https://drek4537l1klr.cloudfront.net/baas/Figures/CH09_F08b_Baas.png)

We like to have more than two designs because it also means the binary nature of two alternatives can greatly influence us versus them when deciding on a design. Using multiple collaborative modeling tools, extracting design heuristics, and spreading the needs that those heuristics solve will give you better dialogue because it creates a better shared understanding, more design alternatives to choose from, and less us versus them between two designs, which if you remember, we started with when we came into the company. It switched from being Rose and Jack and their designs to multiple designs that included all the wisdom the group had.[](/book/collaborative-software-design/chapter-9/)

Next, we asked the group’s confidence level in making a decision, and everyone indicated a 7+ on a scale of 1–10, signaling readiness to vote. Just as in the previous session, we initiated a voting process. With 18 participants, a majority design decision would require at least 10 votes to be selected.

In the initial round of voting, none of the designs secured a majority. The first design received six votes, the second had five votes, and the third got seven votes. This lack of a clear winner indicated that more discussion was needed for a well-informed decision to be made.

We then invited the group members to explain their votes, sparking further dialogue. As facilitators, we used active listening in the ensuing conversation, spreading the roles further within the group for them to be ready for the next voting round.

In the subsequent round, there was still no clear majority, but there was a shift in the vote distribution. The first design’s votes dropped to three, while the second and third designs received seven and eight votes, respectively. Although a majority had yet to be achieved, there was a clear signal of progress toward a consensus. So now we asked the group to really try and persuade the others until the group was ready for another vote, which ended up in a tie between design 2 and design 3, meaning the group already decided to split the domain between ticket purchasing and scheduling. But the one thing they could not agree on was orchestration versus choreography. The group was divided in two camps again!

In situations where a decision isn’t easily reached, it could be beneficial to delve deeper into the debate at hand—in this case, the choice between orchestration and choreography. As they suggest in the Lewis Deep Democracy method, it’s time to “go fishing!”[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)

There are two primary strategies for this. The simpler one is to let the entire group highlight the advantages of both sides. The second, which necessitates a more sophisticated understanding of conflict management and goes beyond the scope of this book, is to stimulate the group to critique both sides. If you’re curious about the latter method, known as “throwing arrows,” we recommend further reading or attending a training on Lewis Deep Democracy ([www.lewisdeepdemocracy.com](https://www.lewisdeepdemocracy.com)). It’s important to note, however, that we seldom resort to the latter approach. The first strategy usually facilitates the decision-making process enough, and when that isn’t the case, you might be better off with someone with a professional background in conflict facilitation.

The simpler strategy involves asking everyone in the group, even those who didn’t vote for choreography, to either talk or write down stickies about all its potential benefits. Once the discussion dwindles, we switch to the orchestration side. We then repeat the process, as the second option can sometimes spark new insights for the first. We end with a final exploration of the benefits of orchestration.

Next, we prompt the group to reflect on the discussion and identify any standout points or triggers that resonated with them, or to put it different, what hit home? After a period of reflection, we ask everyone to share their thoughts, without interruptions from the group, similar to a check-in process. Jack spoke up first and told the group that he really wanted the company to work on the newest technologies, but what hit home for him was someone saying learning and failing in smaller steps, instead of making big jumps. He then follows up that he finds it hard to accept because he doesn’t want to stay behind in his experience as a developer compared to the outside world. But he thinks it’s better to first take a small leap toward that goal, and he will put his ego aside for the company and see if he can experiment himself at home more on those technologies.

This part of go fishing makes sure to lower the waterline further, allowing individuals to display vulnerability, which can inspire others to do the same. By sharing his feelings, Jack made it safer for others to also share their feelings. Though not everyone fully participated by sharing deeper emotions, it was enough that a few did, putting on the flashlight and letting shadows come out. Once everyone who wanted to had spoken, we returned to voting. Interestingly, the third design won the majority of votes, 16 to 2. The two minority voters suggested revisiting the debate once the team gained more experience with choreography. This was agreed upon, and we proceeded with the third design.

The design heuristics applied here addressed solvable problems. But occasionally, a group might encounter unsolvable challenges, such as when to start coding or when to continue collaborative modeling. These ongoing dilemmas, known as polarities, can hinder collaborative modeling. In the next c[](/book/collaborative-software-design/chapter-9/)hapter, we’ll delve deeper into strategies for managing such polarities.[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)

## 9.4 Collaborative software design catalysts

-  Try to find the decision-maker for each decision that needs to be made during team meetings. Who has the veto power here? Who needs to approve the budget?[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)
-  When making a decision, regardless of the context you’re in, try to see if this is a reactive or a proactive decision.
-  When there is only one option (agree/disagree decision), see what other options you can come up with, and share them with the group. Even if you don’t like the options you come up with, sometimes the usefulness of an option is that it might inspire other people to come up with their own.
-  When you’re in a meeting and someone is expressing a minority point of view, try to relate to that person. Is there a similar need that you could mention so this person doesn’t feel alone in their opinion anymore?
-  If you don’t find a similar need, ask the question out loud: “Is there anyone who has a similar need? Is there anyone who can relate to what person *X* just said?”
-  When making a democratic decision during a meeting, try to get a unanimous vote. You don’t even have to make it explicit that this is what you’re trying to do. Just ask the following: “Why do you d[](/book/collaborative-software-design/chapter-9/)isagree with this option?” or “What would it take for you to go along with it?”

## 9.5 Chapter heuristics

*Guiding heuristics**[](/book/collaborative-software-design/chapter-9/)*

-  Imagine you were talking to a clairvoyant and could ask them a single piece of information about the decision you’re trying to make. What piece of information would it be?
-  After a decision is made, always ask the following: “We’re going with this decision, so what do you need to go along with it?” And decide what can be added in the decision to get these people to go along with it.
-  Ask people who didn’t vote for the majority alternative what it takes for them to go along with the decision.
-  Begin by establishing a shared understanding of the problem or need that requires solving before moving on to discussing potential solutions.

*Design* *heuristic*

-  Align bounded context around parts of the domain where there different domain expertise is present. With domain expertise, we don’t mean specific people but different knowledge and skills.

## 9.6 Further reading

-  *Foundations of Decision Analysis* by Ronald Howard and Ali Abbas (Pearson, 2015)[](/book/collaborative-software-design/chapter-9/)[](/book/collaborative-software-design/chapter-9/)
-  *Microservices Patterns: With Examples in Java* by C. Richardson (Manning, 2018)
-  *Fundamentals [](/book/collaborative-software-design/chapter-9/)of Software Architecture* by Mark Richards and Neal Ford (O’Reilly Media, 2020)

## Summary

-  A decision is a conscious, actional process involving a choice from a set of plans (alternatives), differentiating it from the automatic nature of habits.
-  Decision-making requires an irrevocable allocation of resources (time, money, or energy), representing its cost and importance, which can be quantified by potential losses from incorrect choices.
-  Resulting is a common bias where decision quality is erroneously equated with outcome quality; instead, decision quality should be evaluated based on the context and thoroughness of initial analysis rather than just the eventual result.
-  Good decision-making involves the components of information, preferences, and alternatives, managed by a designated decision-maker with the authority to allocate resources.
-  Alternatives should lead to distinct outcomes, with information gathering being crucial to influence the level of uncertainty and confidence in a decision.
-  The decision-making process evaluates preferences against available alternatives, but these preferences can be influenced by how information is presented (framing effect).
-  The decision-making process uses logic to derive a course of action, with the depth of analysis depending on the decision’s complexity, and it begins with a clear problem statement that outlines the problem to be addressed.
-  Decision-making can be reactive (responding to an event) or proactive (initiating change), with each type influencing emotional responses, preferences, and decision time frames. Collaborative modeling helps shift teams from reactive to proactive decision-making.
-  To create sustainable software solutions, a series of smaller decisions considering sociotechnical effects must be made, which requires setting up and refining a decision-making process addressing factors such as decision-making style, buy-in creation, and conflict resolution.
-  Decision-making styles, autocratic and democratic, greatly affect software design. Both styles have advantages and disadvantages, and the choice depends on the context, potentially even involving a mix of both.
-  The choice of decision-making style should consider relevant factors such as time and effect, and the decision process must be communicated clearly to avoid confusion and potential conflict.
-  Buy-in levels range from idea to command, and miscommunication of these levels can cause resistance, as seen in an example involving a software tool introduction.
-  Autocratic and democratic decision-making styles correlate with buy-in levels; Lewis Deep Democracy method supports sustainable, consensus-driven decisions, particularly in software design.[](/book/collaborative-software-design/chapter-9/)

---

[](/book/collaborative-software-design/chapter-9/)[1](/book/collaborative-software-design/chapter-9/footnote-003-backlink)   Abbas, A. E., & Howard, R. A. *Foundations of Decision Analysis*, Global Edition, E-Book, 2023. London: Pearson (p. 30).

[](/book/collaborative-software-design/chapter-9/)[2](/book/collaborative-software-design/chapter-9/footnote-002-backlink)   Richardson, C. *Microservices Patterns: With Examples in Java*, 2018. Shelter Island, NY: Manning.

[](/book/collaborative-software-design/chapter-9/)[3](/book/collaborative-software-design/chapter-9/footnote-001-backlink)   Kramer, J. *Deep Democracy-De wijsheid van de minderheid* (“The Wisdom of the Minority”), 2019. Ashland, OH: Management Impact Publishing.

[](/book/collaborative-software-design/chapter-9/)[4](/book/collaborative-software-design/chapter-9/footnote-000-backlink)   Kramer, *Deep Democracy*.
