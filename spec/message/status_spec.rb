require 'spec_helper'

describe Coinmux::Message::Status do
  before do
    fake_all_network_connections
  end

  let(:template_message) { build(:status_message) }
  let(:state) { template_message.state }
  let(:transaction_id) { template_message.transaction_id }
  let(:coin_join) { template_message.coin_join }

  describe "validations" do
    let(:message) { build(:status_message, state: state, transaction_id: transaction_id) }

    subject { message.valid? }

    it "is valid with default data" do
      expect(subject).to be_true
    end

    describe "#transaction_id" do
      context "when present" do
        context "with completed state" do
          let(:state) { 'completed' }

          it "is valid" do
            expect(subject).to be_true
          end
        end

        (Coinmux::StateMachine::Director::STATES - ['completed']).each do |test_state|
          context "with #{test_state} state" do
            let(:state) { test_state }

            it "is invalid" do
              expect(subject).to be_false
              expect(message.errors[:transaction_id]).to include("must not be present for state #{test_state}")
            end
          end
        end
      end

      context "when nil" do
        let(:transaction_id) { nil }

        context "with completed state" do
          let(:state) { 'completed' }

          it "is invalid" do
            expect(subject).to be_false
            expect(message.errors[:transaction_id]).to include("must be present for state completed")
          end
        end

        (Coinmux::StateMachine::Director::STATES - ['completed']).each do |test_state|
          context "with #{test_state} state" do
            let(:state) { test_state }

            it "is valid" do
              expect(subject).to be_true
            end
          end
        end
      end
    end

    describe "#state_valid" do
      context "when state is invalid" do
        let(:state) { 'InvalidState' }

        it "is invalid" do
          expect(subject).to be_false
          expect(message.errors[:state]).to include("is not a valid state")
        end
      end
    end
  end

  describe "#build" do
    subject { Coinmux::Message::Status.build(coin_join, state: state, transaction_id: transaction_id) }

    it "builds valid status" do
      expect(subject.valid?).to be_true
    end
  end

  describe "#from_json" do
    let(:message) { template_message }
    let(:json) do
      {
        state: message.state,
        transaction_id: message.transaction_id,
      }.to_json
    end

    subject do
      Coinmux::Message::Status.from_json(json, data_store, coin_join)
    end

    it "creates a valid status" do
      expect(subject).to_not be_nil
      expect(subject.valid?).to be_true
      expect(subject.state).to eq(message.state)
      expect(subject.transaction_id).to eq(message.transaction_id)
    end
  end
  
end
