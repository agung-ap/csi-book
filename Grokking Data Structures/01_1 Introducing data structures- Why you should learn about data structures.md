# 1 Introducing data structures: Why you should learn about data structures

### In this chapter

- welcome to this book
- what are data structures
- why you need data structures
- examples of data structures making a difference
- step-by-step guidelines to apply data structures in a project

[](/book/grokking-data-structures/chapter-1/)Data structures make the world go round: information is the gold of the Internet Age, and data structures are necessary for handling and making sense of information. Data structures allow us to shape data in meaningful ways and query it to find what is relevant to us.

## Welcome to Grokking Data Structures

Welcome to *Grokking Data Structures*! I’m super excited to accompany you on this journey through data structures. [](/book/grokking-data-structures/chapter-1/)

In this book, I want to dispel some misconceptions about data structures: they are extremely useful in your everyday work. Even if you are not a researcher, they do make a difference, and they are not hard to learn: you do not need to be a math expert to understand and use data structures!

During our journey, I will show you that data structures are not boring theoretical stuff. They have become part of our lives so much that I can claim you certainly use them regularly without even realizing it. Besides coding, you have used or seen in action some of the data structures we will describe in normal life situations.

### Data structures are everywhere

[](/book/grokking-data-structures/chapter-1/)You don’t believe me? We could make it interesting with a little bet, but that would be so unfair of me!

Let’s see. Do you ever go to a grocery or department store? When you go shopping, you fill your physical cart with items you want to buy: there it is, a *container*. But which container in particular? I don’t want to spoil it for you, but you’ll be able to tell after reading this book.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/01-01.png)

Once you find everything you need, you go to the cashier to pay. While you wait your turn, you are literally in another data structure, a *queue*![](/book/grokking-data-structures/chapter-1/)

Did I manage to convince you? If you are a software developer, convincing you will be even easier because if you write code, you must have used at least arrays. Not to mention that, of course, if you are reading a digital version of this book, your e-reader uses many data structures to hold pages of the book, its words, the bookmarks you might add, and so on.

### Data structures are for everyone

This book teaches data structures to anyone, regardless of their background. You don’t need advanced math; you don’t need to have taken CS101 or any other course; you don’t need to be a coding ninja, although some knowledge of Python might help. This book, like every book in the Grokking series, will provide you with an understanding of how things work, explaining what a data structure is, what the basic structures are, and how you can objectively decide which data structure is better for your task. It’s a book for beginners, meaning that it assumes no previous knowledge, and it relies on your intuition and visual memory. However, even if you are familiar with the subject, you might find it useful to brush up on your skills and get an even deeper understanding of some of the topics.

## What are data structures?

[](/book/grokking-data-structures/chapter-1/)If you are reading this book, you are probably aware that we live in the so-called Age of Data, an era in which data has become an integral part of our lives. We are flooded with information, the production of which is accelerating at an unprecedented, exponential rate, fueled by technological advances. This stream of data is changing the way we live, work, and interact.[](/book/grokking-data-structures/chapter-1/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/01-02.png)

To make sense of this huge amount of information and avoid being overwhelmed, we need to organize it somehow. That’s where data structures come in.

Data structures are a way of organizing and storing information in a computer or a program. They help to efficiently manage and manipulate data.

For example, if you want to find out whether a friend from school is on Facebook, you can. This is only possible because there is a data structure that organizes users in a way that makes it easy and fast to search among a billion users.

#### Algorithms and data structures

You often hear the term *data structures* used in conjunction with *algorithms*. In fact, you hear the term so often that you might ask whether they are the same thing. No, algorithms and data structures are not the same, although they are closely related. [](/book/grokking-data-structures/chapter-1/)[](/book/grokking-data-structures/chapter-1/)

An algorithm is a set of well-defined instructions, a step-by-step procedure designed to solve a specific problem or perform a particular task. In our Facebook example, we use an algorithm that searches through all the users’ names and returns the most promising matches.

A data structure is a way of organizing and storing data in a computer or a programming language. It defines the relationship between the data elements, the operations that can be performed, and the rules or constraints for accessing and modifying the data. Facebook users are stored in a database that organizes its data in a way that makes it efficient to search for users by name.

##### Note

Algorithms are used to describe the operations performed on data structures. To use an analogy, data structures are like nouns, while algorithms are more like verbs.

