# 12 Dictionaries and hash tables: How to build and use associative arrays[](/book/grokking-data-structures/chapter-12/)[](/book/grokking-data-structures/chapter-12/)

### In this chapter

- discovering how the dictionary ADT improves indexing
- implementing a dictionary with the data structures we already know
- introducing a new data structure that is a game changer for dictionaries—the hash table
- how hashing works
- comparing chaining and open addressing, two strategies for resolving conflicts

So far, we have discussed data structures that allow us to retrieve stored data based on the position of elements. For arrays and linked lists, we can retrieve elements based on their position in the data structure. For stacks and queues, the next element that can be retrieved is at a specific position.

Now we introduce key-based data structures, sometimes called *associative arrays*. This chapter also introduces the dictionary, the epitome of key-based abstract data types, followed by a discussion of efficient implementation strategies for retrieving elements by key.[](/book/grokking-data-structures/chapter-12/)

## The dictionary problem

Our little friend Mario is getting really serious about collecting baseball cards. Do you know what his favorite part is? Trading cards with his friends![](/book/grokking-data-structures/chapter-12/)[](/book/grokking-data-structures/chapter-12/)[](/book/grokking-data-structures/chapter-12/)

Mario has a good memory, but now that he has hundreds of cards, it’s hard for him to remember all the cards he already owns and the ones he’s missing. This is especially so because when he trades cards with his friends, he only has a few moments to claim a card before someone else takes it. To stay ahead of the competition, Mario could use a mobile app that scans cards with the camera and checks in a split second whether that card is already in his collection and how many copies he has.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/12-01.png)

This, the core of the app (besides the UX and the object recognition), is what a dictionary does. It stores data by some key (in the case of baseball cards, we could use the player’s name or even the photo of the card) and lets you search data by key. In our example, keys can be associated with attributes such as the number of copies of a card you own or specific details about the card (team info, stats, and so on).

### Removing duplicates

Another common use case for dictionaries is to remove duplicates from a collection.[](/book/grokking-data-structures/chapter-12/)[](/book/grokking-data-structures/chapter-12/)

Suppose that we want to remove duplicates from an array. With what we have learned so far, we would normally sort the array and then find duplicates next to each other as we scan the sorted array. The main cost of this method comes from sorting, which has a running time of `O(n*log(N))`.

Let’s imagine we have this magical black box, a dictionary `D`, that can tell us if we have seen a certain object before. Then we can use it to filter out duplicates from a collection `C`.

The idea is that we can start with an empty dictionary and then go through the list of elements and add each item `c` simultaneously to `D` and a support collection `tmp`, unless we find out that `c` is already in the dictionary. If it is, we know we have a duplicate:

```
tmp = []
for c in C:
    if not c in D:
        D.add(c)
        tmp.append(c)
C = tmp
```

In Python, we can use a `set` for this purpose, which is a special kind of dictionary that stores only elements without associating a value to them. A similar example would be counting the number of occurrences of each element in a collection:

```
counters = {}
for c in C:
    counters[c] = counters.get(c, 0) + 1
```

This is a shorter syntax that’s allowed by Python, but it’s equivalent to checking whether the dictionary contains a key `c`, and then retrieving and incrementing its associated value or initializing the value associated with a new key to `1`.

Here is the question I expect you to ask: Is using a dictionary better than sorting when removing duplicates? Well, it mainly depends on how expensive it is to check a dictionary for an element and to add new entries to it. If either operation costs more than `O(log(n))`, then the dictionary version is more expensive. If both are less than logarithmic, then it’s a great deal. The performance of a dictionary depends on its implementation, and we’ll talk about that later in this chapter.

For now, let’s focus on the abstract data type—what we can do with a dictionary and not how we do it.

### The ADT for dictionaries

[](/book/grokking-data-structures/chapter-12/)When we describe the interface of a dictionary, we need to include the following three methods:[](/book/grokking-data-structures/chapter-12/)[](/book/grokking-data-structures/chapter-12/)

-  To insert a new value
-  To retrieve the value associated with a key, if any
-  To delete a value, or the value associated with a key

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/12-02.png)

In the most common definition of the dictionary interface, we store values to which we can associate keys. For some types of values, such as integers, the associated key is the value itself. Keys can be computed from values by applying a free function to them. In Python, the built-in `hash` function is the perfect candidate for the job. Or, if we are dealing with objects, an object would have its own method to return a key.[](/book/grokking-data-structures/chapter-12/)

