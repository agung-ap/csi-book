# [](/book/tiny-c-projects/chapter-7/)7 String utilities

[](/book/tiny-c-projects/chapter-7/)It’s often [](/book/tiny-c-projects/chapter-7/)said, and rightly so, that the C programming language lacks a string data type. Such a thing would be nice. It would be easier to guarantee that every string in a program is bona fide and that all string functions work cleanly without flaw. But such claims are untrue. A string in C is a character array, weakly typed, and easy for any C programmer to screw up.

[](/book/tiny-c-projects/chapter-7/)Yes, handy string functions exist in C. A crafty coder can easily cobble together any string function, imitating what’s available in some other, loftier programming language but lacking in C. Still, any creative approach to handling an absent string function in C still must deal with the language’s myopic perception of the string concept. Therefore, some extra training is required, which includes:

-  [](/book/tiny-c-projects/chapter-7/)Reviewing what’s so terrible about strings in C
-  [](/book/tiny-c-projects/chapter-7/)Understanding how string length is measured
-  [](/book/tiny-c-projects/chapter-7/)Creating interesting and useful string functions
-  [](/book/tiny-c-projects/chapter-7/)Building your own string function library
-  [](/book/tiny-c-projects/chapter-7/)Exploring make-believe object-oriented programming

[](/book/tiny-c-projects/chapter-7/)Despite what you can do with strings in C, the grousing and disdain remains—and it’s legitimate. C strings are squishy things. It’s easy to mess up when you create or manipulate a string, even for experienced programmers. Still, strings exist as a valid form of data and are necessary for communications. So, prepare to bolster your string knowledge and build up your programming arsenal.

Strings in C

[](/book/tiny-c-projects/chapter-7/)That [](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)which you call a string doesn’t exist in C as its own data type, like an *int* or a *double*. No programmer worries about malforming an integer or incorrectly encoding the binary format of a real number. These data types—*int*[](/book/tiny-c-projects/chapter-7/), *double*[](/book/tiny-c-projects/chapter-7/), and even *char*[](/book/tiny-c-projects/chapter-7/)—are atoms. A string is a molecule. It must be constructed specifically.

[](/book/tiny-c-projects/chapter-7/)Technically, a string is a special type of character array. It has a beginning character, located at some address in memory. Every following character in memory is part of the string, up until the null character, `\0`, is encountered. This ad hoc structure is used as a string in C—though it remains squishy. If you require further understanding of the squishy concept, table 7.1 provides a comparative review.

##### [](/book/tiny-c-projects/chapter-7/)Table 7.1 Squishy things[(view table figure)](https://drek4537l1klr.cloudfront.net/gookin/HighResolutionFigures/table_7-1.png)

| [](/book/tiny-c-projects/chapter-7/)Thing | [](/book/tiny-c-projects/chapter-7/)Why it’s squishy |
| --- | --- |
| [](/book/tiny-c-projects/chapter-7/)Street intersection limit line | [](/book/tiny-c-projects/chapter-7/)Because few cars stop at the limit line. Most just roll through. |
| [](/book/tiny-c-projects/chapter-7/)Grandpa saying “No” | [](/book/tiny-c-projects/chapter-7/)Just give it time. Making a cute face helps. |
| [](/book/tiny-c-projects/chapter-7/)Building permits | [](/book/tiny-c-projects/chapter-7/)Different wait times apply, depending on how friendly you are with the mayor. |
| [](/book/tiny-c-projects/chapter-7/)Food | [](/book/tiny-c-projects/chapter-7/)Doesn’t mean the same thing on an airplane. |
| [](/book/tiny-c-projects/chapter-7/)Personality | [](/book/tiny-c-projects/chapter-7/)Good to have yourself; bad for a blind date. |
| [](/book/tiny-c-projects/chapter-7/)Obese | [](/book/tiny-c-projects/chapter-7/)Actuarial tables haven’t been updated since the 1940s. |
| [](/book/tiny-c-projects/chapter-7/)Fame on social media | [](/book/tiny-c-projects/chapter-7/)Wait a few hours. |
| [](/book/tiny-c-projects/chapter-7/)Sponge cake | [](/book/tiny-c-projects/chapter-7/)By design. |

### [](/book/tiny-c-projects/chapter-7/)7.1.1 Understanding the string

[](/book/tiny-c-projects/chapter-7/)It’s [](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)important to separate what you believe to be a string from a character array. Though all strings are character arrays, not all character arrays are strings. For example:

```
char a[3] = { 'c', 'a', 't' };
```

[](/book/tiny-c-projects/chapter-7/)This statement creates a *char* array `a[]`. It contains three characters: c-a-t. This array is not a string. The following *char* array, however, is a string:

```
char b[4] = { 'c', 'a', 't', '\0'};
```

[](/book/tiny-c-projects/chapter-7/)Array `b[]` contains four characters: c-a-t plus the null character. This terminating null character makes the array a string. It can be processed by any C language string function or output as a string.

[](/book/tiny-c-projects/chapter-7/)To save you time, and to keep the keyboard’s apostrophe key from wearing out, the C compiler lets you craft strings by enclosing characters in double quotes:

```
char c[4] = "cat";
```

[](/book/tiny-c-projects/chapter-7/)Array `c[]` is a string. It consists of four characters, c-a-t, plus the null character added automatically by the compiler. Though this character doesn’t appear in the statement, you must account for it when allocating storage for the string—always! If you declare a string like this:

```
char d[3] = "cat";
```

[](/book/tiny-c-projects/chapter-7/)the compiler allocates three characters for c-a-t, but none for the null character. This declaration might be flagged by the compiler—or it might not. Either way, the string is malformed, and, minus the terminating null character, manipulating or outputting the string yields unpredictable and potentially wacky results.

[](/book/tiny-c-projects/chapter-7/)Because the compiler automatically allocates storage for a string, the following declaration format is used most often:

```
char e[] = "cat";
```

[](/book/tiny-c-projects/chapter-7/)With empty brackets, the compiler calculates the string’s storage and assigns the proper number of elements to the array, including the null character.

[](/book/tiny-c-projects/chapter-7/)Especially when building your own strings, you must take care to account for the terminating null character: storage must be allocated for it, and your code must ensure that the final character in the string is the `\0`.

[](/book/tiny-c-projects/chapter-7/)Here are some string considerations:

-  [](/book/tiny-c-projects/chapter-7/)When allocating string storage, always add one for the null character. Strings are allocated directly as a *char* array declaration[](/book/tiny-c-projects/chapter-7/) or via a memory-allocation function such as *malloc[](/book/tiny-c-projects/chapter-7/)()*.
-  [](/book/tiny-c-projects/chapter-7/)When using string storage, remember that the final character in storage must be the null character, whether or not the buffer is full.
-  [](/book/tiny-c-projects/chapter-7/)The *fgets()* function[](/book/tiny-c-projects/chapter-7/), often used to read string input, automatically accounts for the null character in its second argument, `size`. So, if you use the value 32 as the `size` argument in an *fgets()* statement, the function stores up to 31 characters before it automatically adds the null character to terminate the input string.
-  [](/book/tiny-c-projects/chapter-7/)Without the terminating null character, string functions continuing processing bytes until the next random null character is encountered. The effect could be garbage output or—worse—a segmentation fault.
-  [](/book/tiny-c-projects/chapter-7/)One problem with forgetting the null is that often memory is already packed with null characters. A buffer can overflow, but the random null characters already in memory prevent output from looking bad—and from your mistake being detected. Never rely upon null characters sitting in memory.
-  [](/book/tiny-c-projects/chapter-7/)The null character is necessary to terminate a string but not required. The compiler doesn’t check for it—how could it? This lack of confirmation, of string containment, is what makes strings squishy in [](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)C.

### [](/book/tiny-c-projects/chapter-7/)7.1.2 Measuring a string

[](/book/tiny-c-projects/chapter-7/)The [](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)title of this section has a completely different definition for my grandmother. No, she doesn’t code, but she crochets. The strings are longer in crocheting, but in programming you don’t use the word skein. Instead, you fuss over character count.

[](/book/tiny-c-projects/chapter-7/)As stored in memory, a string is one character longer than its text, this extra character being the null character terminating the string. It’s part of the string but not “in” the string.

[](/book/tiny-c-projects/chapter-7/)According to the *strlen()* function[](/book/tiny-c-projects/chapter-7/), the string is only as long as its number of characters, minus one for the nonprinting null character.

[](/book/tiny-c-projects/chapter-7/)So, how long is the string?

[](/book/tiny-c-projects/chapter-7/)The *man* page[](/book/tiny-c-projects/chapter-7/) for the *strlen()* describes its purpose:

```
The strlen() function calculates the length of the string . . .
excluding the terminating null byte ('\0').
```

[](/book/tiny-c-projects/chapter-7/)The *strlen[](/book/tiny-c-projects/chapter-7/)()* counts the number of characters in the string, with escaped characters counted as a single character. For example, the newline `\n` is a single character, though it occupies two character positions. The tab `\t` is also a single character, though the terminal may translate it into multiple spaces when output.

[](/book/tiny-c-projects/chapter-7/)Regardless of the nits I pick, the value returned by *strlen()* can be used elsewhere in the code to manipulate all characters in the string without violating the terminating null character or double-counting escaped characters. If you want to include the null character in the string’s size, you can use the sizeof operator[](/book/tiny-c-projects/chapter-7/), but be aware that this trick works only on statically allocated strings (otherwise, the pointer size is returned).

