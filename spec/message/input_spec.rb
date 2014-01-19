require 'spec_helper'

describe Coinmux::Message::Input do
  before do
    fake_all_network_connections
  end

  let(:template_message) { build(:input_message) }
  let(:input_identifier) { template_message.input_identifier }
  let(:address) { template_message.address }
  let(:private_key) { template_message.private_key }
  let(:signature) { template_message.signature }
  let(:change_address) { template_message.change_address }
  let(:change_transaction_output_identifier) { template_message.change_transaction_output_identifier }
  let(:coin_join) { template_message.coin_join }
  
  describe "validations" do
    let(:message) do
      build(:input_message,
        address: address,
        private_key: private_key,
        signature: signature,
        change_address: change_address,
        change_transaction_output_identifier: change_transaction_output_identifier,
        coin_join: coin_join)
    end

    subject { message.valid? }

    it "is valid with default data" do
      subject
      expect(subject).to be_true
    end

    describe "#signature_correct" do
      context "with invalid signature" do
        let(:signature) { Base64.encode64('invalid').strip }

        it "is invalid" do
          expect(subject).to be_false
          expect(message.errors[:signature]).to include("is not correct for address #{address}")
        end
      end
    end

    describe "#change_address_valid" do
      context "with invalid change address" do
        let(:change_address) { "invalid_address" }

        it "is invalid" do
          expect(subject).to be_false
          expect(message.errors[:change_address]).to include("is not a valid address")
        end
      end
    end
  end

  describe "#build" do
    subject { Coinmux::Message::Input.build(coin_join, private_key, change_address) }

    it "builds valid input" do
      expect(subject.valid?).to be_true
    end

    it "has private_key" do
      expect(subject.private_key).to eq(private_key)
    end

    it "has message_private_key and message_public_key for encrypting and decrypting" do
      message = "a random message #{rand}"
      encrypted_message = pki_facade.private_encrypt(subject.message_private_key, message)
      expect(pki_facade.public_decrypt(subject.message_public_key, encrypted_message)).to eq(message)
    end

    it "has change address" do
      expect(subject.change_address).to eq(change_address)
    end

    it "has random identifier for change_transaction_output_identifier" do
      expect(subject.change_transaction_output_identifier).to_not be_nil
    end
  end

  describe "#from_json" do
    let(:message) { template_message }
    let(:json) do
      {
        message_public_key: message.message_public_key,
        address: message.address,
        change_address: message.change_address,
        change_transaction_output_identifier: message.change_transaction_output_identifier,
        signature: message.signature
      }.to_json
    end

    subject do
      Coinmux::Message::Input.from_json(json, coin_join)
    end

    it "creates a valid input" do
      expect(subject).to_not be_nil
      expect(subject.valid?).to be_true
      expect(subject.message_public_key).to eq(message.message_public_key)
      expect(subject.address).to eq(message.address)
      expect(subject.change_address).to eq(message.change_address)
    end
  end
  
end
