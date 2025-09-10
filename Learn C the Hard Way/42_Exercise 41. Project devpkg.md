## Exercise 41. Project devpkg

You are now ready to tackle a new project called `devpkg`. In this project you’re going to recreate a piece of software that I wrote specifically for this book called `devpkg`. You’ll then extend it in a few key ways and improve the code, most importantly by writing some unit tests for it.

This exercise has a companion video to it, and also a project on GitHub ([https://github.com](https://github.com/)) that you can reference if you get stuck. You should attempt to do this exercise using the description below, since that’s how you’ll need to learn to code from books in the future. Most computer science textbooks don’t include videos for their exercises, so this project is more about trying to figure it out from this description.

If you get stuck, and you can’t figure it out, *then* go watch the video and look at the GitHub project to see how your code differs from mine.

### What Is devpkg?

`Devpkg` is a simple C program that installs other software. I made it specifically for this book as a way to teach you how a real software project is structured, and also how to reuse other people’s libraries. It uses a portability library called the Apache Portable Runtime (APR), which has many handy C functions that work on tons of platforms, including Windows. Other than that, it just grabs code from the Internet (or local files) and does the usual `./configure`, `make`, and `make install` that every program does.

Your goal in this exercise is to build `devpkg` from the source, finish each *challenge* I give, and use the source to understand what `devpkg` does and why.

#### What We Want to Make

We want a tool that has these commands:

**devpkg -S** Sets up a new installation on a computer.

**devpkg -I** Installs a piece of software from a URL.

**devpkg -L** Lists all of the software that’s been installed.

**devpkg -F** Fetches some source code for manual building.

**devpkg -B** Builds the source code and installs it, even if it’s already installed.

We want `devpkg` to be able to take almost any URL, figure out what kind of project it is, download it, install it, and register that it downloaded that software. We’d also like it to process a simple dependency list so that it can install all of the software that a project might need, as well.

#### The Design

To accomplish this goal, `devpkg` will have a very simple design:

**Use External Commands** You’ll do most of the work through external commands like `curl`, `git`, and `tar`. This reduces the amount of code `devpkg` needs to get things done.

**Simple File Database** You could easily make it more complex, but you’ll start by making just make a single simple file database at `/usr/local/.devpkg/db` to keep track of what’s installed.

**/usr/local Always** Again, you could make this more advanced, but for now just assume it’s always `/usr/local`, which is a standard install path for most software on UNIX.

**configure, make, make install** It’s assumed that most software can be installed with just a `configure`, `make`, and `make install`—and maybe `configure` is optional. If the software at a minimum can’t do that, there are some options to modify the commands, but otherwise, `devpkg` won’t bother.

**The User Can Be Root** We’ll assume that the user can become root using `sudo`, but doesn’t want to become root until the end.

This will keep our program small at first and work well enough for us to get it going, at which point you’ll be able to modify it further for this exercise.

#### The Apache Portable Runtime

One more thing you’ll do is leverage the APR Libraries to get a good set of portable routines for doing this kind of work. APR isn’t necessary, and you could probably write this program without it, but it’d take more code than necessary. I’m also forcing you to use APR now so you get used to linking and using other libraries. Finally, APR also works on *Windows*, so your skills with it are transferable to many other platforms.

You should go get both the `apr-1.5.2` and the `apr-util-1.5.4` libraries, as well as browse through the documentation available at the main APR site at [http://apr.apache.org](http://apr.apache.org/).

Here’s a shell script that will install all the stuff you need. You should write this into a file by hand, and then run it until it can install APR without any errors.

`Exercise 41.1 Session`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch41_images.html#p276pro01a)

```
set -e



# go somewhere safe

cd /tmp



# get the source to base APR 1.5.2

curl -L -O http://archive.apache.org/dist/apr/apr-1.5.2.tar.gz



# extract it and go into the source

tar -xzvf apr-1.5.2.tar.gz

cd apr-1.5.2



# configure, make, make install

./configure

make

sudo make install



# reset and cleanup

cd /tmp

rm -rf apr-1.5.2 apr-1.5.2.tar.gz



# do the same with apr-util

curl -L -O http://archive.apache.org/dist/apr/apr-util-1.5.4.tar.gz



# extract

tar -xzvf apr-util-1.5.4.tar.gz

cd apr-util-1.5.4



# configure, make, make install

./configure --with-apr=/usr/local/apr

# you need that extra parameter to configure because

# apr-util can't really find it because...who knows.



make

sudo make install



#cleanup

cd /tmp

rm -rf apr-util-1.5.4* apr-1.5.2*
```

I’m having you write this script out because it’s basically what we want `devpkg` to do, but with extra options and checks. In fact, you could just do it all in shell with less code, but then that wouldn’t be a very good program for a C book would it?

Simply run this script and fix it until it works, then you’ll have the libraries you need to complete the rest of this project.

### Project Layout

You need to set up some simple project files to get started. Here’s how I usually craft a new project:

`Exercise 41.2 Session`

---

```
mkdir devpkg

cd devpkg

touch README Makefile
```

#### Other Dependencies

You should have already installed apr-1.5.2 and apr-util-1.5.4, so now you need a few more files to use as basic dependencies:

• `dbg.h` from [Exercise 20](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch20.html#ch20).

• `bstrlib.h` and `bstrlib.c` from [http://bstring.sourceforge.net/](http://bstring.sourceforge.net/). Download the .zip file, extract it, and copy just those two files.

• Type `make bstrlib.o`, and if it doesn’t work, read the instructions for fixing `bstring` below.

---

Warning!

In some platforms, the `bstring.c` file will have an error like this:

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch41_images.html#p277pro01a)

```
bstrlib.c:2762: error: expected declaration\

specifiers or '...' before numeric constant
```

This is from a bad `define` that the authors added, which doesn’t always work. You just need to change line 2759 that reads `#ifdef __GNUC__` to read:

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch41_images.html#p277pro02a)

```
#if defined(__GNUC__) && !defined(__APPLE__)
```

and then it should work on OS X.

---

When that’s all done, you should have a `Makefile`, `README`, `dbg.h`, `bstrlib.h`, and `bstrlib.c` ready to go.

### The Makefile

A good place to start is the `Makefile` since this lays out how things are built and what source files you’ll be creating.

`Makefile`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch41_images.html#p278pro01a)

```
PREFIX?=/usr/local

CFLAGS=-g -Wall -I${PREFIX}/apr/include/apr-1

CFLAGS+=-I${PREFIX}/apr/include/apr-util-1

LDFLAGS=-L${PREFIX}/apr/lib -lapr-1 -pthread -laprutil-1



all: devpkg



devpkg: bstrlib.o db.o shell.o commands.o



install: all

    install -d $(DESTDIR)/$(PREFIX)/bin/

    install devpkg $(DESTDIR)/$(PREFIX)/bin/



clean:

    rm -f *.o

    rm -f devpkg

    rm -rf *.dSYM
```

There’s nothing in this that you haven’t seen before, except maybe the strange `?=` syntax, which says “set PREFIX equal to this unless PREFIX is already set.”

---

Warning!

If you’re on more recent versions of Ubuntu, and you get errors about `apr_off_t` or `off64_t`, then add `-D_LARGEFILE64_SOURCE=1` to `CFLAGS`. Another thing is that you need to add `/usr/local/apr/lib` to a file in `/etc/ld.conf.so.d/` and then run `ldconfig` so that it correctly picks up the libraries.

---

### The Source Files

From the `Makefile,` we see that there are five dependencies for `devpkg`:

**bstrlib.o** This comes from `bstrlib.c` and the header file `bstlib.h`, which you already have.

**db.o** This comes from `db.c` and header file `db.h`, and it will contain code for our little database routines.

**shell.o** This is from `shell.c` and header `shell.h`, as well as a couple of functions that make running other commands like `curl` easier.

**commands.o** This is from `command.c` and header `command.h`, and contains all of the commands that `devpkg` needs to be useful.

**devpkg** It’s not explicitly mentioned, but it’s the target (on the left) in this part of the `Makefile`. It comes from `devpkg.c`, which contains the `main` function for the whole program.

Your job is to now create each of these files, type in their code, and get them correct.

---

Warning!

You may read this description and think, “Man! How is it that Zed is so smart that he just sat down and typed these files out like this!? I could never do that.” I didn’t magically craft `devpkg` in this form with my awesome coding powers. Instead, what I did is this:

• I wrote a quick little `README` to get an idea of how I wanted it to work.

• I created a simple bash script (like the one you did earlier) to figure out all of the pieces that were needed.

• I made one .c file and hacked on it for a few days working through the idea and figuring it out.

• I got it mostly working and debugged, *then* I started breaking up the one big file into these four files.

• After getting these files laid down, I renamed and refined the functions and data structures so that they’d be more logical and pretty.

• Finally, after I had it working the *exact same* but with the new structure, I added a few features like the `-F` and `-B` options.

You’re reading this in the order I want to teach it to you, but don’t think this is how I always build software. Sometimes I already know the subject and I use more planning. Sometimes I just hack up an idea and see how well it’d work. Sometimes I write one, then throw it away and plan out a better one. It all depends on what my experience tells me is best or where my inspiration takes me.

If you run into a supposed expert who tries to tell you that there’s only one way to solve a programming problem, they’re lying to you. Either they actually use multiple tactics, or they’re not very good.

---

#### The DB Functions

There must be a way to record URLs that have been installed, list these URLs, and check whether something has already been installed so we can skip it. I’ll use a simple flat file database and the `bstrlib.h` library to do it.

First, create the `db.h` header file so you know what you’ll be implementing.

`db.h`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch41_images.html#p280pro01a)

```
#ifndef _db_h

#define _db_h



#define DB_FILE "/usr/local/.devpkg/db"

#define DB_DIR "/usr/local/.devpkg"





int DB_init();

int DB_list();

int DB_update(const char *url);

int DB_find(const char *url);



#endif
```

Then, implement those functions in `db.c`, and as you build this, use `make` to get it to compile cleanly.

`db.c`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch41_images.html#p280pro02a)

```
#include <unistd.h>

#include <apr_errno.h>

#include <apr_file_io.h>

  4

#include "db.h"

#include "bstrlib.h"

#include "dbg.h"

  8

static FILE *DB_open(const char *path, const char *mode)

{

return fopen(path, mode);

}

 13

static void DB_close(FILE * db)

{

fclose(db);

}

 18

static bstring DB_load()

{

FILE *db = NULL;

bstring data = NULL;

 23

db = DB_open(DB_FILE, "r");

check(db, "Failed to open database: %s", DB_FILE);

 26

data = bread((bNread) fread, db);

check(data, "Failed to read from db file: %s", DB_FILE);

 29

DB_close(db);

return data;

 32

error:

if (db)

DB_close(db);

if (data)

bdestroy(data);

return NULL;

}

 40

int DB_update(const char *url)

{

if (DB_find(url)) {

log_info("Already recorded as installed: %s", url);

}

 46

FILE *db = DB_open(DB_FILE, "a+");

check(db, "Failed to open DB file: %s", DB_FILE);

 49

bstring line = bfromcstr(url);

bconchar(line, '\n');

int rc = fwrite(line->data, blength(line), 1, db);

check(rc == 1, "Failed to append to the db.");

 54

return 0;

error:

if (db)

DB_close(db);

return -1;

}

 61

int DB_find(const char *url)

{

bstring data = NULL;

bstring line = bfromcstr(url);

int res = -1;

 67

data = DB_load();

check(data, "Failed to load: %s", DB_FILE);

 70

if (binstr(data, 0, line) == BSTR_ERR) {

res = 0;

} else {

res = 1;

}

 76

error:                   // fallthrough

if (data)

bdestroy(data);

if (line)

bdestroy(line);

 82

return res;

}

 85

int DB_init()

{

apr_pool_t *p = NULL;

apr_pool_initialize();

apr_pool_create(&p, NULL);

 91

if (access(DB_DIR, W_OK | X_OK) == -1) {

apr_status_t rc = apr_dir_make_recursive(DB_DIR,

APR_UREAD | APR_UWRITE

| APR_UEXECUTE |

APR_GREAD | APR_GWRITE

| APR_GEXECUTE, p);

check(rc == APR_SUCCESS, "Failed to make database dir: %s",

DB_DIR);

}

101

if (access(DB_FILE, W_OK) == -1) {

FILE *db = DB_open(DB_FILE, "w");

check(db, "Cannot open database: %s", DB_FILE);

DB_close(db);

}

107

apr_pool_destroy(p);

return 0;

110

error:

apr_pool_destroy(p);

return -1;

}

115

int DB_list()

{

bstring data = DB_load();

check(data, "Failed to read load: %s", DB_FILE);

120

printf("%s", bdata(data));

bdestroy(data);

return 0;

124

error:

return -1;

}
```

##### Challenge 1: Code Review

Before continuing, read every line of these files carefully and confirm that you have them entered in *exactly* as they appear here. Read them backward line by line to practice that. Also, trace each function call and make sure you’re using `check` to validate the return codes. Finally, look up *every* function that you don’t recognize—either in the APR Web site documentation or in the `bstrlib.h` and `bstrlib.c` source.

#### The Shell Functions

A key design decision for `devpkg` is to have external tools like `curl`, `tar`, and `git` do most of the work. We could find libraries to do all of this internally, but it’s pointless if we just need the base features of these programs. There is no shame in running another command in UNIX.

To do this, I’m going to use the `apr_thread_proc.h` functions to run programs, but I also want to make a simple kind of template system. I’ll use a `struct Shell` that holds all of the information needed to run a program, but has holes in the arguments list that I can replace with values.

Look at the `shell.h` file to see the structure and the commands that I’ll use. You can see that I’m using `extern` to indicate how other `.c` files can access variables that I’m defining in `shell.c`.

`shell.h`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch41_images.html#p283pro01a)

```
#ifndef _shell_h

#define _shell_h



#define MAX_COMMAND_ARGS 100



#include <apr_thread_proc.h>



typedef struct Shell {

    const char *dir;

    const char *exe;



    apr_procattr_t *attr;

    apr_proc_t proc;

    apr_exit_why_e exit_why;

    int exit_code;



    const char *args[MAX_COMMAND_ARGS];

} Shell;



int Shell_run(apr_pool_t * p, Shell * cmd);

int Shell_exec(Shell cmd, ...);



extern Shell CLEANUP_SH;

extern Shell GIT_SH;

extern Shell TAR_SH;

extern Shell CURL_SH;

extern Shell CONFIGURE_SH;

extern Shell MAKE_SH;

extern Shell INSTALL_SH;



#endif
```

Make sure you’ve created `shell.h` exactly as it appears here, and that you’ve got the same names and number of `extern Shell` variables. Those are used by the `Shell_run` and `Shell_exec` functions to run commands. I define these two functions, and create the real variables in `shell.c`.

`shell.c`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch41_images.html#p284pro01a)

```
#include "shell.h"

#include "dbg.h"

#include <stdarg.h>

  4

int Shell_exec(Shell template, ...)

{

apr_pool_t *p = NULL;

int rc = -1;

apr_status_t rv = APR_SUCCESS;

va_list argp;

const char *key = NULL;

const char *arg = NULL;

int i = 0;

 14

rv = apr_pool_create(&p, NULL);

check(rv == APR_SUCCESS, "Failed to create pool.");

 17

va_start(argp, template);

 19

for (key = va_arg(argp, const char *);

key != NULL; key = va_arg(argp, const char *)) {

arg = va_arg(argp, const char *);

 23

for (i = 0; template.args[i] != NULL; i++) {

if (strcmp(template.args[i], key) == 0) {

template.args[i] = arg;

break;              // found it

}

}

}

 31

rc = Shell_run(p, &template);

apr_pool_destroy(p);

va_end(argp);

return rc;

 36

error:

if (p) {

apr_pool_destroy(p);

}

return rc;

}

 43

int Shell_run(apr_pool_t * p, Shell * cmd)

{

apr_procattr_t *attr;

apr_status_t rv;

apr_proc_t newproc;

 49

rv = apr_procattr_create(&attr, p);

check(rv == APR_SUCCESS, "Failed to create proc attr.");

 52

rv = apr_procattr_io_set(attr, APR_NO_PIPE, APR_NO_PIPE,

APR_NO_PIPE);

check(rv == APR_SUCCESS, "Failed to set IO of command.");

 56

rv = apr_procattr_dir_set(attr, cmd->dir);

check(rv == APR_SUCCESS, "Failed to set root to %s", cmd->dir);

 59

rv = apr_procattr_cmdtype_set(attr, APR_PROGRAM_PATH);

check(rv == APR_SUCCESS, "Failed to set cmd type.");

 62

rv = apr_proc_create(&newproc, cmd->exe, cmd->args, NULL, attr, p);

check(rv == APR_SUCCESS, "Failed to run command.");

 65

rv = apr_proc_wait(&newproc, &cmd->exit_code, &cmd->exit_why,

APR_WAIT);

check(rv == APR_CHILD_DONE, "Failed to wait.");

 69

check(cmd->exit_code == 0, "%s exited badly.", cmd->exe);

check(cmd->exit_why == APR_PROC_EXIT, "%s was killed or crashed",

cmd->exe);

 73

return 0;

 75

error:

return -1;

}

 79

Shell CLEANUP_SH = {

.exe = "rm",

.dir = "/tmp",

.args = {"rm", "-rf", "/tmp/pkg-build", "/tmp/pkg-src.tar.gz",

"/tmp/pkg-src.tar.bz2", "/tmp/DEPENDS", NULL}

};

 86

Shell GIT_SH = {

.dir = "/tmp",

.exe = "git",

.args = {"git", "clone", "URL", "pkg-build", NULL}

};

 92

Shell TAR_SH = {

.dir = "/tmp/pkg-build",

.exe = "tar",

.args = {"tar", "-xzf", "FILE", "--strip-components", "1", NULL}

};

 98

Shell CURL_SH = {

.dir = "/tmp",

.exe = "curl",

.args = {"curl", "-L", "-o", "TARGET", "URL", NULL}

};

104

Shell CONFIGURE_SH = {

.exe = "./configure",

.dir = "/tmp/pkg-build",

.args = {"configure", "OPTS", NULL}

,

};

111

Shell MAKE_SH = {

.exe = "make",

.dir = "/tmp/pkg-build",

.args = {"make", "OPTS", NULL}

};

117

Shell INSTALL_SH = {

.exe = "sudo",

.dir = "/tmp/pkg-build",

.args = {"sudo", "make", "TARGET", NULL}

};
```

Read the `shell.c` from the bottom to the top (which is a common C source layout) and you see how I’ve created the actual `Shell` variables that you indicated were `extern` in `shell.h`. They live here, but are available to the rest of the program. This is how you make global variables that live in one `.o` file but are used everywhere. You shouldn’t make many of these, but they are handy for things like this.

Continuing up the file we get to the `Shell_run` function, which is a base function that just runs a command according to what’s in a `Shell` struct. It uses many of the functions defined in `apr_thread_proc.h`, so go look up each one to see how the base function works. This seems like a lot of work compared to just using the `system` function call, but it also gives you more control over the other program’s execution. For example, in our `Shell` struct, we have a `.dir` attribute that forces the program to be in a specific directory before running.

Finally, I have the `Shell_exec` function, which is a variable argument function. You’ve seen this before, but make sure you grasp the `stdarg.h` functions. In the challenge for this section, you’re going to analyze this function.

##### Challenge 2: Analyze Shell_exec

The challenge for these files (in addition to a full code review like you did in Challenge 1) is to fully analyze `Shell_exec` and break down exactly how it works. You should be able to understand each line, how the two `for-loop`s work, and how arguments are being replaced.

Once you have it analyzed, add a field to `struct Shell` that gives you the number of variable `args` that must be replaced. Update all of the commands to have the right count of args, and have an error check to confirm that these args have been replaced, and then error exit.

#### The Command Functions

Now you get to make the actual commands that do the work. These commands will use functions from APR, `db.h`, and `shell.h` to do the real work of downloading and building the software that you want it to build. This is the most complex set of files, so do them carefully. As before, you start by making the `commands.h` file, then implementing its functions in the `commands.c` file.

`commands.h`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch41_images.html#p287pro01a)

```
#ifndef _commands_h

#define _commands_h



#include <apr_pools.h>



#define DEPENDS_PATH "/tmp/DEPENDS"

#define TAR_GZ_SRC "/tmp/pkg-src.tar.gz"

#define TAR_BZ2_SRC "/tmp/pkg-src.tar.bz2"

#define BUILD_DIR "/tmp/pkg-build"

#define GIT_PAT "*.git"

#define DEPEND_PAT "*DEPENDS"

#define TAR_GZ_PAT "*.tar.gz"

#define TAR_BZ2_PAT "*.tar.bz2"

#define CONFIG_SCRIPT "/tmp/pkg-build/configure"



enum CommandType {

    COMMAND_NONE, COMMAND_INSTALL, COMMAND_LIST, COMMAND_FETCH,

    COMMAND_INIT, COMMAND_BUILD

};



int Command_fetch(apr_pool_t * p, const char *url, int fetch_only);



int Command_install(apr_pool_t * p, const char *url,

        const char *configure_opts,

        const char *make_opts, const char *install_opts);



int Command_depends(apr_pool_t * p, const char *path);



int Command_build(apr_pool_t * p, const char *url,

        const char *configure_opts, const char *make_opts,

        const char *install_opts);



#endif
```

There’s not much in `commands.h` that you haven’t seen already. You should see that there are some `define`s for strings that are used everywhere. The really interesting code is in `commands.c`.

`commands.c`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch41_images.html#p288pro01a)

```
#include <apr_uri.h>

#include <apr_fnmatch.h>

#include <unistd.h>

  4

#include "commands.h"

#include "dbg.h"

#include "bstrlib.h"

#include "db.h"

#include "shell.h"

 10

int Command_depends(apr_pool_t * p, const char *path)

{

FILE *in = NULL;

bstring line = NULL;

 15

in = fopen(path, "r");

check(in != NULL, "Failed to open downloaded depends: %s", path);

 18

for (line = bgets((bNgetc) fgetc, in, '\n');

line != NULL;

line = bgets((bNgetc) fgetc, in, '\n'))

{

btrimws(line);

log_info("Processing depends: %s", bdata(line));

int rc = Command_install(p, bdata(line), NULL, NULL, NULL);

check(rc == 0, "Failed to install: %s", bdata(line));

bdestroy(line);

}

 29

fclose(in);

return 0;

 32

error:

if (line) bdestroy(line);

if (in) fclose(in);

return -1;

}

 38

int Command_fetch(apr_pool_t * p, const char *url, int fetch_only)

{

apr_uri_t info = {.port = 0    };

int rc = 0;

const char *depends_file = NULL;

apr_status_t rv = apr_uri_parse(p, url, &info);

 45

check(rv == APR_SUCCESS, "Failed to parse URL: %s", url);

 47

if (apr_fnmatch(GIT_PAT, info.path, 0) == APR_SUCCESS) {

rc = Shell_exec(GIT_SH, "URL", url, NULL);

check(rc == 0, "git failed.");

} else if (apr_fnmatch(DEPEND_PAT, info.path, 0) == APR_SUCCESS) {

check(!fetch_only, "No point in fetching a DEPENDS file.");

 53

if (info.scheme) {

depends_file = DEPENDS_PATH;

rc = Shell_exec(CURL_SH, "URL", url, "TARGET", depends_file,

NULL);

check(rc == 0, "Curl failed.");

} else {

depends_file = info.path;

}

 62

// recursively process the devpkg list

log_info("Building according to DEPENDS: %s", url);

rv = Command_depends(p, depends_file);

check(rv == 0, "Failed to process the DEPENDS: %s", url);

 67

// this indicates that nothing needs to be done

return 0;

 70

} else if (apr_fnmatch(TAR_GZ_PAT, info.path, 0) == APR_SUCCESS) {

if (info.scheme) {

rc = Shell_exec(CURL_SH,

"URL", url, "TARGET", TAR_GZ_SRC, NULL);

check(rc == 0, "Failed to curl source: %s", url);

}

 77

rv = apr_dir_make_recursive(BUILD_DIR,

APR_UREAD | APR_UWRITE |

APR_UEXECUTE, p);

check(rv == APR_SUCCESS, "Failed to make directory %s",

BUILD_DIR);

 83

rc = Shell_exec(TAR_SH, "FILE", TAR_GZ_SRC, NULL);

check(rc == 0, "Failed to untar %s", TAR_GZ_SRC);

} else if (apr_fnmatch(TAR_BZ2_PAT, info.path, 0) == APR_SUCCESS) {

if (info.scheme) {

rc = Shell_exec(CURL_SH, "URL", url, "TARGET", TAR_BZ2_SRC,

NULL);

check(rc == 0, "Curl failed.");

}

 92

apr_status_t rc = apr_dir_make_recursive(BUILD_DIR,

APR_UREAD | APR_UWRITE

| APR_UEXECUTE, p);

 96

check(rc == 0, "Failed to make directory %s", BUILD_DIR);

rc = Shell_exec(TAR_SH, "FILE", TAR_BZ2_SRC, NULL);

check(rc == 0, "Failed to untar %s", TAR_BZ2_SRC);

} else {

sentinel("Don't now how to handle %s", url);

}

103

// indicates that an install needs to actually run

return 1;

error:

return -1;

}

109

int Command_build(apr_pool_t * p, const char *url,

const char *configure_opts, const char *make_opts,

const char *install_opts)

{

int rc = 0;

115

check(access(BUILD_DIR, X_OK | R_OK | W_OK) == 0,

"Build directory doesn't exist: %s", BUILD_DIR);

118

// actually do an install

if (access(CONFIG_SCRIPT, X_OK) == 0) {

log_info("Has a configure script, running it.");

rc = Shell_exec(CONFIGURE_SH, "OPTS", configure_opts, NULL);

check(rc == 0, "Failed to configure.");

}

125

rc = Shell_exec(MAKE_SH, "OPTS", make_opts, NULL);

check(rc == 0, "Failed to build.");

128

rc = Shell_exec(INSTALL_SH,

"TARGET", install_opts ? install_opts : "install",

NULL);

check(rc == 0, "Failed to install.");

133

rc = Shell_exec(CLEANUP_SH, NULL);

check(rc == 0, "Failed to cleanup after build.");

136

rc = DB_update(url);

check(rc == 0, "Failed to add this package to the database.");

139

return 0;

141

error:

return -1;

}

145

int Command_install(apr_pool_t * p, const char *url,

const char *configure_opts, const char *make_opts,

const char *install_opts)

{

int rc = 0;

check(Shell_exec(CLEANUP_SH, NULL) == 0,

"Failed to cleanup before building.");

153

rc = DB_find(url);

check(rc != -1, "Error checking the install database.");

156

if (rc == 1) {

log_info("Package %s already installed.", url);

return 0;

}

161

rc = Command_fetch(p, url, 0);

163

if (rc == 1) {

rc = Command_build(p, url, configure_opts, make_opts,

install_opts);

check(rc == 0, "Failed to build: %s", url);

} else if (rc == 0) {

// no install needed

log_info("Depends successfully installed: %s", url);

} else {

// had an error

sentinel("Install failed: %s", url);

}

175

Shell_exec(CLEANUP_SH, NULL);

return 0;

178

error:

Shell_exec(CLEANUP_SH, NULL);

return -1;

}
```

After you have this entered in and compiling, you can analyze it. If you’ve done the challenges thus far, you should see how the `shell.c` functions are being used to run shells, and how the arguments are being replaced. If not, then go back and make sure you *truly* understand how `Shell_exec` actually works.

##### Challenge 3: Critique My Design

As before, do a complete review of this code and make sure it’s exactly the same. Then go through each function and make sure you know how they work and what they’re doing. You should also trace how each function calls the other functions you’ve written in this file and other files. Finally, confirm that you understand all of the functions that you’re calling from APR here.

Once you have the file correct and analyzed, go back through and assume that I’m an idiot. Then, criticize the design I have to see how you can improve it if you can. Don’t *actually* change the code, just create a little `notes.txt` file and write down some thoughts about what you might change.

#### The devpkg Main Function

The last and most important file, but probably the simplest, is `devpkg.c`, which is where the `main` function lives. There’s no `.h` file for this, since it includes all of the others. Instead, this just creates the executable `devpkg` when combined with the other `.o` files from our `Makefile`. Enter in the code for this file, and make sure it’s correct.

`devpkg.c`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch41_images.html#p292pro01a)

```
#include <stdio.h>

#include <apr_general.h>

#include <apr_getopt.h>

#include <apr_strings.h>

#include <apr_lib.h>

  6

#include "dbg.h"

#include "db.h"

#include "commands.h"

 10

int main(int argc, const char const *argv[])

{

apr_pool_t *p = NULL;

apr_pool_initialize();

apr_pool_create(&p, NULL);

 16

apr_getopt_t *opt;

apr_status_t rv;

 19

char ch = '\0';

const char *optarg = NULL;

const char *config_opts = NULL;

const char *install_opts = NULL;

const char *make_opts = NULL;

const char *url = NULL;

enum CommandType request = COMMAND_NONE;

 27

rv = apr_getopt_init(&opt, p, argc, argv);

 29

while (apr_getopt(opt, "I:Lc:m:i:d:SF:B:", &ch, &optarg) ==

APR_SUCCESS) {

switch (ch) {

case 'I':

request = COMMAND_INSTALL;

url = optarg;

break;

 37

case 'L':

request = COMMAND_LIST;

break;

 41

case 'c':

config_opts = optarg;

break;

 45

case 'm':

make_opts = optarg;

break;

 49

case 'i':

install_opts = optarg;

break;

 53

case 'S':

request = COMMAND_INIT;

break;

 57

case 'F':

request = COMMAND_FETCH;

url = optarg;

break;

 62

case 'B':

request = COMMAND_BUILD;

url = optarg;

break;

}

}

 69

switch (request) {

case COMMAND_INSTALL:

check(url, "You must at least give a URL.");

Command_install(p, url, config_opts, make_opts, install_opts);

break;

 75

case COMMAND_LIST:

DB_list();

break;

 79

case COMMAND_FETCH:

check(url != NULL, "You must give a URL.");

Command_fetch(p, url, 1);

log_info("Downloaded to %s and in /tmp/", BUILD_DIR);

break;

 85

case COMMAND_BUILD:

check(url, "You must at least give a URL.");

Command_build(p, url, config_opts, make_opts, install_opts);

break;

 90

case COMMAND_INIT:

rv = DB_init();

check(rv == 0, "Failed to make the database.");

break;

 95

default:

sentinel("Invalid command given.");

}

 99

return 0;

101

error:

return 1;

}
```

##### Challenge 4: The README and Test Files

The challenge for this file is to understand how the arguments are being processed, what the arguments are, and then create the `README` file with instructions on how to use them. As you write the `README`, also write a simple `test.sh` that runs `./devpkg` to check that each command is actually working against real, live code. Use the `set -e` at the top of your script so that it aborts on the first error.

Finally, run the program under your debugger and make sure it’s working before moving on to the final challenge.

### The Final Challenge

Your final challenge is a mini exam and it involves three things:

• Compare your code to my code that’s available online. Starting at 100%, subtract 1% for each line you got wrong.

• Take the `notes.txt` file that you previously created and implement your improvements to the the code and functionality of `devpkg`.

• Write an alternative version of `devpkg` using your other favorite language or the one you think can do this the best. Compare the two, then improve your *C* version of `devpkg` based on what you’ve learned.

To compare your code with mine, do the following:

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch41_images.html#p295pro01a)

```
cd .. # get one directory above your current one

git clone git://gitorious.org/devpkg/devpkg.git devpkgzed

diff -r devpkg devpkgzed
```

This will clone my version of `devpkg` into a directory called `devpkgzed` so you can then use the tool `diff` to compare what you’ve done to what I did. The files you’re working with in this book come directly from this project, so if you get different lines, that’s an error.

Keep in mind that there’s no real pass or fail on this exercise. It’s just a way for you to challenge yourself to be as exact and meticulous as possible.
