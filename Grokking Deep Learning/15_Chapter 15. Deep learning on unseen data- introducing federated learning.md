# Chapter 15. Deep learning on unseen data: introducing federated learning

### **In this chapter**

- The problem of privacy in deep learning
- Federated learning
- Learning to detect spam
- Hacking into federated learning
- Secure aggregation
- Homomorphic encryption
- Homomorphically encrypted federated learning

“Friends don’t spy; true friendship is about privacy, too.”

*Stephen King, *Hearts in Atlantis* (1999)*

### The problem of privacy in deep learning

#### Deep learning (and tools for it) often means you have access to y- your training data

As you’re keenly aware by now, deep learning, being a subfield of machine learning, is all about learning from data. But often, the data being learned from is incredibly personal. The most meaningful models interact with the most personal information about human lives and tell us things about ourselves that might have been difficult to know otherwise. To paraphrase, a deep learning model can study thousands of lives to help you better understand your own.

The primary natural resource for deep learning is training data (either synthetic or natural). Without it, deep learning can’t learn; and because the most valuable use cases often interact with the most personal datsets, deep learning is often a reason behind companies seeking to aggregate data. They need it in order to solve a particular use case.

But in 2017, Google published a very exciting paper and blog post that made a significant dent in this conversation. Google proposed that we don’t need to centralize a dataset in order to train a model over it. The company proposed this question: what if instead of bringing all the data to one place, we could bring the model to the data? This is a new, exciting subfield of machine learning called *federated learning*, and it’s what this chapter is about.

What if instead of bringing the corpus of training data to one place to train a model, you could bring the model to the data wherever it’s generated?

This simple reversal is extremely important. First, it means in order to participate in the deep learning supply chain, people don’t technically have to send their data to anyone. Valuable models in healthcare, personal management, and other sensitive areas can be trained without requiring anyone to disclose information about themselves. In theory, people could retain control over the only copy of their personal data (at least as far as deep learning is concerned).

This technique will also have a huge impact on the competitive landscape of deep learning in corporate competition and entrepreneurship. Large enterprises that previously wouldn’t (or couldn’t, for legal reasons) share data about their customers can potentially still earn revenue from that data. There are some problem domains where the sensitivity and regulatory constraints surrounding the data have been a headwind to progress. Healthcare is one example where datasets are often locked up tight, making research challenging.

### Federated learning

#### You don’t have to have access to a dataset in order to learn from it

The premise of federated learning is that many datasets contain information that’s useful for solving problems (for example, identifying cancer in an MRI), but it’s hard to access these relevant datasets in large enough quantities to train a suitably strong deep learning model. The main concern is that, even though the dataset has information sufficient to train a deep learning model, it also has information that (presumably) has nothing to do with learning the task but could potentially harm someone if it were revealed.

Federated learning is about a model going into a secure environment and learning how to solve a problem without needing the data to move anywhere. Let’s jump into an example.

```
import numpy as np
from collections import Counter
import random
import sys
import codecs
np.random.seed(12345)
with codecs.open('spam.txt',"r",encoding='utf-8',errors='ignore') as f: #1
    raw = f.readlines()

vocab, spam, ham = (set(["<unk>"]), list(), list())
for row in raw:
    spam.append(set(row[:-2].split(" ")))
    for word in spam[-1]:
        vocab.add(word)

with codecs.open(`ham.txt',"r",encoding='utf-8',errors='ignore') as f:
    raw = f.readlines()

for row in raw:
    ham.append(set(row[:-2].split(" ")))
    for word in ham[-1]:
        vocab.add(word)

vocab, w2i = (list(vocab), {})
for i,w in enumerate(vocab):
    w2i[w] = i

def to_indices(input, l=500):
    indices = list()
    for line in input:
        if(len(line) < l):
            line = list(line) + ["<unk>"] * (l - len(line))
            idxs = list()
            for word in line:
                idxs.append(w2i[word])
            indices.append(idxs)
    return indices
```

### Learning to detect spam

#### Let’s say you want to train a model across people’s emails to detect spam

The use case we’ll talk about is email classification. The first model will be trained on a publicly available dataset called the Enron dataset, which is a large corpus of emails released from the famous Enron lawsuit (now an industry standard email analytics corpus). Fun fact: I used to know someone who read/annotated this dataset professionally, and people emailed all sorts of crazy stuff to each other (much of it very personal). But because it was all released to the public in the court case, it’s free to use now.

The code in the previous section and this section is just the preprocessing. The input data files (ham.txt and spam.txt) are available on the book’s website, [www.manning.com/books/grokking-deep-learning](http://www.manning.com/books/grokking-deep-learning); and on GitHub at [https://github.com/iamtrask/Grokking-Deep-Learning](https://github.com/iamtrask/Grokking-Deep-Learning). You preprocess it to get it ready to forward propagate into the embedding class created in [chapter 13](/book/grokking-deep-learning/chapter-13/ch13) when you created a deep learning framework. As before, all the words in this corpus are turned into lists of indices. You also make all the emails exactly 500 words long by either trimming the email or padding it with `<unk>` tokens. Doing so makes the final dataset square.

```
12345678910111213141516171819202122232425262728293031323334353637383940414243444546474849505152535455565758596061spam_idx = to_indices(spam)
ham_idx = to_indices(ham)

