# [](/book/tiny-c-projects/chapter-11/)11 File finder

[](/book/tiny-c-projects/chapter-11/)Back in [](/book/tiny-c-projects/chapter-11/)[](/book/tiny-c-projects/chapter-11/)ancient times, one of the most popular MS-DOS utilities I wrote was the Fast File Finder. It wasn’t particularly fast, of course. But it did the job of finding a file anywhere on the PC’s hard drive when given a filename. This program was included on the companion floppy diskettes provided with many of my early computing books. Yes, floppy diskettes.

[](/book/tiny-c-projects/chapter-11/)In today’s operating systems, finding files is a big deal. Both Windows and Mac OS X feature powerful file-finding tools, locating files by not only name but also date, size, and content. The Linux command prompt offers its own slate of file-finding tools, just as powerful (if not more so) as their graphical counterparts. For a budding C programmer, or anyone desiring to build their C kung fu, using these tools is useful, but you can’t improve your programming skills by just using the tools.

[](/book/tiny-c-projects/chapter-11/)Hunting for files, and potentially doing something with them, relies upon the directory-spelunking tools covered in chapter 10. From this base, you can expand your knowledge of C by:

-  [](/book/tiny-c-projects/chapter-11/)Reviewing other file-finding utilities
-  [](/book/tiny-c-projects/chapter-11/)Exploring methods for finding text
-  [](/book/tiny-c-projects/chapter-11/)Locating files in a directory tree
-  [](/book/tiny-c-projects/chapter-11/)Using wildcards to match files
-  [](/book/tiny-c-projects/chapter-11/)Finding filename duplicates

[](/book/tiny-c-projects/chapter-11/)When I program a utility, especially one that’s similar to one that’s already available, I look for improvements. Many command-line tools feature a parade of options and features. These switches make the command powerful but beyond what I need. I find the abundance of options overwhelming. Better for me is to build a more specific version of the utility. Although such a program may not have the muscle of something coded by expert C programmers of yore, it’s specific to my needs. By writing your own file tools, you learn more about programming in C, plus you get a tool you can use—and customize to your workflow.

[](/book/tiny-c-projects/chapter-11/)My [](/book/tiny-c-projects/chapter-11/)[](/book/tiny-c-projects/chapter-11/)[](/book/tiny-c-projects/chapter-11/)[](/book/tiny-c-projects/chapter-11/)personal-file finding utilities are based on frustration with the existing crop of Linux file finding tools—specifically, *find*[](/book/tiny-c-projects/chapter-11/) and *grep*[](/book/tiny-c-projects/chapter-11/).

[](/book/tiny-c-projects/chapter-11/)Nothing is wrong with these commands that some well-chosen curse words can’t address. Still, I find myself unable to commit the command formats and options to memory. I constantly refer to the documentation when it comes to using these file-finding tools. I understand that this admission could get me kicked out of the neighborhood computer club.

[](/book/tiny-c-projects/chapter-11/)The *find* command[](/book/tiny-c-projects/chapter-11/) is powerful. In Linux, such power implies options galore, often more command-line switches available than letters of the alphabet—upper- and lowercase. This complexity explains why many nerds resort instead to using GUI file-search tools instead of a terminal window to locate lost files.

[](/book/tiny-c-projects/chapter-11/)Here is the deceptively simple format for the find command[](/book/tiny-c-projects/chapter-11/):

```
find path way-too-many-options
```

[](/book/tiny-c-projects/chapter-11/)Yep. Easy.

[](/book/tiny-c-projects/chapter-11/)Suppose you want to locate a file named `budget.csv,` located somewhere in your home directory tree. Here is the command to use:

```
find ~ -name budget.csv -print
```

[](/book/tiny-c-projects/chapter-11/)The pathname is `~,` shortcut for your home directory. The `-name` switch[](/book/tiny-c-projects/chapter-11/) identifies the file to locate, `budget.csv`. The final switch, `-print`[](/book/tiny-c-projects/chapter-11/) (the one everyone forgets), directs the *find* command[](/book/tiny-c-projects/chapter-11/) to send the results to standard output. You may think something like output would be the necessary default, but the *find* command[](/book/tiny-c-projects/chapter-11/) can do more with found files than send their names to standard output.

[](/book/tiny-c-projects/chapter-11/)The *find* command’s[](/book/tiny-c-projects/chapter-11/) desired output may appear on a line by itself, which is fortunate. More common is that you must sift through a long series of errors and duplicate matches. Eventually the desired file is found, and its path revealed:

```
/home/dang/documents/financial/budget.csv
```

[](/book/tiny-c-projects/chapter-11/)Yes, you can create an alias to the specific *find* utility format you use often. No, I’m not going to get into a debate about how powerful and useful the *find* command[](/book/tiny-c-projects/chapter-11/) is or why I’m a dweeb for not comparing it with a sunshine lollypop for delicious goodness.

[](/book/tiny-c-projects/chapter-11/)The other file-finding command is *grep*[](/book/tiny-c-projects/chapter-11/), which I use specifically to locate files containing a specific tidbit of text. In fact, I’ve used `grep` many times when writing this book to locate defined constants in header files. From the `/usr/include` directory, here is the command to locate the `time_t`[](/book/tiny-c-projects/chapter-11/) defined constant in various header files:

```
grep -r "time_t" *
```

[](/book/tiny-c-projects/chapter-11/)The `-r` switch[](/book/tiny-c-projects/chapter-11/) directs *grep* to recursively look through directories. The string to find is `time_t` and the `*` wildcard directs the program to search all filenames.

[](/book/tiny-c-projects/chapter-11/)Many lines of text spew forth when issuing this command, because the `time_t` defined constant[](/book/tiny-c-projects/chapter-11/) is referenced in multiple header files. Even this trick didn’t locate the specific definition I wanted, though it pointed me in the right direction.

[](/book/tiny-c-projects/chapter-11/)These utilities—*find* and *grep* (and its better cousin, *egrep*)—are wonderful and powerful. Yet I want something friendly and usable without the requirement of chronically checking *man* pages or referring to hefty command-line reference books. This is why I code my own versions, covered in this chapter.

