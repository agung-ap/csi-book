# 3 Sorted arrays: Searching faster, at a price

### In this chapter

- why keep an array sorted
- adjusting the insert and delete methods for sorted arrays
- the difference between linear search and binary search

In chapter 2, we introduced static arrays, and you learned how to use them as containers to hold elements without worrying about the element’s order. In this chapter, we take the next step: keeping the array elements sorted. There are good reasons for ordering arrays, such as domain requirements or to make some operations on the array faster. Let’s discuss an example that shows the tradeoffs and where we can get an advantage by keeping the element of an array in order.

## What’s the point of sorted arrays?

In the previous chapter, we looked at arrays as containers where the order of their entries doesn’t matter. But what if it does? Well, when the order does matter, it changes everything, including how we perform the basic operations we have implemented.[](/book/grokking-data-structures/chapter-3/)[](/book/grokking-data-structures/chapter-3/)

Before we look at how, let’s try to understand when a sorted array can be useful.

### The challenge of the search ninja

Our little friend Mario got excited about both coding and baseball cards. He started saving his lunch money to buy cards to play with his friends. He bought so many cards that it became difficult to carry and find them. His father bought him a binder to make them easier to carry around, but with hundreds of cards, even with the binder, it was still hard to find the ones he needed.[](/book/grokking-data-structures/chapter-3/)[](/book/grokking-data-structures/chapter-3/)

After seeing him struggle, Mario’s mother, a software engineer, suggested that he sort the cards by team and name.

Mario was skeptical: sorting all those cards seemed like a lot of work. He’d rather play now than spend the time. So, it was time for the big talk—the one about fast searching in sorted lists.

Mario’s mom explained that if he sorts the cards first, it will be much easier to find what he is looking for. Mario was still not convinced, so she challenged him: they will split all of Mario’s cards and take half each, and then each of them will randomly choose five cards for the other to find in their half. They can only search for one card at a time, so the next card they need to search for is given only after they find the previous one. Mario can start searching while his mom sorts her deck. Whoever finishes first wins.

Now the challenge begins, and Mario’s mom takes 5 minutes to calmly sort her half, while Mario finds his first card and giggles and taunts her for her efforts—Mario considers himself a search ninja: he is the fastest among his schoolmates.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/03-01.png)

But once Mario’s mom finishes sorting her cards, little does he know that, before Mario finds his third card, his mother has already completed her task. Mario is astonished: “How did you manage to be so fast?”

Good question! But you will have to wait until the next chapter to find out why her method was faster! In this chapter, we will instead focus on how to implement what Mario’s mom used to win the challenge.

## Implementing sorted arrays

In the rest of this chapter, we take a closer look at how the basic operations on a sorted array work and how to implement them in Python. As for unsorted arrays, I’m going to create a class, `SortedArray` this time, that internally handles all the details of a sorted array. You can find the full code on GitHub ([https://mng.bz/x24Y](https://mng.bz/x24Y)), but we also discuss the most important parts here.[](/book/grokking-data-structures/chapter-3/)[](/book/grokking-data-structures/chapter-3/)[](/book/grokking-data-structures/chapter-3/)

For sorted arrays, encapsulation becomes even more important because we need to guarantee another invariant: that the elements in the array are always sorted. As we discuss in the next section, the insert method looks very different for sorted arrays, and if this method were to operate on an array that is not sorted, it would behave erratically and almost certainly produce the wrong output.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/03-02.png)

This is also why we ideally don’t want to let clients directly assign the array’s entries and mess up their order. So, we only allow modifying the array through the `insert` and `delete` methods.

Let’s start with the class declaration and constructor:

```
12345class SortedArray():
    def __init__(self, max_size, typecode = 'l'):
        self._array = core.Array(max_size, typecode)
        self._max_size = max_size
        self._size = 0
```

In the constructor, we keep the same signature as our core static array helper class and, similarly to what we did for the `UnsortedArray` class, we internally compose with an instance of `core.Array`.[](/book/grokking-data-structures/chapter-3/)

Note that the behavior and meaning of some methods will be different between `SortedArray` and `core.Array`. First, compared to the `core.Array` class we provided, the meaning of “size of the array” is different: for the core type, it means the capacity of the array, but it has a different meaning here. We still need to set and remember the capacity of the array, but, like with the unsorted arrays, we want to keep track of how we fill that capacity as we add entries to the array.[](/book/grokking-data-structures/chapter-3/)

Therefore, the behavior we expect when we call `len(array`) is different in this case. For the core array, we always return the array capacity, but here we keep track of how many entries the array currently holds (keeping in mind that the maximum number of entries it can hold is given by the capacity of the underlying core array—a constant value returned by the `max_size` method).[](/book/grokking-data-structures/chapter-3/)

