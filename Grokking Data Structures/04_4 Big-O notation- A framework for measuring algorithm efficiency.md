# 4 Big-O notation: A framework for measuring algorithm efficiency

### In this chapter

- objectively comparing different algorithms
- using big-O notation to understand data structures
- the difference between worst-case, average, and amortized analysis
- a comparative analysis of binary and linear search

[](/book/grokking-data-structures/chapter-4/)In chapter 3, we discussed how binary search seems faster than linear search, but we didn’t have the tools to explain why. In this chapter, we introduce an analysis technique that will change the way you work—and that’s an understatement. After reading this chapter, you’ll be able to distinguish between the high-level analysis of the performance of algorithms and data structures and the more concrete analysis of your code’s running time. This will help you choose the right data structure and avoid bottlenecks *before* you dive into implementing code. With a little upfront effort, this will save you a lot of time and pain.[](/book/grokking-data-structures/chapter-4/)

## How do we choose the best option?

In chapter 3, you were introduced to two methods for searching a sorted array: *linear* and *binary search*. I told you that binary search is faster than linear, and you could see an example where binary search required only a few comparisons, while linear search had to scan almost the whole array instead.[](/book/grokking-data-structures/chapter-4/)[](/book/grokking-data-structures/chapter-4/)[](/book/grokking-data-structures/chapter-4/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/04-01.png)

You might think this was just a coincidence or I chose the example carefully to show you this result. Yes, of course, I totally did, but it turns out that this is also true in general, and only in edge cases, linear search is faster than binary.

However, to determine which algorithm is faster, we need a consistent method to measure their performance. We may want to know not only how fast it is but also, maybe, how much it consumes in terms of resources (memory, disk, specialized processor’s time, etc.).

So, how can we measure algorithm performance? There are two main ways:

-  Measuring the implementation of an algorithm, running the code on various inputs, and measuring the time and the memory it takes. This is called *profiling*.[](/book/grokking-data-structures/chapter-4/)
-  Reasoning about an algorithm in more abstract terms, using a simplified model for the machine it would run on and abstracting many details. In this case, we focus on coming up with a mathematical law describing the running time and the memory in terms of the input size. This is called *asymptotic analysis*.[](/book/grokking-data-structures/chapter-4/)

### Profiling

The good thing about profiling is that there are tools already available that do most of the work for you, measuring the performance of your code and even breaking down the time by method and by line.[](/book/grokking-data-structures/chapter-4/)[](/book/grokking-data-structures/chapter-4/)

