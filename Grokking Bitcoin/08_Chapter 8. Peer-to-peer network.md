# Chapter 8. Peer-to-peer network

### **This chapter covers**

- Removing the last central authority: the shared folder
- Following a transaction in the peer-to-peer network
- Leaving behind the silly cookie tokens
- Bootstrapping the peer-to-peer network

Let’s talk about the elephant in the room: the shared folder. All blocks the miners produce must pass through the shared folder on their way to other full nodes and miners. This chapter will remove the central shared folder and replace it with a decentralized *peer-to-peer network* ([figure 8.1](/book/grokking-bitcoin/chapter-8/ch08fig01)). The peer-to-peer network lets full nodes (including miners) send blocks directly to each other. When nodes can talk directly to each other, we no longer need a central point of authority for communication.

![Figure 8.1. Bitcoin’s peer-to-peer network](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/08fig01_alt.jpg)

Another issue we haven’t talked much about is how wallets send transactions via email to the miners. When a new miner joins the system, all wallets need to update their miner list. Not cool. With this nice peer-to-peer network of nodes, wallets can broadcast their transactions to all miners without knowing who or where they are.

We’ll follow a transaction’s path through the network, both as an unconfirmed transaction and, eventually, as part of a mined block. The transaction will start in John’s wallet and end as a confirmed transaction in the blockchain with Bob’s wallet being notified about it.

After following the transaction through the system, you’ll no longer need the cookie token system to help you understand Bitcoin. We’ll talk only about Bitcoin from that point forward. Practically no differences exist between the cookie token system and Bitcoin anymore, so it doesn’t make sense to keep talking about cookie tokens when, in fact, you want to learn about Bitcoin!

The last topic in this chapter will cover how a new node connects to and becomes part of the peer-to-peer network. This is far from trivial. How does it find nodes to connect to? How does it download the blockchain up to the latest block? We’ll sort all that out. Toward the end of the chapter, you’ll learn how to set up a full node of your own.

### The shared folder

The shared folder administrator, Luke, is a central authority ([figure 8.2](/book/grokking-bitcoin/chapter-8/ch08fig02)). He ultimately gets to decide which blocks can be stored in the shared folder. He also gets to decide who can read from and write to the shared folder.

![Figure 8.2. The shared folder is a central point of authority.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/08fig02_alt.jpg)

So far, we’ve assumed Luke is a totally neutral good guy—but what if he isn’t, or what if he’s forced by Acme Insurances to reject certain blocks? What’s the point of proof of work if the system can be censored at the block level? Proof of work made the *transactions* censorship-resistant because it let users send their transactions to multiple miners. But the *blocks* containing the transactions can still be censored by whoever has administrator privileges over the shared folder. Simply put, the system isn’t yet censorship-resistant. As long as a single entity can decide which blocks or transactions to allow, the system isn’t censorship-resistant.

The shared folder poses yet another problem. Imagine that Rashid has created a 1 MB block and published it to the shared folder. Everyone watching the shared folder, all full nodes, will download Rashid’s block at the same time. If you have 100 full nodes, the total amount of data you need to send from the shared folder to the different nodes is 100 MB. This will cause *block propagation*—the transfer of a block from its creator to all other nodes—to be terribly slow. The more nodes, the slower the block propagation.

### Let’s build a peer-to-peer network

What if the full nodes and miners could talk directly to each other instead of relying on the central shared folder? They could send the blocks directly to one another in a peer-to-peer network ([figure 8.3](/book/grokking-bitcoin/chapter-8/ch08fig03)).

![Figure 8.3. In a peer-to-peer network, blocks are passed from one node to another, much as gossip spreads among people.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/08fig03_alt.jpg)

Think of the peer-to-peer network as a large number of people. One person doesn’t know everyone else, but might know three people. When something interesting happens—for example, Rashid finds a block—he tells his three friends about it, who in turn tell all their friends, and so on until everybody knows about this new block. We call such networks *gossip networks* for apparent reasons.

![Relay](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-02.jpg)

To *relay* a received block means to pass the block on to others.

**Blocks can no longer be easily stopped. A node can choose not to pass a block on, or *relay* it, to its peers, but the peers are connected to several other peers that will gladly relay the block to them. A single node can’t do much to censor information**.

Suppose Rashid finds a block, and he wants to get this block out to all nodes. Rashid sends his block to Qi, Tom, and the cafe. For some reason, the cafe doesn’t forward the block to Lisa ([figure 8.4](/book/grokking-bitcoin/chapter-8/ch08fig04)). But Lisa has several peers in this network. She’s connected to Tom and Qi. Tom will tell Lisa about this new block and send it to her. The cafe can’t hide information from Lisa as long as she’s well-connected—that is, has many different peers.

![Figure 8.4. If the cafe refuses to relay a block to Lisa, someone else will do it.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/08fig04_alt.jpg)

Now that you have this nice network, wallets can use it to get their transactions sent to miners. Then they won’t have to keep track of miner email addresses anymore. The transactions will be broadcast over the peer-to-peer network and reach all full nodes within seconds. This includes the miners, because they’re also full nodes. We covered this briefly in [chapter 1](/book/grokking-bitcoin/chapter-1/ch01), as repeated in [figure 8.5](/book/grokking-bitcoin/chapter-8/ch08fig05).

![Figure 8.5. Transactions travel the peer-to-peer network just like blocks do. Wallets no longer need to know the miners.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/08fig05_alt.jpg)

The same thing goes here as for blocks: a single node can’t hinder transactions from spreading across the network. Another pleasant effect of using the peer-to-peer network for transactions is that a transaction’s recipient can be notified that the transaction is *pending*, or is about to be confirmed. We’ll look at how this works a bit later.

### How do peers talk?

Let’s look at how the communication between two peers happens. We’ll look specifically at how Tom connects to Lisa and how they communicate across their communication channel, called a Transmission Control Protocol (TCP) connection ([figure 8.6](/book/grokking-bitcoin/chapter-8/ch08fig06)).

![Figure 8.6. Tom and Lisa communicate over the internet through a communication channel.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/08fig06_alt.jpg)

![TCP](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-02.jpg)

