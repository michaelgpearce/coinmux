module Coinmux::Threading
  def self.wait_for_callback(object, method, *args, &callback)
    done = false
    results = nil
    object.send(method, *args) do |*callback_results|
      done = true
      results = callback_results
    end

    loop { break if done; sleep(0.05) }

    results
  end

  def wait_for_callback(method, *args, &callback)
    Coinmux::Threading.wait_for_callback(self, method, *args, &callback)
  end
end
