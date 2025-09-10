# 9 [](/book/grokking-algorithms-second-edition/chapter-9/)Dijkstra’s algorithm

### In this chapter

- We continue the discussion of graphs, and you learn about weighted graphs, a way to assign more or less weight to some edges.
- You learn Dijkstra’s algorithm, which lets you answer “What’s the shortest path to X?” for weighted graphs.
- You learn about negative-weight edges in graphs, where Dijkstra’s algorithm doesn’t work.

[](/book/grokking-algorithms-second-edition/chapter-9/)In chapter 6, you figured out a way to get from point A[](/book/grokking-algorithms-second-edition/chapter-9/) to point B.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-1.png)

It’s not necessarily the fastest path. It’s the shortest path because it has the least number of segments (three segments). But suppose you add travel times to those segments. Now you see that there’s a faster path.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-2.png)

You used breadth-first search in chapter 6. Breadth-first search will find the path with the fewest segments (the first graph shown here). What if you want the fastest path instead (the second graph)? You can do that *fastest* with a different algorithm called *Dijkstra’s algorithm.*

## [](/book/grokking-algorithms-second-edition/chapter-9/)Working with [](/book/grokking-algorithms-second-edition/chapter-9/)Dijkstra’s algorithm[](/book/grokking-algorithms-second-edition/chapter-9/)

Let’s see how it works with this graph.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-3.png)

Each segment has a travel time in minutes. You’ll use Dijkstra’s algorithm to go from Start to Finish in the shortest possible time.

If you ran breadth-first search on this graph, you’d get this shortest path.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-4.png)

But that path takes 7 minutes. Let’s see if you can find a path that takes less time! There are four steps to Dijkstra’s algorithm:[](/book/grokking-algorithms-second-edition/chapter-9/)

1.  Find the “cheapest” node. This is the node you can get to in the least amount of time.
1.  Update the costs of the out-neighbors of this node. I’ll explain what I mean by this shortly.
1.  Repeat until you’ve done this for every node in the graph.
1.  Calculate the final path.

Step 1:   Find the cheapest node. You’re standing at Start, wondering if you should go to node A or node B. How long does it take to get to each node?

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-5.png)

It takes 6 minutes to get to node A and 2 minutes to get to node B. The rest of the nodes, you don’t know yet.

Because you don’t know how long it takes to get to Finish yet, you put down infinity (you’ll see why soon). Node B is the closest node—it’s 2 minutes away.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-6.png)

Step 2:   Calculate how long it takes to get to all of node B’s out-neighbors *by following an edge from B.*[](/book/grokking-algorithms-second-edition/chapter-9/)

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-7.png)

Hey, you just found a shorter path to node A! It used to take 6 minutes to get to node A.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-8.png)

But if you go through node B, there’s a path that only takes 5 minutes!

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-9.png)

When you find a shorter path for a neighbor of B, update its cost. In this case, you found

-  A shorter path to A (down from 6 minutes to 5 minutes)
-  A shorter path to Finish (down from infinity to 7 minutes)

Step 3:   Repeat.

Step 1 again:    Find the node that takes the least amount of time to get to. You’re done with node B, so node A has the next smallest time estimate.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-10.png)

Step 2 again:     Update the costs for node A’s out-neighbors.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-11.png)

Woo, it takes 6 minutes to get to Finish now!

You’ve run Dijkstra’s algorithm for every node (you don’t need to run it for the Finish node). At this point, you know[](/book/grokking-algorithms-second-edition/chapter-9/)

-  It takes 2 minutes to get to node B.
-  It takes 5 minutes to get to node A.
-  It takes 6 minutes to get to Finish.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-12.png)

I’ll save the last step, calculating the final path, for the next section. For now, I’ll just show you what the final path is.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-13.png)

Breadth-first search wouldn’t have found this as the shortest path because it has three segments. And there’s a way to get from Start to Finish in two segments.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-14.png)

In the last chapter, you used breadth-first search to find the shortest path between two points. Back then, “shortest path” meant the path with the fewest segments. But in Dijkstra’s algorithm, you assign a number or weight to each segment. Then Dijkstra’s algorithm finds the path with the smallest total weight.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-15.png)

To recap, [](/book/grokking-algorithms-second-edition/chapter-9/)Dijkstra’s algorithm has four steps:

1.  Find the cheapest node. This is the node you can get to in the least amount of time.
1.  Check whether there’s a cheaper path to the out-neighbors of this node. If so, update their costs.
1.  Repeat until you’ve done this for every node in the graph.
1.  Calculate the final path. (Coming up in the next section!)

## [](/book/grokking-algorithms-second-edition/chapter-9/)Terminology[](/book/grokking-algorithms-second-edition/chapter-9/)[](/book/grokking-algorithms-second-edition/chapter-9/)

[](/book/grokking-algorithms-second-edition/chapter-9/)I want to show you some more examples of Dijkstra’s algorithm in action. But, first, let me clarify some terminology.[](/book/grokking-algorithms-second-edition/chapter-9/)

When you work with Dijkstra’s algorithm, each edge in the graph has a number associated with it. These are called *weights.[](/book/grokking-algorithms-second-edition/chapter-9/)*

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-16.png)

A graph with weights is called a *weighted graph*. A graph without weights is called an *unweighted graph*.[](/book/grokking-algorithms-second-edition/chapter-9/)[](/book/grokking-algorithms-second-edition/chapter-9/)

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-17.png)

To calculate the shortest path in an unweighted graph, use *breadth-first search*. To calculate the shortest path in a weighted graph, use *Dijkstra’s algorithm*. Graphs can also have *cycles*. A cycle looks like this.[](/book/grokking-algorithms-second-edition/chapter-9/)

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-18.png)

[](/book/grokking-algorithms-second-edition/chapter-9/)It means you can start at a node, travel around, and end up at the same node. Suppose you’re trying to find the shortest path in this graph that has a cycle.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-19.png)

Would it make sense to follow the cycle? Well, you can use the path that avoids the cycle.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-20.png)

Or you can follow the cycle.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-21.png)

You end up at the target node either way, but the cycle adds more weight. You could even follow the cycle twice if you wanted.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-22.png)

But every time you follow the cycle, you’re just adding 8 to the total weight. So following the cycle will never give you the shortest path.

Finally, remember our conversation about directed versus undirected graphs from chapter 6?

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-23.png)

An undirected graph means that both nodes point to each other. That’s a cycle!

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-24.png)

With an undirected graph, each edge adds another cycle. Dijkstra’s algorithm only works on graphs with no cycles, where all the edges are nonnegative. Yes, it’s possible for graph edges to have a negative weight! But Dijkstra’s algorithm won’t work—in that case, you’ll need an algorithm called Bellman–Ford. There’s a section on negative weight edges coming later in the chapter.

## [](/book/grokking-algorithms-second-edition/chapter-9/)Trading for a piano

[](/book/grokking-algorithms-second-edition/chapter-9/)Enough terminology, let’s look at another example! This is Rama.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-25.png)

Rama is trying to trade a music book for a piano.

“I’ll give you this poster for your book,” says Alex. “It’s a poster of my favorite band, Destroyer. Or I’ll give you this rare LP of Rick Astley for your book and $5 more.” “Ooh, I’ve heard that LP has a really great song,” says Amy. “I’ll trade you my guitar or drum set for the poster or the LP.”

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-26.png)

“I’ve been meaning to get into guitar!” exclaims Beethoven. “Hey, I’ll trade you my piano for either of Amy’s things.”

[](/book/grokking-algorithms-second-edition/chapter-9/)Perfect! With a little bit of money, Rama can trade his way from a piano book to a real piano. Now he just needs to figure out how to spend the least amount of money to make those trades. Let’s graph out what he’s been offered.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-27.png)

In this graph, the nodes are all the items Rama can trade for. The weights on the edges are the amount of money he would have to pay to make the trade. So he can trade the poster for the guitar for $30 or trade the LP for the guitar for $15. How is Rama going to figure out the path from the book to the piano where he spends the least dough? Dijkstra’s algorithm to the rescue! Remember, Dijkstra’s algorithm has four steps. In this example, you’ll do all four steps, so you’ll calculate the final path at the end, too.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-28.png)

Before you start, you need some setup. Make a table of the cost for each node. The cost of a node is how expensive it is to get to.

You’ll keep updating this table as the algorithm goes on. To calculate the final path, you also need a *parent* column on this table.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-29.png)

I’ll show you how this column works soon. Let’s start the algorithm.

