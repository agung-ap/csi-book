## Exercise 17. Heap and Stack Memory Allocation

In this exercise, you’re going to make a big leap in difficulty and create an entire small program to manage a database. This database isn’t very efficient and doesn’t store very much, but it does demonstrate most of what you’ve learned so far. It also introduces memory allocation more formally, and gets you started working with files. We use some file I/O functions, but I won’t be explaining them too well so that you can try to figure them out first.

As usual, type this whole program in and get it working, then we’ll discuss it.

`ex17.c`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch17_images.html#p074pro01a)

```
#include <stdio.h>

#include <assert.h>

#include <stdlib.h>

#include <errno.h>

#include <string.h>

  6

#define MAX_DATA 512

#define MAX_ROWS 100

  9

struct Address {

int id;

int set;

char name[MAX_DATA];

char email[MAX_DATA];

};

 16

struct Database {

struct Address rows[MAX_ROWS];

};

 20

struct Connection {

FILE *file;

struct Database *db;

};

 25

void die(const char *message)

{

if (errno) {

perror(message);

} else {

printf("ERROR: %s\n", message);

}

 33

exit(1);

}

 36

void Address_print(struct Address *addr)

{

printf("%d %s %s\n", addr->id, addr->name, addr->email);

}

 41

void Database_load(struct Connection *conn)

{

int rc = fread(conn->db, sizeof(struct Database), 1, conn->file);

if (rc != 1)

die("Failed to load database.");

}

 48

struct Connection *Database_open(const char *filename, char mode)

{

struct Connection *conn = malloc(sizeof(struct Connection));

if (!conn)

die("Memory error");

 54

conn->db = malloc(sizeof(struct Database));

if (!conn->db)

die("Memory error");

 58

if (mode == 'c') {

conn->file = fopen(filename, "w");

} else {

conn->file = fopen(filename, "r+");

 63

if (conn->file) {

Database_load(conn);

}

}

 68

if (!conn->file)

die("Failed to open the file");

 71

return conn;

}

 74

void Database_close(struct Connection *conn)

{

if (conn) {

if (conn->file)

fclose(conn->file);

if (conn->db)

free(conn->db);

free(conn);

}

}

 85

void Database_write(struct Connection *conn)

{

rewind(conn->file);

 89

int rc = fwrite(conn->db, sizeof(struct Database), 1, conn->file);

if (rc != 1)

die("Failed to write database.");

 93

rc = fflush(conn->file);

if (rc == -1)

die("Cannot flush database.");

}

 98

void Database_create(struct Connection *conn)

{

int i = 0;

102

for (i = 0; i < MAX_ROWS; i++) {

// make a prototype to initialize it

struct Address addr = {.id = i,.set = 0 };

// then just assign it

conn->db->rows[i] = addr;

}

}

110

void Database_set(struct Connection *conn, int id, const char *name,

const char *email)

{

struct Address *addr = &conn->db->rows[id];

if (addr->set)

die("Already set, delete it first");

117

addr->set = 1;

// WARNING: bug, read the "How To Break It" and fix this

char *res = strncpy(addr->name, name, MAX_DATA);

// demonstrate the strncpy bug

if (!res)

die("Name copy failed");

124

res = strncpy(addr->email, email, MAX_DATA);

if (!res)

die("Email copy failed");

}

129

void Database_get(struct Connection *conn, int id)

{

struct Address *addr = &conn->db->rows[id];

133

if (addr->set) {

Address_print(addr);

} else {

die("ID is not set");

}

}

140

void Database_delete(struct Connection *conn, int id)

{

struct Address addr = {.id = id,.set = 0 };

conn->db->rows[id] = addr;

}

146

void Database_list(struct Connection *conn)

{

int i = 0;

struct Database *db = conn->db;

151

for (i = 0; i < MAX_ROWS; i++) {

struct Address *cur = &db->rows[i];

154

if (cur->set) {

Address_print(cur);

}

}

}

160

int main(int argc, char *argv[])

{

if (argc < 3)

die("USAGE: ex17 <dbfile> <action> [action params]");

165

char *filename = argv[1];

char action = argv[2][0];

struct Connection *conn = Database_open(filename, action);

int id = 0;

170

if (argc > 3) id = atoi(argv[3]);

if (id >= MAX_ROWS) die("There's not that many records.");

173

switch (action) {

case 'c':

Database_create(conn);

Database_write(conn);

break;

179

case 'g':

if (argc != 4)

die("Need an id to get");

183

Database_get(conn, id);

break;

186

case 's':

if (argc != 6)

die("Need id, name, email to set");

190

Database_set(conn, id, argv[4], argv[5]);

Database_write(conn);

break;

194

case 'd':

if (argc != 4)

die("Need id to delete");

198

Database_delete(conn, id);

Database_write(conn);

break;

202

case 'l':

Database_list(conn);

break;

default:

die("Invalid action: c=create, g=get, s=set, d=del, l=list");

}

209

Database_close(conn);

211

return 0;

}
```

