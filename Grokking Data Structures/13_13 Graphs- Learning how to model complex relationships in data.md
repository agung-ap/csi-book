# 13 Graphs: Learning how to model complex relationships in data

### In this chapter

- defining graphs
- discussing the basic properties of graphs
- evaluating graph implementation strategies: adjacency list and adjacency matrix
- exploring graph traversal: breadth-first search and depth-first search

[](/book/grokking-data-structures/chapter-13/)In our final chapter, we discuss another data structure that exceeds the characteristics of a container—graphs. They can be used to store elements, but that would be an understatement as graphs have a much broader range of applications.[](/book/grokking-data-structures/chapter-13/)

This chapter defines what graphs are and discusses some of their most important properties. After covering the basics, we move on to their implementation. Finally, we briefly discuss two methods for traversing a graph.

## What’s a graph?

Not surprisingly, the first question we want to answer is, “What is a graph?” There are many ways to define graphs, ranging from informal definitions to rigid theory. I’ll start with this definition: graphs are a generalization of trees. When I introduced trees in chapter 11, I told you that they can be used to model hierarchical relationships. Graphs allow you to model more general relationships. For example, the structure of your file system or an arithmetic expression can be represented using trees, but trees are not suitable to represent a friendship graph or the flow of a computer program. For these kinds of relationships, we need graphs.[](/book/grokking-data-structures/chapter-13/)[](/book/grokking-data-structures/chapter-13/)

### Definition

We’ll return to the differences between graphs and trees later in this section. For now, it’s time for a more formal definition of a graph.[](/book/grokking-data-structures/chapter-13/)

We can define a graph `G` as a pair of sets:

-  *A set of* *vertices* `V`—These are entities that are independent of each other and unique. The set of vertices can be arbitrarily large (it can even be empty).[](/book/grokking-data-structures/chapter-13/)
-  *A set of edges* `E` *connecting the vertices*—An edge is identified by a pair of vertices. The first one is called the *source* vertex, and the second one is called the *destination* vertex. [](/book/grokking-data-structures/chapter-13/)[](/book/grokking-data-structures/chapter-13/)[](/book/grokking-data-structures/chapter-13/)

We can write `G = (V,E)` to make it clear that the graph has a set of vertices `V` and a set of edges `E`.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/13-01.png)

Considering the example in the illustration, we can write the following:

```
G = ([v1, v2, v3, v4], [(v1,v2),(v1,v3),(v2,v4)])
```

Let’s look at some more basic definitions:

-  An edge whose source and destination are the same is called a *loop*.[](/book/grokking-data-structures/chapter-13/)
-  *Simple graphs* are graphs without loops, with at most one edge between any two vertices. For any couple of vertices `u,v`, where `u ≠ v`, there can only be (at most) one edge from `u` to `v`.[](/book/grokking-data-structures/chapter-13/)
-  *Multigraphs*, in contrast, can have any number of edges between two given vertices. Both simple graphs and multigraphs can be extended to allow loops.[](/book/grokking-data-structures/chapter-13/)
-  An edge can have a numerical value associated with it. Such a value is called its *weight*, and the edge is then called a *weighted edge*.[](/book/grokking-data-structures/chapter-13/)
-  A graph is *sparse* if the number of edges is relatively small. For reference, we can consider a graph with `n` vertices to be sparse if its number of edges is `O(n)` or less.[](/book/grokking-data-structures/chapter-13/)
-  A graph is *dense* if the number of edges is close to the maximum possible, which can be at most `O(n2)` for a simple graph with `n` vertices.[](/book/grokking-data-structures/chapter-13/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/13-02.png)

### Friendship graph

[](/book/grokking-data-structures/chapter-13/)In this section, we meet again a group of friends we made in the first chapter. [](/book/grokking-data-structures/chapter-13/)