train_spam_idx = spam_idx[0:-1000]
train_ham_idx = ham_idx[0:-1000]

test_spam_idx = spam_idx[-1000:]
test_ham_idx = ham_idx[-1000:]

train_data = list()
train_target = list()

test_data = list()
test_target = list()

for i in range(max(len(train_spam_idx),len(train_ham_idx))):
    train_data.append(train_spam_idx[i%len(train_spam_idx)])
    train_target.append([1])

    train_data.append(train_ham_idx[i%len(train_ham_idx)])
    train_target.append([0])

for i in range(max(len(test_spam_idx),len(test_ham_idx))):
    test_data.append(test_spam_idx[i%len(test_spam_idx)])
    test_target.append([1])

    test_data.append(test_ham_idx[i%len(test_ham_idx)])
    test_target.append([0])

def train(model, input_data, target_data, batch_size=500, iterations=5):
    n_batches = int(len(input_data) / batch_size)
    for iter in range(iterations):
        iter_loss = 0
        for b_i in range(n_batches):

            # padding token should stay at 0
            model.weight.data[w2i['<unk>']] *= 0
            input = Tensor(input_data[b_i*bs:(b_i+1)*bs], autograd=True)
           target = Tensor(target_data[b_i*bs:(b_i+1)*bs], autograd=True)

            pred = model.forward(input).sum(1).sigmoid()
            loss = criterion.forward(pred,target)
            loss.backward()
            optim.step()

            iter_loss += loss.data[0] / bs

            sys.stdout.write("\r\tLoss:" + str(iter_loss / (b_i+1)))
        print()
    return model


def test(model, test_input, test_output):

    model.weight.data[w2i['<unk>']] *= 0

    input = Tensor(test_input, autograd=True)
    target = Tensor(test_output, autograd=True)

    pred = model.forward(input).sum(1).sigmoid()
    return ((pred.data > 0.5) == target.data).mean()
```

With these nice `train()` and `test()` functions, you can initialize a neural network and train it using the following few lines. After only three iterations, the network can already classify on the test dataset with 99.45% accuracy (the test dataset is balanced, so this is quite good):

| model = Embedding(vocab_size=len(vocab), dim=1)<br>model.weight.data *= 0<br>criterion = MSELoss()<br>optim = SGD(parameters=model.get_parameters(), alpha=0.01)<br><br>for i in range(3):<br>    model = train(model, train_data, train_target, iterations=1)<br>    print("% Correct on Test Set: " + \<br>          str(test(model, test_data, test_target)*100)) |
| --- |
| Loss:0.037140416860871446<br>% Correct on Test Set: **98.65**<br>       Loss:0.011258669226059114<br>% Correct on Test Set: **99.15**<br>       Loss:0.008068268387986223<br>% Correct on Test Set: **99.45** |

### Let’s make it federated

#### The previous example was plain vanilla deep learning. Let’s protect privacy

In the previous section, you got the email example. Now, let’s put all the emails in one place. This is the old-school way of doing things (which is still far too common in the world). Let’s start by simulating a federated learning environment that has multiple different collections of emails:

```
123bob = (train_data[0:1000], train_target[0:1000])
alice = (train_data[1000:2000], train_target[1000:2000])
sue = (train_data[2000:], train_target[2000:])
```

Easy enough. Now you can do the same training as before, but across each person’s email database all at the same time. After each iteration, you’ll average the values of the models from Bob, Alice, and Sue and evaluate. Note that some methods of federated learning aggregate after each batch (or collection of batches); I’m keeping it simple:

```
123456789101112131415161718192021for i in range(3):
    print("Starting Training Round...")
    print("\tStep 1: send the model to Bob")
    bob_model = train(copy.deepcopy(model), bob[0], bob[1], iterations=1)

    print("\n\tStep 2: send the model to Alice")
    alice_model = train(copy.deepcopy(model),
                        alice[0], alice[1], iterations=1)

    print("\n\tStep 3: Send the model to Sue")
    sue_model = train(copy.deepcopy(model), sue[0], sue[1], iterations=1)

    print("\n\tAverage Everyone's New Models")
    model.weight.data = (bob_model.weight.data + \
                         alice_model.weight.data + \
                         sue_model.weight.data)/3

    print("\t% Correct on Test Set: " + \
          str(test(model, test_data, test_target)*100))

    print("\nRepeat!!\n")