[](/book/tiny-c-projects/chapter-11/)With your knowledge of C, you can easily code your own file-finding utilities specific to your needs, as complex or as simple as you desire. Then, if you forget any of the options, you have only yourself to [](/book/tiny-c-projects/chapter-11/)[](/book/tiny-c-projects/chapter-11/)[](/book/tiny-c-projects/chapter-11/)[](/book/tiny-c-projects/chapter-11/)blame.

## [](/book/tiny-c-projects/chapter-11/)11.2 A file finder

[](/book/tiny-c-projects/chapter-11/)My goal for finding files is to type a command like this:

```
find thisfile.txt
```

[](/book/tiny-c-projects/chapter-11/)The utility digs deep through the current directory tree, scouring subdirectory after subdirectory, hunting for the specific file. If found, the full pathname is output—useful information to me. Add in the capability of using wildcards to locate files, and I’ll never need the *find* command again—in the specific format to locate a file.

[](/book/tiny-c-projects/chapter-11/)Oh, yeah—I suppose my own utility must be named something other than *find*, already used in Linux. How about *ff* for *Find File*?

### [](/book/tiny-c-projects/chapter-11/)11.2.1 Coding the Find File utility

[](/book/tiny-c-projects/chapter-11/)Chapter 10 [](/book/tiny-c-projects/chapter-11/)[](/book/tiny-c-projects/chapter-11/)covers the process of directory exploration, using the recursive *dir()* function[](/book/tiny-c-projects/chapter-11/) to plumb subdirectory depths. Building upon this function is perfect for creating a file-finding utility. The goal is to scan directories and compare those files found with a matching filename supplied by the user.

[](/book/tiny-c-projects/chapter-11/)The *Find File* utility presented in this chapter doesn’t use the same *dir()* function from chapter 10. No, the recursive directory-finding function requires modification to locate specific files, not all files. I’ve renamed the function *find[](/book/tiny-c-projects/chapter-11/)()* because I know the name would infuriate the find utility.

[](/book/tiny-c-projects/chapter-11/)My *find()* function[](/book/tiny-c-projects/chapter-11/) features the same first two arguments as *dir()* from chapter 10. But as shown in the next listing, this updated function adds a third argument, `match`, to help hunt for the named file. Other differences between *dir()* and *find()* are commented in the listing.

##### Listing 11.1 The recursive *find()* function

```
void find(char *dirpath,char *parentpath,char *match)
{
    DIR *dp;
    struct dirent *entry;
    struct stat fs;
    char subdirpath[PATH_MAX];                        #1
 
    dp = opendir(dirpath);
    if( dp==NULL )
    {
        fprintf(stderr,"Unable to read directory '%s'\n",
                dirpath
               );
        exit(1);
    }
 
    while( (entry=readdir(dp)) != NULL )
    {
        if( strcmp(entry->d_name,match)==0 )          #2
        {
            printf("%s/%s\n",dirpath,match);          #3
            count++;                                  #4
        }
 
        stat(entry->d_name,&fs);
        if( S_ISDIR(fs.st_mode) )
        {
            if( strncmp( entry->d_name,".",1)==0 )    #5
                continue;
            if( chdir(entry->d_name)==-1 )
            {
                fprintf(stderr,"Unable to change to %s\n",
                        entry->d_name
                       );
                exit(1);
            }
 
            getcwd(subdirpath,BUFSIZ);
            find(subdirpath,dirpath,match);           #6
        }
    }
 
    closedir(dp);
 
    if( chdir(parentpath)==-1 )
    {
        if( parentpath==NULL )
            return;
        fprintf(stderr,"Parent directory lost\n");
        exit(1);
    }
}
```

[](/book/tiny-c-projects/chapter-11/)Beyond the additions noted in listing 11.1, I use the `PATH_MAX` defined constant, which requires including the `limits.h` header file. Because not every C library implements `PATH_MAX`, some preprocessor directives are required:

```
#ifndef PATH_MAX
#define PATH_MAX 256
#endif
```

[](/book/tiny-c-projects/chapter-11/)The value of `PATH_MAX` differs depending on the operating system. For example, in Windows it could be 260 bytes, but in my version of Ubuntu Linux, it’s 1024. I’ve seen it as high as 4096 bytes, so 256 seems like a good value that won’t blow up anything. If you want to define a higher value, feel free to do so.

[](/book/tiny-c-projects/chapter-11/)My *Find File* utility also counts matched files. To keep track, I use the variable `count`[](/book/tiny-c-projects/chapter-11/), which is defined externally. I am loath to use global variables, but in this situation having `count` be external is an effective way to keep track of files found. Otherwise, I could include `count` as a fourth argument to the *find()* function[](/book/tiny-c-projects/chapter-11/), but as a recursive function, maintaining its value consistently introduces all kinds of chaos.

[](/book/tiny-c-projects/chapter-11/)The source code that includes the *find()* function[](/book/tiny-c-projects/chapter-11/) is named `findfile01.c`[](/book/tiny-c-projects/chapter-11/), where the *main()* function is shown in the following listing. The *main()* function’s job is to fetch the filename from the command line, retrieve the current path, make the call to the *find()* function[](/book/tiny-c-projects/chapter-11/), and then report the results. The *main()* function is shown here.

##### Listing 11.2 The *main()* function from findfile01.c

```
int main(int argc, char *argv[])
{
    char current[PATH_MAX];
 
    if( argc<2 )                            #1
    {
        fprintf(stderr,"Format: ff filename\n");
        exit(1);
    }
 
    getcwd(current,PATH_MAX);
    if( chdir(current)==-1 )
    {
        fprintf(stderr,"Unable to access directory %s\n",
                current
               );
            exit(1);
    }
 
    count = 0;                              #2
    printf("Searching for '%s'\n",argv[1]);
    find(current,NULL,argv[1]);             #3
    printf(" Found %d match",count);        #4
    if( count!=1 )                          #5
        printf("es");
    putchar('\n');
    return(0);
}
```

