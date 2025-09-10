# 6 Linked lists: A flexible dynamic collection

### In this chapter

- what linked lists can do better than arrays
- singly linked lists are the simplest version of linked lists
- doubly linked lists make it easier to read the list in both directions
- circular linked lists are good at handling periodic or cyclic data

In chapter 5, we discussed how static arrays have a weak spot when it comes to flexibility. *Dynamic arrays* may give us an illusion of flexibility, but, unfortunately, they are not a different (and flexible) data structure. They are just a strategy to resize static arrays as efficiently as possible. As discussed, the ability to resize arrays comes at a cost—slower insertion and deletion.[](/book/grokking-data-structures/chapter-6/)

This chapter discusses yet another way of having a data structure that can be resized whenever needed, namely, *linked lists.* We will look at both singly linked lists (the simplest version) and doubly linked lists, which trade memory for better performance on some operations. As with dynamic arrays, we will find that there is again a price to pay for this flexibility, only this time, it’s a different price.[](/book/grokking-data-structures/chapter-6/)

## Linked lists vs. arrays

It makes sense to start our discussion by making a comparison between linked lists and arrays. After all, we already have a data structure that can hold data and on which we can perform insert, delete, and search operations. Furthermore, we can traverse an array, that is, we can read its elements sequentially and perform some operation on each of the elements.[](/book/grokking-data-structures/chapter-6/)[](/book/grokking-data-structures/chapter-6/)[](/book/grokking-data-structures/chapter-6/)

But how do linked lists differ from arrays in terms of functionality and efficiency?

### Under the hood of a linked list

Let’s start by explaining how linked lists work.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/06-01.png)

If you remember our discussion in chapter 2, an array is usually implemented as a unique, contiguous block of memory, divided into cells of equal size, each of which contains one of the array elements.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/06-02.png)

Unlike arrays, a linked list is a complex modular structure, made of building blocks called *nodes*: each node contains an element, a single value, of the linked list. But that’s not all! Because the nodes are not in contiguous areas of memory, each must also contain a link to the next node, an extra piece of data that stores the location in the memory of the next node in the list.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/06-03.png)

This is the main difference between arrays and linked lists: in arrays, the location of each element is uniquely determined by the position of the first element and the elements’ size. Therefore, if we know the memory address of the first element of the array (stored in the variable for the array), we can compute the address of each element by knowing its index (that is, its position in the sequence of elements).

### Arrays and linked lists: A comparison

Let’s compare how the same values are stored in an array and a linked list.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/06-04.png)

[](/book/grokking-data-structures/chapter-6/)A linked list is a sequence of linked nodes, where each node is itself a small data structure that stores a single value and a link to the next node.

With linked lists, there are two main differences with respect to arrays:

-  Nodes are not stored contiguously but anywhere in the available memory address space.
-  Owing to the noncontiguous storage, the location of each node must be saved. This address is stored within the node itself, which means that each node of a linked list will take up more memory than the corresponding array element. As you can see, for each node, we have drawn an extra cell, allocated just after the value, which contains the link to the next node.

These differences have consequences, both positive and negative. On the positive side, as the nodes in a linked list don’t have to be allocated contiguously, we have more flexibility: we are not forced to allocate the whole list in advance, and we can add as many nodes as we want at any time, as long as there is enough memory to allocate a new node. The negative consequence, however, is that since the addresses of the nodes are not predetermined, there is no formula to compute where a node will be given its index in the sequence of list elements. This means that, compared to arrays, we lose the ability to access any element by its index and are instead forced to read the linked list from its beginning, one node at a time, getting the address of the next node, and so on, until we get to the element we want to access.

Let’s see a concrete example: What’s the difference between reading the third element from an array versus from a linked list?

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/06-05.png)

With an array, we can just access the element at index 2. It’s a single, constant-time operation (that is, it takes the same time, regardless of whether we access the third, the fourth, or the hundredth element).

In a linked list, we start by accessing the first element and follow its pointer to the second and then to the third element. This operation requires accessing a linear number of nodes, and that’s the main drawback of a linked list. But, of course, there are situations where this is too expensive and other situations where we won’t care (for example, if we know that we won’t be traversing the list much, while instead, we will always be accessing elements near the beginning).

## Singly[](/book/grokking-data-structures/chapter-6/) linked lists[](/book/grokking-data-structures/chapter-6/)[](/book/grokking-data-structures/chapter-6/)

[](/book/grokking-data-structures/chapter-6/)What we have described in the previous section is called a *singly linked list*—yes, that means there are two kinds of linked lists. A singly linked list is a linked list with a single link per node, pointing to the next element in the list.[](/book/grokking-data-structures/chapter-6/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/06-06.png)

