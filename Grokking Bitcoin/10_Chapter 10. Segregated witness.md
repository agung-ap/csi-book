# Chapter 10. Segregated witness

### **This chapter covers**

- Understanding Bitcoin’s problems
- Moving signatures out of transactions

Bitcoin is far from perfect. It has several shortcomings that we should address. The first section of this chapter will explain some of these shortcomings. Among the most critical are *transaction malleability* and inefficiencies in signature verification. We’ve already mentioned transaction malleability in the “[Time-locked transactions](/book/grokking-bitcoin/chapter-9/ch09lev1sec1)” section in [chapter 9](/book/grokking-bitcoin/chapter-9/ch09)—someone might change a transaction in subtle, but valid, ways while it’s being broadcast, which will cause its txid to change.

A solution to these problems was presented at a 2015 conference on Bitcoin scaling. This solution is known as *segregated witness* (segwit), which is a weird name for moving signature data out of transactions. I’ll describe this solution in detail: it includes changes in pretty much all parts of Bitcoin, including Bitcoin addresses, transaction format, block format, local storage, and network protocol.

Because segwit was a pretty big change in Bitcoin, it wasn’t trivial to deploy without disrupting the network. It was carefully designed so old software would continue working and accepting segwit transactions and blocks, although without verifying certain parts of them.

### Problems solved by segwit

In this section, we’ll discuss the problems that segwit will solve.

#### Transaction malleability

To explain transaction malleability, let’s go back to the example in [chapter 9](/book/grokking-bitcoin/chapter-9/ch09) in which you gave a time-locked transaction to your daughter. When almost a year has passed since you created your time-locked transaction, you need to invalidate that transaction and create a new time-locked transaction, as [figure 10.1](/book/grokking-bitcoin/chapter-10/ch10fig01) shows.

![Figure 10.1. You spend one of the outputs that the previous time-locked transaction spends and create a new time-locked transaction that you give to your daughter.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/10fig01_alt.jpg)

It’s important to give the new time-locked transaction, Tx3, to your daughter before broadcasting Tx2, which invalidates the previous time-locked transaction, Tx1. Otherwise, if you do it the other way around and get hit by a bus between the two steps, your daughter won’t be able to claim the money.

Suppose you do this correctly and first give Tx3 to your daughter and then broadcast Tx2. Tx3 spends the output of Tx2, which means Tx3 contains the txid of Tx2 in one of its inputs. Let’s see what might happen when you broadcast Tx2 ([figure 10.2](/book/grokking-bitcoin/chapter-10/ch10fig02)).

![Figure 10.2. Your transaction is being modified by Qi on its way through the network.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/10fig02_alt.jpg)

![Malleability](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-02.jpg)

The word *malleate* means to form—for example, metal with a hammer. This term is used in cryptography to mean changing a signature without making it invalid or changing an encrypted message without making it totally garbled.

Qi wants to mess things up. When she receives your transaction Tx2, she modifies it in a certain way into Tx2M, so Tx2M is still valid and has the same effect as the original transaction, Tx2. (You’ll see shortly some different ways she can do this.) The result is that two different transactions now flow through the network that spend the same outputs and send the money to the same recipients with the same amounts—but they have *different txids*.

Because Tx2 and Tx2M spend the same outputs, they’re in conflict with each other, and at most one of them will be confirmed. Suppose Tx2M is the winner and gets mined in the next block. What happens to your daughter’s inheritance? See [figure 10.3](/book/grokking-bitcoin/chapter-10/ch10fig03).

![Figure 10.3. The inheritance fails because your daughter’s time-locked transaction is forever invalid due to transaction malleability.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/10fig03_alt.jpg)

The *malleated* transaction, Tx2M, is stored in the blockchain. This makes Tx2 invalid because it spends the same output as Tx2M. The first input of the time-locked transaction, Tx3, references Tx2 using its txid, so when 30 April 2020 has passed, your daughter won’t be able to claim her inheritance: she’ll be trying to spend an output from an invalid transaction.

##### How can Qi change the txid?

Qi has several options for changing the transaction without invalidating it. They all involve changing the signature script in one way or another. [Figure 10.4](/book/grokking-bitcoin/chapter-10/ch10fig04) shows three classes of transaction malleability.

![Figure 10.4. Three classes of transaction malleability](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/10fig04_alt.jpg)

![BIP66](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-01.jpg)

BIP66 fixes the first class of malleability issues.

The first one modifies the signature container format, which changes how the signature is *encoded* in the signature script. You can encode the signature in a few different ways that are all valid. This issue was fixed in a system upgrade by using BIP66, which requires all signatures to be encoded in a specific way. The fix was activated in block 363724.

The second way to malleate a transaction is to use cryptographic tricks. I won’t go into details here, but the signature, regardless of the container format, can be modified in a few ways that don’t make it invalid. Only one such trick is known, but we can’t rule out that there are others.

The last approach is about changing the script program itself. You can do this in several ways. The one in [figure 10.4](/book/grokking-bitcoin/chapter-10/ch10fig04) first duplicates (`OP_DUP`) the top item on the stack and then immediately removes (`OP_DROP`) the duplicate from the stack; effectively, this change does nothing, and the whole program will run just fine.

The second and third forms of transaction malleability are somewhat limited by *relay policies*. This means nodes will require that the signatures conform to specific rules and that no script operators except data pushes be present in the signature script. Otherwise, the node won’t relay the transaction. But nothing is stopping a miner from mining malleated transactions. Relay policies are implemented to make transaction malleability harder, but they can’t prevent it.

#### Inefficient signature verification

When a transaction is signed, the signature algorithm hashes the transaction in a certain way.

Remember from “[Signing the transaction](/book/grokking-bitcoin/chapter-5/ch05lev3sec3)” in [chapter 5](/book/grokking-bitcoin/chapter-5/ch05) that you clean all signature scripts before signing. But if you did *just* that, all the transaction’s signatures would use the exact same hash. If the transaction spent two different outputs that pay to the same address, the signature in one of the inputs could be reused in the other input. That property could be exploited by bad actors.

![Why not use a dummy byte?](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-02.jpg)

Inserting the pubkey script into the signature script seems unnecessary. It’d be simpler to add a single dummy byte in the signature script to avoid signature reuse. No one really knows why the pubkey script is used for this.

To avoid this problem, Bitcoin makes each signature commit to a slightly different version of the transaction by copying the spent pubkey script into the signature script of the input that’s currently being signed.

