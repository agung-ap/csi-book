# [](/book/grokking-machine-learning/appendix-b/)Appendix B. The math behind gradient descent: Coming down a mountain using derivatives and slopes

In this[](/book/grokking-machine-learning/appendix-b/) appendix, we’ll go over the mathematical details of gradient descent. This appendix is fairly technical, and understanding it is not required to follow the rest of the book. However, it is here to provide a sense of completeness for the readers who wish to understand the inner workings of some of the core machine learning algorithms. The mathematics knowledge required for this appendix is higher than for the rest of the book. More specifically, knowledge of vectors, derivatives, and the chain rule is required.

In chapters 3, 5, 6, 10, and 11, we used gradient descent to minimize the error functions in our models. More specifically, we used gradient descent to minimize the following error functions:

- Chapter 3: the absolute and square error functions in a linear regression model
- Chapter 5: the perceptron error function in a perceptron model
- Chapter 6: the log loss in a logistic classifier
- Chapter 10: the log loss in a neural network
- Chapter 11: the classification (perceptron) error and the distance (regularization) error in an SVM

As we learned in chapters 3, 5, 6, 10, and 11, the error function measures how poorly the model is doing. Thus, finding the minimum value for this error function—or at least a really small value, even if it’s not the minimum—will be instrumental in finding a good model.

The analogy we used was that of descending a mountain—Mount Errorest, shown in figure B.1. The scenario is the following: You are somewhere on top of a mountain, and you’d like to get to the bottom of this mountain. It is very cloudy, so you can’t see far around you. The best bet you can have is to descend from the mountain one step at a time. You ask yourself , “If I were to take only one step, in which direction should I take it to descend the most?” You find that direction and take that step. Then you ask the same question again, and take another step, and you repeat the process many times. It is imaginable that if you always take the one step that helps you descend the most, that you must get to a low place. You may need a bit of luck to actually get to the bottom of the mountain, as opposed to getting stuck in a valley, but we’ll deal with this later in the section “Getting stuck on local minima.”

