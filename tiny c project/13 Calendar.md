# [](/book/tiny-c-projects/chapter-13/)13 Calendar

[](/book/tiny-c-projects/chapter-13/)It wasn’t [](/book/tiny-c-projects/chapter-13/)just the Mayans who invented their own calendar. Just about every early culture featured some form of classification for the passage of days. The Mayans gained notoriety in 2012 because it was the end of one of their great calendrical cycles—the long count, or *b’ak’tun*. It wasn’t the end of the world—more like turning the page on one of those cheap insurance company calendars. Bummer.

[](/book/tiny-c-projects/chapter-13/)Most cultures start with lunar calendars and eventually switch to solar calendars, either fully or reluctantly. Hebrew, Muslim, Eastern Orthodox, and Chinese calendars are still used today, with different year values and lunar features. Julius Caesar took a stab at updating the Roman calendar system—before the Senate took various stabs at him. And Pope Gregory introduced our modern calendar system in the year 1582.

[](/book/tiny-c-projects/chapter-13/)Even with calendar utilities handy, coding your own calendar tools helps hone your time programming skills in C and more. In this chapter, you learn to:

-  [](/book/tiny-c-projects/chapter-13/)Appreciate the *cal* program
-  [](/book/tiny-c-projects/chapter-13/)Calculate holidays
-  [](/book/tiny-c-projects/chapter-13/)Code week, month, and year utilities
-  [](/book/tiny-c-projects/chapter-13/)Output color text
-  [](/book/tiny-c-projects/chapter-13/)Color-code important dates

[](/book/tiny-c-projects/chapter-13/)Yes, Unix has featured the *cal* program since the steam-powered days. Still, understanding date-and-time programming is important for all C coders. By practicing on these utilities, you can better code your own, custom date programs. You can also use the techniques presented here in any program that relies upon date calculations.

## [](/book/tiny-c-projects/chapter-13/)13.1 The calendar program

[](/book/tiny-c-projects/chapter-13/)The [](/book/tiny-c-projects/chapter-13/)calendar program developed for AT&T Unix (System V) is called *cal*. Linux inherited this fine tool. The default output, with no options specified, displays the current month in this format:

```bash
$ cal
   December 2021
Su Mo Tu We Th Fr Sa
          1  2  3  4
 5  6  7  8  9 10 11
12 13 14 15 16 17 18
19 20 21 22 23 24 25
26 27 28 29 30 31
```

[](/book/tiny-c-projects/chapter-13/)The current day is shown inverse, such as the 20th above.

[](/book/tiny-c-projects/chapter-13/)You can follow *cal* with a year argument to obtain the full, 12-month calendar for the given year:

```bash
$ cal 1993
```

[](/book/tiny-c-projects/chapter-13/)You can add a month argument to see the calendar for a specific month in a specific year:

```bash
$ cal 10 1960
```

[](/book/tiny-c-projects/chapter-13/)The month can be specified numerically or by name. To see the next three months of output, specify the `-A2` argument:

```bash
$ cal -A2
```

[](/book/tiny-c-projects/chapter-13/)Like many classic Unix utilities, the *cal* program is burdened with a plethora of easily forgettable options and unmemorable switches.

[](/book/tiny-c-projects/chapter-13/)The program’s output is consistent: the first row is the full month name and full year. The next row is the weekday header. The program then outputs six rows of text for the calendar. When a month lacks a sixth week, the last row of output is blank.

[](/book/tiny-c-projects/chapter-13/)The only thing the *cal* program doesn’t do is output the calendar sideways. This job is handled by the updated version, the *ncal* program[](/book/tiny-c-projects/chapter-13/):

```bash
$ ncal
    December 2021
Su     5 12 19 26
Mo     6 13 20 27
Tu     7 14 21 28
We  1  8 15 22 29
Th  2  9 16 23 30
Fr  3 10 17 24 31
Sa  4 11 18 25
```

[](/book/tiny-c-projects/chapter-13/)The advantage of the *ncal* program[](/book/tiny-c-projects/chapter-13/) is that it outputs the entire year in a grid four months wide, which makes it easier to read on a text screen. The *cal* program uses a grid three months wide when it outputs an entire year.

[](/book/tiny-c-projects/chapter-13/)You could just use these utilities and go right along on your merry Linux adventures, but then what do you learn? Further, it’s possible to customize calendar output to however you prefer. As with any programming project, the possibilities are endless—providing that the caffeine and chips don’t run [](/book/tiny-c-projects/chapter-13/)out.

##### [](/book/tiny-c-projects/chapter-13/)Calendar trivia

-  [](/book/tiny-c-projects/chapter-13/)When Julius Caesar’s calendar was adopted in 46 BC, the year became 445 days long. This change was to align the new calendar with the solar year. It became the longest year in history.
-  [](/book/tiny-c-projects/chapter-13/)English month names are derived from the old Roman calendar: Ianuarius (January), Februarius (February), Martius (March), Aprilis (April), Maius (May), Iunius (June), Quintilis (July), Sextilis (August), September, October, November, and December.
-  [](/book/tiny-c-projects/chapter-13/)Some religious ceremonies continue to be based on Julian calendar dates—specifically, in the Eastern Orthodox Church.
-  [](/book/tiny-c-projects/chapter-13/)When Pope Gregory adopted the current, Gregorian calendar in 1582, October 4 was immediately followed by October 15.
-  [](/book/tiny-c-projects/chapter-13/)The effect of the Gregorian calendar’s adoption by Great Britain is reflected in the *cal* program’s output for September 1752. Type **cal 9 1752** to see a shortened month as the old calendar was adjusted to the new.
-  [](/book/tiny-c-projects/chapter-13/)Even with the improved Gregorian calendar, leap seconds are added to the year every so often.
-  [](/book/tiny-c-projects/chapter-13/)The number of times Friday falls on the 13th in a specific month varies from one to three times a year.
-  [](/book/tiny-c-projects/chapter-13/)During nonleap years, February and March share the same date patterns—up until March 29, of course.
-  [](/book/tiny-c-projects/chapter-13/)A sidereal year is based on the time it takes Planet Earth to make a lap around the sun. Its value is 365.256363 days.
-  [](/book/tiny-c-projects/chapter-13/)A lunar year consists of 12 moon cycles. It’s 354.37 days long.
-  [](/book/tiny-c-projects/chapter-13/)Intercalary months are added to lunar calendars every few years to resynchronize the moon cycle with the solar calendar.
-  [](/book/tiny-c-projects/chapter-13/)A galactic year is 230,000,000 (solar) years long. It’s the time it takes the sun to orbit the Milky Way galaxy—or the time it takes a toddler to find a matching pair of socks.

## [](/book/tiny-c-projects/chapter-13/)13.2 Good dates to know

[](/book/tiny-c-projects/chapter-13/)C programmers familiar with the library’s time functions know that date-and-time tidbits can easily be extracted from the current timestamp, available from the operating system: values are available for the year, month, day of the month, and day of the week. These items are all you need to construct a calendar for the current week or month. But what about next month? What about July in 1978? For these details, your code must work harder.

[](/book/tiny-c-projects/chapter-13/)Making date calculations is difficult because some months have 30 days and some have 31. Once every four years, February decides to grow another day—but even this leap day isn’t consistent. To help you properly program dates, you must code some tools.

### [](/book/tiny-c-projects/chapter-13/)13.2.1 Creating constants and enumerating dates

[](/book/tiny-c-projects/chapter-13/)More [](/book/tiny-c-projects/chapter-13/)[](/book/tiny-c-projects/chapter-13/)than most of my programming, it seems like date programming brings in a lot of constants—specifically, string and symbolic constants for weekday and month names. For my date programming, I employ both types of constants and try to do so consistently for all my date-and-time related functions.

[](/book/tiny-c-projects/chapter-13/)For weekday and month names, I use *const char* pointers—string[](/book/tiny-c-projects/chapter-13/) constants. The weekday constants are:

```
const char *weekday[] = {
   "Sunday", "Monday", "Tuesday", "Wednesday",
   "Thursday", "Friday", "Saturday"
};
```

[](/book/tiny-c-projects/chapter-13/)Shorter versions are also used:

```
const char *weekday[] = {
   "Sun", "Mon", "Tue", "Wed",
   "Thu", "Fri", "Sat"
};
```

[](/book/tiny-c-projects/chapter-13/)Here are my favorite month constants:

```
const char *month[] = {
   "January", "February", "March", "April",
   "May", "June", "July", "August",
   "September", "October", "November", "December"
};
```

[](/book/tiny-c-projects/chapter-13/)Each statement creates an array of pointers; storage for each string is allocated by the program at runtime. What remains is an array of addresses. Each array is in a sequence that matches the `tm_wday`[](/book/tiny-c-projects/chapter-13/) and `tm_mon` members[](/book/tiny-c-projects/chapter-13/) of the `tm` structure[](/book/tiny-c-projects/chapter-13/) returned from the *localtime()* function[](/book/tiny-c-projects/chapter-13/). For example, the `tm_mon` member[](/book/tiny-c-projects/chapter-13/) for January is numbered 0, and the zeroth element of the `month[]` array[](/book/tiny-c-projects/chapter-13/) is the string for January.

[](/book/tiny-c-projects/chapter-13/)The *const* classifier[](/book/tiny-c-projects/chapter-13/) declares these arrays as immutable, which prevents them from being accidentally altered elsewhere in the code. The strings can be passed to functions, but don’t change them! Doing so leads to unpredictable behavior, but not when they’re classified as constants.

[](/book/tiny-c-projects/chapter-13/)Pairing with these two arrays, I also use enumerated constants to represent the weekday and month values. The C language *enum* keyword[](/book/tiny-c-projects/chapter-13/) makes creating these constants easy.

[](/book/tiny-c-projects/chapter-13/)Don’t tell me you’ve avoided the *enum* keyword[](/book/tiny-c-projects/chapter-13/) because it’s weird. I did so for too long. Yet *enum*[](/book/tiny-c-projects/chapter-13/) helps you define constants similarly to the way an array defines groups of variables with the same data type. For weekday and month names, enum[](/book/tiny-c-projects/chapter-13/) provides a helpful tool to create these constants and make your code more readable.

[](/book/tiny-c-projects/chapter-13/)As a review, the *enum* keyword[](/book/tiny-c-projects/chapter-13/) is followed by a set of braces that contain the enumerated (numbered) constants. Values are assigned sequentially, starting with 0:

```
enum { FALSE, TRUE };
```

[](/book/tiny-c-projects/chapter-13/)Here, constant `FALSE`[](/book/tiny-c-projects/chapter-13/) is defined as 0; `TRUE,` as 1.

[](/book/tiny-c-projects/chapter-13/)You can use an assignment operator to alter the number sequencing:

```
enum { ALPHA=1, GAMMA=5, DELTA, EPSILON, THETA };
```

[](/book/tiny-c-projects/chapter-13/)This statement defines constant `ALPHA`[](/book/tiny-c-projects/chapter-13/) as 1. Constant `GAMMA`[](/book/tiny-c-projects/chapter-13/) is set equal to 5, with the rest of the constants numbered sequentially: `DELTA`[](/book/tiny-c-projects/chapter-13/) is 6, `EPSILON`[](/book/tiny-c-projects/chapter-13/) is 7, and `THETA`[](/book/tiny-c-projects/chapter-13/) is 8.

