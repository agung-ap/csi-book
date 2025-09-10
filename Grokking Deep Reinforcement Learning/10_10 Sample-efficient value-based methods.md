# 10 Sample-efficient value-based methods

### In this chapter

- You will implement a deep neural network architecture that exploits some of the nuances that exist in value-based deep reinforcement learning methods.
- You will create a replay buffer that prioritizes experiences by how surprising they are.
- You will build an agent that trains to a near-optimal policy in fewer episodes than all the value-based deep reinforcement learning agents we’ve discussed.

*Intelligence is based on how efficient a species became at doing the things they need to survive.*

— Charles Darwin
English naturalist, geologist, and biologist Best known for his contributions to the science of evolution

In the previous chapter, we improved on NFQ with the implementation of DQN and DDQN. In this chapter, we continue on this line of improvements to previous algorithms by presenting two additional techniques for improving value-based deep reinforcement learning methods. This time, though, the improvements aren’t so much about stability, although that could easily be a by-product. But more accurately, the techniques presented in this chapter improve the sample-efficiency of DQN and other value-based DRL methods.

First, we introduce a functional neural network architecture that splits the Q-function representation into two streams. One stream approximates the V-function, and the other stream approximates the A-function. V-functions are per-state values, while A-functions express the distance of each action from their V-functions.

This is a handy fact for designing RL-specialized architectures that are capable of squeezing information from samples coming from all action in a given state into the V-function for that same state. What that means is that a single experience tuple can help improve the value estimates of all the actions in that state. This improves the sample efficiency of the agent.

The second improvement we introduce in this chapter is related to the replay buffer. As you remember from the previous chapter, the standard replay buffer in DQN samples experiences uniformly at random. It’s crucial to understand that sampling uniformly at random is a good thing for keeping gradients proportional to the true data-generating underlying distribution, and therefore keeping the updates unbiased. The issue is, however, that if we could devise a way for prioritizing experiences, we could use the samples that are the most promising for learning. Therefore, in this chapter, we introduce a different technique for sampling experiences that allows us to draw samples that appear to provide the most information to the agent for actually making improvements.

## Dueling DDQN: A reinforcement-learning-aware neural network architecture

Let’s now dig into the details of this specialized neural network architecture called the *dueling network architecture*. The dueling network is an improvement that applies only to the network architecture and not the algorithm. That is, we won’t make any changes to the algorithm, but the only modifications go into the network architecture. This property allows dueling networks to be combined with virtually any of the improvements proposed over the years to the original DQN algorithm. For instance, we could have a dueling DQN agent, and a dueling double DQN agent (or the way I’m referring to it—dueling DDQN), and more. Many of these improvements are just plug-and-play, which we take advantage of in this chapter. Let’s now implement a dueling architecture to be used in our experiments and learn about it while building it.

### Reinforcement learning isn’t a supervised learning problem

In the previous chapter, we concentrated our efforts on making reinforcement learning look more like a supervised learning problem. By using a replay buffer, we made online data, which is experienced and collected sequentially by the agent, look more like an independent and identically distributed dataset, such as those commonly found in supervised learning.

We also made targets look more static, which is also a common trait of supervised learning problems. This surely helps stabilize training, but ignoring the fact that reinforcement learning problems are problems of their own isn’t the smartest approach to solving these problems.

One of the subtleties value-based deep reinforcement learning agents have, and that we will exploit in this chapter, is in the way the value functions relate to one another. More specifically, we can use the fact that the state-value function *V*(*s*) and the action-value function *Q*(*s, a*) are related to each other through the action-advantage function *A*(*s, a*).

|   | Refresh My Memory Value functions recap |
| --- | --- |
|  |  |

### Nuances of value-based deep reinforcement learning methods

The action-value function[](/book/grokking-deep-reinforcement-learning/chapter-10/) *Q*(*s, a*) can be defined as the sum of the state-value function *V*(*s*) and the action-advantage function *A*(*s, a*). This means that we can decompose a Q-function[](/book/grokking-deep-reinforcement-learning/chapter-10/) into two components: one that’s shared across all actions, and another that’s unique to each action; or, to say it another way, a component that is dependent on the action and another that isn’t.

Currently, we’re learning the action-value function *Q*(*s, a*) for each action separately, but that’s inefficient. Of course, there’s a bit of generalization happening because networks are internally connected. Therefore, information is shared between the nodes of a network. But, when learning about *Q*(*s, a*1), we’re ignoring the fact that we could use the same information to learn something about *Q*(*s, a*2), *Q*(*s, a*3), and all other actions available in state *s*. The fact is that *V*(*s*) is common to all actions *a*1, *a*2, *a*3, ..., *a**N*.

