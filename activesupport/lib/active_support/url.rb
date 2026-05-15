require "uri"

module ActiveSupport; end unless defined?(ActiveSupport)

module ActiveSupport::URL

  autoload :QueryParser, 'active_support/url/query_parser'
  autoload :QueryToken, 'active_support/url/query_token'
  autoload :Uri, 'active_support/url/uri'
  autoload :Utils, 'active_support/url/utils'

  ESSENTIAL_PARTS =  [
    :anchor, :protocol, :query_string,
    :path, :host, :port, :username, :password,
  ]

  COMBINED_PARTS = [
    :hostinfo, :userinfo, :authority, :ssl, :domain, :domainname,
    :domainzone, :request, :location, :endpoint, :query, :query_tokens,
    :directory, :extension, :file, :filename
  ]

  PARTS = ESSENTIAL_PARTS + COMBINED_PARTS

  ALIASES = {
    protocol: [:schema, :scheme],
    anchor: [:fragment],
    host: [:hostname],
    username: [:user],
    request: [:request_uri]
  }

  DELEGATES = [:port!, :host!, :path!, :home_page?, :https?]

  PROTOCOLS = {
    "http" => {port: 80, ssl: false},
    "https" => {port: 443, ssl: true},
    "ftp" => {port: 21},
    "tftp" => {port: 69},
    "sftp" => {port: 22},
    "ssh" => {port: 22, ssl: true},
    "svn" => {port: 3690},
    "svn+ssh" => {port: 22, ssl: true},
    "telnet" => {port: 23},
    "nntp" => {port: 119},
    "gopher" => {port: 70},
    "wais" => {port: 210},
    "ldap" => {port: 389},
    "prospero" => {port: 1525},
    "file" => {port: nil},
    "postgres" => {port: 5432},
    "mysql" => {port: 3306},
    "mailto" => {port: nil}
  }


  SSL_MAPPING = {
    'http' => 'https',
    'ftp' => 'sftp',
    'svn' => 'svn+ssh',
  }

  WEB_PROTOCOL = ['http', 'https']

  ROOT = '/'

  # Parses a URI string and returns an ActiveSupport::URL::Uri object.
  #
  # The optional +parts+ hash is merged into the parsed result.
  #
  # The +priority+ keyword controls how a protocol-less string is interpreted
  # when the first segment contains no slash:
  #
  # * +:host+ (default) — treats the segment before the first +/+ as the host:
  #
  #     ActiveSupport::URL.parse("gusiev.com/articles")
  #     # host: "gusiev.com", path: "/articles"
  #
  # * +:path+ — treats the entire string as a path:
  #
  #     ActiveSupport::URL.parse("gusiev.com/articles", priority: :path)
  #     # host: nil, path: "/gusiev.com/articles"
  #
  # URLs with an explicit protocol are unaffected by +priority+.
  def self.parse(argument, parts: nil, priority: :host)
    Uri.new(argument, priority: priority).update(parts)
  end

  # Builds a URL string from a hash of +parts+.
  #
  #   ActiveSupport::URL.build(path: "/dashboard", host: 'example.com', protocol: "https")
  #     # => "https://example.com/dashboard"
  def self.build(argument)
    Uri.new(argument).to_s
  end

  class << self
    (PARTS + ALIASES.values.flatten + DELEGATES - [:query_tokens]).each do |part|
      define_method(part) do |string|
        Uri.new(string)[part]
      end
    end
  end

  # Returns +string+ with the given +parts+ merged in.
  #
  #   ActiveSupport::URL.update("http://gusiev.com", protocol: 'https', subdomain: 'www')
  #     # => "https://www.gusiev.com"
  def self.update(string, parts)
    parse(string).update(parts).to_s
  end
  class << self
    alias :merge :update
  end

  # Returns +string+ with +parts+ applied only for keys not already set.
  #
  #   ActiveSupport::URL.defaults("gusiev.com/hello.html", protocol: 'http', path: '/index.html')
  #     # => "http://gusiev.com/hello.html"
  def self.defaults(string, parts)
    parse(string).defaults(parts).to_s
  end

  # Like #update, but replaces query parameters instead of merging them.
  #
  #   ActiveSupport::URL.update("/hello.html?a=1", host: 'gusiev.com', query: {b: 2})
  #     # => "gusiev.com/hello.html?a=1&b=2"
  #
  def self.replace(string, parts)
    parse(string).replace(parts).to_s
  end



  # Parses a query string into a nested parameters hash using the Rack
  # square-bracket convention.
  #
  #   ActiveSupport::URL.parse_query("a[]=1&a[]=2")         # => {"a" => ["1", "2"]}
  #   ActiveSupport::URL.parse_query("p[email]=a&p[two]=2") # => {"p" => {"email" => "a", "two" => "2"}}
  #   ActiveSupport::URL.parse_query("p[one]=1&a[two]=2")   # => {"p" => {"one" => "1"}, "a" => {"two" => "2"}}
  def self.parse_query(query)
    QueryParser.new.parse(query)
  end

  # Parses query key/value pairs from a query string and returns them raw,
  # without organizing them into hashes or normalizing values.
  #
  #   ActiveSupport::URL.query_tokens("a=1&b=2").map {|k,v| "#{k} -> #{v}"}  # => ['a -> 1', 'b -> 2']
  #   ActiveSupport::URL.query_tokens("a=1&a=1&a=2").map {|k,v| "#{k} -> #{v}"}  # => ['a -> 1', 'a -> 1', 'a -> 2']
  #   ActiveSupport::URL.query_tokens("name=Bogdan&email=bogdan%40example.com") # => [name=Bogdan, email=bogdan@example.com]
  #   ActiveSupport::URL.query_tokens("a[one]=1&a[two]=2") # => [a[one]=1, a[two]=2]
  def self.query_tokens(query)
    case query
    when Enumerable, Enumerator
      query.map do |token|
        QueryToken.parse(token)
      end
    when nil, ''
      []
    when String
      query.gsub(/\A\?/, '').split(/[&;] */n, -1).map do |p|
        QueryToken.parse(p)
      end
    else
      raise QueryParseError, "can not parse #{query.inspect} query tokens"
    end
  end

  # Serializes query parameters into a query string.
  # Optionally accepts a +namespace+ to nest all keys under.
  #
  #   ActiveSupport::URL.serialize({a: 1, b: 2}) # => "a=1&b=2"
  #   ActiveSupport::URL.serialize({a: [1,2]}) # => "a[]=1&a[]=2"
  #   ActiveSupport::URL.serialize({a: {b: 1, c:2}}) # => "a[b]=1&a[c]=2"
  #   ActiveSupport::URL.serialize({name: 'Bogdan', email: 'bogdan@example.com'}, namespace: "person")
  #     # => "person[name]=Bogdan&person[email]=bogdan%40example.com"
  #
  def self.serialize(query, namespace: nil, sorted: false, as_hash: nil)
    serialize_tokens(query, namespace: namespace, sorted: sorted, as_hash: as_hash).join("&")
  end

  def self.join(*uris)
    uris.map do |uri|
      ActiveSupport::URL.parse(uri)
    end.reduce do |memo, uri|
      memo.send(:join, uri)
    end
  end

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

  protected

  def self.serialize_tokens(query, namespace: nil, sorted: false, as_hash: nil)
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
          serialize_tokens(value, namespace: namespace ? "#{namespace}[#{key_param}]" : key_param, sorted: sorted, as_hash: as_hash)
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
        serialize_tokens(item, namespace: namespace, sorted: sorted, as_hash: as_hash)
      end
    else
      if namespace
        QueryToken.new(namespace, query)
      else
        []
      end
    end
  end


end
