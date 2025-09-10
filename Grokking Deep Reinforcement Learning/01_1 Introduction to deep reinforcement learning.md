# 1 Introduction to deep reinforcement learning

### In this chapter

- You will learn what deep reinforcement learning is and how it is different from other machine learning approaches.
- You will learn about the recent progress in deep reinforcement learning and what it can do for a variety of problems.
- You will know what to expect from this book and how to get the most out of it.

*I visualize a time when we will be to robots what dogs are to humans, and I’m rooting for the machines.*

— Claude Shannon
Father of the information age and contributor to the field of artificial intelligence

Humans naturally pursue feelings of happiness. From picking out our meals to advancing our careers, every action we choose is derived from our drive to experience rewarding moments in life. Whether these moments are self-centered pleasures or the more generous of goals, whether they bring us immediate gratification or long-term success, they’re still our perception of how important and valuable they are. And to some extent, these moments are the reason for our existence.

Our ability to achieve these precious moments seems to be correlated with intelligence; “intelligence” is defined as the ability to acquire and apply knowledge and skills. People who are deemed by society as intelligent are capable of trading not only immediate satisfaction for long-term goals, but also a good, certain future for a possibly better, yet uncertain, one. Goals that take longer to materialize and that have unknown long-term value are usually the hardest to achieve, and those who can withstand the challenges along the way are the exception, the leaders, the intellectuals of society.

In this book, you learn about an approach, known as deep reinforcement learning, involved with creating computer programs that can achieve goals that require intelligence. In this chapter, I introduce deep reinforcement learning and give suggestions to get the most out of this book.

## What is deep reinforcement learning?

*Deep reinforcement learning* (DRL[](/book/grokking-deep-reinforcement-learning/chapter-1/)) is a machine learning approach to artificial intelligence concerned with creating computer programs that can solve problems requiring intelligence. The distinct property of DRL programs is learning through trial and error from feedback that’s simultaneously sequential, evaluative, and sampled by leveraging powerful non-linear function approximation.

I want to unpack this definition for you one bit at a time. But, don’t get too caught up with the details because it’ll take me the whole book to get you grokking deep reinforcement learning. The following is the introduction to what you learn about in this book. As such, it’s repeated and explained in detail in the chapters ahead.

If I succeed with my goal for this book, after you complete it, you should understand this definition precisely. You should be able to tell why I used the words that I used, and why I didn’t use more or fewer words. But, for this chapter, simply sit back and plow through it.

### Deep reinforcement learning is a machine learning approach to artificial intelligence

*Artificial intelligence* (AI[](/book/grokking-deep-reinforcement-learning/chapter-1/)) is a branch of computer science involved in the creation of computer programs capable of demonstrating intelligence. Traditionally, any piece of software that displays cognitive abilities such as perception, search, planning, and learning is considered part of AI. Several examples of functionality produced by AI software[](/book/grokking-deep-reinforcement-learning/chapter-1/) are

- The pages returned by a search engine
- The route produced by a GPS app
- The voice recognition and the synthetic voice of smart-assistant software
- The products recommended by e-commerce sites
- The follow-me feature in drones

