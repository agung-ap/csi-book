# 6 Swarm intelligence: Ants

### This chapter covers

- Seeing and understanding what inspired swarm intelligence algorithms
- Solving problems with swarm intelligence algorithms
- Designing and implementing an ant colony optimization algorithm

## What is swarm intelligence?

Swarm [](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)intelligence algorithms are a subset of evolutionary algorithms that were discussed in chapter 5 and are also known as nature-inspired algorithms. As with the theory of evolution, the observation of the behavior of life forms in nature is the inspiration for the concepts behind swarm intelligence. When we observe the world around us, we see many life forms that are seemingly primitive and unintelligent as individuals, yet exhibit intelligent emergent behavior when acting in groups.

An example of these life forms is ants. A single ant can carry 10 to 50 times its own body weight and run 700 times its body length per minute. These are impressive qualities; however, when acting in a group, that single ant can accomplish much more. In a group, ants are able to build colonies; find and retrieve food; and even warn other ants, show recognition to other ants, and use peer pressure to influence others in the colony. They achieve these tasks by means of *pheromones*—essentially, perfumes that ants drop wherever they go. Other ants can sense these perfumes and change their behavior based on them. Ants have access to between 10 and 20 types of pheromones that can be used to communicate different intentions. Because individual ants use pheromones to indicate their intentions and needs, we can observe emergent intelligent behavior in groups of ants.

Figure 6.1 shows an example of ants working as a team to create a bridge between two points to enable other ants to carry out tasks. These tasks may be to retrieve food or materials for their colony.

![Figure 6.1 A group of ants working together to cross a chasm](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_F01_Hurbans.png)

An experiment based on real-life harvesting ants showed that they always converged to the shortest path between the nest and the food source. Figure 6.2 depicts the difference in the colony movement from the start to when ants have walked their paths and increased the pheromone intensity on those paths. This outcome was observed in a classical asymmetric bridge experiment with real ants. Notice that the ants converge to the shortest path after just eight minutes.

![Figure 6.2 Asymmetric bridge experiment](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_F02_Hurbans.png)

Ant colony optimization (ACO) algorithms simulate the emergent behavior shown in this experiment. In the case of finding the shortest path, the algorithm converges to a similar state, as observed with real ants.

Swarm intelligence algorithms are useful for solving optimization problems when several constraints need to be met in a specific problem space and an absolute best solution is difficult to find due to a vast number of possible solutions—some better and some worse. These problems represent the same class of problems that genetic algorithms aim to solve; the choice of algorithm depends on how the problem can be represented and reasoned about. We dive into the technicalities of optimization problems in particle swarm optimization in chapter 7. Swarm intelligence is useful in several real-world contexts, some of which are represented in figure 6.3.

![Figure 6.3 Problems addressed by swarm optimization](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_F03_Hurbans.png)

Given the general understanding of swarm intelligence in ants, the following sections explore specific implementations that are inspired by these concepts. The ant colony optimization algorithm is inspired by the behavior of ants moving between destinations, dropping pheromones, and acting on pheromones that they come across. The emergent behavior is ants converging to paths of least [](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)resistance.

## Problems applicable to ant colony optimization

Imagine [](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)that we are visiting a carnival that has many attractions to experience. Each attraction is located in a different area, with varying distances between attractions. Because we don’t feel like wasting time walking too much, we will attempt to find the shortest paths between all the attractions.

Figure 6.4 illustrates the attractions at a small carnival and the distances between them. Notice that taking different paths to the attractions involves different total lengths of travel.

![Figure 6.4 Carnival attractions and paths between them](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_F04_Hurbans.png)

The figure shows six attractions to visit, with 15 paths between them. This example should look familiar. This problem is represented by a fully connected graph, as described in chapter 2. The attractions are vertices or nodes, and the paths between attractions are edges. The following formula is used to calculate the number of edges in a fully connected graph. As the number of attractions gets larger, the number of edges explodes:

![](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_UN01_Hurbans.png)

Attractions have different distances between them. Figure 6.5 depicts the distance on each path between every attraction; it also shows a possible path between all attractions. Note that the lines in figure 6.5 showing the distances between the attractions are not drawn to scale.