Let’s zoom in a bit on what’s happening. Suppose you want to sign a transaction with two inputs. The first input is signed as illustrated in [figure 10.5](/book/grokking-bitcoin/chapter-10/ch10fig05).

![Figure 10.5. Signing the first input. You prepare by copying the pubkey script to the signature script.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/10fig05_alt.jpg)

The signature scripts of all inputs are empty, but you copy the pubkey script of the spent output and insert it into the signature script of the spending input. You then create the signature for the first input and move on to sign the second input ([figure 10.6](/book/grokking-bitcoin/chapter-10/ch10fig06)).

![Figure 10.6. Signing the second input](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/10fig06_alt.jpg)

Here, all signature scripts except the second one are empty. The second signature script is populated with the spent output’s pubkey script. The signature is then created.

By doing this exercise for each input, you ensure that signatures aren’t reusable across inputs if signed by the same private key. But this also introduces a problem: signature verification becomes inefficient.

Suppose you want to verify the signatures of the aforementioned transaction. For every input, you need to perform basically the same procedure as when the transaction was signed: clean all the signature scripts from the transaction and then, one at a time, insert the pubkey script in the signature script of the input you want to verify. Then, verify the signature for that input.

This might seem harmless, but as the number of inputs grows, the amount of data to hash for each signature increases. If you double the number of inputs, you roughly

- Double the number of signatures to verify
- Double the size of the transaction

![Why 1 ms?](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-02.jpg)

The 1 ms time is just an example. The actual time to verify a transaction varies among nodes.

If the time to verify the transaction with two inputs in [figure 10.7](/book/grokking-bitcoin/chapter-10/ch10fig07) is 1 ms, it will take 4 ms to verify a transaction with four inputs. Double the number of inputs again, and you have 16 ms. A transaction with 1,024 inputs would take more than 4 minutes!

![Figure 10.7. Total time for hashing during signature verification. Time roughly quadruples when the number of inputs doubles.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/10fig07_alt.jpg)

This weakness can be exploited by creating a large transaction with a lot of inputs. All nodes verifying the transaction will be occupied for minutes, making them unable to verify other transactions and blocks during this time. The Bitcoin network as a whole would slow down.

It would be much better if the transaction verification time grew linearly instead of quadratically: the time to verify a transaction would double as the number of inputs doubled. Then, the 1,024 inputs would take roughly 512 ms to verify instead of 4 minutes.

#### Waste of bandwidth

When a full node sends a transaction to a lightweight wallet, it sends the complete transaction, which includes all signature data. But a lightweight wallet can’t verify the signatures because it doesn’t have the spent outputs.

The signature scripts constitute a large percentage of the transaction size. A typical signature script spending a p2pkh output takes 107 bytes. Consider a few different transactions with two outputs, as [table 10.1](/book/grokking-bitcoin/chapter-10/ch10table01) shows.

##### Table 10.1. Space occupied by signature script data of different typical transactions[(view table figure)](https://drek4537l1klr.cloudfront.net/rosenbaum/HighResolutionFigures/table_10-1.png)

| Inputs | Total signature script size (bytes) | Tx size (bytes) | Signature script percentage |
| --- | --- | --- | --- |
| 1 | 107 | 224 | 47% |
| 2 | 214 | 373 | 57% |
| 3 | 321 | 521 | 61% |
| 8 | 856 | 1,255 | 68% |

Wouldn’t it be nice if a full node didn’t have to send the signature script data to the lightweight wallet? You’d probably save more than 50% data traffic. There’s just one problem: such data is needed to calculate txids. If you skip sending signature scripts of transactions, the lightweight wallet won’t be able to verify that the transaction is included in a block because it can’t verify the merkle proof ([figure 10.8](/book/grokking-bitcoin/chapter-10/ch10fig08)).

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0340-01.jpg)

![Figure 10.8. Without the signature scripts, a lightweight wallet can’t verify that a transaction is included in the block.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/10fig08_alt.jpg)

We’d definitely like to solve this somehow.

#### Script upgrades are hard

Sometimes, we want to extend the script language with new operations. For example, `OP_CHECKSEQUENCEVERIFY` (`OP_CSV`) and `OP_CHECKLOCKTIMEVERIFY` (`OP_CLTV`) were introduced in the language in 2015 and 2016. Let’s look at how `OP_CLTV` was introduced.

We’ll start with what `OP_` codes are. They’re nothing but a single byte. `OP_EQUAL` for example, is represented by the byte `87` in hex code. Every node knows that when it encounters byte `87` in the script program, it needs to compare the top two items on the stack and push the result back on the stack. `OP_CHECKMULTISIG` is also a single byte, `ae`. All operators are represented by different bytes.

When Bitcoin was created, several NOP operators, `OP_NOP1`–`OP_NOP10`, were specified. These are represented by the bytes `b0`–`b9`. They’re designed to do nothing. The name NOP comes from No OPeration, which basically means, “When this instruction appears, ignore it and move on.”

These NOPs can be used to extend the script language, but only to a certain extent. The `OP_CLTV` operator is actually `OP_NOP2`, or byte `b1`. `OP_CLTV` was introduced by releasing a version of Bitcoin Core that redefines how `OP_NOP2` works. But it needs to be done in a compatible way so we don’t break compatibility with old, non-upgraded nodes.

Let’s go back to the example from “[Absolute time-locked outputs](/book/grokking-bitcoin/chapter-9/ch09lev2sec3)” in [chapter 9](/book/grokking-bitcoin/chapter-9/ch09), where you gave your daughter an allowance in advance that she could cash out on 1 May (see [figure 10.9](/book/grokking-bitcoin/chapter-10/ch10fig09)).

![Figure 10.9. Using OP_CLTV to lock an output until 1 May](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/10fig09_alt.jpg)

The pubkey script for this output is

```
<1 may 2019 00:00:00> OP_CHECKLOCKTIMEVERIFY OP_DROP
OP_DUP OP_HASH160 <PKHD> OP_EQUALVERIFY OP_CHECKSIG
```

This is how a new node—which is aware of the new meaning of byte `b1`—interprets the script. It will do the following:

1. Push the time `<1 may 2019 00:00:00>` to the stack.
1. Check that the spending transaction’s lock time has at least the value found on top of the stack, or fail immediately otherwise.
1. Drop the time value from the stack.
1. Continue with normal signature verification.

An old node, on the other hand, will interpret the script as follows:

```
<1 may 2019 00:00:00> OP_NOP2 OP_DROP
OP_DUP OP_HASH160 <PKHD> OP_EQUALVERIFY OP_CHECKSIG
```

It will

1. Push the time `<1 may 2019 00:00:00>` to the stack.
1. *Do nothing*.
1. Drop the time value from the stack.
1. Continue with normal signature verification.

Old nodes still treat `OP_NOP2` as they used to—by doing nothing and moving on. They aren’t aware of the new rules associated with the byte `b1`.

The old and the new nodes will behave the same if the `OP_CLTV` succeeds on the new node. But if the `OP_CLTV` fails on the new node, the old node won’t fail, because “do nothing” never fails. The new nodes fail more often than the old nodes because new nodes have stricter rules. The old nodes will always finish the script program with success whenever the new nodes finish with success. This is known as a *soft fork*—a system upgrade that doesn’t require all nodes to upgrade. We’ll talk more about forks, system upgrades, and alternate currencies born from Bitcoin’s blockchain in [chapter 11](/book/grokking-bitcoin/chapter-11/ch11).

You might be wondering what the `OP_DROP` instruction is for. `OP_DROP` takes the top item on the stack and discards it. `OP_CLTV` is designed to behave exactly like `OP_NOP2` when it succeeds. If `OP_CLTV` had been designed without taking old nodes into account, it would probably remove the top item from the stack. But because we need to take old nodes into account, `OP_CLTV` doesn’t do that. We must add the extra `OP_DROP` after `OP_CLTV` to get rid of the time item from the stack.

This was an example of how old script operators can be repurposed to do something stricter without disrupting the entire network.

This method of script upgrades has been done for two operators so far:

| Byte | Old code | New code | New meaning |
| --- | --- | --- | --- |
| b1 | OP_NOP2 | OP_CLTV | Verify that the spending transaction has a high enough absolute lock time. |
| b2 | OP_NOP3 | OP_CSV | Verify that the spending input has a high enough relative lock time. |

Only 10 `OP_NOP` operators are available to use for script upgrades, and such upgrades are limited to exactly mimic the `OP_NOP` behavior if they don’t fail.

Sooner or later, we’ll need another script-upgrade mechanism, both because we’ll run out of `OP_NOP`s and because we want the new script operators to behave differently than `OP_NOP` when they succeed.

### Solutions

A solution to all these problems was presented at a 2015 conference. The solution was to move the signature scripts out of transactions altogether.

Let’s look again at the anatomy of a normal transaction, shown in [figure 10.10](/book/grokking-bitcoin/chapter-10/ch10fig10).

![Figure 10.10. The txid is calculated from the entire transaction, including signature scripts.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/10fig10_alt.jpg)

If we could change the system so the txid didn’t cover the signature script, we’d remove all known possibilities of unintentional transaction malleability. Unfortunately, if we did this, we’d make old software incompatible because it calculates the txid in the traditional way.

![BIP141](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-01.jpg)

The new rules defined by segregated witness are specified in BIP141, “Segregated Witness (Consensus layer).”

Segwit solves this problem and all the aforementioned problems in a forward- and backward-compatible way:

- Forward-compatible because blocks created by new software work with old software
- Backward-compatible because blocks created by old software work with new software

In crypto-lingo, a *witness* basically means a signature. It’s something that attests to the authenticity of something. For a Bitcoin transaction, the witness is the contents of the signature scripts, because that’s what proves the transaction is authenticated. *Segregated* means parted, so we part the contents of the signature scripts from the transaction, effectively leaving the signature scripts empty, as [figure 10.11](/book/grokking-bitcoin/chapter-10/ch10fig11) shows.

![Figure 10.11. A segwit transaction contains no signature data. The signatures are attached, instead. The txid doesn’t commit to the signatures.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/10fig11_alt.jpg)

***Segregated witness* thus means the contents of the signature scripts are removed from the transaction and put into an external structure called the witness**.

We’ll follow a few segwit transactions to see how they affect the different parts of the Bitcoin system. But first, let’s get some bitcoin into a segwit wallet.

#### Segwit addresses

Suppose your wallet uses segwit, and you’re selling a laptop to Amy. Your wallet needs to create an address that you can give to Amy. So far, nothing new.

![BIP173](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-01.jpg)

This BIP defines the checksummed encoding scheme Bech32 and how segwit addresses are composed and encoded using Bech32.

But segwit defines a new address type that’s encoded using *Bech32* instead of base58check. Suppose your wallet creates the following segwit address:

```
bc1qeqzjk7vume5wmrdgz5xyehh54cchdjag6jdmkj
```

This address format provides several improvements compared to the base58check addresses you’re used to:

- All characters are of the same case, which means

- QR codes can be made smaller.
- Addresses are easier to verbally read out.

- The checksum used in Bech32 will detect up to four character errors with 100% certainty. If there are more character errors, the probability of detection failure is less than one in a billion. This is a major improvement to the 4-byte checksum in base58check, which doesn’t provide any guarantee.

Your segwit address consists of two parts. The first two characters, `bc` (short for bitcoin) is the *human-readable part*. The `1` is a delimiter between the human-readable part and the *data part*, which encodes the actual information that Amy will use to create the transaction output:

- A version, 0 in this case.
- A *witness program*. In this case, the witness program is a PKH, `c8052b79...3176cba8`.

We’ll explain what the witness program is a bit further on. Think about it as a PKH for now. The version and witness program aren’t directly extractable from the address because they’re encoded using bech32. You give the address `bc1qeqzj...ag6jdmkj` to Amy by showing her a QR code. She has a modern wallet that understands this address format, so she scans your address and extracts the version and witness program, as [figure 10.12](/book/grokking-bitcoin/chapter-10/ch10fig12) illustrates.

![Figure 10.12. Amy decodes the segwit address to get the witness version and the witness program.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/10fig12_alt.jpg)

![Checksum](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-01.jpg)

I won’t go into details on the checksum. I encourage the interested reader to read BIP173.

This occurs in multiple steps:

- ***1*** The human-readable part and the data part are separated.
- ***2*** The data part of the address is converted, character by character, into numbers using a base32 lookup table. The first of these numbers is the witness version, `0`. The following numbers, except the last six, are the witness program. The last six numbers are the checksum.
- ***3*** The checksum is verified; no errors were detected in this example.
- ***4*** The witness program is rewritten by writing each number as a 5-bit number.
- ***5*** The bits are rearranged in groups of 8 bits. Each such group represents a byte of the witness program.
- ***6*** Amy extracts the witness program as `c8052b7...3176cba8`.

