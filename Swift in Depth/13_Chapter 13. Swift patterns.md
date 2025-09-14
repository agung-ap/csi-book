# Chapter 13. Swift patterns

### ***This chapter covers***

- Mocking types with protocols and associated types
- Understanding conditional conformance and its benefits
- Applying conditional conformance with custom protocols and types
- Discovering shortcomings that come with protocols
- Understanding type erasure
- Using alternatives to protocols

In this chapter, you’re going to see some useful patterns that you can apply in your Swift programming. I made sure that these patterns were more Swift-focused, as opposed to a more-traditional OOP focus. We’re focusing on Swift patterns, so protocols and generics take center stage.

First, you’re going to mock existing types with protocols. You’ll see how to replace a networking API with a fake offline one, and also replace this networking API with one that’s focused on testing. I throw in a little trick related to associated types that will help you mock types, including ones from other frameworks.

Conditional conformance is a powerful feature that allows you to extend types with a protocol, but only under certain conditions. You’ll see how to extend existing types with conditional conformance, even if these types have associated types. Then, you’ll go a bit further and create a generic type, which you’ll power up as well by using conditional conformance.

Then the chapter takes a look at the shortcomings that come with protocols with associated types and `Self` requirements, which you can unofficially consider compile-time protocols. You’ll see how to best deal with these shortcomings. You’ll first consider an approach involving enums, and then a more complex, but also more flexible, approach involving *type erasure*.

As an alternative to protocols, you’ll see how to create a generic struct that can replace a protocol with associated types. This type will be highly flexible and an excellent tool to have.

This chapter aims to give you new approaches to existing problems and to help you understand protocols and generics on a deeper level. Let’s get started by seeing how to mock types, which is a technique you can apply across numerous projects.

### 13.1. Dependency injection

