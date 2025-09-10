# 7 Abstract data types: Designing the simplest container—the bag

### In this chapter

- the difference between an abstract data type and a data structure
- arrays and linked lists: are they data structures or data types
- the key properties of a container
- meet the bag, the simplest possible container

[](/book/grokking-data-structures/chapter-7/)By now, you should be familiar with arrays and linked lists, which were the focus of our first six chapters. These are core data structures, ubiquitous in computer science and software engineering. But more than that, they are also *foundational* data structures, which means that we can—and will—build more complex data structures on top of them.[](/book/grokking-data-structures/chapter-7/)

In chapter[](/book/grokking-data-structures/chapter-7/) 2, we discussed how arrays can be approached as concrete language features or as abstract data types. In this chapter, we will discover that this duality isn’t limited to arrays. We will then talk about an important class of abstract data types—containers—which will be our focus in the next five chapters.

This chapter is a bridge between the first half of the book, where we have discussed core data structures and principles, and the second half, where we focus on data structures that build on top of what we have learned so far.

Here, we bridge the gap by introducing the first of many examples taken from the containers class—bags.

## Abstract data types vs. data structures

What’s the difference between a data structure and an abstract data type? We have scratched the surface of this question when we discussed arrays. [](/book/grokking-data-structures/chapter-7/)[](/book/grokking-data-structures/chapter-7/)

An abstract data type (ADT) focuses on what operations you can perform on the data, without specifying how those operations are implemented. A data structure, conversly, specifies more concretely how data is represented, as well as algorithms for performing operations on that data.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/07-01.png)

For example, we can look at arrays as the concrete language feature provided by some programming languages, that is, contiguous blocks of memory that can be divided into cells of equal size, each of which can hold an element of a given (and fixed) type. Or, we can consider a higher abstraction of arrays, focusing on the operations they can offer—constant-time read/write of the elements based on indexes—and ignoring how they are implemented.

In this section, I will first give a more formal definition that highlights the differences between these two views, and then we will look at a few examples to illustrate what we have learned.

### Definitions

Designing and building software is a complex process that usually starts with an abstract idea and refines and enriches it until we get to a code implementation. For data structures, we can think of a three-level hierarchy to describe this design process.[](/book/grokking-data-structures/chapter-7/)

An *abstract data type* (ADT) is a theoretical concept that describes at a high level how data can be organized and the operations that can be performed on the data. It provides little or no detail about the internal representation of the data, how the data is stored, or how physical memory is used. ADTs provide a way to reason at a high level about ways to structure data and the operations that this structuring allows.

We described what a *data structure* (DS) is in chapter 1, but let me give you an alternative definition here: a data structure is a refinement of the specifications provided by an ADT where the computational complexity of its operations—how data is organized in memory (or disk!) and the internal details of the DS—are normally discussed.

There is a third level in this hierarchy: the *implementation*. At the DS level, we don’t worry about the language-specific problems and quirks involved in coding a data structure. For a linked list, we define how a node is designed and what it contains, but we don’t worry about how the memory for the node is allocated or whether the link to the next node should be a pointer or a reference. Instead, at the implementation level, we have to write code for the data structure, so we choose a programming language and translate the general instructions given by the data structure into code.

These three levels are a hierarchy of abstraction of the way in which we can describe data structures in computer software. The relationship between the levels in this hierarchy are, going from top to bottom, always one-to-many: an ADT can be further specified by many DSs, and a DS can have many implementations (some of which may be equivalent), even in different programming languages. The same DS can also be used to implement several ADTs: we’ll see in this and the next few chapters how a dynamic array or a linked list can implement very different ADTs.[](/book/grokking-data-structures/chapter-7/)[](/book/grokking-data-structures/chapter-7/)

##### Table 7.1 Examples of abstraction versus implementation[(view table figure)](https://drek4537l1klr.cloudfront.net/larocca3/HighResolutionFigures/table_7-1.png)

| Abstraction (ADT) | Implementation (DS) |
| --- | --- |
| Vehicle | Car Truck Motorbike |
| Seat | Chair Sofa Armchair Beanbag chair |
| List | Dynamic array Linked list |
| Stack | Dynamic array Linked list |
| Queue | Dynamic array Linked list |

### Arrays and linked lists: ADT or DS?

