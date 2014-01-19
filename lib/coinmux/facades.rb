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
      Coinmux::DataStore.instance
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
  end

  def self.included(base)
    base.extend(Methods)
    base.send(:include, Methods)
  end
end
