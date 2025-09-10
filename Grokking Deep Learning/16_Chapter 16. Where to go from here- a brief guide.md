# Chapter 16. Where to go from here: a brief guide

### **In this chapter**

- Step 1: Start learning PyTorch
- Step 2: Start another deep learning course
- Step 3: Grab a mathy deep learning textbook
- Step 4: Start a blog, and teach deep learning
- Step 5: Twitter
- Step 6: Implement academic papers
- Step 7: Acquire access to a GPU
- Step 8: Get paid to practice
- Step 9: Join an open source project
- Step 10: Develop your local community

“Whether you believe you can do a thing or not, you are right.”

*Henry Ford, automobile manufacturer*

### Congratulations!

#### If you’re reading this, you’ve made it through nearly 300 pages of deep learning

You did it! This was a lot of material. I’m proud of you, and you should be proud of yourself. Today should be a cause for celebration. At this point, you understand the basic concepts behind artificial intelligence, and should feel quite confident in your abilities to speak about them as well as your abilities to learn advanced concepts.

This last chapter includes a few short sections discussing appropriate next steps for you, especially if this is your first resource in the field of deep learning. My general assumption is that you’re interested in pursuing a career in the field or at least continuing to dabble on the side, and I hope my general comments will help guide you in the right direction (although they’re only very general guidelines that may or may not directly apply to you).

### Step 1: Start learning PyTorch

#### The deep learning framework you made most closely resembles PyTorch

You’ve been learning deep learning using NumPy, which is a basic matrix library. You then built your own deep learning toolkit, and you’ve used that quite a bit as well. But from this point forward, except when learning about a new architecture, you should use an actual framework for your experiments. It will be less buggy. It will run (*way*) faster, and you’ll be able to inherit/study other people’s code.

Why should you choose PyTorch? There are many good options, but if you’re coming from a NumPy background, PyTorch will feel the most familiar. Furthermore, the framework you built in [chapter 13](/book/grokking-deep-learning/chapter-13/ch13) closely resembles the API of PyTorch. I did it this way specifically with the intent of preparing you for an actual framework. If you choose PyTorch, you’ll feel right at home. That said, choosing a deep learning framework is sort of like joining a house at Hogwarts: they’re all great (but PyTorch is definitely Gryffindor).

