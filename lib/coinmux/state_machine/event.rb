class Coinmux::StateMachine::Event
  attr_accessor :source, :type, :message
  
  def initialize(params = {})
    params.each do |key, value|
      send("#{key}=", value)
    end
  end
end
