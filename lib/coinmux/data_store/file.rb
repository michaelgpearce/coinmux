require 'active_support/cache'

class Coinmux::DataStore::File < Coinmux::DataStore::Base
  CACHE_TTL = 1.minute

  def initialize(coin_join_uri)
    super(coin_join_uri)

    @data_store ||= ActiveSupport::Cache::FileStore.new(File.join(Coinmux.root, 'tmp', 'file_data_store'), expires_in: CACHE_TTL)
  end

  def clear
    @data_store.clear
  end

  protected

  def write(key, value)
    @data_store.write(key, value)
    value
  end

  def read(key)
    @data_store.read(key)
  end
end