# 8 Introduction to value-based deep reinforcement learning

### In this chapter

- You will understand the inherent challenges of training reinforcement learning agents with non-linear function approximators.
- You will create a deep reinforcement learning agent that, when trained from scratch with minimal adjustments to hyperparameters, can solve different kinds of problems.
- You will identify the advantages and disadvantages of using value-based methods when solving reinforcement learning problems.

*Human behavior flows from three main sources: desire, emotion, and knowledge.*

— Plato
A philosopher in Classical Greece and founder of the Academy in Athens

We’ve made a great deal of progress so far, and you’re ready to truly grok deep reinforcement learning. In chapter 2, you learned to represent problems in a way reinforcement learning agents can solve using Markov decision processes (MDP). In chapter 3, you developed algorithms that solve these MDPs: that is, agents that find optimal behavior in sequential decision-making problems. In chapter 4, you learned about algorithms that solve one-step MDPs without having access to these MDPs. These problems are uncertain because the agents don’t have access to the MDP. Agents learn to find optimal behavior through trial-and-error learning. In chapter 5, we mixed these two types of problems—sequential and uncertain—so we explore agents that learn to evaluate policies. Agents didn’t find optimal policies but were able to evaluate policies and estimate value functions accurately. In chapter 6, we studied agents that find optimal policies on sequential decision-making problems under uncertainty. These agents go from random to optimal by merely interacting with their environment and deliberately gathering experiences for learning. In chapter 7, we learned about agents that are even better at finding optimal policies by getting the most out of their experiences.

Chapter 2 is a foundation for all chapters in this book. Chapter 3 is about planning algorithms that deal with sequential feedback. Chapter 4 is about bandit algorithms that deal with evaluative feedback. Chapters 5, 6, and 7 are about RL algorithms, algorithms that deal with feedback that is simultaneously sequential and evaluative. This type of problem is what people refer to as *tabular reinforcement learning*. Starting from this chapter, we dig into the details of deep reinforcement learning.

More specifically, in this chapter, we begin our incursion into the use of deep neural networks for solving reinforcement learning problems. In deep reinforcement learning, there are different ways of leveraging the power of highly non-linear function approximators, such as deep neural networks. They’re value-based, policy-based, actor-critic, model-based, and gradient-free methods. This chapter goes in-depth on value-based deep reinforcement learning methods.

