# [](/book/grokking-machine-learning/chapter-8/)8 Using probability to its maximum: The naive Bayes model

### In this chapter

- what is Bayes theorem
- dependent and independent events
- the prior and posterior probabilities
- calculating conditional probabilities based on events
- using the naive Bayes model to predict whether an email is spam or ham, based on the words in the email
- coding the naive Bayes algorithm in Python

![](https://drek4537l1klr.cloudfront.net/serrano/Figures/CH08_F01_Serrano_Text.png)

Naive Bayes is an important machine learning model used for classification. The naive Bayes model is a purely probabilistic model, which means the prediction is a number between 0 and 1, indicating the probability that a label is positive. The main component of the naive Bayes model is Bayes’ theorem.

Bayes’ theorem plays a fundamental role in probability and statistics, because it helps calculate probabilities. It is based on the premise that the more information we gather about an event, the better estimate of the probability we can make. For example, let’s say we want to find the probability that it will snow today. If we have no information of where we are and what time of the year it is, we can only come up with a vague estimate. However, if we are given information, we can make a better estimate of the probability. Imagine that I tell you that I am thinking of a type of animal, and I would like you to guess it. What is the probability that the animal I’m thinking of is a dog? Given that you don’t know any information, the probability is quite small. However, if I tell you that the animal I’m thinking of is a house pet, the probability increases quite a bit. However, if I now tell you that the animal I’m thinking of has wings, the probability is now zero. Each time I tell you a new piece of information, your estimate for the probability that it’s a dog becomes more and more accurate. Bayes’ theorem is a way to formalize this type of logic and put it into formulas.

More specifically, Bayes’ theorem answers the question, “What is the probability of *Y* given that *x* occurred?” which is called a *conditional probability**[](/book/grokking-machine-learning/chapter-8/)*. As you can imagine, answering this type of question is useful in machine learning, because if we can answer the question, “What is the probability that *the label is positive* given *the features*?” we have a classification model. For example, we can build a sentiment analysis model (just like we did in chapter 6) by answering the question, “What is the probability that *this sentence is happy* given *the words that it contains*?” However, when we have too many features (in this case, words), the computation of the probability using Bayes’ theorem gets very complicated. This is where the naive Bayes algorithm comes to our rescue. The naive Bayes algorithm uses a slick simplification of this calculation to help us build our desired classification model, called the *naive Bayes model**[](/book/grokking-machine-learning/chapter-8/)*. It’s called *naive* Bayes because to simplify the calculations, we make a slightly naive assumption that is not necessarily true. However, this assumption helps us come up with a good estimate of the probability.

In this chapter, we see Bayes theorem used with some real-life examples. We start by studying an interesting and slightly surprising medical example. Then we dive deep into the naive Bayes model by applying it to a common problem in machine learning: spam classification. We finalize by coding the algorithm in Python and using it to make predictions in a real spam email dataset.

All the code for this chapter is available at this GitHub repository: [https://github.com/luisguiserrano/manning/tree/master/Chapter_8_Naive_Bayes](https://github.com/luisguiserrano/manning/tree/master/Chapter_8_Naive_Bayes).

## [](/book/grokking-machine-learning/chapter-8/)Sick or healthy? A story with Bayes’ theorem as the hero

Consider[](/book/grokking-machine-learning/chapter-8/) the following scenario. Your (slightly hypochondriac) friend calls you, and the following conversation unfolds:

**You**: Hello!

**Friend**: Hi. I have some terrible news!

**You**: Oh no, what is it?

**Friend**: I heard about this terrible and rare disease, and I went to the doctor to be tested for it. The doctor said she would administer a very accurate test. Then today, she called me and told me that I tested positive! I must have the disease!

Oh no! What should you say to your friend? First of all, let’s calm him down, and try to figure out if it is likely that he has the disease.

**You**: First, let’s calm down. Mistakes happen in medicine. Let’s try to see how likely it is that you actually have the disease. How accurate did the doctor say the test was?

**Friend**: She said it was 99% accurate. That means I’m 99% likely to have the disease!

**You**: Wait, let’s look at *all* the numbers. How likely is it to have the disease, regardless of the test? How many people have the disease?

**Friend**: I was reading online, and it says that on average, one out of every 10,000 people have the disease.

**You**: OK, let me get a piece of paper (*puts friend on hold*).

Let’s stop for a quiz.

##### quiz

In what range do you think is the probability that your friend has the disease, given that he has tested positive?

1. 0–20%
1. 20–40%
1. 40–60%
1. 60–80%
1. 80–100%

Let’s calculate this probability. To summarize, we have the following two pieces of information:

- The test is correct 99% of the time. To be more exact (we checked with the doctor to confirm this), on average, out of every 100 healthy people, the test correctly diagnoses 99 of them, and out of every 100 sick people, the test correctly diagnoses 99 of them. Therefore, both on healthy and sick people, the test has an accuracy of 99%.
- On average, 1 out of every 10,000 people has the disease.

Let’s do some rough calculations to see what the probability would be. These are summarized in the confusion matrix shown in figure 8.1. For reference, we can pick a random group of one million people. On average, one out of every 10,000 people are sick, so we expect 100 of these people to have the disease and 999,900 to be healthy.

First, let’s run the test on the 100 sick ones. Because the test is correct 99% of the time, we expect 99 of these 100 people to be correctly diagnosed as sick—that is, 99 sick people who test positive.

Now, let’s run the test on the 999,900 healthy ones. The test makes mistakes 1% of the time, so we expect 1% of these 999,900 healthy people to be misdiagnosed as sick. That is 9,999 healthy people who test positive.

This means that the total number of people who tested positive is 99 + 9,999 = 10,098. Out of these, only 99 are sick. Therefore, the probability that your friend is sick, given that he tested positive, is 99/10.098 = 0.0098, or 0.98%. That is less than 1%! So we can get back to our friend.

**You:** Don’t worry, based on the numbers you gave me, the probability that you have the disease given that you tested positive is less than 1%!

**Friend:** Oh, my God, really? That’s such a relief, thank you!

**You:** Don’t thank me, thank math (*winks eye*).

Let’s summarize our calculation. These are our facts:

- **Fact 1**: Out of every 10,000 people, one has the disease.
- **Fact 2**: Out of every 100 sick people who take the test, 99 test positive, and one tests negative.
- **Fact 3**: Out of every 100 healthy people who take the test, 99 test negative, and one tests positive.

We pick a sample population of one million people, which is broken down in figure 8.1, as follows:

- According to fact 1, we expect 100 people in our sample population to have the disease, and 999,900 to be healthy.
- According to fact 2, out of the 100 sick people, 99 tested positive and one tested negative.
- According to fact 3, out of the 999,900 healthy people, 9,999 tested positive and 989,901 tested negative

![Figure 8.1 Among our 1,000,000 patients, only 100 of them are sick (bottom row). Among the 10,098 diagnosed as sick (left column), only 99 of them are actually sick. The remaining 9,999 are healthy, yet were misdiagnosed as sick. Therefore, if our friend was diagnosed as sick, he has a much higher chance to be among the 9,999 healthy (top left) than to be among the 99 sick (bottom left).](https://drek4537l1klr.cloudfront.net/serrano/Figures/8-11.png)

Because our friend tested positive, he must be in the left column of figure 8.1. This column has 9,999 healthy people who were misdiagnosed as sick and 99 sick people who were correctly diagnosed. The probability that your friend is sick is 99/99+9.999 = 0.0098, which is less than 1%.

This is a bit surprising, if the test is correct 99% of the time, why on earth is it so wrong? Well, the test is not bad if it’s wrong only 1% of the time. But because one person out of every 10,000 is sick with the disease, that means a person is sick 0.01% of the time. What is more likely, to be among the 1% of the population that got misdiagnosed or to be among the 0.01% of the population that is sick? The 1%, although a small group, is much larger than the 0.01%. The test has a problem; it has an error rate much larger than the rate of being sick. We have a similar problem in the section “Two examples of models: Coronavirus and spam email” in chapter 7—we can’t rely on accuracy to measure this model.

A way to look at this is using treelike diagrams. In our diagram, we start with a root at the left, which branches out into two possibilities: that your friend is sick or healthy. Each of these two possibilities branches out into two more possibilities: that your friend gets diagnosed as healthy or diagnosed as sick. The tree is illustrated in figure 8.2, together with the count of patients in each branch.

![Figure 8.2 The tree of possibilities. Each patient can be sick or healthy. For each of the possibilities, the patient can be diagnosed as sick or healthy, which gives us four possibilities. We start with one million patients: 100 of them are sick, and the remaining 999,900 are healthy. Out of the 100 sick, one gets misdiagnosed as healthy, and the remaining 99 get correctly diagnosed as sick. Out of the 999,900 healthy patients, 9,999 get misdiagnosed as sick, and the remaining 989,901 are correctly diagnosed as healthy.](https://drek4537l1klr.cloudfront.net/serrano/Figures/8-21.png)

From figure 8.2, we can again see that the probability that your friend is sick given that he tested positive is 99/99+9.999 = 0.0098, given that he can only be in the first and third groups at the right.

#### [](/book/grokking-machine-learning/chapter-8/)Prelude to Bayes’ theorem: The prior, the event, and the posterior

We[](/book/grokking-machine-learning/chapter-8/)[](/book/grokking-machine-learning/chapter-8/)[](/book/grokking-machine-learning/chapter-8/) now have all the tools to state Bayes’ theorem. The main goal of Bayes’ theorem is calculating a probability. At the beginning, with no information in our hands, we can calculate only an initial probability, which we call the *prior*. Then, an event happens, which gives us information. After this information, we have a much better estimate of the probability we want to calculate. We call this better estimate the *posterior*. The prior, event, and posterior, are illustrated in figure 8.3.

##### prior

The initial probability

##### event

Something that occurs, which gives us information

##### posterior

The final (and more accurate) probability that we calculate using the prior probability and the event

An example follows. Imagine that we want to find out the probability that it will rain today. If we don’t know anything, we can come up with only a rough estimate for the probability, which is the prior. If we look around and find out that we are in the Amazon rain forest (the event), then we can come up with a much more exact estimate. In fact, if we are in the Amazon rain forest, it will probably rain today. This new estimate is the posterior.

![Figure 8.3 The prior, the event, and the posterior. The prior is the “raw” probability, namely, the probability we calculate when we know very little. The event is the information that we obtain, which will help us refine our calculation of the probability. The posterior is the “cooked” probability, or the much more accurate probability that we calculate when we have more information.](https://drek4537l1klr.cloudfront.net/serrano/Figures/8-31.png)

In our ongoing medical example, we need to calculate the probability that a patient is sick. The prior, the event, and the posterior follow:

- **Prior**: Initially, this probability is 1/10,000, because we don’t have any other information, other than the fact that one out of every 10,000 patients is sick. This 1/10,000, or 0.0001, is the prior.
- **Event**: All of a sudden, new information comes to light. In this case, the patient took a test and tested positive.
- **Posterior**: After coming out positive, we recalculate the probability that the patient is sick, and that comes out to be 0.0098. This is the posterior.

Bayes’ theorem is one of the most important building blocks of probability and of machine learning. It is so important that several fields are named after it, such as *Bayesian learning**[](/book/grokking-machine-learning/chapter-8/)*, *Bayesian statistics**[](/book/grokking-machine-learning/chapter-8/)*, and *Bayesian analysis**[](/book/grokking-machine-learning/chapter-8/)*. In this chapter, we learn Bayes’ theorem and an important classification model derived from it: the naive Bayes model. In a nutshell, the naive Bayes model does what most classification models do, which is predict a label out of a set of features. The model returns the answer in the form of a probability, which is calculated using Bayes’ theorem.

## [](/book/grokking-machine-learning/chapter-8/)Use case: Spam-detection model

The[](/book/grokking-machine-learning/chapter-8/)[](/book/grokking-machine-learning/chapter-8/) use case that we study in this chapter is a spam-detection model. This model helps us separate spam from ham emails. As we discussed in chapters 1 and 7, spam is the name given to junk email, and ham is the name given to email that isn’t junk.

The naive Bayes model outputs the probability that an email is spam or ham. In that way, we can send the emails with the highest probability of being spam directly to the spam folder and keep the rest in our inbox. This probability should depend on the features of the email, such as its words, sender, size, and so on. For this chapter, we consider only the words as features. This example is not that different from the sentiment analysis example we studied in chapters 5 and 6. The key for this sentiment analysis classifier is that each word has a certain probability of appearing in a spam email. For example, the word *lottery* is more likely to appear in a spam email than the word *meeting*. This probability is the basis of our calculations.

#### [](/book/grokking-machine-learning/chapter-8/)Finding the prior: The probability that any email is spam

What[](/book/grokking-machine-learning/chapter-8/)[](/book/grokking-machine-learning/chapter-8/) [](/book/grokking-machine-learning/chapter-8/)is the probability that an email is spam? That is a hard question, but let’s try to make a rough estimate, which we call the prior. We look at our current inbox and count how many emails are spam and ham. Imagine that in 100 emails, 20 are spam and 80 are ham. Thus, 20% of the emails are spam. If we want to make a decent estimate, we can say that *to the best of our knowledge*, the probability that a new email is spam is 0.2. This is the prior probability. The calculation is illustrated in figure 8.4, where the spam emails are colored dark gray and the ham emails white.

![Figure 8.4 We have a dataset with 100 emails, 20 of which are spam. An estimate for the probability that an email is spam is 0.2. This is the prior probability.](https://drek4537l1klr.cloudfront.net/serrano/Figures/8-4.png)

#### [](/book/grokking-machine-learning/chapter-8/)Finding the posterior: The probability that an email is spam, knowing that it contains a particular word

Of[](/book/grokking-machine-learning/chapter-8/)[](/book/grokking-machine-learning/chapter-8/)[](/book/grokking-machine-learning/chapter-8/) course, not all emails are created equally. We’d like to come up with a more educated guess for the probability, using the properties of the email. We can use many properties, such as sender, size, or words in the email. For this application, we use only the words in the email. However, I encourage you to go through the example thinking how this could be used with other properties.

Let’s say that we find a particular word, say, the word *lottery*, which tends to appear more often in spam emails than in ham emails. That word represents our event. Among the spam emails, the word *lottery* appears in 15 of them, whereas it appears in only 5 of the ham emails. Therefore, among the 20 emails containing the word *lottery*, 15 of them are spam, and 5 of them are ham. Thus, the probability that an email containing the word *lottery* is spam, is precisely 15/20 = 0.75. That is the posterior probability. The process of calculating this probability is illustrated in figure 8.5.

![Figure 8.5 We have removed (grayed out) the emails that don’t contain the word lottery. All of a sudden, our probabilities change. Among the emails that contain the word lottery, there are 15 spam emails and 5 ham emails, so the probability that an email containing the word lottery is spam, is 15/20 = 0.75.](https://drek4537l1klr.cloudfront.net/serrano/Figures/8-5.png)

There we have it: we’ve calculated the probability that an email is spam given that it contains the word *lottery*. To summarize:

- The **prior** probability is 0.2. This is the probability that an email is spam, knowing nothing about the email.
- The **event** is that the email contains the word *lottery*. This helps us make a better estimate of the probability.
- The **posterior** probability is 0.75. This is the probability that the email is spam, *given that* it contains the word *lottery*.

In this example, we calculated the probability by counting emails and dividing. This is mostly done for pedagogical purposes, but in real life, we can use a shortcut to calculate this probability using a formula. This formula is called Bayes’ theorem, and we see it next.

#### [](/book/grokking-machine-learning/chapter-8/)What the math just happened? Turning ratios into probabilities

One[](/book/grokking-machine-learning/chapter-8/)[](/book/grokking-machine-learning/chapter-8/)[](/book/grokking-machine-learning/chapter-8/)[](/book/grokking-machine-learning/chapter-8/) way to visualize the previous example is with a tree of all four possibilities, just as we did with the medical example in figure 8.2. The possibilities are that the email is spam or ham, and that it contains the word *lottery* or not. We draw it in the following way: we start with the root, which splits into two branches. The top branch corresponds to spam, and the bottom branch corresponds to ham. Each of the branches splits into two more branches, namely, when the email contains the word *lottery* and when it does not. The tree is illustrated in figure 8.6. Notice that in this tree, we’ve also indicated how many emails out of the total 100 belong to each particular group.

![Figure 8.6 The tree of possibilities. The root splits into two branches: spam and ham. Then each of these splits into two branches: when the email contains the word lottery, and when it doesn’t.](https://drek4537l1klr.cloudfront.net/serrano/Figures/8-6.png)

Once we have this tree, and we want to calculate the probability that an email is spam *given that* it contains the word *lottery*, we simply remove all the branches in which the emails don’t contain the word *lottery*. This is illustrated in figure 8.7.

![Figure 8.7 From the previous tree, we have removed the two branches where the emails don’t contain the word lottery. Out of the original 100 emails, we have 20 left that contain lottery. Because of these 20 emails, 15 are spam, we conclude that the probability that an email is spam given that it contains the word  lottery is 0.75.](https://drek4537l1klr.cloudfront.net/serrano/Figures/8-7.png)

[](/book/grokking-machine-learning/chapter-8/)Now, we have 20 emails, and of them, 15 are spam and 5 are ham. Thus, the probability that an email is spam given that it contains the word *lottery* is .

But we’ve already done that, so what is the benefit of the diagram? Aside from making things simpler, the benefit is that normally, the information we have is based on probabilities, and not on the number of emails. Many times, we don’t know how many emails are spam or ham. All we know is the following:

- The probability that an email is spam is .
- The probability that a spam email contains the word *lottery* is  .
- The probability that a ham email contains the word *lottery* is .
- **Question**: What is the probability that an email that contains the word lottery is spam?

First, let’s check if this is enough information. Do we know the probability that an email is ham? Well, we know that the probability that it is spam is . The *only* other possibility is that an email is ham, so it must be the complement, or . This is an important rule—the rule of complementary probabilities.

##### rule of complementary probabilities

For an event *E*, the complement of the event *E*, denoted *E*c, is the event opposite to *E*. The probability of *E*c is 1 minus the probability of *E*, namely,

*P*(*E*c) = 1 − *P*(*E*)

Therefore, we have the following:

-
: the probability of an email being spam
-
: the probability of an email being ham

Now let’s look at the other information. The probability that a spam email contains the word *lottery* is . This can be read as, the probability that an email contains the word *lottery* *given that* it is spam, is 0.75. This is a conditional probability, where the condition is that the email is spam. We denote condition by a vertical bar, so this can be written as *P*(*'lottery'*|*spam*). The complement of this is *P*(*no 'lottery'*|*spam*), namely, the probability that a spam email does *not* contain the word *lottery*. This probability is 1 – *P*(*'lottery'*|*spam*). This way, we can calculate other probabilities as follows:

-
: the probability that a spam email contains the word *lottery*.
-
: the probability that a spam email does not contain the word *lottery*.
-
: the probability that a ham email contains the word *lottery*.
-
: the probability that a ham email does not contain the word *lottery*.

[](/book/grokking-machine-learning/chapter-8/)The next thing we do is find the probabilities of two events happening *at the same time*. More specifically, we want the following four probabilities:

- The probability that an email is spam and contains the word *lottery*
- The probability that an email is spam *and* does not contain the word *lottery*
- The probability that an email is ham *and* contains the word *lottery*
- The probability that an email is ham and does not contain the word *lottery*

These events are called *intersections**[](/book/grokking-machine-learning/chapter-8/)* of events and denoted with the symbol ∩. Thus, we need to find the following probabilities:

- *P*(*'lottery'* ∩ *spam*)
- *P*(*no 'lottery'* ∩ *spam*)
- *P*(*'lottery'* ∩ *ham*)
- *P*(*no 'lottery'* ∩ *ham*)

Let’s look at some numbers. We know that , or 20 out of 100, of emails are spam. Out of those 20,  of them contain the word *lottery*. At the end, we multiply these two numbers,  times , to obtain , which is the same as  , the proportion of emails that are spam and contain the word lottery. What we did was the following: we multiplied the probability that an email is spam times the probability that a spam email contains the word lottery, to obtain the probability that an email is spam and contains the word lottery. The probability that a spam email contains the word *lottery* is precisely the conditional probability, or the probability that an email contains the word *lottery* *given that* it is a spam email. This gives rise to the multiplication rule for probabilities.

##### Product rule of probabilities

For events *E* and *F*, the probability of their intersection is the product of the conditional probability of F given E, times the probability of F, namely, *P*(*E* ∩ *F*) = *P*(*E*|*F*) ∩ *P*(*F*).

Now we can calculate these probabilities as follows:

![](https://drek4537l1klr.cloudfront.net/serrano/Figures/08_07_Ed01.png)

![](https://drek4537l1klr.cloudfront.net/serrano/Figures/08_07_Ed02.png)

![](https://drek4537l1klr.cloudfront.net/serrano/Figures/08_07_Ed03.png)

![](https://drek4537l1klr.cloudfront.net/serrano/Figures/08_07_Ed04.png)

These probabilities are summarized in figure 8.8. Notice that the product of the probabilities on the edges are the probabilities at the right. Furthermore, notice that the sum of all these four probabilities is one, because they encompass all the possible scenarios.

![Figure 8.8 The same tree from figure 8.6, but now with probabilities. From the root, two branches emerge, one for spam emails and one for ham emails. In each one, we record the corresponding probability. Each branch again splits into two leaves: one for emails containing the word lottery, and one for emails not containing it. In each branch we record the corresponding probability. Notice that the product of these probabilities is the probability at the right of each leaf. For example, for the top leaf, 1/5 · 3/4 = 3/20 = 0.15.](https://drek4537l1klr.cloudfront.net/serrano/Figures/8-81.png)

We’re almost done. We want to find *P*(*spam*|*'lottery'*), which is the probability that an email is spam *given that* it contains the word *lottery*. Among the four events we just studied, in only two of them does the word *lottery* appear. Thus, we need to consider only those, namely:

![](https://drek4537l1klr.cloudfront.net/serrano/Figures/08_08_Ea01.png)

![](https://drek4537l1klr.cloudfront.net/serrano/Figures/08_08_Ea02.png)

In other words, we need to consider only the two branches shown in figure 8.9—the first and the third, namely, those in which the email contains the word *lottery*.

![Figure 8.9 From the tree in figure 8.8, we have removed the two branches where the emails don’t contain the word lottery.](https://drek4537l1klr.cloudfront.net/serrano/Figures/8-91.png)

The first one is the probability that an email is spam, and the second one is the probability that the email is ham. These two probabilities don’t add to one. However, because we now live in a world in which the email contains the word lottery, then these two are the only possible scenarios. Thus, their probabilities should add to 1. Furthermore, they should still have the same relative ratio with respect to each other. The way to fix this is to normalize—to find two numbers that are in the same relative ratio with respect to each other as  and  but that add to one. The way to find these is to divide both by the sum. In this case, the numbers become  and . These simplify to 3/4 and 1/4 , which are the desired probabilities. Thus, we conclude the following:

![](https://drek4537l1klr.cloudfront.net/serrano/Figures/08_09_E03.png)

![](https://drek4537l1klr.cloudfront.net/serrano/Figures/08_09_E04.png)

[](/book/grokking-machine-learning/chapter-8/)This is exactly what we figured out when we counted the emails. To wrap up this information, we need a formula. We had two probabilities: the probability that an email is spam *and* contains the word *lottery*, and the probability that an email is spam *and* does not contain the word *lottery*. To get them to add to one, we normalized them. This is the same thing as dividing each one of them by their sum. In math terms, we did the following:

If we remember what these two probabilities were, using the product rule, we get the following:

To verify, we plug in the numbers to get:

This is the formula for Bayes’ theorem! More formally:

##### Bayes theorem

For events E and F,

Because the event *F* can be broken down into the two disjoint events *F*∩*E* and *F*∩*E*c, then

#### [](/book/grokking-machine-learning/chapter-8/)What about two words? The naive Bayes algorithm

In the previous section we calculated the probability that an email is spam given that it contains the keyword *lottery*. However, the dictionary contains many more words, and we’d like to calculate the probability that an email is spam given that it contains several words. As you can imagine, the calculations get more complicated, but in this section, we learn a trick that helps us estimate this probability.

In general, the trick helps us calculate a posterior probability based on two events instead of one (and it easily generalizes to more than two events). It is based on the premise that when events are independent, the probability of both occurring at the same time is the product of their probabilities. Events are not always independent, but assuming they are sometimes helps us make good approximations. For example, imagine the following scenario: there is an island with 1,000 people. Half of the inhabitants (500) are women, and one-tenth of the inhabitants (100) have brown eyes. How many of the inhabitants do you think are women with brown eyes? If all we know is this information, we can’t find out unless we count them in person. However, if we assume that gender and eye color are independent, then we can estimate that half of one tenth of the population consists of women with brown eyes. That is
of the population. Because the total population is 1,000 people, our estimate for the number of women with brown eyes is
people. Maybe we go to the island and find out that that’s not the case, but *to the* *best of our knowledge*, 50 is a good estimate. One may say that our assumption about the independence of gender and eye color was *naive*, and maybe it was, but it was the best estimate we could come up with given the information we had.

The rule we used in the previous example is the product rule for independent probabilities, which states the following:

##### product rule for independent probabilities

[](/book/grokking-machine-learning/chapter-8/) If two events *E* and *F* are independent, namely, the occurrence of one doesn’t influence in any way the occurrence of the other one, then the probability of both happening (the intersection of the events) is the product of the probabilities of each of the events. In other words,

*P*(*E* ∩ *F*) = *P*(*E*) · *P*(*F*).

Back to the email example. After we figured out the probability that an email is spam given that it contains the word *lottery*, we noticed that another word, *sale*, also tends to appear a lot in spam email. We’d like to figure out the probability that an email is spam given that it contains both *lottery* and *sale*. We begin by counting how many spam and ham emails contain the word *sale* and find that it appears in 6 of the 20 spam emails and 4 of the 80 ham emails. Thus, the probabilities are the following (illustrated in figure 8.10):

![Figure 8.10 In a similar calculation as for the word lottery, we look at the emails containing the word sale. Among these (not grayed-out) emails, there are six spam and four ham.](https://drek4537l1klr.cloudfront.net/serrano/Figures/8-101.png)

One can use Bayes’ theorem again to conclude that the probability that an email is spam given that it contains the word *sale* is 0.6, and I encourage you to go through the calculations yourself. However, the more important question is: what is the probability that an email is spam given that it contains the words *lottery* and *sale* at the same time? Before we do this, let’s find the probability that an email contains the words *lottery* and *sale* given that it is spam. This should be easy: we go through all our emails and find how many of the spam emails have the words *lottery* and *sale*.

However, we may run into the problem that there are no emails with the words *lottery* and *sale*. We have only 100 emails, and when we are trying to find two words on them, we may not have enough to be able to properly estimate a probability. What can we do? One possible solution is to collect more data, until we have so many emails that it’s likely that the two words appear in some of them. However, the case may be that we can’t collect any more data, so we have to work with what we have. This is where the naive assumption will help us.

Let’s try to estimate this probability in the same way that we estimated the number of women with brown eyes on the island at the beginning of this section. We know that the probability that the word *lottery* appears in a spam email is 0.75, from the previous section. From earlier in this section, the probability that *sale* appears in a spam email is 0.3. Thus, if we naively assume that the appearances of these two words are independent, the probability that both words appear in a spam email is 0.75 · 0.3 = 0.225. In a similar fashion, because we calculated that the probabilities of a ham email containing the word *lottery* is 0.0625 and containing the word *sale* is 0.05, then the probability of a ham email containing both is 0.0625 · 0.05 = 0.003125. In other words, we’ve done the following estimations:

- *P*(*'lottery'*, *'sale'*|*spam*) = *P*(*'lottery'*|*spam*) *P*(*'sale'*|*spam*) = 0.75 · 0.3 = 0.225
- *P*(*'lottery'* , *'sale'*|*ham*) = *P*(*'lottery'*|*ham*) *P*(*'sale'*|*ham*) = 0.0625 · 0.05 = 0.003125

The naive assumption we’ve made follows:

##### naive assumption

The words appearing in an email are completely independent of each other. In other words, the appearance of a particular word in an email in no way affects the appearance of another one.

Most likely, the naive assumption is not true. The appearance of one word can sometimes heavily influence the appearance of another. For example, if an email contains the word *salt*, then the word *pepper* is more likely to appear in this email, because many times they go together. This is why our assumption is naive. However, it turns out that this assumption works well in practice, and it simplifies our math a lot. It is called the product rule for probabilities and is illustrated in figure 8.11.

Now that we have estimates for the probabilities, we proceed to find the expected number of spam and ham emails that contain the words *lottery* and *sale*.

- Because there are 20 spam emails, and the probability that a spam email contains both words is 0.225, the expected number of spam emails containing both words is 20 · 0.225 = 4.5.
- Similarly, there are 80 ham emails, and the probability that a ham email contains both words is 0.00325, so the expected number of ham emails containing both words is 80 · 0.00325 = 0.25.

![Figure 8.11 Say 20% of the emails contain the word lottery, and 10% of the emails contain the word sale. We make the naive assumption that these two words are independent of each other. Under this assumption, the percentage of emails that contain both words can be estimated as 2%, namely, the product of 20% and 10%.](https://drek4537l1klr.cloudfront.net/serrano/Figures/8-112.png)

The previous calculations imply that if we restrict our dataset to only emails that contain both the words *lottery* and *sale*, we expect 4.5 of them to be spam and 0.25 to be ham. Thus, if we were to pick one at random among these, what is the probability that we pick one that is spam? This may look harder with nonintegers than with integers, but if we look at figure 8.12, this may be more clear. We have 4.5 spam emails and 0.25 ham emails (this is exactly one-fourth of an email). If we throw a dart and it falls in one of the emails, what’s the probability that it landed on a spam email? Well, the total number of emails (or the total area, if you’d like to imagine it that way) is 4.5 + 0.25 = 4.75. Because 4.5 are spam, the probability that the dart landed on spam is 4.5/4.75 = 0.9474. This means that an email with the words *lottery* and *sale* has a 94.74% probability of being spam. That is quite high!

![Figure 8.12 We have 4.5 spam emails and 0.25 ham emails. We throw a dart, and it hits one of the emails. What is the probability that it hit a spam email? The answer is 94.74%.](https://drek4537l1klr.cloudfront.net/serrano/Figures/8-121.png)

What we did here, using probability, was employing Bayes’ theorem, except with the events

- *E* = *lottery* ∩ *sale*
**
**2
**

**

- *F* = *spam*

to get the formula

Then we (naively) assumed that the appearances of the words *lottery* and *sale* were independent among spam (and ham) emails, to get the following two formulas:

*P*(*lottery* ∩ *sale*|*spam*) = *P*(*lottery*|*spam*) · *P*(*sale*|*spam*)

*P(lottery* ∩ *sale | ham) = P(lottery | ham)* · *P(sale | ham)*

Plugging them into the previous formula, we get

Finally, plugging in the following values:

we get

#### [](/book/grokking-machine-learning/chapter-8/)What about more than two words?

In the general case, the email has *n* words *x*1, *x*2, … , *x*n. Bayes’ theorem states that the probability of an email being spam given that it contains the words *x*1, *x*2, … , *x*n is

In the previous equation we removed the intersection sign and replaced it with a comma. The naive assumption is that the appearances of all these words are independent. Therefore,

*P*(*x*1, *x*2, … , *x*n | *spam*) = *P*(*x*1 | *spam*) *P*(*x*2 | *spam*) … *P*(*x*n | *spam*)

and

*P*(*x*1, *x*2, … , *x*n | *ham*) = *P*(*x*1 | *ham*) *P*(*x*2 | ham) … *P*(*x*n | *ham*).

Putting together the last three equations, we get

Each of these quantities on the right-hand side is easy to estimate as a ratio between numbers of emails. For example, *P*(*x*i | *spam*) is the ratio between the number of spam emails that contain the word *x*i and the total number of spam emails.

As a small example, let’s say that the email contains the words *lottery*, *sale*, and *mom*. We examine the word *mom* and notice that it occurs in only one out of the 20 spam emails and in 10 out of the 80 ham emails. Therefore, *P*(*'mom'*|*spam*) = 1/20 and *P*(*'mom'*|*ham*) = 1/8. Using the same probabilities for the words *lottery* and *sale* as in the previous section, we get the following:

Notice that adding the word *mom* into the equation reduced the probability of spam from 94.74% to 87.80%, which makes sense, because this word is more likely to appear in ham emails than in spam emails.

## [](/book/grokking-machine-learning/chapter-8/)Building a spam-detection model with real data

Now[](/book/grokking-machine-learning/chapter-8/)[](/book/grokking-machine-learning/chapter-8/) that we have developed the algorithm, let’s roll up our sleeves and code the naive Bayes algorithm. Several packages such as Scikit-Learn have great implementations of this algorithm, and I encourage you to look at them. However, we’ll code it by hand. The dataset we use is from Kaggle, and for a link to download it, please check the resources for this chapter in appendix C. Here is the code for this section:

-  **Notebook**: Coding_naive_Bayes.ipynb

- [https://github.com/luisguiserrano/manning/blob/master/Chapter_8_Naive_Bayes/Coding_naive_Bayes.ipynb](https://github.com/luisguiserrano/manning/blob/master/Chapter_8_Naive_Bayes/Coding_naive_Bayes.ipynb)

- **Dataset**: emails.csv

For this example, we’ll introduce a useful package for handling large datasets called Pandas (to learn more about it, please check out the section “Using Pandas to load the dataset” in chapter 13). The main object used to store datasets in pandas is the DataFrame. To load our data into a Pandas DataFrame, we use the following command:

```
import pandas
emails = pandas.read_csv('emails.csv')
```

In table 8.1, you can see the first five rows of the dataset.

This dataset has two columns. The first column is the text of the email (together with its subject line), in string format. The second column tells us if the email is spam (1) or ham (0). First we need to do some data preprocessing.

##### Table 8.1 The first five rows of our email dataset. The Text column shows the text in each email, and the Spam column shows a 1 if the email is spam and a 0 if the email is ham. Notice that the first five emails are all spam.[(view table figure)](https://drek4537l1klr.cloudfront.net/serrano/HighResolutionFigures/table_8-1.png)

| Text | Spam |
| --- | --- |
| Subject: naturally irresistible your corporate... | 1 |
| Subject: the stock trading gunslinger fanny i... | 1 |
| Subject: unbelievable new homes made easy im ... | 1 |
| Subject: 4 color printing special request add... | 1 |
| Subject: do not have money, get software cds ... | 1 |

#### [](/book/grokking-machine-learning/chapter-8/)Data preprocessing

Let’s start by turning the text string into a list of words. We do this using the following function, which uses the `lower()` function[](/book/grokking-machine-learning/chapter-8/) to turn all the words into lowercase and the `split()` function[](/book/grokking-machine-learning/chapter-8/) to turn the words into a list. We check only whether each word appears in the email, regardless of how many times it appears, so we turn it into a set and then into a list.

```
def process_email(text):
text = text.lower()
return list(set(text.split()))
```

Now we use the apply() function[](/book/grokking-machine-learning/chapter-8/) to apply this change to the entire column. We call the new column emails['words'].

```
emails['words'] = emails['text'].apply(process_email)
```

The first five rows of the modified email dataset are shown in table 8.2.

##### Table 8.2 The email dataset with a new column called Words, which contains a list of the words in the email (without repetition) and subject line[(view table figure)](https://drek4537l1klr.cloudfront.net/serrano/HighResolutionFigures/table_8-2.png)

| Text | Spam | Words |
| --- | --- | --- |
| Subject: naturally irresistible your corporate... | 1 | [letsyou, all, do, but, list, is, information,... |
| Subject: the stock trading gunslinger fanny i... | 1 | [not, like, duane, trading, libretto, attainde... |
| Subject: unbelievable new homes made easy im ... | 1 | [im, have, $, take, foward, all, limited, subj... |
| Subject: 4 color printing special request add... | 1 | [color, azusa, pdf, printable, 8102, subject:,... |
| Subject: do not have money, get software cds ... | 1 | [get, not, have, all, do, subject:, be, by, me... |

#### [](/book/grokking-machine-learning/chapter-8/)Finding the priors

Let’s [](/book/grokking-machine-learning/chapter-8/)first find the probability that an email is spam (the prior). For this, we calculate the number of emails that are spam and divide it by the total number of emails. Notice that the number of emails that are spam is the sum of entries in the Spam column. The following line will do the job:

```
sum(emails['spam'])/len(emails)
0.2388268156424581
```

We deduce that the prior probability that the email is spam is around 0.24. This is the probability that an email is spam if we don’t know anything about the email. Likewise, the prior probability that an email is ham is around 0.76.

#### [](/book/grokking-machine-learning/chapter-8/)Finding the posteriors with Bayes’ theorem

We [](/book/grokking-machine-learning/chapter-8/)[](/book/grokking-machine-learning/chapter-8/)need to find the probabilities that spam (and ham) emails contain a certain word. We do this for all words at the same time. The following function creates a dictionary called model, which records each word, together with the number of appearances of the word in spam emails and in ham emails:

```
model = {}

for index, email in emails.iterrows():
   for word in email['words']:
       if word not in model:
           model[word] = {'spam': 1, 'ham': 1}
       if word in model:
           if email['spam']:
               model[word]['spam'] += 1
           else:
               model[word]['ham'] += 1
```

Note that the counts are initialized at 1, so in reality, we are recording one more appearance of the email as spam and ham. We use this small hack to avoid having zero counts, because we don’t want to accidentally divide by zero. Now let’s examine some rows of the dictionary as follows:

```
model['lottery']
{'ham': 1, 'spam': 9}

model['sale']
{'ham': 42, 'spam': 39}
```

This means that the word *lottery* appears in 1 ham email and 9 spam emails, whereas the word *sale* appears in 42 ham emails and 39 spam emails. Although this dictionary doesn’t contain any probabilities, these can be deduced by dividing the first entry by the sum of both entries. Thus, if an email contains the word lottery, the probability of it being spam is , and if it contains the word sale, the probability of it being spam is .

#### [](/book/grokking-machine-learning/chapter-8/)Implementing the naive Bayes algorithm

The[](/book/grokking-machine-learning/chapter-8/) input of the algorithm is the email. It goes through all the words in the email, and for each word, it calculates the probabilities that a spam email contains it and that a ham email contains it. These probabilities are calculated using the dictionary we defined in the previous section. Then we multiply these probabilities (the naive assumption) and apply Bayes’ theorem to find the probability that an email is spam given that it contains the words on this particular email. The code to make a prediction using this model follows:

```
def predict_naive_bayes(email):
    total = len(emails)                                      #1
    num_spam = sum(emails['spam'])
    num_ham = total - num_spam
    email = email.lower()                                    #2
    words = set(email.split())
    spams = [1.0]
    hams = [1.0]
    for word in words:
        if word in model:
            spams.append(model[word]['spam']/num_spam*total) #3
            hams.append(model[word]['ham']/num_ham*total)
    prod_spams = np.long(np.prod(spams)*num_spam)            #4
    prod_hams = np.long(np.prod(hams)*num_ham)
    return prod_spams/(prod_spams + prod_hams)               #5
```

You may note that in the previous code, we used another small hack. Every probability is multiplied by the total number of emails in the dataset. This won’t affect our calculations because this factor appears in the numerator and the denominator. However, it does ensure that our products of probabilities are not too small for Python to handle.

Now that we have built the model, let’s test it by making predictions on some emails as follows:

```
predict_naive_bayes('Hi mom how are you')
0.12554358867163865

predict_naive_bayes('meet me at the lobby of the hotel at nine am')
0.00006964603508395

predict_naive_bayes('buy cheap lottery easy money now')
0.9999734722659664

predict_naive_bayes('asdfgh')
0.2388268156424581
```

It seems to work well. Emails like ‘hi mom how are you’ get a low probability (about 0.12) of being spam, and emails like ‘buy cheap lottery easy money now’ get a very high probability (over 0.99) of being spam. Notice that the last email, which doesn’t contain any of the words in the dictionary, gets a probability of 0.2388, which is precisely the prior.

#### [](/book/grokking-machine-learning/chapter-8/)Further work

This was a quick implementation of the naive Bayes algorithm. But for larger datasets, and larger emails, we should use a package. Packages like Scikit-Learn offer great implementations of the naive Bayes algorithm, with many parameters to play with. Explore this and other packages, and use the naive Bayes algorithm on all types of datasets!

## [](/book/grokking-machine-learning/chapter-8/)Summary

- Bayes’ theorem is a technique widely used in probability, statistics, and machine learning.
- Bayes’ theorem consists of calculating a posterior probability, based on a prior probability and an event.
- The prior probability is a basic calculation of a probability, given very little information.
- Bayes’ theorem uses the event to make a much better estimate of the probability in question.
- The naive Bayes algorithm is used when one wants to combine a prior probability together with several events.
- The word *naive* comes from the fact that we are making a naive assumption, namely, that the events in question are all independent.

## [](/book/grokking-machine-learning/chapter-8/)Exercises

#### Exercise 8.1

For each pair of events A and B, determine if they are independent or dependent. For (a) to (d), provide mathematical justification. For (e) and (f) provide verbal justification.

Throwing three fair coins:

1. A: First one falls on heads. B: Third one falls on tails.
1. A: First one falls on heads. B: There is an odd number of heads among the three throws.

Rolling two dice:

1. A: First one shows a 1. B: Second one shows a 2.
1. A: First one shows a 3. B: Second one shows a higher value than the first one.

For the following, provide a verbal justification. Assume that for this problem, we live in a place with seasons.

1. A: It’s raining outside. B: It’s Monday.
1. A: It’s raining outside. B: It’s June.

#### Exercise 8.2

There is an office where we have to go regularly for some paperwork. This office has two clerks, Aisha and Beto. We know that Aisha works there three days a week, and Beto works the other two. However, the schedules change every week, so we never know which three days Aisha is there, and which two days Beto is there.

1. If we show up on a random day to the office, what is the probability that Aisha is the clerk?

We look from outside and notice that the clerk is wearing a red sweater, although we can’t tell who the clerk is. We’ve been going to that office a lot, so we know that Beto tends to wear red more often than Aisha. In fact, Aisha wears red one day out of three (one-third of the time), and Beto wears red one day out of two (half of the time).

1. What is the probability that Aisha is the clerk, knowing that the clerk is wearing red today?

#### Exercise 8.3

The following is a dataset of patients who have tested positive or negative for COVID-19. Their symptoms are cough (C), fever (F), difficulty breathing (B), and tiredness (T).

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

The goal of this exercise is to build a naive Bayes model that predicts the diagnosis from the symptoms. Use the naive Bayes algorithm to find the following probabilities:

##### note

For the following questions, the symptoms that are not mentioned are completely unknown to us. For example, if we know that the patient has a cough, but nothing is said about their fever, it does not mean the patient doesn’t have a fever.

1. The probability that a patient is sick given that the patient has a cough
1. The probability that a patient is sick given that the patient is not tired
1. The probability that a patient is sick given that the patient has a cough and a fever
1. The probability that a patient is sick given that the patient has a cough and a fever, but no difficulty [](/book/grokking-machine-learning/chapter-8/)breathing
