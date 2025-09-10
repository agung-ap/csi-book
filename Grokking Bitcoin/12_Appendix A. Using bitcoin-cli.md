# Appendix A. Using bitcoin-cli

This appendix continues from “[Running your own full node](/book/grokking-bitcoin/chapter-8/ch08lev1sec7)” in [chapter 8](/book/grokking-bitcoin/chapter-8/ch08). I’ll show you how to set up a Bitcoin wallet, receive and send bitcoins, and explore the Bitcoin blockchain using `bitcoin-cli`, Bitcoin Core’s command-line tool.

Note that this appendix won’t go into great depth on `bitcoin-cli`. This should only be regarded as a source of inspiration; it will provide you with the basics to get started. You’re encouraged to explore further.

### Communicating with bitcoind

When `bitcoind` starts, it also starts a web server that listens on TCP port 8332 by default. When you use `bitcoin-cli`, it will connect to the web server, send your command to the web server over HTTP, and display relevant parts of the response to you.

For example, suppose I want to know the block ID of the genesis block (the block at height 0), and I issue the following command:

```bash
$ ./bitcoin-cli getblockhash 0
```

`bitcoin-cli` creates an HTTP `POST` request with the body

```json
{"method":"getblockhash","params":[0],"id":1}
```

and sends it to the web server that `bitcoind` runs. The request body’s `method` property is the command you want to execute, and the argument `0` is passed to the web server as an array with a single element.

The web server processes the HTTP request by looking up the block hash in the blockchain and replies with an HTTP response with the following body:

```
12{"result":"000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f",
"error":null,"id":"1"}
```

`bitcoin-cli` then displays the value of the `result` property on the terminal:

```
000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f
```

This body of the HTTP request follows a standard called JSON-RPC, which describes how a client can call functions on a remote process using JavaScript Object Notation (JSON).

#### Using curl

Because the communication with `bitcoind` happens through `HTTP`, any program that can send `HTTP POST` requests, such as the command-line tool `curl`, can be used to communicate with `bitcoind`. But to use tools other than `bitcoin-cli`, you need to set up a username and password to use as authentication to the web server.

![More parameters](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-02.jpg)

Bitcoin Core offers a lot of options. Run `./bitcoind --help` to get a complete list.

Stop the node with `./bitcoin-cli stop`. Open—or create, if it doesn’t exist—Bitcoin Core’s configuration file ~/.bitcoin/bitcoin.conf, and add these lines:

```
12rpcuser=<a username that you select>
rpcpassword=<a password that you select>
```

After you’ve modified and saved the ~/.bitcoin/bitcoin.conf file, start your node using `./bitcoind -daemon`, to make the changes effective.

