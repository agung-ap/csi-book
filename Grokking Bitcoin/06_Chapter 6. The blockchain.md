# Chapter 6. The blockchain

### **This chapter covers**

- Improving spreadsheet security
- Lightweight (SPV) wallets
- Reducing wallet bandwidth requirements

In [chapter 5](/book/grokking-bitcoin/chapter-5/ch05), we discussed transactions that let anyone verify all transactions in the spreadsheet. But there are still things verifiers can’t verify—that Lisa doesn’t remove or censor transactions. We’ll handle censorship resistance in [chapters 7](/book/grokking-bitcoin/chapter-7/ch07) and [8](/book/grokking-bitcoin/chapter-8/ch08). This chapter examines how to make it impossible for Lisa to remove or replace transactions without also making it obvious that she’s tampered with the transaction history.

Lisa does this by replacing the spreadsheet with a *blockchain* ([figure 6.1](/book/grokking-bitcoin/chapter-6/ch06fig01)). The blockchain contains transactions that are secured from tampering through hashing and signing the set of transactions in a clever way. This technique makes it easy to provide cryptographic proof of fraud if Lisa deletes or replaces transactions. All verifiers keep their own copies of the blockchain, and they can fully verify it to ensure that Lisa doesn’t remove already-confirmed transactions.

![Figure 6.1. The Bitcoin blockchain](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/06fig01_alt.jpg)

This chapter also introduces a lightweight wallet, or *simplified payment verification* (SPV) wallet, that will defer blockchain verification to someone else—a full node—to save bandwidth and storage space. This is possible thanks to the blockchain, but it comes at a cost.

### Lisa can delete transactions

As noted several times before, Lisa can delete transactions. For example, Lisa could buy a cookie from the cafe, eat it, and delete the transaction. Of course, she wouldn’t do this because she’s the most trustworthy person on earth, but not all her coworkers know or believe this. Suppose she does indeed delete a transaction, as [figure 6.2](/book/grokking-bitcoin/chapter-6/ch06fig02) shows.

![Figure 6.2. Lisa buys a cookie and then reverts the transaction. She just stole a cookie from the cafe! The cafe and Lisa now have different UTXO sets.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/06fig02_alt.jpg)

Later, when the cafe notices that the transaction has disappeared, it can’t prove that Lisa’s transaction was ever in the spreadsheet. And Lisa can’t prove it wasn’t there. This situation is troublesome. If it’s word against word, you’re in for a long and costly dispute, possibly involving lawyers, police, Acme Insurances, and private detectives.

How can you prove whether a transaction was confirmed? Lisa needs a way to publish transactions and their ordering such that she can’t tamper with them.

### Building the blockchain

Lisa can delete transactions because no one can prove that the list of all transactions has changed. What if we could change the system to make it provable that she’s fiddled with history?

Among your coworkers, some developers suggest getting rid of the cookie token spreadsheet and replacing it with a blockchain ([figure 6.3](/book/grokking-bitcoin/chapter-6/ch06fig03)).

![Figure 6.3. A blockchain is a chain of blocks. These blocks contain transactions, and each block references its predecessor.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/06fig03_alt.jpg)

![Blockchain length](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-01.jpg)

The Bitcoin blockchain contains hundreds of thousands of blocks. At the time of writing, the chain tip had height 550,836.

In the blockchain, each block references the previous block and has an implicit *height* that says how far it is from the first block. The first block has height 0, the second block has height 1, and so on. In [figure 6.3](/book/grokking-bitcoin/chapter-6/ch06fig03), the *chain tip*, or last block, of this blockchain is at height 7, meaning the blockchain is 8 blocks long. Every 10 minutes, Lisa puts recent unconfirmed transactions into a new block and makes it available to everybody who’s interested.

The blockchain stores transactions just like the spreadsheet did. But each block also contains a *block header* to protect the integrity of the contained transactions and the blockchain before it. Let’s say the blockchain in [figure 6.3](/book/grokking-bitcoin/chapter-6/ch06fig03) has grown to contain 20 blocks, so the chain tip is at height 19. [Figure 6.4](/book/grokking-bitcoin/chapter-6/ch06fig04) zooms in on the last few blocks of the blockchain.

![Figure 6.4. Each block header protects the integrity of the contained transactions and the blockchain before the block.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/06fig04_alt.jpg)

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0166-01.jpg)

Each block contains one or more transactions and a block header. The block header consists of

- The double SHA256 hash of the previous block’s header
- The combined hash of the transactions in the block, the *merkle root*
- A timestamp of the block’s creation time
- Lisa’s signature of the block header

The hash of a block header is an identifier for the block, just as a transaction hash, or transaction ID (txid), is an identifier for a transaction. I’ll sometimes refer to the block header hash as the *block ID*.

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0167-01.jpg)

The leftmost part of the block header is the block ID of the previous block in the blockchain. This is why it’s called a block*chain*. The previous block-header hashes form a chain of block headers.

The second part from the left is the combined hash of the transactions. This is the *merkle root* of a *merkle tree*. We’ll talk about this in later sections of this chapter, but for now, let’s just say that the transactions in the block are hashed together into a single hash value that’s written into the block header. You can’t change any transactions in the block without also changing the merkle root.

The third part from the left is the block’s creation time. This time isn’t exact and doesn’t even always increase from block to block. But it’s roughly accurate.

The fourth part is Lisa’s block signature, which is a stamp of approval from Lisa that anyone can verify. Lisa’s signature proves that she once approved the block, which can be held against her if she tries to cheat. You’ll see how this works shortly. The digital signature in the block header introduces some problems, which we’ll fix in [chapter 7](/book/grokking-bitcoin/chapter-7/ch07) by replacing these digital signatures with something called *proof of work*.

#### Lisa builds a block

Lisa creates a new block roughly every 10 minutes, containing unconfirmed transactions. She writes this block into a new file in a shared folder. Everyone has permission to create new files in the shared folder, but no one has permission to delete or change files. When Lisa writes a block to a file in the shared folder, she *confirms* the transactions in that block.

![Shared folder? Really?](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-01.jpg)

Bitcoin doesn’t use a shared folder. The shared folder is a placeholder for Bitcoin’s peer-to-peer network, which we’ll look at in [chapter 8](/book/grokking-bitcoin/chapter-8/ch08).

Suppose Lisa is about to create a new block at height 20. She’ll do the following:

1. Create a block template.
1. Sign the block template to make it complete.
1. Publish the block.

##### Block templates

Lisa starts by creating the *block template*, a block without a signature ([figure 6.5](/book/grokking-bitcoin/chapter-6/ch06fig05)).

![Figure 6.5. Lisa creates a new block. It’s called a block template because it isn’t yet signed.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/06fig05_alt.jpg)