![Figure B.1 In the gradient descent step, we want to descend from a mountain called Mount Errorest.](https://drek4537l1klr.cloudfront.net/serrano/Figures/B-1.png)

Throughout the following sections we’ll describe the mathematics behind gradient descent and use it to help us train several machine learning algorithms by decreasing their error functions.

## [](/book/grokking-machine-learning/appendix-b/)Using gradient descent to decrease functions

The[](/book/grokking-machine-learning/appendix-b/) mathematical formalism of gradient descent follows: say you want to minimize the function *f*(*x*1, *x*2, …, *x*n) on the *n* variables *x*1, *x*2, …, *x*n. We assume the function is continuous and differentiable over each of the *n* variables.

We are currently standing at the point *p* with coordinates (*p*1, *p*2, …, *p*n), and we wish to find the direction in which the function decreases the most, in order to take that step. This is illustrated in figure B.2. To find the direction in which the function decreases the most, we use the *gradient* of the function. The gradient is the *n*-dimensional vector formed by the partial derivatives of *f* with respect to each of the variables *x*1, *x*2, …, *x*n. This gradient is denoted as ∇*f*, as follows:

The gradient is a vector that points in the direction of greatest growth, namely, the direction in which the function *increases* the most. Thus, the negative of the gradient is the direction in which the function *decreases* the most. This is the step we want to take. We determine the size of the step using the *learning rate**[](/book/grokking-machine-learning/appendix-b/)* we learned in chapter 3 and which we denote with *η*. The gradient descent step consists of taking a step of length *η*|∇*f|* in the direction of the negative of the gradient ∇*f*. Thus, if our original point was *p*, after applying the gradient descent step, we obtain the point *p* – *η*∇*f*. Figure B.2 illustrates the step that we’ve taken to decrease the function *f*.

![Figure B.2 We were originally at the point p. We take a step in the direction of the negative of the gradient and end up at a new point. This is the direction in which the function decreases the most. (Source: Image created with the assistance of Grapher™ from Golden Software, LLC; https://www.goldensoftware.com/products/grapher).](https://drek4537l1klr.cloudfront.net/serrano/Figures/B-2.png)

[](/book/grokking-machine-learning/appendix-b/)Now that we know how to take one step to slightly decrease the function, we can simply repeat this process many times to minimize our function. Thus, the pseudocode of the gradient descent algorithm is the following:

#### Pseudocode for the gradient descent algorithm

**Goal**: To minimize the function *f*.

Hyperparameters:

- Number of epochs (repetitions) *N*
- Learning rate *η*

Process:

- Pick a random point *p*0.
- For *i* = 0, …, *N* – 1:

- – Calculate the gradient ∇*f*(*p*i).
- – Pick the point *p*i+1 = *p*i – *η*∇*f*(*p*i).

- End with the point *p*n.

![Figure B.3 If we repeat the gradient descent step many times, we have a high chance of finding the minimum value of the function. In this figure, p1 represents the starting point and pn the point we have obtained using gradient descent. (Source: Image created with the assistance of Grapher™ from Golden Software, LLC; https://www.goldensoftware.com/products/grapher).](https://drek4537l1klr.cloudfront.net/serrano/Figures/B-3.png)

Does this process *always* find the minimum of the function? Unfortunately, no. Several problems may occur when trying to minimize a function using gradient descent, such as getting stuck at a local minimum (a valley). We’ll learn a very useful technique to deal with this problem in the section “Getting stuck on local minima.”

## [](/book/grokking-machine-learning/appendix-b/)Using gradient descent to train models

Now[](/book/grokking-machine-learning/appendix-b/)[](/book/grokking-machine-learning/appendix-b/) that we know how gradient descent helps us minimize (or at least, find small values for) a function, in this section we see how to use it to train some machine learning models. The models we’ll train follow:

- Linear regression (from chapter 3).
- Perceptron (from chapter 5).
- Logistic classifier (from chapter 6).
- Neural network (from chapter 10).
- Regularization (from chapters 4 and 11). This one is not a model, but we can still see the effects that a gradient descent step has on a model that uses regularization.

The way we use gradient descent to train a model is by letting *f* be the corresponding error function of the model and using gradient descent to minimize *f*. The value of the error function is calculated over the dataset. However, as we saw in the sections “Do we train using one point at a time or many” in chapter 3, “Stochastic, mini-batch, and batch gradient descent” in chapter 6, and “Hyperparameters” in chapter 10, if the dataset is too large, we can speed up training by splitting the dataset into mini-batches of (roughly) the same size and, at each step, picking a different mini-batch on which to calculate the error function.

Here is some notation we’ll use in this appendix. Most of the terms have been introduced in chapters 1 and 2:

- The **size** of the dataset, or the number of rows, is *m*.
- The **dimension** of the dataset, or number of columns, is *n*.
- The dataset is formed by **features** and **labels**.
- The **features** are the *m* vectors *x*i = (*x*1(i), *x*2(i), …, *x*n(i)) for *i* = 1, 2, …, *m*.
- The **labels** *y*i, for *i* = 1, 2, …, *m*.
- The **model** is given by the vector of *n* weights *w* = (*w*1, *w*2, …, *w*n) and the bias *b* (a scalar) (except when the model is a neural network, which will have more weights and biases).
- The **predictions** *ŷ*, for *i* = 1, 2, …, *m*.
- The **learning rate** of the model is *η*.
- The **mini-batches** of data are *B*1, *B*2, …, *B*l, for some number *l*. Each mini-batch has length *q*. The points in one mini-batch (for notational convenience) are denoted *x*(1), …, *x*(q), and the labels are *y*1, …, *y*q.

The gradient descent algorithm that we’ll use for training models follows:

#### Gradient descent algorithm for training machine learning models

Hyperparameters:

- Number of epochs (repetitions) *N*
- Learning rate *η*

Process:

- Pick random weights *w*1, *w*2, …, *w*n and a random bias *b*.
- For *i* = 0, …, *N* – 1:

- For each of the mini-batches *B*1, *B*2, …, *B*l.

- Calculate the error function *f*(*w, b*) on that particular mini-batch.
- Calculate the gradient
- Replace the weights and bias as follows:

- *w*1 gets replaced by
- *b* gets replaced by

Throughout the following subsections, we will perform this process in detail for each of the following models and error functions:

- Linear regression model with the mean absolute error function (the following section)
- Linear regression model with the mean square error function (the following section)
- Perceptron model with the perceptron error function (the section “Using gradient descent to train classification models”)
- Logistic regression model with the log loss function (the section “Using gradient descent to train classification models”)
- Neural network with the log loss function (the section “Using gradient descent to train neural networks”)
- Models with regularization (the section “Using gradient descent for regularization”)

#### [](/book/grokking-machine-learning/appendix-b/)Using gradient descent to train linear regression models

In[](/book/grokking-machine-learning/appendix-b/)[](/book/grokking-machine-learning/appendix-b/)[](/book/grokking-machine-learning/appendix-b/) this section, we use gradient descent to train a linear regression model, using both of the error functions we’ve learned previously: the mean absolute error and the mean square error. Recall from chapter 3 that in linear regression, the predictions *ŷ*1,*ŷ*1, … , *ŷ*q are given by the following formula:

The goal of our regression model is to find the weights *w*1, …, *w*n, which produce predictions that are really close to the labels. Thus, the error function helps by measuring how far *ŷ* is from *y* for a particular set of weights. As we’ve seen in sections “The absolute error” and “The square error” in chapter 3, we have two different ways to calculate this distance. The first is the absolute value |*ŷ* – *y*|, and the second one is the square of the difference (*y* – *ŷ*)2. The first one gives rise to the mean absolute error, and the second one to the mean square error. Let’s study them separately.

#### Training a linear regression model using gradient descent to reduce the mean absolute error

In[](/book/grokking-machine-learning/appendix-b/)[](/book/grokking-machine-learning/appendix-b/) this subsection, we’ll calculate the gradient of the mean absolute error function and use it to apply gradient descent and train a linear regression model. The mean absolute error is a way to tell how far apart *ŷ* and *y* are. It was first defined in the section “The absolute error” in chapter 3, and its formula follows:

For convenience, we’ll abbreviate *MAE*(*w, b, x*, *y*) as *MAE*. To use gradient descent to reduce *MAE*, we need to calculate the gradient ∇*MAE*, which is the vector containing the *n* + 1 partial derivatives of *MAE* with respect to *w*1, …, *w*n, *b*,

We’ll calculate these partial derivatives using the chain rule. First, notice that

The derivative of *f*(*x*) = |*x*| is the sign function , which is +1 when *x* is positive and –1 when x is negative (it is undefined at 0, but for convenience we can define it to be 0). Thus, we can rewrite the previous equation as

To calculate this value, let’s focus on the final part of the equation, namely, the . Since , then

.

This is because the derivative of *w*j with respect to *w*i, is 1 if *j* = *i* and 0 otherwise. Thus, replacing on the derivative, we get the following:

Using a similar analysis, we can calculate the derivative of *MAE*(*w*, *b*) with respect to *b* to be

The gradient descent step is the following:

#### Gradient descent step:

Replace (*w*, *b*) by (*w**'*, *b**'*), where

Notice something interesting: if the mini-batch has size *q* = 1 and consists only of the point *x* = (*x*1, *x*2, …, *x*n) with label *y* and prediction *ŷ*, then the step is defined as follows:

Replace (*w*, *b*) by (*w**'*, *b**'*), where

- *w*j' = *w*j + *η* sgn(*y* – *ŷ*)*x*j
- *b*' = *b* + *η* sgn(*y* – *ŷ*)

This is precisely the simple trick we used in the section “The simple trick” in chapter 3 to train our linear regression algorithm.

#### Training a linear regression model using gradient descent to reduce the mean square error

In[](/book/grokking-machine-learning/appendix-b/)[](/book/grokking-machine-learning/appendix-b/)[](/book/grokking-machine-learning/appendix-b/) this subsection, we’ll calculate the gradient of the mean square error function and use it to apply gradient descent and train a linear regression model. The mean square error is another way to tell how far apart *ŷ* and *y* are. It was first defined in the section “The square error” in chapter 3 and its formula is

For convenience, we’ll abbreviate *MSE*(*w, b, x*, *y*) as *MSE*. To calculate the gradient ∇*MSE*, we can follow the same procedure as we did for the mean absolute error described earlier, with the exception that the derivative of *f*(*x*) = *x*2 is 2*x*. Therefore, the derivative of *MSE* with respect to *w*j is

Similarly, the derivative of *MSE*(*w*, *b*) with respect to *b* is

#### Gradient descent step:

Replace (*w*, *b*) by (*w**'*, *b**'*), where

Notice again that if the mini-batch has size *q =* 1 and consists only of the point *x* = (*x*1, *x*2, …, *x*n) with label *y* and prediction *ŷ*, then the step is defined as follows:

Replace (*w*, *b*) by (*w**'*, *b**'*), where

- *w*j' = *w*j + *η*(*y* – *ŷ*)*x*j

- *b**'* = *b* + *η*(*y* – *ŷ*)

This is precisely the square trick we used in the section “The square trick” in chapter 3 to train our linear regression algorithm.

#### [](/book/grokking-machine-learning/appendix-b/)Using gradient descent to train classification models

In[](/book/grokking-machine-learning/appendix-b/)[](/book/grokking-machine-learning/appendix-b/)[](/book/grokking-machine-learning/appendix-b/) this section we learn how to use gradient descent to train classification models. The two models that we’ll train are the perceptron model (chapter 5) and the logistic regression model (chapter 6). Each one of them has its own error function, so we will develop them separately.

#### Training a perceptron model using gradient descent to reduce the perceptron error

In[](/book/grokking-machine-learning/appendix-b/)[](/book/grokking-machine-learning/appendix-b/) this subsection, we’ll calculate the gradient of the perceptron error function and use it to apply gradient descent and train a perceptron model. In the perceptron model, the predictions are *ŷ*1*,* *ŷ*2*, …,* *ŷ*q where each *ŷ*i is 0 or 1. To calculate the predictions, we first need to remember the step function *step*(*x*), introduced in chapter 5. This function takes as an input any real number *x* and outputs 0 if *x* < 0 and 1 if *x* ≥ 0. Its graph is shown in figure B.4.

![Figure B.4 The step function. For negative numbers it outputs 0, and for non-negative numbers it outputs 1.](https://drek4537l1klr.cloudfront.net/serrano/Figures/B-41.png)

The model gives each point a *score**[](/book/grokking-machine-learning/appendix-b/)*. The score that the model with weights (*w*1, *w*2, …, *w*n) and bias *b* gives to the point *x*(i) = (*x*1(i), *x*n(i), …, *x*n(i)) is

The predictions *ŷ*i are given by the following formula:

In other words, the prediction is 1 if the score is positive, and 0 otherwise.

The perceptron error function is called *PE*(*w, b, x*, *y*), which we’ll abbreviate as *PE*. It was first defined in the section “How to compare classifiers? The error function” in chapter 5. By construction, it is a large number if the model made a bad prediction, and a small number (in this case, actually 0) if the model made a good prediction. The error function is defined as follows.

- *PE*(*w, b, x, y*) = 0 if *ŷ* = *y*
- *PE*(*w, b, x*, *y*) = |*score*(*w, b, x*)| if *ŷ* *≠* *y*

In other words, if the point is correctly classified, the error is zero. If the point is incorrectly classified, the error is the absolute value of the score. Thus, misclassified points with scores of low absolute value produce a low error, and misclassified points with scores of high absolute value produce a high error. This is because the absolute value of the score of a point is proportional to the distance between that point and the boundary. Thus, the points with low error are points that are close to the boundary, whereas points with high error are far from the boundary.

To calculate the gradient ∇*PE*, we can use the same rule as before. One thing we should notice is that the derivative of the absolute value function |*x*| is 1 when *x* ≥ 0 and 0 when *x* < 0. This derivative is undefined at 0, which is a problem with our calculations, but in practice, we can arbitrarily define it as 1 without any problems.

In chapter 10, we introduced the *ReLU*(*x*) (rectified linear unit) function, which is 0 when *x* < 0 and *x* when *x* ≥ 0. Notice that there are two ways in which a point can be misclassified:

- If *y* = 0 and *ŷ* = 1. This means *score*(*w, b, x*) ≥ 0.
- If *y* = 1 and *ŷ* = 0. This means *score*(*w, b, x*) < 0.

Thus, we can conveniently rewrite the perceptron error as

or in more detail, as

Now we can proceed to calculate the gradient ∇*PE* using the chain rule. An important observation that we’ll use and that the reader can verify is that the derivative of *ReLU*(*x*) is the step function *step*(*x*). This gradient is

which we can rewrite as

This looks complicated, but it’s actually not that hard. Let’s analyze each summand from the right-hand side of the previous expression. Notice that *step*(*score*(*w, b, x*)) is 1 if and only if *score*(*w, b, x*) > 0, and otherwise, it is 0. This is precisely when *ŷ* = 1. Similarly, *step*(–*score*(*w, b, x*)) is 1 if and only if *score*(*w, b, x*) < 0, and otherwise, it is 0. This is precisely when *ŷ* = 0. Therefore

- If *ŷ*i = 0 and *y*i = 0:

−*y*i *x*j(i)) *step*(−*score*(*w, b, x*)) + (1 − *y*i) *x*j(i) *step*(*score*(*w, b, x*)) = 0

- If *ŷ*i = 1 and *y*i = 1:

−*y*i *x*j(i)) *step*(−*score*(*w, b, x*)) + (1 − *y*i) *x*j(i) *step*(*score*(*w, b, x*)) = 0

- If *ŷ*i = 0 and *y*i = 1:

−*y*i *x*j(i)) *step*(−*score*(*w, b, x*)) + (1 − *y*i) *x*j(i) *step*(*score*(*w, b, x*)) = −*x*j(i))

- If *ŷ*i = 1 and *y*i = 0:

−*y*i *x*j(i)) *step*(−*score*(*w, b, x*)) + (1 − *y*i) *x*j(i) *step*(*score*(*w, b, x*)) = *x*j(i))

