# Chapter 5. Demystifying initializers

### ***This chapter covers***

- Demystifying Swift’s initializer rules
- Understanding quirks of struct initializers
- Understanding complex initializer rules when subclassing
- How to keep the number of initializers low when subclassing
- When and how to work with required initializers

As a Swift developer, initializing your classes and structs are one of the core fundamentals that you have been using.

But initializers in Swift are not intuitive. Swift offers memberwise initializers, custom initializers, designated initializers, convenience initializers, required initializers, and I didn’t even mention the optional initializers, failable initializers, and throwing initializers. Frankly, it can get bewildering sometimes.

This chapter sheds some light on the situation so that instead of having a boxing match with the compiler, you can make the most out of initializing structs, classes, and subclasses.

In this chapter, we model a boardgame hierarchy that you’ll compose out of structs and classes. While building this hierarchy, you’ll experience the joy of Swift’s strange initializer rules and how you can deal with them. Since creating game mechanics is a topic for a book itself, we only focus on the initializer fundamentals in this chapter.

First, you’ll tinker with struct initializers and learn about the quirks that come with them. After that, you’ll move on to class initializers and the subclassing rules that accompany them; this is usually where the complexity kicks in with Swift. Then you’ll see how you can reduce the number of initializers while you’re subclassing, to keep the number of initializers to a minimum. Finally, you’ll see the role that required initializers play, and when and how to use them.

The goal of this chapter is for you to be able to write initializers in one go, versus doing an awkward dance of trial and error to please the compiler gods.

### 5.1. Struct initializer rules

Structs can be initialized in a relatively straightforward way because you can’t subclass them. Nevertheless, there are still some special rules that apply to structs, which we explore in this section. In the next section, we model a board game, but first we model the players that can play the board game. You’ll create a `Player` struct containing the name and type of each player’s pawn. You’re choosing to model a `Player` as a struct because structs are well suited for small data models (amongst other things). Also, a struct can’t be subclassed, which is fine for modeling `Player`.

##### Join Me!