With these assumptions, the `insert` method takes the full value to add to the dictionary, while `search` takes only the key (which is supposed to be smaller than the value) and retrieves the associated value. The `delete` method, however, can take either the key, the full value, or a reference to the full value to be deleted.[](/book/grokking-data-structures/chapter-12/)[](/book/grokking-data-structures/chapter-12/)[](/book/grokking-data-structures/chapter-12/)

A variant of this API is also possible, where we explicitly associate keys and values by passing two distinct values and storing them separately. For example, Python’s dictionary works this way.

Dictionaries can also provide more methods. For example, methods to retrieve the minimum and maximum keys stored or, given a key, to retrieve its predecessor and successor. These methods, however, are not part of the core interface for dictionaries, so you won’t always find them. The reason is that they are usually only provided with some implementations of the dictionary ADT for which they are easy to implement and fast to run.

## Data structures implementing a dictionary

[](/book/grokking-data-structures/chapter-12/)Which of the data structures we have already discussed can be used to implement a dictionary? Take a moment to think about this, and then let’s review the answer together.[](/book/grokking-data-structures/chapter-12/)[](/book/grokking-data-structures/chapter-12/)

So, we need to be able to insert new elements, but also to retrieve and delete any element stored in the dictionary. These requirements disqualify stacks, queues, and priority queues, because what they can retrieve and delete depends on the order of insertion or priority. So, we are left with arrays, linked lists, and binary search trees, all of which support the three operations. For all these options, we assume that we store both keys and values explicitly as pairs.

### Array

Insertion works right out of the box. We create a `(key, value)` pair and store it in the array using the plain `array.insert` method. What happens if we insert two pairs with the same key but different values? Normally, a dictionary allows only one value to be associated with each unique key. However, if we allow only one value per unique key, then we must tweak insertion to first check whether the key already exists. [](/book/grokking-data-structures/chapter-12/)[](/book/grokking-data-structures/chapter-12/)

To delete a key, we must first perform a special search to find a pair whose key matches the argument.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/12-03.png)

Similarly, when it comes to `search`, we just pass the key as an argument, and we must scan the array to find a pair whose first value matches the key.

We can use sorted or unsorted arrays. The former makes search fast but insertion linear time, and the latter allows constant-time insertion (if we don’t have to check for duplicates) but makes search slow.

### Linked List

Most of the principles discussed for arrays also apply to linked lists. We usually want to use doubly linked lists to make `delete` more efficient. Again, we can choose between sorted and unsorted lists, except that lists, if you remember, don’t support binary search, so we don’t really have an advantage using the sorted version.[](/book/grokking-data-structures/chapter-12/)

### Balanced Binary Search Tree

[](/book/grokking-data-structures/chapter-12/)We have just discovered balanced binary search trees in the previous chapter, but they are actually a good option in this case! All the operations we need to perform on a dictionary (including the accessory ones such as `max`) can be run in logarithmic time on a balanced tree. We must be as careful with duplicates as with the other two data structures, but this option guarantees the most balanced performance at the cost of some extra memory.[](/book/grokking-data-structures/chapter-12/)

### Summary

Table 12.1 lists the time each of the implementations discussed in this chapter takes for the main operations on dictionaries. I included a column for the time needed to create each data structure from a collection of `n` elements. This is a cost that needs to be taken into consideration, and it isn’t always the same as the cost of `n` insertions (remember `heapify` in chapter 10?).

##### Table 12.1 Running time for various implementations of the dictionary[(view table figure)](https://drek4537l1klr.cloudfront.net/larocca3/HighResolutionFigures/table_12-1.png)

|   | Insert | Delete | Search | Init with `n` elements |
| --- | --- | --- | --- | --- |
| Unsorted array | `O(1)` | `O(n)` | `O(n)` | `O(n)` |
| Sorted array | `O(n)` | `O(n)` | `O(log(n))` | `O(n*log(n))` |
| Unsorted doubly linked list | `O(1)` | `O(n)` | `O(n)` | `O(n)` |
| Sorted doubly linked list | `O(n)` | `O(n)` | `O(n)` | `O(n2)` |
| Balanced binary search tree | `O(log(n))` | `O(log(n))` | `O(log(n))` | `O(n*log(n))` |

