# Chapter 2. Cryptographic hash functions and digital signatures

### **This chapter covers**

- Creating a simple money system: cookie tokens
- Understanding cryptographic hash functions
- Authenticating payments using digital signatures
- Keeping your secrets secret

I’ll start this chapter by setting the stage for the rest of this book. We’ll look at a simple payment system that we can improve on using Bitcoin technologies. By the time we get to [chapter 8](/book/grokking-bitcoin/chapter-8/ch08), this simple system will have evolved into what we call Bitcoin.

The second part of this chapter will teach you what you need to know about cryptographic hash functions. These are so important to Bitcoin that you really need to understand them before learning anything else. You’ll see how a cryptographic hash function can be used to verify that a file hasn’t changed since a previous point in time.

The rest of the chapter will solve the problem of the *imposter*: a bad guy claiming to be someone else to pay money from that someone’s account. We solve this problem by introducing digital signatures ([figure 2.1](/book/grokking-bitcoin/chapter-2/ch02fig01)) into the simple system.

![Figure 2.1. Digital signatures in Bitcoin](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/02fig01_alt.jpg)

### The cookie token spreadsheet

Suppose there’s a cafe in the office where you work. You and your coworkers use a spreadsheet to keep track of *cookie tokens* ([figure 2.2](/book/grokking-bitcoin/chapter-2/ch02fig02)), which use the symbol CT. You can exchange cookie tokens for cookies in the cafe.

![Figure 2.2. The cookie token spreadsheet has a column for the sender, a column for the recipient, and a column for the number of cookie tokens transferred. New cookie token transfers are appended at the end of the spreadsheet.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/02fig02_alt.jpg)

![Bitcoin, the currency](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-01.jpg)

A cookie token corresponds to a bitcoin, the currency unit of Bitcoin. Bitcoin got its first price point in 2010, when someone bought two pizzas for 10,000 BTC. That money would get you 6,000,000 pizzas as of November 2018.

Lisa stores this spreadsheet on her computer. It’s shared read-only for everybody on the office network to open and watch, except Lisa. Lisa is very trustworthy. Everybody trusts her. She has full access to do whatever she likes with the spreadsheet. You and all the others can only view the spreadsheet by opening it in read-only mode.

Whenever Alice wants a cookie, she asks Lisa, who sits right next to the cafe, to transfer 10 CT from Alice to the cafe. Lisa knows who Alice is and can verify in the spreadsheet that she owns enough cookie tokens; she’ll search for “Alice” in the spreadsheet, sum all the amounts with Alice’s name in the To column, and subtract all the amounts with Alice’s name in the From column. [Figure 2.3](/book/grokking-bitcoin/chapter-2/ch02fig03) shows the complete search result; three transfers involve Alice.

![Figure 2.3. Lisa calculates Alice’s balance. The sum of her received cookie tokens is 100, and the sum of her withdrawn cookie tokens is 30. Alice’s balance is 70 CT.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/02fig03_alt.jpg)

Lisa calculates that Alice has 70 CT, enough for Alice to pay 10 CT to the cafe. She *appends* a row at the end of the spreadsheet ([figure 2.4](/book/grokking-bitcoin/chapter-2/ch02fig04)).

![Figure 2.4. Lisa adds Alice’s payment for a cookie. The payment is appended last in the cookie token spreadsheet.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/02fig04_alt.jpg)

The cafe sees this new row in the spreadsheet and hands a cookie over to Alice.

![Earn them](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-02.jpg)

You can also get cookie tokens as part of your salary.

When you run out of cookie tokens, you can buy tokens for dollars from someone who is willing to sell you some—possibly Anne or the cafe—at a price you both agree on. Lisa will then add a row to the spreadsheet accordingly.

**Lisa has promised never to remove or change anything in the spreadsheet, just add to it. What happens in the spreadsheet, stays in the spreadsheet!**

Lisa, who is performing valuable work to secure this money system, is rewarded with 7,200 newly minted cookie tokens per day ([figure 2.5](/book/grokking-bitcoin/chapter-2/ch02fig05)). Every day, she adds a new row to the spreadsheet that creates 7,200 new cookie tokens with Lisa as the recipient.

![Figure 2.5. Lisa is rewarded with cookie tokens.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/02fig05_alt.jpg)

![Money supply curve](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-01.jpg)

Bitcoin uses the same schedule for issuance as the cookie token spreadsheet. All new bitcoins are created as rewards to the nodes securing the Bitcoin ledger—the blockchain—just as Lisa is rewarded for securing the cookie token spreadsheet.

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0030-01.jpg)

This is how all the cookie tokens in the spreadsheet are created. The first row in the spreadsheet is a reward row—like the one in the spreadsheet just shown—that creates the very first 7,200 CT ever. The plan is that Lisa is rewarded with 7,200 CT per day during the first four years, and then the reward is halved to 3,600 CT/day for the next four years, and so on until the reward is 0 CT/day.

Don’t worry, for now, about what happens when the reward approaches 0—that’s far in the future. We’ll discuss that in [chapter 7](/book/grokking-bitcoin/chapter-7/ch07). This reward halving makes the total money supply—the total number of cookie tokens in circulation—approach 21 million CT, but it will never exceed 21 million.

What Lisa does with the new cookie tokens she earns is up to her. She can buy cookies or sell the cookie tokens. She can also save them for later. The spreadsheet system works well, and everybody eats a healthy number of cookies.

Lisa basically performs the same work as miners in the Bitcoin network. She verifies payments and updates the ledger, the cookie token spreadsheet. [Table 2.1](/book/grokking-bitcoin/chapter-2/ch02table01) clarifies how the concepts in the spreadsheet correspond to concepts in Bitcoin.

