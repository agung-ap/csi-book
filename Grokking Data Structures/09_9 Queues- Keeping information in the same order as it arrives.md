# 9 Queues: Keeping information in the same order as it arrives

### In this chapter

- introducing the queue abstract data type
- understanding FIFO policy
- implementing a queue with arrays and linked lists
- exploring the applications of simple queues

[](/book/grokking-data-structures/chapter-9/)The containers we discuss next are queues, sometimes referred to as simple queues to distinguish them from priority queues, which we describe in chapter 10.

Like stacks, queues are inspired by our everyday experience and are widely used in computer science. They also work similarly to stacks, with a similar underlying mechanism, and they can also be implemented using arrays or linked lists to hold the data. The difference is in details that we will learn about in this chapter.[](/book/grokking-data-structures/chapter-9/)

## Queue as an abstract data type[](/book/grokking-data-structures/chapter-9/)

A queue is a container that, similarly to a stack, only allows the insertion and removal of elements in specific positions. What operations are available on a queue? What determines the internal state of a queue, and how does it behave?[](/book/grokking-data-structures/chapter-9/)

Let’s first understand how queues work, and then, later in this section, define their interface.

### First in, first out

[](/book/grokking-data-structures/chapter-9/)While stacks use the *LIFO* (*last in, first out*) policy, queues[](/book/grokking-data-structures/chapter-9/) abide by a symmetric principle, called *FIFO*, which stands for *first in, first out*. FIFO means that when we consume an element from a queue, the element will always be the one that has been stored the longest, and it is the only one we can remove.[](/book/grokking-data-structures/chapter-9/)[](/book/grokking-data-structures/chapter-9/)

Queues are ubiquitous—the name is self-explanatory (queue being another word for line—and we’ve all been in a line at some point). FIFO, however, is also a policy that’s used with stocked goods, where we remove the oldest units that are likely to have the closest expiration date. The same principle is applied when tackling bugs and tasks from our virtual team board (unless our tasks have priority, in which case, you need to read the next chapter!).

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/09-01.png)

When we apply the FIFO policy to containers, it means creating a data structure in which elements can be inserted and then processed in the same order in which they were inserted.

### Operations on a queue

For queues, there are constraints on where you can add and delete elements. There’s only one place where a new element is allowed to go: at the *rear* (or tail) of the queue. And elements can only be consumed from the other end of the queue, called the *front* (or head) of the queue.[](/book/grokking-data-structures/chapter-9/)[](/book/grokking-data-structures/chapter-9/)[](/book/grokking-data-structures/chapter-9/)[](/book/grokking-data-structures/chapter-9/)

Therefore, in our interface, we only include the following two methods:

-  *A method to insert an element into the queue*—For queues, we traditionally call this method `enqueue()`.[](/book/grokking-data-structures/chapter-9/)
-  *A method to remove the least recently added element from the queue and return it*—This method is traditionally called `dequeue()`.[](/book/grokking-data-structures/chapter-9/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/09-02.png)

How does a queue work, internally? At the abstract data type (ADT) level, we put no constraint on the internal structure of a queue, but we just define its behavior. Obviously, since we need to consume elements in the same order as they are inserted, we need to save this ordering in the internal state of a queue—but how we do that exactly is something that will be defined only at the data structure level.[](/book/grokking-data-structures/chapter-9/)

At the ADT level, we can imagine a queue in whatever abstract way we find appropriate. Even as the line at the ice cream cart!

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/09-03.png)

When people queue to get an ice cream cone or to check out, they often stand (or are supposed to stand) in a straight line. When someone joins the queue, they walk to its rear and then stand right behind the last person in line. When the person at the front of the queue gets their ice cream, they walk away, and the person who was standing right behind them takes their place. The positioning, the standing in line, is the structure that keeps the memory of the order of insertion of people in the queue.

We can also use a more computer-science-like example, with boxes and numbers. Compare this to how stacks work, as we showed in chapter 8!

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/09-04.png)

There are at least two notable differences:

-  For stacks, we are only interested in holding a reference to their top. For a queue, we need references to both its front and its rear.
-  A stack grows and shrinks from the same end, while a queue evolves asymmetrically, with elements added to its rear and removed from its front.