When you open a web page on [https://bitcoin.org](https://bitcoin.org), your web browser will make a TCP connection to bitcoin.org, download a web page through that connection, and display it to you.

Suppose Tom’s node knows about Lisa’s node. I’ll explain in “[Bootstrapping the network](/book/grokking-bitcoin/chapter-8/ch08lev1sec6)” how Tom learns about other nodes. For now, let’s assume he has the *IP address* and *port* of Lisa’s node. He now wants to connect to Lisa’s node to communicate with it. All computers on the internet have an Internet Protocol (IP) address, which is how one computer can send information to another. A computer program that listens for incoming connections must listen on a specific port number of its computer’s IP address. Lisa’s computer has the IP address 142.12.233.96 and runs a cookie token program that listens for incoming connections on port 8333.

Tom’s node connects to Lisa’s node through the IP address 142.12.233.96 and TCP port 8333. His node (computer program) starts by asking its operating system (OS) to initiate a connection to Lisa ([figure 8.7](/book/grokking-bitcoin/chapter-8/ch08fig07)). The OS sends a message to Lisa’s computer saying that Tom wants to talk to a computer program on Lisa’s port 8333. Her computer knows a program is listening on port 8333, so it sends back a “Sure, welcome” message. Tom’s computer acknowledges this by sending back an “OK, cool. Let’s talk ...” message.

![Figure 8.7. Tom’s computer program sets up a TCP connection to Lisa’s computer program. After this, they can send and receive data between each other.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/08fig07_alt.jpg)

![Port 8333](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-01.jpg)

Port 8333 is the default listening port in Bitcoin Core, the most widely used full node software.

The node software on Tom’s and Lisa’s computers wasn’t involved in this exchange—it was carried out by their OSs, such as Linux, Windows, or macOS. When the message sequence is finished, the OS hands the connection over to the node software. Lisa’s and Tom’s nodes can now speak freely to each other. Tom can send data to Lisa, and Lisa can send data to Tom over this communication channel, or *TCP connection*.

### The network protocol

Tom and Lisa can now send and receive data over a communication channel. But if Tom’s node speaks a language that Lisa’s node doesn’t understand, the communication won’t be meaningful ([figure 8.8](/book/grokking-bitcoin/chapter-8/ch08fig08)). The nodes must have a common language: a *protocol*.

![Figure 8.8. Lisa must be able to understand what Tom writes on the channel.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/08fig08_alt.jpg)

The cookie token network protocol defines a set of message types that are allowed. A typical message in the cookie token (well, Bitcoin) network is the `inv` message ([figure 8.9](/book/grokking-bitcoin/chapter-8/ch08fig09)).

![Figure 8.9. A typical network message](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/08fig09_alt.jpg)

![This is an abstraction](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-02.jpg)

Real network messages don’t look exactly like these; I provide an abstract view of the messages. The exact format of the network messages is out of the scope of this book.

A node uses the `inv`—short for *inventory*—message to inform other nodes about something it has. In [figure 8.9](/book/grokking-bitcoin/chapter-8/ch08fig09), Tom’s node informs Lisa’s node that Tom has three things to offer Lisa: two transactions and a block. The message contains an ID for each of these items.

#### John sends the transaction

Let’s follow a transaction through the network from start to end to see what network messages are being used. We’ll assume the peer-to-peer network is already set up. We’ll come back to how the network is *bootstrapped* later in this chapter.

In the “[Lightweight wallets](/book/grokking-bitcoin/chapter-6/ch06lev1sec3)” section of [chapter 6](/book/grokking-bitcoin/chapter-6/ch06), we said that wallets can connect to full nodes and get information about all block headers and transactions concerning them using bloom filters and merkle proofs ([figure 8.10](/book/grokking-bitcoin/chapter-8/ch08fig10)).

![Figure 8.10. Lightweight wallets communicate with nodes using the Bitcoin network protocol.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/08fig10_alt.jpg)

I didn’t go into detail then about how this communication works. It uses the same protocol the nodes use when they communicate with each other. The wallets and the full nodes (including miners) all speak the same “language.”

Suppose John wants to buy a cookie from the cafe. John’s wallet is connected to Tom’s node with a TCP connection. He scans the payment URI from the cafe’s wallet. John’s wallet creates and signs a transaction. You know the drill. Then it’s time to send the transaction to Tom’s node ([figure 8.11](/book/grokking-bitcoin/chapter-8/ch08fig11)).

![Figure 8.11. The transaction is sent to Tom’s node through a TCP connection.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/08fig11_alt.jpg)

This happens in a three-step process. John’s wallet doesn’t just send the transaction unsolicited: it first informs Tom’s node that there’s a transaction to be fetched ([figure 8.12](/book/grokking-bitcoin/chapter-8/ch08fig12)).

![Figure 8.12. Tom’s node is informed about John’s transaction so that Tom can fetch it.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/08fig12_alt.jpg)

The first message is an `inv` message, as described in the previous section. John’s wallet sends the `inv` to Tom’s full node. Tom checks if he already has the transaction. He doesn’t, because John’s wallet just created it and hasn’t sent it to anyone yet. Tom’s node wants to get this transaction, so he requests it with a `getdata` message that looks just like an `inv` message but with a different meaning: `getdata` means “I want this stuff,” whereas `inv` means “I have this stuff.”

John’s wallet receives the `getdata` message and sends a `tx` message containing the entire transaction to Tom’s node. Tom will verify the transaction and keep it. He’ll also relay this transaction to his network neighbors.

You might ask, “Why doesn’t John’s wallet send the entire transaction immediately? Why go through the hassle with `inv` and `getdata`?” This will become clear later, but it’s because nodes might already have the transaction; we save bandwidth by sending only transaction hashes instead of entire transactions.

#### Tom forwards the transaction

If the transaction is valid, Tom’s node will inform his neighbors about it ([figure 8.13](/book/grokking-bitcoin/chapter-8/ch08fig13)) using an `inv` message, just like John’s wallet did when it informed Tom’s node about the transaction.

![Figure 8.13. Tom forwards the transaction to his peers.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/08fig13_alt.jpg)

The process is the same for these three message exchanges as the one John used when he first sent the transaction to Tom ([figure 8.14](/book/grokking-bitcoin/chapter-8/ch08fig14)). Lisa, Qi, and Rashid will get an `inv` message from Tom.

![Figure 8.14. Tom’s node sends the transaction to Qi’s node using the familiar three-step process.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/08fig14_alt.jpg)

When Lisa, Qi, and Rashid have received the transaction, they too will inform their peers about it after they’ve verified it. Qi’s and Rashid’s nodes are a bit slower, so it takes them a while to verify the transaction; we’ll get back to them later.

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0263-01_alt.jpg)

Lisa was quick to verify the transaction, so she’ll be the first of the three to relay it. She already knows that she received the transaction from Tom, so she won’t inform Tom’s node with an `inv` message. But Lisa doesn’t know that Qi already has the transaction, and she doesn’t know if the cafe has it. She’ll send an `inv` to those two nodes. The cafe’s node will send back a `getdata` because it hasn’t yet seen this transaction. Qi’s node already has this transaction and won’t reply with anything ([figure 8.15](/book/grokking-bitcoin/chapter-8/ch08fig15)). She’ll remember that Lisa has it, though.

![Figure 8.15. Lisa’s node sends an inv to Qi’s node, but Qi’s node already has the transaction.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/08fig15_alt.jpg)

Qi has just finished verifying the transaction. She knows that Lisa’s node has it, so she doesn’t have to send an `inv` to Lisa’s node. But she doesn’t know if Rashid has it, so she sends an `inv` to Rashid’s node.

Rashid’s was the slowest node when verifying John’s transaction, so when it’s time for him to send an `inv` to his neighbors, he’s already received an `inv` from Qi’s node. And he also knows from earlier that Tom already has the transaction. He’ll just send an `inv` to the cafe’s node, which will ignore the `inv` because it already has the transaction.

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0264-01_alt.jpg)

#### The cafe’s lightweight wallet is notified

I said earlier that a good thing about letting transactions travel the peer-to-peer network is that the recipient wallet can get a quick notification of the pending transaction. Let’s explore this now.

The cafe’s full node has received the transaction and verified it. The cafe also has a lightweight wallet on a mobile phone that it uses to send and receive money. The cafe is concerned with security, so it configured this lightweight wallet to connect only the cafe’s own full node, its *trusted node* ([figure 8.16](/book/grokking-bitcoin/chapter-8/ch08fig16)).

![Figure 8.16. The cafe’s lightweight wallet has a TCP connection to its own full node.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/08fig16.jpg)

This common setup gives the cafe the complete security of a full node combined with the flexibility and mobility of a lightweight wallet. I described this setup in the “[Security of lightweight wallets](/book/grokking-bitcoin/chapter-6/ch06lev1sec5)” section in [chapter 6](/book/grokking-bitcoin/chapter-6/ch06).

The cafe’s full node has just verified John’s transaction. It now wants to inform its neighbors about this new transaction. It’s connected to Lisa’s node, Rashid’s node, and the cafe’s lightweight wallet. The full node already knows that Lisa’s and Rashid’s nodes have this transaction, so it doesn’t send an `inv` to those two nodes. The full node doesn’t know whether the wallet has the transaction, but it won’t immediately send an `inv` message to the wallet.

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0265-01.jpg)

The wallet is a lightweight wallet, which uses bloom filters, described in the “[Bloom filters obfuscate addresses](/book/grokking-bitcoin/chapter-6/ch06lev2sec4)” section in [chapter 6](/book/grokking-bitcoin/chapter-6/ch06). The full node will test the transaction against the bloom filter and, if it matches, send an `inv` message to the wallet. If there’s no match, it won’t send an `inv` message.

John’s transaction is for the cafe, so the bloom filter will match the transaction, and the full node will send an `inv`. The wallet will request the actual transaction using `getdata`, as [figure 8.17](/book/grokking-bitcoin/chapter-8/ch08fig17) shows.

![Figure 8.17. The cafe’s wallet gets John’s transaction from the cafe’s trusted node after the transaction is checked against the bloom filter.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/08fig17_alt.jpg)

The wallet has now received the transaction. It can show a message to the cafe owner that a transaction is pending. The cafe owner has a choice: trust that the transaction—a so-called *0-conf transaction*—will be confirmed eventually, or wait until the transaction is confirmed. If the cafe accepts the 0-conf transaction, then it trusts that John has paid a high enough transaction fee and that the transaction won’t be double spent.

This time, the cafe decides that it needs to wait until the transaction is included in a valid block. This brings us to the next phase: including the transaction in a block in the blockchain.