In the analysis for table 12.1, I assumed that no checks on the keys to add are performed (otherwise the running time of `insert` can never be lower than the one of `search`) and that `delete` takes the key to be removed as an argument and as such needs to find it first.

As anticipated, balanced binary search trees have the best average performance considering all the operations.

## Hash tables

[](/book/grokking-data-structures/chapter-12/)The previous section summarized known alternatives and offered a recap of some key takeaways from the previous chapters. Now it’s time to take another step and think about something completely new that changes the rules of the game. This section describes a new data structure and discusses how it works when implementing the dictionary ADT. You think `O(log(n))` is good? Think again! You won’t believe what we’re about to accomplish.[](/book/grokking-data-structures/chapter-12/)[](/book/grokking-data-structures/chapter-12/)

### A new way of indexing

Arrays don’t guarantee great performance for dictionary operations because, with key-based indexing, we lose their main advantage: constant-time access by index. So, how could we exploit this huge advantage of arrays? Let’s go back to Mario and his baseball card collection. [](/book/grokking-data-structures/chapter-12/)

Let’s imagine that his collection of cards is static, with a fixed number of cards, and, to keep things simple, there are no duplicates. If there are `n` cards and the collection of cards never changes, we could in theory associate an integer between `0` and `n-1` to each card. Ring a bell? We could use this integer as the index of an array. But how can we associate this index with each card? For now, let’s imagine that we have an oracle function, a black box that spits out the right index when we feed it with a card.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/12-04.png)

We can ask this oracle, for example, what’s the index associated with Joe Di Maggio’s card, and the oracle answers `3`. So, we know that we can store the card in the array’s fourth cell (at index `3`), and we can use the same index to retrieve that card when we search for it.

Note that we would have to use the array in a different way than what we have discussed in chapter 2. The elements stored in the array wouldn’t be left justified, and their positions wouldn’t be determined by the order in which they were inserted.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/12-05.png)

This data structure is called a *direct-access table*. The stored elements would be scattered over the entire capacity of the array, and we might find empty cells between the elements. For this reason, we also need a way to keep track of which cells are used and which ones are empty. Nothing complicated: we can just store `None`, `null`, or whatever special value your programming language offers to encode the absence of a value.[](/book/grokking-data-structures/chapter-12/)[](/book/grokking-data-structures/chapter-12/)

Under certain conditions, which we’ll describe later in this section, we call this oracle function an indexing function.

Of course, what I’m describing here is a better-than-ideal situation, and we’ll soon discuss all its limitations. But if we could use this solution, its performance would be orders of magnitude better than anything we have discussed in the previous section. Once we have the index provided by the oracle function, all operations, such as searching, inserting, or deleting an element, would take constant time!

Is it too good to be true? Well yes, unfortunately, it is.

### The cost of indexing

First, there is an important detail that we have skipped: What’s the cost of the indexing function? To understand this, let’s further break down the operation of getting from a card to its index in the array.[](/book/grokking-data-structures/chapter-12/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/12-06.png)

With direct-access tables, the key of an object is its index in the array. But we still need to compute this key.

We start with the full object, a baseball card (or its digital representation), and extract from it a unique identifier. This ID may be an integer, in which case we are done. More often, however, the ID will be some sort of string, and we need an extra step to convert it to an integer. This is not difficult at all. One way would be to convert each letter to an integer by taking its ASCII or Unicode value and then adding up all the values. That’s what is shown in the figure. But this formula has a big problem: all anagrams of a sentence produce the same value because we don’t take into account the position of the letters. So, goodbye to unique IDs.

A better formula multiplies the value of each letter by a number determined by its position. For example,

```
id = 0
for c in 'Joe Di Maggio':
    id = id  + ord(c)
    id *= 256
```

This code treats an ASCII string as a base-256 number. Here we just convert the base-256 “number” `'Joe Di Maggio'` to a base-10 integer.

As you can see, to get from the element we want to store to its index in the array, there are intermediate steps that may require some extra cost, for example, iterating over a string. We can factor this out by assuming that the indexing function takes `O(k)` time, where `k` is some value that depends on the elements we want to store. This value `k` is usually independent of the number of elements we are storing, and if it can be bounded by a constant (for example, if all names are at most 50 characters long), then we can treat it as a constant-time operation. But don’t forget that there is a cost to extract keys.

### Problems with the ideal model

