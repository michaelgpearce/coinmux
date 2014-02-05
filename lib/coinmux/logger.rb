require 'logger'

class Coinmux::Logger
  include Singleton

  def debug(*messages)
    write_messages(:debug, messages)
  end

  def info(*messages)
    write_messages(:info, messages)
  end

  def warn(*messages)
    write_messages(:warn, messages)
  end

  def error(*messages)
    write_messages(:error, messages)
  end

  def fatal(*messages)
    write_messages(:fatal, messages)
  end

  def level=(level)
    @level = logger.level = level.is_a?(Fixnum) ? level : ::Logger.const_get(level.to_s.upcase)
  end

  def level
    @level
  end

  def logger
    return @logger if @logger

    path = Coinmux::FileUtil.root_mkdir_p('log')
    file = File.open(File.join(path, "coinmux-#{Coinmux.env}.log"), 'a')
    file.sync = true
    @logger = ::Logger.new(file, 1)
  end

  private

  def write_messages(method, messages)
    messages.each { |message| logger.send(method, message) }
    nil
  end
end