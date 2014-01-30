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
  on :a, :amount=, 'CoinJoin transaction amount (in BTC); must be a power of 2'
  on :b, :bootstrap, 'Run as P2P bootstrap server'
  on :c, :"change-address=", 'Change address (in BTC); optional'
  on :d, :debug, 'Debug mode'
  on :h, :help, 'Display this help message'
  on :k, :"private-key=", 'Input private key in hex format'
  on :o, :"output-address=", 'Output address (in BTC)'
  on :p, :participants=, 'Number of participants'
  on :u, :"coin-join-uri=", 'Connection CoinJoin URI'
  on :v, :version, 'Display the version'
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

  Cli::Application.new(
    amount: opts[:amount],
    participants: opts[:participants],
    input_private_key: opts[:"private-key"],
    output_address: opts[:"output-address"],
    change_address: opts[:"change-address"],
    coin_join_uri: opts[:"coin-join-uri"]
  ).start
end
