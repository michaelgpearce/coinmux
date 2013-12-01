$:.unshift(File.expand_path("../..", __FILE__))

require 'swt'
require 'active_model'

module Coin2Coin; end

require 'app/models/base'
require 'app/models/transaction'
require 'app/models/input'
require 'app/models/output'
require 'app/models/coin_join'
require 'app/views/application'
