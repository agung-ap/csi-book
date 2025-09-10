# Chapter 11. Neural networks that understand language: king – man + woman == ?

### **In this chapter**

- Natural language processing (NLP)
- Supervised NLP
- Capturing word correlation in input data
- Intro to an embedding layer
- Neural architecture
- Comparing word embeddings
- Filling in the blank
- Meaning is derived from loss
- Word analogies

“Man is a slow, sloppy, and brilliant thinker; computers are fast, accurate, and stupid.”

*John Pfeiffer, in *Fortune*, 1961*

### What does it mean to understand language?

#### What kinds of predictions do people make about language?

Up until now, we’ve been using neural networks to model image data. But neural networks can be used to understand a much wider variety of datasets. Exploring new datasets also teaches us a lot about neural networks in general, because different datasets often justify different styles of neural network training according to the challenges hidden in the data.

![](https://drek4537l1klr.cloudfront.net/trask2/Figures/f0188-01.jpg)

We’ll begin this chapter by exploring a much older field that overlaps deep learning: *natural language processing* (NLP). This field is dedicated exclusively to the automated understanding of human language (previously not using deep learning). We’ll discuss the basics of deep learning’s approach to this field.

### Natural language processing (NLP)

#### NLP is divided into a collection of tasks or challenges

Perhaps the best way to quickly get to know NLP is to consider a few of the many challenges the NLP community seeks to solve. Here are a few types of classification problem that are common to NLP:

- Using the *characters* of a document to predict *where words start and end*.
- Using the *words* of a document to predict *where sentences start and end*.
- Using the *words in a sentence* to predict *the part of speech for each word*.
- Using *words in a sentence* to predict *where phrases start and end*.
- Using *words in a sentence* to predict *where named entity (person, place, thing) references start and end*.
- Using *sentences in a document* to predict *which pronouns refer to the same person / place / thing*.
- Using *words in a sentence* to predict the *sentiment* of a sentence.

Generally speaking, NLP tasks seek to do one of three things: label a region of text (such as part-of-speech tagging, sentiment classification, or named-entity recognition); link two or more regions of text (such as coreference, which tries to answer whether two mentions of a real-world thing are in fact referencing the same real-world thing, where the real-world thing is generally a person, place, or some other named entity); or try to fill in missing information (missing words) based on context.

Perhaps it’s also apparent how machine learning and NLP are deeply intertwined. Until recently, most state-of-the-art NLP algorithms were advanced, probabilistic, non-parametric models (not deep learning). But the recent development and popularization of two major neural algorithms have swept the field of NLP: neural word embeddings and recurrent neural networks (RNNs).

In this chapter, we’ll build a word-embedding algorithm and demonstrate why it increases the accuracy of NLP algorithms. In the next chapter, we’ll create a recurrent neural network and demonstrate why it’s so effective at predicting across sequences.

It’s also worth mentioning the key role that NLP (perhaps using deep learning) plays in the advancement of artificial intelligence. AI seeks to create machines that can think and engage with the world as humans do (and beyond). NLP plays a very special role in this endeavor, because language is the bedrock of conscious logic and communication in humans. As such, methods by which machines can use and understand language form the foundation of human-like logic in machines: the foundation of thought.

### Supervised NLP

#### Words go in, and predictions come out

Perhaps you’ll remember the following figure from [chapter 2](/book/grokking-deep-learning/chapter-2/ch02). Supervised learning is all about taking “what you know” and transforming it into “what you want to know.” Up until now, “what you know” has always consisted of numbers in one way or another. But NLP uses text as input. How do you process it?

![](https://drek4537l1klr.cloudfront.net/trask2/Figures/f0190-01.jpg)

Because neural networks only map input numbers to output numbers, the first step is to convert the text into numerical form. Much as we converted the streetlight dataset, we need to convert the real-world data (in this case, text) into a *matrix* the neural network can consume. As it turns out, how we do this is extremely important!

![](https://drek4537l1klr.cloudfront.net/trask2/Figures/f0190-02_alt.jpg)

How should we convert text to numbers? Answering that question requires some thought regarding the problem. Remember, neural networks look for correlation between their input and output layers. Thus, we want to convert text into numbers in such a way that the correlation between input and output is *most obvious* to the network. This will make for faster training and better generalization.

In order to know what input format makes input/output correlation the most obvious to the network, we need to know what the input/output dataset looks like. To explore this topic, let’s take on the challenge of *topic classification*.

### IMDB movie reviews dataset

#### You can predict whether people post positive or negative reviews

The IMDB movie reviews dataset is a collection of review -> rating pairs that often look like the following (this is an imitation, not pulled from IMDB):

“This movie was terrible! The plot was dry, the acting unconvincing, and I spilled popcorn on my shirt.”

*Rating: 1 (stars)*

The entire dataset consists of around 50,000 of these pairs, where the input reviews are usually a few sentences and the output ratings are between 1 and 5 stars. People consider it a *sentiment dataset* because the stars are indicative of the overall sentiment of the movie review. But it should be obvious that this sentiment dataset might be very different from other sentiment datasets, such as product reviews or hospital patient reviews.

You want to train a neural network that can use the input text to make accurate predictions of the output score. To accomplish this, you must first decide how to turn the input and output datasets into matrices. Interestingly, the output dataset is a number, which perhaps makes it an easier place to start. You’ll adjust the range of stars to be between 0 and 1 instead of 1 and 5, so that you can use binary `softmax`. That’s all you need to do to the output. I’ll show an example on the next page.

The input data, however, is a bit trickier. To begin, let’s consider the raw data. It’s a list of characters. This presents a few problems: not only is the input data text instead of numbers, but it’s *variable-length* text. So far, neural networks always take an input of a fixed size. You’ll need to overcome this.

So, the raw input won’t work. The next question to ask is, “What about this data will have correlation with the output?” Representing that property might work well. For starters, I wouldn’t expect any characters (in the list of characters) to have any correlation with the sentiment. You need to think about it differently.

What about the words? Several words in this dataset would have a bit of correlation. I’d bet that *terrible* and *unconvincing* have significant negative correlation with the rating. By *negative*, I mean that as they increase in frequency in any input datapoint (any review), the rating tends to decrease.

Perhaps this property is more general! Perhaps words by themselves (even out of context) would have significant correlation with sentiment. Let’s explore this further.

### Capturing word correlation in input data

#### Bag of words: Given a review’s vocabulary, predict the sentiment

If you observe correlation between the vocabulary of an IMDB review and its rating, then you can proceed to the next step: creating an input matrix that represents the vocabulary of a movie review.

What’s commonly done in this case is to create a matrix where each row (vector) corresponds to each movie review, and each column represents whether a review contains a particular word in the vocabulary. To create the vector for a review, you calculate the vocabulary of the review and then put 1 in each corresponding column for that review and 0s everywhere else. How big are these vectors? Well, if there are 2,000 words, and you need a place in each vector for each word, each vector will have 2,000 dimensions.

This form of storage, called *one-hot encoding*, is the most common format for encoding binary data (the binary presence or absence of an input datapoint among a vocabulary of possible input datapoints). If the vocabulary was only four words, the one-hot encoding might look like this:

```
1234567891011121314import numpy as np

onehots = {}
onehots['cat'] = np.array([1,0,0,0])
onehots['the'] = np.array([0,1,0,0])
onehots['dog'] = np.array([0,0,1,0])
onehots['sat'] = np.array([0,0,0,1])

sentence = ['the','cat','sat']
x = word2hot[sentence[0]] + \
    word2hot[sentence[1]] + \
    word2hot[sentence[2]]

print("Sent Encoding:" + str(x))
```

![](https://drek4537l1klr.cloudfront.net/trask2/Figures/f0192-01.jpg)

As you can see, we create a vector for each term in the vocabulary, and this allows you to use simple vector addition to create a vector representing a subset of the total vocabulary (such as a subset corresponding to the words in a sentence).

```
Output:        Sent Encoding:[1 1 0 1]
```

![](https://drek4537l1klr.cloudfront.net/trask2/Figures/f0192-02.jpg)

Note that when you create an embedding for several terms (such as “the cat sat”), you have multiple options if words occur multiple times. If the phrase was “cat cat cat,” you could either sum the vector for “cat” three times (resulting in `[3,0,0,0]`) or just take the unique “cat” a single time (resulting in `[1,0,0,0]`). The latter typically works better for language.

### Predicting movie reviews

#### With the encoding strategy and the previous network, you can predict sentiment

Using the strategy we just identified, you can build a vector for each word in the sentiment dataset and use the previous two-layer network to predict sentiment. I’ll show you the code, but I strongly recommend attempting this from memory. Open a new Jupyter notebook, load in the dataset, build your one-hot vectors, and then build a neural network to predict the rating of each movie review (positive or negative).

Here’s how I would do the preprocessing step:

```
123456789101112131415161718192021222324252627282930313233343536373839import sys

f = open('reviews.txt')
raw_reviews = f.readlines()
f.close()

f = open('labels.txt')
raw_labels = f.readlines()
f.close()

tokens = list(map(lambda x:set(x.split(" ")),raw_reviews))

vocab = set()
for sent in tokens:
    for word in sent:
        if(len(word)>0):
            vocab.add(word)
vocab = list(vocab)

word2index = {}
for i,word in enumerate(vocab):
    word2index[word]=i

input_dataset = list()
for sent in tokens:
    sent_indices = list()
    for word in sent:
        try:
            sent_indices.append(word2index[word])
        except:
            ""
    input_dataset.append(list(set(sent_indices)))

target_dataset = list()
for label in raw_labels:
    if label == 'positive\n':
        target_dataset.append(1)
    else:
        target_dataset.append(0)
```

### Intro to an embedding layer

#### Here’s one more trick to make the network faster

At right is the diagram from the previous neural network, which you’ll now use to predict sentiment. But before that, I want to describe the layer names. The first layer is the dataset (`layer_0`). This is followed by what’s called a *linear layer* (`weights_0_1`). This is followed by a `relu` layer (`layer_1`), another linear layer (`weights_1_2`), and then the output, which is the prediction layer. As it turns out, you can take a bit of a shortcut to `layer_1` by replacing the first linear layer (`weights_0_1`) with an embedding layer.

![](https://drek4537l1klr.cloudfront.net/trask2/Figures/f0194-01.jpg)

Taking a vector of 1s and 0s is mathematically equivalent to summing several rows of a matrix. Thus, it’s much more efficient to select the relevant rows of `weights_0_1` and sum them as opposed to doing a big vector-matrix multiplication. Because the sentiment vocabulary is on the order of 70,000 words, most of the vector-matrix multiplication is spent multiplying 0s in the input vector by different rows of the matrix before summing them. Selecting the rows corresponding to each word in a matrix and summing them is much more efficient.

![](https://drek4537l1klr.cloudfront.net/trask2/Figures/f0194-02.jpg)

Using this process of selecting rows and performing a sum (or average) means treating the first linear layer (`weights_0_1`) as an embedding layer. Structurally, they’re identical (`layer_1` is exactly the same using either method for forward propagation). The only difference is that summing a small number of rows is much faster.

![](https://drek4537l1klr.cloudfront.net/trask2/Figures/f0194-03.jpg)

#### After running the previous code, run this code

```
1234567891011121314151617181920212223242526272829303132333435363738394041424344454647484950import numpy as np
np.random.seed(1)

def sigmoid(x):
    return 1/(1 + np.exp(-x))

alpha, iterations = (0.01, 2)
hidden_size = 100

weights_0_1 = 0.2*np.random.random((len(vocab),hidden_size)) - 0.1
weights_1_2 = 0.2*np.random.random((hidden_size,1)) - 0.1

correct,total = (0,0)
for iter in range(iterations):

    for i in range(len(input_dataset)-1000):

        x,y = (input_dataset[i],target_dataset[i])
        layer_1 = sigmoid(np.sum(weights_0_1[x],axis=0))
        layer_2 = sigmoid(np.dot(layer_1,weights_1_2))
        layer_2_delta = layer_2 - y
        layer_1_delta = layer_2_delta.dot(weights_1_2.T)
        weights_0_1[x] -= layer_1_delta * alpha
        weights_1_2 -= np.outer(layer_1,layer_2_delta) * alpha

        if(np.abs(layer_2_delta) < 0.5):
            correct += 1
        total += 1
        if(i % 10 == 9):
            progress = str(i/float(len(input_dataset)))
            sys.stdout.write('\rIter:'+str(iter)\
                             +' Progress:'+progress[2:4]\
                             +'.'+progress[4:6]\
                             +'% Training Accuracy:'\
                             + str(correct/float(total)) + '%')
    print()
correct,total = (0,0)
for i in range(len(input_dataset)-1000,len(input_dataset)):

       x = input_dataset[i]
       y = target_dataset[i]

       layer_1 = sigmoid(np.sum(weights_0_1[x],axis=0))
       layer_2 = sigmoid(np.dot(layer_1,weights_1_2))

    if(np.abs(layer_2 - y) < 0.5):
        correct += 1
    total += 1
print("Test Accuracy:" + str(correct / float(total)))
```

### Interpreting the output

#### What did the neural network learn along the way?

Here’s the output of the movie reviews neural network. From one perspective, this is the same correlation summarization we’ve already discussed:

```
123Iter:0 Progress:95.99% Training Accuracy:0.832%
Iter:1 Progress:95.99% Training Accuracy:0.8663333333333333%
Test Accuracy:0.849
```

The neural network was looking for correlation between the input datapoints and the output datapoints. But those datapoints have characteristics we’re familiar with (notably those of language). Furthermore, it’s extremely beneficial to consider what patterns of language would be detected by the correlation summarization, and more importantly, which ones wouldn’t. After all, just because the network is able to find correlation between the input and output datasets doesn’t mean it understands every useful pattern of language.

![](https://drek4537l1klr.cloudfront.net/trask2/Figures/f0196-01.jpg)

Furthermore, understanding the difference between what the network (in its current configuration) is capable of learning relative to what it needs to know to properly understand language is an incredibly fruitful line of thinking. This is what researchers on the front lines of state-of-the-art research consider, and it’s what we’re going to consider here.

What about language did the movie reviews network learn? Let’s start by considering what was presented to the network. As displayed in the diagram at top right, you presented each review’s vocabulary as input and asked the network to predict one of two labels (`positive` or `negative`). Given that the correlation summarization says the network will look for correlation between the input and output datasets, at a minimum, you’d expect the network to identify words that have either a positive or negative correlation (by themselves).

This follows naturally from the correlation summarization. You present the presence or absence of a word. As such, the correlation summarization will find direct correlation between this presence/absence and each of the two labels. But this isn’t the whole story.

![](https://drek4537l1klr.cloudfront.net/trask2/Figures/f0196-02.jpg)

### Neural architecture

#### How did the choice of architecture affect what the network learned?

We just discussed the first, most trivial type of information the neural network learned: direct correlation between the input and target datasets. This observation is largely the clean slate of neural intelligence. (If a network can’t discover direct correlation between input and output data, something is probably broken.) The development of more-sophisticated architectures is based on the need to find more-complex patterns than direct correlation, and this network is no exception.

The minimal architecture needed to identify direct correlation is a two-layer network, where the network has a single weight matrix that connects directly from the input layer to the output layer. But we used a network that has a hidden layer. This begs the question, what does this hidden layer do?

Fundamentally, hidden layers are about grouping datapoints from a previous layer into *n* groups (where *n* is the number of neurons in the hidden layer). Each hidden neuron takes in a datapoint and answers the question, “Is this datapoint in my group?” As the hidden layer learns, it searches for useful groupings of its input. What are useful groupings?

An input datapoint grouping is useful if it does two things. First, the grouping must be useful to the prediction of an output label. If it’s not useful to the output prediction, *the correlation summarization will never lead the network to find the group*. This is a hugely valuable realization. Much of neural network research is about finding training data (or some other manufactured signal for the network to artificially predict) so it finds groupings that are useful for a task (such as predicting movie review stars). We’ll discuss this more in a moment.

Second, a grouping is useful if it’s an actual phenomenon in the data that you care about. Bad groupings just memorize the data. Good groupings pick up on phenomena that are useful linguistically.

For example, when predicting whether a movie review is positive or negative, understanding the difference between “terrible” and “not terrible” is a powerful grouping. It would be great to have a neuron that turned *off* when it saw “awful” and turned *on* when it saw “not awful.” This would be a powerful grouping for the next layer to use to make the final prediction. But because the input to the neural network is the vocabulary of a review, “it was great, not terrible” creates exactly the same `layer_1` value as “it was terrible, not great.” For this reason, the network is very unlikely to create a hidden neuron that understands negation.

Testing whether a layer is the same or different based on a certain language pattern is a great first step for knowing whether an architecture is likely to find that pattern using the correlation summarization. If you can construct two examples with an identical hidden layer, one with the pattern you find interesting and one without, the network is unlikely to find that pattern.

As you just learned, a hidden layer fundamentally groups the previous layer’s data. At a granular level, each neuron classifies a datapoint as either subscribing or not subscribing to its group. At a higher level, two datapoints (movie reviews) are similar if they subscribe to many of the same groups. Finally, two inputs (words) are similar if the weights linking them to various hidden neurons (a measure of each word’s group affinity) are similar. Given this knowledge, in the previous neural network, what should you observe in the weights going into the hidden neurons from the words?

#### What should you see in the weights connecting words and hidden neurons?

Here’s a hint: words that have a similar predictive power should subscribe to similar groups (hidden neuron configurations). What does this mean for the weights connecting each word to each hidden neuron?

Here’s the answer. Words that correlate with similar labels (positive or negative) will have similar weights connecting them to various hidden neurons. This is because the neural network learns to bucket them into similar hidden neurons so that the final layer (`weights_1_2`) can make the correct positive or negative predictions.

You can see this phenomenon by taking a particularly positive or negative word and searching for the other words with the most similar weight values. In other words, you can take each word and see which other words have the most similar weight values connecting them to each hidden neuron (to each group).

![](https://drek4537l1klr.cloudfront.net/trask2/Figures/f0198-01.jpg)

The three bold weights for “good” form the embedding for “good.” They reflect how much the term “good” is a member of each group (hidden neuron). Words with similar predictive power have similar word embeddings (weight values).

Words that subscribe to similar groups will have similar predictive power for positive or negative labels. As such, words that subscribe to similar groups, having similar weight values, will also have similar meaning. Abstractly, in terms of neural networks, a neuron has similar meaning to other neurons in the same layer if and only if it has similar weights connecting it to the next and/or previous layers.

### Comparing word embeddings

#### How can you visualize weight similarity?

For each input word, you can select the list of weights proceeding out of it to the various hidden neurons by selecting the corresponding row of `weights_0_1`. Each entry in the row represents each weight proceeding from that row’s word to each hidden neuron. Thus, to figure out which words are most similar to a target term, you compare each word’s vector (row of the matrix) to that of the target term. The comparison of choice is called *Euclidian distance*, as shown in the following code:

```
123456789101112from collections import Counter
import math

def similar(target='beautiful'):
    target_index = word2index[target]
    scores = Counter()
    for word,index in word2index.items():
        raw_difference = weights_0_1[index] - (weights_0_1[target_index])
        squared_difference = raw_difference * raw_difference
        scores[word] = -math.sqrt(sum(squared_difference))

     return scores.most_common(10)
```

This allows you to easily query for the most similar word (neuron) according to the network:

```
123456789101112print(similar('beautiful'))           print(similar('terrible'))

[('beautiful', -0.0),                 [('terrible', -0.0),
 ('atmosphere', -0.70542101298),       ('dull', -0.760788602671491),
 ('heart', -0.7339429768542354),       ('lacks', -0.76706470275372),
 ('tight', -0.7470388145765346),       ('boring', -0.7682894961694),
 ('fascinating', -0.7549291974),       ('disappointing', -0.768657),
 ('expecting', -0.759886970744),       ('annoying', -0.78786389931),
 ('beautifully', -0.7603669338),       ('poor', -0.825784172378292),
 ('awesome', -0.76647368382398),       ('horrible', -0.83154121717),
 ('masterpiece', -0.7708280057),       ('laughable', -0.8340279599),
 ('outstanding', -0.7740642167)]       ('badly', -0.84165373783678)]
```

As you might expect, the most similar term to every word is itself, followed by words with similar usefulness as the target term. Again, as you might expect, because the network has only two labels (`positive` and `negative`), the input terms are grouped according to which label they tend to predict.

This is a standard phenomenon of the correlation summarization. It seeks to create similar representations (`layer_1` values) within the network based on the label being predicted, so that it can predict the right label. In this case, the side effect is that the weights feeding into `layer_1` get grouped according to output label.

The key takeaway is a gut instinct about this phenomenon of the correlation summarization. It consistently attempts to convince the hidden layers to be similar based on which label should be predicted.

### What is the meaning of a neuron?

#### Meaning is entirely based on the target labels being predicted

Note that the meanings of different words didn’t totally reflect how you might group them. The term most similar to “beautiful” is “atmosphere.” This is a valuable lesson. For the purposes of predicting whether a movie review is positive or negative, these words have nearly identical meaning. But in the real world, their meaning is quite different (one is an adjective and another a noun, for example).

```
123456789101112print(similar('beautiful'))           print(similar('terrible'))

[('beautiful', -0.0),                 [('terrible', -0.0),
 ('atmosphere', -0.70542101298),       ('dull', -0.760788602671491),
 ('heart', -0.7339429768542354),       ('lacks', -0.76706470275372),
 ('tight', -0.7470388145765346),       ('boring', -0.7682894961694),
 ('fascinating', -0.7549291974),       ('disappointing', -0.768657),
 ('expecting', -0.759886970744),       ('annoying', -0.78786389931),
 ('beautifully', -0.7603669338),       ('poor', -0.825784172378292),
 ('awesome', -0.76647368382398),       ('horrible', -0.83154121717),
 ('masterpiece', -0.7708280057),       ('laughable', -0.8340279599),
 ('outstanding', -0.7740642167)]       ('badly', -0.84165373783678)]
```

This realization is incredibly important. The meaning (of a neuron) in the network is defined based on the target labels. Everything in the neural network is contexualized based on the correlation summarization trying to correctly make predictions. Thus, even though you and I know a great deal about these words, the neural network is entirely ignorant of all information outside the task at hand.

How can you convince the network to learn more-nuanced information about neurons (in this case, word neurons)? Well, if you give it input and target data that requires a more nuanced understanding of language, it will have reason to learn more-nuanced interpretations of various terms.

What should you use the neural network to predict so that it learns more-interesting weight values for the word neurons? The task you’ll use to learn more-interesting weight values for the word neurons is a glorified fill-in-the blank task. Why use this? First, there’s nearly infinite training data (the internet), which means nearly infinite signal for the neural network to use to learn more-nuanced information about words. Furthermore, being able to accurately fill in the blank requires at least some notion of context about the real world.

For instance, in the following example, is it more likely that the blank is correctly filled by the word “anvil” or “wool”? Let’s see if the neural network can figure it out.

![](https://drek4537l1klr.cloudfront.net/trask2/Figures/f0200-01.jpg)

### Filling in the blank

#### Learn richer meanings for words by having a richer signal to learn

This example uses almost exactly the same neural network as the previous one, with only a few modifications. First, instead of predicting a single label given a movie review, you’ll take each (five-word) phrase, remove one word (a focus term), and attempt to train a network to figure out the identity of the word you removed using the rest of the phrase. Second, you’ll use a trick called *negative sampling* to make the network train a bit faster.

Consider that in order to predict which term is missing, you need one label for each possible word. This would require several thousand labels, which would cause the network to train slowly. To overcome this, let’s randomly ignore most of the labels for each forward propagation step (as in, pretend they don’t exist). Although this may seem like a crude approximation, it’s a technique that works well in practice. Here’s the preprocessing code for this example:

```
12345678910111213141516171819202122232425262728293031323334353637383940414243444546474849505152535455565758596061626364656667686970717273747576777879808182838485868788import sys,random,math
from collections import Counter
import numpy as np

np.random.seed(1)
random.seed(1)
f = open('reviews.txt')
raw_reviews = f.readlines()
f.close()

tokens = list(map(lambda x:(x.split(" ")),raw_reviews))
wordcnt = Counter()
for sent in tokens:
    for word in sent:
        wordcnt[word] -= 1
vocab = list(set(map(lambda x:x[0],wordcnt.most_common())))

word2index = {}
for i,word in enumerate(vocab):
    word2index[word]=i

concatenated = list()
input_dataset = list()
for sent in tokens:
    sent_indices = list()
    for word in sent:
        try:
             sent_indices.append(word2index[word])
             concatenated.append(word2index[word])
        except:
            ""
    input_dataset.append(sent_indices)
concatenated = np.array(concatenated)

random.shuffle(input_dataset)

alpha, iterations = (0.05, 2)
hidden_size,window,negative = (50,2,5)

weights_0_1 = (np.random.rand(len(vocab),hidden_size) - 0.5) * 0.2
weights_1_2 = np.random.rand(len(vocab),hidden_size)*0

layer_2_target = np.zeros(negative+1)
layer_2_target[0] = 1

def similar(target='beautiful'):
  target_index = word2index[target]

  scores = Counter()
  for word,index in word2index.items():
    raw_difference = weights_0_1[index] - (weights_0_1[target_index])
    squared_difference = raw_difference * raw_difference
    scores[word] = -math.sqrt(sum(squared_difference))
  return scores.most_common(10)

def sigmoid(x):
    return 1/(1 + np.exp(-x))

for rev_i,review in enumerate(input_dataset * iterations):
  for target_i in range(len(review)):

    target_samples = [review[target_i]]+list(concatenated\
      [(np.random.rand(negative)*len(concatenated)).astype('int').tolist()])

       left_context = review[max(0,target_i-window):target_i]
       right_context = review[target_i+1:min(len(review),target_i+window)]

       layer_1 = np.mean(weights_0_1[left_context+right_context],axis=0)
       layer_2 = sigmoid(layer_1.dot(weights_1_2[target_samples].T))
       layer_2_delta = layer_2 - layer_2_target
       layer_1_delta = layer_2_delta.dot(weights_1_2[target_samples])

       weights_0_1[left_context+right_context] -= layer_1_delta * alpha
       weights_1_2[target_samples] -= np.outer(layer_2_delta,layer_1)*alpha

  if(rev_i % 250 == 0):
    sys.stdout.write('\rProgress:'+str(rev_i/float(len(input_dataset)
        *iterations)) + "   " + str(similar('terrible')))
  sys.stdout.write('\rProgress:'+str(rev_i/float(len(input_dataset)
        *iterations)))
print(similar('terrible'))


  Progress:0.99998 [('terrible', -0.0), ('horrible', -2.846300248788519),
  ('brilliant', -3.039932544396419), ('pathetic', -3.4868595532695967),
  ('superb', -3.6092947961276645), ('phenomenal', -3.660172529098085),
  ('masterful', -3.6856112636664564), ('marvelous', -3.9306620801551664),
```

### Meaning is derived from loss

With this new neural network, you can subjectively see that the word embeddings cluster in a rather different way. Where before words were clustered according to their likelihood to predict a `positive` or `negative` label, now they’re clustered based on their likelihood to occur within the same phrase (sometimes regardless of sentiment).

| Predicting POS/NEG | Fill in the blank |
| --- | --- |
| **print(similar('terrible'))**<br><br>**[('terrible', -0.0),**<br> ('dull', -0.760788602671491),<br> ('lacks', -0.76706470275372),<br> ('boring', -0.7682894961694),<br> ('disappointing', -0.768657),<br> ('annoying', -0.78786389931),<br> ('poor', -0.825784172378292),<br> ('horrible', -0.83154121717),<br> ('laughable', -0.8340279599),<br> ('badly', -0.84165373783678)]<br><br>**print(similar('beautiful'))**<br><br>[**('beautiful', -0.0),**<br> ('atmosphere', -0.70542101298),<br> ('heart', -0.7339429768542354),<br> ('tight', -0.7470388145765346),<br> ('fascinating', -0.7549291974),<br> ('expecting', -0.759886970744),<br> ('beautifully', -0.7603669338),<br> ('awesome', -0.76647368382398),<br> ('masterpiece', -0.7708280057),<br> ('outstanding', -0.7740642167)] | **print(similar('terrible'))**<br><br>[**('terrible', -0.0),**<br> ('horrible', -2.79600898781),<br> ('brilliant', -3.3336178881),<br> ('pathetic', -3.49393193646),<br> ('phenomenal', -3.773268963),<br> ('masterful', -3.8376122586),<br> ('superb', -3.9043150978490),<br> ('bad', -3.9141673639585237),<br> ('marvelous', -4.0470804427),<br> ('dire', -4.178749691835959)]<br><br>**print(similar('beautiful'))**<br><br>[**('beautiful', -0.0),**<br> ('lovely', -3.0145597243116),<br> ('creepy', -3.1975363066322),<br> ('fantastic', -3.2551041418),<br> ('glamorous', -3.3050812101),<br> ('spooky', -3.4881261617587),<br> ('cute', -3.592955888181448),<br> ('nightmarish', -3.60063813),<br> ('heartwarming', -3.6348147),<br> ('phenomenal', -3.645669007)] |

The key takeaway is that, even though the network trained over the same dataset with a very similar architecture (three layers, cross entropy, `sigmoid` nonlinear), you can influence what the network learns within its weights by changing what you tell the network to predict. Even though it’s looking at the same statistical information, you can target what it learns based on what you select as the input and target values. For the moment, let’s call this process of choosing what you want the network to learn *intelligence targeting*.

Controlling the input/target values isn’t the only way to perform intelligence targeting. You can also adjust how the network measures error, the size and types of layers it has, and the types of regularization to apply. In deep learning research, all of these techniques fall under the umbrella of constructing what’s called a *loss function*.

#### Neural networks don’t really learn data; they minimize the loss function

In [chapter 4](/book/grokking-deep-learning/chapter-4/ch04), you learned that learning is about adjusting each weight in the neural network to bring the error down to 0. In this section, I’ll explain the same phenomena from a different perspective, choosing the error so the neural network learns the patterns we’re interested in. Remember these lessons?

##### The golden method for learning

Adjust each weight in the correct direction and by the correct amount so `error` reduces to 0.

**The secret**

For any `input` and `goal_pred`, an exact relationship is defined between `error` and `weight`, found by combining the `prediction` and `error` formulas.

```
error = ((0.5 * weight) - 0.8) ** 2
```

Perhaps you remember this formula from the one-weight neural network. In that network, you could evaluate the error by first forward propagating (`0.5 * weight`) and then comparing to the target (0.8). I encourage you not to think about this from the perspective of two different steps (forward propagation, then error evaluation), but instead to consider the entire formula (including forward prop) to be the evaluation of an error value. This context will reveal the true cause of the different word-embedding clusterings. Even though the network and datasets were similar, the error function was fundamentally different, leading to different word clusterings within each network.

| Predicting POS/NEG | Fill in the blank |
| --- | --- |
| **print(similar('terrible'))**<br><br>**[('terrible', -0.0),**<br> ('dull', -0.760788602671491),<br> ('lacks', -0.76706470275372),<br> ('boring', -0.7682894961694),<br> ('disappointing', -0.768657),<br> ('annoying', -0.78786389931),<br> ('poor', -0.825784172378292),<br> ('horrible', -0.83154121717),<br> ('laughable', -0.8340279599),<br> ('badly', -0.84165373783678)] | **print(similar('terrible'))**<br><br>[('terrible', -0.0),<br> ('horrible', -2.79600898781),<br> ('brilliant', -3.3336178881),<br> ('pathetic', -3.49393193646),<br> ('phenomenal', -3.773268963),<br> ('masterful', -3.8376122586),<br> ('superb', -3.9043150978490),<br> ('bad', -3.9141673639585237),<br> ('marvelous', -4.0470804427),<br> ('dire', -4.178749691835959)] |

#### The choice of loss function determines the neural network’s knowledge

The more formal term for an *error function* is a *loss function* or *objective function* (all three phrases are interchangeable). Considering learning to be all about minimizing a loss function (which includes forward propagation) gives a far broader perspective on how neural networks learn. Two neural networks can have identical starting weights, be trained over identical datasets, and ultimately learn very different patterns because you choose a different loss function. In the case of the two movie review neural networks, the loss function was different because you chose two different target values (positive or negative versus fill in the blank).

Different kinds of architectures, layers, regularization techniques, datasets, and nonlinearities aren’t really that different. These are the ways you can choose to construct a loss function. If the network isn’t learning properly, the solution can often come from any of these possible categories.

For example, if a network is overfitting, you can augment the loss function by choosing simpler nonlinearities, smaller layer sizes, shallower architectures, larger datasets, or more-aggressive regularization techniques. All of these choices will have a fundamentally similar effect on the loss function and a similar consequence on the behavior of the network. They all interplay together, and over time you’ll learn how changing one can affect the performance of another; but for now, the important takeaway is that learning is about constructing a loss function and then minimizing it.

Whenever you want a neural network to learn a pattern, everything you need to know to do so will be contained in the loss function. When you had only a single weight, this allowed the loss function to be simple, as you’ll recall:

| **error = ((0.5 * weight) - 0.8) ** 2** |
| --- |

But as you chain large numbers of complex layers together, the loss function will become more complicated (and that’s OK). Just remember, if something is going wrong, the solution is in the loss function, which includes both the forward prediction and the raw error evaluation (such as mean squared error or cross entropy).

### King – Man + Woman ~= Queen

#### Word analogies are an interesting consequence of the previously built network

Before closing out this chapter, let’s discuss what is, at the time of writing, still one of the most famous properties of neural word embeddings (word vectors like those we just created). The task of filling in the blank creates word embeddings with interesting phenomena known as *word analogies*, wherein you can take the vectors for different words and perform basic algebraic operations on them.

For example, if you train the previous network on a large enough corpus, you’ll be able to take the vector for `king`, subtract from it the vector for `man`, add in the vector for `woman`, and then search for the most similar vector (other than those in the query). As it turns out, the most similar vector is often the word “queen.” There are even similar phenomena in the fill-in-the-blank network trained over movie reviews.

```
12345678910111213141516171819202122232425262728293031323334          def analogy(positive=['terrible','good'],negative=['bad']):

              norms = np.sum(weights_0_1 * weights_0_1,axis=1)
              norms.resize(norms.shape[0],1)

              normed_weights = weights_0_1 * norms

              query_vect = np.zeros(len(weights_0_1[0]))
              for word in positive:
                  query_vect += normed_weights[word2index[word]]
              for word in negative:
                  query_vect -= normed_weights[word2index[word]]

              scores = Counter()
              for word,index in word2index.items():
                  raw_difference = weights_0_1[index] - query_vect
                  squared_difference = raw_difference * raw_difference
                  scores[word] = -math.sqrt(sum(squared_difference))

              return scores.most_common(10)[1:]

     terrible – bad + good ~=                 elizabeth – she + he ~=

analogy(['terrible','good'],['bad'])     analogy(['elizabeth','he'],['she'])

[('superb', -223.3926217861),            [('christopher', -192.7003),
 ('terrific', -223.690648739),            ('it', -193.3250398279812),
 ('decent', -223.7045545791),             ('him', -193.459063887477),
 ('fine', -223.9233021831882),            ('this', -193.59240614759),
 ('worth', -224.03031703075),             ('william', -193.63049856),
 ('perfect', -224.125194533),             ('mr', -193.6426152274126),
 ('brilliant', -224.2138041),             ('bruce', -193.6689279548),
 ('nice', -224.244182032763),             ('fred', -193.69940566948),
 ('great', -224.29115420564)]             ('there', -193.7189421836)]
```

### Word analogies

#### Linear compression of an existing property in the data

When this property was first discovered, it created a flurry of excitement as people extrapolated many possible applications of such a technology. It’s an amazing property in its own right, and it did create a veritable cottage industry around generating word embeddings of one variety or another. But the word analogy property in and of itself hasn’t grown that much since then, and most of the current work in language focuses instead on recurrent architectures (which we’ll get to in [chapter 12](/book/grokking-deep-learning/chapter-12/ch12)).

That being said, getting a good intuition for what’s going on with word embeddings as a result of a chosen loss function is extremely valuable. You’ve already learned that the choice of loss function can affect how words are grouped, but this word analogy phenomenon is something different. What about the new loss function causes it to happen?

If you consider a word embedding having two dimensions, it’s perhaps easier to envision exactly what it means for these word analogies to work.

```
king  = [0.6 , 0.1]
man   = [0.5 , 0.0]
woman = [0.0 , 0.8]
queen = [0.1 , 1.0]

king - man = [0.1 , 0.1]
queen - woman  = [0.1 , 0.2]
```

![](https://drek4537l1klr.cloudfront.net/trask2/Figures/f0207-01.jpg)

The relative usefulness to the final prediction between “king”/“man” and “queen”/“woman” is similar. Why? The difference between “king” and “man” leaves a vector of `royalty`. There are a bunch of male- and female-related words in one grouping, and then there’s another grouping in the royal direction.

This can be traced back to the chosen loss. When the word “king” shows up in a phrase, it changes the probability of other words showing up in a certain way. It increases the probability of words related to “man” and the probability of words related to royalty. The word “queen” appearing in a phrase increases the probability of words related to “woman” and the probability of words related to royalty (as a group). Thus, because the words have this sort of Venn diagram impact on the output probability, they end up subscribing to similar combinations of groupings.

Oversimplified, “king” subscribes to the male and the royal dimensions of the hidden layer, whereas “queen” subscribes to the female and royal dimensions of the hidden layer. Taking the vector for “king” and subtracting out some approximation of the male dimensions and adding in the female ones yields something close to “queen.” The most important takeaway is that this is more about the properties of language than deep learning. Any linear compression of these co-occurrence statistics will behave similarly.

### Summary

#### You’ve learned a lot about neural word embeddings and the impact - of loss on learning

In this chapter, we’ve unpacked the fundamental principles of using neural networks to study language. We started with an overview of the primary problems in natural language processing and then explored how neural networks model language at the word level using word embeddings. You also learned how the choice of loss function can change the kinds of properties that are captured by word embeddings. We finished with a discussion of perhaps the most magical of neural phenomena in this space: word analogies.

As with the other chapters, I encourage you to build the examples in this chapter from scratch. Although it may seem as though this chapter stands on its own, the lessons in loss-function creation and tuning are invaluable and will be extremely important as you tackle increasingly more complicated strategies in future chapters. Good luck!