[](/book/grokking-data-structures/chapter-12/)The cost of the indexing function is just the tip of an iceberg. Our assumption that the collection of cards is static and immutable is a bigger problem. As you can imagine, that’s not future proof: new baseball cards are released every year. And if we replace baseball cards with books in an online bookstore, the situation gets even worse because the catalog changes at random times. [](/book/grokking-data-structures/chapter-12/)

To deal with this, we should create an array large enough to hold all possible keys for all possible products. If we compute the index from the names of the players interpreted as base-256 numbers, with `'Joe Di Maggio'`, we get an index in the order of `10``29`. Even if it was possible to create an array that large, we would have a huge array that would be left mostly empty. Let’s crunch some numbers to illustrate this. Suppose that all the possible name combinations for baseball cards are in the order of `2``64`, which is more or less 20 billion billions. The number of all-time Major League players is in the order of 20,000, and so, considering that a player can have a 20-year career, we can assume that less than 400,000 unique baseball cards have ever been printed.

Even if Marco managed to buy one copy of every baseball card ever printed, it would just fill less than 0.000000000002% of an array with a capacity of `2``64` elements, and around 0.009% of a more somber array allocated for `2``32` elements.

In other words, that’s a huge waste of memory. Using an array as a direct-access table is only possible in very particular situations, where we can put constraints on the size and composition of the set of elements to store.

However, there is some good in this idea. Maybe not everything has to go down the drain.

## Hashing

[](/book/grokking-data-structures/chapter-12/)We need to introduce something new to make it work. Our biggest problem with direct-access tables is that the indexing space is usually too large, and we can’t afford to allocate such large arrays.[](/book/grokking-data-structures/chapter-12/)[](/book/grokking-data-structures/chapter-12/)[](/book/grokking-data-structures/chapter-12/)

What we want is to allocate an array of size `m << |keys|`, a container that can store the number of elements we expect to have, not all possible elements that could ever exist. In our example, Marco wants to create an array of about a thousand elements to store his baseball cards, not one with a capacity of billions.

But if the capacity of the array we are using is less than the number of possible keys, then we can no longer use keys as indexes. We need to rethink the process of computing an index from an object, and we need to add an intermediate step that will always produce a valid index.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/12-07.png)

This step is what we call *hashing*, and the array we use to store elements indexed by hashing is called a *hash table*. Broadly speaking, hashing can describe the entire process of getting from an object to its index. In other words, a hash function can take the entire object as input and return a valid index.

But the crucial step where hashing takes place is to go from an arbitrary integer identifier to a valid index for our hash table.

### Hash functions

What are the properties of a hash function? And what makes a good hash function?[](/book/grokking-data-structures/chapter-12/)[](/book/grokking-data-structures/chapter-12/)[](/book/grokking-data-structures/chapter-12/)

These are key questions that we must answer to implement a hash table. The requirements for hash functions depend on the context, specifically the possible values to store and the size of the hash table:

-  The domain of a hash function must be the set of all possible keys. Of course, the possible values for the input depend on the context. But we can always convert the elements to be stored to integers, so we can say that the domain for a general-purpose hash function is the set of all integers.
-  A hash function must return a valid index. If our hash table has size `m`, then the output of the hash function associated with the table must be an integer between `0` and `m-1`.

Understanding what makes a good hash function is somewhat more complicated. In theory, a desirable property of hash functions is uniformity: each element should be equally likely to be hashed to any of the `m` slots in the hash table, regardless of where any other element has been or will be hashed. Unfortunately, uniformity is hard to obtain (elements are often not drawn independently) and hard to verify (because we usually don’t know the distribution of the keys).

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/12-08.png)

In these cases, the best we can do is design heuristics that perform well enough even without coming close to uniformity. A rule of thumb when designing these heuristics is to make sure that the output is independent of any patterns that might be present in the data.

### The division method

[](/book/grokking-data-structures/chapter-12/)In chapter 9, when we discussed circular queues, we introduced the concept of virtual address space and discussed how to wrap around the end of the queue when either the front or rear pointers exceed the end of the array.[](/book/grokking-data-structures/chapter-12/)[](/book/grokking-data-structures/chapter-12/)[](/book/grokking-data-structures/chapter-12/)

The division method works the same way. Given a hash table of size `m`, for any integer key `k`, we compute the index where we store `k` using a hash function `h(k) = k % m`, which is the remainder of the division of `k` by `m`.

