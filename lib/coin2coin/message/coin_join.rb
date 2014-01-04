class Coin2Coin::Message::CoinJoin < Coin2Coin::Message::Base
  VERSION = 1
  SATOSHIS_PER_BITCOIN = 100_000_000
  DEFAULT_TRANSACTION_FEE = (0.0005 * SATOSHIS_PER_BITCOIN).to_i
  
  add_properties :version, :identifier, :message_public_key, :amount, :participants, :participant_transaction_fee
  add_association :inputs, :list, :read_only => false
  add_association :outputs, :list, :read_only => false
  add_association :message_verification, :fixed, :read_only => true
  add_association :transaction, :fixed, :read_only => true
  add_association :transaction_signatures, :list, :read_only => false
  add_association :status, :variable, :read_only => true
  
  attr_accessor :message_private_key
  
  validates :coin_join, :presence => false
  validates :version, :identifier, :message_public_key, :amount, :participants, :participant_transaction_fee, :presence => true
  validate :participants_numericality, :if => :participants
  validate :participant_transaction_fee_numericality, :if => :participant_transaction_fee
  validate :version_matches, :if => :version
  validate :amount_is_base_2_bitcoin, :if => :amount

  class << self
    def build(amount = SATOSHIS_PER_BITCOIN, participants = 5, participant_transaction_fee = (DEFAULT_TRANSACTION_FEE / participants).to_i)
      message = super(nil)

      message.version = VERSION
      message.identifier = Coin2Coin::Digest.instance.random_identifier
      message.message_private_key, message.message_public_key = Coin2Coin::PKI.instance.generate_keypair
      message.amount = amount
      message.participants = participants
      message.participant_transaction_fee = participant_transaction_fee

      message
    end
  end

  private

  def version_matches
    (errors[:version] << "must be #{VERSION}" and return) unless version.to_s == VERSION.to_s
  end

  def participants_numericality
    (errors[:participants] << "is not an integer" and return) unless participants.to_s.to_i == participants
    (errors[:participants] << "must be at least 2" and return) unless participants > 1
  end

  def participant_transaction_fee_numericality
    (errors[:participant_transaction_fee] << "is not an integer" and return) unless participant_transaction_fee.to_s.to_i == participant_transaction_fee
    (errors[:participant_transaction_fee] << "may not be a negative amount" and return) if participant_transaction_fee < 0
    (errors[:participant_transaction_fee] << "may not be greater than #{DEFAULT_TRANSACTION_FEE}" and return) if participant_transaction_fee > DEFAULT_TRANSACTION_FEE
  end

  def amount_is_base_2_bitcoin
    amount = self.amount.to_s.to_f

    (errors[:amount] << "is not a valid amount" && return) if amount <= 0

    quotient = if amount > SATOSHIS_PER_BITCOIN
      amount / SATOSHIS_PER_BITCOIN.to_f
    else
      SATOSHIS_PER_BITCOIN.to_f / amount
    end
    (errors[:amount] << "is not a valid amount" and return) if quotient.to_i != quotient

    quotient = quotient.to_i

    is_base_2 = (quotient & (quotient - 1)) == 0

    errors[:amount] << "is not a valid amount" unless is_base_2
  end
end