### Queues in action

[](/book/grokking-data-structures/chapter-9/)What could be better than picking up a bug from the backlog to start your morning? “Anything,” thinks Priyanka as she scrolls through her backlog. (If you have been there, feel free to raise your hand in support!)[](/book/grokking-data-structures/chapter-9/)

Priyanka just started working at a startup that looked so cool from the outside. Their mission resonates with her, and the AI technology the founders developed is fascinating. But what she didn’t know was that, besides their core technology, she would find an infrastructural and organizational wasteland. What she didn’t realize was that they didn’t even have proper task management tools and that their bug backlog would be a bunch of sticky notes left on her desk, screen, and the mini-kitchen table.

So, “scrolling through” her backlog means collecting these sticky notes, hunting them down all over the office, and then trying to interpret the handwriting or finding out who wrote them. In this situation, it’s easier to miss and forget a bug than to fix it. After a week of missed fixes and red alerts, Priyanka had enough.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/09-05.png)

She asked for a problem-tracking product off the shelf, but apparently, there was no budget for it. So, she decided to write one—a simple one of course—as her weekend project.

She tweaked the company’s mail server and created a dedicated email address so that when a bug needed to be added to the system, anyone could just send an email. When the email comes in, there is a daemon that picks it up and adds the bug to a queue that’s for her to review.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/09-06.png)

[](/book/grokking-data-structures/chapter-9/)Choosing a queue[](/book/grokking-data-structures/chapter-9/) to manage bugs was crucial for her—each morning she checks the queue, and the system gives her the oldest unresolved bug. If she starts working on that bug, it’s all good. If, however, she doesn’t think the bug is urgent, she can send it back to the queue, and it will be added to the rear of the queue.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/09-07.png)

Using a queue for bug tracking ensures she remains organized without misplacing bug reports. Also, the queue implicitly keeps the bugs in chronological order, without having to store a timestamp with them.

This is just one example of how a queue can be part of a real software application, but there could be many more ways to use it. In addition, several algorithms use queues as a fundamental part of their workflow. In chapter 13, we will discuss two graph traversal algorithms: *depth-first search* and *breadth-first search*. They are similar in structure, but to decide which vertex to traverse next, one of them uses a stack, and the other algorithm uses a queue. It’s amazing how such a detail can make such a difference in the algorithm’s behavior.

## Queue as a data structure

Now that we have clarified what interface is needed for a queue, we can take the next step and think about how to implement this data structure. We always have the option of writing a new data structure from scratch, without reusing anything we have already created. This option, however, is only worth considering if none of the alternatives on top of which we can build our new data structure works well. So, the first thing we should always do is check whether we can reuse something and weigh what the benefits and costs are.[](/book/grokking-data-structures/chapter-9/)[](/book/grokking-data-structures/chapter-9/)[](/book/grokking-data-structures/chapter-9/)

Right now, considering what we have discussed in previous chapters, we have the following alternatives:

-  Static array
-  Dynamic array
-  Linked list
-  Stack

Let’s start from the end—implementing a queue using stacks is possible, but it’s just not efficient. Instead of adding elements to the top of the stack by implementing the LIFO policy, we’d need to add to the bottom of the stack. But that’s not easy to do with a stack! So, let’s cross stacks off our list.

Next, we can also cross off dynamic arrays. While it is possible to implement a queue using dynamic arrays, and there are some advantages to doing so, the complexity and performance cost of a dynamic array implementation is simply not worth it. We’ll come back to this topic after we talk about static arrays, and then you’ll understand better why we are ruling out dynamic arrays.

This leaves us with two options: linked lists and static arrays. In the rest of this section, let’s discuss these two alternatives in detail.

### Building on a linked list

A queue is a data structure where the elements are kept in the same order as they are inserted, and all the operations (that is, inserting or deleting elements) happen at either end of the queue. Ring a bell? We add elements to the front (head) of the queue and remove elements from the rear (tail) of the queue. Yes, we have discussed these operations for linked lists.[](/book/grokking-data-structures/chapter-9/)[](/book/grokking-data-structures/chapter-9/)[](/book/grokking-data-structures/chapter-9/)

