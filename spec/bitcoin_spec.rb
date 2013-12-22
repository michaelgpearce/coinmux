require 'spec_helper'

describe Coin2Coin::Bitcoin do
  let(:message) { "this is a message" }
  # Testnet
  let(:address) { "mh9nRF1ZSqLJB3hbUjPLmfDHdnGUURdYdK" }
  let(:private_key_hex) { "585C660C887913E5F40B8E34D99C62766443F9D043B1DE1DFDCC94E386BC6DF6" }
  let(:signature_base_64) { "HIZQbBLAGJLhSZ310FCQMAo9l1X2ysxyt0kXkf6KcBN3znl2iClC6V9wz9Nkn6mMDUaq4kRlgYQDUUlsm29Bl0o=" }

  describe "verify_message" do
    subject { Coin2Coin::Bitcoin.instance.verify_message(message, signature_base_64, address) }

    it "returns true" do
      expect(subject).to be_true
    end
  end

  describe "sign_message" do
    subject { Coin2Coin::Bitcoin.instance.sign_message(message, private_key_hex) }

    it "verifies" do
      expect(Coin2Coin::Bitcoin.instance.verify_message(message, subject, address)).to be_true
    end
  end
end