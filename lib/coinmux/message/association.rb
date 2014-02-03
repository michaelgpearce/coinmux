class Coinmux::Message::Association < Coinmux::Message::Base
  attr_accessor :name, :type, :data_store_identifier_from_build, :data_store_identifier, :read_only

  validate :data_store_identifier_has_correct_permissions, :unless => :created_with_build?

  class << self
    def build(coin_join, options = {})
      options.assert_keys!(required: [:name, :type, :read_only])

      message = build_without_associations(coin_join.data_store, coin_join)
      message.name = options[:name].to_s
      message.type = options[:type]
      message.read_only = options[:read_only]
      message.data_store_identifier_from_build = coin_join.data_store.generate_identifier
      message.data_store_identifier = options[:read_only] ?
        coin_join.data_store.convert_to_request_only_identifier(message.data_store_identifier_from_build) :
        message.data_store_identifier_from_build

      message
    end

    def from_data_store_identifier(data_store_identifier, coin_join, name, type, read_only)
      message = new
      message.data_store = coin_join.data_store
      message.coin_join = coin_join

      message.name = name.to_s
      message.type = type
      message.read_only = read_only
      message.data_store_identifier = data_store_identifier

      if !message.valid?
        debug "Association message #{name} is not valid: #{message.errors.full_messages}"
        return nil
      end

      message
    end
  end

  def initialize
    # Note: a set is ordered in Ruby, but there is no guarantee of ordering of the messages
    # For :fixed and :variable associations, we rely on the datastore returning the correct first/last inserted message
    @data_store_messages = Set.new
    @inserted_messages = Set.new
  end

  def value
    result = if type == :list
      messages
    elsif type == :fixed
      messages.first
    elsif type == :variable
      messages.first # note: we do a "fetch_last" from data_store facade so there is only ever one message
    else
      raise "Unexpected type: #{type.inspect}"
    end

    result
  end

  # A combination of the inserted messages and the fetched data_store messages from invocations of refresh.
  # The inserted messages are chosen over those from the data store since they may have additional data (keys, etc)
  def messages
    result = if type == :list
      @inserted_messages + @data_store_messages # Set arithmetic will choose inserted over data_store
    elsif type == :fixed || type == :variable
      @inserted_messages.empty? ? @data_store_messages : @inserted_messages # if we inserted it, use it
    end

    result.to_a
  end

  def insert(message, &callback)
    @inserted_messages << message

    data_store.insert(data_store_identifier_from_build || data_store_identifier, message.to_json) do |event|
      yield(event) if block_given?
    end
  end

  def refresh(&callback)
    methods = {
      list: :fetch_all,
      fixed: :fetch_first,
      variable: :fetch_last
    }
    fetch_messages(methods[type]) do |event|
      if event.error
        yield(event)
      else
        @data_store_messages.clear
        @data_store_messages += event.data

        yield(Coinmux::Event.new(data: messages))
      end
    end
  end

  private

  def fetch_messages(method, &callback)
    data_store.send(method, data_store_identifier) do |event|
      if event.error
        yield(event)
      else
        messages = if event.data.nil?
          []
        elsif method == :fetch_all
          event.data.collect { |data| association_class.from_json(data, data_store, coin_join) }
        elsif method == :fetch_first || method == :fetch_last
          [association_class.from_json(event.data, data_store, coin_join)]
        end

        # ignore bad data returned by #from_json as nil with compact
        messages.compact!

        yield(Coinmux::Event.new(data: messages))
      end
    end
  end

  def data_store_identifier_has_correct_permissions
    can_insert = data_store.identifier_can_insert?(data_store_identifier.to_s)
    can_request = data_store.identifier_can_request?(data_store_identifier.to_s)

    errors[:data_store_identifier] << "must allow requests" unless can_request
    if !read_only
      errors[:data_store_identifier] << "must allow inserts" if !can_insert
    end
  end

  def association_class
    Coinmux::Message.const_get(name.classify)
  end

  def build_message(json)
    association_class.from_json(json, data_store, coin_join)
  end
end
