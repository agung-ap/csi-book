# 10 Priority queues and heaps: Handling data according to its priority[](/book/grokking-data-structures/chapter-10/)

### In this chapter

- introducing the priority queue abstract data type
- the difference between queue and priority queue
- implementing a priority queue with arrays and linked lists
- introducing the heap, a data structure for the priority queue abstract data type
- why heaps are implemented as arrays rather than trees
- how to efficiently build a heap from an existing array

[](/book/grokking-data-structures/chapter-10/)In chapter 9, we talked about queues, a container that holds your data and returns it in the same order in which it was inserted. This idea can be generalized by introducing the concept of priority, which leads us to priority queues and their most common implementation—heaps. In this chapter, we discuss both, together with some of their applications.

## Extending queues with priority

In the previous chapter, we saw some examples of queues in real life, such as the line to get an ice cream. Not all queues, however, have such a linear development. In an emergency room, for example, the next person to see a doctor isn’t necessarily the person who has waited the longest, but rather the one who needs the most urgent care. And the order is dynamic, not set in stone.[](/book/grokking-data-structures/chapter-10/)[](/book/grokking-data-structures/chapter-10/)[](/book/grokking-data-structures/chapter-10/)

In this section, we introduce the concept of priority and derive from that a variant of the plain queue called *priority queue*.

### Handling bugs (revised)

Remember Priyanka, our software engineer who handles bugs at an early-stage startup? We met her in chapter 9. She has re-engineered the way bugs are handled at her company, making sure no bugs get lost.[](/book/grokking-data-structures/chapter-10/)[](/book/grokking-data-structures/chapter-10/)

The new system works well, so well that she is overwhelmed with work. To manage this, Priyanka has decided to bring in a small team specifically dedicated to addressing and fixing bugs. But that alone is not enough. There is a step in the protocol she created that makes her waste a lot of time.

If you remember, the process was largely automated: engineers would send an email with the bug they found, and a daemon would extract the bug from the email and add it to a bug queue. At this point, however, it was up to Priyanka to look at the bug and decide whether it was urgent. If the bug was urgent, it had to be fixed immediately. Otherwise, it was enqueued back to the rear of the queue.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/10-01.png)

Deciding whether a bug is urgent is expensive in terms of Priyanka’s time. To assess the urgency of a bug, Priyanka often has to reach out to the engineer who filed the bug or to the team who owns the area affected by the bug to understand the context and the impact of the bug.

It takes her a long time to process each bug. It also requires commitment from other engineers, and the effort may be wasted if they agree that the bug is not urgent.

To turn the situation around, Priyanka has an idea: What if it’s up to the person filing the bug to say whether it is urgent or not? She and her team may still have to talk to the owners of the affected code to fix the bug, but they will do so only after someone else has determined that a bug is urgent and needs to be fixed right away. This modification requires a change in the queue. Now, when Priyanka asks for the next bug, the system doesn’t return the oldest bug, but the most urgent one.

To allow for some more flexibility, Priyanka creates a system with four levels of urgency: desired, needed, urgent, and critical. “Critical” is for those bugs that should have been fixed yesterday because they affect the end users. At the other end of the scale, “desired” fixes can wait. They usually are tech debt—improvements that you want to add even if they don’t really affect the end user.

To handle the bugs according to their priority, a regular queue is not enough. It must be replaced with a priority queue.[](/book/grokking-data-structures/chapter-10/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/10-02.png)

You’ll notice that in a priority queue, we no longer need to keep track of the rear of the queue. That’s because when a new element enters the queue, it’s not placed last, but its position is determined by its priority.

### The abstract data type for priority queue

As with plain queues, there are two important methods that we need to include in the interface of a priority queue: one to add a new element to the queue and one to get the element with the highest priority. Traditionally, we use a different nomenclature for these methods. The one that adds a new element is just called `insert`. There is less consensus about the one that pulls and removes the highest-priority item. It is sometimes called `pull_highest_priority_element` (sometimes shortened as `pull`), `extract_max`, or just `top`. I’ll go with the latter, for personal preference and brevity.[](/book/grokking-data-structures/chapter-10/)[](/book/grokking-data-structures/chapter-10/)[](/book/grokking-data-structures/chapter-10/)[](/book/grokking-data-structures/chapter-10/)[](/book/grokking-data-structures/chapter-10/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/10-03.png)

