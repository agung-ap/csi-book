# 5 Dynamic arrays: Handling dynamically sized datasets[](/book/grokking-data-structures/chapter-5/)

### In this chapter

- what are the limitations of static arrays
- overcoming problems with static arrays by using dynamic arrays
- tradeoffs and when to use dynamic arrays
- what does it mean to build a dynamic array
- the best strategies to grow and shrink dynamic arrays

In these first few chapters, we have discovered how versatile arrays are and discussed some of their applications. But have you noticed in all the examples we have seen, the maximum number of elements we can store, and thus the size of the array, is determined in advance and can’t be changed later? This can work in many situations but, of course, not always—it would be naïve to think so.

There are many examples of real-world applications where we need to be flexible and resize a data structure to meet an increasing demand. When the ability to adjust their size is added to arrays, we get *dynamic arrays*. In this chapter, we look at examples where flexibility gives us an advantage and then discuss how to implement dynamic arrays.

## The limitations of static arrays

Arrays are cool, right? Our little friend Mario sure thinks so: they are quite handy for storing items, and you can access these items quickly if you remember their position in the array (that is, their index).[](/book/grokking-data-structures/chapter-5/)[](/book/grokking-data-structures/chapter-5/)

Mario is so excited about learning how to use arrays that he can’t stop talking about it! He shares his passion for STEM and computers with his friend Kim from school, who is just as geeky.

Kim has already read something about arrays in her CS class and tries to curb Mario’s enthusiasm by raising some objections and highlighting their limitations. Their discussion goes on for a while without a clear winner. So, at home, after dinner, Mario looks for his mother’s help. She explains to him that he has only seen static arrays so far and that they do have some shortcomings.

### Fixed size

The most obvious problem with statically sized arrays is that they can’t be resized! I believe we can all agree on that, but what does it really mean? What are the consequences? It’s a twofold problem.[](/book/grokking-data-structures/chapter-5/)

A primary limitation of static arrays is their fixed size. Once full, a new, larger array must be created, and elements must be transferred from the old array to the new one.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/05-01.png)

This problem has less to do with arrays as abstract data structures than with arrays as low-level features of programming languages (as a reminder, we discussed this distinction in chapter 2) because arrays are implemented as a contiguous block of memory. As you can imagine, creating a new array to replace another one is expensive, both in terms of data to be moved and memory to be allocated and released. The second problem is a direct consequence of the first one: since changing the size of an array is expensive, we need to allocate enough space upfront to avoid the need for such resizing.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/05-02.png)

In chapter 3, when we defined our `SortedArray` class, we added an argument to its constructor specifying the maximum capacity of the array so that we could pre-allocate all the memory needed for the maximum number of elements the array could hold.[](/book/grokking-data-structures/chapter-5/)[](/book/grokking-data-structures/chapter-5/)

But this is also a waste. For example, if I know that I will need to support 10,000 elements on peaks, but most of the time, the array will only hold about 100, the remaining 99% of the space allocated to the array is sitting there unused. In such a situation, we are forced to think about the tradeoffs between allocating a larger array and wasting memory versus allocating the space we need “just in time” when we need it, but having to periodically move the elements we have to a larger (or smaller, when we are deleting many elements) array.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/05-03.png)

### Tradeoffs

How nice would it be if there was a more powerful version of arrays that could grow and shrink as we need, without much overhead? Well, unfortunately, there isn’t. In the next chapter, we discuss *linked lists*, a data structure that is more flexible than arrays and can be easily resized. But this flexibility comes at a price. In a linked list, if we want to read the fourth element, we can’t do it directly—we must read the first three before.[](/book/grokking-data-structures/chapter-5/)[](/book/grokking-data-structures/chapter-5/)

You might object that if there isn’t any version of arrays that is more powerful and flexible, why is this chapter titled “Dynamic arrays”?

I understand you may feel confused right now—you have a good reason. Here’s the thing: dynamic arrays are not another data structure or a different programming feature that magically lets us have our cake and eat it too (that is, resizing arrays for free and keeping all their benefits).

