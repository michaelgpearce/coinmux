class Coin2Coin::StateMachine::Controller
  attr_accessor :controller_message, :bitcoin_amount, :minimum_participant_size
  
  # Status: "New" | "WaitingForInputs" | "WaitingForOutputs" | "WaitingForSignatures" | "WaitingForConfirmation" | "Failed" | "Complete"
  state_machine :state, :initial => :new do
    event :wait_for_inputs do
      transition [:new] => :waiting_for_inputs, :if => :bitcoin_amount_and_minimum_participant_size_valid?
    end

    state :new do
    end
    
    state :waiting_for_inputs do
    end
    
    state :waiting_for_outputs do
    end
    
    state :waiting_for_signatures do
    end
    
    state :waiting_for_confirmation do
    end
    
    state :failed do
    end
    
    state :complete do
    end
    
    before_transition :new => :waiting_for_inputs, :do => :create_controller_message
  end

  # Keep empty initialize method here so super call isn't forgotten if logic added!
  def initialize
    super() # NOTE: This *must* be called, otherwise states won't get initialized
  end
  
  private
  
  def create_controller_message
    self.controller_message = Coin2Coin::Message::Controller.new(:amount => bitcoin_amount, :minimum_size => minimum_participant_size)
    insert_key = Coin2Coin::Config.instance['coin_joins'][bitcoin_amount.to_s]['insert_key']
  
    Coin2Coin::Freenet.instance.insert(insert_key, controller_message.to_json) do |event|
      if event.error.nil?
        control_status_message = Coin2Coin::Message::ControlStatus.new(:status => 'WaitingForInputs')
        Coin2Coin::Freenet.instance.insert(controller_message.control_status_queue.read_only_insert_key, control_status_message.to_json) do |event|
        end
      end
    end
  end
  
  def bitcoin_amount_and_minimum_participant_size_valid?
    bitcoin_amount > 0 && minimum_participant_size.to_i >= 1
  end
end
