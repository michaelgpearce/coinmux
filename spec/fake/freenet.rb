require 'singleton'

class Coin2Coin::Fake::Freenet
  attr_accessor :hash
  
  def initialize
    @hash = Hash.new
  end
  
  def generate_keypair
    value = rand
    ["insert-#{value}", "request-#{value}"]
  end
  
  def insert(insert_key, data, &callback)
    (hash[insert_key.gsub(/^insert-/, '')] ||= []).tap do |array|
      array << data
    end
    
    yield(Coin2Coin::FreenetEvent.new(:data => data))
  end
  
  def fetch_last(request_key, &callback)
    yield(Coin2Coin::FreenetEvent.new(:data => fetch(request_key).last))
  end
  
  def fetch_all(request_key, &callback)
    yield(Coin2Coin::FreenetEvent.new(:data => fetch(request_key)))
  end
  
  def fetch_most_recent(request_key, max_items, &callback)
    return [] if max_items <= 0
    yield(Coin2Coin::FreenetEvent.new(:data => fetch(request_key)))[-1*max_items..-1]
  end
  
  def fetch(request_key)
    (hash[request_key.gsub(/^request-/, '')] || []).clone
  end
end