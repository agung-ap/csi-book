# [](/book/tiny-c-projects/front-matter/)[](/book/tiny-c-projects/front-matter/)front matter

## [](/book/tiny-c-projects/front-matter/)preface

## [](/book/tiny-c-projects/front-matter/)Is C programming still relevant?

[](/book/tiny-c-projects/front-matter/)Every time I read that C is becoming obsolete, another article pops up on how C continues to be one of the most popular, in-demand programming languages—even as it passes its 50th birthday. Disparagement aside, C is the primary language used for system programming, networking, gaming, and coding microcontrollers. Even those trendy languages that the cool kids boast about most likely have their core originally written in C. It’s not going away any time soon.

[](/book/tiny-c-projects/front-matter/)I often refer to C as the Latin of computer programming languages. Its syntax and even a few keywords are borrowed heavily by other languages. Just as knowing Latin helps you understand and learn French, Italian, Spanish, and other languages, knowing C allows you to easily understand and learn other programming languages. But don’t stop there! Honing your C skills is just as important as exercising a muscle. And what better way to work on and perfect your C programming abilities than to continually write small, useful programs?

## [](/book/tiny-c-projects/front-matter/)Why did I write this book?

[](/book/tiny-c-projects/front-matter/)I feel the best way to learn programming is to use small demonstration programs. Each one focuses on a specific part of the language. The code is short and easy to type, and it drives home a point. If the little program can do something impressive, inspiring, or silly, all the better.

[](/book/tiny-c-projects/front-matter/)My approach contrasts with other programming books I’ve read. These tedious tomes often list a single, huge program that drives home all the concepts. Typing 100 lines of code when you have no clue what’s going on is discouraging, and it misses one of the more delightful aspects of programming: instant feedback.

