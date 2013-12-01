class Coin2Coin::Transaction < Coin2Coin::Base
  add_attributes :bitcoin_address, :amount, :tx_id, :index
  
  class << self
    def find_all_unspent_by_bitcoin_address(bitcoin_address)
      [
        Coin2Coin::Transaction.new(:bitcoin_address => bitcoin_address, :amount => 1 * 1_000_000, :tx_id => '0011113432', :index => 1),
        Coin2Coin::Transaction.new(:bitcoin_address => bitcoin_address, :amount => 2.45 * 1_000_000, :tx_id => '987234566756', :index => 1),
        Coin2Coin::Transaction.new(:bitcoin_address => bitcoin_address, :amount => 3.48 * 1_000_000, :tx_id => '123872843', :index => 3)
      ]
    end
  end
end
