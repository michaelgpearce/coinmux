class Coin2Coin::Message::Association < Coin2Coin::Message::Base
  property :insert_key
  property :request_key
  
  attr_accessor :read_only_insert_key, :name, :type

  class << self
    def build(coin_join, name, type, read_only)
      message = build_without_associations(coin_join)
      message.name = name.to_s
      message.type = type

      insert_key, request_key = Coin2Coin::DataStore.instance.generate_keypair
      
      if read_only
        message.read_only_insert_key = insert_key
      else
        message.insert_key = insert_key
      end
      message.request_key = request_key

      message
    end

    def from_hash(hash, coin_join, name, type, read_only)
      message = super(hash, coin_join)

      message.name = name.to_s
      message.type = type

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

    Coin2Coin::Fake::DataStore.instance.insert(insert_key, message.to_json) {}

    message
  end

  def update_message_jsons(jsons)
    @messages = message_jsons.collect {|json| build_message(json) }.compact
  end

  private

  def association_class
    Coin2Coin::Message.const_get(name.split('_').collect(&:capitalize).join.gsub(/e?s$/, ''))
  end

  def build_message(json)
    association_class.from_json(json, coin_join)
  end
end