Can you remember which type of linked list was optimized for removing elements from its tail? Doubly linked lists are perfect for this because we can efficiently add and remove elements to and from both ends.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/09-08.png)

However, if we add new elements only to the tail of the linked list and remove them from the front of the list, we can also use a singly linked list. The only caveat is that we need to slightly adjust our code to keep a pointer to the tail of the list, which can be updated in constant time during these two operations.

Anyway, with doubly linked lists, we can reuse the existing code without any change, which brings us to a cleaner solution: unless we know we have to optimize the memory used, we are going to be fine.

[](/book/grokking-data-structures/chapter-9/)We can have fast implementations of the `enqueue` and `dequeue` methods with almost no effort. We will just reuse the `insert_to_back` and `delete_from_front` methods defined for the linked list.[](/book/grokking-data-structures/chapter-9/)[](/book/grokking-data-structures/chapter-9/)[](/book/grokking-data-structures/chapter-9/)[](/book/grokking-data-structures/chapter-9/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/09-09.png)

And the best part is that our queue can grow and shrink dynamically without limits or worries. We can rely on the linked list to take care of memory management and resizing.

### Storing data in a static array

If we decide to implement a queue using a static array, we have to take into account that the queue size remains fixed upon creation. This is a severe limitation compared to the linked list implementation.[](/book/grokking-data-structures/chapter-9/)[](/book/grokking-data-structures/chapter-9/)[](/book/grokking-data-structures/chapter-9/)

At the data structure level, since we are not going to access elements in the middle of the queue, we are not going to use the best feature that arrays have over linked lists—constant-time access to every element in the array.

There is also another problem. With an array implementation, we keep the front of the queue on the same side as the beginning of the array, while the rear of the queue is on the side of the end of the array. The queue grows toward larger indexes, and we fill the unused array cells after the last element in the array.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/09-10.png)

With a stack, the elements stored in the array are naturally kept left justified. If a stack stores `n` elements, they occupy the indexes from `0` to `n-1`. But with a queue, when we dequeue an element, we leave a hole between the beginning of the array and the first remaining element. As long as we have enough unused elements after the used ones, we are fine. But what happens when the rear of the queue reaches the end of the array?[](/book/grokking-data-structures/chapter-9/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/09-11.png)

We have two choices. The easiest way is to give up and say that a queue is full when its rear reaches the end of the array. This is called a *linear queue*. But this also means that the capacity of the queue will decrease over time, and we can only perform `n` insertions on a queue allocated for `n` elements. Then, after we start dequeuing elements, the actual capacity of the queue gets increasingly smaller. This is not very practical, as you may have guessed.[](/book/grokking-data-structures/chapter-9/)

There is an alternative! We can reuse the space that was freed when elements were dequeued. But how do we do that? Again, we have two options:

-  We can move all elements in the queue toward the start of the array so that no empty space is left at the beginning of the array. This means an `O(n)` overhead every time we move elements, which is far from ideal and unnecessarily inefficient.
-  We can get a bit creative with the indexes and use the full array without ever moving an element.

This last option, which is called a *circular queue*, is very interesting. It means no overhead, and it seems too good to be true![](/book/grokking-data-structures/chapter-9/)

But I guarantee you that it is true. Here is what we do: imagine the elements of our array arranged in a circle instead of a straight line, so that the end of the array touches its beginning. This is where the name, circular queue, comes from.

In our example in the figure, we have an array with eight elements, so its indexes go from 0 to 7. What we need to do now is continue indexing as if we could continue after the end of the array. In the circular arrangement, the next element after the one at index 7 is the element at the start of the array, found at index 0. We can write 8 as a secondary index above index 0. Similarly, we write index 9 above index 1, and so on, up to index 15, which is the same element indexed with 7. Let’s call these indexes from 8 to 15 *virtual indexes*.[](/book/grokking-data-structures/chapter-9/)[](/book/grokking-data-structures/chapter-9/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/09-12.png)

