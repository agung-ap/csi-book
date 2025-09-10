## Exercise 16. Structs And Pointers to Them

In this exercise, you’ll learn how to make a `struct`, point a pointer at it, and use it to make sense of internal memory structures. We’ll also apply the knowledge of pointers from the last exercise, and then get you constructing these structures from raw memory using `malloc`.

As usual, here’s the program we’ll talk about, so type it in and make it work.

`ex16.c`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch16_images.html#p068pro01a)

```
#include <stdio.h>

#include <assert.h>

#include <stdlib.h>

#include <string.h>

 5

struct Person {

char *name;

int age;

int height;

int weight;

};

12

struct Person *Person_create(char *name, int age, int height,

int weight)

{

struct Person *who = malloc(sizeof(struct Person));

assert(who != NULL);

18

who->name = strdup(name);

who->age = age;

who->height = height;

who->weight = weight;

23

return who;

}

26

void Person_destroy(struct Person *who)

{

assert(who != NULL);

30

free(who->name);

free(who);

}

34

void Person_print(struct Person *who)

{

printf("Name: %s\n", who->name);

printf("\tAge: %d\n", who->age);

printf("\tHeight: %d\n", who->height);

printf("\tWeight: %d\n", who->weight);

}

42

int main(int argc, char *argv[])

{

// make two people structures

struct Person *joe = Person_create("Joe Alex", 32, 64, 140);

47

struct Person *frank = Person_create("Frank Blank", 20, 72, 180);

49

// print them out and where they are in memory

printf("Joe is at memory location %p:\n", joe);

Person_print(joe);

53

printf("Frank is at memory location %p:\n", frank);

Person_print(frank);

56

// make everyone age 20 years and print them again

joe->age += 20;

joe->height -= 2;

joe->weight += 40;

Person_print(joe);

62

frank->age += 20;

frank->weight += 20;

Person_print(frank);

66

// destroy them both so we clean up

Person_destroy(joe);

Person_destroy(frank);

70

return 0;

}
```

To describe this program, I’m going to use a different approach than before. I’m not going to give you a line-by-line breakdown of the program, I’m going to make *you* write it. I’m giving you a guide of the program based on the parts it contains, and your job is write out what each line does.

**includes** I include some new header files here to gain access to some new functions. What does each give you?

**struct Person** This is where I’m creating a structure that has four elements to describe a person. The final result is a new compound type that lets me reference these elements all as one or each piece by name. It’s similar to a row of a database table or a class in an object-oriented programming (OOP) language.

**function Person_create** I need a way to create these structures, so I’ve made a function to do that. Here are the important things:

• I use `malloc` for memory allocate to ask the OS to give me a piece of raw memory.

• I pass to `malloc` the `sizeof(struct Person)`, which calculates the total size of the structure, given all of the fields inside it.

• I use `assert` to make sure that I have a valid piece of memory back from `malloc.` There’s a special constant called `NULL` that you use to mean “unset or invalid pointer.” This `assert` is basically checking that `malloc` didn’t return a NULL invalid pointer.

• I initialize each field of `struct Person` using the `x->y` syntax, to say what part of the structure I want to set.

• I use the `strdup` function to duplicate the string for the name, just to make sure that this structure actually owns it. The `strdup` actually is like `malloc`, and it also copies the original string into the memory it creates.

**function Person_destroy** If I have a `create` function, then I always need a `destroy` function, and this is what destroys `Person` structures. I again use `assert` to make sure I’m not getting bad input. Then I use the function `free` to return the memory I got with `malloc` and `strdup`. If you don’t do this, you get a *memory leak.*

**function Person_print** I then need a way to print out people, which is all this function does. It uses the same `x->y` syntax to get the field from the structure to print it.

**function main** In the `main` function, I use all of the previous functions and the `struct Person` to do the following:

• Create two people, `joe` and `frank`.

• Print them out, but notice I’m using the `%p` format so you can see *where* the program has actually put your structure in memory.

• Age both of them by 20 years with changes to their bodies, too.

• Print each one after aging them.

• Finally, destroy the structures so we can clean up correctly.

Go through this description carefully, and do the following:

• Look up every function and header file you don’t know. Remember that you can usually do `man 2 function` or `man 3 function`, and it’ll tell you about it. You can also search online for the information.

• Write a *comment* above each and every single line that says what the line does in English.

• Trace through each function call and variable so you know where it comes from in the program.

• Look up any symbols you don’t understand.

### What You Should See

After you augment the program with your description comments, make sure it really runs and produces this output:

`Exercise 16 Session`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch16_images.html#p071pro01a)

```bash
$ make ex16

cc -Wall -g    ex16.c   -o ex16



$ ./ex16

Joe is at memory location 0xeba010:

Name: Joe Alex

  Age: 32

  Height: 64

  Weight: 140

Frank is at memory location 0xeba050:

Name: Frank Blank

  Age: 20

  Height: 72

  Weight: 180

Name: Joe Alex

  Age: 52

  Height: 62

  Weight: 180

Name: Frank Blank

  Age: 40

  Height: 72

  Weight: 200
```

### Explaining Structures

If you’ve done the work, then structures should be making sense, but let me explain them explicitly just to make sure you’ve understood it.

A structure in C is a collection of other data types (variables) that are stored in one block of memory where you can access each variable independently by name. They are similar to a record in a database table, or a very simplistic class in an OOP language. We can break one down this way:

• In the above code, we make a `struct` that has fields for a person: name, age, weight, and height.

• Each of those fields has a type, like `int`.

• C then packs those together so that they can all be contained in one single `struct`.

• The `struct Person` is now a *compound data type*, which means you can refer to `struct Person` using the same kinds of expressions you would for other data types.

• This lets you pass the whole cohesive grouping to other functions, as you did with `Person_print`.

• You can then access the individual parts of a `struct` by their names using `x->y` if you’re dealing with a pointer.

• There’s also a way to make a struct that doesn’t need a pointer, and you use the `x.y` (period) syntax to work with it. We’ll do this in the Extra Credit section.

If you didn’t have `struct`, you’d need to figure out the size, packing, and location of pieces of memory with contents like this. In fact, in most early Assembler code (and even some now), this is what you would do. In C, you can let it handle the memory structuring of these compound data types and then focus on what you do with them.

### How to Break It

The ways in which to break this program involve how you use the pointers and the `malloc` system:

• Try passing `NULL` to `Person_destroy` see what it does. If it doesn’t abort, then you must not have the `-g` option in your `Makefile'`s `CFLAGS`.

• Forget to call `Person_destroy` at the end, and then run it under the debugger to see it report that you forgot to free the memory. Figure out the options you need to pass to the debugger to get it to print how you leaked this memory.

• Forget to free `who->name` in `Person_destroy` and compare the output. Again, use the right options to see how the debugger tells you exactly where you messed up.

• This time, pass `NULL` to `Person_print` and see what the debugger thinks of that. You’ll figure out that `NULL` is a quick way to crash your program.

### Extra Credit

In this part of the exercise, I want you to attempt something difficult for the extra credit: Convert this program to *not* use pointers and `malloc`. This will be hard, so you’ll want to research the following:

• How to create a `struct` on the *stack*, just like you’re making any other variable.

• How to initialize it using the `x.y` (period) character instead of the `x->y` syntax.

• How to pass a structure to other functions without using a pointer.
