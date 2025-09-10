# 7 Achieving goals more effectively and efficiently

### In this chapter

- You will learn about making reinforcement learning agents more effective at reaching optimal performance when interacting with challenging environments.
- You will learn about making reinforcement learning agents more efficient at achieving goals by making the most of the experiences.
- You will improve on the agents presented in the previous chapters to have them make the most out of the data they collect and therefore optimize their performance more quickly.

*Efficiency is doing things right; effectiveness is doing the right things.*

— Peter Drucker
Founder of modern management and Presidential Medal of Freedom recipient

In this chapter, we improve on the agents you learned about in the previous chapter. More specifically, we take on two separate lines of improvement. First, we use the *λ*-return that you learned about in chapter 5 for the policy evaluation requirements of the generalized policy iteration pattern. We explore using the *λ*-return for both on-policy and off-policy methods. Using the *λ*-return with eligibility traces propagates credit to the right state-action pairs more quickly than standard methods, making the value-function estimates get near the actual values faster.

Second, we explore algorithms that use experience samples to learn a model of the environment, a Markov decision process (MDP). By doing so, these methods extract the most out of the data they collect and often arrive at optimality more quickly than methods that don’t. The group of algorithms that attempt to learn a model of the environment is referred to as *model-based reinforcement learning*.

It’s important to note that even though we explore these lines of improvements separately, nothing prevents you from trying to combine them, and it’s perhaps something you should do after finishing this chapter. Let’s get to the details right away.

| ŘŁ | With An RL Accent Planning vs. model-free RL vs. model-based RL |
| --- | --- |
|  | **Planning:** Refers to algorithms that require a model of the environment to produce a policy. Planning methods can be of state-space planning type, which means they use the state space to find a policy, or they can be of plan-space planning type, meaning they search in the space of all possible plans (think about genetic algorithms.) Examples of planning algorithms that we’ve learned about in this book are value iteration and policy iteration. **Model-free RL:** Refers to algorithms that don’t use models of the environments, but are still able to produce a policy. The unique characteristic here is these methods obtain policies without the use of a map, a model, or an MDP. Instead, they use trial-and-error learning to obtain policies. Several examples of model-free RL algorithms that we have explored in this book are MC, SARSA, and Q-learning. **Model-based RL:** Refers to algorithms that can learn, but don’t require, a model of the environment to produce a policy. The distinction is they don’t require models in advance, but can certainly make good use of them if available, and more importantly, attempt to learn the models through interaction with the environment. Several examples of model-based RL algorithms we learn about in this chapter are Dyna-Q and trajectory sampling. |

## Learning to improve policies using robust targets

The first line of improvement we discuss in this chapter is using more robust targets in our policy-evaluation methods. Recall that in chapter 5, we explored policy-evaluation methods that use different kinds of targets for estimating value functions. You learned about the Monte Carlo and TD approaches, but also about a target called the *λ*-return that uses a weighted combination of targets obtained using all visited states.

TD(*λ*) is the prediction method that uses the *λ*-return for our policy evaluation needs. However, as you remember from the previous chapter, when dealing with the control problem, we need to use a policy-evaluation method for estimating action-value functions, and a policy-improvement method that allows for exploration. In this section, we discuss control methods similar to SARSA and Q-learning, but use instead the *λ*-return.

|   | A Concrete Example The slippery walk seven environment |
| --- | --- |
|  | To introduce the algorithms in this chapter, we use the same environment we used in the previous chapter, called slippery walk seven (SWS). However, at the end of the chapter, we test the methods in much more challenging environments. Recall that the SWS is a walk, a single-row grid-world environment, with seven non-terminal states. Remember that this environment is a “slippery” walk, meaning that it’s noisy, that action effects are stochastic. If the agent chooses to go left, there’s a chance it does, but there’s also some chance that it goes right, or that it stays in place.  Slippery walk seven environment MDP As a refresher, above is the MDP of this environments. But remember and always have in mind that the agent doesn’t have any access to the transition probabilities. The dynamics of this environment are unknown to the agent. Also, to the agent, there are no relationships between the states in advance. |

### SARSA(λ): Improving policies after each step based on multi-step estimates

