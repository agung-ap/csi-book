# Chapter 10. Understanding map, flatMap, and compactMap

### ***This chapter covers***

- Mapping over arrays, dictionaries, and other collections
- When and how to `map` over optionals
- How and why to `flatMap` over collections
- Using `flatMap` on optionals
- Chaining and short-circuiting computations
- How to mix `map` and `flatMap` for advanced transformations

Modern languages like Swift borrow many concepts from the functional programming world, and `map` and `flatMap` are powerful examples of that. Sooner or later in your Swift career, you’ll run into (or write) code that applies `map` and `flatMap` operations on arrays, dictionaries, and even optionals. With `map` and `flatMap`, you can write hard-hitting, succinct code that is immutable—and therefore safer. Moreover, since version 4.1, Swift introduces `compactMap`, which is another refreshing operation that helps you perform effective transformations on optionals inside collections.

In fact, you may even be familiar with applying `map` and `flatMap` now and then in your code. This chapter takes a deep dive to show how you can apply `map` and `flatMap` in many ways. Also, it compares these operations against alternatives and looks at the trade-offs that come with them, so you’ll know exactly how to decide between a functional programming style or an imperative style.

This chapter flows well after reading [chapter 9](https://livebook.manning.com/book/swift-in-depth/chapter-9/ch09). If you haven’t read it yet, I recommend going back to that chapter before reading this one.

First, you’ll see how `map` works on arrays and how you can easily perform effective transformations via a pipeline. Also, you’ll find out how iterative *for* loops fare against the functional `map` method, so you’ll have some rules of thumb to pick between each style.

Then you’ll learn about mapping over dictionaries, and other types conforming to the `Sequence` protocol for an in-depth look.

After covering mapping over collections, you’ll find out more about mapping over optionals, which allows you to delay unwrapping of optionals and program a happy path in your program. Then you’ll see that `map` is an abstraction and how it’s beneficial to your code.

Being able to apply `flatMap` on optionals is the next big subject. You’ll see how `map` doesn’t always cut it when dealing with nested optionals, but luckily, `flatMap` can help.

Then, you’ll see how `flatMap` can help you fight nested *if let* unwrapping of optionals—sometimes referred to as the pyramid of doom. You’ll discover how you can create powerful transformations while maintaining high code readability.

Like `map`, `flatMap` is also defined on collections. This chapter covers `Collection` types, such as arrays and strings, to show how you can harness `flatMap` for succinct operations.

Taking it one step further, you’ll get a look at how optionals and collections are affected with `compactMap`. You’ll see how you can filter nils while transforming collections-.

As a cherry on top, you’ll explore the differences and benefits after you start nesting `map`, `flatMap`, and `compactMap` operations.

The goal of this chapter is to make sure you’re confident incorporating `map`, `flatMap`, and `compactMap` often in your daily programming. You’ll see how to write more concise code, as well as more immutable code, and learn some cool tips and tricks along the way, even if you’ve already been using `map` or `flatMap` from time to time. Another reason to get comfortable with `map` and `flatMap` is to prepare you for asynchronous error-handling in [chapter 11](https://livebook.manning.com/book/swift-in-depth/chapter-11/ch11), where `map` and `flatMap` will return.

### 10.1. Becoming familiar with map

##### Join Me!

It’s more educational and fun if you can check out the code and follow along with the chapter. You can download the source code at [http://mng.bz/mzr2](http://mng.bz/mzr2).

Receiving an array, looping over it, and transforming its values is a routine operation.

Suppose that you have the names and git commits of people on a project. You could create a more readable format to see if some developers are involved in a project. To transform the names and commits to a readable format, you start with a *for* loop to iterate over each value and use that to fill up the array you want.

##### Listing 10.1. Transforming an array

```
let commitStats = [                                                        #1
    (name: "Miranda", count: 30),
    (name: "Elly", count: 650),
    (name: "John", count: 0)
]

let readableStats = resolveCounts(statistics: commitStats)                 #2
print(readableStats) // ["Miranda isn't very active on the project", "Elly 
 is quite active", "John isn't involved in the project"]

func resolveCounts(statistics: [(String, Int)]) -> [String] {
     var resolvedCommits = [String]()                                      #3
     for (name, count) in statistics {                                     #4
         let involvement: String                                           #5
 
        switch count {                                                     #6
        case 0: involvement = "\(name) isn't involved in the project"
        case 1..<100: involvement =  "\(name) isn't active on the project"
        default: involvement =  "\(name) is active on the project"
        }

        resolvedCommits.append(involvement)                                #7
     }
    return resolvedCommits                                                 #8
 }
```

The *for* loop is a good start, but you have some boilerplate. You need a new variable array (`resolvedCommits`), which could theoretically be mutated by accident.

Now that the function is in place, you can easily refactor its body without affecting the rest of the program. Here, you’ll use `map` to turn this imperative style of looping into a `map` operation.

With `map`, you can iterate over each element and pass it to a closure that returns a new value. Then, you end up with a new array that contains the new values (see [figure 10.1](https://livebook.manning.com/book/swift-in-depth/chapter-10/ch10fig1)).

![Figure 10.1. A map operation on an array](https://drek4537l1klr.cloudfront.net/veen/Figures/10fig01_alt.jpg)

In code, this means you’re passing a closure to `map`, which gets called for each element in the array. In the closure, you return a new string, and the new array is built with these strings. After `map` finishes, `resolveCounts` returns this new mapped array.

##### Listing 10.2. Refactoring a *for* loop with `map`

```
func resolveCounts(statistics: [(String, Int)]) -> [String] {
    return statistics.map { (name: String, count: Int) -> String in        #1
         switch count {                                                    #2
         case 0: return "\(name) isn't involved in the project."           #3
         case 1..<100: return "\(name) isn't very active on the project."  #3
         default: return "\(name) is active on the project."               #3
         }
    }
}
```

Notice how the structure of the new array is intact. You end up with a new `Array`, with the same length, except its inner values are transformed.

Both the `map` approach and the *for* loop give the same results, but the `map` operation is shorter and immutable, which are two benefits. Another difference with a *for* loop is that with *for* you’re responsible for creating a new array, instead of letting the `map` function handle this for you.

#### 10.1.1. Creating a pipeline with map

Pipelines are an expressive way to describe the steps of data transformations. Let’s discover how this works.

Imagine that you have a function that again takes the names and commit counts. It returns only the counts, but sorted and with empty counts filtered out, such as the following:

`[(name:` `"Miranda",` `count:` `30),` `(name:` `"Elly",` `count:` `650),` `(name:` `"John",` `count:` `0)]` turns into `[650,` `30]`.

You can start with a *for* loop, and transform the array that way. Notice in the following listing how you can filter inside the `for` statement outside of the loop body.

##### Listing 10.3. Transforming data with a `for` loop

```
func counts(statistics: [(String, Int)]) -> [Int] {
    var counts = [Int]()                                 #1
    for (name, count) in statistics where count > 0 {    #2
         counts.append(count)
    }

    return counts.sorted(by: >)                          #3
 }
```

The *for* loop works fine as is. Alternatively, you can take a pipeline approach where you separately describe each step. Notice how for every step, a value goes in, and a value goes out, allowing you to connect the pieces of a pipeline in a modular fashion. You can express the intent of the operations quite elegantly, as shown here.

##### Listing 10.4. Transforming data with a pipeline

```
func counts(statistics: [(String, Int)]) -> [Int] {
    return statistics                                #1
         .map { $0.1 }                               #2
         .filter { $0 > 0 }                          #3
         .sorted(by: >)                              #4
 }
```

The `map` method is a crucial component in constructing a pipeline because it returns a new array. It helps you transform data while you can keep chaining, such as by sorting and filtering operations you apply.

A pipeline defines a clear and immutable way of transforming your data into separate steps. In contrast, if you perform many operations inside a single *for* loop, you risk ending up with a more complex loop and mutable arrays. The second downside of a *for* loop is that many actions can muddy up the loop, where you end up with hard-to-maintain or even buggy code.

The downside of this pipeline approach is that you perform at least two loops on this array: one for `filter`, one for `map`, and some iterations used by the `sorted` method, which doesn’t need to perform a full iteration. With a *for* loop, you can be more efficient by combining the `map` and `filter` in one loop (and also sorting if you want to reinvent the wheel). Generally speaking, a pipeline is performant enough and worth the expressive and immutable nature—Swift is fast, after all. But when absolute performance is vital, a *for* loop might be the better approach.

Another benefit of a *for* loop is that you can stop an iteration halfway with `continue`, `break`, or `return`. But with `map` or a pipeline, you’d have to perform a complete iteration of an array for every action.

Generally speaking, readability and immutability are more crucial than performance optimizations. Use what fits your scenario best.

#### 10.1.2. Mapping over a dictionary

An array isn’t the only type of collection you can `map` over. You can even `map` over dictionaries. For instance, if you have the commits data in the shape of a dictionary, you can again transform these into string values.

Before you work with dictionaries, as a tip, you can effortlessly turn your array of tuples into a dictionary via the `uniqueKeysWithValues` initializer on `Dictionary`, as shown in this code.

##### Listing 10.5. Turning tuples into a dictionary

```
print(commitStats) // [(name: "Miranda", count: 30), (name: "Elly", count:
     650), (name: "John", count: 0)]
let commitsDict = Dictionary(uniqueKeysWithValues: commitStats)
print(commitsDict) // ["Miranda": 30, "Elly": 650, "John": 0]
```

##### Unique Keys

If two tuples with the same keys are passed to `Dictionary (unique-KeysWithValues:)`, a runtime error occurs. For instance, if you pass `[(name:` `"Miranda",` `count:` `30),` `name:` `"Miranda",` `count` `40)]`, an application could crash. In that case, you may want to use `Dictionary(_:uniquing-KeysWith:)`.

Now that you own a dictionary, you can `map` over it, as shown here.

##### Listing 10.6. Mapping over a dictionary

```
print(commitsDict) // ["Miranda": 30, "Elly": 650, "John": 0]

let mappedKeysAndValues = commitsDict.map { (name: String, count: Int) ->
     String in
    switch count {
    case 0: return "\(name) isn't involved in the project."
    case 1..<100: return "\(name) isn't very active on the project."
    default: return "\(name) is active on the project."
    }
}

print(mappedKeysAndValues) // ["Miranda isn't very active on the project",
 "Elly is active on the project", "John isn't involved in the project"]
```

##### From Dictionary to Array

Be aware that going from a dictionary to an array means that you go from an unordered collection to an ordered collection, which may not be the correct ordering you’d like.

With `map`, you turned both a key and value into a single string. If you want, you can only `map` over a dictionary’s values. For instance, you can transform the counts into strings, while keeping the names in the dictionary, as in the next example.

##### Listing 10.7. Mapping over a dictionary’s values

```
let mappedValues = commitsDict.mapValues { (count: Int) -> String in
    switch count {
    case 0: return "Not involved in the project."
    case 1..<100: return "Not very active on the project."
    default: return "Is active on the project"
    }
}

print(mappedValues) // ["Miranda": "Very active on the project", "Elly": 
 "Is active on the project", "John": "Not involved in the project"]
```

Note that by using `mapValues`, you keep owning a dictionary, but with `map` you end up with an array.

#### 10.1.3. Exercises

1. Create a function that turns an array into a nested array. Make sure to use the `map` method. Given the following:

makeSubArrays(["a","b","c"]) // [[a], [b], [c]]
makeSubArrays([100,50,1]) // [[100], [50], [1]]

copy

1. Create a function that transforms the values inside a dictionary for movies. Each rating, from 1 to 5, needs to be turned into a human readable format (for example, a rating of 1.2 is “Very low”, a rating of 3 is “Average”, and a rating of 4.5 is “Excellent”):

let moviesAndRatings: [String : Float] = ["Home Alone 4" : 1.2, "Who
Framed Roger Rabbit?" : 4.6, "Star Wars: The Phantom Menace" : 2.2,
"The Shawshank Redemption" : 4.9]

let moviesHumanRadable = transformRating(moviesAndRatings)

print(moviesHumanRadable) // ["Home Alone 4": "Weak", "Star Wars: The
Phantom Menace": "Average", "Who Framed Roger Rabbit?": "Excellent",
"The Shawshank Redemption": "Excellent"]

copy

1. Still looking at movies and ratings, convert the dictionary into a single description per movie with the rating appended to the title. For example

let movies: [String : Float] = ["Home Alone 4" : 1.2, "Who framed Roger
Rabbit?" : 4.6, "Star Wars: The Phantom Menace" : 2.2, "The Shawshank
Redemption" : 4.9]

copy

turns into

["Home Alone 4 (Weak)", "Star Wars: The Phantom Menace (Average)",
"Who framed Roger Rabbit? (Excellent)", "The Shawshank Redemption
(Excellent)"]

copy

Try to use `map` if possible.

### 10.2. Mapping over sequences

You saw before how you could `map` over `Array` and `Dictionary` types. These types implement a `Collection` and `Sequence` protocol.

As an example, you can generate mock data—such as for tests or to fill up screens in a user interface—by defining some names, creating a `Range` of integers, and mapping over each iteration. In this case, you can quickly generate an array of names, as in this example.

##### Listing 10.8. Mapping over a `Range` sequence

```
let names = [                                  #1
    "John",
    "Mary",
    "Elizabeth"
]
let nameCount = names.count                    #2
 
let generatedNames = (0..<5).map { index in    #3
     return names[index % nameCount]           #4
}

print(generatedNames) // ["John", "Mary", "Elizabeth", "John", "Mary"]
```

With a `Range`, you can generate numbers; but by mapping over a range, you can generate values that can be something other than numbers.

Besides ranges, you can also apply `map` on `zip` or `stride` because they conform to the `Sequence` protocol. With `map`, you can generate lots of useful values and instances. Performing `map` on sequences and collections always returns a new `Array`, which is something to keep in mind when working with `map` on these types.

#### 10.2.1. Exercise

1. Generate an array of the letters “a”, “b”, and “c” 10 times. The end result should be [“a”, “b”, “c”, “a”, “b”, “c”, “a” …] until the array is 30 elements long. Try to use `map` if you can.

### 10.3. Mapping over optionals

At first, applying `map` may seem like a fancy way to update values inside of collections. But the `map` concept isn’t reserved for collections alone. You can also `map` over optionals. Strange, perhaps? Not really—it’s a similar concept to transforming a value inside a container.

Mapping over an array means that you transform its inside values. In contrast, mapping over an optional means that you transform its *single* value (assuming it has one). Mapping over a collection versus mapping over an optional isn’t so different after all. You’re going to get comfortable with it and wield its power.

#### 10.3.1. When to use map on optionals

Imagine that you’re creating a printing service where you can print out books with social media photos and their comments. Unfortunately, the printing service doesn’t support special characters, such as emojis, so you need to strip emojis from the texts.

Let’s see how you can use `map` to clean up your code while stripping emojis. But before you `map` over an optional, you’ll start with a way to strip emojis from strings, which you’ll use in the mapping operation.

##### STRIPPING EMOJIS

First, you need a function that strips the emojis from a `String`; it does so by iterating over the `unicodeScalars` view of a `String`, and removes each scalar that’s an emoji. You achieve this by calling the `isEmoji` property inside the `removeAll` method, as shown here.

##### Listing 10.9. The `removeEmojis` function

```
func removeEmojis(_ string: String) -> String {
     var scalars = string.unicodeScalars                   #1
     scalars.removeAll(where: { $0.properties.isEmoji })   #2
     return String(scalars)                                #3
}
```

Let’s continue and see how you can embed this in a mapping operation to clean up your code.

#### 10.3.2. Creating a cover

Back to your printing service. To create a printed photo book, you need to create a cover. This cover will always have an image, and it will have an optional title to display on top of the image.

The goal is to apply the `removeEmojis` function to the optional title, so that when a cover contains a title, the emojis will get stripped. This way, the emojis don’t end up as squares on a printed photo book (see [figure 10.2](https://livebook.manning.com/book/swift-in-depth/chapter-10/ch10fig2)).

![Figure 10.2. Removing emojis from a cover title](https://drek4537l1klr.cloudfront.net/veen/Figures/10fig02_alt.jpg)

In the following listing, you introduce the `Cover` class, which contains an optional `title` property. Because `removeEmojis` doesn’t accept an optional, you’ll first unwrap the title to apply the `removeEmojis` function.

##### Listing 10.10. The `Cover` class

```
class Cover {
    let image: UIImage
    let title: String?

    init(image: UIImage, title: String?) {
        self.image = image

        var cleanedTitle: String? = nil            #1
        if let title = title {                     #2
            cleanedTitle = removeEmojis(title)     #3
        }
        self.title = cleanedTitle                  #4
     }
}
```

You can condense (and improve) these four steps into a single step by mapping over the optional.

If you were to `map` over an optional, you’d apply the `removeEmojis()` function on the unwrapped value inside `map` (if there is one). If the optional is nil, the mapping operation is ignored (see [figure 10.3](https://livebook.manning.com/book/swift-in-depth/chapter-10/ch10fig3)).

![Figure 10.3. A map operation on two optionals](https://drek4537l1klr.cloudfront.net/veen/Figures/10fig03_alt.jpg)

In [listing 10.12](https://livebook.manning.com/book/swift-in-depth/chapter-10/ch10list12), you’ll see how mapping over an optional would look like inside your `Cover`.

##### Listing 10.11. Mapping over a title

```
class Cover {
    let image: UIImage
    let title: String?

    init(image: UIImage, title: String?) {
        self.image = image

        self.title = title.map { (string: String) -> String in      #1
             return removeEmojis(string)                            #2
        }
    }
}
```

Both operations give you the same output, which is a title without emojis, except you shortened the operation with `map`.

##### Inside Map

Notice how the value inside the `map` closure isn’t an optional. That’s the beauty of `map`: you don’t have to worry about a value being optional or not.

#### 10.3.3. A shorter map notation

You managed to shave off a few lines; big whoop, right? Let’s see if you can shorten it further.

You can start by using the shorthand notation of a closure:

```
self.title = title.map { removeEmojis($0) }
```

But all `map` needs is a function, closure or not, that takes an argument and returns a value. So instead of creating a closure, you can pass your existing function `remove-Emojis` straight to `map`:

```
self.title = title.map(removeEmojis)
```

Passing `removeEmojis` directly to `map` works because it’s a function that accepts one parameter and returns one parameter, which is exactly what `map` expects.

##### Note

The curly braces `{}` are replaced by parentheses `()` because you’re not creating a closure; you’re passing a function reference as a regular argument.

The end result, as shown in this listing, is now much shorter.

##### Listing 10.12. Clean mapping

```
class Cover {
    let image: UIImage
    let title: String?

    init(image: UIImage, title: String?) {
        self.image = image
        self.title = title.map(removeEmojis)
    }
}
```

By using `map`, you turned your multiline unwrapping logic into a clean, immutable one-liner. The `title` property remains an optional string, but its values are transformed when the passed `title` argument has a value.

##### BENEFITS OF MAPPING OVER OPTIONALS

An optional has a context: namely, whether or not a value is nil. With `map`, you could think of mapping over this context. Considering optionals in Swift are everywhere, mapping over them is a powerful tool.

You can perform actions on the optional as if the optional were unwrapped; this way you can delay unwrapping the optional. Also, the function you pass to `map` doesn’t need to know or deal with optionals, which is another benefit.

Applying `map` helps you remove boilerplate. Thanks to `map`, you’re not fiddling with temporary variables or manual unwrapping anymore. Programming in an immutable way is good practice because it saves you from variables changing right under your nose.

Another benefit of `map` is that you can keep chaining, as shown in the following listing. For example, besides removing emojis, you can also remove whitespace from the title by mapping over it twice.

##### Listing 10.13. Chaining `map` operations

```
class Cover {
    let image: UIImage
    let title: String?

    init(image: UIImage, title: String?) {
        self.image = image
        self.title = title.map(removeEmojis).map { $0.trimmingCharacters(in:
     .whitespaces) }
    }
}
```

[Listing 10.14](https://livebook.manning.com/book/swift-in-depth/chapter-10/ch10list14) `map`s over the same optional twice. First, you pass a `removeEmojis` function, and then a closure to trim the whitespace. The second `map` operation is done via a closure because you can’t pass a function reference in this case. Also, notice how you haven’t unwrapped the optional once, yet you performed multiple actions on it.

You end up with a small pipeline where you immutably apply mapping operations on the optional. Somewhere else in the application you can unwrap the optional to read the value. But until then, you can pretend that the optional isn’t nil and work with its inner value.

#### 10.3.4. Exercise

1. Given a contact data dictionary, the following code gets the street and city from the data and cleans up the strings. See if you can reduce the boilerplate (and be sure to use `map` somewhere):

let contact =
["address":

[
"zipcode": "12345",
"street": "broadway",
"city": "wichita"
]

]

func capitalizedAndTrimmed(_ string: String) -> String {
return string.trimmingCharacters(in: .whitespaces).capitalized
}
// Clean up this code:
var capitalizedStreet: String? = nil
var capitalizedCity: String? = nil

if let address = contact["address"] {
if let street = address["street"] {
capitalizedStreet = capitalizedAndTrimmed(street.capitalized)
}
if let city = address["city"] {
capitalizedCity = capitalizedAndTrimmed(city.capitalized)
}
}

print(capitalizedStreet) // Broadway
print(capitalizedCity) // Wichita

copy

### 10.4. map is an abstraction

With `map`, you can transform data while bypassing containers or contexts, such as arrays, dictionaries, or optionals.

Refer back to your method that strips emojis from a string, used in the previous section. Via the use of `map`, you can use the `removeEmojis` function on all types of containers, such as strings, dictionaries, or sets (see [figure 10.4](https://livebook.manning.com/book/swift-in-depth/chapter-10/ch10fig4)).

![Figure 10.4. Removing emojis on multiple types](https://drek4537l1klr.cloudfront.net/veen/Figures/10fig04_alt.jpg)

No matter whether you’re dealing with dictionaries, arrays, optionals, or sets, the `removeEmoji` works on any type via the use of `map`. You don’t need to write a `remove-Emojis` function separately for each type.

The `map` abstraction is called a *functor*, which is a name coming from the field of mathematics and category theory. Mathematics is something you don’t need to know about to use `map`. But it’s interesting to see how a functor defines something that you can `map` over, and that Swift borrows the `map` function from the functional programming world.

### 10.5. Grokking flatMap

Understanding `flatMap` can be a rite of passage in Swift. At first, `flatMap` is like a monster under your bed: it’s scary at first, but once you confront it, you’ll see that `flatMap` isn’t so bad.

![](https://drek4537l1klr.cloudfront.net/veen/Figures/10fig05.jpg)

This section’s goal is for you to develop an understanding of `flatMap`—going for that feeling of “That was it?”, like a magic trick being spoiled.

#### 10.5.1. What are the benefits of flatMap?

Let’s take the magic away: `flatMap` is a flatten operation after a `map` operation.

A flatten operation is useful when you’re applying `map`, but you end up with a nested type. For instance, while mapping you end up with `Optional(Optional(4))`, but you wish it were `Optional(4)`. Alternatively, you end up with `[[1,` `2,` `3],` `[4,` `5,` `6]]`, but you need `[1,` `2,` `3,` `4,` `5,` `6]`.

Simply put: with `flatMap` you combine nested structures.

It’s a little more involved than that—such as the ability to sequence operations while carrying contexts, or when you want to program happy paths—but you’ll get into that soon.

That’s all the theory for now. That wasn’t so bad, was it? Let’s get right to the fun parts.

#### 10.5.2. When map doesn’t cut it

Let’s take a look at how `flatMap` affects optionals.

Consider the following example where you want to transform an optional `String` to an optional `URL`. You naïvely try to use `map` and quickly see that it isn’t suited for this situation.

##### Listing 10.14. Transforming a `String` to `URL`

```
// You received this data.
let receivedData = ["url": "https://www.clubpenguinisland.com"]

let path: String? = receivedData["url"]

let url = path.map { (string: String) -> URL? in
    let url = URL(string: string) // Optional(https://www.clubpenguinisland.com)
    return url // You return an optional string
}

print(url) // Optional(Optional(http://www.clubpenguinisland.com))
```

In this scenario, an optional `String` is given to you; you’d like to transform it into an optional `URL` object.

The problem, however, is that the creation of a `URL` can return a nil value. `URL` returns nil when you pass it an invalid `URL`.

When you’re applying `map`, you’re returning a `URL?` object in the mapping function. Unfortunately, you end up with two optionals nested in each other, such as `Optional(Optional(http://www.clubpenguinisland.com))`.

When you’d like to remove one layer of nesting, you can force unwrap the optional. Easy, right? See the results in the following code.

##### Listing 10.15. Removing double nesting with a force unwrap

```
let receivedData = ["url": "https://www.clubpenguinisland.com"]

let path: String? = receivedData["url"]

let url = path.map { (string: String) -> URL in              #1
     return URL(string: string)!                             #2
 }

print(url) // Optional(http://www.clubpenguinisland.com).    #3
```

Hold your ponies.

Even though this solves your double-nested optional problem, you’ve now introduced a possible crash by using a force unwrap. In this example, the code works fine because the `URL` is valid. But in real-world applications, that might not be the case. As soon as the `URL` returns nil, you’re done for, and you have a crash.

Instead, as shown here, you can use `flatMap` to remove one layer of nesting.

##### Listing 10.16. Using `flatMap` to remove double-nested optional

```
let receivedData = ["url": "https://www.clubpenguinisland.com"]

let path: String? = receivedData["url"]

let url = path.flatMap { (string: String) -> URL? in        #1
     return URL(string: string)                             #2
 }

print(url) // Optional(http://www.clubpenguinisland.com).   #3
```

Note how you return a `URL?` again in the `flatMap` function. Just like with `map`, both closures are the same. But because you use `flatMap`, a flattening operation happens *after* the transformation. This flattening operation removes one layer of optional nesting.

`FlatMap` first performs a `map`, and then it flattens the optional. It can help to think of `flatMap` as `mapFlat`, because of the order of the operations.

By using `flatMap`, you can keep on transforming optionals and refrain from introducing those dreaded force unwraps.

#### 10.5.3. Fighting the pyramid of doom

A pyramid of doom is code that leans to the right via indentation. This pyramid shape is a result of a lot of nesting, such as when unwrapping multiple optionals.

Here’s another example when `map` won’t be able to help, but `flatMap` comes in handy to fight this pyramid.

![](data:image/svg+xml;utf8,%3Csvg%20xmlns=%22http://www.w3.org/2000/svg%22%20xmlns:xlink=%22http://www.w3.org/1999/xlink%22%20version=%221.1%22%20x=%220px%22%20y=%220px%22%20viewBox=%220%200%20446%20346%22%20xml:space=%22preserve%22%20height=%22346px%22%20width=%22446px%22%3E%20%3Crect%20width=%22446%22%20height=%22346%22%20style=%22fill:rgb(255,255,255);%22/%3E%3C/svg%3E)

To showcase fighting the pyramid of doom, let’s talk about the division of integers.

When you divide an integer, decimals get cut off:

```
print(5 / 2) // 2
```

When dividing an `Int`, dividing 5 by 2 returns 2 instead of 2.5, because `Int` doesn’t have floating point precision, as `Float` does.

The function in [listing 10.18](https://livebook.manning.com/book/swift-in-depth/chapter-10/ch10list18) halves an `Int` only when it’s even. If the `Int` is odd, the function returns nil.

The safe halving function takes a non-optional and returns an optional—for example, halving 4 becomes `Optional(2)`. But halving 5 returns nil because decimals would be cut off.

##### Listing 10.17. Safe halving function

```
func half(_ int: Int) -> Int? { // Only half even numbers
    guard int % 2 == 0 else { return nil }
    return int / 2
}
print(half(4)) // Optional(2)
print(half(5)) // nil
```

Next, you’re going to continuously apply this function.

You create a start value and halve it, which returns a new optional. If you halve the new value, you first have to unwrap the newly halved value before passing it on to `half`.

This chain of events creates a create a nasty tree of indented `if` `let` operations, also known as the pyramid of doom, as demonstrated here.

##### Listing 10.18. A pyramid of doom

```
var value: Int? = nil
let startValue = 80
if let halvedValue = half(startValue) {
    print(halvedValue) // 40
    value = halvedValue

    if let halvedValue = half(halvedValue) {
        print(halvedValue) // 20
        value = halvedValue

        if let halvedValue = half(halvedValue) {
            print(halvedValue) // 10
            if let halvedValue = half(halvedValue) {
                value = halvedValue
            } else {
                value = nil
            }

        } else {
            value = nil
        }
    } else {
        value = nil
    }
}

print(value) // Optional(5)
```

As you can see in this example, when you want to apply a function on a value continuously, you have to keep unwrapping the returned value. This nested unwrapping happens because `half` returns an optional each time.

Alternatively, you can group the *if let* statements in Swift, which is an idiomatic approach.

##### Listing 10.19. Combining *if let* statements

```
let startValue = 80
var endValue: Int? = nil

if
    let firstHalf = half(startValue),
    let secondHalf = half(firstHalf),
    let thirdHalf = half(secondHalf),
    let fourthHalf = half(thirdHalf) {
    endValue = fourthHalf
}
print(endValue) // Optional(5)
```

The downside of this approach is that you have to bind values to constants for each step, but naming each step can be cumbersome. Also, not all functions neatly accept one value and return another, which means that you would be chaining multiple closures, in which case the *if let* approach wouldn’t fit.

Let’s take a functional programming approach with `flatMap` and see if you can rewrite your code.

#### 10.5.4. flatMapping over an optional

Now you’re going to see how `flatMap` can be beneficial. Remember, `flatMap` is like `map`, except that it removes a layer of nesting after the mapping operation. You could, for example, have an `Optional(4)` and `flatMap` over it, applying the `half` function, which returns a new optional that `flatMap` flattens (see [figure 10.5](https://livebook.manning.com/book/swift-in-depth/chapter-10/ch10fig5) and [listing 10.21](https://livebook.manning.com/book/swift-in-depth/chapter-10/ch10list21)).

![Figure 10.5. A successful flatMap operation](data:image/svg+xml;utf8,%3Csvg%20xmlns=%22http://www.w3.org/2000/svg%22%20xmlns:xlink=%22http://www.w3.org/1999/xlink%22%20version=%221.1%22%20x=%220px%22%20y=%220px%22%20viewBox=%220%200%20590%20156%22%20xml:space=%22preserve%22%20height=%22156px%22%20width=%22590px%22%3E%20%3Crect%20width=%22590%22%20height=%22156%22%20style=%22fill:rgb(255,255,255);%22/%3E%3C/svg%3E)

You can see that if you `flatMap` the `half` function over `Optional(4)`, you end up with `Optional(2)`. With `map` you would end up with `Optional(Optional(2))`.

##### Listing 10.20. Halving with `flatMap`

```
let startValue = 8
let four = half(startValue) // Optional(4)
let two = four.flatMap { (int: Int) -> Int? in
    print(int) // 4
    let nestedTwo = half(int)
    print(nestedTwo) // Optional(2)
    return nestedTwo
}

print(two) // Optional(2)
```

The beauty of using `flatMap` is that you keep a regular optional, which means that you can keep chaining operations on it.

##### Listing 10.21. Multiple halving operations on `flatMap`

```
let startValue = 40
let twenty = half(startValue) // Optional(20)
let five =
    twenty
        .flatMap { (int: Int) -> Int? in
            print(int) // 20
            let ten = half(int)
            print(ten) // Optional(10)
            return ten
        }.flatMap { (int: Int) -> Int? in
            print(int) // 10
            let five = half(int)
            print(five) // Optional(5)
            return five
}

print(five) // Optional(5)
```

Because you never nest an optional more than once, you can keep chaining forever, or just twice, as in this example. You are getting rid of the ugly nested *if let* pyramid of doom. As a bonus, you aren’t manually keeping track of a temporary value anymore while juggling *if let* statements.

##### SHORTCIRCUITING WITH FLATMAP

Because `flatMap` allows you to keep chaining nullable operations, you get another benefit: you can break off chains if needed.

When you return nil from a `flatMap` operation, you end up with a regular nil value instead. Returning nil from a `flatMap` operation means that subsequent `flatMap` operations are ignored.

In the next example, you halve `5` and `flatMap` over it. You end up with a nil; the result is the same as starting with a nil (see [figure 10.6](https://livebook.manning.com/book/swift-in-depth/chapter-10/ch10fig6)).

![Figure 10.6. flatMap and nil values](data:image/svg+xml;utf8,%3Csvg%20xmlns=%22http://www.w3.org/2000/svg%22%20xmlns:xlink=%22http://www.w3.org/1999/xlink%22%20version=%221.1%22%20x=%220px%22%20y=%220px%22%20viewBox=%220%200%20590%20304%22%20xml:space=%22preserve%22%20height=%22304px%22%20width=%22590px%22%3E%20%3Crect%20width=%22590%22%20height=%22304%22%20style=%22fill:rgb(255,255,255);%22/%3E%3C/svg%3E)

When you have a nil optional, subsequent `flatMap` operations are ignored. Because you can return nil from the `flatMap` closure, you can short-circuit a chained operation.

In the next example, see what happens if you keep on chaining, even when a `flatMap` operation returns nil.

##### Listing 10.22. Short-circuiting

```
let startValue = 40
let twenty = half(startValue) // Optional(20)
let someNil =
    twenty
        .flatMap { (int: Int) -> Int? in
            print(int) // 20
            let ten = half(int)
            print(ten) // Optional(10)
            return ten
        }.flatMap { (int: Int) -> Int? in
            print(int) // 10
            let five = half(int)
            print(five) // Optional(5)
            return five
        }.flatMap { (int: Int) -> Int? in           #1
            print(int) // 5
            let someNilValue = half(int)
            print(someNilValue) // nil
            return someNilValue                     #2
         }.flatMap { (int: Int) -> Int? in          #3
            return half(int)                        #4
 }

print(someNil) // nil
```

`flatMap` ignores the passed closures as soon as a `nil` is found. This is the same as mapping over an optional, which also won’t do anything if a `nil` is found.

Notice how the third `flatMap` operation returns nil, and how the fourth `flatMap` operation is ignored. The result remains `nil`, which means that `flatMap` gives you the power to break off chained operations.

You let `flatMap` handle any failed conversions, and you can focus on the happy path of the program instead!

Moreover, to finalize and clean up your code, you can use a shorter notation, as you did before, where you pass a named function to `map`. You can do the same with `flatMap`, as shown here.

##### Listing 10.23. A shorter notation

```
let endResult =
    half(80)
        .flatMap(half)
        .flatMap(half)
        .flatMap(half)
print(endResult) // Optional(5)
```

Generally, combining *if let* statements is the way to go because it doesn’t require in-depth `flatMap` knowledge. If you don’t want to create intermediate constants, or if you’re working with multiple closures, you can use a `flatMap` approach for concise code.

As shown in the following example, imagine a scenario where you’d find a user by an id, find the user’s favorite product, and see if any related product exists. The last step formats the data. Any of these steps could be a function or a closure. With `flatMap` and `map`, you can cleanly chain transformations without resorting to a big stack of `if` `let` constants and intermediary values.

##### Listing 10.24. Finding related products

```
let alternativeProduct =
    findUser(3)
      .flatMap(findFavoriteProduct)
      .flatMap(findRelatedProduct)
      .map { product in
        product.description.trimmingCharacters(in: .whitespaces)
      }
```

### 10.6. flatMapping over collections

You might have guessed that `flatMap` isn’t reserved just for optionals, but for collections as well.

Just like `flatMap` ends up flattening two optionals, it also flattens a nested collection after a mapping operation.

For instance, you can have a function that generates a new array from each value inside an array—for example, turning `[2,` `3]` into `[[2,` `2],` `[3,` `3]]`. With `flatMap` you can flatten these subarrays again to a single array, such as `[2,` `2,` `3,` `3]` (see [figure 10.7](https://livebook.manning.com/book/swift-in-depth/chapter-10/ch10fig7)).

![Figure 10.7. Flattening a collection with flatMap](data:image/svg+xml;utf8,%3Csvg%20xmlns=%22http://www.w3.org/2000/svg%22%20xmlns:xlink=%22http://www.w3.org/1999/xlink%22%20version=%221.1%22%20x=%220px%22%20y=%220px%22%20viewBox=%220%200%20590%20218%22%20xml:space=%22preserve%22%20height=%22218px%22%20width=%22590px%22%3E%20%3Crect%20width=%22590%22%20height=%22218%22%20style=%22fill:rgb(255,255,255);%22/%3E%3C/svg%3E)

In code this would look as follows.

##### Listing 10.25. Repeating values

```
let repeated = [2, 3].flatMap { (value: Int) -> [Int] in
    return [value, value]
}

print(repeated) // [2, 2, 3, 3]
```

Also, consider the following, where you start with a nested array of values. With `flatMap`, you flatten the subarrays to a single array.

##### Listing 10.26. Flattening a nested array

```
let stringsArr = [["I", "just"], ["want", "to"], ["learn", "about"],
     ["protocols"]]
let flattenedArray = stringsArr.flatMap { $0 }                            #1
 print(flattenedArray) // ["I", "just", "want", "to", "learn", "about",
     "protocols"]
```

Notice how you’re not performing anything particular in the `flatMap` closure in this case.

#### 10.6.1. flatMapping over strings

`String` is a collection, too. As you saw earlier, you can iterate over a view on a `String`, such as `unicodeScalars`. Depending on the “view” of `String` you pick, you can also iterate over the utf8 and utf16 code units of `String`.

If you were to iterate over a `String` itself, you would iterate over its characters. Because `String` conforms to the `Collection` protocol, you can `flatMap` over a `String` as well.

For instance, you can create a succinct `interspersed` method on `String`, which takes a `Character` and intersperses or weaves a character between each character of the string (as in this example, turning “Swift” into “S-w-i-f-t”).

##### Listing 10.27. `interspersed`

```
"Swift".interspersed("-") // S-w-i-f-t

extension String {                                                         #1
     func interspersed(_ element: Character) -> String {
        let characters = self.flatMap { (char: Character) -> [Character] in#2
             return [char, element]                                        #3
             }.dropLast()                                                  #4
 
        return String(characters)                                          #5
     }
}
```

You can write the method in a shorthanded manner, too, by omitting explicit types.

##### Listing 10.28. Shorthanded `interspersed` method

```
extension String {
    func interspersed(_ element: Character) -> String {
        let characters = self.flatMap { return [$0, element] }.dropLast()
        return String(characters)
    }
}
```

#### 10.6.2. Combining flatMap with map

Once you start nesting `flatMap` with other `flatMap` or `map` operations, you can create powerful functionality with a few lines of code. Imagine that you need to create a full deck of cards. You can create this in very few lines once you combine `map` and `flatMap`.

First, you define the suits and faces. Then you iterate through the suits, and for each suit, you iterate through the faces. To create your deck, you’re nesting `flatMap` and `map` so that you have access to both the suit and the face at the same time. This way, you can effortlessly create tuple pairs for each card.

As shown here, in the end, you use the `shuffle()` method, which shuffles `deckOfCards` in place.

##### Listing 10.29. Generating a deck of cards

```
let suits = ["Hearts", "Clubs", "Diamonds", "Spades"]                          #1
let faces = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"] #1
 
var deckOfCards = suits.flatMap { suit in                                      #2
     faces.map { face in                                                       #3
         (suit, face)                                                          #4
     }
}
deckOfCards.shuffle()                                                          #5
print(deckOfCards) // [("Diamonds", "5"), ("Hearts", "8"), ("Hearts", "K"),
 ("Clubs", "3"), ("Diamonds", "10"), ("Spades", "A"), ...
```

##### Tip

You shuffle `deckOfCards` in place, but you can also get a fresh copy with the `shuffled()` method.

The reason you use `flatMap` on the `suits` array is because mapping over `faces` returns an array, causing you to end up with nested arrays. With `flatMap` you remove one layer of nesting so that you neatly end up with an array of tuples.

#### 10.6.3. Using compactMap

For collections, such as `Array`, `String`, or `Dictionary`, there is a little brother of `flatMap` called `compactMap`. With `compactMap`, instead of flattening a nested collection, you can flatten optionals inside a collection.

In simpler terms, you can filter nils out of a collection. As you’ve seen before, not every `String` can be turned into a `URL`, resulting in an optional `URL` type, as in this example.

##### Listing 10.30. Creating optional `URLs`

```
let wrongUrl = URL(string: "OMG SHOES")
print(wrongUrl) // nil
let properUrl = URL(string: "https://www.swift.org")
print(properUrl) // Optional(https://www.swift.org)
```

If you were to fill up an array with strings and try to convert these to `URL` types via `map`, you would end up with an array of optional integers, as shown here.

##### Listing 10.31. Mapping over an array

```
let strings = [
    "https://www.duckduckgo.com",
    "https://www.twitter.com",
    "OMG SHOES",
    "https://www.swift.org"
]

let optionalUrls = strings.map { URL(string: $0) }
print(optionalUrls) // [Optional(https://www.duckduckgo.com), 
 Optional(https://www.twitter.com), nil, Optional(https://www.swift.org)]
```

Notice how `"OMG SHOES"` can’t be turned into an `URL`, resulting in a `nil` value inside the array.

Again, with `compactMap` you can flatten this operation, except this time, flattening the array means removing the nil optionals. This way, as shown in this listing, you end up with a non-optional list of URLs.

##### Listing 10.32. Flattening an optional array

```
let urls = strings.compactMap(URL.init)
print(urls) // [https://www.duckduckgo.com, https://www.twitter.com, https://
    www.swift.org]
```

Because not all strings can be turned into `URL` types, `URL.init` returns an optional `URL`. Then `compactMap` filters out these `nil` values. For instance, you can’t turn `"OMG SHOES"` into a `URL`, so `compactMap` filters out this `nil` for you. The result is that you end up with proper URLs where none are optional.

If a *for* loop is more your cup of tea, you can use one to filter an optional array as well via a `case` `let` expression, as in [listing 10.34](https://livebook.manning.com/book/swift-in-depth/chapter-10/ch10list34). This expression allows you to pattern match on an enum’s case, such as optionals (because optionals are enums). For instance, you can obtain an array with optional `URL` types and loop over them, filtering any nils, and end up with an unwrapped value inside the loop.

##### Listing 10.33. Using a *for* loop to filter an optional array

```
let optionalUrls: [URL?] = [
    URL(string: "https://www.duckduckgo.com"),
    URL(string: "Bananaphone"),
    URL(string: "https://www.twitter.com"),
    URL(string: "https://www.swift.org")
]
for case let url? in optionalUrls {
    print("The url is \(url)") // url is unwrapped here
}

// Output:
// The url is https://www.duckduckgo.com
// The url is https://www.twitter.com
// The url is https://www.swift.org
```

As mentioned before, with *for* loops you get the benefit of using `break`, `continue`, or `return` to break loops halfway.

#### 10.6.4. Nesting or chaining

A nice trick with `flatMap` and `compactMap` is that it doesn’t matter whether you nest or chain `flatMap` or `compactMap` operations. For instance, you could `flatMap` over an `Optional` twice in a row. Alternatively, you can nest two `flatMap` operations. Either way, you end up with the same result:

```
let value = Optional(40)
let lhs = value.flatMap(half).flatMap(half)
let rhs = value.flatMap { int in half(int).flatMap(half) }
lhs == rhs // true
print(rhs) // Optional(10)
```

Another benefit of the nested `flatMap` or `compactMap` approach is that you can refer to encapsulated values inside a nested closure.

For instance, you can both `flatMap` and `compactMap` over the same `String`. First, each element inside the string is bound to `a` inside a `flatMap` operation; then you `compactMap` over the same string again, but you’ll bind each element to `b`. You end up with a way to combine `a` and `b` to build a new list.

Using this technique as shown next, you build up an array of unique tuples from the characters in the same `string`.

##### Listing 10.34. Combining characters from a `string`

```
let string = "abc"
let results = string.flatMap { a -> [(Character, Character)] in     #1
     string.compactMap { b -> (Character, Character)? in            #2
        if a == b {                                                 #3
            return nil                                              #4
        } else {
            return (a, b)
        }
    }
}
print(results) // [("a", "b"), ("a", "c"), ("b", "a"), ("b", "c"), ("c", "a"),
     ("c", "b")]                                                    #5
```

It’s a small trick, but knowing that `flatMap` and `compactMap` can be chained or nested can help you refactor your code in different ways for similar results.

#### 10.6.5. Exercises

1. Create a function that turns an array of integers into an array with a value subtracted and added for each integer—for instance, [20, 30, 40] is turned into [19, 20, 21, 29, 30, 31, 39, 40, 41]. Try to solve it with the help of `map` or `flatMap`.
1. Generate values from 0 to 100, with only even numbers. But be sure to skip every factor of 10, such as 10, 20, and so on. You should end up with [2, 4, 6, 8, 12, 14, 16, 18, 22 …]. See if you can solve it with the help of `map` or `flatMap`.
1. Create a function that removes all vowels from a `string`. Again, see if you can solve it with `map` or `flatMap`.
1. Given an array of tuples, create an array with tuples of all possible tuple pairs of these values—for example, [1, 2] gets turned into [(1, 1), (1, 2), (2, 1), (2, 2)]. Again, see if you can do it with the help from `map` and/or `flatMap` and make sure that there are no duplicates.
1. Write a function that duplicates each value inside an array—for example, [1, 2, 3] turns into [1, 1, 2, 2, 3, 3] and [[“a”, “b”],[“c”, “d”]], turns into [[“a”, “b”], [“a”, “b”], [“c”, “d”], [“c”, “d”]]. See if you can use `map` or `flatMap` for this.

### 10.7. Closing thoughts

Depending on your background, a functional style of programming can feel a bit foreign. Luckily, you don’t need functional programming to create spectacular applications. But by adding `map` and `flatMap` to your toolbelt, you can harness their powers and add powerful immutable abstractions to your code in a succinct manner.

Whether you prefer an imperative style or a functional style to programming, I hope you feel confident picking an approach that creates a delicate balance between readability, robustness, and speed.

### Summary

- The `map` and `flatMap` methods are concepts taken from the functional programming world.
- The `map` method is an abstraction called a *functor*.
- A functor represents a container—or context—of which you can transform its value with `map`.
- The `map` method is defined on many types, including `Array`, `Dictionary`, `Sequence`, and `Collections` protocol, and `Optional`.
- The `map` method is a crucial element when transforming data inside a pipeline.
- Imperative-style programming is a fine alternative to functional, style programming.
- Imperative-style programming can be more performant. In contrast, functional-style programming can involve immutable transformations and can sometimes be more readable and show clearer intent.
- The `flatMap` method is a flatten operation after a `map` operation.
- With `flatMap` you can flatten a nested optional to a single optional.
- With `flatMap` you can sequence operations on an optional in an immutable way.
- Once an optional is nil, `map` and `flatMap` ignores any chained operations.
- If you return `nil` from a `flatMap`, you can short-circuit operations.
- With `flatMap` you can transform arrays and sequences in powerful ways with very little code.
- With `compactMap` you can filter `nils` out of arrays and sequences of optionals.
- You can also filter `nils` with an imperative style by using a *for* loop.
- You can nest `flatMap` and `compactMap` operations for the same results.
- On collections and sequences, you can combine `flatMap` with `map` to combine all their values.

### Answers

1. Create a function that turns an array into a nested array, make sure to use the `map` function:

func makeSubArrays<T>(_ arr: [T]) -> [[T]] {
return arr.map { [$0] }
}

makeSubArrays(["a","b","c"]) // [[a], [b], [c]]
makeSubArrays([100,50,1]) // [[100], [50], [1]]

copy

1. Create a function that transforms the values inside a dictionary for movies. Each rating, from 1 to 5, needs to be turned into a human readable format:

// E.g.
// A rating of 1.2 is "Very low", a rating of 3 is "Average", a rating
of 4.5 is "Excellent".

func transformRating<T>(_ dict: [T: Float]) -> [T: String] {
return dict.mapValues { (rating) -> String in
switch rating {
case ..<1: return "Very weak"
case ..<2: return "Weak"
case ..<3: return "Average"
case ..<4: return "Good"
case ..<5: return "Excellent"
default: fatalError("Unknown rating")
}
}
}

let moviesAndRatings: [String : Float] = ["Home Alone 4" : 1.2,
"Who framed Roger Rabbit?" : 4.6, "Star Wars: The Phantom Menace"
: 2.2, "The Shawshank Redemption" : 4.9]
let moviesHumanRadable = transformRating(moviesAndRatings)

copy

1. Still looking at the movies and ratings, convert the dictionary into a single description per movie with the rating appended to the title:

let movies: [String : Float] = ["Home Alone 4" : 1.2, "Who framed Roger
Rabbit?" : 4.6, "Star Wars: The Phantom Menace" : 2.2, "The Shawshank
Redemption" : 4.9]

func convertRating(_ rating: Float) -> String {
switch rating {
case ..<1: return "Very weak"
case ..<2: return "Weak"
case ..<3: return "Average"
case ..<4: return "Good"
case ..<5: return "Excellent"
default: fatalError("Unknown rating")
}
}
let movieDescriptions = movies.map { (tuple) in
return "\(tuple.key) (\(convertRating(tuple.value)))"
}

print(movieDescriptions) // ["Home Alone 4 (Weak)", "Star Wars: The
Phantom Menace (Average)", "Who framed Roger Rabbit? (Excellent)",
"The Shawshank Redemption (Excellent)"]

copy

1. Generate an array of the letters “a”, “b”, “c” 10 times. The end result should be [“a”, “b”, “c”, “a”, “b”, “c”, “a” …]. The array should be 30 elements long. See if you can solve this with a `map` operation on some kind of iterator:

let values = (0..<30).map { (int: Int) -> String in
switch int % 3 {
case 0: return "a"
case 1: return "b"
case 2: return "c"
default: fatalError("Not allowed to come here")
}
}

print(values)

copy

1. Given a contact data dictionary, the following code gets the street and city from the data and cleans up the strings. See if you can reduce the boilerplate. Be sure to use `map` somewhere:

let someStreet = contact["address"]?["street"].map(capitalizedAndTrimmed)
let someCity = contact["address"]?["city"].map(capitalizedAndTrimmed)

copy

1. Create a function that turns an array of integers into an array with a value subtracted and added for each integer. For instance, [20, 30, 40] will be turned into [19, 20, 21, 29, 30, 31, 39, 40, 41]. Try to solve it with the help of `map` or `flatMap`:

func buildList(_ values: [Int]) -> [Int] {
return values.flatMap {
[$0 - 1, $0, $0 + 1]
}
}

copy

1. Generate values from 0 to 100, with only even numbers. But be sure to skip every factor of 10, such as 10, 20, and so on. You would end up with [2, 4, 6, 8, 12, 14, 16, 18, 22 …]. See if you can solve it with the help of `map` or `flatMap`:

let strideSequence = stride(from: 0, through: 30, by: 2).flatMap { int in
return int % 10 == 0 ? nil : int
}

copy

1. Create a function that removes all vowels from a string. Again, see if you can solve it with `map` or `flatMap`:

func removeVowels(_ string: String) -> String {
let characters = string.flatMap { char -> Character? in
switch char {
case "e", "u", "i", "o", "a": return nil
default: return char
}
}

return String(characters)
}

removeVowels("Hi there!") // H thr!

copy

1. Given an array of tuples, create an array with tuples of all possible tuple pairs of these values—for example, [1, 2] gets turned into [(1, 1), (1, 2), (2, 1), (2, 2)]. Again, see if you can do it with the help from `map` and/or `flatMap`:

func pairValues(_ values: [Int]) -> [(Int, Int)] {
return values.flatMap { lhs in
values.map { rhs -> (Int, Int) in
return (lhs, rhs)
}
}
}

copy

1. Write a function that duplicates each value inside an array—for example, [1, 2, 3] turns into [1, 1, 2, 2, 3, 3], and [[“a”, “b”],[“c”, “d”]] turns into [[“a”, “b”], [“a”, “b”], [“c”, “d”], [“c”, “d”]]. See if you can use `map` or `flatMap` for this:

func double<T>(_ values: [T]) -> [T] {
return values.flatMap { [$0, $0] }
}

print(double([1,2,3]))
print(double([["a", "b"], ["c", "d"]]))

copy
