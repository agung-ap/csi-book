# [](/book/grokking-machine-learning/chapter-11/)11 Finding boundaries with style: Support vector machines and the kernel method

### In this chapter

- what a support vector machine is
- which of the linear classifiers for a dataset has the best boundary
- using the kernel method to build nonlinear classifiers
- coding support vector machines and the kernel method in Scikit-Learn

![Experts recommend the kernel method when attempting to separate chicken datasets.](https://drek4537l1klr.cloudfront.net/serrano/Figures/11-unnumb-1.png)

In this chapter, we discuss a powerful classification model called the *support vector machine* (SVM for short). An SVM is similar to a perceptron, in that it separates a dataset with two classes using a linear boundary. However, the SVM aims to find the linear boundary that is located as far as possible from the points in the dataset. We also cover the kernel method, which is useful when used in conjunction with an SVM, and it can help classify datasets using highly nonlinear boundaries.

In chapter 5, we learned about linear classifiers, or perceptrons. With two-dimensional data, these are defined by a line that separates a dataset consisting of points with two labels. However, we may have noticed that many different lines can separate a dataset, and this raises the following question: how do we know which is the best line? In figure 11.1, we can see three different linear classifiers that separate this dataset. Which one do you prefer, classifier 1, 2, or 3?

![Figure 11.1 Three classifiers that classify our data set correctly. Which should we prefer, classifier 1, 2, or 3?](https://drek4537l1klr.cloudfront.net/serrano/Figures/11-1.png)

If you said classifier 2, we agree. All three lines separate the dataset well, but the second line is better placed. The first and third lines are very close to some of the points, whereas the second line is far from all the points. If we were to wiggle the three lines around a little bit, the first and the third may go over some of the points, misclassifying some of them in the process, whereas the second one will still classify them all correctly. Thus, classifier 2 is more robust than classifiers 1 and 3.

This is where support vector machines come into play. An SVM classifier uses two parallel lines instead of one line. The goal of the SVM is twofold; it tries to classify the data correctly and also tries to space the lines as much as possible. In figure 11.2, we can see the two parallel lines for the three classifiers, together with their middle line for reference. The two external (dotted) lines in classifier 2 are the farthest from each other, which makes this classifier the best one.

![Figure 11.2 We draw our classifier as two parallel lines, as far apart from each other as possible. We can see that classifier 2 is the one where the parallel lines are the farthest away from each other. This means that the middle line in classifier 2 is the one best located between the points.](https://drek4537l1klr.cloudfront.net/serrano/Figures/11-2.png)

We may want to visualize an SVM as the line in the middle that tries to stay as far as possible from the points. We can also imagine it as the two external parallel lines trying to stay as far away from each other as possible. In this chapter, we’ll use both visualizations at different times, because each of them is useful in certain situations.

How do we build such a classifier? We can do this in a similar way as before, with a slightly different error function and a slightly different iterative step.

##### note

In this chapter, all the classifiers are discrete, namely, their output is 0 or 1. Sometimes they are described by their prediction *ŷ* = *step*(*f*(*x*)), and other times by their boundary equation *f*(*x*) = 0, namely, the graph of the function that attempts to separate our data points into two classes. For example, the perceptron that makes the prediction *ŷ* = *step*(3*x*1 + 4*x*2 – 1) sometimes is described only by the linear equation 3*x*1 + 4*x*2 – 1 = 0. For some classifiers in this chapter, especially those in the section “Training SVMs with nonlinear boundaries: The kernel method,” the boundary equation will not necessarily be a linear function.

In this chapter, we see this theory mostly on datasets of one and two dimensions (points on a line or on the plane). However, support vector machines work equally well in datasets of higher dimensions. The linear boundaries in one dimension are points and in two dimensions are lines. Likewise, the linear boundaries in three dimensions are planes, and in higher dimensions, they are hyperplanes of one dimension less than the space in which the points live. In each of these cases, we try to find the boundary that is the farthest from the points. In figure 11.3, you can see examples of boundaries for one, two, and three dimensions.

![Figure 11.3 Linear boundaries for datasets in one, two, and three dimensions. In one dimension, the boundary is formed by two points, in two dimensions by two lines, and in three dimensions by two planes. In each of the cases, we try to separate these two as much as possible. The middle boundary (point, line, or plane) is illustrated for clarity.](https://drek4537l1klr.cloudfront.net/serrano/Figures/11-3.png)

All the code for this chapter is in this GitHub repository: [https://github.com/luisguiserrano/manning/tree/master/Chapter_11_Support_Vector_Machines](https://github.com/luisguiserrano/manning/tree/master/Chapter_11_Support_Vector_Machines).

## [](/book/grokking-machine-learning/chapter-11/)Using[](/book/grokking-machine-learning/chapter-11/) a new error function to build better classifiers

As[](/book/grokking-machine-learning/chapter-11/)[](/book/grokking-machine-learning/chapter-11/) is common in machine learning models, SVMs are defined using an error function. In this section, we see the error function of SVMs, which is very special, because it tries to maximize two things at the same time: the classification of the points and the distance between the lines.

To train an SVM, we need to build an error function for a classifier consisting of two lines, spaced as far apart as possible. When we think of building an error function, we should always ask ourselves: “What do we want the model to achieve?” The following are the two things we want to achieve:

- Each of the two lines should classify the points as best as possible.
- The two lines should be as far away from each other as possible.

The error function should penalize any model that doesn’t achieve these things. Because we want two things, our SVM error function should be the sum of two error functions: the first one penalizes points that are misclassified, and the second one penalizes lines that are too close to each other. Therefore, our error function can look like this:

Error = Classification Error + Distance Error

In the next two sections, we develop each one of these two terms separately.

#### [](/book/grokking-machine-learning/chapter-11/)C[](/book/grokking-machine-learning/chapter-11/)lassification error function: Trying to classify the points correctly

In[](/book/grokking-machine-learning/chapter-11/)[](/book/grokking-machine-learning/chapter-11/)[](/book/grokking-machine-learning/chapter-11/) this section, we learn the classification error function. This is the part of the error function that pushes the classifier to correctly classify the points. In short, this error is calculated as follows. Because the classifier is formed by two lines, we think of them as two separate discrete perceptrons (chapter 5). We then calculate the total error of this classifier as the sum of the two perceptron errors (section “How to compare classifiers? The error function” in chapter 5). Let’s take a look at an example.

The SVM uses two parallel lines, and luckily, parallel lines have similar equations; they have the same weights but a different bias. Thus, in our SVM, we use the central line as a frame of reference L with equation *w*1*x*1 + *w*2*x*2 + *b* = 0, and construct two lines, one above it and one below it, with the respective equations:

- L+: *w*1*x*1 + *w*2*x*2 + *b* = 1, and
- L–: *w*1*x*1 + *w*2*x*2 + *b* = –1

As an example, figure 11.4 shows the three parallel lines, L, L+, and L–, with the following equations:

- L: 2*x*1 + 3*x*2 – 6 = 0
- L+: 2*x*1 + 3*x*2 – 6 = 1
- L–: 2*x*1 + 3*x*2 – 6 = –1

![Figure 11.4 Our main line L is the one in the middle. We build the two parallel equidistant lines L+ and L– by slightly changing the equation of L.](https://drek4537l1klr.cloudfront.net/serrano/Figures/11-4.png)

Our classifier now consists of the lines L+ and L–. We can think of L+ and L– as two independent perceptron classifiers, and each of them has the same goal of classifying the points correctly. Each classifier comes with its own perceptron error function, so the classification function is defined as the sum of these two error functions, as illustrated in figure 11.5.

![Figure 11.5 Now that our classifier consists of two lines, the error of a misclassified point is measured with respect to both lines. We then add the two errors to obtain the classification error. Note that the error is not the length of the perpendicular segment to the boundary, as illustrated, but it is proportional to it.](https://drek4537l1klr.cloudfront.net/serrano/Figures/11-5.png)

Notice that in an SVM, *both* lines have to classify the points well. Therefore, a point that is between the two lines is always misclassified by one of the lines, so it does not count as a correctly classified point by the SVM.

Recall from the section “How to compare classifiers? The error function” in chapter 5 that the error function for the discrete perceptron with prediction *ŷ* = *step*(*w*1*x*1 + *w*2*x*2 + *b*) at the point (*p*, *q*) is given by the following:

- 0 if the point is correctly classified, and
- |*w*1*x*1 + *w*2*x*2 + *b*| if the point is incorrectly classified

As an example, consider the point (4,3) with a label of 0. This point is incorrectly classified by both of the perceptrons in figure 11.5. Note that the two perceptrons give the following predictions:

- L+: *ŷ* = *step*(2*x*1 + 3*x*2 – 7)
- L–: *ŷ* = *step*(2*x*1 + 3*x*2 – 5)

Therefore, its classification error with respect to this SVM is

|2 · 4 + 3 · 3 – 7| + |2 · 4 + 3 · 3 – 5| = 10 + 12 = 22.

#### [](/book/grokking-machine-learning/chapter-11/)Distance error funct[](/book/grokking-machine-learning/chapter-11/)ion: Trying to separate our two lines as far apart as possible

Now[](/book/grokking-machine-learning/chapter-11/)[](/book/grokking-machine-learning/chapter-11/)[](/book/grokking-machine-learning/chapter-11/) that we have created an error function that measures classification errors, we need to build one that looks at the distance between the two lines and raises an alarm if this distance is small. In this section, we discuss a surprisingly simple error function that is large when the two lines are close and small when they are far.

This error function is called the *distance error function*, and we’ve already seen it before; it is the regularization term we learned in the section “Modifying the error function to solve our problem” in chapter 4. More specifically, if our lines have equations *w*1*x*1 + *w*2*x*2 + *b* = 1 and *w*1*x*1 + *w*2*x*2 + *b* = –1, then the error function is *w*12 + *w*22. Why? We’ll make use of the following fact: the perpendicular distance between the two lines is precisely , as illustrated in figure 11.6. If you’d like to work out the details of this distance calculation, please check exercise 11.1 at the end of this chapter.

![Figure 11.6 The distance between the two parallel lines can be calculated based on the equations of the lines.](https://drek4537l1klr.cloudfront.net/serrano/Figures/11-6.png)

[](/book/grokking-machine-learning/chapter-11/)Knowing this, notice the following:

- When *w*1 2 + *w*22 is large,  is small.
- When *w*12 + *w*22 is small,  is large.

Because we want the lines to be as far apart as possible, this term *w*12 + *w*22 is a good error function, as it gives us large values for the bad classifiers (those where the lines are close) and small values for the good classifiers (those where the lines are far).

In figure 11.7, we can see two examples of SVM classifiers. Their equations follow:

- SVM 1:

- L+: 3*x*1 + 4*x*2 + 5 = 1
- L–: 3*x*1 + 4*x*2 + 5 = –1

- SVM 2:

- L+: 30*x*1 + 40*x*2 + 50 = 1
- L–: 30*x*1 + 40*x*2 + 50 = 1

Their distance error functions are shown next:

- SVM 1:

- Distance error function = 32 + 42 = 25

- SVM 2:

- Distance error function = 302 + 402 = 2500

Notice also from figure 11.7 that the lines are much closer in SVM 2 than in SVM 1, which makes SVM 1 a much better classifier (from the distance perspective). The distance between the lines in SVM 1 is , whereas in SVM 2 it is .

![Figure 11.7 Left: An SVM where the lines are at distance 0.4 apart, with an error of 25. Right: An SVM where the lines are at distance 0.04 apart, with an error of 2500. Notice that in this comparison, the classifier on the left is much better than the one on the right, because the lines are farther apart from each other. This results in a smaller distance error.](https://drek4537l1klr.cloudfront.net/serrano/Figures/11-7.png)

#### [](/book/grokking-machine-learning/chapter-11/)Adding the two error functions to obtain the error[](/book/grokking-machine-learning/chapter-11/) function

Now[](/book/grokking-machine-learning/chapter-11/) that we’ve built a classification error function and a distance error function, let’s see how to combine them to build an error function that helps us make sure that we have achieved both goals: classify our points well and with two lines that are far apart from each other.

To obtain this error function, we add the classification error function and the distance error function and get the following formula:

Error = Classification Error + Distance Error

A good SVM that minimizes this error function must then try to make as few classification errors as possible, while simultaneously trying to keep the lines as far apart as possible.

![Figure 11.8 Left: A good SVM consisting of two well-spaced lines that classifies all the points correctly. Middle: A bad SVM that misclassifies two points. Right: A bad SVM that consists of two lines that are too close together.](https://drek4537l1klr.cloudfront.net/serrano/Figures/11-8.png)

In figure 11.8, we can see three SVM classifiers for the same dataset. The one on the left is a good classifier, because it classifies the data well and the lines are far apart, reducing the likelihood of errors. The one in the middle makes some errors (because there is a triangle underneath the top line and a square over the bottom line), so it is not a good classifier. The one on the right classifies the points correctly, but the lines are too close together, so it is also not a good classifier.

#### [](/book/grokking-machine-learning/chapter-11/)Do we want our SVM to focus more on classificat[](/book/grokking-machine-learning/chapter-11/)ion or distance? The C parameter can help us

In[](/book/grokking-machine-learning/chapter-11/)[](/book/grokking-machine-learning/chapter-11/)[](/book/grokking-machine-learning/chapter-11/) this section, we learn a useful technique to tune and improve our model, which involves introducing the C parameter. The *C parameter* is used in cases where we want to train an SVM that pays more attention to classification than to distance (or the other way around).

So far it seems that all we have to do to build a good SVM classifier is to keep track of two things. We want to make sure the classifier makes as few errors as possible, while keeping the lines as far apart as possible. But what if we have to sacrifice one for the benefit of the other? In figure 11.9, we have two classifiers for the same dataset. The one on the left makes some errors, but the lines are far apart. The one on the right makes no errors, but the lines are too close together. Which one should we prefer?

![Figure 11.9 Both of these classifiers have one pro and one con. The one on the left consists of well-spaced lines (pro), but it misclassifies some points (con). The one on the right consists of lines that are too close together (con), but it classifies all the points correctly (pro).](https://drek4537l1klr.cloudfront.net/serrano/Figures/11-9.png)

It turns out that the answer for this depends on the problem we are solving. Sometimes we want a classifier that makes as few errors as possible, even if the lines are too close, and sometimes we want a classifier that keeps the lines apart, even if it makes a few errors. How do we control this? We use a parameter which we call the C parameter. We slightly modify the error formula by multiplying the classification error by C, to get the following formula:

Error formula = C · (Classification Error) + (Distance Error)

If C is large, then the error formula is dominated by the classification error, so our classifier focuses more on classifying the points correctly. If C is small, then the formula is dominated by the distance error, so our classifier focuses more on keeping the lines far apart.

![Figure 11.10 Different values of C toggle between a classifier with well-spaced lines and one that classifies points correctly. The classifier on the left has a small value of C (0.01), and the lines are well spaced, but it makes mistakes. The classifier on the right has a large value of C (100), and it classifies points correctly, but the lines are too close together. The classifier in the middle makes one mistake but finds two lines that are well spaced apart.](https://drek4537l1klr.cloudfront.net/serrano/Figures/11-10.png)

In figure 11.10, we can see three classifiers: one with a large value of C that classifies all points correctly, one with a small value of C that keeps the lines far apart, and one with C = 1, which tries to do both. In real life, C is a hyperparameter that we can tune using methods such as the model complexity graph (section “A numerical way to decide how complex our model should be” in chapter 4) or our own knowledge of the problem we’re solving, the data, and the model.

## [](/book/grokking-machine-learning/chapter-11/)Coding support vector machines in Scikit-Lear[](/book/grokking-machine-learning/chapter-11/)n

Now[](/book/grokking-machine-learning/chapter-11/)[](/book/grokking-machine-learning/chapter-11/) that we’ve learned what an SVM is, we are ready to code one and use it to model some data. In Scikit-Learn, coding an SVM is simple and that’s what we learn in this section. We also learn how to use the C parameter in our code.

#### [](/book/grokking-machine-learning/chapter-11/)Coding a simple SVM

We[](/book/grokking-machine-learning/chapter-11/)[](/book/grokking-machine-learning/chapter-11/) start by coding [](/book/grokking-machine-learning/chapter-11/)a simple SVM in a sample dataset and then we’ll add more parameters. The dataset is called linear.csv, and its plot is shown in figure 11.11. The code for this section follows:

-  **Noteboo****k**: SVM_graphical_example.ipynb

- [https://github.com/luisguiserrano/manning/blob/master/Chapter_11_Support_Vector_Machines/SVM_graphical_example.ipynb](https://github.com/luisguiserrano/manning/blob/master/Chapter_11_Support_Vector_Machines/SVM_graphical_example.ipynb)

- **Dataset**: linear.csv

We first import from the `svm` package in Scikit-Learn and load our data as follows:

```
from sklearn.svm import SVC
```

![Figure 11.11 An almost linearly separable dataset, with some outliers](https://drek4537l1klr.cloudfront.net/serrano/Figures/11-111.png)

Then, as shown in the next code snippet, we load our data into two Pandas DataFrames called `features``` and `labels```, and then we define our model called `svm_linear` and train it. The accuracy we obtain is 0.933, and the plot is shown in figure 11.12.

```
svm_linear = SVC(kernel='linear')
svm_linear.fit(features, labels)
```

![Figure 11.12 The plot of the SVM classifier we’ve built in Scikit-Learn consists of a line. The accuracy of this model is 0.933.](https://drek4537l1klr.cloudfront.net/serrano/Figures/11-12.png)

#### [](/book/grokking-machine-learning/chapter-11/)The C parameter

In [](/book/grokking-machine-learning/chapter-11/)[](/book/grokking-machine-learning/chapter-11/)[](/book/grokking-machine-learning/chapter-11/)Scikit-Learn, we can easily introduce the C parameter into the model. Here we train and plot two models, one with a very small value of 0.01, and another one with a large value of 100, which is shown in the following code and in figure 11.13:

```
svm_c_001 = SVC(kernel='linear', C=0.01)
svm_c_001.fit(features, labels)

svm_c_100 = SVC(kernel='linear', C=100)
svm_c_100.fit(features, labels)
```

![Figure 11.13 The classifier on the left has a small value of C, and it spaced the line well between the points, but it makes some mistakes. The classifier on the right has a large value of C, and it makes no mistakes, although the line passes too close to some of the points.](https://drek4537l1klr.cloudfront.net/serrano/Figures/11-13.png)

We can see that the model with a small value of C doesn’t put that much emphasis on classifying the points correctly, and it makes some mistakes, as is evident in its low accuracy (0.867). It is hard to tell in this example, but this classifier puts a lot of emphasis on the line being as far away from the points as possible. In contrast, the classifier with the large value of C tries to classify all the points correctly, which reflects on its higher accu[](/book/grokking-machine-learning/chapter-11/)racy.

## [](/book/grokking-machine-learning/chapter-11/)Training SVMs with nonlinear boundaries: The kernel method

As[](/book/grokking-machine-learning/chapter-11/)[](/book/grokking-machine-learning/chapter-11/) we’ve seen in other chapters of this book, not every dataset is linearly separable, and many times we need to build nonlinear classifiers to capture the complexity of the data. In this section, we study a powerful method associated with SVMs called the *kernel method*, which helps us build highly nonlinear classifiers.

If we have a dataset and find that we can’t separate it with a linear classifier, what can we do? One idea is to add more columns to this dataset and hope that the richer dataset is linearly separable. The kernel method consists of adding more columns in a clever way, building a linear classifier on this new dataset and later removing the columns we added while keeping track of the (now nonlinear) classifier.

That was quite a mouthful, but we have a nice geometric way to see this method. Imagine that the dataset is in two dimensions, which means that the input has two columns. If we add a third column, the dataset is now three-dimensional, like if the points on your paper all of a sudden start flying into space at different heights. Maybe if we raise the points at different heights in a clever way, we can separate them with a plane. This is the kernel method, and it is illustrated in figure 11.14.

![Figure 11.14 Left: The set is not separable by a line. Middle: We look at it in three dimensions, and proceed to raise the two triangles and lower the two squares. Right: Our new dataset is now separable by a plane. (Source: Image created with the assistance of Grapher™ from Golden Software, LLC; https://www.goldensoftware.com/products/grapher).](https://drek4537l1klr.cloudfront.net/serrano/Figures/11-14.png)

#### Kernels, feature maps, and operator theory

The theory behind the kernel method comes from a field in mathematics called *operator theory**[](/book/grokking-machine-learning/chapter-11/)*. A kernel is a similarity function, which, in short, is a function that tells us if two points are similar or different (e.g., close or far). A kernel can give rise to a *feature map**[](/book/grokking-machine-learning/chapter-11/)[](/book/grokking-machine-learning/chapter-11/)*, which is a map between the space where our dataset lives and a (usually) higher-dimensional space.

The full theory of kernels and feature maps is not needed to understand the classifiers. If you’d like to delve into these more, see the resources in appendix C. For the purpose of this chapter, we look at the kernel method as a way of adding columns to our dataset to make the points separable. For example, the dataset in figure 11.14 has two columns, *x*1 and *x*2, and we have added the third column with the value *x*1*x*2. Equivalently, it can also be seen as the function that sends the point (*x*1, *x*2) in the plane to the point (*x*1, *x*2, *x*1*x*2) in space. Once the points belong in 3-D space, we can separate them using the plane seen on the right of figure 11.14. To study this example more in detail, see exercise 11.2 at the end of the chapter.

The two kernels[](/book/grokking-machine-learning/chapter-11/) and their corresponding features maps we see in this chapter are the *polynomial kernel* and the *radial basis function* (RBF) *kernel**[](/book/grokking-machine-learning/chapter-11/)*. Both of them consist of adding columns to our dataset in different, yet very effective, ways[](/book/grokking-machine-learning/chapter-11/).

#### [](/book/grokking-machine-learning/chapter-11/)Using polynomial equations to our benefit: The polynomial kernel

In[](/book/grokking-machine-learning/chapter-11/)[](/book/grokking-machine-learning/chapter-11/) this section, we discuss the polynomial kernel, a useful kernel that will help us model nonlinear datasets. More specifically, the kernel method helps us model data using polynomial equations such as circles, parabolas, and hyperbolas. We’ll illustrate the polynomial kernel with two exampl[](/book/grokking-machine-learning/chapter-11/)es.

#### Example 1: A circular dataset

For[](/book/grokking-machine-learning/chapter-11/)[](/book/grokking-machine-learning/chapter-11/)[](/book/grokking-machine-learning/chapter-11/) our first example, let’s try to classify the dataset in table 11.1.

##### Table 11.1 A small dataset, depicted in figure 11.15[(view table figure)](https://drek4537l1klr.cloudfront.net/serrano/HighResolutionFigures/table_11-1.png)

| *x*1 | *x*2 | *y* |
| --- | --- | --- |
| 0.3 | 0.3 | 0 |
| 0.2 | 0.8 | 0 |
| –0.6 | 0.4 | 0 |
| 0.6 | –0.4 | 0 |
| –0.4 | –0.3 | 0 |
| 0 | –0.8 | 0 |
| –0.4 | 1.2 | 1 |
| 0.9 | –0.7 | 1 |
| –1.1 | –0.8 | 1 |
| 0.7 | 0.9 | 1 |
| –0.9 | 0.8 | 1 |
| 0.6 | –1 | 1 |

The plot is shown in figure 11.15, where the points with label 0 are drawn as squares and those with label 1 are drawn as triangles.

When we look at the plot in figure 11.15, it is clear that a line won’t be able to separate the squares from the triangles. However, a circle would (seen in figure 11.16). Now the question is, if a support vector machine can draw only linear boundaries, how can we draw this circle?

![Figure 11.15 Plot of the dataset in table 11.1. Note that it is not separable by a line. Therefore, this dataset is a good candidate for the kernel method.](https://drek4537l1klr.cloudfront.net/serrano/Figures/11-15.png)

![Figure 11.16 The kernel method gives us a classifier with a circular boundary, which separates these points well.](https://drek4537l1klr.cloudfront.net/serrano/Figures/11-16.png)

To draw this boundary, let’s think. What is a characteristic that separates the squares from the triangles? From observing the plot, it seems that the triangles are farther from the origin than the circles. The formula that measures the distance to the origin is the square root of the sum of the squares of the two coordinates. If these coordinates are *x*1 and *x*2, then this distance is . Let’s forget about the square root, and think only of *x*12 + *x*22. Now let’s add a column to table 11.1 with this value and see what happens. The resulting dataset is shown in table 11.2.

##### Table 11.2 We have added one more column to table 11.1. This one consists of the sum of the squares of the values of the first two columns.[(view table figure)](https://drek4537l1klr.cloudfront.net/serrano/HighResolutionFigures/table_11-2.png)

| *x*1 | *x*2 | *x*1 2 + *x*22 | *y* |
| --- | --- | --- | --- |
| 0.3 | 0.3 | 0.18 | 0 |
| 0.2 | 0.8 | 0.68 | 0 |
| –0.6 | 0.4 | 0.52 | 0 |
| 0.6 | –0.4 | 0.52 | 0 |
| –0.4 | –0.3 | 0.25 | 0 |
| 0 | –0.8 | 0.64 | 0 |
| –0.4 | 1.2 | 1.6 | 1 |
| 0.9 | –0.7 | 1.3 | 1 |
| –1.1 | –0.8 | 1.85 | 1 |
| 0.7 | 0.9 | 1.3 | 1 |
| –0.9 | 0.8 | 1.45 | 1 |
| 0.6 | –1 | 1.36 | 1 |

After looking at table 11.2, we can see the trend. All the points labeled 0 satisfy that the sum of the squares of the coordinates is less than 1, and the points labeled 1 satisfy that this sum is greater than 1. Therefore, the equation on the coordinates that separates the points is precisely *x*12 + *x*22 = 1. Note that this is not a linear equation, because the variables are raised to a power greater than one. In fact, this is precisely the equation of a circle.

The geometric way to imagine this is depicted in figure 11.17. Our original set lives in the plane, and it is impossible to separate the two classes with a line. But if we raise each point (*x*1, *x*2)to the height *x*12 + *x*22, this is the same as putting the points in the paraboloid with equation *z* = *x*12 + *x*22 (drawn in the figure). The distance we raised each point is precisely the square of the distance from that point to the origin. Therefore, the squares are raised a small amount, because they are close to the origin, and the triangles are raised a large amount, because they are far away from the origin. Now the squares and triangles are far away from each other, and therefore, we can separate them with the horizontal plane at height 1—in other words, the plane with equation *z* = 1. As a final step, we project everything down to the plane. The intersection between the paraboloid and the plane becomes the circle of equation *x*12 + *x*22 = 1. Notice that this equation is not linear, because it has quadratic terms. Finally, the prediction this classifier makes is given by *ŷ* = *step*(*x*12 + *x*22 – 1).

![Figure 11.17 The kernel method. Step 1: We start with a dataset that is not linearly separable. Step 2: Then we raise each point by a distance that is the square of its distance to the origin. This creates a paraboloid. Step 3: Now the triangles are high, whereas the squares are low. We proceed to separate them with a plane at height 1. Step 4. We project everything down. The intersection between the paraboloid and the plane creates a circle. The projection of this circle gives us the circular boundary of our classifier. (Source: Image created with the assistance of Grapher™ from Golden Software, LLC; https://www.goldensoftware.com/products/grapher).](https://drek4537l1klr.cloudfront.net/serrano/Figures/11-17.png)

#### Example 2: T[](/book/grokking-machine-learning/chapter-11/)he modified XOR dataset

Circles[](/book/grokking-machine-learning/chapter-11/)[](/book/grokking-machine-learning/chapter-11/)[](/book/grokking-machine-learning/chapter-11/) are not the only figure we can draw. Let’s consider a very simple dataset, illustrated in table 11.3 and plotted in figure 11.18. This dataset is similar to the one that corresponds to the XOR operator from exercises 5.3 and 10.2. If you’d like to solve the same problem with the original XOR dataset[](/book/grokking-machine-learning/chapter-11/), you can do it in exercise 11.2 at the end of the chapter.

##### Table 11.3 The modified XOR dataset[(view table figure)](https://drek4537l1klr.cloudfront.net/serrano/HighResolutionFigures/table_11-3.png)

| *x*1 | *x*2 | *y* |
| --- | --- | --- |
| –1 | –1 | 1 |
| –1 | 1 | 0 |
| 1 | –1 | 0 |
| 1 | 1 | 1 |

To see that this dataset is not linearly separable, take a look at figure 11.18. The two triangles lie on opposite corners of a large square, and the two squares lie on the remaining two corners. It is impossible to draw a line that separates the triangles from the squares. However, we can use a polynomial equation to help us, and this time we’ll use the product of the two features. Let’s add the column corresponding to the product *x*1*x*2 to the original dataset. The result is shown in table 11.4.

##### Table 11.4 We have added a column to table 11.3, which consists of the product of the first two columns. Notice that there is a strong relation between the rightmost two columns on the table.[(view table figure)](https://drek4537l1klr.cloudfront.net/serrano/HighResolutionFigures/table_11-4.png)

| *x*1 | *x*2 | *x*1 *x*2 | *y* |
| --- | --- | --- | --- |
| –1 | –1 | 1 | 1 |
| –1 | 1 | –1 | 0 |
| 1 | –1 | –1 | 0 |
| 1 | 1 | 1 | 1 |

Notice that the column corresponding to the product *x*1*x*2 is very similar to the column of labels. We can now see that a good classifier for this data is the one with the following boundary equation: *x*1*x*2 = 1. The plot of this equation is the union of the horizontal and vertical axes, and the reason for this is that for the product *x*1*x*2 to be 0, we need that *x*1 = 0 or *x*2 = 0. The prediction this classifier makes is given by *ŷ* = *step*(*x*1*x*2), and it is 1 for points in the northeast and southwest quadrants of the plane, and 0 [](/book/grokking-machine-learning/chapter-11/)elsewhere.

![Figure 11.18 The plot of the dataset in table 11.3. The classifier that separates the squares from the triangles has boundary equation x1x2 = 0, which corresponds to the union of the horizontal and vertical axes.](https://drek4537l1klr.cloudfront.net/serrano/Figures/11-18.png)

#### Going beyond qu[](/book/grokking-machine-learning/chapter-11/)adratic equations: The polynomial kernel

In[](/book/grokking-machine-learning/chapter-11/)[](/book/grokking-machine-learning/chapter-11/) both of the previous examples, we used a polynomial expression to help us classify a dataset that was not linearly separable. In the first example, this expression was *x*12 + *x*22 , because that value is small for points near the origin and large for points far from the origin. In the second example, the expression was *x*1*x*2, which helped us separate points in different quadrants of the plane.

How did we find these expressions? In a more complicated dataset, we may not have the luxury to look at a plot and eyeball an expression that will help us out. We need a method or, in other words, an algorithm. What we’ll do is consider all the possible monomials of degree 2 (quadratic), containing *x*1 and *x*2. These are the following three monomials: *x*12, *x*1*x*2, and *x*22. We call these new variables *x*3, *x*4, and *x*5, and we treat them as if they had no relation with *x*1 and *x*2 whatsoever. Let’s apply this to the first example (the circle). The dataset in table 11.1 with these new columns added is shown in table 11.5.

We can now build an SVM that classifies this enhanced dataset. The way to train an SVM is using the methods learned in the last section. I encourage you to build such a classifier using Scikit-Learn, Turi Create, or the package of your choice. By inspection, here is one equation of a classifier that works:

0*x*1 + 0*x*2 + 1*x*3 + 0*x*4 + 1*x*5 – 1 = 0

##### Table 11.5 We have added three more columns to table 11.1, one corresponding to each of the monomials of degree 2 on the two variables *x*1 and *x*2. These monomials are *x*12, *x*1 *x*2, and *x*22.[(view table figure)](https://drek4537l1klr.cloudfront.net/serrano/HighResolutionFigures/table_11-5.png)

| *x*1 | *x*2 | *x*3 = *x*12 | *x*4 = *x*1 *x*2 | *x*5 = *x*22 | *y* |
| --- | --- | --- | --- | --- | --- |
| 0.3 | 0.3 | 0.09 | 0.09 | 0.09 | 0 |
| 0.2 | 0.8 | 0.04 | 0.16 | 0.64 | 0 |
| –0.6 | 0.4 | 0.36 | –0.24 | 0.16 | 0 |
| 0.6 | –0.4 | 0.36 | –0.24 | 0.16 | 0 |
| –0.4 | –0.3 | 0.16 | 0.12 | 0.09 | 0 |
| 0 | –0.8 | 0 | 0 | 0.64 | 0 |
| –0.4 | 1.2 | 0.16 | –0.48 | 1.44 | 1 |
| 0.9 | –0.7 | 0.81 | –0.63 | 0.49 | 1 |
| –1.1 | –0.8 | 1.21 | 0.88 | 0.64 | 1 |
| 0.7 | 0.9 | 0.49 | 0.63 | 0.81 | 1 |
| –0.9 | 0.8 | 0.81 | –0.72 | 0.64 | 1 |
| 0.6 | –1 | 0.36 | –0.6 | 1 | 1 |

Remembering that *x*3 = *x*12 and *x*5 = *x*22, we get the desired equation of the circle, as shown next:

*x*12 + *x*22 = 1

If we want to visualize this process geometrically, like we’ve done with the previous ones, it gets a little more complicated. Our nice two-dimensional dataset became a five-dimensional dataset. In this one, the points labelled 0 and 1 are now far away, and can be separated with a four-dimensional hyperplane. When we project this down to two dimensions, we get the desired circle.

The polynomial kernel gives rise to the map that sends the 2-D plane to the 5-D space. The map is the one that sends the point (*x*1, *x*2) to the point (*x*1, *x*2, *x*12, *x*1*x*2, *x*22). Because the maximum degree of each monomial is 2, we say that this is the polynomial kernel of degree 2. For the polynomial kernel, we always have to specify the degree.

What columns do we add to the dataset if we are using a polynomial kernel of higher degree, say, *k*? We add one column for each monomial in the given set of variables, of degree less than or equal to *k*. For example, if we are using the degree 3 polynomial kernel on the variables *x*1 and *x*2, we are adding columns corresponding to the monomials {*x*1, *x*2, *x*12, *x*1*x*2, *x*22, *x*13, *x*12*x*2, *x*1*x*22, *x*23}. We can also do this for more variables in the same way. For example, if we use the degree 2 polynomial kernel on the variables *x*1, *x*2, and *x*3, we are adding columns with the following [](/book/grokking-machine-learning/chapter-11/)monomials: {*x*1, *x*2, *x*3, *x*12, *x*1*x*2, *x*1*x*3, *x*22, *x*2*x*3, *x*32}.

#### [](/book/grokking-machine-learning/chapter-11/)Using bumps in higher dimensions to our benefit: The radial basis function (RBF) kernel

The[](/book/grokking-machine-learning/chapter-11/)[](/book/grokking-machine-learning/chapter-11/) next kernel that we’ll see is the radial basis function kernel. This kernel is tremendously useful in practice, because it can help us build nonlinear boundaries using certain special functions centered at each of the data points. To introduce the RBF kernel, let’s first look at the one-dimensional example shown in figure 11.19. This dataset is not linearly separable—the square lies exactly between the two triangles.

![Figure 11.19 A dataset in one dimension that can’t be classified by a linear classifier. Notice that a linear classifier is a point that divides the line into two parts, and there is no point that we can locate on the line that leaves all the triangles on one side and the square on the other side.](https://drek4537l1klr.cloudfront.net/serrano/Figures/11-19.png)

The way we will build a classifier for this dataset is to imagine building a mountain or a valley on each of the points. For the points labeled 1 (the triangles), we’ll put a mountain, and for those labeled 0 (the square), we’ll put a valley. These mountains and valleys are called *radial basis functions*. The resulting figure is shown at the top of figure 11.20. Now, we draw a mountain range such that at every point, the height is the sum of all the heights of the mountains and valleys at that point. We can see the resulting mountain range at the bottom of figure 11.20. Finally, the boundary of our classifier corresponds to the points at which this mountain range is at height zero, namely, the two highlighted points in the bottom. This classifier classifies anything in the interval between those two points as a square and everything outside of the interval as a triangle.

![Figure 11.20 Using an SVM with the RBF kernel to separate a nonlinear dataset in one dimension. Top: We draw a mountain (radial basis function) at each point with label 1 and a valley at each point of label 0. Bottom: We add the radial basis functions from the top figure. The resulting function intersects the axis twice. The two points of intersection are the boundary of our SVM classifier. We classify each point between them as a square (label 0) and every point outside as a triangle (label 1).](https://drek4537l1klr.cloudfront.net/serrano/Figures/11-20.png)

This (plus some math around it which comes in the next section) is the essence of the RBF kernel. Now let’s use it to build a similar classifier in a two-dimensional dataset.

To build the mountains and valleys on the plane, imagine the plane as a blanket (as illustrated in figure 11.21). If we pinch the blanket at that point and raise it, we get the mountain. If we push it down, we get the valley. These mountains and valleys are radial basis functions. They are called radial basis functions because the value of the function at a point is dependent only on the distance between the point and the center. We can raise the blanket at any point we like, and that gives us one different radial basis function for each point. The *radial basis function kernel* (also called RBF kernel) gives rise to a map that uses these radial functions to add several columns to our dataset in a way that will help us separate it.

![Figure 11.21 A radial basis function consists of raising the plane at a particular point. This is the family of functions that we’ll use to build nonlinear classifiers. (Source: Image created with the assistance of Grapher™ from Golden Software, LLC; https://www.goldensoftware.com/products/grapher).](https://drek4537l1klr.cloudfront.net/serrano/Figures/11-211.png)

How do we use this as a classifier? Imagine the following: we have the dataset on the left of figure 11.22, where, as usual, the triangles represent points with label 1, and the squares represent points with label 0. Now, we lift the plane at every triangle and push it down at every square. We get the three-dimensional plot shown on the right of figure 11.22.

To create the classifier, we draw a plane at height 0 and intersect it with our surface. This is the same as looking at the curve formed by the points at height 0. Imagine if there is a landscape with mountains and the sea. The curve will correspond to the coastline, namely, where the water and the land meet. This coastline is the curve shown on the left in figure 11.23. We then project everything back to the plane and obtain our desired classifier, shown on the right in figure 11.23.

That is the idea behind the RBF kernel. Of course, we have to develop the math, which we will do in the next few sections. But in principle, if we can imagine lifting and pushing down a blanket, and then building a classifier by looking at the boundary of the points that lie at a particular height, then we can understand what an RBF kernel is.

![Figure 11.22 Left: A dataset in the plane that is not linearly separable. Right: We have used the radial basis functions to raise each of the triangles and lower each of the squares. Notice that now we can separate the dataset by a plane, which means our modified dataset is linearly separable. (Source: Image created with the assistance of Grapher™ from Golden Software, LLC; https://www.goldensoftware.com/products/grapher).](https://drek4537l1klr.cloudfront.net/serrano/Figures/11-22.png)

![Figure 11.23 Left: If we look at the points at height 0, they form a curve. If we think of the high points as land and the low points as the sea, this curve is the coastline. Right: When we project (flatten) the points back to the plane, the coastline is now our classifier that separates the triangles from the squares. (Source: Image created with the assistance of Grapher™ from Golden Software, LLC; https://www.goldensoftware.com/products/grapher).](https://drek4537l1klr.cloudfront.net/serrano/Figures/11-23.png)

#### A more in-depth look at [](/book/grokking-machine-learning/chapter-11/)radial basis functions

Radial[](/book/grokking-machine-learning/chapter-11/)[](/book/grokking-machine-learning/chapter-11/) basis functions can exist in any number of variables. At the beginning of this section, we saw them in one and two variables. For one variable, the simplest radial basis function has the formula *y* = *e*−x2. This looks like a bump over the line (figure 11.24). It looks a lot like a standard normal (Gaussian) distribution. The standard normal distribution is similar, but it has a slightly different formula, so that the area underneath it is 1.

![Figure 11.24 An example of a radial basis function. It looks a lot like a normal (Gaussian) distribution.](https://drek4537l1klr.cloudfront.net/serrano/Figures/11-24.png)

Notice that this bump happens at 0. If we wanted it to appear at any different point, say *p*, we can translate the formula and get *y* = *e*−(*x* − *p*)2. For example, the radial basis function centered at the point 5 is precisely *y* = *e*−(*x* − 5)2.

For two variables, the formula for the most basic radial basis function is *z* = *e*−(*x*2 + *y*2), and it looks like the plot shown in figure 11.25. Again, you may notice that it looks a lot like a multivariate normal distribution. It is, again, a modified version of the multivariate normal distribution.

![Figure 11.25 A radial basis function on two variables. It again looks a lot like a normal distribution. (Source: Image created with the assistance of Grapher™ from Golden Software, LLC; https://www.goldensoftware.com/products/grapher).](https://drek4537l1klr.cloudfront.net/serrano/Figures/11-25.png)

This bump happens exactly at the point (0,0). If we wanted it to appear at any different point, say (*p, q*), we can translate the formula, and get *y* = *e*−[(*x* − *p*)2 +(*y* − *q*)2]. For example, the radial basis function centered at the point (2, –3) is precisely *y* = *e*−[(*x* − 2)2 +(*y* + 3)2].

For n variables, the formula for the basic radial basis function is *y* = *e*−(*x*12+ ··· +*x*n2). We can’t draw a plot in *n* + 1 dimensions, but if we imagine pinching an *n*-dimensional blanket and lifting it up with our fingers, that’s how it looks. However, because the algorithm that we use is purely mathematical, the computer has no trouble running it in as many variables as we want. As usual, this *n*-dimensional bump is centered at 0, but if we wanted it centered at the point (*p*1, …, *p*n), the formula is *y* = *e*−[(*x*1 - *p*1)2+ ··· +(*x*n - *p*n)2]

#### A measure of how close points are: Sim[](/book/grokking-machine-learning/chapter-11/)ilarity

To [](/book/grokking-machine-learning/chapter-11/)[](/book/grokking-machine-learning/chapter-11/)[](/book/grokking-machine-learning/chapter-11/)build an SVM using the RBF kernel, we need one notion: the notion of *similarity*. We say that two points are similar if they are close to each other, and not similar if they are far away (figure 11.26). In other words, the similarity between two points is high if they are close to each other and low if they are far away from each other. If the pair of points are the same point, then the similarity is 1. In theory, the similarity between two points that are an infinite distance apart is 0.

![Figure 11.26 Two points that are close to each other are defined to have high similarity. Two points that are far away are defined to have low similarity.](https://drek4537l1klr.cloudfront.net/serrano/Figures/11-26.png)

Now we need to find a formula for similarity. As we can see, the similarity between two points decreases as the distance between them increases. Thus, many formulas for similarity would work, as long as they satisfy that condition. Because we are using exponential functions in this section, let’s define it as follows. For points *p* and *q*, the similarity between *p* and *q* is as follows:

*similarity*(*p*,*q*)= *e*–distance(p,q)2

That looks like a complicated formula for similarity, but there is a very nice way to look at it. If we want to find the similarity between two points, say *p* and *q*, this similarity is precisely the height of the radial basis function centered at *p* and applied at the point *q*. This is, if we pinch the blanket at point *p* and lift it, then the height of the blanket at point *q* is high if the *q* is close to *p* and low if *q* is far from *p*. In figure 11.27, we can see this for one variable, but imagine it in any number of variables by using the blanket [](/book/grokking-machine-learning/chapter-11/)analogy.

![Figure 11.27 The similarity is defined as the height of a point in the radial basis function, where the input is the distance. Note that the higher the distance, the lower the similarity, and vice versa.](https://drek4537l1klr.cloudfront.net/serrano/Figures/11-27.png)

#### [](/book/grokking-machine-learning/chapter-11/)Training an SVM with the [](/book/grokking-machine-learning/chapter-11/)RBF kernel

Now[](/book/grokking-machine-learning/chapter-11/)[](/book/grokking-machine-learning/chapter-11/) that we have all the tools to train an SVM using the RBF kernel, let’s see how to put it all together. Let’s first look at the simple dataset displayed in figure 11.19. The dataset itself appears in table 11.6.

##### Table 11.6 The one-dimensional dataset shown in figure 11.19. Note that it isn’t linearly separable, because the point with label 0 is right between the two points with label 1.[(view table figure)](https://drek4537l1klr.cloudfront.net/serrano/HighResolutionFigures/table_11-6.png)

| Point | *x* | y (label) |
| --- | --- | --- |
| 1 | –1 | 1 |
| 2 | 0 | 0 |
| 3 | 1 | 1 |

As we saw, this dataset is not linearly separable. To make it linearly separable, we’ll add a few columns. The three columns we are adding are the similarity columns, and they record the similarity between the points. The similarity between two points with *x*-coordinates *x*1 and *x*2 is measured as *e*(*x*1 + *x*2)2, as indicated in the section “Using bumps in higher dimensions to our benefit.” For example, the similarity between points 1 and 2 is *e*(−1 −0)2 = 0.368. In the Sim1 column, we’ll record the similarity between point 1 and the other three points, and so on. The extended dataset is shown in table 11.7.

##### Table 11.7 We extend the dataset in table 11.6 by adding three new columns. Each column corresponds to the similarity of all points with respect to each point. This extended dataset lives in a four-dimensional space, and it is linearly separable.[(view table figure)](https://drek4537l1klr.cloudfront.net/serrano/HighResolutionFigures/table_11-7.png)

| Point | *x* | Sim1 | Sim2 | Sim3 | *y* |
| --- | --- | --- | --- | --- | --- |
| 1 | –1 | 1 | 0.368 | 0.018 | 1 |
| 2 | 0 | 0.368 | 1 | 0.368 | 0 |
| 3 | 1 | 0.018 | 0.368 | 1 | 1 |

This extended dataset is now linearly separable! Many classifiers will separate this set, but in particular, the one with the following boundary equation will:

*ŷ* = *step*(*Sim*1 – *Sim*2 + *Sim*3)

Let’s verify this by predicting the label at every point as shown next:

- **Point 1**: *ŷ* = *step*(1 – 0.368 + 0.018) = *step*(0.65) = 1
- **Point 2**: *ŷ* = *step*(0.368 – 1 + 0.368) = *step*(–0.264) = 0
- **Point 3**: *ŷ* = *step*(0.018 – 0.368 + 1) = *step*(0.65) = 1

Furthermore, because *Sim*1=*e*(*x* + 1)2, *Sim*2=*e*(*x* − 0)2, and *Sim*3=*e*(*x* − 1)2 then our final classifier makes the following predictions:

*ŷ* = *step*(*e*(*x* + 1)2 − *e**x*2 + *e*(*x* − 1)2)

Now, let’s do this same procedure but in two dimensions. This section does not require code, but the calculations are large, so if you’d like to take a look at them, they are in the following notebook: [https://github.com/luisguiserrano/manning/blob/master/Chapter_11_Support_Vector_Machines/Calculating_similarities.ipynb](https://github.com/luisguiserrano/manning/blob/master/Chapter_11_Support_Vector_Machines/Calculating_similarities.ipynb).

##### Table 11.8 A simple dataset in two dimensions, plotted in figure 11.28. We’ll use an SVM with an RBF kernel to classify this dataset.[(view table figure)](https://drek4537l1klr.cloudfront.net/serrano/HighResolutionFigures/table_11-8.png)

| Point | *x*1 | *x*2 | *y* |
| --- | --- | --- | --- |
| 1 | 0 | 0 | 0 |
| 2 | –1 | 0 | 0 |
| 3 | 0 | –1 | 0 |
| 4 | 0 | 1 | 1 |
| 5 | 1 | 0 | 1 |
| 6 | –1 | 1 | 1 |
| 7 | 1 | –1 | 1 |

Consider the dataset in table 11.8, which we already classified graphically (figures 11.22 and 11.23). For convenience, it is plotted again in figure 11.28. In this plot, the points with label 0 appear as squares and those with label 1 as triangles.

Notice that in the first column of table 11.8 and in figure 11.28, we have numbered every point. This is not part of the data; we did it only for convenience. We will now add seven columns to this table. The columns are the similarities with respect to every point. For example, for point 1, we add a similarity column named Sim1. The entry for every point in this column is the amount of similarity between that point and point 1. Let’s calculate one of them, for example, the similarity with point 6. The distance between point 1 and point 6, by the Pythagorean theorem follows:

![Figure 11.28 The plot of the dataset in table 11.8, where the points with label 0 are squares and those with label 1 are triangles. Notice that the squares and triangles cannot be separated with a line. We’ll use an SVM with an RBF kernel to separate them with a curved boundary.](https://drek4537l1klr.cloudfront.net/serrano/Figures/11-28.png)

Therefore, the similarity is precisely

*similarity*(*point* 1, *point* 6)= *e*–distance(q,p)2 = *e*–2 = 0.135.

This number goes in row 1 and column Sim6 (and by symmetry, also in row 6 and column Sim1). Fill in a few more values in this table to convince yourself that this is the case, or take a look at the notebook where the whole table is calculated. The result is shown in table 11.9.

##### Table 11.9 We have added seven similarity columns to the dataset in table 11.8. Each one records the similarities with all the other six points.[(view table figure)](https://drek4537l1klr.cloudfront.net/serrano/HighResolutionFigures/table_11-9.png)

| Point | *x*1 | *x*2 | Sim1 | Sim2 | Sim3 | Sim4 | Sim5 | Sim6 | Sim7 | *y* |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 0 | 0 | 1 | 0.368 | 0.368 | 0.368 | 0.368 | 0.135 | 0.135 | 0 |
| 2 | –1 | 0 | 0.368 | 1 | 0.135 | 0.135 | 0.018 | 0.368 | 0.007 | 0 |
| 3 | 0 | –1 | 0.368 | 0.135 | 1 | 0.018 | 0.135 | 0.007 | 0.368 | 0 |
| 4 | 0 | 1 | 0.368 | 0.135 | 0.018 | 1 | 0.135 | 0.368 | 0.007 | 1 |
| 5 | 1 | 0 | 0.368 | 0.018 | 0.135 | 0.135 | 1 | 0.007 | 0.368 | 1 |
| 6 | –1 | 1 | 0.135 | 0.368 | 0.007 | 0.367 | 0.007 | 1 | 0 | 1 |
| 7 | 1 | –1 | 0.135 | 0.007 | 0.368 | 0.007 | 0.368 | 0 | 1 | 1 |

Notice the following things:

1. The similarity between each point and itself is always 1.
1. For each pair of points, the similarity is high when they are close in the plot and low when they are far.
1. The table consisting of the columns Sim1 to Sim7 is symmetric, because the similarity between *p* and *q* is the same as the similarity between *q* and *p* (as it depends only on the distance between *p* and *q*).
1. The similarity between points 6 and 7 appears as 0, but in reality, it is not. The distance between points 6 and 7 is , so their similarity is *e*–8 = 0.00033546262, which rounds to zero because we are using three significant figures.

Now, on to building our classifier! Notice that for the data in the small table 11.8, no linear classifier works (because the points can’t be split by a line), but on the much larger table 11.9, which has a lot more features (columns), we can fit such a classifier. We proceed to fit an SVM to this data. Many SVMs can classify this dataset correctly, and in the notebook, I’ve used Turi Create to build one. However, a simpler one works as well. This classifier has the following weights:

- The weights of *x*1 and *x*2 are 0.
- The weight of Sim *p* is 1, for *p* = 1, 2, and 3.
- The weight of Sim *p* is –1, for *p* = 4, 5, 6, and 7.
- The bias is *b* = 0.

We find the classifier was adding a label –1 to the columns corresponding to the points labeled 0, and a +1 to the columns corresponding to the points labeled 1. This is equivalent to the process of adding a mountain at any point of label 1 and a valley at every point of label 0, like in figure 11.29. To check mathematically that this works, take table 11.7, add the values of the columns Sim4, Sim5, Sim6, and Sim7, then subtract the values of the columns Sim1, Sim2 and Sim3. You’ll notice that you get a negative number in the first three rows and a positive one in the last four rows. Therefore, we can use a threshold of 0, and we have a classifier that classifies this dataset correctly, because the points labeled 1 get a positive score, and the points labeled 0 get a negative score. Using a threshold of 0 is equivalent to using the coastline to separate the points in the plot in figure 11.29.

If we plug in the similarity function, the classifier we obtain is the following:

*ŷ* = *step*(−*e**x*12 + *x*2 2 −*e*(*x*1 + 1)2 + *x*22 −*e**x*12 + (*x*2 + 1)2 +*e**x*12 + (*x*2 − 1)2 +*e*(*x*1 − 1)2 + *x*22 +*e*(*x*1 + 1)2 + (*x*2 − 1)2 +*e*(*x*1 − 1)2 + (*x*2 + 1)2)

In summary, we found a dataset that was not linearly separable. We used radial basis functions and similarity between points to add several columns to the dataset. This helped us build a linear classifier (in a much higher-dimensional space). We then projected the higher-dimensional linear classifier into the plane to get the classifier we wanted. We can see the resulting curved classifier in figure 11.29.

![Figure 11.29 In this dataset, we raised each triangle and lowered each square. Then we drew a plane at height 0, which separates the squares and the triangles. The plane intersects the surface in a curved boundary. We then projected everything back down to two dimensions, and this curved boundary is the one that separates our triangles from our squares. The boundary is drawn at the right. (Source: Image created with the assistance of Grapher™ from Golden Software, LLC; https://www.goldensoftware.com/products/grapher).](https://drek4537l1klr.cloudfront.net/serrano/Figures/11-29.png)

#### Overfitting [](/book/grokking-machine-learning/chapter-11/)and underfitting with the RBF kernel: The gamma parameter

At[](/book/grokking-machine-learning/chapter-11/) the beginning of this section, we mentioned that many different radial basis functions exist, namely one per point in the plane. There are actually many more. Some of them lift the plane at a point and form a narrow surface, and others form a wide surface. Some examples can be seen in figure 11.30. In practice, the wideness of our radial basis functions is something we want to tune. For this, we use a parameter called the *gamma parameter*. When gamma is small, the surface formed is very wide, and when it is large, the surface is very narrow.

![Figure 11.30 The gamma parameter determines how wide the surface is. Notice that for small values of gamma, the surface is very wide, and for large values of gamma, the surface is very narrow. (Source: Image created with the assistance of Grapher™ from Golden Software, LLC; https://www.goldensoftware.com/products/grapher).](https://drek4537l1klr.cloudfront.net/serrano/Figures/11-30.png)

Gamma is a hyperparameter. Recall that hyperparameters are the specifications that we use to train our model. The way we tune this hyperparameter is using methods that we’ve seen before, such as the model complexity graph (the section “A numerical way to decide how complex our model should be” in chapter 4). Different values of gamma tend to overfit and underfit. Let’s look back at the example at the beginning of this section, with three different values of gamma. The three models are plotted in figure 11.31.

![Figure 11.31 Three SVM classifiers shown with an RBF kernel and different values of gamma. (Source: Image created with the assistance of Grapher™ from Golden Software, LLC; https://www.goldensoftware.com/products/grapher).](https://drek4537l1klr.cloudfront.net/serrano/Figures/11-311.png)

Notice that for a very small value of gamma, the model overfits, because the curve is too simple, and it doesn’t classify our data well. For a large value of gamma, the model vastly overfits, because it builds a tiny mountain for each triangle and a tiny valley for each square. This makes it classify almost everything as a square, except for the areas just around the triangles. A medium value of gamma seems to work well, because it builds a boundary that is simple enough, yet classifies the points correctly.

The equation for the radial basis function doesn’t change much when we add the gamma parameter—all we have to do is multiply the exponent by gamma. In the general case, the equation of the radial basis function follows:

*y* = *e*−*γ*[(*x*1 − *p*1)2+ ··· +( *xn* + *pn*)2]

Don’t worry very much about learning this formula—just remember that even in higher dimensions, the bumps we make can be wide or narrow. As usual, there is a way to code this and make it work, which is what we do in the next section.

#### [](/book/grokking-machine-learning/chapter-11/)Codi[](/book/grokking-machine-learning/chapter-11/)ng the kernel method

Now[](/book/grokking-machine-learning/chapter-11/)[](/book/grokking-machine-learning/chapter-11/)[](/book/grokking-machine-learning/chapter-11/) that we’ve learned the kernel method for SVMs, we learn code them in Scikit-Learn and train a model in a more complex dataset using the polynomial and RBF kernels. To train an SVM in Scikit-Learn with a particular kernel, all we do is add the kernel as a parameter when we define the SVM. The code for this section follows:

-  **Notebook**: SVM_graphical_example.ipynb

- [https://github.com/luisguiserrano/manning/blob/master/Chapter_11_Support_Vector_Machines/SVM_graphical_example.ipynb](https://github.com/luisguiserrano/manning/blob/master/Chapter_11_Support_Vector_Machines/SVM_graphical_example.ipynb)

- Datasets:

- one_circle.csv
- two_circles.csv

#### Coding t[](/book/grokking-machine-learning/chapter-11/)he polynomial kernel to classify a circular dataset

In[](/book/grokking-machine-learning/chapter-11/)[](/book/grokking-machine-learning/chapter-11/)[](/book/grokking-machine-learning/chapter-11/) this subsection, we see how to code the polynomial kernel in Scikit-Learn. For this, we use the dataset called one_circle.csv, shown in figure 11.32.

![Figure 11.32 A circular dataset, with some noise. We will use an SVM with the polynomial kernel to classify this dataset.](https://drek4537l1klr.cloudfront.net/serrano/Figures/11-32.png)

Notice that aside from some outliers, this dataset is mostly circular. We train an SVM classifier where we specify the `kernel` parameter[](/book/grokking-machine-learning/chapter-11/)[](/book/grokking-machine-learning/chapter-11/) to be `poly`, and the `degree` parameter to be 2, as shown in the next code snippet. The reason we want the degree to be 2 is because the equation of a circle is a polynomial of degree 2. The result is shown in figure 11.33.

```
svm_degree_2 = SVC(kernel='poly', degree=2)
svm_degree_2.fit(features, labels)
```

![Figure 11.33 An SVM classifier with a polynomial kernel of degree 2](https://drek4537l1klr.cloudfront.net/serrano/Figures/11-33.png)

Notice that this SVM with a polynomial kernel of degree 2 manages to build a mostly circular region to bound the dataset, as desired.

#### C[](/book/grokking-machine-learning/chapter-11/)oding the RBF kernel to classify a dataset formed by two intersecting circles and playing with the gamma parameter

We’ve[](/book/grokking-machine-learning/chapter-11/) [](/book/grokking-machine-learning/chapter-11/)drawn a circle, but let’s get more complicated. In this subsection, we learn how to code several SVMs with the RBF kernel to classify a dataset that has the shape of two intersecting circles. This dataset, called two_circles.csv, is illustrated in figure 11.34.

![Figure 11.34 A dataset consisting of two intersecting circles, with some outliers. We will use an SVM with the RBF kernel to classify this dataset.](https://drek4537l1klr.cloudfront.net/serrano/Figures/11-34.png)

To use the RBF kernel, we specify `kernel = 'rbf'`. We can also specify a value for gamma. We’ll train four different SVM classifiers, for the following values of gamma: 0.1, 1, 10, and 100, as shown next:

```
svm_gamma_01 = SVC(kernel='rbf', gamma=0.1)  #1
svm_gamma_01.fit(features, labels)

svm_gamma_1 = SVC(kernel='rbf', gamma=1)     #2
svm_gamma_1.fit(features, labels)

svm_gamma_10 = SVC(kernel='rbf', gamma=10)   #3
svm_gamma_10.fit(features, labels)

svm_gamma_100 = SVC(kernel='rbf', gamma=100) #4
svm_gamma_100.fit(features, labels)
```

![Figure 11.35 Four SVM classifiers with an RBF kernel and different values of gamma](https://drek4537l1klr.cloudfront.net/serrano/Figures/11-35.png)

The four classifiers appear in figure 11.35. Notice that for gamma = 0.1, the model underfits a little, because it thinks the boundary is one oval, and it makes some mistakes. Gamma = 1 gives a good model that captures the data well. By the time we get to gamma = 10, we can see that the model starts to overfit. Notice how it tries to classify every point correctly, including the outliers, which it encircles individually. By the time we get to gamma=100, we can see some serious overfitting. This classifier only surrounds each triangle with a small circular region and classifies everything else as a square. Thus, for this model, gamma = 1 seems to be the best value among the ones we t[](/book/grokking-machine-learning/chapter-11/)ried.

## [](/book/grokking-machine-learning/chapter-11/)Summary

- A support vector machine (SVM) is a classifier that consists of fitting two parallel lines (or hyperplanes), and trying to space them as far apart as possible, while still trying to classify the data correctly.
- The way to build support vector machines is with an error function that comprises two terms: the sum of two perceptron errors, one per parallel line, and the distance error, which is high when the two parallel lines are far apart and low when they are close together.
- We use the C parameter to regulate between trying to classify the points correctly and trying to space out the lines. This is useful while training because it gives us control over our preferences, namely, if we want to build a classifier that classifies the data very well, or a classifier with a well-spaced boundary.
- The kernel method is a useful and very powerful tool for building nonlinear classifiers.
- The kernel method consists of using functions to help us embed our dataset inside a higher-dimensional space, in which the points may be easier to classify with a linear classifier. This is equivalent to adding columns to our dataset in a clever way to make the enhanced dataset linearly separable.
- Several different kernels, such as the polynomial kernel and the RBF kernel, are available. The polynomial kernel allows us to build polynomial regions such as circles, parabolas, and hyperbolas. The RBF kernel allows us to build more complex curved reg[](/book/grokking-machine-learning/chapter-11/)ions.

## [](/book/grokking-machine-learning/chapter-11/)Exer[](/book/grokking-machine-learning/chapter-11/)cises

#### Exercise 11.1

(This exercise completes the calculation needed in the section “Distance error function.”)

Show that the distance between the lines with equations *w*1*x*1 + *w*2*x*1 + *b* = 1 and *w*1*x*1 + *w*2*x*1 + *b* = –1 is precisely .

![](https://drek4537l1klr.cloudfront.net/serrano/Figures/11-unnumb-2.png)

#### E[](/book/grokking-machine-learning/chapter-11/)xercise 11.2

As we learned in exercise 5.3, it is impossible to build a perceptron model that mimics the XOR gate. In other words, it is impossible to fit the following dataset (with 100% accuracy) with a perceptron model:

| *x*1 | *x*2 | *y* |
| --- | --- | --- |
| 0 | 0 | 0 |
| 0 | 1 | 1 |
| 1 | 0 | 1 |
| 1 | 1 | 0 |

This is because the dataset is not linearly separable. An SVM has the same problem, because an SVM is also a linear model. However, we can use a kernel to help us out. What kernel should we use to turn this dataset into a linearly separable one? What would the resulting SVM look like?

##### hint

Look at example 2 in the section “Using polynomial equations to your benefit,” which solves a very similar problem.
