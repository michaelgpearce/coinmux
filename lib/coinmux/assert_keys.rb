class Hash
  def assert_keys!(options)
    required = options[:required] || []
    required = [required] unless required.is_a?(Array)
    optional = options[:optional] || []
    optional = [optional] unless optional.is_a?(Array)

    unknown = keys - (required + optional)
    raise "Unknown keys: #{unknown.join(', ')}" unless unknown.empty?

    missing = required - keys
    raise "Required keys missing: #{missing.join(', ')}" unless missing.empty?
  end
end
