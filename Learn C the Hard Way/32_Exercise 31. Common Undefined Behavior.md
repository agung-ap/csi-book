## Exercise 31. Common Undefined Behavior

At this point in the book, it’s time to introduce you to the most common kinds of UB that you will encounter. C has 191 behaviors that the standards committee has decided aren’t defined by the standard, and therefore anything goes. Some of these behaviors are legitimately not the compiler’s job, but the vast majority are simply lazy capitulations by the standards committee that cause annoyances, or worse, defects. An example of laziness:

*An unmatched “or” character is encountered on a logical source line during tokenization.*

In this instance, the C99 standard actually allows a compiler writer to fail at a parsing task that a junior in college could get right. Why is this? Who knows, but most likely someone on the standards committee was working on a C compiler with this defect and managed to get this in the standard rather than fix their compiler. Or, as I said, simple laziness.

The crux of the issue with UB is the difference between the C abstract machine, defined in the standard and real computers. The C standard describes the C language according to a strictly defined abstract machine. This is a perfectly valid way to design a language, except where the C standard goes wrong: It doesn’t require compilers to implement this abstract machine and enforce its specification. Instead, a compiler writer can completely ignore the abstract machine in 191 instances of the standard. It should really be called an “abstract machine, but”, as in, “It’s a strictly defined abstract machine, but...”

This allows the standards committee and compiler implementers to have their cake and eat it, too. They can have a standard that is full of omissions, lax specification, and errors, but when *you* encounter one of these, they can point at the abstract machine and simply say in their best robot voice, “THE ABSTRACT MACHINE IS ALL THAT MATTERS. YOU DO NOT CONFORM!” Yet, in 191 instances that compiler writers don’t have to conform, you do. You are a second class citizen, even though the language is really written for you to use.

This means that *you*, not the compiler writer, are left to enforce the rules of an abstract computational machine, and when you inevitably fail, it’s your fault. The compiler doesn’t have to flag the UB, do anything reasonable, and it’s your fault for not memorizing all 191 rules that should be avoided. You are just stupid for not memorizing 191 complex potholes on the road to C. This is a wonderful situation for the classic know-it-all type who can memorize these 191 finer points of annoyance with which to beat beginners to intellectual death.

There’s an additional hypocrisy with UB that is doubly infuriating. If you show a C fanatic code that properly uses C strings but can overwrite the string terminator, they will say, “That’s UB. It’s not the C language’s fault!” However, if you show them UB that has `while(x) x <<= 1` in it, they will say, “That’s UB idiot! Fix your damn code!” This lets the C fanatic simultaneously use UB to defend the purity of C’s design, and also beat you up for being an idiot who writes bad code. Some UB is meant as, “you can ignore the security of this since it’s not C’s fault”, and other UB is meant as, “you are an idiot for writing this code,” and the distinction between the two is not specified in the standard.

As you can see, I am *not* a fan of the huge list of UB. I had to memorize all of these before the C99 standard, and just didn’t bother to memorize the changes. I’d simply moved on to a way and found a way to avoid as much UB as I possibly could, trying to stay within the abstract machine specification while also working with real machines. This turns out to be almost impossible, so I just don’t write new code in C anymore because of its glaringly obvious problems.

---

Warning!

The technical explanation as to why C UB is wrong comes from Alan Turing:

**1.** C UB contains behaviors that are lexical, semantic, and execution based.

**2.** The lexical and semantic behaviors can be detected by the compiler.

**3.** The execution-based behaviors fall into Turing’s definition of the *halting problem*, and are therefore NP-complete.

**4.** This means that to avoid C UB, it requires solving one of the oldest proven unsolvable problems in computer science, making UB effectively impossible for a computer to avoid.

To put it more succinctly: “If the only way to know that you’ve violated the abstract machine with UB is to run your C program, then you will never be able to completely avoid UB.”

---

### UB 20

Because of this, I’m going to list the top 20 undefined behaviors in C, and tell you how to avoid them as best I can. In general, the way to avoid UB is to write clean code, but some of these behaviors are impossible to avoid. For example, writing past the end of a C string is an undefined behavior, yet it’s easily done by accident and externally accessible to an attacker. This list will also include related UB that all fall into the same category but with differing contexts.

#### Common UBs

**1.** An object is referred to outside of its lifetime (6.2.4).

• The value of a pointer to an object whose lifetime has ended is used (6.2.4).

• The value of an object with automatic storage duration is used while it is indeterminate (6.2.4, 6.7.8, 6.8).

**2.** Conversion to or from an integer type produces a value outside the range that can be represented (6.3.1.4).

• Demotion of one real floating type to another produces a value outside the range that can be represented (6.3.1.5).

**3.** Two declarations of the same object or function specify types that are not compatible (6.2.7).

**4.** An lvalue having array type is converted to a pointer to the initial element of the array, and the array object has register storage class (6.3.2.1).

• An attempt is made to use the value of a void expression, or an implicit or explicit conversion (except to void) is applied to a void expression (6.3.2.2).

• Conversion of a pointer to an integer type produces a value outside the range that can be represented (6.3.2.3).

