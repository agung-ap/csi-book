# [](/book/tiny-c-projects/chapter-6/)6 Password generators

[](/book/tiny-c-projects/chapter-6/)Are you [](/book/tiny-c-projects/chapter-6/)weary of the prompts? You know when some website asks you to apply a password to your account? “Ensure that it has at least one uppercase letter, one number, a symbol, and some hieroglyphics.” Or, “Here’s a suggested password that you’re incapable of typing, let alone committing to memory.” It’s exasperating.

[](/book/tiny-c-projects/chapter-6/)I hope you recognize the importance of applying a password to a digital account. And I trust that you’re familiar with the common rules: don’t use easily guessed passwords. Don’t use any words or terms easily associated with you. Don’t set the same password for every account. These admonishments are tedious but important.

[](/book/tiny-c-projects/chapter-6/)Setting a solid password is a must these days. As a C programmer, you can bolster your weary password arsenal by:

-  [](/book/tiny-c-projects/chapter-6/)Understanding password strategy
-  [](/book/tiny-c-projects/chapter-6/)Creating basic, jumble passwords
-  [](/book/tiny-c-projects/chapter-6/)Ensuring the password has the required characters
-  [](/book/tiny-c-projects/chapter-6/)Taking a detour in the world of Mad Libs
-  [](/book/tiny-c-projects/chapter-6/)Using random words to build passwords

[](/book/tiny-c-projects/chapter-6/)At its core, of course, a password is nothing more than a string. Authentication is a case-sensitive, character-by-character comparison of the input password with a password stored in an encrypted database. True, the process is more complex than this; I assume at some point the process involves a squirrel on a treadmill. Still, once decrypted, it’s that good old comparison that unlocks the digital door. The point of setting a good password is to create a key no one else knows about or can even guess.

[](/book/tiny-c-projects/chapter-6/)Unix [](/book/tiny-c-projects/chapter-6/)systems have always had password requirements for accounts. I mean, look at Unix nerds! Do you trust them? Better question: did they trust each other? Probably not, because the Unix logon has always prompted for a username and password.

[](/book/tiny-c-projects/chapter-6/)Despite knowing about computer security for decades, Microsoft didn’t require a password for Windows until Windows 95 escaped the castle laboratory in 1996. Even then, one of the most common emails I received from users at the time would ask how to avoid typing in the Windows password. Unlike Unix and other multiuser systems, PC users were unaccustomed to security. Proof of their ignorance is the proliferation of viruses in the 1990s, but I digress. Windows users just wanted to access the computer. Many of them avoided passwords on purpose.

[](/book/tiny-c-projects/chapter-6/)Enter the internet.

[](/book/tiny-c-projects/chapter-6/)As more of our lives are absorbed by the digital realm, creating and using passwords—serious passwords—becomes a must. Yes, at first, these were silly passwords just to meet the minimum requirement. But as the Bad Guys grew more sophisticated, passwords required more complexity.

### [](/book/tiny-c-projects/chapter-6/)6.1.1 Avoiding basic and useless passwords

[](/book/tiny-c-projects/chapter-6/)Lazy [](/book/tiny-c-projects/chapter-6/)Windows 95 users must still be with us. Inept passwords are used every day. Silly humans. You’ll find a list of the top 10 most common passwords in table 6.1. These aren’t even the silly or weak passwords—just the most common. Dwell on that thought for a moment.

##### [](/book/tiny-c-projects/chapter-6/)Table 6.1 Stupid passwords[(view table figure)](https://drek4537l1klr.cloudfront.net/gookin/HighResolutionFigures/table_6-1.png)

| [](/book/tiny-c-projects/chapter-6/)Rank | [](/book/tiny-c-projects/chapter-6/)Password | [](/book/tiny-c-projects/chapter-6/)Comment |
| --- | --- | --- |
| [](/book/tiny-c-projects/chapter-6/)1. | [](/book/tiny-c-projects/chapter-6/)123456 | [](/book/tiny-c-projects/chapter-6/)The bare minimum for a “must be six characters long” password. |
| [](/book/tiny-c-projects/chapter-6/)2. | [](/book/tiny-c-projects/chapter-6/)123456789 | [](/book/tiny-c-projects/chapter-6/)A “more than six characters long” password. |
| [](/book/tiny-c-projects/chapter-6/)3. | [](/book/tiny-c-projects/chapter-6/)qwerty | [](/book/tiny-c-projects/chapter-6/)Keyboard, top row, left. |
| [](/book/tiny-c-projects/chapter-6/)4. | [](/book/tiny-c-projects/chapter-6/)password | [](/book/tiny-c-projects/chapter-6/)An all-time classic. No one would guess! |
| [](/book/tiny-c-projects/chapter-6/)5. | [](/book/tiny-c-projects/chapter-6/)12345 | [](/book/tiny-c-projects/chapter-6/)Some people are just lazy. |
| [](/book/tiny-c-projects/chapter-6/)6. | [](/book/tiny-c-projects/chapter-6/)qwert123 | [](/book/tiny-c-projects/chapter-6/)Must have letters and numbers. |
| [](/book/tiny-c-projects/chapter-6/)7. | [](/book/tiny-c-projects/chapter-6/)1q2w3e | [](/book/tiny-c-projects/chapter-6/)Keyboard, numbers and characters, top left. |
| [](/book/tiny-c-projects/chapter-6/)8. | [](/book/tiny-c-projects/chapter-6/)12345678 | [](/book/tiny-c-projects/chapter-6/)More unclever numbers. |
| [](/book/tiny-c-projects/chapter-6/)9. | [](/book/tiny-c-projects/chapter-6/)111111 | [](/book/tiny-c-projects/chapter-6/)Repetitive unclever numbers. |
| [](/book/tiny-c-projects/chapter-6/)10. | [](/book/tiny-c-projects/chapter-6/)1234567890 | [](/book/tiny-c-projects/chapter-6/)Probably using the numeric keypad for this baby. |