From a developer’s point of view, a dynamic array behaves much like a static one, except that if you try to add a new element to a full dynamic array, you won’t get an error. In fact, you won’t have to worry about the size of a dynamic array at all: the data structure manages its size for you.

Full disclosure: dynamic arrays are implemented with static arrays, and we still have to pay the price of allocating a new array and throwing away the old one every time we need to resize it. The key to dynamic arrays—what makes them a good compromise—is the strategy they use to grow and shrink the underlying static arrays.

The caveat is that dynamic arrays make some of the operations a little slower. That’s natural—we have to pay the cost of resizing the array from time to time. So, if we know in advance that an array will hold a certain number of objects or that the number of elements will slightly fluctuate around a certain value, then we should definitely prefer a static array. If, however, the number of elements grows or varies greatly over time (even shrinking significantly at some points), then a dynamic array would be preferable to avoid wasting memory and provide flexibility.

In the next section, we discuss why these strategies are important and which strategies work better. Then, after consolidating the understanding of how they work, we can move on to their implementation.

## How can we grow an array’s size?

[](/book/grokking-data-structures/chapter-5/)We know there is no shortcut to growing an array, and we know we must endure the pain of creating a new array every time the old one fills up and we need more space. But the following questions emerge:[](/book/grokking-data-structures/chapter-5/)

-  When should we resize the array?
-  How much larger should the new array be?
-  What should we do when we delete elements? Should we shrink the array as well?

It’s time to meet our little friend Kim again, who will help us figure out the answers.

## The trophy case

Kim is passionate about STEM, but what she really loves is robotics. She won several competitions, from the school to regional level, and every time she wins something, she puts the robot that won the prize in a trophy case in her family’s living room. She is so good at robotics and wins so many competitions that the case has run out of space.[](/book/grokking-data-structures/chapter-5/)

Her parents want to clean out the cabinet and get rid of some of the oldest robots, at least the ones she made in primary school. But that’s out of the question for Kim. She does not want to throw anything away, demanding a bigger cabinet for the new prizes.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/05-04.png)

After a lot of tears and pouting, Kim’s parents have to give in, and they agree to provide new cases to house Kim’s new trophies. But there is one caveat: the old cabinets can’t be extended and will have to be disposed of, so Kim will have to pay for the new cabinets (and the disposal of the old ones) herself with money from her piggy bank. If she runs out of money and can’t afford a new cabinet, she’ll have to get rid of some of the older robots.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/05-05.png)

So, Kim has no choice but to find the best strategy to save as much money as possible in the long run. (You might wonder why not use modular furniture. While that’s a valid point, for this analogy, let’s consider that modular solutions aren’t available.)

### Strategy 1: Grow by one element

[](/book/grokking-data-structures/chapter-5/)To establish a baseline, Kim evaluates the simplest possible growth strategy. After the case is full, as soon as she has a new robot to showcase that wouldn’t fit, she throws the old case away and has a new case built, one that can hold exactly the new number of robots and nothing more.[](/book/grokking-data-structures/chapter-5/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/05-06.png)

If her first case could hold four robots, when she wins a fifth prize, she will have a new case built to hold five robots, then one for six robots, and so on. The cost of the cases is (let’s assume) linear considering the number of robots they can hold (say, $200 per robot).

So, she would have to pay $200 * 5 + $200 * 6 + $200 * 7, and so on. At the third case replacement, she would have paid $200 * (5 + 6 + 7) = $3600, and she could probably say goodbye to her weekly allowance until high school.

Kim is not very enthusiastic about this prospect, so she keeps working to come up with better options.

### Strategy 2: Grow by X elements

[](/book/grokking-data-structures/chapter-5/)Growing the case by one unit at a time doesn’t seem like a good option. Intuitively, we can see that the new case is already filled up when created, and when a new robot has to be added, it will trigger the process again.[](/book/grokking-data-structures/chapter-5/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/05-07.png)

Maybe we can have a buffer instead, and when Kim builds a new trophy case, she makes it four units larger? That will cut Kim some slack and give her time to save more money from her allowance while winning trophies before needing to pay for a new case.

