class Object

  TRUE_VALUES = [true, 1, '1', 't', 'T', 'true', 'TRUE', 'on', 'ON'].to_set
  FALSE_VALUES = [false, 0, '0', 'f', 'F', 'false', 'FALSE', 'off', 'OFF'].to_set

  def to_boolean(positive_check = true)
    positive_check ? TRUE_VALUES.include?(self) : !FALSE_VALUES.include?(self)
  end
end

class String
  def to_boolean(positive_check = true)
    self !~ /[^[:space:]]/ ? false : super(positive_check)
  end
end

class Numeric
  def to_boolean(positive_check = true)
    zero? ? false : super(positive_check)
  end
end