```

The next section shows the results. The model learns to nearly the same performance as before, and in theory you didn’t have access to the training data—or did you? After all, each person is changing the model somehow, right? Can you really not discover anything about their dataset?

```
1234567891011Starting Training Round...
  Step 1: send the model to Bob
  Loss:0.21908166249699718

           ......

   Step 3: Send the model to Sue
 Loss:0.015368461608470256

 Average Everyone's New Models
 % Correct on Test Set: 98.8
```

### Hacking into federated learning

#### Let’s use a toy example to see how to still learn the training dataset

Federated learning has two big challenges, both of which are at their worst when each person in the training dataset has only a small handful of training examples. These challenges are performance and privacy. As it turns out, if someone has only a few training examples (or the model improvement they send you uses only a few examples: a training batch), you can still learn quite a bit about the data. Given 10,000 people (each with a little data), you’ll spend most of your time sending the model back and forth and not much time training (especially if the model is really big).

But we’re getting ahead of ourselves. Let’s see what you can learn when a user performs a weight update over a single batch:

```
123456789101112import copy

bobs_email = ["my", "computer", "password", "is", "pizza"]

bob_input = np.array([[w2i[x] for x in bobs_email]])
bob_target = np.array([[0]])

model = Embedding(vocab_size=len(vocab), dim=1)
model.weight.data *= 0

bobs_model = train(copy.deepcopy(model),
                   bob_input, bob_target, iterations=1, batch_size=1)
```

Bob is going to create an update to the model using an email in his inbox. But Bob saved his password in an email to himself that says, “My computer password is pizza.” Silly Bob. By looking at which weights changed, you can figure out the vocabulary (and infer the meaning) of Bob’s email:

```
123for i, v in enumerate(bobs_model.weight.data - model.weight.data):
    if(v != 0):
    print(vocab[i])
```

```
12345is
pizza
computer
password
my
```

And just like that, you learned Bob’s super-secret password (and probably his favorite food, too). What’s to be done? How can you use federated learning if it’s so easy to tell what the training data was from the weight update?

### Secure aggregation

#### Let’s average weight updates from zillions of people before anyone can see them

The solution is to never let Bob put a gradient out in the open like that. How can Bob contribute his gradient if people shouldn’t see it? The social sciences use an interesting technique called *randomized response*.

It goes like this. Let’s say you’re conducting a survey, and you want to ask 100 people whether they’ve committed a heinous crime. Of course, all would answer “No” even if you promised them you wouldn’t tell. Instead, you have them flip a coin twice (somewhere you can’t see), and tell them that if the first coin flip is heads, they should answer honestly; and if it’s tails, they should answer “Yes” or “No” according to the second coin flip.

Given this scenario, you never actually ask people to tell you whether they committed crimes. The true answers are hidden in the random noise of the first and second coin flips. If 60% of people say “Yes,” you can determine (using simple math) that about 70% of the people you surveyed committed heinous crimes (give or take a few percentage points). The idea is that the random noise makes it plausible that any information you learn about the person came from the noise instead of from them.

##### Privacy via plausible deniability

The level of chance that a particular answer came from random noise instead of an individual protects their privacy by giving them plausible deniability. This forms the basis for secure aggregation and, more generally, much of differential privacy.

You’re looking only at aggregate statistics overall. (You never see anyone’s answer directly; you see only pairs of answers or perhaps larger groupings.) Thus, the more people you can aggregate before adding noise, the less noise you have to add to hide them (and the more accurate the findings are).

In the context of federated learning, you could (if you wanted) add a ton of noise, but this would hurt training. Instead, first sum all the gradients from all the participants in such a way that no one can see anyone’s gradient but their own. The class of problems for doing this is called *secure aggregation*, and in order to do it, you’ll need one more (very cool) tool: *homomorphic encryption*.

### Homomorphic encryption

#### You can perform arithmetic on encrypted values

One of the most exciting frontiers of research is the intersection of artificial intelligence (including deep learning) and cryptography. Front and center in this exciting intersection is a very cool technology called homomorphic encryption. Loosely stated, homomorphic encryption lets you perform computation on encrypted values without decrypting them.

In particular, we’re interested in performing addition over these values. Explaining exactly how it works would take an entire book on its own, but I’ll show you how it works with a few definitions. First, a *public key* lets you encrypt numbers. A *private key* lets you decrypt encrypted numbers. An encrypted value is called a *ciphertext*, and an unencrypted value is called a *plaintext*.

Let’s see an example of homomorphic encryption using the phe library. (To install the library, run `pip install phe` or download it from GitHub at [https://github.com/n1analytics/python-paillier](https://github.com/n1analytics/python-paillier)):

```
12345678910111213import phe