The method is simple, but this apparent simplicity hides some challenges. For example, if we choose `m` to be a power of two, `m = 2`p for some positive integer `p`, we are in trouble. The problem is that the result `k % 2`p is exactly the `p` least significant bits of `k`. If we aren’t sure that the distribution of the least `p` bits of the keys is uniform, then we should be careful about the value we choose for `m`—the size of the table.

As a rule of thumb, whenever we use the division method, the best choice for `m` is a prime number that is not too close to a power of two. Finding prime numbers is not the easiest operation, so we might be open to alternatives.

### The multiplication method

If we want to have more freedom in choosing the size of the hash table, or if we don’t have a say in the choice, we can resort to a different method to compute the hash function. The multiplication method is an effective alternative, but it’s also more complex to compute.[](/book/grokking-data-structures/chapter-12/)[](/book/grokking-data-structures/chapter-12/)[](/book/grokking-data-structures/chapter-12/)[](/book/grokking-data-structures/chapter-12/)

The first thing we need to do is choose a real number, a constant `A`, to multiply by our input key `k`. The second step is to take the fractional part of this product, so we compute `(k*A) % 1`.

From this step, we can deduce that not all choices of `A` are equally good. For example, integers are a terrible choice because the resulting value would always be `0`.

The hard part is that the best value for `A` depends on the characteristics of the data to be hashed. Nevertheless, we can always follow Donald Knuth’s advice and use `A = (math.sqrt(5)-1)/2`, which should work well in most situations.

However, we are not done yet! We still need to multiply the resulting real number by `m`, the size of the table, and then take the integer part of the result (which will be an integer between `0` and `m - 1`).

The Python version of function `h` is

```
h = lambda k: math.floor(m * ((A * k) % 1))
```

As I mentioned, the choice of `m` is not critical for this method. Unlike the division method, a power of two is often used because it allows some optimization in the calculation of `h`.

This method has another desirable property, in comparison to the division method: keys that are close to each other end up on indexes that are far apart. This is important for spreading the load evenly across the table, and in the next section, we’ll discuss why this is critical.

There are, of course, other ways to compute our hash function, but these will do for our purposes, and now it’s time to address the “elephant in the table.”

## Conflict resolution

When I introduced hash tables, I told you that the capacity of the array we are using is less than the number of possible keys, and therefore, we can no longer use keys as indexes because a key could be larger than the largest index of the hash table.[](/book/grokking-data-structures/chapter-12/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/12-09.png)

There is another consequence of this size difference that I have glossed over—the hash function will map at least two keys to the same index. This follows from the so-called pigeonhole principle.

If we have five pigeons and four holes, there will be at least one hole with two pigeons. There might also be more than one hole with two pigeons, or holes with more than two pigeons.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/12-10.png)

[](/book/grokking-data-structures/chapter-12/)So, in a hash table, at some point, we will have two keys mapped to the same array cell. When this happens, we say we have a *conflict*. What can we do in these situations? How do we handle conflicts?

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/12-11.png)

There are two main strategies: *chaining* and *open addressing*. They are radically different approaches, with pros and cons. We discuss them in detail next.

### Chaining

The first way we can resolve a conflict is by allowing multiple items to be stored in the same cell. Of course, we can’t make an array cell larger and store more than one value in it. So, we need to be creative.[](/book/grokking-data-structures/chapter-12/)[](/book/grokking-data-structures/chapter-12/)

Instead of storing values directly in the array’s cells, each cell stores the head of a linked list, called a *hash chain*. When a new element `x` is hashed into the `i`-th cell, we retrieve the hash chain pointed to by that cell and insert `x` at its front. If we want to avoid duplicates, we can instead add new elements to the tail of the list, after traversing the entire list and checking that `x` is not there.[](/book/grokking-data-structures/chapter-12/)[](/book/grokking-data-structures/chapter-12/)

Which type of linked list should we use? As we discussed in chapter 5, doubly linked lists are the best option when we need to delete elements at random positions. However, we won’t have a reference to the node to be deleted, so the only difference with singly linked lists will be the complexity of the code to delete an element.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/12-12.png)

Since we already have both types of lists implemented, I used singly linked lists and the multiplication method for the hash function. To compute the index of a value, we apply the multiplication method to the key associated with the value. Internally, the class uses the built-in `hash` method by default to extract a key from any object. However, it is possible to customize the way we extract keys when the class is initialized:[](/book/grokking-data-structures/chapter-12/)

