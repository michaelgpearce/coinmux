class Coin2Coin::Message::Base < Hashie::Dash
  include ActiveModel::Model

  ASSOCIATION_TYPES = [:list, :fixed, :variable]

  attr_accessor :coin_join, :created_with_build

  validate :coin_join_valid, :if => :coin_join

  class << self
    def build(coin_join = nil)
      message = build_without_associations(coin_join)

      associations.each do |name, config|
        message.send("#{name}=", Coin2Coin::Message::Association.build(coin_join, name, config[:type], config[:read_only]))
      end

      message
    end

    def add_properties(*properties)
      properties.each { |prop| property(prop) }
    end

    def from_json(json, coin_join = nil)
      return nil if json.nil?

      return nil if json.bytesize > 5_000 # not sure the best number for this, but all our messages should be small

      hash = JSON.parse(json) rescue nil
      return nil unless hash.is_a?(Hash)

      from_hash(hash, coin_join)
    end

    def from_hash(hash, coin_join = nil)
      return nil unless self.properties.collect(&:to_s).sort == hash.keys.sort

      message = self.new
      message.coin_join = coin_join
      hash.each do |property_name, value|
        property = property_name.to_sym
        if associations[property]
          association = association_from_hash(coin_join, property, value)
          return nil if association.nil?

          message.send("#{property}=", association)
        else
          message.send("#{property}=", value.is_a?(Hash) ? value.symbolize_keys : value)
        end
      end

      return nil unless message.valid?

      message
    end

    def add_association(name, type, options)
      options.assert_required_keys!(:read_only)
      raise ArgumentError, "Invalid association type: #{type}" unless ASSOCIATION_TYPES.include?(type)

      property(name)
      associations[name] = options.merge(:type => type)
    end

    protected

    def build_without_associations(coin_join)
      message = new
      message.coin_join = coin_join
      message.created_with_build = true

      message
    end

    private

    def association_from_hash(coin_join, property, hash)
      return nil unless hash.is_a?(Hash)

      config = associations[property]

      Coin2Coin::Message::Association.from_hash(hash, coin_join, property, config[:type], config[:read_only])
    end

    def associations
      @associations ||= {}
    end
  end

  def initialize
    self.created_with_build = false
  end

  def created_with_build?
    !!created_with_build
  end

  private

  def coin_join_valid
    return if coin_join == self

    errors[:coin_join] << "is not valid" unless coin_join.valid?
  end
end
