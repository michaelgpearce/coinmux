require 'spec_helper'

describe Coinmux::Message::Association do
  before do
    fake_all_network_connections
  end

  let(:template_message) { build(:association_message) }
  let(:created_with_build) { template_message.created_with_build }
  let(:name) { template_message.name }
  let(:type) { template_message.type }
  let(:read_only) { template_message.read_only }
  let(:data_store_identifier_from_build) { template_message.data_store_identifier_from_build }
  let(:data_store_identifier) { template_message.data_store_identifier }
  let(:coin_join) { build(:coin_join_message) }

  describe "validations" do
    let(:message) do
      build(:association_message,
        created_with_build: created_with_build,
        name: name,
        type: type,
        read_only: read_only,
        data_store_identifier_from_build: data_store_identifier_from_build,
        data_store_identifier: data_store_identifier,
        coin_join: coin_join)
    end

    subject { message.valid? }

    it "is valid with default data" do
      expect(subject).to be_true
    end

    describe "data_store_identifier_has_correct_permissions" do
      let(:created_with_build) { false }

      context "when data_store_identifier does not allow requests" do
        before do
          Coinmux::DataStore.instance.stub(:identifier_can_request?).and_return(false)
        end

        it "is invalid" do
          expect(subject).to be_false
          expect(message.errors[:data_store_identifier]).to include("must allow requests")
        end
      end

      context "when not read only and data_store_identifier cannot insert" do
        let(:read_only) { false }
        before { Coinmux::DataStore.instance.stub(:identifier_can_insert?).and_return(false) }

        it "is invalid" do
          expect(subject).to be_false
          expect(message.errors[:data_store_identifier]).to include("must allow inserts")
        end
      end

      context "when not read only and data_store_identifier can insert" do
        let(:read_only) { false }
        before { Coinmux::DataStore.instance.stub(:identifier_can_insert?).and_return(true) }

        it "is valid" do
          expect(subject).to be_true
        end
      end
    end
  end

  describe "build" do
    subject { Coinmux::Message::Association.build(coin_join, name, type, read_only) }

    it "builds valid input" do
      expect(subject.valid?).to be_true
    end

    it "has a data_store_identifier_from_build that can insert and request" do
      expect(Coinmux::DataStore.instance.identifier_can_insert?(subject.data_store_identifier_from_build)).to be_true
      expect(Coinmux::DataStore.instance.identifier_can_request?(subject.data_store_identifier_from_build)).to be_true
    end

    context "when read-only" do
      let(:read_only) { true }

      it "has a data_store_identifier that can only request" do
        expect(Coinmux::DataStore.instance.identifier_can_insert?(subject.data_store_identifier)).to be_false
        expect(Coinmux::DataStore.instance.identifier_can_request?(subject.data_store_identifier)).to be_true
      end
    end

    context "when not read-only" do
      let(:read_only) { false }

      it "has a data_store_identifier that can insert and request" do
        expect(Coinmux::DataStore.instance.identifier_can_insert?(subject.data_store_identifier)).to be_true
        expect(Coinmux::DataStore.instance.identifier_can_request?(subject.data_store_identifier)).to be_true
      end

      it "has same data_store_identifier_from_build and data_store_identifier" do
        expect(subject.data_store_identifier).to eq(subject.data_store_identifier_from_build)
      end
    end
  end

  describe "from_data_store_identifier" do
    let(:message) { template_message }
    let(:data_store_identifier) { message.data_store_identifier }

    subject do
      Coinmux::Message::Association.from_data_store_identifier(data_store_identifier, coin_join, name, type, read_only)
    end

    it "creates a valid input" do
      expect(subject).to_not be_nil
      expect(subject.valid?).to be_true
      expect(subject.name).to eq(message.name)
      expect(subject.type).to eq(message.type)
      expect(subject.read_only).to eq(message.read_only)
      expect(subject.data_store_identifier).to eq(message.data_store_identifier)
    end
  end
  
end
