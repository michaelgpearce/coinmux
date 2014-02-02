require 'yaml'
require 'erb'

class Coinmux::Config
  include Coinmux::Proper, Singleton

  property :bitcoin_network, :coin_join_uri, :webbtc_host
  
  def initialize
    config_path = File.join(Coinmux.root, 'config', 'coinmux.yml')

    YAML.load(ERB.new(File.read(config_path)).result)[Coinmux.env].each do |key, value|
      self[key] = value
    end
  end
end