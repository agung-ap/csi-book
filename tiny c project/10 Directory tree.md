# [](/book/tiny-c-projects/chapter-10/)10 Directory tree

[](/book/tiny-c-projects/chapter-10/)Of all [](/book/tiny-c-projects/chapter-10/)the programming tasks, I’m embarrassed to admit that I enjoy coding file utilities the most. The casual user is unaware of the mountain of information about files provided by the operating system. It’s highly detailed low-hanging fruit, eager for plucking. Plus, exploring files and directories opens your understanding of how computer storage works. Exploring this field may inspire you to write your own interesting file utilities. If it doesn’t, you can keep reading this chapter—your introduction to filesystems and storage.

[](/book/tiny-c-projects/chapter-10/)The goal here is to create a directory tree program. The output shows subdirectories as they sit in the hierarchical filesystem. In addition to being exposed to the word *hierarchical* (which I can amazingly both spell and type), in this chapter you learn how to:

-  [](/book/tiny-c-projects/chapter-10/)Examine information about a file
-  [](/book/tiny-c-projects/chapter-10/)Decipher file modes and permissions
-  [](/book/tiny-c-projects/chapter-10/)Read a directory entry
-  [](/book/tiny-c-projects/chapter-10/)Use recursion to explore the directory structure
-  [](/book/tiny-c-projects/chapter-10/)Extract a directory name from a full pathname
-  [](/book/tiny-c-projects/chapter-10/)Output a directory tree
-  [](/book/tiny-c-projects/chapter-10/)Avoid confusing the word *hierarchical* with *hieroglyphical*

[](/book/tiny-c-projects/chapter-10/)Before diving into the details, be aware that GUI nomenclature prefers the term *folder* over *directory*. As a C programmer, you must use the term *directory*, not *folder*. All C functions that deal with files and directories use *directory* or contain the abbreviation “dir.” Don’t wimp out and use the term *folder*.

[](/book/tiny-c-projects/chapter-10/)The point of the directory tree utility is to output a map of the directory structure. The map details which directories are parents and children of each other. Unlike years ago, today’s directory structures are busy with lots of organization. Users are more attentive when it comes to saving files. Programs are geared toward this type of organization and provide hints to help users employ the subdirectory concept.

[](/book/tiny-c-projects/chapter-10/)Even if a directory map seems trivial, the process of exploring the directory tree lends itself well to other handy disk utilities. For example, chapter 11 covers a file-finding utility, which relies heavily upon the information presented in this chapter to make the utility truly useful.

[](/book/tiny-c-projects/chapter-10/)At [](/book/tiny-c-projects/chapter-10/)the core of all media storage lies the filesystem. The *filesystem* describes the way data is stored on media, how files are accessed, and various nerdy tidbits about the files themselves.

[](/book/tiny-c-projects/chapter-10/)The only time most users deal with the filesystem concept is when formatting media. Choosing a filesystem is part of the formatting process, because it determines how the media is formatted and which protocols to follow. This step is necessary for compatibility: not every filesystem is compatible with every computer operating system. Therefore, the user is allowed to select a filesystem for the media’s format to allow for sharing between operating systems, such as Linux and PC or Macintosh.

[](/book/tiny-c-projects/chapter-10/)The filesystem’s duty is to organize storage. It takes a file’s data and writes it to one or more locations on the media. This information is recorded along with other file details, such as the file’s name, size, dates (created, modified, accessed), permissions, and so on.

[](/book/tiny-c-projects/chapter-10/)Some of the file details are readily obtainable through existing utilities or from various C library functions. But most of the mechanics of the filesystem are geared toward saving, retrieving, and updating the file’s data lurking on the media. All this action takes place automatically under the supervision of the operating system.

[](/book/tiny-c-projects/chapter-10/)The good news for most coders is that it isn’t necessary to know the minutiae of how files are stored on media. Even if you go full nerd and understand the subtle differences between the various filesystems and can tout the benefits of the High Performance File System (HPFS[](/book/tiny-c-projects/chapter-10/)[](/book/tiny-c-projects/chapter-10/)) at nerd cocktail parties, the level of media access required to manipulate a filesystem requires privileges above where typical C programs operate. Functions are available for exploring a file’s details. These functions are introduced in the next section.

[](/book/tiny-c-projects/chapter-10/)Aside from knowing the names and perhaps a few details on how filesystems work, if you’re curious, you can use common tools on your computer to see which filesystems are in use. In a Linux terminal window, use the **man fs** command[](/book/tiny-c-projects/chapter-10/) to review details on how Linux uses a filesystem and the different filesystems available. The `/proc/filesystems` directory lists available filesystems for your Linux installation.

[](/book/tiny-c-projects/chapter-10/)Windows keeps its filesystem information tucked away in the Disk Management console. To access this window, follow these steps:

1.  [](/book/tiny-c-projects/chapter-10/)Tap the Windows key on the keyboard to open the Start menu.
1.  [](/book/tiny-c-projects/chapter-10/)Type **Disk Management**.
1.  [](/book/tiny-c-projects/chapter-10/)From the list of search results, choose Create and Format Hard Disk Partitions.

[](/book/tiny-c-projects/chapter-10/)Figure 10.1 shows the Disk Management console from one of my Windows computers. Available media is presented in the table, with the File System column listing the filesystems used; only NTFS is shown in the figure.

