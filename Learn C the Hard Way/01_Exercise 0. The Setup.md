## Exercise 0. The Setup

The traditional first exercise, Excercise 0, is where you set up your computer for the rest of this book. In this exercise you’ll install packages and software depending on the type of computer you have.

If you have problems following this exercise, then simply watch the [Exercise 0](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch00.html#ch00) video for your computer and follow along with my setup instructions. That video should demonstrate how to do each step and help you solve any problems that might come up.

### Linux

Linux is most likely the easiest system to configure for C development. For Debian systems you run this command from the command line:

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch00_images.html#p002pro01a)

```bash
$ sudo apt−get install build−essential
```

Here’s how you would install the same setup on an RPM-based Linux like Fedora, RedHat, or CentOS 7:

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch00_images.html#p002pro02a)

```bash
$ sudo yum groupinstall development−tools
```

If you have a different variant of Linux, simply search for “c development tools” and your brand of Linux to find out what’s required. Once you have that installed, you should be able to type:

```bash
$ cc --version
```

to see what compiler was installed. You will most likely have the GNU C Compiler (GCC) installed but don’t worry if it’s a different one from what I use in the book. You could also try installing the Clang C compiler using the *Clang’s Getting Started* instructions for your version of Linux, or searching online if those don’t work.

### Mac OS X

On Mac OS X, the install is even easier. First, you’ll need to either download the latest `XCode` from Apple, or find your install DVD and install it from there. The download will be massive and could take forever, so I recommend installing from the DVD. Also, search online for “installing xcode” for instructions on how to do it. You can also use the App Store to install it just as you would any other app, and if you do it that way you’ll receive updates automatically.

To confirm that your C compiler is working, type this:

```bash
$ cc −−version
```

You should see that you are using a version of the Clang C Compiler, but if your XCode is older you may have GCC installed. Either is fine.

### Windows

For Microsoft Windows, I recommend you use the Cygwin system to acquire many of the standard UNIX software development tools. It should be easy to install and use, but watch the videos for this exercise to see how I do it. An alternative to Cygwin is the MinGW system; it is more minimalist but should also work. I will warn you that Microsoft seems to be phasing out C support in their development tools, so you may have problems using Microsoft’s compilers to build the code in this book.

A slightly more advanced option is to use VirtualBox to install a Linux distribution and run a complete Linux system on your Windows computer. This has the added advantage that you can completely destroy this virtual machine without worrying about destroying your Windows configuration. It’s also an opportunity to learn to use Linux, which is both fun and beneficial to your development as a programmer. Linux is currently deployed as the main operating system for many distributed computer and cloud infrastructure companies. Learning Linux will definitely improve your knowledge of the future of computing.

### Text Editor

The choice of text editor for a programmer is a tough one. For beginners, I say just use Gedit since it’s simple and it works for code. However, it doesn’t work in certain international situations, and if you’ve been programming for a while, chances are you already have a favorite text editor.

With this in mind, I want you to try out a few of the standard programmer text editors for your platform and then stick with the one that you like best. If you’ve been using GEdit and like it, then stick with it. If you want to try something different, then try it out real quick and pick one.

The most important thing is *do not get stuck trying to pick the perfect editor*. Text editors all just kind of suck in odd ways. Just pick one, stick with it, and if you find something else you like, try it out. Don’t spend days on end configuring it and making it perfect.

Some text editors to try out:

• GEdit on Linux and OS X.

• TextWrangler on OS X.

• Nano, which runs in Terminal and works nearly everywhere.

• Emacs and Emacs for OS X; be prepared to do some learning, though.

• Vim and MacVim.

There is probably a different editor for every person out there, but these are just a few of the free ones that I know work. Try out a few of these—and maybe some commercial ones—until you find one that you like.

#### Do Not Use an IDE

---

Warning!

Avoid using an integrated development environment (IDE) while you are learning a language. They are helpful when you need to get things done, but their help tends also to prevent you from really learning the language. In my experience, the stronger programmers don’t use an IDE and also have no problem producing code at the same speed as IDE users. I also find that the code produced with an IDE is of lower quality. I have no idea why that is the case, but if you want deep, solid skills in a programming language, I highly recommend that you avoid IDEs while you’re learning.

Knowing how to use a professional programmer’s text editor is also a useful skill in your professional life. When you’re dependent on an IDE, you have to wait for a new IDE before you can learn the newer programming languages. This adds a cost to your career: It prevents you from getting ahead of shifts in language popularity. With a generic text editor, you can code in any language, any time you like, without waiting for anyone to add it to an IDE. A generic text editor means freedom to explore on your own and manage your career as you see fit.

---

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
1. [Linux](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch00.html#ch00lev1sec1)
1. [Mac OS X](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch00.html#ch00lev1sec2)
1. [Windows](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch00.html#ch00lev1sec3)
1. [Text Editor](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch00.html#ch00lev1sec4)Show More Items

1. [Exercise 1. Dust Off That Compiler](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch01.html)queue27% complete
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
