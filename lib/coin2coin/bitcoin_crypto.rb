class Coin2Coin::BitcoinCrypto
  include Singleton, Coin2Coin::BitcoinUtil

  import 'java.math.BigInteger'
  import 'java.security.SignatureException'
  import 'com.google.bitcoin.core.ECKey'
  import 'com.google.bitcoin.core.Address'
  import 'com.google.bitcoin.core.Utils'
  import 'com.google.bitcoin.core.NetworkParameters'
  import 'org.spongycastle.util.encoders.Hex'

  class << self
    def def_no_raise_method(method, raise_return_value)
      define_method(method) do |*args|
        begin
          send("#{method}!", *args)
        rescue Coin2Coin::Error
          raise_return_value
        end
      end
    end
  end

  def verify_message!(message, signature_base_64, address)
    address == ECKey.signedMessageToKey(message, signature_base_64).toAddress(network_params).to_s
  rescue => e
    raise Coin2Coin::Error, "Message cannot be verified: #{e}"
  end
  def_no_raise_method(:verify_message, false)
  
  def sign_message!(message, private_key_hex)
    build_ec_key(private_key_hex).signMessage(message)
  rescue => e
    raise Coin2Coin::Error, "Message cannot be signed: #{e}"
  end
  def_no_raise_method(:sign_message, nil)
  
  def public_key_for_private_key!(private_key_hex)
    Hex.encode(build_ec_key(private_key_hex).getPubKey()).to_s.upcase
  rescue => e
    raise Coin2Coin::Error, "Cannot get public key from private key: #{e}"
  end
  def_no_raise_method(:public_key_for_private_key, nil)
  
  def address_for_public_key!(public_key_hex)
    Address.new(network_params, Utils.sha256hash160(Hex.decode(public_key_hex))).to_s
  rescue => e
    raise Coin2Coin::Error, "Message cannot be signed: #{e}"
  end
  def_no_raise_method(:address_for_public_key, nil)
  
  def address_for_private_key!(private_key_hex)
    address_for_public_key!(public_key_for_private_key!(private_key_hex))
  end
  def_no_raise_method(:address_for_private_key, nil)
  
  def verify_address!(address)
    Address.new(network_params, address)
    true
  rescue => e
    raise Coin2Coin::Error, "Address not valid: #{e}"
  end
  def_no_raise_method(:verify_address, false)
  
  private

  def build_ec_key(private_key_hex)
    ECKey.new(BigInteger.new(private_key_hex, 16))
  end
end