Data structures and algorithms are interdependent, just like a meaningful sentence in English requires subjects, objects, and verbs to describe an action.

![Algorithms transforming data like verbs acting on nouns](https://drek4537l1klr.cloudfront.net/larocca3/Figures/01-03.png)

Data structures provide the organization and representation of information (the data), and algorithms serve as instructions for transforming that data. Each data structure implicitly defines algorithms for operations, such as adding, retrieving, and removing its elements.

Some data structures are specifically designed to allow the efficient execution of certain algorithms, such as hash tables for key-based search. (Don’t worry if you don’t know these terms at this point: they’ll all be covered later in the book.)

Thus, describing a data structure requires accurately explaining the algorithms behind its methods. In other words, in this book, you will learn about many algorithms.

## Why should I care about data structures?

[](/book/grokking-data-structures/chapter-1/)Data structures are the building blocks of computer science. They are important because they help organize data, solve difficult problems, improve efficiency, optimize memory usage, and avoid security risks. They are essential tools for effectively managing and manipulating information in computer programs.[](/book/grokking-data-structures/chapter-1/)

Recently, new trends in computer science that take advantage of data structures have emerged, such as graph neural networks, an even more powerful version of the machine-learning building blocks that power deep-learning models.

The database landscape is also evolving, and the concept of *flexible indexing* has recently been introduced. This is an indexing model based on data structures that can be nested in any combination and at any depth. It is an extremely powerful tool, and you can only harness this power if you master data structures.[](/book/grokking-data-structures/chapter-1/)

![A hammer is unlikely to help if you need to tighten a bolt.](https://drek4537l1klr.cloudfront.net/larocca3/Figures/01-04.png)

However, I can give you an even more powerful reason: learning about data structures can make you a better software developer. Knowing about data structures and algorithms is like adding a tool to your tool belt.

Have you ever heard of Maslow’s hammer, also known as the law of the instrument? It states that if your tool belt only has a hammer, you will be tempted to treat everything as a nail.

It’s an observation that people tend to apply what they know to all sorts of different situations, even when it’s not appropriate.

With data structures, if you only know how to use the data structure called a *hash table*, you’ll be tempted to use it in every situation, even when you need to efficiently perform operations such as *next* and *previous* and would be better off using a *tree*.[](/book/grokking-data-structures/chapter-1/)

[](/book/grokking-data-structures/chapter-1/)Don’t worry if the previous example sounds obscure and not obvious right now or if you don’t know some of the terms used there: it’s a good reason to keep reading because we will cover this topic later in the book.

This book gives you more tools to use when approaching a problem such as this one and trains you to recognize opportunities to use these tools to improve your code.

#### When do I need data structures?

In theory, you need data structures when you must organize your data in a way that makes it easy and efficient to store and retrieve it according to some special rules. That’s a very formal definition, and despite being formally correct, it feels somehow far away from our daily routine, from the world as we make sense of it.

Let’s see some examples of data structures in action to give you a better idea.

#### Searching like a pro

Tom has a large collection of items—imagine thousands of baseball cards or, on a larger scale, millions of products on his e-commerce site. These items have attributes, some of which (such as a name) uniquely identify the items.

How should Tom search that collection? For example, how would he search for Joe Di Maggio’s card among all his cards?

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/01-05.png)

He could, of course, go through them one by one until he finds the card he was looking for. If you like collecting cards as much as I do, you know that when you have thousands of them, searching for a specific card could take a long time. Imagine how long it would take to search for a product in an online catalog with millions of items!

Tom needs a better way to store and search for items, and to learn about the tradeoffs that are required to balance different needs. This book offers a few different options for search-efficient data structures and can help you find the right one for your needs. So, how about starting with sorted arrays and binary search?

#### So many users!

Let me describe another scenario. For Kat’s web application, she needs to keep track of logged-in users and their IPs.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/01-06.png)

First, she implements IP tracking by herself. Locally, it works fine. But when she deploys her changes to production, the data structure she has used is too slow to support the amount of traffic on her web application, so it crashes the application server.

Then, considering how urgent fixing the problem has become, Kat outsources the solution to a consulting firm, hoping they know better. Their solution is indeed fast. It even works well in production...until it doesn’t. It turns out that a hacker has figured out that, with the right sequence of calls, they can overload the data structure the external company used and crash Kat’s application again at will.