This means that when calculating ∂*PE*/∂*x*j, only the summands coming from misclassified points will add value.

In a similar manner,

Thus, the gradient descent step is defined as follows:

#### [](/book/grokking-machine-learning/appendix-b/)Gradient descent step:

Replace (*w*, *b*) by (*w**'*, *b**'*), where

- *w*j' = *w*j + *η* Σiq=1 −*y*i *x*j(i)*step*(−*score*(*w, b, x*)) + (1 − *y*i) *x*j(i) *step*(*score*(*w, b, x*)), and
- *b*' = *b* + *η* Σiq=1 −*y*i*step*(−*score*(*w, b, x*)) + (1− *y*i)*step*(*score*(*w, b, x*))

And again, looking at the right-hand side of the previous expression

- If *ŷ*i = 0 and *y*i = 0:

−*y*i*step*(−*score*(*w, b, x*)) + (1− *y*i)*step*(*score*(*w, b, x*)) = 0

- If *ŷ*i = 1 and *y*i = 1:

−*y*i*step*(−*score*(*w, b, x*)) + (1− *y*i)*step*(*score*(*w, b, x*)) = 0

- If *ŷ*i = 0 and *y*i = 1:

−*y*i*step*(−*score*(*w, b, x*)) + (1− *y*i)*step*(*score*(*w, b, x*)) = −*1*