[](/book/tiny-c-projects/chapter-13/)The weekday values reported from the *localtime()* function[](/book/tiny-c-projects/chapter-13/) start with 0 for Sunday. Here is the *enum* statement to declare weekday values for use in your code:

```
enum { SUNDAY, MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY };
```

[](/book/tiny-c-projects/chapter-13/)For the 12 months, you can split the *enum* statement across multiple lines, just as you can split any statement in C:

```
enum { JANUARY, FEBRUARY, MARCH, APRIL,
   MAY, JUNE, JULY, AUGUST,
   SEPTEMBER, OCTOBER, NOVEMBER, DECEMBER };
```

[](/book/tiny-c-projects/chapter-13/)As with weekdays, the *localtime()* function[](/book/tiny-c-projects/chapter-13/) uses 0 to represent January. These enumerated constants are ready to use in your code. For example:

```
printf(“%s\n”,month[JANUARY]);
```

[](/book/tiny-c-projects/chapter-13/)Using the `month[]` array[](/book/tiny-c-projects/chapter-13/) defined earlier in this section, along with enumerated constant `JANUARY`[](/book/tiny-c-projects/chapter-13/), the previous statement outputs the text `January`. This construction is self-documenting and easier to read than using `month[0]` or something equally vague without reference to what 0 could [](/book/tiny-c-projects/chapter-13/)[](/book/tiny-c-projects/chapter-13/)mean.

### [](/book/tiny-c-projects/chapter-13/)13.2.2 Finding the day of the week

[](/book/tiny-c-projects/chapter-13/)After [](/book/tiny-c-projects/chapter-13/)arriving at the destination, the first thing a time traveler asks is, “What year is it?” This question provides a big-picture answer, but it also helps the production design team understand how to visually misinterpret various eras in history. And it allows the locals to predictably respond, “What are you talking about, stranger in the silver pajamas?”

[](/book/tiny-c-projects/chapter-13/)For calendar programming, yes, knowing the current year is important. Also necessary to plotting out a calendar is knowing month, day, and—vitally—the weekday. The day-and-weekday info are key to unlocking the first day of the month. The other time tidbits are easily obtained from the data reported by the *time[](/book/tiny-c-projects/chapter-13/)()* and *localtime()* functions[](/book/tiny-c-projects/chapter-13/).

[](/book/tiny-c-projects/chapter-13/)In the next listing, the *time()* function[](/book/tiny-c-projects/chapter-13/) obtains the current epoch value, a *time_t* data type[](/book/tiny-c-projects/chapter-13/). The *localtime()* function[](/book/tiny-c-projects/chapter-13/) uses this value to fill a `tm` structure, `date`[](/book/tiny-c-projects/chapter-13/). The month, month day, year, and weekday values are then interpreted and output, displaying the current day and date.

##### Listing 13.1 Source code for weekday01.c

```
#include <stdio.h>
#include <time.h>
 
int main()
{
    const char *weekday[] = {                         #1
        "Sunday", "Monday", "Tuesday", "Wednesday",
        "Thursday", "Friday", "Saturday"
    };
    const char *month[] = {                           #2
        "January", "February", "March", "April",
        "May", "June", "July", "August",
        "September", "October", "November", "December"
    };
    time_t now;                                       #3
    struct tm *date;                                  #4
 
    time(&now);                                       #5
    date = localtime(&now);                           #6
 
    printf("Today is %s %d, %d, a %s\n",              #7
            month[ date->tm_mon ],
            date->tm_mday,
            date->tm_year+1900,
            weekday[ date->tm_wday ]
          );
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-13/)The string constants declared in `weekday01.c` are used throughout this chapter. Remember to define them as *const char* variables; you don’t want to mess with the string’s contents, lest all sorts of mayhem ensue.

[](/book/tiny-c-projects/chapter-13/)The program built from the code in listing 13.1 outputs a simple string, reflecting the current date and weekday:

```
Today is May 1, 2022, a Sunday
```

[](/book/tiny-c-projects/chapter-13/)You can use the date info generated in the program to plot out a calendar—for the current month. To figure out how the following July maps out on a calendar, you must apply some math. To help you, and avoid all that boring trial-and-error, you can steal an algorithm from the internet.

[](/book/tiny-c-projects/chapter-13/)Before computers on desktops were a thing, I remember one of my elementary school teachers demonstrating an algorithm to find the weekday for any day, month, and year. It’s simple enough that you can perform the math in your head without exploding. I forget what my teacher wrote on the chalkboard, but here’s the algorithm, freshly stolen from the internet:

```
int t[] = { 0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4 };
year -= month<3;
r = ( year + year/4 - year/100 + year/400 + t[month-1] + day) % 7
```

[](/book/tiny-c-projects/chapter-13/)Array `t[]` holds the algorithm’s magic. I’m unsure what the data references, though my guess is that it’s probably some sort of month pattern index. The `year` value is reduced by 1 for the months of January and February. Then variable `r` captures the day of the week, with Sunday being 0. I assume most of the year manipulation in the expression is to compensate for leap years. Further, this algorithm assumes that the value of January is 1, not 0. These differences can be adjusted as shown in the *dayoftheweek()* function[](/book/tiny-c-projects/chapter-13/) in the following listing.

##### Listing 13.2 The *dayoftheweek()* function

```
int dayoftheweek(int m,int d,int y)                   #1
{
    int t[] = {                                       #2
        0, 3, 2, 5, 0, 3,
        5, 1, 4, 6, 2, 4
    };
    int r;
 
    y -= m<2;                                         #3
    r = ( y + y/4 - y/100 + y/400 + t[m] + d) % 7;    #4
    return(r);
}
```

[](/book/tiny-c-projects/chapter-13/)I updated the *main()* function from `weekday01.c` to call the *dayoftheweek()* function[](/book/tiny-c-projects/chapter-13/). Specific values are set for month, day, and year variables, which are passed to the function. The result is then output. These modifications are found in the online repository as source code file `weekday02.c`. Here is some sample output:

```
February 3, 1993 is a Wednesday
```

[](/book/tiny-c-projects/chapter-13/)The capability to obtain these four date details—year, month, day, and day of the week—is key to creating a calendar. The next step is to calculate the first day of the month, with the rest of the days flowing after.

#### [](/book/tiny-c-projects/chapter-13/)Exercise 13.1

[](/book/tiny-c-projects/chapter-13/)If you’re like me, you probably played with the source code from `weekday02.c`, typing in your birthday or some other important date out of curiosity. But why keep updating the source code?

[](/book/tiny-c-projects/chapter-13/)Your task for this exercise is to modify the source code from `weekday02.c` so that command-line arguments are interpreted as the month, day, and year for which you want to find the day of the week. And if your locale doesn’t like the argument order—you can change it! Here is a sample run of my solution, which I call *weekday*:

```bash
$ weekday 10 19 1987
October 19, 1987 is a Monday
```

[](/book/tiny-c-projects/chapter-13/)My solution is available in the online repository as [](/book/tiny-c-projects/chapter-13/)`weekday03.c`.

### [](/book/tiny-c-projects/chapter-13/)13.2.3 Calculating the first day of the month

[](/book/tiny-c-projects/chapter-13/)Today [](/book/tiny-c-projects/chapter-13/)is the 20th day of the month—any month. It’s a Monday. On which day of the week did the first day of the month fall?

[](/book/tiny-c-projects/chapter-13/)Uh . . .

[](/book/tiny-c-projects/chapter-13/)Quick! Use the handy illustration in figure 13.1 to help your calculations. If today is Monday the 20th, the first of the month is on a Wednesday, always, for any month where Monday is the 20th.

![Figure 13.1 A month where the 20th is a Monday](https://drek4537l1klr.cloudfront.net/gookin/Figures/13-01.png)

[](/book/tiny-c-projects/chapter-13/)When given a day of the month and its weekday, the computer can easily calculate upon which day the first of the month falls. Here is the formula I devised to determine the weekday for the first of the month when given the current weekday and day of the month:

```
first = weekday - ( day % 7 ) + 1;
```

[](/book/tiny-c-projects/chapter-13/)To work through the formula with figure 13.1, assume that today is the 23rd—which it is as I write this text. It’s a Thursday, numeric value 4:

```
first = 4 - ( 23 % 7 ) + 1
first = 4 - ( 2 ) + 1
first = 3
```

[](/book/tiny-c-projects/chapter-13/)When a month has the 23rd fall on a Thursday, the first is on a Wednesday (value 3). Refer to figure 13.1 to confirm.

[](/book/tiny-c-projects/chapter-13/)To put my first-of-the-month algorithm to the test, the next listing shows code that obtains the current date. It uses the weekday and day of the month values to work the algorithm, outputting on which weekday the first of the month falls.

##### Listing 13.3 Source code for thefirst01.c

```
#include <stdio.h>
#include <time.h>
 
int main()
{
    const char *weekday[] = {
        "Sunday", "Monday", "Tuesday", "Wednesday",
        "Thursday", "Friday", "Saturday"
    };
    time_t now;
    struct tm *date;
    int first;
 
    time(&now);                                           #1
    date = localtime(&now);                               #2
 
    first = date->tm_wday - ( date->tm_mday % 7 ) + 1;    #3
 
    printf("The first of this month was on a %s\n",       #4
            weekday[first]
          );
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-13/)The source code for `thefirst01.c` is available in the online repository, but don’t get excited about it. If the current weekday value is greater than the weekday value for the first of the month, the program works, as it did on my computer:

```
The first of this month was on a Wednesday
```

[](/book/tiny-c-projects/chapter-13/)If the current weekday value is less than the weekday value of the first of the month, the code fails. For example, if today is Tuesday (2) and the first is on Friday (5), you see something like this delightful output:

```
Segmentation fault (core dumped)
```

[](/book/tiny-c-projects/chapter-13/)The reason for the core dump is that the value stored in `first` drops below 0. This error can be corrected by testing for a negative value of `first`:

```
first = WEDNESDAY - ( 12 % 7 ) + 1;
if( first < 0 )
   first += 7;
```

[](/book/tiny-c-projects/chapter-13/)In this update to the code, I use enumerated constant `WEDNESDAY`[](/book/tiny-c-projects/chapter-13/) as the weekday and 12 as the day of the month. The first of the month is on a Saturday. Here is the code’s output:

```
The first of this month was on a Saturday
```

[](/book/tiny-c-projects/chapter-13/)Finding the weekday for the first of the month may seem silly. After all, from the preceding section you find code that locates the day of the week for any day of the month. The issue is that you’re often not given the first of the month. Sure, you could write more code that calls the *dayoftheweek()* function[](/book/tiny-c-projects/chapter-13/) after modifying the current day of the month. But I find that using the algorithm works best for me.

#### [](/book/tiny-c-projects/chapter-13/)Exercise 13.2

[](/book/tiny-c-projects/chapter-13/)It’s time to write another function! From the source code file `thefirst02.c`, pull out the algorithm portion of the *main()* function and set it into its own function, *thefirst[](/book/tiny-c-projects/chapter-13/)()*. This function is prototyped like this:

```
int thefirst(int wday, int mday)
```

[](/book/tiny-c-projects/chapter-13/)Variable `wday`[](/book/tiny-c-projects/chapter-13/) is the day of the week, `mday` is the day of the month. The value returned is the weekday for the first of the month, range 0 through 6.

[](/book/tiny-c-projects/chapter-13/)My solution is available in the online repository as `thefirst03.c`. I wrote code in the *main()* function to report the first of the month when the current day is the 25th, a Saturday. Comments in the code explain my [](/book/tiny-c-projects/chapter-13/)approach.

