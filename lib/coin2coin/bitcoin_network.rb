class Coin2Coin::BitcoinNetwork
  include Singleton, Coin2Coin::BitcoinUtil

  SATOSHIS_PER_BITCOIN = 100_000_000

  def current_block_height_and_nonce(&callback)
    raise "TODO"
    # http://blockchain.info/latestblock
  end
  
  def block_exists?(block_height, nonce, &callback)
    raise "TODO"
    # https://blockchain.info/block-height/279588?format=json
  end

  # nil returned if transaction not found, 0 returned if in transaction pool, 1+ if accepted into blockchain
  def transaction_confirmations(transaction_id, &callback)
    raise "TODO"
  end

  def unspent_inputs_from_address(address, &callback)
    webbtc_get_json("/address/#{address}.json", on_error: callback, on_success: lambda do |data|
      yield(Coin2Coin::Event.new(data: build_unspent_inputs_from_data(data, address)))
    end)
  end

  private

  def build_unspent_inputs_from_data(data, address)
    all_inputs = data['transactions'].values.inject({}) do |acc, txn|
      txn['out'].each_with_index do |out, index|
        if out['address'] == address
          acc[{ hash: txn['hash'], index: index}] = out['value'].to_i * SATOSHIS_PER_BITCOIN
        end
      end

      acc
    end

    unspent_inputs = data['transactions'].values.inject(all_inputs.dup) do |acc, txn|
      txn['in'].each do |in_|
        next unless prev_out = in_['prev_out']
        acc.delete({hash: prev_out['hash'], index: prev_out['n']})
      end

      acc
    end

    unspent_inputs
  end

  def webbtc_get_json(path, options = {})
    Coin2Coin::Http.instance.get(Coin2Coin::Config.instance.webbtc_host, path) do |event|
      if event.error
        options[:on_error].call(event)
      else
        hash = JSON.parse(event.data) rescue nil
        if hash.nil?
          options[:on_error].call(Coin2Coin::Event.new(error: "Unable to parse JSON"))
        elsif hash['error']
          options[:on_error].call(Coin2Coin::Event.new(error: "Invalid request: #{hash['error']}"))
        else
          options[:on_success].call(hash)
        end
      end
    end
  end
end