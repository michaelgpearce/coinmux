raise "COINMUX_ENV not set" if ENV['COINMUX_ENV'].nil?
Bundler.require(:default, ENV['COINMUX_ENV'], :gui)

require 'swt'
require 'glimmer'

module Gui
  module Model; end
  module View; end
end

require 'gui/model/base'
require 'gui/model/transaction'
require 'gui/model/input'
require 'gui/model/output'
require 'gui/model/coin_join'

require 'gui/view/application'