In this program, we’re using a set of structures, or structs, to create a simple database for an address book. There are some things you’ve never seen, so you should go through it line by line, explain what each line does, and look up any functions that you don’t recognize. There are a few key things that you should pay attention to, as well:

**#define for constants** We use another part of the C preprocessor (CPP) to create constant settings of `MAX_DATA` and `MAX_ROWS`. I’ll cover more of what the CPP does later, but this is a way to create a constant that will work reliably. There are other ways, but they don’t apply in certain situations.

**Fixed sized structs** The `Address` struct then uses these constants to create a piece of data that is fixed in size, making it less efficient but easier to store and read. The `Database` struct is then also a fixed size because it’s a fixed length array of `Address` structs. That lets you write the whole thing to disk in one move later.

**die function to abort with an error** In a small program like this, you can make a single function that kills the program with an error if there’s anything wrong. I call this `die`, and it’s used to exit the program with an error after any failed function calls or bad inputs.

**errno and perror() for error reporting** When you have an error return from a function, it will usually set an external variable called `errno` to say exactly what happened. These are just numbers, so you can use `perror` to print the error message.

**FILE functions** I’m using all new functions like `fopen`, `fread`, `fclose`, and `rewind` to work with files. Each of these functions works on a `FILE` struct that’s just like your other structs, but it’s defined by the C standard library.

**nested struct pointers** There’s a use for nested structures and getting the address of array elements that you should study. Specifically, code like `&conn->db->rows[i]` that reads “get the `i` element of `rows`, which is in `db`, which is in `conn`, then get the address of (`&`) it.”

**copying struct prototypes** Best shown in `Database_delete`, you can see I’m using a temporary local `Address`, initializing its `id` and `set` fields, and then simply copying it into the `rows` array by assigning it to the element I want. This trick makes sure that all fields except `set` and `id` are initialized to zeros and it’s actually easier to write. Incidentally, you shouldn’t be using `memcpy` to do these kinds of struct copying operations. Modern C allows you to simply assign one struct to another and it’ll handle the copying for you.

**processing complex arguments** I’m doing some more complex argument parsing, but this isn’t really the best way to do it. We’ll get into a better option for parsing later in the book.

**converting strings to ints** I use the `atoi` function to take the string for the id on the command line and convert it to the `int id` variable. Read up on this and similar functions.

**allocating large data on the heap** The whole point of this program is that I’m using `malloc` to ask the OS for a large amount of memory when I create the `Database`. We’ll cover this in more detail later.

**NULL is 0, so Boolean works** In many of the checks, I’m testing that a pointer is not NULL by simply doing `if(!ptr) die("fail!")`, because NULL will evaluate to false. You could be explicit and say `if(ptr == NULL) die("fail!")`, as well. In some rare systems, NULL will be stored in the computer (represented) as something not 0, but the C standard says you should still be able to write code as if it has a 0 value. From now on when I say “NULL is 0,” I mean its value for anyone who is overly pedantic.

### What You Should See

You should spend as much time as you can testing that it works, and running it with a debugger to confirm that you’ve got all of the memory usage right. Here’s a session of me testing it normally, and then using the debugger to check the operations:

`Exercise 17 Session`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch17_images.html#p080pro01a)

```bash
$ make ex17

cc -Wall -g    ex17.c   -o ex17

$ ./ex17 db.dat c

$ ./ex17 db.dat s 1 zed zed@zedshaw.com

$ ./ex17 db.dat s 2 frank frank@zedshaw.com

$ ./ex17 db.dat s 3 joe joe@zedshaw.com

$

$ ./ex17 db.dat l

1 zed zed@zedshaw.com

2 frank frank@zedshaw.com

3 joe joe@zedshaw.com

$ ./ex17 db.dat d 3

$ ./ex17 db.dat l

1 zed zed@zedshaw.com

2 frank frank@zedshaw.com

$ ./ex17 db.dat g 2

2 frank frank@zedshaw.com
```

