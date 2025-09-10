## Exercise 1. Dust Off That Compiler

After you have everything installed, you need to confirm that your compiler works. The easiest way to do that is to write a C program. Since you should already know at least one programming language, I believe you can start with a small but extensive example.

`ex1.c`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch01_images.html#p006pro01a)

```
#include <stdio.h>

 2

/* This is a comment. */

int main(int argc, char *argv[])

{

int distance = 100;

 7

// this is also a comment

printf("You are %d miles away.\n", distance);

10

return 0;

}
```

If you have problems getting the code up and running, watch the video for this exercise to see me do it first.

### Breaking It Down

There are a few features of the C language in this code that you might or might not have figured out while you were typing it. I’ll break this down, line by line, quickly, and then we can do exercises to understand each part better. Don’t worry if you don’t understand everything in this breakdown. I am simply giving you a quick dive into C and *promise* you will learn all of these concepts later in the book.

Here’s a line-by-line description of the code:

**ex1.c:1** An `include`, and it is the way to import the contents of one file into this source file. C has a convention of using `.h` extensions for *header* files, which contain lists of functions to use in your program.

**ex1.c:3** This is a multiline `comment`, and you could put as many lines of text between the opening `/*` and closing `*/` characters as you want.

**ex1.c:4** A more complex version of the `main` function you’ve been using so far. How C programs work is that the operating system loads your program, and then it runs the function named `main`. For the function to be totally complete it needs to return an `int` and take two parameters: an `int` for the argument count and an array of `char *` strings for the arguments. Did that just fly over your head? Don’t worry, we’ll cover this soon.

**ex1.c:5** To start the body of any function, you write a `{` character that indicates the beginning of a *block*. In Python, you just did a `:` and indented. In other languages, you might have a `begin` or `do` word to start.

**ex1.c:6** A variable declaration and assignment at the same time. This is how you create a variable, with the syntax `type name = value;`. In C, statements (except for logic) end in a `;` (semicolon) character.

**ex1.c:8** Another kind of comment. It works like in Python or Ruby, where the comment starts at the `//` and goes until the end of the line.

**ex1.c:9** A call to your old friend `printf`. Like in many languages, function calls work with the syntax `name(arg1, arg2);` and can have no arguments or any number of them. The `printf` function is actually kind of weird in that it can take multiple arguments. You’ll see that later.

**ex1.c:11** A return from the main function that gives the operating system (OS) your exit value. You may not be familiar with how UNIX software uses return codes, so we’ll cover that as well.

**ex1.c:12** Finally, we end the main function with a closing brace `}` character, and that’s the end of the program.

There’s a lot of information in this breakdown, so study it line by line and make sure you at least have a grasp of what’s going on. You won’t know everything, but you can probably guess before we continue.

### What You Should See

You can put this into an `ex1.c` and then run the commands shown here in this sample shell output. If you’re not sure how this works, watch the video that goes with this exercise to see me do it.

`Exercise 1 Session`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch01_images.html#p007pro01a)

```bash
$ make ex1

cc -Wall -g    ex1.c  -o ex1

$ ./ex1

You are 100 miles away.

$
```

The first command `make` is a tool that knows how to build C programs (and many others). When you run it and give it `ex1` you are telling `make` to look for the `ex1.c` file, run the compiler to build it, and leave the results in a file named `ex1`. This `ex1` file is an executable that you can run with `./ex1`, which outputs your results.

### How to Break It

In this book, I’m going to have a small section for each program teaching you how to break the program if it’s possible. I’ll have you do odd things to the programs, run them in weird ways, or change code so that you can see crashes and compiler errors.

For this program, simply try removing things at random and still get it to compile. Just make a guess at what you can remove, recompile it, and then see what you get for an error.

### Extra Credit

• Open the `ex1` file in your text editor and change or delete random parts. Try running it and see what happens.

• Print out five more lines of text or something more complex than “hello world.”

• Run `man 3 printf` and read about this function and many others.

• For each line, write out the symbols you don’t understand and see if you can guess what they mean. Write a little chart on paper with your guess so you can check it later to see if you got it right.