But is four units the right amount? In the spring, there are a lot of robotic fairs, and Kim usually participates in as many as she can. What if she wins a medal in 5 of them, or 10, or all of them? She might not even get the new case built in time to use it if she wins more than four medals in a week before the wooden shop delivers it.

Maybe she should make them 5 units larger, or 8, or 10? What’s the sweet spot?

### Strategy 3: Double the size

Finally, Kim considers a third strategy. Instead of increasing the size of the case by a constant amount, she doubles the size of the case each time she has to build a new one. This ensures that each new case will accommodate her trophies for a duration equal to the combined lifespan of all previous cases.[](/book/grokking-data-structures/chapter-5/)[](/book/grokking-data-structures/chapter-5/)

![By doubling the case size, the expected life of each new case is the same as the sum of the expected lives of all the previous cases because we can add as many robots to the new one as there were in the case we are replacing.](https://drek4537l1klr.cloudfront.net/larocca3/Figures/05-08.png)

Now that her four-unit case is full and she has won a new trophy, she will have an eight-unit case built. The next one will be a 16-unit case, and the one after that will be able to hold 32 robots.

Sure, if she builds bigger cases, she will have to advance more money, but then she won’t have to worry for a while. And if she wins more trophies faster, the new cases will keep pace.

But will she end up spending more or less money? What’s the best strategy?

### Comparing the strategies[](/book/grokking-data-structures/chapter-5/)

There is only one way to know: do the math.[](/book/grokking-data-structures/chapter-5/)

Kim has an ambitious goal—to win 60 medals by the time she enters high school. So, all she has to do is calculate how much it would cost to build increasingly larger trophy cases until she gets one that can hold at least 60 of her robots and see how they compare. And no, her parents aren’t going to buy a 60-unit case now. That would kind of defeat their purpose of getting their living room back without giving it over to robots.

Table 5.1 provides a cost comparison for the three strategies.

##### Table 5.1 Comparison of costs for strategies to gradually increase the size of a trophy case[(view table figure)](https://drek4537l1klr.cloudfront.net/larocca3/HighResolutionFigures/table_5-1.png)

| Strategy | Total cost (expression) | Final cost |
| --- | --- | --- |
| Increase size by 1 | $200 * (5 + 6 + 7 + 8 + … + 60) | $364,000 |
| Increase size by 4 | $200 * (8 + 12 + 16 + 20 + … + 56 + 60) | $95,200 |
| Double the size | $200 * (8 + 16 + 32 + 64) | $24,000 |

So, with the first solution, Kim would have to give up her college fund. The second option would be somewhat better, but she would still have to get a scholarship just to pay it back. The third option, while still expensive, is a lot cheaper than the other two.

You might have noticed that the last strategy has fewer terms to add—that might be a clue! In fact, she would only have to buy a new trophy case four times, which is a big improvement!

Still, $24,000 is a lot of money to waste on trophy cases, so in the end, Kim might listen to her parents, settle for a trophy case for 10 robots, and display only her best creations.

Nevertheless, the same reasoning can be applied to arrays, and it’s of great value.

### Applying the strategies to arrays

[](/book/grokking-data-structures/chapter-5/)So, from the examples we have seen and the math we have worked out, it seems that the best strategy is to double the size of the array every time we need more space.[](/book/grokking-data-structures/chapter-5/)

Before you are sold, you might still ask: What if, instead of growing by 4 units, we grew the case by 16?

Doing the math, $200 * (20 + 36 + 52 + 68) yields $35,200, closer to the doubling strategy but 50% costlier. A constant-increase strategy might have an optimal point, but it’s tailored to specific situations (like our 60-robot example). If we precisely knew our space needs, we could simply use a static array!

As mentioned earlier, the same reasoning can be applied to dynamic arrays. Suppose we need to implement a dynamic array by starting it with a single element and then allocating a new larger array each time the old one fills up. Let’s also imagine that we will eventually add 100 elements to the array.

Each time we create a new array, we have to allocate the memory, but we also have to copy the elements of the old array into the new one. For example, for the +1 strategy, the first time we resize the array, the old array has one element that we need to copy to the new array (of size two). Then we copy those two elements into a new array of size three, and so on.

It works similarly for the other strategies. The expressions for the cost (in terms of elements copied from the old array to the new array) and the final costs are summarized in table 5.2.

##### Table 5.2 A comparison of the number of assignments for strategies to insert 100 elements into a dynamic array[(view table figure)](https://drek4537l1klr.cloudfront.net/larocca3/HighResolutionFigures/table_5-2.png)

| Strategy | Number of assignments (expression) | Total assignments |
| --- | --- | --- |
| Increase size by 1 | 1 + 2 + 3 + 4 + 5 + 6 + … + 98 + 99 | 4851 |
| Increase size by 4 | 1 + 5 + 9 + 13 + … + 93 + 97 | 1225 |
| Double the size | 1 + 2 + 3 + 6 + 12 + 32 + 64 | 127 |

[](/book/grokking-data-structures/chapter-5/)The difference in the results is astounding! We won’t go into the math, but let me give you an idea of why we have this result. The expression for the first strategy is the sum of the first 99 integers, and it generalizes to any integer `n`: there is a long-known formula that says the result of summing the first `n` integers is `n * (n + 1) / 2`. In other words, the number of elements to be copied would be quadratic.

![Resizing an array with the +1 strategy versus resizing an array with the x2 strategy. There is a clear difference in terms of the number of times we need to copy the old elements over.](https://drek4537l1klr.cloudfront.net/larocca3/Figures/05-09.png)

With the last strategy, instead, we double the number of elements at each step, which means that we wait twice as long before resizing the array again. This is also a known mathematical progression, and we could prove that to get an array of size `n`, starting with an array of size 1 and using this strategy, we will only need to copy `O(n)` elements in the worst case.

In chapter 4, we saw that a quadratic function grows much faster than a linear function, so we do not doubt that we want a strategy that guarantees us linear overhead.

## Should we also shrink arrays?

[](/book/grokking-data-structures/chapter-5/)There is another aspect that we have ignored so far. We have agreed that it can be a good idea to double the size of a dynamic array as it fills up, but we haven’t talked about what to do when we delete elements.[](/book/grokking-data-structures/chapter-5/)[](/book/grokking-data-structures/chapter-5/)

In our trophy case example, we didn’t face this situation at all because Kim never wanted to remove any trophies or robots from the case. So, let’s look at a different example to understand better what we need. The new example will be something more intangible, closer to computer science—let’s imagine we need to implement a dynamic array to keep track of orders that are currently being worked on at your e-commerce company. When a new order comes in, it’s added to the array; when the order is fulfilled and closed, it’s removed. The entries remain in the array in the same sequence they were received (but any order can be deleted at any time).

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/05-10.png)

So, we start with a small array and double its size each time we fill the array—more precisely, each time we need to add a new element to a full array. The array keeps growing as new orders are received, but at some point, we also start deleting closed orders. So, how should the array adjust when orders are removed? Do we need to do something when we delete elements? Do we want to?

It depends heavily on the pace and timing of new orders coming in and old orders being closed, but, in general, we know that we should be ready to adjust when many elements are deleted. Why is that? Let’s consider the following situation: you get a spike in orders for Black Friday, so the array needs to be expanded many times to accommodate them all. For example, you get a peak of 10,000 open orders at the same time during the holidays, while normally, you only have 100 open orders at any given time. If you don’t resize the array after the Black Friday orders are closed, you’ll waste 99% of the memory on a huge, mostly empty, container. And if your company grows by a factor of 100 or more, we are talking about millions of empty elements (and thus gigabytes of memory).

So, it seems that we need to also shrink a dynamic array somehow. But what exactly should we do?

### Halve on delete

One possible strategy, probably the first that comes to mind, would be to shrink the array by halving it as soon as half of its elements are unused. This strategy has the advantage of reducing unused space, which would never be more than half of the total space. However, there is another edge case that we could look at to understand why this strategy might not be a good idea.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/05-11.png)

