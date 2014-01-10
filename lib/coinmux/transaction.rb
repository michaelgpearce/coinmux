require './lib/coinmux'
require 'bitcoin'

import 'com.google.bitcoin.core.Transaction'
import 'java.math.BigInteger'
import 'java.security.SignatureException'
import 'com.google.bitcoin.core.Address'
import 'com.google.bitcoin.core.ECKey'
import 'com.google.bitcoin.core.NetworkParameters'
import 'com.google.bitcoin.core.PeerGroup'
import 'com.google.bitcoin.core.ScriptException'
import 'com.google.bitcoin.core.Utils'
import 'com.google.bitcoin.core.VerificationException'
import 'com.google.bitcoin.script.Script'
import 'com.google.bitcoin.script.ScriptBuilder'
import 'com.google.bitcoin.net.discovery.DnsDiscovery'
import 'org.spongycastle.util.encoders.Hex'

def network_params
  Coinmux::Config.instance.bitcoin_network == 'mainnet' ? NetworkParameters.prodNet() : NetworkParameters.testNet3()
end

TX_JSON_1 = <<-JSON
{
  "hash":"a228b621da5e832c27dba988b2c951885af734a417298357dc6b29593a37fbba",
  "ver":1,
  "vin_sz":1,
  "vout_sz":2,
  "lock_time":0,
  "size":225,
  "in":[
    {
      "prev_out":{
        "hash":"6210677ae370d51f484ce7d3b297bf9fcfae2215b8bec331109d842371c066b0",
        "n":1
      },
      "scriptSig":"304402205dfa1271ab7ddd03222a2490172b5e840f6f209fd30aa69980a1719462ceb85c02201ee0545481c561edfab5e3537f907dd7bd9bfa59f27fa76d4ffded6fd78c761801 03f4e831ebdcb7b9bfd92921ed6aa5b4754fe3df573e63d5f5273d35978c5210a3"
    }
  ],
  "out":[
    {
      "value":"3.00000000",
      "scriptPubKey":"OP_DUP OP_HASH160 2cea78a55e7e690c0b444fb9d77c1406913787b5 OP_EQUALVERIFY OP_CHECKSIG"
    },
    {
      "value":"226.55315755",
      "scriptPubKey":"OP_DUP OP_HASH160 494ec8758e3036802e01c29663ead23565bdea8c OP_EQUALVERIFY OP_CHECKSIG"
    }
  ]
}
JSON

TX_JSON_2 = <<-JSON
{
  "hash":"ffe714ba2baa106adeb6fcf903e4049be1d0fceb0be3215de4b710dc611b886b",
  "ver":1,
  "vin_sz":1,
  "vout_sz":2,
  "lock_time":0,
  "size":227,
  "in":[
    {
      "prev_out":{
        "hash":"3fe662c8a05b1c63588d82dafa9bd7585b24b72dbdff729e17cfec2e97cba967",
        "n":0
      },
      "scriptSig":"3046022100feb794273c985eca88c8862d584b6bbaed6bf33b8a055325ac30258710e75760022100b2d78e3e181a730aace758e5c7ca3288d92a23adbf8455a50120cb993f1e41bb01 03f016231bc63cca438b01ac8642e05e00042240cf93bd339fc8970e3622a0c94d"
    }
  ],
  "out":[
    {
      "value":"947.00000000",
      "scriptPubKey":"OP_DUP OP_HASH160 30fbd724042866d6133dca367df44dcfb512929b OP_EQUALVERIFY OP_CHECKSIG"
    },
    {
      "value":"10.00000000",
      "scriptPubKey":"OP_DUP OP_HASH160 cee4ae95cac24f014355afc12f1492b328625294 OP_EQUALVERIFY OP_CHECKSIG"
    }
  ]
}
JSON

def private_key_for_address(address)
  if address == 'mjcSuqvGTuq8Ys82juwa69eAb4Z69VaqEE'
    'FA45A0CE998DBC372DB1DD323D689A6FDBA18F5EF8D5E4453EA2454AC4EC4B10'
  elsif address == 'mzNuSfzgd1ZNJRAaKA2E5Zhp3ThES8Qqxi'
    'B74D503FFE4A27F4B93AFD0696885EF57AD36A0515456E2040EF9418D63D4E7A'
  end
end

def input_transaction(json)
  bytes = Bitcoin::Protocol::Tx.from_json(json).to_payload.unpack('c*').to_java(:byte)
  Transaction.new(network_params, bytes)
end

def transaction_jsons_for_address(address)
  if address == 'mjcSuqvGTuq8Ys82juwa69eAb4Z69VaqEE'
    [TX_JSON_1]
  elsif address == 'mzNuSfzgd1ZNJRAaKA2E5Zhp3ThES8Qqxi'
    [TX_JSON_2]
  end
