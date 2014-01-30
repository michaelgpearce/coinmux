class Coinmux::Message::Output < Coinmux::Message::Base
  add_properties :address, :message_verification, :transaction_output_identifier
  
  validates :address, :message_verification, :transaction_output_identifier, :presence => true
  validate :message_verification_correct, :if => :message_verification
  validate :address_valid, :if => :address
 
  class << self
    def build(coin_join, options = {})
      options.assert_keys!(required: :address)

      message = super(coin_join.data_store, coin_join)

      message.address = options[:address]
      message.transaction_output_identifier = digest_facade.random_identifier
      message.message_verification = message.build_message_verification

      message
    end
  end

  def build_message_verification
    coin_join.build_message_verification(:output, address)
  end
  
  private

  def message_verification_correct
    return unless director? # only the director can validate these messages; participants wait for transaction message

    unless coin_join.message_verification_valid?(:output, message_verification, address)
      errors[:message_verification] << "cannot be verified"
    end
  end

  def address_valid
    unless bitcoin_crypto_facade.verify_address(address)
      errors[:address] << "is not a valid address"
    end
  end

end
