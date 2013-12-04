class Coin2Coin::StateMachine::Controller
  attr_accessor :controller_message, :coin_join_message, :control_status_message, :bitcoin_amount, :minimum_participant_size
  
  # Status: "New" | "WaitingForInputs" | "WaitingForOutputs" | "WaitingForSignatures" | "WaitingForConfirmation" | "Failed" | "Complete"
  state_machine :state, :initial => :new do
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
    
    event :announce_coin_join do
      transition :new => :waiting_for_inputs, :if => :can_announce_coin_join?
    end

    before_transition :new => :waiting_for_inputs, :do => :do_announce_coin_join
  end

  # Keep empty initialize method here so super call isn't forgotten if logic added!
  def initialize
    super() # NOTE: This *must* be called, otherwise states won't get initialized
  end
  
  private
  
  def do_announce_coin_join
    self.coin_join_message = Coin2Coin::Message::CoinJoin.new
    coin_join_message_insert_key = Coin2Coin::Config.instance['coin_joins'][bitcoin_amount.to_s]['insert_key']
    
    self.controller_message = Coin2Coin::Message::Controller.new(:amount => bitcoin_amount, :minimum_size => minimum_participant_size)
    controller_message_insert_key = coin_join_message.controller_instance.read_only_insert_key
  
    self.control_status_message = Coin2Coin::Message::ControlStatus.new(:status => 'WaitingForInputs')
    control_status_message_insert_key = controller_message.control_status_queue.read_only_insert_key
    
    # insert messages in "reverse" order, control_status -> controller -> coin_join
    Coin2Coin::Freenet.instance.insert(control_status_message_insert_key, control_status_message.to_json) do |event|
      if event.error.nil?
        Coin2Coin::Freenet.instance.insert(controller_message_insert_key, controller_message.to_json) do |event|
          if event.error.nil?
            Coin2Coin::Freenet.instance.insert(coin_join_message_insert_key, coin_join_message.to_json) do |event|
              if event.error.nil?
                # TODO: notify success
              end
            end
          end
        end
      end
    end
  end
  
  def can_announce_coin_join?(*args)
    bitcoin_amount > 0 && minimum_participant_size.to_i >= 1
  end
end
