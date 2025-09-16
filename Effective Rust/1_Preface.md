# Preface

The code is more what you’d call *guidelines* than actual rules.

Hector Barbossa

In the crowded landscape of modern programming languages, Rust is different.  Rust offers the speed of a compiled
language, the efficiency of a non-garbage-collected language, and the type safety of a functional language—as well as a unique solution to memory safety problems.  As a result, Rust [regularly polls as the most loved programming language](https://oreil.ly/KKcb6).

The strength and consistency of Rust’s type system means that if a Rust program compiles, there is already a decent
chance that it will work—a phenomenon previously observed only with more academic, less accessible languages
such as Haskell.  If a Rust program compiles, it will also work *safely*.

This safety—both type safety and memory safety—does come with a cost, though.  Despite the quality of
the basic documentation, Rust has a reputation for having a steep on-ramp, where newcomers have to go through the
initiation rituals of fighting the  borrow checker, redesigning their data structures, and being befuddled by
lifetimes. A Rust program that compiles may have a good chance of working the first time, but the struggle to get it to
compile is real—even with the Rust compiler’s remarkably helpful error diagnostics.

# Who This Book Is For

This book tries to help with these areas where programmers struggle, even if they already have experience with an
existing compiled language like C++. As such—and in common with other *Effective <Language>*
books—this book is intended to be the *second* book that a newcomer to Rust might need, after they have already
encountered the basics elsewhere—for example, in [The Rust Programming Language](https://doc.rust-lang.org/book/) (Steve Klabnik and Carol Nichols, No Starch Press) or  [Programming Rust](https://www.oreilly.com/library/view/programming-rust-2nd/9781492052586/) (Jim Blandy et al., O’Reilly).

However, Rust’s safety leads to a slightly different slant to the Items here, particularly when compared to  Scott Meyers’s original *Effective C++* series.  The C++ language was (and is) full of footguns, so *Effective
C++* focused on a collection of advice for avoiding those footguns, based on real-world experience creating software in C++. Significantly, it contained *guidelines* not rules, because guidelines have exceptions—providing the
detailed rationale for a guideline allows readers to decide for themselves whether their particular scenario warranted
breaking the rule.

The general style of giving advice together with the *reasons* for that advice is preserved here. However, since Rust
is remarkably free of footguns, the Items here concentrate more on the concepts that Rust introduces. Many Items
have titles like *“Understand…”* and *“Familiarize yourself with…”*, and help on the journey toward
writing fluent, idiomatic Rust.

Rust’s safety also leads to a complete absence of Items titled *“Never…”*. If you really should never do
something, the compiler will generally prevent you from doing it.

# Rust Version

The text is written for the  [2018 edition of Rust](https://doc.rust-lang.org/edition-guide/rust-2018/index.html),
using the stable toolchain.  Rust’s  back-compatibility
[promises](https://oreil.ly/husN4) mean that any later edition of Rust, including the
[2021 edition](https://doc.rust-lang.org/edition-guide/rust-2021/index.html), will still support code written for
the 2018 edition, even if that later edition introduces breaking changes.  Rust is now also stable enough that the
differences between the 2018 and 2021 editions are minor; none of the code in the book needs altering to be 2021-edition
compliant (but [Item 19](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_reflection_md) includes one exception in which a later version of Rust allows new behavior that wasn’t previously
possible).

The Items here do not cover any aspects of Rust’s [async functionality](https://oreil.ly/a9r1B), as
this involves more advanced concepts and less stable toolchain support—there’s already enough ground to cover
with synchronous Rust.  Perhaps an *Effective Async Rust* will emerge in the future…

The specific `rustc` version used for code fragments and error messages is 1.70.  The code fragments are
unlikely to need changes for later versions, but the error messages may vary with your particular compiler version.
The error messages included in the text have also been manually edited to fit within the width constraints of the book
but are otherwise as produced by the compiler.

The text has a number of references to and comparisons with other statically typed languages, such as Java, Go, and C++,
to help readers with experience in those languages orient themselves.  (C++ is probably the closest equivalent language,
particularly when  C++11’s move semantics come into play.)

# Navigating This Book

The Items that make up the book are divided into six chapters:

Chapter 1, “Types”Suggestions that revolve around Rust’s core type system

Chapter 2, “Traits”Suggestions for working with Rust’s traits

Chapter 3, “Concepts”Core ideas that form the design of Rust

Chapter 4, “Dependencies”Advice for working with Rust’s package ecosystem

Chapter 5, “Tooling”Suggestions for improving your codebase by going beyond just the Rust compiler

Chapter 6, “Beyond Standard Rust”Suggestions for when you have to work beyond Rust’s standard,
safe environment

Although the “Concepts” chapter is arguably more fundamental than the “Types” and “Traits” chapters, it is deliberately
placed later in the book so that readers who are reading from beginning to end can build up some confidence first.

# Conventions Used in This Book

The following typographical conventions are used in this book:

ItalicIndicates new terms, URLs, email addresses, filenames, and file extensions.

Constant widthUsed for program listings, as well as within paragraphs to refer to program elements such as variable or function names, databases, data types, environment variables, statements, and keywords.

#

```
// Marks code samples that do not compile
```

#

```
// Marks code samples that exhibit undesired behavior
```

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
- [https://www.oreilly.com/about/contact.html](https://www.oreilly.com/about/contact.html)

We have a web page for this book, where we list errata, examples, and any additional information. You can access this page at [https://oreil.ly/effective-rust](https://oreil.ly/effective-rust).

For news and information about our books and courses, visit [https://oreilly.com](https://oreilly.com/).

Find us on LinkedIn: [https://linkedin.com/company/oreilly-media](https://linkedin.com/company/oreilly-media).

Watch us on YouTube: [https://youtube.com/oreillymedia](https://youtube.com/oreillymedia).

# Acknowledgments

My thanks go to the people who helped make this book possible:

-

The technical reviewers who gave expert and detailed feedback on all aspects of the text: Pietro Albini, Jess Males,
Mike Capp, and especially Carol Nichols.

-

My editors at O’Reilly: Jeff Bleiel, Brian Guerin, and Katie Tozer.

-

Tiziano Santoro, from whom I originally learned many things about Rust.

-

Danny Elfanbaum, who provided vital technical assistance for dealing with the AsciiDoc formatting of the book.

-

Diligent readers of the original web version of the book, in particular:

-

Julian Rosse, who spotted dozens of typos and other errors in the online text.

-

Martin Disch, who pointed out potential improvements and inaccuracies in several Items.

-

Chris Fleetwood, Sergey Kaunov, Clifford Matthews, Remo Senekowitsch, Kirill Zaborsky, and an anonymous Proton Mail
user, who pointed out mistakes in the text.

-

My family, who coped with many weekends when I was distracted by writing.
