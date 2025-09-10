# 3 Balancing immediate and long-term goals

### In this chapter

- You will learn about the challenges of learning from sequential feedback and how to properly balance immediate and long-term goals.
- You will develop algorithms that can find the best policies of behavior in sequential decision-making problems modeled with MDPs.
- You will find the optimal policies for all environments for which you built MDPs in the previous chapter.

*In preparing for battle I have always found that plans are useless, but planning is indispensable.*

— Dwight D. Eisenhower
United States Army five-star general and 34th President of the United States

In the last chapter, you built an MDP for the BW, BSW, and FL environments. MDPs are the motors moving RL environments. They define the problem: they describe how the agent interacts with the environment through state and action spaces, the agent’s goal through the reward function, how the environment reacts from the agent’s actions through the transition function, and how time should impact behavior through the discount factor.

In this chapter, you’ll learn about algorithms for solving MDPs. We first discuss the objective of an agent and why simple plans are not sufficient to solve MDPs. We then talk about the two fundamental algorithms for solving MDPs under a technique called *dynamic programming: value iteration* (VI) and *policy iteration* (PI).

You’ll soon notice that these methods in a way “cheat”: they require full access to[](/book/grokking-deep-reinforcement-learning/chapter-3/) the MDP, and they depend on knowing the dynamics of the environment, which is something we can’t always obtain. However, the fundamentals you’ll learn are still useful for learning about more advanced algorithms. In the end, VI and PI are the foundations from which virtually every other RL (and DRL) algorithm originates.

You’ll also notice that when an agent has full access to an MDP, there’s no uncertainty because you can look at the dynamics and rewards and calculate expectations directly. Calculating expectations directly means that there’s no need for exploration; that is, there’s no need to balance exploration and exploitation. There’s no need for interaction, so there’s no need for trial-and-error learning. All of this is because the feedback we’re using for learning in this chapter isn’t evaluative but supervised instead.

Remember, in DRL, agents learn from feedback that’s simultaneously sequential (as opposed to one shot), evaluative (as opposed to supervised), and sampled (as opposed to exhaustive). What I’m doing in this chapter is eliminating the complexity that comes with learning from evaluative and sampled feedback, and studying sequential feedback in isolation. In this chapter, we learn from feedback that’s sequential, supervised, and exhaustive.

## The objective of a decision-making agent

At first, it seems the agent’s goal is to find a sequence of actions that will maximize the return: the sum of rewards (discounted or undiscounted—depending on the value of gamma) during an episode or the entire life of the agent, depending on the task.

Let me introduce a new environment to explain these concepts more concretely.

|   | A Concrete Example The Slippery Walk Five (SWF) environment |
| --- | --- |
|  | The Slippery Walk Five (SWF) is a one-row grid-world environment (a walk), that’s stochastic, similar to the Frozen Lake, and it has only five non-terminal states (seven total if we count the two terminal).  The Slippery Walk Five environment The agent starts in *S, H* is a hole, *G* is the goal and provides a +1 reward. |

|   | Show Me The Math The return *G* |
| --- | --- |
|  |  |

You can think of returns as backward looking—“how much you got” from a past time step; but another way to look at it is as a “reward-to-go”—basically, forward looking. For example, imagine an episode in the SWF environment went this way: State 3 (0 reward), state 4 (0 reward), state 5 (0 reward), state 4 (0 reward), state 5 (0 reward), state 6 (+1 reward). We can shorten it: 3/0, 4/0, 5/0, 4/0, 5/0, 6/1. What’s the return of this trajectory/episode?

Well, if we use discounting the math would work out this way.