- If *ŷ*i = 1 and *y*i = 0:

−*y*i*step*(−*score*(*w, b, x*)) + (1− *y*i)*step*(*score*(*w, b, x*)) = *1*

This all may not mean very much, but one can code this to calculate all the entries of the gradient. Notice again that if the mini-batch has size *q* = 1 and consists only of the point *x* = (*x*1, *x*2, …, *x*n) with label *y* and prediction *ŷ*, then the step is defined as follows:

#### Gradient descent step:

- If the point is correctly classified, don’t change *w* and *b*.
- If the point has label *y* = 0 and is classified as *ŷ* = 1:

- Replace *w* by *w*' = *w* – *η**x*.
- Replace *b* by *b*' = *w* – *η*.

- If the point has label *y* = 1 and is classified as *ŷ* = 0:

- Replace *w* by *w*' = *w* + *η**x*.
- Replace *b* by *b*' = *w* + *η*.

Note that this is precisely the perceptron trick described in the section “The perceptron trick” in chapter 5.

#### Training a logistic regression model using gradient descent to reduce the log loss

In[](/book/grokking-machine-learning/appendix-b/)[](/book/grokking-machine-learning/appendix-b/) this subsection, we’ll calculate the gradient of the log loss function and use it to apply gradient descent and train a logistic regression model. In the logistic regression model, the predictions are *ŷ*1, *ŷ*2, …, *ŷ*q where each *ŷ*i is some real number in between 0 and 1. To calculate the predictions, we first need to remember the sigmoid function *σ*(*x*), introduced in chapter 6. This function takes as an input any real number *x* and outputs some number between 0 and 1. If *x* is a large positive number, then *σ*(*x*) is close to 1. If *x* is a large negative number, then *σ*(*x*) is close to 0. The formula for the sigmoid function is

