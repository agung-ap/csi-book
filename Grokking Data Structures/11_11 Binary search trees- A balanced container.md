# 11 Binary search trees: A balanced container

### In this chapter

- modeling hierarchical relationships with trees
- binary, ternary, and n-ary trees
- introducing data constraints into binary trees: binary search trees
- evaluating the performance of binary search trees
- discovering how balanced trees provide better guarantees

[](/book/grokking-data-structures/chapter-11/)This chapter marks a shift from the previous few chapters, where we focused on containers. Here, we discuss trees, which is a data structure—or rather a class of data structures! Trees can be used to implement several abstract data types, so unlike the other chapters, we won’t have an ADT section here. We’ll go straight to the point, describing trees, and then focus on one particular kind of tree—the binary search tree (BST). We’ll describe what trees do well and how we can make them work even better.[](/book/grokking-data-structures/chapter-11/)

## What makes a tree?

In chapter 6, we discussed linked lists, our first composite data structure. The elements of a linked list, its nodes, are themselves a minimal data structure. Linked lists are based on the idea that each node has a single successor and a single predecessor—except for the head of the list, which has no predecessor, and the tail of the list, which has no successor.[](/book/grokking-data-structures/chapter-11/)

[](/book/grokking-data-structures/chapter-11/)However, things are not always so simple, and the relationships are more intricate. Sometimes, instead of a linear sequence, we need to represent some kind of hierarchy, with a single, clear starting point, but then with different paths branching out from each node.

### Definition of a tree

A generic tree is a composite data structure that consists of nodes connected by links. Each node contains a value and a variable number of links to other nodes, from zero to some number `k` (the branching number of a k-ary tree, that is, the maximum number of links a node can have).

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/11-01.png)

There is a special node in each tree, called the root of the tree. Its peculiarity is that no other node in the tree points to the root.

If a node `P` has a link to another node `C`, then `P` is called the parent of `C`, and `C` is a child of `P`. In the figure, the root of the tree has two children, with values `2` and `8`. Some trees also have explicit links from children to parents, to make traversing of the tree easier.

When a node has no links to children, it’s called a leaf. The other nodes, which do have children, are called internal nodes. In the figures in this section, there are six leaves with values `5`, `1`, `2`, `3`, `4`, and `7`.

For a tree to be well-formed, every node must have exactly one parent, except for the root, which has none. This means that if `C` is a child of `P`, the only path from the root to `C` goes through `P`. It also means that all paths from the root to a leaf are simple, that is, there is no loop in a tree. In other words, in any path from the root to a leaf, you will never see the same node twice. Let’s get a few more definitions before moving on.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/11-02.png)

A node `N` is an ancestor of a node `M` if `N` is in the path between the root and `M`. In that case, `M` is called a descendant of `N`. In other words, a descendant of a node `N` is either one of the children of `N` or the descendant of one of the children of `N`. Of course, the root is the one ancestor that all the other nodes have in common. In the figure, we can also see that node `8` is an ancestor of node `7`.

All children of the same node are siblings. There is no direct link between siblings, so the only way to get from one sibling to another is through their common parent.

A subtree is a portion of the tree containing a node `R` (called the root of the subtree) and all the descendants of `R`. Each child of a node is the root of its own subtree.

The height of a tree is the length of the longest path from the root to a leaf. The height of the tree in the figure is `3` because there are multiple paths with three links, such as `0`→`2`→`6`→`3`. The subtree rooted at the node with value `8` has a height of `2`.

### From linked lists to trees

[](/book/grokking-data-structures/chapter-11/)Linked lists model perfectly linear relationships, where we have defined a total order on the elements in the list: the first element goes before the second, which goes right before the third, and so on. However, a tree can easily represent a partial relation, where there are elements that are comparable and ordered and others that are not comparable or have no relationship between them.[](/book/grokking-data-structures/chapter-11/)[](/book/grokking-data-structures/chapter-11/)

To visualize this difference, how about considering two different approaches to breakfast? I’m talking, of course, about the European continental breakfast, which is usually more sweet than savory.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/11-03.png)