[](/book/tiny-c-projects/chapter-11/)Both *find()* and *main()* are included in the source code file `findfile01.c`[](/book/tiny-c-projects/chapter-11/), available in this book’s online repository. I’ve built the source code into the program file named *ff*. Here are a few sample runs:

```bash
$ ff a.out
Searching for 'a.out'
/Users/Dan/code/a.out
/Users/Dan/code/communications/a.out
/Users/Dan/code/communications/networking/a.out
/Users/Dan/Tiny C Projects/code/08_unicode/a.out
/Users/Dan/Tiny C Projects/code/11_filefind/a.out
Found 5 matches
```

[](/book/tiny-c-projects/chapter-11/)The *Find File* utility locates all the `a.out` files in my home directory tree:

```bash
$ ff hello
Searching for 'hello'
Found 0 matches
```

[](/book/tiny-c-projects/chapter-11/)In the previous example, the utility doesn’t find any files named `hello`:

```bash
$ ff *.c
Searching for 'finddupe01.c'
/Users/Dan/Tiny C Projects/code/11_filefind/finddupe01.c
Found 1 match
```

[](/book/tiny-c-projects/chapter-11/)The utility attempts to locate all files with the .c extension in the current directory. Rather than return them all, you see only the first match reported: `finddupe01.c`. The problem here is that the code doesn’t recognize wildcards; it finds only specific filenames.

[](/book/tiny-c-projects/chapter-11/)To match files with wildcards, you must understand something known as the glob. Unlike The Blob, star of the eponymous 1958 horror film, knowing the glob won’t get you [](/book/tiny-c-projects/chapter-11/)[](/book/tiny-c-projects/chapter-11/)killed.

### [](/book/tiny-c-projects/chapter-11/)11.2.2 Understanding the glob

[](/book/tiny-c-projects/chapter-11/)A [](/book/tiny-c-projects/chapter-11/)[](/book/tiny-c-projects/chapter-11/)[](/book/tiny-c-projects/chapter-11/)glob can be an insidious lump of goo from outer space, but in the computer world, it’s short for *glob*al[](/book/tiny-c-projects/chapter-11/). Specifically, *glob*[](/book/tiny-c-projects/chapter-11/) is a way to use wildcards to specify or match filenames. Most humans I know prefer to say “wildcard” as opposed to “glob.” But in the programming realm, the term is *glob*[](/book/tiny-c-projects/chapter-11/), the process is *globbing*, and people who glob are globbers. The C library function worthy of attention is *glob[](/book/tiny-c-projects/chapter-11/)()*.

[](/book/tiny-c-projects/chapter-11/)As a review, the filename wildcards are:

-  [](/book/tiny-c-projects/chapter-11/)`?` to match a single character
-  [](/book/tiny-c-projects/chapter-11/)`*` to match a group of more than one character

[](/book/tiny-c-projects/chapter-11/)In Windows, globbing takes place automatically. But in the Linux environment, the glob feature must be activated for wildcards to expand. If not, the `*` and `?` wildcards are interpreted literally, which isn’t what most users expect.

[](/book/tiny-c-projects/chapter-11/)To ensure that globbing is active, type the **set -o** command[](/book/tiny-c-projects/chapter-11/). In the output, the *noglob* option[](/book/tiny-c-projects/chapter-11/) should be set to *off*:

```
noglob   off
```

[](/book/tiny-c-projects/chapter-11/)If you see that the option is on, use this command:

```
set +o noglob
```

[](/book/tiny-c-projects/chapter-11/)When globbing is active, the shell expands the `?` and `*` wildcards to match files. In the preceding section, the input provided is `*.c`. Yet the program processed only one file named `finddupe01.c`. The filename is a match, but it’s not the only `*.c` filename in the directory. What gives?

[](/book/tiny-c-projects/chapter-11/)The code in the next listing helps you understand how globbing works when wildcards are typed at the command prompt. The program generated from `glob01.c` loops through all command-line options typed, minus the first item, which is the program filename.

##### Listing 11.3 Source code for glob01.c

```
#include <stdio.h>
 
int main(int argc, char *argv[])
{
    int x;
 
    if( argc>1 )                    #1
    {
        for( x=1; x<argc; x++ )     #2
            printf("%s\n",argv[x]);
    }
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-11/)Here is a sample run of the program created from `glob01.c`, which is named `a.out`:

```bash
$ ./a.out this that the other
this
that
the
other
```

[](/book/tiny-c-projects/chapter-11/)The program dutifully echoes all command-line options. Now try running the same program, but with a wildcard specified:

```bash
$ ./a.out *.c
finddupe01.c
finddupe02.c
finddupe03.c
finddupe04.c
finddupe05.c
findfile01.c

