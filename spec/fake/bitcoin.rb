require 'singleton'

class Coin2Coin::Fake::Bitcoin

  def current_block_height_and_nonce
    [270794, 2617132268]
  end
end