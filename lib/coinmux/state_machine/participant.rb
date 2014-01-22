class Coinmux::StateMachine::Participant < Coinmux::StateMachine::Base
  attr_accessor :input_private_key, :input_address, :output_address, :change_address
  
  STATUSES = %w(finding_available_coin_join failed completed)

  def initialize(event_queue, bitcoin_amount, participant_count, input_private_key, output_address, change_address)
    super(event_queue, bitcoin_amount, participant_count)

    self.input_private_key = input_private_key
    self.input_address = bitcoin_crypto_facade.address_for_private_key!(input_private_key)
    self.output_address = output_address
    self.change_address = change_address
    self.status = 'finding_coin_join'
  end
  
  def start(&notification_callback)
    self.notification_callback = notification_callback

    start_finding_coin_join
  end

  private
  
  def start_finding_coin_join
    notify(:finding_coin_join_message)

    equality_tester = Proc.new do |coin_join_message|
      coin_join_message.amount == bitcoin_amount && coin_join_message.participants == participant_count
    end

    search_for_most_recent_message(Coinmux::Message::CoinJoin, coin_join_data_store_identifier, equality_tester) do |coin_join_message|
      if coin_join_message.nil?
        notify(:no_available_coin_join)
        return
      end

      fetch_last_message(Coinmux::Message::Status, coin_join_message.status.data_store_identifier) do |status_message|
        if status_message && status_message.status == 'waiting_for_inputs'
          self.coin_join_message = coin_join_message
          start_inserting_input
        else
          notify(:no_available_coin_join)
        end
      end
    end
  end

  def start_inserting_input
    notify(:inserting_input)

    coin_join_message.inputs.insert(Coinmux::Message::Input.build(coin_join_message, input_private_key, change_address)) do
      notify(:waiting_for_other_inputs)
      poll_until_status('waiting_for_outputs') do
        fetch_last_message(Coinmux::Message::MessageVerification, coin_join_message.message_verification.data_store_identifier) do |message_verification_message|
          if message_verification_message.nil?
            failure(:input_not_selected)
          else
            coin_join_message.inputs.insert(message_verification_message)
            start_inserting_output
          end
        end
      end
    end
  end

  def start_inserting_output
    notify(:inserting_output)

    coin_join_message.outputs.insert(Coinmux::Message::Output.build(coin_join, output_address)) do
      notify(:waiting_for_other_outputs)
      poll_until_status('waiting_for_signatures') do
        fetch_last_message(Coinmux::Message::Transaction, coin_join_message.transaction.data_store_identifier) do |transaction_message|
          if transaction_message.nil?
            failure(:transaction_not_found)
          else
            coin_join_message.transaction.insert(transaction_message)
            start_inserting_transaction_signatures
          end
        end
      end
    end
  end

  def start_inserting_transaction_signatures
    notify(:inserting_transaction_signatures)

    insert_transaction_signature(0, coin_join_message.transaction.value.inputs)
  end

  def insert_transaction_signature(transaction_input_index, remaining_transaction_inputs)
    transaction_input = remaining_transaction_inputs.shift

    if transaction_input.nil?
      start_waiting_for_confirmation
      return
    end

    if transaction_input['address'] == input_address
      transaction_signature_message = Coinmux::Message::TransactionSignature.build(coin_join, transaction_input_index, input_private_key)
      coin_join_message.transaction_signatures.value.insert(transaction_signature_message) do
        insert_transaction_signature(transaction_input_index + 1, remaining_transaction_inputs)
      end
    else
      insert_transaction_signature(transaction_input_index + 1, remaining_transaction_inputs)
    end
  end

  def start_waiting_for_confirmation
    notify(:waiting_for_confirmation)

    poll_until_status('waiting_for_confirmation') do
      start_waiting_for_completed
    end
  end

  def start_waiting_for_completed
    notify(:waiting_for_completed)

    poll_until_status('completed') do
      notify(:completed)
    end
  end

  def poll_until_status(status, &callback)
    event_queue.interval_exec(MESSAGE_POLL_INTERVAL) do |interval_id|
      fetch_last_message(Coinmux::Message::Status, coin_join_message.status.data_store_identifier) do |status_message|
        if status_message && status_message.status == status
          # we have the message we are waiting for, so quit polling and invoke the callback
          event_queue.clear_interval(interval_id)
          yield
        end
      end
    end
  end

  def failure(error_identifier, error_message = nil)
    notify(:failed, "#{error_identifier}#{": #{error_message}" if error_message}")
  end
end
