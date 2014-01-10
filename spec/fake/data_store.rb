class Coinmux::Fake::DataStore
  attr_accessor :hash
  
  def initialize
    @hash = Hash.new
  end
  
  def generate_identifier
    { 'key' => rand.to_s, 'can_insert' => true, 'can_request' => true }.to_json
  end

  def convert_to_request_only_identifier(identifier)
    JSON.parse(identifier).merge('can_insert' => false).to_json
  end

  def identifier_can_insert?(identifier)
    JSON.parse(identifier)['can_insert'] rescue false
  end

  def identifier_can_request?(identifier)
    JSON.parse(identifier)['can_request'] rescue false
  end

  def insert(identifier, data, &callback)
    identifier = JSON.parse(identifier)['key']
    (hash[identifier] ||= []).tap do |array|
      array << data
    end
    
    yield(Coinmux::Event.new(:data => data))
  end
  
  def fetch_last(identifier, &callback)
    yield(Coinmux::Event.new(:data => fetch(identifier).last))
  end
  
  def fetch_all(identifier, &callback)
    yield(Coinmux::Event.new(:data => fetch(identifier)))
  end
  
  def fetch_most_recent(identifier, max_items, &callback)
    return [] if max_items <= 0
    yield(Coinmux::Event.new(:data => fetch(identifier)))[-1*max_items..-1]
  end
  
  def fetch(identifier)
    identifier = JSON.parse(identifier)['key']
    (hash[identifier] || []).clone
  end
end