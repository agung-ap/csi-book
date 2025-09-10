# 11 Policy-gradient and actor-critic methods

### In this chapter

- You will learn about a family of deep reinforcement learning methods that can optimize their performance directly, without the need for value functions.
- You will learn how to use value function to make these algorithms even better.
- You will implement deep reinforcement learning algorithms that use multiple processes at once for very fast learning.

*There is no better than adversity. Every defeat, every heartbreak, every loss, contains its own seed, its own lesson on how to improve your performance the next time.*

— Malcolm X
American Muslim minister and human rights activist

In this book, we’ve explored methods that can find optimal and near-optimal policies with the help of value functions. However, all of those algorithms learn value functions when what we need are policies.

In this chapter, we explore the other side of the spectrum and what’s in the middle. We start exploring methods that optimize policies directly. These methods, referred to as *policy-based* or *policy-gradient* methods, parameterize a policy and adjust it to maximize expected returns.

After introducing foundational policy-gradient methods, we explore a combined class of methods that learn both policies and value functions. These methods are referred to as actor-critic because the policy, which selects actions, can be seen as an actor, and the value function, which evaluates policies, can be seen as a critic. Actor-critic methods often perform better than value-based or policy-gradient methods alone on many of the deep reinforcement learning benchmarks. Learning about these methods allows you to tackle more challenging problems.

These methods combine what you learned in the previous three chapters concerning learning value functions and what you learn about in the first part of this chapter, about learning policies. Actor-critic methods often yield state-of-the-art performance in diverse sets of deep reinforcement learning benchmarks.