![Figure 6.5 Distances between attractions and a possible path](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_F05_Hurbans.png)

If we spend some time analyzing the distances between all the attractions, we will find that figure 6.6 shows an optimal path between all the attractions. We visit the attractions in this sequence: swings, Ferris wheel, circus, carousel, balloons, and bumper cars.

![Figure 6.6 Distances between attractions and an optimal path](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_F06_Hurbans.png)

The small dataset with six attractions is trivial to solve by hand, but if we increase the number of attractions to 15, the number of possibilities explodes (figure 6.7). Suppose that the attractions are servers, and the paths are network connections. Smart algorithms are needed to solve these problems.

![Figure 6.7 A larger dataset of attractions and paths between them](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_F07_Hurbans.png)

#### Exercise: Find the shortest path in this carnival configuration by hand

![](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_UN02_Hurbans.png)

#### Solution: Find the shortest path in this carnival configuration by hand

![](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_UN03_Hurbans.png)

One way to solve this problem computationally is to attempt a brute-force approach: every combination of tours (a tour is a sequence of visits in which every attraction is visited once) of the attractions is generated and evaluated until the shortest total distance is found. Again, this solution may seem to be a reasonable solution, but in a large dataset, this computation is expensive and time-consuming. A brute-force approach with 48 attractions runs for tens of hours before finding an optimal [](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)solution.

## Representing state: What do paths and ants look like?

Given [](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)the Carnival Problem, we need to represent the data of the problem in a way that is suitable to be processed by the ant colony optimization algorithm. Because we have several attractions and all the distances between them, we can use a distance matrix to represent the problem space accurately and simply.

A *distance matrix* is a 2D array in which every index represents an entity; the related set is the distance between that entity and another entity. Similarly, each index in the list denotes a unique entity. This matrix is similar to the adjacency matrix that we dived into in chapter 2 (figure 6.8 and table 6.1).

![Figure 6.8 An example of the Carnival Problem](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_F08_Hurbans.png)

##### Table 6.1 Distances between attractions[(view table figure)](https://drek4537l1klr.cloudfront.net/hurbans/HighResolutionFigures/table_6-1.png)

|   | **Circus** | **Balloons** | **Bumper cars** | **Carousel** | **Swings** | **Ferris wheel** |
| --- | --- | --- | --- | --- | --- | --- |
| Circus | 0 | 8 | 7 | 4 | 6 | 4 |
| Balloon | 8 | 0 | 5 | 7 | 11 | 5 |
| Bumper cars | 7 | 5 | 0 | 9 | 6 | 7 |
| Carousel | 4 | 7 | 9 | 0 | 5 | 6 |
| Swings | 6 | 11 | 6 | 5 | 0 | 3 |
| Ferris wheel | 4 | 5 | 7 | 6 | 3 | 0 |

Pseudocode

The distances between attractions can be represented as a distance matrix, an array of arrays in which a reference to x, y in the array references the distance between attractions x and y. Notice that the distance between the same attraction will be 0 because it’s in the same position. This array can also be created programmatically by iterating through data from a file and creating each element:

![](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_UN04_Hurbans.png)

The next element to represent is the ants. Ants move to different attractions and leave pheromones behind. Ants also make a judgment about which attraction to visit next. Finally, ants have knowledge about their respective total distance traveled. Here are the basic properties of an ant (figure 6.9):

-  *Memory*—In the ACO algorithm, this is the list of attractions already visited.
-  *Best fitness*—This is the shortest total distance traveled across all attractions.
-  *Action*—Choose the next destination to visit, and drop pheromones along the way.

![Figure 6.9 Properties of an ant](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_F09_Hurbans.png)

Pseudocode

Although the abstract concept of an ant entails memory, best fitness, and action, specific data and functions are required to solve the Carnival Problem. To encapsulate the logic for an ant, we can use a class. When an instance of the ant class is initialized, an empty array is initialized to represent a list of attractions that the ant will visit. Furthermore, a random attraction will be selected to be the starting point for that specific ant:

![](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_UN05_Hurbans.png)

