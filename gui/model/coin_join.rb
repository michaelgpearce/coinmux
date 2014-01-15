class Gui::Model::CoinJoin < Gui::Model::Base
  add_attributes :created_at, :amount, :inputs, :outputs, :change_output
  
  validate :has_inputs?
  
  DEFAULT_AMOUNT = 1
  
  def initialize(attrs = {})
    super({
      :inputs => [],
      :outputs => [],
      :amount => DEFAULT_AMOUNT,
      :change_output => nil,
      :created_at => Time.now
    }.merge(attrs))
  end
  
  private
  
  def has_inputs?
    inputs
  end
end
