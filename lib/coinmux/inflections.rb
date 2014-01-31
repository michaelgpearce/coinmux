class String
  def humanize
    gsub(/_/, ' ')
  end

  def classify
    singularize.gsub(/_/, ' ').split(' ').collect(&:capitalize).join
  end

  def singularize
    if match /uses$/
      self[0...-2]
    elsif match /es$/
      self[0...-1]
    elsif match /[^us]s$/
      self[0...-1]
    else
      self
    end
  end
end