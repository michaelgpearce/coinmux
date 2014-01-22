require 'active_support/cache'

class Coinmux::Fake::FileDataStore < Coinmux::Fake::BaseDataStore
  include Singleton

  def initialize
    @data_store ||= ActiveSupport::Cache::FileStore.new(File.join(Coinmux.root, 'tmp', 'file_data_store'))
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