The first element of a linked list is called its *head*, and the last element of the list is called its *tail*. In a singly linked list, the characteristic of a head node is that no other node points to it, so we need to store a link to the beginning (aka head) of the list somewhere in a variable.[](/book/grokking-data-structures/chapter-6/)[](/book/grokking-data-structures/chapter-6/)

In a linked list, each node only knows about its successor: it is indirectly linked to all nodes after it, but it is isolated from its own predecessors.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/06-07.png)

The characteristic of a tail node is that its next pointer doesn’t point to another node (in programming languages such as Java or C, it’s set to `null`). In this section, we are going to discuss an application of singly linked lists and then explore the characteristics and implementations of the same methods we defined on arrays: `insert`, `delete`, `search`, and `traverse`.[](/book/grokking-data-structures/chapter-6/)[](/book/grokking-data-structures/chapter-6/)[](/book/grokking-data-structures/chapter-6/)[](/book/grokking-data-structures/chapter-6/)

### Orders management

In chapter 5, we discussed a situation where static arrays would struggle and where we would need the flexibility of dynamic arrays. This example is in the section “Should we also shrink arrays?” and it features an e-commerce company and the process that keeps track of the customers’ orders. When a new order is received, it’s added to the end of the list, and orders are kept in the same sequence as received. When an order is fulfilled, it gets removed from the list.[](/book/grokking-data-structures/chapter-6/)[](/book/grokking-data-structures/chapter-6/)

If we were to store the orders in a linked list instead of an array, what would change?

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/06-08.png)

First and foremost, unlike arrays, linked lists wouldn’t have any empty space allocated. We would only allocate nodes as needed.

When we get a new order, we create a new node (*just in time allocation)*, and there is no need to allocate space in advance. When we remove a node, we won’t leave any “hole,” that is, no empty space will be created (we will see this in detail in the next sections). Of course, each node would need some space to store its value (the order, with items, address, and creation date) and also some extra space for the next link.

It seems that linked lists are perfect for our order management task. But are they too good to be true?

### Implementing singly linked lists

Linked lists are different from any data structure we have seen so far. Arrays are just a contiguous area of memory divided into cells of equal size, so there is little overhead in implementing them (at least their simpler versions).

The implementation of linked lists is, however, less straightforward. I like to think of linked lists as two-tier data structures.

There is an external data structure that implements the linked list itself and provides an API for clients to interact with the list and perform our usual operations on it.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/06-09.png)

This is like a shell, a wrapper around the linked list. But internally, inside this wrapper, we need to use a different data structure—the nodes that we have described earlier in the chapter. They can be thought of as data structures that store a single value (to be picky, two values: a user-facing value, the data stored by the client, and an internal value, the link to the next node).

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/06-10.png)

A linked list then consists of nodes sequentially ordered by their links. In addition, it includes some helper attributes, such as a reference to the first node in the list, and some associated methods. Therefore, to implement a linked list, we must first implement a class for the nodes.

As always, the full code for this chapter is also stored in the book’s repo on GitHub: [https://mng.bz/rVRD](https://mng.bz/rVRD). This is the Python code for the `Node` class:[](/book/grokking-data-structures/chapter-6/)

```
class Node:
    def __init__(self, data, next_node = None):
        self._data = data
        self._next = next_node

    def data(self):
        return self._data

    def next(self):
        return self._next

    def has_next(self):
        return self._next is not None

    def append(self, next_node):
        self._next = next_node
```

This class is minimal, with only the attributes for the data and the link to the next node, two public methods to return their values, and two methods to set the link to the next node and check whether there is a link to the next node. That’s all we need for the internal implementation of a singly linked list.

##### Tip

The `Node` class can also be kept hidden from clients by implementing it as a nested class within the list class. This is because users shouldn’t directly manipulate the list’s nodes.[](/book/grokking-data-structures/chapter-6/)

The wrapper class for the list, the one class with which all clients will interact, is also minimal in its initialization section:

```
class SinglyLinkedList:
    def __init__(self):
        self._head = None
```

Yes, that’s it! All we need to do is initialize the internal attribute pointing to the head of the list (that is, the first node in the list) to `None`: when `head` is set to `None`, it means that the list is empty.

If you look closely, you will notice two important differences from the constructors for the array classes we have implemented in the previous chapter:

-  We don’t need to specify a size for the list; we don’t need to allocate any space in advance, and the list can grow dynamically.
-  There is no argument for restricting the type of data stored in nodes. That’s because, in a loosely typed language such as Python, it doesn’t make sense to restrict the type of the values of a container like a list (for arrays, it might make sense to achieve higher efficiency, as we explained in chapter 2). Of course, in strongly typed languages such as Java or C++*,* it makes sense to force the list to contain elements of the same type, and it would still be possible to restrict the type of data stored using Python type hints if there is a strong, context-related reason to do so.

Don’t be fooled, though. The complexity in the `SinglyLinkedList` class is all in its methods.[](/book/grokking-data-structures/chapter-6/)[](/book/grokking-data-structures/chapter-6/)

### Insert

The first operation that we usually want to implement on a data structure is insertion. But how do we do it for an unsorted, singly linked list?[](/book/grokking-data-structures/chapter-6/)

#### Insert at the end of the list

If you remember from chapter 2, for unsorted arrays, we added new elements toward the end of the array, after the last element previously stored in the array. We can do the same for unsorted lists as well. We don’t care about the order of the elements, and we can just append new elements to the end of the list.[](/book/grokking-data-structures/chapter-6/)

To add a new element to the end of the list, we need to traverse the entire list, find its tail, and then add a new `Node` to it (which will be the new tail).

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/06-11.png)

