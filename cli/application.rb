class Cli::Application
  include Coinmux::BitcoinUtil, Coinmux::Facades

  attr_accessor :participant, :director
  attr_accessor :amount, :participants, :input_private_key, :output_address, :change_address, :coin_join_uri

  def initialize(options = {})
    options.assert_keys!(required: [:amount, :participants, :input_private_key, :output_address, :change_address], optional: [:data_store, :list])

    self.amount = (options[:amount].to_f * SATOSHIS_PER_BITCOIN).to_i
    self.participants = options[:participants].to_i
    self.input_private_key = options[:input_private_key]
    self.output_address = options[:output_address]
    self.change_address = options[:change_address]
    self.coin_join_uri = if options[:data_store]
      "coinjoin://coinmux/#{options[:data_store]}"
    else
      Coinmux::Config.instance.coin_join_uri
    end
  end

  def list_coin_joins
    data_store.startup

    run_list_coin_joins

    data_store.shutdown
  end

  def start
    if self.input_private_key.blank?
      puts "Enter your private key:"
      self.input_private_key = input_password
    end

    input_validator = Coinmux::Application::InputValidator.new(
      data_store: data_store,
      coin_join_uri: coin_join_uri,
      input_private_key: input_private_key,
      amount: amount,
      participants: participants,
      change_address: change_address,
      output_address: output_address)
    if (input_errors = input_validator.validate).present?
      message "Unable to perform CoinJoin due to the following:"
      message input_errors.collect { |message| " * #{message}" }
      message "Quitting..."
      return
    end

    # ensure we have the key in hex
    self.input_private_key = bitcoin_crypto_facade.private_key_to_hex!(input_private_key)

    Kernel.trap('SIGINT') { clean_up_coin_join }
    Kernel.trap('SIGTERM') { clean_up_coin_join }

    message "Starting..."

    data_store.startup

    Cli::EventQueue.instance.start

    self.participant = build_participant
    participant.start(&notification_callback)

    Cli::EventQueue.instance.wait

    data_store.shutdown
  end

  private

  def notification_callback
    @notification_callback ||= Proc.new do |event|
      debug "event queue event received: #{event.inspect}"
      if event.type == :failed
        message "Error - #{event.message}", event.source
        message "Quitting..."
        self.director = self.participant = nil # end execution
      else
        message "#{event.type.to_s.humanize.capitalize}#{" - #{event.message}" if event.message}", event.source
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

  end

  def clean_up_coin_join
    puts "Quitting..."
    if !%w(failed completed).include?(director.try(:coin_join_message).try(:state).try(:value).try(:state))
      director.coin_join_message.status.insert(Coinmux::Message::Status.build(director.coin_join_message, state: 'failed')) do
        Cli::EventQueue.instance.stop
      end
    else
      Cli::EventQueue.instance.stop
    end
  end

  def run_list_coin_joins
    begin
      available_coin_joins = Coinmux::Application::AvailableCoinJoins.new(data_store).find

      if available_coin_joins.empty?
        puts "No available CoinJoins"
      else
        puts "%10s  %12s" % ["BTC Amount", "Participants"]
        puts "#{'=' * 10}  #{'=' * 12}"
        available_coin_joins.each do |hash|
          puts "%-10s  %-12s" % [hash[:amount].to_f / SATOSHIS_PER_BITCOIN, "#{hash[:waiting_participants]} of #{hash[:total_participants]}"]
        end
      end
    rescue Coinmux::Error => e
      puts "Error: #{e}"
    end
  end

  def message(messages, event_type = nil)
    messages = [messages] unless messages.is_a?(Array)
    messages.each do |message|
      message = "%14s %s" % ['[' + event_type.to_s.capitalize + ']:', message] if event_type
      puts message
      info message
    end
  end

  def data_store
    @data_store ||= Coinmux::DataStore::Factory.build(Coinmux::CoinJoinUri.parse(coin_join_uri))
  end

  def build_participant
    Coinmux::StateMachine::Participant.new(
      event_queue: Cli::EventQueue.instance,
      data_store: data_store,
      amount: amount,
      participants: participants,
      input_private_key: input_private_key,
      output_address: output_address,
      change_address: change_address)
  end

  def build_director
    Coinmux::StateMachine::Director.new(
      event_queue: Cli::EventQueue.instance,
      data_store: data_store,
      amount: amount,
      participants: participants)
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
      message "CoinJoin successfully created!"
    elsif event.type == :failed
      self.participant = nil # done
      message "CoinJoin failed!"
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

  def input_password
    line = if PLATFORM == 'java'
      import 'jline.console.ConsoleReader'
      Java::jlineConsole::ConsoleReader.new().readLine(Java::JavaLang::Character.new('*'.bytes.first))
    else
      STDIN.noecho(&:gets)
    end

    line.strip
  end
end
