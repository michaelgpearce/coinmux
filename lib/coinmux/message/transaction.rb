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

  def participant_input
    @participant_input ||= coin_join.inputs.value.detect(&:created_with_build?)
  end

  def participant_output
    @participant_output ||= coin_join.outputs.value.detect(&:created_with_build?)
  end

  def participant_input_transactions
    @participant_input_transactions ||= coin_join.minimum_unspent_transaction_inputs(participant_input.address)
  end

  def participant_input_amount
    @participant_input_amount ||= participant_input_transactions.collect { |hash| hash[:amount] }.inject(&:+)
  end

  def participant_change_amount
    @participant_change_amount ||= participant_input_amount - coin_join.amount - coin_join.participant_transaction_fee
  end

  private
  
  def inputs_is_array_of_hashes
    array_of_hashes_is_valid(inputs, :inputs, 'transaction_id', 'output_index')
  end
  
  def outputs_is_array_of_hashes
    array_of_hashes_is_valid(outputs, :outputs, 'address', 'amount', 'identifier')
  end

  def array_of_hashes_is_valid(array, property, *required_keys)
    (errors[property] << "is not an array" and return) unless array.is_a?(Array)

    array.each do |element|
      (errors[property] << "is not a hash" and return) unless element.is_a?(Hash)
      (errors[property] << "does not have correct keys" and return) unless required_keys.sort == element.keys.sort
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

    if !output_exists?(participant_output.address, coin_join.amount, participant_output.transaction_output_identifier)
      errors[:outputs] << "does not have output to #{participant_output.address} for #{coin_join.amount}"
      return
    end

    if participant_input.change_address.nil?
      # this shouldn't ever happen here, but let's make sure we don't send any change as miner fees
      if participant_change_amount != 0
        errors[:outputs] << "has no change address for amount #{participant_change_amount}"
        return
      end
    else
      if !output_exists?(participant_input.change_address, participant_change_amount, participant_input.change_transaction_output_identifier)
        errors[:outputs] << "does not have output to #{participant_input.change_address} for #{participant_change_amount}"
        return
      end
    end
  end

  def output_exists?(address, amount, identifier)
    !!outputs.detect { |output| output['address'] == address && output['amount'] == amount && output['identifier'] == identifier }
  end
end