Anyway, food aside, let’s consider two approaches. The first approach is the methodical approach. Let’s take as an example someone who always eats their cereal in the morning and repeats the same gestures in the same order. This linear approach can be modeled using a linked list.

Our second option is what I would call the inspirational approach. Most mornings, I’ll stick to my diet and eat cereal without adding sugar. Some other mornings, I feel a little down, and I add sugar to my cereal to sweeten up my day. And sometimes, when I’m feeling mopey, I skip the cereal altogether and go straight for the ice cream bucket! This approach, involving choices and multiple options, could not be represented by a linked list—we need a tree for that.

Table 11.1 summarizes additional differences and similarities between linked lists and trees.

##### Table 11.1 A comparison between linked lists and trees[(view table figure)](https://drek4537l1klr.cloudfront.net/larocca3/HighResolutionFigures/table_11-1.png)

| Linked list | Tree |
| --- | --- |
| A single node has no predecessor (the head). | A single node has no parent (the root). |
| A single node has no successor (the tail). | Many nodes don’t have children (the leaves). |
| Each node has exactly one outgoing link to its successor. | Each node has zero, one, or many links to its children. |
| Doubly linked lists: each node has exactly one link to its predecessor. | In some trees, nodes have links to their parents. If they do, each node has exactly one link to its only parent. |

### Binary trees

[](/book/grokking-data-structures/chapter-11/)Binary trees are defined[](/book/grokking-data-structures/chapter-11/) by restricting each node to a maximum of two children. Thus, in a binary tree, a node may have zero, one, or two child links. We usually label these two links: we have the left and right children of a node, and thus its left and right subtrees. The order of the children, however, isn’t always important for all binary trees.[](/book/grokking-data-structures/chapter-11/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/11-04.png)

### [](/book/grokking-data-structures/chapter-11/)Some applications of trees

The number of areas where trees are used is impressive. Whenever we need to represent hierarchical relationships, trees are the answer. Trees are used in machine learning, and decision trees and random forests are some of the best nonneural network classification tools. We have discussed the heap in chapter 10, which is a special tree that efficiently implements priority queues. There are many more specialized trees, such as b-trees, which are used to store data efficiently (like in databases), or kd-trees, which allow the indexing of multidimensional data. But these are just the tip of the iceberg: trees are a very large class of extremely versatile data structures.[](/book/grokking-data-structures/chapter-11/)

## Binary search trees

Besides modeling relationships, we can also use trees as containers. We did so with heaps, whose scope is narrow. But we can have a more general-purpose container, which we discuss in the rest of this chapter—the *binary search tree* (BST). Its name gives away some of its properties: it’s a tree, it’s binary, so each node has (optionally) a left and a right child, and it’s used for searching.

These trees are designed to make search fast, potentially as fast as binary search on a sorted array. And they have one important advantage over sorted arrays: insertion and deletion can be faster on a BST. What’s the catch, and what’s the tradeoff? Like linked lists, trees require more memory to implement, and their code is more complex, especially if we want to guarantee that these operations are faster than on arrays.

In this section, we will describe the BSTs as data structures and discuss their implementation.[](/book/grokking-data-structures/chapter-11/)

### Order matters

Similarly to heaps, where we have constraints on the structure and data of the tree, to go from a binary tree to a BST, we have to add a property on the data stored in the nodes.[](/book/grokking-data-structures/chapter-11/)

##### DEFINITION

All BSTs abide by the *BST property*: for any node `N` that stores a value `v`, all nodes in the left subtree of `N` will have values less than or equal to `v`, and all nodes in the right subtree of `N` will have values greater than `v`.[](/book/grokking-data-structures/chapter-11/)

Bear in mind that there is an asymmetry between the two subtrees: if there are duplicates, we need a way to break the tie so that we always know where to find possible duplicates of a node’s value. The choice of the left subtree is completely arbitrary, based only on convention.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/11-05.png)

#### Class definition and constructor

This is a good time to discuss the implementation of the class for BSTs. Since we are dealing with a composite data structure, we need to implement an outer class for the public interface, shared with the clients, and an inner, private class for the node representation. I implemented a lean version of the `Node` class, and most of the action will happen in the outer class. Just know that the other way around is also possible:[](/book/grokking-data-structures/chapter-11/)[](/book/grokking-data-structures/chapter-11/)[](/book/grokking-data-structures/chapter-11/)

