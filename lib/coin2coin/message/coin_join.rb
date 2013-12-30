class Coin2Coin::Message::CoinJoin < Coin2Coin::Message::Base
  VERSION = 1
  SATOSHIS_PER_BITCOIN = 100_000_000
  
  add_properties :version, :identifier, :message_public_key, :amount, :minimum_participants
  add_association :inputs, :list, :read_only => false
  add_association :outputs, :list, :read_only => false
  add_association :message_verification, :fixed, :read_only => true
  add_association :transaction, :fixed, :read_only => true
  add_association :status, :variable, :read_only => true
  
  attr_accessor :message_private_key
  
  validates :coin_join, :presence => false
  validates :version, :identifier, :message_public_key, :amount, :minimum_participants, :presence => true
  validate :minimum_participants_numericality, :if => :minimum_participants
  validate :version_matches, :if => :version
  validate :amount_is_base_2_bitcoin, :if => :amount

  class << self
    def build(amount = SATOSHIS_PER_BITCOIN, minimum_participants = 5)
      message = super(nil)

      message.version = VERSION
      message.identifier = Coin2Coin::Digest.instance.random_identifier
      message.message_private_key, message.message_public_key = Coin2Coin::PKI.instance.generate_keypair
      message.amount = amount
      message.minimum_participants = minimum_participants

      message
    end
  end

  private

  def version_matches
    (errors[:version] << "must be #{VERSION}" and return) unless version.to_s == VERSION.to_s
  end

  def minimum_participants_numericality
    (errors[:minimum_participants] << "is not an integer" and return) unless minimum_participants.to_s.to_i == minimum_participants
    (errors[:minimum_participants] << "must be at least 2" and return) unless minimum_participants > 1
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