![Efficient use of experiences](https://drek4537l1klr.cloudfront.net/morales/Figures/10_01.png)

|   | Boil It Down The action-value function *Q*(*s, a*) depends on the state-value function *V*(*s*) |
| --- | --- |
|  | The bottom line is that the values of actions depend on the values of states, and it would be nice to leverage this fact. In the end, taking the worst action in a good state could be better than taking the best action in a bad state. You see how “the values of actions depend on values of states”? The dueling network architecture uses this dependency of the action-value function *Q*(*s, a*) on the state-value function *V*(*s*) such that every update improves the state-value function *V*(*s*) estimate, which is common to all actions. |

### Advantage of using advantages

Now, let me give you an example. In the cart-pole[](/book/grokking-deep-reinforcement-learning/chapter-10/) environment, when the pole is in the upright position, the values of the left and right actions are virtually the same. It doesn’t matter what you do when the pole is precisely upright (for the sake of argument, assume the cart is precisely in the middle of the track and that all velocities are 0). Going either left or right should have the same value in this perfect state.

However, it does matter what action you take when the pole is tilted 10 degrees to the right, for instance. In this state, pushing the cart to the right to counter the tilt, is the best action the agent can take. Conversely, going left, and consequently, pronouncing the tilt is probably a bad idea.

Notice that this is what the action-advantage function *A*(*s, a*) represents: how much better than average is taking this particular action *a* in the current state *s*?

![Relationship between value functions](https://drek4537l1klr.cloudfront.net/morales/Figures/10_02.png)

### A reinforcement-learning-aware architecture

The dueling network architecture[](/book/grokking-deep-reinforcement-learning/chapter-10/) consists of creating two separate estimators, one of the state-value function[](/book/grokking-deep-reinforcement-learning/chapter-10/) *V*(*s*), and the other of the action-advantage function[](/book/grokking-deep-reinforcement-learning/chapter-10/) *A*(*s, a*). Before splitting up the network, though, you want to make sure your network shares internal nodes. For instance, if you’re using images as inputs, you want the convolutions to be shared so that feature-extraction layers are shared. In the cart-pole environment, we share the hidden layers.

After sharing most of the internal nodes and layers, the layer before the output layers splits into two streams: a stream for the state-value function *V*(*s*), and another for the action-advantage function *A*(*s, a*). The V-function output layer always ends in a single node because the value of a state is always a single number. The output layer for the Q-function, however, outputs a vector of the same size as the number of actions. In the cart-pole environment, the output layer of the action-advantage function stream has two nodes, one for the left action, and the other for the right action.

![Dueling network architecture](https://drek4537l1klr.cloudfront.net/morales/Figures/10_03.png)

| 0001 | A Bit Of History Introduction of the dueling network architecture |
| --- | --- |
|  | The Dueling neural network architecture was introduced in 2015 in a paper called “Dueling Network Architectures for Deep Reinforcement Learning” by Ziyu Wang when he was a PhD student at the University of Oxford. This was arguably the first paper to introduce a custom deep neural network architecture designed specifically for value-based deep reinforcement learning methods. Ziyu is now a research scientist at Google DeepMind, where he continues to contribute to the field of deep reinforcement learning. |

### Building a dueling network

Building the dueling network[](/book/grokking-deep-reinforcement-learning/chapter-10/) is straightforward. I noticed that you could split the network anywhere after the input layer, and it would work just fine. I can imagine you could even have two separate networks, but I don’t see the benefits of doing that. In general, my recommendation is to share as many layers as possible and split only in two heads, a layer before the output layer.

|   | I Speak Python Building the dueling network[](/book/grokking-deep-reinforcement-learning/chapter-10/) |
| --- | --- |
|  |  |

### Reconstructing the action-value function

First, let me clarify that the motivation of the dueling architecture is to create a new network that improves on the previous network, but without having to change the underlying control method. We need changes that aren’t disruptive and that are compatible with previous methods. We want to swap the neural network and be done with it.

For this, we need to find a way to aggregate the two outputs from the network and reconstruct the action-value function *Q*(*s, a*), so that any of the previous methods could use the dueling network model. This way, we create the dueling DDQN agent[](/book/grokking-deep-reinforcement-learning/chapter-10/) when using the dueling architecture with the DDQN agent. A dueling network and the DQN agent would make the dueling DQN[](/book/grokking-deep-reinforcement-learning/chapter-10/) agent.

|   | Show Me The Math Dueling architecture aggregating equations |
| --- | --- |
|  |  |

But, how do we join the outputs? Some of you are thinking, add them up, right? I mean, that’s the definition that I provided, after all. Though, several of you may have noticed that there is no way to recover *V*(*s*) and *A*(*s, a*) uniquely given only *Q*(*s, a*). Think about it; if you add +10 to *V*(*s*) and remove it from *A*(*s, a*) you obtain the same *Q*(*s, a*) with two different values for *V*(*s*) and *A*(*s, a*).

The way we address this issue in the dueling architecture is by subtracting the mean of the advantages from the aggregated action-value function *Q*(*s, a*) estimate. Doing this shifts *V*(*s*) and *A*(*s, a*) off by a constant, but also stabilizes the optimization process.

While estimates are off by a constant, they do not change the relative rank of *A*(*s, a*), and therefore *Q*(*s, a*) also has the appropriate rank. All of this, while still using the same control algorithm. Big win.

|   | I Speak Python The forward pass of a dueling network[](/book/grokking-deep-reinforcement-learning/chapter-10/) |
| --- | --- |
|  |  |

### Continuously updating the target network

Currently, our agent is using a target network[](/book/grokking-deep-reinforcement-learning/chapter-10/) that can be outdated for several steps before it gets a big weight update when syncing with the online network. In the cart-pole environment, that’s merely ~15 steps apart, but in more complex environments, that number can rise to tens of thousands.

![Full target network update](https://drek4537l1klr.cloudfront.net/morales/Figures/10_04.png)

There are at least a couple of issues with this approach. On the one hand, we’re freezing the weights for several steps and calculating estimates with progressively increasing stale data. As we reach the end of an update cycle, the likelihood of the estimates being of no benefit to the training progress of the network is higher. On the other hand, every so often, a huge update is made to the network. Making a big update likely changes the whole landscape of the loss function all at once. This update style seems to be both too conservative and too aggressive at the same time, if that’s possible.

We got into this issue because we wanted our network not to move too quickly and therefore create instabilities, and we still want to preserve those desirable traits. But, can you think of other ways we can accomplish something similar but in a smooth manner? How about slowing down the target network, instead of freezing it?

We can do that. The technique is called *Polyak Averaging[](/book/grokking-deep-reinforcement-learning/chapter-10/),* and it consists of mixing in online network weights into the target network on every step. Another way of seeing it is that, every step, we create a new target network composed of a large percentage of the target network weights and a small percentage of the online network weights. We add ~1% of new information every step to the network. Therefore, the network always lags, but by a much smaller gap. Additionally, we can now update the network on each step.

|   | Show Me The Math Polyak averaging |
| --- | --- |
|  |  |

|   | I Speak Python Mixing in target and online network weights |
| --- | --- |
|  |  |

### What does the dueling network bring to the table?

Action-advantages are particularly[](/book/grokking-deep-reinforcement-learning/chapter-10/) useful when you have many similarly valued actions, as you’ve seen for yourself. Technically speaking, the dueling architecture improves policy evaluation, especially in the face of many actions with similar values. Using a dueling network, our agent can more quickly and accurately compare similarly valued actions, which is something useful in the cart-pole environment.

Function approximators, such as a neural network, have errors; that’s expected. In a network with the architecture we were using before, these errors are potentially different for all of the state-actions pairs, as they’re all separate. But, given the fact that the state-value function is the component of the action-value function that’s common to all actions in a state, by using a dueling architecture, we reduce the function error and error variance. This is because now the error in the component with the most significant magnitude in similarly valued actions (the state-value function *V*(*s*)) is now the same for all actions.

If the dueling network is improving policy evaluation in our agent, then a fully trained dueling DDQN agent should have better performance than the DDQN when the left and right actions have almost the same value. I ran an experiment by collecting the states of 100 episodes for both, the DDQN and the dueling DDQN agents. My intuition tells me that if one agent is better than the other at evaluating similarly valued actions, then the better agent should have a smaller range along the track. This is because a better agent should learn the difference between going left and right, even when the pole is exactly upright. Warning! I didn’t do ablation studies, but the results of my hand-wavy experiment suggest that the dueling DDQN agent is indeed able to evaluate in those states better.

![State-space visited by fully trained cart-pole agents](https://drek4537l1klr.cloudfront.net/morales/Figures/10_05.png)

|   | It's In The Details The dueling double deep Q-network (dueling DDQN) algorithm[](/book/grokking-deep-reinforcement-learning/chapter-10/) |
| --- | --- |
|  | Dueling DDQN is almost identical to DDQN, and DQN, with only a few tweaks. My intention is to keep the differences of the algorithms to a minimal while still showing you the many different improvements that can be made. I’m certain that changing only a few hyperparameters by a little bit has big effects in performance of many of these algorithms; therefore, I don’t optimize the agents. That being said, now let me go through the things that are still the same as before: <br>      <br>      Network outputs the action-value function *Q*(*s, a; θ*). <br>      Optimize the action-value function to approximate the optimal action-value function *q**(*s, a*). <br>      Use off-policy TD targets (*r + gamma*max_a’Q*(*s’,a’; θ*)) to evaluate policies. <br>      Use an adjustable Huber loss, but still with the max_gradient_norm variable set to float(‘inf’). Therefore, we’re using MSE. <br>      Use RMSprop as our optimizer with a learning rate of 0.0007. <br>      An exponentially decaying epsilon-greedy strategy (from 1.0 to 0.3 in roughly 20,000 steps) to improve policies. <br>      A greedy action selection strategy for evaluation steps. <br>      A replay buffer with 320 samples min, 50,000 max, and a batch of 64. <br>      We replaced <br>      <br>      The neural network architecture. We now use a state-in-values-out dueling network architecture (nodes: 4, 512,128, 1; 2, 2). <br>      The target network that used to freeze for 15 steps and update fully now uses Polyak averaging: every time step, we mix in 0.1 of the online network and 0.9 of the target network to form the new target network weights. <br>      Dueling DDQN is the same exact algorithm as DDQN, but a different network: <br>      <br>      Collect experience: (*S**t**, A**t**, R**t+1**, S**t+1**, D**t+1*), and insert into the replay buffer. <br>      Pull a batch out of the buffer and calculate the off-policy TD targets: *R + gamma*max_a’Q*(*s’,a’; θ*), using double learning. <br>      Fit the action-value function *Q*(*s,a; θ*), using MSE and RMSprop. <br>      One cool thing to notice is that all of these improvements are like Lego™ blocks for you to get creative. Maybe you want to try dueling DQN, without the double learning; maybe you want the Huber loss to clip gradients; or maybe you like the Polyak averaging to mix 50:50 every 5 time steps. It’s up to you! Hopefully, the way I’ve organized the code will give you the freedom to try things out. |

|   | Tally it Up Dueling DDQN is more data efficient than all previous methods |
| --- | --- |
|  | Dueling DDQN and DDQN have similar performance in the cart-pole environment. Dueling DDQN is slightly more data efficient. The number of samples DDQN needs to pass the environment is higher than that of dueling DDQN. However, dueling DDQN takes slightly longer than DDQN. |

## PER: Prioritizing the replay of meaningful experiences

In this section, we introduce a more intelligent experience replay technique. The goal is to allocate resources for experience tuples that have the most significant potential for learning. *prioritized experience replay* (PER[](/book/grokking-deep-reinforcement-learning/chapter-10/)) is a specialized replay buffer that does just that.

### A smarter way to replay experiences

At the moment, our agent samples experience tuples from the replay buffer uniformly at random. Mathematically speaking, this feels right, and it is. But intuitively, this seems like an inferior way of replaying experiences. Replaying uniformly at random allocates resources to unimportant experiences. It doesn’t feel right that our agent spends time and compute power “learning” things that have nothing to offer to the current state of the agent

But, let’s be careful here: while it’s evident that uniformly at random isn’t good enough, it’s also the case that human intuition might not work well in determining a better learning signal. When I first implemented a prioritized replay buffer, before reading the PER paper, my first thought was, “Well, I want the agent to get the highest cumulative discounted rewards possible; I should have it replay experiences with high reward only.” Yeah, that didn’t work. I then realized agents also need negative experiences, so I thought, “Aha! I should have the agent replay experiences with the highest reward magnitude! Besides, I love using that ‘abs’ function!” But that didn’t work either. Can you think why these experiments didn’t work? It makes sense that if I want the agent to learn to experience rewarding states, I should have it replay those the most so that it learns to get there. Right?

|   | Miguel's Analogy Human intuition and the relentless pursuit of happiness |
| --- | --- |
|  | I love my daughter. I love her so much. In fact, so much that I want her to experience only the good things in life. No, seriously, if you’re a parent, you know what I mean. I noticed she likes chocolate a lot, or as she would say, “a bunch,” so, I started opening up to giving her candies every so often. And then more often than not. But, then she started getting mad at me when I didn’t think she should get a candy. Too much high-reward experiences, you think? You bet! Agents (maybe even humans) need to be reminded often of good and bad experiences alike, but they also need mundane experiences with low-magnitude rewards. In the end, none of these experiences give you the most learning, which is what we’re after. Isn’t that counterintuitive? |

### Then, what’s a good measure of “important” experiences?

What we’re looking for is to learn from experiences with unexpected value, surprising experiences, experiences we thought should be valued this much, and ended up valued that much. That makes more sense; these experiences bring reality to us. We have a view of the world, we anticipate outcomes, and when the difference between expectation and reality is significant, we know we need to learn something from that.

In reinforcement learning, this measure of surprise is given by the TD error[](/book/grokking-deep-reinforcement-learning/chapter-10/)! Well, technically, the *absolute* TD error. The TD error provides us with the difference between the agent’s current estimate and target value. The current estimate indicates the value our agent thinks it's going to get for acting in a specific way. The target value suggests a new estimate for the same state-action pair, which can be seen as a reality check. The absolute difference between these values indicates how far off we are, how unexpected this experience is, and how much new information we received, which makes it a good indicator for learning opportunity.

|   | Show Me The Math The absolute TD error is the priority |
| --- | --- |
|  |  |

The TD error isn’t the perfect indicator of the highest learning opportunity, but maybe the best reasonable proxy for it. In reality, the best criterion for learning the most is inside the network and hidden behind parameter updates. But, it seems impractical to calculate gradients for all experiences in the replay buffer every time step. The good things about the TD error are that the machinery to calculate it is in there already, and of course, the fact that the TD error is still a good signal for prioritizing the replay of experiences.

### Greedy prioritization by TD error

Let’s pretend we use TD[](/book/grokking-deep-reinforcement-learning/chapter-10/)[](/book/grokking-deep-reinforcement-learning/chapter-10/) errors for prioritizing experiences are follows:

- Take action a in state s and receive a new state *s'*, a reward *r*, and a done flag *d*.
- Query the network for the estimate of the current state *Q*(*s, a; θ*).
- Calculate a new target value for that experience as *target = r + gamma*max_a'Q* (*s',a'; θ*).
- Calculate the absolute *TD* error as *atd_err = abs*(*Q*(*s, a; θ*) – *target*).
- Insert experience into the replay buffer as a tuple (*s, a, r, s', d, atd_err*).
- Pull out the top experiences from the buffer when sorted by *atd_err*.
- Train with these experiences, and repeat.

There are multiple issues with this approach, but let’s try to get them one by one. First, we are calculating the TD errors twice: we calculate the TD error before inserting it into the buffer, but then again when we train with the network. In addition to this, we’re ignoring the fact that TD errors change every time the network changes because they’re calculated using the network. But, the solution can’t be updating all of the TD errors every time step. It’s simply not cost effective.

A workaround for both these problems is to update the TD errors only for experiences that are used to update the network (the replayed experiences) and insert new experiences with the highest magnitude TD error in the buffer to ensure they’re all replayed at least once.

However, from this workaround, other issues arise. First, a TD error of zero in the first update means that experience will likely never be replayed again. Second, when using function approximators, errors shrink slowly, and this means that updates concentrate heavily in a small subset of the replay buffer. And finally, TD errors are noisy.

For these reasons, we need a strategy for sampling experiences based on the TD errors, but stochastically, not greedily. If we sample prioritized experiences stochastically, we can simultaneously ensure all experiences have a chance of being replayed, and that the probabilities of sampling experiences are monotonic in the absolute TD error.

|   | Boil It Down TD errors, priorities, and probabilities |
| --- | --- |
|  | The most important takeaway from this page is that TD errors aren’t enough; we’ll use TD errors to calculate priorities, and from priorities we calculate probabilities. |

### Sampling prioritized experiences stochastically

Allow me to dig deeper into why we need stochastic prioritization[](/book/grokking-deep-reinforcement-learning/chapter-10/)[](/book/grokking-deep-reinforcement-learning/chapter-10/)[](/book/grokking-deep-reinforcement-learning/chapter-10/). In highly stochastic environments, learning from experiences sampled greedily based on the TD error may lead us to where the noise takes us.

TD errors depend on the one-step reward and the action-value function of the next state, both of which can be highly stochastic. Highly stochastic environments can have higher variance TD errors. In such environments, we can get ourselves into trouble if we let our agents strictly follow the TD error. We don’t want our agents to get fixated with surprising situations; that’s not the point. An additional source of noise in the TD error is the neural network. Using highly non-linear function approximators also contributes to the noise in TD errors, especially early during training when errors are the highest. If we were to sample greedily solely based on TD errors, much of the training time would be spent on the experiences with potentially inaccurately large magnitude TD error.

|   | Boil It Down Sampling prioritized experiences stochastically |
| --- | --- |
|  | TD errors are noisy and shrink slowly. We don’t want to stop replaying experiences that, due to noise, get a TD error value of zero. We don’t want to get stuck with noisy experiences that, due to noise, get a significant TD error. And, we don’t want to fixate on experiences with an initially high TD error. |

| 0001 | A Bit Of History Introduction of the prioritized experience replay buffer |
| --- | --- |
|  | The paper “Prioritized Experience Replay”was introduced simultaneously with the dueling architecture paper in 2015 by the Google DeepMind folks. Tom Schaul[](/book/grokking-deep-reinforcement-learning/chapter-10/), a Senior Research Scientist at Google DeepMind, is the main author of the PER paper. Tom obtained his PhD in 2011 from the Technical University of Munich. After two years as a postdoc at New York University, Tom joined DeepMind Technologies, which six months later would be acquired by Google and turned into what today is Google DeepMind. Tom is a core developer of the PyBrain framework, a modular machine learning library for Python. PyBrain was probably one of the earlier frameworks to implement machine learning, reinforcement learning and black-box optimization algorithms. He’s also a core developer of PyVGDL, a high-level video game description language built on top of pygame. |

### Proportional prioritization

Let’s calculate priorities[](/book/grokking-deep-reinforcement-learning/chapter-10/)[](/book/grokking-deep-reinforcement-learning/chapter-10/)[](/book/grokking-deep-reinforcement-learning/chapter-10/) for each sample in the buffer based on TD errors. A first approach to do so is to sample experiences in proportion to their absolute TD error. We can use the absolute TD error of each experience and add a small constant, epsilon, to make sure zero TD error samples still have a chance of being replayed.

|   | Show Me The Math Proportional prioritization |
| --- | --- |
|  |  |

We scale this priority value by exponentiating it to alpha, a hyperparameter between zero and one. That allows us to interpolate between uniform and prioritized sampling. It allows us to perform the stochastic prioritization we discussed.

When alpha is zero, all values become one, therefore, an equal priority. When alpha is one, all values stay the same as the absolute TD error; therefore, the priority is proportional to the absolute TD error—a value in between blends the two sampling strategies.

These scaled priorities are converted to actual probabilities only by dividing their values by the sum of the values. Then, we can use these probabilities for drawing samples from the replay buffer.

|   | Show Me The Math Priorities to probabilities |
| --- | --- |
|  |  |

### Rank-based prioritization

One issue with the proportional-prioritization[](/book/grokking-deep-reinforcement-learning/chapter-10/)[](/book/grokking-deep-reinforcement-learning/chapter-10/)[](/book/grokking-deep-reinforcement-learning/chapter-10/) approach is that it’s sensitive to outliers. That means experiences with much higher TD error than the rest, whether by fact or noise, are sampled more often than those with low magnitudes, which may be an undesired side effect.

A slightly different experience prioritization approach to calculating priorities is to sample them using the rank of the samples when sorted by their absolute TD error.

Rank here means the position of the sample when sorted in descending order by the absolute TD error—nothing else. For instance, prioritizing based on the rank makes the experience with the highest absolute TD error rank 1, the second rank 2, and so on.

|   | Show Me The Math Rank-based prioritization |
| --- | --- |
|  |  |

After we rank them by TD error, we calculate their priorities as the reciprocal of the rank. And again, for calculating priorities, we proceed by scaling the priorities with alpha, the same as with the proportional strategy. And then, we calculate actual probabilities from these priorities, also, as before, normalizing the values so that the sum is one.

|   | Boil It Down Rank-based prioritization |
| --- | --- |
|  | While proportional prioritization uses the absolute TD error and a small constant for including zero TD error experiences, rank-based prioritization uses the reciprocal of the rank of the sample when sorted in descending order by absolute TD error. Both prioritization strategies then create probabilities from priorities the same way. |

### Prioritization bias

Using one distribution for estimating[](/book/grokking-deep-reinforcement-learning/chapter-10/)[](/book/grokking-deep-reinforcement-learning/chapter-10/)[](/book/grokking-deep-reinforcement-learning/chapter-10/) another one introduces bias in the estimates. Because we’re sampling based on these probabilities, priorities, and TD errors, we need to account for that.

First, let me explain the problem in more depth. The distribution of the updates must be from the same distribution as its expectation. When we update the action-value function of state *s* and an action *a*, we must be cognizant that we always update with targets.

Targets are samples of expectations. That means the reward and state at the next step could be stochastic; there could be many possible different rewards and states when taking action *a* in a state *s*.

If we were to ignore this fact and update a single sample more often than it appears in that expectation, we’d create a bias toward this value. This issue is particularly impactful at the end of training when our methods are near convergence.

The way to mitigate this bias is to use a technique called *weighted importance sampling*[](/book/grokking-deep-reinforcement-learning/chapter-10/). It consists of scaling the TD errors by weights calculated with the probabilities of each sample.

What weighted importance sampling does is change the magnitude of the updates so that it appears the samples came from a uniform distribution.

|   | Show Me The Math Weighted importance-sampling weights calculation |
| --- | --- |
|  |  |

To do weighted importance-sampling effectively with a prioritized replay buffer, we add a convenient hyperparameter, beta, that allows us to tune the degree of the corrections. When beta is zero, there’s no correction; when beta is one, there’s a full correction of the bias.

Additionally, we want to normalize the weights by their max so that the max weight becomes one, and all other weights scale down the TD errors. This way, we keep TD errors from growing too much and keep training stable.

These importance-sampling weights are used in the loss function. Instead of using the TD errors straight in the gradient updates, in PER, we multiply them by the importance-sampling weights and scale all TD errors down to compensate for the mismatch in the distributions.

|   | Show Me The Math Dueling DDQN with PER gradient update |
| --- | --- |
|  |  |

|   | I Speak Python Prioritized replay buffer 1/2[](/book/grokking-deep-reinforcement-learning/chapter-10/) |
| --- | --- |
|  |  |

|   | I Speak Python Prioritized replay buffer 2/2[](/book/grokking-deep-reinforcement-learning/chapter-10/) |
| --- | --- |
|  |  |

|   | I Speak Python Prioritized replay buffer loss function 1/2 |
| --- | --- |
|  |  |

|   | I Speak Python Prioritized replay buffer loss function 2/2 |
| --- | --- |
|  |  |

|   | It's In The Details The dueling DDQN with the prioritized replay buffer algorithm[](/book/grokking-deep-reinforcement-learning/chapter-10/) |
| --- | --- |
|  | One final time, we improve on all previous value-based deep reinforcement learning methods. This time, we do so by improving on the replay buffer. As you can imagine, most hyperparameters stay the same as the previous methods. Let’s go into the details. These are the things that are still the same as before: <br>      <br>      Network outputs the action-value function *Q*(*s, a; θ*). <br>      We use a state-in-values-out dueling network architecture (nodes: 4, 512,128, 1; 2, 2). <br>      Optimize the action-value function to approximate the optimal action-value function *q**(*s, a*). <br>      Use off-policy TD targets (*r + gamma*max_a’Q*(*s’,a’; θ*)) to evaluate policies. <br>      Use an adjustable Huber loss with max_gradient_norm variable set to float(‘inf’). Therefore, we're using MSE. <br>      Use RMSprop as our optimizer with a learning rate of 0.0007. <br>      An exponentially decaying epsilon-greedy strategy (from 1.0 to 0.3 in roughly 20,000 steps) to improve policies. <br>      A greedy action selection strategy for evaluation steps. <br>      A target network that updates every time step using Polyak averaging with a tau (the mix-in factor) of 0.1. <br>      A replay buffer with 320 samples minimum and a batch of 64. <br>      Things we’ve changed: <br>      <br>      Use weighted important sampling to adjust the TD errors (which changes the loss function). <br>      Use a prioritized replay buffer with proportional prioritization, with a max number of samples of 10,000, an alpha (degree of prioritization versus uniform—1 is full priority) value of 0.6, a beta (initial value of beta, which is bias correction—1 is full correction) value of 0.1 and a beta annealing rate of 0.99992 (fully annealed in roughly 30,000 time steps). <br>      PER is the same base algorithm as dueling DDQN, DDQN, and DQN: <br>      <br>      Collect experience: (*S**t**, A**t**, R**t+**1**, S**t+**1**, D**t+1*), and insert into the replay buffer. <br>      Pull a batch out of the buffer and calculate the off-policy TD targets: *R + gamma*max_a’Q(s’,a’; θ),* using double learning. <br>      Fit the action-value function *Q*(*s,a; θ*), using MSE and RMSprop. <br>      Adjust TD errors in the replay buffer. <br> |

|   | Tally it Up PER improves data efficiency even more |
| --- | --- |
|  | The prioritized replay buffer uses fewer samples than any of the previous methods. And as you can see it in the graphs below, it even makes things look more stable. Maybe? |

## Summary

This chapter concludes a survey of value-based DRL methods. In this chapter, we explored ways to make value-based methods more data efficient. You learned about the dueling architecture, and how it leverages the nuances of value-based RL by separating the *Q*(*s, a*) into its two components: the state-value function *V*(*s*) and the action-advantage function *A*(*s, a*). This separation allows every experience used for updating the network to add information to the estimate of the state-value function *V*(*s*), which is common to all actions. By doing this, we arrive at the correct estimates more quickly, reducing sample complexity.

You also looked into the prioritization of experiences. You learned that TD errors are a good criterion for creating priorities and that from priorities, you can calculate probabilities. You learned that we must compensate for changing the distribution of the expectation we’re estimating. Thus, we use importance sampling, which is a technique for correcting the bias.

In the past three chapters, we dove headfirst into the field of value-based DRL. We started with a simple approach, NFQ. Then, we made this technique more stable with the improvements presented in DQN and DDQN. Then, we made it more sample-efficient with dueling DDQN and PER. Overall, we have a pretty robust algorithm. But, as with everything, value-based methods also have cons. First, they’re sensitive to hyperparameters. This is well known, but you should try it for yourself; change any hyperparameter. You can find more values that don’t work than values that do. Second, value-based methods assume they interact with a Markovian environment, that the states contain all information required by the agent. This assumption dissipates as we move away from bootstrapping and value-based methods in general. Last, the combination of bootstrapping, off-policy learning, and function approximators are known conjointly as “the deadly triad.” While the deadly triad is known to produce divergence, researchers still don’t know exactly how to prevent it.

By no means am I saying that value-based methods are inferior to the methods we survey in future chapters. Those methods have issues of their own, too. The fundamental takeaway is to know that value-based deep reinforcement learning methods are well known to diverge, and that’s their weakness. How to fix it is still a research question, but sound practical advice is to use target networks, replay buffers, double learning, sufficiently small learning rates (but not too small), and maybe a little bit of patience. I’m sorry about that; I don’t make the rules.

By now, you

- Can solve reinforcement learning problems with continuous state spaces
- Know how to stabilize value-based DRL agents
- Know how to make value-based DRL agents more sample efficient

|   | Tweetable Feat Work on your own and share your findings |
| --- | --- |
|  | Here are several ideas on how to take what you’ve learned to the next level. If you’d like, share your results with the rest of the world and make sure to check out what others have done, too. It’s a win-win situation, and hopefully, you'll take advantage of it. <br>      <br>      **#gdrl_ch10_tf01:** The replay buffers used in this and the previous chapter are sufficient for the cart-pole environment and other low-dimensional environments. However, you likely noticed that the prioritized buffer becomes the bottleneck for any more complex environment. Try rewriting all replay buffer code by yourself to speed it up. Do not look up other’s code on this yet; try making the replay buffers faster. In the prioritized buffer, you can see that the bottleneck is the sorting of the samples. Find ways to make this portion faster, too. <br>      **#gdrl_ch10_tf02:** When trying to solve high-dimensional environments, such as Atari games, the replay buffer code in this and the previous chapter becomes prohibitively slow, and totally unpractical. Now what? Research how others solve this problem, which is a blocking issue for prioritized buffers. Share your findings and implement the data structures on your own. Understand them well, and create a blog post explaining the benefits of using them, in detail. <br>      **#gdrl_ch10_tf03:** In the last two chapters, you’ve learned about methods that can solve problems with high-dimensional and continuous state spaces, but how about action spaces? It seems lame that these algorithms can only select one action at a time, and these actions have discrete values. But wait, can DQN-like methods only solve problems with discrete action spaces of size one? Investigate and tell us! <br>      **#gdrl_ch10_tf04:** In every chapter, I’m using the final hashtag as a catchall hashtag. Feel free to use this one to discuss anything else that you worked on relevant to this chapter. There’s no more exciting homework than that which you create for yourself. Make sure to share what you set yourself to investigate and your results. <br>      Write a tweet with your findings, tag me @mimoralea (I’ll retweet), and use the particular hashtag from the list to help interested folks find your results. There are no right or wrong results; you share your findings and check others’ findings. Take advantage of this to socialize, contribute, and get yourself out there! We’re waiting for you! Here’s a tweet example: “Hey, @mimoralea. I created a blog post with a list of resources to study deep reinforcement learning. Check it out at <link>. #gdrl_ch01_tf01” I’ll make sure to retweet and help others find your work. |