This works and keeps the elements in the same order as they were inserted. But can you see a problem here? We must traverse the whole list each time we insert a new element: this means that this method takes linear time, `O(n)` for a list of `n` elements. Another way to look at this is that inserting `n` elements into an empty list would take quadratic time:

```
def insert_to_back(self, data):
    current = self._head                       #1
    if current is None:
        self._head = Node(data)                #2
    else:
        while current.next() is not None:
            current = current.next()           #3
        current.append(Node(data))             #4
#1 Start from the head of the list.
#2 In case the list is empty, just create a new head.
#3 Traverse the whole list, until the last element (which, by definition, has no successor).
#4 Add a new tail to the list, with the value to be inserted.
```

[](/book/grokking-data-structures/chapter-6/)With arrays, we can access their last element (or any element) in constant time but, unfortunately, this is no longer true for lists.

##### Note

With linked lists, we could theoretically store a link to the list’s tail, and that would make insertion at the end easier; however, with singly linked lists, updating the link to the tail when we delete an element could be expensive.

So, we are stuck with linear-time insertion, and that’s far from ideal: Can we do better? Of course we can!

#### Insert, smarter (in front)

Although it makes sense to insert elements at the end of the list, we are working with unsorted lists, and we don’t care about the order of the elements. Instead, how about inserting a new element at the beginning of the list?[](/book/grokking-data-structures/chapter-6/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/06-12.png)

Not only is this possible, but it apparently works beautifully:

```
def insert_in_front(self, data):
    old_head = self._head
    self._head = Node(data, old_head)
```

There is a reason why inserting elements at the beginning of the list is fast, while inserting at the end is not. It’s because of the asymmetry in nodes, where we only store the link to the node’s successor but not its predecessor. Therefore, we can only traverse the list in a single direction, and, as we’ll soon see, any change, insertion, or deletion is expensive unless made at the beginning of the list.

By growing the list from its head, we create a new list made up of the newly created node, followed by the old list. And this is as efficient as it gets: it takes only constant time, `O(1).`

### Search

[](/book/grokking-data-structures/chapter-6/)Now that we can populate our linked list with orders, we can start searching it to find any order we have added. The `search` method is a straightforward linear search: we can’t do any better than traverse the entire list until we find what we were looking for or reach the end of the list trying.[](/book/grokking-data-structures/chapter-6/)[](/book/grokking-data-structures/chapter-6/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/06-13.png)

This implementation of the `search` method, which of course takes linear time and constant extra space, returns the node where the matching data is stored:

```
def _search(self, target):
    current = self._head
    while current is not None:
        if current.data() == target:
            return current
        current = current.next()
    return None
```

You may have noticed that the name of the method has an underscore in front of it—I implemented it as a private method. That’s because this implementation should only be used internally. Why is that? There is more than one reason, actually: as a feature, it wouldn’t be that useful, and design-wise, we shouldn’t return `Node` objects.

First, feature-wise: there is no reason to return the node found to a client. With arrays, we return the index of the found value, but with linked lists, a user would not get any additional information from the node because they already have the data stored by the node (in this implementation, we compare the whole `data` field with the `target` value passed as an argument).

There are cases where we store composite data on the nodes, and we may want to perform the search on some fields. For example, in our order management application, we store the order itself, a composite field made of (presumably) order ID, product list, creation date, some sort of status for the order, and details about the buyer and the shipment. We could search by order ID, or by shipping address, and return the whole order.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/06-14.png)

[](/book/grokking-data-structures/chapter-6/)Even if we do so, we definitely don’t want to return a reference to the list node: we shouldn’t share the `Node` class with clients. The internal implementation of the linked list should be opaque to the users, who should rely only on the external interface provided by the linked list. By ensuring users rely only on the external interface, users can seamlessly switch without breaking any code if you later write an improved linked list implementation. By making the `_search` method private, we could also make the `Node` class private to `SinglyLinkedList`.[](/book/grokking-data-structures/chapter-6/)[](/book/grokking-data-structures/chapter-6/)[](/book/grokking-data-structures/chapter-6/)

