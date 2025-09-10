# 2 Mathematical foundations of reinforcement learning

### In this chapter

- You will learn about the core components of reinforcement learning.
- You will learn to represent sequential decision-making problems as reinforcement learning environments using a mathematical framework known as Markov decision processes.
- You will build from scratch environments that reinforcement learning agents learn to solve in later chapters.

*Mankind’s history has been a struggle against a hostile environment. We finally have reached a point where we can begin to dominate our environment. ... As soon as we understand this fact, our mathematical interests necessarily shift in many areas from descriptive analysis to control theory.*

— Richard Bellman
American applied mathematician, an IEEE medal of honor recipient

You pick up this book and decide to read one more chapter despite having limited free time. A coach benches their best player for tonight’s match ignoring the press criticism. A parent invests long hours of hard work and unlimited patience in teaching their child good manners. These are all examples of complex sequential decision-making under uncertainty[](/book/grokking-deep-reinforcement-learning/chapter-2/).

I want to bring to your attention three of the words in play in this phrase: complex sequential decision-making under uncertainty[](/book/grokking-deep-reinforcement-learning/chapter-2/)[](/book/grokking-deep-reinforcement-learning/chapter-2/). The first word, *complex*, refers to the fact that agents may be learning in environments with vast action spaces. In the coaching example, even if you discover that your best player needs to rest every so often, perhaps resting them in a match with a specific opponent is better than with other opponents. Learning to generalize accurately is challenging because we learn from sampled feedback.

The second word I used is *sequential*, and this one refers to the fact that in many problems, there are delayed consequences[](/book/grokking-deep-reinforcement-learning/chapter-2/). In the coaching example, again, let’s say the coach benched their best player for a seemingly unimportant match midway through the season. But, what if the action of resting players lowers their morale and performance that only manifests in finals? In other words, what if the actual consequences are delayed? The fact is that assigning credit to your past decisions is challenging because we learn from sequential feedback.

Finally, the word *uncertainty[](/book/grokking-deep-reinforcement-learning/chapter-2/)* refers to the fact that we don’t know the actual inner workings of the world to understand how our actions affect it; everything is left to our interpretation. Let’s say the coach did bench their best player, but they got injured in the next match. Was the benching decision the reason the player got injured because the player got out of shape? What if the injury becomes a team motivation throughout the season, and the team ends up winning the final? Again, was benching the right decision? This uncertainty gives rise to the need for exploration. Finding the appropriate balance between exploration and exploitation is challenging because we learn from evaluative feedback.

In this chapter, you’ll learn to represent these kinds of problems using a mathematical framework known as *Markov decision processes* (MDPs[](/book/grokking-deep-reinforcement-learning/chapter-2/)). The general framework of MDPs allows us to model virtually any complex sequential decision-making problem under uncertainty in a way that RL agents can interact with and learn to solve solely through experience.

We’ll dive deep into the challenges of learning from sequential feedback in chapter 3, then into the challenges of learning from evaluative feedback in chapter 4, then into the challenges of learning from feedback that’s simultaneously sequential and evaluative in chapters 5 through 7, and then chapters 8 through 12 will add complex into the mix.

## Components of reinforcement learning

The two core components[](/book/grokking-deep-reinforcement-learning/chapter-2/) in RL are the *agent* and the *environment*. The agent[](/book/grokking-deep-reinforcement-learning/chapter-2/)[](/book/grokking-deep-reinforcement-learning/chapter-2/) is the decision maker, and is the solution to a problem. The environment is the representation of a problem. One of the fundamental distinctions of RL from other ML approaches is that the agent and the environment interact; the agent attempts to influence the environment through actions, and the environment reacts to the agent’s actions.

