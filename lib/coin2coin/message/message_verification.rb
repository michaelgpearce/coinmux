class Coin2Coin::Message::MessageVerification < Coin2Coin::Message::Base
  property :encrypted_message_identifier
  property :encrypted_secret_keys
  
  attr_accessor :message_identifier, :secret_key
  
  def initialize(input_message_public_keys)
    @message_identifier = Coin2Coin::Digest.hex_digest(rand.to_s)
    @secret_key = Coin2Coin::Digest.hex_digest(rand.to_s)
    
    self.encrypted_message_identifier = Coin2Coin::Cipher.encrypt(@secret_key, @message_identifier)
    
    # only selected inputs will get the secret to decrypt the identifier
    self.encrypted_secret_keys = input_message_public_keys.inject({}) do |acc, input_message_public_key|
      acc[input_message_public_key] = Coin2Coin::PKI.public_encrypt(input_message_public_key, @secret_key)
      acc
    end
  end
end