```
123456789class Node:
    def __init__(self, value, left=None, right=None):
        self._value = value
        self._left = left
        self._right = right
    def set_left(self, node):
        self._left = node
    def set_right(self, node):
        self._right = node
```

Here I have left out the getter methods, which just return references to the private fields of a `Node` (you can find them in the full code in the book’s repo). While the left and right children of a node can be later changed using the setter methods shown here, I won’t allow a node’s value to be changed. If you want to change the value of a node in the tree, you’ll have to create a new `Node` instance and set its children.[](/book/grokking-data-structures/chapter-11/)[](/book/grokking-data-structures/chapter-11/)

The constructor[](/book/grokking-data-structures/chapter-11/) for the outer class is even simpler. We just need to initialize the root to the empty node:

```
123class BinarySearchTree:
    def __init__(self):
        self._root = None
```

### Search

If we look more closely at the data property on a BST, we can learn some interesting things. Given a node in the tree, we can associate a range of possible values to its subtrees and to the edges of its left and right children.[](/book/grokking-data-structures/chapter-11/)

Each node `N` containing a value `v` partitions the possible values in its subtree so that if we traverse the tree using the left link, we can only find values `x`≤`v`, while if we go right, we can only find values `x>v`.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/11-06.png)

But we actually know more than that, because the constraints of the ancestors of a node are also valid for its children. In the example shown in the figure, if we traverse the left branch from the root, we know that we can only find values `x`≤`6`. Then, we find a node with value `4`. Its right subtree can only have values `>4`, but because of its parent, in the whole subtree rooted at `4`, there can’t be any value `>6`, so for any `x` in the right subtree of the node `4`, we know that `4`<`x`≤`6`.

That’s a lot of information: How can we use it?

The answer is, in searching. If we search our example tree for a certain value, say `100`, the moment we look at the root, we realize that our target can only be in the right subtree of the root. This means that we don’t need to look at the left subtree at all! Similarly, if the value is less than (or equal to) the root’s, we don’t need to look at the right subtree.

[](/book/grokking-data-structures/chapter-11/)What happens with the next node, the one that, in our example, stores the value `7`? The same principle applies—we either go left or right (in this case, if we are still looking for `100`, we go right). At each node, we can only go left or right. We never climb up the tree, toward the root. At some point, if we haven’t found our target yet, we will try to follow a null link. Either we are at a leaf or we have reached an intermediate node with a single child (a left child when we want to go right, or vice versa). There we know that our search is unsuccessful because our target couldn’t be in any other path in the tree. And why is that? Because at every turn, at every node, the two (possible) subtrees are mutually exclusive, and so we followed the only path where the target value could have been stored.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/11-07.png)

The fact that the search method follows a single path, from the root to (possibly) a leaf, means that it will take no more steps than the height of the tree—it needs `O(h)` comparisons, where `h` is the height of the tree.

Now let’s look at the implementation. The search method takes a value and returns the node of the tree that contains that value, or `None` if no such value is stored in the tree. Similar to what we did with linked lists, this method is provided as a private method because we don’t want to expose the internal structure of the tree to clients. We can easily provide a public `contains` method that checks whether a search returned `None`.[](/book/grokking-data-structures/chapter-11/)

Now, I’m going to show you a variant of the search method that returns a tuple—together with the node found, we return its parent. The reason is that if we don’t store a reference to the parent of the node, we are in a situation similar to that of a singly linked list, where we have to remember the predecessor of a node while scanning the list, otherwise, we won’t be able to retrieve the predecessor later:

```
def _search(self, value):
    parent = None                    #1
    node = self._root
    while node is not None:
        node_val = node.value()
        if node_val == value:
            return node, parent      #2
        elif value < node_val:
            parent = node
            node = node.left()
        else:
            parent = node
            node = node.right()
    return None, None                #3
#1 We start from the root, and its parent is None.
#2 Target found!
#3 If it gets here, we broke out of the loop without finding the target.
```