She collects several transactions to put in the block. She then creates the block header. She creates the previous block ID by hashing the previous block header and putting the result in the new block header. The merkle root is built using the transactions in the block template, and the time is set to the current time.

![Block rewards](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-01.jpg)

In Bitcoin, the block reward covers more than just the newly created money. It also includes transaction fees, discussed in [chapter 7](/book/grokking-bitcoin/chapter-7/ch07). The newly created money in a block is called the *block subsidy*.

The first transaction in her block is a coinbase transaction. Blocks’ coinbase transactions create 50 CT per block instead of 7,200 CT as was the case in [chapter 5](/book/grokking-bitcoin/chapter-5/ch05). The idea is that Lisa produces a new block every 10 minutes, which means her daily 7,200 CT reward is spread out over 144 blocks: there are 144 blocks in 24 hours, and 144*50 CT = 7,200 CT. We’ll talk more about block rewards and the coinbase in [chapter 7](/book/grokking-bitcoin/chapter-7/ch07).

##### Signing the block

Before Lisa is finished with the block, she must sign it using a private key only she knows, as shown in [figure 6.6](/book/grokking-bitcoin/chapter-6/ch06fig06).

![Figure 6.6. Lisa signs a block with her block-signing private key. The public key is well known among the coworkers.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/06fig06_alt.jpg)

Lisa uses her private block-signing key to sign the block header. This digital signature commits to

![Proof of work](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-01.jpg)

Bitcoin blocks aren’t signed this way. They’re “signed” with proof of work, described in [chapter 7](/book/grokking-bitcoin/chapter-7/ch07).

- The previous block ID, which means Lisa’s signature commits to the entire blockchain before this new block
- The merkle root, which means the signature commits to all transactions in this new block
- The timestamp

If anything in the blockchain before the new block or in the transactions in this block changes, the block header’s contents will have to change, too; consequently, the signature will become invalid.

The public key corresponding to Lisa’s block-signing key must be made publicly available to all verifiers. The company can publish the public key on its intranet and on a bulletin board at the main entrance. The signature is required because only Lisa should be able to add blocks to the blockchain (for now). For example, John, can create a block and write it to the shared folder. But he won’t be able to sign it correctly because he doesn’t have Lisa’s private key, so no one will accept John’s block.

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0169-01.jpg)

Using private keys to sign blocks can be a bad idea for two reasons:

- Lisa’s private key can be stolen. If this happens, the thief can create valid blocks and write them to the shared folder. These blocks’ coinbase transactions will of course pay the block rewards to the thief’s PKH, and not to Lisa’s.
- The sources containing Lisa’s public key—for example, the bulletin board and the intranet—might be compromised and the public keys replaced by some bad guy’s public key. If this happens, some verifiers will be tricked into accepting blocks signed by a key other than Lisa’s block-signing key. The bad guy can fool some portion of the verifiers. A coworker shouldn’t trust just the note on the bulletin board, because it’s easy for someone to replace the note with a false public key. Coworkers need to get the public key from different sources, such as the bulletin board, the intranet, and by asking fellow workers. A single source is too easily manipulated by bad guys.

The way blocks are signed will change in [chapter 7](/book/grokking-bitcoin/chapter-7/ch07), from digital signatures to proof of work.

##### Publishing the block

Once the block is signed, Lisa needs to make it available to verifiers. She uses the shared folder for this, creating a new file, block_20.dat, in which to save her new block ([figure 6.7](/book/grokking-bitcoin/chapter-6/ch06fig07)).

![Figure 6.7. Lisa has signed her new block and saves it into a new file in the shared folder.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/06fig07_alt.jpg)

The block is now published. Anyone interested can read this block from the shared folder. Remember that no one can delete or alter this file due to restrictive permissions on the shared folder. Not even Lisa can change it. There is, however, a system administrator who has full permission to do anything with the shared folder. We’ll get rid of the system administrator in [chapter 8](/book/grokking-bitcoin/chapter-8/ch08), when I introduce the peer-to-peer network.

##### Transaction selection

When Lisa builds her block, she picks transactions to include. She can select anything from zero transactions to all unconfirmed transactions. The transaction order isn’t important as long as all transactions spend outputs already present in the blockchain or in the block being built. For example, the block in [figure 6.8](/book/grokking-bitcoin/chapter-6/ch06fig08) is perfectly fine.

![Figure 6.8. Transactions must be ordered in spending order. Otherwise, there are no restrictions.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/06fig08_alt.jpg)

All transactions in this block spend transactions already in the blockchain, meaning they all reference transactions to the left of themselves. But the block in [figure 6.9](/book/grokking-bitcoin/chapter-6/ch06fig09) is invalid.

![Figure 6.9. This block is invalid because a transaction spends an output that doesn’t yet exist.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/06fig09_alt.jpg)

It’s invalid because a transaction spends an output that’s placed *after*—to the right of—the spending transaction.

#### How does this process protect you from deletes?

Suppose Lisa wants to eat a cookie without paying for it. She creates a transaction and puts it in the block she’s currently working on, block height 21. She creates the block header, signs it, and writes the block to a new file (block_21.dat) in the shared folder ([figure 6.10](/book/grokking-bitcoin/chapter-6/ch06fig10)).

![Figure 6.10. Lisa creates a block containing her payment for a cookie.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/06fig10_alt.jpg)

The cafe watches the shared folder for incoming blocks. When Lisa writes the block file into the shared folder, the cafe downloads the block and verifies it. Verifying a block involves verifying the following:

- The block-header signature is valid. The signature is verified using Lisa’s public key obtained from the bulletin board or intranet.
- The previous block ID exists. It’s block 20 in this case.
- All transactions in the block are valid. This uses the same verification approach as in [chapter 5](/book/grokking-bitcoin/chapter-5/ch05), using a private unspent transaction output (UTXO) set.
- The combined hash of all transactions matches the merkle root in the block header.
- The timestamp is within reasonable limits.

Lisa has paid for a cookie, and the cafe has downloaded the block that contains Lisa’s transaction and verified it. The cafe gives Lisa the cookie, and she eats it.

Can Lisa undo this payment without being proven a fraud? Her only option is to make another, changed version of block 21 that doesn’t include her transaction and to write this new block to the shared folder as block_21b.dat ([figure 6.11](/book/grokking-bitcoin/chapter-6/ch06fig11)).

![Figure 6.11. Lisa creates an alternative block at height 21 that doesn’t contain her transaction.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/06fig11_alt.jpg)