In [chapter 8](https://livebook.manning.com/book/swift-in-depth/chapter-8/ch08), you saw how protocols are used as an interface or type, where you could pass different types to a method, as long as these types adhere to the same protocol.

You can take this mechanic a bit further and perform *inversion of control*, or *dependency injection*, which are fancy words to say that you pass an implementation to a type. Think of supplying an engine to a motorcycle.

The goal of this exercise is to end up with an interchangeable implementation where you can switch between three network layers: a real network layer, an offline network layer, and a testing layer.

The real network layer is for when you ship an application for production. The fake network layer loads prepared files, which is useful for working with fixed responses where you control all the data, such as when the backend server is not finished yet, or when you need to demo your application without a network connection. The testing layer makes writing unit tests easier.

##### Join Me!

It’s more educational and fun if you can check out the code and follow along with the chapter. You can download the source code at [http://mng.bz/4vPa](http://mng.bz/4vPa).

#### 13.1.1. Swapping an implementation

You’re going to create a class called `WeatherAPI` that retrieves the latest weather status. To create network calls, `WeatherAPI` would use a `URLSession` from the Foundation framework. But you’re going to do it differently. `WeatherAPI` accepts a type conforming to a `Session` protocol, because a protocol allows you to pass a custom implementation. This way, `WeatherAPI` calls network methods on the protocol without knowing about which concrete implementation it received. You’re mocking `URLSession` as a challenge because if you know how to mock a type you don’t own, it will be even easier for types that you *do* own.

First, let’s define a protocol called `Session` representing `URLSession` but also other sessions, such as an offline session. This way you’re able to run an app in demo mode without a network connection, but also a testing session that enables you to verify that your API calls the methods when expected (see [figure 13.1](https://livebook.manning.com/book/swift-in-depth/chapter-13/ch13fig1)).

![Figure 13.1. Mocking](https://drek4537l1klr.cloudfront.net/veen/Figures/13fig01_alt.jpg)

`WeatherAPI` calls methods on `Session`. Let’s mirror a common method on `URL-Session`: creating a `dataTask` that can be run to fetch data.

In the `dataTask` method of `URLSession`, you would normally receive a `URL-Session-DataTask` type. But you’ll apply a little trick.

Instead of returning `URLSessionDataTask` or another protocol, you return an associated type. The reason is that an associated type resolves to a concrete type at compile time. It can represent a `URLSessionDataTask`, but also other types that each implementer can choose to return. Let’s call this associated type `Task`.

##### Listing 13.1. A `Session` protocol

```
protocol Session {
    associatedtype Task                                                 #1
 
    func dataTask(with url: URL, completionHandler: @escaping (Data?,
 URLResponse?, Error?) -> Void) -> Task                               #2
 }
```

Because `Session` mirrors `URLSession`, you merely have to conform `URLSession` to `Session` without writing any implementation code. Let’s extend `URLSession` now and make it conform to `Session`.

##### Listing 13.2. Conforming `URLSession` to `Session`

```
extension URLSession: Session {}
```

#### 13.1.2. Passing a custom Session

Now you can create the `WeatherAPI` class and define a generic called `Session` to allow for a swappable implementation. You’re almost there, but you can’t call `resume` yet on `Session.Task`.

##### Listing 13.3. The `WeatherAPI` class

```
final class WeatherAPI<S: Session> {                                        #1
     let session: S                                                         #2
 
     init(session: S) {                                                     #3
         self.session = session
     }

     func run() {
        guard let url = URL(string: "https://www.someweatherstartup.com")
 else {
            fatalError("Could not create url")
        }
        let task = session.dataTask(with: url) { (data, response, error) in #4
             // Work with retrieved data.
        }

        task.resume() // Doesn't work, task is of type S.Task               #5
     }

}

let weatherAPI = WeatherAPI(session: URLSession.shared)                     #6
weatherAPI.run()
```

You try to run a `task`, but you can’t. The associated type `Task` that `data-Task(with: completionHandler:)` returns is of type `Session.Task`, which doesn’t have any methods. Let’s fix that now.

#### 13.1.3. Constraining an associated type

`URLSessionDataTask` has a `resume()` method, but `Session.Task` does not. To fix this, you introduce a new protocol called `DataTask`, which contains the `resume()` method. Then you constrain `Session.Task` to `DataTask`.

To finalize the implementation, you’ll make `URLSessionDataTask` conform to the `DataTask` protocol as well (see [figure 13.2](https://livebook.manning.com/book/swift-in-depth/chapter-13/ch13fig2)).

![Figure 13.2. Mirroring URLSession](https://drek4537l1klr.cloudfront.net/veen/Figures/13fig02_alt.jpg)

In code, let’s create the `DataTask` protocol and constrain `Session.Task` to it.

##### Listing 13.4. Creating a `DataTask` protocol

```
protocol DataTask {                          #1
     func resume()                           #2
 }

protocol Session {
    associatedtype Task: DataTask            #3
 
    func dataTask(with url: URL, completionHandler: @escaping (Data?,
 URLResponse?, Error?) -> Void) -> Task
}
```

To complete your adjustment, you make `URLSessionDataTask` conform to your `DataTask` protocol so that everything compiles again.

##### Listing 13.5. Implementing `DataTask`

```
extension URLSessionDataTask: DataTask {}       #1
```

All is well again. Now, `URLSession` returns a type conforming to `DataTask`. At this stage, all the code compiles. You can call your API with a real `URLSession` to perform a request.

#### 13.1.4. Swapping an implementation

You can pass `URLSession` to your `WeatherAPI`, but the real power lies in the capability to swap out an implementation. Here’s a fake `URLSession` that you’ll name `Offline-URLSession`, which loads local files instead of making a real network connection. This way, you’re not dependent on a backend to play around with the `WeatherAPI` class. Every time that the `dataTask(with` `url:)` method is called, the `OfflineURL-Session` creates an `OfflineTask` that loads the local file, as shown in the following listing.

##### Listing 13.6. An offline task

```
final class OfflineURLSession: Session {                                 #1
 
    var tasks = [URL: OfflineTask]()                                     #2
 
    func dataTask(with url: URL, completionHandler: @escaping (Data?,
 URLResponse?, Error?) -> Void) -> OfflineTask {
        let task = OfflineTask(completionHandler: completionHandler)     #3
        tasks[url] = task
        return task
    }
}

enum ApiError: Error {                                                   #4
     case couldNotLoadData
}

struct OfflineTask: DataTask {

    typealias Completion = (Data?, URLResponse?, Error?) -> Void         #5
    let completionHandler: Completion

    init(completionHandler: @escaping Completion) {                      #6
         self.completionHandler = completionHandler
    }

    func resume() {                                                      #7
         let url = URL(fileURLWithPath: "prepared_response.json")        #7
         let data = try! Data(contentsOf: url)                           #7
         completionHandler(data, nil, nil)                               #7
    }
}
```

##### Note

A more mature implementation would also deallocate tasks and allow for more configuration of loading files.

Now that you have multiple implementations adhering to `Session`, you can start swapping them without having to touch the rest of your code. You can choose to create a production `WeatherAPI` or an offline `WeatherAPI`.

##### Listing 13.7. Swapping out implementations

```
let productionAPI = WeatherAPI(session: URLSession.shared)
let offlineApi = Weath+rAPI(session: OfflineURLSession())
```

With protocols you can swap out an implementation, such as feeding different sessions to `WeatherAPI`. If you use an associated type, you can make it represent another type inside the protocol, which can make it easier to mimic a concrete type. You don’t always have to use associated types, but it helps when you can’t instantiate certain types, such as when you want to mock code from third-party frameworks.

That’s all it took. Now `WeatherAPI` works with a production layer or a fake offline layer, which gives you much flexibility. With this setup, testing can be made easy as well. Let’s move on to creating the testing layer so that you can properly test `WeatherAPI`.

#### 13.1.5. Unit testing and Mocking with associated types

With a swappable implementation in place, you can pass an implementation that helps you with testing. You can create a particular type conforming to `Session`, loaded up with testing expectations. As an example, you can create a `MockSession` and `MockTask` that see if specific URLs are called.

##### Listing 13.8. Creating a `MockTask` and `MockSession`

```
class MockSession: Session {                                               #1
 
    let expectedURLs: [URL]
    let expectation: XCTestExpectation

    init(expectation: XCTestExpectation, expectedURLs: [URL]) {
        self.expectation = expectation
        self.expectedURLs = expectedURLs
    }

    func dataTask(with url: URL, completionHandler: @escaping (Data?,
 URLResponse?, Error?) -> Void) -> MockTask {
        return MockTask(expectedURLs: expectedURLs, url: url, expectation:
 expectation)                                                            #2
     }
}

struct MockTask: DataTask {
    let expectedURLs: [URL]
    let url: URL
    let expectation: XCTestExpectation                                     #3
 
    func resume() {
        guard expectedURLs.contains(url) else {
            return
        }

        self.expectation.fulfill()
    }
}
```

Now, if you want to test your API, you can test that the expected URLs are called.

##### Listing 13.9. Testing the API

```
class APITestCase: XCTestCase {

    var api: API<MockSession>!                                             #1
 
    func testAPI() {
        let expectation = XCTestExpectation(description: "Expected 
 someweatherstartup.com")                                                #2
        let session = MockSession(expectation: expectation, expectedURLs: 
 [URL(string: "www.someweatherstartup.com")!])                           #3
        api = API(session: session)
        api.run()                                                          #4
        wait(for: [expectation], timeout: 1)                               #5
    }
}

let testcase = APITestCase()
testcase.testAPI()
```

#### 13.1.6. Using the Result type

Because you’re using a protocol, you can offer a default implementation to all sessions via the use of a protocol extension. You may have noticed how you used `Session`’s regular way of handling errors. But you have the powerful `Result` type available to you from the Swift Package Manager, as covered in [chapter 11](https://livebook.manning.com/book/swift-in-depth/chapter-11/ch11). You can extend `Session` and offer a variant that uses `Result` instead, as shown in the following listing. This way, all types adhering to `Session` will be able to return a `Result`.

##### Listing 13.10. Extending `Session` with a `Result` type

```
protocol Session {
    associatedtype Task: DataTask

    func dataTask(with url: URL, completionHandler: @escaping (Data?, 
 URLResponse?, Error?) -> Void) -> Task
    func dataTask(with url: URL, completionHandler: @escaping (Result<Data,
 AnyError>) -> Void) -> Task                                             #1
 }

extension Session {
    func dataTask(with url: URL, completionHandler: @escaping (Result<Data,
 Error>) -> Void) -> Task {                                              #2
         return dataTask(with: url, completionHandler: { (data, response, 
           error) in                                                       #3
             if let error = error {
                completionHandler(Result.failure(error))
            } else if let data = data {
                completionHandler(Result.success(data))
            } else {
                fatalError()
            }
        })
    }
}
```

Now, implementers of `Session`, including Apple’s `URLSession`, can return a `Result` type.

##### Listing 13.11. Multiple sessions retrieving a `Result`

```
URLSession.shared.dataTask(with: url) { (result: Result<Data, AnyError>) in
    // ...
}

OfflineURLSession().dataTask(with: url) { (result: Result<Data, AnyError>) in
    // ...
}
```

With the power of protocols, you have the ability to swap between multiple implementations between production, debugging, and testing use. With the help of extensions, you can use `Result` as well.

#### 13.1.7. Exercise

1. Given these types, see if you can make `WaffleHouse` testable to verify that a `Waffle` has been served:

struct Waffle {}

class Chef {
func serve() -> Waffle {
return Waffle()
}
}

struct WaffleHouse {

let chef = Chef()

func serve() -> Waffle {
return chef.serve()
}

}

let waffleHouse = WaffleHouse()
let waffle = waffleHouse.serve()

copy

### 13.2. Conditional conformance

Conditional conformance is a compelling feature introduced in Swift 4.1. With conditional conformance, you can make a type adhere to a protocol but only under certain conditions. [Chapter 7](https://livebook.manning.com/book/swift-in-depth/chapter-7/ch07) covered conditional conformance briefly, but let’s take this opportunity to become more comfortable with it and see more-advanced use cases. After this section, you’ll know precisely when and how to apply conditional conformance—let’s get to it!

#### 13.2.1. Free functionality

The easiest way to see conditional conformance in action is to create a struct, implement `Equatable` or `Hashable`, and without implementing any of the protocol’s method, you get equatability or hashability for free.

The following is a `Movie` struct. Notice how you can already compare movies by merely making `Movie` adhere to the `Equatable` protocol, without implementing the required `==` function; this is the same technique you applied to `Pair` in [chapter 7](https://livebook.manning.com/book/swift-in-depth/chapter-7/ch07).

##### Listing 13.12. Auto `Equatable`

```
struct Movie: Equatable {
    let title: String
    let rating: Float
}

let movie = Movie(title: "The princess bride", rating: 9.7)

movie == movie // true. You can already compare without implementing Equatable
```

##### Manually Overriding

You can still implement the `==` function from `Equatable` if you want to supply your own logic.

Automatically having an `Equatable` type is possible because all the properties are `Equatable`. Swift synthesizes this for free on some protocols, such as `Equatable` and `Hashable`, but not every protocol. For instance, you don’t get `Comparable` for free, or the ones that you introduce yourself.

##### Warning

Unfortunately, Swift doesn’t synthesize methods on classes.

#### 13.2.2. Conditional conformance on associated types

Another approachable way to see conditional conformance in action is by looking at `Array` and its `Element` type, representing an element inside the array. `Element` is an associated type from `Sequence`, which `Array` uses, as covered in [chapter 9](https://livebook.manning.com/book/swift-in-depth/chapter-9/ch09).

Imagine that you have a `Track` protocol, representing a track used in audio software, such as a wave sample or a distortion effect. You can have an `AudioTrack` implement this protocol; it could play audio files at a specific URL.

##### Listing 13.13. The `Track` protocol

```
protocol Track {
    func play()
}

struct AudioTrack: Track {
    let file: URL
    func play() {
        print("playing audio at \(file)")
    }
}
```

If you have an array of tracks and want to play these tracks at the same time for a musical composition, you could naively extend `Array` only where `Element` conforms to `Track`, and then introduce a `play()` method here. This way, you can trigger `play()` for all `Track` elements inside an array. This approach has a shortcoming, however, which you’ll solve in a bit.

##### Listing 13.14. Extending `Array` (with a shortcoming)

```
extension Array where Element: Track {
    func play() {
        for element in self {
            element.play()
        }
    }
}

let tracks = [
    AudioTrack(file: URL(fileURLWithPath: "1.mp3")),
    AudioTrack(file: URL(fileURLWithPath: "2.mp3"))
]
tracks.play() // You use the play() method
```

But this approach has a shortcoming. `Array` itself does not conform to `Track`; it merely implements a method with the same name as the one inside `Track`, namely the `play()` method.

Because `Array` doesn’t conform to `Track`, you can’t call `play()` anymore on a nested array. Alternatively, if you have a function accepting a `Track`, you also can’t pass an `Array` with `Track` types.

##### Listing 13.15. Can’t use `Array` as a `Track` type

```
let tracks = [
    AudioTrack(file: URL(fileURLWithPath: "1.mp3")),
    AudioTrack(file: URL(fileURLWithPath: "2.mp3"))
]

// If an Array is nested, you can't call play() any more.
[tracks, tracks].play() // error: type of expression is ambiguous without 
     more context

// Or you can't pass an array if anything expects the Track protocol.
func playDelayed<T: Track>(_ track: T, delay: Double) {
  // ... snip
}

playDelayed(tracks, delay: 2.0) // argument type '[AudioTrack]' does not 
     conform to expected type 'Track'
```

#### 13.2.3. Making Array conditionally conform to a custom protocol

Since Swift 4.1, you can solve this problem where `Array` will conform to a custom protocol. You can make `Array` conform to `Track`, but *only* if its elements conform to `Track`. The only difference from before is that you add `:` `Track` after `Array`.

##### Listing 13.16. Making `Array` conform

```
// Before. Not conditionally conforming.
extension Array where Element: Track {
    // ... snip
}

// After. You have conditional conformance.
extension Array: Track where Element: Track {
    func play() {
        for element in self {
            element.play()
        }
    }
}
```

##### Warning

If you’re making a type conditionally conformant to a protocol with a constraint—such as `where` `Element:` `Track`—you need to supply the implementation yourself. Swift won’t synthesize this for you.

Now `Array` is a true `Track` type. You can pass it to functions expecting a `Track`, or nest arrays with other data and you can still call `play()` on it, as shown here.

##### Listing 13.17. Conditional conformance in action

```
let nestedTracks = [
    [
        AudioTrack(file: URL(fileURLWithPath: "1.mp3")),
        AudioTrack(file: URL(fileURLWithPath: "2.mp3"))
    ],
    [
        AudioTrack(file: URL(fileURLWithPath: "3.mp3")),
        AudioTrack(file: URL(fileURLWithPath: "4.mp3"))
    ]
]

// Nesting works.
nestedTracks.play()

// And, you can pass this array to a function expecting a Track!
playDelayed(tracks, delay: 2.0)
```

#### 13.2.4. Conditional conformance and generics

You’ve seen how you extend `Array` with a constraint on an associated type. What’s pretty nifty is that you can also constrain on generic type parameters.

As an example, let’s take `Optional`, because `Optional` only has a generic type called `Wrapped` and no associated types. You can make `Optional` implement `Track` with conditional conformance on its generic as follows.

##### Listing 13.18. Extending `Optional`

```
extension Optional: Track where Wrapped: Track {
    func play() {
        switch self {
        case .some(let track):           #1
            track.play()                 #1
        case nil:
            break // do nothing
        }
    }
}
```

Now `Optional` conforms to `Track`, but only if its inner value conforms to `Track`. Without conditional conformance you could already call `play()` on optionals conforming to `Track`.

##### Listing 13.19. Calling `play()` on an optional

```
let audio: AudioTrack? = AudioTrack(file: URL(fileURLWithPath: "1.mp3"))
audio?.play()                                                              #1
```

But now `Optional` officially is a `Track` as well, allowing us to pass it to types and functions expecting a `Track`. In other words, with conditional conformance, you can pass an optional `AudioTrack?` to a method expecting a non-optional `Track`.

##### Listing 13.20. Passing an optional to `playDelayed`

```
let audio: AudioTrack? = AudioTrack(file: URL(fileURLWithPath: "1.mp3"))
playDelayed(audio, delay: 2.0)                                             #1
```

#### 13.2.5. Conditional conformance on your types

Conditional conformance shines when you work with generic types, such as `Array`, `Optional`, or your own. Conditional conformance becomes powerful when you have a generic type storing an inner type, and you want the generic type to mimic the behavior of the inner type inside (see [figure 13.3](https://livebook.manning.com/book/swift-in-depth/chapter-13/ch13fig3)). Earlier, you saw how an `Array` becomes a `Track` if its elements are a `Track`.

![Figure 13.3. A type mimicking an inner type](https://drek4537l1klr.cloudfront.net/veen/Figures/13fig03.jpg)

Let’s see how this works when creating a generic type yourself. One such type could be a `CachedValue` type. `CachedValue` is a class storing a value. Once a certain time limit has passed, the value is refreshed by a closure that `CachedValue` stores.

The benefit of `CachedValue` is that it can cache expensive calculations for a while before refreshing. It can help limit repeatedly loading large files or repetition of expensive computations.

You can, for instance, store a value with a time-to-live value of two seconds. If you were to ask for the value after three seconds or more, the stored closure would be called again to refresh the value, as shown here.

##### Listing 13.21. `CachedValue` in action

```
let simplecache = CachedValue(timeToLive: 2, load: { () -> String in   #1
     print("I am being refreshed!")                                    #2
     return "I am the value inside CachedValue"
})

// Prints: "I am being refreshed!"
simplecache.value // "I am the value inside CachedValue"               #3
simplecache.value // "I am the value inside CachedValue"
 
sleep(3) // wait 3 seconds                                             #4
 
// Prints: "I am being refreshed!"                                     #4
simplecache.value // "I am the value inside CachedValue"
```

Let’s look at the internals of `CachedValue` and see how it works; then you’ll move on to conditional conformance.

##### Listing 13.22. Inside `CachedValue`

```
final class CachedValue<T> {                                                 #1
    private let load: () -> T                                                #2
    private var lastLoaded: Date

    private var timeToLive: Double
    private var currentValue: T

    public var value: T {
        let needsRefresh = abs(lastLoaded.timeIntervalSinceNow) > timeToLive #3
        if needsRefresh {
            currentValue = load()                                            #4
            lastLoaded = Date()
        }
        return currentValue                                                  #5
    }

    init(timeToLive: Double, load: @escaping (() -> T)) {
        self.timeToLive = timeToLive
        self.load = load
        self.currentValue = load()
        self.lastLoaded = Date()
    }
}
```

##### MAKING YOUR TYPE CONDITIONALLY CONFORMANT

Here comes the fun part. Now that you have a generic type, you can get in your starting positions and start adding conditional conformance. This way, `CachedValue` reflects the capabilities of its value inside. For instance, you can make `CachedValue` `Equatable` if its value inside is `Equatable`. You can make `CachedValue` `Hashable` if its value inside is `Hashable`, and you can make `CachedValue` `Comparable` if its value inside is `Comparable` (see [figure 13.4](https://livebook.manning.com/book/swift-in-depth/chapter-13/ch13fig4)).

![Figure 13.4. Making CachedValue conditionally conform to Equatable, Hashable, and Comparable.](https://drek4537l1klr.cloudfront.net/veen/Figures/13fig04_alt.jpg)

You can add extensions for all the protocols you can imagine (if they make sense). Ready? Set? Go!

##### Listing 13.23. Conditional conformance on `CachedValue`

```
// Conforming to Equatable
extension CachedValue: Equatable where T: Equatable {
    static func == (lhs: CachedValue, rhs: CachedValue) -> Bool {
        return lhs.value == rhs.value
    }
}
// Conforming to Hashable
extension CachedValue: Hashable where T: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}
// Conforming to Comparable
extension CachedValue: Comparable where T: Comparable {
    static func <(lhs: CachedValue, rhs: CachedValue) -> Bool {
        return lhs.value < rhs.value
    }
    static func ==(lhs: CachedValue, rhs: CachedValue) -> Bool {
        return lhs.value == rhs.value
    }
}
```

This is just the beginning; you can use your custom protocols and many others that Swift offers.

Now with conditional conformance in place, `CachedValue` takes on the properties of its inner type. Let’s try it out and see if `CachedValue` is properly `Equatable`, `Hashable`, and `Comparable`.

##### Listing 13.24. `CachedValue` is now `Equatable`, `Comparable`, and `Hashable`

```
let cachedValueOne = CachedValue(timeToLive: 60) {
    // Perform expensive operation
    // E.g. Calculate the purpose of life
    return 42
}

let cachedValueTwo = CachedValue(timeToLive: 120) {
    // Perform another expensive operation
    return 1000
}

cachedValueOne == cachedValueTwo // Equatable: You can check for equality.
cachedValueOne > cachedValueTwo // Comparable: You can compare two cached values.

let set = Set(arrayLiteral: cachedValueOne, cachedValueTwo) // Hashable: 
 You can store CachedValue in a set
```

You could keep going. For instance, you can make `CachedValue` implement `Track` or any other custom implementations.

Conditional conformance works best when storing the lowest common denominator inside the generic, meaning that you should aim to not add too many constraints on `T` in this case.

If a generic type by default is not constrained too much, then extending the type with conditional conformance is easier. In `CachedValue`’s case, `T` is unconstrained, so all types fit, and then you add functionality with conditional conformance. This way, both simple and advanced types fit inside `CachedValue`. As an exaggeration, if you were to constrain `T` to 10 protocols, very few types would fit inside `CachedValue`, and then there would be little benefit to adding functionality with conditional conformance-.

#### 13.2.6. Exercise

1. What is the benefit of a generic having few constraints, when applying conditional conformance?
1. Make `CachedValue` conform to the custom `Track` protocol from this chapter.

### 13.3. Dealing with protocol shortcomings

Protocols are a recipe for a love-hate relationship. They’re a fantastic tool, but then once in a while things that “should just work” simply aren’t possible.

For instance, a common problem for Swift developers is wanting to store `Hashable` types. You’ll quickly find out that it isn’t as easy as it seems.

Imagine that you’re modeling a game server for poker games. You have a `PokerGame` protocol, and `StudPoker` and `TexasHoldem` adhere to this protocol. Notice in the following listing how `PokerGame` is `Hashable` so that you can store poker games inside sets and use them as dictionary keys.

##### Listing 13.25. `PokerGame`

```
protocol PokerGame: Hashable {
    func start()
}

struct StudPoker: PokerGame {
    func start() {
        print("Starting StudPoker")
    }
}
struct TexasHoldem: PokerGame {
    func start() {
        print("Starting Texas Holdem")
    }
}
```

You can store `StudPoker` and `TexasHoldem` types into arrays, sets, and dictionaries. But if you want to mix and match different types of `PokerGame` as keys in a dictionary or inside an array, you stumble upon a shortcoming.

For instance, let’s say you want to store the number of active players for each game inside a dictionary, where `PokerGame` is the key.

##### Listing 13.26. `PokerGame` as a key throws an error

```
// This won't work!
var numberOfPlayers = [PokerGame: Int]()

// The error that the Swift compiler throws is:
error: using 'PokerGame' as a concrete type conforming to protocol 'Hashable' 
     is not supported
var numberOfPlayers = [PokerGame: Int]()
```

It sounds plausible to store `Hashable` as a dictionary key. But the compiler throws this error because you can’t use this protocol as a concrete type. `Hashable` is a subprotocol of `Equatable` and therefore has `Self` requirements, which prevents you from storing a `Hashable` at runtime. Swift wants `Hashable` resolved at compile time into a concrete type; a protocol, however, is not a concrete type.

You could store one type of `PokerGame` as a dictionary key, such as `[TexasHoldem:` `Int]`, but then you can’t mix them.

You could also try generics, which resolve to a concrete type. But this also won’t work.

##### Listing 13.27. Trying to mix games

```
func storeGames<T: PokerGame>(games: [T]) -> [T: Int] {
 /// ... snip
}
```

Unfortunately, this generic would resolve to a *single* type per function, such as the following.

##### Listing 13.28. A resolved generic

```
func storeGames(games: [TexasHoldem]) -> [TexasHoldem: Int] {
 /// ... snip
}

func storeGames(games: [StudPoker]) -> [StudPoker: Int] {
 /// ... snip
}
```

Again, you can’t easily mix and match `PokerGame` types into a single container, such as a dictionary.

Let’s take two different approaches to solve this problem. The first one involves an enum and the second one involves something called *type erasure*.

#### 13.3.1. Avoiding a protocol using an enum

Instead of using a `PokerGame` protocol, consider using a concrete type. Creating a `PokerGame` superclass is tempting, but you’ve explored the downsides of class-based inheritance already. Let’s use an enum instead.

As shown in [listing 13.29](https://livebook.manning.com/book/swift-in-depth/chapter-13/ch13list29), first, `PokerGame` becomes an enum, and stores `StudPoker` and `TexasHoldem` in each case as an associated value. Then, you make `StudPoker` and `TexasHoldem` conform to `Hashable` because `PokerGame` is not a protocol anymore. You also make `Poker-Game` conform to `Hashable` so that you can store it inside a dictionary. This way, you have concrete types, and you can store poker games inside a dictionary.

##### Listing 13.29. `PokerGame`

```
enum PokerGame: Hashable {
    case studPoker(StudPoker)
    case texasHoldem(TexasHoldem)
}

struct StudPoker: Hashable {
    // ... Implementation omitted
}
struct TexasHoldem: Hashable {
    // ... Implementation omitted
}

// This now works
var numberOfPlayers = [PokerGame: Int]()
```

##### Note

Notice how Swift generates the `Hashable` implementation for you, saving you from writing the boilerplate.

#### 13.3.2. Type erasing a protocol

Enums are a quick and painless solution to the problem where you can’t use some protocols as a type. But enums don’t scale well; maintaining a large number of cases is a hassle. Moreover, at the time of writing, you can’t let others extend enums with new cases if you were to build a public API. On top of that, protocols are *the* way to achieve dependency injection, which is fantastic for testing.

If you want to stick to a protocol, you can also consider using a technique called *type erasure*, sometimes referred to as *boxing*. With type erasure, you can move a compile-time protocol to runtime by wrapping a type in a container type. This way, you can have protocols with `Self` requirements—such as `Hashable` or `Equatable` types—or protocols with associated types as dictionary keys.

Before you begin, I must warn you. Erasing a type in Swift is as fun as driving in Los Angeles rush hour. Type erasure is a display of how Swift’s protocols aren’t fully matured yet, so don’t feel bad if it seems complicated. Type erasure is a workaround until the Swift engineers offer a native solution.

##### Note

Inside the Swift source, type erasure is also used. You’re not the only ones running into this problem!

You’ll introduce a new struct, called `AnyPokerGame`. This concrete type wraps a type conforming to `PokerGame` and hides the inner type. Then `AnyPokerGame` conforms to `PokerGame` and forwards the methods to the stored type (see [figure 13.5](https://livebook.manning.com/book/swift-in-depth/chapter-13/ch13fig5)).

![Figure 13.5. Type-erasing PokerGame](https://drek4537l1klr.cloudfront.net/veen/Figures/13fig05_alt.jpg)

Because `AnyPokerGame` is a concrete type—namely, a struct—you can use `AnyPokerGame` to store different poker games inside a single array, set, or dictionaries, and other places (see [figure 13.6](https://livebook.manning.com/book/swift-in-depth/chapter-13/ch13fig6)).

![Figure 13.6. Storing AnyPokerGame inside a Set](data:image/svg+xml;utf8,%3Csvg%20xmlns=%22http://www.w3.org/2000/svg%22%20xmlns:xlink=%22http://www.w3.org/1999/xlink%22%20version=%221.1%22%20x=%220px%22%20y=%220px%22%20viewBox=%220%200%20388%20211%22%20xml:space=%22preserve%22%20height=%22211px%22%20width=%22388px%22%3E%20%3Crect%20width=%22388%22%20height=%22211%22%20style=%22fill:rgb(255,255,255);%22/%3E%3C/svg%3E)

In code, you can see how `AnyPokerGame` wraps the `PokerGame`. Notice how you wrap both a `StudPoker` and `TexasHoldem` game in a single `Array` and `Set`, and also as `Dictionary` keys. Problem solved!

##### Listing 13.30. `AnyPokerGame` in action

```
let studPoker = StudPoker()
let holdEm = TexasHoldem()

// You can mix multiple poker games inside an array.
let games: [AnyPokerGame] = [
    AnyPokerGame(studPoker),
    AnyPokerGame(holdEm)
]

games.forEach { (pokerGame: AnyPokerGame) in
    pokerGame.start()
}

// You can store them inside a Set, too
let setOfGames: Set<AnyPokerGame> = [
    AnyPokerGame(studPoker),
    AnyPokerGame(holdEm)
]

// You can even use poker games as keys!
var numberOfPlayers = [
    AnyPokerGame(studPoker): 300,
    AnyPokerGame(holdEm): 400
]
```

##### Note

Remember `AnyIterator` from [chapter 9](https://livebook.manning.com/book/swift-in-depth/kindle_split_015.html#ch09)? It also type-erases the underlying iterator.

##### CREATING ANYPOKERGAME

Now that you’ve seen `AnyPokerGame` in action, it’s time to create it. You start by introducing `AnyPokerGame`, which adheres to `PokerGame`. In the initializer, you pass a `PokerGame` type constrained by a generic. Then, you store the `start` method from the passed `PokerGame` inside a private property called `_start`. Once `start()` is called on `AnyPokerGame`, you forward it to the stored `_start()` method.

##### Listing 13.31. Introducing `AnyPokerGame`

```
struct AnyPokerGame: PokerGame {                   #1
 
    init<Game: PokerGame>(_ pokerGame: Game)  {    #2
         _start = pokerGame.start                  #3
    }

    private let _start: () -> Void                 #4
 
    func start() {
        _start()                                   #5
    }
}
```

To erase a type, you tediously have to mirror every method from the protocol and store them in their functions as properties. But you’re in luck, because `PokerGame` only has a single method.

You’re almost done. Because `PokerGame` is also `Hashable`, you need to make `AnyPokerGame` adhere to `Hashable`. In this case, Swift can’t synthesize the `Hashable` implementation for you because you’re storing a closure. Like a `class`, a closure is a reference type, which Swift won’t synthesize; so you have to implement `Hashable` yourself. Luckily, Swift offers the `AnyHashable` type, which is a type-erased `Hashable` type. You can store the poker game inside `AnyHashable` and forward the `Hashable` methods to the `AnyHashable` type.

Let’s take a look at the complete implementation of `AnyPokerGame`.

##### Listing 13.32. Implementing `Hashable`

```
struct AnyPokerGame: PokerGame {

    private let _start: () -> Void
    private let _hashable: AnyHashable                      #1
 
    init<Game: PokerGame>(_ pokerGame: Game)  {
        _start = pokerGame.start
        _hashable = AnyHashable(pokerGame)                  #2
    }

    func start() {
        _start()
    }
}
extension AnyPokerGame: Hashable {                          #3
 
    func hash(into hasher: inout Hasher) {
        _hashable.hash(into: &hasher)                       #4
     }

    static func ==(lhs: AnyPokerGame, rhs: AnyPokerGame) -> Bool {
        return lhs._hashable == rhs._hashable
     }
}
```

##### Note

`AnyPokerGame` is extended as a style choice to separate the code to conform to `Hashable`.

Congratulations, you’ve erased a type! `AnyPokerGame` wraps any `PokerGame` type, and now you’re now free to use `AnyPokerGame` inside collections. With this technique, you can use protocols with `Self` requirements—or associated types—*and* work with them at runtime!

Unfortunately, the solution covered here is just the tip of the iceberg. The more complex your protocol is, the more complicated your type-erased protocol turns out. But it could be worth the trade-off; the consumers of your code benefit if you hide these internal complexities from them.

#### 13.3.3. Exercise

1. Are you up for an advanced challenge? You’re building a small Publisher/Subscriber (also known as Pub/Sub) framework, where a publisher can notify all its listed subscribers of an event:

// First, you introduce the PublisherProtocol.
protocol PublisherProtocol {
// Message defaults to String, but can be something else too.
// This saves you a typealias declaration.
associatedtype Message = String

// PublisherProtocol has a Subscriber, constrained to the
SubscriberProtocol.
// They share the same message type.
associatedtype Subscriber: SubscriberProtocol
where Subscriber.Message == Message
func subscribe(subscriber: Subscriber)
}

// Second, you introduce the SubscriberProtocol, resembling a
subscriber that reacts to events from a publisher.
protocol SubscriberProtocol {
// Message defaults to String, but can be something else too.
// This saves you a typealias declaration.
associatedtype Message = String
func update(message: Message)
}
// You create a Publisher that stores a single type of Subscriber. But
it can't mix and match subscribers.
final class Publisher<S: SubscriberProtocol>: PublisherProtocol where
S.Message == String {

var subscribers = [S]()
func subscribe(subscriber: S) {
subscribers.append(subscriber)
}

func sendEventToSubscribers() {
subscribers.forEach { subscriber in
subscriber.update(message: "Here's an event!")
}
}
}

copy

Currently, `Publisher` can maintain an array of a single type of subscriber. Can you type-erase `SubscriberProtocol` so that `Publisher` can store different types of subscribers? Hint: because `SubscriberProtocol` has an associated type, you can make a generic `AnySubscriber<Msg>` where `Msg` represents the `Message` associated type.

### 13.4. An alternative to protocols

You have seen many use-cases when dealing with protocols. With protocols, you may be tempted to make most of the code protocol-based. Protocols are compelling if you have a complex API; then your consumers only need to adhere to a protocol to reap the benefits, while you as a producer can hide the underlying complexities of a system.

However, a common trap is starting with a protocol before knowing that you need one. Once you hold a hammer—and a shiny one at that—things can start looking like nails. Apple advocates starting with a protocol in their WWDC videos. But protocols can be a pitfall, too. If you religiously follow the protocol-first paradigm, but aren’t sure yet if you need them, you may end up with unneeded complexity. You’ve also seen in the previous section how protocols have shortcomings that can make coming up with a fitting solution difficult.

Let’s use this section to consider another alternative.

#### 13.4.1. With great power comes great unreadability

First, consider if you truly need a protocol. Sometimes a little duplication is not that bad. With protocols, you pay the price of abstraction. Walking the line between over-abstractions and rigid code is a fine art.

A straightforward approach is sticking with concrete types when you’re not sure if you need a protocol; for instance, it’s easier to reason about a `String` than a complex generic constraint with three *where* clauses.

Let’s consider another alternative for when you think you need a protocol, but perhaps you can avoid it.

One protocol that is a common occurrence in one shape or another is a `Validator` protocol, representing some piece of data that can be validated, such as in forms. Before being shown an alternative, you’ll model the `Validator` with a protocol, as follows.

##### Listing 13.33. `Validator`

```
protocol Validator {
     associatedtype Value                      #1
     func validate(_ value: Value) -> Bool     #2
 }
```

Then, you can use this `Validator`, for instance, to check whether a `String` has a minimal amount of characters.

##### Listing 13.34. Implementing the `Validator` protocol

```
struct MinimalCountValidator: Validator {
    let minimalChars: Int

    func validate(_ value: String) -> Bool {
        guard minimalChars > 0 else { return true }
        guard !value.isEmpty else { return false } // isEmpty is faster than 
     count check
        return value.count >= minimalChars
    }
}

let validator = MinimalCountValidator(minimalChars: 5)
validator.validate("1234567890") // true
```

Now, for each different implementation, you have to introduce a new type conforming to `Validator` type, which is a fine approach but requires more boilerplate. Let’s consider an alternative to prove that you don’t always need protocols.

#### 13.4.2. Creating a generic struct

With generics, you make a type—such as a struct—work with many other types, but the implementation stays the same. If you add a higher-order function into the mix, you can swap out implementations, too. Instead of creating a `Validator` protocol and many `Validator` types, you can offer a generic `Validator` struct instead. Now, instead of having a protocol and multiple implementations, you can have one generic struct.

Let’s start by creating the generic `Validator` struct. Notice how it stores a closure, which allows you to swap out an implementation.

##### Listing 13.35. Introducing `Validator`

```
struct Validator<T> {

    let validate: (T) -> Bool

    init(validate: @escaping (T) -> Bool) {
        self.validate = validate
    }
}

let notEmpty = Validator<String>(validate: { string -> Bool in
    return !string.isEmpty
})

notEmpty.validate("") // false
notEmpty.validate("Still reading this book huh? That's cool!") // true
```

You end up with a type that can have different implementations *and* that works on many types. With minimal effort, you can seriously power up `Validator`. You can compose little validators into a smart validator via a `combine` method.

##### Listing 13.36. Combining validators

```
extension Validator {
    func combine(_ other: Validator<T>) -> Validator<T> {                  #1
         let combinedValidator = Validator<T>(validate: { (value: T) -> 
     Bool in                                                               #2
             let ownResult = self.validate(value)                          #3
             let otherResult = other.validate(value)
             return ownResult && otherResult
         })

        return combinedValidator                                           #4
     }
}

let notEmpty = Validator<String>(validate: { string -> Bool in
    return !string.isEmpty
})

let maxTenChars = Validator<String>(validate: { string -> Bool in          #5
     return string.count <= 10
})

let combinedValidator: Validator<String> = notEmpty.combine(maxTenChars)   #6
combinedValidator.validate("") // false
combinedValidator.validate("Hi") // true
combinedValidator.validate("This one is way too long") // false
```

You combined two validators. Because `combine` returns a new `Validator`, you can keep chaining, such as by combining a regular expression validator with a not-empty-string validator and so on. Also, because `Validator` is generic, it works on any type, such as `Int` validators and others. It’s one example of how you get flexibility without using protocols.

#### 13.4.3. Rules of thumb for polymorphism

Here are some heuristics to keep in mind when reasoning about polymorphism in Swift.

| **Requirements** | **Suggested approach** |
| --- | --- |
| Light-weight polymorphism | Use enums. |
| A type that needs to work with multiple types | Make a generic type. |
| A type that needs a single configurable implementation | Store a closure. |
| A type that works on multiple types *and* has a single configurable implementation | Use a generic struct or class that stores a closure. |
| When you need advanced polymorphism, default extensions, and other advanced use cases | Use protocols. |

### 13.5. Closing thoughts

You’re armed and ready to make code testable, apply Swift’s conditional conformance, type-erase generic types, and know when to use enums versus generic structs versus protocols!

This chapter laid out some tough sections, but you’re persistent and reached the end. It’s time to pat yourself on the back! The hardest part is over, and you’ve earned your Swift badge for covering the tough theory in this book.

### Summary

- You can use protocols as an interface to swap out implementations, for testing, or for other use cases.
- An associated type can resolve to a type that you don’t own.
- With conditional conformance, a type can adhere to a protocol, as long as its generic type or associated type adheres to this protocol.
- Conditional conformance works well when you have a generic type with very few constraints.
- A protocol with associated types or `Self` requirements can’t be used as a concrete type.
- Sometimes, you can replace a protocol with an enum, and use that as a concrete type.
- You can use a protocol with associated types or `Self` requirements at runtime via *type erasure*.
- Often a generic struct is an excellent alternative to a protocol.
- Combining a higher-order function with a generic struct enables you to create highly flexible types.

### Answers

1. Make `WaffleHouse` testable to verify that a `Waffle` has been served. One way is to make `Chef` a protocol, and then you can swap out the implementation of `Chef` inside `WaffleHouse`. Then you can pass a testing `chef` to `WaffleHouse`:

struct Waffle {}

protocol Chef {
func serve() -> Waffle
}

class TestingChef: Chef {
var servedCounter: Int = 0
func serve() -> Waffle {
servedCounter += 1
return Waffle()
}
}

struct WaffleHouse<C: Chef> {

let chef: C
init(chef: C) {
self.chef = chef
}

func serve() -> Waffle {
return chef.serve()
}

}

let testingChef = TestingChef()
let waffleHouse = WaffleHouse(chef: testingChef)
waffleHouse.serve()
testingChef.servedCounter == 1 // true

copy

1. What is the benefit of a generic having few constraints when applying conditional conformance? You have more flexibility in having a base working with many types, and you still have the option to get benefits when a type does conform to a protocol.
1. Make `CachedValue` conform to the custom `Track` protocol from this chapter:

extension CachedValue: Track where T: Track {
func play() {
currentValue.play()
}
}

copy

1. Build a small Publisher/Subscriber (also known as Pub/Sub) framework, where a publisher can notify all its listed subscribers of an event. You solve it by creating `AnySubscriber`. Notice how you need to make `AnySubscriber` generic, because of the `Message` associated type from `Subscriber`. In this case, `Publisher` stores `AnySubscriber` of type `AnySubscriber<String>`:

struct AnySubscriber<Msg>: SubscriberProtocol {

private let _update: (_ message: Msg) -> Void

typealias Message = Msg

init<S: SubscriberProtocol>(_ subscriber: S) where S.Message == Msg {
_update = subscriber.update
}

func update(message: Msg) {
_update(message)
}
}

copy

Publisher isn’t generic anymore. Now it can mix and match subscribers:

final class Publisher: PublisherProtocol {

// Publisher makes use of AnySubscriber<String> types. Basically,
it pins down the Message associated type to String.
var subscribers = [AnySubscriber<String>]()
func subscribe(subscriber: AnySubscriber<String>) {
subscribers.append(subscriber)
}

func sendEventToSubscribers() {
subscribers.forEach { subscriber in
subscriber.update(message: "Here's an event!")
}
}
}

copy
