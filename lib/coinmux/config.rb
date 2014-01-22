require 'yaml'
require 'erb'

class Coinmux::Config < Hashie::Dash
  include Singleton

  property :bitcoin_network
  property :coin_join_uri
  property :webbtc_host
  
  def initialize
    config_path = File.join(Coinmux.root, 'config.yml')

    YAML.load(ERB.new(File.read(config_path)).result)[Coinmux.env].each do |key, value|
      self[key] = value
    end
  end
end