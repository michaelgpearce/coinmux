class Coinmux::Message::TransactionSignature < Coinmux::Message::Base
  add_properties :transaction_input_index, :script_sig, :message_verification

  validates :transaction_input_index, :script_sig, :message_verification, :presence => true
  validate :message_verification_correct, :if => :director?
  validate :transaction_input_index_valid
  validate :script_sig_valid

  class << self
    def build(coin_join, transaction_input_index, private_key_hex)
      message = super(coin_join)

      message.transaction_input_index = transaction_input_index
      script_sig = Coinmux::BitcoinNetwork.instance.build_transaction_input_script_sig(coin_join.transaction_object, transaction_input_index, private_key_hex)
      message.script_sig = Base64.encode64(script_sig)
      message.message_verification = coin_join.build_message_verification(:transaction_signature, transaction_input_index, script_sig)

      message
    end
  end

  private

  def transaction_input_index_valid
    return unless errors[:transaction_input_index].empty?

    unless bitcoin_network_facade.transaction_input_unspent?(coin_join.transaction_object, transaction_input_index)
      errors[:transaction_input_index] << "has been spent"
    end
  end

  def script_sig_valid
    return unless errors[:script_sig].empty?

    unless bitcoin_network_facade.script_sig_valid?(coin_join.transaction_object, transaction_input_index, Base64.decode64(script_sig))
      errors[:script_sig] << "is not valid"
    end
  end

  def message_verification_correct
    return unless errors[:message_verification].empty?

    unless coin_join.message_verification_valid?(:transaction_signature, message_verification, transaction_input_index, Base64.decode64(script_sig))
      errors[:message_verification] << "cannot be verified"
    end
  end
end
