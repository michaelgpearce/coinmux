require 'spec_helper'

describe Coinmux::BitcoinNetwork do
  describe "#unspent_inputs_for_address" do
    let(:data) { load_fixture("#{address}.json") }
    let(:address) { 'mjcSuqvGTuq8Ys82juwa69eAb4Z69VaqEE' }

    before do
      http_facade.stub(:get).with(config_facade.webbtc_host, "/address/#{address}.json").and_return(data)
    end

    subject { bitcoin_network_facade.unspent_inputs_for_address(address) }

    it "has correct unspent transaction / number and value" do
      expect(subject.size).to eq(1)
      expect(subject[{id: "50faf760057b52e4a9011d7989a1322b2727f5ce7f1750d5796a3883c1bf0fc7", index: 1}]).to eq(400000000)
    end
  end

  describe "#build_unsigned_transaction" do
    let(:transaction_id) { "50faf760057b52e4a9011d7989a1322b2727f5ce7f1750d5796a3883c1bf0fc7" }
    let(:transaction_index) { 1 }
    let(:unspent_inputs) { [{id: transaction_id, index: transaction_index}] }
    let(:amount) { 400000000 }
    let(:outputs) { [{ address: Helper.next_bitcoin_info[:address], amount: 100000000 }, { address: Helper.next_bitcoin_info[:address], amount: 300000000 }] }

    before do
      http_facade.stub(:get).with(config_facade.webbtc_host, "/tx/#{transaction_id}.bin").and_return(load_fixture("#{transaction_id}.bin"))
    end

    subject { Coinmux::BitcoinNetwork.instance.build_unsigned_transaction(unspent_inputs, outputs) }

    context "with valid inputs" do
      it "returns a transaction with inputs" do
        expect(subject.getInputs().size()).to eq(1)
        expect(subject.getInput(0).getOutpoint().getHash().to_s).to eq(transaction_id)
        expect(subject.getInput(0).getOutpoint().getIndex()).to eq(1)
        expect(subject.getInput(0).getOutpoint().getConnectedOutput().getValue().to_s.to_i).to eq(amount)
      end

      it "returns transaction to correct address" do
        expect(subject.getOutputs().size()).to eq(outputs.size)
        outputs.each_with_index do |output, index|
          expect(subject.getOutput(index).value()).to eq(output[:amount])
          expect(subject.getOutput(index).getScriptPubKey().getToAddress(network_params).to_s).to eq(output[:address])
        end
      end
    end

    context "with transaction that cannot be found" do
      it "raises an Coinmux::Error" do
        http_facade.stub(:get).with(config_facade.webbtc_host, "/tx/#{transaction_id}.bin").and_raise(Coinmux::Error.new('An http error'))
        expect { subject }.to raise_error(Coinmux::Error, 'An http error')
      end
    end

    context "with invalid transaction index" do
      let(:transaction_index) { 200 }

      it "raises an Coinmux::Error" do
        expect { subject }.to raise_error(Coinmux::Error, 'Output index does not exist')
      end
    end
  end

  describe "#build_transaction_input_script_sig" do
    let(:transaction_id) { "50faf760057b52e4a9011d7989a1322b2727f5ce7f1750d5796a3883c1bf0fc7" }
    let(:transaction_index) { 1 }
    let(:unspent_inputs) { [{id: transaction_id, index: transaction_index}] }
    let(:amount) { 400000000 }
    let(:outputs) { [{ address: Helper.next_bitcoin_info[:address], amount: 100000000 }, { address: Helper.next_bitcoin_info[:address], amount: 300000000 }] }
    let(:transaction) { bitcoin_network_facade.build_unsigned_transaction(unspent_inputs, outputs) }
    let(:input_index) { 0 }
    let(:private_key_hex) { "FA45A0CE998DBC372DB1DD323D689A6FDBA18F5EF8D5E4453EA2454AC4EC4B10" }

    before do
      http_facade.stub(:get).with(config_facade.webbtc_host, "/tx/#{transaction_id}.bin").and_return(load_fixture("#{transaction_id}.bin"))
    end

    subject { bitcoin_network_facade.build_transaction_input_script_sig(transaction, input_index, private_key_hex) }

    context "with valid inputs" do
      it "creates a script_sig" do
        script_sig = Java::ComGoogleBitcoinScript::Script.new(subject.unpack('c*').to_java(:byte))
        tx_input = transaction.getInput(input_index)
        tx_input.setScriptSig(script_sig)
        expect(tx_input.verify()).to be_nil
      end
    end

    context "with invalid private key" do
      let(:private_key_hex) { "FA45A0CE998DBC372DB1DD323D689A6FDBA18F5EF8D5E4453EA2454AC4EC4B11" }

      it "does not verify the input" do
        script_sig = Java::ComGoogleBitcoinScript::Script.new(subject.unpack('c*').to_java(:byte))
        tx_input = transaction.getInput(input_index)
        tx_input.setScriptSig(script_sig)
        expect { tx_input.verify() }.to raise_error(Java::ComGoogleBitcoinCore::ScriptException)
      end
    end

    context "with invalid input index" do
      let(:input_index) { 1 }

      it "raises Coinmux::Error" do
        expect { subject }.to raise_error(Coinmux::Error, 'Invalid input index')
      end
    end
  end

  describe "#sign_transaction_input" do
    let(:transaction_id) { "50faf760057b52e4a9011d7989a1322b2727f5ce7f1750d5796a3883c1bf0fc7" }
    let(:transaction_index) { 1 }
    let(:unspent_inputs) { [{id: transaction_id, index: transaction_index}] }
    let(:amount) { 400000000 }
    let(:outputs) { [{ address: Helper.next_bitcoin_info[:address], amount: 100000000 }, { address: Helper.next_bitcoin_info[:address], amount: 300000000 }] }
    let(:transaction) { bitcoin_network_facade.build_unsigned_transaction(unspent_inputs, outputs) }
    let(:input_index) { 0 }
    let(:private_key_hex) { "FA45A0CE998DBC372DB1DD323D689A6FDBA18F5EF8D5E4453EA2454AC4EC4B10" }
    let(:script_sig) { bitcoin_network_facade.build_transaction_input_script_sig(transaction, input_index, private_key_hex) }

    before do
      http_facade.stub(:get).with(config_facade.webbtc_host, "/tx/#{transaction_id}.bin").and_return(load_fixture("#{transaction_id}.bin"))
    end

    subject { bitcoin_network_facade.sign_transaction_input(transaction, input_index, script_sig) }

    context "with valid inputs" do
      it "creates a script_sig" do
        expect(subject).to be_nil
      end
    end

    context "with invalid script sig" do
      let(:script_sig) { "invalid-sig" }

      it "creates a script_sig" do
        expect { subject }.to raise_error(Coinmux::Error, /Unable to verify signature/)
      end
    end

    context "with invalid input index" do
      let(:input_index) { 1 }

      it "raises Coinmux::Error" do
        expect { subject }.to raise_error(Coinmux::Error, 'Invalid input index')
      end
    end
  end

  describe "#webbtc_get_json" do
    let(:path) { '/a/valid/path' }

    before do
      http_facade.stub(:get).with(config_facade.webbtc_host, path).and_return(data)
    end

    subject do
      bitcoin_network_facade.send(:webbtc_get_json, path)
    end

    context "with valid JSON" do
      let(:data) { '{"key": "valid data"}' }

      it "returns response as hash" do
        expect(subject).to eq(JSON.parse(data))
      end
    end

    context "with invalid JSON" do
      let(:data) { 'Not JSON' }

      it "raises Coinmux::Error" do
        expect { subject }.to raise_error(Coinmux::Error, 'Unable to parse JSON')
      end
    end

    context "with error JSON" do
      let(:data) { '{"error": "an error"}' }

      it "raises Coinmux::Error" do
        expect { subject }.to raise_error(Coinmux::Error, 'Invalid request: an error')
      end
    end
  end
end