So much for the definitions. Let’s discuss a few examples to help you get an idea: What better place to start than with arrays, which we discussed at length in the early chapters of this book?[](/book/grokking-data-structures/chapter-7/)[](/book/grokking-data-structures/chapter-7/)[](/book/grokking-data-structures/chapter-7/)[](/book/grokking-data-structures/chapter-7/)

Hopefully this won’t come as a surprise, but arrays can fit into any of the following three levels:

-  *Arrays as ADT*—Here we define an array as a high-level abstraction of a sequence of elements. Each element has an intrinsic order and a position (index) associated with it. It must be possible to access each element by its index.
-  *Arrays as DS*—In addition to what is specified by the ADT, we enforce that accessing any element in the array must be a constant-time operation. Note that this is one of many possible data structure definitions for arrays—in another definition, we could, for example, force all the elements to be of the same type.
-  *Array implementation*—At this level, we consider arrays as language features (for those languages that provide them natively). An array must be allocated in a single, contiguous block of memory, and all its elements must use the same memory and be of the same type. For those languages that don’t provide arrays, we can write our own implementation, like I did here: [https://mng.bz/Ad9K](https://mng.bz/Ad9K).

For *linked lists,* the definitions I gave in chapter 6 are already at the data structure level. Here, we specify how the data is organized internally using nodes, how these nodes are designed, and how the operations performed on linked lists work. We also moved toward the implementation level with Python code.

What about the ADT level? We can, of course, define an ADT that is refined by the linked list data structure.

We can call it a *list*—a sequence of elements that can be traversed in some order (the ordering criterion is not important at this level). The elements can be accessed sequentially.

Do you know which other data structure is a refinement of the *list* ADT? If you said arrays, bingo! Linked lists and arrays are two refinements, two data structures, stemming from the same abstract data type.

##### Table 7.2 A comparison of the running time of arrays and linked lists[(view table figure)](https://drek4537l1klr.cloudfront.net/larocca3/HighResolutionFigures/table_7-2.png)

|   | Insert front | Insert back | Insert middle | Delete | Search |
| --- | --- | --- | --- | --- | --- |
| Array | `O(n)` | `O(1)` | `O(n)` | `O(1)*` | `O(n)` |
| Singly linked list | `O(1)` | `O(n)` | `O(n)` | `O(n)` | `O(n)` |
| Doubly linked list | `O(1)` | `O(1)` | `O(n)` | `O(1)**` | `O(n)` |

*   If we can change the order of the elements, switching the element to be deleted with the last element. Otherwise, it’s `O(n)`.

** If we have a link to the node to be deleted. Otherwise, if we have to find the node first, it’s `O(n)`.

You should keep this in mind because it will be an important topic in the next few chapters: we will define some abstract data types and discuss how they can be implemented with both arrays and linked lists.

### One more example: The light switch

Before wrapping up the discussion, let’s look at another example, from a different angle: the light switch.[](/book/grokking-data-structures/chapter-7/)[](/book/grokking-data-structures/chapter-7/)[](/book/grokking-data-structures/chapter-7/)

Yes, you read that right! We are leaving computer science aside for a minute to show you how this hierarchy of abstractions can be applied to a broader area of science and engineering and hopefully make the differences between these levels of abstraction even clearer. But this is also a useful exercise because a light switch is similar to a very common ADT—the Boolean ADT.

#### A light switch as an abstract data type

At the highest level of abstraction, a light switch is a device that has two states, on and off, and two methods:

-  One to turn (the light) on
-  The other one, to turn (the light) off

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/07-02.png)

That’s it! That’s all we need to specify. We can model an even more generic switch by abstracting its purpose, but for this example, let’s keep it tied to the state of the light.

The goal of defining an ADT is to specify an *interface*, a contract with users. As long as we stick to the interface, it doesn’t matter how we implement it, and we can even switch between different implementations without breaking any of the applications using our ADT.

#### A light switch as a data structure

As we move to the data structure level, we need to define more details about how we can interact with our device. Without going into the details of electrical engineering, we can design a few concepts for a light switch.

This is similar to designing different DSs that implement the same ADT: just like we can implement a list using arrays or linked lists, we can implement the switch abstraction using different physical designs.

The first alternative we have is the classic switch with a small toggle that moves up and down.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/07-03.png)

An equivalent design has two buttons that can be pressed, one for off and one for on. Pressing one button disengages the other.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/07-04.png)

