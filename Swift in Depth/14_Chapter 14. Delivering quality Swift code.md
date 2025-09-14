# Chapter 14. Delivering quality Swift code

### ***This chapter covers***

- Documenting code via Quick Help
- Writing good comments that don’t distract
- How style isn’t too important
- Getting consistency and fewer bugs with SwiftLint
- Splitting up large classes in a Swifty way
- Reasoning about making types generic

Writing Swift code is fun, but in larger projects the ratio between writing and maintaining code shifts toward maintenance. Mature projects are where proper naming, code reusability, and documentation play an essential role. This chapter addresses these points to make programmers’ lives more comfortable when looking at code from a maintenance perspective.

This is the least code-centric chapter in this book, but one of the more important ones when working on projects in teams or when trying to pass a code assignment for a new job. It also covers some refactoring approaches to make your code more generic and reusable.

It starts with documentation—who doesn’t love to write it? I know I don’t. But you can really help other programmers get up to speed when you supply them with good examples, descriptions, reasoning, and requirements. You’ll see how to add documentation to code via the use of Quick Help.

Next, you’re going to handle when and how to add comments to your code and see how you can add, not distract, by surgically placing valuable comments. Comments aren’t Swift-centric, but they’re still an influential part of daily (Swift) programming.

Swift offers a lot of different ways to write your code. But you’ll see how style isn’t too important and how consistency is more valuable to teams. You’ll see how to install and configure SwiftLint to keep consistency in a codebase so that everyone, beginner or expert, can write code as if a single developer is writing it.

Then you’ll discover how you can think differently about oversized classes. Generally, these tend to be “Manager” classes. Apple’s source and examples include plenty of these manager classes, and following suit can be tempting. But more often than not, manager classes have many responsibilities that can harm maintainability. You’ll discover how you can split up large classes and pave the road to making generic types.

Finding a fitting name is hard. You’ll find out how types can get overspecified names and how suitable names are more future-proof and can prepare you for making types generic.

### 14.1. API documentation

Writing documentation can be tedious; you know it, I know it, we all know it. But even adding a little documentation to your properties and types can help a coworker get up to speed quickly.

Documentation is handy for internal types across a project. But it becomes especially important when offering elements that are marked as `public`, such as public functions, variables, and classes. Code marked as `public` is accessible when provided via a framework that can be reused across projects, which is all the more reason to provide complete documentation.

In this section, you’ll see how you can add useful notations to accompany your code and to guide your readers via the use of doc comments, which are presented in Xcode via Quick Help.

Then, at the end, you’ll see how to generate a documentation website based on Quick Help, via the help of a tool called Jazzy.

#### 14.1.1. How Quick Help works

Quick Help documentation is a short markdown notation that accompanies types, properties, functions, enum cases, and others. Xcode can show tooltips after Quick Help documentation is added.

Imagine you’re creating a turn-based, online game. You’ll use a small enum to represent each turn a player can take, such as skipping a turn, attacking a location, or healing.

