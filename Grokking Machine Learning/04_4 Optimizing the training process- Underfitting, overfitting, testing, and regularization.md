# [](/book/grokking-machine-learning/chapter-4/)4 Optimizing the training process: Underfitting, overfitting, testing, and regularization

### In this chapter

- what is underfitting and overfitting
- some solutions for avoiding overfitting: testing, the model complexity graph, and regularization
- calculating the complexity of the model using the L1 and L2 norms
- picking the best model in terms of performance and complexity

![](https://drek4537l1klr.cloudfront.net/serrano/Figures/CH04_F01_Serrano_Text.png)

This chapter is different from most of the chapters in this book, because it doesn’t contain a particular machine learning algorithm. Instead, it describes some potential problems that machine learning models may face and effective practical ways to solve them.

Imagine that you have learned some great machine learning algorithms, and you are ready to apply them. You go to work as a data scientist, and your first task is to build a machine learning model for a dataset of customers. You build it and put it in production. However, everything goes wrong, and the model doesn’t do a good job of making predictions. What happened?

It turns out that this story is common, because many things can go wrong with our models. Fortunately, we have several techniques to improve them. In this chapter, I show you two problems that happen often when training models: underfitting and overfitting. I then show you some solutions to avoid underfitting and overfitting our models: testing and validation, the model complexity graph, and regularization.

Let’s explain underfitting and overfitting with the following analogy. Let’s say that we have to study for a test. Several things could go wrong during our study process. Maybe we didn’t study enough. There’s no way to fix that, and we’ll likely perform poorly in our test. What if we studied a lot but in the wrong way. For example, instead of focusing on learning, we decided to memorize the entire textbook word for word. Will we do well in our test? It’s likely that we won’t, because we simply memorized everything without learning. The best option, of course, would be to study for the exam properly and in a way that enables us to answer new questions that we haven’t seen before on the topic.

In machine learning, *underfitting**[](/book/grokking-machine-learning/chapter-4/)* looks a lot like not having studied enough for an exam. It happens when we try to train a model that is too simple, and it is unable to learn the data. *Overfitting**[](/book/grokking-machine-learning/chapter-4/)* looks a lot like memorizing the entire textbook instead of studying for the exam. It happens when we try to train a model that is too complex, and it memorizes the data instead of learning it well. A good model, one that neither underfits nor overfits, is one that looks like having studied well for the exam. This corresponds to a good model that learns the data properly and can make good predictions on new data that it hasn’t seen.

Another way to think of underfitting and overfitting is when we have a task in hand. We can make two mistakes. We can oversimplify the problem and come up with a solution that is too simple. We can also overcomplicate the problem and come up with a solution that is too complex.

Imagine if our task is to kill Godzilla, as shown in figure 4.1, and we come to battle equipped with nothing but a fly swatter. That is an example of an *oversimplification**[](/book/grokking-machine-learning/chapter-4/)*. The approach won’t go well for us, because we underestimated the problem and came unprepared. This is underfitting: our dataset is complex, and we come to model it equipped with nothing but a simple model. The model will not be able to capture the complexities of the dataset.

In contrast, if our task is to kill a small fly and we use a bazooka to do the job, this is an example of an *overcomplication*. Yes, we may kill the fly, but we’ll also destroy everything at hand and put ourselves at risk. We overestimated the problem, and our solution wasn’t good. This is overfitting: our data is simple, but we try to fit it to a model that is too complex. The model will be able to fit our data, but it’ll memorize it instead of learning it. The first time I learned overfitting, my reaction was, “Well, that’s no problem. If I use a model that is too complex, I can still model my data, right?” Correct, but the real problem with overfitting is trying to get the model to make predictions on unseen data. The predictions will likely come out looking horrible, as we see later in this chapter.

![Figure 4.1 Underfitting and overfitting are two problems that can occur when training our machine learning model. Left: Underfitting happens when we oversimplify the problem at hand, and we try to solve it using a simple solution, such as trying to kill Godzilla using a fly swatter. Right: Overfitting happens when we overcomplicate the solution to a problem and try to solve it with an exceedingly complicated solution, such as trying to kill a fly using a bazooka.](https://drek4537l1klr.cloudfront.net/serrano/Figures/4-1.png)

As we saw in the section “Parameters and hyperparameters” in chapter 3, every machine learning model has hyperparameters, which are the knobs that we twist and turn before training the model. Setting the right hyperparameters for our model is of extreme importance. If we set some of them wrong, we are prone to underfit or overfit. The techniques that we cover in this chapter are useful to help us tune the hyperparameters correctly.

To make these concepts clearer, we’ll look at an example with a dataset and several different models that are created by changing one particular hyperparameter: the degree of a polynomial.

You can find all the code for this chapter in the following GitHub repository: [https://github.com/luisguiserrano/manning/tree/master/Chapter_4_Testing_Overfitting_Underfitting](https://github.com/luisguiserrano/manning/tree/master/Chapter_4_Testing_Overfitting_Underfitting).

## [](/book/grokking-machine-learning/chapter-4/)An example of underfitting and overfitting using polynomial regression

In[](/book/grokking-machine-learning/chapter-4/)[](/book/grokking-machine-learning/chapter-4/)[](/book/grokking-machine-learning/chapter-4/) this section, we see an example of overfitting and underfitting in the same dataset. Look carefully at the dataset in figure 4.2, and try to fit a polynomial regression model (seen in the section “What if the data is not in a line?” in chapter 3). Let’s think of what kind of polynomial would fit this dataset. Would it be a line, a parabola, a cubic, or perhaps a polynomial of degree 100? Recall that the degree of a polynomial is the highest exponent present. For example, the polynomial 2*x*14 + 9*x*6 – 3*x* + 2 has degree 14.

![Figure 4.2 In this dataset, we train some models and exhibit training problems such as underfitting and overfitting. If you were to fit a polynomial regression model to this dataset, what type of polynomial would you use: a line, a parabola, or something else?](https://drek4537l1klr.cloudfront.net/serrano/Figures/4-2.png)

I think that dataset looks a lot like a parabola that opens downward (a sad face). This is a polynomial of degree 2. However, we are humans, and we eyeballed it. A computer can’t do that. A computer needs to try many values for the degree of the polynomial and somehow pick the best one. Let’s say the computer will try to fit it with polynomials of degrees 1, 2, and 10. When we fit polynomials of degree 1 (a line), 2 (a quadratic), and 10 (a curve that oscillates at most nine times) to this dataset, we obtain the results shown in figure 4.3.

![Figure 4.3 Fitting three models to the same dataset. Model 1 is a polynomial of degree 1, which is a line. Model 2 is a polynomial of degree 2, or a quadratic. Model 3 is a polynomial of degree 10. Which one looks like the best fit?](https://drek4537l1klr.cloudfront.net/serrano/Figures/4-3.png)

In figure 4.3 we see three models, model 1, model 2, and model 3. Notice that model 1 is too simple, because it is a line trying to fit a quadratic dataset. There is no way we’ll find a good line to fit this dataset, because the dataset simply does not look like a line. Therefore, model 1 is a clear example of underfitting. Model 2, in contrast, fits the data pretty well. This model neither overfits nor underfits. Model 3 fits the data extremely well, but it completely misses the point. The data is meant to look like a parabola with a bit of noise, and the model draws a very complicated polynomial of degree 10 that manages to go through each one of the points but doesn’t capture the essence of the data. Model 3 is a clear example of overfitting.

To summarize the previous reasoning, here is an observation that we use throughout this chapter, and in many other episodes in this book: very simple models tend to underfit. Very complex models tend to overfit. The goal is to find a model that is neither too simple nor too complex and that captures the essence of our data well.

We’re about to get to the challenging part. As humans, we know that the best fit is given by model 2. But what does the computer see? The computer can only calculate error functions. As you may recall from chapter 3, we defined two error functions: absolute error and square error. For visual clarity, in this example we’ll use absolute error, which is the average of the sums of the absolute values of the distances from the points to the curve, although the same arguments would work with the square error. For model 1, the points are far from the model, so this error is large. For model 2, these distances are small, so the error is small. However, for model 3, the distances are zero because the points all fall in the actual curve! This means that the computer will think that the perfect model is model 3. This is not good. We need a way to tell the computer that the best model is model 2 and that model 3 is overfitting. How can we do this? I encourage you to put this book down for a few minutes and think of some ideas yourself, because there are several solutions for this problem.

## [](/book/grokking-machine-learning/chapter-4/)How do we get the computer to pick the right model? By testing

One[](/book/grokking-machine-learning/chapter-4/)[](/book/grokking-machine-learning/chapter-4/)[](/book/grokking-machine-learning/chapter-4/) way to determine if a model overfits is by testing it, and that is what we do in this section. Testing a model consists of picking a small set of the points in the dataset and choosing to use them not for training the model but for testing the model’s performance. This set of points is called the *testing set**[](/book/grokking-machine-learning/chapter-4/)*. The remaining set of points (the majority), which we use for training the model, is called the *training set**[](/book/grokking-machine-learning/chapter-4/)*. Once we’ve trained the model on the training set, we use the testing set to evaluate the model. In this way, we make sure that the model is good at generalizing to unseen data, as opposed to memorizing the training set. Going back to the exam analogy, let’s imagine training and testing this way. Let’s say that the book we are studying for in the exam has 100 questions at the end. We pick 80 of them to train, which means we study them carefully, look up the answers, and learn them. Then we use the remaining 20 questions to test ourselves—we try to answer them without looking at the book, as in an exam setting.

Now let’s see how this method looks with our dataset and our models. Notice that the real problem with model 3 is not that it doesn’t fit the data; it’s that it doesn’t generalize well to new data. In other words, if you trained model 3 on that dataset and some new points appeared, would you trust the model to make good predictions with these new points? Probably not, because the model merely memorized the entire dataset without capturing its essence. In this case, the essence of the dataset is that it looks like a parabola that opens downward.

In figure 4.4, we have drawn two white triangles in our dataset, representing the testing set. The training set corresponds to the black circles. Now let’s examine this figure in detail and see how these three models perform with both our training and our testing sets. In other words, let’s examine the error that the model produces in both datasets. We’ll refer to these two errors as the *training error**[](/book/grokking-machine-learning/chapter-4/)* and the *testing error**[](/book/grokking-machine-learning/chapter-4/)*.

The top row in figure 4.4 corresponds to the training set and the bottom row to the testing set. To illustrate the error, we have drawn vertical lines from the point to the model. The mean absolute error is precisely the average of the lengths of these lines. Looking at the top row we can see that model 1 has a large training error, model 2 has a small training error, and model 3 has a tiny training error (zero, in fact). Thus, model 3 does the best job on the training set.

![Figure 4.4 We can use this table to decide how complex we want our model. The columns represent the three models of degree 1, 2, and 10. The rows represent the training and the testing error. The solid circles are the training set, and the white triangles are the testing set. The errors at each point can be seen as the vertical lines from the point to the curve. The error of each model is the mean absolute error given by the average of these vertical lengths. Notice that the training error goes down as the complexity of the model increases. However, the testing error goes down and then back up as the complexity increases. From this table, we conclude that out of these three models, the best one is model 2, because it gives us a low testing error.](https://drek4537l1klr.cloudfront.net/serrano/Figures/4-4.png)

However, when we get to the testing set, things change. Model 1 still has a large testing error, meaning that this is simply a bad model, underperforming with the training and the testing set: it underfits. Model 2 has a small testing error, which means it is a good model, because it fits both the training and the testing set well. Model 3, however, produces a large testing error. Because it did such a terrible job fitting the testing set, yet such a good job fitting the training set, we conclude that model 3 overfits.

Let’s summarize what we have learned so far.

Models can

- Underfit: use a model that is too simple to our dataset.
- Fit the data well: use a model that has the right amount of complexity for our dataset.
- Overfit: use a model that is too complex for our dataset.

In the training set

- The underfit model will do poorly (large training error).
- The good model will do well (small training error).
- The overfit model will do very well (very small training error).

In the testing set

- The underfit model will do poorly (large testing error).
- The good model will do well (small testing error).
- The overfit model will do poorly (large testing error).

Thus, the way to tell whether a model underfits, overfits, or is good, is to look at the training and testing errors. If both errors are high, then it underfits. If both errors are low, then it is a good model. If the training error is low and the testing error is high, then it overfits.

#### [](/book/grokking-machine-learning/chapter-4/)How do we pick the testing set, and how big should it be?

Here’s [](/book/grokking-machine-learning/chapter-4/)[](/book/grokking-machine-learning/chapter-4/)[](/book/grokking-machine-learning/chapter-4/)a question. Where did I pull those two new points from? If we are training a model in production where data is always flowing, then we can pick some of the new points as our testing data. But what if we don’t have a way to get new points, and all we have is our original dataset of 10 points? When this happens, we just sacrifice some of our data and use it as a test set. How much data? That depends on how much data we have and how well we want the model to do, but in practice, any value from 10% to 20% seems to work well.

#### [](/book/grokking-machine-learning/chapter-4/)Can we use our testing data for training the model? No.

In[](/book/grokking-machine-learning/chapter-4/)[](/book/grokking-machine-learning/chapter-4/)[](/book/grokking-machine-learning/chapter-4/) machine learning, we always need to follow an important rule: when we split our data into training and testing, we should use the training data for training the model, and for absolutely no reason should we touch the testing data while training the model or making decisions on the model’s hyperparameters. Failure to do so is likely to result in overfitting, even if it’s not noticeable by a human. In many machine learning competitions, teams have submitted models they think are wonderful, only for them to fail miserably when tested on a secret dataset. This can be because the data scientists training the models somehow (perhaps inadvertently) used the testing data to train them. In fact, this rule is so important, we’ll make it the golden rule of this book.

##### golden rule

Thou shalt never use your testing data for training.

Right now, it seems like it’s an easy rule to follow, but as we’ll see, it’s a very easy rule to accidentally break.

As a matter of fact, we already broke the golden rule during this chapter. Can you tell where? I encourage you to go back and find where we broke it. We’ll see where in the next section.

## [](/book/grokking-machine-learning/chapter-4/)Where did we break the golden rule, and how do we fix it? The validation set

In [](/book/grokking-machine-learning/chapter-4/)[](/book/grokking-machine-learning/chapter-4/)[](/book/grokking-machine-learning/chapter-4/)this section, we see where we broke the golden rule and learn a technique called validation, which will come to our rescue.

We broke the golden rule in the section “How do we get the computer to pick the right model.” Recall that we had three polynomial regression models: one of degree 1, one of degree 2, and one of degree 10, and we didn’t know which one to pick. We used our training data to train the three models, and then we used the testing data to decide which model to pick. We are not supposed to use the testing data to train our model or to make any decisions on the model or its hyperparameters. Once we do this, we are potentially overfitting! We potentially overfit every time we build a model that caters too much to our dataset.

What can we do? The solution is simple: we break our dataset even more. We introduce a new set, the *validation set*, which we then use to make decisions on our dataset. In summary, we break our dataset into the following three sets:

- **Training set**: for training all our models
- **Validation set**: for making decisions on which model to use
- **Testing set**: for checking how well our model did

Thus, in our example, we would have two more points to use for validation, and looking at the validation error should help us decide that the best model to use is model 2. We should use the testing set at the very end, to see how well our model did. If the model is not good, we should throw everything away and start from scratch.

In terms of the sizes of the testing and validation sets, it is common to use a 60-20-20 split or an 80-10-10 split—in other words, 60% training, 20% validation, 20% testing, or 80% training, 10% validation, 10% testing. These numbers are arbitrary, but they tend to work well, because they leave most of the data for training but still allow us to test the model in a big enough set.

## [](/book/grokking-machine-learning/chapter-4/)A numerical way to decide how complex our model should be: The model complexity graph

In[](/book/grokking-machine-learning/chapter-4/)[](/book/grokking-machine-learning/chapter-4/)[](/book/grokking-machine-learning/chapter-4/) the previous sections, we learned how to use the validation set to help us decide which model was the best among three different ones. In this section, we learn about a graph called the *model complexity graph*, which helps us decide among many more models. Imagine that we have a different and much more complex dataset, and we are trying to build a polynomial regression model to fit it. We want to decide the degree of our model among the numbers between 0 and 10 (inclusive). As we saw in the previous section, the way to decide which model to use is to pick the one that has the smallest validation error.

However, plotting the training and testing errors can give us some valuable information and help us examine trends. In figure 4.5, you can see a plot in which the horizontal axis represents the degree of the polynomial in the model and the vertical axis represents the value of the error. The diamonds represent the training error, and the circles represent the validation error. This is the model complexity graph.

![Figure 4.5 The model complexity graph is an effective tool to help us determine the ideal complexity of a model to avoid underfitting and overfitting. In this model complexity graph, the horizontal axis represents the degree of several polynomial regression models, from 0 to 10 (i.e., the complexity of the model). The vertical axis represents the error, which in this case is given by the mean absolute error. Notice that the training error starts large and decreases as we move to the right. This is because the more complex our model is, the better it can fit the training data. The validation error, however, starts large, then decreases, and then increases again—very simple models can’t fit our data well (they underfit), whereas very complex models fit our training data but not our validation data because they overfit. A happy point in the middle is where our model neither underfits or overfits, and we can find it using the model complexity graph.](https://drek4537l1klr.cloudfront.net/serrano/Figures/4-5.png)

Notice that in the model complexity graph in figure 4.5, the lowest value for the validation error occurs at degree 4, which means that for this dataset, the best-fitting model (among the ones we are considering) is a polynomial regression model of degree 4. Looking at the left of the graph, we can see that when the degree of the polynomial is small, both the training and the validation errors are large, which implies that the models underfit. Looking at the right of the graph, we can see that the training error gets smaller and smaller, but the validation error gets larger and larger, which implies that the models overfit. The sweet spot happens around 4, which is the model we pick.

One benefit of the model complexity graph is that no matter how large our dataset is or how many different models we try, it always looks like two curves: one that always goes down (the training error) and one that goes down and then back up (the validation error). Of course, in a large and complex dataset, these curves may oscillate, and the behavior may be harder to spot. However, the model complexity graph is always a useful tool for data scientists to find a good spot in this graph and decide how complex their models should be to avoid both underfitting and overfitting.

Why do we need such a graph if all we need to do is pick the model with the lowest validation error? This method is true in theory, but in practice, as a data scientist, you may have a much better idea of the problem you are solving, the constraints, and the benchmarks. If you see, for example, that the model with the smallest validation error is still quite complex, and that there is a much simpler model that has only a slightly higher validation error, you may be more inclined to pick that one. A great data scientist is one who can combine these theoretical tools with their knowledge about the use case to build the best and most effective models.

## [](/book/grokking-machine-learning/chapter-4/)Another alternative to avoiding overfitting: Regularization

In[](/book/grokking-machine-learning/chapter-4/)[](/book/grokking-machine-learning/chapter-4/)[](/book/grokking-machine-learning/chapter-4/) this section, we discuss another useful technique to avoid overfitting in our models that doesn’t require a testing set: *regularization*. Regularization relies on the same observation we made in the section “An example of underfitting and overfitting using polynomial regression,” where we concluded that simple models tend to underfit and complex models tend to overfit. However, in the previous methods, we tested several models and selected the one that best balanced performance and complexity. In contrast, when we use regularization, we don’t need to train several models. We simply train the model once, but during the training, we try to not only improve the model’s performance but also reduce its complexity. The key to doing this is to measure both performance and complexity at the same time.

Before we get into the details, let’s discuss an analogy for thinking about measuring the performance and complexity of models. Imagine that we have three houses, and all of them have the same problem—the roof is leaking (figure 4.6). Three roofers come, and each fixes one of the houses. The first roofer used a bandage, the second one used roofing shingles, and the third one used titanium. From our intuition, it seems that the best one is roofer 2, because roofer 1 oversimplified the problem (underfitting) and roofer 3 overcomplicated it (overfitting).

![Figure 4.6 An analogy for underfitting and overfitting. Our problem consists of a broken roof. We have three roofers who can fix it. Roofer 1 comes with a bandage, roofer 2 comes with roofing shingles, and roofer 3 comes with a block of titanium. Roofer 1 oversimplified the problem, so they represent underfitting. Roofer 2 used a good solution. Roofer 3 overcomplicated the solution, so they represent overfitting.](https://drek4537l1klr.cloudfront.net/serrano/Figures/4-6.png)

However, we need to make our decisions using numbers, so let’s take some measurements. The way to measure the performance of the roofers is by how much water leaked after they fix their roof. They had the following scores:

Performance (in mL of water leaked)

Roofer 1: 1000 mL water

Roofer 2: 1 mL water

Roofer 3: 0 mL water

It seems that roofer 1 had a terrible performance, because the roof was still leaking water. However, between roofers 2 and 3, which one do we pick? Perhaps roofer 3, who had a better performance? The performance measure is not good enough; it correctly removes roofer 1 from the equation, but it erroneously tells us to go with roofer 3, instead of roofer 2. We need a measure of their complexity to help us make the right decision. A good measure of their complexity is how much they charged us to fix the roof, in dollars. The prices were as follows:

Complexity (in price)

Roofer 1: $1

Roofer 2: $100

Roofer 3: $100,000

Now we can tell that roofer 2 is better than roofer 3, because they had the same performance, but roofer 2 charged less. However, roofer 1 was the cheapest one—why on’t we go with this one? It seems that what we need is to combine the measures of performance and complexity. We can add the amount of water that the roof leaked and the price, to get the following:

Performance + complexity

Roofer 1: 1001

Roofer 2: 101

Roofer 3: 100,000

Now it is clear that roofer 2 is the best one, which means that optimizing performance and complexity at the same time yields good results that are also as simple as possible. This is what regularization is about: measuring performance and complexity with two different error functions, and adding them to get a more robust error function. This new error function ensures that our model performs well and is not very complex. In the following sections, we get into more details on how to define these two error functions. But before that, let’s look at another overfitting example.

#### [](/book/grokking-machine-learning/chapter-4/)Another example of overfitting: Movie recommendations

In[](/book/grokking-machine-learning/chapter-4/)[](/book/grokking-machine-learning/chapter-4/)[](/book/grokking-machine-learning/chapter-4/) this section, we learn a more subtle way in which a model may overfit—this time not related to the degree of the polynomial but on the number of features and the size of the coefficients. Imagine that we have a movie streaming website, and we are trying to build a recommender system. For simplicity, imagine that we have only 10 movies: M1, M2, …, M10. A new movie, M11, comes out, and we’d like to build a linear regression model to recommend movie 11 based on the previous 10. We have a dataset of 100 users. For each user, we have 10 features, which are the times (in seconds) that the user has watched each of the original 10 movies. If the user hasn’t watched a movie, then this amount is 0. The label for each user is the amount of time the user watched movie 11. We want to build a model that fits this dataset. Given that the model is a linear regression model, the equation for the predicted time the user will watch movie 11 is linear, and it will look like the following:

*ŷ* = *w*1*x*1 + *w*2*x*2 + *w*3*x*3+ *w*4*x*4 + *w*5*x*5 + *w*6*x*6 + *w*7*x*7 + *w*8*x*8 ++ *w*9*x*9 + *w*10*x*10 + *b*,

where

- *ŷ* is the amount of time the model predicts that the user will watch movie 11,
- *x*i is the amount of time the user watched movie *i*, for *i* = 1, 2, …, 10,
- *w*i is the weight associated to movie *i*, and
- *b* is the bias.

Now let’s test our intuition. Out of the following two models (given by their equation), which one (or ones) looks like it may be overfitting?

**Model 1**: *ŷ* = 2*x*3 + 1.4*x*7 – 0.5*x*7 + 4

**Model 2**: *ŷ* = 22*x*1 – 103*x*2 – 14*x*3 + 109*x*4 – 93*x*5 + 203*x*6 + 87*x*7 – 55*x*8 + 378*x*9 – 25*x*10 + 8

If you think like me, model 2 seems a bit complicated, and it may be the one overfitting. The intuition here is that it’s unlikely that the time that a user watched movie 2 needs to be multiplied by –103 and then added to other numbers to obtain the prediction. This may fit the data well, but it definitely looks like it’s memorizing the data instead of learning it.

Model 1, in contrast, looks much simpler, and it gives us some interesting information. From the fact that most of the coefficients are zero, except those for movies 3, 7, and 9, it tells us that the only three movies that are related to movie 11 are those three movies. Furthermore, from the fact that the coefficients of movies 3 and 7 are positive, the model tells us that if a user watched movie 3 or movie 7, then they are likely to watch movie 11. Because the coefficient of movie 9 is negative, then if the user watched movie 9, they are not likely to watch movie 11.

Our goal is to have a model like model 1 and to avoid models like model 2. But unfortunately, if model 2 produces a smaller error than model 1, then running the linear regression algorithm will select model 2 instead. What can we do? Here is where regularization comes to the rescue. The first thing we need is a measure that tells us that model 2 is much more complex than model 1.

#### [](/book/grokking-machine-learning/chapter-4/)Measuring how complex a model is: L1 and L2 norm

In[](/book/grokking-machine-learning/chapter-4/)[](/book/grokking-machine-learning/chapter-4/)[](/book/grokking-machine-learning/chapter-4/)[](/book/grokking-machine-learning/chapter-4/) this section, we learn two ways to measure the complexity of a model. But before this, let’s look at models 1 and 2 from the previous section and try to come up with some formula that is low for model 1 and high for model 2.

Notice that a model with more coefficients, or coefficients of higher value, tends to be more complex. Therefore, any formula that matches this will work, such as the following:

- The sum of the absolute values of the coefficients
- The sum of the squares of the coefficients

The first one is called the *L1 norm*, and the second one is called the *L2 norm*. They come from a more general theory of *L*P spaces, named after the French mathematician Henri Lebesgue. We use absolute values and squares to get rid of the negative coefficients; otherwise, large negative numbers will cancel out with large positive numbers, and we may end up with a small value for a very complex model.

But before we start calculating the norms, a small technicality: the bias in the models is not included in the L1 and L2 norm. Why? Well, the bias in the model is precisely the number of seconds that we expect a user to watch movie 11 if they haven’t watched any of the previous 10 movies. This number is not associated with the complexity of the model; therefore, we leave it alone. The calculation of the L1 norm for models 1 and 2 follows.

Recall that the equations for the models are the following:

**Model 1**: *ŷ* = 2*x*3 + 1.4*x*7 – 0.5*x*7 + 8

**Model 2**: *ŷ* = 22*x*1 – 103*x*2 – 14*x*3 + 109*x*4 – 93*x*5 + 203*x*6 + 87*x*7 – 55*x*8 + 378*x*9 – 25*x*10 + 8

[](/book/grokking-machine-learning/chapter-4/)L1 norm:

- **Model 1**: |2| + |1.4| + |–0.5| = 3.9
- **Model 2**: |22| + |–103| + |–14| + |109| + |–93| + |203| + |87| + |–55| + |378| + |–25| = 1,089

L2 norm:

- **Model 1**: 22 + 1.42 + (–0.5)2 = 6.21
- **Model 2**: 222 + (–103)2 + (–14)2 + 1092 + (-93)2 + 2032 + 872 + (–55)2 + 3782 + (–25)2 = 227,131

As expected, both the L1 and L2 norms of model 2 are much larger than the corresponding norms of model 1.

The L1 and L2 norm can also be calculated on polynomials by taking either the sum of absolute values or the sum of squares of the coefficients, except for the constant coefficient. Let’s go back to the example at the beginning of this chapter, where our three models were a polynomial of degree 1 (a line), degree 2 (a parabola), and degree 10 (a curve that oscillates 9 times). Imagine that their formulas are the following:

- **Model 1**: *ŷ* = 2*x* + 3
- **Model 2**: *ŷ* = –*x*2 + 6*x* – 2
- **Model 3**: *ŷ* = *x*9 + 4*x*8 – 9*x*7 + 3*x*6 – 14*x*5 – 2*x*4 – 9*x*3 + *x*2 + 6*x* + 10

The L1 and L2 norms are calculated as follows:

L1 norm:

- **Model 1**: |2| = 2
- **Model 2**: |–1| + |6| = 7
- **Model 3**: |1| + |4| + |–9| + |3| + |–14| + |–2| + |–9| + |1| + |6| = 49

L2 norm:

- **Model 1**: 22 = 4
- **Model 2**: (–1)2 + 62 = 37
- **Model 3**: 12 + 42 + (–9)2 + 32 + (–14)2 + (–2)2 + (–9)2 + 12 + 62 = 425

Now that we are equipped with two ways to measure the complexity of the models, let’s embark into the training process.

#### [](/book/grokking-machine-learning/chapter-4/)Modifying the error function to solve our problem: Lasso regression and ridge regression

Now[](/book/grokking-machine-learning/chapter-4/)[](/book/grokking-machine-learning/chapter-4/)[](/book/grokking-machine-learning/chapter-4/)[](/book/grokking-machine-learning/chapter-4/)[](/book/grokking-machine-learning/chapter-4/)[](/book/grokking-machine-learning/chapter-4/) that we’ve done most of the heavy lifting, we’ll train a linear regression model using regularization. We have two measures for our model: a measure of performance (the error function) and a measure of complexity (the L1 or L2 norm).

Recall that in the roofer analogy, our goal was to find a roofer that provided both good quality and low complexity. We did this by minimizing the sum of two numbers: the measure of quality and the measure of complexity. Regularization consists of applying the same principle to our machine learning model. For this, we have two quantities: the regression error and the regularization term.

##### regression error

A measure of the quality of the model. In this case, it can be the absolute or square errors that we learned in chapter 3.

##### regularization term

A measure of the complexity of the model. It can be the L1 or the L2 norm of the model.

The quantity that we want to minimize to find a good and not too complex model is the modified error, defined as the sum of the two, as shown next:

Error = Regression error + Regularization term

Regularization is so common that the models themselves have different names based on what norm is used. If we train our regression model using the L1 norm, the model is called *lasso regression*. Lasso stands for “least absolute shrinkage and selection operator.” The error function follows:

Lasso regression error = Regression error + L1 norm

If, instead, we train the model using the L2 norm, it is called *ridge regression*. The name *ridge* comes from the shape of the error function, because adding the L2 norm term to the regression error function turns a sharp corner into a smooth valley when we plot it. The error function follows:

Ridge regression error = Regression error + L2 norm

Both lasso and ridge regression work well in practice. The decision of which one to use comes down to some preferences that we’ll learn about in the upcoming sections. But before we get to that, we need to work out some details to make sure our regularized models work well.

#### [](/book/grokking-machine-learning/chapter-4/)Regulating the amount of performance and complexity in our model: The regularization parameter

Because[](/book/grokking-machine-learning/chapter-4/)[](/book/grokking-machine-learning/chapter-4/)[](/book/grokking-machine-learning/chapter-4/)[](/book/grokking-machine-learning/chapter-4/) the process of training the model involves reducing the cost function as much as possible, a model trained with regularization, in principle, should have high performance and low complexity. However, there is some tug-of-war—trying to make the model perform better may make it more complex, whereas trying to reduce the complexity of the model may make it perform worse. Fortunately, most machine learning techniques come with knobs (hyperparameters) for the data scientist to turn and build the best possible models, and regularization is not an exception. In this section, we see how to use a hyperparameter to regulate between performance and complexity.

This hyperparameter is called the *regularization parameter*, and its goal is to determine if the model-training process should emphasize performance or simplicity. The regularization parameter is denoted by λ, the Greek letter *lambda**[](/book/grokking-machine-learning/chapter-4/)*. We multiply the regularization term by λ, add it to the regression error, and use that result to train our model. The new error becomes the following:

Error = Regression error + λ Regularization term

Picking a value of 0 for λ cancels out the regularization term, and thus we end up with the same regression model we had in chapter 3. Picking a large value for λ results in a simple model, perhaps of low degree, which may not fit our dataset very well. It is crucial to pick a good value for λ, and for this, validation is a useful technique. It is typical to choose powers of 10, such as 10, 1, 0.1, 0.01, but this choice is somewhat arbitrary. Among these, we select the one that makes our model perform best in our validation set.

#### [](/book/grokking-machine-learning/chapter-4/)Effects of L1 and L2 regularization in the coefficients of the model

In[](/book/grokking-machine-learning/chapter-4/)[](/book/grokking-machine-learning/chapter-4/)[](/book/grokking-machine-learning/chapter-4/)[](/book/grokking-machine-learning/chapter-4/) this section, we see crucial differences between L1 and L2 regularization and get some ideas about which one to use in different scenarios. At first glance, they look similar, but the effects they have on the coefficients is interesting, and, depending on what type of model we want, deciding between using L1 and L2 regularization can be critical.

Let’s go back to our movie recommendation example, where we are building a regression model to predict the amount of time (in seconds) that a user will watch a movie, given the time that same user has watched 10 different movies. Imagine that we’ve trained the model, and the equation we get is the following:

**Model**: *ŷ* = 22*x*1 – 103*x*2 – 14*x*3 + 109*x*4 – 93*x*5 + 203*x*6 + 87*x*7 – 55*x*8 + 378*x*9 – 25*x*10 + 8

If we add regularization and train the model again, we end up with a simpler model. The following two properties can be shown mathematically:

- If we use L1 regularization (lasso regression), you end up with a model with fewer coefficients. In other words, L1 regularization turns some of the coefficients into zero. Thus, we may end up with an equation like *ŷ* = 2*x*3 + 1.4*x*7 – 0.5*x*9 + 8.
- If we use L2 regularization (ridge regression), we end up with a model with smaller coefficients. In other words, L2 regularization shrinks all the coefficients but rarely turns them into zero. Thus, we may end up with an equation like *ŷ* = 0.2*x*1 – 0.8*x*2 – 1.1*x*3 + 2.4*x*4 – 0.03*x*5 + 1.02*x*6 + 3.1*x*7 – 2*x*8 + 2.9*x*9 – 0.04*x*10 + 8.

Thus, depending on what kind of equation we want to get, we can decide between using L1 and L2 regularization.

A quick rule of thumb to use when deciding if we want to use L1 or L2 regularization follows: if we have too many features and we’d like to get rid of most of them, L1 regularization is perfect for that. If we have only few features and believe they are all relevant, then L2 regularization is what we need, because it won’t get rid of our useful features.

An example of a problem in which we have many features and L1 regularization can help us is the movie recommendation system we studied in the section “Another example of overfitting: Movie recommendations.” In this model, each feature corresponded to one of the movies, and our goal is to find the few movies that were related to the one we’re interested in. Thus, we need a model for which most of the coefficients are zero, except for a few of them.

An example in which we should use L2 regularization is the polynomial example at the beginning of the section “An example of underfitting using polynomial regression.” For this model, we had only one feature: *x*. L2 regularization would give us a good polynomial model with small coefficients, which wouldn’t oscillate very much and, thus, is less prone to overfitting. In the section “Polynomial regression, testing, and regularization with Turi Create,” we will see a polynomial example for which L2 regularization is the right one to use.

The resources corresponding to this chapter (appendix C) point to some places where you can dig deeper into the mathematical reasons why L1 regularization turns coefficients into zero, whereas L2 regularization turns them into small numbers. In the next section, we will learn how to get an intuition for it.

#### [](/book/grokking-machine-learning/chapter-4/)An intuitive way to see regularization

In[](/book/grokking-machine-learning/chapter-4/)[](/book/grokking-machine-learning/chapter-4/)[](/book/grokking-machine-learning/chapter-4/) this section, we learn how the L1 and L2 norms differ in the way they penalize complexity. This section is mostly intuitive and is developed in an example, but if you’d like to see the formal mathematics behind them, please look at appendix B, “Using gradient descent for regularization.”

When we try to understand how a machine learning model operates, we should look beyond the error function. An error function says, “This is the error, and if you reduce it, you end up with a good model.” But that is like saying, “The secret to succeeding in life is to make as few mistakes as possible.” Isn’t a positive message better, such as, “These are the things you can do to improve your life,” as opposed to “These are the things you should avoid”? Let’s see regularization in this way.

In chapter 3, we learned the absolute and the square tricks, which give us a clearer glimpse into regression. At each stage in the training process, we simply pick a point (or several points) and move the line closer to those points. Repeating this process many times will eventually yield a good line fit. We can be more specific and repeat how we defined the linear regression algorithm in chapter 3.

#### Pseudocode for the linear regression algorithm

**Inputs**: A dataset of points

**Outputs**: A linear regression model that fits that dataset

Procedure:

- Pick a model with random weights and a random bias.
- Repeat many times:

- Pick a random data point.
- Slightly adjust the weights and bias to improve the prediction for that data point.

- Enjoy your model!

Can we use the same reasoning to understand regularization? Yes, we can.

To simplify things, let’s say that we are in the middle of our training, and we want to make the model simpler. We can do this by reducing the coefficients. For simplicity, let’s say that our model has three coefficients: 3, 10, and 18. Can we take a small step to decrease these three by a small amount? Of course we can, and here are two methods to do it. Both require a small number, λ, which we’ll set to 0.01 for now.

**Method 1**: Subtract λ from each of the positive parameters, and add λ to each of the negative parameters. If they are zero, leave them alone.

**Method 2**: Multiply all of them by 1 – λ. Notice that this number is close to 1, because λ is small.

Using method 1, we get the numbers 2.99, 9.99, and 17.99.

Using method 2, we get the numbers 2.97, 9.9, and 17.82.

In this case, λ behaves very much like a learning rate. In fact, it is closely related to the regularization rate (see “Using gradient descent for regularization” in appendix B for details). Notice that in both methods, we are shrinking the size of the coefficients. Now, all we have to do is to repeatedly shrink the coefficients at every stage of the algorithm. In other words, here is how we train the model now:

**Inputs**: A dataset of points

**Outputs**: A linear regression model that fits that dataset

Procedure:

- Pick a model with random weights and a random bias.
- Repeat many times:

- Pick a random data point.
- Slightly adjust the weights and bias to improve the prediction for that particular data point.
- **Slightly shrink the coefficients using method 1 or method 2**.

- Enjoy your model!

If we use method 1, we are training the model with L1 regularization, or lasso regression. If we use method 2, we are training it with L2 regularization, or ridge regression. There is a mathematical justification for this, which is described in appendix B, “Using gradient descent for regularization.”

In the previous section, we learned that L1 regularization tends to turn many coefficients into 0, whereas L2 regularization tends to decrease them but not turn them into zero. This phenomenon is now easier to see. Let’s say that our coefficient is 2, with a regularization parameter of λ = 0.01. Notice what happens if we use method 1 to shrink our coefficient, and we repeat this process 200 times. We get the following sequence of values:

2 → 1.99 → 1.98 → ··· → 0.02 → 0.01 → 0

After 200 epochs of our training, the coefficient becomes 0, and it never changes again. Now let’s see what would happen if we apply method 2, again 200 times and with the same learning rate of *η* = 0.01. We get the following sequence of values:

2 → 1.98 → 1.9602 → ··· → 0.2734 → 0.2707 → 0.2680

Notice that the coefficient decreased dramatically, but it didn’t become zero. In fact, no matter how many epochs we run, the coefficient will never become zero. This is because when we multiply a non-negative number by 0.99 many times, the number will never become zero. This is illustrated in figure 4.7.

![Figure 4.7 Both L1 and L2 shrink the size of the coefficient. L1 regularization (left) does it much faster, because it subtracts a fixed amount, so it is likely to eventually become zero. L2 regularization takes much longer, because it multiplies the coefficient by a small factor, so it never reaches zero.](https://drek4537l1klr.cloudfront.net/serrano/Figures/4-7.png)

## [](/book/grokking-machine-learning/chapter-4/)Polynomial regression, testing, and regularization with Turi Create

In[](/book/grokking-machine-learning/chapter-4/)[](/book/grokking-machine-learning/chapter-4/)[](/book/grokking-machine-learning/chapter-4/) this section, we see an example of polynomial regression with regularization in Turi Create. Here is the code for this section:

-  **Notebook**:

- [https://github.com/luisguiserrano/manning/blob/master/Chapter_4_Testing_Overfitting_Underfitting/Polynomial_regression_regularization.ipynb](https://github.com/luisguiserrano/manning/blob/master/Chapter_4_Testing_Overfitting_Underfitting/Polynomial_regression_regularization.ipynb)

We start with our dataset, which is illustrated in figure 4.8. We can see the curve that best fits this data is a parabola that opens downward (a sad face). Therefore, it is not a problem we can solve with linear regression—we must use polynomial regression. The dataset is stored in an SFrame called `data`, and the first few rows are shown in table 4.1.

![Figure 4.8 The dataset. Notice that its shape is a parabola that opens downward, so using linear regression won’t work well. We’ll use polynomial regression to fit this dataset, and we’ll use regularization to tune our model.](https://drek4537l1klr.cloudfront.net/serrano/Figures/4-8.png)

##### Table 4.1 The first four rows of our dataset[(view table figure)](https://drek4537l1klr.cloudfront.net/serrano/HighResolutionFigures/table_4-1.png)

| *x* | *y* |
| --- | --- |
| 3.4442185152504816 | 6.685961311021467 |
| -2.4108324970703663 | 4.690236225597948 |
| 0.11274721368608542 | 12.205789026637378 |
| -1.9668727392107255 | 11.133217991032268 |

The way to do polynomial regression in Turi Create is to add many columns to our dataset, corresponding to the powers of the main feature, and to apply linear regression to this expanded dataset. If the main feature is, say, *x*, then we add columns with the values of *x*2, *x*3, *x*4, and so on. Thus, our model is finding linear combinations of the powers of *x*, which are precisely polynomials in *x*. If the SFrame containing our data is called `data`, we use the following code to add columns for powers up to *x*199. The first few rows and columns of the resulting dataset appear in table 4.2.

```
for i in range(2,200):
   string = 'x^'+str(i)
   data[string] = data['x'].apply(lambda x:x**i)
```

##### Table 4.2 The top four rows and the leftmost five columns of our dataset. The column labeled *x*^*k* corresponds to the variable *x*^*k*, for *k* = 2, 3, and 4. The dataset has 200 columns.[(view table figure)](https://drek4537l1klr.cloudfront.net/serrano/HighResolutionFigures/table_4-2.png)

| x* * | y | x^2 | x^3 | x^4 |
| --- | --- | --- | --- | --- |
| 3.445 | 6.686 | 11.863 | 40.858 | 140.722 |
| –2.411 | 4.690 | 5.812 | –14.012 | 33.781 |
| 0.113 | 12.206 | 0.013 | 0.001 | 0.000 |
| –1.967 | 11.133 | 3.869 | –7.609 | 14.966 |

[](/book/grokking-machine-learning/chapter-4/)Now, we apply linear regression to this large dataset with 200 columns. Notice that a linear regression model in this dataset looks like a linear combination of the variables in the columns. But because each column corresponds to a monomial, then the model obtained looks like a polynomial on the variable *x*.

Before we train any models, we need to split the data into training and testing datasets, using the following line of code:

```
train, test = data.random_split(.8)
```

Now our dataset is split into two datasets, the training set called *train* and the testing set called *test*. In the repository, a random seed is specified, so we always get the same results, although this is not necessary in practice.

The way to use regularization in Turi Create is simple: all we need to do is specify the parameters `l1_penalty``` and `l2_penalty``` in the `create` method[](/book/grokking-machine-learning/chapter-4/) when we train the model. This penalty is precisely the regularization parameter we introduced in the section “Regulating the amount of performance and complexity in our model.” A penalty of 0 means we are not using regularization. Thus, we will train three different models with the following parameters:

- No regularization model:

- `l1_penalty=0`
- `l2_penalty=0`

- L1 regularization model:

- `l1_penalty=0.1`
- `l2_penalty=0`

- L2 regularization model:

- `l1_penalty=0`
- `l2_penalty=0.1`

We train the models with the following three lines of code:

```
model_no_reg = tc.linear_regression.create(train, target='y', l1_penalty=0.0, l2_penalty=0.0)
model_L1_reg = tc.linear_regression.create(train, target='y', l1_penalty=0.1, l2_penalty=0.0)
model_L2_reg = tc.linear_regression.create(train, target='y', l1_penalty=0.0, l2_penalty=0.1)
```

The first model uses no regularization, the second one uses L1 regularization with a parameter of 0.1, and the third uses L2 regularization with a parameter of 0.1. The plots of the resulting functions are shown in figure 4.9. Notice that in this figure, the points in the training set are circles, and those in the testing set are triangles.

![Figure 4.9 Three polynomial regression models for our dataset. The model on the left has no regularization, the model in the middle has L1 regularization with a parameter of 0.1, and the model on the right has L2 regularization with a parameter of 0.1.](https://drek4537l1klr.cloudfront.net/serrano/Figures/4-9.png)

Notice that the model with no regularization fits the training points really well, but it’s chaotic and doesn’t fit the testing points well. The model with L1 regularization does OK with both the training and the testing sets. But the model with L2 regularization does a wonderful job with both the training and the testing sets and also seems to be the one that really captures the shape of the data.

Also note that for the three models, the boundary curve goes a bit crazy on the end points. This is completely understandable, because the endpoints have less data, and it is natural for the model to not know what to do when there’s no data. We should always evaluate models by how well they perform inside the boundaries of our dataset, and we should never expect a model to do well outside of those boundaries. Even we humans may not be able to make good predictions outside of the boundaries of the model. For instance, how do you think this curve would look outside of the dataset? Would it continue as parabola that opens downward? Would it oscillate forever like a sine function? If we don’t know this, we shouldn’t expect the model to know it. Thus, try to ignore the strange behavior at the end points in figure 4.9, and focus on the behavior of the model inside the interval where the data is located.

To find the testing error, we use the following line of code, with the corresponding name of the model. This line of code returns the maximum error and the root mean square error (RMSE[](/book/grokking-machine-learning/chapter-4/)).

```
model.predict(test)
```

The testing RMSE for the models follow:

- Model with no regularization: 699.03
- Model with L1 regularization: 10.08
- Model with L2 regularization: 3.41

The model with no regularization had a really large RMSE! Among the other two models, the one with L2 regularization performed much better. Here are two questions to think about:

1. Why did the model with L2 regularization perform better than the one with L1 regularization?
1. Why does the model with L1 regularization look flat, whereas the model with L2 regularization managed to capture the shape of the data?

The two questions have a similar answer, and to find it, we can look at the coefficients of the polynomials. These can be obtained with the following line of code:

```
model.coefficients
```

Each polynomial has 200 coefficients, so we won’t display all of them here, but in table 4.3 you can see the first five coefficients for the three models. What do you notice?

##### Table 4.3 The first five coefficients of the polynomials in our three models. Note that the model with no regularization has large coefficients, the model with L1 regularization has coefficients very close to 0, and the model with L2 regularization has small coefficients.[(view table figure)](https://drek4537l1klr.cloudfront.net/serrano/HighResolutionFigures/table_4-3.png)

| Coefficient | model_no_reg | model_L1_reg | model_L2_reg |
| --- | --- | --- | --- |
| *x*0 = 1 | 8.41 | 0.57 | 13.24 |
| *x*1 | 15.87 | 0.07 | 0.87 |
| *x*2 | 108.87 | –0.004 | –0.52 |
| *x*3 | –212.89 | 0.0002 | 0.006 |
| *x*4 | –97.13 | –0.0002 | –0.02 |

To interpret table 4.3, we see the predictions for the three models are polynomials of degree 200. The first terms look as follows:

- Model with no regularization: *ŷ* = 8.41 + 15.87*x* + 108.87*x*2 – 212.89*x*3 – 97.13*x*4 + …
- Model with L1 regularization: *ŷ* = 0.57 + 0.07*x* – 0.004*x*2 + 0.0002*x*3 – 0.0002*x*4 + …
- Model with L2 regularization: *ŷ* = 13.24 + 0.87*x* – 0.52*x*2 + 0.006*x*3 – 0.02*x*4 + …

From these polynomials, we see the following:

- For the model with no regularization, all the coefficients are large. This means the polynomial is chaotic and not good for making predictions.
- For the model with L1 regularization, all the coefficients, except for the constant one (the first one), are tiny—almost 0. This means that for the values close to zero, the polynomial looks a lot like the horizontal line with equation *ŷ* = 0.57. This is better than the previous model but still not great for making predictions.
- For the model with L2 regularization, the coefficients get smaller as the degree grows but are still not so small. This gives us a decent polynomial for making predictions.

## [](/book/grokking-machine-learning/chapter-4/)Summary

- When it comes to training models, many problems arise. Two problems that come up quite often are underfitting and overfitting.
- Underfitting occurs when we use a very simple model to fit our dataset. Overfitting occurs when we use an overly complex model to fit our dataset.
- An effective way to tell overfitting and underfitting apart is by using a testing dataset.
- To test a model, we split the data into two sets: a training set and a testing set. The training set is used to train the model, and the testing set is used to evaluate the model.
- The golden rule of machine learning is to never use our testing data for training or making decisions in our models.
- The validation set is another portion of our dataset that we use to make decisions about the hyperparameters in our model.
- A model that underfits will perform poorly in the training set and in the validation set. A model that overfits will perform well in the training set but poorly in the validation set. A good model will perform well on both the training and the validation sets.
- The model complexity graph is used to determine the correct complexity of a model, so that it doesn’t underfit or overfit.
- Regularization is a very important technique to reduce overfitting in machine learning models. It consists of adding a measure of complexity (regularization term) to the error function during the training process.
- The L1 and L2 norms are the two most common measures of complexity used in regularization.
- Using the L1 norm leads to L1 regularization, or lasso regression. Using the L2 norm leads to L2 regularization, or ridge regression.
- L1 regularization is recommended when our dataset has numerous features, and we want to turn many of them into zero. L2 regularization is recommended when our dataset has few features, and we want to make them small but not zero.

## [](/book/grokking-machine-learning/chapter-4/)Exercises

#### Exercise 4.1

We have trained four models in the same dataset with different hyperparameters. In the following table we have recorded the training and testing errors for each of the models.

| Model | Training error | Testing error |
| --- | --- | --- |
| 1 | 0.1 | 1.8 |
| 2 | 0.4 | 1.2 |
| 3 | 0.6 | 0.8 |
| 4 | 1.9 | 2.3 |

1. Which model would you select for this dataset?
1. Which model looks like it’s underfitting the data?
1. Which model looks like it’s overfitting the data?

#### Exercise 4.2

We are given the following dataset:

| *x* | *y* |
| --- | --- |
| 1 | 2 |
| 2 | 2.5 |
| 3 | 6 |
| 4 | 14.5 |
| 5 | 34 |

We train the polynomial regression model that predicts the value of *y* as *ŷ*, where

*ŷ* = 2*x*2 – 5*x* + 4.

If the regularization parameter is λ = 0.1 and the error function we’ve used to train this dataset is the mean absolute value (MAE), determine the [](/book/grokking-machine-learning/chapter-4/)[](/book/grokking-machine-learning/chapter-4/)following:

1. The lasso regression error of our model (using the L1 norm)
1. The ridge regression error of our model (using the L2 norm)