A variant of this design has a single pressure button, that switches between the two states without any visible change to the device. But we can imagine many more variants, for example, a digital switch, why not?

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/07-05.png)

[](/book/grokking-data-structures/chapter-7/)All these designs have something in common: we are describing, still at a fairly high level, how the internal state is maintained and how we can interact to change the state. While at the ADT level we only defined the interface of the device (there must be two methods to turn it on and off), for the DSs we describe here, we also need to specify how these methods work (that is, which button to press, and what happens when we do).

#### Implementing a light switch

When it comes to building a functioning switch, we can take any of the data-structure-level specifications from the previous section and develop it further. How far? Right down to the smallest detail.

Take the two-button switch, for example. At the implementation level, we need to decide the dimensions of the switch and the buttons, the materials used to build it, whether the buttons will stay pressed or they will move back, the internals of the mechanism that closes/opens the circuit, and so on. We need to clarify everything that is needed to build a working switch.

Similarly, in software, at the implementation level, we need to write code that works in real applications.

## Containers

In the next five chapters, we focus on a particular class of data structures called *containers*, so, in this section, we introduce them and explain how this group of data structures is different and important for developers.[](/book/grokking-data-structures/chapter-7/)[](/book/grokking-data-structures/chapter-7/)

### Wha[](/book/grokking-data-structures/chapter-7/)t’s a container?

A container is an abstract concept, a definition for a large group of data structures with common characteristics. Basically, it is a collection of elements, usually of the same type (but not necessarily; especially in loosely typed languages, this constraint can be relaxed).