![Subfields of artificial intelligence](https://drek4537l1klr.cloudfront.net/morales/Figures/01_01.png)

All computer programs that display intelligence are considered AI, but not all examples of AI can learn. *Machine learning* (ML[](/book/grokking-deep-reinforcement-learning/chapter-1/)) is the area of AI concerned with creating computer programs that can solve problems requiring intelligence by learning from data. There are three main branches of[](/book/grokking-deep-reinforcement-learning/chapter-1/) ML: supervised, unsupervised, and reinforcement learning.

![Main branches of machine learning](https://drek4537l1klr.cloudfront.net/morales/Figures/01_02.png)

*Supervised learning* (SL[](/book/grokking-deep-reinforcement-learning/chapter-1/)[](/book/grokking-deep-reinforcement-learning/chapter-1/)) is the task of learning from labeled data[](/book/grokking-deep-reinforcement-learning/chapter-1/). In SL, a human decides which data to collect and how to label it. The goal in SL is to generalize. A classic example of SL is a handwritten-digit-recognition application[](/book/grokking-deep-reinforcement-learning/chapter-1/): a human gathers images with handwritten digits, labels those images, and trains a model to recognize and classify digits in images correctly. The trained model is expected to generalize and correctly classify handwritten digits in new images.

*Unsupervised learning* (UL[](/book/grokking-deep-reinforcement-learning/chapter-1/)) is the task of learning from unlabeled data[](/book/grokking-deep-reinforcement-learning/chapter-1/). Even though data no longer needs labeling, the methods used by the computer to gather data still need to be designed by a human. The goal in UL is to compress. A classic example of UL is a customer segmentation application; a human collects customer data and trains a model to group customers into clusters. These clusters compress the information, uncovering underlying relationships in customers.

*Reinforcement learning* (RL[](/book/grokking-deep-reinforcement-learning/chapter-1/)[](/book/grokking-deep-reinforcement-learning/chapter-1/)) is the task of learning through trial and error. In this type of task, no human labels data, and no human collects or explicitly designs the collection of data. The goal in RL is to act. A classic example of RL is a Pong-playing agent; the agent repeatedly interacts with a Pong emulator and learns by taking actions and observing their effects. The trained agent is expected to act in such a way that it successfully plays Pong.

A powerful recent approach to ML, called *deep learning* (DL[](/book/grokking-deep-reinforcement-learning/chapter-1/)[](/book/grokking-deep-reinforcement-learning/chapter-1/)), involves using multi-layered non-linear function approximation, typically neural networks. DL isn’t a separate branch of ML, so it’s not a different task than those described previously. DL is a collection of techniques and methods for using neural networks to solve ML tasks, whether SL, UL, or RL. DRL is simply the use of DL to solve RL tasks.

![Deep learning is a powerful toolbox](https://drek4537l1klr.cloudfront.net/morales/Figures/01_03.png)

The bottom line is that DRL is an approach to a problem. The field of AI defines the problem: creating intelligent machines. One of the approaches to solving that problem is DRL. Throughout the book, will you find comparisons between RL and other ML approaches, but only in this chapter will you find definitions and a historical overview of AI in general. It’s important to note that the field of RL includes the field of DRL, so although I make a distinction when necessary, when I refer to RL, remember that DRL is included.

### Deep reinforcement learning is concerned with creating computer programs

At its core, DRL is about complex sequential decision-making problems under uncertainty. But, this is a topic of interest in many fields; for instance, *control theory* (CT[](/book/grokking-deep-reinforcement-learning/chapter-1/)) studies ways to control complex known dynamic systems. In CT, the dynamics of the systems we try to control are usually known in advance. *Operations research* (OR[](/book/grokking-deep-reinforcement-learning/chapter-1/)), another instance, also studies decision-making under uncertainty, but problems in this field often have much larger action spaces than those commonly seen in DRL. *Psychology[](/book/grokking-deep-reinforcement-learning/chapter-1/)* studies human behavior, which is partly the same “complex sequential decision-making under uncertainty” problem.

![The synergy between similar fields](https://drek4537l1klr.cloudfront.net/morales/Figures/01_04.png)

The bottom line is that you have come to a field that’s influenced by a variety of others. Although this is a good thing, it also brings inconsistencies in terminologies, notations, and so on. My take is the computer science approach to this problem, so this book is about building computer programs that solve complex decision-making problems under uncertainty, and as such, you can find code examples throughout the book.

In DRL, these computer programs are called *agents[](/book/grokking-deep-reinforcement-learning/chapter-1/)*. An agent is a decision maker only and nothing else. That means if you’re training a robot to pick up objects, the robot arm isn’t part of the agent. Only the code that makes decisions is referred to as the agent.

### Deep reinforcement learning agents can solve problems that require intelligence

On the other side of the agent is the **environment**[](/book/grokking-deep-reinforcement-learning/chapter-1/). The environment is everything outside the agent; everything the agent has no total control over. Again, imagine you’re training a robot to pick up objects. The objects to be picked up, the tray where the objects lay, the wind, and everything outside the decision maker are part of the environment. That means the robot arm is also part of the environment because it isn’t part of the agent. And even though the agent can decide to move the arm, the actual arm movement is noisy, and thus the arm is part of the environment.

This strict boundary between the agent[](/book/grokking-deep-reinforcement-learning/chapter-1/)[](/book/grokking-deep-reinforcement-learning/chapter-1/) and the environment is counterintuitive at first, but the decision maker, the agent, can only have a single role: *making decisions*. Everything that comes after the decision gets bundled into the environment.

![Boundary between agent and environment](https://drek4537l1klr.cloudfront.net/morales/Figures/01_05.png)

Chapter 2 provides an in-depth survey of all the components of DRL. The following is a preview of what you’ll learn in chapter 2.

The environment is represented by a set of variables[](/book/grokking-deep-reinforcement-learning/chapter-1/)[](/book/grokking-deep-reinforcement-learning/chapter-1/) related to the problem. For instance, in the robotic arm example, the location and velocities of the arm would be part of the variables that make up the environment. This set of variables and all the possible values that they can take are referred to as the *state space*[](/book/grokking-deep-reinforcement-learning/chapter-1/). A state[](/book/grokking-deep-reinforcement-learning/chapter-1/) is an instantiation of the state space, a set of values the variables take.

Interestingly, often, agents don’t have access to the actual full state of the environment. The part of a state that the agent can observe is called an *observation[](/book/grokking-deep-reinforcement-learning/chapter-1/)*. Observations[](/book/grokking-deep-reinforcement-learning/chapter-1/)[](/book/grokking-deep-reinforcement-learning/chapter-1/) depend on states but are what the agent can see. For instance, in the robotic arm example, the agent may only have access to camera images. While an exact location of each object exists, the agent doesn’t have access to this specific state. Instead, the observations the agent perceives are derived from the states. You’ll often see in the literature *states* being used interchangeably, including in this book. I apologize in advance for the inconsistencies. Simply know the differences and be aware of the lingo; that’s what matters.

![States vs. observations](https://drek4537l1klr.cloudfront.net/morales/Figures/01_06.png)

At each state[](/book/grokking-deep-reinforcement-learning/chapter-1/), the environment[](/book/grokking-deep-reinforcement-learning/chapter-1/) makes available a set of actions[](/book/grokking-deep-reinforcement-learning/chapter-1/) the agent can choose from. The agent influences the environment through these actions. The environment may change states as a response to the agent’s action. The function that’s responsible for this mapping is called the *transition function*[](/book/grokking-deep-reinforcement-learning/chapter-1/). The environment may also provide a reward signal[](/book/grokking-deep-reinforcement-learning/chapter-1/) as a response. The function responsible for this mapping is called the *reward function*[](/book/grokking-deep-reinforcement-learning/chapter-1/). The set of transition[](/book/grokking-deep-reinforcement-learning/chapter-1/) and reward functions is referred to as the *model* of the environment[](/book/grokking-deep-reinforcement-learning/chapter-1/)[](/book/grokking-deep-reinforcement-learning/chapter-1/).

![The reinforcement learning cycle](https://drek4537l1klr.cloudfront.net/morales/Figures/01_07.png)

The environment commonly has a well-defined task[](/book/grokking-deep-reinforcement-learning/chapter-1/). The goal[](/book/grokking-deep-reinforcement-learning/chapter-1/) of this task is defined through the reward function. The reward-function signals can be simultaneously sequential[](/book/grokking-deep-reinforcement-learning/chapter-1/), evaluative[](/book/grokking-deep-reinforcement-learning/chapter-1/), and sampled[](/book/grokking-deep-reinforcement-learning/chapter-1/). To achieve the goal, the agent needs to demonstrate intelligence, or at least cognitive abilities commonly associated with intelligence, such as long-term thinking[](/book/grokking-deep-reinforcement-learning/chapter-1/), information gathering[](/book/grokking-deep-reinforcement-learning/chapter-1/), and generalization[](/book/grokking-deep-reinforcement-learning/chapter-1/).

The agent[](/book/grokking-deep-reinforcement-learning/chapter-1/) has a three-step process: the agent interacts with the environment, the agent evaluates its behavior, and the agent improves its responses. The agent can be designed to learn mappings from observations to actions called *policies**[](/book/grokking-deep-reinforcement-learning/chapter-1/)*. The agent can be designed to learn the model of the environment on mappings called *models**[](/book/grokking-deep-reinforcement-learning/chapter-1/)*. The agent can be designed to learn to estimate the reward-to-go on mappings called *value functions*[](/book/grokking-deep-reinforcement-learning/chapter-1/).

### Deep reinforcement learning agents improve their behavior through trial-and-error learning

The interactions between the agent[](/book/grokking-deep-reinforcement-learning/chapter-1/)[](/book/grokking-deep-reinforcement-learning/chapter-1/) and the environment go on for several cycles. Each cycle is called a *time step*[](/book/grokking-deep-reinforcement-learning/chapter-1/). At each time step, the agent observes the environment, takes action, and receives a new observation and reward. The set of the state, the action, the reward, and the new state is called an *experience[](/book/grokking-deep-reinforcement-learning/chapter-1/)*. Every experience has an opportunity for learning and improving performance.

![Experience tuples](https://drek4537l1klr.cloudfront.net/morales/Figures/01_08.png)

The task the agent is trying to solve may or may not have a natural ending. Tasks that have a natural ending, such as a game, are called *episodic tasks*[](/book/grokking-deep-reinforcement-learning/chapter-1/)[](/book/grokking-deep-reinforcement-learning/chapter-1/). Conversely, tasks that don’t are called *continuing tasks*[](/book/grokking-deep-reinforcement-learning/chapter-1/)[](/book/grokking-deep-reinforcement-learning/chapter-1/), such as learning forward motion. The sequence of time steps from the beginning to the end of an episodic task is called an *episode[](/book/grokking-deep-reinforcement-learning/chapter-1/)*. Agents may take several time steps and episodes to learn to solve a task. Agents learn through trial and error: they try something, observe, learn, try something else, and so on.

You’ll start learning more about this cycle in chapter 4, which contains a type of environment with a single step per episode. Starting with chapter 5, you’ll learn to deal with environments that require more than a single interaction cycle per episode.

### Deep reinforcement learning agents learn from sequential feedback

The action taken by the agent[](/book/grokking-deep-reinforcement-learning/chapter-1/)[](/book/grokking-deep-reinforcement-learning/chapter-1/)[](/book/grokking-deep-reinforcement-learning/chapter-1/)[](/book/grokking-deep-reinforcement-learning/chapter-1/) may have delayed consequences. The reward may be sparse and only manifest after several time steps. Thus the agent must be able to learn from sequential feedback. Sequential feedback gives rise to a problem referred to as the *temporal credit assignment problem*[](/book/grokking-deep-reinforcement-learning/chapter-1/). The temporal credit assignment problem is the challenge of determining which state and/or action is responsible for a reward. When there’s a temporal component to a problem, and actions have delayed consequences, it’s challenging to assign credit for rewards.

![The difficulty of the temporal credit assignment problem](https://drek4537l1klr.cloudfront.net/morales/Figures/01_09.png)

In chapter 3, we’ll study the ins and outs of sequential feedback in isolation. That is, your programs learn from simultaneously sequential, supervised (as opposed to evaluative), and exhaustive (as opposed to sampled) feedback.

### Deep reinforcement learning agents learn from evaluative feedback

The reward received by the agent[](/book/grokking-deep-reinforcement-learning/chapter-1/)[](/book/grokking-deep-reinforcement-learning/chapter-1/) may be weak, in the sense that it may provide no supervision. The reward may indicate goodness and not correctness, meaning it may contain no information about other potential rewards. Thus the agent must be able to learn from *evaluative feedback*. Evaluative feedback gives rise to the need for exploration. The agent must be able to balance the gathering of information with the exploitation of current information. This is also referred to as the *exploration versus exploitation trade-off*[](/book/grokking-deep-reinforcement-learning/chapter-1/).

![The difficulty of the exploration vs. exploitation trade-off](https://drek4537l1klr.cloudfront.net/morales/Figures/01_10.png)

In chapter 4, we’ll study the ins and outs of evaluative feedback in isolation. That is, your programs will learn from feedback that is simultaneously one-shot (as opposed to sequential), evaluative, and exhaustive (as opposed to sampled).

### Deep reinforcement learning agents learn from sampled feedback

The reward[](/book/grokking-deep-reinforcement-learning/chapter-1/)[](/book/grokking-deep-reinforcement-learning/chapter-1/) received by the agent is merely a sample, and the agent doesn’t have access to the reward function. Also, the state and action spaces are commonly large, even infinite, so trying to learn from sparse and weak feedback becomes a harder challenge with samples. Therefore, the agent must be able to learn from sampled feedback, and it must be able to generalize.

![The difficulty of learning from sampled feedback](https://drek4537l1klr.cloudfront.net/morales/Figures/01_11.png)

Agents that are designed to approximate policies are called *policy-based*[](/book/grokking-deep-reinforcement-learning/chapter-1/)[](/book/grokking-deep-reinforcement-learning/chapter-1/); agents that are designed to approximate value functions are called *value-based*[](/book/grokking-deep-reinforcement-learning/chapter-1/)[](/book/grokking-deep-reinforcement-learning/chapter-1/); agents that are designed to approximate models are called *model-based*[](/book/grokking-deep-reinforcement-learning/chapter-1/)[](/book/grokking-deep-reinforcement-learning/chapter-1/); and agents that are designed to approximate both policies and value functions are called *actor-critic*[](/book/grokking-deep-reinforcement-learning/chapter-1/)[](/book/grokking-deep-reinforcement-learning/chapter-1/). Agents can be designed to approximate one or more of these components.

### Deep reinforcement learning agents use powerful non-linear function approximation

The agent[](/book/grokking-deep-reinforcement-learning/chapter-1/)[](/book/grokking-deep-reinforcement-learning/chapter-1/)[](/book/grokking-deep-reinforcement-learning/chapter-1/) can approximate functions using a variety of ML methods and techniques, from decision trees to SVMs to neural networks. However, in this book, we use only neural networks[](/book/grokking-deep-reinforcement-learning/chapter-1/); this is what the “deep” part of DRL refers to, after all. Neural networks aren’t necessarily the best solution to every problem; neural networks are data hungry and challenging to interpret, and you must keep these facts in mind. However, neural networks are among the most potent function approximations available, and their performance is often the best.

![A simple feed-forward neural network](https://drek4537l1klr.cloudfront.net/morales/Figures/01_12.png)

*Artificial neural networks* (ANN[](/book/grokking-deep-reinforcement-learning/chapter-1/)[](/book/grokking-deep-reinforcement-learning/chapter-1/)) are multi-layered non-linear function approximators loosely inspired by the biological neural networks in animal brains. An ANN isn’t an algorithm, but a structure composed of multiple layers of mathematical transformations applied to input values.

From chapter 3 through chapter 7, we only deal with problems in which agents learn from exhaustive (as opposed to sampled) feedback. Starting with chapter 8, we study the full DRL problem; that is, using deep neural networks so that agents can learn from sampled feedback. Remember, DRL agents learn from feedback that’s simultaneously sequential, evaluative, and sampled.

## The past, present, and future of deep reinforcement learning

History isn’t necessary to gain skills, but it can allow you to understand the context around a topic, which in turn can help you gain motivation, and therefore, skills. The history of AI and DRL should help you set expectations about the future of this powerful technology. At times, I feel the hype surrounding AI is actually productive; people get interested. But, right after that, when it’s time to put in work, hype no longer helps, and it’s a problem. Although I’d like to be excited about AI, I also need to set realistic expectations.

### Recent history of artificial intelligence and deep reinforcement learning

The beginnings[](/book/grokking-deep-reinforcement-learning/chapter-1/) of DRL could be traced back many years, because humans have been intrigued by the possibility of intelligent creatures other than ourselves since antiquity. But a good beginning could be Alan Turing’s[](/book/grokking-deep-reinforcement-learning/chapter-1/) work in the 1930s, 1940s, and 1950s that paved the way for modern computer science and AI by laying down critical theoretical foundations that later scientists leveraged.

The most well-known of these is the Turing Test[](/book/grokking-deep-reinforcement-learning/chapter-1/), which proposes a standard for measuring machine intelligence: if a human interrogator is unable to distinguish a machine from another human on a chat Q&A session, then the computer is said to count as intelligent. Though rudimentary, the Turing Test allowed generations to wonder about the possibilities of creating smart machines by setting a goal that researchers could pursue.

The formal beginnings of AI as an academic discipline can be attributed to John McCarthy[](/book/grokking-deep-reinforcement-learning/chapter-1/), an influential AI researcher who made several notable contributions to the field. To name a few, McCarthy is credited with coining the term “artificial intelligence” in 1955, leading the first AI conference in 1956, inventing the Lisp programming language in 1958, cofounding the MIT AI Lab in 1959, and contributing important papers to the development of AI as a field over several decades.

### Artificial intelligence winters

All the work and progress of AI early on created a great deal of excitement, but there were also significant setbacks. Prominent AI researchers suggested we would create human-like machine intelligence within years, but this never came. Things got worse when a well-known researcher named James Lighthill[](/book/grokking-deep-reinforcement-learning/chapter-1/) compiled a report criticizing the state of academic research in AI. All of these developments contributed to a long period of reduced funding and interest in AI research known as the first *AI winter*.

The field continued this pattern throughout the years: researchers making progress, people getting overly optimistic, then overestimating—leading to reduced funding by government and industry partners.

![Al funding pattern through the years](https://drek4537l1klr.cloudfront.net/morales/Figures/01_13.png)

### The current state of artificial intelligence

We are likely[](/book/grokking-deep-reinforcement-learning/chapter-1/) in another highly optimistic time in AI history, so we must be careful. Practitioners understand that AI is a powerful tool, but certain people think of AI as this magic black box that can take any problem in and out comes the best solution ever. Nothing can be further from the truth. Other people even worry about AI gaining consciousness, as if that was relevant, as Edsger W. Dijkstra[](/book/grokking-deep-reinforcement-learning/chapter-1/) famously said: “The question of whether a computer can think is no more interesting than the question of whether a submarine can swim.”

But, if we set aside this Hollywood-instilled vision of AI, we can allow ourselves to get excited about the recent progress in this field. Today, the most influential companies in the world make the most substantial investments to AI research. Companies such as Google, Facebook, Microsoft, Amazon, and Apple have invested in AI research and have become highly profitable thanks, in part, to AI systems. Their significant and steady investments have created the perfect environment for the current pace of AI research. Contemporary researchers have the best computing power available and tremendous amounts of data for their research, and teams of top researchers are working together, on the same problems, in the same location, at the same time. Current AI research has become more stable and more productive. We have witnessed one AI success after another, and it doesn’t seem likely to stop anytime soon.

### Progress in deep reinforcement learning

The use of artificial[](/book/grokking-deep-reinforcement-learning/chapter-1/) neural networks for RL problems started around the 1990s. One of the classics is the backgammon-playing computer program, TD-Gammon[](/book/grokking-deep-reinforcement-learning/chapter-1/), created by Gerald Tesauro[](/book/grokking-deep-reinforcement-learning/chapter-1/) et al. TD-Gammon learned to play backgammon[](/book/grokking-deep-reinforcement-learning/chapter-1/) by learning to evaluate table positions on its own through RL. Even though the techniques implemented aren’t precisely considered DRL, TD-Gammon was one of the first widely reported success stories using ANNs to solve complex RL problems.

![TD-Gammon architecture](https://drek4537l1klr.cloudfront.net/morales/Figures/01_14.png)

In 2004, Andrew Ng[](/book/grokking-deep-reinforcement-learning/chapter-1/) et al. developed an autonomous helicopter that taught itself to fly stunts by observing hours of human-experts flights. They used a technique known as *inverse reinforcement learning[](/book/grokking-deep-reinforcement-learning/chapter-1/),* in which an agent learns from expert demonstrations. The same year, Nate Kohl[](/book/grokking-deep-reinforcement-learning/chapter-1/) and Peter Stone[](/book/grokking-deep-reinforcement-learning/chapter-1/) used a class of DRL methods known as *policy-gradient methods*[](/book/grokking-deep-reinforcement-learning/chapter-1/) to develop a soccer-playing robot for the RoboCup tournament. They used RL to teach the agent forward motion. After only three hours of training, the robot achieved the fastest forward-moving speed of any robot with the same hardware.

There were other successes in the 2000s, but the field of DRL really only started growing after the DL field took off around 2010. In 2013 and 2015, Mnih[](/book/grokking-deep-reinforcement-learning/chapter-1/) et al. published a couple of papers presenting the DQN algorithm[](/book/grokking-deep-reinforcement-learning/chapter-1/). DQN learned to play Atari games from raw pixels. Using a convolutional neural network (CNN) and a single set of hyperparameters, DQN performed better than a professional human player in 22 out of 49 games.

![Atari DQN network architecture](https://drek4537l1klr.cloudfront.net/morales/Figures/01_15.png)

This accomplishment started a revolution in the DRL community: In 2014, Silver[](/book/grokking-deep-reinforcement-learning/chapter-1/) et al. released the deterministic policy gradient (DPG) algorithm, and a year later Lillicrap[](/book/grokking-deep-reinforcement-learning/chapter-1/) et al. improved it with deep deterministic policy gradient (DDPG). In 2016, Schulman[](/book/grokking-deep-reinforcement-learning/chapter-1/) et al. released trust region policy optimization (TRPO)[](/book/grokking-deep-reinforcement-learning/chapter-1/) and generalized advantage estimation (GAE) methods[](/book/grokking-deep-reinforcement-learning/chapter-1/), Sergey Levine[](/book/grokking-deep-reinforcement-learning/chapter-1/) et al. published Guided Policy Search (GPS)[](/book/grokking-deep-reinforcement-learning/chapter-1/), and Silver et al. demoed AlphaGo[](/book/grokking-deep-reinforcement-learning/chapter-1/). The following year, Silver et al. demonstrated AlphaZero[](/book/grokking-deep-reinforcement-learning/chapter-1/). Many other algorithms were released during these years: double deep Q-networks (DDQN), prioritized experience replay (PER), proximal policy optimization (PPO), actor-critic with experience replay (ACER), asynchronous advantage actor-critic (A3C), advantage actor-critic (A2C), actor-critic using Kronecker-factored trust region (ACKTR), Rainbow, Unicorn (these are actual names, BTW), and so on. In 2019, Oriol Vinyals[](/book/grokking-deep-reinforcement-learning/chapter-1/) et al. showed the AlphaStar agent[](/book/grokking-deep-reinforcement-learning/chapter-1/) beat professional players at the game of StarCraft II. And a few months later, Jakub Pachocki[](/book/grokking-deep-reinforcement-learning/chapter-1/) et al. saw their team of Dota-2-playing bots, called Five, become the first AI to beat the world champions in an e-sports game.

Thanks to the progress in DRL, we’ve gone in two decades from solving backgammon, with its 1020 perfect-information states, to solving the game of Go[](/book/grokking-deep-reinforcement-learning/chapter-1/), with its 10170 perfect-information states, or better yet, to solving StarCraft II[](/book/grokking-deep-reinforcement-learning/chapter-1/), with its 10270 imperfect-information states. It’s hard to conceive a better time to enter the field. Can you imagine what the next two decades will bring us? Will you be part of it? DRL is a booming field, and I expect its rate of progress to continue.

![Game of Go: enormous branching factor](https://drek4537l1klr.cloudfront.net/morales/Figures/01_16.png)

### Opportunities ahead

I believe AI[](/book/grokking-deep-reinforcement-learning/chapter-1/) is a field with unlimited potential for positive change, regardless of what fear-mongers say. Back in the 1750s, there was chaos due to the start of the industrial revolution. Powerful machines were replacing repetitive manual labor and mercilessly displacing humans. Everybody was concerned: machines that can work faster, more effectively, and more cheaply than humans? These machines will take all our jobs! What are we going to do for a living now? And it happened. But the fact is that many of these jobs were not only unfulfilling, but also dangerous.

One hundred years after the industrial revolution, the long-term effects of these changes were benefiting communities. People who usually owned only a couple of shirts and a pair of pants could get much more for a fraction of the cost. Indeed, change was difficult, but the long-term effects benefited the entire world.

The digital revolution started in the 1970s with the introduction of personal computers. Then, the internet changed the way we do things. Because of the internet, we got big data and cloud computing. ML used this fertile ground for sprouting into what it is today. In the next couple of decades, the changes and impact of AI on society may be difficult to accept at first, but the long-lasting effects will be far superior to any setback along the way. I expect in a few decades humans won’t even need to work for food, clothing, or shelter because these things will be automatically produced by AI. We’ll thrive with abundance.

![Workforce revolutions](https://drek4537l1klr.cloudfront.net/morales/Figures/01_17.png)

As we continue to push the intelligence of machines to higher levels, certain AI researchers think we might find an AI with intelligence superior to our own. At this point, we unlock a phenomenon known as the *singularity[](/book/grokking-deep-reinforcement-learning/chapter-1/)*; an AI more intelligent than humans allows for the improvement of AI at a much faster pace, given that the self-improvement cycle no longer has the bottleneck, namely, humans. But we must be prudent, because this is more of an ideal than a practical aspect to worry about.

![Singularity could be a few decades away](https://drek4537l1klr.cloudfront.net/morales/Figures/01_18.png)

While one must be always aware of the implications of AI and strive for AI safety, the singularity isn’t an issue today. On the other hand, many issues exist with the current state of DRL, as you’ll see in this book. These issues make better use of our time.

## The suitability of deep reinforcement learning

You could formulate any ML problem as a DRL problem, but this isn’t always a good idea for multiple reasons. You should know the pros and cons of using DRL in general, and you should be able to identify what kinds of problems and settings DRL is good and not so good for.

### What are the pros and cons?

Beyond a technological comparison, I’d like you to think about the inherent advantages and disadvantages of using DRL for your next project. You’ll see that each of the points highlighted can be either a pro or a con depending on what kind of problem you’re trying to solve. For instance, this field is about letting the machine take control. Is this good or bad? Are you okay with letting the computer make the decisions for you? There’s a reason why DRL research environments of choice are games: it could be costly and dangerous to have agents training directly in the real world. Can you imagine a self-driving car agent learning not to crash by crashing? In DRL, the agents will have to make mistakes. Can you afford that? Are you willing to risk the negative consequences—actual harm—to humans? Considered these questions before starting your next DRL project.

![Deep reinforcement learning agents will explore! Can you afford mistakes?](https://drek4537l1klr.cloudfront.net/morales/Figures/01_19.png)

You’ll also need to consider how your agent will explore its environment. For instance, most value-based methods explore by randomly selecting an action. But other methods can have more strategic exploration strategies. Now, there are pros and cons to each, and this is a trade-off you’ll have to become familiar with.

Finally, training from scratch every time can be daunting, time consuming, and resource intensive. However, there are a couple of areas that study how to bootstrap previously acquired knowledge. First, there’s *transfer learning***,**[](/book/grokking-deep-reinforcement-learning/chapter-1/) which is about transferring knowledge gained in tasks to new ones. For example, if you want to teach a robot to use a hammer and a screwdriver, you could reuse low-level actions learned on the “pick up the hammer” task and apply this knowledge to start learning the “pick up the screwdriver” task. This should make intuitive sense to you, because humans don’t have to relearn low-level motions each time they learn a new task. Humans seem to form hierarchies of actions as we learn. The field of *hierarchical reinforcement learning*[](/book/grokking-deep-reinforcement-learning/chapter-1/) tries to replicate this in DRL agents.

### Deep reinforcement learning’s strengths

DRL is about mastering[](/book/grokking-deep-reinforcement-learning/chapter-1/) specific tasks. Unlike SL, in which generalization is the goal, RL is good at concrete, well-specified tasks. For instance, each Atari game has a particular task. DRL agents aren’t good at generalizing behavior across different tasks; it’s not true that because you train an agent to play Pong, this agent can also play Breakout. And if you naively try to teach your agent Pong and Breakout simultaneously, you’ll likely end up with an agent that isn’t good at either. SL, on the other hand, is pretty good a classifying multiple objects at once. The point is the strength of DRL is well-defined single tasks.

In DRL, we use generalization techniques to learn simple skills directly from raw sensory input. The performance of generalization techniques, new tips, and tricks on training deeper networks, and so on, are some of the main improvements we’ve seen in recent years. Lucky for us, most DL advancements directly enable new research paths in DRL.

### Deep reinforcement learning’s weaknesses

Of course, DRL[](/book/grokking-deep-reinforcement-learning/chapter-1/) isn’t perfect. One of the most significant issues you’ll find is that in most problems, agents need millions of samples to learn well-performing policies. Humans, on the other hand, can learn from a few interactions. Sample efficiency[](/book/grokking-deep-reinforcement-learning/chapter-1/) is probably one of the top areas of DRL that could use improvements. We’ll touch on this topic in several chapters because it’s a crucial one.

![Deep reinforcement learning agents need lots of interaction samples!](https://drek4537l1klr.cloudfront.net/morales/Figures/01_20.png)

Another issue with DRL is with reward functions[](/book/grokking-deep-reinforcement-learning/chapter-1/) and understanding the meaning of rewards. If a human expert will define the rewards the agent is trying to maximize, does that mean that we’re somewhat “supervising” this agent? And is this something good? Should the reward be as dense as possible, which makes learning faster, or as sparse as possible, which makes the solutions more exciting and unique?

We, as humans, don’t seem to have explicitly defined rewards. Often, the same person can see an event as positive or negative by simply changing their perspective. Additionally, a reward function for a task such as walking isn’t straightforward to design. Is it the forward motion that we should target, or is it not falling? What is the “perfect” reward function for a human walk?!

There’s ongoing interesting research on reward signals. One I’m particularly interested in is called *intrinsic motivation*[](/book/grokking-deep-reinforcement-learning/chapter-1/). Intrinsic motivation allows the agent to explore new actions just for the sake of it, out of curiosity. Agents that use intrinsic motivation show improved learning performance in environments with sparse rewards, which means we get to keep exciting and unique solutions. The point is if you’re trying to solve a task that hasn’t been modeled or doesn’t have a distinct reward function, you’ll face challenges.

## Setting clear two-way expectations

Let’s now touch on another important point going forward. What to expect? Honestly, to me, this is very important. First, I want you to know what to expect from the book so there are no surprises later on. I don’t want people to think that from this book, they’ll be able to come up with a trading agent that will make them rich. Sorry, I wouldn’t be writing this book if it was that simple. I also expect that people who are looking to learn put in the necessary work. The fact is that learning will come from the combination of me putting in the effort to make concepts understandable and you putting in the effort to understand them. I did put in the effort. But, if you decide to skip a box you didn’t think was necessary, we both lose.

### What to expect from the book?

My goal for this book is to take you, an ML enthusiast, from no prior DRL experience to capable of developing state-of-the-art DRL algorithms. For this, the book is organized into roughly two parts. In chapters 3 through 7, you learn about agents that can learn from sequential and evaluative feedback, first in isolation, and then in interplay. In chapters 8 through 12, you dive into core DRL algorithms, methods, and techniques. Chapters 1 and 2 are about introductory concepts applicable to DRL in general, and chapter 13 has concluding remarks.

My goal for the first part (chapters 3 through 7) is for you to understand “tabular” RL. That is, RL problems that can be exhaustively sampled, problems in which there’s no need for neural networks or function approximation of any kind. Chapter 3 is about the sequential aspect of RL and the temporal credit assignment problem. Then, we’ll study, also in isolation, the challenge of learning from evaluative feedback and the exploration versus exploitation trade-off in chapter 4. Last, you learn about methods that can deal with these two challenges simultaneously. In chapter 5, you study agents that learn to estimate the results of fixed behavior. Chapter 6 deals with learning to improve behavior, and chapter 7 shows you techniques that make RL more effective and efficient.

My goal for the second part (chapters 8 through 12) is for you to grasp the details of core DRL algorithms. We dive deep into the details; you can be sure of that. You learn about the many different types of agents from value- and policy-based to actor-critic methods. In chapters 8 through 10, we go deep into value-based DRL. In chapter 11, you learn about policy-based DRL and actor-critic, and chapter 12 is about deterministic policy gradient (DPG) methods, soft actor-critic (SAC) and proximal policy optimization (PPO) methods.

The examples in these chapters are repeated throughout agents of the same type to make comparing and contrasting agents more accessible. You still explore fundamentally different kinds of problems, from small, continuous to image-based state spaces, and from discrete to continuous action spaces. But, the book’s focus isn’t about modeling problems, which is a skill of its own; instead, the focus is about solving already modeled environments.

![Comparison of different algorithmic approaches to deep reinforcement learning](https://drek4537l1klr.cloudfront.net/morales/Figures/01_21.png)

### How to get the most out of this book

There are a few things you need to bring to the table to come out grokking deep reinforcement learning. You need to bring a little prior basic knowledge of ML and DL. You need to be comfortable with Python code and simple math. And most importantly, you must be willing to put in the work.

I assume that the reader has a solid basic understanding of ML. You should know what ML is beyond what’s covered in this chapter; you should know how to train simple SL models, perhaps the Iris or Titanic datasets; you should be familiar with DL concepts such as tensors and matrices; and you should have trained at least one DL model, say a convolutional neural network (CNN) on the MNIST dataset.

This book is focused on DRL topics, and there’s no DL in isolation. There are many useful resources out there that you can leverage. But, again, you need a basic understanding; If you’ve trained a CNN before, then you’re fine. Otherwise, I highly recommend you follow a couple of DL tutorials before starting the second part of the book.

Another assumption I’m making is that the reader is comfortable with Python code. Python is a somewhat clear programming language that can be straightforward to understand, and people not familiar with it often get something out of merely reading it. Now, my point is that you should be comfortable with it, willing and looking forward to reading the code. If you don’t read the code, then you’ll miss out on a lot.

Likewise, there are many math equations in this book, and that’s a good thing. Math is the perfect language, and there’s nothing that can replace it. However, I’m asking people to be comfortable with math, willing to read, and nothing else. The equations I show are heavily annotated so that people “not into math” can still take advantage of the resources.

Finally, I’m assuming you’re willing to put in the work. By that I mean you really want to learn DRL. If you decide to skip the math boxes, or the Python snippets, or a section, or one page, or chapter, or whatever, you’ll miss out on a lot of relevant information. To get the most out of this book, I recommend you read the entire book front to back. Because of the different format, figures and sidebars are part of the main narrative in this book.

Also, make sure you run the book source code (the next section provides more details on how to do this), and play around and extend the code you find most interesting.

### Deep reinforcement learning development environment

Along with this[](/book/grokking-deep-reinforcement-learning/chapter-1/)[](/book/grokking-deep-reinforcement-learning/chapter-1/) book, you’re provided with a fully tested environment and code to reproduce my results. I created a Docker image and several Jupyter Notebooks so that you don’t have to mess around with installing packages and configuring software, or copying and pasting code. The only prerequisite is Docker. Please, go ahead and follow the directions at [https://github.com/mimoralea/gdrl](https://github.com/mimoralea/gdrl) on running the code. It’s pretty straightforward.

The code is written in Python, and I make heavy use of NumPy and PyTorch. I chose PyTorch[](/book/grokking-deep-reinforcement-learning/chapter-1/), instead of Keras, or TensorFlow, because I found PyTorch to be a “Pythonic” library. Using PyTorch feels natural if you have used NumPy, unlike TensorFlow, for instance, which feels like a whole new programming paradigm. Now, my intention is not to start a “PyTorch versus TensorFlow” debate. But, in my experience from using both libraries, PyTorch is a library much better suited for research and teaching.

DRL is about algorithms, methods, techniques, tricks, and so on, so it’s pointless for us to rewrite a NumPy or a PyTorch library. But, also, in this book, we write DRL algorithms from scratch; I’m not teaching you how to use a DRL library, such as Keras-RL, or Baselines, or RLlib. I want you to learn DRL, and therefore we write DRL code. In the years that I’ve been teaching RL, I’ve noticed those who write RL code are more likely to understand RL. Now, this isn’t a book on PyTorch either; there’s no separate PyTorch review or anything like that, just PyTorch code that I explain as we move along. If you’re somewhat familiar with DL concepts, you’ll be able to follow along with the PyTorch code I use in this book. Don’t worry, you don’t need a separate PyTorch resource before you get to this book. I explain everything in detail as we move along.

As for the environments we use for training the agents, we use the popular OpenAI Gym package[](/book/grokking-deep-reinforcement-learning/chapter-1/) and a few other libraries that I developed for this book. But we’re also not going into the ins and outs of Gym. Just know that Gym is a library that provides environments for training RL agents. Beyond that, remember our focus is the RL algorithms, the solutions, not the environments, or modeling problems, which, needless to say, are also critical.

Since you should be familiar with DL, I presume you know what a graphics processing unit (GPU)[](/book/grokking-deep-reinforcement-learning/chapter-1/) is. DRL architectures don’t need the level of computation commonly seen on DL models. For this reason, the use of a GPU, while a good thing, is not required. Conversely, unlike DL models, some DRL agents make heavy use of a central processing unit (CPU) and thread count. If you’re planning on investing in a machine, make sure to account for CPU power[](/book/grokking-deep-reinforcement-learning/chapter-1/) (well, technically, number of cores, not speed) as well. As you’ll see later, certain algorithms massively parallelize processing, and in those cases, it’s the CPU that becomes the bottleneck, not the GPU. However, the code runs fine in the container regardless of your CPU or GPU. But, if your hardware is severely limited, I recommend checking out cloud platforms. I’ve seen services, such as Google Colab, that offer DL hardware for free.

## Summary

Deep reinforcement learning is challenging because agents must learn from feedback that is simultaneously sequential, evaluative, and sampled. Learning from sequential feedback forces the agent to learn how to balance immediate and long-term goals. Learning from evaluative feedback makes the agent learn to balance the gathering and utilization of information. Learning from sampled feedback forces the agent to generalize from old to new experiences.

Artificial intelligence, the main field of computer science into which reinforcement learning falls, is a discipline concerned with creating computer programs that display human-like intelligence. This goal is shared across many other disciplines, such as control theory and operations research. Machine learning is one of the most popular and successful approaches to artificial intelligence. Reinforcement learning is one of the three branches of machine learning, along with supervised learning, and unsupervised learning. Deep learning, an approach to machine learning, isn’t tied to any specific branch, but its power helps advance the entire machine learning community.

Deep reinforcement learning is the use of multiple layers of powerful function approximators known as neural networks (deep learning) to solve complex sequential decision-making problems under uncertainty. Deep reinforcement learning has performed well in many control problems, but, nevertheless, it’s essential to have in mind that releasing human control for critical decision making shouldn’t be taken lightly. Several of the core needs in deep reinforcement learning are algorithms with better sample complexity, better-performing exploration strategies, and safe algorithms.

Still, the future of deep reinforcement learning is bright, and there are perhaps dangers ahead as the technology matures, but more importantly, there’s potential in this field, and you should feel excited and compelled to bring your best and embark on this journey. The opportunity to be part of a potential change this big happens only every few generations. You should be glad you’re living during these times. Now, let’s be part of it.

By now, you

- Understand what deep reinforcement learning is and how it compares with other machine learning approaches
- Are aware of the recent progress in the field of deep reinforcement learning, and intuitively understand that it has the potential to be applied to a wide variety of problems
- Have a sense as to what to expect from this book, and how to get the most out of it

|   | Tweetable Feat Work on your own and share your findings |
| --- | --- |
|  | At the end of every chapter, I’ll give several ideas on how to take what you’ve learned to the next level. If you’d like, share your results with the rest of the world, and make sure to check out what others have done, too. It’s a win-win situation, and hopefully, you’ll take advantage of it. <br>      <br>      **#gdrl_ch01_tf01:** Supervised, unsupervised, and reinforcement learning are essential machine learning branches. And while it’s crucial to know the differences, it’s equally important to know the similarities. Write a post analyzing how these different approaches compare and how they could be used together to solve an AI problem. All branches are going after the same goal: to create artificial general intelligence, it’s vital for all of us to better understand how to use the tools available. <br>      **#gdrl_ch01_tf02:** I wouldn’t be surprised if you don’t have a machine learning or computer science background, yet are still interested in what this book has to offer. One essential contribution is to post resources from other fields that study decision-making. Do you have an operations research background? Psychology, philosophy, or neuroscience background? Control theory? Economics? How about you create a list of resources, blog posts, YouTube videos, books, or any other medium and share it with the rest of us also studying decision-making? <br>      **#gdrl_ch01_tf03:** Part of the text in this chapter has information that could be better explained through graphics, tables, and other forms. For instance, I talked about the different types of reinforcement learning agents (value-based, policy-based, actor-critic, model-based, gradient-free). Why don’t you grab text that’s dense, distill the knowledge, and share your summary with the world? <br>      **#gdrl_ch01_tf04:** In every chapter, I’m using the final hashtag as a catchall hashtag. Feel free to use this one to discuss anything else that you worked on relevant to this chapter. There’s no more exciting homework than that which you create for yourself. Make sure to share what you set yourself to investigate and your results. <br>      Write a tweet with your findings, tag me @mimoralea (I’ll retweet), and use the particular hashtag from this list to help interested folks find your results. There are no right or wrong results; you share your findings and check others’ findings. Take advantage of this to socialize, contribute, and get yourself out there! We’re waiting for you! Here is a tweet example: “Hey, @mimoralea. I created a blog post with a list of resources to study deep reinforcement learning. Check it out at <link>. #gdrl_ch01_tf01” I’ll make sure to retweet and help others find your work. |