#### Including the transaction in a block

Let’s recall some of the miners in this system. At the end of “[Mitigating miner centralization](/book/grokking-bitcoin/chapter-7/ch07lev3sec8)” in [chapter 7](/book/grokking-bitcoin/chapter-7/ch07), there were 10 different miners; but let’s go back in time and pretend Qi, Tom, Lisa, and Rashid are the only miners in this system right now.

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0266-01_alt.jpg)

The transaction reached all these miners during transaction propagation. John’s wallet used to send the transaction via email to all miners. Now, he sends it to any of the full nodes, and it propagates across the entire peer-to-peer network. Miners can choose to include John’s transaction in the blocks they’re mining. Suppose the transaction includes a transaction fee so that some or all miners are willing to include it, and that Rashid is the next miner to find a valid proof of work for his block, which happens to contain John’s transaction ([figure 8.18](/book/grokking-bitcoin/chapter-8/ch08fig18)).

![Figure 8.18. Rashid’s block containing John’s transaction](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/08fig18_alt.jpg)

Rashid wants to get his block to the other miners as quickly as possible to minimize the risk of some other miner getting a block out before Rashid’s block.

![BIP130](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-01.jpg)

This process is defined in BIP130, which replaces an old block-propagation mechanism that used `inv` messages.

He creates a `headers` message and sends it to all his peers: Tom, the cafe, and Qi. Rashid’s peers will send back a `getdata` message, and Rashid will reply with the actual block. The message exchange between Rashid and Qi will look like the one in [figure 8.19](/book/grokking-bitcoin/chapter-8/ch08fig19).

![Figure 8.19. Rashid’s node sends Rashid’s block to Qi’s node.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/08fig19_alt.jpg)

The actual block is sent in a `block` message containing the full block.

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0267-01_alt.jpg)

Let’s continue the block propagation throughout the peer-to-peer network. Rashid has sent his block to Tom, the cafe, and Qi. Now, these three nodes will verify the block and, if it’s valid, send out `headers` messages to all their peers who might not already have it ([figure 8.20](/book/grokking-bitcoin/chapter-8/ch08fig20)).

![Figure 8.20. All but Lisa have the block. Tom, the cafe, and Qi send headers messages.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/08fig20_alt.jpg)

Qi and Tom happen to send their `headers` messages to each other at the same time. This isn’t a problem; because they both have the block, they’ll ignore the `headers` received from peers. Lisa will request the block from one of her peers just like Qi requested the block from Rashid.

This concludes the propagation of this block—almost. The lightweight wallets need to be informed about the block.

#### Notifying wallets

Tom’s node is connected to John’s wallet, so Tom sends a `headers` message to John. Likewise, the cafe’s full node sends a `headers` message to the cafe’s lightweight wallet. Tom’s and the cafe’s full nodes won’t test the block against the bloom filters in any way. They will send the `headers` message unconditionally, but the lightweight wallets won’t request the full blocks.

As you might recall from [chapter 6](/book/grokking-bitcoin/chapter-6/ch06), lightweight wallets don’t download the full blocks. Most of the time, John’s wallet is only interested in the block headers so it can verify the blockchain’s proof of work. But every now and then, transactions that are relevant to John’s wallet are in the blocks, and the wallet wants proof that those transactions are included in the block. To find out if there are any relevant transactions, he sends a `getdata` message to Tom, requesting a `merkleblock` message for the block.

John gets a `merkleblock` message containing the block header and a partial merkle tree connecting his transaction ID (txid) to the merkle root in the block header ([figure 8.21](/book/grokking-bitcoin/chapter-8/ch08fig21)).

![Figure 8.21. Tom sends a merkleblock containing a merkle proof that John’s transaction is in the block.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/08fig21_alt.jpg)

[Figure 8.22](/book/grokking-bitcoin/chapter-8/ch08fig22) gives a little repetition from [chapter 6](/book/grokking-bitcoin/chapter-6/ch06).

![Figure 8.22. The merkleblock message contains a block header and a partial merkle tree.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/08fig22_alt.jpg)

John’s wallet will verify that

- The block header is correct and has a valid proof of work.
- The merkle root in the header can be reconstructed using the partial merkle tree.
- The txid of John’s transaction is included in the partial merkle tree. He doesn’t care about the irrelevant transaction that’s used to obfuscate what belongs to John.

John’s wallet is now sure his transaction is contained in the new block. The wallet can display a message to John saying, “Your transaction has 1 confirmation.”

The cafe’s lightweight wallet will be notified the same way.

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0270-01.jpg)

Because the cafe’s wallet uses a trusted node, privacy isn’t much of an issue ([figure 8.23](/book/grokking-bitcoin/chapter-8/ch08fig23)). The wallet can use a big bloom filter to reduce the number of irrelevant transactions, which in turn will reduce mobile data traffic. The sparser the bloom filter, the less extra obfuscation traffic will be sent to the wallet.

![Figure 8.23. The cafe requests a merkle block from its trusted full node.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/08fig23_alt.jpg)

The cafe’s owner feels comfortable handing the cookie over to John now. John eats his cookie. The deal is done.

#### More confirmations

As time passes, more blocks will be mined by the miners. These blocks will all propagate the network and end up on every full node. The lightweight wallets will get merkle blocks to save bandwidth.

For each new block coming in, John’s transaction will be buried under more and more proof of work ([figure 8.24](/book/grokking-bitcoin/chapter-8/ch08fig24)). This makes John’s transaction harder and harder to double spend. For each new block, the transaction will get one more confirmation.

![Figure 8.24. As more blocks arrive, John’s transaction becomes safer and safer.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/08fig24_alt.jpg)

### Leaving the cookie token system

I don’t think the cookie token system will add any more to your understanding of Bitcoin. It’s time to let go of the cookie tokens and start talking solely about Bitcoin. We’ve developed the cookie token system to a point where there are no differences from Bitcoin. [Table 8.1](/book/grokking-bitcoin/chapter-8/ch08table01) shows the concept mapping table.

##### Table 8.1. The shared folder is ditched in favor of a peer-to-peer network.[(view table figure)](https://drek4537l1klr.cloudfront.net/rosenbaum/HighResolutionFigures/table_8-1.png)

| Cookie tokens | Bitcoin | Covered in |
| --- | --- | --- |
| 1 cookie token | 1 bitcoin | [Chapter 2](/book/grokking-bitcoin/chapter-2/ch02) |
| *The shared folder* | *The Bitcoin network* | *[Chapter 8](/book/grokking-bitcoin/chapter-8/ch08)* |

The last cookie token concept that differs from Bitcoin, the shared folder, has been eliminated. Let’s look at how it all happened, in [figure 8.25](/book/grokking-bitcoin/chapter-8/ch08fig25).

![Figure 8.25. The cookie token system’s evolution](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/08fig25_alt.jpg)

We’ll keep our friends at the office a while longer. John will probably have to buy a few more cookies, but he’ll use Bitcoin to do it.

#### Bitcoin at a glance

The Bitcoin peer-to-peer network is huge. As of this writing:

- There are about 10,000 publicly accessible full nodes.
- Bitcoin’s money supply is about 17,400,000 BTC.
- Each bitcoin is worth around $6,500.
- Bitcoin processes about 250,000 transactions per day.
- An estimate of 100,000 BTC, valued at $630 million, is moved daily.
- The total mining hashrate is about 50 Ehash/s, or 50 × 1018 hash/s. A typical desktop computer can do about 25 Mhash/s.
- The transaction fees paid each day total around 17 BTC. This averages to 6,800 satoshis per transaction, or about $0.40 per transaction.
- People in all corners of the world use Bitcoin to get around problems in their day-to-day lives.

![Where were we?](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-09.jpg)

This chapter is about Bitcoin’s peer-to-peer network. The first half of the chapter described the network in action after it’s been set up, as illustrated by [figure 8.26](/book/grokking-bitcoin/chapter-8/ch08fig26), repeated from [chapter 1](/book/grokking-bitcoin/chapter-1/ch01).

![Figure 8.26. The Bitcoin network distributes blocks (and transactions) to all participants.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/08fig26_alt.jpg)

The second half of this chapter will look at how a new node joins the network.

### Bootstrapping the network

