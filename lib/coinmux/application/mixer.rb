class Coinmux::Application::Mixer
  include Coinmux::Facades

  ATTRS = [:event_queue, :data_store, :amount, :participants, :input_private_key, :output_address, :change_address]

  attr_accessor *ATTRS
  attr_accessor :participant, :director, :notification_callback

  def initialize(attributes)
    attributes.assert_keys!(required: ATTRS)

    attributes.each do |key, value|
      send("#{key}=", value)
    end
  end

  def start(&callback)
    self.notification_callback = callback
    self.participant = build_participant
    participant.start(&mixer_callback)
  end

  def cancel(&callback)
    if !%w(failed completed).include?(director.try(:coin_join_message).try(:state).try(:value).try(:state))
      director.coin_join_message.status.insert(Coinmux::Message::Status.build(director.coin_join_message, state: 'failed')) do
        yield if block_given?
      end
    else
      yield if block_given?
    end
  end


  private

  def notify_event(event)
    notification_callback.call(event)
  end

  def build_participant
    Coinmux::StateMachine::Participant.new(
      event_queue: event_queue,
      data_store: data_store,
      amount: amount,
      participants: participants,
      input_private_key: input_private_key,
      output_address: output_address,
      change_address: change_address)
  end

  def build_director
    Coinmux::StateMachine::Director.new(
      event_queue: event_queue,
      data_store: data_store,
      amount: amount,
      participants: participants)
  end

  def mixer_callback
    @mixer_callback ||= Proc.new do |event|
      debug "event queue event received: #{event.inspect}"
      notify_event(event)

      if event.type == :failed
        self.director = self.participant = nil # end execution
      else
        if event.source == :participant
          handle_participant_event(event)
        elsif event.source == :director
          handle_director_event(event)
        else
          raise "Unknown event source: #{event.source}"
        end
      end

      # nothing left to do
      notify_event(Coinmux::StateMachine::Event.new(source: :mixer, type: :done)) if participant.nil? && director.nil?
    end
  end

  def handle_participant_event(event)
    if [:no_available_coin_join].include?(event.type)
      if director.nil?
        # start our own Director since we couldn't find one
        self.director = build_director
        director.start(&mixer_callback)
      end
    elsif [:input_not_selected, :transaction_not_found].include?(event.type)
      # TODO: try again
    elsif event.type == :completed
      self.participant = nil # done
    elsif event.type == :failed
      self.participant = nil # done
    end
  end

  def handle_director_event(event)
    if event.type == :waiting_for_inputs
      # our Director is now ready, so let's get started with a new participant
      self.participant = build_participant
      participant.start(&mixer_callback)
    elsif event.type == :failed || event.type == :completed
      self.director = nil # done
    end
  end
end