# Chapter 6. Effortless error handling

### ***This chapter covers***

- Error-handling best practices (and downsides)
- Keeping your application in a proper state when throwing
- How errors are propagated
- Adding information for customer-facing applications (and for troubleshooting)
- Bridging to `NSError`
- Making APIs easier to use without harming the integrity of an application

Error handling is an integral part of any software development and not Swift-centric. But how Swift treats error handling does impact the way you deliver code that is pleasant to use and respects problems that can arise in a system. In this chapter, you’ll elegantly throw and catch errors while walking the fine line between creating a useful API instead of a tedious one.

Error handling sounds simple in theory: throw some errors and catch them, and your program keeps running. But in reality, doing it correctly can get quite tricky. Swift also adds a unique flavor on top where it imposes rules, offers syntactic sugar, and compile-time checks to make sure you’re handling thrown errors.

Even though it’s a start to throw an error when something goes wrong, there are many subtleties. Moreover, once you do end up with an error, you need to know where the responsibility lies to handle (or ignore) the error. Do you propagate an error all the way up to the user, or can your program prevent errors altogether? Also, when *exactly* do you throw errors?

This chapter explores how Swift treats errors, but it won’t be a dry repeat of Apple’s documentation. Included are best practices related to keeping an application in a good state, a closer look at the downsides of error handling, and techniques on how to cleanly handle errors.

The first section goes over Swift errors and how to throw them. It also covers some best practices to keep your code in a predictable state when your functions start throwing errors.

Then, you’ll see how functions can propagate errors through an application. You’ll learn how you can add technical information for troubleshooting and localized information for end users, how to bridge to `NSError`, and more about centralizing error handling, all while implementing useful protocols.

To finish up the chapter, you’ll get a look at the downsides of throwing errors and how to negate them. You’ll also see how to make your APIs more pleasant to use while making sure that the system integrity stays intact.

### 6.1. Errors in Swift

Errors can come in all shapes and sizes. If you ask three developers what constitutes an error, you may get three different answers and will most likely hear differences between exceptions, errors, problems at runtime, or even blaming the user for ending up with a problem.

To start this chapter right, let’s classify errors into three categories so that we are on the same page:

- *Programming errors*—These errors could have been prevented by a programmer with a good night’s sleep—for example, arrays being out of bounds, division by zero, and integer overflows. Essentially, these are problems that you can fix on a code level. This is where unit tests and quality assurance can save you when you drop the ball. Usually, in Swift you can use checks such as `assert` to make sure your code acts as intended, and `precondition` to let others know that your API is called correctly. Assertions and preconditions are not what this chapter covers, however.
- *User errors*—A user error is when a user interacts with a system and fails to complete a task correctly, such as accidentally sending drunk selfies to your boss. User errors can be caused by not completely understanding a system, being distracted, or a clumsy user interface. Even though faulting a customer’s intelligence may be a fun pastime, you can blame a user error on the application itself, and you can prevent these issues with good design, clear communication, and shaping your software in such as way that it helps users reach their intent.
- *Errors revealed at runtime*—These errors could be an application being unable to create a file because the hard drive is full, a network request that fails, certificates that expire, JSON parsers that barf up after being fed wrong data, and many other things that can go wrong when an application is running. This last category of errors are recoverable (generally speaking) and are what this chapter focuses on.

In this section, you’ll see how Swift defines errors, what its weaknesses are, and how to catch them. Besides throwing errors, functions can do some extra housekeeping to make sure an application stays in a predictable state, which is another topic that you’ll explore in this section.

#### 6.1.1. The Error protocol

##### Join Me!

