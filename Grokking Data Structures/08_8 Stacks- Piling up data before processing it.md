# 8 Stacks: Piling up data before processing it

### In this chapter

- introducing the stack abstract data type
- applying the LIFO policy in the real world and in computer science
- implementing a stack with arrays and linked lists
- why do we need stacks

[](/book/grokking-data-structures/chapter-8/)In the previous chapter, you familiarized yourself with *containers*, a class of data structures whose main purpose is to hold a collection of objects, and with the simplest of all containers—the *bag*. Bags are simple data structures that require few resources. They can be useful when we want to hold data on which we only need to compute some statistics, but overall, they aren’t widely used.[](/book/grokking-data-structures/chapter-8/)

Now it’s time to look at containers that are crucial to computer science: we start with the *stack*. You’ll find stacks everywhere in computer science, from the low-level software that makes your applications run to the latest graphics software available.

In this chapter, we learn what a stack is, see how stacks work, and look at some of the kinds of applications that use stacks.

## Stack as an ADT

As I mentioned for bags, I start our discussion of each container at the abstract data type (ADT) level. So, this is when we define what a stack is, how a stack works at a high level, and the interface a stack provides for us to interact with it.[](/book/grokking-data-structures/chapter-8/)[](/book/grokking-data-structures/chapter-8/)

### Stack and LIFO

[](/book/grokking-data-structures/chapter-8/)A stack is a container that allows elements to be added or removed according to precise rules: you can’t just add a new element anywhere like with arrays and lists.[](/book/grokking-data-structures/chapter-8/)[](/book/grokking-data-structures/chapter-8/)

The way a stack works is explained by an acronym—*LIFO*—which stands for *l[](/book/grokking-data-structures/chapter-8/)ast in, first out*. This is a method that is widely used in the real world, outside of computer science. The example used in introductory courses is the proverbial pile of dishes in a restaurant’s kitchen: waiters put dirty dishes on the top of the pile, and the kitchen hand takes them in reverse order from the top to wash them. LIFO is also used in cost accounting and inventory management, among other things.[](/book/grokking-data-structures/chapter-8/)

![LIFO in stock management](https://drek4537l1klr.cloudfront.net/larocca3/Figures/08-01.png)

In the context of containers, the LIFO principle requires a data structure in which elements can be inserted and then consumed (or removed) in the reverse order in which they were inserted.

### Operations on a stack

To make the stack adhere to the LIFO paradigm, we design its interface with only two methods:[](/book/grokking-data-structures/chapter-8/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/08-02.png)

-  *A method to insert an element into the stack*—For stacks, we traditionally call this method `push()` instead of just “insert.”[](/book/grokking-data-structures/chapter-8/)
-  *A method to remove the most recently added element from the stack and return it—*This method is traditionally called `pop()` or sometimes `top()`.[](/book/grokking-data-structures/chapter-8/)[](/book/grokking-data-structures/chapter-8/)

Given the LIFO order constraint, a stack must maintain the order in which elements are inserted. The ADT definition imposes no constraints on how this order must be maintained or how elements must be stored, so, for the sake of an example, we can think of our stack as a pile of elements, not unlike a pile of dishes.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/08-03.png)

We also need to keep track of the last element that was added to the stack, which (following the pile analogy) is called the *top of the stack*. In practice, what we need to do is to somehow keep a sequence of the elements in the order of insertion, and the top of the stack will be the side of the sequence where we add and remove elements (regardless of how the sequence is stored).[](/book/grokking-data-structures/chapter-8/)

### Stacks in action

Carlo runs a small, young startup that ships local gourmet food from Naples to expats around the world. They only ship packages of the same size and weight (20 kilograms), but the customers can partly personalize their order.[](/book/grokking-data-structures/chapter-8/)[](/book/grokking-data-structures/chapter-8/)

Carlo’s company is still small, so they have a small space to store the packages ready to be shipped. Carlo bought a tall silo, and the parcels can be only stacked in two columns, leaving just enough room for a forklift to operate. The forklift is also small; it can only lift one parcel at a time. So, from these piles, only the parcel on top can be picked up with the forklift.

Does that ring a bell? Yes, each pile of packages is a stack!

