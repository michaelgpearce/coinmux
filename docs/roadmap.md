### v0.1 - Functional Prototype

* Command line available
* Creates transactions with no bad actors present
* Works on Testnet
* Support WIF private keys
* Can specify/create custom CoinJoin URI
* May have single point of failure (i.e. webbtc HTTP API) and not be fully decentralized
* May not be fully anonymous (i.e. IP address leaked during P2P connections)

### v0.2 - Graphical User Interface

* Graphical user interface available

### v0.3 - Functional Beta

* Creates transactions with no bad actors present
* Works for Mainnet usage for advanced users
* Remove single points of failure
* Transaction fee calculation use transaction size info.
* Support multiple input addresses during CoinJoin (proper fee calculation required)
* Allow single transaction input with value equal to CoinJoin amount to pay 0 transaction fee for rejoining

### v0.4 - Improve deterrence of bad actors

* Ensure that all participants are active (signature of current Director status?)
* Add proof of work for posting inputs / creating new CoinJoin (?)
* Require minimum confirmations for input address (?)
* Blacklist of "bad addresses" (probably not workable)
* Encrypt all messages after publish of message_verification so only participants and director can decrypt
* Dependent Gems are part of project

### v1.0 - Stable enough and feature rich enough for novice users

* Installers for OSX, Windows, Linux
* Improved UI/UX
* User can use proxy server (i.e Tor) or use Tor library (http://www.subgraph.com/orchid.html)
* Existing wallets can integrate CoinJoin protocol when sending transactions

### FUTURE FEATURES:

* Fund by creating a new address and starting coin_join once funds confirmed (instead of/in addition to specifying private key)
* Embed Freenet (or move to P2P [TomP2P] or Bitmessage)
* Automatic retries of failed transactions
* Acts as anonymous wallet (mix to new address, the send)
* Use stealth address for output address / change