### Find the minimum and maximum

[](/book/grokking-data-structures/chapter-11/)Before moving on to the methods that modify a BST, I’d like to discuss a special kind of search: finding the maximum and minimum elements in a tree. This is a simpler task than a generic search. In fact, we know exactly where these two elements will be in the tree.[](/book/grokking-data-structures/chapter-11/)

For example, to get the maximum element, we start at the root and follow the links to the right children until we reach a node that has no right child. This node (which could be the root itself, of course) stores the maximum value in the tree. Why is that? Because if we ever turn left at some point, even after we reach a node with no right child, then the values we could find in the left subtree could be at most the same as the value stored in the current node.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/11-08.png)

It works similarly for the minimum, except we always go left instead of right. Now, let’s take a look at the implementation for the method to find the maximum—we will use it again soon.

A key BST feature is its recursive structure—each subtree is also a valid BST. This also means that we can find the maximum and minimum of any subtree of the main tree. So, let’s implement in the `Node` class the method that finds the maximum of the subtree rooted at the given node:[](/book/grokking-data-structures/chapter-11/)

```
def find_max_in_subtree(self):
    parent = None
    node = self
    while node.right() is not None:
        parent = node
        node = node.right()
    return node, parent
```

Note that, as with `_search`, we also need to return the parent of the node that was found.

### Insert

[](/book/grokking-data-structures/chapter-11/)Now that we know how to search a BST and how to create an empty BST, we need to learn how to populate it! The insertion method is very similar to the way we do search. That’s no coincidence. When we insert a new element, we are actually searching for the position that this new element would have in the tree if it was already inserted.[](/book/grokking-data-structures/chapter-11/)

Of course, there are some differences with the search method. We can’t stop when we find the same value that we want to insert (unless we don’t allow duplicates, but that’s an edge case). Instead, if we find another occurrence of the value we want to insert, we keep traversing the tree by making a left turn.

In general, when we get to a node, we first check the value it stores to understand which branch we need to traverse and whether we need to go left or right. Suppose we figure out that we need to go left. If the node has no left child, we have found the place where we have to add the new element. All we have to do is create a new node and attach it as a left child of the current node. The case where we need to go right is treated symmetrically.

Let’s look at a few examples to clarify how insertion works.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/11-09.png)

In the first example, we add a duplicate of the value at the root of the tree, `6`. At the root, we go left, as we always do when we find the same value as the one stored in a node. We traverse this branch until we reach the leaf with the value `5`, and we know we can add our new node there.

I’ve always found it curious how two occurrences of the same value can end up so far apart in a BST. In a sorted array, they would be adjacent, but not in a BST. Keep this in mind as we will talk about it again.

In the other case presented, we add the largest value yet in the tree, so we traverse a path to the far right of the tree, and there we add a new node for the value `11`.

The code for the `insert` method isn’t much different from the `search` method:[](/book/grokking-data-structures/chapter-11/)[](/book/grokking-data-structures/chapter-11/)[](/book/grokking-data-structures/chapter-11/)

```
def insert(self, value):
    node = self._root
    if node is None:                                      #1
        self._root = BinarySearchTree.Node(value)
    else:
        while node is not None:
            if value <= node.value():
                if node.left() is None:                   #2
                    node.set_left(BinarySearchTree.Node(value))
                    break
                else:                                     #3
                    node = node.left()
            elif node.right() is None:                    #4
                node.set_right(BinarySearchTree.Node(value))
                break
            else:                                         #5
                node = node.right()
#1 The tree is empty.
#2 We have found the right place for the new value.
#3 We need to keep traversing the left branch of this subtree.
#4 Here as well, we have found the right place for the new value.
#5 We need to keep traversing the right branch of this subtree.
```

Since insertion in a BST is equivalent to an unsuccessful search, its running time is also `O(h)`, where `h` is the height of the tree.

### Delete

While adding an element is relatively straightforward, deleting one is much more complicated. But again, this method relies heavily on `search` since what we need to do is find the value we want to delete and get a reference to the node that contains it. This is preferable to directly passing the node to be deleted to the `delete` method. Among other things, we also need a reference to the parent of this node to be deleted.[](/book/grokking-data-structures/chapter-11/)[](/book/grokking-data-structures/chapter-11/)

