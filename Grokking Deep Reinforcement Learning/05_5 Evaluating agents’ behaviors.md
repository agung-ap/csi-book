# 5 Evaluating agents’ behaviors

### In this chapter

- You will learn about estimating policies when learning from feedback that is simultaneously sequential and evaluative.
- You will develop algorithms for evaluating policies in reinforcement learning environments when the transition and reward functions are unknown.
- You will write code for estimating the value of policies in environments in which the full reinforcement learning problem is on display.

*I conceive that the great part of the miseries of mankind are brought upon them by false estimates they have made of the value of things.*

— Benjamin Franklin
Founding Father of the United States an author, politician, inventor, and a civic activist

You know how challenging it is to balance immediate and long-term goals. You probably experience this multiple times a day: should you watch movies tonight or keep reading this book? One has an immediate satisfaction to it; you watch the movie, and you go from poverty to riches, from loneliness to love, from overweight to fit, and so on, in about two hours and while eating popcorn. Reading this book, on the other hand, won’t really give you much tonight, but maybe, and only maybe, will provide much higher satisfaction in the long term.

And that’s a perfect lead-in to precisely the other issue we discussed. How much more satisfaction in the long term, exactly, you may ask. Can we tell? Is there a way to find out? Well, that’s the beauty of life: I don’t know, you don’t know, and we won’t know unless we try it out, unless we utilization.

However, in the previous chapter, we studied this challenge in isolation from the sequential aspect of RL. Basically, you assume your actions have no long-term effect, and your only concern is to find the best thing to do for the current situation. For instance, your concern may be selecting a good movie, or a good book, but without thinking how the movie or the book will impact the rest of your life. Here, your actions don’t have a “compounding effect.”

Now, in this chapter, we look at agents that learn from feedback that’s simultaneously sequential and evaluative; agents need to simultaneously balance immediate and long-term goals, and balance information gathering and utilization. Back to our “movie or book” example, where you need to decide what to do today knowing each decision you make builds up, accumulates, and compounds in the long term. Since you are a near-optimal decision maker under uncertainty, just as most humans, will you watch a movie or keep on reading? Hint!

You’re smart.... In this chapter, we’ll study agents that can learn to estimate the value of policies, similar to the policy-evaluation method, but this time without the MDP. This is often called the prediction problem because we’re estimating value functions, and these are defined as the expectation of future discounted rewards, that is, they contain values that depend on the future, so we’re learning to predict the future in a sense. Next chapter, we’ll look at optimizing policies without MDPs, which is called the control problem because we attempt to improve agents’ behaviors. As you’ll see in this book, these two are equally essential aspects of RL. In machine learning, the saying goes, “The model is only as good as the data.” In RL, I say, “The policy is only as good as the estimates,” or, detailed, “The improvement of a policy is only as good as the accuracy and precision of its estimates.”

Once again, in DRL, agents learn from feedback that’s simultaneously sequential (as opposed to one-shot), evaluative (as opposed to supervised) and sampled (as opposed to exhaustive). In this chapter, we’re looking at agents that learn from feedback that’s simultaneously sequential and evaluative. We’re temporarily shelving the “sampled” part, but we’ll open those gates in chapter 8, and there will be fun galore. I promise.

## Learning to estimate the value of policies

As I mentioned[](/book/grokking-deep-reinforcement-learning/chapter-5/) before, this chapter is about learning to estimate the value of existing policies. When I was first introduced to this prediction problem, I didn’t get the motivation. To me, if you want to estimate the value of a policy, the straightforward way of doing it is running the policy repeatedly and averaging what you get.

And, that’s definitely a valid approach, and perhaps the most natural. What I didn’t realize back then, however, is that there are many other approaches to estimating value functions. Each of these approaches has advantages and disadvantages. Many of the methods can be seen as an exact opposite alternative, but there’s also a middle ground that creates a full spectrum of algorithms.

In this chapter, we’ll explore a variety of these approaches and dig into their pros and cons, showing you how they relate.

