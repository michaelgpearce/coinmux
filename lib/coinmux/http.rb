require 'httpclient'

class Coinmux::Http
  include Singleton

  def get(host, path)
    begin
      result = client.get("#{host}#{path}")

      raise Coinmux::Error, "Invalid response code: #{response.code}" if result.code.to_s != '200'

      result.content
    rescue SocketError => e
      raise Coinmux::Error, e.message
    rescue StandardError => e
      puts e, e.backtrace
      raise Coinmux::Error, "Unknown error: #{e.message}"
    end
  end

  private

  def client
    @client ||= HTTPClient.new
  end
end
