require 'spec_helper'

describe Coin2Coin::StateMachine::Controller do
  before do
    fake_all
  end
  
  context "#initialize" do
    let(:amount) { 100_000_000 }
    let(:minimum_size) { 5 }
    let(:coin_join_request_key) { Coin2Coin::Config.instance['coin_joins'][amount.to_s]['request_key'] }
    
    subject do
      Coin2Coin::StateMachine::Controller.new(:amount => amount, :minimum_size => minimum_size)
    end
    
    it "inserts controller message" do
      controller = subject
      
      expect(controller.controller_message.to_json).to eq(fake_freenet.fetch(coin_join_request_key).last)
    end
    
    it "inserts controller message" do
      controller = subject
      
      expect(controller.controller_message.to_json).to eq(fake_freenet.fetch(coin_join_request_key).last)
    end
    
    it "inserts control status message" do
      controller = subject
      
      expect(Coin2Coin::Message::ControlStatus.new(:status => 'waiting_for_inputs', :transaction_id => nil).to_json).to eq(fake_freenet.fetch(controller.controller_message.control_status_queue.request_key).last)
    end
  end
end
