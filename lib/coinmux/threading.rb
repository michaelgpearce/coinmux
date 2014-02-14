module Coinmux::Threading
  def wait_for_callback(*args, &callback)
    done = false
    results = nil
    send(*args) do |*callback_results|
      done = true
      results = callback_results
    end

    loop { break if done; sleep(0.05) }

    results
  end
end
