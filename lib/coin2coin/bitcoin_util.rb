module Coin2Coin::BitcoinUtil
  import 'com.google.bitcoin.core.NetworkParameters'
  
  def network_params
    Coin2Coin::Config.instance.bitcoin_network == 'mainnet' ? NetworkParameters.prodNet() : NetworkParameters.testNet3()
  end
end