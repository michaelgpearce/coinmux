class Coinmux::Digest
  include Singleton
  
  def digest(message)
    Digest::SHA2.new(256).digest(message)
  end
  
  def hex_message_digest(*params)
    message = params.join(':')
    hex_digest(message)
  end
  
  def hex_digest(message)
    digest(message).unpack('H*').first
  end
  
  def random_identifier
    hex_digest(rand.to_s)
  end
end