Xcode can display Quick Help tips in two ways. The pop-up, shown in [figure 14.1](https://livebook.manning.com/book/swift-in-depth/chapter-14/ch14fig1), is activated by hovering over a word and pressing the Option key (Mac).

![Figure 14.1. Quick Help pop-up](https://drek4537l1klr.cloudfront.net/veen/Figures/14fig01_alt.jpg)

Quick Help is also available in Xcode’s sidebar (see [figure 14.2](https://livebook.manning.com/book/swift-in-depth/chapter-14/ch14fig2)).

![Figure 14.2. Quick Help in the sidebar](https://drek4537l1klr.cloudfront.net/veen/Figures/14fig02.jpg)

The enum in the Quick Help notation is formatted as follows.

##### Listing 14.1. The turn with Quick Help notations

```
1234567891011/// A player's turn in a turn-based online game.
enum Turn {
    /// Player skips turn, will receive gold.
    case skip
    /// Player uses turn to attack location.
    /// - x: Coordinate of x location in 2D space.
    /// - y: Coordinate of y location in 2D space.
    case attack(x: Int, y: Int)
    /// Player uses round to heal, will not receive gold.
    case heal
}
```

By using a `///` notation, you can add Quick Help notations to your types. By adding Quick Help documentation, you can add more information to the code you write.

#### 14.1.2. Adding callouts to Quick Help

Quick Help offers many markup options—called *callouts*—that you can add to Quick Help. Callouts give your Quick Help tips a little boost, such as the types of errors a function can throw or showing an example usage of your code.

Let’s go over how to add example code and error-throwing code by introducing a new function. This new function will accept multiple `Turn` enums and returns a string of the actions happening inside of it.

[Figure 14.3](https://livebook.manning.com/book/swift-in-depth/chapter-14/ch14fig3) shows how Quick Help example code is represented.

![Figure 14.3. Quick Help with callouts](https://drek4537l1klr.cloudfront.net/veen/Figures/14fig03_alt.jpg)

To create an example inside Quick Help, you need to tab text inside a Quick Help notation, as shown here.

##### Listing 14.2. Adding callouts

```
/// Takes an array of turns and plays them in a row.
///
/// - Parameter turns: One or multiple turns to play in a round.
/// - Returns: A description of what happened in the turn.
/// - Throws: TurnError
/// - Example: Passing turns to `playTurn`.
///
///         let turns = [Turn.heal, Turn.heal]
///         try print(playTurns(turns)) "Player healed twice."
func playTurns(_ turns: [Turn]) throws -> String {
```

Swift can tell you at compile time that a function can throw, but the thrown errors are only known at runtime. Adding a `Throws` callout can at least give the reader more information about which errors to expect.

You can even include more callouts, such as *Attention*, *Author*, *Authors*, *Bug*, *Complexity*, *Copyright*, *Date*, *Note*, *Precondition*, *Requires*, *See AlsoVersion*, *Warning*, and a few others.

For a full list of all the callout options, see Xcode’s markup guidelines ([http://mng.bz/Qgow](http://mng.bz/Qgow)).

#### 14.1.3. Documentation as HTML with Jazzy

When you accompany your code with Quick Help documentation, you can get a rich documentation website that accompanies your project.

Jazzy ([https://github.com/realm/jazzy](https://github.com/realm/jazzy)) is a great tool to convert your Quick Help notations into an Apple-like documentation website. For instance, imagine that you’re offering an Analytics framework. You can have Jazzy generate documentation for you, based on the public types and quick help information that’s available (see [figure 14.4](https://livebook.manning.com/book/swift-in-depth/chapter-14/ch14fig4)).

![Figure 14.4. Jazzy documentation](https://drek4537l1klr.cloudfront.net/veen/Figures/14fig04_alt.jpg)

Jazzy is a command-line tool and is installed as a Ruby gem. To install and run Jazzy, use these commands from the terminal:

```
gem install jazzy
jazzy
```

You’ll see the following output:

```
Running xcodebuild
building site
building search index
downloading coverage badge
jam out to your fresh new docs in `docs`
```

Now you’ll find a `docs` folder with your source code nicely documented. You can apply Jazzy to any project where you’d like to generate a website with documentation.

### 14.2. Comments

Even though comments aren’t related to Swift only, delivering code that is pleasing to read and quick to understand is still valuable.

Comments, or explicitly knowing when to add value with comments, are a vital component of day-to-day programming. Unfortunately, comments can muddy up your code if you’re not careful. This section will show you how to write helpful comments.

#### 14.2.1. Explain the “why”

A simple rule to follow is that a comment tells the reader “why” this element is there. In contrast, code tells the reader “what” it’s doing.

Imagine a `Message` struct that allows a user to message another user privately. You can see in this example that when comments are focused on the “what,” comments don’t add much.

##### Listing 14.3. A struct with "what" comments

```
struct Message {
  // The id of the message
  let id: String

  // The date of the message
  let date: Date

  // The contents of the message
  let contents: String
}
```

These comments are redundant and muddy up the code. You can infer the meaning of these variables from the property names and, on top of that, they don’t add anything to Quick Help.

Instead, try to explain the “why” with a comment, as shown here.

##### Listing 14.4. Message with a "why" comment

```
struct Message {
  let id: String
  let date: Date
  let contents: String

  // Messages can get silently cut off by the server at 280 characters.
  let maxLength = 280
}
```

Here you explain why `maxLength` is there and why 280 isn’t just an arbitrary number, which isn’t something you can infer from the property name.

#### 14.2.2. Only explain obscure elements

Not all “whys” need to be explained.

Readers of your code tend only to be interested in obscure deviations from standard code, such as why you’re storing data in two places instead of one (perhaps for performance benefits), or why you’re reversing names in a list before you search in it (maybe so you can search on `lastname` instead).

You don’t need to add comments to code your peers already know. Still, feel free to use them at significant deviations. As a rule of thumb, though, stay stingy with comments.

#### 14.2.3. Code has the truth

No matter how many comments you write, the code has the truth. So when you refactor code, you’ll have to refactor the comments that go with it. Out-of-date comments are garbage and noise in an otherwise pure environment.

#### 14.2.4. Comments are no bandage for bad names

Comments can wrongfully be used as a bandage to compensate for bad function or variable names. Instead, explain yourself in code so that you won’t need comments.

The next example shows comments added as a bandage, which you could omit by giving a Boolean check more context via code:

```
// Make sure user can access content.
if user.age > 18 && (user.isLoggedIn || user.registering) { ... }
```

Instead, give context via code so that a comment isn’t needed:

```
let canUserAccessContent = user.age > 18 && (user.isLoggedIn ||
     user.registering)

if canUserAccessContent {
  ...
}
```

The code now gives context, and a comment isn’t needed anymore.

#### 14.2.5. Zombie code

*Zombie code* is commented-out code that doesn’t do anything. It’s dead but still haunts your workspace.

Zombie code is easily recognizable by commented-out chunks:

```
// func someThingUsefulButNotAnymore() {
//     user.save()
// }
```

Sometimes zombie code can linger inside codebases, probably because it’s forgotten or because of a hunch that it may be needed again at some point.

Attachment issues aside, at some point you’ll have to let go of old code. It will still live on in your memories, except those memories are called version control, such as git. If you need an old function again, you can use the version control of your choice to get it back while keeping your codebase clean.

### 14.3. Settling on a style

In this section, you’ll see how to enforce style rules via a tool called SwiftLint.

It’s rare to find a developer who doesn’t have a strong preference for a style. John loves to use `forEach` wherever possible, whereas Carl wants to solve everything with `for` loops. Mary prefers her curly braces on the same line, and Geoff loves putting each function parameter on a new line so that git diffs are easier to read.

These style preferences can run deep, and they can cause plenty of debates inside teams.

But ultimately style isn’t too important. If code looks sparkly-clean but is full of bugs, or no one uses it, then what is the point of good style? The goal of software isn’t to look readable; it’s to fill a need or solve a problem.

Of course, sometimes style does matter for making a codebase more pleasant to read and easier to understand. In the end, style is a means to an end and not the goal itself.

#### 14.3.1. Consistency is key

When working in a team, more valuable than a style itself is style consistency. You save time when code is predictable and seemingly written by a single developer.

Having a general idea of what a Swift file looks like—before you even open it—is beneficial. You don’t want to spend much time deciphering the code you’re looking at, which lowers the cognitive load of you and your team members. Newcomers to a project are up to speed quicker and adopt stylistic choices when they recognize a clear style to conform to.

By removing style debates from the equation, you can focus on the important parts, which is making software that solves problems or fills needs.

#### 14.3.2. Enforcing rules with a linter

You can increase codebase consistency and minimize style discussions by adding a linter to a project. A linter tries to detect problems, suspicious code, and style deviations before you compile or run your program. Using a linter to analyze your code ensures that you keep a consistent codebase across teams and projects.

With the help of a linter, both newcomers and veterans to a project can work on new *and* old code and maintain a consistent style enforced by the linter. A linter even helps you check for bad practices that may occur from time to time.

Realm offers a great tool called SwiftLint ([https://github.com/realm/SwiftLint](https://github.com/realm/SwiftLint)) to fulfill this linting role. You can use SwiftLint to enforce style guidelines that you configure. By default, it uses guidelines determined by the Swift community ([https://github.com/github/swift-style-guide](https://github.com/github/swift-style-guide)).

For example, the code in [figure 14.5](https://livebook.manning.com/book/swift-in-depth/chapter-14/ch14fig5) violates some rules, such as force unwrapping and empty whitespace. SwiftLint lets you know via warnings and errors. You can consider SwiftLint to be a compiler extension.

![Figure 14.5. SwiftLint in action](https://drek4537l1klr.cloudfront.net/veen/Figures/14fig05_alt.jpg)

It’s not all about style, either. The empty count violation depicted in [figure 14.5](https://livebook.manning.com/book/swift-in-depth/chapter-14/ch14fig5) alerts you to use `isEmpty` instead of `.count` `==` `0`, because `isEmpty` performs better on large arrays.

Don’t worry if you find some rules too strict; you can configure each rule to your liking. After a team settles on rules, everybody can move forward, and you can take style discussions out of the equation while reviewing code.

Read on to see how to install SwiftLint and configure its rules.

#### 14.3.3. Installing SwiftLint

You can install SwiftLint using HomeBrew ([https://brew.sh](https://brew.sh/)). In your command line, type the following:

```
brew install swiftlint
```

Alternatively, you can directly install the SwiftLint package from the Github repository ([https://github.com/realm/Swiftlint/releases](https://github.com/realm/Swiftlint/releases)).

SwiftLint is a command-line tool you can run with `swiftlint`. But chances are you’re using Xcode. You’ll configure it so that SwiftLint works there, too.

In Xcode, locate the Build Phases tab (see [figure 14.6](https://livebook.manning.com/book/swift-in-depth/chapter-14/ch14fig6)). Click the plus button, and choose New Run Script Phase. Then add a new script and add the code shown in [figure 14.7](https://livebook.manning.com/book/swift-in-depth/chapter-14/ch14fig7).

![Figure 14.6. Xcode build phases](data:image/svg+xml;utf8,%3Csvg%20xmlns=%22http://www.w3.org/2000/svg%22%20xmlns:xlink=%22http://www.w3.org/1999/xlink%22%20version=%221.1%22%20x=%220px%22%20y=%220px%22%20viewBox=%220%200%20590%20191%22%20xml:space=%22preserve%22%20height=%22191px%22%20width=%22590px%22%3E%20%3Crect%20width=%22590%22%20height=%22191%22%20style=%22fill:rgb(255,255,255);%22/%3E%3C/svg%3E)

![Figure 14.7. Xcode script](data:image/svg+xml;utf8,%3Csvg%20xmlns=%22http://www.w3.org/2000/svg%22%20xmlns:xlink=%22http://www.w3.org/1999/xlink%22%20version=%221.1%22%20x=%220px%22%20y=%220px%22%20viewBox=%220%200%20590%20263%22%20xml:space=%22preserve%22%20height=%22263px%22%20width=%22590px%22%3E%20%3Crect%20width=%22590%22%20height=%22263%22%20style=%22fill:rgb(255,255,255);%22/%3E%3C/svg%3E)

That’s it! The next time you build your project, SwiftLint throws warnings and errors where applicable, based on a default configuration.

#### 14.3.4. Configuring SwiftLint

Next, you’d probably like to configure SwiftLint to your liking. The configuration file is a yml—or yaml—file called .swiftlint.yml. This yaml file contains the rules you can enable and disable for your project.

##### Listing 14.5. SwiftLint configuration file

```
disabled_rules: # rule identifiers to exclude from running
  - variable_name
  - nesting
  - function_parameter_count
opt_in_rules: # some rules are only opt-in
  - control_statement
  - empty_count
  - trailing_newline
  - colon
  - comma
included: # paths to include during linting. `--path` is ignored if present.
  - Project
  - ProjectTests
  - ProjectUITests
excluded: # paths to ignore during linting. Takes precedence over `included`.
  - Pods
  - Project/R.generated.swift

# configurable rules can be customized from this configuration file
# binary rules can set their severity level
force_cast: warning # implicitly. Give warning only for force casting

force_try:
  severity: warning # explicitly. Give warning only for force try
type_body_length:
  - 300 # warning
  - 400 # error

# or they can set both explicitly
file_length:
  warning: 500
  error: 800

large_tuple: # warn user when using 3 values in tuple, give error if there
 are 4
    - 3
    - 4

# naming rules can set warnings/errors for min_length and max_length
# additionally they can set excluded names
type_name:
  min_length: 4 # only warning

    error: 35
  excluded: iPhone # excluded via string
reporter: "xcode"
```

Alternatively, you can check all the rules that SwiftLint offers via the `swiftlint` `rules` command.

Move this .swiftlint.yml file to the root directory of your source code—such as where you can find the main.swift or AppDelegate.swift file. Now a whole team shares the same rules, and you can enable and disable them as your heart desires.

#### 14.3.5. Temporarily disabling SwiftLint rules

Some rules are meant to be broken. For example, you may have force unwrapping set as a violation, but sometimes you might want it enabled. You can use SwiftLint modifiers to turn off specific rules for several lines in your code.

By applying specific comments in your code, you can disable SwiftLint rules at their respective lines. For example, you can disable and enable a rule in your code with the following:

```
// swiftlint:disable <rule1> [<rule> <rule>...]
// .. violating code here
// swiftlint:enable <rule1> [<rule> <rule>...]
```

You can modify these rules with the `:previous`, `:this`, or `:next` keywords.

For example, you can turn off the violating rules you had at the beginning of this section:

```
if list.count == 0 { // swiftlint:disable:this empty_count
      // swiftlint:disable:next force_unwrapping
      print(lastLogin!)
}
```

#### 14.3.6. Autocorrecting SwiftLint rules

As soon as you add SwiftLint to an existing project, it will likely start raining SwiftLint warnings. Luckily, SwiftLint can fix warnings automatically via the following command you can run from the terminal:

```
swiftlint autocorrect
```

The `autocorrect` command adjusts the files for you and fixes warnings where it feels confident enough to do so.

Of course, it doesn’t hurt to check the version control’s diff file to see whether your code has been corrected properly.

#### 14.3.7. Keeping SwiftLint in sync

If you use SwiftLint with multiple team members, chances are that one team member could have a different version of SwiftLint installed, especially when SwiftLint gets upgraded over time. You can add a small check so that Xcode gives a warning when you’re on the wrong version.

This is another build phase you can add to Xcode. For example, the following command raises an Xcode warning when your SwiftLint isn’t version 0.23.1:

```
EXPECTED_SWIFTLINT_VERSION="0.23.1"
if swiftlint version | grep -q ${EXPECTED_SWIFTLINT_VERSION}; then
echo "Correct version"
else
echo "warning: SwiftLint is not the right version 
${EXPECTED_SWIFTLINT_VERSION}. Download from 
https://github.com/realm/SwiftLint"
```

Now, whenever a team member is falling behind with updates, Xcode throws a warning.

This section provided more than enough to get you started on SwiftLint. SwiftLint offers many more customizations and is regularly updated with new rules. Be sure to keep an eye on the project!

### 14.4. Kill the managers

![](data:image/svg+xml;utf8,%3Csvg%20xmlns=%22http://www.w3.org/2000/svg%22%20xmlns:xlink=%22http://www.w3.org/1999/xlink%22%20version=%221.1%22%20x=%220px%22%20y=%220px%22%20viewBox=%220%200%20461%20245%22%20xml:space=%22preserve%22%20height=%22245px%22%20width=%22461px%22%3E%20%3Crect%20width=%22461%22%20height=%22245%22%20style=%22fill:rgb(255,255,255);%22/%3E%3C/svg%3E)

Manager classes—recognized by the `-Manager` suffix—tend to pop up fairly often in the iOS and Swift community, most likely because Apple’s code as an example offers manager types. But manager classes tend to have many (or too many) responsibilities. Challenge the “you’ve always done it this way” approach and see if you can improve code readability by tackling large manager classes.

You’re going to see how you can reconsider a large class with many responsibilities by cutting it up into smaller reusable types. Working in a more modular way paves the road to a more modular and Swifty approach to architecture, including generic types.

Because manager classes tend to hold the crown of being oversized classes, they serve as a prime example in this section.

#### 14.4.1. The value of managers

Managers tend to be classes with many responsibilities, such as the following examples:

- `BluetoothManager`—Checking connections, holding a list of devices, helping to reconnect, and offering a discovery service
- `ApiRequestManager`—Performing network calls, storing responses inside a cache, having a queue mechanism, and offering WebSocket support

Avoiding manager-like classes in the real world is easier said than done; it isn’t 100% preventable. Also, manager types make sense when you compose them out of smaller types, versus classes containing many responsibilities.

If you have a large manager class, however, you can drop the `Manager` suffix, and the type’s name tells the reader exactly as much as before. For example, rename `BluetoothManager` as `Bluetooth` and expose the same responsibilities. Alternatively, rename `PhotosManager` as `Photos` or `Stack`. Again, without the `-Manager` suffix, a type exposes the same amount of information of its tasks.

#### 14.4.2. Attacking managers

Usually, when a type gains the `-Manager` suffix, it’s an indicator that this class has a lot of essential responsibilities. Let’s see how you can cut it up.

First, name these responsibilities explicitly so that a manager doesn’t hide them. For example, an `ApiRequestManager` might be called `ApiRequestNetworkCacheQueueWebsockets`. That’s a mouthful, but the truth has come out! Explicitly labeling responsibilities means that you uncovered all that the type does; it’s now clear just how much responsibility the `ApiRequestManager` has.

As a next step, consider splitting up the responsibilities into smaller types, such as `ResponseCache`, `RequestQueue`, `Network`, and `Websockets` types (see [figure 14.8](https://livebook.manning.com/book/swift-in-depth/chapter-14/ch14fig8)). Also, you could now rename the `ApiRequestManager` to something more precise, such as `Network`.

![Figure 14.8. Refactoring ApiRequestManager](data:image/svg+xml;utf8,%3Csvg%20xmlns=%22http://www.w3.org/2000/svg%22%20xmlns:xlink=%22http://www.w3.org/1999/xlink%22%20version=%221.1%22%20x=%220px%22%20y=%220px%22%20viewBox=%220%200%20445%20262%22%20xml:space=%22preserve%22%20height=%22262px%22%20width=%22445px%22%3E%20%3Crect%20width=%22445%22%20height=%22262%22%20style=%22fill:rgb(255,255,255);%22/%3E%3C/svg%3E)

The `ApiRequestManager` is divided into precise pieces and is composed of these separated types you just extracted.

You can now reason about each type individually. Also, if a bug exists, such as in the caching mechanism, you don’t need to look inside a giant `ApiRequestManager` class. You can most likely find the bug inside the `ResponseCache` type.

Not only are fewer managers great for getting work done faster—did I say that out loud?—you also gain clarity when writing software in smaller components.

#### 14.4.3. Paving the road for generics

Now that the big `ApiRequestManager` has been cut up into smaller types, you can more easily decide which of these new types you can repurpose, so that they aren’t limited to the network domain.

For example, the `ResponseCache` and `RequestQueue` types are focused explicitly on network-related functionality. But it’s not a big leap to imagine that a cache and queue work on other types, too. If queueing and caching mechanisms are required in multiple parts of an application, you can decide to spend some effort to make `ResponseCache` and `ResponseQueue` generic, indicated with a `<T>` (see [figure 14.9](https://livebook.manning.com/book/swift-in-depth/chapter-14/ch14fig9)).

![Figure 14.9. Making types generic](data:image/svg+xml;utf8,%3Csvg%20xmlns=%22http://www.w3.org/2000/svg%22%20xmlns:xlink=%22http://www.w3.org/1999/xlink%22%20version=%221.1%22%20x=%220px%22%20y=%220px%22%20viewBox=%220%200%20434%20205%22%20xml:space=%22preserve%22%20height=%22205px%22%20width=%22434px%22%3E%20%3Crect%20width=%22434%22%20height=%22205%22%20style=%22fill:rgb(255,255,255);%22/%3E%3C/svg%3E)

You drop the `Response` and `Request` names to gain a `Queue` and `Cache` type for elements outside of the network domain, and you would also refactor these types to make them generic in functionality (see [figure 14.10](https://livebook.manning.com/book/swift-in-depth/chapter-14/ch14fig10)).

![Figure 14.10. Reusing generic types](data:image/svg+xml;utf8,%3Csvg%20xmlns=%22http://www.w3.org/2000/svg%22%20xmlns:xlink=%22http://www.w3.org/1999/xlink%22%20version=%221.1%22%20x=%220px%22%20y=%220px%22%20viewBox=%220%200%20434%20204%22%20xml:space=%22preserve%22%20height=%22204px%22%20width=%22434px%22%3E%20%3Crect%20width=%22434%22%20height=%22204%22%20style=%22fill:rgb(255,255,255);%22/%3E%3C/svg%3E)

This time you can use the generic `Queue` and `Cache` types to queue and cache network requests and responses. But in some other part of your application, thanks to generics, you can use a queue and cache for storing and uploading image data, for example.

Having smaller types with a clear responsibility makes building larger types easier. Add generics on top of that and you have a Swifty approach to deal with core functionality inside an application.

As a counterpoint to generics, creating a generic type from the start isn’t always fruitful. You might look at a chair and a couch and think “I only need a generic `Seat` type.” It’s okay to resist *DRY* (Don’t Repeat Yourself) once in a while. Sometimes duplication is a fine choice when you’re not sure which direction your project is going.

### 14.5. Naming abstractions

Naming your classes, variables, and files in programming can be harder than naming a firstborn baby or your pets, especially when you’re giving names to things that are intricate and encompass several different behaviors.

This section shows how you can name types closer to the abstract while considering some as generic candidates as well.

#### 14.5.1. Generic versus specific

If you give a programmer the task of creating a button to submit a registration form inside a program, I think it would be fair to assume that you don’t want them to create an abstract `Something` class to represent this button. Neither would an oddly overspecific name such as `CommonRegistrationButtonUsedInFourthScreen` be favorable.

Given this example, I hope you can agree that the fitting name is most likely somewhere between the abstract and specific examples.

#### 14.5.2. Good names don’t change

What can happen in software development is a mismatch between what a type can do versus how it’s used.

Imagine that you’re creating an app that displays the top five coffee places. The app reads a user’s past locations and figures out where the user visited most often.

A first thought may be to create a `FavoritePlaces` type. You feed this type a large number of locations, and it returns the five most-visited places. Then you can filter on the coffee types, as shown in this example.

##### Listing 14.6. Getting important places

```
let locations = ... // extracted locations.
let favoritePlaces = FavoritePlaces(locations: locations)
let topFiveFavoritePlaces = favoritePlaces.calculateMostCommonPlaces()

let coffeePlaces = topFiveFavoritePlaces.filter { place in place.type == 
     "Coffee" }
```

But now the client calls and wants to add new functionality to the application. They also want the app to show which coffee places the user has visited the least, so that they can encourage the user to revisit these places.

Unfortunately, you can’t use the `FavoritePlaces` type again. The type does have all the inner workings to group locations and fulfill this new requirement, but the name specifically mentions that it uses favorite places only, not the least-visited places.

What happened is that the type’s name is overspecified. The type is named after how it is used, which is to find the favorite places. But the type’s name would be better if you can name it after what it does, which is find and group occurrences of places (see [figure 14.11](https://livebook.manning.com/book/swift-in-depth/chapter-14/ch14fig11)).

![Figure 14.11. Naming a type after what it does](data:image/svg+xml;utf8,%3Csvg%20xmlns=%22http://www.w3.org/2000/svg%22%20xmlns:xlink=%22http://www.w3.org/1999/xlink%22%20version=%221.1%22%20x=%220px%22%20y=%220px%22%20viewBox=%220%200%20500%20294%22%20xml:space=%22preserve%22%20height=%22294px%22%20width=%22500px%22%3E%20%3Crect%20width=%22500%22%20height=%22294%22%20style=%22fill:rgb(255,255,255);%22/%3E%3C/svg%3E)

The point is that good names don’t change. If you started with a `LocationGrouper` type, you could use it directly for both scenarios by adding a `leastVisitedPlaces` property; this would have prevented a naming refactor or a new type.

Ending up with a bad name is a small point, but it can happen effortlessly and subtly. Before you know it, you might have too many brittle names in a codebase. For example, don’t use something like `redColor` as a button’s property for a warning state; a `warning` property might be better because the warning’s design might change, but a warning’s purpose won’t. Alternatively, when creating a `UserheaderView`—which is nothing more than an image and label you can reuse as something else—perhaps `ImageDescriptionView` would be more fitting as well as reusable.

#### 14.5.3. Generic naming

The more abstract you make your types, the easier it is to make them generic. For example, a `LocationGrouper` is not too far removed from a `Grouper<T>` type, in which `T` could represent `CLLocation` such as `Grouper<CLLocation>`. But `Grouper` as a generic type can also be used to group something else, perhaps ratings for places, in which case you’d be reusing the type as `Grouper<Rating>`.

Making a type generic should not be the goal. The more specific you can make a type, the easier it is to understand. The more generic a type is, the more reusable (but harder to grasp) it can be. But as long as the type’s name fits a type’s purpose, you’ve hit the sweet spot.

### 14.6. Checklist

Next time you create a project, see if you can follow a short checklist to bump the quality of your deliverables:

- Quick Help documentation
- Sparse but useful comments explaining the *why*
- Adding SwiftLint to your project
- Cutting classes with too many responsibilities
- Naming types after what they do, not how they are used

### 14.7. Closing thoughts

Even though this wasn’t a code-centric chapter, its ideas are still valuable. When you keep a consistent, clean codebase, you may make lives more comfortable for yourself and developers around you.

If you liked this chapter, I recommend reading Swift’s API design guidelines ([http://mng.bz/XAMG](http://mng.bz/XAMG)). It’s jam-packed with useful naming conventions.

You’re almost finished; in the next chapter I have some suggestions for you on what you can do next.

### Summary

- Quick Help documentation is a fruitful way to add small snippets of documentation to your codebase.
- Quick Help documentation is especially valuable to public and internal elements offered inside a project and framework.
- Quick Help supports many useful callouts that enrich documentation.
- You can use Jazzy to generate Quick Help documentation.
- Comments explain the “why,” not the “what”.
- Be stingy with comments.
- Comments are no bandage for bad naming.
- There’s no need to let commented-out code, aka Zombie Code, linger around.
- Code consistency is more important than code style.
- Consistency can be enforced by installing SwiftLint.
- SwiftLint supports configurations that you can let your team decide, which helps eliminate style discussions and disagreements.
- Manager classes can drop the `-Manager` suffix and still convey the same meaning.
- A large type can be composed of smaller types with focused responsibilities.
- Smaller components are good candidates to make generic.
- Name your types after what they do, not how they are used.
- The more abstract a type is, the more easily you can make it generic and reusable.
