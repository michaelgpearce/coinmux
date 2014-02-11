$:.unshift(File.expand_path("../..", __FILE__))

require 'json'
require 'singleton'
require 'base64'
require 'set'

Dir[File.join(File.dirname(__FILE__), 'jar', '*.jar')].each { |filename| require filename }

module Coinmux
  require 'rbconfig'
  
  module Application; end
  module Message; end
  module StateMachine; end
  module DataStore; end

  def self.root
    @root ||= File.expand_path(File.join(File.dirname(__FILE__), '..'))
  end

  def self.env
    ENV['COINMUX_ENV'] || 'development'
  end

  def self.os
    @os ||= (
      host_os = RbConfig::CONFIG['host_os']
      case host_os
      when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
        :windows
      when /darwin|mac os/
        :macosx
      when /linux/
        :linux
      when /solaris|bsd/
        :unix
      else
        raise Error::WebDriverError, "unknown os: #{host_os.inspect}"
      end
    )
  end
end

require 'lib/coinmux/try'
require 'lib/coinmux/assert_keys'
require 'lib/coinmux/blank_and_present'
require 'lib/coinmux/inflections'
require 'lib/coinmux/validation_model'
require 'lib/coinmux/proper'
require 'lib/coinmux/file_util'
require 'lib/coinmux/version'
require 'lib/coinmux/facades'
require 'lib/coinmux/http'
require 'lib/coinmux/coin_join_uri'
require 'lib/coinmux/error'
require 'lib/coinmux/digest'
require 'lib/coinmux/cipher'
require 'lib/coinmux/pki'
require 'lib/coinmux/bitcoin_util'
require 'lib/coinmux/bitcoin_crypto'
require 'lib/coinmux/bitcoin_network'
require 'lib/coinmux/event'
require 'lib/coinmux/config'
require 'lib/coinmux/logger'

require 'lib/coinmux/data_store/base'
require 'lib/coinmux/data_store/tomp2p'
require 'lib/coinmux/data_store/memory'
require 'lib/coinmux/data_store/file'
require 'lib/coinmux/data_store/factory'

require 'lib/coinmux/message/base'
require 'lib/coinmux/message/association'
require 'lib/coinmux/message/coin_join'
require 'lib/coinmux/message/status'
require 'lib/coinmux/message/input'
require 'lib/coinmux/message/message_verification'
require 'lib/coinmux/message/output'
require 'lib/coinmux/message/transaction'
require 'lib/coinmux/message/transaction_signature'

require 'lib/coinmux/state_machine/event'
require 'lib/coinmux/state_machine/base'
require 'lib/coinmux/state_machine/director'
require 'lib/coinmux/state_machine/participant'

require 'lib/coinmux/application/available_coin_joins'
require 'lib/coinmux/application/input_validator'