The animal farm is abuzz! A new social network has recently been introduced, and everyone is constantly looking at their phones. The Lion and the Tiger have been feuding for a long time, and now their rivalry has moved into the digital world. There is an election coming up at the animal farm, and the Tiger wants to take over the position of King of the Farm from the Lion. To that end, she and her staff are trying to use social networks by mapping a friendship graph to make sense of their respective connections. They want to understand who has the larger following—the Tiger or the Lion—and identify which animals to focus on in the Tiger’s campaign to sway their vote.

The vertices of this graph will be the animals on the farm. The edges of the graph will represent friendship relationships in social networks. Because we have to start somewhere, in the first version of the friendship graph, the vertices are the Tiger and her campaign advisor and best friend, the Monkey.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/13-03.png)

### Directed vs. undirected

After adding the Monkey to the graph, the next honor goes to the Crocodile, the IT director of Tiger’s campaign. As a software developer, Croc raises a good technical question: Should they use a directed or an undirected graph?[](/book/grokking-data-structures/chapter-13/)

In a *directed graph*, edges have a direction: they only go from the source vertex to the destination vertex. This means that if two vertices `u` and `v` are connected (only) by an edge `(u,v)`, we can go from `u` to `v`, but it’s not possible to go from `v` directly to vertex `u`.[](/book/grokking-data-structures/chapter-13/)

Social networks such as Twitter or Instagram, where you can follow other users even without being followed back, are better represented by directed graphs. Other applications best modeled by directed graphs include maps (some roads are one-way), workflows, and processes (any state machine really).

On Twitter, everyone in her campaign follows the Tiger, who doesn’t follow anyone back. The Crocodile follows the Monkey because he is the campaign manager.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/13-04.png)

[](/book/grokking-data-structures/chapter-13/)In an *undirected graph*, instead, edges can be traversed in both directions. So if an undirected graph has an edge `(u,v)`, we can also go from `v` to `u`. The LinkedIn connection and Facebook friendship are two-way (symmetrical) relationships that should be represented by undirected graphs.[](/book/grokking-data-structures/chapter-13/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/13-05.png)

You may have noticed that edges can have descriptive text next to them. These labels should not be confused with the weight of the edge. In this case, they are just decorative, but (especially in multigraphs) labels can have meaning (for example, specify conditions that must apply to take a certain edge or actions to perform when traversing it).

Is it possible to transform a directed graph into an undirected graph, and vice versa? An undirected edge `(u,v)` is equivalent to two directed edges `(u,v)` and `(v,u)`. So, it’s always possible to represent an undirected graph with directed edges. The opposite is not true: for example, the directed graph in this section is not equivalent to any undirected graph.

For this reason, it’s usually more practical to use directed edges in computer representations of graphs, regardless of the actual type of graph, to ensure greater flexibility.

### Cyclic versus acyclic

At the Tiger campaign headquarters, the animals are working hard to expand their follower graph. They’ve just added the Zebra and the Giraffe, and they’ve noticed that the latter isn’t following the Tiger yet (they’ll have a little chat with the Giraffe later!).[](/book/grokking-data-structures/chapter-13/)[](/book/grokking-data-structures/chapter-13/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/13-06.png)

There is something else interesting in this graph: I have highlighted three edges, making them a little thicker. They go from the Giraffe to the Crocodile, from the Crocodile to the Monkey, and from the Monkey to the Giraffe. That, as you may already know, is a cycle.

Let’s take a small step back. We define a *path* in the graph as a sequence of one or more edges `(v1, v2), (v2, v3)…(vn-1, vn),` where for each adjacent pair of edges in the sequence, the destination of the first edge is the same as the source of the next. In simpler words, a path is a sorted sequence of edges that allows traversing the graph from a vertex `v1` to a vertex `vn`.

A *cycle* is a path that starts and ends at the same vertex—in a cycle, `v1 = vn`. If you look closely at the graph, you may notice that Crocodile→Monkey→Giraffe isn’t its only cycle. There is, in fact, a smaller cycle between the Monkey and the Giraffe.

A graph that has no cycles is called *acyclic*.[](/book/grokking-data-structures/chapter-13/)

