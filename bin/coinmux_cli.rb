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
  on :b, :bootstrap, 'Run as P2P bootstrap server'
  on :a, :amount=, 'CoinJoin transaction amount (in BTC); must be a power of 2'
  on :p, :participants=, 'Number of participants'
  on :d, :debug, 'Debug mode'
end

if opts.version?
  puts Coinmux::VERSION
elsif opts.bootstrap?
  require 'cli/bootstrap'
  Cli::Bootstrap.instance.startup
else
  require 'cli/application'
  Coinmux::Application.instance = Cli::Application.instance
  Cli::Application.instance.start(opts[:amount], opts[:participants])
end
