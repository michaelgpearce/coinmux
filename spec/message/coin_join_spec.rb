require 'spec_helper'

describe Coinmux::Message::CoinJoin do
  before do
    fake_all_network_connections
  end

  let(:amount) { SATOSHIS_PER_BITCOIN }
  let(:participants) { 2 }
  let(:participant_transaction_fee) { DEFAULT_TRANSACTION_FEE / 2 }
  let(:version) { Coinmux::Message::CoinJoin::VERSION }
  
  describe "validations" do
    let(:message) { build(:coin_join_message, amount: amount, participants: participants, participant_transaction_fee: participant_transaction_fee, version: version) }

    subject { message.valid? }

    it "is valid with default data" do
      subject
      expect(subject).to be_true
    end

    describe "participants_numericality" do
      context "with non numeric value" do
        let(:participants) { "non-numeric" }

        it "is invalid" do
          expect(subject).to be_false
          expect(message.errors[:participants]).to include("is not an integer")
        end
      end

      context "with less than 2" do
        let(:participants) { 1 }

        it "is invalid" do
          expect(subject).to be_false
          expect(message.errors[:participants]).to include("must be at least 2")
        end
      end
    end

    describe "participant_transaction_fee_numericality" do
      context "with non numeric value" do
        let(:participant_transaction_fee) { "non-numeric" }

        it "is invalid" do
          expect(subject).to be_false
          expect(message.errors[:participant_transaction_fee]).to include("is not an integer")
        end
      end

      context "with less than 0" do
        let(:participant_transaction_fee) { -1 }

        it "is invalid" do
          expect(subject).to be_false
          expect(message.errors[:participant_transaction_fee]).to include("may not be a negative amount")
        end
      end

      context "with greater than DEFAULT_TRANSACTION_FEE" do
        let(:participant_transaction_fee) { DEFAULT_TRANSACTION_FEE + 1 }

        it "is invalid" do
          expect(subject).to be_false
          expect(message.errors[:participant_transaction_fee]).to include("may not be greater than #{DEFAULT_TRANSACTION_FEE}")
        end
      end
    end

    describe "version_matches" do
      context "with version other than VERSION" do
        let(:version) { Coinmux::Message::CoinJoin::VERSION - 1 }

        it "is invalid" do
          expect(subject).to be_false
          expect(message.errors[:version]).to include("must be #{Coinmux::Message::CoinJoin::VERSION}")
        end
      end
    end

    describe "amount_is_base_2_bitcoin" do
      context "with base 2 bitcoin amount less than 1" do
        let(:amount) { SATOSHIS_PER_BITCOIN / 2 }

        it "is valid" do
          expect(subject).to be_true
        end
      end

      context "with base 2 bitcoin amount greater than 1" do
        let(:amount) { SATOSHIS_PER_BITCOIN * 2 }

        it "is valid" do
          expect(subject).to be_true
        end
      end

      context "with bitcoin amount is not base 2" do
        context "and not divisible by SATOSHIS_PER_BITCOIN" do
          let(:amount) { SATOSHIS_PER_BITCOIN - 1 }

          it "is invalid" do
            expect(subject).to be_false
            expect(message.errors[:amount]).to include("is not a valid amount")
          end
        end

        context "and divisible by SATOSHIS_PER_BITCOIN" do
          let(:amount) { SATOSHIS_PER_BITCOIN * 3 }

          it "is invalid" do
            expect(subject).to be_false
            expect(message.errors[:amount]).to include("is not a valid amount")
          end
        end
      end
    end
  end

  describe "associations" do
    let(:message) { build(:coin_join_message) }

    context "inputs" do
      it "is a read-write list association" do
        expect(message.inputs.value).to eq([])
        expect(message.inputs.type).to eq(:list)
        expect(data_store_facade.identifier_can_insert?(message.inputs.data_store_identifier)).to be_true
        expect(data_store_facade.identifier_can_request?(message.inputs.data_store_identifier)).to be_true
      end
    end

    context "outputs" do
      it "is a read-write list association" do
        expect(message.outputs.value).to eq([])
        expect(message.outputs.type).to eq(:list)
        expect(data_store_facade.identifier_can_insert?(message.outputs.data_store_identifier)).to be_true
        expect(data_store_facade.identifier_can_request?(message.outputs.data_store_identifier)).to be_true
      end
    end

    context "message_verification" do
      it "is a read-only fixed association" do
        expect(message.message_verification.value).to eq(nil)
        expect(message.message_verification.type).to eq(:fixed)
        expect(data_store_facade.identifier_can_insert?(message.message_verification.data_store_identifier)).to be_false
        expect(data_store_facade.identifier_can_request?(message.message_verification.data_store_identifier)).to be_true
      end
    end

    context "transaction" do
      it "is a read-only fixed association" do
        expect(message.transaction.value).to eq(nil)
        expect(message.transaction.type).to eq(:fixed)
        expect(data_store_facade.identifier_can_insert?(message.transaction.data_store_identifier)).to be_false
        expect(data_store_facade.identifier_can_request?(message.transaction.data_store_identifier)).to be_true
      end
    end

    context "transaction_signatures" do
      it "is a read-write list association" do
        expect(message.transaction_signatures.value).to eq([])
        expect(message.transaction_signatures.type).to eq(:list)
        expect(data_store_facade.identifier_can_insert?(message.transaction_signatures.data_store_identifier)).to be_true
        expect(data_store_facade.identifier_can_request?(message.transaction_signatures.data_store_identifier)).to be_true
      end
    end

    context "status" do
      it "is a read-only variable association" do
        expect(message.status.value).to eq(nil)
        expect(message.status.type).to eq(:variable)
        expect(data_store_facade.identifier_can_insert?(message.status.data_store_identifier)).to be_false
        expect(data_store_facade.identifier_can_request?(message.status.data_store_identifier)).to be_true
      end
    end
  end

  describe "build" do
    subject { Coinmux::Message::CoinJoin.build(amount, participants) }

    it "builds valid input" do
      input = subject
      expect(input.valid?).to be_true
    end
  end

  describe "from_json" do
    let(:message) { build(:coin_join_message, amount: amount, participants: participants, participant_transaction_fee: participant_transaction_fee, version: version) }
    let(:json) do
      {
        version: message.version,
        identifier: message.identifier,
        message_public_key: message.message_public_key,
        amount: message.amount,
        participants: message.participants,
        participant_transaction_fee: message.participant_transaction_fee,
        inputs: message.inputs.data_store_identifier,
        message_verification: message.message_verification.data_store_identifier,
        outputs: message.outputs.data_store_identifier,
        transaction: message.transaction.data_store_identifier,
        transaction_signatures: message.transaction_signatures.data_store_identifier,
        outputs: message.outputs.data_store_identifier,
        status: message.status.data_store_identifier
      }.to_json
    end

    subject do
      Coinmux::Message::CoinJoin.from_json(json)
    end

    it "creates a valid input" do
      expect(subject).to_not be_nil
      expect(subject.valid?).to be_true
      expect(subject.version).to eq(message.version)
      expect(subject.identifier).to eq(message.identifier)
      expect(subject.message_public_key).to eq(message.message_public_key)
      expect(subject.amount).to eq(message.amount)
      expect(subject.participants).to eq(message.participants)
      expect(subject.participant_transaction_fee).to eq(message.participant_transaction_fee)
      expect(subject.inputs.data_store_identifier).to eq(message.inputs.data_store_identifier)
      expect(subject.inputs.value).to eq([])
      expect(subject.message_verification.data_store_identifier).to eq(message.message_verification.data_store_identifier)
      expect(subject.message_verification.value).to be_nil
      expect(subject.outputs.data_store_identifier).to eq(message.outputs.data_store_identifier)
      expect(subject.outputs.value).to eq([])
      expect(subject.transaction.data_store_identifier).to eq(message.transaction.data_store_identifier)
      expect(subject.transaction.value).to be_nil
      expect(subject.transaction_signatures.data_store_identifier).to eq(message.transaction_signatures.data_store_identifier)
      expect(subject.transaction_signatures.value).to eq([])
      expect(subject.status.data_store_identifier).to eq(message.status.data_store_identifier)
      expect(subject.status.value).to be_nil
    end
  end
  
  context "message_verification_valid?" do
    let(:coin_join) { build(:coin_join_message, :with_message_verification) }
    let(:prefix) { :the_prefix }
    let(:keys) { %w(foo bar) }
    let(:message_identifier) { coin_join.message_verification.value.message_identifier }
    let(:message_verification) { digest_facade.hex_message_digest(prefix, message_identifier, 'foo', 'bar') }

    before do
      expect(coin_join.director?).to be_true
      expect(coin_join.message_verification.created_with_build?).to be_true
    end

    subject do
      coin_join.message_verification_valid?(prefix, message_verification, *keys)
    end

    context "with matching identifier and keys" do
      it "returns true" do
        expect(subject).to be_true
      end
    end

    context "with incorrect identifier" do
      let(:message_identifier) { "incorrect-identifier" }

      it "returns false" do
        expect(subject).to be_false
      end
    end

    context "with incorrect key" do
      let(:keys) { %w(foot bart) }

      it "returns false" do
        expect(subject).to be_false
      end
    end
  end

  context "build_message_verification" do
    let(:coin_join) do
      build(:coin_join_message, :with_inputs, :with_message_verification).tap do |coin_join|
        # not realistic to be the director and have a built input, but ok for testing
        coin_join.inputs.value.first.created_with_build = true
      end
    end
    let(:prefix) { :a_valid_prefix }
    let(:keys) { %w(foo bar) }
    let(:message_identifier) { coin_join.message_verification.value.message_identifier }
    let(:input) { coin_join.inputs.value.detect(&:created_with_build?) }

    before do
      expect(coin_join.director?).to be_true
      expect(coin_join.message_verification.created_with_build?).to be_true
      expect(input).to_not be_nil
    end

    subject do
      coin_join.build_message_verification(prefix, *keys)
    end

    context "with valid data" do
      it "builds the correct verification message" do
        expect(subject).to eq(digest_facade.hex_message_digest(prefix, message_identifier, *keys))
      end
    end
  end

  context "build_transaction_inputs" do
    let(:coin_join) { build(:coin_join_message, :with_inputs, :with_message_verification, :with_outputs, :with_transaction) }

    before do
      stub_bitcoin_network_for_coin_join(coin_join)
    end

    subject { coin_join.build_transaction_inputs }

    context "when in valid state" do
      it "maps input transactions for address" do
        expect(subject).to eq(coin_join.inputs.value.inject([]) do |acc, input|
          acc += coin_join.minimum_unspent_transaction_inputs(input.address).collect do |tx_input|
            { 'transaction_id' => tx_input[:id], 'output_index' => tx_input[:index] }
          end

          acc
        end)
      end
    end
  end

  context "build_transaction_outputs" do
    let(:coin_join) { build(:coin_join_message, :with_inputs, :with_message_verification, :with_outputs, :with_transaction) }

    before do
      stub_bitcoin_network_for_coin_join(coin_join)
    end

    subject { coin_join.build_transaction_outputs }

    context "when in valid state" do
      context "with change addresses on input" do
        it "maps output address and change address" do
          expected = coin_join.outputs.value.collect do |output|
            { 'address' => output.address, 'amount' => coin_join.amount }
          end

          expected += coin_join.inputs.value.collect do |input|
            unspent_input_amount = bitcoin_network_facade.unspent_inputs_for_address(input.address).values.inject(&:+)
            change_amount = unspent_input_amount - coin_join.amount - coin_join.participant_transaction_fee
            { 'address' => input.address, 'amount' => change_amount }
          end

          expect(subject).to eq(expected)
        end
      end

      context "with no change addresses on input" do
        before do
          coin_join.inputs.value.each do |input|
            input.change_address = nil
          end
        end

        it "maps output address with no change address" do
          expected = coin_join.outputs.value.collect do |output|
            { 'address' => output.address, 'amount' => coin_join.amount }
          end

          expect(subject).to eq(expected)
        end
      end
    end
  end

  context "retrieve_minimum_unspent_transaction_inputs" do
    let(:message) { build(:coin_join_message) }
    let(:unspent_inputs) do
      {
        { id: "a", index: 4 } => 10,
        { id: "b", index: 0 } => 20,
        { id: "c", index: 3 } => 15,
      }
    end

    subject { message.retrieve_minimum_unspent_transaction_inputs(unspent_inputs, minimum_amount) }

    context "with minimum_amount less than largest transaction" do
      let(:minimum_amount) { 15 }

      it "retrieves returns only largest transaction" do
        expect(subject).to eq([{ id: "b", index: 0, amount: 20 }])
      end
    end

    context "with minimum_amount equal largest transaction" do
      let(:minimum_amount) { 20 }

      it "retrieves only largest transaction" do
        expect(subject).to eq([{ id: "b", index: 0, amount: 20 }])
      end
    end

    context "with minimum_amount greater than largest transaction" do
      let(:minimum_amount) { 25 }

      it "retrieves largest two transactions" do
        expect(subject).to eq([{ id: "b", index: 0, amount: 20 }, { id: "c", index: 3, amount: 15 }])
      end
    end

    context "with minimum_amount equal all transactions" do
      let(:minimum_amount) { 45 }

      it "retrieves only largest transaction" do
        expect(subject).to eq([{ id: "b", index: 0, amount: 20 }, { id: "c", index: 3, amount: 15 }, { id: "a", index: 4, amount: 10 }])
      end
    end

    context "with minimum_amount greater than all transactions" do
      let(:minimum_amount) { 46 }

      it "raises error" do
        expect { subject }.to raise_error(Coinmux::Error)
      end
    end
  end
end