##### TIP

Following the principle of least authority, we shouldn’t give any client a reference to a list’s `Node`: if a third party has a reference to an internal node, which is mutable, they can make changes and break the list.

This doesn’t mean that search is useless. In the order management example, we can return a copy of the order’s data, without providing any reference to the list nodes. By changing the returned value, we can implement a `contains` method, which tells the caller only whether the data is stored in the list. And we can always use the `_search` method internally, calling it from other methods of the same class.[](/book/grokking-data-structures/chapter-6/)[](/book/grokking-data-structures/chapter-6/)

### Delete

When it comes to the `delete` method, we don’t have the dilemma we had with arrays. We want to delete elements by value because, as we discussed, list elements are accessed sequentially: for example, we can’t directly access the third element in the list without accessing the first two elements.[](/book/grokking-data-structures/chapter-6/)

On the bright side, however, deleting an element in a list is much easier. All we have to do is bypass the element we want to remove, that is, make sure to update its predecessor’s link, so that it points to the successor of the element we want to delete.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/06-15.png)

Easy, right? Not so fast!

First, there are two edge cases to consider:

1.  [](/book/grokking-data-structures/chapter-6/)If you delete the last node, then you have to make the previous node the new tail (in our implementation, its link is set to `None`).[](/book/grokking-data-structures/chapter-6/)
1.  If you delete the first node, the head of the list, then there is no predecessor! In this case, we just have to update the list’s `head` pointer.[](/book/grokking-data-structures/chapter-6/)

Once we have clarified the edge cases, you might think that we should reuse the search method to find the node to remove, and then perform the change. The sad news is, this won’t work.

In the section about the insert method, I mentioned how nodes in singly linked lists are asymmetric. Because we only store the next pointer in each node, we can go from one node to its successor in the list, but we can’t go to its predecessor.

Basically, when we have a link to a node `N` in the list, it’s as if we can only see the section of the list from `N` onward, while all the nodes before it are invisible to us.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/06-16.png)

So, we can’t use `_search` to find the node that stores the value we need to delete because we wouldn’t be able to update the `next` link on the node’s predecessor.[](/book/grokking-data-structures/chapter-6/)

However, we can still use what we have in the implementation for the search method: we just need to traverse the list and keep a link to the node before the one we are visiting. Once we find our target, we can use that link to access the predecessor of the node we want to delete:

```
def delete(self, target):
    current = self._head
    previous = None
    while current is not None:
        if current.data() == target:
            if previous is None:
                self._head = current.next()                                    #1
            else:
                previous.append(current.next())                                #2
            return
        previous = current
        current = current.next()
    raise ValueError(f'No element with value {target} was found in the list.') #3
#1 Edge case: delete the head of the list.
#2 Average case: a node in the middle of the list (or the tail as well)
#3 If it gets here, target is not in the list.
```

[](/book/grokking-data-structures/chapter-6/)What’s the running time of the `delete` method? We have to search the list first, so it’s `O(n)`. As we have discussed, having a pointer to the node to delete wouldn’t help us, unfortunately, because we would still have to traverse the list up to its predecessor, to update it. We will see later in this chapter how we could address this problem.

Finally, note that this method only requires a constant amount of additional memory.

### Delete from the front of the list

Deleting the head of the list can be considered a special case. There are contexts where we do not need to delete elements at any position, but only at the beginning of the list—we will find the perfect example when we discuss the stack in chapter 8. As we discussed when talking about insertion, operations that only change the head of the list are cheap, and indeed, deleting the first node in the list would be a constant-time operation.

