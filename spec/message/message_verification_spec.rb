# require 'spec_helper'

# describe Coin2Coin::Message::MessageVerification do
#   before do
#     fake_bitcoin
#   end

#   # property :encrypted_message_identifier
#   # property :encrypted_secret_keys
#   # let(:identifier) { "valid_identifier:#{rand}" }
#   let(:input_messages) { rand(2..3).times.collect { Coin2Coin::Message::Input.build(coin_join) } }
#   let(:coin_join) { Coin2Coin::Message::CoinJoin.build }

#   before do
#     coin_join.input_messages = input_messages
#   end

#   describe "validations" do
#     let(:message) do
#       Coin2Coin::Message::MessageVerification.build(coin_join, input_messages.collect(&:message_public_key))
#     end

#     subject { message.valid? }

#     it "is valid with default data" do
#       subject
#       expect(subject).to be_true
#     end

#     # describe "status_valid" do
#     #   context "when status is invalid" do
#     #     let(:status) { 'InvalidStatus' }

#     #     it "is invalid" do
#     #       expect(subject).to be_false
#     #       expect(message.errors[:status]).to include("is not a valid status")
#     #     end
#     #   end
#     # end
#   end

#   # describe "build" do
#   #   subject { Coin2Coin::Message::MessageVerification.build(coin_join, status, transaction_id) }

#   #   it "builds valid input" do
#   #     input = subject
#   #     expect(input.valid?).to be_true
#   #   end
#   # end

#   # describe "from_json" do
#   #   let(:message) { Coin2Coin::Message::MessageVerification.build(coin_join, status, transaction_id) }
#   #   let(:json) do
#   #     {
#   #       identifier: message.identifier,
#   #       status: message.status,
#   #       transaction_id: message.transaction_id,
#   #       updated_at: message.updated_at
#   #     }.to_json
#   #   end

#   #   subject do
#   #     Coin2Coin::Message::MessageVerification.from_json(json, coin_join)
#   #   end

#   #   it "creates a valid input" do
#   #     expect(subject).to_not be_nil
#   #     expect(subject.valid?).to be_true
#   #     expect(subject.identifier).to eq(message.identifier)
#   #     expect(subject.status).to eq(message.status)
#   #     expect(subject.transaction_id).to eq(message.transaction_id)
#   #     expect(subject.updated_at).to eq(message.updated_at)
#   #   end
#   # end
  
# end