When we delete a node, we have to distinguish between the following three situations:

-  We are deleting a leaf.
-  We are deleting a node with only one child.
-  The node we want to delete has both children.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/11-10.png)

For each of these cases, we have a slightly different workflow when the node to be deleted is the root. In all these situations, we assume that we have already performed a search and found the node `N` to be deleted and its parent `P`.

#### D[](/book/grokking-data-structures/chapter-11/)eleting a leaf

[](/book/grokking-data-structures/chapter-11/)This is the simplest case—a leaf by definition has no children, so there are no loose ends to tie up. The only thing we need to do is sever the link between the parent node and the one we want to remove from the tree. This is why we need to return the parent node in a successful search.[](/book/grokking-data-structures/chapter-11/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/11-11.png)

What happens if the node to be deleted is the root and has no parent? If the root is a leaf, then removing it will leave us with an empty tree.

#### D[](/book/grokking-data-structures/chapter-11/)eleting a node with only one child

If the node we want to delete has exactly one child, the process is still simpler compared to nodes with two children. We can directly link the child to the parent of the deleted node.[](/book/grokking-data-structures/chapter-11/)[](/book/grokking-data-structures/chapter-11/)

Here, we have four cases. The node `N` can have a left or right child, and `N` itself can be the left or right child of `P`. The four cases can be treated in the same way, and the only thing that changes is which pointers are used.

To clarify, let’s consider the case where the child `C` of node `N` is a right child. In our example, we want to delete the value `7` from the tree.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/11-12.png)

What we need to do is cut the links between `P` and `N` and `N` and `C`, and create a new direct link between `P` and `C`. In this example, since `N` was also a right child of `P`, `C` is set as the new right child of `P`. This way `S`, the former right subtree of `N`, is moved up and is now the right subtree of `P`.

What if `N` was the root of the tree? Well, in that case, all we would have to do is update the root, and we would be done.

#### Deleting a node with both of its children

This is the most complicated case. Suppose we want to delete node `4` in the BST we used as an example throughout this section. (We’ll actually use a slightly different tree for clarity.)[](/book/grokking-data-structures/chapter-11/)

Once we find it, we realize that the node `N` we want to delete has both children. So, we can’t just short-circuit the link from its parent `P` to one of its children because we wouldn’t know how to fix the other subtree of `N`. We can’t even bubble up values like we did in the heap!

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/11-13.png)

Instead, to replace the node we delete, we would need a value that is smaller than any element in the right subtree of `N` and not smaller than any other value in the left subtree of `N`. This value `v` is the predecessor of `N` in the subtree rooted at `N`. It’s the one value that, if we sorted all the values in the subtree rooted at `N`, would be just before `value(N)`.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/11-14.png)

In our example, this value is `3`, which happens to be the maximum of the left subtree of node `4`! Well, that’s not a coincidence. The value `v` we are looking for is *always* the maximum of the left subtree of `N`. And even better for us, the node `M` that contains this maximum can’t have a right subtree.

In fact, if `M` had a right subtree, it would mean that there was a node in the left subtree of `N` that has a value greater than `v`, which is a contradiction. So, this means that if we were to delete `M`, we would be in either case 1 or case 2 of the delete method. In other words, it’s easy to delete node `M`, and that’s great for us!

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/11-15.png)

So, here is the plan to delete node `4`: we replace the value of the node with its predecessor in the subtree rooted at `4`, which is node `3`. Then we delete node `3` in the left subtree of `4`, knowing that this node, being the maximum of `left(4)`, will be easy to delete. And then, we are done.

### Putting it all together

[](/book/grokking-data-structures/chapter-11/)Now that we have discussed how to solve all the possible cases for deleting a node, let’s put it all together and write a method for the BST class. This is going to be the most complicated method we have written so far.[](/book/grokking-data-structures/chapter-11/)

The main differences with what we have discussed in the previous subsections are implementation details, like the fact that we won’t just replace the value in the node to be deleted, but rather replace the whole node.