That covers most of the concepts we needed. There is just this tiny piece of math we need to clarify, which is using modular arithmetic. The modulo operator, for positive integers, takes the remainder of the division. For example, `8 % 8` (that is 8 modulo 8, the remainder of 8 when divided by 8) is zero, because that’s the remainder of the division operation. Similarly, `9 % 8 == 1`, `10 % 8 == 2,` and so on. The modulo operator is the way to find out which array index corresponds to a virtual index.[](/book/grokking-data-structures/chapter-9/)

In our example, the rear of the queue has reached index 7, so the next array cell to which we should store a new element is at virtual index 8. Now, if we tried to access index 8 in the array, we would cause an index out-of-boundary error. However, if we keep in mind that `8 % 8 == 0`, we realize that 0 is the array index corresponding to virtual index 8. So, we can check whether the array cell at index 0 is empty or already used to store an element. We are in luck: it is empty. How do we know? Well, one way we have is checking where the pointer to the front of the queue is. In our case, it points to index 2, so we are good.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/09-13.png)

And then, the magic is done! The pointer to the rear of the queue moved past the end of the array and re-entered on the side where it begins. Now it can grow again toward larger indexes, at least until it clashes with the front of the queue (we’ll have to check it to avoid clashes).

That settles insertion, but what happens if we dequeue six elements and the front pointer reaches the end of the queue? As you can imagine, we do the same thing as we did for the rear: we use virtual indexes and the modulo operator to let the front pointer wrap around the end of the array.[](/book/grokking-data-structures/chapter-9/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/09-14.png)

We’ll discuss the details of these operations in the implementation section. For now, instead, let’s discuss how the different solutions that we have mentioned compare.

### A c[](/book/grokking-data-structures/chapter-9/)omparison of the possible implementations

Table 9.1 shows the asymptotic analysis for the running time of different implementations of a queue ADT. We can make some observations.[](/book/grokking-data-structures/chapter-9/)[](/book/grokking-data-structures/chapter-9/)

##### Table 9.1 Comparison of various implementations of a queue[](/book/grokking-data-structures/chapter-9/)[](/book/grokking-data-structures/chapter-9/)[(view table figure)](https://drek4537l1klr.cloudfront.net/larocca3/HighResolutionFigures/table_9-1.png)

|   | `enqueue()` | `dequeue()` | Dynamic size |
| --- | --- | --- | --- |
| Static array | `O(1)` | `O(1)` | No |
| Dynamic array | `O(n)` worst case `O(1)` amortized | `O(n)` worst case `O(1)` amortized | Yes |
| Linked list | `O(1)` | `O(1)` | Yes |

At the data structure level, there is nothing to suggest that we should prefer an array implementation because the linked list implementation is just as efficient and also flexible, allowing the queue to grow dynamically.

While fast on average, the implementation based on dynamic arrays can’t give us guarantees on individual operations. At times, `enqueue` and `dequeue` can be slower because we have to resize the underlying array.

However, we learned in chapter 8 that the real world sometimes behaves surprisingly differently from what the theory tells us. Let’s discuss this in the next section.

Exercise

9.1 As mentioned, it is also possible to use stacks to store a queue’s data. One stack, however, is not enough. Can you find a way to use two stacks to implement a queue? Hint: Either enqueue or dequeue will have to be `O(n)`.

## Implementation

The main disadvantage of implementing a queue with an underlying static array is that the queue will have a fixed size, and we have to decide its size the moment we create the queue.[](/book/grokking-data-structures/chapter-9/)

In some situations, this fixed size is a significant problem. However, when a queue’s capacity is predetermined, having a fixed size is not a problem.

And, we must say, using arrays also has some advantages:

-  *Memory efficiency*—An array will require less memory than a linked list to store the same elements. This is because with an array, besides the space needed for storing the actual elements, there is only a constant-space overhead, regardless of the number of elements in the array.[](/book/grokking-data-structures/chapter-9/)
-  *Memory locality*—An array, as we have discussed in chapter 2, is a single chunk of memory where all elements are stored side by side. This characteristic can be used to optimize caching at the processor level.[](/book/grokking-data-structures/chapter-9/)
-  *Performance*—Operations on arrays are usually faster than on linked lists.

