require 'digest/sha2'
require 'singleton'

class Coin2Coin::Digest
  include Singleton
  
  def digest(message)
    Digest::SHA2.new(256).digest(message)
  end
  
  def message_digest(message_identifier, *params)
    message = ([message_identifier] + params).join(':')
    digest(message)
  end
  
  def hex_digest(message)
    digest(message).unpack('H*').first
  end
  
  def random_identifier
    hex_digest(rand.to_s)
  end
end