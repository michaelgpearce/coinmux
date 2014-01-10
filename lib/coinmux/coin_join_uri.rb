class Coin2Coin::CoinJoinUri
  attr_accessor :identifier, :application, :network

  class << self
    def parse(uri)
      match = uri.to_s.match(/coinjoin:\/\/([^\/]+)\/([^?]+)\?(.*)/)
      raise ArgumentError, "Could not parse URI" if match.nil?

      query = match[3]
      query_params = query.split('&').inject({}) do |acc, key_and_value|
        key, value = key_and_value.split('=')
        acc[key] = value
        acc
      end

      new(:application => match[1], :network => match[2], :identifier => query_params['identifier'])
    end
  end

  def initialize(attrs = {})
    attrs.each do |key, value|
      send("#{key}=", value)
    end
  end
end
