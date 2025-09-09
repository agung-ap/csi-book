# [](/book/tiny-c-projects/chapter-4/)4 Caesarean cipher

[](/book/tiny-c-projects/chapter-4/)Caesar wrote, “[](/book/tiny-c-projects/chapter-4/)Gallia est omnis divisa in partes tres.” If he had wanted the message to be a secret, he would have written, “Tnyyvn rfg bzavf qvivfn va cnegrf gerf.” This subtle encryption was easy to concoct, yet even a literate spy would be unable to translate the scrambled Latin without knowing the key. On the receiving end, where the deciphering method is known, the message is quickly decoded and . . . pity poor Gaul. This method of encoding is today known as the Caesarean cipher.

[](/book/tiny-c-projects/chapter-4/)The Caesarean cipher is by no means secure, but it’s a fun programming exercise. It also opens the door to the concepts of filters and filter programming in C. This chapter covers the concept of a filter, including stuff like this:

-  [](/book/tiny-c-projects/chapter-4/)Dealing with streaming input and output
-  [](/book/tiny-c-projects/chapter-4/)Programming a simple input/output (I/O) filter
-  [](/book/tiny-c-projects/chapter-4/)Rotating characters 13 places
-  [](/book/tiny-c-projects/chapter-4/)Shifting characters in specific increments
-  [](/book/tiny-c-projects/chapter-4/)Coding a hex input filter
-  [](/book/tiny-c-projects/chapter-4/)Creating a NATO phonetic alphabet filter
-  [](/book/tiny-c-projects/chapter-4/)Writing a filter to find words

[](/book/tiny-c-projects/chapter-4/)Filters abide in the command prompt’s realm. Special command characters are used to apply the filter at the prompt, redirecting input and output away from the standard I/O devices. Therefore, I strongly suggest you eschew your beloved IDE for this chapter and dive headfirst into the realm of command-line programming. Doing so makes you almost an über nerd, plus it gives you boasting rights at those few parties you’re invited to attend.

book/tiny-c-projects/chapter-4/)4.1 I/O filters

[](/book/tiny-c-projects/chapter-4/)Do [](/book/tiny-c-projects/chapter-4/)[](/book/tiny-c-projects/chapter-4/)you remember singing about I/O back at computer camp? The reason for such merriment was to drive home the point that the computer beehive exists for the purpose of absorbing input and creating modified output. The key is what happens between the I and the O, and not just the slash character. No, what’s important are the mechanics of modifying input to generate some type of useful output.

[](/book/tiny-c-projects/chapter-4/)An I/O filter is a program that consumes standard input, does something to it, then spews forth the modified output. It’s not an interactive program: input flows into the filter like a gentle stream. The filter does something magical, like remove all the bugs and dirt, and then generates output: pure, clean water (though all this action takes place at a digital level, even the bugs).

### [](/book/tiny-c-projects/chapter-4/)[](/book/tiny-c-projects/chapter-4/)4.1.1 Understanding stream I/O

[](/book/tiny-c-projects/chapter-4/)To [](/book/tiny-c-projects/chapter-4/)[](/book/tiny-c-projects/chapter-4/)[](/book/tiny-c-projects/chapter-4/)best implement a filter, you must embrace the concept of stream I/O, which is difficult for many C programmers to understand. That’s because your experience with computer programs is on an interactive level. Yet in C, input and output work at the stream level.

[](/book/tiny-c-projects/chapter-4/)*Stream I/O* means that all I/O gurgles through a program without pause, like water from a garden hose. The code doesn’t know when you’ve paused or stopped typing. It only recognizes when the stream ends as identified by the end-of-file (EOF[](/book/tiny-c-projects/chapter-4/)) character.

[](/book/tiny-c-projects/chapter-4/)Thanks to line buffering, the code may pay only casual attention to the appearance of the newline character, `\n` (when you press the Enter key). Once encountered, the newline may flush an output buffer, but otherwise stream I/O doesn’t strut or crow about what text is input or how it was generated; all that’s processed is the stream, which you can imagine as one long parade of characters, as illustrated in figure 4.1.