The contract that a priority queue establishes with its clients is that the queue will always return the element with the highest priority. How this is done is not something we need to specify at the abstract data type (ADT) level: as always, we’ll talk about it when we get to the data structure level.

Exercises

10.1 Priority queues are based on the notion of priority. But they also are still queues. What choice for the priority of an element would make a priority queue behave like a simple queue?

10.2 What could be a possible choice for the priority of an element that would make a priority queue behave like a stack?

## Priority queues as data structures

[](/book/grokking-data-structures/chapter-10/)How can we store the data of a priority queue? We have two alternatives: we can keep the elements sorted by priority, or we can search for the current highest-priority element every time we have to return it.[](/book/grokking-data-structures/chapter-10/)

Let’s discuss the former option first. Throughout this section, we will show examples with integers, where higher numbers mean higher priority.

### Sorted linked lists and sorted arrays

Maintaining the elements sorted by priority simplifies the `top` method. In fact, for this method, we only need to return the element at the front of the queue. The `insert` method, however, has to deal with new elements, adding them to the existing data and making sure that the order is maintained. Two data structures are good candidates to implement this behavior: sorted linked lists and sorted arrays.[](/book/grokking-data-structures/chapter-10/)[](/book/grokking-data-structures/chapter-10/)[](/book/grokking-data-structures/chapter-10/)[](/book/grokking-data-structures/chapter-10/)

For linked lists, the singly linked variant is sufficient because we can simply remove elements from the head of the list, while insertion takes linear time anyway. We keep the elements sorted from highest (head) to lowest (tail) priority, and when we add a new element, we must scan the list until we find the right place for it, just as we discussed in chapter 6. Deleting an element from the front, however, is a constant-time operation, as you should know by now.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/10-04.png)

With arrays, we can use a similar strategy, but we have to be smart to keep the running time of `top` as fast as possible. We have two options for the order of elements: we can sort them from highest to lowest priority, or vice versa. In the first case, to remove the element with the highest priority, we would have to move all the other elements in the array. So, the right way is to have the highest priority at the end of the array.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/10-05.png)

### Unsorted linked lists and unsorted arrays

[](/book/grokking-data-structures/chapter-10/)The opposite alternative is to use the unsorted version of these two data structures. Insertion becomes easy and constant-time in both cases, because we can just append a new element wherever it’s more convenient. This means at the front of a linked list and at the end of an array.[](/book/grokking-data-structures/chapter-10/)[](/book/grokking-data-structures/chapter-10/)

Conversely, extracting the highest priority element becomes complicated because no information about the elements is available. We have no choice but to go through the whole list, element by element, keeping track of the highest priority found.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/10-06.png)

### Performance overview

Table 10.1 recaps what we have learned so far.

##### Table 10.1 An initial comparison of various implementations of a priority queue[(view table figure)](https://drek4537l1klr.cloudfront.net/larocca3/HighResolutionFigures/table_10-1.png)

|   | `insert()` | `top()` | Dynamic size |
| --- | --- | --- | --- |
| Sorted static array | `O(n)` | `O(1)` | No |
| Unsorted static array | `O(1)` | `O(n)` | No |
| Sorted linked list | `O(n)` | `O(1)` | Yes |
| Unsorted linked list | `O(1)` | `O(n)` | Yes |

Linked lists and arrays behave similarly. If we keep them sorted, insertion is slow, and getting the top element is fast. For the unsorted variants, the opposite is true.

These are two extremes, completely sorted sequences and completely unsorted ones, with opposite extreme behaviors. Wouldn’t it be nice if there was an intermediate solution that allows us to do better than `O(n)` for both operations?

### Partial ordering

[](/book/grokking-data-structures/chapter-10/)For a sorted array `A`, if we pick two indices `i` and `j`, with `i < j`, we immediately know that `A[i]` ≤ `A[j]`. That’s because a sorted array is totally ordered, so given two elements, we can immediately know how they compare based on their position. We know where to find the largest element in the array, and if we remove it, we also know which element will take its place. At the opposite extreme, in unsorted arrays we have no information at all.

The more information we have, the more expensive it is to build and maintain the data structure. Trivially, we have to compare more elements to fully sort an array.