Here’s how I called `getblockhash` using `curl` (the backslash `\` character means the command continues on the next line):

```
123456curl --user kalle --data-binary \
    '{"method":"getblockhash","params":[0],"id":1}' \
    -H 'content-type: text/plain;' http://127.0.0.1:8332/
Enter host password for user 'kalle':
{"result":"000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f",
"error":null,"id":1}
```

Remember to change the username from `kalle` to the username you configured in bitcoin.conf.

This command will prompt you for the password. Enter the password, and press Enter. The reply from the web server will be the same as when you used `bitcoin-cli`, but you’ll need to scan through the response body to spot the result, which is the hash of block 0.

### Graphical user interface

Bitcoin Core comes with a graphical user interface (GUI). This appendix mainly deals with the command-line interface `bitcoin-cli` for controlling and querying your running `bitcoind`. But if you want to use Bitcoin Core as a Bitcoin wallet (and not just as a full node), it can be useful to familiarize yourself with the GUI version. The GUI version of Bitcoin Core lets you perform most common tasks expected from a Bitcoin wallet, but to access Bitcoin Core’s full set of features, you’ll need to use `bitcoin-cli`.

![Why -qt?](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-02.jpg)

The Bitcoin Core GUI is built using a GUI programming library called QT. Hence the name, `bitcoin-qt`.

To use the GUI version of Bitcoin Core, you need to stop the current node and start the GUI version, called `bitcoin-qt`:

```
123$ ./bitcoin-cli stop
Bitcoin server stopping
$ ./bitcoin-qt &
```

If `bitcoind` didn’t have time to finish shutting down before you started `bitcoin-qt`, you’ll get an error message from `bitcoin-qt`. If so, click OK and try running `./bitcoin-qt &` again in a few seconds.

`bitcoin-qt` uses the same data directory, ~/.bitcoin/, as `bitcoind`, which means `bitcoin-qt` will use the already downloaded and verified blockchain and the same wallet as `bitcoind`. It’s just the user interface that differs.

By default, `bitcoin-qt` won’t start the web server to accept JSON-RPC requests as `bitcoind` does. To use `bitcoin-cli` with `bitcoin-qt`, start `bitcoin-qt` as follows, instead:

```bash
$ ./bitcoin-qt -server &
```

### Getting to know bitcoin-cli

You’ve started Bitcoin Core in the background by running

```bash
$ ./bitcoind -daemon
```

The most important command to know is the `help` command. Run it without any arguments to get a list of all available commands:

```bash
$ ./bitcoin-cli help
```

You’ll get a long list of commands grouped by subject—for example, `Blockchain`, `Mining`, and `Wallet`. Some commands are self-explanatory, but if you want to know more about a specific command, you can run `help` with the command name as an argument. For example:

```bash
$ ./bitcoin-cli help getblockhash
getblockhash height

Returns hash of block in best-block-chain at height provided.

Arguments:
1. height         (numeric, required) The height index

Result:
"hash"         (string) The block hash

Examples:
> bitcoin-cli getblockhash 1000
> curl --user myusername --data-binary '{"jsonrpc": [CA]"1.0", "id":"curltest",
"method": "getblockhash", "params": [1000] }' -H 'content-type: text/plain;'
http://127.0.0.1:8332/
```

You can invoke `bitcoin-cli` in two ways:

- *Using positional arguments*—The meanings of the arguments are based on their relative positions: for example, `./bitcoin-cli getblockhash 1000`. This is the most common way to use `bitcoin-cli.`
- *Using named arguments*—The arguments are named on the command line: for example, `./bitcoin-cli -named getblockhash height=1000`. This is sometimes useful when the command takes optional arguments and you want to specify the second optional argument but not the first. You’ll see examples later.

### Getting to work

Let’s create an encrypted wallet and back it up. You’ll then receive some bitcoins and pass that money on to another address while dissecting the transactions for details—all using `bitcoin-cli`.

#### Creating an encrypted wallet

When `bitcoind` (or `bitcoin-qt`) starts, it will automatically create a wallet for you and store it in the file ~/.bitcoin/wallet.dat. But this wallet isn’t encrypted, which means its private keys and its seed, used to derive key pairs as discussed in [chapter 4](/book/grokking-bitcoin/chapter-4/ch04), are stored in the clear on your hard drive. Let’s look at some data for such a wallet:

```bash
$ ./bitcoin-cli getwalletinfo
{
  "walletname": "",
  "walletversion": 169900,
  "balance": 0.00000000,
  "unconfirmed_balance": 0.00000000,
  "immature_balance": 0.00000000,
  "txcount": 0,
  "keypoololdest": 1541941001,
  "keypoolsize": 1000,
  "keypoolsize_hd_internal": 1000,
  "paytxfee": 0.00000000,
  "hdseedid": "bb989ad4e23f7bb713eab0a272eaef3d4857f5e3",
  "hdmasterkeyid": "bb989ad4e23f7bb713eab0a272eaef3d4857f5e3",
  "private_keys_enabled": true
}
```

The output from the `getwalletinfo` command shows various information about the wallet currently being used. This automatically created wallet is unnamed, which is why `walletname` is empty.

`balance` is how many confirmed bitcoins you have (including unconfirmed outgoing transactions), and `unconfirmed_balance` is the sum of incoming unconfirmed payments. `immature_balance` is relevant only for miners and denotes the number of newly created bitcoins, which can’t be spent until after 100 blocks passed. Refer to the help section on `getwalletinfo` for more details about the output.

To create an encrypted wallet, you need to create a *new* wallet using the command `encryptwallet`:

```bash
$ ./bitcoin-cli -stdin encryptwallet
secretpassword<ENTER>
<CTRL-D>
wallet encrypted; Bitcoin server stopping, restart to run with encrypted wallet.
The keypool has been flushed and a new HD seed was generated (if you are using HD).
You need to make a new backup.
```

This command creates a new encrypted wallet. The `-stdin` option is used to read the password argument from standard input, which in this case means you type the password in your terminal window after starting the command. End your input by pressing Enter and Ctrl-D. The reason for using `-stdin` is that you don’t want the password to be written in the command itself, because most shell interpreters, such as bash, keep a history of commands in a file. The `-stdin` option ensures that the password doesn’t end up in any such history files.

It’s important to create a new encrypted wallet instead of just encrypting the existing wallet, because the old wallet might already have been compromised on your hard drive. As noted by the output, `bitcoind` has stopped. Bitcoin Core can’t currently switch to a new wallet file while running.

Let’s start `bitcoind` again and look at the wallet. You’ll see something similar to this:

```bash
$ ./bitcoind -daemon
Bitcoin server starting
$ ./bitcoin-cli getwalletinfo
{
  "walletname": "",
  "walletversion": 169900,
  "balance": 0.00000000,
  "unconfirmed_balance": 0.00000000,
  "immature_balance": 0.00000000,
  "txcount": 0,
  "keypoololdest": 1541941063,
  "keypoolsize": 1000,
  "keypoolsize_hd_internal": 1000,
  "unlocked_until": 0,
  "paytxfee": 0.00000000,
  "hdseedid": "590ec0fa4cec43d9179e5b6f7b2cdefaa35ed282",
  "hdmasterkeyid": "590ec0fa4cec43d9179e5b6f7b2cdefaa35ed282",
  "private_keys_enabled": true
}
```

Your old, unencrypted wallet.dat has been overwritten by the new, encrypted wallet.dat. For safety, however, your old seed is kept in the new encrypted wallet, in case you had actual funds in the old wallet or accidentally receive funds to that old wallet in the future. The `unlocked_until` value of `0` means your private keys are encrypted with the password you entered when you encrypted your wallet. From now on, you need to decrypt your private keys to access them. You’ll do that when you send bitcoin later.

#### Backing up the wallet

You’ve created an encrypted wallet, and before you start using it, you need to back it up. In [chapter 4](/book/grokking-bitcoin/chapter-4/ch04), we talked about mnemonic sentences, as defined in BIP39, which made backing up hierarchical deterministic (HD) wallet seeds simple. But this feature is *not* implemented in Bitcoin Core, for a few reasons—mainly, that the mnemonic sentence lacks information about the following:

- The version of the seed format.
- The *birthday*, which is when the seed was created. Without a birthday, you have to scan the entire blockchain to find your old transactions. With a birthday, you only have to scan the blockchain from the birthday onward.
- The derivation paths to use for restoration. This is somewhat remedied by using standard derivation paths, but not all wallets implement the standard.
- Other arbitrary metadata, such as labels on addresses.

To back up your Bitcoin Core wallet, you need to make a copy of the wallet.dat file. Be careful not to copy the file using your operating system’s copy facilities while `bitcoind` or `bitcoin-qt` is running. If you do this, your backup might be in an inconsistent state because `bitcoind` might be writing data to it while you copy. To make sure you get a consistent copy of the file while Bitcoin Core is running, run the following command:

```bash
$ ./bitcoin-cli backupwallet ~/walletbackup.dat
```

This will instruct `bitcoind` to save a copy of the wallet file to walletbackup.dat in your home directory (you can change the name and path of the file to anything you like). The backup file will be an exact copy of the original wallet.dat file. Move the walletbackup.dat file to a safe place—for example, a USB memory stick in a bank safe-deposit box or on a computer at your brother’s apartment.

#### Receiving money

You’ve created an encrypted, backed-up wallet. Great! Let’s put some bitcoins into it. To do this, you need a Bitcoin address to receive the bitcoins to, so let’s get one:

```bash
$ ./bitcoin-cli -named getnewaddress address_type=bech32
bc1q2r9mql4mkz3z7yfxvef76yxjd637r429620j75
```

This command creates a bech32 p2wpkh address for you. If you prefer another type of address, you can change `bech32` to `legacy` to get a p2pkh address or to `p2sh-segwit` to get a p2wpkh nested in p2sh address. Head back to the “[Recap of payment types](/book/grokking-bitcoin/chapter-10/ch10lev1sec4)” section in [chapter 10](/book/grokking-bitcoin/chapter-10/ch10) to refresh your memory on the different payment and address types.

Now, let’s send bitcoin to that address. Be careful not to send money to the address printed in this book (although I’ll happily accept it), but rather to an address you generate yourself with your own full node wallet.

This raises the question of how to get bitcoins to send to your wallet. You can get bitcoins in several ways:

- Buy bitcoins on an exchange.
- Ask friends who have bitcoins if they can give or sell you some.
- Earn bitcoins as payment for your labor.
- Mine bitcoins.

![On the web](https://drek4537l1klr.cloudfront.net/rosenbaum/Figures/common-01.jpg)

Visit web resource 20 in [appendix C](/book/grokking-bitcoin/appendix-c/app03) to find out more about how to get bitcoins where you live.

I’ll leave it up to you how you obtain bitcoins and assume that you somehow will get bitcoins into the address you created previously.

I made a payment to my new address and then checked my wallet:

```bash
$ ./bitcoin-cli getunconfirmedbalance
0.00500000
```

This shows a pending incoming payment of 5 mBTC (0.005 BTC). I now have to wait until it’s confirmed in the blockchain. Meanwhile, you can dig into the transaction by running the `listtransactions` command. Here are my results:

```bash
$ ./bitcoin-cli listtransactions
[
  {
    "address": "bc1q2r9mql4mkz3z7yfxvef76yxjd637r429620j75",
    "category": "receive",
    "amount": 0.00500000,
    "label": "",
    "vout": 1,
    "confirmations": 0,
    "trusted": false,
    "txid": "ebfd0d14c2ea74ce408d01d5ea79636b8dee88fe06625f5d4842d2a0ba45c195",
    "walletconflicts": [
    ],
    "time": 1541941483,
    "timereceived": 1541941483,
    "bip125-replaceable": "yes"
  }
]
```

This transaction has 0 confirmations and pays 0.005 BTC. You can also see that this transaction’s txid is `ebfd0d14...ba45c195`.

Let’s take a closer look at the transaction using the command `getrawtransaction`:

```bash
$ ./bitcoin-cli getrawtransaction \
    ebfd0d14c2ea74ce408d01d5ea79636b8dee88fe06625f5d4842d2a0ba45c195 1
{
  "txid": "ebfd0d14c2ea74ce408d01d5ea79636b8dee88fe06625f5d4842d2a0ba45c195",
  "hash": "ebfd0d14c2ea74ce408d01d5ea79636b8dee88fe06625f5d4842d2a0ba45c195",
  "version": 1,
  "size": 223,
  "vsize": 223,
  "weight": 892,
  "locktime": 549655,
  "vin": [
    {
       "txid": "8a4023dbcf57dc7f51d368606055e47636fc625a512d3481352a1eec909ab22f",
      "vout": 0,
      "scriptSig": {
        "asm": "3045022100cc095e6b7c0d4c42a1741371cfdda4f1b518590f1af
        0915578d3966fee7e34ea02205fc1e976edcf4fe62f16035a5389c661844f7189
        a9eb45adf59e061ac8cc6fd3[ALL]
        030ace35cc192cedfe2a730244945f1699ea2f6b7ee77c65c83a2d7a37440e3dae",
           "hex":
        "483045022100cc095e6b7c0d4c42a1741371cfdda4f1b518590f1af0915578d3966
fee7e34ea02205fc1e976edcf4fe62f16035a5389c661844f7189a9eb45adf59e061
ac8cc6fd 30121030ace35cc192cedfe2a730244945f1699ea2f6b7ee77c65c83a2d7
a37440e3dae"
      },
      "sequence": 4294967293
    }
  ],
  "vout": [
    {
      "value": 0.00313955,
      "n": 0,
      "scriptPubKey": {
        "asm": "OP_DUP OP_HASH160 6da68d8f89dced72d4339959c94a4fcc872fa089
  OP_EQUALVERIFY OP_CHECKSIG",
        "hex": "76a9146da68d8f89dced72d4339959c94a4fcc872fa08988ac",
        "reqSigs": 1,
        "type": "pubkeyhash",
        "addresses": [
          "1AznBDM2ZfjYNoRw3DLSR9NL2cwwqDHJY6"
        ]
      }
    },
    {
      "value": 0.00500000,
      "n": 1,
      "scriptPubKey": {
        "asm": "0 50cbb07ebbb0a22f11266653ed10d26ea3e1d545",
        "hex": "001450cbb07ebbb0a22f11266653ed10d26ea3e1d545",
        "reqSigs": 1,
        "type": "witness_v0_keyhash",
        "addresses": [
          "bc1q2r9mql4mkz3z7yfxvef76yxjd637r429620j75"
        ]
      }
    }
  ],
  "hex":
"01000000012fb29a90ec1e2a3581342d515a62fc3676e455606068d3517fdc57cfdb
23408a000000006b483045022100cc095e6b7c0d4c42a1741371cfdda4f1b518590f1af0915578
d3966fee7e34ea02205fc1e976edcf4fe62f16035a5389c661844f7189a9eb45adf59e061ac8
cc6fd30121030ace35cc192cedfe2a730244945f1699ea2f6b7ee77c65c83a2d7a37440e3
daefdffffff0263ca0400000000001976a9146da68d8f89dced72d4339959c94a4fcc872fa08988
20a107000000000016001450cbb07ebbb0a22f11266653ed10d26ea3e1d54517630800"
}
```

This command prints the entire transaction in a human-readable (well, at least developer-readable) form. Let’s start from the top and go through the most relevant parts of this transaction. The `txid` is the transaction id. The `hash` is the double SHA256 hash of the whole transaction, including the witness. For non-segwit transactions, `hash` is equal to `txid`.

The `size` of the transaction is 223 bytes, and `vsize` (the virtual size) is also 223 vbytes; `vsize` is the transaction’s number of weight units (`892`) divided by 4, so the virtual size of a non-segwit transaction (which this is, because it only spends non-segwit outputs) is equal to its actual `size`.

The locktime of this transaction is set to `549655`, which was the height of the strongest chain at the time of the transaction’s creation. Thus the transaction can’t be mined until block height 549656. This reduces the attractiveness of an attack in which a miner deliberately tries to reorg the blockchain and include the transaction into a block height that’s already been mined.

Next comes the list of inputs. This transaction has a single input that spends output at index `0` (`vout`) of the transaction with `txid` `8a4023db...909ab22f`. The input spends a p2pkh output.

The input’s sequence number is `4294967293`, which is `fffffffd` in hex code. This means the lock time is enabled (≤`fffffffe`) and the transaction is replaceable (≤`fffffffd`) according to BIP125. The meaning of the sequence number was summarized in [table 9.1](/book/grokking-bitcoin/chapter-9/ch09table01).

After the list of inputs comes the list of transaction outputs. This transaction has a list of two outputs. The first pays 0.00313955 BTC to a p2pkh address you haven’t seen before. This is *probably* a change output. The second output sends 0.005 BTC to the p2wpkh address created earlier.

Let’s see if the transaction is confirmed yet. You can check, for example, with `getbalance`. In my case, if it shows `0.00500000`, then the transaction has confirmed:

```bash
$ ./bitcoin-cli getbalance
0.00500000
```

Cool, the money is confirmed! Let’s move on.

#### Sending money

You’ve received some bitcoins. Now, you want to send bitcoins to someone else. To send bitcoins, you can use the `sendtoaddress` command. You need to make a few decisions first:

- Address to send to
- How much money to send: 0.001 BTC
- How urgent the transaction is: not urgent (you’ll be happy if it confirms within 20 blocks)

I’ll send the bitcoins to address `bc1qu456...5t7uulqm`, but you should get another address to send to. If you have no other wallet, you can create a new address in Bitcoin Core to send to just for experimental purposes. I’ve obfuscated my address below so that you don’t send to my address by mistake:

```bash
$ ./bitcoin-cli -named sendtoaddress \
    address="bc1qu456w7a5mawlgXXXXXXu03wp8wc7d65t7uulqm" \
    amount=0.001 conf_target=20 estimate_mode=ECONOMICAL
