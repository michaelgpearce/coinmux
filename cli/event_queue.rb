require 'thread'
require 'set'

class Cli::EventQueue
  include Singleton, Coinmux::BitcoinUtil

  attr_reader :queue, :cleared_interval_identifiers, :event_thread

  def initialize
    @queue = Queue.new
    @cleared_interval_identifiers = Set.new
  end

  def start
    @event_thread = start_event_thread
    nil
  end

  def stop
    # nil message in queue kills event thread
    queue << nil
    nil
  end

  def wait
    event_thread.join
  end

  def sync_exec(&callback)
    if Thread.current == event_thread
      yield
    else
      mutex = Mutex.new
      condition_variable = ConditionVariable.new

      mutex.synchronize do
        queue << Cli::Event.new(
          mutex: mutex,
          condition_variable: condition_variable,
          callback: callback)

        condition_variable.wait(mutex)
      end
    end
  end
  
  def future_exec(seconds = 0, &callback)
    queue << Cli::Event.new(
      invoke_at: Time.now + seconds,
      callback: callback)
    nil
  end
  
  def interval_exec(seconds, &callback)
    interval_identifier = rand.to_s
    queue << Cli::Event.new(
      invoke_at: Time.now + seconds,
      callback: callback,
      interval_period: seconds,
      interval_identifier: interval_identifier)

    interval_identifier
  end
  
  def clear_interval(interval_identifier)
    cleared_interval_identifiers << interval_identifier
  end

  private

  def start_event_thread
    Thread.new do
      while event = queue.pop # nil in the event thread indicates to quit
        events_to_enqueue = []
        all_events = [event] + queue.size.times.collect { queue.pop }
        all_events.each do |event|
          if event.nil? # nil in the event thread indicates to quit
            break
          elsif cleared_interval_identifiers.include?(event.interval_identifier)
            # remove interval so do not re-enqueue
            cleared_interval_identifiers.delete(event.interval_identifier)
          elsif event.invoke_at && Time.now < event.invoke_at
            # interval has not passed, so re-enqueue
            events_to_enqueue << event
          else
            # invoke the callback
            invocation = lambda do
              begin
                event.callback.call
              rescue
                puts "Unhandled exception in event thread: #{$!}"
                puts $!.backtrace
              end
            end

            if event.mutex
              event.mutex.synchronize do
                begin
                  invocation.call
                ensure
                  event.condition_variable.signal
                end
              end
            else
              invocation.call
            end

            if event.interval_identifier # invoke again in the future
              event.invoke_at = Time.now + event.interval_period
              events_to_enqueue << event
            end
          end
        end

        if !events_to_enqueue.empty?
          sleep(0.1) # so we don't use all the CPU, let's sleep a little before we continue our event thread
          events_to_enqueue.each { |e| queue << e }
        end
      end
    end
  end
end