It’s more educational and fun if you can check out the code and follow along with the chapter. You can download the source code at [http://mng.bz/oN4j](http://mng.bz/oN4j).

Swift offers an `Error` protocol, which you can use to indicate that something went wrong in your application. Enums are well suited as errors because each case is mutually exclusive. You could, for instance, have a `ParseLocationError` enum with three options of failure.

##### Listing 6.1. An enum `Error`

```
12345enum ParseLocationError: Error {
    case invalidData
    case locationDoesNotExist
    case middleOfTheOcean
}
```

The `Error` protocol has no requirements and therefore doesn’t enforce any implementations, which also means that you don’t need to make every error an enum. As an example, you can also use other types, such as structs, to indicate something went wrong. Structs are less conventional to use but can be useful for when you want to add more rich data to an error.

You could, for instance, have an error struct that contains multiple errors and other properties.

##### Listing 6.2. A struct `Error`

```
struct MultipleParseLocationErrors: Error {
    let parsingErrors: [ParseLocationError]
    let isShownToUser: Bool
}
```

At first glance, enums are the way to go when composing errors, but know that you’re not restricted to using them for specific cases.

#### 6.1.2. Throwing errors

Errors exist to be thrown and handled. For instance, when a function fails to save a file, it can throw an error with a reason, such as the hard drive being full or lacking the rights to write to disk. When a function or method can throw an error, Swift requires the `throws` keyword in the function signature behind the closing parenthesis.

You could, for instance, turn two strings into a `Location` type containing `latitude` and `longitude` constants, as shown in the following code. A `parseLocation` function can then convert the strings by parsing them. If the parsing fails, the `parseLocation` function throws a `ParseLocation-Error.invalidData` error.

##### Listing 6.3. Parsing location strings

```
struct Location {                                                          #1
    let latitude: Double
    let longitude: Double
}

func parseLocation(_ latitude: String, _ longitude: String) throws ->
     Location {                                                            #2
    guard let latitude = Double(latitude), let longitude = Double(longitude)
 else {
        throw ParseLocationError.invalidData
    }

    return Location(latitude: latitude, longitude: longitude)
}

do {                                                                       #3
    try parseLocation("I am not a double", "4.899431")                     #4
 } catch {
    print(error) // invalidData                                            #5
 }
```

Because `parseLocation` is a throwing function, as indicated by the `throws` keyword, you need to call it with the `try` keyword. The compiler also forces callers of throwing functions to deal with the error somehow. Later on, you’ll get to see some techniques to make your APIs more pleasant for implementers.

#### 6.1.3. Swift doesn’t reveal errors

Another peculiar aspect of Swift’s error handling is that functions don’t reveal which errors they can throw. A function that is marked as `throws` could theoretically throw no errors or five million different errors, and you have no way of knowing this by looking at a function signature. Not having to list and handle each error explicitly gives you flexibility, but a significant shortcoming is that you can’t quickly know which errors a function can produce or propagate.

Functions don’t reveal their errors, so giving *some* information where possible is recommended. Luckily your friend *Quick Help* can jump in and help you provide more information about the errors you can throw. You can also use it to state when errors can be thrown, as shown in [listing 6.4](https://livebook.manning.com/book/swift-in-depth/chapter-6/ch06list4).

You can generate Quick Help documentation in Xcode by placing the cursor on a function and pressing Cmd-Alt-/ to generate a Quick Help template, including possible errors (see [figure 6.1](https://livebook.manning.com/book/swift-in-depth/chapter-6/ch06fig1)).

![Figure 6.1. A Quick Help informing about errors](https://drek4537l1klr.cloudfront.net/veen/Figures/06fig01_alt.jpg)

##### Listing 6.4. Adding error information to a function

```
/// Turns two strings with a latitude and longitude value into a Location
     type
///
/// - Parameters:
///   - latitude: A string containing a latitude value
///   - longitude: A string containing a longitude value
/// - Returns: A Location struct
/// - Throws: Will throw a ParseLocationError.invalidData if lat and long
 can't be converted to Double.                                           #1
 func parseLocation(_ latitude: String, _ longitude: String) throws ->
     Location {
    guard let latitude = Double(latitude), let longitude = Double(longitude)
     else {
        throw ParseLocationError.invalidData
    }

    return Location(latitude: latitude, longitude: longitude)
}
```

It’s a bandage, but adding this Quick Help gives the developer at least some information regarding the errors to expect.

#### 6.1.4. Keeping the environment in a predictable state

You’ve seen how a caller of a function deals with any possible errors your functions can throw. But throwing an error may not be enough. Sometimes a throwing function can go the extra mile and make sure that an application’s state remains the same once an error occurs.

##### Tip

Generally speaking, keeping a throwing function in a predictable state after it throws an error is a good habit to get into.

A predictable state prevents the environment from being in limbo between an error state and a sort-of-okay state. Keeping an application in a predictable state means that when a function or method throws an error, it should prevent, or undo, any changes that it has done to the environment or instance.

Let’s say you own a memory cache, and you want to store a value to this cache via a method. If this method throws an error, you probably expect your value *not* to be cached. If the function keeps the value in memory on an error, however, an external retry mechanism may even cause the system to run out of memory. The goal is to get the environment back to normal when throwing errors so the caller can retry or continue in other ways.

The easiest way to prevent throwing functions from mutating the environment is if functions don’t even change the environment in the first place. Making a function immutable is one way to achieve this. Immutable functions and methods have benefits in general, but even more so when a function is throwing.

If you look back at the `parseLocation` function, you see that it touches only the values that it gets passed, and it isn’t performing any changes to external values, meaning that there are no hidden side effects. Because `parseLocation` is immutable, it works predictably.

Let’s go over two more techniques to achieve a predictable state.

##### MUTATING TEMPORARY VALUES

A second way that you can keep your environment in a predictable state is by mutating a copy or temporary value and then saving the new state after the mutation completed without errors.

Consider the following `TodoList` type, which can store an array of strings. If a string is empty after trimming, however, the `append` method throws an error.

##### Listing 6.5. The `TodoList` that mutates state on errors

```
enum ListError: Error {
    case invalidValue
}

struct TodoList {

    private var values = [String]()

    mutating func append(strings: [String]) throws {
        for string in strings {
            let trimmedString = string.trimmingCharacters(in: .whitespacesAnd
 Newlines)

            if trimmedString.isEmpty {
                throw ListError.invalidValue         #1
             } else {
                values.append(trimmedString)         #2
             }
        }
    }

}
```

The problem is that after `append` throws an error, the type now has a half-filled state. The caller may assume everything is back to what it was and retry again later. But in the current state, the `TodoList` leaves some trailing information in its values.

Instead, you can consider mutating a temporary value, and only adding the final result to the actual `values` property after every iteration was successful. If the `append` method throws during an iteration, however, the new state is never saved, and the temporary value will be gone, keeping the `TodoList` in the same state as before an error is thrown.

##### Listing 6.6. `TodoList` works with temporary values

```
struct TodoList {

    private var values = [String]()

    mutating func append(strings: [String]) throws {
        var trimmedStrings = [String]()                       #1
        for string in strings {
            let trimmedString = string.trimmingCharacters(in: .whitespacesAnd
 Newlines)

            if trimmedString.isEmpty {
                throw ListError.invalidValue
            } else {
                trimmedStrings.append(trimmedString)          #2
            }
        }

        values.append(contentsOf: trimmedStrings)             #3
     }

}
```

##### RECOVERY CODE WITH DEFER

One way to recover from a throwing function is to *undo* mutations while being in the middle of an operation. Undoing mutating operations halfway tends to be rarer, but can be the only option you may have when you are writing data, such as files to a hard drive.

As an example, consider the following `writeToFiles` function that can write multiple files to multiple local URLs. The caveat, however, is that this function has an all-or-nothing requirement. If writing to one file fails, don’t write any files to disk. To keep the function in a predictable state if an error occurs, you need to write some cleanup code that removes written files after a function starts throwing errors.

You can use `defer` for a cleanup operation. A `defer` closure is executed *after* the function ends, regardless of whether the function is finished normally or via a thrown error. You can keep track of all saved files in the function, and then in the `defer` closure you can delete all saved files, but only if the number of saved files doesn’t match the number of paths you give to the function.

##### Listing 6.7. Recovering writing to files with `defer`

```
import Foundation

func writeToFiles(data: [URL: String]) throws {
    var storedUrls = [URL]()                                       #1
    defer {                                                        #2
        if storedUrls.count != data.count {                        #3
             for url in storedUrls {
                try! FileManager.default.removeItem(at: url)       #4
             }
        }
    }

    for (url, contents) in data {
        try contents.write(to: url, atomically: true, encoding:
 String.Encoding.utf8)                                          #5
         storedUrls.append(url)                                    #6
     }
}
```

Cleaning up after mutation has occurred can be tricky because you’re basically rewinding time. The `writeToFiles` function, for instance, removes all files on an error, but what if there were files before the new files were written? The `defer` block in `writeToFiles` would have to be more advanced to keep a more thorough record of what the *exact* state was before an error is thrown. When writing recovery code, be aware that keeping track of multiple scenarios can become increasingly complicated.

#### 6.1.5. Exercises

1. Can you name one or more downsides of how Swift handles errors, and how to compensate for them?
1. Can you name three ways to make sure throwing functions return to their original state after throwing errors?

### 6.2. Error propagation and catching

Swift offers four ways to handle an error: you can catch them, you can throw them higher up the stack (called *propagation*, or informally called “bubbling up”), you can turn them into optionals via the `try?` keyword, and you can assert that an error doesn’t happen via the `try!` keyword.

In this section, you’ll explore propagation and some techniques for clean catching. Shortly after, you’ll dive deeper into the `try?` and `try!` keywords.

#### 6.2.1. Propagating errors

My favorite way of dealing with problems is to give them to somebody else. Luckily you can do the same in Swift with errors that you receive: you propagate them by throwing them higher in the stack, like a one-sided game of hot potato.

![](https://drek4537l1klr.cloudfront.net/veen/Figures/06fig02.jpg)

Let’s use this section to create a sequence of functions calling each other to see how a lower-level function can propagate an error all the way to a higher-level function.

A trend when looking up cooking recipes is that you have to sift through someone’s personal story merely to get to the recipe and start cooking. A long intro helps search engines for the writer, but stripping all the fluff would be nice so you could extract a recipe straight away and get to cooking before stomachs start to growl.

As an example, you’ll create a `RecipeExtractor` struct (see [listing 6.8](https://livebook.manning.com/book/swift-in-depth/chapter-6/ch06list8)), which extracts a recipe from an HTML web page that it gets passed. `RecipeExtractor` uses smaller functions to perform this task. You’ll focus on the error propagation and not the implementation (see [figure 6.2](https://livebook.manning.com/book/swift-in-depth/chapter-6/ch06fig2)).

![Figure 6.2. Propagating an error](https://drek4537l1klr.cloudfront.net/veen/Figures/06fig03.jpg)

Propagation works via a method that can call a lower-level method, which in turn can also call lower-level methods. But an error can propagate all the way up again to the highest level if you allow it.

When the `extractRecipe` function is called on `RecipeExtractor`, it will call a lower-level function called `parseWebpage`, which in turn will call `parseIngredients` and `parseSteps`. Both `parseIngredients` and `parseSteps` can throw an error, which `parseWebpage` will receive and propagate back up to the `extractRecipe` function as shown in the following code.

##### Listing 6.8. The `RecipeExtractor`

```
struct Recipe {                                                      #1
    let ingredients: [String]
    let steps: [String]
}

enum ParseRecipeError: Error {                                       #2
    case parseError
    case noRecipeDetected
    case noIngredientsDetected
}

struct RecipeExtractor {

    let html: String

    func extractRecipe() -> Recipe? {                                #3
        do {                                                         #4
             return try parseWebpage(html)
        } catch {
            print("Could not parse recipe")
            return nil
        }
    }

    private func parseWebpage(_ html: String) throws -> Recipe {
        let ingredients = try parseIngredients(html)                #5
        let steps = try parseSteps(html)                            #5
        return Recipe(ingredients: ingredients, steps: steps)
    }
    private func parseIngredients(_ html: String) throws -> [String] {
        // ... Parsing happens here

        // .. Unless an error is thrown
        throw ParseRecipeError.noIngredientsDetected
    }
    private func parseSteps(_ html: String) throws -> [String] {
        // ... Parsing happens here

        // .. Unless an error is thrown
        throw ParseRecipeError.noRecipeDetected
    }

}
```

Getting a recipe may fail for multiple reasons; perhaps the HTML file doesn’t contain a recipe at all, or the extractor fails to obtain the ingredients. The lower-level functions `parseIngredients` and `parseSteps` can, therefore, throw an error. Since their parent function `parseWebpage` doesn’t know how to handle the errors, it propagates the error back up again to the `extractRecipe` function of the struct by using the `try` keyword. Since `parseWebpage` propagates an error up again, it also contains the `throws` keyword in its function signature.

Notice how the `extractRecipe` method has a `catch` clause without specifically matching on an error; this way the `extractRecipe` catches all possibly thrown errors. If the `catch` clause were matching on specific errors, theoretically some errors would not be caught and would have to propagate up even higher, making the `extract-Recipe` function throwing as well.

#### 6.2.2. Adding technical details for troubleshooting

Near where the error occurs, plenty of context surrounds it. You have the environment at your hands at the exact point in time; you know precisely which action failed and what the state is of each variable in the proximity of the error. When an error gets propagated up, this exact state may get lost, losing some useful information to handle the error.

When logging an error to help the troubleshooting process, adding some useful information for developers can be beneficial, such as where the parsing of recipes failed, for instance. After you’ve added this extra information, you can pattern match on an error and extract the information when troubleshooting.

For instance, as shown in the following, you can add a `symbol` and `line` property on the `parseError` case of `ParseRecipeError`, to give a little more info about where the parsing went wrong.

##### Listing 6.9. Adding more information to the `ParseRecipeError`

```
enum ParseRecipeError: Error {
    case parseError(line: Int, symbol: String)       #1
    case noRecipeDetected
    case noIngredientsDetected
}
```

This way, you can pattern match against the cases more explicitly when troubleshooting. Notice how you still keep a `catch` clause in there, to prevent `extractRecipes` from becoming a throwing function.

##### Listing 6.10. Matching on a specific error

```
struct RecipeExtractor {

    let html: String

    func extractRecipe() -> Recipe? {
        do {
            return try parseWebpage(html)
        } catch let ParseRecipeError.parseError(line, symbol) {            #1
            print("Parsing failed at line: \(line) and symbol: \(symbol)")
            return nil
        } catch {
            print("Could not parse recipe")
            return nil
        }
    }

    // ... snip
}
```

##### ADDING USER-READABLE INFORMATION

Now that the technical information is there, you can use it to translate the data to a user-readable error. The reason you don’t pass a human-readable string to an error is that with technical details you can make a distinction between a human-readable error and detailed technical information for a developer.

One approach to get human-readable information is to incorporate the `Localized-Error` protocol. When adhering to this protocol, you indicate that the error follows certain conventions and contains user-readable information. Conforming to `Localized-Error` tells an error handler that information is present that it can confidently show the user without needing to do some conversion.

To incorporate the `LocalizedError` protocol, you can implement a few properties, but they all have a default value of nil so you can tailor the error to which properties you would like to implement. An example is given in [listing 6.11](https://livebook.manning.com/book/swift-in-depth/chapter-6/ch06list11). In this scenario, you are choosing to incorporate the `errorDescription` property, which can give more information about the error itself. You are also adding the `failureReason` property, which helps explain why an error failed. You are also incorporating a `recovery-Suggestion` to help users with an action of what they should do, which in this case is to try a different recipe page. On OS X, you could also include the `helpAnchor` property, which you can use to link to Apple’s Help Viewer, but this property isn’t necessary in this example.

Since the strings are user-facing, consider returning localized strings instead of regular strings, so that the messages may fit the user’s locale.

##### Listing 6.11. Implementing `LocalizedError`

```
extension ParseRecipeError: LocalizedError {                               #1
     var errorDescription: String? {                                       #2
         switch self {
         case .parseError:
             return NSLocalizedString("The HTML file had unexpected symbols.",
                                     comment: "Parsing error reason
 unexpected symbols")
         case .noIngredientsDetected:
             return NSLocalizedString("No ingredients were detected.",
                                     comment: "Parsing error no ingredients.")
         case .noRecipeDetected:
             return NSLocalizedString("No recipe was detected.",
                                     comment: "Parsing error no recipe.")
         }
    }

    var failureReason: String? {                                           #3
         switch self {
         case let .parseError(line: line, symbol: symbol):
             return String(format: NSLocalizedString("Parsing data failed at
 line: %i and symbol: %@",
                                                    comment: "Parsing error
 line symbol"), line, symbol)
         case .noIngredientsDetected:
             return NSLocalizedString("The recipe seems to be missing its
 ingredients.",
                                     comment: "Parsing error reason missing
 ingredients.")
         case .noRecipeDetected:
             return NSLocalizedString("The recipe seems to be missing a
 recipe.",
                                     comment: "Parsing error reason missing
 recipe.")
         }
    }

    var recoverySuggestion: String? {                                      #4
         return "Please try a different recipe."
    }

}
```

All the properties are optional. Generally speaking, implementing `errorDescription` and `recoverySuggestion` should be enough.

Once a human-readable error is in place, you can pass it safely to anything user-facing, such as a `UIAlert` on iOS, printing to the command line, or a notification on OS X.

##### BRIDGING TO NSError

With a little effort, you can implement the `CustomNSError` protocol, which helps to bridge a `Swift.Error` to `NSError` in case you’re calling Objective-C from Swift. The `CustomNSError` expects three properties: a static `errorDomain`, an `errorCode` integer, and an `errorUserInfo` dictionary.

The `errorDomain` and `errorCode` are something you need to decide. For convenience, you can fill up the `errorUserInfo` with values you predefined (and fall back on empty values if they are nil).

##### Listing 6.12. Implementing `NSError`

```
extension ParseRecipeError: CustomNSError {
    static var errorDomain: String { return "com.recipeextractor" }         #1
 
    var errorCode: Int { return 300 }                                       #2
 
    var errorUserInfo: [String: Any] {
        return [
            NSLocalizedDescriptionKey: errorDescription ?? "",              #3
             NSLocalizedFailureReasonErrorKey: failureReason ?? "",         #3
             NSLocalizedRecoverySuggestionErrorKey: recoverySuggestion ?? ""#3
         ]
    }
}

let nsError: NSError = ParseRecipeError.parseError(line: 3, symbol: "#") as
     NSError                                                                #4
 print(nsError) // Error Domain=com.recipeextractor Code=300 "Parsing data
 failed at line: 3 and symbol: #" UserInfo={NSLocalizedFailureReason=The 
 HTML file had unexpected symbols., NSLocalizedRecoverySuggestion=Please 
 try a different recipe., NSLocalizedDescription=Parsing data failed at 
 line: 3 and symbol: #}
```

Without supplying this information, converting an `Error` to an `NSError` means that the error doesn’t have the proper `code` and `domain` information. Adopting the `Custom-NSError` gives you tight control over this conversion.

#### 6.2.3. Centralizing error handling

A lower-level function can sometimes solve an error itself—such as a retry mechanism when passing data—but usually, a lower-level function would propagate an error up the stack back to the call-site because the lower-level function is missing the context on how to handle an error. For example, if an embedded framework fails to save a file and throws an error, it wouldn’t know that an iOS application implementing this framework would want to show a `UIAlertController` dialog box, or that a Linux command-line tool would want to log to stderr.

A useful practice when handling propagated errors is to centralize the error-handling. Imagine that when you catch an error, you want to show an error dialog in an iOS or OS X application. If you have error-handling code in dozens of places in your application, making changes is tough, which makes your application resistant to change. To remedy a rigid error-handling setup, you can opt to use a central place to present the errors. When catching code, you can pass the error to an error handler that knows what to do with it, such as presenting a dialog to the user, submitting the error to a diagnostics systems, logging the error to stderr, you name it.

As an example, you can have one error handler that has the same `handleError` function multiple times via function overloads. Thanks to the function overloads, the `ErrorHandler` can get granular control over which error is ready to be presented to the user, and which errors need to fall back on a generic message.

##### Listing 6.13. An `ErrorHandler` with function overloads

```
struct ErrorHandler {

    static let `default` = ErrorHandler()                    #1
 
    let genericMessage = "Sorry! Something went wrong"       #2
 
    func handleError(_ error: Error) {                       #3
         presentToUser(message: genericMessage)
    }

    func handleError(_ error: LocalizedError) {              #4
         if let errorDescription = error.errorDescription {
            presentToUser(message: errorDescription)
        } else {
            presentToUser(message: genericMessage)
        }
    }

    func presentToUser(message: String) {                    #5
         // Not depicted: Show alert dialog in iOS or OS X, or print to
 stderror.
        print(message) // Now you log the error to console.
    }

}
```

##### IMPLEMENTING THE CENTRALIZED ERROR HANDLER

Let’s see how you can best call the centralized error handler. Since you are centralizing error handling, the `RecipeExtractor` doesn’t have to both return an optional and handle errors. If the caller also treats the optional as an error, you may end up with double the error handling. Instead, the `RecipeExtractor` can return a regular `Recipe` (non-optional) and pass the error to the caller as shown in the following code. Then the caller can pass any error to the central error handler.

##### Listing 6.14. `RecipeExtractor` becomes throwing

```
struct RecipeExtractor {

    let html: String

    func extractRecipe() throws -> Recipe {                    #1
         return try parseHTML(html)                            #2
    }
    private func parseHTML(_ html: String) throws -> Recipe {
        let ingredients = try extractIngredients(html)
        let steps = try extractSteps(html)
        return Recipe(ingredients: ingredients, steps: steps)
    }

    // ... snip

}

let html = ... // You can obtain html from a source
let recipeExtractor = RecipeExtractor(html: html)

do {
    let recipe = try recipeExtractor.extractRecipe()           #3
 } catch  {
    ErrorHandler.default.handleError(error)                    #3
 }
```

If you centralize error handling, you separate error handling from code that focuses on the happy path, and you keep an application in a good state. You not only prevent duplication, but changing the way you treat errors is also easier. You could, for instance, decide to show errors in a different way—such as a notification instead of a dialog box—and only need to change this in a single location.

The tricky part is that you can now have one large error-handling type with the risk of it being giant and complicated. Depending on the needs and size of your application, you can choose to split up this type into smaller handlers that hook into the large error handler. Each smaller handler can then specialize in handling specific errors.

#### 6.2.4. Exercises

1. What’s the downside of passing messages for the user inside an error?
1. The following code does not compile. What two changes to `loadFile` can you make to make the code compile (without resorting to `try?` and `try!`)?

enum LoadError {
case couldntLoadFile
}

func loadFile(name: String) -> Data? {
let url = playgroundSharedDataDirectory.appendingPathComponent(name)
do {
return try Data(contentsOf: url)
} catch let error as LoadError {
print("Can't load file named \(name)")
return nil
}
}

copy

### 6.3. Delivering pleasant APIs

APIs that throw more often than a major league baseball pitcher are not fun to work with in an application. When APIs are trigger-happy about throwing errors, implementing them can become a nuisance. The burden is placed on the developer to handle these errors. Developers may start to catch all errors in one big net and treat them all the same or let low-level errors propagate down to a customer who doesn’t always know what to do with them. Sometimes errors are a nuisance because it may not be apparent to the developer what to do with each error. Alternatively, developers may catch errors with a `//` `TODO:` `Implement` comment that lives forever, swallowing both small and severe errors at the same time, leaving critical issues unnoticed.

Ideally speaking, each error gets the utmost care. But in the real world, deadlines need to be met, features need to be launched, and project managers need to be reassured. Error handling can feel like an obstacle that slows you down, which sometimes results in developers taking the easy road.

On top of that, the way Swift treats errors is that you can’t know for sure what errors a function throws. Sure, with some documentation you can communicate which errors to expect from a function or method. But in my experience, having 100% up-to-date documentation can be as common as spotting the Loch Ness monster. Functions start throwing new errors or stop throwing several errors altogether, and chances are you may miss an error or two over time.

APIs are quicker and easier to implement if they don’t throw often. But you have to make sure that you don’t compromise the quality of an application. With the downsides of error handling in mind, let’s go over some techniques to make your APIs friendlier and easier to implement, while still paying attention to problems that may arise in your code.

#### 6.3.1. Capturing validity within a type

You can diminish the amount of error handling you need to do by capturing validity within a type.

For instance, a first attempt to validate a phone number is to use a `validatePhoneNumber` function, and then continuously use it whenever it’s needed. Although having a `validatePhoneNumber` function isn’t wrong, you’ll quickly discover how to improve it in the next listing.

##### Listing 6.15. Validating a phone number

```
enum ValidationError: Error {
    case noEmptyValueAllowed
    case invalidPhoneNumber
}
func validatePhoneNumber(_ text: String) throws {
    guard !text.isEmpty else {
        throw ValidationError.noEmptyValueAllowed                    #1
    }

    let pattern = "^(\\([0-9]{3}\\) |[0-9]{3}-)[0-9]{3}-[0-9]{4}$"
    if text.range(of: pattern, options: .regularExpression, range:
 nil, locale: nil) == nil {
        throw ValidationError.invalidPhoneNumber                     #1
    }
}

do {
    try validatePhoneNumber("(123) 123-1234")                        #2
    print("Phonenumber is valid")
} catch {
    print(error)
}
```

With this approach you may end up validating the same string multiple times: for example, once when entering a form, once more before making an API call, and again when updating a profile. In these recurring places, you put the burden on a developer to handle an error.

Instead, you can capture the validity of a phone number within a type by creating a new type, even though the phone number is only a single string, as shown in the following. You create a `Phone-Number` type and give it a throwable initializer that validates the phone number for you. This initializer either throws an error or returns a proper `PhoneNumber` type, so you can catch any errors right when you create the type.

##### Listing 6.16. The `PhoneNumber` type

```
struct PhoneNumber {

    let contents: String

    init(_ text: String) throws {                                 #1
         guard !text.isEmpty else {
            throw ValidationError.noEmptyValueAllowed
        }

        let pattern = "^(\\([0-9]{3}\\) |[0-9]{3}-)[0-9]{3}-[0-9]{4}$"
        if text.range(of: pattern, options: .regularExpression, range: nil,
     locale: nil) == nil {
            throw ValidationError.invalidPhoneNumber
        }
        self.contents = text                                     #2
     }
}
do {
    let phoneNumber = try PhoneNumber("(123) 123-1234")          #3
    print(phoneNumber.contents) // (123) 123-1234                #4
 } catch {
    print(error)
}
```

After you obtain a `PhoneNumber`, you can safely pass it around your application with the confidence that a specific phone number is valid and without having to catch errors whenever you want to get the phone number’s value. Your methods can accept a `PhoneNumber` type from here on out, and just by looking at the method signatures you know that you’re dealing with a valid phone number.

#### 6.3.2. try?

You can prevent propagation in other ways as well. If you create a `PhoneNumber` type, you can treat it as an optional instead so that you can avoid an error from propagating higher up.

Once a function is a throwing function, but you’re not interested in the reasons for failure, you can consider turning the result of the throwing function into an optional via the `try?` keyword, as shown here.

##### Listing 6.17. Applying the `try?` keyword

```
let phoneNumber = try? PhoneNumber("(123) 123-1234")
print(phoneNumber) // Optional(PhoneNumber(contents: "(123) 123-1234"))
```

By using `try?`, you stop error propagation. You can use `try?` to reduce various reasons for errors into a single optional. In this case, a `PhoneNumber` could not be created for multiple reasons, and with `try?` you indicate that you’re not interested in the reason or error, just that the creation succeeded or not.

#### 6.3.3. try!

You can assert that an error won’t occur. In that case, like when you force unwrap, either you’re right or you get a crash.

If you were to use `try!` to create a `PhoneNumber`, you assert that the creation won’t fail.

##### Listing 6.18. Applying the `try!` keyword.

```
let phoneNumber = try! PhoneNumber("(123) 123-1234")
print(phoneNumber) // PhoneNumber(contents: "(123) 123-1234")
```

The `try!` keyword saves you from unwrapping an optional. But if you’re wrong, the application crashes:

```
let phoneNumber = try! PhoneNumber("Not a phone number") // Crash
```

As with force unwrapping, only use `try!` when you know better than the compiler. Otherwise, you’re playing Russian Roulette.

#### 6.3.4. Returning optionals

Optionals are a way of error handling: either there is a value, or there is not. You can use optionals to signal something is wrong, which is an elegant alternative to throwing errors.

Let’s say you want to load a file from Swift’s playgrounds, which can fail, but the reason for failure doesn’t matter. To remove the burden of error handling for your callers, you can choose to make your function return an optional `Data` value on failure.

##### Listing 6.19. Returning an optional

```
func loadFile(name: String) -> Data? {                                     #1
    let url = playgroundSharedDataDirectory.appendingPathComponent(name)
    return try? Data(contentsOf: url)                                      #2
 }
```

If a function has a single reason for failure and the function returns a value, a rule of thumb is to return an optional instead of throwing an error. If a cause of failure does matter, you can choose to throw an error.

If you’re unsure of what a caller is interested in, and you don’t mind introducing error types, you can still throw an error. The caller can always decide to turn an error into an optional if needed via the `try?` keyword.

#### 6.3.5. Exercise

1. Can you name at least three ways to make throwing APIs easier for developers to use?

### 6.4. Closing thoughts

As you’ve seen, error handling may sound simple on paper, but applying best practices when dealing with errors is important. One of the worst cases of error handling is that errors get swallowed or ignored. By applying best practices in this chapter, I hope that you’ve acquired a good arsenal of techniques to combat—and adequately handle—these errors. If you have a taste for more error-handling techniques, you’re in luck—[chapter 11](https://livebook.manning.com/book/swift-in-depth/chapter-11/ch11) covers errors in an asynchronous environment.

### Summary

- Even though errors are usually enums, any type can implement the `Error` protocol.
- Inferring from a function which errors it throws isn’t possible, but you can use Quick Help to soften the pain.
- Keep throwing code in a predictable state for when an error occurs. You can achieve a predictable state via immutable functions, working with copies or temporary values, and using `defer` to undo any mutations that may occur before an error is thrown.
- You can handle errors four ways: `do` `catch`, `try?` and `try!`, and propagating them higher in the stack.
- If a function doesn’t catch all errors, any error that occurs gets propagated higher up the stack.
- An error can contain technical information to help to troubleshoot. User-facing messages can be deduced from the technical information, by implementing the `LocalizedError` protocol.
- By implementing the `CustomNSError` you can bridge an error to `NSError`.
- A good practice for handling errors is via centralized error handling. With centralized error handling, you can easily change how to handle errors.
- You can prevent throwing errors by turning them into optionals via the `try?` keyword.
- If you’re certain that an error won’t occur, you can turn to retrieve a value from a throwing function with the `try!` keyword, with the risk of a crashing application.
- If there is a single reason for failure, consider returning an optional instead of creating a throwing function.
- A good practice is to capture validity in a type. Instead of having a throwing function you repeatedly use, create a type with a throwing initializer and pass this type around with the confidence of knowing that the type is validated.

### Answers

1. Can you name one or more downsides of how Swift handles errors, and how to compensate for them? Functions are marked as throwing, so it places the burden on the developer to handle them. But functions don’t reveal which errors are thrown. You can add a Quick Help annotation to functions to share which errors can be thrown.
1. Can you name three ways to make sure throwing functions return to their original state after throwing errors?

- - Use immutable functions.
- - Work on copies or temporary values.
- - Use `defer` to reverse mutation that happened before an error is thrown.

1. What’s the downside of passing messages for the user inside an error? Because then it’s harder to differentiate between technical information for debugging and information to display to the user.
1. What two changes to `loadFile` can you make to make the code compile? (without resorting to `try!` and `try?`) Make `loadFile` catch all errors and not just a specific one. Or make `loadFile` throwing to repropagate the error.
1. Can you name at least three ways to make throwing APIs easier for developers to use?

- - Capture an error when creating a type, so an error is handled only on the creation of a type and not passing of a value.
- - Return an optional instead of throwing an error when there is a single failing reason.
- - Convert an error into an optional with the `try?` keyword and return the optional.
- - Prevent propagation with the `try!` keyword.