![Figure 10.1 The Disk Management console reveals the filesystem used to format media available to the PC.](https://drek4537l1klr.cloudfront.net/gookin/Figures/10-01.png)

[](/book/tiny-c-projects/chapter-10/)On the Macintosh, you can use the Disk Utility to browse available media to learn which filesystem is in use. This app is found in the Utilities directory: in the Finder, click Go > Utilities to view the directory and access the Disk Utility app.

[](/book/tiny-c-projects/chapter-10/)If it were easy or necessary to program a filesystem, I’d explore the topic further. For now, understand that the filesystem is the host for data stored on media in a computer. A program such as a directory tree uses the filesystem, but in C, such a utility doesn’t need to know details about the filesystem type to do its [](/book/tiny-c-projects/chapter-10/)job.

## [](/book/tiny-c-projects/chapter-10/)10.2 File and directory details

[](/book/tiny-c-projects/chapter-10/)To [](/book/tiny-c-projects/chapter-10/)gather directory details at the command prompt, use the ls command[](/book/tiny-c-projects/chapter-10/). It’s available in all shells, dating back to the first, prehistoric version of Unix used by the ancient Greeks, when the command was known as λσ. The output is a list of filenames in the current directory:

```bash
$ ls
changecwd.c  dirtree04.c   fileinfo03.c  readdir01.c  subdir01.c  subdir05.c
dirtree01.c  extractor.c   fileinfo04.c  readdir02.c  subdir02.c  subdir06.c
dirtree02.c  fileinfo01.c  fileinfo05.c  readdir03.c  subdir03.c
dirtree03.c  fileinfo02.c  getcwd.c  readdir04.c  subdir04.c
```

[](/book/tiny-c-projects/chapter-10/)For more detail, the `-l` (long) switch is specified:

```bash
$ ls -l
total 68
-rwxrwxrwx 1 dang dang  292 Oct 31 16:26 changecwd.c
-rwxrwxrwx 1 dang dang 1561 Nov  4 21:14 dirtree01.c
-rwxrwxrwx 1 dang dang 1633 Nov  5 10:39 dirtree02.c
...
```

[](/book/tiny-c-projects/chapter-10/)This output shows details about each file, its permissions, ownership, size, date, and other trivia you can use to intimidate your computer illiterate pals. It’s not secret stuff; the details output by the `ls -l` command are stored in the directory like a database. In fact, directories on storage media are really databases. Their records aren’t specifically files, but rather inodes.

[](/book/tiny-c-projects/chapter-10/)An *inode*[](/book/tiny-c-projects/chapter-10/) is not an Apple product. No, it’s a collection of data that describes a file. Although your C programs can’t readily access low-level filesystem details, you can easily examine a file’s inode data. The inode’s name is the same as the file’s name. But beyond the name, the inode contains oodles of details about the file.

### [](/book/tiny-c-projects/chapter-10/)10.2.1 Gathering file info

[](/book/tiny-c-projects/chapter-10/)To [](/book/tiny-c-projects/chapter-10/)obtain details about a file, as well as to read a directory, you need to access inode data. The command-line program that does so is called *stat*. Here’s some sample output on the *stat* program file `fileinfo`:

```
File: fileinfo
 Size: 8464        Blocks: 24         IO Block: 4096   regular file
Device: eh/14d  Inode: 11258999068563657  Links: 1
Access: (0777/-rwxrwxrwx)  Uid: ( 1000/    dang)   Gid: ( 1000/    dang)
Access: 2021-10-23 21:11:17.457919300 -0700
Modify: 2021-10-23 21:11:00.071527400 -0700
Change: 2021-10-23 21:11:00.071527400 -0700
```

[](/book/tiny-c-projects/chapter-10/)These details are stored in the directory database. In fact, part of the output shows the file’s inode number: 11258999068563657. Of course, the name `fileinfo` is far easier to use as a reference.

[](/book/tiny-c-projects/chapter-10/)To read this same information in your C programs, you use the *stat()* function[](/book/tiny-c-projects/chapter-10/). It’s prototyped in the `sys/stat.h` header file. Here is the *man* page format[](/book/tiny-c-projects/chapter-10/):

```
int stat(const char *pathname, struct stat *statbuf);
```

[](/book/tiny-c-projects/chapter-10/)The `pathname` is a filename or a full pathname. Argument `statbuf` is the address of a `stat` structure. Here’s a typical stat() function statement[](/book/tiny-c-projects/chapter-10/), with the `filename` char pointer[](/book/tiny-c-projects/chapter-10/) containing the filename, `fs` as a `stat` structure, and int variable `r` capturing the return value:

```
r = stat(filename,&fs);
```

[](/book/tiny-c-projects/chapter-10/)Upon failure, value -1 is returned. Otherwise, 0 is returned and the `stat` structure `fs` is joyously filled with details about the file—inode data. Table 10.1 lists the common members of the `stat` structure, though different filesystems and operating systems add or change specific members.[](/book/tiny-c-projects/chapter-10/)

##### [](/book/tiny-c-projects/chapter-10/)Table 10.1 Members in the *stat()* function’s `statbuf` structure[(view table figure)](https://drek4537l1klr.cloudfront.net/gookin/HighResolutionFigures/table_10-1.png)

| [](/book/tiny-c-projects/chapter-10/)Member | [](/book/tiny-c-projects/chapter-10/)Data type (placeholder) | [](/book/tiny-c-projects/chapter-10/)Detail |
| --- | --- | --- |
| [](/book/tiny-c-projects/chapter-10/)st_dev | [](/book/tiny-c-projects/chapter-10/)dev_t (%lu) | [](/book/tiny-c-projects/chapter-10/)ID of the media (device) containing the file |
| [](/book/tiny-c-projects/chapter-10/)st_ino | [](/book/tiny-c-projects/chapter-10/)ino_t (%lu) | [](/book/tiny-c-projects/chapter-10/)Inode number |
| [](/book/tiny-c-projects/chapter-10/)st_mode | [](/book/tiny-c-projects/chapter-10/)mode_t (%u) | [](/book/tiny-c-projects/chapter-10/)File type, mode, permissions |
| [](/book/tiny-c-projects/chapter-10/)st_nlink | [](/book/tiny-c-projects/chapter-10/)nlink_t (%lu) | [](/book/tiny-c-projects/chapter-10/)Number of links |
| [](/book/tiny-c-projects/chapter-10/)st_uid | [](/book/tiny-c-projects/chapter-10/)uid_t (%u) | [](/book/tiny-c-projects/chapter-10/)Owner’s user ID |
| [](/book/tiny-c-projects/chapter-10/)st_gid | [](/book/tiny-c-projects/chapter-10/)gid_t (%u) | [](/book/tiny-c-projects/chapter-10/)Group’s user ID |
| [](/book/tiny-c-projects/chapter-10/)st_rdev | [](/book/tiny-c-projects/chapter-10/)dev_t (%lu) | [](/book/tiny-c-projects/chapter-10/)Special file type’s device ID |
| [](/book/tiny-c-projects/chapter-10/)st_size | [](/book/tiny-c-projects/chapter-10/)off_t (%lu) | [](/book/tiny-c-projects/chapter-10/)File size in bytes |
| [](/book/tiny-c-projects/chapter-10/)st_blksize | [](/book/tiny-c-projects/chapter-10/)blksize_t (%lu) | [](/book/tiny-c-projects/chapter-10/)Filesystem’s block size |
| [](/book/tiny-c-projects/chapter-10/)st_blocks | [](/book/tiny-c-projects/chapter-10/)blkcnt_t (%lu) | [](/book/tiny-c-projects/chapter-10/)File blocks allocated (512-byte blocks) |
| [](/book/tiny-c-projects/chapter-10/)st_atime | [](/book/tiny-c-projects/chapter-10/)struct timespec | [](/book/tiny-c-projects/chapter-10/)Time file last accessed |
| [](/book/tiny-c-projects/chapter-10/)st_mtime | [](/book/tiny-c-projects/chapter-10/)struct timespec | [](/book/tiny-c-projects/chapter-10/)Time file last modified |
| [](/book/tiny-c-projects/chapter-10/)st_ctime | [](/book/tiny-c-projects/chapter-10/)struct timespec | [](/book/tiny-c-projects/chapter-10/)Time file status last changed |

[](/book/tiny-c-projects/chapter-10/)Most of the `stat` structure members are integers; I’ve specified the *printf()* placeholder type in table 10.1. They’re all *unsigned*, though some values are *unsigned long*. Watch out for the *long unsigned* values because the compiler bemoans using the incorrect placeholder to represent these values.

[](/book/tiny-c-projects/chapter-10/)The `timespec` structure[](/book/tiny-c-projects/chapter-10/) is accessed as a *time_t* pointer[](/book/tiny-c-projects/chapter-10/). It contains two members: `tv_sec` and `tv_nsec` for seconds and nanoseconds, respectively. An example of using the *ctime()* function[](/book/tiny-c-projects/chapter-10/) to access this structure is shown later.

[](/book/tiny-c-projects/chapter-10/)The following listing shows a sample program, `fileinfo01.c`, that outputs file (or inode) details. Each of the `stat` structure members is accessed for a file supplied as a command-line argument. Most of the code consists of error-checking—for example, to confirm that a filename argument is supplied and to check on the return status of the *stat()* function[](/book/tiny-c-projects/chapter-10/).

##### Listing 10.1 Source code for fileinfo01.c

```
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <time.h>
 
int main(int argc, char *argv[])                         #1
{
    char *filename;
    struct stat fs;
    int r;
 
    if( argc<2 )                                         #2
    {
        fprintf(stderr,"Specify a filename\n");
        exit(1);
    }
 
    filename = argv[1];                                  #3
    printf("Info for file '%s'\n",filename);
    r = stat(filename,&fs);                              #4
    if( r==-1 )                                          #5
    {
        fprintf(stderr,"Error reading '%s'\n",filename);
        exit(1);
    }
 
    printf("Media ID: %lu\n",fs.st_dev);                 #6
    printf("Inode #%lu\n",fs.st_ino);                    #6
    printf("Type and mode: %u\n",fs.st_mode);            #6
    printf("Hard links = %lu\n",fs.st_nlink);            #6
    printf("Owner ID: %u\n",fs.st_uid);                  #6
    printf("Group ID: %u\n",fs.st_gid);                  #6
    printf("Device ID: %lu\n",fs.st_rdev);               #6
    printf("File size %lu bytes\n",fs.st_size);          #6
    printf("Block size = %lu\n",fs.st_blksize);          #6
    printf("Allocated blocks = %lu\n",fs.st_blocks);     #6
    printf("Access: %s",ctime(&fs.st_atime));            #7
    printf("Modification: %s",ctime(&fs.st_mtime));      #7
    printf("Changed: %s",ctime(&fs.st_ctime));           #7
    return(0);
}
```

[](/book/tiny-c-projects/chapter-10/)The information output by the `fileinfo01.c` program mirrors what the command-line stat utility coughs up. Here’s a sample run on the same file, `fileinfo`, this code’s program:

```
Info for file 'fileinfo'
Media ID: 14
Inode #7318349394555950
Type and mode: 33279
Hard links = 1
Owner ID: 1000
Group ID: 1000
Device ID: 0
File size 8464 bytes
Block size = 4096
Allocated blocks = 24
Access: Tue Oct 26 15:55:10 2021
Modification: Tue Oct 26 15:55:10 2021
Changed: Tue Oct 26 15:55:10 2021
```

[](/book/tiny-c-projects/chapter-10/)The details are the same as for the *stat* command’s output shown earlier in this section. The *stat* command[](/book/tiny-c-projects/chapter-10/) does look up the Device ID, Owner ID, and Group ID details, which your code could do as well. But one curious item is structure member `st_mode`, the type and mode value. The value shown in the output above is 33279. This integer value contains a lot of details—bit fields—which you see interpreted in the *stat* command’s output. Your code can also examine this value to determine the file type and its [](/book/tiny-c-projects/chapter-10/)permissions.

### [](/book/tiny-c-projects/chapter-10/)10.2.2 Exploring file type and permissions

[](/book/tiny-c-projects/chapter-10/)Examining [](/book/tiny-c-projects/chapter-10/)a file’s (or inode’s) `st_mode` value is how you determine whether a file is a regular old file, a directory, or some other special type of file. Remember that in the Linux environment, everything is a file. Using the *stat()* function[](/book/tiny-c-projects/chapter-10/) is how your code can determine which type of file the inode represents.

[](/book/tiny-c-projects/chapter-10/)The bit fields in the `st_mode` member[](/book/tiny-c-projects/chapter-10/) of the `stat` structure also describe the file’s permissions. Though you could code a series of complex bitwise logical operations to ferret out the specific details contained in the `st_mode` value’s bits, I recommend that you use instead the handy macros available in the `sys/stat.h` header file.

[](/book/tiny-c-projects/chapter-10/)For example, the `S_ISREG()` macro[](/book/tiny-c-projects/chapter-10/) returns TRUE for regular files. To update the `fileinfo01.c` code to test for regular files, add the following statements:

```
printf("Type and mode: %X\n",fs.st_mode);
if( S_ISREG(fs.st_mode) )
   printf("%s is a regular file\n",filename);
else
   printf("%s is not a regular file\n",filename);
```

[](/book/tiny-c-projects/chapter-10/)If the `S_ISREG()` test on the `fs.st_mode` variable returns TRUE, the *printf()* statement[](/book/tiny-c-projects/chapter-10/) belonging to the *if* statement outputs text confirming that the file is regular. The *else* condition[](/book/tiny-c-projects/chapter-10/) handles other types of files, such as directories.

[](/book/tiny-c-projects/chapter-10/) In my update to the code, `fieinfo02.c` (available in the online archive), I removed all the *printf()* statements from the original code. The five statements shown earlier replace the original `printf()` statements[](/book/tiny-c-projects/chapter-10/), because the focus of this update is to determine file type. Here’s sample output on the `fileinfo02.c` source code file itself:

```
Info for file 'fileinfo02.c'
Type and mode: 81FF
Fileinfo02.c is a regular file
```

[](/book/tiny-c-projects/chapter-10/)If I instead specify the single dot (`.`), representing the current directory, I see this output:

```
Info for file '.'
Type and mode: 41FF
. is a directory
```

[](/book/tiny-c-projects/chapter-10/)In the output above, the `st_mode` value changes as well as the return value from the `S_ISREG()` macro[](/book/tiny-c-projects/chapter-10/); a directory isn’t a regular file. In fact, you can test for directories specifically by using the `S_ISDIR()` macro[](/book/tiny-c-projects/chapter-10/):

```
printf("Type and mode: %X\n",fs.st_mode);
if( S_ISREG(fs.st_mode) )
   printf("%s is a regular file\n",filename);
else if( S_ISDIR(fs.st_mode) )
   printf("%s is a directory\n",filename);
else
  printf("%s is some other type of file\n",filename);
```

[](/book/tiny-c-projects/chapter-10/)I’ve made these modifications and additions to the code in `fileinfo02.c`, with the improvements saved in `fileinfo03.c`, available in this book’s online repository.

[](/book/tiny-c-projects/chapter-10/)Further modifications to the code are possible by using the full slate of file mode macros, listed in table 10.2. These are the common macros, though your C compiler and operating system may offer more. Use these macros to identify files by their type.

##### [](/book/tiny-c-projects/chapter-10/)Table 10.2 Macros defined in `sys/stat.h` to help determine file type[(view table figure)](https://drek4537l1klr.cloudfront.net/gookin/HighResolutionFigures/table_10-2.png)

| [](/book/tiny-c-projects/chapter-10/)Macro | [](/book/tiny-c-projects/chapter-10/)True for this type of file |
| --- | --- |
| [](/book/tiny-c-projects/chapter-10/)S_ISBLK()[](/book/tiny-c-projects/chapter-10/) | [](/book/tiny-c-projects/chapter-10/)Block special, such as mass storage in the /dev directory |
| [](/book/tiny-c-projects/chapter-10/)S_ISCHR()[](/book/tiny-c-projects/chapter-10/) | [](/book/tiny-c-projects/chapter-10/)Character special, such as a pipe or the /dev/null device |
| [](/book/tiny-c-projects/chapter-10/)S_ISDIR()[](/book/tiny-c-projects/chapter-10/) | [](/book/tiny-c-projects/chapter-10/)Directories |
| [](/book/tiny-c-projects/chapter-10/)S_ISFIFO()[](/book/tiny-c-projects/chapter-10/) | [](/book/tiny-c-projects/chapter-10/)A FIFO (named pipe) or socket |
| [](/book/tiny-c-projects/chapter-10/)S_ISREG()[](/book/tiny-c-projects/chapter-10/) | [](/book/tiny-c-projects/chapter-10/)Regular files |
| [](/book/tiny-c-projects/chapter-10/)S_ISLNK()[](/book/tiny-c-projects/chapter-10/) | [](/book/tiny-c-projects/chapter-10/)Symbolic link |
| [](/book/tiny-c-projects/chapter-10/)S_ISSOCK()[](/book/tiny-c-projects/chapter-10/) | [](/book/tiny-c-projects/chapter-10/)Socket |

[](/book/tiny-c-projects/chapter-10/)File type details aren’t the only information contained in the `st_mode` member[](/book/tiny-c-projects/chapter-10/) of the `stat` structure. This value also reveals the file’s permissions. File permissions refer to access bits that determine who-can-do-what to a file. Three access bits, called an octet[](/book/tiny-c-projects/chapter-10/), are available:

-  [](/book/tiny-c-projects/chapter-10/)Read (r)
-  [](/book/tiny-c-projects/chapter-10/)Write (w)
-  [](/book/tiny-c-projects/chapter-10/)Execute (x)

[](/book/tiny-c-projects/chapter-10/)Read permission means that the file is accessed read-only: the file’s data can be read but not modified. Write permission allows the file to be read and written to. Execute permission is set for program files, such as your C programs (set automatically by the compiler or linker), shell scripts (set manually), and directories. This is all standard Linux stuff, so if you desire more information, hunt down a grim, poorly written book on Linux for specifics.

[](/book/tiny-c-projects/chapter-10/)In Linux, the *chmod* command[](/book/tiny-c-projects/chapter-10/) sets and resets file permissions. These permissions can be seen in the long listing of a file when using the *ls* command with the `-l` (little L) switch[](/book/tiny-c-projects/chapter-10/):

```bash
$ ls -l fileinfo
-rwxrwxrwx 1 dang dang 8464 Oct 26 15:55 fileinfo
```

[](/book/tiny-c-projects/chapter-10/)The first chunk of info, `-rwxrwxrwx`, indicates the file type and permissions, which are detailed in figure 10.2. Next is the number of hard links (`1`), the owner (`dang`), and the group (`dang`). The value 8,464 is the file size in bytes, and then comes the date and time stamp, and finally the filename.

![Figure 10.2 Deciphering file permission bits in a long directory listing](https://drek4537l1klr.cloudfront.net/gookin/Figures/10-02.png)

[](/book/tiny-c-projects/chapter-10/)Three sets of file permissions octets are used for a file. These sets are based on user classification:

-  [](/book/tiny-c-projects/chapter-10/)Owner
-  [](/book/tiny-c-projects/chapter-10/)Group
-  [](/book/tiny-c-projects/chapter-10/)Other

[](/book/tiny-c-projects/chapter-10/)You are the owner of the files you create. As a user on the computer, you are also a member of a group. Use the *id* command to view your username and ID number, as well as the groups you belong to (names and IDs). View the `/etc/group` file to see the full list of groups on the system.

[](/book/tiny-c-projects/chapter-10/)File owners grant themselves full access to their files. Setting group permissions is one way to grant access to a bunch of system users at once. The third field, other, applies to anyone who is not the owner or in the named group.

[](/book/tiny-c-projects/chapter-10/)In the long directory listing, a file’s owner and group appear as shown earlier. This value is interpreted from the `st_mode` member[](/book/tiny-c-projects/chapter-10/) of the file’s `stat` structure. As with obtaining the file’s type, you can use defined constants and macros available in the `sys/stat.h` header file to test for the permissions for each user classification.

[](/book/tiny-c-projects/chapter-10/)I count nine permission-defined constants available in `sys/stat.h`, which accounts for each permission octet (three) and the three permission types: read, write, and execute. These are shown in table 10.3.

##### [](/book/tiny-c-projects/chapter-10/)Table 10.3 Defined constants used for permissions, available from the `sys/stat.h` header file[(view table figure)](https://drek4537l1klr.cloudfront.net/gookin/HighResolutionFigures/table_10-3.png)

| [](/book/tiny-c-projects/chapter-10/)Defined constant | [](/book/tiny-c-projects/chapter-10/)Permission octet |
| --- | --- |
| [](/book/tiny-c-projects/chapter-10/)S_IRUSR[](/book/tiny-c-projects/chapter-10/) | [](/book/tiny-c-projects/chapter-10/)Owner read permission |
| [](/book/tiny-c-projects/chapter-10/)S_IWUSR[](/book/tiny-c-projects/chapter-10/) | [](/book/tiny-c-projects/chapter-10/)Owner write permission |
| [](/book/tiny-c-projects/chapter-10/)S_IXUSR[](/book/tiny-c-projects/chapter-10/) | [](/book/tiny-c-projects/chapter-10/)Owner execute permission |
| [](/book/tiny-c-projects/chapter-10/)S_IRGRP[](/book/tiny-c-projects/chapter-10/) | [](/book/tiny-c-projects/chapter-10/)Group read permission |
| [](/book/tiny-c-projects/chapter-10/)S_IWGRP[](/book/tiny-c-projects/chapter-10/) | [](/book/tiny-c-projects/chapter-10/)Group write permission |
| [](/book/tiny-c-projects/chapter-10/)S_IXGRP[](/book/tiny-c-projects/chapter-10/) | [](/book/tiny-c-projects/chapter-10/)Group execute permission |
| [](/book/tiny-c-projects/chapter-10/)S_IROTH[](/book/tiny-c-projects/chapter-10/) | [](/book/tiny-c-projects/chapter-10/)Other read permission |
| [](/book/tiny-c-projects/chapter-10/)S_IWOTH[](/book/tiny-c-projects/chapter-10/) | [](/book/tiny-c-projects/chapter-10/)Other write permission |
| [](/book/tiny-c-projects/chapter-10/)S_IXOTH[](/book/tiny-c-projects/chapter-10/) | [](/book/tiny-c-projects/chapter-10/)Other execute permission |

[](/book/tiny-c-projects/chapter-10/)The good news is that these defined constants follow a naming pattern: each defined constant starts with `S_I`. The `I` is followed by `R`, `W`, or `X` for read, write, or execute, respectively. This letter is followed by `USR`, `GRP`, `OTH` for Owner (user), Group, and Other. This naming convention is summarized in figure 10.3.

![Figure 10.3 The naming convention used for permission defined constants in sys/stat.h](https://drek4537l1klr.cloudfront.net/gookin/Figures/10-03.png)

[](/book/tiny-c-projects/chapter-10/)For example, if you want to test the read permission for a group user, you use the `S_IRGRP` defined constant: `S_I` plus `R` for read and `GRP` for group. This defined constant is used in an *if* test[](/book/tiny-c-projects/chapter-10/) with a bitwise AND operator[](/book/tiny-c-projects/chapter-10/) to test the permission bit on the `st_mode` member[](/book/tiny-c-projects/chapter-10/):

```
If( fs.st_mode & S_IRGRP )
```

[](/book/tiny-c-projects/chapter-10/)The value in `fs_st_mode` (the file’s mode, including type and permissions) is tested against the bit in the `S_IRGRP` defined constant[](/book/tiny-c-projects/chapter-10/). If the test is true, meaning the bit is set, the file has read-only permissions set for the “other” group.

[](/book/tiny-c-projects/chapter-10/)Listing 10.2 puts the testing macros and defined constants to work for a file supplied as a command-line argument. This update to the *fileinfo* series of programs[](/book/tiny-c-projects/chapter-10/) outputs the file type and permissions for the named file. An *if else-if else* structure[](/book/tiny-c-projects/chapter-10/) handles the different file types as listed in table 10.2. Three sets of *if* tests output permissions for the three different groups. You see all the macros and defined constants discussed in this section used in the code. The code appears lengthy, but it contains a lot of copied and pasted information.

##### Listing 10.2 Source code for fileinfo04.c

```
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <time.h>
 
int main(int argc, char *argv[])
{
    char *filename;
    struct stat fs;
    int r;
 
    if( argc<2 )
    {
        fprintf(stderr,"Specify a filename\n");
        exit(1);
    }
 
    filename = argv[1];
    r = stat(filename,&fs);
    if( r==-1 )
    {
        fprintf(stderr,"Error reading '%s'\n",filename);
        exit(1);
    }
                                         #1
    printf("File '%s' is a ",filename);
    if( S_ISBLK(fs.st_mode) )            #2
        printf("block special\n");
    else if( S_ISCHR(fs.st_mode) )
        printf("character special\n");
    else if( S_ISDIR(fs.st_mode) )
        printf("directory\n");
    else if( S_ISFIFO(fs.st_mode) )
        printf("named pipe or socket\n");
    else if( S_ISREG(fs.st_mode) )
        printf("regular file\n");
    else if( S_ISLNK(fs.st_mode) )
        printf("symbolic link\n");
    else if( S_ISSOCK(fs.st_mode) )
        printf("socket\n");
    else
        printf("type unknown\n");
 
    printf("Owner permissions: ");       #3
    if( fs.st_mode & S_IRUSR )
        printf("read ");
    if( fs.st_mode & S_IWUSR )
        printf("write ");
    if( fs.st_mode & S_IXUSR )
        printf("execute");
    putchar('\n');
 
    printf("Group permissions: ");       #4
    if( fs.st_mode & S_IRGRP )
        printf("read ");
    if( fs.st_mode & S_IWGRP )
        printf("write ");
    if( fs.st_mode & S_IXGRP )
        printf("execute");
    putchar('\n');
 
    printf("Other permissions: ");       #5
    if( fs.st_mode & S_IROTH )
        printf("read ");
    if( fs.st_mode & S_IWOTH )
        printf("write ");
    if( fs.st_mode & S_IXOTH )
        printf("execute");
    putchar('\n');
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-10/)The program I created from the source code shown in listing 10.2 is named `a.out`, the default. Here is a sample run on the original *fileinfo* program:

```bash
$ ./a.out fileinfo
File 'fileinfo' is a regular file
Owner permissions: read write execute
Group permissions: read write execute
Other permissions: read write execute
```

[](/book/tiny-c-projects/chapter-10/)The information shown here corresponds to an `ls -l` listing output of `-rwxrwxrwx`.

[](/book/tiny-c-projects/chapter-10/)Here is the output for system directory `/etc`:

```bash
$ ./a.out /etc
File '/etc' is a directory
Owner permissions: read write execute
Group permissions: read execute
Other permissions: read execute
```

[](/book/tiny-c-projects/chapter-10/)From this output, the file type is correctly identified as a directory. The owner permissions are `rwx` (the owner is root). The group and other permissions are `r-x`, which means anyone on the computer can read and access (execute) the directory.

#### [](/book/tiny-c-projects/chapter-10/)Exercise 10.1

[](/book/tiny-c-projects/chapter-10/)The *if-else* structures[](/book/tiny-c-projects/chapter-10/) in listing 10.2 (`fileinfo04.c`) contain a lot of repetition. Seeing repetitive statements in code cries out to me for a function. Your task for this exercise is to a write a function that outputs a file’s permissions.

[](/book/tiny-c-projects/chapter-10/)Call the function *permissions_out[](/book/tiny-c-projects/chapter-10/)()*. It takes a *mode_t* argument of the `st_mode` member[](/book/tiny-c-projects/chapter-10/) in a stat structure. Here is the prototype:

```
void permissions_out(mode_t stm);
```

[](/book/tiny-c-projects/chapter-10/)Use the function to output a string of permissions for each of the three access levels: owner, group, other. Use characters `r`, `w`, `x`, for read, write, and execute access if a bit is set; use a dash (`-`) for unset items. This output is the same as shown in the `ls -l` listing, but without the leading character identifying the file type.

[](/book/tiny-c-projects/chapter-10/)A simple approach exists for this function, and I hope you find it. If not, you can view my solution in the source code file `fileinfo05.c`, available in the online repository. Please try this exercise on your own before peeking at my solution; comments in my code explain my philosophy. Use the *fileinfo* series of programs[](/book/tiny-c-projects/chapter-10/) to perform the basic operations for the *stat()* function[](/book/tiny-c-projects/chapter-10/), if you [](/book/tiny-c-projects/chapter-10/)prefer.

### [](/book/tiny-c-projects/chapter-10/)10.2.3 Reading a directory

[](/book/tiny-c-projects/chapter-10/)A [](/book/tiny-c-projects/chapter-10/)[](/book/tiny-c-projects/chapter-10/)directory is a database of files, but call them inodes if you want to have a nerd find you attractive. Just like a file, a directory database is stored on media. But you can’t use the *fopen()* function to open and read the contents of a directory. No, instead you use the *opendir()* function[](/book/tiny-c-projects/chapter-10/). Here is its *man* page format[](/book/tiny-c-projects/chapter-10/):

```
DIR *opendir(const char *filename);
```

[](/book/tiny-c-projects/chapter-10/)The *opendir()* function[](/book/tiny-c-projects/chapter-10/) accepts a single argument, a string representing the pathname of the directory to examine. Specifying the shortcuts `.` and `..` for the current and parent directory are also valid.

[](/book/tiny-c-projects/chapter-10/)The function returns a pointer to a *DIR* handle[](/book/tiny-c-projects/chapter-10/), similar to the *FILE* handle[](/book/tiny-c-projects/chapter-10/) used by the *fopen()* command[](/book/tiny-c-projects/chapter-10/). As the *FILE* handle[](/book/tiny-c-projects/chapter-10/) represents a file stream, the *DIR* handle[](/book/tiny-c-projects/chapter-10/) represents a directory stream.

[](/book/tiny-c-projects/chapter-10/)Upon an error, the NULL pointer is returned. The global `errno` value is set, indicating the specific booboo the function encountered.

[](/book/tiny-c-projects/chapter-10/)The *opendir()* function[](/book/tiny-c-projects/chapter-10/) features a companion *closedir()* function[](/book/tiny-c-projects/chapter-10/), similar to the *fclose()* function[](/book/tiny-c-projects/chapter-10/) as a companion to *fopen()*. The *closedir()* function[](/book/tiny-c-projects/chapter-10/) requires a single argument, the *DIR* handle of an open directory stream, humorously called “dirp” in the *man* page format[](/book/tiny-c-projects/chapter-10/) example:

```
int closedir(DIR *dirp);
```

[](/book/tiny-c-projects/chapter-10/)Yes, I know that the internet spells it “derp.”

[](/book/tiny-c-projects/chapter-10/)Upon success, the *closedir()* function[](/book/tiny-c-projects/chapter-10/) returns 0. Otherwise, the value -1 is returned and the global `errno` variable[](/book/tiny-c-projects/chapter-10/) is set, yadda-yadda.

[](/book/tiny-c-projects/chapter-10/)Both the *opendir[](/book/tiny-c-projects/chapter-10/)()* and *closedir()* functions[](/book/tiny-c-projects/chapter-10/) are prototyped in the `dirent.h` header file.

[](/book/tiny-c-projects/chapter-10/)In the following listing, you see both the *opendir[](/book/tiny-c-projects/chapter-10/)()* and *closedir()* functions[](/book/tiny-c-projects/chapter-10/) put to work. The current directory "." is opened because it’s always valid.

##### Listing 10.3 Source code for readdir01.c

```
#include <stdio.h>
#include <stdlib.h>
#include <dirent.h>
 
int main()
{
    DIR *dp;                         #1
 
    dp = opendir(".");               #2
    if(dp == NULL)                   #3
    {
        puts("Unable to read directory");
        exit(1);
    }
 
    puts("Directory is opened!");
 
    closedir(dp);                    #4
    puts("Directory is closed!");
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-10/)The code in listing 10.3 merely opens and closes the current directory. Boring! To access the files stored in the directory, you use another function, *readdir[](/book/tiny-c-projects/chapter-10/)()*. This function is also prototyped in the `dirent.h` header file. Here is the *man* page format[](/book/tiny-c-projects/chapter-10/):

```
struct dirent *readdir(DIR *dirp);
```

[](/book/tiny-c-projects/chapter-10/)The function consumes an open *DIR* handle[](/book/tiny-c-projects/chapter-10/) as its only argument. The return value is the address of a `dirent` structure[](/book/tiny-c-projects/chapter-10/), which contains details about a directory entry. This function is called repeatedly to read file entries (inodes) from the directory stream. The value NULL is returned after the final entry in the directory has been read.

[](/book/tiny-c-projects/chapter-10/)Sadly, the `dirent` structure isn’t as rich as I’d like it to be. Table 10.4 lists the two consistent structure members, though some C libraries offer more members. Any extra members are specific to the compiler or operating system and shouldn’t be relied on for code you plan to release into the wild. The only two required members for the POSIX.1 standard are `d_ino` for the entry’s inode and `d_name` for the entry’s filename.

##### [](/book/tiny-c-projects/chapter-10/)Table 10.4 Common members of the `dirent` structure[(view table figure)](https://drek4537l1klr.cloudfront.net/gookin/HighResolutionFigures/table_10-4.png)

| [](/book/tiny-c-projects/chapter-10/)Member | [](/book/tiny-c-projects/chapter-10/)Data type (placeholder) | [](/book/tiny-c-projects/chapter-10/)Description |
| --- | --- | --- |
| [](/book/tiny-c-projects/chapter-10/)d_ino[](/book/tiny-c-projects/chapter-10/) | [](/book/tiny-c-projects/chapter-10/)*ino_t* (%lu) | [](/book/tiny-c-projects/chapter-10/)Inode number |
| [](/book/tiny-c-projects/chapter-10/)d_reclen[](/book/tiny-c-projects/chapter-10/) | [](/book/tiny-c-projects/chapter-10/)*unsigned short* (%u) | [](/book/tiny-c-projects/chapter-10/)Record length |

[](/book/tiny-c-projects/chapter-10/)The best structure member to use, and one that’s consistently available across all compilers and platforms, is `d_name`. This member is used in the source code for `readdir02.c`, shown in the next listing. This update to `readdir01.c` removes two silly *puts()* statements. Added is a *readdir()* statement[](/book/tiny-c-projects/chapter-10/), along with a *printf()* function[](/book/tiny-c-projects/chapter-10/) to output the name of the first file found in the current directory.

##### Listing 10.4 Source code for readdir02.c

```
#include <stdio.h>
#include <stdlib.h>
#include <dirent.h>
 
int main()
{
    DIR *dp;
    struct dirent *entry;                   #1
 
    dp = opendir(".");
    if(dp == NULL)
    {
        puts("Unable to read directory");
        exit(1);
    }
 
    entry = readdir(dp);                    #2
 
    printf("File %s\n",entry->d_name);      #3
 
    closedir(dp);
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-10/)The program generated from the `readdir02.c` source code[](/book/tiny-c-projects/chapter-10/) outputs only one file—most likely, the entry for the current directory itself, the single dot. Obviously, if you want a real directory-reading program, you must modify the code.

[](/book/tiny-c-projects/chapter-10/)As with using the `fread()` function[](/book/tiny-c-projects/chapter-10/) to read data from a regular file , the `readdir()` function[](/book/tiny-c-projects/chapter-10/) is called repeatedly. When the function returns a pointer to a `dirent` structure[](/book/tiny-c-projects/chapter-10/), another entry is available in the directory. Only when the function returns NULL has the full directory been read.

[](/book/tiny-c-projects/chapter-10/)To update the code from `readdir02.c` to `readdir03.c`, you must change the *readdir()* statement[](/book/tiny-c-projects/chapter-10/) into a while loop condition. The *printf()* statement[](/book/tiny-c-projects/chapter-10/) is then set inside the *while* loop. Here are the changed lines:

```
while( (entry = readdir(dp)) != NULL )
{
   printf("File %s\n",entry->d_name);
}
```

[](/book/tiny-c-projects/chapter-10/)The *while* loop repeats as long as the value returned from *readdir()* isn’t NULL. With this update, the program now outputs all files in the current directory.

[](/book/tiny-c-projects/chapter-10/)To gather more information about files in a directory, use the *stat()* function[](/book/tiny-c-projects/chapter-10/), covered earlier in this chapter. The *readdir()* function’s[](/book/tiny-c-projects/chapter-10/) `dirent` structure[](/book/tiny-c-projects/chapter-10/) contains the file’s name in the `d_name` member. When this detail is known, you use the *stat()* function[](/book/tiny-c-projects/chapter-10/) to gather details on the file’s type as well as other information.

[](/book/tiny-c-projects/chapter-10/)The final rendition of the *readdir* series of programs is shown next. It combines code previously covered in this chapter to create a crude directory listing program. Entries are read one at a time, with the *stat()* function[](/book/tiny-c-projects/chapter-10/) returning specific values for file type, size, and access date.

##### Listing 10.5 Source code for readdir04.c

```
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <dirent.h>
#include <time.h>
 
int main()
{
    DIR *dp;
    struct dirent *entry;
    struct stat fs;
    int r;
    char *filename;
 
    dp = opendir(".");
    if(dp == NULL)
    {
        puts("Unable to read directory");
        exit(1);
    }
 
    while( (entry = readdir(dp)) != NULL )
    {
        filename = entry->d_name;              #1
        r = stat( filename,&fs );              #2
        if( r==-1 )
        {
            fprintf(stderr,"Error reading '%s'\n",filename);
            exit(1);
        }
        if( S_ISDIR(fs.st_mode) )              #3
            printf(" Dir %-16s ",filename);    #4
        else
            printf("File %-16s ",filename);    #5
 
        printf("%8lu bytes ",fs.st_size);      #6
 
        printf("%s",ctime(&fs.st_atime));      #7
    }
 
    closedir(dp);
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-10/)This code shows that to truly read a directory, you need both the *readdir[](/book/tiny-c-projects/chapter-10/)()* and *stat()* functions[](/book/tiny-c-projects/chapter-10/). Together, they pull in details about files in the directory—useful information if you plan on exploring directories or writing similar file utilities, such as a directory tree.

[](/book/tiny-c-projects/chapter-10/)Here is sample output from the program generated by the `readdir04.c` source code[](/book/tiny-c-projects/chapter-10/):

```
Dir .                    4096 bytes Sat Oct 30 16:44:34 2021
Dir ..                   4096 bytes Fri Oct 29 21:55:05 2021
File a.out                8672 bytes Sat Oct 30 16:44:34 2021
File fileinfo             8464 bytes Tue Oct 26 15:55:22 2021
File fileinfo01.c          966 bytes Sat Oct 30 16:24:49 2021
File readdir01.c           268 bytes Fri Oct 29 19:30:10 2021
```

[](/book/tiny-c-projects/chapter-10/)Incidentally, the order in which directory entries appear is dependent on the operating system. Some operating systems sort the entries alphabetically, so the *readdir()* function[](/book/tiny-c-projects/chapter-10/) fetches filenames in that order. This behavior isn’t consistent, so don’t rely upon it for the output of your [](/book/tiny-c-projects/chapter-10/)[](/book/tiny-c-projects/chapter-10/)directory-reading [](/book/tiny-c-projects/chapter-10/)programs.

## [](/book/tiny-c-projects/chapter-10/)10.3 Subdirectory exploration

[](/book/tiny-c-projects/chapter-10/)Directories [](/book/tiny-c-projects/chapter-10/)[](/book/tiny-c-projects/chapter-10/)are referenced in three ways:

-  [](/book/tiny-c-projects/chapter-10/)As a named path
-  [](/book/tiny-c-projects/chapter-10/)As the `..` shortcut to the parent directory
-  [](/book/tiny-c-projects/chapter-10/)As a directory entry in the current directory, a subdirectory

[](/book/tiny-c-projects/chapter-10/)Whatever the approach, pathnames are either direct or relative. A direct path is a fully named path, starting at the root directory, your home directory, or the current directory. A relative pathname uses the `..` shortcut for the parent directory—sometimes, a lot of them.

[](/book/tiny-c-projects/chapter-10/)As an example, a full pathname could be:

```
/home/dang/documents/finances/bank/statements
```

[](/book/tiny-c-projects/chapter-10/)This direct pathname shows the directories as they branch from the root, through my home directory, down to the `statements` directory.

[](/book/tiny-c-projects/chapter-10/)If I have another directory, `/home/dang/documents/vacations`, but I’m using the `statements` directory (shown earlier), the relative path from `statements` to `vacations` is:

```
../../../vacations
```

[](/book/tiny-c-projects/chapter-10/)The first `..` represents the `bank` directory. The second `..` represents the `finances` directory. The third `..` represents the `documents` directory, where `vacations` exists as a subdirectory. This construction demonstrates a relative path.

[](/book/tiny-c-projects/chapter-10/)These details about the path are a basic part of using Linux at the command prompt. Understanding these items is vital when it comes to your C programs and how they explore and access directories.

### [](/book/tiny-c-projects/chapter-10/)10.3.1 Using directory exploration tools

[](/book/tiny-c-projects/chapter-10/)Along [](/book/tiny-c-projects/chapter-10/)[](/book/tiny-c-projects/chapter-10/)with using the *opendir()* function[](/book/tiny-c-projects/chapter-10/) to read a directory and *readdir()* to examine directory entries, your code may need to change directories. Further, the program may want to know in which directory it’s currently running. Two C library functions exist to sate these desires: *chdir[](/book/tiny-c-projects/chapter-10/)()* and *getcwd[](/book/tiny-c-projects/chapter-10/)()*. I cover *getcwd[](/book/tiny-c-projects/chapter-10/)()* first because it can be used to confirm that the *chdir()* function[](/book/tiny-c-projects/chapter-10/) did its job.

[](/book/tiny-c-projects/chapter-10/)The [](/book/tiny-c-projects/chapter-10/)*getcwd()* function[](/book/tiny-c-projects/chapter-10/) obtains the directory in which the program is operating. Think of the name as Get the Current Working Directory. It works like the *pwd* command[](/book/tiny-c-projects/chapter-10/) in the terminal window. This function is prototyped in the `unistd.h` header file. Here is the *man* page format[](/book/tiny-c-projects/chapter-10/):

```
char *getcwd(char *buf, size_t size);
```

[](/book/tiny-c-projects/chapter-10/)Buffer `buf`[](/book/tiny-c-projects/chapter-10/) is a character array or buffer of `size` characters[](/book/tiny-c-projects/chapter-10/). It’s where the current directory string is saved, an absolute path from the root. Here’s a tip: you can use the `BUFSIZ` defined constant[](/book/tiny-c-projects/chapter-10/) for the size of the buffer as well as the second argument to *getcwd()*. Some C libraries have a `PATH_MAX` defined constant[](/book/tiny-c-projects/chapter-10/), which is available from the `limits.h` header file. Because its availability is inconsistent, I recommend using `BUFSIZ` instead. (The `PATH_MAX` defined constant is covered in chapter 11.)

[](/book/tiny-c-projects/chapter-10/)The return value from `getcwd()` is the same character string saved in `buf`, or NULL upon an error. For the specific error, check the global `errno` variable[](/book/tiny-c-projects/chapter-10/).

[](/book/tiny-c-projects/chapter-10/)The following listing shows a tiny demo program, `getcwd.c`[](/book/tiny-c-projects/chapter-10/), that outputs the current working directory. I use the `BUFSIZ` defined constant[](/book/tiny-c-projects/chapter-10/) to set the size for char array `cwd[]`[](/book/tiny-c-projects/chapter-10/)[](/book/tiny-c-projects/chapter-10/). The function is called and then the string output.

##### Listing 10.6 Source code for getcwd.c

```
#include <stdio.h>
#include <unistd.h>
 
int main()
{
    char cwd[BUFSIZ];                                      #1
    getcwd(cwd,BUFSIZ);
    printf("The current working directory is %s\n",cwd);   #2
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-10/)When run, the program outputs the current working directory as a full pathname. The buffer is filled with the same text you’d see output from the *pwd* command[](/book/tiny-c-projects/chapter-10/).

[](/book/tiny-c-projects/chapter-10/)The second useful directory function is *chdir[](/book/tiny-c-projects/chapter-10/)()*. This function works like the *cd* command in Linux. If you pay the senior price to see a movie, you may have used the *chdir* command in MS-DOS, though *cd* was also available and quicker to type.

[](/book/tiny-c-projects/chapter-10/)Like *getcwd()*, the *chdir()* function[](/book/tiny-c-projects/chapter-10/) is prototyped in the `unistd.h` header file. Here is the *man* page format[](/book/tiny-c-projects/chapter-10/):

```
int chdir(const char *path);
```

[](/book/tiny-c-projects/chapter-10/)The sole argument is a string representing the directory (`path`) to change to. The return value is 0 upon success, with -1 indicating an error. As you may suspect by now, the global variable `errno`[](/book/tiny-c-projects/chapter-10/) is set to indicate exactly what went afoul.

[](/book/tiny-c-projects/chapter-10/)I use both directory exploration functions in the `changecwd.c` source code[](/book/tiny-c-projects/chapter-10/) shown in the next listing. The *chdir()* function[](/book/tiny-c-projects/chapter-10/) changes to the parent directory, indicated by the double dots. The *getcwd()* function[](/book/tiny-c-projects/chapter-10/) obtains the full pathname to the new directory, outputting the results.

##### Listing 10.7 Source code for changecwd.c

```
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
 
int main()
{
    char cwd[BUFSIZ];
    int r;
 
    r = chdir("..");                                        #1
    if( r==-1 )
    {
        fprintf(stderr,"Unable to change directories\n");
        exit(1);
    }
 
    getcwd(cwd,BUFSIZ);                                     #2
    printf("The current working directory is %s\n",cwd);    #3
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-10/)The resulting program outputs the pathname to the parent directory of the directory in which the program is run.

[](/book/tiny-c-projects/chapter-10/)You notice in the source code for `changecwd.c` that I don’t bother returning to the original directory. Such coding isn’t necessary. An important thing to remember about using the *chdir()* function[](/book/tiny-c-projects/chapter-10/) is that the directory change happens only in the program’s environment. The program may change to directories all over the media, but when it’s done, the directory is the same as where the program [](/book/tiny-c-projects/chapter-10/)[](/book/tiny-c-projects/chapter-10/)started.

### [](/book/tiny-c-projects/chapter-10/)10.3.2 Diving into a subdirectory

[](/book/tiny-c-projects/chapter-10/)It’s [](/book/tiny-c-projects/chapter-10/)[](/book/tiny-c-projects/chapter-10/)easy to change to a subdirectory when you know its full path. An absolute path can be supplied by the user or it can be hardcoded into the program. But what happens when the program isn’t aware of its directory’s location?

[](/book/tiny-c-projects/chapter-10/)The parent directory is always known; you can use the double-dot abbreviation (`..`) to access the parent of every directory except the top level. Going up is easy. Going down requires a bit more work.

[](/book/tiny-c-projects/chapter-10/)Subdirectories are found by using the tools presented so far in this chapter: scan the current directory for subdirectory entries. Once known, plug the subdirectory name into the *chdir()* function[](/book/tiny-c-projects/chapter-10/) to visit that subdirectory.

[](/book/tiny-c-projects/chapter-10/)The code for `subdir01.c` in the next listing builds a program that lists potential subdirectories in a named directory. Portions of the code are pulled from other examples listed earlier in this chapter: a directory argument is required and tested for. The named directory is then opened and its entries read. If any subdirectories are found, they’re listed.

##### Listing 10.8 Source code for subdir01.c

```
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <dirent.h>
 
int main(int argc, char *argv[])
{
    DIR *dp;
    struct dirent *entry;
    struct stat fs;
    int r;
    char *dirname,*filename;
 
    if( argc<2 )                                       #1
    {
        fprintf(stderr,"Missing directory name\n");
        exit(1);
    }
    dirname = argv[1];                                 #2
 
    dp = opendir(dirname);                             #3
    if(dp == NULL)
    {
        fprintf(stderr,"Unable to read directory '%s'\n",
                dirname
               );
        exit(1);
    }
 
    while( (entry = readdir(dp)) != NULL )             #4
    {
        filename = entry->d_name;                      #5
        r = stat( filename,&fs );                      #6
        if( r==-1 )                                    #7
        {
            fprintf(stderr,"Error on '%s'\n",filename);
            exit(1);
        }
 
        if( S_ISDIR(fs.st_mode) )                      #8
            printf("Found directory: %s\n",filename);  #9
    }
 
    closedir(dp);
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-10/)The program generated from the source code `subdir01.c`[](/book/tiny-c-projects/chapter-10/) reads the directory supplied as a command-line argument and then outputs any subdirectories found in that directory. Here is output from a sample run, using my home directory:

```bash
$ ./subdir /home/dang
Found directory: .
Found directory: ..
Error on '.bash_history'
```

[](/book/tiny-c-projects/chapter-10/)Here is output from the root directory:

```bash
$ ./subdir /home/dang
Found directory: .
Found directory: ..
Error on 'bin'
```

[](/book/tiny-c-projects/chapter-10/)In both examples, the *stat()* function[](/book/tiny-c-projects/chapter-10/) fails. Your code could examine the `errno` variable[](/book/tiny-c-projects/chapter-10/), set when the function returns -1, but I can tell you right away what the error is: the first argument passed to the *stat()* function[](/book/tiny-c-projects/chapter-10/) must be a pathname. In the program, only the directory’s name is supplied, not a pathname. For example, the `.bash_history` subdirectory found in the first sample run shown earlier, and the `bin` directory found in the second don’t exist in the current directory.

[](/book/tiny-c-projects/chapter-10/)The solution is for the program to change to the named directory. Only when you change to a directory can the code properly read the files—unless you make the effort to build full pathnames. I’m too lazy to do that, so to modify the code, I add the following statements after the statement `dirname = argv[1]`:

```
r = chdir(dirname);
if( r==-1 )
{
   fprintf(stderr,"Unable to change to %s\n",dirname);
   exit(1);
}
```

[](/book/tiny-c-projects/chapter-10/)Further, you must include the `unistd.h` header file so that the compiler doesn’t complain about the *chdir()* function.

[](/book/tiny-c-projects/chapter-10/)With these updates to the code, available in the online repository as `subdir02.c`, the program now runs properly:

```bash
$ ./subdir /home/dang
Found directory: .
Found directory: ..
Found directory: .cache
Found directory: .config
Found directory: .ddd
Found directory: .lldb
Found directory: .ssh
Found directory: Dan
Found directory: bin
Found directory: prog
Found directory: sto
```

[](/book/tiny-c-projects/chapter-10/)Remember: to read files from a directory, you must either change to the directory (easy) or manually construct full pathnames for the files (not so easy).

#### [](/book/tiny-c-projects/chapter-10/)Exercise 10.2

[](/book/tiny-c-projects/chapter-10/)Every directory has the dot and dot-dot entries. Plus, many directories host hidden subdirectories. All hidden files in Linux start with a single dot. Your task for this exercise is to modify the source code from `subdir02.c` to have the program not output any file that starts with a single dot. My solution is available in the online repository as [](/book/tiny-c-projects/chapter-10/)[](/book/tiny-c-projects/chapter-10/)`subdir03.c`.

### [](/book/tiny-c-projects/chapter-10/)10.3.3 Mining deeper with recursion

[](/book/tiny-c-projects/chapter-10/)It [](/book/tiny-c-projects/chapter-10/)[](/book/tiny-c-projects/chapter-10/)[](/book/tiny-c-projects/chapter-10/)wasn’t until I wrote my first directory tree exploration program that I fully understood and appreciated the concept of recursion. In fact, directory spelunking is a great way to teach any coder the mechanics behind recursion and how it can be beneficial.

[](/book/tiny-c-projects/chapter-10/)As a review, *recursion* is the amazing capability of a function to call itself. It seems dumb, like an endless loop. Yet within the function exists an escape hatch, which allows the recursive function to unwind. Providing that the unwinding mechanism works, recursion is used in programming to solve all sorts of wonderful problems beyond just confusing beginners.

[](/book/tiny-c-projects/chapter-10/)When the *subdir* program[](/book/tiny-c-projects/chapter-10/) encounters a subdirectory, it can change to that directory to continue mining for even more directories. To do so, the same function that read the current directory is called again but with the subdirectory’s path. The process is illustrated in figure 10.4. Once the number of entries in a directory is exhausted, the process ends with a return to the parent directory. Eventually the functions return, backtracking to the original directory, and the program is done.

![Figure 10.4 The process of recursively discovering directories](https://drek4537l1klr.cloudfront.net/gookin/Figures/10-04.png)

[](/book/tiny-c-projects/chapter-10/)My issue with recursion is always how to unwind it. Plumbing the depths of subdirectories showed me that once all the directories are processed, control returns to the parent directory. Even then, as a seasoned Assembly language programmer accustomed to working where memory is tight, I fear blowing up the stack. It hasn’t happened yet—well, not when I code things properly.

[](/book/tiny-c-projects/chapter-10/)To modify the *subdir* series of programs[](/book/tiny-c-projects/chapter-10/) into a recursive directory spelunker, you must remove the program’s core, which explores subdirectories, and set it into a function. I call such a function *dir[](/book/tiny-c-projects/chapter-10/)()*. Its argument is a directory name:

```
void dir(const char *dirname);
```

[](/book/tiny-c-projects/chapter-10/)The *dir()* function[](/book/tiny-c-projects/chapter-10/) uses a *while* loop to process directory entries, looking for subdirectories. When found, the function is called again (within itself) to continue processing directory entries, looking for another subdirectory. When the entries are exhausted, the function returns, eventually ending in the original directory.

[](/book/tiny-c-projects/chapter-10/)The following listing implements the program flow from figure 10.4, as well as earlier versions of the *subdir* programs[](/book/tiny-c-projects/chapter-10/), to create a separate *dir()* function[](/book/tiny-c-projects/chapter-10/). It’s called recursively (within the function’s *while* loop) when a subdirectory is found. The *main()* function is also modified so that the current directory (`"."`) is assumed when a command line argument isn’t supplied.

##### Listing 10.9 Source code for subdir04.c

```
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <dirent.h>
#include <unistd.h>
#include <string.h>
 
void dir(const char *dirname)                     #1
{
    DIR *dp;
    struct dirent *entry;
    struct stat fs;
    char *filename;
    char directory[BUFSIZ];
 
    if( chdir(dirname)==-1 )                      #2
    {
        fprintf(stderr,"Unable to change to %s\n",dirname);
        exit(1);
    }
 
    getcwd(directory,BUFSIZ);                     #3
 
    dp = opendir(directory);                      #4
    if( dp==NULL )
    {
        fprintf(stderr,"Unable to read directory '%s'\n",
                directory
               );
        exit(1);
    }
 
    printf("%s\n",directory);                     #5
    while( (entry=readdir(dp)) != NULL )          #6
    {
        filename = entry->d_name;                 #7
        if( strncmp( filename,".",1)==0 )         #8
            continue;
 
        stat(filename,&fs);                       #9
        if( S_ISDIR(fs.st_mode) )                 #10
            dir(filename);                        #11
    }
 
    closedir(dp);
}
 
int main(int argc, char *argv[])
{
    if( argc<2 )
    {
        dir(".");                                 #12
    }
    else
        dir(argv[1]);                             #13
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-10/)Don’t bother typing in the code for `subdir04.c`. (Does anyone type in code from a book anymore?) Don’t even bother obtaining the source code from the online repository. The program won’t blow up your computer, but it contains several flaws.

[](/book/tiny-c-projects/chapter-10/)For example, here is a sample run on my home directory:

```bash
$ ./subdir ~
/home/dang
/mnt/c/Users/Dan
/mnt/c/Users/Dan/3D Objects
Unable to change to AppData
```

[](/book/tiny-c-projects/chapter-10/)You see the starting directory output correctly, `/home/dang`. Next, the program jumps on a symbolic link to my user profile directory in Windows (from the Linux command line). So far, so good; it followed the symbolic link to `/mnt/c/Users/Dan`. It successfully goes to the `3D Objects` directory, but then it gets lost. The directory `AppData` exists, but it’s not the next proper subdirectory to which the code should branch.

[](/book/tiny-c-projects/chapter-10/)What’s wrong?

[](/book/tiny-c-projects/chapter-10/)The flaw is present in figure 10.4 as well as in the source code shown in listing 10.9: when the *dir()* function[](/book/tiny-c-projects/chapter-10/) starts, it issues the *chdir()* function[](/book/tiny-c-projects/chapter-10/) to change to the named directory, `dirname`. But the *dir()* function[](/book/tiny-c-projects/chapter-10/) doesn’t change back to the parent/original directory when it has finished processing a subdirectory.

[](/book/tiny-c-projects/chapter-10/)To update the code and make the program return to the parent directory, add the following statements at the end of the *dir()* function[](/book/tiny-c-projects/chapter-10/):

```
if( chdir("..")==-1 )
{
   fprintf(stderr,"Parent directory lost\n");
   exit(1);
}
```

[](/book/tiny-c-projects/chapter-10/)The updated code is found in the online repository as `subdir05.c`. A sample run on my home directory outputs pages and pages of directories, almost properly.

[](/book/tiny-c-projects/chapter-10/)Almost.

[](/book/tiny-c-projects/chapter-10/)Turns out, the program created from `subdir05.c` can get lost, specifically with symbolic links. The code follows the symbolic link, but when it tries to return to the parent, it either loses its location or goes to the wrong parent. The problem lies with the *chdir()* chunk of statements just added to the code at the end of the *dir()* function[](/book/tiny-c-projects/chapter-10/). The parent directory isn’t specific:

```
chdir("..");
```

[](/book/tiny-c-projects/chapter-10/)This statement changes to the parent directory, but it’s far better to use the parent directory’s full path. In fact, as I was playing with the code, I discovered that it’s just best to work with full pathnames throughout the *dir()* function[](/book/tiny-c-projects/chapter-10/). Some changes are required.

[](/book/tiny-c-projects/chapter-10/)My final update redefines the *dir()* function[](/book/tiny-c-projects/chapter-10/) as follows:

```
void dir(const char *dirpath, const char *parentpath);
```

[](/book/tiny-c-projects/chapter-10/)For readability, I changed the arguments name to reflect that both are full pathnames. The first is the full pathname to the directory to scan. The second is the full pathname to the parent directory. Both are *const char* types[](/book/tiny-c-projects/chapter-10/) because neither string is modified within the function.

[](/book/tiny-c-projects/chapter-10/)Listing 10.10 shows the updated *dir()* function[](/book/tiny-c-projects/chapter-10/). Most of the changes involve removing *char* variable `directory`[](/book/tiny-c-projects/chapter-10/) and replacing it with argument `dirpath`. It’s also no longer necessary to change to the named directory in the function, which now assumes that the `dirpath` argument represents the current directory. Further comments are found in the code.

##### Listing 10.10 The updated *dir()* function from subdir06.c

```
void dir(const char *dirpath,const char *parentpath)
{
    DIR *dp;
    struct dirent *entry;
    struct stat fs;
    char subdirpath[BUFSIZ];                         #1
 
    dp = opendir(dirpath);                           #2
    if( dp==NULL )
    {
        fprintf(stderr,"Unable to read directory '%s'\n",
                dirpath
               );
        exit(1);
    }
 
    printf("%s\n",dirpath);                          #3
    while( (entry=readdir(dp)) != NULL )             #4
    {
        if( strncmp( entry->d_name,".",1)==0 )       #5
            continue;
 
        stat(entry->d_name,&fs);                     #6
        if( S_ISDIR(fs.st_mode) )                    #7
        {
            if( chdir(entry->d_name)==-1 )           #8
            {
                fprintf(stderr,"Unable to change to %s\n",
                        entry->d_name
                       );
                exit(1);
            }
 
            getcwd(subdirpath,BUFSIZ);               #9
            dir(subdirpath,dirpath);                 #10
        }
    }
 
    closedir(dp);                                    #11
 
    if( chdir(parentpath)==-1 )                      #12
    {
        if( parentpath==NULL )                       #13
            return;
        fprintf(stderr,"Parent directory lost\n");
        exit(1);
    }
}
```

[](/book/tiny-c-projects/chapter-10/)Updating the *dir()* function[](/book/tiny-c-projects/chapter-10/) requires that the *main()* function be updated as well. It has more work to do: the *main()* function must obtain the full pathname to the current directory or the `argv[1]` value, as well as the directory’s parent. This update to the main() function is shown here.

##### Listing 10.11 The updated *main()* function for subdir06.c

```
int main(int argc, char *argv[])
{
    char current[BUFSIZ];
 
    if( argc<2 )
    {
        getcwd(current,BUFSIZ);      #1
    }
    else
    {
        strcpy(current,argv[1]);     #2
        if( chdir(current)==-1 )     #3
        {
            fprintf(stderr,"Unable to access directory %s\n",
                    current
                   );
            exit(1);
        }
        getcwd(current,BUFSIZ);      #4
    }
 
    dir(current,NULL);               #5
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-10/)The full source code file is available in the online repository as `subdir06.c`. It accepts a directory argument or no argument, in which case the current directory is plumbed.

[](/book/tiny-c-projects/chapter-10/)Even though the program uses full pathnames, it may still get lost. Specifically, for symbolic links, the code may wander away from where you intend. Some types of links, such as aliases in Mac OS X, aren’t recognized as directories, so they’re skipped. And when processing system directories, specifically those that contain block or character files, the program’s stack may overflow and generate a [](/book/tiny-c-projects/chapter-10/)[](/book/tiny-c-projects/chapter-10/)[](/book/tiny-c-projects/chapter-10/)segmentation [](/book/tiny-c-projects/chapter-10/)[](/book/tiny-c-projects/chapter-10/)fault.

[](/book/tiny-c-projects/chapter-10/)The [](/book/tiny-c-projects/chapter-10/)ancient MS-DOS operating system featured the `TREE` utility[](/book/tiny-c-projects/chapter-10/). It dumped a map of the current directory structure in a festive, graphical (for a text screen) manner. This command is still available in Windows. In the CMD (command prompt) program in Windows, type **TREE** and you see output like that shown in figure 10.5: directories appear in a hierarchical structure, with lines connecting parent directories and subdirectories in a festive manner, along with indentation showing directory depth.

![Figure 10.5 Output from the TREE command](https://drek4537l1klr.cloudfront.net/gookin/Figures/10-05.png)

[](/book/tiny-c-projects/chapter-10/)The mechanics behind creating a directory tree program are already known to you. The source code for `subdir06.c` processes directories and subdirectories in the same manner as the output shown in figure 10.5. What’s missing are the shortened directory names, text mode graphics, and indentation. You can add these items, creating your own directory tree utility.

### [](/book/tiny-c-projects/chapter-10/)10.4.1 Pulling out the directory name

[](/book/tiny-c-projects/chapter-10/)To [](/book/tiny-c-projects/chapter-10/)[](/book/tiny-c-projects/chapter-10/)mimic the old `TREE` utility[](/book/tiny-c-projects/chapter-10/), the *dir()* function[](/book/tiny-c-projects/chapter-10/) must extract the directory name from the full pathname. Because full pathnames are used, and the string doesn’t end with a trailing slash, everything from the last slash in the string to the null character qualifies as the directory’s name.

[](/book/tiny-c-projects/chapter-10/)The easy way to extract the current directory name from a full pathname is to save the name when it’s found in the parent directory: the `entry->d_name` structure member contains the directory’s name as it appears in the parent’s directory listing. To make this modification, the *dir()* function[](/book/tiny-c-projects/chapter-10/) requires another argument, the short directory name. This modification is simple to code, which is why this approach is the easy way.

[](/book/tiny-c-projects/chapter-10/)The problem with the easy way is that the *main()* function obtains a full directory path when the program is started without an argument. So, even if you choose the easy way, you still must extract the directory name from the full pathname in the *main()* function. Therefore, my approach is to code a new function that pulls a directory name (or filename) from the end of a path.

[](/book/tiny-c-projects/chapter-10/)When I add new features to a program, such as when extracting a directory name from the butt end of a pathname, I write test code. In the next listing, you see the test code for the *extract()* function[](/book/tiny-c-projects/chapter-10/). Its job is to plow through a pathname to pull out the last part—assuming the last part of the string (after the final/separator character) is a directory name. Oh, and the function also assumes the environment is Linux; if you’re using Windows, you specify the backslash (two of them: `\\`) as the path separator, though Windows 10 may also recognize the forward slash.

##### Listing 10.12 Source code for extractor.c

```
#include <stdio.h>
#include <string.h>
 
const char *extract(char *path)
{
    const char *p;
    int len;
 
    len = strlen(path);
    if( len==0 )                      #1
        return(NULL);
    if( len==1 & *(path+0)=='/' )     #2
        return(path);
 
    p = path+len;                     #3
    while( *p != '/' )                #4
    {
        p--;
        if( p==path )                 #5
            return(NULL);
    }
    p++;                              #6
 
    if( *p == '\0' )                  #7
        return(NULL);
    else
        return(p);                    #8
}
 
int main()
{
    const int count=4;
    const char *pathname[count] =  {  #9
        "/home/dang",
        "/usr/local/this/that",
        "/",
        "nothing here"
    };
    int x;
 
    for(x=0; x<count; x++)
    {
        printf("%s -> %s\n",
                pathname[x],
                extract(pathname[x])
              );
    }
 
    return(0);
}
```

[](/book/tiny-c-projects/chapter-10/)The *extract()* function[](/book/tiny-c-projects/chapter-10/) backs up through the pathname string passed. Pointer `p` scans for the `/` separator. It leaves the function referencing the position in the string path where the final directory name starts. Upon an error, NULL is returned. A series of test strings in the *main()* function puts the *extract()* function[](/book/tiny-c-projects/chapter-10/) to work. Here is the output:

```
/home/dang -> dang
/usr/local/this/that -> that
/ -> /
nothing here -> (null)
```

[](/book/tiny-c-projects/chapter-10/)The *extract()* function[](/book/tiny-c-projects/chapter-10/) successfully processes each string, returning the last part, the directory name. It even catches the malformed string, properly returning NULL.

[](/book/tiny-c-projects/chapter-10/)For my first rendition of the directory tree program, I added the *extract()* function[](/book/tiny-c-projects/chapter-10/) to the final update to the *subdir* series of programs[](/book/tiny-c-projects/chapter-10/), `subdir06.c`. The *extract()* function[](/book/tiny-c-projects/chapter-10/) is called from within the *dir()* function[](/book/tiny-c-projects/chapter-10/), just before the main *while* loop that reads directory entries, replacing the existing *printf()* statement[](/book/tiny-c-projects/chapter-10/) at that line:

```
printf("%s\n",extract(dirpath));
```

[](/book/tiny-c-projects/chapter-10/)This update is saved as `dirtree01.c`. The resulting program, *dirtree*[](/book/tiny-c-projects/chapter-10/), outputs the directories but only their names and not the full pathnames. The output is almost a directory tree program, but without proper indenting for each subdirectory [](/book/tiny-c-projects/chapter-10/)[](/book/tiny-c-projects/chapter-10/)level.

### [](/book/tiny-c-projects/chapter-10/)10.4.2 Monitoring directory depth

[](/book/tiny-c-projects/chapter-10/)Programming [](/book/tiny-c-projects/chapter-10/)[](/book/tiny-c-projects/chapter-10/)the fancy output from the old `TREE` command[](/book/tiny-c-projects/chapter-10/), shown in figure 10.5, is more complicated than it looks. Emulating it exactly requires that the code use wide character output (covered in chapter 8). Further, the directory’s depth must be monitored as well as when the last subdirectory in a directory is output. Indeed, to fully emulate the `TREE` command[](/book/tiny-c-projects/chapter-10/) requires massively restructuring the *dirtree* program[](/book/tiny-c-projects/chapter-10/), primarily to save directory entries for output later.

[](/book/tiny-c-projects/chapter-10/)Yeah, so I’m not going there—not all the way.

[](/book/tiny-c-projects/chapter-10/)Rather than restructure the entire code, I thought I’d add some indentation to make the directory output of my *dirtree* series a bit more “tree”-like. This addition requires that the directory depth be monitored so that each subdirectory is indented a notch. To monitor the directory depth, the definition of the *dir()* function[](/book/tiny-c-projects/chapter-10/) is updated:

```
void dir(const char *dirpath,const char *parentpath, int depth);
```

[](/book/tiny-c-projects/chapter-10/)I consider three arguments to be the maximum for a function. Any more arguments, and it becomes obvious to me that what should really be passed to the function is a structure. In fact, I wrote a version of the *dirtree* program[](/book/tiny-c-projects/chapter-10/) that held directory entries in an array of structures. That code became overly complex, however, so I decided to just modify the *dir()* function[](/book/tiny-c-projects/chapter-10/) as shown earlier.

[](/book/tiny-c-projects/chapter-10/)To complete the modification in the code, three more changes are required. First, in the *main()* function, the *dir()* function[](/book/tiny-c-projects/chapter-10/) is originally called with zero as its third argument:

```
dir(current,NULL,0);
```

[](/book/tiny-c-projects/chapter-10/)The zero sets the indent depth as the program starts; the first directory is the top level.

[](/book/tiny-c-projects/chapter-10/)Second, the recursive call within the *dir()* function[](/book/tiny-c-projects/chapter-10/) must be modified, adding the third argument `depth`:

```
dir(subdirpath,dirpath,depth+1);
```

[](/book/tiny-c-projects/chapter-10/)For the recursive call, which means the program is diving down one directory level, the indent level `depth`[](/book/tiny-c-projects/chapter-10/) is increased by one.

[](/book/tiny-c-projects/chapter-10/)Finally, something must be done with the `depth` variable[](/book/tiny-c-projects/chapter-10/) within the *dir()* function[](/book/tiny-c-projects/chapter-10/). I opted to add a loop that outputs a chunk of three spaces for every depth level. This loop requires a new variable to be declared for function *dir[](/book/tiny-c-projects/chapter-10/)()*, integer `i` (for indent):

```
for( i=0; i<depth; i++ )
   printf("   ");
```

[](/book/tiny-c-projects/chapter-10/)This loop appears before the *printf()* statement[](/book/tiny-c-projects/chapter-10/) that outputs the directory’s name, just before the *while* loop. The result is that each subdirectory is indented three spaces as the directory tree is output.

[](/book/tiny-c-projects/chapter-10/)The source code for `dirtree02.c` is available in the online repository. Here is the program’s output for my `prog` (programming) directory:

```
prog
  asm
  c
     blog
     clock
     debug
     jpeg
     opengl
     wchar
     xmljson
     zlib
  python
```

[](/book/tiny-c-projects/chapter-10/)Each subdirectory is indented three spaces. The sub-subdirectories of the `c` directory are further indented.

#### [](/book/tiny-c-projects/chapter-10/)Exercise 10.3

[](/book/tiny-c-projects/chapter-10/)Modify the source code for `dirtree02.c` so that instead of indenting with blanks, the subdirectories appear with text mode graphics. For example:

```
prog
+--asm
+--c
|  +--blog
|  +--clock
|  +--debug
|  +--jpeg
|  +--opengl
|  +--wchar
|  +--xmljson
|  +--zlib
+--python
```

[](/book/tiny-c-projects/chapter-10/)These graphics aren’t as fancy (or precise) as those from the MS-DOS `TREE` command[](/book/tiny-c-projects/chapter-10/), but they are an improvement. This modification requires only a few lines of code. My solution is available in the online [](/book/tiny-c-projects/chapter-10/)[](/book/tiny-c-projects/chapter-10/)repository [](/book/tiny-c-projects/chapter-10/)as [](/book/tiny-c-projects/chapter-10/)`dirtree03.c`[](/book/tiny-c-projects/chapter-10/).
