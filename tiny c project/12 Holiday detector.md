# [](/book/tiny-c-projects/chapter-12/)12 Holiday detector

[](/book/tiny-c-projects/chapter-12/)No matter [](/book/tiny-c-projects/chapter-12/)the time of year, it seems that a holiday looms on the horizon. It could be a religious holiday, a national day, or some other festive event. Many people may get the day off from work to celebrate. For programmers, the holiday is also a celebration but not from work: coders still code, but it’s a more enjoyable experience because everyone else is on vacation, which means fewer interruptions.

[](/book/tiny-c-projects/chapter-12/)Your computer doesn’t care whether one day is a holiday. It’s not being ignorant; it just doesn’t know. To help the computer understand which day is a holiday, and to help you complete other programming projects that rely upon knowing which days are holidays, you must:

-  [](/book/tiny-c-projects/chapter-12/)Understand how the operating system uses return values
-  [](/book/tiny-c-projects/chapter-12/)Work with date programming in C
-  [](/book/tiny-c-projects/chapter-12/)Review major holidays
-  [](/book/tiny-c-projects/chapter-12/)Calculate regular holidays
-  [](/book/tiny-c-projects/chapter-12/)Deal with irregular holidays
-  [](/book/tiny-c-projects/chapter-12/)Figure out when Easter occurs
-  [](/book/tiny-c-projects/chapter-12/)Put your holiday function to the test

[](/book/tiny-c-projects/chapter-12/)These tasks help build routines that detect and report on holidays given a specific day of the year. Such a utility isn’t specifically useful by itself, but it does come into play when programming dates or performing other tasks where knowing when a holiday occurs is important. For example, I wrote a stock tracker where it was useful to know which days not to fetch the stock data because the markets are closed. And my trash pickup reminder shell script uses my holiday program to see whether trash day has shifted.

[](/book/tiny-c-projects/chapter-12/)The routines presented in this chapter also play a role in the calendar programs introduced in chapter 13.

## [](/book/tiny-c-projects/chapter-12/)12.1 The operating system wants its vig

[](/book/tiny-c-projects/chapter-12/)Ever [](/book/tiny-c-projects/chapter-12/)[](/book/tiny-c-projects/chapter-12/)wonder why *main()* is an integer function? Years ago, C programmers freely declared it a *void* function. Scandalous! Old programmers may still pull a `void` `main()` in their code. Goodness, even the first edition of the venerable K&R—*The C Programming Language* (Prentice-Hall)—didn’t even bother to cast the *main()* function. Try not to work yourself into a tizzy.

[](/book/tiny-c-projects/chapter-12/)The reason the *main()* function is cast as an *int* is that it must return a value to the operating system. Like any loan shark, when the operating system releases some of its resources (memory and processor time) to another program, it wants something in return, such as the interest—vigorish, or “vig.” That something is an integer value. This value is often ignored (just don’t miss a payment), or it’s used in some clever and innovative way. Either way, the value is required.

### [](/book/tiny-c-projects/chapter-12/)12.1.1 Understanding exit status versus the termination status

[](/book/tiny-c-projects/chapter-12/)More [](/book/tiny-c-projects/chapter-12/)[](/book/tiny-c-projects/chapter-12/)[](/book/tiny-c-projects/chapter-12/)[](/book/tiny-c-projects/chapter-12/)than one way exists to stop a program. The natural way is for the program to end normally, with a return statement at the end of the *main()* function passing its value back to the operating system. This value is officially known as the program’s exit status.

[](/book/tiny-c-projects/chapter-12/)If the program stops before the *main()* function exits, it has a termination status. For example, an *exit()* statement nestled in a function other than *main()* halts a program. In this case, the value that *exit()* passes to the operating system is known as the termination status.

[](/book/tiny-c-projects/chapter-12/)Termination status. Exit status. Yes, the nerds love to pick nits. The point is that the way the program quits affects how the value returned is interpreted. Many functions that spawn other programs (processes) use a termination status and not an exit status. The termination status is typically 0 for success or -1 otherwise. This value is different from whatever the exit status might be. Be aware of this difference as you code your programs, and especially if you choose to dialogue with [](/book/tiny-c-projects/chapter-12/)[](/book/tiny-c-projects/chapter-12/)[](/book/tiny-c-projects/chapter-12/)[](/book/tiny-c-projects/chapter-12/)nerds.

### [](/book/tiny-c-projects/chapter-12/)12.1.2 Setting a return value

[](/book/tiny-c-projects/chapter-12/)The [](/book/tiny-c-projects/chapter-12/)[](/book/tiny-c-projects/chapter-12/)*return* statement in the *main()* function is responsible for sending a value back to the operating system. Sending an integer value up to the mothership is vital for the *main()* function: miss it, and the compiler points its bony finger at you and shrieks like Donald Sutherland at the end of *Invasion of the Body Snatchers*.

[](/book/tiny-c-projects/chapter-12/)The next listing shows the source code for `return01.c`. This program has only one job: to return a value to the operating system. If the value isn’t specified as a command-line argument, zero is returned.

##### Listing 12.1 Source code for return01.c

```
#include <stdlib.h>                            #1
 
int main(int argc, char *argv[])
{
    if( argc>1 )                               #2
    {
        return( strtol(argv[1],NULL,10) );     #3
    }
    else
    {
        return(0);                             #4
    }
}
```

[](/book/tiny-c-projects/chapter-12/)The *strtol()* function[](/book/tiny-c-projects/chapter-12/) in `return01.c` converts the string held in `argv[1]`, the first argument at the command prompt, into an integer value, base 10. If the string can’t be converted (it contains no digits), the value 0 is returned.

[](/book/tiny-c-projects/chapter-12/)The program surrenders its value via the *return* statement. The *exit()* function[](/book/tiny-c-projects/chapter-12/) could also be used, but this value is an exit status, not a termination status. (I wrote that for the nerds; don’t worry about the difference here.)

[](/book/tiny-c-projects/chapter-12/)Here is a sample run:

[](/book/tiny-c-projects/chapter-12/)Yes, the code lacks output, even when you specify an argument. And, yes, the value returned is consumed by the operating system. It’s available for the shell to interpret. Despite being a loan shark, the operating system rarely if ever does anything with a program’s return value. This job can be done by other programs, but specifically the exit status is available for use by shell [](/book/tiny-c-projects/chapter-12/)[](/book/tiny-c-projects/chapter-12/)scripts.

### [](/book/tiny-c-projects/chapter-12/)12.1.3 Interpreting the return value

[](/book/tiny-c-projects/chapter-12/)The [](/book/tiny-c-projects/chapter-12/)[](/book/tiny-c-projects/chapter-12/)value a program poops out is left on the operating system’s doorstep. Though nothing needs to be done with the value, it remains available for the shell to use—until another program deposits another value.

[](/book/tiny-c-projects/chapter-12/)To demonstrate how the return value is accessed from the shell, rerun the program for `return01.c`:, type the program name, assumed to be *return01*, and a value as an argument, such as:

```bash
$ ./return01 27
```

[](/book/tiny-c-projects/chapter-12/)The program returns the value 27 to the operating system. This value is accessed via the shell scripting variable `$?`. To see it, type the *echo* command[](/book/tiny-c-projects/chapter-12/) followed by `$?`:

```bash
$ echo $?
27
```

[](/book/tiny-c-projects/chapter-12/)Shell scripts can use this value to determine the result of some operation. Alas, in Linux it’s difficult for a non-shell script program to read the return value of another program it spawns. Such a task is possible, and I could so easily get sidetracked to describe the thrilling details, but it’s beyond the scope of this chapter.

[](/book/tiny-c-projects/chapter-12/)The source code for `return02.c` in the following listing attempts to capture the value returned from the *return01* program[](/book/tiny-c-projects/chapter-12/). The *system()* function[](/book/tiny-c-projects/chapter-12/) is used to execute *return01* with a return value of 99. The purpose of the program is to show how the *system()* function[](/book/tiny-c-projects/chapter-12/) doesn’t capture a program’s return value.

##### Listing 12.2 Source code for return02.c

```
#include <stdio.h>
#include <stdlib.h>
 
int main()
{
    int r;
 
    r = system("./return01 99");            #1
    printf("The return value is %d\n",r);   #2
 
    return(r);
}
```

[](/book/tiny-c-projects/chapter-12/)The *system()* function’s single argument is something you would type at the command prompt. The function can return a variety of values, though if the call is successful, the value returned is the termination status of the shell launched to run the program. The value is not the return value of the program run. Here’s a sample run:

```
The return value is 25344
```

[](/book/tiny-c-projects/chapter-12/)After running the *system()* function, the shell returns the value 25344 to the operating system.

