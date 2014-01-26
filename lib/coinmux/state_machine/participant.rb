class Coinmux::StateMachine::Participant < Coinmux::StateMachine::Base
  attr_accessor :input_private_key, :input_address, :output_address, :change_address
  
  STATUSES = %w(finding_available_coin_join failed completed)
  COIN_JOIN_MESSAGE_FETCH_SIZE = 50

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

    fetch_most_recent_coin_join_message do |coin_join_message|
      if coin_join_message.nil?
        notify(:no_available_coin_join)
        return
      end

      self.coin_join_message = coin_join_message

      refresh_message(:status) do
        if coin_join_message.status.value && coin_join_message.status.value.status == 'waiting_for_inputs'
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

    insert_message(:inputs, Coinmux::Message::Input.build(coin_join_message, input_private_key, change_address)) do
      notify(:waiting_for_other_inputs)
      wait_for_status('waiting_for_outputs') do
        refresh_message(:inputs) do
          refresh_message(:message_verification) do
            if coin_join_message.message_verification.value.nil?
              # unable to validate message, so we were not part of it
              failure(:input_not_selected)
            else
              start_inserting_output
            end
          end
        end
      end
    end
  end

  def start_inserting_output
    notify(:inserting_output)

    insert_message(:outputs, Coinmux::Message::Output.build(coin_join_message, output_address)) do
      notify(:waiting_for_other_outputs)
      wait_for_status('waiting_for_signatures') do
        refresh_message(:outputs) do
          refresh_message(:transaction) do
            if coin_join_message.transaction.value.nil?
              failure(:transaction_not_found)
            else
              start_inserting_transaction_signatures
            end
          end
        end
      end
    end
  end

  def start_inserting_transaction_signatures
    notify(:inserting_transaction_signatures)

    insert_transaction_signature(0, coin_join_message.transaction.value.inputs.dup)
  end

  def insert_transaction_signature(transaction_message_input_index, remaining_transaction_inputs)
    transaction_input = remaining_transaction_inputs.shift

    if transaction_input.nil?
      start_waiting_for_completed
      return
    end

    if transaction_input['address'] == input_address
      transaction_signature_message = Coinmux::Message::TransactionSignature.build(coin_join_message, transaction_message_input_index, input_private_key)
      insert_message(:transaction_signatures, transaction_signature_message) do
        insert_transaction_signature(transaction_message_input_index + 1, remaining_transaction_inputs)
      end
    else
      insert_transaction_signature(transaction_message_input_index + 1, remaining_transaction_inputs)
    end
  end

  def start_waiting_for_completed
    notify(:waiting_for_completed)

    wait_for_status('completed') do
      notify(:completed)
    end
  end

  def wait_for_status(status, &callback)
    event_queue.future_exec(MESSAGE_POLL_INTERVAL) do
      refresh_message(:status) do
        if coin_join_message.status.value && coin_join_message.status.value.status == status
          yield
        else
          wait_for_status(status, &callback) # try again
        end
      end
    end
  end

  # Searches for a coin_join_message in the reverse order of data added into data store.
  # TODO: there needs to be a better implementation to guard against flooding.
  #
  # @callback [Proc] Invoked with either a CoinJoin message or nil if none could be found.
  def fetch_most_recent_coin_join_message(&callback)
    data_store_facade.fetch_most_recent(coin_join_data_store_identifier, COIN_JOIN_MESSAGE_FETCH_SIZE) do |event|
      handle_event(event, :unable_to_search_for_most_recent_message) do
        event.data.each do |json|
          if coin_join_message = json.nil? ? nil : Coinmux::Message::CoinJoin.from_json(json, nil)
            if coin_join_message.amount == bitcoin_amount && coin_join_message.participants == participant_count
              yield(coin_join_message)
              return
            end
          end
        end

        yield(nil) # unable to locate a match
      end
    end
  end

  def failure(error_identifier, error_message = nil)
    notify(:failed, "#{error_identifier}#{": #{error_message}" if error_message}")
  end
end
