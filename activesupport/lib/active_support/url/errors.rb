module ActiveSupport::URL
  class Error < StandardError
  end

  class FormattingError < Error
  end

  class ParseError < Error
  end

  class QueryParseError < Error
  end

  class ParamError < ParseError
  end

  class ParameterTypeError < ParamError
  end

  class ParamsTooDeepError < ParamError
  end

  class InvalidParameterError < ParamError
  end
end