| ŘŁ | With An RL Accent Reward vs. return vs. value function |
| --- | --- |
|  | **Reward**: Refers to the one-step reward signal the agent gets: the agent observes a state, selects an action, and receives a reward signal. The reward signal is the core of RL, but it is *not* what the agent is trying to maximize! Again, the agent isn’t trying to maximize the reward! Realize that while your agent maximizes the one-step reward, in the long-term, it’s getting less than it could. **Return**: Refers to the total discounted rewards. Returns are calculated from any state and usually go until the end of the episode. That is, when a terminal state is reached, the calculation stops. Returns are often referred to as total reward, cumulative reward, sum of rewards, and are commonly discounted: total discounted reward, cumulative discounted reward, sum of discounted reward. But, it’s basically the same: a return tells you how much reward your agent *obtained* in an episode. As you can see, returns are better indicators of performance because they contain a long-term sequence, a single-episode history of rewards. But the return isn’t what an agent tries to maximize, either! An agent who attempts to obtain the highest possible return may find a policy that takes it through a noisy path; sometimes, this path will provide a high return, but perhaps most of the time a low one. **Value function**: Refers to the expectation of returns. Sure, we want high returns, but high in *expectation (on average)*. If the agent is in a noisy environment, or if the agent is using a stochastic policy, it’s all fine. The agent is trying to maximize the expected total discounted reward, after all: value functions. |

|   | Miguel's Analogy Rewards, returns, value functions, and life |
| --- | --- |
|  | How do you approach life? Do you select actions that are the best for you, or are you one of those kind folks who prioritize others before themselves? There’s no shame either way! Being selfish, to me, is an excellent reward signal. It takes you places. It drives you around. Early on in life, going after the immediate reward can be a pretty solid strategy. Many people judge others for being “too selfish,” but to me, that’s the way to get going. Go on and do what you want, what you dream of, what gives you satisfaction, go after the rewards! You’ll look selfish and greedy. But you shouldn’t care. As you keep going, you’ll realize that going after the rewards isn’t the best strategy, even for your benefit. You start seeing a bigger picture. If you overeat candy, your tummy hurts; if you spend all of your money on online shopping, you can go broke. Eventually, you start looking at the returns. You start understanding that there’s more to your selfish and greedy motives. You drop the greedy side of you because it harms you in the long run, and now you can see that. But you stay selfish, you still only think in terms of rewards, just now “total” rewards, returns. No shame about that, either! At one point, you’ll realize that the world moves without you, that the world has many more moving parts than you initially thought, that the world has underlying dynamics that are difficult to comprehend. You now know that “what goes around comes around,” one way or another, one day or another, but it does. You step back once again; now instead of the going after rewards or returns, you go after value functions. You wise up! You learn that the more you help others learn, the more you learn. Not sure why, but it works. The more you love your significant other, the more they love you, crazy! The more you don’t spend (save), the more you can spend. How strange! Notice, you’re still selfish! But you become aware of the complex underlying dynamics of the world and can understand that the best for yourself is to better others—a perfect win-win situation. I’d like the differences between rewards, returns, and value functions to be ingrained in you, so hopefully this should get you thinking for a bit. Follow the rewards! Then, the returns! Then, the value functions. |

|   | A Concrete Example The random walk environment |
| --- | --- |
|  | The primary environment we’ll use through this chapter is called the *random walk (RW)*. This is a walk, single-row grid-world environment, with five non-terminal states. But it’s peculiar, so I want to explain it in two ways. On the one hand, you can think of the RW as an environment in which the probability of going left when taking the Left action is equal to the probability of going right when taking the Left action, and the probability of going right when taking the Right action is equal to the probability of going left when taking the Right action. In other words, the agent has no control of where it goes! The agent will go left with 50% and right with 50% regardless of the action it takes. It’s a random walk, after all. Crazy!  Random walk environment MDP But to me, that was an unsatisfactory explanation of the RW, maybe because I like the idea of agents controlling something. What’s the point of studying RL (a framework for learning optimal control) in an environment in which there’s no possible control!? Therefore, you can think of the RW as an environment with a deterministic transition function (meaning that if the agent chooses left, the agent moves left, and it moves right if it picks right—as expected). But pretend the agent wants to evaluate a stochastic policy that selects actions uniformly at random. That’s half the time it chooses left, and the other half, right. Either way, the concept is the same: we have a five non-terminal state walk in which the agent moves left and right uniformly at random. The goal is to estimate the expected total discounted reward the agent can obtain given these circumstances. |

### First-visit Monte Carlo: Improving estimates after each episode

Alright! The goal is to estimate the value of a policy, that is, to learn how much total reward to expect from a policy. More properly, the goal is to estimate the state-value function *v*π*(s)* of a policy *π*. The most straightforward approach that comes to mind is one I already mentioned: it’s to run several episodes with this policy collecting hundreds of trajectories, and then calculate averages for every state, just as we did in the bandit environments. This method of estimating value functions is called *Monte Carlo prediction* (MC[](/book/grokking-deep-reinforcement-learning/chapter-5/)).

