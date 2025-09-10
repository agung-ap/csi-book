## Exercise 51. Storing the Statistics

The next problem to solve is how to store the statistics. There is an advantage to having the statistics in memory, because it’s much faster than storing them. In fact, there are large data storage systems that do this very thing, but in our case, we want a smaller server that can store some of the data to a hard drive.

### The Specification

For this exercise, you’ll add two commands for storing to and loading statistics from a hard drive:

**store** If there’s a URL, store it to a hard drive.

**load** If there are two URLs, load the statistic from the hard drive based on the first URL, and then put it into the second URL that’s in memory.

This may seem simple, but you’ll have a few battles when implementing this feature:

**1.** If URLs have `/` characters in them, then that conflicts with the filesystem’s use of slashes. How will you solve this?

**2.** If URLs have `/` characters in them, then someone can use your server to overwrite files on a hard drive by giving paths to them. How will you solve this?

**3.** If you choose to use deeply nested directories, then traversing directories to find files will be very slow. What will you do here?

**4.** If you choose to use one directory and hash URLs (oops, I gave a hint), then directories with too many files in them are slow. How will you solve this?

**5.** What happens when someone loads a statistic from a hard drive into a URL that already exists?

**6.** How will someone running `statserve` know where the storage should be?

An alternative to using a filesystem to store the data is using something like SQLite and SQL. Another option is to use a system like GNU dbm (GDBM) to store them in a simpler database.

Research all of your options and watch the lecture video, and then pick the simplest option and try it. Take your time figuring out this feature because the next exercise will involve figuring out how to destroy your server.
