class Coinmux::StateMachine::Base
  include Coinmux::Facades
  
  MESSAGE_POLL_INTERVAL = 5

  attr_accessor :event_queue, :coin_join_message, :notification_callback, :state, :amount, :participants, :data_store
  
  def initialize(options = {})
    super() # NOTE: This *must* be called, otherwise states won't get initialized

    self.event_queue = options[:event_queue]
    self.data_store = options[:data_store]

    coin_join_message = Coinmux::Message::CoinJoin.build(options[:data_store], amount: options[:amount], participants: options[:participants])
    raise ArgumentError, "Input params should have been validated! #{self.coin_join_message.errors.full_messages}" if !coin_join_message.valid?

    self.amount = options[:amount]
    self.participants = options[:participants]
  end

  protected

  def assert_initialize_params!(params, options = {})
    params.assert_keys!(
      required: [:event_queue, :amount, :participants, :data_store] + (options[:required] || []),
      optional: options[:optional])
  end


  def source
    self.class.name.gsub(/.*::/, '').downcase.to_sym
  end

  def notify(type, options = {})
    info "notify: #{source} #{type} #{options}"
    event = Coinmux::StateMachine::Event.new(source: source, type: type, options: options)
    event_queue.sync_exec do
      notification_callback.call(event)
    end
  end

  def failure(error_identifier, error_message = nil)
    raise NotImplementedError
  end

  def insert_message(association, message, coin_join = coin_join_message, &callback)
    coin_join.send(association).insert(message) do |event|
      handle_event(event, :"unable_to_insert_into_#{association}") do
        yield
      end
    end
  end

  def refresh_message(association, coin_join = coin_join_message, &callback)
    coin_join.send(association).refresh do |event|
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
