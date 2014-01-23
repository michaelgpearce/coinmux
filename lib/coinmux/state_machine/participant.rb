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
      poll_until_status('waiting_for_outputs') do
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

  def start_inserting_output
    notify(:inserting_output)

    insert_message(:outputs, Coinmux::Message::Output.build(coin_join, output_address)) do
      notify(:waiting_for_other_outputs)
      poll_until_status('waiting_for_signatures') do
        refresh_message(:transaction) do
          if transaction_message.nil?
            failure(:transaction_not_found)
          else
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
      insert_message(:transaction_signatures, transaction_signature_message) do
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
      refresh_message(:status) do
        if coin_join_message.status.value && coin_join_message.status.value.status == status
          # we have the message we are waiting for, so quit polling and invoke the callback
          event_queue.clear_interval(interval_id)
          yield
        end
      end
    end
  end

  # Searches for a message in the reverse order of data added into data store.
  # TODO: there needs to be a better implementation to guard against flooding.
  #
  # @equality_tester [Proc] Called with a message to test if it matches search criteria. Return truthy value if equivalent.
  # @max_size [Fixnum] The maximum datasize to search before returning nil as the callback Event data.
  # @callback [Proc] Invoked with Message. Mesage will be the matched data or nil if none could be found.
  def search_for_most_recent_message(klass, data_store_identifier, equality_tester, max_size = 50, &callback)
    data_store_facade.fetch_most_recent(data_store_identifier, max_size) do |event|
      handle_event(event, :unable_to_search_for_most_recent_message) do
        event.data.each do |json|
          if message = json.nil? ? nil : klass.from_json(json, coin_join_message)
            if equality_tester.call(message)
              yield(message)
              return
            end
          end
        end

        yield(nil) # unable to locate a match
      end
    end
  end
end
