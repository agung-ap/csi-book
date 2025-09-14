# Chapter 9. Iterators, sequences, and collections

### ***This chapter covers***

- Taking a closer look at iteration in Swift
- Showing how `Sequence` is related to `IteratorProtocol`
- Learning useful methods that `Sequence` supplies
- Understanding the different collection protocols
- Creating data structures with the `Sequence` and `Collection` protocols.

You use iterators, sequences, and collections all the time when programming Swift. Whenever you use an `Array`, `String`, `stride`, `Dictionary`, and other types, you’re working with something you can iterate over. Iterators enable the use of *for* loops. They also enable a large number of methods, including, but not limited to, `filter`, `map`, `sorted`, and `reduce`.

In this chapter, you’re going to see how these iterators work, learn about useful methods (such as `reduce` and `lazy`), and see how to create types that conform to the `Sequence` protocol. The chapter also covers the `Collection` protocol and its many subprotocols, such as `MutableCollection`, `RandomAccessCollection`, and others. You’ll find out how to implement the `Collection` protocol to get a lot of free methods on your types. Being comfortable with `Sequence` and `Collection` will give you a deeper understanding of how iteration works, and how to create custom types powered up by iterators.

You’ll start at the bottom and build up from there. You’ll get a look at how *for* loops work and how they are syntactic sugar for methods on `IteratorProtocol` and `Sequence`.

Then, you’ll take a closer look at `Sequence`, and find out how it produces iterators and why this is needed.

After that, you’ll learn some useful methods on `Sequence` that can help expand your iterator vocabulary. You’ll get acquainted with `lazy`, `reduce`, `zip`, and others.

To best show that you understand `Sequence`, you’ll create a custom type that conforms to `Sequence`. This sequence is a data structure called a `Bag` or `MultiSet`, which is like a `Set`, but for multiple values.

Then you’ll move on to `Collection` and see how it’s different from `Sequence`. You’ll see all the different types of `Collection` protocols that Swift offers and their unique traits.

As a final touch, you’ll integrate `Collection` on a custom data structure. You don’t need to be an algorithm wizard to reap the benefits of `Collection`. Instead, you’ll learn a practical approach by taking a regular data structure and power it up with `Collection`.

I made sure that you won’t fall asleep during this chapter either. Besides some theory, this chapter contains plenty of practical use cases.

### 9.1. Iterating

When programming Swift, you’re looping (iterating) through data all the time, such as retrieving elements inside of an array, obtaining individual characters inside a string, processing integers inside a range—you name it. Let’s start with a little bit of theory, so you know the inner workings of iteration in Swift. Then you’ll be ready to apply this newfound knowledge on practical solutions.

##### Join Me!

