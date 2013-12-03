require 'openssl'

class Coin2Coin::Cipher
  class << self
    def encrypt(secret_key, clear_text)
      cipher = build_cipher(:encrypt)
      cipher.key = Coin2Coin::Digest.digest(secret_key)
      cipher.iv = iv = cipher.random_iv # 16 bytes
      
      encrypted = cipher.update(clear_text)
      encrypted << cipher.final
      "#{iv}#{encrypted}"
    end

    def decrypt(secret_key, encrypted_text)
      cipher = build_cipher(:decrypt)
      cipher.key = Coin2Coin::Digest.digest(secret_key)
      cipher.iv = encrypted_text[0...16] # first 16 bytes are IV
      encrypted_text = encrypted_text[16..-1]

      # and decrypt it
      decrypted = cipher.update(encrypted_text)
      decrypted << cipher.final
      decrypted.to_s
    end

    private
    
    def build_cipher(type)
      OpenSSL::Cipher::Cipher.new("aes-256-cbc").tap do |cipher|
        cipher.send(type)
      end
    end
  end
end