The key to better performance is to share the load between these two operations and balance the minimal information required with the maximal elements accessed per operation. The balance is achieved by ordering the elements only partially. This idea stems from the consideration that, as mentioned earlier, we don’t need to know, at all times, the exact order in which the elements will be returned—we just need the next one.

## Heap

In the previous chapters, when discussing the data structures for implementing an ADT, I often mentioned that it is always possible to design a new data structure from scratch, but that this is usually not the best alternative. Now it’s time to discuss an exception to the rule.[](/book/grokking-data-structures/chapter-10/)[](/book/grokking-data-structures/chapter-10/)

The best data structure to implement a priority queue is neither an array nor a linked list. We can’t reuse a stack or a queue for this task. Instead, we introduce a new type of data structure that we haven’t met before.

In the rest of this section, we will discuss the *heap* and how we can use it to implement priority queues.

### A special tree

A heap is a special kind of tree. If you are not familiar with tree data structures, don’t worry. I’m going to explain what we need here, but you can also refer to chapter 11 to get the basics.[](/book/grokking-data-structures/chapter-10/)

In this chapter, we restrict ourselves to binary heaps, which means that we will use binary trees. And, in fact, property 1 of a binary heap is that each node of the tree can have at most two children.

This is not strictly necessary for heaps—they can be ternary trees, quaternary trees, and so on. However, binary heaps are the simplest, and they are enough to fulfill our needs in most cases. If you’d like to learn more about d-way heaps (heaps where nodes have more than two children), you can read a detailed description in chapter 2 of *Advanced Algorithms and Data Structures* (La Rocca, 2021, Manning).

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/10-07.png)

You might have noticed that the nodes in a tree are organized into levels. In the following example, the root of the tree, a node labeled with the letter M, is the only node at level 0. At level 1, we have two nodes, the two children of node M, labeled with B and Z, and so on.

But a heap is not just any binary tree. To be a binary heap, a tree must satisfy two additional properties.

Property 2 is a structural property. The heap tree is “almost complete,” which means that every level of the tree, except possibly the last level, is complete; furthermore, the nodes on the last level are as far left as possible.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/10-08.png)

[](/book/grokking-data-structures/chapter-10/)Finally, property 3 is about the data in the heap. In a heap, each node holds the highest priority element in the subtree rooted at that node.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/10-09.png)

This last property guarantees that the element with the highest priority is always at the root of the heap. The problem now, of course, is that we need to restore these properties when a new element is added to or when the root is extracted from the heap. We’ll explain how to do this in the next section when we discuss the implementation layer for heaps.

### Some properties of a heap

From the foundational properties of heaps, there follow some other very interesting properties. From property 3, we can infer that all paths from the root to any leaf of the tree are sorted.[](/book/grokking-data-structures/chapter-10/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/10-10.png)

Incidentally, this is a possible partial sorting of an array—it’s the tradeoff we talked about in the last section, where we don’t have all the information about how each pair of elements compares, but we do have some information.

From properties 1 and 2, instead, we can infer some interesting structural properties. First, we know exactly how many nodes there will be at each level.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/10-11.png)

At the first level, level 0, there can only be the root. Since each node can have at most two children, level 1, where the children of the root are, can have at most two nodes. Iterating, we can say that the next level has four nodes, and in general, each level `i` can have at most `2``i` nodes (and it will have exactly `2``i` nodes, unless it’s the last level). The index `i` of the levels is their height, that is, their distance from the root.

From all these properties, we derive that the heap’s height (that is, the length of the longest root-to-leaf path) is as small as `log(n)` for a heap with `n` elements. Don’t worry, I won’t go into the math. I’ll leave that to you as an exercise!

### Performance of a heap

The reason why having a bound on the height of the heap is so important is that we can implement `insert` and `top` operations so that they only walk a path from the root to a leaf or vice versa. This, in turn, means that their running time is proportional to the height of the heap.[](/book/grokking-data-structures/chapter-10/)[](/book/grokking-data-structures/chapter-10/)

So, if `insert` and `top` on a heap take time proportional to the height of the heap (and they do—I’ll show you this in the next section), then we can update Table 10.1 to Table 10.2, which shows that heaps provide a more balanced performance for the operations on a priority queue.

