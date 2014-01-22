class Coinmux::StateMachine::Base
  include Coinmux::Facades
  
  MESSAGE_POLL_INTERVAL = 10

  attr_accessor :event_queue, :coin_join_message, :notification_callback, :status, :bitcoin_amount, :participant_count
  
  def initialize(event_queue, bitcoin_amount, participant_count)
    super() # NOTE: This *must* be called, otherwise states won't get initialized

    coin_join_message = Coinmux::Message::CoinJoin.build(bitcoin_amount, participant_count)
    raise ArgumentError, "Input params should have been validated! #{self.coin_join_message.errors.full_messages}" if !coin_join_message.valid?

    self.bitcoin_amount = bitcoin_amount
    self.participant_count = participant_count

    self.event_queue = event_queue
  end

  protected

  def coin_join_data_store_identifier
    Coinmux::CoinJoinUri.parse(config_facade.coin_join_uri).identifier
  end

  def failure(error_identifier, error_message)
    raise NotImplementedError
  end

  def insert_message(data_store_identifier, message, &callback)
    data_store_facade.insert(data_store_identifier, message.to_json) do |event|
      if event.error
        failure(:unable_to_insert_message, event.error)
      else
        yield
      end
    end
  end
  
  def fetch_all_messages(klass, data_store_identifier, &callback)
    data_store_facade.fetch_all(data_store_identifier) do |event|
      if event.error
        failure(:unable_to_fetch_messages, event.error)
      else
        yield(event.data.collect { |data| klass.from_json(data, coin_join_message) }.compact) # ignore bad data returned by #from_json as nil
      end
    end
  end

  # @callback [Proc] Invoked with Message. Mesage will be nil if not valid (formatting or validity check).
  def fetch_last_message(klass, data_store_identifier, &callback)
    data_store_facade.fetch_last(data_store_identifier) do |event|
      if event.error
        failure(:unable_to_fetch_last_message, event.error)
      else
        yield(event.data.nil? ? nil : klass.from_json(event.data, coin_join_message))
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
      if event.error
        failure(:unable_to_search_for_most_recent_message, event.error)
      else
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

  def source
    self.class.name.gsub(/.*::/, '').downcase.to_sym
  end

  def notify(type, message = nil)
    info "notify: #{source} #{type} #{message}"
    event = Coinmux::StateMachine::Event.new(source: source, type: type, message: message)
    event_queue.sync_exec do
      notification_callback.call(event)
    end
  end

  private

  # @return [Enumerator] When no callback.
  # @callback [Proc, nil] Invoked with Coinmux::Event containing Message data.
  def do_fetch_messages(fetch_method, klass, data_store_identifier, &callback)
    to_enum(:do_fetch_messages, fetch_method, klass, data_store_identifier) unless block_given?

    result = data_store_facade.send(fetch_method, data_store_identifier).collect do |event|
      if event.error
        yield(event)
      else
        message = klass.from_json(event.data, coin_join_message)
        yield(Coinmux::Event.new(data: message)) if message # will result in nil with bad data posted
      end
    end
  end

end
