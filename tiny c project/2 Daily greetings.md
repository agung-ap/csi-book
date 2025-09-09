# [](/book/tiny-c-projects/chapter-2/)2 Daily greetings

[](/book/tiny-c-projects/chapter-2/)Your computer day starts when you sign in. The original term was log in, but because trees are so scarce and signs are so plentiful, the term was changed by the Bush administration in 2007. Regardless of such obnoxious federal overreach, your computer day can start with a cheerful greeting after you sign in or open a terminal window, customized by a tiny C program. To make it so, you will:

-  [](/book/tiny-c-projects/chapter-2/)Review the Linux startup process.
-  [](/book/tiny-c-projects/chapter-2/)Discover where in the shell script to add your greeting.
-  [](/book/tiny-c-projects/chapter-2/)Write a simple greetings program.
-  [](/book/tiny-c-projects/chapter-2/)Modify your greetings program to add the time of day.
-  [](/book/tiny-c-projects/chapter-2/)Update the timestamp with the current moon phase.
-  [](/book/tiny-c-projects/chapter-2/)Enhance your greetings message with a bon mot.

[](/book/tiny-c-projects/chapter-2/)The programs created and expanded upon in this chapter are specific to Linux, macOS, and the Windows Subsystem for Linux (WSL[](/book/tiny-c-projects/chapter-2/)), where a startup script is available for configuring the terminal window. A later section explains which startup scripts are available for the more popular shells. This chapter doesn’t go into creating a daily greeting message when the GUI shell starts.

[](/book/tiny-c-projects/chapter-2/)I suppose you could add a startup message for the Windows terminal screen, the command prompt. It’s possible, but the process bores me, and only hardcore Windows nerds would care, so I’m skipping the specifics. The greetings programs still run at the Windows command prompt, if that’s your desire. Otherwise, you may lodge your complaints with me personally; my email address is found in this book’s introduction. I promise not to answer a single email from a whiny Windows user.

[](/book/tiny-c-projects/chapter-2/)Linux [](/book/tiny-c-projects/chapter-2/)has a long, involved, and thoroughly exciting boot process. I’m certain that you’re eager to read all the nitty-gritty details. But this book is about C programming. You must seek out a Linux book to know the complete, torrid steps involved with rousing a Linux computer. The exciting stuff relevant to creating a daily greeting happens later, after the operating system completes its morning routine, when the shell starts.

### [](/book/tiny-c-projects/chapter-2/)2.1.1 Understanding how the shell fits in

[](/book/tiny-c-projects/chapter-2/)Each [](/book/tiny-c-projects/chapter-2/)user account on a Linux system is assigned a default shell. This shell was once the only interface for Linux. I recall booting into an early version of Red Hat Linux back in the 1990s and the first—and only—thing I saw was a text mode screen. Today things are graphical, and the shell has been shunted off to a terminal window. It’s still relevant at this location, which is great for C programming.

[](/book/tiny-c-projects/chapter-2/)The default shell is configured by the something-or-other. I’m too lazy to write about it here. Again, this isn’t a Linux book. Suffice it to say that your account most likely uses the *bash* shell—a[](/book/tiny-c-projects/chapter-2/) collision of the words “Bourne again shell,” so my writing “*bash* shell” is redundant (like ATM machine), but it looks awkward otherwise.

[](/book/tiny-c-projects/chapter-2/)To determine the default shell, start a terminal window. At the prompt, type the command **echo $SHELL**:

```bash
$ echo $SHELL
/bin/bash
```

[](/book/tiny-c-projects/chapter-2/)Here, the output confirms that the assigned user shell is *bash*[](/book/tiny-c-projects/chapter-2/). The `$SHELL` argument represents the environment variable assigned to the startup shell, which is `/bin/bash` here. This output may not reflect the current shell—for example, if you’ve subsequently run the *sh* or *zsh* or similar command to start another shell.

[](/book/tiny-c-projects/chapter-2/)To determine the current shell, type the command **ps -p $$**:

```bash
$ ps -p $$
  PID TTY          TIME CMD
    7 tty1     00:00:00 bash
```

[](/book/tiny-c-projects/chapter-2/)This output shows the shell command is `bash`, meaning the current shell is *bash*[](/book/tiny-c-projects/chapter-2/) regardless of the `$SHELL` variable’s assignment.

[](/book/tiny-c-projects/chapter-2/)To change the shell, use the *chsh* command[](/book/tiny-c-projects/chapter-2/). The command is followed by the new shell name. Changing the shell affects only your account and applies to any new terminal windows you open after issuing the command. That’s enough Linux for [](/book/tiny-c-projects/chapter-2/)today.

### [](/book/tiny-c-projects/chapter-2/)2.1.2 Exploring various shell startup scripts

[](/book/tiny-c-projects/chapter-2/)When [](/book/tiny-c-projects/chapter-2/)a shell starts, it processes commands located in various startup scripts. Some of these scripts may be global, located in system directories. Others are specific to your account, located locally in your home folder.

[](/book/tiny-c-projects/chapter-2/)Startup scripts configure the terminal. They allow you to customize the horrid text-only experience, perhaps adding colors, creating shortcuts, and performing various tasks you may otherwise have to manually perform each time a terminal window opens. Any startup script file located in your home directory is yours to configure.

[](/book/tiny-c-projects/chapter-2/)Given all that, the general advice is not to mess with startup shell scripts. To drive home this point, the shell script files are hidden in your home directory. The filenames are prefixed with a single dot. The dot prefix hides files from appearing in a standard directory listing. This stealth allows the files to be handy yet concealed from a casual user’s attempts to meddle with them.

[](/book/tiny-c-projects/chapter-2/)Because you want to meddle with the shell startup script, specifically to add a personalized greeting, it’s necessary to know the script names. These names can differ, depending upon the shell, though the preferred startup script to edit appears in table 2.1.

##### [](/book/tiny-c-projects/chapter-2/)Table 2.1 Tediously dry info regarding Linux shell scripts[(view table figure)](https://drek4537l1klr.cloudfront.net/gookin/HighResolutionFigures/table_2-1.png)

