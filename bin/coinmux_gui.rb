raise "COINMUX_ENV not set" if ENV['COINMUX_ENV'].nil?
Bundler.require(:default, ENV['COINMUX_ENV'], :gui) unless ENV['COINMUX_JAR'] == 'true'

require File.expand_path("../../lib/coinmux", __FILE__)

if Coinmux.os == :macosx
  # Need to set app name before loading any AWT/Swing components
  {
    "com.apple.mrj.application.apple.menu.about.name" => "Coinmux",
    "apple.laf.useScreenMenuBar" => "true",
  }.each do |key, value|
    Java::JavaLang::System.setProperty(key, value)
  end
  image = Java::JavaAwt.Toolkit.getDefaultToolkit().getImage(File.join(Coinmux.root, "gui", "assets", "icon.png"))
  Java::ComAppleEawt::Application.getApplication().setDockIconImage(image)
end

module Gui
  module Model; end
  module View; end
end

require 'gui/model/base'
require 'gui/model/transaction'
require 'gui/model/input'
require 'gui/model/output'
require 'gui/model/coin_join'

require 'gui/view/base'
require 'gui/view/available_mixes'
require 'gui/view/mix_settings'
require 'gui/view/mixing'
require 'gui/view/application'

# Coinmux::Application.instance = Gui::View::Application.instance
Gui::View::Application.new.start
