## Exercise 6. Memorizing C Syntax

After learning the operators, it’s time to memorize the keywords and basic syntax structures you’ll be using. Trust me when I tell you that the small amount of time spent memorizing these things will pay huge dividends later as you go through the book.

As I mentioned in [Exercise 5](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch05.html#ch05), you don’t have to stop reading the book while you memorize these things. You can and should do both. Use your flash cards as a warm up before coding that day. Take them out and drill on them for 15–30 minutes, then sit down and do some more exercises in the book. As you go through the book, try to use the code you’re typing as more of a way to practice what you’re memorizing. One trick is to build a pile of flash cards containing operators and keywords that you don’t immediately recognize while you’re coding. After you’re done for the day, practice those flash cards for another 15–30 minutes.

Keep this up and you’ll learn C much faster and more solidly than you would if you just stumbled around typing code until you memorized it secondhand.

### The Keywords

The *keywords* of a language are words that augment the symbols so that the language reads well. There are some languages like APL that don’t really have keywords. There are other languages like Forth and LISP that are almost nothing but keywords. In the middle are languages like C, Python, Ruby, and many more that mix sets of keywords with symbols to create the basis of the language.

---

Warning!

The technical term for processing the symbols and keywords of a programming language is *lexical analysis*. The word for one of these symbols or keywords is a *lexeme*.

---

![Image](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780133124385/files/graphics/026tab01.jpg)

![Image](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780133124385/files/graphics/026tab01a.jpg)

### Syntax Structures

I suggest you memorize those keywords, as well as memorizing the syntax structures. A *syntax structure* is a pattern of symbols that make up a C program code form, such as the form of an `if-statement` or a `while-loop`. You should find most of these familiar, since you already know one language. The only trouble is then learning how C does it.

Here’s how you read these:

**1.** Anything in `ALLCAPS` is meant as a replacement spot or hole.

**2.** Seeing `[ALLCAPS]` means that part is optional.

**3.** The best way to test your memory of syntax structures is to open a text editor, and where you see `switch-statement`, try to write the code form after saying what it does.

An `if-statement` is your basic logic branching control:

```
if(TEST) {

    CODE;

} else if(TEST) {

    CODE;

} else {

    CODE;

}
```

A `switch-statement` is like an `if-statement` but works on simple integer constants:

```
switch (OPERAND) {

    case CONSTANT:

        CODE;

        break;

    default:

        CODE;

}
```

A `while-loop` is your most basic loop:

```
while(TEST) {

    CODE;

}
```

You can also use `continue` to cause it to loop. Call this form `while-continue-loop` for now:

```
while(TEST) {

    if(OTHER_TEST) {

        continue;

    }

    CODE;

}
```

You can also use `break` to exit a loop. Call this form `while-break-loop`:

```
while(TEST) {

    if(OTHER_TEST) {

        break;

    }

    CODE;

}
```

The `do-while-loop` is an inverted version of a `while-loop` that runs the code *then* tests to see if it should run again:

```
do {

    CODE;

} while(TEST);
```

It can also have `continue` and `break` inside to control how it operates.

The `for-loop` does a controlled counted loop through a (hopefully) fixed number of iterations using a counter:

```
for(INIT; TEST; POST) {

    CODE;

}
```

An `enum` creates a set of integer constants:

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch06_images.html#p029pro01a)

```
enum { CONST1, CONST2, CONST3 } NAME;
```

A `goto` will jump to a label, and is only used in a few useful situations like error detection and exiting:

```
if(ERROR_TEST) {

    goto fail;

}



fail:

    CODE;
```

A `function` is defined this way:

```
TYPE NAME(ARG1, ARG2, ..) {

    CODE;

    return VALUE;

}
```

That may be hard to remember, so try this example to see what’s meant by `TYPE`, `NAME`, `ARG` and `VALUE`:

```
int name(arg1, arg2) {

    CODE;

    return 0;

}
```

A `typedef` defines a new type:

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch06_images.html#p030pro01a)

```
typedef DEFINITION IDENTIFIER;
```

A more concrete form of this is:

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch06_images.html#p030pro02a)

```
typedef unsigned char byte;
```

Don’t let the spaces fool you; the `DEFINITION` is `unsigned char` and the `IDENTIFIER` is `byte` in that example.

A `struct` is a packaging of many base data types into a single concept, which are used heavily in C:

```
struct NAME {

    ELEMENTS;

} [VARIABLE_NAME];
```

The `[VARIABLE_NAME]` is optional, and I prefer not to use it except in a few small cases. This is commonly combined with `typedef` like this:

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch06_images.html#p030pro03a)

```
typedef struct [STRUCT_NAME] {

    ELEMENTS;

} IDENTIFIER;
```

Finally, `union` creates something like a `struct`, but the elements will overlap in memory. This is strange to understand, so simply memorize the form for now:

```
union NAME {

    ELEMENTS;

} [VARIABLE_NAME];
```

### A Word of Encouragement

Once you’ve created flash cards for each of these, drill on them in the usual way by starting with the name side, and then reading the description and form on the other side. In the video for this exercise, I show you how to use Anki to do this efficiently, but you can replicate the experience with simple index cards, too.

I’ve noticed some fear or discomfort in students who are asked to memorize something like this. I’m not exactly sure why, but I encourage you to do it anyway. Look at this as an opportunity to improve your memorization and learning skills. The more you do it, the better at it you get and the easier it gets.

It’s normal to feel discomfort and frustration. Don’t take it personally. You might spend 15 minutes and simply *hate* doing it and feel like a total failure. This is normal, and it doesn’t mean you actually are a failure. Perseverance will get you past the initial frustration, and this little exercise will teach you two things:

**1.** You can use memorization as a self-evaluation of your competence. Nothing tells you how well you really know a subject like a memory test of its concepts.

**2.** The way to conquer difficulty is a little piece at a time. Programming is a great way to learn this because it’s so easy to break down into small parts and focus on what’s lacking. Take this as an opportunity to build your confidence in tackling large tasks in small pieces.

### A Word of Warning

I’ll add a final word of warning about memorization. Memorizing a large quantity of facts doesn’t automatically make you good at applying those facts. You can memorize the entire ANSI C standards document and still be a terrible programmer. I’ve encountered many *supposed* C experts who know every square inch of standard C grammar but still write terrible, buggy, weird code, or don’t code at all.

Never confuse an ability to regurgitate memorized facts with ability to actually do something well. To do that you need to apply these facts in different situations until you know how to use them. That’s what the rest of this book will help you do.
