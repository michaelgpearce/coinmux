# MessageVerificationInstance:
# {
#   IdentifierPublicKey: '123...abc' # RSA 2048 PKI (PKCS1_PADDING); public key used below; unique from all others
#   EncryptedIdentifier: '123...abc' # a random value encrypted with private key for #IdentifierPublicKey; input with access to the Identifier is verified, but we purposefully cannot identify which input sends a verified message
#   EncryptedIdentifierPrivateKeys: [
#     '123...abc', # private key for MessageVerificationInstance#IdentifierPublicKey encrypted with each InputList#MessagePublicKey that will be in transaction
#     ...
#   ]
# }

class Coin2Coin::Message::MessageVerification < Coin2Coin::Message::Base
  property :identifier_public_key
  property :encrypted_identifier
  property :encrypted_identifier_private_keys
  
  attr_accessor :identifier, :identifier_private_key
  
  def initialize(input_message_public_keys)
    @identifier = Digest::SHA2.new(256).digest(rand.to_s)
    
    @identifier_private_key, self.identifier_public_key = Coin2Coin::PKI.generate_keypair
    
    self.encrypted_identifier = Coin2Coin::PKI.encrypt(@identifier_private_key, @identifier)
    
    self.encrypted_identifier_private_keys = input_message_public_keys.collect do |input_message_public_key|
    end
  end
end