The ant class also contains several functions used for ant movement. The `visit_*` functions are used to determine to which attraction the ant moves to next. The `visit_attraction` function generates a random chance of visiting a random attraction. In this case, `visit_random_attraction` is called; otherwise, `roulette_wheel_selection` is used with a calculated list of probabilities. More details are coming up in the next section:

![](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_UN06_Hurbans.png)

Last, the `get_distance_traveled` function is used to calculate the total distance traveled by a specific ant, using its list of visited attractions. This distance must be minimized to find the shortest path and is used as the fitness for the ants:

![](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_UN07_Hurbans.png)

The final data structure to design is the concept of pheromone trails. Similarly to the distances between attractions, pheromone intensity on each path can be represented as a distance matrix, but instead of containing distances, the matrix contains pheromone intensities. In figure 6.10, thicker lines indicate more-intense pheromone trails. Table 6.2 describes the pheromone trails between [](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)attractions.

![Figure 6.10 Example pheromone intensity on paths](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_F10_Hurbans.png)

##### Table 6.2 Pheromone intensity between attractions[(view table figure)](https://drek4537l1klr.cloudfront.net/hurbans/HighResolutionFigures/table_6-2.png)

|   | **Circus** | **Balloons** | **Bumper cars** | **Carousel** | **Swings** | **Ferris wheel** |
| --- | --- | --- | --- | --- | --- | --- |
| Circus | 0 | 2 | 0 | 8 | 6 | 8 |
| Balloon | 2 | 0 | 10 | 8 | 2 | 2 |
| Bumper cars | 2 | 10 | 0 | 0 | 2 | 2 |
| Carousel | 8 | 8 | 2 | 0 | 2 | 2 |
| Swings | 6 | 2 | 2 | 2 | 0 | 10 |
| Ferris wheel | 8 | 2 | 2 | 2 | 10 | 0 |

## The ant colony optimization algorithm life cycle

Now that we understand the data structures required, we can dive into the workings of the ant colony optimization algorithm. The approach in designing an ant colony optimization algorithm is based on the problem space being addressed. Each problem has a unique context and a different domain in which data is represented, but the principles remain the same.

That said, let’s look into how an ant colony optimization algorithm can be configured to solve the Carnival Problem. The general life cycle of such an algorithm is as follows:

-  *Initialize the pheromone trails.* Create the concept of pheromone trails between attractions, and initialize their intensity values.
-  *Set up the population of ants.* Create a population of ants in which each ant starts at a different attraction.
-  *Choose the next visit for each ant.* Choose the next attraction to visit for each ant until each ant has visited all attractions once.
-  *Update the pheromone trails.* Update the intensity of pheromone trails based on the ants’ movements on them, as well as factor in evaporation of pheromones.
-  *Update the best solution.* Update the best solution, given the total distance covered by each ant.
-  *Determine the stopping criteria.* The process of ants visiting attractions repeats for several iterations. One iteration is every ant visiting all attractions once. The stopping criterion determines the total number of iterations to run. More iterations allow ants to make better decisions based on the pheromone trails.

Figure 6.11 describes the general life cycle of the ant colony optimization algorithm.

![Figure 6.11 The ant colony optimization algorithm life cycle](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_F11_Hurbans.png)

### Initialize the pheromone trails

The first step in the ant colony optimization algorithm is to initialize the pheromone trails. Because no ants have walked on the paths between attractions yet, the pheromone trails will be initialized to 1. When we set all pheromone trails to 1, no trail has any advantage over the others. The important aspect is defining a reliable data structure to contain the pheromone trails, which we look at next (figure 6.12).

![Figure 6.12 Set up the pheromones.](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_F12_Hurbans.png)

This concept can be applied to other problems in which instead of distances between locations, the pheromone intensity is defined by another heuristic.

In figure 6.13, the heuristic is the distance between two destinations.

![Figure 6.13 Initialization of pheromones](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_F13_Hurbans.png)

Pseudocode

Similarly to the attraction distances, the pheromone trails can be represented by a distance matrix, but referencing x, y in this array provides the pheromone intensity on the path between attractions x and y. The initial pheromone intensity on every path is initialized to 1. Values for all paths should initialize with the same number to prevent biasing any paths from the start:

