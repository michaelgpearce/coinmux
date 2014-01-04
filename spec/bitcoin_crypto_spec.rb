require 'spec_helper'

describe Coin2Coin::BitcoinCrypto do
  let(:message) { "this is a message" }
  let(:address) { "mh9nRF1ZSqLJB3hbUjPLmfDHdnGUURdYdK" }
  let(:private_key_hex) { "585C660C887913E5F40B8E34D99C62766443F9D043B1DE1DFDCC94E386BC6DF6" }
  let(:public_key_hex) { "04FD30E98AF97627082F169B524E4646D31F900C9CAB13743140567C0CAE4B3F303AE48426DD157AEA58DCC239BB8FB19193FB856C312592D8296B02C0EA54E03C" }
  let(:signature_base_64) { "HIZQbBLAGJLhSZ310FCQMAo9l1X2ysxyt0kXkf6KcBN3znl2iClC6V9wz9Nkn6mMDUaq4kRlgYQDUUlsm29Bl0o=" }

  describe "verify_message!" do
    subject { Coin2Coin::BitcoinCrypto.instance.verify_message!(message, signature_base_64, address) }

    it "returns true" do
      expect(subject).to be_true
    end
  end

  describe "sign_message!" do
    subject { Coin2Coin::BitcoinCrypto.instance.sign_message!(message, private_key_hex) }

    it "verifies" do
      expect(Coin2Coin::BitcoinCrypto.instance.verify_message!(message, subject, address)).to be_true
    end
  end

  describe "address_for_public_key!" do
    subject { Coin2Coin::BitcoinCrypto.instance.address_for_public_key!(public_key_hex) }

    it "returns the bitcoin address" do
      expect(subject).to eq(address)
    end
  end

  describe "public_key_for_private_key!" do
    subject { Coin2Coin::BitcoinCrypto.instance.public_key_for_private_key!(private_key_hex) }

    it "returns the public key" do
      expect(subject).to eq(public_key_hex)
    end
  end

  describe "verify_address!" do
    subject { Coin2Coin::BitcoinCrypto.instance.verify_address!(address) }

    it "returns true" do
      expect(subject).to be_true
    end
  end
end