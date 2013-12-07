class Coin2Coin::StateMachine::Controller
  attr_accessor :coin_join_message, :status_message, :bitcoin_amount, :minimum_participant_size, :callback
  
  # Status: "WaitingForInputs" | "WaitingForOutputs" | "WaitingForSignatures" | "WaitingForConfirmation" | "Failed" | "Complete"
  state_machine :state, :initial => :initialized do
    state :initialized do
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
    
    event :fail do
      transition any => :failed
    end
    
    after_transition any => :failed, :do => :do_fail
    
    event :start_coin_join do
      transition :initialized => :waiting_for_inputs, :if => :can_announce_coin_join?
    end

    before_transition any => :waiting_for_inputs, :do => :do_announce_coin_join
    
    after_transition any => :waiting_for_inputs, :do => :do_wait_for_inputs
  end

  # Keep empty initialize method here so super call isn't forgotten if logic added!
  def initialize
    super() # NOTE: This *must* be called, otherwise states won't get initialized
  end
  
  def start(bitcoin_amount, minimum_participant_size, &callback)
    self.bitcoin_amount = bitcoin_amount
    self.minimum_participant_size = minimum_participant_size
    self.callback = callback
    
    start_coin_join
  end
  
  private
  
  def do_wait_for_inputs
    notify(:waiting_for_inputs)
  end
  
  def do_announce_coin_join
    self.coin_join_message = Coin2Coin::Message::CoinJoin.new(:amount => bitcoin_amount, :minimum_size => minimum_participant_size)
    coin_join_message_insert_key = Coin2Coin::Config.instance['coin_joins'][bitcoin_amount.to_s]['insert_key']
    
    self.status_message = Coin2Coin::Message::Status.new(:status => 'WaitingForInputs')
    status_message_insert_key = coin_join_message.status_queue.read_only_insert_key
    
    # insert messages in "reverse" order, status -> coin_join
    notify(:inserting_status_message)
    insert_message(status_message_insert_key, status_message) do
      notify(:inserting_coin_join_message)
      insert_message(coin_join_message_insert_key, coin_join_message)
    end
  end
  
  def do_fail
    notify(:error)
  end
  
  def insert_message(insert_key, message, &block)
    Coin2Coin::Freenet.instance.insert(insert_key, message.to_json) do |event|
      if event.error
        fail
      else
        yield if block_given?
      end
    end
  end
  
  def notify(type, data = {})
    callback.call(Coin2Coin::StateMachine::Event.new(:type => type))
  end
  
  def can_announce_coin_join?(*args)
    bitcoin_amount > 0 && minimum_participant_size.to_i >= 1
  end
end
