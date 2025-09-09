# [](/book/tiny-c-projects/chapter-3/)3 NATO output

[](/book/tiny-c-projects/chapter-3/)Count yourself [](/book/tiny-c-projects/chapter-3/)blessed if you’ve never had to spell your name over the phone. Or perhaps you’re named Mary Smith, but you live on a street or in a city you must constantly spell aloud. If so, you resort to your own spelling alphabet, something like, “N, as in Nancy” or “K, as in knife.” As a programmer, you can ease this frustration by reading this chapter, where you

-  [](/book/tiny-c-projects/chapter-3/)Understand the NATO phonetic alphabet and why they even bother.
-  [](/book/tiny-c-projects/chapter-3/)Translate words into the spelling alphabet.
-  [](/book/tiny-c-projects/chapter-3/)Read a file to translate words into the phonetic alphabet.
-  [](/book/tiny-c-projects/chapter-3/)Go backward and translate the NATO alphabet into words.
-  [](/book/tiny-c-projects/chapter-3/)Read a file to translate the NATO alphabet.
-  [](/book/tiny-c-projects/chapter-3/)Learn that natto in Japanese is a delicious, fermented soybean paste.

[](/book/tiny-c-projects/chapter-3/)The last bullet point isn’t covered in this chapter. I just enjoy eating natto, and now I can write it off as a business expense.

[](/book/tiny-c-projects/chapter-3/)Anyway.

[](/book/tiny-c-projects/chapter-3/)The glorious conclusion to all this mayhem is to not only learn some new programming tricks but also proudly spell words aloud by saying “November” instead of “Nancy.”

The NATO alphabet

[](/book/tiny-c-projects/chapter-3/)Beyond [](/book/tiny-c-projects/chapter-3/)being a handy nickname for anyone named Nathaniel, NATO stands for the North Atlantic Treaty Organization[](/book/tiny-c-projects/chapter-3/)[](/book/tiny-c-projects/chapter-3/). It’s a group of countries who are members of a mutual defense pact.

[](/book/tiny-c-projects/chapter-3/)Established after World War II, blah-blah-blah. I could wax on, but the point is that NATO requires some commonality between its member states. You know, so that when Hans is short on ammo, Pierre can offer him bullets and they fit into the gun. Stuff like that.

[](/book/tiny-c-projects/chapter-3/)One common item shared between NATO countries is a way to spell things out loud. That way, Hans doesn’t need to say, “Bullets! That’s B, as in bratwurst; U, as in über; L, as in lederhosen. . . .” And so on. Instead, Hans says, “Bravo, Uniform, Lima, Lima, Echo, Tango.” This way, Pierre can understand Hans, even over all the surrounding gunfire.

[](/book/tiny-c-projects/chapter-3/)Table 3.1 lists the NATO phonetic alphabet, describing each letter with its corresponding word. The words are chosen to be unique and not easily misunderstood. Two of the words (Alfa and Juliett) are misspelled on purpose to avoid being confusing—and to be confusing.

##### [](/book/tiny-c-projects/chapter-3/)Table 3.1 The NATO phonetic alphabet.[(view table figure)](https://drek4537l1klr.cloudfront.net/gookin/HighResolutionFigures/table_3-1.png)