Consider a full dynamic array `A` with eight elements. Adding a ninth element `X` requires us to double the array’s size. So, we make a new 16-slot array `B`, transfer the elements, and add `X`. However, if we soon remove an element, half of `B` becomes empty. Our current approach would shrink the array by half, creating an eight-slot array `C`. Now, `C` is full again, and any addition would need another resize. This back-and-forth resizing, especially with very large arrays, can severely degrade performance. We need a more efficient approach.[](/book/grokking-data-structures/chapter-5/)

### Smarter shrinking

Let’s try another approach: when deleting an element causes the array to be half empty, we don’t panic. Instead of resizing the array immediately, we will wait. How long should we wait? Well, there could be many good options, but I’m going to stick with a safe one: we wait until only a quarter of the array is used. This means that, for an array of capacity eight, we only halve it when there are six unused elements.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/05-12.png)

This way, after the resizing, the new array will be half empty, and we will still be able to insert new elements for a while before it fills up. Is this the perfect solution?

##### Note

There is no perfect solution because the perfect choice could only be made if we knew the sequence of insertions and deletions in advance. But this is a reasonably good solution that works well in most cases.

## Implementing a dynamic array

Now that we have revealed the trick behind dynamic arrays, we can even implement them. To recap what we have discussed in this chapter: dynamic arrays can be implemented by using static arrays underneath and seamlessly (to the client) resizing these arrays as needed. For how to resize the helper static arrays containing data, we will use the following strategy:[](/book/grokking-data-structures/chapter-5/)[](/book/grokking-data-structures/chapter-5/)

