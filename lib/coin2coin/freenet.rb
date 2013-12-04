require 'singleton'

class Coin2Coin::Freenet
  include Singleton
  
  def generate_keypair
    FreenetHash.new.generate_keypair
  end
  
  def insert(insert_key, data, &callback)
  end
  
  def fetch_last(request_key, &callback)
  end
  
  def fetch_all(request_key, &callback)
  end
  
  def fetch_most_recent(request_key, max_items, &callback)
  end
end