##### Table 10.2 An updated comparison of various implementations of a priority queue[(view table figure)](https://drek4537l1klr.cloudfront.net/larocca3/HighResolutionFigures/table_10-2.png)

|   | `insert()` | `top()` |
| --- | --- | --- |
| Sorted array/linked list | `O(n)` | `O(1)` |
| Unsorted array/linked list | `O(1)` | `O(n)` |
| Heap | `O(log(n))` | `O(log(n))` |

### Max-heap and min-heap

Before we get into how to implement a heap, I’d like to make a clarification. You can often find the heaps that we have shown in the examples described as max-heaps: a max-heap is a heap where each parent has a value no smaller than its children. Consequently, the root of a max-heap contains its largest element.[](/book/grokking-data-structures/chapter-10/)[](/book/grokking-data-structures/chapter-10/)

What if we need to have the smallest elements at the root (because we want to extract the next smallest element in a sequence)? In this case, you can often see a min-heap being used—a heap where each parent has a value no larger than its children.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/10-12.png)

Using the idea of a min-heap can be confusing and complicate heap implementation as it inverts parent–child comparisons and the necessary checks. I believe the correct way to handle heaps is through the concept of priority—a heap always has the highest priority element at the root, and for each parent–child pair, we guarantee that `priority(P)` ≥ `priority(C)`. Then, for example, if we want to have smaller numbers at the top of the heap, we can define the priority of a number `x` as `-x`, the opposite of `x`.

This requires defining and applying a function to get the priority of an element, but it removes all ambiguity and gives us more flexibility.

Exercise

10.3 Can you prove that the height of a heap with `n` elements is `log(n)`? Hint: Remember, the heap is an almost complete tree.

## Implementing a heap

Now that we have established that we need a new data structure for priority queues, it’s time to look at how to implement it. I also postponed the discussion of the main operations on a heap, which would normally be part of the DS layer. There is a reason for this: they are heavily influenced by how we implement a heap, and there is a plot twist that we need to unveil before we can talk about implementation. But we need to follow a certain order to explain everything.[](/book/grokking-data-structures/chapter-10/)[](/book/grokking-data-structures/chapter-10/)

### How to store a heap

We could certainly store a heap as a tree, similarly to what we do with linked lists and what we will see in chapter 11. However, we don’t usually do this because there is a better way. To explain why, we need to go back to the second property of a heap. Because a heap is an almost complete binary tree, we know exactly how many nodes we have at each level.[](/book/grokking-data-structures/chapter-10/)

Let’s try to add an incremental index to each node, starting with 0 for the root, and traversing the tree from top to bottom and from left to right.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/10-13.png)

There are a few things we can infer from this figure. Take, for example, the node with index 3. We know that its parent has index 1, and its children have indexes 7 and 8. Similarly, for the node with index 2, its parent’s index is 0, and its children’s indexes are 5 and 6.

We can devise a rule: given a node with an index `i > 0`, its parent’s index is given by the integer division `(i - 1) / 2`, and its children have indexes `2 * i + 1` and `2 * i + 2`. That’s interesting, but what can we do with this information?[](/book/grokking-data-structures/chapter-10/)

Here is another consideration that will help us figure that out: we assigned the indexes so that all the nodes at level 1 come before the nodes at level 2, which come before the nodes at level 3, and so on. An almost complete tree is left justified, which means that there is no “hole” in our indexing, and even at the last level, we know exactly where in the tree the node with index 8 is.

We saw this idea earlier when we talked about arrays: elements in a static array are (usually) kept left justified, with no gaps between the first and last element. And indeed, there is a parallel between this tree and arrays.

If we reorganize the elements of the tree linearly, placing each level side-by-side, the indexing we assign to the nodes will perfectly match the indexing of an array with the same elements.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/10-14.png)

And here is the plot twist—we end up using an array to store the heap’s data! Well, it’s a special array with some constraints and some useful properties, but nonetheless, it’s an array. In the rest of this section, we’ll assume the array has enough space to store the elements we add, and so we’ll treat it as a static array for the purposes of analyzing the operations on the heap. By now, you know that if you need a dynamic array instead, the bounds on the running time are not meant as worst case, but rather as amortized.

### Constructor, priority, and helper methods

