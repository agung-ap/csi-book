# 4 Balancing the gathering and use of information

### In this chapter

- You will learn about the challenges of learning from evaluative feedback and how to properly balance the gathering and utilization of information.
- You will develop exploration strategies that accumulate low levels of regret in problems with unknown transition function and reward signals.
- You will write code with trial-and-error learning agents that learn to optimize their behavior through their own experiences in many-options, one-choice environments known as multi-armed bandits.

*Uncertainty and expectation are the joys of life. Security is an insipid thing.*

— William Congreve
English playwright and poet of the Restoration period and political figure in the British Whig Party

No matter how small and unimportant a decision may seem, every decision you make is a trade-off between information gathering and information exploitation. For example, when you go to your favorite restaurant, should you order your favorite dish, yet again, or should you request that dish you’ve been meaning to try? If a Silicon Valley startup offers you a job, should you make a career move, or should you stay put in your current role?

These kinds of questions illustrate the exploration-exploitation dilemma and are at the core of the reinforcement learning problem. It boils down to deciding when to acquire knowledge and when to capitalize on knowledge previously learned. It’s a challenge to know whether the good we already have is good enough. When do we settle? When do we go for more? What are your thoughts: is a bird in the hand worth two in the bush or not?

The main issue is that rewarding moments in life are relative; you have to compare events to see a clear picture of their value. For example, I’ll bet you felt amazed when you were offered your first job. You perhaps even thought that was the best thing that ever happened to you. But, then life continues, and you experience things that appear even more rewarding—maybe, when you get a promotion, a raise, or get married, who knows!

And that’s the core issue: even if you rank moments you have experienced so far by “how amazing” they felt, you can’t know what’s the most amazing moment you could experience in your life—life is uncertain; you don’t have life’s transition function and reward signal, so you must keep on exploring. In this chapter, you learn about how important it is for your agent to explore when interacting with uncertain environments, problems in which the MDP isn’t available for planning.

In the previous chapter, you learned about the challenges of learning from sequential feedback and how to properly balance immediate and long-term goals. In this chapter, we examine the challenges of learning from evaluative feedback, and we do so in environments that aren’t sequential, but one-shot instead: *multi-armed bandits* (MABs).

MABs isolate and expose the challenges of learning from evaluative feedback. We’ll dive into many different techniques for balancing exploration and exploitation in these particular type of environments: single-state environments with multiple options, but a single choice. Agents will operate under uncertainty, that is, they won’t have access to the MDP. However, they will interact with one-shot environments without the sequential component.

Remember, in DRL, agents learn from feedback that’s simultaneously sequential (as opposed to one shot), evaluative (as opposed to supervised), and sampled (as opposed to exhaustive). In this chapter, I eliminate the complexity that comes along with learning from sequential and sampled feedback, and we study the intricacies of evaluative feedback in isolation. Let’s get to it.

## The challenge of interpreting evaluative feedback

In the last[](/book/grokking-deep-reinforcement-learning/chapter-4/) chapter, when we solved the FL environment, we knew beforehand how the environment would react to any of our actions. Knowing the exact transition function and reward signal of an environment allows us to compute an optimal policy using planning algorithms, such as PI and VI, without having to interact with the environment at all.

But, knowing an MDP in advance oversimplifies things, perhaps unrealistically. We cannot always assume we’ll know with precision how an environment will react to our actions—that’s not how the world works. We could opt for learning such things, as you’ll learn in later chapters, but the bottom line is that we need to let our agents interact and experience the environment by themselves, learning this way to behave optimally, solely from their own experience. This is what’s called trial-and-error learning[](/book/grokking-deep-reinforcement-learning/chapter-4/).

In RL, when the agent learns to behave from interaction with the environment, the environment asks the agent the same question over and over: what do you want to do now? This question presents a fundamental challenge to a decision-making agent. What action should it do now? Should the agent exploit its current knowledge and select the action with the highest current estimate? Or should it explore actions that it hasn’t tried enough? But many additional questions follow: when do you know your estimates are good enough? How do you know you have tried an apparently bad action enough? And so on.

