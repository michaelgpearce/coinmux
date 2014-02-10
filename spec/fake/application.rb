class Coinmux::Fake::Application
  class Invocation
    include Coinmux::Proper

    property :block, :time, :seconds

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
    end
  end

  def sync_exec(&block)
    yield
  end
  
  def future_exec(seconds = 0, &block)
    add_invocation(seconds, block)
  end
  
  private

  def next_invocation
    invocation = invocations.shift
    @current_time = invocation.time

    invocation
  end

  def add_invocation(seconds, block)
    invocation = Invocation.new(:seconds => seconds, :time => @current_time + seconds, :block => block)
    invocations << invocation
    invocations.sort!

    invocation
  end
end