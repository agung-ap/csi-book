# [](/book/tiny-c-projects/chapter-8/)8 Unicode and wide characters

[](/book/tiny-c-projects/chapter-8/)In the [](/book/tiny-c-projects/chapter-8/)beginning was Morse code, a simple method of translating electrical pulses—long and short—into a string of characters and readable text. Morse wasn’t the first electronic encoding method, but it’s perhaps the best known. Developed in 1840, it’s named after Samuel Morse, who helped invent the telegraph and who also bears an uncanny resemblance to *Lost in Space*’s Dr. Smith.

[](/book/tiny-c-projects/chapter-8/)Some 30 years after Morse code came the Baudot code. Also used in telegraph communications, *Baudot*[](/book/tiny-c-projects/chapter-8/) (baw-DOH) represents letters of the alphabet using a 5-bit sequence. This code was later modified into Murray code for use on teletype machines with keyboards, as well as early computers. Then came IBM’s Binary Coded Decimal (BCD[](/book/tiny-c-projects/chapter-8/)) for use on their mainframe computers. Eventually, the ASCII encoding standard ruled the computer roost until Unicode solved everyone’s text encoding problems in the late 20th century.

[](/book/tiny-c-projects/chapter-8/)This chapter’s topic is character encoding, the art of taking an alphabet soup of characters and assigning them a code value for digital representation in a computer. The culmination of this effort is Unicode, which slaps a value to almost every imaginable written scribble in the history of mankind. To help explore Unicode in the C language, in this chapter you will:

-  [](/book/tiny-c-projects/chapter-8/)Review various computer encoding systems
-  [](/book/tiny-c-projects/chapter-8/)Study ASCII text, code pages, and Unicode
-  [](/book/tiny-c-projects/chapter-8/)Set the locale details for your programs
-  [](/book/tiny-c-projects/chapter-8/)Understand different character types, such as UTF-8
-  [](/book/tiny-c-projects/chapter-8/)Work with wide characters and strings
-  [](/book/tiny-c-projects/chapter-8/)Perform wide character file I/O

[](/book/tiny-c-projects/chapter-8/)I really don’t see any new text-encoding format taking over from Unicode. It’s a solid system, with new characters assigned every year. Its only limitation seems to be its spotty implementation in various typefaces. Therefore, although you can program Unicode in a Linux terminal window, text output may not appear accurately. To best resolve this issue, ensure that your terminal program window lets you change fonts so that you can witness the interesting, weird, and impressive text Unicode can produce.

[](/book/tiny-c-projects/chapter-8/)Computers [](/book/tiny-c-projects/chapter-8/)[](/book/tiny-c-projects/chapter-8/)understand numbers, bits organized into bytes dwelling in memory, manipulated by the processor, and stored long-term on media. The system really doesn’t care about text, and it’s totally ignorant of spelling. Still, to communicate with humans, many of these byte values correspond to printed characters. It’s the consistency of this character encoding that allows computers to communicate with humans and exchange information, despite their innate reluctance to do so.

### [](/book/tiny-c-projects/chapter-8/)8.1.1 Reviewing early text formats

[](/book/tiny-c-projects/chapter-8/)The [](/book/tiny-c-projects/chapter-8/)[](/book/tiny-c-projects/chapter-8/)only time you hear about Morse code these days is in the movies. Something important must happen, and communications takes place only via tapping on a pipe or something equally desperate and silly. One of the characters responds with the cliché that their knowledge of Morse code is “rusty,” but the message is decoded, the audience impressed, and the day saved.

[](/book/tiny-c-projects/chapter-8/)Morse code is composed of a series of dashes and dots, long or short pulses, to encode letters and numbers. No distinction is necessary between upper- and lowercase. Some common codes are known among nerds, such as S-O-S, though I can’t readily remember which triplex series of dots and dashes belongs to the S or O. I suppose I can look at table 8.1 to determine which is which.

##### [](/book/tiny-c-projects/chapter-8/)Table 8.1 Morse code[(view table figure)](https://drek4537l1klr.cloudfront.net/gookin/HighResolutionFigures/table_8-1.png)

| [](/book/tiny-c-projects/chapter-8/)Character | [](/book/tiny-c-projects/chapter-8/)Code | [](/book/tiny-c-projects/chapter-8/)Character | [](/book/tiny-c-projects/chapter-8/)Code | [](/book/tiny-c-projects/chapter-8/)Character | [](/book/tiny-c-projects/chapter-8/)Code |
| --- | --- | --- | --- | --- | --- |
| [](/book/tiny-c-projects/chapter-8/)A | [](/book/tiny-c-projects/chapter-8/).- | [](/book/tiny-c-projects/chapter-8/)M | [](/book/tiny-c-projects/chapter-8/)-- | [](/book/tiny-c-projects/chapter-8/)Y | [](/book/tiny-c-projects/chapter-8/)-.-- |
| [](/book/tiny-c-projects/chapter-8/)B | [](/book/tiny-c-projects/chapter-8/)-... | [](/book/tiny-c-projects/chapter-8/)N | [](/book/tiny-c-projects/chapter-8/)-. | [](/book/tiny-c-projects/chapter-8/)Z | [](/book/tiny-c-projects/chapter-8/)--.. |
| [](/book/tiny-c-projects/chapter-8/)C | [](/book/tiny-c-projects/chapter-8/)-.-. | [](/book/tiny-c-projects/chapter-8/)O | [](/book/tiny-c-projects/chapter-8/)--- | [](/book/tiny-c-projects/chapter-8/)1 | [](/book/tiny-c-projects/chapter-8/).----- |
| [](/book/tiny-c-projects/chapter-8/)D | [](/book/tiny-c-projects/chapter-8/)-.. | [](/book/tiny-c-projects/chapter-8/)P | [](/book/tiny-c-projects/chapter-8/).--. | [](/book/tiny-c-projects/chapter-8/)2 | [](/book/tiny-c-projects/chapter-8/)..--- |
| [](/book/tiny-c-projects/chapter-8/)E | [](/book/tiny-c-projects/chapter-8/). | [](/book/tiny-c-projects/chapter-8/)Q | [](/book/tiny-c-projects/chapter-8/)--.- | [](/book/tiny-c-projects/chapter-8/)3 | [](/book/tiny-c-projects/chapter-8/)...-- |
| [](/book/tiny-c-projects/chapter-8/)F | [](/book/tiny-c-projects/chapter-8/)..-. | [](/book/tiny-c-projects/chapter-8/)R | [](/book/tiny-c-projects/chapter-8/).-. | [](/book/tiny-c-projects/chapter-8/)4 | [](/book/tiny-c-projects/chapter-8/)....- |
| [](/book/tiny-c-projects/chapter-8/)G | [](/book/tiny-c-projects/chapter-8/)--. | [](/book/tiny-c-projects/chapter-8/)S | [](/book/tiny-c-projects/chapter-8/)... | [](/book/tiny-c-projects/chapter-8/)5 | [](/book/tiny-c-projects/chapter-8/)..... |
| [](/book/tiny-c-projects/chapter-8/)H | [](/book/tiny-c-projects/chapter-8/).... | [](/book/tiny-c-projects/chapter-8/)T | [](/book/tiny-c-projects/chapter-8/)- | [](/book/tiny-c-projects/chapter-8/)6 | [](/book/tiny-c-projects/chapter-8/)-.... |
| [](/book/tiny-c-projects/chapter-8/)I | [](/book/tiny-c-projects/chapter-8/).. | [](/book/tiny-c-projects/chapter-8/)U | [](/book/tiny-c-projects/chapter-8/)..- | [](/book/tiny-c-projects/chapter-8/)7 | [](/book/tiny-c-projects/chapter-8/)--... |
| [](/book/tiny-c-projects/chapter-8/)J | [](/book/tiny-c-projects/chapter-8/).--- | [](/book/tiny-c-projects/chapter-8/)V | [](/book/tiny-c-projects/chapter-8/)...- | [](/book/tiny-c-projects/chapter-8/)8 | [](/book/tiny-c-projects/chapter-8/)---.. |
| [](/book/tiny-c-projects/chapter-8/)K | [](/book/tiny-c-projects/chapter-8/)-.- | [](/book/tiny-c-projects/chapter-8/)W | [](/book/tiny-c-projects/chapter-8/).-- | [](/book/tiny-c-projects/chapter-8/)9 | [](/book/tiny-c-projects/chapter-8/)----. |
| [](/book/tiny-c-projects/chapter-8/)L | [](/book/tiny-c-projects/chapter-8/).-.. | [](/book/tiny-c-projects/chapter-8/)X | [](/book/tiny-c-projects/chapter-8/)-..- | [](/book/tiny-c-projects/chapter-8/)0 | [](/book/tiny-c-projects/chapter-8/)----- |