| [](/book/tiny-c-projects/chapter-3/)Letter | [](/book/tiny-c-projects/chapter-3/)NATO | [](/book/tiny-c-projects/chapter-3/)Letter | [](/book/tiny-c-projects/chapter-3/)NATO |
| --- | --- | --- | --- |
| [](/book/tiny-c-projects/chapter-3/)A | [](/book/tiny-c-projects/chapter-3/)Alfa | [](/book/tiny-c-projects/chapter-3/)N | [](/book/tiny-c-projects/chapter-3/)November |
| [](/book/tiny-c-projects/chapter-3/)B | [](/book/tiny-c-projects/chapter-3/)Bravo | [](/book/tiny-c-projects/chapter-3/)O | [](/book/tiny-c-projects/chapter-3/)Oscar |
| [](/book/tiny-c-projects/chapter-3/)C | [](/book/tiny-c-projects/chapter-3/)Charlie | [](/book/tiny-c-projects/chapter-3/)P | [](/book/tiny-c-projects/chapter-3/)Papa |
| [](/book/tiny-c-projects/chapter-3/)D | [](/book/tiny-c-projects/chapter-3/)Delta | [](/book/tiny-c-projects/chapter-3/)Q | [](/book/tiny-c-projects/chapter-3/)Quebec |
| [](/book/tiny-c-projects/chapter-3/)E | [](/book/tiny-c-projects/chapter-3/)Echo | [](/book/tiny-c-projects/chapter-3/)R | [](/book/tiny-c-projects/chapter-3/)Romeo |
| [](/book/tiny-c-projects/chapter-3/)F | [](/book/tiny-c-projects/chapter-3/)Foxtrot | [](/book/tiny-c-projects/chapter-3/)S | [](/book/tiny-c-projects/chapter-3/)Sierra |
| [](/book/tiny-c-projects/chapter-3/)G | [](/book/tiny-c-projects/chapter-3/)Golf | [](/book/tiny-c-projects/chapter-3/)T | [](/book/tiny-c-projects/chapter-3/)Tango |
| [](/book/tiny-c-projects/chapter-3/)H | [](/book/tiny-c-projects/chapter-3/)Hotel | [](/book/tiny-c-projects/chapter-3/)U | [](/book/tiny-c-projects/chapter-3/)Uniform |
| [](/book/tiny-c-projects/chapter-3/)I | [](/book/tiny-c-projects/chapter-3/)India | [](/book/tiny-c-projects/chapter-3/)V | [](/book/tiny-c-projects/chapter-3/)Victor |
| [](/book/tiny-c-projects/chapter-3/)J | [](/book/tiny-c-projects/chapter-3/)Juliett | [](/book/tiny-c-projects/chapter-3/)W | [](/book/tiny-c-projects/chapter-3/)Whiskey |
| [](/book/tiny-c-projects/chapter-3/)K | [](/book/tiny-c-projects/chapter-3/)Kilo | [](/book/tiny-c-projects/chapter-3/)X | [](/book/tiny-c-projects/chapter-3/)Xray |
| [](/book/tiny-c-projects/chapter-3/)L | [](/book/tiny-c-projects/chapter-3/)Lima | [](/book/tiny-c-projects/chapter-3/)Y | [](/book/tiny-c-projects/chapter-3/)Yankee |
| [](/book/tiny-c-projects/chapter-3/)M | [](/book/tiny-c-projects/chapter-3/)Mike | [](/book/tiny-c-projects/chapter-3/)Z | [](/book/tiny-c-projects/chapter-3/)Zulu |

[](/book/tiny-c-projects/chapter-3/)NATO isn’t the only phonetic alphabet, but it’s perhaps the most common. The point is consistency. As programmer, you don’t need to memorize any of these words, though as a nerd, you probably will. Still, it’s the program that can output NATO code—or translate it back into words, depending on how you write your C code. Oscar [](/book/tiny-c-projects/chapter-3/)Kilo.

## [](/book/tiny-c-projects/chapter-3/)3.2 The NATO translator program

[](/book/tiny-c-projects/chapter-3/)Any NATO translator program you write must have a string array, like the one shown here:

```
const char *nato[] = {
   "Alfa", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot",
   "Golf", "Hotel", "India", "Juliett", "Kilo", "Lima",
   "Mike", "November", "Oscar", "Papa", "Quebec", "Romeo",
   "Sierra", "Tango", "Uniform", "Victor", "Whiskey",
   "Xray", "Yankee", "Zulu"
};
```

[](/book/tiny-c-projects/chapter-3/)The array’s notation, `*nato[]`, implies an array of pointers, which is how the compiler builds this construction in memory. The array’s data type is *char*, so the pointers reference character arrays—strings—stored in memory. It’s classified as a constant because it’s unwise to create an array of strings as pointers and then risk modifying them later. The `nato[]` array[](/book/tiny-c-projects/chapter-3/) is filled with the memory locations of the strings, as illustrated in figure 3.1.