The new version is like the old version but without Lisa’s transaction. Because she tampers with the transactions in the block, she has to update the merkle root in the header with a merkle root that matches the new set of transactions in the block. When she changes the header, the signature is no longer valid, and the header needs to be re-signed. To make the changed block available to verifiers, she needs to put the block on the shared folder, for example using filename block_21b.dat.

The cafe has already downloaded the first version of block 21. When Lisa adds the new block file, the cafe will discover that there’s another version of the block in the shared folder ([figure 6.12](/book/grokking-bitcoin/chapter-6/ch06fig12)).

![Figure 6.12. The cafe sees two versions of block 21, one with Lisa’s transaction and one without.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/06fig12_alt.jpg)

Now the cafe sees two different blocks at height 21, one that contains the 10 CT payment to the cafe and one that doesn’t. Both blocks are equally valid, and neither block is more accurate than the other from a verification perspective. But the good thing is that the cafe can prove Lisa is playing dirty tricks because she’s created two different *signed* versions of the block. The signatures prove Lisa cheated, and you no longer have a word-against-word situation. Lisa will be fired or at least removed from her powerful position as a transaction processor.

What if there were other blocks after block 21 when Lisa cheated? Suppose blocks 22 and 23 were already created when Lisa decided she wanted to delete her transaction ([figure 6.13](/book/grokking-bitcoin/chapter-6/ch06fig13)).

![Figure 6.13. Lisa needs to create alternative versions of the block containing her transaction and all subsequent blocks.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/06fig13_alt.jpg)

Now she needs to make three alternative blocks: 21, 22, and 23. They must all be replaced by valid blocks.

**Changing anything in a block makes that block and all subsequent blocks invalid. This is because each block header contains a pointer to the previous block—the previous block ID—which will become invalid if the previous block changes.**

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0174-01.jpg)

#### Why use a blockchain?

The blockchain is a complicated way to sign a bunch of transactions. Wouldn’t it be much simpler if Lisa just signed all transactions ever made in one big chunk every 10 minutes? This would accomplish the same goal. But this approach has several problems:

- As the number of transactions grows, the time it takes for Lisa to sign the entire set will increase.
- The same goes for verifiers—the time it takes to verify a signature increases with the total number of transactions.
- It’s hard for verifiers to know what’s new since the last signature. This information is valuable when maintaining the UTXO set.

By using the blockchain, Lisa has to sign only the most recent block of transactions while still, indirectly via the previous block ID pointer, signing all historic transactions, as [figure 6.14](/book/grokking-bitcoin/chapter-6/ch06fig14) shows.

![Figure 6.14. Each block signs all transactions ever made, thanks to the headers’ previous block ID field.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/06fig14_alt.jpg)

Each block’s signature reinforces the previous blocks’ signatures. This will become important when we replace the signatures with proof of work in the next chapter.

The verifiers can also easily see what’s new since the last block and update their UTXO sets accordingly. The new transactions are right there in the block.

The blockchain also provides some nice extra features that we’ll discuss later, such as the merkle tree.

### Lightweight wallets

Coworkers who want to verify the blockchain to make sure they have valid financial information use software that downloads the entire blockchain and keeps a UTXO set up to date at all times. This software needs to run nearly all the time to stay up to date with newly produced blocks. We call this running software a *full node*. A full node knows about all transactions since block 0, the *genesis block*. The company and the cafe are typical full-node users. They don’t have to trust someone else with providing them with financial information: they get their information directly from the blockchain. Anyone is free to run this software as they please.

![Alternative names](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-01.jpg)

A lightweight wallet is sometimes referred to as an *SPV client* or an *SPV wallet*. SPV stands for *simplified payment verification*.

In [chapter 4](/book/grokking-bitcoin/chapter-4/ch04), I introduced a mobile app that coworkers can use to manage their private keys, as well as send and receive money. This wallet app has now been adapted to the new blockchain system.

Because most wallet users are on a mobile data plan, they don’t want to waste bandwidth on downloading all—for them, uninteresting—block data. The overwhelming majority of the blocks won’t contain any transactions concerning them, so downloading all that data would only make their phones run out of data traffic without providing useful information.

The full-node developers and the wallet developers cooperate to let wallets connect to full nodes over the internet and get relevant block data from those nodes in a way that doesn’t require huge amounts of data traffic. Wallets are allowed to connect to any full node and ask for the data they need.

Suppose John’s wallet contains two addresses, @a and @b, and he wants to receive notifications from a full node about transactions concerning his wallet. He can make a network connection to any of the full nodes—for example, the cafe’s. The wallet and the full node then start talking, as [figure 6.15](/book/grokking-bitcoin/chapter-6/ch06fig15) shows.

![Figure 6.15. Information exchange between a lightweight wallet and a full node. The full node sends all block headers and a fraction of all transactions to the wallet.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/06fig15_alt.jpg)

![BIP37](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-01.jpg)

This process is described in full detail in BIP37, found at web resource 9 in [appendix C](/book/grokking-bitcoin/appendix-c/app03).

We’ll examine how this connection is made and how the wallet and node send information between each other more thoroughly in [chapter 8](/book/grokking-bitcoin/chapter-8/ch08). I only provide a high-level glimpse here, as follows:

- ***1*** John’s wallet asks the full node for all block headers since the wallet’s last known block header and all transactions concerning John’s addresses.
- ***2*** The cafe’s full node sends all requested block headers to the wallet and at least all transactions concerning John’s addresses.

In step ***1***, the wallet doesn’t send the exact list of addresses in John’s wallet. This would harm John’s privacy because the cafe would then know that all John’s addresses belong together and could sell that information to Acme Insurances. Not nice. John’s wallet instead sends a filter to the full node. This filter is called a *bloom filter*. The full node uses it to determine whether to send a transaction to the wallet. The filter tells the full node to send all transactions concerning @a and @b, but it also tells the full node to send transactions that aren’t relevant to John’s wallet, to obfuscate what addresses actually belong to the wallet. Although bloom filters don’t have much to do with the blockchain, I still dedicate a subsection to them here because lightweight wallets use them extensively.

In step ***2***, transactions and block headers are sent to John’s wallet, but the complete blocks aren’t sent (to save network traffic). John’s wallet can’t use just a transaction and the header to verify that the transaction is in the block. Something more is required: a *partial merkle tree* that proves that one or more transactions are included in the block.

The two steps are performed as a synchronizing phase just after the wallet connects to the cafe’s full node. After this, as Lisa creates new blocks and the cafe’s full node picks them up, the corresponding block headers are sent to the wallet together with all transactions concerning John’s addresses in roughly the same way as described earlier.

We’ll next discuss bloom filters. Merkle trees are explained in the “Merkle trees” section.

#### Bloom filters obfuscate addresses