![](https://learning.oreilly.com/covers/urn:orm:book:9780133124385/200w/)

### [Learn C the Hard Way: Practical Exercises on the Computational Subjects You Keep Avoiding (Like C)](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/)

[Zed A. Shaw](https://learning.oreilly.com/search/?query=author%3A%22Zed%20A.%20Shaw%22&sort=relevance&highlight=true)

Published byAddison-Wesley Professional17% completeContent Progress 17% completedApprox. 8 hours left1. [About This eBook](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/pref00.html)queue100% completecheckmark circle
1. [Title Page](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/title.html)queue
1. [Copyright Page](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/copyright.html)queue
1. [Contents](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/toc.html)queue
1. [Acknowledgments](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/pref02.html)queue100% completecheckmark circle
1. [This Book Is Not Really about C](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/pref03.html)queue100% completecheckmark circle
1. [Exercise 0. The Setup](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch00.html)queue100% completecheckmark circle
1. [Exercise 1. Dust Off That Compiler](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch01.html)queue27% complete
1. [Breaking It Down](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch01.html#ch01lev1sec1)
1. [What You Should See](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch01.html#ch01lev1sec2)
1. [How to Break It](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch01.html#ch01lev1sec3)
1. [Extra Credit](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch01.html#ch01lev1sec4)

1. [Exercise 2. Using Makefiles to Build](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch02.html)queue24% complete
1. [Exercise 3. Formatted Printing](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch03.html)queue24% complete
1. [Exercise 4. Using a Debugger](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch04.html)queue100% completecheckmark circle
1. [Exercise 5. Memorizing C Operators](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch05.html)queue78% complete
1. [Exercise 6. Memorizing C Syntax](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch06.html)queue34% complete
1. [Exercise 7. Variables and Types](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch07.html)queue26% complete
1. [Exercise 8. If, Else-If, Else](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch08.html)queue31% complete
1. [Exercise 9. While-Loop and Boolean Expressions](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch09.html)queue45% complete
1. [Exercise 10. Switch Statements](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch10.html)queue41% complete
1. [Exercise 11. Arrays and Strings](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch11.html)queue22% complete
1. [Exercise 12. Sizes and Arrays](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch12.html)queue39% complete
1. [Exercise 13. For-Loops and Arrays of Strings](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch13.html)queue21% complete
1. [Exercise 14. Writing and Using Functions](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch14.html)queue25% complete
1. [Exercise 15. Pointers, Dreaded Pointers](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch15.html)queue12% complete
1. [Exercise 16. Structs And Pointers to Them](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch16.html)queue14% complete
1. [Exercise 17. Heap and Stack Memory Allocation](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch17.html)queue9% complete
1. [Exercise 18. Pointers to Functions](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch18.html)queue12% complete
1. [Exercise 19. Zed’s Awesome Debug Macros](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch19.html)queue19% complete
1. [Exercise 20. Advanced Debugging Techniques](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch20.html)queue26% complete
1. [Exercise 21. Advanced Data Types and Flow Control](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch21.html)queue46% complete
1. [Exercise 22. The Stack, Scope, and Globals](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch22.html)queue10% complete
1. [Exercise 23. Meet Duff’s Device](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch23.html)queue16% complete
1. [Exercise 24. Input, Output, Files](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch24.html)queue15% complete
1. [Exercise 25. Variable Argument Functions](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch25.html)queue16% complete
1. [Exercise 26. Project logfind](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch26.html)queue69% complete
1. [Exercise 27. Creative and Defensive Programming](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch27.html)queue7% complete
1. [Exercise 28. Intermediate Makefiles](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch28.html)queue9% complete
1. [Exercise 29. Libraries and Linking](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch29.html)queue
1. [Exercise 30. Automated Testing](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch30.html)queue13% complete
1. [Exercise 31. Common Undefined Behavior](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch31.html)queue56% complete
1. [Exercise 32. Double Linked Lists](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch32.html)queue7% complete
1. [Exercise 33. Linked List Algorithms](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch33.html)queue10% complete
1. [Exercise 34. Dynamic Array](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch34.html)queue12% complete
1. [Exercise 35. Sorting and Searching](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch35.html)queue5% complete
1. [Exercise 36. Safer Strings](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch36.html)queue19% complete
1. [Exercise 37. Hashmaps](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch37.html)queue7% complete
1. [Exercise 38. Hashmap Algorithms](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch38.html)queue10% complete
1. [Exercise 39. String Algorithms](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch39.html)queue7% complete
1. [Exercise 40. Binary Search Trees](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch40.html)queue5% complete
1. [Exercise 41. Project devpkg](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch41.html)queue14% complete
1. [Exercise 42. Stacks and Queues](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch42.html)queue100% completecheckmark circle
1. [Exercise 43. A Simple Statistics Engine](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch43.html)queue47% complete
1. [Exercise 44. Ring Buffer](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch44.html)queue15% complete
1. [Exercise 45. A Simple TCP/IP Client](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch45.html)queue14% complete
1. [Exercise 46. Ternary Search Tree](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch46.html)queue
1. [Exercise 47. A Fast URL Router](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch47.html)queue15% complete
1. [Exercise 48. A Simple Network Server](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch48.html)queue67% complete
1. [Exercise 49. A Statistics Server](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch49.html)queue57% complete
1. [Exercise 50. Routing the Statistics](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch50.html)queue100% completecheckmark circle
1. [Exercise 51. Storing the Statistics](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch51.html)queue69% complete
1. [Exercise 52. Hacking and Improving Your Server](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch52.html)queue100% completecheckmark circle
1. [Next Steps](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/app01.html)queue100% completecheckmark circle
1. [Index](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/index.html)queue2% complete
1. [Where are the Companion Content Files?](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/app03.html)queue100% completecheckmark circle
1. [Code Snippets](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch00_images.html)queue100% completecheckmark circle