The graph of *σ*(*x*) is illustrated in figure B.5.

The predictions of the logistic regression model are precisely the output of the sigmoid function, namely, for *i* = 1, 2, …, *q* they are defined as follows:

![Figure B.5 The sigmoid function always outputs a number between 0 and 1. The output for negative numbers is close to 0, and the output for positive numbers is close to 1.](https://drek4537l1klr.cloudfront.net/serrano/Figures/B-51.png)

The log loss is denoted as *LL*(*w, b, x*, *y*), which we’ll abbreviate as *LL*. This error function was first defined in the section “The dataset and the predictions” in chapter 6. It is similar to the perceptron error function because by construction, it is a large number if the model made a bad prediction and a small number if the model made a good prediction. The log loss function is defined as

We can proceed to calculate the gradient ∇*LL* using the chain rule. Before this, let’s note that the derivative of the sigmoid function can be written as *σ**'*(*x*) = *σ*(*x*)|1 – *σ*(*x*)|. The details on the last calculation can be worked out using the quotient rule for differentiation, and they are left to the reader. Using this, we can calculate the derivative of *ŷ*i with respect to *w*j. Because *ŷ*i = *σ*(Σin=1*w*j*x*j(i) + *b*)), then by the chain rule,

[](/book/grokking-machine-learning/appendix-b/)Now, on to develop the log loss. Using the chain rule again, we get

And by the previous calculation for ∂*ŷ*i/∂*w*j,

Simplifying, we get

which simplifies even more as

Similarly, taking the derivative with respect to *b*, we get

Therefore, the gradient descent step becomes the following:

#### Gradient descent step:

Replace (*w*, *b*) by (*w**'*, *b**'*), where

- *w*' = *w* + *η*Σiq=1(*y*i – *ŷ*i)*x*(i)
- *b*' = *b* + *η*Σiq=1(*y*i – *ŷ*i)

Notice that when the mini-batches are of size 1, the gradient descent step becomes the following:

Replace (*w*, *b*) by (*w**'*, *b**'*), where

- *w*' = *w* + *η*(*y*i – *ŷ*i)*x*(i)
- *b*' = *b* + *η*(*y*i – *ŷ*i)

This is precisely the logistic regression trick we learned in the section “How to find a good logistic classifier?” in chapter 6.

#### [](/book/grokking-machine-learning/appendix-b/)Using gradient descent to train neural networks

In[](/book/grokking-machine-learning/appendix-b/)[](/book/grokking-machine-learning/appendix-b/)[](/book/grokking-machine-learning/appendix-b/) the section “Backpropagation” in chapter 10, we went over backpropagation—the process of training a neural network. This process consists of repeating a gradient descent step to minimize the log loss. In this subsection, we see how to actually calculate the derivatives to perform this gradient descent step. We’ll perform this process in a neural network of depth 2 (one input layer, one hidden layer, and one output layer), but the example is big enough to show how these derivatives are calculated in general. Furthermore, we’ll apply gradient descent on the error for only one point (in other words, we’ll do stochastic gradient descent). However, I encourage you to work out the derivatives for a neural network of more layers, and using mini-batches of points (mini-batch gradient descent).

In our neural network, the input layer consists of *m* input nodes, the hidden layer consists of *n* hidden nodes, and the output layer consists of one output node. The notation in this

subsection is different than in the other ones, for the sake of simplicity, as follows (and illustrated in figure B.6):

- The input is the point with coordinates *x*1, *x*2, …, *x*m.
- The first hidden layer has weights *V*ij and biases *b*j, for *i* = 1, 2, …, *m* and *j* = 1, 2, …, *n*.
- The second hidden layer has weights *W*j for *j* = 1, 2, …, *n*, and bias *c*.

![Figure B.6 The process of calculating a prediction using a neural network with one hidden layer and sigmoid activation functions](https://drek4537l1klr.cloudfront.net/serrano/Figures/B-64.png)

The way the output is calculated is via the following two equations:

![](https://drek4537l1klr.cloudfront.net/serrano/Figures/AppB_06_Ea01.png)

To ease the calculation of the derivatives, we use the following helper variables *r*j and *s*:

![](https://drek4537l1klr.cloudfront.net/serrano/Figures/AppB_06_Ea02.png)

In that way, we can calculate the following partial derivatives (recalling that the derivative of the sigmoid function is *σ**'*(*x*) = *σ**'*(*x*)[1 – *σ*(*x*)] and that the log loss is *L*(*y*, *ŷ*) = – *y ln*(*ŷ*) – (1 – *y*)*ln*(1 – *ŷ*)—we’ll call it *L* for convenience):

1.

To simplify our calculations, notice that if we multiply equations 1 and 2 and use the chain rule, we get

1.

Now, we can use the chain rule and equations 3–7 to calculate the derivatives of the log loss with respect to the weights and biases as follows:

Using the previous equations, the gradient descent step is the following:

#### Gradient descent step for neural networks:

The previous equations are quite complicated, and so are the equations of backpropagation for neural networks of even more layers. Thankfully, we can use PyTorch, TensorFlow, and Keras to train neural networks without having to calculate all the derivatives.

## [](/book/grokking-machine-learning/appendix-b/)Using gradient descent for regularization

In[](/book/grokking-machine-learning/appendix-b/)[](/book/grokking-machine-learning/appendix-b/) the section “Modifying the error function to solve our problem” in chapter 4, we learned regularization as a way to decrease overfitting in machine learning models. Regularization consists of adding a regularization term to the error function, which helps reduce overfitting. This term could be the L1 or the L2 norm of the polynomial used in the model. In the section “Techniques for training neural networks” in chapter 10, we learned how to apply regularization to train neural networks by adding a similar regularization term. Later, in the section “Distance error function” in chapter 11, we learned the distance error function for SVMs, which ensured that the two lines in the classifier stayed close to each other. The distance error function had the same form of the L2 regularization term.

However, in the section “An intuitive way to see regularization” in chapter 4, we learned a more intuitive way to see regularization. In short, every gradient descent step that uses regularization is decreasing the values of the coefficients of the model by a slight amount. Let’s look at the math behind this phenomenon.

For a model with weights *w*1, *w*2, …, *w*n, the regularization terms were the following:

- L1 regularization: *W*1 = |*w*1| + |*w*2| + … + |*w*n|
- L2 regularization: *W*2 = *w*12 + *w*22 + … + *w*n2

Recall that in order to not alter the coefficients too drastically, the regularization term is multiplied by a regularization parameter *l*. Thus, when we apply gradient descent, the coefficients are modified as follows:

- L1 regularization: *w*i is replaced by *w*i – ∇ *W*1
- L2 regularization: *w*i is replaced by *w*i – ∇ *W*2

Where ∇ denotes the gradient of the regularization term. In other words, , . Since , and  then the gradient descent step is the following:

#### Gradient descent step for regularization:

- L1 regularization: Replace *a*i by
- L2 regularization: Replace *a*i by

Notice that this gradient descent step always reduces the absolute value of the coefficient *a*i. In L1 regularization, we are subtracting a small value from *a*i if it is *a*i positive and adding a small value if it is negative. In L2 regularization, we are multiplying *a*i by a number that is slightly smaller than 1.

## [](/book/grokking-machine-learning/appendix-b/)Getting stuck on local minima: How it happens, and how we solve it

As[](/book/grokking-machine-learning/appendix-b/)[](/book/grokking-machine-learning/appendix-b/) was mentioned at the beginning of this appendix, the gradient descent algorithm doesn’t necessarily find the minimum value of the function. As an example, look at figure B.7. Let’s say that we want to find the minimum of the function in this figure using gradient descent. Because the first step in gradient descent is to start on a random point, we’ll start at the point labeled “Starting point.”

![Figure B.7 We’re standing at the point labeled “Starting point.” The minimum value of the function is the point labeled “Minimum.” Will we be able to reach this minimum using gradient descent?](https://drek4537l1klr.cloudfront.net/serrano/Figures/B-710.png)

Figure B.8 shows the path that the gradient descent algorithm will take to find the minimum. Note that it succeeds in finding the closest local minimum to that point, but it completely misses the global minimum on the right.

![Figure B.8 Unfortunately, gradient descent didn’t help us find the minimum value of this function. We did manage to go down, but we got stuck at a local minimum (valley). How can we solve this problem?](https://drek4537l1klr.cloudfront.net/serrano/Figures/B-810.png)

How do we solve this problem? We can use many techniques to fix this, and in this section, we learn a common one called *random restart**[](/book/grokking-machine-learning/appendix-b/)*. The solution is to simply run the algorithm several times, always starting at a different random point, and picking the minimum value that was found overall. In figure B.9, we use random restart to find the global minimum on a function (note that this function is defined only on the interval pictured, and thus, the lowest value in the interval is indeed the global minimum). We have chosen three random starting points, one illustrated by a circle, one by a square, and one by a triangle. Notice that if we use gradient descent on each of these three points, the square manages to find the global minimum of the function.

![Figure B.9 The random restart technique illustrated. The function is defined only on this interval, with three valleys, and the global minimum located in the second valley. Here we run the gradient descent algorithm with three different starting points: the circle, the square, and the triangle. Notice that the square managed to find the global minimum of the function.](https://drek4537l1klr.cloudfront.net/serrano/Figures/B-91.png)

[](/book/grokking-machine-learning/appendix-b/)This method is still not guaranteed to find the global minimum, because we may be unlucky and pick only points that get stuck in valleys. However, with enough random starting points, we have a much higher chance of finding the global minimum. And even if we can’t find the global minimum, we may still be able to find a good enough local minimum that will help us train a good model.