##### Table 2.1. How key ingredients of the cookie token system and the Bitcoin system relate[(view table figure)](https://drek4537l1klr.cloudfront.net/rosenbaum/HighResolutionFigures/table_2-1.png)

| Cookie tokens | Bitcoin | Covered in |
| --- | --- | --- |
| 1 cookie token | 1 bitcoin | [Chapter 2](/book/grokking-bitcoin/chapter-2/ch02) |
| The spreadsheet | The blockchain | [Chapter 6](/book/grokking-bitcoin/chapter-6/ch06) |
| A row in the spreadsheet | A transaction | [Chapter 5](/book/grokking-bitcoin/chapter-5/ch05) |
| Lisa | A miner | [Chapter 7](/book/grokking-bitcoin/chapter-7/ch07) |

This table will follow us throughout the book. It describes differences between the cookie token system and Bitcoin. I’ll delete rows from it as I introduce various Bitcoin stuff. For example, the row “The spreadsheet” will be deleted in [chapter 6](/book/grokking-bitcoin/chapter-6/ch06), when we use a blockchain to store transactions. I’ll also add a few rows as I introduce new concepts for the cookie token system that differ from those in Bitcoin.

At the end of [chapter 8](/book/grokking-bitcoin/chapter-8/ch08), this table will contain only the first row, mapping 1 cookie token to 1 bitcoin. This will mark the end of this cookie token example, and from that point, we’ll talk only about Bitcoin itself.

[Table 2.2](/book/grokking-bitcoin/chapter-2/ch02table02) is your starting point for learning how Bitcoin works, which we can call version 1.0 of the cookie token spreadsheet system.

##### Table 2.2. Release notes, cookie tokens 1.0[(view table figure)](https://drek4537l1klr.cloudfront.net/rosenbaum/HighResolutionFigures/table_2-2.png)

| Version | Feature | How |
| --- | --- | --- |
|  | Simple payment system | Relies on Lisa being trustworthy and knowing everyone’s face |
| Finite money supply | 7,200 new CT rewarded to Lisa daily; halves every four years |  |

We’ll add a lot of fancy stuff to this system and release a new version in every chapter. For example, at the end of this chapter, we’ll release version 2.0, which uses digital signatures to solve the problem of imposters. Every chapter will take us closer to the end result: Bitcoin. But please be aware that this isn’t at all how Bitcoin evolved in reality—I’m just using this made-up system to help explain each important topic in isolation.

### Cryptographic hashes

Cryptographic hashes are used everywhere in Bitcoin. Trying to learn Bitcoin without knowing what cryptographic hashes are is like trying to learn chemistry without knowing what an atom is.

You can think of a cryptographic hash as a fingerprint. A person will produce the same fingerprint of her left thumb every time it’s taken, but it’s extremely hard to find another person with the same left thumb fingerprint. The fingerprint doesn’t disclose any information about the person other than that particular fingerprint. You can’t know what math skills or eye color the person has by looking at this fingerprint.

Digital information also has fingerprints. This fingerprint is called a *cryptographic hash*. To create a cryptographic hash of a file, you send the file into a computer program called a *cryptographic hash function*. Suppose you want to create a cryptographic hash—a fingerprint—of your favorite cat picture. [Figure 2.6](/book/grokking-bitcoin/chapter-2/ch02fig06) illustrates this process.

![Figure 2.6. Creating a cryptographic hash of a cat picture. Input is the cat picture, and output is a big, 32-byte number.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/02fig06_alt.jpg)

The output—the hash—is a 256-bit number; 256 bits equals 32 bytes because 1 byte consists of 8 bits. Thus, to store the number in a file, the file will be 32 bytes big, which is tiny compared to the size of the 1.21 MB cat picture. The particular cryptographic hash function used in this example is called SHA256 (Secure Hash Algorithm with 256-bit output) and is the most commonly used one in Bitcoin.

![Bits? Bytes? Hex?](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-02.jpg)

A *bit* is the smallest unit of information in a computer. It can take either of two different values: 0 or 1. Like a lightbulb, it can be either on or off. A *byte* is 8 bits that together can take 256 different values. We often use *hexadecimal*, or *hex*, encoding when we display numbers in this book. Each byte is printed as two hex digits each in the range 0–f, where a = 10 and f = 15.

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0033-01.jpg)

The word *hash* means something that’s chopped into small pieces or mixed up. That’s a good description of what a cryptographic hash function does. It takes the cat picture and performs a mathematical calculation on it. Out comes a big number—the cryptographic hash—that doesn’t look remotely like a cat. You can’t “reconstruct” the cat picture from just the hash—a cryptographic hash function is a *one-way function*. [Figure 2.7](/book/grokking-bitcoin/chapter-2/ch02fig07) shows what happens when you change the cat picture a little and run it through the same cryptographic hash function.

![Figure 2.7. Hashing a modified cat picture. Can you spot the difference? The cryptographic hash function certainly did.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/02fig07_alt.jpg)

This hash turns out completely different than the first hash. Let’s compare them:

- Old hash:

dee6a5d375827436ee4b47a930160457901dce84ff0fac58bf79ab0edb479561

copy

- New hash:

d2ca4f53c825730186db9ea585075f96cd6df1bfd4fb7c687a23b912b2b39bf6

copy

See how that tiny change to the cat picture made a huge difference in the hash value? The hash value is completely different, but the length of the hash is always the same regardless of input. The input “Hello” will also result in a 256-bit hash value.

#### Why are cryptographic hash functions useful?

Cryptographic hash functions can be used as an integrity check to detect changes in data. Suppose you want to store your favorite cat picture on your laptop’s hard drive, but you suspect the stored picture might become corrupted. This could happen, for example, due to disk errors or hackers. How can you make sure you detect corruption?