[](/book/tiny-c-projects/chapter-7/)In the following listing, a comparison is made between values returned by *strlen()* and *sizeof*. A string `s[]` is declared at line 6, which contains 10 characters. The *printf()* statement[](/book/tiny-c-projects/chapter-7/) at line 8 outputs the string’s *strlen()* value. The *printf()* statement[](/book/tiny-c-projects/chapter-7/) at line 9 outputs the string’s *sizeof* value.

##### Listing 7.1 Source code for string_size.c

```
#include <stdio.h>
#include <string.h>
 
int main()
{
    char s[] = "0123456789";     #1
 
    printf("%s is %lu characters long\n",s,strlen(s));
    printf("%s occupies %zu bytes of storage\n",s,sizeof(s));
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-7/)Here’s the output:

```
0123456789 is 10 characters long
0123456789 occupies 11 bytes of storage
```

[](/book/tiny-c-projects/chapter-7/)The *strlen()* function[](/book/tiny-c-projects/chapter-7/) returns the number of characters in the string; *sizeof* returns the amount of storage the string occupies—essentially `strlen()+1`, though, if the string is smaller than its allocated buffer size, *sizeof* returns the buffer size and not `strlen()+1`. If you make this change to line 6 in the code:

```
char s[20] = "0123456789";     #1
```

[](/book/tiny-c-projects/chapter-7/)Here is the updated output:

```
0123456789 is 10 characters long
0123456789 occupies 20 bytes of storage
```

[](/book/tiny-c-projects/chapter-7/)Despite the larger buffer size, the null character still sits at element 10 (the 11th character) in the `s[]` array. The remainder of the buffer is considered garbage but is still reported as the string’s “size” by the *sizeof* operator[](/book/tiny-c-projects/chapter-7/).

[](/book/tiny-c-projects/chapter-7/)Measuring a string also comes into play with the grand philosophical debate over what is a null string and what is an empty string. The difference is relevant in other programming languages, where a string can be explicitly defined as being either null or empty. In C, with its weak data types and squishy strings, the difference is less obvious. Consider the following:

```
char a[5] = { '\0' };
char b[5];
```

[](/book/tiny-c-projects/chapter-7/)Of the two arrays, `a[]` and `b[]`, which is the null string and which is the empty string?

[](/book/tiny-c-projects/chapter-7/)You may think that C doesn’t care about which string is which. Obviously, array `a[]` is initialized and `b[]` is not. The rest of the discussion is semantics, but according to computer science, `a[]` is the empty string and `b[]` is the null string.

[](/book/tiny-c-projects/chapter-7/)In the next listing, I perform a test comparing the two strings, empty `a[]` and null `b[]`, to see whether the compiler notices the difference between a null string or an empty string. The *strcmp()* function[](/book/tiny-c-projects/chapter-7/) is used, which returns zero when both strings are identical.

##### Listing 7.2 Source code for empty-null.c

```
#include <stdio.h>
#include <string.h>
 
int main()
{
    char a[5] = { '\0' };                                                #1
    char b[5];                                                           #2
 
    if( strcmp(a,b)==0 )                                                 #3
        puts("Strings are the same");
    else
        puts("Strings are not the same");
    printf("Length: a=%lu b=%lu\n",strlen(a),<linearrow />strlen(b));    #4
    printf("Storage: a=%zu b=%zu\n",sizeof(a), ),<linearrow /sizeof(b)); #5
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-7/)The program’s output describes how the strings are seen internally:

```
Strings are not the same
Length: a=0 b=4
Storage: a=5 b=5
```

[](/book/tiny-c-projects/chapter-7/)Of course, there’s always a random chance that the garbage in memory for string `b[]` may match up with the contents of string `a[]`. Therefore, even this output can’t truly be trusted. I mean, why does `strlen(b)` return the value 4?

[](/book/tiny-c-projects/chapter-7/)As far as strings in C are concerned, I prefer to think of a null string as uninitialized. An empty string is an easier concept to understand. After all, it’s completely legitimate in C to have a string that contains only the terminating null character: such a string’s length is zero. It can be manipulated by all string functions. Beyond these curiosities, however, you can leave the debate over “empty string” and “null string” to the grand viziers of other, trendier programming [](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)languages.

### [](/book/tiny-c-projects/chapter-7/)7.1.3 Reviewing C string functions

[](/book/tiny-c-projects/chapter-7/)Many [](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)C language functions understand and process strings. The assumption is that the string is a *char* array that properly terminates. This format is how functions such as *printf()*[](/book/tiny-c-projects/chapter-7/), *puts[](/book/tiny-c-projects/chapter-7/)()*, *fgets[](/book/tiny-c-projects/chapter-7/)()*, and others deal with strings.

[](/book/tiny-c-projects/chapter-7/)String functions are prototyped in the `string.h` header file. Standard C library string manipulation functions are listed in table 7.2.

##### [](/book/tiny-c-projects/chapter-7/)Table 7.2 Common C library string functions[(view table figure)](https://drek4537l1klr.cloudfront.net/gookin/HighResolutionFigures/table_7-2.png)

| [](/book/tiny-c-projects/chapter-7/)Function | [](/book/tiny-c-projects/chapter-7/)Description |
| --- | --- |
| [](/book/tiny-c-projects/chapter-7/)*strcat*[](/book/tiny-c-projects/chapter-7/)*()* | [](/book/tiny-c-projects/chapter-7/)Appends one string to another, sticking both together |
| [](/book/tiny-c-projects/chapter-7/)*strncat*[](/book/tiny-c-projects/chapter-7/)*()* | [](/book/tiny-c-projects/chapter-7/)Sticks two strings together, but limited to a certain number of characters |
| [](/book/tiny-c-projects/chapter-7/)*strchr*[](/book/tiny-c-projects/chapter-7/)*()* | [](/book/tiny-c-projects/chapter-7/)Returns a pointer to the location of a specific character within a string |
| [](/book/tiny-c-projects/chapter-7/)*strcmp*[](/book/tiny-c-projects/chapter-7/)*()* | [](/book/tiny-c-projects/chapter-7/)Compares two strings, returning zero for a match |
| [](/book/tiny-c-projects/chapter-7/)*strncmp*[](/book/tiny-c-projects/chapter-7/)*()* | [](/book/tiny-c-projects/chapter-7/)Compares two strings up to a given length |
| [](/book/tiny-c-projects/chapter-7/)*strcoll*[](/book/tiny-c-projects/chapter-7/)*()* | [](/book/tiny-c-projects/chapter-7/)Compares two strings using locale information |
| [](/book/tiny-c-projects/chapter-7/)*strcpy*[](/book/tiny-c-projects/chapter-7/)*()* | [](/book/tiny-c-projects/chapter-7/)Copies characters from one string into another or into a buffer |
| [](/book/tiny-c-projects/chapter-7/)*strncpy*[](/book/tiny-c-projects/chapter-7/)*()* | [](/book/tiny-c-projects/chapter-7/)Copies a given number of characters from one string to another |
| [](/book/tiny-c-projects/chapter-7/)*strlen*[](/book/tiny-c-projects/chapter-7/)*()* | [](/book/tiny-c-projects/chapter-7/)Returns the number of characters in a string |
| [](/book/tiny-c-projects/chapter-7/)*strpbrk()*[](/book/tiny-c-projects/chapter-7/) | [](/book/tiny-c-projects/chapter-7/)Locates the first instance of a character from one string found in another |
| [](/book/tiny-c-projects/chapter-7/)*strrchr()*[](/book/tiny-c-projects/chapter-7/) | [](/book/tiny-c-projects/chapter-7/)Returns a pointer to character within a string, measured from the end of the string |
| [](/book/tiny-c-projects/chapter-7/)*strspn()*[](/book/tiny-c-projects/chapter-7/) | [](/book/tiny-c-projects/chapter-7/)Returns the position of specified characters in one string found in another |
| [](/book/tiny-c-projects/chapter-7/)*strcspn()*[](/book/tiny-c-projects/chapter-7/) | [](/book/tiny-c-projects/chapter-7/)Returns the position of specified characters in one string not found in another |
| [](/book/tiny-c-projects/chapter-7/)*strstr()*[](/book/tiny-c-projects/chapter-7/) | [](/book/tiny-c-projects/chapter-7/)Returns the position of one string found within another |
| [](/book/tiny-c-projects/chapter-7/)*strtok()*[](/book/tiny-c-projects/chapter-7/) | [](/book/tiny-c-projects/chapter-7/)Parses a string based on separator characters (called repeatedly) |
| [](/book/tiny-c-projects/chapter-7/)*strxfrm()*[](/book/tiny-c-projects/chapter-7/) | [](/book/tiny-c-projects/chapter-7/)Transforms one string into another based on locale information |

[](/book/tiny-c-projects/chapter-7/)Many string functions feature an “n” companion, such as *strcat[](/book/tiny-c-projects/chapter-7/)()* and *strncat[](/book/tiny-c-projects/chapter-7/)()*. The n indicates that the function counts characters or otherwise tries to avoid an overflow by setting a string size value.

[](/book/tiny-c-projects/chapter-7/)Though table 7.2 lists only common C library string functions, your compiler’s library may feature more. For example, the *strcasecmp()* function[](/book/tiny-c-projects/chapter-7/) works like *strcmp[](/book/tiny-c-projects/chapter-7/)()*, but it ignores letter case when making the comparison. (See chapter 11.) Also, the *strfry()* function[](/book/tiny-c-projects/chapter-7/) is available specifically with GNU C libraries. It randomly swaps characters in a string, similar to the *scramble()* function[](/book/tiny-c-projects/chapter-7/) discussed in chapter 6.