| [](/book/tiny-c-projects/chapter-2/)Shell | [](/book/tiny-c-projects/chapter-2/)Name | [](/book/tiny-c-projects/chapter-2/)Command | [](/book/tiny-c-projects/chapter-2/)Startup filename |
| --- | --- | --- | --- |
| [](/book/tiny-c-projects/chapter-2/)Bash[](/book/tiny-c-projects/chapter-2/) | [](/book/tiny-c-projects/chapter-2/)Bash, “Bourne again shell” | [](/book/tiny-c-projects/chapter-2/)*/bin/bash* | [](/book/tiny-c-projects/chapter-2/).bash_profile |
| [](/book/tiny-c-projects/chapter-2/)Tsch[](/book/tiny-c-projects/chapter-2/) | [](/book/tiny-c-projects/chapter-2/)Tee C shell | [](/book/tiny-c-projects/chapter-2/)*/bin/tsch* | [](/book/tiny-c-projects/chapter-2/).tcshrc |
| [](/book/tiny-c-projects/chapter-2/)Csh[](/book/tiny-c-projects/chapter-2/) | [](/book/tiny-c-projects/chapter-2/)C shell | [](/book/tiny-c-projects/chapter-2/)*/bin/csh* | [](/book/tiny-c-projects/chapter-2/).cshrc |
| [](/book/tiny-c-projects/chapter-2/)Ksh[](/book/tiny-c-projects/chapter-2/) | [](/book/tiny-c-projects/chapter-2/)Korn shell | [](/book/tiny-c-projects/chapter-2/)*/bin/ksh* | [](/book/tiny-c-projects/chapter-2/).profile |
| [](/book/tiny-c-projects/chapter-2/)Sh[](/book/tiny-c-projects/chapter-2/) | [](/book/tiny-c-projects/chapter-2/)Bourne shell | [](/book/tiny-c-projects/chapter-2/)*/bin/sh* | [](/book/tiny-c-projects/chapter-2/).profile |
| [](/book/tiny-c-projects/chapter-2/)Zsh[](/book/tiny-c-projects/chapter-2/) | [](/book/tiny-c-projects/chapter-2/)Z shell | [](/book/tiny-c-projects/chapter-2/)*/bin/zsh* | [](/book/tiny-c-projects/chapter-2/).zshrc |

[](/book/tiny-c-projects/chapter-2/)For example, for the *bash* shell[](/book/tiny-c-projects/chapter-2/), I recommend editing the startup script `.bash_profile` to add your greeting. Other startup scripts may run when the shell starts, but this is the script you can modify.

[](/book/tiny-c-projects/chapter-2/)To view your shell’s startup script, use the *cat* command in a terminal window. Follow the command with the shell’s startup filename. For example:

```bash
$ cat ~/.bash_profile
```

[](/book/tiny-c-projects/chapter-2/)The `~/` pathname is a shortcut for your home directory. After you issue the preceding command, the contents of the shell startup script vomit all over the text screen. If not, the file may not exist and you need to create it.

[](/book/tiny-c-projects/chapter-2/)When you see the file’s contents, somewhere in the morass you can stick your greetings program on a line by itself. The rest of the script shouldn’t be meddled with—unless you’re adept at coding in the scripting language and crafting brilliant startup scripts, which you probably [](/book/tiny-c-projects/chapter-2/)aren’t.

### [](/book/tiny-c-projects/chapter-2/)2.1.3 Editing the shell startup script

[](/book/tiny-c-projects/chapter-2/)Shell [](/book/tiny-c-projects/chapter-2/)startup scripts are plain text files. They consist of shell commands, program names, and various directives, which makes the script work like a programming language. The script is edited like any text file.

[](/book/tiny-c-projects/chapter-2/)I could wax eloquent for several pages about shell scripting, but I have a dental appointment in an hour and this book is about C programming. Still, you should note two relevant aspects of a startup shell script: the very first line and the file’s permissions.

[](/book/tiny-c-projects/chapter-2/)To interpret the lines of text in a startup script, the very first line of the file directs the shell to use a specific program to process the remaining lines in the file. Traditionally, the first line of a Unix shell script is:

```
#!/bin/sh
```

[](/book/tiny-c-projects/chapter-2/)This line starts with the `#`, which makes it a comment. The exclamation point, which the cool kids tell me is pronounced “bang,” directs the shell to use the `/bin/sh` program (the original Bourne shell) to process the remaining lines of text in the file. The command could be anything, from a shell like bash[](/book/tiny-c-projects/chapter-2/) to a utility like *expect*.

[](/book/tiny-c-projects/chapter-2/)All shell scripts have their executable permissions bit set. If the file exists, this setting is already made. Otherwise, if you’re creating the shell script, you must bless it with the executable bit after the file is created. Use the chmod command[](/book/tiny-c-projects/chapter-2/) with the `+x` switch, followed by the script filename:

```
chmod +x .bash_profile
```

[](/book/tiny-c-projects/chapter-2/)Issuing this command is required only when you initially create the script.

[](/book/tiny-c-projects/chapter-2/)Within the startup script, my recommendation is to set your greetings program on a line by itself at the end of the script. You can even prefix it with a comment, starting the line before with the `#` character. The cool kids have informed me that `#` is pronounced “hash.”

[](/book/tiny-c-projects/chapter-2/)For practice, edit the terminal window’s startup script: open a terminal window and use your favorite text editor to open the shell’s startup script, as noted in table 2.1. For example, on my Linux system, I type:

```
vim ~/.bash_profile
```

[](/book/tiny-c-projects/chapter-2/)Add the following two lines at the bottom of the script, after all the stuff that looks impressive and tempting:

```bash
# startup greetings
echo "Hello" $LOGNAME
```

[](/book/tiny-c-projects/chapter-2/)The first line is prefixed with a `#`. (I hope you said “hash” in your head.) This tag marks the line as a comment.

[](/book/tiny-c-projects/chapter-2/)The second line outputs the text `"Hello"` followed by the contents of environment variable `$LOGNAME`[](/book/tiny-c-projects/chapter-2/). This variable represents your login account name.

[](/book/tiny-c-projects/chapter-2/)Here’s sample output:

```
Hello dang
```

[](/book/tiny-c-projects/chapter-2/)My account login is *dang*, as shown. This line of text is the final output generated by the shell startup script when the terminal window first opens. The C programs generated for the remainder of this chapter replace this line, outputting their cheerful and interesting messages.

[](/book/tiny-c-projects/chapter-2/)When adding your greetings program to the startup script, it’s important that you specify its pathname, lest the shell script interpreter freak out. The path can be full, as in:

```
/home/dang/cprog/greetings
```

[](/book/tiny-c-projects/chapter-2/)Or it can use the `~/` home directory shortcut:

```
~/cprog/greetings
```

[](/book/tiny-c-projects/chapter-2/)In both cases, the program is named `greetings`, and it dwells in the [](/book/tiny-c-projects/chapter-2/)`cprog` [](/book/tiny-c-projects/chapter-2/)directory.

## [](/book/tiny-c-projects/chapter-2/)2.2 A simple greeting

