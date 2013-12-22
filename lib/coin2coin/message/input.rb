require 'json'

class Coin2Coin::Message::Input < Coin2Coin::Message::Base
  add_properties :message_public_key, :address, :public_key, :change_address, :change_amount, :signature
  
  attr_accessor :message_private_key, :coin_join
  
  validates :message_public_key, :address, :public_key, :signature, :presence => true
  validate :address_matches_public_key
  validate :signature_correct
  validate :change_address_valid, :if => :change_address
  validate :change_amount_and_coin_join_amount_less_than_input_amount
  
  def build
    input = super
    @message_private_key, self.message_public_key = Coin2Coin::PKI.generate_keypair
  end
  
  private
  
  def address_matches_public_key
  end
  
  def signature_correct
  end
  
  def change_address_valid
  end
  
  def change_amount_and_coin_join_amount_less_than_input_amount
  end
end
