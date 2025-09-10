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
