#!/usr/bin/env bundle exec ruby -J-XstartOnFirstThread -J-Xdock:name=Coinmux

require File.expand_path("../../lib/coinmux", __FILE__)

Swt::Widgets::Display.set_app_name "Coinmux"

Coinmux::Application.instance.start
