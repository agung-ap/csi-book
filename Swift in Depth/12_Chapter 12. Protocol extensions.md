# Chapter 12. Protocol extensions

### ***This chapter covers***

- Flexibly modeling data with protocols instead of subclasses
- Adding default behavior with protocol extensions
- Extending regular types with protocols
- Working with protocol inheritance and default implementations
- Applying protocol composition for highly flexible code
- Showing how Swift prioritizes method calls
- Extending types containing associated types
- Extending vital protocols, such as `Sequence` and `Collection`

Previous chapters have shown how to work with protocols, associated types, and generics. To improve your abstract protocol game, this chapter sheds some light on protocol extensions. To some, being able to extend a protocol is the most significant feature of Swift, as you’ll see later in this chapter.

Besides declaring a method signature, with protocols you can supply full implementations. Extending a protocol means that you can offer default implementations to a protocol so that types don’t have to implement certain methods. The benefits are profound. You can elegantly bypass rigid subclassing structures and end up with highly reusable, flexible code in your applications.

In its purest form, a protocol extension sounds simple. Offer a default implementation and be on your merry way. Moreover, protocol extensions can be easy to grasp if you stay at the surface. But as you progress through this chapter, you’ll discover many different use cases, pitfalls, best practices, and tricks related to correctly extending protocols.

You’ll see that it takes more than merely getting your code to compile. You also have the problem that code can be too decoupled, and understanding which methods you’re calling can be hard; even more so when you mix protocols with protocol inheritance while overriding methods. You’ll see how protocols are not always easy to comprehend. But when applied correctly, protocols enable you to create highly flexible code. At first, you’re going to see how protocols enable you to model your data *horizontally* instead of *vertically*, such as with subclassing. You’ll also take a look at how protocol extensions work and how you can override them.

Then you’ll model a mailing API in two ways and consider their trade-offs. First, you’ll use protocol inheritance to deliver a default implementation that is more specialized. Then, you’ll model the same API via a signature feature called *protocol composition*. You’ll see the benefits and downsides of both approaches side by side.

Then, it’s time for some theory for a better understanding of which methods are called when. You’ll look at overriding methods, inheriting from protocols, and the calling priorities of Swift. It’s a little theoretical if you’re into that.

As a next step, you’ll see how you can extend types in multiple directions. You’ll discover the trade-offs between extending a type to conform to a protocol, and to extend a protocol constrained to a type. It’s a subtle but important distinction.

Going further down the rabbit hole, you’ll see how to extend types with associated types. Then you’ll find out how to extend the `Collection` protocol and how Swift prioritizes methods that rely on a constrained associated type.

As the finishing touch, you get to go lower-level and see how Swift extends `Sequence`. You’ll apply this knowledge to create highly reusable extensions. You’re going to create a `take(while:)` method that is the opposite of `drop(while:)`. You’ll also create the `inspect` method, which helps you to debug iterators. A brief look at higher-order functions comes next, along with the esoteric `ContiguousArray` to write these lower-level extensions.

After you have finished this chapter, you may catch yourself writing more highly decoupled code, so let’s get started.

### 12.1. Class inheritance vs. Protocol inheritance

In the world of object-oriented programming, the typical way to achieve inheritance was via subclassing. Subclassing is a legit way to achieve polymorphism and offer sane defaults for subclasses. But as you’ve seen throughout this book, inheritance can be a rigid form of modeling data. As one alternative to class-based inheritance, Swift offers protocol-inheritance, branded as *protocol-oriented programming*, which wowed many developers watching Apple’s World Wide Developers Conference (WWDC) presentations. Via the power of protocol extensions, you can slap a method with a complete implementation on (existing) types without the need for subclassing hierarchies, while offering high reusability.

In this section, you’re going to see how modeling works horizontally rather than vertically when you make use of protocols.

#### 12.1.1. Modeling data horizontally instead of vertically

##### Join Me!

