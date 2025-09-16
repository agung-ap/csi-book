# Preface

# What Is Async Rust?

*Asynchronous programming in Rust*, often referred to as *Async Rust*, is a powerful paradigm that allows developers to write concurrent code that is more efficient and scalable. In contrast to traditional synchronous programming, where tasks are executed one after another, async programming enables tasks to run concurrently, which is particularly useful when dealing with I/O-bound operations like network requests or file handling. This approach allows for the efficient use of system resources and can lead to significant performance improvements in applications that need to handle multiple tasks at once without the need for additional cores.

Rust’s type system and ownership model provide the safety guarantees that we all love. However, mastering async Rust requires an understanding of specific concepts, such as futures, pinning, and executors. This book will guide you through these concepts, equipping you with the knowledge needed to apply async to your own projects and programs.

# Who Is This Book For?

This book is aimed at intermediate Rust developers who want to learn how to improve their applications and programs by using the range of asynchronous functionality available to them.

If you are new to Rust or programming in general, this book may not be the best starting point. Instead, we recommend the following resources for learning Rust from the ground up:

-

[The Rust Programming Language](https://oreil.ly/3M49T) by Steve Klabnik and Carol Nichols (No Starch Press, 2022).

-

*Rust Web Programming* by Maxwell Flitton (Packt Publishing, 2023)

-

[Rust by Example](https://oreil.ly/w_CHT), a collection of online runnable examples written by the Rust community

# Overview of the Chapters

[Chapter 1, “Introduction to Async”](https://learning.oreilly.com/library/view/async-rust/9781098149086/ch01.html#ch01), gives a high-level overview of what async programming is and how it can be useful in particular types of programs—for example, for I/O operations. This chapter also explores threads and processes to explain the context in which async programming is implemented in relation to the operating system.

[Chapter 2, “Basic Async Rust”](https://learning.oreilly.com/library/view/async-rust/9781098149086/ch02.html#ch02), delves into the basics of async programming in Rust, looking at what a future is and why pinning and context are needed to implement async Rust. We’ll finish off with examples of basic data sharing between futures. This chapter will enable you to write basic async futures, implement the `Future` trait, and run async code.

[Chapter 3, “Building Our Own Async Queues”](https://learning.oreilly.com/library/view/async-rust/9781098149086/ch03.html#ch03), puts together the information from the previous two chapters to create our own queue, where we implement passing tasks to different queues and stealing tasks. We create our own join macros and do some basic configuration of our runtime. This chapter shows how async tasks are passed through an async runtime and processed.

[Chapter 4, “Integrating Networking into
Our Own Async Runtime”](https://learning.oreilly.com/library/view/async-rust/9781098149086/ch04.html#ch04), is a relatively complicated chapter that drills down into what an executor and connector are and how to create a program that can do networking. We also get into *mio* and how to use sockets. This builds on the previous chapter, but feel free to skip this chapter if it is too challenging early on and come back to it later. This chapter shows how to integrate networking primitives into an async runtime.

[Chapter 5, “Coroutines”](https://learning.oreilly.com/library/view/async-rust/9781098149086/ch05.html#ch05), introduces coroutines and how to implement them in Rust. We draw the parallels between `async`/`await` and coroutines and implement a basic generator in Rust. This chapter also shows how async tasks are essentially coroutines by building async functionality without any extra threads.

[Chapter 6, “Reactive Programming”](https://learning.oreilly.com/library/view/async-rust/9781098149086/ch06.html#ch06), introduces reactive programming within the context of async Rust. We look at a heater system and build a simple example of a reactive system. We end the chapter learning how to create an event bus.

[Chapter 7, “Customizing Tokio”](https://learning.oreilly.com/library/view/async-rust/9781098149086/ch07.html#ch07), does what it says on the tin. This chapter guides you through customizing your *Tokio* setup to solve your particular problem. We cannot cover the whole of *Tokio*, which is an extensive library, but we do go through building a runtime, local pools, and graceful shutdowns. With this chapter, you get to achieve fine-grained control of how your *Tokio* async tasks are processed, including pinning async tasks to specific threads so those tasks can reference the state of that thread when being polled to completion.

[Chapter 8, “The Actor Model”](https://learning.oreilly.com/library/view/async-rust/9781098149086/ch08.html#ch08), illustrates the power of async as we build our own actor system. We look at the differences between actors and mutuxes and why actors are a helpful design pattern to know. We build a basic key-value storage mechanism using actors so you can get a feel for the design and monitoring of actors.

[Chapter 9, “Design Patterns”](https://learning.oreilly.com/library/view/async-rust/9781098149086/ch09.html#ch09), is a brief overview of some of the common design patterns that work well within an async system. We take an isolated modular approach and apply various design patterns to highlight their benefits and pitfalls. This chapter enables you to integrate async code with existing synchronous codebases.

[Chapter 10, “Building an Async Server with
No Dependencies”](https://learning.oreilly.com/library/view/async-rust/9781098149086/ch10.html#ch10), brings together a lot of the content from the preceding chapters. We get into building our own async system, including our own executor and waker, using the standard library only. It is always helpful to be able to build from scratch if needed, and this chapter highlights some of the benefits and downsides of using a library.

[Chapter 11, “Testing”](https://learning.oreilly.com/library/view/async-rust/9781098149086/ch11.html#ch11), introduces testing an async system. We look at mocking, standard testing, and *Tokio* testing capabilities. We also consider what are we testing for—deadlocks and data races—so we can write clearer and useful tests.

# Conventions Used in This Book

The following typographical conventions are used in this book:

ItalicIndicates new terms, URLs, email addresses, filenames, and file extensions.

Constant widthUsed for program listings, as well as within paragraphs to refer to program elements such as variable or function names, databases, data types, environment variables, statements, and keywords.

###### Tip

This element signifies a tip or suggestion.

###### Note

This element signifies a general note.

###### Warning

This element indicates a warning or caution.

# O’Reilly Online Learning

###### Note

For more than 40 years, [O’Reilly Media](https://oreilly.com/) has provided technology and business training, knowledge, and insight to help companies succeed.

Our unique network of experts and innovators share their knowledge and expertise through books, articles, and our online learning platform. O’Reilly’s online learning platform gives you on-demand access to live training courses, in-depth learning paths, interactive coding environments, and a vast collection of text and video from O’Reilly and 200+ other publishers. For more information, visit [https://oreilly.com](https://oreilly.com/).

# How to Contact Us

Please address comments and questions concerning this book to the publisher:

- O’Reilly Media, Inc.
- 1005 Gravenstein Highway North
- Sebastopol, CA 95472
- 800-889-8969 (in the United States or Canada)
- 707-827-7019 (international or local)
- 707-829-0104 (fax)
- [support@oreilly.com](mailto:support@oreilly.com)
- [https://oreilly.com/about/contact.html](https://oreilly.com/about/contact.html)

We have a web page for this book, where we list errata, examples, and any additional information. You can access this page at [https://oreil.ly/async-rust](https://oreil.ly/async-rust).

For news and information about our books and courses, visit [https://oreilly.com](https://oreilly.com/).

Find us on LinkedIn: [https://linkedin.com/company/oreilly-media](https://linkedin.com/company/oreilly-media).

Watch us on YouTube: [https://youtube.com/oreillymedia](https://youtube.com/oreillymedia).

# Acknowledgments

We have had a huge amount of support from so many people through the process of writing this book. Thank you so much to everyone who helped us to make it a reality. We would like to give an especially big thanks to the following people:

First, the people of O’Reilly—in particular, Melissa Potter, Jonathon Owen, and Brian Guerin—for your feedback and encouragement throughout the whole book cycle.

Thank you to our technical reviewers, Glen De Cauwsemaecker, Allen Wyma, and Julio Merino. Thanks for the hours you put in to make this book better for our audience.

We would both like to thank the people at SurrealDB who have supported both of us during the writing of this book. In particular, thank you to Tobie Morgan Hitchcock, Jaime Morgan Hitchcock, Kirstie Marsh, Lizzie Holmes, Charli Baptie, Ned Rudkins-Stow, Meriel Cunningham, and many others for support on this journey.

Thank you to Harry Tsiligiannis, an amazing DevOps engineer who took the time to teach both of us about how to build a robust system. We learned a lot from you, and your knowledge has immensely improved our programming skills and our approach to problems.

## Maxwell

My output would not have been possible without the extensive support I get from my family. My wife, Melanie Zhang, has been an amazing supportive partner in this journey, alongside raising our son, Henry Flitton, together. My mother, Allison Barson, and Mel’s mother, Ping Zhang, have also been incredible in the amount of support they have given me when writing my books. They are mentioned here because without them, I would not have been able to write this book.

The engineering team at SurrealDB has been amazing, and I have learned so much from them. Emmanuel Keller has never ceased to teach me something new and has not held back on the time spent to help me. Hugh Kaznowski has always been open in bouncing around ideas over coffee and has pushed me to think deeply about approaches. Mees Delzenne has shown me innovative ways to structure Rust code. Alexander Fridriksson and Obinna Ekwuno have shown me again and again how to structure a message and convey information to developers. Ignacio Paz has been invaluable at showing me how to collaborate with people who have different perspectives and priorities. Corrado Bogni has never hesitated to show me how to carry out a task in style. Ned Rudkins-Stow taught me how to keep refining something until it’s ready to be presented. Micha de Vries has repeatedly demonstrated that you can never have too much energy when approaching work. Jaime Morgan Hitchcock has shown me that sleep is essential for a human to function properly and succeed; in short, don’t follow Jaime’s example. Salvador Girones Gil has taught me that if you break a huge task into small jobs, you can achieve the unthinkable in a short time, as he has led the cloud development at SurrealDB at a shocking pace. Raphael Darley has been a reminder that you can juggle multiple things at once, as he studies computer science full-time at Oxford University, while working with us at SurrealDB and running his own company. I’m also grateful to Mark Gyles and Paz Macdonald, who remind me of the human element when communicating and engaging with developers and communities. Finally, Tobie Morgan Hitchcock has been an inspiration in coming up with an idea, fleshing out the details, and delivering on that idea as he turned his Oxford University thesis into the basis of SurrealDB.

And a special thanks to Caroline Morton for always having my back on all the projects we tackle together, and Professor Christos Bergeles for supporting my studies and projects in bioengineering with Rust.

## Caroline

To my mum, Margaret Morton, and her partner, Jacques Lumb, thank you for your incredible support and constant care throughout this process. Your kindness has been a source of strength for me.

This book would not have been possible without the companionship and encouragement of my wonderful friends. In no particular order, I am deeply grateful to Tabitha Grimshaw and Emma Laurence, who have cheered me on and taken me out for much-needed breaks. I would also like to thank Professor Rohini Mathur and Dr. Kate Mansfield for their company, guidance, and support and Dr. Marie Spreckley for being a trusted sounding board. A special thank you to Dr. Rob Johnson, a great longtime friend, who has always encouraged me to think clearly and articulate my thoughts. Dr. Jo Horsburgh, thank you for your unwavering support; and Kristen Petit, one of my oldest friends, your boundless enthusiasm has always lifted my spirits. I am immensely grateful to Professor Sue Smith, who took a chance and gave me my first academic job, setting me on this path. You embody what a great leader should be—kind, knowledgeable, and without ego.

This book is dedicated to my dad, Michael Frank Morton, who was taken from us too soon. I also want to remember my dear aunt, Marilyn Bickerton, who we lost too early. In her memory, I encourage everyone to support ALS research.

Finally, thank you to Maxwell for inviting me on this journey! It would not have been possible without you. Your depth of knowledge and expertise continue to surprise and amaze me. Thank you for all your hard work!