Carlo decides to divide the parcels into two groups. In one pile, he keeps all the standard packages: they are all the same, they have an expiration date far in the future, and once they are prepared, any one of them is equally good to fill a new order. The other pile is used to store custom orders while they sit waiting for the courier to pick them up and ship them.

The “standard” pile works just like a stack—it’s not ideal because the desired behavior would be to ship the parcel that was prepared first each time (something we will deal with in the next chapter), but, unfortunately for Carlo, this is the way piling stuff up works.

More interesting is the “custom” pile. This pile also works like a stack, but the problem is that we need to grab specific elements—an operation that stacks’ interfaces do not support.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/08-04.png)

Fear not, there is a way to make this work, which is using a second temporary stack. Let’s say we have six custom packages stacked up in Carlo’s deposit and, for some reason, he needs to take out the third parcel.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/08-05.png)

What he can do is first grab the package on top, the one marked “6.” Then he puts it down next to the unloading area and picks up the next package, labeled “5,” and so on. In this way, he builds a temporary stack in the unloading area with the elements above the parcel he needs to ship, the one labeled “3.”

Finally, when the target parcel 3 is moved to the courier’s truck, Carlo must put the packages in the temporary pile back in their place: again, starting with the one on top, the one marked “4,” and so on, until all three parcels are back into the custom pile.

In computer science terms, this is an example of an application that uses two stacks to provide the functionality of an array. If your gut instinct tells you that this must be terribly inefficient, you are right: it requires twice as much memory (two stacks of the same size, one of which is kept empty), and removing/returning a generic element in a stack of size `n` takes `O(n)` steps.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/08-06.png)

But sometimes you might have no choice: when life gives you stacks…

## Stack as a data structure

[](/book/grokking-data-structures/chapter-8/)After finalizing the abstract data type for stacks and writing its interface in stone, we need to start thinking about how to implement it.[](/book/grokking-data-structures/chapter-8/)[](/book/grokking-data-structures/chapter-8/)

##### Tip

Remember that an ADT interface is the only part that should be written in stone. Any change to that interface, or to the intended behavior specified in the ADT phase, will make all data structures built on top of an ADT incompatible.

We discussed this in chapter 7: it is possible to have several alternative DS definitions for a single ADT. At the data structure level, we focus on the details of how the data is stored in a stack, and on the resources required by the operations (which, in turn, are usually determined by the choice of the underlying data structures).

As for bags, we can consider three main alternatives for storing a stack’s data:

-  A static array
-  A dynamic array
-  A linked list

Let’s take a closer look at each.

### Static array for storing a stack’s data

If we use a static array to store the elements of a stack, we can push new elements to the end of the array and pop elements from the end of the array. Therefore, a static array guarantees us very good performance for these two operations: they would both require `O(1)` time and no additional memory.[](/book/grokking-data-structures/chapter-8/)[](/book/grokking-data-structures/chapter-8/)[](/book/grokking-data-structures/chapter-8/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/08-07.png)

The big concern with static arrays is that their size is fixed. A stack relying on static arrays to store its data would require its maximum capacity to be set when the stack is created, and it wouldn’t be possible to resize it. While this is acceptable in some contexts, generally speaking, we don’t want this limitation.

### Dynamic array

With a dynamic array, the way we push and pop elements wouldn’t change—it’s still at the end of the array. We would, however, solve the problem of capacity: we could push on the stack as many elements as we wanted—at least until we had enough RAM to allocate a larger array.[](/book/grokking-data-structures/chapter-8/)[](/book/grokking-data-structures/chapter-8/)

The fact that a dynamic array doubles in size when we add a new element to a full array can cause some problems. First, when we grow a dynamic array, we must allocate much more memory than we need—an average of `O(n)` extra memory. And it gets worse. If the array is implemented as a contiguous area of memory, as the stack’s size grows, it becomes increasingly difficult to find an available chunk of memory large enough to allocate the size of the new underlying array. Furthermore, if the array can’t be allocated, we get a runtime error, and our application crashes. Thus, if we expect the stack to grow large, with thousands of elements or more, dynamic arrays might not be the best choice.