### Connected graphs and connected components

To get a better idea of the competition, it’s time to add the Lion and his friends to the graph. After including just a few of the Lion’s connections, something is already apparent: the Lion has a different style than the Tiger. He follows back his connections, probably trying to make them feel closer.[](/book/grokking-data-structures/chapter-13/)

However, the most interesting aspect of this graph is the presence of two different large areas, two clusters centered around the Tiger and the Lion, with no connection between those two parts.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/13-07.png)

Each of the two regions is a *connected component*, that is, a subgraph where all vertices are connected.[](/book/grokking-data-structures/chapter-13/)[](/book/grokking-data-structures/chapter-13/)

Let me give you some definitions. Given a graph `G = (V,E)`,

-  A *subgraph* `G' = (V',E')` consists of a subset `V'` of the vertices of the original graph and a subset `E'` of the edges between the vertices in `V'`.[](/book/grokking-data-structures/chapter-13/)
-  Two vertices `u` and `v` are *connected* if there is a path from `u` to `v`.
-  An undirected graph is *connected* if all its vertices are connected. A connected graph has only one connected component.

A directed graph is *weakly connected* if the undirected graph obtained by replacing directed edges with undirected ones is connected. But there is a stricter definition of connectivity. Two vertices `u` and `v` are *strongly connected* if there is at least one path in the graph that goes from `u` to `v` and one that goes from `v` to `u`.[](/book/grokking-data-structures/chapter-13/)[](/book/grokking-data-structures/chapter-13/)

In an undirected graph, two connected vertices are also strongly connected. In a directed graph, instead, this is no longer true, and it’s usually important to identify its *strongly connected components,* that is, the maximal subgraphs whose vertices are all strongly connected to each other.

In our example, when the team adds the Chicken to the graph, we notice that it becomes a weakly connected graph (the Chicken follows the Crocodile and is followed by the Cow), but it’s not a strongly connected graph. We can, instead, identify five strongly connected components in the graph.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/13-08.png)

Note that if a vertex has all outgoing edges (like the Zebra) or all ingoing edges (like the Tiger), it will certainly be a degenerate strongly connected component with the vertex itself. Those, however, are not the only cases where this can happen (see the Chicken).

Connected and strongly connected components are especially important for large graphs because they allow us to break a large graph into smaller pieces that can be processed separately.

### Trees as graphs

[](/book/grokking-data-structures/chapter-13/)Now that we know all these definitions, we can go back to the difference between trees and graphs and provide a more formal definition of a tree. A tree is, in fact, a simple, undirected, connected, and acyclic graph. As such, a tree with `n` vertices (*nodes*, in tree terms) must have exactly `n-1` edges.[](/book/grokking-data-structures/chapter-13/)

A simple undirected acyclic graph that is not connected is called a *forest*. Here, each connected component is a tree of the forest.[](/book/grokking-data-structures/chapter-13/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/13-09.png)

One might argue that edges in trees go from parent to child and thus should be modeled as directed edges. But, in a tree, identifying the root node eliminates any ambiguity between parents and children, and there is no need to make the direction of the edges explicit.

## Implementing graphs

Like trees, graphs are better described as a class of data structures than as an abstract data type. But we can still define an API, and there are some common operations that most graphs support, such as adding vertices and edges. There are also many more operations that go beyond this basic API.[](/book/grokking-data-structures/chapter-13/)[](/book/grokking-data-structures/chapter-13/)

When we move to the data structure level, the key is to find a way to store a graph’s vertices and edges in such a way that the graph can be easily and conveniently traversed and searched.

In this section, we will look at two ways to implement a graph: the *adjacency list* and the *adjacency matrix*. These are not the only ways, but they are the most common.[](/book/grokking-data-structures/chapter-13/)

### Adjacency list

In the adjacency list representation, we group edges by their source vertex. Given a vertex `v`, the list of all edges with `v` as their source is the adjacency list for `v`. We then build a dictionary in which we associate each vertex in the graph with its adjacency list.[](/book/grokking-data-structures/chapter-13/)[](/book/grokking-data-structures/chapter-13/)