This concludes our section on singly linked lists. Now you have everything you need to implement a usable version of the list! The code on our GitHub repository ([https://mng.bz/Vx00](https://mng.bz/Vx00)) also includes a few more helper methods that can be useful in many situations.

Exercises

6.1 Implement a `delete_from_front` method that removes and returns the head of the list. Hint: This is an edge case in the general-purpose delete method.[](/book/grokking-data-structures/chapter-6/)

6.2 Implement the traverse method for singly linked lists. The method should take a function that can be applied to the data stored in the list and return a Python list with the result of applying such a function.

## Sorted linked lists

We have implemented a singly linked list where the order of its elements doesn’t matter. What changes if the order does matter? For instance, what if we want to store elements in our order management system not in the order in which they are received, but (for example) sorted by user, or by ID (in case IDs are not auto-incremented, but randomly assigned)?[](/book/grokking-data-structures/chapter-6/)[](/book/grokking-data-structures/chapter-6/)[](/book/grokking-data-structures/chapter-6/)

![A list of orders sorted by name of the product (descending).](https://drek4537l1klr.cloudfront.net/larocca3/Figures/06-17.png)

In this section, we will briefly see what we need to change to keep the elements of a singly linked list sorted.

### Insert in the middle

If we need to keep our list of orders sorted, then we can’t just insert new nodes at the beginning (or at the end) of the list. We are forced to traverse the list to find the right place to insert the new value—more specifically, we need to find the node after which the new value should be added and then update the links in the list (and in the newly created node) to include the node that stores the new value.[](/book/grokking-data-structures/chapter-6/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/06-18.png)

If we assume for the sake of simplicity that the node’s data is directly comparable (that is, we can use the `<` operator on these data), the implementation of this new insertion method is very similar to the traversal we have in `delete`:

```
def insert_in_sorted_list(self, new_data):
    current = self._head
    previous = None
    while current is not None:
        if current.data() >= new_data:
            if previous is None:
                self._head = Node(new_data, current)     #1
            else:
                previous.append(Node(new_data, current)) #2
            return
        previous = current
        current = current.next()
    if previous is None:
        self._head = Node(new_data)                      #3
    else:
        previous.append(Node(new_data, None))            #4
#1 Edge case: insert at the beginning of the list.
#2 General case: add the new node between <kbd>previous</kbd> and <kbd>current</kbd>.
#3 Edge case: empty list
#4 Edge case: insert at the end of the list.
```

As you can imagine, this version of the insertion method only works if the list is sorted and its running time is `O(n)`—we lose constant-time insertion.

Exercise

6.3 Can you think of a way to write the `insert_in_sorted_list` method by reusing the `insert_in_front` and `delete` methods and without making any other explicit changes to the nodes? What would be the running time of this method?[](/book/grokking-data-structures/chapter-6/)[](/book/grokking-data-structures/chapter-6/)[](/book/grokking-data-structures/chapter-6/)[](/book/grokking-data-structures/chapter-6/)

### Can we improve search?

In chapter 3, we discussed sorted arrays, and we learned that we have to give up constant-time insertion to keep the elements sorted. We also learned that, in exchange, we get to use *binary search*, a more efficient search method, which only needs to look at `O(log(n))` elements in the worst case, much better than *linear search*, whose running time is `O(n)`.[](/book/grokking-data-structures/chapter-6/)[](/book/grokking-data-structures/chapter-6/)[](/book/grokking-data-structures/chapter-6/)

So, maybe we get the same improvement for linked lists? Take a minute to think about it before you read the answer.

The main advantage of binary search is that we can pick an element from the middle of the array, and then (if we don’t find a match) we can ignore half of the remaining elements. With linked lists, to get to the middle element of the list, we would have to traverse all the elements before it. And then, to find the middle element of the half of the list we kept, we would have to traverse half of those elements (even if we kept the left half of the list, we would still need to traverse those elements again). This would make the running time worse than linear search.

The key to binary search is the constant-time access to any element in the array by its index. Since lists lack this feature, generally, they can’t be more efficient than linear search.

That means that `insert` was the only method we had to change to keep the list’s elements sorted and also that we don’t get any advantage unless, for example, we want to have fast access to the smallest element, which would always be at the head of the list. Anyway, in some contexts, you might be required to keep your list sorted, so this variant might come in handy.

## Doubly linked lists

We have learned that singly linked lists (SLL) do offer greater flexibility than arrays, but they have important drawbacks. First and foremost, we are forced to read the list’s elements sequentially, while with arrays, we can directly access any index in constant time. This is an intrinsic limitation of linked lists, and there is nothing we can do: it’s the price we have to pay to have a data structure that can be allocated “just in time” when we need it.[](/book/grokking-data-structures/chapter-6/)[](/book/grokking-data-structures/chapter-6/)[](/book/grokking-data-structures/chapter-6/)

We can’t get general-purpose constant-time access with linked lists, but doubly linked lists address another quirk specific to singly linked nodes: their asymmetric nature. SLL nodes only maintain a link to their successor, which makes some operations on a list more complicated and slower.

In this section, we discuss how we can overcome this limitation and at what cost.

### Twice as many links, twice as much fun?

You might have already figured this out: a doubly linked list (DLL) is a linked list whose nodes store two links, throwing in the link to the node’s predecessor.[](/book/grokking-data-structures/chapter-6/)[](/book/grokking-data-structures/chapter-6/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/06-19.png)

This trivial change has important consequences:

-  We can traverse a DLL in both directions, from its head to its tail, and from its tail to its head.
-  If we have a link to a single node of the list, we can reach any other node in the list, both before and after it. We experienced how important this is when we discussed the delete method for SLLs.
-  On the negative side, each node of a DLL takes up more space than the corresponding SLL variant. On large lists, the difference can affect your applications.
-  Another negative consequence is that for each change we make to the list, we need to update two links—maintenance becomes more complicated and more expensive.

As for the implementation, the `Node` class, in addition to the new attribute, now has a few more methods to set, access, and check this link to the previous node. Notice that we no longer pass an optional argument to `Node`’s constructor to set the next pointer. It’s better to force clients to create a disconnected node and use the append method explicitly.[](/book/grokking-data-structures/chapter-6/)

Also, for doubly linked lists, the logic of appending a new node is more complicated because, for consistency, we must also set the predecessor link of the node we are appending. Similarly, when we prepend a node, we must set its successor:

```
class Node:
    def __init__(self, data):
        self._data = data
        self._next = None
        self._prev = None
        
    def data(self):
        return self._data

    def next(self):
        return self._next

    def has_next(self):
        return self._next is not None

    def append(self, next_node):
        self._next = next_node
        if next_node is not None:
            next_node._prev = self

    def prev(self):
        return self._prev

    def has_prev(self):
        return self._prev is not None
        
    def prepend(self, prev_node):
        self._prev = prev_node
        if prev_node is not None:
            prev_node._next = self
```

In the wrapper class for the list, we also have some changes:

```
class DoublyLinkedList:
    def __init__(self):
        self._head = None
        self._tail = None
```

[](/book/grokking-data-structures/chapter-6/)Specifically, we also set a link to the tail of the list. This allows us to quickly delete from the end of the list but at the cost of keeping this link updated when we make any changes, as we will see in the next sections.

From these implementations alone, it’s clear that doubly linked lists are more complicated to implement and maintain than their singly linked counterparts. Are DLLs worth the tradeoff? Well, that depends on your application. Before we delve into the implementation of the methods for DLLs, let’s look at one such application where they do make a difference.

### The importance of retracing your steps

Meet Tim! He is working on his first video game, a side-scroller where the hero has to move from one room to another inside a building, from left to right.[](/book/grokking-data-structures/chapter-6/)[](/book/grokking-data-structures/chapter-6/)

Tim has carefully designed the rooms, implemented each room individually, and now he needs to model the sequence of progress between the rooms.

“How do I do that?” he wonders.

The framework Tim is using offers an out-of-the-box singly linked list, which would save him a lot of development time. But if he uses a singly linked list, the game hero can go to the room on the right but won’t be able to go back.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/06-20.png)

The problem is that for the gameplay Tim is designing, the players need to be able to trace back their steps because there are rooms where some interactions can only be unlocked later in the game. Then a singly linked list can’t work, and Tim needs to implement a doubly linked list.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/06-21.png)

Whenever we need to move back and forth through a list, in both directions, that’s a use case for a doubly linked list. It can be layers in a multi-layer document or actions that can be undone and redone. There are many use cases in computer science where the space used by the extra link of DLLs is not only worth it but necessary.

### Insert

We have discussed how the extra link stored in doubly linked lists can create new opportunities and, ultimately, value. Let’s now see the price we must pay, starting with the insert methods.[](/book/grokking-data-structures/chapter-6/)[](/book/grokking-data-structures/chapter-6/)

As before, we have the opportunity to insert elements at the beginning, at the end, or at an arbitrary point of the list.

#### Insert at the beginning of the list

Inserting a new node at the beginning of the list remains as fast as it was for singly linked lists: we still have to get the head of the list (and we have a link to it) and prepend the new node.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/06-22.png)

