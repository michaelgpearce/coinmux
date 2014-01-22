require 'active_support/cache'

class Coinmux::Fake::FileDataStore < Coinmux::Fake::BaseDataStore
  def initialize
    @data_store ||= ActiveSupport::Cache::FileStore.new(File.join(File.dirname(__FILE__), '..', '..', 'data_store.bin'))
  end

  def clear
    @data_store.clear
  end

  def write(key, value)
    @data_store.write(key, value)
    value
  end

  def read(key)
    @data_store.read(key)
  end
end