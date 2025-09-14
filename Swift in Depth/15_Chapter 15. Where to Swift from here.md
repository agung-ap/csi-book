# Chapter 15. Where to Swift from here

You’ve made it to the end; it’s time to give yourself a big pat on the back! You’ve touched upon many language-specific points and best practices, and you’ve expanded your technical arsenal to attack many different problems in a Swifty way. Even better, you have seen how Swift is a collection of modern and not-so-modern concepts wearing a modern coat. These concepts will stay with you in your programming career. Next time you see an exciting new framework or even a new language you want to learn, you may recognize generics, `map`, `flatMap`, `sum` types, and optionals and apply the concepts straight away. Understanding these core concepts carries more weight than a neat Swift trick or a shiny framework.

I hope that you embraced these concepts and that your day-to-day work has gotten a big quality bump. And I hope that helps you get that interesting job or exciting promotion, or it allows you to get those pull requests merged quicker while teaching others powerful ways to write Swift code.

But what should you do next? Read on for some ideas.

### 15.1. Build frameworks that build on Linux

At the time of writing, Swift has a strong focus on Apple’s OS frameworks, such as iOS, tvOS, and MacOS. These platforms already have tons of frameworks. But the Swift community could use some help in making sure that frameworks also build on Linux. Having Swift code compile for Linux projects will help the community on the server side of things, such as command-line tools, web frameworks, and others. If you’re an iOS developer, creating Linux tools will open up a new world of programming and you’ll touch different concepts. A good start is to make your code work with the Swift Package Manager.

### 15.2. Explore the Swift Package Manager

The Swift Package Manager helps you get up and running and building quickly. First, take a look at the Getting Started guide ([http://mng.bz/XAMG](http://mng.bz/XAMG)).

I also recommend exploring the Package Manager source ([https://github.com/apple/swift-package-manager](https://github.com/apple/swift-package-manager)). The Utility and Basic folders especially have some useful extensions and types you may want to use to speed up your development. One of them is `Result`, which we’ve covered already. Other interesting types are `OrderedSet`, `Version`, or helpers to write command-line tools, such as `ArgumentParser` or `ProgressBar`.

You may also find useful extensions ([http://mng.bz/MWP7](http://mng.bz/MWP7)), such as `flatMap-Value` on `Dictionary`, which transforms a value if it’s not nil.

Unfortunately, the Swift Package Manager is not without its problems. At the time of writing, it doesn’t support iOS for dependency management, and it doesn’t play too well with Xcode. Over time, creating systems applications will get easier and more appealing with the evolution of Package Manager and more frameworks being offered by the community.

### 15.3. Explore frameworks

Another learning exercise is to play with or look inside specific frameworks:

- Kitura—([https://github.com/IBM-Swift/Kitura](https://github.com/IBM-Swift/Kitura))
- Vapor—([https://github.com/vapor/vapor](https://github.com/vapor/vapor))
- SwiftNIO — For low-level networking ([https://github.com/apple/swift-nio](https://github.com/apple/swift-nio))
- TensorFlow for Swift—For machine learning ([https://github.com/tensorflow/swift](https://github.com/tensorflow/swift))

If you’re more interested in metaprogramming, I suggest taking a look at Sourcery ([https://github.com/krzysztofzablocki/Sourcery](https://github.com/krzysztofzablocki/Sourcery)), which is a powerful tool to get rid of boilerplate in your codebase, amongst other things.

### 15.4. Challenge yourself

If you’ve always approached a new application a certain way, perhaps it’s a good time to challenge yourself to try a completely different approach.

For instance, try out true protocol-oriented programming, where you model your applications by starting with protocols. See how far you can get without creating concrete types. You’ll enter the world of abstracts and tricky generic constraints. In the end, you will need a concrete type—such as a class or struct—but perhaps you can make the most of the default implementations on a protocol.

See if you can challenge yourself by using protocols, but at compile time only, which means you’ll be using generics and associated types. It will be harder to work with, but seeing your code compile and watching everything work is very rewarding. Taking a protocol-oriented approach may feel like you’re programming with handcuffs on, but it’ll stretch your thinking and be a fruitful exercise.

Another idea is to avoid protocols altogether. See how far you can get with nothing but enums, structs, and higher-order functions.

#### 15.4.1. Join the Swift evolution

It’s great to see Swift progress every few months with fancy new updates. But you don’t have to watch from the sidelines. You can be part of the conversation of Swift’s evolution and even submit your own proposals for change. It all starts at the Swift evolution Github page ([https://github.com/apple/swift-evolution](https://github.com/apple/swift-evolution)).

#### 15.4.2. Final words

Thank you so much for purchasing and reading this book. I hope your Swift skills have gotten a good boost. Feel free to contact me on Twitter at @tjeerdintveen. See you there!