![](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_UN08_Hurbans.png)

### Set up the population of ants

The next step of the ACO algorithm is creating a population of ants that will move between the attractions and leave pheromone trails between them (figure 6.14).

![Figure 6.14 Set up the population of ants.](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_F14_Hurbans.png)

Ants will start at randomly assigned attractions (figure 6.15)—at a random point in a potential sequence because the ant colony optimization algorithm can be applied to problems in which actual distance doesn’t exist. After touring all the destinations, ants are set to their respective starting points.

![Figure 6.15 Ants start at random attractions.](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_F15_Hurbans.png)

We can adapt this principle to a different problem. In a task-scheduling problem, each ant starts at a different task.

Pseudocode

Setting up the colony of ants includes initializing several ants and appending them to a list where they can be referenced later. Remember that the initialization function of the ant class chooses a random attraction to start at:

![](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_UN09_Hurbans.png)

### Choose the next visit for each ant

Ants need to select the next attraction to visit. They visit new attractions until they have visited all attractions once, which is called a tour. Ants choose the next destination based on two factors (figure 6.16):

-  *Pheromone intensities*—The pheromone intensity on all available paths
-  *Heuristic value*—A result from a defined heuristic for all available paths, which is the distance of the path between attractions in the carnival example

![Figure 6.16 Choose the next visit for each ant.](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_F16_Hurbans.png)

Ants will not travel to destinations they have already visited. If an ant has already visited the bumper cars, it will not travel to that attraction again in the current tour.

#### The stochastic nature of ants

The ant colony optimization algorithm has an element of randomness. The intention is to allow ants the possibility of exploring less-optimal immediate paths, which might result in a better overall tour distance.

First, an ant has a random probability of deciding to choose a random destination. We could generate a random number between 0 and 1, and if the result is 0.1 or less, the ant will decide to choose a random destination; this is a 10% chance of choosing a random destination. If an ant decides that it will choose a random destination, it needs to randomly select a destination to visit, which is a random selection between all available destinations.

#### Selecting destination based on a heuristic

When an ant faces the decision of choosing the next destination that is not random, it determines the pheromone intensity on that path and the heuristic value by using the following formula:

![](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_UN10_Hurbans.png)

After it applies this function to every possible path toward its respective destination, the ant selects the destination with the best overall value to travel to. Figure 6.17 illustrates the possible paths from the circus with their respective distances and pheromone intensities.

![Figure 6.17 Example of possible paths from the circus](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_F17_Hurbans.png)

Let’s work through the formula to demystify the calculations that are happening and how the results affect decision-making (figure 6.18).

![Figure 6.18 The pheromone influence and heuristic influence of the formula](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_F18_Hurbans.png)

The variables *alpha (a)* and *beta (b)* are used to give greater weight to either the pheromone influence or the heuristic influence. These variables can be adjusted to balance the ant’s judgment between making a move based on what it knows versus pheromone trails, which represent what the colony knows about that path. These parameters are defined up front and are usually not adjusted while the algorithm runs.

The following example works through each path starting at the circus and calculates the probabilities of moving to each respective attraction.

-  *a (alpha)* is set to 1.
-  *b (beta)* is set to 2.

Because *b* is greater than *a*, the heuristic influence is favored in this example.

Let’s work through an example of the calculations used to determine the probability of choosing a specific path (figure 6.19).

![Figure 6.19 Probability calculations for paths](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_F19_Hurbans.png)

After applying this calculation, given all the available destinations, the ant is left with the options shown in figure 6.20.

![Figure 6.20 The final probability of each attraction being selected](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_F20_Hurbans.png)

Remember that only the available paths are considered; these paths have not been explored yet. Figure 6.21 illustrates the possible paths from the circus, excluding the Ferris wheel, because it’s been visited already. Figure 6.22 shows probability calculations for paths.

![Figure 6.21 Example of possible paths from the circus, excluding visited attractions](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_F21_Hurbans.png)

![Figure 6.22 Probability calculations for paths](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_F22_Hurbans.png)

The ant’s decision now looks like figure 6.23.