![You will learn more effective ways for dealing with the exploration-exploitation trade-off](https://drek4537l1klr.cloudfront.net/morales/Figures/04_01.png)

This is the key intuition: exploration builds the knowledge that allows for effective exploitation, and maximum exploitation is the ultimate goal of any decision maker.

### Bandits: Single-state decision problems

*Multi-armed bandits* (MAB[](/book/grokking-deep-reinforcement-learning/chapter-4/)[](/book/grokking-deep-reinforcement-learning/chapter-4/)) are a special case of an RL problem in which the size of the state space and horizon equal one. A MAB has multiple actions, a single state, and a greedy horizon; you can also think of it as a “many-options, single-choice” environment. The name comes from slot machines (bandits) with multiple arms to choose from (more realistically, multiple slot machines to choose from).

![Multi-armed bandit problem](https://drek4537l1klr.cloudfront.net/morales/Figures/04_02.png)

There are many commercial applications for the methods coming out of MAB research. Advertising companies need to find the right way to balance showing you an ad they predict you’re likely to click on and showing you a new ad with the potential of it being an even better fit for you. Websites that raise money, such as charities or political campaigns, need to balance between showing the layout that has led to the most contributions and new designs that haven’t been sufficiently utilized but still have potential for even better outcomes. Likewise, e-commerce websites need to balance recommending you best-seller products as well as promising new products. In medical trials, there’s a need to learn the effects of medicines in patients as quickly as possible. Many other problems benefit from the study of the exploration-exploitation trade-off: oil drilling, game playing, and search engines, to name a few. Our reason for studying MABs isn’t so much a direct application to the real world, but instead how to integrate a suitable method for balancing exploration and exploitation in RL agents.

|   | Show Me The Math Multi-armed bandit |
| --- | --- |
|  |  |

### Regret: The cost of exploration

The goal of MABs[](/book/grokking-deep-reinforcement-learning/chapter-4/)[](/book/grokking-deep-reinforcement-learning/chapter-4/)[](/book/grokking-deep-reinforcement-learning/chapter-4/) is very similar to that of RL. In RL, the agent needs to maximize the expected cumulative discounted reward (maximize the expected return). This means to get as much reward (maximize) through the course of an episode (cumulative) as soon as possible (if discounted—later rewards are discounted more) despite the environment’s stochasticity (expected). This makes sense when the environment has multiple states and the agent interacts with it for multiple time steps per episode. But in MABs, while there are multiple episodes, we only have a single chance of selecting an action in each episode.

Therefore, we can exclude the words that don’t apply to the MAB case from the RL goal: we remove “cumulative” because there’s only a single time step per episode, and “discounted” because there are no next states to account for. This means, in MABs, the goal is for the agent to maximize the expected reward. Notice that the word “expected” stays there because there’s stochasticity in the environment. In fact, that’s what MAB agents need to learn: the underlying probability distribution of the reward signal.

However, if we leave the goal to “maximize the expected reward,” it wouldn’t be straightforward to compare agents. For instance, let’s say an agent learns to maximize the expected reward by selecting random actions in all but the final episode, while a much more sample-efficient agent uses a clever strategy to determine the optimal action quickly. If we only compare the final-episode performance of these agents, which isn’t uncommon to see in RL, these two agents would have equally good performance, which is obviously not what we want.

A robust way to capture a more complete goal is for the agent to maximize the per-episode expected reward while still minimizing the total expected reward loss of rewards across all episodes. To calculate this value, called *total regret*[](/book/grokking-deep-reinforcement-learning/chapter-4/), we sum the per-episode difference of the true expected reward of the optimal action and the true expected reward of the selected action. Obviously, the lower the total regret, the better. Notice I use the word true here; to calculate the regret, you must have access to the MDP. That doesn’t mean your agent needs the MDP, only that you need it to compare agents’ exploration strategy efficiency.

|   | Show Me The Math Total regret equation |
| --- | --- |
|  |  |

### Approaches to solving MAB environments

There are three[](/book/grokking-deep-reinforcement-learning/chapter-4/)[](/book/grokking-deep-reinforcement-learning/chapter-4/) major kinds of approaches to tackling MABs. The most popular and straightforward approach involves exploring by injecting randomness in our action-selection process; that is, our agent will exploit most of the time, and sometimes it’ll explore using randomness. This family of approaches is called *random exploration strategies[](/book/grokking-deep-reinforcement-learning/chapter-4/)*. A basic example of this family would be a strategy that selects the greedy action most of the time, and with an epsilon threshold, it chooses uniformly at random. Now, multiple questions arise from this strategy; for instance, should we keep this epsilon value constant throughout the episodes? Should we maximize exploration early on? Should we periodically increase the epsilon value to ensure the agent always explores?

Another approach to dealing with the exploration-exploitation dilemma is to be optimistic. Yep, your mom was right. The family of *optimistic exploration strategies*[](/book/grokking-deep-reinforcement-learning/chapter-4/) is a more systematic approach that quantifies the uncertainty in the decision-making problem and increases the preference for states with the highest uncertainty. The bottom line is that being optimistic will naturally drive you toward uncertain states because you’ll assume that states you haven’t experienced yet are the best they can be. This assumption will help you explore, and as you explore and come face to face with reality, your estimates will get lower and lower as they approach their true values.

The third approach to dealing with the exploration-exploitation dilemma is the family of *information state-space exploration strategies*[](/book/grokking-deep-reinforcement-learning/chapter-4/). These strategies will model the information state of the agent as part of the environment. Encoding the uncertainty as part of the state space means that an environment state will be seen differently when unexplored or explored. Encoding the uncertainty as part of the environment is a sound approach but can also considerably increase the size of the state space and, therefore, its complexity.

In this chapter, we’ll explore a few instances of the first two approaches. We’ll do this in a handful of different MAB environments with different properties, pros and cons, and this will allow us to compare the strategies in depth.

It’s important to notice that the estimation of the Q-function in MAB environments[](/book/grokking-deep-reinforcement-learning/chapter-4/)[](/book/grokking-deep-reinforcement-learning/chapter-4/) is pretty straightforward and something all strategies will have in common. Because MABs are one-step environments, to estimate the Q-function we need to calculate the per-action average reward. In other words, the estimate of an action *a* is equal to the total reward obtained when selecting action *a*, divided by the number of times action *a* has been selected.

It’s essential to highlight that there are no differences in how the strategies we evaluate in this chapter estimate the Q-function; the only difference is in how each strategy uses the Q-function estimates to select actions.

|   | A Concrete Example The slippery bandit walk (SBW) environment is back! |
| --- | --- |
|  | The first MAB environment that we’ll consider is one we have played with before: the bandit slippery walk (BSW).  The bandit slippery walk environment Remember, BSW is a grid world with a single row, thus, a walk. But a special feature of this walk is that the agent starts at the middle, and any action sends the agent to a terminal state immediately. Because it is a one-time-step, it’s a bandit environment. BSW is a two-armed bandit, and it can appear to the agent as a two-armed Bernoulli bandit. Bernoulli bandits pay a reward of +1 with a probability *p* and a reward of 0 with probability *q = 1 – p*. In other words, the reward signal is a Bernoulli distribution. In the BSW, the two terminal states pay either 0 or +1. If you do the math, you’ll notice that the probability of a +1 reward when selecting action 0 is 0.2, and when selecting action 1 is 0.8. But your agent doesn’t know this, and we won’t share that info. The question we’re trying to ask is this: how quickly can your agent figure out the optimal action? How much total regret will agents accumulate while learning to maximize expected rewards? Let’s find out.  Bandit slippery walk graph |

### Greedy: Always exploit

The first strategy I want you to consider isn’t really a strategy but a baseline, instead. I already mentioned we need to have some exploration in our algorithms; otherwise, we risk convergence to a suboptimal action. But, for the sake of comparison, let’s consider an algorithm with no exploration at all.

This baseline is called a *greedy strategy*[](/book/grokking-deep-reinforcement-learning/chapter-4/)[](/book/grokking-deep-reinforcement-learning/chapter-4/), or *pure exploitation strategy*. The greedy action-selection approach consists of always selecting the action with the highest estimated value. While there’s a chance for the first action we choose to be the best overall action, the likelihood of this lucky coincidence decreases as the number of available actions increases.

![Pure exploitation in the BSW](https://drek4537l1klr.cloudfront.net/morales/Figures/04_05.png)

As you might have expected, the greedy strategy gets stuck with the first action immediately. If the Q-table is initialized to zero, and there are no negative rewards in the environment, the greedy strategy will always get stuck with the first action.

|   | I Speak Python Pure exploitation strategy |
| --- | --- |
|  |  |

I want you to notice the relationship between a greedy strategy and time. If your agent only has one episode left, the best thing is to act greedily. If you know you only have one day to live, you’ll do things you enjoy the most. To some extent, this is what a greedy strategy does: it does the best it can do with your current view of life assuming limited time left.

And this is a reasonable thing to do when you have limited time left; however, if you don’t, then you appear to be shortsighted because you can’t trade-off immediate satisfaction or reward for gaining of information that would allow you better long-term results.

### Random: Always explore

Let’s also consider the opposite side of the spectrum: a strategy with exploration but no exploitation at all. This is another fundamental baseline that we can call a *random strategy*[](/book/grokking-deep-reinforcement-learning/chapter-4/)[](/book/grokking-deep-reinforcement-learning/chapter-4/) or a *pure exploration strategy*. This is simply an approach to action selection with no exploitation at all. The sole goal of the agent is to gain information.

Do you know people who, when starting a new project, spend a lot of time “researching” without jumping into the water? Me too! They can take weeks just reading papers. Remember, while exploration is essential, it must be balanced well to get maximum gains.

![Pure exploration in the BSW](https://drek4537l1klr.cloudfront.net/morales/Figures/Pure-exploration-BSW.png)

A random strategy is obviously not a good strategy either and will also give you suboptimal results. Similar to exploiting all the time, you don’t want to explore all the time, either. We need algorithms that can do both exploration and exploitation: gaining and using information.

|   | I Speak Python Pure exploration strategy |
| --- | --- |
|  |  |

I left a note in the code snippet, and I want to restate and expand on it. The pure exploration strategy I presented is one way to explore, that is, random exploration. But you can think of many other ways. Perhaps based on counts, that is, how many times you try one action versus the others, or maybe based on the variance of the reward obtained.

Let that sink in for a second: while there’s only a single way to exploit, there are multiple ways to explore. Exploiting is nothing but doing what you think is best; it’s pretty straightforward. You think A is best, and you do A. Exploring, on the other hand, is much more complex. It’s obvious you need to collect information, but how is a different question. You could try gathering information to support your current beliefs. You could gather information to attempt proving yourself wrong. You could explore based on confidence, or based on uncertainty. The list goes on.

The bottom line is intuitive: exploitation is your goal, and exploration gives you information about obtaining your goal. You must gather information to reach your goals, that is clear. But, in addition to that, there are several ways to collect information, and that’s where the challenge lies.

### Epsilon-greedy: Almost always greedy and sometimes random

Let’s now combine the two baselines, pure exploitation and pure exploration, so that the agent can exploit, but also collect information to make informed decisions. The hybrid strategy consists of acting greedily most of the time and exploring randomly every so often.

This strategy, referred to as the *epsilon-greedy strategy*[](/book/grokking-deep-reinforcement-learning/chapter-4/)[](/book/grokking-deep-reinforcement-learning/chapter-4/), works surprisingly well. If you select the action you think is best almost all the time, you’ll get solid results because you’re still selecting the action believed to be best, but you’re also selecting actions you haven’t tried sufficiently yet. This way, your action-value function has an opportunity to converge to its true value; this will, in turn, help you obtain more rewards in the long term.

![Epsilon-greedy in the BSW](https://drek4537l1klr.cloudfront.net/morales/Figures/04_07.png)

|   | I Speak Python Epsilon-greedy strategy |
| --- | --- |
|  |  |

The epsilon-greedy strategy is a random exploration strategy because we use randomness to select the action. First, we use randomness to choose whether to exploit or explore, but also we use randomness to select an exploratory action. There are other random-exploration strategies, such as softmax (discussed later in this chapter), that don’t have that first random decision point.

I want you to notice that if epsilon is 0.5 and you have two actions, you can’t say your agent will explore 50% of the time, if by “explore” you mean selecting the non-greedy action. Notice that the “exploration step” in epsilon-greedy includes the greedy action. In reality, your agent will explore a bit less than the epsilon value depending on the number of actions.

### Decaying epsilon-greedy: First maximize exploration, then exploitation

Intuitively, early on when the agent hasn’t experienced the environment enough is when we’d like it to explore the most; while later, as it obtains better estimates of the value functions, we want the agent to exploit more and more. The mechanics are straightforward: start with a high epsilon less than or equal to one, and decay its value on every step. This strategy, called *decaying epsilon-greedy strategy*[](/book/grokking-deep-reinforcement-learning/chapter-4/)[](/book/grokking-deep-reinforcement-learning/chapter-4/), can take many forms depending on how you change the value of epsilon. Here I’m showing you two ways.

|   | I Speak Python Linearly decaying epsilon-greedy strategy |
| --- | --- |
|  |  |

|   | I Speak Python Exponentially decaying epsilon-greedy strategy |
| --- | --- |
|  |  |

There are many other ways you can handle the decaying of epsilon: from a simple 1/episode to dampened sine waves. There are even different implementations of the same linear and exponential techniques presented. The bottom line is that the agent should explore with a higher chance early and exploit with a higher chance later. Early on, there’s a high likelihood that value estimates are wrong. Still, as time passes and you acquire knowledge, the likelihood that your value estimates are close to the actual values increases, which is when you should explore less frequently so that you can exploit the knowledge acquired.

### Optimistic initialization: Start off believing it’s a wonderful world

Another interesting approach to dealing with the exploration-exploitation dilemma is to treat actions that you haven’t sufficiently explored as if they were the best possible actions—like you’re indeed in paradise. This class of strategies is known as *optimism in the face of uncertainty*. The optimistic initialization strategy[](/book/grokking-deep-reinforcement-learning/chapter-4/)[](/book/grokking-deep-reinforcement-learning/chapter-4/) is an instance of this class.

The mechanics of the optimistic initialization strategy are straightforward: we initialize[](/book/grokking-deep-reinforcement-learning/chapter-4/) the Q-function[](/book/grokking-deep-reinforcement-learning/chapter-4/) to a high value and act greedily using these estimates. Two points to clarify: First “a high value” is something we don’t have access to in RL, which we’ll address this later in this chapter; but for now, pretend we have that number in advance. Second, in addition to the Q-values, we need to initialize the counts to a value higher than one. If we don’t, the Q-function will change too quickly, and the effect of the strategy will be reduced.

![Optimistic initialization in the BSW](https://drek4537l1klr.cloudfront.net/morales/Figures/04_08.png)

|   | I Speak Python Optimistic initialization strategy |
| --- | --- |
|  |  |

Interesting, right? Momma was right! Because the agent initially expects to obtain more reward than it actually can, it goes around exploring until it finds sources of reward. As it gains experience, the “naiveness” of the agent goes away, that is, the Q-values get lower and lower until they converge to their actual values.

Again, by initializing the Q-function to a high value, we encourage the exploration of unexplored actions. As the agent interacts with the environment, our estimates will start converging to lower, but more accurate, estimates, allowing the agent to find and converge to the action with the actual highest payoff.

The bottom line is if you’re going to act greedily, at least be optimistic.

|   | A Concrete Example Two-armed Bernoulli bandit environment |
| --- | --- |
|  | Let’s compare specific instantiations of the strategies we have presented so far on a set of two-armed Bernoulli bandit environments. Two-armed Bernoulli bandit environments have a single non-terminal state and two actions. Action 0 has an α chance of paying a +1 reward, and with 1–α, it will pay 0 rewards. Action 1 has a β chance of paying a +1 reward, and with 1–β, it will pay 0 rewards. This is similar to the BSW to an extent. BSW has complimentary probabilities: action 0 pays +1 with α probability, and action 1 pays +1 with 1–α chance. In this kind of bandit environment, these probabilities are independent; they can even be equal. Look at my depiction of the two-armed Bernoulli bandit MDP.  Two-armed Bernoulli bandit environments It’s crucial you notice there are many different ways of representing this environment. And in fact, this isn’t how I have it written in code, because there’s much redundant and unnecessary information. Consider, for instance, the two terminal states. One could have the two actions transitioning to the same terminal state. But, you know, drawing that would make the graph too convoluted. The important lesson here is you’re free to build and represent environments your own way; there isn’t a single correct answer. There are definitely multiple incorrect ways, but there are also multiple correct ways. Make sure to *explore*! Yeah, I went there. |

|   | Tally it Up Simple exploration strategies in two-armed Bernoulli bandit environments |
| --- | --- |
|  | I ran two hyperparameter instantiations of all strategies presented so far: the epsilon-greedy, the two decaying, and the optimistic approach, along with the pure exploitation and exploration baselines on five two-armed Bernoulli bandit environments with probabilities α and β initialized uniformly at random, and five seeds. Results are means across 25 runs.  The best performing strategy in this experiment is the optimistic with 1.0 initial Q-values and 10 initial counts. All strategies perform pretty well, and these weren’t highly tuned, so it’s just for the fun of it and nothing else. Head to chapter 4’s Notebook and play, have fun. |

|   | It's In The Details Simple strategies in the two-armed Bernoulli bandit environments |
| --- | --- |
|  | Let’s talk about several of the details in this experiment. First, I ran five different seeds (12, 34, 56, 78, 90) to generate five different two-armed Bernoulli bandit environments. Remember, all Bernoulli bandits pay a +1 reward with certain probability for each arm. The resulting environments and their probability of payoff look as follows: Two-armed bandit with seed 12: <br>      <br>      Probability of reward: [0.41630234, 0.5545003 ] <br>      Two-armed bandit with seed 34: <br>      <br>      Probability of reward: [0.88039337, 0.56881791] <br>      Two-armed bandit with seed 56: <br>      <br>      Probability of reward: [0.44859284, 0.9499771 ] <br>      Two-armed bandit with seed 78: <br>      <br>      Probability of reward: [0.53235706, 0.84511988] <br>      Two -armed bandit with seed 90: <br>      <br>      Probability of reward: [0.56461729, 0.91744039] <br>      The mean optimal value across all seeds is 0.83. All of the strategies were run against each of the environments above with five different seeds (12, 34, 56, 78, 90) to smooth and factor out the randomness of the results. For instance, I first used seed 12 to create a Bernoulli bandit, then I used seeds 12, 34, and so on, to get the performance of each strategy under the environment created with seed 12. Then, I used seed 34 to create another Bernoulli bandit and used 12, 34, and so on, to evaluate each strategy under the environment created with seed 34. I did this for all strategies in all five environments. Overall, the results are the means over the five environments and five seeds, so 25 different runs per strategy. I tuned each strategy independently but also manually. I used approximately 10 hyperparameter combinations and picked the top two from those. |

## Strategic exploration

Alright, imagine you’re[](/book/grokking-deep-reinforcement-learning/chapter-4/)[](/book/grokking-deep-reinforcement-learning/chapter-4/) tasked with writing a reinforcement learning agent to learn driving a car. You decide to implement an epsilon-greedy exploration strategy. You flash your agent into the car’s computer, start the car, push that beautiful bright green button, and then your car starts exploring. It will flip a coin and decide to explore with a random action, say to drive on the other side of the road. Like it? Right, me neither. I hope this example helps to illustrate the need for different exploration strategies.

Let me be clear that this example is, of course, an exaggeration. You wouldn’t put an untrained agent directly into the real world to learn. In reality, if you’re trying to use RL in a real car, drone, or in the real world in general, you’d first pre-train your agent in simulation, and/or use more sample-efficient methods.

But, my point holds. If you think about it, while humans explore, we don’t explore randomly. Maybe infants do. But not adults. Maybe imprecision is the source of our randomness, but we don’t randomly marry someone just because (unless you go to Vegas.) Instead, I’d argue that adults have a more strategic way of exploring. We know that we’re sacrificing short- for long-term satisfaction. We know we want to acquire information. We explore by trying things we haven’t sufficiently tried but have the potential to better our lives. Perhaps, our exploration strategies are a combination of estimates and their uncertainty. For instance, we might prefer a dish that we’re likely to enjoy, and we haven’t tried, over a dish that we like okay, but we get every weekend. Perhaps we explore based on our “curiosity” or our prediction error. For instance, we might be more inclined to try new dishes at a restaurant that we thought would be okay-tasting food, but it resulted in the best food you ever had. That “prediction error” and that “surprise” could be our metric for exploration at times.

In the rest of this chapter, we’ll look at slightly more advanced exploration strategies. Several are still random exploration strategies, but they apply this randomness in proportion to the current estimates of the actions. Other exploration strategies take into account the confidence and uncertainty levels of the estimates.

All this being said, I want to reiterate that the epsilon-greedy strategy (and its decaying versions) is still the most popular exploration strategy in use today, perhaps because it performs well, perhaps because of its simplicity. Maybe it’s because most reinforcement learning environments today live inside a computer, and there are very few safety concerns with the virtual world. It’s important for you to think hard about this problem. Balancing the exploration versus exploitation trade-off, the gathering and utilization of information is central to human intelligence, artificial intelligence, and reinforcement learning. I’m certain the advancements in this area will have a big impact in the fields of artificial intelligence, reinforcement learning, and all other fields interested in this fundamental trade-off.

### Softmax: Select actions randomly in proportion to their estimates

Random exploration[](/book/grokking-deep-reinforcement-learning/chapter-4/)[](/book/grokking-deep-reinforcement-learning/chapter-4/)[](/book/grokking-deep-reinforcement-learning/chapter-4/) strategies make more sense if they take into account Q-value estimates. By doing so, if there is an action that has a really low estimate, we’re less likely to try it. There’s a strategy, called *softmax strategy*, that does this: it samples an action from a probability distribution over the action-value function such that the probability of selecting an action is proportional to its current action-value estimate. This strategy, which is also part of the family of random exploration strategies, is related to the epsilon-greedy strategy because of the injection of randomness in the exploration phase. Epsilon-greedy samples uniformly at random from the full set of actions available at a given state, while softmax samples based on preferences of higher valued actions.

By using the softmax strategy, we’re effectively making the action-value estimates an indicator of preference. It doesn’t matter how high or low the values are; if you add a constant to all of them, the probability distribution will stay the same. You put preferences over the Q-function[](/book/grokking-deep-reinforcement-learning/chapter-4/) and sample an action from a probability distribution based on this preference. The difference between Q-value estimates will create a tendency to select actions with the highest estimates more often, and actions with the lowest estimates less frequently.

We can also add a hyperparameter to control the algorithm’s sensitivity to the differences in Q-value estimates. That hyperparameter, called the temperature[](/book/grokking-deep-reinforcement-learning/chapter-4/) (a reference to statistical mechanics), works in such a way that as it approaches infinity, the preferences over the Q-values are equal. Basically, we sample an action uniformly. But, as the temperature value approaches zero, the action with the highest estimated value will be sampled with probability of one. Also, we can decay this hyperparameter either linearly, exponentially, or another way. But, in practice, for numerical stability reasons, we can’t use infinity or zero as the temperature; instead, we use a very high or very low positive real number, and normalize these values.

|   | Show Me The Math Softmax exploration strategy |
| --- | --- |
|  |  |

|   | I Speak Python Softmax strategy |
| --- | --- |
|  |  |

### UCB: It’s not about optimism, it’s about realistic optimism

In the last section, I introduced[](/book/grokking-deep-reinforcement-learning/chapter-4/)[](/book/grokking-deep-reinforcement-learning/chapter-4/)[](/book/grokking-deep-reinforcement-learning/chapter-4/)[](/book/grokking-deep-reinforcement-learning/chapter-4/) the optimistic initialization strategy. This is a clever (and perhaps philosophical) approach to dealing with the exploration versus exploitation trade-off, and it’s the simplest method in the optimism in the face of uncertainty family of strategies. But, there are two significant inconveniences with the specific algorithm we looked at. First, we don’t always know the maximum reward the agent can obtain from an environment. If you set the initial Q-value estimates of an optimistic strategy to a value much higher than its actual maximum value, unfortunately, the algorithm will perform sub-optimally because the agent will take many episodes (depending on the “counts” hyperparameter) to bring the estimates near the actual values. But even worse, if you set the initial Q-values to a value lower than the environment’s maximum, the algorithm will no longer be optimistic, and it will no longer work.

The second issue with this strategy as we presented it is that the “counts” variable is a hyperparameter and it needs tuning, but in reality, what we’re trying to represent with this variable is the uncertainty of the estimate, which shouldn’t be a hyperparameter. A better strategy, instead of believing everything is roses from the beginning and arbitrarily setting certainty measure values, follows the same principles as optimistic initialization while using statistical techniques to calculate the value estimates uncertainty and uses that as a bonus for exploration. This is what the *upper confidence bound* (UCB) strategy does.

In UCB, we’re still optimistic, but it’s a more a realistic optimism; instead of blindly hoping for the best, we look at the uncertainty of value estimates. The more uncertain a Q-value estimate, the more critical it is to explore it. Note that it’s no longer about believing the value will be the “maximum possible,” though it might be! The new metric that we care about here is uncertainty[](/book/grokking-deep-reinforcement-learning/chapter-4/); we want to give uncertainty the benefit of the doubt.

|   | Show Me The Math Upper confidence bound (UCB) equation |
| --- | --- |
|  |  |

To implement this strategy, we select the action with the highest sum of its Q-value estimate and an action-uncertainty bonus U. That is, we’re going to add a bonus, upper confidence bound *Ut (a)*, to the Q-value estimate of action *a*, such that if we attempt action *a* only a few times, the *U* bonus is large, thus encouraging exploring this action. If the number of attempts is significant, we add only a small *U* bonus value to the Q-value estimates, because we are more confident of the Q-value estimates; they’re not as critical to explore.

|   | I Speak Python Upper confidence bound (UCB) strategy |
| --- | --- |
|  |  |

On a practical level, if you plot *U* as a function of the episodes and counts, you’ll notice it’s much like an exponentially decaying function with a few differences. Instead of the smooth decay exponential functions show, there’s a sharp decay early on and a long tail. This makes it so that early on when the episodes are low, there’s a higher bonus for smaller differences between actions, but as more episode pass, and counts increase, the difference in bonuses for uncertainty become smaller. In other words, a 0 versus 100 attempts should give a higher bonus to 0 than to a 100 in a 100 versus 200 attempts. Finally, the *c* hyperparameter controls the scale of the bonus: a higher *c* means higher bonuses, lower *c* lower bonuse

### Thompson sampling: Balancing reward and risk

The UCB algorithm[](/book/grokking-deep-reinforcement-learning/chapter-4/)[](/book/grokking-deep-reinforcement-learning/chapter-4/)[](/book/grokking-deep-reinforcement-learning/chapter-4/) is a frequentist approach to dealing with the exploration versus exploitation trade-off because it makes minimal assumptions about the distributions underlying the Q-function. But other techniques, such as Bayesian strategies, can use priors to make reasonable assumptions and exploit this knowledge. The *Thompson sampling* strategy is a sample-based probability matching strategy that allows us to use Bayesian techniques to balance the exploration and exploitation trade-off.

A simple way to implement this strategy is to keep track of each Q-value as a Gaussian (a.k.a. normal) distribution. In reality, you can use any other kind of probability distribution as prior; beta distributions, for instance, are a common choice. In our case, the Gaussian mean is the Q-value estimate, and the Gaussian standard deviation measures the uncertainty of the estimate, which are updated on each episode.

![Comparing two action-value functions represented as Gaussian distributions](https://drek4537l1klr.cloudfront.net/morales/Figures/04_09.png)

As the name suggests, in Thompson sampling, we sample from these normal distributions and pick the action that returns the highest sample. Then, to update the Gaussian distributions’ standard deviation, we use a formula similar to the UCB strategy in which, early on when the uncertainty is higher, the standard deviation is more significant; therefore, the Gaussian is broad. But as the episodes progress, and the means shift toward better and better estimates, the standard deviations gets lower, and the Gaussian distribution shrinks, and so its samples are more and more likely to be near the estimated mean.

|   | I Speak Python Thompson sampling strategy |
| --- | --- |
|  |  |

In this particular implementation, I use two hyperparameters: alpha, to control the scale of the Gaussian, or how large the initial standard deviation will be, and beta, to shift the decay such that the standard deviation shrinks more slowly. In practice, these hyperparameters need little tuning for the examples in this chapter because, as you probably already know, a standard deviation of just five, for instance, is almost a flat-looking Gaussian representing over a ten-unit spread. Given our problems have rewards (and Q-values) between 0 and 1, and approximately between –3 and 3 (the example coming up next), we wouldn’t need any Gaussian with standard deviations too much greater than 1.

Finally, I want to reemphasize that using Gaussian distributions is perhaps not the most common approach to Thompson sampling. Beta distributions seem to be the favorites here. I prefer Gaussian for these problems because of their symmetry around the mean, and because their simplicity makes them suitable for teaching purposes. However, I encourage you to dig more into this topic and share what you find.

|   | Tally it Up Advanced exploration strategies in two-armed Bernoulli bandit environments |
| --- | --- |
|  | I ran two hyperparameter instantiations of each of the new strategies introduced: the softmax, the UCB, and the Thompson approach, along with the pure exploitation and exploration baselines, and the top-performing simple strategies from earlier on the same five two-armed Bernoulli bandit environments. This is again a total of 10 agents in five environments across five seeds. It’s a 25 runs total per strategy. The results are averages across these runs.  Besides the fact that the optimistic strategy uses domain knowledge that we cannot assume we’ll have, the results indicate that the more advanced approaches do better. |

|   | A Concrete Example 10-armed Gaussian bandit environments |
| --- | --- |
|  | 10-armed Gaussian bandit environments still have a single non-terminal state; they’re bandit environments. As you probably can tell, they have ten arms or actions instead of two like their Bernoulli counterparts. But, the probability distributions and reward signals are different from the Bernoulli bandits. First, Bernoulli bandits have a probability of payoff of p, and with 1–p, the arm won’t pay anything. Gaussian bandits, on the other hand, will always pay something (unless they sample a 0—more on this next). Second, Bernoulli bandits have a binary reward signal: you either get a +1 or a 0. Instead, Gaussian bandits pay every time by sampling a reward from a Gaussian distribution.  10-armed Gaussian bandit To create a 10-armed Gaussian bandit environment, you first sample from a standard normal (Gaussian with mean 0 and variance 1) distribution 10 times to get the optimal action-value function *q*(ak)* for all *k*(10) arms. These values will become the mean of the reward signal for each action. To get the reward for action *k* at episode e, we sample from another Gaussian with mean *q*(ak)*, and variance 1. |

|   | Show Me The Math 10-armed Gaussian bandit reward function |
| --- | --- |
|  |  |

|   | Tally it Up Advanced exploration strategies in 10-armed Gaussian bandit environments |
| --- | --- |
|  | I ran the same hyperparameter instantiations of the simple strategies introduced earlier, now on five 10-armed Gaussian bandit environments. This is obviously an “unfair” experiment because these techniques can perform well in this environment if properly tuned, but my goal is to show that the most advanced strategies still do well with the old hyperparameters, despite the change of the environment. You’ll see that in the next example.  Look at that, several of the most straightforward strategies have the lowest total regret and the highest expected reward across the five different scenarios. Think about that for a sec! |

|   | Tally it Up Advanced exploration strategies in 10-armed Gaussian bandit environments |
| --- | --- |
|  | I then ran the advanced strategies with the same hyperparameters as before. I also added the two baselines and the top two performing simple strategies in the 10-armed Gaussian bandit. As with all other experiments, this is a total of 25 five runs.  This time only the advanced strategies make it on top, with a pretty decent total regret. What you should do now is head to the Notebook and have fun! Please, also share with the community your results, if you run additional experiments. I can’t wait to see how you extend these experiments. Enjoy! |

## Summary

Learning from evaluative feedback is a fundamental challenge that makes reinforcement learning unique. When learning from evaluative feedback, that is, +1, +1.345, +1.5, –100, –4, your agent doesn’t know the underlying MDP and therefore cannot determine what the maximum reward it can obtain is. Your agent “thinks”: “Well, I got a +1, but I don’t know, maybe there’s a +100 under this rock?” This uncertainty in the environment forces you to design agents that explore.

But as you learned, you can’t take exploration lightly. Fundamentally, exploration wastes cycles that could otherwise be used for maximizing reward, for exploitation, yet, your agent can’t maximize reward, or at least pretend it can, without gathering information first, which is what exploration does. All of a sudden, your agent has to learn to balance exploration and exploitation; it has to learn to compromise, to find an equilibrium between two crucial yet competing sides. We’ve all faced this fundamental trade-off in our lives, so these issues should be intuitive to you: “A bird in the hand is worth two in the bush,” yet “A man’s reach should exceed his grasp.” Pick your poison, and have fun doing it, just don’t get stuck to either one. Balance them!

Knowing this fundamental trade-off, we introduced several different techniques to create agents, or strategies, for balancing exploration and exploitation. The epsilon-greedy strategy does it by exploiting most of the time and exploring only a fraction. This exploration step is done by sampling an action at random. Decaying epsilon-greedy strategies capture the fact that agents need more exploration at first because they need to gather information to start making a right decision, but they should quickly begin to exploit to ensure they don’t accumulate regret, which is a measure of how far from optimal we act. Decaying epsilon-greedy strategies decay epsilon as episodes increase and, hopefully, as our agent gathers information.

But then we learned about other strategies that try to ensure that “hopefully” is more likely. These strategies take into account estimates and their uncertainty and potential and select accordingly: optimistic initialization, UCB, Thompson sampling, and although softmax doesn’t really use uncertainty measures, it explores by selecting randomly in the proportion of the estimates.

By now, you

- Understand that the challenge of learning from evaluative feedback is because agents cannot see the underlying MDP governing their environments
- Learned that the exploration versus exploitation trade-off rises from this problem
- Know about many strategies that are commonly used for dealing with this issue

|   | Tweetable Feat Work on your own and share your findings |
| --- | --- |
|  | Here are several ideas on how to take what you’ve learned to the next level. If you’d like, share your results with the rest of the world and make sure to check out what others have done, too. It’s a win-win situation, and hopefully, you’ll take advantage of it. <br>      <br>      **#gdrl_ch04_tf01:** There are many more techniques for solving bandit environments. Try exploring other resources out there and tell us techniques that are important. Research Bayesian approaches to action selection, and also, action-selection strategies that are based on information gain. What is information gain, again? Why is this important in the context of RL? Can you develop other interesting action-selection strategies, including decaying strategies that use information to decay the exploration rate of agents? For instance, imagine an agent the decays epsilon based on state visits—perhaps on another metric. <br>      **#gdrl_ch04_tf02:** Can you think of a few other bandit environments that are interesting to examine? Clone my bandit repository ([https://github.com/mimoralea/gym-bandits](https://github.com/mimoralea/gym-bandits) -which is forked, too,) and add a few other bandit environments to it. <br>      **#gdrl_ch04_tf03:** After bandit environments, but before reinforcement learning algorithms, there’s another kind of environment called contextual bandit problems. What are these kinds of problems? Can you help us understand what these are? But, don’t just create a blog post about them. Also create a Gym environment with contextual bandits. Is that even possible? Create those environments in a Python package, and another Python package with algorithms that can solve contextual bandit environments. <br>      **#gdrl_ch04_tf04:** In every chapter, I’m using the final hashtag as a catchall hashtag. Feel free to use this one to discuss anything else that you worked on relevant to this chapter. There’s no more exciting homework than that which you create for yourself. Make sure to share what you set yourself to investigate and your results. <br>      Write a tweet with your findings, tag me @mimoralea (I’ll retweet), and use the particular hashtag from this list to help interested folks find your results. There are no right or wrong results; you share your findings and check others’ findings. Take advantage of this to socialize, contribute, and get yourself out there! We’re waiting for you! Here’s a tweet example: “Hey, @mimoralea. I created a blog post with a list of resources to study deep reinforcement learning. Check it out at <link>. #gdrl_ch01_tf01” I’ll make sure to retweet and help others find your work. |
