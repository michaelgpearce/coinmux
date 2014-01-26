class Coinmux::Message::Status < Coinmux::Message::Base
  STATUSES_REQUIRING_TRANSACTION_ID = %w(waiting_for_confirmation completed)

  property :status
  property :transaction_id
  
  validates :status, :presence => true
  validate :transaction_id_presence
  validate :transaction_confirmed, :if => :is_completed?
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
    if STATUSES_REQUIRING_TRANSACTION_ID.include?(status)
      errors[:transaction_id] << "must be present for status #{status}" if transaction_id.nil?
    else
      errors[:transaction_id] << "must not be present for status #{status}" unless transaction_id.nil?
    end
  end

  def is_waiting_for_confirmation?
    status == 'waiting_for_confirmation'
  end

  def is_completed?
    status == 'completed'
  end

  def status_valid
    errors[:status] << "is not a valid status" unless Coinmux::StateMachine::Director::STATUSES.include?(status)
  end

  def transaction_confirmed
    errors[:transaction_id] << "is not confirmed" unless Coinmux::BitcoinNetwork.instance.transaction_confirmations(transaction_id.to_s).to_i > 0
  end
end
