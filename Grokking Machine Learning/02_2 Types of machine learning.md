# [](/book/grokking-machine-learning/chapter-2/)2 Types of machine learning

### In this chapter

- three different types of machine learning: supervised, unsupervised, and reinforcement learning
- the difference between labeled and unlabeled data
- the difference between regression and classification, and how they are used

![](https://drek4537l1klr.cloudfront.net/serrano/Figures/CH02_F01_Serrano_Text.png)

As we learned in chapter 1, machine learning is common sense for a computer. Machine learning roughly mimics the process by which humans make decisions based on experience, by making decisions based on previous data. Naturally, programming computers to mimic the human thinking process is challenging, because computers are engineered to store and process numbers, not make decisions. This is the task that machine learning aims to tackle. Machine learning is divided into several branches, depending on the type of decision to be made. In this chapter, we overview some of the most important among these branches.

Machine learning has applications in many fields, such as the following:

- Predicting house prices based on the house’s size, number of rooms, and location
- Predicting today’s stock market prices based on yesterday’s prices and other factors of the market
- Detecting spam and non-spam emails based on the words in the e-mail and the sender
- Recognizing images as faces or animals, based on the pixels in the image
- Processing long text documents and outputting a summary
- Recommending videos or movies to a user (e.g., on YouTube or Netflix)
- Building chatbots that interact with humans and answer questions
- Training self-driving cars to navigate a city by themselves
- Diagnosing patients as sick or healthy
- Segmenting the market into similar groups based on location, acquisitive power, and interests
- Playing games like chess or Go

Try to imagine how we could use machine learning in each of these fields. Notice that some of these applications are different but can be solved in a similar way. For example, predicting housing prices and predicting stock prices can be done using similar techniques. Likewise, predicting whether an email is spam and predicting whether a credit card transaction is legitimate or fraudulent can also be done using similar techniques. What about grouping users of an app based on their similarity? That sounds different from predicting housing prices, but it could be done similarly to grouping newspaper articles by topic. And what about playing chess? That sounds different from all the other previous applications, but it could be like playing Go.

Machine learning models are grouped into different types, according to the way they operate. The main three families of machine learning models are

- *supervised learning*,
- *unsupervised learning*, and
- *reinforcement learning*.

In this chapter, we overview all three. However, in this book, we focus only on supervised learning because it is the most natural one to start learning and arguably the most used right now. Look up the other types in the literature and learn about them, too, because they are all interesting and useful! In the resources in appendix C, you can find some interesting links, including several videos created by the author.

## [](/book/grokking-machine-learning/chapter-2/)What is the difference between labeled and unlabeled data?

#### [](/book/grokking-machine-learning/chapter-2/)What is data?

We[](/book/grokking-machine-learning/chapter-2/)[](/book/grokking-machine-learning/chapter-2/)[](/book/grokking-machine-learning/chapter-2/) talked about data in chapter 1, but before we go any further, let’s first establish a clear definition of what we mean by *data* in this book. Data is simply information. Any time we have a table with information, we have data. Normally, each row in our table is a data point. Say, for example, that we have a dataset of pets. In this case, each row represents a different pet. Each pet in the table is described by certain features of that pet.

#### [](/book/grokking-machine-learning/chapter-2/)And what are features?

In [](/book/grokking-machine-learning/chapter-2/)chapter 1, we defined features as the properties or characteristics of the data. If our data is in a table, the features are the columns of the table. In our pet example, the features may be size, name, type, or weight. Features could even be the colors of the pixels in an image of the pet. This is what describes our data. Some features are special, though, and we call them *labels*.

#### [](/book/grokking-machine-learning/chapter-2/)Labels?

This [](/book/grokking-machine-learning/chapter-2/)one is a bit less straightforward, because it depends on the context of the problem we are trying to solve. Normally, if we are trying to predict a particular feature based on the other ones, that feature is the label. If we are trying to predict the type of pet (e.g., cat or dog) based on information on that pet, then the label is the type of pet (cat/dog). If we are trying to predict if the pet is sick or healthy based on symptoms and other information, then the label is the state of the pet (sick/healthy). If we are trying to predict the age of the pet, then the label is the age (a number).

#### [](/book/grokking-machine-learning/chapter-2/)Predictions

We [](/book/grokking-machine-learning/chapter-2/)have been using the concept of making predictions freely, but let’s now pin it down. The goal of a predictive machine learning model is to guess the labels in the data. The guess that the model makes is called a *prediction*.

Now that we know what labels are, we can understand there are two main types of data: *labeled* and *unlabeled* data.

#### [](/book/grokking-machine-learning/chapter-2/)Labeled and unlabeled data

Labeled[](/book/grokking-machine-learning/chapter-2/) data is data that comes with labels. Unlabeled data is data that comes with no labels. An example of labeled data is a dataset of emails that comes with a column that records whether the emails are spam or ham, or a column that records whether the email is work related. An example of unlabeled data is a dataset of emails that has no particular column we are interested in predicting.

In figure 2.1, we see three datasets containing images of pets. The first dataset has a column recording the type of pet, and the second dataset has a column specifying the weight of the pet. These two are examples of labeled data. The third dataset consists only of images, with no label, making it unlabeled data.

![Figure 2.1 Labeled data is data that comes with a tag, or label. That label can be a type or a number. Unlabeled data is data that comes with no tag. The dataset on the left is labeled, and the label is the type of pet (dog/cat). The dataset in the middle is also labeled, and the label is the weight of the pet (in pounds). The dataset on the right is unlabeled.](https://drek4537l1klr.cloudfront.net/serrano/Figures/2-1.png)

Of course, this definition contains some ambiguity, because depending on the problem, we decide whether a particular feature qualifies as a label. Thus, determining if data is labeled or unlabeled, many times, depends on the problem we are trying to solve.

Labeled and unlabeled data yield two different branches of machine learning called *supervised* and *unsupervised* learning, which are defined in the next three sections.

## [](/book/grokking-machine-learning/chapter-2/)Supervised learning: The branch of machine learning that works with labeled data

We[](/book/grokking-machine-learning/chapter-2/)[](/book/grokking-machine-learning/chapter-2/)[](/book/grokking-machine-learning/chapter-2/) can find supervised learning in some of the most common applications nowadays, including image recognition, various forms of text processing, and recommendation systems. Supervised learning is a type of machine learning that uses labeled data. In short, the goal of a supervised learning model is to predict (guess) the labels.

In the example in figure 2.1, the dataset on the left contains images of dogs and cats, and the labels are “dog” and “cat.” For this dataset, the machine learning model would use previous data to predict the label of new data points. This means, if we bring in a new image *without* a label, the model will guess whether the image is of a dog or a cat, thus predicting the label of the data point (figure 2.2).

![Figure 2.2 A supervised learning model predicts the label of a new data point. In this case, the data point corresponds to a dog, and the supervised learning algorithm is trained to predict that this data point does, indeed, correspond to a dog.](https://drek4537l1klr.cloudfront.net/serrano/Figures/2-2.png)

If you recall from chapter 1, the framework we learned for making a decision was remember-formulate-predict. This is precisely how supervised learning works. The model first **remembers** the dataset of dogs and cats. Then it **formulates** a model, or a rule, for what it believes constitutes a dog and a cat. Finally, when a new image comes in, the model makes a **prediction** about what it thinks the label of the image is, namely, a dog or a cat (figure 2.3).

![Figure 2.3 A supervised learning model follows the remember-formulate-predict framework from chapter 1. First, it remembers the dataset. Then, it formulates rules for what would constitute a dog and a cat. Finally, it predicts whether a new data point is a dog or a cat.](https://drek4537l1klr.cloudfront.net/serrano/Figures/2-3.png)

Now, notice that in figure 2.1, we have two types of labeled datasets. In the dataset in the middle, each data point is labeled with the weight of the animal. In this dataset, the labels are numbers. In the dataset on the left, each data point is labeled with the type of animal (dog or cat). In this dataset, the labels are states. Numbers and states are the two types of data that we’ll encounter in supervised learning models. We call the first type *numerical data**[](/book/grokking-machine-learning/chapter-2/)* and the second type *categorical data**[](/book/grokking-machine-learning/chapter-2/)*.

##### numerical data

is any type of data that uses numbers such as 4, 2.35, or –199. Examples of numerical data are prices, sizes, or weights.

##### categorical data

is any type of data that uses categories, or states, such as male/female or cat/dog/bird. For this type of data, we have a finite set of categories to associate to each of the data points.

This gives rise to the following two types of supervised learning models:

##### regression models

are the types of models that predict **numerical data**. The output of a regression model is a *number*, such as the weight of the animal.

##### classification models

are the types of models that predict **categorical data**. The output of a classification model is a *category*, or a *state*, such as the type of animal (cat or dog).

Let’s look at two examples of supervised learning models, one regression and one classification.

**Model 1: housing prices model****[](/book/grokking-machine-learning/chapter-2/)[](/book/grokking-machine-learning/chapter-2/)** **(regression).** In this model, each data point is a house. The label of each house is its price. Our goal is that when a new house (data point) comes on the market, we would like to predict its label, namely, its price.

**Model 2: email spam–detection model****[](/book/grokking-machine-learning/chapter-2/)** **(classification).** In this model, each data point is an email. The label of each email is either spam or ham. Our goal is that when a new email (data point) comes into our inbox, we would like to predict its label, namely, whether it is spam or ham.

Notice the difference between models 1 and 2.

- The housing prices model is a model that can return a number from many possibilities, such as $100, $250,000, or $3,125,672.33. Thus, it is a *regression* model[](/book/grokking-machine-learning/chapter-2/).
- The spam detection model, on the other hand, can return only two things: spam or ham. Thus, it is a *classification* model[](/book/grokking-machine-learning/chapter-2/).

In the following subsections, we elaborate more on regression and classification.

#### [](/book/grokking-machine-learning/chapter-2/)Regression models predict numbers

As[](/book/grokking-machine-learning/chapter-2/)[](/book/grokking-machine-learning/chapter-2/)[](/book/grokking-machine-learning/chapter-2/)[](/book/grokking-machine-learning/chapter-2/) we discussed previously, regression models are those in which the label we want to predict is a number. This number is predicted based on the features. In the housing example, the features can be anything that describes a house, such as the size, the number of rooms, the distance to the closest school, or the crime rate in the neighborhood.

Other places where one can use regression models follow:

- **Stock market**: predicting the price of a certain stock based on other stock prices and other market signals
- **Medicine**: predicting the expected life span of a patient or the expected recovery time, based on symptoms and the medical history of the patient
- **Sales**: predicting the expected amount of money a customer will spend, based on the client’s demographics and past purchase behavior
- **Video recommendations**: predicting the expected amount of time a user will watch a video, based on the user’s demographics and other videos they have watched

The most common method used for regression is linear regression, which uses linear functions (lines or similar objects) to make our predictions based on the features. We study linear regression in chapter 3. Other popular methods used for regression are decision tree regression, which we learn in chapter 9, and several ensemble methods such as random forests, AdaBoost, gradient boosted trees, and XGBoost, which we learn in chapter 12.

#### [](/book/grokking-machine-learning/chapter-2/)Classification models predict a state

Classification[](/book/grokking-machine-learning/chapter-2/)[](/book/grokking-machine-learning/chapter-2/)[](/book/grokking-machine-learning/chapter-2/)[](/book/grokking-machine-learning/chapter-2/) models are those in which the label we want to predict is a state belonging to a finite set of states. The most common classification models predict a “yes” or a “no,” but many other models use a larger set of states. The example we saw in figure 2.3 is an example of classification, because it predicts the type of the pet, namely, “cat” or “dog.”

In the email spam recognition example, the model predicts the state of the email (namely, spam or ham) from the features of the email. In this case, the features of the email can be the words on it, the number of spelling mistakes, the sender, or anything else that describes the email.

Another common application of classification is image recognition. The most popular image recognition models take as input the pixels in the image, and they output a prediction of what the image depicts. Two of the most famous datasets for image recognition are MNIST and CIFAR-10. MNIST contains approximately 60,000 28-by-28-pixel black-and-white images of handwritten digits which are labelled 0–9. These images come from a combination of sources, including the American Census Bureau and a repository of handwritten digits written by American high school students. The MNIST dataset can be found in the following link: [http://yann.lecun.com/exdb/mnist/](http://yann.lecun.com/exdb/mnist/)**.** The CIFAR-10 dataset contains 60,000 32-by-32-pixel colored images of different things. These images are labeled with 10 different objects (thus the 10 in its name), namely airplanes, cars, birds, cats, deer, dogs, frogs, horses, ships, and trucks. This database is maintained by the Canadian Institute for Advanced Research (CIFAR), and it can be found in the following link: [https://www.cs.toronto.edu/~kriz/cifar.html](https://www.cs.toronto.edu/~kriz/cifar.html)**.**

Some additional powerful applications of classification models follow:

- **Sentiment analysis****[](/book/grokking-machine-learning/chapter-2/)**: predicting whether a movie review is positive or negative, based on the words in the review
- **Website traffic****[](/book/grokking-machine-learning/chapter-2/)**: predicting whether a user will click a link or not, based on the user’s demographics and past interaction with the site

- **Social media****[](/book/grokking-machine-learning/chapter-2/)**: predicting whether a user will befriend or interact with another user, based on their demographics, history, and friends in common
- **Video recommendations**: predicting whether a user will watch a video, based on the user’s demographics and other videos they have watched

The bulk of this book (chapters 5, 6, 8, 9, 10, 11, and 12) covers classification models. In these chapters we learn the perceptrons (chapter 5), logistic classifiers (chapter 6), the naive Bayes algorithm (chapter 8), decision trees (chapter 9), neural networks (chapter 10), support vector machines (chapter 11), and ensemble methods (chapter 12).

## [](/book/grokking-machine-learning/chapter-2/)Unsupervised learning: The branch of machine learning that works with unlabeled data

Unsupervised[](/book/grokking-machine-learning/chapter-2/)[](/book/grokking-machine-learning/chapter-2/)[](/book/grokking-machine-learning/chapter-2/) learning is also a common type of machine learning. It differs from supervised learning in that the data is unlabeled. In other words, the goal of a machine learning model is to extract as much information as possible from a dataset that has no labels, or targets to predict.

What could such a dataset be, and what could we do with it? In principle, we can do a little less than what we can do with a labeled dataset, because we have no labels to predict. However, we can still extract a lot of information from an unlabeled dataset. For example, let’s go back to the cats and dogs example on the rightmost dataset in figure 2.1. This dataset consists of images of cats and dogs, but it has no labels. Therefore, we don’t know what type of pet each image represents, so we can’t predict if a new image corresponds to a dog or a cat. However, we can do other things, such as determine if two pictures are similar or different. This is something unsupervised learning algorithms do. An unsupervised learning algorithm can group the images based on similarity, even without knowing what each group represents (figure 2.4). If done properly, the algorithm could separate the dog images from the cat images, or even group each of them by breed!

![Figure 2.4 An unsupervised learning algorithm can still extract information from data. For example, it can group similar elements together.](https://drek4537l1klr.cloudfront.net/serrano/Figures/2-4.png)

As a matter of fact, even if the labels are there, we can still use unsupervised learning techniques on our data to preprocess it and apply supervised learning methods more effectively.

The main branches of unsupervised learning are clustering, dimensionality reduction, and generative learning.

##### clustering algorithms

The algorithms that group data into clusters based on similarity

##### dimensionality reduction algorithms

The algorithms that simplify our data and faithfully describe it with fewer features

##### generative algorithms

The algorithms that can generate new data points that resemble the existing data

In the following three subsections, we study these three branches in more detail.

#### [](/book/grokking-machine-learning/chapter-2/)Clustering algorithms split a dataset into similar groups

As[](/book/grokking-machine-learning/chapter-2/)[](/book/grokking-machine-learning/chapter-2/)[](/book/grokking-machine-learning/chapter-2/)[](/book/grokking-machine-learning/chapter-2/) we stated previously, clustering algorithms are those that split the dataset into similar groups. To illustrate this, let’s go back to the two datasets in the section “Supervised learning”—the housing dataset and the spam email dataset—but imagine that they have no labels. This means that the housing dataset has no prices, and the email dataset has no information on the emails being spam or ham.

Let’s begin with the housing dataset. What can we do with this dataset? Here is an idea: we could somehow group the houses by similarity. For example, we could group them by location, price, size, or a combination of these factors. This process is called *clustering*. Clustering is a branch of unsupervised machine learning that consists of the tasks that group the elements in our dataset into clusters where all the data points are similar.

Now let’s look at the second example, the dataset of emails. Because the dataset is unlabeled, we don’t know whether each email is spam or ham. However, we can still apply some clustering to our dataset. A clustering algorithm splits our images into a few different groups based on different features of the email. These features could be the words in the message, the sender, the number and size of the attachments, or the types of links inside the email. After clustering the dataset, a human (or a combination of a human and a supervised learning algorithm) could label these clusters by categories such as “Personal,” “Social,” and “Promotions.”

As an example, let’s look at the dataset in table 2.1, which contains nine emails that we would like to cluster. The features of the dataset are the size of the email and the number of recipients.

##### Table 2.1 A table of emails with their size and number of recipients[(view table figure)](https://drek4537l1klr.cloudfront.net/serrano/HighResolutionFigures/table_2-1.png)

| Email | Size | Recipients |
| --- | --- | --- |
| 1 | 8 | 1 |
| 2 | 12 | 1 |
| 3 | 43 | 1 |
| 4 | 10 | 2 |
| 5 | 40 | 2 |
| 6 | 25 | 5 |
| 7 | 23 | 6 |
| 8 | 28 | 6 |
| 9 | 26 | 7 |

To the naked eye, it looks like we could group the emails by their number of recipients. This would result in two clusters: one with emails having two or fewer recipients, and one with emails having five or more recipients. We could also try to group them into three groups by size. But you can imagine that as the table gets larger and larger, eyeballing the groups gets harder and harder. What if we plot the data? Let’s plot the emails in a graph, where the horizontal axis records the size and the vertical axis records the number of recipients. This gives us the plot in figure 2.5.

![Figure 2.5  A plot of the email dataset. The horizontal axis corresponds to the size of the email and the vertical axis to the number of recipients. We can see three well-defined clusters in this dataset.](https://drek4537l1klr.cloudfront.net/serrano/Figures/2-5.png)

In figure 2.5 we can see three well-defined clusters, which are highlighted in figure 2.6.

![Figure 2.6 We can cluster the emails into three categories based on size and number of recipients.](https://drek4537l1klr.cloudfront.net/serrano/Figures/2-6.png)

This last step is what clustering is all about. Of course, for us humans, it’s easy to eyeball the three groups once we have the plot. But for a computer, this task is not easy. Furthermore, imagine if our data contained millions of points, with hundreds or thousands of features. With more than three features, it is impossible for humans to see the clusters, because they would be in dimensions that we cannot visualize. Luckily, computers can do this type of clustering for huge datasets with multiple rows and columns.

Other applications of clustering are the following:

- **Market segmentation****[](/book/grokking-machine-learning/chapter-2/)**: dividing customers into groups based on demographics and previous purchasing behavior to create different marketing strategies for the groups
- **Genetics****[](/book/grokking-machine-learning/chapter-2/)**: clustering species into groups based on gene similarity
- **Medical imaging****[](/book/grokking-machine-learning/chapter-2/)**: splitting an image into different parts to study different types of tissue
- **Video recommendations**: dividing users into groups based on demographics and previous videos watched and using this to recommend to a user the videos that other users in their group have watched

#### More on unsupervised learning models

In the rest of this book, we don’t cover unsupervised learning. However, I strongly encourage you to study it on your own. Here are some of the most important clustering algorithms out there. Appendix C lists several more (including some videos of mine) where you can learn these algorithms in detail.

- **K****-means clustering****[](/book/grokking-machine-learning/chapter-2/)**: this algorithm groups points by picking some random centers of mass and moving them closer and closer to the points until they are at the right spots.

- **Hierarchical clustering****[](/book/grokking-machine-learning/chapter-2/)[](/book/grokking-machine-learning/chapter-2/)**: this algorithm starts by grouping the closest points together and continuing in this fashion, until we have some well-defined groups.
- **Density-based spatial clustering (DBSCAN****[](/book/grokking-machine-learning/chapter-2/)[](/book/grokking-machine-learning/chapter-2/)[](/book/grokking-machine-learning/chapter-2/)****)**: this algorithm starts grouping points together in places with high density, while labeling the isolated points as noise.
- **Gaussian mixture models****[](/book/grokking-machine-learning/chapter-2/)**: this algorithm does not assign a point to one cluster but instead assigns fractions of the point to each of the existing clusters. For example, if there are three clusters, A, B, and C, then the algorithm could determine that 60% of a particular point belongs to group A, 25% to group B, and 15% to group C.

#### [](/book/grokking-machine-learning/chapter-2/)Dimensionality reduction simplifies data without losing too much information

Dimensionality[](/book/grokking-machine-learning/chapter-2/)[](/book/grokking-machine-learning/chapter-2/)[](/book/grokking-machine-learning/chapter-2/)[](/book/grokking-machine-learning/chapter-2/) reduction is a useful preprocessing step that we can apply to vastly simplify our data before applying other techniques. As an example, let’s go back to the housing dataset. Imagine that the features are the following:

- Size
- Number of bedrooms
- Number of bathrooms
- Crime rate in the neighborhood
- Distance to the closest school

This dataset has five columns of data. What if we wanted to turn the dataset into a simpler one with fewer columns, without losing a lot of information? Let’s do this by using common sense. Take a closer look at the five features. Can you see any way to simplify them—perhaps to group them into some smaller and more general categories?

After a careful look, we can see that the first three features are similar, because they are all related to the size of the house. Similarly, the fourth and fifth features are similar to each other, because they are related to the quality of the neighborhood. We could condense the first three features into a big “size” feature, and the fourth and fifth into a big “neighborhood quality” feature. How do we condense the size features? We could forget about rooms and bedrooms and consider only the size, we could add the number of bedrooms and bathrooms, or maybe take some other combination of the three features. We could also condense the area quality features in similar ways. Dimensionality reduction algorithms will find good ways to condense these features, losing as little information as possible and keeping our data as intact as possible while managing to simplify it for easier process and storage (figure 2.7).

![Figure 2.7 Dimensionality reduction algorithms help us simplify our data. On the left, we have a housing dataset with many features. We can use dimensionality reduction to reduce the number of features in the dataset without losing much information and obtain the dataset on the right.](https://drek4537l1klr.cloudfront.net/serrano/Figures/2-7.png)

Why is it called dimensionality reduction if all we’re doing is reducing the number of columns in our data? The fancy word for the number of columns in a dataset is *dimension**[](/book/grokking-machine-learning/chapter-2/)*. Think about this: if our data has one column, then each data point is one number. A collection of numbers can be plotted as a collection of points in a line, which has precisely one dimension. If our data has two columns, then each data point is formed by a pair of numbers. We can imagine a collection of pairs of numbers as a collection of points in a city, where the first number is the street number and the second number is the avenue. Addresses on a map are two-dimensional, because they are in a plane. What happens when our data has three columns? In this case, then each data point is formed by three numbers. We can imagine that if every address in our city is a building, then the first and second numbers are the street and avenue, and the third one is the floor in the building. This looks more like a three-dimensional city. We can keep going. What about four numbers? Well, now we can’t really visualize it, but if we could, this set of points would look like places in a four-dimensional city, and so on. The best way to imagine a four-dimensional city is by imagining a table with four columns. What about a 100-dimensional city? This would be a table with 100 columns, in which each person has an address that consists of 100 numbers. The mental picture we could have when thinking of higher dimensions is shown in figure 2.8. Therefore, as we went from five dimensions down to two, we reduced our five-dimensional city into a two-dimensional city. This is why it is called dimensionality reduction.

![Figure 2.8 How to imagine higher dimensional spaces: One dimension is like a street, in which each house only has one number. Two dimensions is like a flat city, in which each address has two numbers, a street and an avenue. Three dimensions is like a city with buildings, in which each address has three numbers: a street, an avenue, and a floor. Four dimensions is like an imaginary place in which each address has four numbers. We can imagine higher dimensions as another imaginary city in which addresses have as many coordinates as we need.](https://drek4537l1klr.cloudfront.net/serrano/Figures/2-8.png)

#### [](/book/grokking-machine-learning/chapter-2/)Other ways of simplifying our data: Matrix factorization and singular value decomposition

It[](/book/grokking-machine-learning/chapter-2/)[](/book/grokking-machine-learning/chapter-2/)[](/book/grokking-machine-learning/chapter-2/)[](/book/grokking-machine-learning/chapter-2/) seems that clustering and dimensionality reduction are nothing like each other, but, in reality, they are not so different. If we have a table full of data, each row corresponds to a data point, and each column corresponds to a feature. Therefore, we can use clustering to reduce the number of rows in our dataset and dimensionality reduction to reduce the number of columns, as figures 2.9 and 2.10 illustrate.

![Figure 2.9 Clustering can be used to simplify our data by reducing the number of rows in our dataset by grouping several rows into one.](https://drek4537l1klr.cloudfront.net/serrano/Figures/2-9.png)

![Figure 2.10 Dimensionality reduction can be used to simplify our data by reducing the number of columns in our dataset.](https://drek4537l1klr.cloudfront.net/serrano/Figures/2-10.png)

You may be wondering, is there a way that we can reduce both the rows and the columns at the same time? And the answer is yes! Two common ways we can do this are *matrix factorization**[](/book/grokking-machine-learning/chapter-2/)* and *singular value decomposition**[](/book/grokking-machine-learning/chapter-2/)*. These two algorithms express a big matrix of data into a product of smaller matrices.

Places like Netflix use matrix factorization extensively to generate recommendations. Imagine a large table where each row corresponds to a user, each column to a movie, and each entry in the matrix is the rating that the user gave the movie. With matrix factorization, one can extract certain features, such as type of movie, actors appearing in the movie, and others, and be able to predict the rating that a user gives a movie, based on these features.

Singular value decomposition is used in image compression. For example, a black-and-white image can be seen as a large table of data, where each entry contains the intensity of the corresponding pixel. Singular value decomposition uses linear algebra techniques to simplify this table of data, thus allowing us to simplify the image and store its simpler version using fewer [](/book/grokking-machine-learning/chapter-2/)entries.

#### [](/book/grokking-machine-learning/chapter-2/)Generative machine learning

*Generative**[](/book/grokking-machine-learning/chapter-2/)[](/book/grokking-machine-learning/chapter-2/)[](/book/grokking-machine-learning/chapter-2/)* *machine learning* is one of the most astonishing fields of machine learning. If you have seen ultra-realistic faces, images, or videos created by computers, then you have seen generative machine learning in action.

The field of generative learning consists of models that, given a dataset, can output new data points that look like samples from that original dataset. These algorithms are forced to learn how the data looks to produce similar data points. For example, if the dataset contains images of faces, then the algorithm will produce realistic-looking faces. Generative algorithms have been able to create tremendously realistic images, paintings, and so on. They have also generated video, music, stories, poetry, and many other wonderful things. The most popular generative algorithm is generative adversarial networks[](/book/grokking-machine-learning/chapter-2/) (GANs), developed by Ian Goodfellow and his coauthors. Other useful and popular generative algorithms are variational autoencoders, developed by Kingma and Welling, and restricted Boltzmann machines[](/book/grokking-machine-learning/chapter-2/) (RBMs), developed by Geoffrey Hinton.

As you can imagine, generative learning is quite hard. For a human, it is much easier to determine if an image shows a dog than it is to draw a dog. This task is just as hard for computers. Thus, the algorithms in generative learning are complicated, and lots of data and computing power are needed to make them work well. Because this book is on supervised learning, we won’t cover generative learning in detail, but in chapter 10, we get an idea of how some of these generative algorithms work, because they tend to use neural networks. Appendix C contains recommendations of resources, including a video by the author, if you’d like to explore this topic further.

## [](/book/grokking-machine-learning/chapter-2/)What is reinforcement learning?

Reinforcement[](/book/grokking-machine-learning/chapter-2/)[](/book/grokking-machine-learning/chapter-2/) learning is a different type of machine learning in which no data is given, and we must get the computer to perform a task. Instead of data, the model receives an environment and an agent who is supposed to navigate in this environment. The agent has a goal or a set of goals. The environment has rewards and punishments that guide the agent to make the right decisions to reach its goal. This all sounds a bit abstract, but let’s look at an example.

#### Example: Grid world

In[](/book/grokking-machine-learning/chapter-2/) figure 2.11, we see a grid world with a robot at the bottom-left corner. That is our agent. The goal is to get to the treasure chest in the top right of the grid. In the grid, we can also see a mountain, which means we cannot go through that square, because the robot cannot climb mountains. We also see a dragon, which will attack the robot, should the robot dare to land in its square, which means that part of our goal is to not land over there. This is the game. And to give the robot information about how to proceed, we keep track of a score. The score starts at zero. If the robot gets to the treasure chest, then we gain 100 points. If the robot reaches the dragon, we lose 50 points. And to make sure our robot moves quickly, we can say that for every step the robot makes, we lose 1 point, because the robot loses energy as it walks.

![Figure 2.11 A grid world in which our agent is a robot. The goal of the robot is to find the treasure chest, while avoiding the dragon. The mountain represents a place through which the robot can’t pass.](https://drek4537l1klr.cloudfront.net/serrano/Figures/2-11.png)

The way to train this algorithm, in very rough terms, follows: The robot starts walking around, recording its score and remembering what steps took it there. After some point, it may meet the dragon, losing many points. Therefore, it learns to associate the dragon square and the squares close to it with low scores. At some point it may also hit the treasure chest, and it learns to start associating that square and the squares close to it to high scores. After playing this game for a long time, the robot will have a good idea of how good each square is, and it can take the path following the squares all the way to the treasure chest. Figure 2.12 shows a possible path, although this one is not ideal, because it passes too close to the dragon. Can you think of a better one?

![Figure 2.12 Here is a path that the robot could take to find the treasure chest.](https://drek4537l1klr.cloudfront.net/serrano/Figures/2-12.png)

Of course, this is a very brief explanation, and there is a lot more to reinforcement learning. Appendix C recommends some resources for further study, including a deep reinforcement learning video.

Reinforcement learning has numerous cutting-edge applications, including the following:

- **Games****[](/book/grokking-machine-learning/chapter-2/)**: recent advances in teaching computers how to win at games, such as Go or chess, use reinforcement learning. Also, agents have been taught to win at Atari games such as *Breakout* or *Super Mario*.
- **Robotics****[](/book/grokking-machine-learning/chapter-2/)**: reinforcement learning is used extensively to help robots carry out tasks such as picking up boxes, cleaning a room, or even dancing!
- **Self-driving cars**: reinforcement learning techniques are used to help the car carry out many tasks such as path planning or behaving in particular environments.

## [](/book/grokking-machine-learning/chapter-2/)Summary

- Several types of machine learning exist, including supervised learning, unsupervised learning, and reinforcement learning.
- Data can be labeled or unlabeled. Labeled data contains a special feature, or label, that we aim to predict. Unlabeled data doesn’t contain this feature.
- Supervised learning is used on labeled data and consists of building models that predict the labels for unseen data.
- Unsupervised learning is used on unlabeled data and consists of algorithms that simplify our data without losing a lot of information. Unsupervised learning is often used as a preprocessing step.
- Two common types of supervised learning algorithms are called regression and classification.

- Regression models are those in which the answer is any number.
- Classification models are those in which the answer is of a type or a class.

- Two common types of unsupervised learning algorithms are clustering and dimensionality reduction.

- Clustering is used to group data into similar clusters to extract information or make it easier to handle.
- Dimensionality reduction is a way to simplify our data, by joining certain similar features and losing as little information as possible.
- Matrix factorization and singular value decomposition are other algorithms that can simplify our data by reducing both the number of rows and columns.

- Generative machine learning is an innovative type of unsupervised learning, consisting of generating data that is similar to our dataset. Generative models can paint realistic faces, compose music, and write poetry.
- Reinforcement learning is a type of machine learning in which an agent must navigate an environment and reach a goal. It is extensively used in many cutting-edge applications.

## [](/book/grokking-machine-learning/chapter-2/)Exercises

#### Exercise 2.1

For each of the following scenarios, state if it is an example of supervised or unsupervised learning. Explain your answers. In cases of ambiguity, pick one, and explain why you picked it.

1. A recommendation system on a social network that recommends potential friends to a user
1. A system in a news site that divides the news into topics
1. The Google autocomplete feature for sentences
1. A recommendation system on an online retailer that recommends to users what to buy based on their past purchasing history
1. A system in a credit card company that captures fraudulent transactions

#### Exercise 2.2

For each of the following applications of machine learning, would you use regression or classification to solve it? Explain your answers. In cases of ambiguity, pick one, and explain why you picked it.

1. An online store predicting how much money a user will spend on their site
1. A voice assistant decoding voice and turning it into text
1. Selling or buying stock from a particular company
1. YouTube recommending a video to a user

#### Exercise 2.3

Your task is to build a self-driving car. Give at least three examples of machine learning problems that you would have to solve to build it. In each example, explain if you are using supervised/unsupervised learning, and, if supervised, whether you are using regression or classification. If you are using other types of machine learning, explain which ones, and why.