```
class HashTable:
    __A__ = Decimal((sqrt(5) - 1) / 2)                  #1
    def __init__(self, buckets, extract_key=hash):
        self._m = buckets
        self._data = [SinglyLinkedList() for _ in range(buckets)]
        self._extract_key = extract_key
    def _hash(self, key):
        return floor(self._m*((Decimal(key) * HashTable.__A__)%1))
#1 The constant for the multiplication method, defined as a class property
```

This is the bulk of the code we need to write to implement a hash table. Later, I’ll show you that its methods take only a couple of lines each because we can use the methods of class `SinglyLinkedList` to do the hard work.

So how efficient is a hash table with chaining? To understand this, we need to take a different approach to asymptotic analysis than we have done so far. Let’s assume we have a hash table with `m` buckets in which we have already stored `n` elements. We also assume that computing the hash of a key takes `O(1)` and that we don’t care about duplicates.

For our analysis, the key factor is the size of the hash chains. But if we don’t know the exact distribution of the keys in advance, we can only reason in terms of averages. We can hypothesize that, *on average*, each array cell will have `n/m` keys mapped to it.

[](/book/grokking-data-structures/chapter-12/)For insert, we are in luck: if we insert new elements at the front of the lists, then the `insert` method is particularly efficient, taking only constant time, regardless of the values of `m` and `n`:[](/book/grokking-data-structures/chapter-12/)

```
def insert(self, value):
    index = self._hash(self._extract_key(value))
    self._data[index].insert_in_front(value)
```

What about the `search` method? As we said, the average list has `n/m` elements, and we can only use linear search, so the average running time for `search` is `O(1 + n/m)`. However, if we are particularly unlucky (or not careful enough, as we’ll see), all the keys could be mapped to the same bucket. The worst-case running time for search is, therefore, `O(n)`:[](/book/grokking-data-structures/chapter-12/)

```
def _search(self, value):
    index = self._hash(key)
    value_matches_key = lambda v: self._extract_key(v) == key
    return self._data[index].search(value_matches_key)
```

In the code for `search`, we use a special search method for linked lists that takes a predicate as its only argument and returns the first element for which the predicate returns `True`. Remember, for this whole class to work, keys must be unique identifiers for values.

Deleting an element can take constant time on doubly linked lists, but only if we have a reference to the list node to be deleted. Otherwise, it takes the same time as searching.

Although it is common in the literature for the `delete` method to take a reference to where the value to be deleted is stored, my advice is to avoid this version because it’s neither clean nor safe. We can thus choose between deleting by key or deleting by value. For the sake of space, we only present the delete-by-value version, but both of them require a search to be performed first and take `O(1 + n/m)` on average:[](/book/grokking-data-structures/chapter-12/)

```
def delete(self, value):
    index = self._hash(self._extract_key(value))
    self._data[index].delete(value)
```

You can find the full code for class `HashTable` on GitHub: [https://mng.bz/jXRP](https://mng.bz/jXRP).[](/book/grokking-data-structures/chapter-12/)[](/book/grokking-data-structures/chapter-12/)

In general, iterating through all the elements of a hash table takes `O(n+m)` steps because we have to go through at least all the array cells, even if the linked lists they point to are empty.

What if we are interested in finding the minimum or maximum of the table? In that case, we must scan the whole table, so the running time is also `O(n+m)`. The same reasoning applies if we want to find the successor or predecessor of an element.

Table 12.2 summarizes the running time of the main methods of a hash table with chaining.

##### Table 12.2 Running time for a hash table implementation of the dictionary ADT (with duplicates)[(view table figure)](https://drek4537l1klr.cloudfront.net/larocca3/HighResolutionFigures/table_12-2.png)

|   | Insert | Delete | Search | Init with `n` elements |
| --- | --- | --- | --- | --- |
| Chaining (average) | `O(1)` | `O(1+n/m)` | `O(1+n/m)` | `O(m+n)` |
| Chaining (worst case) | `O(1)` | `O(n)` | `O(n)` | `O(m+n)` |

### Open addressing

Chaining isn’t the only way to resolve hashing conflicts. If we want to avoid composite data structures and store elements directly in the table, we can take a different approach. In open addressing, for each key, we can *probe* all `m` array cells, in some order, until we either find what we were looking for (an element or an empty cell), or we probed all cells. In a way, after a conflict we get a retry, a second chance (and a third chance, and so on).[](/book/grokking-data-structures/chapter-12/)[](/book/grokking-data-structures/chapter-12/)

To allow probing, we extend the hash function to take two arguments: the key to be hashed and the number of attempts already made. Let me explain how this works. Suppose we want to insert a new element, whose integer key is `714`. We compute `p(714,0)=3`, and then we check cell `3` and find that another element whose key is (say) `423` is already stored at index `3`.

But we don’t give up! Instead, we compute `p(714,1)=1` and probe another cell, at index `1`: unfortunately, it’s still not available. Let’s try again: `p(714,2) = 6`, and at index `6`, we find an empty cell. We can then store our element, and we are done.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/12-13.png)