It’s more educational and fun if you can check out the code and follow along with the chapter. You can download the source code at [http://mng.bz/nQE5](http://mng.bz/nQE5).

The `Player` that you’ll model resembles a pawn on a board game. You can instantiate a `Player` by passing it a name and a type of pawn, such as a car, shoe, or hat.

##### Listing 5.1. Creating a `player`

```
let player = Player(name: "SuperJeff", pawn: .shoe)
```

You see that a `Player` has two properties: `name` and `pawn`. Notice how the struct has no initializer defined. Under the hood, you get a so-called *memberwise initializer*, which is a free initializer the compiler generates for you, as shown here.

##### Listing 5.2. Introducing the `Player` struct

```
12345678910enum Pawn {
    case dog, car, ketchupBottle, iron, shoe, hat
}

struct Player {
  let name: String
  let pawn: Pawn
}

let player = Player(name: "SuperJeff", pawn: .shoe)
```

#### 5.1.1. Custom initializers

Swift is very strict about wanting all properties populated in structs and classes, which is no secret. If you’re coming from languages where this wasn’t the case (such as Ruby and Objective-C), fighting the Swift compiler can be quite frustrating at first.

To illustrate, you can’t initialize a `Player` with only a name, omitting a pawn. The following won’t compile.

##### Listing 5.3. Omitting a property

```
let player = Player(name: "SuperJeff")

error: missing argument for parameter 'pawn' in call
let player = Player(name: "SuperJeff")
                                     ^
                                     , pawn: Pawn
```

To make initialization easier, you can omit `pawn` from the initializer parameters. The struct needs all properties propagated with a value. If the struct initializes its properties, you don’t have to pass values. In [listing 5.4](https://livebook.manning.com/book/swift-in-depth/chapter-5/ch05list4) you’re going to add a custom initializer where you can *only* pass a name of the `Player`. The pawn can then randomly be picked for players, making your struct easier to initialize. The custom initializer accepts a name and randomly selects the pawn.

First, you make sure that the `Pawn` enum conforms to the `CaseIterable` protocol; doing so allows you to obtain an array of all cases via the `allCases` property. Then in the initializer of `Player`, you can use the `randomElement()` method on `allCases` to pick a random element.

##### Note

`CaseIterable` works only on enums without associated values, because with associated values an enum could theoretically have an infinite number of variations.

##### Listing 5.4. Creating your initializer

```
enum Pawn: CaseIterable {                                  #1
     case dog, car, ketchupBottle, iron, shoe, hat
}

struct Player {
    let name: String
    let pawn: Pawn

    init(name: String) {                                  #2
         self.name = name
        self.pawn = Pawn.allCases.randomElement()!        #3
     }
}

// The custom initializer in action.
let player = Player(name: "SuperJeff")
print(player.pawn) // shoe
```

##### Note

The `randomElement()` method returns an optional that you need to unwrap. You force unwrap it via a `!`. Usually, a force unwrap is considered bad practice. But in this case, you know at compile-time that it’s safe to unwrap.

Now indecisive players can have a pawn picked for them.

#### 5.1.2. Struct initializer quirk

Here is an interesting quirk. You can’t use the memberwise (free) initializer from earlier; it won’t work.

##### Listing 5.5. Initializing a `player` with a custom initializer

```
let secondPlayer = Player(name: "Carl", pawn: .dog)
error: extra argument 'pawn' in call
```

The reason that the memberwise initializer doesn’t work any more is to make sure that developers can’t circumvent the logic in the custom initializer. It’s a useful protection mechanism! In your case, offering both the custom and memberwise initializers would be favorable. You can offer both initializers by extending the struct and putting your custom initializer there.

First, you restore the `Player` struct, so it won’t contain any custom initializers, giving you the memberwise initializer back. Then you extend the `Player` struct and put your custom initializer in there.

##### Listing 5.6. Restoring the `Player` struct

```
struct Player {
    let name: String
    let pawn: Pawn
}

extension Player {             #1
     init(name: String) {      #2
        self.name = name
        self.pawn = Pawn.allCases.randomElement()!
    }
}
```

You can confirm this worked because you now can initialize a `Player` via both initializers.

##### Listing 5.7. Initializing a `player` with both initializers

```
// Both initializers work now.
let player = Player(name: "SuperJeff")
let anotherPlayer = Player(name: "Mary", pawn: .dog)
```

By using an extension, you can keep the best of both worlds. You can offer the free memberwise and a custom initializer with specific logic.

#### 5.1.3. Exercises

1. Given the following struct

struct Pancakes {

enum SyrupType {
case corn
case molasses
case maple
}

let syrupType: SyrupType
let stackSize: Int

init(syrupType: SyrupType) {
self.stackSize = 10
self.syrupType = syrupType
}
}

copy

will the following initializers work?

let pancakes = Pancakes(syrupType: .corn, stackSize: 8)
let morePancakes = Pancakes(syrupType: .maple)

copy

1. If these initializers didn’t work, can you make them work without adding another initializer?

### 5.2. Initializers and subclassing

Subclassing is a way to achieve polymorphism. With polymorphism, you can offer a single interface, such as a function, that works on multiple types.

But subclassing isn’t too popular in the Swift community, especially because Swift often is marketed as a protocol-oriented language, which is one subclassing alternative.

You saw in [chapter 2](https://livebook.manning.com/book/swift-in-depth/chapter-2/ch02) how subclasses tend to be a rigid data structure. You also saw how enums are a flexible alternative to subclassing, and you’ll see more flexible approaches when you start working with protocols and generics.

Nevertheless, subclassing is still a valid tool that Swift offers. You can consider overriding or extending behavior from classes; this includes code from frameworks you don’t even own. Apple’s UIKit is a recurring example of this, where you can subclass `UIView` to create new elements for the screen.

This section will help you understand how initializers work in regard to classes and subclassing—also known as inheritance—so that when you’re not jumping on the protocol-oriented programming bandwagon, you can offer clean subclassing constructions.

#### 5.2.1. Creating a board game superclass

The `Player` model is all set up; now it’s time to start modeling the board game hierarchy.

First, you’re going to create a class called `BoardGame` that serves as a superclass. Then you’ll subclass `BoardGame` to create your own board game called Mutability Land: an exciting game that teaches Swift developers to write immutable code.

![](https://drek4537l1klr.cloudfront.net/veen/Figures/05fig01.jpg)

After the hierarchy is set up, you’ll discover Swift’s quirks that come with subclassing and approaches on how to deal with them.

#### 5.2.2. The initializers of BoardGame

The `BoardGame` superclass has three initializers: one designated initializer and two convenience initializers to make initialization easier (see [figure 5.1](https://livebook.manning.com/book/swift-in-depth/chapter-5/ch05fig1)).

![Figure 5.1. BoardGame initializers](https://drek4537l1klr.cloudfront.net/veen/Figures/05fig02_alt.jpg)

Before continuing, get acquainted with the two types of initializers for classes.

First is the *designated initializer*, which is the run-of-the-mill variety. Designated initializers are there to make sure all properties get initialized. Classes tend to have very few designated initializers, usually just one, but more are possible. Designated initializers point to a superclass if there is one.

Second is the *convenience initializer*, which can help make initialization easier by supplying default values or create a simpler initialization syntax. Convenience initializers can call other convenience initializers, but they ultimately call a designated initializer from the same class.

If you look inside `BoardGame`, you can confirm the use of one designated initializer and two convenience initializers, as shown here.

##### Listing 5.8. The `BoardGame` superclass

```
class BoardGame {
    let players: [Player]
    let numberOfTiles: Int

    init(players: [Player], numberOfTiles: Int) {         #1
        self.players = players
        self.numberOfTiles = numberOfTiles
    }

    convenience init(players: [Player]) {                 #2
        self.init(players: players, numberOfTiles: 32)
    }

    convenience init(names: [String]) {                   #3
        var players = [Player]()
        for name in names {
            players.append(Player(name: name))
        }
        self.init(players: players, numberOfTiles: 32)
    }
}
```

##### Note

Alternatively, you could also add a default `numberOfTiles` value to the designated initializer, such as `init(players:` `[Player],` `numberOfTiles:` `Int` `=` `32)`. By doing so, you can get rid of one convenience initializer. For example purposes, you continue with two separate convenience initializers.

The `BoardGame` contains two properties: a `players` array containing all players in the board game, and a `numberOfTiles` integer indicating the size of the board game.

Here are the different ways you can initialize the `BoardGame` superclass.

##### Listing 5.9. Initializing `BoardGame`

```
//Convenience initializer
let boardGame = BoardGame(names: ["Melissa", "SuperJeff", "Dave"])

let players = [
    Player(name: "Melissa"),
    Player(name: "SuperJeff"),
    Player(name: "Dave")
]

//Convenience initializer
let boardGame = BoardGame(players: players)

//Designated initializer
let boardGame = BoardGame(players: players, numberOfTiles: 32)
```

The convenience initializers accept only an array of players or an array of names, which `BoardGame` turns into players. These convenience initializers point at the designated initializer.

##### Lack of Memberwise Initializers

Unfortunately, classes don’t get free memberwise initializers like structs do. With classes you’ll have to manually type them out. So much for being lazy!

#### 5.2.3. Creating a subclass

Now that you created `BoardGame`, you can start subclassing it to build board games. In this chapter, you’re creating only one game, which doesn’t exactly warrant a superclass setup. Theoretically, you can create lots of board games that subclass `BoardGame`.

The subclass is called `MutabilityLand`, which subclasses `BoardGame` (see [figure 5.2](https://livebook.manning.com/book/swift-in-depth/chapter-5/ch05fig2)). `MutabilityLand` inherits all the initializers from `BoardGame`.

![Figure 5.2. Subclassing BoardGame](https://drek4537l1klr.cloudfront.net/veen/Figures/05fig03.jpg)

As shown in [listing 5.10](https://livebook.manning.com/book/swift-in-depth/chapter-5/ch05list10), you can initialize `MutabilityLand` the same way as `BoardGame` because it inherits all the initializers that `BoardGame` has to offer.

##### Listing 5.10. `MutabilityLand` inherits all the `BoardGame` initializers

```
// Convenience initializer
let mutabilityLand = MutabilityLand(names: ["Melissa", "SuperJeff", "Dave"])
// Convenience initializer
let mutabilityLand = MutabilityLand(players: players)
// Designated initializer
let mutabilityLand = MutabilityLand(players: players, numberOfTiles: 32)
```

Looking inside `MutabilityLand`, you see that it has two properties of its own, `scoreBoard` and `winner`. The scoreboard keeps track of each player’s name and their score. The `winner` property remembers the latest winner of the game.

##### Listing 5.11. The `MutabilityLand` class

```
class MutabilityLand: BoardGame {
    // ScoreBoard is initialized with an empty dictionary
    var scoreBoard = [String: Int]()
    var winner: Player?
}
```

Perhaps surprisingly these properties don’t need an initializer; this is because `scoreBoard` is already initialized outside of an initializer, and `winner` is an optional, which is allowed to be nil.

#### 5.2.4. Losing convenience initializers

Here is where the process gets tricky: *once a subclass adds unpopulated properties, consumers of the subclass lose ALL the superclass’s initializers.*

Let’s see how this works. First, you’ll add an `instructions` property to `Mutability-Land`, which tells players the rules of the game.

[Figure 5.3](https://livebook.manning.com/book/swift-in-depth/chapter-5/ch05fig3) shows your current hierarchy with your new setup. Notice how the inherited initializers are gone now that you’ve added a new property (`instructions`) to `MutabilityLand`.

![Figure 5.3. Disappearing initializers](https://drek4537l1klr.cloudfront.net/veen/Figures/05fig04_alt.jpg)

To populate the new `instructions` property, you’ll create the designated initializer to populate it.

Let’s see how this looks in code.

##### Listing 5.12. Creating a designated initializer for `MutabilityLand`

```
class MutabilityLand: BoardGame {
    var scoreBoard = [String: Int]()
    var winner: Player?

    let instructions: String                                             #1
 
    init(players: [Player], instructions: String, numberOfTiles: Int) {  #2
        self.instructions = instructions
        super.init(players: players, numberOfTiles: numberOfTiles)       #3
     }
}
```

At this stage, `MutabilityLand` has lost the three inherited initializers from its superclass `Boardgame`.

You can’t initialize `MutabilityLand` anymore with the inherited initializers.

##### Listing 5.13. Inherited initializers don’t work any more

```
// These don't work any more.
let mutabilityLand = MutabilityLand(names: ["Melissa", "SuperJeff", "Dave"])
let mutabilityLand = MutabilityLand(players: players)
let mutabilityLand = MutabilityLand(players: players, numberOfTiles: 32)
```

To prove that you’ve lost the inherited initializers, try to create a `Mutability-Land` instance with an initializer from `BoardGame`—only this time, you get an error.

##### Listing 5.14. Losing superclass initializers

```
error: missing argument for parameter 'instructions' in call
let mutabilityLand = MutabilityLand(names: ["Melissa", "SuperJeff", "Dave"])
                                                                           ^
                                                                           ,
```

Losing inherited initializers may seem strange, but there is a legitimate reason why `MutabilityLand` loses them. The inherited initializers are gone because `BoardGame` can’t populate the new `instructions` property of its subclass. Moreover, since Swift wants all properties populated, it can now *only* rely on the newly designated initializer on `MutabilityLand`.

#### 5.2.5. Getting the superclass initializers back

There is a way to get all the superclass’ initializers back so that `MutabilityLand` can enjoy the free initializers from `BoardGame`.

By overriding the *designated* initializer from a superclass, a subclass gets the superclass’s initializers back. In other words, `MutabilityLand` overrides the designated initializer from `BoardGame` to get the convenience initializers back. The designated initializer from `MutabilityLand` still points to the designated initializer from `Board-Game` (see [figure 5.4](https://livebook.manning.com/book/swift-in-depth/chapter-5/ch05fig4)).

![Figure 5.4. MutabilityLand regains the free initializers from BoardGame.](https://drek4537l1klr.cloudfront.net/veen/Figures/05fig05_alt.jpg)

By overriding the superclass’ designated initializer, `MutabilityLand` gets all the convenience initializers back from `BoardGame`. Overriding an initializer is achieved by adding the `override` keyword on a designated initializer in `MutabilityLand`. The code can be found in [listing 5.15](https://livebook.manning.com/book/swift-in-depth/chapter-5/ch05list15).

##### Designated Initializer Funnels

You can see how designated initializers are like *funnels*. In a class hierarchy, convenience initializers go horizontal, and designated initializers go vertical.

##### Listing 5.15. `MutabilityLand` overrides the designated initializer

```
class MutabilityLand: BoardGame {
     // ... snip
    override init(players: [Player], numberOfTiles: Int) {
        self.instructions = "Read the manual"                         #1
        super.init(players: players, numberOfTiles: numberOfTiles)
    }
}
```

Since you override the superclass initializer, `MutabilityLand` needs to come up with its instructions there. Now that the designated initializer from `BoardGame` is overridden, you have a lot to choose from when initializing `MutabilityLand`.

##### Listing 5.16. All available initializers for `MutabilityLand`

```
// MutabilityLand's initializer
let mutabilityLand = MutabilityLand(players: players, instructions: "Just 
 read the manual", numberOfTiles: 40)

// BoardGame initializers all work again.
let mutabilityLand = MutabilityLand(names: ["Melissa", "SuperJeff", "Dave"])
let mutabilityLand = MutabilityLand(players: players)
let mutabilityLand = MutabilityLand(players: players, numberOfTiles: 32)
```

Thanks to a single override, you get all initializers back that the superclass has to offer.

#### 5.2.6. Exercise

1. The following superclass, called `Device`, registers devices in an office and keeps track of the rooms where these devices can be found. Its subclass `Television` is one of such devices that subclasses `Device`. The challenge is to initialize the `Television` subclass with a `Device` initializer. In other words, make the following line of code work by adding a single initializer somewhere:

let firstTelevision = Television(room: "Lobby")
let secondTelevision = Television(serialNumber: "abc")

copy

The classes are as follows:

class Device {

var serialNumber: String
var room: String

init(serialNumber: String, room: String) {
self.serialNumber = serialNumber
self.room = room
}

convenience init() {
self.init(serialNumber: "Unknown", room: "Unknown")
}

convenience init(serialNumber: String) {
self.init(serialNumber: serialNumber, room: "Unknown")
}

convenience init(room: String) {
self.init(serialNumber: "Unknown", room: room)
}

}

class Television: Device {
enum ScreenType {
case led
case oled
case lcd
case unknown
}

enum Resolution {
case ultraHd
case fullHd
case hd
case sd
case unknown
}

let resolution: Resolution
let screenType: ScreenType

init(resolution: Resolution, screenType: ScreenType, serialNumber:
String, room: String) {
self.resolution = resolution
self.screenType = screenType
super.init(serialNumber: serialNumber, room: room)
}

}

copy

### 5.3. Minimizing class initializers

You saw that `BoardGame` has one designated initializer; its subclass `MutabilityLand` has two designated initializers. If you were to subclass `MutabilityLand` again and add a stored property, that subclass would have three initializers, and so on. At this rate, you’d have to override more initializers the more you subclass, making your hierarchy complicated. Luckily there is a solution to keep the number of designated initializers low so that each subclass holds only a single designated initializer.

#### 5.3.1. Convenience overrides

In the previous section, `MutabilityLand` was overriding the designated initializer from the `BoardGame` class. But a neat trick is to make the overridden initializer in `MutabilityLand` into a *convenience override* initializer (see [figure 5.5](https://livebook.manning.com/book/swift-in-depth/chapter-5/ch05fig5)).

![Figure 5.5. MutabilityLand performs a convenience override on a designated initializer.](data:image/svg+xml;utf8,%3Csvg%20xmlns=%22http://www.w3.org/2000/svg%22%20xmlns:xlink=%22http://www.w3.org/1999/xlink%22%20version=%221.1%22%20x=%220px%22%20y=%220px%22%20viewBox=%220%200%20590%20233%22%20xml:space=%22preserve%22%20height=%22233px%22%20width=%22590px%22%3E%20%3Crect%20width=%22590%22%20height=%22233%22%20style=%22fill:rgb(255,255,255);%22/%3E%3C/svg%3E)

Now the overriding initializer in `MutabilityLand` is a convenience override initializer that points sideways to the designated initializer inside `MutabilityLand`. This designated initializer from `MutabilityLand` still points upwards to the designated initializer inside `BoardGame`.

In your class you make this happen using the `convenience` `override` keywords.

##### Listing 5.17. A convenience override

```
class MutabilityLand: BoardGame {
    var scoreBoard = [String: Int]()
    var winner: Player?

    let instructions: String

    convenience override init(players: [Player], numberOfTiles: Int) {   #1
        self.init(players: players, instructions: "Read the manual",
     numberOfTiles: numberOfTiles)                                       #2
    }
    init(players: [Player], instructions: String, numberOfTiles: Int) {  #3
        self.instructions = instructions
        super.init(players: players, numberOfTiles: numberOfTiles)
    }

}
```

Since the overriding initializer is now a convenience initializer, it points horizontally to the designated initializer in the same class. This way, `MutabilityLand` goes from having two designated initializers to one convenience initializer and a single designated initializer. Any subclass now only has to override a single designated initializer to get all initializers from the superclass.

The downside is that this approach is not as flexible. For example, the convenience initializer now has to figure out how to fill the `instructions` property. But if a convenience override works in your code, it reduces the number of designated initializers.

#### 5.3.2. Subclassing a subclass

To prove that you can keep the number of designated initializers low, you’ll introduce a subclass from `MutabilityLand` called `MutabilityLandJunior`, for kids. This game is a bit easier and has the option to play sounds, indicated by a new `soundsEnabled` property.

Because of your convenience override trick, this new subclass only has to override a single designated initializer. The hierarchy is shown in [figure 5.6](https://livebook.manning.com/book/swift-in-depth/chapter-5/ch05fig6).

![Figure 5.6. MutabilityLandJunior only needs to override one initializer.](data:image/svg+xml;utf8,%3Csvg%20xmlns=%22http://www.w3.org/2000/svg%22%20xmlns:xlink=%22http://www.w3.org/1999/xlink%22%20version=%221.1%22%20x=%220px%22%20y=%220px%22%20viewBox=%220%200%20590%20296%22%20xml:space=%22preserve%22%20height=%22296px%22%20width=%22590px%22%3E%20%3Crect%20width=%22590%22%20height=%22296%22%20style=%22fill:rgb(255,255,255);%22/%3E%3C/svg%3E)

You can see how this sub-subclass only needs to override a single initializer to inherit all initializers. Out of good habit, this initializer is a convenience override as well, in case `MutabilityLandJunior` gets subclassed again, as shown in the following listing.

##### Listing 5.18. `MutabilityLandJunior`

```
class MutabilityLandJunior: MutabilityLand {
    let soundsEnabled: Bool

    init(soundsEnabled: Bool, players: [Player], instructions: String,
     numberOfTiles: Int) {                                                #1
         self.soundsEnabled = soundsEnabled
         super.init(players: players, instructions: instructions,
         numberOfTiles: numberOfTiles)
    }

    convenience override init(players: [Player], instructions: String,
     numberOfTiles: Int) {                                               #2
         self.init(soundsEnabled: false, players: players, instructions: 
 instructions, numberOfTiles: numberOfTiles)
    }
}
```

You can now initialize this game in five ways.

##### Listing 5.19. Initializing `MutabilityLandJunior` with all initializers

```
let mutabilityLandJr = 
 MutabilityLandJunior(players: players, instructions: "Kids don't read 
 manuals", numberOfTiles: 8)

let mutabilityLandJr = MutabilityLandJunior(soundsEnabled: true, players: 
 players, instructions: "Kids don't read manuals", numberOfTiles: 8)

let mutabilityLandJr = MutabilityLandJunior(names: ["Philippe", "Alex"])

let mutabilityLandJr = MutabilityLandJunior(players: players)

let mutabilityLandJr = MutabilityLandJunior(players: players, numberOfTiles: 8)
```

Thanks to convenience overrides, this subclass gets many initializers for free.

Also, no matter how many subclasses you have (hopefully not too many), subclasses only have to override a single initializer!

#### 5.3.3. Exercise

1. Given the following class, which subclasses `Television` from the previous exercise

class HandHeldTelevision: Television {
let weight: Int
init(weight: Int, resolution: Resolution, screenType: ScreenType,
serialNumber: String, room: String) {
self.weight = weight
super.init(resolution: resolution, screenType: screenType,
serialNumber: serialNumber, room: room)
}
}

copy

add two convenience override initializers in the subclassing hierarchy to make this initializer work from the top-most superclass:

let handheldTelevision = HandHeldTelevision(serialNumber: "293nr30znNdjW")

copy

### 5.4. Required initializers

You may have seen *required* initializers pop up in the wild sometimes, such as when working with UIKit’s `UIViewController`. Required initializers play a crucial role when subclassing classes. You can decorate initializers with a `required` keyword. Adding the `required` keyword assures that subclasses implement the required initializer. You need the `required` keyword for two reasons—factory methods and protocols—which you’ll explore in this section.

#### 5.4.1. Factory methods

Factory methods are the first reason why you need the `required` keyword. Factory methods are a typical design pattern that facilitates creating instances of a class. You can call these methods on a type, such as a class or a struct (as opposed to an instance), for easy instantiating of preconfigured instances. Here’s an example where you create a `BoardGame` instance or `MutabilityLand` instance via the `make-Game` factory method.

##### Listing 5.20. Factory methods in action

```
let boardGame = BoardGame.makeGame(players: players)
let mutabilityLand = MutabilityLand.makeGame(players: players)
```

Now return to the `BoardGame` superclass where you add the `makeGame` class function.

The `makeGame` method accepts only players and returns an instance of `Self`. `Self` refers to the current type that `makeGame` is called on; this could be `BoardGame` or one of its subclasses.

In a real-world scenario, the board game could be set up with all kinds of settings, such as a time limit and locale, as shown in the following example, adding more benefits to creating a factory method.

##### Listing 5.21. Introducing the `makeGame` factory method

```
class BoardGame {
      // ... snip

    class func makeGame(players: [Player]) -> Self {
        let boardGame = self.init(players: players, numberOfTiles: 32)
        // Configuration goes here.
        // E.g.
        // boardGame.locale = Locale.current
        // boardGame.timeLimit = 900
        return boardGame
    }
}
```

The reason that `makeGame` returns `Self` is that `Self` is different for each subclass. If the method were to return a `BoardGame` instance, `makeGame` wouldn’t be able to return an instance of `MutabilityLand` for example. But you’re not there yet; this gives the following error.

##### Listing 5.22. `required` error

```
constructing an object of class type 'Self' with a metatype value must use a
     'required' initializer
return self.init(players: players, numberOfTiles: 32)
               ~~~~ ^
```

The initializer throws an error because `makeGame` can return `BoardGame` or any subclass instance. Because `makeGame` refers to `self.init`, it needs a guarantee that subclasses implement this method. Adding a `required` keyword to the designated initializer enforces subclasses to implement the initializer, which satisfies this requirement.

First, you add the `required` keyword to the initializer referred to in `makeGame`.

##### Listing 5.23. Adding the `required` keyword to initializers

```
class BoardGame {
      // ... snip

    required init(players: [Player], numberOfTiles: Int) {
        self.players = players
        self.numberOfTiles = numberOfTiles
    }
}
```

Subclasses can now replace `override` with `required` in the related initializer.

##### Listing 5.24. Subclass `required`

```
class MutabilityLand: BoardGame {

      // ... snip

    convenience required init(players: [Player], numberOfTiles: Int) {
        self.init(players: players, instructions: "Read the manual",
     numberOfTiles: numberOfTiles)
    }
}
```

Now the compiler is happy, and you can reap the benefits of factory methods on superclasses and subclasses.

#### 5.4.2. Protocols

Protocols are the second reason the `required` keyword exists.

##### Protocols

We’ll handle protocols in depth in [chapters 7](https://livebook.manning.com/book/swift-in-depth/kindle_split_013.html#ch07), [8](https://livebook.manning.com/book/swift-in-depth/kindle_split_014.html#ch08), [12](https://livebook.manning.com/book/swift-in-depth/kindle_split_018.html#ch12), and [13](https://livebook.manning.com/book/swift-in-depth/kindle_split_019.html#ch13).

When a protocol has an initializer, a class adopting that protocol *must* decorate that initializer with the `required` keyword. Let’s see why and how this works.

First, you introduce a protocol called `BoardGameType`, which contains an initializer.

##### Listing 5.25. Introducing the `BoardGameType` protocol

```
protocol BoardGameType {
    init(players: [Player], numberOfTiles: Int)
}
```

Then you’ll implement this protocol on the `BoardGame` class so that `BoardGame` implements the `init` method from the protocol.

##### Listing 5.26. Implementing the `BoardGameType` protocol

```
class BoardGame: BoardGameType {
// ... snip
```

At this point, the compiler still isn’t happy. Because `BoardGame` conforms to the `BoardGameType` protocol, its subclasses also have to conform to this protocol and implement `init(players:` `[Player],` `numberOfTiles:` `Int)`.

You can again use `required` to force your subclasses to implement this initializer, in precisely the same way as in the previous example.

#### 5.4.3. When classes are final

One way to avoid needing the `required` keyword is by adding the `final` keyword to a class. Making a class final indicates that you can’t subclass it. Making classes final until you explicitly need subclassing behavior can be a good start because adding a `final` keyword helps performance.[[1](https://livebook.manning.com/book/swift-in-depth/chapter-5/ch05fn01)]

1“Increasing Performance by Reducing Dynamic Dispatch” [https://developer.apple.com/swift/blog/?id=27](https://developer.apple.com/swift/blog/?id=27)

If a class is final, you can drop any `required` keywords from the initializers. For example, let’s say nobody likes playing the games that are subclassed, except for the `BoardGame` itself. Now you can make `BoardGame` final and delete any subclasses. Note that you’re omitting the `required` keyword from the designated initializer.

##### Listing 5.27. `BoardGame` is now a final class

```
protocol BoardGameType {
    init(players: [Player], numberOfTiles: Int)
}

final class BoardGame: BoardGameType {                   #1
    let players: [Player]
    let numberOfTiles: Int

    // No need to make this required
    init(players: [Player], numberOfTiles: Int) {        #2
        self.players = players
        self.numberOfTiles = numberOfTiles
    }

    class func makeGame(players: [Player]) -> Self {
        return self.init(players: players, numberOfTiles: 32)
    }

    // ... snip
}
```

Despite implementing the `BoardGameType` protocol and having a `makeGame` factory method, `BoardGame` won’t need any required initializers because it’s a *final* class.

#### 5.4.4. Exercises

1. Would required initializers make sense on structs? Why or why not?
1. Can you name two use cases for needing required initializers?

### 5.5. Closing thoughts

You witnessed how Swift has many types of initializers, each one paired with its own rules and oddities. You noticed how initializers are even more complicated when you’re subclassing. Subclassing may not be popular, yet it can be a viable alternative depending on your background, coding style, and the code that you may inherit when joining an exciting company.

After this chapter, I hope that you feel confident enough to write your initializers without problems and that you’ll be able to offer clean interfaces to get your types initialized.

### Summary

- Structs and classes want all their non-optional properties initialized.
- Structs generate “free” memberwise initializers.
- Structs lose memberwise initializers if you add a custom initializer.
- If you extend structs with your custom initializers, you can have both memberwise and custom initializers.
- Classes must have one or more designated initializers.
- Convenience initializers point to designated initializers.
- If a subclass has its own stored properties, it won’t directly inherit its superclass initializers.
- If a subclass overrides designated initializers, it gets the convenience initializers from the superclass.
- When overriding a superclass initializer with a convenience initializer, a subclass keeps the number of designated initializers down.
- The required keyword makes sure that subclasses implement an initializer and that factory methods work on subclasses.
- Once a protocol has an initializer, the required keyword makes sure that subclasses conform to the protocol.
- By making a class final, initializers can drop the required keyword.

### Answers

1. Will the following initializers work?

let pancakes = Pancakes(syrupType: .corn, stackSize: 8)
let morePancakes = Pancakes(syrupType: .maple)

copy

No. When you use a custom initializer, a memberwise initializer won’t be available.
1. If these initializers didn’t work, can you make them work without adding another initializer?

struct Pancakes {

enum SyrupType {
case corn
case molasses
case maple
}

let syrupType: SyrupType
let stackSize: Int

}

extension Pancakes {                  ***1***

init(syrupType: SyrupType) {      ***2***
self.stackSize = 10
self.syrupType = syrupType
}

}

let pancakes = Pancakes(syrupType: .corn, stackSize: 8)
let morePancakes = Pancakes(syrupType: .maple)
!@%STYLE%@!
{"css":"{\"css\": \"font-weight: bold;\"}","target":"[[{\"line\":13,\"ch\":38},{\"line\":13,\"ch\":39}],[{\"line\":16,\"ch\":25},{\"line\":16,\"ch\":26}],[{\"line\":15,\"ch\":38},{\"line\":15,\"ch\":39}]]"}
!@%STYLE%@!

copy

- ***1* Extend Pancakes.**
- ***2* Put the custom initializer inside the extension.**

1. The following superclass called `Device` registers devices in an office and keeps track of the rooms where these devices can be found. `Television` is one such device that subclasses `Device`. The challenge is to initialize the `Television` subclass with a `Device` initializer. In other words, make the following line of code work by adding a single initializer somewhere:

class Television: Device {

override init(serialNumber: String, room: String) {        ***1***
self.resolution = .unknown
self.screenType = .unknown
super.init(serialNumber: serialNumber, room: room)
}

// ... snip
}
!@%STYLE%@!
{"css":"{\"css\": \"font-weight: bold;\"}","target":"[[{\"line\":2,\"ch\":63},{\"line\":2,\"ch\":64}]]"}
!@%STYLE%@!

copy

- ***1* Override a designated initializer from Device.**

1. Given the following class, which subclasses `Television` from the previous exercise, add two convenience override initializers in the subclassing hierarchy to make this initializer work from the top-most superclass:

class Television {

convenience override init(serialNumber: String, room: String) {  ***1***
self.init(resolution: .unknown, screenType: .unknown,
serialNumber: serialNumber, room: room)
}

// ... snip

}

class HandHeldTelevision: Television {

convenience override init(resolution: Resolution, screenType:
ScreenType, serialNumber: String, room: String) {                 ***2***
self.init(weight: 0, resolution: resolution, screenType:
screenType, serialNumber: "Unknown", room: "UnKnown")
}

// ... snip

}
!@%STYLE%@!
{"css":"{\"css\": \"font-weight: bold;\"}","target":"[[{\"line\":2,\"ch\":69},{\"line\":2,\"ch\":70}],[{\"line\":14,\"ch\":67},{\"line\":14,\"ch\":68}]]"}
!@%STYLE%@!

copy

- ***1* Add a convenience initializer to Television which overrides a designated initializer from Device.**
- ***2* Add a convenience initializer to HandHeldTelevision which overrides a designated initializer from Television.**

1. Would required initializers make sense on structs? Why or why not? No, required initializers enforce initializers on subclasses, and structs can’t be subclassed.
1. Can you name two use cases for required initializers? To enforce factory methods on subclasses and to conform to a protocol defining an initializer.
