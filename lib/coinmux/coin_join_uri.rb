class Coinmux::CoinJoinUri
  VALID_NETWORKS = %w(p2p filesystem test)

  attr_accessor :params, :application, :network

  class << self
    def parse(uri)
      match = uri.to_s.match(/coinjoin:\/\/([^\/]+)\/([^?]+)\??(.*)/)
      raise Coinmux::Error, "Could not parse URI" if match.nil?

      application = match[1]
      raise Coinmux::Error, "Invalid application #{application}. Must be coinmux" if application != 'coinmux'

      network = match[2]
      raise Coinmux::Error, "Invalid network #{network}. Must be one of #{VALID_NETWORKS.join(', ')}" unless VALID_NETWORKS.include?(network)

      query = match[3]
      query_params = query.split('&').inject({}) do |acc, key_and_value|
        key, value = key_and_value.split('=')
        acc[key] = value
        acc
      end

      new(:application => application, :network => network, :params => query_params)
    end
  end

  def initialize(attrs = {})
    attrs.each do |key, value|
      send("#{key}=", value)
    end
  end
end
