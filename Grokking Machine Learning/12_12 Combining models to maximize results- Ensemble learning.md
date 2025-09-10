# [](/book/grokking-machine-learning/chapter-12/)12 Combining models to maximize results: Ensemble learning

### In this chapter

- what ensemble learning is, and how it is used to combine weak classifiers into a stronger one
- using bagging to combine classifiers in a random way
- using boosting to combine classifiers in a cleverer way
- some of the most popular ensemble methods: random forests, AdaBoost, gradient boosting, and XGBoost

![](https://drek4537l1klr.cloudfront.net/serrano/Figures/12-unnumb.png)

After learning many interesting and useful machine learning models, it is natural to wonder if it is possible to combine these classifiers. Thankfully, we can, and in this chapter, we learn several ways to build stronger models by combining weaker ones. The two main methods we learn in this chapter are bagging and boosting. In a nutshell, bagging consists of constructing a few models in a random way and joining them together. Boosting, on the other hand, consists of building these models in a smarter way by picking each model strategically to focus on the previous models’ mistakes. The results that these ensemble methods have shown in important machine learning problems has been tremendous. For example, the Netflix Prize, which was awarded to the best model that fits a large dataset of Netflix viewership data, was won by a group that used an ensemble of different models.

In this chapter, we learn some of the most powerful and popular bagging and boosting models, including random forests, AdaBoost, gradient boosting, and XGBoost. The majority of these are described for classification, and some are described for regression. However, most of the ensemble methods work in both cases.

A bit of terminology: throughout this book, we have referred to machine learning models as models, or sometimes regressors or classifiers, depending on their task. In this chapter, we introduce the term *learner**[](/book/grokking-machine-learning/chapter-12/)*, which also refers to a machine learning model. In the literature, it is common to use the terms *weak learner* and *strong learner* when talking about ensemble methods. However, there is no difference between a machine learning model and a learner.

All the code for this chapter is available in this GitHub repository: [https://github.com/luisguiserrano/manning/tree/master/Chapter_12_Ensemble_Methods](https://github.com/luisguiserrano/manning/tree/master/Chapter_12_Ensemble_Methods).

## [](/book/grokking-machine-learning/chapter-12/)With a little help from our friends

Let’s[](/book/grokking-machine-learning/chapter-12/) visualize ensemble methods using the following analogy: Imagine that we have to take an exam that consists of 100 true/false questions on many different topics, including math, geography, science, history, and music. Luckily, we are allowed to call our five friends—Adriana, Bob, Carlos, Dana, and Emily—to help us. There is a small constraint, which is that all of them work full time, and they don’t have time to answer all 100 questions, but they are more than happy to help us with a subset of them. What techniques can we use to get their help? Two possible techniques follow:

**Technique 1**: For each of the friends, pick several random questions, and ask them to answer them (make sure every question gets an answer from at least one of our friends). After we get the responses, answer the test by selecting the option that was most popular among those who answered that question. For example, if two of our friends answered “True” and one answered “False” on question 1, then we answer question 1 as “True” (if there are ties, we can pick one of the winning responses randomly).

**Technique 2**: We give the exam to Adriana and ask her to answer only the questions she is the surest about. We assume that those answers are good and remove them from the test. Now we give the remaining questions to Bob, with the same instructions. We continue in this fashion until we pass it to all the five friends.

Technique 1 resembles a bagging algorithm, and technique 2 resembles a boosting algorithm. To be more specific, bagging and boosting use a set of models called *weak learners**[](/book/grokking-machine-learning/chapter-12/)* and combine them into a *strong learner* (as illustrated in figure 12.1).

![Figure 12.1 Ensemble methods consist of joining several weak learners to build a strong learner.](https://drek4537l1klr.cloudfront.net/serrano/Figures/12-1.png)

**Bagging****[](/book/grokking-machine-learning/chapter-12/)**: Build random sets by drawing random points from the dataset (with replacement). Train a different model on each of the sets. These models are the weak learners. The strong learner is then formed as a combination of the weak models, and the prediction is done by voting (if it is a classification model) or averaging the predictions (if it is a regression model).

**Boosting****[](/book/grokking-machine-learning/chapter-12/)**: Start by training a random model, which is the first weak learner. Evaluate it on the entire dataset. Shrink the points that have good predictions, and enlarge the points that have poor predictions. Train a second weak learner on this modified dataset. We continue in this fashion until we build several models. The way to combine them into a strong learner is the same way as with bagging, namely, by voting or by averaging the predictions of the weak learner. More specifically, if the learners are classifiers, the strong learner predicts the most common class predicted by the weak learners (thus the term *voting*), and if there are ties, by choosing randomly among them. If the learners are regressors, the strong learner predicts the average of the predictions given by the weak learners.

Most of the models in this chapter use decision trees (both for regression and classification) as the weak learners. We do this because decision trees lend themselves very well to this type of approach. However, as you read the chapter, I encourage you to think of how you would combine other types of models, such as perceptrons and SVMs.

We’ve spent an entire book building very good learners. Why do we want to combine several weak learners instead of simply building a strong learner from the start? One reason is that ensemble methods have been shown to overfit much less than other models. In a nutshell, it is easy for one model to overfit, but if you have several models for the same dataset, the combination of them overfits less. In a sense, it seems that if one learner makes a mistake, the others tend to correct it, and on average, they work better.

We learn the following models in this chapter. The first one is a bagging algorithm, and the last three are boosting:

- Random forests
- AdaBoost
- Gradient boosting
- XGBoost

All these models work for regression and classification. For educational purposes, we learn the first two as classification models and the last two as regression models. The process is similar for both classification and regression. However, read each of them and imagine how it would work in both cases. To learn how all these algorithms work for classification and regression, see the links to videos and reading material in appendix C that explain both cases in detail.

## [](/book/grokking-machine-learning/chapter-12/)Bagging: Joining some weak learners randomly to build a strong learner

In[](/book/grokking-machine-learning/chapter-12/) this section we see one of the most well-known bagging models: a *random forest**[](/book/grokking-machine-learning/chapter-12/)[](/book/grokking-machine-learning/chapter-12/)*. In a random forest, the weak learners are small decision trees trained on random subsets of the dataset. Random forests work well for classification and regression problems, and the process is similar. We will see random forests in a classification example. The code for this section follows:

-  **Notebook**: Random_forests_and_AdaBoost.ipynb

- [https://github.com/luisguiserrano/manning/blob/master/Chapter_12_Ensemble_Methods/Random_forests_and_AdaBoost.ipynb](https://github.com/luisguiserrano/manning/blob/master/Chapter_12_Ensemble_Methods/Random_forests_and_AdaBoost.ipynb)

We use a small dataset of spam and ham emails, similar to the one we used in chapter 8 with the naive Bayes model. The dataset is shown in table 12.1 and plotted in figure 12.2. The features of the dataset are the number of times the words “lottery” and “sale” appear in the email, and the “yes/no” label indicates whether the email is spam (yes) or ham (no).

##### Table 12.1 Table of spam and ham emails, together with the number of appearances of the words “lottery” and “sale” on each email[(view table figure)](https://drek4537l1klr.cloudfront.net/serrano/HighResolutionFigures/table_12-1.png)

| Lottery | Sale | Spam |
| --- | --- | --- |
| 7 | 8 | 1 |
| 3 | 2 | 0 |
| 8 | 4 | 1 |
| 2 | 6 | 0 |
| 6 | 5 | 1 |
| 9 | 6 | 1 |
| 8 | 5 | 0 |
| 7 | 1 | 0 |
| 1 | 9 | 1 |
| 4 | 7 | 0 |
| 1 | 3 | 0 |
| 3 | 10 | 1 |
| 2 | 2 | 1 |
| 9 | 3 | 0 |
| 5 | 3 | 0 |
| 10 | 1 | 0 |
| 5 | 9 | 1 |
| 10 | 8 | 1 |

![Figure 12.2 Figure 12.2  The plot of the dataset in table 12.1. Spam emails are represented by triangles and ham emails by squares. The horizontal and vertical axes represent the number of appearances of the words “lottery” and “sale,” respectively.](https://drek4537l1klr.cloudfront.net/serrano/Figures/12-2.png)

#### First, (over)fitting a decision tree

Before [](/book/grokking-machine-learning/chapter-12/)[](/book/grokking-machine-learning/chapter-12/)[](/book/grokking-machine-learning/chapter-12/)we get into random forests, let’s fit a decision tree classifier to this data and see how well it performs. Because we’ve learned this in chapter 9, figure 12.3 shows only the final result, but we can see the code in the notebook. On the left of figure 12.3, we can see the actual tree (quite deep!), and on the right, we can see the plot of the boundary. Notice that it fits the dataset very well, with a 100% training accuracy, although it clearly overfits. The overfitting can be noticed on the two outliers that the model tries to classify correctly, without noticing they are outliers.

![Figure 12.3 Left: A decision tree that classifies our dataset. Right: The boundary defined by this decision tree. Notice that it splits the data very well, although it hints at overfitting, because a good model would treat the two isolated points as outliers, instead of trying to classify them correctly.](https://drek4537l1klr.cloudfront.net/serrano/Figures/12-3.png)

In the next sections, we see how to solve this overfitting problem by fitting a random forest.

#### [](/book/grokking-machine-learning/chapter-12/)Fitting a random forest manually

In[](/book/grokking-machine-learning/chapter-12/)[](/book/grokking-machine-learning/chapter-12/) this section, we learn how to fit a random forest manually, although this is only for educational purposes, because this is not the way to do it in practice. In a nutshell, we pick random subsets from our dataset and train a weak learner (decision tree) on each one of them. Some data points may belong to several subsets, and others may belong to none. The combination of them is our strong learner. The way the strong learner makes predictions is by letting the weak learners vote. For this dataset, we use three weak learners. Because the dataset has 18 points, let’s consider three subsets of 6 data points each, as shown in figure 12.4.

![Figure 12.4 The first step to build a random forest is to split our data into three subsets. This is a splitting of the dataset shown in figure 12.2.](https://drek4537l1klr.cloudfront.net/serrano/Figures/12-4.png)

[](/book/grokking-machine-learning/chapter-12/)Next, we proceed to build our three weak learners. Fit a decision tree of depth 1 on each of these subsets. Recall from chapter 9 that a decision tree of depth 1 contains only one node and two leaves. Its boundary consists of a single horizontal or vertical line that splits the dataset as best as possible. The weak learners are illustrated in figure 12.5.

![Figure 12.5 The three weak learners that form our random forest are decision trees of depth 1. Each decision tree fits one of the corresponding three subsets from figure 12.4.](https://drek4537l1klr.cloudfront.net/serrano/Figures/12-5.png)

We combine these into a strong learner by voting. In other words, for any input, each of the weak learners predicts a value of 0 or 1. The prediction the strong learner makes is the most common output of the three. This combination can be seen in figure 12.6, where the weak learners are on the top and the strong learner on the bottom.

Note that the random forest is a good classifier, because it classifies most of the points correctly, but it allows a few mistakes in order to not overfit the data. However, we don’t need to train these random forests manually, because Scikit-Learn has functions for this, which we see in the next section.

![Figure 12.6 The way to obtain the predictions of the random forest is by combining the predictions of the three weak learners. On the top, we can see the three boundaries of the decision trees from figure 12.5. On the bottom, we can see how the three decision trees vote to obtain the boundary of the corresponding random forest.](https://drek4537l1klr.cloudfront.net/serrano/Figures/12-6.png)

#### [](/book/grokking-machine-learning/chapter-12/)Training a random forest in Scikit-Learn

In[](/book/grokking-machine-learning/chapter-12/)[](/book/grokking-machine-learning/chapter-12/)[](/book/grokking-machine-learning/chapter-12/) this section, we see how to train a random forest using Scikit-Learn. In the following code, we make use of the `RandomForestClassifier` package[](/book/grokking-machine-learning/chapter-12/). To begin, we have our data in two Pandas DataFrames called `features``` and `labels```, as shown next:

```
from sklearn.ensemble import RandomForestClassifier
random_forest_classifier = RandomForestClassifier(random_state=0, n_estimators=5, max_depth=1)
random_forest_classifier.fit(features, labels)
random_forest_classifier.score(features, labels)
```

In the previous code, we specified that we want five weak learners with the `n_estimators` hyperparameter[](/book/grokking-machine-learning/chapter-12/). These weak learners are again decision trees, and we have specified that their depth is 1 with the `max_depth` hyperparameter[](/book/grokking-machine-learning/chapter-12/). The plot of the model is shown in figure 12.7. Note how this model makes some mistakes but manages to find a good boundary, where the spam emails are those with a lot of appearances of the words “lottery” and “sale” (top right of the plot) and the ham emails are those with not many appearances of these words (bottom left of the figure).

![Figure 12.7 The boundary of the random forest obtained with Scikit-Learn. Notice that it classifies the dataset well, and it treats the two misclassified points as outliers, instead of trying to classify them correctly.](https://drek4537l1klr.cloudfront.net/serrano/Figures/12-7.png)

[](/book/grokking-machine-learning/chapter-12/)Scikit-Learn also allows us to visualize and plot the individual weak learners (see the notebook for the code). The weak learners are shown in figure 12.8. Notice that not all the weak learners are useful. For instance, the first one classifies every point as ham.

![Figure 12.8 The random forest is formed by five weak learners obtained using Scikit-Learn. Each one is a decision tree of depth 1. They combine to form the strong learner shown in figure 12.7.](https://drek4537l1klr.cloudfront.net/serrano/Figures/12-8.png)

In this section, we used decision trees of depth 1 as weak learners, but in general, we can use trees of any depth we want. Try retraining this model using decision trees of higher depth by varying the `max_depth` hyperparameter, and see what the random forest looks [](/book/grokking-machine-learning/chapter-12/)like!

## [](/book/grokking-machine-learning/chapter-12/)AdaBoost: Joining weak learners in a clever way to build a strong learner

Boosting[](/book/grokking-machine-learning/chapter-12/)[](/book/grokking-machine-learning/chapter-12/) is similar to bagging in that we join several weak learners to build a strong learner. The difference is that we don’t select the weak learners at random. Instead, each learner is built by focusing on the weaknesses of the previous learners. In this section, we learn a powerful boosting technique called AdaBoost, developed by Freund and Schapire in 1997 (see appendix C for the reference). AdaBoost is short for adaptive boosting, and it works for regression and classification. However, we will use it in a classification example that illustrates the training algorithm very clearly.

In AdaBoost, like in random forests, each weak learner is a decision tree of depth 1. Unlike random forests, each weak learner is trained on the whole dataset, rather than on a portion of it. The only caveat is that after each weak learner is trained, we modify the dataset by enlarging the points that have been incorrectly classified, so that future weak learners pay more attention to these. In a nutshell, AdaBoost works as follows:

Pseudocode for training an AdaBoost model

- Train the first weak learner on the first dataset.
- Repeat the following step for each new weak learner:

- After a weak learner is trained, the points are modified as follows:

- The points that are incorrectly classified are enlarged.

- Train a new weak learner on this modified dataset.

In this section, we develop this pseudocode in more detail over an example. The dataset we use has two classes (triangles and squares) and is plotted in figure 12.9.

![Figure 12.9 The dataset that we will classify using AdaBoost. It has two labels represented by a triangle and a square.](https://drek4537l1klr.cloudfront.net/serrano/Figures/12-9.png)

#### [](/book/grokking-machine-learning/chapter-12/)A big picture of AdaBoost: Building the weak learners

Over[](/book/grokking-machine-learning/chapter-12/)[](/book/grokking-machine-learning/chapter-12/) the next two subsections, we see how to build an AdaBoost model to fit the dataset shown in figure 12.9. First we build the weak learners that we’ll then combine into one strong learner.

The first step is to assign to each of the points a weight of 1, as shown on the left of figure 12.10. Next, we build a weak learner on this dataset. Recall that the weak learners are decision trees of depth 1. A decision tree of depth 1 corresponds to the horizontal or vertical line that best splits the points. Several such trees do the job, but we’ll pick one—the vertical line illustrated in the middle of figure 12.10—which correctly classifies the two triangles to its left and the five squares to its right, and incorrectly classifies the three triangles to its right. The next step is to enlarge the three incorrectly classified points to give them more importance under the eyes of future weak learners. To enlarge them, recall that each point initially has a weight of 1. We define the *rescaling factor**[](/book/grokking-machine-learning/chapter-12/)* of this weak learner as the number of correctly classified points divided by the number of incorrectly classified points. In this case, the rescaling factor is 7/3 = 2.33. We proceed to rescale every misclassified point by this rescaling factor, as illustrated on the right of figure 12.10.

![Figure 12.10 Fitting the first weak learner of the AdaBoost model. Left: The dataset, where each point gets assigned a weight of 1. Middle: A weak learner that best fits this dataset. Right: The rescaled dataset, where we have enlarged the misclassified points by a rescaling factor of 7/3.](https://drek4537l1klr.cloudfront.net/serrano/Figures/12-10.png)

Now that we’ve built the first weak learner, we build the next ones in the same manner. The second weak learner is illustrated in figure 12.11. On the left of the figure, we have the rescaled dataset. The second weak learner is one that fits this dataset best. What do we mean by that? Because points have different weights, we want the weak learner for which the sum of the weights of the correctly classified points is the highest. This weak learner is the horizontal line in the middle of figure 12.11. We now proceed to calculate the rescaling factor. We need to slightly modify its definition, because the points now have weights. The rescaling factor is the ratio between the sum of the weights of the correctly classified points and the sum of the weights of the incorrectly classified points. The first term is 2.33 + 2.33 + 2.33 + 1 + 1 + 1 + 1 = 11, and the second is 1 + 1 + 1 = 3. Thus, the rescaling factor is 11/3 = 3.67. We proceed to multiply the weights of the three misclassified points by this factor of 3.67, as illustrated on the right of figure 12.11.

![Figure 12.11 Fitting the second weak learner of the AdaBoost model. Left: The rescaled dataset from figure 12.10. Middle: A weak learner that best fits the rescaled dataset—this means, the weak learner for which the sum of weights of the correctly classified points is the largest. Right: The new rescaled dataset, where we have enlarged the misclassified points by a rescaling factor of 11/3.](https://drek4537l1klr.cloudfront.net/serrano/Figures/12-111.png)

We continue in this fashion until we’ve built as many weak learners as we want. For this example, we build only three weak learners. The third weak learner is a vertical line, illustrated in figure 12.12.

![Figure 12.12 Fitting the third weak learner of the AdaBoost model. Left: The rescaled dataset from figure 12.11. Right: A weak learner that best fits this rescaled dataset.](https://drek4537l1klr.cloudfront.net/serrano/Figures/12-12a.png)

This is how we build the weak learners. Now, we need to combine them into a strong learner. This is similar to what we did with random forests, but using a little more math, as shown in the next section.

#### [](/book/grokking-machine-learning/chapter-12/)Combining the weak learners into a strong learner

Now[](/book/grokking-machine-learning/chapter-12/)[](/book/grokking-machine-learning/chapter-12/) that we’ve built the weak learners, in this section, we learn an effective way to combine them into a strong learner. The idea is to get the classifiers to vote, just as they did in the random forest classifier, but this time, good learners get more of a say than poor learners. In the event that a classifier is *really* bad, then its vote will actually be negative.

To understand this, imagine we have three friends: Truthful Teresa, Unpredictable Umbert, and Lying Lenny. Truthful Teresa almost always tells the truth, Lying Lenny almost always lies, and Unpredictable Umbert says the truth roughly half of the time and lies the other half. Out of these three friends, which is the least useful one?

The way I see it, Truthful Teresa is very reliable, because she almost always tells the truth, so we can trust her. Among the other two, I prefer Lying Lenny. If he almost always lies when we ask him a yes-or-no question, we simply take as truth the opposite of what he tells us, and we’ll be correct most of the time! On the other hand, Unpredictable Umbert serves us no purpose if we have no idea whether he’s telling the truth or lying. In that case, if we were to assign a score to what each friend says, I’d give Truthful Teresa a high positive score, Lying Lenny a high negative score, and Unpredictable Umbert a score of zero.

Now imagine that our three friends are weak learners trained in a dataset with two classes. Truthful Teresa is a classifier with very high accuracy, Lying Lenny is one with very low accuracy, and Unpredictable Umbert is one with an accuracy close to 50%. We want to build a strong learner where the prediction is obtained by a weighted vote from the three weak learners. Thus, to each of the weak learners, we assign a score, and that is how much the vote of the learner will count in the final vote. Furthermore, we want to assign these scores in the following way:

- The Truthful Teresa classifier gets a high positive score.
- The Unpredictable Umbert classifier gets a score close to zero.
- The Lying Lenny classifier gets a high negative score.

In other words, the score of a weak learner is a number that has the following properties:

1. Is positive when the accuracy of the learner is greater than 0.5
1. Is 0 when the accuracy of the model is 0.5
1. Is negative when the accuracy of the learner is smaller than 0.5
1. Is a large positive number when the accuracy of the learner is close to 1
1. Is a large negative number when the accuracy of the learner is close to 0

To come up with a good score for a weak learner that satisfies properties 1–5 above, we use a popular concept in probability called the *logit*, or *log-odds*, which we discuss next.

#### Probability, odds, and log-odds

You [](/book/grokking-machine-learning/chapter-12/)[](/book/grokking-machine-learning/chapter-12/)[](/book/grokking-machine-learning/chapter-12/)[](/book/grokking-machine-learning/chapter-12/)may have seen in gambling that probabilities are never mentioned, but they always talk about *odds*. What are these odds? They are similar to probability in the following sense: if we run an experiment many times and record the number of times a particular outcome occurred, the probability of this outcome is the number of times it occurred divided by the total number of times we ran the experiment. The odds of this outcome are the number of times it occurred divided by the number of times it didn’t occur.

For example, the probability of obtaining 1 when we roll a die is 1/6, but the odds are 1/5. If a particular horse wins 3 out of every 4 races, then the probability of that horse winning a race is 3/4, and the odds are 3/1 = 3. The formula for odds is simple: if the probability of an event is *x*, then the odds are . For instance, in the dice example, the probability is 1/6 and the odds are

.

Notice that because the probability is a number between 0 and 1, then the odds are a number between 0 and ∞.

Now let’s get back to our original goal. We are looking for a function that satisfies properties 1–5 above. The odds function is close, but not quite there, because it outputs only positive values. The way to turn the odds into a function that satisfies properties 1–5 above is by taking the logarithm. Thus, we obtain the log-odds, also called the logit, defined as follows:

Figure 12.13 shows the graph of the log-odds function . Notice that this function satisfies properties 1–5.

Therefore, all we need to do is use the log-odds function to calculate the score of each of the weak learners. We apply this log-odds function on the accuracy. Table 12.2 contains several values for the accuracy of a weak learner and the log-odds of this accuracy. Notice that, as desired, models with high accuracy have high positive scores, models with low accuracy have high negative scores, and models with accuracy close to 0.5 have scores close to 0.

![Figure 12.13 The curve shows the plot of the log-odds function with respect to the accuracy. Notice that for small values of the accuracy, the log-odds is a very large negative number, and for higher values of the accuracy, it is a very large positive number. When the accuracy is 50% (or 0.5), the log-odds is precisely zero.](https://drek4537l1klr.cloudfront.net/serrano/Figures/12-13.png)

##### Table 12.2 Several values for the accuracy of a weak classifier, with the corresponding score, calculated using the log-odds. Notice that the models with very low accuracy get large negative scores, the values with very high accuracy get large positive scores, and the values with accuracy close to 0.5 get scores close to 0.[(view table figure)](https://drek4537l1klr.cloudfront.net/serrano/HighResolutionFigures/table_12-2.png)

| Accuracy | Log-odds (score of the weak learner) |
| --- | --- |
| 0.01 | –4.595 |
| 0.1 | –2.197 |
| 0.2 | –1.386 |
| 0.5 | 0 |
| 0.8 | 1.386 |
| 0.9 | 2.197 |
| 0.99 | 4.595 |

#### Combining the classifiers

Now [](/book/grokking-machine-learning/chapter-12/)[](/book/grokking-machine-learning/chapter-12/)that we’ve settled on the log-odds as the way to define the scores for all the weak learners, we can proceed to join them to build the strong learner. Recall that the accuracy of a weak learner is the sum of the scores of the correctly classified points divided by the sum of the scores of all the points, as shown in figures 12.10–12.12.

- Weak learner 1:

- Weak learner 2:

- Weak learner 3:

The prediction that the strong learner makes is obtained by the weighted vote of the weak classifiers, where each classifier’s vote is its score. A simple way to see this is to change the predictions of the weak learners from 0 and 1 to –1 and 1, multiplying each prediction by the score of the weak learner, and adding them. If the resulting prediction is greater than or equal to zero, then the strong learner predicts a 1, and if it is negative, then it predicts a 0. The voting process is illustrated in figure 12.14, and the predictions in figure 12.15. Notice also in figure 12.15 that the resulting classifier classified every point in the dataset correctly.

![Figure 12.14 How to combine the weak learners into a strong learner in the AdaBoost model. We score each of the weak learners using the log-odds and make them vote based on their scores (the larger the score, the more voting power that particular learner has). Each of the regions in the bottom diagram has the sum of the scores of the weak learners. Note that to simplify our calculations, the predictions from the weak learners are +1 and –1, instead of 1 and 0.](https://drek4537l1klr.cloudfront.net/serrano/Figures/12-141.png)

![Figure 12.15 How to obtain the predictions for the AdaBoost model. Once we have added the scores coming from the weak learners (shown in figure 12.14), we assign a prediction of 1 if the sum of scores is greater than or equal to 0 and a prediction of 0 otherwise.](https://drek4537l1klr.cloudfront.net/serrano/Figures/12-151.png)

#### [](/book/grokking-machine-learning/chapter-12/)Coding AdaBoost in Scikit-Learn

In[](/book/grokking-machine-learning/chapter-12/)[](/book/grokking-machine-learning/chapter-12/)[](/book/grokking-machine-learning/chapter-12/) this section, we see how to use Scikit-Learn to train an AdaBoost model. We train it on the same spam email dataset that we used in the section “Fitting a random forest manually” and plotted in figure 12.16. We continue using the following notebook from the previous sections:

-  **Notebook**: Random_forests_and_AdaBoost.ipynb

- [https://github.com/luisguiserrano/manning/blob/master/Chapter_12_Ensemble_Methods/Random_forests_and_AdaBoost.ipynb](https://github.com/luisguiserrano/manning/blob/master/Chapter_12_Ensemble_Methods/Random_forests_and_AdaBoost.ipynb)

![Figure 12.16 In this dataset, we train an AdaBoost classifier using Scikit-Learn. This is the same spam dataset from the section “Bagging,” where the features are the number of appearances of the words “lottery” and “spam,” and the spam emails are represented by triangles and the ham emails by squares.](https://drek4537l1klr.cloudfront.net/serrano/Figures/12-161.png)

The dataset is in two Pandas DataFrames called `features` and `labels`. The training is done using the `AdaBoostClassifier` package[](/book/grokking-machine-learning/chapter-12/) in Scikit-Learn. We specify that this model will use six weak learners with the `n_estimators` hyperparameter, as shown next:

```
from sklearn.ensemble import AdaBoostClassifier
adaboost_classifier = AdaBoostClassifier(n_estimators=6)
adaboost_classifier.fit(features, labels)
adaboost_classifier.score(features, labels)
```

The boundary of the resulting model is plotted in figure 12.17.

We can go a bit further and explore the six weak learners and their scores (see notebook for the code). Their boundaries are plotted in figure 12.18, and as is evident in the notebook, the scores of all the weak learners are 1.

![Figure 12.17 The result of the AdaBoost classifier on the spam dataset in figure 12.16. Notice that the classifier does a good job fitting the dataset and doesn’t overfit much.](https://drek4537l1klr.cloudfront.net/serrano/Figures/12-17.png)

![Figure 12.18 The six weak learners in our AdaBoost model. Each one of them is a decision tree of depth 1. They combine into the strong learner in figure 12.17.](https://drek4537l1klr.cloudfront.net/serrano/Figures/12-18.png)

Note that the strong learner in figure 12.17 is obtained by assigning a score of 1 to each of the weak learners in figure 12.18 and letting them vote.

## [](/book/grokking-machine-learning/chapter-12/)Gradient boosting: Using decision trees to build strong learners

In[](/book/grokking-machine-learning/chapter-12/)[](/book/grokking-machine-learning/chapter-12/)[](/book/grokking-machine-learning/chapter-12/) this section, we discuss gradient boosting, one of the most popular and successful machine learning models currently. Gradient boosting is similar to AdaBoost, in that the weak learners are decision trees, and the goal of each weak learner is to learn from the mistakes of the previous ones. One difference between gradient boosting and AdaBoost is that in gradient boosting, we allow decision trees of depth more than 1. Gradient boosting can be used for regression and classification, but for clarity, we use a regression example. To use it for classification, we need to make some small tweaks. To find out more about this, check out links to videos and reading material in appendix C. The code for this section follows:

-  **Notebook**: Gradient_boosting_and_XGBoost.ipynb

- [https://github.com/luisguiserrano/manning/blob/master/Chapter_12_Ensemble_Methods/Gradient_boosting_and_XGBoost.ipynb](https://github.com/luisguiserrano/manning/blob/master/Chapter_12_Ensemble_Methods/Gradient_boosting_and_XGBoost.ipynb)

The example we use is the same one as in the section “Decision trees for regression” in chapter 9, in which we studied the level of engagement of certain users with an app. The feature is the age of the user, and the label is the number of days that the user engages with the app (table 12.3). The plot of the dataset is shown in figure 12.19.

![Figure 12.19 The plot of the user engagement dataset from table 12.3. The horizontal axis represents the age of the users, and the vertical axis represents the days per week that the user uses our app.](https://drek4537l1klr.cloudfront.net/serrano/Figures/12-19.png)

##### Table 12.3 A small dataset with eight users, their age, and their engagement with our app. The engagement is measured in the number of days when they opened the app in one week. We’ll fit this dataset using gradient boosting.[(view table figure)](https://drek4537l1klr.cloudfront.net/serrano/HighResolutionFigures/table_12-3.png)

| Feature (age) | Label (engagement) |
| --- | --- |
| 10 | 7 |
| 20 | 5 |
| 30 | 7 |
| 40 | 1 |
| 50 | 2 |
| 60 | 1 |
| 70 | 5 |
| 80 | 4 |

The idea of gradient boosting is that we’ll create a sequence of trees that fit this dataset. The two hyperparameters that we’ll use for now are the number of trees, which we set to five, and the learning rate, which we set to 0.8. The first weak learner is simple: it is the decision tree of depth 0 that best fits the dataset. A decision tree of depth 0 is simply a node that assigns the same label to each point in the dataset. Because the error function we are minimizing is the mean square error, then this optimal value for the prediction is the average value of the labels. The average value of the labels of this dataset is 4, so our first weak learner is a node that assigns a prediction of 4 to every point.

The next step is to calculate the residual, which is the difference between the label and the prediction made by this first weak learner, and fit a new decision tree to these residuals. As you can see, what this is doing is training a decision tree to fill in the gaps that the first tree has left. The labels, predictions, and residuals are shown in table 12.4.

The second weak learner is a tree that fits these residuals. The tree can be as deep as we’d like, but for this example, we’ll make sure all the weak learners are of depth at most 2. This tree is shown in figure 12.20 (together with its boundary), and its predictions are in the rightmost column of table 12.4. This tree has been obtained using Scikit-Learn; see the notebook for the procedure.

![Figure 12.20 The second weak learner in the gradient boosting model. This learner is a decision tree of depth 2 pictured on the left. The predictions of this weak learner are shown on the plot on the right.](https://drek4537l1klr.cloudfront.net/serrano/Figures/12-20.png)

##### Table 12.4 The predictions from the first weak learner are the average of the labels. The second weak learner is trained to fit the residuals of the first weak learner.[(view table figure)](https://drek4537l1klr.cloudfront.net/serrano/HighResolutionFigures/table_12-4.png)

| Feature (age) | Label (engagement) | Prediction from weak learner 1 | Residual | Prediction from weak learner 2 |
| --- | --- | --- | --- | --- |
| 10 | 7 | 4 | 3 | 3 |
| 20 | 5 | 4 | 2 | 2 |
| 30 | 7 | 4 | 3 | 2 |
| 40 | 1 | 4 | –3 | –2.667 |
| 50 | 2 | 4 | –2 | –2.667 |
| 60 | 1 | 4 | –3 | –2.667 |
| 70 | 5 | 4 | 1 | 0.5 |
| 80 | 4 | 4 | 0 | 0.5 |

The idea is to continue in this fashion, calculating new residuals and training a new weak learner to fit these residuals. However, there’s a small caveat—to calculate the prediction from the first two weak learners, we first multiply the prediction of the second weak learner by the learning rate. Recall that the learning rate we’re using is 0.8. Thus, the combined prediction of the first two weak learners is the prediction of the first one (4) plus 0.8 times the prediction of the second one. We do this because we don’t want to overfit by fitting our training data too well. Our goal is to mimic the gradient descent algorithm, by slowly walking closer and closer to the solution, and this is what we achieve by multiplying the prediction by the learning rate. The new residuals are the original labels minus the combined predictions of the first two weak learners. These are calculated in table 12.5.

##### Table 12.5 The labels, the predictions from the first two weak learners, and the residual. The prediction from the first weak learner is the average of the labels. The prediction from the second weak learner is shown in figure 12.20. The combined prediction is equal to the prediction of the first weak learner plus the learning rate (0.8) times the prediction of the second weak learner. The residual is the difference between the label and the combined prediction from the first two weak learners.[(view table figure)](https://drek4537l1klr.cloudfront.net/serrano/HighResolutionFigures/table_12-5.png)

| Label | Prediction from weak learner 1 | Prediction from weak learner 2 | Prediction from weak learner 2 times the learning rate | Prediction from weak learners 1 and 2 | Residual |
| --- | --- | --- | --- | --- | --- |
| 7 | 4 | 3 | 2.4 | 6.4 | 0.6 |
| 5 | 4 | 2 | 1.6 | 5.6 | –0.6 |
| 7 | 4 | 2 | 1.6 | 5.6 | 1.4 |
| 1 | 4 | –2.667 | –2.13 | 1.87 | –0.87 |
| 2 | 4 | –2.667 | –2.13 | 1.87 | 0.13 |
| 1 | 4 | –2.667 | –2.13 | 1.87 | –0.87 |
| 5 | 4 | 0.5 | 0.4 | 4.4 | 0.6 |
| 4 | 4 | 0.5 | 0.4 | 4.4 | –0.4 |

Now we can proceed to fit a new weak learner on the new residuals and calculate the combined prediction of the first two weak learners. We obtain this by adding the prediction for the first weak learner and 0.8 (the learning rate) times the sum of the predictions of the second and the third weak learner. We repeat this process for every weak learner we want to build. Instead of doing it by hand, we can use the `GradientBoostingRegressor` package[](/book/grokking-machine-learning/chapter-12/) in Scikit-Learn (the code is in the notebook). The next few lines of code show how to fit the model and make predictions. Note that we have set the depth of the trees to be at most 2, the number of trees to be five, and the learning rate to be 0.8. The hyperparameters used for this are `max_depth`, `n_estimators`, and `learning_rate```. Note, too, that if we want five trees, we must set the `n_estimators` hyperparameter to four, because the first tree isn’t counted.

```
from sklearn.ensemble import GradientBoostingRegressor
gradient_boosting_regressor = GradientBoostingRegressor(max_depth=2, n_estimators=4, learning_rate=0.8)
gradient_boosting_regressor.fit(features, labels)
gradient_boosting_regressor.predict(features)
```

The plot for the resulting strong learner is shown in figure 12.21. Notice that it does a good job predicting the values.

![Figure 12.21 The plot of the predictions of the strong learner in our gradient boosting regressor. Note that the model fits the dataset quite well.](https://drek4537l1klr.cloudfront.net/serrano/Figures/12-211.png)

However, we can go a little further and actually plot the five weak learners we obtain. The details for this are in the notebook, and the five weak learners are shown in figure 12.22. Notice that the predictions of the last weak learners are much smaller than those of the first ones, because each weak learner is predicting the error of the previous ones, and these errors get smaller and smaller at each step.

![Figure 12.22 The five weak learners in the gradient boosting model. The first one is a decision tree of depth 0 that always predicts the average of the labels. Each successive weak learner is a decision tree of depth at most 2, which fits the residuals from the prediction given by the previous weak learners. Note that the predictions of the weak learners get smaller, because the residuals get smaller when the predictions of the strong learner get closer to the labels.](https://drek4537l1klr.cloudfront.net/serrano/Figures/12-22.png)

Finally, we can use Scikit-Learn or a manual calculation to see that the predictions are the following:

- Age = 10, prediction = 6.87
- Age = 20, prediction = 5.11
- Age = 30, prediction = 6.71
- Age = 40, prediction = 1.43
- Age = 50, prediction = 1.43
- Age = 60, prediction = 1.43
- Age = 70, prediction = 4.90
- Age = 80, prediction = 4.10

## [](/book/grokking-machine-learning/chapter-12/)XGBoost: An extreme way to do gradient boosting

XGBoost[](/book/grokking-machine-learning/chapter-12/)[](/book/grokking-machine-learning/chapter-12/), which stands for *extreme gradient boosting**[](/book/grokking-machine-learning/chapter-12/)*, is one of the most popular, powerful, and effective gradient boosting implementations. Created by Tianqi Chen and Carlos Guestrin in 2016 (see appendix C for the reference), XGBoost models often outperform other classification and regression models. In this section, we discuss how XGBoost works, using the same regression example from the section “Gradient boosting: Using decision trees to build strong learners.”

XGBoost uses decision trees as the weak learners, and just like in the previous boosting methods we learned, each weak learner is designed to focus on the weaknesses of the previous ones. More specifically, each tree is built to fit the residuals of the predictions of the previous trees. However, there are some small differences, such as the way we build the trees, which is using a metric called the *similarity score**[](/book/grokking-machine-learning/chapter-12/)*. Furthermore, we add a pruning step to prevent overfitting, in which we remove the branches of the trees if they don’t satisfy certain conditions. In this section, we cover this in more detail.

#### [](/book/grokking-machine-learning/chapter-12/)XGBoost similarity score: A new and effective way to measure similarity in a set

In[](/book/grokking-machine-learning/chapter-12/)[](/book/grokking-machine-learning/chapter-12/)[](/book/grokking-machine-learning/chapter-12/) this subsection, we see the main building block of XGBoost, which is a way to measure how similar the elements of a set are. This metric is aptly called the *similarity score*. Before we learn it, let’s do a small exercise. Among the following three sets, which one has the most amount of similarity, and which one has the least?

- **Set 1**: {10, –10, 4}
- **Set 2**: {7, 7, 7}
- **Set 3**: {7}

If you said that set 2 has the most amount of similarity and set 1 has the least amount, your intuition is correct. In set 1, the elements are very different from each other, so this one has the least amount of similarity. Between sets 2 and 3, it’s not so clear, because both sets have the same element, but a different number of times. However, set 2 has the number seven appearing three times, whereas set 3 has it appearing only once. Therefore, in set 2, the elements are more homogeneous, or more similar, than in set 3.

To quantify similarity, consider the following metric. Given a set {*a*1, *a*2, …, *a*n}, the similarity score is the square of the sum of the elements, divided by the number of elements, namely, . Let’s calculate the similarity score for the three sets above, shown next:

![](https://drek4537l1klr.cloudfront.net/serrano/Figures/12_22_E02.png)

Note that as expected, the similarity score of set 2 is the highest, and that of set 1 is the lowest.

##### note

This similarity score is not perfect. One can argue that the set {1, 1, 1} is more similar than the set {7, 8, 9}, yet the similarity score of {1, 1, 1} is 3, and the similarity score of {7, 8, 9} is 192. However, for the purposes of our algorithm, this score still works. The main goal of the similarity score is to be able to separate the large and small values well, and this goal is met, as we’ll see in the current example.

There is a hyperparameter λ associated with the similarity score, which helps prevent overfitting. When used, it is added to the denominator of the similarity score, which gives the formula . Thus, for example, if λ = 2, the similarity score of set 1 is now . We won’t use the λ hyperparameter in our example, but when we get to the code, we’ll see how to set it to any value we want.

#### [](/book/grokking-machine-learning/chapter-12/)Building the weak learners

In[](/book/grokking-machine-learning/chapter-12/)[](/book/grokking-machine-learning/chapter-12/)[](/book/grokking-machine-learning/chapter-12/) this subsection, we see how to build each one of the weak learners. To illustrate this process, we use the same example from the section “Gradient boosting,” shown in table 12.3. For convenience, the same dataset is shown in the two leftmost columns of table 12.6. This is a dataset of users of an app, in which the feature is the age of the users, and the label is the number of days per week in which they engage with the app. The plot of this dataset is shown in figure 12.19.

##### Table 12.6 The same dataset as in table 12.3, containing users, their age, and the number of days per week in which they engaged with our app. The third column contains the predictions from the first weak learner in our XGBoost model. These predictions are all 0.5 by default. The last column contains the residual, which is the difference between the label and the prediction.[(view table figure)](https://drek4537l1klr.cloudfront.net/serrano/HighResolutionFigures/table_12-6.png)

| Feature (age) | Label (engagement) | Prediction from the first weak learner | Residual |
| --- | --- | --- | --- |
| 10 | 7 | 0.5 | 6.5 |
| 20 | 5 | 0.5 | 4.5 |
| 30 | 7 | 0.5 | 6.5 |
| 40 | 1 | 0.5 | 0.5 |
| 50 | 2 | 0.5 | 1.5 |
| 60 | 1 | 0.5 | 0.5 |
| 70 | 5 | 0.5 | 4.5 |
| 80 | 4 | 0.5 | 3.5 |

The process of training an XGBoost model is similar to that of training gradient boosting trees. The first weak learner is a tree that gives a prediction of 0.5 to each data point. After building this weak learner, we calculate the residuals, which are the differences between the label and the predicted label. These two quantities can be found in the two rightmost columns of table 12.6.

Before we start building the remaining trees, let’s decide how deep we want them to be. To keep this example small, let’s again use a maximum depth of 2. That means that when we get to depth 2, we stop building the weak learners. This is a hyperparameter, which we’ll see in more detail in the section “Training an XGBoost model in Python.”

To build the second weak learner, we need to fit a decision tree to the residuals. We do this using the similarity score. As usual, in the root node, we have the entire dataset. Thus, we begin by calculating the similarity score of the entire dataset as follows:

Now, we proceed to split the node using the age feature in all the possible ways, as we did with decision trees. For each split, we calculate the similarity score of the subsets corresponding to each of the leaves and add them. That is the combined similarity score corresponding to that split. The scores are the following:

Split for the root node, with dataset {6.5, 4.5, 6.5, 0.5, 1.5, 0.5, 4.5, 3.5}, and similarity score = 98:

- Split at 15:

- Left node: {6.5}; similarity score: 42.25
- Right node: {4.5, 6.5, 0.5, 1.5, 0.5, 4.5, 3.5}; similarity score: 66.04
- Combined similarity score: 108.29

- Split at 25:

- Left node: {6.5, 4.5}; similarity score: 60.5
- Right node: {6.5, 0.5, 1.5, 0.5, 4.5, 3.5}; similarity score: 48.17
- Combined similarity score: 108.67

- Split at 35:

- Left node: {6.5, 4.5, 6.5}; similarity score: 102.08
- Right node: {0.5, 1.5, 0.5, 4.5, 3.5}; similarity score: 22.05
- **Combined similarity score: 124.13**

- Split at 45:

- Left node: {6.5, 4.5, 6.5, 0.5}; similarity score: 81
- Right node: {1.5, 0.5, 4.5, 3.5}; similarity score: 25
- Combined similarity score: 106

- Split at 55:

- Left node: {6.5, 4.5, 6.5, 0.5, 1.5}; similarity score: 76.05
- Right node: {0.5, 4.5, 3.5}; similarity score: 24.08
- Combined similarity score: 100.13

- Split at 65:

- Left node: {6.5, 4.5, 6.5, 0.5, 1.5, 0.5}; similarity score: 66.67
- Right node: {4.5, 3.5}; similarity score: 32
- Combined similarity score: 98.67

- Split at 75:

- Left node: {6.5, 4.5, 6.5, 0.5, 1.5, 0.5, 4.5}; similarity score: 85.75
- Right node: {3.5}; similarity score: 12.25
- Combined similarity score: 98

As shown in these calculations, the split with the best combined similarity score is at age = 35. This is going to be the split at the root node.

Next, we proceed to split the datasets at each of the nodes in the same way.

Split for the left node, with dataset {6.5, 4.5, 6.5} and similarity score 102.08:

- Split at 15:

- Left node: {6.5}; similarity score: 42.25
- Right node: {4.5, 6.5}; similarity score: 60.5
- Similarity score: 102.75

- Split at 25:

- Left node: {6.5, 4.5}; similarity score: 60.5
- Right node: {6.5}; similarity score: 42.25
- Similarity score: 102.75

Both splits give us the same combined similarity score, so we can use any of the two. Let’s use the split at 15. Now, on to the right node.

Split for the right node, with dataset {0.5, 1.5, 0.5, 4.5, 3.5} and similarity score 22.05:

- Split at 45:

- Left node: {0.5}; similarity score: 0.25
- Right node: {1.5, 0.5, 4.5, 3.5}; similarity score: 25
- Similarity score: 25.25

- Split at 55:

- Left node: {0.5, 1.5}; similarity score: 2
- Right node: {0.5, 4.5, 3.5}; similarity score: 24.08
- Similarity score: 26.08

- Split at 65:

- Left node: {0.5, 1.5, 0.5}; similarity score: 2.08
- Right node: {4.5, 3.5}; similarity score: 32
- **Similarity score: 34.08**

- Split at 75:

- Left node: {0.5, 1.5, 0.5, 4.5}; similarity score: 12.25
- Right node: {3.5}; similarity score: 12.25
- Similarity score: 24.5

From here, we conclude that the best split is at age = 65. The tree now has depth 2, so we stop growing it, because this is what we decided at the beginning of the algorithm. The resulting tree, together with the similarity scores at the nodes, is shown in figure 12.23.

![Figure 12.23 The second weak learner in our XGBoost classifier. For each of the nodes, we can see the split based on the age feature, the labels corresponding to that node, and the similarity score for each set of labels. The split chosen for each node is the one that maximizes the combined similarity score of the leaves. For each of the leaves, you can see the corresponding labels and their similarity score.](https://drek4537l1klr.cloudfront.net/serrano/Figures/12-231.png)

That’s (almost) our second weak learner. Before we continue building more weak learners, we need to do one more step to help reduce overfitting.

#### [](/book/grokking-machine-learning/chapter-12/)Tree pruning: A way to reduce overfitting by simplifying the weak learners

A[](/book/grokking-machine-learning/chapter-12/)[](/book/grokking-machine-learning/chapter-12/)[](/book/grokking-machine-learning/chapter-12/)[](/book/grokking-machine-learning/chapter-12/) great feature of XGBoost is that it doesn’t overfit much. For this, it uses several hyperparameters that are described in detail in the section “Training an XGBoost model in Python.” One of them, the minimum split loss, prevents a split from happening if the combined similarity scores of the resulting nodes are not significantly larger than the similarity score of the original node. This difference is called the *similarity gain*. For example, in the root node of our tree, the similarity score is 98, and the combined similarity score of the nodes is 124.13. Thus, the similarity gain is 124.13 – 98 = 26.13. Similarly, the similarity gain of the left node is 0.67, and that of the right node is 12.03, as shown in figure 12.24.

![Figure 12.24 On the left, we have the same tree from figure 12.23, with an extra piece of information: the similarity gain. We obtain this by subtracting the similarity score for each node from the combined similarity score of the leaves. We only allow splits with a similarity gain higher than 1 (our minimum split loss hyperparameter), so one of the splits is no longer permitted. This results in the pruned tree on the right, which now becomes our weak learner.](https://drek4537l1klr.cloudfront.net/serrano/Figures/12-24.png)

We’ll set the minimum split loss to 1. With this value, the only split that is prevented is the one on the left node (age ≤ 15). Thus, the second weak learner looks like the one on the right of figure 12.24.

#### [](/book/grokking-machine-learning/chapter-12/)Making the predictions

Now[](/book/grokking-machine-learning/chapter-12/)[](/book/grokking-machine-learning/chapter-12/)[](/book/grokking-machine-learning/chapter-12/) that we’ve built our second weak learner, it’s time to use it to make predictions. We obtain predictions the same way we obtain them from any decision tree, namely, by averaging the labels in the corresponding leaf. The predictions for our second weak learner are seen in figure 12.25.

Now, on to calculate the combined prediction for the first two weak learners. To avoid overfitting, we use the same technique that we used in gradient boosting, which is multiplying the prediction of all the weak learners (except the first one) by the learning rate. This is meant to emulate the gradient descent method, in which we slowly converge to a good prediction after several iterations. We use a learning rate of 0.7. Thus, the combined prediction of the first two weak learners is equal to the prediction of the first weak learner plus the prediction of the second weak learner times 0.7. For example, for the first data point, this prediction is

0.5 + 5.83 . 0.7 = 4.58.

![Figure 12.25 The second weak learner in our XGBoost model after being pruned. This is the same tree from figure 12.24, with its predictions. The prediction at each leaf is the average of the labels corresponding to that leaf.](https://drek4537l1klr.cloudfront.net/serrano/Figures/12-25.png)

The fifth column of table 12.7 contains the combined prediction of the first two weak learners.

##### Table 12.7 The labels, predictions from the first two weak learners, and the residual. The combined prediction is obtained by adding the prediction from the first weak learner (which is always 0.5) plus the learning rate (0.7) times the prediction from the second weak learner. The residual is again the difference between the label and the combined prediction.[(view table figure)](https://drek4537l1klr.cloudfront.net/serrano/HighResolutionFigures/table_12-7.png)

| Label (engagement) | Prediction from weak learner 1 | Prediction from weak learner 2 | Prediction from weak learner 2 times the learning rate | Combined prediction | Residual |
| --- | --- | --- | --- | --- | --- |
| 7 | 0.5 | 5.83 | 4.08 | 4.58 | 2.42 |
| 5 | 0.5 | 5.83 | 4.08 | 4.58 | 0.42 |
| 7 | 0.5 | 5.83 | 4.08 | 4.58 | 2.42 |
| 1 | 0.5 | 0.83 | 0.58 | 1.08 | –0.08 |
| 2 | 0.5 | 0.83 | 0.58 | 1.08 | 0.92 |
| 1 | 0.5 | 0.83 | 0.58 | 1.08 | –0.08 |
| 5 | 0.5 | 4 | 2.8 | 3.3 | 1.7 |
| 4 | 0.5 | 4 | 2.8 | 3.3 | 0.7 |

Notice that the combined predictions are closer to the labels than the predictions of the first weak learner. The next step is to iterate. We calculate new residuals for all the data points, fit a tree to them, prune the tree, calculate the new combined predictions, and continue in this fashion. The number of trees we want is another hyperparameter that we can choose at the start. To continue building these trees, we resort to a useful Python package called `xgboost`.

#### [](/book/grokking-machine-learning/chapter-12/)Training an XGBoost model in Python

In[](/book/grokking-machine-learning/chapter-12/)[](/book/grokking-machine-learning/chapter-12/)[](/book/grokking-machine-learning/chapter-12/) this section, we learn how to train the model to fit the current dataset using the `xgboost` Python package. The code for this section is in the same notebook as the previous one, shown here:

-  **Notebook**: Gradient_boosting_and_XGBoost.ipynb

- [https://github.com/luisguiserrano/manning/blob/master/Chapter_12_Ensemble_Methods/Gradient_boosting_and_XGBoost.ipynb](https://github.com/luisguiserrano/manning/blob/master/Chapter_12_Ensemble_Methods/Gradient_boosting_and_XGBoost.ipynb)

Before we start, let’s revise the hyperparameters that we’ve defined for this model:

##### number of estimators

The number of weak learners. Note: in the `xgboost` package, the first weak learner is not counted among the estimators. For this example, we set it to 3, which will give us four weak learners.

##### maximum depth

[](/book/grokking-machine-learning/chapter-12/) The maximum depth allowed for each one of the decision trees (weak learners). We set it to 2.

##### lambda parameter

[](/book/grokking-machine-learning/chapter-12/) The number added to the denominator of the similarity score. We set it to 0.

##### minimum split loss

[](/book/grokking-machine-learning/chapter-12/) The minimum gain in similarity score to allow for a split to happen. We set it to 1.

##### learning rate

[](/book/grokking-machine-learning/chapter-12/) The predictions from the second to last weak learners are multiplied by the learning rate. We set it to 0.7.

With the following lines of code, we import the package, build a model called `XGBRegressor```, and fit it to our dataset:

```
import xgboost
from xgboost import XGBRegressor
xgboost_regressor = XGBRegressor(random_state=0,
                                n_estimators=3,
                                max_depth=2,
                                reg_lambda=0,
                                min_split_loss=1,
                                learning_rate=0.7)
xgboost_regressor.fit(features, labels)
```

The plot of the model is shown in figure 12.26. Notice that it fits the dataset well.

![Figure 12.26 The plot of the predictions of our XGBoost model. Note that it fits the dataset well.](https://drek4537l1klr.cloudfront.net/serrano/Figures/12-26.png)

The `xgboost` package[](/book/grokking-machine-learning/chapter-12/) also allows us to look at the weak learners, and they appear in figure 12.24. The trees obtained in this fashion already have the labels multiplied by the learning rate of 0.7, which is clear when compared with the predictions of the tree obtained manually in figure 12.25 and the second tree from the left in figure 12.27.

![Figure 12.27 The four weak learners that form the strong learner in our XGBoost model. Note that the first one always predicts 0.5. The other three are quite similar in shape, which is a coincidence. However, notice that the predictions from each of the trees get smaller, because each time we are fitting smaller residuals. Furthermore, notice that the second weak learner is the same tree we obtained manually in figure 12.25, where the only difference is that in this tree, the predictions are already multiplied by the learning rate of 0.7.](https://drek4537l1klr.cloudfront.net/serrano/Figures/12-27.png)

Thus, to obtain the predictions of the strong learner, we need to add only the prediction of every tree. For example, for a user who is 20 years old, the predictions are the following:

- Weak learner 1: 0.5
- Weak learner 2: 4.08
- Weak learner 3: 1.22
- Weak learner 4: –0.57

Thus, the prediction is 0.5 + 5.83 + 1.22 – 0.57 = 5.23. The predictions for the other points [](/book/grokking-machine-learning/chapter-12/)follow:

- Age = 10; prediction = 6.64
- Age = 20; prediction = 5.23
- Age = 30; prediction = 6.05
- Age = 40; prediction = 1.51
- Age = 50; prediction = 1.51
- Age = 60; prediction = 1.51
- Age = 70; prediction = 4.39
- Age = 80; prediction = 4.39

## [](/book/grokking-machine-learning/chapter-12/)Applications of ensemble methods

Ensemble [](/book/grokking-machine-learning/chapter-12/)methods are some of the most useful machine learning techniques used nowadays because they exhibit great levels of performance with relatively low cost. One of the places where ensemble methods are used most is in machine learning challenges, such as the Netflix Challenge. The Netflix Challenge was a competition that Netflix organized, where they anonymized some data and made it public. The competitors’ goal was to build a better recommendation system than Netflix itself; the best system would win one million dollars. The winning team used a powerful combination of learners in an ensemble to win. For more information on this, check the reference in appendix C.

## [](/book/grokking-machine-learning/chapter-12/)Summary

- Ensemble methods consist of training several weak learners and combining them into a strong one. They are an effective way to build powerful models that have had great results with real datasets.
- Ensemble methods can be used for regression and for classification.
- There are two major types of ensemble methods: bagging and boosting.
- Bagging, or bootstrap aggregating, consists of building successive learners on random subsets of our data and combining them into a strong learner that makes predictions based on a majority vote.
- Boosting consists of building a sequence of learners, where each learner focuses on the weaknesses of the previous one, and combining them into a strong classifier that makes predictions based on a weighted vote of the learners.
- AdaBoost, gradient boosting, and XGBoost are three advanced boosting algorithms that produce great results with real datasets.
- Applications of ensemble methods range widely, from recommendation algorithms to applications in medicine and biology.

## [](/book/grokking-machine-learning/chapter-12/)Exercises

#### Exercise 12.1

A boosted strong learner *L* is formed by three weak learners, *L*1, *L*2, and *L*3. Their weights are 1, 0.4, and 1.2, respectively. For a particular point, *L*1 and *L*2 predict that its label is positive, and *L*3 predicts that it’s negative. What is the final prediction the learner *L* makes on this point?

#### Exercise 12.2

We are in the middle of training an AdaBoost model on a dataset of size 100. The current weak learner classifies 68 out of the 100 data points correctly. What is the weight that we’ll assign to this learner in the final model?
