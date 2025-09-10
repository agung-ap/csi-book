# 11 [](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)Communicating and documenting decisions

### This chapter covers

- Formalizing decisions using Pros-Cons-and-Fixes lists and Architectural Decision Records
- Spreading knowledge through the company
- Approaching your modeling process as a whirlpool of feedback loops

In chapter 9, we touched on the decision process and creating sustainability in that process. What comes after is communicating and documenting those decisions. In this chapter, we’ll talk about two documentation tools that will help you communicate decisions to your future team. We’ll also discuss how to spread the decision through the company so that everybody is informed in the right way. Lastly, we mentioned that you can’t make a decision and blindly follow the course of action that comes with it. The context in which you make decisions changes as you uncover information you didn’t have while making the decisions, which is why you need to keep your design decisions aliv[](/book/collaborative-software-design/chapter-11/)e.

## 11.1 Formalizing a decision

If you’ve ever tried to understand a previous decision made by someone else, you know how hard it can be to understand what others were thinking when they made it. An important part of any decision is formalizing it, so that our future selves have access to the decision. There are two things you need to do to formalize a decision:[](/book/collaborative-software-design/chapter-11/)

-  Find the consequences of the chosen alternative.
-  Capture the decision on paper.

Let’s start by looking at finding the consequenc[](/book/collaborative-software-design/chapter-11/)es.[](/book/collaborative-software-design/chapter-11/)

### 11.1.1 Finding the consequences

In chapter 9, we ended up with a majority of the votes for the third design. As you can see in figure 11.1, the final design, which we showed in chapter 1, and the design that got the most votes, are still different from one another. This is because we haven’t yet looked at the consequences of the design on the left.[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)