![Operations on a stack implemented with a dynamic array. When push(1) is called, there is no unused array cell, so the array doubles its size.](https://drek4537l1klr.cloudfront.net/larocca3/Figures/08-08.png)

Even for smaller stacks, however, we pay a price, compared to static arrays: `push` and `pop` becoming `O(n)` in the worst case for a stack of `n` elements. If you remember our discussion about dynamic arrays in chapter 5, there is a silver lining. Pushing `n` elements into an empty stack takes `O(n)` amortized time; similarly, emptying a stack with `n` elements takes `O(n)` amortized time. Both operations require constant additional memory.

### Linked lists and stacks

[](/book/grokking-data-structures/chapter-8/)As always, the linked list implementation is the most flexible. For stacks, we only need to make changes to one side of the list, and we can choose to work at the beginning of the list—storing elements in inverse order of insertion is no problem at all as there is no need to iterate through them.[](/book/grokking-data-structures/chapter-8/)[](/book/grokking-data-structures/chapter-8/)

Can you guess why these considerations are important? It’s because it means we can use singly linked lists (SLLs). We don’t need to traverse the list at all, and inserting and deleting from the front of the list are both `O(1)` for SLLs, so there is no reason to use doubly linked lists.

The best part? Linked lists, as we know at this point in the book, are inherently flexible, allowing the stack to grow and shrink as needed at no additional cost. In addition, linked lists have fewer constraints on the allocation of the memory they require: a new node can be allocated anywhere (not necessarily next to or near the rest of the nodes). This makes it easier to allocate larger stacks compared to the array implementations.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/08-09.png)

Is all that glitters gold? Well, not always, as you should know. There is the extra memory per element required by linked lists to store the links to the next node. And in the next section, we will look more closely at possible downsides.

But long story short, the implementation with linked lists is your best choice if you need flexibility, and, in theory, it also provides the most efficient implementation of operations on a stack—at least, if the additional memory needed for the node pointers is not a problem. But if you know the size of the stack in advance, the implementation with static arrays can be a better alternative.

## Linked list implementation

[](/book/grokking-data-structures/chapter-8/)The analysis at the data structure level suggests that an implementation with an underlying linked list is the alternative that guarantees us the best performance and use of resources for all the stack operations. So, while we’ll briefly discuss the dynamic arrays variant later in the section, for now, we will just focus on linked lists, starting with the class definition. You’ll notice many similarities with the `Bag` class we talked about in chapter 7—as with bags, the `Stack` class is merely a wrapper that restricts the interface of a linked list, allowing only a subset of its methods:[](/book/grokking-data-structures/chapter-8/)[](/book/grokking-data-structures/chapter-8/)[](/book/grokking-data-structures/chapter-8/)

```
123class Stack:
    def __init__(self):
        self._data = SinglyLinkedList()
```

And as for bags, the constructor just creates an empty linked list. You can find the full code for stacks in the book’s repo on GitHub: [https://mng.bz/d6lO](https://mng.bz/d6lO).

Technically, in addition to the three options I gave you at the data structure level, there is a fourth alternative: we could implement a stack from scratch, handling the way data is stored without reusing any underlying data structure. But why would we do that? We would gain nothing, and, in exchange, we would have a lot of duplicated code because we would have to implement the details of all the operations.

In the rest of this section, we discuss the operations in the stack’s API, `push` and `pop`, and a third method, `peek`, a read-only operation that is sometimes provided outside of the standard API.[](/book/grokking-data-structures/chapter-8/)[](/book/grokking-data-structures/chapter-8/)[](/book/grokking-data-structures/chapter-8/)

### Push

[](/book/grokking-data-structures/chapter-8/)Instead of implementing everything from scratch, if we use a linked list to store the stack’s data, we can reuse the existing `insert_in_front` method from linked lists when pushing a new element onto the stack. Assuming that it is already properly tested and consolidated, we can write the `push` method as a one-liner:[](/book/grokking-data-structures/chapter-8/)[](/book/grokking-data-structures/chapter-8/)[](/book/grokking-data-structures/chapter-8/)

```
12def push(self, value):
    self._data.insert_in_front(value)
```

The underlying linked list takes care of all the details; we just have to forward the call to the linked list.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/08-10.png)