![Figure 4.1 A stream of text—not as jubilant as a parade, but you get the idea.](https://drek4537l1klr.cloudfront.net/gookin/Figures/04-01.png)

[](/book/tiny-c-projects/chapter-4/)Stream I/O may frustrate you, but it has its place. To help you accept it, understand that input may not always come from the standard input device (the keyboard). Likewise, output may not always go to the standard output device (the display). The standard input device, `stdin`[](/book/tiny-c-projects/chapter-4/), is just one of several sources of input. For example, input can also come from a file, another program, or a specific device, like a modem.

[](/book/tiny-c-projects/chapter-4/)The code in listing 4.1 demonstrates how many C beginners craft a wannabe interactive program. The assumption made is that input is interactive. Instead, input is read from the stream (refer to figure 4.1). Though the code may prompt for a single letter, it’s really reading the next character from the input stream. Nothing else matters—no other considerations are made.

##### Listing 4.1 stream_demo.c

```
#include <stdio.h>
 
int main()
{
    int a,b;
 
    printf("Type a letter:");
    a = getchar();                  #1
    printf("Type a letter:");
    b = getchar();                  #2
 
    printf("a='%c', b='%c'\n",a,b);
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-4/)The programmer’s desire is to read two characters, each typed at its own prompt. What happens instead is that the *getchar()* function[](/book/tiny-c-projects/chapter-4/) plucks each character from the input stream, which includes the first letter typed *plus* the Enter key press (newline). Here’s a sample run:

```
Type a letter:a
Type a letter:a='a', b='
'
```

[](/book/tiny-c-projects/chapter-4/)The first character is read by *getchar[](/book/tiny-c-projects/chapter-4/)()*, the letter a. Then the user presses Enter, which becomes the next character read by the second *getchar()* statement. You see this character in the output for `b` (split between two lines). Take a gander at figure 4.2, which illustrates what the user typed as the input stream and how the code read it.

![Figure 4.2 The input stream contains two characters read by two getchar() functions.](https://drek4537l1klr.cloudfront.net/gookin/Figures/04-02.png)

[](/book/tiny-c-projects/chapter-4/)If you type **ab** at the first prompt, you see this output:

```
Type a letter:ab
Type a letter:a='a', b='b'
```

[](/book/tiny-c-projects/chapter-4/)The two *getchar()* functions[](/book/tiny-c-projects/chapter-4/) read characters from the stream, one after the other. If the user types **a** and **b**, these characters are plucked from the stream regardless of the onscreen prompt, lovingly illustrated in figure 4.3. The newline (which appears in the input stream in the figure) isn’t read by the code but is used to flush the buffer. It allows the code to process input without the user having to sit and wait for an EOF.

![Figure 4.3 Two more characters are read from the input stream.](https://drek4537l1klr.cloudfront.net/gookin/Figures/04-03.png)

[](/book/tiny-c-projects/chapter-4/)Understanding stream I/O helps you properly code C programs and also appreciate how an I/O filter works. Even so, you probably remain curious about how interactive programs are constructed. The secret is to avoid stream I/O and access the terminal directly. The Ncurses library is one tool you can use to make programs fully interactive. This library is the foundation upon which full-screen text-mode programs like vi, top, and others are built. Check out Ncurses if you want to code interactive, full-screen text mode programs for Linux. And, of course, I wrote a book on the topic, which you can order from Amazon: *Dan Gookin’s Guide to Ncurses Programming*[](/book/tiny-c-projects/chapter-4/).

[](/book/tiny-c-projects/chapter-4/)*Enough self-promotion.—Editor*

[](/book/tiny-c-projects/chapter-4/)Another aspect of stream I/O is buffering. You see a bit of this when you press the Enter key to process input for a wannabe interactive program like `stream_demo.c`. In fact, an aspect of I/O buffering is present when the program’s first prompt is output:

```
Type a letter:
```

[](/book/tiny-c-projects/chapter-4/)This text appears and output stops because of buffering. Output to the standard output device (`stdout`) is *line buffered* in C. This configuration means that stream output is stored in a buffer until the buffer gets full or when a newline character is encountered in the stream, after which the text is output. It’s the presence of the newline that makes output stop in the `stream_demo.c` program.

[](/book/tiny-c-projects/chapter-4/)Another type of buffer is *block buffering*[](/book/tiny-c-projects/chapter-4/). When this mode is active, output doesn’t appear until the buffer is full—or when the program ends. Even if a newline appears in the stream, block buffering stores the character in the stream, la-di-da.

[](/book/tiny-c-projects/chapter-4/)Buffering for an I/O device is set by using the *setbuf()* function[](/book/tiny-c-projects/chapter-4/), defined in the `stdio.h` header file. This function overrides the terminal’s default line buffering and establishes block buffering using a specific chunk of memory. In effect, it disables line buffering for the given file handle (or standard I/O device) and activates block buffering.

[](/book/tiny-c-projects/chapter-4/)The code in the next listing uses the *setbuf()* function[](/book/tiny-c-projects/chapter-4/) to alter output from line buffering to block buffering. The *setbuf()* statement[](/book/tiny-c-projects/chapter-4/) helps demonstrate how the output stream (`stdout`) is affected.

##### Listing 4.2 buffering.c

```
#include <stdio.h>
 
int main()
{
    char buffer[BUFSIZ];       #1
    int a,b;
 
    setbuf(stdout,buffer);     #2
 
    printf("Type a letter:");
    a = getchar();
    printf("Type a letter:");
    b = getchar();
 
    printf("a='%c', b='%c'\n",a,b);
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-4/)If you build and run `buffering.c`, you see no output. Instead, the *getchar()* function[](/book/tiny-c-projects/chapter-4/) prompts for input, so the program waits. The output is held back, stored in the character array `buffer`[](/book/tiny-c-projects/chapter-4/), waiting for text to fill the buffer or for the program to end.

[](/book/tiny-c-projects/chapter-4/)Here is a sample run of the code, where no prompt appears. Still, the user is somehow prescient enough to provide input, typing ab at the blinking cursor. Only after the Enter key is pressed does the program end and the buffer is flushed, revealing standard output:

```
ab
Type a letter:Type a letter:a='a', b='b'
```

[](/book/tiny-c-projects/chapter-4/)By the way, some C programmers use the *fflush()* function[](/book/tiny-c-projects/chapter-4/) to force output or to clear the input stream. This function, defined in the `stdio.h` header file, dumps the stream for the named file handle, such as `stdin` or `stdout`. I find it unreliable and an awkward method to force stream I/O to somehow feign an interactive C program. Using this technique (which I confess to recommending in some of my other books) is known as a *kludge*[](/book/tiny-c-projects/chapter-4/). This term implies that using *fflush()* to empty an input or output buffer may be a workable solution but not the [](/book/tiny-c-projects/chapter-4/)[](/book/tiny-c-projects/chapter-4/)[](/book/tiny-c-projects/chapter-4/)best.

### [](/book/tiny-c-projects/chapter-4/)4.1.2 Writing a simple filter

[](/book/tiny-c-projects/chapter-4/)Filters [](/book/tiny-c-projects/chapter-4/)[](/book/tiny-c-projects/chapter-4/)modify stream input and generate stream output. They manipulate the stream at the character level: a tiny character pops in, it’s somehow manipulated, and then something else pops out or not at all. The two functions most commonly used to perform the filter’s magic are *getchar[](/book/tiny-c-projects/chapter-4/)()* and *putchar[](/book/tiny-c-projects/chapter-4/)()*, both defined in the `stdio.h` header file.

[](/book/tiny-c-projects/chapter-4/)The *getchar()* function[](/book/tiny-c-projects/chapter-4/) reads a single character from standard input. For most compilers, *getchar[](/book/tiny-c-projects/chapter-4/)()* is a macro, equivalent to the *fgetc()* function[](/book/tiny-c-projects/chapter-4/):

```
c = fgetc(stdin);
```

[](/book/tiny-c-projects/chapter-4/)The *fgetc()* function[](/book/tiny-c-projects/chapter-4/) reads a single character (byte) from an open file handle. On the preceding line, `stdin` is used as the standard input device. The integer value returned is stored in the int variable `c`. This variable *must* be declared of the integer data type, not character. The reason is that important values, specifically the end-of-file (EOF[](/book/tiny-c-projects/chapter-4/)) marker, are integer values. Assigning the function’s return value to a *char* variable means the EOF won’t be interpreted properly.

[](/book/tiny-c-projects/chapter-4/)The *putchar()* function[](/book/tiny-c-projects/chapter-4/) sends a single character to standard output. As with *getchar()*, *putchar[](/book/tiny-c-projects/chapter-4/)()* is often defined as a macro that expands to the *fputc()* function[](/book/tiny-c-projects/chapter-4/):

```
r = fputc(c,stdout);
```

[](/book/tiny-c-projects/chapter-4/)The *fputc()* function[](/book/tiny-c-projects/chapter-4/) sends an integer value `c` to the open file handle represented by `stdout`, the standard output device. The return value, `r`, is the character written or EOF for an error. As with *fgetc()*, both variables `r` and `c` must be integers.

[](/book/tiny-c-projects/chapter-4/)A do-nothing filter is presented in listing 4.3. It uses a *while* loop to process input until the EOF (end-of-file) marker[](/book/tiny-c-projects/chapter-4/) is encountered. In this configuration, a character is read from standard input and stored in an *int* variable `ch`. The value of this character is then compared with the EOF defined constant. Providing that the character read isn’t the EOF, the loop spins. Such a loop can be constructed in other ways, but by using this method, you ensure that the EOF isn’t output accidentally.

##### Listing 4.3 io_filter.c

```
#include <stdio.h>
 
int main()
{
    int ch;                            #1
 
    while( (ch = getchar()) != EOF)    #2
        putchar(ch);                   #3
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-4/)The result of the `io_filter.c` program is to do nothing. It works just like plumbing: water goes in, water comes out. No modification is made to the characters; the *putchar()* function[](/book/tiny-c-projects/chapter-4/) outputs the character input, `ch`[](/book/tiny-c-projects/chapter-4/). Even so, the program demonstrates the basic structure for creating a filter that does something useful.

[](/book/tiny-c-projects/chapter-4/)If you run the filter program by itself, you see input echoed to output: pressing Enter flushes the output buffer, causing the echoed text to appear:

```
hello
hello
```

[](/book/tiny-c-projects/chapter-4/)Press the EOF key to halt the program. In Linux, the EOF key is Ctrl+D. In Windows, press Ctrl+Z for the EOF.

[](/book/tiny-c-projects/chapter-4/)To make the filter do something, build up the *while* loop in the `io_filter.c` source code. The goal is to modify the characters’ input before sending them to output. (Otherwise: plumping.)

[](/book/tiny-c-projects/chapter-4/)As an example, you could modify the input so that all vowels are detected and replaced with an asterisk character. This modification takes place within the while loop, as it processes the input stream. Here is one way to accomplish this task:

```
while( (ch = getchar()) != EOF)
{
   switch(ch)
   {
       case 'a':
       case 'A':
       case 'e':
       case 'E':
       case 'i':
       case 'I':
       case 'o':
       case 'O':
       case 'u':
       case 'U':
           putchar('*');
           break;
       default:
           putchar(ch);
   }
}
```

[](/book/tiny-c-projects/chapter-4/)The full source code for this modification is available in this book’s GitHub repository as `censored.c`. Here’s a sample run:

```
hello
h*ll*
```

#### [](/book/tiny-c-projects/chapter-4/)Exercise 4.1

[](/book/tiny-c-projects/chapter-4/)Now that you have the basic filter skeleton in `io_filter.c`, you can perform your own modifications, testing your filter programming skills. Here is such a challenge you can code on your own: write a filter that converts lowercase characters to uppercase. The effect of such a filter is to generate output in ALL CAPS. My solution to this exercise is found in this book’s GitHub repository as `allcaps.c`.

#### [](/book/tiny-c-projects/chapter-4/)Exercise 4.2

[](/book/tiny-c-projects/chapter-4/)Write a filter that randomizes character text, modifying standard input to generate output in either upper- or lowercase, regardless of the original character’s case. I have included my potential solution to this exercise in this book’s GitHub repository as [](/book/tiny-c-projects/chapter-4/)[](/book/tiny-c-projects/chapter-4/)`ransom.c`.

### [](/book/tiny-c-projects/chapter-4/)4.1.3 Working a filter at the command prompt

[](/book/tiny-c-projects/chapter-4/)You [](/book/tiny-c-projects/chapter-4/)[](/book/tiny-c-projects/chapter-4/)can’t test a filter from within an IDE, so banish yourself to the command prompt if you haven’t already. The I/O redirection tools you need are shown in table 4.1. These single-character commands modify the stream, altering the flow of input or output—or both!

##### [](/book/tiny-c-projects/chapter-4/)Table 4.1 I/O redirection characters and their functions[(view table figure)](https://drek4537l1klr.cloudfront.net/gookin/HighResolutionFigures/table_4-1.png)

| [](/book/tiny-c-projects/chapter-4/)Character | [](/book/tiny-c-projects/chapter-4/)Name | [](/book/tiny-c-projects/chapter-4/)What it does |
| --- | --- | --- |
| [](/book/tiny-c-projects/chapter-4/)> | [](/book/tiny-c-projects/chapter-4/)Greater than | [](/book/tiny-c-projects/chapter-4/)Redirects output (not really used for filters) |
| [](/book/tiny-c-projects/chapter-4/)< | [](/book/tiny-c-projects/chapter-4/)Less than | [](/book/tiny-c-projects/chapter-4/)Redirects input |
| [](/book/tiny-c-projects/chapter-4/)\| | [](/book/tiny-c-projects/chapter-4/)Pipe | [](/book/tiny-c-projects/chapter-4/)Sends output through another program |

[](/book/tiny-c-projects/chapter-4/)Assume that you’ve completed exercise 4.2, where you create a filter to randomize character text. This filter program is named `hostage`. To use this filter, you must specify the program’s full pathname. For the following commands, it’s assumed that the filter is stored in the same directory where the command is typed; the `./` prefix directs the operating system to find the program in the current directory:

```
echo "Give me all your money" | ./hostage
```

[](/book/tiny-c-projects/chapter-4/)The *echo* command[](/book/tiny-c-projects/chapter-4/) sends a string of text to standard output. However, the pipe character intercepts standard output, sending it away from the standard output device (the terminal window). Instead, the *echo* command’s output is provided as input to the named program, `ransom`[](/book/tiny-c-projects/chapter-4/). The result is that the filter processes the string of text as its input:

```
gIvE ME AlL yoUR mONey
```

[](/book/tiny-c-projects/chapter-4/)Another way to churn text through a filter is to use input redirection. In this configuration, the filter program name comes first. It’s followed by the input redirection character, `<` (less than), and the source of input, such as a text file:

```
./hostage < file.txt
```

[](/book/tiny-c-projects/chapter-4/)Above, the contents of `file.txt` are redirected as input for the `hostage` program[](/book/tiny-c-projects/chapter-4/), which outputs the file’s text using random upper- and lowercase letters.

[](/book/tiny-c-projects/chapter-4/)The output redirection character doesn’t really play a role with a filter. Instead, it takes a program’s output and sends it to a file or a device: The program (or construction’s) output supplies text for the file. If the file exists, it’s overwritten. Otherwise, a new file is created:

```
echo “Give me all your money” | ./hostage > ransom_note.txt
```

[](/book/tiny-c-projects/chapter-4/)Above, the *echo* command’s text is processed through the `hostage` filter[](/book/tiny-c-projects/chapter-4/). The output would normally go to the standard output device, but instead it’s redirected and saved into the file `ransom_note.txt`.

[](/book/tiny-c-projects/chapter-4/)Remember that output redirection doesn’t supply input for a filter. Use the pipe to send output from one program (or some other source) into [](/book/tiny-c-projects/chapter-4/)[](/book/tiny-c-projects/chapter-4/)the [](/book/tiny-c-projects/chapter-4/)[](/book/tiny-c-projects/chapter-4/)filter.

## [](/book/tiny-c-projects/chapter-4/)[](/book/tiny-c-projects/chapter-4/)4.2 On the front lines with Caesar

[](/book/tiny-c-projects/chapter-4/)Julius Caesar didn’t invent the cipher that’s been given his name. The technique is old but effective with a mostly illiterate population: Caesar could send an encrypted letter and—should it fall into enemy hands—the bad guys would be clueless. Silly Belgae. Yet once received by the right person, the text was instantly deciphered and pity poor Gaul again.

[](/book/tiny-c-projects/chapter-4/)Figure 4.4 illustrates how the cipher works, which is a simple letter shift. It’s based upon a starting pair, such as A to D, shown in the figure. This relationship continues throughout the alphabet, shifting letters based on the initial pair: A to D, B to E, C to F, and so on.

![Figure 4.4 The Caesarean cipher is based upon a letter shift.](https://drek4537l1klr.cloudfront.net/gookin/Figures/04-04.png)

[](/book/tiny-c-projects/chapter-4/)When you know the initial pair of the cipher, the message is easily decoded. In fact, you may have used this type of cipher if you have ever obtained a secret decoder ring: the initial pair is given and then rest of the message is encoded or decoded, letter by letter:

[](/book/tiny-c-projects/chapter-4/)*EH VXUH WR GULQN BRXU RYDOWLQH.*

[](/book/tiny-c-projects/chapter-4/)Surprisingly, the Caesarean cipher, also called a substitution cipher, is still used today. It’s admittedly weak, but don’t tell the neighbors. The *rot13* filter[](/book/tiny-c-projects/chapter-4/) is perhaps the most common, which you can read about in the next section. Still, it’s a fun filter to program, and it has its place in the realm of encryption techniques.

### [](/book/tiny-c-projects/chapter-4/)[](/book/tiny-c-projects/chapter-4/)4.2.1 Rotating 13 characters

[](/book/tiny-c-projects/chapter-4/)The [](/book/tiny-c-projects/chapter-4/)[](/book/tiny-c-projects/chapter-4/)most common Caesarean cipher known to Unix mavens is the *rot13* filter[](/book/tiny-c-projects/chapter-4/). Please say “rote 13” and not “rot 13.” Thank you.

[](/book/tiny-c-projects/chapter-4/)The *rot13* program works as a filter. If it’s not included with your Linux distro, use your package manager to locate it as well as other ancient and nifty command-line tools.

[](/book/tiny-c-projects/chapter-4/)The name *rot13* comes from the character substitution pattern: the Latin alphabet (and ASCII) holds 26 characters, A to Z. If you perform an A-to-N character substitution, the upper half of the alphabet is swapped with the lower, as illustrated in figure 4.5. The program “rotates 13” characters. The beauty of this translation is that running that *rot13* filter[](/book/tiny-c-projects/chapter-4/) twice restores text to the original. This way, the same filter is used to both encrypt and decrypt messages.

![Figure 4.5 The rot13 filter swaps the upper half of the alphabet with the lower half, effectively “rotating” the characters by 13 positions.](https://drek4537l1klr.cloudfront.net/gookin/Figures/04-05.png)

[](/book/tiny-c-projects/chapter-4/)Back on the old ARPANET, as well as on early internet, *rot13* was used as a filter in messaging services to hide spoilers, punchlines, and other information people may not want to read right away. Figure 4.6 shows a run of the *rot13* filter[](/book/tiny-c-projects/chapter-4/) on a message. In the original text, the joke appears in standard text with the punchline concealed. After applying the *rot13* filter[](/book/tiny-c-projects/chapter-4/), the joke text is concealed but the punchline is revealed, for a hearty har-har.

![Figure 4.6 The effect of applying the rot13 filter to text, scrambled and unscrambled](https://drek4537l1klr.cloudfront.net/gookin/Figures/04-06.png)

[](/book/tiny-c-projects/chapter-4/)This type of Caesarean cipher is easy to code, because you either add or subtract 13 from a given character’s ASCII value, depending on where the character squats in the alphabet: upper or lower half. The addition or subtraction operation works for both upper- and lowercase letters.

[](/book/tiny-c-projects/chapter-4/)In listing 4.4, the code for `caesar01.c` uses the isalpha() function[](/book/tiny-c-projects/chapter-4/) to weed out letters of the alphabet. The *toupper()* function[](/book/tiny-c-projects/chapter-4/) converts the letters to uppercase so that it can test for characters in the range from A through M. If so, these characters are shifted up 13 places: `ch+=` `13`. Otherwise, the else statement[](/book/tiny-c-projects/chapter-4/) catches the higher letters of the alphabet, shifting them down.

##### Listing 4.4 caesar01.c

```
#include <stdio.h>
#include <ctype.h>
 
int main()
{
    int ch;
 
    while( (ch = getchar()) != EOF)
    {
        if( isalpha(ch))                                 #1
        {
            if( toupper(ch)>='A' && toupper(ch)<='M')    #2
                ch+= 13;                                 #3
            else
                ch-= 13;                                 #4
        }
        putchar(ch);
    }
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-4/)As with all filters, you can employ I/O redirection commands (characters) to see it in action at the command prompt. Refer to section 4.1.3 for the specifics. If the program for the `caesar01.c` source code is named `caesar01`, here’s a sample run:

```bash
$ echo "Hail, Caesar!" | ./caesar01
Unvy, Pnrfne!
```

[](/book/tiny-c-projects/chapter-4/)When the program is run directly, it processes the text you type as standard input:

```bash
$ ./caesar01
Unvy, Pnrfne!
Hail, Caesar!
```

[](/book/tiny-c-projects/chapter-4/)Because the *rot13* filter[](/book/tiny-c-projects/chapter-4/) decodes and encodes the same text, you can put the program to the test by running text through it twice. In the command-line construction below, text is echoed through the program once and then again. The result is the original text, thanks to the magic of the *rot13* process:

```bash
$ echo "Hail, Caesar!" | ./caesar01 | ./caesar01
Hail, Caesar!
```

[](/book/tiny-c-projects/chapter-4/)Remember that the *rot13* filter[](/book/tiny-c-projects/chapter-4/) isn’t designed to keep information completely secure. Still, it provides a handy and common way to keep something concealed but not necessarily encrypted beyond [](/book/tiny-c-projects/chapter-4/)[](/book/tiny-c-projects/chapter-4/)reach:

[](/book/tiny-c-projects/chapter-4/)*Why did Caesar cross the Rubicon?*

[](/book/tiny-c-projects/chapter-4/)*Gb trg gb gur bgure fvqr.*

### [](/book/tiny-c-projects/chapter-4/)4.2.2 Devising a more Caesarean cipher

[](/book/tiny-c-projects/chapter-4/)Caesar [](/book/tiny-c-projects/chapter-4/)didn’t use the *rot13* filter to encrypt his messages, mostly because he never upgraded to Linux from his trusty Commodore 64. No, he preferred the A-to-D shift. Sometimes it was just an A-to-B shift. Regardless, coding such a beast is a bit more involved than the convenient 13-character shift of the *rot13* filter.

[](/book/tiny-c-projects/chapter-4/)Properly transposing letters based on a value other than 13 means the letters will wrap. For example, an A-to-D translation means that Z would wrap to some character Z+3 in the ASCII table. Therefore, to keep the translation going, the letter shift must wrap from Z back to C (refer to figure 4.4). You must account for such wrapping in your code, confirming that characters are contained within the 26-letter change of the alphabet—both upper- and lowercase.

[](/book/tiny-c-projects/chapter-4/)To account for such wrapping, specifically with an A-to-D translation, your code must construct a complex *if* condition using logical comparisons to account for characters that shift out of range. Figure 4.7 illustrates how such an expression works. It tests for values greater than `'Z'` and less than `'a'`, but also greater than `'z'`. This arrangement exists due to how characters are encoded with the ASCII standard. (See chapter 5 for more details on ASCII.)

![Figure 4.7 Detecting overflow characters when performing an A-to-D shift](https://drek4537l1klr.cloudfront.net/gookin/Figures/04-07.png)

[](/book/tiny-c-projects/chapter-4/)When a character is detected as out of range by the *if* statement, its value must be reduced by 26, wrapping it back to `'A'` or `'a'`, depending on the letter’s original case.

[](/book/tiny-c-projects/chapter-4/)Due to the proximity of uppercase `'Z'` to lowercase `'a'`, this *if* statement test works because this particular shift is only three characters. From figure 4.7, you see that the ASCII table sets only six characters between uppercase Z and lowercase a. For larger character shifts, more complex testing must be performed.

[](/book/tiny-c-projects/chapter-4/)Listing 4.5 shows how the A-to-D character shift cipher is coded, complete with the complex *if* statement that wraps overflow characters. Otherwise, the character is shifted by the value of variable `shift`[](/book/tiny-c-projects/chapter-4/), calculated as `'D'` `-` `'A'`. This shift is expressed backward to properly calculate as three. Therefore, three is added to each alphabetic character in the code—unless the character is out of range.

##### Listing 4.5 caesar02.c

```
#include <stdio.h>
#include <ctype.h>
 
int main()
{
    int shift,ch;
 
    shift = 'D' - 'A';                           #1
 
    while( (ch = getchar()) != EOF)
    {
        if( isalpha(ch))                         #2
        {
            ch+=shift;                           #3
            if( (ch>'Z' && ch<'a') || ch>'z')    #4
                 ch-= 26;                        #5
        }
        putchar(ch);
    }
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-4/)Here is a sample run:

```
Now is the time for all good men...
Qrz lv wkh wlph iru doo jrrg phq...
```

[](/book/tiny-c-projects/chapter-4/)Unlike with a *rot13* filter, you can’t run the same program twice to decode the A-to-D shift. Instead, to decode the message, you must shift from D back to A. Two changes are required to make this change. In the code shown in listing 4.5, first alter the shift calculation:

```
shift = 'A' - 'D';
```

[](/book/tiny-c-projects/chapter-4/)Second, the out-of-bounds testing must check the underside of the alphabet, so see whether a character’s value has dipped below `'A'` or `'a'`:

```
if( ch<'A' || (ch>'Z' && ch<'a'))
   ch+= 26;
```

[](/book/tiny-c-projects/chapter-4/)If the character wraps on the underside of the alphabet, its value is increased by 26, which wraps it back up to the Z end, correcting the overflow.

[](/book/tiny-c-projects/chapter-4/)The final program is available as `caesar03.c` in this book’s GitHub repository. Here is a sample run:

```
Now is the time for all good men
Klt fp qeb qfjb clo xii dlla jbk
Qrz lv wkh wlph iru doo jrrg phq...
Now is the time for all good men...
```

[](/book/tiny-c-projects/chapter-4/)The first two lines show the D-to-A shift of normal text, how the filter encodes plain text. The second two lines show how the D-to-A shift decrypts the original A-to-D shift of the `caesar02.c` code. (Refer to the output shown earlier.)

[](/book/tiny-c-projects/chapter-4/)As with any filter, you can pipe output through both filters to recover the original text:

```bash
$ echo "Hail, Caesar!" | ./caesar02 | ./caesar03
Hail, Caesar!
```

[](/book/tiny-c-projects/chapter-4/)Of course, the best way to code a more Caesarean cipher is to let the user determine which letters to shift. To make this filter work, command-line arguments are required; filters are not interactive, so the user isn’t given the opportunity to provide input otherwise.

[](/book/tiny-c-projects/chapter-4/)The command-line arguments provide the two letters for the shift, from argument 1 to argument 2. The code then works out the process, performing the shift on whatever text is flung into standard input.

[](/book/tiny-c-projects/chapter-4/)Letting the user decide options is always good. Providing this feature means that the bulk of the code is used to interpret the command-line options: you must check to see whether the options are present and then confirm that both are letters of the alphabet. Such code is available in the GitHub repository as `caesar04.c`. The extra step of checking for two command-line arguments in this source code file consumes 16 lines of code.

[](/book/tiny-c-projects/chapter-4/)Once the two shifting characters are set, they’re saved in *char* variables `a` and `b`. A *while* loop then processes the text based on the shift value of the two characters supplied. Because the shift can be up or down, and to best check for out-of-range values, the loop must separate upper- and lowercase characters. This approach is best to detect shift overflow and deal with it properly. The program’s core *while* loop and the various tests from my `caesar04.c` program are shown in the next listing.

##### Listing 4.6 The *while* loop in caesar04.c that performs the character shift

```
while( (ch = getchar()) != EOF)
{
    if( isupper(ch) )            #1
    {
        ch+= shift;
        if( ch>'Z' ) ch-=26;     #2
        if( ch<'A' ) ch+=26;     #2
        putchar(ch);
    }
    else if( islower(ch) )
    {
        ch+= shift;
        if( ch>'z' ) ch-=26;     #2
        if( ch<'a' ) ch+=26;     #2
        putchar(ch);
    }
    else
    {
        putchar(ch);
    }
}
```

[](/book/tiny-c-projects/chapter-4/)Here is a sample run of the *caesar04* program with an A-to-R shift:

```bash
$ ./caesar04 A R
This is a test
Kyzj zj r kvjk
```

[](/book/tiny-c-projects/chapter-4/)And to reverse, the R-to-A shift is specified as command line arguments:

```bash
$ ./caesar04 R A
Kyzj zj r kvjk
This is a test
```

[](/book/tiny-c-projects/chapter-4/)As an improvement, it might be better to have a single argument that specifies the character shift, such as **RA** instead of the separate R and A just shown. Then again, as with most programmers, messing with code is an eternal process. I leave this task up [](/book/tiny-c-projects/chapter-4/)to you.

## [](/book/tiny-c-projects/chapter-4/)4.3 Deep into filter madness

[](/book/tiny-c-projects/chapter-4/)I’ve created a slew of filters over my programming career. It’s amazing to think of the fun things you can accomplish. Well, fun for nerds. Non-nerds are reading a romance novel right now. Let me spoil it: his work is more important to him than she is. There. Saved you 180 dreary pages.

[](/book/tiny-c-projects/chapter-4/)Regardless of what a filter does, the method for composing a filter is always the same: read standard input, modify it, and then generate standard output.

[](/book/tiny-c-projects/chapter-4/)Before the chapter closes (and I must hurry because my work is important), I offer a few different filter ideas to help churn your creative juices. The possibilities are endless.

### [](/book/tiny-c-projects/chapter-4/)4.3.1 Building the hex output filter

[](/book/tiny-c-projects/chapter-4/)Just [](/book/tiny-c-projects/chapter-4/)[](/book/tiny-c-projects/chapter-4/)because one character flows into a filter doesn’t mean another character must always flow out. Some filters may spew out several characters of output for each character input. Other filters may not output any modification of text, such as the *more* filter[](/book/tiny-c-projects/chapter-4/).

[](/book/tiny-c-projects/chapter-4/)The *more* filter[](/book/tiny-c-projects/chapter-4/) is a handy text-reading utility. It’s used to page output. Shoving output through the *more* filter[](/book/tiny-c-projects/chapter-4/) prompts for input after each screen of text:

```
cat long.txt | more
```

[](/book/tiny-c-projects/chapter-4/)Above, the contents of file `long.txt` are output via the *cat* command. The *more* filter[](/book/tiny-c-projects/chapter-4/) pauses the display after every screenful of text. This filter was popular enough in Unix that Microsoft “borrowed” it for inclusion with its text-mode operating system, MS-DOS.

[](/book/tiny-c-projects/chapter-4/)For a filter that generates more output than input, consider the following listing. The code accepts standard input and outputs the hex values for each character. The *printf()* statement[](/book/tiny-c-projects/chapter-4/) generates two-digit hex values.

##### Listing 4.7 hexfilter01.c

```
#include <stdio.h>
 
int main()
{
    int ch;
 
    while( (ch=getchar()) != EOF )
    {
        printf("%02X ",ch);    #1
    }
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-4/)The code for `hexfilter01.c` works well, but it does have a problem with its output: the two-digit character format appears as a long string of text. Often a text value is split between two lines. A better approach would be to monitor output to avoid splitting a hex value at the end of a line.

#### [](/book/tiny-c-projects/chapter-4/)Exercise 4.3

[](/book/tiny-c-projects/chapter-4/)Assuming that the terminal screen is 80 characters wide, modify the code to `hexfilter01.c` so that output doesn’t split a hex value between two lines. Further, when a newline character is encountered, have the line of output terminated with a newline. My solution for this exercise can be found in the GitHub repository as `hexfilter02.c`. Please try this exercise on your own before you peek at my [](/book/tiny-c-projects/chapter-4/)[](/book/tiny-c-projects/chapter-4/)solution.

### [](/book/tiny-c-projects/chapter-4/)4.3.2 Creating a NATO filter

[](/book/tiny-c-projects/chapter-4/)Chapter 3 [](/book/tiny-c-projects/chapter-4/)[](/book/tiny-c-projects/chapter-4/)covered the NATO phonetic alphabet, which—surprise—can also be applied as a filter. For example, the filter reads standard input, plucking out all the alphabetic characters. For each one, the filter outputs the corresponding NATO term. This program is another example of a filter that does more than a single-character exchange.

[](/book/tiny-c-projects/chapter-4/)To make the phonetic alphabet translation, the code must borrow the `nato[]` array[](/book/tiny-c-projects/chapter-4/) of terms presented in chapter 3. This array is shown in listing 4.8. It’s coupled with the standard I/O filter *while* loop. In the loop, the *isalpha()* function[](/book/tiny-c-projects/chapter-4/) detects alphabetic characters. Some math is performed to obtain the proper term offset in the array, which outputs the correct term for each letter processed.

##### Listing 4.8 nato01.c

```
#include <stdio.h>
#include <ctype.h>
 
int main()
{
    char *nato[] = {
        "Alfa", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot",
        "Golf", "Hotel", "India", "Juliett", "Kilo", "Lima",
        "Mike", "November", "Oscar", "Papa", "Quebec", "Romeo",
        "Sierra", "Tango", "Uniform", "Victor", "Whiskey",
        "Xray", "Yankee", "Zulu"
    };
    char ch;
 
    while( (ch=getchar()) != EOF)
    {
        if(isalpha(ch))
            printf("%s ",nato[toupper(ch)-'A']);   #1
        if( ch=='\n' )                             #2
            putchar(ch);
    }
    putchar('\n');
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-4/)Here’s a sample run:

```bash
$ ./nato
hello
Hotel Echo Lima Lima Oscar
```

[](/book/tiny-c-projects/chapter-4/)It’s important to know that any nonalphabetic characters (aside from newline) are ignored by this filter. Ignoring input in a filter is legitimate; a filter need not generate one-to-one output based on [](/book/tiny-c-projects/chapter-4/)[](/book/tiny-c-projects/chapter-4/)input.

### [](/book/tiny-c-projects/chapter-4/)4.3.3 Filtering words

[](/book/tiny-c-projects/chapter-4/)Filters [](/book/tiny-c-projects/chapter-4/)operate on character I/O, but this limitation doesn’t restrict a filter from affecting words, sentences, or other chunks of text. The key is to store input as it arrives. Once the proper text chunks are assembled, such as a word or sentence, the filter can process it.

[](/book/tiny-c-projects/chapter-4/)For example, to slice standard input by word, you write a filter that collects characters until a word boundary—a space, comma, tab, or period, for example—is encountered. The input must be stored, so further testing must be done to ensure that the storage doesn’t overflow. Once the buffer contains a word (or whatever size text chunk you need), it can be sent to standard output or manipulated in whatever way the filter needs to massage the data.

[](/book/tiny-c-projects/chapter-4/)In listing 4.9, a 64-character buffer `word[]`[](/book/tiny-c-projects/chapter-4/) stores words. The *while* loop is split into *if-else* conditions[](/book/tiny-c-projects/chapter-4/). The *if* test marks the end of a word, capping the `word[]` buffer with a null character, confirming that a full word is ready to output, and then outputting the word. The *else* test builds the word, ensuring that the buffer doesn’t overflow. The result is a filter that pulls out words and sets each one on a line by itself.

##### Listing 4.9 word_filter.c

```
#include <stdio.h>
#include <ctype.h>
 
#define WORDSIZE 64                        #1
 
int main()
{
    char word[WORDSIZE];
    int ch,offset;
 
    offset = 0;                            #2
    while( (ch = getchar()) != EOF)
    {
        if( isspace(ch) )                  #3
        {
            word[offset] = '\0';           #4
            if( offset>0 )                 #5
                printf("%s\n",word);       #6
            offset = 0;                    #7
        }
        else                               #8
        {
            word[offset] = ch;             #9
            offset++;                      #10
            if( offset==WORDSIZE-1 )       #11
            {
                word[offset] = '\0';       #12
                printf("%s\n",word);       #13
                offset = 0;                #14
            }
        }
    }
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-4/)To build words, the code in `word_filter.c` replies upon the *isspace()* function[](/book/tiny-c-projects/chapter-4/), defined in the `ctype.h` header file. This function returns TRUE when a whitespace character is encountered on input. These characters include space, tab, and newline. These whitespace characters trigger a word boundary, though the code could be modified to account for other characters as well.

[](/book/tiny-c-projects/chapter-4/)Here’s a sample run:

```bash
$ ./word_filter
Is this still the Caesarean Cipher chapter?
Is
this
still
the
Caesarean
Cipher
chapter?
```

[](/book/tiny-c-projects/chapter-4/)Twice in the code you see statements that cap the `word[]` buffer[](/book/tiny-c-projects/chapter-4/) with a null character:

```
word[offset] = '\0';
```

[](/book/tiny-c-projects/chapter-4/)It’s vital that all strings in C end with the null character, `\0`. Especially when you build your own strings, as is done in the `word_filter.c` code, confirm that the string that’s created is capped. If not, you get an overflow and all kinds of ugly output—and potential [](/book/tiny-c-projects/chapter-4/)bad things [](/book/tiny-c-projects/chapter-4/)happening.