```
def delete(self, value):
    if self._root is None:
        raise ValueError('Delete on an empty tree')
    node, parent = self._search(value)
    if node is None:
        raise ValueError('Value not found')
    if node.left() is None or node.right() is None:                   #1
        maybe_child = node.right() if node.left() is None
            else node.left()                                        #2
        if parent is None:                                            #3
            self._root = maybe_child
        elif value <= parent.value():
            parent.set_left(maybe_child)
        else:
            parent.set_right(maybe_child)
    else:
        max_node, max_node_parent = node.left().find_max_in_subtree() #4
        if max_node_parent is None:                                   #5
            new_node = BinarySearchTree.Node(max_node.value(), None, node.right())
        else:
            new_node = BinarySearchTree.Node(
                max_node.value(),
                node.left(),
                node.right())
            max_node_parent.set_right(max_node.left())
        if parent is None:
            self._root = new_node
        elif value <= parent.value():
            parent.set_left(new_node)
        else:
            parent.set_right(new_node)
#1 This branch covers cases 1 and 2.
#2 This instruction allows us to later use the same code for both variants of case 2, and also for case 1 when both children are None.
#3 If parent is None, then node is the root. Otherwise, check whether node is a left or right child.
#4 Find the max in the left subtree of the node to be deleted.
#5 In this case, it means the max of the left subtree is exactly the left child of node.
```

In none of the three cases we ever climb up the tree, but we always follow a path from the root to a leaf. Therefore, `delete` also takes at most `O(h)` steps.

### Traversing a BST

[](/book/grokking-data-structures/chapter-11/)Traversal is one of the fundamental operations of data structures. For some of the data structures we have discussed so far, the way to traverse them was obvious. For arrays and linked lists, you start at the beginning and proceed linearly. For other data structures, traversal was disabled. The elements in stacks, queues, and priority queues can only be iterated by being removed from the container.[](/book/grokking-data-structures/chapter-11/)[](/book/grokking-data-structures/chapter-11/)

For BSTs, we are stepping on to uncharted territory in our journey. This data structure is inherently nonlinear, so how do we traverse it?

For a generic binary tree, there are three ways to traverse it:

-  Pre-order, where we visit each node before its subtrees.
-  Post-order, where we visit the subtrees of a node before visiting it.
-  In-order, where, given a node `N`, we first visit its left subtree, then `N`, then its right subtree.

For a BST, the option that makes more sense is in-order.

To understand why, let’s consider a mini-BST, with a root and two children, and check in what order the nodes would be visited:

-  Pre-order: `B A C`
-  Post-order: `A C B`
-  In-order: `A B C`

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/11-16.png)

In-order is the only way to get the sorted sequence of elements in a BST. You can find the code for the in-order traversal on the book’s GitHub repo: [https://mng.bz/9de1](https://mng.bz/9de1).

### Predecessor and Successor

[](/book/grokking-data-structures/chapter-11/)Exceptionally, for BSTs, we describe two additional operations: finding the predecessor and successor of a node. Formally, given a collection `C` without duplicates, the successor of an element `x` is the element `s`, which is the minimum among the elements in `C` that are greater than `x`. Similarly, the predecessor of `x` is the maximum among the elements that are less than `x`.[](/book/grokking-data-structures/chapter-11/)[](/book/grokking-data-structures/chapter-11/)[](/book/grokking-data-structures/chapter-11/)[](/book/grokking-data-structures/chapter-11/)

These operations are trivial in a sorted array and in a sorted doubly linked list—the predecessor and successor of an element `x` are (if present) adjacent to `x`, literally the element before and after `x` in the data structure.

In the unsorted versions of these DSs, the operations are still not complicated, but they become expensive—we have to scan the whole container to find a successor.

What about BSTs? We know that elements in a BST follow a certain order, but getting predecessor and successor is not a constant-time operation.

When discussing the `delete` method, we discovered that, given a node `N`, the predecessor of `N` limited to the subtree rooted at `N` is the maximum of `N`’s left subtree (if it exists). However, when it comes to finding the predecessor of a node `N` in the whole tree, it’s not so simple:

-  If `N` has a left subtree, then yes, its predecessor is the maximum of that subtree.
-  If `N` does *not* have a left subtree and it’s a right child, then its parent is also its predecessor.
-  If `N` does *not* have a left subtree and it’s a left child, we have to climb up the tree until we find node `M` that is a right child—its parent is the predecessor of `N`.
-  If we reach the root before finding such a node, then it means that `N` is the minimum of the tree, and it has no predecessor.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/11-17.png)

