# Chapter 4. Making optionals second nature

### ***This chapter covers***

- Best practices related to optionals
- Handling multiple optionals with guards
- Properly dealing with optional strings versus empty strings
- Juggling various optionals at once
- Falling back to default values using the nil-coalescing operator
- Simplifying optional enums
- Dealing with optional Booleans in multiple ways
- Digging deep into values with optional chaining
- Force unwrapping guidelines
- Taming implicitly unwrapped optionals

This chapter helps you acquire many tools to take you from optional frustration to *optional nirvana* while applying best practices along the way. Optionals are so pervasive in Swift that we spend some extra pages on them to leave no stone unturned. Even if you are adept at handling optionals, go through this chapter and fill in any knowledge gaps.

The chapter starts with what optionals are and how Swift helps you by adding syntactic sugar. Then we go over style tips paired with bite-sized examples that you regularly encounter in Swift. After that, you’ll see how to stop optionals from propagating inside a method via a guard. We also cover how to decide on returning empty strings versus optional strings. Next, we show how to get more granular control over multiple optionals by pattern matching on them. Then, you’ll see that you can fall back on default values with the help of the *nil-coalescing operator*.

Once you encounter optionals containing other optionals, you’ll see how optional chaining can be used to dig deeper to reach nested values. Then we show how to pattern match on optional enums. You’ll be able to shed some weight off your switch statements after reading this section. You’ll also see how optional Booleans can be a bit awkward; we show how to correctly handle them, depending on your needs.

*Force unwrapping*, a technique to bypass the safety that optionals offer, gets some personal attention. This section shares when it is acceptable to force unwrap optionals. You’ll also see how you can supply more information if your application unfortunately crashes. This section has plenty of heuristics that you can use to improve your code. Following force unwrapping, we cover implicitly unwrapped optionals, which are optionals that have different behavior depending on their context. You’ll explicitly see how to handle them properly.

This chapter is definitely “big-boned.” On top of that, optionals keep returning to other chapters with nifty tips and tricks, such as applying `map` and `flatMap` on optionals, and `compactMap` on arrays with optionals. The goal is that at the end of this chapter you’ll feel adept and confident in being able to handle any scenario involving optionals.

### 4.1. The purpose of optionals

