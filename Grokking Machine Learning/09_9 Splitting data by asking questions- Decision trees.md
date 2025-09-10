# [](/book/grokking-machine-learning/chapter-9/)9 Splitting data by asking questions: Decision trees

### In this chapter

- what is a decision tree
- using decision trees for classification and regression
- building an app-recommendation system using users’ information
- accuracy, Gini index, and entropy, and their role in building decision trees
- using Scikit-Learn to train a decision tree on a university admissions dataset

![](https://drek4537l1klr.cloudfront.net/serrano/Figures/CH09_F01_Serrano_Text.png)

In this chapter, we cover decision trees. Decision trees are powerful classification and regression models, which also give us a great deal of information about our dataset. Just like the previous models we’ve learned in this book, decision trees are trained with labeled data, where the labels that we want to predict can be classes (for classification) or values (for regression). For most of this chapter, we focus on decision trees for classification, but near the end of the chapter, we describe decision trees for regression. However, the structure and training process of both types of tree is similar. In this chapter, we develop several use cases, including an app-recommendation system and a model for predicting admissions at a university.

Decision trees follow an intuitive process to make predictions—one that very much resembles human reasoning. Consider the following scenario: we want to decide whether we should wear a jacket today. What does the decision process look like? We may look outside and check if it’s raining. If it’s raining, then we definitely wear a jacket. If it’s not, then maybe we check the temperature. If it is hot, then we don’t wear a jacket, but if it is cold, then we wear a jacket. In figure 9.1, we can see a graph of this decision process, where the decisions are made by traversing the tree from top to bottom.

![Figure 9.1 A decision tree used to decide whether we want to wear a jacket or not on a given day. We make the decision by traversing the tree down and taking the branch corresponding to each correct answer.](https://drek4537l1klr.cloudfront.net/serrano/Figures/9-1.png)

Our decision process looks like a tree, except it is upside down. The tree is formed of vertices, called *nodes**[](/book/grokking-machine-learning/chapter-9/)*, and edges. On the very top, we can see the *root node**[](/book/grokking-machine-learning/chapter-9/)*, from which two branches emanate. Each of the nodes has either two or zero branches (edges) emanating from them, and for this reason, we call it a *binary tree**[](/book/grokking-machine-learning/chapter-9/)[](/book/grokking-machine-learning/chapter-9/)*. The nodes that have two branches emanating from them are called *decision nodes*, and the nodes with no branches emanating from them are called *leaf nodes*, or *leaves**[](/book/grokking-machine-learning/chapter-9/)*. This arrangement of nodes, leaves, and edges is what we call a decision tree. Trees are natural objects in computer science, because computers break every process into a sequence of binary operations.

The simplest possible decision tree, called a *decision stump**[](/book/grokking-machine-learning/chapter-9/)[](/book/grokking-machine-learning/chapter-9/)*, is formed by a single decision node (the root node) and two leaves. This represents a single yes-or-no question, based on which we immediately make a decision.

The depth of a decision tree is the number of levels underneath the root node. Another way to measure it is by the length of the longest path from the root node to a leaf, where a path is measured by the number of edges it contains. The tree in figure 9.1 has a depth of 2. A decision stump has a depth of 1.

Here is a summary of the definitions we’ve learned so far:

##### decision tree

[](/book/grokking-machine-learning/chapter-9/) A machine learning model based on yes-or-no questions and represented by a binary tree. The tree has a root node, decision nodes, leaf nodes, and branches.

##### root node

The topmost node of the tree. It contains the first yes-or-no question. For convenience, we refer to it as the *root*.

##### decision node

[](/book/grokking-machine-learning/chapter-9/) Each yes-or-no question in our model is represented by a decision node, with two branches emanating from it (one for the “yes” answer, and one for the “no” answer).

##### leaf node

[](/book/grokking-machine-learning/chapter-9/) A node that has no branches emanating from it. These represent the decisions we make after traversing the tree. For convenience, we refer to them as *leaves*.

##### branch

[](/book/grokking-machine-learning/chapter-9/) The two edges emanating from each decision node, corresponding to the “yes” and “no” answers to the question in the node. In this chapter, by convention, the branch to the left corresponds to “yes” and the branch to the right to “no.”

##### depth

[](/book/grokking-machine-learning/chapter-9/) The number of levels in the decision tree. Alternatively, it is the number of branches on the longest path from the root node to a leaf node.

Throughout this chapter, nodes are drawn as rectangles with rounded edges, the answers in the branches as diamonds, and leaves as ovals. Figure 9.2 shows how a decision tree looks in general.

![Figure 9.2 A regular decision tree with a root node, decision nodes, branches, and leaves. Note that each decision node contains a yes-or-no question. From each possible answer, one branch emanates, which can lead to another decision node or a leaf. This tree has a depth of 2, because the longest path from a leaf to the root goes through two branches.](https://drek4537l1klr.cloudfront.net/serrano/Figures/9-2.png)

How did we build this tree? Why were those the questions we asked? We could have also checked if it was Monday, if we saw a red car outside, or if we were hungry, and built the following decision tree:

![Figure 9.3 A second (maybe not as good) decision tree we could use to decide whether we want to wear a jacket on a given day](https://drek4537l1klr.cloudfront.net/serrano/Figures/9-3.png)

Which tree do we think is better when it comes to deciding whether or not to wear a jacket: tree 1 (figure 9.1) or tree 2 (figure 9.3)? Well, as humans, we have enough experience to figure out that tree 1 is much better than tree 2 for this decision. How would a computer know? Computers don’t have experience per se, but they have something similar, which is data. If we wanted to think like a computer, we could just go over all possible trees, try each one of them for some time—say, one year—and compare how well they did by counting how many times we made the right decision using each tree. We’d imagine that if we use tree 1, we were correct most days, whereas if we used tree 2, we may have ended up freezing on a cold day without a jacket or wearing a jacket on an extremely hot day. All a computer has to do is go over all trees, collect data, and find which one is the best one, right?

Almost! Unfortunately, even for a computer, searching over all the possible trees to find the most effective one would take a really long time. But luckily, we have algorithms that make this search much faster, and thus, we can use decision trees for many wonderful applications, including spam detection, sentiment analysis, and medical diagnosis. In this chapter, we’ll go over an algorithm for constructing good decision trees quickly. In a nutshell, we build the tree one node at a time, starting from the top. To pick the right question corresponding to each node, we go over all the possible questions we can ask and pick the one that is right the highest number of times. The process goes as follows:

#### Picking a good first question

We need to pick a good first question for the root of our tree. What would be a good question that helps us decide whether to wear a jacket on a given day? Initially, it can be anything. Let’s say we come up with five candidates for our first question:

1. Is it raining?
1. Is it cold outside?
1. Am I hungry?
1. Is there a red car outside?
1. Is it Monday?

Out of these five questions, which one seems like the best one to help us decide whether we should wear a jacket? Our intuition says that the last three questions are useless to help us decide. Let’s say that from experience, we’ve noticed that among the first two, the first one is more useful. We use that question to start building our tree. So far, we have a simple decision tree, or a decision stump, consisting of that single question, as illustrated in Figure 9.4.

![Figure 9.4 A simple decision tree (decision stump) that consists of only the question, “Is it raining?” If the answer is yes, the decision we make is to wear a jacket.](https://drek4537l1klr.cloudfront.net/serrano/Figures/9-4.png)

Can we do better? Imagine that we start noticing that when it rains, wearing a jacket is always the correct decision. However, there are days on which it doesn’t rain, and not wearing a jacket is not the correct decision. This is where question 2 comes to our rescue. We use that question to help us in the following way: after we check that it is not raining, *then* we check the temperature, and if it is cold, we decide to wear a jacket. This turns the left leaf of the tree into a node, with two leaves emanating from it, as shown in figure 9.5.

![Figure 9.5 A slightly more complicated decision tree than the one in figure 9.4, where we have picked one leaf and split it into two further leaves. This is the same tree as in figure 9.1.](https://drek4537l1klr.cloudfront.net/serrano/Figures/9-5.png)

Now we have our decision tree. Can we do better? Maybe we can if we add more nodes and leaves to our tree. But for now, this one works very well. In this example, we made our decisions using our intuition and our experience. In this chapter, we learn an algorithm that builds these trees solely based on data.

Many questions may arise in your head, such as the following:

1. How exactly do you decide which is the best possible question to ask?
1. Does the process of always picking the best possible question actually get us to build *the* best decision tree?
1. Why don’t we instead build all the possible decision trees and pick the best one from there?
1. Will we code this algorithm?
1. Where can we find decision trees in real life?
1. We can see how decision trees work for classification, but how do they work for regression?

This chapter answers all of these questions, but here are some quick answers:

1.  **How exactly do you decide which is the best possible question to ask?**

We have several ways to do this. The simplest one is using accuracy, which means: which question helps me be correct more often? However, in this chapter, we also learn other methods, such as Gini index or entropy.

1.  **Does the process of always picking the best possible question actually get us to build** *the* **best decision tree?**

Actually, this process does not guarantee that we get the best possible tree. This is what we call a *greedy algorithm*. Greedy algorithms work as follows: at every point, the algorithm makes the best possible available move. They tend to work well, but it’s not always the case that making the best possible move at each timestep gets you to the best overall outcome. There may be times in which asking a weaker question groups our data in a way that we end up with a better tree at the end of the day. However, the algorithms for building decision trees tend to work very well and very quickly, so we’ll live with this. Look at the algorithms that we see in this chapter, and try to figure out ways to improve them by removing the greedy property!

1.  **Why don’t we instead build all the possible decision trees and pick the best one from there?**

The number of possible decision trees is very large, especially if our dataset has many features. Going through all of them would be very slow. Here, finding each node requires only a linear search across the features and not across all the possible trees, which makes it much faster.

1.  **Will we code this algorithm?**

This algorithm can be coded by hand. However, we’ll see that because it is recursive, the coding can get a bit tedious. Thus, we’ll use a useful package called Scikit-Learn to build decision trees with real data.

1.  **Where can we find decision trees in real life?**

In many places! They are used extensively in machine learning, not only because they work very well but also because they give us a lot of information on our data. Some places in which decision trees are used are in recommendation systems (to recommend videos, movies, apps, products to buy, etc)., in spam classification (to decide whether or not an email is spam), in sentiment analysis (to decide whether a sentence is happy or sad), and in biology (to decide whether or not a patient is sick or to help identify certain hierarchies in species or in types of genomes).

1.  **We can see how decision trees work for classification, but how do they work for regression?**

A regression decision tree looks exactly like a classification decision tree, except for the leaves. In a classification decision tree, the leaves have classes, such as yes and no. In a regression decision tree, the leaves have values, such as 4, 8.2, or –199. The prediction our model makes is given by the leaf at which we arrived when traversing the tree in a downward fashion.

The first use case that we’ll study in this chapter is a popular application in machine learning, and one of my favorites: recommendation systems.

The code for this chapter is available in this GitHub repository: [https://github.com/luisguiserrano/manning/tree/master/Chapter_9_Decision_Trees](https://github.com/luisguiserrano/manning/tree/master/Chapter_9_Decision_Trees).

## [](/book/grokking-machine-learning/chapter-9/)The problem: We need to recommend apps to users according to what they are likely to download

Recommendation[](/book/grokking-machine-learning/chapter-9/)[](/book/grokking-machine-learning/chapter-9/) systems are one of the most common and exciting applications in machine learning. Ever wonder how Netflix recommends movies, YouTube guesses which videos you may watch, or Amazon shows you products you might be interested in buying? These are all examples of recommendation systems. One simple and interesting way to see recommendation problems is to consider them classification problems. Let’s start with an easy example: our very own app-recommendation system using decision trees.

Let’s say we want to build a system that recommends to users which app to download among the following options. We have the following three apps in our store (figure 9.6):

- **Atom Count**: an app that counts the number of atoms in your body
- **Beehive Finder**: an app that maps your location and finds the closest beehives
- **Check Mate Mate**: an app for finding Australian chess players

![Figure 9.6 The three apps we are recommending: Atom Count, an app for counting the number of atoms in your body; Beehive Finder, an app for locating the nearest beehives to your location; and Check Mate Mate, an app for finding Australian chess players in your area](https://drek4537l1klr.cloudfront.net/serrano/Figures/9-6.png)

The training data is a table with the platform used by the user (iPhone or Android), their age, and the app they have downloaded (in real life there are many more platforms, but for simplicity we’ll assume that these are the only two options). Our table contains six people, as shown in table 9.1.

##### Table 9.1 A dataset with users of an app store. For each customer, we record their platform, age, and the app they downloaded.[(view table figure)](https://drek4537l1klr.cloudfront.net/serrano/HighResolutionFigures/table_9-1.png)

| Platform | Age | App |
| --- | --- | --- |
| iPhone | 15 | Atom Count |
| iPhone | 25 | Check Mate Mate |
| Android | 32 | Beehive Finder |
| iPhone | 35 | Check Mate Mate |
| Android | 12 | Atom Count |
| Android | 14 | Atom Count |

Given this table, which app would you recommend to each of the following three customers?

- **Customer 1**: a 13-year-old iPhone user
- **Customer 2**: a 28-year-old iPhone user
- **Customer 3**: a 34-year-old Android user

What we should do follows:

**Customer 1:** a 13-year-old iPhone user. To this customer, we should recommend Atom Count, because it seems (looking at the three customers in their teens) that young people tend to download Atom Count.

**Customer 2:** a 28-year-old iPhone user. To this customer, we should recommend Check Mate Mate, because looking at the two iPhone users in the dataset (aged 25 and 35), they both downloaded Check Mate Mate.

**Customer 3:** a 34-year-old Android user. To this customer, we should recommend Beehive Finder, because there is one Android user in the dataset who is 32 years old, and they downloaded Beehive Finder.

However, going customer by customer seems like a tedious job. Next, we’ll build a decision tree to take care of all customers at once.

## [](/book/grokking-machine-learning/chapter-9/)The solution: Building an app-recommendation system

In[](/book/grokking-machine-learning/chapter-9/)[](/book/grokking-machine-learning/chapter-9/) this section, we see how to build an app-recommendation system using decision trees. In a nutshell, the algorithm to build a decision tree follows:

1. Figure out which of the data is the most useful to decide which app to recommend.
1. This feature splits the data into two smaller datasets.
1. Repeat processes 1 and 2 for each of the two smaller datasets.

In other words, what we do is decide which of the two features (platform or age) is more successful at determining which app the users will download and pick this one as our root of the decision tree. Then, we iterate over the branches, always picking the most determining feature for the data in that branch, thus building our decision tree.

#### [](/book/grokking-machine-learning/chapter-9/)First step to build the model: Asking the best question

The[](/book/grokking-machine-learning/chapter-9/)[](/book/grokking-machine-learning/chapter-9/) first step to build our model is to figure out the most useful feature: in other words, the most useful question to ask. First, let’s simplify our data a little bit. Let’s call everyone under 20 years old “Young” and everyone 20 or older “Adult” (don’t worry—we’ll go back to the original dataset soon, in the section “Splitting the data using continuous features, such as age”). Our modified dataset is shown in table 9.2.

##### Table 9.2 A simplified version of the dataset in table 9.1, where the age column has been simplified to two categories, “young” and “adult”[(view table figure)](https://drek4537l1klr.cloudfront.net/serrano/HighResolutionFigures/table_9-2.png)

| Platform | Age | App |
| --- | --- | --- |
| iPhone | Young | Atom Count |
| iPhone | Adult | Check Mate Mate |
| Android | Adult | Beehive Finder |
| iPhone | Adult | Check Mate Mate |
| Android | Young | Atom Count |
| Android | Young | Atom Count |

The building blocks of decision trees are questions of the form “Does the user use an iPhone?” or “Is the user young?” We need one of these to use as our root of the tree. Which one should we pick? We should pick the one that best determines the app they downloaded. To decide which question is better at this, let’s compare them.

#### First question: Does the user use an iPhone or Android?

This question splits the users into two groups, the iPhone users and Android users. Each group has three users in it. But we need to keep track of which app each user downloaded. A quick look at table 9.2 helps us notice the following:

- Of the iPhone users, one downloaded Atom Count and two downloaded Check Mate Mate.
- Of the Android users, two downloaded Atom Count and one downloaded Beehive Finder.

The resulting decision stump is shown in figure 9.7.

![Figure 9.7 If we split our users by platform, we get this split: the iPhone users are on the left, and the Android users on the right. Of the iPhone users, one downloaded Atom Count and two downloaded Check Mate Mate. Of the Android users, two downloaded Atom Count and one downloaded Beehive Finder.](https://drek4537l1klr.cloudfront.net/serrano/Figures/9-7.png)

Now let’s see what happens if we split them by age.

#### Second question: Is the user young or adult?

This question splits the users into two groups, the young and the adult. Again, each group has three users in it. A quick look at table 9.2 helps us notice what each user downloaded, as follows:

- The young users all downloaded Atom Count.
- Of the adult users, two downloaded Atom Count and one downloaded Beehive Finder.

The resulting decision stump is shown in figure 9.8.

![Figure 9.8 If we split our users by age, we get this split: the young are on the left, and the adults on the right. Out of the young users, all three downloaded Atom Count. Out of the adult users, one downloaded Beehive Finder and two downloaded Check Mate Mate.](https://drek4537l1klr.cloudfront.net/serrano/Figures/9-8.png)

From looking at figures 9.7 and 9.8, which one looks like a better split? It seems that the second one (based on age) is better, because it has picked up on the fact that all three young people downloaded Atom Count. But we need the computer to figure out that age is a better feature, so we’ll give it some numbers to compare. In this section, we learn three ways to compare these two splits: accuracy, Gini impurity, and entropy. Let’s start with the first one: accuracy.

#### Accuracy: How often is our model correct?

We[](/book/grokking-machine-learning/chapter-9/) learned about accuracy in chapter 7, but here is a small recap. Accuracy is the fraction of correctly classified data points over the total number of data points.

Suppose that we are allowed only one question, and with that one question, we must determine which app to recommend to our users. We have the following two classifiers:

- **Classifier** 1: asks the question “What platform do you use?” and from there, determines what app to recommend
- **Classifier 2**: asks the question “What is your age?” and from there, determines what app to recommend

Let’s look more carefully at the classifiers. The key observation follows: if we must recommend an app by asking only one question, our best bet is to look at all the people who answered with the same answer and recommend the most common app among them.

**Classifier 1**: What platform do you use?

- If the answer is “iPhone,” then we notice that of the iPhone users, the majority downloaded Check Mate Mate. Therefore, we recommend Check Mate Mate to all the iPhone users. We are correct **two times out of three**
- If the answer is “Android,” then we notice that of the Android users, the majority downloaded Atom Count, so that is the one we recommend to all the Android users. We are correct **two times out of three**.

**Classifier 2**: What is your age?

- If the answer is “young,” then we notice that all the young people downloaded Atom Count, so that is the recommendation we make. We are correct **three times out of three**.
- If the answer is “adult,” then we notice that of the adults, the majority downloaded Check Mate Mate, so we recommend that one. We are correct **two times out of three**.

Notice that classifier 1 is correct **four times out of six**, and classifier 2 is correct **five times out of six.** Therefore, for this dataset, classifier 2 is better. In figure 9.9, you can see the two classifiers with their accuracy. Notice that the questions are reworded so that they have yes-or-no answers, which doesn’t change the classifiers or the outcome.

![Figure 9.9 Classifier 1 uses platform, and classifier 2 uses age. To make the prediction at each leaf, each classifier picks the most common label among the samples in that leaf. Classifier 1 is correct four out of six times, and classifier 2 is correct five out of six times. Therefore, based on accuracy, classifier 2 is better.](https://drek4537l1klr.cloudfront.net/serrano/Figures/9-9.png)

#### Gini impurity index: How diverse is my dataset?

The[](/book/grokking-machine-learning/chapter-9/) *Gini impurity index,* or *Gini index*, is another way we can compare the platform and age splits. The Gini index is a measure of diversity in a dataset. In other words, if we have a set in which all the elements are similar, this set has a low Gini index, and if all the elements are different, it has a large Gini index. For clarity, consider the following two sets of 10 colored balls (where any two balls of the same color are indistinguishable):

- **Set 1**: eight red balls, two blue balls
- **Set 2**: four red balls, three blue balls, two yellow balls, one green ball

Set 1 looks more pure than set 2, because set 1 contains mostly red balls and a couple of blue ones, whereas set 2 has many different colors. Next, we devise a measure of impurity that assigns a low value to set 1 and a high value to set 2. This measure of impurity relies on probability. Consider the following question:

If we pick two random elements of the set, what is the probability that they have a different color? The two elements don’t need to be distinct; we are allowed to pick the same element twice.

For set 1, this probability is low, because the balls in the set have similar colors. For set 2, this probability is high, because the set is diverse, and if we pick two balls, they’re likely to be of different colors. Let’s calculate these probabilities. First, notice that by the law of complementary probabilities (see the section “What the math just happened?” in chapter 8), the probability that we pick two balls of different colors is 1 minus the probability that we pick two balls of the same color:

P(picking two balls of different color) = 1 – P(picking two balls of the same color)

Now let’s calculate the probability that we pick two balls of the same color. Consider a general set, where the balls have *n* colors. Let’s call them color 1, color 2, all the way up to color *n*. Because the two balls must be of one of the *n* colors, the probability of picking two balls of the same color is the sum of probabilities of picking two balls of each of the *n* colors:

P(picking two balls of the same color) = P(both balls are color 1) + P(both balls are color 2) + … + P(both balls are color *n*)

What we used here is the sum rule for disjoint probabilities, that states the following:

##### sum rule for disjoint probabilities

[](/book/grokking-machine-learning/chapter-9/) If two events *E* and *F* are disjoint, namely, they never occur at the same time, then the probability of either one of them happening (the union of the events) is the sum of the probabilities of each of the events. In other words,

*P*(*E* ∪ *F*) = *P*(*E*) + *P*(*F*)

Now, let’s calculate the probability that two balls have the same color, for each of the colors. Notice that we’re picking each ball completely independently from the others. Therefore, by the product rule for independent probabilities (section “What the math just happened?” in chapter 8), the probability that both balls have color 1 is the square of the probability that we pick one ball and it is of color 1. In general, if *p*i is the probability that we pick a random ball and it is of color *i*, then

P(both balls are color *i*) = *p*i2.

Putting all these formulas together (figure 9.10), we get that

P(picking two balls of different colors) = 1 – *p*12 – *p*22 – … – *p*n2.

This last formula is the Gini index of the set.

![Figure 9.10 Summary of the calculation of the Gini impurity index](https://drek4537l1klr.cloudfront.net/serrano/Figures/9-10.png)

Finally, the probability that we pick a random ball of color *i* is the number of balls of color *i* divided by the total number of balls. This leads to the formal definition of the Gini index.

##### gini impurity index

In a set with *m* elements and *n* classes, with *a*i elements belonging to the *i*-th class, the Gini impurity index is

*Gini* = 1 – *p*12 – *p*22 – … – *p*n2,

where *p*i = *a*i / *m*. This can be interpreted as the probability that if we pick two random elements out of the set, they belong to different classes.

Now we can calculate the Gini index for both of our sets. For clarity, the calculation of the Gini index for set 1 is illustrated in figure 9.11 (with red and blue replaced by black and white).

**Set 1**: {red, red, red, red, red, red, red, red, blue, blue} (eight red balls, two blue balls)

**Set 2**: {red, red, red, red, blue, blue, blue, yellow, yellow, green}

Notice that, indeed, the Gini index of set 1 is larger than that of set 2.

![Figure 9.11 The calculation of the Gini index for the set with eight black balls and two white balls. Note that if the total area of the square is 1, the probability of picking two black balls is 0.82, and the probability of picking two white balls is 0.22 (these two are represented by the shaded squares). Thus, the probability of picking two balls of a different color is the remaining area, which is 1 – 0.82 – 0.22 =0.32. That is the Gini index.](https://drek4537l1klr.cloudfront.net/serrano/Figures/9-111.png)

How do we use the Gini index to decide which of the two ways to split the data (age or platform) is better? Clearly, if we can split the data into two purer datasets, we have performed a better split. Thus, let’s calculate the Gini index of the set of labels of each of the leaves. Looking at figure 9.12, here are the labels of the leaves (where we abbreviate each app by the first letter in its name):

Classifier 1 (by platform):

- Left leaf (iPhone): {A, C, C}
- Right leaf (Android): {A, A, B}

Classifier 2 (by age):

- Left leaf (young): {A, A, A}
- Right leaf (adult): {B, C, C}

The Gini indices of the sets {A, C, C}, {A, A, B}, and {B, C, C} are all the same: . The Gini index of the set {A, A, A} is . In general, the Gini index of a pure set is always 0. To measure the purity of the split, we average the Gini indices of the two leaves. Therefore, we have the following calculations:

Classifier 1 (by platform):

Average Gini index = 1/2(0.444+0.444) = 0.444

Classifier 2 (by age):

Average Gini index = 1/2(0.444+0) = 0.222

![Figure 9.12 The two ways to split the dataset, by platform and age, and their Gini index calculations. Notice that splitting the dataset by age gives us two smaller datasets with a lower average Gini index. Therefore, we choose to split the dataset by age.](https://drek4537l1klr.cloudfront.net/serrano/Figures/9-12.png)

We conclude that the second split is better, because it has a lower average Gini index.

##### aside

The Gini impurity index should not be confused with the Gini coefficient. The Gini coefficient is used in statistics to calculate the income or wealth inequality in countries. In this book, whenever we talk about the Gini index, we are referring to the Gini impurity index.

#### Entropy: Another measure of diversity with strong applications in information theory

In [](/book/grokking-machine-learning/chapter-9/)this section, we learn another measure of homogeneity in a set—its entropy—which is based on the physical concept of entropy and is highly important in probability and information theory. To understand entropy, we look at a slightly strange probability question. Consider the same two sets of colored balls as in the previous section, but think of the colors as an ordered set.

- **Set 1**: {red, red, red, red, red, red, red, red, blue, blue} (eight red balls, two blue balls)
- **Set 2**: {red, red, red, red, blue, blue, blue, yellow, yellow, green} (four red balls, three blue balls, two yellow balls, one green ball)

Now, consider the following scenario: we have set 1 inside a bag, and we start picking balls out of this bag and immediately return each ball we just picked back to the bag. We record the colors of the balls we picked. If we do this 10 times, imagine that we get the following sequence:

- Red, red, red, blue, red, blue, blue, red, red, red

Here is the main question that defines entropy:

What is the probability that, by following the procedure described in the previous paragraph, we get the exact sequence that defines set 1, which is {red, red, red, red, red, red, red, red, blue, blue}?

This probability is not very large, because we must be really lucky to get this sequence. Let’s calculate it. We have eight red balls and two blue balls, so the probability that we get a red ball is  and the probability that we get a blue ball is . Because all the draws are independent, the probability that we get the desired sequence is

.

This is tiny, but can you imagine the corresponding probability for set 2? For set 2, we are picking balls out of a bag with four red balls, three blue balls, two yellow balls, and one green ball and hoping to obtain the following sequence:

- Red, red, red, red, blue, blue, blue, yellow, yellow, green.

This is nearly impossible, because we have many colors and not many balls of each color. This probability, which is calculated in a similar way, is

.

The more diverse the set, the more unlikely we’ll be able to get the original sequence by picking one ball at a time. In contrast, the most pure set, in which all balls are of the same color, is easy to obtain this way. For example, if our original set has 10 red balls, each time we pick a random ball, the ball is red. Thus, the probability of getting the sequence {red, red, red, red, red, red, red, red, red, red} is 1.

These numbers are very small for most cases—and this is with only 10 elements. Imagine if our dataset had one million elements. We would be dealing with tremendously small numbers. When we have to deal with really small numbers, using logarithms is the best method, because they provide a convenient way to write small numbers. For instance, 0.000000000000001 is equal to 10–15, so its logarithm in base 10 is –15, which is a much nicer number to work with.

The entropy is defined as follows: we start with the probability that we recover the initial sequence by picking elements in our set, one at a time, with repetition. Then we take the logarithm, and divide by the total number of elements in the set. Because decision trees deal with binary decisions, we’ll be using logarithms in base 2. The reason we took the negative of the logarithm is because logarithms of very small numbers are all negative, so we multiply by –1 to turn it into a positive number. Because we took a negative, the more diverse the set, the higher the entropy.

Now we can calculate the entropies of both sets and expand them using the following two identities:

- *log*(*ab*) = *log*(*a*) + *log*(*b*)
- *log*(*a*c) = *c* *log*(*a*)

[](/book/grokking-machine-learning/chapter-9/)**Set 1**: {red, red, red, red, red, red, red, red, blue, blue} (eight red balls, two blue balls)

**Set 2**: {red, red, red, red, blue, blue, blue, yellow, yellow, green}

Notice that the entropy of set 2 is larger than the entropy of set 1, which implies that set 2 is more diverse than set 1. The following is the formal definition of entropy:

##### entropy

[](/book/grokking-machine-learning/chapter-9/) In a set with *m* elements and *n* classes, with *a*i elements belonging to the *i*-th class, the entropy is

We can use entropy to decide which of the two ways to split the data (platform or age) is better in the same way as we did with the Gini index. The rule of thumb is that if we can split the data into two datasets with less combined entropy, we have performed a better split. Thus, let’s calculate the entropy of the set of labels of each of the leaves. Again, looking at figure 9.12, here are the labels of the leaves (where we abbreviate each app by the first letter in its name):

Classifier 1 (by platform):

Left leaf: {A, C, C}

Right leaf: {A, A, B}

Classifier 2 (by age):

Left leaf: {A, A, A}

Right leaf: {B, C, C}

The entropies of the sets {A, C, C}, {A, A, B}, and {B, C, C} are all the same: . The entropy of the set {A, A, A} is . In general, the entropy of a set in which all elements are the same is always 0. To measure the purity of the split, we average the entropy of the sets of labels of the two leaves, as follows (illustrated in figure 9.13):

Classifier 1 (by platform):

Average entropy = 1/2(0.918 + 0.918) = 0.918

Classifier 2 (by age):

Average entropy = 1/2(0.918+0) = 0.459

![Figure 9.13 The two ways to split the dataset, by platform and age, and their entropy calculations. Notice that splitting the dataset by age gives us two smaller datasets with a lower average entropy. Therefore, we again choose to split the dataset by age.](https://drek4537l1klr.cloudfront.net/serrano/Figures/9-131.png)

Thus, again we conclude that the second split is better, because it has a lower average entropy.

Entropy is a tremendously important concept in probability and statistics, because it has strong connections with information theory, mostly thanks to the work of Claude Shannon. In fact, an important concept called *information gain**[](/book/grokking-machine-learning/chapter-9/)* is precisely the change in entropy. To learn more on the topic, please see appendix C for a video and a blog post which covers this topic in much more detail.

#### Classes of different sizes? No problem: We can take weighted averages

In the previous sections we learned how to perform the best possible split by minimizing average Gini impurity index or entropy. However, imagine that you have a dataset with eight data points (which when training the decision tree, we also refer to as samples), and you split it into two datasets of sizes six and two. As you may imagine, the larger dataset should count for more in the calculations of Gini impurity index or entropy. Therefore, instead of considering the average, we consider the weighted average, where at each leaf, we assign the proportion of points corresponding to that leaf. Thus, in this case, we would weigh the first Gini impurity index (or entropy) by 6/8, and the second one by 2/8. Figure 9.14 shows an example of a weighted average Gini impurity index and a weighted average entropy for a sample split.

![Figure 9.14 A split of a dataset of size eight into two datasets of sizes six and two. To calculate the average Gini index and the average entropy, we weight the index of the left dataset by 6/8 and that of the right dataset by 2/8. This results in a weighted Gini index of 0.333 and a weighted entropy of 0.689.](https://drek4537l1klr.cloudfront.net/serrano/Figures/9-141.png)

Now that we’ve learned three ways (accuracy, Gini index, and entropy) to pick the best split, all we need to do is iterate this process many times to build the decision tree! This is detailed in the next section.

#### [](/book/grokking-machine-learning/chapter-9/)Second step to build the model: Iterating

In[](/book/grokking-machine-learning/chapter-9/)[](/book/grokking-machine-learning/chapter-9/)[](/book/grokking-machine-learning/chapter-9/) the previous section, we learned how to split the data in the best possible way using one of the features. That is the bulk of the training process of a decision tree. All that is left to finish building our decision tree is to iterate on this step many times. In this section we learn how to do this.

Using the three methods, accuracy, Gini index, and entropy, we decided that the best split was made using the “age” feature. Once we make this split, our dataset is divided into two datasets. The split into these two datasets, with their accuracy, Gini index, and entropy, is illustrated in figure 9.15.

![Figure 9.15 When we split our dataset by age, we get two datasets. The one on the left has three users who downloaded Atom Count, and the one on the right has one user who downloaded Beehive Count and two who downloaded Check Mate Mate.](https://drek4537l1klr.cloudfront.net/serrano/Figures/9-151.png)

Notice that the dataset on the left is pure—all the labels are the same, its accuracy is 100%, and its Gini index and entropy are both 0. There’s nothing more we can do to split this dataset or to improve the classifications. Thus, this node becomes a leaf node, and when we get to that leaf, we return the prediction “Atom Count.”

The dataset on the right can still be divided, because it has two labels: “Beehive Count” and “Check Mate Mate.” We’ve used the age feature already, so let’s try using the platform feature. It turns out that we’re in luck, because the Android user downloaded Beehive Count, and the two iPhone users downloaded Check Mate Mate. Therefore, we can split this leaf using the platform feature and obtain the decision node shown in figure 9.16.

![Figure 9.16 We can split the right leaf of the tree in figure 9.15 using platform and obtain two pure datasets. Each one of them has an accuracy of 100% and a Gini index and entropy of 0.](https://drek4537l1klr.cloudfront.net/serrano/Figures/9-161.png)

After this split, we are done, because we can’t improve our splits any further. Thus, we obtain the tree in figure 9.17.

![Figure 9.17 The resulting decision tree has two nodes and three leaves. This tree predicts every point in the original dataset correctly.](https://drek4537l1klr.cloudfront.net/serrano/Figures/9-17.png)

This is the end of our process, and we have built a decision tree that classifies our entire dataset. We almost have all the pseudocode for the algorithm, except for some final details which we see in the next section.

#### [](/book/grokking-machine-learning/chapter-9/)Last step: When to stop building the tree and other hyperparameters

In[](/book/grokking-machine-learning/chapter-9/)[](/book/grokking-machine-learning/chapter-9/)[](/book/grokking-machine-learning/chapter-9/) the previous section, we built a decision tree by recursively splitting our dataset. Each split was performed by picking the best feature to split. This feature was found using any of the following metrics: accuracy, Gini index, or entropy. We finish when the portion of the dataset corresponding to each of the leaf nodes is pure—in other words, when all the samples on it have the same label.

Many problems can arise in this process. For instance, if we continue splitting our data for too long, we may end up with an extreme situation in which every leaf contains very few samples, which can lead to serious overfitting. The way to prevent this is to introduce a stopping condition. This condition can be any of the following:

1. Don’t split a node if the change in accuracy, Gini index, or entropy is below some threshold.
1. Don’t split a node if it has less than a certain number of samples.
1. Split a node only if both of the resulting leaves contain at least a certain number of samples.
1. Stop building the tree after you reach a certain depth.

All of these stopping conditions require a hyperparameter. More specifically, these are the hyperparameters corresponding to the previous four conditions:

1. The minimum amount of change in accuracy (or Gini index, or entropy)
1. The minimum number of samples that a node must have to split it
1. The minimum number of samples allowed in a leaf node
1. The maximum depth of the tree

The way we pick these hyperparameters is either by experience or by running an exhaustive search where we look for different combinations of hyperparameters and choose the one that performs best in our validation set. This process is called *grid search**[](/book/grokking-machine-learning/chapter-9/)*, and we’ll study it in more detail in the section "Tuning the hyperparameters to find the best model: Grid search" in chapter 13.

#### [](/book/grokking-machine-learning/chapter-9/)The decision tree algorithm: How to build a decision tree and make predictions with it

Now[](/book/grokking-machine-learning/chapter-9/)[](/book/grokking-machine-learning/chapter-9/) we are finally ready to state the pseudocode for the decision tree algorithm, which allows us to train a decision tree to fit a dataset.

#### Pseudocode for the decision tree algorithm

Inputs:

- A training dataset of samples with their associated labels
- A metric to split the data (accuracy, Gini index, or entropy)
- One (or more) stopping condition

Output:

- A decision tree that fits the dataset

Procedure:

- Add a root node, and associate it with the entire dataset. This node has level 0. Call it a leaf node.
- Repeat until the stopping conditions are met at every leaf node:

- Pick one of the leaf nodes at the highest level.
- Go through all the features, and select the one that splits the samples corresponding to that node in an optimal way, according to the selected metric. Associate that feature to the node.
- This feature splits the dataset into two branches. Create two new leaf nodes, one for each branch, and associate the corresponding samples to each of the nodes.
- If the stopping conditions allow a split, turn the node into a decision node, and add two new leaf nodes underneath it. If the level of the node is *i*, the two new leaf nodes are at level *i* + 1.
- If the stopping conditions don’t allow a split, the node becomes a leaf node. To this leaf node, associate the most common label among its samples. That label is the prediction at the leaf.

[](/book/grokking-machine-learning/chapter-9/)Return:

- The decision tree obtained.

To make predictions using this tree, we simply traverse down it, using the following rules:

- Traverse the tree downward. At every node, continue in the direction that is indicated by the feature.
- When arriving at a leaf, the prediction is the label associated with the leaf (the most common among the samples associated with that leaf in the training process).

This is how we make predictions using the app-recommendation decision tree we built previously. When a new user comes, we check their age and their platform, and take the following actions:

- If the user is young, then we recommend them Atom Count.
- If the user is an adult, then we check their platform.

- If the platform is Android, then we recommend Beehive Count.
- If the platform is iPhone, then we recommend Check Mate Mate.

##### aside

The literature contains terms like *Gini gain* and *information gain* when training decision trees. The Gini gain is the difference between the weighted Gini impurity index of the leaves and the Gini impurity index (entropy) of the decision node we are splitting. In a similar way, the information gain is the difference between the weighted entropy of the leaves and the entropy of the root. The more common way to train decision trees is by maximizing the Gini gain or the information gain. However, in this chapter, we train decision trees by, instead, minimizing the weighted Gini index or the weighted entropy. The training process is exactly the same, because the Gini impurity index (entropy) of the decision node is constant throughout the process of splitting that particular decision node.

## [](/book/grokking-machine-learning/chapter-9/)Beyond questions like yes/no

In[](/book/grokking-machine-learning/chapter-9/)[](/book/grokking-machine-learning/chapter-9/) the section “The solution: Building an app-recommendation system,” we learned how to build a decision tree for a very specific case in which every feature was categorical and binary (meaning that it has only two classes, such as the platform of the user). However, almost the same algorithm works to build a decision tree with categorical features with more classes (such as dog/cat/bird) and even with numerical features (such as age or average income). The main step to modify is the step in which we split the dataset, and in this section, we show you how.

#### [](/book/grokking-machine-learning/chapter-9/)Splitting the data using non-binary categorical features, such as dog/cat/bird

Recall [](/book/grokking-machine-learning/chapter-9/)[](/book/grokking-machine-learning/chapter-9/)[](/book/grokking-machine-learning/chapter-9/)that when we want to split a dataset based on a binary feature, we simply ask one yes-or-no question of the form, “Is the feature X?” For example, when the feature is the platform, a question to ask is “Is the user an iPhone user?” If we have a feature with more than two classes, we just ask several questions. For example, if the input is an animal that could be a dog, a cat, or a bird, then we ask the following questions:

- Is the animal a dog?
- Is the animal a cat?
- Is the animal a bird?

No matter how many classes a feature has, we can split it into several binary questions (figure 9.18).

![Figure 9.18 When we have a nonbinary feature, for example, one with three or more possible categories, we instead turn it into several binary (yes-or-no) features, one for each category. For example, if the feature is a dog, the answers to the three questions “Is it a dog?,” “Is it a cat?,” and “Is it a bird?” are “yes,” “no,” and “no.”](https://drek4537l1klr.cloudfront.net/serrano/Figures/9-18.png)

Each of the questions splits the data in a different way. To figure out which of the three questions gives us the best split, we use the same methods as in the section “First step to build the model”: accuracy, Gini index, or entropy. This process of turning a nonbinary categorical feature into several binary features is called *one-hot encoding**[](/book/grokking-machine-learning/chapter-9/)*. In the section “Turning categorical data into numerical data” in chapter 13, we see it used in a real dataset.

#### [](/book/grokking-machine-learning/chapter-9/)Splitting the data using continuous features, such as age

Recall[](/book/grokking-machine-learning/chapter-9/)[](/book/grokking-machine-learning/chapter-9/)[](/book/grokking-machine-learning/chapter-9/) that before we simplified our dataset, the “age” feature contained numbers. Let’s get back to our original table and build a decision tree there (table 9.3).

##### Table 9.3 Our original app recommendation dataset with the platform and (numerical) age of the users. This is the same as table 9.1.[(view table figure)](https://drek4537l1klr.cloudfront.net/serrano/HighResolutionFigures/table_9-3.png)

| Platform | Age | App |
| --- | --- | --- |
| iPhone | 15 | Atom Count |
| iPhone | 25 | Check Mate Mate |
| Android | 32 | Beehive Finder |
| iPhone | 35 | Check Mate Mate |
| Android | 12 | Atom Count |
| Android | 14 | Atom Count |

The idea is to turn the Age column into several questions of the form, “Is the user younger than X?” or “Is the user older than X?” It seems like we have infinitely many questions to ask, because there are infinitely many numbers, but notice that many of these questions split the data in the same way. For example, asking, “Is the user younger than 20?” and “Is the user younger than 21,” gives us the same split. In fact, only seven splits are possible, as illustrated in figure 9.19.

![Figure 9.19 A graphic of the seven possible ways to split the users by age. Note that it doesn’t matter where we put the cutoffs, as long as they lie between consecutive ages (except for the first and last cutoff).](https://drek4537l1klr.cloudfront.net/serrano/Figures/9-19.png)

As a convention, we’ll pick the midpoints between consecutive ages to be the age for splitting. For the endpoints, we can pick any random value that is out of the interval. Thus, we have seven possible questions that split the data into two sets, as shown in table 9.4. In this table, we have also calculated the accuracy, the Gini impurity index, and the entropy of each of the splits.

Notice that the fourth question (“Is the user younger than 20?”) gives the highest accuracy, the lowest weighted Gini index, and the lowest weighted entropy and, therefore, is the best split that can be made using the “age” feature.

##### Table 9.4 The seven possible questions we can pick, each with the corresponding splitting. In the first set, we put the users who are younger than the cutoff, and in the second set, those who are older than the cutoff.[(view table figure)](https://drek4537l1klr.cloudfront.net/serrano/HighResolutionFigures/table_9-4.png)

| Question | First set (yes) | Second set (no) | Labels | Weighted accuracy | Weighted Gini impurity index | Weighted entropy |
| --- | --- | --- | --- | --- | --- | --- |
| Is the user younger than 7? | empty | 12, 14, 15, 25, 32, 35 | {}, {A,A,A,C,B,C} | 3/6 | 0.611 | 1.459 |
| Is the user younger than 13? | 12 | 14, 15, 25, 32, 35 | {A}, {A,A,C,B,C} | 3/6 | 0.533 | 1.268 |
| Is the user younger than 14.5? | 12, 14 | 15, 25, 32, 35 | {A,A} {A,C,B,C} | 4/6 | 0.417 | 1.0 |
| Is the user younger than 20? | 12, 14, 15 | 25, 32, 35 | {A,A,A}, {C,B,C} | 5/6 | 0.222 | 0.459 |
| Is the user younger than 28.5? | 12, 14, 15, 25 | 32, 35 | {A,A,A,C}, {B,C} | 4/6 | 0.416 | 0.874 |
| Is the user younger than 33.5? | 12, 14, 15, 25, 32 | 35 | {A,A,A,C,B}, {C} | 4/6 | 0.467 | 1.145 |
| Is the user younger than 100? | 12, 14, 15, 25, 32, 35 | empty | {A,A,A,C,B,C}, {} | 3/6 | 0.611 | 1/459 |

Carry out the calculations in the table, and verify that you get the same answers. The entire calculation of these Gini indices is in the following notebook: [https://github.com/luisguiserrano/manning/blob/master/Chapter_9_Decision_Trees/Gini_entropy_calculations.ipynb](https://github.com/luisguiserrano/manning/blob/master/Chapter_9_Decision_Trees/Gini_entropy_calculations.ipynb).

For clarity, let’s carry out the calculations of accuracy, weighted Gini impurity index, and weighted entropy for the third question. Notice that this question splits the data into the following two sets:

-  **Set 1** (younger than 14.5)

- Ages: 12, 14
- Labels: {A, A}

-  **Set 2** (14.5 and older):

- Ages: 15, 25, 32, 25
- Labels: {A, C, B, C}

#### Accuracy calculation

The [](/book/grokking-machine-learning/chapter-9/)[](/book/grokking-machine-learning/chapter-9/)most common label in set 1 is “A” and in set 2 is “C,” so these are the predictions we’ll make for each of the corresponding leaves. In set 1, every element is predicted correctly, and in set 2, only two elements are predicted correctly. Therefore, this decision stump is correct in four out of the six data points, for an accuracy of 4/6 = 0.667.

For the next two calculations, notice the following:

- Set 1 is pure (all its labels are the same), so its Gini impurity index and entropy are both 0.
- In set 2, the proportions of elements with labels “A,” “B,” and “C” are 1/4, 1/4, and 2/4 =1/2, respectively.

#### Weighted Gini impurity index calculation

The [](/book/grokking-machine-learning/chapter-9/)Gini impurity index of the set {A, A} is 0.

The Gini impurity index of the set {A, C, B, C} is

The weighted average of the two Gini impurity indices is

#### Accuracy calculation

The [](/book/grokking-machine-learning/chapter-9/)entropy of the set {A, A} is 0.

The entropy of the set {A, C, B, C} is

The weighted average of the two entropies is

A numerical feature becomes a series of yes-or-no questions, which can be measured and compared with the other yes-or-no questions coming from other features, to pick the best one for that decision node.

##### aside

This app-recommendation model is very small, so we could do it all by hand. However, to see it in code, please check this notebook: [https://github.com/luisguiserrano/manning/blob/master/Chapter_9_Decision_Trees/App_recommendations.ipynb](https://github.com/luisguiserrano/manning/blob/master/Chapter_9_Decision_Trees/App_recommendations.ipynb). The notebook uses the Scikit-Learn package, which we introduce in more detail in the section “Using Scikit-Learn to build a decision tree.”

## [](/book/grokking-machine-learning/chapter-9/)The graphical boundary of decision trees

In[](/book/grokking-machine-learning/chapter-9/)[](/book/grokking-machine-learning/chapter-9/) this section, I show you two things: how to build a decision tree geometrically (in two dimensions) and how to code a decision tree in the popular machine learning package Scikit-Learn.

Recall that in classification models, such as the perceptron (chapter 5) or the logistic classifier (chapter 6), we plotted the boundary of the model that separated the points with labels 0 and 1, and it turned out to be a straight line. The boundary of a decision tree is also nice, and when the data is two-dimensional, it is formed by a combination of vertical and horizontal lines. In this section, we illustrate this with an example. Consider the dataset in figure 9.20, where the points with label 1 are triangles, and the points with label 0 are squares. The horizontal and vertical axes are called *x*0 and *x*1, respectively.

![Figure 9.20 A dataset with two features (x0 and x1) and two labels (triangle and square) in which we will train a decision tree](https://drek4537l1klr.cloudfront.net/serrano/Figures/9-201.png)

If you had to split this dataset using only one horizontal or vertical line, what line would you pick? There could be different lines, according to the criteria you would use to measure the effectiveness of a solution. Let’s go ahead and select a vertical line at *x*0 = 5. This leaves mostly triangles to the right of it and mostly squares to the left of it, with the exception of two misclassified points, one square and one triangle (figure 9.21). Try checking all the other possible vertical and horizontal lines, compare them using your favorite metric (accuracy, Gini index, and entropy), and verify that this is the line that best divides the points.

Now let’s look at each half separately. This time, it’s easy to see that two horizontal lines at *x*1 = 8 and *x*1 = 2.5 will do the job on the left and the right side, respectively. These lines completely divide the dataset into squares and triangles. Figure 9.22 illustrates the result.

![Figure 9.21 If we have to use only one vertical or horizontal line to classify this dataset in the best possible way, which one would we use? Based on accuracy, the best classifier is the vertical line at x0 = 5, where we classify everything to the right of it as a triangle, and everything to the left of it as a square. This simple classifier classifies 8 out of the 10 points correctly, for an accuracy of 0.8.](https://drek4537l1klr.cloudfront.net/serrano/Figures/9-212.png)

![Figure 9.22 The classifier in figure 9.21 leaves us with two datasets, one at each side of the vertical line. If we had to classify each one of them, again using one vertical or horizontal line, which one would we choose? The best choices are horizontal lines at x1 = 8 and x1 = 2.5, as the figure shows.](https://drek4537l1klr.cloudfront.net/serrano/Figures/9-221.png)

What we did here was build a decision tree. At every stage, we picked from each of the two features (*x*0 and *x*1) and selected the threshold that best splits our data. In fact, in the next subsection, we use Scikit-Learn to build the same decision tree on this dataset.

#### [](/book/grokking-machine-learning/chapter-9/)Using Scikit-Learn to build a decision tree

In[](/book/grokking-machine-learning/chapter-9/) this section, we learn how to use a popular machine learning package called Scikit-Learn (abbreviated sklearn) to build a decision tree. The code for this section follows:

-  **Notebook**: Graphical_example.ipynb

- [https://github.com/luisguiserrano/manning/blob/master/Chapter_9_Decision_Trees/Graphical_example.ipynb](https://github.com/luisguiserrano/manning/blob/master/Chapter_9_Decision_Trees/Graphical_example.ipynb)

We begin by loading the dataset as a Pandas DataFrame called `dataset` (introduced in chapter 8), with the following lines of code:

```
import pandas as pd
dataset = pd.DataFrame({
   'x_0':[7,3,2,1,2,4,1,8,6,7,8,9],
   'x_1':[1,2,3,5,6,7,9,10,5,8,4,6],
   'y': [0,0,0,0,0,0,1,1,1,1,1,1]})
```

Now we separate the features from the labels as shown here:

```
features = dataset[['x_0', 'x_1']]
labels = dataset['y']
```

To build the decision tree, we create a `DecisionTreeClassifier` object[](/book/grokking-machine-learning/chapter-9/) and use the `fit` function[](/book/grokking-machine-learning/chapter-9/), as follows:

```
decision_tree = DecisionTreeClassifier()
decision_tree.fit(features, labels)
```

We obtained the plot of the tree, shown in figure 9.23, using the `display_tree` function[](/book/grokking-machine-learning/chapter-9/) in the utils.py file.

![Figure 9.23 The resulting decision tree of depth 2 that corresponds to the boundary in figure 9.22. It has three nodes and four leaves.](https://drek4537l1klr.cloudfront.net/serrano/Figures/9-23.png)

Notice that the tree in figure 9.23 corresponds precisely to the boundary in figure 9.22. The root node corresponds to the first vertical line at *x*0 = 5, with the points at each side of the line corresponding to the two branches. The two horizontal lines at *x*1 = 8.0 and *x*1 = 2.5 on the left and right halves of the plot correspond to the two branches. Furthermore, at each node we have the following information:

- **Gini**: the Gini impurity index of the labels at that node
- **Samples**: the number of data points (samples) corresponding to that node
- **Value**: the number of data points of each of the two labels at that node

As you can see, this tree has been trained using the Gini index, which is the default in Scikit-Learn. To train it using entropy, we can specify it when building the `DecisionTree` object[](/book/grokking-machine-learning/chapter-9/), as follows:

```
decision_tree = DecisionTreeClassifier(criterion='entropy')
```

We can specify more hyperparameters when training the tree, which we see in the next section with a much bigger example.

## [](/book/grokking-machine-learning/chapter-9/)Real-life application: Modeling student admissions with Scikit-Learn

In[](/book/grokking-machine-learning/chapter-9/)[](/book/grokking-machine-learning/chapter-9/) this section, we use decision trees to build a model that predicts admission to graduate schools. The dataset can be found in Kaggle (see appendix C for the link). As in the section “The graphical boundary of decision trees,” we’ll use Scikit-Learn to train the decision tree and Pandas to handle the dataset. The code for this section follows:

-  **Notebook**: University_admissions.ipynb

- [https://github.com/luisguiserrano/manning/blob/master/Chapter_9_Decision_Trees/University_Admissions.ipynb](https://github.com/luisguiserrano/manning/blob/master/Chapter_9_Decision_Trees/University_Admissions.ipynb)

- **Dataset**: Admission_Predict.csv

The dataset has the following features:

- **GRE score**: a number out of 340
- **TOEFL score**: a number out of 120
- **University rating**: a number from 1 to 5
- **Statement of purpose strength (SOP)**: a number from 1 to 5
- **Undergraduate grade point average (CGPA)**: a number from 1 to 10
- **Letter of recommendation strength (LOR)**: a number from 1 to 5
- **Research experience**: Boolean variable (0 or 1)

The labels on the dataset are the chance of admission, which is a number between 0 and 1. To have binary labels, we’ll consider every student with a chance of 0.75 or higher as “admitted,” and any other student as “not admitted.”

The code for loading the dataset into a Pandas DataFrame and performing this preprocessing step is shown next:

```
import pandas as pd
data = pd.read_csv('Admission_Predict.csv', index_col=0)
data['Admitted'] = data['Chance of Admit'] >= 0.75
data = data.drop(['Chance of Admit'], axis=1)
```

The first few rows of the resulting dataset are shown in table 9.5.

##### Table 9.5 A dataset with 400 students and their scores in standardized tests, grades, university ratings, letters of recommendations, statements of purpose, and information about their chances of being admitted to graduate school[(view table figure)](https://drek4537l1klr.cloudfront.net/serrano/HighResolutionFigures/table_9-5.png)

| GRE score | TOEFL score | University rating | SOP | LOR | CGPA | Research | Admitted |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 337 | 118 | 4 | 4.5 | 4.5 | 9.65 | 1 | True |
| 324 | 107 | 4 | 4.0 | 4.5 | 8.87 | 1 | True |
| 316 | 104 | 3 | 3.0 | 3.5 | 8.00 | 1 | False |
| 322 | 110 | 3 | 3.5 | 2.5 | 8.67 | 1 | True |
| 314 | 103 | 2 | 2.0 | 3.0 | 8.21 | 0 | False |

As we saw in the section “The graphical boundary of decision trees,” Scikit-Learn requires that we enter the features and the labels separately. We’ll build a Pandas DataFrame called `features``` containing all the columns except the Admitted column, and a Pandas Series called `labels``` containing only the Admitted column. The code follows:

```
features = data.drop(['Admitted'], axis=1)
labels = data['Admitted']
```

Now we create a `DecisionTreeClassifier` object (which we call `dt`) and use the `fit` method[](/book/grokking-machine-learning/chapter-9/). We’ll train it using the Gini index, as shown next, so there is no need to specify the `criterion` hyperparameter[](/book/grokking-machine-learning/chapter-9/), but go ahead and train it with entropy and compare the results with those that we get here:

```
from sklearn.tree import DecisionTreeClassifier
dt = DecisionTreeClassifier()
dt.fit(features, labels)
```

To make predictions, we can use the `predict` function[](/book/grokking-machine-learning/chapter-9/). For example, here is how we make predictions for the first five students:

```
dt.predict(features[0:5])
Output: array([ True, True, False, True, False])
```

However, the decision tree we just trained massively overfits. One way to see this is by using the `score` function[](/book/grokking-machine-learning/chapter-9/) and realizing that it scores 100% in the training set. In this chapter, we won’t test the model, but will try building a testing set and verifying that this model overfits. Another way to see the overfitting is to plot the tree and notice that its depth is 10 (see the notebook). In the next section, we learn about some hyperparameters that help us prevent overfitting.

#### [](/book/grokking-machine-learning/chapter-9/)Setting hyperparameters in Scikit-Learn

To[](/book/grokking-machine-learning/chapter-9/) prevent overfitting, we can use some of the hyperparameters that we learned in the section “Last step: When to stop building the tree and other hyperparameters,” such as the following:

- `max_depth`: the maximum allowed depth.
- `max_features```: the maximum number of features considered at each split (useful for when there are too many features, and the training process takes too long).
- `min_impurity_decrease```: the decrease in impurity must be higher than this threshold to split a node.

- `min_impurity_split```: when the impurity at a node is lower than this threshold, the node becomes a leaf.
- `min_samples_leaf```: the minimum number of samples required for a leaf node. If a split leaves a leaf with less than this number of samples, the split is not performed.
- `min_samples_split```: the minimum number of samples required to split a node.

Play around with these parameters to find a good model. We’ll use the following:

- `max_depth = 3`
- `min_samples_leaf = 10`
- `min_samples_split = 10`

```
dt_smaller = DecisionTreeClassifier(max_depth=3, min_samples_leaf=10, min_samples_split=10)
dt_smaller.fit(features, labels)
```

The resulting tree is illustrated in figure 9.24. Note that in this tree, all the edges to the right correspond to “False” and to the left to “True.”

![Figure 9.24 A decision tree of depth 3 trained in the student admissions dataset](https://drek4537l1klr.cloudfront.net/serrano/Figures/9-24.png)

[](/book/grokking-machine-learning/chapter-9/)The prediction given at each of the leaves is the label corresponding to the majority of the nodes in that leaf. In the notebook, each node has a color assigned to it, ranging from orange to blue. The orange nodes are those with more points with label 0, and the blue nodes are those with label 1. Notice that the white leaf, in which there are the same number of points with labels 0 and 1. For this leaf, any prediction has the same performance. In this case, Scikit-Learn defaults to the first class in the list, which in this case is false.

To make a prediction, we use the `predict` function. For example, let’s predict the admission for a student with the following numbers:

- GRE score: 320
- TOEFL score: 110
- University rating: 3
- SOP: 4.0
- LOR: 3.5
- CGPA: 8.9
- Research: 0 (no research)

```
dt_smaller.predict([[320, 110, 3, 4.0, 3.5, 8.9, 0]])
Output: array([ True])
```

The tree predicts that the student will be admitted.

From this tree, we can infer the following things about our dataset:

- The most important feature is the sixth column (*X*5), corresponding to the CGPA, or the grades. The cutoff grade is 8.735 out of 10. In fact, most of the predictions to the right of the root node are “admit” and to the left are “not admit,” which implies that CGPA is a very strong feature.
- After this feature, the two most important ones are GRE score (*X*0) and TOEFL score (*X*1), both standardized tests. In fact, among the students who got good grades, most of them are likely to be admitted, unless they did poorly on the GRE, as accounted for by the sixth leaf from the left in the tree in figure 9.24.
- Aside from grades and standardized tests, the only other feature appearing in the tree is SOP, or the strength of the statement of purpose. This is located down in the tree, and it didn’t change the predictions much.

Recall, however, that the construction of the tree is greedy in nature, namely, at each point it selects the top feature. This doesn’t guarantee that the choice of features is the best, however. For example, there could be a combination of features that is very strong, yet none of them is strong individually, and the tree may not be able to pick this up. Thus, even though we got some information about the dataset, we should not yet throw away the features that are not present in the tree. A good feature selection algorithm, such as L1 regularization, would come in handy when selecting features in this dataset.

## [](/book/grokking-machine-learning/chapter-9/)Decision trees for regression

In[](/book/grokking-machine-learning/chapter-9/)[](/book/grokking-machine-learning/chapter-9/) most of this chapter, we’ve used decision trees for classification, but as was mentioned earlier, decision trees are good regression models as well. In this section, we see how to build a decision tree regression model. The code for this section follows:

-  **Notebook**: Regression_decision_tree.ipynb

- [https://github.com/luisguiserrano/manning/blob/master/Chapter_9_Decision_Trees/Regression_decision_tree.ipynb](https://github.com/luisguiserrano/manning/blob/master/Chapter_9_Decision_Trees/Regression_decision_tree.ipynb)

Consider the following problem: we have an app, and we want to predict the level of engagement of the users in terms of how many days per week they used it. The only feature we have is the user’s age. The dataset is shown in table 9.6, and its plot is in figure 9.25.

##### Table 9.6 A small dataset with eight users, their age, and their engagement with our app. The engagement is measured in the number of days when they opened the app in one week.[(view table figure)](https://drek4537l1klr.cloudfront.net/serrano/HighResolutionFigures/table_9-6.png)

| Age | Engagement |
| --- | --- |
| 10 | 7 |
| 20 | 5 |
| 30 | 7 |
| 40 | 1 |
| 50 | 2 |
| 60 | 1 |
| 70 | 5 |
| 80 | 4 |

From this dataset, it seems that we have three clusters of users. The young users (ages 10, 20, 30) use the app a lot, the middle-aged users (ages 40, 50, 60) don’t use it very much, and the older users (ages 70, 80) use it sometimes. Thus, a prediction like this one would make sense:

- If the user is 34 years old or younger, the engagement is 6 days per week.
- If the user is between 35 and 64, the engagement is 1 day per week.
- If the user is 65 or older, the engagement is 3.5 days per week.

![Figure 9.25 The plot of the dataset in table 9.6, where the horizontal axis corresponds to the age of the user and the vertical axis to the number of days per week that they engaged with the app](https://drek4537l1klr.cloudfront.net/serrano/Figures/9-25.png)

The predictions of a regression decision tree look similar to this, because the decision tree splits our users into groups and predicts a fixed value for each of the groups. The way to split the users is by using the features, exactly like we did for classification problems.

Lucky for us, the algorithm used for training a regression decision tree is very similar to the one we used for training a classification decision tree. The only difference is that for classification trees, we used accuracy, Gini index, or entropy, and for regression trees, we use the mean square error[](/book/grokking-machine-learning/chapter-9/)[](/book/grokking-machine-learning/chapter-9/) (MSE). The mean square error may sound familiar—we used it to train linear regression models in the section “How do we measure our results? The error function” in chapter 3.

Before we get into the algorithm, let’s think about it conceptually. Imagine that you have to fit a line as close as possible to the dataset in figure 9.25. But there is a catch—the line must be horizontal. Where should we fit this horizontal line? It makes sense to fit it in the “middle” of the dataset—in other words, at a height equal to the average of the labels, which is 4. That is a very simple classification model, which assigns to every point the same prediction of 4.

Now, let’s go a bit further. If we had to use two horizontal segments, how should we fit them as close as possible to the data? We might have several guesses, with one being to put a high bar for the points to the left of 35 and a low bar to the right of 35. That represents a decision stump that asks the question, “Are you younger than 35?” and assigns predictions based on how the user answered that question.

What if we could split each of these two horizontal segments into two more—where should we locate them? We can continue following this process until we have broken down the users

into several groups in which their labels are very similar. We then predict the average label for all the users in that group.

The process we just followed is the process of training a regression decision tree. Now let’s get more formal. Recall that when a feature is numerical, we consider all the possible ways to split it. Thus, the possible ways to split the age feature are using, for example, the following cutoffs: 15, 25, 35, 45, 55, 65, and 75. Each of these cutoffs gives us two smaller datasets, which we call the left dataset and the right dataset. Now we carry out the following steps:

1. For each of the smaller datasets, we predict the average value of the labels.
1. We calculate the mean square error of the prediction.
1. We select the cutoff that gives us the smallest square error.

For example, if our cutoff is 65, then the two datasets are the following:

- **Left dataset**: users younger than 65. The labels are {7, 5, 7, 1, 2, 1}.
- **Right dataset**: users 65 or older. The labels are {5,4}.

For each dataset, we predict the average of the labels, which is 3.833 for the left one and 4.5 for the right one. Thus, the prediction for the first six users is 3.833, and for the last two is 4.5. Now, we calculate the MSE as follows:

In table 9.7, we can see the values obtained for each of the possible cutoffs. The full calculations are at the end of the notebook for this section.

##### Table 9.7 The nine possible ways to split the dataset by age using a cutoff. Each cutoff splits the dataset into two smaller datasets, and for each of these two, the prediction is given by the average of the labels. The mean square error (MSE) is calculated as the average of the squares of the differences between the labels and the prediction. Notice that the splitting with the smallest MSE is obtained with a cutoff of 35. This gives us the root node in our decision tree.[(view table figure)](https://drek4537l1klr.cloudfront.net/serrano/HighResolutionFigures/table_9-7.png)

| Cutoff | Labels left set | Labels right set | Prediction left set | Prediction right set | MSE |
| --- | --- | --- | --- | --- | --- |
| 0 | {} | {7,5,7,1,2,1,5,4} | None | 4.0 | 5.25 |
| 15 | {7} | {5,7,1,2,1,5,4} | 7.0 | 3.571 | 3.964 |
| 25 | {7,5} | {7,1,2,1,5,4} | 6.0 | 3.333 | 3.917 |
| 35 | {7,5,7} | {1,2,1,5,4} | 6.333 | 2.6 | 1.983 |
| 45 | {7,5,7,1} | {2,1,5,4} | 5.0 | 3.0 | 4.25 |
| 55 | {7,5,7,1,2} | {1,5,4} | 4.4 | 3.333 | 4.983 |
| 65 | {7,5,7,1,2,1} | {5,4} | 3.833 | 4.5 | 5.167 |
| 75 | {7,5,7,1,2,1,5} | {4} | 4.0 | 4.0 | 5.25 |
| 100 | {7,5,7,1,2,1,5,4} | {} | 4.0 | none | 5.25 |

The best cutoff is at 35 years old, because it gave us the prediction with the least mean square error. Thus, we’ve built the first decision node in our regression decision tree. The next steps are to continue splitting the left and right datasets recursively in the same fashion. Instead of doing it by hand, we’ll use Scikit-Learn as before.

First, we define our features and labels. We can use arrays for this, as shown next:

```
features = [[10],[20],[30],[40],[50],[60],[70],[80]]
labels = [7,5,7,1,2,1,5,4]
```

Now, we build a regression decision tree of maximum depth 2 using the `DecisionTreeRegressor` object[](/book/grokking-machine-learning/chapter-9/) as follows:

```
from sklearn.tree import DecisionTreeRegressor
dt_regressor = DecisionTreeRegressor(max_depth=2)
dt_regressor.fit(features, labels)
```

The resulting decision tree is shown in figure 9.26. The first cutoff is at 35, as we had already figured out. The next two cutoffs are at 15 and 65. At the right of figure 9.26, we can also see the predictions for each of these four resulting subsets of the data.

![Figure 9.26 Left: The resulting decision tree obtained in Scikit-Learn. This tree has three decision nodes and four leaves. Right: The plot of the predictions made by this decision tree. Note that the cutoffs are at ages 35, 15, and 65, corresponding to the decision nodes in the tree. The predictions are 7, 6, 1.33, and 4.5, corresponding to the leaves in the tree.](https://drek4537l1klr.cloudfront.net/serrano/Figures/9-26.png)

## [](/book/grokking-machine-learning/chapter-9/)Applications

Decision[](/book/grokking-machine-learning/chapter-9/) trees have many useful applications in real life. One special feature of decision trees is that, aside from predicting, they give us a lot of information about our data, because they organize it in a hierarchical structure. Many times, this information is of as much or even more value as the capacity of making predictions. In this section, we see some examples of decision trees used in real life in the following fields:

- Health care
- Recommendation systems

#### [](/book/grokking-machine-learning/chapter-9/)Decision trees are widely used in health care

Decision [](/book/grokking-machine-learning/chapter-9/)[](/book/grokking-machine-learning/chapter-9/)trees are widely used in medicine, not only to make predictions but also to identify features that are determinant in the prediction. You can imagine that in medicine, a black box saying “the patient is sick” or “the patient is healthy” is not good enough. However, a decision tree comes with a great deal of information about why the prediction was made. The patient could be sick based on their symptoms, family medical history, habits, or many other factors.

#### [](/book/grokking-machine-learning/chapter-9/)Decision trees are useful in recommendation systems

In[](/book/grokking-machine-learning/chapter-9/) recommendation systems, decision trees are also useful. One of the most famous recommendation systems problems, the Netflix prize, was won with the help of decision trees. In 2006, Netflix held a competition that involved building the best possible recommendation system to predict user ratings of their movies. In 2009, they awarded $1,000,000 USD to the winner, who improved the Netflix algorithm by over 10%. The way they did this was using gradient-boosted decision trees to combine more than 500 different models. Other recommendation engines use decision trees to study the engagement of their users and figure out the demographic features to best determine engagement.

In chapter 12, we will learn more about gradient-boosted decision trees and random forests. For now, the best way to imagine them is as a collection of many decision trees working together to make the best predictions.

## [](/book/grokking-machine-learning/chapter-9/)Summary

- Decision trees are important machine learning models, used for classification and regression.
- The way decision trees work is by asking binary questions about our data and making a prediction based on the answers to those questions.
- The algorithm for building decision trees for classification consists of finding the feature in our data that best determines the label and iterating over this step.
- We have several ways to tell if a feature determines the label best. The three that we learned in this chapter are accuracy, Gini impurity index, and entropy.
- The Gini impurity index measures the purity of a set. In that way, a set in which every element has the same label has a Gini impurity index of 0. A set in which every element has a different label has a Gini impurity label close to 1.
- Entropy is another measure for the purity of a set. A set in which every element has the same label has an entropy of 0. A set in which half of the elements have one label and the other half has another label has an entropy of 1. When building a decision tree, the difference in entropy before and after a split is called information gain.
- The algorithm for building a decision tree for regression is similar to the one used for classification. The only difference is that we use the mean square error to select the best feature to split the data.
- In two dimensions, regression tree plots look like the union of several horizontal lines, where each horizontal line is the prediction for the elements in a particular leaf.
- Applications of decision trees range very widely, from recommendation algorithms to applications in medicine and biology.

## [](/book/grokking-machine-learning/chapter-9/)Exercises

#### Exercise 9.1

In the following spam-detection decision tree model, determine whether an email from your mom with the subject line, “Please go to the store, there’s a sale,” will be classified as spam.

![](https://drek4537l1klr.cloudfront.net/serrano/Figures/9-unnumb-2.png)

#### Exercise 9.2

Our goal is to build a decision tree model to determine whether credit card transactions are fraudulent. We use the dataset of credit card transactions below, with the following features:

- **Value**: value of the transaction.
- **Approved vendor**: the credit card company has a list of approved vendors. This variable indicates whether the vendor is in this list.

|   | Value | Approved vendor | Fraudulent |
| --- | --- | --- | --- |
| Transaction 1 | $100 | Not approved | Yes |
| Transaction 2 | $100 | Approved | No |
| Transaction 3 | $10,000 | Approved | No |
| Transaction 4 | $10,000 | Not approved | Yes |
| Transaction 5 | $5,000 | Approved | Yes |
| Transaction 6 | $100 | Approved | No |

Build the first node of the decision tree with the following specifications:

1. Using the Gini impurity index
1. Using entropy

#### Exercise 9.3

A dataset of patients who have tested positive or negative for COVID-19 follows. Their symptoms are cough (C), fever (F), difficulty breathing (B), and tiredness (T).

|   | Cough (C) | Fever (F) | Difficulty breathing (B) | Tiredness (T) | Diagnosis |
| --- | --- | --- | --- | --- | --- |
| Patient 1 |  | X | X | X | Sick |
| Patient 2 | X | X |  | X | Sick |
| Patient 3 | X |  | X | X | Sick |
| Patient 4 | X | X | X |  | Sick |
| Patient 5 | X |  |  | X | Healthy |
| Patient 6 |  | X | X |  | Healthy |
| Patient 7 |  | X |  |  | Healthy |
| Patient 8 |  |  |  | X | Healthy |

Using accuracy, build a decision tree of height 1 (a decision stump) that classifies this data. What is the accuracy of this classifier on the dataset?
