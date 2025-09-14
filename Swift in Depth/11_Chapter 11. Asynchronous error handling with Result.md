# Chapter 11. Asynchronous error handling with Result

### ***This chapter covers***

- Learning about the problems with Cocoa style error handling
- Getting an introduction to Swift’s `Result` type
- Seeing how `Result` provides compile-time safety
- Preventing bugs involving forgotten callbacks
- Transforming data robustly with `map`, `mapError`, `flatMap`, and `flatMapError`
- Focusing on the happy path when handling errors
- Mixing throwing functions with `Result`
- Learning how to use errors dynamically with `Result`
- How to show intent with the `Never` type

You’ve covered a lot of Swift’s error handling mechanics, and you may have noticed in [chapter 6](https://livebook.manning.com/book/swift-in-depth/chapter-6/ch06) that you were throwing errors synchronously. This chapter focuses on handling errors from asynchronous processes, which is, unfortunately, an entirely different idiom in Swift.

Asynchronous actions could be some code running in the background while a current method is running. For instance, you could perform an asynchronous API call to fetch JSON data from a server. When the call finishes, it triggers a callback giving you the data or an error.

Swift 5 offers an official solution to asynchronous error handling. According to rumor, Swift will offer an even better solution once the async/await pattern gets introduced somewhere around Swift version 7 or 8. The community seems to favor asynchronous error handling with the `Result` type (which is reinforced by Apple’s inclusion of an official `Result` type since Swift 5). You may already have worked with the `Result` type and even implemented it in projects. In this chapter, you’ll use one offered by Swift, which may be a bit more advanced than most examples found online. To get the most out of `Result`, you’ll go deep into the rabbit hole and look at propagation and so-called monadic error handling. The `Result` type is an enum like `Optional`, with some differences, so if you’re comfortable with `Optional`, then `Result` should not be too big of a jump.

You’ll start off by exploring the `Result` type’s benefits and how you can add it to your projects. You’ll create a networking API, and then keep improving it in the following sections. Then you’ll start rewriting the API, but you’ll use the `Result` type to reap its benefits.

Next, you’ll see how to propagate asynchronous errors and how you can keep your code clean while focusing on the happy path. You do this via the use of `map`, `mapError`, and `flatMap`.

After building a solid API, you’ll look at a unique characteristic of Swift 5 that allows you to use errors dynamically in combination with `Result`. This technique gives you the option to store multiple types of errors inside a `Result`. The benefit is that you can loosen up the error handling strictness without needing to look back to Objective-C by using `NSError`. You’ll also see easy ways to swap back and forth between throwing functions and the `Result` type.

Before we finish up, you’ll see how to perform clean error handling with `Result` by using the elusive `flatMapError` method.

You’ll then take a look at the `Never` type to indicate that your code can never fail or succeed. It’s a little theoretical but a nice finisher. Consider it a bonus section.

By the end of the chapter, you’ll feel comfortable applying powerful transformations to your asynchronous code while dealing with all the errors that can come with it. You’ll also be able to avoid the dreaded pyramid of doom and focus on the happy path. But the significant benefit is that your code will be safe and succinct while elegantly handling errors—so let’s begin!

### 11.1. Why use the Result type?

##### Join Me!

It’s more educational and fun if you can check out the code and follow along with the chapter. You can download the source code at [http://mng.bz/5YP1](http://mng.bz/5YP1).

Swift’s throwing error-handling mechanism doesn’t translate well to asynchronous error handling. Not too long ago, developers tended to use Cocoa’s style of error handling—coming from the good ol’ Objective-C days—where a network call returns multiple values. For instance, you could fetch some JSON data from an API, and the callback gives you both a value *and* an error where you’d have to check for nil on both of them.

Unfortunately, the Cocoa Touch way has some problems—which you’ll uncover in a moment—and the `Result` type solves them. The `Result` type, inspired by Rust’s `Result` type and the `Either` type in Haskell and Scala, is a functional programming idiom that has been taken on by the Swift community.

#### 11.1.1. Result is like Optional, with a twist

`Result` is a *lot* like `Optional`, which is great because if you’re comfortable with optionals (see [chapter 4](https://livebook.manning.com/book/swift-in-depth/chapter-4/ch04)), you’ll feel right at home with the `Result` type.

Swift’s `Result` type is an enum with two cases: namely, a success case and a failure case. But don’t let that fool you. `Optional` is also “just” an enum with two cases, but it’s powerful, and so is `Result`.

In its simplest form, the `Result` type looks as follows.

##### Listing 11.1. The `Result` type

```
public enum Result<Success, Failure: Error > {                           #1
     /// Indicates success with value in the associated object.
    case success(Success)                                                #2
 
    /// Indicates failure with error inside the associated object.
    case failure(Failure)                                                #3
 
    // ... The rest is left out for later
}
```

The difference with `Optional` is that instead of a value being present (`some` case) or nil (`none` case), `Result` states that it either has a value (`success` case) or it has an error (`failure` case). In essence, the `Result` type indicates possible failure instead of nil. In other words, with `Result` you can give context for why an operation failed, instead of missing a value.

`Result` contains a value for each case, whereas with `Optional`, only the `some` case has a value. Also the `Failure` generic is constrained to Swift’s `Error` protocol, which means that only `Error` types can fit inside the `failure` case of `Result`. The constraint comes in handy for some convenience functions, which you’ll discover in a later section. Note that the `success` case can fit any type because it isn’t constrained.

You haven’t seen the full `Result` type, which has plenty of methods, but this code is enough to get you started. Soon enough you’ll get to see more methods, such as bridging to and from throwing functions and transforming values and errors inside `Result` in an immutable way.

Let’s quickly move on to the *raison d’être* of `Result`: error handling.

#### 11.1.2. Understanding the benefits of Result

To better understand the benefits of the `Result` type in asynchronous calls, let’s first look at the downsides of Cocoa Touch–style asynchronous APIs before you see how `Result` is an improvement. Throughout the chapter, you’ll keep updating this API with improvements.

Let’s look at `URLSession` inside the `Foundation` framework. You’ll use `URL-Session` to perform a network call, as shown in [listing 11.2](https://livebook.manning.com/book/swift-in-depth/chapter-11/ch11list2), and you’re interested in the data and error of the response. The iTunes app isn’t known for its “popular” desktop application, so you’ll create an API for searching the iTunes Store without a desktop app.

To start, you’ll use a hardcoded string to search for “iron man”—which you percent encode manually at first—and make use of a function `callURL` to perform a network call.

##### Listing 11.2. Performing a network call

```
func callURL(with url: URL, completionHandler: @escaping (Data?, Error?)   #1
 -> Void) {                                                              #2
     let task = URLSession.shared.dataTask(with: url, completionHandler: 
 { (data, response, error) -> Void in
        completionHandler(data, error)                                     #3
     })

    task.resume()
}

let url = URL(string: "https://itunes.apple.com/search?term=iron%20man")!

callURL(with: url) { (data, error) in                                      #4
     if let error = error {                                                #5
         print(error)
    } else if let data = data {                                            #6
         let value = String(data: data, encoding: .utf8)                   #7
         print(value)
    } else {
        // What goes here?                                                 #8
     }
}
```

But the problem is that you have to check whether an error and/or the data is nil. Also, what happens if both values are nil? The `URLSession` documentation ([http://mng.bz/oVxr](http://mng.bz/oVxr)) states that either `data` or `error` has a value; yet in code this isn’t reflected, and you still have to check against all values.

When returning multiple values from an asynchronous call from `URLSession`, a success and failure value are not mutually exclusive. In theory, you could have received both response data and a failure error or neither. Or you can have one or the other, but falsely assume that if there is no error, the call must have succeeded. Either way, you don’t have a compile-time guarantee to enforce safe handling of the returned data. But you’re going to change that and see how `Result` will give you these compile-time guarantees.

#### 11.1.3. Creating an API using Result

Let’s get back to the API call. With a `Result` type, you can enforce at compile time that a response is either a success (with a value) or a failure (with an error). As an example, let’s update the asynchronous call so that it passes a `Result`.

You’re going to introduce a `NetworkError` and make the `callURL` function use the `Result` type.

##### Listing 11.3. A response with `Result`

```
enum NetworkError: Error {
    case fetchFailed(Error)                                                #1
 }

func callURL(with url: URL, completionHandler: @escaping (Result<Data, 
 NetworkError>) -> Void) {                                              #2
    let task = URLSession.shared.dataTask(with: url, completionHandler: { 
 (data, response, error) -> Void in
      // ... details will be filled in shortly
    })

    task.resume()
}

let url = URL(string: "https://itunes.apple.com/search?term=iron%20man")!

callURL(with: url) { (result: Result<Data, NetworkError>) in               #3
    switch result {
    case .success(let data):                                               #4
         let value = String(data: data, encoding: .utf8)
         print(value)
    case .failure(let error):                                              #5
         print(error)
    }
}
```

As you can see, you receive a `Result<Data,` `NetworkError>` type when you call `call-URL()`. But this time, instead of matching on both `error` and `data`, the values are now mutually exclusive. If you want the value out of `Result`, you *must* handle both cases, giving you compile-time safety in return and removing any awkward situations where both `data` and `error` can be nil or filled at the same time. Also, a big benefit is that you know beforehand that the error inside the `failure` case is of type `NetworkError`, as opposed to throwing functions where you only know the error type at runtime.

You may also use an error handling system where a data type contains an `onSuccess` or `onFailure` closure. But I want to emphasize that with `Result`, if you want the value out, you *must* do something with the error.

##### AVOIDING ERROR HANDLING

Granted, you can’t fully enforce handling an error inside of `Result` if you match on a single case of an enum with the `if` `case` `let` statement. Alternatively, you can ignore the error with the infamous `//` `TODO` `handle` `error` comment, but then you’d be consciously going out of your way to avoid handling an error. Generally speaking, if you want to get the value out of `Result`, the compiler tells you to handle the error, too.

#### 11.1.4. Bridging from Cocoa Touch to Result

Moving on, the response from `URLSession`’s `dataTask` returns three values: `data`, `response`, and `error`.

##### Listing 11.4. The `URLSession`'s response

```
URLSession.shared.dataTask(with: url, completionHandler: { (data, response,
     error) -> Void in ... }
```

But if you want to work with `Result`, you’ll have to convert the values from `URL-Session`’s completion handler to a `Result` yourself. Let’s take this opportunity to flesh out the `callURL` function so that you can bridge Cocoa Touch–style error handling to a `Result`-style error handling.

One way to convert a value and error to `Result` is to add a custom initializer to `Result` that performs the conversion for you, as shown in the next listing. You can pass this initializer the data and error, and then use that to make a new `Result`. In your `callURL` function, you can then return a `Result` via the closure.

##### Listing 11.5. Converting a response and error into a `Result`

```
extension Result<Success, Failure> {
      // ... snip

    init(value: Success?, error: Failure?) {                               #1
        if let error = error {
            self = .failure(error)
        } else if let value = value {
            self = .success(value)
        } else {
            fatalError("Could not create Result")                          #2
        }
    }
}

func callURL(with url: URL, completionHandler: @escaping (Result<Data, 
 NetworkError>) -> Void) {
    let task = URLSession.shared.dataTask(with: url, completionHandler: 
 { (data, response, error) -> Void in
         let dataTaskError = error.map { NetworkError.fetchFailed($0)}     #3
         let result = Result<Data, NetworkError>(value: data, error: 
 dataTaskError)                                                          #4
         completionHandler(result)                                         #5
    })

    task.resume()
}
```

##### If an API Doesn’t Return a Value

Not all APIs return a value, but you can still use `Result` with a so-called *unit type* represented by `Void` or `()`. You can use `Void` or `()` as the value for a `Result`, such as `Result<(),` `MyError>`.

### 11.2. Propagating Result

Let’s make your API a bit higher-level so that instead of manually creating URLs, you can search for items in the iTunes Store by passing strings. Also, instead of dealing with lower-level errors, let’s work with a higher-level `SearchResultError`, which better matches the new search abstraction you’re creating. This section is a good opportunity to see how you can propagate and transform any `Result` types.

The API that you’ll create allows you to enter a search term, and you’ll get JSON results back in the shape of `[String:` `Any]`

##### Listing 11.6. Calling the search API

```
enum SearchResultError: Error {
     case invalidTerm(String)                                                   #1
     case underlyingError(NetworkError)                                         #2
     case invalidData                                                           #3
 }
search(term: "Iron man") { (result: Result<[String: Any], SearchResultError>) in#4
     print(result)
}
```

#### 11.2.1. Typealiasing for convenience

Before creating the `search` implementation, you create a few typealiases for convenience, which come in handy when repeatedly working with the same `Result` over and over again.

For instance, if you work with many functions that return a `Result<Value,` `SearchResultError>`, you can define a typealias for the `Result` containing a `Search-ResultError`. This typealias is to make sure that `Result` requires only a single generic instead of two by pinning the error generic.

##### Listing 11.7. Creating a typealias

```
typealias SearchResult<Success> = Result<Success, SearchResultError>   #1
 
let searchResult = SearchResult.success("Tony Stark")                  #2
print(searchResult) // success("Tony Stark")
```

##### Partial Typealias

The typealias still has a `Success` generic for `Result`, which means that the defined `SearchResult` is pinned to `SearchResultError`, but its value could be anything, such as a `[String:` `Any]`, `Int`, and so on.

You can create this `SearchResult` by only passing it a value. But its true type is `Result<Success,` `SearchResultError>`.

Another typealias you can introduce is for the JSON type, namely a dictionary of type `[String:` `Any]`. This second typealias helps you to make your code more readable-, so that you work with `SearchResult<JSON>` in place of the verbose `SearchResult-<[String:` `Any]>` type.

##### Listing 11.8. The JSON typealias

```
typealias JSON = [String: Any]
```

With these two typealiases in place, you’ll be working with the `SearchResult<JSON>` type.

#### 11.2.2. The search function

The new `search` function makes use of the `callURL` function, but it performs two extra tasks: it parses the data to JSON, and it translates the lower-level `NetworkError` to a `SearchResultError`, which makes the function a bit more high-level to use, as shown in the following listing.

##### Listing 11.9. The `search` function implementation

```
func search(term: String, completionHandler: @escaping (SearchResult<JSON>)
     -> Void) {                                                              #1
     let encodedString = term.addingPercentEncoding(withAllowedCharacters:
     .urlHostAllowed)                                                        #2
     let path = encodedString.map { "https://itunes.apple.com/search?term="
     + $0 }                                                                  #3
 
    guard let url = path.flatMap(URL.init) else {                            #4
         let result = SearchResult<JSON>.failure(.invalidTerm(term))
                 completionHandler(result)                                   #5
         return
    }

    callURL(with: url) { result in                                           #6
        switch result {
        case .success(let data):                                             #7
             if
                let json = try? JSONSerialization.jsonObject(with: data,
   options: []),
                let jsonDictionary = json as? JSON {
                let result = SearchResult<JSON>.success(jsonDictionary)
                completionHandler(result)                                    #8
             } else {
                let result = SearchResult<JSON>.failure(.invalidData)
                completionHandler(result)                                    #9
             }
        case .failure(let error):
             let result = SearchResult<JSON>.failure(.underlyingError(error))#10
             completionHandler(result)
        }
    }
}
```

Thanks to the `search` function, you end up with a higher-level function to search the iTunes API. But, it’s still a little bit clunky because you’re manually creating multiple result types and calling the `completionHandler` in multiple places. It’s quite the boilerplate, and you could possibly forget to call the `completionHandler` in larger functions. Let’s clean that up with `map`, `mapError`, and `flatMap` so that you’ll transform and propagate a single `Result` type and you’ll only need to call `completion-Handler` once.

### 11.3. Transforming values inside Result

Similar to how you can weave optionals through an application and `map` over them (which delays the unwrapping), you can also weave a `Result` through your functions and methods while programming the happy path of your application. In essence, after you obtained a `Result`, you can pass it around, transform it, and only switch on it when you’d like to extract its value or handle its error.

One way to transform a `Result` is via `map`, similar to mapping over `Optional`. Remember how you could `map` over an optional and transform its inner value if present? Same with `Result`: you transform its `success` value if present. Via mapping, in this case, you’d turn `Result<Data,` `NetworkError>` into `Result<JSON,` `NetworkError>`.

Related to how `map` ignores nil values on optionals, `map` also ignores errors on `Result` (see [figure 11.1](https://livebook.manning.com/book/swift-in-depth/chapter-11/ch11fig1)).

![Figure 11.1. Mapping over a Result](https://drek4537l1klr.cloudfront.net/veen/Figures/11fig01_alt.jpg)

As a special addition, you can *also* `map` over an error instead of a value inside `Result`. Having `mapError` is convenient because you translate a `NetworkError` inside `Result` to a `SearchResultError`.

With `mapError`, you’d therefore turn `Result<JSON,` `NetworkError>` into `Result <JSON,` `SearchResultError>`, which matches the type you pass to the `completionHandler` (see [figure 11.2](https://livebook.manning.com/book/swift-in-depth/chapter-11/ch11fig2)).

![Figure 11.2. Mapping over an error inside Result](https://drek4537l1klr.cloudfront.net/veen/Figures/12fig03_alt.jpg)

With the power of both `map` and `mapError` combined, you can turn a `Result<Data,` `NetworkError>` into a `Result<JSON,` `SearchResultError>`, aka `SearchResult<JSON>`, without having to switch on a result once (see [figure 11.3](https://livebook.manning.com/book/swift-in-depth/chapter-11/ch11fig3)). The [listing 11.10](https://livebook.manning.com/book/swift-in-depth/chapter-11/ch11list10) gives an example of mapping over an error and value.

![Figure 11.3. Mapping over both the value and error](https://drek4537l1klr.cloudfront.net/veen/Figures/11fig03.jpg)

Applying `mapError` and `map` help you remove some boilerplate from earlier in the `search` function.

##### Listing 11.10. Mapping over an error and value

```
func search(term: String, completionHandler: @escaping (SearchResult<JSON>)
 -> Void) {
    // ... snip

    callURL(with: url) { result in

        let convertedResult: SearchResult<JSON> =
            result                                                  #1
                 // Transform Data to JSON
                .map { (data: Data) -> JSON in                      #2
                     guard
                        let json = try? JSONSerialization.jsonObject(with:
 data, options: []),
                        let jsonDictionary = json as? JSON else {
                            return [:]                              #3
                     }

                    return jsonDictionary
                }
                // Transform NetworkError to SearchResultError
                .mapError { (networkError: NetworkError) ->
 SearchResultError in                                             #4
                     return SearchResultError.underlyingError(networkError) 
 // Handle error from lower layer
        }

        completionHandler(convertedResult)                          #5
     }
}
```

Now, instead of manually unwrapping result types and passing them to the `completion-Handler` in multiple flows, you transform the `Result` to a `SearchResult`, and pass it to the `completionHandler` only once. Just like with optionals, you delay any error handling until you want to get the value out.

As the next step for improvement, let’s improve failure, because currently you’re returning an empty dictionary instead of throwing an error. You’ll improve this with `flatMap`.

#### 11.3.1. flatMapping over Result

One missing piece from your search function is that when the data can’t be converted to JSON format, you’d need to obtain an error. You could throw, but throwing is somewhat awkward because you would be mixing Swift’s throwing idiom with the `Result` idiom. You’ll take a look at that in section 11.4.

To stay in the `Result` way of thinking, let’s return another `Result` from inside `map`. But you may have guessed that returning a `Result` from a mapping operation leaves you with a nested `Result`, such as `SearchResult<SearchResult<JSON>>`. You can make use of `flatMap`—that is defined on `Result`—to get rid of one extra layer of nesting.

Exactly like how you can use `flatMap` to turn `Optional<Optional<JSON>>` into `Optional<JSON>`, you can also turn `SearchResult<SearchResult<JSON>>` into `Search-Result<JSON>` (see [figure 11.4](https://livebook.manning.com/book/swift-in-depth/chapter-11/ch11fig4)).

![Figure 11.4. How flatMap works on Result](https://drek4537l1klr.cloudfront.net/veen/Figures/11fig04_alt.jpg)

By replacing `map` with `flatMap` when parsing `Data` to `JSON`, you can return an error `Result` from inside the `flatMap` operation when parsing fails, as shown in [listing 11.11](https://livebook.manning.com/book/swift-in-depth/chapter-11/ch11list11).

##### Listing 11.11. `flatMap`ing over `Result`

```
func search(term: String, completionHandler: @escaping (SearchResult<JSON>)
 -> Void) {
      // ... snip

    callURL(with: url) { result in

        let convertedResult: SearchResult<JSON> =
            result
                // Transform error type to SearchResultError
                .mapError { (networkError: NetworkError) ->
 SearchResultError in                                                    #1
                     return SearchResultError.underlyingError(networkError)
                }
                // Parse Data to JSON, or return SearchResultError
                .flatMap { (data: Data) -> SearchResult<JSON> in           #2
                     guard
                        let json = try? JSONSerialization.jsonObject(with:
 data, options: []),
                        let jsonDictionary = json as? JSON else {
                            return SearchResult.failure(.invalidData)      #3
                     }

                     return SearchResult.success(jsonDictionary)
        }
        completionHandler(convertedResult)
    }
}
```

##### Flatmap Doesn’t Change the Error Type

A `flatMap` operation on `Result` doesn’t change an error type from one to another. For instance, you can’t turn `Result<Value,` `SearchResultError>` to a `Result<Value,` `NetworkError>` via a `flatMap` operation. This is something to keep in mind and why `mapError` is moved up the chain.

#### 11.3.2. Weaving errors through a pipeline

By composing `Result` with functions via mapping and flatmapping, you’re performing so-called *monadic* error handling. Don’t let the term scare you—`flatMap` is based on *monad* laws from functional programming. The beauty is that you can focus on the happy path of transforming your data.

As with optionals, `flatMap` isn’t called if `Result` doesn’t contain a value. You can work with the real value (whether `Result` is erroneous or not) while carrying an error context and propagate the `Result` higher—all the way to where some code can pattern match on it, such as the caller of a function.

As an example, if you were to continue the data transformations, you could end up with multiple chained operations. In this pipeline, `map` would always keep you on the happy path, and with `flatMap` you could short-circuit and move to either the happy path or error path.

For instance, let’s say you want to add more steps, such as validating data, filtering it, and storing it inside a database (perhaps a cache). You would have multiple steps where `flatMap` could take you to an error path. In contrast, `map` always keeps you on the happy path (see [figure 11.5](https://livebook.manning.com/book/swift-in-depth/chapter-11/ch11fig5)).

![Figure 11.5. Happy path programming](https://drek4537l1klr.cloudfront.net/veen/Figures/11fig05.jpg)

For the sake of brevity, you aren’t going to implement all these methods, but the point is that you can build a sophisticated pipeline, as shown in the following listing, weave the error through it, and only call the completion handler once.

##### Listing 11.12. A longer pipeline

```
func search(term: String, completionHandler: @escaping (SearchResult<JSON>)
     -> Void) {
      // ... snip
    callURL(with: url) { result in

        let convertedResult: SearchResult<JSON> =
            result
                // Transform error type to SearchResultError
                .mapError { (networkError: NetworkError) ->
    SearchResultError in
                  // code omitted
                }
                // Parse Data to JSON, or return SearchResultError
                .flatMap { (data: Data) -> SearchResult<JSON> in
                  // code omitted
                }
                // validate Data
                .flatMap { (json: JSON) -> SearchResult<JSON> in
                  // code omitted
                }
                // filter values
                .map { (json: JSON) -> [JSON] in
                  // code omitted
                }
                // Save to database
                .flatMap { (mediaItems: [JSON]) -> SearchResult<JSON> in
                  // code omitted
        }

        completionHandler(convertedResult)
    }
}
```

##### Short-Circuiting a Chaining Operation

Note that `map` and `flatMap` are ignored if `Result` contains an error. If any `flatMap` operation returns a `Result` containing an error, any subsequent `flatMap` and `map` operations are ignored as well.

With `flatMap` you can short-circuit operations, just like with `flatMap` on `Optional`.

#### 11.3.3. Exercises

1. Using the techniques you’ve learned, try to connect to a real API. See if you can implement the FourSquare API ([http://mng.bz/nxVg](http://mng.bz/nxVg)) and obtain the venues JSON. You can register to receive free developer credentials. Be sure to use `Result` to return any venues that you can get from the API. To allow for asynchronous calls inside playgrounds, add the following:

import PlaygroundSupport
PlaygroundPage.current.needsIndefiniteExecution = true

copy

1. See if you can use `map`, `mapError`, and even `flatMap` to transform the result so that you call the completion handler only once.
1. The server can return an error, even if the call succeeds. For example, if you pass a latitude and longitude of 0, you get an `errorType` and `errorDetail` value in the `meta` key in the JSON, like so:

{"meta":{"code":400,"errorType":"param_error","errorDetail":"Must
provide parameters (ll and radius) or (sw and ne) or (near and
radius)","requestId":"5a9c09ba9fb6b70cfe3f2e12"},"response":{}}

copy

Try to make sure that this error is reflected in the `Result` type.

#### 11.3.4. Finishing up

It may not look like much, but your API packs quite the punch. It handles network errors and parsing errors, and it’s easy to read and to extend. And still you avoid having an ugly pyramid of doom, and your code mostly focuses on the happy path. On top of that, calling `search` means that you only need to switch on the `Result`.

Receiving a simple `Result` enum looks a little underwhelming after all that work. But clean APIs tend to appear simple from time to time.

### 11.4. Handling multiple errors with Result

Working with Result may feel constricting at times when multiple actions can fail. Previously, you were translating each failure into a `Result` holding a single error type, namely `SearchResultError`. Translating errors to a single error type can be a good practice to follow. But, it may get burdensome moving forward if you’re dealing with many different errors, which can slow you down—especially when you’re beginning a new project, and you need to glue together all kinds of methods that can fail. Luckily, Swift offers a solution for this.

Imagine the following scenario in which you want to process a payment between two accounts. You create the `processPayment` method, passing two accounts to transfer money from and to, and the amount to transfer in cents. For example purposes, we make `processPayment` a synchronous method, meaning that instead of a completion closure, we return a `Result`. We naively pin the `Error` type in the `Result` to `PaymentError`.

##### Note

Since we aren’t interested in the value, you can define the `Success` type of `Result` to `()`, also known as `Void` or unit.

##### Listing 11.13. Returning a specific error type

```
func processPayment(fromAccount: Account, toAccount: Account,
     amountInCents:Int) -> Result<(), PaymentError> {         #1
    // rest omitted
}
```

This is a good start, but there’s a problem; the `processPayment` method can return multiple `Error` types, such as a `PaymentError` or an `AccountError`, and inside the method, there’s a call to `moneyAPI.transfer(amount:,` `from:,` `to:)`, which can also throw errors. Mixing errors means that you can’t return a `Result` containing a specific `PaymentError`. You may want to loosen up your code by mixing and matching multiple error types in combination with the `Result` type. We can introduce a new error type that can store other errors, but there’s a quicker way. What we can do is pin the `Error` generic to itself in the definition of `Result`, such as `Result<(),` `Error>`; this will allow us to use errors at runtime. Let’s see how this works by completing the `processPayment` method.

##### Listing 11.14. Returning multiple error types

```
func processPayment(fromAccount: Account, toAccount: Account,
     amountInCents:Int) -> Result<(), Error> {               #1

    guard amountInCents > 0 else {
        return Result.failure(PaymentError.amountTooLow)     #2
    }

    guard fromAccount != toAccount else {
        return Result.failure(AccountError.invalidAccount)   #2
    }

    // Process payment
    do {
        try moneyAPI.transfer(amount: amountInCents, from: fromAccount, to:
     toAccount)
        return Result.success(())
    } catch {
        return Result.failure(error)                         #3
    }
}
```

Once we set the `Error` type to `Error` itself, we can put all kinds of error types inside `Result`. The downside is that we don’t know the error type until runtime, similar to throwing methods.

##### Note

One could argue “Why not use a throwing method if you use Result synchronously?” This is a controversial topic and shows why `Result` is reluctantly added to the Swift language, because we ended up having two error-handling idioms in the Swift language. The Swift language designers favor throwing methods by convention, but nothing is stopping you from choosing a functional style of error handling with `Result`.

Using errors dynamically will speed up your development when working with `Result`. Then, once you’re ready, you can slowly replace each `Error` inside `Result` to a specific error, which you can do with `mapError()`. Working with specific errors will make your code more rigid, but, in return, you gain robustness by having error-type knowledge at compile-time.

When we set the `Error` constraint to `Error` itself—as opposed to a concrete type such as `PaymentError`—we state that *Error conforms to itself*. Having a protocol conform to itself normally isn’t possible for other protocols, but `Error` is an exception. One reason that this is possible is because the `Error` protocol definition is empty—it is a marker for error handling, if you will. The Swift 5 compiler can use that knowledge to apply some optimizations that allow for this rare exception.

#### 11.4.1. Mixing Result with throwing functions

We’ve seen how Result is a second idiom as opposed to throwing functions. Let’s talk about swapping back and forth between them.

First, we can easily bridge from a throwing function to Result. Looking at the example from before, we’ve seen how we had a throwing method, namely `moneyAPI .transfer(amount:,` `from:,` `to:)`, which we put inside a `do` `catch` statement. `Result` offers a convenience method to quickly turn the throwing method into a `Result` to shave off a few lines. You can use the method by passing a throwing method to the `Result(catching:)` initializer.

##### Listing 11.15. Using the catching initializer on `Result`

```
// Before
do {
    try moneyAPI.transfer(amount: amountInCents, from: fromAccount, to:
     toAccount)
    return Result.success(())
} catch {
    return Result.failure(error)
}

// After
return Result(catching: {
    try moneyAPI.transfer(amount: amountInCents, from: fromAccount, to:
     toAccount)
})
```

Conversely, if you have a `Result`, and if you want the value out, you can use the throwing `get()` method on `Result`. For example, in the next listing, we can log the value inside a `Result`. We get the value out using the `get()` method, and if `Result` contains an error, `get()` will throw it, which you can catch.

##### Listing 11.16. Getting the value out using the `get` method

```
func logPaymentResult(_ result: Result<String, PaymentError>) {
    do {
        let string = try result.get()
        print("Payment succeeded: \(string)")
    } catch {
        print("Received error: \(error)")
    }
}

// Will print: "Received error: amountTooLow
logPaymentResult(.failure(PaymentError.amountTooLow))
```

#### 11.4.2. Exercise

1. Given the following throwing functions, see if you can use them to transform `Result` in your FourSquare API:

func parseData(_ data: Data) throws -> JSON {
guard
let json = try? JSONSerialization.jsonObject(with: data,
options: []),
let jsonDictionary = json as? JSON else {
throw FourSquareError.couldNotParseData
}
return jsonDictionary
}

func validateResponse(json: JSON) throws -> JSON {
if
let meta = json["meta"] as? JSON,
let errorType = meta["errorType"] as? String,
let errorDetail = meta["errorDetail"] as? String {
throw FourSquareError.serverError(errorType: errorType,
errorDetail: errorDetail)
}

return json
}

func extractVenues(json:  JSON) throws -> [JSON] {
guard
let response = json["response"] as? JSON,
let venues = response["venues"] as? [JSON]
else {
throw FourSquareError.couldNotParseData
}
return venues
}

copy

### 11.5. Error recovery with Result

Another mechanic that `Result` offers is error recovery. Normally, you would be using `do` `catch` when we deal with throwing methods. However, since `Result` is a functional programming type, it uses another so-called *functional combinator* for error recovery, which is `flatMapError`.

As the name implies, `flatMapError` is very similar to `flatMap`. Instead of mapping over the value and flattening it, we can map over an error to produce a new result and flatten that. When you use `flatMapError`, you can produce a successful result from an error (see [figure 11.6](https://livebook.manning.com/book/swift-in-depth/chapter-11/ch11fig6)).

![Figure 11.6. Calling flatMapError on Result](data:image/svg+xml;utf8,%3Csvg%20xmlns=%22http://www.w3.org/2000/svg%22%20xmlns:xlink=%22http://www.w3.org/1999/xlink%22%20version=%221.1%22%20x=%220px%22%20y=%220px%22%20viewBox=%220%200%20590%20379%22%20xml:space=%22preserve%22%20height=%22379px%22%20width=%22590px%22%3E%20%3Crect%20width=%22590%22%20height=%22379%22%20style=%22fill:rgb(255,255,255);%22/%3E%3C/svg%3E)

For example, imagine that we’re loading a weather report from a public API, which will return us a `Result<Data,` `Error>`. Our goal is to create an API that will give us a concrete `WeatherReport` with a concrete `WeatherError` if there is one, such as `Result<WeatherReport,` `WeatherError>`. You can use `flatMap` to transform this data to a `WeatherReport` type. If the loading has failed, however, you use `flatMapError` to recover and offer a dummy `WeatherReport` as a fallback option, such as for testing your application.

##### Listing 11.17. Error recovery using `flatMapError`

```
enum WeatherError: Error {                                                 #1
    case loadingFailed
    case couldNotParseData
}

func loadWeatherReport(completion: @escaping (Result<WeatherReport,
     WeatherError>) -> Void) {                                             #2
    loadData(url: URL(string: "https://api.myweatherstartup.com")!) {
     (result: Result<Data, Error>) in                                      #3
        let transformedResult =                                            #4
            result
                .flatMap { (data: Data) -> Result<WeatherReport, Error> in #5
                    return Result(catching: { try WeatherReport.init(data: #5
     data) })                                                              #5
                }
                .flatMapError({ (error: Error) -> Result<WeatherReport,
     WeatherError> in                                                      #6
                    guard error is WeatherError else {
                        return Result.failure(WeatherError.loadingFailed)  #7
                    }

                    // Parsing failed, let's return a hard-coded
     WeatherReport
                    let weatherReport = WeatherReport(fahrenheit: 68,
     pressure: 1012, humidity: 81, windSpeed: 4, description: "windy")
                    return Result.success(weatherReport)                   #8
                })

        completion(transformedResult)                                      #9
    }
}

loadWeatherReport { (result: Result<WeatherReport, WeatherError>) in       #10
    switch result {
        case .success(let weatherReport):
            print("Received \(weatherReport)")
        case .failure(let error):
            print("Could not load weather report \(error)")
    }
}
```

In practice, you can do more elaborate error recovery using `flatMapError`, such as loading cached weather reports or more elaborate error transformations. In the end, `loadWeatherReport` is nothing but a pipeline of transformations.

##### Note

Remember how `flatMap` doesn’t allow you to change the type of error? When using `flatMapError`, you can change the error if you want, but you can’t change the type of success value.

Generally speaking, it makes sense for `flatMapError` to exist when it’s part of a larger API where you transform and propagate a `Result` value. However, you run the risk of being too “clever.” If you use `Result` in isolation, I recommend using the `get()` method and performing a regular `do` `catch` on the error that `get()` may throw. Again, we’re dealing with two idioms here, so I recommend favoring the one that most Swift developers know by heart.

### 11.6. Impossible failure and Result

Sometimes you may need to conform to a protocol that wants you to use a `Result` type. But the type that implements the protocol may never fail. Let’s see how you can improve your code in this scenario with a unique tidbit. This section is a bit esoteric and theoretical, but it proves useful when you run into a similar situation.

#### 11.6.1. When a protocol defines a Result

Imagine that you have a `Service` protocol representing a type that loads some data for you. This `Service` protocol determines that data is to be loaded asynchronously, and it makes use of a `Result`.

You have multiple types of errors and data that can be loaded, so `Service` defines them as associated types.

##### Listing 11.18. The `Service` protocol

```
protocol Service {
     associatedtype Value                                          #1
     associatedtype Err: Error                                     #2
     func load(complete: @escaping (Result<Value, Err>) -> Void)   #3
 }
```

Now you want to implement this `Service` by a type called `SubscriptionsLoader`, which loads a customer’s subscriptions for magazines. This is shown in [listing 11.19](https://livebook.manning.com/book/swift-in-depth/chapter-11/ch11list19). Note that loading subscriptions *always* succeeds, which you can guarantee because they are loaded from memory. But the `Service` type declares that you use `Result`, which needs an error, so you do need to declare what error a `SubscriptionsLoader` throws. `SubscriptionsLoader` doesn’t have errors to throw. To remedy this problem, let’s create an empty enum—conforming to `Error`—called `BogusError` so that `Subscriptions-Loader` can conform to `Service` protocol. Notice that `BogusError` has no cases, meaning that nothing can actually create this enum.

##### Listing 11.19. Implementing the `Service` protocol

```
struct Subscription {                                                    #1
   // ... details omitted
}

enum BogusError: Error {}                                                #2
 
final class SubscriptionsLoader: Service {
    func load(complete: @escaping (Result<[Subscription], BogusError>) ->
     Void) {                                                             #3
         // ... load data. Always succeeds
        let subscriptions = [Subscription(), Subscription()]
        complete(Result(subscriptions))
    }
}
```

You made an empty enum that conforms to `Error` merely to please the compiler. But because `BogusError` has no cases, you can’t instantiate it, and Swift knows this. Once you call `load` on `SubscriptionsLoader` and retrieve the `Result`, you can match *only* on the `success` case, and Swift is smart enough to understand that you can *never* have a failure case. To emphasize, a `BogusError` can *never* be created, so you don’t need to match on this, as the following example shows.

##### Listing 11.20. Matching only on the success case

```
let subscriptionsLoader = SubscriptionsLoader()
subscriptionsLoader.load { (result: Result<[Subscription], BogusError>) in
    switch result {
    case .success(let subscriptions): print(subscriptions)
        // You don't need .failure                          #1
    }
}
```

This technique gives you compile-time elimination of cases to match on and can clean up your APIs and show clearer intent. But an official solution—the `Never` type—lets you get rid of `BogusError`.

##### THE NEVER TYPE

To please the compiler, you made a bogus error type that can’t be instantiated. Actually, such a type already exists in Swift and is called the `Never` type.

The `Never` type is a so-called *bottom type*; it tells the compiler that a certain code path can’t be reached. You may also find this mechanism in other programming languages, such as the `Nothing` type in Scala, or when a function in Rust returns an exclamation mark (`!`).

`Never` is a hidden type used by Swift to indicate impossible paths. For example, when a function calls a `fatalError`, it can return a `Never` type, indicating that returning something is an impossible path.

##### Listing 11.21. From the Swift source

```
func crashAndBurn() -> Never {                        #1
     fatalError("Something very, very bad happened")
}
```

If you look inside the Swift source, you can see that `Never` is nothing but an empty enum.

##### Listing 11.22. The `Never` type

```
public enum Never {}
```

In your situation, you can replace your `BogusError` with `Never` and get the same result. You do, however, need to make sure that `Never` implements `Error`.

##### Listing 11.23. Implementing `Never`

```
final class SubscriptionsLoader: Service {
    func load(complete: @escaping (Result<[Subscription], Never>) -> Void) {#1
         // ... load data. Always succeeds
        let subscriptions = [Subscription(), Subscription()]
        complete(Result.success(subscriptions))
    }
}
```

##### Note

From Swift 5 on, `Never` conforms to some protocols, like `Error`.

Notice that `Never` can also indicate that a service never succeeds. For instance, you can put the `Never` as the success case of a `Result`.

### 11.7. Closing thoughts

I hope that you can see the benefits of error handling with `Result`. You’ve seen how `Result` can give you compile-time insights into which error to expect. Along the way you took your `map` and `flatMap` knowledge and wrote code that pretended to be error-free, yet was carrying an error-context. Now you know how to apply monadic error handling.

Here’s a controversial thought: you can use the `Result` type for *all* the error handling in your project. You get more compile-time benefits, but at the price of more difficult programming. Error handling is more rigid with `Result`, but your code will be safer and stricter as a reward. And if you want to speed up your work a little, you can always create a `Result` type with the failure case constrained to the `Error` protocol.

### Summary

- Using the default way of `URLSession`’s data tasks is an error-prone way of error handling.
- `Result` is a good way to handle asynchronous error handling.
- `Result` has two generics and is a lot like `Optional`, but has a context of why something failed.
- `Result` is a compile-time safe way of error handling, and you can see which error to expect before running a program.
- By using `map`, `mapError`, `flatMap`, and `flatMapError`, you can cleanly chain transformations of your data while carrying an error context.
- Throwing functions can be converted to a `Result` via a special throwing initializer. This initializer allows you to mix and match two error throwing idioms.
- You can circumvent strict error handling by pinning the `Error` generic to `Error` itself.
- By pinning the `Error` generic to `Error` itself, you can mix multiple error types inside `Result`.
- You can use the `Never` type to indicate that a `Result` can’t have a `failure` case, or a `success` case.

### Answers

1. Using the techniques you’ve learned, try to connect to a real API. See if you can implement the FourSquare API ([http://mng.bz/nxVg](http://mng.bz/nxVg)) and obtain the venues JSON. You can register to receive free developer credentials.
1. See if you can use `map`, `mapError`, and even `flatMap` to transform the result, so that you call the completion handler only once.
1. The server can return an error, even if the call succeeds. For example, if you pass a latitude and longitude of 0, you get an `errorType` and `errorDetail` value in the `meta` key in the JSON. Try to make sure that this error is reflected in the `Result` type:

let clientId = "USE YOUR FOURSQUARE CLIENT ID"
let clientSecret = "USE YOUR FOURSQUARE CLIENT SECRET"
let apiVersion = "20180403"

func createURL(endpoint: String, parameters: [String: String]) -> URL? {
let baseURL = "https://api.foursquare.com/v2/"

// We convert the parameters dictionary in an array of URLQueryItems
var queryItems = parameters.map { pair -> URLQueryItem in
return URLQueryItem(name: pair.key, value: pair.value)
}

// Add default parameters to query
queryItems.append(URLQueryItem(name: "v", value: apiVersion))
queryItems.append(URLQueryItem(name: "client_id", value: clientId))
queryItems.append(URLQueryItem(name: "client_secret", value:
clientSecret))

var components = URLComponents(string: baseURL + endpoint)
components?.queryItems = queryItems
return components?.url
}

enum FourSquareError: Error {
case couldNotCreateURL
case networkError(Error)
case serverError(errorType: String, errorDetail: String)
case couldNotParseData
}

typealias JSON = [String: Any]

/// Search for venues with the FourSquare API
/// // https://developer.foursquare.com/docs/api/venues/search
///
/// - Parameters:
///   - latitude: latitude of a location
///   - longitude: longitude of a location
///   - completion: returns Result with either a [JSON] or potential
FourSquareError
func getVenues(latitude: Double, longitude: Double, completion: @escaping
(Result<[JSON], FourSquareError>) -> Void) {
let parameters = [
"ll": "\(latitude),\(longitude)",
"intent": "browse",
"radius": "250"
]

guard let url = createURL(endpoint: "venues/search", parameters:
parameters)
else {
completion(Result.failure(.couldNotCreateURL))
return
}
let task = URLSession.shared.dataTask(with: url) { data, response,
error in
let translatedError = error.map { FourSquareError.networkError($0) }
let result = Result<Data, FourSquareError>(value: data, error:
translatedError)
// Parsing Data to JSON
.flatMap { data in
guard
let rawJson = try? JSONSerialization.jsonObject(with:
data, options: []),
let json = rawJson as? JSON
else {
return Result.failure(.couldNotParseData)
}
return Result.success(json)
}
// Check for server errors
.flatMap { (json: JSON) -> Result<JSON, FourSquareError> in
if
let meta = json["meta"] as? JSON,
let errorType = meta["errorType"] as? String,
let errorDetail = meta["errorDetail"] as? String {
return Result.failure(.serverError(errorType: errorType,
errorDetail: errorDetail))
}
return Result.success(json)
}
// Extract venues
.flatMap { (json: JSON) -> Result<[JSON], FourSquareError> in
guard
let response = json["response"] as? JSON,
let venues = response["venues"] as? [JSON]
else {
return Result.failure(.couldNotParseData)
}
return Result.success(venues)
}
completion(result)
}

task.resume()
}

// Times square
let latitude = 40.758896
let longitude = -73.985130

// Calling getVenues

getVenues(latitude: latitude, longitude: longitude) { (result:
Result<[JSON], FourSquareError>) in
switch result {
case .success(let categories): print(categories)
case .failure(let error): print(error)
}
}

copy

1. Given the throwing functions, see if you can use them to transform `Result` in your FourSquare API:

enum FourSquareError: Error {
// ... snip
case unexpectedError(Error) // Adding new error for when conversion to
Result fails
}
func getVenues(latitude: Double, longitude: Double, completion:
@escaping (Result<[JSON], FourSquareError>) -> Void) {
// ... snip

let task = URLSession.shared.dataTask(with: url) { data, response,
error in
let translatedError = error.map { FourSquareError.networkError($0) }
let result = Result<Data, FourSquareError>(value: data, error:
translatedError)
// Parsing Data to JSON
.flatMap { data in
do {
return Result.success(try parseData(data))
} catch {
return Result.failure(.unexpectedError(error))
}
}
// Check for server errors
.flatMap { (json: JSON) -> Result<JSON, FourSquareError> in
do {
return Result.success(try validateResponse(json: json))
} catch {
return Result.failure(.unexpectedError(error))
}
}
// Extract venues
.flatMap { (json: JSON) -> Result<[JSON], FourSquareError> in
do {
return Result.success(try extractVenues(json: json))
} catch {
return Result.failure(.unexpectedError(error))
}
}

completion(result)
}

task.resume()
}

copy
