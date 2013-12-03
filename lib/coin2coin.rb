$:.unshift(File.expand_path("../..", __FILE__))

require 'swt'
require 'active_model'
require 'json'
require 'state_machine'
require 'hashie'
require 'freenet_hash'

module Coin2Coin
  module Message
  end
end

require 'lib/coin2coin/digest'
require 'lib/coin2coin/cipher'
require 'lib/coin2coin/pki'
require 'lib/coin2coin/bitcoin'
require 'lib/coin2coin/state_machine'
require 'lib/coin2coin/message/base'
require 'lib/coin2coin/message/freenet_association'
require 'lib/coin2coin/message/controller'
require 'lib/coin2coin/message/control_status'
require 'lib/coin2coin/message/input'

require 'app/models/coin2coin/base'
require 'app/models/coin2coin/transaction'
require 'app/models/coin2coin/input'
require 'app/models/coin2coin/output'
require 'app/models/coin2coin/coin_join'

require 'app/views/coin2coin/application'
