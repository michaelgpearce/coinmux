raise "COINMUX_ENV not set" if ENV['COINMUX_ENV'].nil?

require File.expand_path("../../lib/coinmux", __FILE__)

module Cli
end

require 'optparse'
require 'ostruct'

options = OpenStruct.new
OptionParser.new do |o|
  o.banner = "#{Coinmux::BANNER}\n\nUsage: coinmux [options]\n"
  o.separator ""

  o.on('-v', '--version', 'Display the version') { |v| options.version = v }
  o.on('-h', '--help', 'Display this help message') { |v| options.help = v }
  o.on('-l', '--list', 'List CoinJoins waiting for inputs') { |v| options.list = v }
  o.on('-a', '--amount AMOUNT', 'CoinJoin transaction amount (in BTC)') { |v| options.amount = v }
  o.on('-p', '--participants PARTICIPANTS', 'Number of participants') { |v| options.participants = v }
  o.on('-o', '--output-address OUTPUTADDRESS', 'Output address (in BTC)') { |v| options.output_address = v }
  o.on('-c', '--change-address [CHANGEADDRESS]', 'Change address (in BTC)') { |v| options.change_address = v }
  o.on('-k', '--private-key [PRIVATEKEY]', 'Input private key in hex or wallet import format *NOT SECURE*') { |v| options.private_key = v }
  o.on('-d', '--data-store DATASTORE', 'Data store to use: p2p <default> or filesystem') { |v| options.data_store = v }
  o.on('-b', '--bootstrap [PORT]', 'Run as P2P bootstrap server') { |v| options.bootstrap = v }
end.parse!

if options.version
  puts Coinmux::VERSION
elsif options.bootstrap
  require 'cli/bootstrap'

  Cli::Bootstrap.new(port: options.bootstrap).startup
else
  require 'cli/event'
  require 'cli/event_queue'
  require 'cli/application'

  app = Cli::Application.new(
    amount: options.amount,
    participants: options.participants,
    input_private_key: options.private_key,
    output_address: options.output_address,
    change_address: options.change_address,
    data_store: options.data_store,
    list: options.list
  )
  if options.list
    app.list_coin_joins
  else
    app.start
  end
end
