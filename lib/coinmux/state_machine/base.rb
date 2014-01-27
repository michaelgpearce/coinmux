class Coinmux::StateMachine::Base
  include Coinmux::Facades
  
  MESSAGE_POLL_INTERVAL = 5

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
    data_store_facade.get_identifier_from_coin_join_uri(Coinmux::CoinJoinUri.parse(config_facade.coin_join_uri))
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

  def failure(error_identifier, error_message = nil)
    raise NotImplementedError
  end

  def insert_message(association, message, &callback)
    coin_join_message.send(association).insert(message) do |event|
      handle_event(event, :"unable_to_insert_into_#{association}") do
        yield
      end
    end
  end

  def refresh_message(association, &callback)
    coin_join_message.send(association).refresh do |event|
      handle_event(event, :"unable_to_refresh_#{association}") do
        yield
      end
    end
  end

  def handle_event(event, error_identifier, &callback)
    if event.error
      failure(error_identifier, event.error)
    else
      yield
    end
  end
end
