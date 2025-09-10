# 6 [](/book/grokking-machine-learning/chapter-6/)A continuous approach to splitting points: Logistic classifiers

### In this chapter

- the difference between hard assignments and soft assignments in classification models
- the sigmoid function, a continuous activation function
- discrete perceptrons vs. continuous perceptrons, also called logistic classifiers
- the logistic regression algorithm for classifying data
- coding the logistic regression algorithm in Python
- using the logistic classifier in Turi Create to analyze the sentiment of movie reviews
- using the softmax function to build classifiers for more than two classes

![](https://drek4537l1klr.cloudfront.net/serrano/Figures/CH06_F01_Serrano_Text.png)

In the previous chapter, we built a classifier that determined if a sentence was happy or sad. But as we can imagine, some sentences are happier than others. For example, the sentence “I’m good” and the sentence “Today was the most wonderful day in my life!” are both happy, yet the second is much happier than the first. Wouldn’t it be nice to have a classifier that not only predicts if sentences are happy or sad but that gives a rating for how happy sentences are—say, a classifier that tells us that the first sentence is 60% happy and the second one is 95% happy? In this chapter, we define the *logistic classifier*, which does precisely that. This classifier assigns a score from 0 to 1 to each sentence, in a way that the happier a sentence is, the higher the score it receives.

In a nutshell, a logistic classifier is a type of model that works just like a perceptron classifier, except instead of returning a yes or no answer, it returns a number between 0 and 1. In this case, the goal is to assign scores close to 0 to the saddest sentences, scores close to 1 to the happiest sentences, and scores close to 0.5 to neutral sentences. This threshold of 0.5 is common in practice, though arbitrary. In chapter 7, we’ll see how to adjust it to optimize our model, but for this chapter we use 0.5.

This chapter relies on chapter 5, because the algorithms we develop here are similar, aside from some technical differences. Making sure you understand chapter 5 well will help you understand the material in this chapter. In chapter 5, we described the perceptron algorithm using an error function that tells us how good a perceptron classifier is and an iterative step that turns a classifier into a slightly better classifier. In this chapter, we learn the logistic regression algorithm, which works in a similar way. The main differences follow:

- The step function is replaced by a new activation function, which returns values between 0 and 1.
- The perceptron error function is replaced by a new error function, which is based on a probability calculation.
- The perceptron trick is replaced by a new trick, which improves the classifier based on this new error function.

##### aside

In this chapter we carry out a lot of numerical computations. If you follow the equations, you might find that your calculations differ from those in the book by a small amount. The book rounds the numbers at the very end of the equation, not in between steps. This, however, should have very little effect on the final results.

At the end of the chapter, we apply our knowledge to a real-life dataset of movie reviews on the popular site IMDB ([www.imdb.com](https://www.imdb.com)). We use a logistic classifier to predict whether movie reviews are positive or negative.

The code for this chapter is available in the following GitHub repository: [https://github.com/luisguiserrano/manning/tree/master/Chapter_6_Logistic_Regression](https://github.com/luisguiserrano/manning/tree/master/Chapter_6_Logistic_Regression).

## [](/book/grokking-machine-learning/chapter-6/)Logistic classifiers: A continuous version of perceptron classifiers

In chapter 5, we covered the perceptron, which is a type of classifier that uses the features of our data to make a prediction. The prediction can be 1 or 0. This is called a *discrete perceptron**[](/book/grokking-machine-learning/chapter-6/)*, because it returns an answer from a discrete set (the set containing 0 and 1). In this chapter, we learn *continuous perceptrons**[](/book/grokking-machine-learning/chapter-6/)*, which return an answer that can be any number in the interval between 0 and 1. A more common name for continuous perceptrons is *logistic classifiers*. The output of a logistic classifier can be interpreted as a score, and the goal of the logistic classifier is to assign scores as close as possible to the label of the points—points with label 0 should get scores close to 0, and points with label 1 should get scores close to 1.

We can visualize continuous perceptrons similar to discrete perceptrons: with a line (or high-dimensional plane) that separates two classes of data. The only difference is that the discrete perceptron predicts that everything to one side of the line has label 1 and to the other side has label 0, whereas the continuous perceptron assigns a value from 0 to 1 to all the points based on their position with respect to the line. Every point on the line gets a value of 0.5. This value means the model can’t decide if the sentence is happy or sad. For example, in the ongoing sentiment analysis example, the sentence “Today is Tuesday” is neither happy nor sad, so the model would assign it a score close to 0.5. Points in the positive zone get scores larger than 0.5, where the points even farther away from the 0.5 line in the positive direction get values closer to 1. Points in the negative zone get scores smaller than 0.5, where, again, the points farther from the line get values closer to 0. No point gets a value of 1 or 0 (unless we consider points at infinity), as shown in figure 6.1.

![Figure 6.1 Left: The perceptron algorithm trains a discrete perceptron, where the predictions are 0 (happy) and 1 (sad). Right: The logistic regression algorithm trains a continuous perceptron, where the predictions are numbers between 0 and 1 which indicate the predicted level of happiness.](https://drek4537l1klr.cloudfront.net/serrano/Figures/6-1.png)

Why do we call this *classification**[](/book/grokking-machine-learning/chapter-6/)* instead of *regression**[](/book/grokking-machine-learning/chapter-6/)*, given that the logistic classifier is not outputting a state per se but a number? The reason is, after scoring the points, we can classify them into two classes, namely, those points with a score of 0.5 or higher and those with a score lower than 0.5. Graphically, the two classes are separated by the boundary line, just like with the perceptron classifier. However, the algorithm we use to train logistic classifiers is called the *logistic regression algorithm**[](/book/grokking-machine-learning/chapter-6/)*. This notation is a bit peculiar, but we’ll keep it as it is to match the literature.

#### [](/book/grokking-machine-learning/chapter-6/)A probability approach to classification: The sigmoid function

How [](/book/grokking-machine-learning/chapter-6/)[](/book/grokking-machine-learning/chapter-6/)do we slightly modify the perceptron models from the previous section to get a score for each sentence, as opposed to a simple “happy” or “sad”? Recall how we made the predictions in the perceptron models. We scored each sentence by separately scoring each word and adding the scores, plus the bias. If the score was positive, we predicted that the sentence was happy, and if it was negative, we predicted that the sentence was sad. In other words, what we did was apply the step function to the score. The step function returns a 1 if the score was nonnegative and a 0 if it was negative.

Now we do something similar. We take a function that receives the score as the input and outputs a number between 0 and 1. The number is close to 1 if the score is positive and close to zero if the score is negative. If the score is zero, then the output is 0.5. Imagine if you could take the entire number line and crunch it into the interval between 0 and 1. It would look like the function in figure 6.2.

![Figure 6.2 The sigmoid function sends the entire number line to the interval (0,1).](https://drek4537l1klr.cloudfront.net/serrano/Figures/6-2.png)

Many functions can help us here, and in this case, we use one called the *sigmoid*, denoted with the Greek letter *sigma* (*σ*). The formula for the sigmoid follows:

What really matters here is not the formula but what the function does, which is crunching the real number line into the interval (0,1). In figure 6.3, we can see a comparison of the graphs of the step and the sigmoid functions.

![Figure 6.3 Left: The step function used to build discrete perceptrons. It outputs a value of 0 for any negative input and a value of 1 for any input that is positive or zero. It has a discontinuity at zero. Right: The sigmoid function used to build continuous perceptrons. It outputs values less than 0.5 for negative inputs and values greater than 0.5 for positive inputs. At zero, it outputs 0.5. It is continuous and differentiable everywhere.](https://drek4537l1klr.cloudfront.net/serrano/Figures/6-3.png)

The sigmoid function is, in general, better than the step function for several reasons. Having continuous predictions gives us more information than discrete predictions. In addition, when we get into the calculus, the sigmoid function has a much nicer derivative than the step function. The step function has a derivative of zero, with the exception of the origin, where it is undefined. In table 6.1, we calculate some values of the sigmoid function to make sure the function does what we want it to.

##### Table 6.1 Some inputs and their outputs under the sigmoid function. Notice that for large negative inputs, the output is close to 0, whereas for large positive inputs, the output is close to 1. For the input 0, the output is 0.5.[(view table figure)](https://drek4537l1klr.cloudfront.net/serrano/HighResolutionFigures/table_6-1.png)

| *x* | σ(*x*) |
| --- | --- |
| –5 | 0.007 |
| –1 | 0.269 |
| 0 | 0.5 |
| 1 | 0.731 |
| 5 | 0.993 |

The prediction of a logistic classifier is obtained by applying the sigmoid function to the score, and it returns a number between 0 and 1, which, as was mentioned earlier, can be interpreted in our example as the probability that the sentence is happy.

In chapter 5, we defined an error function for a perceptron, called the perceptron error. We used this perceptron error to iteratively build a perceptron classifier. In this chapter, we follow the same procedure. The error of a continuous perceptron is slightly different from the one of a discrete predictor, but they still have similarities.

#### [](/book/grokking-machine-learning/chapter-6/)The dataset and the predictions

In [](/book/grokking-machine-learning/chapter-6/)this chapter, we use the same use case as in chapter 5, in which we have a dataset of sentences in alien language with the labels “happy” and “sad,” denoted by 1 and 0, respectively. The dataset for this chapter is slightly different than that in chapter 5, and it is shown in table 6.2.

##### Table 6.2 The dataset of sentences with their happy/sad labels. The coordinates are the number of appearances of the words aack and beep in the sentence.[(view table figure)](https://drek4537l1klr.cloudfront.net/serrano/HighResolutionFigures/table_6-2.png)

|   | Words | Coordinates (#aack, #beep) | Label |
| --- | --- | --- | --- |
| Sentence 1 | Aack beep beep aack aack. | (3,2) | Sad (0) |
| Sentence 2 | Beep aack beep. | (1,2) | Happy (1) |
| Sentence 3 | Beep! | (0,1) | Happy (1) |
| Sentence 4 | Aack aack. | (2,0) | Sad (0) |

The model we use has the following weights and bias:

Logistic Classifier 1

- Weight of *Aack*: *a* = 1
- Weight of *Beep*: *b* = 2
- Bias: *c* = –4

We use the same notation as in chapter 5, where the variables *x*aack and *x*beep keep track of the appearances of *aack* and *beep*, respectively. A perceptron classifier would predict according to the formula *ŷ* = *step*(*ax*aack + *bx*beep + *c*), but because this is a logistic classifier, it uses the sigmoid function instead of the step function. Thus, its prediction is *ŷ* = *σ*(*ax*aack + *bx*beep + *c*). In this case, the prediction follows:

**Prediction**: *ŷ* = *σ*(1 · *x*aack + 2 · *x*beep – 4)

Therefore, the classifier makes the following predictions on our dataset:

- **Sentence 1**: *ŷ* = *σ*(3 + 2 · 2 – 4) = *σ*(3) = 0.953.
- **Sentence 2**: *ŷ* = *σ*(1 + 2 · 2 – 4) = *σ*(1) = 0.731.
- **Sentence 3**: *ŷ* = *σ*(0 + 2 · 1 – 4) = *σ*(–2) = 0.119.
- **Sentence 4**: *ŷ* = *σ*(2 + 2 · 0 – 4) = *σ*(–2) = 0.119.

The boundary between the “happy” and “sad” classes is the line with equation *x*aack + 2*x*beep – 4 = 0, depicted in figure 6.4.

![Figure 6.4 The plot of the dataset in table 6.2 with predictions. Notice that points 2 and 4 are correctly classified, but points 1 and 3 are misclassified.](https://drek4537l1klr.cloudfront.net/serrano/Figures/6-4.png)

This line splits the plane into positive (happy) and negative (sad) zones. The positive zone is formed by the points with prediction higher than or equal to 0.5, and the negative zone is formed by those with prediction less than 0.5.

#### [](/book/grokking-machine-learning/chapter-6/)The error functions: Absolute, square, and log loss

In [](/book/grokking-machine-learning/chapter-6/)[](/book/grokking-machine-learning/chapter-6/)this section, we build three error functions for a logistic classifier. What properties would you like a good error function to have? Some examples follow:

- If a point is correctly classified, the error is a small number.
- If a point is incorrectly classified, the error is a large number.
- The error of a classifier for a set of points is the sum (or average) of the errors at all the points.

Many functions satisfy these properties, and we will see three of them; the absolute error, the square error, and the log loss. In table 6.3, we have the labels and predictions for the four points corresponding to the sentences in our dataset with the following characteristics:

- The points on the line are given a prediction of 0.5.
- Points that are in the positive zone are given predictions higher than 0.5, and the farther a point is from the line in that direction, the closer its prediction is to 1.
- Points that are in the negative zone are given predictions lower than 0.5, and the farther a point is from the line in that direction, the closer its prediction is to 0.

##### Table 6.3 Four points—two happy and two sad with their predictions—as illustrated in figure 6.4. Notice that points 1 and 4 are correctly classified, but points 2 and 3 are not. A good error function should assign small errors to the correctly classified points and large errors to the poorly classified points.[(view table figure)](https://drek4537l1klr.cloudfront.net/serrano/HighResolutionFigures/table_6-3.png)

| Point | Label | Prediction | Error? |
| --- | --- | --- | --- |
| 1 | 0 (Sad) | 0.953 | Should be large |
| 2 | 1 (Happy) | 0.731 | Should be small |
| 3 | 1 (Happy) | 0.119 | Should be large |
| 4 | 0 (Sad) | 0.119 | Should be small |

Notice that in table 6.3, points 2 and 4 get a prediction that is close to the label, so they should have small errors. In contrast, points 1 and 3 get a prediction that is far from the label, so they should have large errors. Three error functions that have this particular property follow:

#### Error function 1: Absolute error

The *[](/book/grokking-machine-learning/chapter-6/)[](/book/grokking-machine-learning/chapter-6/)[](/book/grokking-machine-learning/chapter-6/)**absolute error* is similar to the absolute error we defined for linear regression in chapter 3. It is the absolute value of the difference between the prediction and the label. As we can see, it is large when the prediction is far from the label and small when they are close.

#### Error function 2: Square error

Again, [](/book/grokking-machine-learning/chapter-6/)[](/book/grokking-machine-learning/chapter-6/)[](/book/grokking-machine-learning/chapter-6/)just like in linear regression, we also have the *square error*. This is the square of the difference between the prediction and the label, and it works for the same reason that the absolute error works.

Before we proceed, let’s calculate the absolute and square error for the points in table 6.4. Notice that points 2 and 4 (correctly classified) have small errors, and points 1 and 3 (incorrectly classified) have larger errors.

##### Table 6.4 We have attached the absolute error and the square error for the points in table 6.3. Notice that as we desired, points 2 and 4 have small errors, and points 1 and 3 have larger errors.[(view table figure)](https://drek4537l1klr.cloudfront.net/serrano/HighResolutionFigures/table_6-4.png)

| Point | Label | Predicted label | Absolute Error | Square Error |
| --- | --- | --- | --- | --- |
| 1 | 0 (Sad) | 0.953 | 0.953 | 0.908 |
| 2 | 1 (Happy) | 0.731 | 0.269 | 0.072 |
| 3 | 1 (Happy) | 0.119 | 0.881 | 0.776 |
| 4 | 0 (Sad) | 0.119 | 0.119 | 0.014 |

The absolute and the square errors may remind you of the error functions used in regression. However, in classification, they are not so widely used. The most popular is the next one we see. Why is it more popular? The math (derivatives) works much nicer with the next function. Also, these errors are all pretty small. In fact, they are all smaller than 1, no matter how poorly classified the point is. The reason is that the difference (or the square of the difference) between two numbers that are between 0 and 1 is at most 1. To properly train models, we need error functions that take larger values than that. Thankfully, a third error function can do that for [](/book/grokking-machine-learning/chapter-6/)us.

#### Error function 3: log loss

The [](/book/grokking-machine-learning/chapter-6/)[](/book/grokking-machine-learning/chapter-6/)[](/book/grokking-machine-learning/chapter-6/)*log loss* is the most widely used error function for continuous perceptrons. Most of the error functions in this book have the word *error* in their name, but this one instead has the word *loss* in its name. The *log* part in the name comes from a natural logarithm that we use in the formula. However, the real soul of the log loss is probability.

The outputs of a continuous perceptron are numbers between 0 and 1, so they can be considered probabilities. The model assigns a probability to every data point, and that is the probability that the point is happy. From this, we can infer the probability that the point is sad, which is 1 minus the probability of being happy. For example, if the prediction is 0.75, that means the model believes the point is happy with a probability of 0.75 and sad with a probability of 0.25.

Now, here is the main observation. The goal of the model is to assign high probabilities to the happy points (those with label 1) and low probabilities to the sad points (those with label 0). Notice that the probability that a point is sad is 1 minus the probability that the point is happy. Thus, for each point, let’s calculate the probability that the model gives to its label. For the points in our dataset, the corresponding probabilities follow:

-  **Point 1**:

- Label = 0 (sad)
- Prediction (probability of being happy) = 0.953
- Probability of being its label: 1 – 0.953 = **0.047**

-  **Point 2**:

- Label = 1 (happy)
- Prediction (probability of being happy) = 0.731
- Probability of being its label: **0.731**

-  **Point 3**:

- Label = 1 (happy)
- Prediction (probability of being happy) = 0.119
- Probability of being its label: **0.119**

-  **Point 4**:

- Label = 0 (sad)
- Prediction (probability of being happy) = 0.119
- Probability of being its label: 1 – 0.119 = **0.881**

Notice that points 2 and 4 are the points that are well classified, and the model assigns a high probability that they are their own label. In contrast, points 1 and 3 are poorly classified, and the model assigns a low probability that they are their own label.

The logistic classifier, in contrast with the perceptron classifier, doesn’t give definite answers. The perceptron classifier would say, “I am 100% sure that this point is happy,” whereas the logistic classifier says, “Your point has a 73% probability of being happy and 27% of being sad.” Although the goal of the perceptron classifier is to be correct as many times as possible, the goal of the logistic classifier is to assign to each point the highest possible probability of having the correct label. This classifier assigns the probabilities 0.047, 0.731, 0.119, and 0.881 to the four labels. Ideally, we’d like these numbers to be higher. How do we measure these four numbers? One way would be to add them or average them. But because they are probabilities, the natural approach is to multiply them. When events are independent, the probability of them occurring simultaneously is the product of their probabilities. If we assume that the four predictions are independent, then the probability that this model assigns to the labels “sad, happy, happy, sad” is the product of the four numbers, which is 0.047 · 0.731 · 0.119 · 0.881 = 0.004. This is a very small probability. Our hope would be that a model that fits this dataset better would result in a higher probability.

That probability we just calculated seems like a good measure for our model, but it has some problems. For instance, it is a product of many small numbers. Products of many small numbers tend to be tiny. Imagine if our dataset had one million points. The probability would be a product of one million numbers, all between 0 and 1. This number may be so small that a computer may not be able to represent it. Also, manipulating a product of one million numbers is extremely difficult. Is there any way that we could perhaps turn it into something easier to manipulate, like a sum?

Luckily for us, we have a convenient way to turn products into sums—using the logarithms. For this entire book, all we need to know about the logarithm is that it turns products into sums. More specifically, the logarithm of a product of two numbers is the sum of the logarithms of the numbers, as shown next:

*ln*(*a · b*) = *ln*(*a*) + *ln*(*b*)

We can use logarithms in base 2, 10, or e. In this chapter, we use the natural logarithm, which is on base e. However, the same results can be obtained if we were to use the logarithm in any other base.

If we apply the natural logarithm to our product of probabilities, we obtain

*ln*(0.047 *·* 0.731 *·* 0.119 *·* 0.881) = *ln*(0.047) + *ln*(0.731) + *ln*(0.119) + *ln*(0.881) = –5.616.

One small detail. Notice that the result is a negative number. In fact, this will always be the case, because the logarithm of a number between 0 and 1 is always negative. Thus, if we take the negative logarithm of the product of probabilities, it is always a positive number.

The log loss is defined as the negative logarithm of the product of probabilities, which is also the sum of the negative logarithms of the probabilities. Furthermore, each of the summands is the log loss at that point. In table 6.5, you can see the calculation of the log loss for each of the points. By adding the log losses of all the points, we obtain a total log loss of 5.616.

##### Table 6.5 Calculation of the log loss for the points in our dataset. Notice that points that are well classified (2 and 4) have a small log loss, whereas points that are poorly classified (1 and 3) have a large log loss.[(view table figure)](https://drek4537l1klr.cloudfront.net/serrano/HighResolutionFigures/table_6-5.png)

| Point | Label | Predicted label | Probability of being its label | Log loss |
| --- | --- | --- | --- | --- |
| 1 | 0 (Sad) | 0.953 | 0.047 | –ln(0.047) = 3.049 |
| 2 | 1 (Happy) | 0.731 | 0.731 | –ln(0.731) = 0.313 |
| 3 | 1 (Happy) | 0.119 | 0.119 | –ln(0.119) = 2.127 |
| 4 | 0 (Sad) | 0.119 | 0.881 | –ln(0.881) = 0.127 |

Notice that, indeed, the well-classified points (2 and 4) have a small log loss, and the poorly classified points have a large log loss. The reason is that if a number *x* is close to 0, –*ln*(*x*) is a large number, but if *x* is close to 1, then –*ln*(*x*) is a small number.

To summarize, the steps for calculating the log loss follow:

- For each point, we calculate the probability that the classifier gives its label.

- For the happy points, this probability is the score.
- For the sad points, this probability is 1 minus the score.

- We multiply all these probabilities to obtain the total probability that the classifier has given to these labels.
- We apply the natural logarithm to that total probability.
- The logarithm of a product is the sum of the logarithms of the factors, so we obtain a sum of logarithms, one for each point.
- We notice that all the terms are negative, because the logarithm of a number less than 1 is a negative number. Thus, we multiply everything by –1 to get a sum of positive numbers.
- This sum is our log loss.

The log loss is closely related to the concept of *cross-entropy**[](/book/grokking-machine-learning/chapter-6/)*, which is a way to measure similarity between two probability distributions. More details about cross-entropy are available in the references in appendix C.

#### Formula for the log loss

The [](/book/grokking-machine-learning/chapter-6/)log loss for a point can be condensed into a nice formula. Recall that the log loss is the negative logarithm of the probability that the point is its label (happy or sad). The prediction the model gives to each point is *ŷ*, and that is the probability that the point is happy. Thus, the probability that the point is sad, according to the model, is 1 – *ŷ*. Therefore, we can write the log loss as follows:

- If the label is 0: *log loss* = –*ln*(1 – *ŷ*)
- If the label is 1: *log loss* = –*ln*(*ŷ*)

Because the label is y, the previous `if` statement can be condensed into the following formula:

*log loss* = –*y* *ln*(*ŷ*) – (1 – *y*) *ln*(1 – *ŷ*)

The previous formula works because if the label is 0, the first summand is 0, and if the label is 1, the second summand is 0. We use the term *log loss* when we refer to the log loss of a point or of a whole dataset. The log loss of a dataset is the sum of the log losses at every point.

#### [](/book/grokking-machine-learning/chapter-6/)Comparing classifiers using the log loss

Now [](/book/grokking-machine-learning/chapter-6/)[](/book/grokking-machine-learning/chapter-6/)that we have settled on an error function for logistic classifiers, the log loss, we can use it to compare two classifiers. Recall that the classifier we’ve been using in this chapter is defined by the following weights and bias:

Logistic Classifier 1

- Weight of *Aack*: *a* = 1
- Weight of *Beep*: *b* = 2
- Bias: *c* = –4

In [](/book/grokking-machine-learning/chapter-6/)[](/book/grokking-machine-learning/chapter-6/)this section, we compare it with the following logistic classifier:

Logistic Classifier 2

- Weight of *Aack*: *a* = –1
- Weight of *Beep*: *b* = 1
- Bias: *c* = 0

The [](/book/grokking-machine-learning/chapter-6/)[](/book/grokking-machine-learning/chapter-6/)predictions that each classifier makes follow:

- **Classifier 1**: *ŷ* = *σ*(*x*aack + 2*x*beep – 4)
- **Classifier 2**: *ŷ* = *σ*(–*x*aack + *x*beep)

The predictions of both classifiers are recorded in table 6.6, and the plot of the dataset and the two boundary lines are shown in figure 6.5.

##### Table 6.6 Calculation of the log loss for the points in our dataset. Notice that the predictions made by classifier 2 are much closer to the labels of the points than the predictions made by classifier 1. Thus, classifier 2 is a better classifier.[(view table figure)](https://drek4537l1klr.cloudfront.net/serrano/HighResolutionFigures/table_6-6.png)

| Point | Label | Classifier 1 prediction | Classifier 2 prediction |
| --- | --- | --- | --- |
| 1 | 0 (Sad) | 0.953 | 0.269 |
| 2 | 1 (Happy) | 0.731 | 0.731 |
| 3 | 1 (Happy) | 0.119 | 0.731 |
| 4 | 0 (Sad) | 0.881 | 0.119 |

![Figure 6.5 Left: A bad classifier that makes two mistakes. Right: A good classifier that classifies all four points correctly.](https://drek4537l1klr.cloudfront.net/serrano/Figures/6-5.png)

From the results in table 6.6 and figure 6.5, it is clear that classifier 2 is much better than classifier 1. For instance, in figure 6.5, we can see that classifier 2 correctly located the two happy sentences in the positive zone and the two sad sentences in the negative zone. Next, we compare the log losses. Recall that the log loss for classifier 1 was 5.616. We should obtain a smaller log loss for classifier 2, because this is the better classifier.

According to the formula *log loss* = –*y* *ln*(*ŷ*) – (1 – *y*) *ln*(1 – *ŷ*), the log loss for classifier 2 at each of the points in our dataset follows:

-  **Point 1**: *y* = 0, *ŷ* = 0.269:

- *log loss* = *ln*(1 – 0.269) = 0.313

-  **Point 2**: *y* = 1, *ŷ* = 0.731:

- *log loss* = *ln*(0.731) = 0.313

-  **Point 3**: *y* = 1, *ŷ* = 0.731:

- *log loss* = *ln*(0.731) = 0.313

-  **Point 4**: *y* = 0, *ŷ* = 0.119:

- *log loss* = *ln*(1 – 0.119) = 0.127

The total log loss for the dataset is the sum of these four, which is 1.067. Notice that this is much smaller than 5.616, confirming that classifier 2 is indeed much better than classifier 1.

## [](/book/grokking-machine-learning/chapter-6/)How to find a good logistic classifier? The logistic regression algorithm

In [](/book/grokking-machine-learning/chapter-6/)this section, we learn how to train a logistic classifier. The process is similar to the process of training a linear regression model or a perceptron classifier and consists of the following steps:

- Start with a random logistic classifier.
- Repeat many times:

- Slightly improve the classifier.

- Measure the log loss to decide when to stop running the loop.

The key to the algorithm is the step inside the loop, which consists of slightly improving a logistic classifier. This step uses a trick called the *logistic trick**[](/book/grokking-machine-learning/chapter-6/)*. The logistic trick is similar to the perceptron trick, as we see in the next section.

#### [](/book/grokking-machine-learning/chapter-6/)The logistic trick: A way to slightly improve the continuous perceptron

Recall [](/book/grokking-machine-learning/chapter-6/)from chapter 5 that the perceptron trick consists of starting with a random classifier, successively picking a random point, and applying the perceptron trick. It had the following two cases:

- **Case 1**: If the point is correctly classified, leave the line as it is.
- **Case 2**: If the point is incorrectly classified, move the line a little closer to the point.

The logistic trick (illustrated in figure 6.6) is similar to the perceptron trick. The only thing that changes is that when the point is well classified, we move the line *away* from the point. It has the following two cases:

- **Case 1**: If the point is correctly classified, slightly move the line away from the point.
- **Case 2**: If the point is incorrectly classified, slightly move the line closer to the point.

![Figure 6.6 In the logistic regression algorithm, every point has a say. Points that are correctly classified tell the line to move farther away, to be deeper in the correct zone. Points that are incorrectly classified tell the line to come closer, in hopes of one day being on the correct side of the line.](https://drek4537l1klr.cloudfront.net/serrano/Figures/6-6.png)

Why do we move the line away from a correctly classified point? If the point is well classified, it means it is in the correct zone with respect to the line. If we move the line farther away, we move the point even deeper into the correct zone. Because the prediction is based on how far the point is from the boundary line, for points in the positive (happy) zone, the prediction increases if the point is farther from the line. Similarly, for points in the negative (sad) zone, the prediction decreases if the point is farther from the line. Thus, if the label of the point is 1, we are increasing the prediction (making it even closer to 1), and if the label of the point is 0, we are decreasing the prediction (making it even closer to 0).

For example, look at classifier 1 and the first sentence in our dataset. Recall that the classifier has weights *a* = 1, *b* = 2, and bias *c* = –4. The sentence corresponds to a point of coordinates (*x*aack, *x*beep) = (3,2), and label *y* = 0. The prediction we obtained for this point was *ŷ* = *σ*(3 + 2 · 2 – 4) = *σ*(3) = 0.953. The prediction is quite far from the label, so the error is high: in fact, in table 6.5, we calculated it to be 3.049. The error that this classifier made was to think that this sentence is happier than it is. Thus, to tune the weights to ensure that the classifier reduces the prediction for this sentence, we should drastically decrease the weights *a*, *b*, and the bias *c*.

Using the same logic, we can analyze how to tune the weights to improve the classification for the other points. For the second sentence in the dataset, the label is *y* = 1 and the prediction is 0.731. This is a good prediction, but if we want to improve it, we should slightly increase the weights and the bias. For the third sentence, because the label is *y* = 1 and the prediction is *ŷ* = 0.119, we should drastically increase the weights and the bias. Finally, for the fourth sentence, the label is *y* = 0 and the prediction is *ŷ* = 0.119, so we should slightly decrease the weights and the bias. These are summarized in table 6.7.

##### Table 6.7 Calculation of the log loss for the points in our dataset. Notice that points that are well classified (2 and 4) have a small log loss, whereas points that are poorly classified (1 and 3) have a large log loss.[(view table figure)](https://drek4537l1klr.cloudfront.net/serrano/HighResolutionFigures/table_6-7.png)

| Point | Label *y* | Classifier 1 prediction *y* | How to tune the weights *a*, *b*, and the bias *c* | *y* – *ŷ* |
| --- | --- | --- | --- | --- |
| 1 | 0 | 0.953 | Decrease by a large amount | –0.953 |
| 2 | 1 | 0.731 | Increase by a small amount | 0.269 |
| 3 | 1 | 0.119 | Increase by a large amount | 0.881 |
| 4 | 0 | 0.119 | Decrease by a small amount | –0.119 |

The following observations can help us figure out the perfect amount that we want to add to the weights and bias to improve the predictions:

- **Observation 1**: the last column of table 6.7 has the value of the label minus the prediction. Notice the similarities between the two rightmost columns in this table. This hints that the amount we should update the weights and the bias should be a multiple of *y* – *ŷ*.
- **Observation 2**: imagine a sentence in which the word *aack* appears 10 times and *beep* appears once. If we are to add (or subtract) a value to the weights of these two words, it makes sense to think that the weight of *aack* should be updated by a larger amount, because this word is more crucial to the overall score of the sentence. Thus, the amount we should update the weight of *aack* should be multiplied by *x*aack , and the amount we should update the weight of *beep* should be multiplied by *x*beep *.*
- **Observation 3**: the amount that we update the weights and biases should also be multiplied by the learning rate *η* because we want to make sure that this number is small.

Putting the three observations together, we conclude that the following is a good set of updated weights:

- *a*' = *a* + *η*(*y* – *ŷ*)*x*1
- *b*' = *b* + *η*(*y* – *ŷ*)*x*2
- *c*' = *c* + *η*(*y* – *ŷ*)

Thus, the pseudocode for the logistic trick follows. Notice how similar it is to the pseudocode for the perceptron trick we learned at the end of the section “The perceptron trick” in chapter 5.

#### Pseudocode for the logistic trick

Inputs:

- A logistic classifier with weights *a, b,* and bias *c*
- A point with coordinates (*x*1, *x*2) and label *y*
- A small value *η* (the learning rate)

Output:

- A perceptron with new weights *a', b',* and bias *c'* which is at least as good as the input perceptron for that point

Procedure:

- The prediction the perceptron makes at the point is *ŷ* = *σ*(*ax*1 + *bx*2 + *c*).

Return:

- The perceptron with the following weights and bias:

- *a*' = *a* + *η*(*y* - *ŷ*)*x*1
- *b*' = *b* + *η*(*y* - *ŷ*)*x*2
- *c*' = *c* + *η*(*y* - *ŷ*)

The way we updated the weights and bias in the logistic trick is no coincidence. It comes from applying the gradient descent algorithm to reduce the log loss. The mathematical details are described in appendix B, section “Using gradient descent to train classification models.”

To verify that the logistic trick works in our case, let’s apply it to the current dataset. In fact, we’ll apply the trick to each of the four points separately, to see how much each one of them would modify the weights and bias of the model. Finally, we’ll compare the log loss at that point before and after the update and verify that it has indeed been reduced. For the following calculations, we use a learning rate of *η* = 0.05.

#### Updating the classifier using each of the sentences

Using the first sentence:

- Initial weights and bias: *a* = 1, *b* = 2, *c* = –4
- Label: *y* = 0
- Prediction: 0.953
- Initial log loss: –0 · *ln*(0.953) – 1 *ln*(1 – 0.953) = 3.049
- Coordinates of the point: *x*aack = 3, *x*beep = 2
- Learning rate: *η* = 0.01
**
**2
**

**

- Updated weights and bias:

- a' = 1 + 0.05 · (0 – 0.953) · 3 = 0.857
- b' = 2 + 0.05 · (0 – 0.953) · 2 = 1.905
- c' = –4 + 0.05 · (0 – 0.953) = –4.048

- Updated prediction: *ŷ* = *σ*(0.857 · 3 + 1.905 · 2 – 4.048 = 0.912. (Notice that the prediction decreased, so it is now closer to the label 0).
- Final log loss: –0 · *ln*(0.912) – 1 *ln*(1 – 0.912) = 2.426. (Note that the error decreased from 3.049 to 2.426).

The calculations for the other three points are shown in table 6.8. Notice that in the table, the updated prediction is always closer to the label than the initial prediction, and the final log loss is always smaller than the initial log loss. This means that no matter which point we use for the logistic trick, we’ll be improving the model for that point and decreasing the final log loss.

##### Table 6.8 Calculations of the predictions, log loss, updated weights, and updated predictions for all the points.[(view table figure)](https://drek4537l1klr.cloudfront.net/serrano/HighResolutionFigures/table_6-8.png)

| Point | Coordinates | Label | Initial prediction | Initial log loss | Updated weights: | Updated prediction | Final log loss |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | (3,2) | 0 | 0.953 | 3.049 | *a’* = 0.857 *b’* = 1.905 *c’* = –4.048 | 0.912 | 2.426 |
| 2 | (1,2) | 1 | 0.731 | 0.313 | *a’* = 1.013 *b*’ = 2.027 *c*’ = –3.987 | 0.747 | 0.292 |
| 3 | (0,1) | 1 | 0.119 | 2.127 | *a’* = 1 *b’* = 2.044 *c’* = –3.956 | 0.129 | 2.050 |
| 4 | (2,0) | 0 | 0.119 | 0.127 | *a’* = 0.988 *b’* = 2 *c’* = –4.006 | 0.127 | 0.123 |

At the beginning of this section, we discussed that the logistic trick can also be visualized geometrically as moving the boundary line with respect to the point. More specifically, the line is moved closer to the point if the point is misclassified and farther from the point if the point is correctly classified. We can verify this by plotting the original classifier and the modified classifier in the four cases in table 6.8. In figure 6.7, you can see the four plots. In each of them, the solid line is the original classifier, and the dotted line is the classifier obtained by applying the logistic trick, using the highlighted point. Notice that points 2 and 4, which are correctly classified, push the line away, whereas points 1 and 3, which are misclassified, move the line closer to them.

![Figure 6.7 The logistic trick applied to each of the four data points. Notice that for correctly classified points, the line moves away from the point, whereas for misclassified points, the line moves closer to the point.](https://drek4537l1klr.cloudfront.net/serrano/Figures/6-7.png)

#### [](/book/grokking-machine-learning/chapter-6/)Repeating the logistic trick many times: The logistic regression algorithm

The [](/book/grokking-machine-learning/chapter-6/)[](/book/grokking-machine-learning/chapter-6/)logistic regression algorithm is what we use to train a logistic classifier. In the same way that the perceptron algorithm consists of repeating the perceptron trick many times, the logistic regression algorithm consists of repeating the logistic trick many times. The pseudocode follows:

#### Pseudocode for the logistic regression algorithm

Inputs:

- A dataset of points, labeled 1 and 0
- A number of epochs, *n*
- A learning rate *η*

Output:

- A logistic classifier consisting of a set of weights and a bias, which fits the dataset

Procedure:

- Start with random values for the weights and bias of the logistic classifier.
- Repeat many times:

- Pick a random data point.
- Update the weights and the bias using the logistic trick.

Return:

- The perceptron classifier with the updated weights and bias

As we saw previously, each iteration of the logistic trick either moves the line closer to a misclassified point or farther away from a correctly classified point.

#### [](/book/grokking-machine-learning/chapter-6/)Stochastic, mini-batch, and batch gradient descent

The [](/book/grokking-machine-learning/chapter-6/)[](/book/grokking-machine-learning/chapter-6/)[](/book/grokking-machine-learning/chapter-6/)[](/book/grokking-machine-learning/chapter-6/)logistic regression algorithm, together with linear regression and the perceptron, is another algorithm that is based on gradient descent. If we use gradient descent to reduce the log loss, the gradient descent step becomes the logistic trick.

The general logistic regression algorithm works not only for datasets with two features but for datasets with as many features as we want. In this case, just like the perceptron algorithm, the boundary won’t look like a line, but it would look like a higher-dimensional hyperplane splitting points in a higher dimensional space. However, we don’t need to visualize this higher-dimensional space; we only need to build a logistic regression classifier with as many weights as features in our data. The logistic trick and the logistic algorithm update the weights in a similar way to what we did in the previous sections.

Just like with the previous algorithms we learned, in practice, we don’t update the model by picking one point at a time. Instead, we use mini-batch gradient descent—we take a batch of points and update the model to fit those points better. For the fully general logistic regression algorithm and a thorough mathematical derivation of the logistic trick using gradient descent, please refer to appendix B, section “Using gradient descent to train classification models.”

## [](/book/grokking-machine-learning/chapter-6/)Coding the logistic regression algorithm

In [](/book/grokking-machine-learning/chapter-6/)[](/book/grokking-machine-learning/chapter-6/)this section, we see how to code the logistic regression algorithm by hand. The code for this section follows:

-  **Notebook**: Coding_logistic_regression.ipynb

- [https://github.com/luisguiserrano/manning/blob/master/Chapter_6_Logistic_Regression/Coding_logistic_regression.ipynb](https://github.com/luisguiserrano/manning/blob/master/Chapter_6_Logistic_Regression/Coding_logistic_regression.ipynb)

We’ll test our code in the same dataset that we used in chapter 5. The dataset is shown in table 6.9.

##### Table 6.9 The dataset that we will fit with a logistic classifier[(view table figure)](https://drek4537l1klr.cloudfront.net/serrano/HighResolutionFigures/table_6-9.png)

| *Aack* *x*1 | *Beep* *x*2 | Label *y* |
| --- | --- | --- |
| 1 | 0 | 0 |
| 0 | 2 | 0 |
| 1 | 1 | 0 |
| 1 | 2 | 0 |
| 1 | 3 | 1 |
| 2 | 2 | 1 |
| 2 | 3 | 1 |
| 3 | 2 | 1 |

The code for loading our small dataset follows, and the plot of the dataset is shown in figure 6.8:

```
import numpy as np
features = np.array([[1,0],[0,2],[1,1],[1,2],[1,3],[2,2],[2,3],[3,2]])
labels = np.array([0,0,0,0,1,1,1,1])
```

![Figure 6.8 The plot of our dataset, where the happy sentences are represented by triangles and the sad sentences by squares.](https://drek4537l1klr.cloudfront.net/serrano/Figures/6-8.png)

#### [](/book/grokking-machine-learning/chapter-6/)Coding the logistic regression algorithm by hand

In this section, we see how to code the logistic trick and the logistic regression algorithm by hand. More generally, we’ll code the logistic regression algorithm for a dataset with *n* weights. The notation we use follows:

- Features: *x*1, *x*2, … , *x*n
- Label: *y*
- Weights: *w*1, *w*2, … , *w*n
- Bias: *b*

The score for a particular sentence is the sigmoid of the sum of the weight of each word (*w*i) times the number of times that appears (*x*i), plus the bias (*b*). Notice that we use the summation notation for

.

- Prediction: *ŷ* = *σ*(*w*1*x*1 + *w*2*x*2 + … + *w*n*x*n + *b*) = *σ*(Σin=1*w*i *x*i + *b*).

For our current problem, we’ll refer to *x*aack and *x*beep as *x*1 and *x*2, respectively. Their corresponding weights are *w*1 and *w*1, and the bias is *b.*

We start by coding the sigmoid function, the score, and the prediction. Recall that the formula for the sigmoid function is

```
def sigmoid(x):
   return np.exp(x)/(1+np.exp(x))
```

For the score function, we use the dot product between the features and the weights. Recall that the dot product between vectors (*x*1, *x*2, … , *x*n) and (*w*1, *w*2, … , *w*n) is *w*1 *x*1 + *w*2 *x*2 + … + *w*n *x*n.

```
def score(weights, bias, features):
   return np.dot(weights, features) + bias
```

Finally, recall that the prediction is the sigmoid activation function applied to the score.

```
def prediction(weights, bias, features):
   return sigmoid(score(weights, bias, features))
```

Now that we have the prediction, we can proceed to the log loss. Recall that the formula for the log loss is

*log loss* = –*y ln*(*ŷ*) – (1 – *y*) *ln*(1 – *y*).

Let’s code that formula as follows:

```
def log_loss(weights, bias, features, label):
   pred = prediction(weights, bias, features)
   return -label*np.log(pred) - (1-label)*np.log(1-pred)
```

We need the log loss over the whole dataset, so we can add over all the data points as shown here:

```
def total_log_loss(weights, bias, features, labels):
   total_error = 0
   for i in range(len(features)):
       total_error += log_loss(weights, bias, features[i], labels[i])
   return total_error
```

Now we are ready to code the logistic regression trick, and the logistic regression algorithm. In more than two variables, recall that the logistic regression step for the *i*-th weight is the following formula, where *η* is the learning rate:

- *w*i → *w*i + *η*(*y* – *ŷ*)*x*i for *i* = 1, 2, … , *n*
- *b* → *b* + *η*(*y* – *ŷ*) for *i* = 1, 2, … , *n*.

```
def logistic_trick(weights, bias, features, label, learning_rate = 0.01):
   pred = prediction(weights, bias, features)
   for i in range(len(weights)):
       weights[i] += (label-pred)*features[i]*learning_rate
       bias += (label-pred)*learning_rate
   return weights, bias

def logistic_regression_algorithm(features, labels, learning_rate = 0.01, epochs = 1000):
   utils.plot_points(features, labels)
   weights = [1.0 for i in range(len(features[0]))]
   bias = 0.0
   errors = []
   for i in range(epochs):
       errors.append(total_log_loss(weights, bias, features, labels))
       j = random.randint(0, len(features)-1)
       weights, bias = logistic_trick(weights, bias, features[j], labels[j])
   return weights, bias
```

Now we can run the logistic regression algorithm to build a logistic classifier that fits our dataset as follows:

```
logistic_regression_algorithm(features, labels)
([0.46999999999999953, 0.09999999999999937], -0.6800000000000004)
```

The classifier we obtain has the following weights and biases:

- *w*1 = 0.47
- *w*2 = 0.10
- *b* = –0.68

The plot of the classifier (together with a plot of the previous classifiers at each of the epochs) is depicted in figure 6.9.

![Figure 6.9 The boundary of the resulting logistic classifier](https://drek4537l1klr.cloudfront.net/serrano/Figures/6-9.png)

In figure 6.10, we can see the plot of the classifiers corresponding to all the epochs (left) and the plot of the log loss (right). On the plot of the intermediate classifiers (Figure 6.10, left), the final one corresponds to the dark line. Notice from the log loss plot that, as we run the algorithm for more epochs, the log loss decreases drastically, which is exactly what we want. Furthermore, the log loss is never zero, even though all the points are correctly classified. This is because for any point, no matter how well classified, the log loss is never zero. Contrast this to figure 5.26 in chapter 5, where the perceptron loss indeed reaches a value of zero when every point is correctly classified.

![Figure 6.10 Left: A plot of all the intermediate steps of the logistic regression algorithm. Notice that we start with a bad classifier and slowly move toward a good one (the thick line). Right: The error plot. Notice that the more epochs we run the logistic regression algorithm, the lower the error gets.](https://drek4537l1klr.cloudfront.net/serrano/Figures/6-10.png)

## [](/book/grokking-machine-learning/chapter-6/)Real-life application: Classifying IMDB reviews with Turi Create

In [](/book/grokking-machine-learning/chapter-6/)[](/book/grokking-machine-learning/chapter-6/)this section, we see a real-life application of the logistic classifier in sentiment analysis. We use Turi Create to build a model that analyzes movie reviews on the popular IMDB site. The code for this section follows:

-  **Notebook**: Sentiment_analysis_IMDB.ipynb

- [https://github.com/luisguiserrano/manning/blob/master/Chapter_6_Logistic_Regression/Sentiment_analysis_IMDB.ipynb](https://github.com/luisguiserrano/manning/blob/master/Chapter_6_Logistic_Regression/Sentiment_analysis_IMDB.ipynb)

- **Dataset**: IMDB_Dataset.csv

First, we import Turi Create, download the dataset, and convert it into an SFrame, which we call `movies`, as follows:

```
import turicreate as tc
movies = tc.SFrame('IMDB Dataset.csv')
```

The first five rows of the dataset appear in table 6.10.

##### Table 6.10 The first five rows of the IMDB dataset. The Review column has the text of the review, and the Sentiment column has the sentiment of the review, which can be positive or negative.[(view table figure)](https://drek4537l1klr.cloudfront.net/serrano/HighResolutionFigures/table_6-10.png)

| Review | Sentiment |
| --- | --- |
| One of the other reviewers has mentioned... | Positive |
| A wonderful little production... | Positive |
| I thought this was a wonderful day to spend... | Positive |
| Basically, there’s a family where a little... | Negative |
| Petter Mattei’s “Love in the time of money” is a... | Positive |

The dataset has two columns, one with the review, as a string, and one with the sentiment, as positive or negative. First, we need to process the string, because each of the words needs to be a different feature. The Turi Create built-in function `count_words` in the `text_analytics` package[](/book/grokking-machine-learning/chapter-6/) is useful for this task, because it turns a sentence into a dictionary with the word counts. For example, the sentence “to be or not to be” is turned into the dictionary {‘to’:2, ‘be’:2, ‘or’:1, ‘not’:1}. We add a new column called `words` containing this dictionary as follows:

```
movies['words'] = tc.text_analytics.count_words(movies['review'])
```

The first few rows of our dataset with the new column are shown in table 6.11.

##### Table 6.11 The Words column is a dictionary where each word in the review is recorded together with its number of appearances. This is the column of features for our logistic classifier.[(view table figure)](https://drek4537l1klr.cloudfront.net/serrano/HighResolutionFigures/table_6-11.png)

| Review | Sentiment | Words |
| --- | --- | --- |
| One of the other reviewers has mentioned... | Positive | {'if': 1.0, 'viewing': 1.0, 'comfortable': 1.0, ... |
| A wonderful little production... | Positive | {'done': 1.0, 'every': 1.0, 'decorating': 1.0, ... |
| I thought this was a wonderful day to spend... | Positive | {'see': 1.0, 'go': 1.0, 'great': 1.0, 'superm ... |
| Basically, there’s a family where a little... | Negative | {'them': 1.0, 'ignore': 1.0, 'dialogs': 1.0, ... |
| Peter Mattei’s *Love in the Time of Money* is a... | Positive | {'work': 1.0, 'his': 1.0, 'for': 1.0, 'anxiously': ... |

We are ready to train our model! For this, we use the function `create``` in the `logistic_classifier` package[](/book/grokking-machine-learning/chapter-6/), in which we specify the target (label) to be the `sentiment` column[](/book/grokking-machine-learning/chapter-6/) and the features to be the `words` column. Note that the target is expressed as a string with the name of the column containing the label, but the features are expressed as an array of strings with the names of the columns containing each of the features (in case we need to specify several columns), as shown here:

```
model = tc.logistic_classifier.create(movies, features=['words'], target='sentiment')
```

Now that we’ve trained our model, we can look at the weights of the words, with the `coefficients` command. The table we obtain has several columns, but the ones we care about are `index``` and `value`, which show the words and their weights. The top five follow:

- (intercept): 0.065
- if: –0.018
- viewing: 0.089
- comfortable: 0.517
- become: 0.106

The first one, called intercept, is the bias. Because the bias of the model is positive, the empty review is positive, as we learned in chapter 5, in the section “The bias, the *y*-intercept, and the inherent mood of a quiet alien.” This makes sense, because users who rate movies negatively tend to leave a review, whereas many users who rate movies positively don’t leave any review. The other words are neutral, so their weights don’t mean very much, but let’s explore the weights of some words, such as *wonderful*, *horrible*, and *the*, as shown next:

- wonderful: 1.043
- horrible: –1.075
- the: 0.0005

As we see, the weight of the word *wonderful* is positive, the weight of the word *horrible* is negative, and the weight of the word *the* is small. This makes sense: *wonderful* is a positive word, *horrible* is a negative word, and *the* is a neutral word.

As a last step, let’s find the most positive and negative reviews. For this, we use the model to make predictions for all the movies. These predictions will be stored in a new column called `predictions```, using the following command:

```
movies['prediction'] = model.predict(movies, output_type='probability')
```

Let’s find the most positive and most negative movies, according to the model. We do this by sorting the array, as follows:

Most positive review:

```
movies.sort('predictions')[-1]
```

**Output**: “It seems to me that a lot of people don’t know that *Blade* is actually a superhero movie on par with *X-Men*…”

Most negative review:

```
movies.sort('predictions')[0]
```

**Output**: “Even duller, if possible, than the original…”

We could do a lot more to improve this model. For example, some text manipulation techniques, such as removing punctuation and capitalization, or removing stop words (such as *the*, *and*, *of*, *it*), tend to give us better results. But it’s great to see that with a few lines of code, we can build our own sentiment analysis classifier!

## [](/book/grokking-machine-learning/chapter-6/)Classifying into multiple classes: The softmax function

So [](/book/grokking-machine-learning/chapter-6/)[](/book/grokking-machine-learning/chapter-6/)far we have seen continuous perceptrons classify two classes, happy and sad. But what if we have more classes? At the end of chapter 5, we discussed that classifying between more than two classes is hard for a discrete perceptron. However, this is easy to do with a logistic classifier.

Imagine an image dataset with three labels: “dog”, “cat”, and “bird”. The way to build a classifier that predicts one of these three labels for every image is to build three classifiers, one for each one of the labels. When a new image comes in, we evaluate it with each of the three classifiers. The classifier corresponding to each animal returns a probability that the image is the corresponding animal. We then classify the image as the animal from the classifier that returned the highest probability.

This, however, is not the ideal way to do it, because this classifier returns a discrete answer, such as “dog,” “cat,” or “bird.” What if we wanted a classifier that returns probabilities for the three animals? Say, an answer could be of the form “10% dog, 85% cat, and 5% bird.” The way we do this is using the softmax function.

The softmax function works as follows: recall that a logistic classifier makes a prediction using a two-step process—first it calculates a score, and then it applies the sigmoid function to this score. Let’s forget about the sigmoid function and output the score instead. Now imagine that the three classifiers returned the following scores:

- Dog classifier: 3
- Cat classifier: 2
- Bird classifier: –1

How do we turn these scores into probabilities? Well, here’s an idea: we can normalize. This means dividing all these numbers by their sum, which is five, to get them to add to one. When we do this, we get the probabilities 3/5 for dog, 2/5 for cat, and –1/5 for bird. This works, but it’s not ideal, because the probability of the image being a bird is a negative number. Probabilities must always be positive, so we need to try something different.

What we need is a function that is always positive and that is also increasing. Exponential functions work great for this. Any exponential function, such as 2x, 3x, or 10x, would do the job. By default, we use the function *e*x, which has wonderful mathematical properties (e.g., the derivative of *e*x is also *e*x ). We apply this function to the scores, to get the following values:

- Dog classifier: *e*3 = 20.085
- Cat classifier: *e*2 = 7.389
- Bird classifier: *e*–1 = 0.368

Now, we do what we did before—we normalize, or divide by the sum of these numbers for them to add to one. The sum is 20.085 + 7.389 + 0.368 = 27.842, so we get the following:

- Probability of dog: 20.085/27.842 = 0.721
- Probability of cat: 7.389/27.842 = 0.265
- Probability of bird: 0.368/27.842 = 0.013

These are the three probabilities given by our three classifiers. The function we used was the softmax, and the general version follows: if we have *n* classifiers that output the *n* scores *a*1, *a*2, … , *a*n, the probabilities obtained are *p*1, *p*2, … , *p*n, where

This formula is known as the softmax function.

What would happen if we use the softmax function for only two classes? We obtain the sigmoid function. Why not convince yourself of this as an exercise?

## [](/book/grokking-machine-learning/chapter-6/)Summary

- Continuous perceptrons, or logistic classifiers, are similar to perceptron classifiers, except instead of making a discrete prediction such as 0 or 1, they predict any number between 0 and 1.
- Logistic classifiers are more useful than discrete perceptrons, because they give us more information. Aside from telling us which class the classifier predicts, they also give us a probability. A good logistic classifier would assign low probabilities to points with label 0 and high probabilities to points with label 1.
- The log loss is an error function for logistic classifiers. It is calculated separately for every point as the negative of the natural logarithm of the probability that the classifier assigns to its label.
- The total log loss of a classifier on a dataset is the sum of the log loss at every point.
- The logistic trick takes a labeled data point and a boundary line. If the point is incorrectly classified, the line is moved closer to the point, and if it is correctly classified, the line is moved farther from the point. This is more useful than the perceptron trick, because the perceptron trick doesn’t move the line if the point is correctly classified.
- The logistic regression algorithm is used to fit a logistic classifier to a labeled dataset. It consists of starting with a logistic classifier with random weights and continuously picking a random point and applying the logistic trick to obtain a slightly better classifier.
- When we have several classes to predict, we can build several linear classifiers and combine them using the softmax function.

## [](/book/grokking-machine-learning/chapter-6/)Exercises

#### Exercise 6.1

A dentist has trained a logistic classifier on a dataset of patients to predict if they have a decayed tooth. The model has determined that the probability that a patient has a decayed tooth is

*σ*(*d* + 0.5*c* – 0.8),

where

- *d* is a variable that indicates whether the patient has had another decayed tooth in the past, and
- *c* is a variable that indicates whether the patient eats candy.

For example, if a patient eats candy, then *c* = 1, and if they don’t, then *c* = 0. What is the probability that a patient that eats candy and was treated for a decayed tooth last year has a decayed tooth today?

#### Exercise 6.2

Consider the logistic classifier that assigns to the point (*x*1, *x*2) the prediction *ŷ* = *σ*(2*x*1 + 3*x*2 – 4), and the point *p* = (1, 1) with label 0.

1. Calculate the prediction *ŷ* that the model gives to the point *p*.
1. Calculate the log loss that the model produces at the point *p*.
1. Use the logistic trick to obtain a new model that produces a smaller log loss. You can use *η* = 0.1 as the learning rate.
1. Find the prediction given by the new model at the point *p*, and verify that the log loss obtained is smaller than the original.

#### Exercise 6.3

Using the model in the statement of exercise 6.2, find a point for which the prediction is 0.8.

##### hint

First find the score that will give a prediction of 0.8, and recall that the prediction is *ŷ* = *σ*(score).
