module ActiveSupport
  class URL
    class QueryToken
      include Comparable

      SEPARATOR = "&"

      attr_reader :name, :value

      # Parses query key/value pairs from a query string and returns them raw,
      # without organizing them into hashes or normalizing values.
      #
      #   ActiveSupport::URL::QueryToken.tokenize("a=1&b=2").map {|k,v| "#{k} -> #{v}"}  # => ['a -> 1', 'b -> 2']
      #   ActiveSupport::URL::QueryToken.tokenize("a=1&a=1&a=2").map {|k,v| "#{k} -> #{v}"}  # => ['a -> 1', 'a -> 1', 'a -> 2']
      #   ActiveSupport::URL::QueryToken.tokenize("name=Bogdan&email=bogdan%40example.com") # => [name=Bogdan, email=bogdan@example.com]
      #   ActiveSupport::URL::QueryToken.tokenize("a[one]=1&a[two]=2") # => [a[one]=1, a[two]=2]
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
              tokenize(
                value,
                namespace: namespace ? "#{namespace}[#{key_param}]" : key_param,
                sorted: sorted,
                as_hash: as_hash,
              )
            end
          end
          result.flatten!
          result.compact!
          result
        when nil, ''
          namespace ? new(namespace, query) : []
        when String
          if namespace
            new(namespace, query)
          else
            raise FormattingError, "Can not tokenize a string without namespace"
          end
        when QueryToken
          namespace ? new("#{namespace}[#{query.name}]", query.value) : [query]
        when Enumerable, Enumerator
          if namespace
            ns = "#{namespace}[]"
            query.map do |item|
              raise FormattingError, "Can not serialize #{item.inspect} as element of an Array" if item.is_a?(Array)
              tokenize(item, namespace: ns, sorted: sorted, as_hash: as_hash)
            end
          else
            query.map { |token| parse_one(token) }
          end
        else
          namespace ? new(namespace, query) : raise(QueryParseError, "can not tokenize #{query.inspect}")
        end
      end

      def self.parse(value, separator: nil)
        return [] if value.nil?
        if value.is_a?(String)
          value = value.delete_prefix("?").split(separator || SEPARATOR, -1)
        end
        value.map do |p|
          parse_one(p)
        end
      end


      # Note this departs from WHATWG's specified parsing algorithm by
      # giving a nil value for keys that do not use '='. Callers that need
      # the standard's interpretation can use `v.to_s`.
      def self.parse_one(value)
        case value
        when QueryToken
          value
        when String
          key, value = value.split('=', 2).map do |s|
            ::URI.decode_www_form_component(s)
          end
          key ||= ""
          new(key, value)
        when Array
          QueryToken.new(*value)
        else
          raise QueryParseError, "Can not parse query token #{value.inspect}"
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
        keys = key <=> other.key
        keys == 0 ? value <=> other.value : keys
      end

      def ==(other)
        other = self.class.parse_one(other)
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
end
