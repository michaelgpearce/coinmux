require 'yaml'
require 'erb'
require 'singleton'

class Coin2Coin::Config
  include Singleton
  
  def initialize
    config_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'config.yml'))
    env_key = ENV['COIN2COIN_ENV'] || 'development'
    
    @config = YAML.load(ERB.new(File.read(config_path)).result)[env_key]
  end
  
  def [](key)
    @config[key]
  end
end