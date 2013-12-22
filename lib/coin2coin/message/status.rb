class Coin2Coin::Message::Status < Coin2Coin::Message::Base
  property :identifier
  property :status
  property :transaction_id
  property :updated_at
  
  def initialize(params = {:status => nil, :transaction_id => nil})
    params.assert_valid_keys(:status, :transaction_id)
    
    self.identifier = Coin2Coin::Digest.random_identifier
    self.status = params[:status]
    self.transaction_id = params[:transaction_id]
    
    block_height, nonce = Coin2Coin::Bitcoin.instance.current_block_height_and_nonce
    self.updated_at = {
      :block_height => block_height,
      :nonce => nonce
    }
  end
end
