class Coinmux::Fake::MemoryDataStore < Coinmux::Fake::BaseDataStore
  include Singleton
  
  def initialize
    @data_store ||= Hash.new
  end

  def clear
    @data_store.clear
  end

  def write(key, value)
    @data_store[key] = value
  end

  def read(key)
    @data_store[key]
  end
end