[](/book/tiny-c-projects/chapter-2/)All [](/book/tiny-c-projects/chapter-2/)major programming projects start out simple and have a tendency to grow into complex, ugly monsters. I’m certain that Excel began its existence as a quick-and-dirty, text mode calculator—and now look at it. Regardless, it’s good programming practice not to begin a project by coding everything you need all at once. No, it’s best to grow the project, starting with something simple and stupid, which is the point of this section.

### [](/book/tiny-c-projects/chapter-2/)2.2.1 Coding a greeting

[](/book/tiny-c-projects/chapter-2/)The [](/book/tiny-c-projects/chapter-2/)most basic greetings program you can make is a simple regurgitation of the silly *Hello World* program[](/book/tiny-c-projects/chapter-2/) that ushers in the pages of every introductory C programming book since Moses. Listing 2.1 shows the version you could write for your greetings program.

##### Listing 2.1 Source code for greet01.c

```
#include <stdio.h>

int main()
{
   printf("Hello, Dan!\n");

   return(0);
}
```

[](/book/tiny-c-projects/chapter-2/)Don’t build. Don’t run. If you do, use this command to build a program named `greetings`:

```
clang -Wall greet01.c -o greetings
```

[](/book/tiny-c-projects/chapter-2/)You may substitute *clang* with your favorite-yet-inferior compiler. Upon success, the resulting program is named `greetings`. Set this program into your shell’s startup script, adding the last line that looks like this:

```
greetings
```

[](/book/tiny-c-projects/chapter-2/)Ensure that you prefix the program name with a pathname—either the full pathname, like this:

```
/home/dang/bin/greetings
```

[](/book/tiny-c-projects/chapter-2/)or a relative pathname:

```
~/bin/greetings
```

[](/book/tiny-c-projects/chapter-2/)The startup script cannot magically locate program files, unless you specify a path, such as my personal `~/bin` directory shown in the examples. (I also use my shell startup script to place my personal `~/bin` directory on the search path—another Linux trick found in another book somewhere.)

[](/book/tiny-c-projects/chapter-2/)After the startup script is updated, the next terminal window you open runs a startup script that outputs the following line, making your day more cheerful:

```
Hello, Dan!
```

[](/book/tiny-c-projects/chapter-2/)And if your name isn’t Dan, then the greeting is more puzzling than [](/book/tiny-c-projects/chapter-2/)cheerful.

### [](/book/tiny-c-projects/chapter-2/)2.2.2 Adding a name as an argument

[](/book/tiny-c-projects/chapter-2/)The [](/book/tiny-c-projects/chapter-2/)initial version of the `greetings` program is inflexible. That’s probably why you didn’t code it and are instead eager to modify it with some customization.

[](/book/tiny-c-projects/chapter-2/)Consider the modest improvement offered in listing 2.2. This update to the code allows you to present the program with an argument, allowing it to be flexible.

##### Listing 2.2 Source code for greet02.c

```
#include <stdio.h>
 
int main(int argc, char *argv[])
{
    if( argc<2)                              #1
        puts("Hello, you handsome beast!");
    else
        printf("Hello, %s!\n",argv[1]);      #2
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-2/)Build this code into a program and thrust it into your shell’s startup script as written in the ancient scrolls but also in the preceding section:

```
greetings Danny
```

[](/book/tiny-c-projects/chapter-2/)The program now outputs the following message when you open a new terminal window:

```
Hello, Danny!
```

[](/book/tiny-c-projects/chapter-2/)This new message is far more cheerful than the original but still begging for [](/book/tiny-c-projects/chapter-2/)some [](/book/tiny-c-projects/chapter-2/)improvement.

## [](/book/tiny-c-projects/chapter-2/)2.3 The time of day

[](/book/tiny-c-projects/chapter-2/)One [](/book/tiny-c-projects/chapter-2/)of the first programs I wrote for my old DOS computer greeted me every time I turned on the computer. The program was similar to those created in the last two sections, which means it was boring. To spice it up, and inspired by my verbal interactions with humans I encounter in real life, I added code to make the greeting reflect the time of day. You can do so as well with varying degrees of accuracy.

### [](/book/tiny-c-projects/chapter-2/)2.3.1 Obtaining the current time

[](/book/tiny-c-projects/chapter-2/)Does [](/book/tiny-c-projects/chapter-2/)anyone really know what time it is? The computer can guess. It keeps semi-accurate time because it touches base with an internet time server every so often. Otherwise, the computer’s clock would be off by several minutes every day. Trust me, computers make lousy clocks, but this truth doesn’t stop you from plucking the current time from its innards.

[](/book/tiny-c-projects/chapter-2/)The C library is rife with time functions, all defined in the `time.h` header file. The *time_t* data type[](/book/tiny-c-projects/chapter-2/) is also defined in the header. This positive integer value (*long* data type, *printf()* placeholder `%ld`) stores the Unix epoch, the number of seconds ticking away since midnight January 1, 1970.

[](/book/tiny-c-projects/chapter-2/)The Unix epoch is a great value to use in your greetings program. For example, imagine your joy at seeing—every day when you start the terminal—the following jolly message:

```
Hello, Danny, it's 1624424373
```

[](/book/tiny-c-projects/chapter-2/)Try to hold back any emotion.

[](/book/tiny-c-projects/chapter-2/)Of course, the *time_t* value must be manipulated into something a bit more useful. Listing 2.3 shows some sample code. Be aware that many time functions, such as *time[](/book/tiny-c-projects/chapter-2/)()* and *ctime[](/book/tiny-c-projects/chapter-2/)()* used in the code for `time01.c`, require the address of the *time_t* variable[](/book/tiny-c-projects/chapter-2/). Yup, they’re pointers.

##### Listing 2.3 Source code for time01.c

```
#include <stdio.h>
#include <time.h>                                   #1
 
int main()
{
    time_t now;
 
    time(&now);                                     #2
    printf("The computer thinks it's %ld\n",now);
    printf("%s",ctime(&now));                       #3
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-2/)Here is sample output from the resulting program:

```
The computer thinks it's 1624424373
Tue Jun 22 21:59:33 2021
```

[](/book/tiny-c-projects/chapter-2/)The output shows the number of seconds of tick-tocking since 1970. This same value is swallowed by the *ctime()* function[](/book/tiny-c-projects/chapter-2/) to output a formatted time string. This result may be acceptable in your greetings program, but time data can be customized further. The key to unlocking specific time details is found in the *localtime()* function[](/book/tiny-c-projects/chapter-2/), as the code in listing 2.4 demonstrates.

##### Listing 2.4 Source code for time02.c

