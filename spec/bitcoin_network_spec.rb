require 'spec_helper'

describe Coin2Coin::BitcoinNetwork do
  describe "build_unspent_inputs_from_data" do
    let(:data) { JSON.parse(load_fixture('webbtc_address.json')) }
    let(:address) { 'mjcSuqvGTuq8Ys82juwa69eAb4Z69VaqEE' }

    subject { Coin2Coin::BitcoinNetwork.instance.send(:build_unspent_inputs_from_data, data, address) }

    it "has correct unspent transaction / number and value" do
      expect(subject.size).to eq(1)
      expect(subject[{hash: "50faf760057b52e4a9011d7989a1322b2727f5ce7f1750d5796a3883c1bf0fc7", index: 1}]).to eq(400000000)
    end
  end

  describe "webbtc_get_json" do
    let(:path) { '/a/valid/path' }
    let(:on_success) { lambda { |e| @on_success = e } }
    let(:on_error) { lambda { |e| @on_error = e } }

    before do
      Coin2Coin::Http.instance.stub(:get).with(Coin2Coin::Config.instance.webbtc_host, path).and_yield(event)
    end

    subject do
      Coin2Coin::BitcoinNetwork.instance.send(:webbtc_get_json, path, on_success: on_success, on_error: on_error)
    end

    context "with valid JSON" do
      let(:data) { '{"key": "valid data"}' }
      let(:event) { Coin2Coin::Event.new(data: data) }

      it "invokes on_success with parsed hash event data" do
        subject
        expect(@on_success).to eq(JSON.parse(data))
      end
    end

    context "with error event" do
      let(:error) { 'some error' }
      let(:event) { Coin2Coin::Event.new(error: error) }

      it "invokes on_error with error" do
        subject
        expect(@on_error.error).to eq(error)
      end
    end

    context "with invalid JSON" do
      let(:event) { Coin2Coin::Event.new(data: 'Not JSON') }

      it "invokes on_error with error" do
        subject
        expect(@on_error.error).to eq('Unable to parse JSON')
      end
    end

    context "with error JSON" do
      let(:event) { Coin2Coin::Event.new(data: '{"error": "an error"}') }

      it "invokes on_error with error" do
        subject
        expect(@on_error.error).to eq('Invalid request: an error')
      end
    end
  end
end