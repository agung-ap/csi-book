# 3 [](/book/collaborative-software-design/chapter-3/)[](/book/collaborative-software-design/chapter-3/)[](/book/collaborative-software-design/chapter-3/)[](/book/collaborative-software-design/chapter-3/)[](/book/collaborative-software-design/chapter-3/)[](/book/collaborative-software-design/chapter-3/)[](/book/collaborative-software-design/chapter-3/)[](/book/collaborative-software-design/chapter-3/)[](/book/collaborative-software-design/chapter-3/)Using collaborative modeling for design and architecture

### This chapter covers

- The relationship between collaborative modeling, design, and architecture
- Heuristics and their usage during collaborative modeling
- Driving the design by understanding the business

The previous chapter gave you an idea of what collaborative modeling is and how it can be used to truly understand business problems before diving into solutions. We explained the relationship between Domain-Driven Design (DDD) and collaborative modeling, and described some of our favorite collaborative modeling tools. So, we’ve got the basics right. At this point, you’re probably wondering how collaborative modeling can be used to create an actual design and architecture. That’s exactly what we’ll cover in this chapter. [](/book/collaborative-software-design/chapter-3/)

We’ll continue with our BigScreen example and take you further on their journey. We start with defining design and architecture, which is crucial if we want to move to the solution space. We’ll also dive into the difference between design and architecture, as well as how you can benefit from doing both collaboratively.

All of these activities take place in a bigger system in which we live and work. It’s not just about getting the technical details right, such as the structure of the software system, the work that needs to be done, or even the best technology for the challenge at hand; it’s also how the organization structure, social structure, and our cognition affect these activities. Those aspects together form the sociotechnical system that balances social, technical, and cognitive aspects. To succeed, you’ll have to optimize all aspects together because they heavily affect each other. In this chapter, we’ll provide an introduction to sociotechnical systems.

Definitions are great, but putting those definitions into practice is a whole other ballgame. We’ll also further explain the need for collaborative modeling in design and architecture. We’ll explore how bad design decisions can affect social dynamics and (implicit) architecture, and which consequences can follow from these bad decisions. One way to drive the design and collaborative modeling sessions is by using *heuristics*, which are simple rules to make quick decisions. This chapter will explain what heuristics are and how and when you can use them. We’ll share some of our own favorite heuristics and invite you to start your own heuristics journal at the end of this chapter.[](/book/collaborative-software-design/chapter-3/)

This chapter concludes with more insights on how to drive design by understanding the business. This is where we really move toward solutions. We’ll dive into bounded contexts and why boundaries are designed through collaboration[](/book/collaborative-software-design/chapter-3/).

## 3.1 What is software design and architecture?

[](/book/collaborative-software-design/chapter-3/)In the previous chapter, we discussed how the goal of collaborative modeling is to foster a deep and shared understanding of the problem. We aim not only to share our individual mental models of the problem but also to understand the diverse perspectives and ultimately create a shared understanding of those models. *Models* is plural here because, depending on the information, a problem can be represented in various ways. Donella Meadows puts it like this in *Thinking in Systems: A Primer*: [](/book/collaborative-software-design/chapter-3/)

*Remember, always, that everything you know, and everything everyone knows, is only a model. Get your model out there where it can be viewed. Invite others to challenge your assumptions and add their own.*[1](/book/collaborative-software-design/chapter-3/footnote-003)

This notion of everyone having a model, whether you spend a lot of time and energy on modeling or no conscious time at all, is inevitable.

Similarly, when it comes to software design and architecture, the presence of some form of design, whether good or bad, is unavoidable. Bad design is very real. Bad design can manifest from a lack of design decisions, isolated decisions that no one truly grasps, or decisions that exist but haven’t been explicitly stated. Often, we observe that these problems are caused by design decisions that are based on incorrect models or misunderstood concepts. This leads to an implicit design and architecture.

When faced with such implicitness, software development teams might resort to workarounds because they need to navigate the murky waters. However, these workarounds only introduce more complexity into an already intricate environment. To prevent this added complexity, we stress the importance of making design and architecture explicit. The key is to model collaboratively, ensuring a shared understanding and eliminating as much implicitness or ambiguity as possible. By doing so, we can effectively manage the complexity introduced by the people within the system, that is, in the sociotechnical syst[](/book/collaborative-software-design/chapter-3/)em.

### 3.1.1 The importance of meaning and definitions

[](/book/collaborative-software-design/chapter-3/)Language is crucial in collaborative modeling because if we don’t have a shared understanding of what a word means, that misunderstanding ends up in our decision-making. It reminds us of *Friends* episode “The One Where Underdog Gets Away” (Season 1) where Monica and Rachel walk out of their apartment. Monica says, “Got the keys,” and Rachel replies, “Okay.” Neither has the keys, and they are locked out of their apartment. As the episode shows you, language ambiguity can lead to all sorts of negative, time-consuming, and frustrating situations. Language ambiguity is everywhere, so we’re always keen on removing it in collaborative modeling sessions. “What do you mean with . . .?” is a question we hear ourselves ask very (very) often. Now we wouldn’t call ourselves DDD practitioners without finding it essential to define these words and create our ubiquitous language for this book.[](/book/collaborative-software-design/chapter-3/)

Of course, those definitions might not be how you would describe those concepts or use the words we use. We would be surprised if our description matches what is used across the entire software industry because language is fluid and constantly changing. Nevertheless, keep in mind that we designed our definitions in the context of this book, our ubiquitous language.

You can agree with it or disagree with the definitions, and that’s perfectly fine. In fact, we believe that definitions should be continuously challenged and evolve where necessary. We can all learn from that process.

Now, we’ll elaborate on what we mean by *design*, *architecture*, and *sociotechnical* *system*. Let’s start explaining *our* definition by seeing how implicit architecture and design can create more accidental complexity in our BigScreen comp[](/book/collaborative-software-design/chapter-3/)any.

### 3.1.2 What is software architecture?

The previous chapter highlighted how BigScreen reaped the advantages of collaborative modeling in understanding its business problems. Through EventStorming, the team delved into the current ticket-purchasing process, which offered invaluable insights for their “Anytime, Anywhere” campaign. Understanding how the business operates with the existing software system is important for this team because they are afraid of altering the reservation code due to lost knowledge. Throughout the session, a recurring theme was the team’s astonishment and questions about how the software system evolved to its present state. This isn’t a unique observation; we’ve seen numerous instances where individuals were taken aback by certain design decisions.[](/book/collaborative-software-design/chapter-3/)

It’s becoming increasingly common for software teams to encounter such surprises, and perhaps you’ve experienced this yourself. While there were specific, contextual reasons for these past decisions, the recurring surprise underscores a gap in knowledge or communication. We posit that the industry’s shift toward Agile methodologies in the past 5–10 years, a transition BigScreen also underwent, might be a contributing factor.

As mentioned in chapter 1, we’ve observed that many companies often find themselves in an “Agile theater;” that is, they might implement Agile frameworks such as Scrum or Kanban, or even use a scaling framework, yet they retain their traditional hierarchies. We’re not criticizing these frameworks; in fact, we’ve employed them ourselves and recognize their value when applied in the right context for the right reasons.

[](/book/collaborative-software-design/chapter-3/)Following industry trends, BigScreen also transitioned to an Agile approach for its development team. However, the team didn’t fully grasp the methodology’s nuances. One major misconception they held was the belief that up-front architecture and an Agile approach are inherently at odds. This misunderstanding fostered significant emotional baggage among the development teams, who began to view the architect and the overarching architecture as limiting factors. As these teams shifted to iterative development, delivering features every sprint, the architect and the practices surrounding architecture became a bottleneck. This led to the rise of terms such as “ivory-tower” architect. It’s essential to note that being perceived as a bottleneck, or being labeled an ivory-tower architect, isn’t solely or even primarily the architect’s fault, especially in BigScreen’s case. The company’s existing hierarchy persisted, and this structure still held the same expectations of the architect as it did in the past.

In response to this conflict, teams began to sidestep the architect to ensure they could deliver on their commitments. This led to a situation where the teams and the architect found themselves with competing objectives. However, these teams weren’t adequately trained or well-versed in software architecture, as it wasn’t a primary focus in the waterfall approach they were accustomed to. As a result, they didn’t initiate explicit design activities, which left them oblivious to the ramifications of their design decisions on the software architecture. We believe that software teams—not a software architect outside the team—should own the software architecture. However, before they can do that, they should be enabled and trained in software architecture before firing the architect!