Step 1:   Find the cheapest node. In this case, the poster is the cheapest trade at $0. Is there a cheaper way to trade for the poster? This is a really important point, so think about it. Can you see a series of trades that will get Rama the poster for less than $0? Read on when you’re ready.
Answer: No. *Because the poster is the cheapest node Rama can get to, there’s no way to make it any cheaper.* Here’s a different way to look at it. Suppose you’re traveling from home to work.[](/book/grokking-algorithms-second-edition/chapter-9/)

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-30.png)

If you take the path toward the school, that takes 2 minutes. If you take the path toward the park, that takes 6 minutes. Is there any way you can take the path toward the park and end up at the school in less than 2 minutes? It’s impossible because it takes longer than 2 minutes just to get to the park. On the other hand, can you find a faster path to the park? Yup.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-31.png)

This is the key idea behind Dijkstra’s algorithm: look at the cheapest node on your graph. There is no cheaper way to get to this node!

Back to the music example. The poster is the cheapest trade.

Step 2:   Figure out how long it takes to get to its out-neighbors (the cost).[](/book/grokking-algorithms-second-edition/chapter-9/)

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-32.png)

You have prices for the bass guitar and the drum set in the table. Their value was set when you went through the poster, so the poster gets set as their parent. That means, to get to the bass guitar, you follow the edge from the poster, and the same for the drums.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-33.png)

Step 1 again:    The LP is the next cheapest node at $5.

Step 2 again:    Update the values of all of its out-neighbors.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-34.png)

Hey, you updated the price of both the drums and the guitar! That means it’s cheaper to get to the drums and guitar by following the edge from the LP. So you set the LP as the new parent for both instruments.

The bass guitar is the next cheapest item. Update its out-neighbors.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-35.png)

[](/book/grokking-algorithms-second-edition/chapter-9/)OK, you finally have a price for the piano by trading the guitar for the piano. So you set the guitar as the parent. Finally, the last node, the drum set.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-36.png)

Rama can get the piano even cheaper by trading the drum set for the piano instead. *So the cheapest set of trades will cost Rama $35*.

Now, as I promised, you need to figure out the path. So far, you know that the shortest path costs $35, but how do you figure out the path? To start with, look at the parent for *piano*.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-37.png)

The piano has drums as its parent. That means Rama trades the drums for the piano. So you follow this edge.

Let’s see how you’d follow the edges. *Piano* has *drums* as its parent.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-38.png)

And *drums* has the LP as its parent.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-39.png)

[](/book/grokking-algorithms-second-edition/chapter-9/)So Rama will trade the LP for the drums. And, of course, he’ll trade the book for the LP. By following the parents backward, you now have the complete path.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-40.png)

Here’s the series of trades Rama needs to make.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-41.png)

So far, I’ve been using the term *shortest path* pretty literally: calculating the shortest path between two locations or between two people. I hope this example showed you that the shortest path doesn’t have to be about physical distance. It can be about minimizing something. In this case, Rama wanted to minimize the amount of money he spent. Thanks, Dijkstra![](/book/grokking-algorithms-second-edition/chapter-9/)

## [](/book/grokking-algorithms-second-edition/chapter-9/)Negative[](/book/grokking-algorithms-second-edition/chapter-9/)-weight[](/book/grokking-algorithms-second-edition/chapter-9/) edges

[](/book/grokking-algorithms-second-edition/chapter-9/)In the trading example, Alex offered to trade the book for two items.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-42.png)

Suppose Sarah offers to trade the LP for the poster, and *she’ll give Rama an additional $7.* It doesn’t cost Rama anything to make this trade; instead, he gets $7 back.

How would you show this on the graph?

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-43.png)

The edge from the LP to the poster has a negative weight! Rama gets $7 back if he makes that trade. Now Rama has two ways to get to the poster.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-44.png)

So it makes sense to do the second trade—Rama gets $2 back that way! Now, if you remember, Rama can trade the poster for the drums. There are two paths he could take.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-45.png)

[](/book/grokking-algorithms-second-edition/chapter-9/)The second path costs him $2 less, so he should take that path, right? Well, guess what? If you run Dijkstra’s algorithm on this graph, Rama will take the wrong path. He’ll take the longer path. *You can’t use Dijkstra’s algorithm if you have negative-weight edges.* Negative-weight edges break the algorithm. Let’s see what happens when you run Dijkstra’s algorithm on this. First, make the table of costs.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-46.png)

Next, find the lowest-cost node and update the costs for its out-neighbors. In this case, the poster is the lowest-cost node. So, according to Dijkstra’s algorithm, *there is no cheaper way to get to the poster than paying $0* (you know that’s wrong!). Anyway, let’s update the costs for its out-neighbors.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-47.png)

