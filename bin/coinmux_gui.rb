raise "COINMUX_ENV not set" if ENV['COINMUX_ENV'].nil?
Bundler.require(:default, ENV['COINMUX_ENV'], :gui) unless ENV['COINMUX_JAR'] == 'true'

require File.expand_path("../../lib/coinmux", __FILE__)

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

Swt::Widgets::Display.set_app_name "Coinmux"

Coinmux::Application.instance = Gui::View::Application.instance
Coinmux::Application.instance.start