MC is easy to implement. The agent will first interact with the environment using policy *π* until the agent hits a terminal state *S**t*. The collection of state *S**t*, action *A**t*, reward *R**t*+1, and next state *S**t*+1 is called an *experience tuple*[](/book/grokking-deep-reinforcement-learning/chapter-5/). A sequence of experiences is called a *trajectory*[](/book/grokking-deep-reinforcement-learning/chapter-5/). The first thing you need to do is have your agent generate a trajectory.

Once you have a trajectory, you calculate the returns *G*t:T for every state *S*t encountered. For instance, for state *S**t*, you go from time step *t* forward, adding up and discounting the rewards received along the way: *R**t*+1*, R*t+2*, R*t+3*, ... , R**T*, until the end of the trajectory at time step *T*. Then, you repeat that process for state *S**t*+1, adding up the discounted reward from time step *t+1* until you again reach *T*; then for *S*t+2 and so on for all states except *S**T*, which by definition has a value of 0. *G*t:T will end up using the rewards from time step *t+1*, up to the end of the episode at time step *T*. We discount those rewards with an exponentially decaying discount factor: *γ*0*,* *γ*1*,* *γ*2*, ... ,* *γ*T-1. That means multiplying the corresponding discount factor *γ* by the reward *r*, then adding up the products along the way.

After generating a trajectory and calculating the returns for all states *s*t, you can estimate the state-value function *v*π*(s)* at the end of every episode *e* and final time step *t* by merely averaging the returns obtained from each state *s*. In other words, we’re estimating an expectation with an average. As simple as that.