Even when coding, you can make pivotal design decisions. The act of coding makes a developer do software architecture. For example, you’re tasked with modifying an integration with another system. While coding, you decide to alter a specific name that triggers a series of changes across the systems involved. You’ve made a significant design decision. While a mere name change might not alter the fundamental structure of the software systems, it introduces complexities and dependencies that ripple through the architecture. This perspective on software architecture aligns with the views of Grady Booch, who is internationally recognized for his contributions to software architecture and is the creator o[](/book/collaborative-software-design/chapter-3/)f the Unified Modeling Language (UML).

##### Definition

*Software architecture* represents the significant design decisions that shape a system, where significance is measured by cost of change ([www.bredemeyer.com/whatis.htm](https://www.bredemeyer.com/whatis.htm)).[](/book/collaborative-software-design/chapter-3/)

BigScreen is consistently involved in decision-making processes that shape the system at various levels of the organization. While transitioning from waterfall to Agile isn’t directly making design decisions, these shifts certainly affect the manner in which design decisions are approached and executed.

Design decisions, regardless of their scale, have the potential to affect the fundamental shape of software systems. The essence of these decisions lies in their significance. Booch has associated significance with the cost of change. Thus, when a design decision is made, architectural considerations should factor into the potential cost of implementing that change and its influence on the fundamental structure of the software. This fundamental structure is the foundational layout and organization of the software system. Alterations to this structure can affect the degree in which a system can be divided into smaller self-contained units (*modularity*), which affects its ability to undergo modifications (*changeability*), and its capacity to adjust to new functionalities or requirements (*adaptability*).[](/book/collaborative-software-design/chapter-3/)[](/book/collaborative-software-design/chapter-3/)[](/book/collaborative-software-design/chapter-3/)

In the context of BigScreen, the cost associated with altering the design is substantial. The current software system poses challenges in adapting to the new “Anytime, Anywhere” campaign requirements. The company aspires to modernize the ticketing system, enabling customers to purchase tickets through a mobile app. However, integrating this feature into the existing software isn’t cost-effective. Ideally, a good architecture should ensure that the introduction of new features doesn’t slow down the system or escalate costs, maintaining both its changeability and adaptability. Yet, the inherent challenge lies in the unpredictability of the future and the probability of new features needing to be added, making software architecture a complex [](/book/collaborative-software-design/chapter-3/)endeavor.[](/book/collaborative-software-design/chapter-3/)[](/book/collaborative-software-design/chapter-3/)

### 3.1.3 What is software design?

By using collaborative modeling as introduced in chapter 2, the teams started to understand the business problems. Having a model of the current situation that includes the wisdom, perspectives, and knowledge of the entire group created an overview and insights into how processes affect each other. BigScreen could start moving toward a design to modify the software system. Modifying your current system to what you want is where design activities come in. As mentioned in chapter 2, we use design activities to go from the problem space to the solution space. We’ll provide more in-depth examples of these design activities later in the chapter. For now, we’re using these design activities to create a plan to modify the current software systems to end up with the new desired systems. That is how we define *software design*, which includes all the design activities aimed to modify the current software systems into a preferred one.[](/book/collaborative-software-design/chapter-3/)

##### Definition

*Software design* refers to the design activities aimed to modify the current software systems into a preferred one ([www.bredemeyer.com/whatis.htm](https://www.bredemeyer.com/whatis.htm)).[](/book/collaborative-software-design/chapter-3/)

Design activities often culminate in a plan to modify software systems. Within this plan, we formulate design decisions. However, not every design decision holds equal weight or significance for our software architecture. As Booch aptly puts it, “All software architecture is design, but not all design is software architecture.” This distinction is crucial to grasp. Software design is a given; whenever we make alterations to software systems, we’re inherently engaging in design. The real question is, which of these design decisions have the potential to alter the foundational shape of the software system, that is, the software architecture? Later in this chapter, we show you examples of software design done within BigScreen by designing boundaries (section 3.3.1), as well as how that software design leads to a new software architecture.

If a design decision doesn’t affect the core structure, then it’s not a matter of software architecture. In such cases, there’s no need to invest time and effort in software architecture considerations. If the change is merely tweaking a portion of the code without causing ripple effects throughout the system, then explicit architectural design decisions aren’t necessary; you can simply implement the change.

Software architecture, however, encompasses more than just the software system itself. It’s embedded within a broader ecosystem, being built by a team of people, used by individuals, and integrated into the organization’s structure. Design decisions—whether they pertain to the team, the organization, or the manner in which people work—have continuous and interconnected effects. Given the interconnected nature of software systems and the broader ecosystem they exist within, it’s crucial to make sustainable design decisions that account for long-term effects and adaptability. We’ll talk more about what makes a design decision sustainable in chapter 9.

[](/book/collaborative-software-design/chapter-3/)One of the most significant benefits of collaborative modeling, especially when aligned with company goals and strategy, is its ability to help teams concentrate on the right priorities. With a clear model of the present situation, we can envision and design the future with the following questions in mind:

-  What does our ideal future look like?
-  What steps should we take to reach that state most effectively?
-  Where should our investments go?
-  Which areas should our development teams prioritize?
-  Is our current team structure equipped for the impending changes?
-  How will these changes affect the cognitive load of our teams?

These are all critical strategic questions that leadership teams must address. Having a clear understanding of where you currently stand—your starting point—provides invaluable insights into answering thes[](/book/collaborative-software-design/chapter-3/)e questions.

### 3.1.4 What are sociotechnical systems?

To enable teams to focus on parts of the software systems that are in line with the company strategy and goals, the bigger mental model needs to be created and shared with all involved. Certain teams may still focus more on specific parts of the system, but at least the effects and dependencies are known and can be designed for.[](/book/collaborative-software-design/chapter-3/)[](/book/collaborative-software-design/chapter-3/)[](/book/collaborative-software-design/chapter-3/)

When we talk about *systems*, we don’t mean purely technical systems; we mean the system as a group of interacting components, for example, the team, the people in the team, and the software systems they use and build. To be more specific, sociotechnical systems are networks of interrelated components where the different social, technical, and cognitive aspects interact. A technical decision will have social and cognitive consequences, and vice versa. Balancing these aspects is hard, but necessary.

A sociotechnical system provides us with a holistic framework for understanding and organizing intricate work environments. Rooted in the foundational work of Emery et al., the term *sociotechnical system* encapsulates the intricate interplay between human dynamics, technological tools, and the broader environmental context,[2](/book/collaborative-software-design/chapter-3/footnote-002) as you can see in figure 3.1. Today, as we navigate increasingly complex workspaces, this interplay between social practices, technology, and cognitive processes becomes even more pronounced. These elements are deeply intertwined, and any attempt to optimize one while ignoring the rest only amplifies systemic complexity. For instance, a technological decision can reshape team dynamics and increase cognitive demands, as new tools necessitate new skills. [](/book/collaborative-software-design/chapter-3/)

A notable example of focusing on one aspect while overlooking others is seen in how many companies have adopted open-plan office spaces. This move was influenced by the benefits observed in communication, collaboration, equality, health, and cost in other organizations with similar environments.[3](/book/collaborative-software-design/chapter-3/footnote-001) However, simply shifting to an open-plan layout often means just optimizing the physical system, while neglecting to jointly optimize structure, people, and task systems in a sociotechnical system. Studies reveal that most companies making this transition mainly realized cost reductions, but the other four expected benefits often didn’t improve as anticipated. Those companies that did achieve all the benefits managed this by involving their employees in the design of the open-plan space. By doing so, they effectively jointly optimized all four systems in the sociotechnical system. The physical system was improved through the workspace alteration, the people system evolved as employees influenced the social dynamics in the new space, the structural system benefited from teams reorganizing based on their communication needs, and the task system was enhanced due to the new interaction methods. The connections and mutual dependencies within a sociotechnical system are depicted in[](/book/collaborative-software-design/chapter-3/) figure 3.1.

![Figure 3.1 A sociotechnical system is the relationship between the technical system (the tasks and the physical system) and the social system (structure and people). When designing software, we often forget about the effect of the social system.4](https://drek4537l1klr.cloudfront.net/baas/Figures/CH03_F01_Baas.png)

*Sociotechnical* might seem like a modern buzzword, but its origins date back to the post-World War II era. During this period, scientists investigated work systems in coal mines. They found that organizations where teams were responsible for control, coordination, and the primary goal of coal extraction were more efficient than those where teams focused on specific tasks, such as digging or detonation. In these latter organizations, the responsibility of control and coordination fell to the managers.

[](/book/collaborative-software-design/chapter-3/)Emery’s later research in Norway provided deeper insights. Organizations without a hierarchical structure for control and coordinat[](/book/collaborative-software-design/chapter-3/)ion, known as “design principle 2 (dp2),” outperformed those where these responsibilities were held by manag[](/book/collaborative-software-design/chapter-3/)ement, termed “design principle 1 (dp1).” A hallmark of dp2 organizations was the teams’ active involvement in shaping their structures through participatory design sessions. This approach enabled them to quickly adapt to external changes, unlike the slower response seen in dp1 structures.

This research underscores the significance of optimizing various aspects collaboratively for success. Prioritizing one element, such as efficiency, can inadvertently affect other system components, negating potential benefits. Technological decisions carry social and cognitive implications. For instance, the evolution from early mobile phones to smartphones transformed not just communication but also our societal behaviors and culture. Similarly, in development teams, introducing a new technique or process, such as Scrum, alters team dynamics and relationships. This change demands immediate cognitive adjustment, requiring individuals to understand the new workflow and its broader implications. While a technological shift might seem beneficial, it’s crucial to anticipate its social and cognitive effects and plan accordingly. Most importantly, the shift must be done by the team members themselves, and they should have the control to discard the changes if necessary.

We see a lot of change initiatives and transformation projects. Consider, fo[](/book/collaborative-software-design/chapter-3/)r example, the DevOps movement. Moving to DevOps is not only introducing new tools and methodologies but also introducing new social practices, ways of working, different communication patterns, and new desired behavior. It also works the other way around when organizations intend to change the culture, for example. There’s a lot of focus on the more social aspects, such as values, mindset, and emphasizing the “why.” The work is often being ignored or overlooked, not the technology. By looking at the system as a whole, you can create the conditions for success.

So, what’s the relationship between sociotechnical systems and collaborative modeling? The short answer is that all aspects of sociotechnical systems are present in collaborative modeling sessions, which are the perfect places to make these aspects explicit and balance them out. Collaborative modeling sessions depend on the knowledge and behavior of the people involved. When facilitated properly, they also trigger the right conversations about software, architecture, processes, relationships, and underlying challenges. Collaborative modeling sessions expose group dynamics and cultural norms, which influence the process of creating software. Many signals—both weak and strong—tell you something about the culture within a group of people, a team, or an organization. Collaborative modeling is the perfect setting to clarify these signals. This is also why we believe it’s so important to have proper facilitation during these sessions. It’s almost a full-time job to pay attention to these signals and see how they aff[](/book/collaborative-software-design/chapter-3/)ect the group.[](/book/collaborative-software-design/chapter-3/)[](/book/collaborative-software-design/chapter-3/)[](/book/collaborative-software-design/chapter-3/)

### 3.1.5 Design decisions and collaborative modeling

Design decisions are a critical part of design and architecture. As mentioned, collaborative modeling enables making (design) decisions, taking into account all aspects of sociotechnical systems (technical, social, cognitive). All design decisions made will affect the architecture and social dynamics within a group. Again, this is why it’s so important to think in terms of sociotechnical systems instead of focusing on one part of the puzzle.[](/book/collaborative-software-design/chapter-3/)

Collaborative modeling can help you make good design decisions that will result in the best possible solutions. When all domain experts and relevant stakeholders are present, it’s easier to identify possible decisions, their tradeoffs, and their value. It’s also the perfect place to make design decisions explicitly, so you won’t end up with a black box and/or *implicit architecture*. But that’s the ideal world; now, let’s dive into the consequences of bad design decisions and how they affect your group dynamics [](/book/collaborative-software-design/chapter-3/)and architecture.[](/book/collaborative-software-design/chapter-3/)

#### Consequences of bad design decisions

Remember our fictitious company called BigScreen? The company faced challenges including the product owner (Ralph) being involved in gathering user requirements, arguments between developers, and tension in the group, which resulted in one of the developers just starting and implementing his own design. One of the biggest problems was that the team wasn’t kept in the loop regarding design decisions. This led to wrong implementation, delays, and rework. When design decisions go wrong, it often results in what we call an implicit architecture. We see three main reasons for this:[](/book/collaborative-software-design/chapter-3/)

-  Design decisions are being made, but they aren’t made explicit (often with time pressure).
-  Those implicit design decisions weren’t understood by everyone.
-  Implicit design decisions can’t be communicated.

As stated in the introduction of this section, there is no such thing as *no design*. As in the BigScreen example, someone may decide to just start and implement whatever they see fit. Or maybe someone makes design decisions in isolation that affect the architecture big time. What’s interesting here is to look into why there are no decisions being made. Hesitation to make decisions can be a signal that people are suppressing knowledge. Maybe it’s not safe enough to speak up in the group, maybe the group has learned that making a decision is followed by more work, or maybe the environment isn’t safe to fail in. A lack of design decisions being made doesn’t have to mean that (technical) knowledge is missing in the group. It can be, of course, but there’s a good chance that social and cognitive factors are influencing these patterns as well. Treating your environment like a sociotechnical system (refer to section 3.1.4) will help![](/book/collaborative-software-design/chapter-3/)

When design decisions are being made, but they aren’t explicit, it’s valuable to look at certain social dynamics within a group. Bad design decisions can heavily affect both the implicit architecture and social dynamics in a group. Ranking, which will be further discussed in chapter 6, is a good example of this. We usually see that the person higher in rank (e.g., CTO, CEO, architect, but also developers who are in the company the longest or know the most) makes a decision that eventually lacks buy-in from the group. Because that person is perceived to have a higher rank, many people choose to stay quiet and work with—or around—the decision. This could result in conflict, polarities, and people ignoring the decision when implementing the design.

The same happens when design decisions are being made, but not everyone understands them. It might lead to lower buy-in, and groups will find themselves cycling back to those decisions over and over again. Be mindful that these sorts of decision-making processes will likely initiate resistant behavior: sarcastic jokes, gossiping, or communication breakdown, for example. These resistant behaviors indicate there is something lingering in the shadows of the group. When not dealt with properly, this will grow and hinder progress. We’ll discuss resistance and how to manage it further in chapter 8.

Hopefully, it’s clear now how bad design decisions can affect the social dynamics in a group and how that influences the (implicit) architecture. Some very negative consequences also become visible when implementing the design, including the following common ones:

-  Not being able to add new functionality
-  Adding new functionality takes much longer
-  Longer push-to-production time
-  More bugs because developers [](/book/collaborative-software-design/chapter-3/)need to write hacks

##### Our take on technical debt

Technical debt is often perceived negatively, typically linked to implicit architectural decisions. However, this perspective may be overly narrow. Technical debt isn’t merely about *cruft*, which is poorly written or redundant code. Rather, we view technical debt as a result of a conscious, explicit architectural decision. This happens when you knowingly introduce less-than-ideal design and code to deliver value more quickly. In doing so, you create a debt, similar to a financial obligation, that needs to be repaid over time. It’s essential to distinguish between cruft arising from technical debt and that which comes from implicit design, possibly due to a lack of skill or awareness. With an explicit decision, you’re looking ahead, including stakeholders in the decision-making process, and acknowledging the potential risks and consequences. In contrast, implicit architectural decisions lead to unintended cruft, which can bring unexpected risks and consequences. Such scenarios often cause frustration, especially toward developers, when efficiency begins to suffer. In the end, cruft is inevitable, but recognizing cruft as part of technical debt, especially when it’s deliberate, makes it less difficult to manage.[](/book/collaborative-software-design/chapter-3/)[](/book/collaborative-software-design/chapter-3/)

This is what you want to avoid and that starts with making better design decisions. Collaborative modeling is a good starting point to make explicit which decisions need to be made, how these decisions could possibly affect the architecture and social dynamics, what alternative views are available, and what it takes for people to go al[](/book/collaborative-software-design/chapter-3/)ong with a decision.[](/book/collaborative-software-design/chapter-3/)[](/book/collaborative-software-design/chapter-3/)[](/book/collaborative-software-design/chapter-3/)

## 3.2 Heuristics for collaborative modeling

The previous sections explained what software architecture and design entails, why we need to approach this from a sociotechnical perspective, and design decisions in collaborative modeling. In this section, we’ll dive a bit further into some of the (group) processes that you can encounter during these sessions. For example, did you ever get the feeling during a (collaborative modeling) session that you’re stuck and don’t know what the next step should be? That’s a common state in most sessions we’ve been a part of. Discussions on where the boundary should be, removing duplicate stickies because someone assumes it’s a duplicate, and conversations that go in completely different directions are all examples of situations that can occur during collaborative modeling and that require a decision to make progress. What do you do in these kinds of situations? Through experience, you build up simple rules—*heuristics*—that can help you make decisions. When talking about heuristics, we like to use the following definition: [](/book/collaborative-software-design/chapter-3/)[](/book/collaborative-software-design/chapter-3/)

##### Definition

A *heuristic* is a simple rule to help you make a (quick) decision.

Note that heuristics are based on experience. You’ve learned what works and what doesn’t from experience in facilitating collaborative modeling sessions. Some heuristics are more universal and are effective across groups; others are group specific. As a facilitator, it’s important to keep your box of heuristics flexible and open for suggestions. Heuristics can make you feel more comfortable and secure in situations that aren’t comfortable and secure. They can guide you, based on experience, to the next step. In this section, we’ll dive into heuristics and how to use them during collaborative modeling sessions.

Remember that the practices and techniques outlined in this book are intended as guidance. The same is true for heuristics. Think of them in the same way you would approach a cooking recipe. You might not follow the recipe exactly; you could add more garlic, for example, if you have a preference for a stronger garlic flavor. Similarly, in each session you facilitate, it’s necessary to adjust the “ingredients” to ensure its success. Heuristics can provide enabling constraints and inspiration, but the specifics will differ for each session. It’s important to initially use heuristics from others as they are, much like following a recipe for the first time, before modifying them to suit your own needs. In this section, we’ll present some example heuristics that have been[](/book/collaborative-software-design/chapter-3/) gathered over the years.

### 3.2.1 What are heuristics?

Heuristics help us make progress. Based on previous experience and learning, we’ve gathered some sort of toolkit that we can use in particular situations. You can imagine that this could be very useful during collaborative modeling sessions, but it goes beyond that area. For example, when I go to the supermarket to buy groceries, I use heuristics, such as “Get nonfrozen stuff before frozen stuff.” This is a very simple example, but it helps me tackle the problem of buying groceries in an optimal manner. Collaborative modeling sessions are much more complex than buying groceries, of course, and heuristics are even more useful there. As mentioned, heuristics are simple rules to make quick decisions.[](/book/collaborative-software-design/chapter-3/)[](/book/collaborative-software-design/chapter-3/)

A very important aspect of the definition of heuristics is the focus on decision-making. Heuristics work in situations where a decision is needed. Are we putting this boundary here or there? Are we going to discuss this diverging topic together or in a smaller group? When facing situations like this, heuristics help us make quick decisions. Note that a decision implies conscious action. A decision without action is just an intention. We’ll dive further into decisions and decision-making in chapter 9.

Another important thing to note here is that using heuristics doesn’t necessarily provide worse results than you would have when doing a deep and detailed analysis of the situation. Think about an emergency room; doctors use heuristics to determine if your situation requires immediate and urgent action, or if you can wait. They simply don’t have time to complete a deep analysis of your situation. Instead, doctors use heuristics they gained from previous knowledge and experience, which provides them with proper results.

The same goes (to some extent) for collaborative modeling sessions. No matters of life and death here, but the time constraint is similar. During these sessions, there’s usually no time to do a deep analysis before making a decision. Based on what you know and have experienced in the past, you know that it’s probably best to do A (or B, or C) in that particular situation. It enables decision-making and therefore progress, which is what’s needed at that moment. Different situations and goals require different types of heuristics. Let’s explore these types and [](/book/collaborative-software-design/chapter-3/)dive into some examples.

#### Different types of heuristics

Heuristics aren’t extensive rule-based phrases, but short sentences and reminders that help you take the next step in tackling a problem. Based on experience, you’ve learned that in situation A, it might be helpful to do B, unless C is the case. Or, it might help to try X before Y in situation Z. For example, if it’s raining outside, it might be helpful to bring an umbrella, unless there’s a very strong wind too. This has a lot to do with common sense, but it’s how heuristics work. They live in people’s heads and are very often used unconsciously. Imagine how much groups, teams, and organizations could benefit from collecting, documenting, and sharing all the heuristics that exist within a group of people. When thinking about our BigScreen company, a heuristic might be “If I want to buy a ticket via the app, it might be helpful to have my credit card information at hand.”[](/book/collaborative-software-design/chapter-3/)[](/book/collaborative-software-design/chapter-3/)

We use three types of heuristics ([https://dddheuristics.com/](https://dddheuristics.com/)):

-  *Design heuristics*—Heuristics we use to design software
-  *Guiding heuristics*—Heuristics that guide o[](/book/collaborative-software-design/chapter-3/)ur use of other heuristics (i.e., meta-heuristics)
-  *Value-based heuristics*—Heuristics that determine our attitude and behavior toward design (or the world) and the way we work

Because we’re talking about design and architecture, you can imagine that the design heuristics are crucial. When designing a system or architecture, you have to solve various specific problems. Because most of us do this more than once, a lot of design heuristics are probably already lying around and (un)consciously being used when designing. Here are a couple of design heuristics that we regularly use: “Align with domain experts on boundaries,” “Design bounded contexts by looking at the humans during a big picture EventStorming,” and “Align bounded context with the domain experts.” The list of (personal) design heuristics is constantly growing and evolving, and we try to share them with o[](/book/collaborative-software-design/chapter-3/)thers as much as possible.

#### The Bounded Context Pattern

We mentioned the bounded context pattern when we explained DDD in the previous chapter. If you’re not familiar with a bounded context, Eric Evans describes the pattern as a boundary (typically a subsystem, or the work of a particular team) within which a particular model is defined and applicable (see Evans’s book, *Domain-Driven Design: Tackling Complexity in the Heart of Software* [Addison-Wesley Professional, 2003]). He described the pattern because he observed that large projects often have multiple models due to varying user needs, independent team approaches, or different tool sets. Combining distinct models can lead to buggy software and communication confusion. A bounded context ensures clarity by providing a boundary where terms and concepts have unambiguous meanings, preventing model mix-ups and allowing independent evolution.[](/book/collaborative-software-design/chapter-3/)[](/book/collaborative-software-design/chapter-3/)

Let’s think about one of the most crucial parts of collaborative modeling sessions: designing boundaries. It’s also a very hard part. A lot of the conversations during the sessions revolve around boundaries. Where do we put them? What’s in, what’s out? Who’s responsible for this? Where are the dependencies? Very often, this is a conversation around designing bounded contexts. We work out how design heuristics work for BigScreen in section 3.3.1, where we’ll do an extensive deep dive into design heuristics. Heuristics are very useful here, especially design heuristics. One design heuristic that can help here is “Find the natural boundaries in the domain.” It gives you a starting point in making decisions and moving on.

What hopefully stands out to you is that heuristics can be used to drive the design and handle smaller design decisions. They can help tackle specific problems within a potential bigger design problem. That’s why heuristics are so valuable during collaborative modeling sessions; they are pragmatic and focused on a specific problem at hand, which helps the group in taking the next step instead of circling back to recurring topics without making decisions.

The guiding heuristics are used when we’re approaching a problem and feel the need for structure. What do we need to do now? What’s the next step? How could we use all the heuristics we have at hand to make progress? We use them when we need some sort of plan that guides us in our endeavors and comforts us that we’re doing the right thing. That feeling, or need, very often arises during collaborative modeling sessions—especially when you[](/book/collaborative-software-design/chapter-3/)’re facilitating a session.[](/book/collaborative-software-design/chapter-3/)

#### Heuristics for the facilitator in collaborative modeling sessions

Following are some example situations that you can run into during collaborative modeling sessions where heuristics are very helpful: [](/book/collaborative-software-design/chapter-3/)

-  You sense that not everything is said that needs to be said within the group.
-  You sense that some people aren’t comfortable speaking up, increasing the risk of suppressed knowledge.
-  Discussions, conflicts, or polarities start to arise.
-  You sense frustration during a Big Picture EventStorming session because the storyline doesn’t seem to get structured enough.

The first three example situations can be very uncomfortable and frustrating because they are mainly implicit, can be sensitive, and can hold back progress. When encountering situations like these, one of our go-to heuristics is the f[](/book/collaborative-software-design/chapter-3/)ollowing:

##### GUIDING HEURISTIC

Do sensemaking to test your assumptions.

*Sensemaking* is a low-key, nonjudgmental exercise to get the group’s perspective on a certain topic. It will trigger conversations and allow the minority or alternative perspective to be brought up. We’ll dive into sensemaking in more detail in chapter 4. Arising conversations on alternative perspectives trigger another heuristic:[](/book/collaborative-software-design/chapter-3/)[](/book/collaborative-software-design/chapter-3/)

##### GUIDING HEURISTIC

Ask the group who feels they can relate to or recognize even a part of what was just discussed.

People often recognize parts of alternative views. By making that explicit, the conversation will feel safer and easier.

During a Big Picture EventStorming session it is also common to find these situations. After the chaotic exploration part of Big Picture EventStorming, you can have 100+ Domain Events on your paper roll. Now what? How do you structure that in a nonfrustrating way? Let’s clarify with an example conversation from one of our sessions that starts after everyone put their stickies on the brown paper, and we start enforcing the timeline:

Us: Okay, so the next step is to enforce a timeline here. We have all these Domain Events on stickies, and now we have to create one logical timeline out of them. This also includes getting rid of the duplicates. We’ll leave it up to you to decide how you want to do this.

Ralph: Right, so how many days do we have to do this? Ha ha!

Wei: Maybe we can start with the end and work our way backwards?

Rick: We could, but the essence and challenges are in the middle part. I don’t really care about the last part to be honest. It’s about getting the middle part right because that’s where our real problems are.

Ralph: That’s not true Rick. Maybe for you it is, but I’m stuck in pointless meetings about that last part more than I would want. Plus, starting in the middle doesn’t feel right.

Us: Is there anyone who feels they can relate to or recognizes even a part of what Ralph is saying?

Susan: I do. I know the marketing part at the end is not the most technical and probably not the most interesting for many people here, but there are a lot of dependencies we have to deal with there. So, for me, it would be very valuable to dive into that part.

Ralph: It’s absolutely interesting. For everyone here. I think we could all learn a lot from what you put on the brown paper.

Rick: Ok, never mind. I’ll shut up then . . . let’s start there then, since it’s so important. Which Domain Event is first?

Wei: This feels off. It feels a bit condescending to be honest, Rick. The point of us being here is to get to a shared understanding, right? So that means we have to address all the parts of this process and that they are equally important.

Us: Who might partially agree with this statement?

*Everybody raised their hand*.

Us: Okay, so if we all partly agree with that, then we suggest we divide this process. We can make a first division in stickies. We do that by identifying two Domain Events that are key. Once we have them, we can move all stickies either to the left or right of that particular event. That way, we can create subgroups who can work on parts of the timeline. No worries, we’ll converge every 15 minutes so we all stay aligned. Is that okay for the group? Great. Which Domain Event would be a good candidate to start with? Any suggestions?

This is a common conversation during collaborative modeling sessions. As facilitators at the end, we use one of our heuristics. The heuristic we often use in this case is the following:

##### GUIDING HEURISTIC

Indicate emerging pivotal events.

We use these pivotal or key events to start sorting and structuring the Domain Events. These events are very important to the group and mark a key point in the flow: only when this happens can other events happen. Domain Events can be placed left or right from a pivotal event, which can unblock the group and get them started in sorting and structuring the timeline.

These are just a couple of examples. There are many more, and the list grows as we gain experience. You might encounter a problem in which more than one heuristic seems to fit. In that case, you’re dealing with competing heuristics.[](/book/collaborative-software-design/chapter-3/)[](/book/collaborative-software-design/chapter-3/)[](/book/collaborative-software-design/chapter-3/)

### 3.2.2 Competing heuristics

Heuristics are very useful, but they can also be competing. Two or more heuristics can be valid and useful at the same time. When that happens, the *competing heuristics* push you in different directions and give different outcomes, even though they are both valid options. What to do then? Let’s illustrate with an example from an EventStorming session. When doing Big Picture EventStorming, usually there are more than 10 people in the room working on the same paper roll. Starting to enforce the timeline can be challenging with a big group of people. Effectiveness and the number of insights might go down, some people may turn quiet, and the group might feel they aren’t making progress. Two heuristics are valid here:[](/book/collaborative-software-design/chapter-3/)

##### GUIDING HEURISTIC

Create different groups between pivotal events.

##### GUIDING HEURISTIC

Add minority wisdom to the group.

Splitting up the group and enforcing the timeline between pivotal events will work in terms of progress and speed, and adding the full and minority wisdom to the group works in terms of completeness. We need the full group for this. It also allows everything to be said by creating a safe space where everyone can share what they want to share. There are also tradeoffs, however: splitting up the group might mean we’re not including minority wisdom in all parts of the timeline, and adding minority wisdom might mean we don’t finish the timeline. We want to do both—finish the timeline and add minority wisdom to all parts of the timeline—meaning our two valid heuristics are competing. What are we going to do? In this particular case, our heuristics gained nuance as our experience grew. Splitting up the group is the way to go, as long as we converge as a group every 30 minutes or so to walk through the timeline centrally. By doing so, we allow alternative perspectives to be added. By asking “Who can somewhat relate to this?” often during this convergence, we try to add the minority wisdom as much as possible to the subgroups. This is an example of how heuristics can evolve over time, especially competing one[](/book/collaborative-software-design/chapter-3/)s that recur from time to time.

#### Diverging conversations

Here’s another example to illustrate these competing heuristics: negotiating boundaries during a collaborative modeling session. A huge part of collaborative modeling is about boundaries: What’s in, what’s out? How do they relate? Do we need to design for dependencies? Because people usually have a stake in the decisions around boundaries—it affects them and their work—conflicts arise pretty easily. People or groups of people disagree with each other for various reasons that may or may not be about the content itself. As a facilitator, you have to deal with that. Two heuristics that are both valid in this situation are the following:[](/book/collaborative-software-design/chapter-3/)[](/book/collaborative-software-design/chapter-3/)

##### GUIDING HEURISTIC

Discuss conflicts with the entire group.

##### GUIDING HEURISTIC

Split and merge during diverging conversations.

These are both valid heuristics, but they compete with each other. Discussing the conflict with the entire group will take time and therefore slow down progress, with a risk of not achieving the desired modeling outcomes for that day. On the other hand, it might result in mutual understanding and trigger long-awaited conversations that needed to take place to really move on. Is it worth it to invest time in that? The other valid heuristic—“split and merge during diverging conversations”—will result in the bigger part of the group continuing with the model, which increases the chances of achieving the desired modeling outcomes for that day. The subgroup can dive into the matter at hand and share their insights later with the entire group. There’s a risk here when it comes to mutual understanding regarding the subgroup and the entire group, so what are you going to do?

From experience, you might find that when there are only two or three people in a specific conflict, it’s better to split, discuss, and visualize the conflict in a subgroup before coming back to the group. Or you might find that when a social dynamic seems to be causing the conflict, rather than the boundary itself, it’s more valuable to discuss the conflict with the entire group and even add some sensemaking exercises. What we’re saying is that a set of heuristics is never complete. You might start with a more general one and, after time, add more heuristics to make it more nuanced in a way. You can be flexible[](/book/collaborative-software-design/chapter-3/) when using the guiding heuristics.[](/book/collaborative-software-design/chapter-3/)

### 3.2.3 How to use heuristics

As previously noted, a heuristics toolkit is a personal thing. While heuristics can be shared, they are greatly influenced by your own preferences, knowledge, and experience. Ultimately, there is immense value in learning from your own experiments, trial and error, and personal reflections. Therefore, we recommend that you take time to plan before each session. Write down a few heuristics from others that you might want to apply in the upcoming session, focusing on one or two to integrate into your facilitation. Gradually incorporating these heuristics can be very effective. We also suggest starting a heuristic journal. After every session, whether you participate or facilitate, take a moment to record your observations and experiences. What did you notice? How did the group dynamics unfold? From these insights, you can develop your own heuristics, which will evolve and become more intuitive over time. Initially, you may find yourself referring to your journal often during sessions. However, as you gain experience, you’ll likely find that certain heu[](/book/collaborative-software-design/chapter-3/)ristics become second nature to you.[](/book/collaborative-software-design/chapter-3/)[](/book/collaborative-software-design/chapter-3/)

##### Exercise 3.1: Get started with using heuristics

To get you started and encourage you to adopt the new habit of starting a heuristics journal, we’ll provide some of our own heuristics at the end of every chapter. Another important insight from this section is that heuristics can drive the design. Using design heuristics can help you with designing boundaries, for example. In the next section, we’ll explain how design heuristics can be used to make design decisions by continuing with our BigScreen journey. [](/book/collaborative-software-design/chapter-3/)

To get started with your own heuristics journal, try to capture personal heuristics you use during sessions. These can be collaborative modeling sessions, programming, workshops, or any other. Reflect on decisions you make to maintain flow and get to the next step. Write them down, and reflect on them some more and attempt to generalize them. You can use the heuristics we provide at th[](/book/collaborative-software-design/chapter-3/)e end of the chapters as inspiration. [](/book/collaborative-software-design/chapter-3/)[](/book/collaborative-software-design/chapter-3/)

## 3.3 Driving the design by understanding the business

In the previous chapter, we explained how to get better at understanding the business and the business problems. To understand the business better, we create models of those problems through collaborative modeling with the domain experts. Now, the hard part is finding a fitting and sustainable design and architecture.[](/book/collaborative-software-design/chapter-3/)

Let’s start with some bad news: there is no perfect solution and no one way to model a system. We know, it’s difficult to read this; it took us a long time to accept this too. To be honest, on a bad day, we’re still desperately looking for that perfect model, and we believe that’s normal, if you really think about this part of the job we’re performing. It has fancy titles, such as software designer, senior architect, and so on, as well as fancy (-ity) words such as flexibility, scalability, and extensibility, to describe the system’s characteristics we’re trying to achieve. Honestly, a more fitting job title would be *clairvoyant*:

-  *Why do we need flexibility?* Because companies change, and the system has to change with them.
-  *Why do we need scalability?* Because companies grow, and the system has to grow with them.
-  *Why do we need extensibility?* Because the companies evolve, and the system has to evolve with them.

You get the idea. So why would clairvoyant be a better description? Basically, we’re trying to predict the future. We don’t know how companies will change, we don’t know what will change, and we don’t know when this change will happen. There is a lot of uncertainty when creating software systems, and the only certain thing is that there will be change, which is why there is no perfect solution or correct way to model a system.

And now for the good news! Many great people in our field have done research into software architecture and its characteristics. One of the important things to do in a software system is create explicit boundaries. You can achieve that by dividing the business model into smaller parts. Breaking the business model into smaller parts is often referred to as *modularity*. There are different levels of modularity in a system, but here we’ll talk about the creation of deployable units. A *deployable unit* is a component of the system that can be tested and deployed to production independently, for example, a microservice. Before we can create our deployable units, we need to design boundaries for the business model. Modularity is so important because it’s both a characteristic and an enabler of other architecture characteristics. This is why you have to investigate and explore how you can break up your business model into smaller parts. In this s[](/book/collaborative-software-design/chapter-3/)ection, we’ll dig a bit deeper into that.[](/book/collaborative-software-design/chapter-3/)[](/book/collaborative-software-design/chapter-3/)

### 3.3.1 Designing boundaries

In chapter 2, we mentioned that we go from the problem space to the solution space by performing a number of design activities. If we zoom in on those design activities, we’re doing a number of iterations on our bounded contexts. We do a variety of design activities to work toward this deeper understanding of where the boundaries are in our software system. Designing the first boundaries, Iteration 1 in figure 3.2, relies on intuition. While heuristics are specific mental shortcuts with identifiable patterns, *intuitions* are more general feelings or judgments. But intuitions might sometimes be the result of internalized heuristics, which you apply unconsciously, wh[](/book/collaborative-software-design/chapter-3/)ile drawing the first bounded contexts.[](/book/collaborative-software-design/chapter-3/)

![Figure 3.2 Zooming in on the design activities, we can see that this is an iterative process where we design toward a deeper model. In each iteration, the model captures more of the complexity of the domain. Sometimes, we can identify the bounded context as the Core, Supporting, or Generic domain, and sometimes one emerges that we can’t identify yet (Emerging).](https://drek4537l1klr.cloudfront.net/baas/Figures/CH03_F02_Baas.png)

The more experience and heuristics you use, the better your intuition will become. In other words, the collection of heuristics that you unconsciously apply during that first iteration will grow. But don’t worry, we’re giving you an intuition starters kit called “Find the natural boundaries in the domain” to help.

#### Intuition starters kit

“Find the natural boundaries in the domain” is a high-level heuristic, which encapsulates several other heuristics, as shown here, in the intuition starters kit. When starting out on your own, this high-level heuristic isn’t useful on your own because you are still building your intuition. That’s where the intuition starters kit heuristics that you can apply to find the natural boundaries. The more experience you have designing boundaries and using heuristics, the more heuristics you’ll apply when you say “Let’s find the natural boundaries.”[](/book/collaborative-software-design/chapter-3/)[](/book/collaborative-software-design/chapter-3/)[](/book/collaborative-software-design/chapter-3/)

##### Design Heuristic

Find the natural boundaries in the domain.

The intuition starters kit includes the following heuristics, which will allow you to be successful in using the “find the natural boundaries in the domain” heuristic:

-  Split according to the language
-  Split according to the departments
-  Split according to the actors

Let’s apply the intuition starters kit to BigScreen. In figure 3.3, you can see a small part of[](/book/collaborative-software-design/chapter-3/) the Big Picture EventStorm of BigScreen.

![Figure 3.3 A small part of the EventStorm on purchasing tickets with a legend. The output of an EventStorming session, which happens in the problem space, will be used as the input for our design activities. Those design activities will give us bounded contexts for our solution space. (Note: An EventStorm normally appears on just one line as shown at the top of the figure here, but to fit the page and make it readable, we set the EventStorm on two lines.)](https://drek4537l1klr.cloudfront.net/baas/Figures/CH03_F03_Baas.png)

[](/book/collaborative-software-design/chapter-3/)We created two bounded contexts in our first design iteration (figure 3.4): Movie Scheduling and Ticket Purchasing. To create these boundaries, we applied design heuristic “Split according to the language.” When we look at the language, we notice that movie scheduling talks about how our users search for a movie. Once they pick a specific movie, in a specific theater, at a specific day and time, they start the process of purchasing tickets. So, until we have our Domain “Event 4 Normal Pricing Selected,” we’re searching for movie scheduling. Before that, a ticket didn’t exist. So, we split the EventStorm right before Domain Event “4 Normal Pricing Selected,” where the concept of a tick[](/book/collaborative-software-design/chapter-3/)et exists, and we create two boundaries.

Of course, we could have picked heuristic “Split according to the departments” or heuristic “Split according to the actors” from the starters kit and had a different starting point, or we could have applied all three at once and gotten a lot more bounded contexts (which is what you do when you have a lot more experience). The important thing is that you pick one, apply it, and start your second iteration. A lot of participants in our collaborative modeling sessions fall into the trap of starting to discuss what bounded context there can be instead of modeling them out in iterations. They ask each other, “How many bounded contexts should we have?” or “What should they be, and are they correct?” This leads us to a guiding heuristic to use during your design activities:

##### GUIDING HEURISTIC

Pick some boundaries to start with and iterate.

![Figure 3.4 BigScreen’s natural boundaries. We picked one of our heuristics from our intuition starters kit and applied it to the EventStorm, creating two bounded contexts: Movie Scheduling and Ticket Purchasing. This way, we have a starting point to dig deeper with other design activities.](https://drek4537l1klr.cloudfront.net/baas/Figures/CH03_F04_Baas.png)

So that is what we did in BigScreen. If we dig a bit deeper, we notice the Payment Details Provided and Payment Completed events. Remember our business model canvas? We said that payment providers are key partners, so these events don’t happen in our system, but in the system of the payment providers. We have to communicate with that external system and translate their ubiquitous language into our language. This is true for all communication that happens with external systems, so a good design heuristic is the following:[](/book/collaborative-software-design/chapter-3/)[](/book/collaborative-software-design/chapter-3/)

##### DESIGN HEURISTIC

Communication with external systems happens in a separate bounded context.

In figure 3.5, you can see how the BigScreen EventS[](/book/collaborative-software-design/chapter-3/)torm looks when applying that heuristic.

![Figure 3.5 BigScreen’s external systems communication is encapsulated in a new bounded context called Payments.](https://drek4537l1klr.cloudfront.net/baas/Figures/CH03_F05_Baas.png)

As mentioned earlier, while designing the boundaries of our system, we have to take the business and its future into account. We don’t know how things will change, but the business has a better understanding of that. The company might not know how it will change but can see the potential value of some business processes. This leads us to another design heuristic:[](/book/collaborative-software-design/chapter-3/)[](/book/collaborative-software-design/chapter-3/)

##### DESIGN HEURISTIC

Optimize for future potential.

Understanding the future potential is something you need to learn from your domain experts. You can optimize for the future, but only the domain experts can tell you if this has potential from a business perspective.

If we look at BigScreen again, where would the future potential be? We had two ideas for that: where the prices get calculated and where the seats get allocated. We spoke with the business and explained how we could change the pricing model and the seat allocations model in the future.

For the pricing model, right now, BigScreen doesn’t offer subscriptions yet, but the idea is floating around in the office. Some theaters are struggling because there aren’t many movie viewers, and even the blockbusters aren’t doing well. We’re unsure how subscriptions would work, but we do know that there could be multiple subscriptions similar to the ticket pricing, and the domain experts told us it’s worth testing subscriptions in those theaters that aren’t doing well. So, first, we put that in a different bounded context: Price Calculation.

Second, the system suggests seats to the customers. Right now, this is a very simple flow that doesn’t take the customers preferences into account, and we told them we could change that. If we change the seat allocations algorithm to take customer preference into account, we wouldn’t have to perform it so often, *and* customers could purchase tickets quicker because they don’t have to change seats. We want to start collecting data on this to be able to analyze how often customers change their seats. The domain experts liked our suggestion but said this wasn’t something we should try to do this year because the “Anytime, Anywhere” campaign was more important. We agreed, but we introduced a bounded context called Seat Allocations, to make sure we could implement this easier when the time was right.

[](/book/collaborative-software-design/chapter-3/)We also changed the name of the Ticket Purchasing bounded context to Ticketing because the logic inside this boundary now focuses on creating and sending out tickets to our movie viewers and not on purchasing a ticket. We now have five boun[](/book/collaborative-software-design/chapter-3/)daries in total, as shown in figure 3.6.

![Figure 3.6 BigScreen’s future potential bounded contexts: Price Calculation and Seat Allocations. We also renamed the Ticket Purchasing boundary to Ticketing because the business logic inside this boundary is about creating and sending out tickets.](https://drek4537l1klr.cloudfront.net/baas/Figures/CH03_F06_Baas.png)

Introducing a separate boundary for price calculation means more communication happening between bounded contexts because Seat Allocations, Ticketing, and Price Calculation have a dependency on each other. We have another design heuristic in our toolkit that pushes us in a different direction:

##### DESIGN HEURISTIC

Split bounded contexts based on how it would happen in a paper world, without using software.

In a “paper” world, before we digitized ticket purchases, you went to the cinema and purchased your tickets when you arrived. Calculating the price was done manually with premade tickets, similar to the ones from those rolls you get when entering a raffle. With this heuristic, we would not separate the Price Calculation from the Ticketing bounded contexts. We only have two bounded contexts called Ticket Purchase and Seat Allocations, as shown in figure 3.7. These are the competin[](/book/collaborative-software-design/chapter-3/)g heuristics we spoke about previously.[](/book/collaborative-software-design/chapter-3/)

![Figure 3.7 BigScreen’s paper process bounded contexts. Price calculating and ticketing are one bounded context instead of two, called Ticket Purchase.](https://drek4537l1klr.cloudfront.net/baas/Figures/CH03_F07_Baas.png)

How do we select one of the options now? First, we see if we have any other design heuristics in our toolkit that could help us decide. Second, we look for the tradeoff that both designs give us. If we pick the design in figure 3.7, there would be fewer dependencies between bounded contexts, but Ticket Purchase would have more internal business logic and dependencies, increasing the local complexity of the bounded context. If we pick the other one (refer to figure 3.6) there is a higher global complexity in the system because we have more dependencies between bounded contexts, but less local complexity for both bounded contexts. Which tradeoff is better? That depends (sorry)—we would need to dig deeper into the teams, the business, and so on to answer that question. One thing’s for sure, though, [](/book/collaborative-software-design/chapter-3/)we can’t answer that question on our own.

##### Exercise 3.2: Your current bounded contexts

In the previous chapter, you created an EventStorm for one of your own scenarios. In this exercise, you’ll us[](/book/collaborative-software-design/chapter-3/)e the output of exercise 2.2 to apply the intuition starters kit. Apply the heuristics from the starters kit to your EventStorm by drawing boxes around the stickies that fit together. Give the boxes a different color for each bounded context, as we did in our examples from BigScreen.[](/book/collaborative-software-design/chapter-3/)

When you’ve applied the heuristics, try to find names for the bounded contexts that you discovered. Look at the stickies inside the [](/book/collaborative-software-design/chapter-3/)boundaries to come up with a fitting name.[](/book/collaborative-software-design/chapter-3/)[](/book/collaborative-software-design/chapter-3/)

### 3.3.2 Why boundaries are designed through collaboration

When designing boundaries, there are a lot of different perspectives that you need to take into account. In our BigScreen examples, we mostly focused on the business value. We didn’t think about the user experience, the technical constraints, and so on. We still need to put on a lot of different thinking hats to come to a good design. One person can’t do this on their own, which is why designing boundaries also happens in collaboration. We can approach these modeling sessions a bit differently though. We start with a few iterations on the design with just the people who are directly involved in creating the software system. Afterward, we can validate the outcome of those iterations with the other stakeholders. We take their feedback and start iterating again. Slowly, a better model will arise throughout this process because we gain insights and a deeper understanding.[](/book/collaborative-software-design/chapter-3/)

So far, we’ve used EventStorming as a tool to design the boundaries. There are different tools that you can use here too. If you want to know how commands and events will flow through the system, you can use a *domain message flow diagram* (figure 3.8), which is based on Domain Storytelling[](/book/collaborative-software-design/chapter-3/) but specific to bounded context design.

*Context mapping* will give you another visualization, which mainly focuses on the models, language, and team communication between bounded contexts ([https://github.com/ddd-crew/context-mapping](https://github.com/ddd-crew/context-mapping)). All those visualizations will give you new insights and new tradeoffs to consider when designing. A design is never finished, but you have to start building it anyway at some point. In chapter 10, we’ll go into that [](/book/collaborative-software-design/chapter-3/)polarity between designing and implementing. *[](/book/collaborative-software-design/chapter-3/)*

![Figure 3.8 Example of a domain message flow diagram, a modeling tool created by Nick Tune based on Domain Storytelling but specific to bounded context design. You can learn how to use this tool at https://mng.bz/Ddyg.](https://drek4537l1klr.cloudfront.net/baas/Figures/CH03_F08_Baas.png)

### 3.3.3 From design to architecture

Many people think that designing your bounded contexts is the only design activity needed to create the architecture of a system, but nothing is further from the truth. An architecture is more than the bounded contexts. This isn’t a book on architecture, so we won’t go into a lot of detail here, but we do want to show you the relationship between bounded contexts and deployable units (and sneak in some more heuristics for your journal).[](/book/collaborative-software-design/chapter-3/)[](/book/collaborative-software-design/chapter-3/)

Looking at the current architecture of BigScreen’s software system in a bit more detail (figure 3.9), we can see that it has multiple domains, a single [](/book/collaborative-software-design/chapter-3/)bounded context, and one deployable unit.

Taking the newly designed bounded contexts in mind, a possible archi[](/book/collaborative-software-design/chapter-3/)tecture could be as shown in figure 3.10.

Notice that deployable units and bounded contexts don’t have a 1:1 relationship. Depending on the size or the dependencies, bounded contexts can align with a deployable unit, but they are different concepts. Bounded contexts are linguistic boundaries, where deployable units are boundaries of deployment. You can have multiple deployable units for one bounded context, but we don’t advise that. If you create multiple deployable units from a single bounded context, those deployable units will have a high chance of being changed together because the logic elements inside a bounded context are dependent on each other. On the other hand, you can put multiple bounded contexts into a single deployable unit, often nowadays referred to as a modular monolith (the rebranding was needed because, in the past, people didn’t implement the monolith architecture correctly, so that got tainted). Don’t make a deployable unit too big though, or you’ll start losing adaptability and scalability.

![Figure 3.9 Detailed current architecture of BigScreen. This architecture has a single bounded context, which is Big Ball of Mud, and a single deployable unit. This type of architecture is referred to as a monolith. A monolith isn’t a bad architecture style, but the problem is that we’re lacking a clear architecture and boundaries. If we put the domain boundaries on top, you can clearly see the problem.](https://drek4537l1klr.cloudfront.net/baas/Figures/CH03_F09_Baas.png)

[](/book/collaborative-software-design/chapter-3/)Sometimes, changes affect multiple bounded contexts, so you deploy the bounded contexts that change together. This leads us to another helpful design heuristic:

##### DESIGN HEURISTIC

What changes together, gets deployed together.

This heuristic is derived from a more generic heuristic. We use this more generic heuristic when we look for bounded contexts: “The business logic that changes together, stays together.” Another heuristic that you can apply when looking for bounded contexts is the following:

##### DESIGN HEURISTIC

What changes together, stays together.

![Figure 3.10 New architecture for BigScreen, designed via collaborative modeling. This architecture captures the complexity of the domain with multiple bounded contexts and deployable units. Price Calculation, Payments, and Seat Allocations bounded contexts align one-to-one with a deployable unit. User Interface and Ticketing are two bounded contexts in one deployable unit. PaS and Movie Scheduling are a single domain but are in two deployable units. This architecture makes the “Anytime, Anywhere” campaign possible.](https://drek4537l1klr.cloudfront.net/baas/Figures/CH03_F10_Baas.png)

[](/book/collaborative-software-design/chapter-3/)We split Ticket Purchase into two different bounded contexts—Price Calculation and Ticketing—because it was more valuable to the business to have the pricing separate. While creating deployable units, we can decide to deploy them together, as long as it makes sense. If two years from now, we’re still deploying them together, we can decide to merge the bounded contexts (this is also a heuristic).

One last thought before we move on to the next chapter: during this exercise, we focused on a very small part of the business. Big Picture EventStorming stays at a very high level. Because of that, the bounded contexts and architecture are simplified. Should we build the actual system of BigScreen, we would stay much longer in the problem space and dive much deeper into understanding the problems. We would also spend a lot more time on designing the bounded contexts before we used [](/book/collaborative-software-design/chapter-3/)the design as input for the solution space.[](/book/collaborative-software-design/chapter-3/)

## 3.4 Collaborative software design catalysts

-  During a meeting, it’s beneficial to ask the following: “What do you mean by *X*?” where *X* represents a business-specific term. A lot of confusing communication can be resolved by creating a shared understanding of domain-specific concepts.[](/book/collaborative-software-design/chapter-3/)
-  During collaborative modeling, it’s beneficial to make assumptions, questions, and conflicts clear by jotting them down on a sticky note.
-  Aim to extract and clarify people’s heuristics from their assumptions, questions, and suggestions for a good design. This practice of making heuristics ex[](/book/collaborative-software-design/chapter-3/)[](/book/collaborative-software-design/chapter-3/)plicit can be a valuable part of the process.[](/book/collaborative-software-design/chapter-3/)

## 3.5 Chapter heuristics

[](/book/collaborative-software-design/chapter-3/)As mentioned, we’ll start collecting our personal heuristics at the end of every chapter. These can serve as inspiration for you to start your own journal. Feel free to use, edit, and complement them as you please. [](/book/collaborative-software-design/chapter-3/)

*Design heuristics*: *heuristics to solve a specific problem*

-  Split according to the language.
-  Split according to the departments.
-  Split according to the actors.
-  Communication with external systems happens in a separate bounded context.
-  Optimize for future potential.
-  Split bounded contexts based on how it would happen in a paper world, without using software.
-  What changes together, gets deployed together.
-  What changes together, stays together.
-  If we’re still deploying the bounded contexts together after two years, we merge them into one.

*Guiding heuristics: heuristics that guide our use of other heuristics* (*i.e., meta-heuristics*)

-  Do sensemaking to test your assumptions.
-  Ask the group who feels they can relate to or recognizes even a part of what was just discussed.
-  Indicate emerging pivotal events.
-  Create different groups between pivotal events.
-  Add minority wisdom to the group.
-  Discuss conflicts with the entire group.
-  Split and merge during diverging conversations.

## 3.6 Further reading

-  *Adaptive Systems with Domain-Driven Design, Wardley Mapping, and Team Topologies: Architecture for Flow* by Susanne Kaiser (Pearson Education, 2024)[](/book/collaborative-software-design/chapter-3/)[](/book/collaborative-software-design/chapter-3/)
-  *Architecture Modernization: Socio-Technical Alignment of Software, Strategy, and Structure* by Nick Tune with Jean-Georges Perrin (Manning, 2024, [www.manning.com/books/architecture-modernization](https://www.manning.com/books/architecture-modernization))
-  “Are software patterns simply a handy way to package design heuristics?” by Rebecca Wirfs-Brock (PLoP ‘17: Proceedings of the 24th Conference on Pattern Languages of Programs)
-  *Design and Reality* by Rebecca Wirfs-Brock and Mathias Verraes (Leanpub, [https://leanpub.com/design-and-reality](https://leanpub.com/design-and-reality))
-  *Learning Systems Thinking* by Diana Montalion (O’Reilly Media, 2024)
-  *System Design Heuristics* by Gerald M. Weinberg (Leanpub, [https://leanpub.com/systemdesignheuristics](https://leanpub.com/systemdesignheuristics))
-  *Thinking in Systems: A Primer* by Don[](/book/collaborative-software-design/chapter-3/)ella H. Meadows (Chelsea Green Publishing, 2008)
-  “Traces, tracks, trails, and paths: An Exploration of How We Approach Software Design” by Rebecca Wirfs-Brock (PLoP ‘18: Proceedings of the 25th Conference on Pattern Languages of Programs)

## Summary

-  Software design and architecture are inevitable in development, with “bad design” often arising from implicit, misunderstood, or unmade decisions. Making these aspects explicit through collaborative modeling is key to managing complexity and ensuring shared understanding within teams.
-  Language and definitions play a critical role in collaborative modeling, highlighting the importance of establishing a shared vocabulary to prevent misunderstandings and streamline decision-making processes.
-  BigScreen’s shift to Agile methodologies revealed challenges in adapting to up-front architecture, emphasizing the need for software teams to be trained and take ownership of software architecture to avoid bottlenecks and foster iterative development.
-  Sociotechnical systems emphasize the interconnectedness of social, technical, and cognitive components within work environments, advocating for a holistic approach to optimizing workspaces and technology decisions.
-  Collaborative modeling and design decisions within sociotechnical frameworks focus on inclusive, participatory processes, ensuring that technological advancements and workspace designs enhance rather than disrupt team dynamics and overall system efficiency.
-  Heuristics are simple rules to make quick decisions. The three different types of heuristics help you drive the design and facilitate collaborative modeling sessions based on experience and knowledge.
-  Heuristics compete when more than one heuristic is valid at the same time, but push you in a different direction. Based on tradeoffs and experience, you can decide what the outcome of both paths is and determine the best way forward.
-  Heuristics evolve and increase (in numbers) over time and experience. Keeping a journal and adding to it after every session is a great way to build your heuristic toolkit.
-  Considering various perspectives and using tools beyond EventStorming, such as domain message flow diagrams or context mapping, lead to insights and refinement.
-  Bounded contexts and deployable units shape system architecture, emphasizing adaptability and the principle of deploying together what changes together for effective design and implementation.[](/book/collaborative-software-design/chapter-3/)

---

[](/book/collaborative-software-design/chapter-3/)[1](/book/collaborative-software-design/chapter-3/footnote-003-backlink)   Meadows, *D. H. Thinking in Systems: A Primer*, 2008. London: Chelsea Green Publishing (p. 172).

[](/book/collaborative-software-design/chapter-3/)[2](/book/collaborative-software-design/chapter-3/footnote-002-backlink)   Emery, F. E., Trist, E. L., Churchman, C. W., & Verhulst, M. *Socio-Technical Systems, Management Science Models and Techniques*, 1960, vol. 2. Oxford, UK: Pergamon (p. 83–97).

[](/book/collaborative-software-design/chapter-3/)[3](/book/collaborative-software-design/chapter-3/footnote-001-backlink)   Wright, J. *The Good, the Bad, the Open-Plan: Creating Environments for Collaborative Knowledge Work*, 2019, Lean Agile, [https://vimeo.com/374629143](https://vimeo.com/374629143).

[](/book/collaborative-software-design/chapter-3/)[4](/book/collaborative-software-design/chapter-3/footnote-000-backlink)   Oosthuizen, R., & Pretorius, L. “Assessing the Impact of New Technology on Complex Sociotechnical System,” 2016, [https://mng.bz/lM0R](https://mng.bz/lM0R).
