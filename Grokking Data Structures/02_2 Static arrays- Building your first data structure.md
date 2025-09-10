# 2 Static arrays: Building your first data structure[](/book/grokking-data-structures/chapter-2/)

### In this chapter

- a few basic ideas concerning data structures
- introducing a fundamental data structure—arrays
- the difference between statically and dynamically sized arrays
- introducing typical operations that can be done on arrays
- using arrays to solve a problem

In this chapter, we’ll begin to talk about how data structures work and how to implement them. The chapter is special in that it will slowly introduce you to the process we are going to follow throughout the book as we talk about the technology we are introducing. However, it will also familiarize you with some basic concepts that you will need for the rest of the book.

## What is an array?

We will begin our journey to the land of data structures with *arrays*, specifically static arrays. Arrays organize data by holding a collection of elements and making them accessible through an index.[](/book/grokking-data-structures/chapter-2/)[](/book/grokking-data-structures/chapter-2/)[](/book/grokking-data-structures/chapter-2/)

But right now, the most important question I want you to be able to answer is, why arrays? Let me explain by using an example.

#### Memory and drawers

First, we need to take a step back and talk about how memory is organized. For the sake of simplicity, I like to think of memory as a modular shelf holding removable drawers.[](/book/grokking-data-structures/chapter-2/)[](/book/grokking-data-structures/chapter-2/)[](/book/grokking-data-structures/chapter-2/)[](/book/grokking-data-structures/chapter-2/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/02-01.png)

If the shelf structure is memory, then drawers are variables—a programming concept I assume you’re already familiar with. Think of memory as potential: if you want to use some memory, you can create variables, the drawers that can hold your data from which you can retrieve it.

The size of the shelf determines the maximum number of drawers. You can create variables (drawers) of different sizes, as long as they fit into the space of the shelf. You can also fill those drawers with data, and larger drawers can hold larger data types. For example, you’ll need a larger drawer for a floating-point value than for characters or (short) integers.[](/book/grokking-data-structures/chapter-2/)

### When do I need an array?

Meet Mario! He loves sweets, and he really loves chocolate. There is a drawer in his parents’ kitchen where Mario keeps his chocolate truffles, his favorites. Right now, Mario has five truffles left. A drawer is like a variable, a container for data. In this case, an integer variable named `drawer` would contain the value 5.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/02-02.png)

[](/book/grokking-data-structures/chapter-2/)To get from integer variables to arrays, let’s look at another example. December is coming, and Mario’s family prepares an Advent calendar for their children. The calendar is in the shape of a gingerbread house, with little drawers marked with numbers from 1 to 24.

If you are not familiar with an Advent calendar, it’s similar to *Advent of Code*, except that instead of coding problems, you get a sweet treat every day between the 1st and the 24th of December (funny how the analogy usually works the other way around for everyone except software engineers!). Each drawer of an Advent calendar holds a cookie, some chocolates, or other candy, and the kids can open each drawer only on the day corresponding to the drawer number.

Going back to our shelf analogy, suppose you reuse part of the big storage shelf for the Advent calendar. The 24 drawers could be created anywhere on the shelf: they don’t even have to be next to each other, and they don’t have to be in any particular order. But if we were to create these numbered drawers, we would want to put them in ascending order and next to each other. Otherwise, it would be hard to find them.

Similarly, if we wanted to model an advent calendar in software, we could create 24 little variables and call them `advent_drawer_1`, `advent_drawer_2`, and so on. No one would stop us from doing so (although, hopefully, *someone* would stop us before we get this mess into production!).

It would already be painful to create 24 different variables by hand, but what’s worse, every time we’d need to access one of the drawers in code, we’d have to use the correct variable name, so normally, in most programming languages, we’d have to know which variable we need at compile time (that is, when we write code).

Sometimes, however, we only get this information at *runtime*, when code is executed. For example, if we have a program that asks the user which drawer we need to check, we wouldn’t know in advance which variable we need because we only get the information through I/O as our program runs. And if this is not your first code rodeo, you are probably familiar with loops: Can you imagine what a mess it would be to go through all the drawers without a `for` loop? (Don’t worry if you can’t because we’ll see an example shortly.)