Now we have a *class* for our next data structure, the sorted array. However, a data structure is not really useful until we can perform operations on it. There are some basic operations that we usually want to perform on most data structures: *insert*, *delete*, *search*, and *traverse*.[](/book/grokking-data-structures/chapter-3/)[](/book/grokking-data-structures/chapter-3/)[](/book/grokking-data-structures/chapter-3/)[](/book/grokking-data-structures/chapter-3/)[](/book/grokking-data-structures/chapter-3/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/03-03.png)

Some data structures have special versions of some of these (for example, some only allow you to remove certain elements, as we will see when we discuss the *stack*), and some others may not support all operations. However, by and large, we’ll often implement these core operations.

### Insert

We start with insertion. When we need to add a new element to a sorted array, we must be more careful than with the unsorted version. In this case, the order does matter, and we can’t just append the new element to the end of our array. Instead, we need to find the right place to put our new entry, where it won’t break the order, and then fix the array. (I’ll soon explain how.) Because of the way arrays work, this is not as easy as we might hope.[](/book/grokking-data-structures/chapter-3/)[](/book/grokking-data-structures/chapter-3/)

Let’s see a concrete case: a sorted array with five elements, to which we want to add a new value, 3. (For the sake of simplicity, we avoid duplicates in this example, but the approach would be the same if we had duplicates.)

Once we find the right position for our new entry 3, we create a split of the old array, basically by dividing it into two parts: a left subarray `L` containing the elements smaller than 3 (namely, 1 and 2) and a right subarray `R` containing the entries larger than 3 (namely, 4, 5, and 6).

Theoretically, we would have to break the old array at the insertion point and then patch [1,2]–[3]–[4,5,6] together, connecting these three parts. Unfortunately, we can’t do this easily with arrays (it’s easier with linked lists, as we discuss later in the book).

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/03-04.png)

Since arrays must hold a contiguous region of memory, and their entries must be in order, from the lowest-index memory cell to higher indexes, we need to move all elements in the right partition `R` one entry to the right of the array.

There are a few ways to implement insertion, but we will go with this plan:

1.  Start with the last (rightmost) element in the array—let’s call it `X` (6 in our example)—and compare it to the new value `K` to insert (3).
1.  If the new value `K` is greater than or equal to `X`, then `K` must be inserted exactly to the right of that position. Otherwise (as in our example, where 3 < 6), we know that `X` will have to be moved to the right, so we might as well move it now. We choose our new `X` element (5) as the element to the left of `X` and go to the previous step. We repeat until we find an entry `X` that is less than or equal to `K` or until we reach the beginning of the array.
1.  Once we have found the right place, we can just assign `K` to that position without any other change because we already moved all the elements that needed to be moved to the left of this position.