First, you calculate a cryptographic hash of the cat picture on your hard drive and write it down on a piece of paper ([figure 2.8](/book/grokking-bitcoin/chapter-2/ch02fig08)).

![Figure 2.8. Save a hash of the cat picture on a piece of paper.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/02fig08_alt.jpg)

Later, when you want to look at the picture, you can check if it’s changed since you wrote the hash on that paper. Calculate the cryptographic hash of the cat picture again, and compare it to the original hash on your paper ([figure 2.9](/book/grokking-bitcoin/chapter-2/ch02fig09)).

![Figure 2.9. Check the integrity of the cat picture. You detect a change.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/02fig09_alt.jpg)

![How sure?](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-02.jpg)

There’s a tiny chance the cat picture has changed even though the hashes match. But as you’ll see later, that chance is so small, you can ignore it.

If the new hash matches the one on paper, you can be sure the picture hasn’t changed. On the other hand, if the hashes don’t match, the cat picture has definitely changed.

Bitcoin uses cryptographic hash functions a lot to verify that data hasn’t changed. For example, every now and then—on average, every 10 minutes—a new hash of the entire payment history is created. If someone tries to change the data, anyone verifying the hash of the modified data will notice.

#### How does a cryptographic hash function work?

The real answer is complex, so I won’t go into exact detail. But to help you understand the operation of a cryptographic hash function, we’ll create a very simplistic one. Well, it isn’t really cryptographic, as I’ll explain later. Let’s just call it a hash function for now.

![Modulo](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-02.jpg)

*Modulo* means to wrap around when a calculation reaches a certain value. For example:

- 0 mod 256 = 0
- 255 mod 256 = 255
- 256 mod 256 = 0
- 257 mod 256 = 1
- 258 mod 256 = 2

258 mod 256 is the remainder of the integer division 258/256: 258 = 1 × 256 + 2. The remainder is 2.

Suppose you want to hash a file containing the six bytes `a1 02 12 6b c6 7d`. You want the hash to be a 1-byte number (8 bits). You can construct a hash function using *addition modulo 256*, which means to wrap around to 0 when the result of an addition reaches 256 ([figure 2.10](/book/grokking-bitcoin/chapter-2/ch02fig10)).

![Figure 2.10. Simplistic hash function using byte-wise addition modulo 256](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/02fig10_alt.jpg)

The result is the decimal number 99. What does 99 say about the original input `a1 02 12 6b c6 7d`? Not much—99 looks just as random as any other single-byte number.

If you change the input, the hash will change, although a chance exists that the hash will remain 99. After all, this simple hash function has just 256 different possible outputs. With real cryptographic hash functions, like the one we used to hash the cat picture, this chance is unimaginably small. You’ll soon get a glimpse of this probability.

#### Properties of a cryptographic hash function

A cryptographic hash function takes any digital input data, called a *pre-image*, and produces a fixed-length output, called a *hash*. In the example with the cat picture on your hard drive, the pre-image is the cat picture of 1.21 MB, and the hash is a 256-bit number. The function will output the exact same hash each time the same pre-image is used. But it will, with extremely high probability, output a totally different hash when even the slightest variation of that pre-image is used. The hash is also commonly referred to as a *digest*.

Let’s look at what properties you can expect from a cryptographic hash function. I’ll illustrate using SHA256 because it’s the one Bitcoin uses most. Several cryptographic hash functions are available, but they all provide the same basic properties:

1. **The same input will always produce the same hash.**
1. **Slightly different inputs will produce very different hashes.**
1. **The hash is always of the same fixed size. For SHA256, it’s 256 bits.**
1. **Brute-force trial and error is the only known way to find an input that gives a certain hash.**

![Figure 2.11. A cryptographic hash function, SHA256, in action. The input “Hello!” will give you the same output every time, but the slightly modified input “Hello” will give you totally different output.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/02fig11_alt.jpg)

[Figure 2.11](/book/grokking-bitcoin/chapter-2/ch02fig11) illustrates the first three properties. The fourth property of a cryptographic hash function is what makes it a *cryptographic* hash function, and this needs a bit more elaboration. There are some variations to the fourth property, all of which are desirable for cryptographic hash functions ([figure 2.12](/book/grokking-bitcoin/chapter-2/ch02fig12)):

![Figure 2.12. Different desirable properties for cryptographic hash functions. For collision resistance, X can be anything, as long as the two different inputs give the same output X.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/02fig12_alt.jpg)

- *Collision resistance*—You have only the cryptographic hash function at hand. It’s hard to find two *different* inputs that *result in the same hash*.
- *Pre-image resistance*—You have the hash function and a hash. It’s hard to find *a pre-image of that hash*.
- *Second-pre-image resistance*—You have the hash function and a pre-image (and thus the hash of that pre-image). It’s hard to find *another pre-image with the same hash*.

##### Illustration of “hard”

The term *hard* in this context means astronomically hard. It’s silly to even try. We’ll look at second-pre-image resistance as an example of what *hard* means, but a similar example can be made for any of the three variants.

Suppose you want to find an input to SHA256 that results in the same hash as “Hello!”:

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0037-01.jpg)

```
334d016f755cd6dc58c53a86e183882f8ec14f52fb05345887c8a5edd42c87b7
```

You can’t change the input “Hello!” just a little so the function “won’t notice.” It *will* notice and will output a totally different hash. The only way to find an input other than “Hello!” that gives the hash `334d016f...d42c87b7` is to try different inputs one by one and check whether one produces the desired hash.

Let’s try, using [table 2.3](/book/grokking-bitcoin/chapter-2/ch02table03).

