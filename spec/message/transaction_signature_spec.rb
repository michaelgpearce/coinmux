require 'spec_helper'

describe Coinmux::Message::Transaction do
  let(:template_message) { build(:transaction_signature_message) }
  let(:coin_join) { template_message.coin_join }
  let(:transaction_input_index) { template_message.transaction_input_index }
  let(:script_sig) { template_message.script_sig }
  let(:message_verification) { template_message.message_verification }

  before do
    stub_bitcoin_network_for_coin_join(coin_join)
  end

  describe "validations" do
    let(:message) do
      build(:transaction_signature_message,
        transaction_input_index: transaction_input_index,
        script_sig: script_sig,
        message_verification: message_verification,
        coin_join: coin_join)
    end

    subject { message.valid? }

    it "is valid with default data" do
      expect(subject).to be_true
    end

    describe "#message_verification_correct" do
      let(:message_verification) { 'invalid-message-verification' }

      it "is invalid with incorrect message_verification" do
        expect(subject).to be_false
        expect(message.errors[:message_verification]).to include("cannot be verified")
      end
    end

    describe "#transaction_input_index_valid" do
      it "is invalid with spent transaction" do
        bitcoin_network_facade.should_receive(:transaction_input_unspent?).with(coin_join.transaction_object, transaction_input_index).and_return(false)

        expect(subject).to be_false
        expect(message.errors[:transaction_input_index]).to include("has been spent")
      end
    end

    describe "#script_sig_valid" do
      it "is invalid with script_sig" do
        bitcoin_network_facade.should_receive(:script_sig_valid?).with(coin_join.transaction_object, transaction_input_index, Base64.decode64(script_sig)).and_return(false)

        expect(subject).to be_false
        expect(message.errors[:script_sig]).to include("is not valid")
      end
    end
  end

  describe "#build" do
    let(:private_key_hex) { Helper.next_bitcoin_info[:private_key] }
    let(:script_sig) { "scriptsig-#{rand}" }

    subject { Coinmux::Message::TransactionSignature.build(coin_join, transaction_input_index, private_key_hex) }

    before do
      Coinmux::BitcoinNetwork.instance.stub(:build_transaction_input_script_sig).and_return(script_sig)
    end

    it "builds valid transaction_signature" do
      expect(subject.valid?).to be_true
    end

    it "builds a script sig" do
      Coinmux::BitcoinNetwork.instance.should_receive(:build_transaction_input_script_sig).with(coin_join.transaction_object, transaction_input_index, private_key_hex)

      subject
    end

    it "base 64 encodes the script sig" do
      script_sig = bitcoin_network_facade.build_transaction_input_script_sig(coin_join.transaction_object, transaction_input_index, private_key_hex)
      expect(subject.script_sig).to eq(Base64.encode64(script_sig))
    end

    it "builds a message_verification" do
      expect(subject.message_verification).to eq(coin_join.build_message_verification(:transaction_signature, transaction_input_index, script_sig))
    end
  end

  describe "#from_json" do
    let(:message) { template_message }
    let(:json) do
      {
        transaction_input_index: message.transaction_input_index,
        script_sig: message.script_sig,
        message_verification: message.message_verification
      }.to_json
    end

    subject do
      Coinmux::Message::TransactionSignature.from_json(json, coin_join)
    end

    it "creates a valid transaction_signature" do
      expect(subject).to_not be_nil
      expect(subject.valid?).to be_true
      expect(subject.transaction_input_index).to eq(message.transaction_input_index)
      expect(subject.script_sig).to eq(message.script_sig)
      expect(subject.message_verification).to eq(message.message_verification)
    end
  end
end
