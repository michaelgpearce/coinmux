require 'digest/sha2'
require 'singleton'

class Coin2Coin::Digest
  include Singleton
  
  class << self
    def digest(message)
      Digest::SHA2.new(256).digest(message)
    end
    
    def message_digest(message_identifier, *params)
      message = ([message_identifier] + params).join(':')
      digest(message)
    end
  end
end