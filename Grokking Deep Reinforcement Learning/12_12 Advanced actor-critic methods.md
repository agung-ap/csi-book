# 12 Advanced actor-critic methods

### In this chapter

- You will learn about more advanced deep reinforcement learning methods, which are, to this day, the state-of-the-art algorithmic advancements in deep reinforcement learning.
- You will learn about solving a variety of deep reinforcement learning problems, from problems with continuous action spaces, to problem with high-dimensional action spaces.
- You will build state-of-the-art actor-critic methods from scratch and open the door to understanding more advanced concepts related to artificial general intelligence.

*Criticism may not be agreeable, but it is necessary. It fulfills the same function as pain in the human body. It calls attention to an unhealthy state of things.*

— Winston Churchill
British politician, army officer, writer, and Prime Minister of the United Kingdom

In the last chapter, you learned about a different, more direct, technique for solving deep reinforcement learning problems. You first were introduced to policy-gradient methods in which agents learn policies by approximating them directly. In pure policy-gradient methods, we don’t use value functions as a proxy for finding policies, and in fact, we don’t use value functions at all. We instead learn stochastic policies directly.

However, you quickly noticed that value functions can still play an important role and make policy-gradient methods better. And so you were introduced to actor-critic methods. In these methods, the agent learns both a policy and a value function. With this approach, you could use the strengths of one function approximation to mitigate the weaknesses of the other approximation. For instance, learning policy can be more straightforward in certain environments than learning a sufficiently accurate value function, because the relationships in action space may be more tightly related than the relationships of values. Still, even though knowing the values of states precisely can be more complicated, a rough approximation can be useful for reducing the variance of the policy-gradient objective. As you explored in the previous chapter, learning a value function and using it as a baseline or for calculating advantages can considerably reduce the variance of the targets used for policy-gradient updates. Moreover, reducing the variance often leads to faster learning.

However, in the previous chapter, we focused on using the value function as a critic for updating a stochastic policy. We used different targets for learning the value function and parallelized the workflows in a few different ways. However, algorithms used the learned value function in the same general way to train the policy, and the policy learned had the same properties, because it was a stochastic policy. We scratched the surface of using a learned policy and value function. In this chapter, we go deeper into the paradigm of actor-critic methods and train them in four different challenging environments: pendulum, hopper, cheetah, and lunar lander. As you soon see, in addition to being more challenging environments, most of these have a continuous action space, which we face for the first time, and it’ll require using unique polices models.

To solve these environments, we first explore methods that learn deterministic policies; that is, policies that, when presented with the same state, return the same action, the action that’s believed to be optimal. We also study a collection of improvements that make deterministic policy-gradient algorithms one of the state-of-the-art approaches to date for solving deep reinforcement learning problems. We then explore an actor-critic method that, instead of using the entropy in the loss function, directly uses the entropy in the value function equation. In other words, it maximizes the return along with the long-term entropy of the policy. Finally, we close with an algorithm that allows for more stable policy improvement steps by restraining the updates to the policy to small changes. Small changes in policies make policy-gradient methods show steady and often monotonic improvements in performance, allowing for state-of-the-art performance in several DRL benchmarks.

## DDPG: Approximating a deterministic policy

In this section, we explore an algorithm called *deep deterministic policy gradient* (DDPG[](/book/grokking-deep-reinforcement-learning/chapter-12/)). DDPG can be seen as an approximate DQN, or better yet, a DQN for continuous action spaces. DDPG uses many of the same techniques found in DQN: it uses a replay buffer to train an action-value function in an off-policy manner, and target networks to stabilize training. However, DDPG also trains a policy that approximates the optimal action. Because of this, DDPG is a deterministic policy-gradient method restricted to continuous action spaces.

### DDPG uses many tricks from DQN