• Conversion between two pointer types produces a result that is incorrectly aligned (6.3.2.3).

• A pointer is used to call a function whose type is not compatible with the pointed-to type (6.3.2.3).

• The operand of the unary * operator has an invalid value (6.5.3.2).

• A pointer is converted to other than an integer or pointer type (6.5.4).

• Addition or subtraction of a pointer into, or just beyond, an array object and an integer type produces a result that does not point into, or just beyond, the same array object (6.5.6).

• Addition or subtraction of a pointer into, or just beyond, an array object and an integer type produces a result that points just beyond the array object and is used as the operand of a unary * operator that is evaluated (6.5.6).

• Pointers that do not point into, or just beyond, the same array object are subtracted (6.5.6).

• An array subscript is out of range, even if an object is apparently accessible with the given subscript (as in the `lvalue` expression `a[1][7]` given the declaration `int a[4][5])` (6.5.6).

• The result of subtracting two pointers is not representable in an object of type `ptrdiff_t`(6.5.6).

• Pointers that do not point to the same aggregate or union (nor just beyond the same array object) are compared using relational operators (6.5.8).

• An attempt is made to access, or generate a pointer to just past, a flexible array member of a structure when the referenced object provides no elements for that array (6.7.2.1).

• Two pointer types that are required to be compatible are not identically qualified, or are not pointers to compatible types (6.7.5.1).

• The size expression in an array declaration is not a constant expression and evaluates at program execution time to a nonpositive value (6.7.5.2).

• The pointer passed to a library function array parameter does not have a value such that all address computations and object accesses are valid (7.1.4).

**5.** The program attempts to modify a string literal (6.4.5).

**6.** An object has its stored value accessed other than by an lvalue of an allowable type (6.5).

**7.** An attempt is made to modify the result of a function call, a conditional operator, an assignment operator, or a comma operator, or to access it after the next sequence point (6.5.2.2, 6.5.15, 6.5.16, 6.5.17).

**8.** The value of the second operand of the / or % operator is zero (6.5.5).

**9.** An object is assigned to an inexactly overlapping object or to an exactly overlapping object with incompatible type (6.5.16.1).

**10.** A constant expression in an initializer is not, or does not evaluate to, one of the following: an arithmetic constant expression, a null pointer constant, an address constant, or an address constant for an object type plus or minus an integer constant expression (6.6).

• An arithmetic constant expression does not have arithmetic type; has operands that are not integer constants, floating constants, enumeration constants, character constants, or sizeof expressions; or contains casts (outside operands to sizeof operators) other than conversions of arithmetic types to arithmetic types (6.6).

**11.** An attempt is made to modify an object defined with a const-qualified type through use of an lvalue with non-const-qualified type (6.7.3).

**12.** A function with external linkage is declared with an inline function specifier, but is not also defined in the same translation unit (6.7.4).

**13.** The value of an unnamed member of a structure or union is used (6.7.8).

**14.** The } that terminates a function is reached, and the value of the function call is used by the caller (6.9.1).

**15.** A file with the same name as one of the standard headers, not provided as part of the implementation, is placed in any of the standard places that are searched for included source files (7.1.2).

**16.** The value of an argument to a character handling function is neither equal to the value of EOF nor representable as an unsigned char (7.4).

**17.** The value of the result of an integer arithmetic or conversion function cannot be represented (7.8.2.1, 7.8.2.2, 7.8.2.3, 7.8.2.4, 7.20.6.1, 7.20.6.2, 7.20.1).

**18.** The value of a pointer to a FILE object is used after the associated file is closed (7.19.3).

• The stream for the `fflush` function points to an input stream or to an update stream in which the most recent operation was input (7.19.5.2).

• The string pointed to by the `mode` argument in a call to the `fopen` function does not exactly match one of the specified character sequences (7.19.5.3).

• An output operation on an update stream is followed by an input operation without an intervening call to the `fflush` function or a file positioning function, or an input operation on an update stream is followed by an output operation with an intervening call to a file positioning function (7.19.5.3).

**19.** A conversion specification for a formatted output function uses a # or 0 flag with a conversion specifier other than those described (7.19.6.1, 7.24.2.1). * An s conversion specifier is encountered by one of the formatted output functions, and the argument is missing the null terminator (unless a precision is specified that does not require null termination) (7.19.6.1, 7.24.2.1). * The contents of the array supplied in a call to the `fgets`, `gets`, or `fgetws` function are used after a read error occurred (7.19.7.2, 7.19.7.7, 7.24.3.2).

**20.** A non-null pointer returned by a call to the `calloc`, `malloc`, or `realloc` function with a zero requested size is used to access an object (7.20.3). * The value of a pointer that refers to space deallocated by a call to the `free` or `realloc` function is used (7.20.3). * The pointer argument to the `free` or `realloc` function does not match a pointer earlier returned by `calloc`, `malloc`, or `realloc`, or the space has been deallocated by a call to `free` or `realloc` (7.20.3.2, 7.20.3.4).

There are many more, but these seem to be the ones that I run into the most often or that come up the most often in C code. They are also the most difficult to avoid, so if you at least remember these, you’ll be able to avoid the major ones.
