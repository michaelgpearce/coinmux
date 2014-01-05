class Coin2Coin::Message::Output < Coin2Coin::Message::Base
  add_properties :address, :message_verification
  
  validates :address, :message_verification, :presence => true
  validate :message_verification_correct, :if => :message_verification
  validate :address_valid, :if => :address
 
  class << self
    def build(coin_join, address)
      message = super(coin_join)

      message.address = address
      message.message_verification = message.build_message_verification

      message
    end
  end

  def build_message_verification
    coin_join.build_message_verification(:output, address)
  end
  
  private

  def message_verification_correct
    return unless director? # only the director can validation these messages; participants wait for transaction message

    unless coin_join.message_verification_valid?(message_verification, :output, address)
      errors[:message_verification] << "cannot be verified"
    end
  end

  def address_valid
    unless Coin2Coin::BitcoinCrypto.instance.verify_address(address)
      errors[:address] << "is not a valid address"
    end
  end

end