In a Python implementation, the adjacency lists can be actual linked lists, but they can also be Python lists or sets—any container that provides search and traversal, really.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/13-10.png)

Let’s take a closer look at a possible Python implementation. There are so many methods to implement that it’s impossible to show them all here, but you can check out the full code on the book’s GitHub repo: [https://mng.bz/8wgw](https://mng.bz/8wgw).

For the dictionary, I used a Python dictionary for clarity and simplicity. To store the adjacency lists, I’ll instead use the singly linked lists we defined in chapter 6. Each edge could be stored using a custom `Edge` object, as a pair `(source, destination)` or a tuple `(source, destination, weight)`. But if the graph consists only of unweighted and unlabeled edges, we can just store the destination vertices in the adjacency list because we already know its source vertex.[](/book/grokking-data-structures/chapter-13/)

I’ll start by defining an internal class for the vertices. Each vertex will be a wrapper, uniquely identified by its key. It will also store its own adjacency list. This way, we can add all sorts of methods dealing with outgoing edges to the `Vertex` object itself, which will be solely responsible for keeping things in order:[](/book/grokking-data-structures/chapter-13/)

```
12345678910class Vertex:
    def __init__(self, key):
        self.id = key
        self._adj_list = SinglyLinkedList()
    def has_edge_to(self, destination_vertex):
        return self._adj_list._search(destination_vertex) is not None
    def add_edge_to(self, destination_vertex):
        if self.has_edge_to(destination_vertex):
            raise ValueError(f'Edge already exists: {self} -> { destination_vertex}')
        self._adj_list.insert_in_front(destination_vertex)
```

[](/book/grokking-data-structures/chapter-13/)To keep things simple, I implemented an unweighted graph, and we only store the destination vertex in the adjacency lists. Thus, searching for an edge in an adjacency list means finding a vertex in a linked list, and it can then be delegated to the linked list API. Similarly, to insert a new edge, we can use the method provided by linked lists—after making sure that such an edge doesn’t already exist.

We can now define our outer Graph class, with a simple constructor—we just create an empty dictionary for the adjacency list:

```
123class Graph:
    def __init__(self):
        self._adj = {}
```

As I said, vertices will be identified by their keys, and the `Vertex` object should only be used internally by `Graph`. For example, if a client asks to insert a vertex with key `"v"`, they will never get a reference to the instance `Vertex("v")` that is created internally. When they need to perform some action on that vertex, they can only identify it by the ID, `"v"`—for example, a client will call something like `graph.add_edge("v", "u")`. Therefore, we need a way to retrieve the `Vertex` object associated with a given vertex ID. We implement `_get_vertex` as a private method because we don’t need to let the client get a reference to these objects (however, the method will be very useful for us). Here is where the `_adj` attribute comes in. It’s a dictionary whose keys are the vertex identifiers and whose values are the corresponding `Vertex` objects:[](/book/grokking-data-structures/chapter-13/)[](/book/grokking-data-structures/chapter-13/)

```
1234def _get_vertex(self, key):
    if key not in self._adj:
        raise ValueError(f'Vertex {key} does not exist!')
    return self._adj[key]
```

Adding a new vertex to the graph simply requires setting a value in the dictionary, plus a check to make sure the vertex isn’t already in the graph:

```
1234def insert_vertex(self, key):
    if key in self._adj:
        raise ValueError(f'Vertex {key} already exists!')
    self._adj[key] = Graph.Vertex(key)
```

Finally, let’s see how to add a new edge. We need to get the `Vertex` objects for the source and destination and then we can delegate the operation to the source vertex, which will also check if the edge already exists:

```
1234def insert_edge(self, key1, key2):
    v1 = self._get_vertex(key1)
    v2 = self._get_vertex(key2)
    v1.add_edge_to(v2)
```

[](/book/grokking-data-structures/chapter-13/)Removing an edge is just as easy: we can follow the same flow, delegating to the source vertex and letting it check for errors. I omit the method here for space reasons, but you can check it on the GitHub repo.

Removing a vertex instead is something we need to think through. Removing the entry for a vertex `v` in the adjacency list is not enough: that way we would certainly remove `v`’s outgoing edges, but if `v` also has ingoing edges, those would not be affected. Unfortunately, the only way to do this is to go through all the adjacency lists and remove every edge whose destination is `v`. As you can imagine, this is an expensive operation that takes `O(n+m)` steps for a graph with `n` vertices and `m` edges:

```
123456def delete_vertex(self, key):
    v = self._get_vertex(key)
    for u in self._adj.values():
        if u != v and u.has_edge_to(v):
            u.remove_edge_to(v)
    del self._adj[key]
```

### Adjacency matrix

In the adjacency matrix representation, we store the edges in a large matrix whose rows and columns are the vertices of the graph. A cell of the matrix with coordinates `(u,v)` can store a binary value (`0` if there is no edge; `1` if there is an edge from `u` to `v`), the weight of the edge (or a special value such as `None` if there is no edge), or an object that models an edge.[](/book/grokking-data-structures/chapter-13/)[](/book/grokking-data-structures/chapter-13/)[](/book/grokking-data-structures/chapter-13/)

Adjacency matrices can be faster than adjacency lists when we need to check whether there is an edge between two vertices: it takes only a single lookup in a 2D array, which is `O(1)`. Thus, adjacency matrices give us an advantage for algorithms that require intensive connectivity checking.

In contrast, an adjacency matrix requires memory proportional to the square of the number of vertices (that is, the maximum number of edges in a simple graph), even if the graph is sparse. Therefore, they are rarely used, and usually only when we are sure that we are dealing with dense graphs. Also, for this reason, we won’t dive into the code for the adjacency matrix implementation.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/13-11.png)

