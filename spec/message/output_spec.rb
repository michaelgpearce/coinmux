require 'spec_helper'

describe Coinmux::Message::Output do
  before do
    fake_all_network_connections
  end

  let(:coin_join) { build(:coin_join_message, :with_inputs, :with_message_verification, :with_outputs) }
  let(:message) { coin_join.outputs.value.detect(&:created_with_build?) }
  
  describe "validations" do
    subject { message.valid? }

    it "is valid with default data" do
      subject
      expect(subject).to be_true
    end


    describe "#message_verification_correct" do
      before do
        expect(coin_join.director?).to be_true
      end

      context "with invalid value" do
        before do
          message.message_verification = coin_join.build_message_verification(:output, 'not correct')
        end

        it "is invalid" do
          expect(subject).to be_false
          expect(message.errors[:message_verification]).to include("cannot be verified")
        end
      end
    end

    describe "#address_valid" do
      context "with invalid address" do
        before do
          message.address = "invalid_address"
        end

        it "is invalid" do
          expect(subject).to be_false
          expect(message.errors[:address]).to include("is not a valid address")
        end
      end
    end
  end

  describe "#build" do
    let(:address) { message.address }

    subject { Coinmux::Message::Output.build(coin_join, address: address) }

    it "builds valid output" do
      expect(subject.valid?).to be_true
    end

    it "has address" do
      expect(subject.address).to eq(address)
    end

    it "has random identifier for transaction_output_identifier" do
      expect(subject.transaction_output_identifier).to_not be_nil
    end

    it "has message verification" do
      expect(subject.message_verification).to eq(coin_join.build_message_verification(:output, address))
    end
  end

  describe "#from_json" do
    let(:json) do
      {
        address: message.address,
        transaction_output_identifier: message.transaction_output_identifier,
        message_verification: message.message_verification,
      }.to_json
    end

    subject do
      Coinmux::Message::Output.from_json(json, data_store, coin_join)
    end

    it "creates a valid output" do
      expect(subject).to_not be_nil
      expect(subject.valid?).to be_true
      expect(subject.address).to eq(message.address)
      expect(subject.transaction_output_identifier).to eq(message.transaction_output_identifier)
      expect(subject.message_verification).to eq(message.message_verification)
    end
  end
  
end