### [](/book/tiny-c-projects/chapter-13/)13.2.4 Identifying leap years

[](/book/tiny-c-projects/chapter-13/)You [](/book/tiny-c-projects/chapter-13/)[](/book/tiny-c-projects/chapter-13/)can’t discuss date programming without bringing up the squidgy issue of leap years. The varying number of days in February is yet another example of the universe trying to tell us that nothing would exist if everything were in perfect balance.

[](/book/tiny-c-projects/chapter-13/)When I work with days in the month, I typically write an array like this:

```
int mdays[] = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };
```

[](/book/tiny-c-projects/chapter-13/)This array holds the number of days for January through December. For February, the value is 28. But one out of every four years (on average), February has 29 days—the extra leap day in a leap year.

[](/book/tiny-c-projects/chapter-13/)To determine which years are leap years, and adjust the `mdays[]`, you must do some math. Here are the leap year rules in order of elimination:

-  [](/book/tiny-c-projects/chapter-13/)If the year is divisible by both 100 and 400, it’s a leap year.
-  [](/book/tiny-c-projects/chapter-13/)If the year is divisible only by 100, it’s not a leap year.
-  [](/book/tiny-c-projects/chapter-13/)If the year is divisible by four, it’s a leap year.

[](/book/tiny-c-projects/chapter-13/)Normally, the leap year rules are listed in reverse order: If the year is divisible by four, it’s a leap year, unless the year is divisible by 100, in which case it’s not a leap year, unless the year is also divisible by 400, in which case it is a leap year.

[](/book/tiny-c-projects/chapter-13/)Got it?

[](/book/tiny-c-projects/chapter-13/)No, it’s easier to list the rules upside down, which also helps to write a leap year function, *february[](/book/tiny-c-projects/chapter-13/)()*, shown next. Its purpose is to return the number of days in February, a value then set into an array like `mdays[]` (shown earlier). The rules for calculating a leap year appear in the function as a series of *if* tests[](/book/tiny-c-projects/chapter-13/) based on the `year` value passed.

##### Listing 13.4 The *february()* function

```
int february(int year)
{
    if( year%400==0 )     #1
        return(29);
 
    if( year%100==0 )     #2
        return(28);
 
    if( year%4!=0 )       #3
        return(28);
 
    return(29);           #4
}
```

[](/book/tiny-c-projects/chapter-13/)I use the *february()* function[](/book/tiny-c-projects/chapter-13/) in the source code file `leapyear01.c`, available in the online repository. In the *main()* function, a loop tests the years 1584 through 2101, which span the time from when the Gregorian calendar began to when the lizard people finally invade. If the year is a leap year, meaning the *february()* function[](/book/tiny-c-projects/chapter-13/) returns 29, its value is output. Here is the tail end of a sample run:

```
...
1996
2000
2004
2008
2012
2016
2020
2024
2028
2032
```

[](/book/tiny-c-projects/chapter-13/)The code accurately identifies the year 2000 as a leap year.

[](/book/tiny-c-projects/chapter-13/)The *february()* function[](/book/tiny-c-projects/chapter-13/) is used in programs demonstrated later in this chapter to update the `mdays[]` array[](/book/tiny-c-projects/chapter-13/) to reflect the proper number of days in February for a given [](/book/tiny-c-projects/chapter-13/)[](/book/tiny-c-projects/chapter-13/)year.

### [](/book/tiny-c-projects/chapter-13/)13.2.5 Getting the time zone correct

[](/book/tiny-c-projects/chapter-13/)One [](/book/tiny-c-projects/chapter-13/)[](/book/tiny-c-projects/chapter-13/)weirdo issue to consider when dealing with dates is the computer’s time zone. This value is set according to the system’s locale. It reflects the local time of day, which is what’s accessed when you program dates and time in C.

[](/book/tiny-c-projects/chapter-13/)Normally, the time zone detail is ignored; what you want to obtain from the *time()* function[](/book/tiny-c-projects/chapter-13/) is the current date and time for the computer or other device’s location. However, if your code doesn’t account for the difference between GMT, or Greenwich Mean Time, and your local time zone, the time calculation you make could be inaccurate.

[](/book/tiny-c-projects/chapter-13/)For example, my time zone is US Pacific. If I’m not careful, the eight-hour time difference gives me results that are off by eight hours. Believe it or not, this level of chronological accuracy is necessary for a program to spit out an accurate calendar.

[](/book/tiny-c-projects/chapter-13/)To drive home this concern, consider the source code in the next listing. It initializes a time_t value to 0, which is the dawn of the Unix epoch, or midnight January 1, 1970. This value is output in a *printf()* statement[](/book/tiny-c-projects/chapter-13/), which uses the *ctime()* function[](/book/tiny-c-projects/chapter-13/) to convert a *time_t* value into a human-readable string.

##### Listing 13.5 Source code for timezone01.c

```
#include <stdio.h>
#include <time.h>
 
int main()
{
    time_t epoch = 0;                         #1
 
    printf("Time is %s\n",ctime(&epoch) );    #2
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-13/)When the program is run, I see this text on my computer:

```
Time is Wed Dec 31 16:00:00 1969
```

[](/book/tiny-c-projects/chapter-13/)The output shows eight hours before the epoch began (midnight, January 1) because my computer’s time zone is set to GMT-8 (Greenwich Mean Time minus eight hours), or Pacific Standard Time. The output is accurate: when it was midnight on January 1 in the UK, it was 4:00 P.M. the day before here on the West Coast of the United States.

[](/book/tiny-c-projects/chapter-13/)In Linux, you can check the computer’s time zone information by examining the `/etc/localtime` symbolic link. Use the **ls -l** (dash-L) command[](/book/tiny-c-projects/chapter-13/):

```
ls -l /etc/localtime
```

[](/book/tiny-c-projects/chapter-13/)Here is the relevant part of the output I see on my system:

```
/etc/localtime -> /usr/share/zoneinfo/America/Los_Angeles
```

[](/book/tiny-c-projects/chapter-13/)My time zone is set the same as in Los Angeles, though the people are much nicer where I live. The output you see is local to your system, a value set when Linux was first configured.

[](/book/tiny-c-projects/chapter-13/)Your code need not look up the `/etc/localtime` symbolic link to determine the computer’s time zone or attempt to change this setting. Instead, you can write code to temporarily set the `TZ` (time zone) environment variable[](/book/tiny-c-projects/chapter-13/)[](/book/tiny-c-projects/chapter-13/) to GMT. To make this update to the source code for `timezone01.c,` you must add two functions: *putenv[](/book/tiny-c-projects/chapter-13/)()* and *tzset[](/book/tiny-c-projects/chapter-13/)()*.

[](/book/tiny-c-projects/chapter-13/)The *putenv[](/book/tiny-c-projects/chapter-13/)()* adds an environment variable to the program’s local environment; the change doesn’t affect the shell, so it’s not something you must undo later in the code. The *man* page format[](/book/tiny-c-projects/chapter-13/) is

```
int putenv(char *string);
```

[](/book/tiny-c-projects/chapter-13/)The `string` is the environment entry to add. In this case, it’s `TZ=GMT` for “time zone equals Greenwich Mean Time” exactly, the time zone you want. This function requires the inclusion of the `stdlib.h` library[](/book/tiny-c-projects/chapter-13/).

[](/book/tiny-c-projects/chapter-13/)The *tzset()* function[](/book/tiny-c-projects/chapter-13/) sets the program’s time zone—but only while it runs. The function doesn’t otherwise alter the system. Here is the *man* page format[](/book/tiny-c-projects/chapter-13/):

```
void tzset(void);
```

[](/book/tiny-c-projects/chapter-13/)The *tzset()* function[](/book/tiny-c-projects/chapter-13/) requires no arguments because it uses the `TZ` environment variable[](/book/tiny-c-projects/chapter-13/)[](/book/tiny-c-projects/chapter-13/) to set the program’s time zone. The `time.h` header file must be included for this function to behave properly.

[](/book/tiny-c-projects/chapter-13/)To update the code for `timezone01.c`, add the following two statements before the *printf()* statement[](/book/tiny-c-projects/chapter-13/):

```
putenv("TZ=GMT");
tzset();
```

[](/book/tiny-c-projects/chapter-13/)And don’t forget to include the `stdlib.h` header file for the *putenv()* function[](/book/tiny-c-projects/chapter-13/). These changes are found in the online repository in the source code file `timezone02.c`. Here is the program’s output:

```
Time is Thu Jan  1 00:00:00 1970
```

[](/book/tiny-c-projects/chapter-13/)The output now reflects the true Unix epoch as the program’s time zone is changed to GMT internally.

[](/book/tiny-c-projects/chapter-13/)This code is used later in this chapter, when the full year calendar is generated. Without making the adjustment, the calendar outputs the incorrect year, before or after the desired year based on your local time zone. The time zone adjustment ensures that the calendar is properly aligned. You can also use this trick in other programs that rely upon precise [](/book/tiny-c-projects/chapter-13/)[](/book/tiny-c-projects/chapter-13/)time-and-date calculations.

## [](/book/tiny-c-projects/chapter-13/)13.3 Calendar utilities

[](/book/tiny-c-projects/chapter-13/)The Linux *cal* program does more than you can imagine. It’s impressive. Given its abundance of options and switches, *cal* can output dates in a given range for a given locale in a specific format. As with other Linux command-line programs I’ve aped, the goal for my calendar programs is to be specific, as opposed to writing one program that does everything.

[](/book/tiny-c-projects/chapter-13/)I first coded my calendar programs because I wanted to see output for the current month in a wider format than what the *cal* program generates. Also, I just wanted to see whether I could code a calendar for any given month. The result is my *month* program[](/book/tiny-c-projects/chapter-13/), which I use far more often than *cal*.

[](/book/tiny-c-projects/chapter-13/)One decision to make right away with any calendar utility is whether the week starts on Monday or Sunday. The *cal* program (as you may suspect) has options to set the week’s starting day. For my series of calendar programs in this chapter, it’s assumed that the week starts on Sunday.

### [](/book/tiny-c-projects/chapter-13/)13.3.1 Generating a week

[](/book/tiny-c-projects/chapter-13/)I [](/book/tiny-c-projects/chapter-13/)suppose the simplest calendar would output only the current day—something like this:

```
September 2022
Friday
23
```

[](/book/tiny-c-projects/chapter-13/)Most people want more from a calendar. But rather than start with the current month, my first calendar program shows the current week. This code hinges upon knowing the current day of the month and weekday. Here is the output I want to see for the final program:

```
December / January - Week 52
Sun Mon Tue Wed Thu Fri Sat
[26] 27  28  29  30  31   1
```

[](/book/tiny-c-projects/chapter-13/)The current day is December 26. The month (and year) ends on Friday, with Saturday being the first of January and the new year. It’s the 52nd week of the year.

[](/book/tiny-c-projects/chapter-13/)Before coding all that output, I want to start small and output only the current week. A loop outputs the days, Sunday through Saturday. No matter which weekday it is currently, the output starts on Sunday. Today’s day is highlighted in brackets.

[](/book/tiny-c-projects/chapter-13/)The *localtime()* function[](/book/tiny-c-projects/chapter-13/) reports details about the current day of the week. The formula I use to determine Sunday’s date is:

```
sunday = day_of_the_month - weekday;
```

[](/book/tiny-c-projects/chapter-13/)The `day_of_the_month` value is found in the `tm` structure[](/book/tiny-c-projects/chapter-13/), member `tm_mday`[](/book/tiny-c-projects/chapter-13/). Today’s `weekday` value is member `tm_wday`[](/book/tiny-c-projects/chapter-13/). As an example, if today is Thursday the 16th, the formula reads:

```
sunday = 16 - 4;
```

[](/book/tiny-c-projects/chapter-13/)The date for Sunday is the 12th, which checks out on the monthly calendar shown in figure 13.1, earlier in this chapter. The `sunday` value is then used in a loop to output the seven days of the week:

```
for( d=sunday; d<sunday+7; d++ )
```

[](/book/tiny-c-projects/chapter-13/)I output the consecutive days in a space four characters wide. This room allows for today’s date to be output embraced by square brackets.

[](/book/tiny-c-projects/chapter-13/)The full code for my `week01.c` program[](/book/tiny-c-projects/chapter-13/) is shown in the next listing. It reads data from the *time[](/book/tiny-c-projects/chapter-13/)()* and *localtime[](/book/tiny-c-projects/chapter-13/)()* functions, outputs the current month (but not the year), and outputs dates for the current week. I use variables `day`[](/book/tiny-c-projects/chapter-13/), `month`[](/book/tiny-c-projects/chapter-13/), and `weekday`[](/book/tiny-c-projects/chapter-13/) as readable shortcuts for their related members of the `tm` structure[](/book/tiny-c-projects/chapter-13/).

##### Listing 13.6 Source code for week01.c

```
#include <stdio.h>
#include <time.h>
 