Start by visualizing DDPG[](/book/grokking-deep-reinforcement-learning/chapter-12/)[](/book/grokking-deep-reinforcement-learning/chapter-12/) as an algorithm with the same architecture as DQN. The training process is similar: the agent collects experiences in an online manner and stores these online experience samples into a replay buffer. On every step, the agent pulls out a mini-batch from the replay buffer that is commonly sampled uniformly at random. The agent then uses this mini-batch to calculate a bootstrapped TD target and train a Q-function.

The main difference between DQN and DDPG is that while DQN uses the target Q-function for getting the greedy action using an argmax, DDPG uses a target deterministic policy function that is trained to approximate that greedy action. Instead of using the argmax of the Q-function of the next state to get the greedy action as we do in DQN, in DDPG, we directly approximate the best action in the next state using a policy function. Then, in both, we use that action with the Q-function to get the max value.

|   | Show Me The Math DQN vs. DDPG value function objectives |
| --- | --- |
|  |  |

|   | I Speak Python DDPG’s Q-function network[](/book/grokking-deep-reinforcement-learning/chapter-12/)[](/book/grokking-deep-reinforcement-learning/chapter-12/) |
| --- | --- |
|  |  |

### Learning a deterministic policy

Now, the one[](/book/grokking-deep-reinforcement-learning/chapter-12/) thing we need to add to this algorithm to make it work is a policy network. We want to train a network that can give us the optimal action in a given state. The network must be differentiable with respect to the action. Therefore, the action must be continuous to make for efficient gradient-based learning. The objective is simple; we can use the expected Q-value using the policy network, mu. That is, the agent tries to find the action that maximizes this value. Notice that in practice, we use minimization techniques, and therefore minimize the negative of this objective.

|   | Show Me The Math DDPG’s deterministic policy objective |
| --- | --- |
|  |  |

Also notice that, in this case, we don’t use target networks, but the online networks for both the policy, which is the action selection portion, and the value function (the action evaluation portion). Additionally, given that we need to sample a mini-batch of states for training the value function, we can use these same states for training the policy network.

| 0001 | A Bit Of History Introduction of the DDPG algorithm |
| --- | --- |
|  | DDPG was introduced in 2015 in a paper titled “Continuous control with deep reinforcement learning.” The paper was authored by Timothy Lillicrap (et al.) while he was working at Google DeepMind as a research scientist. Since 2016, Tim has been working as a Staff Research Scientist at Google DeepMind and as an Adjunct Professor at University College London. Tim has contributed to several other DeepMind papers such as the A3C algorithm, AlphaGo, AlphaZero, Q-Prop, and Starcraft II, to name a few. One of the most interesting facts is that Tim has a background in cognitive science and systems neuroscience, not a traditional computer science path into deep reinforcement learning. |

|   | I Speak Python DDPG’s deterministic policy network[](/book/grokking-deep-reinforcement-learning/chapter-12/) |
| --- | --- |
|  |  |

|   | I Speak Python DDPG’s model-optimization step[](/book/grokking-deep-reinforcement-learning/chapter-12/) |
| --- | --- |
|  |  |

### Exploration with deterministic policies

In DDPG[](/book/grokking-deep-reinforcement-learning/chapter-12/), we train deterministic[](/book/grokking-deep-reinforcement-learning/chapter-12/) greedy policies. In a perfect world, this type of policy takes in a state and returns the optimal action for that state. But, in an untrained policy, the actions returned won’t be accurate enough, yet still deterministic. As mentioned before, agents need to balance exploiting knowledge with exploring. But again, since the DDPG agent learns a deterministic policy, it won’t explore on-policy. Imagine the agent is stubborn and always selects the same actions. To deal with this issue, we must explore off-policy. And so in DDPG, we inject Gaussian noise into the actions selected by the policy.

You’ve learned about exploration in multiple DRL agents. In NFQ, DQN, and so on, we use exploration strategies based on Q-values. We get the values of actions in a given state using the learned Q-function and explore based on those values. In REINFORCE, VPG, and so on, we use stochastic policies, and therefore, exploration is on-policy. That is, exploration is taken care of by the policy itself because it’s stochastic; it has randomness. In DDPG, the agent explores by adding external noise to actions, using off-policy exploration strategies.

