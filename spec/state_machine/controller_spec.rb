require 'spec_helper'

describe Coin2Coin::StateMachine::Controller do
  before do
    fake_all
  end
  
  context "#initialize" do
    subject do
      Coin2Coin::StateMachine::Controller.new
    end
    
    it "should be in the new state" do
      expect(subject.state).to eq('new')
    end
  end
  
  context "#announce_coin_join" do
    let(:controller) { Coin2Coin::StateMachine::Controller.new }
    let(:bitcoin_amount) { 100_000_000 }
    let(:minimum_participant_size) { 5 }
    let(:coin_join_request_key) { Coin2Coin::Config.instance['coin_joins'][bitcoin_amount.to_s]['request_key'] }
    
    subject do
      controller.minimum_participant_size = minimum_participant_size
      controller.bitcoin_amount = bitcoin_amount
      controller.announce_coin_join
    end
    
    context "with valid input" do
      it "has status waiting_for_inputs" do
        subject
        
        expect(controller.state).to eq('waiting_for_inputs')
      end
      
      it "inserts coin join message" do
        subject

        expect(fake_freenet.fetch(coin_join_request_key).last).to eq(controller.coin_join_message.to_json)
      end

      it "inserts controller message" do
        subject

        expect(fake_freenet.fetch(controller.coin_join_message.controller_instance.request_key).last).to eq(controller.controller_message.to_json)
      end

      it "inserts control status message" do
        subject

        expect(fake_freenet.fetch(controller.controller_message.control_status_queue.request_key).last).to eq(controller.control_status_message.to_json)
        expect(controller.control_status_message.status).to eq('WaitingForInputs')
        expect(controller.control_status_message.transaction_id).to be_nil
      end
    end
  end
end
