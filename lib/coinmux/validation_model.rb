module Coinmux::ValidationModel
  class Errors
    def initialize
      @errors = {}
    end

    def [](key)
      @errors[key.to_sym] ||= []
    end

    def full_messages
      @errors.collect { |key, value| "#{key.to_s.gsub('_', ' ')} #{value}" }
    end

    def clear
      @errors.clear
    end

    def empty?
      @errors.values.flatten.empty?
    end
  end

  module ClassMethods
    def validate(method, options = {})
      method = method.to_sym
      method_validations = validations[method] ||= []

      method_validations << options.dup
    end

    def validations
      @validations ||= {}
    end

    def validates(*attributes)
      options = attributes.pop
      attributes.each do |attribute|
        validate(:validate, options.merge(attribute: attribute))
      end
    end
  end

  module InstanceMethods
    def valid?
      errors.clear

      self.class.validations.each do |method_name, array_of_options|
        array_of_options.each do |options|
          needs_validation =
            (options[:if].nil? && options[:unless].nil?) ||
            (options[:if] && send(options[:if])) ||
            (options[:unless] && !send(options[:unless]))

          if needs_validation
            method(method_name).arity == 0 ? send(method_name) : send(method_name, options)
          end
        end
      end

      errors.empty?
    end

    def errors
      @errors ||= Errors.new
    end

    private

    def validate(options)
      attribute = options[:attribute]

      if !options[:presence].nil?
        errors[attribute] << "is not present" if options[:presence] && send(attribute).blank?
        errors[attribute] << "is present" if !options[:presence] && send(attribute).present?
      end
    end
  end

  def self.included(base)
    base.send(:include, InstanceMethods)
    base.send(:extend, ClassMethods)
  end
end