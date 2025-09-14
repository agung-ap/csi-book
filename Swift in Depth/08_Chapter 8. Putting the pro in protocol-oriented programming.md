# Chapter 8. Putting the pro in protocol-oriented programming

### ***This chapter covers***

- The relationship and trade-offs between generics and using protocols as types
- Understanding associated types
- Passing around protocols with associated types
- Storing and constraining protocols with associated types
- Simplifying your API with protocol inheritance

Protocols bring a lot of power and flexibility to your code. Some might say it’s Swift’s flagship feature, especially since Apple markets Swift as a *protocol-oriented-programming* language. But as lovely as protocols are, they can become difficult fast. Plenty of subtleties are involved, such as using protocols at runtime or compile time, and constraining protocols with associated types.

This chapter’s goal is to lay down a solid foundation regarding protocols; it will shed light on using protocols as an interface versus using protocols to constrain generics. This chapter also aims to carry you over the hump of what can be considered advanced protocols, which are protocols with associated types. The end goal is to make sure you understand why, when, and how to apply protocols (and generics) in multiple scenarios. The only requirements are that you’re at least a little bit familiar with protocols and that you have read [chapter 7](https://livebook.manning.com/book/swift-in-depth/chapter-7/ch07), “Generics.” After this chapter, protocols and associated types will repeatedly return, so I recommend not to skip this one!

First, you’ll take a look to see how protocols fare by themselves, versus using protocols to constrain generics. You’ll look at both sides of the coin and take on two approaches. One approach uses generics, and the other does not. The aim of this chapter is that you’ll be able to make trade-offs and decide on a proper approach in day-to-day programming.

In the second section, you’ll move on to the more difficult aspect of protocols, which is when you start using associated types. You can consider protocols with associated types as generic protocols, and you’ll discover why you would need them and when you can apply them in your applications.

Once you start passing around protocols with associated types, you’re working with very flexible code. But things will get tricky. You’ll take a closer look to see how to pass protocols with associated types around, and how to create types that store them with constraints. On top of that, you’ll apply a nice trick to clean up your APIs by using a technique called protocol inheritance.

### 8.1. Runtime versus compile time

So far, this book has covered generics extensively and how they relate to protocols. With generics, you create polymorphic functions defined at compile time. But protocols don’t always have to be used with generics if you want to gain particular runtime—also known as *dynamic dispatch*—benefits. In this section, you’re going to create a protocol, and then you’ll see how to make trade-offs between generics constrained by protocols, and how to use protocols as types without using generics.

#### 8.1.1. Creating a protocol

##### Join Me!

It’s more educational and fun if you can check out the code and follow along with the chapter. You can download the source code at [http://mng.bz/qJZ2](http://mng.bz/qJZ2).

You’ll start building a cryptocoin portfolio that can hold coins such as Bitcoin, Ethereum, Litecoin, Neo, Dogecoin, and a bazillion others.

You don’t want to write a portfolio or function for each coin, especially with the hundreds of other coins that your application may support. You’ve seen before how you can use enums to work with polymorphism, which is often a suitable approach. But enums, in this case, would be too restrictive. You would have to declare a case for each coin (which could be hundreds!). Alternatively, what if you offer a framework, but then implementers can’t add more cases to the types of coins? In these cases, you can use protocols, which are a more flexible way to achieve polymorphism. If you introduce a protocol, you and others can adhere to this protocol for each coin.

To showcase this method, you’ll introduce a protocol, as shown in the following listing, called `CryptoCurrency`, with four properties called `name`, `symbol`, and `price` (for the current price in the user’s currency setting) and `holdings` (representing the number of coins a user has).

##### Listing 8.1. A `CryptoCurrency` protocol

```
12345678import Foundation

protocol CryptoCurrency {
    var name: String { get }
    var symbol: String { get }
    var holdings: Double { get set }
    var price: NSDecimalNumber? { get set }
}
```

You are taking advantage of commonalities where you define the minimum properties that each coin should have. Protocols are like blueprints in this way; you can write functions and properties that work only on a `CryptoCurrency` protocol, not needing to know about the coin that’s passed to it.

As a next step, you declare a few coins that adhere to this protocol.

##### Listing 8.2. Declaring coins

```
12345678910111213struct Bitcoin: CryptoCurrency {
    let name = "Bitcoin"
    let symbol = "BTC"
    var holdings: Double
    var price: NSDecimalNumber?
}

struct Ethereum: CryptoCurrency {
    let name = "Ethereum"
    let symbol = "ETH"
    var holdings: Double
    var price: NSDecimalNumber?
}
```

##### Var or Let

Whenever you declare properties on a protocol, they are always a `var`. The implementer can then choose to make it a `let` or `var` property. Also, if the protocol has a `get` `set` modifier on a property, the implementer has to offer a `var` to allow for mutation.

#### 8.1.2. Generics versus protocols

Let’s build a portfolio that can hold some coins for a customer. You’ve seen before how you can use generics to work with a protocol. You’ll start with the next listing by taking the generics approach and quickly see the problem that accompanies it.

##### Listing 8.3. Introducing a portfolio (won’t fully work yet!)

```
final class Portfolio<Coin: CryptoCurrency> {        #1
    var coins: [Coin]                                #2
 
    init(coins: [Coin]) {
        self.coins = coins
    }

    func addCoin(_ newCoin: Coin) {
        coins.append(newCoin)
    }

    // ... snip. We are leaving out removing coins, calculating the total
     value, and other functionality.
}
```

The previous code is a small segment of a larger `Portfolio` class, which can have more functionality, such as removing coins, tracking gains and losses, and other use cases.

##### Pop Quiz

The `Portfolio` class has a problem. Can you detect it?

#### 8.1.3. A trade-off with generics

There’s a shortcoming. The Coin generic represents a single type, so you can only add one type of coin to your portfolio.

##### Listing 8.4. Trying to add different coins to the `Portfolio`

```
let coins = [
    Ethereum(holdings: 4, price: NSDecimalNumber(value: 500)),      #1
    // If we mix coins, we can't pass them to Portfolio
    // Bitcoin(holdings: 4, price: NSDecimalNumber(value: 6000))    #2
 ]
let portfolio = Portfolio(coins: coins)                             #2
```

Currently, the portfolio contains an Ethereum coin. Because you used a generic, `Coin` inside the portfolio is now pinned to Ethereum coins. Because of generics, if you add a different coin, such as Bitcoin, you’re stopped by the compiler, as shown in this listing.

##### Listing 8.5. Can’t mix protocols with generics

```
let btc = Bitcoin(holdings: 3, price: nil)
portfolio.addCoin(btc)

error: cannot convert value of type 'Bitcoin' to expected argument type 'Ethereum'
```

The compiler smacks you with an error. At compile time, the `Portfolio` initializer resolves the generic to `Ethereum`, which means that you can’t add different types to the portfolio. You can confirm as well by checking the type of coins that `Portfolio` holds, as shown in this example.

##### Listing 8.6. Checking the type of coins

```
print(type(of: portfolio)) // Portfolio<Ethereum>
print(type(of: portfolio.coins)) // Array<Ethereum>
```

##### Type(Of: )

By using `type(of:)` you can inspect a type.

Generics give you benefits, such as knowing what types you’re dealing with at compile time. The compiler can also apply performance optimizations because of this extra information.

But in this case, you don’t want to pin down the `Coin` type at compile time. You want to mix and match coins and even add new coins at runtime. To meet this requirement, you’re going to move from compile time to runtime, so it’s time to step away from generics. Not to worry; you’ll keep using the `CryptoCurrency` protocol.

#### 8.1.4. Moving to runtime

You move to runtime by removing the generic. In th next example, you’ll refactor `Portfolio` so that it holds coins that adhere to `CryptoCurrency`.

##### Listing 8.7. A dynamic `Portfolio`

```
// Before
final class Portfolio<Coin: CryptoCurrency> {
    var coins: [Coin]

    // ... snip
}

// After
final class Portfolio {             #1
     var coins: [CryptoCurrency]    #2
 
    // ... snip
}
```

The portfolio has no generic and holds only `CryptoCurrency` types. You can mix and match the types inside the `CryptoCurrency` array, as indicated next by adding multiple types of coins.

##### Listing 8.8. Mixing and match coins

```
// No need to specify what goes inside of portfolio.
let portfolio = Portfolio(coins: [])                    #1
 
// Now we can mix coins.
let coins: [CryptoCurrency] = [
    Ethereum(holdings: 4, price: NSDecimalNumber(value: 500)),
    Bitcoin(holdings: 4, price: NSDecimalNumber(value: 6000))
]
portfolio.coins = coins                                 #2
```

By stepping away from generics, you gain flexibility back.

#### 8.1.5. Choosing between compile time and runtime

It’s a subtle distinction, but these examples showcase how generics are defined in the compile-time world and how protocols as types live in the runtime world.

If you use a protocol at runtime, you could think of them as interfaces or types. As shown in the following example, if you check the types inside the `coins` array, you get an array of `Crypto-Currency`, whereas before the array resolved to one type, namely `[Ethereum]` and potentially others.

##### Listing 8.9. Checking an array

```
print(type(of: portfolio)) // Portfolio

let retrievedCoins = portfolio.coins
print(type(of: retrievedCoins)) // Array<CryptoCurrency>
```

Using a protocol at runtime means you can mix and match all sorts of types, which is a fantastic benefit. But the type you’re working with is a `CryptoCurrency` protocol. If `Bitcoin` has a special method called `bitcoinStores()`, you wouldn’t be able to access it from the portfolio unless the protocol has the method defined as well, which means all coins now have to implement this method. Alternatively, you could check at runtime if a coin is of a specific type, but that can be considered an anti-pattern and doesn’t scale with hundreds of possible coins.

#### 8.1.6. When a generic is the better choice

Let’s consider another scenario that showcases another difference between protocols as a type and using protocols to constrain generics. This time, constraining a generic with a protocol is the better choice.

For example, you can have a function called `retrievePrice`. You pass this function a coin, such as a `Bitcoin` struct or `Ethereum` struct, and you receive the same coin but updated with its most recent price. Next, you can see two similar functions: one with a generic implementation for compile time use, and one with a protocol as a type for runtime use.

##### Listing 8.10. A generic protocol vs. a runtime protocol

```
func retrievePriceRunTime(coin: CryptoCurrency, completion: ((CryptoCurrency)
     -> Void) ) {                                                          #1
     // ... snip. Server returns coin with most-recent price.
    var copy = coin
    copy.price = 6000
    completion(copy)
}

func retrievePriceCompileTime<Coin: CryptoCurrency>(coin: Coin,
 completion: ((Coin) -> Void)) {                                         #2
     // ... snip. Server returns coin with most-recent price.
    var copy = coin
    copy.price = 6000
    completion(copy)
}

let btc = Bitcoin(holdings: 3, price: nil)
retrievePriceRunTime(coin: btc) { (updatedCoin: CryptoCurrency) in         #3
     print("Updated value runtime is \(updatedCoin.price?.doubleValue ?? 0)")
}

retrievePriceCompileTime(coin: btc) { (updatedCoin: Bitcoin) in            #4
     print("Updated value compile time is \(updatedCoin.price?.doubleValue
     ?? 0)")
}
```

Thanks to generics, you know exactly what type you’re working with inside the closure. You lose this benefit when using a protocol as a type.

Having generics appear inside your application may be wordy, but I hope you’re encouraged to use them because of their benefits compared to runtime protocols.

Generally speaking, using a protocol as a type speeds up your programming and makes mixing and swapping things around easier. Generics are more restrictive and wordy, but they give you performance benefits and compile-time knowledge of the types you’re implementing. Generics are often the better (but harder) choice, and in some cases they’re the only choice, which you’ll discover next when implementing protocols with associated types.

#### 8.1.7. Exercises

1. Given this protocol

protocol AudioProtocol {}

copy

what is the difference between the following statements?

func loadAudio(audio: AudioProtocol) {}
func loadAudio<T: AudioProtocol>(audio: T) {}

copy

1. How would you decide to use a generic or nongeneric protocol in the following example?

protocol Ingredient {}
struct Recipe<I: Ingredient> {
let ingredients: [I]
let instructions: String
}

copy

1. How would you decide to use a generic or nongeneric protocol in the following struct?

protocol APIDelegate {
func load(completion:(Data) -> Void)
}
struct ApiLoadHandler: APIDelegate {
func load(completion: (Data) -> Void) {
print("I am loading")
}
}
class API {
private let delegate: APIDelegate?

init(delegate: APIDelegate) {
self.delegate = delegate
}
}
let dataModel = API(delegate: ApiLoadHandler())

copy

### 8.2. The why of associated types

Let’s go more in-depth and work with what may be considered *advanced protocols*, also known as protocols with associated types—or PATs for short, to go easy on the finger-joints of yours truly.

Protocols are abstract as they are, but with PATs, you’re making your protocols generic, which makes your code even more abstract and exponentially complex.

Wielding PATs is a useful skill to have. It’s one thing to hear about them, nod, and think that they may be useful for your code one day. But I aim to make you understand PATs profoundly and feel comfortable with them, so that at the end of this section, PATs don’t intimidate you, and you feel ready to start implementing them (when it makes sense to do so).

In this section, you start by modeling a protocol and keep running into shortcomings, which you ultimately will solve with associated types. Along the way, you get to experience the reasoning and decision making of why you want to use PATs.

#### 8.2.1. Running into a shortcoming with protocols

Imagine that you want to create a protocol resembling a piece of work that it needs to perform. It could represent a job or task, such as sending emails to all customers, migrating a database, resizing images in the background, or updating statistics by gathering information. You can model this piece of code via a protocol you’ll call `Worker`.

The first type you’ll create and conform to `Worker` is `MailJob`. `MailJob` needs a `String` email address for its input, and returns a `Bool` for its output, indicating whether the job finished successfully. You’ll start naïvely and reflect the input and output of `MailJob` in the `Worker` protocol. `Worker` has a single method, called `start`, that takes a `String` for its input and a `Bool` for its output, as in the following listing.

##### Listing 8.11. The `Worker` protocol

```
protocol Worker {

     @discardableResult                       #1
     func start(input: String) -> Bool        #2
 }

class MailJob: Worker {                       #3
     func start(input: String) -> Bool {
        // Send mail to email address (input can represent an email address)
        // On finished, return whether or not everything succeeded
        return true
    }
}
```

##### Note

Normally you may want to run a worker implementation in the background, but for simplicity you keep it in the same thread.

But `Worker` does not cover all the requirements. `Worker` fits the needs for `MailJob`, but doesn’t scale to other types that may not have `String` and `Bool` as their input and output.

Let’s introduce another type that conforms to `Worker` and specializes in removing files and call it `FileRemover`. `FileRemover` accepts a `URL` type as input for its directory, removes the files, and returns an array of strings representing the files it deleted. Since `FileRemover` accepts a `URL` and returns `[String]`, it can’t conform to `Worker` (see [figure 8.1](https://livebook.manning.com/book/swift-in-depth/chapter-8/ch08fig1)).

![Figure 8.1. Trying to conform to Worker](https://drek4537l1klr.cloudfront.net/veen/Figures/08fig01.jpg)

Unfortunately, the protocol doesn’t *scale* well. Try two different approaches before heading to the solution involving protocols with associated types.

#### 8.2.2. Trying to make everything a protocol

Before you solve your problem with associated types, consider a solution that involves more protocols. How about making `Input` and `Output` a protocol, too? This seems like a valid suggestion—it allows you to avoid PATs altogether. But this approach has issues, as you are about to witness.

##### Listing 8.12. `Worker` without associated types

```
protocol Input {}                           #1
protocol Output {}                          #1
 
protocol Worker {
    @discardableResult
    func start(input: Input) -> Output      #2
}
```

This approach works. But for *every* type you want to use for the input and output, you’d have to make multiple types adhere to the `Input` and `Output` protocols. This approach is a surefire way to end up with boilerplate, such as making `String`, `URL`, and `[URL]` adhere to the `Input` protocol, and again for the `Output` protocol. Another downside is that you’re introducing a new protocol for each parameter and return type. On top of that, if you were to introduce a new method on `Input` or `Output`, you would have to implement it on *all* the types adhering to these protocols. Making everything a protocol is viable on a smaller project, but it won’t scale nicely, causes boilerplate, and puts a burden on the developers that conform to your protocol.

![8.2.3. Designing a generic protocol](https://drek4537l1klr.cloudfront.net/veen/Figures/08fig02.jpg)

Let’s take a look at another approach where you’d like both `MailJob` and `FileRemover` to conform to `Worker`. In the next listing, you’ll first approach your solution naïvely (which won’t compile), but it highlights the motivation of associated types. Then, you’ll solve your approach with associated types.

The `Worker` protocol wants to make sure that each implementation can decide for itself what the input and output represents. You can attempt this by defining two generics on the protocol, called `Input` and `Output`. Unfortunately, your approach won’t work yet—let’s see why.

##### Listing 8.13. A `Worker` protocol (won’t compile yet!)

```
protocol Worker<Input, Output> {           #1
    @discardableResult
    func start(input: Input) -> Output     #2
 }
```

Swift quickly stops you:

```
error: protocols do not allow generic parameters; use associated types instead
```

Swift doesn’t support protocols with generic parameters. If Swift would support a generic protocol, you would need to define a concrete type on the protocol on an implementation. For instance, let’s say you model the `MailJob` class with the `Input` generic set to `String` and the `Output` generic set to `Bool`. Its implementation would then be `class` `MailJob:` `Worker<String,` `Bool>`. Since the `Worker` protocol would be generic, you theoretically could implement `Worker` multiple times on `MailJob`. Multiple implementations of the same protocol, however, do not compile, as shown in this listing.

##### Listing 8.14. Not supported: a `MailJob` implementing `Worker` multiple times

```
// Not supported: Implementing a generic Worker.
class MailJob: Worker<String, Bool> {              #1
     // Implementation omitted
}

class MailJob: Worker<Int, [String]> {             #1
     // Implementation omitted
}

// etc
```

At the time of writing, Swift doesn’t support multiple implementations of the same protocol. What Swift does support, however, is that you can implement a protocol only once for each type. In other words, `MailJob` gets to implement `Worker` once. Associated types give you this balance of making sure that you can implement a protocol once while working with generic values. Let’s see how this works.

#### 8.2.4. Modeling a protocol with associated types

You’ve seen two alternatives that were not the real solutions to your problem. You’ll create a viable solution to the problem. You’re going to follow the compiler’s advice and use associated types. You can rewrite `Worker` and use the `associatedtype` keyword, where you declare both the `Input` and `Output` generics as associated types.

##### Listing 8.15. `Worker` with associated types

```
protocol Worker {                         #1
    associatedtype Input                  #2
    associatedtype Output                 #2
 
    @discardableResult
    func start(input: Input) -> Output    #3
}
```

Now the `Input` and `Output` generics are declared as associated types. Associated types are similar to generics, but they are defined *inside* a protocol. Notice how `Worker` does not have the `<Input,` `Output>` notation. With `Worker` in place, you can start to conform to it for both `MailJob` and `FileRemover`.

#### 8.2.5. Implementing a PAT

The `Worker` protocol is ready to be implemented. Thanks to associated types, both `Mailjob` and `FileRemover` can successfully conform to `Worker`. `MailJob` sets the `Input` and `Output` to `String` and `Bool`, whereas `FileRemover` sets the `Input` and `Output` to `URL` and `[String]` (see [figure 8.2](https://livebook.manning.com/book/swift-in-depth/chapter-8/ch08fig2)).

![Figure 8.2. Worker implemented](https://drek4537l1klr.cloudfront.net/veen/Figures/08fig03.jpg)

Looking at the details of `MailJob` in the next listing, you can see that it sets the `Input` and `Output` to concrete types.

##### Listing 8.16. `Mailjob` (implementation omitted)

```
class MailJob: Worker {
    typealias Input = String                    #1
    typealias Output = Bool                     #2
 
    func start(input: String) -> Bool {
        // Send mail to email address (input can represent an email address)
        // On finished, return whether or not everything succeeded
        return true
    }
}
```

Now, `MailJob` always uses `String` and `Bool` for its `Input` and `Output`.

##### Note

Each type conforming to a protocol can only have a single implementation of a protocol. But you still get generic values with the help of associated types. The benefit is that each type can decide what these associated values represent.

The implementation of `FileRemover` is different than `MailJob`, and its associated types are also of different types. Note, as shown in the following, that you can omit the `typealias` notation if Swift can infer the associated types.

##### Listing 8.17. The `FileRemover`

```
class FileRemover: Worker {
//    typealias Input = URL                                                #1
//    typealias Output = [String]                                          #1
 
    func start(input: URL) -> [String] {
        do {
            var results = [String]()
            let fileManager = FileManager.default
            let fileURLs = try fileManager.contentsOfDirectory(at: input, 
 includingPropertiesForKeys: nil)                                        #2
 
            for fileURL in fileURLs {
                try fileManager.removeItem(at: fileURL)                    #2
                results.append(fileURL.absoluteString)
            }

            return results
        } catch {
            print("Clearing directory failed.")
            return []
        }
    }
}
```

When using protocols with associated types, multiple types can conform to the same protocol; yet, each type can define what an associated type represents.

##### Tip

Another way to think of an associated type is that it’s a generic, except it’s a generic that lives inside a protocol.

#### 8.2.6. PATs in the standard library

Swift uses associated types all around the standard library, and you’ve been using a few already!

The most common uses of a PAT are the `IteratorProtocol`, `Sequence`, and `Collection-` protocols. These protocols are conformed to by `Array`, `String`, `Set`, `Dictionary`, and others, which use an associated type called `Element`, representing an element inside the collection. But you’ve also seen other protocols, such as `Raw-Representable` on enums where an associated type called `RawValue` allows you to transform any type to an enum and back again.

##### SELF REQUIREMENTS

Another flavor of an associated type is the `Self` keyword. A common example is the `Equatable` protocol, which you saw in [chapter 7](https://livebook.manning.com/book/swift-in-depth/chapter-7/ch07). With `Equatable`, two of the same types—represented by `Self`—are compared. As shown in this listing, `Self` resolves to the type that conforms to `Equatable`.

##### Listing 8.18. `Equatable`

```
public protocol Equatable {
  static func == (lhs: Self, rhs: Self) -> Bool      #1
}
```

#### 8.2.7. Other uses for associated types

Bending your mind around PATs can be tough. A protocol with an associated type is a generic protocol, making it harder to reason about. Introducing associated types starts making sense when conformers of a protocol use different types in their implementation. Generally speaking, PATs tend to pop up more often in frameworks because of a higher chance of reusability.

Here are some use cases for associated types:

- *A `Recording` protocol*—Each recording has a duration, and it could also support scrubbing through time via a `seek()` method, but the actual data could be different for each implementation, such as an audio file, video file, or YouTube stream.
- *A `Service` protocol*—It loads data; one type could return JSON data from an API, and another could locally search and return raw string data.
- *A `Message` protocol*—It’s on a social media tool that tracks posts. In one implementation, a message represents a Tweet; in another, a message represents a Facebook direct message; and in another, it could be a message on WhatsApp.
- *A `SearchQuery` protocol*—It resembles database queries, where the result is different for each implementation.
- *A `Paginator` protocol*—It can be given a page and offset to browse through a database. Each page could represent some data. Perhaps it has some users in a user table in a database, or perhaps a list of files, or a list of products inside a view.

#### 8.2.8. Exercise

1. Consider the following subclassing hierarchy for a game, where you have enemies that can attack with a specific type of damage. Can you replace this subclassing hierarchy with a protocol-based solution?

class AbstractDamage {}

class AbstractEnemy {
func attack() -> AbstractDamage {
fatalError("This method must be implemented by subclass")
}
}

class Fire: AbstractDamage {}
class Imp: AbstractEnemy {
override func attack() -> Fire {
return Fire()
}
}

class BluntDamage: AbstractDamage {}
class Centaur: AbstractEnemy {
override func attack() -> BluntDamage {
return BluntDamage()
}
}

copy

### 8.3. Passing protocols with associated types

![](https://drek4537l1klr.cloudfront.net/veen/Figures/08fig04.jpg)

Let’s see the ways you can pass a protocol with associated types around. You’ll use the `Worker` protocol from the last section with two associated types named `Input` and `Output`.

Imagine that you want to write a generic function or method that accepts a single worker and an array of elements that this worker must process. By passing an array of type `[W.Input]`, where `W` represents a `Worker`, you make sure that the `Input` associated type is the exact type the `Worker` can handle (see figure 8.5). PATs can only be implemented as generic constraints—with some complicated exceptions aside—so you’ll use generics to stay in the world of compile-time code.

##### Note

You can safely omit any references to `W.Output` in `runWorker` because you’re not doing anything with it.

![Figure 8.3. Passing the same input to multiple workers](https://drek4537l1klr.cloudfront.net/veen/Figures/08fig05_alt.jpg)

With `runWorker` in place, you can pass it multiple `Worker` types, such as a `MailJob` or a `FileRemover`, as shown in the next listing. Make sure that you pass matching `Input` types for each worker; you pass strings for `MailJob` and URLs to `FileRemover`.

##### Listing 8.19. Passing multiple workers

```
let mailJob = MailJob()
runWorker(worker: mailJob, input: ["grover@sesamestreetcom", "bigbird@sesames
     treet.com"])                                                          #1
 
let fileRemover = FileRemover()
runWorker(worker: fileRemover, input: [                                    #2
    URL(fileURLWithPath: "./cache", isDirectory: true),
    URL(fileURLWithPath: "./tmp", isDirectory: true),
    ])
```

##### Note

Like generics, associated types get resolved at compile time, too.

#### 8.3.1. Where clauses with associated types

You can constrain associated types in functions with a *where* clause, which becomes useful if you want to specialize functionality somewhat. Constraining associated types is very similar to constraining a generic, yet the syntax is slightly different.

For instance, let’s say you want to process an array of users; perhaps you need to strip empty spaces from their names or update other values. You can pass an array of users to a single worker. You can make sure that the `Input` associated type is of type `User` with the help of a *where* clause so that you can print the users’ names the worker is processing. By constraining an associated type, the function is specialized to work only with users as input.

##### Listing 8.20. Constraining the `Input` associated type

```
final class User {                                                          #1
    let firstName: String
    let lastName: String
    init(firstName: String, lastName: String) {
        self.firstName = firstName
        self.lastName = lastName
    }
}

func runWorker<W>(worker: W, input: [W.Input])
where W: Worker, W.Input == User {                                          #2
     input.forEach { (user: W.Input) in
        worker.start(input: user)
        print("Finished processing user \(user.firstName) \(user.lastName)")#3
     }
}
```

#### 8.3.2. Types constraining associated types

You just saw how associated types get passed via functions. Now focus on how associated types work with types such as structs, classes, or enums.

As an example, you could have an `ImageProcessor` class that can store a `Worker` type (see figure 8.6). Workers in this context could be types that crop an image, resize an image, or turn them to sepia. What exactly this `ImageProcessor` does depends on the `Worker`. The added value of the `ImageProcessor` is that it can batch process a large number of images by getting them out of a store, such as a database.

![Figure 8.4. ImageProcessor](data:image/svg+xml;utf8,%3Csvg%20xmlns=%22http://www.w3.org/2000/svg%22%20xmlns:xlink=%22http://www.w3.org/1999/xlink%22%20version=%221.1%22%20x=%220px%22%20y=%220px%22%20viewBox=%220%200%20500%20263%22%20xml:space=%22preserve%22%20height=%22263px%22%20width=%22500px%22%3E%20%3Crect%20width=%22500%22%20height=%22263%22%20style=%22fill:rgb(255,255,255);%22/%3E%3C/svg%3E)

The `ImageProcessor` accepts an `ImageCropper` that is of type `Worker`.

##### Listing 8.21. Calling the `ImageProcessor`

```
let cropper = ImageCropper(size: CGSize(width: 200, height: 200))
let imageProcessor: ImageProcessor<ImageCropper> = ImageProcessor(worker:
 cropper)                                                                #1
```

First you’ll introduce the `Worker`, which in this case is `ImageCropper`. The implementation is omitted to focus on the protocol conformance.

##### Listing 8.22. `ImageCropper`

```
final class ImageCropper: Worker {

    let size: CGSize
    init(size: CGSize) {
        self.size = size
    }

    func start(input: UIImage) -> Bool {
        // Omitted: Resize image to self.size
        // return bool to indicate that the process succeeded
        return true
    }
}
```

Here is where you’ll create the `ImageProcessor` type. `ImageProcessor` accepts a generic `Worker`. But this `Worker` has two constraints: the first constraint sets the `Input` to type `UIImage`, and the `Output` is expected to be a Boolean, which reflects whether the job of the `Worker` was completed successfully or not.

You can constrain the associated types of `Worker` with a *where* clause. You can write this *where* clause before the opening brackets of `ImageProcessor`, as shown here.

##### Listing 8.23. The `ImageProcessor` type

```
final class ImageProcessor<W: Worker>                              #1
 where W.Input == UIImage, W.Output == Bool {                      #2
 
    let worker: W

    init(worker: W) {
        self.worker = worker
    }

    private func process() {                                       #3
        // start batches

        let amount = 50
        var offset = 0
        var images = fetchImages(amount: amount, offset: offset)
        var failedCount = 0
        while !images.isEmpty {                                    #4
 
            for image in images {
                if !worker.start(input: image) {                   #5
                     failedCount += 1
                }
            }

            offset += amount
            images = fetchImages(amount: amount, offset: offset)
        }

        print("\(failedCount) images failed")
    }

    private func fetchImages(amount: Int, offset: Int) -> [UIImage] {
        // Not displayed: Return images from database or harddisk
        return [UIImage(), UIImage()]                              #6
     }
}
```

By accepting a generic `Worker`, the `ImageProcessor` class can accept different types, such as image croppers, resizers, or one that makes an image black and white.

#### 8.3.3. Cleaning up your API with protocol inheritance

Depending on how generic this application turns out, you may end up passing a generic `Worker` around. Redeclaring the same constraints—such as `where` `W.Input` `==` `UIImage,` `W.Output` `==` `Bool`—may get tiresome, though.

For convenience, you can apply protocol inheritance to further constrain a protocol. Protocol inheritance means that you create a new protocol that inherits the definition of another protocol. Think of it like subclassing a protocol.

You can create an `ImageWorker` protocol that inherits all the properties and functions from the `Worker` protocol, but with one big difference: the `ImageWorker` protocol constrains the `Input` and `Output` associated types with a *where* clause, as shown here.

##### Listing 8.24. The `ImageWorker`

```
protocol ImageWorker: Worker where Input == UIImage, Output == Bool {
    // extra methods can go here if you want
}
```

##### Protocol Extension

In this case, `ImageWorker` is empty, but note that you can add extra protocol definitions to it if you’d like. Then types adhering to `ImageWorker` must implement these on top of the `Worker` protocol.

With this protocol, the *wher**e* clause is implied, and passing an `ImageWorker` around means that types don’t need to manually constrain to `Image` and `Bool` anymore. The `ImageWorker` protocol can make the `API` of `ImageProcessor` a bit cleaner.

##### Listing 8.25. No need to constrain anymore

```
// Before:
final class ImageProcessor<W: Worker>
where W.Input == UIImage, W.Output == Bool { ... }

// After:
final class ImageProcessor<W: ImageWorker> { ... }
```

#### 8.3.4. Exercises

1. You have the following types:

// A protocol representing something that can play a file at a location.
protocol Playable {
var contents: URL { get }
func play()
}

// A Movie struct that inherits this protocol.
final class Movie: Playable {
let contents: URL

init(contents: URL) {
self.contents = contents
}

func play() { print("Playing video at \(contents)") }
}

copy

You introduce a new `Song` type, but instead of playing a file at a URL, it uses an `AudioFile` type. How would you deal with this? See if you can make the protocol reflect this change:

struct AudioFile {}

final class Song: Playable {
let contents: AudioFile
init(contents: AudioFile) {
self.contents = contents
}

func play() { print("Playing song") }
}

copy

1. Given this playlist that first could only play movies, how can you make sure it can play either movies or songs?

final class Playlist {

private var queue: [Movie] = []

func addToQueue(playable: Movie) {
queue.append(playable)
}

func start() {
queue.first?.play()
}
}

copy

### 8.4. Closing thoughts

Protocols with associated types and generics unlocks abstract code, but forces you to reason about types during compile time. Although it’s sometimes challenging to work with, getting your highly reusable abstract code to compile can be rewarding. You don’t always have to make things difficult, however. Sometimes a single generic or concrete code is enough to give you what you want. Now that you have seen how associated types work, you’re prepared to take them on when they return in upcoming chapters.

### Summary

- You can use protocols as generic constraints. But protocols can also be used as a type at runtime (dynamic dispatch) when you step away from generics.
- Using protocols as a generic constraint is usually the way to go, until you need dynamic dispatch.
- Associated types are generics that are tied to a protocol.
- Protocols with associated types allow a concrete type to define the associated type. Each concrete type can specialize an associated type to a different type.
- Protocols with `Self` requirements are a unique flavor of associated types referencing the current type.
- Protocols with associated types or `Self` requirements force you to reason about types at compile time.
- You can make a protocol inherit another protocol to further constrain its associated types.

### Answers

1. What is the difference between the statements?

- - The nongeneric function uses dynamic dispatch (runtime).
- - The generic function is resolved at compile time.

1. How would you decide to use a generic or nongeneric protocol in the struct? A recipe requires multiple different ingredients. By using a generic, you can use only one type of ingredient. Using eggs for everything can get boring, so, in this case, you should step away from generics.
1. How would you decide to use a generic or nongeneric protocol in the struct? The delegate is a single type; you can safely use a generic here. You get compile-time benefits, such as extra performance, and seeing at compile time which type you’ll use. The code could look like this:

protocol APIDelegate {
func load(completion:(Data) -> Void)
}

struct ApiLoadHandler: APIDelegate {
func load(completion: (Data) -> Void) {
print("I am loading")
}
}

class API<Delegate: APIDelegate> {
private let delegate: Delegate?

init(delegate: Delegate) {
self.delegate = delegate
}
}

let dataModel = API(delegate: ApiLoadHandler())

copy

1. Consider the subclassing hierarchy for a game, where you have enemies that can attack with a certain type of damage. Can you replace this subclassing hierarchy with a protocol-based solution?

protocol Enemy {
associatedtype DamageType
func attack() -> DamageType
}

struct Fire {}
class Imp: Enemy {
func attack() -> Fire {
return Fire()
}
}

struct BluntDamage {}
class Centaur: Enemy {
func attack() -> BluntDamage {
return BluntDamage()
}
}

copy

1. You introduce a new `Song` type, but instead of playing a file at a URL, it uses an `AudioFile` type. How would you deal with this? See if you can make the protocol reflect this. Answer: You introduce an associated type, such as `Media`. The `contents` property is now of type `Media`, which resolves to something different for each implementation:

protocol Playable {
associatedtype Media
var contents: Media { get }
func play()
}

final class Movie: Playable {
let contents: URL

init(contents: URL) {
self.contents = contents
}

func play() { print("Playing video at \(contents)") }
}

struct AudioFile {}
final class Song: Playable {
let contents: AudioFile

init(contents: AudioFile) {
self.contents = contents
}

func play() { print("Playing song") }
}

copy

1. Given the playlist that first could only play movies, how can you make sure it can play either movies or songs?

final class Playlist<P: Playable> {

private var queue: [P] = []

func addToQueue(playable: P) {
queue.append(playable)
}

func start() {
queue.first?.play()
}
}

copy

##### Note

You can’t mix movies and songs, but you can create a playlist for songs (or a playlist for movies).