public_key, private_key = phe.generate_paillier_keypair(n_length=1024)

x = public_key.encrypt(5)

y = public_key.encrypt(3)

z = x + y

z_ = private_key.decrypt(z)
print("The Answer: " + str(z_))
```

```
The Answer: 8
```

This code encrypts two numbers (5 and 3) and adds them together while they’re still encrypted. Pretty neat, eh? There’s another technique that’s a sort-of cousin to homomorphic encryption: *secure multi-party computation*. You can learn about it at the “Cryptography and Machine Learning” blog ([https://mortendahl.github.io](https://mortendahl.github.io)).

Now, let’s return to the problem of secure aggregation. Given your new knowledge that you can add together numbers you can’t see, the answer becomes plain. The person who initializes the model sends a `public_key` to Bob, Alice, and Sue so they can each encrypt their weight updates. Then, Bob, Alice, and Sue (who don’t have the private key) talk directly to each other and accumulate all their gradients into a single, final update that’s sent back to the model owner, who decrypts it with the `private_key`.

### Homomorphically encrypted federated learning

#### Let’s use homomorphic encryption to protect the gradients being aggregated

```
1234567891011121314151617181920212223242526272829303132333435363738394041424344454647model = Embedding(vocab_size=len(vocab), dim=1)
model.weight.data *= 0

# note that in production the n_length should be at least 1024
public_key, private_key = phe.generate_paillier_keypair(n_length=128)

def train_and_encrypt(model, input, target, pubkey):
    new_model = train(copy.deepcopy(model), input, target, iterations=1)

    encrypted_weights = list()
    for val in new_model.weight.data[:,0]:
        encrypted_weights.append(public_key.encrypt(val))
    ew = np.array(encrypted_weights).reshape(new_model.weight.data.shape)

    return ew

for i in range(3):
    print("\nStarting Training Round...")
    print("\tStep 1: send the model to Bob")
    bob_encrypted_model = train_and_encrypt(copy.deepcopy(model),
                                            bob[0], bob[1], public_key)

    print("\n\tStep 2: send the model to Alice")
    alice_encrypted_model=train_and_encrypt(copy.deepcopy(model),
                                            alice[0],alice[1],public_key)

    print("\n\tStep 3: Send the model to Sue")
    sue_encrypted_model = train_and_encrypt(copy.deepcopy(model),
                                            sue[0], sue[1], public_key)

    print("\n\tStep 4: Bob, Alice, and Sue send their")
    print("\tencrypted models to each other.")
    aggregated_model = bob_encrypted_model + \
                       alice_encrypted_model + \
                       sue_encrypted_model

    print("\n\tStep 5: only the aggregated model")
    print("\tis sent back to the model owner who")
    print("\t can decrypt it.")
    raw_values = list()
    for val in sue_encrypted_model.flatten():
        raw_values.append(private_key.decrypt(val))
    new = np.array(raw_values).reshape(model.weight.data.shape)/3
    model.weight.data = new

    print("\t% Correct on Test Set: " + \
              str(test(model, test_data, test_target)*100))
```

Now you can run the new training scheme, which has an added step. Alice, Bob, and Sue add up their homomorphically encrypted models before sending them back to you, so you never see which updates came from which person (a form of plausible deniability). In production, you’d also add some additional random noise sufficient to meet a certain privacy threshold required by Bob, Alice, and Sue (according to their personal preferences). More on that in future work.

```
123456789101112Starting Training Round...
  Step 1: send the model to Bob
  Loss:0.21908166249699718

  Step 2: send the model to Alice
  Loss:0.2937106899184867

             ...
             ...
             ...

  % Correct on Test Set: 99.15
```

### Summary

#### Federated learning is one of the most exciting breakthroughs in deep learning

I firmly believe that federated learning will change the landscape of deep learning in the coming years. It will unlock new datasets that were previously too sensitive to work with, creating great social good as a result of this newly available entrepreneurial opportunities. This is part of a broader convergence between encryption and artificial intelligence research that, in my opinion, is the most exciting convergence of the decade.

The main thing holding back these techniques from practical use is their lack of availability in modern deep learning toolkits. The tipping point will be when anyone can run `pip install...` and then have access to deep learning frameworks where privacy and security are first-class citizens, and where techniques such as federated learning, homomorphic encryption, differential privacy, and secure multi-party computation are all built in (and you don’t have to be an expert to use them).

Out of this belief, I’ve been working with a team of open source volunteers as a part of the OpenMined project for the past year, extending major deep learning frameworks with these primitives. If you believe in the importance of these tools to the future of privacy and security, come check us out at [http://openmined.org](http://openmined.org) or at the GitHub repository ([https://github.com/OpenMined](https://github.com/OpenMined)). Show your support, even if it’s only starring a few repos; and do join if you can (slack.openmined.org is the chat room).