Amy creates a transaction with a new kind of pubkey script that you aren’t used to ([figure 10.13](/book/grokking-bitcoin/chapter-10/ch10fig13)).

![Figure 10.13. Amy sends 0.1 BTC to your segwit address. The pubkey script doesn’t contain any script operators, just data.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/10fig13_alt.jpg)

She broadcasts this transaction on the Bitcoin network. The network will accept the transaction because it’s correctly signed in the old-fashioned way. Eventually, it will be confirmed in a block. Your wallet will acknowledge that you’ve received the money, and you’ll give the laptop to Amy.

#### Spending your segwit output

Now that you’ve received your money, you want to spend it on a used popcorn machine. It costs only 0.09 BTC. It’s a bargain! Suppose the owner of the popcorn machine has the segwit address `bc1qlk34...ul0qwrqp`.

Your transaction sends the money to the popcorn machine owner’s segwit address and pays a 0.01 BTC transaction fee ([figure 10.14](/book/grokking-bitcoin/chapter-10/ch10fig14)). The input has an empty signature script; the signature data is instead added as a *witness field* in the attached witness.

![Figure 10.14. You create and broadcast a payment to the popcorn machine owner.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/10fig14_alt.jpg)

Had there been multiple inputs in this transaction, there would be multiple witness fields in the witness, one for each input. You can mix segwit inputs and legacy inputs, in which case the witness fields for the legacy inputs would be empty because their signatures are in the respective signature script, as they always were.

#### Verifying the segwit transaction

You’ve sent your transaction for the popcorn machine to the Bitcoin peer-to-peer network for processing. Let’s see how an upgraded full node verifies this transaction before relaying it to other nodes ([figure 10.15](/book/grokking-bitcoin/chapter-10/ch10fig15)). Because it’s running the latest and greatest software, it knows how to deal with segwit transactions.

![Figure 10.15. A full node verifies your transaction’s witness. The pattern 00 followed by exactly 20 bytes gets special treatment.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/10fig15_alt.jpg)

![Remember p2sh](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-02.jpg)

A segwit output is recognized by pattern matching, just like a p2sh output was in [chapter 5](/book/grokking-bitcoin/chapter-5/ch05).

The full node, which knows about segwit, looks for a pattern in the pubkey script starting with a single version byte followed by a 2- to 40-byte witness program. In this case, the pattern matches, which means this is a segwit output.

The next step for the full node is to understand what *kind* of segwit output it is. As of this writing, there’s only one version of segwit output: version `00`. This version comes in two different flavors:

- *Pay-to-witness-public-key-hash* *(p2wpkh)*, identified by a 20-byte witness program, as in this example
- *Pay-to-witness-script-hash (p2wsh)*, identified by a 32-byte witness program. p2wsh will be explained later in this chapter.

![Why “witness program”?](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-02.jpg)

It’s called a witness program because it can be regarded as a program of a weird language. In version 00, the witness program is a single operator whose length defines its behavior.

In this case, we have the version byte `00` followed by exactly 20 bytes, which means this is a p2wpkh payment. If the version byte is unknown to the node, the node will immediately accept this input without further processing. This acceptance of unknown versions will become useful for future, forward-compatible upgrades of the script language. All segwit nodes will recognize version `00`.

The p2wpkh is the simplest of the two types because it’s similar to the well-known p2pkh. Let’s look at how they both work:

- *p2pkh*—The pubkey script contains the actual script that checks the signature in the signature script.
- *p*2*wpkh*—The actual script is a predetermined template, and the witness program *is* the PKH to insert into the script template. The signature and the public key are taken from the witness.

In the end, it’s seemingly the exact same program that is run for both of these two types. The difference is where the components come from. But other differences exist between segwit scripts and legacy scripts—for example, the meaning of `OP_CHECKSIG` has changed, as you’ll see in “[New hashing method for signatures](/book/grokking-bitcoin/chapter-10/ch10lev2sec10).”

Why do p2wpkh at all when we’re running the exact same script program as in p2pkh? Recall that we want to solve transaction malleability. We do this by removing the signature data from the transaction inputs so no one can change the txid by making subtle changes to the signature script.

The full node has verified this transaction and sends it to its peers. There’s just one problem: one peer has no idea what segwit is. It’s an old node that hasn’t been upgraded for a while.

##### “Verifying” on old nodes

An old node has just received your transaction and wants to verify it. Old nodes know nothing about segwit or that there are witnesses attached to transactions. The old node downloads the transaction as it always has, which is without the witness attachment. [Figure 10.16](/book/grokking-bitcoin/chapter-10/ch10fig16) shows what the node sees.

![Figure 10.16. An old node sees just two data items in the pubkey script and an empty signature script.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/10fig16_alt.jpg)

Because the node doesn’t know anything else, it creates the script program by taking the empty signature script and appending the pubkey script. The resulting program looks like this:

```
00 c8052b799cde68ed8da8150c4cdef4ae3176cba8
```

The node runs this program. The program puts two data items on the stack—first `00`, and then the `c805...cba8`. When it’s done, there’s nothing left to do but check whether the top item on the stack, `c805...cba8`, is `true`. Bitcoin defines anything that’s nonzero to be true, so this script will pass, and the transaction is authorized.

This doesn’t seem very secure. This is known as an *anyone-can-spend*, meaning anyone can create a transaction that spends the output. It requires no signature. You just have to create an input with an empty signature script to take the money.

![Nonstandard transactions](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-01.jpg)

A node that doesn’t recognize the spent script type normally doesn’t relay the transaction. It’s considered nonstandard. This relay policy reduces the risk that a transaction that uses the segwit output as an anyone-can-spend ends up in a block.

In [chapter 11](/book/grokking-bitcoin/chapter-11/ch11), we’ll talk about how to deploy upgrades like segwit safely. For now, you can assume that 95% of the hashrate (miners) run with segwit. If a transaction uses your output as an anyone-can-spend, and a non-segwit miner includes it in a block, then this block will be rejected by 95% of the hashrate and consequently excluded from the strongest chain. The miner will lose its block reward.

#### Including your segwit transaction in a block

