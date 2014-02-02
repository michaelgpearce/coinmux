class Coinmux::Message::Status < Coinmux::Message::Base
  property :state
  property :transaction_id
  
  validates :state, :presence => true
  validate :transaction_id_presence
  validate :state_valid

  class << self
    def build(coin_join, options = {})
      options.assert_keys!(required: :state, optional: :transaction_id)

      message = super(coin_join.data_store, coin_join)
      message.state = options[:state]
      message.transaction_id = options[:transaction_id]

      message
    end
  end

  private

  def transaction_id_presence
    if state == 'completed'
      errors[:transaction_id] << "must be present for state #{state}" if transaction_id.nil?
    else
      errors[:transaction_id] << "must not be present for state #{state}" unless transaction_id.nil?
    end
  end

  def is_completed?
    state == 'completed'
  end

  def state_valid
    errors[:state] << "is not a valid state" unless Coinmux::StateMachine::Director::STATES.include?(state)
  end
end
