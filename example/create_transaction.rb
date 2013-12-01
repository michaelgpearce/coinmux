require 'bouncy-castle-java'
require 'bitcoin'
require 'net/http'
require 'uri'

# use testnet so you don't acidentially your whole money!
Bitcoin.network = :testnet3

# make the DSL methods available in your scope
include Bitcoin::Builder

# the previous transaction that has an output to your address
prev_hash = "6c44b284c20fa22bd69c57a9dbff91fb71deddc8c54fb2f5aa41fc78c96c1ad1"

# the number of the output you want to use
prev_out_index = 0

# fetch the tx from whereever you like and parse it
prev_tx = Bitcoin::P::Tx.from_json(Net::HTTP.get(URI("http://test.webbtc.com/tx/#{prev_hash}.json")))

# the key needed to sign an input that spends the previous output
key = Bitcoin::Key.from_base58("92ZRu28m2GHSKaaF2W7RswJ2iJYpTzVhBaN6ZLs7TENCs4b7ML8")

# create a new transaction (and sign the inputs)
new_tx = build_tx do |t|

  # add the input you picked out earlier
  t.input do |i|
    i.prev_out prev_tx
    i.prev_out_index prev_out_index
    i.signature_key key
  end

  # add an output that sends some bitcoins to another address
  t.output do |o|
    o.value 50000000 # 0.5 BTC in satoshis
    o.script {|s| s.recipient "mugwYJ1sKyr8EDDgXtoh8sdDQuNWKYNf88" }
  end

  # add another output spending the remaining amount back to yourself
  # if you want to pay a tx fee, reduce the value of this output accordingly
  # if you want to keep your financial history private, use a different address
  t.output do |o|
    o.value 49000000 # 0.49 BTC, leave 0.01 BTC as fee
    o.script {|s| s.recipient key.addr }
  end

end

# examine your transaction. you can relay it through http://webbtc.com/relay_tx
# that will also give you a hint on the error if something goes wrong
puts new_tx.to_json
