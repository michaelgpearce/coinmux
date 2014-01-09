class Coin2Coin::Message::Association < Coin2Coin::Message::Base
  attr_accessor :name, :type, :data_store_identifier_from_build, :data_store_identifier, :read_only

  validate :data_store_identifier_has_correct_permissions, :unless => :created_with_build?

  class << self
    def build(coin_join, name, type, read_only)
      message = build_without_associations(coin_join)
      message.name = name.to_s
      message.type = type
      message.read_only = read_only
      message.data_store_identifier_from_build = Coin2Coin::DataStore.instance.generate_identifier
      message.data_store_identifier = read_only ?
        Coin2Coin::DataStore.instance.convert_to_request_only_identifier(message.data_store_identifier_from_build) :
        message.data_store_identifier_from_build

      message
    end

    def from_data_store_identifier(data_store_identifier, coin_join, name, type, read_only)
      message = new
      message.coin_join = coin_join

      message.name = name.to_s
      message.type = type
      message.read_only = read_only
      message.data_store_identifier = data_store_identifier

      return nil unless message.valid?

      message
    end
  end

  def initialize
    @messages = []
  end

  def value
    result = if type == :list
      messages
    elsif type == :fixed
      messages.first
    elsif type == :variable
      messages.last
    else
      raise "Unexpected type: #{type.inspect}"
    end

    result
  end

  def messages
    @messages
  end

  def insert(message)
    @messages << message

    Coin2Coin::DataStore.instance.insert(data_store_identifier_from_build || data_store_identifier, message.to_json) {}

    message
  end

  # Note: messages are not directly retrieved since this would require a callback/blocking
  # Instead, there is another thread that updates the messages with this method
  def update_message_jsons(jsons)
    @messages = message_jsons.collect { |json| build_message(json) }.compact
  end

  private

  def data_store_identifier_has_correct_permissions
    can_insert = Coin2Coin::DataStore.instance.identifier_can_insert?(data_store_identifier.to_s)
    can_request = Coin2Coin::DataStore.instance.identifier_can_request?(data_store_identifier.to_s)

    errors[:data_store_identifier] << "must allow requests" unless can_request
    if !read_only
      errors[:data_store_identifier] << "must allow inserts" if !can_insert
    end
  end

  def association_class
    Coin2Coin::Message.const_get(name.split('_').collect(&:capitalize).join.gsub(/e?s$/, ''))
  end

  def build_message(json)
    association_class.from_json(json, coin_join)
  end
end
