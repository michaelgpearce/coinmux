class Coinmux::DataStore::Factory
  NETWORK_TO_CLASS = {
    p2p: 'Tomp2p',
    filesystem: 'File',
    test: 'Memory'
  }

  class << self
    def build(coin_join_uri)
      data_store_class_name = NETWORK_TO_CLASS[coin_join_uri.network.to_sym]

      Coinmux::DataStore.const_get(data_store_class_name).new(coin_join_uri)
    end
  end
end
