# [](/book/grokking-machine-learning/chapter-1/)1 What is machine learning? It is common sense, except done by a computer

### In this chapter

- what is machine learning
- is machine learning hard (spoiler: no)
- what do we learn in this book
- what is artificial intelligence, and how does it differ from machine learning
- how do humans think, and how can we inject those ideas into a machine
- some basic machine learning examples in real life

![](https://drek4537l1klr.cloudfront.net/serrano/Figures/CH01_F01_Serrano_Text.png)

#### [](/book/grokking-machine-learning/chapter-1/)I am super happy to join you in your learning journey!

Welcome to this book! I’m super happy to be joining you in this journey through understanding machine learning. At a high level, machine learning is a process in which the computer solves problems and makes decisions in much the same way as humans.

In this book, I want to bring one message to you: machine learning is easy! You do not need to have a heavy math and programming background to understand it. You do need some basic mathematics, but the main ingredients are common sense, a good visual intuition, and a desire to learn and apply these methods to anything that you are passionate about and where you want to make an improvement in the world. I’ve had an absolute blast writing this book, because I love growing my understanding of this topic, and I hope you have a blast reading it and diving deep into machine learning!

#### [](/book/grokking-machine-learning/chapter-1/)Machine learning is everywhere

Machine learning is everywhere. This statement seems to be truer every day. I have a hard time imagining a single aspect of life that cannot be improved in some way or another by machine learning. For any job that requires repetition or looking at data and gathering conclusions, machine learning can help. During the last few years, machine learning has seen tremendous growth due to the advances in computing power and the ubiquity of data collection. Just to name a few applications of machine learning: recommendation systems, image recognition, text processing, self-driving cars, spam recognition, medical diagnoses . . . the list goes on. Perhaps you have a goal or an area in which you want to make an impact (or maybe you are already making it!). Very likely, machine learning can be applied to that field—perhaps that is what brought you to this book. Let’s find out together!

## [](/book/grokking-machine-learning/chapter-1/)Do I need a heavy math and coding background to understand machine learning?

No. Machine[](/book/grokking-machine-learning/chapter-1/) learning requires imagination, creativity, and a visual mind. Machine learning is about picking up patterns that appear in the world and using those patterns to make predictions in the future. If you enjoy finding patterns and spotting correlations, then you can do machine learning. If I were to tell you that I stopped smoking and am eating more vegetables and exercising, what would you predict will happen to my health in one year? Perhaps that it will improve. If I were to tell you that I’ve switched from wearing red sweaters to green sweaters, what would you predict will happen to my health in one year? Perhaps that it won’t change much (it may, but not based on the information I gave you). Spotting these correlations and patterns is what machine learning is about. The only difference is that in machine learning, we attach formulas and numbers to these patterns to get computers to spot them.

Some mathematics and coding knowledge are needed to do machine learning, but you don’t need to be an expert. If you *are* an expert in either of them, or both, you will certainly find your skills will be rewarded. But if you are not, you can still learn machine learning and pick up the mathematics and coding as you go. In this book, we introduce all the mathematical concepts we need at the moment we need them. When it comes to coding, how much code you write in machine learning is up to you. Machine learning jobs range from those who code all day long, to those who don’t code at all. Many packages, APIs, and tools help us do machine learning with minimal coding. Every day, machine learning is more available to everyone in the world, and I’m glad you’ve jumped on the bandwagon!

#### [](/book/grokking-machine-learning/chapter-1/)Formulas and code are fun when seen as a language

In most machine learning books, algorithms are explained mathematically using formulas, derivatives, and so on. Although these precise descriptions of the methods work well in practice, a formula sitting by itself can be more confusing than illustrative. However, like a musical score, a formula may hide a beautiful melody behind the confusion. For example, let’s look at this formula: Σi4=1*i*. It looks ugly at first glance, but it represents a very simple sum, namely, 1 + 2 + 3 + 4. And what about Σin=1*w*i? That is simply the sum of many (*n*) numbers. But when I think of a sum of many numbers, I’d rather imagine something like 3 + 2 + 4 + 27, rather than 1 Σin=1*w*i. Whenever I see a formula, I immediately have to imagine a small example of it, and then the picture is clearer in my mind. When I see something like *P*(*A*|*B*), what comes to mind? That is a conditional probability, so I think of some sentence along the lines of “The probability that an event A occurs given that another event B already occurs.” For example, if A represents rain today and B represents living in the Amazon rain forest, then the formula *P*(*A*|*B*) = 0.8 simply means “The probability that it rains today given that we live in the Amazon rain forest is 80%.”

If you do love formulas, don’t worry—this book still has them. But they will appear right after the example that illustrates them.

The same phenomenon happens with code. If we look at code from far away, it may look complicated, and we might find it hard to imagine that someone could fit all of that in their head. However, code is simply a sequence of steps, and normally each of these steps is simple. In this book, we’ll write code, but it will be broken down into simple steps, and each step will be carefully explained with examples or illustrations. During the first few chapters, we will be coding our models from scratch to understand how they work. In the later chapters, however, the models get more complicated. For these, we will use packages such as Scikit-Learn, Turi Create, or Keras, which have implemented most machine learning algorithms with great clarity and power.

## [](/book/grokking-machine-learning/chapter-1/)OK, so what exactly is machine learning?

To define machine learning, first let’s define a more general term: artificial intelligence.

#### [](/book/grokking-machine-learning/chapter-1/)What is artificial intelligence?

*Artificial*[](/book/grokking-machine-learning/chapter-1/)[](/book/grokking-machine-learning/chapter-1/) *intelligence*[](/book/grokking-machine-learning/chapter-1/) (AI) is a general term, which we define as follows:

##### artificial intelligence

The set of all tasks in which a computer can make decisions

In many cases, a computer makes these decisions by mimicking the ways a human makes decisions. In other cases, they may mimic evolutionary processes, genetic processes, or physical processes. But in general, any time we see a computer solving a problem by itself, be it driving a car, finding a route between two points, diagnosing a patient, or recommending a movie, we are looking at artificial [](/book/grokking-machine-learning/chapter-1/)intelligence.

#### [](/book/grokking-machine-learning/chapter-1/)What is machine learning?

Machine[](/book/grokking-machine-learning/chapter-1/) learning is similar to artificial intelligence, and often their definitions are confused. *Machine learning* (ML) is a part of artificial intelligence, and we define it as follows:

##### machine learning

The set of all tasks in which a computer can make decisions *based on data*

What does this mean? Allow me to illustrate with the diagram in figure 1.1.

![Figure 1.1 Machine learning is a part of artificial intelligence.](https://drek4537l1klr.cloudfront.net/serrano/Figures/1-11.png)

Let’s go back to looking at how humans make decisions. In general terms, we make decisions in the following two ways:

- By using logic and reasoning
- By using our experience

For example, imagine that we are trying to decide what car to buy. We can look carefully at the features of the car, such as price, fuel consumption, and navigation, and try to figure out the best combination of them that adjusts to our budget. That is using logic and reasoning. If instead we ask all our friends what cars they own, and what they like and dislike about them, we form a list of information and use that list to decide, then we are using experience (in this case, our friends’ experiences).

Machine learning represents the second method: making decisions using our experience. In computer lingo, the term for *experience* is *data**[](/book/grokking-machine-learning/chapter-1/)*. Therefore, in machine learning, computers make decisions based on data. Thus, any time we get a computer to solve a problem or make a decision using only data, we are doing machine learning. Colloquially, we could describe machine learning in the following way:

Machine learning is common sense, except done by a computer.

Going from solving problems using any means necessary to solving problems using only data may feel like a small step for a computer, but it has been a huge step for humanity (figure 1.2). Once upon a time, if we wanted to get a computer to perform a task, we had to write a program, namely, a whole set of instructions for the computer to follow. This process is good for simple tasks, but some tasks are too complicated for this framework. For example, consider the task of identifying if an image contains an apple. If we start writing a computer program to develop this task, we quickly find out that it is hard.

![Figure 1.2 Machine learning encompasses all the tasks in which computers make decisions based on data. In the same way that humans make decisions based on previous experiences, computers can make decisions based on previous data.](https://drek4537l1klr.cloudfront.net/serrano/Figures/1-21.png)

Let’s take a step back and ask the following question. How did we, as humans, learn how an apple looks? The way we learned most words was not by someone explaining to us what they mean; we learned them by repetition. We saw many objects during our childhood, and adults would tell us what these objects were. To learn what an apple was, we saw many apples throughout the years while hearing the word *apple*, until one day it clicked, and we knew what an apple was. In machine learning, that is what we get the computer to do. We show the computer many images, and we tell it which ones contain an apple (that constitutes our data). We repeat this process until the computer catches the right patterns and attributes that constitute an apple. At the end of the process, when we feed the computer a new image, it can use these patterns to determine whether the image contains an apple. Of course, we still need to program the computer so that it catches these patterns. For that, we have several techniques, which we will learn in this book.

#### [](/book/grokking-machine-learning/chapter-1/)And now that we’re at it, what is deep learning?

In[](/book/grokking-machine-learning/chapter-1/)[](/book/grokking-machine-learning/chapter-1/)[](/book/grokking-machine-learning/chapter-1/) the same way that machine learning is part of artificial intelligence, deep learning is a part of machine learning. In the previous section, we learned we have several techniques we use to get the computer to learn from data. One of these techniques has been performing tremendously well, so it has its own field of study called *deep learning**[](/book/grokking-machine-learning/chapter-1/)[](/book/grokking-machine-learning/chapter-1/)* (DL), which we define as follows and as shown in figure 1.3:

##### deep learning

The field of machine learning that uses certain objects called *neural networks**[](/book/grokking-machine-learning/chapter-1/)*

What are neural networks? We’ll learn about them in chapter 10. Deep learning is arguably the most used type of machine learning because it works really well. If we are looking at any of the cutting-edge applications, such as image recognition, text generation, playing Go, or self-driving cars, very likely we are looking at deep learning in some way or another.

![Figure 1.3 Deep learning is a part of machine learning.](https://drek4537l1klr.cloudfront.net/serrano/Figures/1-3.png)

In other words, deep learning is part of machine learning, which in turn is part of artificial intelligence. If this book were about transportation, then AI would be vehicles, ML would be cars, and DL would be Ferraris.

## [](/book/grokking-machine-learning/chapter-1/)How do we get machines to make decisions with data? The remember-formulate-predict framework

In[](/book/grokking-machine-learning/chapter-1/)[](/book/grokking-machine-learning/chapter-1/) the previous section, we discussed that machine learning consists of a set of techniques that we use to get the computer to make decisions based on data. In this section, we learn what is meant by making decisions based on data and how some of these techniques work. For this, let’s again analyze the process humans use to make decisions based on experience. This is what is called the *remember-formulate-predict framework*, shown in figure 1.4. The goal of machine learning is to teach computers how to think in the same way, following the same framework.

#### [](/book/grokking-machine-learning/chapter-1/)How do humans think?

When[](/book/grokking-machine-learning/chapter-1/)[](/book/grokking-machine-learning/chapter-1/) we, as humans, need to make a decision based on our experience, we normally use the following framework:

1. We **remember** past situations that were similar.
1. We **formulate** a general rule.
1. We use this rule to **predict** what may happen in the future.

For example, if the question is, “Will it rain today?,” the process to make a guess is the following:

1. We **remember** that last week it rained most of the time.
1. We **formulate** that in this place, it rains most of the time.
1. We **predict** that today it will rain.

We may be right or wrong, but at least we are trying to make the most accurate prediction we can based on the information we have.

![Figure 1.4 The remember-formulate-predict framework is the main framework we use in this book. It consists of three steps: (1) We remember previous data; (2) we formulate a general rule; and (3) we use that rule to make predictions about the future.](https://drek4537l1klr.cloudfront.net/serrano/Figures/1-4.png)

#### [](/book/grokking-machine-learning/chapter-1/)Some machine learning lingo—models and algorithms

Before[](/book/grokking-machine-learning/chapter-1/)[](/book/grokking-machine-learning/chapter-1/)[](/book/grokking-machine-learning/chapter-1/)[](/book/grokking-machine-learning/chapter-1/) we delve into more examples that illustrate the techniques used in machine learning, let’s define some useful terms that we use throughout this book. We know that in machine learning, we get the computer to learn how to solve a problem using data. The way the computer solves the problem is by using the data to build a *model*. What is a model? We define a model as follows:

##### model

A set of rules that represent our data and can be used to make predictions

We can think of a model as a representation of reality using a set of rules that mimic the existing data as closely as possible. In the rain example in the previous section, the model was our representation of reality, which is a world in which it rains most of the time. This is a simple world with one rule: it rains most of the time. This representation may or may not be accurate, but according to our data, it is the most accurate representation of reality that we can formulate. We later use this rule to make predictions on unseen data.

An *algorithm* is the process that we used to build the model. In the current example, the process is simple: we looked at how many days it rained and realized it was the majority. Of course, machine learning algorithms can get much more complicated than that, but at the end of the day, they are always composed of a set of steps. Our definition of algorithm follows:

##### algorithm

A procedure, or a set of steps, used to solve a problem or perform a computation. In this book, the goal of an algorithm is to build a model.

In short, a model is what we use to make predictions, and an algorithm is what we use to build the model. Those two definitions are easy to confuse and are often interchanged, but to keep them clear, let’s look at a few examples.

#### [](/book/grokking-machine-learning/chapter-1/)Some examples of models that humans use

In[](/book/grokking-machine-learning/chapter-1/)[](/book/grokking-machine-learning/chapter-1/)[](/book/grokking-machine-learning/chapter-1/) this section we focus on a common application of machine learning: spam detection. In the following examples, we will detect spam and non-spam emails. Non-spam emails are also referred to as *ham**[](/book/grokking-machine-learning/chapter-1/)*.

##### spam and ham

*spam* is the common term used for junk or unwanted email, such as chain letters, promotions, and so on. The term comes from a 1972 Monty Python sketch in which every item in the menu of a restaurant contained Spam as an ingredient. Among software developers, the term *ham* is used to refer to non-spam emails.

#### Example 1: An annoying email friend

In this example, our friend Bob likes to send us email. A lot of his emails are spam, in the form of chain letters. We are starting to get a bit annoyed with him. It is Saturday, and we just got a notification of an email from Bob. Can we guess if this email is spam or ham without looking at it?

To figure this out, we use the remember-formulate-predict method. First, let us **remember**, say, the last 10 emails that we got from Bob. That is our data. We remember that six of them were spam, and the other four were ham. From this information, we can **formulate****[](/book/grokking-machine-learning/chapter-1/)** the following model:

**Model 1**: Six out of every 10 emails that Bob sends us are spam.

This rule will be our model. Note, this rule does not need to be true. It could be outrageously wrong. But given our data, it is the best that we can come up with, so we’ll live with it. Later in this book, we learn how to evaluate models and improve them when needed.

Now that we have our rule, we can use it to **predict****[](/book/grokking-machine-learning/chapter-1/)** whether the email is spam. If six out of 10 of Bob’s emails are spam, then we can assume that this new email is 60% likely to be spam and 40% likely to be ham. Judging by this rule, it’s a little safer to think that the email is spam. Therefore, we predict that the email is spam (figure 1.5).

Again, our prediction may be wrong. We may open the email and realize it is ham. But we have made the prediction *to the best of our knowledge*. This is what machine learning is all about.

You may be thinking, can we do better? We seem to be judging every email from Bob in the same way, but there may be more information that can help us tell the spam and ham emails apart. Let’s try to analyze the emails a little more. For example, let’s see when Bob sent the emails to see if we find a pattern.

![Figure 1.5 A very simple machine learning model](https://drek4537l1klr.cloudfront.net/serrano/Figures/1-5.png)

#### Example 2: A seasonal annoying email friend

Let’s look more carefully at the emails that Bob sent us in the previous month. More specifically, we’ll look at what day he sent them. Here are the emails with dates and information about being spam or ham:

- Monday: Ham
- Tuesday: Ham
- Saturday: Spam
- Sunday: Spam
- Sunday: Spam
- Wednesday: Ham
- Friday: Ham
- Saturday: Spam
- Tuesday: Ham
- Thursday: Ham

Now things are different. Can you see a pattern? It seems that every email Bob sent during the week is ham, and every email he sent during the weekend is spam. This makes sense—maybe during the week he sends us work email, whereas during the weekend, he has time to send spam and decides to roam free. So, we can **formulate** a more educated rule, or model, as follows:

**Model 2**: Every email that Bob sends during the week is ham, and those he sends during the weekend are spam.

Now let’s look at what day it is today. If it is Sunday and we just got an email from Bob, then we can **predict** with great confidence that the email he sent is spam (figure 1.6). We make this prediction, and without looking, we send the email to the trash and carry on with our day.

![Figure 1.6 A slightly more complex machine learning model](https://drek4537l1klr.cloudfront.net/serrano/Figures/1-6.png)

#### Example 3: Things are getting complicated!

Now, let’s say we continue with this rule, and one day we see Bob in the street, and he asks, “Why didn’t you come to my birthday party?” We have no idea what he is talking about. It turns out last Sunday he sent us an invitation to his birthday party, and we missed it! Why did we miss it? Because he sent it on the weekend, and we assumed that it would be spam. It seems that we need a better model. Let’s go back to look at Bob’s emails—this is our **remember** step. Let’s see if we can find a pattern.

- 1 KB: Ham
- 2 KB: Ham
- 16 KB: Spam
- 20 KB: Spam
- 18 KB: Spam
- 3 KB: Ham
- 5 KB: Ham
- 25 KB: Spam
- 1 KB: Ham
- 3 KB: Ham

What do we see? It seems that the large emails tend to be spam, whereas the smaller ones tend to be ham. This makes sense, because the spam emails frequently have large attachments.

So, we can **formulate** the following rule:

**Model 3**: Any email of size 10 KB or larger is spam, and any email of size less than 10 KB is ham.

Now that we have formulated our rule, we can make a **prediction**. We look at the email we received today from Bob, and the size is 19 KB. So, we conclude that it is spam (figure 1.7).

![Figure 1.7 Another slightly more complex machine learning model](https://drek4537l1klr.cloudfront.net/serrano/Figures/1-7.png)

Is *this* the end of the story? Not even close.

But before we keep going, notice that to make our predictions, we used the day of the week and the size of the email. These are examples of *features**[](/book/grokking-machine-learning/chapter-1/)*. A feature is one of the most important concepts in this book.

##### feature

Any property or characteristic of the data that the model can use to make predictions

You can imagine that there are many more features that could indicate if an email is spam or ham. Can you think of some more? In the next paragraphs, we’ll see a few more features.

#### Example 4: More?

Our two classifiers were good, because they rule out large emails and emails sent on the weekends. Each one of them uses exactly one of these two features. But what if we wanted a rule that worked with both features? Rules like the following may work:

**Model 4**: If an email is larger than 10 KB or it is sent on the weekend, then it is classified as spam. Otherwise, it is classified as ham.

**Model 5**: If the email is sent during the week, then it must be larger than 15 KB to be classified as spam. If it is sent during the weekend, then it must be larger than 5 KB to be classified as spam. Otherwise, it is classified as ham.

Or we can get even more complicated.

**Model 6**: Consider the number of the day, where Monday is 0, Tuesday is 1, Wednesday is 2, Thursday is 3, Friday is 4, Saturday is 5, and Sunday is 6. If we add the number of the day and the size of the email (in KB), and the result is 12 or more, then the email is classified as spam (figure 1.8). Otherwise, it is classified as ham.

![Figure 1.8 An even more complex machine learning model](https://drek4537l1klr.cloudfront.net/serrano/Figures/1-8.png)

All of these are valid models. We can keep creating more and more models by adding layers of complexity or by looking at even more features. Now the question is, which is the best model? This is where we start to need the help of a computer.

#### [](/book/grokking-machine-learning/chapter-1/)Some examples of models that machines use

The[](/book/grokking-machine-learning/chapter-1/) [](/book/grokking-machine-learning/chapter-1/)[](/book/grokking-machine-learning/chapter-1/)goal is to make the computer think the way we think, namely, use the remember-formulate-predict framework. In a nutshell, here is what the computer does in each of the steps:

**Remember**: Look at a huge table of data.

**Formulate**: Create models by going through many rules and formulas, and check which model fits the data best.

**Predict**: Use the model to make predictions about future data.

This process is not much different than what we did in the previous section. The great advancement here is that the computer can build models quickly by going through many formulas and combinations of rules until it finds one that fits the existing data well. For example, we can build a spam classifier with features such as the sender, the date and time of day, the number of words, the number of spelling mistakes, and the appearances of certain words such as *buy* or *win*. A model could easily look like the following logical statement:

**Model 7**:

- If the email has two or more spelling mistakes, then it is classified as spam.
- If it has an attachment larger than 10 KB, it is classified as spam.
- If the sender is not in our contact list, it is classified as spam.
- If it has the words *buy* and *win*, it is classified as spam.
- Otherwise, it is classified as ham.

It could also look like the following formula:

**Model 8**: If (size) + 10 (number of spelling mistakes) – (number of appearances of the word “mom”) + 4 (number of appearances of the word “buy”) > 10, then we classify the message as spam (figure 1.9). Otherwise, we classify it as ham.

![Figure 1.9 A much more complex machine learning model, found by a computer](https://drek4537l1klr.cloudfront.net/serrano/Figures/1-9.png)

Now the question is, which is the best rule? The quick answer is the one that fits the data best, although the real answer is the one that best generalizes to new data. At the end of the day, we may end up with a complicated rule, but the computer can formulate it and use it to make predictions quickly. Our next question is, how do we build the best model? That is exactly what this book is about.

## [](/book/grokking-machine-learning/chapter-1/)Summary

- Machine learning is easy! Anyone can learn it and use it, regardless of their background. All that is needed is a desire to learn and great ideas to implement!
- Machine learning is tremendously useful, and it is used in most disciplines. From science to technology to social problems and medicine, machine learning is making an impact and will continue doing so.
- Machine learning is common sense, done by a computer. It mimics the ways humans think to make decisions quickly and accurately.
- Just like humans make decisions based on experience, computers can make decisions based on previous data. This is what machine learning is all about.

Machine learning uses the remember-formulate-predict framework, as follows:

- **Remember**: look at the previous data.
- **Formulate**: build a model, or a rule, based on this data.
- **Predict**: use the model to make predictions about future data.
