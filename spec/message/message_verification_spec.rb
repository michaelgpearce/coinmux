require 'spec_helper'

describe Coin2Coin::Message::MessageVerification do
  before do
    fake_all_network_connections
  end

  let(:coin_join) { build(:coin_join_message, :with_inputs) }
  let(:template_message) { Coin2Coin::Message::MessageVerification.build(coin_join) }
  let(:encrypted_message_identifier) { template_message.encrypted_message_identifier }
  let(:encrypted_secret_keys) { template_message.encrypted_secret_keys }
  let(:message) do
    Coin2Coin::Message::MessageVerification.new(
      coin_join: coin_join,
      encrypted_message_identifier: encrypted_message_identifier,
      encrypted_secret_keys: encrypted_secret_keys)
  end

  describe "validations" do
    subject { message.valid? }

    it "is valid with default data" do
      subject
      expect(subject).to be_true
    end

    context "ensure_owned_input_can_decrypt_message_identifier" do
      context "with no invalid encrypted secret key" do
        before do
          message.encrypted_secret_keys.keys.each do |address|
            message.encrypted_secret_keys[address] = "invalid encoding"
          end
        end

        it "is invalid" do
          subject
          expect(message.errors[:encrypted_secret_keys]).to include("cannot be decrypted")
        end
      end
    end

    context "ensure_has_addresses_for_all_encrypted_secret_keys" do
      context "with unknown encrypted_secret_keys address" do
        before do
          message.encrypted_secret_keys[:unknown_address] = "should be here"
        end

        it "is invalid" do
          subject
          expect(message.errors[:encrypted_secret_keys]).to include("contains address not an input")
        end
      end
    end
  end

  describe "get_secret_key_for_address!" do
    let(:message) { template_message }
    let(:input) { coin_join.inputs.value.first }
    let(:address) { input.address }
    subject { message.get_secret_key_for_address!(address) }

    context "with valid data" do
      it "returns the secret key for the address" do
        expect(subject).to eq(message.secret_key)
      end
    end

    context "with no matching address" do
      before do
        message.encrypted_secret_keys = {}
      end

      it "raises ArgumentError" do
        expect { subject }.to raise_error(ArgumentError, "not found for address #{address}")
      end
    end

    context "with encrypted_secret_keys incorrectly encoded" do
      before do
        message.encrypted_secret_keys[address.to_sym] = "not-base-64"
      end

      it "raises ArgumentError" do
        expect { subject }.to raise_error(ArgumentError, "cannot be decrypted")
      end
    end

    context "with encrypted_secret_keys with invalid key" do
      before do
        message.encrypted_secret_keys[address.to_sym] = Base64.encode64("incorrect key")
      end

      it "raises ArgumentError" do
        expect { subject }.to raise_error(ArgumentError, "cannot be decrypted")
      end
    end
  end

  describe "build" do
    subject { Coin2Coin::Message::MessageVerification.build(coin_join) }

    it "builds valid input" do
      input = subject
      expect(input.valid?).to be_true
    end
  end

  describe "from_json" do
    let(:message) { Coin2Coin::Message::MessageVerification.build(coin_join) }
    let(:json) do
      {
        encrypted_message_identifier: message.encrypted_message_identifier,
        encrypted_secret_keys: message.encrypted_secret_keys
      }.to_json
    end

    subject do
      Coin2Coin::Message::MessageVerification.from_json(json, coin_join)
    end

    it "creates a valid input" do
      expect(subject).to_not be_nil
      expect(subject.valid?).to be_true
      expect(subject.encrypted_message_identifier).to eq(message.encrypted_message_identifier)
      expect(subject.encrypted_secret_keys).to eq(message.encrypted_secret_keys)
    end
  end
  
end