Search works similarly, with one important caveat: the moment we are hashed to an empty cell, we know the search is unsuccessful. Otherwise, we check the value we found, and if it matches the target of the search, we are successful. Otherwise, we know we need to try again.

Of course, the hash function must be designed in such a way that, for any possible key `k`, `[p(k,i) for i in range(0,m)]` contains all possible indexes of the hash table. In other words, `<p(k,0), p(k,1),…,p(k,m-1)>` should be a permutation of the sequence <`0,…,m-1>` for any `k`.

Given a valid hash function `h`, two of the most commonly used options for the probing function are *linear probing*, with `p(k,i) = (h(k) + i) % m`, and *quadratic probing,* where `p(k,i) = (h(k) + a*i + b*i`2`) % m` for some constants `a`, `b`.[](/book/grokking-data-structures/chapter-12/)[](/book/grokking-data-structures/chapter-12/)[](/book/grokking-data-structures/chapter-12/)

### Problems with open addressing

Compared to chaining, open addressing has one main advantage—you don’t waste memory for the linked lists, and you need only minimal overhead for the array.[](/book/grokking-data-structures/chapter-12/)[](/book/grokking-data-structures/chapter-12/)

However, there are many drawbacks:

-  Chaining allows unlimited element storage, whereas open addressing uses a static array, fixing hash tables’ capacity at initialization (`n` ≤ `m`).
-  Linear and quadratic probing often produce element clusters, long chains that must be traversed during search and insertion, thus slowing down these operations. Quadratic probing works a little better but, for a given size of the table `m`, not all combinations of `a` and `b` are valid (the formula must return a valid permutation of the indexes).
-  With open addressing, deleting an element becomes complicated. If we just left a position empty, then we would break search. Going back to our example, if after inserting an element `x` at index `6` we deleted the element at index `1` leaving an empty cell, new searches for `x` might stop prematurely upon encountering the empty cell at index `1`.

We could use a special value for deleted elements, but then in a search, we would visit more elements than are actually stored, making it slow. Otherwise, we need to disable element removal, but then we fill up the table quickly, and we have to allocate a larger table even if not needed.

Long story short, if you need to delete items, you should use chaining.

### Risks with hashing

Hash tables offer a noticeable improvement over any other implementation of the dictionary ADT. It almost seems too good to be true. But you must remember that in data structures, as in life, there is no rose without a thorn (but many a thorn without a rose).[](/book/grokking-data-structures/chapter-12/)[](/book/grokking-data-structures/chapter-12/)[](/book/grokking-data-structures/chapter-12/)

The first thing to remember is that while `insert`, `search`, and `delete` can be maximally efficient with a hash table, other operations such as `maximum`, `minimum`, `successor`, and `predecessor` are faster when a BST is used instead.

However, there are bigger potential problems that can arise if we are not careful. A premise: the version of chaining I presented inserts elements at the front of linked lists and ignores duplicates for maximum efficiency. If we need to check for duplicates or if we want to keep the linked lists sorted for some reason, then insertion becomes linear time, as summarized in table 12.3.

##### Table 12.3 Running times for a hash table, when duplicates are not allowed[(view table figure)](https://drek4537l1klr.cloudfront.net/larocca3/HighResolutionFigures/table_12-3.png)

|   | Insert | Delete | Search | Init with `n` elements |
| --- | --- | --- | --- | --- |
| Chaining (average) | `O(1+n/m)` | `O(1+n/m)` | `O(1+n/m)` | `O(m+(n/m)2)` |
| Chaining (worst case) | `O(n)` | `O(n)` | `O(n)` | `O(m+n2)` |

