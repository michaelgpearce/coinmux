class Coin2Coin::Message::Input < Coin2Coin::Message::Base
  property :message_public_key
  property :address
  property :public_key
  property :change_address
  property :change_amount
  property :signature
  
  attr_accessor :message_private_key
  
  def initialize(params = {:message_public_key => nil})
    params.assert_valid_keys(:message_identifier, :address)
    
    @message_private_key, self.message_public_key = Coin2Coin::PKI.generate_keypair
    self.address = nil
    self.public_key = nil
    self.change_address = nil
    self.change_amount = nil
    self.signature = nil
  end
end