John’s wallet contains two addresses, @a and @b, but John doesn’t want to reveal to anyone that @a and @b belong to the same wallet. He has reason to be wary because he’s heard rumors that Acme Insurances pays good money for such information, to “adjust” premiums based on people’s cookie-eating habits.

##### Creating the bloom filter

To obfuscate what addresses belong together, John’s wallet creates a bloom filter to send to the full node ([figure 6.16](/book/grokking-bitcoin/chapter-6/ch06fig16)).

![Figure 6.16. The client sends a bloom filter to the full node to obfuscate what addresses belong to the wallet.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/06fig16_alt.jpg)

The bloom filter is a sequence of bits, which, as mentioned in [chapter 2](/book/grokking-bitcoin/chapter-2/ch02), can have the value 0 or the value 1. John’s bloom filter happens to be 8 bits long. [Figure 6.17](/book/grokking-bitcoin/chapter-6/ch06fig17) illustrates how it was created.

![Figure 6.17. The lightweight wallet creates a bloom filter to send to the full node. Each address in the wallet is added to the bloom filter.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/06fig17_alt.jpg)

The wallet creates the sequence of bits (the bloom filter) and initializes them with zeroes all over. It then adds all John’s public key hashes (PKHs) to the bloom filter, starting with PKHa, the PKH for @a.

![Why three hash functions?](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-01.jpg)

The number of hash functions can be anything, as can the size of the bloom filter. This example uses three hash functions and 8 bits.

It runs PKHa through the first of the three hash functions. This hash function results in the value `2`. This value is the index of a bit in the bloom filter. The bit at index 2 (the third from the left) is then set to `1`. Then PKHa is run through the second hash function, which outputs `0`, and the corresponding bit (the first from the left in the figure) is set to `1`. Finally, the third hash function outputs `6`, and the bit at index 6 (seventh from the left) is set to `1`.

Next up is PKHb, which is handled the exact same way. The three hash functions output `5`, `0`, and `3`. These three bits are all set to `1`. Note that bit 0 was already set by PKHa, so this bit isn’t modified.

The bloom filter is finished and ready to be sent to the full node.

##### Using the bloom filter

The full node receives the bloom filter from the wallet and wants to use it to filter transactions to send to the wallet.

Suppose Lisa just published a new block to the shared folder, and the full node has verified the block. The full node now wants to send the new block’s header and all relevant transactions in it to the wallet. How does the full node use the bloom filter to determine what transactions to send?

The block contains three transactions: Tx1, Tx2, and Tx3 ([figure 6.18](/book/grokking-bitcoin/chapter-6/ch06fig18)).

![Figure 6.18. The block to send contains three transactions; only one concerns John.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/06fig18_alt.jpg)

Tx1 and Tx3 have nothing to do with John’s addresses, but Tx2 is a payment to John’s address @b. Let’s look at how the full node uses the bloom filter ([figure 6.19](/book/grokking-bitcoin/chapter-6/ch06fig19)).

![Figure 6.19. The full node uses the bloom filter to determine which transactions are “interesting” to the wallet.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/06fig19_alt.jpg)

For each output in a transaction, the node tests whether any PKH matches the filter. It starts with Tx1, which has a single output to PKHL. To test whether PKHL matches the filter, it runs PKHL through the same three hash functions as John’s wallet did when the filter was created. The hash functions output the indexes `5`, `1`, and `0`. The bits at index `5` and `0` are both `1`, but the bit at index `1` is `0`. A 0 bit means PKHL definitely isn’t interesting to John’s wallet. If John’s wallet was interested in PKHL, the wallet would have added it to the filter, thus setting bit `1` to `1`. Because PKHL was the only PKH in Tx1, John’s wallet isn’t interested in this transaction.

The next transaction is Tx2. It contains two PKHs: PKHb and PKHX. It begins with PKHb. Running this PKH through the hash functions gives the indexes `5`, `0`, and `3`. All three bits have the value `1`. This means the node can’t say for sure if the transaction is interesting to the wallet, but it can’t say that it’s definitely *not* interesting. Testing any further PKHs in this transaction is pointless because the node has already determined that Tx2 should be sent to the wallet.

The last transaction has two outputs to PKHY and PKHZ. It starts with PKHY, which happens to point at `2`, `7`, and `4`. Both bits `4` and `7` are `0`, which means PKHY definitely isn’t interesting to the wallet. Let’s continue with PKHZ, which results in bits `2`, `3`, and `0`. All three bits have the value `1`. This, again, means Tx3 *might* be interesting to the wallet, so the node will send this transaction, too. John’s wallet doesn’t actually contain PKHZ, but the bloom filter aims to match more than needed to preserve some degree of privacy. We call this a *false positive* match.

The result of the bloom filtering is that the node will send Tx2 and Tx3 to the wallet. How the transactions are sent is a totally different story, described in “Merkle trees.”

##### Warning!

The following is challenging. Feel free to skip this part and jump to “Where were we?”

The previous description is a simplification of what really happens. You tested only PKHs of the transaction outputs described, which would capture all transactions that pay cookie tokens *to* any of John’s addresses. But what about transactions that are spending *from* John’s addresses? We could argue that the full node doesn’t need to send those transactions to the wallet because the wallet already knows about them, given that it created them in the first place. Unfortunately, you do need to send those transactions, for two reasons.

First, it might not be this wallet app that created the transaction. John can have multiple wallet apps that generate addresses from the same seed. For example, do you remember in [chapter 4](/book/grokking-bitcoin/chapter-4/ch04) how a wallet can be restored from a mnemonic sentence? This sentence can be used by multiple wallet apps at the same time. John might want to make a payment from one of the wallet apps and be notified of the payment in the other wallet app so he can monitor the total balance in that app.

Second, John wants to be notified when the transaction is confirmed. The wallet app might already have the transaction, but it’s still marked as *unconfirmed* in the app. John wants to know when the transaction has been included in a block, so he needs the node to send him this transaction when it’s in a block.

What the node really tests are the following items ([figure 6.20](/book/grokking-bitcoin/chapter-6/ch06fig20)):

![Figure 6.20. Several things in a transaction are tested through the bloom filter to determine whether the transaction is possibly interesting.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/06fig20.jpg)

- The txid of the transaction
- All transaction output (TXO) references in the inputs
- All data items in signature scripts
- All data items of the outputs

For John’s wallet to be notified of spends, it needs to add either all its public keys to the bloom filter or all its UTXO references.

##### Throttling privacy and data traffic

The purpose of the bloom filter is to enhance user privacy. The level of privacy can be controlled by tuning the ratio between the number of 1s in the bloom filter and the bloom filter’s size. The more 1s in the bloom filter in relation to the bloom filter’s size, the more false positives. More false positives means the full node will send more unrelated transactions to the wallet. More unrelated transactions means more wasted data traffic but also improved privacy.

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0181-01.jpg)

