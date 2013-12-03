require 'openssl'

class Coin2Coin::PKI
  class << self
    def generate_keypair
      pki = OpenSSL::PKey::RSA.new(2048)
      private_key = pki.to_s
      public_key = pki.public_key

      [private_key, public_key]
    end

    def encrypt(private_key, clear_message)
      OpenSSL::PKey::RSA.new(private_key).private_encrypt(clear_message, OpenSSL::PKey::RSA::PKCS1_PADDING)
    end

    def decrypt(public_key, encrypted_message)
      OpenSSL::PKey::RSA.new(public_key).public_decrypt(encrypted_message, OpenSSL::PKey::RSA::PKCS1_PADDING)
    end

  end
end