[](/book/tiny-c-projects/chapter-8/)I’ll avoid getting into the weeds with technical details about the length of a dash or dot and spaces and such. Though, one nerdy point I can bring up is that the encoding is designed so that frequently used letters have fewer units, such as E, T, I, A, N, and so on.

[](/book/tiny-c-projects/chapter-8/)The next listing shows the *toMorse()* function[](/book/tiny-c-projects/chapter-8/), which outputs a Morse code character string based on an input character. The character strings are stored in two *const char* arrays[](/book/tiny-c-projects/chapter-8/), matching the sequences A to Z for `morse_alpha[]` and 0 to 9 for `morse_digit[]`. An *if-else* structure[](/book/tiny-c-projects/chapter-8/) uses ctype functions to pull out alpha and numeric characters; all other characters are ignored.

##### Listing 8.1 The *toMorse()* function

```
void toMorse(char c)
{
    const char *morse_alpha[] = {                    #1
        ".-", "-...", "-.-.", "-..", ".", "..-.",
        "--.", "....", "..", ".---", "-.-", ".-..",
        "--", "-.", "---", ".--.", "--.-", ".-.",
        "...", "-", "..-", "...-", ".--", "-..-",
        "-.--", "--.."
    };
    const char *morse_digit[] = {                    #1
        "-----", ".----", "..---", "...--", "....-",
        ".....", "-....", "--...", "---..", "----."
    };
 
    if( isalpha(c) )                                 #2
    {
        c = toupper(c);                              #3
        printf("%s ",morse_alpha[c-'A']);            #4
    }
    else if( isdigit(c) )                            #5
    {
        printf("%s ",morse_digit[c-'0']);            #6
    }
    else if( c==' ' || c=='\n' )                     #7
    {
        putchar('\n');
    }
    else                                             #8
        return;
}
```

[](/book/tiny-c-projects/chapter-8/)The *toMorse()* function[](/book/tiny-c-projects/chapter-8/) is easily set into a filter, which translates text input into Morse code strings for output. Such a filter is found in the source code file `morse_code_` `filter.c`, available in this book’s online repository.

[](/book/tiny-c-projects/chapter-8/)Another text encoding scheme is Baudot. This term may be strange to you—unless you’re an old timer who once referred to your dial-up modem’s speed in “baud.” A 300-baud modem crept along at 300 characters per second. Because baud isn’t exactly a representation of characters per second, faster modems (and today’s broadband) are measured in bits per second (BPS) and not baud.

[](/book/tiny-c-projects/chapter-8/)Anyway.

[](/book/tiny-c-projects/chapter-8/)The Baudot scheme encodes text in 5-bit chunks. This code was adapted by engineer and inventor Donald Murray into Murray code for use on teletype machines. These machines featured a QWERTY keyboard and were often used as input devices for early computer systems. Specifically, Murray developed paper tape to store and read keystrokes. Holes punched in the paper tape represented characters, as illustrated in figure 8.1.