error code: -13
error message:
Error: Please enter the wallet passphrase with walletpassphrase first.
```

Oh, dear! An error. As indicated by the error message, the private keys are encrypted in the wallet.dat file. Bitcoin Core needs the private keys to sign the transaction. To make the private keys accessible, you need to decrypt them. You do this using the `walletpassphrase` command with the `-stdin` option to prevent the passphrase from being stored by your command-line interpreter, such as bash:

```bash
$ ./bitcoin-cli -stdin walletpassphrase
secretpassword<ENTER>
300<ENTER>
<CTRL-D>
```

The last argument, `300`, is the number of seconds you should keep the wallet unlocked. After 300 seconds, the wallet will be automatically locked again in case you forget to lock it manually. Let’s retry the `sendtoaddress` command:

```bash
$ ./bitcoin-cli -named sendtoaddress \
    address="bc1qu456w7a5mawlgXXXXXXu03wp8wc7d65t7uulqm" \
    amount=0.001 conf_target=20 estimate_mode=ECONOMICAL
a13bcb16d8f41851cab8e939c017f1e05cc3e2a3c7735bf72f3dc5ef4a5893a2
```

The command output a txid for the newly created transaction. This means it went well. You can relock the wallet using the `walletlock` command:

```bash
$ ./bitcoin-cli walletlock
```

The wallet is now locked. I’ll list my transactions again:

```bash
$ ./bitcoin-cli listtransactions
[
  {
    "address": "bc1q2r9mql4mkz3z7yfxvef76yxjd637r429620j75",
    "category": "receive",
    "amount": 0.00500000,
    "label": "",
    "vout": 1,
    "confirmations": 1,
    "blockhash": "000000000000000000240eec03ac7499805b0f3df34a7d5005670f3a8fa836ca",
    "blockindex": 311,
    "blocktime": 1541946325,
    "txid": "ebfd0d14c2ea74ce408d01d5ea79636b8dee88fe06625f5d4842d2a0ba45c195",
    "walletconflicts": [
    ],
    "time": 1541941483,
    "timereceived": 1541941483,
    "bip125-replaceable": "no"
  },
  {
    "address": "bc1qu456w7a5mawlg35y00xu03wp8wc7d65t7uulqm",
    "category": "send",
    "amount": -0.00100000,
    "vout": 1,
    "fee": -0.00000141,
    "confirmations": 0,
    "trusted": true,
    "txid": "a13bcb16d8f41851cab8e939c017f1e05cc3e2a3c7735bf72f3dc5ef4a5893a2",
    "walletconflicts": [
    ],
    "time": 1541946631,
    "timereceived": 1541946631,
    "bip125-replaceable": "no",
    "abandoned": false
  }
]
```

The new transaction is the last one of the two. It isn’t yet confirmed, as indicated by `"confirmations": 0`. The fee paid was 141 satoshis. Let’s look into this transaction in detail:

```bash
$ ./bitcoin-cli getrawtransaction \
    a13bcb16d8f41851cab8e939c017f1e05cc3e2a3c7735bf72f3dc5ef4a5893a2 1
{
  "txid": "a13bcb16d8f41851cab8e939c017f1e05cc3e2a3c7735bf72f3dc5ef4a5893a2",
  "hash": "554a3a3e57dcd07185414d981af5fd272515d7f2159cf9ed9808d52b7d852ead",
  "version": 2,
  "size": 222,
  "vsize": 141,
  "weight": 561,
  "locktime": 549665,
  "vin": [
    {
      "txid": "ebfd0d14c2ea74ce408d01d5ea79636b8dee88fe06625f5d4842d2a0ba45c195",
      "vout": 1,
      "scriptSig": {
        "asm": "",
        "hex": ""
      },
        "txinwitness": [
        "30440220212043afeaf70a97ea0aa09a15749ab94e09c6fad427677610286666a3
decf0b022076818b2b2dc64b1599fd6b39bb8c249efbf4c546e334bcd7e1874115
da4dfd0c01",

         "020127d82280a939add393ddbb1b8d08f0371fffbde776874cd69740b59e098866"
      ],
      "sequence": 4294967294
    }
  ],
  "vout": [
    {
      "value": 0.00399859,
      "n": 0,
      "scriptPubKey": {
        "asm": "0 4bf041f271bd94385d6bcac8487adf6c9a862d10",
        "hex": "00144bf041f271bd94385d6bcac8487adf6c9a862d10",
        "reqSigs": 1,
        "type": "witness_v0_keyhash",
        "addresses": [
          "bc1qf0cyrun3hk2rshttetyys7kldjdgvtgs6ymhzz"
        ]
      }
    },
    {
      "value": 0.00100000,
      "n": 1,
      "scriptPubKey": {
        "asm": "0 e569a77bb4df5df446847bcdc7c5c13bb1e6ea8b",
        "hex": "0014e569a77bb4df5df446847bcdc7c5c13bb1e6ea8b",
        "reqSigs": 1,
        "type": "witness_v0_keyhash",
        "addresses": [
          "bc1qu456w7a5mawlg35y00xu03wp8wc7d65t7uulqm"
        ]
      }
    }
  ],
  "hex":
"0200000000010195c145baa0d242485d5f6206fe88ee8d6b6379ead5018d40
ce74eac2140dfdeb0100000000feffffff02f3190600000000001600144bf041f27
1bd94385d6bcac8487adf6c9a862d10a086010000000000160014e569a77bb4
df5df446847bcdc7c5c13bb1e6ea8b024730440220212043afeaf70a97ea0aa09
a15749ab94e09c6fad427677610286666a3decf0b022076818b2b2dc64b1599
fd6b39bb8c249efbf4c546e334bcd7e1874115da4dfd0c0121020127d82280a
939add393ddbb1b8d08f0371fffbde776874cd69740b59e0988662163080"
}
```

The first thing to note is that `txid` and `hash` differ. That’s because this is a segwit transaction. As you may recall from [chapter 10](/book/grokking-bitcoin/chapter-10/ch10), the witness isn’t included in the txid—that’s how you avoid transaction malleability—but the `hash` in the output includes it. Note that `size` and `vsize` differ, too, which is expected from a segwit transaction. The fee was 141 satoshis, as shown by the `listtransactions` command, and the `vsize` was 141 vbytes. The fee rate was thus selected by Bitcoin Core to be 1 sat/vbyte.

The transaction has a single input that spends output `1` of transaction `ebfd0d14...ba45c195`. You should recognize this output from the section where I paid 0.005 BTC to my Bitcoin Core wallet. Because that output was a p2wpkh output, the signature script (`scriptSig`) is empty, and the `txinwitness` contains the signature and pubkey.

The sequence number of the input is 4294967294, which equals `fffffffe`. This means the transaction has lock time enabled but isn’t replaceable using BIP125 (opt-in replace-by-fee).

I have two outputs. The first is the change of 0.00399859 BTC back to an address I own. The other is the actual payment of 0.001 BTC. Let’s check the balance again:

```
./bitcoin-cli getbalance
0.00399859
```

Yep, there it is. I didn’t have to wait for confirmation to see the new balance, because `getbalance` always includes my own *outgoing* unconfirmed transactions. I’ve spent my only UTXO (of 0.005 BTC) and created a new UTXO of 0.00399859 to myself:

```
Spent:   0.005
Pay:    -0.001
Fee:    -0.00000141
===================
Change:  0.00399859
```

It sums up perfectly.

I’ve shown a few commands you can use to wing your Bitcoin Core node, but there’s a lot more to it. Explore `./bitcoin-cli help` to find out more.
