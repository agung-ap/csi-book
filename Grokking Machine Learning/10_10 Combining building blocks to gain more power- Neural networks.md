# [](/book/grokking-machine-learning/chapter-10/)10 Combining building blocks to gain more power: Neural networks

### In this chapter

- what is a neural network
- the architecture of a neural network: nodes, layers, depth, and activation functions
- training neural networks using backpropagation
- potential problems in training neural networks, such as the vanishing gradient problem and overfitting
- techniques to improve neural network training, such as regularization and dropout
- using Keras to train neural networks for sentiment analysis and image classification
- using neural networks as regression models

![](https://drek4537l1klr.cloudfront.net/serrano/Figures/10-unnumb-1.png)

[](/book/grokking-machine-learning/chapter-10/)In this chapter, we learn *neural networks*, also called *multilayer perceptrons**[](/book/grokking-machine-learning/chapter-10/)*. Neural networks are one of the most popular (if not the most popular) machine learning models out there. They are so useful that the field has its own name: *deep learning**[](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/)*. Deep learning has numerous applications in the most cutting-edge areas of machine learning, including image recognition, natural language processing, medicine, and self-driving cars. Neural networks are meant to, in a broad sense of the word, mimic how the human brain operates. They can be very complex, as figure 10.1 shows.

![Figure 10.1 A neural network. It may look complicated, but in the next few pages, we will demystify this image.](https://drek4537l1klr.cloudfront.net/serrano/Figures/10-1.png)

The neural network in figure 10.1 may look scary with lots of nodes, edges, and so on. However, we can understand neural networks in much simpler ways. One way to see them is as a collection of perceptrons (which we learned in chapters 5 and 6). I like to see neural networks as compositions of linear classifiers that give rise to nonlinear classifiers. In low dimensions, the linear classifiers would look like lines or planes, and the nonlinear classifiers would look like complicated curves or surfaces. In this chapter, we discuss the intuition behind neural networks and the details about how they work, and we also code neural networks and use them for several applications such as image recognition.

Neural networks are useful for classification and regression. In this chapter, we focus mostly on classification neural networks, but we also learn the small changes needed to make them work for regression. First, a bit of terminology. Recall that in chapter 5, we learned the perceptron, and in chapter 6, we learned the logistic classifier. We also learned that they are called the discrete and continuous perceptrons. To refresh your memory, the output of the discrete perceptron is either 0 or 1, and the output of a continuous perceptron is any number in the interval (0,1). To calculate this output, the discrete perceptron uses the step function (the section “The step function and activation functions” in chapter 5), and the continuous perceptron uses the sigmoid function (the section “A probability approach to classification: The sigmoid function” in chapter 6). In this chapter, we refer to both classifiers as perceptrons, and when needed, we specify whether we are talking about a discrete or a continuous perceptron.

The code for this chapter is available in this GitHub repository: [https://github.com/luisguiserrano/manning/tree/master/Chapter_10_Neural_Networks](https://github.com/luisguiserrano/manning/tree/master/Chapter_10_Neural_Networks)[](/book/grokking-machine-learning/chapter-10/).

## [](/book/grokking-machine-learning/chapter-10/)Neural networks with an example: A more complicated alien planet

In[](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/) this section, we learn what a neural network is using a familiar sentiment analysis example from chapters 5 and 6. The scenario is the following: we find ourselves on a distant planet populated by aliens. They seem to speak a language formed by two words, *aack* and *beep*, and we want to build a machine learning model that helps us determine whether an alien is happy or sad based on the words they say. This is called sentiment analysis, because we need to build a model to analyze the sentiment of the aliens. We record some aliens talking and manage to identify by other means whether they are happy or sad, and we come up with the dataset shown in in table 10.1.

##### Table 10.1 Our dataset, in which each row represents an alien. The first column represents the sentence they uttered. The second and third columns represent the number of appearances of each of the words in the sentence. The fourth column represents the alien’s mood.[(view table figure)](https://drek4537l1klr.cloudfront.net/serrano/HighResolutionFigures/table_10-1.png)

| Sentence | Aack | Beep | Mood |
| --- | --- | --- | --- |
| “*Aack*” | 1 | 0 | Sad |
| “*Aack aack*” | 2 | 0 | Sad |
| “*Beep*” | 0 | 1 | Sad |
| “*Beep beep*” | 0 | 2 | Sad |
| “*Aack beep*” | 1 | 1 | Happy |
| “*Aack aack beep*” | 2 | 1 | Happy |
| “*Beep aack beep*” | 1 | 2 | Happy |
| “*Beep aack beep aack*” | 2 | 2 | Happy |

This looks like a nice enough dataset, and we should be able to fit a classifier to this data. Let’s plot it first, as shown in figure 10.2.

![Figure 10.2 The plot of the dataset in table 10.1. The horizontal axis corresponds to the number of appearances of the word aack, and the vertical axis to the number of appearances of the word beep. The happy faces correspond to the happy aliens, and the sad faces to the sad aliens.](https://drek4537l1klr.cloudfront.net/serrano/Figures/10-2.png)

From figure 10.2, it looks like we won’t be able to fit a linear classifier to this data. In other words, drawing a line that splits the happy and the sad faces apart would be impossible. What can we do? We’ve learned other classifiers that can do the job, such as the naive Bayes classifier (chapter 8) or decision trees (chapter 9). But in this chapter, we stick with perceptrons. If our goal is to separate the points in figure 10.2, and one line won’t do it, what then is better than one line? What about the following:

1. Two lines
1. A curve

These are examples of neural networks. Let’s begin by seeing why the first one, a classifier using two lines, is a neural network.

#### [](/book/grokking-machine-learning/chapter-10/)Solution: If one line is not enough, use two lines to classify your dataset

In[](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/) this section, we explore a classifier that uses two lines to split the dataset. We have many ways to draw two lines to split this dataset, and one of these ways is illustrated in figure 10.3. Let’s call them line 1 and line 2.

![Figure 10.3 The happy and the sad points in our dataset cannot be divided by one line. However, drawing two lines separates them well—the points above both lines can be classified as happy, and the remaining points as sad. Combining linear classifiers this way is the basis for neural networks.](https://drek4537l1klr.cloudfront.net/serrano/Figures/10-3.png)

We can define our classifier as follows:

#### Sentiment analysis classifier

A[](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/) sentence is classified as happy if its corresponding point is above the two lines shown in figure 10.3. If it is below at least one of the lines, it is classified as sad.

Now, let’s throw in some math. Can we think of two equations for these lines? Many equations would work, but let’s use the following two (where *x*a is the number of times the word *aack* appears in the sentence, and *x*b is the number of times *beep* appears).

- Line 1: 6*x*a + 10*x*b – 15 = 0
- Line 2: 10*x*a + 6*x*b – 15 = 0

##### aside: How did WE find these equations?

Notice that line 1 passes through the points (0, 1.5) and (2.5, 0). Therefore, the slope, defined as the change in the horizontal axis divided by the change in the vertical axis, is precisely
. The *y*-intercept—namely, the height at which the line crosses the vertical axis—is 1.5. Therefore, the equation of this line is
. By manipulating this equation, we get 6*x*a + 10*x*b – 15 = 0. We can take a similar approach to find the equation for line 2.

Therefore, our classifier becomes the following:

#### Sentiment analysis classifier

A sentence is classified as happy if both of the following two inequalities hold:

- **Inequality 1**: 6*x*a + 10*x*b – 15 ≥ 0
- **Inequality 2**: 10*x*a + 6*x*b **–** 15 ≥ 0

If at least one of them fails, then the sentence is classified as sad.

As a consistency check, table 10.2 contains the values of each of the two equations. At the right of each equation, we check whether the equation’s value is larger than or equal to 0. The right-most column checks whether both values are larger than or equal to 0.

##### Table 10.2 The same dataset as in table 10.1, but with some new columns. The fourth and the sixth columns correspond to our two lines. The fifth and seventh column check if the equation of each of the lines at each of the data points gives a non-negative value. The last column checks if the two values obtained are both non-negative.[(view table figure)](https://drek4537l1klr.cloudfront.net/serrano/HighResolutionFigures/table_10-2.png)

| Sentence | Aack | Beep | Equation 1 | Equation 1 ≥ 0? | Equation 2 | Equation 2 ≥ 0? | Both equations ≥ 0 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| “*Aack*” | 1 | 0 | –9 | No | –5 | No | No |
| “*Aack aack*” | 2 | 0 | –3 | No | 5 | Yes | No |
| “*Beep*” | 0 | 1 | –5 | No | –9 | No | No |
| “*Beep beep*” | 0 | 2 | 5 | Yes | 3 | No | No |
| “*Aack beep*” | 1 | 1 | 1 | Yes | 1 | Yes | Yes |
| “*Aack aack beep*” | 1 | 2 | 11 | Yes | 7 | Yes | Yes |
| “*Beep aack beep*” | 2 | 1 | 7 | Yes | 11 | Yes | Yes |
| “*Beep aack beep aack*” | 2 | 2 | 17 | Yes | 17 | Yes | Yes |

Note that the right-most column in table 10.2 (yes/no) coincides with the right-most column in table 10.1 (happy/sad). This means the classifier managed to classify all the data correct[](/book/grokking-machine-learning/chapter-10/)ly.

#### [](/book/grokking-machine-learning/chapter-10/)Why two lines? Is happiness not linear?

In chapters 5 and 6, we managed to infer things about the language based on the equations of the classifiers. For example, if the weight of the word *aack* was positive, we concluded that it was likely a happy word. What about now? Could we infer anything about the language in this classifier that contains two equations?

The way we could think of two equations is that maybe on the alien planet, happiness is not a simple linear thing but is instead based on two things. In real life, happiness can be based on many things: it can be based on having a fulfilling career combined with a happy family life and food on the table. It could be based on having coffee and a doughnut. In this case, let’s say that the two aspects of happiness are career and family. For an alien to be happy, it needs to have *both*.

It turns out that in this case, both career happiness and family happiness are simple linear classifiers, and each is described by one of the two lines. Let’s say that line 1 corresponds to career happiness and line 2 to family happiness. Thus, we can think of alien happiness as the diagram in figure 10.4. In this diagram, career happiness and family happiness are joined by an AND operator[](/book/grokking-machine-learning/chapter-10/), which checks whether both are true. If they are, then the alien is happy. If any of them fails, the alien is unhappy.

![Figure 10.4 The happiness classifier is formed by the career happiness classifier, the family happiness classifier, and an AND operator. If both the career and family happiness classifiers output a Yes, then so does the happiness classifier. If any of them outputs a No, then the happiness classifier also outputs a No.](https://drek4537l1klr.cloudfront.net/serrano/Figures/10-4.png)

The family and career happiness classifiers are both perceptrons, because they are given by the equation of a line. Can we turn this AND operator into another perceptron? The answer is yes, and we’ll see how in the next subsection.

Figure 10.4 is starting to look like a neural network. Just a few more steps and a little bit more math, and we’ll get to something looking much more like figure 10.1 at the beginning of the c[](/book/grokking-machine-learning/chapter-10/)hapter.

#### [](/book/grokking-machine-learning/chapter-10/)Combining the outputs of perceptrons into another perceptron

Figure 10.4[](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/) hints at a combination of perceptrons, in which we plug in the outputs of two perceptrons as inputs into a third perceptron. This is how neural networks are built, and in this section, we see the math behind it.

In the section “The step function and activation functions” in chapter 5, we defined the step function, which returns 0 if the input is negative and 1 if the input is positive or zero. Notice that because we are using the step function, these are discrete perceptrons. Using this function, we can define the family and career happiness classifiers as follows:

#### Career happiness classifier

Weights:

- *Aack*: 6
- *Beep*: 10

**Bias**: –15

**Score of a sentence**: 6*x*a + 10*x*b – 15

**Prediction**: *F* = *step*(6*x*a + 10*x*b – 15)

#### Family happiness classifier

Weights:

- *Aack*: 10
- *Beep*: 6

**Bias**: –15

**Score of a sentence**: 10*x*a+6*x*b – 15

**Prediction**: *C* = *step*(10*x*a+6*x*b – 15)

The [](/book/grokking-machine-learning/chapter-10/)next step is to plug the outputs of the career and family happiness classifiers into a new happiness classifier. Try verifying that the following classifier works. Figure 10.5 contains two tables with the outputs of the career and family classifiers, and a third table in which the first two columns are the outputs of the career and family classifier, and the last column is the output of the happiness classifier. Each of the tables in figure 10.5 corresponds to a perceptron.

![Figure 10.5 Three perceptron classifiers, one for career happiness, one for family happiness, and one for happiness, which combines the two previous ones. The outputs of the career and family perceptrons are inputs into the happiness perceptron.](https://drek4537l1klr.cloudfront.net/serrano/Figures/10-5.png)

#### Happiness classifier

Weights:

- Career: 1
- Family: 1

**Bias**: –1.5

**Score of a sentence**: 1 · *C* + 1 · *F* – 1.5

**Prediction**: *ŷ* = *step*(1 · *C* + 1 · *F* – 1.5)

This combination of classifiers is a neural network. Next, we see how to make this look like the image [](/book/grokking-machine-learning/chapter-10/)in figur[](/book/grokking-machine-learning/chapter-10/)e 10.1.

#### [](/book/grokking-machine-learning/chapter-10/)A graphical representation of perceptrons

In[](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/) this section, I show you how to represent perceptrons graphically, which gives rise to the graphical representation of neural networks. We call them neural networks because their basic unit, the perceptron, vaguely resembles a neuron.

A neuron comprises three main parts: the soma, the dendrites, and the axon. In broad terms, the neuron receives signals coming from other neurons through the dendrites, processes them in the soma, and sends a signal through the axon to be received by other neurons. Compare this to a perceptron, which receives numbers as inputs, applies a mathematical operation to them (normally consisting of a sum composed with an activation function), and outputs a new number. This process is illustrated in figure 10.6.

![Figure 10.6 A perceptron is loosely based on a neuron. Left: A neuron with its main components: the dendrites, the soma, and the axon. Signals come in through the dendrites, get processed in the soma, and get sent to other neurons through the axon. Right: A perceptron. The nodes in the left correspond to numerical inputs, the node in the middle performs a mathematical operation and outputs a number.](https://drek4537l1klr.cloudfront.net/serrano/Figures/10-6.png)

[](/book/grokking-machine-learning/chapter-10/)More formally, recall the definition of a perceptron from chapters 5 and 6, in which we had the following entities:

- **Inputs**: *x*1, *x*2, …, *x*n
- **Weights**: *w*1, *w*2, …, *w*n
- **Bias**: *b*
- **An activation function**: Either the step function (for discrete perceptrons) or the sigmoid function (for continuous perceptrons). (Later in this chapter we learn other new activation functions.)
- **A prediction**: Defined by the formula *ŷ* = *f*(*w*1 *x*1 + *w*2 *x*2 + … + *w*n *x*n + *b*), where *f* is the corresponding activation function

The way these are located in the diagram is illustrated in figure 10.7. On the left, we have the input nodes, and on the right, we have the output node. The input variables go on the input nodes. The final input node doesn’t contain a variable, but it contains a value of 1. The weights are located on the edges connecting the input nodes with the output node. The weight corresponding to the final input node is the bias. The mathematical operations for calculating the prediction happen inside the output node, and this node outputs the prediction.

For example, the perceptron defined by the equation *ŷ* = *σ*(3*x*1 – 2*x*2 + 4*x*3 + 2) is illustrated in figure 10.7. Notice that in this perceptron, the following steps are performed:

- The inputs are multiplied with their corresponding weights and added to obtain 3*x*1 – 2*x*2 + 4*x*3.
- The bias is added to the previous equation, to obtain 3*x*1 – 2*x*2 + 4*x*3 + 2.
- The sigmoid activation function is applied to obtain the output *ŷ* = *σ*(3*x*1 – 2*x*2 + 4*x*3 + 2).

![Figure 10.7 A visual representation of a perceptron. The inputs (features and bias) appear as nodes on the left, and the weights and bias are on the edges connecting the input nodes to the main node in the middle. The node in the middle takes the linear combination of the weights and the inputs, adds the bias, and applies the activation function, which in this case is the sigmoid function. The output is the prediction given by the formula ŷ = σ(3x1 – 2x2 + 4x3 + 2).](https://drek4537l1klr.cloudfront.net/serrano/Figures/10-7.png)

For example, if the input to this perceptron is the point (*x*1, *x*2, *x*3) = (1, 3, 1), then the output is *σ*(3 · 1 – 2 · 3 + 4 · 1 + 2) = *σ*(3) = 0.953.

If this perceptron was defined using the step function instead of the sigmoid function, the output would be *step*(3 · 1 – 2 · 3 + 4 · 1 + 2) = *step*(3) = 1.

This graphical representation makes perceptrons easy to concatenate, as we see in the next section.

#### [](/book/grokking-machine-learning/chapter-10/)A gra[](/book/grokking-machine-learning/chapter-10/)phical representation of neural networks

As [](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/)we saw in the previous section, a neural network is a concatenation of perceptrons. This structure is meant to loosely emulate the human brain, in which the output of several neurons becomes the input to another neuron. In the same way, in a neural network, the output of several perceptrons becomes the input of another perceptron, as illustrated in figure 10.8.

![Figure 10.8 Neural networks are meant to (loosely) emulate the structure of the brain. Left: The neurons are connected inside the brain in a way that the output of a neuron becomes the input to another neuron. Right: The perceptrons are connected in a way that the output of a perceptron becomes the input to another perceptron.](https://drek4537l1klr.cloudfront.net/serrano/Figures/10-8.png)

The neural network we built in the previous section, in which we concatenate the career perceptron and the family perceptron with the happiness perceptron, is illustrated in figure 10.9.

Notice that in the diagram in figure 10.9, the inputs to the career and family perceptrons are repeated. A cleaner way to write this, in which these inputs don’t get repeated, is illustrated in figure 10.10.

Notice that these three perceptrons use the step function. We did this only for educational purposes, because in real life, neural networks never use the step function as an activation function, because it makes it impossible for us to use gradient descent (more on this in the section “Training neural networks”). The sigmoid function, however, is widely used in neural networks, and in the section “Different activation functions,” we learn some other useful activation functions used in practice.

![Figure 10.9 When we connect the outputs of the career and family perceptrons into the happiness perceptron, we get a neural network. This neural network uses the step function as an activation function.](https://drek4537l1klr.cloudfront.net/serrano/Figures/10-9.png)

![Figure 10.10 A cleaned-up version of the diagram in figure 10.9. In this diagram, the features xa and xb, and the bias are not repeated. Instead, each of them connects to both of the nodes at the right, nicely combining the three perceptrons into the same diagram.](https://drek4537l1klr.cloudfront.net/serrano/Figures/10-10.png)

#### [](/book/grokking-machine-learning/chapter-10/)The bo[](/book/grokking-machine-learning/chapter-10/)undary of a neural network

In[](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/) chapters 5 and 6, we studied the boundaries of perceptrons, which are given by lines. In this section, we see what the boundaries of neural networks look like.

Recall from chapters 5 and 6 that both the discrete perceptron and the continuous perceptron (logistic classifier) have a linear boundary given by the linear equation defining them. The discrete perceptron assigns predictions of 0 and 1 to the points according to what side of the line they are. The continuous perceptron assigns a prediction between 0 and 1 to every point in the plane. The points over the line get a prediction of 0.5, the points on one side of the line get predictions higher than 0.5, and the points on the other side get predictions lower than 0.5. Figure 10.11 illustrates the discrete and continuous perceptrons corresponding to the equation 10*x*a + 6*x*b – 15 = 0.

![Figure 10.11 The boundary of a perceptron is a line. Left: For a discrete perceptron, the points on one side of the line are given a prediction of 0, and the points on the other side a prediction of 1. Right: For a continuous perceptron, the points are all given a prediction in the interval (0,1). In this example, the points at the very left get predictions close to 0, those at the very right get predictions close to 1, and those over the line get predictions of 0.5.](https://drek4537l1klr.cloudfront.net/serrano/Figures/10-111.png)

We can also visualize the output of a neural network in a similar way. Recall that the output of the neural network with the step activation function is the following:

- If 6*x*a + 10*x*b – 15 ≥ 0 and 10*x*a + 6*x*b – 15 ≥ 0, then the output is 1.
- Otherwise, the output is 0.

This boundary is illustrated in the left side of figure 10.12 using two lines. Notice that it’s expressed as a combination of the boundaries of the two input perceptrons and the bias node. The boundary obtained with the step activation function is made by broken lines, whereas the one obtained with the sigmoid activation function is a curve.

To study these boundaries more carefully, check the following notebook: [https://github.com/luisguiserrano/manning/blob/master/Chapter_10_Neural_Networks/Plotting_Boundaries.ipynb](https://github.com/luisguiserrano/manning/blob/master/Chapter_10_Neural_Networks/Plotting_Boundaries.ipynb). In this notebook, the boundaries of the two lines and the two neural networks are plotted with the step and sigmoid activation functions, as illustrated in figure 10.13.

![Figure 10.12 To build a neural network, we use the outputs of two perceptrons and a bias node (represented by a classifier that always outputs a value of 1) to a third perceptron. The boundary of the resulting classifier is a combination of the boundaries of the input classifiers. On the left, we see the boundary obtained using the step function, which is a broken line. On the right, we see the boundary obtained using the sigmoid function, which is a curve.](https://drek4537l1klr.cloudfront.net/serrano/Figures/10-12.png)

![Figure 10.13 The plots of the boundaries of the classifiers. Top: The two linear classifiers, the career (left) and family (right) classifiers. Bottom: The two neural networks, using the step function (left) and the sigmoid function (right).](https://drek4537l1klr.cloudfront.net/serrano/Figures/10-13.png)

Note that the neural network with the sigmoid activation function actually doesn’t fit the entire dataset well, because it misclassifies the point (1,1), as shown in the bottom right of figure 10.13. Try changing the weights in a way that it fits this point well. (See exercise 10.3 at the end of the chapter).

#### [](/book/grokking-machine-learning/chapter-10/)The gener[](/book/grokking-machine-learning/chapter-10/)al architecture of a fully connected neural network

In[](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/) the previous sections, we saw an example of a small neural network, but in real life, neural networks are much larger. The nodes are arranged in layers, as illustrated in figure 10.14. The first layer is the input layer, the final layer is the output layer, and all the layers in between are called the hidden layers. The arrangement of nodes and layers is called the *architecture* of the neural network. The number of layers (excluding the input layer) is called the *depth* of the neural network. The neural network in figure 10.14 has a depth of 3, and the following architecture:

- An input layer of size 4
- A hidden layer of size 5
- A hidden layer of size 3
- An output layer of size 1

![Figure 10.14 The general architecture of a neural network. The nodes are divided into layers, where the leftmost layer is the input layer, the rightmost layer is the output layer, and all the layers in between are hidden layers. All the nodes in a layer are connected to all the (non-bias) nodes in the next layer.](https://drek4537l1klr.cloudfront.net/serrano/Figures/10-14.png)

Neural networks are often drawn without the bias nodes, but it is assumed they are part of the architecture. However, we don’t count bias nodes in the architecture. In other words, the size of a layer is the number of non-bias nodes in that layer.

Notice that in the neural network in figure 10.14, every node in a layer is connected to every (non-bias) node in the next layer. Furthermore, no connections happen between nonconsecutive layers. This architecture is called *fully connected*. For some applications, we use different architectures where not all the connections are there, or where some nodes are connected between nonconsecutive layers—see the section “Other architectures for more complex dialects” to read about some of them. However, in this chapter, all the neural networks we build are fully connected.

Picture the boundary of a neural network like the one shown in figure 10.15. In this diagram, you can see the classifier corresponding to each node. Notice that the first hidden layer is formed by linear classifiers, and the classifiers in each successive layer are slightly more complex than those in the previous ones.

![Figure 10.15 The way I like to visualize neural networks. Each of the nodes corresponds to a classifier, and this classifier has a well-defined boundary. The nodes in the first hidden layer all correspond to linear classifiers (perceptrons), so they are drawn as lines. The boundaries of the nodes in each layer are formed by combining the boundaries from the previous layer. Therefore, the boundaries get more and more complex in each hidden layer. In this diagram, we have removed the bias nodes.](https://drek4537l1klr.cloudfront.net/serrano/Figures/10-15.png)

A great tool to play with to understand neural networks is TensorFlow Playground, which can be found at [https://playground.tensorflow.org](https://playground.tensorflow.org). Several graphical datasets are available there, and it is possible to train neural networks with different architectures and hyperparameters.

## [](/book/grokking-machine-learning/chapter-10/)Training neural networks

In[](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/) this chapter, we’ve seen how neural networks look in general and that they’re not as mysterious as they sound. How do we train one of these monsters? In theory, the process is not complicated, although it can be computationally expensive. We have several tricks and heuristics we can use to speed it up. In this section, we learn this training process. Training a neural network is not that different from training other models, such as the perceptron or the logistic classifier. We begin by initializing all the weights and biases at random. Next, we define an error function to measure the performance of the neural network. Finally, we repeatedly use the error function to tune in the weights and biases of the model to reduce the error function[](/book/grokking-machine-learning/chapter-10/).

#### [](/book/grokking-machine-learning/chapter-10/)Error function: A way to measure how the neural network is performing

In [](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/)this section, we learn about the error function used to train neural networks. Luckily, we’ve seen this function before—the log-loss function from the section “Logistic classifiers” in chapter 6. Recall that the formula for the log loss is

*log loss* = –*y* *ln*(*ŷ*) – (1 – *y*) *ln*(1 – *ŷ*),

where *y* is the label and *ŷ* the prediction.

As a refresher, a good reason for using log loss for classification problems is that it returns a small value when the prediction and the label are close and a large value when they are fa[](/book/grokking-machine-learning/chapter-10/)r.

#### [](/book/grokking-machine-learning/chapter-10/)Backpropagation: The key step in training the neural network

In[](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/) this section, we learn the most important step in the process of training a neural network. Recall that in chapters 3, 5, and 6 (linear regression, perceptron algorithm, and logistic regression), we used gradient descent to train our models. This is also the case for neural networks. The training algorithm is called the *backpropagation algorithm*, and its pseudocode fo[](/book/grokking-machine-learning/chapter-10/)llows:

#### Pseudocode for the backpropagation algorithm

- Initialize[](/book/grokking-machine-learning/chapter-10/) the neural network with random weights and biases.
- Repeat many times:

- Calculate the loss function and its gradient (namely, the derivatives with respect to each one of the weights and biases).
- Take a small step in the direction opposite to the gradient to decrease the loss function by a small amount.

- The weights you obtain correspond to a neural network that (likely) fits the data well.

The loss function of a neural network is complicated, because it involves the logarithm of the prediction, and the prediction itself is a complicated function. Furthermore, we need to calculate the derivative with respect to many variables, corresponding to each of the weights and biases of the neural network. In appendix B, “Using gradient descent to train neural networks,” we go over the mathematical details of the backpropagation algorithm for a neural network with one hidden layer or arbitrary size. See some recommended resources in appendix C to go deep into the math of backpropagation for deeper neural networks. In practice, great packages, such as Keras, TensorFlow, and PyTorch, have implemented this algorithm with great speed and performance.

Recall that when we learned linear regression models (chapter 3), discrete perceptrons (chapter 5), and continuous perceptrons (chapter 6), the process always had a step where we moved a line in the way we needed to model our data well. This type of geometry is harder to visualize for neural networks, because it happens in much higher dimensions. However, we can still form a mental picture of backpropagation, and for this, we need to focus on only one of the nodes of the neural network and one data point. Imagine a classifier like the one on the right in figure 10.16. This classifier is obtained from the three classifiers on the left (the bottom one corresponds to the bias, which we represent by a classifier that always returns a prediction of 1). The resulting classifier misclassifies the point, as is shown. From the three input classifiers, the first one classifies the point well, but the other two don’t. Thus, the backpropagation step will increase the weight on the edge corresponding to the top classifier and decrease those corresponding to the two classifiers at the bottom. This ensures the resulting classifier will look more like the top one, and thus, its classification for the point will improve.

![Figure 10.16 A mental picture of backpropagation. At each step of the training process, the weights of the edges are updated. If a classifier is good, its weight gets increased by a small amount, and if it is bad, its weight gets decreased.](https://drek4537l1klr.cloudfront.net/serrano/Figures/10-16.png)

#### [](/book/grokking-machine-learning/chapter-10/)Potential problems: From overfitting to vanishing gradients

In[](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/) practice, neural networks work very well. But, due to their complexity, many problems arise with their training. Luckily, we can have a solution for the most pressing ones. One problem that neural networks have is overfitting—really big architectures can potentially memorize our data without generalizing it well. In the next section, we see some techniques to reduce overfitting when training neural networks.

Another serious problem that neural networks can have is vanishing gradients. Notice that the sigmoid function is very flat on the ends, which signifies that the derivatives (tangents to the curve) are too flat (see figure 10.17). This means their slopes are very close to zero.

![Figure 10.17 The sigmoid function is flat at the ends, which means that for large positive and negative values, its derivative is very small, hampering the training.](https://drek4537l1klr.cloudfront.net/serrano/Figures/10-17.png)

During the backpropagation process, we compose many of these sigmoid functions (which means we plug in the output of a sigmoid function as the input to another sigmoid function repeatedly). As expected, this composition results in derivatives that are very close to zero, which means the steps taken during backpropagation are tiny. If this is the case, it may take us a very long time to get to a good classifier, which is a problem.

We have several solutions to the vanishing gradient problem, and so far one of the most effective ones is to change the activation function. In the section “Different activation functions,” we learn some new activation functions to help us deal with the vanishing gradi[](/book/grokking-machine-learning/chapter-10/)ent problem.

#### [](/book/grokking-machine-learning/chapter-10/)Techniques for training neural networks: Regularization and dropout

As[](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/) mentioned in the previous section, neural networks are prone to overfitting. In this section, we discuss some techniques to decrease the amount of overfitting during the training of neural networks.

How do we pick the correct architecture? This is a difficult question, with no concrete answer. The rule of thumb is to err on the side of picking a larger architecture than we may need and then apply techniques to reduce the amount of overfitting that your network may have. In some way it is like picking a pair of pants, where the only choices you have are too small or too big. If we pick pants that are too small, there is not much we can do. On the other hand, if we pick pants that are too big, we can wear a belt to make them fit better. It’s not ideal, but it’s all we have for now. Picking the correct architecture based on the dataset is a complicated problem, and a lot of research is currently being done in this direction. To learn more about this, check out the resourc[](/book/grokking-machine-learning/chapter-10/)es in appendix C.

#### Regularization: A way to reduce overfitting by punishing higher weights

As[](/book/grokking-machine-learning/chapter-10/) [](/book/grokking-machine-learning/chapter-10/)we learned in chapter 4, we can use L1 and L2 regularization to decrease overfitting in regression and classification models, and neural networks are no exception. The way one applies regularization in neural networks is the same as one would apply it in linear regression—by adding a regularization term to the error function. If we are doing L1 regularization, the regularization term is equal to the regularization parameter (λ) times the sum of the absolute values of all the weights of our model (not including the biases). If we are doing L2 regularization, then we take the sum of squares instead of absolute values. As an example, the L2 regularization error of the neural network in the example in the section “Neural networks with an example” is

*log loss* + λ *·* (62 + 102 + 102 + 62 + 12 + 12) = *log loss* + 274λ.

#### Dropout: Making sure a few strong nodes are not dominating the training

Dropout [](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/)is an interesting technique used to reduce overfitting in neural networks, and to understand it, let’s consider the following analogy: imagine that we are right-handed, and we like to go to the gym. After some time, we start noticing that our right bicep is growing a lot, but our left one is not. We then start paying more attention to our training and realize that because we are right-handed, we tend to always pick up the weights with the right arm, and we’re not allowing the left arm to do much exercise. We decide that enough is enough, so we take a drastic measure. Some days we decide to tie our right hand to our back and force ourselves to do the entire routine without using the right arm. After this, we start seeing that the left arm starts to grow, as desired. Now, to get both arms to work, we do the following: every day before heading to the gym, we flip two coins, one for each arm. If the left coin falls on heads, we tie the left arm to our back, and if the right arm falls on heads, we tie the right arm to our back. Some days we’ll work with both arms, some days with only one, and some days with none (those are leg days, perhaps). The randomness of the coins will make sure that, on average, we are working both arms almost equally.

Dropout uses this logic, except instead of arms, we are training the weights in the neural network. When a neural network has too many nodes, some of the nodes pick up patterns in the data that are useful for making good predictions, whereas other nodes pick up patterns that are noisy or irrelevant. The dropout process removes some of the nodes randomly at every epoch and performs one gradient descent step on the remaining ones. By dropping some of the nodes at each epoch, it is likely that sometimes we may drop the ones that have picked up the useful patterns, thus forcing the other nodes to pick up the slack.

To be more specific, the dropout process attaches a small probability *p* to each of the neurons. In each epoch of the training process, each neuron is removed with probability *p*, and the neural network is trained only with the remaining ones. Dropout is used only on the hidden layers, not on the input or output layers. The dropout process is illustrated in figure 10.18, where some neurons are removed in each of four epochs of training.

Dropout has had great success in the practice, and I encourage you to use it every time you train a neural network. The packages that we use for training neural networks make it easy to use, as we’ll see lat[](/book/grokking-machine-learning/chapter-10/)er in this chapter.

![Figure 10.18 The dropout process. At different epochs, we pick random nodes to remove from the training to give all the nodes an opportunity to update their weights and not have a few single nodes dominating the training.](https://drek4537l1klr.cloudfront.net/serrano/Figures/10-18.png)

#### [](/book/grokking-machine-learning/chapter-10/)Different activation functions: Hyperbolic tangent (tanh) and the rectified linear unit (ReLU)

As[](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/) we saw in the section “Potential problems,” the sigmoid function is a bit too flat, which causes problems with vanishing gradients. A solution to this problem is to use different activation functions. In this section, we cover two different activation functions that are crucial to improve our training process: the hyperbolic tangent[](/book/grokking-machine-learning/chapter-10/) (tanh) and the[](/book/grokking-machine-learning/chapter-10/) rectified linear unit[](/book/grokking-machine-learning/chapter-10/) (ReLU)

#### Hyperbolic tangent (tanh)

The *hyperbolic tangent* function tends to work better than the sigmoid function in practice, due to its shape, and is given by the following formula:

Tanh is a bit less flat than sigmoid, but it still has a similar shape, as is shown in figure 10.19. It provides an improvement over sigmoid, but it still suffers from the vanishing gradient problem.

![Figure 10.19 Three different activation functions used in neural networks. Left: The sigmoid function, represented by the Greek letter sigma. Middle: The hyperbolic tangent, or tanh. Right: The rectified linear unit, or ReLU.](https://drek4537l1klr.cloudfront.net/serrano/Figures/10-19.png)

#### Rectified linear unit (ReLU)

A much more popular activation that is commonly used in neural networks is the *rectified linear unit*, or ReLU. This one is simple: if the input is negative, the output is zero; otherwise, the output is equal to the input. In other words, it leaves nonnegative numbers alone and turns all the negative numbers into zero. For *x* ≥ 0, *ReLU*(*x*) = *x*, and for *x* < 0, *ReLU*(*x*) = 0. ReLU is a good solution to the vanishing gradient problem, because its derivative is 1 when the input is positive, and thus, it is widely used in large neural networks.

The great thing about these activation functions is that we can combine different ones in the same neural network. In one of the most common architectures, every node uses the ReLU activation function except for the last one, which uses the sigmoid. The reason for this sigmoid at the end is that if our problem is a classification problem, the output of the neural network mus[](/book/grokking-machine-learning/chapter-10/)t be between 0 and 1.

#### [](/book/grokking-machine-learning/chapter-10/)Neural networks with more than one output: The softmax function

So[](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/) far, the neural networks we’ve worked with have had only one output. However, it is not hard to build a neural network that produces several outputs using the softmax function that we learned in the section “Classifying into multiple classes: The softmax function” in chapter 6. The softmax function is a multivariate extension of the sigmoid, and we can use it to turn scores into probabilities.

The best way to illustrate the softmax function is with an example. Imagine that we have a neural network whose job is to determine whether an image contains an aardvark, a bird, a cat, or a dog. In the final layer, we have four nodes, one corresponding to each animal. Instead of applying the sigmoid function to the scores coming from the previous layer, we apply the softmax function to all of them. For example, if the scores are 0, 3, 1, and 1, softmax returns the following:

These results indicate that the neural network strongly believes that the image c[](/book/grokking-machine-learning/chapter-10/)orresponds to a bird.

#### [](/book/grokking-machine-learning/chapter-10/)Hyperparameters

Like [](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/)most machine learning algorithms, neural networks use many hyperparameters that we can fine-tune to get them to work better. These hyperparameters determine how we do our training, namely, how long we want the process to go, at what speed, and how we choose to enter our data into the model. Some of the most important hyperparameters in neural networks follow:

- **Learning rate *η***:: the size of the step that we use during our training
- **Number of epochs**: the number of steps we use for our training
- **Batch vs. mini-batch vs. stochastic gradient descent****[](/book/grokking-machine-learning/chapter-10/)**: how many points at a time enter the training process—namely, do we enter the points one by one, in batches, or all at the same time?
-  **Architecture****[](/book/grokking-machine-learning/chapter-10/)**:

- The number of layers in the neural network
- The number of nodes per layer
- The activation functions used in each node

-  **Regularization parameters****[](/book/grokking-machine-learning/chapter-10/)****:**

- L1 or L2 regularization
- The regularization term λ

- **Dropout probability *p***

We tune these hyperparameters in the same way we tune them for other algorithms, using methods such as grid search. In chapter 13, we elaborate on these methods more[](/book/grokking-machine-learning/chapter-10/) with a real-life example.

## [](/book/grokking-machine-learning/chapter-10/)Coding neural networks in Keras

Now[](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/) that we learned the theory behind neural networks, it’s time to put them in practice! Many great packages have been written for neural networks, such as Keras, TensorFlow, and PyTorch. These three are powerful, and in this chapter, we’ll use Keras due to its simplicity. We’ll build two neural networks for two different datasets. The first dataset contains points with two features and labels of 0 and 1. The dataset is two-dimensional, so we’ll be able to look at the nonlinear boundary created by the model. The second dataset is a common dataset used in image recognition called the MNIST (Modified National Institute of Standards and Technology[](/book/grokking-machine-learning/chapter-10/)) dataset. The MNIST dataset contains handwritten digits that we c[](/book/grokking-machine-learning/chapter-10/)an classify using a neural network.

#### [](/book/grokking-machine-learning/chapter-10/)A graphical example in two dimensions

In[](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/) this section, we’ll train a neural network in Keras on the dataset shown in figure 10.20. The dataset contains two labels, 0 and 1. The points with label 0 are drawn as squares, and those with label 1 are drawn as triangles. Notice that the points with label 1 are located mostly at the center, whereas the points with label 0 are located on the sides. For this type of dataset, we need a classifier with a nonlinear boundary, which makes it a good example for a neural network. The code for this section follows:

-  **Notebook**: Graphical_example.ipynb

- [https://github.com/luisguiserrano/manning/blob/master/Chapter_10_Neural_Networks/Graphical_example.ipynb](https://github.com/luisguiserrano/manning/blob/master/Chapter_10_Neural_Networks/Graphical_example.ipynb)

- **Dataset**: one_circle.csv

![Figure 10.20 Neural networks are great for nonlinearly separable sets. To test this, we’ll train a neural network on this circular dataset.](https://drek4537l1klr.cloudfront.net/serrano/Figures/10-20.png)

Before we train the model, let’s look at some random rows in our data. The input will be called x, with features x_1 and x_2, and the output will be called y. Table 10.3 has some sample data points. The dataset has 110 rows.

##### Table 10.3 The dataset with 110 rows, two features, and labels of 0 and 1[(view table figure)](https://drek4537l1klr.cloudfront.net/serrano/HighResolutionFigures/table_10-3.png)

| x_1 | x_2 | *y* |
| --- | --- | --- |
| –0.759416 | 2.753240 | 0 |
| –1.885278 | 1.629527 | 0 |
| ... | ... | ... |
| 0.729767 | –2.479655 | 1 |
| –1.715920 | –0.393404 | 1 |

Before we build and train the neural networks, we must do some data preprocessing.

#### [](/book/grokking-machine-learning/chapter-10/)Categorizing our data: Turning nonbinary features into binary ones

In [](/book/grokking-machine-learning/chapter-10/)this dataset, the output is a number between 0 and 1, but it represents two classes. In Keras, it is recommended to categorize this type of output. This simply means that points with label 0 will now have a label [1,0], and points with label 1 will now have a label [0,1]. We do this using the `to_categorical` function as follows:

```
from tensorflow.keras.utils import to_categorical
categorized_y = np.array(to_categorical(y, 2))
```

The new labels are called `categorized_y`.

#### The architecture of the neural network

In[](/book/grokking-machine-learning/chapter-10/) this section, we build the architecture of the neural network for this dataset. Deciding which architecture to use is not an exact science, but it is normally recommended to go a little bigger rather than a little smaller. For this dataset, we’ll use the following architecture with two hidden layers (figure 10.21):

- Input layer

- Size: 2

- First hidden layer

- Size:128
- Activation function: ReLU

- Second hidden layer

- Size: 64
- Activation function: ReLU

- Output layer

- Size: 2
- Activation function: softmax

![Figure 10.21 The architecture that we will use to classify our dataset. It contains two hidden layers: one of 128 and one of 64 nodes. The activation function between them is a ReLU, and the final activation function is a softmax.](https://drek4537l1klr.cloudfront.net/serrano/Figures/10-211.png)

Furthermore, we’ll add dropout layers between our hidden layers with a dropout probability of 0.2, to prevent overfittin[](/book/grokking-machine-learning/chapter-10/)g.

#### Building the model in Keras

Building[](/book/grokking-machine-learning/chapter-10/) the neural network takes only a few lines of code in Keras. First we import the necessary packages and functions as follows:

```
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense, Dropout, Activation
```

Now, on to define the model with the architecture that we have defined in the previous subsection. First, we define the model with the following line:

```
model = Sequential()                                       #1
model.add(Dense(128, activation='relu', input_shape=(2,))) #2
model.add(Dropout(.2))                                     #3
model.add(Dense(64, activation='relu'))                    #4
model.add(Dropout(.2))
model.add(Dense(2, activation='softmax'))                  #5
```

Once the model is defined, we can compile it, as shown here:

```
model.compile(loss = 'categorical_crossentropy', optimizer='adam', metrics=['accuracy'])
```

The parameters in the `compile` function[](/book/grokking-machine-learning/chapter-10/) follow:

- `loss = 'categorical_crossentropy'`: this is the loss function, which we have defined as the log loss. Because our labels have more than one column, we need to use the multivariate version for the log loss function, called categorical cross-entropy.
- `optimizer = 'adam'`: packages like Keras have many built-in tricks that help us train a model in an optimal way. It’s always a good idea to add an optimizer to our training. Some of the best ones are Adam, SGD, RMSProp, and AdaGrad. Try this same training with other optimizers, and see how they do.
- `metrics = ['accuracy']`: As the training goes, we get reports on how the model is doing at each epoch. This flag allows us to define what metrics we want to see during the training, and for this example, we’ve picked the accuracy.

When we run the code, we get a summary of the architecture and number of parameters, as follows:

```
Model: "sequential"
_________________________________________________________________
Layer (type)         Output Shape                Param #
=================================================================
dense (Dense)        (None, 128)                 384
_________________________________________________________________
dropout (Dropout)    (None, 128)                 0
_________________________________________________________________
dense_1 (Dense)      (None, 64)                  8256
_________________________________________________________________
dropout_1 (Dropout)  (None, 64)                  0
_________________________________________________________________
dense_2 (Dense)      (None, 2)                   130
=================================================================
Total params: 8,770
Trainable params: 8,770
Non-trainable params: 0
_________________________________________________________________
```

Each row in the previous output is a layer (dropout layers are treated as separate layers for description purposes). The columns correspond to the type of the layer, the shape (number of nodes), and the number of parameters, which is precisely the number of weights plus the number of biases. This model has a total of 8,770 trainable pa[](/book/grokking-machine-learning/chapter-10/)rameters.

#### Training the model

For[](/book/grokking-machine-learning/chapter-10/) training, one simple line of code suffices, shown next:

```
model.fit(x, categorized_y, epochs=100, batch_size=10)
```

Let’s examine each of the inputs to this fit function.

- `x and categorized_y`: the features and labels, respectively.
- `epochs`: the number of times we run backpropagation on our whole dataset. Here we do it 100 times.
- `batch_size`: the length of the batches that we use to train our model. Here we are introducing our data to the model in batches of 10. For a small dataset like this one, we don’t need to input it in batches, but in this example, we are doing it for exposure.

As the model trains, it outputs some information at each epoch, namely, the loss (error function) and the accuracy. For contrast, notice next how the first epoch has a high loss and a low accuracy, whereas the last epoch has much better results in both metrics:

```
Epoch 1/100
11/11 [==============================] - 0s 2ms/step - loss: 0.5473 - accuracy: 0.7182
...
Epoch 100/100
11/11 [==============================] - 0s 2ms/step - loss: 0.2110 - accuracy: 0.9000
```

The final accuracy of the model on the training is 0.9. This is good, although remember that accuracy must be calculated in the testing set instead. I won’t do it here, but try splitting the dataset into a training and a testing set and retraining this neural network to see what testing accuracy you obtain. Figure 10.22 shows the plot of the boundary of the neural network.

![Figure 10.22 The boundary of the neural network classifier we trained. Notice that it correctly classifies most of the points, with a few exceptions.](https://drek4537l1klr.cloudfront.net/serrano/Figures/10-22.png)

Note that the model managed to classify the data pretty well, encircling the triangles and leaving the squares outside. It made some mistakes, due to noisy data, but this is OK. The rigged boundary hints to small levels of overfitting, but in general it seems like [](/book/grokking-machine-learning/chapter-10/)a good model.

#### [](/book/grokking-machine-learning/chapter-10/)Training a neural network for image recognition

In[](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/) [](/book/grokking-machine-learning/chapter-10/)this section, we learn how to train a neural network for image recognition. The dataset we use is MNIST, a popular dataset for image recognition, which contains 70,000 handwritten digits from 0 to 9. The label of each image is the corresponding digit. Each grayscale image comes as a 28-by-28 matrix of numbers between 0 and 255, where 0 represents white, 255 represents black, and any number in between represents a shade of gray. The code for this section follows:

-  **Notebook**: Image_recognition.ipynb

- [https://github.com/luisguiserrano/manning/blob/master/Chapter_10_Neural_Networks/Image_recognition.ipynb](https://github.com/luisguiserrano/manning/blob/master/Chapter_10_Neural_Networks/Image_recognition.ipynb)

- **Dataset**: MNIST (comes pr[](/book/grokking-machine-learning/chapter-10/)eloaded with Keras)

#### Loading the data

This [](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/)dataset comes preloaded in Keras, so it is easy to load it into NumPy arrays. In fact, it has already been separated into training and testing sets of sizes 60,000 and 10,000, respectively. The following lines of code will load them into NumPy arrays:

```
from tensorflow import keras
(x_train, y_train), (x_test, y_test) = keras.datasets.mnist.load_data()
```

In figure 10.23, you can see the first five images in the dataset with their labels.

![Figure 10.23 Some examples of handwritten digits in MNIST with their labels](https://drek4537l1klr.cloudfront.net/serrano/Figures/10-23.png)

#### Preprocessing the data

Neural[](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/) networks receive vectors as input instead of matrices, so we must turn each 28-by-28 image into a long vector of length 282 = 784. We can use the `reshape` function for this, as shown next:

```
x_train_reshaped = x_train.reshape(-1, 28*28)
x_test_reshaped = x_test.reshape(-1, 28*28)
```

As with the previous example, we must also categorize the labels. Because the label is a number between 0 and 9, we must turn that into a vector of length 10, in which the entry corresponding to the label is a 1 and the rest are 0. We can do this with the following lines of code:

```
y_train_cat = to_categorical(y_train, 10)
y_test_cat = to_categorical(y_test, 10)
```

This process is illustrated in figure 10.24.

![Figure 10.24 Before training the neural network, we preprocess the images and the labels in the following way. We shape the rectangular image into a long vector by concatenating the rows. We then convert each label into a vector of length 10 with only one non-zero entry in the position of the corresponding label.](https://drek4537l1klr.cloudfront.net/serrano/Figures/10-24.png)

#### Building and training the model

We[](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/) can use the same architecture that we used in the previous model, with a small change, because the input is now of size 784. In the next lines of code, we define the model and its architecture:

```
model = Sequential()
model.add(Dense(128, activation='relu', input_shape=(28*28,)))
model.add(Dropout(.2))
model.add(Dense(64, activation='relu'))
model.add(Dropout(.2))
model.add(Dense(10, activation='softmax'))
```

Now we compile and train the model for 10 epochs with a batch size of 10, as shown here. This model has 109,386 trainable parameters, so training for 10 epochs may take a few minutes on your computer.

```
model.compile(loss = 'categorical_crossentropy', optimizer='adam', metrics=['accuracy'])
model.fit(x_train_reshaped, y_train_cat, epochs=10, batch_size=10)
```

Looking at the output, we can see that the model has a training accuracy of 0.9164, which is good, but let’s evaluate the testing accuracy to make sure the [](/book/grokking-machine-learning/chapter-10/)model is not overfitting.

#### Evaluating the model

We [](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/)can evaluate the accuracy in the testing set by making predictions in the testing dataset and comparing them with the labels. The neural network outputs vectors of length 10 with the probabilities it assigns to each of the labels, so we can obtain the predictions by looking at the entry of maximum value in this vector, as follows:

```
predictions_vector = model.predict(x_test_reshaped)
predictions = [np.argmax(pred) for pred in predictions_vector]
```

When we compare these to the labels, we get a testing accuracy of 0.942, which is quite good. We can do better than this with more complicated architectures, such as convolutional neural networks (see more of this in the next section), but it’s good to know that with a small, fully connected neural network, we can do quite well in an image recognition problem.

Let’s now look at some predictions. In figure 10.25, we can see a correct one (left) and an incorrect one (right). Notice that the incorrect one is a poorly written image of a number 3, which also looks a bit like an 8.

![Figure 10.25 Left: An image of a 4 that has been correctly classified by the neural network. Right: An image of a 3 that has been incorrectly classified as an 8.](https://drek4537l1klr.cloudfront.net/serrano/Figures/10-25.png)

With this exercise, we can see that the process of training such a large neural network is simple with a few lines of code in Keras! Of course, there is much more one can do here. Play with the notebook, add more layers to the neural network, change the hyperparameters, and see how high you can improve the test[](/book/grokking-machine-learning/chapter-10/)ing accuracy for this model!

## [](/book/grokking-machine-learning/chapter-10/)Neural networks for regression

Throughout[](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/) this chapter, we’ve seen how to use neural networks as a classification model, but neural networks are just as useful as regression models. Luckily, we have only two small tweaks to apply to a classification neural network to obtain a regression neural network. The first tweak is to remove the final sigmoid function from the neural network. The role of this function is to turn the input into a number between 0 and 1, so if we remove it, the neural network will be able to return any number. The second tweak is to change the error function to the absolute error or the mean square error, because these are the error functions associated with regression. Everything else will remain the same, including the training process.

As an example, let’s look at the perceptron in figure 10.7 in the section “A graphical representation of perceptrons.” This perceptron makes the prediction *ŷ* = *σ*(3*x*1 – 2*x*2 + 4*x*3 + 2). If we remove the sigmoid activation function, the new perceptron makes the prediction *ŷ* = 3*x*1 – 2*x*2 + 4*x*3 + 2. This perceptron is illustrated in figure 10.26. Notice that this perceptron represents a linear regression model.

![Figure 10.26 If we remove the activation function from a perceptron, we turn a classification model into a linear regression model. The linear regression model predicts any numerical value, not just one between 0 and 1.](https://drek4537l1klr.cloudfront.net/serrano/Figures/10-26.png)

To illustrate this process, we train a neural network in Keras on a familiar dataset: the dataset of housing prices in Hyderabad. Recall that in the section “Real-life application: Using Turi Create to predict housing prices in India,” in chapter 3, we trained a linear regression model to fit this dataset. The code for this section follows:

-  **Notebook**: House_price_predictions_neural_network.ipynb

- [https://github.com/luisguiserrano/manning/blob/master/Chapter_10_Neural_Networks/House_price_predictions_neural_network.ipynb](https://github.com/luisguiserrano/manning/blob/master/Chapter_10_Neural_Networks/House_price_predictions_neural_network.ipynb)

- **Dataset**: Hyderabad.csv

The details for loading the dataset and splitting the dataset into features and labels can be found in the notebook. The architecture of the neural network that we’ll use follows:

- An input layer of size 38 (the number of columns in the dataset)
- A hidden layer of size 128 with a ReLU activation function and a dropout parameter of 0.2
- A hidden layer of size 64 with a ReLU activation function and a dropout parameter of 0.2
- An output layer of size 1 with no activation function

```
model = Sequential()
model.add(Dense(38, activation='relu', input_shape=(38,)))
model.add(Dropout(.2))
model.add(Dense(128, activation='relu'))
model.add(Dropout(.2))
model.add(Dense(64, activation='relu'))
model.add(Dropout(.2))
model.add(Dense(1))
```

To train the neural network, we use the mean square error function and the Adam optimizer. We’ll train for 10 epochs using a batch size of 10, as shown here:

```
model.compile(loss = 'mean_squared_error', optimizer='adam')
model.fit(features, labels, epochs=10, batch_size=10)
```

This neural network reports a root mean square error of 5,535,425 in the training dataset. Study this model further by adding a testing set, and play with the architecture, and s[](/book/grokking-machine-learning/chapter-10/)ee how much you can improve it!

## [](/book/grokking-machine-learning/chapter-10/)Other architectures for more complex datasets

Neural[](/book/grokking-machine-learning/chapter-10/) networks are useful in many applications, perhaps more so than any other machine learning algorithm currently. One of the most important qualities of neural networks is their versatility. We can modify the architectures in very interesting ways to better fit our data and solve our problem. To find out more about these architectures, check out *Grokking Deep Learning**[](/book/grokking-machine-learning/chapter-10/)* by Andrew Trask[](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/) (Manning, 2019) and a set of videos available in appendix C or at [https://serrano.academy/neural-networks/](https://serrano.academy/neural-networks/).

#### [](/book/grokking-machine-learning/chapter-10/)How neural networks see: Convolutional neural networks (CNN)

As we learned in this chapter, neural[](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/) networks are great with images, and we can use them in many applications, such as the following:

-  **Image recognition****[](/book/grokking-machine-learning/chapter-10/)**: the input is an image, and the output is the label on the image. Some famous datasets used for image recognition follow:

- MNIST: handwritten digits in 28-by-28 gray scale images
- CIFAR-10: color images, with 10 labels such as airplane, automobile, and so on, in 32-by-32 images
- CIFAR-100: similar to CIFAR-10, but with 100 labels such as aquatic mammals, flowers, and so on

- **Semantic segmentation****[](/book/grokking-machine-learning/chapter-10/)**: the input is an image, and the output is not only the labels of the things found in the image but also their location inside the image. Normally, the neural network outputs this location as a bounded rectangle in the image.

In the section “Training a neural network for image recognition,” we built a small, fully connected neural network that classified the MNIST dataset quite well. However, for more complicated images, such as pictures and faces, a neural network like this one won’t do well because turning the image into a long vector loses a lot of information. For these complicated images, we need different architectures, and this is where convolutional neural networks come to help us.

For the details on neural networks, review the resources in appendix C, but here is a rough outline of how they work. Imagine that we have a large image that we want to process. We take a smaller window, say 5-by-5, or 7-by-7 pixels, and swipe it through the large image. Every time we pass it through, we apply a formula called a *convolution*. Thus, we end with a slightly smaller filtered image, which in some way summarizes the previous one—a convolutional layer. A convolutional neural network consists of several of these convolutional layers, followed by some fully connected layers.

When it comes to complicated images, we normally wouldn’t go about training a neural network from scratch. A useful technique called *transfer learning**[](/book/grokking-machine-learning/chapter-10/)* consists of starting with a pretrained network and using our data to tweak some of its parameters (usually the last layer). This technique tends to work well and at a low computational cost. Networks such as InceptionV3, ImageNet, ResNet, and VGG have been trained by companies and research groups with large computational power, so it’s highly recommended for us to use them.

#### [](/book/grokking-machine-learning/chapter-10/)How neural networks talk: Recurrent neural networks (RNN), gated recurrent units (GRU), and long short-term memory networks (LSTM)

One[](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/) of the most fascinating applications of neural networks is when we can get them to talk to us or understand what we say. This involves listening to what we say or reading what we write, analyzing it, and being able to respond or act. The ability for computers to understand and process language is called *natural language processing*. Neural networks have had a lot of success in natural language processing. The sentiment analysis example at the beginning of this chapter is part of natural language processing, because it entails understanding sentences and determining whether they have positive or negative sentiment. As you can imagine, many more cutting-edge applications exist, such as the following:

- **Machine translation**: translating sentences from various languages into others.
- **Speech recognition****[](/book/grokking-machine-learning/chapter-10/)**: decoding human voice and turning it into text.
- **Text summarization****[](/book/grokking-machine-learning/chapter-10/)**: summarizing large texts into a few paragraphs.
- **Chatbots****[](/book/grokking-machine-learning/chapter-10/)**: a system that can talk to humans and answer questions. These are not yet perfected, but useful chatbots operate in specific topics, such as customer support.

The most useful architectures that work well for processing texts are *recurrent neural networks*, and some more advanced versions of them called *long short-term memory networks* (LSTM) and *gated recurrent units* (GRU). To get an idea of what they are, imagine a neural network where the output is plugged back into the network as part of the inputs. In this way, neural networks have a memory, and when trained properly, this memory can help them make sense of the topic [](/book/grokking-machine-learning/chapter-10/)in the text.

#### [](/book/grokking-machine-learning/chapter-10/)How neural networks paint paintings: Generative adversarial networks (GAN)

One [](/book/grokking-machine-learning/chapter-10/)[](/book/grokking-machine-learning/chapter-10/)of the most fascinating applications of neural networks is generation. So far, neural networks (and most other ML models in this book) have worked well in predictive machine learning, namely, being able to answer questions such as “How much is that?” or “Is this a cat or a dog?” However, in recent years, many advances have occurred in a fascinating area called *generative machine learning**[](/book/grokking-machine-learning/chapter-10/)*. Generative machine learning is the area of machine learning that teaches the computer how to create things, rather than simply answer questions. Actions such as painting a painting, composing a song, or writing a story represent a much higher level of understanding of the world.

Without a doubt, one of the most important advances in the last few years has been the development of *generative adversarial networks*, or GANs. Generative adversarial networks have shown fascinating results when it comes to image generation. GANs consist of two competing networks, the generator and the discriminator. The generator attempts to generate real-looking images, whereas the discriminator tries to tell the real images and the fake images apart. During the training process, we feed real images to the discriminator, as well as fake images generated by the generator. When applied to a dataset of human faces, this process results in a generator that can generate some very real-looking faces. In fact, they look so real that humans often have a hard time telling them apart. Test yourself against a GAN—[https://www.whichfaceisreal.com](https://www.whichfaceisreal.com).

## [](/book/grokking-machine-learning/chapter-10/)Summary

- Neural networks are a powerful model used for classification and regression. A neural network consists of a set of perceptrons organized in layers, where the output of one layer serves as input to the next layer. Their complexity allows them to achieve great success in applications that are difficult for other machine learning models.
- Neural networks have cutting-edge applications in many areas, including image recognition and text processing.
- The basic building block of a neural network is the perceptron. A perceptron receives several values as inputs, and outputs one value by multiplying the inputs by weights, adding a bias, and applying an activation function.
- Popular activation functions include sigmoid, hyperbolic tangent, softmax, and the rectified linear unit (ReLU). They are used between layers in a neural network to break linearity and help us build more complex boundaries.
- The sigmoid function is a simple function that sends any real number to the interval between 0 and 1. The hyperbolic tangent is similar, except the output is the interval between –1 and 1. Their goal is to squish our input into a small interval so that our answers can be interpreted as a category. They are mostly used for the final (output) layer in a neural network. Due to the flatness of their derivatives, they may cause problems with vanishing gradients.
- The ReLU function is a function that sends negative numbers to 0, and non-negative numbers to themselves. It showed great success in reducing the vanishing gradient problem, and thus it is used more in training neural networks than the sigmoid function or the hyperbolic tangent function.
- Neural networks have a very complex structure, which makes them hard to train. The process we use to train them, called backpropagation, has shown great success. Backpropagation consists of taking the derivative of the loss function and finding all the partial derivatives with respect to all the weights of the model. We then use these derivatives to update the weights of the model iteratively to improve its performance.
- Neural networks are prone to overfitting and other problems such as vanishing gradients, but we can use techniques such as regularization and dropout to help reduce these problems.
- We have some useful packages to train neural networks, such as Keras, TensorFlow, and PyTorch. These packages make it very easy for us to train neural networks, because we have to define only the architecture of the model and the error functions, and they take care of the training. Furthermore, they have many built-in cutting-edge optimizers that we[](/book/grokking-machine-learning/chapter-10/) can take advan[](/book/grokking-machine-learning/chapter-10/)tage of.

## [](/book/grokking-machine-learning/chapter-10/)Exercises

#### Exercise 10.1

The following image shows a neural network in which all the activations are sigmoid functions.

![](https://drek4537l1klr.cloudfront.net/serrano/Figures/10-unnumb-2.png)

What would this neural network predi[](/book/grokking-machine-learning/chapter-10/)ct for the input (1,1)?

#### Exercise 10.2

As we learned in exercise 5.3, it is impossible to build a perceptron that mimics the XOR gate. In other words, it is impossible to fit the following dataset with a perceptron and obtain 100% accuracy:

| *x*1 | *x*2 | *y* |
| --- | --- | --- |
| 0 | 0 | 0 |
| 0 | 1 | 1 |
| 1 | 0 | 1 |
| 1 | 1 | 0 |

This is because the dataset is not linearly separable. Using a neural network of depth 2, build a perceptron that mimics the XOR gate shown previously. As the activation functions, use the step function instead of the sigmoid function to get discrete outputs.

##### hint

This will be hard to do using a training method; instead, try eyeballing the weights. Try (or search online how) to build an XOR gate using AND, OR, and NOT gates, and use the results of exercise 5.3 to help you.

#### [](/book/grokking-machine-learning/chapter-10/)Exercise 10.3

At the end of the section “A graphical representation of neural networks,” we saw that the neural network in figure 10.13 with the activation function doesn’t fit the dataset in table 10.1 because the point (1,1) is misclassified.

1. Verify that this is the case.
1. Change the weights so that the neural network classifies every point correctly.
