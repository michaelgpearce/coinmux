## Coinmux - Bitcoin Mixer

### Decentralized<sup>1</sup>, Trustless, Anonymous<sup>2</sup> and Open Bitcoin Mixer

### DO NOT USE WITH THE MAIN BITCOIN NETWORK!<br>THIS SOFTWARE IS FOR TESTING PURPOSES ONLY!

<sup>1</sup> Its not totally decentralized yet. It makes some connections to [webbtc.com](http://webbtc.com) to get transaction data since this cannot be retrieved over the Bitcoin network without a full copy of the blockchain.

<sup>2</sup> Its not totally anonymous yet. Your IP address will be leaked when connecting over the P2P network. But your CoinJoin transactions output is difficult to trace in the blockchain.

## Synopsis

Coinmux is an implementation of [CoinJoin](https://bitcointalk.org/index.php?topic=279249).
It is currently in early development and only suitable for use on Bitcoin's Testnet network.

CoinJoin increases your Bitcoin privacy and helps bitcoins remain [fungible](http://en.wikipedia.org/wiki/Fungibility). Your bitcoins along with others are joined into a single transaction with some of the output addresses at the same Bitcoin amount. These same amount output addresses are indistinguishable from one another and there is no way to match them to a specific input addresses.

CoinJoin is also safe. Even though you are combining your bitcoins with strangers on the internet, because Coinmux only signs transactions that have the inputs and outputs you specify. There is no chance of anyone stealing your coins - if your outputs are not 100% correct, Coinmux will not sign the transaction and your coins don't go anywhere!

You can view some of the [transactions](http://test.webbtc.com/address/mjfCi3t1jBsizt9MKtNDxpn3qdd73CRyhQ) made during testing.

[Protocol Specification](docs/spec.md)

[Roadmap](docs/roadmap.md)


## Installation

Note that Coinmux is currently only for development purposes.  You should already have Java installed on your computer.

Install RVM and JRuby
```bash
\curl -sSL https://get.rvm.io | bash -s stable --ruby=jruby-1.7.8
```

Clone the git repository to your computer
```bash
git clone https://github.com/michaelgpearce/coinmux.git
```

Install application dependencies from the project directory
```bash
gem install bundler && bundle
```


## Command Line Interface

Print options from the project directory
```bash
./bin/coinmux --help
```

### Trying it out over the Internet P2P

Coinmux in P2P mode requires external access to ports 14141 TCP and UDP. If you are behind a firewall and your router supports UPNP, these ports will be opened for you automatically, otherwise you must manually allow access to these ports.

To begin, start one participant in a CoinJoin between 2 participants for 0.5 BTC. You will be prompted to enter the private key of your input Bitcoin address.
```bash
./bin/coinmux -p 2 -a 0.5 -o my-output-address -c my-change-address
```

Now, on a second computer (or Virtual Machine), start a second process with matching number of participants and Bitcoin amount, but using a different input private key, output address and change address.
```bash
./bin/coinmux -p 2 -a 0.5 -o my-output-address-2 -c my-change-address-2
```

You will see output like this for the first participant:
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
Coin join successfully created!
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
Coin join successfully created!
```

You can get a list of available CoinJoins that are waiting for participants:
```bash
./bin/coinmux -l
```

It outputs something like this:
```
BTC Amount  Participants
==========  ============
0.5         1 of 2      
1.0         3 of 5      
0.0625      1 of 5      
```

If there no CoinJoin availble, your computer will direct the CoinJoin for other participants when you run the program.


### Usage on a single computer

If you want to try Coinmux out on a single computer, you use a filesystem ```coin_join_uri``` instead of the p2p URI. When communicating via the filesystem, no external connections are made to find peers - only your computer's filesystem.

Using the filesystem will look something like this:
```bash
./bin/coinmux -p 2 -a 0.5 -o my-output-address -c my-change-address
```

There may be some interesting things to try combining a filesystem CoinJoin with services like Dropbox or using FTP or [SSHFS](http://fuse.sourceforge.net/sshfs.html).


## Graphical Interface

TODO


## Tests

Run tests with the following command

```bash
bundle exec rake
```


## License

Licenced with Apache v2.0.