![A box is the epitome of a container.](https://drek4537l1klr.cloudfront.net/larocca3/Figures/07-06.png)

The main feature of containers is to provide a way to organize and store data in a structured way, which allows the efficient implementation of some key operations: accessing, inserting, deleting, and searching the elements a container holds. The purpose of a container is to hold multiple pieces of data as a single entity, allowing developers to work with collections of data more conveniently and efficiently.

Containers abstract away the complexities of data management. Remember back in chapter 2 when we discussed how to model an Advent calendar in software? I mentioned that we could have implemented the calendar as 25 different variables, but that would have been difficult. With an array, we can instead treat the calendar as a single entity, and the data is neatly organized and easily accessible by index.

And in case you were wondering, yes, arrays are containers, and so are linked lists. They are the core containers, the most basic ones, and perhaps the most important ones since they are the foundation for the more complex containers we will discuss in the next chapters.

We know that arrays and linked lists are very different, and they have pros and cons. Similarly, containers can vary in their underlying implementation and capabilities, but they all share the common feature of grouping data elements and a few other characteristics.

### What isn’t a container?

Are all data structures containers? No, many data structures are not considered containers.

For example, in chapter 13, we discuss *graphs*. While graphs, like containers, are a collection of elements, they are primarily used to represent relationships and connections between those elements and provide various algorithms for exploring those connections. They are not usually regarded as containers because their purpose is different from simply managing data, and their complexity is beyond that of containers.

Another interesting data structure we can use as an example is k–d trees. These special trees have the main purpose of organizing multidimensional data and allowing efficient proximity queries—they go far beyond containers, and they are also not designed to efficiently delete or search elements by value.

### Key features of containers

I mentioned[](/book/grokking-data-structures/chapter-7/) that containers have some common characteristics, but what are those? Let’s name a few:[](/book/grokking-data-structures/chapter-7/)

-  Containers are collections of elements. They hold multiple elements, which can be of the same or different types and can be stored in a particular order or without any order.
-  Containers typically provide the same set of basic operations to insert, delete, access, modify, and search elements in the collection.
-  Containers can be traversed. All containers offer a way to go through all their elements in sequence. At the implementation level, it’s common for containers to provide iterators that allow sequential access to all the elements in the collection and can be used, for example, in `for` loops.
-  Containers can maintain the elements they store in a certain order. The order can be based on the sequence of insertion (as we have discussed in lists), or follow specific rules, as we will see in the next three chapters with stacks, queues, and priority queues.
-  Containers are designed to provide efficient access to their elements. The complexity of common operations (that is, insert, delete, search) varies depending on the container type.

These features are extremely relevant to software development: any time we need to store elements that will be processed later, we need a container. Most algorithms require us to iterate through elements in a certain order; thus, choosing the right container becomes crucial in these cases, as following the wrong order can break an algorithm or degrade its performance.

Containers, in fact, also have differences, or each wouldn’t be considered as a different data structure. Some containers have specific constraints or rules about how elements can be added, accessed, or removed: we will look at many examples in the next three chapters, but we start right here, in the following section, with our first example.

## The most basic container: The bag

Can you imagine what the simplest possible container will look like? Meet the bag, the most basic container of all. It’s simpler than arrays and linked lists, which is ironic because we have to use either to implement a bag.[](/book/grokking-data-structures/chapter-7/)[](/book/grokking-data-structures/chapter-7/)[](/book/grokking-data-structures/chapter-7/)

![Remember our shopping cart from chapter 1? Yes, it is both a container and a bag!](https://drek4537l1klr.cloudfront.net/larocca3/Figures/07-07.png)

### Definition of bag

How can a bag be simpler than an array? Well, to begin with, when we add elements to an array, we keep the order of insertion. We can also access a specific element of the array by index, and we can delete elements by value or by index. The thing is, none of these features are strictly required by the definition of containers![](/book/grokking-data-structures/chapter-7/)[](/book/grokking-data-structures/chapter-7/)

We can insert elements and forget about the order of insertion. We don’t have to keep elements indexed either—we would still comply with the definition of container. These are all things that can be simplified, compared to arrays.

Starting with bags, we adopt a more formal way of defining data structures. We will do the same for all data structures in the rest of the book.

The first thing I would like to do is define the *abstract data type* for a bag, and that means specifying its interface: we need to clearly define the methods through which a client can interact with a bag. It’s not enough to specify the name, arguments, and return types of all the public methods of an ADT; we must also write in stone the behavior of each method, its *side effects*—the changes it will have on the internal state of the bag, if any—and what the method is expected to accomplish.[](/book/grokking-data-structures/chapter-7/)

Don’t worry, following this process for bags will make it clearer.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/07-08.png)

A bag is a collection of objects with the following methods:

-  `insert(x)`—Allows a client to add a single element to the bag. The order of insertion is not important, so an implementation of a bag doesn’t need to keep it.
-  `iterate()`—Allows a client to go through all the elements in the bag. The order in which elements are iterated is not guaranteed, and it can actually change from one iteration to another.[](/book/grokking-data-structures/chapter-7/)

At this point, we can also add that a bag can store duplicates (no uniqueness constraints, unless they come from the context in which a bag is used). Notice that there are no methods to remove or search elements. These two operations would normally be expected in a container, so bags are kind of borderline—a container with restrictions.

The definitions above fully describe the bag as an abstract data type, and now we can refine the above specifications to define a more concrete data structure. But first, let’s look at how we would use bags. After all, as we discussed when defining ADTs, we only need this high-level interface to add bags to the design of our application, while we postpone the definition of the data structure and the implementation.

### Bags in action

[](/book/grokking-data-structures/chapter-7/)When will you need to use a bag? Let’s look at an example. [](/book/grokking-data-structures/chapter-7/)[](/book/grokking-data-structures/chapter-7/)

Andrea is a backend engineer at the Beanbags company. She recently gave a presentation about how she used a bag container as a cache to collect daily statistics on orders.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/07-09.png)

When Sarah from the audience asked Andrea to explain how bags work, she replied, “Did you collect marbles as a kid?”

To better explain how a bag works, she uses an example with marbles. Imagine that our bag data structure can only contain marbles of different colors and patterns. We can add marbles one by one, and they will be inside the bag DS—like with a real bag containing marbles, after a certain number of marbles are added, it’s hard to figure out what’s inside the bag, and where—it’s pure chaos!

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/07-10.png)

When I was a kid (a long, long time ago!), my friends and I would collect marbles, but, eventually, we also wanted to play, build a marble track, and race. So before starting, everyone had to catalog their treasure (it was also a way to brag to the others!). To count how many marbles one had and how many of each type, there was only one way: pour the marbles on the sand and start counting.

In computer science, the equivalent procedure is iterating through the bag while counting the elements!

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/07-11.png)

[](/book/grokking-data-structures/chapter-7/)To make sure no one was cheating, sometimes, we would do a second pass to double-check what the other kids were saying. This meant going through a set of marbles again and, of course, the second time you counted them, they wouldn’t be in the same order. But if no one cheated or was sloppy, then the order didn’t matter, and the totals and breakdowns would match.

