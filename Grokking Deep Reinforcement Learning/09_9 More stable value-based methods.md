# 9 More stable value-based methods

### In this chapter

- You will improve on the methods you learned in the previous chapter by making them more stable and therefore less prone to divergence.
- You will explore advanced value-based deep reinforcement learning methods, and the many components that make value-based methods better.
- You will solve the cart-pole environment in a fewer number of samples, and with more reliable and consistent results.

*Let thy step be slow and steady, that thou stumble not.*

— Tokugawa Ieyasu
Founder and first shōgun of the Tokugawa shogunate of Japan and one of the three unifiers of Japan

In the last chapter, you learned about value-based deep reinforcement learning. NFQ, the algorithm we developed, is a simple solution to the two most common issues value-based methods face: first, the issue that data in RL isn’t independent and identically distributed. It’s probably the exact opposite. The experiences are dependent on the policy that generates them. And, they aren’t identically distributed since the policy changes throughout the training process. Second, the targets we use aren’t stationary, either. Optimization methods require fixed targets for robust performance. In supervised learning, this is easy to see. We have a dataset with premade labels as constants, and our optimization method uses these fixed targets for stochastically approximating the underlying data-generating function. In RL, on the other hand, targets such as the TD target use the reward and the discounted predicted return from the landing state as a target. But this predicted return comes from the network we’re optimizing, which changes every time we execute the optimization steps. This issue creates a moving target that creates instabilities in the training process.

The way NFQ addresses these issues is through the use of batching. By growing a batch, we have the opportunity of optimizing several samples at the same time. The larger the batch, the more the opportunity for collecting a diverse set of experience samples. This somewhat addresses the IID assumption. NFQ addresses the stationarity of target requirements by using the same mini-batch in multiple sequential optimization steps. Remember that in NFQ, every E episode, we “fit” the neural network to the same mini-batch *K* times. That *K* allows the optimization method to move toward the target more stably. Gathering a batch and fitting the model for multiple iterations is similar to the way we train supervised learning methods, in which we gather a dataset and train for multiple epochs.

NFQ does an okay job, but we can do better. Now that we know the issues, we can address them using better techniques. In this chapter, we explore algorithms that address not only these issues, but other issues that you learn about making value-based methods more stable.

## DQN: Making reinforcement learning more like supervised learning

The first algorithm that we discuss in this chapter is called *deep Q-network* (DQN[](/book/grokking-deep-reinforcement-learning/chapter-9/)). DQN is one of the most popular DRL algorithms because it started a series of research innovations that mark the history of RL. DQN claimed for the first time superhuman level performance on an Atari benchmark in which agents learned from raw pixel data from mere images.

Throughout the years, there have been many improvements proposed to DQN. And while these days DQN in its original form is not a go-to algorithm, with the improvements, many of which you learn about in this book, the algorithm still has a spot among the best-performing DRL agents.

### Common problems in value-based deep reinforcement learning

We must be clear and understand the two most common problems that consistently show up in value-based deep reinforcement learning: the violations of the IID assumption, and the stationarity of targets.

In supervised learning, we obtain a full dataset in advance. We preprocess it, shuffle it, and then split it into sets for training. One crucial step in this process is the shuffling of the dataset. By doing so, we allow our optimization method to avoid developing overfitting biases; reduce the variance of the training process; speed up convergence; and overall learn a more general representation of the underlying data-generating process. In reinforcement learning, unfortunately, data is often gathered online; as a result, the experience sample generated at time step *t+1* correlates with the experience sample generated at time step *t*. Moreover, as the policy is to improve, it changes the underlying data-generating process changes, too, which means that new data is locally correlated and not evenly distributed.

|   | Boil It Down Data isn’t independently and identically distributed (IID) |
| --- | --- |
|  | The first problem is non-compliance with the IID assumption of the data. Optimization methods have been developed with the assumption that samples in the dataset we train with are independent and identically distributed. We know, however, our samples aren’t independent, but instead, they come from a sequence, a time series, a trajectory. The sample at time step *t*+1 is dependent on the sample at time step *t*. Samples are correlated, and we can’t prevent that from happening; it’s a natural consequence of online learning. But samples are also not identically distributed because they depend on the policy that generates the actions. We know the policy is changing through time, and for us that’s a good thing. We want policies to improve. But that also means the distribution of samples (state-action pairs visited) will change as we keep improving. |

Also, in supervised learning, the targets used for training are fixed values on your dataset; they’re fixed throughout the training process. In reinforcement learning in general, and even more so in the extreme case of online learning, targets move with every training step of the network. At every training update step, we optimize the approximate value function and therefore change the shape of the function, possibly the entire value function. Changing the value function means that the target values change as well, which, in turn, means the targets used are no longer valid. Because the targets come from the network, even before we use them, we can assume targets are invalid or biased at a minimum.

|   | Boil It Down Non-stationarity of targets |
| --- | --- |
|  | The problem of the non-stationarity of targets is depicted. These are the targets we use to train our network, but these targets are calculated using the network itself. As a result, the function changes with every update, in turn changing the targets.  Non-stationarity of targets |

In NFQ, we lessen this problem by using a batch and fitting the network to a small fixed dataset for multiple iterations. In NFQ, we collect a small dataset, calculating targets, and optimize the network several times before going out to collect more samples. By doing this on a large batch of samples, the updates to the neural network are composed of many points across the function, additionally making changes even more stable.