|   | I Speak Python Exploration in deterministic policy gradients |
| --- | --- |
|  |  |

|   | A Concrete Example The pendulum environment |
| --- | --- |
|  | The Pendulum-v0 environment consists of an inverted pendulum that the agent needs to swing up, so it stays upright with the least effort possible. The state-space is a vector of three variables (cos(theta), sin(theta), theta dot) indicating the cosine of the angle of the rod, the sine, and the angular speed. The action space is a single continuous variable from –2 to 2, indicating the joint effort. The joint is that black dot at the bottom of the rod. The action is the effort either clockwise or counterclockwise. The reward function is an equation based on angle, speed, and effort. The goal is to remain perfectly balanced upright with no effort. In such an ideal time step, the agent receives 0 rewards, the best it can do. The highest cost (lowest reward) the agent can get is approximately –16 reward. The precise equation is *–(theta^2 + 0.1*theta_dt^2 + 0.001*action^2)*.  This is a continuing task, so there’s no terminal state. However, the environment times out after 200 steps, which serves the same purpose. The environment is considered unsolved, which means there’s no target return. However, –150 is a reasonable threshold to hit. |

|   | Tally it Up DDPG in the pendulum environment |
| --- | --- |
|  |  |

## TD3: State-of-the-art improvements over DDPG

DDPG has been one of the state-of-the-art deep reinforcement learning methods for control for several years. However, there have been improvements proposed that make a big difference in performance. In this section, we discuss a collection of improvements that together form a new algorithm called *twin-delayed DDPG* (TD3[](/book/grokking-deep-reinforcement-learning/chapter-12/)). TD3 introduces three main changes to the main DDPG algorithm. First, it adds a double learning technique, similar to what you learned in double Q-learning and DDQN, but this time with a unique “twin” network architecture. Second, it adds noise, not only to the action passed into the environment but also to the target actions, making the policy network more robust to approximation error. And, third, it delays updates to the policy network, its target network, and the twin target network, so that the twin network updates more frequently.

### Double learning in DDPG

In TD3[](/book/grokking-deep-reinforcement-learning/chapter-12/), we use a particular[](/book/grokking-deep-reinforcement-learning/chapter-12/) kind of Q-function network with two separate streams that end on two separate estimates of the state-action pair in question. For the most part, these two streams are totally independent, so one can think about them as two separate networks. However, it’d make sense to share feature layers if the environment was image-based. That way CNN would extract common features and potentially learn faster. Nevertheless, sharing layers is also usually harder to train, so this is something you’d have to experiment with and decide by yourself.

In the following implementation, the two streams are completely separate, and the only thing being shared between these two networks is the optimizer. As you see in the twin network loss function, we add up the losses for each of the networks and optimize both networks on that joint loss.

|   | Show Me The Math Twin target in TD3 |
| --- | --- |
|  |  |

|   | I Speak Python TD3’s twin Q-network 1/2 |
| --- | --- |
|  | [](/book/grokking-deep-reinforcement-learning/chapter-12/) |

|   | I Speak Python TD3’s twin Q-network 2/2 |
| --- | --- |
|  | [](/book/grokking-deep-reinforcement-learning/chapter-12/) |

### Smoothing the targets used for policy updates

Remember that to improve exploration in DDPG, we inject Gaussian noise into the action used for the environment. In TD3[](/book/grokking-deep-reinforcement-learning/chapter-12/), we take this concept further and add noise, not only to the action used for exploration, but also to the action used to calculate the targets.

Training the policy with noisy targets can be seen as a regularizer because now the network is forced to generalize over similar actions. This technique prevents the policy network from converging to incorrect actions because, early on during training, Q-functions can prematurely inaccurately value certain actions. The noise over the actions spreads that value over a more inclusive range of actions than otherwise.

|   | Show Me The Math Target smoothing procedure |
| --- | --- |
|  |  |

|   | I Speak Python TD3’s model-optimization step 1/2[](/book/grokking-deep-reinforcement-learning/chapter-12/) |
| --- | --- |
|  |  |

