class Coinmux::DataStore::Tomp2p
  include Singleton
  
  def generate_identifier
    raise "TODO"
  end

  def convert_to_request_only_identifier(identifier)
    raise "TODO"
  end

  def identifier_can_insert?(identifier)
    raise "TODO"
  end

  def identifier_can_request?(identifier)
    raise "TODO"
  end

  def insert(identifier, data, &callback)
    raise "TODO"
  end
  
  def fetch_last(identifier, &callback)
    raise "TODO"
  end
  
  def fetch_all(identifier, &callback)
    raise "TODO"
  end
  
  def fetch_most_recent(identifier, max_items, &callback)
    raise "TODO"
  end
end