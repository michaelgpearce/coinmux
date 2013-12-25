require 'spec_helper'

describe Coin2Coin::Message::Status do
  before do
    fake_bitcoin

    if !transaction_id.nil?
      Coin2Coin::Bitcoin.instance.test_add_transaction_id_to_pool(transaction_id)
      Coin2Coin::Bitcoin.instance.test_confirm_block
    end
  end

  let(:identifier) { "valid_identifier:#{rand}" }
  let(:status) { "Complete" }
  let(:transaction_id) { "valid_transaction_id:#{rand}" }
  let(:current_block_height) { Coin2Coin::Bitcoin.instance.current_block_height_and_nonce.first }
  let(:current_nonce) { Coin2Coin::Bitcoin.instance.current_block_height_and_nonce.last }
  let(:updated_at) { { :block_height => current_block_height, :nonce => current_nonce } }
  let(:coin_join) { Coin2Coin::Message::CoinJoin.build }
  
  describe "validations" do
    let(:message) do
      Coin2Coin::Message::Status.build(coin_join, status, transaction_id).tap do |message|
        message.identifier = identifier
        message.status = status
        message.transaction_id = transaction_id
        message.updated_at = updated_at
      end
    end

    subject { message.valid? }

    it "is valid with default data" do
      subject
      expect(subject).to be_true
    end

    describe "transaction_id" do
      context "when present" do
        Coin2Coin::Message::Status::STATUSES_REQUIRING_TRANSACTION_ID.each do |test_status|
          context "with #{test_status} status" do
            let(:status) { test_status }

            it "is valid" do
              subject
              expect(subject).to be_true
            end
          end
        end

        (Coin2Coin::StateMachine::Controller::STATUSES - Coin2Coin::Message::Status::STATUSES_REQUIRING_TRANSACTION_ID).each do |test_status|
          context "with #{test_status} status" do
            let(:status) { test_status }

            it "is invalid" do
              subject
              expect(subject).to be_false
              expect(message.errors[:transaction_id]).to include("must not be present for status #{test_status}")
            end
          end
        end
      end

      context "when nil" do
        let(:transaction_id) { nil }

        Coin2Coin::Message::Status::STATUSES_REQUIRING_TRANSACTION_ID.each do |test_status|
          context "with #{test_status} status" do
            let(:status) { test_status }

            it "is invalid" do
              subject
              expect(subject).to be_false
              expect(message.errors[:transaction_id]).to include("must be present for status #{test_status}")
            end
          end
        end

        (Coin2Coin::StateMachine::Controller::STATUSES - Coin2Coin::Message::Status::STATUSES_REQUIRING_TRANSACTION_ID).each do |test_status|
          context "with #{test_status} status" do
            let(:status) { test_status }

            it "is valid" do
              subject
              expect(subject).to be_true
            end
          end
        end
      end
    end

    describe "transaction_confirmed" do
      context "when in Complete state" do
        let(:status) { 'Complete' }

        context "with confirmed transaction" do
          it "is valid" do
            subject
            expect(subject).to be_true
          end
        end

        context "with no confirmed transaction" do
          let(:transaction_id) { nil }

          it "is invalid" do
            subject
            expect(subject).to be_false
            expect(message.errors[:transaction_id]).to include("is not confirmed")
          end
        end
      end
    end

    describe "status_valid" do
      context "when status is invalid" do
        let(:status) { 'InvalidStatus' }

        it "is invalid" do
          subject
          expect(subject).to be_false
          expect(message.errors[:status]).to include("is not a valid status")
        end
      end
    end

    describe "updated_at" do
      context "with non-Hash" do
        let(:updated_at) { nil }

        it "is invalid" do
          subject
          expect(subject).to be_false
          expect(message.errors[:updated_at]).to include("must be a hash")
        end
      end

      context "with non-existant block height" do
        let(:updated_at) { { :block_height => current_block_height + 1, :nonce => current_nonce } }

        it "is invalid" do
          subject
          expect(subject).to be_false
          expect(message.errors[:updated_at]).to include("is not a valid block")
        end
      end

      context "with invalid nonce" do
        let(:updated_at) { { :block_height => current_block_height, :nonce => "wrong nonce" } }

        it "is invalid" do
          subject
          expect(subject).to be_false
          expect(message.errors[:updated_at]).to include("is not a valid block")
        end
      end
    end
  end

  describe "build" do
    subject { Coin2Coin::Message::Status.build(coin_join, status, transaction_id) }

    it "builds valid input" do
      input = subject
      expect(input.valid?).to be_true
    end
  end

  describe "from_json" do
    let(:message) { Coin2Coin::Message::Status.build(coin_join, status, transaction_id) }
    let(:json) do
      {
        identifier: message.identifier,
        status: message.status,
        transaction_id: message.transaction_id,
        updated_at: message.updated_at
      }.to_json
    end

    subject do
      Coin2Coin::Message::Status.from_json(json, :coin_join => coin_join)
    end

    it "creates a valid input" do
      expect(subject).to_not be_nil
      expect(subject.valid?).to be_true
      expect(subject.identifier).to eq(message.identifier)
      expect(subject.status).to eq(message.status)
      expect(subject.transaction_id).to eq(message.transaction_id)
      expect(subject.updated_at).to eq(message.updated_at)
    end
  end
  
end