1.  We start with an array of size one (unless the client specifies an initial capacity).
1.  If we need to insert a new element and the static array is already filled to its maximum capacity, we resize the array by doubling its size.
1.  After we remove an element from the array, we resize the array by halving its size if only a quarter of the maximum capacity is filled.

All set! We just need to write some code to do the magic for us.

### The DynamicArray class

In the rest of this chapter, we will implement an *unsorted* dynamic array. This means that the order of the elements is not guaranteed. We’ll make the following assumption: the elements will be stored in the same order as they are inserted. When an element is deleted from the array, the elements after it are shifted to fill the hole left by the removed element (we will discuss this decision in detail in the section about the `delete` method).[](/book/grokking-data-structures/chapter-5/)[](/book/grokking-data-structures/chapter-5/)[](/book/grokking-data-structures/chapter-5/)

Let’s dive into the implementation. As always, you’ll find the full code, along with documentation and tests, in the book’s repo on GitHub: [https://mng.bz/67J6](https://mng.bz/67J6). We’ll begin with

```
class DynamicArray():
    def __init__(self, initial_capacity = 1, typecode = 'l'):
        self._array = core.Array(initial_capacity, typecode)
        self._capacity = initial_capacity
        self._size = 0
        self._typecode = typecode
```

As with the `SortedArray` class, we reuse the `core.Array` base class with composition, creating the static array as an internal attribute, that the `DynamicArray` class will handle behind the curtain.[](/book/grokking-data-structures/chapter-5/)[](/book/grokking-data-structures/chapter-5/)[](/book/grokking-data-structures/chapter-5/)

As you can see, it’s a simple constructor, very similar to the one for `SortedArray`. But notice that this time, we need to store the type of the array’s elements, that is, the `typecode` argument. This is because we will need to create new static arrays each time we resize, and to do so, we need to pass the `typecode` argument to the constructor of `core.Array`.[](/book/grokking-data-structures/chapter-5/)[](/book/grokking-data-structures/chapter-5/)[](/book/grokking-data-structures/chapter-5/)

### Insert

Insertion doesn’t change much from what we were doing with static arrays in chapter 2. The only difference is that, before performing the insertions, we need to check if there is any room left. If the static array is full, we need to resize it by creating a new array with twice the capacity and moving all the elements from the old array to the new one.[](/book/grokking-data-structures/chapter-5/)[](/book/grokking-data-structures/chapter-5/)[](/book/grokking-data-structures/chapter-5/)

Let’s start by defining a helper method to perform the resizing:

```
def _double_size(self):
    old_array = self._array
    self._array = core.Array(self._capacity * 2, self._typecode) #1
    self._capacity *= 2
    for i in range(self._size):                                  #2
        self._array[i] = old_array[i]
#1 After saving a reference to the old array in a local variable, we can create a new array twice as large.
#2 We need to copy all the elements from the old array to the new one.
```

It’s nothing fancy. We only need to implement what we have discussed in this chapter and earlier in this section.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/05-13.png)

