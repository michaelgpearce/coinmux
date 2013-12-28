$:.unshift(File.expand_path("../..", __FILE__))

require 'swt'
require 'active_model'
require 'json'
require 'state_machine'
require 'hashie'
require 'freenet_hash'


class Hash
  include Hashie::Extensions::KeyConversion

  def assert_required_keys!(*keys)
    raise "There are invalid keys #{self.keys}, expected #{keys}" if self.keys.sort != keys.sort
  end
end

module Coin2Coin
  module Message
  end
  module StateMachine
  end
end

require 'lib/coin2coin/coin_join_uri'
require 'lib/coin2coin/error'
require 'lib/coin2coin/digest'
require 'lib/coin2coin/cipher'
require 'lib/coin2coin/pki'
require 'lib/coin2coin/bitcoin'
require 'lib/coin2coin/data_store'
require 'lib/coin2coin/data_store_event'
require 'lib/coin2coin/config'

require 'lib/coin2coin/message/base'
require 'lib/coin2coin/message/association'
require 'lib/coin2coin/message/coin_join'
require 'lib/coin2coin/message/status'
require 'lib/coin2coin/message/input'

require 'lib/coin2coin/state_machine/event'
require 'lib/coin2coin/state_machine/controller'
require 'lib/coin2coin/state_machine/participant'

require 'app/models/coin2coin/base'
require 'app/models/coin2coin/transaction'
require 'app/models/coin2coin/input'
require 'app/models/coin2coin/output'
require 'app/models/coin2coin/coin_join'

require 'app/views/coin2coin/application'
