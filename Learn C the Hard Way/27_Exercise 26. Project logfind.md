## Exercise 26. Project logfind

This is a small project for you to attempt on your own. To be effective at C, you’ll need to learn to apply what you know to problems. In this exercise, I describe a tool I want you to implement, and I describe it in a vague way on purpose. This is done so that you will try to implement whatever you can, however you can. When you’re done, you can then watch a video for the exercise that shows you how *I* did it, and then you can get the code and compare it to yours.

Think of this project as a real-world puzzle that you might have to solve.

### The logfind Specification

I want a tool called `logfind` that lets me search through log files for text. This tool is a specialized version of another tool called `grep`, but designed only for log files on a system. The idea is that I can type:

```
logfind zedshaw
```

And, it will search all the common places that log files are stored, and print out every file that has the word “zedshaw” in it.

The `logfind` tool should have these basic features:

**1.** This tool takes any sequence of words and assumes I mean “and” for them. So `logfind zedshaw smart guy` will find all files that have `zedshaw` *and* `smart` *and* `guy` in them.

**2.** It takes an optional argument of `-o` if the parameters are meant to be *or* logic.

**3.** It loads the list of allowed log files from `~/.logfind`.

**4.** The list of file names can be anything that the `glob` function allows. Refer to `man 3 glob` to see how this works. I suggest starting with just a flat list of exact files, and then add `glob` functionality.

**5.** You should output the matching lines as you scan, and try to match them as fast as possible.

That’s the entire description. Remember that this may be *very* hard, so take it a tiny bit at a time. Write some code, test it, write more, test that, and so on in little chunks until you have it working. Start with the simplest thing that gets it working, and then slowly add to it and refine it until every feature is done.
