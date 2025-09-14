# Chapter 7. Generics

### ***This chapter covers***

- How and when to write generic code
- Understanding how to reason about generics
- Constraining generics with one or more protocols
- Making use of the `Equatable`, `Comparable`, and `Hashable` protocols
- Creating highly reusable types
- Understanding how subclasses work with generics

Generics are a core component of Swift, and they can be tricky to understand at first. There is no shame if you’ve been staying away from generics, perhaps because they are sometimes intimidating or confusing. Like a carpenter can do work without a hammer, so can you develop software without generics. But making generics part of your regular software routine sure does help, because by using generics you can create code that works on current and future requirements, and it saves much repetition. By using generics, your code ends up more succinct, hard-hitting, boilerplate-reducing, and future-proof.

This chapter starts by looking at the benefits of generics and when and how to apply them. It starts slow, but then ramps up the difficulty by looking at more complex use cases. Generics are a cornerstone of Swift, so it’s good to internalize them because they’re going to pop up a lot, both in the book and while reading and writing Swift out in the wild.

After enough exposure and “aha” moments, you’ll start to feel comfortable in using generics to write hard-hitting, highly reusable code.

You’ll discover the purpose and benefits of generics and how they can save you from writing duplicate code. Then, you’ll take a closer look at what generics do behind the scenes, and how you can reason about them. At this point, generics should be a little less scary.

In Swift, generics and protocols are vital in creating polymorphic code. You’ll find out how to use protocols to *constrain* generics, which enables you to create generic functions with specific behavior. Along the way, this chapter introduces two essential protocols that often coincide with generics: `Equatable` and `Comparable`.

Then, to step up your generics game, you’ll find out how to constrain generics with multiple protocols, and you’ll see how to improve readability with a `where` clause. The `Hashable` protocol is introduced, which is another essential protocol that you see often when working with generics.

It all comes together when you create a flexible struct. This struct contains multiple constrained generics and implements the `Hashable` protocol. Along the way, you’ll get a glimpse of a Swift feature called *conditional conformance*.

To further cement your knowledge of generics, you’ll learn that generics don’t always mix with subclasses. When using both techniques at the same time, you’ll need to be aware of a few special rules.

Once generics become part of your toolbox, you may find yourself slimming down your codebase with elegant and highly reusable code. Let’s take a look.

### 7.1. The benefits of generics

##### Join Me!