findfile02.c
glob01.c
glob02.c
```

[](/book/tiny-c-projects/chapter-11/)The `*.c` wildcard (globby thing) is expanded by the shell, which feeds each matching filename from the current directory to the program as a command-line argument. Instead of a single argument, `*.c`, multiple arguments are supplied.

[](/book/tiny-c-projects/chapter-11/)The problem with globbing is that your program really doesn’t know whether multiple command-line arguments are supplied or a single wildcard is typed and expanded. Further, because the wildcard argument is translated into multiple matching files, you have no way of knowing which wildcard was specified. Perhaps some way exists, because I know utilities that can perform wildcard matching in amazing ways, but I’ve yet to discover what this magic is.

[](/book/tiny-c-projects/chapter-11/)Rather than be flustered, you can rely upon the *glob()* function[](/book/tiny-c-projects/chapter-11/) to do the pattern matching for you. Here is the *man* page format[](/book/tiny-c-projects/chapter-11/):

```
int glob(const char *pattern, int flags, int (*errfunc) (const char *epath, int eerrno), glob_t *pglob);
```

[](/book/tiny-c-projects/chapter-11/)The function has four arguments:

-  [](/book/tiny-c-projects/chapter-11/)`const` `char` `*pattern` is a pathname wildcard pattern to match.
-  [](/book/tiny-c-projects/chapter-11/)`int` `flags` are options to customize the function’s behavior, usually a series of defined constants logically OR’d together.
-  [](/book/tiny-c-projects/chapter-11/)`int` `(*errfunc)` is the name of an error-handling function (along with its two arguments), which is necessary because the *glob()* function[](/book/tiny-c-projects/chapter-11/) can be quirky. Specify NULL to use the default error handler.
-  [](/book/tiny-c-projects/chapter-11/)`glob_t` `*pglob` is a structure containing details about the matching files. Two useful members are `gl_pathc`, which lists the number of matching files, and `gl_pathv`, which serves as the base of a pointer list referencing matching filenames in the current directory.

[](/book/tiny-c-projects/chapter-11/)The *glob()* function[](/book/tiny-c-projects/chapter-11/) returns zero on success. Other return values include defined constants you can test to determine whether the function screwed up or failed to find any matching files.

[](/book/tiny-c-projects/chapter-11/)More scintillating details are available about the *glob()* function[](/book/tiny-c-projects/chapter-11/) in the *man* pages[](/book/tiny-c-projects/chapter-11/). Pay special attention to the `flags` argument because it’s easy for various issues to arise.

[](/book/tiny-c-projects/chapter-11/)You must include the `glob.h` header file in your source code to keep the compiler content with the *glob()* function[](/book/tiny-c-projects/chapter-11/).

[](/book/tiny-c-projects/chapter-11/)In the next listing, the source code for `glob02.c` uses the *glob()* function[](/book/tiny-c-projects/chapter-11/) to scan for matching files in the current directory. The user is prompted for input. The input string is scrubbed of any newlines. The glob() function[](/book/tiny-c-projects/chapter-11/) is called to process input, searching for filenames that match any wildcards specified. Finally, a *while* loop outputs the matching filenames.

##### Listing 11.4 Source code for glob02.c

```
#include <stdio.h>
#include <stdlib.h>
#include <glob.h>
#include <limits.h>                                                  #1
 
#ifndef PATH_MAX                                                     #2
#define PATH_MAX 256
#endif
 
int main()
{
    char filename[PATH_MAX];
    char *r;
    int g;                                                           #3
    glob_t gstruct;                                                  #4
    char **found;                                                    #5
 
    printf("Filename or wildcard: ");                                #6
    r = fgets(filename,PATH_MAX,stdin);
    if( r==NULL )
        exit(1);
    while( *r!='\0' )
    {
        if( *r=='\n' )
        {
            *r = '\0';
            break;
        }
        r++;
    }
 
    g = glob(filename, GLOB_ERR , NULL, &gstruct);                   #7
    if( g!=0 )                                                       #8
    {
        if( g==GLOB_NOMATCH )
            fprintf(stderr,"No matches for '%s'\n",filename);
        else
            fprintf(stderr,"Some kinda glob error\n");
        exit(1);
    }
 
    printf("Found %zu filename matches\n",[CA]gstruct.gl_pathc);     #9
    found = gstruct.gl_pathv;                                        #10
    while(*found)                                                    #11
    {
        printf("%s\n",*found);                                       #12
        found++;                                                     #13
    }
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-11/)Remember, the wildcard input must be supplied by the user because the program doesn’t interpret wildcard input as a command-line argument. Here is a sample run:

```
Filename or wildcard: find*
Found 7 filename matches
finddupe01.c
finddupe02.c
finddupe03.c
finddupe04.c
finddupe05.c
findfile01.c
findfile02.c
```

[](/book/tiny-c-projects/chapter-11/)The program successfully found all files starting with `find`. The techniques used in the source code can now be incorporated into the *Find File* utility to use wildcards in its [](/book/tiny-c-projects/chapter-11/)[](/book/tiny-c-projects/chapter-11/)[](/book/tiny-c-projects/chapter-11/)search.

### [](/book/tiny-c-projects/chapter-11/)11.2.3 Using wildcards to find files

[](/book/tiny-c-projects/chapter-11/)Some [](/book/tiny-c-projects/chapter-11/)[](/book/tiny-c-projects/chapter-11/)[](/book/tiny-c-projects/chapter-11/)modifications are necessary for the Find File utility to take advantage of wildcards. To assist the *glob()* function[](/book/tiny-c-projects/chapter-11/), the matching filename must now be entered at a prompt, similar to the `glob02.c` program in the preceding section. Then the *glob()* function[](/book/tiny-c-projects/chapter-11/) must be integrated into the *find()* function[](/book/tiny-c-projects/chapter-11/) to help scour subdirectories for matching filenames.

[](/book/tiny-c-projects/chapter-11/)Modifications to the *main()* function can be found in the source code file, `findfile02.c`, available in the online repository. These updates reflect added statements from the `glob02.c` source code file, mostly to accept and confirm input regarding wildcards. The rest of the modifications are shown in the following listing, where the *glob()* function[](/book/tiny-c-projects/chapter-11/) is integrated into the *find()* function[](/book/tiny-c-projects/chapter-11/). In this version of the code, the string argument `match` can be a specific filename or a filename including wildcards.

##### Listing 11.5 The *find()* function from source code file findfile02.c

