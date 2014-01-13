class Coinmux::StateMachine::Director
  include Coinmux::CoinmuxFacades

  attr_accessor :coin_join_message, :status_message, :bitcoin_amount, :participant_count, :callback
  
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
    
    event :failure do
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
  
  def start(bitcoin_amount, participant_count, &callback)
    self.bitcoin_amount = bitcoin_amount
    self.participant_count = participant_count
    self.callback = callback
    
    start_coin_join
  end
  
  private
  
  def do_wait_for_inputs
    notify(:waiting_for_inputs)
    
    Coinmux::Application.instance.interval_exec(60) do |interval_id|
      if state == 'waiting_for_inputs'
        self.status_message = Coinmux::Message::Status.build(coin_join_message, 'WaitingForInputs')
        insert_message(status_message_identifier, status_message)
      else
        Coinmux::Application.clear_interval(interval_id)
      end
    end
    
    Coinmux::Application.instance.interval_exec(60) do |interval_id|
      if state == 'waiting_for_inputs'
        messages = fetch_all_messages(Coinmux::Message::Input, coin_join_message.inputs.request_key)
        self.status_message = Coinmux::Message::Status.build(coin_join_message, 'WaitingForInputs')
        insert_message(status_message_identifier, status_message)
      else
        Coinmux::Application.clear_interval(interval_id)
      end
    end
    
    waiting_for_inputs_sleep = 60
    update_status_proc = Proc.new do
    end
    Coinmux::Application.instance.future_exec(waiting_for_inputs_sleep, &update_status_proc)
    
    waiting_for_inputs_sleep = 60
    update_status_proc = Proc.new do
      if state == 'waiting_for_inputs'
        self.status_message = Coinmux::Message::Status.build(coin_join_message, 'WaitingForInputs')
        insert_message(status_message_identifier, status_message) do
          Coinmux::Application.instance.future_exec(waiting_for_inputs_sleep, &update_status_proc)
        end
      end
    end
    Coinmux::Application.instance.future_exec(waiting_for_inputs_sleep, &update_status_proc)
  end
  
  def do_announce_coin_join
    self.coin_join_message = Coinmux::Message::CoinJoin.build(bitcoin_amount, participant_count)
    coin_join_message_data_store_identifier = Coinmux::CoinJoinUri.parse(config_facade.coin_join_uri).identifier
    
    self.status_message = Coinmux::Message::Status.build(coin_join_message, 'WaitingForInputs')
    status_message_data_store_identifier = coin_join_message.status.data_store_identifier
    
    # insert messages in "reverse" order, status -> coin_join
    notify(:inserting_status_message)
    insert_message(status_message_data_store_identifier, status_message) do
      notify(:inserting_coin_join_message)
      insert_message(coin_join_message_data_store_identifier, coin_join_message) do
        announce_coin_join_completed
      end
    end
  end
  
  def do_fail
    notify(:error)
  end
  
  def insert_message(data_store_identifier, message, &block)
    if block_given?
      data_store_facade.insert(data_store_identifier, message.to_json) do |event|
        if event.error
          failure
        else
          yield
        end
      end
    else
      data_store_facade.insert(data_store_identifier, message.to_json)
    end
  end
  
  def fetch_all_messages(klass, data_store_identifier)
    data_store_facade.fetch_all(data_store_identifier).collect do |message_json|
      klass.from_json(data) if message_json
    end
  end
  
  def notify(type, data = {})
    event = Coinmux::StateMachine::Event.new(:type => type)
    Coinmux::Application.instance.sync_exec do
      callback.call(event)
    end
  end
  
  def can_announce_coin_join?(*args)
    bitcoin_amount > 0 && participant_count.to_i >= 1
  end
end
