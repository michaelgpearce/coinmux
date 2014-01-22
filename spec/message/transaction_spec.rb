require 'spec_helper'

describe Coinmux::Message::Transaction do
  let(:template_message) { build(:transaction_message) }
  let(:coin_join) { template_message.coin_join }
  let(:inputs) { template_message.inputs }
  let(:outputs) { template_message.outputs }

  before do
    stub_bitcoin_network_for_coin_join(coin_join)
  end

  describe "validations" do
    let(:message) do
      build(:transaction_message,
        inputs: inputs,
        outputs: outputs,
        coin_join: coin_join)
    end

    subject { message.valid? }

    it "is valid with default data" do
      expect(subject).to be_true
    end

    describe "#inputs_is_array_of_hashes" do
      context "with non-array" do
        let(:inputs) { 'not an array' }

        it "is invalid" do
          expect(subject).to be_false
          expect(message.errors[:inputs]).to include("is not an array")
        end
      end

      context "with non-hash array element" do
        let(:inputs) { ['not a hash'] }

        it "is invalid" do
          expect(subject).to be_false
          expect(message.errors[:inputs]).to include("is not a hash")
        end
      end
    end

    describe "#inputs_is_array_of_hashes" do
      context "with non-array" do
        let(:outputs) { 'not an array' }

        it "is invalid" do
          expect(subject).to be_false
          expect(message.errors[:outputs]).to include("is not an array")
        end
      end

      context "with non-hash array element" do
        let(:outputs) { ['not a hash'] }

        it "is invalid" do
          expect(subject).to be_false
          expect(message.errors[:outputs]).to include("is not a hash")
        end
      end
    end

    describe "#has_minimum_number_of_coin_join_amount_outputs" do
      let(:removed_output) { template_message.outputs.detect { |output| output['amount'] == coin_join.amount } }
      let(:outputs) { template_message.outputs.select { |output| output != removed_output } }

      it "is invalid with missing output" do
        expect(subject).to be_false
        expect(message.errors[:outputs]).to include("does not have enough participants")
      end
    end

    describe "#has_no_duplicate_inputs" do
      let(:inputs) { template_message.inputs + [template_message.inputs.first] }

      it "is invalid with duplicate inputs" do
        expect(subject).to be_false
        expect(message.errors[:inputs]).to include("has a duplicate input")
      end
    end

    describe "#has_no_duplicate_outputs" do
      let(:outputs) { template_message.outputs + [template_message.outputs.first] }

      it "is invalid with duplicate outputs" do
        expect(subject).to be_false
        expect(message.errors[:outputs]).to include("has a duplicate output")
      end
    end

    describe "#has_correct_participant_inputs" do
      let(:removed_input_tx) { template_message.participant_input_transactions.first }
      let(:inputs) { template_message.inputs.select { |input| input['transaction_id'] != removed_input_tx[:id] } }

      it "is invalid with missing input" do
        expect(subject).to be_false
        expect(message.errors[:inputs]).to include("does not contain transaction #{removed_input_tx[:id]}:#{removed_input_tx[:index]}")
      end
    end

    describe "#has_correct_participant_outputs" do
      let(:participant_output) { template_message.participant_output }
      let(:participant_output_address) { participant_output.address }
      let(:participant_transaction_output_identifier) { participant_output.transaction_output_identifier }
      let(:participant_input) { template_message.participant_input }
      let(:participant_change_address) { participant_input.change_address }
      let(:participant_change_transaction_output_identifier) { participant_input.change_transaction_output_identifier }
      let(:participant_output_hash) { outputs.detect { |output| output['address'] == participant_output_address } }
      let(:participant_change_hash) { outputs.detect { |output| output['address'] == participant_change_address } }

      context "with incorrect participant coin_join output amount" do
        before do
          participant_output_hash['amount'] = coin_join.amount - 1
          participant_change_hash['amount'] = coin_join.amount # so we have the correct number of coin_join.amount outputs
        end

        it "is invalid" do
          expect(subject).to be_false
          expect(message.errors[:outputs]).to include("does not have output to #{participant_output_address} for #{coin_join.amount}")
        end
      end

      context "with incorrect transaction output identifier" do
        before do
          participant_output.transaction_output_identifier = 'a different identifier'
        end

        it "is invalid" do
          expect(subject).to be_false
          expect(message.errors[:outputs]).to include("does not have output to #{participant_output_address} for #{coin_join.amount}")
        end
      end

      context "with change amount but no change address" do
        before do
          participant_input.change_address = nil
        end

        it "is invalid" do
          expect(subject).to be_false
          expect(message.errors[:outputs]).to include("has no change address for amount #{message.participant_change_amount}")
        end
      end

      context "with incorrect change transaction output identifier" do
        before do
          participant_input.change_transaction_output_identifier = 'a different identifier'
        end

        it "is invalid" do
          expect(subject).to be_false
          expect(message.errors[:outputs]).to include("does not have output to #{message.participant_input.change_address} for #{message.participant_change_amount}")
        end
      end

      context "with incorrect participant change output amount" do
        before do
          participant_change_hash['amount'] = 1
        end

        it "is invalid" do
          expect(subject).to be_false
          expect(message.errors[:outputs]).to include("does not have output to #{message.participant_input.change_address} for #{message.participant_change_amount}")
        end
      end
    end
  end

  describe "#build" do
    subject { Coinmux::Message::Transaction.build(coin_join, inputs, outputs) }

    it "builds valid transaction" do
      expect(subject.valid?).to be_true
    end
  end

  describe "#from_json" do
    let(:message) { template_message }
    let(:json) do
      {
        inputs: message.inputs,
        outputs: message.outputs
      }.to_json
    end

    subject do
      Coinmux::Message::Transaction.from_json(json, coin_join)
    end

    it "creates a valid transaction" do
      expect(subject).to_not be_nil
      expect(subject.valid?).to be_true
      expect(subject.inputs).to eq(message.inputs)
      expect(subject.outputs).to eq(message.outputs)
    end
  end
end
