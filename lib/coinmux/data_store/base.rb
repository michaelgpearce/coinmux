class Coinmux::DataStore::Base
  include Coinmux::Facades
  DATA_TIME_TO_LIVE = 1 * 60 * 60

  attr_accessor :coin_join_uri, :connected

  def initialize(coin_join_uri)
    self.connected = false
    self.coin_join_uri = coin_join_uri
  end

  def coin_join_identifier
    "#{coin_join_uri.params["identifier"] || "default"}-rw"
  end

  def connect(&callback)
    self.connected = true
    yield(Coinmux::Event.new)
  end

  def disconnect(&callback)
    self.connected = false
    yield(Coinmux::Event.new) if block_given?
  end

  def generate_identifier
    "#{digest_facade.random_identifier}-rw"
  end

  def convert_to_request_only_identifier(identifier)
    identifier.gsub(/-rw$/, '-ro')
  end

  def identifier_can_insert?(identifier)
    !!(identifier =~ /-rw$/)
  end

  def identifier_can_request?(identifier)
    true
  end

  def insert(identifier, data, &callback)
    raise "Cannot insert" unless identifier_can_insert?(identifier)
    raise "Data store not connected" unless connected

    key = key_from_identifier(identifier)

    array = read(key) || []
    array << data
    write(key, array)

    debug "DATASTORE INSERT #{identifier}: #{data}"
    yield(Coinmux::Event.new(:data => data))
  end
  
  def fetch_first(identifier, &callback)
    yield(Coinmux::Event.new(:data => fetch(identifier).first))
  end
  
  def fetch_last(identifier, &callback)
    yield(Coinmux::Event.new(:data => fetch(identifier).last))
  end
  
  def fetch_all(identifier, &callback)
    yield(Coinmux::Event.new(:data => fetch(identifier)))
  end
  
  # items are in reverse inserted order
  def fetch_most_recent(identifier, max_items, &callback)
    data = fetch(identifier)
    yield(Coinmux::Event.new(:data => (data[-1*max_items..-1] || data).reverse))
  end

  private

  def key_from_identifier(identifier)
    identifier.gsub(/-r.$/, '')
  end

  def fetch(identifier)
    raise "Data store not connected" unless connected

    key = key_from_identifier(identifier)

    data = (read(key) || []).clone
    debug "DATASTORE FETCH #{identifier}: #{data}"

    data
  end
end