##### Table 2.3. Finding an input with the same hash as “Hello!” is nearly impossible.[(view table figure)](https://drek4537l1klr.cloudfront.net/rosenbaum/HighResolutionFigures/table_2-3.png)

| Input | Hash | Success? |
| --- | --- | --- |
| Hello1! | 82642dd9...2e366e64 | Nope |
| Hello2! | 493cb8b9...83ba14f8 | Nope |
| Hello3! | 90488e86...64530bae | Nope |
| ... | ... | Nope, nope, ..., nope |
| Hello9998! | cf0bc6de...e6b0caa4 | Nope |
| Hello9999! | df82680f...ef9bc235 | Nope |
| Hello10000! | 466a7662...ce77859c | Nope |
|  | dee6a5d3...db479561 | Nope |
| My entire music collection | a5bcb2d9...9c143f7a | Nope |

![How big is 2256?](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-02.jpg)

2256 is about 1077, which is almost the number of atoms in the universe. Finding a pre-image of a SHA256 hash is like picking an atom in the universe and hoping it’s the correct one.

As you can see, we aren’t very successful. Think about how much time it would take for a typical desktop computer to find such an input. It can calculate about 60 million hashes per second, and the expected number of tries needed to find a solution is 2255. The result is 2255 / (60 × 106) s ≈ 1068 s ≈ 3 × 1061 years, or about 30,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000 years.

I think we can stop trying, don’t you? I don’t think buying a faster computer will help, either. Even if we had 1 trillion computers and ran them concurrently, it would take about 3 × 1049 years.

Pre-image resistance, second-pre-image resistance, and collision resistance are extremely important in Bitcoin. Most of its security relies on these properties.

#### Some well-known hash functions

[Table 2.4](/book/grokking-bitcoin/chapter-2/ch02table04) shows several different cryptographic hash functions. Some aren’t considered cryptographically secure.

##### Table 2.4. A few cryptographic hash functions. Some old ones have been deemed insecure.[(view table figure)](https://drek4537l1klr.cloudfront.net/rosenbaum/HighResolutionFigures/table_2-4.png)

| Name | Bits | Secure so far? | Used in Bitcoin? |
| --- | --- | --- | --- |
| SHA256 | 256 | Yes | Yes |
| SHA512 | 512 | Yes | Yes, in some wallets |
| RIPEMD160 | 160 | Yes | Yes |
| SHA-1 | 160 | No. A collision has been found. | No |
| MD5 | 128 | No. Collisions can be trivially created. The algorithm is also vulnerable to pre-image attacks, but not trivially. | No |

![Double SHA256](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-01.jpg)

We most often use double SHA256 in Bitcoin:

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0039-01.jpg)

Generally, when a single collision has been found in a cryptographic hash function, most cryptographers will consider the function insecure.

#### Recap of cryptographic hashes

A cryptographic hash function is a computer program that takes any data as input and computes a big number—a cryptographic hash—based on that input.

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0039-02_alt.jpg)

It’s astronomically hard to find an input that will result in a specific output. This is why we call it a *one-way function*. You have to repeatedly guess different inputs.

We’ll discuss important topics throughout this book. When you’ve learned about a specific topic, like cryptographic hash functions, you can put a new tool into your toolbox for later use. Your first tool is the cryptographic hash function, which is represented here by a paper shredder; the cryptographic hash is represented by a pile of paper strips.

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0040-01.jpg)

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0040-02_alt.jpg)

From now on, we’ll use these tool icons to represent cryptographic hash functions and cryptographic hashes, with some exceptions.

### Exercises

#### Warm up

**[2.1](/book/grokking-bitcoin/appendix-b/app02qa3q0a1)**

How many bits is the output of SHA256?

**[2.2](/book/grokking-bitcoin/appendix-b/app02qa3q0a2)**

How many bytes is the output of SHA256?

**[2.3](/book/grokking-bitcoin/appendix-b/app02qa3q0a3)**

What’s needed to calculate the cryptographic hash of the text “hash me”?

**[2.4](/book/grokking-bitcoin/appendix-b/app02qa3q0a4)**

What are the decimal and the binary representations of the hexadecimal data `061a`?

**[2.5](/book/grokking-bitcoin/appendix-b/app02qa3q0a5)**

Can you, in practice, modify the text “cat” so the modified text gets the same cryptographic hash as “cat”?

#### Dig in

**[2.6](/book/grokking-bitcoin/appendix-b/app02qa3q0a6)**

The simplistic hash function from the section “[How does a cryptographic hash function work?](/book/grokking-bitcoin/chapter-2/ch02lev2sec2)”, repeated for you as follows, isn’t a *cryptographic* hash function. Which two of the four properties of a cryptographic hash function is it lacking?

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0041-01_alt.jpg)

The four properties are also repeated as follows:

1. The same input will always produce the same hash.
1. Slightly different inputs will produce very different hashes.
1. The hash is always of the same fixed size. For SHA256, it’s 256 bits.
1. Brute-force trial and error is the only known way to find an input that gives a certain hash.

**[2.7](/book/grokking-bitcoin/appendix-b/app02qa3q0a7)**

Let’s go back to the example where you had a cat picture on your hard drive and wrote down the cryptographic hash of the picture on a piece of paper. Suppose someone wanted to change the cat picture on your hard drive without you noticing. What variant of the fourth property is important for stopping the attacker from succeeding?

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0041-02_alt.jpg)

### Digital signatures

In this section, we explore how you can prove to someone that you approve a payment. To do that, we use *digital signatures*. A digital signature is a digital equivalent of a handwritten signature. The difference is that a handwritten signature is tied to a person, whereas a digital signature is tied to a random number called a *private key*. A digital signature is much harder to forge than a handwritten signature.

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0042-01_alt.jpg)