## Graph search

Searching in a graph has a different meaning than what we have seen so far. Sure, we can also search whether a vertex or an edge is in the graph by looking at the adjacency list or the adjacency matrix.[](/book/grokking-data-structures/chapter-13/)[](/book/grokking-data-structures/chapter-13/) But that would underestimate the potential of a graph. Remember, a graph is more than just a container: it stores how entities (the vertices) are related to each other.

This section provides some examples of how to extract this kind of information from graphs.

### Exploring friends

For this and the next section, we will be working with an undirected graph. However, the same considerations can apply to directed graphs.[](/book/grokking-data-structures/chapter-13/)[](/book/grokking-data-structures/chapter-13/)[](/book/grokking-data-structures/chapter-13/)

There is a flurry of activity at the Tiger campaign headquarters: the IT team is now building a Facebook friendship graph. As we discussed, this is a symmetric relationship that is best modeled with undirected edges. This is a larger graph than we have seen before, and it takes some effort to analyze it. The idea Croc and the team have is to find all the direct friends of the Tiger and compare them to the direct friends of the Lion.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/13-12.png)

So, the Tiger has five friends, and the Lion has just four of them—that’s good news! But, is it all we can learn from this graph?

The next step for the IT team is to study the “friend of a friend” sets. The sets of friends for the Tiger and the Lion don’t intersect, so we can suppose these nine animals will vote for their closest friend. And a reasonable guess is that there are undecided voters among the second-degree connections whose preferences can be influenced by their friends. So, it’s important to swing those votes.

Here the situation is not as bright. The illustration, for clarity, only shows the Tiger’s perspective. The second-degree neighbors for the Tiger are just the Giraffe and the Chicken. The Lion has three second-degree friends: he shares the Giraffe and the Chicken with the Tiger, plus the Cat.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/13-13.png)

What if we get to the third-degree friends? Or the fourth-degree and so on?

### Breadth-first search