What happened here? The first time, performance was the problem because the wrong data structure was used, and it was too slow to operate at scale.

[](/book/grokking-data-structures/chapter-1/)The second time, a better option was chosen. Unfortunately, the new solution was used carelessly, leaving a vulnerability to an adversary sequence (a sequence of inputs chosen ad hoc to cause problems to the data structure). This vulnerability, in turn, allowed a *denial of service* (DoS) attack. In such a scenario, a hacker can use a vulnerability to make an application so slow that its legitimate users won’t be able to interact with it.[](/book/grokking-data-structures/chapter-1/)

Is there any hope? We will see that hash tables, if used properly, could solve most of Kat’s problems. When talking about hash tables, we will learn more about the problem that made the DoS attack possible, how to fix it, and, more importantly, what to look for: even if you buy a finished product from a third party, you need to know what questions to ask, to make sure they did everything right.

#### Modeling relationships

Sandra is launching the next generation of social networks that will change the way we connect. Well, at least that’s her dream. She is still implementing a minimum viable product and hoping to get some funding.

She is making good progress, but she has hit a bit of a roadblock when it comes to tracking the relationship between users. She wants to try something like a spreadsheet or a tabular structure, but she is not sure how to store it or implement queries about “friends of friends” relationships.

Sandra tries a naive solution by iterating through the entire list of users several times, but this somehow makes her application unresponsive, and she becomes very frustrated.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/01-07.png)

Sandra has only tried to do this in memory: What if she needs to add persistence to this data? And what if she later needs to find even more distant relationships such as “friend of a friend of a friend” or the six degrees of Kevin Bacon? Unfortunately, an SQL database doesn’t seem to support everything she needs.

Later in this book, you’ll learn that graphs would help Sandra tame highly relational data and that she could use the breadth-first search algorithms to explore indirect friend relationships. With graphs come graph databases, a different way of storing highly relational data that allows us to quickly run queries based on the relationships between different pieces of data.

### Will I ever write code for these data structures?

[](/book/grokking-data-structures/chapter-1/)Except for positions that involve some research, most software engineering positions won’t require you to write your own algorithms or data structures on a daily or weekly basis. Most of the time, you’ll just be using someone else’s code. Yet, even then, studying data structures will help you make the right choices or be aware of the better solutions.

There are still certain situations in which you may need to roll up your sleeves and write your own implementation—for example, if you’re using a brand-new programming language for which there aren’t many libraries available or need to customize a data structure to solve a special case.

But regardless, even if you never have to write your own implementation, only first-hand knowledge of data structures will give you a better understanding of the tradeoffs you are making in your code and how to make your code more efficient.

### How should I choose a data structure?

From the examples in the previous section, it’s clear that choosing your data structures wisely is important. A less obvious point is that it’s not about choosing the perfect data structure. You don’t always have to choose the best possible one; most of the time, you can get away with a near-optimal alternative. But what’s fundamental is avoiding the wrong choice, which would be a data structure that would crash your application or cause a security problem.

The most important thing I hope you take away from this book is a method for evaluating and choosing which data structure to use in any given context.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/01-08.png)

How do you do that? The ability to choose the right data structure is like a muscle that you need to train. Throughout the book, we’ll build your knowledge and intuition by showing you the dangers you might face, how to systematically identify them by evaluating the complexity of algorithms, what aspects to balance, and what tradeoffs to consider.

## How do we use data structures in a project?

[](/book/grokking-data-structures/chapter-1/)At this point, you have an idea of what is in this book and why it is important. The next step is to understand how you can use what you learn here in your daily work.[](/book/grokking-data-structures/chapter-1/)

Data structures and algorithms are not a technology, so it’s hard to even imagine a manual on how to use them. They are used everywhere; most of the time, you use them without even realizing it.

The point is not how to add data structures to your code because, one way or another, you are already using them. Rather, it’s about developing a process that will allow you to make conscious, informed choices about the data structures you use and expanding your knowledge of data structures so that when you face a problem, you remember the possible alternatives.

### A mental model for applying data s[](/book/grokking-data-structures/chapter-1/)tructures