Depending on the context, we can use the `push` wrapper to perform some checks before actually inserting an element into the list. For example, if there are restrictions on the valid values, we could perform validation at this point: for a stack containing strings, we could check that the value pushed is not the empty string.[](/book/grokking-data-structures/chapter-8/)

### Pop

Similar to `push`, the `pop` method relies heavily on the linked list interface. In its simplest form, we could also have a one-liner that simply calls `delete_from_front` on the underlying list.[](/book/grokking-data-structures/chapter-8/)[](/book/grokking-data-structures/chapter-8/)[](/book/grokking-data-structures/chapter-8/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/08-11.png)

However[](/book/grokking-data-structures/chapter-8/), if we try to delete from an empty list, an exception will be raised (see chapter 6 for details). This is the expected behavior, but the place where the exception is triggered, and the error message, could be confusing to anyone using a stack, and it would reveal unnecessary internal details to the caller. So, what I believe is best here is to explicitly check the error condition in the stack’s method and raise an exception there if the stack is empty. The price to pay for this clarity is, of course, that in the happy case (where no error is triggered), the check is performed twice, once by the stack and once by the linked list:

```
def pop(self):
    if self.is_empty():
        raise ValueError("Cannot pop from an empty stack")
    return self._data.delete_from_front()
```

Alternatively, we can catch the exception raised by the linked list method and raise a different exception.

### Peek

The `peek` method should be the easiest one to implement, right? After all, we just need to return the element at the top of the stack without making any structural changes to the stack. And instead, even such a simple method hides some pitfalls! There are some considerations we need to make, and some aspects we need to discuss, to prevent possible future bugs.[](/book/grokking-data-structures/chapter-8/)[](/book/grokking-data-structures/chapter-8/)

The simplest version of this method could also be a one-liner and simply return the data stored at the head of the list (something like this):

```
return self._data._head.data()
```

There are three problems with this approach:

-  We don’t check if the list is empty before accessing its head.
-  It is accessing the private attribute `_head` of the linked list.[](/book/grokking-data-structures/chapter-8/)
-  We would return a reference to the element stored in the head node. If the elements of the list are mutable objects, then whoever gets the reference can change the object at any time.