![Figure 11.1 The design that received the most votes, 16 to 2, of the group (left) and the final design (right)](https://drek4537l1klr.cloudfront.net/baas/Figures/CH11_F01_Baas.png)

There is a Dutch saying “*Wie z’n billen brandt, moet op de blaren zitten*,” which translates to “Who burns their bottom, must sit on blisters.” In other words, when you do something, especially when it’s stupid, you have to live with the consequences. Yet, we rarely take a moment to write down what the consequences are of an alternative. One important thing we realized is that visualized discussions are better at reaching a conclusion than simply talking about it. The technique also needs to be easy to use. One of those easy structures to visualize the consequences of an alternative you designed during a collaborative modeling session is the Pros-Cons-and-Fixes[1](/book/collaborative-software-design/chapter-11/footnote-002) list. We found it to be very helpful when thinking about the benefits or drawbacks of an alternative. The *Pros-Cons-and-Fixes list* is an extension of the pro-con list. It helps you deal with the tendency to overfocus on the drawbacks of an alternati[](/book/collaborative-software-design/chapter-11/)ve.[](/book/collaborative-software-design/chapter-11/)

#### How to use the Pros-Cons-and-Fixes list

We start by writing down the advantages of the alternative, that is, all the things we’ll gain if we pick this one. We know it’s tempting to start with summing up the cons first because it’s a lot easier to come up with those, but remember we’re starting with the pros for a good reason. We don’t want to end up in a conversation where we only talk about the negative. Think about biking to work for a second. You can likely come up with a lot more downsides than benefits from biking to work. For example, the cons might include it takes longer, you arrive sweaty, you get wet when it rains, and so on. Now think about the benefits: um, it’s healthy to exercise? That’s it, that’s all we have, but let’s get back to those cons. So, write down the pros first! [](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)

After that, you write down all the disadvantages of the design. This is where it gets interesting. After you write down a disadvantage, you think about the way you could “fix” it. Sounds simple (because it is), but it’s very powerful. For example, one of the drawbacks of biking to work is that you get wet when it rains. There are a lot of ways to deal with that: put an extra pair of clothes in your office (that also works for being sweaty), buy water-repelling biking gear. Biking to work in the rain didn’t become a joy all of a sudden, but these adaptations did neutralize one or two of the disadvantages.

That is what we did at BigScreen too; we filled in a Pros-Cons-and-Fixes list to visualize the consequences of the design that had the majority of votes (figure 11.2). When we were filling in the cons of the design, Kala pointed out that Seat Allocations also calculated the ticket price, which wasn’t clear from the name. An easy way to fix this was to split calculating the price and assigning a seat. Once we changed the design to accommodate that, everyone felt comfortable about moving forward with i[](/book/collaborative-software-design/chapter-11/)t. So Pros-Cons-and-Fixes is not only for documenting decision, but also a collaborative modeling tool which you can use any time in your design flow.

#### Tips and tricks to get the most out of the technique

When using the Pros-Cons-and-Fixes with our clients, we noticed some common mistakes people made when filling in the list. Following is a list of tips and tricks to avoid these mistakes:[](/book/collaborative-software-design/chapter-11/)

-  *Not every con has a fix*—You can’t neutralize every con; sometimes, you have to learn to accept the negative side of an alternative. When you split a monolith into services, the global complexity increases because those services have to communicate with each other. We designed the architecture in such a way that we don’t push all the complexity in the communication between services, but we’ll have to live with some global complexity.
-  *A fix has to be actionable*—The term *actionable* means that you have to be able to do something when you read a fix. For example, “Find out if” or “Encourage people to” are not actionable steps. They point to missing information that we need to make a decision. Find out if your fix is possible, make it concrete, and write that down. In figure 11.2, you’ll notice that our fixes are actionable. We aren’t wondering if we could hire extra developers, we know management is willing to give us a budget to hire the extra developers that we’ll need. The list *is* the research moment; the research doesn’t come after creating the list. You can’t make an informed decision if you’re not sure a fix is possible.[](/book/collaborative-software-design/chapter-11/)

![Figure 11.2 The Pros-Cons-and-Fixes list of the new architecture that enables the “Anytime, Anywhere” campaign](https://drek4537l1klr.cloudfront.net/baas/Figures/CH11_F02_Baas.png)

-  *Understand the tradeoff when making decisions*—At BigScreen, we didn’t create a Pros-Cons-and-Fixes list for the current architecture because we already knew it was no longer sufficient. We also had a majority on the third design, so we didn’t dig deeper into those other designs that were created. If there’s a lot of doubt between two designs, you need find the tradeoff to aid your decision:

-  Alternative A will give us x, y, and z with downsides a and b.
-  Alternative B will give us a, b, and z with downsides b and c.

If you pick A, you won’t get certain pros and cons from alternative B, and vice versa. *That* is your tradeoff.
-  *Focus on all of the consequences*—Something we’ve noticed when working with a Pros-Cons-and-Fixes list, is that it’s very tempting to fixate on a couple of items on a list, instead of talking about the list as a whole. If you start doing that, you’re just back to a pointless discussion that won’t result in a decision with actionable steps to move forward. As a facilitator, it’s important to stop the pointless discussion. You can try to refocus people on the entire list by giving out a climate report. Introducing a break is helpful when you’re trying to refocus people. If a break isn’t helping, you can switch topics altogether and restart the discussion after a few days.
-  *Each item must be able to stand on its own*—It’s very tempting to write vague statements when filling in the items. Words such as “more,” “less,” “faster,” and “extra” commonly pop up. If we take a look at BigScreen, our first iteration on the pros had “Better boundaries” on it, instead of “Separation of external and internal facing software” and “Clean boundaries between user interface and backend services for purchasing tickets.” The reason someone wrote “Better boundaries” is because they were comparing this design with the big ball of mud (BBoM) that was currently in production. Although it’s our nature to compare, future software development teams will struggle to understand what “Better boundaries” means when the BBoM isn’t around anymore to compare.[](/book/collaborative-software-design/chapter-11/) So, as a facilitator, when you see comparative words such as “better,” “more,” and “less,” always ask “Better than what?” or “What exactly makes it faster?” We do this for two reasons:

-  We have to be able to understand the alternative we picked on its own two years from now, without spending an enormous amount of time reestablishing the context of that alternative. When the current situation we’re comparing to is no longer there, we can still understand the items on the list.
-  We don’t want to pick an alternative based on our vague understanding of the tradeoff we’ll get when picking one alternative over another. We want to have concrete information when we’re making our decision.

##### GUIDING HEURISTIC

When doing Pros-Cons-and-Fixes, words such as “better,” “more,” “less,” and “extra” are triggers to dig deeper so that we understand the real consequences.[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)

-  *Some consequences are just neutral*—Whether or not a consequence is positive or negative is subjective and context-specific information. Therefore, not all consequences can be categorized as positive or negative; some are just neutral. For example, you want to make a decision on which programming language to use for a prototype of a microservice. There are two options on the table: C# (current programming language) and Python (very good for prototyping). Nobody on the team knows Python. In a company that doesn’t invest in educating their people, this is a downside. But, if you work in a company that invests a lot in education, learning Python can be seen as neutral. It’s something we’ll have to do that will take time, so that isn’t immediately positive, but it’s not a downside either because we’re supported in this. So “Learning python” is neutral (neither a pro nor a con). You can adapt the Pros-Cons-and-Fixes list, as shown in figure 11.3, to capture the neutral consequences of an alterna[](/book/collaborative-software-design/chapter-11/)tive.

![Figure 11.3 Extend the Pros-Cons-and-Fixes list to capture the neutral consequences of an alternative. Whether something is pro, con, or neutral depends on the context because what is neutral for one team can be a con for another.](https://drek4537l1klr.cloudfront.net/baas/Figures/CH11_F03_Baas.png)

-  *Individual brainstorming before team collaboration*—If you’re creating the Pros-Cons-and-Fixes list in a team, it’s better to divide each step into two steps:[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)

-  Write down all your pros individually.
-  Group them together, and merge the individual items into one pro column.

The same goes for summing up cons and their fixes. Note there can be differences of opinion in a team when writing down pros (and cons and their fixes) individually first. It’s important to have a conversation about these pros and decide together as a team what the pros are for the team as a whole. Instead of brainstorming cons and fixes at the same time, we recommend making it a two-pass process that allows everyone to consider fixes for all cons, not just the ones they thought of th[](/book/collaborative-software-design/chapter-11/)emselves.

### 11.1.2 Capturing the decision

If we want to stop wondering what were they thinking, we need to capture more than just the outcome of a decision. The good news is that there already is a documentation tool available—the *architectural decision record* (ADR)—to capture architectural decisions. ADRs were first mentioned by Michael Nygard in 2011 ([https://mng.bz/4JPD](https://mng.bz/4JPD)) and have gained more popularity over the years. The purpose of the tool is to create clarity on previous decisions that were made. It’s an investment you make now, so you don’t have to be confused in the future about prior decisions that were made.[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)

There are some recommendations on how to create ADRs and what information is valuable to add, but besides that, ADRs are very flexible, and teams are free to adapt them to their own needs. The intent is to have enough information on your decision to avoid others wondering what you were thinking when you made the previous decision and whether the information is still accurate. A good ADR has at least the following attributes:[](/book/collaborative-software-design/chapter-11/)

-  Title
-  Status
-  Context
-  Decision
-  Consequences

The format of ADRs also isn’t fixed. Some people like to create a canvas for it, as shown in figure 11.4, while others prefer Markdown or a Word document. Again, it’s up to you to decide what works best for your team and where to store the ADRs for easy access. Whichever you pick, keep in mind that the ADR isn’t static, so it should be easy to change. For BigScreen, we created an ADR canvas because we wanted to keep it close to our design efforts, which happen[](/book/collaborative-software-design/chapter-11/) on Miro.

![Figure 11.4 The ADR for redesigning the BBoM into clear boundaries to enable the “Anytime, Anywhere” campaign. It contains the new architecture for the system and the Pros-Cons-and-Fixes list.](https://drek4537l1klr.cloudfront.net/baas/Figures/CH11_F04_Baas.png)

#### Title

The title describes the architectural decision we’re making. We’re designing a new architecture to enable the “Anytime, Anywhere” campaign. We also added a reference number, ADR #1, so that we can refer to this specific record in [](/book/collaborative-software-design/chapter-11/)other ADRs.[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)

#### Status

When reading about ADRs, the three most commonly used statuses are Proposed, Accepted, and Superseded. Of course, it’s up to you to extend the statuses to capture what’s important to your team. For example, Rejected is sometimes added as a status. When an ADR has the Proposed status, it means that we’re actively discussing it, and no conclusion has been reached yet. When a conclusion is reached, meaning we know which alternative we want, the status changes to Accepted. So, for BigScreen, the current status is Accepted. We also added the date on which the decision was accepted at BigScreen.[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)

Until a design is tested in production, we can never be 100% sure that it’s a good design. In addition, the world doesn’t stand still while you’re refactoring your designs. As mentioned in chapter 9, we’re making decisions under uncertainty, and sustainable decision-making means reevaluating your design when new information becomes available. This is why an ADR can be superseded. Instead of adapting the ADR, we create a new one and mark the previous one as in Superseded status with a reference to the new ADR. We want to have a historical understanding of the design decisions we made and how w[](/book/collaborative-software-design/chapter-11/)e adapted them.

#### Context

The context of a decision is important because we’ll select different alternatives as more desirable based on that context:[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)

-  How much budget is there to implement the decision?
-  Who is supportive of this, and who is opposed?
-  What is the time constraint?
-  What are the technical constraints?
-  What other political, technical, or social constraints need to be taken into account?

We described the context of the ADR for BigScreen (refer to figure 11.4) as follows: The application has been around for 15 years, and the modularity has heavily decreased over that period of time. The business wants to add a mobile app, which currently isn’t possible due to that decrease in modularity. The business has difficulty making informed decisions because the internal and external facing parts of the software system are intertwined, and adding the features they need has proven difficult.

At BigScreen, we were very lucky. Everybody was supportive of rearchitecting the current design, money was not a problem (they hired consultants after all), and everybody agreed that this was critical for the company. This isn’t always the case, and it’s good to understand everything at play when m[](/book/collaborative-software-design/chapter-11/)aking a decision.

#### Decision

The decision is a summary of what changes will be made. It’s often written in an active voice: we will, Kala will, and so on. The summary not only describes the “what” but also the “why.” As you can see on the ADR of BigScreen, making informed decisions became difficult because the software team had trouble changing or implementing features. Separating internal- and external-facing logic enables us to do this again. On the ADR for BigScreen (figure 11.4), we wrote the following:[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)

-  We’ll extract the back office into the Planning and Scheduling service to disentangle internal- and external-facing parts of the software system. This way, we can create and iterate on the models specifically designed for the business to make informed decisions.
-  We’ll create a service called Movie Schedule that contains all the information on movies. This allows us to eliminate dependencies between Purchasing Tickets and planning and scheduling (PaS).
-  We’ll refactor Purchasing Tickets into client and server, with clear boundaries for Price Calculation, Payments, and Seat Allocations. This enables the creati[](/book/collaborative-software-design/chapter-11/)on of a mobile app.

#### Consequences

The consequences explain the effect this will have on your project or product. This section tackles the future “What were they thinking?” questions. If you’re using the Pros-Cons-and-Fixes list, as we did at BigScreen, you can add it here.[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)

Some teams also like to add the other alternatives that were considered, together with the analysis of those consequences and the reason they selected a certain alternative. If you want to capture the tradeoff clearly, thi[](/book/collaborative-software-design/chapter-11/)s is a good practice.[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)

## 11.2 Spreading the knowledge through the company

Now that we’ve formalized a decision, we’ll delve deeper into propagating these decisions and their accompanying knowledge throughout the company. This is crucial because not everyone can always be present at each of these collaborative modeling sessions. Furthermore, involving everyone in each meeting would be expensive, time-consuming, and, honestly,[](/book/collaborative-software-design/chapter-11/) rather boring for many.

### 11.2.1 Communicating decisions

The most important action to take when decisions are made is to update those who either weren’t present but could be affected by the decision or possess relevant expertise. We learned this heuristic from Andrew Harmel-Law’s “architecture advice process,”[2](/book/collaborative-software-design/chapter-11/footnote-001) which shifts architectural decision-making toward the team constructing the software.[](/book/collaborative-software-design/chapter-11/)

##### VALUE-BASED HEURISTIC

Communicate the decision to the people who weren’t there but are either affected by that decision or have expertise involved in that decision.

But who exactly are these individuals within an organization? How can we pinpoint them? Referring back to chapter 4, we should have already identified these stakeholders using the essential categories from chapter 2 during the preparation of our collaborative modeling session. However, new stakeholders might be discovered during the session itself.

Therefore, it’s crucial during a session to ascertain we have consent of these stakeholders and whether we can proceed with a decision in the absence of certain stakeholders. This is a sensemaking task that requires ongoing attention. We must strike a balance—while we don’t want to involve everyone all the time, it’s possible that people excluded from smaller design groups might be affected by the decisions made. What we ought to do then is to generate options in an ADR and subsequently involve these individuals. This can be done asynchronously, such as updating everyone via email or messaging app about a new ADR. When doing so, it’s important to consider levels of buy-in from chapter 9. Be explicit about how you communicate the ad based on the levels of buy-in. Alternatively, involvement of people who are affected by the decision could occur during the architecture advice process[3](/book/collaborative-software-design/chapter-11/footnote-000) mention[](/book/collaborative-software-design/chapter-11/)ed earlier or the weekly Architecture Advisory Forum, or it might necessitate s[](/book/collaborative-software-design/chapter-11/)cheduling a new meeting.

#### Communicating asynchronously

When we communicate asynchronously with people, the ADR format is a structured way to do so. However, during collaborative modeling, a lot of the conversation is still lost, and people might lack context or make assumptions if we only present them with the outcome of the collaborative modeling. We should then either clean up the outcome or distill it into a clear diagram. The most essential pattern here is what Jacqui Read calls “know your audience” in her book *Communication Patterns* (O’Reilly, 2024).

For instance, with the team at BigScreen, we engaged in a lot of EventStorming, Example Mapping, and domain storytelling. So, after a session, to allow the team to asynchronously review what happened, we cleaned up the outcome on a virtual board. Cleaning up the outcome means structuring and making the model complete with a good legend, as discussed during the session. Most of the time, the model after such a session isn’t clear enough to show to others. The model itself is also not the artifact or outcome of such a session—it’s the transformative capabilities of the shared understanding we get from collaborative modeling. So, we also don’t focus on having a clear model as the outcome. However, to get more people on board, we want to make the model more exact. That way, the team became familiar with these collaborative modeling tools, which began to serve as a language for communicating these sessions, ensuring that everyone underst[](/book/collaborative-software-design/chapter-11/)ood what had transpired.

#### Distilling diagrams

Some tools, however, such as all the EventStorming color coding, might be confusing to people who have never experienced such a session. We prefer to create domain storytelling diagrams combined with a visualized Example Mapping, like the one in figure 11.5, especially for people on the business side to understand better. These diagrams express a much clearer functional understanding without the need for extensive kn[](/book/collaborative-software-design/chapter-11/)ow[](/book/collaborative-software-design/chapter-11/)ledge of the legend.[](/book/collaborative-software-design/chapter-11/)

![Figure 11.5 Domain storytelling diagram distilled from one of the collaborative modeling sessions to get the message across to the business of what the end flow might look like.](https://drek4537l1klr.cloudfront.net/baas/Figures/CH11_F05_Baas.png)

Sometimes, you need to communicate and distill different tools and show varied levels of abstraction to give all the unique perspectives to a decision. For example, if you want to communicate how your architecture changed, you can distill that to a C4 diagram like the one you see in figure 11.6. Be sure to remain consistent in the diagrams, especially[](/book/collaborative-software-design/chapter-11/) regarding language.

![Figure 11.6 C4 Container diagram explaining how the architecture might look in the new design](https://drek4537l1klr.cloudfront.net/baas/Figures/CH11_F06_Baas.png)

One crucial aspect to comprehend regarding distilling diagrams is that despite their clarity, there’s always room for misinterpretation. This can lead to assumptions and misconceptions. Therefore, it’s pivotal to have a system where individuals can provide feedback asynchronously. We advocate for two effective methods:[](/book/collaborative-software-design/chapter-11/)

-  *Diagramming as code*—Think of this as generating visual diagrams from textual descriptions using specific coding languages. These textual descriptions generate the visual diagrams for you. A few examples are Mermaid JS, PlantUML, and some [](/book/collaborative-software-design/chapter-11/)specific tools such as Structurizr for modeling C4. These coded diagrams can be stored in a repository so that team members and anyone with access can critique, modify, or comment directly on the code. The diagrams can also be integrated with ticketing systems so you don’t need the work to be planned first. However, don’t confuse diagramming as code with a generator that analyzes your code and creates a diagram from it.
-  *Virtual tools*—Platforms such as Miro allow users to model and showcase their diagrams. Here, participants can seamlessly comment on and discuss various parts of the illustration, fostering collaboration. These online whiteboard tools can often be easily integrated into other documentation platforms, such as wikis.

Ultimately, diagrams are more than just static images. They are evolving representations of ideas that continually reveal fresh perspectives and insights. Because a diagram is a perspective on the reality that the diagram represents, a fresh pair of eyes will get new insights on improving the model or the system. However, there are a few expectations, specifically when the diagram is a snapshot in time as with an ADR, when we want to keep t[](/book/collaborative-software-design/chapter-11/)hat diagram immutable!

#### Communicating decisions by proxy

Because these diagrams, as well as the decisions from a collaborative modeling session, can give new insights, we find that explaining the session by proxy is the most insightful. After the session, we usually identify the key stakeholders who weren’t present at the meeting and see if we can plan a meeting with them. In that meeting, we go through the outcome of the session. Doing this online is easy; in-person meetings mean you need to roll up the paper carefully in hopes nothing falls off if you use stickies, so be sure to always take pictures.[](/book/collaborative-software-design/chapter-11/)

A good way to gain new insights on these decisions is to put a structure in place to discuss the insights and share. For architecture decisions, for instance, the Architecture Advisory Forum meeting that we mentioned earlier is a good structure to scale that practice. Here, we can share decisions with the rest of the company. But remember that the forum isn’t a gatekeeping meeting where others need to vote on the decision. The Architecture Advisory Forum in essence is for the person presenting the decision to gain new insights and for the people who are there to become informed. Because a decision that is made is almost never permanent, we need to kee[](/book/collaborative-software-design/chapter-11/)p that decision alive.

## 11.3 Keeping the decision alive

Now that you’ve created ADRs to capture your entire decision and communicated in the right way, you might think that will do the trick. Unfortunately, the journey doesn’t end here. Actually, the journey is a collection of feedback loops that will have you iterate on your model and design continuously. These iterations are needed to challenge your model and design to make relevant adjustments as you go. Because we’re making decisions under uncertainty, we need feedback loops that provide us with information to make an informed decision. You could see the modeling process as a whirlpool, which we’ll explain in this section. [](/book/collaborative-software-design/chapter-11/)

This nonlinear modeling process includes iterations, feedback loops, and living documentation, which means you’ll have to throw away a model every once in a while. We’ve seen many people fall in love with a model, which ended up in terrible heartbreaks. One of the best pieces of advice we can give you is to not fall in love with any model, design, or decision because they aren’t static and are highly likely to change with every iteration. Spare yourself the heartache by not set[](/book/collaborative-software-design/chapter-11/)ting your heart on it.

### 11.3.1 The modeling process as a whirlpool

Now that you’ve made it to the documentation part, it might seem that you’re almost there. The heavy lifting part is done, you’ve dealt with conflicts and polarities, and made a decision or two. The ADR is filled in, and the Pros-Cons-and-Fixes list provided some valuable insights. Let’s wrap it up, right? Well, not quite. Software design isn’t a linear process. You should consider it a loop, or multiple loops within one loop—almost like a whirlpool. The key is to keep challenging your software model. New insights, new people, time passing, new requirements, market changes, budget costs, and technical decisions that have social consequences are just some of the complexities of the environment that the software model and the system will be implemented in. All of these factors should motivate you to adapt your model continuously. [](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)

From our experience, the modeling process is sometimes considered, or at least experienced, in a linear manner. Starting with understanding and discovering, eventually strategizing and organizing ourselves based on modeling endeavors, and eventually realizing all of this effort into code. This isn’t where it should stop. The modeling process consists of multiple loops that provide new insights and require changes to your model. The starting point, for example, which is often about discovering and understanding, requires multiple iterations and feedback loops. Trying to fully understand the current state by, for example, doing EventStorming just once, won’t complete the discovery of your current state. You need iterations with new or different people who add their perspective, knowledge, and wisdom to the EventStorm, for example. New insights always pop up after an EventStorming session because you let it sink in for a while. Then, when the model is being shared with others outside the modeling bubble, you can expect an additional iteration or two. The real value of these collaborative modeling sessions is in the modeling itself, not the output. You can iterate on your model based on the conversations that take place, the people you speak to, the conflicts that pop up, and the biases that becomes explicit during a session. This means you’ll go around in loops, which is exactly what you need.

In his Whirlpool Process of Model Exploration diagram (figure 11.7), Eric Evans presents a whirlpool model designed to aid in exploring models and iterating on their design. This approach isn’t linear; instead, it promotes challenging one’s understanding and examining models from various angles. This process bears similarities to the approach taken in Behavior-Driven Development (BDD). We touched on BDD in chapter 2, specifically discussing Example Mapping. In BDD, we select a story from the backlog, identify the requirements, formalize them into acceptance criteria, and perhaps automate these criteria into automated acceptance tests. Each of these steps incorporates feedback loops. The stages of discovery, formalization, and automation mirror the pattern of scenario, model, and code probe, emphasizing the necessity to close the feedback loop in each phase.[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)

This is exactly what we aim for with collaborative modeling, while also taking in the social and cognitive perspectives that we described in previous chapters, such as ranking, bias, co[](/book/collaborative-software-design/chapter-11/)nflict, and polarities.

![Figure 11.7 Model Exploration Whirlpool from Eric Evans. This whirlpool helps in considering collaborative modeling as a collection of feedback loops, rather than a linear process. (Source: www.domainlanguage.com/ddd/whirlpool/)](https://drek4537l1klr.cloudfront.net/baas/Figures/CH11_F07_Baas.png)

[](/book/collaborative-software-design/chapter-11/)The whirlpool in figure 11.7 starts with Harvest & Document to capture the current state. BigPicture EventStorming, Business Model Canvas, and Wardley Mapping are excellent tools to gather the relevant information and knowledge here. These collaborative modeling tools can provide relevant scenarios and will enable you to propose a model after a while. The whirlpool allows exploring multiple scenarios and models, instead of going through a linear process. It’s about experimenting in code based on the proposed model, then challenging that model with new scenarios, and rolling your way through the whirlpool again. In this way, you keep challenging your model continuously, which will make it more valuable. In other words, when you arrive at the part where you can fill in ADRs and Pros-Cons-and-Fixes lists, it might actually be the start of a new loop! Isn’t that an exciting idea?! Let’s illustrate this with an example of our friends at BigScreen:

-  BigScreen started off with Big Picture EventStorming to visualize their current state with all relevant domain experts. This exercise provided highly valuable insights, and emerging bounded contexts were popping up.
-  Smaller parts of the EventStorm, for example, Purchasing a Ticket and Movie Scheduling, can become bounded contexts that allow BigScreen to start design activities. Instead of wanting to get all the possible bounded contexts right, they picked these and started a second iteration.
-  In that next iteration, they noticed domain events around Payment happen in the system of their payment provider, meaning there needs to be communication with that external system.
-  Then we went back to our emerging bounded context design and make sure we capture that.

The preceding example is a simple illustration of how these feedback loops work by creating smaller iterations that trigger feedback and challenge our assumptions and perspectives. We can’t really prescribe how to design these feedback loops. From our experience, it helps to have different tools in your toolbox that you can use to create these feedback loops. All the tools we mentioned in earlier chapters—EventStorming, Business Model Canvas, Example Mapping, and sensemaking—can help you create[](/book/collaborative-software-design/chapter-11/) valuable feedback loops. If you want to understand more on how the whirpool works, or how to start a modeling process, check out the Domain-Driven Design Starter Modelling Process by the DDD Crew: [https://github.com/ddd-crew/ddd-starter-modelling-process](https://github.com/ddd-crew/ddd-starter-modelling-process).[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)

#### The importance of feedback loops

If you ask a random person about feedback loops, they will probably confirm that having those loops in place is crucial. The real question is why they are so important. We’ve learned that they are important, and we’re conditioned to at least consider them in a lot of our activities, but the “why” of feedback loops sometimes remains ambiguous. For us, it’s pretty clear: we need feedback loops because we make decisions under uncertainty and use heuristics when making decisions. Both uncertainty and heuristics don’t guarantee success, so we need feedback loops to gather information—not only once, but during multiple loops. [](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)

Chapter 9 helped us understand that information is crucial to make an informed decision. What makes a decision easy or hard is how well informed you feel about the decision you have to make. The more information we have, the better we can evaluate available alternatives and make an informed decision. You want to get the level of uncertainty down, so the decision will be easier to make. You can never be 100% informed, but you can be as informed as possible.

Creating feedback loops will help you in gathering the necessary information to evaluate alternatives and eventually make an informed decision. You must use the information you’re getting from the feedback loops to adjust your model when necessary. When your models aren’t functioning as you hoped, you need to make adjustments instead of continuing on your stubborn path.

The other reason feedback loops are important is related to the uncertainty that comes with making decisions and how using heuristics can help you deal with that. As explained in chapter 3, heuristics are simple rules to help you make decisions. Heuristics are based on experience and knowledge, and help us to progress forward when a decision is needed. Are we putting this boundary here or there? Are we going to split up to design bounded contexts or do that collectively? These are both situations where you could use heuristics, but these heuristics don’t guarantee solutions or success as Billy Vaughn Koen points out in his book *Discussion of The Method: Conducting the Engineer’s Approach to Problem Solving*, heuristics are ultimately unjustified, impossible to fully justify, and inherently fallible. So, you need feedback loops that will provide you with more information. Maybe split up for now, but come back together after two days to do a walkthrough and adjust the model collectively. Then, go back into (reshuffled) subgroups, and come back together again after two days. These iterations and feedback loops will help you discover what works well and what doesn’t.

The thing is, you don’t know if something works until it’s in production. The same goes for architecture. You need these feedback loops to lower uncertainty by gathering information you need to make an important decision. So, the next time someone asks you why feedback loops are important, you [](/book/collaborative-software-design/chapter-11/)know the answer: uncertainty.

#### Emerging living documentation

Documentation is part of your feedback loops. The way you document your models, thought processes, decisions, and design is crucial to get that information from your feedback loops you need to make an informed decision. This documentation preferably is alive and emerging, meaning this documentation emerges and changes every time you’re in a (new) feedback loop. Based on new information you gathered in a loop, you may need to add something to your documentation. For example, from your Big Picture EventStorm, you take smaller parts to do some process EventStorming on. Or, based on your Example Mapping, you add a Pros-Cons-and-Fixes list. [](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)

There are different ways to deal with this emerging living documentation. With online whiteboards such as Miro and Mural, it’s relatively easy to keep track of what you’re doing. You could start with one big Miro board that contains all of your information: EventStorming, context maps, Pros-Cons-and-Fixes lists, and polarity maps. But maybe you’ll realize that your board is getting very big by continuing to add new information and iterations, so you might want to go with separate boards for all bounded contexts, for example. You might also start a separate polarity board that captures all relevant maps and polarities within the group. Then you come to the point where you want to start documenting ADRs. Although this will be easier in Git, for example, you might want to add links to it on your Miro board.

##### GUIDING HEURISTIC

When your online whiteboard gets too big, find a way to split the board up based on your teams, or architecture.

This is how you end up with emerging living documentation, which will keep decisions alive and allow you to make relevant adjustments to your models based on information from your feedback loops. Note that it’s up to the people working on the models and designs to decide how you deal with this documentation, such as when it’s preferred to start a separate board or who the board owners will be, for example. The choices you make regarding this emerging living documentation are design decisions as well.

Note that with the use of Miro, we see people continuing on versions they started with, which means in following iterations, the model is being adjusted or extended during new collaborative modeling sessions. By doing this, you’re losing the previous version. This could be a downside because you also might lose important thought processes or small design decisions you’ve made along the way. In that light, it’s important to consciously make a distinction between reusing collaborative models and immutable collaborative models in which the immutable models are frozen at a point in time, let’s say. As a group, you decide when to freeze the model, and if you want to start iterations, you make a copy of that immutable model and start working on that copy. In that way, you keep important information on your board so you can keep track of adjustments. To decide when to freeze a model, you could use ADRs. ADRs capture significant design decisions, so every time you create an ADR, that might be a natural moment to freeze a model and make a copy for further iterations, superseding the model.

##### GUIDING HEURISTIC

Whenever you create an ADR, freeze your model and use [](/book/collaborative-software-design/chapter-11/)copies for following iterations.

### 11.3.2 Don’t fall in love with your model

[](/book/collaborative-software-design/chapter-11/)Remember, as beautiful and brilliant as your model might be, don’t fall in love with it! When you fall in love with something, it’s hard to look at it objectively, let alone throw it away when necessary. With the feedback loops comes new information that helps you make an informed decision. The new information you gathered might require you to make adjustments to your model or design, or even throw it away completely. When you’re already madly in love with a model, you’ll be tempted to make extensions to the existing model, rather than redesigning it so that it will be a better fit for purpose. That’s what you want to avoid. [](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)

##### VALUE-BASED HEURISTIC

Tell yourself not to fall in love with a model every now and then and that it’s okay to throw your model away when needed.

In chapter 7, we talked about the availability bias and model fitting. The availability bias pops up when we’re trying to make decisions or assess information, and we add more value to information that can be recalled easily or at least find it more important than alternative solutions not as readily recalled. When we do collaborative modeling, we might favor our first design over later designs because we substitute “good” for “easy.” So due to the availability bias, we already have a strong preference for the first model we came up with and that will only grow over time. We feed our love for that model and get emotionally attached to it, so when we then get challenged on our assumptions and perspectives in a feedback loop, we might be hesitant to completely redesign our first model. This can be true even though the new information indicates that this is the best way forward.

What we then often see is that people start to make extensions of that first model, thereby compromising on its quality. This is called model fitting, where we deform, add, or leave out elements from the problem domain to force it into an already existing model just because we got emotionally attached to it. This is why it’s important to design your models in different ways, so you get more information, reduce uncertainty, and prevent the availability bias from feeding too much love to your initial model.

Two other biases that are related to emotional attachment to an existing model and model fitting are loss aversion and sunk cost fallacy. *Loss aversion* was explained in chapter 9, which is about the tendency to avoid losses over gaining wins. Throwing away an existing model, however strong the arguments may be, feels like a loss. Because we want to avoid that, we’ll be more likely to start model fitting instead of doing a redesign. *Sunk cost fallacy* is about our tendency to follow through on an endeavor if we’ve already invested time, effort, or money into it, whether or not the current costs outweigh the benefits. So, we might stick with an existing model because we’ve been working on it for months, it has cost a lot of frustration and iterations to finally get somewhere, and we won’t throw it away just because we got some new piece of information that might contradict our previous endeavors. The more you invest in a model, the more emotionally attached you’ll be, the harder it will be to throw it away. It might feel like you’re throwing away all the hard work you and your team put into it over the past months. And that’s a horrible feeling. [](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)

Note that all these biases can be at play at the same time, reinforcing each other. Due to the availability bias, we prefer the existing model, and our tendency to avoid loss will make it very hard to throw that existing model away. At the same time, thanks to the sunk cost fallacy, we are heavily emotionally attached to that existing model. Note that these biases—just like other biases—are working mainly unconsciously. We’re often not aware of our emotional attachment and the behavior that follows from it. This is where a facilitator can come in to observe and recognize the biases at hand, making them explicit. Either way, all these forces may lead you toward model fitting, instead of doing what’s necessary: face your breakup and part ways with your model, or as writers would say, “Kill your darlings.”

To conclude this chapter and our attempt to convince you that you shouldn’t fall in love with your model, we understand that we might not succeed—or at least not with everyone. Our words of advice might resonate with you, but there are other ways to make important messages stick. In that light, we asked ChatGPT to write a song about not falling in love with your model. We proudly present the lyrics to you here! [](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)

*Verse 1*:

Blueprints and sketches, lines on the page

A designer’s vision, a world to create

The structure’s design, it’s so alluring

But don’t get too caught up, it’s just a drawing

*Chorus*:

Don’t fall in love with the model

It’s just a concept, not something to hold

Don’t let the plans consume your soul

Remember it’s just a vision, not a reality to behold

*Verse 2*:

The curves and angles, they may entice

But don’t forget, it’s not a living device

It’s just a model, a representation

Not something to build your life’s foundation

*Chorus*:

Don’t fall in love with the model

It’s just an idea, not something to touch

Don’t let the design control your role

Remember it’s just a [](/book/collaborative-software-design/chapter-11/)blueprint, not something you can clutch

## 11.4 Collaborative software design catalysts

-  When there are different options to a decision, start experimenting with a Pros-Cons-and-Fixes list. Try out one for yourself first, and then see if you can use one together with your team. [](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)
-  After using a Pros-Cons-and-Fixes list, reflect on its benefits and downsides. How can it help you? How or in which situations could it be valuable to you and/or your team to use the list?
-  Start experimenting with ADRs. Don’t start too big; consider something more lightweight to assess if this tool is somethi[](/book/collaborative-software-design/chapter-11/)ng that would be of value to your team.

## 11.5 Chapter heuristics

*Guiding heuristics*[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)

-  When doing Pros-Cons-and-Fixes, words such as “better,” “more,” “less,” and “extra” are triggers to dig deeper so that we understand the real consequences
-  When your online whiteboard gets too big, find a way to split the board up based on your teams, or architecture.
-  Whenever you create an ADR, freeze your model and use copies for following iterations.

*Value-based* *heuristics*

-  Communicate the decision to the people who weren’t there but are either affected by that decision or have expertise involved in that decision.
-  Tell yourself to not fall in love with a model every now and then and that it’s okay to throw your model away when needed.

## 11.6 Further reading

-  *Communication Patterns* by Jacqui Read (O’Reilly, 2024)[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/)
-  “Scaling the [](/book/collaborative-software-design/chapter-11/)Practice of Architecture, Conversationally”[](/book/collaborative-software-design/chapter-11/)[](/book/collaborative-software-design/chapter-11/) by Andrew Harmel-Law ([https://mng.bz/Ad4Q](https://mng.bz/Ad4Q))[](/book/collaborative-software-design/chapter-11/)

## Summary

-  Formalizing decisions is essential for future reference and understanding. This involves finding the consequences of chosen alternatives and capturing them.
-  The Pros-Cons-and-Fixes list is a powerful technique to visualize the benefits and drawbacks of alternatives. It helps identify actionable fixes for disadvantages, aiding decision-making.
-  When faced with multiple options, it’s crucial to assess tradeoffs to make informed decisions. Each item in the Pros-Cons-and-Fixes list should stand on its own, avoiding vague statements and focusing on all consequences.
-  The Architectural Decision Record (ADR) is a flexible documentation tool for capturing entire architectural decisions, including context, decision, and consequences, to avoid future misunderstandings and enable sustainable decision-making.
-  A well-structured ADR includes essential attributes such as title, context, decision, status, and consequences. It allows teams to record decisions effectively and adapt as needed to account for changing circumstances.
-  Updating absent stakeholders and experts by using ADR format and asynchronous methods on decisions is crucial for transparency and inclusivity.
-  Distill diagrams such as C4 models, domain storytelling, and Example Mapping to enhance understanding, allowing asynchronous comments for insights.
-  You can facilitate discussions in forums such as the Architecture Advisory Forum to share decisions, keep them alive, and gain further insights for ongoing improvement.
-  Design isn’t linear but a loop; challenge and iterate on the model to accommodate new insights, perspectives, and requirements.
-  Use feedback loops to gather information, lower uncertainty, and make informed decisions. Adopt emerging living documentation to keep models alive and allow relevant adjustments based on feedback.
-  Avoid Emotional Attachment and don’t fall in love with your model to maintain objectivity and prevent biases such as availability bias, model fitting, loss aversion, and sunk cost fallacy.
-  Embrace redesign, and be open to throwing away or redesigning your model based on new information to reduce uncertainty and make better decisions.[](/book/collaborative-software-design/chapter-11/)

---

[](/book/collaborative-software-design/chapter-11/)[1](/book/collaborative-software-design/chapter-11/footnote-002-backlink)   Jones, M. D. *The Thinker’s Toolkit: 14 Powerful Techniques for Problem Solving*, 1998. New York: Crown Currency (p. 97).

[](/book/collaborative-software-design/chapter-11/)[2](/book/collaborative-software-design/chapter-11/footnote-001-backlink)   Harmel-Law, A. “Scaling the Practice of Architecture, Conversationally,” 2021. [https://mng.bz/Ad4Q](https://mng.bz/Ad4Q)

[](/book/collaborative-software-design/chapter-11/)[3](/book/collaborative-software-design/chapter-11/footnote-000-backlink)   Ibid.