These three points can make a lot of difference in practice. So, which implementation should we choose?

If you need flexibility in the size of the queue, and clean, minimal code is valuable to you, then go with linked lists. In the implementation based on linked lists, the `enqueue` and `dequeue` methods are just wrappers that call the methods of the underlying linked list: `insert_to_back` for `enqueue` and `delete_from_front` for `dequeue`. Therefore, we won’t discuss this implementation in detail here, but you can find the full Python code in the book’s repo on GitHub: [https://mng.bz/Dd5w](https://mng.bz/Dd5w).[](/book/grokking-data-structures/chapter-9/)[](/book/grokking-data-structures/chapter-9/)[](/book/grokking-data-structures/chapter-9/)

However, if you can pre-allocate your queue to its maximum capacity or if static size is not a concern, an implementation based on arrays may offer considerable advantages. The code in this case will be more complicated, but it’s a tradeoff with improved performance.

In the rest of this section, we will discuss the implementation of a circular queue, the one where the front and rear pointers wrap around the end of the array. The linear queue implementation simply has too many drawbacks to be practical in most situations.

### An underlying static array

Let’s dive into the details of the array-based implementation: as always, you can find the full code in our repo on GitHub: [https://mng.bz/NRa1](https://mng.bz/NRa1).[](/book/grokking-data-structures/chapter-9/)[](/book/grokking-data-structures/chapter-9/)

Even before we start with the class definition and the constructor, we must make the first decision. In the implementation using linked lists, the front and rear of the queue were easy to identify—they were just the head and tail of the list. We are not so lucky when we switch to arrays, and we have to decide how to handle these pointers.[](/book/grokking-data-structures/chapter-9/)[](/book/grokking-data-structures/chapter-9/)

Let me stress that this is not the only possible way, but here is what we will do—we will store two indexes, `front` and `rear`:[](/book/grokking-data-structures/chapter-9/)[](/book/grokking-data-structures/chapter-9/)

-  `front` will be the index of the next element to be dequeued.
-  `rear`, conversly, will be the index of the next array cell where a new element can enqueued.

Initially, we set both `front` and `rear` to `0`, the index of the first element in the array.[](/book/grokking-data-structures/chapter-9/)[](/book/grokking-data-structures/chapter-9/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/09-15.png)

When we enqueue a new element, the `rear` pointer is advanced to the next index. And when we dequeue an element, it’s the `front` pointer that is incremented.[](/book/grokking-data-structures/chapter-9/)[](/book/grokking-data-structures/chapter-9/)

All sounds good until we reach the maximum capacity. For example, if our queue has a capacity of five elements, and we enqueue all five elements without dequeuing any, the `rear` pointer will wrap around the array and will point back to the array cell at index `0`. So, both when the array is empty, and when it’s full, the `front` and `rear` pointers will point to the same index. How can we tell these situations apart?[](/book/grokking-data-structures/chapter-9/)[](/book/grokking-data-structures/chapter-9/)

There are many possible solutions, and here is the simplest one: we store the size of the queue in a variable that is updated on every enqueue and dequeue. This variable will make our life easier and many operations on the queue faster.

So, to recap, when we initialize a queue, we need to set the `front` and `rear` attributes for the class to `0`, and we also initialize the size of the queue (that is, the number of elements currently stored in the queue) setting it to `0`. We are not done just yet—we also need to initialize the underlying array. Note that I’m using a Python list in these examples although it’s actually a dynamic array because it’s the most convenient alternative in Python. Not only can it store any object, but we can also initialize it using a one-liner:[](/book/grokking-data-structures/chapter-9/)[](/book/grokking-data-structures/chapter-9/)

```
123456789class Queue:
    def __init__(self):
        if max_size <= 1:
            raise ValueError(f'Invalid size for a queue (must have at least 2 elements): {max_size}')
        self._data = [None] * max_size     
        self._max_size = max_size
        self._front = 0
        self._rear = 0
        self._size = 0
```

The first thing we need to do, however, is store the capacity of the queue, passed through the argument `max_size`. Before accepting it, we need to validate the value passed and make sure that the new queue will be able to host at least two elements. With this setup, checking the queue’s size, or whether it’s empty or full, becomes trivial:[](/book/grokking-data-structures/chapter-9/)

```
123456def __len__(self):
    return self._size
def is_empty(self):
    return len(self) == 0
def is_full(self):
    return len(self) == self._max_size
```

### Enqueue

[](/book/grokking-data-structures/chapter-9/)Now let’s focus on the details of enqueuing a new value to the queue. When we design how this method will work, we need to distinguish between three possible situations (assuming a queue with a capacity of `n` elements, `n>1`):[](/book/grokking-data-structures/chapter-9/)

-  `front <= rear` and `rear < n-1`: `front` is before `rear`, and `rear` is not at the end of the array.
-  `front <= rear` but `rear == n-1`: `front` is before `rear`, and `rear` points to the last element in the array.
-  `rear < front`: `front` and `rear` are swapped after `rear` has wrapped around the end of the array.

#### The initial situation

When the queue is created, both `front` and `rear` are initialized to `0`. From that point on, `rear` can only be incremented until it reaches the end of the array. And `front` can also be incremented on dequeue, but it can never get past `rear`.[](/book/grokking-data-structures/chapter-9/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/09-16.png)

This is the easiest situation to handle, where we still don’t have to worry about virtual indexes and wrapping the `rear` pointer around the end of the array. Before `rear` reaches the end of the array, the queue can’t even be full, so all we need to do is store the new value and increment `rear`.

#### Wrapping around the array

Now we get to the interesting part: `rear` points to the last element in the array. Well, we can start by assigning the new value to the empty cell pointed to by `rear`, nothing changes for this part. At this point, in our example, `rear=4`. If we just incremented it, it would point to index 5, which overruns the boundaries of our array. This is where we remember about virtual indexes, as discussed in the “Queue as a data structure” section.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/09-17.png)

[](/book/grokking-data-structures/chapter-9/)We can extend the regular indexing space of an array with these virtual indexes by imagining that indexes larger than the physical index of the last element will wrap around the array, as if they were arranged in a circle.[](/book/grokking-data-structures/chapter-9/)

Thus, index `5` will point to the same array cell as index `0`, and the `rear` pointer will effectively wrap around the array.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/09-18.png)

