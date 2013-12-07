require 'spec_helper'

describe Coin2Coin::StateMachine::Controller do
  before do
    fake_all
  end
  
  context "#initialize" do
    subject do
      Coin2Coin::StateMachine::Controller.new
    end
    
    it "should be in the initialized state" do
      expect(subject.state).to eq('initialized')
    end
  end
  
  context "#start" do
    let(:controller) { Coin2Coin::StateMachine::Controller.new }
    let(:bitcoin_amount) { 100_000_000 }
    let(:minimum_participant_size) { 5 }
    let(:coin_join_request_key) { Coin2Coin::Config.instance['coin_joins'][bitcoin_amount.to_s]['request_key'] }
    
    subject do
      callback_events = []
      controller.start(bitcoin_amount, minimum_participant_size) do |e|
        callback_events << e
      end
      callback_events
    end
    
    context "with valid input" do
      it "invokes callback with no error" do
        callback_events = subject
        
        expect(callback_events.collect(&:type)).to eq([:inserting_status_message, :inserting_coin_join_message, :waiting_for_inputs])
      end
      
      it "has status waiting_for_inputs" do
        subject
        
        expect(controller.state).to eq('waiting_for_inputs')
      end
      
      it "inserts coin join message" do
        subject

        expect(fake_freenet.fetch(coin_join_request_key).last).to eq(controller.coin_join_message.to_json)
      end

      it "inserts status message" do
        subject

        expect(fake_freenet.fetch(controller.coin_join_message.status_queue.request_key).last).to eq(controller.status_message.to_json)
        expect(controller.status_message.status).to eq('WaitingForInputs')
        expect(controller.status_message.transaction_id).to be_nil
      end
    end
  end
end