```
#include <stdio.h>
#include <time.h>
 
int main()
{
    time_t now;
    struct tm *clock;                                         #1
 
    time(&now);
    clock = localtime(&now);
    puts("Time details:");
    printf(" Day of the year: %d\n",clock->tm_yday);
    printf(" Day of the week: %d\n",clock->tm_wday);          #2
    printf("            Year: %d\n",clock->tm_year+1900);     #3
    printf("           Month: %d\n",clock->tm_mon+1);         #4
    printf("Day of the month: %d\n",clock->tm_mday);
    printf("            Hour: %d\n",clock->tm_hour);
    printf("          Minute: %d\n",clock->tm_min);
    printf("          Second: %d\n",clock->tm_sec);
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-2/)I formatted the code in listing 2.4 with oodles of spaces so that you could easily identify the `tm` structure’s members. These variables represent the time tidbits that the *localtime()* function[](/book/tiny-c-projects/chapter-2/) extracts from a `time_t` value. Ensure that you remember to adjust some values as shown in listing 2.4: the year value `tm_year` must be increased by 1900 to reflect the current, valid year; the month value `tm_mon` starts with zero, not one.

[](/book/tiny-c-projects/chapter-2/)The output is trivial, so I need not show it—unless you send me a check for $5. Still, the point of the code is to show how you can obtain useful time information with which to properly pepper your terminal [](/book/tiny-c-projects/chapter-2/)greetings.

### [](/book/tiny-c-projects/chapter-2/)2.3.2 Mixing in the general time of day

[](/book/tiny-c-projects/chapter-2/)The [](/book/tiny-c-projects/chapter-2/)[](/book/tiny-c-projects/chapter-2/)program I wrote years ago for my DOS computer was called `GREET.COM`[](/book/tiny-c-projects/chapter-2/). It was part of my computer’s `AUTOEXEC.BAT` program, which ran each time I started my trusty ol’ IBM PC. Because I’m fond of nostalgia, I’ve kept a copy of the program. Written in x86 Assembly, it still runs under DOSBox. Ah, the sweet perfume of the digital past. Smells like ozone.

[](/book/tiny-c-projects/chapter-2/)Alas, I no longer have the source code for my `GREET.COM` program[](/book/tiny-c-projects/chapter-2/). From memory (and disassembly), I see that the code fetches the current hour of the day and outputs an appropriate time-of-day greeting: good morning, good afternoon, or good evening. You can code the same trick—though in C for your current computer and not in x86 Assembly for an ancient IBM PC.

[](/book/tiny-c-projects/chapter-2/)Pulling together resources from the first chunk of this chapter, listing 2.5 shows a current version of my old greetings program.

##### Listing 2.5 Source code for greet03.c

```
#include <stdio.h>
#include <time.h>
 
int main(int argc, char *argv[])
{
    time_t now;
    struct tm *clock;
    int hour;
 
    time(&now);
    clock = localtime(&now);
    hour = clock->tm_hour;     #1
 
    printf("Good ");
    if( hour < 12 )            #2
        printf("morning");
    else if( hour < 17 )       #3
        printf("afternoon");
    else                       #4
        printf("evening");
 
    if( argc>1 )               #5
        printf(", %s",argv[1]);
 
    putchar('\n');
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-2/)Assuming that the built program is named `greetings`, that the user types in **Danny** as the command-line argument, and that it’s 4 o’clock in the afternoon, here is the code’s output:

```
Good afternoon, Danny
```

[](/book/tiny-c-projects/chapter-2/)This code effectively replicates what I wrote decades ago as my `GREET.COM` program[](/book/tiny-c-projects/chapter-2/). The output is a cheery, time-relevant greeting given the current time of day.

[](/book/tiny-c-projects/chapter-2/)For extra humor, you can add a test for early hours, such as midnight to 4:00 AM. Output some whimsical text such as “Working late?” or “Are you still up?” Oh, the jocularity! I hope your sides don’t [](/book/tiny-c-projects/chapter-2/)[](/book/tiny-c-projects/chapter-2/)hurt.

### [](/book/tiny-c-projects/chapter-2/)2.3.3 Adding specific time info

[](/book/tiny-c-projects/chapter-2/)Another [](/book/tiny-c-projects/chapter-2/)[](/book/tiny-c-projects/chapter-2/)way to treat yourself when you open a terminal window is to output a detailed time string. The simple way to accomplish this task is to output the greeting followed by a time string generated by the *ctime()* function[](/book/tiny-c-projects/chapter-2/). Here are the two relevant lines of code:

```
printf(“Good day, %s\n”,argv[1]);
printf(“It’s %s”,ctime(&now));
```

[](/book/tiny-c-projects/chapter-2/)These two statements reflect code presented earlier in this chapter, so you get the idea. Still, the program is lazy. Better to incorporate the *strftime()* function[](/book/tiny-c-projects/chapter-2/), which formats a timestamp string according to your specifications.

[](/book/tiny-c-projects/chapter-2/)The *strftime()* function[](/book/tiny-c-projects/chapter-2/) works like *printf()*, with a special string that formats time information. The function’s output is saved in a buffer, which your code can use later. The code shown in listing 2.6 demonstrates.

##### Listing 2.6 Source code for greet04.c