Given all that you have learned in the previous subsection, you can imagine that we will define a `Heap` class that uses an array (a Python list) as an internal attribute. As discussed earlier, I prefer passing a function to extract element priority, ensuring the highest priority is always on top of the heap:[](/book/grokking-data-structures/chapter-10/)[](/book/grokking-data-structures/chapter-10/)[](/book/grokking-data-structures/chapter-10/)

```
class Heap:
    def __init__(self, elements=None, element_priority=lambda x: x):
        self._priority = element_priority
        if elements is not None and len(elements) > 0:
            self._heapify(elements)
        else:
            self._elements = []
```

I also strongly encourage you to always develop some helper methods that take care of the details of comparing the priority of two elements, finding an element’s parent, and finding its children. Besides giving you cleaner code, abstracting these operations into their own methods will help you reason about more complex operations without having to check each time if you need to use `<` or `>`, or if you got the formula to get the index of the parent node right:

```
def _has_lower_priority(self, element_1, element_2):
    return self._priority(element_1) < self._priority(element_2)
def _has_higher_priority(self, element_1, element_2):
    return self._priority(element_1) > self._priority(element_2)
def _left_child_index(self, index):
    return index * 2 + 1
def _parent_index(self, index):
    return (index - 1) // 2
```

There is one more helper method, `_heapify`, which builds a heap from an existing array. However, we’ll talk about it at the end of this section.[](/book/grokking-data-structures/chapter-10/)

Once we have defined these methods, we are ready to discuss the main operations on a heap. For the examples in this chapter, we will use the bug queue example we discussed at the beginning of the chapter, with one change: priorities are decimal numbers instead of classes. A higher number indicates a higher priority.

### Insert

Let’s start with insertion. To help you visualize what we are doing, I’ll show you the tree and array representations of the heap side by side. We will use this heap/bug queue as the starting state.[](/book/grokking-data-structures/chapter-10/)[](/book/grokking-data-structures/chapter-10/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/10-15.png)

Each element is a pair with the bug description and its priority. In the tree representation, most of the descriptions are omitted due to space limitations. For the same reason, going forward, I’ll only display the descriptions in the array representation.

Now, suppose we want to add a new element. Like we said, we assume that the array has been allocated with enough space to append new elements, and we only show the portion of the array that is actually populated, leaving out the empty cells.

We want to add the tuple `("Broken Login", 9)`. First, we add the new element to the end of the array. But then we notice that the new element breaks the third property of heaps because its priority is higher than its parent!

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/10-16.png)

What can we do to fix this? Here is an idea: swap the child and parent nodes! This will fix the priority hierarchy for both of them, and it will also be fine with the sibling node (the one with index 7) because it was already not greater than the old parent, which, in turn, is smaller than the new element.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/10-17.png)

[](/book/grokking-data-structures/chapter-10/)But we are not done yet. The new element, even in its new position, can still break the heap’s properties. And indeed, it does because its priority is higher than its new parent, the node with index 1. To restore the heap’s properties, we *bubble up* the new element until it either reaches the root of the heap or we find a parent with higher priority. In our case, this means just one more hop and we are done.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/10-18.png)

Code-wise, I have extracted the bubble-up part into its own helper method so that the `insert` method itself looks clean and short. Just append a new element to the end of the array, and then bubble it up:

```
def insert(self, element):
    self._elements.append(element)
    self._bubble_up(len(self._elements) - 1)
```

Of course, the complexity is all in the helper method. This method contains an optimization. Instead of repeatedly swapping the same element with its current parent, we trickle down those parents that should be swapped and finally store the new element in its final position:

```
def _bubble_up(self, index):
    element = self._elements[index]
    while index > 0:
        parent_index = self._parent_index(index)
        parent = self._elements[parent_index]
        if self._has_higher_priority(element, parent):
            self._elements[index] = parent  #1
            index = parent_index
        else:
            break                           #2
    self._elements[index] = element
#1 There is a violation of the heap’s properties, and we need to swap the new element with its parent.
#2 The new element and its parent don’t violate the heap’s properties, so we have found the final place to insert the new element.
```

How many elements do we have to swap? We can only bubble up the new element on a path from a leaf to the root, so the number of swaps is at most equal to the height of the heap. Therefore, as I promised, insertion on a heap takes `O(log(n))` steps.

