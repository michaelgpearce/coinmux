require 'json'

class Coin2Coin::Message::Input < Coin2Coin::Message::Base
  add_properties :message_public_key, :address, :public_key, :change_address, :change_amount, :signature
  
  attr_accessor :message_private_key, :private_key
  
  # validates :message_public_key, :address, :public_key, :signature, :presence => true
  validate :address_matches_public_key
  validate :signature_correct
  validate :change_address_valid, :if => :change_address
  validate :change_amount_and_coin_join_amount_less_than_input_amount
  
  class << self
    def build(coin_join, private_key_hex, change_address = nil, change_amount = nil)
      input = super(coin_join)
      input.message_private_key, input.message_public_key = Coin2Coin::PKI.generate_keypair

      input.private_key = private_key_hex
      input.public_key = Coin2Coin::Bitcoin.instance.public_key_for_private_key!(private_key_hex)
      input.address = Coin2Coin::Bitcoin.instance.address_for_public_key!(input.public_key)
      input.signature = Coin2Coin::Bitcoin.instance.sign_message!(coin_join.identifier, private_key_hex)

      input
    end
  end
  
  private
  
  def address_matches_public_key
    if Coin2Coin::Bitcoin.instance.address_for_public_key(public_key) != address
      errors[:public_key] << "is not correct for address #{address}"
    end
  end
  
  def signature_correct
    unless Coin2Coin::Bitcoin.instance.verify_message(coin_join.identifier, signature, address)
      errors[:signature] << "is not correct for address #{address}"
    end
  end
  
  def change_address_valid
    unless Coin2Coin::Bitcoin.instance.verify_address(change_address)
      errors[:change_address] << "is not a valid address"
    end
  end
  
  def change_amount_and_coin_join_amount_less_than_input_amount
    # TODO
  end
end