The scenario in “[The network protocol](/book/grokking-bitcoin/chapter-8/ch08lev1sec4)” assumed that all nodes involved were already connected to each other. But how does a new node start? How would it find other nodes to connect to? How would it download the full blockchain from the genesis block, block 0, up to the latest block? How does it know what the latest block is?

Let’s sort it out.

Suppose Selma wants to start her own full node. This is how it would typically happen ([figure 8.27](/book/grokking-bitcoin/chapter-8/ch08fig27)):

- ***1*** Selma downloads, verifies, and starts the full node computer program.
- ***2*** The computer program connects to some nodes.
- ***3*** Selma’s node downloads blocks from her peers.
- ***4*** Selma’s node enters a normal mode of operation.

![Figure 8.27. Running a full node involves downloading and running the software, connecting to other nodes, downloading old blocks, and entering normal operation.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/08fig27_alt.jpg)

#### Step *1*—Run the software

Selma needs a computer program to run a full node. The most commonly used such program is Bitcoin Core. Several others are available, such as libbitcoin, bcoin, bitcoinj, and btcd. We’ll focus only on Bitcoin Core, but you’re encouraged to explore the others yourself.

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0275-01.jpg)

To download Bitcoin Core, Selma visits its web page, [https://bitcoincore.org](https://bitcoincore.org), and finds a download link there. But she encounters a potential problem: Selma isn’t sure the program she downloads is actually the version the developers behind Bitcoin Core released. Someone could have fooled Selma into downloading the program from bitconcore.org instead of bitcoincore.org, or someone might have hacked bitcoincore.org and replaced the downloadable files with alternative programs.

The Bitcoin Core team therefore signs all released versions of the program with a private key—let’s call it the *Bitcoin Core key*. They provide the signature in a downloadable file, named SHA256SUMS.asc. This file contains the hash value of the released Bitcoin Core software and a signature that signs the contents of the SHA256SUMS.asc file ([figure 8.28](/book/grokking-bitcoin/chapter-8/ch08fig28)).

![Figure 8.28. The Bitcoin Core team signs the released program with their private key.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/08fig28_alt.jpg)

Selma has downloaded both the program, in a file called bitcoin-0.17.0-x86_64-linux-gnu.tar.gz, and the signature file, SHA256SUMS.asc. To verify that the program is in fact signed by the Bitcoin Core private key, she needs to know the corresponding public key. But how can she know what this key is?

This is a hard problem. Remember when Lisa used to sign blocks with her private key? How would the full nodes verify that the blocks were actually signed by Lisa? They used multiple sources to fetch Lisa’s public key—for example, looking at the bulletin board at the entrance of the office, checking the company’s intranet, and asking colleagues. The same applies here; you shouldn’t trust a single source, but should use at least two different sources. The key that’s currently being used to sign Bitcoin Core releases is named

```
Wladimir J. van der Laan (Bitcoin Core binary release signing key)
<laanwj@gmail.com>
```

and has the following 160-bit SHA1 hash, called *fingerprint*:

```
01EA 5486 DE18 A882 D4C2 6845 90C8 019E 36C2 E964
```

This book can serve as *one* of Selma’s sources. She decides to

1. Get the fingerprint of the key from [https://bitcoincore.org](https://bitcoincore.org).
1. Verify the fingerprint with the *Grokking Bitcoin* book.
1. Verify the fingerprint with a friend.

![Where to get the key](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-02.jpg)

It doesn’t really matter where you get the actual public key, but it’s important to verify that its fingerprint is what you expect.

The fingerprints from the three sources match, so Selma downloads the public key from a *key server*. A key server is a computer on the internet that provides a repository of keys. Key servers are commonly used to download keys identified by the key’s fingerprint. Selma doesn’t trust the key server, so she needs to verify that the fingerprint of the downloaded key matches the expected fingerprint, which it does.

Now, when she has the Bitcoin Core public key, she can verify the signature of the SHA256SUMS.asc file ([figure 8.29](/book/grokking-bitcoin/chapter-8/ch08fig29)).

![Figure 8.29. Selma verifies the Bitcoin Core signature and that the hash in the signature file matches the hash of the actual program.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/08fig29_alt.jpg)

She uses the Bitcoin Core public key to verify the signature in the signature file. She must also verify that the program has the same hash value as stated in SHA256SUMS.asc. The signature is valid, and the hashes match, which means Selma can be sure the software she’s about to run is authentic.

Selma starts the program on her computer.

#### Step *2*—Connect to nodes

When Selma’s full node program starts, it isn’t connected to any other nodes. She’s not part of the Bitcoin network yet. In this step, the node will try to find peers to connect to.

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0277-01.jpg)

To connect to a peer, the full node needs the IP address and the TCP port for that peer. For example:

```
IP: 142.12.233.96 port: 8333
```

An IP address and port are often written as

```
142.12.233.96:8333
```

##### Finding initial peers

Where does Selma’s node find initial addresses of other peers? Several sources are available ([figure 8.30](/book/grokking-bitcoin/chapter-8/ch08fig30)):

- Configure the full node with custom peer addresses. Selma can get an address by asking a friend who’s running a full node.
- Use the Domain Name System (DNS) to look up initial peer addresses to connect to.
- Use hardcoded peer addresses in the full node program.

![Figure 8.30. Selma’s full node has three different types of sources to find initial peers.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/08fig30_alt.jpg)

**Selma’s node shouldn’t initially connect to just one node. If that single node is malicious, she’d have no way of knowing it. If you connect to multiple nodes initially, you can verify that they all send data consistent with each other. If not, one or more nodes are deliberately lying to you, or they themselves have been fooled**.

The default way of finding initial node addresses is to look them up in the DNS system. DNS is a global name lookup system, used to look up IP numbers from computer names. For example, when you visit [https://bitcoin.org](https://bitcoin.org) with your web browser, it will use DNS to look up the IP number of the name bitcoin.org. The Bitcoin Core software does the same. Names to look up are hardcoded into Bitcoin Core, just like the hardcoded IP addresses and ports. Several DNS seeds are coded into the software. A lookup of a DNS seed can return several IP addresses, and every new lookup might return a different set of IP addresses. The final, third option is used as a last resort.

Note from [figure 8.30](/book/grokking-bitcoin/chapter-8/ch08fig30) that DNS lookups don’t return port numbers. The other two methods of finding initial peers usually include one, but the DNS response can return only IP addresses. The nodes on these IP addresses are assumed to listen on the default port that Bitcoin Core listens on, which is 8333.

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0278-01.jpg)

##### Handshaking

Suppose Selma’s node chooses to connect to Qi’s node, 1.234.63.203:4567, and to Rashid’s node, 47.196.31.246:8333. Selma sets up a TCP connection to each of the two nodes and sends an initial message to both of them on the new TCP connections. Let’s look at how she talks to Qi’s node ([figure 8.31](/book/grokking-bitcoin/chapter-8/ch08fig31)).

![Figure 8.31. Selma exchanges a version message with Qi.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/08fig31_alt.jpg)

The exchange, called a *handshake*, starts with Selma, who sends a `version` message to Qi. The handshake is used to agree on which protocol version to use and tell each other what block heights they have. The `version` message contains a lot of information not shown in the figure, but the most essential stuff is there:

- *Protocol version*—The version of the network protocol, or “language,” that peers use to talk to each other. Selma and Qi will use version 70012 because that’s the highest version Qi will understand. Selma knows all protocol versions up to her own.
- *User agent*—This is shown as “software identification” in the figure because “user agent” is a bit cryptic. It’s used to hint to the other node what software you’re running, but it can be anything.
- *Height*—This is the height of the tip of the best chain the node has.

Other useful information in the `version` message includes

- *Services*—A list of features this node supports, such as bloom filtering used by lightweight clients.
- *My address*—The IP address and port of the node sending the `version` message. Without it, Qi wouldn’t know what address to connect to if she restarts and wants to reconnect to Selma’s node.

When Qi’s node receives Selma’s `version` message, Qi will reply with her own `version` message. She’ll also send a `verack` message immediately after the `version` message. The `verack` doesn’t contain any information; rather, it’s used to acknowledge to Selma that Qi has received the `version` message.

As soon as Selma’s node receives Qi’s `version` message, it will reply with a `verack` message back to Qi’s node. The handshake is done. Selma also goes through the same procedure with Rashid’s node.

##### Finding peers’ peers

When Selma’s node is connected to Rashid’s node, it will ask that node for other peer addresses to connect to. This way, Selma will be able to expand her set of peers ([figure 8.32](/book/grokking-bitcoin/chapter-8/ch08fig32)).

![Figure 8.32. Selma asks her peers for more peer addresses to connect to.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/08fig32_alt.jpg)

Selma is only connected to two peers: Qi’s node and Rashid’s node. But she thinks she needs more nodes to connect to. Being connected to only two nodes has some implications:

- Qi and Rashid can collude to hide transactions and blocks from Selma.
- Qi’s node may break, leaving Selma with only Rashid’s node. Rashid can then singlehandedly hide information from Selma.
- Both Qi’s and Rashid’s nodes may break, in which case Selma will be completely disconnected from the network until she connects to some other nodes via the initial peer-lookup mechanisms.

[Figure 8.33](/book/grokking-bitcoin/chapter-8/ch08fig33) shows how Selma asks Rashid for more peer addresses to connect to.

![Figure 8.33. Selma requests more peer addresses from Rashid’s node. He responds with a bunch.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/08fig33_alt.jpg)

![Initial nodes](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-02.jpg)

After getting an `addr` message, nodes disconnect from initial nodes (except manually configured ones) to avoid overloading them. They’re initial nodes for many other nodes.

Selma sends a `getaddr` message to a peer, Rashid’s node. Rashid responds with a set of IP addresses and TCP ports that Selma can use to connect to more peers. Rashid chooses which addresses to send to Selma, but it’s usually the addresses to which Rashid is already connected and possibly some that Rashid collected from his peers but didn’t use himself.

Selma will connect to any number of the received addresses to increase her *connectivity*. The more peers you’re connected to, the better your connectivity. A high degree of connectivity decreases the risk of missing out on information due to misbehaving peers. Also, information propagates more quickly if nodes have higher connectivity. A typical full node in Bitcoin has about 100 active connections at the same time. Only eight (by default) of those are *outbound connections*, meaning connections initiated by that node. The rest are *inbound connections* initiated by other nodes. Consequently, a full node that isn’t reachable on port 8333 from the internet—for example, due to a firewall—won’t get more than eight connections in total.

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0281-01.jpg)