int main()
{
    const char *months[] = {
        "January", "February", "March", "April",
        "May", "June", "July", "August",
        "September", "October", "November", "December"
    };
    time_t now;
    struct tm *date;
    int day,weekday,month,sunday,d;
 
    time(&now);                                 #1
    date = localtime(&now);                     #2
 
    day = date->tm_mday;                        #3
    month = date->tm_mon;
    weekday = date->tm_wday;
    sunday = day - weekday;                     #4
 
    printf("  %s\n",months[month]);             #5
    printf("Sun Mon Tue Wed Thu Fri Sat\n");    #6
    for( d=sunday; d<sunday+7; d++ )            #7
    {
        if( d==day )                            #8
            printf("[%2d]",d);
        else
            printf(" %2d ",d);                  #9
    }
    putchar('\n');
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-13/)The source code from listing 13.6 is available in the online repository as `week01.c`. Its core consists of three lines of output, with the third line generated by a loop. The loop outputs days of the week, starting at Sunday. The current day is highlighted, as shown in the sample output:

```
September
Sun Mon Tue Wed Thu Fri Sat
12  13  14  15 [16] 17  18
```

[](/book/tiny-c-projects/chapter-13/)Of course, this code isn’t perfect. If the first of the month falls on any day other than Sunday, you see output like this:

```
September
Sun Mon Tue Wed Thu Fri Sat
-3  -2  -1   0   1 [ 2]  3
```

[](/book/tiny-c-projects/chapter-13/)Likewise, at the end of the month, you can see output like this:

```
September
Sun Mon Tue Wed Thu Fri Sat
26  27 [28] 29  30  31  32
```

[](/book/tiny-c-projects/chapter-13/)For my first update to the code, I added another decision in the output: In the *for* loop, if the value of variable `d` is less than one, spaces are output instead of the day value. Likewise, spaces are output when the day value is greater than the number of days in the current month.

[](/book/tiny-c-projects/chapter-13/)Determining the last day of the month requires more code. Specifically, you must add the `mdays[]` array[](/book/tiny-c-projects/chapter-13/) that lists days of each month, and also the *february()* function[](/book/tiny-c-projects/chapter-13/), covered earlier in this chapter. This function is necessary to ensure that the proper number of days in February is known for the current year.

[](/book/tiny-c-projects/chapter-13/)The `mdays[]` array[](/book/tiny-c-projects/chapter-13/) is added to the code in the variable declaration part of the *main()* function:

```
int mdays[] = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };
```

[](/book/tiny-c-projects/chapter-13/)The *february()* function[](/book/tiny-c-projects/chapter-13/) is also added to the source code. After the *localtime()* function[](/book/tiny-c-projects/chapter-13/) is called, the *february()* function[](/book/tiny-c-projects/chapter-13/) is called to update the `mdays[]` array[](/book/tiny-c-projects/chapter-13/), element one:

```
mdays[1] = february(date->tm_year+1900);
```

[](/book/tiny-c-projects/chapter-13/)The following code shows the updated *for* loop in the *main()* function. The first *if* decision[](/book/tiny-c-projects/chapter-13/) outputs spaces for out-of-range dates. The *else* portion consists of the original *if-else* decision from the first version of the code.

##### Listing 13.7 The updated *for* loop found in week02.c

```
for( d=sunday; d<sunday+7; d++ )
{
    if( d<1 || d>mdays[month] )    #1
        printf("    ");
    else
    {
        if( d==day )               #2
            printf("[%2d]",d);
        else
            printf(" %2d ",d);     #3
    }
}
```

[](/book/tiny-c-projects/chapter-13/)This update to the source code is found in the online repository as `week02.c`. It accurately addresses the date overflow issues, as shown in this sample output:

```
September
Sun Mon Tue Wed Thu Fri Sat
                 1 [ 2]  3
```

[](/book/tiny-c-projects/chapter-13/)At the end of the month, the output now looks like this:

```
September
Sun Mon Tue Wed Thu Fri Sat
26  27 [28] 29  30
```

[](/book/tiny-c-projects/chapter-13/)Delightfully awkward output happens when today is the first and it’s a Saturday:

```
January
Sun Mon Tue Wed Thu Fri Sat
                       [ 1]
```

[](/book/tiny-c-projects/chapter-13/)I don’t want this program to show multiple weeks, which would eventually devolve it into a month program. No, what would be keen is to output those final days from the preceding month, like this:

```
December / January
Sun Mon Tue Wed Thu Fri Sat
26  27  28  29  30  31  [ 1]
```

[](/book/tiny-c-projects/chapter-13/)Both months are listed in the header because dates from both months appear in the output. The current date is highlighted so that an astute user (that’s you) can tell that the week is the last one of the previous year, but today’s date is New Year’s Day.

[](/book/tiny-c-projects/chapter-13/)This update to the code from `week02.c` requires the addition of a new variable, `pmonth`[](/book/tiny-c-projects/chapter-13/), which holds the value of the previous month. The `pmonth` calculation takes place after the current month’s value is read and stored in variable `month`[](/book/tiny-c-projects/chapter-13/):

```
pmonth = month-1;
if( pmonth<0 )
   pmonth=11;
```

[](/book/tiny-c-projects/chapter-13/)The previous month’s value is the current month’s value minus one. If it’s January (0), the previous month’s value is negative. The *if* test[](/book/tiny-c-projects/chapter-13/) catches this condition, in which case the value of `pmonth` is set to 11, December.

[](/book/tiny-c-projects/chapter-13/)Next, a series of tests are performed to determine which month names to output: a single month, the current and previous months, or the current and next months. These tests are illustrated here.

##### Listing 13.8 Tests to determine which months to output (from week03.c)

```
if( sunday<1 )                                                  #1
    printf("  %s / %s\n",months[pmonth],months[month]);
else if( sunday+6 > mdays[month] )                              #2
{
    if( month==11 )                                             #3
        printf("  %s / %s\n",months[month],months[0]);
    else
        printf("  %s / %s\n",months[month],months[month+1]);    #4
}
else
    printf("  %s\n",months[month]);                             #5
```

[](/book/tiny-c-projects/chapter-13/)To output dates from the previous or next month, the *for* loop in the *main()* function must be modified. Again, an *if else-if else* structure[](/book/tiny-c-projects/chapter-13/) is used, shown in the next listing. Calculations are made to generate the trailing dates from the previous month and the following dates from the next month.

##### Listing 13.9 The updated *for* loop (from week03.c)

```
for( d=sunday; d<sunday+7; d++ )
{
    if( d<1 )                               #1
        printf(" %2d ",mdays[pmonth]+d);    #2
    else if( d>mdays[month] )               #3
        printf(" %2d ",d-mdays[month]);     #4
    else                                    #5
    {
        if( d==day )
            printf("[%2d]",d);
        else
            printf(" %2d ",d);
    }
}
```

[](/book/tiny-c-projects/chapter-13/)These decisions look messy, but they’re required to fill in the proper dates for overlapping months. The full source code is available from the online repository as `week03.c`. Here’s a sample run:

```
December / January
Sun Mon Tue Wed Thu Fri Sat
[26] 27  28  29  30  31   1
```

[](/book/tiny-c-projects/chapter-13/)Above, the next month and first day of the month are output for the current week, when today is December 26. Similar output is shown when days from the previous month appear in the week:

```
November / December
Sun Mon Tue Wed Thu Fri Sat
28  29 [30]  1   2   3   4
```

[](/book/tiny-c-projects/chapter-13/)And:

```
November / December
Sun Mon Tue Wed Thu Fri Sat
28  29  30   1   2 [ 3]  4
```

[](/book/tiny-c-projects/chapter-13/)The program is pretty much complete at this point. Being a nerd, however, I always look for ways to improve upon the code. The only thing I can think to add is to output the current week number as well.

[](/book/tiny-c-projects/chapter-13/)Each year has 52 weeks, though they don’t fall in a regular pattern. After all, the first week of the year may have a few lingering days from December. From what I gather, when January 1 falls on a Wednesday or earlier in the week, it’s in the first week of the year. Otherwise, January 1 is part of week 52 from the previous year.

[](/book/tiny-c-projects/chapter-13/)An exception occurs during leap years when January 1 falls on a Thursday. Though it could be week 52 of the preceding year, a leap year can have 53 weeks. The next time a year has 53 weeks is in 2032—so hang on to this book!

[](/book/tiny-c-projects/chapter-13/)My first attempt to calculate the current week number resulted in this formula:

```
weekno = (9 + day_of_the_year - weekday) / 7;
```

[](/book/tiny-c-projects/chapter-13/)The `day_of_the_year` value is kept in the `tm` structure[](/book/tiny-c-projects/chapter-13/) as member `tm_yday`[](/book/tiny-c-projects/chapter-13/). The weekday value is `tm` structure member `tm_wday`[](/book/tiny-c-projects/chapter-13/), where Sunday is zero. The expression is divided by seven, which is rounded as an integer value and stored in variable `weekno`[](/book/tiny-c-projects/chapter-13/).

[](/book/tiny-c-projects/chapter-13/)The value of `weekno` must be tested for the first week of the year—specifically, when the first of January falls late in the week. In this configuration, the `weekno` value returned by the equation is 0. It should be 52, as it’s technically the last week of the previous year. Therefore, some adjustment is necessary before the value is output:

```
if( weekno==0 )
   weekno = 52;
```

[](/book/tiny-c-projects/chapter-13/)To complete the code update from `week03.c`, you must remove all the newlines from the *printf()* statement[](/book/tiny-c-projects/chapter-13/) that outputs the current month or pair of months. Follow these statements with a new *printf()* statement[](/book/tiny-c-projects/chapter-13/):

```
printf(" - Week %d\n",weekno);
```

[](/book/tiny-c-projects/chapter-13/)The final program is available in the online repository as `week04.c`. Here is a sample run:

```
December / January - Week 52
Sun Mon Tue Wed Thu Fri Sat
[26] 27  28  29  30  31   1
```

[](/book/tiny-c-projects/chapter-13/)Here is the output for January 1 of the same week:

```
December / January - Week 52
Sun Mon Tue Wed Thu Fri Sat
26  27  28  29  30  31 [ 1]
```

[](/book/tiny-c-projects/chapter-13/)By the way, you can also use the *strftime()* function[](/book/tiny-c-projects/chapter-13/) to obtain the current week number. The placeholder is `%W`, but it reports the first day of the week as Monday. The week number value is set into a string, which must be converted to an integer to perform any math. Like the formula I chose to use for my update to the code, the *strftime()* function[](/book/tiny-c-projects/chapter-13/) returns 0 for the first week of the [](/book/tiny-c-projects/chapter-13/)year.

### [](/book/tiny-c-projects/chapter-13/)13.3.2 Showing a month

[](/book/tiny-c-projects/chapter-13/)The [](/book/tiny-c-projects/chapter-13/)month program was the first calendar program I wrote. I used it to help with my C programming blog posts ([https://c-for-dummies.com/blog](https://c-for-dummies.com/blog)), which I write in advance and schedule for later. Obviously, I could use the *cal* program, which outputs the current month as a default:

```
December 2021
Su Mo Tu We Th Fr Sa
          1  2  3  4
 5  6  7  8  9 10 11
12 13 14 15 16 17 18
19 20 21 22 23 24 25
26 27 28 29 30 31
```

[](/book/tiny-c-projects/chapter-13/)Oh, and the *cal* program does lots of other things, too. But I didn’t let its flexibility stop me. Here is the output from my program, which I call *month*:

```
December 2021
Sun Mon Tue Wed Thu Fri Sat
             1   2   3   4
 5   6   7   8   9  10  11
12  13  14  15  16  17  18
19  20  21  22  23  24  25
26 [27] 28  29  30  31
```

[](/book/tiny-c-projects/chapter-13/)The output is a bit wider, which I find more readable—even back before I needed reading glasses. After all, my goal is to output the current month. The dimensions of the *cal* program’s output are designed so that the entire year can be shown three months wide by three columns deep. My *month* program[](/book/tiny-c-projects/chapter-13/) could output months three wide, but the text won’t fit on an 80-column screen. I touch upon this issue later in this chapter.

[](/book/tiny-c-projects/chapter-13/)A month of dates is really a grid: rows for weeks and columns for days of the week. It’s not a full grid because the starting point occurs at a specific column; the first row of output is special. The rest of the days of the month flow through the grid until the last day, when output stops.

[](/book/tiny-c-projects/chapter-13/)The following listing shows my test code to ensure that the month program works. It outputs the month of December 2021. The focus is on the nested loop: the *while* loop uses the variable `day`[](/book/tiny-c-projects/chapter-13/) to churn through days of the month. The inner *for* loop processes weeks. The first week is special, which outputs blanks for days from the previous month.

##### Listing 13.10 Source code for month01.c

```
#include <stdio.h>
 
int main()
{
    int mdays,today,first,day,d;
 
    mdays = 31;                               #1
    today = 27;                               #2
    first = 3;                                #3
 
    printf("December 2021\n");
    printf("Sun Mon Tue Wed Thu Fri Sat\n");
 
    day = 1;                                  #4
    while( day<=mdays )                       #5
    {
        for( d = 0; d < 7; d++)               #6
        {
            if( d<first && day==1 )           #7
            {
                printf("    ");               #8
            }
            else                              #9
            {
                if( day == today )            #10
                    printf("[%2d]",day);
                else
                    printf(" %2d ",day);      #11
                day++;                        #12
                if( day>mdays )               #13
                    break;
            }
        }
        putchar('\n');
    }
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-13/)From listing 13.10, in the *for* loop you can see that the first week of the month is handled differently from the remaining weeks. No output should occur before the first day of the month. Variable `first`[](/book/tiny-c-projects/chapter-13/) holds the weekday value—3 for Wednesday—so the *if* test is TRUE for days before the first of the month:

```
if( d<first && day==1 )
{
   printf("    ");
}
```

[](/book/tiny-c-projects/chapter-13/)Variable `d` tracks days of the week, Sunday through Saturday (0 through 6). Variable `first`[](/book/tiny-c-projects/chapter-13/) holds the day of the week on which the first of the month falls. Variable `day`[](/book/tiny-c-projects/chapter-13/) represents the day of the month.

[](/book/tiny-c-projects/chapter-13/)When the first of the month is encountered, the *else* portion[](/book/tiny-c-projects/chapter-13/) of the *if* decision[](/book/tiny-c-projects/chapter-13/) takes over, outputting the rest of the month grid. Sample output for this version of the month program is shown earlier. The source code file `month01.c` is available in the online repository.

[](/book/tiny-c-projects/chapter-13/)I messed with variables `mdays`[](/book/tiny-c-projects/chapter-13/), `today`[](/book/tiny-c-projects/chapter-13/), and `first`[](/book/tiny-c-projects/chapter-13/) to ensure that the month program output the various month configurations. The next step to improve the code is to use the current month’s data. This improvement requires several steps.

[](/book/tiny-c-projects/chapter-13/)First, the code must include the *february[](/book/tiny-c-projects/chapter-13/)()* and *thefirst()* functions[](/book/tiny-c-projects/chapter-13/), covered earlier in this chapter. You need to add the *february()* function[](/book/tiny-c-projects/chapter-13/) to complete a proper `mdays[]` array[](/book/tiny-c-projects/chapter-13/), which contains days of the month for the current year. The other function lets you know upon which weekday the first of the month falls.

[](/book/tiny-c-projects/chapter-13/)Second, the variable declarations are updated to include the month name constants, `mdays[]` array[](/book/tiny-c-projects/chapter-13/), and other variables required to report the current month’s dates:

```
const char *months[] = {
   "January", "February", "March", "April",
   "May", "June", "July", "August",
   "September", "October", "November", "December"
};
int mdays[] = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };
time_t now;
struct tm *date;
int month,today,weekday,year,first,day,d;
```

[](/book/tiny-c-projects/chapter-13/)Third, the *time[](/book/tiny-c-projects/chapter-13/)()* and *localtime()* functions[](/book/tiny-c-projects/chapter-13/) are called to obtain details about the current date:

```
time(&now);
date = localtime(&now);
```

[](/book/tiny-c-projects/chapter-13/)Fourth, the current date info is packed into the variables `month`[](/book/tiny-c-projects/chapter-13/), `today`[](/book/tiny-c-projects/chapter-13/), `weekday`[](/book/tiny-c-projects/chapter-13/), and `year`[](/book/tiny-c-projects/chapter-13/). February’s days are updated with a call to the *february()* function[](/book/tiny-c-projects/chapter-13/), and variable `first`[](/book/tiny-c-projects/chapter-13/) is set to the day of the week upon which the first of the month falls:

```
month = date->tm_mon;
today = date->tm_mday;
weekday = date->tm_wday;
year = date->tm_year+1900;
mdays[1] = february(year);
first = thefirst(weekday,today);
```

[](/book/tiny-c-projects/chapter-13/)Fifth, the *printf()* statement[](/book/tiny-c-projects/chapter-13/) to output the current month and year is updated:

```
printf("%s %d\n",months[month],year);
```

[](/book/tiny-c-projects/chapter-13/)And finally, the `mdays` variable[](/book/tiny-c-projects/chapter-13/) in the original source code file must be replaced by `mdays[month]` in the final version.

[](/book/tiny-c-projects/chapter-13/)This update to the code is titled `month02.c`, available in the online repository. Unlike the original, static program, this version outputs the current month.

#### [](/book/tiny-c-projects/chapter-13/)Exercise 13.3

[](/book/tiny-c-projects/chapter-13/)The *month* program’s output[](/book/tiny-c-projects/chapter-13/) lists the current month and year as the top heading but right-justified. Update the code to create a new function, `center`[](/book/tiny-c-projects/chapter-13/)`()`. The function’s purpose is to output a string of text centered within a certain width. Here is the prototype to use:

```
void center(char *text,int width);
```

[](/book/tiny-c-projects/chapter-13/)The function calculates the length of string `text` and then does the fancy math to center the string within the given width. If the string is longer than the `width`, it’s output and truncated to the `width`.

[](/book/tiny-c-projects/chapter-13/)Making this update to the `month02.c` code involves more than just writing the *center()* function[](/book/tiny-c-projects/chapter-13/). Ensure that the function is called with the proper string arguments and that the result is output atop the calendar. My solution is titled `month03.c`, and it’s available in the online repository.

#### [](/book/tiny-c-projects/chapter-13/)Exercise 13.4

[](/book/tiny-c-projects/chapter-13/)No, you’re not quite done with the month program[](/book/tiny-c-projects/chapter-13/). Your final task is to modify the *main()* function from `month03.c` (see the preceding exercise) so that any command-line arguments are parsed as a month-and-year value. Both values must be present and valid; otherwise, the current month is output. My solution is available in the online repository as [](/book/tiny-c-projects/chapter-13/)`month04.c`.

### [](/book/tiny-c-projects/chapter-13/)13.3.3 Displaying a full year

[](/book/tiny-c-projects/chapter-13/)The [](/book/tiny-c-projects/chapter-13/)issue with outputting a full year has nothing to do with fancy date coding; the math and functions required are already presented so far in this chapter. The problem is getting the output correct—rows and columns.

[](/book/tiny-c-projects/chapter-13/)Figure 13.2 shows the output from a *year* program[](/book/tiny-c-projects/chapter-13/) that uses the same format as the *months* program[](/book/tiny-c-projects/chapter-13/), shown earlier in this chapter. You see three columns by four rows of months. Steam output generates the text, one row at a time. Some coordination is required to produce the visual effect you see in the figure. Further, the output is far too wide for a typical 80-column text screen. So, while the math and functions might be known, fine-tuning the output is the big issue.

![Figure 13.2 Output from a year program that uses the same format as the month program](https://drek4537l1klr.cloudfront.net/gookin/Figures/13-02.png)

[](/book/tiny-c-projects/chapter-13/)Rather than go hog-wild and attempt to code a multicolumn year program all at once, I sought to first code a long vertical column for the current year. The code, `year01.c`[](/book/tiny-c-projects/chapter-13/), is available in the online repository. It uses the existing *center[](/book/tiny-c-projects/chapter-13/)()* and *february()* functions[](/book/tiny-c-projects/chapter-13/).

[](/book/tiny-c-projects/chapter-13/)The *main()* function consists of two parts. The first part initializes all variables to a specific year. I chose the year 2000. The code sets the weekday for January 1, which starts the entire year. Once established, the second part of the *main()* function consists of a loop to output the months.

[](/book/tiny-c-projects/chapter-13/)The following listing shows the initialization portion of the *main()* function. The code is cobbled together from the *month* series of programs, though the program doesn’t scan command-line input.

##### Listing 13.11 Initialization in the *main()* function from year01.c

```
const char *months[] = {                          #1
    "January", "February", "March", "April",
    "May", "June", "July", "August",
    "September", "October", "November", "December"
};
int mdays[] = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };
struct tm date;
int month,weekday,year,day,dow;
const int output_width = 27;
char title[output_width];
 
date.tm_year = 2000-1900;                         #2
date.tm_mon = 0;
date.tm_mday = 1;
date.tm_hour = 0;                                 #3
date.tm_min = 0;
date.tm_sec = 0;
putenv("TZ=GMT");                                 #4
tzset();
mktime(&date);                                    #5
 