### Top

Now let’s start with the heap of nine elements we obtained after inserting `("Broken Login", 9)` and remove its highest priority element, the root of the heap. Just removing the element from the heap leaves us with a broken tree. There are two subtrees, each of which is a valid heap, but their array representation is broken, that is, without a common root.[](/book/grokking-data-structures/chapter-10/)[](/book/grokking-data-structures/chapter-10/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/10-19.png)

Shifting the remaining elements would mess up the heap’s indexing and structure. Similarly, bubbling up one of the former root’s children (like in `insert`) won’t work because, first, we’d be moving to one of the subtrees the hole left by the former root. And second, we would have to bubble up the largest of the children. Depending on which one is the largest and on the structure of the heap, we might end up with a hole at the leaf level, breaking the “almost complete” property.

Here is a better option: How about we take the last element of the heap (in this case, the one with index 8) and move it to the root of the heap, replacing the former highest priority element? This will permanently fix the structural problem and restore the second property of the heap, making it an almost complete tree.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/10-20.png)

[](/book/grokking-data-structures/chapter-10/)Not all the properties of the heap, however, are now restored: the third property is still violated because the root of the heap is smaller than at least one of its children (this was likely to happen since we took a leaf, likely one of the smallest elements in the heap, and moved it to the root).

To reinstate all the heap’s properties, we need to *push down* the new root, down toward the leaves, swapping it with the smallest of its children until we find a place where it no longer violates the third property of the heap. Here is the final position that we found for element 6, with the path of nodes swapped to get there highlighted.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/10-21.png)

Similar to what we did with `insert`, we have a short method body for `top`, handling edge cases and the first step, where we move the last element of the array to the root of the heap:

```
def top(self):
    if self.is_empty():
        raise ValueError('Method top called on an empty heap.')
    if len(self) == 1:
        element = self._elements.pop()         #1
    else:
        element = self._elements[0]
        self._elements[0] = self._elements.pop()
        self._push_down(0)
    return element
#1 If the heap has a single element, we just need to pop its root.
```

[](/book/grokking-data-structures/chapter-10/)Most of the work is done by a helper method, _`push_down`.[](/book/grokking-data-structures/chapter-10/)

We need an extra helper method to find out which of a node’s children has the highest priority. The method returns `None` if the current node is a leaf (this will help us later):

```
def _highest_priority_child_index(self, index):
    first_index = self._left_child_index(index)
    if first_index >= len(self):
        return None                  #1
    if first_index + 1 >= len(self):
        return first_index           #2
    if self._has_higher_priority(self._elements[first_index], self._elements[first_index + 1]):
        return first_index
    else:
        return first_index + 1
#1 The current node has no children.
#2 The current node only has one child.
```

Once we have this method, `_push_down` becomes easier. What we have to do is, given a node, check whether it is a leaf (we’ll get `None` from the call to `_highest_priority_child_index`), and if so, we are done.[](/book/grokking-data-structures/chapter-10/)[](/book/grokking-data-structures/chapter-10/)

Otherwise, we compare the current element with the one of its children that has the highest priority. If they don’t violate the third heap property, we are also done. If they do, we have to swap them and repeat the process:

```
def _push_down(self, index):
    element = self._elements[index]
    current_index = index
    while True:
        child_index = self._highest_priority_child_index(current_index)
        if child_index is None:
            break
        if self._has_lower_priority(element, self._elements[child_index]):
            self._elements[current_index] = self._elements[child_index]
            current_index = child_index
        else:
            break
    self._elements[current_index] = element
```

As with insert, we optimize the method by avoiding explicit swapping. But how many swaps would we have to do? Again, we can only go along a path from the root to a leaf, so it’s a number at most equal to the height of the heap.

This time, we have another aspect we need to check. We are swapping the element pushed down and the smallest of its children, so we need to find that first. How many comparisons do we need to find out which child is the smallest and if we need to swap it with the pushed-down element? We need at most two comparisons for each swap, so we are still good because we have `O(log(n))` swaps and `O(2*log(n)) = O(log(n))` comparisons.

So, this shows that the logarithmic bound I have anticipated for this method is indeed correct.

### Heapify