#### Step *3*—Synchronize

Now that Selma is well-connected to, and part of, the Bitcoin network, it’s time for her to download and verify the full blockchain up to the latest block available. This process is called *synchronization*, *sync*, or *initial blockchain download*.

Selma has only a single block: the genesis block. The genesis block is hardcoded in the Bitcoin Core software, so all nodes have this block when they start.

She needs to download all historic blocks from her peers and verify them before she can verify newly created blocks. This is because she has no idea what the current unspent transaction output (UTXO) set looks like. To build the current UTXO set, she needs to start with an empty UTXO set, go through all historic blocks from block 0, and update the UTXO set with the information in the transactions in the blocks.

The process is as follows:

1. Download all historic block headers from one peer, and verify the proof of work.
1. Download all blocks on the strongest chain from multiple peers in parallel.

Selma selects one of her peers, Tom, to download all block headers from. [Figure 8.34](/book/grokking-bitcoin/chapter-8/ch08fig34) shows how Selma’s node downloads the block headers from Tom’s node.

![Figure 8.34. Selma downloads block headers from Tom by repeatedly sending a getheaders message with her latest block ID.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/08fig34_alt.jpg)

![Simplified](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-02.jpg)

The `getheaders` message contains a list of some block IDs from Selma’s blockchain so that Tom can find a common block they both have in case Tom doesn’t have Selma’s tip. Let’s not bother with that.

She sends a `getheaders` message containing Selma’s latest block ID, which happens to be the genesis block, block 0. Tom sends back a list of 2,000 block headers; each block header is 80 bytes. Selma verifies each header’s proof of work and requests a new batch of headers from Tom. This process continues until Selma receives a batch of fewer than 2,000 headers from Tom, which is a signal that he has no more headers to give her.

When Selma has received all the headers from Tom, she determines which branch is the strongest and starts downloading actual block data belonging to that branch from her peers. She can download block data from multiple peers at the same time to speed things up. [Figure 8.35](/book/grokking-bitcoin/chapter-8/ch08fig35) shows her communication with Rashid’s node.

![Figure 8.35. Selma downloads blocks from Rashid by repeatedly sending a getdata message with a list block IDs she wants the blocks for.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/08fig35_alt.jpg)

![Bigger batches](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-01.jpg)

In this example, Selma requests 3 blocks at a time, but in reality, Bitcoin Core would request a list of at most 16 blocks per batch.

It starts with Selma, who sends a `getdata` message to Rashid. This message specifies which blocks she wants to download from Rashid, who sends back the requested blocks in `block` messages, one by one. Note that Selma downloads only some of the blocks from Rashid. She also downloads blocks from Tom in parallel, which is why there are gaps in the sequence of requested blocks. The process repeats until Selma doesn’t want any more blocks from Rashid.

![Initial download](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-02.jpg)

The initial blockchain download, about 210 GB as of this writing, takes several hours, even days, depending on your hardware performance and internet speed.

As Selma downloads blocks, Rashid will probably receive more fresh blocks from his peers. Suppose he has received a new block by the time Selma has received the first 100 blocks from Rashid. Rashid will then send out a `headers` message to his peers, including Selma, as described in the section “[Including the transaction in a block](/book/grokking-bitcoin/chapter-8/ch08lev2sec4).” This way, Selma will be aware of all new blocks appearing during her initial synchronization and can later request them from any peer.

As Selma receives blocks, she verifies them, updates her UTXO set, and adds them to her own blockchain.

##### Verifying early blocks

The most time-consuming part of verifying a block is verifying the transaction signatures. If you know of any block ID that’s part of a valid blockchain, you can skip verifying the signatures of all blocks prior to and including this block ([figure 8.36](/book/grokking-bitcoin/chapter-8/ch08fig36)). This will greatly speed up the initial blockchain download up to that block.

![Figure 8.36. To speed up initial block download, signatures of reasonably old transactions won’t be verified.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/08fig36_alt.jpg)

Of course, other stuff, like verifying that no double spends occur or that the block rewards are correct, is still done. The syncing node must build its own UTXO set, so it must still go through all transactions to be able to update the UTXO set accordingly.

Bitcoin Core ships with a preconfigured block ID of a block from some weeks back from the release date. For Bitcoin Core 0.17.0, that block is

```
height: 534292
hash: 0000000000000000002e63058c023a9a1de233554f28c7b21380b6c9003f36a8
```

This is about 10,000 blocks back in the blockchain at release date. This is, of course, a configuration parameter, and the aforementioned block is just a default reasonable value. Selma could have changed this when starting her node, or she could have verified with friends and other sources she trusts that this block is in fact representing an “all valid transactions blockchain.” She could also have disabled the feature to verify all transaction signatures since block 0.

After a while, Selma is finally on the same page as the other nodes and ready to enter the normal mode of operation.

##### Step *4*—Normal operation

This step is easy because we already discussed it in “[The network protocol](/book/grokking-bitcoin/chapter-8/ch08lev1sec4).” Selma enters the normal mode of operation. From now on, she’ll participate in block propagation and transaction propagation, and verify every transaction and block coming in ([figure 8.37](/book/grokking-bitcoin/chapter-8/ch08fig37)).

![Figure 8.37. Selma is finally an active part of the Bitcoin peer-to-peer network.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/08fig37_alt.jpg)

Selma is now running a full-blown full node.

### Running your own full node

##### Warning!

This section will walk you through setting up your own Bitcoin Core full node on a Linux OS. It’s intended for readers comfortable with the Linux OS and command line.

##### Online instructions

