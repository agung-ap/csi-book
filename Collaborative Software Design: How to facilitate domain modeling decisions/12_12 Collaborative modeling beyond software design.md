# 12 [](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)Collaborative modeling beyond software design

### This chapter covers

- Understanding the context through collaborative modeling with managing roles
- Collaborating with user researchers and product and engineering managers
- Moving toward implementation through collaborative modeling

We hope you’ve gotten a good understanding of why designing software requires collaborative software design with stakeholders. We also hope this book has been helpful as you take the first steps and understand how to do so. We discussed the different stages you’ll go through during collaborative modeling and what facilitation skills are needed to help the group move past certain blockers. We covered the social dynamics that come into play when bringing a diverse group of people together in a room, especially how to manage conflicts and include everyone when making software design decisions. We also demonstrated how to incorporate insights and onboard people who weren’t present during the collaboration. Additionally, we highlighted the importance of building in feedback loops to keep the decision-making process alive.

However, the knowledge we shared isn’t just useful in the domain of software design; in fact, much of the information came from the diverse fields of anthropology, behavioral science, and complexity science. So, you can imagine these skills have applications beyond software design. In this final chapter, we’ll provide examples of how collaborative modeling can be used for understanding context, mapping out strategies, and collaborating with user researchers, product owners, and engineering managers. We’ll conclude with a clear example of how to progress toward implementation.[](/book/collaborative-software-design/chapter-12/)

## 12.1 Moving toward understanding the context