Your segwit transaction has propagated through the network, and all nodes have verified it along the way. Now, a miner wants to insert the transaction into a new block. Suppose the miner runs modern software and thus knows about segwit. Let’s look at how it’s included in the block ([figure 10.17](/book/grokking-bitcoin/chapter-10/ch10fig17)).

![Figure 10.17. Your segwit transaction gets included in a block. The block commits to the witnesses by putting the witness commitment into an output of the coinbase transaction.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/10fig17_alt.jpg)

The block is built as before, but with one important difference. A new block rule is introduced in segwit: if there are segwit transactions in the block, the coinbase transaction must contain an output with a *witness commitment*. This witness commitment is the combined hash of the *witness root hash* and a *witness reserved value*. The witness root hash is the merkle root of the *witness txids* (*wtxids*) of all transactions in the block. The wtxid is the hash of the transaction *including the witness*, if there is one. An exception exists for the coinbase, whose wtxid is always defined as 32 zero bytes. The witness reserved value is dedicated for future system upgrades.

The witness commitment is written in an `OP_RETURN` output ([figure 10.18](/book/grokking-bitcoin/chapter-10/ch10fig18)).

![Figure 10.18. The coinbase transaction’s witness contains the witness reserved value, and an OP_RETURN output contains the witness commitment.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/10fig18_alt.jpg)

The witness reserved value can be any value. But a full node verifying this block needs a way to know what that value is. If the node didn’t know the witness reserved value, it wouldn’t be able to reconstruct the witness commitment for comparison with the `OP_RETURN` output’s witness commitment. The coinbase transaction’s witness contains the witness reserved value so full nodes can verify the witness commitment.

##### Old nodes verifying the block

The block in [figure 10.17](/book/grokking-bitcoin/chapter-10/ch10fig17) is valid for new segwit-enabled full nodes, so it must also be valid for old nodes that don’t know what segwit is. An old node won’t download any witnesses from its peers because it doesn’t know they exist ([figure 10.19](/book/grokking-bitcoin/chapter-10/ch10fig19)).

![Figure 10.19. An old node verifies the block with your transaction. It won’t verify the signatures or the witness commitment.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/10fig19_alt.jpg)

This node will do what it’s always done—run the scripts of the transactions, which will look like spending anyone-can-spend outputs. That’s OK, move on. If some of the transactions in the block are non-segwit, those transactions will be fully verified.

We’ve now gone full circle with your transaction to the popcorn machine owner, who hands over the machine to you.

#### Pay-to-witness-script-hash

Do you remember when we introduced p2sh in the “[Pay-to-script-hash](/book/grokking-bitcoin/chapter-5/ch05lev2sec9)” section of [chapter 5](/book/grokking-bitcoin/chapter-5/ch05)? p2sh moves the pubkey script part of the program to the spending input. Let’s have another look at the charity wallet that John, Ellen, and Faiza set up ([figure 10.20](/book/grokking-bitcoin/chapter-10/ch10fig20)).

![Figure 10.20. John and Faiza spend an output from their multisig wallet.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/10fig20_alt.jpg)

The idea here was that the payer—the donor, in this case—shouldn’t have to pay a higher fee for a big, complex pubkey script. Instead, the recipient wanting to use this fancy scheme will pay for the complexity.

With segwit, you can do about the same thing using pay-to-witness-script-hash, which is the segwit version of p2sh. Isn’t naming in Bitcoin fantastic?

Suppose John, Ellen, and Faiza use segwit for their charity wallet and that the previous popcorn machine owner wants to give the money he received for the popcorn machine to the charity.

John, Ellen, and Faiza must provide the popcorn guy with a p2wsh address. Their *witness script* is the same as their p2sh *redeem script* was when they were using p2sh ([figure 10.21](/book/grokking-bitcoin/chapter-10/ch10fig21)).

![Figure 10.21. The witness script is hashed into a witness script hash.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/10fig21_alt.jpg)

They use this witness script hash to create a p2wsh address in the same way you created your p2wpkh address. They encode

```
00 983b977f86b9bce124692e68904935f5e562c88226befb8575b4a51e29db9062
```

using Bech32 and get the p2wsh address:

```
bc1qnqaewluxhx7wzfrf9e5fqjf47hjk9jyzy6l0hpt4kjj3u2wmjp3qr3lft8
```

This address is handed to the popcorn guy, who creates and broadcasts a transaction like that shown in [figure 10.22](/book/grokking-bitcoin/chapter-10/ch10fig22).

![Figure 10.22. The popcorn guy sends the money to the charity’s p2wsh address.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/10fig22_alt.jpg)

The transaction has the witness attached, just like your transaction to the popcorn guy. The only difference between your transaction and the popcorn guy’s transaction is that their outputs have a different witness program length. Your transaction had a 20-byte witness program because it was a SHA256+RIPEMD160 hash of a public key, and the popcorn guy’s transaction has a 32-byte witness program because that’s the SHA256 hash of a witness script.

This transaction will be verified and eventually included in a block.

##### Spending the p2wsh transaction

Suppose John and Faiza want to spend the 0.08 BTC they got from the popcorn guy by sending it to a shelter for homeless people. The shelter happens to also have a p2wsh address. John and Faiza collaborate to create the transaction [figure 10.23](/book/grokking-bitcoin/chapter-10/ch10fig23) shows.

![Figure 10.23. The charity pays 0.07 BTC to the shelter’s address. The witness is the signatures followed by a data item that contains the actual witness script.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/10fig23_alt.jpg)

Note how there’s nothing in the signature script. When we used p2sh in [chapter 5](/book/grokking-bitcoin/chapter-5/ch05)’s “[Pay-to-script-hash](/book/grokking-bitcoin/chapter-5/ch05lev2sec9),” the signature script got really big because it contained two signatures and the redeem script, which in turn contained three public keys. With segwit, all data is contained in the witness instead.

##### Verifying the p2wsh input

A full node that wants to verify this transaction needs to determine the type of output being spent ([figure 10.24](/book/grokking-bitcoin/chapter-10/ch10fig24)). It looks at the output, finds the pattern `<version byte> <2 to 40 bytes data>`, and concludes that this is a segwit output. The next thing to check is the value of the version byte.

![Figure 10.24. Preparing to verify the p2wsh input](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/10fig24_alt.jpg)

The version byte is `00`. A version `00` segwit output can have two different lengths of the witness program, 20 or 32 bytes. We covered the first one in the previous sections on p2wpkh. The witness program in this example is 32 bytes, which means this is a p2wsh output.

