class Cli::Event
  attr_accessor :callback, :invoke_at, :interval_period, :interval_identifier, :mutex, :condition_variable

  def initialize(attrs = {})
    attrs.each { |k, v| send("#{k}=", v) }
  end
end