|   | I Speak Python TD3’s model-optimization step 2/2[](/book/grokking-deep-reinforcement-learning/chapter-12/) |
| --- | --- |
|  |  |

### Delaying updates

The final improvement that TD3[](/book/grokking-deep-reinforcement-learning/chapter-12/) applies over DDPG is delaying the updates to the policy network and target networks so that the online Q-function[](/book/grokking-deep-reinforcement-learning/chapter-12/) updates at a higher rate than the rest. Delaying these networks is beneficial because often, the online Q-function changes shape abruptly early on in the training process. Slowing down the policy so that it updates after a couple of value function updates allows the value function to settle into more accurate values before we let it guide the policy. The recommended delay for the policy and target networks is every other update to the online Q-function.

The other thing that you may notice in the policy updates is that we must use one of the streams of the online value model for getting the estimated Q-value for the action coming from the policy. In TD3, we use one of the two streams, but the same stream every time.

| 0001 | A Bit Of History Introduction of the TD3 agent |
| --- | --- |
|  | TD3 was introduced by Scott Fujimoto et al. in 2018 in a paper titled “Addressing Function Approximation Error in Actor-Critic Methods.” Scott is a graduate student at McGill University working on a PhD in computer science and supervised by Prof. David Meger and Prof. Doina Precup. |

|   | A Concrete Example The hopper environment |
| --- | --- |
|  | The hopper environment we use is an open source version of the MuJoCo and Roboschool Hopper environments, powered by the Bullet Physics engine. MuJoCo is a physics engine with a variety of models and tasks. While MuJoCo is widely used in DRL research, it requires a license. If you aren’t a student, it can cost you a couple thousand dollars. Roboschool was an attempt by OpenAI to create open source versions of MuJoCo environments, but it was discontinued in favor of Bullet. Bullet Physics is an open source project with many of the same environments found in MuJoCo.  The HopperBulletEnv-v0 environment features a vector with 15 continuous variables as an unbounded observation space, representing the different joints of the hopper robot. It features a vector of three continuous variables bounded between –1 and 1 and representing actions for the thigh, leg, and foot joints. Note that a single action is a vector with three elements at once. The task of the agent is to move the hopper forward, and the reward function reinforces that, also promoting minimal energy cost. |

|   | It's In The Details Training TD3 in the hopper environment[](/book/grokking-deep-reinforcement-learning/chapter-12/)[](/book/grokking-deep-reinforcement-learning/chapter-12/) |
| --- | --- |
|  | If you head to the chapter’s Notebook, you may notice that we train the agent until it reaches a 1,500 mean reward for 100 consecutive episodes. In reality, the recommended threshold is 2,500. However, because we train using five different seeds, and each training run takes about an hour, I thought to reduce the time it takes to complete the Notebook by merely reducing the threshold. Even at 1,500, the hopper does a decent job of moving forward, as you can see on the GIFs in the Notebook. Now, you must know that all the book’s implementations take a long time because they execute one evaluation episode after every episode. Evaluating performance on every episode isn’t necessary and is likely overkill for most purposes. For our purposes, it’s okay, but if you want to reuse the code, I recommend you remove that logic and instead check evaluation performance once every 10–100 or so episodes. Also, take a look at the implementation details. The book’s TD3 optimizes the policy and the value networks separately. If you want to train using CNNs, for instance, you may want to share the convolutions and optimize all at once. But again, that would require much tuning. |

|   | Tally it Up TD3 in the hopper environment |
| --- | --- |
|  |  |

## SAC: Maximizing the expected return and entropy

The previous two algorithms, DDPG and TD3, are off-policy methods that train a deterministic policy. Recall, off-policy means that the method uses experiences generated by a behavior policy that’s different from the policy optimized. In the cases of DDPG and TD3, they both use a replay buffer that contains experiences generated by several previous policies. Also, because the policy being optimized is deterministic, meaning that it returns the same action every time it’s queried, they both use off-policy exploration strategies. On our implementation, they both use Gaussian noise injection to the action vectors going into the environment.

