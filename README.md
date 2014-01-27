## Coinmux

### Decentralized, Trustless, Anonymous and Open Bitcoin Mixer

### DO NOT USE WITH THE BITCOIN NETWORK! THIS SOFTWARE IS FOR TESTING PURPOSES ONLY!


## Synopsis

Coinmux is an implementation of [CoinJoin](https://bitcointalk.org/index.php?topic=279249) for the Bitcoin Network.
It is currently in early development and only suitable for use on Bitcoin's Testnet network.

CoinJoin is intended increase your Bitcoin privacy and help bitcoins remain [fungible](http://en.wikipedia.org/wiki/Fungibility).

You can view some of the [transactions](http://test.webbtc.com/address/mjfCi3t1jBsizt9MKtNDxpn3qdd73CRyhQ) made during testing.

[Protocol Specification](docs/spec.md)
[Roadmap](docs/roadmap.md)


## Installation

Note that Coinmux is currently only for development purposes.  You should already have Java installed on your computer.

Install RVM and JRuby
```bash
\curl -sSL https://get.rvm.io | bash -s stable --ruby=jruby
```

Clone the git repository to your computer
```bash
git clone git@github.com:michaelgpearce/coinmux.git
```

Install application dependencies from the project directory
```bash
bundle
```


## Command Line Interface

Print options from the project directory
```bash
./bin/coinmux --help
```

Start one participant in a CoinJoin between two participants for 0.5 BTC:
```bash
./bin/coinmux -p 2 -a 0.5 -o my-output-address -c my-change-address -k my-input-private-key-in-hex
```

For a second participant to join, the number of participants and Bitcoin amount must match.

## Graphical Interface

TODO


## Tests

Run tests with the following command

```bash
bundle exec rake
```


## License

Licenced with Apache v2.0.