Let’s do some back-of-the-envelope calculations. The bloom filter in the earlier example has 8 bits, of which five are 1s. A single hash function’s output has a 5/8 probability of hitting a 1. For a single test, the probability that all three hash functions hit a 1 is then (5/8)3. The probability that a single test is negative—at least one of the three hash functions points to a 0—is then 1 – (5/8)3. The full node will perform several tests on each transaction, typically nine for a transaction with two inputs and two outputs. Let’s check this against the list of tests the full node performs:

- The txid of the transaction (1)
- All TXO references in the inputs (2)
- All data items in signature scripts (public key and signature × 2 = 4)
- All data items of the outputs (2)

The probability that all nine tests are negative is (1 – (5/8)3)9 ≈ 0.08. So, almost all—92/100—transactions will be sent to the wallet. This shows that having only three 0s of 8 bits in the bloom filter won’t help reduce the data much, but it protects your privacy better.

To get fewer false positives, John’s wallet must use a larger bloom filter so the ratio (number of ones/bloom filter size) decreases.

Let’s define some symbols:

- *t* = Number of tests performed on a transaction (9)
- *p* = Probability of a transaction being deemed uninteresting
- *r* = Ratio of the number of 1s/bloom filter size

We can generalize our calculation as follows:

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0182-01.jpg)

Let’s say you only want to get 1/10 of all transactions (given that all transactions are like the previous transaction, with two inputs and two outputs). How big do you have to make the bloom filter?

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0182-02.jpg)

This calculation means the bloom filter should be about 6/0.23 ≈ 26 bits to get only 1/10 of all transactions. The bloom filter size must be a multiple of 8 bits, so 26 bits isn’t allowed. We can round upward to 32 bits.

Remember that these are rough calculations based on somewhat false assumptions regarding transaction characteristics. We also aren’t considering that the number of 1s in the example isn’t strictly six but can be anywhere from three to six, given that both John’s addresses could have generated the same set of indexes. But this process should help you get an idea of how big a bloom filter must be.

##### Problems with bloom filters

Bloom filters have been broadly used by many lightweight wallets, but they have issues:

- *Privacy*—A node that receives bloom filters from a lightweight client can, with high precision, determine what addresses belong to a wallet. The more bloom filters collected, the higher the accuracy. See web resource 14 in [appendix C](/book/grokking-bitcoin/appendix-c/app03) for details.
- *Performance*—When a full node first receives a bloom filter from a lightweight client, the node needs to scan the entire blockchain for matching transactions. This scanning is processing and disk intensive and can take several minutes, depending on the full node’s hardware. This fact can be used maliciously to attack full nodes so they become unresponsive, in a *denial-of-service* (DoS) attack.

New Bitcoin Improvement Proposals (BIPs), BIP157 and BIP158, have been proposed that aim to solve these issues, but they haven’t been widely implemented and tested yet. The general idea is to reverse the process so a full node sends a filter to the lightweight wallet for each block. This filter contains information about what addresses the block affects. The lightweight client checks whether its addresses match the filter and, if so, downloads the entire block. The block can be downloaded from any source, not just the full node that sent the filter.

![Where were we?](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-09.jpg)

For the sake of orientation, [figure 6.21](/book/grokking-bitcoin/chapter-6/ch06fig21) shows part of what I sketched out in “[Step 4: Wallets](/book/grokking-bitcoin/chapter-1/ch01lev3sec4)” in [chapter 1](/book/grokking-bitcoin/chapter-1/ch01), where Bob’s wallet was notified of Alice’s payment to Bob.

![Figure 6.21. A Bitcoin wallet is notified of an incoming payment by a full node.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/06fig21.jpg)

In the example in this chapter, John has sent a bloom filter to the cafe’s full node to receive only information concerning him. The full node has received a block that contains two transactions that are interesting to John, at least according to John’s bloom filter.

The next thing that happens is that the new block’s header and the potentially interesting transactions are sent to John’s wallet.

### Merkle trees

Now that the full node has determined which transactions to send to the wallet, it needs to send the new block header and all transactions John’s wallet might be interested in.

The full node has determined that transactions Tx2 and Tx3 need to be sent to the wallet. If the node sends only the header and the two transactions, then John’s wallet won’t be able to verify that the transactions belong to the block. The merkle root depends on three transactions, Tx1, Tx2, and Tx3, but the wallet only gets Tx2 and Tx3 from the full node. The wallet can’t re-create the merkle root in the block header. It needs more information to verify that the transactions are included in the block. Remember that you want to save data traffic, so sending all transactions in the block isn’t good enough.

#### Creating the merkle root

It’s time to reveal how Lisa created the merkle root. Suppose Lisa is about to create the block header shown in [figure 6.22](/book/grokking-bitcoin/chapter-6/ch06fig22). She needs to calculate the combined hash of all transactions, called the merkle root ([figure 6.23](/book/grokking-bitcoin/chapter-6/ch06fig23)). You calculate the merkle root by creating a hierarchy of cryptographic hashes, a merkle tree.

![Figure 6.22. The full node feeds the lightweight wallet the block header and potentially relevant transactions.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/06fig22_alt.jpg)

![Figure 6.23. Lisa creates a merkle root from the transactions in a block.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/06fig23_alt.jpg)

The transactions are ordered the same way they are in the block. If the number of items is odd, the last item is duplicated and added last. This extra item isn’t added to the block; it’s only duplicated temporarily for the merkle tree calculation.

Each item (transaction, in this case) is hashed with double SHA256. This results in four hash values of 256 bits each.

The hash values are pairwise *concatenated*, meaning two hashes are merged by appending the second hash after the first hash. For example, `abc` concatenated with `def` becomes `abcdef`.

The four hash values have now become two concatenated values. Because two is an even number, you don’t add an extra item at the end. The two concatenated values are each hashed separately, resulting in two 256-bit hashes.

These two hash values are concatenated into a single 512-bit value. This value is hashed, resulting in the 256-bit merkle root. This merkle root is written into the block header. If any transaction is added, deleted, or changed, the merkle root must be recalculated ([figure 6.24](/book/grokking-bitcoin/chapter-6/ch06fig24)).

![Figure 6.24. A change in the transactions will cause a change in the merkle root, making the signature invalid.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/06fig24.jpg)

This is nice, because when Lisa signs the block header, you know that if someone tampers with the transactions in it, the signature becomes invalid.

#### Proving that a transaction is in a block

