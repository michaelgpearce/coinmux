class Cli::Application
  include Coinmux::BitcoinUtil, Coinmux::Facades

  attr_accessor :participant, :director, :notification_callback
  attr_accessor :bitcoin_amount, :participant_count, :input_private_key, :output_address, :change_address


  def initialize(bitcoin_amount, participant_count, input_private_key, output_address, change_address)
    self.bitcoin_amount = (bitcoin_amount.to_f * SATOSHIS_PER_BITCOIN).to_i
    self.participant_count = participant_count.to_i
    self.input_private_key = input_private_key
    self.output_address = output_address
    self.change_address = change_address
  end

  def start
    info "Starting CLI application"

    Coinmux::Message::CoinJoin.build(bitcoin_amount, participant_count).tap do |coin_join_message|
      (puts coin_join_message.errors.full_messages; return) unless coin_join_message.valid?
    end

    Cli::EventQueue.instance.start

    self.notification_callback = Proc.new do |event|
      debug "event queue event received: #{event.inspect}"
      if event.type == :failed
        puts "#{event.source.capitalize}: Error - #{event.message}"
        puts "Quitting..."
        self.director = self.participant = nil # end execution
      else
        puts "[#{event.source.capitalize}]: #{event.type.to_s.gsub('_', ' ').capitalize}#{" : #{event.message}" if event.message}"
        if event.source == :participant
          handle_participant_event(event)
        elsif event.source == :director
          handle_director_event(event)
        else
          raise "Unknown event source: #{event.source}"
        end
      end

      if participant.nil? && director.nil?
        # we are done, so notify the event queue to complete
        Cli::EventQueue.instance.stop
      end
    end

    self.participant = build_participant
    participant.start(&notification_callback)

    Cli::EventQueue.instance.wait
  end

  private

  def build_participant
    Coinmux::StateMachine::Participant.new(
      Cli::EventQueue.instance,
      bitcoin_amount,
      participant_count,
      input_private_key,
      output_address,
      change_address)
  end

  def build_director
    Coinmux::StateMachine::Director.new(Cli::EventQueue.instance, bitcoin_amount, participant_count)
  end

  def handle_participant_event(event)
    if [:no_available_coin_join].include?(event.type)
      if director.nil?
        # start our own Director since we couldn't find one
        self.director = build_director
        director.start(&notification_callback)
      end
    elsif [:input_not_selected, :transaction_not_found].include?(event.type)
      # TODO: try again
    elsif event.type == :completed
      self.participant = nil # done
      puts "Coin join successfully created!"
    elsif event.type == :failed
      self.participant = nil # done
      puts "Coin join failed!"
    end
  end

  def handle_director_event(event)
    if event.type == :waiting_for_inputs
      # our Director is now ready, so let's get started with a new participant
      self.participant = build_participant
      participant.start(&notification_callback)
    elsif event.type == :failed || event.type == :completed
      self.director = nil # done
    end
  end
end