As mentioned, it’s not easy to distill an expert’s experience and knowledge of data structures and algorithms into a step-by-step process. Perhaps it can be considered as part science and part art, with tacit knowledge built up through experience making the difference. It’s a challenge, but I believe it’s possible to extract some guidelines that can assist you and raise the level of your coding.[](/book/grokking-data-structures/chapter-1/)

At a high level, the process of going from a problem to a solution using algorithms and data structures can be described in a few steps, illustrated in the following figure.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/01-09.png)

The steps are as follows:

1.  Understand the problem you are solving.
1.  Sketch out a possible solution.
1.  Identify the data structures you need.
1.  Implement a solution.
1.  Check whether the solution works; if not, iterate.
1.  Check whether the solution is good (efficient) enough; if not, iterate.

The key parts for us are steps 3 and 6:

-  We think about the data structures we can use in our solution (step 3).
-  We evaluate whether our (working) solution is too slow, uses too much memory, or breaks our requirements in any other way (step 6).

The implementation step is also relevant if we are implementing the data structures from scratch. In that case, we must also thoroughly test the code of the data structure for correctness and performance. But implementation is not our focus here: for simplicity, we will assume that there is a third-party library that we can use.[](/book/grokking-data-structures/chapter-1/)

#### [](/book/grokking-data-structures/chapter-1/)Identify [](/book/grokking-data-structures/chapter-1/)what data structures are needed

So, assuming you’ve understood the requirements of your problem (a step that should not be neglected!) and sketched out a solution that you think you might work on, now it’s time to think about what you need to build that solution. This is where you go from a high-level idea of what you need to solve a problem to a more concrete plan that includes what you will use to solve it.

For example, if your problem is getting to a meeting by 9 a.m. the next morning, your high-level solution might include setting up an alarm, planning your trip from home to the meeting, and making sure you have your presentation with you. Your next step is to identify the tools you can use: your phone to set the alarm, a bus or your car to get to the meeting, and your laptop for the presentation.

#### C[](/book/grokking-data-structures/chapter-1/)heck whether your solution is good enough

[](/book/grokking-data-structures/chapter-1/)Identifying a possible way to solve your problem may not be enough. You also need to be able to solve it in a reasonable amount of time with the resources you have available. For an e-commerce website, it’s not acceptable to take 10 minutes (or 1 minute!) to return your search results. For a video game, it’s not acceptable to have requirements beyond home computers.

Then again, you don’t want to overengineer, or overbuild, your application. You don’t need a supercomputer to run your school’s website, just like you don’t need an overly complicated data structure for something that can be solved efficiently with an array. To avoid premature optimization, you’ll usually want to start small and try more complicated data structures only if you already know, or find out in this step, that you have a bottleneck.

#### What about tests?

Looking at the flow we previously sketched, you might be concerned and remark that testing your code, cleaning it up, and making sure that, for example, variable and method names are not confusing are all important phases of software development. You’d be right—they certainly are. These phases are not included here because we are looking at the process at a high level and focusing on an abstract solution, leaving out the implementation details.

### Data structures in action

Now that you are familiar with the steps you can take to include data structures in a project, let’s look at an example to make the flow clearer and to illustrate the importance of selecting the most appropriate data structure.

Our scenario is an emergency room for pets. In this scenario, our little furry (and talking!) friends come to see the doctors, waiting for their turn in the lobby until they are admitted. We must triage patients, decide who gets admitted and when, and try to keep things running smoothly. We do not want to upset our patients, especially the alligators, who have a notoriously bad temper.

#### Understanding the problem and sketching out a solution

This may seem trivial, but underestimating a task would be a huge mistake. The most important thing in any project is to understand your client’s requirements; the sooner you clarify them, the less painful the project will be. Here, the problem definition is vague enough to allow multiple interpretations: Do we need to worry about who’s in the room? Can cats, dogs, alligators, and rabbits be in the same room? Is there a capacity limit (for the lobby or in terms of visits per day)? These (and many more) are all questions you should ask when faced with a similar task.

In this case, let’s keep it simple: we just want to handle the registration and admission of the patients, and we assume that the lobby has infinite capacity and no other constraints. So, what we need is a device, a piece of software, that registers patients and then admits them in a certain order.

The next sections show how we can iterate the remaining steps until we find a good solution.