[](/book/tiny-c-projects/chapter-6/)The reason using these passwords is useless is that every Bad Guy knows them and tries them first. And you know what? Sometimes they work! Lots of cases documented every day show some high-and-mighty official whose online security is compromised because the bozo was lazy and used a convenient password. It seems like such a person deserves to be hacked.

[](/book/tiny-c-projects/chapter-6/)Not listed in table 6.1, but still incredibly stupid, are using the following personal information tidbits foolishly in or as a password:

-  [](/book/tiny-c-projects/chapter-6/)Your birth year
-  [](/book/tiny-c-projects/chapter-6/)The current year
-  [](/book/tiny-c-projects/chapter-6/)Your first name
-  [](/book/tiny-c-projects/chapter-6/)Your favorite sports team’s name
-  [](/book/tiny-c-projects/chapter-6/)A curse word
-  [](/book/tiny-c-projects/chapter-6/)The word sex
-  [](/book/tiny-c-projects/chapter-6/)Your city or street name or street number

[](/book/tiny-c-projects/chapter-6/)The list goes on. These items are important to avoid—and why those quizzes on social media ask you such silly questions. Trust me—confessing who your best friend was in high school doesn’t tell Facebook which *Star Wars* character you are any more than rolling dice does. The Bad Guys are smart. Humans are dumb. The common answers people provide are used later to crack their passwords.

[](/book/tiny-c-projects/chapter-6/)Knowing these tricks is important when crafting a better password. After all, it’s easy for someone to take a stab at what might be your password than to brute-force combinations of letters, numbers, and symbols to try to guess a password. Be smart.

#### [](/book/tiny-c-projects/chapter-6/)Exercise 6.1

[](/book/tiny-c-projects/chapter-6/)Write a program that brute-force guesses the password *password*. Have your code spin through all the letter combinations *aaaaaaaa* through *zzzzzzzz* until it matches password. Eventually it will, of course, but the purpose of this exercise is to see how long the process takes. The solution I coded takes about 8 minutes to crack the password on my fastest computer (generating no output).

[](/book/tiny-c-projects/chapter-6/)My solution is titled `brutepass01.c`, and it’s available in this book’s online repository. It uses recursion to spin through letters of the alphabet like miles turning on an odometer. Comments in the code explain my [](/book/tiny-c-projects/chapter-6/)madness.

### [](/book/tiny-c-projects/chapter-6/)6.1.2 Adding password complexity

[](/book/tiny-c-projects/chapter-6/)To [](/book/tiny-c-projects/chapter-6/)help you be smart when it comes to passwords, your kind and loving system administrators have devised a few rules. These started simple:

[](/book/tiny-c-projects/chapter-6/)*Have a password. Please.*

[](/book/tiny-c-projects/chapter-6/)Then complexity was added:

[](/book/tiny-c-projects/chapter-6/)*Your password must contain both letters and numbers.*

[](/book/tiny-c-projects/chapter-6/)As the Bad Guys grew more adept at guessing passwords, or applying brute-force methods, more details were added:

[](/book/tiny-c-projects/chapter-6/)*Your password must contain at least one uppercase letter.*

[](/book/tiny-c-projects/chapter-6/)*Your password must be at least eight (or more) characters long.*

[](/book/tiny-c-projects/chapter-6/)*Your password must contain a symbol.*

[](/book/tiny-c-projects/chapter-6/)These suggestions add complexity, making it difficult to guess or brute-force the password. Even then, some websites offer even more annoying specifics. For example, figure 6.1 shows the rules for creating a new password at my bank. These rules are about as complex as they can get.

