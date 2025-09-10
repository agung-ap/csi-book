## Exercise 21. Advanced Data Types and Flow Control

This exercise will be a complete compendium of the available C data types and flow control structures you can use. It will work as a reference to complete your knowledge, and won’t have any code for you to enter. I’ll have you memorize some of the information by creating flash cards so you can get the important concepts solid in your mind.

For this exercise to be useful, you should spend at least a week hammering in the content and filling out all of the elements that are missing here. You’ll be writing out what each one means, and then writing a program to confirm what you’ve researched.

### Available Data Types

![Image](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780133124385/files/graphics/104tab01.jpg)

#### Type Modifiers

![Image](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780133124385/files/graphics/104tab02.jpg)

#### Type Qualifiers

![Image](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780133124385/files/graphics/105tab01.jpg)

#### Type Conversion

C uses a sort of stepped type promotion mechanism, where it looks at two operands on either side of an expression, and promotes the smaller side to match the larger side before doing the operation. If one side of an expression is on this list, then the other side is converted to that type before the operation is done. It goes in this order:

**1.** `long double`

**2.** `double`

**3.** `float`

**4.** `int` (but only `char` and `short int`);

**5.** `long`

If you find yourself trying to figure out how your conversions are working in an expression, then don’t leave it to the compiler. Use explicit casting operations to make it exactly what you want. For example, if you have

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch21_images.html#p105pro01a)

```
long + char - int * double
```

Rather than trying to figure out if it will be converted to double correctly, just use casts:

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch21_images.html#p105pro02a)

```
(double)long - (double)char - (double)int * double
```

Putting the type you want in parentheses before the variable name is how you force it into the type you really need. The important thing, though, is *always promote up, not down*. Don’t cast `long` into `char` unless you know what you’re doing.

#### Type Sizes

The `stdint.h` defines both a set of `typdefs` for exact-sized integer types, as well as a set of macros for the sizes of all the types. This is easier to work with than the older `limits.h` since it is consistent. Here are the types defined:

![Image](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780133124385/files/graphics/106tab01.jpg)

The pattern here is in the form (u)int(*BITS*)_t where a *u* is put in front to indicate “unsigned,” and *BITS* is a number for the number of bits. This pattern is then repeated for macros that return the maximum values of these types:

`INT(N)_MAX` Maximum positive number of the signed integer of bits *(N)*, such as `INT16_MAX`.

`INT(N)_MIN` Minimum negative number of signed integer of bits *(N)*.

`UINT(N)_MAX` Maximum positive number of unsigned integer of bits *(N)*. Since it’s unsigned, the minimum is 0 and it can’t have a negative value.

---

Warning!

Pay attention! Don’t go looking for a literal `INT(N)_MAX` definition in any header file. I’m using the `(N)` as a placeholder for any number of bits your platform currently supports. This `(N)` could be any number—8, 16, 32, 64, maybe even 128. I use this notation in this exercise so that I don’t have to literally write out every possible combination.

---

There are also macros in `stdint.h` for sizes of the `size_t` type, integers large enough to hold pointers, and other handy size defining macros. Compilers have to at least have these, and then they can allow other, larger types.

Here is a full list that should be in `stdint.h`:

![Image](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780133124385/files/graphics/107tab01.jpg)

### Available Operators

This is a comprehensive list of all the operators in the C language. In this list, I’m indicating the following:

![Image](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780133124385/files/graphics/108tab01.jpg)

#### Math Operators

These perform your basic math operations, plus I include `()` since it calls a function and is close to a math operation.

![Image](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780133124385/files/graphics/108tab02.jpg)

#### Data Operators

These are used to access data in different ways and forms.

![Image](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780133124385/files/graphics/109tab01.jpg)

#### Logic Operators

These handle testing equality and inequality of variables.

![Image](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780133124385/files/graphics/109tab02.jpg)

#### Bit Operators

These are more advanced and are for shifting and modifying the raw bits in integers.

![Image](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780133124385/files/graphics/109tab03.jpg)

#### Boolean Operators

These are used in truth testing. Study the ternary operator carefully. It’s very handy.

![Image](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780133124385/files/graphics/110tab01.jpg)

#### Assignment Operators

Here are compound assignment operators that assign a value, and/or perform an operation at the same time. Most of the above operations can also be combined into a compound assignment operator.

![Image](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780133124385/files/graphics/110tab02.jpg)

### Available Control Structures

There are a few control structures that you haven’t encountered yet.

**do-while** `do { ... } while(X);` First does the code in the block, then tests the `X` expression before exiting.

**break** Puts a break in a loop, ending it early.

**continue** Stops the body of a loop and jumps to the test so it can continue.

**goto** Jumps to a spot in the code where you’ve placed a `label:`, and you’ve been using this in the `dbg.h` macros to go to the `error:` label.

### Extra Credit

• Read `stdint.h` or a description of it, and write out all the available size identifiers.

• Go through each item here and write out what it does in code. Research it online so you know you got it right.

• Get this information memorized by making flash cards and spending 15 minutes a day practicing it.

• Create a program that prints out examples of each type, and confirm that your research is right.
