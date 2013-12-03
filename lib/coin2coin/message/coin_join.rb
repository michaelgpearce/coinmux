class Coin2Coin::Message::CoinJoin < Coin2Coin::Message::Base
  VERSION = 1
  
  property :version, :default => VERSION
  property :controller_instance
  
  def initialize
    self.controller_instance = Coin2Coin::Message::FreenetAssociation.new(true)
  end
end