DQN is an algorithm that addresses the question, how do we make reinforcement learning look more like supervised learning? Consider this question for a second, and think about the tweaks you would make to make the data look IID and the targets fixed.

### Using target networks

A straightforward[](/book/grokking-deep-reinforcement-learning/chapter-9/)[](/book/grokking-deep-reinforcement-learning/chapter-9/) way to make target values more stationary is to have a separate network that we can fix for multiple steps and reserve it for calculating more stationary targets. The network with this purpose in DQN is called the *target network*.

![Q-function optimization without a target network](https://drek4537l1klr.cloudfront.net/morales/Figures/09_01.png)

![Q-function approximation with a target network](https://drek4537l1klr.cloudfront.net/morales/Figures/09_02.png)

By using a target network to fix targets, we mitigate the issue of “chasing your own tail” by artificially creating several small supervised learning problems presented sequentially to the agent. Our targets are fixed for as many steps as we fix our target network. This improves our chances of convergence, but not to the optimal values because such things don’t exist with non-linear function approximation, but convergence in general. But, more importantly, it substantially reduces the chance of divergence, which isn’t uncommon in value-based deep reinforcement learning methods.

|   | Show Me The Math Target network gradient update |
| --- | --- |
|  |  |

It’s important to note that in practice we don’t have two “networks,” but instead, we have two instances of the neural network weights. We use the same model architecture and frequently update the weights of the target network to match the weights of the online network, which is the network we optimize on every step. “Frequently” here means something different depending on the problem, unfortunately. It’s common to freeze these target network weights for 10 to 10,000 steps at a time, again depending on the problem. (That’s time steps, not episodes. Be careful there.) If you’re using a convolutional neural network, such as what you’d use for learning in Atari games, then a 10,000-step frequency is the norm. But for more straightforward problems such as the cart-pole environment, 10–20 steps is more appropriate.

By using target networks, we prevent the training process from spiraling around because we’re fixing the targets for multiple time steps, thus allowing the online network weights to move consistently toward the targets before an update changes the optimization problem, and a new one is set. By using target networks, we stabilize training, but we also slow down learning because you’re no longer training on up-to-date values; the frozen weights of the target network can be lagging for up to 10,000 steps at a time. It’s essential to balance stability and speed and tune this hyperparameter.

|   | I Speak Python Use of the target and online networks in DQN[](/book/grokking-deep-reinforcement-learning/chapter-9/)[](/book/grokking-deep-reinforcement-learning/chapter-9/)[](/book/grokking-deep-reinforcement-learning/chapter-9/)[](/book/grokking-deep-reinforcement-learning/chapter-9/) |
| --- | --- |
|  |  |

### Using larger networks

Another way you[](/book/grokking-deep-reinforcement-learning/chapter-9/) can lessen the non-stationarity issue, to some degree, is to use larger networks. With more powerful networks, subtle differences between states are more likely to be detected. Larger networks reduce the aliasing of state-action[](/book/grokking-deep-reinforcement-learning/chapter-9/) pairs; the more powerful the network, the lower the aliasing; the lower the aliasing, the less apparent correlation between consecutive samples. And all of this can make target values and current estimates look more independent of each other.

By “aliasing” here I refer to the fact that two states can look like the same (or quite similar) state to the neural network, but still possibly require different actions. State aliasing can occur when networks lack representational power. After all, neural networks are trying to find similarities to generalize; their job is to find these similarities. But, too small of a network can cause the generalization to go wrong. The network could get fixated with simple, easy to find patterns.

One of the motivations for using a target network is that they allow you to differentiate between correlated states more easily. Using a more capable network helps your network learn subtle differences, too.

But, a more powerful neural network takes longer to train. It needs not only more data (interaction time) but also more compute (processing time). Using a target network is a more robust approach to mitigating the non-stationary problem, but I want you to know all the tricks. It’s favorable for you to know how these two properties of your agent (the size of your networks, and the use of target networks, along with the update frequency), interact and affect final performance in similar ways.

|   | Boil It Down Ways to mitigate the fact that targets in reinforcement learning are non-stationary |
| --- | --- |
|  | [](/book/grokking-deep-reinforcement-learning/chapter-9/) Allow me to restate that to mitigate the non-stationarity issue we can <br>      <br>      Create a target network that provides us with a temporarily stationary target value. <br>      Create large-enough networks so that they can “see” the small differences between similar states (like those temporally correlated). <br>      Target networks work and work well, and have been proven to work multiple times. The technique of “larger networks” is more of a hand-wavy solution than something scientifically proven to work every time. Feel free to experiment with this chapter’s Notebook. You’ll find it easy to change values and test hypotheses. |

### Using experience replay

In our NFQ experiments[](/book/grokking-deep-reinforcement-learning/chapter-9/), we use a mini-batch of 1,024 samples, and train with it for 40 iterations, alternating between calculating new targets and optimizing the network. These 1,024 samples are temporally correlated because most of them belong to the same trajectory, and the maximum number of steps in a cart-pole episode is 500. One way to improve on this is to use a technique called *experience replay*. Experience replay consists of a data structure, often referred to as a replay buffer or a replay memory, that holds experience samples for several steps (much more than 1,024 steps), allowing the sampling of mini-batches from a broad set of past experiences. Having a replay buffer allows the agent two critical things. First, the training process can use a more diverse mini-batch for performing updates. Second, the agent no longer has to fit the model to the same small mini-batch for multiple iterations. Adequately sampling a sufficiently large replay buffer yields a slow-moving target, so the agent can now sample and train on every time step with a lower risk of divergence.

| 0001 | A Bit Of History Introduction of experience replay |
| --- | --- |
|  | Experience replay was introduced by Long-Ji Lin in a paper titled “Self-Improving Reactive Agents Based On Reinforcement Learning, Planning and Teaching,” believe it or not, published in *1992*! That’s right, 1992! Again, that’s when neural networks were referred to as “connectionism” ... Sad times! After getting his PhD from CMU, Dr. Lin moved through several technical roles in many different companies. Currently, he’s a Chief Scientist at Signifyd, leading a team that works on a system to predict and prevent online fraud. |

There are multiple benefits to using experience replay. By sampling at random, we increase the probability that our updates to the neural network have low variance. When we used the batch in NFQ, most of the samples in that batch were correlated and similar. Updating with similar samples concentrates the changes on a limited area of the function, and that potentially overemphasizes the magnitude of the updates. If we sample uniformly at random from a substantial buffer, on the other hand, chances are that our updates to the network are better distributed all across, and therefore more representative of the true value function.

Using a replay buffer also gives the impression our data is IID so that the optimization method is stable. Samples appear independent and identically distributed because of the sampling from multiple trajectories and even policies at once.

By storing experiences and later sampling them uniformly, we make the data entering the optimization method look independent and identically distributed. In practice, the replay buffer needs to have considerable capacity to perform optimally, from 10,000 to 1,000,000 experiences depending on the problem. Once you hit the maximum size, you evict the oldest experience before inserting the new one.

![DQN with a replay buffer](https://drek4537l1klr.cloudfront.net/morales/Figures/09_03.png)

Unfortunately, the implementation becomes a little bit of a challenge when working with high-dimensional observations, because poorly implemented replay buffers hit a hardware memory limit quickly in high-dimensional environments. In image-based environments, for instance, where each state representation is a stack of the four latest image frames, as is common for Atari games, you probably don’t have enough memory on your personal computer to naively store 1,000,000 experience samples. For the cart-pole environment, this isn’t so much of a problem. First, we don’t need 1,000,000 samples, and we use a buffer of size 50,000 instead. But also, states are represented by four-element vectors, so there isn’t so much of an implementation performance challenge.

|   | Show Me The Math Replay buffer gradient update |
| --- | --- |
|  |  |

Nevertheless, by using a replay buffer, your data looks more IID and your targets more stationary than in reality. By training from uniformly sampled mini-batches, you make the RL experiences gathered online look more like a traditional supervised learning dataset with IID data and fixed targets. Sure, data is still changing as you add new and discard old samples, but these changes are happening slowly, and so they go somewhat unnoticed by the neural network and optimizer.

|   | Boil It Down Experience replay makes the data look IID, and targets somewhat stationary |
| --- | --- |
|  | The best solution to the problem of data not being IID is called *experience replay.* The technique is simple, and it’s been around for decades: As your agent collects experiences tuples *e*t*=(S**t**,A**t**,R**t*+1*,S**t*+1) online, we insert them into a data structure, commonly referred to as the *replay buffer* *D*[](/book/grokking-deep-reinforcement-learning/chapter-9/), such that *D={e*1*, e*2 *, ... , e**M**}*. *M*, the size of the replay buffer, is a value often between 10,000 to 1,000,000, depending on the problem. We then train the agent on mini-batches sampled, usually uniformly at random, from the buffer, so that each sample has equal probability of being selected. Though, as you learn in the next chapter, you could possibly sample with another distribution. Just beware because it isn’t that straightforward. We’ll discuss details in the next chapter. |

|   | I Speak Python A simple replay buffer[](/book/grokking-deep-reinforcement-learning/chapter-9/) |
| --- | --- |
|  |  |

### Using other exploration strategies

Exploration is a vital[](/book/grokking-deep-reinforcement-learning/chapter-9/) component of reinforcement learning. In the NFQ algorithm, we use an epsilon-greedy exploration strategy, which consists of acting randomly with epsilon probability. We sample a number from a uniform distribution (0, 1). If the number is less than the hyperparameter constant, called epsilon, your agent selects an action uniformly at random (that’s including the greedy action); otherwise, it acts greedily.

For the DQN experiments, I added to chapter 9’s Notebook some of the other exploration strategies introduced in chapter 4. I adapted them to use them with neural networks, and they are reintroduced next. Make sure to check out all Notebooks and play around.

|   | I Speak Python Linearly decaying epsilon-greedy exploration strategy[](/book/grokking-deep-reinforcement-learning/chapter-9/) |
| --- | --- |
|  |  |

|   | I Speak Python Exponentially decaying epsilon-greedy exploration strategy[](/book/grokking-deep-reinforcement-learning/chapter-9/) |
| --- | --- |
|  |  |

|   | I Speak Python Softmax exploration strategy[](/book/grokking-deep-reinforcement-learning/chapter-9/) |
| --- | --- |
|  |  |

|   | It's In The Details Exploration strategies have an impactful effect on performance |
| --- | --- |
|  |  |

|   | It's In The Details The full deep Q-network (DQN) algorithm[](/book/grokking-deep-reinforcement-learning/chapter-9/) |
| --- | --- |
|  | Our DQN implementation has components and settings similar to our NFQ: <br>      <br>      Approximate the action-value function *Q*(*s,a; θ*). <br>      Use a state-in-values-out architecture (nodes: 4, 512,128, 2). <br>      Optimize the action-value function to approximate the optimal action- value function *q**(*s,a*). <br>      Use off-policy TD targets (*r + gamma*max_a’Q*(*s’,a’; θ*)) to evaluate policies. <br>      Use mean squared error (MSE) for our loss function. <br>      Use RMSprop as our optimizer with a learning rate of 0.0005. <br>      Some of the differences are that in the DQN implementation we now <br>      <br>      Use an exponentially decaying epsilon-greedy strategy to improve policies, decaying from 1.0 to 0.3 in roughly 20,000 steps. <br>      Use a replay buffer with 320 samples min, 50,000 max, and mini-batches of 64. <br>      Use a target network that updates every 15 steps. <br>      DQN has three main steps: <br>      <br>      Collect experience: (*S*t *, A*t *, R**t*+1*, S**t*+1*, D**t*+1), and insert it into the replay buffer. <br>      Randomly sample a mini-batch from the buffer, and calculate the off-policy TD targets for the whole batch: *r + gamma*max_a’Q*(*s’,a’; θ*). <br>      Fit the action-value function *Q*(*s,a; θ*) using MSE and RMSprop[](/book/grokking-deep-reinforcement-learning/chapter-9/). <br> |

| 0001 | A Bit Of History Introduction of the DQN algorithm |
| --- | --- |
|  | DQN was introduced in 2013 by Volodymyr “Vlad” Mnih in a paper called “Playing Atari with Deep Reinforcement Learning.” This paper introduced DQN with experience replay. In 2015, another paper came out, “Human-level control through deep reinforcement learning.” This second paper introduced DQN with the addition of target networks; it’s the full DQN version you just learned about. Vlad got his PhD under Geoffrey Hinton (one of the fathers of deep learning), and works as a research scientist at Google DeepMind. He’s been recognized for his DQN contributions, and has been included in the 2017 MIT Technology Review 35 Innovators under 35 list. |

|   | Tally it Up DQN passes the cart-pole environment |
| --- | --- |
|  | The most remarkable part of the results is that NFQ needs far more samples than DQN to solve the environment; DQN is more sample efficient. However, they take about the same time, both training (compute) and wall-clock time. |

## Double DQN: Mitigating the overestimation of action-value functions

In this section, we introduce one of the main improvements to DQN that have been proposed throughout the years, called *double deep Q-networks* (double DQN, or DDQN[](/book/grokking-deep-reinforcement-learning/chapter-9/)). This improvement consists of adding double learning to our DQN agent. It’s straightforward to implement, and it yields agents with consistently better performance than DQN. The changes required are similar to the changes applied to Q-learning to develop double Q-learning; however, there are several differences that we need to discuss.

### The problem of overestimation, take two

As you can probably remember from chapter 6, Q-learning tends to overestimate action-value functions. Our DQN agent is no different; we’re using the same off-policy TD target, after all, with that max operator. The crux of the problem is simple: We’re taking the max of estimated values. Estimated values are often off-center, some higher than the true values, some lower, but the bottom line is that they’re off. The problem is that we’re always taking the max of these values, so we have a preference for higher values, even if they aren’t correct. Our algorithms show a positive bias, and performance suffers.

|   | Miguel's Analogy The issue with overoptimistic agents, and people |
| --- | --- |
|  | I used to like super-positive people until I learned about double DQN. No, seriously, imagine you meet a very optimistic person; let’s call her DQN. DQN is extremely optimistic. She’s experienced many things in life, from the toughest defeat to the highest success. The problem with DQN, though, is she expects the sweetest possible outcome from every single thing she does, regardless of what she actually does. Is that a problem? One day, DQN went to a local casino. It was the first time, but lucky DQN got the jackpot at the slot machines. Optimistic as she is, DQN immediately adjusted her value function. She thought, “Going to the casino is quite rewarding (the value of *Q*(*s, a*) should be high) because at the casino you can go to the slot machines (next state *s’*) and by playing the slot machines, you get the jackpot [*max_a’Q*(*s’, a’*)]”. But, there are multiple issues with this thinking. To begin with, DQN doesn't play the slot machines every time she goes to the casino. She likes to try new things too (she explores), and sometimes she tries the roulette, poker, or blackjack (tries a different action). Sometimes the slot machine area is under maintenance and not accessible (the environment transitions her somewhere else). Additionally, most of the time when DQN plays the slot machines, she doesn’t get the jackpot (the environment is stochastic). After all, slot machines are called bandits for a reason, not those bandits, the other—never mind. |

### Separating action selection from action evaluation

One way to better understand positive bias and how we can address it when using function approximation is by unwrapping the *max* operator[](/book/grokking-deep-reinforcement-learning/chapter-9/) in the target calculations. The *max* of a Q-function is the same as the Q-function of the *argmax* action[](/book/grokking-deep-reinforcement-learning/chapter-9/).

|   | Refresh My Memory What’s an argmax, again? |
| --- | --- |
|  | The argmax function is defined as the arguments of the maxima. The argmax action-value function, argmax Q-function, *argmax**a**Q*(*s, a*) is the index of the action with the maximum value at the given state s. For example, if you have a *Q*(*s*) with values *[–1, 0 , –4, –9]* for actions 0-3, the *max**a**Q*(*s, a*) is *0*, which is the maximum value, and the *argmax**a**Q*(*s, a*) is *1*, which is the index of the maximum value. |

Let’s unpack the previous sentence with the max and argmax. Notice that we made pretty much the same changes when we went from Q-learning to double Q-learning, but given that we’re using function approximation, we need to be cautious. At first, this unwrapping might seem like a silly step, but it helps me understand how to mitigate this problem.

|   | Show Me The Math Unwrapping the argmax |
| --- | --- |
|  |  |

|   | I Speak Python Unwrapping the max in DQN[](/book/grokking-deep-reinforcement-learning/chapter-9/) |
| --- | --- |
|  |  |

All we’re saying here is that taking the *max* is like asking the network, “What’s the value of the highest-valued action in state *s*?”

But, we are really asking two questions with a single question. First, we do an *argmax*, which is equivalent to asking, “Which action is the highest-valued action in state *s*?”

And then, we use that action to get its value, equivalent to asking, “What’s the value of this action (which happens to be the highest-valued action) in state *s*?”

One of the problems is that we are asking both questions to the same Q-function, which shows bias in the same direction in both answers. In other words, the function approximator will answer, “I think this one is the highest-valued action in state *s*, and this is its value.”

### A solution

A way to reduce the chance of positive bias is to have two instances of the action-value function, the way we did in chapter 6.

If you had another source of the estimates, you could ask one of the questions to one and the other question to the other. It’s somewhat like taking votes, or like an “I cut, you choose first” procedure, or like getting a second doctor’s opinion on health matters.

In double learning, one estimator selects the index of what it believes to be the highest-valued action, and the other estimator gives the value of this action.

|   | Refresh My Memory Double learning procedure |
| --- | --- |
|  | We did this procedure with tabular reinforcement learning in chapter 6 under the double Q-learning agent. It goes like this: <br>      <br>      You create two action-value functions, *Q*A and *Q*B. <br>      You flip a coin to decide which action-value function to update. For example, *Q*A on heads, *Q*B on tails. <br>      If you got a heads and thus get to update *Q*A: You select the action index to evaluate from *Q*B, and evaluate it using the estimate *Q*A predicts. Then, you proceed to update *Q*A as usual, and leave *Q*B alone. <br>      If you got a tails and thus get to update *Q*B, you do it the other way around: get the index from *Q*A, and get the value estimate from *Q*B. *Q*B gets updated, and *Q*A is left alone. <br> |

However, implementing this double-learning procedure exactly as described when using function approximation (for DQN) creates unnecessary overhead. If we did so, we’d end up with four networks: two networks for training (*Q*A, *Q*B) and two target networks, one for each online network.

Additionally, it creates a slowdown in the training process, since we’d be training only one of these networks at a time. Therefore, only one network would improve per step. This is certainly a waste.

Doing this double-learning procedure with function approximators may still be better than not doing it at all, despite the extra overhead. Fortunately for us, there’s a simple modification to the original double-learning procedure that adapts it to DQN and gives us substantial improvements without the extra overhead.

### A more practical solution

Instead of adding this overhead that’s a detriment to training speed, we can perform double learning with the other network we already have, which is the target network. However, instead of training both the online and target networks, we continue training only the online network, but use the target network to help us, in a sense, cross-validate the estimates.

We want to be cautious as to which network to use for action selection and which network to use for action evaluation. Initially, we added the target network to stabilize training by avoiding chasing a moving target. To continue on this path, we want to make sure we use the network we’re training, the online network, for answering the first question. In other words, we use the online network to find the index of the best action. Then, we use the target network to ask the second question, that is, to evaluate the previously selected action.

This is the ordering that works best in practice, and it makes sense why it works. By using the target network for value estimates, we make sure the target values are frozen as needed for stability. If we were to implement it the other way around, the values would come from the online network, which is getting updated at every time step, and therefore changing continuously.

![Selecting action, evaluating action](https://drek4537l1klr.cloudfront.net/morales/Figures/09_04.png)

| 0001 | A Bit Of History Introduction of the double DQN algorithm |
| --- | --- |
|  | Double DQN was introduced in 2015 by Hado van Hasselt, shortly after the release of the 2015 version of DQN. (The 2015 version of DQN is sometimes referred to as Nature DQN—because it was published in the Nature scientific journal, and sometimes as Vanilla DQN—because it is the first of many other improvements over the years.) In 2010, Hado also authored the double Q-learning algorithm (double learning for the tabular case), as an improvement to the Q-learning algorithm. This is the algorithm you learned about and implemented in chapter 6. Double DQN, also referred to as DDQN, was the first of many improvements proposed over the years for DQN. Back in 2015 when it was first introduced, DDQN obtained state-of-the-art (best at the moment) results in the Atari domain. Hado obtained his PhD from the University of Utrecht in the Netherlands in artificial intelligence (reinforcement learning). After a couple of years as a postdoctoral researcher, he got a job at Google DeepMind as a research scientist. |

|   | I Speak Python Double DQN[](/book/grokking-deep-reinforcement-learning/chapter-9/) |
| --- | --- |
|  |  |

### A more forgiving loss function

In the previous chapter, we selected[](/book/grokking-deep-reinforcement-learning/chapter-9/) the L2 loss, also known as *mean square error* (MSE[](/book/grokking-deep-reinforcement-learning/chapter-9/)[](/book/grokking-deep-reinforcement-learning/chapter-9/)), as our loss function, mostly for its widespread use and simplicity. And, in reality, in a problem such as the cart-pole environment, there might not be a good reason to look any further. However, because I’m teaching you the ins and outs of the algorithms and not only “how to hammer the nail,” I’d also like to make you aware of the different knobs available so you can play around when tackling more challenging problems.

![](https://drek4537l1klr.cloudfront.net/morales/Figures/09_05.png)

MSE is a ubiquitous loss function because it’s simple, it makes sense, and it works well. But, one of the issues with using MSE for reinforcement learning is that it penalizes large errors more than small errors. This makes sense when doing supervised learning because our targets are the true value from the get-go, and are fixed throughout the training process. That means we’re confident that, if the model is very wrong, then it should be penalized more heavily than if it’s just wrong.

But as stated now several times, in reinforcement learning, we don’t have these true values, and the values we use to train our network are dependent on the agent itself. That’s a mind shift. Besides, targets are constantly changing; even when using target networks, they still change often. In reinforcement learning, being very wrong is something we expect and welcome. At the end of the day, if you think about it, we aren’t “training” agents; our agents learn on their own. Think about that for a second.

A loss function not as unforgiving, and also more robust to outliers, is the *mean absolute error*[](/book/grokking-deep-reinforcement-learning/chapter-9/)[](/book/grokking-deep-reinforcement-learning/chapter-9/), also known as MAE or L1 loss. MAE is defined as the average absolute difference between the predicted and true values, that is, the predicted action-value function and the TD target. Given that MAE is a linear function as opposed to quadratic such as MSE, we can expect MAE to be more successful at treating large errors the same way as small errors. This can come in handy in our case because we expect our action-value function to give wrong values at some point during training, particularly at the beginning. Being more resilient to outliers often implies errors have less effect, as compared to MSE, in terms of changes to our network, which means more stable learning.

![](https://drek4537l1klr.cloudfront.net/morales/Figures/09_06.png)

Now, on the flip side, one of the helpful things of MSE that MAE doesn’t have is the fact that its gradients decrease as the loss goes to zero. This feature is helpful for optimization methods because it makes it easier to reach the optima: lower gradients mean small changes to the network. But luckily for us, there’s a loss function that’s somewhat a mix of MSE and MAE, called the Huber loss.

The *Huber loss*[](/book/grokking-deep-reinforcement-learning/chapter-9/) has the same useful property as MSE of quadratically penalizing the errors near zero, but it isn’t quadratic all the way out for huge errors. Instead, the Huber loss is quadratic (curved) near-zero error, and it becomes linear (straight) for errors larger than a preset threshold. Having the best of both worlds makes the Huber loss robust to outliers, just like MAE, and differentiable at 0, just like MSE.

![](https://drek4537l1klr.cloudfront.net/morales/Figures/09_07.png)

The Huber loss uses a hyperparameter, *δ,* to set this threshold in which the loss goes from quadratic to linear, basically, from MSE to MAE. If *δ* is zero, you’re left precisely with MAE, and if *δ* is infinite, then you’re left precisely with MSE. A typical value for *δ* is 1, but be aware that your loss function, optimization, and learning rate interact in complex ways. If you change one, you may need to tune several of the others. Check out the Notebook for this chapter so you can play around.

![](https://drek4537l1klr.cloudfront.net/morales/Figures/09_08.png)

Interestingly, there are at least two different ways of implementing the Huber loss function. You could either compute the Huber loss as defined, or compute the MSE loss instead, and then set all gradients larger than a threshold to a fixed magnitude value. You clip the magnitude of the gradients. The former depends on the deep learning framework you use, but the problem is that some frameworks don’t give you access to the *δ* hyperparameter, so you’re stuck with *δ* set to 1, which doesn’t always work, and isn’t always the best. The latter, often referred to as *loss clipping,* or better yet *gradient clipping,* is more flexible and, therefore, what I implement in the Notebook.

|   | I Speak Python Double DQN with Huber loss[](/book/grokking-deep-reinforcement-learning/chapter-9/)[](/book/grokking-deep-reinforcement-learning/chapter-9/) |
| --- | --- |
|  |  |

Know that there’s such a thing as *reward clipping[](/book/grokking-deep-reinforcement-learning/chapter-9/)*, which is different than *gradient clipping[](/book/grokking-deep-reinforcement-learning/chapter-9/)*. These are two very different things, so beware. One works on the rewards and the other on the errors (the loss). Now, above all don’t confuse either of these with *Q-value clipping,* which is undoubtedly a mistake.

Remember, the goal in our case is to prevent gradients from becoming too large. For this, we either make the loss linear outside a given absolute TD error threshold or make the gradient constant outside a max gradient magnitude threshold.

In the cart-pole environment experiments that you find in the Notebook, I implement the Huber loss function by using the gradient clipping technique. That is, I calculate MSE and then clip the gradients. However, as I mentioned before, I set the hyperparameter setting for the maximum gradient values to infinity. Therefore, it’s effectively using good-old MSE. But, please, experiment, play around, explore! The Notebooks I created should help you learn almost as much as the book. Set yourself free over there.

|   | It's In The Details The full double deep Q-network (DDQN) algorithm |
| --- | --- |
|  | [](/book/grokking-deep-reinforcement-learning/chapter-9/) DDQN is almost identical to DQN, but there are still several differences: <br>      <br>      Approximate the action-value function *Q*(*s, a; θ*). <br>      Use a state-in-values-out architecture (nodes: 4, 512,128, 2). <br>      Optimize the action-value function to approximate the optimal action- value function *q**(*s,a*). <br>      Use off-policy TD targets (*r + gamma*max_a’Q*(*s’,a’; θ*)) to evaluate policies. <br>      Notice that we now <br>      <br>      Use an adjustable Huber loss, which, since we set the max_gradient_norm variable to “float(‘inf’),” we’re effectively using mean squared error (MSE) for our loss function. <br>      Use RMSprop as our optimizer with a learning rate of 0.0007. Note that before we used 0.0005 because without double learning (vanilla DQN), several seeds fail if we train with a learning rate of 0.0007. Perhaps stability? In DDQN, on the other hand, training with a higher learning rate works best. <br>      In DDQN we’re still using <br>      <br>      An exponentially decaying epsilon-greedy strategy (from 1.0 to 0.3 in roughly 20,000 steps) to improve policies. <br>      A replay buffer with 320 samples min, 50,000 max, and a batch of 64. <br>      A target network that freezes for 15 steps and then updates fully. <br>      DDQN, similar to DQN, has the same three main steps: <br>      <br>      Collect experience: (*S**t**, A**t**, R**t*+1*, S**t*+1*, D**t*+1), and insert it into the replay buffer. <br>      Randomly sample a mini-batch from the buffer and calculate the off-policy TD targets for the whole batch: *r + gamma*max_a’Q*(*s’,a’; θ*). <br>      Fit the action-value function *Q(s, a; θ) using MSE and RMSprop[](/book/grokking-deep-reinforcement-learning/chapter-9/).* <br>      The bottom line is that the DDQN implementation and hyperparameters are identical to those of DQN, except that we now use double learning and therefore train with a slightly higher learning rate. The addition of the Huber loss doesn’t change anything because we’re “clipping” gradients to a max value of infinite, which is equivalent to using MSE. However, for many other environments you’ll find it useful, so tune this hyperparameter. |

|   | Tally it Up DDQN is more stable than NFQ or DQN |
| --- | --- |
|  | DQN and DDQN have similar performance in the cart-pole environment. However, this is a simple environment with a smooth reward function. In reality, DDQN should always give better performance. |

### Things we can still improve on

Surely our current value-based deep reinforcement learning method isn’t perfect, but it’s pretty solid. DDQN can reach superhuman performance in many of the Atari games. To replicate those results, you’d have to change the network to take images as input (a stack of four images to be able to infer things such as direction and velocity from the images), and, of course, tune the hyperparameters.

Yet, we can still go a little further. There are at least a couple of other improvements to consider that are easy to implement and impact performance in a positive way.

The first improvement requires us to reconsider the current network architecture. As of right now, we have a naive representation of the Q-function on our neural network architecture.

|   | Refresh My Memory Current neural network architecture |
| --- | --- |
|  | We’re literately “making reinforcement learning look like supervised learning.” But, we can, and should, break free from this constraint, and think out of the box.  State-in-values-out architecture Is there any better way of representing the Q-function? Think about this for a second while you look at the images on the next page. |

The images on the right are bar plots representing the estimated action-value function Q, state-value function V, and action-advantage function A for the cart-pole environment with a state in which the pole is near vertical.

![](https://drek4537l1klr.cloudfront.net/morales/Figures/09_09a.png)

Notice the different functions and values and start thinking about how to better architect the neural network so that data is used more efficiently. As a hint, let me remind you that the Q-values of a state are related through the V-function. That is, the action-value function *Q* has an essential relationship with the state-value function V, because of both actions in *Q*(*s*) are indexed by the same state *s* (in the example to the right *s*=[0.02, –0.01, –0.02, –0.04]).

![](https://drek4537l1klr.cloudfront.net/morales/Figures/09_09b.png)

The question is, could you learn anything about *Q*(*s*, 0) if you’re using a *Q*(*s*, 1) sample? Look at the plot showing the action-advantage function *A*(*s*) and notice how much easier it is for you to eyeball the greedy action with respect to these estimates than when using the plot with the action-value function *Q*(*s*). What can you do about this? In the next chapter, we look at a network architecture called the *dueling network* that helps us exploit these relationships.

![](https://drek4537l1klr.cloudfront.net/morales/Figures/09_09c.png)

The other thing to consider improving is the way we sample experiences from the replay buffer. As of now, we pull samples from the buffer uniformly at random, and I’m sure your intuition questions this approach and suggests we can do better, and we can.

Humans don’t go around the world remembering random things to learn from at random times. There’s a more systematic way in which intelligent agents “replay memories.” I’m pretty sure my dog chases rabbits in her sleep. Certain experiences are more important than others to our goals. Humans often replay experiences that caused them unexpected joy or pain. And it makes sense, and you need to learn from these experiences to generate more or less of them. In the next chapter, we look at ways of prioritizing the sampling of experiences to get the most out of each sample, when we learn about the prioritized experience replay (PER) method.

## Summary

In this chapter, you learned about the widespread issues with value-based deep reinforcement learning methods. The fact that online data isn’t stationary, and it also isn’t independent and identically distributed as most optimization methods expect, creates an enormous amount of problems value-based methods are susceptible to.

You learned to stabilize value-based deep reinforcement learning methods by using a variety of techniques that have empirical results in several benchmarks, and you dug deep on these components that make value-based methods more stable. Namely, you learned about the advantages of using target networks and replay buffers in an algorithm known as DQN (nature DQN, or vanilla DQN). You learned that by using target networks, we make the targets appear stationary to the optimizer, which is good for stability, albeit by sacrificing convergence speed. You also learned that by using replay buffers, the online data looks more IID, which, you also learned, is a source of significant issues in value-based bootstrapping methods. These two techniques combined make the algorithm sufficiently stable for performing well in several deep reinforcement learning tasks.

However, there are many more potential improvements to value-based methods. You implemented a straightforward change that has a significant impact on performance, in general. You added a double-learning strategy to the baseline DQN agent that, when using function approximation, is known as the DDQN agent, and it mitigates the issues of overestimation in off-policy value-based methods.

In addition to these new algorithms, you learned about different exploration strategies to use with value-based methods. You learned about linearly and exponentially decaying epsilon-greedy and softmax exploration strategies, this time, in the context of function approximation. Also, you learned about different loss functions and which ones make more sense for reinforcement learning and why. You learned that the Huber loss function allows you to tune between MSE and MAE with a single hyperparameter, and it’s one of the preferred loss functions used in value-based deep reinforcement learning methods.

By now, you

- Understand why using online data for training neural network with optimizers that expect stationary and IID data is a problem in value-based DRL methods
- Can solve reinforcement learning problems with continuous state-spaces with algorithms that are more stable and therefore give more consistent results
- Have an understanding of state-of-the-art, value-based, deep reinforcement learning methods and can solve complex problems

Build it yourself with a liveProject!Deep Reinforcement Learning for Self-Driving RobotsInvestigate reinforcement learning approaches that allow autonomous robotic carts to navigate a warehouse floor without any bumps or crashes. Buy this related liveProject and put theory to practice!view liveProject![Deep Reinforcement Learning for Self-Driving Robots](https://images.manning.com/264/352/resize/liveProject/1/09fdbbd-4f48-4338-acf6-707d0ecd0cf4/DeepReinforcementLearningforSelf-drivingRobots.jpg)

|   | Tweetable Feat Work on your own and share your findings |
| --- | --- |
|  | Here are several ideas on how to take what you have learned to the next level. If you’d like, share your results with the rest of the world and make sure to check out what others have done, too. It’s a win-win situation, and hopefully, you'll take advantage of it. <br>      <br>      **#gdrl_ch09_tf01:** In this and the next chapter, we test the algorithms only in the cart-pole environment. Find a couple other environments and test the agents in those, for instance, the lunar lander environment here: [https://gym.openai.com/envs/#box2d](https://gym.openai.com/envs/#box2d), and the mountain car environment here: [https://gym.openai.com/envs/#classic_control](https://gym.openai.com/envs/#classic_control). Did you have to make any changes to the agents, excluding hyperparameters, to make the agents work in these environments? Make sure to find a single set of hyperparameters that solve all environments. To clarify, I mean you use a single set of hyperparameters, and train an agent from scratch in each environment, not a single trained agent that does well in all environments. <br>      **#gdrl_ch09_tf02:** In this and the next chapter, we test the algorithms in environments that are continuous, but low dimensional. You know what a high-dimensional environment is? Atari environments. Look them up here (the non “ram”): [https://gym.openai.com/envs/#atari](https://gym.openai.com/envs/#atari). Now, modify the networks, replay buffer, and agent code in this chapter so that the agent can solve image-based environments. Beware that this isn’t a trivial task, and training will take a while, from many hours to several days. <br>      **#gdrl_ch09_tf03:** I mentioned that value-based methods are sensitive to hyperparameters. In reality, there’s something called the “deadly triad,” that basically tells us using neural networks with bootstrapping and off-policy is bad. Investigate! <br>      **#gdrl_ch09_tf04:** In every chapter, I’m using the final hashtag as a catchall hashtag. Feel free to use this one to discuss anything else that you worked on relevant to this chapter. There’s no more exciting homework than that which you create for yourself. Make sure to share what you set yourself to investigate and your results. <br>      Write a tweet with your findings, tag me @mimoralea (I’ll retweet), and use the particular hashtag from the list to help interested folks find your results. There are no right or wrong results; you share your findings and check others’ findings. Take advantage of this to socialize, contribute, and get yourself out there! We’re waiting for you! Here’s a tweet example: “Hey, @mimoralea. I created a blog post with a list of resources to study deep reinforcement learning. Check it out at <link>. #gdrl_ch01_tf01” I’ll make sure to retweet and help others find your work. |
