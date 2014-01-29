class Hash
  def assert_keys!(options)
    required = options[:required] || []
    required = [required] unless required.is_a?(Array)
    optional = options[:optional] || []
    optional = [optional] unless optional.is_a?(Array)

    assert_valid_keys(required + optional)

    missing = required - keys
    raise "Required keys missing: #{missing.join(', ')}" unless missing.empty?
  end
end