#### Front and rear swapped

At this point, the queue isn’t yet full (because `front` in our example points to index `1`, `dequeue` must have been called at some point), but `rear` points to a lower index than `front`. In practice, the two pointers have been swapped.

When we enqueue a new element, we can just increment `rear` as in our first case. But instead of checking for the end of the array, the boundary for the `rear` pointer becomes the `front` pointer instead.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/09-19.png)

In our example, after enqueuing the value `9`, `rear` and `front` both point to the element at index 1, and so `rear` can’t advance anymore: the queue is full.

As mentioned at the beginning of the implementation section, there are several ways to translate the checks and increments of the pointer into code, but using a helper variable to remember the size of the queue will make our lives incredibly easier. To understand whether the queue is empty, full, or partially full, we don’t have to check where `rear` and `front` are or which of the three cases above we are in. Instead, we just check how many elements are stored.

##### Tip

Delegate size, emptiness, and fullness checks of a data structure to helper methods that you can reuse in your code. Your code will be cleaner, with less duplication, and thus less prone to error.

[](/book/grokking-data-structures/chapter-9/)To increment `rear`, we could also handle the three cases separately by using conditionals, but I’ll go for a cleaner (although arguably less efficient) way—we can use the modulo operator to map virtual indexes into the physical indexes of the array, as explained in the “Queue as a data structure” section.[](/book/grokking-data-structures/chapter-9/)

With these assumptions, the code for `enqueue` becomes as simple as possible:

```
def enqueue(self, value):
    if self.is_full():
        raise ValueError('The queue is already full!')
    self._data[self._rear] = value
    self._rear = (self._rear + 1) % self._max_size
    self._size += 1
```

### Dequeue

We’ve learned how to add elements to the queue. Now let’s look at how to remove an element from it.[](/book/grokking-data-structures/chapter-9/)