#### Typical use of digital signatures

Suppose you want to send your favorite cat picture to your friend Fred via email, but you suspect the picture might be, maliciously or accidentally, corrupted during transfer. How would you and Fred make sure the picture Fred receives is exactly the same as the one you send?

![Figure 2.13. You send a digitally signed cat picture to Fred. Fred verifies the signature to make sure he’s got the same cat as the cat you signed.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/02fig13_alt.jpg)

You can include a digital signature of the cat picture in the email. Fred can then verify this digital signature to make sure the cat picture is authentic. You do this in three different phases, as [figure 2.13](/book/grokking-bitcoin/chapter-2/ch02fig13) shows.

Step ***1*** is *preparation*. You create a huge random number: the private key. You can use this to create digital signatures. You then create the *public key*, which is used to verify the signatures the private key creates. The public key is *calculated* from the private key. You hand the public key to Fred in person so Fred is sure it belongs to you.

Step ***2*** is *signing*. You write an email to Fred and attach the cat picture. You also use your private key and the cat picture to digitally sign the cat picture. The result is a digital signature that you include in your email message. You then send the email to Fred.

Step ***3*** is *verifying*. Fred receives your email, but he’s concerned the cat picture might be corrupt, so he wants to verify the signature. He uses the public key he got from you in step ***1***, the digital signature in the email, and the attached cat picture. If the signature or the cat picture has changed since you created the signature, the verification will fail.

#### Improving cookie token security

It’s time to return to our cookie token spreadsheet. The company is growing, and Lisa has a hard time recognizing everyone. She notices that some people aren’t honest. For example, Mallory says she is Anne, to trick Lisa into moving cookie tokens from Anne to the cafe, instead of from Mallory to the cafe. Lisa thinks of requiring everybody to digitally sign their cookie token transfers by writing a message and a digital signature in an email, as [figure 2.14](/book/grokking-bitcoin/chapter-2/ch02fig14) shows.

![Figure 2.14. John needs to digitally sign his payment request and include the signature in the email.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/02fig14.jpg)

Suppose John is the new guy at the office. The company gave him some cookie tokens as a welcome gift when he started. Now, John wants to buy a cookie in the cafe for 10 CT. He needs to digitally sign a cookie token transfer. [Figure 2.15](/book/grokking-bitcoin/chapter-2/ch02fig15) shows what he has to do.

![Figure 2.15. The digital signature process. 1 John creates a key pair and gives the public key to Lisa. 2 John signs a message with the private key. 3 Lisa verifies the message is signed with the private key belonging to the public key she got from John.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/02fig15_alt.jpg)

Just as with the email to Fred in the previous section, there are three phases in this process (please compare with the steps in [figure 2.13](/book/grokking-bitcoin/chapter-2/ch02fig13) to see the similarities):

- ***1*** John prepares by generating a key pair. John keeps the private key secret and hands the public key over to Lisa. This is a one-time setup step.
- ***2*** John wants a cookie. He writes a message and signs it with his private key. He sends the message and the digital signature in an email to Lisa.
- ***3*** Lisa verifies the signature of the message using John’s public key and updates the spreadsheet.

![Key pair reuse](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-02.jpg)

A key pair is created once. The same private key can be used several times to digitally sign stuff.

#### Preparation: John generates a key pair

The signing and verification processes are based on a key pair. John needs a private key to sign payments, and Lisa will need John’s public key to verify John’s signatures. John needs to prepare for this by creating a key pair. He does this by first generating a private key and then calculating the public key from that private key, as [figure 2.16](/book/grokking-bitcoin/chapter-2/ch02fig16) shows.

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0045-01.jpg)

![Figure 2.16. John creates a key pair. The private key is a huge random number, and the public key is derived from that random number. John stores his private key on his hard drive, and the public key is handed to Lisa.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/02fig16_alt.jpg)

John will use a random number generator to generate a huge, 256-bit random number. A random number generator is available on almost all operating systems. The random number is now John’s private key. The private key is then transformed into a public key using a public-key derivation function.

**Public-key derivation is a one-way function, just like cryptographic hash functions; you can’t derive the private key from the public key. The security of digital signatures relies heavily on this feature. Also, running the private key through the public-key derivation function multiple times will always result in the same public key.**

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0046-01.jpg)

The public key is 33 bytes (66 hex digits) long. This is longer than the private key, which is 32 bytes (64 hex digits) long. The reason for the “extra” byte and how the public-key derivation function works is a hard topic, covered in [chapter 4](/book/grokking-bitcoin/chapter-4/ch04). Luckily, you don’t have to be a cryptography expert to understand how signatures work from a user’s perspective.

##### Two ways to use the key pair

Keys are used to encrypt and decrypt data. Encryption is used to make messages unreadable to everybody but those who hold the proper decryption key.

We can think of the private and public keys as a pair because they have a strong relationship: the public key can be used to encrypt messages that only the private key can decrypt, and the private key can encrypt messages that only the public key can decrypt ([Figure 2.17](/book/grokking-bitcoin/chapter-2/ch02fig17)).

![Figure 2.17. Encrypting and decrypting with the public and private keys. Left: Encrypt with the public key, and decrypt with the private key. Right: Encrypt with the private key, and decrypt with the public key.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/02fig17_alt.jpg)

Following the left side of [figure 2.17](/book/grokking-bitcoin/chapter-2/ch02fig17), only John would be able to read the encrypted message because he’s the only one with access to his private key. Bitcoin doesn’t use this feature of public and private keys at all. It’s used when two parties want to communicate in private, as when you do your online banking. When you see the little padlock in the address bar of your web browser, then you know the process shown on the left side of the figure is being used to secure your communication.