```
void find(char *dirpath,char *parentpath,char *match)
{
    DIR *dp;
    struct dirent *entry;
    struct stat fs;
    char subdirpath[PATH_MAX];
    int g;
    glob_t gstruct;
    char **found;
    dp = opendir(dirpath);
    if( dp==NULL )
    {
        fprintf(stderr,"Unable to read directory '%s'\n",
                dirpath
               );
        exit(1);
    }
 
    g = glob(match, GLOB_ERR, NULL, &gstruct);    #1
    if( g==0 )                                    #2
    {
        found = gstruct.gl_pathv;
        while(*found)
        {
            printf("%s/%s\n",dirpath,*found);
            found++;
            count++;
        }
    }
 
    while( (entry=readdir(dp)) != NULL )          #3
    {
        stat(entry->d_name,&fs);
        if( S_ISDIR(fs.st_mode) )                 #4
        {
            if( strncmp( entry->d_name,".",1)==0 )
                continue;
            if( chdir(entry->d_name)==-1 )
            {
                fprintf(stderr,"Unable to change to %s\n",
                        entry->d_name
                       );
                exit(1);
            }
 
            getcwd(subdirpath,BUFSIZ);
            find(subdirpath,dirpath,match);
        }
    }
 
    closedir(dp);
 
    if( chdir(parentpath)==-1 )
    {
        if( parentpath==NULL )
            return;
        fprintf(stderr,"Parent directory lost\n");
        exit(1);
    }
}
```

[](/book/tiny-c-projects/chapter-11/)In its final incarnation, the *Find File* utility (source code file `findfile02.c`) prompts for input, which can be a specific file or a wildcard. All files in the current directory and in all subdirectories are searched with the results reported:

```bash
$ ff
Filename or wildcard: *.c
Searching for '*.c'
/Users/Dan/code/0424a.c
/Users/Dan/code/0424b.c
...
/Users/Dan/Tiny C Projects/code/11_filefind/sto/unique04.c
/Users/Dan/Tiny C Projects/code/11_filefind/sto/unique05.c
/Users/Dan/Tiny C Projects/code/11_filefind/sto/unique06.c
Found 192 matches
```

[](/book/tiny-c-projects/chapter-11/)Here, the *Find File* utility located 192 C source code files in my home folder.

```bash
$ ff
Filename or wildcard: *deposit*
Searching for '*deposit*'
/Users/Dan/Documents/bank deposit.docx
Found 1 match
```

[](/book/tiny-c-projects/chapter-11/)In the sample run shown here, the *Find File* utility located my bank deposit document. Having the *glob()* function[](/book/tiny-c-projects/chapter-11/) in the program allows wildcards to be used effectively. Though the program can still locate specific files when the full name is input:

```bash
$ ff
Filename or wildcard: ch03.docx
Searching for 'ch03.docx'
/Users/Dan/Documents/Word/text/ch03.docx
Found 1 match
```

[](/book/tiny-c-projects/chapter-11/)As I wrote earlier, I use this utility often because it’s simple and it generates the results I want. What I don’t want is to keep working on the utility, which may eventually lead me to reinvent the *find* program. No, instead, the concept of finding a file can be taken further to locating [](/book/tiny-c-projects/chapter-11/)[](/book/tiny-c-projects/chapter-11/)[](/book/tiny-c-projects/chapter-11/)duplicate files.

## [](/book/tiny-c-projects/chapter-11/)11.3 The duplicate file finder

[](/book/tiny-c-projects/chapter-11/)One [](/book/tiny-c-projects/chapter-11/)[](/book/tiny-c-projects/chapter-11/)my favorite shareware utilities for MS-DOS is *finddupe*[](/book/tiny-c-projects/chapter-11/). I’ve found nothing like it for Windows (not that I’ve aggressively looked). A version of the utility is still available for the command shell in Windows. It finds duplicate files, not just by name but also by contents. *finddupe*[](/book/tiny-c-projects/chapter-11/) is a handy tool for cleaning up and organizing files on a mass storage device.

[](/book/tiny-c-projects/chapter-11/)I never bothered coding my own *finddupe* utility[](/book/tiny-c-projects/chapter-11/), mostly because the existing tool is spiffy. Even so, I often thought of the process: the program must not only scan all directories but also must record filenames. From the list of recorded filenames, each must be compared with others in the list to see whether the same name exists. I tremble at the thought of the added process of comparing file contents.

[](/book/tiny-c-projects/chapter-11/)Still, the topic intrigued me: How would you scan files in subdirectories and then check to see whether any duplicate names are found?

[](/book/tiny-c-projects/chapter-11/)The process of creating a *Find Dupe* utility borrows heavily from the subdirectory scanning tools presented in chapter 10 and used earlier in this chapter. But the rest of the code—recording and scanning the list of saved files—is new territory: a list of files must be created. The list must be scanned for duplicates and then the duplicates output, along with their pathnames.

### [](/book/tiny-c-projects/chapter-11/)11.3.1 Building a file list

[](/book/tiny-c-projects/chapter-11/)As [](/book/tiny-c-projects/chapter-11/)[](/book/tiny-c-projects/chapter-11/)with any programming projects, I made several attempts to successfully build a list of files found in subdirectories. It was obvious that I’d need some kind of structure to hold the file information: name, path, and so on. But do I create a dynamic array (allocated pointers) of structures, use a linked list, make the structure array external, or just give up and become a dairy farmer?

[](/book/tiny-c-projects/chapter-11/)To me, making any variable external is a last choice. Sometimes it’s the only choice, but never should it be a choice because it’s easy to do. As shown earlier in this chapter with the `count` variable[](/book/tiny-c-projects/chapter-11/), sometimes it’s necessary because the other ways to implement the variable are awkward. Especially with recursion, having an external variable untangles some knots that are otherwise at the Christmas-tree-light level.

[](/book/tiny-c-projects/chapter-11/)The two options remaining are to pass a dynamically allocated list or use a linked list. I wrote several iterations of the code where a dynamically allocated list of structures was passed to the recursive function. It failed, which is easy because pointers can get lost in recursion. Therefore, my only remaining option is to create a linked list.

[](/book/tiny-c-projects/chapter-11/)A linked list structure must have as a member a pointer to the next item, or *node*, in the list. This member becomes part of the structure that stores found filenames and their paths. Here is its definition:

```
struct finfo {
 int index;
 char name[BUFSIZ];
 char path[PATH_MAX];
 struct finfo *next;
};
```

[](/book/tiny-c-projects/chapter-11/)I originally named the structure `fileinfo`. I would have kept the name, but this book’s margins are only so wide and I don’t like wrapping source code. So, I settled on `finfo`[](/book/tiny-c-projects/chapter-11/). This structure contains four members:

