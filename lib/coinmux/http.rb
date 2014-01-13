require 'httpclient'

class Coinmux::Http
  include Singleton

  def get(host, path)
    begin
      with_cache(host, path) do
        response = client.get("#{host}#{path}")

        raise Coinmux::Error, "Invalid response code: #{response.code}" if response.code.to_s != '200'

        response.content
      end
    rescue Coinmux::Error => e
      raise e
    rescue SocketError => e
      raise Coinmux::Error, e.message
    rescue StandardError => e
      puts e, e.backtrace
      raise Coinmux::Error, "Unknown error: #{e.message}"
    end
  end

  private

  def cache
    @cache ||= {}
  end

  def clear_cache
    cache.clear
  end

  def with_cache(host, path, &block)
    key = [host, path]

    if (result = @cache[key]).nil?
      result = @cache[key] = yield
    end

    result
  end

  def client
    @client ||= HTTPClient.new
  end
end
