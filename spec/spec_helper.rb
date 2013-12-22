require File.join(File.dirname(__FILE__), '..', 'lib', 'coin2coin')

ENV['COIN2COIN_ENV'] = 'test'

module Coin2Coin
  module Fake
  end
end

require 'spec/fake/data_store'
require 'spec/fake/bitcoin'

def fake_all
  fake_data_store
  fake_bitcoin
end

def fake_data_store
  @fake_data_store ||= (
    data_store = Coin2Coin::Fake::DataStore.new.tap do |data_store|
      Coin2Coin::DataStore.stub(:instance).and_return(data_store)
    end
  )
end

def fake_bitcoin
  @fake_bitcoin ||= Coin2Coin::Fake::Bitcoin.new.tap do |bitcoin|
    Coin2Coin::Bitcoin.stub(:instance).and_return(bitcoin)
  end
end

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'
end