The full node wants to send Tx2 and Tx3 to John’s wallet because it thinks those transactions might be interesting to John’s wallet. The full node wants to prove to the wallet that both Tx2 and Tx3 are included in the block. But let’s begin with proving only a single transaction, Tx2. We’ll look at a bigger, more complex example later in this chapter.

How can the full node provide proof to the wallet that Tx2 is included in the block? It can provide a *partial merkle tree* that connects Tx2 to the merkle root in the block header. The general idea is to send the bare minimum to the lightweight wallet—just enough to verify that Tx2 is in the block. In this example, the node will send the stuff in [figure 6.28](/book/grokking-bitcoin/chapter-6/ch06fig25) to the lightweight wallet.

![Figure 6.25. The bare minimum to prove Tx2 is in the block. The full node sends this to the wallet.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/06fig25_alt.jpg)

The lightweight wallet will then use this information to verify that Tx2 is in the block by calculating the intermediary hashes toward the root, and verify that the hash of Tx2 is among the hashes provided by the full node ([figure 6.26](/book/grokking-bitcoin/chapter-6/ch06fig26)).

![Figure 6.26. The lightweight wallet verifies that Tx2 is in the block by reconstructing the merkle root.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/06fig26_alt.jpg)

The hash functions have been removed from the diagram to make it easier to read. The wallet can now be certain Tx2 is in the block.

#### How it really works

##### Warning!

The following describes in detail how to create and verify a partial merkle tree. If you want, you can skip this part and jump to “[Security of lightweight wallets](#ch06lev1sec5).”

##### Creating the partial merkle tree

The partial merkle tree is a pruned version of the full merkle tree, containing only the parts needed to prove Tx2 is part of the tree. The full node sends three things to the wallet:

- The block header
- The partial merkle tree
- Tx2

Let’s construct the partial merkle tree. The full node knows the number of transactions in the block, so it knows the merkle tree’s shape. To construct the partial merkle tree, the full node examines the hashes in the merkle tree, starting at the merkle root and moving downward in the tree, left branch first ([figure 6.27](/book/grokking-bitcoin/chapter-6/ch06fig27)).

![Figure 6.27. The full node constructs a partial merkle tree that connects Tx2 to the merkle root in the block header.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/06fig27_alt.jpg)

The partial merkle tree consists of

- A number indicating the total number of transactions in the block
- A list of flags
- A list of hashes

At each step, you do two things with the current hash, as outlined in the following table:

1. Add the flag to the list of flags.  means there’s nothing interesting in this hash’s branch;  means this branch contains an interesting transaction.
1. If the flag is , or if this hash is an interesting txid, add the hash to the list of hashes.

| Step | Commits to interesting txid? | List of flags | Is flag , or is the hash an interesting txid? | List of hashes |
| --- | --- | --- | --- | --- |
| ***1*** | Yes |  | No | — |
| ***2*** | Yes |  | No | — |
| ***3*** | No |  | Yes | 3 |
| ***4*** | Yes |  | Yes | 3 4 |
| ***5*** | No |  | Yes | 3 4 5 |

This ordering of the steps is called *depth first*, meaning you always move downward in the tree as far as you can before moving sideways. But you won’t go down in tree branches that don’t contain any interesting transactions. This is noted in the list of flags as . You stop at  because you don’t want to send unnecessary data to the wallet, hence the term *partial* merkle tree.

Now that the full node has created this partial merkle tree, the node will send the block header and the partial merkle tree to the wallet, and then send the actual transaction Tx2. The block header together with the partial merkle tree are often referred to as a *merkle proof*.

##### Verifying the partial merkle tree

The wallet has received a block header, a partial merkle tree, and the transaction Tx2 from the full node. That’s all the wallet needs to verify that Tx2 is indeed included in the block. The goal is to verify that there’s a way to “connect” Tx2 to the merkle root in the block header. It starts with verifying the partial merkle tree ([figure 6.28](/book/grokking-bitcoin/chapter-6/ch06fig28)).

![Figure 6.28. The wallet verifies the partial merkle tree.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/06fig28_alt.jpg)

Use the number of transactions (three) received from the full node to build the merkle tree’s structure. The wallet knows how a merkle tree with three transactions looks.

Use the list of flags and the list of hashes to attach hashes to the merkle tree in depth-first order, as follows.

| Step | Next flag from list | Remaining list of flags | Is flag , or are you at the lowest level? | Attach hash | List of hashes |
| --- | --- | --- | --- | --- | --- |
| ***1*** |  |  | No | — | 3 4 5 |
| ***2*** |  |  | No | — | 3 4 5 |
| ***3*** |  |  | Yes | 3 | 4 5 |
| ***4*** |  |  | Yes | 4 | 5 |
| ***5*** |  |  | Yes | 5 |  |

The wallet has now attached enough hashes (***3***, ***4***, and ***5***) to the merkle tree to fill in the blanks upward toward the partial merkle tree root. First, the hash of step ***2*** is calculated from ***3*** and ***4***; then the root is calculated from ***2*** and ***5***.

Compare the calculated merkle root with the merkle root in the block header—the actual merkle root—and verify that they’re the same. Also, check that the hash of Tx2 is among the list of hashes received from the full node ([figure 6.29](/book/grokking-bitcoin/chapter-6/ch06fig29)).

![Figure 6.29. The wallet checks that the merkle roots match and that Tx2 is included in the list of hashes. If so, Tx2 is proven to belong to the block.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/06fig29_alt.jpg)

If the transaction turns out to match one of the hashes in the partial merkle tree, and if the partial merkle tree root matches the merkle root in the block header, the full node has proven that Tx2 is part of the block.

But the full node wanted to send two transactions from this block. How would the merkle proof look with two transactions? Do you send multiple merkle proofs? No—we’ll leave this as an exercise at the end of this chapter.

##### Handling thousands of transactions in a block

The block in the previous example contained only three transactions. You didn’t save much space sending the header, the partial merkle tree, and Tx2. You could just as well send all three txids instead of the partial merkle tree—that would be much simpler. But the gains with merkle proofs become more apparent when the number of transactions in a block increases.

Suppose the full node just verified a block containing 12 transactions. It has determined, by testing all transactions against the wallet’s bloom filter, that two of the transactions are potentially interesting to the wallet. [Figure 6.30](/book/grokking-bitcoin/chapter-6/ch06fig30) shows how this would look.

![Figure 6.30. Constructing a partial merkle tree from 12 transactions and two interesting transactions](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/06fig30_alt.jpg)

The full node has to send only the block header, the number 12, 14 flags, and seven hashes. This sums to about 240 bytes, far less data than sending the block header and all 12 txids (about 464 bytes).

Let’s check some rough numbers to see how the merkle proof compares in size to the full block and the simplistic approach of sending all txids as the number of transactions grows ([table 6.1](/book/grokking-bitcoin/chapter-6/ch06table01)).

##### Table 6.1. Size of merkle proofs compared to the block size and simple proof for different block sizes[(view table figure)](https://drek4537l1klr.cloudfront.net/rosenbaum/HighResolutionFigures/table_6-1.png)

| Number of tx[[*](/book/grokking-bitcoin/chapter-6/ch06table01tn01)] in block | Block size (bytes) | Size of simple proof (bytes) | Size of merkle proof (bytes) | Length of list of hashes |
| --- | --- | --- | --- | --- |
| 1 | 330 | 112 | 112 | 1 |
| 10 | 2,580 | 400 | 240 | 5 |
| 100 | 25,080 | 3,280 | 336 | 8 |
| 1,000 | 250,080 | 32,080 | 432 | 11 |
| 10,000 | 2,500,080 | 320,080 | 560 | 15 |
| 100,000 | 25,000,080 | 3,200,080 | 656 | 18 |

* tx = *transaction*

[Table 6.1](/book/grokking-bitcoin/chapter-6/ch06table01) assumes that all transactions are 250 bytes and that you only want to prove a single transaction. The block size is calculated as the 80-byte block header plus the number of transactions times 250. The simple proof is calculated as the 80-byte block header plus the number of transactions times 32. The merkle proof is calculated as the 80-byte block header plus the length of the list of hashes times 32. Ignore the flags and number of transactions, because they’re negligible.

![80-byte header](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-01.jpg)

Bitcoin’s block header is always 80 bytes. The cookie token block headers are slightly bigger because of the signature. In the next chapter, you’ll fix the block header to match Bitcoin’s more closely; and in [chapter 11](/book/grokking-bitcoin/chapter-11/ch11), we’ll talk about the version, which is also in the block header.

The merkle proofs don’t grow as fast as the simple proofs, because merkle proofs grow *logarithmically* with the number of transactions, whereas simple proofs grow *linearly* with the number of transactions. When the block *doubles* in size, the merkle proof size roughly increases *by a constant term* of 32 bytes, whereas the simple proof doubles in size.

### Security of lightweight wallets

Lightweight wallets seem like a nice touch for the cookie token system. They certainly are, but users should be aware of what they’re missing out on compared to full nodes.

Full nodes verify the blockchain’s complete history and know for sure that the money a transaction spends exists and that the signatures are valid.

A lightweight wallet knows the entire chain of block headers. It will verify that Lisa has correctly signed each block header. When the wallet receives a transaction and a merkle proof, it can check that the transaction is contained in the block and that Lisa signed that block. But it can’t verify a lot of other things. For example:

- That the script programs in the transaction all return “OK,” which usually means verifying the signatures of all inputs
- That the spent outputs aren’t already spent
- That it receives all relevant transactions

The lightweight wallet also doesn’t know what rules the full node is following. The full node might have adopted a rule that pays double the reward to Lisa. A typical full node would consider any block that pays too much to Lisa as invalid because that isn’t a rule it signed up for, and would drop the block.

The lightweight wallet needs to trust the full node to verify those things on its behalf and that the full node is following the rules the wallet expects it to follow.

The full node can hide relevant transactions to the wallet. This means the wallet won’t be notified about some incoming or outgoing transactions.

A lightweight wallet gives verification responsibility to the full node it’s connected to. Suppose Lisa produces an invalid block—for example, a block that contains a transaction that spends an output that doesn’t exist. When the full node receives this block, it should verify the block and drop it because it’s invalid. But there might be occasions when the full node, deliberately or accidentally, doesn’t detect the error. Perhaps the cafe is in cahoots with Lisa to fool John—who knows? The cafe and Lisa can, at least temporarily, make John believe he’s received money that he didn’t receive.

John can take at least two measures to reduce the risk of being fooled by a full node:

-  *Connect to multiple full nodes simultaneously*—Most lightweight wallets in Bitcoin do this automatically. All full nodes that John’s wallet is connected to must take active part in the conspiracy in order to fool John ([figure 6.31](/book/grokking-bitcoin/chapter-6/ch06fig31)).

- *Connect to a trusted node*—A *trusted node* is a full node that John runs himself on a computer he controls ([figure 6.32](/book/grokking-bitcoin/chapter-6/ch06fig32)). This way, John can use a lightweight wallet on his mobile phone to save data traffic while still being sure he receives correct information from his full node.

![Trusted node](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-01.jpg)

![Figure 6.31. John’s wallet is connected to multiple full nodes. Hopefully, they don’t all collude to fool John.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/06fig31.jpg)

![Figure 6.32. John has set up a trusted node that his lightweight wallet connects to.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/06fig32.jpg)

The last option is useful if John is concerned some full nodes might adopt rule changes he doesn’t agree with. The only way to be absolutely sure you follow the rules *you want* is to run your own full node.

### Recap

This chapter has described the blockchain and how it enables full nodes to prove if Lisa has tried to delete or change transactions. The blockchain is a sequence of blocks that are connected through cryptographic hashes.

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0195-01_alt.jpg)

