class Coin2Coin::Message::CoinJoin < Coin2Coin::Message::Base
  VERSION = 1
  
  add_properties :version, :identifier, :message_public_key, :amount, :minimum_size
  add_list_association :inputs, :read_only => false
  add_list_association :outputs, :read_only => false
  add_fixed_association :message_verification, :read_only => true
  add_fixed_association :transaction, :read_only => true
  add_variable_association :status, :read_only => true
  
  attr_accessor :message_private_key
  
  class << self
    def build(amount = 100_000_000, minimum_size = 5)
      message = super(nil)
      message.coin_join = message

      message.version = VERSION
      message.identifier = Coin2Coin::Digest.random_identifier
      message.message_private_key, message.message_public_key = Coin2Coin::PKI.generate_keypair
      message.amount = amount
      message.minimum_size = minimum_size

      message
    end
  end
end
