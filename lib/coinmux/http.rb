require 'net/http'

class Coinmux::Http
  include Singleton, Coinmux::Facades

  def get(host, path, options = {:disable_cache => false})
    begin
      info "HTTP GET Request #{host}#{path}"
      if options[:disable_cache]
        do_get(host, path)
      else
        with_cache(host, path) do
          do_get(host, path)
        end
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

  def do_get(host, path)
    uri = URI("#{host}#{path}")
    response = Net::HTTP.get_response(uri)

    info "HTTP GET Response #{response.code}"
    raise Coinmux::Error, "Invalid response code: #{response.code}" if response.code.to_s != '200'

    # debug "HTTP GET Response Content #{response.body}"
    response.body
  end

  def cache
    @cache ||= {}
  end

  def clear_cache
    cache.clear
  end

  def with_cache(host, path, &block)
    key = [host, path]

    result = cache[key]
    
    info "HTTP cached? #{!result.nil?}"

    if result.nil?
      result = cache[key] = yield
    end

    result
  end
end