[](/book/collaborative-software-design/chapter-12/)In chapter 2, we already introduced you to the Business Model Canvas as a way for a team to align with the business objectives. While many Business Model Canvases are created by management and product managers to explore their business, it also helps to include the development teams in this process. A very good example that shows the power of including teams in this process comes from Javier Fernández’s talk, “Black Ops DDD Using the Business Model Canvas” ([www.youtube.com/watch?v=M5CbbWmdsFU](https://www.youtube.com/watch?v=M5CbbWmdsFU)). He conducted separate sessions with his CEO and the development team, and then compared outcomes. This approach gave the CEO new insights into value proposition opportunities.[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)

### 12.1.1 Focusing on customer needs

Many times, we see people focusing on solutions when doing collaborative modeling. I hope this isn’t a new insight for you, but we often find ourselves falling into this sam[](/book/collaborative-software-design/chapter-12/)e anti-pattern. When you conduct a Business Model Canvas, as explained in chapter 2, with either business stakeholders or teams, you should be wary of this anti-pattern, as it can divert your discovery away from understanding the context.[](/book/collaborative-software-design/chapter-12/)

Organizations often jump to solutions based on initial perceptions. For example, they might deduce that a client wants a chatbot feature in their app. However, this approach can be restrictive—don’t get lured into that trap! It’s crucial to first understand the “value proposition” of a Business Model Canvas, which means identifying the primary benefits or unique offerings your product or service brings to the market. Simultaneously, it’s equally important to identify the “customer segment” on the Business Model Canvas, which highlights the specific demographic or group you’re aiming to serve. A deeper dive into these elements can be achieved through[](/book/collaborative-software-design/chapter-12/) a Value Proposition Canvas, as illustrated in figure 12.1, ensuring you cater directly to customer needs.

The same can happen when doing Domain Storytelling or EventStorming. When we model the process as it currently exists, the process may be designed to revolve around the current software systems. Businesses often buy software that might fit at the time, but as businesses change with the market, those software systems might wear them down. As a result, they start working around the problems with several patch processes to fix them—and don’t forget that Excel export that everyone wants! By removing the systems from EventStorming and Domain Storytelling, you’ll be able to refocus on customer needs and gain a deeper understanding of the context and business problems[](/book/collaborative-software-design/chapter-12/).

![Figure 12.1 The Value Proposition Canvas from Strategyzer. You start by filling in the customer segment before moving to the value proposition. This can be used as a base in your Business Model Canvas.](https://drek4537l1klr.cloudfront.net/baas/Figures/CH12_F01_Baas.png)

### 12.1.2 Connecting business strategy, product, and software architecture

[](/book/collaborative-software-design/chapter-12/)In the IT industry, there’s a common problem with aligning our solutions with the overall business strategy. Tools such as the Business Model Canvas can provide some guidance, but they don’t show us how our software architecture fits with the strategy. They also don’t help us adjust our software to see if it still aligns with our goals.[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)

This misalignment often leads to software systems that don’t adapt to meet the company’s strategy. When we build new systems on top of the existing ones without proper alignment, it only complicates the situation further. The systems become more intertwined and less adaptable to strategic changes. Strategies in the business world are often put into words that seem logical but don’t really help us grasp the entire situation. This leads to software systems that don’t effectively align with our strategic goals, resulting in a very rigid software architecture that is unable to accommodate business chang[](/book/collaborative-software-design/chapter-12/)es.

#### Wardley Mapping

Simon Wardley (who created Wardley Mapping) faced this problem years ago when he was a CEO. Once, an executive asked him if his strategy made sense, and he realized he didn’t know what a genuine strategy should look like. Although his strategy seemed fine and resembled others he’d seen, with familiar diagrams and wording, he later discovered that no one really understood it. Wardley compared most boardroom strategies and strategic consultancy decisions to playing chess without a chessboard. Without seeing the board, people often end up mimicking others’ moves. In business, when there’s no clear understanding of the landscape of an organization, companies tend to adopt generic strategies that have worked for others. Common examples might include embracing microservices, the cloud, the Spotify model, or a digital-first approach.[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)

But it’s difficult to discern what’s truly important for an organization without a clear view of its landscape or to know how to act based on a strategy that lacks context. How can development teams, often facing complex situations, be expected to move in the right direction? Wardley recognized this problem and created a strategy cycle, as illustrated in figure 12.2. Inspired by Sun Tzu’s *The Art of War* and John Boyd’s OODA loop, the cycle begins with mapping out the current organizational landscape. This approach seeks to provide a clearer understanding of the organizational environment, so strategies can be more tailored, relevant, and effective.[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)

##### DEFINITION

The *OODA loop (Observe, Orient, Decide, Act)* is a decision-making framework developed by military strategist John Boyd, emphasizing rapid, continuous cycles of observation, orientation, decision-making, and action to outmaneuver opponents or adapt to changing environments. It’s widely used in military, business, and other strategic fields to enhance responsiveness and effect[](/book/collaborative-software-design/chapter-12/)iveness. [](/book/collaborative-software-design/chapter-12/)

![Figure 12.2 Wardley Mapping Strategy Cycle, based on Sun Tzu’s five factors and John Boyd’s OODA loop. It includes mapping the landscape, introducing climate patterns, adding doctrine, and making decisions that create a purpose. (Source: https://mng.bz/67PZ. Licensed by Simon Wardley under a Creative Commons Attribution-ShareAlike 4.0 license)](https://drek4537l1klr.cloudfront.net/baas/Figures/CH12_F02_Baas.png)

Wardley Mapping is effective not only in the boardroom but also for other strategic decisions such as product, teams, and software architecture. It’s a powerful storytelling tool that creates a shared understanding of the current landscape and climate, where we can orient what principles to use and make collaborative decisions together. So, what exactly does Wardley mean by “landscape” in this cycle?

In chapter 10, we introduced you to the initial phase of mapping the landscape, which is the value chain as a vertical axis. We identified the users as an anchor on the map to start from. These users have needs that are fulfilled by the capabilities required to meet those needs in the organization. For user needs mapping we dived deeper in streamlets and team boundaries. For Wardley Mapping we go to the horizontal axis where we place each capability on the map in a stage of evolution. The four evolution stages are Genesis, Custom Build, Product & Rental, and Commodity & Utility. For each capability in the value chain, we collaborate on which evolution stage that capability is in based on the context of our organization.

Determining evolutionary stages collaboratively is pivotal for informed strategy and resource allocation. Different stages signal varied competitive advantages, risks, and required management practices. Recognizing a component’s stage aids in predicting its natural progression, optimizing supply chains, and tailoring operational approaches accordingly, ensuring organizations remain agile and competitive in their landscape. Different stages have different characteristics, so different approaches are needed to handle them. Let’s look at an example from BigScreen in figure 12.3 where we continued from the value chain; however, instead of looking for streamlets, we now place each capability in an evolutiona[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)ry stage.

![Figure 12.3 Step 2 of Wardley Mapping performed with the management and development teams of BigScreen. In this case, we placed each capability where the group believes the capability is in the context of BigScreen. We observed that people wondered why we will build the planning software ourselves, so we circled that with an arrow to the right and a red sticky to indicate that.](https://drek4537l1klr.cloudfront.net/baas/Figures/CH12_F03_Baas.png)

Placing the capabilities immediately raised a question: Why were we building our own planning software? We observed specific cinema rooms emerging on the map, where management could communicate that IMAX was reaching its market cap, while 4DX (movies shown with environmental effects such as seat movement) seemed to be maturing into a solid product. These insights could guide future design decisions.

Wardley Mapping involves many more steps than we cannot explain in a few paragraphs. Therefore, we advise you to visit [https://learnwardleymapping.com/](https://learnwardleymapping.com/). This website offers all Wardley Mapping resources for free and will answer many of the questions that you might still have. Make sure to read all the blogs that Simon has written about his journey, which are bundled tog[](/book/collaborative-software-design/chapter-12/)ether i[](/book/collaborative-software-design/chapter-12/)n an e-pub.[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)

#### Collaborative stressor analysis for resilient software design

Another topic to consider is *climate*, which refers to the external forces acting on your landscape. You can learn about these patterns as well at [https://learnwardleymapping.com/](https://learnwardleymapping.com/). Another tool we find useful for understanding the contextual effect of the complexity of these climate patterns is a *stressor analysis*, which comes from residuality theory by Barry M. O'Reilly.

A fundamental idea in this theory is *hyperliminality*,[1](/book/collaborative-software-design/chapter-12/footnote-004) which is an ordered system inside a disordered system. Software systems are ordered systems that are predictable, mappable, and testable, and they operate in our organization, which is the disordered system. In chapter 3, we already mentioned that a more fitting job title would be clairvoyant, because we can’t predict what will happen in that organization and the market it’s operating in. When we collaboratively design software, we’re forced to work toward an unknown future. Any event that arises in that unknown future, which the system isn’t designed for, is known as a *stressor*.[2](/book/collaborative-software-design/chapter-12/footnote-003)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)

These stressors all lead to something called an *attractor*, a limited number of states in the network’s state space to which the system will repeatedly return.[3](/book/collaborative-software-design/chapter-12/footnote-002) There is more to unfold about attractors, which were demonstrated by Kaufmann networks in 1969.[4](/book/collaborative-software-design/chapter-12/footnote-001) Different stressors may lead to the same attractor that affects our system. Even a stressor that seems irrelevant, and which we might disregard due to its low likelihood, could end up affecting the system in the same way as a stressor that we didn’t foresee. That’s why when doing stressor analysis, we ignore probability. Heck, it’s even forbidden![](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)

With a stressor analysis, we identify the stressor, understand how it affects the architecture, determine ways to detect it, and come up with ways to mitigate its effect. There are two approaches to this: One is to brainstorm as many potential stressors as you can think of and then outline their characteristics. The alternative is to start with a single stressor, fully define it, and allow additional stressors to emerge organically.

Personally, we prefer the former approach—identifying as many potential stressors first, and then assessing each one individually. Keep in mind that new stressors may surface as you delve deeper into the analysis of each one. In addition, if you can’t think of a lot of stressors, then you’re probably not dealing with a complex system.

Let’s consider an example relevant to our BigScreen: imagine everyone has purchased advanced virtual reality (VR) systems that provide a comparable audiovisual experience to that of a cinema, negating the need to visit the cinema. This scenario would affect the cinema’s ability to sell tickets. We could detect this trend through media reports and a decline in ticket sales. A potential mitigation strategy might be to begin offering VR movies on our online platform.

At some point when working out these stressors, you’ll find patterns in the stressors when a lot of the times you’ll use the same mitigation for different stressors. The stressors that lead to the same mitigation are considered attractors, which can be seen in the Wardley Mapping sense as climate patterns. Taking these mitigations into account when designing software will lead to more resilient architectures. If you want to read more, check out the blog post written by one of the authors called “Resilient Bounded Contexts: A Pragmatic Approach with Residuality Theory” ([https://mng.bz/RZWa](https://mng.bz/RZWa)).

Business Model Canvas, Wardley Mapping, and stressor analysis all require your domain experts and stakeholders to actually possess the expertise required and have an overview of the entire system. Unfortunately, we often observe companies that have a siloed organization where no one has the full picture of what the entire business actually does. If you’re faced with that situation, we always advise to start with a Big Picture EventStorming by putting all of these people in a room. From that Big Picture EventStorming, you can distill several asp[](/book/collaborative-software-design/chapter-12/)ects of your business.[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)

## 12.2 Collaborative modeling beyond software design

As mentioned before, software design is not all there is when it comes to collaborative modeling. In section 12.1, we zoomed out a bit to get a clear overview of the entire context we’re working in. The modeling part can really drag you down potential rabbit holes, so it’s good to zoom out every now and then and reconsider what it was that you wanted to achieve in the first place. [](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)

As far as context goes, it doesn’t stop there. It’s also important to consider that software design is only a small part of the entire cycle of teams and organizations. There are lots of different roles and people that are part of that bigger cycle who could also benefit from collaborative modeling. In this section, we want to zoom in on them an[](/book/collaborative-software-design/chapter-12/)d their needs a little bit.

### 12.2.1 Different roles, different modeling needs

What we talked about so far in this book mainly focuses on software design. But, as mentioned, there’s more to that story. It’s just a small part of the bigger picture that we call an organization. Plus, the things we talked about so far aren’t limited to software design as they also apply to organizational change in a more general sense. Collaborative modeling implies a variety of stakeholders together in the same room. Big Picture EventStorms can be very useful for product managers and product owners to improve the requirements gathering process, for CTOs to optimize the (global) strategy, and for UX designers to improve user journeys and customer journeys, just to name a few. One of the authors even successfully used EventStorming to plan their wedding (check out [https://mng.bz/2Kxw](https://mng.bz/2Kxw)). When a tool can even help you manage your in-laws, you can’t deny that it’s more broadly applicable than software design.[](/book/collaborative-software-design/chapter-12/)

Long story short, the different people and roles that are part of the entire context will have to do some form of collaborative modeling. They might have different needs than software developers, but they can still benefit from collaborative modeling tools. We’ll highlight a few of them to give you an idea of how to apply other forms of collaborative model[](/book/collaborative-software-design/chapter-12/)ing to meet different needs.

#### The customer journey

You may have noticed how we’ve casually referred to customer journeys and user journeys. We introduced both customer and user journeys in chapter 2. These two tools are often used interchangeably, but there are some nuances. What they have in common is that they are both visual representations of the stages that customers go through and how they interact with the company and its products. Another important similarity is that they take the perspective of the customer as the starting point.

The difference we see is that a customer journey is a more holistic representation of the broader customer experience, including touch points and channels. So, interaction with marketing, customer service, and company employees (both digital and physical) are important aspects. In the case of BigScreen, the *customer journey* represents the entire experience of customers from searching a movie to going home and reviewing the movie. A *user journey*, on the other hand, is something we more often see in product design and development. The focus in a user journey map is more on the product itself and the user’s experience with that product, that is, understanding the different steps a user takes when using the product, what their needs are, and where they can run into challenges. To us, the main difference lies thus in the focus of the different maps: the entire customer journey versus the interaction of users with a product. For now, we’ll dive more into the customer journey that BigScreen created.

[](/book/collaborative-software-design/chapter-12/)A customer journey can be an excellent starting point for various collaborative[](/book/collaborative-software-design/chapter-12/) modeling sessions, including User Story Mapping, EventStorming, and Wardley Mapping. It tells you, from the perspective of your customer, what happens from start to finish. Apart from technical opportunities, linked (external) systems, and software design challenges, it provides insights into what’s important to your customer, which is a great addition to or starting point for your software architecture.

Our friends at BigScreen were very aware of that, and they created a customer journey themselves. It’s a work in progress, and based on iterative updates, it represents the general customer journey of people who are visiting BigScreen. Figure 12.4 shows the custo[](/book/collaborative-software-design/chapter-12/)mer journey of BigScreen.

For the purpose of this chapter and book, we don‘t show all the details because they aren’t crucial in understanding the journey. This customer journey provides an overview of the main stages and the type of information that is required in a typical customer journey. We’ll use this journey to further explain some of the collaborative model[](/book/collaborative-software-design/chapter-12/)ing tools that you can use.

#### User Story Mapping

To map your user stories to the customer journey, you must have a customer journey in the first place. In the customer journey of BigScreen just shown in figure 12.4, let’s take product managers or product owners as an example here. There is a product that needs to be managed, and User Story Mapping is an excellent collaborative modeling tool that you can use here. From a product management perspective, you want to create solutions that focus on the needs and desires of the actual users. It would also be great if everyone involved had the same understanding of what those needs are and which solutions (products) they are building.

![Figure 12.4 A simple customer journey of BigScreen, with details removed from it](https://drek4537l1klr.cloudfront.net/baas/Figures/CH12_F04_Baas.png)

User Story Mapping can help you out with that! It’s a well-established tool coming from the Agile community and focuses on telling a story with the user perspective in mind. At the end of a User Story Mapping session, you have a visualized representation of the context of the customer journey, and you’ll be able to make your product backlog more transparent based on that visualization. As mentioned, User Story Mapping is a collaborative modeling tool. To create the best user experience, everyone who contributes to the delivery of customer value should be in the session, so you can expect product management, engineers, UX/design, sales, marketing, customer support, and legal to be represented.

The narrative is central here: it’s about the user experience. Taking that perspective prevents you from getting caught up in your own perspectives of what you believe would add value. If you take this too far, you’ll end up with a monstrous product backlog full of potentially irrelevant user stories. The goal is to map your user stories to the customer journey to make sure all your stories are relevant. By doing this, it will become easier to discover product increments and stay aligned with everyone involved. Based on that, you’ll be able to create a transparent and focused backlog with user stories that are relevant to your customers. As a bonus, writing user stories will also become much easier because they flow from the narrative you all follow. More guidance on how to run this exercise is extensively described in *Visual Collaboration Tools: For Teams Building Software* ([https://leanpub.com/visualcollaborationtools/](https://leanpub.com/visualcollaborationtools/))[](/book/collaborative-software-design/chapter-12/).[](/book/collaborative-software-design/chapter-12/)

#### Impact Mapping

Whatever product you’re building, eventually you need to deliver business value. Impact Mapping is another well-established visualization tool that focuses on aligning user stories with business objectives. Together with relevant stakeholders, four questions will be answered (we’ll delve into these in detail later in this section):

-  *Why?*—Goals
-  *Who?*—Actors
-  *How?*—Impact
-  *What?—*Deliverables

Because it all starts with the intended goal of the product (milestone), everything that will be identified after will have a direct effect on achieving that goal. It’s a great tool to get a mutual understanding of the goals, visualize assumptions, set priorities, and discuss delivery options. Impact Mapping was introduced by Gojko Adzic in *Impact Mapping* (Provoking Thoughts, 2012).

There are several reasons to create an Impact Map. As mentioned, focus, prioritization, and business value are important benefits. We see lots of companies and teams that get so caught up in building a solution that they forget what problem they were trying to solve or if the solution they’re building is (still) in line with business requirements. The map is visualized and simple, which makes it an excellent tool to have meaningful discussions with other stakeholders, including customers. It explains why certain features are being prioritized and why others aren’t, which is all linked back to that initial goal.

Impact Mapping can also be a way to detect cognitive bias and manage it when necessary. Availability bias, for example (as explained in chapter 7), can hinder us from taking on new perspectives and thinking creatively. With Impact Mapping, you can explore various options to reach a goal early on when no one has fallen deeply in love with any solution yet, and you’re still flexible enough to change course. You can visualize different options and pick the one that seems best.

Let’s briefly consider the steps that you go through when creating an Impact Map. As mentioned, it all starts with describing the goal of a product (milestone). That might sound easy, but formulating a good goal is challenging. “Creating a mobile Cinema app,” for example, isn’t a good goal, although it could be a means to an end. What do you want to achieve with this app? More early bird reservations, enhanced client satisfaction, increased mobile advertising revenue, and/or stronger customer loyalty? These are all examples that would work well. The first step is to decide on what the real goal is together with your relevant stakeholders:[](/book/collaborative-software-design/chapter-12/)

-  *Step 1: Goal.* Why are you doing this? The preceding examples provide inspiration for this step. Don’t take it lightly. Spend significant time on specifying your goal and creating alignment.
-  *Step 2: Actors*. Who has an effect on achieving the aforementioned goal? To answer this question, consider the following questions: Who can obstruct achieving the goal? For whom are we building this product; identifying our users and customers? Who will be affected by our product? There’s a strong link to behavior here: potential required behavioral change for the actors to achieve the goal determines step 3.
-  *Step 3: Impact.* This is where we relate actors to our business goal: What behavior is required from our actors to achieve our goal? Do we need a behavioral change? What is the current undesired behavior we see? How does that negatively affect achieving our goal? What behavior that is currently there should not change? These questions should be answered for all actors identified in step 2.
-  *Step 4: Deliverables*. Now that we know which role each actor plays in achieving our goal and which behavior is needed to get there, we can define deliverables such as features and organizational activities that support the impact we identified in step 3 and that are needed to achieve our goal.

Figure 12.5 is an example of an Impact Map from Adzic’s book. As you can see, it’s a simple visualization that provides a lot of[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/) insights and knowledge.

![Figure 12.5 An example of an Impact Map](https://drek4537l1klr.cloudfront.net/baas/Figures/CH12_F05_Baas.png)

### 12.2.2 Customer journeys and EventStorming: A love story

Different roles have unique needs and can benefit from different collaborative modeling tools, but the whole point of collaborative modeling is to do the modeling part together, meaning that there might be mutual value in different collaborative modeling efforts. From our experience, there definitely can be! Let’s take a look at a potential love story, specifically the one between customer journeys and EventStorming.

Imagine our situation at BigScreen. Several customer journeys have been mapped out by the UX designers, aiming at visualizing their needs and opportunities for BigScreen in terms of pain points and touch points. At the same time, a group of people visualized the bigger picture during a Big Picture EventStorming session as input for their software architecture. It doesn’t take a rocket scientist to see there is mutual value in these efforts. User journeys should fit the current software architecture, if we want to deliver the most value to our customers. What we often see happening, however, is that customer journeys are being mapped out in (partial) isolation and are mainly used for marketing efforts.

Here’s one example we’ve encountered: We once facilitated a Big Picture EventStorming session where both UX and developers were present, among others, of course. At one point, the architect wondered aloud if it would be useful to have customer journeys, so they could map that on the EventStorm to identify potential hotspots and opportunities. All of a sudden, someone stated (mildly frustrated), “Obviously, we mapped out all of our customer journeys already, and they are all available on *<shared drive>*!” The room turned a bit quiet and was wondering what to do next. One of the authors here—we’ll anonymize for obvious reasons—raised their hand and asked the group: “So, just out of curiosity, who of you have seen these customer journeys or are aware of their existence?” Turned out that apart from UX, no one was aware of these mapped-out journeys or had seen them.

This side story emphasizes the opportunities available to combine and align different collaborative modeling efforts. When customer journeys are mapped out in isolation, missing validation or input from domain experts, chances are they won’t fit in the current software architecture. If they complement each other, it would be easier to identify opportunities and (technical) solutions for pain points identified in the customer journeys.

The love story of customer journeys and EventStorming is rooted in how they complement each other. The customer journeys are focused on what end users or customers have to do and the stages they go through. An EventStorm also includes systems and how they support the process. To strengthen collaboration, you could include existing customer journeys in your EventStorming session, adding existing wireframes or mock ups. It’s a way to validate your customer journeys and to add crucial wisdom from a customer perspective to your EventStorm.

[](/book/collaborative-software-design/chapter-12/)If you take another look at the customer journey shown earlier in figure 12.4, you can see how it maps to (parts of) the Big Picture EventStorm. The Purchase stage, for example, is also visualized in the EventStorm. When we were designing boundaries in chapter 3, figure 3.6 showed a small part of the Big Picture EventStorm that captures the Payments part. As shown in that figure, external systems are mapped on two different bounded contexts: Movie Scheduling and Ticketing. By combining your customer journey and EventStorm, you can validate both and let them complement each other. In that way, you also allow all the present wisdom and knowledge to be p[](/book/collaborative-software-design/chapter-12/)art of the bigger picture.

### 12.2.3 Aligning capabilities with your strategy

Once you understand your entire context, you can take it one step further. If you know what you want to achieve, and you know what your context looks like, you can assess your current capabilities and discover if and which new capabilities you might need to reach your goals. We want to highlight two tools that we use to dive into understanding team processes and capabilities. With those outcomes, you can further strategize for the [](/book/collaborative-software-design/chapter-12/)future and implementation.

#### Team Topologies

We’ve already briefly discussed how the value chain of Wardley Mapping can be used to identify streamlets with user needs mapping. However, an important aspect we haven’t covered yet is cognitive load, a concept characterized by psychologist John Sweller in 1988 as “the total amount of mental effort being used in the working memory.”[5](/book/collaborative-software-design/chapter-12/footnote-000)

Engineering managers need to consider the cognitive load their teams are dealing with. For example, a software architecture that, theoretically, might be the most decoupled—such as a large number of small microservices—might result in teams grappling with a multitude of cross-cutting concerns. Alternatively, if the software architecture isn’t intentionally structured, it could result in excessive collaboration among teams, which can not only be costly but also cognitively demanding.

Team together with management, we can use Team Topologies as a collaborative modeling tool to map out teams and their interactions. The goal is to consider these independent business flows and the teams’ cognitive loads. It’s essential to keep in mind that when you begin collaborative software design, particularly with complex systems, circumstances can change quickly. This fluidity means you might need to adjust the teams and reevaluate their collaborations. Don’t apply Team Topologies once and then forget about it; instead, decide how you can strategize over time to transition teams from high collaboration to what Team Topologies calls “as-a-service.” Team Topologies is meant to be used as a collaborative modeling tool and dynamically changing teams over time to accommodate for changing business needs and problems.

For those keen to delve deeper into the theoretical integration of Domain-Driven Design (DDD), Wardley Mapping, and Team Topologies, we highly recommend exploring the insightful resources provided by Susanne Kaiser. Her videos and the upcoming book offer a valuable exploration of these ideas. We’ve included her blog post on this topic in the further reading list in section 12.6 for a more comprehensive understanding.[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)

![Figure 12.6 The positive and negative effects of the polarity “coding versus collaborative modeling”](https://drek4537l1klr.cloudfront.net/baas/Figures/CH12_F06_Baas.png)

#### Change/Maturity mapping

In Team Topologies, we can design an enabling team to infuse new knowledge into the Stream-aligned team. When modernizing your architecture, as we did at BigScreen, the team may require new capabilities to implement that architecture. For example, transitioning toward a microservice architecture necessitates many new capabilities to handle cross-cutting concerns and introduces a plethora of methods for observability.

Traditionally, many managers resort to using a skills matrix, or worse, a maturity model. The problem with these methods is that they don’t account for the context in which a team operates. Each team may require different capabilities and find themselves in unique contextual situations regarding their abilities. That’s why we can employ a variant of Wardley Mapping, created by Marc Burgauer an[](/book/collaborative-software-design/chapter-12/)d Chris McDermott, known as Maturity Mapping ([https://maturitymapping.com/](https://maturitymapping.com/)).

The concept is similar to Wardley Mapping, but we map out Capabilities as practices, which evolve from Novel, to Emerging, to Good, and finally to Best. However, it’s crucial to understand the team’s objective: What problem are they solving? From there, we can create a value chain and align every practice with the problem they are addressing for the business. This top anchor provides the context the team needs to map their maturity and understand their position.

This map empowers the team to decide how they should develop their capabilities. They can initiate experiments by having one or two people investigate a new capability. Once that capability has emerged and seems to work, the team can then advance it to a “good practice” and perhaps document the way of working. This map also provides the engineering manager with information for discussions about how individuals’ personal growth can align with the team’s goals. It can also inform decisions about whether to hire specialists, or if several teams are experiencing the same capability problem, whether to create an enabling team. Collaborative modeling and mapping out a landscape together serve as powerful tools for collaboration be[](/book/collaborative-software-design/chapter-12/)tween management and teams!

## 12.3 Moving toward implementation

The end goal of collaborative modeling is to create a functioning software system that fits the user needs. To do that, there are a few questions left, which we’ll answer in this section:[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)

-  When do we know it’s time to start coding?
-  Now that we have our EventS[](/book/collaborative-software-design/chapter-12/)torm, what do we do with it?

### 12.3.1 When to go from collaborative modeling to coding

Let’s start with the first one: When do we know it’s time to start coding? We can also ask ourselves the reverse: How do we know we haven’t modeled enough yet? Collaborative Modeling versus Coding is another polarity that needs to be managed, which we spoke about in chapter 10. A design stays a design, until it’s tested in production—only then do we know the feasibility of our models. On the other hand, modeling with stickies is cheaper than having to refactor.[](/book/collaborative-software-design/chapter-12/)

As a facilitator, it’s interesting to map out this polarity together with the group you’re facilitating to understand the signals and actions of the polarity. In figure 12.6, you can see some examples of the positive and negative effects of staying too long in both poles. We called the positive effects of coding and collaborative modeling, L+ and R+, Domain-Oriented Modeling. We named the negative effects, L− and R−, Shal[](/book/collaborative-software-design/chapter-12/)low Technical Programming.[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)

Next, you can ask the group for signals that they have been modeling too long or not long enough. If you start coding, and you have to add a lot of comments in the code to explain what’s happening, it’s time to go back to the virtual drawing board together with your team and dig a bit deeper into this part of the business logic. Ask the group questions such as the following: Can we introduce a new concept in our ubiquitous language that will make the code more readable?

Then, you fill in the actions that the group can take when they notice one of the signals. If you have too many comments in your code, you can model that specific scenario in detail. If you’re mainly discussing technical aspects of the model, it’s time to implement those technical aspects into the code. In figure 12.7, you can s[](/book/collaborative-software-design/chapter-12/)ee our signals and actions.[](/book/collaborative-software-design/chapter-12/)

As you may have noticed, those are fairly generic. Signals and heuristics are context dependent, and what is a signal or a possible action in one group of people, won[](/book/collaborative-software-design/chapter-12/)’t be there in another group. We wrote more in details about this polarity for EventStore which we added a link to in the further reading.

##### Exercise 12.1

In exercise 10.1 in chapter 10, we asked you to create the polarity map for Collaborative Modeling versus Coding polarity. Compare your solution with ours:

-  What are the similarities and differences between the effects?
-  Did we think of different signals and actions than you did?

At this point, you already have two important polarities you can use when introducing collaborative modeling into your teams: Deep versus Wide for use during the modeling sessions and Collaborative Modeling versus Coding to know when to start or stop modeling again. In the next section, we’ll look at how to conve[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)rt your EventStorm into code.

![Figure 12.7 Signals and actions that you can use to move between collaborative modeling and implementing the solution](https://drek4537l1klr.cloudfront.net/baas/Figures/CH12_F07_Baas.png)

### 12.3.2 From collaborative modeling to code

Now that we know when to go from collaborative modeling to code, let’s dive a bit deeper into how to do that. In chapter 2, we showed a piece of the EventStorm that we did together with the business at BigScreen. You can see a portion of this in figure 12.8. Where we want to end up is functionality implemented in the software. In this section, we’ll walk you through our approach to get there. We’ll leave the customer changing seats out of scope, and we’ll fo[](/book/collaborative-software-design/chapter-12/)cus on purchasing tickets.[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)

![Figure 12.8 A small part of the process for buying a ticket and allocating a seat](https://drek4537l1klr.cloudfront.net/baas/Figures/CH12_F08_Baas.png)

We’ve already designed the bounded contexts here, but that doesn’t mean we can just start implementing. We’re going to walk through the EventStorm again and add questions we still have that prevent us from implem[](/book/collaborative-software-design/chapter-12/)enting this (figure 12.9).

One of the questions we still have is around the cancellation policy: we’re trying to buy a ticket, but something with the seat allocation can go wrong. We said that this cancellation policy needs to deallocate the seat, but we also already requested the ticket. So, we also need to release the reserved tickets when their reservation has expired.[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)

![Figure 12.9 Your EventStorm will look something like this after you’ve iterated on it again. We now have added the questions we still need answered to start implementing them explicitly.](https://drek4537l1klr.cloudfront.net/baas/Figures/CH12_F09_Baas.png)

#### Diving into constraints

In chapter 2, we demonstrated Example Mapping. To go from collaborative modeling to implementation, we need to understand the constraints best of all. Those are stickies that will turn into code. We had a hotspot sticky next to the event that said “What do we do when this happens?” We can find that hotspot in our examples too. If you look at figure 12.10, there are still some cases in which we don’t allocate seats. It was conflicting with other information that we received, stating that seats always need to ha[](/book/collaborative-software-design/chapter-12/)ve an initial allocation.[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)

![Figure 12.10 Some constraints result in not allocating seats when customers are purchasing a ticket. These are clues that we don’t fully understand the constraints yet.](https://drek4537l1klr.cloudfront.net/baas/Figures/CH12_F10_Baas.png)

We went back to the business with some concrete examples of how we could allocate seats when we still had availability, but it didn’t match any of the constraints we discussed before. You can see the result of this in figure 12.11. We gave the business possible options and asked which one they preferred. When there are still seats available, but not in a single row, the business wanted us to balance the seats over multiple rows.[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)

![Figure 12.11 Digging deeper into the examples: What do we need to do when there are still seats available, but not adjacent in a single row? We provided two options to figure out what the business preferred.](https://drek4537l1klr.cloudfront.net/baas/Figures/CH12_F11_Baas.png)

The constraint “Only adjacent seating per row” is now seen as a first attempt to allocate seats, not the only constraint that we have. We also have a backup constraint to continue trying to allocate: when no single row allocation is possible, we balance seats over multiple rows. We did the same for “No adjacent seats over the corridor.” We provided them with four options here, as you[](/book/collaborative-software-design/chapter-12/) can see in figure 12.12.

Our initial two constraints have now transformed into a series of constraints with a specific order:

-  When allocating for the first time, we should try to allocate in a single row.
-  When no single row allocation is possible, we balance seats over multiple rows.
-  When we can’t balance in a column, we balance over corridors.
-  When there are only scattered seats left, we allocate as close as possible.

Digging deeper into the seat allocation constraints gave us very valuable information. There always should be a seat allocation, unless we don’t[](/book/collaborative-software-design/chapter-12/) have the capacity anymore.

![Figure 12.12 Examining the “No adjacent seats over corridor” constraint. What happens when we only have scattered seats available? We discovered that we’re allowed to allocate seats with a corridor in between, but we should try this only when we can’t balance seats in a column.](https://drek4537l1klr.cloudfront.net/baas/Figures/CH12_F12_Baas.png)

#### Designing for implementation

After digging deeper into the constraints and resolving some hotspots from figure 12.9, we have a much clearer idea already of how to implement the functionality of the EventStorm. There are still some pieces missing right now, however:[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)

-  Where are the consistency boundaries?
-  How can we glue commands together with the events the system is supposed to respond to?
-  Which bounded context has the information to answer the queries that our customers[](/book/collaborative-software-design/chapter-12/) need to make a decision?

Most of the functionality is part of the Seat Allocations bounded context, but as you can see in figure 12.13, we have two commands and events that are in a different boundary: Price Calculation and Payments. We’re going to leave those as is for now and fo[](/book/collaborative-software-design/chapter-12/)cus on Seat Allocations.

![Figure 12.13 The end result of digging deeper into the constraints and resolving the hotspots. By resolving the hotspots, we came to the conclusion that we need to not only cancel or confirm seat allocations but also do the same for the ticket reservation.](https://drek4537l1klr.cloudfront.net/baas/Figures/CH12_F13_Baas.png)

![Figure 12.14 Our EventStorm is divided into consistency boundaries (rectangles). Most of the events reside within the Seat allocations context. Two commands and events are from different bounded contexts (rounded corners): Price Calculation and Payments.](https://drek4537l1klr.cloudfront.net/baas/Figures/CH12_F14_Baas.png)

In figure 12.14, the rectangles represent aggregates, a key tactical design pattern from DDD. An *aggregate* serves as a consistency boundary surrounding a cluster of domain objects, safeguarding business invariants. Our goal is to maintain the consistency of these domain objects, ensuring they don’t reach an invalid state. To achieve this, constraints must be applied within the same boundary and dur[](/book/collaborative-software-design/chapter-12/)ing a single transaction. [](/book/collaborative-software-design/chapter-12/)

##### DESIGN HEURISTIC

Design consistency boundaries (aggregates) to guarantee that the business invariants aren’t violated.

Take a simple yet illustrative example: It’s important to prevent the allocation of a single seat to multiple tickets. If not, two individual tickets hold a reservation for the same seat, resulting in customer dissatisfaction. To avoid this, we might encapsulate the Seat, Row, and ScheduledMovieSeating domain objects within an aggregate, managing modifications through ScheduledMovieSeating (aggregate root). This approach ensures that the entire collection of domain objects remain correct in relation to the business invariant “Allocate 1 seat per ticket.” In this part of the EventStorm, we’ve designed two aggregates: ScheduledMovie and ScheduledMovieSeating. Coming up next, we’ll delve into the process of converting these aggre[](/book/collaborative-software-design/chapter-12/)gates into executable code.

#### Going to code

It has taken a bit of time, but we’re ready to start implementing our design! As you can see on the EventStorm in figure 12.14, we have multiple rectangles called ScheduledMovie. If you look at listing 12.1, you can see that the three blocks of ScheduledMovie have [](/book/collaborative-software-design/chapter-12/)been converted to a method.[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)

##### Listing 12.1 Simplified aggregate ScheduledMovie

```
public class ScheduledMovie {
  
   private int reservedTickets;
   private int purchasedTickets;
 
   private readonly int capacity;
  
   private int AvailableTickets => 
     this.capacity - this.reservedTickets - this.purchasedTickets;
  
   public ScheduledMovie() {
      this.capacity = 200;
   }
  
   public TicketsRequested RequestTickets(RequestTickets command) {
      if(command.Amount > 8) {
         throw new TicketRequestTooLarge(command.Quantity);
      }
  
      if(this.AvailableTickets < command.Quantity) {
         throw new TicketRequestExceedsCapacity(
            command.Amount, this.capacity);
      }
  
      this.reservedTickets += command.Quantity;
      return new TicketsRequested(command.Quantity);
   }
  
   public TicketsCancelled CancelReservedTickets(CancelTickets command) {
      this.reservedTickets -= command.Quantity;
      return new TicketsCancelled(command.Quantity);
   }
  
   public TicketsConfirmed ConfirmTicketPurchase(ConfirmTickets command) {
      this.reservedTickets -= command.Quantity;
      this.purchasedTickets += command.Quantity;
      return new TicketsConfirmed(command.Quantity);
   }
}
```

If we take a closer look at the `RequestTickets` method, we can see two `if` statements there. Those are the constraints from our EventStorm “amount of tickets must not exceed available tickets” and “tickets must not exceed 8.” This aggregate and code design is far from finished, and it only serves as a simplified example to show how those constraints ended up in code. We also only looked at a very small piece of the EventStorm in this section. As mentioned in chapter 11, section 11.3, software design is nonlinear, which can be best described as a whirlpool, and that includes the coding part. However, this gives you a good idea of how to go from collaborative modeling to code:[](/book/collaborative-software-design/chapter-12/)

-  A block on your EventStorm is a method in your aggregate.
-  The method has an input parameter, which is the command.
-  The method has a return type, which is the event.
-  The constraints get implemented in the method.

There are a lot of ways to go from collaborative modeling to code, and a lot of books in the DDD community go a lot deeper into that. So be sure to go to [https://virtualddd.com](https://virtualddd.com) and join the comm[](/book/collaborative-software-design/chapter-12/)unity to learn more about it.[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)

## 12.4 Collaborative software design catalysts

-  When the team needs to implement a new feature, create a customer journey for this feature.[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)
-  Organize a “Lunch and Learn” session within your company to explore the Impact Map.
-  With your team, create your own Collaborative Modeling versus Coding polarity map.
-  Go back to the business logic of your code: Take a large piece of code and create an EventStorm out of it. If applicable,[](/book/collaborative-software-design/chapter-12/) draw the consistency boundaries.

## 12.5 Chapter heuristics

*Design* *heuristic*

-  Design consistency boundaries (aggregates) to guarantee that the business invariants aren’t violated.[](/book/collaborative-software-design/chapter-12/)

## 12.6 Further reading

-  *Adaptive Systems with Domain-Driven Design, Wardley Mapping, and Team Topologies: Architecture for Flow* by Susanne Kaiser (Pearson Education, 2024)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)
-  “Architecture for Flow with Wardley Mapping, DDD, and Team Topologies” by Susanne Kaiser (QCon Plus conference video), [https://mng.bz/ZE59](https://mng.bz/ZE59)[](/book/collaborative-software-design/chapter-12/)
-  “Black Ops DDD Using the Business Model Canvas” by Javier Fernández (Explore DDD conference video), [www.youtube.com/watch?v=M5CbbWmdsFU](https://www.youtube.com/watch?v=M5CbbWmdsFU)[](/book/collaborative-software-design/chapter-12/)
-  “DDD, Wardley Mapping, & Team Topologies” by Susanne Kaiser (InfoQ podcast), [https://mng.bz/1GxR](https://mng.bz/1GxR) [](/book/collaborative-software-design/chapter-12/)
-  “EventStorming the Perfect Wedding” by Kenny Baas-Schwegler, [https://mng.bz/2Kxw](https://mng.bz/2Kxw)[](/book/collaborative-software-design/chapter-12/)
-  *Impact Mapping: Making a Big Impact with Software Products and Projects* by Gojko Adzic (Provoking Thoughts, 2012)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)
-  “Resilient Bounded Contexts: A Pragmatic Approach with Residuality Theory” by Kenny Baas-Schwegler, [https://mng.bz/RZWa](https://mng.bz/RZWa)[](/book/collaborative-software-design/chapter-12/)
-  *User Story Mapping: Discover the Whole Story, Build the Ri[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)ght Product* by Jeff Patton (O’Reilly, 2014)
-  *Residues: Time, Change, and Uncertainty in Software Architecture*, Barry M. O'Reilly (Leanpub, 2024)
-  *Team Topologies: Organizing for fast flow of value*, by Manuel Pais and Matthew Skelton (It Revolution Press, 2019)
-  “When to go from collaborative modelling to coding? Part 1” by Kenny Baas-Schwegler, Evelyn van Kelle, and Gien Verschatse, [https://www.eventstore.com/blog/when-to-go-from-collaborative-modelling-to-coding-part-1](https://www.eventstore.com/blog/when-to-go-from-collaborative-modelling-to-coding-part-1)[](/book/collaborative-software-design/chapter-12/)[](/book/collaborative-software-design/chapter-12/)

## Summary

-  Avoid the trap of preconceived solutions; prioritize understanding customer needs and context in collaborative modeling tools such as Business Model Canvas and EventStorming. Refocus on value proposition and customer segment, eliminating software-centric biases to gain deeper insights.
-  By mapping the business landscape, introducing climate patterns, and using evolution stages, Wardley Mapping provides a clear view for tailored, effective strategies, aiding decisions in product, teams, and software design areas.
-  Stressor analysis, derived from residuality theory, uncovers hidden stressors in complex systems, guiding mitigation strategies and fostering resilient software architectures through shared approaches.
-  Collaborative modeling, applicable beyond software design, benefits product manager and UX designer roles through techniques such as Big Picture EventStorming.
-  Customer journeys encompass overall experiences, while user journeys focus on product interactions; both enhance sessions such as User Story Mapping and EventStorming, enriching software architecture with customer-centric insights.
-  Impact Mapping, introduced by Gojko Adzic, visually aligns user stories with business goals by clarifying why, who, how, and what. This technique aids prioritization, fosters discussions, detects cognitive bias, and guides product development by connecting behavior change with deliverables.
-  Integrating mapped customer journeys into EventStorming sessions validates and enhances understanding, helping identify pain points, opportunities, and solutions for a more comprehensive perspective.
-  Consider cognitive load when designing software architecture, as the most decoupled architecture may lead to cross-cutting concerns or excessive collaboration. Team Topologies, when combined with Maturity Mapping, offers a collaborative modeling approach to strategically structure teams, manage capabilities, and foster adaptive development in evolving contexts.
-  Address the balance between collaborative modeling and coding by recognizing signals and actions. Domain-Oriented Modeling (L+ and R+) supports meaningful design, while Shallow Technical Programming (L− and R−) leads to inefficiencies.
-  Transitioning from collaborative modeling to code implementation involves transforming EventStorm blocks into aggregate methods.
-  Constraints identified in the EventStorm guide the implementation process and are incorporated into the body of the methods of the aggregate.
-  Deeper analysis and discussions with the business refine constraints, leading to a clearer implementation plan.
-  Aggregates define consistency boundaries around domain objects, maintaining internal consistency.[](/book/collaborative-software-design/chapter-12/)

---

[](/book/collaborative-software-design/chapter-12/)[1](/book/collaborative-software-design/chapter-12/footnote-004-backlink)   O’Reilly, B. M. “Residuality Theory, Random Simulation, and Attractor Networks,” 2022. Procedia Computer Science, 201:639–645.

[](/book/collaborative-software-design/chapter-12/)[2](/book/collaborative-software-design/chapter-12/footnote-003-backlink)   O’Reilly, “Residuality Theory,” 639–645.

[](/book/collaborative-software-design/chapter-12/)[3](/book/collaborative-software-design/chapter-12/footnote-002-backlink)   Ibid.

[](/book/collaborative-software-design/chapter-12/)[4](/book/collaborative-software-design/chapter-12/footnote-001-backlink)   Ibid.

[](/book/collaborative-software-design/chapter-12/)[5](/book/collaborative-software-design/chapter-12/footnote-000-backlink)   Skelton, M., & Pais, M. “Team Cognitive Load,” 2021, [https://itrevolution.com/articles/cognitive-load/](https://itrevolution.com/articles/cognitive-load/).