The merkle root in the block header is the combined hash of all contained transactions. This hash is created by hashing the transactions in a merkle tree structure. Hashes are concatenated pairwise, and the result is hashed to get one level closer to the root.

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0196-01_alt.jpg)

A full node can prove to a lightweight wallet that a transaction is in a block by sending a merkle proof to the wallet. The merkle proof consists of the block header and a partial merkle tree. The merkle proof grows logarithmically with the number of transactions in the block.

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0196-02_alt.jpg)

For privacy reasons, wallets don’t want just the transactions they’re actually interested in. To obfuscate what addresses belong to it, the wallet uses bloom filters to subscribe to more transactions than those that are actually interesting. It creates a bloom filter and sends it to the full node.

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0197-01_alt.jpg)

The full node tests various stuff from the transactions—for example, PKHs in outputs—using the three hash functions. If any such item hashes to indexes all containing `1`, then the node will send the transaction. If not, it won’t send the transaction.

This chapter has solved the issue with deleted or changed transactions. Lisa can’t change the contents of the blockchain without being proven a fraud.

Lisa can still censor transactions. She can refuse to confirm transactions being sent to her. She has ultimate power over what goes into the blockchain and what doesn’t. In [chapter 7](/book/grokking-bitcoin/chapter-7/ch07), we’ll make it much harder for a single actor like Lisa to make such decisions.

#### System changes

We’ve introduced the blockchain, which replaces the spreadsheet on Lisa’s computer ([table 6.2](/book/grokking-bitcoin/chapter-6/ch06table02)). This chapter also introduced a new concept specifically for the cookie token system: the shared folder. This folder will be replaced by a peer-to-peer network of full nodes in [chapter 8](/book/grokking-bitcoin/chapter-8/ch08).