![Figure 3.1 How an array of pointers references strings as they sit in memory](https://drek4537l1klr.cloudfront.net/gookin/Figures/03-01.png)

[](/book/tiny-c-projects/chapter-3/)For example, in the figure, the string *Alfa* (terminated with a null character, `\0`) is stored at address 0x404020. This memory location is stored in the `nato[]` array[](/book/tiny-c-projects/chapter-3/), not the string itself. Yes, the string appears in the array’s declaration, but it’s stored elsewhere in memory at runtime. The same structure holds true for all elements in the array: each one corresponds to a string’s memory location, from Alfa to Zulu.

[](/book/tiny-c-projects/chapter-3/)The beauty of the `nato[]` array[](/book/tiny-c-projects/chapter-3/) is that the contents are sequential, matching up to ASCII values `'A'` through `'Z'` when you subtract the value of `'A'`. (See chapter 4 for more details on how this operation works.) This coincidence makes extracting the character corresponding to the NATO word embarrassingly easy.

### [](/book/tiny-c-projects/chapter-3/)3.2.1 Writing the NATO translator

[](/book/tiny-c-projects/chapter-3/)A [](/book/tiny-c-projects/chapter-3/)simple NATO translator is shown in listing 3.1. It prompts for input, using the *fgets()* function[](/book/tiny-c-projects/chapter-3/) to gather a word from standard input. A *while* loop churns through the word letter by letter. Along the way, any alphabetic characters are detected by the *isalpha()* function[](/book/tiny-c-projects/chapter-3/). If found, the letter is used as a reference into the `nato[]` array[](/book/tiny-c-projects/chapter-3/). The result is the NATO phonetic alphabet term output.

##### Listing 3.1 Source code for nato01.c

```
#include <stdio.h>
#include <ctype.h>
 
int main()
{
    const char *nato[] = {
        "Alfa", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot",
        "Golf", "Hotel", "India", "Juliett", "Kilo", "Lima",
        "Mike", "November", "Oscar", "Papa", "Quebec", "Romeo",
        "Sierra", "Tango", "Uniform", "Victor", "Whiskey",
        "Xray", "Yankee", "Zulu"
    };
    char phrase[64];
    char ch;
    int i;
 
    printf("Enter a word or phrase: ");
    fgets(phrase,64,stdin);                #1
 
    i = 0;
    while(phrase[i])                       #2
    {
        ch = toupper(phrase[i]);           #3
        if(isalpha(ch))                    #4
            printf("%s ",nato[ch-'A']);    #5
        i++;
        if( i==64 )                        #6
            break;
    }
    putchar('\n');
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-3/)When built and run, the program prompts for input. Whatever text is typed (up to 63 characters) is translated and output in the phonetic alphabet. For example, “Howdy” becomes:

```
Hotel Oscar Whiskey Delta Yankee
```

[](/book/tiny-c-projects/chapter-3/)Typing a longer phrase such as “Hello, World!” yields:

```
Hotel Echo Lima Lima Oscar Whiskey Oscar Romeo Lima Delta
```

[](/book/tiny-c-projects/chapter-3/)Because nonalpha characters are ignored in the code, no output for them is generated.

[](/book/tiny-c-projects/chapter-3/)Translation into another phonetic alphabet is easy with this code. All you do is replace the `nato[]` array[](/book/tiny-c-projects/chapter-3/) with your own phonetic alphabet. For example, here is the array you can use for the law enforcement phonetic [](/book/tiny-c-projects/chapter-3/)alphabet:

```
const char *fuzz[] = {
   "Adam", "Boy", "Charles", "David", "Edward", "Frank",
   "George", "Henry", "Ida", "John", "King", "Lincoln",
   "Mary", "Nora", "Ocean", "Paul", "Queen", "Robert",
   "Sam", "Tom", "Union", "Victor", "William",
   "X-ray", "Young", "Zebra"
};
```

### [](/book/tiny-c-projects/chapter-3/)3.2.2 Reading and converting a file

[](/book/tiny-c-projects/chapter-3/)I’m [](/book/tiny-c-projects/chapter-3/)unsure of the need to translate all the text from a file into the NATO phonetic alphabet. It’s a C project you can undertake, primarily for practice, but practically speaking, it makes little sense. I mean, it would be tedious to hear three hours of *Antony and Cleopatra* done entirely in the NATO alphabet, though if you’re a theater/IT dual major, give it a shot. Still, this is a book and I’m a nerd, so the topic will be explored for your betterment.

[](/book/tiny-c-projects/chapter-3/)Listing 3.2 presents code that devours a file and translates each character into its NATO phonetic alphabet counterpart. The filename is supplied at the command prompt. If not, the program bails with an appropriate error message. Otherwise, similar to the code in `nato01.c`, the code churns though the file one character at a time, spewing out the matching NATO words.

##### Listing 3.2 Source code for nato02.c

```
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
 
int main(int argc, char *argv[])
{
    const char *nato[] = {
        "Alfa", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot",
        "Golf", "Hotel", "India", "Juliett", "Kilo", "Lima",
        "Mike", "November", "Oscar", "Papa", "Quebec", "Romeo",
        "Sierra", "Tango", "Uniform", "Victor", "Whiskey",
        "Xray", "Yankee", "Zulu"
    };
    FILE *n;
    int ch;
 
    if( argc<2 )                                       #1
    {
        fprintf(stderr,"Please supply a text file argument\n");
        exit(1);
    }
 
    n = fopen(argv[1],"r");                            #2
    if( n==NULL )
    {
        fprintf(stderr,"Unable to open '%s'\n",argv[1]);
        exit(1);
    }
 
    while( (ch=fgetc(n))!=EOF )                        #3
    {
        if(isalpha(ch))                                #4
            printf("%s ",nato[toupper(ch)-'A']);       #5
    }
    putchar('\n');
 
    fclose(n);
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-3/)Remember to use integer variables when processing text from a file. The EOF flag[](/book/tiny-c-projects/chapter-3/) that marks the end of a file is an *int* value, not a *char* value. The *while* statement in the code is careful to extract a character from the file as well as evaluate the character to determine when the operation is over.

[](/book/tiny-c-projects/chapter-3/)To run the program, type a filename argument after the program name. Text files are preferred. The output appears as a single line of text reflecting the phonetic alphabet words for every dang doodle character in the file.

[](/book/tiny-c-projects/chapter-3/)For extra fun on the Macintosh, pipe the program’s output through the say command[](/book/tiny-c-projects/chapter-3/):

```
nato02 antony_and_cleopatra.txt | say
```

[](/book/tiny-c-projects/chapter-3/)This way, the phonetic alphabet contents of the file given are read aloud by the Mac, from start to end. Sit back [](/book/tiny-c-projects/chapter-3/)and enjoy.

## [](/book/tiny-c-projects/chapter-3/)3.3 From NATO to English

[](/book/tiny-c-projects/chapter-3/)Phonetic [](/book/tiny-c-projects/chapter-3/)alphabet translation is supposed to happen in your head. Someone spells their hometown: India, Sierra, Sierra, Alfa, Quebec, Uniform, Alfa, Hotel. And the listener knows how to write down the word, spelling it properly. The word is *Issaquah*, which is a city where I once lived. I had to spell the name frequently. The beauty of this operation is that even a person who doesn’t know the NATO alphabet can understand what’s being spelled, thanks to the initial letter.

[](/book/tiny-c-projects/chapter-3/)More difficult, however, is to write code that scans for phonetic alphabet words and translates them into the proper single characters. This process involves parsing input and examining it word by word to see whether one of the words matches a term found in the lexicon.

### [](/book/tiny-c-projects/chapter-3/)3.3.1 Converting NATO input to character output

[](/book/tiny-c-projects/chapter-3/)To [](/book/tiny-c-projects/chapter-3/)determine whether a phonetic alphabet term appears in a chunk of text, you must parse the text. The string is separated into word chunks. Only after you pull out the words can you compare them with the phonetic alphabet terms.

[](/book/tiny-c-projects/chapter-3/)To do the heavy lifting, use the *strtok()* function[](/book/tiny-c-projects/chapter-3/) to parse words in a stream of text. I assume the function name translates as “string tokenizer” or “string to kilograms,” which makes no sense.

[](/book/tiny-c-projects/chapter-3/)The *strtok()* function[](/book/tiny-c-projects/chapter-3/) parses a string into chunks based on one or more separator characters. Defined in the `string.h` header file, the man page format[](/book/tiny-c-projects/chapter-3/) is:

```
char *strtok(char *str, const char *delim);
```

[](/book/tiny-c-projects/chapter-3/)The first argument, `str`, is the string to scan. The second argument, `delim`, is a string containing the individual characters that can separate, or *delimit*, the character chunks you want to parse. The value returned is a *char* pointer[](/book/tiny-c-projects/chapter-3/) referencing the character chunk found. For example:

```
match = strtok(string," ");
```

[](/book/tiny-c-projects/chapter-3/)This statement scans characters held in buffer `string`, stopping when the space character is encountered. Yes, the second argument is a full string, even when only a single character is required. The *char* pointer `match`[](/book/tiny-c-projects/chapter-3/) holds the address of the word (or text chunk) found, terminated with a null character where the space or another delimiter would otherwise be. The `NULL` constant[](/book/tiny-c-projects/chapter-3/) is returned when nothing is found.

[](/book/tiny-c-projects/chapter-3/)To continue scanning the same string, the first argument is replaced with the `NULL` constant[](/book/tiny-c-projects/chapter-3/):

```
match = strtok(NULL," ");
```

[](/book/tiny-c-projects/chapter-3/)The `NULL` argument informs the function to use the string passed earlier and continue the tokenizing operation. The code shown in the next listing illustrates how to put the *strtok()* function[](/book/tiny-c-projects/chapter-3/) to work.

##### Listing 3.3 Source code for word_parse01.c

```
#include <stdio.h>
#include <string.h>
 
int main()
{
    char sometext[64];
    char *match;
 
    printf("Type some text: ");
    fgets(sometext,64,stdin);
 
    match = strtok(sometext," ");     #1
    while(match)                      #2
    {
        printf("%s\n",match);
        match = strtok(NULL," ");     #3
    }
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-3/)In this code, the user is prompted for a string. The *strtok()* function[](/book/tiny-c-projects/chapter-3/) extracts words from the string, using a single space as the separator. Here’s a sample run:

```
Type some text: This is some text
This
is
some
text
```

[](/book/tiny-c-projects/chapter-3/)When separators other than the space appear in the string, they’re included in the character chunk match:

```
Type some text: Hello, World!
Hello,
World!
```

[](/book/tiny-c-projects/chapter-3/)To avoid capturing the punctuation characters, you can set this delimiter string:

```
match = strtok(sometext," ,.!?:;\"'");
```

[](/book/tiny-c-projects/chapter-3/)Here, the second argument lists common punctuation characters, including the double quote character, which must be escaped (\"). The result is that the delimited words are truncated, as in:

```
Type some text: Hello, World!
Hello
World
```

[](/book/tiny-c-projects/chapter-3/)You may find some trailing blank lines in the program’s output. These extra newline characters are fine for matching text, because the blank lines won’t match anything anyhow.

[](/book/tiny-c-projects/chapter-3/)To create a phonetic alphabet input translator, you modify this code to perform string comparisons with an array of NATO phonetic alphabet terms. The *strcmp()* function[](/book/tiny-c-projects/chapter-3/) handles this task, but you must consider two factors.

[](/book/tiny-c-projects/chapter-3/)First, *strcmp()* is case-sensitive. Some C libraries feature a *strcasecmp()* function[](/book/tiny-c-projects/chapter-3/) that performs case-insensitive comparisons, though this function isn’t part of the C standard. Second, the string length may vary. For example, if you choose not to count the punctuation characters (`"` `,.!?:;\"'"`) in the *strtok()* function[](/book/tiny-c-projects/chapter-3/)—or when an unanticipated punctuation character appears—the comparison fails.

[](/book/tiny-c-projects/chapter-3/)Given these two situations, I figure it’s best to concoct a unique string comparison function, one designed specifically to check parsed words for a match with a phonetic alphabet term. This function, *isterm[](/book/tiny-c-projects/chapter-3/)()*, is shown next.

##### Listing 3.4 The *isterm()* function

```
char isterm(char *term)
{
    const char *nato[] = {
        "Alfa", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot",
        "Golf", "Hotel", "India", "Juliett", "Kilo", "Lima",
        "Mike", "November", "Oscar", "Papa", "Quebec", "Romeo",
        "Sierra", "Tango", "Uniform", "Victor", "Whiskey",
        "Xray", "Yankee", "Zulu"
    };
    int x;
    char *n,*t;
 
    for( x=0; x<26; x++)
    {
        n = nato[x];                      #1
        t = term;                         #2
        while( *n!='\0' )                 #3
        {
            if( (*n|0x20)!=(*t|0x20) )    #4
                break;                    #5
            n++;                          #6
            t++;                          #6
        }
        if( *n=='\0' )                    #7
            return( *nato[x] );           #8
    }
    return('\0');
}
```

[](/book/tiny-c-projects/chapter-3/)The *isterm()* function[](/book/tiny-c-projects/chapter-3/) accepts a word as its argument. The return value is a single character if the word matches a NATO phonetic alphabet term; otherwise, the null character is returned.

[](/book/tiny-c-projects/chapter-3/)To create a new NATO translation program, add the *isterm()* function[](/book/tiny-c-projects/chapter-3/) to your source code file, below any existing code. You must include both the `stdio.h` and `string.h` header files. Then add the following main() function to build a new program, `nato03.c`[](/book/tiny-c-projects/chapter-3/), as shown here.

##### Listing 3.5 The *main()* function from nato03.c

```
int main()
{
   char phrase[64];
   char *match;
   char ch;
   printf("NATO word or phrase: ");
   fgets(phrase,64,stdin);

   match = strtok(phrase," ");
   while(match)
   {
       if( (ch=isterm(match))!='\0' )
           putchar(ch);
       match = strtok(NULL," ");
   }
   putchar('\n');

   return(0);
}
```

[](/book/tiny-c-projects/chapter-3/)The code scans the line input for any matching phonetic alphabet terms. The *isterm()* function[](/book/tiny-c-projects/chapter-3/) handles the job. The matching character is returned and output. Here’s a sample run:

```
NATO word or phrase: india tango whiskey oscar romeo kilo sierra
ITWORKS
```

[](/book/tiny-c-projects/chapter-3/)An input sentence with no matching characters outputs a blank line. Mixed characters are output like this:

```
NATO word or phrase: Also starring Zulu as Kono
Z
```

[](/book/tiny-c-projects/chapter-3/)If you want to add in code to translate special characters, such as punctuation characters, you can do so on your own. Keep in mind that the NATO phonetic alphabet lacks terms with punctuation, though if you’re creating your own text-translation program, checking for special characters might be [](/book/tiny-c-projects/chapter-3/)required.

### [](/book/tiny-c-projects/chapter-3/)3.3.2 Reading NATO input from a file

[](/book/tiny-c-projects/chapter-3/)Reading [](/book/tiny-c-projects/chapter-3/)input to detect and translate an alphabetic language is silly but a good exercise. Reading an entire file to detect an alphabetic language is even sillier. I try not to think of it as a necessity but rather as programming practice: can you scan a file for specific words and then report on their presence? Adopt this notion to justify completing such a program.

[](/book/tiny-c-projects/chapter-3/)As with reading a line of text, to process text in a file for signs of NATO alphabet words, you need the isterm() function[](/book/tiny-c-projects/chapter-3/). The file reads a line at a time, and the contents of each line are examined similarly to the code presented in `nato03.c`. Mixing in the file commands from `nato02.c`, I’ve created a child program, `nato04.c`[](/book/tiny-c-projects/chapter-3/). It’s found in this book’s GitHub repository. Assembling such a program in a kind of Frankenstein way appeals to me. It’s the philosophy upon which Stack Overflow is successful.

[](/book/tiny-c-projects/chapter-3/)The guts of `nato04.c` process an open file by using two while loops, illustrated in the next listing. If you’ve been following along with the NATO series of programs in this chapter, many of the statements are familiar to you.

##### Listing 3.6 Processing words in a file with nested loops

```
while( !feof(n) )                                 #1
{
    fgets(phrase,64,n);                           #2
    match = strtok(phrase," ,.!?=()[]{}'\"");     #3
    while(match)                                  #4
    {
        if( (ch=isterm(match))!='\0' )            #5
            putchar(ch);
        match = strtok(NULL," ,.!?=()[]{}'\"");
    }
}
putchar('\n');
```

[](/book/tiny-c-projects/chapter-3/)The result of all this cobbled code is to pluck out any matching NATO phonetic alphabet terms stored in a file and pop out the corresponding letter for each. As you may guess, few files have a NATO term smuggled inside, so the output is often empty. Still, I ran the code using the `nato04.c` source code file as input:

```bash
$ nato04 nato04.c
ABCDEFGHIJKLMNOPQRSTUVWXYZ
```

[](/book/tiny-c-projects/chapter-3/)Much to its delight, the program found the `nato[]` array’s text and gobbled up all the alphabetic terms, in order, to spew out the alphabet itself. Wonderful.

[](/book/tiny-c-projects/chapter-3/)One problem with the code in `nato04.c` is that the *fgets()* function[](/book/tiny-c-projects/chapter-3/) reads in only a slice of characters per line. In the source code, if a line of text in the file is shorter than the given number of characters (63 plus one for the null character), the line of text is read up to and including the newline character. If the line of text in a file is longer than the quantity specified by the *fgets()* function[](/book/tiny-c-projects/chapter-3/), it’s truncated. Truncating text when you’re looking for a word is bad, though not as bad as truncating an elephant.

[](/book/tiny-c-projects/chapter-3/)To better process the file, and ensure that words aren’t split by an unforgiving *fgets()* function[](/book/tiny-c-projects/chapter-3/), I’ve recajiggered the code to read the file one character at a time. In this approach, the code works more like a program filter. (Filters are covered in chapter 4.) The words in the file are assembled as each character is digested.

[](/book/tiny-c-projects/chapter-3/)Listing 3.7 shows a *while* loop that processes an open file, represented by *FILE* handle `n`. Characters are stored in int variable `ch`[](/book/tiny-c-projects/chapter-3/), read one at a time by using the *fgetc()* function[](/book/tiny-c-projects/chapter-3/). The integer variable `offset` tracks the characters read as they’re stored in a `word[]` buffer[](/book/tiny-c-projects/chapter-3/). This buffer is 64 characters long. If a buffer overflow occurs, the program terminates. I mean, show me a word longer than 64 characters. And if you can legitimately find one, increase the buffer size.

##### Listing 3.7 Processing words in a file one at a time

```
offset = 0;
while( (ch=fgetc(n))!=EOF )             #1
{
    if( isalpha(ch)  )                  #2
    {
        word[offset] = ch;              #3
        offset++;
        if( offset>=64 )                #4
        {
            fprintf(stderr,"Buffer overflow\n");
            return(1);
        }
    }
    else                                #5
    {
        if( offset > 0 )                #6
        {
            word[offset] = '\0';        #7
            putchar( isterm(word) );    #8
            offset=0;                   #9
        }
    }
}
putchar('\n');
```

[](/book/tiny-c-projects/chapter-3/)The code shown in listing 3.7 is part of the `nato05.c` source code file, available in this book’s GitHub repository. The program works similarly to `nato04.c`, though a long line of text read from the file isn’t split—which could split a valid word. By processing the file’s text one character at a time, such a split can’t happen (unless the word is ridiculously long).

[](/book/tiny-c-projects/chapter-3/)The program’s output is identical to that of `nato04.c` in the case of processing the source code file’s text:

```bash
$ nato05 nato05.c
ABCDEFGHIJKLMNOPQRSTUVWXYZ
```

[](/book/tiny-c-projects/chapter-3/)Like any program, the code for `nato05.c` can be improved upon. As it’s written, the code relies upon a nonalphabetic character to terminate a word: the *isalpha()* function[](/book/tiny-c-projects/chapter-3/) returns TRUE when the character (*int* value) examined is in the range `'A'` to `'Z'` or `'a'` to `'z'`. This rule eliminates contractions (*don’t*, *o’clock*), though it’s rare such contractions would be included in a phonetic alphabet.

[](/book/tiny-c-projects/chapter-3/)Beyond peeking into a file for NATO phonetic alphabetic terms, the code provides a practical example of how to scan any file for specific words. Consider it inspiration for other programs you may create. Or just enjoy your newfound knowledge of the NATO phonetic alphabet, so you can beam with pride when asked to spell your city name [](/book/tiny-c-projects/chapter-3/)over [](/book/tiny-c-projects/chapter-3/)the [](/book/tiny-c-projects/chapter-3/)phone.
