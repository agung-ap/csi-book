# Chapter 3. Writing cleaner properties

### ***This chapter covers***

- How to create getter and setter computed properties
- When (not) to use computed properties
- Improving performance with lazy properties
- How lazy properties behave with structs and mutability
- Handling stored properties with behavior

Cleanly using properties can thoroughly simplify the interface of your structs, classes, and enums, making your code safer and easier to read and use for others (and your future self). Because properties are a core part of Swift, following the pointers in this chapter can help the readability of your code straight away.

First, we cover *computed* properties, which are functions that look like properties. Computed properties can clean up the interface of your structs and classes. You’ll see how and when to create them, but also when it’s better to avoid them.

Then we explore *lazy* properties, which are properties that you can initialize at a later time or not at all. Lazy properties are convenient for some reasons, such as when you want to optimize expensive computations. You’ll also witness the different behaviors lazy properties have in structs versus classes.

Moreover, you’ll see how you can trigger custom behavior on properties via so-called property observers and the rules and quirks that come with them.

By the end of this chapter, you’ll be able to accurately choose between lazy properties, stored properties, and computed properties so that you can create clean interfaces for your structs and classes.

### 3.1. Computed properties

Computed properties are functions *masquerading* as properties. They do not store any values, but on the outside, they look the same as stored properties.

For instance, you could have a countdown timer in a cooking app and you could check this timer to see if your eggs are boiled, as shown in the following listing.

##### Listing 3.1. A countdown timer

```
cookingTimer.secondsRemaining  // 411
```

However, this value changes over time as shown here.

##### Listing 3.2. Value changes over time with computed properties

```
12345cookingTimer.secondsRemaining  // 409
// wait a bit
cookingTimer.secondsRemaining  // 404
// wait a bit
cookingTimer.secondsRemaining  // 392
```

Secretly, this property is a function because the value keeps dynamically changing.

The remainder of this section explores the benefits of computed properties. You’ll see how they can clean up the interface of your types. You’ll also see how computed properties run code each time a property is accessed, giving your properties a dynamic “always up to date” nature.

Then section 3.2 highlights when *not* to use computed properties and how lazy properties are sometimes the better choice.

#### 3.1.1. Modeling an exercise

Let’s examine a running exercise for a workout app. Users would be able to start a run and keep track of their current progress over time, such as the elapsed time in seconds.

##### Join Me!

