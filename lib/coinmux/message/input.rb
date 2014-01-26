class Coinmux::Message::Input < Coinmux::Message::Base
  add_properties :message_public_key, :address, :change_address, :change_transaction_output_identifier, :signature
  
  attr_accessor :message_private_key, :private_key
  
  validates :message_public_key, :address, :signature, :change_transaction_output_identifier, :presence => true
  validate :signature_correct
  validate :change_address_valid, :if => :change_address
  validate :change_amount_not_more_than_transaction_fee, :unless => :change_address
  validate :input_has_enough_value
  
  class << self
    def build(coin_join, private_key_hex, change_address = nil)
      message = super(coin_join)
      message.message_private_key, message.message_public_key = pki_facade.generate_keypair

      message.private_key = private_key_hex
      message.address = bitcoin_crypto_facade.address_for_private_key!(private_key_hex)
      message.signature = bitcoin_crypto_facade.sign_message!(coin_join.identifier, private_key_hex)

      message.change_address = change_address
      message.change_transaction_output_identifier = digest_facade.random_identifier

      message
    end
  end
  
  private
  
  def signature_correct
    unless bitcoin_crypto_facade.verify_message(coin_join.identifier, signature, address)
      errors[:signature] << "is not correct for address #{address}"
    end
  end
  
  def change_address_valid
    unless bitcoin_crypto_facade.verify_address(change_address)
      errors[:change_address] << "is not a valid address"
    end
  end

  def change_amount_not_more_than_transaction_fee
    # make sure not to send a large transaction fee because no change address specified
    # TODO
  end
  
  def input_has_enough_value
    unless coin_join.input_has_enough_unspent_value?(address)
      errors[:address] << "does not have enough unspent value"
    end
  end
end
