class Coinmux::Http
  include Singleton

  def get(host, path, options = {}, &callback)
    EM.run do
      http = EM::HttpRequest.new("#{host}#{path}").get({'Accept-Encoding' => 'gzip,deflate,sdch'}.merge!(options))

      http.errback do
        begin
          callback.call(Coinmux::Event.new(error: http.error.to_s))
        ensure
          EM.stop
        end
      end

      http.callback do
        begin
          if http.response_header.status.to_s == '200'
            callback.call(Coinmux::Event.new(data: http.response))
          else
            callback.call(Coinmux::Event.new(error: "Unexpected status code: #{http.response_header.status}"))
          end
        ensure
          EM.stop
        end
      end
    end
  end
end
