class Coinmux::CoinJoinUri
  VALID_NETWORKS = %w(tomp2p memory file)

  attr_accessor :identifier, :application, :network

  class << self
    def parse(uri)
      match = uri.to_s.match(/coinjoin:\/\/([^\/]+)\/([^?]+)\?(.*)/)
      raise ArgumentError, "Could not parse URI" if match.nil?

      application = match[1]
      raise ArgumentError, "Invalid application #{application}. Must be coinmux" if application != 'coinmux'

      network = match[2]
      raise ArgumentError, "Invalid network #{network}. Must be one of #{VALID_NETWORKS.join(', ')}" unless VALID_NETWORKS.include?(network)

      query = match[3]
      query_params = query.split('&').inject({}) do |acc, key_and_value|
        key, value = key_and_value.split('=')
        acc[key] = value
        acc
      end

      new(:application => application, :network => network, :identifier => query_params['identifier'])
    end
  end

  def initialize(attrs = {})
    attrs.each do |key, value|
      send("#{key}=", value)
    end
  end
end