There is a little more maintenance to this operation for DLLs, because we need to update the previous pointer of the old head, and possibly we might have to update the link to the list’s tail, in one edge case—when we insert in an empty list:

```
def insert_in_front(self, data):
    if self._head is None:
        self._tail = self._head = Node(data)
    else:
        old_head = self._head
        self._head = Node(data)
        self._head.append(old_head)
```

#### Insert at the end of the list

Things get interesting with the insertion at the end of the list. If you remember what we discussed earlier in this chapter: inserting at the end of the list is particularly inefficient for SLLs. It takes linear time.

For DLLs, however, two things are game changers:

-  We can store a pointer to the tail of the list, which can then be accessed in constant time.
-  From any node, we can access (and update) its predecessor in constant time.

This means that we can follow the link to the tail of the list, and add a new node as its successor, all in constant time.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/06-23.png)

With a doubly linked list, we can efficiently insert the elements at either end of the list indifferently. Even more, since we can traverse the list in both directions, we can access the elements in both the direct and inverse order of insertion:

```
def insert_to_back(self, data):
    if self._tail is None:
        self._tail = self._head = Node(data)
    else:
        old_tail = self._tail
        self._tail = Node(data)
        self._tail.prepend(old_tail)
```

#### Insert in the middle

Finally, what if we want to insert an element in an arbitrary position in the middle of the list (that is, neither at the end nor at the beginning)?

