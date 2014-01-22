class Coinmux::Fake::BaseDataStore
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
    hash = JSON.parse(identifier)
    key = hash['key']
    raise "Cannot insert" unless hash['can_insert']

    array = read(key) || []
    array << identifier
    write(key, array)

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
    hash = JSON.parse(identifier)
    key = hash['key']
    raise "Cannot request" unless hash['can_request']

    (read(key) || []).clone
  end
end