To implement this method in a BST that doesn’t store links to the nodes’ parents we would have to use a technique called *backtracking*, which is beyond the scope of this book. You can read more about these methods in *Introduction to Algorithms* (Cormen, Leiserson, Rivest, Stein, 2022, MIT Press), chapter 12, page 258.[](/book/grokking-data-structures/chapter-11/)

The two important things I want you to remember are that these two operations are harder than you might think and that they take `O(h)` time in a BST.

Exercises

[](/book/grokking-data-structures/chapter-11/)11.1 Implement a `BST` class where nodes contain a link to their parent, and then add the predecessor and successor methods.[](/book/grokking-data-structures/chapter-11/)

11.2 Can you find an example among the BSTs shown in the previous sections where the `predecessor` method described above would fail? Hint: Refer to the next exercise.[](/book/grokking-data-structures/chapter-11/)

11.3 When a BST contains duplicates, then getting the predecessor of a node is a bit more complicated, while the `successor` method can work as it is. Can you explain why?[](/book/grokking-data-structures/chapter-11/)

11.4 How can we fix the `predecessor` method to deal with duplicates?[](/book/grokking-data-structures/chapter-11/)

## Balanced trees

All the operations we have seen on BSTs take time proportional to the height of the tree. Is that a good thing? This question translates to, given a BST with `n` nodes and height `h`, is `O(h)` better than `O(n)`? It certainly can’t be worse, but the question is, could it be `O(h) = O(n)`?[](/book/grokking-data-structures/chapter-11/)[](/book/grokking-data-structures/chapter-11/)[](/book/grokking-data-structures/chapter-11/)

### Binary search trees in action

Mario, our little friend who’s learning computer science, got burned when he challenged his mother. If you remember, in chapter 3, he bet—and lost—that he was faster at finding baseball cards from a deck. Mario knows he can’t trick his mother that easily, but he wants to use what he learned to pull a fast one on someone else. So, he decides to try his mother’s trick against his classmate Kim. But Mario wants more than just to win. He wants to impress Kim, so he plans to use BSTs (which he just learned about from his parents’ computer science textbooks) instead of a sorted array.[](/book/grokking-data-structures/chapter-11/)

The challenge is the same. They are each given half of Mario’s deck of cards, and each of them prepares a list of cards to find in the shortest time possible.

The only problem for Mario is that Kim knows BSTs better, and when she hears that he wants to go that way, she quickly arranges her half of the cards deck so that the cards are almost sorted (descending, in reverse order).

When Mario starts to build his BST on the floor of his room, he realizes that she played him. The tree won’t fit in his room, and Mario has to continue building a long, long branch out in the hallway.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/11-18.png)

By the time he gets back to his room, Kim has already found her five cards, leaving Mario mopey and defeated. Finally, he asks her, “I know you tricked me, but what happened here?”

### Adversary insertion sequences

[](/book/grokking-data-structures/chapter-11/)What Kim did was select a carefully crafted sequence that is known to cause trouble to BSTs. If we insert the elements of a BST from the smallest to the largest (or vice versa), we get completely skewed trees that look like linked lists.[](/book/grokking-data-structures/chapter-11/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/11-19.png)

In these extreme cases, the height of the tree is exactly `n`. If you think about it, it’s ironic how we get the worst performance from sequences that were already sorted!

To prove that for generic BSTs, `O(h) = O(n)` in the worst case, that single example of a worst-case scenario would be enough. Unfortunately, it’s not the only one. We don’t have to be so unlucky as to have all the elements inserted in their final order to get a skewed tree. If we can find in the insertion sequence a (nonadjacent) subsequence of half, or say a quarter, or a fifth (and so on) of the sorted elements, then the height of the tree will be at least `n/2`, `n/4,` or `n/5`. And we know that `O(n/5) = O(n)`.

