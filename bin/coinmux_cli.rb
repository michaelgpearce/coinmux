raise "COINMUX_ENV not set" if ENV['COINMUX_ENV'].nil?
Bundler.require(:default, ENV['COINMUX_ENV'], :cli)

require File.expand_path("../../lib/coinmux", __FILE__)

require 'slop'

module Cli
end

opts = Slop.parse(help: true) do
  banner <<-TEXT
#{Coinmux::BANNER}

Usage: coinmux [options]
TEXT
  on :v, :version, 'Display the version'
  on :h, :help, 'Display this help message'
  on :l, :"list", 'List CoinJoins waiting for inputs'
  on :a, :amount=, 'CoinJoin transaction amount (in BTC); must be a power of 2'
  on :p, :participants=, 'Number of participants'
  on :o, :"output-address=", 'Output address (in BTC)'
  on :c, :"change-address=", 'Change address (in BTC); optional'
  on :k, :"private-key=", 'Input private key in hex format *NOT SECURE*'
  on :d, :"data-store=", 'Data store to use: (p2p <default> | filesystem)'
  on :b, :bootstrap, 'Run as P2P bootstrap server'
end

if opts.version?
  puts Coinmux::VERSION
elsif opts.bootstrap?
  require 'cli/bootstrap'

  Cli::Bootstrap.instance.startup
else
  require 'cli/event'
  require 'cli/event_queue'
  require 'cli/application'

  app = Cli::Application.new(
    amount: opts[:amount],
    participants: opts[:participants],
    input_private_key: opts[:"private-key"],
    output_address: opts[:"output-address"],
    change_address: opts[:"change-address"],
    data_store: opts[:"data-store"],
    list: opts[:list]
  )
  if opts[:list]
    app.list_coin_joins
  else
    app.start
  end
end
