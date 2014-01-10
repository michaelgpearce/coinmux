class Coinmux::Fake::Application
  class Invocation < Hashie::Dash
    property :block
    property :time
    property :interval
    property :seconds
    property :interval_identifier

    def <=>(other)
      self.time <=> other.time
    end
  end

  attr_reader :invocations

  def initialize
    @invocations = []
    @current_time = 0
  end

  def invoke(&block)
    yield

    while next_invocation
      invocation.block.call

      if invocation.interval_identifier
        add_invocation(invocation.seconds, invocation.block, invocation.interval_identifier)
      end
    end
  end

  def sync_exec(&block)
    yield
  end
  
  def future_exec(seconds = 0, &block)
    add_invocation(seconds, block)
  end
  
  def interval_exec(seconds, &block)
    interval_identifier = rand.to_s
    add_invocation(seconds, block, interval_identifier)

    interval_identifier
  end
  
  def clear_interval(interval_id)
    invocations.delete_if do |invocation|
      invocation.interval_identifier == interval_id
    end
  end

  private

  def next_invocation
    invocation = invocations.shift
    @current_time = invocation.time

    invocation
  end

  def add_invocation(seconds, block, interval_identifier = nil)
    invocation = Invocation.new(:seconds => seconds, :time => @current_time + seconds, :block => block, :interval_identifier => interval_identifier)
    invocations << invocation
    invocations.sort!

    invocation
  end
end