Special rules apply when spending a p2wsh output. First, the data items in the spending input’s witness field are pushed onto the program stack. Then, the top item on the stack, the witness script, is verified against the witness program in the output ([figure 10.25](/book/grokking-bitcoin/chapter-10/ch10fig25)).

![Figure 10.25. Verifying the witness of a p2wsh payment](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/10fig25_alt.jpg)

The witness script is hashed and compared to the witness program in the spent output before being executed with the three items on the stack. This process is similar to that of verifying a p2sh payment.

Miners and block verifiers handle all segwit transactions the same way, so there’s no difference in how the transaction is included in a block compared to p2wpkh transactions.

![BIP143](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-01.jpg)

This solution is specified in BIP143, “Transaction Signature Verification for Version 0 Witness Program.”

#### New hashing method for signatures

One problem that segwit solves is inefficient signature hashing. As explained in “[Inefficient signature verification](/book/grokking-bitcoin/chapter-10/ch10lev2sec2),” if the number of inputs doubles, the time it takes to verify the transaction roughly quadruples. This is because you

- Double the number of signatures to verify
- Double the transaction’s size

![This algorithm is simplified](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-01.jpg)

In reality, three different intermediate hashes are created: one for all outpoints, one for all sequence numbers, and one for all outputs. However, the effect is the same. Read BIP143 for details.

If you double the number of hashes performed *and* double the amount of data each hash needs to process, you effectively quadruple the total time spent on hashing.

The solution is to make the signatures in steps. Suppose you want to sign all four inputs of a transaction, as [figure 10.26](/book/grokking-bitcoin/chapter-10/ch10fig26) shows.

![Figure 10.26. Hashing is done in two steps. The intermediate hash is reused for each input.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/10fig26_alt.jpg)

First you create an intermediate hash of the complete transaction. If the transaction contains non-segwit inputs, those signature scripts will be cleaned prior to hashing. The intermediate hash commits to all of that transaction’s inputs and outputs. Then, for each input, add the intermediate hash to some input-specific data:

- *Spent outpoint*—The txid and index of the output this input spends
- *Spent script*—The witness script or p2wpkh script corresponding to the spent output
- *Spent amount*—The BTC value of the spent output

The bulk of the transaction is hashed only once to create the intermediate hash. This drastically reduces the amount of hashing needed. When the number of inputs doubles, the needed amount of hashing only doubles. This makes the hashing algorithm perform *linearly with the number of inputs* instead of *quadratically*. The time to verify the transaction with 1,024 inputs discussed in [figure 10.7](/book/grokking-bitcoin/chapter-10/ch10fig07) is reduced from 262,144 ms to 512 ms.

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0358-01.jpg)

##### Signature commits to amount

Why do we include the spent amount? We didn’t do that in the old signature-hashing algorithm. This has nothing to do with hashing efficiency, but it fixes yet another problem that offline wallets and some lightweight wallets face.

![Hardware wallets](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-02.jpg)

A *hardware wallet* is an electronic device designed to keep private keys safe. Unsigned transactions are sent to the device for signing. The device usually requires a PIN code to sign.

An offline wallet—for example, a hardware wallet—can’t know how much money is being spent. If the offline wallet is to sign a transaction, the wallet can’t display the transaction’s fee amount to the user because it can’t see the values of the outputs it’s spending ([figure 10.27](/book/grokking-bitcoin/chapter-10/ch10fig27)). It has no access to the blockchain.

![Figure 10.27. An offline wallet can’t know a transaction’s fee.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/10fig27_alt.jpg)

This is true for both non-segwit and segwit transactions. But with segwit transactions, when the signatures commit to the spent output amounts, the wallet must get the amounts from somewhere to be able to sign. Suppose the input amounts are somehow provided to the offline wallet, alongside the transaction to sign. The wallet can then sign the transaction using those amounts and even show the user what fee is being paid before signing.

If the offline wallet receives the wrong amount, it won’t be able to tell. It can’t verify the input values. But because the signatures now cover the amounts, the transaction will be invalid. A verifying node will know the correct amounts and use them when verifying the signatures. The signature check will fail. The new signature hashing algorithm makes it impossible to trick a wallet into signing a valid transaction with a fee the user didn’t intend.

#### Bandwidth savings

Segwit removes the signature data from the transaction, so when a lightweight wallet requests a transaction from a full node, the full node can send the transaction without the witness data. This means less data traffic is needed per transaction. This fact can be used to either

- Keep the bloom filter size as is and get about 50% reduction in data traffic
- Improve privacy by decreasing the size of the bloom filter to get more false positives without increasing data traffic

#### Upgradable script

The version byte is used for future script language upgrades. Before segwit, we had to use the `OP_NOP`s to introduce new features to the language—for example, `OP_CSV`. This wasn’t optimal for the following reasons:

- We might run out of `OP_NOP`s—there are eight left.
- The `OP_NOP`s can’t be redefined in arbitrary ways; they still need to behave as `OP_NOP`s in case the new behavior succeeds.

The version byte allows for much more powerful future upgrades. We can do anything from slight modifications of specific operators to implementing completely new languages.

### Wallet compatibility

Most old wallets won’t support sending bitcoin to a segwit address. They usually only allow p2pkh and p2sh addresses. So segwit’s developers created *p2wsh nested in p2sh* and *p2wpkh nested in p2sh*: ways to trigger the segwit verification instead of the legacy script verification.

Suppose you have a segwit wallet and want to sell your popcorn machine to your neighbor, Nina. But Nina doesn’t have a segwit-aware wallet. She can only pay to ordinary addresses, like p2pkh and p2sh. You can make a p2sh address that Nina can pay to ([figure 10.28](/book/grokking-bitcoin/chapter-10/ch10fig28)).

![Figure 10.28. Nina sends 0.1 BTC to your segwit wallet using a p2wpkh inside a p2sh address.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/10fig28_alt.jpg)

Nina pays to `3KsJCgA6...k2G6C1Be`, which is an old-style p2sh address that contains the hash of the redeem script `00 bb4d4977...75ff02d1`. This redeem script is a version byte `00` followed by a 20-byte witness program. This is the pattern for p2wpkh, which we covered earlier. Nina’s wallet knows nothing about this. It sees only a p2sh address and makes a payment to that script hash.

Later, when you want to spend your output, you create a transaction like the one in [figure 10.29](/book/grokking-bitcoin/chapter-10/ch10fig29).