It’s more educational and fun if you can check out the code and follow along with the chapter. You can download the source code at [http://mng.bz/7JPy](http://mng.bz/7JPy).

#### 9.1.1. IteratorProtocol

Every time you use a *for in* loop, you’re using an iterator. For example, you can loop over an array regularly via *for in*.

##### Listing 9.1. Using *for in*

```
let cheeses = ["Gouda", "Camembert", "Brie"]

for cheese in cheeses {
    print(cheese)
}
// Output:
"Gouda"
"Camembert"
"Brie"
```

But *for in* is syntactic sugar. Actually, what’s happening under the hood is that an iterator is created via the `makeIterator()` method. Swift walks through the elements via a *while* loop, shown here.

##### Listing 9.2. Using `makeIterator()`

```
var cheeseIterator = cheeses.makeIterator()       #1
while let cheese = cheeseIterator.next() {        #2
     print(cheese)
}

// Output:
"Gouda"
"Camembert"
"Brie"
```

Although a *for* loop calls `makeIterator()` under the hood, you can pass an iterator directly to a *for* loop:

```
var cheeseIterator = cheeses.makeIterator()
for element in cheeseIterator {
    print(cheese)
}
```

The `makeIterator()` method is defined in the `Sequence` protocol, which is closely related to `IteratorProtocol`. Before moving on to `Sequence`, let’s take a closer look at `IteratorProtocol` first.

#### 9.1.2. The IteratorProtocol

An iterator implements `IteratorProtocol`, which is a small, yet powerful component in Swift. `IteratorProtocol` has an associated type called `Element` and a `next()` method that returns an optional `Element` (see [figure 9.1](https://livebook.manning.com/book/swift-in-depth/chapter-9/ch09fig1) and the listing that follows). Iterators generate values, which is how you can loop through multiple elements.

![Figure 9.1. IteratorProtocol produces elements](https://drek4537l1klr.cloudfront.net/veen/Figures/09fig01.jpg)

##### Listing 9.3. `IteratorProtocol` in Swift

```
public protocol IteratorProtocol {
  /// The type of element traversed by the iterator.
  associatedtype Element                               #1

  mutating func next() -> Element?
}
```

##### Note

If you’ve ever seen `Array` extensions, this is the same `Element` the extension uses.

Every time you call `next` on an iterator, you get the next value an iterator produces until the iterator is exhausted, on which you receive `nil`.

An iterator is like a bag of groceries— you can pull elements out of it, one by one. When the bag is empty, you’re out. The convention is that after an iterator depletes, it returns `nil` and any subsequent `next()` call is expected to return `nil`, too, as shown in this example.

##### Listing 9.4. Going through an iterator

```
let groceries = ["Flour", "Eggs", "Sugar"]
var groceriesIterator: IndexingIterator<[String]> = groceries.makeIterator()
print(groceriesIterator.next()) // Optional("Flour")
print(groceriesIterator.next()) // Optional("Eggs")
print(groceriesIterator.next()) // Optional("Sugar")
print(groceriesIterator.next()) // nil
print(groceriesIterator.next()) // nil
```

##### Note

Array returns an `IndexingIterator`, but this could be different per type.

#### 9.1.3. The Sequence protocol

Closely related to `IteratorProtocol`, the `Sequence` protocol is implemented all over Swift. In fact, you’ve been using sequences all the time. `Sequence` is the backbone behind any other type that you can iterate over. `Sequence` is also the superprotocol of `Collection`, which is inherited by `Array`, `Set`, `String`, `Dictionary`, and others, which means that these types also adhere to `Sequence`.

#### 9.1.4. Taking a closer look at Sequence

A `Sequence` can produce iterators. Whereas an `IteratorProtocol` is exhaustive, after the elements inside an iterator are consumed, the iterator is depleted. But that’s not a problem for `Sequence`, because `Sequence` can create a new iterator for a new loop. This way, types conforming to `Sequence` can repeatedly be iterated over (see [figure 9.2](https://livebook.manning.com/book/swift-in-depth/chapter-9/ch09fig2)).

![Figure 9.2. Sequence produces iterators](https://drek4537l1klr.cloudfront.net/veen/Figures/09fig02_alt.jpg)

Notice in [listing 9.5](https://livebook.manning.com/book/swift-in-depth/chapter-9/ch09list5) that the `Sequence` protocol has an associated type called `Iterator`, which is constrained to `IteratorProtocol`. `Sequence` also has a `make-Iterator` method that creates an iterator.

`Sequence` is a large protocol with a great number of default methods, but this chapter covers only the crucial elements.

##### Listing 9.5. `Sequence` protocol (not complete)

```
public protocol Sequence {

  associatedtype Element                                                     #1
 
  associatedtype Iterator: IteratorProtocol where Iterator.Element == Element#2#3
 
  func makeIterator() -> Iterator                                            #4
 
  func filter(                                                               #5
     _ isIncluded: (Element) throws -> Bool
) rethrows -> [Element]

 func forEach(_ body: (Element) throws -> Void) rethrows                     #5
 
// ... snip
}
```

##### No 'Sequenceprotocol'?

`Sequence` is not `SequenceProtocol`. Yet, `Sequence` constrains `Iterator` to `IteratorProtocol`, which might explain why `Iterator-Protocol` is named this way. Quirky, but so be it.

To implement `Sequence`, you merely have to implement `makeIterator()`. Being able to produce iterators is the secret sauce to how a `Sequence` can be iterated over repeatedly, such as looping over an array multiple times. `Sequence` may seem like an iterator factory, but don’t let this code snippet fool you. `Sequence` packs quite the punch, because it offers many default methods, such as `filter`, `map`, `reduce`, `flatMap`, `forEach`, `dropFirst`, `contains`, regular looping with *for in*, and much more. Having a type conform to `Sequence` means that it gets a lot of functionality for free. `Sequence` is not reserved for Swift types; you can create custom types that adhere to `Sequence`, too.

Let’s take a look at some essential methods on `Sequence`.

### 9.2. The powers of Sequence

Types that implement `Sequence` gain many useful methods for free. This book doesn’t rehash all methods because you’re probably familiar with some of them (and I’d like to try to keep this book under 1,000 pages). Let’s take this opportunity to shed light on some useful or tricky methods to build your iterative vocabulary.

#### 9.2.1. filter

Swift doesn’t shy away from taking ideas from *functional programming* concepts, such as `map`, `filter,` or `reduce` methods. The `filter` method is a common method that `Sequence` offers.

As an example, `filter` on `Sequence` filters data depending on the closure you pass it. For each element, `filter` passes each element to the closure function and expects a Boolean in return.

The `filter` method returns a new collection, except it keeps the elements from which you return `true` in the passed closure.

To illustrate, notice how `filter` is being applied to filter values of an array. It returns an array with all values higher than 1.

##### Listing 9.6. `filter` is a higher-order function

```
let result = [1,2,3].filter { (value) -> Bool in
    return value > 1
}

print(result) // [2, 3]
```

#### 9.2.2. forEach

Eating pasta every day gets boring—same with using *for* loops every day. If boredom strikes, you can use `forEach` instead; it’s a good alternative to a regular *for* loop to indicate that you want a so-called side effect. A side effect happens when some outside state is altered—such as saving an element to a database, printing, rendering a view, you name it—indicated by `forEach` not returning a value.

![](https://drek4537l1klr.cloudfront.net/veen/Figures/09fig03.jpg)

For instance, you can have an array of strings where for each element the `deleteFile` function gets called.

##### Listing 9.7. Using `forEach`

```
["file_one.txt", "file_two.txt"].forEach { path in
    deleteFile(path: path)
}

func deleteFile(path: String) {
    // deleting file ....
}
```

With `forEach` you have a nice shorthand way to call a function. In fact, if the function only accepts an argument and returns nothing, you can directly pass it to `forEach` instead. Notice in this listing how curly braces `{}` are replaced by parentheses `()`, because you’re directly passing a function.

##### Listing 9.8. Using `forEach` by passing a function

```
["file_one.txt", "file_two.txt"].forEach(deleteFile)
```

#### 9.2.3. enumerated

When you want to keep track of the number of times you looped, you can use the `enumerate-d` method, as shown in the following listing. It returns a special `Sequence` called `EnumeratedSequence` that keeps count of the iterations. The iteration starts at zero.

##### Listing 9.9. `enumerated`

```
["First line", "Second line", "Third line"]
     .enumerated()                                   #1
     .forEach { (index: Int, element: String) in
        print("\(index+1): \(element)")              #2
 }

// Output:
1: First line
2: Second line
3: Third line
```

Notice how `forEach` fits well once you chain sequence methods.

#### 9.2.4. Lazy iteration

Whenever you’re calling methods on a sequence, such as `forEach`, `filter`, or others, the elements are iterated *eagerly*. Eager iteration means that the elements inside the sequence are accessed immediately once you iterate. In most scenarios, an eager approach is the one you need. But in some scenarios this is not ideal. For example, if you have extremely large (or even infinite) resources, you may not want to traverse the whole sequence, but only some elements at a time.

For this case, Swift offers a particular sequence called `LazySequence`, which you obtain via the `lazy` keyword.

For example, you could have a range, going from 0 to the massive `Int.max` number. You want to filter on this range to keep all even numbers, and then get the last three numbers. You’ll use `lazy` to prevent a full iteration over a gigantic collection. Because of `lazy`, this iteration is quite cheap, because a lazy iterator calculates only a select few elements.

Notice in this listing that no actual work is done by `LazySequence` until you start reading the elements, which you do in the last step.

##### Listing 9.10. Using `lazy`

```
let bigRange = 0..<Int.max                               #1
 
let filtered = bigRange.lazy.filter { (int) -> Bool in
    return int.isMultiple(of: 2)
}                                                        #2
 
let lastThree = filtered.suffix(3)                       #3
 
for value in lastThree {
    print(value)                                         #4
 }

// Output:
9223372036854775802
9223372036854775804
9223372036854775806
```

Using `lazy` can be a great tool for large collections when you’re not interested in all the values. One downside is that `lazy` closures are `@escaping` and temporarily store a closure. Another downside of using `lazy` is that every time you access the elements, the results are recalculated on the fly. With an eager iteration, once you have the results, you’re done.

#### 9.2.5. reduce

The `reduce` method may be one of the trickier methods on `Sequence` to understand. With its foundation in functional programming, you may see it appear in other languages. It could be called `fold`, like in Kotlin or Rust, or it could be called `inject` in Ruby. To make it even more challenging, Swift offers two variants of the `reduce` method, so you have to decide which one to pick for each scenario. Let’s take a look at both variants.

With `reduce` you iterate over each element in a `Sequence`, such as an `Array`, and you accumulatively build an object. When `reduce` is done, it returns the finalized object. In other words, with `reduce` you turn multiple elements into a new object. Most commonly, you’re turning an array into something else, but `reduce` can also be called on other types.

##### REDUCE IN ACTION

Here, you’ll apply `reduce` to see it in action. `String` conforms to `Sequence`, so you can call `reduce` on it and iterate over its characters. For instance, imagine that you want to know the number of line breaks on a `String`. You’ll do this by iterating over each character, and increase the count if a character equals `"\n"`.

To start off, you have to supply a start value to `reduce`. Then, for each iteration, you update this value. In the next scenario, you want to count the number of line breaks, so you pass an integer with a value of zero, representing the count. Then your final result is the number of line breaks you measured, stored in `numberOf-LineBreaks`.

##### Listing 9.11. Preparing for a `reduce`

```
let text = "It's hard to come up with fresh exercises.\nOver and over again.\
    nAnd again."
let startValue = 0
let numberOfLineBreaks = text.reduce(startValue) { // ... snip
  // ... Do some work here
}
print(numberOfLineBreaks) // 2
```

With each iteration, `reduce` passes two values via a closure: one value is the element from the iteration, the other is the integer (`startValue`) you passed to `reduce`.

Then, for each iteration, you check for a newline character, represented by `"\n"`, and you increase the integer by one if needed. You do this by returning a new integer (see [figure 9.3](https://livebook.manning.com/book/swift-in-depth/chapter-9/ch09fig3)).

![Figure 9.3. How reduce passes values](https://drek4537l1klr.cloudfront.net/veen/Figures/09fig04_alt.jpg)

But `reduce` does something clever: in each iteration, you get the next character and the new integer you just updated in the previous iteration.

You return the `accumulation` value inside the closure, and `reduce` gives it right back again in the next iteration, allowing you to keep updating the `accumulation` integer. This way, you iterate over all elements while you update a single value. After `reduce` has finished iterating, it returns the final value you created—in this case `numberOf-LineBreaks`.

#### 9.2.6. reduce into

Imagine that you’re reducing the number of student grades into a dictionary that counts the number of grades, resolved to A, B, C, or D. You would be updating this dictionary in each iteration. The problem, however, is that you would have to create a mutable copy of this dictionary for every iteration. A copy occurs whenever you reference a dictionary, because `Dictionary` is a *value type*. Let’s see in this next listing how this works with `reduce`, before improving the code with `reduce(into:)`.

##### Listing 9.12. `reduce` with less performance

```
let grades = [3.2, 4.2, 2.6, 4.1]
let results = grades.reduce([:]) { (results: [Character: Int], grade: Double) in #1
     var copy = results                                                          #2
     switch grade {
     case 1..<2: copy["D", default: 0] += 1                                      #3
     case 2..<3: copy["C", default: 0] += 1                                      #3
     case 3..<4: copy["B", default: 0] += 1                                      #3
     case 4...: copy["A", default: 0] += 1                                       #3
     default: break
     }
    return copy                                                                  #4
 }

print(results) // ["C": 1, "B": 1, "A": 2]                                       #5
```

Because you’re copying the dictionary for every iteration with `var` `copy` `=` `results`, you incur a performance hit. Here is where `reduce(into:)` comes in. With the `into` variant, you can keep mutating the same dictionary, as shown here.

##### Listing 9.13. `reduce(into:)`

```
let results = grades.reduce(into: [:]) { (results: inout [Character: Int],
     grade: Double) in                                                     #1
     switch grade {
     case 1..<2: results["D", default: 0] += 1
     case 2..<3: results["C", default: 0] += 1
     case 3..<4: results["B", default: 0] += 1
     case 4...: results["A", default: 0] += 1
     default: break
     }
}
```

##### Note

You aren’t returning anything from the closure when using `reduce (into:)`.

When you’re working with larger value types—such as dictionaries or arrays—consider using the `into` variant for added performance.

Using `reduce` may look a bit foreign, because you might as well use a *for* loop as an alternative. But `reduce` can be a very concise way to build a value accumulatively. You could also state that `reduce` shows intent. With a *for* loop, you have to play the compiler to see if you’re filtering or transforming data or doing something else. If you see a `reduce`, you can quickly deduce (poetry intended) that you’re turning multiple values into something new.

Reduce is abstract enough that you can do many things with it. But `reduce` is most elegant when converting a list of elements into one thing. Whether that thing is a simple integer or a complex class or struct, `reduce` is your friend.

#### 9.2.7. zip

To close off this section, let’s look at `zip`. Zipping allows you to zip (pair) two iterators. If one iterator depletes, `zip` stops iterating.

Notice in this next listing how you iterate both from a to c and 1 to 10. Since the array with strings is the shortest, `zip` ends after three iterations.

##### Listing 9.14. `zip`

```
for (integer, string) in zip(0..<10, ["a", "b", "c"]) {
    print("\(integer): \(string)")
}
// Output:
// 0: a
// 1: b
// 2: c
```

##### Note

`zip` is a free-standing function and not called on a type.

Many more methods exist, including, but not limited to, `map`, `flatMap`, and `compactMap`, which have the privilege of their own chapter ([chapter 10](https://livebook.manning.com/book/swift-in-depth/chapter-10/ch10)). Let’s move on and see how to create a type conforming to `Sequence`, which gets all these methods for free.

#### 9.2.8. Exercises

1. What is the difference between reduce and `reduce(into:)`?
1. How would you choose between the two?

### 9.3. Creating a generic data structure with Sequence

Earlier you survived the theory lesson of how `Sequence` and `IteratorProtocol` work under the hood. Now, you’ll focus on building something with the newly acquired knowledge.

In this section, you’re building a data structure called a `Bag`, also known as a multiset. You’ll be using `Sequence` and `IteratorProtocol` so that you get free methods on `Bag`, such as `contains` or `filter`.

A `Bag` is like a `Set`: it stores elements in an unordered way and has quick insertion and lookup capabilities. But a `Bag` can store the same element multiple times, whereas a `Set` doesn’t.

Foundation has `NSCountedSet`, which is similar, but it’s not a native Swift type with a Swift-like interface. The one you build here is smaller in functionality, but Swifty all over and a good exercise.

#### 9.3.1. Seeing bags in action

First, let’s see how a bag works (see [figure 9.4](https://livebook.manning.com/book/swift-in-depth/chapter-9/ch09fig4)). You can insert objects just like `Set`, but with one big difference: you can store the same object multiple times. `Bag` has one optimization trick up its sleeve, though, because it keeps track of the number of times an object is stored and doesn’t physically store an object multiple times. Storing an element only once keeps memory usage down.

![Figure 9.4. How Bag stores data](https://drek4537l1klr.cloudfront.net/veen/Figures/09fig05.jpg)

Let’s see your `Bag` in action in this next listing. Its interface is similar to that of `Set`, but notice how you can add the same string multiple times. Also note that `Bag` is generic, just like `Set`, indicated by `Bag` storing strings, integers, or anything `Hashable`.

##### Listing 9.15. Using `Bag`

```
var bag = Bag<String>()
bag.insert("Huey")                                        #1
bag.insert("Huey")                                        #1
bag.insert("Huey")                                        #1
 
bag.insert("Mickey")                                      #1
 
bag.remove("Huey")                                        #2
 
bag.count // 3

print(bag)
// Output:
// Huey occurs 2 times
// Mickey occurs 1 time

let anotherBag: Bag = [1.0, 2.0, 2.0, 3.0, 3.0, 3.0]      #3
 print(anotherBag)
// Output:
// 2.0 occurs 2 times
// 1.0 occurs 1 time
// 3.0 occurs 3 times
```

##### Note

A bag can store anything that’s `Hashable`. Even though a bag can store anything, it can’t simply mix and match types—such as strings and integers—just like with `Array` or `Set`.

Before you implement any protocols, get your base data structure working to keep things simple.

Like `Set`, your `Bag` stores `Hashable` types so that you can have quick lookups by putting an element inside a dictionary. You define a generic `Element` constrained to `Hashable` for this, representing the elements that `Bag` stores. `Bag` stores each element inside a `store` property, and increases the counter of an element if you add the same element again. Conversely, `Bag` decreases the counter if you remove an element from it. When the counter hits zero, `Bag` removes the element altogether, which frees up memory, as shown in this listing.

##### Listing 9.16. Looking inside `Bag`

```
struct Bag<Element: Hashable> {                    #1
    private var store = [Element: Int]()           #2
 
    mutating func insert(_ element: Element) {
        store[element, default: 0] += 1            #3
    }

    mutating func remove(_ element: Element) {
        store[element]? -= 1                       #4
        if store[element] == 0 {                   #5
             store[element] = nil                  #5
        }
    }

    var count: Int {
        return store.values.reduce(0, +)           #6
    }

}
```

Now, with the basic functionality in place, start implementing some useful protocols. To help peek inside the bag, implement `CustomStringConvertible`. Whenever you print your bag, the `description` property supplies a custom string of the elements inside and their occurrences, as shown in this listing.

##### Listing 9.17. Making `Bag` conform to `CustomStringConvertible`

```
extension Bag: CustomStringConvertible {
    var description: String {
        var summary = String()
        for (key, value) in store {
            let times = value == 1 ? "time" : "times"
            summary.append("\(key) occurs \(value) \(times)\n")
        }
        return summary
    }
}
```

This is how you got the output as before:

```
let anotherBag: Bag = [1.0, 2.0, 2.0, 3.0, 3.0, 3.0]
print(anotherBag)
// Output:
// 2.0 occurs 2 times
// 1.0 occurs 1 time
// 3.0 occurs 3 times
```

#### 9.3.2. Creating a BagIterator

You can already use `Bag` as is. But you can’t iterate over it until you implement `Sequence`. To implement `Sequence`, you need an iterator, which you’ll creatively call `BagIterator`.

Inside `Bag`, a `store` property holds the data. `Bag` passes `store` to the `Iterator-Protocol` so that `IteratorProtocol` can produce values one by one. Sending a copy to `IteratorProtocol` means that it can mutate its copy of the `store` without affecting `Bag`.

Since `store` is a value type, it gets copied to `IteratorProtocol` when `Bag` passes the store to `IteratorProtocol`—but not to worry: Swift optimizes this to make sure a copy is cheap.

You need to apply a little trick because `Bag` is lying. It isn’t holding the number of elements that it says it does; it’s merely holding the element with a counter. So you’ll apply a trick: `BagIterator` returns the same element a multiple of times depending on the element’s count. This way, an outsider doesn’t need to know about the tricks `Bag` uses, and yet it gets the correct amount of elements.

Every time you call `next` on `BagIterator`, the iterator returns an element and lowers its count. Once the count hits nil, `BagIterator` removes the element. If no elements are left, the iterator is depleted and returns nil, signaling that `BagIterator` has finished iteration. The following listing gives an example of this.

##### Listing 9.18. Creating a `BagIterator`

```
struct BagIterator<Element: Hashable>: IteratorProtocol {        #1
 
    var store = [Element: Int]()                                 #2
 
    mutating func next() -> Element? {                           #3
         guard let (key, value) = store.first else {             #4
             return nil                                          #4
         }
         if value > 1 {                                          #5
             store[key]? -= 1                                    #5
         } else {
             store[key] = nil                                    #6
         }
         return key                                              #7
     }
}
```

You’re almost there. With `BagIterator` in place, you can extend `Bag` and make it conform to `Sequence`, as shown in the following listing. All that you need to do is implement `makeIterator` and return a freshly made `BagIterator`, which gets a fresh copy of `store`.

##### Listing 9.19. Implementing `Sequence`

```
extension Bag: Sequence {                             #1
     func makeIterator() -> BagIterator<Element> {    #2
         return BagIterator(store: store)             #3
     }
}
```

That was it; you now have unlocked the powers of `Sequence`, and `Bag` has plenty of free functionality. You can call `filter`, `lazy`, `reduce`, `contains`, and many other methods on a `Bag` instance.

##### Listing 9.20. Wielding the power of `Sequence`

```
bag.filter { $0.count > 2}
bag.lazy.filter { $0.count > 2}
bag.contains("Huey") // true
bag.contains("Mickey") // false
```

`Bag` is complete and wields the power of `Sequence`. Still, you can implement at least two more optimizations, related to `AnyIterator` and `ExpressibleByArrayLiteral`. Let’s go over them now.

#### 9.3.3. Implementing AnyIterator

For `Bag`, you had very little work to do when extending `Sequence`. All you did was create an instance of `BagIterator` and return it. In a scenario like this, you can decide to return `AnyIterator` to save you from creating a `BagIterator` altogether.

`AnyIterator` is a *type erased* iterator, which you can think of as a generalized iterator. `AnyIterator` accepts a closure when initialized; this closure is called whenever `next` is called on the iterator. In other words, you can put the `next` functionality from `BagIterator` inside the closure you pass to `AnyIterator`.

The result is that you can extend `Bag` by conforming to `Sequence`, return a new `AnyIterator` there, and then you can delete `BagIterator`.

##### Listing 9.21. Using `AnyIterator`

```
extension Bag: Sequence {
    func makeIterator() -> AnyIterator<Element> {                      #1
         var exhaustiveStore = store // create copy

        return AnyIterator<Element> {                                  #2
            guard let (key, value) = exhaustiveStore.first  else {
                return nil
            }
            if value > 1 {
                exhaustiveStore[key]? -= 1
            } else {
                exhaustiveStore[key] = nil
            }
            return key
        }
    }
}
```

Whether you want to use `AnyIterator` depends on your situation, but it can be an excellent alternative to a custom iterator to remove some boilerplate.

#### 9.3.4. Implementing ExpressibleByArrayLiteral

Earlier, you saw how to create a bag from an array literal syntax. Notice how you create a bag, even though you use an array-like notation:

```
let colors: Bag = ["Green", "Green", "Blue", "Yellow", "Yellow", "Yellow"]
```

To obtain this syntactic sugar, you can implement `ExpressibleByArrayLiteral`. By doing so, you implement an initializer that accepts an array of elements. You can then use these elements to propagate the `store` property of `Bag`. You’ll use the `reduce` method on the array to reduce all elements into one `store` dictionary.

##### Listing 9.22. Implementing `ExpressibleByArrayLiteral`

```
extension Bag: ExpressibleByArrayLiteral {                                 #1
    typealias ArrayLiteralElement = Element
    init(arrayLiteral elements: Element...) {                              #2
         store = elements.reduce(into: [Element: Int]()) {
     (updatingStore, element) in                                           #3
             updatingStore[element, default: 0] += 1                       #4
         }
    }
}

let colors: Bag = ["Green", "Green", "Blue", "Yellow", "Yellow", "Yellow"] #5
print(colors)
// Output:
// Green occurs 2 times
// Blue occurs 1 time
// Yellow occurs 3 times
```

The `Bag` type has a Swift-friendly interface. In its current state, `Bag` is ready to use, and you can keep adding to it, such as by adding `intersection` and `union` methods to make it more valuable. Generally speaking, you won’t have to create a custom data structure every day, but it does have use once in a while. Knowing about `Sequence` lays down an essential foundation because it’s the base for the `Collection` protocol, which is a bit higher-level. The next section introduces the `Collection` protocol.

#### 9.3.5. Exercise

1. Make an infinite sequence. This sequence keeps looping over the sequence you pass. An infinite sequence is handy to generate data, such as when zipping. The infinite sequence keeps going, but the other sequence could deplete, thus stopping the iteration. For example, this code

let infiniteSequence = InfiniteSequence(["a","b","c"])
for (index, letter) in zip(0..<100, infiniteSequence) {
print("\(index): \(letter)")
}

copy

outputs the following:

0: a
1: b
2: c
3: a
4: b

... snip

95: c
96: a
97: b
98: c
99: a

copy

### 9.4. The Collection protocol

It’s time to move on to the next level of the iteration trifecta: besides `IteratorProtocol` and `Sequence`, there is the `Collection` protocol.

The `Collection` protocol is a subprotocol of `Sequence`—meaning that `Collection` inherits all functionality from `Sequence`. One major difference between `Collection` and `Sequence` is that collection types are indexable. In other words, with collection types, you can directly access an element at a specific position, such as via a subscript; for example, you can use `myarray[2]` or `myset["monkeywrench"]`.

Another difference is that `Sequence` doesn’t dictate whether or not it’s destructive, meaning that two iterations may not give the same results, which can potentially be a problem if you want to iterate over the same sequence multiple times.

As an example, if you break an iteration and continue from where you left off, you won’t know if a `Sequence` continues where it stopped, or if it restarted from the beginning.

##### Listing 9.23. Resuming iteration on a `Sequence`

```
let numbers = // Let's say numbers is a Sequence but not a Collection
for number in numbers {
  if number == 10 {
    break
  }
}

for number in numbers {
  // Will iteration resume, or start from the beginning?
}
```

`Collection` does guarantee to be nondestructive, and it allows for repeated iteration over a type with the same results every time.

The most common `Collection` types that you use every day are `String`, `Array`, `Dictionary`, and `Set`. You’ll start by taking a closer look at all available `Collection` protocols.

#### 9.4.1. The Collection landscape

With collections, you gain indexing capabilities. For example, on `String` you can use indices to get elements, such as getting the words before and after a space character, as shown in the following listing.

##### Listing 9.24. Indexing a `String`

```
let strayanAnimals = "Kangaroo Koala"
if let middleIndex = strayanAnimals.firstIndex(of: " ") {                 #1
    strayanAnimals.prefix(upTo: middleIndex) // Kangaroo
    strayanAnimals.suffix(from: strayanAnimals.index(after: middleIndex)) //
     Koala
}
```

Besides offering indexing capabilities, `Collection` has multiple subprotocols, which each offer restrictions and optimizations on top of `Collection`. For instance, `Mutable-Collection` allows for mutation of a collection, but it doesn’t allow you to change its length. Alternatively, `RangeReplaceableCollection` allows the length of a collection to change. `BidirectionalCollection` allows a collection to be traversed backwards. `RandomAccessCollection` promises performance improvements over `Bidirectional-Collection` (see [figure 9.5](https://livebook.manning.com/book/swift-in-depth/chapter-9/ch09fig5)).

![Figure 9.5. An overview of the Collection protocols](data:image/svg+xml;utf8,%3Csvg%20xmlns=%22http://www.w3.org/2000/svg%22%20xmlns:xlink=%22http://www.w3.org/1999/xlink%22%20version=%221.1%22%20x=%220px%22%20y=%220px%22%20viewBox=%220%200%20590%20381%22%20xml:space=%22preserve%22%20height=%22381px%22%20width=%22590px%22%3E%20%3Crect%20width=%22590%22%20height=%22381%22%20style=%22fill:rgb(255,255,255);%22/%3E%3C/svg%3E)

#### 9.4.2. MutableCollection

`MutableCollection` offers methods that mutate elements in place without changing the length of a collection. Because the methods of `MutableCollection` don’t change the length, the protocol can offer guarantees and performance improvements. The most common type that adheres to `MutableCollection` is `Array`.

`MutableCollection` adds a few special methods. To obtain these methods, you need to have a variable `Array`—as opposed to a constant—by using the `var` keyword.

With a `MutableCollection` you can sort in place:

```
var mutableArray = [4, 3, 1, 2]
mutableArray.sort() // [1, 2, 3, 4]
```

Another intriguing method that `MutableCollection` offers is `partition`. The partition method reshuffles the array in two parts that you define. On top of that, `partition` returns the index of where the array is split up. You can, as shown in this example, choose to partition an array of integers into odd and even numbers.

##### Listing 9.25. Partitioning

```
var arr = [1,2,3,4,5]
let index = arr.partition { (int) -> Bool in
    return int % 2 == 0                         #1
}

print(arr) // [1, 5, 3, 4, 2]                   #2
print(index) // 3                               #3
 
arr[..<index] // [1, 5, 3]                      #4
arr[index...] // [4, 2]                         #5
```

Other methods, such as `reverse()` and `swapAt()`, come in handy, too. I recommended experimenting with them and making them part of your iterator vocabulary.

##### STRING DOESN’T CONFORM TO MUTABLECOLLECTION

Perhaps surprisingly, `String` doesn’t conform to `MutableCollection`, because the length of `String` can change if you were to reorder characters. Changing the length of a collection is something that `MutableCollection` doesn’t allow.

The length of `String` changes when you reorder characters, because of its underlying structure; a character can be composed out of multiple unicode *scalars*. For instance, the character `é` could exist out of the scalars `e` and the acute accent `'`; swapping them around could turn `é` into `'e`. Because moving scalars could potentially create different characters, `String` can change length, which is why `String` does *not* conform to `MutableCollection`.

#### 9.4.3. RangeReplaceableCollection

Next up in the list of contenders is `RangeReplaceableCollection`, which allows you to swap out ranges and change its length. `Array` and `String` conform to `Range-Replaceable-Collection`. Moreover, it brings you some handy methods, such as concatenation via the `+` method.

If the array is defined mutably by `var` (not to be confused with `MutableCollection`), you can use the `+=` keyword to append in place. Notice in the next listing how you can change the length of the array with the methods offered by `RangeReplaceable-Collection`.

##### Listing 9.26. Mutating length of an array

```
var muppets = ["Kermit", "Miss Piggy", "Fozzie bear"]

muppets += ["Statler", "Waldorf"]
print(muppets) // ["Kermit", "Miss Piggy", "Fozzie bear", "Statler", "Waldorf"]

muppets.removeFirst() // "Kermit"
print(muppets) // ["Miss Piggy", "Fozzie bear", "Statler", "Waldorf"]

muppets.removeSubrange(0..<2)
print(muppets) // ["Statler", "Waldorf"]
```

Since `String` adheres to `RangeReplaceableCollection`, you can mutate strings in place and change its length.

##### Listing 9.27. Mutating `String`

```
var matrix = "The Matrix"
matrix += " Reloaded"
print(matrix) // The Matrix Reloaded
```

##### REMOVEALL

`RangeReplaceableCollection` also has a useful method called `removeAll(where:)`. With this method, you can quickly remove elements from a collection, such as `Array` (for instance, when you want to remove “Donut” from an array of healthy food items, as shown in the following code).

##### Listing 9.28. `removeAll` in action

```
var healthyFood = ["Donut", "Lettuce", "Kiwi", "Grapes"]
healthyFood.removeAll(where:{ $0 == "Donut" })
print(healthyFood) // ["Lettuce", "Kiwi", "Grapes"]
```

You may be tempted to use `filter` instead, but when removing values, special optimizations can be applied, making it faster to use the `removeAll` method on variable collections.

##### Note

The `removeAll` method is only available if your collection is a variable, as indicated with `var`.

#### 9.4.4. BidirectionalCollection

With a `BidirectionalCollection` you can traverse a collection backwards from an index, as in the following example. You can get the index before another index, which allows you to access a previous element (such as obtaining previous characters on a string).

##### Listing 9.29. Iterating backwards

```
var letters = "abcd"
var lastIndex = letters.endIndex
while lastIndex > letters.startIndex {
    lastIndex = letters.index(before: lastIndex)
    print(letters[lastIndex])
}

// Output:
// d
// c
// b
// a
```

Using `index(before:)` is a bit low level for regular use. Idiomatically, you can use the `reversed()` keyword to reverse a collection.

##### Listing 9.30. Using `reversed()` instead

```
var letters = "abcd"
for value in letters.reversed() {
    print(value)
}
```

But `index(before:)` does help if you want to iterate backwards only a specific number of times. By using `reversed()`, the iterator keeps looping until you break the loop.

#### 9.4.5. RandomAccessCollection

The `RandomAccessCollection` inherits from `BidirectionalCollection` and offers some performance improvements for its methods. The major difference is that it can measure distances between indices in constant time. In other words, `RandomAccessCollection` poses more restrictions on the implementer, because it must be able to measure the distances between indices without traversal. Potentially, traversing a collection can be expensive when you advance indices—for example, using `index(_offsetBy:)`—which is not the case for `RandomAccessCollection`.

Array conforms to all collection protocols, including `RandomAccessCollection`, but a more esoteric type that conforms to `RandomAccessCollection` is the `Repeated` type. This type is handy to enumerate over a value multiple times. You obtain a `Repeated` type by using the `repeatElement` function, as shown here.

##### Listing 9.31. `Repeated` type

```
for element in repeatElement("Broken record", count: 3) {
    print(element)
}

// Output:
// Broken record
// Broken record
// Broken record
```

You can use `repeatElement` to quickly generate values, which is useful for use cases such as generating test data. You can even zip them together, as in the following example, for more advanced iterations.

##### Listing 9.32. Using `zip`

```
zip(repeatElement("Mr. Sniffles", count: 3), repeatElement(100, count:
     3)).forEach { name, index in
    print("Generated \(name) \(index)")
}

Generated Mr. Sniffles 100
Generated Mr. Sniffles 100
Generated Mr. Sniffles 100
```

### 9.5. Creating a collection

Let’s face it, in most of your programming you’re not inventing a new collection type every day. You can usually get by with `Set`, `Array`, and others that Swift offers. That isn’t to say that knowing about `Collection` is a waste of time, though. More often than not you have some data structure that could benefit from `Collection`. With a little bit of code, you can make your types conform to `Collection` and reap all the benefits without knowing how to balance binary search trees or by implementing other fancy algorithms.

#### 9.5.1. Creating a travel plan

You’ll start by making a data structure called `TravelPlan`. A travel plan is a sequence of days, consisting of one or more activities. For instance, a travel plan could be visiting Florida, and it could contain multiple activities, such as visiting Key West, being chased by alligators on the golf course, or having breakfast at the beach.

First, you’ll create the data structures, and then you’ll adhere `TravelPlan` to `Collection` so that you can iterate over `TravelPlan` and obtain indexing behavior. You’ll start with the `Activity` and `Day` before you move on to `TravelPlan`.

As shown in this listing, `Activity` is nothing more than a timestamp and a description.

##### Listing 9.33. `Activity`

```
struct Activity: Equatable {
    let date: Date
    let description: String
}
```

`Day` is slightly more intricate than `Activity`. `Day` has a date, but since it covers a whole day, you can strip the time, as in this next listing. Then you can make `Day` conform to `Hashable` so that you can store it in a dictionary as a key later.

##### Listing 9.34. `Day`

```
struct Day: Hashable {                                                          #1
    let date: Date

    init(date: Date) {
        // Strip time from Date
        let unitFlags: Set<Calendar.Component> = [.day, .month, .year]          #2
        let components = Calendar.current.dateComponents(unitFlags, from: date)
        guard let convertedDate = Calendar.current.date(from: components) else {#3
            self.date = date
            return
        }
        self.date = convertedDate
    }

}
```

The `TravelPlan` stores days as keys, and their activities as values. This way, a travel plan can have multiple days, where each day can have multiple activities. Having multiple activities per day is reflected by a dictionary inside `TravelPlan`. Since you refer to this dictionary multiple times, you introduce a `typealias` for convenience called `DataType`.

Also, you add an initializer that accepts activities. You can then group activities by days and store them in the dictionary. In this next listing, you’ll use the `grouping` method on `Dictionary` to turn `[Activity]` into `[Day:` `[Activity]]`.

##### Listing 9.35. `TravelPlan`

```
struct TravelPlan {

    typealias DataType = [Day: [Activity]]                                 #1
 
    private var trips = DataType()

    init(activities: [Activity]) {
        self.trips = Dictionary(grouping: activities) { activity -> Day in #2
             Day(date: activity.date)
        }
    }

}
```

`grouping` works by passing it a sequence—such as `[Activity]`—and a closure. Then `grouping` calls the closure for each element. You return a `Hashable` type inside the closure, and then every value of the array is added to the corresponding key. You end up with the keys—the ones you return in the closure—and an array of values for each key.

#### 9.5.2. Implementing Collection

Now, your `TravelPlan` data structure is functional, but you can’t iterate over it yet. Instead of conforming `TravelPlan` to `Sequence`, you’ll make `TravelPlan` conform to `Collection`.

Surprisingly enough, you don’t need to implement `makeIterator`. You could, but `Collection` supplies a default `IndexingIterator`, which is a nice benefit of adhering to `Collection`.

To adhere to `Collection`, you need to implement four things: two variables (`start-Index` and `endIndex`) and two methods (`index(after:)` and `subscript(index:)`).

Because you’re not coming up with your own algorithm and you’re encapsulating a type that conforms to `Collection`—in this case, a dictionary—you can use the methods of the underlying dictionary instead, as shown in this listing. In essence, you’re forwarding the underlying methods of a dictionary.

##### Listing 9.36. Implementing `Collection`

```
extension TravelPlan: Collection {

    typealias KeysIndex = DataType.Index                         #1
    typealias DataElement = DataType.Element                     #1
 
    var startIndex: KeysIndex { return trips.keys.startIndex }   #2
    var endIndex: KeysIndex { return trips.keys.endIndex }       #2
 
    func index(after i: KeysIndex) -> KeysIndex {                #3
         return trips.index(after: i)
    }

    subscript(index: KeysIndex) -> DataElement {                 #3
         return trips[index]
    }

}
```

That’s all it took! Now `TravelPlan` is a full-fledged `Collection` and you can iterate over it.

##### Listing 9.37. `TravelPlan` iteration

```
for (day, activities) in travelPlan {
    print(day)
    print(activities)
}
```

You don’t have to come up with a custom iterator. `Collection` supplies `Indexing-Iterator` for you.

##### Listing 9.38. A default iterator

```
let defaultIterator: IndexingIterator<TravelPlan> = travelPlan.makeIterator()
```

#### 9.5.3. Custom subscripts

By adhering to `Collection`, you gain subscript capabilities, which let you access a collection via square brackets [].

But since you’re forwarding the one from a dictionary, you’d have to use an esoteric dictionary index type. In the next listing, you’ll create a few convenient subscripts instead, which allows you to access elements via a useful subscript syntax.

##### Listing 9.39. Implementing subscripts

```
extension TravelPlan {
    subscript(date: Date) -> [Activity] {
        return trips[Day(date: date)] ?? []
    }

    subscript(day: Day) -> [Activity] {
        return trips[day] ?? []
    }
}

// Now, you can access contents via convenient subscripts.

travelPlan[Date()]                  #1
 
let day = Day(date: Date())
travelPlan[day]                     #2
```

Another critical aspect of `Collection` is that the subscript is expected to give back a result instantaneously unless stated otherwise for your type. Instant access is also referred to as *constant-time* or O(1) performance in Big-O notation. Since you’re forwarding method calls from a dictionary, `TravelPlan` is returning values in constant time. If you were to traverse a full collection to get a value, access would not be instantaneous, and you would have a so-called O(n) performance. With O(n) performance, longer collections mean that lookup times increase linearly. Developers that use your collection may not expect that.

#### 9.5.4. ExpressibleByDictionaryLiteral

Like you did with the `Bag` type in section 9.3.4, “Implementing ExpressibleByArrayLiteral”, you can implement the `Expressible-ByArrayLiteral` protocol for convenient initializing. To conform to this protocol, you merely have to adopt an initializer that accepts multiple elements. As shown in this listing, inside the body of the initializer, you can relay the method by calling an existing initializer.

##### Listing 9.40. Implementing `ExpressibleByArrayLiteral`

```
extension TravelPlan: ExpressibleByArrayLiteral {
    init(arrayLiteral elements: Activity...) {
        self.init(activities: elements)
    }
}
```

Another protocol you can implement for convenience is `ExpressibleByDictionary-Literal`. It’s similar to `ExpressibleByArrayLiteral`, but it allows you to create a `Travel-Plan` from a dictionary notation instead. You implement an initializer that supplies an array of tuples. Then you can use the `uniquingKeysWith:` method on `Dictionary` to turn the tuples into a dictionary. The closure you pass to `uniquing-KeysWith:` is called when a conflict of two keys occurs. In this case, you choose one of the two conflicting values, as shown in the following code.

##### Listing 9.41. Implementing `ExpressibleByDictionaryLiteral`

```
extension TravelPlan: ExpressibleByDictionaryLiteral {
    init(dictionaryLiteral elements: (Day, [Activity])...) {
        self.trips = Dictionary(elements, uniquingKeysWith: { (first: Day, ) in #1
             return first // Choose one when a Day is duplicate.                #2
         })
    }
}

let adrenalineTrip = Day(date: Date())
let adrenalineActivities = [
    Activity(date: Date(), description: "Bungee jumping"),
    Activity(date: Date(), description: "Driving in rush hour LA"),
    Activity(date: Date(), description: "Sky diving")
]

let adrenalinePlan = [adrenalineTrip: activities] // You can now create a
     TravelPlan from a dictionary
```

#### 9.5.5. Exercise

1. Make the following type adhere to the `Collection` protocol:

struct Fruits {
let banana = "Banana"
let apple = "Apple"
let tomato = "Tomato"
}

copy

### 9.6. Closing thoughts

You’ve successfully—and relatively painlessly—created a custom type that adheres to `Collection`. The real power lies in recognizing when you can implement these iteration protocols. Chances are that you might have some types in your projects that can gain extra functionality by adhering to `Collection`.

You’ve also taken a closer look at `Sequence` and `IteratorProtocol` to get a deeper understand of how iteration works in Swift. You don’t need to be an algorithmic wizard to power up your types, which come in handy in day-to-day work. You also discovered a handful of widespread and useful iterator methods you can find on `Sequence`. If you want more iteration tips, check out [chapter 10](https://livebook.manning.com/book/swift-in-depth/chapter-10/ch10), which covers `map`, `flatMap`, and `compactMap`.

### Summary

- Iterators produce elements.
- To iterate, Swift uses a while loop on `makeIterator()` under the covers.
- Sequences produce iterators, allowing them to be iterated over repeatedly.
- Sequences won’t guarantee the same values when iterated over multiple times.
- `Sequence` is the backbone for methods such as `filter`, `reduce`, `map`, `zip`, `repeat`, and many others.
- `Collection` inherits from `Sequence`.
- `Collection` is a protocol that adds subscript capabilities and guarantees nondestructive iteration.
- `Collection` has subprotocols, which are more-specialized versions of `Collection`.
- `MutableCollection` is a protocol that offers mutating methods without changing the length of a collection.
- `RangeReplaceableCollection` is a protocol that restricts collections for easy modification of part of a collection. As a result, the length of a collection may change. It also offers useful methods, such as `removeAll(where:)`.
- `BidirectionalCollection` is a protocol that defines a collection that can be traversed both forward and backward.
- `RandomAccessCollection` restricts collections to constant-time traversal between indices.
- You can implement `Collection` for regular types that you use in day-to-day programming.

### Answers

1. What is the difference between reduce and `reduce(into:)`? With `reduce(into:)` you can prevent copies for each iteration.
1. How would you choose between the two? `reduce` makes sense when you aren’t creating expensive copies for each iteration, such as when you’re reducing into an integer. `reduce(into:)` makes more sense when you’re reducing into a struct, such as an array or dictionary.
1. Make an infinite sequence. This sequence will keep looping over the sequence you pass:

// If you implement both Sequence and IteratorProtocol, you only need
to implement the next method.
struct InfiniteSequence<S: Sequence>: Sequence, IteratorProtocol {

let sequence: S
var currentIterator: S.Iterator
var isFinished: Bool = false

init(_ sequence: S) {
self.sequence = sequence
self.currentIterator = sequence.makeIterator()
}
mutating func next() -> S.Element? {
guard !isFinished else {
return nil
}

if let element = currentIterator.next() {
return element
} else {
self.currentIterator = sequence.makeIterator()
let element = currentIterator.next()
if element == nil {
// If sequence is still empty after creating a new one,
then the sequence is empty to begin with; you will need to protect
against this in case of an infinite loop.
isFinished = true
}
return element
}
}

}

let infiniteSequence = InfiniteSequence(["a","b","c"])
for (index, letter) in zip(0..<100, infiniteSequence) {
print("\(index): \(letter)")
}

copy

1. Make the following type adhere to `Collection`:

struct Fruits {
let banana = "Banana"
let apple = "Apple"
let tomato = "Tomato"
}

extension Fruits: Collection {
var startIndex: Int {
return 0
}

var endIndex: Int {
return 3 // Yep, it's 3, not 2. That's how Collection wants it.
}
func index(after i: Int) -> Int {
return i+1
}
subscript(index: Int) -> String {
switch index {
case 0: return banana
case 1: return apple
case 2: return tomato
default: fatalError("The fruits end here.")
}
}

}

let fruits = Fruits()
fruits.forEach { (fruit) in
print(fruit)
}

copy