![Policy-based, value-based, and actor-critic methods](https://drek4537l1klr.cloudfront.net/morales/Figures/11_01.png)

## REINFORCE: Outcome-based policy learning

In this section, we begin motivating the use of policy-based methods, first with an introduction; then we discuss several of the advantages you can expect when using these kinds of methods; and finally, we introduce the simplest policy-gradient algorithm, called *REINFORCE[](/book/grokking-deep-reinforcement-learning/chapter-11/)*.

### Introduction to policy-gradient methods

The first point I’d like to emphasize is that in policy-gradient methods[](/book/grokking-deep-reinforcement-learning/chapter-11/), unlike in value-based methods, we’re trying to maximize a performance objective. In value-based methods, the main focus is to learn to evaluate policies. For this, the objective is to minimize a loss between predicted and target values. More specifically, our goal is to match the true action-value function of a given policy, and therefore, we parameterized a value function and minimized the mean squared error between predicted and target values. Note that we didn’t have true target values, and instead, we used actual returns in Monte Carlo methods or predicted returns in bootstrapping methods.

In policy-based methods, on the other hand, the objective is to maximize the performance of a parameterized policy, so we’re running gradient ascent (or executing regular gradient descent on the negative performance). It’s rather evident that the performance of an agent is the expected total discounted reward from the initial state, which is the same thing as the expected state-value function from all initial states of a given policy.

|   | Show Me The Math Value-based vs. policy-based methods objectives |
| --- | --- |
|  |  |

| ŘŁ | With An RL Accent Value-based vs. policy-based vs. policy-gradient vs. actor-critic methods |
| --- | --- |
|  | **Value-based methods:** Refers to algorithms that learn value functions and only value functions.Q-learning, SARSA, DQN, and company are all value-based methods. **Policy-based methods:** Refers to a broad range of algorithms that optimize policies, including black-box optimization methods, such as genetic algorithms. **Policy-gradient methods:** Refers to methods that solve an optimization problem on the gradient of the performance of a parameterized policy, methods you’ll learn in this chapter. **Actor-critic methods:** Refers to methods that learn both a policy and a value function, primarily if the value function is learned with bootstrapping and used as the score for the stochastic policy gradient. You learn about these methods in this and the next chapter. |

### Advantages of policy-gradient methods

The main advantage[](/book/grokking-deep-reinforcement-learning/chapter-11/) of learning parameterized policies is that policies can now be any learnable function. In value-based methods, we worked with discrete action spaces, mostly because we calculate the maximum value over the actions. In high-dimensional action spaces, this max could be prohibitively expensive. Moreover, in the case of continuous action spaces, value-based methods are severely limited.

Policy-based methods, on the other hand, can more easily learn stochastic policies, which in turn has multiple additional advantages. First, learning stochastic policies means better performance under partially observable environments. The intuition is that because we can learn arbitrary probabilities of actions, the agent is less dependent on the Markov assumption. For example, if the agent can’t distinguish a handful of states from their emitted observations, the best strategy is often to act randomly with specific probabilities.

![Learning stochastic policies could get us out of trouble](https://drek4537l1klr.cloudfront.net/morales/Figures/11_02.png)

Interestingly, even though we’re learning stochastic policies, nothing prevents the learning algorithm from approaching a deterministic policy. This is unlike value-based methods, in which, throughout training, we have to force exploration with some probability to ensure optimality. In policy-based methods with stochastic policies, exploration is embedded in the learned function, and converging to a deterministic policy for a given state while training is possible.

Another advantage of learning stochastic policies is that it could be more straightforward for function approximation to represent a policy than a value function. Sometimes value functions are too much information for what’s truly needed. It could be that calculating the exact value of a state or state-action pair is complicated or unnecessary.

![Learning policies could be an easier, more generalizable problem to solve](https://drek4537l1klr.cloudfront.net/morales/Figures/11_03.png)

A final advantage to mention is that because policies are parameterized with continuous values, the action probabilities change smoothly as a function of the learned parameters. Therefore, policy-based methods often have better convergence properties. As you remember from previous chapters, value-based methods are prone to oscillations and even divergence. One of the reasons for this is that tiny changes in value-function space may imply significant changes in action space. A significant difference in actions can create entirely unusual new trajectories, and therefore create instabilities.

In value-based methods, we use an aggressive operator to change the value function; we take the maximum over Q-value estimates. In policy-based methods, we instead follow the gradient with respect to stochastic policies, which only progressively and smoothly changes the actions. If you directly follow the gradient of the policy, you’re guaranteed convergence to, at least, a local optimum.

|   | I Speak Python Stochastic policy for discrete action spaces 1/2[](/book/grokking-deep-reinforcement-learning/chapter-11/) |
| --- | --- |
|  |  |

|   | I Speak Python Stochastic policy for discrete action spaces 2/2[](/book/grokking-deep-reinforcement-learning/chapter-11/) |
| --- | --- |
|  |  |

### Learning policies directly

One of the main advantages of optimizing policies directly is that, well, it’s the right objective. We learn a policy that optimizes the value function directly, without learning a value function, and without taking into account the dynamics of the environment. How is this possible? Let me show you.

|   | Show Me The Math Deriving the policy gradient |
| --- | --- |
|  |  |

### Reducing the variance of the policy gradient

It’s useful to have[](/book/grokking-deep-reinforcement-learning/chapter-11/) a way to compute the policy gradient without knowing anything about the environment’s transition function. This algorithm increases the log probability of all actions in a trajectory, proportional to the goodness of the full return. In other words, we first collect a full trajectory and calculate the full discounted return, and then use that score to weight the log probabilities of every action taken in that trajectory: *A**t*, *A**t*+1, ..., *A*T–1.

![Let’s use only rewards that are a consequence of actions](https://drek4537l1klr.cloudfront.net/morales/Figures/11_04.png)

|   | Show Me The Math Reducing the variance of the policy gradient |
| --- | --- |
|  |  |

| 0001 | A Bit Of History Introduction of the REINFORCE algorithm |
| --- | --- |
|  | Ronald J. Williams introduced the REINFORCE family of algorithms in 1992 in a paper titled “Simple Statistical Gradient-Following Algorithms for Connectionist Reinforcement Learning.” In 1986, he coauthored a paper with Geoffrey Hinton et al. called “Learning representations by back-propagating errors,” triggering growth in artificial neural network (ANN) research at the time. |

|   | I Speak Python REINFORCE 1/2 |
| --- | --- |
|  |  |

|   | I Speak Python REINFORCE 2/2 |
| --- | --- |
|  |  |

## VPG: Learning a value function

The REINFORCE algorithm you learned about in the previous section works well in simple problems, and it has convergence guarantees. But because we’re using full Monte Carlo returns for calculating the gradient, its variance is a problem. In this section, we discuss a few approaches for dealing with this variance in an algorithm called *vanilla policy gradient* or *REINFORCE with baseline*[](/book/grokking-deep-reinforcement-learning/chapter-11/).

### Further reducing the variance of the policy gradient

REINFORCE is a principled algorithm, but it has a high variance. You probably remember from the discussion in chapter 5 about Monte Carlo targets, but let’s restate. The accumulation of random events along a trajectory, including the initial state sampled from the initial state distribution—transition function probabilities, but now in this chapter with stochastic policies—is the randomness that action selection adds to the mix. All this randomness is compounded inside the return, making it a high-variance signal that's challenging to interpret.

One way for reducing the variance is to use partial returns instead of the full return for changing the log probabilities of actions. We already implemented this improvement. But another issue is that action log probabilities change in the proportion of the return. This means that, if we receive a significant positive return, the probabilities of the actions that led to that return are increased by a large margin. And if the return is of significant negative magnitude, then the probabilities are decreased by of large margin.

However, imagine an environment such as the cart-pole, in which all rewards and returns are positive. In order to accurately separate okay actions from the best actions, we need a lot of data. The variance is, otherwise, hard to muffle. It would be handy if we could, instead of using noisy returns, use something that allows us to differentiate the values of actions in the same state. Recall?

|   | Refresh My Memory Using estimated advantages in policy-gradient methods |
| --- | --- |
|  |  |

### Learning a value function

As you see on the previous page, we can further reduce the variance of the policy gradient by using an estimate of the action-advantage function, instead of the actual return. Using the advantage somewhat centers scores around zero; better-than-average actions have a positive score, worse-than-average, a negative score. The former decreases the probabilities, and the latter increases them.

We’re going to do exactly that. Let’s now create two neural networks, one for learning the policy, the other for learning a state-value function, V. Then, we use the state-value function and the return for calculating an estimate of the advantage function, as we see next.

![Two neural networks, one for the policy, one for the value function](https://drek4537l1klr.cloudfront.net/morales/Figures/11_05.png)

| ŘŁ | With An RL Accent REINFORCE, vanilla policy gradient, baselines, actor-critic |
| --- | --- |
|  | Some of you with prior DRL exposure may be wondering, is this a so-called “actor-critic”? It’s learning a policy and a value-function, so it seems it should be. Unfortunately, this is one of those concepts where the “RL accent” confuses newcomers. Here’s why. First, according to one of the fathers of RL, Rich Sutton[](/book/grokking-deep-reinforcement-learning/chapter-11/), policy-gradient methods approximate the gradient of the performance measure, whether or not they learn an approximate value function. However, David Silver[](/book/grokking-deep-reinforcement-learning/chapter-11/), one of the most prominent figures in DRL, and a former student of Sutton, disagrees. He says that policy-based methods don’t additionally learn a value function, only actor-critic methods[](/book/grokking-deep-reinforcement-learning/chapter-11/) do. But, Sutton further explains that only methods that learn the value function using bootstrapping should be called actor-critic, because it’s bootstrapping[](/book/grokking-deep-reinforcement-learning/chapter-11/) that adds bias to the value function, and thus makes it a “critic.” I like this distinction; therefore, REINFORCE and VPG, as presented in this book, aren’t considered actor-critic methods. But beware of the lingo, it’s not consistent. |

### Encouraging exploration

Another essential improvement to policy-gradient methods is to add an entropy term to the loss function[](/book/grokking-deep-reinforcement-learning/chapter-11/)[](/book/grokking-deep-reinforcement-learning/chapter-11/). We can interpret entropy in many different ways, from the amount of information one can gain by sampling from a distribution to the number of ways one can order a set.

![](https://drek4537l1klr.cloudfront.net/morales/Figures/11_06.png)

The way I like to think of entropy is straightforward. A uniform distribution, which has evenly distributed samples, has high entropy, in fact, the highest it can be. For instance, if you have two samples, and both can be drawn with a 50% chance, then the entropy is the highest it can be for a two-sample set. If you have four samples, each with a 25% chance, the entropy is the same, the highest it can be for a four-sample set. Conversely, if you have two samples, and one has a 100% chance and the other 0%, then the entropy is the lowest it can be, which is always zero. In PyTorch, the natural log is used for calculating the entropy instead of the binary log. This is mostly because the natural log uses Euler’s number, e, and makes math more “natural.” Practically speaking, however, there’s no difference and the effects are the same. The entropy in the cart-pole environment, which has two actions, is between 0 and 0.6931.

The way to use entropy in policy-gradient methods is to add the negative weighted entropy to the loss function to encourage having evenly distributed actions. That way, a policy with evenly distributed actions, which yields the highest entropy, contributes to minimizing the loss. On the other hand, converging to a single action, which means entropy is zero, doesn’t reduce the loss. In that case, the agent had better converge to the optimal action.

|   | Show Me The Math Losses to use for VPG |
| --- | --- |
|  |  |

|   | I Speak Python State-value function neural network model[](/book/grokking-deep-reinforcement-learning/chapter-11/) |
| --- | --- |
|  |  |

|   | I Speak Python Vanilla policy gradient a.k.a. REINFORCE with baseline[](/book/grokking-deep-reinforcement-learning/chapter-11/) |
| --- | --- |
|  |  |

## A3C: Parallel policy updates

VPG is a pretty robust method for simple problems; it is, for the most part, unbiased because it uses an unbiased target for learning both the policy and value function. That is, it uses Monte Carlo returns, which are complete actual returns experienced directly in the environment, without any bootstrapping. The only bias in the entire algorithm is because we use function approximation, which is inherently biased, but since the ANN is only a baseline used to reduce the variance of the actual return, little bias is introduced, if any at all.

However, biased algorithms are necessarily a thing to avoid. Often, to reduce variance, we add bias. An algorithm called *asynchronous advantage actor-critic* (A3C[](/book/grokking-deep-reinforcement-learning/chapter-11/)) does a couple of things to further reduce variance. First, it uses *n*-step returns with bootstrapping to learn the policy and value function, and second, it uses concurrent actors to generate a broad set of experience samples in parallel. Let’s get into the details.

### Using actor-workers

One of the main sources[](/book/grokking-deep-reinforcement-learning/chapter-11/) of variance in DRL algorithms is how correlated and non-stationary online samples are. In value-based methods, we use a replay buffer to uniformly sample mini-batches of, for the most part, independent and identically distributed data. Unfortunately, using this experience-replay scheme for reducing variance is limited to off-policy methods, because on-policy agents cannot reuse data generated by previous policies. In other words, every optimization step requires a fresh batch of on-policy experiences.

Instead of using a replay buffer, what we can do in on-policy methods such as the policy-gradient algorithms we learn about in this chapter, is have multiple workers generating experience in parallel and asynchronously updating the policy and value function. Having multiple workers generating experience on multiple instances of the environment in parallel decorrelates the data used for training and reduces the variance of the algorithm.

![Asynchronous model updates](https://drek4537l1klr.cloudfront.net/morales/Figures/11_07.png)

|   | I Speak Python A3C worker logic 1/2[](/book/grokking-deep-reinforcement-learning/chapter-11/) |
| --- | --- |
|  |  |

|   | I Speak Python A3C worker logic 2/2[](/book/grokking-deep-reinforcement-learning/chapter-11/) |
| --- | --- |
|  |  |

### Using *n*-step estimates

On the previous[](/book/grokking-deep-reinforcement-learning/chapter-11/) page, you notice that I append the value of the next state, whether terminal or not, to the reward sequence. That means that the reward variable contains all rewards from the partial trajectory and the state-value estimate of that last state. We can also see this as having the partial return and the predicted remaining return in the same place. The partial return is the sequence of rewards, and the predicted remaining return is a single-number estimate. The only reason why this isn’t a return is that it isn’t a discounted sum, but we can take care of that as well.

You should realize that this is an *n*-step return, which you learned about in chapter 5. We go out for *n*-steps collecting rewards, and then bootstrap after that *n*th state, or before if we land on a terminal state, whichever comes first.

A3C takes advantage of the lower variance of *n*-step returns when compared to Monte Carlo returns. We use the value function also to predict the return used for updating the policy. You remember that bootstrapping reduces variance, but it adds bias. Therefore, we’ve added a critic to our policy-gradient algorithm. Welcome to the world of actor-critic methods.

|   | Show Me The Math Using *n*-step bootstrapping estimates |
| --- | --- |
|  |  |

|   | I Speak Python A3C optimization step 1/2[](/book/grokking-deep-reinforcement-learning/chapter-11/) |
| --- | --- |
|  |  |

|   | I Speak Python A3C optimization step 2/2[](/book/grokking-deep-reinforcement-learning/chapter-11/) |
| --- | --- |
|  |  |

### Non-blocking model updates

One of the most[](/book/grokking-deep-reinforcement-learning/chapter-11/) critical aspects of A3C is that its network updates are asynchronous and lock-free. Having a shared model creates a tendency for competent software engineers to want a blocking mechanism to prevent workers from overwriting other updates. Interestingly, A3C uses an update style called a Hogwild[](/book/grokking-deep-reinforcement-learning/chapter-11/)!, which is shown to not only achieve a near-optimal rate of convergence but also outperform alternative schemes that use locking by an order of magnitude.

|   | I Speak Python Shared Adam optimizer |
| --- | --- |
|  | [](/book/grokking-deep-reinforcement-learning/chapter-11/) |

| 0001 | A Bit of history Introduction of the asynchronous advantage actor-critic (A3C) |
| --- | --- |
|  | Vlad Mnih et al. introduced A3C in 2016 in a paper titled “Asynchronous Methods for Deep Reinforcement Learning.” If you remember correctly, Vlad also introduced the DQN agent in two papers, one in 2013 and the other in 2015. While DQN ignited growth in DRL research in general, A3C directed lots of attention to actor-critic methods more precisely. |

## GAE: Robust advantage estimation

A3C uses *n*-step returns for reducing the variance of the targets. Still, as you probably remember from chapter 5, there’s a more robust method that combines multiple *n*-step bootstrapping targets in a single target, creating even more robust targets than a single *n*-step: the *λ*-target. *Generalized advantage estimatio***n** (GAE) is analogous to the *λ*-target in TD(λ), but for advantages.

### Generalized advantage estimation

GAE is not an agent on its own, but a way of estimating targets for the advantage function that most actor-critic methods can leverage. More specifically, GAE uses an exponentially weighted combination of *n*-step action-advantage function targets, the same way the *λ*-target is an exponentially weighted combination of *n*-step state-value function targets. This type of target, which we tune in the same way as the *λ*-target, can substantially reduce the variance of policy-gradient estimates at the cost of some bias.

|   | Show Me The Math Possible policy-gradient estimators |
| --- | --- |
|  |  |

|   | Show Me The Math GAE is a robust estimate of the advantage function |
| --- | --- |
|  |  |

|   | Show Me The Math Possible value targets |
| --- | --- |
|  |  |

| 0001 | A Bit Of History Introduction of the generalized advantage estimations |
| --- | --- |
|  | John Schulman et al. published a paper in 2015 titled “High-dimensional Continuous Control Using Generalized Advantage Estimation,” in which he introduces GAE. John is a research scientist at OpenAI, and the lead inventor behind GAE, TRPO, and PPO, algorithms that you learn about in the next chapter. In 2018, John was recognized by Innovators Under 35 for creating these algorithms, which are to this date state of the art. |

|   | I Speak Python GAE’s policy optimization step |
| --- | --- |
|  | [](/book/grokking-deep-reinforcement-learning/chapter-11/) |

## A2C: Synchronous policy updates

In A3C, workers update the neural networks asynchronously. But, asynchronous workers may not be what makes A3C such a high-performance algorithm. Advantage actor-critic (A2C[](/book/grokking-deep-reinforcement-learning/chapter-11/)) is a synchronous version of A3C, which despite the lower numbering order, was proposed after A3C and showed to perform comparably to A3C. In this section, we explore A2C, along with a few other changes we can apply to policy-gradient methods.

### Weight-sharing model

One change to our current algorithm is to use a single neural network for both the policy and the value function. Sharing a model can be particularly beneficial when learning from images because feature extraction can be compute-intensive. However, model sharing can be challenging due to the potentially different scales of the policy and value function updates.

![Sharing weights between policy and value outputs](https://drek4537l1klr.cloudfront.net/morales/Figures/11_08.png)

|   | I Speak Python Weight-sharing actor-critic neural network model 1/2[](/book/grokking-deep-reinforcement-learning/chapter-11/) |
| --- | --- |
|  |  |

|   | I Speak Python Weight-sharing actor-critic neural network model 2/2[](/book/grokking-deep-reinforcement-learning/chapter-11/) |
| --- | --- |
|  |  |

### Restoring order in policy updates

Updating the neural network in a Hogwild!-style[](/book/grokking-deep-reinforcement-learning/chapter-11/) can be chaotic, yet introducing a lock mechanism lowers A3C performance considerably. In A2C, we move the workers from the agent down to the environment. Instead of having multiple actor-learners, we have multiple actors with a single learner. As it turns out, having workers rolling out experiences is where the gains are in policy-gradient methods.

![](https://drek4537l1klr.cloudfront.net/morales/Figures/11_09.png)

|   | I Speak Python Multi-process environment wrapper 1/2 |
| --- | --- |
|  | [](/book/grokking-deep-reinforcement-learning/chapter-11/) |

|   | I Speak Python Multi-process environment wrapper 2/2 |
| --- | --- |
|  | [](/book/grokking-deep-reinforcement-learning/chapter-11/) |

|   | I Speak Python The A2C train logic[](/book/grokking-deep-reinforcement-learning/chapter-11/) |
| --- | --- |
|  |  |

|   | I Speak Python The A2C optimize-model logic[](/book/grokking-deep-reinforcement-learning/chapter-11/) |
| --- | --- |
|  |  |

|   | It's In The Details Running all policy-gradient methods in the CartPole-v1 environment |
| --- | --- |
|  | [](/book/grokking-deep-reinforcement-learning/chapter-11/)[](/book/grokking-deep-reinforcement-learning/chapter-11/) To demonstrate the policy-gradient algorithms, and to make comparison easier with the value-based methods explored in the previous chapters, I ran experiments with the same configurations as in the value-based method experiments. Here are the details: REINFORCE: <br>      <br>      Runs a policy network with 4-128-64-2 nodes, Adam optimizer, and lr 0.0007. <br>      Trained at the end of each episode with Monte Carlo returns. No baseline. <br>      VPG (REINFORCE with Monte Carlo baseline): <br>      <br>      Same policy network as REINFORCE, but now we add an entropy term to the loss function with 0.001 weight, and clip the gradient norm to 1. <br>      We now learn a value function and use it as a baseline, not as a critic. This means MC returns are used without bootstrapping and the value function only reduces the scale of the returns. The value function is learned with a 4-256-128-1 network, RMSprop optimizer, and a 0.001 learning rate. No gradient clippings, though it’s possible. <br>      A3C: <br>      <br>      We train the policy and value networks the same exact way. <br>      We now bootstrap the returns every 50 steps maximum (or when landing on a terminal state). This is an actor-critic method. <br>      We use eight workers each with copies of the networks and doing Hogwild! updates. <br>      GAE: <br>      <br>      Same exact hyperparameter as the rest of the algorithms. <br>      Main difference is GAE adds a tau hyperparameter to discount the advantages. We use 0.95 for tau here. Notice that the agent style has the same *n*-step bootstrapping logic, which might not make this a pure GAE implementation. Usually, you see batches of full episodes being processed at once. It still performs pretty well. <br>      A2C: <br>      <br>      A2C does change most of the hyperparameters. To begin with, we have a single network: 4-256-128-3 (2 and 1). Train with Adam, lr of 0.002, gradient norm of 1. <br>      The policy is weighted at 1.0, value function at 0.6, entropy at 0.001. <br>      We go for 10-step bootstrapping, eight workers, and a 0.95 tau. <br>      These algorithms weren’t tuned independently; I’m sure they could do even better. |

|   | Tally it Up Policy-gradient and actor-critic methods on the CartPole-v1 environment |
| --- | --- |
|  |  |

## Summary

In this chapter, we surveyed policy-gradient and actor-critic methods. First, we set up the chapter with a few reasons to consider policy-gradient and actor-critic methods. You learned that directly learning a policy is the true objective of reinforcement learning methods. You learned that by learning policies, we could use stochastic policies, which can have better performance than value-based methods in partially observable environments. You learned that even though we typically learn stochastic policies, nothing prevents the neural network from learning a deterministic policy.

You also learned about four algorithms. First, we studied REINFORCE and how it’s a straightforward way of improving a policy. In REINFORCE, we could use either the full return or the reward-to-go as the score for improving the policy.

You then learned about vanilla policy gradient, also known as REINFORCE with baseline. In this algorithm, we learn a value function using Monte Carlo returns as targets. Then, we use the value function as a baseline and not as a critic. We don’t bootstrap in VPG; instead, we use the reward-to-go, such as in REINFORCE, and subtract the learned value function to reduce the variance of the gradient. In other words, we use the advantage function as the policy score.

We also studied the A3C algorithm. In A3C, we bootstrap the value function, both for learning the value function and for scoring the policy. More specifically, we use *n*-step returns to improve the models. Additionally, we use multiple actor-learners that each roll out the policy, evaluate the returns, and update the policy and value models using a Hogwild! approach. In other words, workers update lock-free models.

We then learned about GAE, and how this is a way for estimating advantages analogous to TD(*λ*) and the *λ*-return. GAE uses an exponentially weighted mixture of all *n*-step advantages for creating a more robust advantage estimate that can be easily tuned to use more bootstrapping and therefore bias, or actual returns and therefore variance.

Finally, we learned about A2C and how removing the asynchronous part of A3C yields a comparable algorithm without the need for implementing custom optimizers.

By now, you

- Understand the main differences between value-based, policy-based, policy-gradient, and actor-critic methods
- Can implement fundamental policy-gradient and actor-critic methods by yourself
- Can tune policy-gradient and actor-critic algorithms to pass a variety of environments

|   | Tweetable Feat Work on your own and share your findings |
| --- | --- |
|  | Here are several ideas on how to take what you’ve learned to the next level. If you’d like, share your results with the rest of the world and make sure to check out what others have done, too. It’s a win-win situation, and hopefully, you'll take advantage of it. <br>      <br>      **#gdrl_ch11_tf01:** Earlier in this chapter I talked about a fictitious foggy lake environment, but hey, it’s only fictitious because you haven’t implemented it, right? Go ahead and implement a foggy lake and also a foggy frozen lake environment. For this one, make sure the observation passed to the agent is different than the actual internal state of the environment. If the agent is in cell 3, for example, the internal state is kept secret, and the agent is only able to observe that it’s in a foggy cell. In this case, all foggy cells should emit the same observation, so the agent can’t tell where it is. After implementing this environment, test DRL agents that can only learn deterministic policies (such as in previous chapters), and agents that can learn stochastic policies (such as in this chapter). You’ll have to do one-hot encoding of the observations to pass into the neural network. Create a Python package with the environment, and a Notebook with interesting tests and results. <br>      **#gdrl_ch11_tf02:** In this chapter, we’re still using the CartPole-v1 environment as a test bed, but you know swapping environments should be straightforward. First, test the same agents in similar environments, such as the LunarLander-v2, or MountainCar-v0. Note what makes it similar is that the observations are low dimensional and continuous, and the actions are low dimensional and discrete. Second, test them in different environments, high dimensional, or continuous observations or actions. <br>      **#gdrl_ch11_tf03:** In every chapter, I’m using the final hashtag as a catchall hashtag. Feel free to use this one to discuss anything else that you worked on relevant to this chapter. There is no more exciting homework than that which you create for yourself. Make sure to share what you set yourself to investigate and your results. <br>      Write a tweet with your findings, tag me @mimoralea (I’ll retweet), and use the particular hashtag from the list to help interested folks find your results. There are no right or wrong results; you share your findings and check others’ findings. Take advantage of this to socialize, contribute, and get yourself out there! We’re waiting for you! Here’s a tweet example: “Hey, @mimoralea. I created a blog post with a list of resources to study deep reinforcement learning. Check it out at <link>. #gdrl_ch01_tf01” I’ll make sure to retweet and help others find your work. |