We’ll use the right side of [figure 2.17](/book/grokking-bitcoin/chapter-2/ch02fig17) to make digital signatures. We won’t use the left side at all in this book.

Following the right side of the figure, Lisa can decrypt the message because she has the public key belonging to John’s private key. This feature is used for digital signatures. Using the private key to encrypt secret messages isn’t a good idea because the public key is, well, public. Anyone with the public key can decrypt the message. Digital signatures, on the other hand, don’t need any secret messages. We’ll explore digital signatures deeper soon. But first, some recap and orientation.

#### Recap of key pairs

Let’s summarize what you’ve learned about public and private keys. You create a key pair by first creating a private key. The private key is a huge, secret random number. The public key is then calculated from the private key.

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0047-01_alt.jpg)

You can use the private key to encrypt a message that can be decrypted only using the public key.

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0047-02_alt.jpg)

The encryption and decryption in this figure are the foundation for digital signatures. This process is *not* suitable for sending secret messages because the public key is usually widely known.

The reverse process is also common, in which the public key is used to encrypt and the private key is used to decrypt. This process is used to send secret messages. Bitcoin doesn’t use it.

![Where were we?](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-09.jpg)

Digital signatures were briefly mentioned in [chapter 1](/book/grokking-bitcoin/chapter-1/ch01), where Alice signed her Bitcoin transaction of 1 BTC to Bob using her private key ([figure 2.18](/book/grokking-bitcoin/chapter-2/ch02fig18)).

![Figure 2.18. Digital signatures in Bitcoin](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/02fig18.jpg)

John has created a pair of keys and is about to digitally sign his payment to the cafe with his private key so Lisa can verify that it’s actually John making the payment. Lisa verifies this using John’s public key.

#### John signs his payment

Let’s have a close look at how the signing really happens ([figure 2.19](/book/grokking-bitcoin/chapter-2/ch02fig19)).

![Figure 2.19. John digitally signs the transfer of 10 CT to the cafe. The message to Lisa is first hashed and then encrypted with John’s private key. The email to Lisa contains both the message in cleartext and the signature.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/02fig19_alt.jpg)

The message John wants to sign is, “Lisa, please move 10CT to Cafe. /John”. The signing function will hash this message with SHA256, whose output is a 256-bit number. This hash value is then encrypted with John’s private key. The result is a digital signature that looks like this:

```
INxAs7oFDr80ywy4bt5uYPIv/09fJMW+04U3sJUfgV39
A2k8BKzoFRHBXm8AJeQwnroNb7qagg9QMj7Vp2wcl+c=
```

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0048-01.jpg)

The signature is an encrypted hash of a message. If John had used another private key to sign with or a slightly different message, the signature would have looked completely different.

![Signatures in Bitcoin](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-01.jpg)

Bitcoin uses this type of signature for most payments today, but it isn’t the only way to authenticate a payment.

For example, using the input message “Lisa, please move 10CT to Mallory. /John” would generate this signature:

```
ILDtL+AVMmOrcrvCRwnsJUJUtzedNkSoLb7OLRoH2iaD
G1f2WX1dAOTYkszR1z0TfTVIVwdAlD0W7B2hBTAzFkk=
```

This isn’t remotely similar to the previous signature. This is good for John, because he knows his signature can’t be used for messages other than his specific message.

John has now composed an email to Lisa. This email contains a message and a signature of that message. John finishes by sending the email to Lisa.

#### Lisa verifies the signature

Lisa looks at the email and sees it claims to be from John, so she looks up John in her table of public keys ([figure 2.20](/book/grokking-bitcoin/chapter-2/ch02fig20)).

![Figure 2.20. Lisa uses the message A, the signature B, and John’s public key C to verify that the message is signed with John’s private key.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/02fig20_alt.jpg)

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0050-01.jpg)

Lisa’s actions in this figure aim to determine that the cookie token transfer was signed by the private key it claims to be signed with. The message *says* it’s from John. She received John’s public key the other day and put that public key in her table of public keys. The things she has at hand are

- ***A*** The message “Lisa, please move 10CT to Cafe. /John”
- ***B*** The signature `INxAs7oFDr8...`
- ***C*** John’s public key that she just looked up in her table

**John encrypted the message’s hash with his *private* key. This encrypted hash is the signature. If Lisa decrypts the signature *B* with John’s *public* key *C*, the result should be a hash that equals the hash of the message *A* in the email.**

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0050-02.jpg)

Lisa takes the signature ***B*** and decrypts it with the public key ***C*** she looked up in her table of public keys. The decryption outputs a big number. If this number is equal to the hash of the message ***A***, it proves John’s private key was used to sign the message. Lisa takes the message ***A***, exactly as written, and hashes that message just like John did when he created the signature. This message hash is then compared with the decrypted signature. The message hash and the decrypted signature match, which means the signature is valid.

Note that this process works only if John and Lisa use the exact same digital signature scheme. This must be agreed on beforehand, but it’s usually standardized. In Bitcoin, everyone knows exactly what digital signature scheme to use.

Lisa can now be sure no one is trying to fool her. She updates the spreadsheet with John’s transfer, as shown in [figure 2.21](/book/grokking-bitcoin/chapter-2/ch02fig21).

![Figure 2.21. Lisa has added a row for John’s cookie token transfer after verifying the signature of John’s message.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/02fig21_alt.jpg)

#### Private key security

John is in control of his cookie tokens because he owns the private key. No one but John can use John’s cookie tokens because he’s the only one with access to his private key. If his private key is stolen, he can lose any and all of his cookie tokens.

The morning after John’s transfer, he comes to the office, takes his laptop from his desk, and goes straight to the cafe to buy two morning cookies. He opens his laptop to write an email to Lisa:

- Good morning Lisa! Please move 20 CT to Cafe. /John
- Signature:

H1CdE34cRuJDsHo5VnpvKqllC5JrMJ1jWcUjL2VjPbsj
X6pi/up07q/gWxStb1biGU2fjcKpT4DIxlNd2da9x0o=

copy

He sends this email containing the message and a signature to Lisa. But the cafe doesn’t hand him any cookies. The guy behind the desk says he hasn’t seen an incoming payment of 20 CT yet. Lisa usually verifies and executes transfers quickly.

John opens the spreadsheet—he has read-only access, remember—and searches for “John.” [Figure 2.22](/book/grokking-bitcoin/chapter-2/ch02fig22) shows what he sees.

![Figure 2.22. Someone stole money from John. Who is Melissa, and how was this possible? John didn’t sign any such transfer.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/02fig22_alt.jpg)

John steps into Lisa’s office, asking for an explanation. She answers that she got a message signed with John’s private key, asking her to send money to a new coworker, Melissa. Lisa even shows him the message and signature. Of course, there is no Melissa at the office, even though several new employees have started at the company. Lisa doesn’t care about names anymore, only public keys and signatures. But she needs the name to look up the correct public key in the table.

The explanation to all this is that Mallory has

1. Managed to copy John’s private key. John’s laptop has been on his desk all night long. Anyone could have taken the hard drive out of the laptop to search for his private key.
1. Created a new key pair and sent the new public key to Lisa, with the following message:

- Hi Lisa. My name is Melissa, and I’m new here.
- My public key is

02c5d2dd24ad71f89bfd99b9c2132f796fa746596a06f5
a33c53c9d762e37d9008

copy

1. Sent a fraudulent message, signed with the stolen private key, to Lisa as follows:

- Hi Lisa, please move 90 CT to Melissa. Thanks, John
- Signature:

IPSq8z0IyCVZNZNMIgrOz5CNRRtRO+A8Tc3j9og4pWbA
H/zT22dQEhSaFSwOXNp0lOyE34d1+4e30R86qzEbJIw=

copy

Lisa verified the transfer in step 3, concluded it was valid, and executed the transfer. John asks Lisa to revert the—according to him—fraudulent transfer. But Lisa refuses to do so. She thinks the transfer is perfectly valid. If John let someone see his private key, that’s his problem, not Lisa’s. That’s part of why she’s so trusted in the company—she keeps her promises.

John creates a new key pair and asks Lisa to add his new public key under the name John2. How can John secure his new private key and still have it readily available when he wants a cookie? John is pretty sure he won’t have more than 1,000 cookie tokens on that key.

![You are responsible](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-02.jpg)

You have full responsibility for the security of your private keys.

The security of the spreadsheet has shifted from a system in which Lisa knows everyone’s face to one in which she knows everyone’s public key. In a sense, the security could be worse now, because it might be easier for Mallory to steal John’s private key than it is for her to trick Lisa into thinking Mallory is John. This depends on how John protects his private key. An important thing to note is that the security of John’s private key is totally up to him. No one will be able to restore John’s private key if he loses it. And Lisa sure isn’t going to reverse “fraudulent” transfers just because John is sloppy with security.

If John stores his private key in cleartext in a shared folder on the company’s intranet, anyone can easily copy it and use it to steal his cookie tokens. But if John stores the private key in an encrypted file, protected by a strong password, on his own laptop’s hard drive, getting a copy of his key is a lot harder. An attacker would have to

- Get access to John’s hard drive
- Know John’s password

If John never has more than 50 CT on his private key, he might not be that concerned with security. But the cafe, which manages about 10,000 CT daily, might be concerned. John and the cafe probably need different strategies for storing their private keys.

A trade-off exists between security and convenience. You can, for example, keep your private key encrypted on an offline laptop in a bank safe-deposit box. When you want to buy a cookie, you’ll need to go to the bank, take the laptop out of your safe-deposit box, decrypt the private key with your password, and use it to digitally sign a message to Lisa that you save to a USB stick. Then, you’ll have to put the laptop back into the safe-deposit box, bring the USB stick back to the office, and send the email to Lisa. The private key never leaves the laptop in the safe-deposit box. Very secure, and very inconvenient.

On the other hand, you can store your private key in cleartext on your mobile phone. You’ll have the key at your fingertips and can sign a message within seconds of when the urge for a cookie starts to nudge you. Very insecure, and very convenient.

Some of the different trade-offs, as illustrated in [figure 2.23](/book/grokking-bitcoin/chapter-2/ch02fig23), are as follows:

![Figure 2.23. Security considerations against attackers. Note how the more secure options are also more inconvenient.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/02fig23_alt.jpg)

- *Online vs. offline*—Online means the private key is stored on a device with network access, like your mobile phone or general-purpose laptop. Offline means the private key is stored on a piece of paper or a computer without any network access. Online storage is risky because remote security exploits or malicious software on your computer, such as computer viruses, might send the private key to someone without you noticing. If the device is offline, no one can take the private key without physical access to the device.
- *Cleartext vs. encrypted*—If the private key is stored in cleartext in a file on your computer’s hard drive, anyone with access to your computer, either remotely over a computer network or physically, can copy the private key. This includes any viruses your computer might be victim to. You can avoid many of these attacks by encrypting your private key with a password that only you know. An attacker would then need access to both your hard drive and your secret password to get the private key.
- *Whole key vs. split key*—People usually store their entire private key on a single computer. This is convenient—you need only one computer to spend your cookie tokens. An attacker must get access to your hard drive to steal the private key. But if your private key is split into three parts (there are good and bad schemes for this—be careful), and you store the three parts separately on three different computers, then the attacker must get access to the hard drives of three computers. This is much harder because they must know what three computers to attack and also successfully attack them. Making a payment in this setup is a real hassle, but very secure.

