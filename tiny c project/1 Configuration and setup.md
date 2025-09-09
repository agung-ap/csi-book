# [](/book/tiny-c-projects/chapter-1/)1 Configuration and setup

[](/book/tiny-c-projects/chapter-1/)This first chapter is purely optional. If you already know how to build C code, especially if you’re familiar with working at the command prompt, stop wasting time and merrily skip up to chapter 2. Otherwise, slug it out and

-  [](/book/tiny-c-projects/chapter-1/)Review the C language development cycle
-  [](/book/tiny-c-projects/chapter-1/)Use an integrated development environment (IDE) to build code
-  [](/book/tiny-c-projects/chapter-1/)Explore the excitement of command-line programming in a terminal window, just like Grandpa did
-  [](/book/tiny-c-projects/chapter-1/)Review options for linking in libraries and supplying command-line arguments

[](/book/tiny-c-projects/chapter-1/)The purpose of this material is for review, though if you’ve never used a command line to program, you’re in for a treat: I find command-line programming to be fast and easy, specifically for the tiny programs created in this book. This code is well suited for the command-line environment.

[](/book/tiny-c-projects/chapter-1/)Still reading? Good. This chapter serves as a review when your C programming skills are rusty or if you just want to confirm that what you know is up to par for successfully navigating the rest of the book. I appreciate that you’re still here. Otherwise, these pages would be blank.

[](/book/tiny-c-projects/chapter-1/)And why do skills get rusty? Is it the iron and oxygen? The field of computer jargon needs to plant new terms for poor skills, something highly offensive and obnoxious to the point of being widely accepted. I’ll ruminate on the topic, and maybe add a quiz question along these lines at the end of the chapter.

The C development cycle

[](/book/tiny-c-projects/chapter-1/)According [](/book/tiny-c-projects/chapter-1/)to ancient Mesopotamian tablets currently on display in the British Museum, four steps are taken to develop a C language program. These are illustrated in figure 1.1, where you can plainly see the C development cycle written in cuneiform.