It’s more educational and fun if you check out the code and follow along with the chapter. You can download the source code at [http://mng.bz/5N4q](http://mng.bz/5N4q).

The type that represents an exercise is called `Run`, which benefits from computed properties. A run has an `elapsedTime()` function that shows how much time has passed since the start of a run. Once a run is finished, you can call the `setFinished()` function to round up the exercise. You check to confirm a running exercise is completed by checking that the `isFinished()` function returns true. The lifecycle of a running exercise is shown in the following example.

##### Listing 3.3. The lifecycle of a running exercise

```
var run = Run(id: "10", startTime: Date())
// Check the elapsed time.
print(run.elapsedTime()) // 0.00532001256942749
// Check the elapsed time again.
print(run.elapsedTime()) // 14.00762099027634
run.setFinished() // Finish the exercise.
print(run.isFinished()) // true
```

After introducing `Run`, you’ll see how to clean it up by transforming its function into computed properties.

#### 3.1.2. Converting functions to computed properties

Let’s take a peek at the `Run` type in the following listing to see how it is composed; then, you’ll determine how to refactor it so that it uses computed properties.

##### Listing 3.4. The `Run` struct

```
import Foundation

struct Run {
    let id: String
    let startTime: Date
    var endTime: Date?

    func elapsedTime() -> TimeInterval {             #1
         return Date().timeIntervalSince(startTime)
    }

    func isFinished() -> Bool {                      #2
         return endTime !=  nil
    }

    mutating func setFinished() {
        endTime = Date()
    }

    init(id: String, startTime: Date) {
        self.id = id
        self.startTime = startTime
        self.endTime = nil
    }
}
```

By looking at the signatures of the `elapsedTime()` and `isFinished()` functions shown in the following listing, you can see that both functions are not accepting a parameter but are returning a value.

##### Listing 3.5. Candidates for computed properties

```
func isFinished() -> Bool { ... }
func elapsedTime() -> TimeInterval { ... }
```

The lack of parameters and the fact that the functions return a value show that these functions are candidates for computed properties.

Next, let’s convert `isFinished()` and `elapsedTime()` into computed properties.

##### Listing 3.6. `Run` with computed properties

```
struct Run {
    let id: String
    let startTime: Date
    var endTime: Date?

    var elapsedTime: TimeInterval {                  #1
         return Date().timeIntervalSince(startTime)
    }

    var isFinished: Bool {                           #2
         return endTime !=  nil
    }

    mutating func setFinished() {
        endTime = Date()
    }

    init(id: String, startTime: Date) {
        self.id = id
        self.startTime = startTime
        self.endTime = nil
    }
}
```

You converted the functions into properties by giving a property a closure that returns a value.

This time, when you want to read the value, you can call the computed properties, as shown in the following example.

##### Listing 3.7. Calling computed properties

```
var run = Run(id: "10", startTime: Date())
print(run.elapsedTime) // 30.00532001256942749
print(run.elapsedTime) // 34.00822001332744283
print(run.isFinished) // false
```

Computed properties can change value dynamically and are thus *calculated*; this is in contrast to stored properties, which are fixed and have to be updated explicitly.

As a check before delivering a struct or class, do a quick scan to see if you can convert any functions to computed properties for added readability.

#### 3.1.3. Rounding up

By turning functions into properties, you can clean up a struct or class interface. To outsiders, some values communicate better as properties to broadcast their intention. Your coworkers, for instance, don’t always need to know that some properties can secretly be a function.

Converting lightweight functions to properties hides implementation details to users of your type, which is a small win, but it can add up in large codebases.

Let’s continue and see how computed properties may *not* be the best choice and how lazy properties can help.

### 3.2. Lazy properties

Computed properties are not always the best choice to add a dynamic nature to your types. When a computed property becomes computationally expensive, you’ll have to resort to other means, such as lazy properties.

In a nutshell, lazy properties make sure properties are calculated at a later time (if at all) and only once.

In this section, you’ll discover how lazy properties can help when you’re dealing with expensive computations or when a user has to wait for a long time.

#### 3.2.1. Creating a learning plan

Let’s go over an example where computed properties are not always the best choice and see how lazy properties are a better fit.

Imagine that you’re creating an API that can serve as a mentor to learn new languages. Using a fancy algorithm, it gives customers a tailor-made daily routine for studying a language. `LearningPlan` will base its schedule on each customer’s level, first language, and the language a customer wants to learn. The higher the level, the more effort is required of a customer. For simplicity, you’ll focus on a learning plan that produces plans related to learning English.

This section won’t implement an actual algorithm, but what is important to note is that this hypothetical algorithm takes a few seconds to process, which keeps customers waiting. A few seconds may not sound like much for a single occurrence, but it doesn’t scale well when creating many schedules, especially if these schedules are expected to load quickly on a mobile device.

Because this algorithm is expensive, you only want to call it once when you need to.

#### 3.2.2. When computed properties don’t cut it

Let’s discover why computed properties are not the best choice for expensive computations-.

You can initialize a `LearningPlan` with a description and a level parameter, as shown in the following listing. Via the `contents` property, you can read the plan that the fancy algorithm generates.

##### Listing 3.8. Creating a `LearningPlan`

```
var plan = LearningPlan(level: 18, description: "A special plan for today!")

print(Date()) // 2018-09-30 18:04:43 +0000
print(plan.contents) // "Watch an English documentary."
print(Date()) // 2018-09-30 18:04:45 +0000
```

Notice how calling `contents` takes two seconds to perform, which is because of your expensive algorithm.

In the next listing, let’s take a look at the `LearningPlan` struct; you can see how it’s built with computed properties. This is a naïve approach that you’ll improve with a lazy property.

##### Listing 3.9. A `LearningPlan` struct

```
struct LearningPlan {

    let level: Int

    var description: String

    // contents is a computed property.
    var contents: String {                                       #1
         // Smart algorithm calculation simulated here
        print("I'm taking my sweet time to calculate.")
        sleep(2)                                                 #2
 
        switch level {                                           #3
         case ..<25: return "Watch an English documentary."
         case ..<50: return "Translate a newspaper article to English and
    transcribe one song."
         case 100...: return "Read two academic papers and translate them
    into your native language."
         default: return "Try to read English for 30 minutes."
        }
    }
}
```

##### Pattern Matching

You can pattern match on so-called *one-sided ranges*, meaning there is no start range. For example, `..<25` means “anything below 25, and `100…` means “100 and higher.”

Notice how every time `contents` is called it takes two seconds to calculate.

As shown next, if you were to call it only five times (such as in a loop, shown in the following listing), the application would take ten seconds to perform—not very fast!

##### Listing 3.10. Calling contents five times

```
var plan = LearningPlan(level: 18, description: "A special plan for today!")
print(Date()) // A start marker
for _ in 0..<5 {
    plan.contents
}
print(Date()) // An end marker
```

This prints the following listing.

##### Listing 3.11. Taking ten seconds

```
2018-10-01 06:39:37 +0000
I'm taking my sweet time to calculate.
I'm taking my sweet time to calculate.
I'm taking my sweet time to calculate.
I'm taking my sweet time to calculate.
I'm taking my sweet time to calculate.
2018-10-01 06:39:47 +0000
```

Notice how the start and end date markers are ten seconds apart. Because a computed property runs whenever it’s called, using computed properties for expensive operations is highly discouraged.

Next you’ll replace the computed property with a lazy property to make your code more efficient.

#### 3.2.3. Using lazy properties

You can use lazy properties to make sure a computationally expensive or slow property is performed only once, and only when you call it (if at all). Refactor the computed property into a lazy property in the following listing.

##### Listing 3.12. `LearningPlan` with a lazy property

```
struct LearningPlan {

    let level: Int

    var description: String

    lazy var contents: String = {                             #1
         // Smart algorithm calculation simulated here
        print("I'm taking my sweet time to calculate.")
        sleep(2)

        switch level {
        case ..<25: return "Watch an English documentary."
        case ..<50: return "Translate a newspaper article to English and
    transcribe one song."
        case 100...: return "Read two academic papers and translate them
    into your native language."
        default: return "Try to read English for 30 minutes."
        }
    }()                                                       #2
}
```

##### Referring to Properties

You can refer to other properties from inside a lazy property closure. Notice how `contents` can refer to the `level` property.

Still, this isn’t enough; a lazy property is considered a regular property that the compiler wants to be initialized. You can circumvent this by adding a custom initializer, as shown in the following listing, where you elide `contents`, satisfying the compiler.

##### Listing 3.13. Adding a custom initializer

```
struct LearningPlan {
    // ... snip
    init(level: Int, description: String) { // no contents to be found here!
        self.level = level
        self.description = description
    }
}
```

Everything compiles again. Moreover, the best part is that when you repeatedly call `contents`, the expensive algorithm is used only once! Once a value is computed, it’s stored. Notice in the following listing that even though `contents` is accessed five times, the lazy property is only initialized once.

##### Listing 3.14. Contents loaded only once

```
print(Date())
for _ in 0..<5 {
    plan.contents
}
print(Date())

// Will print:
2018-10-01 06:43:24 +0000
I'm taking my sweet time to calculate.
2018-10-01 06:43:26 +0000
```

Reading the contents takes two seconds the first time you access it, but the second time `contents` returns instantly. The total time spent by the algorithm is now two seconds instead of ten!

#### 3.2.4. Making a lazy property robust

A lazy property on its own is not particularly robust; you can easily break it. Witness the following scenario where you set the `contents` property of `LearningPlan` to a less desirable plan.

##### Listing 3.15. Overriding the contents of `LearningPlan`

```
var plan = LearningPlan(level: 18, description: "A special plan for today!")
plan.contents = "Let's eat pizza and watch Netflix all day."
print(plan.contents) // "Let's eat pizza and watch Netflix all day."
```

As you can see, you can bypass the algorithm by setting a lazy property, which makes the property a bit brittle.

But not to worry—you can limit the access level of properties. By adding the `private-(set)` keyword to a property, as shown in the following listing, you can indicate that your property is readable, but can only be set (mutated) by its owner, which is `LearningPlan` itself.

##### Listing 3.16. Making `contents` a `private(set)` property

```
struct LearningPlan {
    lazy private(set) var contents: String = {
    // ... snip
}
```

Now the property can’t be mutated from outside the struct; `contents` is read-only to the outside world. The error, given by the compiler, confirms this, as the following listing shows.

##### Listing 3.17. `contents` property can’t be set

```
error: cannot assign to property: 'contents' setter is inaccessible
plan.contents = "Let's eat pizza and watch Netflix all day."
~~~~~~~~~~~~~ ^
```

This way you can expose a property as read-only to the outside and mutable to the owner only, making the lazy property a bit more robust.

#### 3.2.5. Mutable properties and lazy properties

Once you initialize a lazy property, you cannot change it. You need to use extra caution when you use mutable properties—also known as `var` properties—in combination with lazy properties. This holds even truer when working with structs.

Let’s go over a scenario where a seemingly innocent chance can introduce subtle bugs.

To demonstrate, in the following listing, `level` turns from a `let` to a `var` property so it can be mutated.

##### Listing 3.18. `LearningPlan` level now mutable

```
struct LearningPlan {
  // ... snip
  var level: Int
}
```

You create a copy by referring to a struct. Structs have so-called *value semantics*, which means that when you refer to a struct, it gets copied.

You can, as an example, create an intense learning plan, copy it, and lower the level, leaving the original learning plan intact, as the following listing shows.

##### Listing 3.19. Copying a struct

```
var intensePlan = LearningPlan(level: 138, description: "A special plan for
     today!")
intensePlan.contents                #1
var easyPlan = intensePlan          #2
easyPlan.level = 0                  #3
 // Quiz: What does this print?
print(easyPlan.contents)
```

Now you’ve got a copy, but here’s a little quiz: What do you get when you print `easyPlan.contents`?

The answer is the intense plan: *“Read two academic papers and translate them into your native language.”*

When `easyPlan` was created, the `contents` were already loaded before you made a copy, which is why `easyPlan` is copying the intense plan (see [figure 3.1](https://livebook.manning.com/book/swift-in-depth/chapter-3/ch03fig1)).

![Figure 3.1. Copying after initializing a lazy description](https://drek4537l1klr.cloudfront.net/veen/Figures/03fig01.jpg)

Alternatively, you can call `contents` after making a copy, in which case both plans can individually lazy load their contents (see [figure 3.2](https://livebook.manning.com/book/swift-in-depth/chapter-3/ch03fig2)).

![Figure 3.2. Copying before initializing a lazy description](https://drek4537l1klr.cloudfront.net/veen/Figures/03fig02.jpg)

In the next listing you see how both learning plans calculate their plans because the copy happens *before* the lazy properties are initialized.

##### Listing 3.20. Copying before lazy loading

```
var intensePlan = LearningPlan(level: 138, description: "A special plan for
     today!")
var easyPlan = intensePlan                #1
 easyPlan.level = 0                       #2
 
// Now both plans have proper contents.
print(intensePlan.contents) // Read two academic papers and translate them
     into your native language.
print(easyPlan.contents) // Watch an English documentary.
```

The previous examples highlight that complexity surges as soon as you start mutating variables, used by lazy loading properties. Once a property changes, it’s out of sync with a lazy-loaded property.

Therefore, make sure you keep properties immutable when a lazy property depends on it. Since structs are copied when you reference them, it becomes even more important to take extra care when mixing structs and lazy properties.

#### 3.2.6. Exercises

In this exercise, you’re modeling a music library (think Apple Music or Spotify):

```
//: Decodable allows you to turn raw data (such as plist files) into songs
struct Song: Decodable {
    let duration: Int
    let track: String
    let year: Int
}

struct Artist {

    var name: String
    var birthDate: Date
    var songsFileName: String

    init(name: String, birthDate: Date, songsFileName: String) {
        self.name = name
        self.birthDate = birthDate
        self.songsFileName = songsFileName
    }

    func getAge() -> Int? {
        let years = Calendar.current
            .dateComponents([.year], from: Date(), to: birthDate)
            .day

        return years
    }

    func loadSongs() -> [Song] {
        guard
            let fileURL = Bundle.main.url(forResource: songsFileName,
    withExtension: "plist"),
            let data = try? Data(contentsOf: fileURL),
            let songs = try? PropertyListDecoder().decode([Song].self, from:
    data) else {
                return []
        }
        return songs
    }

    mutating func songsReleasedAfter(year: Int) -> [Song] {
        return loadSongs().filter { (song: Song) -> Bool in
            return song.year > year
        }
    }

}
See if you can clean up the Artist type by using lazy and/or computed properties.
Assuming loadSongs is turned into a lazy property called songs, make sure the following code doesn’t break it by trying to override the property data: // billWithers.songs = []
```

1. Assuming `loadSongs` is turned into a lazy property called `songs`, how can you make sure that the following lines won’t break the lazily loaded property? Point out two ways to prevent a lazy property from breaking:

billWithers.songs // load songs
billWithers.songsFileName = "oldsongs" // change file name
billWithers.songs.count // Should be 0 after renaming songsFileName,
but is 2

copy

### 3.3. Property observers

Sometimes you want the best of both worlds: you want to store a property, but you’d still like custom behavior on it. In this section, you’ll explore the combination of storage and behavior via the help of *property observers*. It wouldn’t be Swift if it didn’t come with its own unique rules, so let’s see how you can best navigate property observers.

Property observers are actions triggered when a stored property changes value, which is an ideal candidate for when you want to do some cleanup work after setting a property, or when you want to notify other parts of your application of property changes.

#### 3.3.1. Trimming whitespace

Imagine a scenario where a player can join an online multiplayer game; the only thing a player needs to enter is a name containing a minimum number of characters. However, people who want short names may fill up the remaining characters with spaces to meet the requirements.

You’re going to see how you can clean up a name automatically after you set it. The property observer removes unnecessary whitespace from a name.

In the following example, you can see how the name automatically gets rid of trailing whitespace after a property is updated. Note that the initializer doesn’t trigger the property observer.

##### Listing 3.21. Trimming whitespace

```
let jeff = Player(id: "1", name: "SuperJeff    ")
print(jeff.name) // "SuperJeff    "                #1
print(jeff.name.count) // 13

jeff.name = "SuperJeff    "
print(jeff.name) // "SuperJeff"                    #2
print(jeff.name.count) // 9
```

The name property automatically trims its whitespace, but *only* when updated, not when you initially set it. Before you solve this issue, look at the `Player` class to see how the property observer works, as shown in the following listing.

##### Listing 3.22. The `Player` class

```
import Foundation

class Player {

    let id: String

    var name: String {                                            #1
         didSet {                                                 #2
               print("My previous name was \(oldValue)")          #3
               name = name.trimmingCharacters(in: .whitespaces)   #4
         }
    }

    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}
```

##### Didset Willset

Besides `didSet`, you can also use `willSet` observers, which are triggered right before a property is changed. If you use `willSet`, you can use the `newValue` constant.

#### 3.3.2. Trigger property observers from initializers

The `name` property got cleaned up after you updated the property, but initially `name` still contained its whitespace, as shown in the next listing.

##### Listing 3.23. Property observer isn’t triggered from initializer

```
let jeff = Player(id: "1", name: "SuperJeff    ")
print(jeff.name) // "SuperJeff    "                  #1
print(jeff.name.count) // 13
```

Property observers are unfortunately *not* triggered from initializers, which is intentional, but you have to be aware of this Swift gotcha. Luckily, there’s a workaround.

Officially, the recommended technique is to separate the `didSet` closure into a function, then you can call this function from an initializer. However, another trick is to add a `defer` closure to the initializer method.

When a function finishes, the `defer` closure is called. You can put the `defer` closure anywhere in the initializer, but it will only be called after a function reaches the end, which is handy when you want to run cleanup code at the end of functions.

Add a `defer` closure to the initializer that sets the title in the next listing.

##### Listing 3.24. Adding a `defer` closure to the initializer

```
class Player {

     // ... snip

    init(id: String, name: String) {
        defer { self.name = name }      #1
        self.id = id
        self.name = name                #2
     }
}
```

The `defer` closure is called right after `Player` is initialized, triggering the property observer as shown in the following listing.

##### Listing 3.25. Trimming whitespace

```
let jeff = Player(id: "1", name: "SuperJeff    ")
print(jeff.name) // "SuperJeff"
print(jeff.name.count) // 9

jeff.name = "SuperJeff    "
print(jeff.name) // "SuperJeff"
print(jeff.name.count) // 9
```

You get the best of both worlds. You can store a property, you can trigger actions on it, *and* there is no distinction between setting the property from the initializer or property accessor.

One caveat is that the `defer` trick isn’t officially intended to be used this way, which means that the `defer` method may not work in the future. However, until then, this solution is a neat trick you can apply.

#### 3.3.3. Exercises

1. If you need a property with both behavior and storage, what kind of property would you use?
1. If you need a property with only behavior and no storage, what kind of property would you use?
1. Can you spot the bug in the following code?

struct Tweet {
let date: Date
let author: String
var message: String {
didSet {
message = message.trimmingCharacters(in: .whitespaces)
}
}
}

let tweet = Tweet(date: Date(),
author: "@tjeerdintveen",
message: "This has a lot of unnecessary whitespace   ")

copy

1. How can you fix the bug?

### 3.4. Closing thoughts

Even though you have been using properties already, I hope that taking a moment to understand them on a deeper level was worthwhile.

You saw how to choose between a computed property, lazy property, and stored properties with behaviors. Making the right choices makes your code more predictable, and it cleans up the interface and behaviors of your classes and structs.

### Summary

- You can use computed properties for properties with specific behavior but *without* storage.
- Computed properties are functions masquerading as properties.
- You can use computed properties when a value can be different each time you call it.
- Only lightweight functions should be made into computed properties.
- Lazy properties are excellent for expensive or time-consuming computations.
- Use lazy properties to delay a computation or if it may not even run at all.
- Lazy properties allow you to refer to other properties inside classes and structs.
- You can use the private(set) annotation to make properties read-only to outsiders of a class or struct.
- When a lazy property refers to another property, make sure to keep this other property immutable to keep complexity low.
- You can use property observers such as `willSet` and `didSet` to add behavior on stored properties.
- You can use `defer` to trigger property observers from an initializer.

### Answers

1. See if you can clean up the `Artist` type by using lazy and/or computed properties:

struct Artist {

var name: String
var birthDate: Date
let songsFileName: String

init(name: String, birthDate: Date, songsFileName: String) {
self.name = name
self.birthDate = birthDate
self.songsFileName = songsFileName
}

// Age is now computed (calculated each time)
var age: Int? {
let years = Calendar.current
.dateComponents([.year], from: Date(), to: birthDate)
.day

return years
}

// loadSongs() is now a lazy property, because it's expensive to
load a file on each call.
lazy private(set) var songs: [Song] = {
guard
let fileURL = Bundle.main.url(forResource: songsFileName,
withExtension: "plist"),
let data = try? Data(contentsOf: fileURL),
let songs = try? PropertyListDecoder().decode([Song].self,
from: data) else {
return []
}
return songs
}()

mutating func songsReleasedAfter(year: Int) -> [Song] {
return songs.filter { (song: Song) -> Bool in
return song.year > year
}
}
}

copy

1. Assuming `loadSongs` is turned into a lazy property called `songs`, make sure the following code doesn’t break it by overriding the property data:

// billWithers.songs = []

copy

You can achieve this by making `songs` a private(set) property.
1. Assuming `loadSongs` is turned into a lazy property called `songs`, how can you make sure that the following lines won’t break the lazily loaded property? Point out two ways:

billWithers.songs
billWithers.songsFileName = "oldsongs"
billWithers.songs.count // Should be 0 after renaming songsFileName,
but is 2

copy

The lazy property `songs` points to a var called `songsFileName`. To prevent mutation after lazily loading songs, you can make `songsFileName` a constant with `let`. Alternatively, you can make `Artist` a class to prevent this bug.
1. If you need a property with both behavior and storage, what kind of property would you use? A stored property with a property observer
1. If you need a property with only behavior and no storage, what kind of property would you use? A computed property, or lazy property if the computation is expensive
1. Can you spot the bug in the code? The whitespace isn’t trimmed from the initializer.
1. How can you fix the bug? By adding an initializer to the struct with a `defer` clause

struct Tweet {
let date: Date
let author: String
var message: String {
didSet {
message = message.trimmingCharacters(in: .whitespaces)
}
}

init(date: Date, author: String, message: String) {
defer { self.message = message }
self.date = date
self.author = author
self.message = message
}
}

let tweet = Tweet(date: Date(),
author: "@tjeerdintveen",
message: "This has a lot of unnecessary whitespace   ")

tweet.message.count

copy
