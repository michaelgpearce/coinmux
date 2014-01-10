require File.join(File.dirname(__FILE__), '..', 'lib', 'coin2coin')

ENV['COIN2COIN_ENV'] = 'test'

module Coin2Coin
  module Fake
  end
end

require 'rspec'
require 'spec/fake/application'
require 'spec/fake/data_store'
require 'spec/fake/bitcoin_network'
require 'factory_girl'
require 'pry'

FactoryGirl.find_definitions rescue puts "Warn: #{$!}"

# allow loading in console
require 'rspec/mocks'
RSpec::Mocks::setup(Object.new)

def fake_all
  fake_application
  fake_data_store
  fake_bitcoin_network
end

def fake_all_network_connections
  fake_data_store
  fake_bitcoin_network
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

def fake_bitcoin_network
  @fake_bitcoin_network ||= Coin2Coin::Fake::BitcoinNetwork.new.tap do |bitcoin_network|
    Coin2Coin::BitcoinNetwork.stub(:instance).and_return(bitcoin_network)
  end
end

def load_fixture(name)
  open(File.join(File.dirname(__FILE__), 'fixtures', name)) { |f| f.read }
end

module Helper
  @@bitcoin_infos = []
  @@bitcoin_info_index = 0

  def self.next_bitcoin_info
    if (bitcoin_info = @@bitcoin_infos[@@bitcoin_info_index]).nil?
      bitcoin_info = {}
      bitcoin_info[:private_key] = "%064x" % (@@bitcoin_info_index + 1)
      bitcoin_info[:public_key] = Coin2Coin::BitcoinCrypto.instance.public_key_for_private_key!(bitcoin_info[:private_key])
      bitcoin_info[:address] = Coin2Coin::BitcoinCrypto.instance.address_for_public_key!(bitcoin_info[:public_key])
      bitcoin_info[:identifier] = "valid-identifier-#{@@bitcoin_info_index + 1}"
      bitcoin_info[:signature] = Coin2Coin::BitcoinCrypto.instance.sign_message!(bitcoin_info[:identifier], bitcoin_info[:private_key])

      @@bitcoin_infos << bitcoin_info
    end

    @@bitcoin_info_index += 1
    bitcoin_info
  end
end

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  config.before do
    Helper.class_variable_set(:@@bitcoin_info_index, 0) # start over reading bitcoin infos for each spec
  end
end
