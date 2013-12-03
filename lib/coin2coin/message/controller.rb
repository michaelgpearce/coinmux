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
  
  def initialize
    @message_private_key, self.message_public_key = Coin2Coin::PKI.generate_keypair
    self.amount = 1 * 100_000_000
    self.minimum_size = 5
    self.input_list = Coin2Coin::Message::FreenetAssociation.new
    self.message_verification_instance = Coin2Coin::Message::FreenetAssociation.new(true)
    self.output_list = Coin2Coin::Message::FreenetAssociation.new
    self.transaction_instance = Coin2Coin::Message::FreenetAssociation.new(true)
    self.control_status_queue = Coin2Coin::Message::FreenetAssociation.new(true)
  end
end