It’s more educational and fun if you can check out the code and follow along with the chapter. You can download the source code at [http://mng.bz/nQE8](http://mng.bz/nQE8).

Let’s start small to get a feel for generics. Imagine that you have a function called `firstLast` that extracts the first and last elements from an array of integers.

##### Listing 7.1. First and last

```
let (first, last) = firstLast(array: [1,2,3,4,5])
print(first) // 1
print(last) // 5

func firstLast(array: [Int]) -> (Int, Int) {
    return (array[0], array[array.count-1])
}
```

Now, you’d like the same for arrays containing `String`. In the following listing, you’re defining a similar function, except it’s specified to the `String` type. Swift knows which similarly named function to pick.

##### Listing 7.2. `firstLast` with an array of strings

```
123456func firstLast(array: [String]) -> (String, String) {
    return (array[0], array[array.count-1])
}
let (first, last) = firstLast(array: ["pineapple", "cherry", "steam locomotive"])
print(first) // "pineapple"
print(last) // "steam locomotive"
```

Having to create a new function for each type doesn’t quite scale. If you want this method for an array of `Double`, `UIImage`, or custom `Waffle` types, you would have to create new functions every time.

Alternatively, you can write a single function that works with `Any`, but then the return value of the tuple would be `(Any,` `Any)`, not `(String,` `String)` or `(Int,` `Int)`. You would have to downcast `(Any,` `Any)` to `(String,` `String)` or `(Int,` `Int)` at runtime.

Reducing boilerplate and avoiding `Any` is where generics can help. With generics, you can create a function that is polymorphic at compile time. Polymorphic code means that it can work on multiple types. With a generic function, you need to define the function only once, and it works with `Int`, `String`, and any other type, including custom types that you introduce or haven’t even written yet. With generics, you would not work with `Any`, saving you from downcasting at runtime.

#### 7.1.1. Creating a generic function

Let’s compare the nongeneric and the generic version of the `firstLast` function.

You’re adding a generic `<T>` type parameter to your function signature. Adding a `<T>` helps you introduce a generic to your function, which you can refer to in the rest of your function. Notice how all you do is define a `<T>` and replace all occurrences of `Int` with `T`.

##### Listing 7.3. Comparing a generic versus nongeneric function signature

```
// Nongeneric version
func firstLast(array: [Int]) -> (Int, Int) {
    return (array[0], array[array.count-1])
}
// Generic version
func firstLast<T>(array: [T]) -> (T, T) {
    return (array[0], array[array.count-1])
}
```

##### A Cup of T?

Usually a generic is often defined as type `T`, which stands for *Type*. Generics tend to be called something abstract such as `T`, `U`, or `V` as a convention. Generics can be words, too, such as `Wrapped`, as used in `Optional`.

By declaring a generic `T` via the `<T>` syntax, you can refer to this `T` in the rest of the function—for example, `array:[T]` and its return type `(T,` `T)`.

You can refer to `T` in the body, which is showcased by expanding the body of the function, as shown here.

##### Listing 7.4. Referencing a generic from the body

```
func firstLast<T>(array: [T]) -> (T, T) {
    let first: T = array[0]
    let last: T = array[array.count-1]
    return (first, last)
}
```

You can see your generic function in action. Notice how your function works on multiple types. You could say your function is type-agnostic.

##### Listing 7.5. The generic function in action

```
let (firstString, lastString) = firstLast(array: ["pineapple", "cherry",
     "steam locomotive"])
print(firstString) // "pineapple"
print(lastString) // "steam locomotive"
```

If you were to inspect the values `firstString` or `lastString`, you could see that they are of type `String`, as opposed to `Any`. You can pass custom types, too, as demonstrated next by the `Waffle` struct shown here.

##### Listing 7.6. Custom types

```
// Custom types work, too
struct Waffle {
    let size: String
}

let (firstWaffle: Waffle, lastWaffle: Waffle) = firstLast(array: [
    Waffle(size: "large"),
    Waffle(size: "extra-large"),
    Waffle(size: "snack-size")
    ])

print(firstWaffle) // Waffle(size: "large")
print(lastWaffle) // Waffle(size: "snack-size")
```

That’s all it takes. Thanks to generics, you can use one function for an array holding `Int`, `String`, `Waffle`, or anything else, and you’re getting concrete types back. You aren’t juggling with `Any` or downcasting at runtime; the compiler declares everything at compile time.

##### Why Not Write Generics Straight Away?

Starting with a nongeneric function and later replacing all types with a generic is easier than starting to write a generic function from the get-go. But if you’re feeling confident, go ahead and write a generic function right away!

![7.1.2. Reasoning about generics](https://drek4537l1klr.cloudfront.net/veen/Figures/07fig01.jpg)

Reasoning about generics can be hard and abstract. Sometimes a `T` is a `String`, and at a different time it’s an `Int`, and so forth. You can wrap both an integer and a string inside an array via the use of a generic function as shown here.

##### Listing 7.7. Wrapping a value inside an array

```
func wrapValue<T>(value: T) -> [T] {
    return [value]
}
wrapValue(value: 30) // [30]
wrapValue(value: "Howdy!") // ["Howdy!"]
```

But you can’t specialize the type from *inside* the function body; this is to say, you can’t pass a `T` and turn it into an `Int` value from inside the function body.

##### Listing 7.8. A faulty generic function

```
func illegalWrap<T>(value: T) -> [Int] {
    return [value]
}
```

[Listing 7.8](https://livebook.manning.com/book/swift-in-depth/chapter-7/ch07list8) produces a Swift compiler error:

```
Cannot convert value of type ‘T’ to expected element type ‘Int’.
```

When working with generics, Swift generates specialized code at compile time. You can think of it as the generic `wrapValue` function turning into specialized functions for you to use, sort of like a prism where a white light goes in, and colors come out (see [figure 7.1](https://livebook.manning.com/book/swift-in-depth/chapter-7/ch07fig1) and the listing that follows).

![Figure 7.1. Generic code is turned to specialized code at compile time.](https://drek4537l1klr.cloudfront.net/veen/Figures/07fig02_alt.jpg)

##### Listing 7.9. The `wrapValue` function

```
// Given this generic function...
func wrapValue<T>(value: T) -> [T] { ... }

// ... you get access to specialized functions.
func wrapValue(value: Int) -> [Int] { ... }
func wrapValue(value: String) -> [String] { ... }
func wrapValue(value: YourOwnType) -> [YourOwnType] { ... }
```

Swift creates multiple `wrapValue` functions behind the scenes—a process called *monomorphization* where the compiler turns polymorphic code into concrete singular code. Swift is clever enough to prevent tons of code generation to prevent large binaries. Swift uses various tricks involving metadata to limit the amount of code generation. In this case, the compiler creates a low-level `wrapValue` function. Then, for relevant types, Swift generates metadata, called *value witness tables*. At runtime, Swift passes the corresponding metadata to the low-level representation of `wrapValue` when needed.

The compiler is smart enough to minimize the amount of metadata generated. Because Swift can make smart decisions about when and how to generate code, you don’t have to worry about large binary files—also known as *code bloat*—or extra-long compilation times!

Another significant benefit of generics in Swift is that you know what values you’re dealing with at compile time. If you were to inspect the return value of `wrapValue`—by Alt-clicking it in Xcode—you could already see that it returns a `[String]` or `[Int]`, or anything that you put in there. You can inspect types before you even consider running the application, making it easier to reason about polymorphic types.

#### 7.1.3. Exercise

1. Which of the following functions compile? Confirm this by running the code:

func wrap<T>(value: Int, secondValue: T) -> ([Int], U) {
return ([value], secondValue)
}
func wrap<T>(value: Int, secondValue: T) -> ([Int], T) {
return ([value], secondValue)
}

func wrap(value: Int, secondValue: T) -> ([Int], T) {
return ([value], secondValue)
}

func wrap<T>(value: Int, secondValue: T) -> ([Int], Int) {
return ([value], secondValue)
}

func wrap<T>(value: Int, secondValue: T) -> ([Int], Int)? {
if let secondValue = secondValue as? Int {
return ([value], secondValue)
} else {
return nil
}
}

copy

1. What’s the benefit of using generics over the `Any` type (for example, writing a function as `func<T>(process:` `[T])` versus `func(process:[Any])`)?

### 7.2. Constraining generics

Earlier, you saw how you worked with a generic type `T`, which could be anything. The generic `T` in your previous examples is an *unconstrained* generic. But when a type can be anything you also can’t do much with it.

You can narrow down what a generic represents by constraining it with a protocol; let’s see how this works.

#### 7.2.1. Needing a constrained function

Imagine that you want to write a generic function that gives you the lowest value inside an array. This function is set up generically so that it works on an array with any type, as shown here.

##### Listing 7.10. Running the `lowest` function

```
lowest([3,1,2]) // Optional(1)
lowest([40.2, 12.3, 99.9]) // Optional(12.3)
lowest(["a","b","c"]) // Optional("a")
```

The `lowest` function can return nil when the passed array is empty, which is why the values are optional.

Your first attempt is to create the function with a generic parameter of type `T`. But you’ll quickly discover in the following code that the function signature is lacking something.

##### Listing 7.11. The `lowest` function (will compile soon, but not yet)

```
// The function signature is not finished yet!
func lowest<T>(_ array: [T]) -> T? {
    let sortedArray = array.sorted { (lhs, rhs) -> Bool in    #1
         return lhs < rhs                                     #2
    }
    return sortedArray.first                                  #3
 }

lowest([1,2,3])
```

##### Lhs and Rhs

`lhs` stands for “left hand side.” `rhs` stands for “right hand side.” This is a convention when comparing two of the same types.

Unfortunately, [listing 7.11](https://livebook.manning.com/book/swift-in-depth/chapter-7/ch07list11) won’t work. Swift throws the following error:

```
error: binary operator '<' cannot be applied to two 'T' operands
        if lowest < value {
           ~~~~~~ ^ ~~~~~
```

The error occurs because `T` could be anything. Still, you’re performing actions on it, such as comparing the `T` with another `T` via the `<` operator. But since `T` represents anything, the `lowest` function doesn’t know it can compare `T` values.

Let’s find out how you can fix `lowest` with a protocol. First, you’ll take a little detour to learn about two key protocols, which you’ll need to finish the `lowest` function.

#### 7.2.2. The Equatable and Comparable protocols

Protocols define an interface with requirements, such as which functions or variables to implement. Types that conform to a protocol implement the required functions and variables. You’ve already observed this in earlier chapters when you made types conform to the `CustomStringConvertible` protocol or the `RawRepresentable` protocol.

The prevalent `Equatable` protocol allows you to check if two types are equal. Such types can be integers, strings, and many others, including your custom types:

```
5 == 5 // true
30231 == 2 // false
"Generics are hard!" == "Generics are easy!" // false
```

When a type conforms to the `Equatable` protocol, that type needs to implement the static `==` function, as shown here.

##### Listing 7.12. `Equatable`

```
public protocol Equatable {
  static func == (lhs: Self, rhs: Self) -> Bool
}
```

##### Note

For structs and enums, Swift can synthesize the `Equatable` implementation for you, which saves you from manually implementing the `==` method.

Another common protocol that Swift offers is `Comparable`. Types conforming to `Comparable` can be compared with each other, to see which value is more, or less, than the other value:

```
5 > 2 // true
3.2 <= 1.3 // false
"b" > "a" // true
```

Interestingly, `Comparable` also consists of static functions, but that’s not a requirement for protocols.

##### Listing 7.13. `Comparable`

```
public protocol Comparable : Equatable {            #1
   static func < (lhs: Self, rhs: Self) -> Bool     #2
   static func <= (lhs: Self, rhs: Self) -> Bool    #2
   static func >= (lhs: Self, rhs: Self) -> Bool    #2
   static func > (lhs: Self, rhs: Self) -> Bool     #2
 }
```

Both `Comparable` and `Equatable` are highly prevalent, and both live in the core Swift library.

#### 7.2.3. Constraining means specializing

Back to the problem. Your `lowest` function was comparing two `T` types, but `T` is not yet `Comparable`. You can specialize the `lowest` function by indicating that `T` conforms to `Comparable`, as shown here.

##### Listing 7.14. Constraining a generic

```
// Before. Didn't compile.
func lowest<T>(_ array: [T]) -> T? {

// After. The following signature is correct.
func lowest<T: Comparable>(_ array: [T]) -> T? {
```

Inside the `lowest` function scope, `T` represents anything that conforms to `Comparable`. The code compiles again and works on multiple `Comparable` types, such as integers, floats, strings, and anything else that conforms to `Comparable`.

Here’s the full `lowest` function.

##### Listing 7.15. The `lowest` function

```
func lowest<T: Comparable>(_ array: [T]) -> T? {
    let sortedArray = array.sorted { (lhs, rhs) -> Bool in
        return lhs < rhs
    }
    return sortedArray.first
}
```

You earlier recognized how `sorted` takes two values and returns a `Bool`. But `sorted` can use the power of protocols if all its elements are `Comparable`. You only need to call the `sorted` method without arguments, making the function body much shorter.

##### Listing 7.16. The `lowest` function (shortened)

```
func lowest<T: Comparable>(_ array: [T]) -> T? {
    return array.sorted().first
}
```

#### 7.2.4. Implementing Comparable

You can apply `lowest` to your types, too. First, create an enum conforming to `Comparable-`. This enum represents three royal ranks that you can compare. Then, you’ll pass an array of this enum to the `lowest` function.

##### Listing 7.17. The `RoyalRank` enum, adhering to `Comparable`

```
enum RoyalRank: Comparable {                                   #1
    case emperor
    case king
    case duke

    static func <(lhs: RoyalRank, rhs: RoyalRank) -> Bool {    #2
        switch (lhs, rhs) {                                    #3
          case (king, emperor): return true
          case (duke, emperor): return true
          case (duke, king): return true
          default: return false
        }
    }
```

To make `RoyalRank` adhere to `Comparable`, you usually would need to implement `==` from `Equatable`. Luckily, Swift synthesizes this method for you, saving you from writing an implementation. On top of this, you also would need to implement the four methods from `Comparable`. But you only need to implement the `<` method, because with the implementations for both the `<` and `==` methods, Swift can deduce all other implementations for `Comparable`. As a result, you only need to implement the `<` method, saving you from writing some boilerplate.

You made `RoyalRank` adhere to `Comparable`—and indirectly to `Equatable`—so now you can compare ranks against each other, or pass an array of them to your `lowest` function as in the following.

##### Listing 7.18. `Comparable` in action

```
let king = RoyalRank.king
let duke = RoyalRank.duke

duke < king // true
duke > king // false
duke == king // false

let ranks: [RoyalRank] = [.emperor, .king, .duke]
lowest(ranks) // .duke
```

One of the benefits of generics is that you can write functions for types that don’t even exist yet. If you introduce new `Comparable` types in the future, you can pass them to `lowest` without extra work!

#### 7.2.5. Constraining vs. flexibility

Not all types are `Comparable`. If you passed an array of Booleans, for instance, you’d get an error:

```
lowest([true, false])

error: in argument type '[Bool]', 'Bool' does not conform to expected type
     'Comparable'
```

Booleans do not conform to `Comparable`. As a result, the `lowest` function won’t work on an array with Booleans.

Constraining a generic means trading flexibility for functionality. A constrained generic becomes more specialized but is less flexible.

### 7.3. Multiple constraints

Often, one single protocol won’t solve all your problems when constraining to it.

Imagine a scenario where you not only want to keep track of the lowest values inside an array but also their occurrences. You would have to compare the values and probably store them in a dictionary to keep track of their occurrences. If you need a generic that can be compared and stored in a dictionary, you require that the generic conforms to both the `Comparable` and `Hashable` protocols.

You haven’t looked at the `Hashable` protocol yet; do that now before seeing how to constrain a generic to multiple protocols.

#### 7.3.1. The Hashable protocol

Types conforming to the `Hashable` protocol can be reduced to a single integer called a *hash value.* The act of hashing is done via a hashing function, which turns a type into an integer (see [figure 7.2](https://livebook.manning.com/book/swift-in-depth/chapter-7/ch07fig2)).

![Figure 7.2. In Swift, a hashing function turns a value into an integer.](https://drek4537l1klr.cloudfront.net/veen/Figures/07fig03.jpg)

##### Note

Hashing functions are a complex topic. Providing a deep understanding of them is outside the scope of this book.

`Hashable` types can be used as dictionary keys, or part of a `Set`, amongst other use cases. One common `Hashable` type is `String`.

##### Listing 7.19. A `String` as a `dictionary` key

```
let dictionary = [
    "I am a key": "I am a value",
    "I am another key": "I am another value",
]
```

Integers are also `Hashable`; they can also serve as dictionary keys or be stored inside a `Set`:

```
let integers: Set = [1, 2, 3, 4]
```

Many built-in types that are `Equatable` are also `Hashable`, such as `Int`, `String`, `Character-`, and `Double`.

##### TAKING A CLOSER LOOK AT THE HASHABLE PROTOCOL

The `Hashable` protocol defines a method that accepts a hasher; the implementing type can then feed values to this hasher. Note in this example that the `Hashable` protocol extends `Equatable`.

##### Listing 7.20. The `Hashable` protocol

```
public protocol Hashable : Equatable {      #1
   func hash(into hasher: inout Hasher)     #2
   // ... details omitted
}
```

Types adhering to `Hashable` need to offer the static `==` method from `Equatable` and the `func` `hash(into` `hasher:` `inout` `Hasher)` method from `Hashable`.

##### Note

Just like it can with `Equatable`, Swift can synthesize implementations for `Hashable` for free on structs and enums, which is showcased in section 7.4.

#### 7.3.2. Combining constraints

To create the `lowestOccurences` function as mentioned earlier, you need a generic type that conforms both to `Hashable` and `Comparable`. Conforming to two protocols is possible when you constrain a generic to multiple types, as shown in [figure 7.3](https://livebook.manning.com/book/swift-in-depth/chapter-7/ch07fig3) and [listing 7.21](https://livebook.manning.com/book/swift-in-depth/chapter-7/ch07list21).

![Figure 7.3. A generic that conforms to two protocols.](https://drek4537l1klr.cloudfront.net/veen/Figures/07fig04.jpg)

The `lowestOccurrence` function has a generic `T` type which is constrained to both the `Comparable` and `Hashable` protocols with the help of the `&` operator.

##### Listing 7.21. Combining constraints

```
func lowestOccurrences<T: Comparable & Hashable>(values: [T]) -> [T: Int] {
    // ... snip
}
```

Now `T` can be compared and put inside a dictionary inside the function body.

If a generic signature gets a bit hard to read, you can use a `where` clause, as an alternative, which goes at the end of a function, as shown here.

##### Listing 7.22. `where` clause

```
func lowestOccurrences<T>(values: [T]) -> [T: Int]     #1
     where T: Comparable & Hashable {                  #2
     // ... snip
}
```

These are two different styles of writing generic constraints, but they both work the same.

#### 7.3.3. Exercises

1. Write a function that, given an array, returns a dictionary of the occurrences of each element inside the array.
1. Create a logger that prints a generic type’s description and debug description when passed. Hint: Besides `CustomStringConvertible`, which makes sure types implement a description property, Swift also offers `CustomDebugStringConvertible`, which makes type implement a `debugDescription` property.

### 7.4. Creating a generic type

Thus far, you’ve been applying generics to your functions. But you can also make *types* generic.

In [chapter 4](https://livebook.manning.com/book/swift-in-depth/chapter-4/ch04), you delved into how `Optional` uses a generic type called `Wrapped` to store its value, as shown in the following listing.

##### Listing 7.23. The generic type `Wrapped`

```
public enum Optional<Wrapped> {
  case none
  case some(Wrapped)
}
```

Another generic type is `Array`. You write them as `[Int]` or `[String]` or something similar, which is syntactic sugar. Secretly, the syntax is `Array<Element>`, such as `Array<Int>`, which also compiles.

Let’s use this section to create your generic struct that helps you combine `Hashable` types. The goal is to make clear how to juggle multiple generics at once while you work with the `Hashable` protocol.

#### 7.4.1. Wanting to combine two Hashable types

Unfortunately, using two `Hashable` types as a key for a dictionary isn’t possible, even if this key consists out of two `Hashable` types. In particular, you can combine two strings—which are `Hashable`—into a tuple and try to pass it as a dictionary key as shown here.

##### Listing 7.24. Using a tuple as a key for a dictionary

```
let stringsTuple = ("I want to be part of a key", "Me too!")
let anotherDictionary = [stringsTuple: "I am a value"]
```

But Swift quickly puts a stop to it.

##### Listing 7.25. Error when using a tuple as a key

```
error: type of expression is ambiguous without more context
let anotherDictionary = [stringsTuple: "I am a value"]
                        ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```

As soon as you put two `Hashable` types inside a tuple, that tuple isn’t `Hashable` anymore. Swift doesn’t offer a way to combine the two hash values from a tuple. You’ll solve this problem by creating a `Pair` type that contains two `Hashable` properties.

#### 7.4.2. Creating a Pair type

You can combine two `Hashable` types by introducing a new generic struct that you’ll call `Pair`. The `Pair` type accepts two `Hashable` types and will be made `Hashable` itself, too, as shown in this listing.

##### Listing 7.26. `Pair` type in action

```
let keyPair = Pair("I want to be part of a key", "Me too!")
let anotherDictionary = [keyPair: "I am a value"] // This works.
```

`Pair` can store two types, which are `Hashable`. A first naive approach may be to declare a single generic `T`, as shown in the next listing.

##### Listing 7.27. Introducing `Pair`

```
struct Pair<T: Hashable> {          #1
    let left: T                     #2
    let right: T                    #3
 
    init(_ left: T, _ right: T) {
      self.left = left
      self.right = right
    }
}
```

`Pair` isn’t `Hashable` yet, but you’ll get to that shortly. First, there is a different problem—can you guess it?

#### 7.4.3. Multiple generics

Since `T` is used for both values, `Pair` gets specialized to types such as the following.

##### Listing 7.28. `Pair` is specialized: the `left` and `right` properties are of the same type

```
struct Pair {
  let left: Int
  let right: Int
}

struct Pair {
  let left: String
  let right: String
}
```

Currently, you can’t have a `Pair` where the `left` property is one type—such as a `String`—and the right property is something else, such as an `Int`.

##### Pop Quiz

Before continuing, can you guess how to fix `Pair` so that it accepts two separate types?

You can make sure that `Pair` accepts two separate (or the same) types by defining two different generics on `Pair`.

##### Listing 7.29. `Pair` accepts two generics

```
struct Pair<T: Hashable, U: Hashable> {       #1
    let left: T
    let right: U                              #2
 
    init(_ left: T, _ right: U) {             #3
      self.left = left
      self.right = right
    }
}
```

Now `Pair` can accept two different types, such as a `String` and `Int`, but also two similar types as shown here.

##### Listing 7.30. `Pair` accepts mixed types

```
// Pair accepts mixed types
let pair = Pair("Tom", 20)

// Same types such as two strings are still okay
let pair = Pair("Tom", "Jerry")
```

By introducing multiple generic types, `Pair` becomes more flexible because the compiler separately specializes the `T` and `U` types.

#### 7.4.4. Conforming to Hashable

Currently, `Pair` isn’t `Hashable` yet—you’ll fix that now.

To create a hash value for `Pair`, you have two options: you can let Swift synthesize the implementation for you, or you can create your own. First, do it the easy way where Swift synthesizes the `Hashable` implementation for you, saving you from writing boilerplate.

Introduced in version 4.1, Swift has a fancy technique called *conditional conformance*, which allows you to automatically conform certain types to the `Hashable` or `Equatable` protocol. If all its properties conform to these protocols, Swift synthesizes all the required methods for you. For instance, if all properties are `Hashable`, `Pair` can automatically be `Hashable`.

In this case, all you need to do is make `Pair` conform to `Hashable`, and you don’t need to give an implementation; this works as long as both `left` and `right` are `Hashable`, as in this example.

##### Listing 7.31. `Pair` accepts two generics

```
struct Pair<T: Hashable, U: Hashable>: Hashable {       #1
     let left: T                                        #2
     let right: U                                       #2
 
    // ... snip
}
```

Swift now creates a hash value for `Pair`. With little effort, you can use `Pair` as a `Hashable` type, such as adding them to a `Set`.

##### Listing 7.32. Adding a `Pair` to a `Set`

```
let pair = Pair<Int, Int>(10, 20)
print(pair.hashValue) // 5280472796840031924

let set: Set = [
  Pair("Laurel", "Hardy"),
  Pair("Harry", "Lloyd")
]
```

##### Being Explicit

Notice how you can explicitly specify the types inside the `Pair` by using the `Pair<Int,` `Int>` syntax.

Since `Pair` is `Hashable`, you can pass it a hasher, which `Pair` updates with values, as shown here.

##### Listing 7.33. Passing a hasher to `Pair`

```
let pair = Pair("Madonna", "Cher")
var hasher = Hasher()                         #1
hasher.combine(pair)                          #1
// alternatively: pair.hash(into: &hasher)    #2
let hash = hasher.finalize()                  #3
print(hash) // 4922525492756211419
```

There isn’t one winning hasher. Some hashers are fast, some are slow but more secure, and some are better at cryptography. Because you can pass custom hashers, you keep control of how and when to hash types. Then a `Hashable` type such as `Pair` keeps control of what to hash.

##### MANUALLY IMPLEMENTING HASHABLE

Swift can synthesize a `Hashable` implementation for structs and enums. But synthesizing `Equatable` and `Hashable` implementations won’t work on classes. Also, perhaps you’d like more control over them.

In these cases, implementing `Hashable` manually makes more sense. Let’s see how.

You can consolidate the hash values from the two properties inside `Pair` by implementing the `func` `hash(into` `hasher:` `inout` `Hasher)` method. In this method, you call `combine` for each value you want to include in the hashing operation. You also implement the static `==` method from `Equatable`, in which you compare both values from two pairs.

##### Listing 7.34. Implementing `Hashable` manually

```
struct Pair<T: Hashable, U: Hashable>: Hashable {

    // ... snip

    func hash(into hasher: inout Hasher) {                        #1
         hasher.combine(left)                                     #2
         hasher.combine(right)                                    #2
    }

    static func ==(lhs: Pair<T, U>, rhs: Pair<T, U>) -> Bool {    #3
         return lhs.left == rhs.left && lhs.right == rhs.right    #4
    }

}
```

Writing `Pair` took some steps, but you have a type that is flexible and highly reusable across projects. Which other generic structs can make your life easier? Perhaps a parser that turns a dictionary into a concrete type, or a struct that can write away any type to a file.

#### 7.4.5. Exercise

1. Write a generic cache that allows you to store values by `Hashable` keys.

### 7.5. Generics and subtypes

This section covers subclassing mixed with generics. It’s a bit theoretical, but it does shed a little light on some tricky situations if you want to understand generics on a deeper level.

Subclassing is one way to achieve polymorphism; generics are another. Once you start mixing the two, you must be aware of some rules, because generics become unintuitive once you intertwine these two polymorphism mechanisms. Swift hides many complexities behind polymorphism, so you usually don’t have to worry about theory. But you’re going to hit a wall sooner or later once you use subclassing in combination with generics, in which case a little theory can be useful. To understand subclassing and generics, you need to dive into a bit of theory called *subtype polymorphism* and *variance*.

#### 7.5.1. Subtyping and invariance

Imagine that you’re modeling data for an online education website where a subscriber can start specific courses. Consider the following class structure: the `OnlineCourse` class is a superclass for courses, such as `SwiftOnTheServer`, which inherits from `OnlineCourse`. You’re omitting the details to focus on generics, as given here.

##### Listing 7.35. Two classes

```
class OnlineCourse {
    func start() {
        print("Starting online course.")
    }
}

class SwiftOnTheServer: OnlineCourse {
    override func start() {
        print("Starting Swift course.")
    }
}
```

As a small reminder of subclassing in action: whenever an `OnlineCourse` is defined, such as on a variable, you can assign it to a `SwiftOnTheServer`, as shown in the next listing, since they both are of type `OnlineCourse`.

##### Listing 7.36. Assigning a subclass to superclass

```
var swiftCourse: SwiftOnTheServer = SwiftOnTheServer()
var course: OnlineCourse = swiftCourse // is allowed
course.start() // "Starting Swift course".
```

You could state that `SwiftOnTheServer` is a *subtype* of `OnlineCourse`. Usually, subtypes refer to subclassing. But sometimes a subtype isn’t about subclassing. For instance, an `Int` is a subtype of an optional `Int?`, because whenever an `Int?` is expected, you can pass a regular `Int`.

#### 7.5.2. Invariance in Swift

Passing a subclass when your code expects a superclass is all fine and dandy. But once a generic type wraps a superclass, you lose subtyping capabilities. For example, you’re introducing a generic `Container` holding a value of type `T`. Then you try to assign `Container<Swift-OnTheServer>` to `Container<OnlineCourse>`, just like before where you assigned `SwiftOnTheServer` to `OnlineCourse`. Unfortunately, you can’t do this, as shown in [figure 7.4](https://livebook.manning.com/book/swift-in-depth/chapter-7/ch07fig4).

![Figure 7.4. Subtyping doesn’t apply to Container](https://drek4537l1klr.cloudfront.net/veen/Figures/07fig05.jpg)

Even though `SwiftOnTheServer` is a subtype of `OnlineCourse`, `Container<Swift-OnTheServer>` is not a subtype of `Container<OnlineCourse>`, as demonstrated in this listing.

##### Listing 7.37. `Container`

```
struct Container<T> {}

var containerSwiftCourse: Container<SwiftOnTheServer> =
 Container<SwiftOnTheServer>()
var containerOnlineCourse: Container<OnlineCourse> = containerSwiftCourse

error: cannot convert value of type 'Container<SwiftOnTheServer>' to 
 specified type 'Container<OnlineCourse>'
```

Let’s see this shortcoming in a scenario slightly closer to real life. Imagine a generic `Cache` that stores data. You’d like to refresh a cache that holds online courses via the `refreshCache` method, as follows.

##### Listing 7.38. `Cache`

```
struct Cache<T> {
    // methods omitted
}
func refreshCache(_ cache: Cache<OnlineCourse>) {
    // ... snip
}
```

But here it shows again that, you can only pass `Cache<OnlineCourse>` types, but not `Cache<SwiftOnTheServer>`.

##### Listing 7.39. Invariance in action

```
refreshCache(Cache<OnlineCourse>()) // This is allowed
refreshCache(Cache<SwiftOnTheServer>()) // error: cannot convert 
 value of type 'Cache<SwiftOnTheServer>' to expected argument type
 'Cache<OnlineCourse>'
```

Swift’s generics are *invariant*, which states that just because a generic type wraps a subclass, it does *not* make it a subtype of a generic wrapping its superclass. My best guess why this is? Because Swift is relatively young, and invariance is a safe way to handle polymorphism until the language gets fleshed out more.

#### 7.5.3. Swift’s generic types get special privileges

To make things even more confusing, Swift’s generic types, such as `Array` or `Optional`, do allow for subtyping with generics. In other words, Swift’s types from the standard library do not have the limitation you just witnessed. Only the generics that you define yourself have the limitations.

For better comparison, write out optionals as their true generic counterpart; for example, `Optional<OnlineCourse>` instead of the syntactic sugar `OnlineCourse?`. Then you’ll pass an `Optional<SwiftOnTheServer>` to a function accepting an `Optional<OnlineCourse>`. Remember, this was illegal for your generic `Container`, but now it’s fine.

##### Listing 7.40. Swift’s types are covariant

```
func readOptionalCourse(_ value: Optional<OnlineCourse>) {
    // ... snip
}

readOptionalCourse(OnlineCourse()) // This is allowed.
readOptionalCourse(SwiftOnTheServer()) // This is allowed, Optional is covariant.
```

Swift’s built-in generic types are *covariant*, which means that generic types can be subtypes of other generic types. Covariance explains why you can pass an `Int` to a method expecting an `Int?`.

You’re flying economy while Swift’s types are enjoying extra legroom in the business class. Hopefully, it’s only a matter of time until your generic types can be covariant, too.

At first thought, it might be frustrating when you’re running into a situation where you want to mix generics and subclasses. Honestly, you can get pretty far without subclassing. In fact, if you’re not using specific frameworks that depend on subclassing, such as UIKit, you can deliver a complete application without subclassing at all. Making your classes `final` by default can also help to disincentivize subclassing and stimulate protocols and extensions to add functionality to classes. This book highlights multiple alternatives to subclassing that Swift offers.

### 7.6. Closing thoughts

Having read this chapter, I hope you feel confident in your ability to create generic components in your projects.

Abstractions come at a cost. Code becomes a bit more complicated and harder to interpret with generics. But you gain a lot of flexibility in return. With a bit of practice, it may seem like the *Matrix* (if you’re familiar with the film), where looking at these `T`, `U`, and `V` types will turn them into blondes, brunettes, and redheads, or perhaps `String`, `Int`, and `Float`.

The more comfortable you are with generics, the easier it is to shrink the size of your codebase and write more reusable components. I can’t express enough how important understanding generics on a fundamental level is, because generics keep returning in other chapters and in many Swift types in the wild.

### Summary

- Adding an unconstrained generic to a function allows a function to work with all types.
- Generics can’t be specialized from inside the scope of a function or type.
- Generic code is converted to specialized code that works on multiple types.
- Generics can be constrained for more specialized behavior, which may exclude some types.
- A type can be constrained to multiple generics to unlock more functionality on a generic type.
- Swift can synthesize implementations for the `Equatable` and `Hashable` protocols on structs and enums.
- Synthesizing default implementations doesn’t work on classes.
- Generics that you write are invariant, and therefore you cannot use them as subtypes.
- Generic types in the standard library are covariant, and you can use them as subtypes.

### Answers

1. Which of the functions will compile? Confirm this by running the code. This one will work:

func wrap<T>(value: Int, secondValue: T) -> ([Int], T) {
return ([value], secondValue)
}

copy

Also, this one will work:

func wrap<T>(value: Int, secondValue: T) -> ([Int], Int)? {
if let secondValue = secondValue as? Int {
return ([value], secondValue)
} else {
return nil
}
}

copy

1. What’s the benefit of using generics over the `Any` type (for example, writing a function as `func<T>(process:` `[T])` versus `func(process:[Any])`)? By using a generic, code is made polymorphic at compile time. By using `Any`, you have to downcast at runtime.
1. Write a function that, given an array, returns a dictionary of the occurrences of each element inside the array:

func occurrences<T: Hashable>(values: [T]) -> [T: Int] {
var groupedValues = [T: Int]()

for element in values {
groupedValues[element, default: 0] += 1
}

return groupedValues
}

print(occurrences(values: ["A", "A", "B", "C", "A"])) // ["C": 1,
"B": 1, "A": 3]

copy

1. Create a logger that will print a generic type’s description and `debugDescription` when passed:

struct CustomType: CustomDebugStringConvertible, CustomStringConvertible {
var description: String {
return  "This is my description"
}

var debugDescription: String {
return "This is my debugDescription"
}
}

struct Logger {
func log<T>(type: T)
where T: CustomStringConvertible & CustomDebugStringConvertible {
print(type.debugDescription)
print(type.description)
}
}

let logger = Logger()
logger.log(type: CustomType())

copy

1. Write a generic cache that allows you to store values by `Hashable` keys:

class MiniCache<T: Hashable, U> {

var cache = [T: U]()

init() {}

func insert(key: T, value: U) {
cache[key] = value
}

func read(key: T) -> U? {
return cache[key]
}

}

let cache = MiniCache<Int, String>()
cache.insert(key: 100, value: "Jeff")
cache.insert(key: 200, value: "Miriam")
cache.read(key: 200) // Optional("Miriam")
cache.read(key: 99) // Optional("Miriam")

copy
