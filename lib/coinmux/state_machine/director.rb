class Coinmux::StateMachine::Director < Coinmux::StateMachine::Base
  STATES = %w(waiting_for_inputs waiting_for_outputs waiting_for_signatures failed completed)
  STATUS_UPDATE_INTERVAL = 60
  
  def initialize(options = {})
    assert_initialize_params!(options)

    super(options)

    self.coin_join_message = Coinmux::Message::CoinJoin.build(data_store, amount: options[:amount], participants: options[:participants])
    self.state = 'waiting_for_inputs'
  end
  
  def start(&notification_callback)
    self.notification_callback = notification_callback

    start_coin_join
  end
  
  private

  def start_status_update
    event_queue.interval_exec(STATUS_UPDATE_INTERVAL) do |interval_id|
      info("director doing status update")

      if %w(failed completed).include?(state)
        event_queue.clear_interval(interval_id)
      else
        status_message = coin_join_message.status.value
        insert_current_status_message(status_message.transaction_id)
      end
    end
  end

  def insert_current_status_message(transaction_id = nil, &callback)
    status_message = coin_join_message.status.value

    if status_message.nil? || state != status_message.state
      new_status_message = Coinmux::Message::Status.build(coin_join_message, state: state, transaction_id: transaction_id)
      insert_message(:status, new_status_message) do
        yield if block_given?
      end
    else
      yield if block_given?
    end
  end

  def failure(error_identifier, error_message = nil)
    if state != 'failed' # already failed so don't cause infinite loop
      update_state('failed', nil, "#{error_identifier}: #{error_message}")
    end
  end
  
  def start_coin_join
    notify(:inserting_coin_join_message)
    insert_coin_join_message(coin_join_message) do
      notify(:inserting_status_message)
      insert_current_status_message do
        start_waiting_for_inputs
        start_status_update
      end
    end
  end
  
  def start_waiting_for_inputs
    update_state_and_poll('waiting_for_inputs') do |&continue_poll|
      refresh_message(:inputs) do
        if coin_join_message.inputs.value.size >= coin_join_message.participants
          notify(:inserting_message_verification_message)
          insert_message(:message_verification, Coinmux::Message::MessageVerification.build(coin_join_message)) do
            start_waiting_for_outputs
          end
        else
          continue_poll.call
        end
      end
    end
  end
  
  def start_waiting_for_outputs
    update_state_and_poll('waiting_for_outputs') do |&continue_poll|
      refresh_message(:outputs) do
        if coin_join_message.outputs.value.size == coin_join_message.inputs.value.size
          inputs = coin_join_message.build_transaction_inputs
          outputs = coin_join_message.build_transaction_outputs
          notify(:inserting_transaction_message)
          insert_message(:transaction, Coinmux::Message::Transaction.build(coin_join_message, inputs: inputs, outputs: outputs)) do
            start_waiting_for_signatures
          end
        else
          continue_poll.call
        end
      end
    end
  end
  
  def start_waiting_for_signatures
    update_state_and_poll('waiting_for_signatures') do |&continue_poll|
      refresh_message(:transaction_signatures) do
        if coin_join_message.transaction_signatures.value.size == coin_join_message.transaction.value.inputs.size
          notify(:publishing_transaction)
          publish_transaction do |transaction_id|
            update_state('completed', transaction_id)
          end
        else
          continue_poll.call
        end
      end
    end
  end

  def update_state(state, transaction_id = nil, message = nil, &block)
    info("director updating state to #{state}")

    self.state = state
    insert_current_status_message(transaction_id) do
      notify(state.to_sym, message)
      yield if block_given?
    end
  end

  def update_state_and_poll(state, transaction_id = nil, &block)
    update_state(state, transaction_id) do
      poll_for_state(state, &block)
    end
  end

  def poll_for_state(state, &block)
    event_queue.future_exec(MESSAGE_POLL_INTERVAL) do
      debug "director waiting for state change: #{state}"
      if self.state == state
        debug "director state not changed"
        block.call do
          # call again until state changes
          poll_for_state(state, &block)
        end

      end
    end
  end

  def publish_transaction(&callback)
    transaction = coin_join_message.transaction_object
    transaction_signatures = coin_join_message.transaction_signatures.value

    transaction_signatures = transaction_signatures.sort do |a, b|
      a.transaction_input_index <=> b.transaction_input_index
    end

    transaction_signatures.each_with_index do |transaction_signature, input_index|
      script_sig = Base64.decode64(transaction_signature.script_sig)
      begin
        bitcoin_network_facade.sign_transaction_input(transaction, input_index, script_sig)
      rescue Coinmux::Error => e
        yield Coinmux::Event.new(error: "Unable to sign transaction input: #{e}")
        return
      end
    end

    bitcoin_network_facade.post_transaction(transaction) do |event|
      handle_event(event, :unable_to_post_transaction) do
        yield(event.data)
      end
    end
  end

  def insert_coin_join_message(message, &callback)
    data_store.insert(data_store.coin_join_identifier, message.to_json) do |event|
      handle_event(event, :unable_to_insert_message) do
        yield
      end
    end
  end
  
end