[](/book/tiny-c-projects/chapter-7/)Just to ensure that you’re always alarmed or confused, some compilers may also feature a `strings.h` header file. This header defines a few additional string functions, such as strcasecmp[](/book/tiny-c-projects/chapter-7/)(), with some C libraries. I don’t cover these functions in this [](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)chapter.

### [](/book/tiny-c-projects/chapter-7/)7.1.4 Returning versus modifying directly

[](/book/tiny-c-projects/chapter-7/)Functions [](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)that manipulate strings in C have two ways they can make their changes. The first is to return a modified version of the string. The second is to manipulate the passed string directly. Choosing an approach really depends on the function’s purpose.

[](/book/tiny-c-projects/chapter-7/)For example, the *strcat()* function[](/book/tiny-c-projects/chapter-7/) appends one string to another. Here is the man page format[](/book/tiny-c-projects/chapter-7/):

```
char *strcat(char *dest, const char *src);
```

[](/book/tiny-c-projects/chapter-7/)String `src` (source) is appended to the end of string `dest` (destination). The function assumes enough room is available in the `dest` buffer[](/book/tiny-c-projects/chapter-7/) to successfully append the string. Upon success, string `dest` contains both `dest` plus `src`. The function returns a pointer to `dest`. The *strcat()* function[](/book/tiny-c-projects/chapter-7/) is an example of manipulating a passed string directly.

[](/book/tiny-c-projects/chapter-7/)In the next listing, two strings are present in the *main()* function, `s1[]` and `s2[]`. It’s the job of the *strappend()* function[](/book/tiny-c-projects/chapter-7/) to stick both strings together, returning a pointer to the new, longer string. The secret is that within the *strappend()* function[](/book/tiny-c-projects/chapter-7/) is the *strcat()* function[](/book/tiny-c-projects/chapter-7/), and its value (the address of `dest`) is returned.

##### Listing 7.3 Source code for strcat.c

```
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
 
char *strappend(char *dest, char *src)
{
    return( strcat(dest,src) );          #1
}
 
int main()
{
    char s1[32] = "This is another ";    #2
    char s2[] = "fine mess!";
    char *s3;
 
    s3 = strappend(s1,s2);
    printf("%s\n",s3);
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-7/)The program’s output shows the concatenated string:

```
This is another fine mess!
```

[](/book/tiny-c-projects/chapter-7/)In this example, the function doesn’t really create a new string. It merely returns a pointer to the first string passed, which now contains both strings.

#### [](/book/tiny-c-projects/chapter-7/)Exercise 7.1

[](/book/tiny-c-projects/chapter-7/)Modify the source code for `strcat.c`. Remove the *strcat()* function[](/book/tiny-c-projects/chapter-7/) from the code, replacing it with your own code that sticks the contents of argument `src` to the end of argument `dest`. Do not use the *strcat()* function to accomplish this task! Instead, determine the size of the resulting string and allocate storage for it. The *strappend()* function[](/book/tiny-c-projects/chapter-7/) returns the address of the created string.

[](/book/tiny-c-projects/chapter-7/)You can further modify the code so that string `s1[]` holds only the text shown; it doesn’t need to allocate storage for the new string. Proper allocation is instead made within the *strappend()* function[](/book/tiny-c-projects/chapter-7/).

[](/book/tiny-c-projects/chapter-7/)My solution to this exercise is available in the online repository as `strappend.c`. Comments in the code explain my approach. Remember, this code demonstrates how a string function can create a new string as opposed to modifying a string passed as [](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)an [](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)argument.

## [](/book/tiny-c-projects/chapter-7/)7.2 String functions galore

[](/book/tiny-c-projects/chapter-7/)C [](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)has plenty of string functions, but apparently not enough for the grand poohbahs of those other programming languages. They disparage C as being weak on string manipulation. Of course, any function you feel is missing from the C library—one that happily dwells in some other, trendier programming language—can easily be coded. All you must do is remember to include the all-important terminating null character, and anything string-related is possible in C.

[](/book/tiny-c-projects/chapter-7/)In this section, I present a smattering of string functions, some of which exist in other programming languages, others of which I felt compelled to create because of some personal brain defect. Regardless, these functions prove that anything you can do with a string in those Johnny-come-lately programming languages is just as doable in C.

[](/book/tiny-c-projects/chapter-7/)Oh! One point to make: the functions found in other languages are sometimes called *methods* because they pertain to object-oriented programming. Well, *la-di-da*. I can call my car the Batmobile, but it’s still a Hyundai.

### [](/book/tiny-c-projects/chapter-7/)7.2.1 Changing case

[](/book/tiny-c-projects/chapter-7/)Functions [](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)that change text case in a string are common in other languages. In C, the ctype functions *toupper()* and *tolower()* convert single characters, letters of the alphabet to upper- or lowercase, respectively. These functions can easily be applied to an entire string. All you need to do is write a function that handles the task.

[](/book/tiny-c-projects/chapter-7/)The following listing shows the source code for `strupper.c`, which converts a string’s lowercase letters to uppercase. The string is modified within the function, where a *while* loop processes each character. If the character is in the range of `'a'` to `'z'`, its sixth bit is reset (changed to zero), which converts it to lowercase. (This bitwise manipulation is discussed in chapter 5.) The *strupper()* function[](/book/tiny-c-projects/chapter-7/) avoids using any ctype functions.

##### Listing 7.4 Source code for strupper.c

```
#include <stdio.h>
 
void strupper(char *s)
{
    while(*s)                        #1
    {
        if( *s>='a' && *s<='z' )     #2
        {
            *s &= 0xdf;              #3
        }
        s++;
    }
}
 
int main()
{
    char string[] = "Random STRING sample 123@#$";
 
    printf("Original string: %s\n",string);
    strupper(string);
    printf("Uppercase string: %s\n",string);
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-7/)Here is the program’s output:

```
Original string: Random STRING sample 123@#$
Uppercase string: RANDOM STRING SAMPLE 123@#$
```

[](/book/tiny-c-projects/chapter-7/)The *strupper()* function[](/book/tiny-c-projects/chapter-7/) could also convert characters to uppercase by performing basic math. Due to the layout of the ASCII table, the following statement also works:

```
*s -= 32;
```

[](/book/tiny-c-projects/chapter-7/)Subtracting 32 from each character’s ASCII value also converts it to lowercase.

[](/book/tiny-c-projects/chapter-7/)It’s easy to modify the *strupper()* function[](/book/tiny-c-projects/chapter-7/) to create a function that converts characters to lowercase. Here is how a *strlower()* function[](/book/tiny-c-projects/chapter-7/) may look:

```
void strlower(char *s)
{
    while(*s)
    {
        if( *s>='A' && *s<='Z' )     #1
        {
            *s += 32;                #2
        }
        s++;
    }
}
```

[](/book/tiny-c-projects/chapter-7/)The complete source code showing the *strlower()* function[](/book/tiny-c-projects/chapter-7/) is found in this book’s online repository as `strlower.c`.

#### [](/book/tiny-c-projects/chapter-7/)Exercise 7.2

[](/book/tiny-c-projects/chapter-7/)Write a function, *strcaps[](/book/tiny-c-projects/chapter-7/)()*, that capitalizes the first letter of every word in a string. Process the text “This is a sample string” or a similar string that contains several words written in lowercase, including at least one one-letter word. The function modifies the string directly as opposed to generating a new string.

[](/book/tiny-c-projects/chapter-7/)My solution is found in the online repository as `strcaps.c`. It contains comments that explain my [](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)approach.

### [](/book/tiny-c-projects/chapter-7/)7.2.2 Reversing a string

[](/book/tiny-c-projects/chapter-7/)The key to [](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)changing the order of characters in a string is knowing the string’s length—where it starts and where it ends.

[](/book/tiny-c-projects/chapter-7/)For the string’s start, the string’s variable name is used, which holds the base address. The string’s ending address isn’t stored anywhere; the code must find the string’s terminating null character and then use math to calculate the string’s size. This math isn’t required in other programming languages, where every aspect of the string is fully known. Further, in C the string can be malformed, which would make the process impossible.

[](/book/tiny-c-projects/chapter-7/)Figure 7.1 illustrates a string lounging in memory, with both array and pointer notation calling out some of its parts. The terminating null character marks the end of the string, wherever its location may be, measured as offset n from the string’s start.