You can use any combination of these methods to store your keys. But as a rule of thumb, the greater the security against attackers, the greater the risk of you accidentally losing access to your key. For example, if you store the private key encrypted on your hard drive, you risk losing your key due to both computer failure and forgetting your password. In this sense, the more securely you store your key, the less secure it is.

### Recap

Lisa has solved the problem with people claiming to be someone else when they make a payment. She requires all payers to digitally sign the cookie token transfers. Every spreadsheet user needs a private key and a public key. Lisa keeps track of who owns which public key. From now on, a payment must be written in an email to Lisa, and the message must be digitally signed with the person’s private key. Lisa can then verify the signature to make sure she isn’t being fooled. The gist is that as long as John keeps his private key to himself, no one will be able to spend his money.

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0056-01_alt.jpg)

We need to add “Email to Lisa” to our concept table ([table 2.5](/book/grokking-bitcoin/chapter-2/ch02table05)).

##### Table 2.5. Adding “Email to Lisa” as a key concept[(view table figure)](https://drek4537l1klr.cloudfront.net/rosenbaum/HighResolutionFigures/table_2-5.png)

| Cookie tokens | Bitcoin | Covered in |
| --- | --- | --- |
| 1 cookie token | 1 bitcoin | [Chapter 2](/book/grokking-bitcoin/chapter-2/ch02) |
| The spreadsheet | The blockchain | [Chapter 6](/book/grokking-bitcoin/chapter-6/ch06) |
| **Email to Lisa** | **A transaction** | **[Chapter 5](/book/grokking-bitcoin/chapter-5/ch05)** |
| A row in the spreadsheet | A transaction | [Chapter 5](/book/grokking-bitcoin/chapter-5/ch05) |
| Lisa | A miner | [Chapter 7](/book/grokking-bitcoin/chapter-7/ch07) |

The email to Lisa will be replaced by transactions in [chapter 5](/book/grokking-bitcoin/chapter-5/ch05). Transactions will replace both the email to Lisa and the row in the spreadsheet. It’s time to release version 2.0 of the cookie token spreadsheet system ([table 2.6](/book/grokking-bitcoin/chapter-2/ch02table06)).

##### Table 2.6. Release notes, cookie tokens 2.0[(view table figure)](https://drek4537l1klr.cloudfront.net/rosenbaum/HighResolutionFigures/table_2-6.png)

| Version | Feature | How |
| --- | --- | --- |
|  | Secure payments | Digital signatures solve the problem with imposters. |
| 1.0 | Simple payment system | Relies on Lisa being trustworthy and knowing everyone’s face |
| Finite money supply | 7,200 new CT rewarded to Lisa daily; halves every four years |  |

Everybody still trusts Lisa to not change the spreadsheet in any way except when executing signed cookie token transfers. If Lisa wanted to, she could steal anyone’s cookie tokens just by adding a transfer to the spreadsheet. But she wouldn’t do that—or would she?

You now have a lot of new tools to put in your toolbox for later use: key-pair generation, digital signing, the signature, and the verification.

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0057-02.jpg)

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0057-03_alt.jpg)

### Exercises

#### Warm up

**[2.8](/book/grokking-bitcoin/appendix-b/app02qa3q0a8)**

Lisa is currently rewarded 7,200 CT per day for her work. Why won’t the supply increase infinitely over time? Why don’t we have 7,200 × 10,000 = 72 million CT after 10,000 days?

**[2.9](/book/grokking-bitcoin/appendix-b/app02qa3q0a9)**

How can coworkers detect if Lisa rewards herself too much or too often?

**[2.10](/book/grokking-bitcoin/appendix-b/app02qa3q0a10)**

How is the private key of a key pair created?

**[2.11](/book/grokking-bitcoin/appendix-b/app02qa3q0a11)**

What key is used to digitally sign a message?

**[2.12](/book/grokking-bitcoin/appendix-b/app02qa3q0a12)**

The signing process hashes the message to sign. Why?

**[2.13](/book/grokking-bitcoin/appendix-b/app02qa3q0a13)**

What would Mallory need to steal cookie tokens from John?

#### Dig in

**[2.14](/book/grokking-bitcoin/appendix-b/app02qa3q0a14)**

Suppose you have a private key and you’ve given your public key to a friend, Fred. Suggest how Fred can send you a secret message that only you can understand.

**[2.15](/book/grokking-bitcoin/appendix-b/app02qa3q0a15)**

Suppose you (let’s pretend your name is Laura) and Fred still have the keys from the previous exercise. Now you want to send a message in a bottle to Fred saying,

- Hi Fred! Can we meet at Tiffany’s at sunset tomorrow? /Laura

Explain how you would sign the message so Fred can be sure the message is actually from you. Explain what steps you and Fred take in the process.

### Summary

- Bitcoins are created as rewards to nodes securing the blockchain.
- The reward halves every four years to limit the money supply.
- You can use cryptographic hash functions to detect changes in a file or in a message.
- You can’t make up a pre-image of a cryptographic hash. A pre-image is an input that has a certain known output.
- Digital signatures are useful to prove a payment’s authenticity. Only the rightful owner of bitcoins may spend them.
- Someone verifying a digital signature doesn’t have to know *who* made the signature. They just have to know the signature was made with the private key the signature claims to be signed with.
- To receive bitcoins or cookie tokens, you need a public key. First, you create a private key for yourself in private. You then derive your public key from your private key.
- Several strategies are available for storing private keys, ranging from unencrypted on your mobile phone to split and encrypted across several offline devices.
- As a general rule of thumb, the more secure the private key is against theft, the easier it is to accidentally lose the key, and vice versa.
