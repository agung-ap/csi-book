## Exercise 49. A Statistics Server

The next phase of your project is to implement the very first feature of the `statserve` server. Your program from [Exercise 48](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch48.html#ch48) should be working and not crashing. Remember to think defensively and attempt to break and destroy your project as best you can before continuing. Watch both [Exercise 48](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch48.html#ch48) videos to see how I do this.

The purpose of `statserve` is for clients to connect to it and submit commands for modifying statistics. If you remember, we learned a little bit about doing incremental basic statistics, and you know how to use data structures like hash maps, dynamic arrays, binary search trees, and ternary search trees. These are going to be used in `statserve` to implement this next feature.

### Specification

You have to implement a protocol that your network client can use to store statistics. If you remember from [Exercise 43](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch43.html#ch43), you have three simple operations you can do to in the `stats.h` API:

**create** Create a new statistic.

**mean** Get the current mean of a statistic.

**sample** Add a new sample to a statistic.

**dump** Get all of the elements of a statistic (sum, sumsq, n, min, and max).

This will make the beginning of your protocol, but you’ll need to do some more things:

**1.** You’ll need to allow people to name these statistics, which means using one of the map style data structures to map names to `Stats` structs.

**2.** You’ll need to add the `CRUD` standard operations for each name. CRUD stands for create read update delete. Currently, the list of commands above has create, mean, and dump for reading; and sample for updating. You need a delete command now.

**3.** You may also need to have a `list` command for listing out all of the available statistics in the server.

Given that your `statserve` should handle a protocol that allows the above operations, let’s create statistics, update their sample, delete them, dump them, get the mean, and finally, list them.

Do your best to design a simple (and I mean *simple*) protocol for this using plain text, and see what you come up with. Do this on paper first, then watch the lecture video for this exercise to find out how to design a protocol and get more information about the exercise.

I also recommend using unit tests to test that the protocol is parsing separately from the server. Create separate .c and .h files for just processing strings with protocol in them, and then test those until you get them right. This will make things much easier when you add this feature to your server.
