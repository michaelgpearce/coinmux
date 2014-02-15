require 'yaml'
require 'erb'

class Coinmux::Config
  include Coinmux::Proper, Singleton

  property :bitcoin_network, :coin_join_uri, :webbtc_host, :show_transaction_url
  
  def initialize
    YAML.load(ERB.new(Coinmux::FileUtil.read_content('config', 'coinmux.yml')).result)[Coinmux.env].each do |key, value|
      self[key] = value
    end
  end
end