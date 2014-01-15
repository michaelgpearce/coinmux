class Gui::Model::Input < Gui::Model::Base
  add_attributes :amount, :bitcoin_address, :private_key, :public_key, :transactions

  def initialize(attrs = {})
    super({
      :amount => 0,
      :transactions => []
    }.merge(attrs))
  end
  
  class << self
    def find_by_private_key(private_key)
      public_key = get_public_key(private_key)
      bitcoin_address = get_bitcoin_address(public_key)
      unspent_transactions = Gui::Model::Transaction.find_all_unspent_by_bitcoin_address(bitcoin_address)
      
      self.new(
        :amount => unspent_transactions.collect(&:amount).sum,
        :bitcoin_address => bitcoin_address,
        :private_key => private_key,
        :public_key => public_key
      )
    end
    
    private
    
    def get_public_key(private_key)
      "0310F5AC0359088C6CA22F768E17F63C70077055535F3401CC9AA470848626480F"
    end
    
    def get_bitcoin_address(public_key)
      "1KRn5YChBkV8Q9xq91Y3iqk4YPBJSr33ef"
    end
  end
end