The first problem can be easily solved the same way we did with `pop()`—we should just check for the edge case before attempting anything. And for the last one, we can use an existing Python library ([https://docs.python.org/3/library/copy.html](https://docs.python.org/3/library/copy.html)) to copy the data instead of passing a reference:

```
import copy
def peek(self):
    if self.is_empty():
        raise ValueError("Cannot peek at an empty stack")
    return copy.deepcopy(self._data._head.data())
```

This is better, but it still accesses a private attribute of the linked list. The only decent solution would be to add a method to the linked list class that returns the element stored in a generic position in the list.

Exercises

8.1 Implement a `get(i)` method for linked lists that returns the `i`-th element from the head of the list (`i≥0`). Then, modify the implementation of `peek` to avoid accessing the `_head` private attribute of the linked list.[](/book/grokking-data-structures/chapter-8/)[](/book/grokking-data-structures/chapter-8/)[](/book/grokking-data-structures/chapter-8/)

8.2 After implementing `get(i)`, do we still need to call `deepcopy` in `peek`? Check your implementation of `get` and make sure we don’t.[](/book/grokking-data-structures/chapter-8/)

8.3 Implement a separate `Stack` class that uses dynamic arrays to store the stack elements. How does this new implementation compare to the one that uses linked lists?[](/book/grokking-data-structures/chapter-8/)

## Theory vs. the real world

In the previous section, when we discussed how to move from the ADT definition of a stack to a more concrete definition of a data structure, I showed you that the implementation of a stack using an underlying linked list is the most efficient. To recap, using an SLL, both `push` and `pop` operations can be performed in worst-case constant time, while when using a dynamic array, both methods take linear time in the worst case, but if a large number of operations is performed, their amortized cost can be considered `O(1)`.[](/book/grokking-data-structures/chapter-8/)[](/book/grokking-data-structures/chapter-8/)[](/book/grokking-data-structures/chapter-8/)

Is that it? Should we just implement the linked list version and forget about it?

Well, not really. First, you shouldn’t implement your own library unless it’s absolutely necessary—either because you can’t find an existing implementation that is trustworthy, efficient, and well-tested or because you have to customize your implementation heavily.

Second, if the code where you need to use this library is critical for your application and can become a bottleneck, you should *profile* it. [](/book/grokking-data-structures/chapter-8/)[](/book/grokking-data-structures/chapter-8/)

##### TIP

You shouldn’t profile all your code though. Unless you are writing code for a real-time device, that would be time-consuming and mostly useless. The secret is to focus on the critical sections where optimization will improve efficiency the most.

Profiling your code means measuring your application as it runs to see which methods are executed more often and which ones take longer.

In Python, we can do this using *cProfile* [https://docs.python.org/3/library/profile.html](https://docs.python.org/3/library/profile.html). So, I implemented a version of the stack, called `StackArray`, that uses a Python `list` to store its elements: [https://mng.bz/Bdj8](https://mng.bz/Bdj8).[](/book/grokking-data-structures/chapter-8/)[](/book/grokking-data-structures/chapter-8/)

Why `list`? First, our version of dynamic arrays has constraints on the type of its elements that would make it incompatible with the linked lists version defined in this section. Second, well, I don’t want to spoil it, but it has to do with performance. We’ll talk about that in a minute.

So, I wrote a quick script ([https://mng.bz/lMB8](https://mng.bz/lMB8)) that runs millions of operations on both types of stacks (let’s call the two classes `Stack` and `StackArray`), with twice as many calls to `push` as to `pop`. The same operations, in the same order, are performed on both versions of the stack, and then we measure how long each version took.[](/book/grokking-data-structures/chapter-8/)[](/book/grokking-data-structures/chapter-8/)

What do you expect as a result? How much would you bet on the linked list version being faster? Well, you might be in for a surprise:

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/08-12.png)

We need to look at the column with the cumulative time, that is, the time spent within a function or any of its sub-calls (this is especially important since we call the linked list methods within all methods in `Stack`).

When implemented with dynamic arrays—as a Python `list`—`push` is more than four times faster, and `pop` is more than three times faster.

How is this possible? Does that mean we should throw away asymptotic analysis? Of course not. There are a few considerations to make:

-  With an implementation based on dynamic arrays, while the worst-case running time for `push` and `pop` is linear, their amortized running time is as good as with linked lists: `n` operations (`push` or `pop`) take `O(n)` time. We have discussed this in chapter 5 for dynamic arrays. Since we are measuring the performance of these methods over a large number of operations, there is no asymptotic advantage to using linked lists.[](/book/grokking-data-structures/chapter-8/)[](/book/grokking-data-structures/chapter-8/)
-  Python provides an optimized, extremely efficient implementation for `list`. This code is usually written in C and compiled for use in Python to make sure it’s as efficient as possible ([https://docs.python.org/3/extending/extending.html](https://docs.python.org/3/extending/extending.html)). It’s hard to write pure Python code that can be nearly as efficient. So, each call to push on an instance of `StackArray` takes a fraction of what it takes on an instance of `Stack`.[](/book/grokking-data-structures/chapter-8/)
-  With linked lists, we must allocate a new node on each call to `push` and then destroy a `Node` object on each `pop`. Allocating the memory and creating the objects takes time.[](/book/grokking-data-structures/chapter-8/)[](/book/grokking-data-structures/chapter-8/)[](/book/grokking-data-structures/chapter-8/)[](/book/grokking-data-structures/chapter-8/)

To confirm the third hypothesis, we can look at the stats for the methods in `SinglyLinkedList`:

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/08-13.png)

Most of the time taken by `Stack.push` was spent running `SinglyLinkedList.insert_in_front`, and the same is true for `Stack.pop` and `SinglyLinkedList.delete_from_front`.[](/book/grokking-data-structures/chapter-8/)[](/book/grokking-data-structures/chapter-8/)[](/book/grokking-data-structures/chapter-8/)[](/book/grokking-data-structures/chapter-8/)

The last line is also interesting—half of the time taken by `insert_in_front` is spent creating a new `Node` instance.[](/book/grokking-data-structures/chapter-8/)[](/book/grokking-data-structures/chapter-8/)

So, what lessons can we learn from this analysis?

##### Tip

When designing a data structure, choose the implementations that have the best big-O performance. If two solutions have close performance in the asymptotic analysis, consider using profiling to compare the efficiency of their implementations.

That’s a good starting point, but, unfortunately, not always enough. There are cases of data structures that are better on paper (their big-O running time is better than the alternatives), but whose implementation turns out to be slower in practice, at least for finite inputs.

One notorious example is Fibonacci heaps, an advanced priority queue that has the best theoretical efficiency. We talk about heaps in chapter 10, but the important point here is that Fibonacci heaps are asymptotically better than regular ones (`O(1)` amortized time for insertion and extraction of the minimum value, while both are `O(log(n))` for regular heaps), but their implementation is much slower for any practical input.[](/book/grokking-data-structures/chapter-8/)

As you gain experience, you will find it easier to identify these edge cases. However, when in doubt, profiling can help you figure out where and how to improve your data structure or application.

## More applications of a stack

We have discussed some real-world situations that work like LIFO, but stacks are broadly used in computer science and programming. Let’s look briefly at a few applications!

### The call stack

[](/book/grokking-data-structures/chapter-8/)A *call stack* is a special kind of stack that stores information about the active functions (or, more in general, subroutines) of a computer program that is being executed. To better illustrate this idea, let’s see what a call stack for the `Stack.push` method might look like:[](/book/grokking-data-structures/chapter-8/)[](/book/grokking-data-structures/chapter-8/)[](/book/grokking-data-structures/chapter-8/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/08-14.png)

As we discussed in the implementation section, the `push` method calls `SinglyLinkedList.insert_in_front`, which in turn calls the constructor for the `SinglyLinkedList.Node` class: [](/book/grokking-data-structures/chapter-8/)[](/book/grokking-data-structures/chapter-8/)[](/book/grokking-data-structures/chapter-8/)

```
push(3)
... [Stack.push]
    self._data.insert_in_front(3)
    ... [SinglyLinkedList.insert_in_front]
        self._head = Node(3, old_head)
        ... [Node.__init__]
            self._data = 3
```

Execution needs to pass along the element we are pushing to our `Stack` between each call. In code, we do this by using function arguments. At a lower level, function arguments are passed through the call stack: when we call `push`, a stack frame is created for this function call, and an area is allocated for `push` arguments. [](/book/grokking-data-structures/chapter-8/)

The same happens with `insert_in_front`, where the value for the `data` argument is stored (usually at the beginning of the stack frame). There is a similar mechanism for return values, with an area of memory reserved in the stack frame for the values that will be returned to the caller. If the caller saves the return value in a local variable, that’s also stored in its stack frame. Finally, each stack frame contains the *return address*: it’s the address where the instruction making the function call is stored in memory, and it is used to resume the execution of the calling function when the callee returns.[](/book/grokking-data-structures/chapter-8/)[](/book/grokking-data-structures/chapter-8/)[](/book/grokking-data-structures/chapter-8/)

Stack frames are stacked on top of each other, and the execution rolls back just like a stack: the last function called is the first to return, its stack frame is popped from the call stack (and the return address with it), which allows the execution of the caller to resume, and so on.

### Evaluating expressions

*Postfix notation* is a way of writing arithmetic expressions so that the operator always follows the operands. For example, what is written as `3 + 2` in *infix* *notation*, becomes `3 2 +` in postfix notation. One of the advantages of this notation is that it removes the ambiguities that you have in infix notation.[](/book/grokking-data-structures/chapter-8/)[](/book/grokking-data-structures/chapter-8/)[](/book/grokking-data-structures/chapter-8/)

For example, to compute an expression like `3 + 2 * 4`, we need to use the concept of operator priority and agree that multiplication takes precedence over addition so that we actually interpret it as `3 + (2 * 4)`. If we wanted to do the sum first, we would have to use parentheses and write `(3 + 2) * 4`. In postfix notation, we don’t need parentheses—we can write the two possible combinations as `3 2 4 * +` and `3 2 + 4 *`, respectively.

The other advantage we have is that we can easily compute the value of a postfix expression by using a stack: when we parse an operand (that is, a value) we push it on the stack, and when instead we parse an operator, we pop the last two values from the stack (for a binary operator), apply the operator, and then push the result on the stack.[](/book/grokking-data-structures/chapter-8/)

Let’s look at an example. This is how the parsing of the expression `3 2 4 * +` would look like:

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/08-15.png)

And this is how `3 2 + 4 *` is parsed instead:

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/08-16.png)

### Undo/redo

[](/book/grokking-data-structures/chapter-8/)Have you ever wondered how the *undo* functionality of your IDE or text editor works? It uses a stack (two stacks actually, if you are allowed to revert what you have undone).[](/book/grokking-data-structures/chapter-8/)[](/book/grokking-data-structures/chapter-8/)

The first stack is used to keep track of the changes you make to your documents. This stack is usually limited in size, so older entries will be deleted, and you can only undo a limited number of changes.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/08-17.png)

When you click undo, the document is restored to the state it was before the last action you performed. But that’s not all: the change you have undone gets added to a new stack, the redo stack, so that if you accidentally click undo, or if you change your mind before making any new modification to the document, you can revert it.[](/book/grokking-data-structures/chapter-8/)

### Retracing your steps

Stacks are great when you need to retrace your steps. Remember back in chapter 6 we talked about retracing your steps? We were helping our friend Tim, who was working on a video game and needed to keep a list of the rooms in the game, and how the main character could move between them, from left to right and vice versa.[](/book/grokking-data-structures/chapter-8/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/08-18.png)

[](/book/grokking-data-structures/chapter-8/)The doubly linked list was perfect for keeping track of the static situation—of the structure of the game. But what if now Tim needs to remember the path that the player has taken from the beginning of the game up to where they are now and allow the character to retrace their steps? Well, you must have guessed it: Tim needs to use a stack![](/book/grokking-data-structures/chapter-8/)

When the player enters a room, that room is added to a stack. When we need to trace the player’s steps, we start to pop rooms from the stack. Note how the same room can be in the stack multiple times if the player re-entered a room after leaving it.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/08-19.png)

This scenario is an edge case, where our rooms are arranged linearly. In the more general case, we might want to move around a 2D or 3D environment. In the rooms/videogame analogy, we would have more than two doors in some rooms. This kind of environment can’t be modeled with a list—we will need a *graph*.

In chapter 13, we discuss graphs, how they can be used to model a city map, and how the *depth-first search* algorithm uses a stack to navigate through the graph.

Exercise

8.4 Write a method that reverses an SLL. Hint: How can you use a stack to perform the task? What would be the running time of the operation?

## Recap

-  A *stack* is a container that abides by the LIFO policy: that is, the *last* element *in* the stack is the *first* element to get *out*. You can picture a stack as a pile of dishes: you can only add or remove dishes at the top.[](/book/grokking-data-structures/chapter-8/)[](/book/grokking-data-structures/chapter-8/)
-  Stacks are widely used in computer science and programming, including call stacks, expressions evaluation, the undo/redo functionality, and keeping track of indentation and bracketing in editors. In addition, many algorithms use stacks to keep track of the path taken, such as depth-first search.
-  Stacks provide two operations: `push`, to add an element to the top of the stack, and `pop`, to remove and return the element from the top of the stack. There is no other way to insert or delete elements, and search is generally not allowed.[](/book/grokking-data-structures/chapter-8/)[](/book/grokking-data-structures/chapter-8/)
-  A third operation can sometimes be provided: `peek`, which returns the element at the top of the stack without removing it.[](/book/grokking-data-structures/chapter-8/)
-  A stack can be implemented using either arrays or linked lists to store its elements.
-  Using dynamic arrays, `push` and `pop` take `O(n)` time in the worst case, but `O(1)` amortized time (over a large number of operations).[](/book/grokking-data-structures/chapter-8/)
-  Using SLLs, `push` and `pop` take `O(1)` time in the worst case.[](/book/grokking-data-structures/chapter-8/)
-  The amortized performance of the two implementations is close, and profiling can help you understand which of the two implementations is more efficient in a given programming language.
