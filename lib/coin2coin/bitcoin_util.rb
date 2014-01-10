module Coin2Coin::BitcoinUtil
  SATOSHIS_PER_BITCOIN = 100_000_000
  DEFAULT_TRANSACTION_FEE = (0.0001 * SATOSHIS_PER_BITCOIN).to_i

  import 'com.google.bitcoin.core.NetworkParameters'
  
  def network_params
    Coin2Coin::Config.instance.bitcoin_network == 'mainnet' ? NetworkParameters.prodNet() : NetworkParameters.testNet3()
  end
end