[](/book/grokking-data-structures/chapter-6/)There are two possible situations. If we have the link to either of the nodes between which we need to add the new element, then the operation of adding the new node consists only of updating the `next` and `prev` pointers on those nodes, and it only takes constant time: compared to arrays, we don’t need to shift the elements to the right, and that’s a huge saving![](/book/grokking-data-structures/chapter-6/)[](/book/grokking-data-structures/chapter-6/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/06-24.png)

If we need to find the insertion point, especially when we want to keep the list sorted, this requires traversing the list. And list traversal takes linear time. The good news is that, even in this case, we wouldn’t need to store a reference to the previous node while traversing the list, which makes the operation easier than with SLLs.

### Search and traversal

When it comes to searching a doubly linked list, the extra links to the predecessors can’t really help us. Our best option is still linear search, which means traversing the list from its beginning to its end, until we find the element we are looking for, or until we reach the end of the list. Sure, we can now traverse the list in both directions, but (unless *domain knowledge* suggests otherwise), there is generally no advantage in doing so. Therefore, we can reuse the `_search` method written for SLLs exactly as it is—we don’t need to repeat the code here.[](/book/grokking-data-structures/chapter-6/)[](/book/grokking-data-structures/chapter-6/)[](/book/grokking-data-structures/chapter-6/)

Obviously, the same consideration applies to the `traverse` method. But as an exercise, you can add a method to traverse the list in reverse order, from tail to head.[](/book/grokking-data-structures/chapter-6/)

### Delete

Conceptually, `delete` on DLLs works exactly the same way as `delete` on SLLs: we traverse the list until we find the element we want to delete, `E`, and then update the links of the nodes before and after `E`, bypassing it. And then, we are done.[](/book/grokking-data-structures/chapter-6/)

There is one big difference, however: nodes store a link to their predecessor, so we can reuse the search method to find the node with the element to delete. Another difference is that we must pay attention to edge cases and update the `_tail` link for the linked list when needed.[](/book/grokking-data-structures/chapter-6/)

The implementation of the method, therefore, looks a lot different for doubly linked and singly linked lists:

```
def delete(self, target):
    node = self._search(target)
    if node is None:
        raise ValueError(f'{target} not found in the list.')
    if node.prev() is None:            #1
        self._head = node.next()
        if self._head is None:         #2
            self._tail = None
        else:
            self._head.prepend(None)
    elif node.next() is None:          #3
        self._tail = node.prev()
        self._tail.append(None)
    else:                              #4
        node.prev().append(node.next())
        del node
#1 Delete the node at the beginning of the list.
#2 In this case, the list’s head was the only element in the list.
#3 Delete the node at the end of the list.
#4 General case
```

The running time for the delete method remains `O(n)`, like for SLLs, because we still need to traverse the list to search the node storing the element to be deleted.

### Concatenating two lists

Imagine you have two or more lists, for example, lists of tasks, one list per day, where the tasks must be completed in the order they appear in the list, and today’s task must be completed before tomorrow’s tasks.[](/book/grokking-data-structures/chapter-6/)[](/book/grokking-data-structures/chapter-6/)

Suppose at some point we need to compress two days’ worth of errands into a single day—some travel is suddenly scheduled for tomorrow, and you need to complete your tasks by today. Concatenating two lists by appending one to the other is super easy—we just need to append the head of the second list to the tail of the first list.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/06-25.png)

In code: `today._tail.append(tomorrow._head)`. That’s it! Lists, and especially doubly linked lists, offer constant-time concatenation.

Now, imagine if we had to merge two arrays! We would have to allocate a new array whose size would be the sum of the sizes of the two original arrays and then move all the elements of both arrays into the newly created array.

Now imagine you have large lists of unsorted items that need to be merged often. This is the perfect example of an application where a linked list can perform much better than an array.

And that’s all for the doubly linked list. As always, you can find the full code for this class on the book’s repo on GitHub: [https://mng.bz/x2Re](https://mng.bz/x2Re).

Exercises

6.4 Implement a method to insert a new element after a certain node in the list. This node must be passed as an argument. What’s the running time for this method? Is there any edge case?

6.5 Implement the `SortedDoublyLinkedList` class, modeling a DLL whose elements are kept sorted. Hint: Follow the example of what we did with the `SortedSingleLinkedList` class. What methods do we need to override in this case?[](/book/grokking-data-structures/chapter-6/)[](/book/grokking-data-structures/chapter-6/)[](/book/grokking-data-structures/chapter-6/)

## Circular linked lists

So far in this chapter, we have been discussing linear lists that have a clear distinction between their beginning and end. In other words, we assume that once we have traversed a list and reached its end, we are done. Sometimes in life, it doesn’t work that way. Sometimes you need to start over instead of just stopping. In this section, we will look at some examples where this happens, and we will briefly discuss how we can modify our linked list data structures to adapt.[](/book/grokking-data-structures/chapter-6/)[](/book/grokking-data-structures/chapter-6/)

### Examples of circular linked lists

There are cyclical activities whose steps are repeated many times in the same sequence. For example, the agricultural cycle repeats the same steps each season, and the seasons themselves repeat in a perpetual cycle.[](/book/grokking-data-structures/chapter-6/)[](/book/grokking-data-structures/chapter-6/)[](/book/grokking-data-structures/chapter-6/)

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/06-26.png)