![Figure 10.29. You spend the money you got from Nina by setting the version byte and witness program in the redeem script in your input’s signature script.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/10fig29_alt.jpg)

You create a witness, just as you would with a normal p2wpkh input, but you also set the redeem script as a single data item in the signature script. The redeem script happens to be a version byte followed by your 20-byte PKH. Using this signature script, old nodes can verify that the script hash in the spent output matches the hash of the redeem script in the signature script. New nodes will detect that the redeem script is a version byte and a witness program, and verify the witness accordingly.

This way of nesting a segwit payment inside a p2sh payment can also be used for p2wsh payments in a similar fashion: a p2wsh nested in p2sh.

### Recap of payment types

We’ve talked about several types of payments. [Figures 10.30](/book/grokking-bitcoin/chapter-10/ch10fig30)–[10.35](/book/grokking-bitcoin/chapter-10/ch10fig35) summarize the most common ones.

![Figure 10.30. p2pkh: address format 1<some base58 characters>](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/10fig30_alt.jpg)

![Figure 10.31. p2sh: address format 3<some base58 characters>](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/10fig31_alt.jpg)

![Figure 10.32. p2wpkh: address format bc1q<38 base32 characters>](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/10fig32_alt.jpg)

![Figure 10.33. p2wsh: address format bc1q<58 base32 characters>](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/10fig33_alt.jpg)

![Figure 10.34. p2wpkh nested in p2sh: address format 3<some base58 characters>](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/10fig34_alt.jpg)

![Figure 10.35. p2wsh nested in p2sh: address format 3<some base58 characters>](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/10fig35_alt.jpg)

### Block limits

Bitcoin blocks are limited to 1,000,000 bytes in size and 20,000 signature operations.

#### Block size limit

In 2010, the Bitcoin software was updated with a block size limit of 1,000,000 bytes. It isn’t totally clear why this was done, but most people think the limit was introduced to reduce the impact of certain denial of service (DoS) attacks. DoS attacks aim at stalling or crashing Bitcoin nodes so the network can’t function properly.

One way to mess with the network is to create a very large block that takes 10 seconds to download on a good internet connection. This might seem fast enough, but uploading this block to five peers will take 50 seconds. This will cause the block to propagate very slowly across the peer-to-peer network, which will increase the risk of an unintended blockchain split. Unintended splits will resolve with time, as you saw in the section “[Drawing lucky numbers](/book/grokking-bitcoin/chapter-7/ch07lev2sec2)” in [chapter 7](/book/grokking-bitcoin/chapter-7/ch07), but Bitcoin’s overall security will decrease during such splits.

Another potential problem with big blocks that attackers could exploit is that people with poor internet connections will be left out completely because they can’t keep up with the network, or they don’t have the required processing power, RAM, or disk storage space needed to run a full node. These people will need to switch to systems with less security, such as lightweight wallets, reducing the security of the whole network.

Regardless of the reason, this limit is in place.

#### Signature operations limit

The signature operations limit was put in place because signature-verification operations are relatively slow, especially in non-segwit transactions. An attacker could stuff a transaction with a tremendous number of signatures, causing verifying nodes to be busy verifying signatures for a long time. The limit of 20,000 such operations per block was somewhat arbitrarily chosen to prevent such an attack.

#### Increasing the limits

It will take a *hard fork* to remove or increase these limits. A hard fork is a rule change that causes old nodes and new nodes to disagree on what the strongest valid blockchain is. We’ll examine forks and upgrades in [chapter 11](/book/grokking-bitcoin/chapter-11/ch11). For now, suppose new nodes decide that 8,000,000-byte blocks are OK. When a miner publishes a block that’s bigger than 1,000,000 bytes, new nodes will accept it, whereas old nodes won’t. A permanent blockchain split will occur, and we’ll effectively have two different cryptocurrencies.

Segwit offers an opportunity to somewhat increase both these limits without a hard fork.

##### Increasing the block size limit

The old rule of 1,000,000 bytes remains, so old nodes can continue working as they used to. New nodes will count block size differently, but in a compatible way. Witness bytes will be counted with a “discount” compared to other bytes, such as the block header or transaction outputs. A new measurement, *block weight*, is put in place. A block’s maximum weight is 4,000,000 *weight units* (WU; [figure 10.36](/book/grokking-bitcoin/chapter-10/ch10fig36)).

![Figure 10.36. Witness bytes and nonwitness bytes are counted differently. Witness bytes contribute less to the block weight and not at all to the traditional block size, the base block size.](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/10fig36_alt.jpg)

Let’s call the block excluding the witnesses the *base block*:

- 1 byte of base block data is counted as 4 WU.
- 1 byte of witness data is counted as 1 WU.

**The effect is that the old 1,000,000-byte block size limit remains because the new rule and the old rule are effectively the same on the base block. But the more segwit is used, the more data can be moved from the base block to the witnesses, which allows for a bigger total block size**.

Suppose the witnesses in a block account for ratio *r* of the data in a block. The maximum block weight is 4,000,000, and a total block size *T* gives

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0364-01.jpg)

Inserting various values of *r* into this formula gives different maximum total block sizes, as [table 10.2](/book/grokking-bitcoin/chapter-10/ch10table02) shows.

##### Table 10.2. Maximum block sizes for different ratios of witness data[(view table figure)](https://drek4537l1klr.cloudfront.net/rosenbaum/HighResolutionFigures/table_10-2.png)

| *r* (witness bytes/total bytes) | Max total block size (bytes) |
| --- | --- |
| 0 | 1,000,000 |
| 0.1 | 1,081,081 |
| 0.3 | 1,290,323 |
| 0.5 | 1,600,000 |
| 0.6 | 1,818,182 |
| 0.7 | 2,105,263 |
| 0.8 | 2,500,000 |

As the relative amount of witness data increases in the block, we can squeeze in more transactions. The effect is an actual maximum block size increase.

The witness discount is implemented for several reasons:

- The signature scripts and witnesses don’t go into the UTXO set. Data that goes into the UTXO set has higher costs because the UTXO set should preferably be stored in RAM for fast transaction verification.
- It gives wallet developers, exchanges, and smart contract developers more incentive to make fewer outputs, which reduces the UTXO set’s size. For example, an exchange can choose to consolidate its many outputs into a few outputs.
- The witnesses don’t have to be sent to a lightweight wallet.

##### Increasing the signature operations limit