Now that we have the helper method for resizing the underlying static array, we can implement the `insert` method more easily and with a cleaner result:

```
def insert(self, value):
    if self._size >= self._capacity:
        self._double_size()
    self._array[self._size] = value     #1
    self._size += 1
#1 When it gets here, we are sure that self._size &lt; len(self._array).
```

What is the running time of the `insert` method, and how much extra memory does it use? Looking at the code, the instructions in insert take `O(1)` steps and require `O(1)` extra memory, except for the call to `_double_size()`.[](/book/grokking-data-structures/chapter-5/)

Remember, whenever we have a call to another method, the called method’s running time contributes to the overall execution time, so we need to analyze the inner calls as well. And indeed, there is a catch here: when called on an array of size `n`, `_double_size()` creates a new array (using `O(n)` extra memory) and moves `O(n)` elements.[](/book/grokking-data-structures/chapter-5/)[](/book/grokking-data-structures/chapter-5/)

A word of caution about space analysis: don’t let the fact that some memory is freed after it’s been used confuse you. We need to include all allocated memory, even if it’s freed later.

So `insert`, in turn, also takes `O(n)` time and uses `O(n)` extra space when the method to resize the array is called. This means that as the number of elements, `n`, grows, the resources needed by the method also grow linearly.

The fact that the worst-case running time and space requirements for `insert` are linear is bad news. We don’t have a worst-case constant-time `insert` anymore, like we had with static arrays.

Upon deeper analysis, however, we can also find a silver lining. I said that these are the requirements for when the resize helper method is called: What about when we don’t need to resize? In the best case, only the constant-time instructions are executed, and no extra space is used.

So, if we are lucky and we don’t have to resize the array, `insert` is pretty fast. That’s why it’s important—if we have any idea of how many elements we might need to insert—to use the `initial_capacity` argument in the constructor and pre-allocate a larger static array (this is not just theory; you can find the same idea in Java standard library).[](/book/grokking-data-structures/chapter-5/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/05-14.png)

But there is more! We need to dig even deeper and ask how many times the `_double_size` method is actually called?[](/book/grokking-data-structures/chapter-5/)

I won’t go into the formal analysis, but here is the intuition. If we start with an array of size `1`, we can only double it `log(n)` times before its size becomes `n`. And on each of those calls, we move only a fraction of those `n` elements.

For example, to get to eight elements, we call `_double_size` three times, and we move a total of `1 + 2 + 4 = 7` elements (1 the first time, 2 the second, and so on). This is generally true, and we can prove that we only need to copy `O(n)` elements and use `O(n)` extra space to insert `n` elements into a dynamic array.

Therefore, we can say that the *amortized time* for `n` insertions into a dynamic array is `O(n)`. As mentioned in chapter 4, with an amortized analysis, we can’t give any guarantee for the individual insertion, which can be slow if we are unlucky and need to resize the underlying array. But if we perform a batch of operations, we can guarantee that the total cost is of the same order of growth as for static arrays.

### Find

[](/book/grokking-data-structures/chapter-5/)There is nothing special about the `find` method for dynamic arrays. We can use the same methods we wrote for unsorted and sorted arrays, respectively, on both static and `dynamic` arrays.[](/book/grokking-data-structures/chapter-5/)[](/book/grokking-data-structures/chapter-5/)

In our case, for an unsorted array, we just have to bite the bullet and scan the whole array until we find a match (or don’t). Thus, with an unsorted array, we already know that we can’t do better than `O(n)` for the running time (no extra space used).

