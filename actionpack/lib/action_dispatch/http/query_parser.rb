# frozen_string_literal: true

require "active_support/url"

module ActionDispatch
  class QueryParser
    def self.strict_query_string_separator
      ActionDispatch.deprecator.warn <<~MSG
        The `strict_query_string_separator` configuration is deprecated have no effect and will be removed in Rails 8.2.
      MSG
      @strict_query_string_separator
    end

    def self.strict_query_string_separator=(value)
      ActionDispatch.deprecator.warn <<~MSG
        The `strict_query_string_separator` configuration is deprecated have no effect and will be removed in Rails 8.2.
      MSG
      @strict_query_string_separator = value
    end

    def self.each_pair(s, separator = nil)
      return enum_for(:each_pair, s, separator) unless block_given?
      sep = separator && separator.length > 1 ? /[#{Regexp.escape(separator)}]/n : separator
      ActiveSupport::URL::QueryToken.parse(s, separator: sep).each do |token|
        yield token.name, token.value
      end
      nil
    end
  end
end
