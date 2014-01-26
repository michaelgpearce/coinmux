class Coinmux::Message::Status < Coinmux::Message::Base
  property :status
  property :transaction_id
  
  validates :status, :presence => true
  validate :transaction_id_presence
  validate :status_valid

  class << self
    def build(coin_join, status, transaction_id = nil)
      message = super(coin_join)
      message.status = status
      message.transaction_id = transaction_id

      message
    end
  end

  private

  def transaction_id_presence
    if status == 'completed'
      errors[:transaction_id] << "must be present for status #{status}" if transaction_id.nil?
    else
      errors[:transaction_id] << "must not be present for status #{status}" unless transaction_id.nil?
    end
  end

  def is_completed?
    status == 'completed'
  end

  def status_valid
    errors[:status] << "is not a valid status" unless Coinmux::StateMachine::Director::STATUSES.include?(status)
  end
end