weekday = date.tm_wday;                           #6
year = date.tm_year+1900;                         #7
mdays[1] = february(year);                        #8
```

[](/book/tiny-c-projects/chapter-13/)It’s important that the time zone be set to GMT, as shown in listing 13.11. In my original code, I forgot to do this step—even though I warned about doing so earlier in this chapter—and the oversight caused lots of grief. As I was testing the code late in the evening, the years and dates were off. Only by asserting GMT as the time zone does the calendar year properly render, no matter what your time zone.

[](/book/tiny-c-projects/chapter-13/)The *main()* function’s nested loops are shown next. They consist of an outer *for* loop to process the months and an inner while loop to process days of the month. Variable `dow`[](/book/tiny-c-projects/chapter-13/) counts weekdays. It’s updated manually as opposed to being in a loop because the first weekday of the month isn’t the same for every month.

##### Listing 13.12 The output loop from the *main()* function in year01.c

```
dow = 0;                                         #1
for( month=0; month<12; month++ )                #2
{
    sprintf(title,"%s %d",months[month],year);   #3
    center(title,output_width);
    printf("Sun Mon Tue Wed Thu Fri Sat\n");
 
    day = 1;                                     #4
    while( day<=mdays[month] )                   #5
    {
        if( dow<weekday && day==1 )              #6
        {
            printf("    ");
            dow++;
        }
        else
        {
            printf(" %2d ",day);                 #7
            dow++;                               #8
            if( dow > 6 )                        #9
            {
                dow = 0;                         #10
                putchar('\n');                   #11
            }
            day++;                               #12
            if( day>mdays[month] )               #13
                break;
        }
    }
    weekday = dow;                               #14
    dow = 0;                                     #15
    printf("\n\n");
}
```

[](/book/tiny-c-projects/chapter-13/)Variable `dow`[](/book/tiny-c-projects/chapter-13/) works with variable `weekday`[](/book/tiny-c-projects/chapter-13/) to output the first week of January. Afterward, variables `weekday`[](/book/tiny-c-projects/chapter-13/) and `dow`[](/book/tiny-c-projects/chapter-13/) are updated so that the following month’s start day is properly set.

[](/book/tiny-c-projects/chapter-13/)The full code is available in the online repository as `year01.c`. Here is the first part of the output:

```
January 2000
Sun Mon Tue Wed Thu Fri Sat
                         1
 2   3   4   5   6   7   8
 9  10  11  12  13  14  15
16  17  18  19  20  21  22
23  24  25  26  27  28  29
30  31

      February 2000
Sun Mon Tue Wed Thu Fri Sat
         1   2   3   4   5
 6   7   8   9  10  11  12
. . .
```

[](/book/tiny-c-projects/chapter-13/)Each month follows, all down one long page of text. The output is accurate for the year 2000, but who wants to relive that?

#### [](/book/tiny-c-projects/chapter-13/)Exercise 13.5

[](/book/tiny-c-projects/chapter-13/)Modify the `year01.c` code[](/book/tiny-c-projects/chapter-13/) so that it accepts a command-line argument for the year to output. When a command-line argument isn’t available, the current year is output. The changes necessary all take place in the main() function. Remember that the year input and the `tm_year` value differ by 1900.

[](/book/tiny-c-projects/chapter-13/)My solution is named `year02.c` and is found in the online repository. Comments in the code explain my [](/book/tiny-c-projects/chapter-13/)approach.

### [](/book/tiny-c-projects/chapter-13/)13.3.4 Putting the full year into a grid

[](/book/tiny-c-projects/chapter-13/)To [](/book/tiny-c-projects/chapter-13/)output a full year of months in a grid on a text screen requires that it be output one row at a time. The approach used in the `year01.c` code[](/book/tiny-c-projects/chapter-13/) just won’t work; stream output doesn’t let you back up or move the cursor on the text screen. Each line must be processed one a time, with multiple steps required to output different dates for different months. So, I threw out most of the `year01.c` code[](/book/tiny-c-projects/chapter-13/) to start over.

[](/book/tiny-c-projects/chapter-13/)The calendar still progresses month by month. But the months are organized into columns. For each column, individual rows for each month are output. Figure 13.3 illustrates this approach, with each month output a row at a time: two header rows, a special first week of the month row, and then the remaining weeks in the month. Each month must output six weeks, even when the month has only five weeks of dates.

![Figure 13.3 The approach to output a multicolumn display](https://drek4537l1klr.cloudfront.net/gookin/Figures/13-03.png)

[](/book/tiny-c-projects/chapter-13/)To start working on the code, I copied the *center[](/book/tiny-c-projects/chapter-13/)()* and *february()* functions[](/book/tiny-c-projects/chapter-13/) from the existing *year* source code files. The *main()* function retains most of the setup required for the `year02.c` update to read a command-line argument. From this base, I built the rest of the code.

[](/book/tiny-c-projects/chapter-13/)From the top down, the first change is to add a defined constant, `COLUMNS`[](/book/tiny-c-projects/chapter-13/):

```
#define COLUMNS 3
```

[](/book/tiny-c-projects/chapter-13/)This symbolic constant sets the number of columns wide for the output, but it’s not a value the user should change: valid values for `COLUMNS` are limited to factors of 12. You can change the definition to two, three, four, six, or even 12. But if you use another value, the arrays in the code will overflow.

[](/book/tiny-c-projects/chapter-13/)The next update required is to the *center()* function[](/book/tiny-c-projects/chapter-13/). As used earlier in this chapter, the function centers the month and year within a given width but doesn’t pad out the rest of the row of text. To line up the months in a grid, the header row one must be output at a consistent size. The next listing shows the required updates to the *center()* function[](/book/tiny-c-projects/chapter-13/) for row-by-row output. The `width` argument centers the text *and* sets the number of spaces to pad on both sides.

##### Listing 13.13 The updated *center()* function

```
void center(char *text,int width)
{
    int s,length,indent;
 
    length = strlen(text);
    if( length < width )
    {
        indent = (width-length)/2;
        for(s=0;s<indent;s++)
            putchar(' ');
        while( *text )         #1
        {
            putchar(*text);    #2
            text++;            #3
            s++;               #4
        }
        for(;s<width;s++)      #5
            putchar(' ');
    }
    else
    {
        for(s=0;s<width;s++)
            putchar(*text++);
    }
}
```

[](/book/tiny-c-projects/chapter-13/)With the *center()* function[](/book/tiny-c-projects/chapter-13/) updated, my approach is to output only the first row by itself—just to see whether it works. The program outputs header row one, the month and year. I used this code:

```
for( month=0; month<12; month+=COLUMNS )    #1
{
    for( c=0; c<COLUMNS; c++ )
    {
        sprintf(title,"%s %d",months[month+c],year);
        center(title,output_width);
        printf("   ");                      #2
    }
    putchar('\n');
}
```

[](/book/tiny-c-projects/chapter-13/)The *prntf()* statement[](/book/tiny-c-projects/chapter-13/) outputs three spaces to keep each month/year header separated in the grid. This program serves as a test to ensure that the grid is output in the order I want. Here’s a sample run, minus a few spaces to fit on this page:

```
January 2021              February 2021              March 2021
   April 2021                 May 2021                  June 2021
    July 2021                August 2021             September 2021
  October 2021              November 2021             December 2021
```

[](/book/tiny-c-projects/chapter-13/)Adding the weekday header row is the next step. It requires a second *for* loop inside the outer `month` loop. In fact, each row of output represents a *for* loop in the code. These statements are inserted after the `putchar('\n')` statement[](/book/tiny-c-projects/chapter-13/) ending the previous *for* loop, which also adds spaces to separate the columns:

```
for( c=0; c<COLUMNS; c++ )
{
   printf("Sun Mon Tue Wed Thu Fri Sat   ");
}
```

[](/book/tiny-c-projects/chapter-13/)At this point, I became confident that I could output the year calendar in a grid. The key was to use sequential *for* loops, one for each row in the month. The last statement in each *for* loop pads spaces to keep the month grids separate in each column.

[](/book/tiny-c-projects/chapter-13/)The most difficult row to output is the first week of the month. As with the other calendar programs in this chapter, the first day of the month starts on a specific weekday. I could use the *first()* function[](/book/tiny-c-projects/chapter-13/) to determine each month’s starting weekday, but instead I created an array in the *main()* function:

```
int dotm[12];
```

[](/book/tiny-c-projects/chapter-13/)The `dotm[]` (day of the month) array[](/book/tiny-c-projects/chapter-13/) holds the starting day for each month in the year. Its values are the same as the `weekday` variable[](/book/tiny-c-projects/chapter-13/), 0 through 6. The `weekday` variable[](/book/tiny-c-projects/chapter-13/) already holds the day of the week for January 1. It’s stored in element 0 of the `dotm[]` array[](/book/tiny-c-projects/chapter-13/). A *for* loop then fills in values for the remaining months:

```
dotm[0] = weekday;

