require File.join(File.dirname(__FILE__), '..', 'lib', 'coinmux')

ENV['COINMUX_ENV'] = 'test'

module Coinmux
  module Fake
  end
end

require 'rspec'
require 'spec/fake/application'
require 'spec/fake/bitcoin_network'
require 'factory_girl'
require 'pry'

FactoryGirl.find_definitions rescue puts "Warn: #{$!}"

include Coinmux::BitcoinUtil, Coinmux::Facades

# allow loading in console
require 'rspec/mocks'
RSpec::Mocks::setup(Object.new)

def fake_all
  fake_application
  fake_bitcoin_network
end

def fake_all_network_connections
  fake_bitcoin_network
end

def fake_application
  @fake_application ||= (
    Coinmux::Fake::Application.new.tap do |application|
      Coinmux::Application.stub(:instance).and_return(application)
    end
  )
end

def fake_bitcoin_network
  @fake_bitcoin_network ||= Coinmux::Fake::BitcoinNetwork.new.tap do |bitcoin_network|
    Coinmux::BitcoinNetwork.stub(:instance).and_return(bitcoin_network)
  end
end

def stub_bitcoin_network_for_coin_join(coin_join)
  coin_join.stub(:transaction_object).and_return(double('transaction object double'))

  if !coin_join.inputs.value.empty?
    coin_join.inputs.value.each do |input|
      Coinmux::BitcoinNetwork.instance.stub(:unspent_inputs_for_address).with(input.address).and_return({
        { id: "tx-#{input.address}", index: 123 } => 1234 * SATOSHIS_PER_BITCOIN
      })
    end
  end

  if coin_join.transaction.value
    coin_join.transaction.value.inputs.each do |hash|
      address = hash['transaction_id'].split('-').last # we format the transaction id: "tx-address"
      change_address = coin_join.inputs.value.detect { |input| input.address == address }.change_address
      change_amount = coin_join.transaction.value.outputs.detect { |output| output['address'] == change_address }['amount']
      tx_amount = coin_join.amount + change_amount + coin_join.participant_transaction_fee

      result = {}.tap do |result|
        key = {id: hash['transaction_id'], index: hash['output_index']}
        result[key] = tx_amount
      end

      Coinmux::BitcoinNetwork.instance.stub(:unspent_inputs_for_address).with(address).and_return(result)
    end

    coin_join.transaction.value.inputs.each_with_index do |input_hash, transaction_input_index|
      Coinmux::BitcoinNetwork.instance.stub(:build_transaction_input_script_sig).with(coin_join.transaction_object, transaction_input_index, "privkey-#{transaction_input_index}").and_return("scriptsig-#{transaction_input_index}")
    end
  end

  Coinmux::BitcoinNetwork.instance.stub(:transaction_input_unspent?).and_return(true)
  Coinmux::BitcoinNetwork.instance.stub(:script_sig_valid?).and_return(true)
end

def data_store
  Helper.data_store
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
      bitcoin_info[:public_key] = bitcoin_crypto_facade.public_key_for_private_key!(bitcoin_info[:private_key])
      bitcoin_info[:address] = bitcoin_crypto_facade.address_for_public_key!(bitcoin_info[:public_key])
      bitcoin_info[:identifier] = "valid-identifier-#{@@bitcoin_info_index + 1}"
      bitcoin_info[:signature] = bitcoin_crypto_facade.sign_message!(bitcoin_info[:identifier], bitcoin_info[:private_key])

      @@bitcoin_infos << bitcoin_info
    end

    @@bitcoin_info_index += 1
    bitcoin_info
  end

  def self.bitcoin_info_for_address(address)
    @@bitcoin_infos.detect { |bitcoin_info| bitcoin_info[:address] == address }
  end

  def self.data_store
    @data_store ||= (
      coin_join_uri = Coinmux::CoinJoinUri.parse(Coinmux::Config.instance.coin_join_uri)
      Coinmux::DataStore::Factory.build(coin_join_uri)
    )
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
    Helper.data_store.clear
    Helper.class_variable_set(:@@bitcoin_info_index, 0) # start over reading bitcoin infos for each spec
  end
end
