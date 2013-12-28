class Coin2Coin::Message::CoinJoin < Coin2Coin::Message::Base
  VERSION = 1
  
  add_properties :version, :identifier, :message_public_key, :amount, :minimum_participants
  add_list_association :inputs, :read_only => false
  add_list_association :outputs, :read_only => false
  add_fixed_association :message_verification, :read_only => true
  add_fixed_association :transaction, :read_only => true
  add_variable_association :status, :read_only => true
  
  attr_accessor :message_private_key
  
  validates :version, :identifier, :message_public_key, :amount, :minimum_participants, :presence => true
  validate :minimum_participants_numericality, :if => :minimum_participants
  validate :version_matches, :if => :version
  validate :amount_is_base_2_bitcoin, :if => :amount

  class << self
    def build(amount = 100_000_000, minimum_participants = 5)
      message = super(nil)
      message.coin_join = message

      message.version = VERSION
      message.identifier = Coin2Coin::Digest.random_identifier
      message.message_private_key, message.message_public_key = Coin2Coin::PKI.instance.generate_keypair
      message.amount = amount
      message.minimum_participants = minimum_participants

      message
    end
  end

  private

  def version_matches
    (errors[:version] << "must be #{VERSION}" and return) unless version == VERSION
  end

  def minimum_participants_numericality
    (errors[:minimum_participants] << "is not an integer" and return) unless minimum_participants.to_s.to_i == minimum_participants
    (errors[:minimum_participants] << "must be at least 2" and return) unless minimum_participants > 1
  end

  def amount_is_base_2_bitcoin
    amount = self.amount.to_s.to_i

    (errors[:amount] << "is not a valid amount" && return) if amount <= 0

    quotient = if amount > 100_000_000
      amount / 100_000_000
    else
      100_000_000 / amount
    end
    quotient = quotient.to_i

    is_base_2 = (quotient & (quotient - 1)) == 0

    errors[:amount] << "is not a valid amount" unless is_base_2
  end
end
