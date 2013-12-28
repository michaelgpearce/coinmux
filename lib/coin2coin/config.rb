require 'yaml'
require 'erb'
require 'singleton'

class Coin2Coin::Config < Hashie::Dash
  include Singleton

  property :bitcoin_network
  property :coin_join_uri
  
  def initialize
    config_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'config.yml'))
    env_key = ENV['COIN2COIN_ENV'] || 'development'
    
    YAML.load(ERB.new(File.read(config_path)).result)[env_key].each do |key, value|
    	self[key] = value
    end
  end
end