![Figure 7.1 Measuring a string in memory](https://drek4537l1klr.cloudfront.net/gookin/Figures/07-01.png)

[](/book/tiny-c-projects/chapter-7/)The easiest way to locate the end of a string is to use the *strlen()* function[](/book/tiny-c-projects/chapter-7/). Add the function’s return value to the string’s starting location in memory to find the string’s end.

[](/book/tiny-c-projects/chapter-7/)For the do-it-yourself crowd, you can craft your own string-end function or loop to locate the string’s caboose. Assume that char pointer `s` references the string’s start and that *int* variable `len` is initialized to zero. If so, this *while* loop locates the string’s end, where the null character dwells:

```
while(*s++)
   len++;
```

[](/book/tiny-c-projects/chapter-7/)After this loop is complete, pointer `*s` references the string’s terminating null character, and the value of `len` is equal to the string’s length (minus the null character). Here is a more readable version of the loop:

```
while( *s != '\0' )
{
   len++;
   s++;
}
```

[](/book/tiny-c-projects/chapter-7/)The stupidest way to find the end of a string is to use the *sizeof* operator[](/book/tiny-c-projects/chapter-7/). The operator isn’t dumb, but when used on a *char* pointer argument, *sizeof* returns the number of bytes the pointer (memory address variable) occupies, not the size of the buffer the pointer references. For example, on my computer, a pointer is 4 bytes wide, so no matter what size buffer `*s` refers to, `sizeof(s)` always returns 4.

[](/book/tiny-c-projects/chapter-7/)After obtaining the string’s length, the reversing process works backgrounds through the string, copying each character into another buffer, front to back. The result is a new string containing the reverse character order of the original.

[](/book/tiny-c-projects/chapter-7/)The *strrev()* function[](/book/tiny-c-projects/chapter-7/) shown in the next listing creates a new string, `reversed`. First, a *while* loop calculates the string’s size (argument `*s`). Second, storage is allocated for the new string based on the original string’s size. I don’t need to +1 in the *malloc()* statement to make room for the null character, because variable `len`[](/book/tiny-c-projects/chapter-7/) already references the null character’s offset. Finally, a *while* loop processes string `s` backward as it fills string `reversed` with characters.

##### Listing 7.5 The *strrev()* function

```
char *strrev(char *s)
{
    int len,i;
    char *reversed;
 
    len = 0;                                     #1
    while( *s )                                  #2
    {
        len++;
        s++;
    }
 
    reversed = malloc( sizeof(char) * len );     #3
    if( reversed==NULL )
    {
        fprintf(stderr,"Unable to allocate memory\n");
        exit(1);
    }
 
    s--;                                         #4
    i = 0;                                       #5
    while(len)                                   #6
    {
        *(reversed+i) = *s;                      #7
        i++;                                     #8
        len--;                                   #9
        s--;                                     #10
    }
    *(reversed+i) = '\0';                        #11
 
    return(reversed);                            #12
}
```

[](/book/tiny-c-projects/chapter-7/)This function is included with the source code for `strrev.c`, found in the book’s online repository. In the *main()* function a sample string is output, and then the reversed string is output for comparison. Here’s a sample run:

```
Before: A string dwelling in memory
After: yromem ni gnillewd gnirts A
```

[](/book/tiny-c-projects/chapter-7/)This code shows only one way to create a string reversal function, though the general approach is the same for all variations: work the original string backward to create the new [](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)string.

### [](/book/tiny-c-projects/chapter-7/)7.2.3 Trimming a string

[](/book/tiny-c-projects/chapter-7/)String-truncating [](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)functions are popular in other programming languages. For example, I remember the `LEFT$`[](/book/tiny-c-projects/chapter-7/), `RIGHT$`[](/book/tiny-c-projects/chapter-7/), and `MID$` commands[](/book/tiny-c-projects/chapter-7/) from my days of programming in BASIC. These commands lack similar functions in C, but they’re easy enough to craft. Figure 7.2 gives you an idea of what each one does.

![Figure 7.2 Extracting portions of a string: left, middle, and right](https://drek4537l1klr.cloudfront.net/gookin/Figures/07-02.png)

[](/book/tiny-c-projects/chapter-7/)Each function requires at least two arguments: a string to slice and a character count. The middle extraction function also requires an offset. For my approach, I decided to return a new string containing the desired chunk, which leaves the original string intact.

[](/book/tiny-c-projects/chapter-7/)The next listing shows my concoction of a *left(* function[](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/), which extracts `len` characters[](/book/tiny-c-projects/chapter-7/) from the passed string `s`. As with each of these trimming functions, storage is allocated for a new string. The *left()* function[](/book/tiny-c-projects/chapter-7/) is the easiest to code because it copies the first `len` characters[](/book/tiny-c-projects/chapter-7/) of the passed string `s` into the target string `buf`. The address of `buf` is returned.

##### Listing 7.6 The *left()* function

```
char *left(char *s,int len)
{
    char *buf;                            #1
    int x;
 
    buf = malloc(sizeof(char)*len+1);     #2
    if( buf==NULL )
    {
        fprintf(stderr,"Memory allocation error\n");
        exit(1);
    }
 
    for(x=0;x<len;x++)                    #3
    {
        if( *(s+x)=='\0' )                #4
            break;
        *(buf+x) = *(s+x);                #5
    }
    *(buf+x) = '\0';                      #6
 
    return(buf);
}
```

[](/book/tiny-c-projects/chapter-7/)Figure 7.3 illustrates the guts of the left() function[](/book/tiny-c-projects/chapter-7/).

![Figure 7.3 The way the left() function slices a string](https://drek4537l1klr.cloudfront.net/gookin/Figures/07-03.png)

[](/book/tiny-c-projects/chapter-7/)Unlike the *left()* function[](/book/tiny-c-projects/chapter-7/), chopping off the right side of a string requires that the program knows where the string ends. From the preceding section, you recall that C doesn’t track a string’s tail. Your code must hunt down that terminating null character. For the *right()* function[](/book/tiny-c-projects/chapter-7/), I count backward from the null character to lop off the right side of the string.

[](/book/tiny-c-projects/chapter-7/)My *right()* function[](/book/tiny-c-projects/chapter-7/) is shown in the following listing. It borrows its allocation routine from the *left()* function[](/book/tiny-c-projects/chapter-7/) shown in listing 7.6. After the buffer is created, the code hunts for the end of the string, moving the pointer `start` to this location. Then the value of `len` is subtracted from `start` to reposition the pointer to the beginning of the right-end string chunk desired. Then `len` number of characters are copied into the new string.

##### Listing 7.7 The *right()* function

```
char *right(char *s,int len)
{
    char *buf;
    char *start;
    int x;
 
    buf = (char *)malloc(sizeof(char)*len+1);
    if( buf==NULL )
    {
        fprintf(stderr,"Memory allocation error\n");
        exit(1);
    }
 
    start = s;                #1
    while(*start!='\0')       #2
       start++;
    start -= len;             #3
    if( start < s )           #4
        exit(1);
 
    for(x=0;x<len;x++)        #5
        *(buf+x) = *(start+x);
    *(buf+x) = '\0';          #6
 
    return(buf);
}
```

[](/book/tiny-c-projects/chapter-7/)The *right()* function’s[](/book/tiny-c-projects/chapter-7/) operation is illustrated in figure 7.4.

![Figure 7.4 The calculations made to extract the right side of a string](https://drek4537l1klr.cloudfront.net/gookin/Figures/07-04.png)

[](/book/tiny-c-projects/chapter-7/)The final string-trimming function is really the only one you need: when given the proper arguments, the mid() function[](/book/tiny-c-projects/chapter-7/) can easily substitute for the *left[](/book/tiny-c-projects/chapter-7/)()* or *right()* functions[](/book/tiny-c-projects/chapter-7/). In fact, these two functions could be macros based on *mid()*. I blab more on this topic in a few paragraphs.

[](/book/tiny-c-projects/chapter-7/)My *mid()* function[](/book/tiny-c-projects/chapter-7/) has three arguments:

```
char *mid(char *s, int offset, int len);
```

[](/book/tiny-c-projects/chapter-7/)Pointer `s` references the string to slice. Integer `offset`[](/book/tiny-c-projects/chapter-7/) is the character position to start extraction. And integer `len`[](/book/tiny-c-projects/chapter-7/) is the number of characters to extract.

[](/book/tiny-c-projects/chapter-7/)The full *mid()* function[](/book/tiny-c-projects/chapter-7/) is shown in listing 7.8. It performs a straight character-by-character copy from the passed string `s` into the new string buffer `buf`[](/book/tiny-c-projects/chapter-7/). The key, however, is adding the `offset` value when passing the characters:

```
*(buf+x) = *(s+offset-1+x)
```

[](/book/tiny-c-projects/chapter-7/)The `offset` value must be reduced by 1 to account for the fact that characters in the string start at offset 0, not offset 1. If I were to write documentation for the function, I’d need to explain that valid values for argument offset are in the range of 1 through the string’s length. Unlike in C coding, you don’t want to start with zero—though you could. Again, state so in the function’s documentation.

##### Listing 7.8 The *mid()* function

```
char *mid(char *s, int offset, int len)
{
    char *buf;
    int x;
 
    buf = (char *)malloc(sizeof(char)*len+1);
    if( buf==NULL )
    {
        fprintf(stderr,"Memory allocation error\n");
        exit(1);
    }
 
    for(x=0;x<len;x++)                 #1
    {
        *(buf+x) = *(s+offset-1+x);    #2
        if( *(buf+x)=='\0')            #3
            break;
    }
    *(buf+x) = '\0';                   #4
 
    return(buf);
}
```

[](/book/tiny-c-projects/chapter-7/)Figure 7.5 illustrates how the *mid()* function[](/book/tiny-c-projects/chapter-7/) operates.

![Figure 7.5 The operations of the mid() function](https://drek4537l1klr.cloudfront.net/gookin/Figures/07-05.png)

[](/book/tiny-c-projects/chapter-7/)As I wrote earlier, the *left[](/book/tiny-c-projects/chapter-7/)()* and *right()* functions[](/book/tiny-c-projects/chapter-7/) are easily reproduced by using specific formats for the *mid()* function[](/book/tiny-c-projects/chapter-7/). If you were to write a macro for the *left()* function[](/book/tiny-c-projects/chapter-7/), you could use this format:

```
#define left(s,n) mid(s,1,n)
```

[](/book/tiny-c-projects/chapter-7/)With an offset of 1, this mid() function[](/book/tiny-c-projects/chapter-7/) returns the leftmost `len` characters[](/book/tiny-c-projects/chapter-7/) of string `s`. (Remember, the `offset` value is reduced by 1 in the *mid()* function[](/book/tiny-c-projects/chapter-7/).)

[](/book/tiny-c-projects/chapter-7/)Crafting the *right()* function[](/book/tiny-c-projects/chapter-7/) equivalent of *mid()* requires that the string’s length be obtained in the call:

```
#define right(s,n) mid(s,strlen(s)-n,n)
```

[](/book/tiny-c-projects/chapter-7/)The second argument is the string’s length (obtained by the *strlen()* function[](/book/tiny-c-projects/chapter-7/)), minus the number of characters desired. It bothers me to call the *strlen()* function[](/book/tiny-c-projects/chapter-7/) in a macro, but my point is more to show that the true power function for string slicing is the *mid()* function[](/book/tiny-c-projects/chapter-7/).

[](/book/tiny-c-projects/chapter-7/)You can find all these string-trimming functions—*left[](/book/tiny-c-projects/chapter-7/)()*, *right[](/book/tiny-c-projects/chapter-7/)()*, and *mid[](/book/tiny-c-projects/chapter-7/)()*—in the source code file `trimming.c`, found in this book’s online [](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)repository.

### [](/book/tiny-c-projects/chapter-7/)7.2.4 Splitting a string

[](/book/tiny-c-projects/chapter-7/)I [](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)wrote my string-splitting function out of spite. Another programmer, a disciple of one of those fancy new languages, scoffed, “You can’t even split a string in C with fewer than 20 lines of code.”

[](/book/tiny-c-projects/chapter-7/)Challenge accepted.

[](/book/tiny-c-projects/chapter-7/)Though I can easily code a string-splitting function in C with fewer than 20 lines of code, one point I must concede is that such a function requires at least four arguments:

```
int strsplit(char *org,int offset,char **s1,char **s2)
```

[](/book/tiny-c-projects/chapter-7/)Pointer `org`[](/book/tiny-c-projects/chapter-7/) references the string to split. Integer `offset`[](/book/tiny-c-projects/chapter-7/) is the location of the split. And the last two pointers, `s1` and `s2`, contain the two sides of the split. These pointers are passed by reference, which allows the function to access and modify their contents.

[](/book/tiny-c-projects/chapter-7/)The next listing shows my *strsplit()* function[](/book/tiny-c-projects/chapter-7/), with its cozy 15 lines of code—and no obfuscation. I used white space and indents as I normally do. The size of the original string is obtained and used to allocate storage for `s1` and `s2`. Then the *strncpy()* function[](/book/tiny-c-projects/chapter-7/) copies the separate portions of the original string into the separate strings. The function returns 1 upon success, and 0 when things foul up.

##### Listing 7.9 The *strsplit()* function

```
int strsplit(char *org,int offset,char **s1,char **s2)
{
    int len;
 
    len = strlen(org);                              #1
    if(offset > len)                                #2
        return(0);
    *s1 = malloc(sizeof(char) * offset+1);          #3
    *s2 = malloc(sizeof(char) * len-offset+1);      #4
    if( s1==NULL || s2==NULL )                      #5
        return(0);
    strncpy(*s1,org,offset);                        #6
    strncpy(*s2,org+offset,len-offset);             #6
    return(1);
}
```

[](/book/tiny-c-projects/chapter-7/)The *strsplit()* function[](/book/tiny-c-projects/chapter-7/) you see in listing 7.9 is my first version, where my goal was to see how few lines of code I could use. It calls C library string functions to perform some of the basic operations, which means this version of the *strsplit()* function[](/book/tiny-c-projects/chapter-7/) relies upon the `string.h` header file. I wrote another version that avoids using the string library functions, though its code is obviously much longer.

[](/book/tiny-c-projects/chapter-7/)The *strsplit()* function[](/book/tiny-c-projects/chapter-7/) shown in listing 7.9 is found in the online repository in the `strsplit.c` source code [](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)file.

### [](/book/tiny-c-projects/chapter-7/)7.2.5 Inserting one string into another

[](/book/tiny-c-projects/chapter-7/)When [](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)I originally thought of writing a string insertion function, I figured I’d use two C library string functions to accomplish the task: *strcpy[](/book/tiny-c-projects/chapter-7/)()* and *strcat[](/book/tiny-c-projects/chapter-7/)()*. These functions can build the string one step at a time: the *strcpy()* function[](/book/tiny-c-projects/chapter-7/) copies one string to another, duplicating a string in another array or chunk of memory. The *strcat()* function[](/book/tiny-c-projects/chapter-7/) sticks one string onto the end of another, creating a larger string. The inserted string is pieced together: original string, plus insert, plus the rest of the original string.

[](/book/tiny-c-projects/chapter-7/)The function would have this declaration:

```
int strinsert(char *org, char *ins, int offset);
```

[](/book/tiny-c-projects/chapter-7/)Pointer `org`[](/book/tiny-c-projects/chapter-7/) is the original string, which must be large enough to accommodate the inserted text. Pointer `ins`[](/book/tiny-c-projects/chapter-7/) is the string to insert; integer `offset`[](/book/tiny-c-projects/chapter-7/) is the location (starting with 1) at which string `ins` is inserted into string `org`.

[](/book/tiny-c-projects/chapter-7/)My *strinsert()* function[](/book/tiny-c-projects/chapter-7/) returns 1 upon success, 0 on error.

[](/book/tiny-c-projects/chapter-7/)It didn’t work.

[](/book/tiny-c-projects/chapter-7/)The problem with using *strcpy[](/book/tiny-c-projects/chapter-7/)()* and *strcat[](/book/tiny-c-projects/chapter-7/)()* is that I must split the original string, save the remainder, and then build final string. This step requires a temporary buffer for the remainder of string `org` at position `offset`, as illustrated in figure 7.6. Then string `ins` is concatenated to the new end of string `org`, then the original end of string `org` is concatenated to the result. Messy.

![Figure 7.6 The process of using string library functions makes inserting a string overly complex.](https://drek4537l1klr.cloudfront.net/gookin/Figures/07-06.png)

[](/book/tiny-c-projects/chapter-7/)Further, as shown in figure 7.6, the hope is that the user has allocated enough storage for the original string `org` to accommodate the inserted text. To me, this hope is too risky, so I changed my approach. Here is the function’s updated declaration:

```
char *strinsert(char *org, char *ins, int offset);
```

[](/book/tiny-c-projects/chapter-7/)The function’s return value is a newly created string, which avoids the necessity that string `org` be large enough to also accommodate inserting string `ins`. Returning the string, that is, creating it within the function, also avoids having to temporarily store the remainder of string `org` for concatenation later.

[](/book/tiny-c-projects/chapter-7/)In this new approach, I build the new string character by character, inserting string `ins` at `offset` characters[](/book/tiny-c-projects/chapter-7/) as the new string is built. Figure 7.7 illustrates how the improved version of the function operates.

![Figure 7.7 The improved technique for inserting one string into another](https://drek4537l1klr.cloudfront.net/gookin/Figures/07-07.png)

[](/book/tiny-c-projects/chapter-7/)Rather than use the *strcat*[](/book/tiny-c-projects/chapter-7/)() and *strcpy()* functions[](/book/tiny-c-projects/chapter-7/), my improved version of the *strinsert()* function[](/book/tiny-c-projects/chapter-7/) copies characters sequentially from string `org` into a newly created buffer, `new`[](/book/tiny-c-projects/chapter-7/). Once the character count is equal to `offset`, characters are copied from string `ins` into the newly created buffer. After that, the count continues from string `org`.

[](/book/tiny-c-projects/chapter-7/)You find the full *strinsert()* function[](/book/tiny-c-projects/chapter-7/) in the following listing. It builds the string `new` character by character from arguments `org` and `ins`. The C library’s *strlen()* function[](/book/tiny-c-projects/chapter-7/) is used; otherwise, the string is built using statements within the function.

##### Listing 7.10 The *strinsert()* function

```
char *strinsert(char *org, char *ins, int offset)
{
    char *new;
    int size,index,append;
 
    size = strlen(org)+strlen(ins);         #1
    if( offset<0 )                          #2
        return(NULL);
 
    new = malloc(sizeof(char) * size+1);    #3
    if( new==NULL )
    {
        fprintf(stderr,"Memory allocation error\n");
        exit(1);
    }
 
    offset -= 1;                            #4
    index = 0;                              #5
    append = 0;                             #6
    while( *org )                           #7
    {
        if( index==offset )                 #8
        {
            while( *ins )                   #9
            {
                *(new+index) = *ins;
                index++;
                ins++;
            }
            append = 1;                     #10
        }
        *(new+index) = *org;                #11
        index++;
        org++;
    }
    if( !append )                           #12
    {
        while( *ins )
        {
            *(new+index) = *ins;
            index++;
            ins++;
        }
    }
    *(new+index) = '\0';                    #13
 
    return(new);
}
```

[](/book/tiny-c-projects/chapter-7/)In the function, I tried to handle a condition when the `offset` argument is larger than the length of string `org`. I couldn’t quite get it to work, so I decided to use the out-of-range value as a feature: if the value of `offset` is longer than string `org`, string `ins` is appended to string `org` regardless of the `offset` value.

[](/book/tiny-c-projects/chapter-7/)You can find the *strinsert()* function[](/book/tiny-c-projects/chapter-7/) inside the source code file `strinsert.c` in this book’s online repository. Here is the program’s output, where the string “fine” (plus a space) is inserted into the string “Well, this is another mess!” at [](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)offset 23:

```
Before: Well, this is another mess!
After: Well, this is another fine mess!
```

### [](/book/tiny-c-projects/chapter-7/)7.2.6 Counting words in a string

[](/book/tiny-c-projects/chapter-7/)To [](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)solve the puzzle of counting words in a string, you must write code that recognizes when a word starts. You’ve already written such code if you completed exercise 7.2, which capitalizes the first character of words in a string. The *strcaps()* function[](/book/tiny-c-projects/chapter-7/) can be modified to count words rather than convert characters to uppercase.

[](/book/tiny-c-projects/chapter-7/)The next listing shows an update to my solution for exercise 7.2 (do you regret reading this chapter front-to-back?), where the *strwords()* function[](/book/tiny-c-projects/chapter-7/) consumes a string’s characters in sequence, one after the other. The variable `inword`[](/book/tiny-c-projects/chapter-7/) determines whether the current character is inside a word. Each time a new word starts, variable `count`[](/book/tiny-c-projects/chapter-7/) is incremented.

##### Listing 7.11 The *strwords()* function inside source code strwords.c

```
#include <stdio.h>
#include <ctype.h>
 
int strwords(char *s)
{
    enum { FALSE, TRUE };         #1
    int inword = FALSE;           #2
    int count;
 
    count = 0;                    #3
    while(*s)                     #4
    {
        if( isalpha(*s) )         #5
        {
            if( !inword )         #6
            {
                count++;          #7
                inword = TRUE;    #8
            }
        }
        else
        {
            inword = FALSE;       #9
        }
        s++;
    }
 
    return(count);
}
 
int main()
{
    char string[] = "This is a sample string";
 
    printf("The string '%s' contains %d words\n",
            string,
            strwords(string)
          );
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-7/)Here is a sample run of the `strwords.c` program[](/book/tiny-c-projects/chapter-7/):

```
The string 'This is a sample string' contains 5 words
```

[](/book/tiny-c-projects/chapter-7/)If you change the word is to isn’t in the string, here is the modified output:

```
The string 'This isn't a sample string' contains 6 words
```

[](/book/tiny-c-projects/chapter-7/)Hmmm.

#### [](/book/tiny-c-projects/chapter-7/)Exercise 7.3

[](/book/tiny-c-projects/chapter-7/)Modify the *strwords()* function[](/book/tiny-c-projects/chapter-7/) shown in listing 7.11 so that it accounts for contractions. This task has a simple solution, one that’s presented in the first C language programming book, *The C Programming Language*[](/book/tiny-c-projects/chapter-7/), by Brian Kernighan[](/book/tiny-c-projects/chapter-7/) and Dennis Ritchie (Pearson, 1988).[](/book/tiny-c-projects/chapter-7/) Without cheating, see if you can accomplish the same task.

[](/book/tiny-c-projects/chapter-7/)My solution is titled `strwords2.c`, and it’s available in this book’s online [](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)repository.

### [](/book/tiny-c-projects/chapter-7/)7.2.7 Converting tabs to spaces

[](/book/tiny-c-projects/chapter-7/)The [](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)terminal you use in Linux is smart enough to output tab characters to the next virtual tab stop on the display. These tab stops are set at 8 characters by default. Some shells, such as *bash*[](/book/tiny-c-projects/chapter-7/) and *zsh*[](/book/tiny-c-projects/chapter-7/), feature the *tabs* command[](/book/tiny-c-projects/chapter-7/), which can set the tab stops to a different character interval: for example, tabs 4 sets a terminal tab stop that is 4 characters wide.

[](/book/tiny-c-projects/chapter-7/)The following *printf()* statement[](/book/tiny-c-projects/chapter-7/) outputs a string with two tab characters:

```
printf("Hello\tHi\tHowdy\n");
```

[](/book/tiny-c-projects/chapter-7/)Here is the output:

```
Hello   Hi      Howdy
```

[](/book/tiny-c-projects/chapter-7/)The tab character didn’t expand to a constant number of characters. Instead, it’s interpreted by the shell and expanded to the next virtual tab stop at 8-character intervals across the display. This effect ensures that columns line up perfectly as you use tabs to line up text or create tables.

[](/book/tiny-c-projects/chapter-7/)Obviously, you don’t need to convert tabs into spaces for output on the terminal. But one function you can write is one that sets variable-width tab stops in a program’s output. The width for these tab stops is created by outputting spaces; this book doesn’t go into terminal hardware programming.

[](/book/tiny-c-projects/chapter-7/)To set a tab stop, you must know where text output is going across the screen—the current column value. This value is compared with the tab stop width desired, using the following equation:

```
spaces = tab - (column % tab)
```

[](/book/tiny-c-projects/chapter-7/)Here is how this statement works out:

![](https://drek4537l1klr.cloudfront.net/gookin/Figures/07-07_UN01.png)

[](/book/tiny-c-projects/chapter-7/)The `(column` `%` `tab)` expression returns the number of spaces since the last tab stop interval (`tab`) based on the cursor’s current column offset (`column`). To obtain the number of spaces until the next tab stop, this value is subtracted from the tab stop width. The result is the number of spaces required to line up the next character output with a tab stop.

[](/book/tiny-c-projects/chapter-7/)The tab calculation equation exists as a statement in the *strtabs()* function[](/book/tiny-c-projects/chapter-7/), shown in the next listing. The function outputs a string, carefully checking each character for the tab, `\t`. When encountered, the next tab stop offset is calculated, and the given number of spaces are output.

##### Listing 7.12 The *strtabs()* function inside source code file strtabs.c

```
#include <stdio.h>
 
void strtabs(const char *s, int tab)
{
    int column,x,spaces;
 
    column = 0;                               #1
    while(*s)                                 #2
    {
        if( *s == '\t')                       #3
        {
            spaces = tab - (column % tab);    #4
            for( x=0; x<spaces; x++ )         #5
                putchar(' ');
            column += spaces;                 #6
        }
        else                                  #7
        {
            putchar(*s);
            if( *s=='\n' )                    #8
                column = 0;
            else
                column++;
        }
        s++;
    }
}
 
/* calculate and display a tab */
int main()
{
    const char *text[3] = {
      "Hello\tHi\tHowdy\n",
      "\tLa\tLa\n",
      "Constantinople\tConstantinople\n"
    };
    int x,y;
 
    for(y=4;y<32;y*=2)                        #9
    {
        printf("Tab width: %d\n",y);
        for(x=0;x<3;x++)
        {
            strtabs(text[x],y);
        }
    }
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-7/)The program’s output generates three strings, with different tab patterns using three different tab stop settings. Here’s the output:

```
Tab width: 4
Hello   Hi  Howdy
   La  La
Constantinople  Constantinople
Tab width: 8
Hello   Hi      Howdy
       La      La
Constantinople  Constantinople
Tab width: 16
Hello           Hi              Howdy
               La              La
Constantinople  Constantinople
```

[](/book/tiny-c-projects/chapter-7/)When the terminal window encounters a tab, it doesn’t convert the tab into multiple spaces like the `strtabs.c` program[](/book/tiny-c-projects/chapter-7/) does. For the terminal window, the cursor itself moves the required number of character positions across the screen; spaces aren’t output. To prove so, take the standard output of some program that generates tabs and look at the raw data. You see tab characters (ASCII 9) instead of a series [](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)of [](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)spaces.

## [](/book/tiny-c-projects/chapter-7/)7.3 A string library

[](/book/tiny-c-projects/chapter-7/)One [](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)of the best ways to put all string-manipulation functions to work, or to deal with any targeted collection of functions, is to create your own custom library. It’s a way to share the functions with others or have them ready for yourself in a practical way.

[](/book/tiny-c-projects/chapter-7/)You know about other libraries and have probably used them, such as the math library. Creating these tools isn’t that difficult, nor is knowing how to create them a secret: if you know how to compile code, you can create a library.

[](/book/tiny-c-projects/chapter-7/)All C libraries are created by someone—some clever coder who cobbles together functions and other elements required to let you share in their genius. Even the C standard library is written and maintained by C coders, the high lords of the programming realm.

[](/book/tiny-c-projects/chapter-7/)Using your string library is as easy as using another library; your string library is linked into the object code file at build time. The functions are prototyped and supported by a custom header file. Everything works for your library just as it does for other libraries.

[](/book/tiny-c-projects/chapter-7/)For the string library, I’ll include many of the functions demonstrated in this chapter. If you have additional, favorite string functions, feel free to add them as well. Directions throughout this section explain the details and offer tips for creating your own custom library.

### [](/book/tiny-c-projects/chapter-7/)7.3.1 Writing the library source and header file

[](/book/tiny-c-projects/chapter-7/)Creating [](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)a library starts with a source code editor. Your goal is to create two files at minimum:

-  [](/book/tiny-c-projects/chapter-7/)A source code file
-  [](/book/tiny-c-projects/chapter-7/)A header file containing the functions’ prototypes

[](/book/tiny-c-projects/chapter-7/)The source code is one or more files (depending on how you work) containing all the functions for the library—just the functions. You don’t need a *main()* function, because you’re building a library, not a program. This file is compiled just like any other source code file, but it’s not linked. You need only the object code file, .o, to create the library.

[](/book/tiny-c-projects/chapter-7/)The library also requires a header file, which contains the function prototypes’s defined constants, necessary includes, and other goodies that assist the functions. For example, if a function uses a structure, it must be declared in the source code file as well as in the header file. Programmers who use your library need the structure definition to make the function work. The header file is where you put these things, and it’s where they’re referenced when programmers use your library.

[](/book/tiny-c-projects/chapter-7/)In listing 7.13, you see the first part of the `mystring.c` source code file, which contains many of the string functions demonstrated in this chapter. The file has descriptive comments, which can be expanded to show version history, offer tips, and provide examples. The `#include` directives[](/book/tiny-c-projects/chapter-7/) in the source code file are required for the functions, just as they would be in any source code file. Further, see how I’ve feebly attempted to document each function, showing the arguments and return value? Yes, this information can be expanded upon; documentation is good.

##### Listing 7.13 The first part of the mystring.c library source code file

```
/* mystring library */                   #1
/* 10 September 2021 */                  #1
/* Dan Gookin, dan@gookin.com */         #1
 
#include <stdio.h>                       #2
#include <stdlib.h>                      #2
#include <string.h>                      #2
#include <ctype.h>                       #2
 
/* Return the left portion of a string   #3
   s = string                            #3
   len = length to cut from the left     #3
   return value: new string              #3
 */  
char *left(char *s,int len)              #4
{
```

[](/book/tiny-c-projects/chapter-7/)The order of the functions inside the source code file doesn’t matter—unless one function references another. In such a situation, ensure that the referenced function appears before (above) the function it’s referenced in.

[](/book/tiny-c-projects/chapter-7/)The companion header file for your library isn’t listed in the library’s source code file (refer to listing 7.13). The header file is necessary to provide support for programmers who use your library; only if items in the header file are referenced in the code (defined constants, for example) do you need to include the library’s header file in the source code file. Key to the header file are the function prototypes, structures, global/external variable definitions, macros, and defined constants.

[](/book/tiny-c-projects/chapter-7/)As with the library’s source code file, I recommend commenting the header file to document its parts. Be helpful to your programmer pals. Further, I add version number defined constants to my header files, as shown here.

##### Listing 7.14 The mystring.h header file to support the mystring library

```
/* mystring library header file */                       #1
/* 10 September 2021 */                                  #1
/* Dan Gookin, dan@gookin.com */                         #1
 
#define mystring_version "1.0"                           #2
#define mystring_version_major 1                         #2
#define mystring_version_minor 0                         #2
 
char *left(char *s,int len);                             #3
char *mid(char *s, int offset, int len);                 #3
char *right(char *s,int len);                            #3
void strcaps(char *s);                                   #3
char *strinsert(char *org, char *ins, int offset);       #3
void strlower(char *s);                                  #3
char *strrev(char *s);                                   #3
int strsplit(char *org,int offset,char **s1,char **s2);  #3
void strtabs(const char *s, int tab);                    #3
void strupper(char *s);                                  #3
int strwords(char *s);                                   #3
```

[](/book/tiny-c-projects/chapter-7/)Both files, the source code and header file, are necessary to use the [](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)library.

### [](/book/tiny-c-projects/chapter-7/)7.3.2 Creating a library

[](/book/tiny-c-projects/chapter-7/)Libraries [](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)are created from object code files. The *ar* (archive) utility[](/book/tiny-c-projects/chapter-7/) is what transforms the object code file into a library. Therefore, the first step to creating a library is to compile—but not link—your library’s source code file. Once you have the compiled object code, you use the *ar* utility to create the library.

[](/book/tiny-c-projects/chapter-7/)For this example, I’m using the `mystring.c` source code file, which is available from this book’s online code repository. To compile the source code into object code, the `-c` switch is[](/book/tiny-c-projects/chapter-7/) specified. This switch is available to all C compilers. Here is the command format for *clang*:

```
clang -Wall -c mystring.c
```

[](/book/tiny-c-projects/chapter-7/)The `-c` switch[](/book/tiny-c-projects/chapter-7/) directs *clang* to “compile only.” The source code file is compiled into object code, `mystring.o`[](/book/tiny-c-projects/chapter-7/), but it’s not linked to create a program. This step is repeated for all source code files, though you can specify the lot in a single command:

```
clang -Wall -c first.c second.c third.c
```

[](/book/tiny-c-projects/chapter-7/)For this command, three object code files are created: `first.o`, `second.o`, and `third.o`.

[](/book/tiny-c-projects/chapter-7/)The next step is to use the archive utility *ar* to build the library. This command is followed by three arguments: command switches, the name of the library file, and finally the object code files required to build the library. For example:

```
ar -rcs libmystring.a mystring.o
```

[](/book/tiny-c-projects/chapter-7/)Here are what the switches do:

-  [](/book/tiny-c-projects/chapter-7/)`-c`[](/book/tiny-c-projects/chapter-7/)—Creates the archive
-  [](/book/tiny-c-projects/chapter-7/)`-s`[](/book/tiny-c-projects/chapter-7/)—Indexes the archive
-  [](/book/tiny-c-projects/chapter-7/)`-r`[](/book/tiny-c-projects/chapter-7/)—Inserts file(s) into the archive

[](/book/tiny-c-projects/chapter-7/)You can specify them as *-rcs* or *-r* *-c* *-s*—either way.

[](/book/tiny-c-projects/chapter-7/)The name of the library file will be `libmystring.a`. The *ar* utility[](/book/tiny-c-projects/chapter-7/) uses the object code file `mystring.o` to create the library. If multiple object code files were required, specify them after `mystring.o`.

[](/book/tiny-c-projects/chapter-7/)Upon success, the *ar* utility[](/book/tiny-c-projects/chapter-7/) creates the library named libmystring.a. This naming format follows the convention used in Linux: libname.a. The library starts with lib, and then name, which is the library name. The filename extension is dot-a.

[](/book/tiny-c-projects/chapter-7/)The .a extension, as well as the process outlined in this section for creating a library, is designed for static library, as opposed to a dynamic library. The static model works best for this type of library, which is used only by command-line programs and doesn’t require the capabilities of a dynamic library. I do not cover dynamic libraries in this [](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)book.

### [](/book/tiny-c-projects/chapter-7/)7.3.3 Using the string library

[](/book/tiny-c-projects/chapter-7/)To use a library other than the standard C library, its name must be specified at build time. The `-l` (li[](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)ttle L) switch[](/book/tiny-c-projects/chapter-7/) is immediately followed by the library name. The name is the only part of the library filename used, not the first three letters (lib) or the .a extension.

[](/book/tiny-c-projects/chapter-7/)If you’ve copied the library into the `/usr/local/lib` folder, the linker searches for it there. Otherwise, the `-L` (big L) switch[](/book/tiny-c-projects/chapter-7/) directs the linker to look in a specific directory for library files. For a library you create in the same folder as your program, such as when working the examples in this book, specify the `-L.` (dash-big L-period) switch[](/book/tiny-c-projects/chapter-7/) to direct the linker to look in the current directory. For example:

```
clang -Wall -L. libsample.c -lmystring
```

[](/book/tiny-c-projects/chapter-7/)When *clang* builds the source code from `libsample.c` into a program, it directs the linker to look in the current directory (`-L.`) for the library file `libmystring.h` (`-lmystring`). The format for this command is important; the `-l` switch[](/book/tiny-c-projects/chapter-7/) must be specified last or else you see linker errors. (Some compilers may be smart enough to discover the library switch as any command-line argument, though my experience leads me to recommend putting the `-l` switch[](/book/tiny-c-projects/chapter-7/) last.)

[](/book/tiny-c-projects/chapter-7/)The next listing shows the source code found in `libsample.c`, available in this book’s online repository. The *strcaps()* function[](/book/tiny-c-projects/chapter-7/) at line 8 is part of the mystring library. Its prototype is found in the `mystring.h` header file (also included in the repository), though it’s the library that contains the function’s code. Line 2 shows the header file in double quotes, which directs the compiler to locate it in the current directory.

##### Listing 7.15 Source code for libsample.c

```
#include <stdio.h>
#include "mystring.h"      #1
 
int main()
{
    char string[] = "the great american novel";
 
    strcaps(string);       #2
    printf("%s\n",string);
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-7/)Here is the program’s output when built and linked using the command shown earlier:

```
The Great American Novel
```

[](/book/tiny-c-projects/chapter-7/)Just as you can place a copy of your personal library in the `/usr/local/lib` folder, you can place a copy of the library’s header file into the `/usr/local/include` folder. This step avoids having to use the double quotes to set the header file’s location; as with `/usr/local/lib`, the compiler scans the `/usr/local/include` folder for [](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)header [](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)files.

[](/book/tiny-c-projects/chapter-7/)C [](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)is a procedural programming language. Inelegantly put, this description means that C code runs from top to bottom, with one thing happening after another. Older programming languages like C are also procedural. The list includes BASIC, Fortran, COBOL, and other relics. But don’t let the antiquity fool you! COBOL programmers made bank during the Y2K crisis.

[](/book/tiny-c-projects/chapter-7/)Newer programming languages are object-oriented. They approach the programming task differently, something you can read about in wonderful books about these popular and trendy digital dialects. Without getting too far into the weeds, and keeping this discussion vague to avoid the nitpickers, object-oriented programming (OOP) involves methods instead of functions. *Methods*[](/book/tiny-c-projects/chapter-7/) work like functions, though they’re often a part of the data type they manipulate.

[](/book/tiny-c-projects/chapter-7/)For example, if you want to obtain the length of a string in the Java programming language, you use this construction:

```
Len = Str.length()
```

[](/book/tiny-c-projects/chapter-7/)The string variable is named `Str`[](/book/tiny-c-projects/chapter-7/). The dot operator accesses the *length()* method[](/book/tiny-c-projects/chapter-7/), which is attached to all string objects. (Get it?) The result returned is the number of characters in string `Str`. The equivalent C language statement is:

```
len = strlen(str);
```

[](/book/tiny-c-projects/chapter-7/)The dot operator is also used in C, specifically in a structure. And one of the members of a string can be . . . a function. Surprise.

### [](/book/tiny-c-projects/chapter-7/)7.4.1 Adding a function to a structure

[](/book/tiny-c-projects/chapter-7/)A str[](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)ucture contains members of specific data types: *int*[](/book/tiny-c-projects/chapter-7/), *float*[](/book/tiny-c-projects/chapter-7/), *char*[](/book/tiny-c-projects/chapter-7/), and so on. As it turns out, a function is also a data type, and it can serve as a member of a structure.

[](/book/tiny-c-projects/chapter-7/)For comparison, if you’ve been around the C language a while, you know that many functions can accept another function as an argument; the *qsort()* function[](/book/tiny-c-projects/chapter-7/) uses another function (its name as an address) as one of its arguments. As with functions as arguments, specifying a function as a structure member involves using a specific format:

```
type (*name)(arguments)
```

[](/book/tiny-c-projects/chapter-7/)The `type`[](/book/tiny-c-projects/chapter-7/) is a data type, the value returned from the function or *void* for nothing returned.

[](/book/tiny-c-projects/chapter-7/)The `name` is the function’s name, which is secretly a pointer. In this format, the function’s name isn’t followed by parentheses. Instead, the `arguments` item lists any arguments passed to the function.

[](/book/tiny-c-projects/chapter-7/)To form a clear picture, here is a structure definition that has a function as one of its members:

```
struct str {
   char *string;
   unsigned long (*length)(const char *);
};
```

[](/book/tiny-c-projects/chapter-7/)The `str` structure’s function[](/book/tiny-c-projects/chapter-7/) member is referenced as the `length`. It takes a *const char* pointer—a[](/book/tiny-c-projects/chapter-7/) string—as its argument. And it returns an *unsigned long* value[](/book/tiny-c-projects/chapter-7/). This declaration merely creates a function as a member of the `str` structure[](/book/tiny-c-projects/chapter-7/), which also contains a string member. To make the function member work, it must be assigned to a specific function. In this case, the function I have in mind is *strlen()*, which takes a *const char* pointer[](/book/tiny-c-projects/chapter-7/) as an argument and returns an *unsigned long* value[](/book/tiny-c-projects/chapter-7/).

[](/book/tiny-c-projects/chapter-7/)Creating a structure merely defines its members. To use the structure, a variable of the structure type is created. Here, structure `str` variable `str1` is created:

```
struct str str1;
```

[](/book/tiny-c-projects/chapter-7/)And its members must be assigned values. Here is how the `length` member is assigned:

```
str1.length = &strlen;
```

[](/book/tiny-c-projects/chapter-7/)The `length` member’s function is *strlen()*. It’s specified without the parentheses, prefixed by the ampersand to obtain its address. Once assigned, the function member can be called like any function. For example:

```
len = str1.length(str1.string);
```

[](/book/tiny-c-projects/chapter-7/)Member `str1.length`[](/book/tiny-c-projects/chapter-7/) is a function (secretly *strlen()*). It operates on the `string` member of the same structure, `str1.string`. The value returned, the length of the string, is stored in variable `len`[](/book/tiny-c-projects/chapter-7/).

[](/book/tiny-c-projects/chapter-7/)The following listing demonstrates all these crazy steps in the source code for `struct_funct.c`. This file is available in this book’s online repository.

##### Listing 7.16 Source code for struct_funct.c

```
#include <stdio.h>
#include <string.h>                                #1
 
int main()
{
    struct str {
        char *string;
        unsigned long (*length)(const char *);     #2
    };
    struct str str1;                               #3
    char s[] = "Heresy";
 
    str1.string = s;                               #4
    str1.length = &strlen;                         #5
 
    printf("The string '%s' is %lu characters long\n",
            str1.string,
            str1.length(str1.string)               #6
          );
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-7/)Here is the program’s output:

```
The string 'Heresy' is 6 characters long
```

[](/book/tiny-c-projects/chapter-7/)I confess that the expression `str1.length(str1.string)` doesn’t magically transform C into an object-oriented programming language. Yet for those intrepid coders who strive to make C more OOP-like, this is the approach they take. They may even cobble together macros to make the contraption look cleaner, such as `str.length()`, which is what I’d be pleased with. Still, C wasn’t created to offer such constructions. Most coders who want to use OOP drift to languages such as C++, C#, and [](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)Python.

### [](/book/tiny-c-projects/chapter-7/)7.4.2 Creating a string “object”

[](/book/tiny-c-projects/chapter-7/)I’m [](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)risking certain heresy charges and banishment from the C programming world, but it’s possible to further expand upon the idea of making C more OOP-like. Consider that you could create a string structure “object.” The problem with C is that the implementation must be done through functions.

[](/book/tiny-c-projects/chapter-7/)For example, you could write a function to create the pseudo string object. The function would require a string structure to be passed. Such a structure might look like this:

```
struct string {
 char *value;
 int length;
};
```

[](/book/tiny-c-projects/chapter-7/)This example is brief. You could add other string descriptors as structure members and perhaps a smattering of functions as well. But, for a pseudo string object demonstration, this construction is sufficient.

[](/book/tiny-c-projects/chapter-7/)To create the phony string object, a *string_create()* function[](/book/tiny-c-projects/chapter-7/) is needed. This function is passed a pointer to a `string` structure[](/book/tiny-c-projects/chapter-7/) along with the string’s contents (text):

```
int string_create(struct string *s, char *v)
```

[](/book/tiny-c-projects/chapter-7/)The pointer is necessary to allow the function to modify the structure directly. Without the pointer, any changes made to the passed structure within the function are discarded. The string passed, `v`, is eventually incorporated into the structure along with other informative goodies.

[](/book/tiny-c-projects/chapter-7/)The next listing illustrates the *string_create()* function[](/book/tiny-c-projects/chapter-7/). It returns TRUE or FALSE values depending on whether the object is successfully created: the string’s length is obtained and stored in the structure’s `length` member. This value is used to allocate storage for the string. I feel that allocating storage specifically for the string is better than duplicating the passed string’s pointer, which could change in the future.

##### Listing 7.17 The *string_create()* function

```
int string_create(struct string *s, char *v)
{
    if( s==NULL )                                        #1
        return(FALSE);
 
    s->length = strlen(v);                               #2
 
    s->value = malloc( sizeof(char) * s->length +1 );    #3
    if( s->value==NULL )
        return(FALSE);
 
    strcpy(s->value,v);                                  #4
 
    return(TRUE);                                        #5
}
```

[](/book/tiny-c-projects/chapter-7/)Just as an object is created, a companion *string_destroy()* function[](/book/tiny-c-projects/chapter-7/) must exist. This function removes the object, which means deallocating the string’s storage and zeroing out any other structure members.

[](/book/tiny-c-projects/chapter-7/)The next listing shows the *string_destroy()* function[](/book/tiny-c-projects/chapter-7/), called with the sole argument as the `string` structure[](/book/tiny-c-projects/chapter-7/) to clear. The function does three things: frees the allocated memory, assigns the value pointer to `NULL` (which confirms that the memory is deallocated), and sets the string’s length to zero. This function doesn’t obliterate the structure variable, unlike OOP languages that may also remove the variable that’s created.

##### Listing 7.18 The *string_destroy()* function

```
void string_destroy(struct string *s)
{
    free(s->value);      #1
    s->value = NULL;     #2
    s->length = 0;       #3
}
```

[](/book/tiny-c-projects/chapter-7/)Of course, after destroying a string structure variable, it can be reused or reassigned. The point is to have both a create function and a destroy function for the “object,” which mimics how some object-oriented programming languages work with objects.

[](/book/tiny-c-projects/chapter-7/)The source code file `string_object.c`, available on this book’s online repository, showcases both functions. In the code, you see that the `string` structure[](/book/tiny-c-projects/chapter-7/) is declared externally, which allows all functions to access its definition.

[](/book/tiny-c-projects/chapter-7/)It’s possible to expand upon the `string` structure[](/book/tiny-c-projects/chapter-7/), adding more members that describe the string—including function members. I leave this topic to you for further exploration, though keep in mind that object-oriented programming languages are available for you to learn and play. Forcing C into this mold is a consideration, but I would recommend focusing on the language’s strengths as opposed to [](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)pretending it’s [](/book/tiny-c-projects/chapter-7/)[](/book/tiny-c-projects/chapter-7/)something [](/book/tiny-c-projects/chapter-7/)else.
