class Coinmux::Message::Transaction < Coinmux::Message::Base
  add_properties :inputs, :outputs

  validate :inputs_is_array_of_hashes
  validate :outputs_is_array_of_hashes
  validate :has_minimum_number_of_coin_join_amount_outputs
  validate :has_no_duplicate_inputs
  validate :has_no_duplicate_outputs
  validate :has_correct_participant_inputs, :unless => :created_with_build?
  validate :has_correct_participant_outputs, :unless => :created_with_build?

  class << self
    def build(coin_join, inputs, outputs)
      message = super(coin_join)

      message.inputs = inputs
      message.outputs = outputs

      message
    end
  end

  private
  
  # Retrieves the minimum number of inputs that can be used to satisfy the `coin_join#amount` requirement.
  # @address [String] Participant address.
  # @return [Array] Array of hashes with `:id` (transaction hash identifier), `:index` (the index of the transaction output that is unspent) and `:amount` (the unspent amount) sorted from largest amount to smallest amount.
  # @raise [Coinmux::Error] Unable to retrieve inputs or input data invalid
  def minimum_unspent_transaction_inputs(address)
    @minimum_unspent_transaction_inputs_hash ||= {}
    
    if (inputs = @minimum_unspent_transaction_inputs_hash[address]).nil?
      inputs = retrieve_minimum_unspent_transaction_inputs(Coinmux::BitcoinNetwork.instance.unspent_inputs_for_address(address), coin_join.amount + coin_join.participant_transaction_fee)

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

  def inputs_is_array_of_hashes
    (errors[:inputs] << "is not an array" and return) unless inputs.is_a?(Array)

    inputs.each do |input|
      (errors[:inputs] << "is not a hash" and return) unless input.is_a?(Hash)
    end
  end
  
  def participant_input
    @participant_input ||= coin_join.inputs.value.detect(&:created_with_build?)
  end

  def participant_input_transactions
    @participant_input_transactions ||= minimum_unspent_transaction_inputs(participant_input.address)
  end

  def participant_output_address
    @participant_output_address ||= coin_join.outputs.value.detect(&:created_with_build?).address
  end

  def participant_change_address
    @participant_change_address ||= coin_join.inputs.value.detect(&:created_with_build?).change_address
  end

  def participant_input_amount
    @participant_input_amount ||= participant_input_transactions.collect { |hash| hash[:amount] }.inject(&:+)
  end

  def participant_change_amount
    @participant_change_amount ||= participant_input_amount - coin_join.amount - coin_join.participant_transaction_fee
  end

  def outputs_is_array_of_hashes
    (errors[:outputs] << "is not an array" and return) unless outputs.is_a?(Array)

    outputs.each do |output|
      (errors[:outputs] << "is not a hash" and return) unless output.is_a?(Hash)
    end
  end
  
  def has_minimum_number_of_coin_join_amount_outputs
    return unless errors[:outputs].empty?

    if outputs.select { |output| output['amount'] == coin_join.amount }.size < coin_join.participants
      errors[:outputs] << "does not have enough participants"
    end
  end

  def has_no_duplicate_inputs
    return unless errors[:inputs].empty?

    if inputs.uniq.size != inputs.size
      errors[:inputs] << "has a duplicate input"
    end
  end

  def has_no_duplicate_outputs
    return unless errors[:outputs].empty?

    if outputs.collect { |output| output['address'] }.uniq.size != outputs.size
      errors[:outputs] << "has a duplicate output"
    end
  end
  
  def has_correct_participant_inputs
    return unless errors[:inputs].empty?

    # every one of the participant transactions must be specified, these are the only transactions participant will sign
    participant_input_transactions.each do |p_tx|
      if inputs.detect { |input| input['transaction_id'] == p_tx[:id] && input['output_index'] == p_tx[:index] }.nil?
        errors[:inputs] << "does not contain transaction #{p_tx[:id]}:#{p_tx[:index]}"
        return
      end
    end
  end

  def has_correct_participant_outputs
    return unless errors[:outputs].empty?

    if outputs.detect { |output| output['address'] == participant_output_address && output['amount'] == coin_join.amount }.nil?
      errors[:outputs] << "does not have output to #{participant_output_address} for #{coin_join.amount}"
      return
    end

    if participant_change_address.nil?
      # this shouldn't ever happen here, but let's make sure we don't send any change as miner fees
      if participant_change_amount != 0
        errors[:outputs] << "has no change address for amount #{participant_change_amount}"
        return
      end
    else
      if outputs.detect { |output| output['address'] == participant_change_address && output['amount'] == participant_change_amount }.nil?
        errors[:outputs] << "does not have output to #{participant_change_address} for #{participant_change_amount}"
        return
      end
    end
  end
end
