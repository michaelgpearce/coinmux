class Coin2Coin::Base
  include ActiveModel::Model
  
  class << self
    def attribute_keys
      @attribute_keys ||= []
    end
    
    def add_attributes(*attributes)
      attributes.each do |attr|
        attr_accessor attr
        attribute_keys << attr.to_sym
      end
    end
  end
  
  def initialize(attrs = {})
    attrs.each do |attr, value|
      send("#{attr}=", value)
    end
  end
  
  def attributes
    self.class.attribute_keys.inject({}) do |acc, attr|
      acc[attr] = send(attr)
      acc
    end
  end
  
  def valid
    valid?
  end
end
