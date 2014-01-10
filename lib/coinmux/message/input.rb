class Coinmux::Message::Input < Coinmux::Message::Base
  add_properties :message_public_key, :address, :change_address, :signature
  
  attr_accessor :message_private_key, :private_key
  
  validates :message_public_key, :address, :signature, :presence => true
  validate :signature_correct
  validate :change_address_valid, :if => :change_address
  validate :change_amount_not_more_than_transaction_fee, :unless => :change_address
  validate :input_has_enough_value
  
  class << self
    def build(coin_join, private_key_hex, change_address = nil)
      message = super(coin_join)
      message.message_private_key, message.message_public_key = Coinmux::PKI.instance.generate_keypair

      message.private_key = private_key_hex
      message.address = Coinmux::BitcoinCrypto.instance.address_for_private_key!(private_key_hex)
      message.signature = Coinmux::BitcoinCrypto.instance.sign_message!(coin_join.identifier, private_key_hex)

      message
    end
  end
  
  private
  
  def signature_correct
    unless Coinmux::BitcoinCrypto.instance.verify_message(coin_join.identifier, signature, address)
      errors[:signature] << "is not correct for address #{address}"
    end
  end
  
  def change_address_valid
    unless Coinmux::BitcoinCrypto.instance.verify_address(change_address)
      errors[:change_address] << "is not a valid address"
    end
  end

  def change_amount_not_more_than_transaction_fee
    # make sure not to send a large transaction fee because no change address specified
    # TODO
  end
  
  def input_has_enough_value
    # TODO
  end
end