In Python, `cProfile` and `profile` ([https://docs.python.org/3/library/profile.html](https://docs.python.org/3/library/profile.html)) are available to everyone. You only have to import the one you want to use and set up some code that calls the methods you want to profile.[](/book/grokking-data-structures/chapter-4/)[](/book/grokking-data-structures/chapter-4/)

Profiling looks great, but does it solve all our needs? Not really.

We profile a specific implementation of an algorithm, so the results are heavily influenced by the programming language we choose (some languages may handle the operations we need better than others) and also by the actual code we write. Thus, the implementation details can affect the overall result, and bad implementation choices can make the implementation of a good algorithm slow. Moreover, the machine on which the profiling is run and its software, such as the operating system, drivers, and compilers, can also affect the final result.

In other words, when we profile linear and binary search, we compare the two implementations, and we get data about the implementation. We can’t assume that these results will hold for all implementations, and, for what is worth, we also can’t generalize the results and use them to compare (only) the two algorithms.

The other notable shortcoming of profiling is that we are testing these implementations on finite inputs. We can, of course, run the profiler tool on inputs of different sizes, but we can only use inputs as large as the machine we are using will allow.

For some practical situations, testing on these inputs may be enough. But you can only generalize the result so much: some algorithms outperform their competition only when the size of the input is larger than a certain threshold. And you can’t generalize the results you get on a smaller machine for larger machines or from a single machine to a distributed system.

### Asymptotic analysis

[](/book/grokking-data-structures/chapter-4/)The main alternative to profiling is asymptotic analysis. The goal of asymptotic analysis is to find mathematical formulas that describe how an algorithm behaves as a function of its input. With these formulas, it’s easier for us to generalize our results to any size of the input and to check how the performance of two algorithms compares as the size of the input grows toward infinity (hence the name).[](/book/grokking-data-structures/chapter-4/)[](/book/grokking-data-structures/chapter-4/)

The results we obtain are independent of any implementation and, in principle, valid for all programming languages.

You can imagine that there is also a downside. Of course, we have to work harder to get those formulas, and it requires working out the math, sometimes a lot of math. Occasionally, it’s so hard that there are algorithms for which we haven’t found the formula yet or we don’t know if we found the best formula to describe their running time.

However, this challenge in finding the right formula does not occur with the algorithms used by the data structures described in this book and with many others. You won’t even have to figure out these formulas yourself, and in fact, this book will not discuss the math involved. You’ll just be working with the results that have been proven by generations of computer scientists.

My goal is to show you how to use these results and what to look for when deciding which algorithm or data structure to use.

### Which one should I use?

Both profiling and asymptotic analysis are useful at different stages of the development process. Asymptotic analysis is mostly used during the design phase because it helps you choose the right data structures and algorithms—at least on paper.[](/book/grokking-data-structures/chapter-4/)

Profiling is useful after you have written an implementation to check for bottlenecks in your code. It detects problems in your implementation, but it can also help you understand if you are using the wrong data structure in case you skipped the asymptotic analysis or drew the wrong conclusions.

## Big-O notation

In this book, we are going to focus on asymptotic analysis, so we will briefly describe the notation commonly used to express the formulas that describe the algorithms’ behavior. But before we do so, remember what we said about asymptotic analysis? It uses a generic (and simplified) representation of a computer on which we imagine running our algorithms. It’s important that we begin by describing this model because it deeply influences how we perform our analysis.[](/book/grokking-data-structures/chapter-4/)

### The RAM model

[](/book/grokking-data-structures/chapter-4/)In the rest of the book, when we analyze an algorithm, we need a touchstone that allows us to compare different algorithms, and we want to abstract away as many hardware details (such as CPU speed or multithreading) as possible.[](/book/grokking-data-structures/chapter-4/)[](/book/grokking-data-structures/chapter-4/)

Our fixed points are a single-core processor and *random-access memory* (RAM). This means that we don’t have to worry about multitasking or parallelism and that we don’t have to read memory sequentially like in tapes, but we can access any memory location in a single operation that takes the same time, regardless of the actual position.[](/book/grokking-data-structures/chapter-4/)

From there, we define a *random-access machine* (also abbreviated as RAM), a computation model for a single-processor computer and random-access memory.[](/book/grokking-data-structures/chapter-4/)

##### NOTE

When we talk about the RAM model, RAM stands for random-access machine, not random-access memory.

This is a simplified model where memory is not hierarchical like in real computers (where you can have disk, RAM, cache, registries, and so on). There is only one type of memory, but it is infinitely available.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/04-02.png)

In this simplified model, the single-core processor offers only a few instructions—mainly those for arithmetic, data movement, and flow control. Each of these instructions can be executed in a constant amount of time (exactly the same amount of time for each).

Of course, some of these assumptions are unrealistic, but in this context, they are also fine. For example, the available memory can’t be infinite, and not all operations have the same speed, but these assumptions are fine for our analysis, and they even make sense to a certain point.

### Growth rate

Now that we have defined a computational model for studying algorithms, we are ready to introduce the actual metrics we use. Yes, that means this is the math part! But don’t worry! We are going to take a visual approach and greatly simplify the notation used—we are going to define and use it very informally.[](/book/grokking-data-structures/chapter-4/)[](/book/grokking-data-structures/chapter-4/)[](/book/grokking-data-structures/chapter-4/)

As mentioned earlier, we want to describe the behavior of algorithms using some formulas that relate the size of the input to the resources used.

There are times when we need to go through this mathematical analysis. We are interested in how the resources needed change as the input gets larger. In other words, we are interested in the rate of growth of these relations.

For a given resource, for instance, the running time of our algorithm, we are going to define a function `f(n)`, where `n` is typically used to define the size of the input. To express the rate of growth of function `f`, we use the big-O notation.

##### Note

The name big-O comes from the symbol used for the notation, a capital O.

We write `f(n) = O(n)` to state that the function `f` grows as fast as a line in the *Cartesian plane.* Which line? Well, we don’t say as we don’t need to know. It can be any line passing through the *origin*, except the vertical axis.[](/book/grokking-data-structures/chapter-4/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/04-03.png)

In practice, if a resource, such as the memory used by our algorithm, grows at a rate given by a function `f(n) = O(n)`, this means that as the input to our algorithm gets larger, the memory it uses is bounded between two straight lines on the graph.

More formally, we could say, for example, that for `n > 3`, it holds `n/2 < f(n) < n`. Or, equivalently, we could say that for `n > 30`, it holds `n/4 < f(n) < 5n`. It doesn’t matter whether we choose the first pair of lines, `y = n/2` and `y = n`, or the second pair, `y = n/4` and `y = 5n`: asymptotic analysis just asks us to find one such pair of lines that, for sufficiently large values of `n`, act as bounds for `f`.

In fact, the notation `O(n)` doesn’t define a single function but a class of functions—all the functions that grow as fast as straight lines—and writing `f(n) = O(n)` means that `f` belongs to this class.

However, the important thing that `f(n) = O(n)` tells us is that there is at least one line that will outgrow `f(n)` when `n` becomes large enough.

So, when we say that our algorithm runs in `O(n)` time (aka linear time), it means that if we drew a graph showing how long it took for the algorithm to run on inputs of different lengths, the graph would look like a straight line. There would be tiny bumps here and there due to random things that can happen in computers as programs run, but if you zoom out of those details, it looks like a straight line.

### Common growth functions

[](/book/grokking-data-structures/chapter-4/)You might ask, though, which line is it going to be? If we look at the lines in the next figure, there is a lot of difference between them: one grows much slower than the other! (Note that we will focus on the first quadrant for the rest of the graphs, restricting to positive values for both axes.)[](/book/grokking-data-structures/chapter-4/)[](/book/grokking-data-structures/chapter-4/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/04-04.png)

With this notation, we can’t tell upfront which line our growth is going to be close to. That’s too bad, but we are okay with it. Some functions grow a lot faster than straight lines, and we have ruled them out! Other functions grow more slowly (significantly more slowly!) than our running time, and that’s unfortunate, but at least we know.

![Some of the growth rates you might encounter when studying algorithms. From left to right, the functions grow increasingly faster.](https://drek4537l1klr.cloudfront.net/larocca3/Figures/04-05.png)

If you look at some examples of cornerstone functions that we might often encounter in algorithms, you can see that logarithmic functions grow very slowly, and linear functions grow at a constant rate. With linearithmic functions (in the order of `O(n * log(n))`), we see a bit of acceleration, meaning that the growth is faster with larger inputs (for example, the growth is less when we go from 100 to 200 elements than when we go from 200 to 300). Linearithmic functions, however, do not grow too fast. Polynomial functions such as `n``3` or `3n``2` `– 4n + 5`, conversely, accelerate rapidly with input size, and exponential functions such as `2``n` or `5``n+2` really skyrocket.

The set of functions I’ve shown you doesn’t include all the possible function classes: it’s impossible to list them all. But there is one that it’s worth adding: the constant function, a function whose value doesn’t change with the size of the input. The class of constant functions is denoted by `O(1)`.

In our RAM model, we can say that all the basic instructions take `O(1)` time.

### Growth rate in the real world

[](/book/grokking-data-structures/chapter-4/)In the previous section, we have only talked about how these functions grow, but are they good or bad? Is a logarithmic function better than an exponential one? Of course, functions are not good or bad inherently—that depends on what quantity a function describes. If your formula describes your income based on units sold, I bet you’d prefer that it featured a factorial term![](/book/grokking-data-structures/chapter-4/)

In asymptotic analysis, we usually measure the resources needed to run an algorithm, so we are usually happy to find that our algorithm is associated with a slowly growing function. It’s time we look at a concrete example to give you a better idea.

Imagine that we are trying to understand whether we can afford to include some algorithms in our code, based on their running time. In particular, we want to look at the following five algorithms that operate on arrays:

-  Search in a sorted array.
-  Search in an unsorted array.
-  *Heapsort*, a sorting algorithm that we will discuss in chapter 10. Sorting takes the array [3,1,2] and returns [1,2,3].[](/book/grokking-data-structures/chapter-4/)
-  Generating all pairs of elements in an array. For example, for the array [1,2,3], its pairs are [1,2], [1,3], and [2,3].
-  Generating all the possible subarrays of an array. For example, for the array [1,2,3], its subarrays are [], [1], [2], [3], [1,2], [1,3], [2,3], [1,2,3].

How do we figure out which is fast and which is slow? Should we run all these algorithms on many inputs and take note of how long it took? That might not be a good idea because it would take us a long time—a really long time, as we’ll see.

The good news is that if we know a formula that describes the asymptotic behavior of an algorithm, we can understand its order of magnitude, an estimate of the time it will take for inputs of various sizes (not the exact time it will take to run, but an idea of whether it will take milliseconds, seconds, or even years!).

[](/book/grokking-data-structures/chapter-4/)I have summarized in another figure an estimate of how the five algorithms would perform, assuming that each one of the basic instructions on our RAM model takes 10 nanoseconds (ns) to run. For each algorithm, the figure shows the formula for its asymptotic running time. You’ll have to trust me on these, but we’ll soon see an example of how to derive these formulas.

![How long does it take to run an algorithm? That depends on the order of growth of its running time. All results are approximated.](https://drek4537l1klr.cloudfront.net/larocca3/Figures/04-06.png)

As you can see, logarithmic functions are pretty nice. We could run a binary search on a billion elements, and it would still take the time it takes some atoms to decay, which is too fast for us to notice, anyway. Sorry to break it to you, but most algorithms won’t be that fast. The range of acceptable growth rates includes linear functions, which take the blink of an eye (or maybe a few blinks—in this analysis, it’s the order of magnitude that matters), even for large inputs.

Linearithmic functions, like good sorting algorithms, are still manageable: we are talking about minutes to sort a billion elements—just the time to take a break and make a cup of tea or coffee. Quadratic functions, however, are already hard to run on large inputs: we are talking about thousands of years on the same one-billion-element array, so if such a job were finished today, it would have started about the time the Pyramids were built. Now I hope you understand why it is important that you choose a sorting algorithm that is linearithmic, like *mergesort* or *heapsort*, over one that is quadratic, like *selection sort*.[](/book/grokking-data-structures/chapter-4/)[](/book/grokking-data-structures/chapter-4/)[](/book/grokking-data-structures/chapter-4/)

##### Tip

If you’d like to learn more about sorting algorithms, Aditya Bhargava explains them nicely in his highly popular *Grokking Algorithms, Second Edition* (Manning, 2023)![](/book/grokking-data-structures/chapter-4/)[](/book/grokking-data-structures/chapter-4/)

Finally, we talk about the exponential functions: small inputs are usually manageable, but you can see that with 60 elements, it would take us centuries (and so many subsets!), and with 100 elements, we are already in the order of magnitude of the age of the universe.

### Big-O arithmetic

[](/book/grokking-data-structures/chapter-4/)When I gave you the definition of the big-O notation, I told you that to be able to state that `f(n) = O(n)`, we do not care which straight line can grow beyond `f`, as long as there is one. It doesn’t matter which line we choose, whether it is `y = n`, `y = 5n`, or some other. The important thing is that for sufficiently large values of `n`, the line is always above our `f(n)`.[](/book/grokking-data-structures/chapter-4/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/04-07.png)

This property allows us to look at the big-O definition from a different angle: we can say that `O(n)` is the class of all straight lines. This means that, for asymptotic analysis, two lines are considered asymptotically equivalent, so two functions `f(n) = n` and `g(n) = 3n` are considered equivalent—their growth is of the same order of magnitude.

But obviously, `3n` grows much faster than `n`, by a factor of 3. So, how can they be equivalent?

Beyond the math, the key point is that if you compare them to any function in `h(n) = O(log(n))`, both will outgrow `h`, at some point. And if you compare `f`, `g,` or any `c*n = O(n)` with `z(n) = O(n*log(n))`, they will all be outgrown by `z`, no matter how big the value of the constant `c` is.

These considerations have direct consequences for how we write expressions in the big-O notation and also how we compute expressions with terms expressed in the big-O notation.

First, as we have seen, constant factors can be ignored, so `c * O(n) = O(c * n) = O(n)` for all real (positive) constants `c`. The second important conclusion we can draw is that we only need to remember the largest factor in a polynomial. `O(c * n + b)` simplifies to `O(n)`: in fact, `O(c * n + b) = c * O(n) + b * O(1) = O(n)`. Geometrically, this means that we don’t need a line to pass through the origin to find a line with a steeper growth trajectory.

Perhaps the best way to show what this means and why it holds is with an example. Let’s consider the function `f(n) = 3n + 5`.[](/book/grokking-data-structures/chapter-4/)

Plotting function `f` in the Cartesian plane, we can see that we can find (at least) two lines, `g(n) = 5n` and `h(n) = 2n`, which bound `f` for `n` ≥ `3`, that is, for `n` ≥ `3` we have `2n < 3n + 5 < 5n`. But this satisfies the requirements of big-O notation, and so we can conclude that `3n + 5 = O(n)`.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/04-08.png)

Now, the best part is that this simplification rule is not limited to lines! It’s true for polynomials of any order and, in general, for expressions that sum any class of functions:

```
O(6 * n * log(n) + 110 * n + 9999) = O(n * log(n)) + O(n) + O(1) = O(n * log(n)).
```

Finally, you must be more careful when there are nonconstant terms that are multiplied or combined with other nonlinear functions.

With `O(n)*O(log(n)),` we can’t simplify anything except the notation, bringing all the formulas together as `O(n * log(n))`.

### Worst-case vs. average vs. amortized analysis

Now that you have covered the notation, there are a few more considerations about asymptotic analysis that we need to make.[](/book/grokking-data-structures/chapter-4/)[](/book/grokking-data-structures/chapter-4/)[](/book/grokking-data-structures/chapter-4/)[](/book/grokking-data-structures/chapter-4/)[](/book/grokking-data-structures/chapter-4/)

When doing asymptotic analysis, we usually, unless otherwise stated, consider the worst possible situation. Think about linear search in a sorted array. There are searches where the result is found after only a few comparisons, if it’s near the beginning of the array, and other searches where we have to scan almost the whole array, if the target is near the end of the array. Which case should we consider? Well, we want to be thorough and consider the worst possible case, and we call this *worst-case analysis*.

There are [](/book/grokking-data-structures/chapter-4/)other situations where we can still have different behaviors depending on how lucky we are, but the probability of good behavior is much higher than for linear search. In these cases, along with worst-case performance, we can also discuss the *average-case analysis* of the algorithm’s performance, which takes into account the likelihood of many different inputs to compute an expected value for the performance of the algorithm.

Finally, for some data structures, there is a guarantee that by performing the same operation on the data structure many times, even with different inputs, the average performance will be better than we can guarantee for a single run. For example, in chapter 12, we will learn that if we repeat `search` and `insert` on a hash table many times (say a million) under certain conditions, we can guarantee that the sum of all the running times will be better than the worst-case running time of a single operation multiplied by a million.

When this happens, the guarantee is never on a single operation, which can be unusually slow if you are unlucky. If we run a large number of operations, however, we can amortize the cost of the single unlucky operation by spreading it over the total time taken by all the operations. In fact, this is what we call *amortized analysis.* While average-case analysis tells us what to expect on average but gives us no guarantees for a single run, amortized analysis establishes a worst-case bound for the combined performance of a large number of operations.

For exampl[](/book/grokking-data-structures/chapter-4/)e, you might have a data structure `D` for which insertion normally takes `O(1)`, but once in a hundred runs, it takes `O(n)`, where `n` is the number of elements the data structure stores. We know that

-  Worst-case analysis tells us that insertion for `D` is as slow as `O(n)` in some cases. That’s technically correct but also quite misleading, isn’t it? It’s only going to be a slow linear operation once in a hundred operations!
-  Average-case analysis tells us that if `D` has `n` elements, the average running time is `O(n/100)` for a single insertion, which still means a linear bound for large values of `n`. And it still doesn’t tell us the whole story, because only one in a hundred operations takes linear time.

Now suppose we insert `m = 1000` elements into an initially empty `D`. Here’s what each type of analysis can tell us:

-  Worst-case analysis: `T(m) = O(m2)`.
-  Average-case analysis: `T(m) = O((m/100)2) = O(m2)`.
-  Simplifying, we assume that exactly `990` of these operations will take `O(1)`, and only `10` of them take `O(m)`. So, the time spent on all `m` operations is `T(m) = (m - 10) * O(1) + 10 * O(m) = O(m)`. We can do a similar reasoning for `m = k * 100`, where `k` is constant.

Amortized analysis matches our intuition when we need to measure the performance of an algorithm over a large batch of operations, each of which is usually fast and only sometimes slow. In these cases, we can use amortized analysis to get a tighter bound on all the operations combined. We will look at a very similar example in chapter 5.

##### Tip

To avoid unpleasant surprises, it’s very important that, when you evaluate an algorithm, you pay attention to what kind of analysis the results refer to. Amortized analysis is great, but sometimes—for example, in real-time systems—you need guarantees on the worst possible case.

### Measured resources

[](/book/grokking-data-structures/chapter-4/)There can be many resources you may want to measure, depending on the context, but in this book, we focus on two. You have already seen that we are interested in running time to understand how long it will take for an algorithm to compute its result. To say that algorithm *A* takes linear time, we write `T``A``(n) = O(n)`.[](/book/grokking-data-structures/chapter-4/)[](/book/grokking-data-structures/chapter-4/)

The other critical resource is memory. There are cases where you may want to differentiate between RAM and disk consumption or cache usage. But, in general, we just use the term *space* to refer to all the memory used by an algorithm or a data structure, without worrying about where it’s hosted.[](/book/grokking-data-structures/chapter-4/)

For data structures, we want to keep track of how much *extra space* an algorithm (applied to the data structure) uses. Extra space means any memory in addition to what is already occupied by the data structure.[](/book/grokking-data-structures/chapter-4/)

For example, suppose you need to invert an array `A`. We can do this using a second array `B` of the same size and assign the last element of `A` to the first of `B`, and so on. This way, we use `O(n)` extra space for an array of size `n`, and we can write `S(n) = O(n)`.

Alternatively, we can invert the array in place, using a single variable to swap the first and last elements of `A`, then the second and penultimate, and so on. Since we are using only a single variable whose size doesn’t depend on `n`, we only need a constant amount of extra space, so we can write that as `S(n) = O(1)`.

## An example of asymptotic analysis

Now that we have defined the nomenclature we will use throughout the rest of the book, we need to close the circle for this chapter and use big-O notation to evaluate the performance of the two search algorithms we have defined on ordered arrays.[](/book/grokking-data-structures/chapter-4/)[](/book/grokking-data-structures/chapter-4/)[](/book/grokking-data-structures/chapter-4/)

How do we do this? We can reason about the steps the algorithm performs abstractly. Or we can look carefully at our code and note the expected asymptotic running time for each instruction. Then, we derive an expression from which we can compute the final formula—most of the time, this is enough.

By the way, our main goal in our analysis will be to find an upper bound on the running time and extra space of the algorithm (that is, to find a formula that limits the maximum running time of the algorithm).

Proving that the formulas we derive are also lower bounds (that is, that it’s not possible to find a function that grows more slowly) is beyond the scope of this book.

### Linear search

If we reason about the algorithm, our intuition immediately tells us that, in the worst case, we have to scan the whole array. But let’s look at the code as an exercise:[](/book/grokking-data-structures/chapter-4/)[](/book/grokking-data-structures/chapter-4/)

```
def linear_search(self, target):
    for i in range(self._size):        # repeat F(n) times
        if self._array[i] == target:       # cost: O(1)
            return i                       # cost: O(1)
        elif self._array[i] > target:      # cost: O(1)
            return None                    # cost: O(1)
    return None                        # cost: O(1)
```

The first instruction is a `for` loop: `for` loops are multipliers, meaning that the cost of the instructions inside the loop must be multiplied by the number of iterations. This `for` loop is repeated, let’s say, `F(n)` times (we still need to find the value of `F`), and the four instructions in the loop each take a constant amount of time. The last instruction, after the end of the loop, is executed only once and also takes constant time.

So the formula for the running time of linear search is `T(n) = F(n) * [O(1) + O(1) + O(1) + O(1)] + O(1) = F(n) * O(1) + O(1) = O(F(n)) + O(1) = O(F(n))`.

Now we need to find an expression for `F` (that is, we need to understand how many times the `for` loop is repeated). The `for` loop is set to repeat `n` times, but there are two return statements inside of the loop that cause the flow to break out of the loop. For example, if we find what we were looking for in the first element, we will exit the loop after just one iteration.

Conversely, with an unsuccessful search (when a search doesn’t find a match), the loop completes all `n` iterations.

How do we reconcile these opposite scenarios? We can do one of two things:

-  Consider the *worst-case scenario*: then, if we are unlucky, we need `O(n)` iterations.
-  Consider the *average* number of elements scanned before finding a match.

Would we get a better result by going with the average? Not necessarily: on average (without any prior knowledge of the array element distribution and the calls), we can say that it would take us `n/2` tries to find a match. But we can simplify constants in big-O notation, and `O(n/2) = O(n)`.

Therefore, we can say that for linear search, `T(n) = O(n):` unsurprisingly, *linear* search takes *linear time*!

Two important points:

-  By analyzing code, we are evaluating this implementation of an algorithm. Our analysis will be as good as the implementation itself.
-  Watch out for hidden costs. Take the `for` loop, for example: at each iteration, there is some extra cost to increment the loop variable and check the exit condition. In this case, it’s all constant-time operations, but it doesn’t have to be. And every time you call a method inside a loop, you have to remember to factor in its cost.

Finally, how about extra space? It’s easy to show that this method only takes a constant amount of memory.

### Binary search

[](/book/grokking-data-structures/chapter-4/)So much for linear search. Now let’s look at binary search, starting directly from its code:[](/book/grokking-data-structures/chapter-4/)[](/book/grokking-data-structures/chapter-4/)

```
def binary_search(self, target):
    left = 0                              # O(1)
    right = self._size - 1                # O(1)
    while left <= right:                  # O(1), G(n) iterations
        mid_index = (left + right) // 2       # O(1)
        mid_val = self._array[mid_index]      # O(1)
        if mid_val == target:                 # O(1)
            return mid_index                  # O(1)
        elif mid_val > target:                # O(1)
            right = mid_index - 1             # O(1)
        else: 
            left = mid_index + 1              # O(1)
    return None                           # O(1)
```

Each line of code executes in constant time, except for the `while` loop—once again, we must watch out for hidden costs, but luckily, there is none here.

The expression can be roughly simplified as `T(n) = O(1) + O(1) + G(n) * [O(1) + O(1) + O(1) + O(1) + O(1) + O(1)+ O(1)] + O(1) = O(1) + G(n) * O(1) = O(G(n)) + O(1) =` `O(G(n))`.

So, what we need now is to find an expression for `G(n),` a function that describes the number of iterations of the `while` loop.

The loop goes on until the left pointer goes beyond the right pointer. We begin by considering that `left` initially points to the first element of the array and `right` points to the last element: all the elements of the array are contained between the two pointers. It’s hard to anticipate how `left` and `right` will be updated because it depends on the actual values of the elements and of the target being searched, so the way they evolve is erratic. But we can make some considerations about their distance.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/04-09.png)

At first, as we know, their distance (the number of array elements in the range from `left` to `right` included) is `n`. After one comparison, if we don’t have a match, we discard more than half of the elements in the array. In other words, one of the two pointers will advance at least half of the distance. And their distance keeps halving until we either find a match or the distance becomes 0.

How many times can we halve this distance? As many times as we can divide `n` by 2 until it becomes 0 (assuming integer division). This number is exactly `log2(n)`, so we can only have `O(log(n))` iterations of the main loop of the method. Replacing `G(n)`with `O(log(n))` in the expression for `T(n)`, we can finally say that for binary search, `T(n) = O(log(n))`, which, as you should know by now, is great, much better than linear search, especially when we have to do a lot of searches! But remember, the catch is you can only perform binary search on a sorted array, while for linear search, there is no difference, in terms of asymptotic analysis, between sorted and unsorted array. In terms of memory, like *linear search*, we only use `O(1)` additional space.[](/book/grokking-data-structures/chapter-4/)

So, now you know how, in chapter 3, Mario’s mother won the search competition, and why it was a good idea to sort the cards beforehand!

This concludes our introduction to big-O notation and asymptotic analysis: we will use it a lot in the rest of the book.

Exercise

4.1 Using big-O notation and asymptotic analysis, derive the running time and extra memory used for `insert`, `delete`, and `traverse` on sorted arrays. How do they compare to the same methods on unsorted arrays?

## Recap

-  To evaluate the performance of an algorithm, we can use asymptotic analysis, which means finding out a formula, expressed in *big-O notation*, that describes the behavior of the algorithm on the *RAM model*.[](/book/grokking-data-structures/chapter-4/)
-  The *RAM model* is a simplified computational model of a generic computer that provides only a limited set of basic instructions, all of which take constant time.
-  *Big-O notation* is used to classify functions based on their asymptotic growth. We use these classes of functions to express how fast the running time or memory used by an algorithm grows as the input becomes larger.
-  Some of the most common classes of functions, the ones you will see more often in this book, are

-  *O(1)–constant*—Whenever a resource grows independently of *n* (for example, a basic instruction).
-  *O(log(n))–logarithmic*—Slow growth, like binary search.
-  *O(n)–linear*—A function that grows at the same rate as the input, like the number of comparisons you need in a linear search.
-  *O(n*log(n))–linearithmic*—We’ll see this order of growth for priority queues.
-  *O(n*2*)–quadratic*—Functions in this class grow too fast for resources to be manageable beyond about a million elements. An example is the number of pairs in an array.
-  *O(2n)–exponential*—Functions with exponential growth have huge values for *n* > 30 already. So if you want to compute all the subsets of an array, you should know that you can only do this on small arrays.
