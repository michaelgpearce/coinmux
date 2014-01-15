require File.expand_path("../../lib/coinmux", __FILE__)
require File.expand_path("../../gui/coinmux", __FILE__)

Swt::Widgets::Display.set_app_name "Coinmux"

Coinmux::Application.instance = Gui::View::Application.instance
Coinmux::Application.instance.start
