class Coinmux::Message::MessageVerification < Coinmux::Message::Base
  property :encrypted_message_identifier
  property :encrypted_secret_keys
  
  attr_accessor :message_identifier, :secret_key
  
  validates :encrypted_message_identifier, :encrypted_secret_keys, :presence => true
  validates :message_identifier, :secret_key, :presence => true, :if => :created_with_build?
  validates :message_identifier, :secret_key, :absence => true, :unless => :created_with_build?
  validate :ensure_has_addresses_for_all_encrypted_secret_keys, :unless => :created_with_build?
  validate :ensure_owned_input_can_decrypt_message_identifier, :unless => :created_with_build?

  class << self
    def build(coin_join)
      message = super(coin_join.data_store, coin_join)

      message.message_identifier = digest_facade.random_identifier
      message.secret_key = digest_facade.random_identifier
      
      message.encrypted_message_identifier = Base64.encode64(cipher_facade.encrypt(message.secret_key, message.message_identifier)).strip
      
      message.encrypted_secret_keys = message.build_encrypted_secret_keys

      message
    end
  end

  def build_encrypted_secret_keys
    # only selected inputs will get the secret to decrypt the identifier
    coin_join.inputs.value.inject({}) do |acc, input|
      encrypted_secret_key = pki_facade.public_encrypt(input.message_public_key, secret_key)
      acc[input.address] = Base64.encode64(encrypted_secret_key)

      acc
    end
  end

  # raise ArgumentError if unable to decrypt
  def get_secret_key_for_address!(address)
    input = coin_join.inputs.value.detect { |input| input.address.to_s == address.to_s }
    raise "Invalid state: no input!" if input.nil?

    encoded_encrypted_secret_key = encrypted_secret_keys[address]
    raise ArgumentError, "not found for address #{address}" if encoded_encrypted_secret_key.nil?

    encrypted_secret_key = (Base64.decode64(encoded_encrypted_secret_key) rescue nil) || ""
    secret_key = pki_facade.private_decrypt(input.message_private_key, encrypted_secret_key) rescue nil
    raise ArgumentError, "cannot be decrypted" if secret_key.nil?

    secret_key
  end

  private

  def ensure_owned_input_can_decrypt_message_identifier
    input = coin_join.inputs.value.detect(&:message_private_key)
    raise "Invalid state: no input!" if input.nil?

    get_secret_key_for_address!(input.address)
  rescue ArgumentError => e
    errors[:encrypted_secret_keys] << e.message
  end

  def ensure_has_addresses_for_all_encrypted_secret_keys
    (errors[:encrypted_secret_keys] << "is not a Hash" and return) unless encrypted_secret_keys.is_a?(Hash)

    errors[:encrypted_secret_keys] << "contains address not an input" if (encrypted_secret_keys.keys.collect(&:to_s) - coin_join.inputs.value.collect(&:address)).size != 0
  end
end