To put it into perspective, the agents that you learned about in the previous chapter learn on-policy. Remember, they train stochastic policies, which by themselves introduce randomness and, therefore, exploration. To promote randomness in stochastic policies, we add an entropy term to the loss function.

In this section, we discuss an algorithm called *soft actor-critic* (SAC[](/book/grokking-deep-reinforcement-learning/chapter-12/)), which is a hybrid between these two paradigms. SAC is an off-policy algorithm similar to DDPG and TD3, but it trains a stochastic policy as in REINFORCE, A3C, GAE, and A2C instead of a deterministic policy, as in DDPG and TD3.

### Adding the entropy to the Bellman equations

The most crucial characteristic of SAC[](/book/grokking-deep-reinforcement-learning/chapter-12/) is that the entropy of the stochastic policy becomes part of the value function that the agent attempts to maximize. As you see in this sectiovn, jointly maximizing the expected total reward and the expected total entropy naturally encourages behavior that’s as diverse as possible while still maximizing the expected return.

|   | Show Me The Math The agent needs to also maximize the entropy |
| --- | --- |
|  |  |

### Learning the action-value function

In practice, SAC[](/book/grokking-deep-reinforcement-learning/chapter-12/) learns the value function in a way similar to TD3. That is, we use two networks approximating the Q-function[](/book/grokking-deep-reinforcement-learning/chapter-12/) and take the minimum estimate for most calculations. A few differences, however, are that, with SAC, independently optimizing each Q-function yields better results, which is what we do. Second, we add the entropy term to the target values. And last, we don’t use the target action smoothing directly as we did in TD3. Other than that, the pattern is the same as in TD3.

|   | Show Me The Math Action-value function target (we train doing MSE on this target) |
| --- | --- |
|  |  |

### Learning the policy

This time for learning the stochastic policy, we use a squashed Gaussian policy that, in the forward pass, outputs the mean and standard deviation. Then we can use those to sample from that distribution, squash the values with a hyperbolic tangent function tanh, and then rescale the values to the range expected by the environment.

For training the policy, we use the reparameterization trick[](/book/grokking-deep-reinforcement-learning/chapter-12/). This “trick” consists of moving the stochasticity out of the network and into an input. This way, the network is deterministic, and we can train it without problems. This trick is straightforwardly implemented in PyTorch, as you see next.

|   | Show Me The Math Policy objective (we train minimizing the negative of this objective) |
| --- | --- |
|  |  |

### Automatically tuning the entropy coefficient

The cherry on the cake of SAC[](/book/grokking-deep-reinforcement-learning/chapter-12/) is that alpha, which is the entropy coefficient, can be tuned automatically. SAC employs gradient-based optimization of alpha toward a heuristic expected entropy. The recommended target entropy is based on the shape of the action space; more specifically, the negative of the vector product of the action shape. Using this target entropy, we can automatically optimize alpha so that there’s virtually no hyperparameter to tune related to regulating the entropy term.

|   | Show Me The Math Alpha objective function (we train minimizing the negative of this objective) |
| --- | --- |
|  |  |

|   | I Speak Python SAC Gaussian policy 1/2[](/book/grokking-deep-reinforcement-learning/chapter-12/) |
| --- | --- |
|  |  |

|   | I Speak Python SAC Gaussian policy 2/2[](/book/grokking-deep-reinforcement-learning/chapter-12/) |
| --- | --- |
|  |  |

|   | I Speak Python SAC optimization step 1/2[](/book/grokking-deep-reinforcement-learning/chapter-12/) |
| --- | --- |
|  |  |

|   | I Speak Python SAC optimization step 2/2[](/book/grokking-deep-reinforcement-learning/chapter-12/) |
| --- | --- |
|  |  |