for( month=1; month<12; month++ )
{
   dotm[month] = (mdays[month-1]+dotm[month-1]) % 7;
}
```

[](/book/tiny-c-projects/chapter-13/)The statement in the *for* loop totals the values of the number of days in the previous month, `mdays[month-1]`, with the starting day of the week for the previous month, `dotm[month-1]`. This total is modulo 7, which yields the starting day of the week for the month represented by variable `month`[](/book/tiny-c-projects/chapter-13/). When the loop is complete, the `dotm[]` array[](/book/tiny-c-projects/chapter-13/) holds the starting weekday for the first of each month in the given year.

[](/book/tiny-c-projects/chapter-13/)Listing 13.14 shows the next nested *for* loop that generates the first row for each month of the year. The starting value in the `dotm[]` array[](/book/tiny-c-projects/chapter-13/) determines which weekday starts the month. The day of the month, starting with one, is stored in variable `day`[](/book/tiny-c-projects/chapter-13/).

##### Listing 13.14 The third nested *for* loop, outputting the first week of each month

```
for( c=0; c<COLUMNS; c++ )
{
    day = 1;                       #1
    for( dow=0; dow<7; dow++ )     #2
    {
        if( dow<dotm[month+c] )    #3
        {
            printf("    ");
        }
        else
        {
            printf(" %2d ",day);   #4
            day++;                 #5
        }
    }
    printf("  ");                  #6
    dotm[month+c] = day;           #7
}
putchar('\n');
```

[](/book/tiny-c-projects/chapter-13/)Most of the *for* loop shown in listing 13.14 is borrowed from code presented earlier in this chapter. What’s different is saving the day of the month for the next row’s output: `dotm[month+c]` `=` `day`. This value, available in variable `day`[](/book/tiny-c-projects/chapter-13/), replaces the starting day of the month in the `dotm[]` array[](/book/tiny-c-projects/chapter-13/). It’s used to output the next row, to set the day of the month value for the next Sunday.

[](/book/tiny-c-projects/chapter-13/)The final *for* loop is responsible for outputting rows two through six for each month. It includes a nested for loop for each day of the week, with the outer *for* loop processing each week. The following listing shows the details, which again use the `dotm[]` array[](/book/tiny-c-projects/chapter-13/) to hold the starting day for each subsequent week.

##### Listing 13.15 The final *for* loops for the *main()* function

```
for( week=1; week<6; week++ )               #1
{
    for( c=0; c<COLUMNS; c++ )              #2
    {
        day = dotm[month+c];                #3
        for( dow=0; dow<7; dow++ )          #4
        {
            if( day <= mdays[month+c] )     #5
                printf(" %2d ",day);
            else
                printf("    ");             #6
            day++;
        }
        printf("  ");                       #7
        dotm[month+c] = day;                #8
    }
    putchar('\n');                          #9
}
putchar('\n');                              #10
```

[](/book/tiny-c-projects/chapter-13/)Because the starting day of the week is saved in the `dotm[]` array[](/book/tiny-c-projects/chapter-13/), the triple nested loops shown in listing 13.15 have an easy time outputting weeks for each row and then each month in the larger grid row.

[](/book/tiny-c-projects/chapter-13/)The updated code for the *year* program[](/book/tiny-c-projects/chapter-13/) is available in the online repository as `year03.c`. The output is shown in figure 13.2. I’ve adjusted the `COLUMNS` value to 2 and then 4, and the code still performs well. It also handles the year as a command-line argument. But it’s just too wide!

[](/book/tiny-c-projects/chapter-13/)Yes, you can adjust the terminal window for your operating system. Still, I like a cozy 80-by-24 window, just like grandpa used. Though I could adjust the output width for days of the week, making it narrower like the *cal* program, a better way to condense things might be to color-code [](/book/tiny-c-projects/chapter-13/)the output.

## [](/book/tiny-c-projects/chapter-13/)13.4 A calendar in color

[](/book/tiny-c-projects/chapter-13/)Text [](/book/tiny-c-projects/chapter-13/)[](/book/tiny-c-projects/chapter-13/)mode need not be as boring as it was at the height of its unpopularity in the early 1980s. Yes, many people had text-only displays because it was cheaper. Early graphics systems, primitive beyond belief by today’s standards, were pricey. Early PC monochrome monitors could output text in normal or high intensity (brightness), inverse, and underline. Some data terminals output text in color, as did a few home computers.

[](/book/tiny-c-projects/chapter-13/)As costs came down, color text became more common. Early word processors highlighted onscreen text in various colors to show different attributes and fonts. Colorful text programs, databases, spreadsheets, and such were all the rage—until graphical operating systems took over. Then color text took the backseat, where it’s been ever since.

[](/book/tiny-c-projects/chapter-13/)Color text can aid in program visibility. It’s easier to identify different parts of the screen when the text is colored differently. Add in Unicode fancy characters, and the text terminal has a potential for output more interesting than just letters and numbers.

### [](/book/tiny-c-projects/chapter-13/)13.4.1 Understanding terminal colors

[](/book/tiny-c-projects/chapter-13/)Text [](/book/tiny-c-projects/chapter-13/)[](/book/tiny-c-projects/chapter-13/)output in the terminal windows can be whatever the boring default is, such as green on black, but your options aren’t limited to the terminal window’s settings. Your programs can generate a variety of colors—eight foreground and eight background for up to 64 combinations, many of them annoying or invisible. To make this rainbow magic happen, the program outputs ANSI color sequences. As most terminals are ANSI-color compatible, all you need to know are the proper ANSI escape sequences.

[](/book/tiny-c-projects/chapter-13/)An ANSI escape sequence is a series of characters, the first of which is the escape character, ASCII 27, hex 1B. This character must be output directly; you can’t press the keyboard’s Esc key to pull off this trick. The remainder of the characters follow a pattern, which are numerical codes representing various colors. The final character is `m`, which signals the end of the escape sequence, as illustrated in figure 13.4.

![Figure 13.4 The format for an ANSI color text escape sequence](https://drek4537l1klr.cloudfront.net/gookin/Figures/13-04.png)

[](/book/tiny-c-projects/chapter-13/)Text output that follows the ANSI sequence appears in the specified attributes or colors. To change colors, issue a new escape sequence. To restore terminal colors, a reset escape sequence is given.

[](/book/tiny-c-projects/chapter-13/)Table 13.1 lists the basic character effects or attributes available with ANSI escape sequences. The escape character is listed as hex value `\x1b`, how it appears as a character in C.

##### [](/book/tiny-c-projects/chapter-13/)Table 13.1 ANSI text effects[(view table figure)](https://drek4537l1klr.cloudfront.net/gookin/HighResolutionFigures/table_13-1.png)

| [](/book/tiny-c-projects/chapter-13/)Effect | [](/book/tiny-c-projects/chapter-13/)Code | [](/book/tiny-c-projects/chapter-13/)Sequence |
| --- | --- | --- |
| [](/book/tiny-c-projects/chapter-13/)Reset | [](/book/tiny-c-projects/chapter-13/)0 | [](/book/tiny-c-projects/chapter-13/)\x1b[0m |
| [](/book/tiny-c-projects/chapter-13/)Bold | [](/book/tiny-c-projects/chapter-13/)1 | [](/book/tiny-c-projects/chapter-13/)\x1b[1m |
| [](/book/tiny-c-projects/chapter-13/)Faint | [](/book/tiny-c-projects/chapter-13/)2 | [](/book/tiny-c-projects/chapter-13/)\x1b[2m |
| [](/book/tiny-c-projects/chapter-13/)Underline | [](/book/tiny-c-projects/chapter-13/)4 | [](/book/tiny-c-projects/chapter-13/)\x1b[4m |
| [](/book/tiny-c-projects/chapter-13/)Blinking | [](/book/tiny-c-projects/chapter-13/)5 | [](/book/tiny-c-projects/chapter-13/)\x1b[5m |
| [](/book/tiny-c-projects/chapter-13/)Inverse | [](/book/tiny-c-projects/chapter-13/)7 | [](/book/tiny-c-projects/chapter-13/)\x1b[7m |

[](/book/tiny-c-projects/chapter-13/)Not all attributes shown in table 13.1 are available in every terminal window. Just in case, the test program shown in the next listing creates defined constant strings for the escape sequences and then outputs each one a line at a time.

##### Listing 13.16 Source code for ansi01.c

```
#include <stdio.h>

#define RESET "\x1b[0m"
#define BOLD "\x1b[1m"
#define FAINT "\x1b[2m"
#define UNDERLINE "\x1b[4m"
#define BLINK "\x1b[5m"
#define INVERSE "\x1b[7m"