![Figure 6.1 Bank password restrictions are about as obnoxious as you can get.](https://drek4537l1klr.cloudfront.net/gookin/Figures/06-01.png)

[](/book/tiny-c-projects/chapter-6/)To add even more security, many services employ two-factor authentication. This technique involves a confirmation code sent to your cell phone or a code value generated by an app or special device. This extra level of security ensures that even if your password is compromised, the second-factor security key keeps your information [](/book/tiny-c-projects/chapter-6/)safe.

### [](/book/tiny-c-projects/chapter-6/)6.1.3 Applying the word strategy

[](/book/tiny-c-projects/chapter-6/)Studies [](/book/tiny-c-projects/chapter-6/)have shown that your typical jumbled password is no better at thwarting the Bad Guys than a password consisting of several words slung together and separated by numbers or symbols. For example, this password:

```
fbjKehL@g4jm7Vy$Glup
```

[](/book/tiny-c-projects/chapter-6/)offers no added security over this one:

```
Bob3monkeys*spittoon
```

[](/book/tiny-c-projects/chapter-6/)The second password has the advantage of being easier to remember and type. Yet when put to the test, password-cracking software takes the same if not longer amount of time to break the second, more readable password than the useless jumble.

[](/book/tiny-c-projects/chapter-6/)This better approach to password creation is what I call the *word strategy*: string together three or more words, mix in some upper- and lowercase letters, add numbers and symbols. In fact, the password requirements shown in figure 6.1 allow both password types shown in this section, but the word strategy is better.

[](/book/tiny-c-projects/chapter-6/)The word strategy also has the advantage of hashing. For example, you can key specific passwords to the sites and services you frequent. Should a password become compromised, you would immediately identify the source. Such a thing happened to me, when I received an email saying that “I know your password.” The Bad Guy listed the password—which was one I’ve used. I recognized it as my old Yahoo! password, which I changed after hackers stole the Yahoo! user database. I knew the password was compromised, and, based on the words used in the password, I knew the source. I wasn’t surprised or concerned by [](/book/tiny-c-projects/chapter-6/)this [](/book/tiny-c-projects/chapter-6/)revelation.

## [](/book/tiny-c-projects/chapter-6/)6.2 The complex password jumble

[](/book/tiny-c-projects/chapter-6/)You [](/book/tiny-c-projects/chapter-6/)[](/book/tiny-c-projects/chapter-6/)may think it’s relatively easy to write code that outputs your typical, jumbled text password. It is. You may have written such a program in your digital youth: a silly random-character generator. But like all things easy, it’s not a really good way to code a password program. Don’t let the silliness of the exercise dissuade you.

### [](/book/tiny-c-projects/chapter-6/)6.2.1 Building a silly random password program

[](/book/tiny-c-projects/chapter-6/)Listing 6.1 [](/book/tiny-c-projects/chapter-6/)[](/book/tiny-c-projects/chapter-6/)shows my random password generator, a silly version titled `randomp01.c` because the filename `silly.c` is already taken on my computer. It slices off the printable character ASCII spectrum from the exclamation point to the tilde, codes 33 through 126. (Refer to chapter 5 for fun details on ASCII.) This value sets the random number range. The character value output is added to the exclamation point character, which brings it back into printable range.

##### Listing 6.1 Source code for randomp01.c

```
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
 
int main()
{
    int x;
    char ch;
    const int length = 10;                #1
 
    srand( (unsigned)time(NULL) );
 
    for( x=0; x<length; x++ )
    {
        ch = rand() % ('~' - '!' + 1);    #2
        putchar( ch+'!' );                #3
    }
    putchar('\n');
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-6/)The program’s output is delightfully random but practically useless as a password:

```
aVd["o_rG2
```

[](/book/tiny-c-projects/chapter-6/)First, good luck memorizing that. Second, better luck typing it. Third, hope that the website allows all the characters’ output; the double-quote is suspect. Obviously, some conditions must be applied to the [](/book/tiny-c-projects/chapter-6/)[](/book/tiny-c-projects/chapter-6/)output.

### [](/book/tiny-c-projects/chapter-6/)6.2.2 Adding conditions to the password program

[](/book/tiny-c-projects/chapter-6/)Most [](/book/tiny-c-projects/chapter-6/)[](/book/tiny-c-projects/chapter-6/)of those random password generator routines on the internet produce a jumble of letters, numbers, and symbols, like a festive salad of nonsense but—like real salad—supposedly healthy for you. Obviously, some sort of intelligent programming is going on, as opposed to silly random character generation shown in the preceding section.

[](/book/tiny-c-projects/chapter-6/)A generated password’s characters can still be random, but they must be typed: uppercase, lowercase, numbers, symbols. The quantity of each depends on the password length, and the ratio of character types varies.

[](/book/tiny-c-projects/chapter-6/)To improve the silly password program and make it smarter, consider limiting the password’s contents to the following:

-  [](/book/tiny-c-projects/chapter-6/)One uppercase letter
-  [](/book/tiny-c-projects/chapter-6/)Six lowercase letters
-  [](/book/tiny-c-projects/chapter-6/)One number
-  [](/book/tiny-c-projects/chapter-6/)Two symbols

[](/book/tiny-c-projects/chapter-6/)The total number of characters is 10, which is good for a password.

[](/book/tiny-c-projects/chapter-6/)Random letters and numbers are easy to generate, but to avoid running afoul of any character restrictions, I would offer that these symbols are safe, though you’re always free to create your own list:

```
! @ # $ % * _ -
```

[](/book/tiny-c-projects/chapter-6/)The task now is to limit the password to the restrictions given.

#### [](/book/tiny-c-projects/chapter-6/)Exercise 6.2

[](/book/tiny-c-projects/chapter-6/)Write code that generates a random password limited to the characters listed in this section (10 total). Name the code `randomp02.c`. Include in your solution these four functions: *uppercase[](/book/tiny-c-projects/chapter-6/)()*, *lowercase[](/book/tiny-c-projects/chapter-6/)()*, *number[](/book/tiny-c-projects/chapter-6/)()*, and *symbol[](/book/tiny-c-projects/chapter-6/)()*. The *uppercase()* function[](/book/tiny-c-projects/chapter-6/) returns a random character in the range from A to Z. The *lowercase()* function[](/book/tiny-c-projects/chapter-6/) returns a lowercase character, A to Z. The *number()* function[](/book/tiny-c-projects/chapter-6/) returns a character 0 through 9. And the *symbol()* function[](/book/tiny-c-projects/chapter-6/) plucks a random character from an array of safe symbols and returns it. The password is output in the *main()* function, which uses this pattern: one uppercase letter, six lowercase letters, one number, two symbols.

[](/book/tiny-c-projects/chapter-6/)As a tip, I use defined constants to create the pattern:

```
#define UPPER 1
#define LOWER 6
#define NUM 1
#define SYM 2
```

[](/book/tiny-c-projects/chapter-6/)These defined constants save time later, as the code is [](/book/tiny-c-projects/chapter-6/)[](/book/tiny-c-projects/chapter-6/)updated.

### [](/book/tiny-c-projects/chapter-6/)6.2.3 Improving upon the password

[](/book/tiny-c-projects/chapter-6/)My [](/book/tiny-c-projects/chapter-6/)[](/book/tiny-c-projects/chapter-6/)solution to exercise 6.2 generates output like this:

```
Tmxlqeg8#@
Gdnqgrs2@%
Whizxxb9-*
```

[](/book/tiny-c-projects/chapter-6/)These valiant attempts at generating a random, jumbled password are successful but uninspired. Further, they might be easily compromised in that their pattern is predictable: they all start with an uppercase letter, six lowercase letters, a number, and finally two symbols. Writing a password-cracking program would be easier knowing this pattern.

[](/book/tiny-c-projects/chapter-6/)A better way to output the random characters is to scramble them. For this improvement, the password must be stored in an array as opposed to output directly (which is what I did for my solution to exercise 6.2). So, the first step in making the conversion from `randomp02.c` to `randomp03.c` is to store the generated password—still using the same functions and pattern as before.

[](/book/tiny-c-projects/chapter-6/)Listing 6.2 shows the *main()* function from my updated code `randomp03.c`. The `password[]` buffer[](/book/tiny-c-projects/chapter-6/) is created, equal to the number of characters stored—all defined constants created earlier in the code—plus one for the terminating null character. I replaced the *for* loops in my version of `randomp02.c` with while loops, which pack the array with the necessary characters. The string is terminated and then output.

##### Listing 6.2 Improvements to the *main()* function for randomp03.c

```
int main()
{
    char password[ UPPER+LOWER+NUM+SYM+1 ];  #1
    int x;
 
    srand( (unsigned)time(NULL) );           #2
 
    x = 0;                                   #3
    while( x<UPPER )                         #4
        password[x++] = uppercase();
    while( x<UPPER+LOWER )                   #5
        password[x++] = lowercase();
    while( x<UPPER+LOWER+NUM )               #6
        password[x++] = number();
    while( x<UPPER+LOWER+NUM+SYM )           #7
        password[x++] = symbol();
    password[x] = '\0';                      #8
 
    printf("%s\n",password);                 #9
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-6/)The program’s output is unchanged, but this incremental step stores the password. With the password stored in a buffer, it can be passed to a new function, *scramble[](/book/tiny-c-projects/chapter-6/)()*, which randomizes the characters in the buffer.

[](/book/tiny-c-projects/chapter-6/)My *scramble()* function[](/book/tiny-c-projects/chapter-6/) is shown in listing 6.3. It uses a temporary buffer `key[]` to determine which characters need to be randomized. This array is initialized with null characters. A *while* loop spins, generating random values in the range of 0 through 9—the same as the number of elements in both the passed array `p[]` and local array `key[]`[](/book/tiny-c-projects/chapter-6/). If a random element contains the null character, a character from the passed array is stored in that position. The *while* loop repeats until all characters from the passed array are copied. A final *for* loop updates the passed array.

##### Listing 6.3 The *scramble()* function to randomize characters in an array

```
void scramble(char p[])
{
    const int size = UPPER+LOWER+NUM+SYM+1;   #1
    char key[size];
    int x,r;
 
    for( x=0; x<size; x++ )                   #2
        key[x] = '\0';
 
    x = 0;                                    #3
    while(x<size-1)                           #4
    {
        r = rand() % (size-1);                #5
        if( !key[r] )                         #6
        {
            key[r] = p[x];                    #7
            x++;                              #8
        }
    }
 
    for( x=0; x<size; x++ )                   #9
        p[x] = key[x];
}
```

[](/book/tiny-c-projects/chapter-6/)To call the *scramble()* function[](/book/tiny-c-projects/chapter-6/), update the code from `randomp03.c.` First add the *scramble()* function[](/book/tiny-c-projects/chapter-6/) somewhere before the *main()* function. This position negates the need to prototype the function earlier in the source code file. Then insert the following line before the *printf()* statement[](/book/tiny-c-projects/chapter-6/) in the *main()* function:

```
scramble(password);
```

[](/book/tiny-c-projects/chapter-6/)The full source code is available as `randomp04.c` in the book’s online repository. Here is sample output:

```
z%Wea#zhuX
```

[](/book/tiny-c-projects/chapter-6/)Yay! It’s still a horrible password to memorize or type, but it’s blessedly randomized.

[](/book/tiny-c-projects/chapter-6/)Further modification to the code can be made to adjust the password length and the specific number of the different type of characters. I had originally thought of presenting command-line switches to set the number of options and overall password length. For example:

```
pass_random -u1 -l6 -n1 -s2
```

[](/book/tiny-c-projects/chapter-6/)These arguments set one uppercase letter, six lowercase letters, one number, and two symbols. These options allow for more flexibility in creating the password. You could take the idea further and specify which symbols to include in the random password. Oh! I could go nuts coding this thing, but personally I prefer to use words in my passwords, so I’m moving on to the [](/book/tiny-c-projects/chapter-6/)[](/book/tiny-c-projects/chapter-6/)next [](/book/tiny-c-projects/chapter-6/)[](/book/tiny-c-projects/chapter-6/)section.

## [](/book/tiny-c-projects/chapter-6/)6.3 Words in passwords

[](/book/tiny-c-projects/chapter-6/)I [](/book/tiny-c-projects/chapter-6/)[](/book/tiny-c-projects/chapter-6/)gave up on jumbled passwords years ago. My preferred approach is to string a few random words together, along with the requisite capital letter and symbol, and at the desired length. This approach is far easier to remember and type. In fact, I still remember my old CompuServe password, with was just two words separated by a number. A password generator that spews forth words and the proper quantities of symbols and such is far more useful and interesting to code than the random password generator.

### [](/book/tiny-c-projects/chapter-6/)6.3.1 Generating random words, Mad Libs style

[](/book/tiny-c-projects/chapter-6/)To [](/book/tiny-c-projects/chapter-6/)[](/book/tiny-c-projects/chapter-6/)build a random word password generator, you need a routine that spits out random words. If they’re to be legitimate words, you most likely need some type of list from which to extract the words. Writing a word-generating function is a good approach, plus it gives you an opportunity to create a list of words you like, silly words, or words you frequently say in Walmart.

[](/book/tiny-c-projects/chapter-6/)Listing 6.4 highlights my *add_word()* function[](/book/tiny-c-projects/chapter-6/) as it appears in the source code file `randwords01.c`. The function contains a dozen words (actually pointers to strings) in array `vocabulary[]`. Variable `r` holds a random value in the range of zero to the number of elements in the array: `sizeof(vocabulary)` returns the number of bytes occupied by the array. This value is divided by `sizeof(char *)`, which is the size of each element in the array—a *char* pointer[](/book/tiny-c-projects/chapter-6/). The result is 12, which means `r` holds a random number from 0 through 11. This expression ensures that no matter how many words are in the array, the random number calculated is in the proper range. The function returns the random array element, a pointer to a string.

##### Listing 6.4 The *add_word()* function in randwords01.c

```
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
 
#define repeat(a) for(int x=0;x<a;x++)                  #1
const char *add_word(void)
{
    const char *vocabulary[] = {
        "orange", "grape", "apple", "banana",
        "coffee", "tea", "juice", "beverage",
        "happy", "grumpy", "bashful", "sleepy"
    };
    int r;
 
    r = rand() % (sizeof(vocabulary)/sizeof(char *));   #2
    return( vocabulary[r] );                            #3
}
 
int main()
{
    srand( (unsigned)time(NULL) );
 
    repeat(3)                                           #4
        printf("%s ", add_word() );
    putchar('\n');
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-6/)The code calls the *add_word()* function[](/book/tiny-c-projects/chapter-6/) thrice, though no guarantee is provided to prevent the same word from repeating, as shown in this sample output:

```
banana grape grape
```

[](/book/tiny-c-projects/chapter-6/)As a C programmer, you could add code to prevent duplicates from appearing in the output, but I would offer that a repeated word is also random. Still, this code is merely one step in a longer process.

[](/book/tiny-c-projects/chapter-6/)After writing the `randwords01.c` code[](/book/tiny-c-projects/chapter-6/), I felt inspired to ape the famous Mad Libs word game. Mad Libs is a registered trademark of Penguin Random House LLC and is fairly used here for educational purposes. Please don’t sue me.

[](/book/tiny-c-projects/chapter-6/)The first step in coding a Mad Libs program, all while avoiding a lawsuit, is crafting several functions along the lines of *add_word[](/book/tiny-c-projects/chapter-6/)()* used in the `randwords01.c` code[](/book/tiny-c-projects/chapter-6/). You must write one function for each word category as found in a Mad Libs: *add_noun()*, *add_verb()*, and *add_adjective()*, for example. Each function is populated with its own `vocabulary[]` array[](/book/tiny-c-projects/chapter-6/), packed with the corresponding word types: nouns, verbs, and adjectives. The *main()* function calls each function as required to fill in the blanks for a Mad Libs-like sentence, carefully crafted to avoid legal peril, such as the deliberately weak and unfunny example shown here.

##### Listing 6.5 The *main()* function from madlib01.c

```
int main()
{
    srand( (unsigned)time(NULL) );              #1
 
    printf("Will you please take the %s %s ",   #2
            add_adjective(),                    #3
            add_noun()                          #4
          );
    printf("and %s the %s?\n",                  #5
            add_verb(),                         #6
            add_noun()                          #7
          );
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-6/)Yes, my Mad Libs prototype is embarrassing. If you really want to treat yourself to a good Mad Libs, obtain one of the books from Leonard Stern and Roger Price because they won’t sic their lawyers on me. Still, the code works, fetching a random word from each of the functions. The output is less than hilarious, which, like any Mad Libs game, depends on good word choices:

```
Will you please take the ripe dog and slice the necklace?
```

[](/book/tiny-c-projects/chapter-6/)One way to add a richer variety of words to the various functions is to take the code a step further and read words from a vocabulary text file. For example, a `noun.txt` file contains dozens or hundreds of nouns, each on a line by itself. This format keeps the list accessible, easy to view and edit. Similar files could be created for other word types: `verb.txt`, `adjective.txt`, and so on.

[](/book/tiny-c-projects/chapter-6/)To read through the files and pluck out a random word, you can borrow a technique presented in chapter 2: the “pithy saying” series of programs ended with code that read from a text file, stored all the lines from the file, and then selected a random line of text for output. This approach can be used in an update to the Mad Libs program, where three separate files are scanned for random words. The code from chapter 2 is incorporated into the *build_vocabulary()* function[](/book/tiny-c-projects/chapter-6/) found in my updated Mad Libs program.

[](/book/tiny-c-projects/chapter-6/)In the next listing, you see the *main()* function from my updated Mad Libs program, `madlib02.c`. To handle numerous problems, and effectively shunt a lot of the work to the *build_vocabulary()* function[](/book/tiny-c-projects/chapter-6/), I chose to use structures to hold information about the various types of words. The output is lamentably the same pathetic text generated by the `madlib01.c` program[](/book/tiny-c-projects/chapter-6/).

##### Listing 6.6 The *main()* function from madlib02.c

```
int main()
{
       
    struct term noun = {"noun.txt",NULL,0,NULL};   #1
    struct term verb = {"verb.txt",NULL,0, NULL};
    struct term adjective = {"adjective.txt",NULL,0, NULL};
 
    build_vocabulary(&noun);                       #2
    build_vocabulary(&verb);
    build_vocabulary(&adjective);
 
    srand( (unsigned)time(NULL) );
 
    printf("Will you please take the %s %s ",
            add_word(adjective),                   #3
            add_word(noun)
          );
    printf("and %s the %s?\n",
            add_word(verb),
            add_word(noun)
          );
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-6/)The *main()* function begins by defining three `term` structures[](/book/tiny-c-projects/chapter-6/) to hold and reference the types of words to fill in the Mad Libs. Each member in the structure is defined, with `NULL` constants[](/book/tiny-c-projects/chapter-6/) set for the two pointer items.

[](/book/tiny-c-projects/chapter-6/)Here is the unfunny output:

```
Will you please take the pretty car and yell the motorcycle?
```

[](/book/tiny-c-projects/chapter-6/)You can view the entire source code file found in this book’s online repository. It’s named `madlib02.c`. It helps if you have this code visible in your editor as I discuss the details over the next few pages.

[](/book/tiny-c-projects/chapter-6/)The workhorse in the `madlib02.c` code[](/book/tiny-c-projects/chapter-6/) is the *build_vocabulary()* function[](/book/tiny-c-projects/chapter-6/). It relies upon the `term` structure[](/book/tiny-c-projects/chapter-6/), which is defined externally so that it’s visible to all the functions in the source code file:

```
struct term {
    char filename[16];    #1
    FILE *fp;             #2
    int items;            #3
    char **list_base;     #4
};
```

[](/book/tiny-c-projects/chapter-6/)By throwing these items in a structure, each call to the *build_vocabulary()* function[](/book/tiny-c-projects/chapter-6/) needs only one argument. The *build_vocabulary()* function[](/book/tiny-c-projects/chapter-6/) is based on the source code for `pithy05.c` (covered in chapter 2). Major retooling is done to use the passed structure members instead of local variables, but most of the code remains the same. Here is the prototype:

```
void build_vocabulary(struct term *t);
```

[](/book/tiny-c-projects/chapter-6/)The structure is passed as a pointer, `struct term *t`[](/book/tiny-c-projects/chapter-6/), which allows the function to modify the structure’s members and have the updated data retained. Otherwise, when the structure is passed directly (not as a pointer), any changes are abandoned when the function terminates. Because a pointer is passed, structure pointer notation (`->`) is used within the function.

[](/book/tiny-c-projects/chapter-6/)The *build_vocabulary()* function[](/book/tiny-c-projects/chapter-6/) performs these tasks:

1.  [](/book/tiny-c-projects/chapter-6/)Open the `t->filename` member, saving the `FILE` pointer in variable `t->fp` upon success.
1.  [](/book/tiny-c-projects/chapter-6/)Allocate storage for the `t->list_base` member, which eventually references all strings read from the file.

[](/book/tiny-c-projects/chapter-6/)A *while* loop reads each string (word) from the file. It performs these tasks:

1.  [](/book/tiny-c-projects/chapter-6/)Fetches the string and double-checks to confirm the EOF isn’t encountered.
1.  [](/book/tiny-c-projects/chapter-6/)Allocates memory for the string.
1.  [](/book/tiny-c-projects/chapter-6/)Copies the string into allocated memory.
1.  [](/book/tiny-c-projects/chapter-6/)Removes the newline (`\n`) from the string. This step isn’t found in the original `pithy05.c` code. It’s required to ensure that the word returned doesn’t contain a newline.
1.  [](/book/tiny-c-projects/chapter-6/)Confirms that the `t->list_base` buffer isn’t full. If so, reallocates the buffer to a larger size. [](/book/tiny-c-projects/chapter-6/)The last step takes place after the *while* loop is done:
1.  [](/book/tiny-c-projects/chapter-6/)Closes the open file.

[](/book/tiny-c-projects/chapter-6/)At the end of the function, the `items` member of the structure contains a count of all the words read from the file. The `list_base` member contains the addresses for each string stored in memory.

[](/book/tiny-c-projects/chapter-6/)The *main()* function in listing 6.6 also references the *add_word()* function[](/book/tiny-c-projects/chapter-6/). This function doesn’t require a pointer as an argument because it doesn’t modify the structure’s contents. Here is the add_word() function[](/book/tiny-c-projects/chapter-6/):

```
char *add_word(struct term t)        #1
{
    int word;
 
    word = rand() % t.items;          #2
    return( *(t.list_base+word) );    #3
}
```

[](/book/tiny-c-projects/chapter-6/)Most of the add_word() function[](/book/tiny-c-projects/chapter-6/) exists in the original `pithy05.c` code[](/book/tiny-c-projects/chapter-6/). It was set into a function here because it’s called with different structures, each one representing a grammatical word category.

[](/book/tiny-c-projects/chapter-6/)These programs can be used in any application where words stored in a file must be fetched and referenced as a program runs. By keeping the words stored in memory, the list can be accessed multiple times without having to reread the [](/book/tiny-c-projects/chapter-6/)[](/book/tiny-c-projects/chapter-6/)file.

### [](/book/tiny-c-projects/chapter-6/)6.3.2 Building a random word password generator

[](/book/tiny-c-projects/chapter-6/)You [](/book/tiny-c-projects/chapter-6/)[](/book/tiny-c-projects/chapter-6/)can craft two different types of random word password programs based on the two versions of the Mad Libs programs shown in the preceding section. The first program (`madlib01.c`[](/book/tiny-c-projects/chapter-6/)) uses arrays to store a series of random words. For more variety, however, you can use the second (`madlib02.c`[](/book/tiny-c-projects/chapter-6/)) code to take advantage of files that store your favorite password words.

[](/book/tiny-c-projects/chapter-6/)The easy version of the random word password generator works like the earlier *randomp* series of programs[](/book/tiny-c-projects/chapter-6/), specifically from the source code for `randomp04.c`. The goal is to create functions that return specific password pieces: a random word, a random number[](/book/tiny-c-projects/chapter-6/), and a random symbol. The words should already be mixed case. My version is named `passwords01.c`, and it’s found in this book’s online repository. Open it in an editor window so that you can follow along in the text.

[](/book/tiny-c-projects/chapter-6/)The *number()* and *symbol()* functions[](/book/tiny-c-projects/chapter-6/) are retained from the earlier code, though each now returns a string as opposed to a single character. A *static char* array holds the character to return as two-character string: The random character is saved in the first element, and a null character is saved in the second, making the array a string. Here are both functions:

```
char *number(void)
{
    static char n[2];            #1
 
    n[0] = rand() % 10 + '0';    #2
    n[1] = '\0';                 #3
 
    return(n);
}
 
char *symbol(void)
{
    char sym[8] = "!@#$%*_-";
    static char s[2];            #1
 
    s[0] = sym[rand() % 8];      #4
    s[1] = '\0';                 #3
 
    return( s );
}
```

[](/book/tiny-c-projects/chapter-6/)To generate words for the password, I borrowed the *add_noun()* function[](/book/tiny-c-projects/chapter-6/) from `madlib01.c`, changing it to reflect a series of random words with a few uppercase letters thrown in:

```
char *add_word(void)
{
   char *vocabulary[] = {
       "Orange", "Grape", "Apple", "Banana",
       "coffee", "tea", "juice", "beverage",
       "happY", "grumpY", "bashfuL", "sleepY"
   };
   int r;

   r = rand() % 12;
   return( vocabulary[r] );
}
```

[](/book/tiny-c-projects/chapter-6/)What I didn’t need from the `randomp04.c` code were the functions *scramble[](/book/tiny-c-projects/chapter-6/)()*, *uppercase[](/book/tiny-c-projects/chapter-6/)()*, and *lowercase[](/book/tiny-c-projects/chapter-6/)()*. The *main()* function, shown here, assembles everything into the final password string.

##### Listing 6.7 The *main()* function from passwords01.c

```
int main()
{
    char password[32];              #1
 
    srand( (unsigned)time(NULL) );
 
    password[0] = '\0';             #2
 
    strcpy(password,add_word());    #3
    strcat(password,number());      #4
    strcat(password,add_word());    #5
    strcat(password,symbol());      #6
    strcat(password,add_word());    #7
 
    printf("%s\n",password);
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-6/)Here is a sample run:

```
juice9grumpY%Grape
```

[](/book/tiny-c-projects/chapter-6/)Nothing is done in the code to prevent a word from being repeated, and the output might be missing an uppercase letter. But if you don’t like the words, add more by expanding the `vocabulary[]` array[](/book/tiny-c-projects/chapter-6/) in the *add_word()* function[](/book/tiny-c-projects/chapter-6/). Or, better, devise a system where you have files containing words you like to use in a password, like the way the second Mad Libs program works. In fact, you can use the same word files, `noun.txt`, `verb.txt`, and `adjective.txt`.

[](/book/tiny-c-projects/chapter-6/)My source code for `passwords02.c` pulls in elements from both `passwords01.c` and `madlib02.c`—specifically, the *build_vocabulary()* function[](/book/tiny-c-projects/chapter-6/) that reads words from a file and stores them in memory.

[](/book/tiny-c-projects/chapter-6/)You can see how both source code files are merged by examining the *main()* function from `passwords02.c` in the following listing. Yes, I’m being lazy with this code, where the first part of the *main()* function pulled from the *Mad Libs* program[](/book/tiny-c-projects/chapter-6/) and the second part from `passwords02.c`. The output is a string containing three random words, a random number, and a random symbol.

##### Listing 6.8 The *main()* function from passwords02.c

```
int main()
{
    char password[32];                               #1
    struct term noun = {"noun.txt",NULL,0,NULL};     #2
    struct term verb = {"verb.txt",NULL,0,NULL};
    struct term adjective = {"adjective.txt",NULL,0,NULL};
 
    build_vocabulary(&noun);
    build_vocabulary(&verb);
    build_vocabulary(&adjective);
 
    srand( (unsigned)time(NULL) );
 
    password[0] = '\0';                              #3
    strcpy(password,add_word(noun));
    strcat(password,number());
    strcat(password,add_word(verb));
    strcat(password,symbol());
    strcat(password,add_word(adjective));
 
    printf("%s\n",password);
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-6/)Here is a sample run, which isn’t any different from the `passwords01.c` code’s program output:

```
eyeball9yell!ripe
```

[](/book/tiny-c-projects/chapter-6/)On a positive note, this password output is far more hilarious than the output from any of my Mad Libs programs. Still, it has a password problem: where is the uppercase letter?

#### [](/book/tiny-c-projects/chapter-6/)Exercise 6.3

[](/book/tiny-c-projects/chapter-6/)Add another function to the source code from `passwords02.c` to create a new source code file, `passwords03.c`. This new function, *check_caps[](/book/tiny-c-projects/chapter-6/)()*, examines a string for an uppercase letter. If no uppercase letter is found, the function converts a lowercase letter to uppercase at some random position within the string. My solution is available online as `passwords03.c`, but try this exercise on your own before you sneak off to see how [](/book/tiny-c-projects/chapter-6/)[](/book/tiny-c-projects/chapter-6/)I [](/book/tiny-c-projects/chapter-6/)[](/book/tiny-c-projects/chapter-6/)did [](/book/tiny-c-projects/chapter-6/)it.