![The reinforcement learning-interaction cycle](https://drek4537l1klr.cloudfront.net/morales/Figures/02_01.png)

|   | Miguel's Analogy The parable of a Chinese farmer |
| --- | --- |
|  | There’s an excellent parable that shows how difficult it is to interpret feedback that’s simultaneously sequential, evaluative, and sampled. The parable goes like this: A Chinese farmer gets a horse, which soon runs away. A neighbor says, “So, sad. That’s bad news.” The farmer replies, “Good news, bad news, who can say?” The horse comes back and brings another horse with him. The neighbor says, “How lucky. That’s good news.” The farmer replies, “Good news, bad news, who can say?” The farmer gives the second horse to his son, who rides it, then is thrown and badly breaks his leg. The neighbor says, “So sorry for your son. This is definitely bad news.” The farmer replies, “Good news, bad news, who can say?” In a week or so, the emperor’s men come and take every healthy young man to fight in a war. The farmer’s son is spared. So, good news or bad news? Who can say? Interesting story, right? In life, it’s challenging to know with certainty what are the long-term consequences of events and our actions. Often, we find misfortune responsible for our later good fortune, or our good fortune responsible for our later misfortune. Even though this story could be interpreted as a lesson that “beauty is in the eye of the beholder,” in reinforcement learning, we assume there’s a correlation between actions we take and what happens in the world. It’s just that it’s so complicated to understand these relationships, that it’s difficult for humans to connect the dots with certainty. But, perhaps this is something that computers can help us figure out. Exciting, right? Have in mind that when feedback is simultaneously evaluative, sequential, and sampled, learning is a hard problem. And, deep reinforcement learning is a computational approach to learning in these kinds of problems. Welcome to the world of deep reinforcement learning! |

### Examples of problems, agents, and environments

The following are abbreviated examples of RL problems[](/book/grokking-deep-reinforcement-learning/chapter-2/)[](/book/grokking-deep-reinforcement-learning/chapter-2/)[](/book/grokking-deep-reinforcement-learning/chapter-2/)[](/book/grokking-deep-reinforcement-learning/chapter-2/)[](/book/grokking-deep-reinforcement-learning/chapter-2/), agents, environments, possible actions, and observations:

- **Problem** You’re training your dog to sit. **Agent:** The part of your brain that makes decisions. **Environment** Your dog, the treats, your dog’s paws, the loud neighbor, and so on. **Actions:** Talk to your dog. Wait for dog’s reaction. Move your hand. Show treat. Give treat. Pet. **Observations:** Your dog is paying attention to you. Your dog is getting tired. Your dog is going away. Your dog sat on command.
- **Problem**: Your dog wants the treats you have. **Agent**: The part of your dog’s brain that makes decisions. **Environment**: You, the treats, your dog’s paws, the loud neighbor, and so on. **Actions:** Stare at owner. Bark. Jump at owner. Try to steal the treat. Run. Sit. **Observations:** Owner keeps talking loud at dog. Owner is showing the treat. Owner is hiding the treat. Owner gave the dog the treat.
- **Problem**: A trading agent investing in the stock market. **Agent**: The executing DRL code in memory and in the CPU. **Environment**: Your internet connection, the machine the code is running on, the stock prices, the geopolitical uncertainty, other investors, day traders, and so on. **Actions:** Sell *n* stocks of *y* company. Buy *n* stocks of *y* company. Hold. **Observations:** Market is going up. Market is going down. There are economic tensions between two powerful nations. There’s danger of war in the continent. A global pandemic is wreaking havoc in the entire world.
- **Problem** You’re driving your car. **Agent**: The part of your brain that makes decisions. **Environment**: The make and model of your car, other cars, other drivers, the weather, the roads, the tires, and so on. **Actions:** Steer by *x*, accelerate by *y*. Break by *z*. Turn the headlights on. Defog windows. Play music. **Observations:** You’re approaching your destination. There’s a traffic jam on Main Street. The car next to you is driving recklessly. It’s starting to rain. There’s a police officer driving in front of you.

As you can see, problems can take many forms: from high-level decision-making problems that require long-term thinking and broad general knowledge, such as investing in the stock market, to low-level control problems, in which geopolitical tensions don’t seem to play a direct role, such as driving a car.

Also, you can represent a problem from multiple agents’ perspectives. In the dog training example, in reality, there are two agents each interested in a different goal and trying to solve a different problem.

Let’s zoom into each of these components independently.

### The agent: The decision maker

As I mentioned in chapter 1, this whole book is about agents, except for this chapter, which is about the environment. Starting with chapter 3, you dig deep into the inner workings of agents, their components, their processes, and techniques to create agents that are effective and efficient.

For now, the only important thing for you to know about agents is that they are the decision-makers in the RL big picture. They have internal components and processes of their own, and that’s what makes each of them unique and good at solving specific problems.

If we were to zoom in, we would see that most agents have a three-step process: all agents[](/book/grokking-deep-reinforcement-learning/chapter-2/) have an interaction component, a way to gather data for learning; all agents evaluate their current behavior; and all agents improve something in their inner components that allows them to improve (or at least attempt to improve) their overall performance.

![The three internal steps that every reinforcement learning agent goes through](https://drek4537l1klr.cloudfront.net/morales/Figures/02_02.png)

We’ll continue discussing the inner workings of agents starting with the next chapter. For now, let’s discuss a way to represent environments, how they look, and how we should model them, which is the goal of this chapter.

### The environment: Everything else

Most real-world decision-making problems can be expressed as RL environments. A common way to represent decision-making processes in RL is by modeling the problem using a mathematical framework known as Markov decision processes (MDPs)[](/book/grokking-deep-reinforcement-learning/chapter-2/)[](/book/grokking-deep-reinforcement-learning/chapter-2/). In RL, we assume all environments have an MDP working under the hood. Whether an Atari game, the stock market, a self-driving car, your significant other, you name it, every problem has an MDP running under the hood (at least in the RL world, whether right or wrong).

The environment is represented by a set of variables[](/book/grokking-deep-reinforcement-learning/chapter-2/) related to the problem. The combination of all the possible values this set of variables can take is referred to as the *state* *space[](/book/grokking-deep-reinforcement-learning/chapter-2/)*. A state[](/book/grokking-deep-reinforcement-learning/chapter-2/) is a specific set of values[](/book/grokking-deep-reinforcement-learning/chapter-2/) the variables take at any given time.

Agents may or may not have access to the actual environment’s state; however, one way or another, agents can observe something from the environment. The set of variables the agent perceives at any given time is called an observation[](/book/grokking-deep-reinforcement-learning/chapter-2/).

The combination of all possible values these variables can take is the *observation space*[](/book/grokking-deep-reinforcement-learning/chapter-2/). Know that state[](/book/grokking-deep-reinforcement-learning/chapter-2/)[](/book/grokking-deep-reinforcement-learning/chapter-2/) and observation are terms used interchangeably in the RL community. This is because often agents are allowed to see the internal state of the environment, but this isn’t always the case. In this book, I use state and observation interchangeably as well. But you need to know that there might be a difference between states and observations, even though the RL community often uses the terms interchangeably.

At every state, the environment makes available a set of actions[](/book/grokking-deep-reinforcement-learning/chapter-2/) the agent can choose from. Often the set of actions is the same for *action space*.

The agent attempts to influence the environment through these actions. The environment may change states as a response to the agent’s action. The function that is responsible for this transition is called the *transition function*[](/book/grokking-deep-reinforcement-learning/chapter-2/).

After a transition, the environment emits a new observation. The environment may also provide a reward[](/book/grokking-deep-reinforcement-learning/chapter-2/) signal as a response. The function responsible for this mapping is called the *reward function*[](/book/grokking-deep-reinforcement-learning/chapter-2/). The set of transition and reward function is referred to as the *model* of the environment[](/book/grokking-deep-reinforcement-learning/chapter-2/)[](/book/grokking-deep-reinforcement-learning/chapter-2/).

|   | A Concrete Example The bandit walk environment |
| --- | --- |
|  | Let’s make these concepts concrete with our first RL environment. I created this very simple environment for this book; I call it the bandit walk (BW). BW is a simple *grid-world* (GW) environment[](/book/grokking-deep-reinforcement-learning/chapter-2/). GWs are a common type of environment for studying RL algorithms that are grids of any size. GWs can have any model (transition and reward functions) you can think of and can make any kind of actions available. But, they all commonly make move actions available to the agent: Left, Down, Right, Up (or West, South, East, North, which is more precise because the agent has no heading and usually has no visibility of the full grid, but cardinal directions can also be more confusing). And, of course, each action corresponds with its logical transition: Left goes left, and Right goes right. Also, they all tend to have a fully observable discrete state and observation spaces (that is, state equals observation) with integers representing the cell id location of the agent. A “walk” is a special case of grid-world environments with a single row. In reality, what I call a “walk” is more commonly referred to as a “Corridor.” But, in this book, I use the term “walk” for all the grid-world environments with a single row. The bandit walk (BW) is a walk with three states, but only one non-terminal state. Environments that have a single non-terminal state are called “bandit” environments. “Bandit” here is an analogy to slot machines, which are also known as “one-armed bandits”; they have one arm and, if you like gambling, can empty your pockets, the same way a bandit would. The BW environment has just two actions available: a Left (action 0) and an Right (action 1) action. BW has a deterministic transition function: a Left action always moves the agent to the Left, and a Right action always moves the agent to the right. The reward signal is a +1 when landing on the rightmost cell, 0 otherwise. The agent starts in the middle cell.  The bandit walk (BW) environment |

A graphical representation of the BW environment would look like the following.

![Bandit walk graph](https://drek4537l1klr.cloudfront.net/morales/Figures/02_04.png)

I hope this raises several questions, but you’ll find the answers throughout this chapter. For instance, why do the terminal states have actions that transition to themselves: seems wasteful, doesn’t? Any other questions? Like, what if the environment is stochastic? What exactly is an environments that is “stochastic”?! Keep reading.

We can also represent this environment in a table form.

| State | Action | Next state | Transition probability | Reward signal |
| --- | --- | --- | --- | --- |
| 0 (Hole) | 0 (Left) | 0 (Hole) | 1.0 | 0 |
| 0 (Hole) | 1 (Right) | 0 (Hole) | 1.0 | 0 |
| 1 (Start) | 0 (Left) | 0 (Hole) | 1.0 | 0 |
| 1 (Start) | 1 (Right) | 2 (Goal) | 1.0 | +1 |
| 2 (Goal) | 0 (Left) | 2 (Goal) | 1.0 | 0 |
| 2 (Goal) | 1 (Right) | 2 (Goal) | 1.0 | 0 |

Interesting, right? Let’s look at another simple example.

|   | A Concrete Example The bandit slippery walk environment |
| --- | --- |
|  | Okay, so how about we make this environment stochastic? Let’s say the surface of the walk is slippery and each action has a 20% chance of sending the agent backwards. I call this environment the bandit slippery walk (BSW). BSW is still a one-row-grid world, a walk, a corridor, with only Left and Right actions available. Again, three states and two actions. The reward is the same as before, +1 when landing at the rightmost state (except when coming from the rightmost state-from itself), and zero otherwise. However, the transition function is different: 80% of the time the agent moves to the intended cell, and 20% of time in the opposite direction. A depiction of this environment would look as follows.  The bandit slippery walk (BSW) environment Identical to the BW environment! Interesting ... How do we know that the action effects are stochastic? How do we represent the “slippery” part of this problem? The graphical and table representations can help us with that. |

A graphical representation of the BSW environment would look like the following.

![Bandit slippery walk graph](https://drek4537l1klr.cloudfront.net/morales/Figures/02_06.png)

See how the transition function is different now? The BSW environment has a stochastic transition function[](/book/grokking-deep-reinforcement-learning/chapter-2/). Let’s now represent this environment in a table form as well.

| State | Action | Next state | Transition probability | Reward signal |
| --- | --- | --- | --- | --- |
| 0 (Hole) | 0 (Left) | 0 (Hole) | 1.0 | 0 |
| 0 (Hole) | 1 (Right) | 0 (Hole) | 1.0 | 0 |
| 1 (Start) | 0 (Left) | 0 (Hole) | 0.8 | 0 |
| 1 (Start) | 0 (Left) | 2 (Goal) | 0.2 | +1 |
| 1 (Start) | 1 (Right) | 2 (Goal) | 0.8 | +1 |
| 1 (Start) | 1 (Right) | 0 (Hole) | 0.2 | 0 |
| 2 (Goal) | 0 (Left) | 2 (Goal) | 1.0 | 0 |
| 2 (Goal) | 1 (Right) | 2 (Goal) | 1.0 | 0 |

And, we don’t have to limit ourselves to thinking about environments with discrete state and action spaces or even walks (corridors) or bandits (which we discuss in-depth in the next chapter) or grid worlds. Representing environments as MDPs is a surprisingly powerful and straightforward approach to modeling complex sequential decision-making problems under uncertainty.

Here are a few more examples of environments[](/book/grokking-deep-reinforcement-learning/chapter-2/) that are powered by underlying MDPs.

| Description | Observation space | Sample observation | Action space | Sample action | Reward function |
| --- | --- | --- | --- | --- | --- |
| **Hotter, colder**[](/book/grokking-deep-reinforcement-learning/chapter-2/)**:** Guess a randomly selected number using hints. | Int range 0–3. 0 means no guess yet submitted, 1 means guess is lower than the target, 2 means guess is equal to the target, and 3 means guess is higher than the target. | 2 | Float from –2000.0–2000.0. The float number the agent is guessing. | –909.37 | The reward is the squared percentage of the way the agent has guessed toward the target. |
| **Cart pole**[](/book/grokking-deep-reinforcement-learning/chapter-2/)**:** Balance a pole in a cart. | A four-element vector with ranges: from [–4.8, –Inf, –4.2, –Inf] to [4.8, Inf, 4.2, Inf]. First element is the cart position, second is the cart velocity, third is pole angle in radians, fourth is the pole velocity at tip. | [–0.16, –1.61, 0.17, 2.44] | Int range 0–1. 0 means push cart left, 1 means push cart right. | 0 | The reward is 1 for every step taken, including the termination step. |
| **Lunar lander**[](/book/grokking-deep-reinforcement-learning/chapter-2/)**:** Navigate a lander to its landing pad. | An eight-element vector with ranges: from [–Inf, –Inf, –Inf, –Inf, –Inf, –Inf, 0, 0] to [Inf, Inf, Inf, Inf, Inf, Inf, 1, 1]. First element is the x position, the second the y position, the third is the x velocity, the fourth is the y velocity, fifth is the vehicle’s angle, sixth is the angular velocity, and the last two values are Booleans indicating legs contact with the ground. | [0.36 , 0.23, –0.63, –0.10, –0.97, –1.73, 1.0, 0.0] | Int range 0–3. No-op (do nothing), fire left engine, fire main engine, fire right engine. | 2 | Reward for landing is 200. There’s a reward for moving from the top to the landing pad, for crashing or coming to rest, for each leg touching the ground, and for firing the engines. |
| **Pong**[](/book/grokking-deep-reinforcement-learning/chapter-2/)**:** Bounce the ball past the opponent, and avoid letting the ball pass you. | A tensor of shape 210, 160, 3. Values ranging 0–255. Represents a game screen image. | [[[246, 217, 64], [ 55, 184, 230], [ 46, 231, 179], ..., [ 28, 104, 249], [ 25, 5, 22], [173, 186, 1]], ...]] | Int range 0–5. Action 0 is No-op, 1 is Fire, 2 is up, 3 is right, 4 is Left, 5 is Down. Notice how some actions don’t affect the game in any way. In reality the paddle can only move up or down, or not move. | 3 | The reward is a 1 when the ball goes beyond the opponent, and a –1 when your agent’s paddle misses the ball. |
| **Humanoid**[](/book/grokking-deep-reinforcement-learning/chapter-2/)**:** Make robot run as fast as possible and not fall. | A 44-element (or more, depending on the implementation) vector. Values ranging from –Inf to Inf. Represents the positions and velocities of the robot’s joints. | [0.6, 0.08, 0.9, 0. 0, 0.0, 0.0, 0.0, 0.0, 0.045, 0.0, 0.47, ... , 0.32, 0.0, –0.22, ... , 0.] | A 17-element vector. Values ranging from –Inf to Inf. Represents the forces to apply to the robot’s joints. | [–0.9, –0.06, 0.6, 0.6, 0.6, –0.06, –0.4, –0.9, 0.5, –0.2, 0.7, –0.9, 0.4, –0.8, –0.1, 0.8, –0.03] | The reward is calculated based on forward motion with a small penalty to encourage a natural gait. |

Notice I didn’t add the transition function to this table. That’s because, while you can look at the code implementing the dynamics for certain environments, other implementations are not easily accessible. For instance, the transition function[](/book/grokking-deep-reinforcement-learning/chapter-2/) of the cart pole[](/book/grokking-deep-reinforcement-learning/chapter-2/) environment is a small Python file defining the mass of the cart and the pole and implementing basic physics equations, while the dynamics of Atari games, such as Pong[](/book/grokking-deep-reinforcement-learning/chapter-2/), are hidden inside an Atari emulator and the corresponding game-specific ROM file.

Notice that what we’re trying to represent here is the fact that the environment “reacts” to the agent’s actions in some way, perhaps even by ignoring the agent’s actions. But at the end of the day, there’s an internal process that’s uncertain (except in this and the next chapter). To represent the ability to interact with an environment in an MDP, we need states, observations, actions, a transition, and a reward function.

![Process the environment goes through as a consequence of agent’s actions](https://drek4537l1klr.cloudfront.net/morales/Figures/02_07.png)

### Agent-environment interaction cycle

The environment[](/book/grokking-deep-reinforcement-learning/chapter-2/)[](/book/grokking-deep-reinforcement-learning/chapter-2/) commonly has a well-defined task[](/book/grokking-deep-reinforcement-learning/chapter-2/). The goal[](/book/grokking-deep-reinforcement-learning/chapter-2/) of this task is defined through the reward signal. The reward signal[](/book/grokking-deep-reinforcement-learning/chapter-2/) can be dense[](/book/grokking-deep-reinforcement-learning/chapter-2/)[](/book/grokking-deep-reinforcement-learning/chapter-2/), sparse, or anything in between. When you design environments, reward signals are the way to train your agent the way you want. The more dense, the more supervision the agent will have, and the faster the agent will learn, but the more bias you’ll inject into your agent, and the less likely the agent will come up with unexpected behaviors. The more sparse, the less supervision, and therefore, the higher the chance of new, emerging behaviors, but the longer it’ll take the agent to learn.

The interactions between the agent and the environment go on for several cycles. Each cycle is called a *time step*[](/book/grokking-deep-reinforcement-learning/chapter-2/). A time step is a unit of time, which can be a millisecond, a second, 1.2563 seconds, a minute, a day, or any other period of time.

At each time step, the agent observes the environment, takes action, and receives a new observation and reward. Notice that, even though rewards can be negative values, they are still called rewards in the RL world. The set of the observation (or state), the action, the reward, and the new observation (or new state) is called an *experience tuple*.

The task the agent is trying to solve may or may not have a natural ending[](/book/grokking-deep-reinforcement-learning/chapter-2/). Tasks that have a natural ending, such as a game, are called *episodic tasks*[](/book/grokking-deep-reinforcement-learning/chapter-2/)[](/book/grokking-deep-reinforcement-learning/chapter-2/). Tasks that don’t, such as learning forward motion, are called *continuing tasks[](/book/grokking-deep-reinforcement-learning/chapter-2/)[](/book/grokking-deep-reinforcement-learning/chapter-2/)*. The sequence of time steps from the beginning to the end of an episodic task is called an *episode[](/book/grokking-deep-reinforcement-learning/chapter-2/)*. Agents may take several time steps and episodes to learn to solve a task. The sum of rewards[](/book/grokking-deep-reinforcement-learning/chapter-2/)[](/book/grokking-deep-reinforcement-learning/chapter-2/) collected in a single episode is called a *return[](/book/grokking-deep-reinforcement-learning/chapter-2/)*. Agents are often designed to maximize the return. A time step limit is often added to continuing tasks, so they become episodic tasks, and agents can maximize the return.

Every experience tuple has an opportunity for learning and improving performance. The agent may have one or more components to aid learning. The agent may be designed to learn mappings from observations to actions called policies[](/book/grokking-deep-reinforcement-learning/chapter-2/). The agent may be designed to learn mappings from observations to new observations and/or rewards called models[](/book/grokking-deep-reinforcement-learning/chapter-2/). The agent may be designed to learn mappings from observations (and possibly actions) to reward-to-go estimates (a slice of the return) called value functions[](/book/grokking-deep-reinforcement-learning/chapter-2/).

For the rest of this chapter, we’ll put aside the agent and the interactions, and we’ll examine the environment and inner MDP in depth. In chapter 3, we’ll pick back up the agent, but there will be no interactions because the agent won’t need them as it’ll have access to the MDPs. In chapter 4, we’ll remove the agent’s access to MDPs and add interactions back into the equation, but it’ll be in single-state environments (bandits). Chapter 5 is about learning to estimate returns in multi-state environments when agents have no access to MDPs. Chapters 6 and 7 are about optimizing behavior, which is the full reinforcement learning problem. Chapters 5, 6, and 7 are about agents learning in environments where there’s no need for function approximation. After that, the rest of the book is all about agents that use neural networks for learning.

## MDPs: The engine of the environment

Let’s build MDPs[](/book/grokking-deep-reinforcement-learning/chapter-2/) for a few environments as we learn about the components that make them up. We’ll create Python dictionaries representing MDPs from descriptions of the problems. In the next chapter, we’ll study algorithms for planning on MDPs. These methods can devise solutions to MDPs and will allow us to find optimal solutions to all problems in this chapter.

The ability to build environments yourself is an important skill to have. However, often you find environments for which somebody else has already created the MDP. Also, the dynamics of the environments are often hidden behind a simulation engine and are too complex to examine in detail; certain dynamics are even inaccessible and hidden behind the real world. In reality, RL agents don’t need to know the precise MDP of a problem to learn robust behaviors, but knowing *you* because agents are commonly designed with the assumption that an MDP, even if inaccessible, is running under the hood.

|   | A Concrete Example The frozen lake environment |
| --- | --- |
|  | This is another, more challenging problem for which we will build an MDP in this chapter. This environment is called the frozen lake (FL). FL is a simple grid-world (GW) environment. It also has discrete state and action spaces. However, this time, four actions are available: move Left, Down, Right, or Up. The task in the FL environment is similar to the task in the BW and BSW environments: to go from a start location to a goal location while avoiding falling into holes. The challenge is similar to the BSW, in that the surface of the FL environment is slippery, it’s a frozen lake after all. But the environment itself is larger. Let’s look at a depiction of the FL.  The frozen lake (FL) environment The FL is a 4 × 4 grid (it has 16 cells, ids 0–15). The agent shows up in the START cell every new episode. Reaching the GOAL cell gives a +1 reward; anything else is a 0. Because the surface are slippery, the agent moves only a third of the time as intended. The other two-thirds are split evenly in orthogonal directions. For example, if the agent chooses to move down, there’s a 33.3% chance it moves down, 33.3% chance it moves left, and 33.3% chance it moves right. There’s a fence around the lake, so if the agent tries to move out of the grid world, it will bounce back to the cell from which it tried to move. There are four holes in the lake. If the agent falls into one of these holes, it’s game over. Are you ready to start building a representation of these dynamics? We need a Python dictionary representing the MDP as described here. Let’s start building the MDP. |

### States: Specific configurations of the environment

A *state* is a unique and self-contained configuration of the problem. The set of all possible states, the *state space*, is defined as the set *S*. The state space[](/book/grokking-deep-reinforcement-learning/chapter-2/)[](/book/grokking-deep-reinforcement-learning/chapter-2/)[](/book/grokking-deep-reinforcement-learning/chapter-2/) can be finite[](/book/grokking-deep-reinforcement-learning/chapter-2/)[](/book/grokking-deep-reinforcement-learning/chapter-2/) or infinite. But notice that the state space is different than the set of variables that compose a single state. This other set must always be finite and of constant size from state to state. In the end, the state space[](/book/grokking-deep-reinforcement-learning/chapter-2/) is a set of sets. The inner set must be of equal size and finite, as it contains the number of variables representing the states, but the outer set can be infinite depending on the types of elements of the inner sets.

![State space: A set of sets](https://drek4537l1klr.cloudfront.net/morales/Figures/02_09.png)

For the BW, BSW, and FL environments, the state is composed of a single variable containing the id of the cell where the agent is at any given time. The agent’s location cell id is a discrete variable. But state variables can be of any kind, and the set of variables can be larger than one. We could have the Euclidean distance that would be a continuous variable and an infinite state space; for example, 2.124, 2.12456, 5.1, 5.1239458, and so on. We could also have multiple variables defining the state, for instance, the number of cells away from the goal in the x- and y-axis. That would be two variables representing a single state. Both variables would be discrete, therefore, the state space finite. However, we could also have variables of mixed types; for instance, one could be discrete, another continuous, another Boolean.

With this state representation for the BW[](/book/grokking-deep-reinforcement-learning/chapter-2/), BSW[](/book/grokking-deep-reinforcement-learning/chapter-2/), and FL[](/book/grokking-deep-reinforcement-learning/chapter-2/) environments, the size of the state space is 3, 3, and 16, respectively. Given we have 3, 3, or 16 cells, the agent can be at any given time, then we have 3, 3, and 16 possible states in the state space. We can set the ids of each cell starting from zero, going left to right, top to bottom.

In the FL, we set the ids from zero to 15, left to right, top to bottom. You could set the ids in any other way: in a random order, or group cells by proximity, or whatever. It’s up to you; as long as you keep them consistent throughout training, it will work. However, this representation is adequate, and it works well, so it’s what we’ll use.

![States in the FL contain a single variable indicating the id of the cell in which the agent is at any given time step](https://drek4537l1klr.cloudfront.net/morales/Figures/02_10.png)

In the case of MDPs[](/book/grokking-deep-reinforcement-learning/chapter-2/)[](/book/grokking-deep-reinforcement-learning/chapter-2/), the states are fully observable[](/book/grokking-deep-reinforcement-learning/chapter-2/)[](/book/grokking-deep-reinforcement-learning/chapter-2/): we can see the internal state of the environment at each time step, that is, the observations and the states are the same. *partially observable Markov decision processes* (POMDPs[](/book/grokking-deep-reinforcement-learning/chapter-2/)[](/book/grokking-deep-reinforcement-learning/chapter-2/)) is a more general framework for modeling environments in which observations, which still depend on the internal state of the environment, are the only things the agent can see instead of the state. Notice that for the BW, BSW, and FL environments, we’re creating an MDP, so the agent will be able to observe the internal state of the environment.

States must contain all the variables necessary to make them independent of all other states. In the FL environment, you only need to know the current state of the agent to tell its next possible states. That is, you don’t need the history of states visited by the agent for anything. You know that from state 2 the agent can only transition to states 1, 3, 6, or 2, and this is true regardless of whether the agent’s previous state was 1, 3, 6, or 2.

The probability of the next state, given the current state and action, is independent of the history of interactions. This memoryless property of MDPs is known as the *Markov property*[](/book/grokking-deep-reinforcement-learning/chapter-2/)[](/book/grokking-deep-reinforcement-learning/chapter-2/): the probability of moving from one state *s* to another state *s* on two separate occasions, given the same action *a*, is the same regardless of all previous states or actions encountered before that point.

|   | Show Me The Math The Markov property |
| --- | --- |
|  |  |

But why do you care about this? Well, in the environments we’ve explored so far it’s not that obvious, and it’s not that important. But because most RL (and DRL) agents are designed to take advantage of the Markov assumption, you must make sure you feed your agent the necessary variables to make it hold as tightly as possible (completely keeping the Markov assumption is impractical, perhaps impossible).

For example, if you’re designing an agent to learn to land a spacecraft, the agent must receive all variables that indicate velocities along with its locations. Locations alone are not sufficient to land a spacecraft safely, and because you must assume the agent is memoryless, you need to feed the agent more information than just its x, y, z coordinates away from the landing pad.

But, you probably know that acceleration is to velocity what velocity is to position: the derivative. You probably also know that you can keep taking derivatives beyond acceleration. To make the MDP completely Markovian, how deep do you have to go? This is more of an art than a science: the more variables you add, the longer it takes to train an agent, but the fewer variables, the higher the chance the information fed to the agent is not sufficient, and the harder it is to learn anything useful. For the spacecraft example, often locations and velocities are adequate, and for grid-world environments, only the state id location of the agent is sufficient.

The set of all states in the MDP is denoted S+. There is a subset of S+ called the set of *starting* or *initial states*, denoted Si. To begin interacting with an MDP, we draw a state from *S*i from a probability distribution. This distribution can be anything, but it must be fixed throughout training: that is, the probabilities must be the same from the first to the last episode of training and for agent evaluation.

There’s a unique state called the *absorbing[](/book/grokking-deep-reinforcement-learning/chapter-2/)* or *terminal state*[](/book/grokking-deep-reinforcement-learning/chapter-2/)[](/book/grokking-deep-reinforcement-learning/chapter-2/), and the set of all non-terminal states is denoted[](/book/grokking-deep-reinforcement-learning/chapter-2/) *S*. Now, while it’s common practice to create a single terminal state (a sink state) to which all terminal transitions go, this isn’t always implemented this way. What you’ll see more often is multiple terminal states, and that’s okay. It doesn’t really matter under the hood if you make all terminal states behave as expected.

As expected? Yes. A terminal state is a special state: it must have all available actions transitioning, with probability 1, to itself, and these transitions must provide no reward. Note that I’m referring to the transitions from the terminal state, not to the terminal state.

It’s very commonly the case that the end of an episode provides a non-zero reward[](/book/grokking-deep-reinforcement-learning/chapter-2/)[](/book/grokking-deep-reinforcement-learning/chapter-2/). For instance, in a chess game you win, you lose, or you draw. A logical reward signal would be +1, –1, and 0, respectively. But it’s a compatibility convention that allows for all algorithms to converge to the same solution to make all actions available in a terminal state transition from that terminal state to itself with probability 1 and reward 0. Otherwise, you run the risk of infinite sums and algorithms that may not work altogether. Remember how the BW and BSW environments had these terminal states?

In the FL environment, for instance, there’s only one starting state (which is state 0) and five terminal states (or five states that transition to a single terminal state, whichever you prefer). For clarity, I use the convention of multiple terminal states (5, 7, 11, 12, and 15) for the illustrations and code; again, each terminal state is a separate terminal state.

![States in the frozen lake environment](https://drek4537l1klr.cloudfront.net/morales/Figures/02_11.png)

### Actions: A mechanism to influence the environment

MDPs[](/book/grokking-deep-reinforcement-learning/chapter-2/)[](/book/grokking-deep-reinforcement-learning/chapter-2/) make[](/book/grokking-deep-reinforcement-learning/chapter-2/)[](/book/grokking-deep-reinforcement-learning/chapter-2/) available a set of actions A that depends on the state. That is, there might be actions that aren’t allowed in a state—in fact, A is a function that takes a state as an argument; that is, A(s). This function returns the set of available actions for state s. If needed, you can define this set to be constant across the state space; that is, all actions are available at every state. You can also set all transitions from a state-action pair to zero if you want to deny an action in a given state. You could also set all transitions from state s and action a to the same state s to denote action a as a no-intervene[](/book/grokking-deep-reinforcement-learning/chapter-2/) or no-op action[](/book/grokking-deep-reinforcement-learning/chapter-2/).

Just as with the state, the action[](/book/grokking-deep-reinforcement-learning/chapter-2/)[](/book/grokking-deep-reinforcement-learning/chapter-2/) space may be finite or infinite, and the set of variables of a single action may contain more than one element and must be finite. However, unlike the number of state variables, the number of variables that compose an action may not be constant. The actions available in a state may change depending on that state. For simplicity, most environments are designed with the same number of actions in all states.

The environment makes the set of all available actions known in advance. Agents[](/book/grokking-deep-reinforcement-learning/chapter-2/)[](/book/grokking-deep-reinforcement-learning/chapter-2/) can select actions either deterministically or stochastically. This is different than saying the environment reacts deterministically or stochastically to agents’ actions. Both are true statements, but I’m referring here to the fact that agents can either select actions from a lookup table or from per-state probability distributions.

In the BW, BSW, and FL environments, actions are singletons representing the direction the agent will attempt to move. In FL, there are four available actions in all states: Up, Down, Right, or Left. There’s one variable per action, and the size of the action space is four.

![The frozen lake environment has four simple move actions](https://drek4537l1klr.cloudfront.net/morales/Figures/02_12.png)

### Transition function: Consequences of agent actions

The way the environment changes as a response to actions is referred to as the *state-transition* *probabilities*, or more simply, the *transition function*[](/book/grokking-deep-reinforcement-learning/chapter-2/), and is denoted by *T(s, a, s')*. The transition function *T* maps a transition tuple *s*, *a*, *s'* to a probability; that is, you pass in a state *s*, an action *a*, and a next state *s'*, and it’ll return the corresponding probability of transition from state *s* to state *s'* when taking action *a*. You could also represent it as *T(s, a)* and return a dictionary with the next states for its keys and probabilities for its values.

Notice that *t* also describes a probability distribution *p( · | s, a)* determining how the system will evolve in an interaction cycle from selecting action *a* in state *s*. When integrating over the next states *s'*, as any probability distribution, the sum of these probabilities must equal one.

|   | Show Me The Math The transition function |
| --- | --- |
|  |  |

The BW environment was deterministic; that is, the probability of the next state *s'* given the current state *s* and action *a* was always 1. There was always a single possible next state *s'*. The BSW and FL environments are stochastic; that is, the probability of the next state *s'* given the current state *s* and action *a* is less than 1. There are more than one possible next state *s'*s.

One key assumption of many RL (and DRL) algorithms is that this distribution is stationary. That is, while there may be highly stochastic transitions, the probability distribution may not change during training or evaluation. Just as with the Markov assumption, the stationarity assumption is often relaxed to an extent. However, it’s important for most agents to interact with environments that at least appear to be stationary.

In the FL environment, we know that there’s a 33.3% chance we’ll transition to the intended cell (state) and a 66.6% chance we’ll transition to orthogonal directions. There’s also a chance we’ll bounce back to the state we’re coming from if it’s next to the wall.

For simplicity and clarity, I’ve added to the following image only the transition function for all actions of states 0, 2, 5, 7, 11, 12, 13, and 15 of the FL environment. This subset of states allows for the illustration of all possible transitions without too much clutter.

![The transition function of the frozen lake environment](https://drek4537l1klr.cloudfront.net/morales/Figures/02_13.png)

It might still be a bit confusing, but look at it this way: for consistency, each action in non-terminal states has three separate transitions (certain actions in corner states could be represented with only two, but again, let me be consistent): one to the intended cell and two to the cells in orthogonal directions.

### Reward signal: Carrots and sticks

The reward[](/book/grokking-deep-reinforcement-learning/chapter-2/) function[](/book/grokking-deep-reinforcement-learning/chapter-2/) *r* maps a transition tuple *s, a, s'* to a scalar[](/book/grokking-deep-reinforcement-learning/chapter-2/). The reward function gives a numeric signal of goodness to transitions. When the signal is positive, we can think of the reward as an income[](/book/grokking-deep-reinforcement-learning/chapter-2/) or a reward. Most problems have at least one positive signal—winning a chess match or reaching the desired destination, for example. But, rewards can also be negative, and we can see these as cost[](/book/grokking-deep-reinforcement-learning/chapter-2/), punishment[](/book/grokking-deep-reinforcement-learning/chapter-2/), or penalty[](/book/grokking-deep-reinforcement-learning/chapter-2/). In robotics, adding a time step cost[](/book/grokking-deep-reinforcement-learning/chapter-2/) is a common practice because we usually want to reach a goal, but within a number of time steps. One thing to clarify is that whether positive or negative, the scalar coming out of the reward function is always referred to as the *reward*. RL folks are happy folks.

It’s also important to highlight that while the reward function can be represented as *R(s,a,s')*, which is explicit, we could also use *R(s,a),* or even *R(s)*, depending on our needs. Sometimes rewarding the agent based on state is what we need; sometimes it makes more sense to use the action and the state. However, the most explicit way to represent the reward function is to use a state, action, and next state triplet. With that, we can compute the marginalization over next states in *R(s,a,s')* to obtain *R(s,a)*, and the marginalization over actions in *R(s,a)* to get *R(s)*. But, once we’re in *R(s)* we can’t recover *R(s,a)* or *R(s,a,s'),* and once we’re in *R(s,a)* we can’t recover *R(s,a,s')*.

|   | Show Me The Math The reward function |
| --- | --- |
|  |  |

In the FL environment, the reward function is +1 for landing in state 15, 0 otherwise. Again, for clarity to the following image, I’ve only added the reward signal to transitions that give a non-zero reward, landing on the final state (state 15.)

There are only three ways to land on 15. (1) Selecting the Right action in state 14 will transition the agent with 33.3% chance there (33.3% to state 10 and 33.3% back to 14). But, (2) selecting the Up and (3) the Down action from state 14 will unintentionally also transition the agent there with 33.3% probability for each action. See the difference between actions and transitions? It’s interesting to see how stochasticity complicates things, right?

![Reward signal for states with non-zero reward transitions](https://drek4537l1klr.cloudfront.net/morales/Figures/02_14.png)

Expanding the transition and reward functions into a table form is also useful. The following is the format I recommend for most problems. Notice that I’ve only added a subset of the transitions (rows) to the table to illustrate the exercise. Also notice that I’m being explicit, and several of these transitions could be grouped and refactored (for example, corner cells).

| State | Action | Next state | Transition probability | Reward signal |
| --- | --- | --- | --- | --- |
| 0 | Left | 0 | 0.33 | 0 |
| 0 | Left | 0 | 0.33 | 0 |
| 0 | Left | 4 | 0.33 | 0 |
| 0 | Down | 0 | 0.33 | 0 |
| 0 | Down | 4 | 0.33 | 0 |
| 0 | Down | 1 | 0.33 | 0 |
| 0 | Right | 4 | 0.33 | 0 |
| 0 | Right | 1 | 0.33 | 0 |
| 0 | Right | 0 | 0.33 | 0 |
| 0 | Up | 1 | 0.33 | 0 |
| 0 | Up | 0 | 0.33 | 0 |
| 0 | Up | 0 | 0.33 | 0 |
| 1 | Left | 1 | 0.33 | 0 |
| 1 | Left | 0 | 0.33 | 0 |
| 1 | Left | 5 | 0.33 | 0 |
| 1 | Down | 0 | 0.33 | 0 |
| 1 | Down | 5 | 0.33 | 0 |
| 1 | Down | 2 | 0.33 | 0 |
| 1 | Right | 5 | 0.33 | 0 |
| 1 | Right | 2 | 0.33 | 0 |
| 1 | Right | 1 | 0.33 | 0 |
| 2 | Left | 1 | 0.33 | 0 |
| 2 | Left | 2 | 0.33 | 0 |
| 2 | Left | 6 | 0.33 | 0 |
| 2 | Down | 1 | 0.33 | 0 |
| ... | ... | ... | ... | ... |
| 14 | Down | 14 | 0.33 | 0 |
| 14 | Down | 15 | 0.33 | 1 |
| 14 | Right | 14 | 0.33 | 0 |
| 14 | Right | 15 | 0.33 | 1 |
| 14 | Right | 10 | 0.33 | 0 |
| 14 | Up | 15 | 0.33 | 1 |
| 14 | Up | 10 | 0.33 | 0 |
| ... | ... | ... | ... | ... |
| 15 | Left | 15 | 1.0 | 0 |
| 15 | Down | 15 | 1.0 | 0 |
| 15 | Right | 15 | 1.0 | 0 |
| 15 | Up | 15 | 1.0 | 0 |

### Horizon: Time changes what’s optimal

We can represent time in MDPs[](/book/grokking-deep-reinforcement-learning/chapter-2/) as well. A *time step*[](/book/grokking-deep-reinforcement-learning/chapter-2/), also referred to as epoch, cycle, iteration, or even interaction, is a global clock syncing all parties and discretizing time. Having a clock gives rise to a couple of possible types of tasks. An *episodic* task[](/book/grokking-deep-reinforcement-learning/chapter-2/)[](/book/grokking-deep-reinforcement-learning/chapter-2/) is a task in which there’s a finite number of time steps, either because the clock stops or because the agent reaches a terminal state. There are also continuing tasks[](/book/grokking-deep-reinforcement-learning/chapter-2/)[](/book/grokking-deep-reinforcement-learning/chapter-2/), which are tasks that go on forever; there are no terminal states, so there’s an infinite number of time steps. In this type of task, the agent must be stopped manually.

Episodic and continuing tasks can also be defined from the agent’s perspective. We call it the *planning horizon[](/book/grokking-deep-reinforcement-learning/chapter-2/)*. On the one hand, a *finite horizon*[](/book/grokking-deep-reinforcement-learning/chapter-2/) is a planning horizon in which the agent knows the task will terminate in a finite number of time steps: if we forced the agent to complete the frozen lake environment in 15 steps, for example. A special case of this kind of planning horizon is called a *greedy horizon*[](/book/grokking-deep-reinforcement-learning/chapter-2/), of which the planning horizon is one. The BW and BSW have both a greedy planning horizon: the episode terminates immediately after one interaction. In fact, all bandit environments have greedy horizons.

On the other hand, an *infinite horizon*[](/book/grokking-deep-reinforcement-learning/chapter-2/) is when the agent doesn’t have a predetermined time step limit, so the agent plans for an infinite number of time steps[](/book/grokking-deep-reinforcement-learning/chapter-2/). Such a task may still be episodic and therefore terminate, but from the perspective of the agent, its planning horizon is infinite. We refer to this type of infinite planning horizon task as an *indefinite horizon*[](/book/grokking-deep-reinforcement-learning/chapter-2/) task. The agent plans for infinite, but interactions may be stopped at any time by the environment.

For tasks in which there’s a high chance the agent gets stuck in a loop and never terminates, it’s common practice to add an artificial terminal state[](/book/grokking-deep-reinforcement-learning/chapter-2/)[](/book/grokking-deep-reinforcement-learning/chapter-2/) based on the time step: a hard time step limit using the transition function. These cases require special handling of the time step limit terminal state. The environment for chapters 8, 9, and 10, the cart pole environment, has this kind of artificial terminal step, and you’ll learn to handle these special cases in those chapters.

The BW, BSW, and FL environment are episodic tasks, because there are terminal states; there are a clear goal and failure states. FL is an indefinite planning horizon; the agent plans for infinite number of steps, but interactions may stop at any time. We won’t add a time step limit to the FL environment because there’s a high chance the agent will terminate naturally; the environment is highly stochastic. This kind of task is the most common in RL.

We refer to the sequence of consecutive time steps from the beginning to the end of an episodic task as an *episode[](/book/grokking-deep-reinforcement-learning/chapter-2/)*, *trial*, *period[](/book/grokking-deep-reinforcement-learning/chapter-2/)*, or *stage[](/book/grokking-deep-reinforcement-learning/chapter-2/)*. In indefinite planning horizons, an episode is a collection containing all interactions between an initial and a terminal state.

### Discount: The future is uncertain, value it less

Because of the possibility of infinite sequences of time steps in infinite horizon tasks, we need a way to discount the value of rewards over time; that is, we need a way to tell the agent that getting +1’s is better sooner than later. We commonly use a positive real value less than one to exponentially discount the value of future rewards. The further into the future we receive the reward, the less valuable it is in the present.

This number is called the *discount factor[](/book/grokking-deep-reinforcement-learning/chapter-2/)[](/book/grokking-deep-reinforcement-learning/chapter-2/),* or *gamma[](/book/grokking-deep-reinforcement-learning/chapter-2/)*. The discount factor adjusts the importance of rewards over time. The later we receive rewards, the less attractive they are to present calculations. Another important reason why the discount factor is commonly used is to reduce the variance of return estimates. Given that the future is uncertain, and that the further we look into the future, the more stochasticity we accumulate and the more variance our value estimates will have, the discount factor helps reduce the degree to which future rewards affect our value function estimates, which stabilizes learning for most agents.

![Effect of discount factor and time on the value of rewards](https://drek4537l1klr.cloudfront.net/morales/Figures/02_15.png)

Interestingly, gamma is part of the MDP definition: the problem, and not the agent. However, often you’ll find no guidance for the proper value of gamma to use for a given environment. Again, this is because gamma is also used as a hyperparameter for reducing variance, and therefore left for the agent to tune.

You can also use gamma as a way to give a sense of “urgency” to the agent. To wrap your head around that, imagine that I tell you I’ll give you $1,000 once you finish reading this book, but I’ll discount (gamma) that reward by 0.5 daily. This means that every day I cut the value that I pay in half. You’ll probably finish reading this book today. If I say gamma is 1, then it doesn’t matter when you finish it, you still get the full amount.

For the BW[](/book/grokking-deep-reinforcement-learning/chapter-2/) and BSW[](/book/grokking-deep-reinforcement-learning/chapter-2/) environments, a gamma of 1 is appropriate; for the FL[](/book/grokking-deep-reinforcement-learning/chapter-2/) environment, however, we’ll use a gamma of 0.99, a commonly used value.

|   | Show Me The Math The discount factor (gamma) |
| --- | --- |
|  |  |

### Extensions to MDPs

There are many extensions to the MDP[](/book/grokking-deep-reinforcement-learning/chapter-2/) framework, as we’ve discussed. They allow us to target slightly different types of RL problems. The following list isn’t comprehensive, but it should give you an idea of how large the field is. Know that the acronym MDPs is often used to refer to all types of MDPs. We’re currently looking only at the tip of the iceberg:

- Partially observable Markov decision process (POMDP): When the agent cannot fully observe the environment state
- Factored Markov decision process (FMDP[](/book/grokking-deep-reinforcement-learning/chapter-2/)[](/book/grokking-deep-reinforcement-learning/chapter-2/)[](/book/grokking-deep-reinforcement-learning/chapter-2/)): Allows the representation of the transition and reward function more compactly so that we can represent large MDPs
- Continuous [Time|Action|State] Markov decision process: When either time, action, state or any combination of them are continuous
- Relational Markov decision process (RMDP[](/book/grokking-deep-reinforcement-learning/chapter-2/)[](/book/grokking-deep-reinforcement-learning/chapter-2/)[](/book/grokking-deep-reinforcement-learning/chapter-2/)): Allows the combination of probabilistic and relational knowledge
- Semi-Markov decision process (SMDP[](/book/grokking-deep-reinforcement-learning/chapter-2/)[](/book/grokking-deep-reinforcement-learning/chapter-2/)[](/book/grokking-deep-reinforcement-learning/chapter-2/)): Allows the inclusion of abstract actions that can take multiple time steps to complete
- Multi-agent Markov decision process (MMDP[](/book/grokking-deep-reinforcement-learning/chapter-2/)[](/book/grokking-deep-reinforcement-learning/chapter-2/)[](/book/grokking-deep-reinforcement-learning/chapter-2/)): Allows the inclusion of multiple agents in the same environment
- Decentralized Markov decision process (Dec-MDP): Allows for multiple agents to collaborate and maximize a common reward

|   | I Speak Python [](/book/grokking-deep-reinforcement-learning/chapter-2/)The bandit walk (BW) MDP |
| --- | --- |
|  |  |

|   | I Speak Python [](/book/grokking-deep-reinforcement-learning/chapter-2/)The bandit slippery walk (BSW) MDP |
| --- | --- |
|  |  |

|   | I Speak Python [](/book/grokking-deep-reinforcement-learning/chapter-2/)The frozen lake (FL) MDP |
| --- | --- |
|  |  |

### Putting it all together

Unfortunately, when you go out to the real world, you’ll find many different ways that MDPs are defined. Moreover, certain sources describe POMDPs and refer to them as MDPs without full disclosure. All of this creates confusion to newcomers, so I have a few points to clarify for you going forward. First, what you saw previously as Python code isn’t a complete MDP, but instead only the transition functions and reward signals. From these, we can easily infer the state and action spaces. These code snippets come from a few packages containing several environments I developed for this book, and the FL environment is part of the OpenAI Gym package mentioned in the first chapter. Several of the additional components of an MDP that are missing from the dictionaries above, such as the initial state distribution *S*θ that comes from the set of initial state *S*i, are handled internally by the Gym framework and not shown here. Further, other components, such as the discount factor *γ* and the horizon *H*, are not shown in the previous dictionary, and the OpenAI Gym framework doesn’t provide them to you. Like I said before, discount factors are commonly considered hyperparameters, for better or worse. And the horizon is often assumed to be infinity.

But don’t worry about this. First, to calculate optimal policies for the MDPs presented in this chapter (which we’ll do in the next chapter), we only need the dictionary shown previously containing the transition function and reward signal; from these, we can infer the state and action spaces, and I’ll provide you with the discount factors. We’ll assume horizons of infinity, and won’t need the initial state distribution. Additionally, the most crucial part of this chapter is to give you an awareness of the components of MDPs and POMDPs. Remember, you won’t have to do much more building of MDPs than what you’ve done in this chapter. Nevertheless, let me define MDPs and POMDPs so we’re in sync.

|   | Show Me The Math MDPs vs. POMDPs |
| --- | --- |
|  |  |

## Summary

Okay. I know this chapter is heavy on new terms, but that’s its intent. The best summary for this chapter is on the previous page, more specifically, the definition of an MDP. Take another look at the last two equations and try to remember what each letter means. Once you do so, you can be assured that you got what’s necessary out of this chapter to proceed.

At the highest level, a reinforcement learning problem is about the interactions between an agent and the environment in which the agent exists. A large variety of issues can be modeled under this setting. The Markov decision process is a mathematical framework for representing complex decision-making problems under uncertainty.

Markov decision processes (MDPs) are composed of a set of system states, a set of per-state actions, a transition function, a reward signal, a horizon, a discount factor, and an initial state distribution. States describe the configuration of the environment. Actions allow agents to interact with the environment. The transition function tells how the environment evolves and reacts to the agent’s actions. The reward signal encodes the goal to be achieved by the agent. The horizon and discount factor add a notion of time to the interactions.

The state space, the set of all possible states, can be infinite or finite. The number of variables that make up a single state, however, must be finite. States can be fully observable, but in a more general case of MDPs, a POMDP, the states are partially observable. This means the agent can’t observe the full state of the system, but can observe a noisy state instead, called an observation.

The action space is a set of actions that can vary from state to state. However, the convention is to use the same set for all states. Actions can be composed with more than one variable, just like states. Action variables may be discrete or continuous.

The transition function links a state (a next state) to a state-action pair, and it defines the probability of reaching that future state given the state-action pair. The reward signal, in its more general form, maps a transition tuple *s*, *a*, *s'* to scalar, and it indicates the goodness of the transition. Both the transition function and reward signal define the model of the environment and are assumed to be stationary, meaning probabilities stay the same throughout.

By now, you

- Understand the components of a reinforcement learning problem and how they interact with each other
- Recognize Markov decision processes and know what they are composed from and how they work
- Can represent sequential decision-making problems as MDPs

|   | Tweetable Feat Work on your own and share your findings |
| --- | --- |
|  | Here are several ideas on how to take what you have learned to the next level. If you’d like, share your results with the rest of the world, and make sure to check out what others have done, too. It’s a win-win situation, and hopefully, you’ll take advantage of it. <br>      <br>      **#gdrl_ch02_tf01:** Creating environments is a crucial skill that deserves a book of its own. How about you create a grid-world environment of your own? Here, look at the code for the walk environments in this chapter ([https://github.com/mimoralea/gym-walk](https://github.com/mimoralea/gym-walk)) and some other grid-world environments ([https://github.com/mimoralea/gym-aima](https://github.com/mimoralea/gym-aima), [https://github.com/mimoralea/gym-bandits](https://github.com/mimoralea/gym-bandits), [https://github.com/openai/gym/tree/master/gym/envs/toy_text](https://github.com/openai/gym/tree/master/gym/envs/toy_text)). Now, create a Python package with a new grid-world environment! Don’t limit yourself to simple move actions; you can create a ‘teleport’ action, or anything else. Also, maybe add creatures to the environment other than your agent. Maybe add little monsters that your agent needs to avoid. Get creative here. There’s so much you could do. <br>      **#gdrl_ch02_tf02:** Another thing to try is to create what is called a “Gym environment” for a simulation engine of your choosing. First, investigate what exactly is a “Gym environment.” Next, explore the following Python packages ([https://github.com/openai/mujoco-py](https://github.com/openai/mujoco-py), [https://github.com/openai/atari-py](https://github.com/openai/atari-py), [https://github.com/google-research/football](https://github.com/google-research/football), and many of the packages at [https://github.com/openai/gym/](https://github.com/openai/gym/)). Then, try to understand how others have exposed simulation engines as Gym environments. Finally, create a Gym environment for a simulation engine of your choosing. This is a challenging one! <br>      **#gdrl_ch02_tf03:** In every chapter, I’m using the final hashtag as a catchall hashtag. Feel free to use this one to discuss anything else that you worked on relevant to this chapter. There’s no more exciting homework than that which you create for yourself. Make sure to share what you set yourself to investigate and your results. <br>      Write a tweet with your findings, tag me @mimoralea (I’ll retweet), and use the particular hashtag from this list to help interested folks find your results. There are no right or wrong results; you share your findings and check others’ findings. Take advantage of this to socialize, contribute, and get yourself out there! We’re waiting for you! Here’s a tweet example: “Hey, @mimoralea. I created a blog post with a list of resources to study deep reinforcement learning. Check it out at <link>. #gdrl_ch01_tf01” I’ll make sure to retweet and help others find your work. |