![Discounted return in the slippery walk five environment](https://drek4537l1klr.cloudfront.net/morales/Figures/03_02.png)

If we don’t use discounting, well, the return would be 1 for this trajectory and all trajectories that end in the right-most cell, state 6, and 0 for all trajectories that terminate in the left-most cell, state 0.

In the SWF environment, it’s evident that going right is the best thing to do. It may seem, therefore, that all the agent must find is something called a *plan[](/book/grokking-deep-reinforcement-learning/chapter-3/)*—that is, a sequence of actions from the *GOAL* state. But this doesn’t always work.

![A solid plan in the SWF environment](https://drek4537l1klr.cloudfront.net/morales/Figures/03_03.png)

In the FL environment, a plan would look like the following.

![A solid plan in the FL environment](https://drek4537l1klr.cloudfront.net/morales/Figures/03_04.png)

But this isn’t enough! The problem with plans is they don’t account for stochasticity in environments, and both the SWF and FL are stochastic*;* actions taken won’t always work the way we intend. What would happen if, due to the environment’s stochasticity, our agent lands on a cell not covered by our plan?

![A possible hole in our plan](https://drek4537l1klr.cloudfront.net/morales/Figures/03_05.png)

Same happens in the FL environment.

![Plans aren’t enough in stochastic environments](https://drek4537l1klr.cloudfront.net/morales/Figures/03_06.png)

What the agent needs to come up with is called[](/book/grokking-deep-reinforcement-learning/chapter-3/) a *policy[](/book/grokking-deep-reinforcement-learning/chapter-3/)*. Policies are universal plans; policies cover all possible states. We need to plan for every possible state. Policies can be *s*tochastic or deterministic: the policy can return action-probability distributions or single actions for a given state (or observation). For now, we’re working with deterministic policies, which is a lookup table that maps actions to states.

![Optimal policy in the SWF environment](https://drek4537l1klr.cloudfront.net/morales/Figures/03_07.png)

In the SWF[](/book/grokking-deep-reinforcement-learning/chapter-3/)[](/book/grokking-deep-reinforcement-learning/chapter-3/) environment, the optimal policy is always going right, for every single state. Great, but there are still many unanswered questions. For instance, how much reward should I expect from this policy? Because, even though we know how to act optimally, the environment might send our agent backward to the hole even if we always select to go toward the goal. This is why returns aren’t enough. The agent is really looking to maximize the expected return[](/book/grokking-deep-reinforcement-learning/chapter-3/); that means the return taking into account the environment’s stochasticity.

Also, we need a method to automatically find optimal policies, because in the FL example, for instance, it isn’t obvious at all what the optimal policy looks like!

There are a few components that are kept internal to the agent that can help it find optimal behavior: there are policies, there can be multiple policies for a given environment, and in fact, in certain environments, there may be multiple optimal policies. Also, there are value functions to help us keep track of return estimates. There’s a single optimal value function for a given MDP, but there may be multiple value functions in general.

Let’s look at all the components internal to a reinforcement learning agent that allow them to learn and find optimal policies, with examples to make all of this more concrete.

### Policies: Per-state action prescriptions

Given the stochasticity in the Frozen[](/book/grokking-deep-reinforcement-learning/chapter-3/) Lake environment (and most reinforcement learning problems,) the agent needs to find a policy, denoted as *π*. A policy is a function that prescribes actions to take for a given nonterminal state. (Remember, policies can be stochastic: either directly over an action or a probability distribution over actions. We’ll expand on stochastic policies[](/book/grokking-deep-reinforcement-learning/chapter-3/) in later chapters.)

Here’s a sample policy.

![A randomly generated policy](https://drek4537l1klr.cloudfront.net/morales/Figures/03_08.png)

One immediate question that arises when looking at a policy is this: how good is this policy? If we find a way to put a number to policies, we could also ask the question, how much better is this policy compared to another policy?

![How can we compare policies?](https://drek4537l1klr.cloudfront.net/morales/Figures/03_09.png)

### State-value function: What to expect from here?

Something that’d help[](/book/grokking-deep-reinforcement-learning/chapter-3/) us compare policies is to put numbers to states for a given policy. That is, if we’re given a policy and the MDP, we should be able to calculate the expected return starting from every single state (we care mostly about the START state). How can we calculate how valuable being in a state is? For instance, if our agent is in state 14 (to the left of the GOAL), how is that better than being in state 13 (to the left of 14)? And precisely how much better is it? More importantly, under which policy would we have better results, the Go-get-it or the Careful policy?

Let’s give it a quick try with the Go-get-it policy[](/book/grokking-deep-reinforcement-learning/chapter-3/). What is the value of being in state 14 under the Go-get-it policy?

![What’s the value of being in state 14 when running the Go-get-it policy?](https://drek4537l1klr.cloudfront.net/morales/Figures/03_10.png)

Okay, so it isn’t that straightforward to calculate the value of state 14 when following the Go-get-it policy because of the dependence on the values of other states (10 and 14, in this case), which we don’t have either. It’s like the chicken-or-the-egg problem. Let’s keep going.

We defined the return as the sum of rewards the agent obtains from a trajectory. Now, this return can be calculated without paying attention to the policy the agent is following: you sum all of the rewards obtained, and you’re good to go. But, the number we’re looking for now is the expectation of returns (from state 14) if we follow a given policy π. Remember, we’re under stochastic environments, so we must account for all the possible ways the environment can react to our policy! That’s what an expectation gives us.

We now define the value of a state s when following a policy *π*: the value of a state s under policy *π* is the expectation of returns if the agent follows policy *π* starting from state *s*. Calculate this for every state, and you get the state-value function, or V-function or value function. It represents the expected return when following policy *π* from state *s*.

|   | Show Me The Math The state-value function *v* |
| --- | --- |
|  |  |

These equations are fascinating. A bit of a mess given the recursive dependencies, but still interesting. Notice how the value of a state depends recursively on the value of possibly many other states, which values may also depend on others, including the original state!

The recursive relationship between states and successive states will come back in the next section when we look at algorithms that can iteratively solve these equations and obtain the state-value function of any policy in the FL environment (or any other environment, really).

For now, let’s continue exploring other components commonly found in RL agents. We’ll learn how to calculate these values later in this chapter. Note that the state-value function is often referred to as the value function, or even the V-function, or more simply *V**π(s)*. It may be confusing, but you’ll get used to it.

### Action-value function: What should I expect from here if I do this?

Another critical question that we often need to ask isn’t merely about the value of a state but the value of taking action *a* in a state *s*. Differentiating answers to this kind of question will help us decide between actions.

For instance, notice that the Go-get-it policy goes right when in state 14, but the Careful policy goes down. But which action is better? More specifically, which action is better under each policy? That is, what is the value of going down, instead of right, and then following the Go-get-it policy, and what is the value of going right, instead of down, and then following the Careful policy?

By comparing between different actions under the same policy, we can select better actions, and therefore improve our policies. The *action-value function*[](/book/grokking-deep-reinforcement-learning/chapter-3/), also known as *Q-function* or *Qπ**(s,a)*, captures precisely this: the expected return if the agent follows policy *π* after taking action *a* in state *s*.

In fact, when we care about improving policies, which is often referred to as the control problem[](/book/grokking-deep-reinforcement-learning/chapter-3/), we need action-value functions. Think about it: if you don’t have an MDP, how can you decide what action to take merely by knowing the values of all states? V-functions don’t capture the dynamics of the environment. The Q-function, on the other hand, does somewhat capture the dynamics of the environment and allows you to improve policies without the need for MDPs. We expand on this fact in later chapters.

|   | Show Me The Math The action-value function *Q* |
| --- | --- |
|  |  |

### Action-advantage function: How much better if I do that?

Another type of value function is derived from the previous two. The *action-advantage function*[](/book/grokking-deep-reinforcement-learning/chapter-3/), also known as *advantage function*, *A-function*, or *Aπ**(s, a),* is the difference between the action-value function of action *a* in state *s* and the state-value function of state *s* under policy *π*.

|   | Show Me The Math The action-advantage function *A* |
| --- | --- |
|  |  |

The advantage function describes how much better it is to take action *a* instead of following policy *π*: the advantage of choosing action *a* over the default action.

Look at the different value functions for a (dumb) policy in the SWF environment. Remember, these values depend on the policy. In other words, the *Q*π*(s, a)* assumes you’ll follow policy *π* (always left in the following example) and right after taking action *a* in state *s*.

![State-value, action-value, and action-advantage functions](https://drek4537l1klr.cloudfront.net/morales/Figures/03_11.png)

### Optimality

Policies, state-value functions, action-value functions, and action-advantage functions are the components we use to describe, evaluate, and improve behaviors. We call it *optimality[](/book/grokking-deep-reinforcement-learning/chapter-3/)* when these components are the best they can be.

An *optimal policy*[](/book/grokking-deep-reinforcement-learning/chapter-3/) is a policy that for every state can obtain expected returns greater than or equal to any other policy. An optimal state-value function[](/book/grokking-deep-reinforcement-learning/chapter-3/)[](/book/grokking-deep-reinforcement-learning/chapter-3/) is a state-value function with the maximum value across all policies for all states. Likewise, an optimal action-value function[](/book/grokking-deep-reinforcement-learning/chapter-3/)[](/book/grokking-deep-reinforcement-learning/chapter-3/) is an action-value function with the maximum value across all policies for all state-action pairs. The optimal action-advantage function[](/book/grokking-deep-reinforcement-learning/chapter-3/)[](/book/grokking-deep-reinforcement-learning/chapter-3/) follows a similar pattern, but notice an optimal advantage function would be equal to or less than zero for all state-action pairs, since no action could have any advantage from the optimal state-value function.

Also, notice that although there could be more than one optimal policy for a given MDP, there can only be one optimal state-value function, optimal action-value function, and optimal action-advantage function.

You may also notice that if you had the optimal V-function, you could use the MDP to do a one-step search for the optimal Q-function and then use this to build the optimal policy. On the other hand, if you had the optimal Q-function, you don’t need the MDP[](/book/grokking-deep-reinforcement-learning/chapter-3/) at all. You could use the optimal Q-function to find the optimal V-function by merely taking the maximum over the actions. And you could obtain the optimal policy using the optimal Q-function by taking the argmax over the actions.

|   | Show Me The Math The Bellman optimality equations |
| --- | --- |
|  |  |

## Planning optimal sequences of actions

We have state-value functions to keep[](/book/grokking-deep-reinforcement-learning/chapter-3/)[](/book/grokking-deep-reinforcement-learning/chapter-3/) track of the values of states, action-value functions to keep track of the values of state-action pairs, and action-advantage functions to show the “advantage” of taking specific actions. We have equations for all of these to evaluate current policies, that is, to go from policies to value functions, and to calculate and find optimal value functions and, therefore, optimal policies.

Now that we’ve discussed the reinforcement learning problem formulation, and we’ve defined the objective we are after, we can start exploring methods for finding this objective. Iteratively computing the equations presented in the previous section is one of the most common ways to solve a reinforcement learning problem and obtain optimal policies when the dynamics of the environment, the MDPs, are known. Let’s look at the methods.

### Policy evaluation: Rating policies

We talked about comparing policies in the previous section. We established that policy *π* is better than or equal to policy *π*' if the expected return is better than or equal to *π*' for all states. Before we can use this definition, however, we must devise an algorithm for evaluating an arbitrary policy. Such an algorithm is known as an *iterative policy evaluation* or just *policy evaluation*.

The policy-evaluation algorithm consists of calculating the V-function for a given policy by sweeping through the state space and iteratively improving estimates. We refer to the type of algorithm that takes in a policy and outputs a value function as an algorithm that solves the **prediction problem**[](/book/grokking-deep-reinforcement-learning/chapter-3/), which is calculating the values of a predetermined policy.

|   | Show Me The Math The policy-evaluation equation |
| --- | --- |
|  |  |

Using this equation, we can iteratively approximate the true V-function of an arbitrary policy. The iterative policy-evaluation algorithm is guaranteed to converge to the value function of the policy if given enough iterations, more concretely as we approach infinity. In practice, however, we use a small threshold to check for changes in the value function we’re approximating. Once the changes in the value function are less than this threshold, we stop.

Let’s see how this algorithm works in the SWF environment, for the always-left policy[](/book/grokking-deep-reinforcement-learning/chapter-3/).

![Initial calculations of policy evaluation](https://drek4537l1klr.cloudfront.net/morales/Figures/03_12.png)

You then calculate the values for all states 0–6, and when done, move to the next iteration. Notice that to calculate *V*2*π(s)* you’d have to use the estimates obtained in the previous iteration, *V*1*π(s)*. This technique of calculating an estimate from an estimate is referred to as *bootstrapping*[](/book/grokking-deep-reinforcement-learning/chapter-3/), and it’s a widely used technique in RL (including DRL).

Also, it’s important to notice that the *k*’s here are iterations across estimates, but they’re not interactions with the environment. These aren’t episodes that the agent is out and about selecting actions and observing the environment. These aren’t time steps either. Instead, these are the iterations of the iterative policy-evaluation algorithm. Do a couple more of these estimates. The following table shows you the results you should get.

| k | Vπ(0) | Vπ(1) | Vπ(2) | Vπ(3) | Vπ(4) | Vπ(5) | Vπ(6) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 1 | 0 | 0 | 0 | 0 | 0 | 0.1667 | 0 |
| 2 | 0 | 0 | 0 | 0 | 0.0278 | 0.2222 | 0 |
| 3 | 0 | 0 | 0 | 0.0046 | 0.0463 | 0.2546 | 0 |
| 4 | 0 | 0 | 0.0008 | 0.0093 | 0.0602 | 0.2747 | 0 |
| 5 | 0 | 0.0001 | 0.0018 | 0.0135 | 0.0705 | 0.2883 | 0 |
| 6 | 0 | 0.0003 | 0.0029 | 0.0171 | 0.0783 | 0.2980 | 0 |
| 7 | 0 | 0.0006 | 0.0040 | 0.0202 | 0.0843 | 0.3052 | 0 |
| 8 | 0 | 0.0009 | 0.0050 | 0.0228 | 0.0891 | 0.3106 | 0 |
| 9 | 0 | 0.0011 | 0.0059 | 0.0249 | 0.0929 | 0.3147 | 0 |
| 10 | 0 | 0.0014 | 0.0067 | 0.0267 | 0.0959 | 0.318 | 0 |
| ... | ... | ... | ... | ... | ... | ... | ... |
| 104 | 0 | 0.0027 | 0.011 | 0.0357 | 0.1099 | 0.3324 | 0 |

What are several of the things the resulting state-value function tells us?

Well, to begin with, we can say we get a return of 0.0357 in expectation when starting an episode in this environment and following the always-left policy[](/book/grokking-deep-reinforcement-learning/chapter-3/). Pretty low.

We can also say, that even when we find ourselves in state 1 (the leftmost non-terminal state), we still have a chance, albeit less than one percent, to end up in the GOAL cell (state 6). To be exact, we have a 0.27% chance of ending up in the GOAL state when we’re in state 1. And we select left all the time! Pretty interesting.

Interestingly also, due to the stochasticity of this environment, we have a 3.57% chance of reaching the GOAL cell (remember this environment has 50% action success, 33.33% no effects, and 16.66% backward). Again, this is when under an always-left policy. Still, the Left action could send us right, then right and right again, or left, right, right, right, right, and so on.

Think about how the probabilities of trajectories combine. Also, pay attention to the iterations and how the values propagate backward from the reward (transition from state 5 to state 6) one step at a time. This backward propagation of the values is a common characteristic among RL algorithms and comes up again several times.

|   | I Speak Python The policy-evaluation algorithm |
| --- | --- |
|  |  |

Let’s now run policy evaluation in the randomly generated policy presented earlier for the FL[](/book/grokking-deep-reinforcement-learning/chapter-3/) environment.

![Recall the randomly generated policy](https://drek4537l1klr.cloudfront.net/morales/Figures/03_13.png)

The following shows the progress policy evaluation makes on accurately estimating the state-value function of the randomly generated policy after only eight iterations.

![Policy evaluation on the randomly generated policy for the FL environment](https://drek4537l1klr.cloudfront.net/morales/Figures/03_14.png)

![State-value function of the randomly generated policy](https://drek4537l1klr.cloudfront.net/morales/Figures/03_15.png)

This final state-value function is the state-value function for this policy. Note that even though this is still an estimate, because we’re in a discrete state and action spaces, we can assume this to be the actual value function when using gamma of 0.99.

In case you’re wondering about the state-value functions of the two policies presented earlier, here are the results.

![Results of policy evolution](https://drek4537l1klr.cloudfront.net/morales/Figures/03_16.png)

It seems being a Go-get-it policy doesn’t pay well in the FL environment! Fascinating results, right? But a question arises: Are there any better policies for this environment?

### Policy improvement: Using ratings to get better

The motivation[](/book/grokking-deep-reinforcement-learning/chapter-3/)[](/book/grokking-deep-reinforcement-learning/chapter-3/) is clear now. You have a way of evaluating any policy. This already gives you some freedom: you can evaluate many policies and rank them by the state-value function of the START state. After all, that number tells you the expected cumulative reward the policy in question will obtain if you run many episodes. Cool, right?

No! Makes no sense. Why would you randomly generate a bunch of policies and evaluate them all? First, that’s a total waste of computing resources, but more importantly, it gives you no guarantee that you’re finding better and better policies. There has to be a better way.

The key to unlocking this problem is the action-value function[](/book/grokking-deep-reinforcement-learning/chapter-3/), the Q-function. Using the V-function and the MDP, you get an estimate of the Q-function. The Q-function will give you a glimpse of the values of all actions for all states, and these values, in turn, can hint at how to improve policies. Take a look at the Q-function of the Careful policy and ways we can improve this policy:

![How can the Q-function help us improve policies?](https://drek4537l1klr.cloudfront.net/morales/Figures/03_17.png)

Notice how if we act greedily with respect to the Q-function of the policy, we obtain a new policy: Careful+. Is this policy any better? Well, policy evaluation can tell us! Let’s find out!

![State-value function of the Careful policy](https://drek4537l1klr.cloudfront.net/morales/Figures/03_18.png)

The new policy is better than the original policy. This is great! We used the state-value function of the original policy and the MDP to calculate its action-value function. Then, acting greedily with respect to the action-value function gave us an improved policy. This is what the *policy-improvement* algorithm does: it calculates an action-value function using the state-value function and the MDP, and it returns a *greedy* policy[](/book/grokking-deep-reinforcement-learning/chapter-3/) with respect to the action-value function of the original policy. Let that sink in, it’s pretty important.

|   | Show Me The Math The policy-improvement equation |
| --- | --- |
|  |  |

This is how the policy-improvement algorithm looks in Python.

|   | I Speak Python The policy-improvement algorithm |
| --- | --- |
|  |  |

The natural next questions are these: Is there a better policy than this one? Can we do any better than *again*? Maybe! But, there’s only one way to find out. Let’s give it a try!

![Can we improve over the Careful+ policy?](https://drek4537l1klr.cloudfront.net/morales/Figures/03_19.png)

I ran policy evaluation on the Careful+ policy, and then policy improvement. The Q-functions of Careful and Careful+ are different, but the greedy policies over the Q-functions are identical. In other words, there’s no improvement this time.

No improvement occurs because the Careful+ policy is an optimal policy of the FL environment (with gamma 0.99). We only needed one improvement over the Careful policy because this policy was good to begin with.

Now, even if we start with an adversarial policy designed to perform poorly, alternating over policy evaluation and improvement would still end up with an optimal policy. Want proof? Let’s do it! Let’s make up an adversarial policy for FL environment and see what happens.

![Adversarial policy for the FL environment](https://drek4537l1klr.cloudfront.net/morales/Figures/03_20.png)

### Policy iteration: Improving upon improved behaviors

The plan with this adversarial policy is to alternate between policy evaluation and policy improvement until the policy coming out of the policy-improvement phase no longer yields a different policy. The fact is that, if instead of starting with an adversarial policy, we start with a randomly generated policy, this is what an algorithm called *policy iteration*[](/book/grokking-deep-reinforcement-learning/chapter-3/)[](/book/grokking-deep-reinforcement-learning/chapter-3/) does.

|   | I Speak Python The policy-iteration algorithm |
| --- | --- |
|  |  |

Great! But, let’s first try it starting with the adversarial policy and see what happens.

![Improving upon the adversarial policy 1/2](https://drek4537l1klr.cloudfront.net/morales/Figures/03_21.png)

![Improving upon the adversarial policy 2/2](https://drek4537l1klr.cloudfront.net/morales/Figures/03_22.png)

As mentioned, alternating policy evaluating and policy improvement yields an optimal policy and state-value function regardless of the policy you start with. Now, a few points I’d like to make about this sentence.

Notice how I use “*an* optimal policy,” but also use “*the* optimal state-value function.” This is not a coincidence or a poor choice of words; this is, in fact, a property that I’d like to highlight again. An MDP can have more than one optimal policy, but it can only have a single optimal state-value function[](/book/grokking-deep-reinforcement-learning/chapter-3/)[](/book/grokking-deep-reinforcement-learning/chapter-3/). It’s not too hard to wrap your head around that.

State-value functions are collections of numbers. Numbers can have infinitesimal accuracy, because they’re numbers. There will be only one optimal state-value function (the collection with the highest numbers for all states). However, a state-value function may have actions that are equally valued for a given state; this includes the optimal state-value function. In this case, there could be multiple optimal policies, each optimal policy selecting a different, but equally valued, action. Take a look: the FL environment is a great example of this.

![The FL environment has multiple optimal policies](https://drek4537l1klr.cloudfront.net/morales/Figures/03_23.png)

By the way, it’s not shown here, but all the actions in a terminal state have the same value, zero, and therefore a similar issue that I’m highlighting in state 6.

As a final note, I want to highlight that policy iteration is guaranteed to converge to the exact optimal policy: the mathematical proof shows it will not get stuck in local optima. However, as a practical consideration, there’s one thing to be careful about. If the action-value function has a tie (for example, right/left in state 6), we must make sure not to break ties randomly. Otherwise, policy improvement could keep returning different policies, even without any real improvement. With that out of the way, let’s look at another essential algorithm for finding optimal state-value functions and optimal policies.

### Value iteration: Improving behaviors early

You probably notice[](/book/grokking-deep-reinforcement-learning/chapter-3/)[](/book/grokking-deep-reinforcement-learning/chapter-3/)[](/book/grokking-deep-reinforcement-learning/chapter-3/) the way policy evaluation works: values propagate consistently on each iteration, but slowly. Take a look.

![Policy evaluation on the always-left policy on the SWF environment](https://drek4537l1klr.cloudfront.net/morales/Figures/03_24.png)

The image shows a single state-space sweep of policy evaluation followed by an estimation of the Q-function. We do this by using the truncated estimate of the V-function and the MDP, on each iteration. By doing so, we can more easily see that even after the first iteration, a greedy policy over the early Q-function estimates would be an improvement. Look at the Q-values for state 5 in the first iteration; changing the action to point towards the GOAL state is obviously already better.

In other words, even if we truncated policy evaluation after a single iteration, we could still improve upon the initial policy by taking the greedy policy of the Q-function estimation after a single state-space sweep of policy evaluation. This algorithm is another fundamental algorithm in RL: it's called *value iteration* (VI).

VI can be thought of “greedily greedifying policies,” because we calculate the greedy policy as soon as we can, greedily. VI doesn’t wait until we have an accurate estimate of the policy before it improves it, but instead, VI truncates the policy-evaluation phase after a single state sweep. Take a look at what I mean by “greedily greedifying policies.”

![Greedily greedifying the always-left policy of the SFW environment](https://drek4537l1klr.cloudfront.net/morales/Figures/03_25.png)

If we start with a randomly generated policy, instead of this adversarial policy always-left for the SWF environment, VI would still converge to the optimal state-value function. VI is a straightforward algorithm that can be expressed in a single equation.

|   | Show Me The Math The value-iteration equation |
| --- | --- |
|  |  |

Notice that in practice, in VI, we don’t have to deal with policies at all. VI doesn’t have any separate evaluation phase that runs to convergence. While the goal of VI is the same as the goal of PI—to find the optimal policy for a given MDP—VI happens to do this through the value functions; thus the name value iteration.

Again, we only have to keep track of a V-function and a Q-function (depending on implementation). Remember that to get the greedy policy over a Q-function, we take the arguments of the maxima (argmax) over the actions of that Q-function. Instead of improving the policy by taking the argmax to get a better policy and then evaluating this improved policy to obtain a value function again, we directly calculate the maximum (max, instead of argmax) value across the actions to be used for the next sweep over the states.

Only at the end of the VI algorithm, after the Q-function converges to the optimal values, do we extract the optimal policy by taking the argmax over the actions of the Q-function, as before. You’ll see it more clearly in the code snippet on the next page.

One important thing to highlight is that whereas VI and PI are two different algorithms, in a more general view, they are two instances of *generalized policy iteration* (GPI[](/book/grokking-deep-reinforcement-learning/chapter-3/)[](/book/grokking-deep-reinforcement-learning/chapter-3/)). GPI is a general idea in RL in which policies are improved using their value function estimates, and value function estimates are improved toward the actual value function for the current policy. Whether you wait for the perfect estimates or not is just a detail.

|   | I Speak Python The value-iteration algorithm |
| --- | --- |
|  |  |

## Summary

The objective of a reinforcement learning agent is to maximize the expected return, which is the total reward over multiple episodes. For this, agents must use policies, which can be thought of as universal plans. Policies prescribe actions for states. They can be deterministic, meaning they return single actions, or stochastic, meaning they return probability distributions. To obtain policies, agents usually keep track of several summary values. The main ones are state-value, action-value, and action-advantage functions.

State-value functions summarize the expected return from a state. They indicate how much reward the agent will obtain from a state until the end of an episode in expectation. Action-value functions summarize the expected return from a state-action pair. This type of value function tells the expected reward-to-go after an agent selects a specific action in a given state. Action-value functions allow the agent to compare across actions and therefore solve the control problem. Action-advantage functions show the agent how much better than the default it can do if it were to opt for a specific state-action pair. All of these value functions are mapped to specific policies, perhaps an optimal policy. They depend on following what the policies prescribe until the end of the episode.

Policy evaluation is a method for estimating a value function from a policy and an MDP. Policy improvement is a method for extracting a greedy policy from a value function and an MDP. Policy iteration consists of alternating between policy-evaluation and policy improvement to obtain an optimal policy from an MDP. The policy evaluation phase may run for several iterations before it accurately estimates the value function for the given policy. In policy iteration, we wait until policy evaluation finds this accurate estimate. An alternative method, called value iteration, truncates the policy-evaluation phase and exits it, entering the policy-improvement phase early.

The more general view of these methods is generalized policy iteration, which describes the interaction of two processes to optimize policies: one moves value function estimates closer to the real value function of the current policy, another improves the current policy using its value function estimates, getting progressively better and better policies as this cycle continues.

By now, you

- Know the objective of a reinforcement learning agent and the different statistics it may hold at any given time
- Understand methods for estimating value functions from policies and methods for improving policies from value functions
- Can find optimal policies in sequential decision-making problems modeled by MDPs

|   | Tweetable Feat Work on your own and share your findings |
| --- | --- |
|  | Here are several ideas on how to take what you have learned to the next level. If you’d like, share your results with the rest of the world and check out what others have done, too. It’s a win-win situation, and hopefully, you’ll take advantage of it. <br>      <br>      **#gdrl_ch03_tf01:** Many of the grid-world environments out there have MDPs available that can be solved with the policy iteration and value iteration functions presented in this chapter. Surprised? Use “env.unwrapped.P” and pass that variable to the functions in this chapter. More explicitly, do that for a few environments that we did not used in this chapter, environments created by others, or perhaps the environment you created yourself in the last chapter. <br>      **#gdrl_ch03_tf02:** The discount factor, gamma, was introduced in the previous chapter as part of the MDP definition. However, we didn’t go into the details of this crucial variable. How about you run policy iteration and value iteration with several different values of gamma, capture the sum of rewards agents obtain with each, as well as the optimal policies. How do these compare? Can you fi nd anything interesting that can help others better understand the role of the discount factor? <br>      **#gdrl_ch03_tf03:** Policy iteration and value iteration both do the same thing: they take an MDP definition and solve for the optimal value function and optimal policies. However, an interesting question is, how do these compare? Can you think of an MDP that’s challenging for policy iteration and easy for value iteration to solve or the other way around? Create such an environment as a Python package, and share it with the world. What did you fi nd that others may want to know? How do VI and PI compare? <br>      **#gdrl_ch04_tf04:** In every chapter, I’m using the final hashtag as a catchall hashtag. Feel free to use this one to discuss anything else that you worked on relevant to this chapter. There’s no more exciting homework than that which you create for yourself. Make sure to share what you set yourself to investigate and your results. <br>      Write a tweet with your findings, tag me @mimoralea (I’ll retweet), and use the particular hashtag from this list to help interested folks find your results. There are no right or wrong results; you share your findings and check others’ findings. Take advantage of this to socialize, contribute, and get yourself out there! We’re waiting for you! Here is a tweet example: “Hey, @mimoralea. I created a blog post with a list of resources to study deep reinforcement learning. Check it out at <link>. #gdrl_ch01_tf01” I’ll make sure to retweet and help others find your work. |