There are cyclical processes that go through stages, over and over again, like the process of building and launching a startup or a product, or the water cycle. Some resources are used cyclically, ranging from agricultural examples such as crops to computer-science-related instances such as cache nodes or servers. Another computer-related resource that is used cyclically and that you are probably familiar with are pictures in slide shows and carousels.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/06-27.png)

In all these contexts, instead of using a regular linked list, we might want to turn to one of its variants, a circular linked list.

Circular linked lists can be implemented as either singly linked or doubly linked lists indifferently. The choice between singly and doubly linked is independent and is based on the traversal requirements, as discussed earlier in the chapter.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/06-28.png)

For example, a singly linked list is sufficient to model a slideshow, a presentation where images are shown cyclically in the same order, without the possibility of manually going back. Similarly, if we need to represent the agricultural cycle, or route incoming calls to a list of servers, we can use a singly linked list, because we will only be traversing the list in one direction.

![](https://drek4537l1klr.cloudfront.net/larocca3/Figures/06-29.png)

If, instead, we need to be able to move in both directions in the list, we have to use a doubly linked list. In contrast to the slideshow above, imagine a carousel that allows users to go back and forth between pictures. An example of this would be modeling the process of creating, building, and growing a startup, where we might need to go back to a previous step at any time. For example, we could go back from the market phase to the analysis phase to adjust a product, without having to start from scratch.

### Implementation tips

[](/book/grokking-data-structures/chapter-6/)We won’t go into detail on how to implement circular linked lists, mainly because it requires only minimal changes with respect to the classes we already implemented in this chapter.[](/book/grokking-data-structures/chapter-6/)[](/book/grokking-data-structures/chapter-6/)

There are, however, a few things to keep in mind when designing a circular linked list:

-  While in regular lists the last node had no successor (and the head, in doubly linked lists, has no predecessor), in circular lists, we set the successor of the tail of the list to its head. This means that we must be careful when traversing the list, or we will end up in an infinite loop.
-  For a circular doubly linked list, we don’t need to store a link to the tail of the list: it’s just `head.prev`.
-  For circular linked lists, it is common to have some sort of iterative way to traverse the list: one element at a time, as we would do with a Python iterator. This means that we need to add another attribute to the list to store the node currently being traversed, plus a method that returns its data and, at the same time, advances to the next node.
-  If we provide step-by-step traversal, we will have to be very careful when deleting or inserting elements to the list—we will have to make sure to update the pointer to the current element when needed.

Exercise

6.6 Implement a circular linked list, with step-by-step traversal. You can implement either a singly or doubly linked version. Can we reuse anything from the classes we have defined earlier in the chapter? Is composition an option? Is inheritance an option, and what are pros and cons here?[](/book/grokking-data-structures/chapter-6/)

## Recap

-  *Linked lists* are an alternative to arrays because they can be expanded and shrunk more easily, without reallocating or moving elements other than those being added or removed.
-  A linked list is a two-tier data structure that is internally implemented as a sequence of instances of a data structure called *node*. Each node contains some data, namely an element of the list, and at least one link to the next node in the list.
-  Linked lists with only one link, the one to the successor of each node, are called *singly linked lists* (SLL). They are the simplest version of linked lists. Singly linked lists can only be traversed in one direction, from their beginning, called its *head*, to their end, called its *tail*.
-  Singly linked lists are fast for operations on the list head: inserting a node before the head of the list and deleting or accessing the head are all constant-time operations. Other operations take linear time.
-  In a *doubly linked list* (DLL), each node also stores a pointer to its predecessor. Therefore, doubly linked lists can also be traversed from their tail to their head, making it easier to read the list from both directions.
-  DLLs require more memory than SLLs to store the same elements.
-  Operations such as `insert`, `delete,` and `search` are, for the most part, as fast in SLLs as in DLLs. Doubly linked lists are faster when we need to insert or delete an element from the end of the list.
-  The best reason to choose a DLL over an SLL is the need to move through the list in both directions.
-  *Circular linked lists* are lists (either DLLs or SLLs) where the successor of the tail of the list is the head of the list (and vice versa, for DLLs). All nodes have a successor, and in DLLs, all nodes have a predecessor.
-  Circular linked lists are used whenever we need to traverse a list repeatedly (for example, to cyclically use resources or perform tasks)[](/book/grokking-data-structures/chapter-6/).