#### First try:[](/book/grokking-data-structures/chapter-1/) Order agnostic

[](/book/grokking-data-structures/chapter-1/)We understand our inputs and outputs. The next step is to understand how we are going to make this device.

Working on a solution means writing your own algorithm to transform an input and get to your goal, but it is a more high-level operation based on domain knowledge. Now it’s time we start thinking about details.[](/book/grokking-data-structures/chapter-1/)

We need a container, a data structure that can hold the patient registrations and return the next patient to be admitted each time we ask. But which container?

Keep in mind that all of the data structures mentioned in the following are covered in the book; you don’t need to understand them right now. For our first attempt, we put the forms in a suggestion box at registration, and when a doctor gets free, we just blindly fish out one of these paper forms. The container we used is a *bag,* which is perfect if you don’t care about the order in which you read the elements stored.

For this example, we assume the implementation phase produced code without bugs. Thus, we move directly to the questions: Does this solution work, and does it work well?

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/01-10.png)

Randomly choosing who gets in next has some problems: on average, everyone gets served within an acceptable time. However, patients tend to notice when someone who arrived after them cuts the line, especially when there are only a few patients. Fights start, and when an alligator eats a rabbit who cut into the line in front of her, it’s clear that this is not a good solution.

#### Reverse order

We need to iterate on our solution. The high-level solution works, but we need to change the data structure we use.

This time, the forms are stored in order, in a pile with the oldest at the bottom and the newest at the top. Unfortunately, because of a misunderstanding, the triage operators take the next form from the top of the pile: they are implementing a *stack*, so the last registered patient is the first one admitted! At the end of the first day, when they have to deal with an angry lion who had been waiting the whole day to get a splinter removed from his paw, everyone realizes that this stack solution doesn’t work at all.

[](/book/grokking-data-structures/chapter-1/)A stack is good when we need to process the most recent entries first, but it’s terrible to handle a waiting line.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/01-11.png)

#### First come, first serve

This time, the correction is conceptually simpler: we take the next forms from the bottom of the pile, so the first patient to arrive will be the first to see a doctor. For this approach, we are using a *queue*, a data structure that allows us to iterate through the elements in the same order in which they were added.

And the solution works pretty well: no more arguments, no more endless waiting; patients are happier, and triage is less stressful. Finally, the implemented solution works.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/01-12.png)

Now the final step. The question is, does it work well enough? After a few weeks of working with the new triage system, the doctors realized that in a few cases, some complications could have been avoided had the patients been seen immediately instead of waiting their turn.

Do you know what that means? We can do better. It’s time to iterate.

#### Emergencies first

What we need is a data structure that allows us to take into account more than just the arrival time. Triage operators have the registration forms on which they write down a patient’s initial anamnesis: they can estimate the urgency of a case and reorder the forms so that, even if the lion with the splinter arrived at the ER first, he would get in after the python who ate a computer mouse and the turtle who twisted her ankle while running.

Luckily, we have the right data structure for this: a priority queue. If we add all our cases to a priority queue, we can later ask it to return us the most urgent case, followed by the next most urgent one, and so on.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/01-13.png)

[](/book/grokking-data-structures/chapter-1/)This solution works, and it works well. Are we done? That depends. First, it depends on the real requirements, which might require more guarantees. Then, we should consider the real implementation of the system to decide which kind of priority queue is fast enough or handles memory well enough for our needs.

But you get the point: you can measure the performance, compare it to your requirements, and then decide. For this example, because we understand how to choose the right data structure, we found a solution that works perfectly for our needs—understanding how to choose the right data structure.

## Recap

-  A data structure is a way to organize and store data in a computer or a programming language by defining the relationship between data, operations that can be performed, and rules or constraints for accessing and modifying data.
-  Data structures are fundamental to organizing and storing data efficiently.
-  An algorithm is a set of well-defined instructions, a step-by-step procedure designed to solve a specific problem or perform a particular task.
-  Algorithms and data structures complement each other the way nouns and verbs complement each other in a sentence.
-  Choosing the wrong data structure can have dire consequences, such as crashing your website or causing security hazards.
-  There is a step-by-step process that can help you decide which data structures to use in a project.
-  The process is iterative and requires checking the quality of your solution until you meet all your requirements.[](/book/grokking-data-structures/chapter-1/)