int main()
{
   printf("%sBold text%s\n",BOLD,RESET);
   printf("%sFaint text%s\n",FAINT,RESET);
   printf("%sUnderline text%s\n",UNDERLINE,RESET);
   printf("%sBlinking text%s\n",BLINK,RESET);
   printf("%sInverse text%s\n",INVERSE,RESET);

   return(0);
}
```

[](/book/tiny-c-projects/chapter-13/)Running the program for `ansi01.c` yielded mixed results on my various computers. The Mac Terminal window shows the output the best, including blinking text, which is most annoying. Ubuntu Linux in Windows 10/11 shows underlined text well. The rest of my computers were a mixed bag. Again, remember that you can obtain another terminal program if the one your OS provides shows less than spectacular results.

[](/book/tiny-c-projects/chapter-13/)The ANSI color code sequences are shown in table 13.2. Codes in the 30s represent foreground colors; codes in the 40s are background colors.

##### [](/book/tiny-c-projects/chapter-13/)Table 13.2 ANSI color-code escape sequences[(view table figure)](https://drek4537l1klr.cloudfront.net/gookin/HighResolutionFigures/table_13-2.png)

| [](/book/tiny-c-projects/chapter-13/)Color | [](/book/tiny-c-projects/chapter-13/)Foreground Code | [](/book/tiny-c-projects/chapter-13/)Background Code | [](/book/tiny-c-projects/chapter-13/)Foreground Sequence | [](/book/tiny-c-projects/chapter-13/)Background Sequence |
| --- | --- | --- | --- | --- |
| [](/book/tiny-c-projects/chapter-13/)Black | [](/book/tiny-c-projects/chapter-13/)30 | [](/book/tiny-c-projects/chapter-13/)40 | [](/book/tiny-c-projects/chapter-13/)\x1b[30m | [](/book/tiny-c-projects/chapter-13/)\x1b[40m |
| [](/book/tiny-c-projects/chapter-13/)Red | [](/book/tiny-c-projects/chapter-13/)31 | [](/book/tiny-c-projects/chapter-13/)41 | [](/book/tiny-c-projects/chapter-13/)\x1b[31m | [](/book/tiny-c-projects/chapter-13/)\x1b[41m |
| [](/book/tiny-c-projects/chapter-13/)Green | [](/book/tiny-c-projects/chapter-13/)32 | [](/book/tiny-c-projects/chapter-13/)42 | [](/book/tiny-c-projects/chapter-13/)\x1b[32m | [](/book/tiny-c-projects/chapter-13/)\x1b[42m |
| [](/book/tiny-c-projects/chapter-13/)Yellow | [](/book/tiny-c-projects/chapter-13/)33 | [](/book/tiny-c-projects/chapter-13/)43 | [](/book/tiny-c-projects/chapter-13/)\x1b[33m | [](/book/tiny-c-projects/chapter-13/)\x1b[43m |
| [](/book/tiny-c-projects/chapter-13/)Blue | [](/book/tiny-c-projects/chapter-13/)34 | [](/book/tiny-c-projects/chapter-13/)44 | [](/book/tiny-c-projects/chapter-13/)\x1b[34m | [](/book/tiny-c-projects/chapter-13/)\x1b[44m |
| [](/book/tiny-c-projects/chapter-13/)Magenta | [](/book/tiny-c-projects/chapter-13/)35 | [](/book/tiny-c-projects/chapter-13/)45 | [](/book/tiny-c-projects/chapter-13/)\x1b[35m | [](/book/tiny-c-projects/chapter-13/)\x1b[45m |
| [](/book/tiny-c-projects/chapter-13/)Cyan | [](/book/tiny-c-projects/chapter-13/)36 | [](/book/tiny-c-projects/chapter-13/)46 | [](/book/tiny-c-projects/chapter-13/)\x1b[36m | [](/book/tiny-c-projects/chapter-13/)\x1b[46m |
| [](/book/tiny-c-projects/chapter-13/)White | [](/book/tiny-c-projects/chapter-13/)37 | [](/book/tiny-c-projects/chapter-13/)47 | [](/book/tiny-c-projects/chapter-13/)\x1b[37m | [](/book/tiny-c-projects/chapter-13/)\x1b[47m |

[](/book/tiny-c-projects/chapter-13/)Codes can be combined in a single sequence, as shown back in figure 13.4. For example, if you want red text on a blue background, you can use the sequence `\x1b[31;44m`, where 31 is the code for red foreground and 44 is the code for blue background.

[](/book/tiny-c-projects/chapter-13/)The code for `ansi02.c` in the next code listing cycles through all the permutations of foreground and background colors. Run the program to ensure that the terminal window is capable of outputting colors, plus to see how nifty it is to do color text output in C. (Well, it’s a terminal feature, not really part of the C programming language.)

##### Listing 13.17 Source code for ansi02.c

```
#include <stdio.h>
 
int main()
{
    int f,b;
 
 
    for( f=0 ; f<8; f++ )                   #1
    {
        for( b=0; b<8; b++ )                #2
        {
            printf("\x1b[%d;%dm %d:%d ",    #3
                    f+30,b+40,f+30,b+40     #4
                  );
        }
        printf("\x1b[0m\n");                #5
    }
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-13/)The generated output from `ansi02.c`—which I won’t show here because this book isn’t in color—is a grid of all the color combinations. Output with the same foreground and background colors makes the text invisible, but it’s there.

[](/book/tiny-c-projects/chapter-13/)This color output can be used in your text mode programs to spice up the screen or to call attention to one part of the output or another. Keep in mind that the output is still streaming, one character after another. Also, not all terminals properly render the character [](/book/tiny-c-projects/chapter-13/)[](/book/tiny-c-projects/chapter-13/)attributes.

### [](/book/tiny-c-projects/chapter-13/)13.4.2 Generating a tight-but-colorful calendar

[](/book/tiny-c-projects/chapter-13/)It’s [](/book/tiny-c-projects/chapter-13/)[](/book/tiny-c-projects/chapter-13/)possible to squeeze more months on a text screen if you eliminate the space between the days. On a plain text screen, such a move would render the month’s data output useless to all but the most insane nerd. Yet it’s possible to output a month with no spaces between the days—if you change each day’s colors.

[](/book/tiny-c-projects/chapter-13/)In figure 13.5, you see single month output from my year program[](/book/tiny-c-projects/chapter-13/) (so far), the *cal* program, and then from a version of my year program[](/book/tiny-c-projects/chapter-13/) with no spaces between the dates. Which is easiest to read?

![Figure 13.5 Comparing output from various calendar programs](https://drek4537l1klr.cloudfront.net/gookin/Figures/13-05.png)

[](/book/tiny-c-projects/chapter-13/)I would offer that the calendars shown in figure 13.5 rank, from left to right, in order of easiest to read. However, the easier the calendar is to read, the more text screen real estate it occupies. You can always adjust the terminal window size, but a larger window is often impractical for many of the fun times to be had in text mode.

[](/book/tiny-c-projects/chapter-13/)The year configuration on the right in figure 13.5 allows for more months to pack into a typical 80-by-24 character terminal window. In fact, you can march four columns of months across the terminal window when using this dense format. You can almost see all 12 months as well, though not the complete bottom row. The problem is that the numbers all run together—unless you color-code them.

[](/book/tiny-c-projects/chapter-13/)Figure 13.6 shows a full year’s worth of output with no spaces between dates in each month. The dates are color-coded, as are the weekday headers. You can’t see the colors in this book, but even in grayscale, it’s far easier to visually separate the days in a month.

![Figure 13.6 Color-coded days allow the tight calendar to be useful.](https://drek4537l1klr.cloudfront.net/gookin/Figures/13-06.png)

[](/book/tiny-c-projects/chapter-13/)To update the *year* series of programs to output a tighter annual calendar, start with the `year03.c` source code[](/book/tiny-c-projects/chapter-13/). Color output requires no additional headers or libraries—just that you add the ANSI escape sequences to output color. These updates are found in the source code file `year04.c`, available in the online repository. Follow along as I review each update to the code.

[](/book/tiny-c-projects/chapter-13/)First, I added the following defined constants, which help output colors, foreground and background:

```
#define BOLD 1
#define BLACK 0
#define CYAN 6
#define WHITE 7
#define FG 30
#define BG 40
```

[](/book/tiny-c-projects/chapter-13/)The updated year program uses only the colors listed. Constants `FG`[](/book/tiny-c-projects/chapter-13/) and `BG`[](/book/tiny-c-projects/chapter-13/) are added to the other values to create the various foreground and background color combinations.

[](/book/tiny-c-projects/chapter-13/)Second, to output dates, I added the *color_output()* function[](/book/tiny-c-projects/chapter-13/), shown in the next listing. Its job is to output every other date of the month in a different color. The *if* decision[](/book/tiny-c-projects/chapter-13/) alternates between odd and even days, with variable `d` passed as an argument. The defined constants shown earlier are used in the *printf()* statement[](/book/tiny-c-projects/chapter-13/) to set color output.

##### Listing 13.18 The *color_output()* function from year04.c

```
void color_output(int d)
{
    if( d%2 )                         #1
        printf("\x1b[%d;%dm%2d",      #2
                FG+BLACK,
                BG+WHITE,
                d
              );
    else
        printf("\x1b[%d;%dm%2d",      #3
                FG+WHITE,
                BG+CYAN,
                d
              );
}
```

[](/book/tiny-c-projects/chapter-13/)Along with the addition of the *color_output()* function[](/book/tiny-c-projects/chapter-13/), the *printf()* functions[](/book/tiny-c-projects/chapter-13/) that output the current day must be replaced. They go from this:

```
printf(“ %2d “,day);
```

[](/book/tiny-c-projects/chapter-13/)to this:

```
color_output(day);
```

[](/book/tiny-c-projects/chapter-13/)I also changed the length of the month and day strings. The month names are shortened to better fit in the tighter layout:

```
const char *months[] = {
   "Jan", "Feb", "March", "April",
   "May", "June", "July", "Aug",
   "Sep", "Oct", "Nov", "Dec"
};
```

[](/book/tiny-c-projects/chapter-13/)The weekday headings are reset to two characters long. Like the days of the month, the weekday headings must be color-coded. I couldn’t think of a clever way to code the weekday header without creating another array, so a series of *printf()* statements[](/book/tiny-c-projects/chapter-13/) output the days, alternating bold and normal attributes:

```
printf("\x1b[%dm%s",BOLD,"Su");
printf("\x1b[0m%s","Mo");
printf("\x1b[%dm%s",BOLD,"Tu");
printf("\x1b[0m%s","We");
printf("\x1b[%dm%s",BOLD,"Th");
printf("\x1b[0m%s","Fr");
printf("\x1b[%dm%s",BOLD,"Sa");
printf("\x1b[0m  ");
```

[](/book/tiny-c-projects/chapter-13/)Finally, the space between months is reduced to two. Various `putchar('\n')` statements[](/book/tiny-c-projects/chapter-13/) are replaced by *printf()* statements[](/book/tiny-c-projects/chapter-13/) that also output the ANSI escape sequence to reset the colors back to normal. This change avoided color spill at the end of each line of output. In fact, color spill is something you must be aware of when coding color output: always terminate the color output, resetting it when colored text is no longer required. The reset sequence is `\x1b[0m;.`

[](/book/tiny-c-projects/chapter-13/)Output for the program generated by `year04.c` appears earlier, in figure 13.6. The `BOLD` attribute[](/book/tiny-c-projects/chapter-13/) looks faint in the image because of how the terminal window sets bold color. Again, color output differs from terminal to terminal.

#### [](/book/tiny-c-projects/chapter-13/)Exercise 13.6

[](/book/tiny-c-projects/chapter-13/)What is missing from the output for the `year04.c` code, and missing in figure 13.6 as well, is a highlight for the current day of the year.

[](/book/tiny-c-projects/chapter-13/)Your task for this exercise is to modify the source code for `year04.c` to detect the current day of the year and output this one specific day in a special color. Obviously, if the calendar isn’t showing the current year, your code won’t highlight today’s date. So, your solution must detect whether the current year is shown.

[](/book/tiny-c-projects/chapter-13/)My solution is named `year05.c`, available in the online repository. Comments in the text explain what I did. My chosen colors for the current day of the year are red text on a black [](/book/tiny-c-projects/chapter-13/)[](/book/tiny-c-projects/chapter-13/)background.

### [](/book/tiny-c-projects/chapter-13/)13.4.3 Coloring holidays

[](/book/tiny-c-projects/chapter-13/)The [](/book/tiny-c-projects/chapter-13/)[](/book/tiny-c-projects/chapter-13/)final step to the year series of programs, and for both this and the preceding chapter, is to generate an annual calendar with highlighted holidays. This program requires an update to the `year04.c` source code[](/book/tiny-c-projects/chapter-13/) but also the inclusion of the *isholiday()* function[](/book/tiny-c-projects/chapter-13/) from chapter 12. The output uses the return value from *isholiday[](/book/tiny-c-projects/chapter-13/)()* to color-code holiday dates, making them visible in the output.

[](/book/tiny-c-projects/chapter-13/)To accomplish this task, three separate files are required:

-  [](/book/tiny-c-projects/chapter-13/)The new source code file, `year05.c`, which calls the *isholiday()* function[](/book/tiny-c-projects/chapter-13/) and color-codes holiday dates
-  [](/book/tiny-c-projects/chapter-13/)A source code file, `isholiday.c`, containing the *isholiday()* function[](/book/tiny-c-projects/chapter-13/) and its support functions
-  [](/book/tiny-c-projects/chapter-13/)A header file, `holiday_year.h`, which contains resources for the final program: header files to include, defined constants, the `holiday` structure definition[](/book/tiny-c-projects/chapter-13/), and the function prototype for *isholiday()*

[](/book/tiny-c-projects/chapter-13/)These files are available in the online repository. Review them as I cover the changes to the code.

[](/book/tiny-c-projects/chapter-13/)To update the `year04.c` source code[](/book/tiny-c-projects/chapter-13/) to `year05.c`, several updates are required. The first is the addition of the *color_holiday()* function[](/book/tiny-c-projects/chapter-13/), which outputs a holiday’s value with white text on a red background:

```
void color_holiday(int d)
{
   printf("\x1b[%d;%dm%2d",
           FG+WHITE,
           BG+RED,
           d
         );
}
```

[](/book/tiny-c-projects/chapter-13/)Next, the *for* loop that outputs the first day of the month is updated to scan for any holidays. The following listing shows the updates—specifically, how `holiday` structure `h`[](/book/tiny-c-projects/chapter-13/) is filled to make the *isholiday()* function call[](/book/tiny-c-projects/chapter-13/). Also note that if a holiday falls on today’s date, the color used is for the holiday, not the color for today’s date.

##### Listing 13.19 The updated *for* loop for the first day of the week in year 06.c

```
for( c=0; c<COLUMNS; c++ )
{
    h.month = month+c;                                #1
    h.year = year;
    h.name = NULL;
    day = 1;                                          #2
    for( dow=0; dow<7; dow++ )                        #3
    {
        if( dow<dotm[month+c] )                       #4
        {
            printf("  ");
        }
        else
        {
            h.day = day;                              #5
            h.wday = dow;
            if( isholiday(&h)==1 )                    #6
               color_holiday(day);                    #7
            else if( today->tm_year+1900==year &&     #8
                today->tm_mon==month+c &&
                today->tm_mday==day
               )
               color_today(day);
            else
                color_output(day);                    #9
            day++;                                    #10
        }
    }
    printf("\x1b[0m  ");                              #11
    dotm[month+c] = day;                              #12
}
printf("\x1b[0m\n");                                  #13
```

[](/book/tiny-c-projects/chapter-13/)Changes similar to those shown in listing 13.19 are made in the next *for* loop, which outputs the remaining days of the month.

[](/book/tiny-c-projects/chapter-13/)To build the program, you must build both `year06.c` and `isholiday.c` into a single program. I use the following command, which generates a program file named `year`. Also, don’t forget to link in the math library, shown as the last argument:

```
clang -Wall year06.c isholiday.c -o year -lm
```

[](/book/tiny-c-projects/chapter-13/)The program’s output shows the current year—or any year specified at the command prompt—highlighting all the holidays and today’s date, providing today isn’t a holiday. It’s compact, with nearly the entire year fitting in a standard terminal window. This type of output works well only when you [](/book/tiny-c-projects/chapter-13/)[](/book/tiny-c-projects/chapter-13/)color-code [](/book/tiny-c-projects/chapter-13/)[](/book/tiny-c-projects/chapter-13/)the [](/book/tiny-c-projects/chapter-13/)dates.