```
#include <stdio.h>
#include <time.h>
 
int main(int argc, char *argv[])
{
    time_t now;
    struct tm *clock;
    char time_string[64];        #1
 
    time(&now);
    clock = localtime(&now);     #2
 
    strftime(time_string,64,"Today is %A, %B %d, %Y%nIt is %r%n",clock);
 
    printf("Greetings");
    if( argc>1 )
        printf(", %s",argv[1]);
    printf("!\n%s",time_string);
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-2/)You can review the *man* page[](/book/tiny-c-projects/chapter-2/) for *strftime()* to discover all the fun placeholders and what they do. Like the *printf()* function[](/book/tiny-c-projects/chapter-2/), the placeholders are prefixed by a `%` character. Any other text in the formatting string is output as is. Here are the highlights from the *strftime()* statement[](/book/tiny-c-projects/chapter-2/) in listing 2.6:

![](https://drek4537l1klr.cloudfront.net/gookin/Figures/02-00_UN01.png)

[](/book/tiny-c-projects/chapter-2/)The output reflects the time string generated and stored in the `time_string[]` buffer. The time string appears after the general greeting as covered earlier in this chapter:

```
Greetings, Danny!
Today is Wednesday, June 23, 2021
It is 04:24:47 PM
```

[](/book/tiny-c-projects/chapter-2/)At this point, some neckbeard might say that all this output can easily be accomplished by using a shell scripting language, which is the native tongue of the shell startup and configuration file anyway. Yes, such people exist. Still, as a C programmer, your job is to offer more insight and power to the greeting. Such additions aren’t possible when using a sad little shell scripting language. [](/book/tiny-c-projects/chapter-2/)[](/book/tiny-c-projects/chapter-2/)So [](/book/tiny-c-projects/chapter-2/)there.

[](/book/tiny-c-projects/chapter-2/)My [](/book/tiny-c-projects/chapter-2/)sense is that most programmers operate best at night. So why bother programming a moon phase greeting when you can just pop your head out a window and look up?

[](/book/tiny-c-projects/chapter-2/)You’re correct: the effort is too much trouble, especially when you can write a C program to get a good approximation of the moon phase while remaining safely indoors. You can even delight yourself with this interesting tidbit every time you start a terminal window. Outside? It’s overrated.

### [](/book/tiny-c-projects/chapter-2/)2.4.1 Observing moon phases

[](/book/tiny-c-projects/chapter-2/)The [](/book/tiny-c-projects/chapter-2/)ancient Mayans wrote the first moon phase algorithm, probably in COBOL. I’d print a copy of the code here, but it’s just easier to express the pictogram: it’s a little guy squatting on a rock, extending a long tongue, wearing a festive hat, and wearing an angry expression on his face. Programmers know this stance well.

[](/book/tiny-c-projects/chapter-2/)The moon goes through phases as it orbits the Earth. The phases are based on how much of the moon is exposed to sunlight as seen from Earth. Figure 2.1 illustrates the moon’s orbit. The sunny side always faces the sun, though from the Earth we see different portions of the moon illuminated. These are the moon’s phases.

![Figure 2.1 The moon’s orbit affects how much of the illuminated side is visible from Earth.](https://drek4537l1klr.cloudfront.net/gookin/Figures/02-01.png)

[](/book/tiny-c-projects/chapter-2/)The phases as they appear from an earthling’s perspective are named and illustrated in figure 2.2. During its 28-day journey, the moon’s phase changes from new (no illumination) to full and back to new again. Further, half the time, the moon is visible (often barely) during daylight hours.

![Figure 2.2 Moon phases as seen from Earth](https://drek4537l1klr.cloudfront.net/gookin/Figures/02-02.png)

[](/book/tiny-c-projects/chapter-2/)The phases shown in figure 2.2 follow the moon’s progress from new to full and back again. The latter waning phases happen in the morning, which is why they’re only popular with men named [](/book/tiny-c-projects/chapter-2/)Wayne.

### [](/book/tiny-c-projects/chapter-2/)2.4.2 Writing the moon phase algorithm

[](/book/tiny-c-projects/chapter-2/)Without [](/book/tiny-c-projects/chapter-2/)looking outside right now, can you tell the moon phase?

[](/book/tiny-c-projects/chapter-2/)Yes, I assume that you’re reading this book at night. Programmers are predictable. Congratulations if you’re reading this book during the day—outside, even. Regardless of the time, the moon has a current phase. Not a moody teenager phase, but one of the moon how-much-is-illuminated thingies covered in the preceding section.

[](/book/tiny-c-projects/chapter-2/)To determine the moon phase without looking outside or in a reference, you use an algorithm. These are abundant and available on the internet as well as carved into Mayan tablets. The key is the moon’s predictable cycle, which can be mapped to days, months, and years. The degree of accuracy of the algorithm depends on a lot of things, such as your location and the time of day. And if you want to be exact, you must use complex geometry and messy stuff I don’t even want to look at through one eye half-shut.

[](/book/tiny-c-projects/chapter-2/)Listing 2.7 shows the moon_phase() function[](/book/tiny-c-projects/chapter-2/). It contains an algorithm I found years ago, probably on the old ARPANET. My point is: I don’t know where it came from. It’s mostly accurate, which is what I find of typical moon phase algorithms that don’t use complex and frightening math functions.

##### Listing 2.7 The *moon_phase()* function

```
int moon_phase(int year,int month,int day)
{
   int d,g,e;

   d = day;
   if(month == 2)
       d += 31;
   else if(month > 2)
       d += 59+(month-3)*30.6+0.5;
   g = (year-1900)%19;
   e = (11*g + 29) % 30;
   if(e == 25 || e == 24)
       ++e;
   return ((((e + d)*6+5)%177)/22 & 7);
}
```

[](/book/tiny-c-projects/chapter-2/)The algorithm presented in listing 2.7 requires three arguments: the integers `year`, `month`, and `day`. These are the same as values found in the members of a *localtime()* `tm` structure: `tm_year+1900` for the year, `tm_mon` for the month (which starts with 0 for January), and `tm_day` for the day of the month, starting with 1.

[](/book/tiny-c-projects/chapter-2/)Here’s how I’m going to explain how the algorithm works: I’m not. Seriously, I have no clue what’s going on. I just copied down the formula from somewhere and—by golly—it mostly works. Mostly.

[](/book/tiny-c-projects/chapter-2/)Insert the code from listing 2.7 into your favorite greetings program. If you paste it in above the *main()* function, it won’t require a prototype. Otherwise, prototype it as:

```
int moon_phase(int year,int month,int day);
```

[](/book/tiny-c-projects/chapter-2/)The function returns an integer in the range of 0 to 7 representing the eight moon phases shown earlier in figure 2.2, and in that order. An array of strings representing these phases, matching up to the value returned by the *moon_phase()* function[](/book/tiny-c-projects/chapter-2/), looks like this:

```
char *phase[8] = {
       "waxing crescent", "at first quarter",
       "waxing gibbous", "full", "waning gibbous",
       "at last quarter", "waning crescent", "new"
};
```

[](/book/tiny-c-projects/chapter-2/)You can craft the rest of the code yourself. I’ve included it as `moon.c` in this book’s code repository as described in the introduction, which you haven’t read.

[](/book/tiny-c-projects/chapter-2/)With this knowledge in hand, you can easily add the moon phase as output to your terminal program’s initial greeting. One thing you don’t want to do, however, is use this moon phase algorithm to accurately predict the moon phase. Seriously, it’s for fun only. Don’t use this algorithm to launch a manned rocket to the moon. I’m looking at you, [](/book/tiny-c-projects/chapter-2/)Italy.

### [](/book/tiny-c-projects/chapter-2/)2.4.3 Adding the moon phase to your greeting

[](/book/tiny-c-projects/chapter-2/)You [](/book/tiny-c-projects/chapter-2/)[](/book/tiny-c-projects/chapter-2/)can add the *moon_phase()* function[](/book/tiny-c-projects/chapter-2/) to any of the source code samples for the greetings series of programs listed in this chapter. You need to fetch time-based data, which the *moon_phase()* function[](/book/tiny-c-projects/chapter-2/) requires to make its calculation. You also need an array of strings to output the current moon phase text based on the value the function returns.

[](/book/tiny-c-projects/chapter-2/)Listing 2.6, showing the `greet04.c` source code, is the best candidate for modification. Make the following changes:

[](/book/tiny-c-projects/chapter-2/)Add a declaration in the main() function for integer variable `mp`[](/book/tiny-c-projects/chapter-2/) to hold the value returned from the *moon_phase()* function[](/book/tiny-c-projects/chapter-2/):

```
int mp;
```

[](/book/tiny-c-projects/chapter-2/)Add the following two statements after the last *printf()* statement[](/book/tiny-c-projects/chapter-2/) in the existing code, just before the *return*:

```
mp = moon_phase(clock->tm_year+1900,clock->tm_mon,clock->tm_mday);
printf("The moon is %s\n",phase[mp]);
```

[](/book/tiny-c-projects/chapter-2/)You could combine these statements into a single *printf()* statement[](/book/tiny-c-projects/chapter-2/), eliminating the need for the `mp` variable[](/book/tiny-c-projects/chapter-2/): Insert the *moon_phase()* function[](/book/tiny-c-projects/chapter-2/) call (the first line) into the brackets in the *printf()* statement[](/book/tiny-c-projects/chapter-2/). The result is a painfully long line of code, which is why I split it up. I’d choose readability over a long line of code any day.

[](/book/tiny-c-projects/chapter-2/)A final copy of `greet05.c` can be found in this book’s GitHub repository. Here is sample output:

```bash
$ greetings Danny
Greetings, Danny!
Today is Thursday, June 24, 2021
It is 10:02:33 PM
The moon is full
```

[](/book/tiny-c-projects/chapter-2/)Imagine the delight your users will have, seeing such a meaty message at the start of their terminal window day. They’ll lean back and smile, giving a thankful nod as they say, “I appreciate the scintillating details, my programmer friend. Glad I don’t have to venture outside [](/book/tiny-c-projects/chapter-2/)[](/book/tiny-c-projects/chapter-2/)tonight. [](/book/tiny-c-projects/chapter-2/)Thank you.”

## [](/book/tiny-c-projects/chapter-2/)2.5 A pithy saying

[](/book/tiny-c-projects/chapter-2/)The [](/book/tiny-c-projects/chapter-2/)`fortune` program[](/book/tiny-c-projects/chapter-2/) has been a staple of shell startup scripts since the old days, back when some Unix terminals were treadle powered. It remains available today, easily installed from your distro’s package manager; search for “fortune.”

[](/book/tiny-c-projects/chapter-2/)The name “fortune” comes from the fortune cookie. The idea is to generate a pithy saying, or *bon mot*, which you can use as fresh motivation to start your day. These are inspired by the desserts provided at some Chinese restaurants, which serve the purpose of holding down the paper ticket more than they provide any nutritional value.

[](/book/tiny-c-projects/chapter-2/)Here is an example of a digital fortune cookie, output from the `fortune` program[](/book/tiny-c-projects/chapter-2/):

```bash
$ fortune
There is no logic in the computer industry.
              --Dan Gookin
