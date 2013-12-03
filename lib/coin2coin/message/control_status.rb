class Coin2Coin::Message::ControlStatus < Coin2Coin::Message::Base
  property :status
  property :transaction_id
  property :updated_at
  
  def initialize
    self.status = "WaitingForInputs"
    self.transaction_id = nil
    
    block_height, nonce = Coin2Coin::Bitcoin.current_block_height_and_nonce
    self.updated_at = {
      :block_height => block_height,
      :nonce => nonce
    }
  end
end
