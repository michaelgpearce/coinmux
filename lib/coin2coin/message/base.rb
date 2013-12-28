class Coin2Coin::Message::Base < Hashie::Dash
  include ActiveModel::Model

  ASSOCIATION_TYPES = [:list, :fixed, :variable]

  attr_accessor :coin_join

  validate :coin_join_valid, :if => :coin_join

  class << self
    def build(coin_join = nil)
      message = new
      message.coin_join = coin_join
      associations.each do |(type, name), options|
        message.send("#{association_property(type, name)}=", Coin2Coin::Message::Association.new(options[:read_only]))
        message.send("#{name}=", options[:default_value_builder].call)
      end

      message
    end

    def add_properties(*properties)
      properties.each { |prop| property(prop) }
    end

    def add_list_association(property, options)
      add_association(:list, property, lambda { Array.new }, options)
    end

    def add_fixed_association(property, options)
      add_association(:fixed, property, lambda { nil }, options)
    end

    def add_variable_association(property, options)
      add_association(:variable, property, lambda { nil }, options)
    end

    def from_json(json, coin_join = nil)
      return nil if json.nil?

      return nil if json.bytesize > 5_000 # not sure the best number for this, but all our messages should be small

      hash = JSON.parse(json) rescue nil
      return nil unless hash.is_a?(Hash)

      return nil unless self.properties.collect(&:to_s).sort == hash.keys.sort

      message = self.new
      message.coin_join = coin_join
      hash.each do |property_name, value|
        property = property_name.to_sym
        if (type_and_name = association_property_map[property])
          if value.is_a?(Hash)
            config = associations[type_and_name]
            message.send("#{property}=", build_association(value, config[:read_only]))
            message.send("#{type_and_name.last}=", config[:default_value_builder].call)
          end
        else
          message.send("#{property}=", value.is_a?(Hash) ? value.symbolize_keys : value)
        end
      end

      return nil unless message.valid?

      message
    end

    private

    def build_association(hash, read_only)
      association = Coin2Coin::Message::Association.new(read_only)
      association.request_key = hash['request_key']
      if !read_only
        association.insert_key = hash['insert_key']
      end

      association
    end

    def add_association(type, name, default_value_builder, options)
      options.assert_required_keys!(:read_only)
      raise ArgumentError, "Invalid association type: #{type}" unless ASSOCIATION_TYPES.include?(type)

      attr_accessor name

      association_property = association_property(type, name)
      property(association_property)
      associations[[type, name]] = options.merge(:default_value_builder => default_value_builder)
      association_property_map[association_property] = [type, name]
    end

    def association_property_map
      @association_property_map ||= {}
    end

    def associations
      @associations ||= {}
    end

    def association_property(type, name)
      property_name = type.to_s == 'list' ? name.to_s.gsub(/e?s$/, '') : name
      
      :"#{property_name}_#{type}"
    end
  end

  private

  def coin_join_valid
    return if coin_join == self

    errors[:coin_join] << "is not valid" unless coin_join.valid?
  end
end