Because we’re increasing the block size with segwit, we also need to increase the number of allowed signature operations; allowing more transaction data per block should imply that we also need to allow more signature operations. We can increase the limit in the same manner as we increased the block size limit.

We increase the number of allowed signature operations from 20,000 to 80,000 and count each legacy signature as four operations and each segwit operation as one operation. We count a segwit signature operation less than a legacy operation because the former is more efficient, as discussed in “[New hashing method for signatures](/book/grokking-bitcoin/chapter-10/ch10lev2sec10).”

This will have the same effect as the block size increase. If a block contains only legacy inputs, the old limit of 20,000 actual operations remains. If the block contains only segwit inputs, the new limit of 80,000 actual operations is in effect. Any combination of legacy and segwit inputs in a block will result in a limit somewhere between 20,000 and 80,000 actual signature operations.

### Recap

This chapter has walked through segregated witness, which solves some problems:

- *Transaction malleability*—A txid might change without changing the effect of its transaction. This can cause broken links between transactions, making the child transaction invalid.
- *Inefficient signature verification*—As the number of inputs doubles in a transaction, the time to verify the transaction increases quadratically. This is because both the transaction’s size and the number of signatures to verify doubles.
- *Wasted bandwidth*—Lightweight wallets must download the transactions, including all signatures, to be able to verify the merkle proof, but the signature data is useless to them because they don’t have the spent outputs to verify against.
- *Hard to upgrade*—There is limited room for script language upgrades. A handful of `OP_NOP`s are left, and you can’t change an `OP_NOP` however you please. If the new operator behavior succeeds, it must behave exactly as an `OP_NOP`.

#### Solutions

By moving signature data out of the base transaction, that data will no longer be part of the txid.

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0367-01_alt.jpg)

If the signature is malleated, it won’t affect the txid. Unconfirmed chains of transactions become unbreakable.

A new signature-hashing algorithm is used that makes the verification time grow *linearly* with the number of inputs. The old signature-hashing algorithm hashes the entire transaction for each signature.

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0367-02_alt.jpg)

Signatures in witnesses will hash the transaction only once.

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0367-03_alt.jpg)

The intermediate hash is reused for each signature, which greatly reduces the total amount of hashing.

The bandwidth that lightweight wallets require decreases because they don’t have to download the witnesses to verify that a transaction is included in a block. They can use the per-transaction savings to increase their privacy by decreasing their bloom filter size or to reduce data traffic with preserved privacy.

The witness version in the pubkey script allows for future upgrades of the script language. These upgrades can be arbitrarily complex with no restrictions on functionality.

New rules apply for blocks containing segwit transactions. An output in the coinbase transaction must commit to all the block’s witnesses.

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0368-01_alt.jpg)

Old nodes will still work because they aren’t aware of the commitment in the coinbase transaction. This let us introduce segwit without disrupting, or splitting, the blockchain into two separate cryptocurrencies.

### Exercises

#### Warm up

**[10.1](/book/grokking-bitcoin/appendix-b/app02qa11q0a1)**

What part of the transaction is the cause for transaction malleability?

**[10.2](/book/grokking-bitcoin/appendix-b/app02qa11q0a2)**

Why is transaction malleability a problem?

**[10.3](/book/grokking-bitcoin/appendix-b/app02qa11q0a3)**

Why do we say that legacy transaction verification time increases quadratically with the number of inputs?

**[10.4](/book/grokking-bitcoin/appendix-b/app02qa11q0a4)**

Why do lightweight wallets need the signatures of a legacy transaction to verify that it’s included in a block?

**[10.5](/book/grokking-bitcoin/appendix-b/app02qa11q0a5)**

Suppose you want to add a new feature to Bitcoin’s Script language, and you want to redefine the behavior of `OP_NOP5`. What’s important to think about when you design the new behavior to avoid a blockchain split (because not all nodes will upgrade simultaneously)?

**[10.6](/book/grokking-bitcoin/appendix-b/app02qa11q0a6)**

Which of the following are segwit addresses? What kind of segwit addresses are they?

1. `bc1qeqzjk7vume5wmrdgz5xyehh54cchdjag6jdmkj`
1. `c8052b799cde68ed8da8150c4cdef4ae3176cba8`
1. `bc1qnqaewluxhx7wzfrf9e5fqjf47hjk9jyzy6l0hpt4kjj3u2wmjp3qr3lft8`
1. `3KsJCgA6ubxgmmzvZaQYR485tsk2G6C1Be`
1. `00 bb4d49777d981096a75215ccdba8dc8675ff02d1`

**[10.7](/book/grokking-bitcoin/appendix-b/app02qa11q0a7)**

What’s the witness version used for? The witness version is the first number in a segwit output—for example, `00` in

```
00 bb4d49777d981096a75215ccdba8dc8675ff02d1
```

#### Dig in

**[10.8](/book/grokking-bitcoin/appendix-b/app02qa11q0a8)**

Explain how a segwit transaction is valid according to an old node that knows nothing about segwit. This is what the old node sees:

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0370-01_alt.jpg)

**[10.9](/book/grokking-bitcoin/appendix-b/app02qa11q0a9)**

Explain how a segwit transaction is verified by a new node that knows about segwit. This is what it sees:

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0370-02_alt.jpg)

**[10.10](/book/grokking-bitcoin/appendix-b/app02qa11q0a10)**

Suppose you want to upgrade the Bitcoin system. You want the witness commitment to commit to the transaction fees in the block, in addition to the witness root hash, by making a merkle tree of all transaction fees. Suggest how the fee merkle root could be committed to in the block without breaking compatibility with old nodes. You don’t have to think about future upgradability after this change, because that’s more complex. Use the following figure as a hint:

![](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/f0370-03_alt.jpg)

**[10.11](/book/grokking-bitcoin/appendix-b/app02qa11q0a11)**

How would old nodes and new nodes verify blocks that contain the commitment in the previous exercise?

### Summary

- Segwit moves signature script data out of transactions to solve transaction malleability issues.
- Segwit uses a new signature-hashing algorithm that makes transaction verification faster. This helps nodes stay up to date with less resources.
- Lightweight wallets get better privacy with preserved data traffic by not downloading witness data.
- The witness version byte of the pubkey script makes upgrading the script language easier.
- We can increase the maximum block size somewhat by counting witness bytes with a discount.
- A new address format helps wallets distinguish between legacy payments and segwit payments.
- Segwit can be “embedded” in old-style p2sh addresses to let old wallets send money to segwit wallets.