There are situations where we can’t allow duplicates, and this exacerbates the problem we’ll describe next. In particular, note how building the table becomes a quadratic operation.

Half of the problem with hash tables is that, while the average performance is very good, the worst-case performance is on the side of bad (worse than an implementation using BSTs).

The other half of the problem is that, unless we take countermeasures, a client can deliberately make a hash table perform poorly. In particular, if the hash function is fixed and known (or if it’s possible to reverse engineer it), a client can find sequences of keys that all map to the same hash chain. This has been exploited for an attack that targets the hash table used by servers to store the HTTP parameters sent with POST requests.

Sending millions of form parameters, all known to hash to the same bucket in the table, slowed down the processing of a request to about a minute—a minute during which one processor core was busy with this task. You can imagine how sending hundreds or thousands of these requests could bring a server to a halt.

You can read more about the exploit at [https://lwn.net/Articles/474912/](https://lwn.net/Articles/474912/), and you can find the original paper explaining the vulnerability in detail at [https://mng.bz/WEK1](https://mng.bz/WEK1).

Note that the vulnerability wasn’t caused by the server code, but it was inherent in programming languages such as Perl, PHP, Python, Ruby, Java, and JavaScript. So, how can we prevent this attack?

This vulnerability stems from the deterministic nature of the hash function. Of course, the function must be deterministic for a given table, and it can’t change with every operation. Otherwise, the table would be broken. However, creating a hash function with a random element initialized along with the hash table can prevent the key bucket mapping from being exploited by attackers. This might not be enough as an attacker may still be able to guess the hash function used, but more complex solutions have been developed to address this risk.

For this reason, it’s so important that you understand how hash tables (and the other data structures in this book) work. Only by understanding their internals can you wisely choose the libraries you use, verify their specifics, and make sure they don’t have such vulnerabilities.

## Recap

-  The *dictionary* is an abstract data type for a container that stores elements that can later be searched (or deleted) by key. Dictionaries are used everywhere, from routers to key-value databases.[](/book/grokking-data-structures/chapter-12/)[](/book/grokking-data-structures/chapter-12/)
-  We can use several of the data structures discussed in this book to implement a dictionary ADT, but balanced binary search trees are the ones that guarantee the best performance over all operations.
-  An implementation using *hash tables* offers the best average performance for `insert`, `search`, and `delete`.[](/book/grokking-data-structures/chapter-12/)
-  A *direct-access table* is an array where each key (integer element) `k` is stored at index `k`, making search-by-value as fast as constant time. Non-integer elements are first converted to integers by extracting a unique ID. Direct-access tables are impractically large.[](/book/grokking-data-structures/chapter-12/)
-  A *hash table* is a special version of an array, where the index of an (integer) element is returned by a special function called a hash function. Hash tables can be much smaller than the range of values stored, making them more practical than direct-access tables.[](/book/grokking-data-structures/chapter-12/)
-  Since the range of keys of a hash table can be larger than the number of cells in the table, we can’t avoid *conflicts*, that is, two keys mapping to the same array cell.[](/book/grokking-data-structures/chapter-12/)
-  Conflicts can be resolved through *chaining* or *open addressing.**[](/book/grokking-data-structures/chapter-12/)*
-  In chaining, each table cell references a linked list where the elements are stored. These tables can grow indefinitely.[](/book/grokking-data-structures/chapter-12/)
-  In open addressing, a different permutation of the table’s indexes corresponds to each key. If on insert we find that the first index is already taken, then we try the second one, and so on—similarly with search.[](/book/grokking-data-structures/chapter-12/)
-  Hash tables with open addressing can’t store more elements than the number of cells. They make deleting elements complicated, and their performance degrades with the filling ratio. Thus, they are rarely used.[](/book/grokking-data-structures/chapter-12/)
-  The average running time of insertion, search, and deletion for hash tables is constant time. The worst-case performance, however, is linear time.[](/book/grokking-data-structures/chapter-12/)
-  If the hash function used is deterministic or easily guessed by an attacker, it is possible to design a sequence of keys that will cause the hash table to perform very poorly. This originated a vulnerability in servers written in several programming languages, including Perl, PHP, Python, Ruby, Java, and JavaScript.[](/book/grokking-data-structures/chapter-12/)[](/book/grokking-data-structures/chapter-12/)