*SARSA***(***λ*[](/book/grokking-deep-reinforcement-learning/chapter-7/)**)** is a straightforward[](/book/grokking-deep-reinforcement-learning/chapter-7/) improvement to the original SARSA agent. The main difference between SARSA and SARSA(*λ*) is that instead of using the one-step bootstrapping target—the TD target, as we do in SARSA, in SARSA(*λ*), we use the *λ*-return. And that’s it; you have SARSA(*λ*). Seriously! Did you see how learning the basics makes the more complex concepts easier?

Now, I’d like to dig a little deeper into the concept of eligibility traces[](/book/grokking-deep-reinforcement-learning/chapter-7/) that you first read about in chapter 5. The type of eligibility trace I introduced in chapter 5 is called the *accumulating trace*[](/book/grokking-deep-reinforcement-learning/chapter-7/). However, in reality, there are multiple ways of tracing state or state-action pairs responsible for a reward.

In this section, we dig deeper into the accumulating trace and adapt it for solving the control problem, but we also explore a different kind of trace called the *replacing trace*[](/book/grokking-deep-reinforcement-learning/chapter-7/) and use them both in the SARSA(*λ*) agent.

| 0001 | A Bit Of History Introduction of the SARSA and SARSA(*λ*) agents |
| --- | --- |
|  | In 1994, Gavin Rummery and Mahesan Niranjan published a paper titled “Online Q-Learning Using Connectionist Systems,” in which they introduced an algorithm they called at the time “Modified Connectionist Q-Learning.” In 1996, Singh and Sutton dubbed this algorithm SARSA because of the quintuple of events that the algorithm uses: (*S**t*, *A**t*, *R**t*+1, *S**t*+1, *A**t*+1). People often like knowing where these names come from, and as you’ll soon see, RL researchers can get pretty creative with these names. Funny enough, before this open and “unauthorized” rename of the algorithm, in 1995 in his PhD thesis titled “Problem Solving with Reinforcement Learning,” Gavin issued Sutton an apology for continuing to use the name “Modified Q-Learning[](/book/grokking-deep-reinforcement-learning/chapter-7/)” despite Sutton’s preference for “SARSA.” Sutton also continued to use SARSA, which is ultimately the name that stuck with the algorithm in the RL community. By the way, Gavin’s thesis also introduced the SARSA(λ) agent. After obtaining his PhD in 1995, Gavin became a programmer and later a lead programmer for the company responsible for the series of the Tomb Raider games. Gavin has had a successful career as a game developer. Mahesan, who became Gavin’s PhD supervisor after the unexpected death of Gavin’s original supervisor, followed a more traditional academic career holding lecturer and professor roles ever since his graduation in 1990. |

For adapting the accumulating trace to solving the control problem, the only necessary change is that we must now track the visited state-action pairs, instead of visited states. Instead of using an eligibility vector for tracking visited states, we use an eligibility matrix for tracking visited state-action pairs.

The replace-trace mechanism is also straightforward. It consists of clipping eligibility traces to a maximum value of one; that is, instead of accumulating eligibility without bound, we allow traces to only grow to one. This strategy has the advantage that if your agents get stuck in a loop, the traces still don’t grow out of proportion. The bottom line is that traces, in the replace-trace strategy, are set to one when a state-action pair is visited, and decay based on the *λ* value just like in the accumulate-trace strategy.

| 0001 | A Bit Of History Introduction of the eligibility trace mechanism |
| --- | --- |
|  | The general idea of an eligibility trace mechanism is probably due to A. Harry Klopf, when, in a 1972 paper titled “Brain Function and Adaptive Systems—A Heterostatic Theory,” he described how synapses would become “eligible” for changes after reinforcing events. He hypothesized: “When a neuron fires, all of its excitatory and inhibitory synapses that were active during the summation of potentials leading to the response are *eligible* to undergo changes in their transmittances.” However, in the context of RL, Richard Sutton’s[](/book/grokking-deep-reinforcement-learning/chapter-7/) PhD thesis (1984) introduced the mechanism of eligibility traces. More concretely, he introduced the accumulating trace that you’ve learned about in this book, also known as the conventional accumulating trace. The replacing trace, on the other hand, was introduced by Satinder Singh[](/book/grokking-deep-reinforcement-learning/chapter-7/) and Richard Sutton in a 1996 paper titled “Reinforcement Learning with Replacing Eligibility Traces[](/book/grokking-deep-reinforcement-learning/chapter-7/),” which we discuss in this chapter. They found a few interesting facts. First, they found that the replace-trace mechanism results in faster and more reliable learning than the accumulate-trace one. They also found that the accumulate-trace mechanism is biased, while the replace-trace one is unbiased. But more interestingly, they found relationships between TD(1), MC, and eligibility traces. More concretely, they found that TD(1) with replacing traces is related to first-visit MC and that TD(1) with accumulating traces is related to every-visit MC. Moreover, they found that the offline version of the replace-trace TD(1) is identical to first-visit MC. It’s a small world! |