| 0001 | A Bit Of History Introduction of the SAC agent |
| --- | --- |
|  | SAC was introduced by Tuomas Haarnoja in 2018 in a paper titled “Soft actor-critic: Off-policy maximum entropy deep reinforcement learning with a stochastic actor.” At the time of publication, Tuomas was a graduate student at Berkeley working on a PhD in computer science under the supervision of Prof. Pieter Abbeel and Prof. Sergey Levine, and a research intern at Google. Since 2019, Tuomas is a research scientist at Google DeepMind. |

|   | A Concrete Example The cheetah environment |
| --- | --- |
|  | The HalfCheetahBulletEnv-v0 environment features a vector with 26 continuous variables for the observation space, representing the joints of the robot. It features a vector of 6 continuous variables bounded between –1 and 1, representing the actions. The task of the agent is to move the cheetah forward, and as with the hopper, the reward function reinforces that also, promoting minimal energy cost. |

|   | Tally it Up SAC on the cheetah environment |
| --- | --- |
|  |  |

## PPO: Restricting optimization steps

In this section, we introduce an actor-critic algorithm called *proximal policy optimization* (PPO[](/book/grokking-deep-reinforcement-learning/chapter-12/)). Think of PPO as an algorithm with the same underlying architecture as A2C. PPO can reuse much of the code developed for A2C[](/book/grokking-deep-reinforcement-learning/chapter-12/)[](/book/grokking-deep-reinforcement-learning/chapter-12/). That is, we can roll out using multiple environments in parallel, aggregate the experiences into mini-batches, use a critic to get GAE estimates, and train the actor and critic in a way similar to training in A2C.

The critical innovation in PPO is a surrogate objective function that allows an on-policy algorithm to perform multiple gradient steps on the same mini-batch of experiences. As you learned in the previous chapter, A2C, being an on-policy method, cannot reuse experiences for the optimization steps. In general, on-policy methods need to discard experience samples immediately after stepping the optimizer.

However, PPO introduces a clipped objective function that prevents the policy from getting too different after an optimization step. By optimizing the policy conservatively, we not only prevent performance collapse due to the innate high variance of on-policy policy gradient methods but also can reuse mini-batches of experiences and perform multiple optimization steps per mini-batch. The ability to reuse experiences makes PPO a more sample-efficient method than other on-policy methods, such as those you learned about in the previous chapter.

### Using the same actor-critic architecture as A2C

Think of PPO[](/book/grokking-deep-reinforcement-learning/chapter-12/)[](/book/grokking-deep-reinforcement-learning/chapter-12/) as an improvement to A2C. What I mean by that is that even though in this chapter we have learned about DDPG, TD3, and SAC, and all these algorithms have commonality. PPO should not be confused as an improvement to SAC. TD3 is a direct improvement to DDPG. SAC was developed concurrently with TD3. However, the SAC author published a second version of the SAC paper shortly after the first one, which includes several of the features of TD3. While SAC isn’t a direct improvement to TD3, it does share several features. PPO, however, is an improvement to A2C, and we reuse part of the A2C code. More specifically, we sample parallel environments to gather the mini-batches of data and use GAE for policy targets.

| 0001 | A Bit Of History Introduction of the PPO agent |
| --- | --- |
|  | PPO was introduced by John Schulman et al. in 2017 in a paper titled “Proximal Policy Optimization Algorithms.” John is a Research Scientist, a cofounding member, and the co-lead of the reinforcement learning team at OpenAI. He received his PhD in computer science from Berkeley, advised by Pieter Abbeel. |

### Batching experiences

One of the features of PPO[](/book/grokking-deep-reinforcement-learning/chapter-12/) that A2C didn’t have is that with PPO, we can reuse experience samples. To deal with this, we could gather large trajectory batches, as in NFQ, and “fit” the model to the data, optimizing it over and over again. However, a better approach is to create a replay buffer and sample a large mini-batch from it on every optimization step. That gives the effect of stochasticity on each mini-batch because samples aren’t always the same, yet we likely reuse all samples in the long term.

|   | I Speak Python Episode replay buffer 1/4[](/book/grokking-deep-reinforcement-learning/chapter-12/) |
| --- | --- |
|  |  |

