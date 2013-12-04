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
  module StateMachine
  end
end

require 'lib/coin2coin/digest'
require 'lib/coin2coin/cipher'
require 'lib/coin2coin/pki'
require 'lib/coin2coin/bitcoin'
require 'lib/coin2coin/freenet'
require 'lib/coin2coin/freenet_event'
require 'lib/coin2coin/config'

require 'lib/coin2coin/message/base'
require 'lib/coin2coin/message/association'
require 'lib/coin2coin/message/coin_join'
require 'lib/coin2coin/message/controller'
require 'lib/coin2coin/message/control_status'
require 'lib/coin2coin/message/input'

require 'lib/coin2coin/state_machine/controller'
require 'lib/coin2coin/state_machine/event'

require 'app/models/coin2coin/base'
require 'app/models/coin2coin/transaction'
require 'app/models/coin2coin/input'
require 'app/models/coin2coin/output'
require 'app/models/coin2coin/coin_join'

require 'app/views/coin2coin/application'