![Accumulating traces in the SWS environment](https://drek4537l1klr.cloudfront.net/morales/Figures/07_02.png)

|   | Boil It Down Frequency and recency heuristics in the accumulating-trace mechanism |
| --- | --- |
|  | The accumulating trace combines a frequency and a recency heuristic. When your agent tries a state-action pair, the trace for this pair is incremented by one. Now, imagine there’s a loop in the environment, and the agent tries the same state-action pair several times. Should we make this state-action pair “more” responsible for rewards obtained in the future, or should we make it just responsible? Accumulating traces allow trace values higher than one while replacing traces don’t. Traces have a way for combining frequency (how often you try a state-action pair) and recency (how long ago you tried a state-action pair) heuristics implicitly encoded in the trace mechanism. |

![Replacing traces in the SWS environment](https://drek4537l1klr.cloudfront.net/morales/Figures/07_03.png)

|   | I Speak Python The SARSA(λ) agent |
| --- | --- |
|  |  |

|   | Miguel's Analogy Accumulating and replacing traces, and a gluten- and banana-free diet |
| --- | --- |
|  | A few months back, my daughter was having trouble sleeping at night. Every night, she would wake up multiple times, crying very loudly, but unfortunately, not telling us what the problem was. After a few nights, my wife and I decided to do something about it and try to “trace” back the issue so that we could more effectively “assign credit” to what was causing the sleepless nights. We put on our detective hats (if you’re a parent, you know what this is like) and tried many things to diagnose the problem. After a week or so, we narrowed the issue to foods; we knew the bad nights were happening when she ate certain foods, but we couldn’t determine which foods exactly were to blame. I noticed that throughout the day, she would eat lots of carbs with gluten, such as cereal, pasta, crackers, and bread. And, close to bedtime, she would snack on fruits. An “accumulating trace” in my brain pointed to the carbs. “Of course!” I thought, “Gluten is evil; we all know that. Plus, she is eating all that gluten throughout the day.” If we trace back and accumulate the number of times she ate gluten, gluten was clearly eligible, was clearly to blame, so we did remove the gluten. But, to our surprise, the issue only subsided, it didn’t entirely disappear as we hoped. After a few days, my wife remembered she had trouble eating bananas at night when she was a kid. I couldn’t believe it, I mean, bananas are fruits, and fruits are only good for you, right? But funny enough, in the end, removing bananas got rid of the bad nights. Hard to believe! But, perhaps if I would’ve used a “replacing trace” instead of an “accumulating trace,” all of the carbs she ate multiple times throughout the day would have received a more conservative amount of blame. Instead, because I was using an accumulating trace, it seemed to me that the many times she ate gluten were to blame. Period. I couldn’t see clearly that the recency of the bananas played a role. The bottom line is that accumulating traces can “exaggerate” when confronted with frequency while replacing traces moderate the blame assigned to frequent events. This moderation can help the more recent, but rare events surface and be taken into account. Don’t make any conclusions, yet. Like everything in life, and in RL, it’s vital for you to know the tools and don’t just dismiss things at first glance. I’m just showing you the available options, but it’s up to you to use the right tools to achieve your goals. |

### Watkins’s *Q*(*λ*): Decoupling behavior from learning, again

And, of course[](/book/grokking-deep-reinforcement-learning/chapter-7/), there’s an off-policy control version of the *λ* algorithms. *Q*(*λ*) is an extension of Q-learning that uses the *λ*-return for policy-evaluation requirements of the generalized policy-iteration pattern. Remember, the only change we’re doing here is replacing the TD target for off-policy control (the one that uses the max over the action in the next state) with a *λ*-return for off-policy control. There are two different ways to extend Q-learning to eligibility traces, but, I’m only introducing the original version, commonly referred to as *Watkins’s Q(**λ*).

| 0001 | A Bit Of History Introduction of the Q-learning and *Q*(*λ*) agents |
| --- | --- |
|  | In 1989, the Q-learning and *Q*(*λ*) methods were introduced by Chris Watkins in his PhD thesis titled “Learning from Delayed Rewards,” which was foundational to the development of the current theory of reinforcement learning. Q-learning is still one of the most popular reinforcement learning algorithms, perhaps because it’s simple and it works well. *Q*(*λ*) is now referred to as Watkins’s *Q*(*λ*) because there’s a slightly different version of *Q*(*λ*)—due to Jing Peng[](/book/grokking-deep-reinforcement-learning/chapter-7/) and Ronald Williams[](/book/grokking-deep-reinforcement-learning/chapter-7/)—that was worked between 1993 and 1996 (that version is referred to as Peng’s *Q*(*λ*).) In 1992, Chris, along with Peter Dayan[](/book/grokking-deep-reinforcement-learning/chapter-7/), published a paper titled “Technical Note Q-learning[](/book/grokking-deep-reinforcement-learning/chapter-7/),” in which they proved a convergence theorem for Q-learning. They showed that Q-learning converges with probability 1 to the optimum action-value function, with the assumption that all state-action pairs are repeatedly sampled and represented discretely. Unfortunately, Chris stopped doing RL research almost right after that. He went on to work for hedge funds in London, then visited research labs, including a group led by Yann LeCun, always working AI-related problems, but not so much RL. For the past 22+ years, Chris has been a Reader in Artificial Intelligence at the University of London. After finishing his 1991 PhD thesis titled “Reinforcing Connectionism: Learning the Statistical Way.” (Yeah, connectionism is what they called neural networks back then—“deep reinforcement learning” you say? Yep!) Peter went on a couple of postdocs, including one with Geoff Hinton at the University of Toronto. Peter was a postdoc advisor to Demis Hassabis, cofounder of DeepMind. Peter has held many director positions at research labs, and the latest is the Max Planck Institute. Since 2018 he’s been a Fellow of the Royal Society, one of the highest awards given in the UK. |

|   | I Speak Python The Watkins’s *Q*(*λ*) agent 1/3[](/book/grokking-deep-reinforcement-learning/chapter-7/) |
| --- | --- |
|  |  |

|   | I Speak Python The Watkins’s *Q*(*λ*) agent 2/3[](/book/grokking-deep-reinforcement-learning/chapter-7/) |
| --- | --- |
|  |  |

|   | I Speak Python The Watkins’s *Q*(*λ*) agent 3/3[](/book/grokking-deep-reinforcement-learning/chapter-7/) |
| --- | --- |
|  |  |

## Agents that interact, learn, and plan

In chapter 3, we discussed planning algorithms such as value iteration (VI) and policy iteration (PI). These are planning algorithms because they require a model of the environment, an MDP. Planning methods calculate optimal policies offline. On the other hand, in the last chapter I presented model-free reinforcement learning methods, perhaps even suggesting that they were an improvement over planning methods. But are they?

The advantage of model-free RL over planning methods is that the former doesn’t require MDPs. Often MDPs are challenging to obtain in advance; sometimes MDPs are even impossible to create. Imagine representing the game of Go with *10*170 possible states or StarCraft II with *10*1685 states. Those are significant numbers, and that doesn’t even include the action spaces or transition function, imagine! Not requiring an MDP in advance is a practical benefit.

But, let’s think about this for a second: what if we don’t require an MDP in advance, but perhaps learn one as we interact with the environment? Think about it: as you walk around a new area, you start building a map in your head. You walk around for a while, find a coffee shop, get coffee, and you know how to get back. The skill of learning maps should be intuitive to you. Can reinforcement learning agents do something similar to this?

In this section, we explore agents that interact with the environment, like the model-free methods, but they also learn models of the environment from these interactions, MDPs. By learning maps, agents often require fewer experience samples to learn optimal policies. These methods are called *model-based reinforcement learning*[](/book/grokking-deep-reinforcement-learning/chapter-7/). Note that in the literature, you often see VI and PI referred to as planning methods, but you may also see them referred to as model-based methods. I prefer to draw the line and call them planning methods because they require an MDP to do anything useful at all. SARSA and Q-learning algorithms are model-free because they do not require and do not learn an MDP. The methods that you learn about in this section are model-based because they do not require, but do learn and use an MDP (or at least an approximation of an MDP).

| ŘŁ | With An RL Accent Sampling models vs. distributional models |
| --- | --- |
|  | **Sampling models**: Refers to models of the environment that produce a single sample of how the environment will transition given some probabilities; you sample a transition from the model. **Distributional models**: Refers to models of the environment that produce the probability distribution of the transition and reward functions. |

### Dyna-Q: Learning sample models

One of the most well-known architectures for unifying planning and model-free methods is called *Dyna-Q*[](/book/grokking-deep-reinforcement-learning/chapter-7/). Dyna-Q consists of interleaving a model-free RL method, such as Q-learning, and a planning method, similar to value iteration, using both experiences sampled from the environment and experiences sampled from the learned model to improve the action-value function.

In Dyna-Q, we keep track of both the transition and reward function as three-dimensional tensors indexed by the state, the action, and the next state. The transition tensor keeps count of the number of times we’ve seen the three-tuple *(s, a, s')* indicating how many times we arrived at state *s'* from state *s* when selecting action *a*. The reward tensor holds the average reward we received on the three-tuple *(s, a, s')* indicating the expected reward when we select action *a* on state *s* and transition to state *s'*.

![A model-based reinforcement learning architecture](https://drek4537l1klr.cloudfront.net/morales/Figures/07_04.png)

| 0001 | A Bit Of History Introduction of the Dyna-Q agent |
| --- | --- |
|  | Ideas related to model-based RL methods can be traced back many years, and are credited to several researchers, but there are three main papers that set the foundation for the Dyna architecture. The first is a 1981 paper by Richard Sutton[](/book/grokking-deep-reinforcement-learning/chapter-7/) and Andrew Barto[](/book/grokking-deep-reinforcement-learning/chapter-7/) titled “An Adaptive Network that Constructs and Uses an Internal Model of Its World[](/book/grokking-deep-reinforcement-learning/chapter-7/),” then a 1990 paper by Richard Sutton titled “Integrated Architectures for Learning, Planning, and Reacting Based on Approximating Dynamic Programming[](/book/grokking-deep-reinforcement-learning/chapter-7/),” and, finally, a 1991 paper by Richard Sutton titled “Dyna, an Integrated Architecture for Learning, Planning, and Reacting[](/book/grokking-deep-reinforcement-learning/chapter-7/),” in which the general architecture leading to the specific Dyna-Q agent was introduced. |

|   | I Speak Python The Dyna-Q agent 1/3[](/book/grokking-deep-reinforcement-learning/chapter-7/) |
| --- | --- |
|  |  |

|   | I Speak Python The Dyna-Q agent 2/3[](/book/grokking-deep-reinforcement-learning/chapter-7/) |
| --- | --- |
|  |  |

|   | I Speak Python The Dyna-Q agent 3/3[](/book/grokking-deep-reinforcement-learning/chapter-7/) |
| --- | --- |
|  |  |

|   | Tally it Up Model-based methods learn the transition and reward function (transition below) |
| --- | --- |
|  |  |

### Trajectory sampling: Making plans for the immediate future

In Dyna-Q, we learn the model[](/book/grokking-deep-reinforcement-learning/chapter-7/) as previously described, adjust action-value functions as we do in vanilla Q-learning, and then run a few planning iterations at the end of the algorithm. Notice that if we removed the model-learning and planning lines from the code, we’d be left with the same Q-learning algorithm that we had in the previous chapter.

At the planning phase, we only sample from the state-action pairs that have been visited, so that the agent doesn’t waste resources with state-action pairs about which the model has no information. From those visited state-action pairs, we sample a state uniformly at random and then sample action from previously selected actions, also uniformly at random. Finally, we obtain the next state and reward sampling from the probabilities of transition given that state-action pair. But doesn’t this seem intuitively incorrect? We’re planning by using a state selected uniformly at random!

Couldn’t this technique be more effective if we used a state that we expect to encounter during the current episode? Think about it for a second. Would you prefer prioritizing planning your day, week, month, and year, or would you instead plan a random event that “could” happen in your life? Say that you’re a software engineer: would you prefer planning reading a programming book, and working on that side project, or a future possible career change to medicine? Planning for the immediate future is the smarter approach. *trajectory sampling* is a model-based RL method that does just that.

|   | Boil It Down Trajectory sampling |
| --- | --- |
|  | While Dyna-Q samples the learned MDP uniformly at random, trajectory sampling gathers trajectories, that is, transitions and rewards that can be encountered in the immediate future. You’re planning your week, not a random time in your life. It makes more sense to do it this way. The traditional trajectory-sampling approach is to sample from an initial state until reaching a terminal state using the on-policy trajectory, in other words, sampling actions from the same behavioral policy at the given time step. However, you shouldn’t limit yourself to this approach; you should experiment. For instance, my implementation samples starting from the current state, instead of an initial state, to a terminal state within a preset number of steps, sampling a policy greedy with respect to the current estimates. But you can try something else. As long as you’re sampling a trajectory, you can call that trajectory sampling. |

|   | I Speak Python The trajectory-sampling agent 1/3[](/book/grokking-deep-reinforcement-learning/chapter-7/) |
| --- | --- |
|  |  |

|   | I Speak Python The trajectory-sampling agent 2/3[](/book/grokking-deep-reinforcement-learning/chapter-7/) |
| --- | --- |
|  |  |

|   | I Speak Python The trajectory-sampling agent 3/3[](/book/grokking-deep-reinforcement-learning/chapter-7/) |
| --- | --- |
|  |  |

|   | Tally it Up Dyna-Q and trajectory sampling sample the learned model differently[](/book/grokking-deep-reinforcement-learning/chapter-7/)[](/book/grokking-deep-reinforcement-learning/chapter-7/) |
| --- | --- |
|  |  |

|   | A Concrete Example The frozen lake environment |
| --- | --- |
|  | In chapter 2, we developed the MDP for an environment called frozen lake (FL). As you remember, FL is a simple grid-world (GW) environment. It has discrete state and action spaces, with 16 states and four actions. The goal of the agent is to go from a start location to a goal location while avoiding falling into holes. In this particular instantiation of the frozen lake environment, the goal is to go from state 0 to state 15. The challenge is that the surface of the lake is frozen, and therefore slippery, very slippery.  The frozen lake environment The FL environment is a 4 × 4 grid with 16 cells, states 0–15, top-left to bottom-right. State 0 is the only state in the initial state distribution, meaning that on every new episode, the agent shows up in that START state. States 5, 7, 11, 12, and 15 are terminal states: once the agent lands on any of those states, the episode terminates. States 5, 7, 11, and 12 are holes, and state 15 is the “GOAL.” What makes “holes” and “GOAL” be any different is the reward function. All transitions landing on the GOAL state, state 15, provide a +1 reward, while every other transition in the entire grid world provides a 0 reward, no reward. The agent will naturally try to get to that +1 transition, and that involves avoiding the holes. The challenge of the environment is that actions have stochastic effects, so the agent moves only a third of the time as intended. The other two-thirds is split evenly in orthogonal directions. If the agent tries to move out of the grid world, it will bounce back to the cell from which it tried to move. |

|   | It's In The Details Hyperparameter values for the frozen lake environment |
| --- | --- |
|  | The frozen lake (FL) environment is a more challenging environment than, for instance, the slippery walk seven (SWS) environment. Therefore, one of the most important changes we need to make is to increase the number of episodes the agent interacts with the environment. While in the SWS environment, we allow the agent to interact for only 3,000 episodes; in the FL environment, we let the agent gather experience for 10,000 episodes. This simple change also automatically adjusts the decay schedule for both alpha and epsilon. Changing the value of the n_episodes parameter from 3,000 to 10,000 automatically changes the amount of exploration and learning of the agent. Alpha now decays from an initial value of 0.5 to a minimum value of 0.01 after 50% of the total episodes, which is 5,000 episodes, and epsilon decays from an initial value of 1.0 to a minimum value of 0.1 after 90% of the total episodes, which is 9,000 episodes.  Finally, it’s important to mention that I’m using a gamma of 0.99, and that the frozen lake environment, when used with OpenAI Gym, is automatically wrapped with a time limit Gym Wrapper. This “time wrapper” instance makes sure the agent terminates an episode with no more than 100 steps. Technically speaking, these two decisions (gamma and the time wrapper) change the optimal policy and value function the agent learns, and should not be taken lightly. I recommend playing with the FL environment in chapter 7’s Notebook and changing gamma to different values (1, 0.5, 0) and also removing the time wrapper by getting the environment instance attribute “unwrapped,” for instance, “env = env.unwrapped.” Try to understand how these two things affect the policies and value functions found. |

|   | Tally it Up Model-based RL methods get estimates closer to actual in fewer episodes |
| --- | --- |
|  |  |

|   | Tally it Up Both traces and model-based methods are efficient at processing experiences |
| --- | --- |
|  |  |

|   | A Concrete Example The frozen lake 8 x 8 environment |
| --- | --- |
|  | How about we step it up and try these algorithms in a challenging environment? This one is called frozen lake 8 × 8 (FL8×8[](/book/grokking-deep-reinforcement-learning/chapter-7/)) and as you might expect, this is an 8-by-8 grid world with properties similar to the FL. The initial state is state 0, the state on the top-left corner; the terminal, and GOAL state is state 63, the state on the bottom-right corner. The stochasticity of action effects is the same: the agent moves to the intended cell with a mere 33.33% chance, and the rest is split evenly in orthogonal directions.  The frozen lake 8 × 8 environment The main difference in this environment, as you can see, is that there are many more holes, and obviously they’re in different locations. States 19, 29, 35, 41, 42, 46, 49, 52, 54, and 59 are holes; that’s a total of 10 holes! Similar to the original FL environment, in FL8×8, the right policy allows the agent to reach the terminal state 100% of the episodes. However, in the OpenAI Gym implementation, agents that learn optimal policies do not find these particular policies because of gamma and the time wrapper we discussed. Think about it for a second: given the stochasticity of these environments, a safe policy could terminate in zero rewards for the episode due to the time wrapper. Also, given a gamma value less than one, the more steps the agent takes, the lower the reward will impact the return. For these reasons, safe policies aren’t necessarily optimal policies; therefore, the agent doesn’t learn them. Remember that the goal isn’t simply to find a policy that reaches the goal 100% of the times, but to find a policy that reaches the goal within 100 steps in FL and 200 steps in FL8×8. Agents may need to take risks to accomplish this goal. |

|   | It's In The Details Hyperparameter values for the frozen lake 8 × 8 environment |
| --- | --- |
|  | The frozen lake 8 × 8 (FL8×8) environment is the most challenging discrete state- and action-space environment that we discuss in this book. This environment is challenging for a number of reasons: first, 64 states is the largest number of states we’ve worked with, but more importantly having a single non-zero reward makes this environment particularly challenging. What that really means is agents will only know they’ve done it right once they hit the terminal state for the first time. Remember, this is randomly! After they find the non-zero reward transition, agents such as SARSA and Q-learning (not the lambda versions, but the vanilla ones) will only update the value of the state from which the agent transitioned to the GOAL state. That’s a one-step back from the reward. Then, for that value function to be propagated back one more step, guess what, the agent needs to randomly hit that second-to-final state. But, that’s for the non-lambda versions. With SARSA(λ) and Q(λ), the propagation of values depends on the value of lambda. For all the experiments in this chapter, I use a lambda of 0.5, which more or less tells the agent to propagate the values half the trajectory (also depending on the type of traces being used, but as a ballpark). Surprisingly enough, the only change we make to these agents is the number of episodes we let them interact with the environments. While in the SWS environment we allow the agent to interact for only 3,000 episodes, and in the FL environment we let the agent gather experience for 10,000 episodes; in FL8×8 we let these agents gather 30,000 episodes. This means that alpha now decays from an initial value of 0.5 to a minimum value of 0.01 after 50% of the total episodes, which is now 15,000 episodes, and epsilon decays from an initial value of 1.0 to a minimum value of 0.1 after 90% of the total episodes, which is now 27,000 episodes. |

|   | Tally it Up On-policy methods no longer keep up, off-policy with traces and model-based do |
| --- | --- |
|  |  |

|   | Tally it Up Some model-based methods show large error spikes to be aware of |
| --- | --- |
|  |  |

## Summary

In this chapter, you learned about making RL more effective and efficient. By effective, I mean that agents presented in this chapter are capable of solving the environment in the limited number of episodes allowed for interaction. Other agents, such as vanilla SARSA, or Q-learning, or even Monte Carlo control, would have trouble solving these challenges in the limited number of steps; at least, for sure, they’d have trouble solving the FL8x8 environment in only 30,000 episodes. That’s what effectiveness means to me in this chapter; agents are successful in producing the desired results.

We also explored more efficient algorithms. And by efficient here, I mean data-efficient; I mean that the agents we introduced in this chapter can do more with the same data than other agents. SARSA(*λ*) and Q(*λ*), for instance, can propagate rewards to value-function estimates much quicker than their vanilla counterparts, SARSA and Q-learning. By adjusting the *λ* hyperparameter, you can even assign credit to all states visited in an episode. A value of 1 for *λ* is not always the best, but at least you have the option when using SARSA(*λ*) and Q(*λ*).

You also learned about model-based RL methods, such as Dyna-Q and trajectory sampling. These methods are sample efficient in a different way. They use samples to learn a model of the environment; if your agent lands 100% of 1M samples on state *s'* when taking action *a*, in state *s*, why not use that information to improve value functions and policies? Advanced model-based deep reinforcement learning methods are often used in environments in which gathering experience samples is costly: domains such as robotic, or problems in which you don’t have a high-speed simulation, or where hardware requires large financial resources.

For the rest of the book, we’re moving on to discuss the subtleties that arise when using non-linear function approximation with reinforcement learning. Everything that you’ve learned so far still applies. The only difference is that instead of using vectors and matrices for holding value functions and policies, now we move into the world of supervised learning and function approximation. Remember, in DRL, agents learn from feedback that’s simultaneously sequential (as opposed to one-shot), evaluative (as opposed to supervised), and sampled (as opposed to exhaustive). We haven’t touched the “sampled” part yet; agents have always been able to visit all states or state-action pairs, but starting with the next chapter, we concentrate on problems that cannot be exhaustively sampled.

By now, you

- Know how to develop RL agents that are more effective at reaching their goals
- Know how to make RL agents that are more sample efficient
- Know how to deal with feedback that is simultaneously sequential and evaluative

|   | Tweetable Feat Work on your own and share your findings |
| --- | --- |
|  | Here are several ideas on how to take what you’ve learned to the next level. If you’d like, share your results with the rest of the world and make sure to check out what others have done, too. It’s a win-win situation, and hopefully, you'll take advantage of it. <br>      <br>      **#gdrl_ch07_tf01:** I only test on the frozen lake 8 × 8 environment the algorithms presented in this chapter, but are you curious about how the algorithms in the previous chapter compare? Well, do that! Go to the book’s Notebooks and copy the algorithms from the previous chapter into this chapter’s Notebook, and then run, and collect information to compare all the algorithms. <br>      **#gdrl_ch07_tf02:** There are many more advanced algorithms for the tabular case. Compile a list of interesting algorithms and share the list with the world. <br>      **#gdrl_ch07_tf03:** Now, implement one algorithm from your list and implement another algorithm from someone else’s list. If you’re the first person posting to this hashtag, then implement two of the algorithms on your list. <br>      **#gdrl_ch07_tf04:** There’s a fundamental algorithm called prioritized sweeping. Can you investigate this algorithm, and tell us more about it? Make sure you share your implementation, add it to this chapter’s Notebook, and compare it with the other algorithms in this chapter. <br>      **#gdrl_ch07_tf05:** Create and environment like Frozen Lake 8×8, but much more complex, something like frozen lake 16 × 16, perhaps? Now test all the algorithms, and see how they perform. Are there any of the algorithms in this chapter that do considerably better than other algorithms? <br>      **#gdrl_ch07_tf06:** In every chapter, I’m using the final hashtag as a catchall hashtag. Feel free to use this one to discuss anything else that you worked on relevant to this chapter. There’s no more exciting homework than that which you create for yourself. Make sure to share what you set yourself to investigate and your results. <br>      Write a tweet with your findings, tag me @mimoralea (I’ll retweet), and use the particular hashtag from the list to help interested folks find your results. There are no right or wrong results; you share your findings and check others’ findings. Take advantage of this to socialize, contribute, and get yourself out there! We’re waiting for you! Here’s a tweet example: “Hey, @mimoralea. I created a blog post with a list of resources to study deep reinforcement learning. Check it out at <link>. #gdrl_ch01_tf01” I’ll make sure to retweet and help others find your work. |