More detailed instructions for all major OSs are available at web resource 18 in [appendix C](../Text/kindle_split_023.html#app03).

You’ve seen how a Bitcoin full node is downloaded, started, and synchronized in theory. This section will help you install your own full node.

This section requires that you

- Have a computer with at least 2 GB of RAM running a Linux OS.
- Have lots of available disk space. As of this writing, about 210 GB is needed.
**
**3
**

**

- Have an internet connection without a limited data plan.
- Know how to start and use a command-line terminal.

If you don’t have a Linux OS, you can still use these instructions; but you’ll have to install the version of Bitcoin Core that’s appropriate for your system, and the commands will look different. I suggest that you visit web resource 18 in [appendix C](/book/grokking-bitcoin/appendix-c/app03) to get up-to-date instructions for your non-Linux OS.

The general process for getting your own node running is as follows:

1. Download Bitcoin Core from [https://bitcoincore.org/en/download](https://bitcoincore.org/en/download).
1. Verify the software.
1. Unpack and start.
1. Wait for the initial blockchain download to finish.

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0286-01.jpg)

#### Downloading Bitcoin Core

To run your own full Bitcoin node, you need the software program to run. In this example, you’ll download Bitcoin Core from web resource 19 in [appendix C](/book/grokking-bitcoin/appendix-c/app03). As of this writing, the latest version of Bitcoin Core is 0.17.0. Let’s download it:

```bash
$ wget https://bitcoincore.org/bin/bitcoin-core-0.17.0/\
    bitcoin-0.17.0-x86_64-linux-gnu.tar.gz
```

As the filename bitcoin-0.17.0-x86_64-linux-gnu.tar.gz indicates, the command downloads version 0.17.0 for 64-bit (x86_64) Linux (linux-gnu). By the time you read this, new versions of Bitcoin Core will probably have been released. Consult web resource 19 to get the latest version of Bitcoin Core. Also, if you use another OS or computer architecture, please select the file that’s right for you.

#### Verifying the software

##### Warning!

This section is hard and requires a fair amount of work on the command line. If you just want to install and run the Bitcoin Core software for experimental purposes, you can skip this section and jump to “[Unpacking and starting](#ch08lev2sec14).” If you aren’t using it for experimental purposes, please understand the risks explained earlier in this chapter in “[Step 1—Run the software](#ch08lev2sec9)” before skipping this step.

This section will show you how to verify that the downloaded .tar.gz file hasn’t been tampered with in any way. This file is digitally signed by the Bitcoin Core team’s private key. The verification process involves the following steps:

1. Download the signature file.
1. Verify that the hash of the .tar.gz file matches the hash in the message part of the signature file.
1. Download the Bitcoin Core team’s public key.
1. Install the public key as trusted on your computer.
1. Verify the signature.

Let’s get started.

##### Downloading the signature file

To verify that your downloaded Bitcoin Core package is actually from the Bitcoin Core team, you need to download the signature file named SHA256SUMS.asc. [Figure 8.38](/book/grokking-bitcoin/chapter-8/ch08fig38), repeated from “[Step 1—Run the software](/book/grokking-bitcoin/chapter-8/ch08lev2sec9),” explains how the SHA256SUMS.asc file is designed.

![Figure 8.38. The Bitcoin Core team signs the released program with their private key.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/08fig38_alt.jpg)

Download the signature file SHA256SUMS.asc from the same server you downloaded the program from:

```bash
$ wget https://bitcoincore.org/bin/bitcoin-core-0.17.0/SHA256SUMS.asc
```

This file will be used to verify that the downloaded .tar.gz file is signed by the Bitcoin Core team. Note that this file is for version 0.17.0 only. If you use another version of Bitcoin Core, please select the correct signature file at web resource 19.

The following listing shows what the contents of this file look like (the actual hashes have been shortened):

```
-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA256

1e43...35ed  bitcoin-0.17.0-aarch64-linux-gnu.tar.gz
a4ff...7585  bitcoin-0.17.0-arm-linux-gnueabihf.tar.gz
967a...f1b7  bitcoin-0.17.0-i686-pc-linux-gnu.tar.gz
e421...5d61  bitcoin-0.17.0-osx64.tar.gz
0aea...ac58  bitcoin-0.17.0-osx.dmg
98ef...785e  bitcoin-0.17.0.tar.gz
1f40...8ee7  bitcoin-0.17.0-win32-setup.exe
402f...730d  bitcoin-0.17.0-win32.zip
b37f...0b1a  bitcoin-0.17.0-win64-setup.exe
d631...0799  bitcoin-0.17.0-win64.zip
9d6b...5a4f  bitcoin-0.17.0-x86_64-linux-gnu.tar.gz
-----BEGIN PGP SIGNATURE-----
Version: GnuPG v1.4.11 (GNU/Linux)

iQIcBAEBCAAGBQJbtIOFAAoJEJDIAZ42wulk5aQP/0tQp+EwFQPtSJgtmjYucw8L
SskGHj76SviCBSfCJ0LKjBdnQ4nbrIBsSuw0oKYLVN6OIFIp6hvNSfxin1S8bipo
hCLX8xB0FuG4jVFHAqo8PKmF1XeB7ulfOkYg+qF3VR/qpkrjzQJ6S/nnrgc4bZu+
lXzyUBH+NNqqlMeTRzYW92g0zGMexig/ZEMqigMckTiFDrTUGkQjJGzwlIy73fXI
LZ/KtZYDUw82roZINXlp4oNHDQb8qT5R1L7ACvqmWixbq49Yqgt+MAL1NG5hvCSW
jiVX4fasHUJLlvVbmCH2L42Z+W24VCWYiy691XkZ2D0+bmllz0APMSPtgVEWDFEe
wcUeLXbFGkMtN1EDCLctQ6/DxYk3EM2Ffxkw3o5ehTSD6LczqNC7wG+ysPCjkV1P
O4oT4AyRSm/sP/o4qxvx/cpiRcu1BQU5qgIJDO+sPmCKzPn7wEG7vBoZGOeybxCS
UUPEOSGan1Elc0Jv4/bvbJ0XLVJPVC0AHk1dDE9zg/0PXof9lcFzGffzFBI+WRT3
zf1rBPKqrmQ3hHpybg34WCVmsvG94Zodp/hiJ3mGsxjqrOhCJO3PByk/F5LOyHtP
wjWPoicI2pRin2Xl/YTVAyeqex519XAnYCSDEXRpe+W4BdzFoOJwm5S6eW8Q+wkN
UtaRwoYjFfUsohMZ3Lbt
=H8c2
-----END PGP SIGNATURE-----
```

The signed message in the upper part of the file lists several files along with their respective SHA256 hashes. The listed files are installation packages for all OSs and architectures for which Bitcoin Core is released. The lower part of the file is the signature of the message in the upper part. The signature commits to the entire message and thus to all the hashes and files listed in the message.

##### Verifying the hash of the downloaded file

The file you downloaded is named bitcoin-0.17.0-x86_64-linux-gnu.tar.gz so you expect that the SHA256 hash of that file matches `9d6b...5a4f` exactly. Let’s check:

```bash
$ sha256sum bitcoin-0.17.0-x86_64-linux-gnu.tar.gz
9d6b472dc2aceedb1a974b93a3003a81b7e0265963bd2aa0acdcb1759
8215a4f  bitcoin-0.17.0-x86_64-linux-gnu.tar.gz
```

This command calculates the SHA256 hash of your downloaded file. It does indeed match the hash in the SHA256SUMS.asc file. If they don’t match, then something is wrong, and you should halt the installation and investigate.

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0289-01.jpg)

##### Getting the Bitcoin Core signing key

To verify that the signature in the signature file was done using the Bitcoin Core signing key, you need the corresponding public key. As noted in “[Step 1—Run the software](/book/grokking-bitcoin/chapter-8/ch08lev2sec9),” you should convince yourself about what fingerprint the Bitcoin Core key has and then download that key from any source.

You could, for example,

- Get the fingerprint of the Bitcoin Core team’s key from [https://bitcoincore.org](https://bitcoincore.org), the official website of the Bitcoin Core team.
- Consult the book *Grokking Bitcoin* to verify the fingerprint.
- Verify the fingerprint with a friend.

Start by finding the Bitcoin Core team’s public key fingerprint on their website. You find the following fingerprint on the downloads page:

```
01EA5486DE18A882D4C2684590C8019E36C2E964
```

Now, consult the book *Grokking Bitcoin* to check if the fingerprint in that book matches the fingerprint from [https://bitcoincore.org](https://bitcoincore.org). Look in the “[Step 1—Run the software](/book/grokking-bitcoin/chapter-8/ch08lev2sec9)” section of [chapter 8](/book/grokking-bitcoin/chapter-8/ch08) of that book. It says

```
01EA 5486 DE18 A882 D4C2  6845 90C8 019E 36C2 E964
```

This is the same fingerprint (although formatted slightly differently). The book and the website [https://bitcoincore.org](https://bitcoincore.org) both claim that this key belongs to the Bitcoin Core team. Let’s not settle for that. You’ll also call a friend you trust and have her read the fingerprint to you:

**You:** “Hello, Donna! What’s the fingerprint of the current Bitcoin Core signing key?”

**Donna:** “Hi! I verified that key myself a few months ago, and I know the fingerprint is `01EA 5486 DE18 A882 D4C2 6845 90C8 019E 36C2 E964`.”

**You:** “Thank you, it matches mine. Goodbye!”

**Donna:** “You’re welcome. Goodbye!”

Donna’s statement further strengthens your trust in this key. You think you’ve collected enough evidence that this is, in fact, the correct key.

Let’s start downloading the key. To do this, you can use a tool called gpg, which stands for GnuPG, which in turn stands for Gnu Privacy Guard. This program conforms to a standard called OpenPGP (Pretty Good Privacy). This standard specifies how keys can be exchanged and how to do encryption and digital signatures in an interoperable way.

GnuPG is available on most Linux computers by default. To download a public key with a certain fingerprint, you run the following `gpg` command:

```bash
$ gpg --recv-keys 01EA5486DE18A882D4C2684590C8019E36C2E964
gpg: key 90C8019E36C2E964: public key "Wladimir J. van der Laan (Bitcoin
Core binary release signing key) <laanwj@gmail.com>" imported
gpg: no ultimately trusted keys found
gpg: Total number processed: 1
gpg:               imported: 1
```

Depending on the version of gpg you use, the output can vary. This command downloads the public key from any available key server and verifies that the downloaded public key in fact has the fingerprint that you requested. The owner of this key is “Wladimir J. van der Laan (Bitcoin Core binary release signing key).”

The prior command downloads the key into gpg and adds it to your list of known keys. But the output of this command mentions “no ultimately trusted keys found.” This means this key isn’t signed by any key that you trust. You’ve only imported the key. In gpg, keys can sign other keys to certify that the signed key is legit.

##### Signing the public key as trusted on your computer

You’ve verified that the key belongs to the Bitcoin Core team and installed that key onto your system using gpg.

You’ll now sign that key with a private key that you own. You do this to remember this key as trusted. The Bitcoin Core team will probably release new versions of Bitcoin Core in the future. If GnuPG remembers this public key as trusted, you won’t have to go through all these key-verification steps again when you upgrade.

The process is as follows:

1. Create a key of your own.
1. Sign the Bitcoin Core public key with your own private key.

GnuPG lets you create a key of your own with the following command:

```bash
$ gpg --gen-key
gpg (GnuPG) 2.1.18; Copyright (C) 2017 Free Software Foundation, Inc.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Note: Use "gpg --full-generate-key" for a full featured key generation
dialog.
GnuPG needs to construct a user ID to identify your key.
```

GnuPG will ask for your name and email address. Answer these questions; they’ll be used to identify your key:

```
Real name: Kalle Rosenbaum
Email address: kalle@example.com
You selected this USER-ID:
    "Kalle Rosenbaum <kalle@example.com>"

Change (N)ame, (E)mail, or (O)kay/(Q)uit?
```

Continue by pressing O (capital letter “oh”). You then need to select a password with which to encrypt your private key. Choose a password, and make sure you remember it.

Key generation might take a while, because it takes time to generate good random numbers for your key. When it’s finished, you should see output like this:

```
public and secret key created and signed.

pub   rsa2048 2018-04-27 [SC] [expires: 2020-04-26]
      B8C0D19BB7E17E5CEC6D69D487C0AC3FEDA7E796
      B8C0D19BB7E17E5CEC6D69D487C0AC3FEDA7E796
uid                    Kalle Rosenbaum <kalle@example.com>
sub   rsa2048 2018-04-27 [E] [expires: 2020-04-26]
```

**You now have a key of your own that you’ll use to sign keys that you trust. Let’s sign the Bitcoin Core team key:**

```bash
$ gpg --sign-key 01EA5486DE18A882D4C2684590C8019E36C2E964
pub  rsa4096/90C8019E36C2E964
     created: 2015-06-24 expires: 2019-02-14 usage: SC
     trust: unknown      validity: unknown
[ unknown] (1). Wladimir J. van der Laan (Bitcoin Core binary release
signing key) <laanwj@gmail.com>
pub  rsa4096/90C8019E36C2E964
     created: 2015-06-24  expires: 2019-02-14 usage: SC
     trust: unknown       validity: unknown
 Primary key fingerprint: 01EA 5486 DE18 A882 D4C2 6845 90C8 019E 36C2
E964
     Wladimir J. van der Laan (Bitcoin Core binary release signing key)
<laanwj@gmail.com>
This key is due to expire on 2019-02-14.
Are you sure that you want to sign this key with your
key "Kalle Rosenbaum <kalle@example.com>" (8DC7D3846BA6AB5E)

Really sign? (y/N)
```

Enter `y`. You’ll be prompted for your private key password. Enter it, and press Enter. The Bitcoin Core key should now be regarded as trusted by gpg. This will simplify the process when you upgrade your node in the future.

Let’s look at your newly signed key:

```bash
$ gpg --list-keys 01EA5486DE18A882D4C2684590C8019E36C2E964
pub   rsa4096 2015-06-24 [SC] [expires: 2019-02-14]
      01EA5486DE18A882D4C2684590C8019E36C2E964
uid         [  full  ] Wladimir J. van der Laan (Bitcoin Core binary release
signing key) <laanwj@gmail.com>
```

The word to look for is `full` in square brackets. This means gpg, and you, fully trust this key.

##### Verifying the signature

It’s time to verify the signature of the SHA256SUMS.asc file:

```bash
$ gpg --verify SHA256SUMS.asc
gpg: Signature made Wed 03 Oct 2018 10:53:25 AM CEST
gpg:                using RSA key 90C8019E36C2E964
gpg: Good signature from "Wladimir J. van der Laan (Bitcoin Core binary
release signing key) <laanwj@gmail.com>" [full]
```

It says that the signature is `Good` and that it’s signed with a key that you fully trust, `[full]`.

To summarize, you’ve done the following:

1. Downloaded Bitcoin Core and the signature file
1. Verified that the hash of the .tar.gz file matches the stated hash in SHA256SUMS.asc
1. Downloaded a public key and verified that it belongs to Bitcoin Core
1. Signed that key with your own private key so GnuPG and you remember that the Bitcoin Core key is legit
1. Verified the signature of the SHA256SUMS.asc file

When you later upgrade the program, you can skip several of these steps. The process will then be

1. Download Bitcoin Core and the signature file.
1. Verify that the hash of the .tar.gz file matches the stated hash in SHA256SUMS.asc.
1. Verify the signature of the SHA256SUMS.asc file.

#### Unpacking and starting

Let’s unpack the software:

```bash
$ tar -zxvf bitcoin-0.17.0-x86_64-linux-gnu.tar.gz
```

This will create a directory called bitcoin-0.17.0. Go into the directory bitcoin-0.17.0/bin, and have a look:

```bash
$ cd bitcoin-0.17.0/bin
$ ls
bitcoin-cli  bitcoind  bitcoin-qt  bitcoin-tx  test_bitcoin
```

Here you have several executable programs:

- bitcoin-cli is a program you can use to extract information about the node you’re running as well as manage a built-in wallet that’s shipped with Bitcoin Core.
- bitcoind is the program to use if you want to run the node in the background without a graphical user interface (GUI).
- bitcoin-qt is the program to run if you want a GUI for your node. This is mainly useful if you use the built-in wallet.
- bitcoin-tx is a small utility program to create and modify Bitcoin transactions.
- test_bitcoin lets you test run a test suite.

In this tutorial, you’ll run bitcoind, which stands for “Bitcoin daemon.” In UNIX systems such as Linux, the word *daemon* is used for computer programs that run in the background.

Let’s start the Bitcoin Core daemon in the background and see what happens:

```bash
$ ./bitcoind -daemon
Bitcoin server starting
```

This starts your node. It will automatically begin connecting to peers and downloading the blockchain for you.

#### Initial blockchain download

This process will take time. Depending on your internet connection, processor, and disk, it can vary from several days down to a few hours.

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0295-01.jpg)

You can use the bitcoin-cli program to query the running node about the download progress, as in the following:

```bash
$ ./bitcoin-cli getblockchaininfo
{
  "chain": "main",
  "blocks": 207546,
  "headers": 549398,
  "bestblockhash":
"00000000000003a6a5f2f360f02a3b8e4c214d27bd8e079a70f5fb630a0817c5",
  "difficulty": 3304356.392990344,
  "mediantime": 1352672365,
  "verificationprogress": 0.0249296506976196,
  "initialblockdownload": true,
  "chainwork":
"0000000000000000000000000000000000000000000000202ad90c17ec6ea33c",
  "size_on_disk": 11945130882,
  "pruned": false,
  "softforks": [
    {
      "id": "bip34",
      "version": 2,
      "reject": {
        "status": false
      }
    },
    {
      "id": "bip66",
      "version": 3,
      "reject": {
        "status": false
      }
    },
    {
      "id": "bip65",
      "version": 4,
      "reject": {
        "status": false
      }
    }
  ],
 "bip9_softforks": {
    "csv": {
      "status": "defined",
      "startTime": 1462060800,
      "timeout": 1493596800,
      "since": 0
    },
    "segwit": {
      "status": "defined",
      "startTime": 1479168000,
      "timeout": 1510704000,
      "since": 0
    }
  },
  "warnings": ""
}
```

This command shows a lot of information about the blockchain. Note that blocks have been downloaded and verified up to height 207546. Bitcoin Core will download block headers prior to the full blocks to verify proof of work. This node has downloaded headers up to height 549398, which are all the headers there are at this time. Another interesting thing is the `initialblockdownload` field, which will remain `true` until the initial block download is finished.

Keep this daemon running. You’ll get back to it in [appendix A](/book/grokking-bitcoin/appendix-a/app01), where I’ll give you a small tutorial on how to use bitcoin-cli to examine the blockchain and use your built-in wallet.

If you want to stop the node, issue the following command:

```bash
$ ./bitcoin-cli stop
```

You can start the node again whenever you like, and the node will begin where it left off.

### Recap

We’ve replaced the last central point of authority, the shared folder, with a peer-to-peer network. In a peer-to-peer network, the full nodes communicate directly with each other. Each node is connected to several (potentially hundreds of) other nodes. This makes it extremely hard to prevent blocks and transactions from propagating the network.

This chapter had two main parts:

- How transactions and blocks flow through the network
- How new nodes join the network

#### Part 1—Following a transaction

In the first part of the chapter, we followed a transaction through the system. It started with John buying a cookie. His transaction was propagated across the peer-to-peer network and to the cafe’s wallet.

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0297-01_alt.jpg)

The cafe will almost immediately see that a transaction is incoming, but it’s not yet confirmed. The next stage is to mine the block. Rashid is the lucky miner who finds the next block containing John’s transaction.

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0297-02_alt.jpg)

Rashid sends out the block to his peers, who will relay it to their peers and so on until the block has reached the entire network. Part of this propagation includes sending the block to lightweight wallets. These lightweight wallets will request `merkleblock` messages from the full node so they don’t have to download the full block.

#### Part 2—Joining the network

Starting a new node involves fours steps:

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0298-01_alt.jpg)

