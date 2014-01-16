raise "COINMUX_ENV not set" if ENV['COINMUX_ENV'].nil?
Bundler.require(:default, ENV['COINMUX_ENV'], :cli)

require File.expand_path("../../lib/coinmux", __FILE__)

require 'slop'

module Cli
end

require 'cli/bootstrap'

opts = Slop.parse(help: true) do
  banner <<-TEXT
#{Coinmux::BANNER}

Usage: coinmux [options]
TEXT
  on :v, :version, 'Display the version'
  on :h, :help, 'Display this help message'
  on :b, :bootstrap, 'Run as P2P bootstrap server'
end

if opts.version?
  puts Coinmux::VERSION
elsif opts.bootstrap?
  Cli::Bootstrap.instance.startup
end
