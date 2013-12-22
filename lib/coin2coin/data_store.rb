require 'singleton'

class Coin2Coin::DataStore
  include Singleton
  
  def initialize
    @freenet_hash = FreenetHash.new
  end
  
  def generate_keypair
    @freenet_hash.generate_keypair
  end
  
  def insert(insert_key, data, &callback)
    @freenet_hash.put(insert_key, data, &callback)
  end
  
  def fetch_last(request_key, &callback)
    @freenet_hash.fetch(request_key, &callback)
  end
  
  def fetch_all(request_key, &callback)
  end
  
  def fetch_most_recent(request_key, max_items, &callback)
  end
end