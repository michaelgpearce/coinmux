module Coinmux::Facades
  module Methods
    def bitcoin_crypto_facade
      Coinmux::BitcoinCrypto.instance
    end

    def bitcoin_network_facade
      Coinmux::BitcoinNetwork.instance
    end

    def cipher_facade
      Coinmux::Cipher.instance
    end

    def config_facade
      Coinmux::Config.instance
    end

    def data_store_facade
      require 'spec/fake/base_data_store'
      require 'spec/fake/file_data_store'
      Coinmux::Fake::FileDataStore.instance
      #Coinmux::DataStore.instance
    end

    def digest_facade
      Coinmux::Digest.instance
    end

    def http_facade
      Coinmux::Http.instance
    end

    def pki_facade
      Coinmux::PKI.instance
    end

    def debug(*messages)
      Coinmux::Logger.instance.debug(*messages)
    end

    def info(*messages)
      Coinmux::Logger.instance.info(*messages)
    end

    def warn(*messages)
      Coinmux::Logger.instance.warn(*messages)
    end

    def error(*messages)
      Coinmux::Logger.instance.error(*messages)
    end

    def fatal(*messages)
      Coinmux::Logger.instance.fatal(*messages)
    end
  end

  def self.included(base)
    base.extend(Methods)
    base.send(:include, Methods)
  end
end