Now the next question: how should you learn PyTorch? The best way is to take a deep learning course that teaches you deep learning using the framework. This will jog your memory about the concepts you’re already familiar with while showing you where each piece lives in PyTorch. (You’ll review stochastic gradient descent while also learning about where it’s located in PyTorch’s API.) The best place to do this at the time of writing is either Udacity’s deep learning Nanodegree (although I’m biased: I helped teach it) or fast.ai. In addition, [https://pytorch.org/tutorials](https://pytorch.org/tutorials) and [https://github.com/pytorch/examples](https://github.com/pytorch/examples) are golden resources.

### Step 2: Start another deep learning course

#### I learned deep learning by relearning the same concepts over and over

Although it would be nice to think that one book or course is sufficient for your entire deep learning education, it’s not. Even if every concept was covered in this book (they aren’t), hearing the same concepts from multiple perspectives is essential for you to really grok them (see what I did there?). I’ve taken probably a half-dozen different courses (or YouTube series) in my growth as a developer in addition to watching tons of YouTube videos and reading lots of blog posts describing basic concepts.

Look for online courses on YouTube from the big deep learning universities or AI labs (Stanford, MIT, Oxford, Montreal, NYU, and so on). Watch all the videos. Do all the exercises. Do fast.ai, and Udacity if you can. Relearn the same concepts over and over. Practice them. Become familiar with them. You want the fundamentals to be second nature in your head.

### Step 3: Grab a mathy deep learning textbook

#### You can reverse engineer the math from your deep learning knowledge

My undergraduate degree at university was in applied discrete mathematics, but I learned way more about algebra, calculus, and statistics from spending time in deep learning than I ever did in the classroom. Furthermore, and this might sound surprising, I learned by hacking together NumPy code and then going back to the math problems it implements to figure out how they worked. This is how I really learned the deep learning–related math at a deeper level. It’s a nice trick I hope you’ll take to heart.

If you’re not sure which mathy book to go for, probably the best on the market at the time of writing is *Deep Learning* by Ian Goodfellow, Yoshua Bengio, and Aaron Courville (MIT Press, 2016). It’s not insane on the math side, but it’s the next step up from this book (and the math notation guide in the front of the book is golden).

### Step 4: Start a blog, and teach deep learning

#### Nothing I’ve ever done has helped my knowledge or career more

I probably should have put this as step 1, but here goes. Nothing has boosted my knowledge of deep learning (and my career in deep learning) more than teaching deep learning on my blog. Teaching forces you to explain everything as simply as possible, and the fear of public shaming will ensure that you do a good job.

Funny story: one of my first blog posts made it onto Hacker News, but it was horribly written, and a major researcher at a top AI lab totally destroyed me in the comments. It hurt my feelings and my confidence, but it also tightened up my writing. It made me realize that most of the time, when I read something and it’s hard to understand, it’s not my fault; the person who was writing it didn’t take enough time to explain all the little pieces I needed to know to understand the full concepts. They didn’t provide relatable analogies to help my understanding.

All that is to say, start a blog. Try to get on the Hacker News or ML Reddit front page. Start by teaching the basic concepts. Try to do it better than anyone else. Don’t worry if the topic has already been covered. To this day, my most popular blog post is “A Neural Network in 11 Lines of Python,” which teaches the most over-taught thing in deep learning: a basic feedforward neural network. But I was able to explain it in a new way, which helped some folks. The main reason it did was that I wrote the post in a way that helped *me* understand it. That’s the ticket. Teach things the way you want to learn them.

And don’t just do summaries of deep learning concepts! Summaries are boring, and no one wants to read them. Write tutorials. Every blog post you write should include a neural network that learns to do something—something the reader can download and run. Your blog should give a line-by-line account of what each piece does so that even a five-year-old could understand. That’s the standard. You may want to give up when you’ve been working on a two-page blog post for three days, but that’s not the time to turn back: that’s the time to press on and make it amazing! One great blog post can change your life. Trust me.

If you want to apply to a job, masters, or PhD program to do AI, pick a researcher you want to work with in that program, and write tutorials about their work. Every time I’ve done that, it has led to later meeting that researcher. Doing this shows that you understand the concepts they’re working with, which is a prerequisite to them wanting to work with you. This is much better than a cold email, because, assuming it gets on Reddit, Hacker News, or some other venue, someone else will send it to them first. Sometimes they’ll even reach out to you.

### Step 5: Twitter

#### A lot of AI conversation happens on Twitter

I’ve met more researchers from around the world on Twitter than almost any other way, and I’ve learned about nearly every paper I read because I was following someone who tweeted about it. You want to be up-to-date on the latest changes; and, more important, you want to become part of the conversation. I started by finding some AI researchers I looked up to, following them, and then following the people they follow. That got my feed started, and it has helped me greatly. (Just don’t let it become an addiction!)

### Step 6: Implement academic papers

#### Twitter + your blog = tutorials on academic papers

Watch your Twitter feed until you come across a paper that both sounds interesting and doesn’t need an insane number of GPUs. Write a tutorial on it. You’ll have to read the paper, decipher the math, and go through the motions of tuning that the original researchers also had to go through. There’s no better exercise if you’re interested in doing abstract research. My first published paper at the International Conference on Machine Learning (ICML) came out of me reading the paper for and subsequently reverse-engineering the code in word2vec. Eventually, you’ll be reading along and go, “Wait! I think I can make this better!” And voila: you’re a researcher.

### Step 7: Acquire access to a GPU (or many)

#### The faster you can experiment, the faster you can learn

It’s no secret that GPUs give 10 to 100× faster training times, but the implication is that you can iterate through your own (good and bad) ideas 100× faster. This is unbelievably valuable for learning deep learning. One of the mistakes I made in my career was waiting too long to start working with GPUs. Don’t be like me: go buy one from NVIDIA, or use the free K80s you can access in Google Colab notebooks. NVIDIA also occasionally lets students use theirs for free for certain AI competitions, but you have to watch out for them.

### Step 8: Get paid to practice

#### The more time you have to do deep learning, the faster you’ll learn

Another pivot point in my career was when I got a job that let me explore deep learning tools and research. Become a data scientist, data engineer, or research engineer, or freelance as a consultant doing statistics. The point is, you want to find a way to get paid to keep learning during work hours. These jobs exist; it just takes some effort to find them.

Your blog is essential to getting a job like this. Whatever job you want to get, write at least two blog posts showing that you can do whatever it is they’re looking to hire someone for. That’s the perfect resume (better than a degree in math). The perfect candidate is someone who has already shown they can do the job.

### Step 9: Join an open source project

#### The best way to network and career-build in AI is to become a cor- re developer in an open source project

Find a deep learning framework you like, and start implementing things. Before you know it, you’ll be interacting with researchers at the top labs (who will be reading/approving your pull requests). I know of plenty of folks who have landed awesome jobs (seemingly from nowhere) using this approach.

That being said, you have to put in the time. No one is going to hold your hand. Read the code. Make friends. Start by adding unit tests and documentation explaining the code, then work on bugs, and eventually start in on bigger projects. It takes time, but it’s an investment in your future. If you’re not sure, go with a major deep learning framework like PyTorch, TensorFlow, or Keras, or you can come work with me at OpenMined (which I think is the coolest open source project around). We’re very newbie friendly.

### Step 10: Develop your local community

#### I really learned deep learning because I enjoyed hanging with friends who were

I learned deep learning at Bongo Java, sitting next to my best friends who were also interested in it. A big part of me sticking with it when the bugs were hard to fix (it took me two days to find a single period once) or the concepts were hard to master was that I was spending time around the people I loved being with. Don’t underestimate this. If you’re in a place you like to be, with people you like to be with, you’re going to work longer and advance faster. It’s not rocket science, but you have to be intentional. Who knows? You might even have a little fun while you’re at it!