```

[](/book/tiny-c-projects/chapter-2/)It’s possible to replicate the `fortune` program output[](/book/tiny-c-projects/chapter-2/), providing you have a database of pithy sayings and a program eager to pluck out a random one.

### [](/book/tiny-c-projects/chapter-2/)2.5.1 Creating a pithy phrase repository

[](/book/tiny-c-projects/chapter-2/)The [](/book/tiny-c-projects/chapter-2/)`fortune` program[](/book/tiny-c-projects/chapter-2/) comes with one or more databases of witticisms. It’s from this database that the fortune cookie message is retrieved and output on the screen. You could borrow from this list, but that’s cheating. It’s also silly, because the `fortune` program[](/book/tiny-c-projects/chapter-2/) is already written. You’d learn nothing. For shame!

[](/book/tiny-c-projects/chapter-2/)Your goal is to write your own version of the pithy phrase database. It need not be quotes or humor, either. The list could contain tips about using the computer, reminders about IT security, and other important information, like the current, trendy hairstyles.

[](/book/tiny-c-projects/chapter-2/)I can imagine several ways to configure the list. This planning is vital to writing good code: a well-organized list means you have less coding to do. The goal is to pluck a random phrase from the repository, which means an organized file is a must. Figure 2.3 outlines the process for writing code to pluck a random, pithy phrase from a list or database.

![Figure 2.3 The process for reading a random, pithy quote from a file](https://drek4537l1klr.cloudfront.net/gookin/Figures/02-03.png)

[](/book/tiny-c-projects/chapter-2/)I can imagine several approaches to formatting the file, as covered in table 2.2.

##### [](/book/tiny-c-projects/chapter-2/)Table 2.2 Approaches to storing sayings for easy access[(view table figure)](https://drek4537l1klr.cloudfront.net/gookin/HighResolutionFigures/table_2-2.png)

| [](/book/tiny-c-projects/chapter-2/)File format/data | [](/book/tiny-c-projects/chapter-2/)Pros | [](/book/tiny-c-projects/chapter-2/)Cons |
| --- | --- | --- |
| [](/book/tiny-c-projects/chapter-2/)Basic text file | [](/book/tiny-c-projects/chapter-2/)Simple to maintain using existing tools | [](/book/tiny-c-projects/chapter-2/)The file must be read and indexed every time the program runs. |
| [](/book/tiny-c-projects/chapter-2/)Formatted file with an initial item count reflecting the number of entries | [](/book/tiny-c-projects/chapter-2/)Item count can be read instantly | [](/book/tiny-c-projects/chapter-2/)The item count must be updated as the list is modified. |
| [](/book/tiny-c-projects/chapter-2/)Hash table with indexed entries | [](/book/tiny-c-projects/chapter-2/)Easy to read and access each record | [](/book/tiny-c-projects/chapter-2/)You will most likely need a separate program to maintain the list, which is more coding to do. |

[](/book/tiny-c-projects/chapter-2/)I prefer the basic text file for my list, which means more overhead is required in order to fetch a random entry. It also means that I don’t need to write a list maintenance program. Another benefit is that anyone can edit the sayings file, adding and removing entries at their whim.

[](/book/tiny-c-projects/chapter-2/)Eschewing all other options, my approach is to read the file a line at a time, storing and indexing each line in memory. The file needs to be read only once with this method, so it’s what I choose to do. The downside? I must manage memory locations, also known as *pointers*[](/book/tiny-c-projects/chapter-2/).

[](/book/tiny-c-projects/chapter-2/)Fret not, gentle reader.

[](/book/tiny-c-projects/chapter-2/)The bonus of my approach (forgetting pointers for the moment) is that you can use any text file for your list. Files with short lines of text work best; otherwise, you must wrap the text on the terminal screen, which is more work. The file `pithy.txt` can be found in this book’s GitHub [](/book/tiny-c-projects/chapter-2/)repository.

### [](/book/tiny-c-projects/chapter-2/)2.5.2 Randomly reading a pithy phrase

[](/book/tiny-c-projects/chapter-2/)My [](/book/tiny-c-projects/chapter-2/)pithy-phrase greetings program reads lines of text from the repository file, allocating storage space for each string read. As the lines are read and stored, an index is created. This index is a pointer array, but one created dynamically by allocating storage as the file is read. This approach is complex in that it involves those horrifying pointer-pointer things (two-asterisk notation) and liberal use of the *malloc*[](/book/tiny-c-projects/chapter-2/)() and *realloc()* function[](/book/tiny-c-projects/chapter-2/). I find such activity enjoyable, but I also enjoy natto. So there.

[](/book/tiny-c-projects/chapter-2/)As with any complex topic in programming, the best way to tackle the project is to code it one step at a time. The first step is to read a text file and output its contents. The code in listing 2.8 accomplishes this first task by reading lines of text from the file `pithy.txt`. Remember, this code is just the start. The pointer insanity is added later.

##### Listing 2.8 Source code for pithy01.c

```
#include <stdio.h>
#include <stdlib.h>
 
