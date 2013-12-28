class Coin2Coin::StateMachine::Controller
  attr_accessor :coin_join_message, :status_message, :bitcoin_amount, :minimum_participant_size, :callback
  
  STATUSES = %w(WaitingForInputs WaitingForOutputs WaitingForSignatures WaitingForConfirmation Failed Complete)
  
  state_machine :state, :initial => :initialized do
    state :initialized do
    end
    
    state :announcing_coin_join do
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
      transition :initialized => :announcing_coin_join, :if => :can_announce_coin_join?
    end

    after_transition any => :announcing_coin_join, :do => :do_announce_coin_join
    
    event :announce_coin_join_completed do
      transition :announcing_coin_join => :waiting_for_inputs
    end
    
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
    
    Coin2Coin::Application.instance.interval_exec(60) do |interval_id|
      if state == 'waiting_for_inputs'
        self.status_message = Coin2Coin::Message::Status.build(coin_join_message, 'WaitingForInputs')
        insert_message(status_message_insert_key, status_message)
      else
        Coin2Coin::Application.clear_interval(interval_id)
      end
    end
    
    Coin2Coin::Application.instance.interval_exec(60) do |interval_id|
      if state == 'waiting_for_inputs'
        messages = fetch_all_messages(Coin2Coin::Message::Input, coin_join_message.input_list.request_key)
        self.status_message = Coin2Coin::Message::Status.build(coin_join_message, 'WaitingForInputs')
        insert_message(status_message_insert_key, status_message)
      else
        Coin2Coin::Application.clear_interval(interval_id)
      end
    end
    
    waiting_for_inputs_sleep = 60
    update_status_proc = Proc.new do
    end
    Coin2Coin::Application.instance.future_exec(waiting_for_inputs_sleep, &update_status_proc)
    
    waiting_for_inputs_sleep = 60
    update_status_proc = Proc.new do
      if state == 'waiting_for_inputs'
        self.status_message = Coin2Coin::Message::Status.build(coin_join_message, 'WaitingForInputs')
        insert_message(status_message_insert_key, status_message) do
          Coin2Coin::Application.instance.future_exec(waiting_for_inputs_sleep, &update_status_proc)
        end
      end
    end
    Coin2Coin::Application.instance.future_exec(waiting_for_inputs_sleep, &update_status_proc)
  end
  
  def do_announce_coin_join
    self.coin_join_message = Coin2Coin::Message::CoinJoin.build(bitcoin_amount, minimum_participant_size)
    coin_join_message_insert_key = Coin2Coin::CoinJoinUri.parse(Coin2Coin::Config.instance['coin_join_uri']).insert_key
    
    self.status_message = Coin2Coin::Message::Status.build(coin_join_message, 'WaitingForInputs')
    status_message_insert_key = coin_join_message.status_variable.read_only_insert_key
    
    # insert messages in "reverse" order, control_status -> coin_join
    notify(:inserting_status_message)
    insert_message(status_message_insert_key, status_message) do
      notify(:inserting_coin_join_message)
      insert_message(coin_join_message_insert_key, coin_join_message) do
        announce_coin_join_completed
      end
    end
  end
  
  def do_fail
    notify(:error)
  end
  
  def insert_message(insert_key, message, &block)
    if block_given?
      Coin2Coin::DataStore.instance.insert(insert_key, message.to_json) do |event|
        if event.error
          fail
        else
          yield
        end
      end
    else
      Coin2Coin::DataStore.instance.insert(insert_key, message.to_json)
    end
  end
  
  def fetch_all_messages(klass, request_key)
    Coin2Coin::DataStore.instance.fetch_all(request_key).collect do |message_json|
      klass.from_json(data) if message_json
    end
  end
  
  def notify(type, data = {})
    event = Coin2Coin::StateMachine::Event.new(:type => type)
    Coin2Coin::Application.instance.sync_exec do
      callback.call(event)
    end
  end
  
  def can_announce_coin_join?(*args)
    bitcoin_amount > 0 && minimum_participant_size.to_i >= 1
  end
end