![Types of algorithmic approaches you learn about in this book](https://drek4537l1klr.cloudfront.net/morales/Figures/08_01.png)

## The kind of feedback deep reinforcement learning agents use

In deep reinforcement learning, we build agents that are capable of learning from feedback that’s simultaneously evaluative, sequential, and sampled. I’ve emphasized this throughout the book because you need to understand what that means.

In the first chapter, I mentioned that deep reinforcement learning is about complex sequential decision-making problems under uncertainty. You probably thought, “What a bunch of words.” But as I promised, all these words mean something. “Sequential decision-making problems” is what you learned about in chapter 3. “Problems under uncertainty” is what you learned about in chapter 4. In chapters 5, 6, and 7, you learned about “sequential decision-making problems under uncertainty.” In this chapter, we add the “complex” part back to that whole sentence. Let’s use this introductory section to review one last time the three types of feedback a deep reinforcement learning agent uses for learning.

|   | Boil It Down Kinds of feedback in deep reinforcement learning |
| --- | --- |
|  |  |

### Deep reinforcement learning agents deal with sequential feedback

Deep reinforcement learning agents have to deal with sequential feedback[](/book/grokking-deep-reinforcement-learning/chapter-8/)[](/book/grokking-deep-reinforcement-learning/chapter-8/). One of the main challenges of sequential feedback is that your agents can receive delayed information.

You can imagine a chess game in which you make a few wrong moves early on, but the consequences of those wrong moves only manifest at the end of the game when and if you materialize a loss.

Delayed feedback makes it tricky to interpret the source of the feedback. Sequential feedback gives rise to the temporal credit assignment problem, which is the challenge of determining which state, action, or state-action pair is responsible for a reward. When there’s a temporal component to a problem and actions have delayed consequences, it becomes challenging to assign credit for rewards.

![Sequential feedback](https://drek4537l1klr.cloudfront.net/morales/Figures/08_02.png)

### But, if it isn’t sequential, what is it?

The opposite of delayed feedback is immediate feedback[](/book/grokking-deep-reinforcement-learning/chapter-8/)[](/book/grokking-deep-reinforcement-learning/chapter-8/). In other words, the opposite of sequential feedback is one-shot feedback. In problems that deal with one-shot feedback, such as supervised learning or multi-armed bandits, decisions don’t have long-term consequences. For example, in a classification problem, classifying an image, whether correctly or not, has no bearing on future performance; for instance, the images presented in the next model are not any different whether the model classified the previous batch correctly or not. In DRL, this sequential dependency exists.

![Classification problem](https://drek4537l1klr.cloudfront.net/morales/Figures/08_03.png)

Moreover, in bandit problems, there’s also no long-term consequence, though it's perhaps a bit harder to see why. Bandits are one-state one-step MDPs in which episodes terminate immediately after a single action selection. Therefore, actions don’t have long-term consequences in the performance of the agent during that episode.

![Two-armed bandit](https://drek4537l1klr.cloudfront.net/morales/Figures/08_04.png)

### Deep reinforcement learning agents deal with evaluative feedback

The second property we learned about is that of evaluative feedback[](/book/grokking-deep-reinforcement-learning/chapter-8/)[](/book/grokking-deep-reinforcement-learning/chapter-8/). Deep reinforcement learning, tabular reinforcement learning, and bandits all deal with evaluative feedback. The crux of evaluative feedback is that the goodness of the feedback is only relative, because the environment is uncertain. We don’t know the actual dynamics of the environment; we don’t have access to the transition function and reward signal.

As a result, we must explore the environment around us to find out what’s out there. The problem is that, by exploring, we miss capitalizing on our current knowledge and, therefore, likely accumulate regret. Out of all this, the exploration-exploitation trade-off arises. It’s a constant by-product of uncertainty. While not having access to the model of the environment, we must explore to gather new information or improve on our current information.

![Evaluative feedback](https://drek4537l1klr.cloudfront.net/morales/Figures/08_05.png)

### But, if it isn’t evaluative, what is it?

The opposite of evaluative feedback is supervised feedback[](/book/grokking-deep-reinforcement-learning/chapter-8/)[](/book/grokking-deep-reinforcement-learning/chapter-8/). In a classification problem, your model receives supervision; that is, during learning, your model is given the correct labels for each of the samples provided. There’s no guessing. If your model makes a mistake, the correct answer is provided immediately afterward. What a good life!

![Classification is “supervised”](https://drek4537l1klr.cloudfront.net/morales/Figures/08_06.png)

The fact that correct answers are given to the learning algorithm makes supervised feedback much easier to deal with than evaluative feedback. That’s a clear distinction between supervised learning problems and evaluative-feedback problems, such as multi-armed bandits, tabular reinforcement learning, and deep reinforcement learning.

Bandit problems may not have to deal with sequential feedback, but they do learn from evaluative feedback. That’s the core issue bandit problems solve. When under evaluative feedback, agents must balance exploration versus exploitation requirements. If the feedback is evaluative and sequential at the same time, the challenge is even more significant. Algorithms must simultaneously balance immediate- and long-term goals and the gathering and utilization of information. Both tabular reinforcement learning and DRL agents learn from feedback that’s simultaneously sequential and evaluative.

![Bandits deal with evaluative feedback](https://drek4537l1klr.cloudfront.net/morales/Figures/08_07.png)

### Deep reinforcement learning agents deal with sampled feedback

What differentiates deep reinforcement[](/book/grokking-deep-reinforcement-learning/chapter-8/)[](/book/grokking-deep-reinforcement-learning/chapter-8/) learning from tabular reinforcement learning is the complexity of the problems. In deep reinforcement learning, agents are unlikely to sample all possible feedback exhaustively. Agents need to generalize using the gathered feedback and come up with intelligent decisions based on that generalization.

Think about it. You can’t expect exhaustive feedback from life. You can’t be a doctor and a lawyer and an engineer all at once, at least not if you want to be good at any of these. You must use the experience you gather early on to make more intelligent decisions for your future. It’s basic. Were you good at math in high school? Great, then, pursue a math-related degree. Were you better at the arts? Then, pursue that path. Generalizing helps you narrow your path going forward by helping you find patterns, make assumptions, and connect the dots that help you reach your optimal self.

By the way, supervised learning deals with sampled feedback. Indeed, the core challenge in supervised learning is to learn from sampled feedback: to be able to generalize to new samples, which is something neither multi-armed bandit nor tabular reinforcement learning problems do.

![Sampled feedback](https://drek4537l1klr.cloudfront.net/morales/Figures/08_08.png)

### But, if it isn’t sampled, what is it?

The opposite of sampled feedback is exhaustive feedback[](/book/grokking-deep-reinforcement-learning/chapter-8/)[](/book/grokking-deep-reinforcement-learning/chapter-8/). To exhaustively sample environments means agents have access to all possible samples. Tabular reinforcement learning and bandits agents, for instance, only need to sample for long enough to gather all necessary information for optimal performance. To gather exhaustive feedback is also why there are optimal convergence guarantees in tabular reinforcement learning. Common assumptions, such as “infinite data” or “sampling every state-action pair infinitely often,” are reasonable assumptions in small grid worlds with finite state and action spaces.

![Sequential, evaluative, and exhaustive feedback](https://drek4537l1klr.cloudfront.net/morales/Figures/08_09.png)

This dimension we haven’t dealt with until now. In this book so far, we surveyed the tabular reinforcement learning problem. Tabular reinforcement learning learns from evaluative, sequential, and exhaustive feedback. But, what happens when we have more complex problems in which we cannot assume our agents will ever exhaustively sample environments? What if the state space is high dimensional, such as a Go board with 10170 states? How about Atari games with (2553)210 × 160 at 60 Hz? What if the environment state space has continuous variables, such as a robotic arm indicating joint angles? How about problems with both high-dimensional and continuous states or even high-dimensional and continuous actions? These complex problems are the reason for the existence of the field of deep reinforcement learning.

## Introduction to function approximation for reinforcement learning

It’s essential to understand why we use function approximation[](/book/grokking-deep-reinforcement-learning/chapter-8/) for reinforcement learning in the first place. It’s common to get lost in words and pick solutions due to the hype. You know, if you hear “deep learning,” you get more excited than if you hear “non-linear function approximation,” yet they’re the same. That’s human nature. It happens to me; it happens to many, I’m sure. But our goal is to remove the cruft and simplify our thinking.

In this section, I provide motivations for the use of function approximation to solve reinforcement learning problems in general. Perhaps a bit more specific to value functions, than RL overall, but the underlying motivation applies to all forms of DRL.

### Reinforcement learning problems can have high-dimensional state and action spaces

The main drawback of tabular reinforcement learning is that the use of a table to represent value functions is no longer practical in complex problems. Environments can have high-dimensional state spaces[](/book/grokking-deep-reinforcement-learning/chapter-8/)[](/book/grokking-deep-reinforcement-learning/chapter-8/), meaning that the number of variables that comprise a single state is vast. For example, Atari games described above are high dimensional because of the 210-by-160 pixels and the three color channels. Regardless of the values that these pixels can take when we talk about dimensionality, we’re referring to the number of variables that make up a single state.

![High-dimensional state spaces](https://drek4537l1klr.cloudfront.net/morales/Figures/08_10.png)

### Reinforcement learning problems can have continuous state and action spaces

Environments[](/book/grokking-deep-reinforcement-learning/chapter-8/) can additionally have continuous variables[](/book/grokking-deep-reinforcement-learning/chapter-8/)[](/book/grokking-deep-reinforcement-learning/chapter-8/), meaning that a variable can take on an infinite number of values. To clarify, state and action spaces can be high dimensional with discrete variables, they can be low dimensional with continuous variables, and so on.

Even if the variables aren’t continuous and, therefore, not infinitely large, they can still take on a large number of values to make it impractical for learning without function approximation. This is the case with Atari, for instance, where each image-pixel can take on 256 values (0–255 integer values.) There you have a finite state-space, yet large enough to require function approximation for any learning to occur.

But, sometimes, even low-dimension state spaces can be infinitely large state spaces. For instance, imagine a problem in which only the x, y, z coordinates of a robot compose the state-space. Sure, a three-variable state-space is a pretty low-dimensional state-space environment, but what if any of the variables is provided in continuous form, that is, that variable can be of infinitesimal precision? Say, it could be a 1.56, or 1.5683, or 1.5683256, and so on. Then, how do you make a table that takes all these values into account? Yes, you could discretize the state space, but let me save you time and get right to it: you need function approximation.

![Continuous state spaces](https://drek4537l1klr.cloudfront.net/morales/Figures/08_11.png)

|   | A Concrete Example The cart-pole environment |
| --- | --- |
|  | The cart-pole environment is a classic in reinforcement learning. The state space is low dimensional but continuous, making it an excellent environment for developing algorithms; training is fast, yet still somewhat challenging, and function approximation can help.  This is the cart-pole environment Its state space is comprised of four variables: <br>      <br>      The cart position on the track (x-axis) with a range from –2.4 to 2.4 <br>      The cart velocity along the track (x-axis) with a range from –inf to inf <br>      The pole angle with a range of ~–40 degrees to ~ 40 degrees <br>      The pole velocity at the tip with a range of –inf to inf <br>      There are two available actions in every state: <br>      <br>      Action 0 applies a –1 force to the cart (push it left) <br>      Action 1 applies a +1 force to the cart (push it right) <br>      You reach a terminal state if <br>      <br>      The pole angle is more than 12 degrees away from the vertical position <br>      The cart center is more than 2.4 units from the center of the track <br>      The episode count reaches 500 time steps (more on this later) <br>      The reward function is <br>      <br>      +1 for every time step <br> |

### There are advantages when using function approximation

I’m sure you get the point that in environments with high-dimensional or continuous state spaces, there are no practical reasons for not using function approximation[](/book/grokking-deep-reinforcement-learning/chapter-8/). In earlier chapters, we discussed planning and reinforcement learning algorithms. All of those methods represent value functions using tables.

|   | Refresh My Memory Algorithms such as value iteration and Q-learning use tables for value functions |
| --- | --- |
|  | Value iteration is a method that takes in an MDP and derives an optimal policy for such MDP by calculating the optimal state-value function, *v**. To do this, value iteration keeps track of the changing state-value function, *v*, over multiple iterations. In value iteration, the state-value function estimates are represented as a vector of values indexed by the states. This vector is stored with a lookup table for querying and updating estimates.  A state-value function The Q-learning algorithm does not need an MDP and doesn’t use a state-value function. Instead, in Q-learning, we estimate the values of the optimal action-value function, *q**. Action-value functions are not vectors, but, instead, are represented by matrices. These matrices are 2D tables indexed by states and actions.  An action-value function |

|   | Boil It Down Function approximation can make our algorithms more efficient |
| --- | --- |
|  | In the cart-pole environment, we want to use generalization because it’s a more efficient use of experiences. With function approximation, agents learn and exploit patterns with less data (and perhaps faster).  A state-value function with and without function approximation |

While the inability of value iteration and Q-learning to solve problems with sampled feedback make them impractical, the lack of generalization makes them inefficient. What I mean by this is that we could find ways to use tables in environments with continuous-variable states, but we’d pay a price for doing so. Discretizing values could indeed make tables possible, for instance. But, even if we could engineer a way to use tables and store value functions, by doing so, we’d miss out on the advantages of generalization.

For example, in the cart-pole environment, function approximation would help our agents learn a relationship in the x distance. Agents would likely learn that being 2.35 units away from the center is a bit more dangerous than being 2.2 away. We know that 2.4 is the x boundary. This additional reason for using generalization isn’t to be understated. Value functions often have underlying relationships that agents can learn and exploit. Function approximators, such as neural networks, can discover these underlying relationships.

|   | Boil It Down Reasons for using function approximation |
| --- | --- |
|  | Our motivation for using function approximation isn’t only to solve problems that aren’t solvable otherwise, but also to solve problems more efficiently. |

## NFQ: The first attempt at value-based deep reinforcement learning

The following algorithm is called *neural fitted Q* (NFQ[](/book/grokking-deep-reinforcement-learning/chapter-8/)) *iteration*, and it’s probably one of the first algorithms to successfully use neural networks as a function approximation to solve reinforcement learning problems.

For the rest of this chapter, I discuss several components that most value-based deep reinforcement learning algorithms have. I want you to see it as an opportunity to decide on different parts that we could’ve used. For instance, when I introduce using a loss function with NFQ, I discuss a few alternatives. My choices aren’t necessarily the choices that were made when the algorithm was originally introduced. Likewise, when I choose an optimization method, whether root mean square propagation (RMSprop) or adaptive moment estimation (Adam), I give a reason why I use what I use, but more importantly, I give you context so you can pick and choose as you see fit.

What I hope you notice is that my goal is not only to teach you this specific algorithm but, more importantly, to show you the different places where you could try different things. Many RL algorithms feel this “plug-and-play” way, so pay attention.

### First decision point: Selecting a value function to approximate

Using neural networks to approximate value functions can be done in many different ways. To begin with, there are many different value functions we could approximate.

|   | Refresh My Memory Value functions |
| --- | --- |
|  | You’ve learned about the following value functions: <br>      <br>      The state-value function *v*(*s*) <br>      The action-value function *q*(*s,a*) <br>      The action-advantage function *a*(*s,a*) <br>      You probably remember that the state-value function *v*(*s*), though useful for many purposes, isn’t sufficient on its own to solve the control problem. Finding *v*(*s*) helps you know how much expected total discounted reward you can obtain from state s and using policy *π* thereafter. But, to determine which action to take with a V-function, you also need the MDP of the environment so that you can do a one-step look-ahead and take into account all possible next states after selecting each action. You likely also remember that the[](/book/grokking-deep-reinforcement-learning/chapter-8/) action-value function *q*(*s,a*) allows us to solve the control problem, so it’s more like what we need to solve the cart-pole environment: in the cart-pole[](/book/grokking-deep-reinforcement-learning/chapter-8/) environment, we want to learn the values of actions for all states in order to balance the pole by controlling the cart. If we had the values of state-action pairs[](/book/grokking-deep-reinforcement-learning/chapter-8/), we could differentiate the actions that would lead us to either gain information, in the case of an exploratory action, or maximize the expected return, in the case of a greedy action. I want you to notice, too, that what we want to estimate the optimal action-value function and not just an action-value function. However, as we learned in the generalized policy iteration pattern, we can do on-policy learning using an epsilon-greedy policy and estimate its values directly, or we can do off-policy learning and always estimate the policy greedy with respect to the current estimates, which then becomes an optimal policy. Last, we also learned about the action-advantage function[](/book/grokking-deep-reinforcement-learning/chapter-8/) *a(s,a),* which can help us differentiate between values of different actions, and it also lets us easily see how much better than average an action is. |

We’ll study how to use the *v(s)* and *a(s)* functions in a few chapters. For now, let’s settle on estimating the action-value function *q*(*s,a*), just like in Q-learning. We refer to the approximate action-value function estimate[](/book/grokking-deep-reinforcement-learning/chapter-8/) as *Q*(*s,a;* *θ*), which means the Q estimates are parameterized by *θ*, the weights of a neural network, a state *s* and an action *a*.

### Second decision point: Selecting a neural network architecture

We settled on learning[](/book/grokking-deep-reinforcement-learning/chapter-8/)[](/book/grokking-deep-reinforcement-learning/chapter-8/) the approximate action-value function *Q(s,a;* *θ*). But although I suggested the function should be parameterized by *θ**, s,* and *a*, that doesn’t have to be the case. The next component we discuss is the neural network architecture.

![State-action-in-value-out architecture](https://drek4537l1klr.cloudfront.net/morales/Figures/08_12.png)

When we implemented the Q-learning agent, you noticed how the matrix holding the action-value function was indexed by state and action pairs. A straightforward neural network architecture is to input the state (the four state variables in the cart-pole environment), and the action to evaluate. The output would then be one node representing the Q-value for that state-action pair.

![State-in-values-out architecture](https://drek4537l1klr.cloudfront.net/morales/Figures/08_13.png)

This architecture would work fine for the cart-pole environment. But, a more efficient architecture consists of only inputting the state (four for the cart-pole environment) to the neural network and outputting the Q-values for all the actions in that state (two for the cart-pole environment). This is clearly advantageous when using exploration strategies such as epsilon-greedy or softmax, because having to do only one pass forward to get the values of all actions for any given state yields a high-performance implementation, more so in environments with a large number of actions.

For our NFQ implementation, we use the *state-in-values-out architecture*[](/book/grokking-deep-reinforcement-learning/chapter-8/): that is, four input nodes and two output nodes for the cart-pole environment.

|   | I Speak Python Fully connected Q-function (state-in-values-out) |
| --- | --- |
|  |  |

### Third decision point: Selecting what to optimize

Let’s pretend for a second[](/book/grokking-deep-reinforcement-learning/chapter-8/) that the cart-pole environment is a supervised learning problem. Say you have a dataset with states as inputs and a value function as labels. Which value function would you wish to have for labels?

|   | Show Me The Math Ideal objective |
| --- | --- |
|  |  |

Of course, the dream labels for learning the optimal action-value function are the corresponding optimal Q-values (notice that a lowercase q refers to the true values; uppercase is commonly used to denote estimates) for the state-action input pair. That is exactly what the optimal action-value function *q**(*s,a*) represents, as you know.

If we had access to the optimal action-value function, we’d use that, but if we had access to sampling the optimal action-value function, we could then minimize the loss between the approximate and optimal action-value functions, and that would be it.

The optimal action-value function is what we’re after.

|   | Refresh My Memory Optimal action-value function |
| --- | --- |
|  |  |

But why is this an impossible dream? Well, the visible part is we don’t have the optimal action-value function *q*(s,a),* but to top that off, we cannot even sample these optimal Q-values because we don’t have the optimal policy either.

Fortunately, we can use the same principles learned in generalized policy iteration in which we alternate between policy-evaluation and policy-improvement processes to find good policies. But just so you know, because we’re using non-linear function approximation, convergence guarantees no longer exist. It’s the Wild West of the “deep” world.

For our NFQ implementation, we do just that. We start with a randomly initialized action-value function (and implicit policy.) Then, we evaluate the policy by sampling actions from it, as we learned in chapter 5. Then, improve it with an exploration strategy such as epsilon-greedy, as we learned in chapter 4. Finally, keep iterating until we reach the desired performance, as we learned in chapters 6 and 7.

|   | Boil It Down We can’t use the ideal objective |
| --- | --- |
|  | We can’t use the ideal objective because we don’t have access to the optimal action-value function, and we don’t even have an optimal policy to sample from. Instead, we must alternate between evaluating a policy (by sampling actions from it), and improving it (using an exploration strategy, such as epsilon-greedy). It’s as you learned in chapter 6, in the generalized policy iteration pattern. |

### Fourth decision point: Selecting the targets for policy evaluation

There are multiple ways[](/book/grokking-deep-reinforcement-learning/chapter-8/)[](/book/grokking-deep-reinforcement-learning/chapter-8/) we can evaluate a policy. More specifically, there are different *targets* we can use for estimating the action-value function of a policy π. The core targets you learned about are the Monte Carlo (MC) target, the temporal-difference (TD) target, the *n*-step target, and lambda target.

![MC, TD, n-step, and lambda targets](https://drek4537l1klr.cloudfront.net/morales/Figures/08_14.png)

We could use any of these targets and get solid results, but this time for our NFQ implementation, we keep it simple and use the TD target for our experiments.

You remember that the TD targets can be either on-policy or off-policy, depending on the way you bootstrap the target. The two main ways for bootstrapping the TD target are to either use the action-value function of the action the agent will take at the landing state, or alternatively, to use the value of the action with the highest estimate at the next state.

Often in the literature, the on-policy version of this target is called the SARSA target, and the off-policy version is called the Q-learning target.

|   | Show Me The Math On-policy and off-policy TD targets |
| --- | --- |
|  |  |

In our NFQ implementation, we use the same off-policy TD target we used in the Q-learning algorithm. At this point, to get an objective function, we need to substitute the optimal action-value function *q*(s,a),* that we had as the ideal objective equation, by the Q-learning target.

|   | Show Me The Math The Q-learning target, an off-policy TD target |
| --- | --- |
|  |  |

|   | I Speak Python Q-learning target |
| --- | --- |
|  |  |

I want to bring to your attention two issues that I, unfortunately, see often in DRL implementations of algorithms that use TD targets.

First, you need to make sure that you only backpropagate through the predicted values. Let me explain. You know that in supervised learning, you have predicted values that come from the learning model, and true values that are commonly constants provided in advance. In RL, often the “true values” depend on predicted values themselves: they come from the model.

For instance, when you form a TD target, you use a reward, which is a constant, and the discounted value of the next state, which comes from the model. Notice, this value is also not a true value, which is going to cause all sorts of problems that we’ll address in the next chapter. But what I also want you to notice now is that the predicted value comes from the neural network. You have to make this predicted value a constant. In PyTorch, you do this only by calling the *detach* method. Please look at the two previous boxes and understand these points. They’re vital for the reliable implementation of DRL algorithms.

The second issue that I want to raise before we move on is the way terminal states are handled when using OpenAI Gym environments. The OpenAI Gym step, which is used to interact with the environment, returns after every step a handy flag indicating whether the agent just landed on a terminal state. This flag helps the agent force the value of terminal states to zero, which, as you remember from chapter 2, is a requirement to keep the value functions from diverging. You know the value of life after death is nil.

![What’s the value of this state?](https://drek4537l1klr.cloudfront.net/morales/Figures/08_15.png)

The tricky part is that some OpenAI Gym environments, such as the cart-pole, have a wrapper code that artificially terminates an episode after some time steps. In CartPole-v0, the time step limit is 200, and in CartPole-v1 it is 500. This wrapper code helps to prevent agents from taking too long to complete an episode, which can be useful, but it can get you in trouble. Think about it: what do you think the value of having the pole straight up in time step 500 would be? I mean, if the pole is straight up, and you get +1 for every step, then the true value of straight-up is infinite. Yet, since at time step 500 your agent times out, and a terminal flag is passed to the agent, you’ll bootstrap on zero if you’re not careful. This is bad. I cannot stress this enough. There is a handful of ways you can handle this issue, and here are the two common ones. Instead of bootstrapping on zero, bootstrap on the value of the next state as predicted by the network, if either you (1) reach the time step limit for the environment or (2) find the key “TimeLimit.truncated” in the info dictionary. Let me show you the second way.

|   | I Speak Python Properly handling terminal states[](/book/grokking-deep-reinforcement-learning/chapter-8/)[](/book/grokking-deep-reinforcement-learning/chapter-8/) |
| --- | --- |
|  |  |

### Fifth decision point: Selecting an exploration strategy

Another thing we need[](/book/grokking-deep-reinforcement-learning/chapter-8/)[](/book/grokking-deep-reinforcement-learning/chapter-8/) to decide is which policy improvement step to use for our generalized policy iteration needs. You know this from chapters 6 and 7, in which we alternate a policy evaluation method, such as MC or TD, and a policy improvement method that accounts for exploration, such as decaying e-greedy.

In chapter 4, we surveyed many different ways to balance the exploration-exploitation trade-off, and almost any of those techniques would work fine. But in an attempt to keep it simple, we’re going to use an epsilon-greedy strategy on our NFQ implementation.

But, I want to highlight the implication of the fact that we’re training an off-policy learning algorithm here. What that means is that there are two policies: a policy that generates behavior, which in this case is an epsilon-greedy policy, and a policy that we’re learning about, which is the greedy (an ultimately optimal) policy.

One interesting fact of off-policy learning algorithms you studied in chapter 6 is that the policy generating behavior can be virtually anything. That is, it can be anything as long as it has broad support, which means it must ensure enough exploration of all state-action pairs. In our NFQ implementation, I use an epsilon-greedy strategy that selects an action randomly 50% of the time during training. However, when evaluating the agent, I use the action greedy with respect to the learned action-value function.

|   | I Speak Python Epsilon-greedy exploration strategy[](/book/grokking-deep-reinforcement-learning/chapter-8/) |
| --- | --- |
|  |  |

### Sixth decision point: Selecting a loss function

A loss[](/book/grokking-deep-reinforcement-learning/chapter-8/)[](/book/grokking-deep-reinforcement-learning/chapter-8/) function is a measure of how well our neural network predictions are. In supervised learning, it’s more straightforward to interpret the loss function: given a batch of predictions and their corresponding true values, the loss function computes a distance score indicating how well the network has done in this batch.

There are many different ways for calculating this distance score, but I continue to keep it simple in this chapter and use one of the most common ones: MSE (mean squared error, or L2 loss). Still, let me restate that one challenge in reinforcement learning, as compared to supervised learning, is that our “true values” use predictions that come from the network.

MSE (or L2 loss) is defined as the average squared difference between the predicted and true values; in our case, the predicted values are the predicted values of the action-value function that come straight from the neural network: all good. But the true values are, yes, the TD targets, which depend on a prediction also coming from the network, the value of the next state.

![Circular dependency of the action-value function](https://drek4537l1klr.cloudfront.net/morales/Figures/08_16.png)

As you may be thinking, this circular dependency is bad. It’s not well behaved because it doesn’t respect several of the assumptions made in supervised learning problems. We’ll cover what these assumptions are later in this chapter, and the problems that arise when we violate them in the next chapter.

### Seventh decision point: Selecting an optimization method

Gradient descent[](/book/grokking-deep-reinforcement-learning/chapter-8/) is a stable optimization method given a couple of assumptions: data must be independent and identically distributed (IID), and targets must be stationary. In reinforcement learning, however, we cannot ensure any of these assumptions hold, so choosing a robust optimization method to minimize the loss function can often make the difference between convergence and divergence.

If you visualize a loss function as a landscape with valleys, peaks, and planes, an optimization method is the hiking strategy for finding areas of interest, usually the lowest or highest point in that landscape.

A classic optimization method in supervised learning is called *batch gradient descent*. The batch gradient descent algorithm takes the entire dataset at once, calculates the gradient of the given dataset, and steps toward this gradient a little bit at a time. Then, it repeats this cycle until convergence. In the landscape analogy, this gradient represents a signal telling us the direction we need to move. Batch gradient descent isn’t the first choice of researchers because it isn’t practical to process massive datasets at once. When you have a considerable dataset with millions of samples, batch gradient descent is too slow to be practical. Moreover, in reinforcement learning, we don’t even have a dataset in advance, so batch gradient descent isn’t a practical method for our purpose either.

![Batch gradient descent](https://drek4537l1klr.cloudfront.net/morales/Figures/08_17.png)

An optimization method capable of handling smaller batches of data is called mini-batch gradient descent. In mini-batch gradient descent, we use only a fraction of the data at a time. We process a mini-batch of samples to find its loss, then backpropagate to compute the gradient of this loss, and then adjust the weights of the network to make the network better at predicting the values of that mini-batch. With mini-batch gradient descent, you can control the size of the mini-batches, which allows the processing of large datasets.

![Mini-batch gradient descent](https://drek4537l1klr.cloudfront.net/morales/Figures/08_18.png)

At one extreme, you can set the size of your mini-batch to the size of your dataset, in which case, you’re back at batch gradient descent. At the other extreme, you can set the mini-batch size to a single sample per step. In this case, you’re using an algorithm called *stochastic gradient* descent.

![Stochastic gradient descent](https://drek4537l1klr.cloudfront.net/morales/Figures/08_19.png)

The larger the batch, the lower the variance the steps of the optimization method have. But use a batch too large, and learning slows down considerably. Both extremes are too slow in practice. For these reasons, it’s common to see mini-batch sizes ranging from 32 to 1024.

![Zig-zag pattern of mini-batch gradient descent](https://drek4537l1klr.cloudfront.net/morales/Figures/08_20.png)

An improved gradient descent algorithm is called *gradient descent with momentum*, or *momentum* for short. This method is a mini-batch gradient descent algorithm that updates the network’s weights in the direction of the moving average of the gradients, instead of the gradient itself.

![Mini-batch gradient descent vs. momentum](https://drek4537l1klr.cloudfront.net/morales/Figures/08_21.png)

An alternative to using momentum is called *root mean square propagation* (RMSprop). Both RMSprop and momentum do the same thing of dampening the oscillations and moving more directly towards the goal, but they do so in different ways.

While momentum takes steps in the direction of the moving average of the gradients, RMSprop takes the safer bet of scaling the gradient in proportion to a moving average of the magnitude of gradients. It reduces oscillations by merely scaling the gradient in proportion to the square root of the moving average of the square of the gradients or, more simply put, in proportion to the average magnitude of recent gradients.

|   | Miguel's Analogy Optimization methods in value-based deep reinforcement learning |
| --- | --- |
|  | To visualize RMSprop, think of the steepness change of the surface of your loss function. If gradients are high, such as when going downhill, and the surface changes to a flat valley, where gradients are small, the moving average magnitude of gradients is higher than the most recent gradient; therefore, the size of the step is reduced, preventing oscillations or overshooting. If gradients are small, such as in a near-flat surface, and they change to a significant gradient, as when going downhill, the average magnitude of gradients is small, and the new gradient large, therefore increasing the step size and speeding up learning. |

A final optimization method I’d like to introduce is called *adaptive moment estimation* (Adam). Adam is a combination of RMSprop and momentum. The Adam method steps in the direction of the velocity of the gradients, as in momentum. But, it scales updates in proportion to the moving average of the magnitude of the gradients, as in RMSprop. These properties make Adam as an optimization method a bit more aggressive than RMSprop, yet not as aggressive as momentum.

In practice, both Adam and RMSprop are sensible choices for value-based deep reinforcement learning methods. I use both extensively in the chapters ahead. However, I do prefer RMSprop for value-based methods, as you’ll soon notice. RMSprop is stable and less sensitive to hyperparameters, and this is particularly important in value-based deep reinforcement learning.

| 0001 | A Bit Of History Introduction of the NFQ algorithm |
| --- | --- |
|  | NFQ was introduced in 2005 by Martin Riedmiller in a paper called “Neural Fitted Q Iteration − First Experiences with a Data Efficient Neural Reinforcement Learning Method.” After 13 years working as a professor at a number of European universities, Martin took a job as a research scientist at Google DeepMind. |

|   | It's In The Details The full neural fitted Q-iteration (NFQ) algorithm |
| --- | --- |
|  | Currently, we’ve made the following selections: <br>      <br>      Approximate the action-value function *Q*(*s,a; θ*). <br>      Use a state-in-values-out architecture (nodes: 4, 512,128, 2). <br>      Optimize the action-value function to approximate the optimal action- value function *q**(*s,a*). <br>      Use off-policy TD targets (*r + γ*max_a’Q*(*s’,a’; θ*)) to evaluate policies. <br>      Use an epsilon-greedy strategy (epsilon set to 0.5) to improve policies. <br>      Use mean squared error (MSE) for our loss function. <br>      Use RMSprop as our optimizer with a learning rate of 0.0005. <br>      NFQ has three main steps: <br>      <br>      Collect E experiences: (*s, a, r, s’, d*) tuples. We use 1024 samples. <br>      Calculate the off-policy TD targets: *r + γ*max_a’Q*(*s’,a’; θ*). <br>      Fit the action-value function *Q*(*s,a; θ*) using MSE and RMSprop. <br>      This algorithm repeats steps 2 and 3 *K* number of times before going back to step 1. That’s what makes it fitted: the nested loop. We’ll use 40 fitting steps *K*.  NFQ |

|   | Tally it Up NFQ passes the cart-pole environment |
| --- | --- |
|  | Although NFQ is far from a state-of-the-art, value-based deep reinforcement learning method, in a somewhat simple environment, such as the cart-pole, NFQ shows a decent performance. |

### Things that could (and do) go wrong

There are two issues[](/book/grokking-deep-reinforcement-learning/chapter-8/) with our algorithm. First, because we’re using a powerful function approximator, we can generalize across state-action pairs, which is excellent, but that also means that the neural network adjusts the values of all similar states at once.

Now, think about this for a second: our target values depend on the values for the next state, which we can safely assume are similar to the states we are adjusting the values of in the first place. In other words, we’re creating a non-stationary target for our learning updates. As we update the weights of the approximate Q-function, the targets also move and make our most recent update outdated. Thus, training becomes unstable quickly.

![Non-stationary target](https://drek4537l1klr.cloudfront.net/morales/Figures/08_22.png)

Second, in NFQ, we batched 1024 experience samples collected online and update the network from that mini-batch. As you can imagine, these samples are correlated, given that most of these samples come from the same trajectory and policy. That means the network learns from mini-batches of samples that are similar, and later uses different mini-batches that are also internally correlated, but likely different from previous mini-batches, mainly if a different, older policy collected the samples.

All this means that we aren’t holding the IID assumption, and this is a problem because optimization methods assume the data samples they use for training are independent and identically distributed. But we’re training on almost the exact opposite: samples on our distribution are not independent because the outcome of a new state *s* is dependent on our current state *s*.

And, also, our samples aren’t identically distributed because the underlying data generating process, which is our policy, is changing over time. That means we don’t have a fixed data distribution. Instead, our policy, which is responsible for generating the data, is changing and hopefully improving periodically. Every time our policy changes, we receive new and likely different experiences. Optimization methods allow us to relax the IID assumption to a certain degree, but reinforcement learning problems go all the way, so we need to do something about this, too.

![Data correlated with time](https://drek4537l1klr.cloudfront.net/morales/Figures/08_23.png)

In the next chapter, we look at ways of mitigating these two issues. We start by improving NFQ with the algorithm that arguably started the deep reinforcement learning revolution, DQN. We then follow by exploring many of the several improvements proposed to the original DQN algorithm over the years. We also look at double DQN in the next chapter, and then in chapter 10, we look at dueling DQN and PER.

## Summary

In this chapter, we gave a high-level overview of how sampled feedback interacts with sequential and evaluative feedback. We did so while introducing a simple deep reinforcement learning agent that approximates the Q-function, that in previous chapters, we would represent in tabular form, with a lookup table. This chapter was an introduction to value-based deep reinforcement learning methods.

You learned the difference between high-dimensional and continuous state and action spaces. The former indicates a large number of values that make up a single state; the latter hints at at least one variable that can take on an infinite number of values. You learned that decision-making problems could be both high-dimensional and continuous variables, and that makes the use of non-linear function approximation intriguing.

You learned that function approximation isn’t only beneficial for estimating expectations of values for which we only have a few samples, but also for learning the underlying relationships in the state and action dimensions. By having a good model, we can estimate values for which we never received samples and use all experiences across the board.

You had an in-depth overview of different components commonly used when building deep reinforcement learning agents. You learned you could approximate different kinds of value functions, from the state-value function *v(s)* to the action-value *q(s, a)*. And, you can approximate these value functions using different neural network architectures; we explored the state-action pair in, value out, to the more efficient state-in, values out. You learned about using the same objective we used for Q-learning, using the TD target for off-policy control. And, you know there are many different targets you can use to train your network. You surveyed exploration strategies, loss functions, and optimization methods. You learned that deep reinforcement learning agents are susceptible to the loss and optimization methods we select. You learned about RMSprop and Adam as the stable options for optimization methods.

You learned to combine all of these components into an algorithm called neural fitted Q-iteration. You learned about the issues commonly occurring in value-based deep reinforcement learning methods. You learned about the IID assumption and the stationarity of the targets. You learned that not being careful with these two issues can get us into trouble.

By now, you

- Understand what it is to learn from feedback that is sequential, evaluative, and sampled
- Can solve reinforcement learning problems with continuous state-spaces
- Know about the components and issues in value-based DRL methods

|   | Tweetable Feat Work on your own and share your findings |
| --- | --- |
|  | Here are several ideas on how to take what you’ve learned to the next level. If you’d like, share your results with the rest of the world and make sure to check out what others have done, too. It’s a win-win situation, and hopefully, you'll take advantage of it. <br>      <br>      **#gdrl_ch08_tf01:** After tabular reinforcement learning, and before deep reinforcement learning, there are a couple things to explore. With this hashtag, explore and share results for state discretization and tile coding techniques. What are those? Are there any other techniques that we should know about? <br>      **#gdrl_ch08_tf02:** The other thing I’d like you to explore is the use of linear function approximation, instead of deep neural networks. Can you tell us how other function approximation techniques compare? What techniques show promising results? <br>      **#gdrl_ch08_tf03:** In this chapter, I introduced gradient descent as the type of optimization method we use for the remainder of the book. However, gradient descent is not the only way to optimize a neural network; did you know? Either way, you should go out there and investigate other ways to optimize a neural network, from black-box optimization methods, such as genetic algorithms, to other methods that aren’t as popular. Share your findings, create a Notebook with examples, and share your results. <br>      **#gdrl_ch08_tf04:** I started this chapter with a better way for doing Q-learning with function approximation. Equally important to knowing a better way is to have an implementation of the simplest way that didn’t work. Implement the minimal changes to make Q-learning work with a neural network: that is, Q-learning with online experiences as you learned in chapter 6. Test and share your results. <br>      **#gdrl_ch08_tf05:** In every chapter, I’m using the final hashtag as a catchall hashtag. Feel free to use this one to discuss anything else that you worked on relevant to this chapter. There’s no more exciting homework than that which you create for yourself. Make sure to share what you set yourself to investigate and your results. <br>      Write a tweet with your findings, tag me @mimoralea (I’ll retweet), and use the particular hashtag from the list to help interested folks find your results. There are no right or wrong results; you share your findings and check others’ findings. Take advantage of this to socialize, contribute, and get yourself out there! We’re waiting for you! Here’s a tweet example: “Hey, @mimoralea. I created a blog post with a list of resources to study deep reinforcement learning. Check it out at <link>. #gdrl_ch01_tf01” I’ll make sure to retweet and help others find your work. |