#define BSIZE 256
 
int main()
{
    const char filename[] = "pithy.txt";   #1
    FILE *fp;
    char buffer[BSIZE];                    #2
    char *r;
 
    fp = fopen(filename,"r");
    if( fp==NULL )
    {
        fprintf(stderr,"Unable to open file %s\n",filename);
        exit(1);
    }
 
    while( !feof(fp) )                     #3
    {
        r = fgets(buffer,BSIZE,fp);        #4
        if( r==NULL )
            break;
        printf("%s",buffer);               #5
    }
 
    fclose(fp);
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-2/)The purpose of `pithy01.c` is to read all the lines from the file. That’s it. Each line is stored in char array `buffer[]` and then output. The same buffer is used over and over.

[](/book/tiny-c-projects/chapter-2/)The program’s output is a dump of the contents of file `pithy.txt`. For a release program, your code must ensure that the proper path to `pithy.txt` (or whatever file you choose) is confirmed and made available.

[](/book/tiny-c-projects/chapter-2/)Build and run to prove it works. Fix any problems. When it’s just right, move on to the next step: use a pointer and allocate memory to store the strings read. Remember, the final program stores all the file’s strings in memory. Because the number of strings is unknown, this allocation method works better than guessing an array size.

[](/book/tiny-c-projects/chapter-2/)To proceed with the next improvement, a new variable entry[](/book/tiny-c-projects/chapter-2/) is introduced. It’s a char pointer[](/book/tiny-c-projects/chapter-2/), which must be allocated based on the size of the line read from the file. Once allocated, the contents of `buffer[]` are copied into the memory chunk referenced by pointer `entry`. It’s this string that’s output, not the contents of `buffer[]`.

[](/book/tiny-c-projects/chapter-2/)Another improvement is to count the number of items read from the file. For this task, the *int* variable `items`[](/book/tiny-c-projects/chapter-2/)[](/book/tiny-c-projects/chapter-2/) is added, initialized, and incremented within the *while* loop.

[](/book/tiny-c-projects/chapter-2/)Here are the updates to the code: Add a line to include the `string.h` header file, required for the *strcpy()* function[](/book/tiny-c-projects/chapter-2/):

```
#include <string.h>
```

[](/book/tiny-c-projects/chapter-2/)In the variable declarations part of the code, add *char* pointer `entry` and *int* variable `items`[](/book/tiny-c-projects/chapter-2/):

```
char *r,*entry;
int items;
```

[](/book/tiny-c-projects/chapter-2/)Before the *while* loop, initialize variable `items`[](/book/tiny-c-projects/chapter-2/) to zero:

```
items = 0;
```

[](/book/tiny-c-projects/chapter-2/)Within the *while* loop, memory is allocated for variable `entry`[](/book/tiny-c-projects/chapter-2/). The pointer must be tested to ensure memory is available. Then the contents of `buffer[]` are copied to `entry`, the contents of `entry` output, and the `items` variable[](/book/tiny-c-projects/chapter-2/) incremented. Here is the chunk of code to replace the existing *printf()* statement[](/book/tiny-c-projects/chapter-2/) in the original program:

```
entry = (char *)malloc(sizeof(char) * strlen(buffer)+1);     #1
if( entry==NULL )
{
    fprintf(stderr,"Unable to allocate memory\n");
    exit(1);
}
strcpy(entry,buffer);
printf("%d: %s",items,entry);
items++;
```

[](/book/tiny-c-projects/chapter-2/)These updates, found in the online repository in `pithy02.c`, only change the output by prefixing each line read with its item number, starting with zero for the first line read from the file. While this update may seem tiny, it’s necessary to continue with the next step, which is dynamically storing all the strings read from the file into memory.

[](/book/tiny-c-projects/chapter-2/)As the program sits now, it allocates a series of buffers to store the strings read. Yet the addresses for these buffers are lost in memory. To resolve this issue, a pointer-pointer is required. The pointer-pointer, or address of a pointer, keeps track of all the string’s memory locations. This improvement is where the code earns its NC-17 rating.

[](/book/tiny-c-projects/chapter-2/)To track the strings stored in memory, make these improvements to `pithy02.c`, which now becomes `pithy03.c`:

[](/book/tiny-c-projects/chapter-2/)Add a second *int* variable, `x`, used in a later *for* loop. Also add the pointer-pointer variable `list_base`[](/book/tiny-c-projects/chapter-2/)[](/book/tiny-c-projects/chapter-2/):

```
int items,x;
char **list_base;
```

[](/book/tiny-c-projects/chapter-2/)The `list_base` variable[](/book/tiny-c-projects/chapter-2/) keeps track of the `entry` pointers[](/book/tiny-c-projects/chapter-2/)[](/book/tiny-c-projects/chapter-2/) allocated later in the code. But first, the `list_base` pointer[](/book/tiny-c-projects/chapter-2/) must be allocated itself. Insert this code just after the file is opened and before the *while* loop:

```
list_base = (char **)malloc(sizeof(char *) * 100);
if( list_base==NULL )
{
   fprintf(stderr,"Unable to allocate memory\n");
   exit(1);
}
```

[](/book/tiny-c-projects/chapter-2/)The illustration in figure 2.4 shows what’s happening with the first statement allocating variable `list_base`[](/book/tiny-c-projects/chapter-2/). It’s a pointer to a pointer, which requires the `**` notation. The items it references are character pointers. The size of the list is 100 entries, which is good enough—for now.

![Figure 2.4 How the terrifying pointer-pointer buffer is allocated](https://drek4537l1klr.cloudfront.net/gookin/Figures/02-04.png)

[](/book/tiny-c-projects/chapter-2/)Within the *while* loop, remove the *printf()* statement[](/book/tiny-c-projects/chapter-2/). Outputting statements takes place outside the loop. In place of the *printf()* statement[](/book/tiny-c-projects/chapter-2/), add this statement below the *strcpy()* statement[](/book/tiny-c-projects/chapter-2/):

```
*(list_base+items) = entry;
```

[](/book/tiny-c-projects/chapter-2/)Using the offset provided by the `items` count, this statement copies the address stored in pointer variable `entry`[](/book/tiny-c-projects/chapter-2/) into the list maintained at location `list_base`. Only the address is copied, not the entire string. This statement represents crazy pointer stuff—and it works. Figure 2.5 illustrates how the crazy kit ’n’ kaboodle looks.

![Figure 2.5 The list_base and items variables help store strings allocated by the entry pointer.](https://drek4537l1klr.cloudfront.net/gookin/Figures/02-05.png)

[](/book/tiny-c-projects/chapter-2/)Finally, after the file is closed, output all the items with this *for* loop:

```
for( x=0; x<items; x++ )
   printf("%s",*(list_base+x));
```

[](/book/tiny-c-projects/chapter-2/)In this loop, variable `x` sets the offset in the list of addresses: `*(list_base+x)` references each line of text read from the file, now stored in memory.

[](/book/tiny-c-projects/chapter-2/)At this point, the program effectively reads all the text from the file, stores the text in memory, and keeps track of each string. Before a random string can be plucked out of the lot, care must be taken to consider when more than 100 lines are read from the file.

[](/book/tiny-c-projects/chapter-2/)When memory is allocated for the `list_base` variable[](/book/tiny-c-projects/chapter-2/), only 100 pointers can be stored in that memory chunk. If the value of variable `items`[](/book/tiny-c-projects/chapter-2/) creeps above 100, a memory overflow occurs. To prevent this catastrophe, the code must reallocate memory for `list_base`. This way, if the file that’s read contains more than 100 lines of text, they can be stored in memory without the program puking all over itself.

[](/book/tiny-c-projects/chapter-2/)To reallocate memory, or to increase the size of an already-created buffer, use the *realloc()* function[](/book/tiny-c-projects/chapter-2/). Its arguments are the existing buffer’s pointer and the new buffer size. Upon success, the contents of the old buffer are copied into the new, larger buffer. For the size of `list_base` to be increased, it must be reallocated to another 100 char pointer-sized chunks.

[](/book/tiny-c-projects/chapter-2/)Only one change is required in order to update the code. The following lines are inserted at the end of the *while* loop, just after the `items` variable[](/book/tiny-c-projects/chapter-2/) is incremented:

```
if( items%100==0 )                                                         #1
{
    list_base = (char **)realloc(list_base,sizeof(char *)*(items+100));    #2
    if( list_base==NULL )
    {
        fprintf(stderr,"Unable to reallocate memory\n");
        exit(1);
    }
}
```

[](/book/tiny-c-projects/chapter-2/)This update is saved as `pithy04.c`. The code runs the same as the program generated from `pithy03.c`, though if the file that’s read contains more than 100 lines of text, each is properly allocated, stored, and referenced without disaster.

[](/book/tiny-c-projects/chapter-2/)The program is now ready to do its job: to select and output a random item from the file. The final step is to remove the *for* loop at the end of the code; it’s no longer needed, as the program is required to output only one random line from the file.

[](/book/tiny-c-projects/chapter-2/)Start by including the `time.h` header file:

```
#include <time.h>
```

[](/book/tiny-c-projects/chapter-2/)Replace the declaration for its *int* variable `x` with a declaration for new variable `saying`[](/book/tiny-c-projects/chapter-2/):

```
int items,saying;
```

[](/book/tiny-c-projects/chapter-2/)Three lines are added to the end of the code, just above the *return* statement:

```
srand( (unsigned)time(NULL) );
saying = rand() % (items-1);
printf("%s",*(list_base+saying));
```

[](/book/tiny-c-projects/chapter-2/)This is the final update to the code, available in the online repository as `pithy05.c`. When run, the program extracts a random line from the file, outputting its text.

[](/book/tiny-c-projects/chapter-2/)As I wrote earlier in this section, this approach is only one way to resolve the problem. It’s quick and it works, which is good enough to add a pithy saying to your shell startup script.

[](/book/tiny-c-projects/chapter-2/)One final note: the program doesn’t release any memory directly. Normally, the end of a function would be dotted with *free()* statements[](/book/tiny-c-projects/chapter-2/), one for each memory chunk allocated. Because the entire code dwells within the *main()* function, freeing memory isn’t necessary. The memory allocated is freed when the program quits. Had the allocation taken place in a function, however, it’s necessary to release the allocation or risk losing the memory chunk and potentially causing a memory [](/book/tiny-c-projects/chapter-2/)overflow.

### [](/book/tiny-c-projects/chapter-2/)2.5.3 Adding the phrase to your greeting code

[](/book/tiny-c-projects/chapter-2/)If [](/book/tiny-c-projects/chapter-2/)[](/book/tiny-c-projects/chapter-2/)your goal is to modify a single greetings program for the shell’s startup script, your next task is to add the code from the pithy series of programs into your greetings program. Such a task would keep all your efforts in a single program and all the output on a single line in the shell startup script.

[](/book/tiny-c-projects/chapter-2/)Because the *pithy* program is kinda fun, I’m not incorporating it into my previous greetings program code. Instead, I’ll leave it as its own line in the shell startup script. That way, I can also run the program from the command prompt any time I need to be humored or am in need of levity. You can work to incorporate the pithy program into your greetings program [](/book/tiny-c-projects/chapter-2/)[](/book/tiny-c-projects/chapter-2/)on [](/book/tiny-c-projects/chapter-2/)your own.