![Figure 6.23 The final probability of each attraction being selected](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_F23_Hurbans.png)

Pseudocode

The pseudocode for calculating the probabilities of visiting the possible attractions is closely aligned with the mathematical functions that we have worked through. Some interesting aspects of this implementation include:

-  *Determining the available attractions to visit*—Because the ant would have visited several attractions, it should not return to those attractions. The `possible_attractions` array stores this value by removing `visited_attractions` from the complete list of attractions: `all_attractions`.
-  *Using three variables to store the outcome of the probability calculations—*`possible_indexes` stores the attraction indexes; `possible_probabilities` stores the probabilities for the respective index; and `total_probabilities` stores the sum of all probabilities, which should equal 1 when the function is complete. These three data structures could be represented by a class for a cleaner code convention.

![](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_UN11_Hurbans.png)

We meet roulette-wheel selection again. The roulette-wheel selection function takes the possible probabilities and attraction indexes as input. It generates a list of slices, each of which includes the index of the attraction in element 0, the start of the slice in index 1, and the end of the slice in index 2. All slices contain a start and end between 0 and 1. A random number between 0 and 1 is generated, and the slices that it falls into is selected as the winner:

![](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_UN12_Hurbans.png)

Now that we have probabilities of selecting the different attractions to visit, we will use roulette-wheel selection.

To recap, roulette-wheel selection (from chapters 3 and 4) gives different possibilities portions of a wheel based on their fitness. Then the wheel is “spun,” and an individual is selected. A higher fitness gives an individual a larger slice of the wheel, as shown in figure 6.23 earlier in this chapter. The process of choosing attractions and visiting them continues for every ant until each one has visited all the attractions once.

#### Exercise: Determine the probabilities of visiting the attractions with the following information

![](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_UN13_Hurbans.png)

#### Solution: Determine the probabilities of visiting the attractions with the following information

![](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_UN14_Hurbans.png)

### Update the pheromone trails

Now that the ants have completed a tour of all the attractions, they have all left pheromones behind, which changes the pheromone trails between the attractions (figure 6.24).

![Figure 6.24 Update the pheromone trails.](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_F24_Hurbans.png)

Two steps are involved in updating the pheromone trails: evaporation and depositing new pheromones.

#### Updating pheromones due to evaporation

The concept of evaporation is also inspired by nature. Over time, the pheromone trails lose their intensity. Pheromones are updated by multiplying their respective current values by an evaporation factor—a parameter that can be adjusted to tweak the performance of the algorithm in terms of exploration and exploitation. Figure 6.25 illustrates the updated pheromone trails due to evaporation.

![Figure 6.25 Example of updating pheromone trails for evaporation](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_F25_Hurbans.png)

#### Updating pheromones based on ant tours

Pheromones are updated based on the ants that have moved along the paths. If more ants move on a specific path, there will be more pheromones on that path.

Each ant contributes its fitness value to the pheromones on every path it has moved on. The effect is that ants with better solutions have a greater influence on the best paths. Figure 6.26 illustrates the updated pheromone trails based on ant movements on the paths.

![Figure 6.26 Pheromone updates based on ant movements](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_F26_Hurbans.png)

#### Exercise: Calculate the pheromone update given the following scenario

![](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_UN15_Hurbans.png)

#### Solution: Calculate the pheromone update given the following scenario

![](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_UN16_Hurbans.png)

Pseudocode

The `update_pheromones` function applies two important concepts to the pheromone trails. First, the current pheromone intensity is evaporated based on the evaporation rate. If the evaporation rate is 0.5, for example, the intensity decreases by half. The second operation adds pheromones based on ant movements on that path. The amount of pheromones contributed by each ant is determined by the ant’s fitness, which in this case is each respective ant’s total distance traveled:

![](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_UN17_Hurbans.png)

### Update the best solution

The best solution is described by the sequence of attraction visits that has the lowest total distance (figure 6.27).

![Figure 6.27 Update the best solution.](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_F27_Hurbans.png)

Pseudocode

After an iteration, after every ant has completed a tour (a tour is complete when an ant visits every attraction), the best ant in the colony must be determined. To make this determination, we find the ant that has the lowest total distance traveled and set it as the new best ant in the colony:

![](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_UN18_Hurbans.png)

### Determine the stopping criteria

The algorithm stops after several iterations: conceptually, the number of tours that the group of ants concludes. Ten iterations means that each ant does 10 tours; each ant would visit each attraction once and do that 10 times (figure 6.28).

![Figure 6.28 Reached stopping condition?](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_F28_Hurbans.png)

The stopping criteria for the ant colony optimization algorithm can differ based on the domain of the problem being solved. In some cases, realistic limits are known, and when they’re unknown, the following options are available:

-  *Stop when a predefined number of iterations is reached.* In this scenario, we define a total number of iterations for which the algorithm will always run. If 100 iterations are defined, each ant completes 100 tours before the algorithm terminates.
-  *Stop when the best solution stagnates.* In this scenario, the best solution after each iteration is compared with the previous best solution. If the solution doesn’t improve after a defined number of iterations, the algorithm terminates. If iteration 20 resulted in a solution with fitness 100, and that iteration is repeated up until iteration 30, it is likely (but not guaranteed) that no better solution exists.

Pseudocode

The `solve` function ties everything together and should give you a better idea of the sequence of operations and the overall life cycle of the algorithm. Notice that the algorithm runs for several defined total iterations. The ant colony is also initialized to its starting point at the beginning of each iteration, and a new best ant is determined after each iteration:

![](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_UN19_Hurbans.png)

We can tweak several parameters to alter the exploration and exploitation of the ant colony optimization algorithm. These parameters influence how long the algorithm will take to find a good solution. Some randomness is good for exploring. Balancing the weighting between heuristics and pheromones influences whether ants attempt a greedy search (when favoring heuristics) or trust pheromones more. The evaporation rate also influences this balance. The number of ants and the total number of iterations they have influences the quality of a solution. When we add more ants and more iterations, more computation is required. Based on the problem at hand, time to compute may influence these parameters (figure 6.29):

![Figure 6.29 Parameters that can be tweaked in the ant colony optimization algorithm](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_F29_Hurbans.png)

Now you have insight into how ant colony optimization algorithms work and how they can be used to solve the Carnival Problem. The following section describes some other possible use cases. Perhaps these examples may help you find uses for the algorithm in [](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)your [](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)work.

## Use cases for ant colony optimization algorithms

Ant [](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)colony optimization algorithms are versatile and useful in several real-world applications. These applications usually center on complex optimization problems such as the following:

-  *Route optimization*—Routing problems usually include several destinations that need to be visited with several constraints. In a logistics example, perhaps the distance between destinations, traffic conditions, types of packages being delivered, and times of day are important constraints that need to be considered to optimize the operations of the business. Ant colony optimization algorithms can be used to address this problem. The problem is similar to the carnival problem explored in this chapter, but the heuristic function is likely to be more complex and context specific.
-  *Job scheduling*—Job scheduling is present in almost any industry. Nurse shifts are important to ensure that good health care can be provided. Computational jobs on servers must be scheduled in an optimal manner to maximize the use of the hardware without waste. Ant colony optimization algorithms can be used to solve these problems. Instead of looking at the entities that ants visit as locations, we see that ants visit tasks in different sequences. The heuristic function includes constraints and desired rules specific to the context of the jobs being scheduled. Nurses, for example, need days off to prevent fatigue, and jobs with high priorities on a server should be favored.
-  *Image processing*—The ant colony optimization algorithm can be used for edge detection in image processing. An image is composed of several adjacent pixels, and the ants move from pixel to pixel, leaving behind pheromone trails. Ants drop stronger pheromones based on the pixel colors’ intensity, resulting in pheromone trails along the edges of objects containing the highest density of pheromones. This algorithm essentially traces the outline of the image by performing edge detection. The images may require preprocessing to decolorize the image to grayscale so that the pixel-color values can be [](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)compared [](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)[](/book/grokking-artificial-intelligence-algorithms/chapter-6/)consistently.

## Summary of ant colony optimization

![](https://drek4537l1klr.cloudfront.net/hurbans/Figures/CH06_F30_Hurbans.png)
