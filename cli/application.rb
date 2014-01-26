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

    if !(input_errors = validate_inputs).empty?
      puts "Unable to perform CoinJoin due to the following:"
      puts input_errors.collect { |message| " * #{message}" }
      puts "Quitting..."
      return
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

  def validate_inputs
    coin_join = Coinmux::Message::CoinJoin.build(bitcoin_amount, participant_count)
    return coin_join.errors.full_messages unless coin_join.valid?

    input = Coinmux::Message::Input.build(coin_join, input_private_key, change_address)
    input.valid?
    return input.errors[:address].collect { |e| "Input address #{e}" } unless input.errors[:address].nil?
    return input.errors[:change_address].collect { |e| "Change address #{e}" } unless input.errors[:change_address].nil?

    output = Coinmux::Message::Output.build(coin_join, output_address)
    output.valid?
    return output.errors[:address].collect { |e| "Output address #{e}" } unless output.errors[:address].nil?

    []
  end

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