![Figure 8.1 Paper tape with holes punched representing Baudot-Murray code](https://drek4537l1klr.cloudfront.net/gookin/Figures/08-01.png)

[](/book/tiny-c-projects/chapter-8/)The International Telegraph Alphabet No. 2 (ITA2[](/book/tiny-c-projects/chapter-8/)[](/book/tiny-c-projects/chapter-8/)) standard for Baudot-Murray code was introduced in 1928. In the United States, the standard is named US-TTY (TTY for teletype). Because it’s 5 bits wide, not enough values are available to handle the full character set. Therefore, the code requires a shift character to switch between the alpha and symbol sets.

[](/book/tiny-c-projects/chapter-8/)Table 8.2 lists the Baudot-Murray hexadecimal codes for alphanumeric characters, the letter set. The code 0x1B switches to the figure set characters, shown in table 8.3. Code 0x1B or code 0x1F switches back.

##### [](/book/tiny-c-projects/chapter-8/)Table 8.2 Baudot-Murray codes for ITA2 and US-TTY, letter set[(view table figure)](https://drek4537l1klr.cloudfront.net/gookin/HighResolutionFigures/table_8-2.png)

| [](/book/tiny-c-projects/chapter-8/)Code | [](/book/tiny-c-projects/chapter-8/)Character | [](/book/tiny-c-projects/chapter-8/)Code | [](/book/tiny-c-projects/chapter-8/)Character | [](/book/tiny-c-projects/chapter-8/)Code | [](/book/tiny-c-projects/chapter-8/)Character | [](/book/tiny-c-projects/chapter-8/)Code | [](/book/tiny-c-projects/chapter-8/)Character |
| --- | --- | --- | --- | --- | --- | --- | --- |
| [](/book/tiny-c-projects/chapter-8/)0x00 | [](/book/tiny-c-projects/chapter-8/)\0 | [](/book/tiny-c-projects/chapter-8/)0x08 | [](/book/tiny-c-projects/chapter-8/)\r | [](/book/tiny-c-projects/chapter-8/)0x10 | [](/book/tiny-c-projects/chapter-8/)T | [](/book/tiny-c-projects/chapter-8/)0x18 | [](/book/tiny-c-projects/chapter-8/)O |
| [](/book/tiny-c-projects/chapter-8/)0x01 | [](/book/tiny-c-projects/chapter-8/)E | [](/book/tiny-c-projects/chapter-8/)0x09 | [](/book/tiny-c-projects/chapter-8/)D | [](/book/tiny-c-projects/chapter-8/)0x11 | [](/book/tiny-c-projects/chapter-8/)Z | [](/book/tiny-c-projects/chapter-8/)0x19 | [](/book/tiny-c-projects/chapter-8/)B |
| [](/book/tiny-c-projects/chapter-8/)0x02 | [](/book/tiny-c-projects/chapter-8/)\n | [](/book/tiny-c-projects/chapter-8/)0x0A | [](/book/tiny-c-projects/chapter-8/)R | [](/book/tiny-c-projects/chapter-8/)0x12 | [](/book/tiny-c-projects/chapter-8/)L | [](/book/tiny-c-projects/chapter-8/)0x1A | [](/book/tiny-c-projects/chapter-8/)G |
| [](/book/tiny-c-projects/chapter-8/)0x03 | [](/book/tiny-c-projects/chapter-8/)A | [](/book/tiny-c-projects/chapter-8/)0x0B | [](/book/tiny-c-projects/chapter-8/)J | [](/book/tiny-c-projects/chapter-8/)0x13 | [](/book/tiny-c-projects/chapter-8/)W | [](/book/tiny-c-projects/chapter-8/)0x1B | [](/book/tiny-c-projects/chapter-8/)shift |
| [](/book/tiny-c-projects/chapter-8/)0x04 | [](/book/tiny-c-projects/chapter-8/)space | [](/book/tiny-c-projects/chapter-8/)0x0C | [](/book/tiny-c-projects/chapter-8/)N | [](/book/tiny-c-projects/chapter-8/)0x14 | [](/book/tiny-c-projects/chapter-8/)H | [](/book/tiny-c-projects/chapter-8/)0x1C | [](/book/tiny-c-projects/chapter-8/)M |
| [](/book/tiny-c-projects/chapter-8/)0x05 | [](/book/tiny-c-projects/chapter-8/)S | [](/book/tiny-c-projects/chapter-8/)0x0D | [](/book/tiny-c-projects/chapter-8/)F | [](/book/tiny-c-projects/chapter-8/)0x15 | [](/book/tiny-c-projects/chapter-8/)Y | [](/book/tiny-c-projects/chapter-8/)0x1D | [](/book/tiny-c-projects/chapter-8/)X |
| [](/book/tiny-c-projects/chapter-8/)0x06 | [](/book/tiny-c-projects/chapter-8/)I | [](/book/tiny-c-projects/chapter-8/)0x0E | [](/book/tiny-c-projects/chapter-8/)C | [](/book/tiny-c-projects/chapter-8/)0x16 | [](/book/tiny-c-projects/chapter-8/)P | [](/book/tiny-c-projects/chapter-8/)0x1E | [](/book/tiny-c-projects/chapter-8/)V |
| [](/book/tiny-c-projects/chapter-8/)0x07 | [](/book/tiny-c-projects/chapter-8/)U | [](/book/tiny-c-projects/chapter-8/)0x0F | [](/book/tiny-c-projects/chapter-8/)K | [](/book/tiny-c-projects/chapter-8/)0x17 | [](/book/tiny-c-projects/chapter-8/)Q | [](/book/tiny-c-projects/chapter-8/)0x1F | [](/book/tiny-c-projects/chapter-8/)del |

##### [](/book/tiny-c-projects/chapter-8/)Table 8.3 Baudot-Murray codes for ITA2 and US-TTY, figure set[(view table figure)](https://drek4537l1klr.cloudfront.net/gookin/HighResolutionFigures/table_8-3.png)

| [](/book/tiny-c-projects/chapter-8/)Code | [](/book/tiny-c-projects/chapter-8/)Character | [](/book/tiny-c-projects/chapter-8/)Code | [](/book/tiny-c-projects/chapter-8/)Character | [](/book/tiny-c-projects/chapter-8/)Code | [](/book/tiny-c-projects/chapter-8/)Character | [](/book/tiny-c-projects/chapter-8/)Code | [](/book/tiny-c-projects/chapter-8/)Character |
| --- | --- | --- | --- | --- | --- | --- | --- |
| [](/book/tiny-c-projects/chapter-8/)0x00 | [](/book/tiny-c-projects/chapter-8/)\0 | [](/book/tiny-c-projects/chapter-8/)0x08 | [](/book/tiny-c-projects/chapter-8/)/r | [](/book/tiny-c-projects/chapter-8/)0x10 | [](/book/tiny-c-projects/chapter-8/)5 | [](/book/tiny-c-projects/chapter-8/)0x18 | [](/book/tiny-c-projects/chapter-8/)9 |
| [](/book/tiny-c-projects/chapter-8/)0x01 | [](/book/tiny-c-projects/chapter-8/)3 | [](/book/tiny-c-projects/chapter-8/)0x09 | [](/book/tiny-c-projects/chapter-8/)$ | [](/book/tiny-c-projects/chapter-8/)0x11 | [](/book/tiny-c-projects/chapter-8/)" | [](/book/tiny-c-projects/chapter-8/)0x19 | [](/book/tiny-c-projects/chapter-8/)? |
| [](/book/tiny-c-projects/chapter-8/)0x02 | [](/book/tiny-c-projects/chapter-8/)\n | [](/book/tiny-c-projects/chapter-8/)0x0A | [](/book/tiny-c-projects/chapter-8/)4 | [](/book/tiny-c-projects/chapter-8/)0x12 | [](/book/tiny-c-projects/chapter-8/)) | [](/book/tiny-c-projects/chapter-8/)0x1A | [](/book/tiny-c-projects/chapter-8/)& |
| [](/book/tiny-c-projects/chapter-8/)0x03 | [](/book/tiny-c-projects/chapter-8/)- | [](/book/tiny-c-projects/chapter-8/)0x0B | [](/book/tiny-c-projects/chapter-8/)' | [](/book/tiny-c-projects/chapter-8/)0x13 | [](/book/tiny-c-projects/chapter-8/)2 | [](/book/tiny-c-projects/chapter-8/)0x1B | [](/book/tiny-c-projects/chapter-8/)shift |
| [](/book/tiny-c-projects/chapter-8/)0x04 | [](/book/tiny-c-projects/chapter-8/)space | [](/book/tiny-c-projects/chapter-8/)0x0C | [](/book/tiny-c-projects/chapter-8/), | [](/book/tiny-c-projects/chapter-8/)0x14 | [](/book/tiny-c-projects/chapter-8/)# | [](/book/tiny-c-projects/chapter-8/)0x1C | [](/book/tiny-c-projects/chapter-8/). |
| [](/book/tiny-c-projects/chapter-8/)0x05 | [](/book/tiny-c-projects/chapter-8/)\a | [](/book/tiny-c-projects/chapter-8/)0x0D | [](/book/tiny-c-projects/chapter-8/)! | [](/book/tiny-c-projects/chapter-8/)0x15 | [](/book/tiny-c-projects/chapter-8/)6 | [](/book/tiny-c-projects/chapter-8/)0x1D | [](/book/tiny-c-projects/chapter-8/)/ |
| [](/book/tiny-c-projects/chapter-8/)0x06 | [](/book/tiny-c-projects/chapter-8/)8 | [](/book/tiny-c-projects/chapter-8/)0x0E | [](/book/tiny-c-projects/chapter-8/): | [](/book/tiny-c-projects/chapter-8/)0x16 | [](/book/tiny-c-projects/chapter-8/)0 | [](/book/tiny-c-projects/chapter-8/)0x1E | [](/book/tiny-c-projects/chapter-8/); |
| [](/book/tiny-c-projects/chapter-8/)0x07 | [](/book/tiny-c-projects/chapter-8/)7 | [](/book/tiny-c-projects/chapter-8/)0x0F | [](/book/tiny-c-projects/chapter-8/)( | [](/book/tiny-c-projects/chapter-8/)0x17 | [](/book/tiny-c-projects/chapter-8/)1 | [](/book/tiny-c-projects/chapter-8/)0x1F | [](/book/tiny-c-projects/chapter-8/)letters |

[](/book/tiny-c-projects/chapter-8/)Don’t try to make sense of the character mapping used in Baudot-Murray. If you’re pleased with the way ASCII codes are organized (refer to chapter 5), the text encoding shown in tables 8.2 and 8.3 is particularly baffling. Keep in mind that these codes were created for consistency with earlier systems. Perhaps some sense is to be found in the encoding. Who knows?

[](/book/tiny-c-projects/chapter-8/)I was all excited to write a program that translates between ASCII and Baudot-Murray encoding. The problem with such translation is that the resulting code is pretty much brute force, a character-to-character swap. Mix in the shifting character sets, and such a programming chore becomes a nightmare with no practical [](/book/tiny-c-projects/chapter-8/)[](/book/tiny-c-projects/chapter-8/)purpose.

### [](/book/tiny-c-projects/chapter-8/)8.1.2 Evolving into ASCII text and code pages

[](/book/tiny-c-projects/chapter-8/)Beyond [](/book/tiny-c-projects/chapter-8/)[](/book/tiny-c-projects/chapter-8/)[](/book/tiny-c-projects/chapter-8/)the Baudot-Murray code used on teletype machines, IBM invented a text-encoding standard for its mainframes: Extended Binary Coded Decimal Interchange Code (EBCDIC[](/book/tiny-c-projects/chapter-8/)[](/book/tiny-c-projects/chapter-8/)). This scheme was one of the first 8-bit character encoding standards, though it was used primarily with IBM mainframes.

[](/book/tiny-c-projects/chapter-8/)For input, IBM systems used punch cards. Therefore, the EBCDIC encoding scheme was designed to allocate codes for characters with the goal of keeping the punched holes in the card from collecting in clusters. This approach was necessary to prevent the cards from tearing or the holes from connecting with each other. To meet this goal, the EBCDIC codes feature gaps in their sequences; many EBCDIC character codes are blank.

[](/book/tiny-c-projects/chapter-8/)As computing moved away from punch cards, throngs of programmers rejoiced. A new encoding standard—ASCII—was developed by the American Standards Association in 1963. A 7-bit standard, ASCII added logic and—more important—compassion to text encoding.

[](/book/tiny-c-projects/chapter-8/)The 7-bit ASCII code is still in use today, though bytes today are consistently composed of 8 bits. This extra bit means that modern computers can encode 256 characters for a byte of data, only half of which (codes 0 through 127) are standardized by ASCII.

[](/book/tiny-c-projects/chapter-8/)You can read more about having fun with ASCII in chapter 4. My focus in this section is about character codes 128 through 255, the so-called extended ASCII character set.

[](/book/tiny-c-projects/chapter-8/)Extended ASCII was never an official standard, nor was it consistent among all 8-bit computers. These extra 128 characters in a byte were mapped to non-ASCII characters on various microcomputers in the late 1970s and early 1980s. Having the codes available meant that more symbols could be generated on a typical computer, including common characters such as ×, ÷, ±, Greek letters, fractions, accented characters, diglyphs, and so on.

[](/book/tiny-c-projects/chapter-8/)Figure 8.2 lists the extended ASCII character set available on the original IBM PC series of computers back in the early 1980s. Though the variety of characters is rich, these 128 bonus symbols weren’t enough to represent every available or desired character—only a tease.

![Figure 8.2 The original IBM PC “extended ASCII” character set](https://drek4537l1klr.cloudfront.net/gookin/Figures/08-02.png)

[](/book/tiny-c-projects/chapter-8/)To accommodate more characters, early computers used code pages. A *code page*[](/book/tiny-c-projects/chapter-8/) represents a different collection of characters, for both ASCII (codes 0 through 127) and the 8-bit character codes, 128 to 255.

[](/book/tiny-c-projects/chapter-8/)The characters shown in figure 8.2 for codes 128 through 255 represent IBM PC code page 437. Other code pages use different symbols. Eventually code pages were made available for specific foreign languages and alphabetic. Chinese, Japanese, Arabic, and other character sets are featured on various code pages.

[](/book/tiny-c-projects/chapter-8/)Commands available in the venerable MS-DOS operating system allowed code page character sets to be switched, though the computer was still limited to using only one code page of characters at a time. In the system configuration file (`CONFIG.SYS`), the COUNTRY command[](/book/tiny-c-projects/chapter-8/) set locale details, including available code pages. At the command prompt, the CHCP command[](/book/tiny-c-projects/chapter-8/) is used to check the current code page as well as change the character set to a new code page.

[](/book/tiny-c-projects/chapter-8/)Linux doesn’t use code pages, mostly because it implements Unicode (see the next section). Windows, however, still uses the same extended ASCII code page as the original IBM PC. You can view these legacy characters when a program outputs character code values from 128 through 255.

[](/book/tiny-c-projects/chapter-8/)The source code in the following listing generates the contents of figure 8.2. The core of the program consists of nested for loops that output rows and columns representing the traditional extended ASCII character set, or code page 1. Formatting within the *printf()* statements[](/book/tiny-c-projects/chapter-8/) ensure that the output appears in a handy table.

##### Listing 8.2 Source code for extended_ascii.c

```
#include <stdio.h>
 
int main()
{
    int x,y;
 
    printf("      ");                  #1
    for(x=0; x<16; x++)
        printf(" %X ",x);              #2
    putchar('\n');
 
    for( x=0x80;x<0x100; x+=0x10 )     #3
    {
        printf(" 0x%2x ",x);
        for( y=0; y<0x10; y++ )
        {
            printf(" %c ",x+y);        #4
        }
        putchar('\n');
    }
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-8/)The program generated by the `extended_ascii.c` source code[](/book/tiny-c-projects/chapter-8/) works best on Windows computers. If you run it under Linux or on a Mac, the table is empty or populated with question marks. The characters aren’t missing; they just aren’t generated in the Linux/Unix environment unless a specific locale is set in the code. The topic of setting a locale is covered later in this chapter.

[](/book/tiny-c-projects/chapter-8/)The tasks of swapping code pages and exploring extended ASCII character sets are no longer required to generate fancy text. With the advent of Unicode in the 1990s, all the text encoding inconsistencies since the early telegraph days are finally [](/book/tiny-c-projects/chapter-8/)[](/book/tiny-c-projects/chapter-8/)[](/book/tiny-c-projects/chapter-8/)resolved.

### [](/book/tiny-c-projects/chapter-8/)8.1.3 Diving into Unicode

[](/book/tiny-c-projects/chapter-8/)Back [](/book/tiny-c-projects/chapter-8/)[](/book/tiny-c-projects/chapter-8/)[](/book/tiny-c-projects/chapter-8/)in the 1980s, those computer scientists who sat around thinking of wonderful new things to do hit the jackpot. They considered the possibilities of creating a consistent way to encode text—not just ASCII or Latin alphabet characters, but every scribble, symbol, and gewgaw known on this planet, both forward and backward in time. The result, unveiled in the 1990s, is Unicode.

[](/book/tiny-c-projects/chapter-8/)The original intention of Unicode was to widen character width from 8 bits to 16 bits. This change doesn’t double the number of characters—it increases possible character encodings from 256 to over 65,000. But even this huge quantity wasn’t enough.

[](/book/tiny-c-projects/chapter-8/)Today, the Unicode standard encompasses millions of characters, including hieroglyphics and emojis, a sampling of which is shown in figure 8.3. New characters are added all the time, almost every year. For example, in 2021, 838 new characters were added.

![Figure 8.3 Various Unicode characters](https://drek4537l1klr.cloudfront.net/gookin/Figures/08-03.png)

[](/book/tiny-c-projects/chapter-8/)The current code space for Unicode (as of 2022) consists of 1,114,111 code points. *Code space*[](/book/tiny-c-projects/chapter-8/) is the entire spectrum of Unicode. You can think of *code points*[](/book/tiny-c-projects/chapter-8/) as characters. Not every code point has a character assigned, however: many chunks of the code space are empty. Some code points are designed as overlays or macrons to combine with other characters. Of the plethora, the first 128 code points align with the ASCII standard.

[](/book/tiny-c-projects/chapter-8/)Unicode characters are referenced in the format U+*nnnn*, where *nnnn* is the hexadecimal value for the code point. The code space is organized into code panes representing various languages or scripts. Most web pages that reference Unicode characters, such as [unicode-table.com](http://unicode-table.com), use these code planes or blocks when you browse the collection of characters.

[](/book/tiny-c-projects/chapter-8/)To translate from a Unicode code point—say, U+2665—into a character in C, you must adhere to an encoding format. The most beloved of these encoding formats is the Unicode Transformation Format, UTF[](/book/tiny-c-projects/chapter-8/). Several flavors of UTF exist:

-  [](/book/tiny-c-projects/chapter-8/)UTF-8 uses 8-bit chunks (bytes) to hold character values, with multiple bytes containing the code for some values. The number of bytes varies, but they’re all 8-bit chunks.
-  [](/book/tiny-c-projects/chapter-8/)UTF-16 uses 16-bit chunks (words) to hold character values. This format isn’t as popular as UTF-8.
-  [](/book/tiny-c-projects/chapter-8/)UTF-32 uses 32-bit chunks (long words). All characters are represented by 32 bits whether or not they need the storage space. This format isn’t that popular because it occupies more space than many code points require.

[](/book/tiny-c-projects/chapter-8/)These encoding formats play a role with setting the locale, which is the key to working with Unicode text in C. More information on the locale is offered in section 8.2.1

[](/book/tiny-c-projects/chapter-8/)The character itself is described as a *wide character*, or a character that may require more than a single byte to generate output. This topic is covered later in section 8.2.2.

[](/book/tiny-c-projects/chapter-8/)Finally, be aware that not every typeface supports the entire Unicode host. Missing characters are output as blanks, question marks, or boxes, depending on the font. You may encounter this problem when running some of the programs later in this chapter. The solution is to set another font for the terminal window or to configure the terminal window so that it’s capable of outputting [](/book/tiny-c-projects/chapter-8/)[](/book/tiny-c-projects/chapter-8/)[](/book/tiny-c-projects/chapter-8/)Unicode [](/book/tiny-c-projects/chapter-8/)[](/book/tiny-c-projects/chapter-8/)text.

## [](/book/tiny-c-projects/chapter-8/)8.2 Wide character programming

[](/book/tiny-c-projects/chapter-8/)Just [](/book/tiny-c-projects/chapter-8/)[](/book/tiny-c-projects/chapter-8/)outputting a wide character to the console doesn’t work. You can try. Maybe you’ll be lucky, especially in Windows. But to properly output and program Unicode text in your C programs, you must first set the locale. This setting informs the computer that the program is capable of handling wide characters.

[](/book/tiny-c-projects/chapter-8/)After setting the locale, the code must access and use wide characters for its text I/O. This process is how some text mode programs output fancy Unicode characters in a terminal window—and how email messages and even text messages show emojis and other fun characters. Your program can do so as well, once you learn the steps introduced in this section.

### [](/book/tiny-c-projects/chapter-8/)8.2.1 Setting the locale

[](/book/tiny-c-projects/chapter-8/)Locale [](/book/tiny-c-projects/chapter-8/)[](/book/tiny-c-projects/chapter-8/)settings in a program establish such details as language, date and time format, currency symbol, and others specific to a language or region. This function and its pals allow you to write programs for different regions while being lazy about researching, for example, the culture’s thousands separator or currency symbol.

[](/book/tiny-c-projects/chapter-8/)For wide character output, setting the proper locale allows your code to use wide characters—the Unicode character set. Yes, setting the locale is the secret.

[](/book/tiny-c-projects/chapter-8/)To view the current locale settings in the Linux environment, type the locale command[](/book/tiny-c-projects/chapter-8/) in the terminal window. Here is the output I see:

```
LANG=C.UTF-8
LANGUAGE=
LC_CTYPE="C.UTF-8"
LC_NUMERIC="C.UTF-8"
LC_TIME="C.UTF-8"
LC_COLLATE="C.UTF-8"
LC_MONETARY="C.UTF-8"
LC_MESSAGES="C.UTF-8"
LC_PAPER="C.UTF-8"
LC_NAME="C.UTF-8"
LC_ADDRESS="C.UTF-8"
LC_TELEPHONE="C.UTF-8"
LC_MEASUREMENT="C.UTF-8"
LC_IDENTIFICATION="C.UTF-8"
LC_ALL=
```

[](/book/tiny-c-projects/chapter-8/)The UTF-8 character format is what allows Unicode text I/O—though to enable UTF-8 output in your code, you must use the *setlocale()* function, prototyped in the locale.h [](/book/tiny-c-projects/chapter-8/)header file. Here is the format:

```
char *setlocale(int category, const char *locale);
```

[](/book/tiny-c-projects/chapter-8/)The first argument, `category`, is a defined constant representing which aspect of the locale you want to set. Use `LC_ALL` to set all categories. The `LC_CTYPE` category[](/book/tiny-c-projects/chapter-8/) is specific to text.

[](/book/tiny-c-projects/chapter-8/)The second argument is a string to set the specific locale details. For example, for text you can specify `"en_US.UTF-8"`, which activates the 8-bit Unicode character set for English. An empty string can also be specified.

[](/book/tiny-c-projects/chapter-8/)The *setlocale()* function[](/book/tiny-c-projects/chapter-8/) returns a string representing the specific information requested. You need not use the string; setting the locale is good enough for wide character I/O.

[](/book/tiny-c-projects/chapter-8/)Be aware that the *setlocale()* function[](/book/tiny-c-projects/chapter-8/) isn’t available in some Windows compilers. The method for accessing Unicode characters in Windows is different from what’s described in this chapter.

[](/book/tiny-c-projects/chapter-8/)The next listing shows a tiny program that uses the *setlocale()* function[](/book/tiny-c-projects/chapter-8/) to output locale details—specifically, the character set in use. Line 8 uses the *setlocale()* function[](/book/tiny-c-projects/chapter-8/) to return a string describing the current locale, saved in variable `locale`[](/book/tiny-c-projects/chapter-8/). A *printf()* statement[](/book/tiny-c-projects/chapter-8/) outputs the locale string. Used in this way, the *setlocale()* function[](/book/tiny-c-projects/chapter-8/) doesn’t change the locale settings; it only reports information.

##### Listing 8.3 Source code for locale_function.c

```
#include <stdio.h>
#include <locale.h>                                 #1
 
int main()
{
    char *locale;                                   #2
 
    locale = setlocale(LC_ALL,"");                  #3
    printf("The current locale is %s\n",locale);    #4
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-8/)Here is sample output:

```
The current locale is C.UTF-8
```

[](/book/tiny-c-projects/chapter-8/)The C stands for the C language. If it doesn’t, it should. UTF-8 is the character encoding.

[](/book/tiny-c-projects/chapter-8/)After setting the locale, the next step to outputting Unicode characters is to understand the concept of wide [](/book/tiny-c-projects/chapter-8/)[](/book/tiny-c-projects/chapter-8/)characters.

### [](/book/tiny-c-projects/chapter-8/)8.2.2 Exploring character types

[](/book/tiny-c-projects/chapter-8/)To [](/book/tiny-c-projects/chapter-8/)[](/book/tiny-c-projects/chapter-8/)invoke the magic that enables access to Unicode’s humongous character set, you must be familiar with the three types of characters used in computerdom:

-  [](/book/tiny-c-projects/chapter-8/)Single-byte characters
-  [](/book/tiny-c-projects/chapter-8/)Wide characters
-  [](/book/tiny-c-projects/chapter-8/)Multibyte characters

[](/book/tiny-c-projects/chapter-8/)Single-byte characters provide the traditional way to generate text. These are 8-bit values, the *char* data type[](/book/tiny-c-projects/chapter-8/), equal to a single byte of storage. Though *char* values range from 0 through 255 (unsigned), only values 0 through 127 are assigned characters using the ASCII standard.

[](/book/tiny-c-projects/chapter-8/)The wide character data type uses more than 8-bits to encode text. The number of bytes can vary, depending on the character. In C, the *wchar_t* data type[](/book/tiny-c-projects/chapter-8/) handles wide characters, and the wide character (wchar) family of functions manipulates these characters.

[](/book/tiny-c-projects/chapter-8/)A multibyte character requires several bytes to represent the character. This description includes wide characters but also characters that require a prefix byte, or lead unit, and then another sequence of bytes to represent a single character. This type of multibyte character may be used in specific applications and computer platforms. It’s not covered in this book.

[](/book/tiny-c-projects/chapter-8/)To represent a single-byte character, you use the *char* data type[](/book/tiny-c-projects/chapter-8/) in C. For example:

```
char hash = '#';
```

[](/book/tiny-c-projects/chapter-8/)The hash character is assigned to *char* variable `hash`[](/book/tiny-c-projects/chapter-8/). The character code is 35 decimal, 23 hex.

[](/book/tiny-c-projects/chapter-8/)To represent wide characters, use the *wchar_t* data type[](/book/tiny-c-projects/chapter-8/). Its definition is found in the `wchar.h` header file, which must be included in your code. This header file also prototypes the various wide character functions. (See the next section.)

[](/book/tiny-c-projects/chapter-8/)The following statement declares the wide character `yen`[](/book/tiny-c-projects/chapter-8/):

```
wchar_t yen = 0xa5;
```

[](/book/tiny-c-projects/chapter-8/)The Yen character ¥ is U+00a5. This value is assigned to *wchar_t* variable `yen`[](/book/tiny-c-projects/chapter-8/). The compiler won’t let you assign the character directly:

```
wchar_t yen = L'¥';
```

[](/book/tiny-c-projects/chapter-8/)The `L` prefix defines the character as long (wide). This prefix works like the `L` suffix applied to *long* integer values: `123L` indicates the value 123 specified as a *long int* value. Although this L-prefix trick works with ASCII characters expressed as wide characters, your C compiler most likely chokes on the attempt to compile with such a character in the source code file; the warning I see is “Illegal character encoding.” Your editor also may not allow you to type or paste wide characters directly.

[](/book/tiny-c-projects/chapter-8/)The `L` prefix is also used to declare a wide character string. Here is a wide character string:

```
wchar_t howdy[] = L"Hello, planet Earth!";
```

[](/book/tiny-c-projects/chapter-8/)The string above, `"Hello,` `planet` `Earth!"`, is composed of wide characters, thanks to the `L` prefix. The *wchar_t* data type[](/book/tiny-c-projects/chapter-8/) declares wide string `howdy`.

[](/book/tiny-c-projects/chapter-8/)As with single characters, you cannot insert special characters into a wide string. The following declaration is flagged as illegal character encoding:

```
wchar_t monetary[] = L"$¥€₤";
```

[](/book/tiny-c-projects/chapter-8/)Such a string is instead composed in this manner:

```
wchar_t monetary[] = {
   0x24, 0xa5, 0x20ac, 0xa3, 0x0
};
```

[](/book/tiny-c-projects/chapter-8/)Hex values above represent the characters dollar sign, yen, euro, and British pound, followed by the null character caboose to terminate the string.

[](/book/tiny-c-projects/chapter-8/)To output wide characters and wide strings, use the w*printf()* function[](/book/tiny-c-projects/chapter-8/). This function works like the standard library *printf()* function[](/book/tiny-c-projects/chapter-8/), though it deals with wide strings. Special placeholders are used for wide characters and wide strings:

-  [](/book/tiny-c-projects/chapter-8/)The `%lc` placeholder represents a single wide character.
-  [](/book/tiny-c-projects/chapter-8/)The `%ls` placeholder represents a wide string.

[](/book/tiny-c-projects/chapter-8/)Lowercase L in the placeholder identifies the target variable as the wide or *wchar_t* data type[](/book/tiny-c-projects/chapter-8/). This character is analogous to the little L in the `%ld` placeholder for long decimal integer [](/book/tiny-c-projects/chapter-8/)[](/book/tiny-c-projects/chapter-8/)values.

### [](/book/tiny-c-projects/chapter-8/)8.2.3 Generating wide character output

[](/book/tiny-c-projects/chapter-8/)To [](/book/tiny-c-projects/chapter-8/)[](/book/tiny-c-projects/chapter-8/)output wide characters in C, you employ the functions declared in the `wchar.h` header file, which also conveniently defines the *wchar_t* data type[](/book/tiny-c-projects/chapter-8/). The functions parallel the standard string functions (from `string.h`), with most companion functions prefixed by a w or some other subtle difference. For example, the wide character version of *printf()* is *wprintf()*.

[](/book/tiny-c-projects/chapter-8/)Oh, and you need the `locale.h` header file because the wide character functions must be activated by first setting the locale. Refer to section 8.2.1 for details on using the *setlocale()* function[](/book/tiny-c-projects/chapter-8/).

[](/book/tiny-c-projects/chapter-8/)The next listing shows source code that uses the *wprintf()* function[](/book/tiny-c-projects/chapter-8/) in the traditional “Hello, world!” type of program, with my own wide twist. The *setlocale()* function[](/book/tiny-c-projects/chapter-8/) isn’t required because the output is ASCII, albeit wide ASCII, which is why the *wprintf()* formatting string is prefixed by an `L` (long, or wide character). The *stdio.h* header isn’t required because none of its functions appear in the code.

##### Listing 8.4 Source code for hello_wworld01.c

```
#include <wchar.h>                       #1
 
int main()
{
    wprintf(L"Hello, wide world!\n");    #2
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-8/)Here is the program’s output:

```
Hello, wide world!
```

[](/book/tiny-c-projects/chapter-8/)Nothing surprising, but don’t let the lack of suspense lull you into a false sense of familiarity. To help ease you into the wide character functions, you can modify the code in two steps.

[](/book/tiny-c-projects/chapter-8/)First, set the string as its own declaration earlier in the code:

```
wchar_t hello[] = L"Hello, wide world!\n";
```

[](/book/tiny-c-projects/chapter-8/)The *wchar_t* data type[](/book/tiny-c-projects/chapter-8/) defines array `hello[]`[](/book/tiny-c-projects/chapter-8/) composed of characters present in the wide string. If the `L` prefix is omitted, the compiler barfs up a data type mismatch error. Yes, it’s an error: the code won’t compile. To create a wide string, you need both the *wchar_t* data type[](/book/tiny-c-projects/chapter-8/) and the `L` prefix on the text enclosed in double quotes.

[](/book/tiny-c-projects/chapter-8/)Second, modify the *wprintf()* statement[](/book/tiny-c-projects/chapter-8/) to output the string:

```
wprintf(L"%ls",hello);
```

[](/book/tiny-c-projects/chapter-8/)The `L` prefix is required for the formatting string, because all wide character functions deal with wide characters. The `%ls` placeholder represents a string of wide characters. Argument `hello` references the address of the wide `hello[]` array[](/book/tiny-c-projects/chapter-8/).

[](/book/tiny-c-projects/chapter-8/)These two updates to the `hello_wworld01.c` code[](/book/tiny-c-projects/chapter-8/) are found in the online repository in the source code file `hello_wworld02.c`. The output is the same as from the first program.

[](/book/tiny-c-projects/chapter-8/)To output a single wide character, use the *putwchar()* function[](/book/tiny-c-projects/chapter-8/). It works like putchar(), and it’s one of several wide character functions where the w is found in the middle of its name.

[](/book/tiny-c-projects/chapter-8/)The code in the next listing outputs the four playing card suits: spades, hearts, clubs, and diamonds. Their Unicode values are assigned as elements of the `suits[]` array. The *setlocale()* function[](/book/tiny-c-projects/chapter-8/) is required because these are not ASCII characters. Within the *for* loop, the *putwchar()* function outputs the characters. A final *putwchar()* function[](/book/tiny-c-projects/chapter-8/)[](/book/tiny-c-projects/chapter-8/) outputs a newline—a wide newline.

##### Listing 8.5 Source code for suits.c

```
#include <wchar.h>
#include <locale.h>
 
int main()
{
    const int count = 4;
    wchar_t suits[count] = {
        0x2660, 0x2665, 0x2663, 0x2666    #1
    };
    int x;
 
    setlocale(LC_CTYPE,"en_US.UTF-8");    #2
 
    for( x=0; x<count; x++ )
        putwchar(suits[x]);               #3
    putwchar('\n');
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-8/)Here is the code’s output:

[](/book/tiny-c-projects/chapter-8/)♠♥♣♦

[](/book/tiny-c-projects/chapter-8/)On my Linux systems, the output is monochrome. But on my Macintosh, the hearts and diamonds symbols are colored red. This difference is based on the font used. The Mac seems to have a better selection of Unicode characters available in its terminal window than are available in my Linux distro.

[](/book/tiny-c-projects/chapter-8/)The code for `suits.c` illustrates how many Unicode strings are created and then output. The technique for creating the `suits[]` array is how you build a wide character string from scratch, though `suits[]` is a character array and not a string, which must be terminated with the null character.

[](/book/tiny-c-projects/chapter-8/) In the following listing, three Unicode strings are declared in the *main()* function. Each one ends with newline and null characters. The *fputws()* function[](/book/tiny-c-projects/chapter-8/) sends the strings as the output to the *stdout* device[](/book/tiny-c-projects/chapter-8/) (file handle, defined in `stdio.h`). This function is the equivalent of the *fputs()* function[](/book/tiny-c-projects/chapter-8/).

##### Listing 8.6 Source code for wide_hello.c

```
#include <stdio.h>                     #1
#include <wchar.h>
#include <locale.h>
 
int main()
{
    wchar_t russian[] = {              #2
        0x41f, 0x440, 0x438, 0x432, 0x435, 0x442, '!' , '\n', '\0'
    };
    wchar_t chinese[] = {
        0x4f31, 0x597d, '\n', '\0'
    };
    wchar_t emoji[] = {
        0x1f44b, '\n', '\0'
    };
 
    setlocale(LC_ALL,"en_US.UTF-8");
    fputws(russian,stdout);            #3
    fputws(chinese,stdout);
    fputws(emoji,stdout);
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-8/)Figure 8.4 shows the output generated by the `wide_hello.c` program[](/book/tiny-c-projects/chapter-8/). This screenshot is from my Macintosh, where the Terminal app properly generates all the Unicode characters. The output looks similar in Linux, though under Windows 10 Ubuntu Linux, only the Cyrillic text is output; the rest of the text appears as question marks in boxes. These generic characters mean that the Unicode characters shown in figure 8.4 are unavailable in the terminal’s assigned typeface.

![Figure 8.4 The properly interpreted output of the wide_hello.c program](https://drek4537l1klr.cloudfront.net/gookin/Figures/08-04.png)

[](/book/tiny-c-projects/chapter-8/)The inability of some typefaces to properly render portions of the Unicode character set is something you should always consider when coding wide text output.

[](/book/tiny-c-projects/chapter-8/)Not every string you output requires all wide text characters, such as those strings shown in listing 8.6. In fact, most often you may find a single character required in a string of otherwise typable, plain ASCII text. One way to sneak such a character into a string is demonstrated next. Here, the Yen character (¥) is declared on its own as *wchar_t* variable `yen`[](/book/tiny-c-projects/chapter-8/). This value is output in the *wprintf()* function[](/book/tiny-c-projects/chapter-8/) by using the `%lc` placeholder.

##### Listing 8.7 Source code for yen01.c

```
#include <wchar.h>
#include <locale.h>
 
int main()
{
    wchar_t yen = 0xa5;                       #1
 
    setlocale(LC_CTYPE,"en_US.UTF-8");
 
    wprintf(L"That will be %lc500\n",yen);    #2
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-8/)Here is the code’s output:

```
That will be ¥500
```

[](/book/tiny-c-projects/chapter-8/)In the code, I set the locale `LC_CTYPE` value to `en_US.UTF-8`, which is proper for the English language as it’s abused in the United States. You don’t need to set the Japanese locale (`ja_JP.UTF-8`) to output the character.

[](/book/tiny-c-projects/chapter-8/)Another way to insert a non-ASCII Unicode character in a string is substitution. For example, you can create a wide character string of ASCII text, then plop in a specific character before the string is output.

[](/book/tiny-c-projects/chapter-8/)To modify listing 8.7, first you create a wide character string with a placeholder for the untypable Unicode character:

```
wchar_t s[] = L"That will be $500\n";
```

[](/book/tiny-c-projects/chapter-8/)At element 13 in wide character string `s[]`, I’ve used a dollar sign instead of the Yen sign I need. The next step is to replace this element with the proper wide character:

```
s[13] = 0xa5;
```

[](/book/tiny-c-projects/chapter-8/)This assignment works because all characters in string `s[]` are wide. Character code 0xa5 replaces the dollar sign. The string is then output with this statement:

```
wprintf(L"%ls",s);
```

[](/book/tiny-c-projects/chapter-8/)This update to the code is named `yen02.c`, and it’s found in this book’s online repository. If you perform a trick like this, ensure that you properly document what value `0xa5` is, so as not to confuse any other programmers who may later examine your code.

#### [](/book/tiny-c-projects/chapter-8/)Exercise 8.1

[](/book/tiny-c-projects/chapter-8/)Using the method described earlier, and available in the source code file `yen02.c`, substitute a Unicode (untypable) character in a string. Create a program that outputs this text:

```
I ♥ to code.
```

[](/book/tiny-c-projects/chapter-8/)The Unicode value for the heart symbol is U+2665, shown earlier in the `suits.c` source code.

[](/book/tiny-c-projects/chapter-8/)My solution is available in the online repository as [](/book/tiny-c-projects/chapter-8/)[](/book/tiny-c-projects/chapter-8/)`code_love.c`.

### [](/book/tiny-c-projects/chapter-8/)8.2.4 Receiving wide character input

[](/book/tiny-c-projects/chapter-8/)Wide [](/book/tiny-c-projects/chapter-8/)[](/book/tiny-c-projects/chapter-8/)character input functions are prototyped in the `wchar.h` header file along with their output counterparts, covered in the preceding section. Like the wide character output functions, these input functions parallel those of standard input. For example, the *getwchar()* function receives wide character input just as the *getchar()* function[](/book/tiny-c-projects/chapter-8/)[](/book/tiny-c-projects/chapter-8/) receives normal character input. Or should it be called thin character input?

[](/book/tiny-c-projects/chapter-8/)The tricky part about wide character input is how to generate the wide characters. Standard keyboard input works as it always does—the characters interpreted as their wide values. Some keyboards have Unicode character keys, such as the £ or € symbols. Check to see whether your Linux terminal program allows for fancy character input methods, often from a right-click menu. When these tools aren’t available to you, the only trick left is to copy and paste Unicode characters from elsewhere, such as a web page or the output of some Unicode-happy application.

[](/book/tiny-c-projects/chapter-8/)The source code for `mood.c` is shown in the following listing. It uses the *getwchar()* function[](/book/tiny-c-projects/chapter-8/) to process standard input, including wide characters. The single-character input is echoed back in the *wprintf()* statement[](/book/tiny-c-projects/chapter-8/). The `%lc` placeholder represents *wchar_t* variable `mood`[](/book/tiny-c-projects/chapter-8/).

##### Listing 8.8 Source code for mood.c

```
#include <locale.h>
#include <wchar.h>
 
int main()
{
    wchar_t mood;                         #1
 
    setlocale(LC_CTYPE,"en_US.UTF-8");
 
    wprintf(L"What is your mood? ");      #2
    mood = getwchar();                    #3
    wprintf(L"I feel %lc, too!\n",mood);  #4
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-8/)The program created by `mood.c` reads from standard input, though any text you type is represented internally by using wide characters. Therefore, the program runs whether you type a Unicode character or any other keyboard character, as in this example:

```
What is your mood? 7
I feel 7, too!
```

[](/book/tiny-c-projects/chapter-8/)The true test, however, is to type a Unicode character, specifically an emoji. With some versions of Linux (not the Windows version), you can right-click (or control-click) in the terminal window to access emoji characters for input.

[](/book/tiny-c-projects/chapter-8/)In Windows, press the Windows and period keys on the keyboard to bring up an emoji palette. This trick works in the Ubuntu Linux shell window.

[](/book/tiny-c-projects/chapter-8/)On the Macintosh, press the Ctrl+Command+Space keyboard shortcut to see a pop-up emoji palette, as shown in figure 8.5. From this palette, you can choose an emoji to represent your mood, which then appears in the output string.

![Figure 8.5 Using the Macintosh emoji input panel in the Terminal app](https://drek4537l1klr.cloudfront.net/gookin/Figures/08-05.png)

[](/book/tiny-c-projects/chapter-8/)As a last resort, you can copy and paste the desired character from another program or website. Providing that the terminal window’s typeface has the given character, it appears in the program’s output.

[](/book/tiny-c-projects/chapter-8/)The *getwchar()* function[](/book/tiny-c-projects/chapter-8/) deals with stream input the same way that *getchar()* does; it’s not an interactive function. Review chapter 4 for information on stream I/O in C. The same rules apply to wide characters as they do to the standard *char* data type[](/book/tiny-c-projects/chapter-8/).

[](/book/tiny-c-projects/chapter-8/)To read more than a single character, use the *fgetws()* function[](/book/tiny-c-projects/chapter-8/). This function is the wide character version of *fgets()*, with a similar set of arguments. Here is the *man* page format[](/book/tiny-c-projects/chapter-8/):

```
wchar_t *fgetws(wchar_t *ws, int n, FILE *stream);
```

[](/book/tiny-c-projects/chapter-8/)The first argument is a *wchar_t* buffer[](/book/tiny-c-projects/chapter-8/) to store input. Then comes the buffer size, which is the input character count minus one for the null character, which is automatically added, and finally, the file stream, such as `stdin` for standard input.

[](/book/tiny-c-projects/chapter-8/)The *fgetws()* function[](/book/tiny-c-projects/chapter-8/) returns the buffer’s address upon success or NULL otherwise.

[](/book/tiny-c-projects/chapter-8/)The source code for `wide_string_in.c`, illustrated in the next listing, shows how the *fgetws()* function[](/book/tiny-c-projects/chapter-8/) is used. The wide character buffer `input`[](/book/tiny-c-projects/chapter-8/) stores wide characters read from the standard input device (`stdin`[](/book/tiny-c-projects/chapter-8/)). A *wprintf()* function[](/book/tiny-c-projects/chapter-8/) outputs the characters stored in the `input` buffer[](/book/tiny-c-projects/chapter-8/).

##### Listing 8.9 Source code for wide_in.c

```
#include <stdio.h>                            #1
#include <wchar.h>
#include <locale.h>
 
int main()
{
    const int size = 32;                      #2
    wchar_t input[size];                      #3
 
    setlocale(LC_CTYPE,"UTF-8");
 
    wprintf(L"Type some fancy text: ");
    fgetws(input,size,stdin);                 #4
    wprintf(L"You typed: '%ls'\n",input);     #5
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-8/)The program created from the `wide_in.c` source code[](/book/tiny-c-projects/chapter-8/) works like any basic I/O program—something you probably wrote when you first learned to program C. The difference is that wide characters are read, stored, and output. So, you can get fancy with your text, as shown in this sample run:

```
Type some fancy text: 你好，世界
You typed: '你好，世界
'
```

[](/book/tiny-c-projects/chapter-8/)As with standard input and the *fgets()* function[](/book/tiny-c-projects/chapter-8/), the newline character is retained in the input string. You see its effect on the output where the final single quote appears on the following line.

[](/book/tiny-c-projects/chapter-8/)Another wide input function I reluctantly want to cover is *wscanf[](/book/tiny-c-projects/chapter-8/)()*. This function is based on *scanf[](/book/tiny-c-projects/chapter-8/)()*, which is perhaps my least favorite C language input function, though it does have its purposes. Still, the function is a booger to work with because you must get the input data just right or else the thing collapses like a professional soccer player with a hangnail.

[](/book/tiny-c-projects/chapter-8/)Here is the man page[](/book/tiny-c-projects/chapter-8/) for *wscanf[](/book/tiny-c-projects/chapter-8/)()*:

```
int wscanf(const wchar_t *restrict format, ...);
```

[](/book/tiny-c-projects/chapter-8/)This format is identical to that of the *scanf()* function[](/book/tiny-c-projects/chapter-8/), though the formatting string (the first argument) is composed of wide characters. If you use this function, you will probably forget the `L` prefix on the formatting string at least once or twice.

[](/book/tiny-c-projects/chapter-8/)Listing 8.10 shows a silly I/O program, one that I may use in a beginner’s programming book. The only Unicode character involved is the British pound sign (£), which is declared early in the code. Otherwise, pay attention to how the *wscanf()* function[](/book/tiny-c-projects/chapter-8/) uses the `L` prefix for its formatting string. All the statements output wide characters. Input can be in wide characters as well, though only ASCII digits 0 through 9 hold any meaning to the code.

##### Listing 8.10 Source code for wscanf.c

```
#include <wchar.h>
#include <locale.h>
 
int main()
{
    const wchar_t pound = 0xa3;                 #1
    int quantity;
    float total;
 
    setlocale(LC_CTYPE,"en_US.UTF-8");
 
    wprintf(L"How many crisps do you want? ");
    wscanf(L"%d",&quantity);                    #2
    total = quantity * 1.4;                     #3
    wprintf(L"That'll be %lc%.2f\n",            #4
            pound,
            total
          );
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-8/)Here is a sample run:

```
How many crisps do you want? 2
That'll be £2.80
```

[](/book/tiny-c-projects/chapter-8/)They must be very nice crisps.

#### [](/book/tiny-c-projects/chapter-8/)Exercise 8.2

[](/book/tiny-c-projects/chapter-8/)Source code file `wide_in.c` (listing 8.9) processes a string of input. But when the string is shorter than the maximum number of characters allowed, the newline is retained in the string. Your task is to modify the source code so that any newline in the string is removed from output.

[](/book/tiny-c-projects/chapter-8/)One way to accomplish this task is to write your own output function. That’s too easy. Instead, you must create a function that removes the newline added by the *fgetws()* function[](/book/tiny-c-projects/chapter-8/), effectively trimming the string.

[](/book/tiny-c-projects/chapter-8/)My solution is available in this book’s online repository as `wide_in_better.c`. Please try this exercise on your own before you sneak a peek at my [](/book/tiny-c-projects/chapter-8/)[](/book/tiny-c-projects/chapter-8/)solution.

### [](/book/tiny-c-projects/chapter-8/)8.2.5 Working with wide characters in files

[](/book/tiny-c-projects/chapter-8/)The [](/book/tiny-c-projects/chapter-8/)[](/book/tiny-c-projects/chapter-8/)`wchar.h` header file also defines wide character equivalents of file I/O functions available in the standard C library—for example, *fputwc[](/book/tiny-c-projects/chapter-8/)()* to send a wide character to a stream, the equivalent of *fputc[](/book/tiny-c-projects/chapter-8/)()*. These wide character functions are paired with the standard library file I/O functions, such as *fopen[](/book/tiny-c-projects/chapter-8/)()*. This mixture creates an exciting pastiche of wide and nonwide characters, so mind your strings!

[](/book/tiny-c-projects/chapter-8/)As with standard I/O, your wide character file functions must set the locale. The file must be opened for reading, writing, or both. Wide character file I/O functions are used to put and get text from the file. The `WEOF` constant is used to identify the wide end-of-file character, *wint_t* data type[](/book/tiny-c-projects/chapter-8/). Once the file activity is done, the file is closed. This operation should be familiar to you if you’ve worked with file I/O in C.

[](/book/tiny-c-projects/chapter-8/)As an example, consider code to output the 24 uppercase letters of the Greek alphabet, alpha to omega, Α (U+0391) to Ω (U+03A9), saving the alphabet to a file. The Unicode values increment successively for each letter, though a blank spot exists at code U+03A2. These values parallel the lowercase Greek alphabet, which starts at U+03B1. The uppercase blank spot keeps the upper- and lowercase values parallel, as two lowercase sigma characters are used in Greek. These Unicode values are represented by constants within the code:

```
const wchar_t alpha = 0x391;
const wchar_t omega = 0x3a9;
const wchar_t no_sigma = 0x3a2;
```

[](/book/tiny-c-projects/chapter-8/)After the file is created, the uppercase Greek characters are written to the file one at a time, using a *for* loop as shown in the next listing. Constants `alpha`[](/book/tiny-c-projects/chapter-8/) and `omega`[](/book/tiny-c-projects/chapter-8/) represent the first and last characters’ Unicode values. The *wchar_t* constant `no_sigma`[](/book/tiny-c-projects/chapter-8/) is used in an *if* test[](/book/tiny-c-projects/chapter-8/) with the loop so that its character (U+03A2, which is blank) is skipped.

##### Listing 8.11 A loop that writes the uppercase Greek alphabet to a file

```
wprintf(L"Writing the Greek alphabet...\n");    #1
for( a=alpha; a<=omega; a++ )                   #2
{
    if( a==no_sigma )                           #3
        continue;                               #4
    fputwc(a,fp);                               #5
    fputwc(a,stdout);                           #6
}
fputwc('\0',fp);                                #7
```

[](/book/tiny-c-projects/chapter-8/)The rest of the code, not shown in listing 8.11, is available in this book’s online repository in the source code file `greek_write.c`. Missing are the statements to open and close the file, along with various variable declarations. Here is sample output:

```
Writing the Greek alphabet...
ΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩ
Done
```

[](/book/tiny-c-projects/chapter-8/)With the locale set, the file contains the Greek uppercase alphabet and not junk. Because the terminal window is intelligent enough to recognize Unicode, you can use the *cat* command[](/book/tiny-c-projects/chapter-8/) to dump the file:

```bash
$ cat alphabeta.wtxt
ΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩ $
```

[](/book/tiny-c-projects/chapter-8/)The filename is `alphabeta.wtxt`. I made up the `wtxt` extension for a wide text file. You also see that the file’s content lacks a newline, which is why the command prompt ($) appears after the Omega.

[](/book/tiny-c-projects/chapter-8/)Here is output from the *hexdump* utility[](/book/tiny-c-projects/chapter-8/), to show the file’s raw bytes:

```
0000000 91ce 92ce 93ce 94ce 95ce 96ce 97ce 98ce
0000010 99ce 9ace 9bce 9cce 9dce 9ece 9fce a0ce
0000020 a1ce a3ce a4ce a5ce a6ce a7ce a8ce a9ce
0000030 0000
0000031
```

[](/book/tiny-c-projects/chapter-8/)Several approaches are possible for reading wide characters from a file. Because I wrote the null character at the end of the alphabet, you can use the *fgetws()* function[](/book/tiny-c-projects/chapter-8/) to read in the line of text. This function is the wide character sibling of the *fgets()* function[](/book/tiny-c-projects/chapter-8/).

[](/book/tiny-c-projects/chapter-8/)The following listing shows the file-reading code, found in source code file `greek_read01.c` in this book’s online repository. Traditional file I/O commands open the file. The locale is set. Then the *fgetws()* function[](/book/tiny-c-projects/chapter-8/) does its magic to read the uppercase alphabet wide string. The line is output, and the file is closed.

##### Listing 8.12 Source code for greek_read01.c

```
#include <stdio.h>
#include <stdlib.h>
#include <wchar.h>
#include <locale.h>
 
int main()
{
    const char *file = "alphabeta.wtxt";    #1
    const int length = 64;                  #2
    FILE *fp;
    wchar_t line[length];                   #3
 
    fp = fopen(file,"r");                   #4
    if( file==NULL )                        #5
    {
        fprintf(stderr,"Unable to open %s\n",file);
        exit(1);
    }
 
    setlocale(LC_CTYPE,"en_US.UTF-8");
 
    wprintf(L"Reading from %s:\n",file);    #6
    fgetws(line,length,fp);                 #7
    wprintf(L"%ls\n",line);                 #8
 
    fclose(fp);
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-8/)Because the source code for `greek_write.c` adds a null character to the end of the alphabet, the *fgetws()* function[](/book/tiny-c-projects/chapter-8/) in `greek_read01.c` reads text from the file in one chunk: like the *fgets[](/book/tiny-c-projects/chapter-8/)()* function, *fgetws[](/book/tiny-c-projects/chapter-8/)()* stops reading when it encounters the null byte, a newline, or the buffer fills. Here is the program’s output:

```
Reading from alphabeta.wtxt:
ΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩ
```

[](/book/tiny-c-projects/chapter-8/)To read one wide character at a time from a file, use the *fgetwc()* function[](/book/tiny-c-projects/chapter-8/), which is the wide character counterpart of *fgetc[](/book/tiny-c-projects/chapter-8/)()*. Like *fgetc()*, the value returned by *fgetwc[](/book/tiny-c-projects/chapter-8/)()* isn’t a character or even a wide character. It’s a wide integer. Here is the *fgetwc()* function’s *man* page format[](/book/tiny-c-projects/chapter-8/):

```
wint_t fgetwc(FILE *stream);
```

[](/book/tiny-c-projects/chapter-8/)The function’s argument is an open file handle, or *stdin*[](/book/tiny-c-projects/chapter-8/) for standard input. The value returned is of the *wint_t* data type[](/book/tiny-c-projects/chapter-8/). As with *fgetc()*, the reason is that the wide end-of-file marker, *WEOF*[](/book/tiny-c-projects/chapter-8/), can be encountered, which the *wchar_t* type doesn’t interpret properly.

[](/book/tiny-c-projects/chapter-8/)To modify the code from `greek_read01.c` to read single characters from the file, only a few changes are required:

[](/book/tiny-c-projects/chapter-8/)The `line[]` buffer[](/book/tiny-c-projects/chapter-8/) is removed, along with the `length` constant[](/book/tiny-c-projects/chapter-8/). In its place, a [](/book/tiny-c-projects/chapter-8/)single *wint_t* variable is declared:

```
wint_t ch;
```

[](/book/tiny-c-projects/chapter-8/)To read from the file, the *fgetws()* statement, as well as the *wprintf()* statement[](/book/tiny-c-projects/chapter-8/), are replaced with these statements:

```
while( (ch=fgetwc(fp)) != WEOF )
   putwchar(ch);
putwchar('\n');
```

[](/book/tiny-c-projects/chapter-8/)The *while* loop’s condition both reads a character (a *wint_t* value) from the open file handle `fp`. This value is compared with *WEOF*[](/book/tiny-c-projects/chapter-8/), the wide character end-of-file marker. As long as the character isn’t the end of file, the loop repeats.

[](/book/tiny-c-projects/chapter-8/)The loop’s sole statement is `putwchar(ch)`[](/book/tiny-c-projects/chapter-8/), which outputs the character read. A final *putwchar()* statement[](/book/tiny-c-projects/chapter-8/) outputs a newline, cleaning up the output.

[](/book/tiny-c-projects/chapter-8/)The complete source code for `greek_read02.c` is available in this book’s online repository. The program’s output is the same as for the program version that used the *fgetws()* function[](/book/tiny-c-projects/chapter-8/) to read the alphabet:

```
Reading from alphabeta.wtxt:
ΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩ
```

#### [](/book/tiny-c-projects/chapter-8/)Exercise 8.3

[](/book/tiny-c-projects/chapter-8/)Using my Greek alphabet programs as a guide, create code that writes the Cyrillic alphabet to a file. You can optionally write a program that reads in the Cyrillic alphabet from the file you create, though the *cat* command works just as well.

[](/book/tiny-c-projects/chapter-8/)The first letter of the Cyrillic alphabet, A, is U+0410. The last letter is Я, U+042F. These are the uppercase letters. Unlike Greek, no blanks are found in the Unicode sequence.

[](/book/tiny-c-projects/chapter-8/)My solution is called `cyrillic.c`, and it’s available in this book’s [](/book/tiny-c-projects/chapter-8/)[](/book/tiny-c-projects/chapter-8/)online [](/book/tiny-c-projects/chapter-8/)[](/book/tiny-c-projects/chapter-8/)code [](/book/tiny-c-projects/chapter-8/)repository.