![Monte Carlo prediction](https://drek4537l1klr.cloudfront.net/morales/Figures/05_02.png)

|   | Show Me The Math Monte Carlo learning |
| --- | --- |
|  |  |

### Every-visit Monte Carlo: A different way of handling state visits

You probably notice that in practice, there are two different ways of implementing an averaging-of-returns algorithm. This is because a single trajectory may contain multiple visits to the same state. In this case, should we calculate the returns following each of those visits independently and then include all of those targets in the averages, or should we only use the first visit to each state?

Both are valid approaches, and they have similar theoretical properties. The more “standard” version is *first-visit MC* (FVMC[](/book/grokking-deep-reinforcement-learning/chapter-5/)[](/book/grokking-deep-reinforcement-learning/chapter-5/)[](/book/grokking-deep-reinforcement-learning/chapter-5/)), and its convergence properties are easy to justify because each trajectory is an independent and identically distributed (IID) sample of *v*π*(s)*, so as we collect infinite samples, the estimates will converge to their true values. *Every-visit MC* (EVMC[](/book/grokking-deep-reinforcement-learning/chapter-5/)[](/book/grokking-deep-reinforcement-learning/chapter-5/)) is slightly different because returns are no longer independent and identically distributed when states are visited multiple times in the same trajectory. But, fortunately for us, EVMC has also been proven to converge given infinite samples.

|   | Boil It Down First- vs. every-visit MC |
| --- | --- |
|  | MC prediction estimates *v**π*(*s*) as the average of returns of *π*. FVMC uses only one return per state per episode: the return following a first visit. EVMC averages the returns following all visits to a state, even if in the same episode. |

| 0001 | A Bit Of History First-visit Monte Carlo prediction |
| --- | --- |
|  | You’ve probably heard the term “Monte Carlo simulations” or “runs” before. Monte Carlo methods, in general, have been around since the 1940s and are a broad class of algorithms that use random sampling for estimation. They are ancient and widespread. However, it was in 1996 that first- and every-visit MC methods were identified in the paper “Reinforcement Learning with Replacing Eligibility Traces,” by Satinder Singh and Richard Sutton. Satinder Singh[](/book/grokking-deep-reinforcement-learning/chapter-5/) and Richard Sutton[](/book/grokking-deep-reinforcement-learning/chapter-5/) each obtained their PhD in Computer Science from the University of Massachusetts Amherst, were advised by Professor Andy Barto, became prominent figures in RL due to their many foundational contributions, and are now Distinguished Research Scientists at Google DeepMind. Rich got his PhD in 1984 and is a professor at the University of Alberta, whereas Satinder got his PhD in 1994 and is a professor at the University of Michigan. |

|   | I Speak Python Exponentially decaying schedule |
| --- | --- |
|  |  |

|   | I Speak Python Generate full trajectories |
| --- | --- |
|  |  |

|   | I Speak Python Monte Carlo prediction 1/2 |
| --- | --- |
|  |  |

|   | I Speak Python Monte Carlo prediction 2/2 |
| --- | --- |
|  |  |

| ŘŁ | With An RL Accent Incremental vs. sequential vs. trial-and-error |
| --- | --- |
|  | **Incremental methods**: Refers to the iterative improvement of the estimates. Dynamic programming is an incremental method: these algorithms iteratively compute the answers. They don’t “interact” with an environment, but they reach the answers through successive iterations, incrementally. Bandits are also incremental: they reach good approximations through successive episodes or trials. Reinforcement learning is incremental, as well. Depending on the specific algorithm, estimates are improved on an either per-episode or per-time-step basis, incrementally. **Sequential methods**: Refers to learning in an environment with more than one non-terminal (and reachable) state. Dynamic programming is a sequential method. Bandits are not sequential, they are one-state one-step MDPs. There’s no long-term consequence for the agent’s actions. Reinforcement learning is certainly sequential. **Trial-and-error methods**: Refers to learning from interaction with the environment. Dynamic programming is not trial-and-error learning. Bandits are trial-and-error learning. Reinforcement learning is trial-and-error learning, too. |

### Temporal-difference learning: Improving estimates after each step

One of the main drawbacks of MC is the fact that the agent has to wait until the end of an episode when it can obtain the actual return *G**t:T* before it can update the state-value function estimate *V**T**(S**t*). On the one hand, MC has pretty solid convergence properties because it updates the value function estimate *V**T**(S**t*) toward the actual return *G**t*:*T*, which is an unbiased estimate of the true state-value function *v**π**(s)*.

However, while the actual returns are pretty accurate estimates, they are also not very precise. Actual returns are also high-variance estimates of the true state-value function *v**π*(*s*). It’s easy to see why: actual returns accumulate many random events in the same trajectory; all actions, all next states, all rewards are random events. The actual return *G**t:T* collects and compounds all of that randomness for multiple time steps, from *t* to *T*. Again, the actual return *G**t:T* is unbiased, but high variance.

Also, due to the high variance of the actual returns *G**t*:*T*, MC can be sample inefficient. All of that randomness becomes noise that can only be alleviated with data, lots of data, lots of trajectories, and actual return samples. One way to diminish the issues of high variance is to, instead of using the actual return *G**t*:*T*, estimate a return. Stop for a second and think about it before proceeding: your agent is already calculating the state-value function estimate *V(s)* of the true state-value function *v**π*(*s*). How can you use those estimates to estimate a return, even if just partially estimated? Think!

Yes! You can use a single-step reward *R**t*+1, and once you observe the next state *S**t*+1, you can use the state-value function estimates *V(S**t*+1) as an estimate of the return at the next step *G*t+1:*T*. This is the relationship in the equations that *temporal-difference* (TD[](/book/grokking-deep-reinforcement-learning/chapter-5/)[](/book/grokking-deep-reinforcement-learning/chapter-5/)) methods exploit. These methods, unlike MC, can learn from incomplete episodes by using the one-step actual return, which is the immediate reward *R**t*+1, but then an estimate of the return from the next state onwards, which is the state-value function estimate of the next state *V(S**t*+1): that is, *R**t*+1 *+* *γ**V(S**t*+1), which is called the **TD target**[](/book/grokking-deep-reinforcement-learning/chapter-5/).

|   | Boil It Down Temporal-difference learning and bootstrapping |
| --- | --- |
|  | TD methods estimate *v**π*(*s*) using an estimate of *v**π*(*s*). It bootstraps and makes a guess from a guess; it uses an estimated return instead of the actual return. More concretely, it uses *R**t*+1 + γ*V**t*( *S**t*+1) to calculate and estimate *V**t*+1( *S**t*). Because it also uses one step of the actual return *R**t*+1, things work out fine. That reward signal *R**t*+1 progressively “injects reality” into the estimates. |

|   | Show Me The Math Temporal-difference learning equations |
| --- | --- |
|  |  |

|   | I Speak Python The temporal-difference learning algorithm |
| --- | --- |
|  |  |

| ŘŁ | With An RL Accent True vs. actual vs. estimated |
| --- | --- |
|  | **True value function**: Refers to the exact and perfectly accurate value function, as if given by an oracle. The true value function is the value function agents estimate through samples. If we had the true value function, we could easily estimate returns. **Actual return**: Refers to the experienced return, as opposed to an estimated return. Agents can only experience actual returns, but they can use estimated value functions to estimate returns. *Actual return* refers to the full experienced return. **Estimated value function or estimated return**: Refers to the rough calculation of the true value function or actual return. “Estimated” means an approximation, a guess. True value functions let you estimate returns, and estimated value functions add bias to those estimates. |

Now, to be clear, the TD target is a biased estimate of the true state-value function *v*π*(s)*, because we use an estimate of the state-value function to calculate an estimate of the state-value function. Yeah, weird, I know. This way of updating an estimate with an estimate is referred to as bootstrapping*[](/book/grokking-deep-reinforcement-learning/chapter-5/)*, and it’s much like what the dynamic programming methods we learned about in chapter 3 do. The thing is, though, DP methods bootstrap on the one-step expectation while TD methods bootstrap on a sample of the one-step expectation. That word sample makes a whole lot of a difference.

On the good side, while the new estimated return, the TD target, is a biased estimate of the true state-value function *v*π(*s*), it also has a much lower variance than the actual return *G*t:T we use in Monte Carlo updates. This is because the TD target depends only on a single action, a single transition, and a single reward, so there’s much less randomness being accumulated. As a consequence, TD methods usually learn much faster than MC methods.

| 0001 | A Bit Of History Temporal-difference learning |
| --- | --- |
|  | In 1988, Richard Sutton released a paper titled “Learning to Predict by the Methods of Temporal Differences” in which he introduced the TD learning method. The RW environment we’re using in this chapter was also first presented in this paper. The critical contribution of this paper was the realization that while methods such as MC calculate errors using the differences between predicted and actual returns, TD was able to use the difference between temporally successive predictions, thus, the name temporal-difference learning. TD learning is the precursor of methods such as SARSA, Q-learning, double Q-learning, deep Q-networks (DQN), double deep Q-networks (DDQN), and more. We’ll learn about these methods in this book. |

![TD prediction](https://drek4537l1klr.cloudfront.net/morales/Figures/05_03.png)

|   | It's In The Details FVMC, EVMC, and TD on the RW environment |
| --- | --- |
|  | I ran these three policy evaluation algorithms on the RW environment. All methods evaluated an all-left policy. Now, remember, the dynamics of the environment make it such that any action, Left or Right, has a uniform probability of transition (50% Left and 50% Right). In this case, the policy being evaluated is irrelevant. I used the same schedule for the learning rate, alpha, in all algorithms: alpha starts at 0.5, and it decreases exponentially to 0.01 in 250 episodes out of the 500 total episodes. That’s 50% of the total number of episodes. This hyperparameter is essential. Often, alpha is a positive constant less than 1. Having a constant alpha helps with learning in non-stationary environments.  However, I chose to decay alpha to show convergence. The way I’m decaying alpha helps the algorithms get close to converging, but because I’m not decreasing alpha all the way to zero, they don’t fully converge. Other than that, these results should help you gain some intuition about the differences between these methods. |

|   | Tally it Up MC and TD both nearly converge to the true state-value function |
| --- | --- |
|  |  |

|   | Tally it Up MC estimates are noisy; TD estimates are off-target |
| --- | --- |
|  |  |

|   | Tally it Up MC targets high variance; TD targets bias |
| --- | --- |
|  |  |

## Learning to estimate from multiple steps

In this chapter, we looked[](/book/grokking-deep-reinforcement-learning/chapter-5/) at the two central algorithms for estimating value functions of a given policy through interaction. In MC methods, we sample the environment all the way through the end of the episode before we estimate the value function. These methods spread the actual return, the discounted total reward, on all states. For instance, if the discount factor is less than 1 and the return is only 0 or 1, as is the case in the RW environment, the MC target will always be either 0 or 1 for every single state. The same signal gets pushed back all the way to the beginning of the trajectory. This is obviously not the case for environments with a different discount factor or reward function.

![What’s in the middle?](https://drek4537l1klr.cloudfront.net/morales/Figures/05_04.png)

On the other hand, in TD learning, the agent interacts with the environment only once, and it estimates the expected return to go to, then estimates the target, and then the value function. TD methods bootstrap: they form a guess from a guess. What that means is that, instead of waiting until the end of an episode to get the actual return like MC methods do, TD methods use a single-step reward but then an estimate of the expected return-to-go, which is the value function of the next state.

But, is there something in between? I mean, that’s fine that TD bootstraps after one step, but how about after two steps? Three? Four? How many steps should we wait before we estimate the expected return and bootstrap on the value function?

As it turns out, there’s a spectrum of algorithms lying in between MC and TD. In this section, we’ll look at what’s in the middle. You’ll see that we can tune how much bootstrapping our targets depend on, letting us balance bias and variance.

|   | Miguel's Analogy MC and TD have distinct personalities |
| --- | --- |
|  | I like to think of MC-style algorithms as type-A personality agents and TD-style algorithms as type-B personality agents. If you look it up you’ll see what I mean. Type-A people are outcome-driven, time-conscious, and businesslike, while type-B are easygoing, reflective, and hippie-like. The fact that MC uses actual returns and TD uses predicted returns should make you wonder if there is a personality to each of these target types. Think about it for a while; I’m sure you’ll be able to notice several interesting patterns to help you remember. |

### N-step TD learning: Improving estimates after a couple of steps

The motivation[](/book/grokking-deep-reinforcement-learning/chapter-5/)[](/book/grokking-deep-reinforcement-learning/chapter-5/) should be clear; we have two extremes, Monte Carlo methods and temporal-difference methods. One can perform better than the other, depending on the circumstances. MC is an infinite-step method because it goes all the way until the end of the episode.

I know, “infinite” may sound confusing, but recall in chapter 2, we defined a terminal state as a state with all actions and all transitions coming from those actions looping back to that same state with no reward. This way, you can think of an agent “getting stuck” in this loop forever and therefore doing an infinite number of steps without accumulating a reward or updating the state-value function.

TD, on the other hand, is a one-step method because it interacts with the environment for a single step before bootstrapping and updating the state-value function. You can generalize these two methods into an *n*-step method. Instead of doing a single step, like TD, or the full episode like MC, why not use *n*-steps to calculate value functions and abstract *n* out? This method is called *n-step TD*, which does an *n*-step bootstrapping[](/book/grokking-deep-reinforcement-learning/chapter-5/). Interestingly, an intermediate *n* value often performs the better than either extreme. You see, you shouldn’t become an extremist!

|   | Show Me The Math *N*-step temporal-difference equations |
| --- | --- |
|  |  |

|   | I Speak Python [](/book/grokking-deep-reinforcement-learning/chapter-5/)*N*-step TD |
| --- | --- |
|  |  |

### Forward-view TD(λ): Improving estimates of all visited states

But, a question[](/book/grokking-deep-reinforcement-learning/chapter-5/)[](/book/grokking-deep-reinforcement-learning/chapter-5/) emerges: what is a good *n* value, then? When should you use a one-step, two-step, three-step, or anything else? I already gave practical advice that values of *n* higher than one are usually better, but we shouldn’t go all the way out to actual returns either. Bootstrapping helps, but its bias is a challenge.

How about using a weighted combination of all *n*-step targets as a single target? I mean, our agent could go out and calculate the *n*-step targets corresponding to the one-, two-, three-, ..., infinite-step target, then mix all of these targets with an exponentially decaying factor. Gotta have it!

This is what a method called *forward-view TD*(*λ*[](/book/grokking-deep-reinforcement-learning/chapter-5/)) does. Forward-view TD(*λ*) is a prediction method that combines multiple *n*-steps into a single update. In this particular version, the agent will have to wait until the end of an episode before it can update the state-value function estimates. However, another method, called, *backward-view* *TD(λ)*, can split the corresponding updates into partial updates and apply those partial updates to the state-value function estimates on every step, like leaving a trail of TD updates along a trajectory. Pretty cool, right? Let’s take a deeper look.

![Generalized bootstrapping](https://drek4537l1klr.cloudfront.net/morales/Figures/05_05.png)

|   | Show Me The Math Forward-view TD(λ) |
| --- | --- |
|  |  |

### TD(*λ*): Improving estimates of all visited states after each step

MC methods[](/book/grokking-deep-reinforcement-learning/chapter-5/)[](/book/grokking-deep-reinforcement-learning/chapter-5/) are under “the curse of the time step” because they can only apply updates to the state-value function estimates after reaching a terminal state. With *n*-step bootstrapping, you’re still under “the curse of the time step” because you still have to wait until *n* interactions with the environment have passed before you can make an update to the state-value function estimates. You’re basically playing catch-up with an *n*-step delay. For instance, in a five-step bootstrapping method, you’ll have to wait until you’ve seen five (or fewer when reaching a terminal state) states, and five rewards before you can make any calculations, a little bit like MC methods.

With forward-view TD(*λ*), we’re back at MC in terms of the time step; the forward-view TD(*λ*) must also wait until the end of an episode before it can apply the corresponding update to the state-value function estimates. But at least we gain something: we can get lower-variance targets if we’re willing to accept bias.

In addition to generalizing and unifying MC and TD methods, backward-view TD(*λ*), or **TD**(*λ*) for short, can still tune the bias/variance trade-off in addition to the ability to apply updates on every time step, just like TD.

The mechanism that provides TD(*λ*) this advantage is known as *eligibility traces*[](/book/grokking-deep-reinforcement-learning/chapter-5/). An eligibility trace is a memory vector that keeps track of recently visited states. The basic idea is to track the states that are eligible for an update on every step. We keep track, not only of whether a state is eligible or not, but also by how much, so that the corresponding update is applied correctly to eligible states.

![Eligibility traces for a four-state environment during an eight-step episode](https://drek4537l1klr.cloudfront.net/morales/Figures/05_06.png)

For example, all eligibility traces are initialized to zero, and when you encounter a state, you add a one to its trace. Each time step, you calculate an update to the value function for all states and multiply it by the eligibility trace vector. This way, only eligible states will get updated. After the update, the eligibility trace vector is decayed by the *λ* (weight mix-in factor) and *γ* (discount factor), so that future reinforcing events have less impact on earlier states. By doing this, the most recent states get more significant credit for a reward encountered in a recent transition than those states visited earlier in the episode, given that *λ* isn’t set to one; otherwise, this is similar to an MC update, which gives equal credit (assuming no discounting) to all states visited during the episode.

|   | Show Me The Math Backward-view TD(λ) — TD(λ) with eligibility traces, “the” TD(λ) |
| --- | --- |
|  |  |

A final thing I wanted to reiterate is that TD(λ) when λ=0 is equivalent to the TD method we learned about before. For this reason, TD is often referred to as **TD**(**0**); on the other hand, TD(λ), when λ=1 is equivalent to MC, well kind of. In reality, it’s equal to MC assuming offline updates, assuming the updates are accumulated and applied at the end of the episode. With online updates, the estimated state-value function changes likely every step, and therefore the bootstrapping estimates vary, changing, in turn, the progression of estimates. Still, **TD**(**1**) is commonly assumed equal to MC. Moreover, a recent method, called *true online* *TD*(λ[](/book/grokking-deep-reinforcement-learning/chapter-5/)), is a different implementation of TD(λ) that achieves perfect equivalence of TD(0) with TD and TD(1) with MC.

|   | I Speak Python The TD(λ) algorithm, a.k.a. backward-view The TD(λ) |
| --- | --- |
|  |  |

|   | Tally it Up [](/book/grokking-deep-reinforcement-learning/chapter-5/)Running estimates that *n*-step TD and TD(λ) produce in the [](/book/grokking-deep-reinforcement-learning/chapter-5/)RW environment |
| --- | --- |
|  |  |

|   | A Concrete Example Evaluating the optimal policy of the Russell and Norvig’s Gridworld environment |
| --- | --- |
|  | Let’s run all algorithms in a slightly different environment. The environment is one you’ve probably come across multiple times in the past. It is from Russell and Norvig’s book on AI.  Russell and Norvig’s Gridworld This environment, which I will call Russell and Norvig’s Gridworld (RNG), is a 3 x 4 grid world in which the agent starts at the bottom-left corner, and it has to reach the top-right corner. There is a hole, similar to the frozen lake environment, south of the goal, and a wall near the start. The transition function has a 20% noise; that is, 80% the action succeeds, and 20% it fails uniformly at random in orthogonal directions. The reward function is a –0.04 living penalty, a +1 for landing on the goal, and a –1 for landing on the hole. Now, what we’re doing is evaluating a policy. I happen to include the optimal policy in chapter 3’s Notebook: I didn’t have space in that chapter to talk about it. In fact, make sure you check all the Notebooks provided with the book.  Optimal policy in the RNG environment |

|   | Tally it Up FVMC, TD, *n*-step TD, and TD(λ) in the RNG environment |
| --- | --- |
|  |  |

|   | Tally it Up RNG shows a bit better the bias and variance effects on estimates |
| --- | --- |
|  |  |

|   | Tally it Up FVMC and TD targets of the RNG’s initial state |
| --- | --- |
|  |  |

## Summary

Learning from sequential feedback is challenging; you learned quite a lot about it in chapter 3. You created agents that balance immediate and long-term goals. Methods such as value iteration (VI) and policy iteration (PI) are central to RL. Learning from evaluative feedback is also very difficult. Chapter 4 was all about a particular type of environment in which agents must learn to balance the gathering and utilization of information. Strategies such as epsilon-greedy, softmax, optimistic initialization, to name a few, are also at the core of RL.

And I want you to stop for a second and think about these two trade-offs one more time as separate problems. I’ve seen 500-page and longer textbooks dedicated to each of these trade-offs. While you should be happy we only put 30 pages on each, you should also be wondering. If you want to develop new DRL algorithms, to push the state of the art, I recommend you study these two trade-offs independently. Search for books on “planning algorithms” and “bandit algorithms,” and put time and effort into understanding each of those fields. You’ll feel leaps ahead when you come back to RL and see all the connections. Now, if your goal is simply to understand DRL, to implement a couple of methods, to use them on your own projects, what’s in here will do.

In this chapter, you learned about agents that can deal with feedback that’s simultaneously sequential and evaluative. And as mentioned before, this is no small feat! To simultaneously balance immediate and long-term goals and the gathering and utilization of information is something even most humans have problems with! Sure, in this chapter, we restricted ourselves to the prediction problem, which consists of estimating values of agents’ behaviors. For this, we introduced methods such as Monte Carlo prediction and temporal-difference learning. Those two methods are the extremes in a spectrum that can be generalized with the *n*-step TD agent. By merely changing the step size, you can get virtually any agent in between. But then we learned about TD(*λ*) and how a single agent can combine the two extremes and everything in between in a very innovative way.

Next chapter, we’ll look at the control problem, which is nothing but improving the agents’ behaviors. The same way we split the policy-iteration algorithm into policy evaluation and policy improvement, splitting the reinforcement learning problem into the prediction problem and the control problem allows us to dig into the details and get better methods.

By now, you

- Understand that the challenge of reinforcement learning is because agents cannot see the underlying MDP governing their evolving environments
- Learned how these two challenges combine and give rise to the field of RL
- Know about many ways of calculating targets for estimating state-value functions

|   | Tweetable Feat Work on your own and share your findings |
| --- | --- |
|  | Here are several ideas on how to take what you have learned to the next level. If you’d like, share your results with the rest of the world and make sure to check out what others have done, too. It’s a win-win situation, and hopefully, you’ll take advantage of it. <br>      <br>      **#gdrl_ch05_tf01**: None of the methods in this chapter handle the time step limit that’s wrapped around many Gym environments. No idea what I’m talking about? No worries, I explain it in more detail in chapter 8. However, for the time being, check out this file: [https://github.com/openai/gym/blob/master/gym/envs/__init__.py](https://github.com/openai/gym/blob/master/gym/envs/__init__.py). See how many environments, including the frozen lake, have a variable max_episode_steps. This is a time step limit imposed over the environments. Think about this for a while: how does this time step limit affect the algorithms presented in this chapter? Go to the book’s Notebook, and modify the algorithms so that they handle the time step limit correctly, and the value function estimates are more accurate. Do the value functions change? Why, why not? Note that if you don’t understand what I’m referring to, you should continue and come back once you do. <br>      **#gdrl_ch05_tf02:** Comparing and plotting the Monte Carlo and temporal- difference targets is useful. One thing that would help you understand the difference is to do a more throughout analysis of these two types of targets, and also include the *n*-step and TD-lambda targets. Go ahead and start by that collecting the *n*-step targets for different values of time steps, and do the same for different values of lambda in TD-lambda targets. How do these compare with MC and TD? Also, find other ways to compare these prediction methods. But, do the comparison with graphs, visuals! <br>      **#gdrl_ch05_tf03:** In every chapter, I’m using the final hashtag as a catchall hashtag. Feel free to use this one to discuss anything else that you worked on relevant to this chapter. There’s no more exciting homework than that which you create for yourself. Make sure to share what you set yourself to investigate and your results. <br>      Write a tweet with your findings, tag me @mimoralea (I’ll retweet), and use the particular hashtag from this list to help interested folks find your results. There are no right or wrong results; you share your findings and check others’ findings. Take advantage of this to socialize, contribute, and get yourself out there! We’re waiting for you! Here’s a tweet example: “Hey, @mimoralea. I created a blog post with a list of resources to study deep reinforcement learning. Check it out at <link>. #gdrl_ch01_tf01” I’ll make sure to retweet and help others find your work. |
