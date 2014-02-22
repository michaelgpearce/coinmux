require 'yaml'

class Coinmux::Config
  include Coinmux::Proper

  CONFIG = YAML.load(Coinmux::FileUtil.read_content('config', 'coinmux.yml'))

  property :name, :bitcoin_network, :coin_join_uris, :webbtc_host, :show_transaction_url
  
  class << self
    def configs
      @configs ||= %w(mainnet testnet test).each_with_object({}) do |config_key, configs|
        configs[config_key] = self.new(config_key)
      end
    end

    %w(mainnet testnet test).each do |config_key|
      define_method(config_key) do
        self[config_key]
      end
    end

    def [](config_key)
      configs[config_key]
    end

    def instance
      @instance ||= (
        case Coinmux.env
        when 'production'; mainnet
        when 'development'; testnet
        when 'test'; test
        end)
    end

    def instance=(config)
      @instance = config
    end
  end

  def initialize(config_key)
    CONFIG[config_key].each do |key, value|
      self[key] = value
    end
  end

  def coin_join_uri
    coin_join_uris.first[1]
  end
end