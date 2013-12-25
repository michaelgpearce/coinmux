class Coin2Coin::Fake::Bitcoin
  def initialize
    @blocks = []
    @transaction_pool = []

    test_confirm_block
  end

  def current_block_height_and_nonce
    [@blocks.size, @blocks.last[:nonce]]
  end

  def block_exists?(block_height, nonce)
    block = @blocks[block_height - 1]

    block && block[:nonce] == nonce
  end

  # nil returned if transaction not found, 0 returned if in transaction pool, 1+ if accepted into blockchain
  def transaction_confirmations(transaction_id)
    if @transaction_pool.include?(transaction_id)
      0
    elsif block_index = test_find_block_index_with_transaction_id(transaction_id)
      block_index + 1
    else
      nil
    end
  end

  def test_add_transaction_id_to_pool(transaction_id)
    @transaction_pool << transaction_id
  end

  def test_confirm_block
    @blocks << {:nonce => rand(1..1_000_000), :transaction_ids => @transaction_pool.dup}
    @transaction_pool.clear

    current_block_height_and_nonce
  end

  private

  def test_find_block_index_with_transaction_id(transaction_id)
    @blocks.find_index { |block| block[:transaction_ids].include?(transaction_id) }
  end
end