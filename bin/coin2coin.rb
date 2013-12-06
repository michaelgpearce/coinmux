#!/usr/bin/env bundle exec ruby -J-XstartOnFirstThread -Xdock:name=Coin2Coin

require File.expand_path("../../lib/coin2coin", __FILE__)

Swt::Widgets::Display.set_app_name "Coin2Coin"

Coin2Coin::Application.instance.start
