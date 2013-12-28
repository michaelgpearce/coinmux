require 'spec_helper'

describe Coin2Coin::Message::CoinJoin do
  before do
    fake_bitcoin
  end

  let(:amount) { Coin2Coin::Message::CoinJoin::SATOSHIS_PER_BITCOIN }
  let(:minimum_participants) { 2 }
  let(:version) { Coin2Coin::Message::CoinJoin::VERSION }
  
  describe "validations" do
    let(:message) do
      Coin2Coin::Message::CoinJoin.build(amount, minimum_participants).tap do |message|
        message.amount = amount
        message.minimum_participants = minimum_participants
        message.version = version
      end
    end

    subject { message.valid? }

    it "is valid with default data" do
      subject
      expect(subject).to be_true
    end

    describe "minimum_participants_numericality" do
      context "with non numeric value" do
        let(:minimum_participants) { "non-numeric" }

        it "is invalid" do
          expect(subject).to be_false
          expect(message.errors[:minimum_participants]).to include("is not an integer")
        end
      end

      context "with less than 2" do
        let(:minimum_participants) { 1 }

        it "is invalid" do
          expect(subject).to be_false
          expect(message.errors[:minimum_participants]).to include("must be at least 2")
        end
      end
    end

    describe "version_matches" do
      context "with version other than VERSION" do
        let(:version) { Coin2Coin::Message::CoinJoin::VERSION - 1 }

        it "is invalid" do
          expect(subject).to be_false
          expect(message.errors[:version]).to include("must be #{Coin2Coin::Message::CoinJoin::VERSION}")
        end
      end
    end

    describe "amount_is_base_2_bitcoin" do
      context "with base 2 bitcoin amount less than 1" do
        let(:amount) { Coin2Coin::Message::CoinJoin::SATOSHIS_PER_BITCOIN / 2 }

        it "is valid" do
          expect(subject).to be_true
        end
      end

      context "with base 2 bitcoin amount greater than 1" do
        let(:amount) { Coin2Coin::Message::CoinJoin::SATOSHIS_PER_BITCOIN * 2 }

        it "is valid" do
          expect(subject).to be_true
        end
      end

      context "with bitcoin amount is not base 2" do
        context "and not divisible by SATOSHIS_PER_BITCOIN" do
          let(:amount) { Coin2Coin::Message::CoinJoin::SATOSHIS_PER_BITCOIN - 1 }

          it "is invalid" do
            expect(subject).to be_false
            expect(message.errors[:amount]).to include("is not a valid amount")
          end
        end

        context "and divisible by SATOSHIS_PER_BITCOIN" do
          let(:amount) { Coin2Coin::Message::CoinJoin::SATOSHIS_PER_BITCOIN * 3 }

          it "is invalid" do
            expect(subject).to be_false
            expect(message.errors[:amount]).to include("is not a valid amount")
          end
        end
      end
    end
  end

  describe "associations" do
    let(:message) { Coin2Coin::Message::CoinJoin.build }

    context "inputs" do
      it "is a read-write list association" do
        expect(message.inputs).to eq([])
        expect(message.input_list.read_only_insert_key).to be_nil
        expect(message.input_list.insert_key).to_not be_nil
        expect(message.input_list.request_key).to_not be_nil
      end
    end

    context "outputs" do
      it "is a read-write list association" do
        expect(message.outputs).to eq([])
        expect(message.output_list.read_only_insert_key).to be_nil
        expect(message.output_list.insert_key).to_not be_nil
        expect(message.output_list.request_key).to_not be_nil
      end
    end

    context "outputs" do
      it "is a read-write list association" do
        expect(message.outputs).to eq([])
        expect(message.output_list.read_only_insert_key).to be_nil
        expect(message.output_list.insert_key).to_not be_nil
        expect(message.output_list.request_key).to_not be_nil
      end
    end

    context "message_verification" do
      it "is a read-only fixed association" do
        expect(message.message_verification).to eq(nil)
        expect(message.message_verification_fixed.read_only_insert_key).to_not be_nil
        expect(message.message_verification_fixed.insert_key).to be_nil
        expect(message.message_verification_fixed.request_key).to_not be_nil
      end
    end

    context "transaction" do
      it "is a read-only fixed association" do
        expect(message.transaction).to eq(nil)
        expect(message.transaction_fixed.read_only_insert_key).to_not be_nil
        expect(message.transaction_fixed.insert_key).to be_nil
        expect(message.transaction_fixed.request_key).to_not be_nil
      end
    end

    context "status" do
      it "is a read-only variable association" do
        expect(message.status).to eq(nil)
        expect(message.status_variable.read_only_insert_key).to_not be_nil
        expect(message.status_variable.insert_key).to be_nil
        expect(message.status_variable.request_key).to_not be_nil
      end
    end
  end

  describe "build" do
    subject { Coin2Coin::Message::CoinJoin.build(amount, minimum_participants) }

    it "builds valid input" do
      input = subject
      expect(input.valid?).to be_true
    end
  end

  describe "from_json" do
    let(:message) { Coin2Coin::Message::CoinJoin.build(amount, minimum_participants) }
    let(:json) do
      {
        version: message.version,
        identifier: message.identifier,
        message_public_key: message.message_public_key,
        amount: message.amount,
        minimum_participants: message.minimum_participants,
        input_list: { insert_key: message.input_list.insert_key, request_key: message.input_list.request_key },
        message_verification_fixed: { request_key: message.message_verification_fixed.request_key },
        output_list: { insert_key: message.output_list.insert_key, request_key: message.output_list.request_key },
        transaction_fixed: { request_key: message.transaction_fixed.request_key },
        status_variable: { request_key: message.status_variable.request_key }
      }.to_json
    end

    subject do
      Coin2Coin::Message::CoinJoin.from_json(json)
    end

    it "creates a valid input" do
      expect(subject).to_not be_nil
      expect(subject.valid?).to be_true
      expect(subject.version).to eq(message.version)
      expect(subject.identifier).to eq(message.identifier)
      expect(subject.message_public_key).to eq(message.message_public_key)
      expect(subject.amount).to eq(message.amount)
      expect(subject.minimum_participants).to eq(message.minimum_participants)
      expect(subject.input_list.insert_key).to eq(message.input_list.insert_key)
      expect(subject.input_list.request_key).to eq(message.input_list.request_key)
      expect(subject.inputs).to eq([])
      expect(subject.message_verification_fixed.insert_key).to be_nil
      expect(subject.message_verification_fixed.request_key).to eq(message.message_verification_fixed.request_key)
      expect(subject.message_verification).to be_nil
      expect(subject.output_list.insert_key).to eq(message.output_list.insert_key)
      expect(subject.output_list.request_key).to eq(message.output_list.request_key)
      expect(subject.outputs).to eq([])
      expect(subject.transaction_fixed.insert_key).to be_nil
      expect(subject.transaction_fixed.request_key).to eq(message.transaction_fixed.request_key)
      expect(subject.transaction).to be_nil
      expect(subject.status_variable.insert_key).to be_nil
      expect(subject.status_variable.request_key).to eq(message.status_variable.request_key)
      expect(subject.status).to be_nil
    end
  end
  
end
