# [](/book/tiny-c-projects/chapter-14/)14 Lotto picks

[](/book/tiny-c-projects/chapter-14/)Back when [](/book/tiny-c-projects/chapter-14/)I was a C programmer hatchling, I returned from a trip to Las Vegas eager to write my own keno program. Keno is a random-number game, a cross between the lottery and bingo. You pick several numbers in the range from 1 through 80. Payouts depend on how many numbers you choose and guess correctly.

[](/book/tiny-c-projects/chapter-14/)In the process of writing the code, it became apparent that the payouts offered in the casino were nowhere close to the true odds. For example, if you pick 10 numbers and guess correctly, you win $200,000. But the odds of picking 10 out of 10 numbers in a range of 80 numbers are 1:8,911,712. You should win $8,911,712, right? But at least they have killer shrimp cocktail for a dollar. Or they once did.

[](/book/tiny-c-projects/chapter-14/)The process of programming games of chance clues you in to several interesting and useful coding areas, including these:

-  [](/book/tiny-c-projects/chapter-14/)Understanding the odds and probability
-  [](/book/tiny-c-projects/chapter-14/)Calculating the odds
-  [](/book/tiny-c-projects/chapter-14/)Exploring random numbers
-  [](/book/tiny-c-projects/chapter-14/)Simulating drawing lotto balls
-  [](/book/tiny-c-projects/chapter-14/)Running simulations to test the odds

[](/book/tiny-c-projects/chapter-14/)I acknowledge that I’m not a math genius. I understand math, but I got a D in calculus, which was a passing grade, so that’s my limit. I’m not up to par when it comes to the realms of probability and such. After all, it’s the computer that does the math. Your job is to plug in the proper equation and do all those programming things that keep the computer from crashing. The odds on this skill are pretty good.

## [](/book/tiny-c-projects/chapter-14/)14.1 A tax for those who are bad at math

[](/book/tiny-c-projects/chapter-14/)I play the Powerball, even though my rational brain knows that I have scant chance of winning. My emotional brain argues, “Well, someone has to win!” Satisfied, I dump $20 on a sheaf of random lotto picks and fantasize about what I’ll do with my never-to-appear loot.

[](/book/tiny-c-projects/chapter-14/)It’s this hope that keeps people playing games of chance. Whether it’s the lotto, keno, or any casino game (except for poker and perhaps blackjack), people rely upon desire more than a clean understanding of the math. That’s because the math isn’t in your favor.

### [](/book/tiny-c-projects/chapter-14/)14.1.1 Playing the lottery

[](/book/tiny-c-projects/chapter-14/)Rumor [](/book/tiny-c-projects/chapter-14/)has it that a lottery financed the Great Wall of China. Even if the rumor is untrue, governments have used lotteries for centuries to finance various projects. The early United States used a lottery to fund defense.

[](/book/tiny-c-projects/chapter-14/)Lotteries are used for other purposes as well. The Great Council of Genoa used a lottery to choose its members, drawing several names from a larger pool. Citizens would wager on the winners, calling the game *lotto*. It eventually grew so popular that lotteries were held by drawing numbers instead of names.

[](/book/tiny-c-projects/chapter-14/)The goal of a good lottery is to raise funds, either for a project or to distribute as prize money. A portion of the funds always goes to pay the winners. To keep the lottery successful and popular, the prize money is typically spread across many winners. For most humans, seeing a return of two or three dollars after buying $20 worth of tickets is “winning.”

[](/book/tiny-c-projects/chapter-14/)In the multistate Powerball lottery, numbers are printed on palm-size balls and drawn sequentially from a machine. After five white balls are drawn, with a range from 1 through 69, a single red “power ball” is drawn, with a range from 1 to 26. Various side bets are available, but the desire is to match all five numbers drawn, plus the red power ball, to win the grand prize. If no one guesses all six numbers, the prize money rolls over—sometimes accumulating to the hundreds of millions of dollars.

[](/book/tiny-c-projects/chapter-14/)The kind of lottery simulated for the programs in this chapter is a random-number lottery, like Powerball. Random numbers are drawn to represent the balls from the Powerball lottery. Important to the simulation is not to draw the same number twice, which is impossible in a physical lottery. Two methods of preventing duplicate numbers from being drawn are offered in this [](/book/tiny-c-projects/chapter-14/)chapter.

### [](/book/tiny-c-projects/chapter-14/)14.1.2 Understanding the odds

[](/book/tiny-c-projects/chapter-14/)To [](/book/tiny-c-projects/chapter-14/)dampen your glee over potential lottery winnings, I must discuss the odds. These are the numbers that explain the ratio of the probability of something happening or not happening. I desire not to get too heavily into the math, nor to discuss the difference between statistical odds and gambling odds. Just stare at figure 14.1.

