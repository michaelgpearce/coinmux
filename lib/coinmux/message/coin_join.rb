class Coinmux::Message::CoinJoin < Coinmux::Message::Base
  include Coinmux::BitcoinUtil
  
  VERSION = 1
  
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
      message.identifier = digest_facade.random_identifier
      message.message_private_key, message.message_public_key = pki_facade.generate_keypair
      message.amount = amount
      message.participants = participants
      message.participant_transaction_fee = participant_transaction_fee

      message
    end
  end

  def build_message_verification(prefix, *keys)
    return nil unless input = inputs.value.detect(&:created_with_build?)
    return nil if message_verification.value.nil?
    encoded_secret_message_key = message_verification.value.encrypted_secret_keys[input.address]
    encrypted_secret_message_key = Base64.decode64(encoded_secret_message_key)
    message_private_key = input.message_private_key

    return nil unless secret_message_key = pki_facade.private_decrypt(message_private_key, encrypted_secret_message_key)

    return nil unless message_identifier = cipher_facade.decrypt(
      secret_message_key,
      Base64.decode64(message_verification.value.encrypted_message_identifier))

      digest_facade.hex_message_digest(prefix, message_identifier, *keys)
  end

  def message_verification_valid?(prefix, message_verification, *keys)
    raise ArgumentError, "Only director can check message verification validity" unless director?

    message_verification == digest_facade.hex_message_digest(prefix, self.message_verification.value.message_identifier, *keys)
  end

  def director?
    coin_join.nil?
  end

  def build_transaction_inputs
    raise ArgumentError, "cannot be invoked until all inputs and outputs present" unless ready_to_build_transaction?
    raise ArgumentError, "cannot be called unless director" unless director?

    inputs.value.inject([]) do |acc, input|
      acc += minimum_unspent_transaction_inputs(input.address).collect do |tx_input|
        { 'transaction_id' => tx_input[:id], 'output_index' => tx_input[:index] }
      end

      acc
    end
  end

  def build_transaction_outputs
    raise ArgumentError, "cannot be invoked until all inputs and outputs present" unless ready_to_build_transaction?
    raise ArgumentError, "cannot be called unless director" unless director?

    [].tap do |result|
      result.concat(outputs.value.collect do |output|
        { 'address' => output.address, 'amount' => amount }
      end)

      result.concat(inputs.value.select(&:change_address).collect do |input|
        unspent_input_amount = bitcoin_network_facade.unspent_inputs_for_address(input.address).values.inject(&:+)
        change_amount = unspent_input_amount - amount - participant_transaction_fee
        { 'address' => input.address, 'amount' => change_amount }
      end)
    end
  end

  def ready_to_build_transaction?
    # Note that all outputs have been verified as being associated to an unknown input
    inputs.value.size >= participants && outputs.value.size == inputs.value.size
  end

  def transaction_object
    raise ArgumentError, "cannot be invoked unless transaction present" if transaction.value.nil?

    @transaction_object ||= (
      # Note: we never call this function until we have finalized the transaction inputs/outs with the transaction message

      inputs = transaction.value.inputs.collect { |input| { id: input['transaction_id'], index: input['output_index'] } }
      outputs = transaction.value.outputs.collect { |output| { address: output['address'], amount: output['amount'] } }

      bitcoin_network_facade.build_unsigned_transaction(inputs, outputs)
    )
  end

  # Retrieves the minimum number of inputs that can be used to satisfy the `coin_join#amount` requirement.
  # @address [String] Participant address.
  # @return [Array] Array of hashes with `:id` (transaction hash identifier), `:index` (the index of the transaction output that is unspent) and `:amount` (the unspent amount) sorted from largest amount to smallest amount.
  # @raise [Coinmux::Error] Unable to retrieve inputs or input data invalid
  def minimum_unspent_transaction_inputs(address)
    @minimum_unspent_transaction_inputs_hash ||= {}
    
    if (inputs = @minimum_unspent_transaction_inputs_hash[address]).nil?
      inputs = retrieve_minimum_unspent_transaction_inputs(bitcoin_network_facade.unspent_inputs_for_address(address), amount + participant_transaction_fee)

      @minimum_unspent_transaction_inputs_hash[address] = inputs
    end

    inputs
  end

  def retrieve_minimum_unspent_transaction_inputs(unspent_inputs, minimum_amount)
    total_amount = 0

    inputs = unspent_inputs.collect do |key, amount|
      { id: key[:id], index: key[:index], amount: amount }
    end.sort do |left, right|
      result = right[:amount] <=> left[:amount]
      result = right[:id] <=> left[:id] if result == 0 # ensure always sort the same way when amounts are equal
      result
    end.select do |hash|
      if total_amount < minimum_amount
        total_amount += hash[:amount]
        true
      end
    end

    raise Coinmux::Error, "does not have #{minimum_amount} unspent" if total_amount < minimum_amount

    inputs
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