There is a search algorithm that works exactly this way, exploring the vertices of a graph in concentric rings until it finds what it is looking for.[](/book/grokking-data-structures/chapter-13/)[](/book/grokking-data-structures/chapter-13/)[](/book/grokking-data-structures/chapter-13/)[](/book/grokking-data-structures/chapter-13/)

According to the info gathered by the campaign manager, the Rabbit is the star of the social networks, and winning the Rabbit’s support can swing the election. At the Tiger HQ, they want to understand how far the rabbit is in the chain of friends. Also, what’s the shortest path between the Tiger and the Rabbit? The plan involves starting with a friend of the Tiger, having that friend introduce the Tiger to one of her friends, who then introduces the Tiger to one of his friends, and so on until she gets to the Rabbit. So, the shorter the path, the fewer people involved.

The *breadth-first search* (BFS) algorithm does exactly this: it explores the graph starting from a start vertex `s`, the Tiger, by expanding a frontier of vertices connected (directly or indirectly) to `s` until we reach the target vertex (the Rabbit). More importantly, BFS explores vertices in a specific order, starting with the start vertex’s neighbors, then expanding the frontier to the second-degree neighbors, and so on.[](/book/grokking-data-structures/chapter-13/)

In detail, this expansion is not done level by level, but vertex by vertex. To make sure that we explore the closest vertices before the others, we can use a queue: first, we add all of the Tiger’s neighbors to the queue.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/13-14.png)

Then, we extract the first vertex in the queue (the Monkey), we go through all its outgoing edges, and add all their destinations to the rear of the queue. These vertices (if not already explored) will be two edges away from the Tiger.

[](/book/grokking-data-structures/chapter-13/)If we add all neighbors to the queue without checking, we may get some duplicates in the queue. These duplicates represent alternative paths to the vertex from the start, but none of these duplicated paths will have a shorter distance to the start vertex! So, we can just ignore the neighbors that have already been added to the queue and avoid adding them a second time.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/13-15.png)

We continue to explore the graph, expanding the frontier of vertices connected to the start vertex, until we finally reach our target (or run out of vertices in the queue).

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/13-16.png)

If we keep track of the distance of a vertex `v` when we add it to the queue, by setting `distance[v]` to 1 plus the distance of the source of the currently traversed edge, we can prove that when we explore a vertex, this value is the minimum distance (in terms of edges to be traversed) between the start vertex and `v`.

And if we also keep track of which edge we traversed to reach `v`, at the end of the method, we can reconstruct the shortest path from the start vertex to each vertex (highlighted in the illustrations). In our example, there are multiple shortest paths of length 4 from the Tiger to the Rabbit, so which one we actually choose depends on the order in which vertices were added to the queue.

[](/book/grokking-data-structures/chapter-13/)Now it’s time to look at some code for this beautiful method:

```
def bfs(self, start_vertex, target_vertex):
    distance = {v: float('inf') for v in self._adj}
    predecessor = {v: None for v in self._adj}
    queue = Queue(self.vertex_count())
    queue.enqueue(start_vertex)        #1
    distance[start_vertex] = 0
    while not queue.is_empty():
        u = queue.dequeue()
        if u == target_vertex:
            return reconstruct_path(predecessor, target_vertex)
        for (_, v) in self._get_vertex(u).outgoing_edges():
            if distance[v] == float('inf'):
                distance[v] = distance[u] + 1
                predecessor[v] = u
                queue.enqueue(v)
    return None                        #2
#1 Initially, we add the start vertex to the queue.
#2 At this point, we know there is no path from the start to the target vertex.
```

Note that, because of how the vertices are explored, when we reach a vertex for the first time, we have already found its minimum distance from the start vertex. So, we don’t need to explicitly keep track of visited vertices—we rather make sure to add them to the queue only once.

We still miss the last piece of the puzzle—the helper method that takes a dictionary with the predecessors of each vertex `v` and reconstructs the shortest path from `s` to `v`:

```
def reconstruct_path(pred, target):
    path = []
    while target:
        path.append(target)
        target = pred[target]
    return path[::-1]                  #1
#1 The list goes from target to start: we need to reverse it.
```

