## Coinmux - Bitcoin Mixer

### Decentralized<sup>1</sup>, Trustless, Anonymous<sup>2</sup> and Open Bitcoin Mixer

### DO NOT USE WITH THE MAIN BITCOIN NETWORK!<br>THIS SOFTWARE IS FOR TESTING PURPOSES ONLY!

<sup>1</sup> Its not totally decentralized yet. It makes some connections to [webbtc.com](http://webbtc.com) to get transaction data since this cannot be retrieved over the Bitcoin network without a full copy of the blockchain.

<sup>2</sup> Its not totally anonymous yet. Your IP address will be leaked when connecting over the P2P network. But your CoinJoin transaction's output is difficult to trace once added to the Bitcoin blockchain.

## Synopsis

Coinmux is an implementation of [CoinJoin](https://bitcointalk.org/index.php?topic=279249).
It is currently in early development and only suitable for use on Bitcoin's Testnet network.

CoinJoin increases your Bitcoin privacy and helps bitcoins remain [fungible](http://en.wikipedia.org/wiki/Fungibility). Your bitcoins along with others are joined into a single transaction with some of the output addresses at the same Bitcoin amount. These same amount output addresses are indistinguishable from one another and there is no way to match them to a specific input addresses.

CoinJoin is also safe. Even though you are combining your bitcoins with strangers on the internet, Coinmux only signs transactions that have the inputs and outputs you specify. There is no chance of anyone stealing your coins - if your outputs are not 100% correct, Coinmux will not sign the transaction and your coins don't go anywhere!

And CoinJoin is very inexpensive. The only fees involved are those used to pay Bitcoin miners their normal transaction fee. And that low fee is split between all participants!

You can view some of the [transactions](http://test.webbtc.com/address/mjfCi3t1jBsizt9MKtNDxpn3qdd73CRyhQ) made during testing.

[Protocol Specification](docs/spec.md)

[Roadmap](docs/roadmap.md)


## Installation

You can either run Coinmux from the pre-built Java Jar file or run directly from source. You should already have Java installed on your computer. 

### Runnable Java Jar File Installation

Download the Java Jar file:

[http://coinmux.com/releases/coinmux-SNAPSHOT.jar](http://coinmux.com/releases/coinmux-SNAPSHOT.jar)

### Ruby Developer Installation

Install RVM and JRuby
```bash
\curl -sSL https://get.rvm.io | bash -s stable --ruby=jruby-1.7.8
```

Clone the git repository to your computer.
```bash
git clone https://github.com/michaelgpearce/coinmux.git
```

Install application dependencies from the project directory. (You may need to reload your terminal shell.)
```bash
gem install bundler && bundle
```


## Command Line Interface

All commands can be run with either ```java -jar coinmux-SNAPSHOT.jar [options]``` from the directory of the jar file or ```./bin/coinmux [options]``` from your Coinmux project directory. The remainder of this document assumes you are using the Jar file. If you are using the ```./bin/coinmux``` command, simply replace the start of the commands below.

Print options from the project directory
```bash
java -jar coinmux-SNAPSHOT.jar --help
```

### Trying it out P2P over the Internet

Coinmux in P2P mode requires external access to ports 14141 TCP and UDP. If you are behind a firewall and your router supports UPNP, these ports will be opened for you automatically, otherwise you must manually allow access to these ports.

To begin, check to see if there are available CoinJoins already on the network. If not, Coinmux will create one automatically when you start a CoinJon.

```
java -jar coinmux-SNAPSHOT.jar --list
```

You will see something like this:
```
BTC Amount  Participants
==========  ============
0.0625      2 of 5
0.125       1 of 2
1.0         3 of 5
```

Notice that the bitcoin amount must be a power of 2 number of bitcoins: 1, 2, 4, or 1/2, 1/4, 1/8, etc.

Now execute Coinmux in a CoinJoin between 2 participants for 0.5 BTC. You will be prompted to enter the private key of your input Bitcoin address.
```bash
java -jar coinmux-SNAPSHOT.jar --participants 2 --amount 0.5 --output-address my-output-address --change-address my-change-address
```

Coinmux will wait for more participants to arrive until there are the correct number you specified to begin the CoinJoin.

To join the CoinJoin with another of your input addresses, start a second process with a matching number of participants and Bitcoin amount, but using a different input private key, output address and change address. If you run this on the same computer, you will also need to tell Coinmux to use a different port for connecting to the P2P network.
```bash
java -jar coinmux-SNAPSHOT.jar --participants 2 --amount 0.5 --output-address my-output-address-2 --change-address my-change-address-2 --data-store p2p?port=14142
```

If you are the only two partipants in the CoinJoin, you will see output like this for the first participant:
```
[Participant]: Finding coin join message
[Participant]: No available coin join
   [Director]: Inserting coin join message
   [Director]: Inserting status message
   [Director]: Waiting for inputs
[Participant]: Finding coin join message
[Participant]: Inserting input
[Participant]: Waiting for other inputs
   [Director]: Inserting message verification message
   [Director]: Waiting for outputs
[Participant]: Inserting output
[Participant]: Waiting for other outputs
   [Director]: Inserting transaction message
   [Director]: Waiting for signatures
[Participant]: Inserting transaction signatures
[Participant]: Waiting for completed
   [Director]: Publishing transaction
   [Director]: Completed
[Participant]: Completed - Transaction ID: 3b1d7dc373ecf5abc8e2a18d61839a7d7d06a99f3c94fec5cbff17330596c8a6
CoinJoin successfully created!
```

And like this for the second:
```
[Participant]: Finding coin join message
[Participant]: Inserting input
[Participant]: Waiting for other inputs
[Participant]: Inserting output
[Participant]: Waiting for other outputs
[Participant]: Inserting transaction signatures
[Participant]: Waiting for completed
[Participant]: Completed - Transaction ID: 3b1d7dc373ecf5abc8e2a18d61839a7d7d06a99f3c94fec5cbff17330596c8a6
CoinJoin successfully created!
```


### Usage on a single computer over the filesystem

If you want to try Coinmux out on a single computer, use the ```filesystem``` data-store instead of ```p2p```. When communicating via the filesystem, no external connections are made to find peers. This is useful for mixing your own wallet.

Using the filesystem looks like this:
```bash
java -jar coinmux-SNAPSHOT.jar --participants 2 --amount 0.5 --output-address my-output-address --change-address my-change-address --data-store filesystem
```

There may be some interesting things to try combining a filesystem CoinJoin with services like Dropbox or using FTP or [SSHFS](http://fuse.sourceforge.net/sshfs.html).


## Graphical Interface

Since Coinmux is in early development, there may be bugs that can cause a loss of Bitcoin. To make Coinmux only appeal to the development community, there is currently no graphical interface and the application defaults to connecting to the Testnet Bitcoin network.

As the system shows its robustness, it will have a graphical interface and default to Bitcoin's Mainnet.

## Tests

Run tests with the following command

```bash
bundle exec rake
```

## Donation

If you find this software useful and want to contribute to the continued development of Coinmux to enhance Bitcoin privacy and fungibility, donations can be sent to:

16f6gUFDFafjLPkWB55nvDjE3YkA6uPvoG

## License

Licenced with Apache v2.0.