-  [](/book/tiny-c-projects/chapter-11/)`index`, which keeps a count of the files found (avoiding an external variable)
-  [](/book/tiny-c-projects/chapter-11/)`name`, which contains the name of the found file
-  [](/book/tiny-c-projects/chapter-11/)`path`, which contains the full path to the file
-  [](/book/tiny-c-projects/chapter-11/)`next`, which references the next node in the linked list, or NULL for the end of the list

[](/book/tiny-c-projects/chapter-11/)This structure must be declared externally so that all functions in the code understand its definition.

[](/book/tiny-c-projects/chapter-11/)My first build of the program is simply to see whether the thing works: that the linked list is properly allocated, filled, and returned from the recursive function. In the next listing, you see the *main()* function. It allocates the first node in the linked list. This structure must be empty; it’s the recursive function *find[](/book/tiny-c-projects/chapter-11/)()* that builds the linked list. The *main()* function fetches the starting directory for a call to the recursive function. Upon completion, a *while* loop outputs the names of the files referenced by the linked list.

##### Listing 11.6 The *main()* function from finddupe01.c

```
int main()
{
    char startdir[PATH_MAX];
    struct finfo *first,*current;                  #1
 
    first = malloc( sizeof(struct finfo) * 1 );    #2
    if( first==NULL )                              #3
    {
        fprintf(stderr,"Unable to allocate memory\n");
        exit(1);
    }
 
    first->index = 0;                              #4
    strcpy(first->name,"");                        #4
    strcpy(first->path,"");                        #4
    first->next = NULL;                            #4
 
    getcwd(startdir,PATH_MAX);                     #5
    if( chdir(startdir)==-1 )
    {
        fprintf(stderr,"Unable to access directory %s\n",
                startdir
               );
            exit(1);
    }
 
    find(startdir,NULL,first);                     #6
 
    current = first;                               #7
    while( current )                               #8
    {
        if( current->index > 0 )                   #9
            printf("%d:%s/%s\n",                   #10
                    current->index,
                    current->path,
                    current->name
                   );
        current = current->next;                   #11
    }
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-11/)The *while* loop skips the first node in the linked list, the empty item. I could avoid the `if(` `current->index` `>` `0)` text (shown earlier) by replacing the initialization statement for `current` with:

```
current = first->next;
```

[](/book/tiny-c-projects/chapter-11/)I only just thought of this change now, so you won’t find it in the source code files. Either way, the first node in the linked list is skipped over.

[](/book/tiny-c-projects/chapter-11/)The *find()* function[](/book/tiny-c-projects/chapter-11/) for my *Find Dupe* code is based upon the *find()* function[](/book/tiny-c-projects/chapter-11/) in the *Find File* utility presented earlier in this chapter. The third argument of the *find()* function[](/book/tiny-c-projects/chapter-11/) is replaced by a pointer to the current node in the linked list. The function’s job is to create new nodes, filling their structures as it finds files in the current directory.

[](/book/tiny-c-projects/chapter-11/)The next listing shows the *find()* function[](/book/tiny-c-projects/chapter-11/) for the *Find Dupe* utility, which is called from the *main()* function shown in listing 11.6. This function allocates storage for a new node in the list upon finding a file in the current directory. This change is the only addition to the function.

##### Listing 11.7 The *find()* function from finddupe01.c

```
void find( char *dirpath, char *parentpath, struct finfo *f)
{
    DIR *dp;
    struct dirent *entry;
    struct stat fs;
    char subdirpath[PATH_MAX];
    int i;
 
    dp = opendir(dirpath);                                   #1
    if( dp==NULL )
    {
        fprintf(stderr,"Unable to read directory '%s'\n",
                dirpath
               );
        exit(1);
        /* will free memory as it exits */
    }
 
    while( (entry=readdir(dp)) != NULL )
    {
        stat(entry->d_name,&fs);
        if( S_ISDIR(fs.st_mode) )                            #2
        {
            if( strncmp( entry->d_name,".",1)==0 )
                continue;
            if( chdir(entry->d_name)==-1 )
            {
                fprintf(stderr,"Unable to change to %s\n",
                        entry->d_name
                       );
                exit(1);
            }
            getcwd(subdirpath,BUFSIZ);
            find(subdirpath,dirpath,f);
        }
        else                                                 #3
        {
            f->next = malloc( sizeof(struct finfo) * 1);     #4
            if( f->next == NULL )
            {
                fprintf(stderr,
                        "Unable to allocate new structure\n");
                exit(1);
            }
 
            i = f->index;                                    #5
            f = f->next;                                     #6
            f->index = i+1;                                  #7
            strcpy(f->name,entry->d_name);                   #8
            strcpy(f->path,dirpath);                         #9
            f->next = NULL;                                  #10
        }
    }
 
    closedir(dp);
 
    if( chdir(parentpath)==-1 )
    {
        if( parentpath==NULL )
            return;
        fprintf(stderr,"Parent directory lost\n");
        exit(1);
    }
}
```

[](/book/tiny-c-projects/chapter-11/)The *find()* function[](/book/tiny-c-projects/chapter-11/) makes a simple decision based on whether a directory entry is a subdirectory or a file. When a subdirectory is found, the function is recursively called. Otherwise, a new node in the linked list is allocated and the file entry information is recorded.

[](/book/tiny-c-projects/chapter-11/)The full source code for `finddupe01.c` can be found in the online repository. Here is output from sample run in my working directory:

```
1:/Users/Dan/code/11_filefind/.finddupe01.c.swp
2:/Users/Dan/code/11_filefind/a.out
3:/Users/Dan/code/11_filefind/finddupe01.c
4:/Users/Dan/code/11_filefind/finddupe02.c
5:/Users/Dan/code/11_filefind/finddupe03.c
6:/Users/Dan/code/11_filefind/finddupe04.c
7:/Users/Dan/code/11_filefind/finddupe05.c
8:/Users/Dan/code/11_filefind/findfile01.c
9:/Users/Dan/code/11_filefind/findfile02.c
10:/Users/Dan/code/11_filefind/glob01.c
11:/Users/Dan/code/11_filefind/glob02.c
12:/Users/Dan/code/11_filefind/sto/findword01.c
13:/Users/Dan/code/11_filefind/sto/findword02.c
```

[](/book/tiny-c-projects/chapter-11/)The output was able to record files from the current directory as well as the `sto` subdirectory. However, when I changed to the parent directory (`code`) and ran the program again, the output didn’t change. It should: my `code` directory has over 100 files in various subdirectories. So why was the output unchanged?

[](/book/tiny-c-projects/chapter-11/)I puzzled over the bug with the assistance of my cat, trying to discover the solution. After a few purrs, it occurred to me: the problem is the recursive function, which should have been my first clue.

[](/book/tiny-c-projects/chapter-11/)When the *find()* function[](/book/tiny-c-projects/chapter-11/) returns, or “unwinds,” the previous value of pointer `f` is used—not the newly allocated value in the recursive call. Each time the function changes to the parent directory, the structures created in the linked list are lost because pointer `f` is reset to the original value passed to the function. Ugh.

[](/book/tiny-c-projects/chapter-11/)Fortunately, the solution is simple: return pointer `f`.

[](/book/tiny-c-projects/chapter-11/)Updating the code requires only three changes and one addition. First, the *find()* function’s data type must be changed from void to `struct` `finfo*`:

```
struct finfo *find( char *dirpath, char *parentpath, struct finfo *f)
```

[](/book/tiny-c-projects/chapter-11/)Second, the recursive call must capture the function’s return value:

```
f = find(subdirpath,dirpath,f);
```

[](/book/tiny-c-projects/chapter-11/)Effectively, this change updates pointer `f` to reflect its new value after the recursive call.

[](/book/tiny-c-projects/chapter-11/)Third, the *return* statement in the error check for the *chdir()* function[](/book/tiny-c-projects/chapter-11/) must specify the value of variable `f`:

```
return(f);
```

[](/book/tiny-c-projects/chapter-11/)And finally, the *find()* function[](/book/tiny-c-projects/chapter-11/) must have a statement at the end to return the value of pointer `f`:

```
return(f);
```

[](/book/tiny-c-projects/chapter-11/)These updates are found in the source code file `finddupe02.c` in the online repository.

[](/book/tiny-c-projects/chapter-11/)Upon building the code, the program accurately scans subdirectories—and retains the linked list when it changes back to the parent directory. The output is complete and accurate: a record is made via a linked list of all files found in the current directory as well as its [](/book/tiny-c-projects/chapter-11/)[](/book/tiny-c-projects/chapter-11/)subdirectories.

### [](/book/tiny-c-projects/chapter-11/)11.3.2 Locating the duplicates

[](/book/tiny-c-projects/chapter-11/)The [](/book/tiny-c-projects/chapter-11/)[](/book/tiny-c-projects/chapter-11/)purpose of creating a linked list in the *Find Dupe* program is to find duplicates. At some point, the list must be scanned and a determination made as to which filenames are repeated and in which directories the duplicates are found.

[](/book/tiny-c-projects/chapter-11/)I thought of several ways to accomplish this task. Most of them involved creating a second list of filenames. But I didn’t want to build list after list. Instead, I added a new member to the `finfo` structure[](/book/tiny-c-projects/chapter-11/), `repeat`, as shown in this updated structure definition:

```
struct finfo {
  int index;
  int repeat;         #1
  char name[BUFSIZ];
  char path[PATH_MAX];
  struct finfo *next;
};
```

[](/book/tiny-c-projects/chapter-11/)The `repeat` member[](/book/tiny-c-projects/chapter-11/) tracks how many times a name repeats. Its value is initialized to one in the *find()* function[](/book/tiny-c-projects/chapter-11/) as each node is created. After all, every filename found exists at least once.

[](/book/tiny-c-projects/chapter-11/)To track repeated filenames, the `repeat` member[](/book/tiny-c-projects/chapter-11/) is incremented as the list is scanned after its creation. In the *main()* function, a nested loop works like a bubble sort. It compares each node in the list sequentially with the rest of the nodes.

[](/book/tiny-c-projects/chapter-11/)To perform the second scan, I need another *struct* `finfo` variable[](/book/tiny-c-projects/chapter-11/) declared in the *main()* function. This variable, `*scan`, is used in addition to `*first` and `*current` to scan the linked list:

```
struct finfo *first,*current,*scan;
```

[](/book/tiny-c-projects/chapter-11/)The nested *while* loop is added just before the *while* loop that outputs the list. This nested loop uses the `*current` pointer to process the entire linked list. The `*scan` pointer is used in an inner *while* loop to compare the `current->name` member with subsequent `name` members[](/book/tiny-c-projects/chapter-11/). When a match is found, the `current->repeat` structure member for the file with the repeated name is incremented, as shown here.

##### Listing 11.8 The nested *while* loops added to the *main()* function in finddupe03.c

```
current = first;
while( current )                                          #1
{
    if( current->index > 0 )                              #2
    {
        scan = current->next;                             #3
        while( scan )                                     #4
        {
            if( strcmp(current->name,scan->name)==0 )     #5
            {
                current->repeat++;                        #6
            }
            scan = scan->next;                            #7
        }
    }
    current = current->next;                              #8
}
```

[](/book/tiny-c-projects/chapter-11/)These nested loops update the `repeat` member[](/book/tiny-c-projects/chapter-11/) of structures containing identical filenames. They’re followed by the existing *while* loop that outputs the list. The *printf()* statement[](/book/tiny-c-projects/chapter-11/) in that second loop is updated to output the `repeat` value:

```
printf("%d:%s/%s (%d)\n",
       current->index,
       current->path,
       current->name,
       current->repeat
     );
