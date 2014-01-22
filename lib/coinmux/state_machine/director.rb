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
    bitcoin_network_facade.current_block_height_and_nonce do |event|
      if event.error
        failure(:unable_to_retrieve_block_height_and_nonce, event.error) if status != 'failed' # already failed so don't cause infinite loop
      else
        status_message = coin_join_message.status.value
        block_height = event.data[:block_height]
        nonce = event.data[:nonce]

        status_changed = status_message.nil? ||
          status != status_message.status ||
          block_height != status_message['updated_at']['block_height'] ||
          nonce != status_message['updated_at']['nonce']
        if status_changed
          new_status_message = Coinmux::Message::Status.build(coin_join_message, status, block_height, nonce, transaction_id)
          coin_join_message.status.insert(new_status_message) do
            yield if block_given?
          end
        else
          yield if block_given?
        end
      end
    end
  end

  def failure(error_identifier, error_message)
    update_status('failed', nil, "#{error_identifier}: #{error_message}")
  end
  
  def start_coin_join
    notify(:inserting_coin_join_message)
    insert_message(coin_join_data_store_identifier, coin_join_message) do
      notify(:inserting_status_message)
      insert_current_status_message do
        start_waiting_for_inputs
        start_status_update
      end
    end
  end
  
  def start_waiting_for_inputs
    update_status_and_poll('waiting_for_inputs') do
      fetch_all_messages(Coinmux::Message::Input, coin_join_message.inputs.data_store_identifier) do |input_messages|
        if input_messages.size >= coin_join_message.participants
          notify(:inserting_message_verification_message)
          coin_join_message.message_verification.insert(Coinmux::Message::MessageVerification.build(coin_join_message)) do
            start_waiting_for_outputs
          end
        end
      end
    end
  end
  
  def start_waiting_for_outputs
    update_status_and_poll('waiting_for_outputs') do
      fetch_all_messages(Coinmux::Message::Output, coin_join_message.outputs.data_store_identifier) do |output_messages|
        if output_messages.size == coin_join_message.inputs.value.size
          inputs = coin_join_message.build_transaction_inputs
          outputs = coin_join_message.build_transaction_outputs
          notify(:inserting_transaction_message)
          coin_join_message.transaction.insert(Coinmux::Message::Transaction.build(coin_join_message, inputs, outputs)) do
            start_waiting_for_signatures
          end
        end
      end
    end
  end
  
  def start_waiting_for_signatures
    update_status_and_poll('waiting_for_signatures') do
      fetch_all_messages(Coinmux::Message::TransactionSignature, coin_join_message.transaction_signatures.data_store_identifier) do |transaction_signature_messages|
        if transaction_signature_messages.size == coin_join_message.transaction_message.value.inputs.size
          notify(:publishing_transaction)
          publish_transaction(coin_join_message.transaction_object, transaction_signature_messages) do |transaction_id|
            start_waiting_for_confirmation(transaction_id)
          end
        end
      end
    end
  end

  def start_waiting_for_confirmation(transaction_id)
    update_status_and_poll('waiting_for_confirmation', transaction_id) do
      bitcoin_network.transaction_confirmations(transaction_id) do |event|
        if event.error
          failure(:unable_to_retrieve_transaction, event.error)
        else
          if event.data.nil?
            failure(:unable_to_locate_posted_transaction, "Unable to find transaction on Bitcoin network: #{transaction_id}")
          elsif event.data >= 1
            update_status('completed', transaction_id)
          # else 0 confirmations so try again
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
      event_queue.interval_exec(MESSAGE_POLL_INTERVAL) do |interval_id|
        debug "director waiting for status change: #{status}"
        if self.status == status
          debug "director status not changed"
          yield
        else
          # we are at a different status, so no longer poll for this status
          debug "director received status change: #{status}"
          event_queue.clear_interval(interval_id)
        end
      end
    end
  end

  def publish_transaction(transaction, transaction_signature_messages, &callback)
    transaction_signature_messages = transaction_signature_messages.sort do |a, b|
      a.transaction_input_index <=> b.transaction_input_index
    end

    transaction_signature_messages.each_with_index do |transaction_signature_message, input_index|
      script_sig = Base64.decode64(transaction_signature_message.script_sig)
      bitcoin_network.sign_transaction_input(transaction, input_index, script_sig)
    end

    bitcoin_network.post_transaction(transaction) do |event|
      if event.error
        failure(:unable_to_post_transaction, event.error)
      else
        yield(event.data)
      end
    end
  end
end
