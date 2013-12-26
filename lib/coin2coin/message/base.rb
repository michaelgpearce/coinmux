class Coin2Coin::Message::Base < Hashie::Dash
  include ActiveModel::Model

  attr_accessor :coin_join

  validates :coin_join, :presence => true
  validate :coin_join_valid, :if => :coin_join

  class << self
    def build(coin_join)
      message = new
      message.coin_join = coin_join
      associations.each do |type, association_config|
        association_config.each do |property, options|
          message.send("#{property}_#{type}=", Coin2Coin::Message::Association.new(options[:read_only]))
          message.send("#{property}=", options[:default_value_builder].call)
        end
      end

      message
    end

    def add_properties(*properties)
      properties.each { |prop| property(prop) }
    end

    def add_list_association(property, options)
      add_association(property, :list, lambda { Array.new }, options)
    end

    def add_fixed_association(property, options)
      add_association(property, :fixed, lambda { nil }, options)
    end

    def add_variable_association(property, options)
      add_association(property, :variable, lambda { nil }, options)
    end

    def from_json(json, attributes = {})
      return nil if json.nil?

      return nil if json.bytesize > 5_000 # not sure the best number for this, but all our messages should be small

      hash = JSON.parse(json) rescue nil
      return nil unless hash.is_a?(Hash)

      return nil unless self.properties.collect(&:to_s).sort == hash.keys.sort

      message = self.new
      hash.merge(attributes).each do |key, value|
        message.send("#{key}=", value.is_a?(Hash) ? value.symbolize_keys : value)
      end

      return nil unless message.valid?

      message
    end

    private

    def add_association(property, type, default_value_builder, options)
      options.assert_required_keys!(:read_only)

      attr_accessor property

      property("#{property}_#{type}")
      association_config(type)[property] = options.merge(:default_value_builder => default_value_builder)
    end

    def associations
      @associations ||= {}
    end

    def association_config(type)
      associations[type] ||= {}
    end
  end

  private

  def coin_join_valid
    return if coin_join == self

    errors[:coin_join] << "is not valid" unless coin_join.valid?
  end
end