```

[](/book/tiny-c-projects/chapter-11/)All these changes are found in the `finddupe03.c` source code file, available in the online repository. The output doesn’t yet show duplicate files. This incremental improvement to the *Find Dupe* series of source code files merely outputs the same, full file list, but with the number of repeats shown at the end of the file pathname string:

```
163:/Users/Dan/code/sto/secret01.c (1)
```

[](/book/tiny-c-projects/chapter-11/)The next update to the *Find Dupe* program is found in source code file `finddupe04.c`. Obtain this source code file from the online repository, and display it in an editor. Follow along with the text to review the two improvements I’ll make.

[](/book/tiny-c-projects/chapter-11/)First, a new *int* variable `found`[](/book/tiny-c-projects/chapter-11/) is declared in the *main()* function, up top where I prefer to set my variable declarations:

```
int found = 0;
```

[](/book/tiny-c-projects/chapter-11/)When a repeating filename is discovered in the nested *while* loops, the value of `found` is reset to 1:

```
if( strcmp(current->name,scan->name)==0 )
{
   current->repeat++;
   found = 1;
}
```

[](/book/tiny-c-projects/chapter-11/)The value of `found` need not accumulate; it’s effectively a Boolean variable. When it stays at 0, no duplicate filenames are found and the following statements are executed:

```
if( !found )
{
   puts("No duplicates found");
   return(1);
}
```

[](/book/tiny-c-projects/chapter-11/)The “No duplicates found” message is output, then the program exits with a return value of 1.

[](/book/tiny-c-projects/chapter-11/)When the value of `found` has been reset to 1, duplicate filenames are detected. The second *while* loop in the *main()* function proceeds to process the list. This loop is updated to catch and output the repeats, as illustrated in the following listing. Again, the `*scan` variable is used in a nested *while* loop, but this time to output duplicate filenames and their pathnames.

##### Listing 11.9 A second nested *while* loop in the *main()* function in finddupe04.c

```
current = first;                                     #1
while( current )
{
    if( current->index > 0 )
    {
        if( current->repeat > 1 )                    #2
        {
            printf("%d duplicates found of %s:\n",   #3
                    current->repeat,
                    current->name
                  );
            printf(" %s/%s\n",                       #4
                    current->path,
                    current->name
                  );
            scan = current->next;                    #5
            while( scan )
            {
                if( strcmp(scan->name,current->name)==0 )
                {
                    printf(" %s/%s\n",
                            scan->path,
                            scan->name
                          );
                }
                scan = scan->next;
            }
        }
    }
    current = current->next;
}
```

[](/book/tiny-c-projects/chapter-11/)This update to the code in `finddupe04.c` outputs a shorter list, showing only those repeated filenames, plus listing all the duplicate names and their paths.

[](/book/tiny-c-projects/chapter-11/)For example, in my programming tree, I see five duplicates of the `a.out` file in the program’s output:

```
5 duplicates found of a.out:
/Users/Dan/code/a.out
/Users/Dan/code/communications/a.out
/Users/Dan/code/communications/networking/a.out
/Users/Dan/Tiny C Projects/code/08_unicode/a.out
/Users/Dan/Tiny C Projects/code/11_filefind/a.out
```

[](/book/tiny-c-projects/chapter-11/)The problem is that the duplicates also show duplicates. So, the output continues for the same filename as follows for multiple occurrences of the `a.out` file:

```
4 duplicates found of a.out:
/Users/Dan/code/communications/a.out
/Users/Dan/code/communications/networking/a.out
/Users/Dan/Tiny C Projects/code/08_unicode/a.out
/Users/Dan/Tiny C Projects/code/11_filefind/a.out
3 duplicates found of a.out:
/Users/Dan/code/communications/networking/a.out
/Users/Dan/Tiny C Projects/code/08_unicode/a.out
/Users/Dan/Tiny C Projects/code/11_filefind/a.out
```

[](/book/tiny-c-projects/chapter-11/)This output is inefficient because it repeatedly lists the duplicates. The reason is that the `repeat` member[](/book/tiny-c-projects/chapter-11/) for repeated filename structures in the linked list is greater than 1. Because this value doesn’t change when the first repeated filename is output, the code catches all the duplicates.

[](/book/tiny-c-projects/chapter-11/)This problem frustrated me because I didn’t want to create yet another structure member nor did I want to return to rehab. My goal is to avoid exceptions in an already complex, nested *while* loop.

[](/book/tiny-c-projects/chapter-11/)I stewed over this problem for a while, but eventually inspiration hit me, and a one-line solution presented itself:

```
scan->repeat = 0;
```

[](/book/tiny-c-projects/chapter-11/)This single statement is added to the second nested *while* loop, shown in listing 11.9. It appears after the matching filename is detected:

```
while( scan )
{
   if( strcmp(scan->name,current->name)==0 )
   {
       printf(" %s/%s\n",
               scan->path,
               scan->name
              );
       scan->repeat = 0;
   }
   scan = scan->next;
}
```

[](/book/tiny-c-projects/chapter-11/)In the nested *while* loop, after the repeated filename is output, its `repeat` value is reset to 0. This change prevents a repeated filename from appearing later in the output. This change is available in the source code file `finddupe05.c`.

[](/book/tiny-c-projects/chapter-11/) The *Find Dupe* program is complete: it scans the current directory structure and lists matching filenames, showing the full pathname for all duplicates.

[](/book/tiny-c-projects/chapter-11/)Like all code, the *Find Dupe* series can be improved upon. For example, the file’s size could be added to the `finfo` structure[](/book/tiny-c-projects/chapter-11/). Filename matches and file size matches could be output. And you could go whole hog and try to match file contents as well. The basic framework for whatever system you need is provided in the existing code. All that’s left is your desire to improve upon it and the time necessary to anticipate all those unexpected things that are bound to happen [](/book/tiny-c-projects/chapter-11/)[](/book/tiny-c-projects/chapter-11/)along [](/book/tiny-c-projects/chapter-11/)[](/book/tiny-c-projects/chapter-11/)the [](/book/tiny-c-projects/chapter-11/)[](/book/tiny-c-projects/chapter-11/)way.
