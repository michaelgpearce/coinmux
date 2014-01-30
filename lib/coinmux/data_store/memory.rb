class Coinmux::DataStore::Memory < Coinmux::DataStore::Base
  def initialize(coin_join_uri)
    super(coin_join_uri)
    
    @data_store ||= Hash.new
  end

  def clear
    @data_store.clear
  end

  protected

  def write(key, value)
    @data_store[key] = value
  end

  def read(key)
    @data_store[key]
  end
end
