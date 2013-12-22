%w(bitcoinj-0.8.jar guava-15.0.jar sc-light-jdk15on-1.47.0.3.jar scprov-jdk15on-1.47.0.2.jar slf4j-api-1.7.5.jar slf4j-nop-1.7.5.jar).each do |f|
  require File.join(File.dirname(__FILE__), '..', f)
end
require 'singleton'

class Coin2Coin::Bitcoin
  include Singleton
  import 'java.math.BigInteger'
  import 'java.security.SignatureException'
  import 'com.google.bitcoin.core.ECKey'
  import 'com.google.bitcoin.core.Address'
  import 'com.google.bitcoin.core.NetworkParameters'

  def current_block_height_and_nonce
    raise "TODO"
  end
  
  def verify_message(message, signature_base_64, address)
    address == ECKey.signedMessageToKey(message, signature_base_64).toAddress(network_params).to_s
  rescue
    false
  end
  
  def sign_message(message, private_key_hex)
    ECKey.new(BigInteger.new(private_key_hex, 16)).signMessage(message)
  rescue
    nil
  end

  private

  def network_params
    Coin2Coin::Config.instance.bitcoin_network == 'mainnet' ? NetworkParameters.prodNet() : NetworkParameters.testNet3()
  end
end