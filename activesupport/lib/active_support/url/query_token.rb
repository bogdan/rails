module ActiveSupport::URL
  class QueryToken
    include Comparable

    attr_reader :name, :value

    def self.tokenize(query, namespace: nil, sorted: false, as_hash: nil)
      if as_hash && !query.is_a?(Hash) && !query.is_a?(Array)
        query = as_hash.call(query) || query
      end
      case query
      when Hash
        keys = query.keys
        keys.sort_by!(&:to_s) if sorted && !namespace.to_s.include?("[]")
        result = keys.map do |key|
          value = query[key]
          unless (value.is_a?(Hash) || value.is_a?(Array)) && value.empty?
            key_param = key.respond_to?(:to_param) ? key.to_param : key
            tokenize(value, namespace: namespace ? "#{namespace}[#{key_param}]" : key_param, sorted: sorted, as_hash: as_hash)
          end
        end
        result.flatten!
        result.compact!
        result
      when Array
        if namespace.nil? || namespace.empty?
          raise FormattingError, "Can not serialize Array without namespace"
        end
        namespace = "#{namespace}[]"
        query.map do |item|
          if item.is_a?(Array)
            raise FormattingError, "Can not serialize #{item.inspect} as element of an Array"
          end
          tokenize(item, namespace: namespace, sorted: sorted, as_hash: as_hash)
        end
      else
        namespace ? new(namespace, query) : []
      end
    end

    def self.parse(token)
      case token
      when QueryToken
        token
      when String
        key, value = token.split('=', 2).map do |s|
          ::URI.decode_www_form_component(s)
        end
        key ||= ""
        new(key, value)
      when Array
        QueryToken.new(*token)
      else
        raise QueryParseError, "Can not parse query token #{token.inspect}"
      end
    end

    def initialize(name, value)
      @name = name
      @value = value
    end

    def to_a
      [name, value]
    end

    def <=>(other)
      to_s <=> other.to_s
    end

    def ==(other)
      other = self.class.parse(other)
      return false unless other
      to_s == other.to_s
    end

    def to_s
      encoded_key = ::URI.encode_www_form_component(name.to_s)

      !value.nil? ?
        "#{encoded_key}=#{::URI.encode_www_form_component(value_to_param)}" :
        encoded_key
    end

    def as_json(options = nil)
      to_a
    end

    def inspect
      [name, value].join('=')
    end

    private

    def value_to_param
      (value.respond_to?(:to_param) ? value.to_param : value).to_s
    end
  end
end