This is the same for a bag data structure: to compute statistics about the content of a bag (say, a set of marbles, or our daily orders), we must iterate through its elements. If we iterate twice, we may not get the elements in the same order, but even so, most of the computed statistics will match—all those statistics where the order doesn’t matter, like daily total or daily breakdown by type.

![Iterating through the elements of a bag may produce a different order, but statistics that do not depend on the order of the elements, such as sum or total by type, are not affected.](https://drek4537l1klr.cloudfront.net/larocca3/Figures/07-12.png)

### Implementation

Now that we have seen a few examples of how a bag should be used, we are ready to delve into its data structure definition and then its implementation.[](/book/grokking-data-structures/chapter-7/)[](/book/grokking-data-structures/chapter-7/)

#### The importance of randomness

Let me start with a premise: when defining bags as an ADT, I told you that for bags, we can ignore the order of insertion because the elements can be iterated upon in any order. It’s even fine if we don’t get the elements in the same order when we iterate through the bag a second time.[](/book/grokking-data-structures/chapter-7/)[](/book/grokking-data-structures/chapter-7/)[](/book/grokking-data-structures/chapter-7/)

But the fact it’s possible to iterate through elements in a *random* order doesn’t mean that we *must* randomly iterate through elements. In other words, when it comes to building a library that implements a bag, it’s fine if we always iterate through elements in the same order—unless, of course, the context requires that we use randomness, for example, because we are performing some operation whose good outcome depends on trying different (and possibly uniformly distributed) sequences.

##### Note

There is an important asymmetry here. While as the implementers of a bag, we could decide to always use a certain order for iterating elements, clients should not rely on that order because the definition of bags clearly states that no order is guaranteed.

There are other data structures where randomness is crucial. We won’t see them in this book, but you can find some examples in *Advanced Algorithms and Data Structures* (Manning, 2021). For bags, anyway, and in the absence of domain constraints, we can simplify our lives and just iterate through the elements in the order they are inserted. Again, the definition tells us that we are not forced to follow the order of insertion, but also that we are not forbidden to do so, and in this particular case, following the order of insertion makes our task less difficult.

#### Bags as a data structure

This consideration regarding the order of the elements frees our hands when it comes to defining a data structure to implement the bag ADT. Because we are not forced to return a random permutation of the elements, a bag becomes a special variant of a list, implementing only a subset of its instructions. It means that we can use any implementation of the *list ADT* (static arrays, dynamic arrays, linked lists) as a basis for our bag DS.[](/book/grokking-data-structures/chapter-7/)[](/book/grokking-data-structures/chapter-7/)

At the data structure level, we can also refine our definitions by adding the desired constraints for the running time and additional space taken by the bag’s methods, and the additional space required by the DS to store the elements.

So, let’s see the options we have here:

-  *Static arrays*–We could add elements in (worst-case) constant time and iterate through the elements in linear time. But the problem with a static array would be that we would have to decide the maximum capacity of a bag at creation. This would be an additional constraint on the ADT definition, and that’s a big drawback.[](/book/grokking-data-structures/chapter-7/)
-  *Dynamic arrays*—With this solution, we don’t have to decide the capacity of the bag in advance. However, the tradeoff is that the insertion becomes `O(n)` in the worst case (although the *amortized* running time to insert `n` elements would still be `O(n)`, as we discussed in chapter 5).[](/book/grokking-data-structures/chapter-7/)[](/book/grokking-data-structures/chapter-7/)
-  *Linked lists*—Since we are allowed to iterate through the elements in reverse order of insertion (and in any order, really), we can use a singly linked list and insert the new elements at the beginning of the list. This way, we can guarantee `O(1)` insertion and `O(n)` traversal, and we have maximum flexibility to grow the list as needed. There will be some extra memory required to store the links, but we will worry about that at the implementation level— asymptotically, both arrays and linked lists require `O(n)` *total* memory to store `n` elements.[](/book/grokking-data-structures/chapter-7/)[](/book/grokking-data-structures/chapter-7/)

#### The Bag class

[](/book/grokking-data-structures/chapter-7/)So, the best option to implement a `Bag` class seems to be using a singly linked list to store the elements—we don’t need a doubly linked list because we won’t be deleting elements, nor will we need to traverse the list from tail to head.[](/book/grokking-data-structures/chapter-7/)[](/book/grokking-data-structures/chapter-7/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/07-13.png)

We can use composition and set the linked list as an attribute of the new class. The `Bag` class is just a wrapper around the linked list with the elements. We need this wrapper because we want the `Bag` class to have only two public methods with which clients can interact:

```
class Bag:
    def __init__(self):
        self._data = SinglyLinkedList()
```

The constructor is minimalistic—it simply initializes an empty bag by creating an empty linked list.

#### Insert

The best advantage of reusing other data structures is that it makes the methods of the `Bag` class clean and short. When adding new elements, as we discussed, we definitely want to insert them at the beginning of the list, not at the end, which would be inefficient for a singly linked list (because, as we discovered in chapter 6, it would require traversal of the entire list to find the last node). What’s great about our implementation is that we only need to forward the new element to the insertion method of the linked list:[](/book/grokking-data-structures/chapter-7/)[](/book/grokking-data-structures/chapter-7/)

```
def insert(self, value):
    self._data.insert_in_front(value)
```

#### Traversal

To allow clients to iterate through the elements of a bag, we could either implement the traverse method or—in languages that allow it—define an iterator. The details of how iterators work in Python are not particularly interesting to us, but you can find an implementation of the iterator for `Bag` in our repo on GitHub: [https://mng.bz/ZEWO](https://mng.bz/ZEWO).[](/book/grokking-data-structures/chapter-7/)[](/book/grokking-data-structures/chapter-7/)[](/book/grokking-data-structures/chapter-7/)

If, instead, you want to define a method `traverse` that returns a Python list with the elements in the bag, here it is:

```
def traverse(self):
    return self._data.traverse()
```

Remember: bags do not guarantee that the elements will be returned in any particular order, so any client code shouldn’t count on that. This means that even in tests, you shouldn’t impose constraints on the order in which the elements are visited. A good approach in tests is to compare the result and the expected result as sets. Check out the tests I created: [https://mng.bz/RZO0](https://mng.bz/RZO0).

For instance, I have implemented the `Bag` class with an underlying linked list, and I iterate through the elements in reverse order of insertion. Even though I know in advance the order in which the elements will be returned by the current implementation, if I tested that particular order, I wouldn’t be able to switch to a different implementation that uses, for example, arrays to store the elements of the bag and reads them in the order of insertion, because the tests would fail. Similarly, if you write any code that relies on the iteration order of this implementation, replacing it with a different implementation will break your code. And if you are using a `Bag` object from a third-party library over which you have no control, you don’t want to find yourself in the position of having to explain to your boss why, all of a sudden, your code was broken when the library owner changed the implementation of a bag without breaking its interface.[](/book/grokking-data-structures/chapter-7/)

## Recap

-  An *abstract data type* (ADT) is a concept that describes at a high level how data can be organized and what operations can be performed on the data. It provides little or no detail about the internal representation of the data.
-  A *data structure* (DS) is a refinement of an ADT definition where we specify how data is organized in memory and the computational complexity of the operations defined by the ADT.
-  An *implementation* is a further refinement of the definition of a DS, dealing with a programming-language-specific constraint and producing as output some code, in a chosen language, that fully implements the DS.[](/book/grokking-data-structures/chapter-7/)
-  A container is a data structure that belongs to a class that shares some common characteristics:[](/book/grokking-data-structures/chapter-7/)

-  Containers are collections[](/book/grokking-data-structures/chapter-7/) of elements.
-  Containers provide the same set of basic operations to insert, delete, access, modify, and search elements within the collection.
-  All containers provide a way to iterate through all their elements.
-  Containers may or may not keep the elements they store in a particular order.
-  Containers are designed to provide efficient access to their elements. The complexity of common operations (that is, insert, delete, search) varies by container type and is specified at the data structure level of design.

-  The bag is the simplest form of container, offering only two methods, one to insert elements and one to iterate through the elements stored in the bag (elements can’t be searched or removed).[](/book/grokking-data-structures/chapter-7/)
-  A bag can be implemented on top of basic data structures such as arrays and linked lists. The singly linked list implementation guarantees the best running time for both operations defined on a bag. More complex data structures could also be used, depending on specific requirements or constraints.[](/book/grokking-data-structures/chapter-7/)