|   | I Speak Python Episode replay buffer 2/4[](/book/grokking-deep-reinforcement-learning/chapter-12/) |
| --- | --- |
|  |  |

|   | I Speak Python Episode replay buffer 3/4[](/book/grokking-deep-reinforcement-learning/chapter-12/) |
| --- | --- |
|  |  |

|   | I Speak Python Episode replay buffer 4/4[](/book/grokking-deep-reinforcement-learning/chapter-12/) |
| --- | --- |
|  |  |

### Clipping the policy updates

The main issue[](/book/grokking-deep-reinforcement-learning/chapter-12/)[](/book/grokking-deep-reinforcement-learning/chapter-12/) with the regular policy gradient is that even a small change in parameter space can lead to a big difference in performance. The discrepancy between parameter space and performance is why we need to use small learning rates in policy-gradient methods, and even so, the variance of these methods can still be too large. The whole point of clipped PPO is to put a limit on the objective such that on each training step, the policy is only allowed to be so far away. Intuitively, you can think of this clipped objective as a coach preventing overreacting to outcomes. Did the team get a good score last night with a new tactic? Great, but don’t exaggerate. Don’t throw away a whole season of results for a new result. Instead, keep improving a little bit at a time.

|   | Show Me The Math Clipped policy objective |
| --- | --- |
|  |  |

### Clipping the value function updates

We can apply[](/book/grokking-deep-reinforcement-learning/chapter-12/)[](/book/grokking-deep-reinforcement-learning/chapter-12/) a similar clipping strategy to the value function with the same core concept: let the changes in parameter space change the Q-values only this much, but not more. As you can tell, this clipping technique keeps the variance of the things we care about smooth, whether changes in parameter space are smooth or not. We don’t necessarily need small changes in parameter space; however, we’d like level changes in performance and values.

|   | Show Me The Math Clipped value loss |
| --- | --- |
|  |  |

|   | I Speak Python PPO optimization step 1/3[](/book/grokking-deep-reinforcement-learning/chapter-12/) |
| --- | --- |
|  |  |

|   | I Speak Python PPO optimization step 2/3[](/book/grokking-deep-reinforcement-learning/chapter-12/) |
| --- | --- |
|  |  |

|   | I Speak Python PPO optimization step 3/3[](/book/grokking-deep-reinforcement-learning/chapter-12/) |
| --- | --- |
|  |  |

|   | A Concrete Example The LunarLander environment |
| --- | --- |
|  | Unlike all the other environments we have explored in this chapter, the LunarLander environment features a discrete action space. Algorithms, such as DDPG and TD3, only work with continuous action environments, whether single-variable, such as pendulum, or a vector, such as in hopper and cheetah. Agents such as DQN only work in discrete action-space environments, such as the cart-pole. Actor-critic methods such as A2C and PPO have a big plus, which is that you can use stochastic policy models that are compatible with virtually any action space.  In this environment, the agent needs to select one out of four possible actions on every step. That is 0 for do nothing; or 1 for fire the left engine; or 2 for fire the main engine; or 3 for fire the right engine. The observation space is a vector with eight elements, representing the coordinates, angles, velocities, and whether its legs touch the ground. The reward function is based on distance from the landing pad and fuel consumption. The reward threshold for solving the environment is 200, and the time step limit is 1,000. |

|   | Tally it Up PPO in the LunarLander environment |
| --- | --- |
|  |  |

## Summary

In this chapter, we surveyed the state-of-the-art actor-critic and deep reinforcement learning methods in general. You first learned about DDPG methods, in which a deterministic policy is learned. Because these methods learn deterministic policies, they use off-policy exploration strategies and update equations. For instance, with DDPG and TD3, we inject Gaussian noise into the action-selection process, allowing deterministic policies to become exploratory.