![An example of insertion in a sorted array](https://drek4537l1klr.cloudfront.net/larocca3/Figures/03-05.png)

[](/book/grokking-data-structures/chapter-3/)These steps are the core of a sorting algorithm called *insertion sort*. It sorts an existing array *incrementally* by building a sorted subsequence used as a starting point and adding the elements of the array from left to right, one by one. Although there are faster sorting algorithms than insertion sort, it’s still a good choice whenever you need to build your sorted sequence incrementally, like in our case. If you are interested in learning more about sorting algorithms, I suggest reading *Grokking Algorithms*, *Second Edition* (Manning, 2023), especially chapters 2 to 4.[](/book/grokking-data-structures/chapter-3/)

Now that we know what we have to implement, we just need to write some *Python* code to do it:

```
def insert(self, value):
    if self._size >= self._max_size:
        raise ValueError(f'The array is already full, maximum size: {self._max_size}')
    for i in range(self._size, 0, -1):
        if self._array[i-1] <= value:          #1
            self._array[i] = value
            self._size += 1
            return
        else:
            self._array[i] = self._array[i-1]
    self._array[0] = value                     #2
    self._size += 1
#1 Found the spot in the middle of the array
#2 If it gets here, the right spot is at the beginning of the array.
```

As you can see, the only other thing we needed to add was a check at the beginning of the method to make sure we didn’t overflow the array’s capacity.

### Delete

The same considerations we made for inserting apply symmetrically to deleting existing elements. Suppose we need to delete the fourth element (the one at index 3) of an array with seven entries. We can’t leave a “hole” in the array, and we can’t use the same trick as for unsorted arrays, filling the deleted position with the last entry of the array.[](/book/grokking-data-structures/chapter-3/)[](/book/grokking-data-structures/chapter-3/)[](/book/grokking-data-structures/chapter-3/)

Instead, we need to shift all elements between the fifth and the seventh positions. We need to move these elements one position to the left so that the element previously at index 4 is moved to the cell at index 3, and so on.

##### Tip

The general rule is the following: shift all elements from the index after the deleted element to the end of the array.

Typically, with a sorted array, we are more interested in deleting a specific value than the element at a specific position. That is, it’s more common for the client to know the value they want to delete rather than its position.

![To remove an element from a sorted array, first we find its index, and then we shift all the elements to its right, overwriting the deleted element.](https://drek4537l1klr.cloudfront.net/larocca3/Figures/03-06.png)

How do we reconcile this need with what we have discussed so far and provide a user-friendly interface? All we need to do is find the position of the value we want to delete, and to do that, we can reuse a search method, which we’ll discuss in the next section. When implementing the `delete` (by value) method, we’ll assume that we have already defined a `search` method: for the purposes of this section, we don’t need to know the details of how it works, just that it returns the index of the value we’re looking for, or `None`, if it’s not available.[](/book/grokking-data-structures/chapter-3/)

Once we have the index we are looking for, we simply have to shift all elements to the right of the index one position to the left:

```
def delete(self, target):
    index = self.search(target)
    if index is None:
        raise ValueError(f'Unable to delete element {target}: the entry is not in the array')
    for i in range(index, self._size - 1):
        self._array[i] = self._array[i + 1]
    self._size -= 1
```

Exercise

3.1 What if we want to implement the delete-by-index method? Describe the abstract steps this algorithm should perform, and then implement it in Python, as part of the `SortedArray` class.

### Linear search

We implemented the delete-by-value method using search, so the next step feels kind of obvious: implementing the `search` method. This is also the point of this whole section on sorted arrays: we want to keep an array sorted so that we can search it faster.[](/book/grokking-data-structures/chapter-3/)[](/book/grokking-data-structures/chapter-3/)[](/book/grokking-data-structures/chapter-3/)[](/book/grokking-data-structures/chapter-3/)

One immediately apparent advantage of searching in a sorted array is that if we go through all the elements from left to right, we can stop an unsuccessful search (one that discovers that our target is not in the array) as soon as we find an entry larger than the target itself. Since the elements are sorted, the ones on the right can only be even larger, so there is no point in searching further:

```
def linear_search(self, target):
    for i in range(self._size):
        if self._array[i] == target:
            return i
        elif self._array[i] > target:
            return None
    return None
```

The advantage we get is already something, but it’s not a game changer. Sure, if we search for one of the smallest elements, we’ll be much faster, but if we look for one of the largest, we’ll still have to go through the whole array, more or less.

![An unsuccessful linear search in a sorted array. We need to scan every element from the beginning of the array until we find an element (9) that is larger than our target 8. Note that it took eight comparisons to find out that the searched value was not in the array.](https://drek4537l1klr.cloudfront.net/larocca3/Figures/03-07.png)

That begs the question: Is there a faster way to find the target value without traversing the entire array? Pause for a moment and think about what we could do differently.

Now, would you believe me if I told you that we can do much better?

### Binary search

You should believe me, because it turns out that we can. Although we will discuss the reasons more formally in the next chapter, by the end of this section, you will have a clear idea that binary search is a different game than linear search.[](/book/grokking-data-structures/chapter-3/)[](/book/grokking-data-structures/chapter-3/)[](/book/grokking-data-structures/chapter-3/)

![An unsuccessful binary search. After one comparison, we have ruled out more than half of the array. After two, more than 75% of it is excluded. In this example, by the third comparison, when we have only two elements where our target could be, we discover that the target is not in the array.](https://drek4537l1klr.cloudfront.net/larocca3/Figures/03-08.png)

Meanwhile, I’ll tell you how. We start by looking at the middle element of the array, and if we find our target, just like that, we’re done (and extremely lucky).

Otherwise, since the array is sorted, we can still squeeze some information out of the comparison. If our target is larger than the middle element `M`, then it can’t be to the left of it, right? Because the array is sorted, all the elements before the middle one are smaller than or equal to `M`. Similarly, if it’s smaller, it can’t be to the right of our current position. One way or another, we can focus our search on either half of the array and repeat the process as if we were dealing with a smaller array.

This method is called *binary search*. The implementation may not seem too complicated: we define two *guards*, the left and the right index, which delimit the subsection of the array where we know the target should be. Then, we bring these two guards closer at each step until we either find our target or find out that it’s not in the array:

```
def binary_search(self, target):
    left = 0                      #1
    right = self._size - 1 
    while left <= right:
        mid_index = (left + right) // 2
        mid_val = self._array[mid_index]
        if mid_val == target:
            return mid_index      #2
        elif mid_val > target:
            right = mid_index - 1 #3
        else: 
            left = mid_index + 1  #4
    return None                   #5
#1 Initially, the target can be in the whole array.
#2 We found the position of the target.
#3 The target can only be in the left half.
#4 The target can only be in the right half.
#5 If it gets here, the target is not in the array.
```

But trust me, this is one of those algorithms where the devil is in the details, and it’s hard to get it right the first time you write it. So, you better test it thoroughly, even if it’s the hundredth time you write it!

Why it’s called a binary search and why it’s more efficient than the `linear_search` method, you’ll find out in the next chapter. But for now, a word of caution: if your array contains duplicates, and you need to find the first (or last) occurrence of a target value, then this method will not work as is. You could (and will) adapt it to find the first occurrence, but that makes the logic of the method a little more complicated and the code a little less efficient. It is still faster than linear search, but obviously, if you return the first occurrence that you find, you’ll be even faster. So, you only worry about duplicates if you have a good reason to return the first occurrence, or if not, all occurrences are the same.[](/book/grokking-data-structures/chapter-3/)

And that concludes our discussion of static arrays. I know that I mentioned a fourth operation: traversal. As a reminder, traversal is the process of accessing each element in an array exactly once. Now you have all the elements to perform this operation yourself. Just remember that in the context of sorted arrays, traversal is typically performed in ascending order, from the smallest element to the largest.[](/book/grokking-data-structures/chapter-3/)

Exercises

3.2 Implement the traverse method for sorted arrays. Then use it to print all the elements in the array in an ascending sequence.[](/book/grokking-data-structures/chapter-3/)

3.3 Implement a version of binary search that, in case of duplicates, returns the first occurrence of a value. Be careful! We need to make sure that the new method is still as fast as the original version. Hint: Before doing this exercise, be sure to understand the difference in running time between binary and linear search. Reading chapter 4 first can help with this part.

## Recap

-  A *sorted array* is an array whose elements are kept in order as they change.[](/book/grokking-data-structures/chapter-3/)
-  To maintain the elements of an array in order, we need a different approach when inserting and deleting elements. These methods must preserve the order and therefore require more effort than their counterparts for unsorted arrays.
-  On an already sorted array, we can run *binary search*, a search algorithm that can find a match by looking at fewer elements than *linear search* (which simply scans all elements until it finds a match).[](/book/grokking-data-structures/chapter-3/)[](/book/grokking-data-structures/chapter-3/)
-  With sorted arrays, you have faster search, but you also have an extra cost to keep them sorted. Therefore, they should be preferred when there is a high read-to-write ratio (many more calls to the `binary_search` method than to `insert` and `delete`).