![](https://drek4537l1klr.cloudfront.net/veen/Figures/04fig01.jpg)

Simply put, an optional is a “box” that *does* or *does not* have a value. You may have heard of optionals, such as the `Option` type in Rust or Scala, or the `Maybe` type in Haskell.

Optionals help you prevent crashes when a value is empty; they do so by asking you to explicitly handle each case where a variable or constant could be nil. An optional value needs to be *unwrapped* to get the value out. If there is a value, a particular piece of code can run. If there isn’t a value present, the code takes a different path.

Thanks to optionals you’ll always know at compile time if a value can be nil, which is a luxury not found in specific other languages. As a case in point, if you obtain a nil value in `Ruby` and don’t check for it, you may get a runtime error. The downside of handling optionals is that it may slow you down and cause some frustration up front because Swift makes you explicitly handle each optional when you want its value. But as a reward, you gain safer code in return.

With this book’s help, you’ll become so accustomed to optionals that you’ll be able to handle them quickly and comfortably. With enough tools under your belt, you may find optionals are pleasant to work with, so let’s get started!

### 4.2. Clean optional unwrapping

In this section, you’ll see how optionals are represented in code and how to unwrap them in multiple ways.

You’ll start by modeling a customer model for the backend of a fictional web store called *The Mayonnaise Depot*, catering to all your mayonnaise needs.

##### Join Me!

It’s more educational and fun if you can check out the code and follow along with the chapter. You can download the source code at [http://mng.bz/6jO5](http://mng.bz/6jO5).

This `Customer` struct holds a customer’s ID, email, name, and current balance, which the web store can use to do business with a customer. For demonstration purposes, we left out some other important properties, such as an address and payment information.

The web store is quite lenient and allows for a customer to leave out their first and last name when ordering delicious mayonnaise; this makes it easier for customers to order mayonnaise. You represent these values as optional `firstName` and `lastName` inside the struct as shown in the following.

##### Listing 4.1. The `Customer` struct

```
struct Customer {
    let id: String                         #1
    let email: String
    let balance: Int // amount in cents
    let firstName: String?                 #2
    let lastName: String?
}
```

Optionals are variables or constants denoted by a `?`. But if you take a closer look, you’ll see that an optional is an enum that may or may not contain a value. Let’s look at the `Optional` type inside the Swift source code.

##### Listing 4.2. Optionals are an enum

```
// Details omitted from Swift source.
public enum Optional<Wrapped> {
  case none
  case some(Wrapped)
}
```

The `Wrapped` type is a *generic type* that represents the value inside an optional. If it has a value, it is wrapped inside the `some` case; if no value is present, the optional has a `none` case for that.

Swift adds some syntactic sugar to the optional syntax because without this sugar you would be writing your `Customer` struct as follows.

##### Listing 4.3. Optionals without syntactic sugar

```
struct Customer {
    let id: String
    let email: String
    let balance: Int
    let firstName: Optional<String>     #1
    let lastName: Optional<String>      #2
}
```

##### Note

Writing an optional explicitly is still legit Swift code and compiles just fine, but it isn’t idiomatic Swift (so only use this knowledge to win pub quizzes).

#### 4.2.1. Matching on optionals

In general, you unwrap an optional using `if` `let`, such as unwrapping a customer’s `firstName` property.

##### Listing 4.4. Unwrapping via `if let`

```
let customer = Customer(id: "30", email: "mayolover@gmail.com",
 firstName: "Jake", lastName: "Freemason", balance: 300)

print(customer.firstName) // Optional("Jake")         #1
if let firstName = customer.firstName {
    print(firstName) // "Jake"                        #2
}
```

But again, without Swift’s syntactic sugar you’d be matching on optionals everywhere with switch statements. Matching on an optional is demonstrated in [figure 4.1](https://livebook.manning.com/book/swift-in-depth/chapter-4/ch04fig1), and it comes in handy later in this chapter—for example, when you want to combine unwrapping with pattern matching.

![Figure 4.1. Matching on an optional](https://drek4537l1klr.cloudfront.net/veen/Figures/04fig02_alt.jpg)

Swift agrees that you can pattern match on optionals; it even offers a little syntactic sugar for that.

You can omit the `.some` and `.none` cases from the example below and replace them with `let` `name?` and `nil`, as shown in [listing 4.5](https://livebook.manning.com/book/swift-in-depth/chapter-4/ch04list5).

##### Listing 4.5. Matching on optional with syntactic sugar

```
switch customer.firstName {
 case let name?: print("First name is \(name)")           #1
 case nil: print("Customer didn't enter a first name")    #2
}
```

This code does the same as before, just written a bit differently.

Luckily, Swift offers plenty of syntactic sugar to save us all some typing. Still, it’s good to know that optionals are enums at heart once you stumble upon more complicated or esoteric unwrapping techniques.

#### 4.2.2. Unwrapping techniques

You can combine the unwrapping of multiple optionals. Combining them instead of indenting helps keep indentation lower. For instance, you can handle two optionals at once by unwrapping both the `firstName` and the `lastName` of a `Customer`, as shown here.

##### Listing 4.6. Combining optional unwrapping

```
if let firstName = customer.firstName, let lastName = customer.lastName {
    print("Customer's full name is \(firstName) \(lastName)")
}
```

Unwrapping optionals doesn’t have to be the only action inside an `if` statement; you can combine `if` `let` statements with Booleans.

For example, you can unwrap a customer’s `firstName` and combine it with a Boolean, such as the `balance` property, to write a customized message.

##### Listing 4.7. Combining a Boolean with an optional

```
if let firstName = customer.firstName, customer.balance > 0 {
    let welcomeMessage = "Dear \(firstName), you have money on your account,
     want to spend it on mayonnaise?"
}
```

But it doesn’t have to stop at Booleans. You can also pattern match while you unwrap an optional. For example, you can pattern match on `balance` as well.

In the following example, you’ll create a notification for the customer when their `balance` (indicated by cents) has a value that falls inside a range between 4,500 and 5,000 cents, which would be 45 to 50 dollars.

##### Listing 4.8. Combining pattern matching with optional unwrapping

```
if let firstName = customer.firstName, 4500..<5000 ~= customer.balance {
    let notification = "Dear \(firstName), you are getting close to afford
     our $50 tub!"
}
```

Embellishing `if` statements with other actions can clean up your code. You can separate Boolean checks and pattern matching from optional unwrapping, but then you’d usually end up with nested if statements and sometimes multiple else blocks.

#### 4.2.3. When you’re not interested in a value

Using `if` `let` to unwrap optionals is great for when you’re interested in a value. But if you want to perform actions when a value is nil or not relevant, you can use a traditional nil check as other languages do.

In the next example, you’d like to know whether a customer has a full name filled in, but you aren’t interested in what this name may be. You can again use the “don’t care” wildcard operator to bind the unwrapped values to nothing.

##### Listing 4.9. Underscore use

```
if
  let _ = customer.firstName,
  let _ = customer.lastName {
  print("The customer entered his full name")
}
```

Alternatively, you can use nil checks for the same effect.

##### Listing 4.10. Nil checking optionals

```
if
  customer.firstName != nil,
  customer.lastName != nil {
  print("The customer entered his full name")
}
```

You can also perform actions when a value is empty.

Next, you check if a customer has a name set, without being interested in what this name may be.

##### Listing 4.11. When an optional is nil

```
if customer.firstName == nil,
   customer.lastName == nil {
   print("The customer has not supplied a name.")
}
```

Some may argue that nil checking isn’t “Swifty.” But you can find nil checks inside the Swift source code. Feel free to use nil checks if you think it helps readability. Clarity is more important than style.

### 4.3. Variable shadowing

At first, you may be tempted to come up with unique names when unwrapped (for instance, having a constant `firstName` and naming the unwrapped constant `unwrappedFirstName`), but this is not necessary.

You can give the unwrapped value the same name as the optional in a different scope; this is a technique called *variable shadowing*. Let’s see how this looks.

#### 4.3.1. Implementing CustomStringConvertible

To demonstrate variable shadowing, you’ll create a method that uses the optional properties of `Customer`. Let’s make `Customer` conform to the `CustomStringConvertible` protocol so that you can demonstrate this.

By making `Customer` adhere to the `CustomStringConvertible` protocol, you indicate that it prints a custom representation in print statements. Conforming to this protocol forces you to implement the `description` property.

##### Listing 4.12. Conforming to the `CustomStringConvertible` protocol

```
extension Customer: CustomStringConvertible {                         #1
     var description: String {
        var customDescription: String = "\(id), \(email)"

        if let firstName = firstName {                                #2
             customDescription += ", \(firstName)"                    #3
        }

        if let lastName = lastName {                                  #4
             customDescription += " \(lastName)"                      #5
        }

        return customDescription
    }
}
let customer = Customer(id: "30", email: "mayolover@gmail.com",
 firstName: "Jake", lastName: "Freemason", balance: 300)

print(customer) // 30, mayolover@gmail.com, Jake Freemason            #6
```

This example shows how both `firstName` and `lastName` were unwrapped using variable shadowing, preventing you from coming up with special names. At first, variable shadowing may look confusing, but once you’ve been handling optionals for a while, you can be assured that it is nice to read.

### 4.4. When optionals are prohibited

Let’s see how you handle multiple optionals when nil values aren’t usable. When The Mayonnaise Depot web store receives an order, customers get a confirmation message sent by email, which needs to be created by the backend. This message looks as follows.

##### Listing 4.13. Confirmation message

```
Dear Jeff,
Thank you for ordering the economy size party tub!
Your order will be delivered tomorrow.

Kind regards,
The Mayonnaise Depot
```

The function helps create a confirmation message by accepting a customer’s name and the product that the customer ordered.

##### Listing 4.14. An order confirmation message

```
func createConfirmationMessage(name: String, product: String) -> String {
    return """                                                             #1
     Dear \(name),                                                         #2
     Thank you for ordering the \(product)!
     Your order will be delivered tomorrow.

     Kind regards,
     The Mayonnaise Depot
     """
}

let confirmationMessage = createConfirmationMessage(name: "Jeff", product:
    "economy size party tub")                                             #3
```

To get the customer’s name, first decide on the name to display. Because both `firstName` and `lastName` are optional, you want to make sure you have these values to display in an email.

#### 4.4.1. Adding a computed property

You’re going to introduce a computed property to supply a valid customer name. You’ll call this property `displayName`. Its goal is to help display a customer’s name for use in emails, web pages, and so on.

You can use a guard to make sure that all properties have a value; if not, you return an empty string. But you’ll quickly see a better solution than returning an empty string, as shown in this listing.

##### Listing 4.15. The `Customer` struct

```
struct Customer {
    let id: String
    let email: String
    let firstName: String?
    let lastName: String?

    var displayName: String {
      guard let firstName = firstName, let lastName = lastName else {   #1
         return ""                                                      #2
      }
      return "\(firstName) \(lastName)"                                 #3
    }
}
```

Guards are great for a “none shall pass” approach where optionals are not wanted. In a moment you’ll see how to get more granular control with multiple optionals.

##### Guards and Indentation

Guards keep the indentation low! This makes them a good candidate for unwrapping without increasing indentation.

Now you can use the `displayName` computed property to use it in any customer communication.

##### Listing 4.16. `displayName` in action

```
let customer = Customer(id: "30", email: "mayolover@gmail.com",
 firstName: "Jake", lastName: "Freemason", balance: 300)

customer.displayName // Jake Freemason
```

### 4.5. Returning optional strings

In real-world applications, you may be tempted to return an empty string because it saves the hassle of unwrapping an optional string. Empty strings often make sense, too, but in this scenario, they aren’t beneficial. Let’s explore why.

The `displayName` computed property serves its purpose, but a problem occurs when the `firstName` and `lastName` properties are nil: `displayName` returns an empty string, such as `""`. Unless you rely on a sharp coworker to add `displayName.isEmpty` checks throughout the whole application, you may miss one case, and some customers will get an email starting with `"Dear` `,"` where the name is missing.

Strings are expected to be empty where they make sense, such as loading a text file that may be empty, but an empty string makes less sense in `displayName` because implementers of this code expect some name to display.

In such a scenario, a better method is to be explicit and tell the implementers of the method that the string can be optional; you do this by making `displayName` return an optional string.

The benefit of returning an optional `String` is that you would know at compile-time that `displayName` may not have a value, whereas with the `isEmpty` check you’d know it at runtime. This compile-time safety comes in handy when you send out a newsletter to 500,000 people, and you don’t want it to start with `“Dear` `,”`.

Returning an optional string may sound like a strawman argument, but it happens plenty of times inside projects, especially when developers aren’t too keen on optionals. By not returning an optional, you are trading compile-time safety for a potential runtime error.

To set the right example, `displayName` would return an optional `String` for `display-Name`.

##### Listing 4.17. Making `displayName` return an optional `String`

```
struct Customer {
   // ... snip

    var displayName: String? {                                           #1
       guard let firstName = firstName, let lastName = lastName else {
         return nil                                                      #2
       }
       return "\(firstName) \(lastName)"
    }
}
```

Now that `displayName` returns an optional `String`, the caller of the method must deal with unwrapping the optional explicitly. Having to unwrap `displayName`, as shown next, may be a hassle, but you get more safety in return.

##### Listing 4.18. Unwrapping the optional `displayName`

```
if let displayName = customer.displayName {
    createConfirmationMessage(name: displayName, product: "Economy size party
     tub")
} else {
    createConfirmationMessage(name: "customer", product: "Economy size party
     tub")
}
```

For peace of mind, you can add an `isEmpty` check for extra runtime safety to be super-duper safe in critical places in your application—such as sending newsletters—but at least you now get some help from the compiler.

### 4.6. Granular control over optionals

Currently, `displayName` on a customer needs to have both a `firstName` and `lastName` value before it returns a proper string. Let’s loosen `displayName` up a little so that it can return whatever name it can find, making the property more lenient. If only a first name or last name is known, the `displayName` function can return either or both of those values, depending on which names are filled in.

You can make `displayName` more flexible by replacing the `guard` with a `switch` statement. Essentially this means that unwrapping the two optionals becomes part of the logic of a `displayName`, whereas with `guard` you would block any nil values before the property’s method continues.

As an improvement, you put both optionals inside a tuple, such as `(firstName,` `lastName)`, and then match on both optionals at once. This way you can return a value depending on which optionals carry a value.

![](https://drek4537l1klr.cloudfront.net/veen/Figures/04fig03_alt.jpg)

By using the `"?"` operator in the cases, you bind *and* unwrap the optionals. This is why you end up with a non-optional property in the strings inside the case statements.

Now when a customer doesn’t have a full name, you can still use part of the name, such as the last name only.

##### Listing 4.19. `displayName` works with a partially filled-in name

```
let customer = Customer(id: "30", email: "famthompson@gmail.com", 
 firstName: nil, lastName: "Thompson", balance: 300)

print(customer.displayName) // "Thompson"
```

Just be wary of adding too many optionals in a tuple. Usually, when you’re adding three or more optionals inside a tuple, you may want to use a different abstraction for readability, such as falling back to a combination of `if` `let` statements.

#### 4.6.1. Exercises

1. If no optionals in a function are allowed to have a value, what would be a good tactic to make sure that all optionals are filled?
1. If the functions take different paths depending on the optionals inside it, what would be a correct approach to handle all these paths?

### 4.7. Falling back when an optional is nil

Earlier you saw how you checked empty and optional strings for a customer’s `displayName-` property.

When you ended up with an unusable `displayName`, you fell back to “customer,” so that in the communication, The Mayonnaise Depot starts their emails with “Dear customer.”

When an optional is nil, it’s a typical scenario to resort to a fallback value. Because of this, Swift offers some syntactic sugar in the shape of the `??` operator, called the nil-coalescing operator.

You could use the `??` operator to fall back to `"customer"` when a customer has no name available.

##### Listing 4.20. Defaulting back on a value with the nil-coalescing operator

```
let title: String = customer.displayName ?? "customer"
createConfirmationMessage(name: title, product: "Economy size party tub")
```

Just like before, any time the customer’s name isn’t filled in, the email form starts with “Dear customer.” This time, however, you shaved off some explicit `if` `let` unwrapping from your code.

Not only does the nil-coalescing operator fall back to a default value, but it also *unwraps* the optional when it does have a value.

Notice how `title` is a `String`, yet you feed it the `customer.displayName` optional. This means that `title` will either have the customer’s unwrapped name *or* fall back to the non-optional “customer” value.

### 4.8. Simplifying optional enums

You saw before how optionals are enums and that you can pattern match on them, such as when you were creating the `displayName` value on the `Customer` struct. Even though optionals are enums, you can run into an enum that is an optional. An optional enum is an enum inside an enum. In this section, you’ll see how to handle these optional enums.

Our favorite web store, The Mayonnaise Depot, introduces two memberships, `silver` and `gold`, each with respectively five and ten percent discounts on their delicious products. Customers can pay for these memberships to get discounts on all their orders.

A `Membership` enum, as shown in this example, represents these membership types; it contains the `silver` and `gold` cases.

##### Listing 4.21. The `Membership` enum

```
enum Membership {
    /// 10% discount
    case gold
    /// 5% discount
    case silver
}
```

Not all customers have upgraded to a membership, resulting in an optional `membership` property on the `Customer` struct.

##### Listing 4.22. Adding a `membership` property to `Customer`

```
struct Customer {
    // ... snip
    let membership: Membership?
}
```

When you want to read this value, a first implementation tactic could be to unwrap the enum first and act accordingly.

##### Listing 4.23. Unwrapping an optional before pattern matching

```
if let membership = customer.membership {
    switch membership {
    case .gold: print("Customer gets 10% discount")
    case .silver: print("Customer gets 5% discount")
    }
} else {
    print("Customer pays regular price")
}
```

Even better, you can take a shorter route and match on the optional enum by using the `?` operator. The `?` operator indicates that you are unwrapping and reading the optional `membership` at the same time.

##### Listing 4.24. Pattern matching on an optional

```
switch customer.membership {
case .gold?: print("Customer gets 10% discount")
case .silver?: print("Customer gets 5% discount")
case nil: print("Customer pays regular price")
}
```

##### Note

If you match on `nil`, the compiler tells you once you add a new case to the enum. With `default` you don’t get this luxury.

In one fell swoop, you both pattern matched on the enum and unwrapped it in the process, helping you eliminate an extra `if` `let` unwrapping step from your code.

#### 4.8.1. Exercise

1. You have two enums. One enum represents the contents of a pasteboard (some data that a user cut or copied to the pasteboard):

enum PasteBoardContents {
case url(url: String)
case emailAddress(emailAddress: String)
case other(contents: String)
}

copy

The `PasteBoardEvent` represents the event related to `PasteBoardContents`. Perhaps the contents were added to the pasteboard, erased from the pasteboard, or pasted from the pasteboard:

enum PasteBoardEvent {
case added
case erased
case pasted
}

copy

The `describeAction` function takes on the two enums, and it returns a `String` describing the event, such as “The user added an email address to pasteboard.” The goal of this exercise is to fill the body of a function:

func describeAction(event: PasteBoardEvent?, contents:
PasteBoardContents?) -> String {
// What goes here?
}

copy

Given this input

describeAction(event: .added, contents: .url(url: "www.manning.com"))
describeAction(event: .added, contents: .emailAddress(emailAddress:
"info@manning.com"))
describeAction(event: .erased, contents: .emailAddress(emailAddress:
"info@manning.com"))
describeAction(event: .erased, contents: nil)
describeAction(event: nil, contents: .other(contents: "Swift in Depth"))

copy

make sure that the output is as follows:

"User added an url to pasteboard: www.manning.com."
"User added something to pasteboard."
"User erased an email address from the pasteboard."
"The pasteboard is updated."
"The pasteboard is updated."

copy

### 4.9. Chaining optionals

Sometimes you need a value from an optional property that can also contain another optional property.

Let’s demonstrate by creating a product type that The Mayonnaise Depot offers in their store, such as a giant tub of mayonnaise. The following struct represents a product.

##### Listing 4.25. Introducing `Product`

```
struct Product {
    let id: String
    let name: String
    let image: UIImage?
}
```

A customer can have a favorite product for special quick orders. Add it to the `Customer` struct.

##### Listing 4.26. Adding an optional `favoriteProduct` to `Customer`

```
struct Customer {
    // ... snip
    let favoriteProduct: Product?
```

If you were to get the image from a `favoriteProduct`, you’d have to dig a bit to reach it from a customer. You can dig inside optionals by using the `?` operator to perform *optional chaining*.

Additionally, if you were to set an image to UIKit’s `UIImageView`, you could give it a customer’s product’s image with the help of chaining.

##### Listing 4.27. Applying optional chaining

```
let imageView = UIImageView()
imageView.image = customer.favoriteProduct?.image
```

Notice how you used the `?` to reach for the `image` inside `favoriteProduct`, which is an optional.

You can still perform regular unwraps on chained optionals by using `if` `let`, which is especially handy when you want to perform some action when a chained optional is nil.

The following listing tries to display the image from a product and fall back on a missing default image if either `favoriteProduct` or its `image` property is nil.

##### Listing 4.28. Unwrapping a chained optional

```
if let image = customer.favoriteProduct?.image {
  imageView.image = image
} else {
  imageView.image = UIImage(named: "missing_image")
}
```

For the same effect, you can also use a combination of optional chaining and nil coalescing.

##### Listing 4.29. Combining nil coalescing with optional chaining

```
imageView.image = customer.favoriteProduct?.image ?? UIImage(named: "missing_
     image")
```

Optional chaining isn’t a mandatory technique, but it helps with concise optional unwrapping.

### 4.10. Constraining optional Booleans

Booleans are a value that can either be true or false, making your code nice and predictable. Now Swift comes around and says “Here’s a Boolean with three states: true, false, and nil.”

Ending up with some sort of quantum Boolean that can contain three states can make things awkward. Is a nil Boolean the same as false? It depends on the context. You can deal with Booleans in three scenarios: one where a nil Boolean represents false, one where it represents a true value, and one where you explicitly want three states.

Whichever approach you pick, these methods are here to make sure that nil Booleans don’t propagate too far into your code and cause mass confusion.

#### 4.10.1. Reducing a Boolean to two states

You can end up with an optional Boolean, for example, when you’re parsing data from an API in which you try to read a Boolean, or when retrieving a key from a dictionary-.

For instance, a server can return some preferences a user has set for an app, such as wanting to log in automatically, or whether or not to use Apple’s Face ID to log in, as shown in the following example.

##### Listing 4.30. Receiving an optional Boolean

```
let preferences = ["autoLogin": true, "faceIdEnabled": true]      #1
 
let isFaceIdEnabled = preferences["faceIdEnabled"]                #2
print(isFaceIdEnabled) // Optional(true)
```

When you want to treat a nil as `false`, making it a regular Boolean straight away can be beneficial, so dealing with an optional Boolean doesn’t propagate far into your code.

You can do this by using a fallback value, with help from the nil-coalescing operator- `??`.

##### Listing 4.31. Falling back with the nil-coalescing operator

```
let preferences = [“autoLogin”: true, “faceIdEnabled”: true]

let isFaceIdEnabled = preferences["faceIdEnabled"] ?? false
print(isFaceIdEnabled) // true, not optional any more.
```

Via the use of the nil-coalescing operator, the Boolean went from three states to a regular Boolean again.

#### 4.10.2. Falling back on true

Here’s a counterpoint: blindly falling back to `false` is not recommended. Depending on the scenario, you may want to fall back on a `true` value instead.

Consider a scenario where you want to see whether a customer has Face ID enabled so that you can direct the user to a Face ID settings screen. In that case, you can fall back on `true` instead.

##### Listing 4.32. Falling back on `true`

```
if preferences["faceIdEnabled"] ?? true {
    // go to Face ID settings screen.
} else {
    // customer has disabled Face ID
}
```

It’s a small point, but it shows that seeing an optional Boolean and thinking “Let’s make it false” isn’t always a good idea.

#### 4.10.3. A Boolean with three states

You can give an optional Boolean more context when you *do* want to have three states. Consider an enum instead to make these states explicit.

Following the user preference example from earlier, you’re going to convert the Boolean to an enum called `UserPreference` with three cases: `.enabled`, `.disabled`, and `.notSet`. You do this to be more explicit in your code and gain compile-time benefits.

##### Listing 4.33. Converting a Boolean to an enum

```
let isFaceIdEnabled = preferences["faceIdEnabled"]
print(isFaceIdEnabled) // Optional(true)

// We convert the optional Boolean to an enum here.
let faceIdPreference = UserPreference(rawValue: isFaceIdEnabled)    #1
 
// Now we can pass around the enum.
// Implementers can match on the UserPreference enum.
switch faceIdPreference {                                           #2
case .enabled: print("Face ID is enabled")
case .disabled: print("Face ID is disabled")
case .notSet: print("Face ID preference is not set")
}
```

A nice benefit is that now receivers of this enum have to explicitly handle all three cases, unlike with the optional Boolean.

#### 4.10.4. Implementing RawRepresentable

You can add a regular initializer to an enum to convert it from a Boolean. Still, you can be “Swiftier” and implement the `RawRepresentable` protocol ([https://developer.apple.com/documentation/swift/rawrepresentable](https://developer.apple.com/documentation/swift/rawrepresentable)) as a convention.

Conforming to `RawRepresentable` is the idiomatic way of turning a type to a raw value and back again. Adhering to this protocol makes streamlining to Objective-C easier and simplifies conformance to other protocols, such as `Equatable`, `Hashable`, and `Comparable`—more on that in [chapter 7](https://livebook.manning.com/book/swift-in-depth/chapter-7/ch07).

Once you implement the `RawRepresentable` protocol, a type has to implement a `rawValue` initializer as well as a `rawValue` property to convert a type to the enum and back again.

The `UserPreference` enum looks as follows.

##### Listing 4.34. The `UserPreference` enum

```
enum UserPreference: RawRepresentable {          #1
    case enabled
    case disabled
    case notSet

    init(rawValue: Bool?) {                      #2
         switch rawValue {                       #3
           case true?: self = .enabled           #4
           case false?: self = .disabled         #4
           default: self = .notSet
         }
    }

    var rawValue: Bool? {                        #5
         switch self {
           case .enabled: return true
           case .disabled: return false
           case .notSet: return nil
         }
    }

}
```

Inside the initializer, you pattern match on the optional Boolean. By using the question mark, you pattern match directly on the value inside the optional; then you set the enum to the proper case.

As a final step, you default to setting the enum to `.notSet`, which happens if the preference is nil.

Now you constrained a Boolean to an enum and gave it more context. But it comes at a cost: you are introducing a new type, which may muddy up the codebase. When you want to be explicit and gain compile-time benefits, an enum might be worth that cost.

#### 4.10.5. Exercise

1. Given this optional Boolean

let configuration = ["audioEnabled": true]

copy

create an enum called `AudioSetting` that can handle all three cases:

let audioSetting = AudioSetting(rawValue: configuration["audioEnabled"])

switch audioSetting {
case .enabled: print("Turn up the jam!")
case .disabled: print("sshh")
case .unknown: print("Ask the user for the audio setting")
}

copy

Also, make sure you can get the value out of the enum again:

let isEnabled = audioSetting.rawValue

copy

### 4.11. Force unwrapping guidelines

![](https://drek4537l1klr.cloudfront.net/veen/Figures/04fig04.jpg)

*Force unwrapping* means you unwrap an optional without checking to see if a value exists. By force unwrapping an optional, you reach for its wrapped value to use it. If the optional has a value, that’s great. If the optional is empty, however, the application crashes, which is not so great.

Take Foundation’s `URL` type, for example. It accepts a `String` parameter in its initializer. Then a `URL` is either created or not, depending on whether the passed string is a proper path—hence `URL`’s initializer can return nil.

##### Listing 4.35. Creating an optional `URL`

```
let optionalUrl = URL(string: "https://www.themayonnaisedepot.com") 
 // Optional(http://www.themayonnaisedepot.com)
```

You can force unwrap the optional by using an exclamation mark, bypassing any safe techniques.

##### Listing 4.36. Force unwrapping an optional `URL`

```
let forceUnwrappedUrl = URL(string: "https://www.themayonnaisedepot.com")! 
 // http://www.themayonnaisedepot.com. Notice how we use the ! to force
     unwrap.
```

Now you don’t need to unwrap the optional anymore. But force unwrapping causes your app to crash on an invalid path.

##### Listing 4.37. A crashing optional `URL`

```
let faultyUrl = URL(string: "mmm mayonnaise")!       #1
```

#### 4.11.1. When force unwrapping is “acceptable”

Ideally, you would never use force unwrapping. But sometimes you can’t avoid force unwrapping because your application can end up in a bad state. Still, think about it: Is there truly no other way you can prevent a force unwrap? Perhaps you can return a nil instead, or throw an error.

As a heuristic, only use a force unwrap as a last resort and consider the following exceptions.

##### POSTPONING ERROR HANDLING

Having error handling in place at the start can slow you down. When your functions can throw an error, the caller of the function must now deal with the error, which is extra work and logic that takes time to implement.

One reason to apply a force unwrap is to produce some working piece of code quickly, such as creating a prototype or a quick and dirty Swift script. Then you can worry about error handling later.

You could use force unwraps to get your application started, then consider them as markers to replace the force unwraps with proper error handling. But you and I both know that in programming “I’ll do it later” means “I’m never going to do it,” so take this advice with a grain of salt.

##### WHEN YOU KNOW BETTER THAN THE COMPILER

If you’re dealing with a value that’s fixed at compile-time, force unwrapping an optional can make sense.

In the following listing, you know that the passed URL will parse, even though the compiler doesn’t know it yet. It’s safe to force unwrap here.

##### Listing 4.38. Force unwrapping a valid `URL`

```
let url = URL(string: "http://www.themayonnaisedepot.com")! //
     http://www.themayonnaisedepot.com
```

But if this `URL` is a runtime-loaded variable—such as user input—you can’t guarantee a safe value, in which case you would risk a crash if you were to force unwrap it.

#### 4.11.2. Crashing with style

Sometimes you may not be able to avoid a crash. But then you may want to supply more information instead of performing a force unwrap.

For example, imagine you’re creating a `URL` from a path you get at runtime—meaning that the passed path isn’t guaranteed to be usable—and the application for some reason cannot continue when this `URL` is invalid, which means that the `URL` type returns nil.

Instead of force unwrapping the `URL` type, you can choose to crash manually and add some more information, which helps you with debugging in the logs.

You can do this by manually crashing your application with the `fatalError` function. You can then supply extra information such as `#line` and `#function`, which supplies the precise information where an application crashed.

In the following listing you try to unwrap the `URL` first using a guard. But if the unwrapping fails, you manually cause a `fatalError` with some extra information that can help you during debugging.

##### Listing 4.39. Crashing manually

```
guard let url = URL(string: path) else {
  fatalError("Could not create url on \(#line) in \(#function)")
}
```

One big caveat though: if you’re building an iOS app, for example, your users may see sensitive information that you supply in the crash log. What you put in the `fatalError` message is something you’ll have to decide on a case-by-case basis.

### 4.12. Taming implicitly unwrapped optionals

![](https://drek4537l1klr.cloudfront.net/veen/Figures/04fig05.jpg)

Implicitly unwrapped optionals, or IUOs, are tricky because they are unique optionals that are automatically unwrapped depending on their context. But if you aren’t careful, they can crash your application!

This section is about bending IUOs to your will while making sure they won’t hurt you.

#### 4.12.1. Recognizing IUOs

An IUO force unwraps a type, instead of an instance.

##### Listing 4.40. Introducing an IUO

```
let lastName: String! = "Smith"      #1
 
let name: String? = 3
let firstName = name!                #2
```

You can recognize IUOs by the bang (`!`) after the type, such as `String!`. You can think of them as *pre-unwrapped* optionals.

Like force unwrapping, the `!` indicates a danger sign in Swift. IUOs also can crash your application, which you’ll see shortly.

#### 4.12.2. IUOs in practice

IUOs are like a power drill. You may not use them often, but they come in handy when you need them. But if you make a mistake, they can mess up your foundation.

When you create an IUO, you promise that a variable or constant is populated shortly *after* initialization, but *before* you need it. When that promise is broken, people get hurt (well, technically, the application can crash). But disaster happens if your application controls nuclear power plants or helps dentists administer laughing gas to patients.

Going back to The Mayonnaise Depot, they have decided to add a chat service to their backend so that customers can ask for help ordering products.

When the backend server starts, the server initiates a process monitor before anything else. This process monitor makes sure that the system is ready before other services are initialized and started, which means that you’ll have to start the chat server after the process monitor. After the process monitor is ready, the chat server is passed to the process monitor (see [figure 4.2](https://livebook.manning.com/book/swift-in-depth/chapter-4/ch04fig2)).

![Figure 4.2. Starting the process monitor](data:image/svg+xml;utf8,%3Csvg%20xmlns=%22http://www.w3.org/2000/svg%22%20xmlns:xlink=%22http://www.w3.org/1999/xlink%22%20version=%221.1%22%20x=%220px%22%20y=%220px%22%20viewBox=%220%200%20581%20282%22%20xml:space=%22preserve%22%20height=%22282px%22%20width=%22581px%22%3E%20%3Crect%20width=%22581%22%20height=%22282%22%20style=%22fill:rgb(255,255,255);%22/%3E%3C/svg%3E)

Since the server initiates `ProcessMonitor` before anything else, `ProcessMonitor` could have an optional reference to the chat service. As a result, the `ChatService` can be given to `ProcessMonitor` at a later time. But making the chat server optional on the process monitor is cumbersome because to access the chat server, you’d have to unwrap the chat service every time while knowing that the process monitor has a valid reference.

You could also make the chat service a lazy property on `ProcessMonitor`, but then `ProcessMonitor` is in charge of initializing `ChatService`. In this case, `ProcessMonitor` doesn’t want to handle the possible dependencies of `ChatService`.

This is a good scenario for an IUO. By making the chat service an IUO, you don’t have to pass the chat service to the process monitor’s initializer, but you don’t need to make chat service an optional, either.

##### CREATING AN IUO

The following listing shows the code for `ChatService` and `ProcessMonitor`. The `Process-Monitor` has a `start()` method to create the monitor. It has a `status()` method to check if everything is still up and running.

##### Listing 4.41. Introducing `ChatService` and `ProcessMonitor`

```
class ChatService {
    var isHealthy = true
    // Left empty for demonstration purposes.
}

class ProcessMonitor {

    var chatService: ChatService!              #1
 
    class func start() -> ProcessMonitor {
        // In a real-world application: run elaborate diagnostics.
        return ProcessMonitor()
    }

    func status() -> String {
        if chatService.isHealthy {
            return "Everything is up and running"
        } else {
            return "Chatservice is down!"
        }
    }
}
```

The initialization process starts the monitor, then the chat service, and then finally passes the service to the monitor.

##### Listing 4.42. The initialization process

```
let processMonitor = ProcessMonitor.start()
// processMonitor runs important diagnostics here.
// processMonitor is ready.

let chat = ChatService() // Start Chatservice.

processMonitor.chatService = chat
processMonitor.status() // "Everything is up and running"
```

This way you can kick off the `processMonitor` first, but you have the benefit of having `chatService` available to `processMonitor` right before you need it.

But `chatService` is an IUO, and IUOs can be dangerous. If you for some reason accessed the `chatService` property before it passed to `processMonitor`, you’d end up with a crash.

##### Listing 4.43. A crash from an IUO

```
let processMonitor = ProcessMonitor.start()
processMonitor.status() // fatal error: unexpectedly found nil
```

By making `chatService` an IUO, you don’t have to initialize it via an initializer, but you also don’t have to unwrap it every time you want to read a value. It’s a win-win with some danger added. As you work more with Swift, you’ll find other ways to get rid of IUOs because they are a double-edged sword. For instance, you could pass a `Chat-ServiceFactory` to `ProcessMonitor` that can produce a chat server for `Process-Monitor` without `ProcessMonitor` needing to know about dependencies.

#### 4.12.3. Exercise

1. What are good alternatives to IUOs?

### 4.13. Closing thoughts

This chapter covered many scenarios involving optionals. Going over all these techniques was no easy feat—feel free to be proud!

Being comfortable with optionals is powerful and an essential foundation as a Swift programmer. Mastering optionals helps you make the right choices in a plethora of situations in daily Swift programming.

Later chapters expand on the topic of optionals when you start looking at applying `map`, `flatMap`, and `compactMap` on optionals. After you’ve worked through these advanced topics, you’ll be optionally zen and handle every optional curveball Swift throws at you.

### Summary

- Optionals are enums with syntactic sugar sprinkled over them.
- You can pattern match on optionals.
- Pattern match on multiple optionals at once by putting them inside a tuple.
- You can use nil-coalescing to fall back to default values.
- Use optional chaining to dig deep into optional values.
- You can use nil-coalescing to transform an optional Boolean into a regular Boolean.
- You can transform an optional Boolean into an enum for three explicit states.
- Return optional strings instead of empty strings when a value is expected.
- Use force unwrapping only if your program can’t recover from a nil value.
- Use force unwrapping when you want to delay error handling, such as when prototyping.
- It’s safer to force unwrap optionals if you know better than the compiler.
- Use implicitly unwrapped optionals for properties that are instantiated right after initialization.

### Answers

1. If no optionals in a function are allowed to have a value, what would be a good tactic to make sure that all optionals are filled? Use a guard—this can block optionals at the top of a function.
1. If the functions take different paths depending on the optionals inside it, what would be a correct approach to handle all these paths? Putting multiple optionals inside a tuple allows you to pattern match on them and take different paths in a function.
1. The code looks like this:

// Use a single switch statement inside describeAction.
func describeAction(event: PasteBoardEvent?, contents:
PasteBoardContents?) -> String {
switch (event, contents) {
case let (.added?, .url(url)?): return "User added a url to
pasteboard: \(url)"
case (.added?, _): return "User added something to pasteboard"
case (.erased?, .emailAddress?): return "User erased an email
address from the pasteboard"
default: return "The pasteboard is updated"
}
}

copy

1. The code looks like this:

enum AudioSetting: RawRepresentable {
case enabled
case disabled
case unknown

init(rawValue: Bool?) {
switch rawValue {
case let isEnabled? where isEnabled: self = .enabled
case let isEnabled? where !isEnabled: self = .disabled
default: self = .unknown
}
}

var rawValue: Bool? {
switch self {
case .enabled: return true
case .disabled: return false
case .unknown: return nil
}
}

}

copy

1. What are good alternatives to IUOs? Lazy properties or factories that are passed via an initializer
