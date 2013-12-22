require 'spec_helper'
require 'base64'

describe Coin2Coin::Message::Input do
  let(:input_identifier) { "this is a message" }
  let(:address) { "mh9nRF1ZSqLJB3hbUjPLmfDHdnGUURdYdK" }
  let(:private_key_hex) { "585C660C887913E5F40B8E34D99C62766443F9D043B1DE1DFDCC94E386BC6DF6" }
  let(:public_key_hex) { "04FD30E98AF97627082F169B524E4646D31F900C9CAB13743140567C0CAE4B3F303AE48426DD157AEA58DCC239BB8FB19193FB856C312592D8296B02C0EA54E03C" }
  let(:signature_base_64) { "HIZQbBLAGJLhSZ310FCQMAo9l1X2ysxyt0kXkf6KcBN3znl2iClC6V9wz9Nkn6mMDUaq4kRlgYQDUUlsm29Bl0o=" }
  let(:change_address) { "mi4J2qXAVTwonMhaWGX63eKnjZcFM9Gy8Q" }
  let(:change_amount) { 100000 }
  let(:coin_join) do
    Coin2Coin::Message::CoinJoin.build.tap do |coin_join|
      coin_join.identifier = input_identifier
    end
  end
  
  describe "validations" do
    let(:input) do
      Coin2Coin::Message::Input.build(coin_join, private_key_hex, change_address, change_amount).tap do |input|
        input.address = address
        input.private_key = private_key_hex
        input.public_key = public_key_hex
        input.signature = signature_base_64
        input.change_address = change_address
      end
    end

    subject { input.valid? }

    it "is valid with default data" do
      expect(subject).to be_true
    end

    describe "address_matches_public_key" do
      context "with public key not matching address" do
        let(:public_key_hex) { "00FD30E98AF97627082F169B524E4646D31F900C9CAB13743140567C0CAE4B3F303AE48426DD157AEA58DCC239BB8FB19193FB856C312592D8296B02C0EA54E03C" }

        it "is invalid" do
          expect(subject).to be_false
          expect(input.errors[:public_key]).to eq(["is not correct for address #{address}"])
        end
      end
    end

    describe "signature_correct" do
      context "with invalid signature" do
        let(:signature_base_64) { Base64.encode64('invalid').strip }

        it "is invalid" do
          expect(subject).to be_false
          expect(input.errors[:signature]).to eq(["is not correct for address #{address}"])
        end
      end
    end

    describe "change_address_valid" do
      context "with invalid change address" do
        let(:change_address) { "invalid_address" }

        it "is invalid" do
          expect(subject).to be_false
          expect(input.errors[:change_address]).to eq(["is not a valid address"])
        end
      end
    end
  end

  describe "build" do
    subject { Coin2Coin::Message::Input.build(coin_join, private_key_hex) }

    it "builds valid input" do
      input = subject
      expect(input.valid?).to be_true
    end
  end
  
end