Similar to what we did for `enqueue`, we need to consider a few cases when designing the `dequeue` method:[](/book/grokking-data-structures/chapter-9/)

-  When `front` is before `rear`
-  When `front` and `rear` point to the same index
-  When `front` and `rear` are swapped after `rear` has wrapped around the end of the array, but `front` is not at the end of the array
-  When `front` and `rear` are swapped, and `front` points to the last element in the array

If `front` points to a lower index than `rear`, we can simply increment `front` to dequeue an element.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/09-20.png)

If `front` and `rear` are pointing to the same index, the queue can be either empty or full, and we can only understand which it is by checking the `size` attribute.[](/book/grokking-data-structures/chapter-9/)[](/book/grokking-data-structures/chapter-9/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/09-21.png)

The last two cases are handled similarly to what we did for `rear` when enqueuing a new value. We increment the index that `front` points to, and if `front` is right at the end of the array, we use the virtual index trick and the modulo operator so that `front` can wrap around the end of the array.

Note that when `front` wraps around the end of the array, we go back to the initial configuration where `front` and `rear` are not swapped (that is, `front <= rear`).

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/09-22.png)

As for enqueue, instead of treating each case separately, we can use the modulo operator and write some cleaner code that doesn’t separately address each case:

```
def dequeue(self):
    if self.is_empty():
        raise ValueError("Cannot dequeue from an empty queue")
    value = self._data[self._front]
    self._front = (self._front + 1) % self._max_size
    self._size -= 1
    return value
```

Similar to what we did for stacks, we could define a peek method that returns the element at the front of the queue without removing it. As we saw in the last chapter, however, this method introduces a lot of unnecessary complication, so I wouldn’t include it in the queue interface unless it’s absolutely necessary.

Exercises

9.2 Implement the `peek` method for the `Queue` class. What are the main problems we need to be aware of, and how do we solve them? Hint: Check out what we did for stacks.[](/book/grokking-data-structures/chapter-9/)[](/book/grokking-data-structures/chapter-9/)[](/book/grokking-data-structures/chapter-9/)

9.3 Implement an iterator on the queue. Hint: When a queue, or a stack, is used in `for` loops, the elements are provided in the correct order, but they are also removed from the container.

## What about dynamic arrays?

Earlier in the chapter, I mentioned that dynamic arrays are rarely used for queues. Still, it’s worth discussing how such a solution works. It helps us better understand how circular queues work. And, although unlikely, in some contexts, dynamic arrays might actually be the best option.[](/book/grokking-data-structures/chapter-9/)[](/book/grokking-data-structures/chapter-9/)[](/book/grokking-data-structures/chapter-9/)

With a static array, even if we use virtual indexes and circular configuration to re-use the array cells freed up on dequeue, at some point, the queue might get full. It happens when the rear pointer reaches the (virtual) index immediately before the front of the queue. If we try to insert another element, we get an error because the queue is full—the rear pointer would walk past the front pointer.

If we were using a dynamic array, instead, this would be the time when we double the capacity of the underlying array—when we try to enqueue an element on a full queue, we can just allocate a new array. The problem is that our new array would have a size of 16, while our old array had a size of 8.

It might not seem like a big deal, but all the virtual indexes, as we had computed them on the old array, would be misplaced, and we couldn’t use modulo 8 to compute the array indexes. So, we would need modulo 16.

Even worse, if we copy the array as it is over the new array, we will encounter a big problem: the rear and front pointers will no longer make sense, and there will be a big hole in the middle of the queue. And yet, when we try to enqueue a new element, the rear pointer will still be just before the front pointer! So, because of this, depending on how we implement `is_full`, the method could erroneously consider the queue full. Or, in our implementation, the queue would overwrite existing elements and still stop before it fills the additional space.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/09-23.png)

[](/book/grokking-data-structures/chapter-9/)There is a way to work around this. When we copy the elements to the new array, we need to align the front of the queue to index 0, as shown in the following figure.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/09-24.png)

This won’t be any slower than copying the elements in the same positions as they were, and it won’t affect the asymptotic analysis. But it will make the code more complicated. Add to this the fact that with dynamic arrays the worst case for `insert` and `delete` is `O(n)`, which in turn means that `enqueue` and `dequeue` would also take linear time in the worst case. All in all, if you need a flexible queue whose size can adapt, you are often better off with an implementation based on linked lists.