[](/book/tiny-c-projects/chapter-12/)In Windows, the *system()* function works differently. Unlike with Linux, it returns the value generated by any program run. Here’s sample output of the same code built in Windows, with the option 99 specified:

```
The return value is 99
```

[](/book/tiny-c-projects/chapter-12/)As an old MS-DOS/Windows coder, I remember using this trick with the *system()* function[](/book/tiny-c-projects/chapter-12/) ages ago in various programs. Because system() behaves differently in Linux, relying upon the function to report a program’s return value isn’t anything you should do.

[](/book/tiny-c-projects/chapter-12/)Yes, I know: the *system()* function[](/book/tiny-c-projects/chapter-12/) in Linux does, in fact, return the exit status of the program run—the shell. The point I’m making is that the function can’t be used to examine another program’s return value.

[](/book/tiny-c-projects/chapter-12/)Other functions that spawn a process—*fork[](/book/tiny-c-projects/chapter-12/)()*, *popen[](/book/tiny-c-projects/chapter-12/)()*, and so on—behave similarly to *system()*: the program spawned may generate an exit status, but this value isn’t reported by the function making the call.

[](/book/tiny-c-projects/chapter-12/)As I wrote earlier, it’s possible to spawn a process and capture its return value. If you’re curious to know the procedure, visit my blog and search for the wait() function[](/book/tiny-c-projects/chapter-12/): [](/book/tiny-c-projects/chapter-12/)[](/book/tiny-c-projects/chapter-12/)[https://c-for-dummies.com/blog](https://c-for-dummies.com/blog/).

### [](/book/tiny-c-projects/chapter-12/)12.1.4 Using the preset return values

[](/book/tiny-c-projects/chapter-12/)The[](/book/tiny-c-projects/chapter-12/)[](/book/tiny-c-projects/chapter-12/) C overlords want you to know that an exit status of 0 indicates success; everything went as planned. An exit status of 1 means something went wrong. I use this consistency in my code, but don’t use the defined constants available in the `stdlib.h` header file:

```
EXIT_FAILURE
EXIT_SUCCESS
```

[](/book/tiny-c-projects/chapter-12/)These two values are defined as 1 and 0 for failure and success, respectively. The defined constants are consistent—the same for all compilers and platforms.

[](/book/tiny-c-projects/chapter-12/)The next listing shows the source code for `return03.c`, which generates a random integer, 0 or 1. This value is used to determine which defined constant is returned as an exit status: `EXIT_FAILURE`[](/book/tiny-c-projects/chapter-12/) or `EXIT_SUCCESS`[](/book/tiny-c-projects/chapter-12/).

##### Listing 12.3 Source code for return03.c

```
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
 
int main()
{
    int r;
 
    srand( (unsigned)time(NULL) );                                #1
 
    r = rand() % 2;                                               #2
    if(r)                                                         #3
    {
        fprintf(stderr,"Welp, this program screwed [CA]up!\n");   #4
        return(EXIT_FAILURE);
    }
    else
    {
        printf("Everything went ducky!\n");                       #5
        return(EXIT_SUCCESS);
    }
}
```

[](/book/tiny-c-projects/chapter-12/)The program’s output depends on the random number generated. To confirm the value, you can use the `$?` variable at the command prompt:

```bash
$ ./a.out
Welp, this program screwed up!
$ echo $?
1
```

[](/book/tiny-c-projects/chapter-12/)And:

```bash
$ ./a.out
Everything went ducky!
$ echo $?
0
```

[](/book/tiny-c-projects/chapter-12/)Remember, return values need not be limited to 0 and 1. Many programs and utilities return different values, each of which can be interpreted by a shell script to determine what happened. The interpretation of these values is up to whatever purpose the program has, to help it fulfill [](/book/tiny-c-projects/chapter-12/)[](/book/tiny-c-projects/chapter-12/)its [](/book/tiny-c-projects/chapter-12/)[](/book/tiny-c-projects/chapter-12/)function.

## [](/book/tiny-c-projects/chapter-12/)12.2 All about today

[](/book/tiny-c-projects/chapter-12/)Ages ago, US national holidays fell on specific days. I remember, when I was young, getting to take off both Lincoln’s birthday *and* George Washington’s birthday. As a kid, I’d take two days off school in February over a Nintendo Switch in a heartbeat.

[](/book/tiny-c-projects/chapter-12/)Well, maybe not.

[](/book/tiny-c-projects/chapter-12/)Before you can determine which day is a holiday, you need a point of reference. That point is today, the current date obtained from the operating system. Or you can backfill a `tm` structure with any old date and work from there. Both items are easy to obtain by invoking the proper C language functions.

### [](/book/tiny-c-projects/chapter-12/)12.2.1 Getting today’s date

[](/book/tiny-c-projects/chapter-12/)One [](/book/tiny-c-projects/chapter-12/)of the hallmarks of the early PC era was the prompt:

```
The current date is: Tue 1-01-1980
Enter the new date: (mm-dd-yy)
```

[](/book/tiny-c-projects/chapter-12/)MS-DOS didn’t know whether today was a holiday because it didn’t even know which day it was! The user had to input the current date. Eventually, technology was added to the motherboard to retain the current date and time. This setup is how modern computers work, but with the bonus of an internet time server to keep the clock accurate. Your C code can use this information to obtain the current date and time—as it’s known to the computer.

[](/book/tiny-c-projects/chapter-12/)The following listing shows the typical time code for the C language. The current epoch value—the number of seconds ticked since January 1, 1970—is obtained from the *time()* function[](/book/tiny-c-projects/chapter-12/) and stored in *time_t* variable `now`[](/book/tiny-c-projects/chapter-12/). This variable is used in the *localtime()* function[](/book/tiny-c-projects/chapter-12/) to fill a `tm` structure, `today`[](/book/tiny-c-projects/chapter-12/). The `tm` structure’s members contain individual time tidbit values, which are output.

##### Listing 12.4 Source code for getdate01.c

```
#include <stdio.h>
#include <time.h>
 
int main()
{
    time_t now;
    struct tm *today;
    int month,day,year,weekday;
 
    now = time(NULL);                    #1
    today = localtime(&now);             #2
 
    month = today->tm_mon+1;             #3
    day = today->tm_mday;
    weekday = today->tm_wday;
    year = today->tm_year+1900;          #4
 
    printf("Today is %d, %d %d, %d\n",   #5
            weekday,
            month,
            day,
            year
          );
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-12/)This code’s approach should be familiar to you if you’ve written any time-related programs. The output shows the current date in this format:

```
Today is 1, 12 6, 2021
```

[](/book/tiny-c-projects/chapter-12/)Of course, the output could be made readable by a human. Unless you’re a true nerd you may not recognize “1” as the value for Monday.

#### [](/book/tiny-c-projects/chapter-12/)Exercise 12.1

[](/book/tiny-c-projects/chapter-12/)Update the code for `getdate01.c` to output strings for the days of the week and months. This improvement requires adding two string arrays to the code and other updates, including to the *printf()* function[](/book/tiny-c-projects/chapter-12/).

[](/book/tiny-c-projects/chapter-12/)My solution is available in the online repository as `getdate02.c`. Please try this exercise on your own before you see how I did it. Comments in my code explain what’s going on—including an important point you will probably [](/book/tiny-c-projects/chapter-12/)forget.

### [](/book/tiny-c-projects/chapter-12/)12.2.2 Obtaining any old date

[](/book/tiny-c-projects/chapter-12/)The [](/book/tiny-c-projects/chapter-12/)*time()* function[](/book/tiny-c-projects/chapter-12/) obtains the current time, a *time_t* value containing the number of seconds elapsed from January 1, 1970. This value is useless by itself, which is why functions like *localtime[](/book/tiny-c-projects/chapter-12/)()* help sort out the details for you. But what about dates other than today?

[](/book/tiny-c-projects/chapter-12/)It’s possible to backfill a `tm` structure[](/book/tiny-c-projects/chapter-12/). You assign values to the various members, then use the *mktime()* function[](/book/tiny-c-projects/chapter-12/) to translate these time tidbits into a *time_t* value. Further, the *mktime()* function[](/book/tiny-c-projects/chapter-12/) fills in unknown details for you, such as the day of the week. This information is vital if you plan to determine upon which date a holiday falls.

[](/book/tiny-c-projects/chapter-12/)Here is the *man* page format[](/book/tiny-c-projects/chapter-12/) for the *mktime()* function[](/book/tiny-c-projects/chapter-12/):

```
time_t mktime(struct tm *tm);
```

[](/book/tiny-c-projects/chapter-12/)The function is passed the address of a partially filled `tm` structure[](/book/tiny-c-projects/chapter-12/). A *time_t* value is returned, but more importantly, the rest of the `tm` structure[](/book/tiny-c-projects/chapter-12/) is filled with key details.

[](/book/tiny-c-projects/chapter-12/)The *mktime()* function[](/book/tiny-c-projects/chapter-12/) is prototyped in the `time.h` header file.

[](/book/tiny-c-projects/chapter-12/)As a quick reference, table 12.1 shows the common members of a `tm` structure[](/book/tiny-c-projects/chapter-12/).

##### [](/book/tiny-c-projects/chapter-12/)Table 12.1 Members of the `tm` structure[(view table figure)](https://drek4537l1klr.cloudfront.net/gookin/HighResolutionFigures/table_12-1.png)

| [](/book/tiny-c-projects/chapter-12/)Member | [](/book/tiny-c-projects/chapter-12/)References | [](/book/tiny-c-projects/chapter-12/)Range/Notes |
| --- | --- | --- |
| [](/book/tiny-c-projects/chapter-12/)tm_sec[](/book/tiny-c-projects/chapter-12/) | [](/book/tiny-c-projects/chapter-12/)Seconds | [](/book/tiny-c-projects/chapter-12/)0 to 60 (60 allows for a leap second) |
| [](/book/tiny-c-projects/chapter-12/)tm_min[](/book/tiny-c-projects/chapter-12/) | [](/book/tiny-c-projects/chapter-12/)Minutes | [](/book/tiny-c-projects/chapter-12/)0 to 59 |
| [](/book/tiny-c-projects/chapter-12/)tm_hour[](/book/tiny-c-projects/chapter-12/) | [](/book/tiny-c-projects/chapter-12/)Hours | [](/book/tiny-c-projects/chapter-12/)0 to 23 |
| [](/book/tiny-c-projects/chapter-12/)tm_mday[](/book/tiny-c-projects/chapter-12/) | [](/book/tiny-c-projects/chapter-12/)Day of the month | [](/book/tiny-c-projects/chapter-12/)1 to 31 |
| [](/book/tiny-c-projects/chapter-12/)tm_mon[](/book/tiny-c-projects/chapter-12/) | [](/book/tiny-c-projects/chapter-12/)Month | [](/book/tiny-c-projects/chapter-12/)0 to 11 |
| [](/book/tiny-c-projects/chapter-12/)tm_year[](/book/tiny-c-projects/chapter-12/) | [](/book/tiny-c-projects/chapter-12/)Year | [](/book/tiny-c-projects/chapter-12/)Current year minus 1900 |
| [](/book/tiny-c-projects/chapter-12/)tm_wday[](/book/tiny-c-projects/chapter-12/) | [](/book/tiny-c-projects/chapter-12/)Day of the week | [](/book/tiny-c-projects/chapter-12/)0 to 6, Sunday to Saturday |
| [](/book/tiny-c-projects/chapter-12/)tm_yday[](/book/tiny-c-projects/chapter-12/) | [](/book/tiny-c-projects/chapter-12/)Day of the year | [](/book/tiny-c-projects/chapter-12/)0 to 365; zero is January 1 |
| [](/book/tiny-c-projects/chapter-12/)tm_isdst[](/book/tiny-c-projects/chapter-12/) | [](/book/tiny-c-projects/chapter-12/)Daylight saving time | [](/book/tiny-c-projects/chapter-12/)Positive values indicate daylight saving time; zero indicates not; negative values indicate that the data is unavailable |

[](/book/tiny-c-projects/chapter-12/)Say you want to find out the day of the week for April 12, 2022. The code shown in the next listing attempts to do so by filling in three members of the `tm` structure: `tm_mon`[](/book/tiny-c-projects/chapter-12/), `tm_day`[](/book/tiny-c-projects/chapter-12/), and `tm_year`[](/book/tiny-c-projects/chapter-12/). Adjustments are made for the `tm_mon` member[](/book/tiny-c-projects/chapter-12/)[](/book/tiny-c-projects/chapter-12/), which uses zero for January, and the `tm_year` member, which starts its count at 1900. A *printf()* statement[](/book/tiny-c-projects/chapter-12/) outputs the result in mm/dd/yyyy format, which also accesses the newly filled `tm_wday` member[](/book/tiny-c-projects/chapter-12/) to output the day of the week string.

##### Listing 12.5 Source code for getdate03.c

```
#include <stdio.h>
#include <time.h>
 
int main()
{
    struct tm day;
    const char *days[] = {
        "Sunday", "Monday", "Tuesday", "Wednesday",
        "Thursday", "Friday", "Saturday", "Sunday"
    };
 
    day.tm_mon = 4-1;                         #1
    day.tm_mday = 12;                         #2
    day.tm_year = 2022-1900;                  #3
 
    mktime(&day);                             #4
 
    printf("%02d/%02d/%04d is on a %s\n",     #5
            day.tm_mon+1,
            day.tm_mday,
            day.tm_year+1900,
            days[day.tm_wday]
          );
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-12/)Here is the program’s output:

```
09/11/0122 is on a Tuesday
```

[](/book/tiny-c-projects/chapter-12/)Alas, September 11 in the year 122 wasn’t expected, whether or not it’s a Tuesday. That is the output from my Linux machine. On the Macintosh, I saw this output:

```
08/22/5839 is on a Thursday
```

[](/book/tiny-c-projects/chapter-12/)Curiously, August 22 in the year 5839 is on a Thursday. The computer is amazing, not only to know the exact date, but that our reptilian overlords will continue to use the common calendar. Obviously, something went wrong. These types of bugs are frustrating, especially when the code cleanly compiles.

[](/book/tiny-c-projects/chapter-12/)The issue is that the `tm` structure[](/book/tiny-c-projects/chapter-12/) contains garbage that’s misinterpreted or conflicting with the three values preset. My solution is to also set the values for hour, minute, and second members, adding the following three lines to the code just below the statements where the day, month, and year are set:

```
day.tm_hour = 0;
day.tm_min = 0;
day.tm_sec = 0;
```

[](/book/tiny-c-projects/chapter-12/)This change is found in the source code file `getdate04.c`, available in the online repository. When built, here is the output:

```
04/12/2022 is on a Tuesday
```

[](/book/tiny-c-projects/chapter-12/)I used a greasy old garage calendar to confirm that, indeed, April 12, 2022, is a Tuesday.

[](/book/tiny-c-projects/chapter-12/)The lesson learned is that you can obtain details about a date if you know the month, day, and year, by filling the six `tm` structure members[](/book/tiny-c-projects/chapter-12/), as outlined here, and calling the *mktime()* function[](/book/tiny-c-projects/chapter-12/). Yet even then, you may get the [](/book/tiny-c-projects/chapter-12/)wrong date.

## [](/book/tiny-c-projects/chapter-12/)12.3 Happy holidays

[](/book/tiny-c-projects/chapter-12/)It seems like every day is a holiday, a feast day, a saint’s day, or a day of proclamation for this or that cause, celebrity, hero, or historic figure. You’ve seen the hairspray dolls on local TV cheerfully announce, “Well, today is National Hoot Like an Owl Day . . .” or some such nonsense. Such filler is possible because every day is some sort of celebration—and it’s a slow news day.

[](/book/tiny-c-projects/chapter-12/)For purposes of this chapter, a holiday must be a big deal, such as a national holiday when everyone gets the day off. My personal indication of a major holiday is when the mail doesn’t come. Excluding every Sunday, these holidays are few, typically one a month. This is the type of holiday I want my holiday detector to report, though you’re free to modify the code to list any holiday—including every Sunday.

### [](/book/tiny-c-projects/chapter-12/)12.3.1 Reviewing holidays in the United States

[](/book/tiny-c-projects/chapter-12/)The [](/book/tiny-c-projects/chapter-12/)United States have a smattering of holidays, though not every national holiday is a day off for everyone. Instead, I consider the specific holidays shown in table 12.2. For these holidays, most people have the day off, government offices are closed, banks are closed, school is out, the mail doesn’t come, and people don’t bother me as much with phone calls and email.

##### [](/book/tiny-c-projects/chapter-12/)Table 12.2 US national holidays[(view table figure)](https://drek4537l1klr.cloudfront.net/gookin/HighResolutionFigures/table_12-2.png)

| [](/book/tiny-c-projects/chapter-12/)Holiday | [](/book/tiny-c-projects/chapter-12/)Date | [](/book/tiny-c-projects/chapter-12/)Notes |
| --- | --- | --- |
| [](/book/tiny-c-projects/chapter-12/)New Year’s Day | [](/book/tiny-c-projects/chapter-12/)January 1 | [](/book/tiny-c-projects/chapter-12/)Friday/Monday holiday when this holiday occurs on a weekend. |
| [](/book/tiny-c-projects/chapter-12/)Martin Luther King Jr. Day | [](/book/tiny-c-projects/chapter-12/)Third Monday of January | [](/book/tiny-c-projects/chapter-12/) |
| [](/book/tiny-c-projects/chapter-12/)Washington’s Birthday | [](/book/tiny-c-projects/chapter-12/)Third Monday of February | [](/book/tiny-c-projects/chapter-12/)Unofficially called Presidents Day. |
| [](/book/tiny-c-projects/chapter-12/)Easter | [](/book/tiny-c-projects/chapter-12/)Sunday in March or April | [](/book/tiny-c-projects/chapter-12/)Calculation is made on the lunar calendar, so it varies. |
| [](/book/tiny-c-projects/chapter-12/)Memorial Day | [](/book/tiny-c-projects/chapter-12/)Last Monday of May | [](/book/tiny-c-projects/chapter-12/) |
| [](/book/tiny-c-projects/chapter-12/)Juneteenth | [](/book/tiny-c-projects/chapter-12/)June 19 | [](/book/tiny-c-projects/chapter-12/)Friday/Monday holiday when this holiday occurs on a weekend. |
| [](/book/tiny-c-projects/chapter-12/)Independence Day | [](/book/tiny-c-projects/chapter-12/)July 4 | [](/book/tiny-c-projects/chapter-12/)Friday/Monday holiday when this holiday occurs on a weekend. |
| [](/book/tiny-c-projects/chapter-12/)Labor Day | [](/book/tiny-c-projects/chapter-12/)First Monday of September | [](/book/tiny-c-projects/chapter-12/) |
| [](/book/tiny-c-projects/chapter-12/)Columbus Day | [](/book/tiny-c-projects/chapter-12/)Second Monday of October | [](/book/tiny-c-projects/chapter-12/)Also celebrated as Indigenous Peoples’ Day. Not every government office is closed. |
| [](/book/tiny-c-projects/chapter-12/)Veterans Day | [](/book/tiny-c-projects/chapter-12/)November 11 | [](/book/tiny-c-projects/chapter-12/)Friday/Monday holiday when this holiday occurs on a weekend. |
| [](/book/tiny-c-projects/chapter-12/)Thanksgiving | [](/book/tiny-c-projects/chapter-12/)Fourth Thursday of November | [](/book/tiny-c-projects/chapter-12/) |
| [](/book/tiny-c-projects/chapter-12/)Christmas | [](/book/tiny-c-projects/chapter-12/)December 25 | [](/book/tiny-c-projects/chapter-12/)Friday/Monday holiday when this holiday occurs on a weekend. |

[](/book/tiny-c-projects/chapter-12/)Some holidays, such as Independence Day and Christmas, are specific to a day and date, though the holiday is often observed on the Friday or Monday after it falls on a weekend. Other holidays float based on the week of the month or other factors, as noted in table 12.2.

[](/book/tiny-c-projects/chapter-12/)When calculating a holiday, you can set two dates: the holiday’s actual date and the date on which the holiday is observed. Most calendars I’ve seen show both, such as Christmas and Christmas Observed. Adding such programming is shown later in this chapter, such as when a holiday falls on a Sunday and the celebration is on [](/book/tiny-c-projects/chapter-12/)Monday.

### [](/book/tiny-c-projects/chapter-12/)12.3.2 Discovering holidays in the UK

[](/book/tiny-c-projects/chapter-12/)As [](/book/tiny-c-projects/chapter-12/)one of the rebels, I have no idea which days are celebrated as holidays in the United Kingdom—or any other country, for that matter. From Dickens, I know that Christmas is a thing in England, at least. I doubt the British celebrate George Washington’s birthday—well, perhaps not the way we do in the States. The rest of the UK holidays seem to be bank holidays, most likely celebrating the greatest banks in Britain. Even people who don’t work in a bank get the day off, supposedly.

[](/book/tiny-c-projects/chapter-12/)Table 12.3 lists UK national holidays as reported by the internet. Only three of them are tied to a specific date: New Year’s Day, Christmas, and Boxing Day. If any of these holidays falls on Saturday or Sunday, the day off is the following Monday. If Christmas or Boxing Day takes place on the weekend, it’s possible to see both Monday and Tuesday off, frequently with Tuesday as the day off for Christmas, for some reason.

##### [](/book/tiny-c-projects/chapter-12/)Table 12.3 UK national holidays[(view table figure)](https://drek4537l1klr.cloudfront.net/gookin/HighResolutionFigures/table_12-3.png)

| [](/book/tiny-c-projects/chapter-12/)Holiday | [](/book/tiny-c-projects/chapter-12/)Date |
| --- | --- |
| [](/book/tiny-c-projects/chapter-12/)New Year’s Day | [](/book/tiny-c-projects/chapter-12/)January 1 |
| [](/book/tiny-c-projects/chapter-12/)Good Friday | [](/book/tiny-c-projects/chapter-12/)Friday before Easter |
| [](/book/tiny-c-projects/chapter-12/)Easter Monday | [](/book/tiny-c-projects/chapter-12/)Monday after Easter |
| [](/book/tiny-c-projects/chapter-12/)Early May Bank Holiday | [](/book/tiny-c-projects/chapter-12/)First Monday of May |
| [](/book/tiny-c-projects/chapter-12/)Spring Bank Holiday | [](/book/tiny-c-projects/chapter-12/)Last Monday of May |
| [](/book/tiny-c-projects/chapter-12/)Summer Bank Holiday | [](/book/tiny-c-projects/chapter-12/)Last Monday of August |
| [](/book/tiny-c-projects/chapter-12/)Christmas Day | [](/book/tiny-c-projects/chapter-12/)December 25 |
| [](/book/tiny-c-projects/chapter-12/)Boxing Day | [](/book/tiny-c-projects/chapter-12/)December 26 |

[](/book/tiny-c-projects/chapter-12/)The Easter holiday floats depending on when Easter falls. You must use an algorithm to calculate these holidays: Easter and Good Friday. Such code is presented later in this chapter.

[](/book/tiny-c-projects/chapter-12/)Don’t worry, my English, Irish, Scottish, and Welsh friends: I shan’t be writing any code to detect holidays in the UK. That’s your job. Given the information presented in this chapter, the task is [](/book/tiny-c-projects/chapter-12/)quite doable.

## [](/book/tiny-c-projects/chapter-12/)12.4 Is today a holiday?

[](/book/tiny-c-projects/chapter-12/)Humans enjoy plenty of clues about impending holidays. For example, every August, shoppers at Costco are thrilled to see Christmas decorations up for sale. And who can forget early March with all the green shamrocks and cheery leprechauns reminding us of Easter? These cultural clues mean nothing to a computer—unless you, the programmer, are willing to help.

[](/book/tiny-c-projects/chapter-12/)For a computer holiday detector, three timely tidbits are necessary:

-  [](/book/tiny-c-projects/chapter-12/)The month number
-  [](/book/tiny-c-projects/chapter-12/)The day of the month
-  [](/book/tiny-c-projects/chapter-12/)The day of the week

[](/book/tiny-c-projects/chapter-12/)With these three items known, it’s possible for a computer to identify a date as a holiday.

[](/book/tiny-c-projects/chapter-12/)For the remainder of this chapter, I use holidays in the United States. The same techniques demonstrated can also be used to detect holidays in other countries, providing they follow a consistency on the solar calendar. I don’t cover how to map lunar holidays to solar holidays, except for Easter later in this chapter.

### [](/book/tiny-c-projects/chapter-12/)12.4.1 Reporting regular date holidays

[](/book/tiny-c-projects/chapter-12/)The [](/book/tiny-c-projects/chapter-12/)easiest holidays to report are the predictable ones—what I call the regular date holidays. Each of these is fixed to a specific month and day:

-  [](/book/tiny-c-projects/chapter-12/)New Year’s Day, January 1
-  [](/book/tiny-c-projects/chapter-12/)Juneteenth, June 19
-  [](/book/tiny-c-projects/chapter-12/)Independence Day, July 4
-  [](/book/tiny-c-projects/chapter-12/)Veterans Day, November 11
-  [](/book/tiny-c-projects/chapter-12/)Christmas Day, December 25

[](/book/tiny-c-projects/chapter-12/)To report these dates, I use the *isholiday()* function[](/book/tiny-c-projects/chapter-12/). Here’s the prototype:

```
int isholiday(struct tm *d)
```

[](/book/tiny-c-projects/chapter-12/)The function’s only argument is the address of a `tm` structure[](/book/tiny-c-projects/chapter-12/), the same structure returned from the *localtime()* function[](/book/tiny-c-projects/chapter-12/) and used by the *mktime()* function[](/book/tiny-c-projects/chapter-12/). Reusing this structure is convenient for this stage in the *isholiday()* function’s evolution.

[](/book/tiny-c-projects/chapter-12/)The *isholiday()* function[](/book/tiny-c-projects/chapter-12/) shown next returns an integer value: 0 for nonholiday days and 1 for a holiday. The function does a straight-up comparison of month-and-day values to report the regular date holidays, as shown in the listing. Please note that the month values used start with zero for January.

##### Listing 12.6 The *isholiday()* function

```
int isholiday(struct tm *d)
{
    if( d->tm_mon==0 && d->tm_mday==1)          #1
        return(1);
 
    if( d->tm_mon==5 && d->tm_mday==19)         #2
    return(1);
 
    if( d->tm_mon==6 && d->tm_mday==4)          #3
        return(1);
 
    if( d->tm_mon==10 && d->tm_mday==11)        #4
        return(1);
 
    if( d->tm_mon == 11 && d->tm_mday == 25)    #5
        return(1);
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-12/)The *main()* function calls the *time[](/book/tiny-c-projects/chapter-12/)()* and *localtime()* functions[](/book/tiny-c-projects/chapter-12/) to obtain the current time info and pack it into the `tm` structure[](/book/tiny-c-projects/chapter-12/). This structure is passed to *isholiday[](/book/tiny-c-projects/chapter-12/)()* and the results reported. You can find the full source code at the online repository as `isholiday01.c`. Here is a sample run:

```
Today is 12/09/2021, not a holiday
```

[](/book/tiny-c-projects/chapter-12/)For my first update to the *isholiday()* function[](/book/tiny-c-projects/chapter-12/), I’d like the function to report the holiday’s name. To make this improvement, the `tm` structure[](/book/tiny-c-projects/chapter-12/) must be ditched as the *isholiday()* function’s[](/book/tiny-c-projects/chapter-12/) argument. Instead, I use a new structure `holiday`[](/book/tiny-c-projects/chapter-12/), defined with these members:

```
struct holiday {
   int month;
   int day;
   char *name;
};
```

[](/book/tiny-c-projects/chapter-12/)The `month` and `day` members[](/book/tiny-c-projects/chapter-12/) match up to the `tm_mon`[](/book/tiny-c-projects/chapter-12/) and `tm_mday` members[](/book/tiny-c-projects/chapter-12/) of the `tm` structure[](/book/tiny-c-projects/chapter-12/). The `name` member[](/book/tiny-c-projects/chapter-12/) is a *char* pointer[](/book/tiny-c-projects/chapter-12/) to hold the holiday’s name. The strings assigned to this pointer are declared in the *isholiday()* function[](/book/tiny-c-projects/chapter-12/), as shown in the following listing. There you also see the updates to each *if* decision[](/book/tiny-c-projects/chapter-12/), which now assigns the `name` member[](/book/tiny-c-projects/chapter-12/) of the `holiday` structure[](/book/tiny-c-projects/chapter-12/) passed.

##### Listing 12.7 The *isholiday()* function updated to return the holiday name

```
int isholiday(struct holiday *h)     #1
{
    char *n[] = {                    #2
        "New Years Day",
        "Juneteenth",
        "Independence Day",
        "Veterans Day",
        "Christmas"
    };
 
    if( h->month==0 && h->day==1)
    {
        h->name = n[0];              #3
        return(1);                   #4
    }
 
    if( h->month==5 && h->day==19)   #5
    {
        h->name = n[1];
        return(1);
    }
 
    if( h->month==6 && h->day==4)
    {
        h->name = n[2];
        return(1);
    }
 
    if( h->month==10 && h->day==11)
    {
        h->name = n[3];
        return(1);
    }
 
    if( h->month== 11 && h->day == 25)
    {
        h->name = n[4];
        return(1);
    }
 
    return(0);                       #6
}
```

[](/book/tiny-c-projects/chapter-12/)The *main()* function is also updated to assign values to the `holiday` structure[](/book/tiny-c-projects/chapter-12/) declared there. The output statements are also modified to output the named holiday. For example:

```
Today is 12/25/2021, Christmas
```

[](/book/tiny-c-projects/chapter-12/)The full source code for this update is found in the online repository as `isholiday02.c`.

[](/book/tiny-c-projects/chapter-12/)The holidays detected so far are absolute. If you were creating a calendar (see chapter 13) and you wanted to color-code the holidays red, the *isholiday()* function[](/book/tiny-c-projects/chapter-12/) properly reports the values. But if you wanted to note when the holiday is observed, more coding is necessary.

[](/book/tiny-c-projects/chapter-12/)Specifically, when one of these holidays falls on a weekend, it’s often the Friday before or the Monday after that everyone takes a day off: when Independence Day (July 4) is on a Sunday, the country takes off Monday, July 5. Though when this type of holiday falls on a Tuesday, Wednesday, or Thursday, the day before or after isn’t considered a holiday, even though some people, mostly the lazy, take additional days.

[](/book/tiny-c-projects/chapter-12/)To update the code for `isholiday02.c`, and to improve the *isholiday()* function[](/book/tiny-c-projects/chapter-12/), some changes are in order. These changes account for those times when the holiday falls on a weekend.

[](/book/tiny-c-projects/chapter-12/)First comes an update to the `holiday` structure[](/book/tiny-c-projects/chapter-12/), which adds a new member, `wday`. This member echoes the `tm_wday` member[](/book/tiny-c-projects/chapter-12/) of the `tm` structure[](/book/tiny-c-projects/chapter-12/). It indicates a day of the week—0 for Sunday through 6 for Saturday. Here is the updated definition:

```
struct holiday {
   int month;
   int day;
   int wday;
   char *name;
};
```

[](/book/tiny-c-projects/chapter-12/)Because only two days are required for testing, I also added two defined constants:

```
#define FRIDAY 5
#define MONDAY 1
```

[](/book/tiny-c-projects/chapter-12/)When New Year’s Day is observed on a Friday, the date is December 31 of the prior year. This difference makes the New Year’s Day test a bit more complex than the other Friday/Monday tests. The next listing shows the code necessary to make the New Year’s Day test, which isn’t as elegant as the other holiday tests due to the year-before overlap.

##### Listing 12.8 Statements to detect New Year’s Day and any Friday/Monday celebrations

```
if( h->month==11 && h->day==31 && h->wday==FRIDAY )   #1
{
    h->name = n[0];
    return(2);                                        #2
}
if( h->month==0 && h->day==1 )                        #3
{
    h->name = n[0];
    return(1);                                        #4
}
if( h->month==0 && h->day==2 && h->wday==MONDAY )     #5
{
    h->name = n[0];
    return(2);                                        #6
}
```

[](/book/tiny-c-projects/chapter-12/)The new return code from the *isholiday()* function[](/book/tiny-c-projects/chapter-12/) is 2, as shown in listing 12.8. This value is handled uniquely in the *main()* function, which is found in the complete update source code file, `isholiday03.c`. Here is a sample run for a nonholiday:

```
Today is 12/09/2021, not a holiday
```

[](/book/tiny-c-projects/chapter-12/)And for a holiday:

```
Today is 12/25/2021, Christmas
```

[](/book/tiny-c-projects/chapter-12/)And a Monday holiday:

```
Today is 12/26/2022, Christmas observed
```

[](/book/tiny-c-projects/chapter-12/)In the code, however, I notice something that bothers me: After New Year’s Day is determined, the next four holidays all share similar statements. For example, the construction for Juneteenth is shown in the next listing. The structure of this code matches the structure used to test for the next three holidays. All that changes are the specific day values. That’s a lot of repetitious code.

##### Listing 12.9 Statements to detect Juneteenth and other holidays

```
if( h->month==5 )                              #1
{
    if( h->day>17 && h->day<21 )               #2
    {
        if( h->day==18 && h->wday==FRIDAY )    #3
        {
            h->name = n[1];
            return(2);                         #4
        }
        if( h->day==20 && h->wday==MONDAY )    #5
        {
            h->name = n[1];
            return(2);                         #6
        }
        if( h->day==19 )                       #7
        {
            h->name = n[1];
            return(1);                         #8
        }
    }
}
```

[](/book/tiny-c-projects/chapter-12/)Whenever I see such repetition in my code, it cries out for a function. The function I created is named *weekend[](/book/tiny-c-projects/chapter-12/)()*. Here is its prototype:

```
int weekend(int holiday, int mday, int wday)
```

[](/book/tiny-c-projects/chapter-12/)The function has three arguments. Integer `holiday`[](/book/tiny-c-projects/chapter-12/) is the day of the month on which the holiday occurs. Integers `mday`[](/book/tiny-c-projects/chapter-12/) and `wday`[](/book/tiny-c-projects/chapter-12/) are the day of the month and day of the week values, respectively. These three items represent the different values that change for each holiday test in the *isholiday()* function[](/book/tiny-c-projects/chapter-12/) from source code file `isholiday03.c`.

[](/book/tiny-c-projects/chapter-12/)The following listing shows the *weekend()* function[](/book/tiny-c-projects/chapter-12/). It contains most of the code shown in listing 12.9, the statements that repeat, but is modified to use variables instead of specific day-of-the-month values. This code evaluates the days before and after the holiday, Friday and Monday, to determine celebration days. The only item not addressed in the function is the string assignment for the holiday name.

##### Listing 12.10 The *weekend()* function from isholiday04.c

```
int weekend(int holiday, int mday, int wday)
{
  if( mday>holiday-2 && mday<holiday+2 )      #1
  {
    if( mday==holiday-1 && wday==FRIDAY )     #2
      return(2);
    if( mday==holiday+1 && wday==MONDAY )     #3
      return(2);
    if( mday==holiday )                       #4
      return(1);
  }
  return(0);                                  #5
}
```

[](/book/tiny-c-projects/chapter-12/)This function’s update is found in the online repository as `isholiday04.c`. The *isholiday()* function[](/book/tiny-c-projects/chapter-12/) is also updated to account for passing most of the work to the *weekend()* function[](/book/tiny-c-projects/chapter-12/). The code reads more cleanly than it did before.

[](/book/tiny-c-projects/chapter-12/)Further improvements could be made to the *isholiday()* function[](/book/tiny-c-projects/chapter-12/). But first, the irregular holidays must be dealt [](/book/tiny-c-projects/chapter-12/)with.

### [](/book/tiny-c-projects/chapter-12/)12.4.2 Dealing with irregular holidays

[](/book/tiny-c-projects/chapter-12/)Unlike [](/book/tiny-c-projects/chapter-12/)specific date holidays, irregular holidays occur on specific weeks and days of the month. The day is Monday, save for Thanksgiving, which takes place on a Thursday. These holidays are irregular in that they fall within a range of dates each year, so the program must think harder about when these holidays occur. As a review, here are the irregular holidays in the United States:

-  [](/book/tiny-c-projects/chapter-12/)Martin Luther King Jr. Day, third Monday of January
-  [](/book/tiny-c-projects/chapter-12/)Presidents Day, third Monday of February
-  [](/book/tiny-c-projects/chapter-12/)Memorial Day, last Monday of May
-  [](/book/tiny-c-projects/chapter-12/)Labor Day, first Monday of September
-  [](/book/tiny-c-projects/chapter-12/)Columbus Day, second Monday of October
-  [](/book/tiny-c-projects/chapter-12/)Thanksgiving, fourth Thursday of November

[](/book/tiny-c-projects/chapter-12/)Unlike the regular date holidays, you don’t need to worry about a shifting observance day; these are all specific day-of-the-week holidays. This consistency means that it’s possible to calculate a day-of-the-month range for each holiday. I’ve summarized the day ranges in table 12.4 for weeks in a month.

##### [](/book/tiny-c-projects/chapter-12/)Table 12.4 Day ranges for Monday holidays on a given week[(view table figure)](https://drek4537l1klr.cloudfront.net/gookin/HighResolutionFigures/table_12-4.png)

| [](/book/tiny-c-projects/chapter-12/)Week of month | [](/book/tiny-c-projects/chapter-12/)Monday range |
| --- | --- |
| [](/book/tiny-c-projects/chapter-12/)First | [](/book/tiny-c-projects/chapter-12/)1 to 7 |
| [](/book/tiny-c-projects/chapter-12/)Second | [](/book/tiny-c-projects/chapter-12/)8 to 14 |
| [](/book/tiny-c-projects/chapter-12/)Third | [](/book/tiny-c-projects/chapter-12/)15 to 21 |
| [](/book/tiny-c-projects/chapter-12/)Fourth | [](/book/tiny-c-projects/chapter-12/)22 to 28 |
| [](/book/tiny-c-projects/chapter-12/)Last | [](/book/tiny-c-projects/chapter-12/)25 and higher |

[](/book/tiny-c-projects/chapter-12/)The difference between the fourth and last week occurs in those months with five Mondays, such as May, shown in figure 12.1: when the 31st of May falls on a Monday, it’s the fifth Monday. The 24th of May is still in the fourth week (refer to table 12.3), but in this month configuration, where the 31st is on a Monday, it’s the last day. This reason is why the last week has a different range than the fourth week.

![Figure 12.1 A configuration of May, with five Mondays](https://drek4537l1klr.cloudfront.net/gookin/Figures/12-01.png)

[](/book/tiny-c-projects/chapter-12/)For Thanksgiving, the final Thursday of the month could fall on any day from the 22nd through the 28th. This value is shown in the fourth row in Table 12.3, which also applies to Thursdays.

[](/book/tiny-c-projects/chapter-12/)The *isholiday()* function[](/book/tiny-c-projects/chapter-12/) is nearly complete when these final, irregular holidays are coded. To help do so, I created a few macros and added the `THURSDAY` defined constant[](/book/tiny-c-projects/chapter-12/):

```
#define FRIDAY 5
#define MONDAY 1
#define THURSDAY 4
#define FIRST_WEEK h->day<8
#define SECOND_WEEK h->day>7&&h->day<15
#define THIRD_WEEK h->day>14&&h->day<22
#define FOURTH_WEEK h->day>21&&h->day<29
#define LAST_WEEK h->day>24&&h->day<32
```

[](/book/tiny-c-projects/chapter-12/)The weekday holidays fall on Friday, Monday, or Thursday, so the defined constants add readability to the code.

[](/book/tiny-c-projects/chapter-12/)The macros shown here relate to the date values presented in table 12.3. The variable `h->day` is used in the *isholiday()* function[](/book/tiny-c-projects/chapter-12/). These macros add readability to the function. For example, this code doesn’t use the macro:

```
if( h->day>14&&h->day<22 )
{
   h->name = n[1];
   return(1);
}
```

[](/book/tiny-c-projects/chapter-12/)But this code, which does the same thing as the previous snippet, is far more readable:

```
if( THIRD_WEEK )
{
   h->name = n[1];
   return(1);
}
```

[](/book/tiny-c-projects/chapter-12/)To avoid any confusion, the entire, updated code for the *isholiday()* function[](/book/tiny-c-projects/chapter-12/) is shown in the next listing. I recognize that it’s a bit long, but it shows all the code to capture the 12 annual holidays in the United States, save for Easter, which is covered in the next section. Aside from New Year’s Day, pay attention to the patterns used for the regular and irregular holidays. Not shown in the listing are the *weekend()* and *main()* functions.

##### Listing 12.11 The *isholiday()* function

```
int isholiday(struct holiday *h)
{
    char *n[] = {
        "New Years Day",
        "Martin Luther King Day",
        "Presidents Day",
        "Memorial Day",
        "Juneteenth",
        "Independence Day",
        "Labor Day",
        "Columbus Day",
        "Veterans Day",
        "Thanksgiving",
        "Christmas"
    };
    int r;
 
    if( h->month==11 && h->day==31 && h->wday==FRIDAY )    #1
    {
        h->name = n[0];
        return(2);
    }
    if( h->month==0 && h->day==1 )
    {
        h->name = n[0];
        return(1);
    }
    if( h->month==0 && h->day==2 && h->wday==MONDAY )
    {
        h->name = n[0];
        return(2);
    }
 
    if( h->month==0 && h->wday==MONDAY )                   #2
    {
        if( THIRD_WEEK )
        {
            h->name = n[1];
            return(1);
        }
    }
 
    if( h->month==1 && h->wday==MONDAY )                   #3
    {
        if( THIRD_WEEK )
        {
            h->name = n[2];
            return(1);
        }
    }
 
    if( h->month==4 && h->wday==MONDAY )                   #4
    {
        if( LAST_WEEK )
        {
            h->name = n[3];
            return(1);
        }
    }
 
    if( h->month==5 )                                      #5
    {
        r = weekend(19,h->day,h->wday);
        h->name = n[4];
        return(r);
    }
 
    if( h->month==6 )                                      #6
    {
        r = weekend(4,h->day,h->wday);
        h->name = n[5];
        return(r);
    }
 
    if( h->month==8 && h->wday==MONDAY )                   #7
    {
        if( FIRST_WEEK )
        {
            h->name = n[6];
            return(1);
        }
    }
    if( h->month==9 && h->wday==MONDAY)                   #8
    {
        if( SECOND_WEEK )
        {
            h->name = n[7];
            return(1);
        }
    }
 
    if( h->month==10 )                                    #9
    {
        r = weekend(11,h->day,h->wday);
        h->name = n[8];
        return(r);
    }
 
    if( h->month==10 && h->wday==THURSDAY )               #10
    {
        if( FOURTH_WEEK )
        {
            h->name = n[9];
            return(1);
        }
    }
 
    if( h->month==11 )                                    #11
    {
        r = weekend(25,h->day,h->wday);
        h->name = n[10];
        return(r);
    }
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-12/)Here is a sample run of the program for a nonholiday:

```
Today is 2/20/2022, not a holiday
```

[](/book/tiny-c-projects/chapter-12/)And for a holiday:

```
Today is 2/21/2022, Presidents Day
```

[](/book/tiny-c-projects/chapter-12/)After testing this code more thoroughly, I discovered a flaw for calculating Veterans Day and Thanksgiving, both of which occur in November. Here is the relevant code chunk:

```
if( h->month==10 )
   {
       r = weekend(11,h->day,h->wday);
       h->name = n[8];
       return(r);
   }

   if( h->month==10 && h->wday==THURSDAY )
   {
       if( FOURTH_WEEK )
       {
           h->name = n[9];
           return(1);
       }
   }
```

[](/book/tiny-c-projects/chapter-12/)The first *if* test[](/book/tiny-c-projects/chapter-12/) captures all dates for November and returns. This exit means that the next *if* test[](/book/tiny-c-projects/chapter-12/) for November, `h->month==10`, never occurs. Oops.

[](/book/tiny-c-projects/chapter-12/)To remedy the situation, a single *if* test must be done for November. Then a test can be made for Thanksgiving and then Veterans Day. Here is the udpated code:

```
if( h->month==10 )
{
   if( h->wday==THURSDAY && FOURTH_WEEK )
   {
       h->name = n[9];
       return(1);
   }
   r = weekend(11,h->day,h->wday);
   h->name = n[8];
   return(r);
}
```

[](/book/tiny-c-projects/chapter-12/)With this change made, the code now faithfully reports both Thanksgiving and Veterans Day. All these updates and additions are found in the full source code listing, `isholiday05.c`, available in the online repository.

[](/book/tiny-c-projects/chapter-12/)The only holiday left is the most difficult to calculate: Easter.

#### [](/book/tiny-c-projects/chapter-12/)Exercise 12.2

[](/book/tiny-c-projects/chapter-12/)In a major update to the code, add constants for the months of the year. Use these constants in the *isholiday()* function[](/book/tiny-c-projects/chapter-12/) so that this comparison

```
if( h->month==0 && h->wday==MONDAY )
```

[](/book/tiny-c-projects/chapter-12/)now reads like this:

```
if( h->month==JANUARY && h->wday==MONDAY )
```

[](/book/tiny-c-projects/chapter-12/)My solution is available in the online repository as `isholiday06.c`. For bonus points, see if you can use enumerated constants, which is what I [](/book/tiny-c-projects/chapter-12/)did.

### [](/book/tiny-c-projects/chapter-12/)12.4.3 Calculating Easter

[](/book/tiny-c-projects/chapter-12/)Easter [](/book/tiny-c-projects/chapter-12/)falls on different dates each year because it’s the last holiday remaining in Western culture based on the lunar calendar. On the solar calendar, the date of Easter can be as early as March 22 or as late as April 25. It’s always on a Sunday.

[](/book/tiny-c-projects/chapter-12/)For the lunar calendar, Easter is the first Sunday after the first new moon after the vernal equinox. This date is based on the Jewish holiday of Passover. So, first comes the spring equinox, when the sun returns to the northern hemisphere and Hades releases Persephone from the underworld. The next full moon—which could be weeks away—must pass, and then the following Friday is Passover with Easter falling on Sunday.

[](/book/tiny-c-projects/chapter-12/)In my original holiday-detector program, written years ago, I hardcoded the date for Easter. It was easy but not a long-lasting solution.

[](/book/tiny-c-projects/chapter-12/)As with determining the moon phase (refer to chapter 2), the date of Easter is best calculated by using an algorithm. As with the moon algorithm, I have no idea what’s going on with my Easter algorithm; I just copied it down. But unlike the moon phase algorithm, the Easter algorithm is extremely accurate.

[](/book/tiny-c-projects/chapter-12/)Just a guess: a lot of what you see in the next listing deals with mapping the moon’s cycle to the solar year, as well as accounting for leap years. What a wonder! The value passed to the easter() function[](/book/tiny-c-projects/chapter-12/) represents a year. No value is returned, because the function itself outputs the date of Easter. Building this code requires inclusion of the `math.h` header file, which implies that you link in the math library for many platforms: use the `-lm` (little L) switch[](/book/tiny-c-projects/chapter-12/), specified last when building at the command prompt.

##### Listing 12.12 The *easter()* function from source code file easter01.c

```
void easter(int year)                  #1
{
    int Y,a,c,e,h,k,L;                 #2
    double b,d,f,g,i,m,month,day;      #3
 
    Y = year;                          #4
    a = Y%19;
    b = floor(Y/100);
    c = Y%100;
    d = floor(b/4);
    e = (int)b%4;
    f = floor((b+8)/25);
    g = floor((b-f+1)/3);
    h = (19*a+(int)b-(int)d-(int)g+15)%30;
    i = floor(c/4);
    k = c%4;
    L = (32+2*e+2*(int)i-h-k)%7;
    m = floor((a+11*h+22*L)/451);
    month = floor((h+L-7*m+114)/31);   #5
    day = ((h+L-7*(int)m+114)%31)+1;   #6
 
    printf("In %d, Easter is ",Y);     #7
    if(month == 3)
        printf("March %d\n",(int)day);
    else
        printf("April %d\n",(int)day);
}
```

[](/book/tiny-c-projects/chapter-12/)The full source code file including the *easter()* function[](/book/tiny-c-projects/chapter-12/) is available in the online repository as `easter01.c`[](/book/tiny-c-projects/chapter-12/). What’s missing from listing 12.13 is the *main()* function. It contains a loop that calls the *easter()* function[](/book/tiny-c-projects/chapter-12/) with year values from 2018 through 2035:

```
In 2018, Easter is April 1
In 2019, Easter is April 21
In 2020, Easter is April 12
In 2021, Easter is April 4
In 2022, Easter is April 17
In 2023, Easter is April 9
In 2024, Easter is March 31
In 2025, Easter is April 20
In 2026, Easter is April 5
In 2027, Easter is March 28
In 2028, Easter is April 16
In 2029, Easter is April 1
In 2030, Easter is April 21
In 2031, Easter is April 13
In 2032, Easter is March 28
In 2033, Easter is April 17
In 2034, Easter is April 9
In 2035, Easter is March 25
```

[](/book/tiny-c-projects/chapter-12/)Merging the *easter[](/book/tiny-c-projects/chapter-12/)()* into the *isholiday()* function[](/book/tiny-c-projects/chapter-12/) requires too much work. Instead, I sought to include *easter[](/book/tiny-c-projects/chapter-12/)()* as a companion function called by *isholiday[](/book/tiny-c-projects/chapter-12/)()*—like the *weekend()* function[](/book/tiny-c-projects/chapter-12/) already in the code.

[](/book/tiny-c-projects/chapter-12/)The *easter()* function[](/book/tiny-c-projects/chapter-12/) must be modified to accept a date value and return 1 or 0 depending on whether the date matches Easter for the given year. To begin this journey, a few changes are required to update the existing *isholiday* code. First, the `holiday` structure[](/book/tiny-c-projects/chapter-12/) must be modified to also include a `year` member:

```
struct holiday {
 int month;
 int day;
 int year;
 int wday;
 char *name;
};
```

[](/book/tiny-c-projects/chapter-12/)Second, the `year` member’s value must be assigned in the *main()* function:

```
h.year = today->tm_yeari+1900;
```

[](/book/tiny-c-projects/chapter-12/)Remember to add 1900 to the year value!

[](/book/tiny-c-projects/chapter-12/)Third, a call must be made to *easter[](/book/tiny-c-projects/chapter-12/)()* in the *isholiday()* function[](/book/tiny-c-projects/chapter-12/). At the start of the function, a string for Easter is added to the `n[]` pointer array[](/book/tiny-c-projects/chapter-12/). I chose to add the string at the end, which doesn’t upset the existing array numbering elsewhere in the function. The `"Easter"` string is last in the array declaration, `n[11]`.

[](/book/tiny-c-projects/chapter-12/)These statements in the *isholiday()* function[](/book/tiny-c-projects/chapter-12/) call the *easter()* function[](/book/tiny-c-projects/chapter-12/). They are the last few statements in the function, right before the final return:

```
r = easter(h);
if( r==1 )
{
   h->name = n[10];
   return(r);
}
```

[](/book/tiny-c-projects/chapter-12/)The next listing shows the updated *easter()* function[](/book/tiny-c-projects/chapter-12/), changed to accommodate a holiday structure pointer as its argument and to return 1 or 0, whether the current date is or is not Easter, respectively.

##### Listing 12.13 The updated *easter()* function as it sits in source code isholiday07.c

```
int easter(struct holiday *hday)                  #1
{
    int Y,a,c,e,h,k,L;                            #2
    double b,d,f,g,i,m,month,day;
 
    Y = hday->year;
    a = Y%19;
    b = floor(Y/100);
    c = Y%100;
    d = floor(b/4);
    e = (int)b%4;
    f = floor((b+8)/25);
    g = floor((b-f+1)/3);
    h = (19*a+(int)b-(int)d-(int)g+15)%30;
    i = floor(c/4);
    k = c%4;
    L = (32+2*e+2*(int)i-h-k)%7;
    m = floor((a+11*h+22*L)/451);
    month = floor((h+L-7*m+114)/31)-1;            #3
    day = ((h+L-7*(int)m+114)%31)+1;
 
    if( hday->month==month && hday->day==day )    #4
        return(1);                                #5
    else
        return(0);                                #6
}
```

[](/book/tiny-c-projects/chapter-12/)Finally, remember to add the `math.h` header file so that the compiler doesn’t barf over the *floor()* function[](/book/tiny-c-projects/chapter-12/) used in the *easter()* function[](/book/tiny-c-projects/chapter-12/). And ensure that when you build the code, you link in the math library, `-lm` (little L). All these changes and updates are found in the source code file `isholiday07.c`, available from this book’s online repository.

[](/book/tiny-c-projects/chapter-12/)The code runs as it did before, but now it recognizes Easter. Here is a sample run for Easter [](/book/tiny-c-projects/chapter-12/)2022:

```
Today is 4/17/2022, Easter
```

### [](/book/tiny-c-projects/chapter-12/)12.4.4 Running the date gauntlet

[](/book/tiny-c-projects/chapter-12/)To [](/book/tiny-c-projects/chapter-12/)test the *isholiday()* function[](/book/tiny-c-projects/chapter-12/), you must run it through the date gauntlet. This test is how I refer to a program that generates dates from January 1 through December 31 for a given year. The goal is to ensure that the *isholiday()* function[](/book/tiny-c-projects/chapter-12/) properly reacts, reporting the national holidays.

[](/book/tiny-c-projects/chapter-12/)The next listing shows the code for `gauntlet01.c`. It contains two arrays of string constants to represent months and days of the week. The `mdays[]` array[](/book/tiny-c-projects/chapter-12/) lists the number of days in each month, where it’s assumed the year isn’t a leap year; February has only 28 days in the code. The dates are output in a nested loop: the outer loop processes months, and the inner loop churns days of the month.

##### Listing 12.14 Source code for gauntlet01.c

```
#include <stdio.h>
 
int main()
{
    const char *month[] = {
        "January", "February", "March", "April",
        "May", "June", "July", "August",
        "September", "October", "November", "December"
    };
    const char *weekday[] = {
        "Sunday", "Monday", "Tuesday", "Wednesday",
        "Thursday", "Friday", "Saturday"
    };
    int mdays[] = { 31, 28, 31, 30, 31, 30, 31, 31,      #1
        30, 31, 30, 31 };
    enum { SU, MO, TU, WE, TH, FR, SA };                 #2
    int start_day,dom,doy,year,m;
 
    start_day = SA;                                      #3
    doy = 1;                                             #4
    year = 2022;                                         #5
    for( m=0; m<12; m++ )                                #6
    {
        for( dom=1; dom<=mdays[m]; dom++ )               #7
        {
            printf("%s, %s %d, %d\n",
                    weekday[ (doy+start_day-1) % 7],     #8
                    month[m],
                    dom,
                    year
                  );
            doy++;                                       #9
        }
    }
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-12/)The math in the code determines the proper day of the week. This detail is based on the `start_day` variable[](/book/tiny-c-projects/chapter-12/) set to the proper day of the week for January 1, which is a Saturday—enumerated constant `SA` in the code. The day-of-the-year variable, `doy`[](/book/tiny-c-projects/chapter-12/), is used in this calculation, incremented in the inner loop to keep track of each day of the year.

[](/book/tiny-c-projects/chapter-12/)The source code for `gauntlet01.c` is available in the online repository. Here is the abbreviated output:

```
Saturday, January 1, 2022
Sunday, January 2, 2022
Monday, January 3, 2022
Tuesday, January 4, 2022
...
Tuesday, December 27, 2022
Wednesday, December 28, 2022
Thursday, December 29, 2022
Friday, December 30, 2022
Saturday, December 31, 2022
```

[](/book/tiny-c-projects/chapter-12/)These days all check out, matching up perfectly with the date and day of the week for the year 2022. I changed some of the variables in the code to test other years as well, and it all works.

[](/book/tiny-c-projects/chapter-12/)The next step is to add the functions *isholiday[](/book/tiny-c-projects/chapter-12/)()*, *weekend[](/book/tiny-c-projects/chapter-12/)()*, and *easter[](/book/tiny-c-projects/chapter-12/)()* to the code—the entire *isholiday* package—to[](/book/tiny-c-projects/chapter-12/) confirm that all holidays are properly tracked throughout the year. As the gauntlet code churns through days of the year, the *isholiday()* function[](/book/tiny-c-projects/chapter-12/) is called. Only holidays are output. As a review, here are the US national holidays and their days and dates for 2022:

-  [](/book/tiny-c-projects/chapter-12/)New Year’s Day: Saturday, January 1
-  [](/book/tiny-c-projects/chapter-12/)Martin Luther King Jr. Day: Monday, January 17
-  [](/book/tiny-c-projects/chapter-12/)Washington’s Birthday/Presidents Day: Monday, February 21
-  [](/book/tiny-c-projects/chapter-12/)Easter: Sunday, April 17
-  [](/book/tiny-c-projects/chapter-12/)Memorial Day: Monday, May 30
-  [](/book/tiny-c-projects/chapter-12/)Juneteenth: Sunday, June 19
-  [](/book/tiny-c-projects/chapter-12/)Juneteenth observed: Monday, June 20
-  [](/book/tiny-c-projects/chapter-12/)Independence Day: Monday, July 4
-  [](/book/tiny-c-projects/chapter-12/)Labor Day: Monday, September 5
-  [](/book/tiny-c-projects/chapter-12/)Columbus Day: Monday, October 10
-  [](/book/tiny-c-projects/chapter-12/)Veterans Day: Friday, November 11
-  [](/book/tiny-c-projects/chapter-12/)Thanksgiving: Thursday, November 24
-  [](/book/tiny-c-projects/chapter-12/)Christmas: Sunday, December 25
-  [](/book/tiny-c-projects/chapter-12/)Christmas Day observed: Monday, December 26

[](/book/tiny-c-projects/chapter-12/)The update to the code is found in the online repository as `gauntlet02.c`. It features only minor changes to the *main()* function for output formatting. Remember that this code requires linking of the math library, `-lm` (little L), so that the math functions in Easter all behave well. Here is the output:

```
Saturday, January 1, 2022 is New Years Day
Monday, January 17, 2022 is Martin Luther King Day
Monday, February 21, 2022 is Presidents Day
Sunday, April 17, 2022 is Easter
Monday, May 30, 2022 is Memorial Day
Sunday, June 19, 2022 is Juneteenth
Monday, June 20, 2022 Juneteenth is observed
Monday, July 4, 2022 is Independence Day
Monday, September 5, 2022 is Labor Day
Monday, October 10, 2022 is Columbus Day
Friday, November 11, 2022 is Veterans Day
Thursday, November 24, 2022 is Thanksgiving
Sunday, December 25, 2022 is Christmas
Monday, December 26, 2022 Christmas is observed
```

[](/book/tiny-c-projects/chapter-12/)The *isholiday()* function[](/book/tiny-c-projects/chapter-12/) can be incorporated into a variety of your source code files, or you can make it its own module to be linked in with special programs. This process is reviewed in chapter 13, which covers outputting [](/book/tiny-c-projects/chapter-12/)a colorful [](/book/tiny-c-projects/chapter-12/)calendar.