That’s where arrays come in. An array is a data structure that holds multiple entries accessed by index. We’ll define arrays properly in the next section, but for now, remember that, as a general rule of thumb, you use arrays when you need to store, iterate over, or manipulate a collection of values of (roughly) the same type without knowing much about how the individual values are correlated. (For cases when you have more information about the inner structure of your data and how the elements are related to each other, this book will introduce you to other data structures that will help you further.)

### Definitions[](/book/grokking-data-structures/chapter-2/): Statically vs. dynamically sized

[](/book/grokking-data-structures/chapter-2/)What is an array, then? Here is what our Advent calendar would look like as an array.[](/book/grokking-data-structures/chapter-2/)[](/book/grokking-data-structures/chapter-2/)

![An integer array for the Advent calendar](https://drek4537l1klr.cloudfront.net/larocca3/Figures/02-03.png)

Arrays aren’t limited to storing integers or numbers in general: they can store fractions, strings, and other types of objects. As an example, how about an array of candies?

![An integer array for candies](https://drek4537l1klr.cloudfront.net/larocca3/Figures/02-04.png)

In its simplest definition, an array is an indexed collection of data. Indexed means that an array stores a sequence of items (usually called *elements*), and you only can access them by their position (also known as their index). For example, in the Advent calendar, we can access the drawer indexed with 1 to get the treat for December 1st, but we can’t access the drawers by their content—for example, we can’t easily find the drawer with seven truffles, nor in the candies array can we just say, “Get the strawberry lollipop.”

Now that we are getting closer to formal definitions, we need to make a distinction because we can look at the definition of array from different angles.

If we focus on the functionality of arrays at a high, semi-abstract level, the array data structure has a few key characteristics:

-  It stores a collection of data.
-  Its elements can be accessed by index.
-  Elements don’t have to be accessed sequentially; that is, if I need the 10th element of an array, I can access it directly without having to read the 9 elements stored in the array before it.

These few points define an array at an abstract level. Technically, these points define an array as an *abstract data type*. Keep this term in mind as we will encounter it again in chapter 7.

From a different point of view, arrays are one of the core features of many programming languages. This is also where things get more concrete. Looking at arrays from this point of view, we have to deal with implementation details that vary depending on the programming language we choose.

Yet, many programming languages adhere to a few common characteristics when implementing arrays as a core language feature (we continue the previous list):

-  Arrays are allocated in memory as a single, uninterrupted block of memory with sequential locations, which is both memory and time efficient.
-  Arrays are restricted to storing data of the same type. This restriction also stems from the need for optimization because it allows the same memory to be allocated for each element in the array and the compiler/interpreter to quickly know the memory address of each element. We’ll talk about this in detail in the next section.
-  The size of arrays, that is, the number of elements contained in an array, must be decided when the array is created, and that size can’t be changed.

The last three points represent a *lower-level* definition that describes *static* (aka *statically sized*) arrays, a core feature of many programming languages such as C, C++, Java, and so on.[](/book/grokking-data-structures/chapter-2/)

In this chapter, we focus on static arrays. *Dynamic* (aka *dynamically sized*) arrays, whose size can change at runtime, are another variant of this data structure. We’ll learn more about dynamic arrays in chapter 5. Note that it’s also possible to relax the fourth point of the list and allow heterogeneous content for arrays, which means that you can mix different data types for the array’s elements: Python, the programming language we use in this book, natively provides *lists*, a dynamically sized kind of array that allows any data type for its elements.[](/book/grokking-data-structures/chapter-2/)

### [](/book/grokking-data-structures/chapter-2/)Values and indexes

[](/book/grokking-data-structures/chapter-2/)In the previous section, we learned that arrays are an indexed data structure. This means that an array associates an index to each of the elements it contains, and only through an index can we access the corresponding element.[](/book/grokking-data-structures/chapter-2/)[](/book/grokking-data-structures/chapter-2/)[](/book/grokking-data-structures/chapter-2/)

When we talked about static arrays, I pointed out that in many languages, arrays force all their elements to be of the same data type. This requirement is useful for several reasons.

First, as the next figure illustrates, it allows you to allocate the exact amount of memory needed for the array. Second, it makes it possible to quickly compute the memory address for each element because all elements will have the same size and thus be equally spaced, which makes computing the memory location of an element straightforward.

![Arrays implementation and memory addresses](https://drek4537l1klr.cloudfront.net/larocca3/Figures/02-05.png)

You may noticed that in the examples of the Advent calendar array shown in the previous section, the indexes of the array elements start at 1. In other words, each index corresponds nicely to one of the first 24 days of December. Some of you may have an eyebrow raised because you’re used to indexes starting at 0, so let’s talk about it.

While many programming languages start indexes at 0, some have array indexes starting at 1. A few of the most well-known examples are Julia, MATLAB, R, and Fortran.

Python is one of those languages that use zero-based indexing, and so we follow the convention throughout the book of having the indexes of arrays start at 0.[](/book/grokking-data-structures/chapter-2/)

Zero-based indexing, as you can imagine (and may already have experienced), forces developers to be careful when thinking about indexes, especially if they need to implement algorithms that access specific positions or when they need to be careful about staying within the bounds of the valid indexes. For example, the last element of a zero-based indexed array of size `n` will be at index `n-1`, and trying to access the element at index `n` will result in an error.[](/book/grokking-data-structures/chapter-2/)

![A zero-based-indexing version of the Advent calendar array](https://drek4537l1klr.cloudfront.net/larocca3/Figures/02-06.png)

### Initialization

[](/book/grokking-data-structures/chapter-2/)As discussed earlier, the rest of this chapter focuses on static arrays. One key point I briefly mentioned is that when you create a static array, you need to decide its size in advance. For example, if you need to store five elements in an array, you’ll need to allocate the memory for all those elements when you create the array. That is, by declaring an array, we create the structure that will hold five values of a certain type, which must also be decided at that moment.[](/book/grokking-data-structures/chapter-2/)[](/book/grokking-data-structures/chapter-2/)[](/book/grokking-data-structures/chapter-2/)

We are preparing the space to hold those elements, but what happens before we actually assign values to them?

To get started, there are two ways to create an array: we can just declare it, or (in most programming languages) we can *initialize* the array elements at the same time we declare it.

Initializing an array means assigning (valid) values to all of its elements. In this case, the compiler, while translating your code into a program that can run on your machine, simultaneously allocates memory for the array and fills it with the values we decide at compile time, before moving on to the next instruction.

What happens when you just declare the array without initializing it? Are its elements kept “empty”?

![An “empty” array: What values will we find? We just don’t know!](https://drek4537l1klr.cloudfront.net/larocca3/Figures/02-07.png)

There is no concept of empty, which means that when you declare a variable, the compiler must assign a value to it. In the case of arrays, all elements must be assigned a value.

The actual value depends on the programming language and the type of the array; for example, in Java, an array of integers will have all its elements set to `0` if it is created without initialization. Some programming languages have a special value to represent emptiness; for example, Python has the value `None`, and Java uses `null`. Note that these are special values that are explicitly assigned to the array elements.

The gist is that you must be careful when creating an array if you plan to access its elements without first assigning them. When in doubt, check the language specifications to understand what will actually happen.

## Arrays in Python

[](/book/grokking-data-structures/chapter-2/)OK, that’s enough theory. Let’s get a taste of arrays in action. Young Mario not only loves candy but also computer programming. He is learning Python and wants to keep track of his Advent calendar, so every morning, as soon as he opens his drawer for the day, he wants to update his digital version of the calendar. He also plans to update it every time he eats a piece of chocolate, so he can keep an eye on his little brother Ian, who is strongly suspected of stealing Mario’s treats on Halloween.[](/book/grokking-data-structures/chapter-2/)[](/book/grokking-data-structures/chapter-2/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/02-08.png)

Let’s help Mario build a simple application using arrays!

### Python lists vs. the array.array class

I already mentioned that Python offers the `list` class as its native array-like solution. *Python* lists are closer to dynamic arrays, and they also don’t have the limitation of holding data of the same type: you can create a list with numbers, strings, or other lists, all together.[](/book/grokking-data-structures/chapter-2/)[](/book/grokking-data-structures/chapter-2/)

Python *lists* are more powerful than static arrays: for example, they support dynamic resizing, while `array.array`, which comes with Python’s standard library, doesn’t. But you know how it is: with great power comes great responsibility—and a price to pay. In general, the price for supporting dynamic resizing is degraded performance and a slower data structure (we’ll talk more about this in chapter 4). To be clear, in many cases, you’ll be fine using *lists*, and you won’t notice the difference in your application. But if you are writing critical sections of your code, potential bottlenecks where performance is critical, then you may want to make sure to use the most performant option.

##### Tip

Just remember that optimization also has a cost (in terms of development time, maintenance, and clarity), so avoid optimizing too early or without real benefits. Before you decide to optimize some code, make sure you run it and identify the critical sections where optimization would make the most difference.

It’s important that you understand how static arrays work before we approach their dynamic counterpart in a later chapter. Unfortunately, Python doesn’t offer a native static array alternative. The closest we get is Python’s array module, which enforces type consistency but is still a dynamic array. A true static array can be found in the NumPy library, which is a math library fine-tuned to be efficient at vector computation. With `numpy.array`, you can create fixed-size arrays of doubles, still somewhat different from Java arrays.[](/book/grokking-data-structures/chapter-2/)

This is not the place to explore the pros and cons of all the possible solutions, although it’s important that you know they exist. Instead, to help you experiment with static arrays, we created a custom class based on `array.array`, which simulates how a static array works. (You can find this custom class in the book’s repo: [https://mng.bz/VxpG](https://mng.bz/VxpG).) At this point, you shouldn’t worry about the details of how we implement a static array. The important point is that once you import the class, you can create a new array of size `n` using the following code:[](/book/grokking-data-structures/chapter-2/)

```
from arrays.core import Array
a = Array(n)
```

Then you can access all elements of `a`, from index `0` to `n-1`, and assign them like a regular array. On the flipside, you can’t expand or shrink this array.

[](/book/grokking-data-structures/chapter-2/)By default, an array of *integers* is created. If you want to create an array (of five elements) of *floats*, you can use[](/book/grokking-data-structures/chapter-2/)[](/book/grokking-data-structures/chapter-2/)

```
b = Array(5, 'f')
```

Then, for example, you can run

```
print(b)
print(b[2])
b[3] = 3.1415
```

Note that all elements of the newly created array are initialized to `0` (or `0.0` for floats).

### Indexing

As mentioned previously, Python uses zero-based indexing for arrays, which means that for an array with *n* elements, the first element of the array is always at index `0`, and the last element is at index `n-1`.[](/book/grokking-data-structures/chapter-2/)

Sometimes zero-based indexing is a bit inconvenient, like in our Advent calendar example. We’ll find day 1 at index `0`, when it would have been more intuitive to find it at index `1`.

Sometimes, it’s more than inconvenient: you have to be careful about indices to avoid going past the end of an array. For an array of size `n`, `n-1` is the last valid index. Even with Python lists, while `-1` is a valid index (specifically, the index of the last element in the array), accessing `a[n]` will crash your application. Now you could be asking: What about `a[-n]`? And `a[n+1]`? Only one of them will work: Can you guess which one?

To avoid having to deal with this kind of Jedi mind trick, we have disabled negative indexes for our class of static arrays.

## Operations on arrays

Now that you know how to create an array, the next question is what to do with it.[](/book/grokking-data-structures/chapter-2/)[](/book/grokking-data-structures/chapter-2/)

[](/book/grokking-data-structures/chapter-2/)Initially, our array is an *empty* container—not in the sense that its elements are actually empty, but rather that the values assigned to the array’s cells are meaningless. Our helper class arbitrarily initializes every array element to 0, like it’s done in many programming languages.

However, the details of each programming language are not important now. The only assumption you need to make is that, unless or until you initialize the array, its data is *meaningless*.

You can fill the array however you like. You don’t have to follow any order when assigning new values to its elements, but here’s the caveat: you might want to keep track of which elements are *meaningful* to your application. I’ll go further: you definitely want to; I can’t think of an example where you wouldn’t.

In most cases, the order in which we store the elements won’t matter. If that’s the case, we can simply add the new elements at the first unused index in the array and keep the array left-justified: this means that if we add `k`≤`n` elements to our array, they will be at the indexes from `0` to `k-1`.

![An array with some elements assigned and some “empty” elements](https://drek4537l1klr.cloudfront.net/larocca3/Figures/02-09.png)

![A left-justified array](https://drek4537l1klr.cloudfront.net/larocca3/Figures/02-10.png)

With left-justified arrays, it becomes quite convenient to keep track of which elements are meaningful, and we only need to store the size of the filled chunk of the array.

##### Note

This is one[](/book/grokking-data-structures/chapter-2/) possible way to do it—in fact, one of many. If you choose to work with a left-justified array, it’s your responsibility to keep track of how many elements are currently stored in the array.

Now let’s see how to perform some basic operations on our (unsorted) array.

### A class for unsorted arrays

We could write a set of global functions that take a `core.Array` object as an argument and manipulate it. However, I’m not going to take this approach. I know we can have a cleaner implementation by writing an `UnsortedArray` class that wraps around and isolates (*encapsulates*) our array.[](/book/grokking-data-structures/chapter-2/)[](/book/grokking-data-structures/chapter-2/)[](/book/grokking-data-structures/chapter-2/)[](/book/grokking-data-structures/chapter-2/)

Why? There are many good reasons to prefer object-oriented programming over the imperative paradigm. If this debate is a new topic for you, I suggest you take some time to research and read about it.

One thing you may have already considered is that we need to keep track of the size of the filled part of the array. With a left-justified array, that’s enough to separate the part of the array that holds data from the empty part.

If we implement a class for the unsorted array, we can store its size in an attribute and update it as part of the operations on the array. Without wrapping our unsorted array in a class, we would have to store the size of the array in a global variable and pass that value to each of the functions that manipulate the unsorted array.

These methods, in turn, would have to trust the caller and still perform some sort of validation on the input. Anyone using these methods could, by accident or design, pass an incorrect value for the size of an array. Even worse, whoever owns the array has to keep the size variable in sync: for example, they have to remember to update the array after inserting and deleting values.

##### Encapsulation: A pillar of modern programming

The fact that anyone can change the variable with the size of the array is frighteningly prone to errors. Instead, we need to strive for something called *encapsulation*. Each instance of an array needs to have this value bundled with it and, ideally, only modifiable internally by the instance itself. (Python does not help us much here as it has no real private access to class attributes.)[](/book/grokking-data-structures/chapter-2/)[](/book/grokking-data-structures/chapter-2/)

So, we’re going to implement unsorted arrays as a class. You can find the full code on GitHub ([https://mng.bz/x2dX](https://mng.bz/x2dX)):

```
class UnsortedArray:
    def __init__(self, max_size, typecode = 'l'):
        self._array = Array(max_size, typecode)
        self._max_size = max_size
        self._size = 0
```

In the constructor, we keep the same signature as for our core static array helper class. In fact, we even use one of those static arrays internally to host the data.

Note that while we could inherit from `core.Array`, we instead create an instance of `core.Array` and assign it to an attribute of the object: we use composition with an instance of `core.Array`.

##### Tip

A general rule of thumb is to favor composition over inheritance: it gives you more flexibility in design.

If you are not familiar with composition, inheritance, and their tradeoffs, a good read would be Dane Hillard’s *Practices of the Python Pro* (Manning, 2019).

### Adding a new entry

For context, we create our array `arr = UnsortedArray(n)`, where `n` is the number of elements we allocate for the array (its maximum capacity). Let’s say we have already added `k` elements to the array. We can’t make any assumptions about the order of the elements, and we even don’t care about their order.[](/book/grokking-data-structures/chapter-2/)[](/book/grokking-data-structures/chapter-2/)

Under these assumptions, we can add the next entry of the array at index `k`, right after the last entry, that is, if there is room in the array! The first thing we have to do is check that `k` is a valid index. If it is, we can proceed with the assignment, remembering to increment `k`, the current size.

![Adding the fifth entry to an array with size n=9](https://drek4537l1klr.cloudfront.net/larocca3/Figures/02-11.png)

If the array is full, we raise an exception to alert the caller to the problem.

##### Tip

Don’t hide errors. You don’t necessarily have to use exceptions, but it’s important to let the client know, so they can discover and handle failure.

One advantage of exceptions over, for example, returning a special value on error, is that exceptions force the caller to care and check whether the operation succeeded, while return values can and will be ignored.

Here is how the code would look like as a method of our class:

```
def insert(self, new_entry):
    if self._size >= len(self._array):
        raise ValueError('The array is already full')
    else:
        self._array[self._size] = new_entry
        self._size += 1
```

### Removing an entry

Adding new elements to an unsorted array is pretty straightforward, right? Things get a little more interesting when we want to remove an existing entry. [](/book/grokking-data-structures/chapter-2/)

In the most common scenario, you’ll want to remove an entry somewhere in the middle of the array. Unfortunately, simply “clearing” the entry at the given index would leave a gap in the middle of the chunk of the array where we store our valid entries, breaking our assumption that the entries are left justified.

To fix this situation, in the abstract, we would have to shift all the entries to the right of the gap one position to the left. This would solve the problem, but it would also be a lot of work.

![Removing an entry leaves a gap; therefore, we need to shift all elements to the right of the gap.](https://drek4537l1klr.cloudfront.net/larocca3/Figures/02-12.png)

This is unfortunate: it would be much easier if we just had to remove the last entry of the array instead! We could just update the size of the array to ignore that last entry.

There is a special case, a data structure called a *stack*, which only allows you to remove its last entry. We’ll study stacks in chapter 8, but in the meantime, it turns out we are in luck after all: there is a way to manipulate unsorted arrays and get into the same scenario, where we only remove the last entry.

Since the array is unsorted, and we assumed that the order of the entries doesn’t matter, we can just swap the last entry and the one we want to remove, and then we can always remove the last entry!

![Swapping the entry to be removed with the rightmost one in the array, and then deleting it](https://drek4537l1klr.cloudfront.net/larocca3/Figures/02-13.png)

We have to take care of a few edge cases, especially checking whether the array is empty, but then things are much easier than we thought:

```
def delete(self, index):
    if self._size == 0:
        raise ValueError('Delete from an empty array') 
    elif index < 0 or index >= self._size:
        raise ValueError(f'Index {index} out of range.')
    else:
        self._array[index] = self._array[self._size-1] #1
        self._size -= 1                                #2
#1 “Smart swapping” by overwriting the deleted element (We don’t need to store the value that we are going to delete.)
#2 The last element will be outside the populated chunk (a word of caution: array loitering).
```

### Searching for a value

[](/book/grokking-data-structures/chapter-2/)Another important operation we want to be able to perform is searching: given a certain value, is it stored in the array, and at what index?[](/book/grokking-data-structures/chapter-2/) If we look more closely, we need to ask a few more questions. For example

-  What happens if there are multiple occurrences of the same value? Do we return the first occurrence, any occurrence, or all of them?
-  If the target value isn’t in the array, what do we return? One way would be to return `-1`, which works in many languages. However, in Python, `-1` is a valid index for lists, because you can use negative numbers to index elements from right to left. Therefore, returning `-1` could backfire and cause an error to go unnoticed if the caller doesn’t check the method output.

Let’s make the following assumptions: we will return the index of the first occurrence of the target entry found, or `None` (an invalid index) if not found.

So how do we do a search? Unfortunately, because the entries are stored without any ordering, we have no better way than to iterate through all items until we find a match. It’s not very efficient, but we don’t have any information that would allow us to do better:

```
def find(self, target):
    for index in range(0, self._size):
        if self._array[index] == target:
            return index
    return None                                  #1
#1 If it got to this point, it couldn’t find the target.
```

The search method can be used in conjunction with the `delete` method to remove elements by value. First, we find the index of the value we want to remove, and then we can call the delete method defined in the previous section.[](/book/grokking-data-structures/chapter-2/)[](/book/grokking-data-structures/chapter-2/)

### Traversal

Sometimes, we want to apply the same operation to all elements of a data structure, and the same goes for arrays. It could be printing them or squaring them. What we want is to traverse our array, going through all its elements (exactly once, in some order that depends on the data structure), and applying some method that we’ll take as an argument.[](/book/grokking-data-structures/chapter-2/)[](/book/grokking-data-structures/chapter-2/)

For more advanced data structures such as trees and graphs, this gets more complicated, as we’ll see. But for arrays, it only requires a `for` loop:

```
def traverse(self, callback):
    for index in range(self._size):
        callback(self._array[index])
```

We’ll assume that the operation we want to perform has some sort of side effect and that we don’t need to collect its output (otherwise, we’d be talking about a map operation).

Once defined in its simplest form, we can try calling it with the `print` method to get the gist of how it works:[](/book/grokking-data-structures/chapter-2/)

```
array.traverse(print)
```

## Arrays in action

Now that we have seen how arrays work, let’s see how we can make use of them.[](/book/grokking-data-structures/chapter-2/)

### Statistics

[](/book/grokking-data-structures/chapter-2/)Mario and Tony play this game that they invented where Tony picks the lower three numbers on a die, and Mario picks the top three. So, if the result of a dice roll is 1, 2, or 3, Tony wins, and if it’s 4, 5, or 6, Mario wins.[](/book/grokking-data-structures/chapter-2/)[](/book/grokking-data-structures/chapter-2/)

They take turns rolling the dice, betting their baseball cards on each roll. Whoever rolls the dice at any given time decides how many cards to bet, and the other one can double the bet.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/02-14.png)

After playing the game for a while, Mario has lost half of his card deck. He thinks that Tony is winning a bit too much and doesn’t understand why. When Mario tells his father about this game, Mario’s father suggests that Tony may be (unknowingly) using an unfair die: a die with certain numbers coming up more often than others.

With a fair die, he continues, over a large number of rolls, each of the six numbers should come up about one-sixth of the time. The more rolls you try, the closer the actual frequencies will be to each other.

Therefore, one way to prove that a die is unfair is to record the statistics of the results of many rolls and then check how the results are distributed. After breaking the ice with programming and arrays, Mario feels on a roll (pun intended), and he wants to use arrays to prove that Tony is cheating. So, his father helps him write a mobile application that Mario will use to record the results of the dice rolls.

![An array with six counters. Each time a die is thrown, the corresponding counter is incremented.](https://drek4537l1klr.cloudfront.net/larocca3/Figures/02-15.png)

Whenever Mario registers a dice roll on his phone, the application registers the result in array `counters` with six elements. All elements of `counters` are initialized to 0 when the app is first run. When the die comes up with, say, a 4, the app increments `counters[3]`. Remember that the possible values go from 1 to 6, but the array indexes go from 0 to 5 (in Python and many other languages), so if we want to update the number of times `k` has been drawn, we need to increment `counters[k-1]`.[](/book/grokking-data-structures/chapter-2/)

For this particular application, we don’t need to fill the array incrementally or keep track of meaningful entries: we know exactly how many entries to allocate from the start, and they can all be considered meaningful once initialized to zero. In other words, we populate the array at initialization. But, in the next example, we’ll see how to use what we’ve learned about incrementally filling arrays.

Once Tony and Mario have played enough, and Mario has recorded hundreds, even thousands of dice rolls, here comes the interesting part: How does he check that the values are those of a fair die? There are a few ways, but most of them would probably be way beyond the math of a primary school kid. So Mario’s father suggests to start by finding the maximum value in the array for the number that shows up more often. Let’s assume that there is a single maximum value or that, in case of a tie, we can indifferently return the one with the lowest index.

Then what Mario needs to code is a variation of array traversal. We go through all the elements, one by one, and check: Is this the one with the highest frequency?

Notice that instead of assuming that the maximum value in the array is nonnegative (which would be true in our case), we can write a safer, slightly more general method by initializing the variable `max_value` to the first element in the array and then start iterating from the second element.[](/book/grokking-data-structures/chapter-2/)[](/book/grokking-data-structures/chapter-2/)

This variant makes the code more robust (we don’t have to rely on the caller passing an array with nonnegative values) and more widely applicable.

For each element, we compare it to the currently stored value for `max_value`, and if the current element is greater, we update both the value and its index. In the end, we can just return the value found and the index where it is. But in our use case, we need to remember to add 1 to the index we get to have the most frequent value that came up when rolling Tony’s dice:

```
def max_in_array(array):
    if len(array) == 0:
        raise Exception('Max of an empty array')
    max_index = 0
    for index in range(1, len(array)):
        if array[index] > array[max_index]:
            max_index = index
    return max_index, array[max_index]
```

The second task Mario’s father gives him is to write a similar function that returns which face of the die comes up least often and how often that happened.

“Once we have these four values,” Mario’s father says, “we can check if Tony’s die is fair.”

```
max_in_array(counters)
> 1, 234
min_in_array(counters)
> 5, 107
```

They find that the most common result showing up is 2 (remember we get the index, which is 1 minus the actual value on the dice), and the least common is 6, with a large difference in their frequency.

“That’s weird,” says Mario. “What does that mean?”

“It means I’m going to call Tony’s parents. You should get your cards back.”

Exercises

2.1 Write the code for a function returning the minimum value in an array and its index. Hint: Can you adapt the function `max_in_array`?[](/book/grokking-data-structures/chapter-2/)[](/book/grokking-data-structures/chapter-2/)

2.2 Can you write a method returning both the max and min values at once? What’s the advantage of computing both within the same method?

### Collections

Another use case for arrays is to keep track of things as they appear. For example, Mario loves collecting baseball cards (or any kind of cards).[](/book/grokking-data-structures/chapter-2/)[](/book/grokking-data-structures/chapter-2/)

His parents gave him a special binder in which he can put his most valuable cards. The binder has a limited capacity, so Mario has to choose wisely which cards to put in it.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/02-16.png)

If we want to model the binder on a computer, an array is a good analogy. An unsorted array, like the one we saw in the previous section, is an even better analogy.

You can make the array as big as the size of the deck. The array would start out empty, meaning we would keep track of the cards we added to it—initially none.

As we buy or trade cards, we can add new entries to the array: we don’t care about the order. We can just have them in any order. Once the deck/array is full, we can remove some of the cards/entries to make room for the new memorabilia we want to keep in the deck. If we have an idea about which card we want to remove (maybe a Billy Ripken 1989 Fleer?), we can run a search on the whole array to find the index to free up.

Finally, to complete the analogy, if we want to write down some data for each card, such as the player’s name and age, then we should be thinking about running `traverse` with a function printing that information.

### Multidimensional arrays

Arrays are not limited to holding only numbers. Their entries can be characters, strings, objects, and other arrays. In particular, an array of arrays is a *multidimensional array*. Matrices are used in many fields such as graph theory, linear algebra, machine learning, and physics simulations. To learn more about multidimensional arrays, check out the book’s repo: [https://mng.bz/Adlx](https://mng.bz/Adlx).[](/book/grokking-data-structures/chapter-2/)[](/book/grokking-data-structures/chapter-2/)

## Recap[](/book/grokking-data-structures/chapter-2/)

-  Arrays are a way of storing a collection of elements and efficiently accessing them by position.
-  The term *array* usually serves as a synonym for a statically sized array (or static array for short), a collection of elements accessed by an index, where the number of elements is fixed for the entire lifetime of the collection.
-  Dynamically sized arrays are also possible. They behave like static arrays, except that the number of elements they contain can change.
-  Many programming languages, such as C or Java, offer static arrays as a built-in feature.
-  Arrays can be initialized at compile time. If a language allows you to skip initialization, then the initial value of the array’s elements depends on the language.
-  Arrays can be nested: you can create an array of arrays. As for static arrays, we call them multidimensional arrays or matrices.
-  If we don’t mind the order of its elements, adding and removing elements to and from an array can be done easily.
-  We can search all (generic) arrays by traversing them until we find what we are looking for.
-  It’s possible to use arrays for many applications. For example, counting items and computing statistics are perfect use cases for arrays.