The method is exactly the same as the linear search that we have already discussed in chapter 2:

```
def find(self, target):
    for index in range(self._size):
        if self._array[index] == target:
            return index
    return None
```

### Delete

For the `delete` method, either we can either implement a delete-by-index method or we can reuse `find` to implement a delete-by-value variant. Here, I’ll show you the latter, which only has three more instructions to find the index and check if the value exists.[](/book/grokking-data-structures/chapter-5/)[](/book/grokking-data-structures/chapter-5/)

Note that if there are duplicates, we delete the first occurrence of the value.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/05-15.png)

As with `insert`, we need to check whether we need to resize, but this time, the check is the last action we perform, and resizing means shrinking. So, first, we must find the element to delete and then remove it from the array, shifting all elements after it. Only at this point can we check whether the array is full for more than a quarter of its maximum capacity—otherwise we decide to shrink it:

```
def delete(self, target):
    index = self.find(target)
    if index is None:
        raise(ValueError(f'Unable to delete element {target}: the entry is not in the array'))
    for i in range(index, self._size - 1):
        self._array[i] = self._array[i + 1]
    self._size -= 1
    if self._capacity > 1 and self._size <= self._capacity/4:   #1
        self._halve_size()
#1 Check if the array should be shrunk after removal.
```

Similar to `insert`, the `delete` method uses a larger amount of resources in the calls where the resize is triggered. But unlike for `insert`, even if we don’t resize the array, this version of the method has an `O(n)` worst case for the running time. Here, we use linear search to find the index of the value to delete and then shift all elements after the deleted one (an operation that requires a linear number of assignments, in the worst case).[](/book/grokking-data-structures/chapter-5/)[](/book/grokking-data-structures/chapter-5/)

If we decided not to preserve the insertion order, we could implement a delete-by-index method (taking the position of the element to be deleted as an argument) that had a similar amortized performance as the `insert` method. Which version of the method is better? That depends on the context, that is, on the requirements of your application.

Note that the difference is not just a matter of implementation. We are choosing between different algorithms, each with its unique behavior and tradeoffs.

This concludes the implementation section—the same `traverse` method we implemented earlier can be used here as well.[](/book/grokking-data-structures/chapter-5/)

Exercises

5.1 Implement the delete-by-index method and make sure that the amortized running time and extra space for `n` deletions are both `O(n)`. Hint: Suppose we don’t need to preserve the insertion order of the elements.

5.2 If you implement the version of delete that removes elements by index, what are some possible drawbacks to swapping the deleted element with the last element instead of shifting the elements after the deleted one?

5.3 Implement the `DynamicSortedArray` class, modeling a dynamic array whose elements are kept in ascending order. What’s the best possible running time for `insert` and `delete`?[](/book/grokking-data-structures/chapter-5/)[](/book/grokking-data-structures/chapter-5/)

## Recap

-  [](/book/grokking-data-structures/chapter-5/)Arrays are great containers when we need to access elements based on their position. They provide constant-time access to any element, and we can read or write any element without sequentially accessing the elements before it.
-  However, arrays are inherently static. That is, because of the way they are implemented in memory, their size cannot be changed once they are created.
-  Having a fixed-size container means that we can’t be flexible if we find that we need to store more elements. Furthermore, allocating a large array from the start to support the largest possible number of elements is often a waste of memory.
-  Dynamic arrays are a way to get the best of arrays and add some flexibility. They are not a different type of data structure. They use fixed-size arrays but add a strategy to grow and shrink them as needed, reallocating the underlying static array each time it needs to be resized.
-  The best strategy for dynamic arrays is to double the size of the underlying static array when we try to insert a new element into a full array and halve the size of the array when, after removing an element, three-quarters of the elements are empty.
-  This flexibility comes at a cost: insert and delete can’t be constant time as they are for static unsorted arrays. But for the insert method (and, under some assumptions, for the delete method as well), we can guarantee that `n` operations take an `O(n)` amortized running time and additional memory.