[](/book/grokking-data-structures/chapter-13/)Overall, in the worst case, the `bfs` method has to go through all `m` edges and `n` vertices, so its running time is `O(n+m)`.[](/book/grokking-data-structures/chapter-13/)

This method works perfectly when we are only interested in the distance in terms of the number of edges. If edges are weighted, and we define the distance between two vertices `u` and `v` as the sum of the edges’ weights on a path from `u` to `v`, we need a refined version of the BFS algorithm—Dijkstra’s algorithm. If you’d like to learn more about this, you can check chapter 15 of *Advanced Algorithms and Data Structures* (La Rocca, 2021, Manning).[](/book/grokking-data-structures/chapter-13/)

### Depth-first search

Is BFS the only way to explore a graph? Of course, it’s not. BFS explores the graph in concentric rings of increasing distance from the start vertex. Thus, it expands the frontier of visited vertices like a wave, in all directions. The opposite choice would be to go as deep into the graph as possible, and that’s what *depth-first search* (DFS) does. We must choose a start vertex `s`, and then the algorithm follows one path from `s` to its end. When the end of a path is reached, it goes back until it finds a vertex where we could have chosen a different edge and again follows that path to the end.[](/book/grokking-data-structures/chapter-13/)[](/book/grokking-data-structures/chapter-13/)[](/book/grokking-data-structures/chapter-13/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/13-17.png)

This algorithm can’t be used to find the shortest path between vertices. In contrast, it can help us find connected and strongly connected components, understand if a directed graph is acyclic, and find a topological sorting for DAGs (*directed acyclic graphs*).[](/book/grokking-data-structures/chapter-13/)

In this section, we’ll look at how to find out if a graph is acyclic; for the other applications, see *Advanced Algorithms and Data Structures* (La Rocca, 2021, Manning).

To use DFS to check for the presence of cycles in the graph, we need to perform some additional actions while traversing the vertices—specifically, we mark the vertices with colors. Initially, all vertices are *white*, then we mark a vertex as *gray* when we visit it, and finally, we mark it as *black* when we leave it, that is, when we remove its first occurrence on the stack after traversing all its outgoing edges.

But what order should we follow when exploring vertices? In BFS, we use a queue to traverse edges in the order we discover them. For DFS, again in a symmetric fashion, we use a stack so that we traverse edges as they are discovered, following paths as far as we can.

Now, what does it mean when we pop a vertex from the stack and discover what color it was marked with?[](/book/grokking-data-structures/chapter-13/)

-  If we find a *white* vertex, it’s a vertex we haven’t explored yet, so we don’t learn anything, but we have a lot of work to do: we add its neighbors to the stack and then explore them.
-  With a *black* vertex `v`, we know that we have already fully explored it. Now we have found another vertex `u` that has an edge to `v`: thus, we learn that it’s not possible to reach `u` from `v`.
-  If, however, we find a *gray* vertex `w`, that’s a vertex that is not fully explored. Therefore, there is a path in the graph that starts at `w` and ends at `w`: we have found a cycle.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/13-18.png)

There is a lot more to say about DFS, but now for us, it’s time to wrap up and see some code. I have implemented an iterative version of the `dfs` method that uses an explicit stack (as opposed to the queue used by BFS). You should know, however, that it is common to use recursion to implement DFS, implicitly using a call stack to decide the order of the vertices.

With an explicit stack, we need a little trick to know when we are done exploring a vertex. The first time we visit a vertex `v`, we can push `v` back on the stack, but that alone is not enough because we could add it again as a neighbor of some other vertex. So, we also need a flag telling us that this is the last occurrence of `v` on the stack. For this reason, I push a tuple on the stack. The first value in the tuple tells us if we are ready to mark the vertex as black:

```
def dfs(self, start_vertex, color=None):
    if color is None:
        color = {v: 'white' for v in self._adj}
    acyclic = True
    stack = Stack()
    stack.push((False, start_vertex))
    while not stack.is_empty():
        (mark_as_black, v) = stack.pop()
        col = color.get(v, 'white')
        if mark_as_black:
            color[v] = 'black'
        elif col == 'grey':
            acyclic = False
        elif col == 'white':
            color[v] = 'grey'
            stack.push((True, v))
            for (_, w) in self._get_vertex(v).outgoing_edges():
                stack.push((False, w))
    return acyclic, color
```

[](/book/grokking-data-structures/chapter-13/)This method can be called multiple times with a different start vertex. If a graph isn’t strongly connected, it’s unlikely we will visit the whole graph with a single call. That’s why we return the `color` dictionary along with a Boolean flag that tells us whether DFS found a cycle. We can use the previously marked colors to find out which vertices can be reached from the start vertex and the connected components of the graph (see the tests for this method on GitHub: [https://mng.bz/EZ6O](https://mng.bz/EZ6O)).[](/book/grokking-data-structures/chapter-13/)

DFS can traverse all edges and visit all vertices of a graph, so its running time is `O(n+m)`, like for BFS.

## What’s next

The section on DFS concludes our discussion on graphs, this chapter, and the whole book. If you’d like to learn more about graphs and the algorithms that run on graphs, I recommend the following books:[](/book/grokking-data-structures/chapter-13/)[](/book/grokking-data-structures/chapter-13/)

-  *Advanced Algorithms and Data Structures* (M. La Rocca, 2021, Manning)
-  *Introduction to Algorithms* (Cormen, Leiserson, Rivest, Stein, 2022, MIT Press)
-  *Graph-Powered Machine Learning* (A. Negro, 2021, Manning)
-  *Graph Databases in Action* (D. Bechberger, J. Perryman, 2020, Manning)

This is the end of our tour of data structures, and I hope you enjoyed it and are motivated to learn more. Your journey with data structures has just begun, and the wonderful news is that you have many great books to read to learn more about data structures. In addition to classic textbooks such as *Introduction to Algorithms* or *The Algorithms Design Manual*, here are some great Manning books to check out:

-  *Grokking Algorithms (Second Edition)* by A. Bhargava is somewhat complementary to this book. It focuses more on algorithms you can run on data structures, such as sorting or searching.
-  *Optimization Algorithms* by A. Khamis: Learn about advanced search algorithms, evolutionary algorithms, and machine learning.
-  *Advanced Algorithms and Data Structures*: Along with a deeper discussion of graphs, it introduces advanced data structures such as randomized heaps, tries, k-d trees and Ss+Trees, and more. [](/book/grokking-data-structures/chapter-13/)

## Recap

-  Graphs are much more than containers: they can model relationships between entities (called vertices) connected by edges.
-  Graphs are a generalization of trees. Specifically, trees are simple, connected, and acyclic graphs.
-  A graph is *simple* if it has at most one edge between any pair of vertices and no loops (that is, an edge from a vertex to itself).
-  A graph is *connected* if, given any pair of vertices, it’s possible to find a sequence of edges going from one vertex to the other. If a graph is not connected, we can decompose it into its connected components.
-  A graph is *cyclic* if it has at least one path that starts and ends at the same vertex; otherwise, the graph is said to be *acyclic*.
-  In a *directed* graph, edges can only be traversed in one direction—from their source to their destination. Twitter follows are best modeled using a directed graph. In an *undirected* graph, all edges can be traversed in both directions. An example would be Facebook friendship.
-  Graphs are usually implemented using either an *adjacency list* or an *adjacency matrix*. The latter is only used in niche contexts.
-  *Breadth-first search* (*BFS*) is an algorithm for traversing graphs and finding paths with the minimum number of edges between a start vertex and the rest of the graph.
-  *Depth-first search* (*DFS*) searches the graph by following paths to their end. It can be used to check many properties of the graph, such as whether the graph is connected and has cycles.[](/book/grokking-data-structures/chapter-13/)
