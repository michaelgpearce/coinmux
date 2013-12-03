class Coin2Coin::Message::Controller < Coin2Coin::Message::Base
  property :message_public_key
  property :amount
  property :minimum_size
  property :input_list
  property :message_verification_instance
  property :output_list
  property :transaction_instance
  property :control_status_queue
  
  attr_accessor :message_private_key
  
  def initialize(params = {:amount => nil, :minimum_size => nil})
    params.assert_valid_keys(:amount, :minimum_size)
    
    @message_private_key, self.message_public_key = Coin2Coin::PKI.generate_keypair
    self.amount = params[:amount]
    self.minimum_size = params[:minimum_size]
    self.input_list = Coin2Coin::Message::FreenetAssociation.new
    self.message_verification_instance = Coin2Coin::Message::FreenetAssociation.new(true)
    self.output_list = Coin2Coin::Message::FreenetAssociation.new
    self.transaction_instance = Coin2Coin::Message::FreenetAssociation.new(true)
    self.control_status_queue = Coin2Coin::Message::FreenetAssociation.new(true)
  end
end