OK, the drums have a cost of $35 now.

Let’s get the next-cheapest node that hasn’t already been processed.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-48.png)

Update the costs for its out-neighbors.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-49.png)

[](/book/grokking-algorithms-second-edition/chapter-9/)You already processed the poster node, but you’re updating the cost for it. This is a big red flag. Once you process a node, it means there’s no cheaper way to get to that node. But you just found a cheaper way to the poster! Drums doesn’t have any out-neighbors, so that’s the end of the algorithm. Here are the final costs.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-50.png)

It costs $35 to get to the drums. You know that there’s a path that costs only $33, but Dijkstra’s algorithm didn’t find it. Dijkstra’s algorithm assumed that because you were processing the poster node, there was no cheaper way to get to that node. That assumption only works if you have no negative-weight edges. So you *can’t use negative-weight edges with Dijkstra’s algorithm.* If you want to find the shortest path in a graph that has negative-weight edges, there’s an algorithm for that! It’s called the *Bellman–Ford algorithm*. Bellman–Ford is out of the scope of this book, but you can find some great explanations online.[](/book/grokking-algorithms-second-edition/chapter-9/)

## [](/book/grokking-algorithms-second-edition/chapter-9/)Implementation[](/book/grokking-algorithms-second-edition/chapter-9/)

[](/book/grokking-algorithms-second-edition/chapter-9/)Let’s see how to implement [](/book/grokking-algorithms-second-edition/chapter-9/)Dijkstra’s algorithm in code. Here’s the graph I’ll use for the example.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-51.png)

To code this example, you’ll need three hash[](/book/grokking-algorithms-second-edition/chapter-9/) tables.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-52.png)

You’ll update the costs and parents hash tables as the algorithm progresses. First, you need to implement the graph. You’ll use a hash table like you did in chapter 6:

```
graph = {}
```

In the last chapter, you stored all the out-neighbors of a node in the hash table, like this:

```
graph["you"] = ["alice", "bob", "claire"]
```

But this time, you need to store the out-neighbors *and* the cost for getting to that neighbor. For example, Start has two out-neighbors, A and B.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-53.png)

How do you represent the weights of those edges? Why not just use another hash table?

```
graph["start"] = {}
graph["start"]["a"] = 6
graph["start"]["b"] = 2
```

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-54.png)

[](/book/grokking-algorithms-second-edition/chapter-9/)So `graph["start"]` is a hash table. You can get all the out-neighbors for Start like this:

```
>>> print(list(graph["start"].keys()))
["a", "b"]
```

There’s an edge from Start to A and an edge from Start to B. What if you want to find the weights of those edges?

```
>>> print(graph["start"]["a"])
6
>>> print(graph["start"]["b"])
2
```

Let’s add the rest of the nodes and their out-neighbors to the graph:

```
graph["a"] = {}
graph["a"]["fin"] = 1

graph["b"] = {}
graph["b"]["a"] = 3
graph["b"]["fin"] = 5

graph["fin"] = {}   #1
```

The full graph hash table looks like this.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-55.png)

Next, you need a hash table to store the current costs for each node.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-56.png)

[](/book/grokking-algorithms-second-edition/chapter-9/)The *cost* of a node is how long it takes to get to that node from Start. You know it takes 2 minutes from Start to node B. You know it takes 6 minutes to get to node A (although you may find a path that takes less time). You don’t know how long it takes to get to Finish. If you don’t know the cost yet, you put down infinity. Can you represent *infinity* in Python? Turns out, you can:

```
infinity = math.inf
```

Here’s the code to make the costs table:

```
infinity = math.inf
costs = {}
costs["a"] = 6
costs["b"] = 2
costs["fin"] = infinity
```

You also need another hash table for the parents:

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-57.png)

Here’s the code to make the hash table for the parents:

```
parents = {}
parents["a"] = "start"
parents["b"] = "start"
parents["fin"] = None
```

Finally, you need a set to keep track of all the nodes you’ve already processed because you don’t need to process a node more than once:

```
processed = set()
```

That’s all the setup. Now let’s look at the algorithm.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-58.png)

[](/book/grokking-algorithms-second-edition/chapter-9/)I’ll show you the code first and then walk through it. Here’s the code:

```
node = find_lowest_cost_node(costs)     #1
while node is not None:                 #2
    cost = costs[node]
    neighbors = graph[node]  
    for n in neighbors.keys():          #3
        new_cost = cost + neighbors[n] 
        if costs[n] > new_cost:         #4
            costs[n] = new_cost         #5
            parents[n] = node           #6
    processed.add(node)                 #7
    node = find_lowest_cost_node(costs) #8
#1 Finds the lowest-cost node that you haven’t processed yet
#2 If you’ve processed all the nodes, this while loop is done.
#3 Goes through all the out-neighbors of this node
#4 If it’s cheaper to get to this out-neighbor by going through this node .&nbsp;.&nbsp;.
#5 .&nbsp;.&nbsp;. updates the cost for the neighbor
#6 This node becomes the new parent for this out-neighbor.
#7 Marks the node as processed
#8 Finds the next node to process and loops
```

That’s Dijkstra’s algorithm in Python! Let's see this code in action. Then I'll show you the code for the `find_lowest_cost_node` function.[](/book/grokking-algorithms-second-edition/chapter-9/)

Find the node with the lowest cost.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-59.png)

Get the cost and out-neighbors of that node.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-60.png)

Loop through the out-neighbors.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-61.png)

[](/book/grokking-algorithms-second-edition/chapter-9/)Each node has a cost. The cost is how long it takes to get to that node from Start. Here, you’re calculating how long it would take to get to node A if you went Start > node B > node A, instead of Start > node A.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-62.png)

Let’s compare those costs.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-63.png)

You found a shorter path to node A! Update the cost.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-64.png)

The new path goes through node B, so set B as the new parent.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-65.png)

[](/book/grokking-algorithms-second-edition/chapter-9/)OK, you’re back at the top of the loop. The next out-neighbor in the `for` loop is the Finish node.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-66.png)

How long does it take to get to Finish if you go through node B?

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-67.png)

It takes 7 minutes. The previous cost was infinity minutes, and 7 minutes is less than that.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-68.png)

Set the new cost and the new parent for the Finish node.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-69.png)

[](/book/grokking-algorithms-second-edition/chapter-9/)OK, you updated the costs for all the out-neighbors of node B. Mark it as processed.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-70.png)

Find the next node to process.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-71.png)

Get the cost and out-neighbors for node A.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-72.png)

Node A only has one out-neighbor: the Finish node.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-73.png)

[](/book/grokking-algorithms-second-edition/chapter-9/)Currently, it takes 7 minutes to get to the Finish node. How long would it take to get there if you went through node A?

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-74.png)

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-75.png)

It’s faster to get to Finish from node A! Let’s update the cost and parent.

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-76.png)

Once you’ve processed all the nodes, the algorithm is over. I hope the walkthrough helped you understand the algorithm a little better. Finding the lowest-cost node is pretty easy with the `find_lowest_cost_node` function. Here it is in code:

```
def find_lowest_cost_node(costs):
    lowest_cost = math.inf
    lowest_cost_node = None
    for node in costs:                                   #1
        cost = costs[node]
        if cost < lowest_cost and node not in processed: #2
            lowest_cost = cost                           #3
            lowest_cost_node = node
    return lowest_cost_node
#1 Goes through each node
#2 If it’s the lowest cost so far and hasn’t been processed yet .&nbsp;.&nbsp;.
#3 .&nbsp;.&nbsp;. sets it as the new lowest-cost node
```

To find the lowest cost node, we loop through all the nodes each time. There is a more efficient version of this algorithm. It uses a data structure called a priority queue. A priority queue is itself built on top of a different data structure called a heap. If you’re curious about priority queues and heaps, check out the section on heaps in the last chapter of the book.[](/book/grokking-algorithms-second-edition/chapter-9/)

#### Exercise

9.1 In each of these graphs, what is the weight of the shortest path from Start to Finish?

![](https://drek4537l1klr.cloudfront.net/bhargava2/Figures/image_9-77.png)

## [](/book/grokking-algorithms-second-edition/chapter-9/)Recap[](/book/grokking-algorithms-second-edition/chapter-9/)

-  Breadth-first search is used to calculate the shortest path for an unweighted graph.
-  Dijkstra’s algorithm[](/book/grokking-algorithms-second-edition/chapter-9/) is used to calculate the shortest path for a weighted graph.
-  Dijkstra’s algorithm works when all the weights are nonnegative.
-  If you have negative weights, use the Bellman–Ford algorithm.
