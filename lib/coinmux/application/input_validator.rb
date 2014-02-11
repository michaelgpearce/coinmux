class Coinmux::Application::InputValidator
  include Coinmux::Facades

  ATTRS = [:data_store, :coin_join_uri, :input_private_key, :amount, :participants, :change_address, :output_address]
  attr_accessor *ATTRS

  def initialize(params)
    params.assert_keys!(required: ATTRS)

    params.each do |key, value|
      send("#{key}=", value)
    end
  end

  def validate
    errors = []

    begin
      Coinmux::CoinJoinUri.parse(coin_join_uri)
    rescue Coinmux::Error => e
      errors << ErrorMessage.new(:coin_join_uri, "is invalid", "CoinJoin URI is invalid")
    end

    hex_private_key = begin
      bitcoin_crypto_facade.private_key_to_hex!(input_private_key)
    rescue Coinmux::Error => e
      errors << ErrorMessage.new(:input_private_key, "is invalid")
      nil
    end

    coin_join = Coinmux::Message::CoinJoin.build(data_store, amount: amount, participants: participants)
    coin_join.valid?
    errors += coin_join.errors[:amount].collect { |e| ErrorMessage.new(:amount, e) }
    errors += coin_join.errors[:participants].collect { |e| ErrorMessage.new(:participants, e) }

    input = Coinmux::Message::Input.build(coin_join, private_key: hex_private_key || '', change_address: change_address)
    input.valid?
    errors += input.errors[:address].collect { |e| ErrorMessage.new(:input_address, e) } if hex_private_key
    errors += input.errors[:change_address].collect { |e| ErrorMessage.new(:change_address, e) }

    output = Coinmux::Message::Output.build(coin_join, address: output_address)
    output.valid?
    errors += output.errors[:address].collect { |e| ErrorMessage.new(:output_address, e) }

    errors
  end

  class ErrorMessage
    attr_accessor :key, :message, :full_message

    def initialize(key, message, full_message = "#{key.to_s.capitalize} #{message}")
      self.key, self.message, self.full_message = key, message.to_s, full_message
    end

    def to_s
      full_message
    end
  end
end
