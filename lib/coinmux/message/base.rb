class Coinmux::Message::Base < Hashie::Dash
  include ActiveModel::Model, Coinmux::Facades

  MAX_JSON_DATA_SIZE = 10_000 # not sure the best number for this, but all our messages should be small
  ASSOCIATION_TYPES = [:list, :fixed, :variable]

  attr_accessor :coin_join, :created_with_build

  validate :coin_join_valid, :if => :should_validate_coin_join

  class << self
    def build(coin_join = nil)
      message = build_without_associations(coin_join)

      coin_join = message if self == Coinmux::Message::CoinJoin

      associations.each do |name, config|
        message[name] = Coinmux::Message::Association.build(coin_join, name: name, type: config[:type], read_only: config[:read_only])
      end

      message
    end

    def add_properties(*properties)
      properties.each { |prop| property(prop) }
    end

    def from_json(json, coin_join = nil)
      return nil if json.nil?

      return nil if json.bytesize > MAX_JSON_DATA_SIZE

      hash = JSON.parse(json) rescue nil
      return nil unless hash.is_a?(Hash)

      from_hash(hash, coin_join)
    end

    def from_hash(hash, coin_join = nil)
      return nil unless self.properties.collect(&:to_s).sort == hash.keys.sort

      message = self.new
      coin_join = message if self == Coinmux::Message::CoinJoin

      message.coin_join = coin_join
      hash.each do |property_name, value|
        property = property_name.to_sym
        if associations[property]
          association = association_from_data_store_identifier(coin_join, property, value)
          return nil if association.nil?

          message[property] = association
        else
          message[property] = value
        end
      end

      if !message.valid?
        debug "Message #{self} is not valid: #{hash}, #{message.errors.full_messages}"
        return nil
      end

      message
    end

    def add_association(name, type, options)
      options.assert_required_keys!(:read_only)
      raise ArgumentError, "Invalid association type: #{type}" unless ASSOCIATION_TYPES.include?(type)

      property(name)
      associations[name] = options.merge(:type => type)
    end

    def associations
      @associations ||= {}
    end
    
    protected

    def build_without_associations(coin_join)
      message = new
      message.coin_join = coin_join
      message.created_with_build = true

      message
    end

    private

    def association_from_data_store_identifier(coin_join, property, identifier)
      config = associations[property]

      Coinmux::Message::Association.from_data_store_identifier(identifier, coin_join, property, config[:type], config[:read_only])
    end
  end

  def initialize(attributes = {})
    self.created_with_build = false

    attributes.each do |key, value|
      send("#{key}=", value)
    end
  end

  def director?
    coin_join.director?
  end

  def created_with_build?
    !!created_with_build
  end

  def to_hash
    self.class.associations.keys.reduce(super) do |acc, property|
      acc[property.to_s] = self[property].data_store_identifier
      acc
    end
  end

  private

  def should_validate_coin_join
    !is_a?(Coinmux::Message::CoinJoin) && !is_a?(Coinmux::Message::Association)
  end

  def coin_join_valid
    return if coin_join == self

    errors[:coin_join] << "is not valid" unless coin_join.valid?
  end
end