![Figure 1.1 The C development cycle, courtesy of the British Museum](https://drek4537l1klr.cloudfront.net/gookin/Figures/01-01.png)

[](/book/tiny-c-projects/chapter-1/)As a review, and because neither of us knows Babylonian, here is the translation:

1.  [](/book/tiny-c-projects/chapter-1/)Start by creating the source code file.
1.  [](/book/tiny-c-projects/chapter-1/)Compile the source code into object code.
1.  [](/book/tiny-c-projects/chapter-1/)Link in a library to create a program file.
1.  [](/book/tiny-c-projects/chapter-1/)Finally, run the program for testing, disappointment, or delight.

[](/book/tiny-c-projects/chapter-1/)Step 4 is a rather liberal translation on my part. The original reads, “Run the program and rejoice by consuming a cow.” I have also omitted references to pagan deities.

[](/book/tiny-c-projects/chapter-1/)These steps present a simple overview of the process. The steps are more numerous due to inevitable errors, bugs, booboos, and lack of cows. The following sections describe the details.

### [](/book/tiny-c-projects/chapter-1/)1.1.1 Editing source code

[](/book/tiny-c-projects/chapter-1/)C [](/book/tiny-c-projects/chapter-1/)language source code is plain text. What makes the file a C source code file and not a boring ol’ text file is the .c filename extension; all C source code files use this filename extension. Eyeball code uses the .see extension. Naval code uses .sea. Know the difference.

[](/book/tiny-c-projects/chapter-1/)Use a text editor to craft your source code. Do not use a word processor, which is like using a helicopter to prune a tree. Don’t let the exciting visual image dissuade you; your goal is to use the best tool for the job. Any plain-text editor works, though the good ones offer features like color-coding, pattern matching, and other swanky features that make the process easier. I prefer the VIM text editor, which is available at [vim.org](https://www.vim.org/). VIM is available as a both a text mode (terminal window) program and a GUI or windowed version.

[](/book/tiny-c-projects/chapter-1/)IDEs feature a built-in text editor, which is the point of the I in IDE: integrated. This editor is what you’re stuck with unless an option is available to change it. For example, in Visual Studio Code, you can obtain an extension to bring your favorite editor commands into the IDE.

[](/book/tiny-c-projects/chapter-1/)As a tip, the .c file extension defines a C language source code filetype, which is often associated by the operating system with your IDE. On my system, I associate .c files with my favorite VIM text editor. This trick allows me to double-click a C source code file icon and have it open in my text editor as opposed to having the IDE [](/book/tiny-c-projects/chapter-1/)load.

### [](/book/tiny-c-projects/chapter-1/)1.1.2 Compiling, linking, building

[](/book/tiny-c-projects/chapter-1/)After [](/book/tiny-c-projects/chapter-1/)[](/book/tiny-c-projects/chapter-1/)[](/book/tiny-c-projects/chapter-1/)writing the source code, you build the program. This process combines two original steps that only a handful of programmers at the Old Coder’s Home remember: compiling and linking. Most code babies today just think of compiling, but linking is still in there somewhere.

[](/book/tiny-c-projects/chapter-1/)After the source code file is as perfect as you can imagine, you compile it into object code: the compiler consumes the text in the source code file, churns through it, and spews forth an object code file. Object code files traditionally have a .o (“dot-oh”) filename extension unless your compiler or IDE opts for the heretical .obj extension.

[](/book/tiny-c-projects/chapter-1/)Items in your source code that offend the compiler are flagged as warnings or errors. An error terminates the process with an appropriately rude but helpful message. A warning may also thwart the creation of object code, but often the compiler shrugs its shoulders and creates an object code file anyway, figuring you’re smart enough to go back and fix the problem. You probably aren’t, which is why I admonish you to always take compiler warnings seriously.

[](/book/tiny-c-projects/chapter-1/)Object code is linked or combined with the C library file to build a program. Any errors halt the process, which must be addressed by re-editing the source code, compiling, and linking again.

[](/book/tiny-c-projects/chapter-1/)These days, the original separate steps of compiling and linking are combined into a single step called building. Compiling and linking still take place. No matter how many steps it takes, the result is the creation of a program.

[](/book/tiny-c-projects/chapter-1/)Run the program.

[](/book/tiny-c-projects/chapter-1/)I’m quite nervous when my efforts survive the building process with no warnings or errors. I’m even more suspicious when I run the program and it works properly the first time. Still, it happens. Prepare to be delighted or have your suspicions confirmed. When things go awry, which is most of the time, you re-edit the source code file, compile, link, and run again. In fact, the actual C program development cycle looks more like figure 1.2.

![Figure 1.2 The true nature of the program development cycle. (Image courtesy of the California Department of Highway Safety.)](https://drek4537l1klr.cloudfront.net/gookin/Figures/01-02.png)

[](/book/tiny-c-projects/chapter-1/)For trivia’s sake, the original C compiler in Unix was called cc. Guess what it stands for?

[](/book/tiny-c-projects/chapter-1/)The original Unix linker was named *ld*. It probably stands for “link dis.” The *ld* program[](/book/tiny-c-projects/chapter-1/) still exists on today’s Linux and other Unix-like systems. It’s called internally by the compiler—unless the code is riddled with errors, in which case the compiler calls its friend Betsy to giggle about how horrible your C code reads.

[](/book/tiny-c-projects/chapter-1/)Okay. The *ld* program most likely is short for Link eDitor. Please stop composing that [](/book/tiny-c-projects/chapter-1/)[](/book/tiny-c-projects/chapter-1/)[](/book/tiny-c-projects/chapter-1/)email [](/book/tiny-c-projects/chapter-1/)now.

## [](/book/tiny-c-projects/chapter-1/)1.2 The integrated development environment (IDE)

[](/book/tiny-c-projects/chapter-1/)Most [](/book/tiny-c-projects/chapter-1/)coders prefer to work in an *integrated development environment*, or *IDE*—this program is software used to create software, like a toaster that makes toasters but also makes toast and bread.

[](/book/tiny-c-projects/chapter-1/)The IDE combines an editor, a compiler, and a running environment in a single program. Using an IDE is a must for creating GUI programs where you can build graphical elements like windows and dialog boxes and then add them to your code without the toil of coding everything by hand. Programmers love IDEs.

### [](/book/tiny-c-projects/chapter-1/)1.2.1 Choosing an IDE

[](/book/tiny-c-projects/chapter-1/)You [](/book/tiny-c-projects/chapter-1/)don’t need an IDE to craft the programs presented in this course. I suggest that you use the command prompt, but you’re stubborn and love your IDE—and you’re still reading—so I’m compelled to write about it.

[](/book/tiny-c-projects/chapter-1/)The IDE I recommend for C programming is Visual Studio Code, available at [code.visualstudio.com](https://code.visualstudio.com). It comes in Windows, macOS, and Linux flavors.

[](/book/tiny-c-projects/chapter-1/)Visual Studio Code can be overwhelming, so I also recommend Code::Blocks, available at [codeblocks.org](https://codeblocks.org/). Its best version is available only for Windows. Ensure that you obtain a version of Code::Blocks that comes with a compiler. The default is MinGW[](/book/tiny-c-projects/chapter-1/), which is nice. Better, get *clang*[](/book/tiny-c-projects/chapter-1/) for Windows, which can be obtained at the LLVM website: [llvm.org](https://llvm.org/). You must manually cajole Code::Blocks into accepting *clang* as its compiler; details are offered in the next section.

[](/book/tiny-c-projects/chapter-1/)If you’re using Linux, you already have a compiler, *gcc*[](/book/tiny-c-projects/chapter-1/), which is the default. Even so, I recommend obtaining the LLVM clang compiler[](/book/tiny-c-projects/chapter-1/). It’s incredibly sophisticated. It[](/book/tiny-c-projects/chapter-1/) features detailed error messages plus suggestions for fixing your code. If I were a robot, I would insist that clang[](/book/tiny-c-projects/chapter-1/) be used to compile my brain’s software. Use your distro’s package manager to obtain this superb compiler at [](/book/tiny-c-projects/chapter-1/)once!

### [](/book/tiny-c-projects/chapter-1/)1.2.2 Using Code::Blocks

[](/book/tiny-c-projects/chapter-1/)Though [](/book/tiny-c-projects/chapter-1/)[](/book/tiny-c-projects/chapter-1/)I prefer Visual Studio Code, I recommend Code::Blocks if you’re just starting out. Before you build your first program in the Code::Blocks IDE, confirm that the path to the compiler is correct. For a standard installation, the path is:

```
C:\Program Files (x86)\CodeBlocks\MinGW\bin
```

[](/book/tiny-c-projects/chapter-1/)Ensure that this address is specified for Code::Blocks to locate the default compiler, MinGW[](/book/tiny-c-projects/chapter-1/), which I just mentioned. Or, if you’ve disobeyed the setup program’s suggestions, set the proper path to your compiler. For example, be spicy and use LLVM clang[](/book/tiny-c-projects/chapter-1/) as your compiler. If so, set the proper path to that compiler so that Code::Blocks doesn’t barf every time you click the Build button.

[](/book/tiny-c-projects/chapter-1/)To set the path, heed these directions in Code::Blocks. Don’t be lazy! The missing compiler error message is one of the most common email complaint messages I receive from readers who can’t get Code::Blocks to work. Follow these steps in Code::Blocks:

1.  [](/book/tiny-c-projects/chapter-1/)Choose Settings > Compiler.
1.  [](/book/tiny-c-projects/chapter-1/)In the Compiler Settings dialog box, click the Toolchain Executables tab.
1.  [](/book/tiny-c-projects/chapter-1/)Write (or paste) the compiler’s address into the Compiler’s Installation Directory text box.
1.  [](/book/tiny-c-projects/chapter-1/)Click OK.

[](/book/tiny-c-projects/chapter-1/)The IDE should be happy with the compiler after you work through these steps. If not—yep, you guessed it—get some cows.

[](/book/tiny-c-projects/chapter-1/)Once the compiler is set, you use Code::Block’s built-in editor to create your code. The editor uses color-coding, matches parentheses and other pairs, and features inline context assistance for C library functions. All good.

[](/book/tiny-c-projects/chapter-1/)After creating—and saving—your source code, Code::Blocks uses a Build command to compile and link the source code. Messages are output in another part of the window where you read whether the operation succeeded or failed.

[](/book/tiny-c-projects/chapter-1/)Figure 1.3 shows the Code::Blocks workspace. Its presentation can be customized, though in the figure look for the callout items of the buttons used to build or run or do a combined build-and-run.

![Figure 1.3 Important stuff in the Code::Blocks IDE window](https://drek4537l1klr.cloudfront.net/gookin/Figures/01-03.png)

[](/book/tiny-c-projects/chapter-1/)Like all IDEs, Code::Blocks prefers that you create a new project when you start to code. The process works like this:

1.  [](/book/tiny-c-projects/chapter-1/)Click File > New > Project.
1.  [](/book/tiny-c-projects/chapter-1/)From the New From Template window, select the Console Application icon, and then click the Go button.
1.  [](/book/tiny-c-projects/chapter-1/)Select C as the programming language, and then click Next.
1.  [](/book/tiny-c-projects/chapter-1/)Type a title for the project, which is also the name of the project folder tree.
1.  [](/book/tiny-c-projects/chapter-1/)Choose the folder in which to create the project.
1.  [](/book/tiny-c-projects/chapter-1/)Click Next.
1.  [](/book/tiny-c-projects/chapter-1/)Select to create a Release configuration. You don’t need the Debug configuration unless you plan on using the Code::Blocks debugger (which is really quite cool, but no).
1.  [](/book/tiny-c-projects/chapter-1/)Click Finish to create the project skeleton.

[](/book/tiny-c-projects/chapter-1/)Code::Blocks spawns all kinds of folders and creates a prewritten source code file, `main.c`. You can replace the contents of this file with your own stuff. I find this entire process tedious, but it’s how an IDE prefers to work.

[](/book/tiny-c-projects/chapter-1/)As an alternative, you can use the File > New > Empty File command to open a new source code file in the editor. Immediately save the file with a `.c` filename extension to activate the editor’s nifty features. You can then proceed with creating an individual program without enduring the bulk and heft of a full-on project.

[](/book/tiny-c-projects/chapter-1/)Existing files—such as those you steal from GitHub for this book or for other, nefarious purposes—can be opened directly. The point of opening any file directly is that you don’t need the bulk and overhead of creating a project to create such small programs.

[](/book/tiny-c-projects/chapter-1/)To perform a quick compile and link in Code::Blocks, click the Build button. This step checks for warnings and errors but doesn’t run the created program. If things go well, click the Run button to view the output in a command prompt window, such as the one shown in figure 1.4.

![Figure 1.4 The command prompt window](https://drek4537l1klr.cloudfront.net/gookin/Figures/01-04.png)

[](/book/tiny-c-projects/chapter-1/)Close the command prompt window when you’re done. Remember to do this! A common problem some people have with Code::Blocks is that they can’t see the output window. This dilemma most likely occurs because an output window is already open. Ensure that after test-running your programs, you close the wee li’l terminal window.

[](/book/tiny-c-projects/chapter-1/)If you’re feeling cocky, you can use the combo Build-and-Run button (refer to figure 1.3) instead of working through the separate Build and Run commands. When you click Build and Run, the code builds and immediately runs, unless you riddled the thing with errors, in which case you get to fix [](/book/tiny-c-projects/chapter-1/)[](/book/tiny-c-projects/chapter-1/)them.

### [](/book/tiny-c-projects/chapter-1/)1.2.3 Using XCode

[](/book/tiny-c-projects/chapter-1/)The [](/book/tiny-c-projects/chapter-1/)[](/book/tiny-c-projects/chapter-1/)XCode IDE on the Macintosh is a top-flight application used to build everything from macOS programs to those teensy apps that run on cell phones and wristwatches for the terminally hip. You can use this sophisticated tool to write the simple command-line, text mode utilities offered in this book. It’s kind of impractical, given the power of XCode, but this hindrance doesn’t prevent millions of Apple fans from doing so.

[](/book/tiny-c-projects/chapter-1/)If your Macintosh lacks XCode, you can obtain a copy for free from the App Store. If prompted, ensure that you choose to add the command-line tools.

[](/book/tiny-c-projects/chapter-1/)To create a text mode C language project in XCode, heed these directions:

1.  [](/book/tiny-c-projects/chapter-1/)Choose File > New > Project.
1.  [](/book/tiny-c-projects/chapter-1/)Select the Command Line Tool template for the project.
1.  [](/book/tiny-c-projects/chapter-1/)Click Next.
1.  [](/book/tiny-c-projects/chapter-1/)Type a name for the project.
1.  [](/book/tiny-c-projects/chapter-1/)Ensure that C is chosen as the language.
1.  [](/book/tiny-c-projects/chapter-1/)Click the Next button.
1.  [](/book/tiny-c-projects/chapter-1/)Confirm the folder location.
1.  [](/book/tiny-c-projects/chapter-1/)Click the Create button.

[](/book/tiny-c-projects/chapter-1/)XCode builds a project skeleton, providing the `main.c` file, complete with source code you can gleefully replace with your own.

[](/book/tiny-c-projects/chapter-1/)Alas, unlike with other IDEs, you cannot open an individual C source code file and then build and run it within XCode. This reason is why I recommend using command-line programming on the Mac, especially for the small, text mode utilities presented in this book. Refer to the next section.

[](/book/tiny-c-projects/chapter-1/)To build and run in XCode, click the Run icon, shown in figure 1.5. Output appears in the bottom part of the project window, as illustrated in the figure.

![Figure 1.5 XCode’s window. (Squint to view clearly.)](https://drek4537l1klr.cloudfront.net/gookin/Figures/01-05.png)

[](/book/tiny-c-projects/chapter-1/)While the project files may dwell in the folder you chose earlier in step 7, the resulting program is created and buried deep within XCode’s folder system. This attempt at concealment makes it inconvenient for running and testing command-line programs demonstrated in this book. Specifically, to set command-line options or perform I/O redirection at the prompt requires jumping through too many hoops. To me, this awkwardness makes using XCode as your IDE an option limited to masochists and the fanatical [](/book/tiny-c-projects/chapter-1/)[](/book/tiny-c-projects/chapter-1/)Apple [](/book/tiny-c-projects/chapter-1/)type.

## [](/book/tiny-c-projects/chapter-1/)1.3 Command-line compiling

[](/book/tiny-c-projects/chapter-1/)Welcome [](/book/tiny-c-projects/chapter-1/)to the early years of computing. It’s nostalgic to edit, build, and run C programs in text mode, but it works well and is quite efficient. You must understand how the command line works, which is something I believe all C programmers should know innately. Truly, it’s rare to find a C coder worthy of the title who lacks a knowledge of text mode programming in Unix or Linux.

### [](/book/tiny-c-projects/chapter-1/)1.3.1 Accessing the terminal window

[](/book/tiny-c-projects/chapter-1/)Every [](/book/tiny-c-projects/chapter-1/)[](/book/tiny-c-projects/chapter-1/)Linux distro comes with a terminal window. MacOS features a terminal program. Even Windows 10 comes with a command shell, though it’s better to install the Windows Subsystem for Linux (WSL[](/book/tiny-c-projects/chapter-1/)) and use an Ubuntu bash shell for consistency with the other platforms. Never have the times been so good for text mode programming. Crack open a Tab and kick off your sandals!

-  [](/book/tiny-c-projects/chapter-1/)To start a terminal window in Linux, look for the Terminal program on the GUI’s program menu. It may be called Terminal, Term, Xterm, or something similar.
-  [](/book/tiny-c-projects/chapter-1/)On the Mac, start the Terminal application, which is found in the Utilities folder. Access this folder from the Finder by clicking Go > Utilities from the menu or by pressing the Shift+Command+U keyboard shortcut.
-  [](/book/tiny-c-projects/chapter-1/)In Windows 10, open the Microsoft Store and search for the Ubuntu app. It’s free to download, but to make it work you must also install the WSL. Directions for installing the subsystem are splattered all over the Internet.

[](/book/tiny-c-projects/chapter-1/)The Windows 10 Ubuntu app is shown in figure 1.6. Like all other terminal windows, it can be customized: you can reset the font size, the number of rows and columns, screen colors, and so on. Be aware that the traditional text mode screen supported 80 columns by 24 rows of text.

![Figure 1.6 Linux in Windows—such sacrilege](https://drek4537l1klr.cloudfront.net/gookin/Figures/01-06.png)

[](/book/tiny-c-projects/chapter-1/)If you plan on using the terminal window for your program production, I recommend keeping a shortcut to the Terminal program available for quick access. For example, in Windows, I pin a shortcut to the Ubuntu shell on the taskbar. On the Mac, I have my Terminal window automatically start each time I sign into OS X. Directions for accomplishing such tasks are concealed on the [](/book/tiny-c-projects/chapter-1/)[](/book/tiny-c-projects/chapter-1/)internet.

### [](/book/tiny-c-projects/chapter-1/)1.3.2 Reviewing basic shell commands

[](/book/tiny-c-projects/chapter-1/)I [](/book/tiny-c-projects/chapter-1/)[](/book/tiny-c-projects/chapter-1/)bet you know a few shell commands. Good. In case doubt lingers, table 1.1 lists some commands you should be familiar with to make it easy to work at the command prompt. These are presented without context or further information, which helps maintain the command prompt’s mysterious and powerful aura.

##### [](/book/tiny-c-projects/chapter-1/)Table 1.1 Shell commands worthy of attention[(view table figure)](https://drek4537l1klr.cloudfront.net/gookin/HighResolutionFigures/table_1-1.png)

| [](/book/tiny-c-projects/chapter-1/)Command | [](/book/tiny-c-projects/chapter-1/)What it does |
| --- | --- |
| [](/book/tiny-c-projects/chapter-1/)*cd*[](/book/tiny-c-projects/chapter-1/) | [](/book/tiny-c-projects/chapter-1/)Change to the named directory. When typed without an argument, the command changes to your home directory. |
| [](/book/tiny-c-projects/chapter-1/)*cp*[](/book/tiny-c-projects/chapter-1/) | [](/book/tiny-c-projects/chapter-1/)Copy a file. |
| [](/book/tiny-c-projects/chapter-1/)*exit*[](/book/tiny-c-projects/chapter-1/) | [](/book/tiny-c-projects/chapter-1/)Log out of the terminal window, which may close the window. |
| [](/book/tiny-c-projects/chapter-1/)*ls*[](/book/tiny-c-projects/chapter-1/) | [](/book/tiny-c-projects/chapter-1/)List files in the current directory. |
| [](/book/tiny-c-projects/chapter-1/)*man*[](/book/tiny-c-projects/chapter-1/) | [](/book/tiny-c-projects/chapter-1/)Summon the manual page (online documentation) for the named shell command or C language function. This is the most useful command to know. |
| [](/book/tiny-c-projects/chapter-1/)*mkdir*[](/book/tiny-c-projects/chapter-1/) | [](/book/tiny-c-projects/chapter-1/)Make a new directory. |
| [](/book/tiny-c-projects/chapter-1/)*mv*[](/book/tiny-c-projects/chapter-1/) | [](/book/tiny-c-projects/chapter-1/)Move a file from one directory to another. Also used to rename a file. |
| [](/book/tiny-c-projects/chapter-1/)*pwd*[](/book/tiny-c-projects/chapter-1/) | [](/book/tiny-c-projects/chapter-1/)Print the current working directory. |
| [](/book/tiny-c-projects/chapter-1/)*unlink*[](/book/tiny-c-projects/chapter-1/) | [](/book/tiny-c-projects/chapter-1/)Delete the named file. |

[](/book/tiny-c-projects/chapter-1/)Each of the commands listed in table 1.1 has options and arguments, such as filenames and pathnames. Most everything is typed in lowercase and spelling errors unforgivable. (Some shells offer spell-check and command completion.)

[](/book/tiny-c-projects/chapter-1/)Another command to know is make[](/book/tiny-c-projects/chapter-1/), which helps build larger projects. This command is covered later in this book. I’d list a chapter reference, but I haven’t written the chapter yet.

[](/book/tiny-c-projects/chapter-1/)Also important is to know how the package manager works, though with many Linux distros you can obtain command-line packages from the GUI package manager. If not, familiarize yourself with how the command-line package manager works.

[](/book/tiny-c-projects/chapter-1/)For example, in Ubuntu Linux, use the *apt* command[](/book/tiny-c-projects/chapter-1/) to search for, install, update, and remove command-line software. Various magical options make these things happen. Oh, and the *apt* command must be run from the superuser account; onscreen directions explain the details.

[](/book/tiny-c-projects/chapter-1/)My final recommendation is to understand the file-naming conventions. Spaces and other oddball characters are easy to type in a GUI, but at the command prompt, they can be nettlesome. For the most part, prefix spaces with the backslash character, \ , which acts as an escape. You can also take advantage of filename completion: in *bash*[](/book/tiny-c-projects/chapter-1/), *zsh*[](/book/tiny-c-projects/chapter-1/), and other shells, type the first part of a filename, and then press the Tab key to spew out the rest of the name automatically.

[](/book/tiny-c-projects/chapter-1/)File-naming conventions also cover pathnames. Understand the difference between relative and absolute paths, which helps when running programs and managing your files.

[](/book/tiny-c-projects/chapter-1/)I’m sure you can find a good book somewhere to help you brush up on your Linux knowledge. Here is an obligatory plug for a tome from Manning Publications: *Learn Linux in a Month of Lunches*[](/book/tiny-c-projects/chapter-1/), by Steven Ovadia[](/book/tiny-c-projects/chapter-1/) (2016). Remember, it’s free at the [](/book/tiny-c-projects/chapter-1/)[](/book/tiny-c-projects/chapter-1/)library.

### [](/book/tiny-c-projects/chapter-1/)1.3.3 Exploring text screen editors

[](/book/tiny-c-projects/chapter-1/)To [](/book/tiny-c-projects/chapter-1/)[](/book/tiny-c-projects/chapter-1/)properly woo the command prompt, you must know how to use a text mode editor. Many are installed by default with Linux. Those that aren’t can be obtained from your distro’s package manager. On the Mac, you can use the Homebrew system to add text mode programs that Apple deems unworthy to ship with its operating system; learn more about Homebrew at [brew.sh](http://brew.sh)[](/book/tiny-c-projects/chapter-1/).

[](/book/tiny-c-projects/chapter-1/)My favorite text mode editor is *VIM*[](/book/tiny-c-projects/chapter-1/), the improved version of the classic vi editor[](/book/tiny-c-projects/chapter-1/). It has a terminal window version that runs in text mode as well as a full GUI version. The program is available for all operating systems.

[](/book/tiny-c-projects/chapter-1/)The thing that ticks off most coders about *VIM*[](/book/tiny-c-projects/chapter-1/) is that it’s a modal editor, which means you must switch between text editing and input modes. This duality drives some programmers crazy, which is fine by me.

[](/book/tiny-c-projects/chapter-1/)Another popular text mode editor is *Emacs*[](/book/tiny-c-projects/chapter-1/). Like *VIM*, it’s also available as a text mode editor as well as a GUI editor. I don’t use *Emacs*, so I am unable to wax eloquent upon its virtues.

[](/book/tiny-c-projects/chapter-1/)Whatever text editor you obtain, ensure that it offers C language color-coding as well as other helpful features like matching pairs: parentheses, brackets, and braces. With many editors, it’s possible to customize features, such as writing a startup script that properly contorts the editor to your liking. For example, I prefer a four-space tab stop in my code, which I can set by configuring the .vimrc file in my home [](/book/tiny-c-projects/chapter-1/)[](/book/tiny-c-projects/chapter-1/)directory.

### [](/book/tiny-c-projects/chapter-1/)1.3.4 Using a GUI editor

[](/book/tiny-c-projects/chapter-1/)It [](/book/tiny-c-projects/chapter-1/)[](/book/tiny-c-projects/chapter-1/)may be scandalous, but it’s convenient to use a GUI editor while you work at the command prompt. This arrangement is my preferred programming mode: I write code in my editor’s glorious graphical window and then build and run in the dreary text mode terminal window. This arrangement gives me the power of a GUI editor and the ability to examine text mode output at the same time, as illustrated in figure 1.7.

![Figure 1.7 A desktop with an editor and a terminal window arranged just so](https://drek4537l1klr.cloudfront.net/gookin/Figures/01-07.png)

[](/book/tiny-c-projects/chapter-1/)The only limitation to using a GUI editor is that you must remember to save the source code in one window before you build in the other. This reminder isn’t as much of an issue when you use a text mode editor running in the terminal, because you save when you quit. But when bouncing between two different windows on a desktop, it’s easy to forget to [](/book/tiny-c-projects/chapter-1/)[](/book/tiny-c-projects/chapter-1/)save.

### [](/book/tiny-c-projects/chapter-1/)1.3.5 Compiling and running

[](/book/tiny-c-projects/chapter-1/)The [](/book/tiny-c-projects/chapter-1/)command-line compiler in Linux is gcc[](/book/tiny-c-projects/chapter-1/), which is the GNU version of the original cc compiler from the caveman days of Unix. As I wrote earlier, I recommend using the clang compiler[](/book/tiny-c-projects/chapter-1/) instead of gcc. It offers better error reporting and suggestions. Use your distro’s package manager to obtain clang[](/book/tiny-c-projects/chapter-1/) or visit [llvm.org](https://llvm.org). For the remainder of this chapter, as well as the rest of this book, my assumption is that you use clang[](/book/tiny-c-projects/chapter-1/) as your compiler.

[](/book/tiny-c-projects/chapter-1/)To build code, which includes both the compiling and linking steps, use the following command:

```
clang -Wall source.c
```

[](/book/tiny-c-projects/chapter-1/)The compiler is named clang[](/book/tiny-c-projects/chapter-1/). The `-Wall` switch[](/book/tiny-c-projects/chapter-1/) activates all warnings—always a good idea. And `source.c` represents the source code filename. The command I just listed generates a program file, `a.out`, upon success. Warnings may also yield a program file; run it at your own peril. Error messages indicate a serious problem you must address; no program file is generated.

[](/book/tiny-c-projects/chapter-1/)If you desire to set an output filename, use the `-o` switch[](/book/tiny-c-projects/chapter-1/) followed by the output filename:

```
clang -Wall source.c -o program
```

[](/book/tiny-c-projects/chapter-1/)Upon success, the previous command generates a program file named `program`.

[](/book/tiny-c-projects/chapter-1/)The compiler sets the program’s executable bit as well as file permissions that match those for your account. Once your program is created, it’s ready to run.

[](/book/tiny-c-projects/chapter-1/)To run the program, you must specify its full pathname. Remember that in Linux, unless the program exists in a directory on the search path, a full pathname must be specified. For programs in the current directory, use the `./` prefix, like so:

```
./a.out
```

[](/book/tiny-c-projects/chapter-1/)This command runs the program file `a.out`, located in the current directory, as shown here:

```
./cypher
```

[](/book/tiny-c-projects/chapter-1/)This command runs the program name `cypher`[](/book/tiny-c-projects/chapter-1/), again located in the current directory.

[](/book/tiny-c-projects/chapter-1/)The single dot is an abbreviation for the current directory. The slash separates the pathname from the filename. Together, the `./` forces the shell to locate and run the named program in the current directory. Because the program’s executable bit is set, its binary data is loaded into memory [](/book/tiny-c-projects/chapter-1/)and [](/book/tiny-c-projects/chapter-1/)executed.

[](/book/tiny-c-projects/chapter-1/)As someone who aspires to improve the craft, you must be aware of the assortment of compiler options—specifically, those that link in libraries. These libraries expand a mere mortal C program into realms of greater capabilities.

[](/book/tiny-c-projects/chapter-1/)All C programs link in the standard C library. This library contains the horsepower behind such functions as *printf()*[](/book/tiny-c-projects/chapter-1/). Yet, it’s a common misconception among beginning C programmers that it’s the header file that contains the oomph. Nope. The linker builds the program by combining object code (created by the compiler) with a C language library.

[](/book/tiny-c-projects/chapter-1/)Other libraries are also available, which are linked in addition to the standard C library to build complex and interesting programs. These libraries add more capabilities to your program, providing access to the internet, graphics, specific hardware, and a host of other useful features. Hundreds of libraries are available, each of which helps extend your program’s potential. The key to using these libraries is to understand how they’re linked in, which also raises the issue of compiler options or command-line switches.

[](/book/tiny-c-projects/chapter-1/)As you may expect, methods of adding options and linking libraries differ between the IDE and command prompt approaches to creating programs.

### [](/book/tiny-c-projects/chapter-1/)1.4.1 Linking libraries and setting other options in an IDE

[](/book/tiny-c-projects/chapter-1/)One [](/book/tiny-c-projects/chapter-1/)[](/book/tiny-c-projects/chapter-1/)area where using an IDE becomes inconvenient is the task of setting compiler options or specifying command-line arguments. Setting the options includes linking in a library. You must not only discover where the linking option is hidden but also confirm the location of the library on the filesystem and ensure that it’s compatible with the compiler.

[](/book/tiny-c-projects/chapter-1/)I don’t have the time, and it’s really not this book’s subject, to get into specifics for each IDE and how they set command-line arguments for the programs you build or how specific options are set, such as linking in an extra compiler. After all, I push command-line programming enough—get the hint! But if you insist, or you just enjoy seeing how difficult things can be, read on. For brevity’s sake, I’ll stick with Code::Blocks because I know it best. Other IDEs have similar options and settings. I hope.

[](/book/tiny-c-projects/chapter-1/)Compiler options in Code::Blocks are found in the Settings dialog box: click Settings > Compiler to view the dialog box, shown in figure 1.8. This is the same location where you specify another library to link.

![Figure 1.8 Finding useful stuff in the Code::Blocks’ Settings dialog box](https://drek4537l1klr.cloudfront.net/gookin/Figures/01-08.png)

[](/book/tiny-c-projects/chapter-1/)Preset options are listed on the Compiler Flags tab, illustrated in figure 1.8. This tab is a subtab of the Compiler Settings tab, also called out in the figure. The command-line switches for each option are shown at the end of the descriptive text.

[](/book/tiny-c-projects/chapter-1/)Use the Other Compiler Options tab to specify any options not found on the Compiler Flags tab. I can’t think of any specific options you might consider adding, but this tab is where they go.

[](/book/tiny-c-projects/chapter-1/)Click the Linker Settings tab (refer to figure 1.8) to add libraries. Click the Add button to browse for a library to link in. You must know the folder in which the library file dwells. Unlike command-line compiling, default directories for library files aren’t searched automatically. Ditto for header files, which are often included in the same directory tree as the libraries.

[](/book/tiny-c-projects/chapter-1/)To specify command-line arguments for your programs in Code::Blocks, use the Project > Set Programs’ Arguments command. The problem here is that the apostrophe is misplaced on the menu; it should read Program’s. I mention this because my editor will query me otherwise.

[](/book/tiny-c-projects/chapter-1/)After choosing the grammatically incorrect Set Programs’ Arguments command, you see the Select Target dialog box. Use the Program Arguments text field to specify required arguments for the programs you run in the IDE. The limitation here is that your command-line program must be built as a project in Code::Blocks. Otherwise, the option to set command-line arguments is unavailable.

[](/book/tiny-c-projects/chapter-1/)Please be aware that the tiny programs presented in this book are designed to run at the command prompt, which makes it weird to set arguments in an IDE. Because the IDE creates a program, you can always navigate to the program folder to run the program directly at a command prompt. If possible, discover whether your IDE allows you quick access to the folder containing the program executable. Or just surrender to the inevitable ease and self-fulfilling joy of programming in a terminal [](/book/tiny-c-projects/chapter-1/)[](/book/tiny-c-projects/chapter-1/)window.

### [](/book/tiny-c-projects/chapter-1/)1.4.2 Using command-line compiler options

[](/book/tiny-c-projects/chapter-1/)It’s [](/book/tiny-c-projects/chapter-1/)easy and obvious to type compiler options and program arguments at a command prompt in a terminal window: no extra settings, menus, mouse clicks, or other options to hunt for. Again, these are many of the reasons programming at the command prompt makes sense for the programs presented in this book, as well as for lots of tiny C projects.

[](/book/tiny-c-projects/chapter-1/)Of the slate of command-line options, one worthy of note is `-l` (little L[](/book/tiny-c-projects/chapter-1/)). This switch is used to link in a library. The `-l` is followed immediately by the library name, as in:

```
clang -Wall weather.c -lcurl
```

[](/book/tiny-c-projects/chapter-1/)Here, the libcurl library, named `curl`[](/book/tiny-c-projects/chapter-1/), is linked along with the standard C library to build a program based on the `weather.c` source code file. (You don’t need to specify the standard C library, because it’s linked in by default.)

[](/book/tiny-c-projects/chapter-1/)To specify an output filename, use the `-o` switch[](/book/tiny-c-projects/chapter-1/) as covered earlier in this chapter:

```
clang -Wall weather.c -lcurl -o weather
```

[](/book/tiny-c-projects/chapter-1/)With some compilers, option order is relevant. If you see a slew of linker errors when using the `-l` switch[](/book/tiny-c-projects/chapter-1/), change the argument order to specify `-l` last:

```
clang -Wall weather.c -o weather -lcurl
```

[](/book/tiny-c-projects/chapter-1/)At the command line, the compiler searches default directories for locations of library files as well as header files. In Unix and Linux—but not OS/X—these locations follow:

-  [](/book/tiny-c-projects/chapter-1/)Header files: `/usr/include`
-  [](/book/tiny-c-projects/chapter-1/)Library files: `/usr/lib`

[](/book/tiny-c-projects/chapter-1/)Custom library and header files you install can be found at these locations:

-  [](/book/tiny-c-projects/chapter-1/)Header files: `/usr/local/include`
-  [](/book/tiny-c-projects/chapter-1/)Library files: `/usr/local/lib`

[](/book/tiny-c-projects/chapter-1/)The compiler automatically searches these directories for header files and libraries. If the library file exists elsewhere, you specify its pathname after the `-l` switch[](/book/tiny-c-projects/chapter-1/).

[](/book/tiny-c-projects/chapter-1/)No toil is involved in specifying command-line arguments for your programs. Unlike an IDE, the arguments are typed directly after the program name:

```
./weather KSEA
```

[](/book/tiny-c-projects/chapter-1/)Here, the weather program runs in the current directory with a single argument, `KSEA`. Simple. Easy. I shan’t use [](/book/tiny-c-projects/chapter-1/)further superlatives.

## [](/book/tiny-c-projects/chapter-1/)1.5 Quiz

[](/book/tiny-c-projects/chapter-1/)I decided against adding a quiz.
