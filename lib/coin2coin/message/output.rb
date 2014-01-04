class Coin2Coin::Message::Output < Coin2Coin::Message::Base
  property :address
  property :message_verification
  
  def initialize(params = {:message_identifier => nil, :address => nil})
    params.assert_valid_keys(:message_identifier, :address)
    
    self.address = params[:address]
    self.message_verification = Coin2Coin::Digest.instance.message_digest(params[:message_identifier], params[:address])
  end
end