In addition, you learned that TD3 improves DDPG with three key adjustments. First, TD3 uses a double-learning technique similar to that of DDQN, in which we “cross-validate” the estimates coming out of the value function by using a twin Q-network. Second, TD3, in addition to adding Gaussian noise to the action passed into the environment, also adds Gaussian noise to target actions, to ensure the policy does not learn actions based on bogus Q-value estimates. Third, TD3 delays the updates to the policy network, so that the value networks get better estimates before we use them to change the policy.

We then explored an entropy-maximization method called SAC, which consists of maximizing a joint objective of the value function and policy entropy, which intuitively translates into getting the most reward with the most diverse policy. The SAC agent, similar to DDPG and TD3, learns in an off-policy way, which means these agents can reuse experiences to improve policies. However, unlike DDPG and TD3, SAC learns a stochastic policy, which implies exploration can be on-policy and embedded in the learned policy.

Finally, we explored an algorithm called PPO, which is a more direct descendant of A2C, being an on-policy learning method that also uses an on-policy exploration strategy. However, because of a clipped objective that makes PPO improve the learned policy more conservatively, PPO is able to reuse past experiences for its policy-improvement steps.

In the next chapter, we review several of the research areas surrounding DRL that are pushing the edge of a field that many call *artificial general intelligence* (AGI). AGI is an opportunity to understand human intelligence by recreating it. Physicist Richard Feynman said, “What I cannot create, I don’t understand.” Wouldn’t it be nice to understand intelligence?

By now, you

- Understand more advanced actor-critic algorithms and relevant tricks
- Can implement state-of-the-art deep reinforcement learning methods and perhaps devise improvements to these algorithms that you can share with others
- Can apply state-of-the-art deep reinforcement learning algorithms to a variety of environments, hopefully even environments of your own

|   | Tweetable Feat Work on your own and share your findings |
| --- | --- |
|  | Here are several ideas on how to take what you’ve learned to the next level. If you’d like, share your results with the rest of the world and make sure to check out what others have done, too. It’s a win-win situation, and hopefully, you'll take advantage of it. <br>      <br>      **#gdrl_ch12_tf01:** Pick a continuous action-space environment and test all of the agents you learned about in this chapter in that same environment. Notice that you’ll have to change PPO for this. But, it’s worth learning how these algorithms compare. <br>      **#gdrl_ch12_tf02:** Grab PPO, and add it to the previous chapter’s Notebook. Test it in similar environments and compare the results. Notice that this implementation of PPO buffers some experiences before it does any updates. Make sure to adjust the code or hyperparameters to make the comparison fair. How does PPO compare? Make sure to also test on a more challenging environment than cart-pole! <br>      **#gdrl_ch12_tf03:** There are other maximum-entropy deep reinforcement learning methods, such as soft Q-learning. Find a list of algorithms that implement this maximum-entropy objective, pick one of them, and implement it yourself. Test it and compare your implementation with other agents, including SAC. Create a blog post explaining the pros and cons of these kinds of methods. <br>      **#gdrl_ch12_tf04:** Test all the algorithms in this chapter in a high-dimensional observation-space environment that also has continuous action space. Check out the car-racing environment ([https://gym.openai.com/envs/CarRacing-v0/](https://gym.openai.com/envs/CarRacing-v0/)), for instance. Any other like that one would do. Modify the code so agents learn in these. <br>      **#gdrl_ch12_tf05:** In every chapter, I’m using the final hashtag as a catchall hashtag. Feel free to use this one to discuss anything else that you worked on relevant to this chapter. There’s no more exciting homework than that which you create for yourself. Make sure to share what you set yourself to investigate and your results. <br>      Write a tweet with your findings, tag me @mimoralea (I’ll retweet), and use the particular hashtag from the list to help interested folks find your results. There are no right or wrong results; you share your findings and check others’ findings. Take advantage of this to socialize, contribute, and get yourself out there! We’re waiting for you! Here’s a tweet example: “Hey, @mimoralea. I created a blog post with a list of resources to study deep reinforcement learning. Check it out at <link>. #gdrl_ch01_tf01” I’ll make sure to retweet and help others find your work. |