It’s more educational and fun if you can check out the code and follow along with the chapter. You can download the source code at [http://mng.bz/vOvJ](http://mng.bz/vOvJ).

You can think of subclassing as a vertical way to model data. You have a superclass, and you can subclass it and override methods and behavior to add new functionality, and then you can go even lower and subclass again. Imagine that you’re creating a `RequestBuilder`, which creates `URLRequest` types for a network call. A subclass could expand functionality by adding default headers, and another subclass can encrypt the data inside the request. Via subclassing, you end up with a type that can build encrypted network requests for you (see [figure 12.1](https://livebook.manning.com/book/swift-in-depth/chapter-12/ch12fig1)).

![Figure 12.1. Class-based inheritance](https://drek4537l1klr.cloudfront.net/veen/Figures/12fig01.jpg)

Protocols, on the other hand, can be imagined as a horizontal way of modeling data. You take a type and add extra functionality to it by making it adhere to protocols, like adding building blocks to your structure. Instead of creating a superclass, you create separate protocols with a default implementation for building requests and headers and for encryption (see [figure 12.2](https://livebook.manning.com/book/swift-in-depth/chapter-12/ch12fig2)).

![Figure 12.2. Implementing protocols](https://drek4537l1klr.cloudfront.net/veen/Figures/12fig02_alt.jpg)

The concept of decoupling functionality from a type gives you a ton of flexibility and code reuse. You are not constrained to a single superclass anymore. As long as a type conforms to a `RequestBuilder`, it gets its default functionality for free. Any type could be a `RequestBuilder`—an enum, a struct, a class, a subclass—it doesn’t matter.

#### 12.1.2. Creating a protocol extension

Creating a protocol extension is painless. Let’s continue with the `RequestBuilder` example. First, you define a protocol, and then you extend the protocol where you can add a default implementation for each type that conforms to this protocol.

##### Listing 12.1. A protocol extension

```
protocol RequestBuilder {
     var baseURL: URL { get }                               #1
     func makeRequest(path: String) -> URLRequest           #2
 }

extension RequestBuilder {                                  #3
     func makeRequest(path: String) -> URLRequest {         #4
         let url = baseURL.appendingPathComponent(path)     #5
         var request = URLRequest(url: url)
         request.httpShouldHandleCookies = false
         request.timeoutInterval = 30
         return request
    }
}
```

##### Note

A default implementation on a protocol is always added via an extension.

To get the implementation of `makeRequest` for free, you merely have to conform to the `RequestBuilder` protocol. You conform to `RequestBuilder` by making sure to store the `baseURL` property. For instance, imagine having an app for a startup that lists thrilling bike trips. The application needs to make requests to retrieve data. For that to happen, the `BikeRequestBuilder` type conforms to the `RequestBuilder` protocol, and you make sure to implement the `baseURL` property. As a result, it gets `makeRequest` for free.

##### Listing 12.2. Implementing a protocol with default implementation

```
struct BikeRequestBuilder: RequestBuilder {                               #1
     let baseURL: URL = URL(string: "https://www.biketriptracker.com")!   #1
 }

let bikeRequestBuilder = BikeRequestBuilder()
let request = bikeRequestBuilder.makeRequest(path: "/trips/all")          #2
print(request) // https://www.biketriptracker.com/trips/all               #3
```

#### 12.1.3. Multiple extensions

A type is free to conform to multiple protocols. Imagine having a `BikeAPI` that both builds requests and handles the response. It can conform to two protocols: `RequestBuilder` from before, and a new one, `ResponseHandler`, as in the following example. `BikeAPI` is now free to conform to both protocols and gain multiple methods for free.

##### Listing 12.3. `ResponseHandler`

```
enum ResponseError: Error {
    case invalidResponse
}
protocol ResponseHandler {                              #1
     func validate(response: URLResponse) throws
}

extension ResponseHandler {
    func validate(response: URLResponse) throws {
        guard let httpresponse = response as? HTTPURLResponse else {
            throw ResponseError.invalidResponse
        }
    }
}

class BikeAPI: RequestBuilder, ResponseHandler {        #2
     let baseURL: URL = URL(string: "https://www.biketriptracker.com")!
}
```

### 12.2. Protocol inheritance vs. Protocol composition

You’ve seen before how you can offer default implementations via a protocol extension. You can model data with extensions several other ways, namely via *protocol inheritance* and *protocol composition*.

You’re going to build a hypothetical framework that can send emails via SMTP. You’ll focus on the API and omit the implementation. You’ll start by taking the protocol inheritance approach, and then you’ll create a more flexible approach via the use of composing protocols. This way, you can see the process and trade-offs in both approaches.

#### 12.2.1. Builder a mailer

First, as shown in the following listing, you define an `Email` type, which uses a `MailAddress` struct to define its email properties. A `MailAddress` shows more intent than simply using a `String`. You also define the `Mailer` protocol with a default implementation via a protocol extension (implementation omitted).

##### Listing 12.4. The `Email` and `Mailer` types

```
struct MailAddress {                      #1
     let value: String
}
struct Email {                            #2
    let subject: String
    let body: String
    let to: [MailAddress]
    let from: MailAddress
}

protocol Mailer {
    send(email: Email) throws             #3
 }

extension Mailer {
    func send(email: Email) {             #4
        // Omitted: Connect to server
        // Omitted: Submit email
        print("Email is sent!")
    }
}
```

You’re off to a good start. Now, imagine that you want to add a default implementation for a `Mailer` that *also* validates the `Email` before sending. But not all mailers validate the email. Perhaps a mailer is based on UNIX sendmail or a different service that doesn’t validate an email per sé. Not all mailers validate, so you can’t assume that `Mailer` validates an email by default.

#### 12.2.2. Protocol inheritance

If you do want to offer a default implementation that allows for sending validated emails, you can take at least two approaches. You’ll start with a protocol inheritance approach and then switch to a composition approach to see both pros and cons.

With protocol inheritance, you can expand on a protocol to add extra requirements. You do this by making a subprotocol that inherits from a superprotocol, similar to how `Hashable` inherits from `Equatable`.

As a next step, you start by creating a `ValidatingMailer` that inherits from `Mailer`. `ValidatingMailer` overrides the `send(email:)` method by making it throwing. `Validating-Mailer` introduces a new method called `validate(email:)` (see [figure 12.3](https://livebook.manning.com/book/swift-in-depth/chapter-12/ch12fig3)).

![Figure 12.3. ValidatingMailer inheriting from Mailer](https://drek4537l1klr.cloudfront.net/veen/Figures/12fig04.jpg)

To make life easier for implementers of `ValidatingMailer`, you extend `ValidatingMailer` and offer a default `send(email:)` method, which uses the `validate(email:)` method before sending. Again, to focus on the API, implementations are omitted, as shown in this listing.

##### Listing 12.5. `ValidatingMailer`

```
protocol ValidatingMailer: Mailer {
    func validate(email: Email) throws
}

extension ValidatingMailer {
    func send(email: Email) throws {
        try validate(email: email)        #1
        // Connect to server
        // Submit email
        print("Email validated and sent.")
    }

    func validate(email: Email) throws {
        // Check email address, and whether subject is missing.
    }
}
```

Now, `SMTPClient` implements `ValidatingMailer` and automatically get’s a validated `send(email:)` method.

##### Listing 12.6. `SMTPClient`

```
struct SMTPClient: ValidatingMailer {
    // Implementation omitted.
}

let client = SMTPClient()
try? client.send(email: Email(subject: "Learn Swift",
                              body: "Lorem ipsum",
                              to: [MailAdress(value: "john@appleseed.com")],
                              from: MailAdress(value: "stranger@somewhere.com"))
```

A downside of protocol inheritance is that you don’t separate functionality and semantics. For instance, because of protocol inheritance, anything that validates emails automatically has to be a `Mailer`. You can loosen this restriction by applying protocol composition—let’s do that now.

#### 12.2.3. The composition approach

For the composition approach, you keep the `Mailer` protocol. But instead of a `Validating-Mailer` that inherits from `Mailer`, you offer a standalone `MailValidator` protocol that doesn’t inherit from anything. The `MailValidator` protocol also offers a default implementation via an extension, which you omit for brevity as shown here.

##### Listing 12.7. The `MailValidator` protocol

```
protocol MailValidator {
    func validate(email: Email) throws
}

extension MailValidator {
    func validate(email: Email) throws {
        // Omitted: Check email address, and whether subject is missing.
    }
}
```

Now you can compose. You make `SMTPClient` conform to both separate protocols. `Mailer` does not know about `MailValidator`, and vice versa (see [figure 12.4](https://livebook.manning.com/book/swift-in-depth/chapter-12/ch12fig4)).

![Figure 12.4. SMTPClient implementing Mailer and MailValidator](https://drek4537l1klr.cloudfront.net/veen/Figures/12fig05_alt.jpg)

With the two protocols in place, you can create an extension that only works on a protocol intersection. Extending on an intersection means that types adhering to both `Mailer` and `MailValidator` get a specific implementation or even bonus method implementations. Inside the intersection, `send(email:)` combines functionality from both `Mailer` and `MailValidator` (see [figure 12.5](https://livebook.manning.com/book/swift-in-depth/chapter-12/ch12fig5)).

![Figure 12.5. Intersecting extension](https://drek4537l1klr.cloudfront.net/veen/Figures/12fig06.jpg)

To create an extension with an intersection, you extend one protocol that conforms to the other via the `Self` keyword.

##### Listing 12.8. Intersecting `Mailer` and `MailValidator`

```
extension MailValidator where Self: Mailer {       #1
 
    func send(email: Email) throws {               #2
        try validate(email: email)
        // Connect to server
        // Submit email
        print("Email validated and sent.")
    }

}
```

##### Note

Whether you extend `MailValidator` or `Mailer` doesn’t matter—either direction is fine.

Another benefit of this approach is that you can come up with new methods such as `send(email:,` `at:)`, which allows for a mail to be validated and queued. You validate the email so that the queue has the confidence that the mail can be sent. You can define new methods on a protocol intersection.

##### Listing 12.9. Adding bonus methods

```
extension MailValidator where Self: Mailer {
    // ... snip

    func send(email: Email, at: Date) throws {       #1
         try validate(email: email)
        // Connect to server
        // Add email to delayed queue.
        print("Email validated and stored.")
    }
}
```

#### 12.2.4. Unlocking the powers of an intersection

Now, you’re going to make `SMTPClient` adhere to both the `Mailer` and `MailValidator` protocols, which unlocks the code inside the protocol intersection. In other words, `SMTPClient` gets the validating `send(email:)` and `send(email:,` `at:)` methods for free.

##### Listing 12.10. Implementing two protocols to get a free method

```
struct SMTPClient: Mailer, MailValidator {}                            #1
 
let client = SMTPClient()
let email = Email(subject: "Learn Swift",
      body: "Lorem ipsum",
      to: [MailAdress(value: "john@appleseed.com")],
      from: MailAdress(value: "stranger@somewhere.com"))

try? client.send(email: email) // Email validated and sent.            #2
try? client.send(email: email, at: Date(timeIntervalSinceNow: 3600)) 
 // Email validated and queued.                                     #3
```

Another way to see the benefits is via a generic function, as in [listing 12.11](https://livebook.manning.com/book/swift-in-depth/chapter-12/ch12list11). When you constrain to both protocols, the intersection implementation becomes available. Notice how you define the generic `T` and constrain it to both protocols. By doing so, the delayed `send(email:,` `at:)` method becomes available.

##### Listing 12.11. Generic with an intersection

```
func submitEmail<T>(sender: T, email: Email) where T: Mailer, T: MailValidator {
    try? sender.send(email: email, at: Date(timeIntervalSinceNow: 3600))
}
```

Taking a composition approach decouples your code significantly. In fact, it may even become *too* decoupled. Implementers may not know precisely which method implementation is used under the hood; they may also be unable to decipher when bonus methods are unlocked. Another downside is that a type such as `SMTPClient` has to implement multiple protocols. But the benefits are profound. When used carefully, you can have elegant, highly reusable, highly decoupled code by using compositions.

A second way to think of intersecting protocols is to offer free benefits, under the guise of “Because you conform to both A and B, you might as well offer C for free.”

With protocol inheritance, `SMTPClient` has to implement only a single protocol, and it’s more rigid. Knowing what an implementer gets is also a little more straightforward. When you’re working with protocols, trying to find the best abstraction can be a tough balancing act.

#### 12.2.5. Exercise

1. Create an extension that enables the `explode()` function, but only on types that conform to the `Mentos` and `Coke` protocols:

protocol Mentos {}
protocol Coke {}

func mix<T>(concoction: T) where T: Mentos, T: Coke {
//    concoction.explode() // make this work, but only if T conforms
to both protocols, not just one
}

copy

### 12.3. Overriding priorities

When implementing protocols, you need to follow a few rules. As a palate cleanser, you’ll move away from `Mailer` from the previous section and get a bit more conceptual.

#### 12.3.1. Overriding a default implementation

To see how protocol inheritance works, imagine having a protocol `Tree` with a method called `grow()`. This protocol offers a default implementation via a protocol extension. Meanwhile, an `Oak` struct implements `Tree` *and* also implements `grow()` (see [figure 12.6](https://livebook.manning.com/book/swift-in-depth/chapter-12/ch12fig6)).

![Figure 12.6. Overriding a protocol](data:image/svg+xml;utf8,%3Csvg%20xmlns=%22http://www.w3.org/2000/svg%22%20xmlns:xlink=%22http://www.w3.org/1999/xlink%22%20version=%221.1%22%20x=%220px%22%20y=%220px%22%20viewBox=%220%200%20473%20171%22%20xml:space=%22preserve%22%20height=%22171px%22%20width=%22473px%22%3E%20%3Crect%20width=%22473%22%20height=%22171%22%20style=%22fill:rgb(255,255,255);%22/%3E%3C/svg%3E)

Swift picks the most specific method it can find. If a type implements the same method as the one on a protocol extension, Swift ignores the protocol extension’s method. In other words, Swift calls the `grow()` on `Oak`, and *not* the one on `Tree`. This allows you to override methods that are defined on a protocol extension.

Keep in mind that a protocol extension can’t override methods from actual types, such as trying to give an existing type a new implementation via a protocol. Also, at the time of writing, no special syntax exists that lets you know if a type overrides a protocol method. When a type—such as a class, struct, or enum—implements a protocol and implements the same method as the protocol extension, seeing which method Swift is calling under the hood is opaque.

#### 12.3.2. Overriding with protocol inheritance

To make things a bit more challenging, you’ll introduce protocol inheritance. This time you’ll introduce another protocol called `Plant`. `Tree` inherits from `Plant`. `Oak` still implements `Tree`. `Plant` also offers a default implementation of `grow()`, which `Tree` overrides.

Swift again calls the most specialized implementation of `grow()` (see [figure 12.7](https://livebook.manning.com/book/swift-in-depth/chapter-12/ch12fig7)). Swift calls `grow()` on `Oak`, if available; otherwise, it calls `grow()` on `Tree`, if available. If all else fails, Swift calls `grow()` on `Plant`. If nothing offers a `grow()` implementation, the compiler throws an error.

![Figure 12.7. Overrides with protocol inheritance](data:image/svg+xml;utf8,%3Csvg%20xmlns=%22http://www.w3.org/2000/svg%22%20xmlns:xlink=%22http://www.w3.org/1999/xlink%22%20version=%221.1%22%20x=%220px%22%20y=%220px%22%20viewBox=%220%200%20590%20216%22%20xml:space=%22preserve%22%20height=%22216px%22%20width=%22590px%22%3E%20%3Crect%20width=%22590%22%20height=%22216%22%20style=%22fill:rgb(255,255,255);%22/%3E%3C/svg%3E)

You can see the overrides happening with a code example. In the next listing, you’re going to define a `growPlant` function; notice how it accepts a `Plant`, not a `Tree` or `Oak`. Swift picks the most specialized implementation either way.

##### Listing 12.12. Overrides in action

```
func growPlant<P: Plant>(_ plant: P) {             #1
     plant.grow()
}

protocol Plant {
    func grow()
}

extension Plant {                                  #2
     func grow() {
        print("Growing a plant")
    }
}
protocol Tree: Plant {}                            #3
 
extension Tree {
    func grow() {                                  #3
         print("Growing a tree")
    }
}

struct Oak: Tree {
    func grow() {                                  #4
         print("The mighty oak is growing")
    }
}

struct CherryTree: Tree {}                         #5
 
struct KiwiPlant: Plant {}                         #6
 
growPlant(Oak()) // The mighty oak is growing
growPlant(CherryTree()) // Growing a tree          #7
growPlant(KiwiPlant()) // Growing a plant
```

With protocol inheritance, an interesting detail is that you get overriding behavior, similar to classes and subclasses. With protocols this behavior is available to not only classes but also to structs and enums.

#### 12.3.3. Exercise

1. What is the output of the following code?

protocol Transaction {
var description: String { get }
}
extension Transaction {
var description: String { return "Transaction" }
}

protocol RefundableTransaction: Transaction {}

extension RefundableTransaction {
var description: String { return "RefundableTransaction" }
}

struct CreditcardTransaction: RefundableTransaction {}
func printDescription(transaction: Transaction) {
print(transaction.description)
}

printDescription(transaction: CreditcardTransaction())

copy

### 12.4. Extending in two directions

Generally speaking, the urge to subclass becomes less needed with these protocol extensions, with a few exceptions. Subclassing can be a fair approach from time to time, such as when bridging to Objective-C and subclassing `NSObject`, or dealing with specific frameworks like `UIKit`, which offer views and subviews amongst other things. Even though this book normally doesn’t venture into frameworks, let’s make a small exception for a real practical use case related to extensions, UI, and subclassing.

A typical use of protocols in combination with subclasses involves UIKit’s `UIViewController`, which represents a (piece of) screen that is rendered on an iPhone, iPad, or AppleTV. `UIViewController` is meant to be subclassed and makes for a good use case in this section.

#### 12.4.1. Opting in to extensions

Imagine that you have an `AnalyticsProtocol` protocol that helps track analytic events for user metrics. You could implement `AnalyticsProtocol` on `UIViewController`, which offers a default implementation. This adds the functionality of `Analytics-Protocol` to all `UIViewController` types and its subclasses.

But assuming that *all* viewcontrollers need to conform to this protocol is probably not safe. If you’re delivering a framework with this extension, a developer implementing this framework gets this extension automatically, whether they like it or not. Even worse, the extension from a framework could clash with an existing extension in an application if they share the same name!

One way to avoid these issues is to flip the extension. Flipping the extension means that instead of extending a `UIViewController` with a protocol, you can extend a protocol constrained to a `UIViewController`, as follows.

##### Listing 12.13. Flipping extension directions

```
protocol AnalyticsProtocol {
    func track(event: String, parameters: [String: Any])
}

// Not like this:
extension UIViewController: AnalyticsProtocol {
    func track(event: String, parameters: [String: Any]) { // ... snip }
}

// But as follows:
extension AnalyticsProtocol where Self: UIViewController {
    func track(event: String, parameters: [String: Any]) { // ... snip }
}
```

Now if a `UIViewController` explicitly adheres to this protocol, it opts in for the benefits of the protocol—for example, a `NewsViewController` can explicitly adhere to `AnalyticsProtocol` and reap its free methods. This way, you prevent *all* viewcontrollers from adhering to a protocol by default.

##### Listing 12.14. Opting in for benefits

```
extension NewsViewController: UIViewController, AnalyticsProtocol {
    // ... snip

    override func viewDidAppear(_ animated: Bool) {
      super.viewDidAppear(animated)
      track("News.appear", params: [:])
    }
}
```

This technique becomes even more critical when you’re offering a framework. Extensions are not namespaced, so be careful with adding public extensions inside a framework, because implementers may not want their classes to adhere to a protocol by default.

#### 12.4.2. Exercise

1. What is the difference between these two extensions?

extension UIViewController: MyProtocol {}

extension MyProtocol where Self: UIViewController {}

copy

### 12.5. Extending with associated types

Let’s see how Swift prioritizes method calls on protocols, especially protocols with associated types.

You start by looking at `Array`. It implements the `Collection` protocol, which has an associated type of `Element`, representing an element inside a collection. If you extend `Array` with a special function—such as `unique()`, which removes all duplicates—you can do so by referring to `Element` as its inner value.

##### Listing 12.15. Applying `unique ()` to `Array`

```
[3, 2, 1, 1, 2, 3].unique() // [3, 2, 1]
```

Let’s extend `Array`. To be able to check each element for equality, you need to make sure that an `Element` is `Equatable`, which you can express via a constraint. Constraining `Element` to `Equatable` means that `unique()` is only available on arrays with `Equatable` elements.

##### Listing 12.16. Extending `Array`

```
extension Array where Element: Equatable {         #1
     func unique() -> [Element] {                  #2
        var uniqueValues = [Element]()
        for element in self {
            if !uniqueValues.contains(element) {   #3
                 uniqueValues.append(element)
            }
        }
        return uniqueValues
    }
}
```

Extending `Array` is a good start. But it probably makes more sense to give this extension to many types of collections, not only `Array` but perhaps also the values of a dictionary or even strings. You can go a bit lower-level and decide to extend the `Collection` protocol instead, as shown here, so that multiple types can benefit from this method. Shortly after, you’ll discover a shortcoming of this approach.

##### Listing 12.17. Extending `Collection` protocol

```
// This time we're extending Collection instead of Array
extension Collection where Element: Equatable {
    func unique() -> [Element] {
        var uniqueValues = [Element]()
        for element in self {
            if !uniqueValues.contains(element) {
                uniqueValues.append(element)
            }
        }
        return uniqueValues
    }
}
```

Now, every type adhering to the `Collection` protocol inherits the `unique()` method. Let’s try it out.

##### Listing 12.18. Testing out the `unique()` method

```
// Array still has unique()
[3, 2, 1, 1, 2, 3].unique() // [3, 2, 1]

// Strings can be unique() now, too
"aaaaaaabcdef".unique() // ["a", "b", "c", "d", "e", "f"]

// Or a Dictionary's values
let uniqueValues = [1: "Waffle",
 2: "Banana",
 3: "Pancake",
 4: "Pancake",
 5: "Pancake"
].values.unique()

print(uniqueValues) // ["Banana", "Pancake", "Waffle"]
```

Extending `Collection` instead of `Array` benefits more than one type, which is the benefit of extending a protocol versus a concrete type.

#### 12.5.1. A specialized extension

One thing remains. The `unique()` method is not very performant. For every value inside the collection, you need to check if this value already exists in a new unique array, which means that for each element, you need to loop through (possibly) the whole `uniqueValues` array. You would have more control if `Element` were `Hashable` instead. Then you could check for uniqueness via a hash value via a `Set`, which is much faster than an array lookup because a `Set` doesn’t keep its elements in a specific order.

To support lookups via a `Set`, you create another `unique()` extension on `Collection` where its elements are `Hashable`. `Hashable` is a subprotocol of `Equatable`, which means that Swift picks an extension with `Hashable` over an extension with `Equatable`, if possible (see [figure 12.8](https://livebook.manning.com/book/swift-in-depth/chapter-12/ch12fig8)). For instance, if an array has `Hashable` types inside it, Swift uses the fast `unique()` method; but if elements are `Equatable` instead, Swift uses the slower version.

![Figure 12.8. Specializing an associated type](data:image/svg+xml;utf8,%3Csvg%20xmlns=%22http://www.w3.org/2000/svg%22%20xmlns:xlink=%22http://www.w3.org/1999/xlink%22%20version=%221.1%22%20x=%220px%22%20y=%220px%22%20viewBox=%220%200%20497%20202%22%20xml:space=%22preserve%22%20height=%22202px%22%20width=%22497px%22%3E%20%3Crect%20width=%22497%22%20height=%22202%22%20style=%22fill:rgb(255,255,255);%22/%3E%3C/svg%3E)

In your second extension—also called `unique()`—you can put each element in a `Set` for a speed improvement.

##### Listing 12.19. Extending `Collection` with a `Hashable` constraint on `Element`

```
// This extension is an addition, it is NOT replacing the other extension.
extension Collection where Element: Hashable {                             #1
     func unique() -> [Element] {
        var set = Set<Element>()                                           #2
        var uniqueValues = [Element]()
        for element in self {
            if !set.contains(element) {                                    #3
                uniqueValues.append(element)
                set.insert(element)
            }
        }
        return uniqueValues
    }
}
```

Now you have two extensions on `Collection`. One constrains `Element` to `Equatable`, and another constrains `Element` to `Hashable`. Swift picks the most specialized one.

#### 12.5.2. A wart in the extension

Picking an abstraction can be tricky from time to time. In fact, there’s a wart in this API. At the moment, `Set` by its nature is unique already, and yet it gains the `unique` method because `Set` conforms to `Collection`. You can put a bandage on this wart and on `Set` override the method for a quick conversion to `Array`.

##### Listing 12.20. `unique` on `Set`

```
extension Set {
    func unique() -> [Element] {
        return Array(self)
    }
}
```

The `unique` method on `Set` does not add real value, but at least you have a quick way to convert a `Set` to `Array` now. The point is, finding the balance between extending the lowest common denominator without weakening the API of concrete types is a bit of an art.

Warts aside, what’s interesting is that Swift again picks the most concrete implementation. Swift picks `Equatable` as the lowest denominator, `Hashable` if elements are `Hashable`, and with `Set`, Swift uses use its concrete implementation, ignoring any same-name method extensions on `Collection`.

### 12.6. Extending with concrete constraints

You can also constrain associated types to a concrete type instead of constraining to a protocol. As an example, let’s say you have an `Article` struct with a `viewCount` property, which tracks the number of times that people viewed an `Article`.

##### Listing 12.21. An `Article` struct

```
struct Article: Hashable {
    let viewCount: Int
}
```

You can extend `Collection` to get the total number of view counts inside a collection. But this time you constrain an `Element` to `Article`, as shown in the following. Since you’re constraining to a concrete type, you can use the `==` operator.

##### Listing 12.22. Extending `Collection`

```
// Not like this
extension Collection where Element: Article { ... }

// But like this
extension Collection where Element == Article {
    var totalViewCount: Int {
        var count = 0
        for article in self {
            count += article.viewCount
        }
        return count
    }
}
```

With this constraint in place, you can get the total view count whenever you have a collection with articles in it, whether that’s an `Array`, a `Set`, or something else altogether.

##### Listing 12.23. Extension in action

```
let articleOne = Article(viewCount: 30)
let articleTwo = Article(viewCount: 200)

// Getting the total count on an Array.
let articlesArray = [articleOne, articleTwo]
articlesArray.totalViewCount // 230

// Getting the total count on a Set.
let articlesSet: Set<Article> = [articleOne, articleTwo]
articlesSet.totalViewCount // 230
```

Whenever you make an extension, deciding how low-level you need to go can be tricky. A concrete extension on `Array` is enough for 80% of the cases, in which case you don’t need to go to `Collection`. If you notice that you need the same implementation on other types, you may want to strap in and go lower-level where you’ll extend `Collection`. In doing so, you’ll be working with more abstract types. If you need to go even lower-level, you can end up at `Sequence`, so that you can offer extensions to even more types. To see how you can go super low-level, let’s try to extend `Sequence` to offer useful extensions for many types.

### 12.7. Extending Sequence

A very interesting protocol to extend is `Sequence`. By extending `Sequence` you can power up many types at once, such as `Set`, `Array`, `Dictionary`, your collections—you name it.

When you’re comfortable with `Sequence`, it lowers the barrier for creating your extensions for methods you’d like to see. You can wait for Swift updates, but if you’re a little impatient or have special requirements, you can create your own. Extending `Sequence` as opposed to a concrete type—such as `Array`—means that you can power up many types at once.

Swift loves borrowing concepts from the Rust programming language; the two languages are quite similar in many respects. How about you shamelessly do the same and add some useful methods to the `Sequence` vocabulary? Extending `Sequence` won’t merely be a programming exercise, because these methods are helpful utilities you can use in your projects.

#### 12.7.1. Looking under the hood of filter

Before extending `Sequence`, let’s take a closer look at a few interesting things regarding how Swift does it. First, `filter` accepts a function. This function is the closure you pass to `filter`.

##### Listing 12.24. A small `filter` method

```
let moreThanOne = [1,2,3].filter { (int: Int) in
  int > 1
}
print(moreThanOne) // [2, 3]
```

Looking at the signature of `filter`, you can see that it accepts a function, which makes `filter` a higher-order function. A higher-order function is a ten-dollar concept for a one-dollar name, indicating that a function can accept or return another function. This function is the closure you pass to `filter`.

Also note that `filter` has the `rethrows` keyword as showing in [listing 12.25](https://livebook.manning.com/book/swift-in-depth/chapter-12/ch12list25). If a function or method `rethrows`, any errors thrown from a closure are propagated back to the caller. Having a method with `rethrows` is similar to regular error propagation, except `rethrows` is reserved for higher-order functions, such as `filter`. The benefit of this is that `filter` accepts both nonthrowing and throwing functions; it’s the caller that has to handle any errors.

##### Listing 12.25. Looking at `filter`'s signature

```
public func filter(
    _ isIncluded: (Element) throws -> Bool    #1
   ) rethrows -> [Element] {                  #2
     // ... snip
}
```

Now, let’s look at the body. You can see that `filter` creates a `results` array, which is of the obscure type called `ContiguousArray`—more on that in a minute—and iterates through each element via the low-level, no-overhead `makeIterator` method. For each element, `filter` calls the `isIncluded` method, which is the closure you pass to `filter`. If `isIncluded`—also known as the *passed closure*—returns `true`, then `filter` appends the element to the `results` array.

Finally, `filter` converts the `ContiguousArray` back to a regular `Array`.

##### Listing 12.26. Looking at `filter`

```
public func filter(
    _ isIncluded: (Element) throws -> Bool       #1
   ) rethrows -> [Element] {
    var result = ContiguousArray<Element>()      #2
 
    var iterator = self.makeIterator()           #3
 
    while let element = iterator.next() {        #3
       if try isIncluded(element) {              #4
         result.append(element)                  #5
       }
    }

    return Array(result)                         #6
 }
```

##### Note

In the Swift source, the `filter` method forwards the call to another `_filter` method which does the work. For example purposes, we kept referring to the method as `filter`.

##### CONTIGUOUSARRAY

Seeing `ContiguousArray` there instead of `Array` may feel out of place. The `filter` method uses `ContiguousArray` for extra performance, which makes sense for such a low-level, highly reused method.

`ContiguousArray` can potentially deliver performance benefits when containing classes or an Objective-C protocol; otherwise, the performance is the same as a regular `Array`. But `ContiguousArray` does not bridge to Objective-C.

When `filter` did its work, it returns a regular `Array`. Regular arrays can bridge to `NSArray` if needed for Objective-C, whereas `ContiguousArray` cannot. So using `Contiguous-Array` can help squeeze out the last drops of performance, which matters on low-level methods such as `filter`.

Now that you’ve seen how to create an extension on `Sequence`, let’s make a custom extension.

#### 12.7.2. Creating the Inspect method

A useful method you may want to add to your library is `inspect`. It is *very* similar to `forEach`, with one difference: it returns the sequence. The `inspect` method is especially useful for debugging a pipeline where you chain operations.

You can squeeze `inspect` in the middle of a chained pipeline operation, do something with the values, such as logging them, and continue with the pipeline as if nothing happened, whereas `forEach` would end the iteration, as shown here.

##### Listing 12.27. The `inspect` method in action

```
["C", "B", "A", "D"]
    .sorted()
    .inspect { (string) in
        print("Inspecting: \(string)")
    }.filter { (string) -> Bool in
        string < "C"
    }.forEach {
        print("Result: \($0)")
}

// Output:
// Inspecting: A
// Inspecting: B
// Inspecting: C
// Inspecting: D
// Result: A
// Result: B
```

To add `inspect` to your codebase, you can take the following code. Notice how you don’t have to use `makeIterator` if you don’t want to.

##### Listing 12.28. Extending `Sequence` with `inspect`

```
extension Sequence {
    public func inspect(
        _ body: (Element) throws -> Void   #1
         ) rethrows  -> Self {
        for element in self {
            try body(element)              #2
        }
        return self                        #3
     }
}
```

Extending `Sequence` means that you go quite low-level. Not only does `Array` gain extra methods, but so does `Set`, `Range`, `zip`, `String`, and others. You’re only scratching the surface. Apple uses many optimization tricks and particular sequences for further optimizations. The approach in this section should cover many cases, however.

Extending `Sequence` with methods you feel are missing is a good and useful exercise. What other extensions can you create?

#### 12.7.3. Exercise

1. Up for a challenge? Create a “scan” extension on `Sequence`. The `scan` method is like `reduce`, but besides returning the end value it also returns intermediary results, all as one array, which is very useful for debugging a reduce method! Be sure to use `makeIterator` and `ContiguousArray` for extra speed:

let results = (0..<5).scan(initialResult: "") { (result: String, int:
Int) -> String in
return "\(result)\(int)"
}
print(results) // ["0", "01", "012", "0123", "01234"]

let lowercased = ["S", "W", "I", "F", "T"].scan(initialResult: "") {
(result: String, string: String) -> String in
return "\(result)\(string.lowercased())"
}

print(lowercased) // ["s", "sw", "swi", "swif", "swift"]

copy

### 12.8. Closing thoughts

The lure of using extensions and protocols is strong. Keep in mind that sometimes a concrete type is the right way to go before diving into clever abstractions. Extending protocols is one of the most powerful—if not *the* most powerful—feature of Swift. It allows you to write highly decoupled, highly reusable code. Finding a suitable abstraction to solve a problem is a tough balancing act. Now that you’ve read this chapter, I hope that you know to extend horizontally and vertically in clever ways that will help you deliver concise and clean code.

### Summary

- Protocols can deliver a default implementation via protocol extensions.
- With extensions, you can think of modeling data horizontally, whereas with subclassing, you’re modeling data in a more rigid vertical way.
- You can override a default implementation by delivering an implementation on a concrete type.
- Protocol extensions cannot override a concrete type.
- Via protocol inheritance, you can override a protocol’s default implementation.
- Swift always picks the most concrete implementation.
- You can create a protocol extension that only unlocks when a type implements two protocols, called a protocol intersection.
- A protocol intersection is more flexible than protocol inheritance, but it’s also more abstract to understand.
- When mixing subclasses with protocol extensions, extending a protocol and constraining it to a class is a good heuristic (as opposed to extending a class to adhere to a protocol). This way, an implementer can pick and choose a protocol implementation.
- For associated types, such as `Element` on the `Collection` protocol, Swift picks the most specialized abstraction, such as `Hashable` over `Equatable` elements.
- Extending a low-level protocol—such as `Sequence`—means you offer new methods to many types at once.
- Swift uses a special `ContiguousArray` when extending `Sequence` for extra performance.

### Answers

1. Create an extension that enables the `explode()` function, but only on types that conform to `Mentos` and `Coke` protocols:

extension Mentos where Self: Coke {
func explode() {
print("BOOM!")
}
}

copy

1. What is the output of the following code?

"RefundableTransaction"

copy

1. What is the difference between these two extensions?

extension UIViewController: MyProtocol {}

extension MyProtocol where Self: UIViewController {}

copy

The first line makes all viewcontrollers and their subclasses conform to `My-Protocol`. The second line makes a viewcontroller only adhere to a protocol on an as-needed basis.
1. Create a “scan” extension on `Sequence`. Be sure to use `makeIterator` and `Contiguous-Array` for extra speed:

extension Sequence {
func scan<Result>(
initialResult: Result,
_ nextPartialResult: (Result, Element) throws -> Result
) rethrows -> [Result] {
var iterator = makeIterator()

var results = ContiguousArray<Result>()
var accumulated: Result = initialResult
while let element = iterator.next() {
accumulated = try nextPartialResult(accumulated, element)
results.append(accumulated)
}

return Array(results)
}
}

copy