[](/book/tiny-c-projects/front-matter/)Somehow, the habit of writing tiny programs sticks with me, even beyond when I’m writing a C programming book or teaching an online C programming course. For years, I’ve been coding tiny programs on my blog at [https://c-for-dummies.com/blog](https://c-for-dummies.com/blog/). I do so to provide supplemental material for my readers and learners, but also because I enjoy coding.

[](/book/tiny-c-projects/front-matter/)Of course, to make small programs meaningful, they must dwell in the ancient command-line, text-mode environment. Graphics are limited. Animation is dull. The excitement, however, remains—especially when something useful is presented all within only a few lines of code.

[](/book/tiny-c-projects/front-matter/)My approach echoes the way I code: start small and grow the code. So, the programs in this book may begin as only a dozen lines of code that output a simple message. From there the process expands. Eventually a useful program emerges, all while remaining tiny and tight and teaching something useful along the way.

[](/book/tiny-c-projects/front-matter/)Who knows when the mood will hit you and you decide to code a handy command-line utility to improve your workflow? With a knowledge of C programming, the desire, and a few hours of your time, you can make it happen. It’s my hope that this book provides you with ample inspiration.

## [](/book/tiny-c-projects/front-matter/)acknowledgments

[](/book/tiny-c-projects/front-matter/)I set out to be a fiction author. At one point, I was engaged in personal correspondence with a magazine editor who liked my stuff, but nothing was ever published. Then along came a job at a computer book publishing house, CompuSoft. There I combined my self-taught skills in programming with my love of writing to help craft a series of technical books. It was there I learned how to write for beginners and inject humor in the text.

[](/book/tiny-c-projects/front-matter/)Six years and 20 titles later, I wrote *DOS For Dummies*, which revolutionized the computer book publishing industry. This book showed that technological titles could successfully impart information to a beginner by using humor. The entire industry changed, and the *For Dummies* phenomenon continues to this day.

[](/book/tiny-c-projects/front-matter/)Computer books have diminished as an industry, thanks to the internet and humanity’s disdain for reading printed material. Still, it’s been a great journey and I have many people to thank: Dave Waterman, for hiring me at CompuSoft and teaching me the basics of technical writing; Bill Gladstone and Matt Wagner, for being my agents; Mac McCarthy, for the insane idea of *DOS For Dummies*; and Becky Whitney, for being my long-time, favorite editor. She has taught me more about writing than anyone—or perhaps just taught me how to write in a way that makes her job as editor easy. I appreciate all of you.

[](/book/tiny-c-projects/front-matter/)Finally, to all the reviewers: Adam Kalisz, Adhir Ramjiawan, Aditya Sharma, Alberto Simões, Ashley Eatly, Chris Kolosiwsky, Christian Sutton, Clifford Thurber, David Sims, Glen Sirakavit, Hugo Durana, Jean-François Morin, Jeff Lim, Joel Silva, Joe Tingsanchali, Juan Rufes, Jura Shikin, K. S. Ooi, Lewis Van Winkle, Louis Aloia, Maciej Jurkowski, Manu Raghavan Sareena, Marco Carnini, Michael Wall, Mike Baran, Nathan McKinley-Pace, Nitin Gode, Patrick Regan, Patrick Wanjau, Paul Silisteanu, Phillip Sorensen, Roman Zhuzha, Sanchir Kartiev, Shankar Swamy, Sriram Macharla, and Vitosh Doynov, your input helped make this a better book.

## [](/book/tiny-c-projects/front-matter/)about this book

### [](/book/tiny-c-projects/front-matter/)Who should read this book?

[](/book/tiny-c-projects/front-matter/)This book assumes that you have a good knowledge of C. You don’t need to be an expert, but a raw beginner may struggle with the pace. Though I explain the techniques used and my approach for writing these small programs, I don’t go into detail regarding how the basic aspects of C work.

[](/book/tiny-c-projects/front-matter/)The operating system I chose is Linux. Though I’ve run the code on a Linux box, I developed the programs on Ubuntu Linux running under Windows 10/11. The programs also run on a Macintosh. All the programs in this book are text mode, which requires a terminal window and knowledge of various shell commands, though nothing too technical or specific. Chapter 1 covers the details of coding and building in the command-prompt environment.

[](/book/tiny-c-projects/front-matter/)Bottom line: this book was written for anyone who loves the C language, enjoys programming, and takes pleasure from writing small, useful, and interesting programs.

### [](/book/tiny-c-projects/front-matter/)How this book is organized: A road map

[](/book/tiny-c-projects/front-matter/)This book is organized into 15 chapters. The first chapter touches upon configuration and setup to ensure that you get started properly and are able to code and create the programs without going nuts.

[](/book/tiny-c-projects/front-matter/)Chapters 2 through 15 each cover a specific type of program. The chapter builds upon the program’s idea, often presenting a simple version and then expanding the program to offer more features. Sometimes other programs are introduced along the way, each of which follows the main theme or otherwise assists the primary program in its goal.

### [](/book/tiny-c-projects/front-matter/)Software/hardware requirements

[](/book/tiny-c-projects/front-matter/)Any modern version of a C compiler works with this book. The code doesn’t touch upon any of the newer C language keywords. Some functions are specific to the GNU compiler. These are mentioned in the text, with alternative approaches available if your C compiler lacks the GNU extensions.

[](/book/tiny-c-projects/front-matter/)No third-party libraries are required to build any of the programs. Variations in Linux distributions or between Windows 10/11 and macOS play no significant role in creating the code presented here.

### [](/book/tiny-c-projects/front-matter/)Online resources

[](/book/tiny-c-projects/front-matter/)My personal C programming website is [c-for-dummies.com](https://c-for-dummies.com), which is updated weekly. I’ve been keeping up my habit of weekly C language lessons since 2013, each one covering a specific topic in C programming, offering advice on coding techniques, and providing a monthly Exercise challenge. Please check out the blog for up-to-date information and feedback on C, as well as more details about this book.

[](/book/tiny-c-projects/front-matter/)I also teach various C programming courses at LinkedIn Learning. These courses range from beginner level to advanced topics such as using various C language libraries, pointers, and network programming. Visit [www.linkedin.com/learning/instructors/dan-gookin](http://www.linkedin.com/learning/instructors/dan-gookin) to check out my courses.

### [](/book/tiny-c-projects/front-matter/)About the code

[](/book/tiny-c-projects/front-matter/)This book contains many examples of source code both in numbered listings and in line with normal text. In both cases, source code is formatted in a `fixed-width font like this` to separate it from ordinary text.

[](/book/tiny-c-projects/front-matter/)In many cases, the original source code has been reformatted; we’ve added line breaks and reworked indentation to accommodate the available page space in the book. In rare cases, even this was not enough, and listings include line-continuation markers (➥). Additionally, comments in the source code have often been removed from the listings when the code is described in the text. Code annotations accompany many of the listings, highlighting important concepts.

[](/book/tiny-c-projects/front-matter/)You can get executable snippets of code from the liveBook (online) version of this book at [https://livebook.manning.com/book/tiny-c-projects](https://livebook.manning.com/book/tiny-c-projects/). The complete code for the examples in the book is available for download from the Manning website at [www.manning.com](http://www.manning.com) and from GitHub at [github.com/dangookin/Tiny_C_Projects](https://github.com/dangookin/Tiny_C_Projects).

### [](/book/tiny-c-projects/front-matter/)liveBook discussion forum

[](/book/tiny-c-projects/front-matter/)Purchase of *Tiny C Projects* includes free access to liveBook, Manning’s online reading platform. Using liveBook’s exclusive discussion features, you can attach comments to the book globally or to specific sections or paragraphs. It’s a snap to make notes for yourself, ask and answer technical questions, and receive help from the author and other users. To access the forum, go to [https://livebook.manning.com/book/tiny-c-projects/discussion](https://livebook.manning.com/book/tiny-c-projects/discussion). You can also learn more about Manning’s forums and the rules of conduct at [https://livebook.manning.com/discussion](https://livebook.manning.com/discussion).

[](/book/tiny-c-projects/front-matter/)Manning’s commitment to our readers is to provide a venue where a meaningful dialogue between individual readers and between readers and the author can take place. It is not a commitment to any specific amount of participation on the part of the author, whose contribution to the forum remains voluntary (and unpaid). We suggest you try asking the author some challenging questions lest his interest stray! The forum and the archives of previous discussions will be accessible from the publisher’s website as long as the book is in print.

## [](/book/tiny-c-projects/front-matter/)about the author

![](https://drek4537l1klr.cloudfront.net/gookin/Figures/Gookin_author_black.png)

[](/book/tiny-c-projects/front-matter/)Dan Gookin has been writing about technology since the steam-powered days of computing. He combines his love of writing with his gizmo fascination to craft books that are informative and entertaining. Having written over 170 titles with millions of copies in print and translated into more than 30 languages, Dan can attest that his method of creating computer tomes seems to work.

[](/book/tiny-c-projects/front-matter/)Perhaps his most famous title is the original *DOS For Dummies*, published in 1991. It became the world’s fastest-selling computer book, at one time moving more copies per week than the *New York Times* #1 best-seller list (though as a reference, it couldn’t be listed on the NYT best-seller list). From that book spawned the entire line of *For Dummies* books, which remains a publishing phenomenon to this day.

[](/book/tiny-c-projects/front-matter/)Dan’s popular titles include *PCs For Dummies, Android For Dummies, Word For Dummies*, and *Laptops For Dummies*. His number-one programming title is *C For Dummies,* supported at [c-for-dummies.com](https://c-for-dummies.com). Dan also does online training at LinkedIn Learning, where his many courses cover a diverse range of topics.

[](/book/tiny-c-projects/front-matter/)Dan holds a degree in communications/visual arts from the University of California, San Diego. He resides in the Pacific Northwest, where he serves as councilman for the city of Coeur d’Alene, Idaho. Dan enjoys spending his leisure time gardening, biking, woodworking, and annoying people who think they’re important.

## [](/book/tiny-c-projects/front-matter/)about the cover illustration

[](/book/tiny-c-projects/front-matter/)The figure on the cover of *Tiny C Projects* is captioned “Femme de la Carniole,” or “Woman from Carniola,” taken from a collection by Jacques Grasset de Saint-Sauveur, published in 1797. Each illustration is finely drawn and colored by hand.

[](/book/tiny-c-projects/front-matter/)In those days, it was easy to identify where people lived and what their trade or station in life was just by their dress. Manning celebrates the inventiveness and initiative of the computer business with book covers based on the rich diversity of regional culture centuries ago, brought back to life by pictures from collections such as this one.