- ***1*** Download and verify, for example, the Bitcoin Core software. Then start it.
- ***2*** Connect to other nodes.
- ***3*** Download historic blocks.
- ***4*** Enter normal operation.

#### System changes

The table of concept mappings between the cookie token system and Bitcoin has become tiny ([table 8.2](/book/grokking-bitcoin/chapter-8/ch08table02)).

##### Table 8.2. The shared folder has been ditched in favor of a peer-to-peer network.[(view table figure)](https://drek4537l1klr.cloudfront.net/rosenbaum/HighResolutionFigures/table_8-2.png)

| Cookie tokens | Bitcoin | Covered in |
| --- | --- | --- |
| 1 cookie token | 1 bitcoin | [Chapter 2](/book/grokking-bitcoin/chapter-2/ch02) |

Given that there are no longer any technical differences between the cookie token system and the Bitcoin system, we’ll drop the cookie tokens and work only with Bitcoin from now on.

This will be the final release of the cookie token system. Another, much more widely used system, Bitcoin, has taken the world by storm, and we’ve decided to ditch the cookie token project. Enjoy the last version ([table 8.3](/book/grokking-bitcoin/chapter-8/ch08table03)).

##### Table 8.3. Release notes, cookie tokens 8.0[(view table figure)](https://drek4537l1klr.cloudfront.net/rosenbaum/HighResolutionFigures/table_8-3.png)