### Heap versus Stack Allocation

You kids have it great these days. You play with your Ruby or Python and just make objects and variables without any care for where they live. You don’t care if it’s on the *stack,* and what about on the *heap*? Fuggedaboutit. You don’t even know, and you know what, chances are your language of choice doesn’t even put the variables on stack at all. It’s all heap, and you don’t even *know* if it is.

C is different because it’s using the real CPU’s actual machinery to do its work, and that involves a chunk of RAM called the stack and another called the heap. What’s the difference? It all depends on where you get the storage.

The heap is easier to explain since it’s just all the remaining memory in your computer, and you access it with the function `malloc` to get more. Each time you call `malloc`, the OS uses internal functions to register that piece of memory to you, and then returns a pointer to it. When you’re done with it, you use `free` to return it to the OS so that it can be used by other programs. Failing to do this will cause your program to *leak* memory, but Valgrind will help you track these leaks down.

The stack is a special region of memory that stores temporary variables, which each function creates as locals to that function. How it works is that each argument to a function is *pushed* onto the stack and then used inside the function. It’s really a stack data structure, so the last thing in is the first thing out. This also happens with all local variables like `char action` and `int id` in `main`. The advantage of using a stack for this is simply that when the function exits, the C compiler pops these variables off of the stack to clean up. This is simple and prevents memory leaks if the variable is on the stack.

The easiest way to keep this straight is with this mantra: If you didn’t get it from `malloc`, or a function that got it from `malloc`, then it’s on the stack.

There are three primary problems with stacks and heaps to watch out for:

• If you get a block of memory from `malloc`, and have that pointer on the stack, then when the function exits the pointer will get popped off and lost.

• If you put too much data on the stack (like large structs and arrays), then you can cause a *stack overflow* and the program will abort. In this case, use the heap with `malloc`.

• If you take a pointer to something on the stack, and then pass or return it from your function, then the function receiving it will *segmentation fault* (segfault), because the actual data will get popped off and disappear. You’ll be pointing at dead space.

This is why I created a `Database_open` that allocates memory or dies, and then a `Database_close` that frees everything. If you create a create function that makes the whole thing or nothing, and then a destroy function that safely cleans up everything, then it’s easier to keep it all straight.

Finally, when a program exits, the OS will clean up all of the resources for you, but sometimes not immediately. A common idiom (and one I use in this exercise) is to just abort and let the OS clean up on error.

### How to Break It

This program has a lot of places where you can break it, so try some of these but also come up with your own:

• The classic way is to remove some of the safety checks so that you can pass in arbitrary data. For example, remove the check on line 160 that prevents you from passing in any record number.

• You can also try corrupting the data file. Open it in any editor and change random bytes, and then close it.

• You could also find ways to pass bad arguments to the program when it’s run. For example, getting the file and action backward will make it create a file named after the action, and then do an action based on the first character.

• There’s a bug in this program because `strncpy` is poorly designed. Go read about `strncpy` and try to find out what happens when the `name` or `address` you give is *greater* than 512 bytes. Fix this by simply forcing the last character to `'\0'` so that it’s always set no matter what (which is what `strncpy` should do).

• In the Extra Credit section, I have you augment the program to create arbitrary size databases. Try to see what the biggest database is before you cause the program to die due to lack of memory from `malloc`.

### Extra Credit

• The `die` function needs to be augmented to let you pass the `conn` variable, so it can close it and clean up.

• Change the code to accept parameters for `MAX_DATA` and `MAX_ROWS`, store them in the `Database` struct, and write that to the file, thus creating a database that can be arbitrarily sized.

• Add more operations you can do with the database, like `find`.

• Read about how C does it’s struct packing, and then try to see why your file is the size it is. See if you can calculate a new size after adding more fields.

• Add some more fields to `Address` and make them searchable.

• Write a shell script that will do your testing automatically for you by running commands in the right order. Hint: Use `set -e` at the top of a `bash` to make it abort the whole script if any command has an error.

• Try reworking the program to use a single global for the database connection. How does this new version of the program compare to the other one?

• Go research stack data structure and write one in your favorite language, then try to do it in C.
