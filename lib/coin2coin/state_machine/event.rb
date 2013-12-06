class Coin2Coin::StateMachine::Event
  attr_accessor :type, :data
  
  def initialize(params = {})
    params.each do |key, value|
      send("#{key}=", value)
    end
  end
end