![Figure 14.1 Some math formula-things explain the odds.](https://drek4537l1klr.cloudfront.net/gookin/Figures/14-01.png)

[](/book/tiny-c-projects/chapter-14/)Suppose that you’re betting on the roll of a die. Here is how you would calculate your odds of guessing the right number, one out of six:

```
odds = 1 / (1+5) = 1/6 = 0.166...
```

[](/book/tiny-c-projects/chapter-14/)You have a 16.6% chance of guessing correctly. To calculate your odds of losing, change the numerator in the top equation in figure 14.1 so that *Chances of losing* replaces *Chances of winning*. Here’s the math for the dice roll:

```
odds = 5 / (1+5) = 5/6 = 0.833...
```

[](/book/tiny-c-projects/chapter-14/)You have an 83.3% chance of losing. See how much stating the odds in this manner dashes all hope? It’s depressing.

[](/book/tiny-c-projects/chapter-14/)Odds are also expressed as a colon ratio, as shown on the bottom in figure 14.1. For the dice example, your odds of winning are 1 in 5, often expressed as 5:1 or “five to one.” The odds aren’t 1:6 because one of the choices wins but five lose. Therefore, the odds are expressed 5:1 with the same win/lose percentages: 16.6 and 83.3.

[](/book/tiny-c-projects/chapter-14/)For a game like Powerball, the odds are calculated as numbers are drawn but also considering that the balls aren’t drawn in any order. These items must be considered to properly calculate the odds.

[](/book/tiny-c-projects/chapter-14/)For example, if you could bet on only one ball (and the minimum bet for Powerball is three numbers), the odds are 68:1 or 1/(68+1), which is a 1.45 percent chance of winning. If you bet on drawing two balls, the odds for the second ball become 67:1, and then 66:1 for the third ball, and so on. If you do the math, you get a very small number:

```
1/69 * 1/68 * 1/67 * 1/66 * 1/65 = 7.415e-10
```

[](/book/tiny-c-projects/chapter-14/)Inverting the result, you see that your probability of winning is 1:1,348,621,560. The problem with this value is that the permutations of the numbers drawn must also be considered. If your guesses are 1, 2, 3, 5, and 8, the first ball could be any of those numbers. The second ball could be any four of those numbers, and so on. The number of balls from which the numbers are drawn—69, 68, 67, 66, 65—must be divided by 5 * 4 * 3 * 2 * 1, or 5! (five factorial):

```
( 69 * 68 * 67 * 66 * 65 ) / (5 * 4 * 3 * 2 * 1 ) = 11,238,513
```

[](/book/tiny-c-projects/chapter-14/)Your chance of correctly picking five numbers from a 69-ball lottery is 1:11,268,513. Incidentally, the Powerball lottery pays $1 million if you succeed in accurately picking the five numbers. The probability is 11 times [](/book/tiny-c-projects/chapter-14/)that.

### [](/book/tiny-c-projects/chapter-14/)14.1.3 Programming the odds

[](/book/tiny-c-projects/chapter-14/)At [](/book/tiny-c-projects/chapter-14/)university, I avoided computers because I thought you had to be a math genius to understand them. Poppycock! It’s the computer that does the math. The preceding section introduced the formulas for calculating the odds. The next step is to program them.

[](/book/tiny-c-projects/chapter-14/)The next listing shows the code for a simple odds calculator. You input the chances of something happening, such as guessing the correct roll of a dice. Then you input the chances of it not happening. The computer uses the formula shown earlier (refer to figure 14.1) to output the results. The source code is available in the online repository as `odds01.c`.

##### Listing 14.1 Source code for odds01.c

```
#include <stdio.h>
 
int main()
{
    int ow,ol;                                                   #1
 
    printf("Chances of happening: ");
    scanf("%d",&ow);
    printf("Chances of not happening: ");
    scanf("%d",&ol);
 
    printf("Your odds of winning are[CA] %2.1f%%, or %d:%d\n",   #2
            (float)ow/(float)(ow+ol)*100,                        #3
            ow,
            ol
          );
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-14/)To test the program, use the dice example shown earlier in this section:

```
Chances of happening: 1
Chances of not happening: 5
Your odds of winning are 16.7%, or 1:5
```

[](/book/tiny-c-projects/chapter-14/)If you guess one of the six sides of a die, the chances of it happening are one, and the chances of it not happening are five. The odds of winning are 16.7%, or one in five.

[](/book/tiny-c-projects/chapter-14/)Say you want to calculate the odds of drawing a heart from a deck of cards:

```
Chances of happening: 13
Chances of not happening: 39
Your odds of winning are 25.0%, or 13:39
```

[](/book/tiny-c-projects/chapter-14/)Because hearts is one of four suits, your odds are 25% or one in four—though the program doesn’t reduce the ratio. Even so, the answer is accurate.

[](/book/tiny-c-projects/chapter-14/)To calculate multiple draws, as in a lottery, more math is required: The decreasing number of balls must be multiplied, as well as permutations of the number guessed. This formula is shown earlier, but coded in the following listing. The product of the total items is calculated in variable `i`; the product of the items to draw is calculated in variable `d`.

##### Listing 14.2 Source code for odds02.c

```
#include <stdio.h>
 
int main()
{
    int items,draw,x;
    unsigned long long i,d;                      #1
 
    printf("Number of items: ");
    scanf("%d",&items);
    printf("Items to draw: ");
    scanf("%d",&draw);
 
    i = items;
    d = draw;
    for(x=1;x<draw;x++)                          #2
    {
        i *= items-x;                            #3
        d *= draw-x;                             #4
    }
    printf("Your odds of drawing %d ",draw);
    printf("items from %d are:\n",items);
    printf("\t1:%.0f\n",(float)i/(float)d);      #5
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-14/)I had to keep enlarging the storage space for variables `i` and `d` in the code, from *int* to *long*, to *unsigned long*. The product of multiple values grows quickly. Still, the code renders accurate results for the Powerball odds (not counting the Powerball itself):

```
Number of items: 69
Items to draw: 5
Your odds of drawing 5 items from 69 are:
   1:11238513
```

[](/book/tiny-c-projects/chapter-14/)This result matches the value shown earlier, 11,238,513. As usual, many modifications to the code are possible.

#### [](/book/tiny-c-projects/chapter-14/)Exercise 14.1

[](/book/tiny-c-projects/chapter-14/)One thing that’s missing from the source code for `odds02.c` is error-checking. What happens if the user inputs 10 items but 12 to draw? What happens when 0 is input for either value? Your task for this exercise is to modify the code to confirm that the input of either value isn’t 0, and that the number of items drawn doesn’t exceed the number of items available.

[](/book/tiny-c-projects/chapter-14/)My solution, chock-full of comments, is available in the online repository as `odds03.c`. Use the source code for `odds02.c` as your starting point.

#### [](/book/tiny-c-projects/chapter-14/)Exercise 14.2

[](/book/tiny-c-projects/chapter-14/)Another good improvement to the code is to add commas to the output. After all, which is better: 1:11238513 or 1:11,238,513? Human eyeballs appreciate commas.

[](/book/tiny-c-projects/chapter-14/)Your task for this exercise is to add commas to the odds numeric output. I recommend that you write a function to accept a floating-point value as input. Assume that the value has no decimal portion. Return a string that represents the value, but with commas placed every three positions, as shown earlier. My solution is the *commify()* function[](/book/tiny-c-projects/chapter-14/), available in the source code file `oddsd04.c`, found in the [](/book/tiny-c-projects/chapter-14/)online repository.

## [](/book/tiny-c-projects/chapter-14/)14.2 Here are your winning numbers

[](/book/tiny-c-projects/chapter-14/)Those lottery numbers you find on a fortune cookie fortune were most likely computer generated. I find this development disappointing. Instead, wouldn’t it be charming to imagine some wise old Chinese woman sitting in an incense-filled room, actively consulting with the spirit world for inspiration? But, no. The truth is that the numbers were spewed forth from a computer—randomly generated. Sure, they could be correct guesses and win you a fortune, but the odds are against it.

[](/book/tiny-c-projects/chapter-14/)To have the computer pick your lottery winners requires programming random numbers. These must simulate the randomness of the magical lottery-ball machine that generates the actual numbers drawn in Powerball. Unlike in the real world, your lottery simulation must ensure that the values drawn are in range. Further, you can’t draw the same number twice. Your lottery picks must be unique, just like in the real world.

### [](/book/tiny-c-projects/chapter-14/)14.2.1 Generating random values

[](/book/tiny-c-projects/chapter-14/)I [](/book/tiny-c-projects/chapter-14/)[](/book/tiny-c-projects/chapter-14/)can’t think of a computer game that doesn’t rely upon random numbers. Even complex chess-playing software must still decide its first move. A spin of the old random-number generator is what makes the decision.

[](/book/tiny-c-projects/chapter-14/)Computers don’t generate truly random numbers. The values are referred to as *pseudo random*[](/book/tiny-c-projects/chapter-14/) because, if you had all the data, you could predict the values. Still, random-number generation is central to setting up an interesting game—or picking lottery numbers. The required tool is the *rand()* function[](/book/tiny-c-projects/chapter-14/), prototyped in the `stdlib.h` header file:

```
int rand(void);
```

[](/book/tiny-c-projects/chapter-14/)The function takes no arguments and returns an integer value in the range zero through `RAND_MAX`. This value for most compilers is set to 0x7ffffffff or 2,147,483,647. An improved version of the function, *random[](/book/tiny-c-projects/chapter-14/)()*, works similarly to *rand()*, though this function isn’t a part of the standard C library.

[](/book/tiny-c-projects/chapter-14/)The source code shown next works like one of the first programs I ever wrote in BASIC, years ago. It spews out a grid of random numbers, five rows by five columns. The *rand()* function[](/book/tiny-c-projects/chapter-14/) generates the value saved in variable `r` and output in a *printf()* statement[](/book/tiny-c-projects/chapter-14/).

##### Listing 14.3 Source code for random01.c

```
#include <stdio.h>
#include <stdlib.h>            #1
 
int main()
{
    const int rows = 5;
    int x,y,r;
 
    for( x=0; x<rows; x++ )    #2
    {
        for( y=0; y<rows; y++ )
        {
            r = rand();        #3
            printf("%d ",r);   #4
        }
        putchar('\n');         #5
    }
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-14/)The code shown in listing 14.3 serves its purpose. It generates 25 random values, and the output is completely ugly:

```
1804289383 846930886 1681692777 1714636915 1957747793
424238335 719885386 1649760492 596516649 1189641421
1025202362 1350490027 783368690 1102520059 2044897763
1967513926 1365180540 1540383426 304089172 1303455736
35005211 521595368 294702567 1726956429 336465782
```

[](/book/tiny-c-projects/chapter-14/)The numbers are huge, which is within the range generated by the *rand()* function[](/book/tiny-c-projects/chapter-14/), from zero through `RAND_MAX`. To output values in a different range, you can employ the modulo operator. Here is the expression I use:

```
value = rand() % range;
```

[](/book/tiny-c-projects/chapter-14/)The variable `value`[](/book/tiny-c-projects/chapter-14/) is between 0 and the value of `range`. If you want the value to be between 1 and `range`, I use this version of the expression:

```
value = rand() % range + 1;
```

[](/book/tiny-c-projects/chapter-14/)To set the random-number output to values from 1 through 100, change two statements to modify the source code for `random01.c`:

```
r = rand() % 100 +1;
printf("%3d ",r);
```

[](/book/tiny-c-projects/chapter-14/)The first statement limits the *rand()* function’s output to the range of 1 through 100. The second statement aligns output, restricting the value to a three-character-wide frame, followed by a space. These changes are incorporated into the source code file `random02.c`, available in the online repository. Here is the updated output:

```
84  87  78  16  94
36  87  93  50  22
63  28  91  60  64
27  41  27  73  37
12  69  68  30  83
```

[](/book/tiny-c-projects/chapter-14/)Alas, if you run the program twice, the same numbers are generated. This result doesn’t bode well for your lottery picks because the desire is to be random.

[](/book/tiny-c-projects/chapter-14/)If you’ve ever coded random numbers, you know that the solution is to seed the randomizer. The *srand()* function[](/book/tiny-c-projects/chapter-14/), also prototyped in the `stdlib.h` header file, handles the task:

```
void srand(unsigned int seed);
```

[](/book/tiny-c-projects/chapter-14/)The seed argument is a positive integer value, which the *rand()* function[](/book/tiny-c-projects/chapter-14/) uses in its random-number calculations. The *srand()* function[](/book/tiny-c-projects/chapter-14/) needs to be called only once. It’s often used with the *time()* function[](/book/tiny-c-projects/chapter-14/), which returns the current clock-tick value as a seed:

```
srand( (unsigned)time(NULL) );
```

[](/book/tiny-c-projects/chapter-14/)The *time()* function[](/book/tiny-c-projects/chapter-14/) is typecast to *unsigned* and given the NULL argument. This format ensures that the clock-tick value is properly consumed by the *srand()* function[](/book/tiny-c-projects/chapter-14/), and a new slate of random numbers is generated every time the program runs.

[](/book/tiny-c-projects/chapter-14/)(If you use the *random()* function[](/book/tiny-c-projects/chapter-14/), it has a similar seed function, *srandom[](/book/tiny-c-projects/chapter-14/)()*.)

[](/book/tiny-c-projects/chapter-14/)Improvements to the `random02.c` code[](/book/tiny-c-projects/chapter-14/) are included with `random03.c`, available in the online repository. The `time.h` header file is also included. Here is a sample run:

```
8  53  95  12  93
76  92  59  45  21
32  65  73  95  85
62  55   9  89  16
59  13  33  61  74
```

[](/book/tiny-c-projects/chapter-14/)And here’s another sample run, just to show a different slate of random numbers:

```
14  49  92  92  56
80  95  41  57  66
 8  99  62  86  73
26  32  23  55  38
98  66  94  20  98
```

[](/book/tiny-c-projects/chapter-14/)By the way, because a *time_t* value (returned from the *time()* function[](/book/tiny-c-projects/chapter-14/)) is used, if you run the program rapidly in succession, you see the same values generated. This is a weakness of seeding the randomizer with a clock-tick value, but it shouldn’t be a problem for most [](/book/tiny-c-projects/chapter-14/)[](/book/tiny-c-projects/chapter-14/)applications.

### [](/book/tiny-c-projects/chapter-14/)14.2.2 Drawing lotto balls

[](/book/tiny-c-projects/chapter-14/)Into [](/book/tiny-c-projects/chapter-14/)the tumbler fall 69 balls, numbered 1 through 69. The balls are agitated, popping up and down as they stir for a few tense moments. Using some sort of magic, a single ball is drawn from the lot, rolling down a tube onto a slide. Eager but stupid people tighten their focus to witness the number revealed. No, it probably wasn’t one of their picks—but they have four more chances! Hope remains high. This process is how the Powerball lottery works.

[](/book/tiny-c-projects/chapter-14/)For my lottery simulation, I use the basic premise of the Powerball: randomly draw five numbers in the range from 1 through 69. The sixth, the Powerball, adds another level of complexity, and it can be programmed later, but not in this chapter.

[](/book/tiny-c-projects/chapter-14/)Drawing lottery numbers is like drawing any random sequence of items, such as playing cards. My first attempt at the simulation is shown in the next listing, the source code for `lotto01.c`. It borrows from the random series of programs shown earlier in this chapter but uses a *for* loop to output five random numbers in the range from 1 through 69.

##### Listing 14.4 Source code for lottt01.c

```
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
 
int main()
{
    const int balls = 69, draw = 5;                  #1
    int x,r;
 
    srand( (unsigned)time(NULL) );                   #2
 
    printf("Drawing %d numbers from %d balls:\n",    #3
            draw,
            balls
          );
 
    for( x=0; x<draw; x++ )                          #4
    {
        r = rand() % balls+1;                        #5
        printf("%2d\n",r);                           #6
    }
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-14/)Sometimes I think the code used to generate lottery winners on fortune cookie fortunes is just as simple as that presented in listing 14.4. Here is the output:

```
Drawing 5 numbers from 69 balls:
17
64
38
1
26
```

[](/book/tiny-c-projects/chapter-14/)True, the output could be prettier. An update is presented in a few pages. But if you run the code often enough, you eventually see output like this:

```
Drawing 5 numbers from 69 balls:
44
19
19
10
33
```

[](/book/tiny-c-projects/chapter-14/)Because the code doesn’t check previous numbers drawn, values can repeat. Such output it not only unrealistic—it’s unlucky.

[](/book/tiny-c-projects/chapter-14/)The code can’t determine whether a value drawn is a repeat unless the values drawn are stored and examined. To do so, an array is necessary, dimensioned to the number of balls drawn. Each random value drawn must be stored in the array, and then the array is examined to ensure that no two values repeat.

[](/book/tiny-c-projects/chapter-14/)For my first approach to this problem, I use the `winners[]` array[](/book/tiny-c-projects/chapter-14/), shown next, an update to the `lotto01.c` code[](/book/tiny-c-projects/chapter-14/). A *for* loop fills the array with random values. Next, a nested *for* loop works like a bubble sort to compare each value in the array with other values. When two values match, the second is replaced with a new random value, and the loop is reset to scan again.

##### Listing 14.5 Source code for lottt02.c

```
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
 
int main()
{
    const int balls = 69, draw = 5;
    int x,y;
    int winners[draw];                             #1
 
    srand( (unsigned)time(NULL) );
 
    printf("Drawing %d numbers from %d balls:\n",
            draw,
            balls
          );
 
    for( x=0; x<draw; x++ )                        #2
    {
        winners[x] = rand()%balls+1;
    }
 
    for( x=0; x<draw-1; x++ )                      #3
        for( y=x+1; y<draw ; y++ )                 #4
            if( winners[x]==winners[y] )           #5
            {
                winners[y] = rand()%balls + 1;     #6
                y = draw;                          #7
                x = -1;                            #8
            }
 
    for( x=0; x<draw; x++ )                        #9
        printf("%2d\n",winners[x]);
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-14/)The improved version of the lotto program checks for repeated values and replaces them. The output looks the same as for the first version of the program, but no numbers repeat. You’re all ready to plunk down your money for a chance at riches, yet the code presents room for improvement.

#### [](/book/tiny-c-projects/chapter-14/)Exercise 14.3

[](/book/tiny-c-projects/chapter-14/)The output from the existing rendition of the *lotto* program is tacky. It looks nothing like the back of a fortune cookie fortune. Two ways to improve it are to sort the numbers and output them on a single line to improve readability. For example:

```
Drawing 5 numbers from 69 balls:
5 - 10 - 14 - 19 - 33
```

[](/book/tiny-c-projects/chapter-14/)The output is now linear, ready for printing and saving that old Chinese woman time that she can spend with her grandkids. My solution for this exercise is titled `lotto03.c`, and it’s available in the online [](/book/tiny-c-projects/chapter-14/)repository.

### [](/book/tiny-c-projects/chapter-14/)14.2.3 Avoiding repeated numbers, another approach

[](/book/tiny-c-projects/chapter-14/)The [](/book/tiny-c-projects/chapter-14/)key to any lottery simulation is to ensure that no two numbers are drawn twice. The preceding section offered one method. Another method, one that I’ve used many times, is to simulate all the numbers or balls in an array. As random numbers are generated, elements of the array are updated to reflect that the ball is no longer available. I find this approach much easier to code, though perhaps not as easy to explain.

[](/book/tiny-c-projects/chapter-14/)Figure 14.2 illustrates an array `numbers[]`[](/book/tiny-c-projects/chapter-14/) that’s been initialized with all zeros. The array’s elements represent balls in a lottery. When an element has the value zero, it means that the ball hasn’t yet been drawn. When a ball is drawn, its corresponding element in the array is set to 1, as shown in the figure. For example, if the random number generator returns 12, the 12th element of the array is set to one.

![Figure 14.2 Elements in an array representing lotto balls](https://drek4537l1klr.cloudfront.net/gookin/Figures/14-02.png)

[](/book/tiny-c-projects/chapter-14/)To confirm that a number is available to draw, the code tests the related array element. If the element is 0, the number is available and it’s set to 1. If the element is 1, it’s skipped and another random number is generated. The following code performs this test:

```
for( x=0; x<draw; x++ )
{
   do
       r=rand()%balls;
   while( numbers[r]==1 );
   numbers[r] = 1;
}
```

[](/book/tiny-c-projects/chapter-14/)The `numbers[]` array[](/book/tiny-c-projects/chapter-14/) represents the simulated lotto balls. It’s dimensioned to the number of balls available, 69. Variable `draw`[](/book/tiny-c-projects/chapter-14/) is the number of balls to draw—five, in this instance.

[](/book/tiny-c-projects/chapter-14/)The *do-while* loop[](/book/tiny-c-projects/chapter-14/) repeats whenever the random array element `numbers[r]` is equal to 1. This test ensures that a ball isn’t drawn twice. Otherwise, if the element is zero, meaning that the ball is available, it’s “drawn” by setting its value to one: `numbers[r]` `=` `1`. This statement flags the ball as drawn and prevents it from being drawn again.

[](/book/tiny-c-projects/chapter-14/)The variable `balls`[](/book/tiny-c-projects/chapter-14/) helps to truncate, via the modulus operator, the *rand()* function’s return value: `r=rand()%balls`. However, this value isn’t increased by 1. Because the code deals with an array, the first value must be 0. Therefore, the numbers drawn are in the range of 0 to balls-minus-1, or 68 in this example. This result can be adjusted during output to reflect the true lottery ball number.

[](/book/tiny-c-projects/chapter-14/)The rest of the code to simulate a lottery drawing is presented in the following listing. The `numbers[]` array[](/book/tiny-c-projects/chapter-14/)[](/book/tiny-c-projects/chapter-14/) is initialized, the balls are drawn, and then the result is output. Because the `numbers[]` array is processed sequentially in the final for loop, the winning numbers need not be sorted before they’re output.

##### Listing 14.6 Source code for lotto04.c

```
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
int main()
{
    const int balls = 69, draw = 5;
    int x,r,count;
    int numbers[balls];
 
    srand( (unsigned)time(NULL) );
 
    printf("Drawing %d numbers from %d balls:\n",
            draw,
            balls
          );
 
    for( x=0; x<balls; x++ )       #1
    {
        numbers[x] = 0;
    }
 
    for( x=0; x<draw; x++ )        #2
    {
        do
            r=rand()%balls;
        while( numbers[r]==1 );
        numbers[r] = 1;
    }
 
    count = 0;
    for( x=0; x<balls; x++ )       #3
    {
        if( numbers[x] )           #4
        {
            printf(" %d",x+1);     #5
            count++;
            if( count<draw )       #6
                printf-");
        }
    }
    putchar('\n');
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-14/)The `lotto04.c` source code file shown in listing 14.6 is available in the online repository. Here is the output:

```
Drawing 5 numbers from 69 balls:
1 - 25 - 37 - 39 - 40
```

[](/book/tiny-c-projects/chapter-14/)No numbers are repeated, and the output is sorted. [](/book/tiny-c-projects/chapter-14/)Good luck!

## [](/book/tiny-c-projects/chapter-14/)14.3 Never tell me the odds

[](/book/tiny-c-projects/chapter-14/)If only you could play the lottery forever. Or perhaps you’re eccentric enough to believe that you can purchase 11,238,513 tickets, each with a different number combination, and somehow come out ahead. But the system just doesn’t work that way. Oh, I could wax on about the various techniques to “win” the lottery, but foo on all that.

[](/book/tiny-c-projects/chapter-14/)Fortunately, you don’t need to purchase a bunch of lottery tickets to see how well you would fare playing a game. The computer can not only generate lotto picks but also match those picks with other picks. You can run simulations to determine how many random draws it takes before the computer guesses which numbers the computer chose. As long as the coding is proper, you can put the odds to the test. Alas, you just don’t win any money.

### [](/book/tiny-c-projects/chapter-14/)14.3.1 Creating the lotto() function

[](/book/tiny-c-projects/chapter-14/)To [](/book/tiny-c-projects/chapter-14/)[](/book/tiny-c-projects/chapter-14/)simulate multiple draws in a lottery, you must modify the existing *lotto* code so that the balls are drawn in a function, which I call *lotto()*. This improvement to the code allows the function to be called repeatedly, representing the original numbers to match as well as the guesses made.

[](/book/tiny-c-projects/chapter-14/)I toiled a few times writing the *lotto()* function: should it return the random numbers drawn, or should they be passed in an array? I finally chose to pass an array, which works as a pointer within the function. This method allows the array’s elements to be modified directly, so the function returns nothing.

[](/book/tiny-c-projects/chapter-14/)The *lotto()* function, shown next, uses similar statements as the *main()* function in the *lotto* series of programs[](/book/tiny-c-projects/chapter-14/) shown earlier in this chapter: the `numbers[]` array[](/book/tiny-c-projects/chapter-14/) now dwells within the *lotto()* function because its contents need not be retained between calls. After the array is initialized, a *for* loop sets the random element values representing numbers drawn. This operation is followed by a second *for* loop that processes the entire `numbers[]` array[](/book/tiny-c-projects/chapter-14/), filling elements from the passed array.

##### Listing 14.7 The *lotto()* function from lotto05.c

```
void lotto(int *a)              #1
{
    int numbers[BALLS];         #2
    int x,y,r;
 
    for( x=0; x<BALLS; x++ )    #3
    {
        numbers[x] = 0;
    }
 
    for( x=0; x<DRAW; x++ )     #4
    {
        do
            r=rand()%BALLS;
        while( numbers[r]==1 );
        numbers[r] = 1;
    }
 
    y = 0;                      #5
    for( x=0; x<BALLS; x++ )    #6
    {
        if( numbers[x] )        #7
        {
            *(a+y) = x;         #8
            y++;                #9
        }
        if( y==DRAW )           #10
            break;
    }
}
```

[](/book/tiny-c-projects/chapter-14/)The defined constants `BALLS`[](/book/tiny-c-projects/chapter-14/) and `DRAW`[](/book/tiny-c-projects/chapter-14/) are the same as the *const int* values shown in early versions of the lotto programs. These are made into defined constants so that their values are available to all functions in the source code file.

[](/book/tiny-c-projects/chapter-14/)The *main()* function calls the *lotto()* function, and then it outputs the contents of the array passed. The next listing shows the *main()* function, which again is based on parts of the *lotto* series shown earlier in this chapter.

##### Listing 14.8 The *main()* function from lotto05.c

```
int main()
{
    int x;
    int match[DRAW];                #1
 
    srand( (unsigned)time(NULL) );
 
    printf("Trying to match:");
    lotto(match);                   #2
    for( x=0; x<DRAW; x++ )         #3
    {
        printf(" %d",match[x]+1);
        if( x<DRAW-1 )
            printf(" -");
    }
    putchar('\n');
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-14/)The full source code for `lotto05.c` is available in the online repository. Here is a sample run:

```
Trying to match: 32 - 33 - 45 - 55 - 61
```

[](/book/tiny-c-projects/chapter-14/)The output looks like all the other *lotto* programs so far, though with the *lotto()* function set, it’s now possible to draw multiple lottery numbers in the same code. After all, the prompt above says, “Trying to match.” The next step in the program’s generation is to obtain another set of random lottery ball picks to see whether they match the first numbers [](/book/tiny-c-projects/chapter-14/)[](/book/tiny-c-projects/chapter-14/)drawn.

### [](/book/tiny-c-projects/chapter-14/)14.3.2 Matching lottery picks

[](/book/tiny-c-projects/chapter-14/)The [](/book/tiny-c-projects/chapter-14/)*lotto()* function[](/book/tiny-c-projects/chapter-14/) allows the code to repeatedly pull lottery numbers over and over, trying to match the original draw. To do so, I duplicated the *for* loop and output statements in the `lotto05.c` code[](/book/tiny-c-projects/chapter-14/), but with a second array, `guess[]`. This change appears in the source code file `lotto06.c`, which outputs a second round of lottery numbers to see whether the two draws match. Here is sample output:

```
Trying to match: 2 - 18 - 38 - 47 - 69
    Your guess: 6 - 10 - 34 - 35 - 49
```

[](/book/tiny-c-projects/chapter-14/)I’m not showing the full source code here because it doesn’t do anything new—it just repeats the same block of code but with a new array, `guess[]`. This array is passed to the *lotto()* function[](/book/tiny-c-projects/chapter-14/) and then output, as shown earlier. The result is two lottery number draws. Do they match? Probably not.

[](/book/tiny-c-projects/chapter-14/)Even if the two arrays matched, you must perform a visual inspection to confirm. In the previous sample output, they don’t. But why do the work yourself when the computer is not only bored but all too eager?

[](/book/tiny-c-projects/chapter-14/) To make the comparison between two sets of lottery ball draws, I use the *winner()* function[](/book/tiny-c-projects/chapter-14/), shown here. As arguments, it consumes two arrays, referenced as integer pointers. Nested *for* loops compare each array value from the first array with each array value in the second array. Pointer notation is used to make the comparison. When a match is found, variable `c` is incremented. The total number of matches, ranging from zero through `DRAW`, is returned.

##### Listing 14.9 The *winner()* function from lotto07.c

```
int winner(int *m, int *g)              #1
{
    int x,y,c;
 
    c = 0;                              #2
    for( x=0; x<DRAW; x++ )             #3
        for( y=0; y<DRAW; y++ )         #4
        {
            if( *(m+x) == *(g+y) )      #5
                c++;                    #6
        }
    return(c);                          #7
}
```

[](/book/tiny-c-projects/chapter-14/)The *main()* function calls the *winner()* function[](/book/tiny-c-projects/chapter-14/) immediately after array `guess[]`[](/book/tiny-c-projects/chapter-14/)[](/book/tiny-c-projects/chapter-14/)[](/book/tiny-c-projects/chapter-14/) is filled by the *lotto()* function[](/book/tiny-c-projects/chapter-14/):

```
lotto(guess);
c = winner(match,guess);
```

[](/book/tiny-c-projects/chapter-14/)The arrays are passed by name. In the *winner()* function[](/book/tiny-c-projects/chapter-14/), these arrays are recognized as integer pointers. Back in the *main()* function, the values for array *guess[]*[](/book/tiny-c-projects/chapter-14/) are output, along with a final *printf()* statement that reports the number of matches.

[](/book/tiny-c-projects/chapter-14/)The full code is available in the online repository as `lotto07.c`. Here is a sample run:

```
Trying to match: 20 - 27 - 34 - 41 - 59
     Your draw: 1 - 19 - 27 - 33 - 48
You matched 1 numbers
```

[](/book/tiny-c-projects/chapter-14/)As luck would have it, one of the values matched between the two simulated lottery drawings the first time I ran the code (shown above). The *winner()* function[](/book/tiny-c-projects/chapter-14/) returned one in variable `c`, as both arrays share the value 27. I’m pleased that I didn’t need to run the code several times to show a match. Yet, it’s this step of repeatedly running the program that inspired me to code the program’s final version, covered in the next [](/book/tiny-c-projects/chapter-14/)section.

### [](/book/tiny-c-projects/chapter-14/)14.3.3 Testing the odds

[](/book/tiny-c-projects/chapter-14/)In [](/book/tiny-c-projects/chapter-14/)the Powerball game, you can’t just match a single ball to win. No, you must match a single ball and the Powerball to win some paltry amount. Ditto for two balls: two balls plus the Powerball equals some modest payout. You can, however, match three main numbers to win $7 on a $2 bet. Garsh! Of course, I didn’t code any of the Powerball nonsense, so my *lotto* programs[](/book/tiny-c-projects/chapter-14/) are straightforward, and the prize money is consistently zero.

[](/book/tiny-c-projects/chapter-14/)The odds of matching one number and the Powerball are 1:92. This value means that if you play the game 92 times, you’ll probably match one value and the Powerball at least once—but it’s not a guarantee. I won’t get into the math, but it could take you several hundred times to see a match or you could match the first time. It’s this unpredictability that entices people to gamble—even when the odds are stupidly high.

[](/book/tiny-c-projects/chapter-14/)Rather than run the lotto program[](/book/tiny-c-projects/chapter-14/) over and over, I decided to program a loop to output guesses until at least two numbers match. The next listing shows the *main()* function from an updated—the final—version of the *lotto* series of programs[](/book/tiny-c-projects/chapter-14/). The *lotto[](/book/tiny-c-projects/chapter-14/)()* and *winner()* functions[](/book/tiny-c-projects/chapter-14/) are unchanged, but to the *main()* function I added a constant, `tomatch`[](/book/tiny-c-projects/chapter-14/). It sets the minimum number of balls to match before a *do-while* loop stops drawing random lotto balls. Nothing is output until a match is found, which shaves several seconds from the processing time.

##### Listing 14.10 The *main()* function from lotto08.c

```
int main()
{
    const int tomatch = 2;                               #1
    int x,c,count;
    int match[DRAW],guess[DRAW];                         #2
 
    srand( (unsigned)time(NULL) );
 
    printf("Trying to match:");                          #3
    lotto(match);
    for( x=0; x<DRAW; x++ )
    {
        printf(" %d",match[x]+1);
        if( x<DRAW-1 )
            printf(" -");
    }
    putchar('\n');
 
    count = 0;                                           #4
    do
    {
        lotto(guess);                                    #5
        c = winner(match,guess);                         #6
        count++;                                         #7
    } while( c<tomatch );                                #8
 
    printf("It took %d times to match %d balls:\n",      #9
            count,
            c
          );
    for( x=0; x<DRAW; x++ )                              #10
    {
        printf(" %d",guess[x]+1);
        if( x<DRAW-1 )
            printf(" -");
    }
    putchar('\n');
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-14/)The complete code for `lotto08.c` is available in the online repository. The program keeps drawing random lottery picks until the minimum match value, stored in variable `tomatch`[](/book/tiny-c-projects/chapter-14/), is met. Here is a sample run:

```
Trying to match: 1 - 5 - 21 - 33 - 37
It took 5 times to match 2 balls:
1 - 30 - 37 - 63 - 66
```

[](/book/tiny-c-projects/chapter-14/)The computer took five loops to find two matches—1 and 37, according to the output. You can run the program multiple times to see how many loops it takes to match at least two balls from five out of a total of 69. Again, I don’t know the precise odds, but it’s less than 100.

[](/book/tiny-c-projects/chapter-14/)The fun part comes when you modify the code: alter the `tomatch` constant[](/book/tiny-c-projects/chapter-14/) to the value 5, and then run the program. Here is sample output after I made this modification:

```
Trying to match: 15 - 33 - 47 - 59 - 60
It took 5907933 times to match 5 balls:
15 - 33 - 47 - 59 - 60
```

[](/book/tiny-c-projects/chapter-14/)Above, it took 5,907,933 spins of the *do-while* loop[](/book/tiny-c-projects/chapter-14/) before an exact match of the five balls was achieved.

[](/book/tiny-c-projects/chapter-14/)I don’t know whether this code convinces anyone of the futility of playing a lottery. The issue is never the math; it’s the human misunderstanding of odds and probability. The notion that “someone’s gotta win” trumps logic and common sense every time.

#### [](/book/tiny-c-projects/chapter-14/)Exercise 14.4

[](/book/tiny-c-projects/chapter-14/)The computer mindlessly and effortlessly simulates as many lottery ball draws as you’re willing to let it perform. The `lotto08.c` code[](/book/tiny-c-projects/chapter-14/) shows that even when attempting to match five out of five balls, the program runs rather quickly. Yet, more coding can always be done, especially to sate the curious mind.

[](/book/tiny-c-projects/chapter-14/)Your task for this exercise is modify the `lotto08.c` code[](/book/tiny-c-projects/chapter-14/) with the goal of determining the average number of plays required to match all five balls from 69 possible numbers. Run the simulation 100 times, each time recording how many repeated calls to the *lotto()* function[](/book/tiny-c-projects/chapter-14/) were required to achieve a match. Store each value, and then report the average number of plays it took to make a match.

[](/book/tiny-c-projects/chapter-14/)Here is sample output from my solution, which is available in the online repository as `lotto09.c`:

```
Trying to match: 9 - 32 - 33 - 42 - 64
For 100 times, the average count to match 5 balls is 11566729
```

[](/book/tiny-c-projects/chapter-14/)On average, it took 11,566,729 calls to the *lotto()* function[](/book/tiny-c-projects/chapter-14/) to match the original numbers drawn. Remember from earlier in this chapter that the calculated odds of drawing the same five numbers from 69 lotto balls is 11,238,513. Darn close.

[](/book/tiny-c-projects/chapter-14/)Comments in my solution explain my approach, though please attempt this exercise on your own before you see what I did. The modifications aren’t that involved, because most of the coding necessary is already in the `lotto08.c` source code file.

[](/book/tiny-c-projects/chapter-14/)Oh! And the solution program takes a while to run. On my fastest system, I timed it at almost 9 minutes to churn out the [](/book/tiny-c-projects/chapter-14/)results. Be [](/book/tiny-c-projects/chapter-14/)patient.
