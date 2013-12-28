require 'openssl'

class Coin2Coin::PKI
  include Singleton
  
  def generate_keypair
    pki = OpenSSL::PKey::RSA.new(2048)
    private_key = pki.to_s
    public_key = pki.public_key.to_s

    [private_key, public_key]
  end

  def public_encrypt(public_key, clear_text)
    OpenSSL::PKey::RSA.new(public_key).public_encrypt(clear_text, OpenSSL::PKey::RSA::PKCS1_PADDING)
  end

  def private_encrypt(private_key, clear_text)
    OpenSSL::PKey::RSA.new(private_key).private_encrypt(clear_text, OpenSSL::PKey::RSA::PKCS1_PADDING)
  end

  def public_decrypt(public_key, encrypted_text)
    OpenSSL::PKey::RSA.new(public_key).public_decrypt(encrypted_text, OpenSSL::PKey::RSA::PKCS1_PADDING)
  end

  def private_decrypt(private_key, encrypted_text)
    OpenSSL::PKey::RSA.new(private_key).private_decrypt(encrypted_text, OpenSSL::PKey::RSA::PKCS1_PADDING)
  end
end