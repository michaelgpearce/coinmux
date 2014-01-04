class Coin2Coin::BitcoinNetwork
  include Singleton, Coin2Coin::BitcoinUtil

  def current_block_height_and_nonce
    raise "TODO"
  end
  
  def block_exists?(block_height, nonce)
    raise "TODO"
  end

  # nil returned if transaction not found, 0 returned if in transaction pool, 1+ if accepted into blockchain
  def transaction_confirmations(transaction_id)
    raise "TODO"
  end
end