One more heap operation to discuss is the *heapification* of a set of elements—creating a valid heap from an initial set of elements. This operation is not part of the priority queue interface because it’s specific to heaps. The context is as follows: we have an initial array with `n` elements (no assumptions can be made about their order), and we need to build a heap containing them. There are at least two trivial ways of doing this:[](/book/grokking-data-structures/chapter-10/)[](/book/grokking-data-structures/chapter-10/)[](/book/grokking-data-structures/chapter-10/)

-  We can sort the elements—a sorted array is a valid heap.
-  We can create an empty heap and call insert `n` times.

Both operations take `O(n*log(n))` time and possibly some (up to linear) extra space.

But heaps allow us to do better. In fact, it’s possible to create a heap from an array of elements in linear time, `O(n)`. This is another advantage compared to using sorted arrays to implement a priority queue.

We start with two considerations: every subtree of a heap is a valid subheap, and every leaf of a tree is a valid subheap of height 0. If we start with an arbitrary array and represent it as a binary, almost complete tree, its internal nodes may violate the third property of heaps, but its leaves are certainly valid subheaps. Our goal is to build larger subheaps iteratively, using smaller building blocks.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/10-22.png)

In a binary heap, at least half (plus/minus 1) of the nodes are leaves, so only the other half of the nodes, the internal nodes, can violate the heap properties. If we take any of the internal nodes at the second-to-last level, level 2 in the example, it will have one or two children, both of which are leaves and therefore valid heaps. Now we have a heap with a root that might violate the third property and two valid subheaps as children—exactly what we have discussed for the `top` method, after replacing the root with the last element in the array. So, we can fix the subheap by pushing down its current root.[](/book/grokking-data-structures/chapter-10/)[](/book/grokking-data-structures/chapter-10/)

In the example, the only internal node of level 2 is the one at index 3, which violates the heap properties. After pushing it down, the subtree rooted at index 3 becomes a valid heap.[](/book/grokking-data-structures/chapter-10/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/10-23.png)

Next, we go to level 1, where the only other node whose children are leaves is the one at index 2. Note that, if there are `n/2` leaves, then there are `n/4` internal nodes whose children are only leaves. In this example, there are only two of them, for five leaves (here, the division is assumed to be an integer division).

We try to push down the root of the subtree, but in this case, there is nothing else to do. Now, all the subheaps of height 1 are valid. We can move to the subheaps of height 2 (there is only one of them) and then to the subheaps of height 3, which is the whole heap in this example.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/10-24.png)

It’s easier to code it than to explain or understand it. The body of `_heapify` is just a few lines: it copies the collection in input to a new array, then computes the index of the last internal node of the heap (using a helper function that returns the index of the first leaf) and finally iterates over the internal nodes, pushing each of them down. It’s important to go through the internal nodes from the last (the deepest in the tree) to the first (the root) because this is the only way to guarantee that the children of each node we push down are valid heaps:[](/book/grokking-data-structures/chapter-10/)[](/book/grokking-data-structures/chapter-10/)

```
def _heapify(self, elements):
    self._elements = elements[:]
    last_inner_node_index = self._first_leaf_index() - 1
    for index in range(last_inner_node_index, -1, -1):
        self._push_down(index)  
def _first_leaf_index(self):
    return len(self) // 2
```

How long does it take to heapify an array? It takes `O(n)` comparison and assignments. For a mathematical proof, you can take a look at section 2.6.7 of *Advanced Algorithms and Data Structures* (Manning, 2021) available at [https://mng.bz/KZX0](https://mng.bz/KZX0).[](/book/grokking-data-structures/chapter-10/)

I’ll give you some idea here. For `n/2` nodes, the heap leaves, we don’t do anything. For `n/4` nodes, the parents of the leaves, `_push_down` will do at most one swap. The pattern continues, with at most two swaps for `n/8` nodes (the parents of the `n/4` ones in the previous step, and so on, for `log(n)` of such terms). The sum of these numbers of operations is `O(n)`.

## Priority queues in action

Now that we understand how a heap works, let’s see it in action! In this section, we’ll discuss a nontrivial example of how we can use a heap. And we’ll meet some old friends!

### Find the k largest entries

[](/book/grokking-data-structures/chapter-10/)After breaking the ice with programming and arrays, Mario is on a roll. In chapter 2, we saw him using an array to store the statistics of a die to find out if the die was fair. Now he wants to reuse those skills to win the lottery.[](/book/grokking-data-structures/chapter-10/)

His idea is simple (and statistically unsound, but Mario is in seventh grade, so he can’t know that yet). He wants to keep track of which numbers are drawn most frequently in the national lottery and play the lottery with the six most frequent numbers. His assumption that these are the most likely numbers to be drawn is, as we know, wrong, but his parents encourage him to go ahead with his project to develop some analytical and programming skills.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/10-25.png)

