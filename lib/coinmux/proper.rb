module Coinmux::Proper
  module ClassMethods
    def properties
      @properties ||= []
    end

    def property(*names)
      names.each do |name|
        properties << name.to_sym

        define_method(name) do
          self[name]
        end

        define_method(:"#{name}=") do |value|
          self[name] = value
        end
      end
    end
  end

  module InstanceMethods
    def [](property)
      properties[property.to_s]
    end

    def []=(property, value)
      properties[property.to_s] = value
    end

    def properties
      @properties ||= {}
    end

    def to_hash
      properties.dup
    end

    def to_json
      to_hash.to_json
    end

    def ==(other)
      return false unless other.is_a?(self.class)
      
      return properties == other.properties
    end
  end

  def self.included(base)
    base.send(:include, InstanceMethods)
    base.send(:extend, ClassMethods)
  end
end