end

def transaction_outputs
  input_addresses.inject([]) do |result, address|
    transaction_jsons_for_address(address).each do |json|
      input_transaction(json).getOutputs().each do |tx_output|
        if address == tx_output.getScriptPubKey().getToAddress(network_params).toString() && tx_output.isAvailableForSpending()
          result << { transaction_output: tx_output, address: address }
        end
      end
    end

    result
  end
end

def input_addresses
  %w(mjcSuqvGTuq8Ys82juwa69eAb4Z69VaqEE mzNuSfzgd1ZNJRAaKA2E5Zhp3ThES8Qqxi)
end

def input_signature(index)
  private_key = private_keys(index)
end

def outputs
  [
    {
      address: 'mng6y83G5DWUseA9t2jVM53brjDaFNvGzB',
      amount: 13 * 100_000_000
    }
  ]
end

def build_ec_key(private_key_hex)
  ECKey.new(BigInteger.new(private_key_hex, 16))
end

def sign_transaction_input(transaction, input_index, private_key)
  tx_input = transaction.getInput(input_index)
  raise ArgumentError, "No connected output: #{tx_input}" if tx_input.getOutpoint().getConnectedOutput().nil?
  raise ArgumentError, "Signing already signed transaction: #{tx_input}" if tx_input.getScriptBytes().length != 0
  begin
    tx_input.getScriptSig().correctlySpends(transaction, input_index, tx_input.getOutpoint().getConnectedOutput().getScriptPubKey(), true)
    raise ArgumentError, "Input already spent: #{tx_input}"
  rescue ScriptException
    # input not spent... what we want
  end

  key = build_ec_key(private_key)
  connected_pub_key_script = tx_input.getOutpoint().getConnectedPubKeyScript()
  signature = transaction.calculateSignature(input_index, key, nil, connected_pub_key_script, Transaction::SigHash::ALL, false)

  # scriptPubKey = input.getOutpoint().getConnectedOutput().getScriptPubKey();
  tx_input.setScriptSig(ScriptBuilder.createInputScript(signature, key))
  begin
    tx_input.verify()
  rescue ScriptException => e
    raise ArgumentError, "Unable to verify signature: #{e}"
  rescue VerificationException => e
    raise ArgumentError, "Unable to verify signature: #{e}"
  end

  tx_input.getScriptSig()
end

# Director gets #participants addresses
# Create an unsigned transaction: For each address, get all unspent transactions for input addresses and add outputs for each output

# Participant builds same transaction and verifies transaction hash and that all of my inputs and outputs are present

def build_unsigned_transaction
  Transaction.new(network_params).tap do |transaction|
    transaction_outputs.each do |hash|
      tx_output = hash[:transaction_output]
      puts "adding input from #{tx_output} with value #{tx_output.getValue()}"
      transaction.add_input(tx_output)
    end

    outputs.each do |hash|
      puts "adding output to #{hash.inspect}"
      transaction.add_output(BigInteger.new(hash[:amount].to_s), Address.new(network_params, hash[:address]))
    end
  end
end


unsigned_tx = build_unsigned_transaction
puts "--- DIRECTOR UNSIGNED TX HASH: #{unsigned_tx.getHash()}"


tx_input_script_signatures = []

input_addresses.each do |my_input_address|
  puts "SIGNING with #{my_input_address}"
  my_private_key = private_key_for_address(my_input_address)
  my_transaction = build_unsigned_transaction
  transaction_outputs.each_with_index do |hash, index|
    if hash[:address] == my_input_address
      signature = sign_transaction_input(my_transaction, index, my_private_key)
      puts "Signed input #{index} for #{hash[:address]}: #{signature}"
      tx_input_script_signatures[index] = signature
    end
  end
  puts "--- PARTICIPANT #{my_input_address} TX HASH: #{my_transaction.getHash()}"
end


signed_tx = build_unsigned_transaction.tap do |transaction|
  transaction.getInputs().each_with_index do |tx_input, index|
    tx_input.setScriptSig(tx_input_script_signatures[index])
    begin
      tx_input.verify()
    rescue ScriptException => e
      raise ArgumentError, "Unable to verify signature: #{e}"
    rescue VerificationException => e
      raise ArgumentError, "Unable to verify signature: #{e}"
    end
  end
end

puts "--- DIRECTOR SIGNED TX HASH: #{signed_tx.getHash()}"


peer_group = PeerGroup.new(network_params)
peer_group.setUserAgent("Coinmux", Coinmux::VERSION)
peer_group.addPeerDiscovery(DnsDiscovery.new(network_params))
peer_group.startAndWait()
peer_group.broadcastTransaction(signed_tx).get()