##### Table 6.2. The spreadsheet is replaced by the blockchain. We also introduced the shared folder, which acts as a placeholder for the Bitcoin network.[(view table figure)](https://drek4537l1klr.cloudfront.net/rosenbaum/HighResolutionFigures/table_6-2.png)

| Cookie tokens | Bitcoin | Covered in |
| --- | --- | --- |
| 1 cookie token | 1 bitcoin | [Chapter 2](/book/grokking-bitcoin/chapter-2/ch02) |
| *The spreadsheet* | *The blockchain* | *[Chapter 6](/book/grokking-bitcoin/chapter-6/ch06)* |
| Lisa | A miner | [Chapter 7](/book/grokking-bitcoin/chapter-7/ch07) |
| Block signature | Proof of work | [Chapter 7](/book/grokking-bitcoin/chapter-7/ch07) |
| The shared folder | The Bitcoin network | [Chapter 8](/book/grokking-bitcoin/chapter-8/ch08) |

This blockchain is close to how Bitcoin’s blockchain works but with an important difference: Lisa signs the blocks using digital signatures, whereas in Bitcoin, they’re signed using proof of work.

It’s time again to release a new version of the cookie token system. Just look at the fancy new features in [table 6.3](/book/grokking-bitcoin/chapter-6/ch06table03)!

##### Table 6.3. Release notes, cookie tokens 6.0[(view table figure)](https://drek4537l1klr.cloudfront.net/rosenbaum/HighResolutionFigures/table_6-3.png)

| Version | Feature | How |
| --- | --- | --- |
|  | Prevent Lisa from deleting transactions | Signed blocks in a blockchain |
| Fully validating nodes | Download and verify the entire blockchain. |  |
| Lightweight wallet saves data traffic | Bloom filters and merkle proofs |  |
| 5.0 | Spend multiple “coins” in one payment | Multiple inputs in transactions |
| Anyone can verify the spreadsheet | Make the signatures publicly available in the transactions |  |
| Sender decides on criteria for spending the money | Script programs inside transactions |  |

### Exercises

#### Warm up

**[6.1](/book/grokking-bitcoin/appendix-b/app02qa7q0a1)**

How does a block in the blockchain refer to the previous block?

**[6.2](/book/grokking-bitcoin/appendix-b/app02qa7q0a2)**

What information does the merkle root commit to?

**[6.3](/book/grokking-bitcoin/appendix-b/app02qa7q0a3)**

What information does Lisa’s block signature commit to?

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0199-01.jpg)

**[6.4](/book/grokking-bitcoin/appendix-b/app02qa7q0a4)**

How are new cookie tokens (or bitcoins) created?

**[6.5](/book/grokking-bitcoin/appendix-b/app02qa7q0a5)**

What transactions would match a bloom filter containing only 1s (`1`)?

**[6.6](/book/grokking-bitcoin/appendix-b/app02qa7q0a6)**

What stuff from a transaction does the full node test when determining whether to send a transaction to the lightweight wallet? Skip this exercise if you didn’t read the challenging parts on bloom filters.

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0199-02.jpg)

**[6.7](/book/grokking-bitcoin/appendix-b/app02qa7q0a7)**

The hash functions used to create the bloom filter aren’t *cryptographic* hash functions. Why not?

#### Dig in

**[6.8](/book/grokking-bitcoin/appendix-b/app02qa7q0a8)**

Draw the structure of a merkle tree of a block with five transactions.

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0200-01_alt.jpg)

**[6.9](/book/grokking-bitcoin/appendix-b/app02qa7q0a9)**

Lisa signs all blocks with her block-signing private key. The public key is made public through several sources, such as the intranet and the bulletin board. Name at least one security risk with this scheme. There are mainly two such risks.

**[6.10](/book/grokking-bitcoin/appendix-b/app02qa7q0a10)**

There are two places where a single person can censor transactions or blocks. Which two places?

**[6.11](/book/grokking-bitcoin/appendix-b/app02qa7q0a11)**

Suppose Lisa creates a block in the shared folder at the same height as another block. The new block contains the same transactions as the other block except that one transaction is replaced by another transaction spending the same money. She tries to pull off a double spend. Would this be detected by a full node that

1. Hasn’t downloaded the original block yet?
1. Has already downloaded the original block?

##### Warning!

Exercises 12–15 require you to have read the hard parts I warned you about earlier in the chapter.

**[6.12](/book/grokking-bitcoin/appendix-b/app02qa7q0a12)**

Make a bloom filter of 8 bits of the two addresses @1 and @2, where @1 hashes to the indexes `6`, `1`, and `7`, and @2hashes to `1`, `5`, and `7`. Then suppose a full node wants to use your bloom filter to decide whether to send the following transaction to the wallet:

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0201-01_alt.jpg)

This image shows the hash function results for different parts of the transaction. Would the full node send this transaction to the lightweight wallet?

**[6.13](/book/grokking-bitcoin/appendix-b/app02qa7q0a13)**

When we constructed the merkle proof in “[Proving that a transaction is in a block](/book/grokking-bitcoin/chapter-6/ch06lev2sec7),” we only created the proof for a single transaction, Tx2. In this exercise, construct a partial merkle tree for both transactions Tx2 and Tx3. The number of transactions in the block is three.

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0201-02_alt.jpg)

**[6.14](/book/grokking-bitcoin/appendix-b/app02qa7q0a14)**

In “[Handling thousands of transactions in a block](/book/grokking-bitcoin/chapter-6/ch06lev3sec11),” we constructed a partial merkle tree from a block with 12 transactions. What txids does the full node consider interesting?

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0202-01_alt.jpg)

**[6.15](/book/grokking-bitcoin/appendix-b/app02qa7q0a15)**

Suppose that you’ve calculated the root of a partial merkle tree, as in the previous exercise. What else do you need to do to verify that a certain transaction is included in this block?

### Summary

- Transactions are placed in blocks that Lisa signs to hold her accountable if she tries to delete transactions.
- Each block signature commits to the transactions in that block and all previous blocks so history can’t be tampered with without re-signing the fraudulent block and all subsequent blocks.
- The transactions in a block are collectively hashed in a merkle tree structure to create a merkle root that’s written in the block header. This makes it possible to create a lightweight wallet.
- Lightweight wallets save bandwidth but at the cost of reduced security.
- Lightweight wallet security is reduced because such wallets can’t fully verify a transaction and because a full node can hide transactions from them.
- The only way to be absolutely sure the block rules are followed is to run your own full node.
- The security of a lightweight wallet can be improved by connecting to multiple full nodes or a trusted node.
- Lisa can still censor transactions.