So, they find Mario the records of the weekly lottery drawing for the last 30 years and set him up with a computer and a Python interpreter. They also help him code the I/O part so that he can assume that the numbers drawn can be inserted one at a time. Mario’s application doesn’t remember when a number was last drawn. It just counts how many times it appears among the winning six.

He reuses the program he wrote for the dice to store the number of occurrences of each of the 90 numbers that can be drafted in the lottery. Eventually, after hours of typing and entering all 30 years of data, he gets an array with 90 entries, where `drawn[i]` is the number of times the number `i` has been drawn in the last 30 years. (For the sake of simplicity, the array is allocated for 91 elements, and he just ignores the first entry.)

To find out what the most frequently drawn numbers are, Mario plans to sort the array and take the first six entries. But when he talks to his friend Kim about his plan, she challenges him: “I can write a more efficient solution.” Kim is really good at coding, and in their class, they just studied priority queues. So, Mario accepts the challenge and takes a swing at a better solution: “How about using `heapify` to create a heap with 90 elements and then extract the six largest ones?”

Kim grins: “That’s better, but I can still improve it!”

“See,” she adds, “if we had to pick the `k` largest out of `n` elements, sorting all of them would take `O(n*log(n) + k)` steps. Your solution would take `O(n + k*log(n))` steps and `O(n)` extra space. But I can do it in `O(n*log(k) + k)` steps and with only `O(k)` additional space.”

When Mario gasps in surprise, Kim cheers and explains to him how the better solution works. She will create a heap, inserting elements as tuples `(number, frequency)`. But she won’t use a regular heap—this heap will only store `k` elements, in this case the six largest elements found so far.

Here is the crucial bit: the heap must be a min-heap. Or rather, in terms of priority, the priority of an element must be the opposite of its frequency, so that the root of the heap will hold the one element with the lower frequency.

She will then look at the lottery numbers one by one and compare them to the root of the heap. If the root of the heap is smaller, she will extract it and then insert the new entry. Eventually, only the six more frequently drawn entries will be in the queue.[](/book/grokking-data-structures/chapter-10/)

Here is some code that does the job:

```
def k_largest_elements(arr, k):
    heap = Heap(element_priority=lambda x: -x[1])
    for i in range(len(arr)):
        if len(heap) >= k:
            if heap.peek()[1] < arr[i]:
                heap.top()                 #1
                heap.insert((i, arr[i]))
        else:
            heap.insert((i, arr[i]))
    return [heap.top() for _ in range(k)]

print(k_largest_elements(drawn, 6))
#1 When we remove the smallest element, we don’t need the value. We just discard it.
```

Now Mario has only one question tormenting him: Should he share the money with Kim if they win?

## Recap

-  Priority queues generalize regular queues, allowing us to use criteria other than the insertion order to determine which element should be extracted next.
-  A *priority queue* is an abstract data type that provides two operations: `insert`, to add a new element, and `top`, to remove and return the element with the highest priority.[](/book/grokking-data-structures/chapter-10/)[](/book/grokking-data-structures/chapter-10/)
-  Priority queues can be implemented using different data structures, but the maximally efficient implementation is achieved using heaps.
-  A *binary heap* is a special type of tree. It’s a binary, almost complete tree, where each node has a priority higher than or equal to its children’s. The root of the heap is the element with the highest priority in the heap.[](/book/grokking-data-structures/chapter-10/)[](/book/grokking-data-structures/chapter-10/)
-  Heaps have another characteristic. They are a tree that is better implemented as an array. This is possible because a heap is an almost complete tree.
-  With the array implementation of a heap, we can build a priority queue where `insert` and `top` take logarithmic time.
-  Additionally, it’s possible to transform an array of `n` elements into a heap in linear time, using the `heapify` method.
