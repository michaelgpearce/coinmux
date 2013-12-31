require File.join(File.dirname(__FILE__), '..', 'lib', 'coin2coin')

ENV['COIN2COIN_ENV'] = 'test'

module Coin2Coin
  module Fake
  end
end

require 'spec/fake/application'
require 'spec/fake/data_store'
require 'spec/fake/bitcoin'
require 'factory_girl'
require 'pry'

FactoryGirl.find_definitions

def fake_all
  fake_application
  fake_data_store
  fake_bitcoin
end

def fake_application
  @fake_application ||= (
    Coin2Coin::Fake::Application.new.tap do |application|
      Coin2Coin::Application.stub(:instance).and_return(application)
    end
  )
end

def fake_data_store
  @fake_data_store ||= (
    Coin2Coin::Fake::DataStore.new.tap do |data_store|
      Coin2Coin::DataStore.stub(:instance).and_return(data_store)
    end
  )
end

def fake_bitcoin
  @fake_bitcoin ||= Coin2Coin::Fake::Bitcoin.new.tap do |bitcoin|
    Coin2Coin::Bitcoin.stub(:instance).and_return(bitcoin)
  end
end

module Helpers
  # Keep these cached for performance reasons
  def self.create_bitcoin_info(index)
    @bitcoin_infos ||= []
    raise "Invalid index: #{index}" unless index <= @bitcoin_infos.size

    if (bitcoin_info = @bitcoin_infos[index]).nil?
      bitcoin_info = {}
      bitcoin_info[:private_key] = "%064x" % (index + 1)
      bitcoin_info[:public_key] = Coin2Coin::Bitcoin.instance.public_key_for_private_key!(bitcoin_info[:private_key])
      bitcoin_info[:address] = Coin2Coin::Bitcoin.instance.address_for_public_key!(bitcoin_info[:public_key])
      bitcoin_info[:identifier] = "valid-identifier-#{index + 1}"
      bitcoin_info[:signature] = Coin2Coin::Bitcoin.instance.sign_message!(bitcoin_info[:identifier], bitcoin_info[:private_key])

      @bitcoin_infos << bitcoin_info
    end

    bitcoin_info
  end
end


RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
  config.include Helpers
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'
end