## More applications of a queue

At the beginning of this chapter, we have discussed both real-world situations that work according to the FIFO principle and a software application such as task management that (in its simplest form) uses a queue. There are many other areas where queues are used as a part of a larger system and many algorithms that rely on a queue to work. For example, in chapter 13, we will talk about breadth-first search, an algorithm for traversing a graph and finding the minimum distance (in terms of number of edges) between one vertex of the graph and any (or all) of the other vertices.

Let’s discuss some other examples of how queues are used in computer science.

### Messaging systems

[](/book/grokking-data-structures/chapter-9/)When building large applications, and especially large web applications, the pace of requests can sometimes get too fast and too hectic to handle properly. When the requesters can afford a slower (non-real-time) response, we can regulate the pace of a web service by using the so-called *pull strategy* and a queue.[](/book/grokking-data-structures/chapter-9/)[](/book/grokking-data-structures/chapter-9/)[](/book/grokking-data-structures/chapter-9/)

Typically, a web service is configured to use the push strategy: when a service or a user client has a request, it directly contacts the service, which then handles the request. A surge of requests, however, can exceed the capacity of the server. Suppose that your service can handle a maximum of 100 requests per minute. If there is a surge of 200 requests within a few seconds, your service will be overloaded, some (in this case, many) requests will be lost and never answered, and your service may even crash.

With a messaging system, instead, requests are pushed to a high-capacity service that simply enqueues them as messages to a buffer like Kafka. Your service then reads (*pulls*) the messages from the queue at its own pace and in the same order they were sent.

If the buffer doesn’t support a priority for the messages, then the data structure it uses is exactly the simple queue we are presenting in this chapter. When priority is involved, a different type of queue is used, which we discuss in the next chapter.

### Web servers

A similar strategy can be used by web servers to keep track of the requests received from clients. In this case, there may be no messaging service buffer, and the web server may simply use a queue to store the incoming requests before processing them at its own pace.[](/book/grokking-data-structures/chapter-9/)[](/book/grokking-data-structures/chapter-9/)

### Operating systems

When it comes to scheduling CPU usage among active processes, disk usage, or printer spooling, your operating system can use a queue to round-robin the processes that need to access the same resource. Modern operating systems (OS) support the concept of process priority so that resources such as CPU or disk are allocated first and more often to high-priority processes. Printer spooling, however, is more likely to be handled more fairly according to the FIFO policy, so you can find a printer queue in your OS.[](/book/grokking-data-structures/chapter-9/)[](/book/grokking-data-structures/chapter-9/)

## Recap

-  A *queue* is a container that adheres to the FIFO policy: that is, the *first* element *in* the queue is the *first* element *out*. You can picture a queue as a line at the checkout counter: people enter at the back of the queue, and the one person at the front gets served.[](/book/grokking-data-structures/chapter-9/)[](/book/grokking-data-structures/chapter-9/)
-  Queues are widely used in computer science and programming, including messaging systems, networking, web servers, and operating systems. In addition, many algorithms use queues to keep track of the order in which elements must be processed, such as breadth-first search.
-  Queues provide two operations: `enqueue` (to add an element to the back of the queue) and `dequeue` (to remove and return the element from the front of the queue). Similarly to stacks, there is no other way to insert or delete elements, and searching is generally not allowed.[](/book/grokking-data-structures/chapter-9/)[](/book/grokking-data-structures/chapter-9/)
-  A queue can be implemented using either arrays or linked lists to store its elements.
-  Using linked lists, `enqueue` and `dequeue` take `O(1)` time in the worst case.
-  Using static arrays, we can implement a *linear queue*, which can only support a fixed number of enqueue operations. Alternatively, we can implement a *circular queue*, where the array is imagined as a circular container. This requires additional complexity.[](/book/grokking-data-structures/chapter-9/)[](/book/grokking-data-structures/chapter-9/)
-  While it is possible to use dynamic arrays, this type of implementation is quite complicated and not very common.