| Version | Feature | How |
| --- | --- | --- |
|  | Censorship-resistant; for real this time | Shared folder replaced by a peer-to-peer network |
| Transaction broadcasting | Transactions broadcast to miners and others using the peer-to-peer network |  |
| 7.0 | Censorship-resistant | Multiple miners, “Lisas,” enabled by proof of work |
| Anyone can join the mining race | Automatic difficulty adjustments |  |
| 6.0 | Prevent Lisa from deleting transactions | Signed blocks in a blockchain |
| Fully validating nodes | Download and verify the entire blockchain. |  |
| Lightweight wallet saves data traffic | Bloom filters and merkle proofs |  |

### Exercises

#### Warm up

**[8.1](/book/grokking-bitcoin/appendix-b/app02qa9q0a1)**

Why is the shared folder a bad idea?

**[8.2](/book/grokking-bitcoin/appendix-b/app02qa9q0a2)**

What does it mean to relay a transaction or a block?

**[8.3](/book/grokking-bitcoin/appendix-b/app02qa9q0a3)**

What are `inv` messages used for?

**[8.4](/book/grokking-bitcoin/appendix-b/app02qa9q0a4)**

How does the full node decide what transactions to send to lightweight wallets?

**[8.5](/book/grokking-bitcoin/appendix-b/app02qa9q0a5)**

How does a node notify a lightweight wallet about an incoming pending transaction?

**[8.6](/book/grokking-bitcoin/appendix-b/app02qa9q0a6)**

Blocks aren’t sent in full to lightweight wallets. What part of the block is always sent to the wallet?

**[8.7](/book/grokking-bitcoin/appendix-b/app02qa9q0a7)**

Why does the cafe send a very big bloom filter to its trusted node?

**[8.8](/book/grokking-bitcoin/appendix-b/app02qa9q0a8)**

What would a security-conscious person do after downloading Bitcoin Core but before starting the software?

**[8.9](/book/grokking-bitcoin/appendix-b/app02qa9q0a9)**

What types of sources for peer addresses are available to a newly started node?

**[8.10](/book/grokking-bitcoin/appendix-b/app02qa9q0a10)**

How would a full node know if any newly created blocks are available for download when it’s finished syncing?

**[8.11](/book/grokking-bitcoin/appendix-b/app02qa9q0a11)**

The Bitcoin peer-to-peer network consists of the following nodes:

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0300-01.jpg)

Which node owners do you need to threaten to prevent Lisa from getting any blocks but those she creates herself?

#### Dig in

**[8.12](/book/grokking-bitcoin/appendix-b/app02qa9q0a12)**

Suppose Qi just received two transactions with transaction IDs TXID1 and TXID2. She now wants to inform Rashid about these new transactions. She doesn’t know if Rashid already knows about them. What does she do?

**[8.13](/book/grokking-bitcoin/appendix-b/app02qa9q0a13)**

Suppose you’re running a full node and experience a power outage for 18 minutes. When power comes back, you start your node again. During those 18 minutes, two blocks, B1 and B2, have been created. Your latest block is B0. What will your node do after reconnecting to the network? For simplicity, assume that no new blocks are found during synchronization, and that you have only one peer. Use this table of message types to fill out the following template:

| Type | Data | Purpose |
| --- | --- | --- |
| block | Full block | Sends a block to a peer |
| getheaders | Block ID | Asks a peer for subsequent block headers after the given block ID |
| getdata | txids or block IDs | Requests data from a peer |
| headers | List of headers | Sends a list of headers to a peer |

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0301-01_alt.jpg)

### Summary

- The peer-to-peer network makes blocks censorship-resistant.
- A node connects to multiple peers to reduce their vulnerability for information hiding.
- The Bitcoin network protocol is the “language” nodes speak to communicate.
- Transactions are broadcast on the Bitcoin peer-to-peer network to reach both miners and the recipient of the money early.
- New nodes synchronize with the Bitcoin network to get up to date with the other nodes. This takes hours or days.
- Nodes don’t need to stay online 24/7. They can drop out and come back and sync up the latest stuff.
- Signature verification can be skipped for older blocks to speed up initial synchronization. This is useful if you know a specific block is valid.
