require 'spec_helper'

describe Coinmux::StateMachine::Director do
  before do
    fake_all
  end
  
  # describe "#initialize" do
  #   subject do
  #     Coinmux::StateMachine::Director.new
  #   end
    
  #   it "should be in the initialized state" do
  #     expect(subject.state).to eq('initialized')
  #   end
  # end
  
  # describe "#start" do
  #   let(:director) { Coinmux::StateMachine::Director.new }
  #   let(:bitcoin_amount) { 100_000_000 }
  #   let(:participant_count) { 5 }
  #   let(:coin_join_data_store_identifier) { Coinmux::CoinJoinUri.parse(config_facade.coin_join_uri).identifier }
    
  #   subject do
  #     callback_events = []
  #     director.start(bitcoin_amount, participant_count) do |e|
  #       callback_events << e
  #     end
  #     callback_events
  #   end
    
  #   context "with valid input" do
  #     it "invokes callback with no error" do
  #       callback_events = subject
        
  #       expect(callback_events.collect(&:type)).to eq([:inserting_status_message, :inserting_coin_join_message, :waiting_for_inputs])
  #     end
      
  #     it "has status waiting_for_inputs" do
  #       subject
        
  #       expect(director.state).to eq('waiting_for_inputs')
  #     end
      
  #     it "inserts coin join message" do
  #       subject

  #       expect(data_store_facade.fetch(coin_join_data_store_identifier).last).to eq(director.coin_join_message.to_json)
  #     end

  #     it "inserts status message" do
  #       subject

  #       expect(data_store_facade.fetch(director.coin_join_message.status.data_store_identifier).last).to eq(director.status_message.to_json)
  #       expect(director.status_message.status).to eq('WaitingForInputs')
  #       expect(director.status_message.transaction_id).to be_nil
  #     end
  #   end
  # end
end