### Delet[](/book/grokking-data-structures/chapter-11/)ions make your tree skewed

There are two other sources of imbalance for the BSTs. First, when we have duplicates, as you know, we break ties by always going left. This means that the left branches will be slightly larger on average than the right branches.[](/book/grokking-data-structures/chapter-11/)

Second, and worse, when we delete values from a BST, we always take the maximum of the left branch of the node to be deleted. It means we make the left branch increasingly smaller, and after many deletions, the tree will be fairly skewed, with the right branches sensibly larger than the left branches.

### Tre[](/book/grokking-data-structures/chapter-11/)e balancing

From what we have discussed so far, things don’t look good for BSTs. If we choose the wrong insertion order, we get a skewed tree. And if we perform a lot of deletions on the tree, we also get a skewed tree. So, are we doomed?[](/book/grokking-data-structures/chapter-11/)

There are some tricks we can use that might help. If we have some control over the insertion sequence, we can shuffle the order of the input sequence to reduce the probability of having an even partially sorted sequence. And one way to deal with the imbalance caused by `delete` is to randomly alternate between the predecessor and successor of the value to be deleted to replace it.

But often, we don’t have control over the insertion sequence, which could be dynamic and “just in time.” And anyway, none of these tricks can give us a guaranteed upper bound on the height of the tree.

However, in chapter 10, we discussed the heap, whose height is guaranteed to be `O(log(n))` for `n` elements: Can we get something similar for BST? Of course, the structure of the heap is different—for a heap, we don’t store a total ordering of the nodes, and this makes it easier to keep its height logarithmic.

But there are also ways to force a BST to be *balanced*. A binary tree is said to be *height-balanced* if, for any node, the difference in height between its left and right subtrees is at most 1, and both of its subtrees are also balanced.

There are data structures, evolutions of the BST, which can guarantee this condition. One of these structures uses the properties of the heap to achieve balance: randomized heaps are a nondeterministically balanced binary search tree. You can read more about them in chapter 3 of *Advanced Algorithms and Data Structures* (La Rocca, 2021, Manning).

The most used balanced search trees are, however, red–black trees and 2–3 trees. You can read more about them in the same chapter of *Advanced Algorithms and Data Structures*, or in chapter 13 of *Introduction to Algorithms* (Cormen, Leiserson, Rivest, Stein, 2022, MIT Press), and in section 3.3 of *Algorithms 4th Edition* (Sedgewick, Wayne, 2020, Pearson), respectively.

With a *balanced binary search tree* (BBST), operations such as search, insertion, and deletion can be performed on the tree in `O(log(n))` time. This makes BBSTs the data structure with the best average performance across the full range of operations: there are some operations where a sorted array or a linked list might be faster, but the average over all operations favors BBSTs.[](/book/grokking-data-structures/chapter-11/)

And that also answers the question, What do I need BSTs for? You can use them to do the same things as a sorted array, but overall faster.

## Recap

-  Trees are recursive data structures consisting of nodes. Each node stores a value and a certain number of links to children. Each child is the root of a valid subtree.[](/book/grokking-data-structures/chapter-11/)
-  Trees are perfect for modeling hierarchical relationships and any situation with paths branching out of intersections.
-  In binary trees, each node can have zero, one, or two children. Nodes without children are called leaves. The other nodes, called internal nodes, have one or two children.
-  Links to children in a binary tree are usually labeled “left” and “right.” In some, but not all, binary trees, this distinction may have a meaning.
-  In a *binary search tree* (BST), for any node `N`, the left subtree of `N` can only contain values not greater than `N`’s, and the right subtree can only contain values greater than `N`’s.
-  BSTs are good for search—if the tree is balanced, search can be completed by comparing at most `O(log(n))` elements.
-  In general, for a BST with `n` nodes and height `h`, all operations (insertion, deletion, search, predecessor and successor, maximum and minimum) take `O(h)` time.
-  For *balanced binary search trees* (BBST), the height `h` of the tree is guaranteed to be `O(log(n))`, and so all the above operations take logarithmic time.[](/book/grokking-data-structures/chapter-11/)
