class Coin2Coin::StateMachine::Controller
  attr_accessor :controller_message
  
  # Status: "WaitingForInputs" | "WaitingForOutputs" | "WaitingForSignatures" | "WaitingForConfirmation" | "Failed" | "Complete"
  state_machine :state, :initial => :waiting_for_inputs do
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
    
  #   before_transition :parked => any - :parked, :do => :put_on_seatbelt
  # 
  #   after_transition :on => :crash, :do => :tow
  #   after_transition :on => :repair, :do => :fix
  #   after_transition any => :parked do |vehicle, transition|
  #     vehicle.seatbelt_on = false
  #   end
  # 
  #   after_failure :on => :ignite, :do => :log_start_failure
  # 
  #   event :park do
  #     transition [:idling, :first_gear] => :parked
  #   end
  # 
  #   event :shift_up do
  #     transition :idling => :first_gear, :first_gear => :second_gear, :second_gear => :third_gear
  #   end
  # 
  #   state :parked do
  #     def speed
  #       0
  #     end
  #   end
  end

  def initialize(params = {:amount => nil, :minimum_size => nil})
    super() # NOTE: This *must* be called, otherwise states won't get initialized
    
    params.assert_valid_keys(:amount, :minimum_size)
    
    @controller_message = Coin2Coin::Message::Controller.new(params)
    insert_key = Coin2Coin::Config.instance['coin_joins'][params[:amount].to_s]['insert_key']
    
    Coin2Coin::Freenet.instance.insert(insert_key, @controller_message.to_json) do |event|
      if event.error.nil?
        control_status_message = Coin2Coin::Message::ControlStatus.new(:status => state)
        Coin2Coin::Freenet.instance.insert(@controller_message.control_status_queue.read_only_insert_key, control_status_message.to_json) do |event|
        end
      end
    end
  end
end
