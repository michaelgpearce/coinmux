class Coinmux::StateMachine::Director < Coinmux::StateMachine::Base
  STATUSES = %w(waiting_for_inputs waiting_for_outputs waiting_for_signatures waiting_for_confirmation failed completed)
  STATUS_UPDATE_INTERVAL = 60
  
  def initialize(event_queue, bitcoin_amount, participant_count)
    super(event_queue, bitcoin_amount, participant_count)

    self.coin_join_message = Coinmux::Message::CoinJoin.build(bitcoin_amount, participant_count)
    self.status = 'waiting_for_inputs'
  end
  
  def start(&notification_callback)
    self.notification_callback = notification_callback

    start_coin_join
  end
  
  private

  def start_status_update
    event_queue.interval_exec(STATUS_UPDATE_INTERVAL) do |interval_id|
      info("director doing status update")

      if %w(failed completed).include?(status)
        event_queue.clear_interval(interval_id)
      else
        status_message = coin_join_message.status.value
        insert_current_status_message(status_message.transaction_id)
      end
    end
  end

  def insert_current_status_message(transaction_id = nil, &callback)
    status_message = coin_join_message.status.value

    if status_message.nil? || status != status_message.status
      new_status_message = Coinmux::Message::Status.build(coin_join_message, status, transaction_id)
      insert_message(:status, new_status_message) do
        yield if block_given?
      end
    else
      yield if block_given?
    end
  end

  def failure(error_identifier, error_message = nil)
    if status != 'failed' # already failed so don't cause infinite loop
      update_status('failed', nil, "#{error_identifier}: #{error_message}")
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
    update_status_and_poll('waiting_for_inputs') do |&continue_poll|
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
    update_status_and_poll('waiting_for_outputs') do |&continue_poll|
      refresh_message(:outputs) do
        if coin_join_message.outputs.value.size == coin_join_message.inputs.value.size
          inputs = coin_join_message.build_transaction_inputs
          outputs = coin_join_message.build_transaction_outputs
          notify(:inserting_transaction_message)
          insert_message(:transaction, Coinmux::Message::Transaction.build(coin_join_message, inputs, outputs)) do
            start_waiting_for_signatures
          end
        else
          continue_poll.call
        end
      end
    end
  end
  
  def start_waiting_for_signatures
    update_status_and_poll('waiting_for_signatures') do |&continue_poll|
      refresh_message(:transaction_signatures) do
        if coin_join_message.transaction_signatures.value.size == coin_join_message.transaction.value.inputs.size
          notify(:publishing_transaction)
          publish_transaction do |transaction_id|
            start_waiting_for_confirmation(transaction_id)
          end
        else
          continue_poll.call
        end
      end
    end
  end

  def start_waiting_for_confirmation(transaction_id)
    update_status_and_poll('waiting_for_confirmation', transaction_id) do |&continue_poll|
      bitcoin_network_facade.transaction_confirmations(transaction_id) do |event|
        handle_event(event, :unable_to_retrieve_transaction) do
          if event.data.nil?
            failure(:unable_to_locate_posted_transaction, "Unable to find transaction on Bitcoin network: #{transaction_id}")
          elsif event.data >= 1
            update_status('completed', transaction_id)
          else
            # 0 confirmations so try again
            continue_poll.call
          end
        end
      end
    end
  end

  def update_status(status, transaction_id = nil, message = nil, &block)
    info("director updating status to #{status}")

    self.status = status
    insert_current_status_message(transaction_id) do
      notify(status.to_sym, message)
      yield if block_given?
    end
  end

  def update_status_and_poll(status, transaction_id = nil, &block)
    update_status(status, transaction_id) do
      poll_for_status(status, &block)
    end
  end

  def poll_for_status(status, &block)
    event_queue.future_exec(MESSAGE_POLL_INTERVAL) do
      debug "director waiting for status change: #{status}"
      if self.status == status
        debug "director status not changed"
        block.call do
          # call again until status changes
          poll_for_status(status, &block)
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
      bitcoin_network_facade.sign_transaction_input(transaction, input_index, script_sig)
    end

    bitcoin_network_facade.post_transaction(transaction) do |event|
      handle_event(event, :unable_to_post_transaction) do
        yield(event.data)
      end
    end
  end

  def insert_coin_join_message(message, &callback)
    data_store_facade.insert(coin_join_data_store_identifier, message.to_json) do |event|
      handle_event(event, :unable_to_insert_message) do
        yield
      end
    end
  end
  
end
