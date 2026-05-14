# frozen_string_literal: true

# :markup: markdown

require "furi"

module ActionDispatch
  module Http
    module FilterRedirect
      FILTERED = "[FILTERED]" # :nodoc:

      def filtered_location # :nodoc:
        if location_filter_match?
          FILTERED
        else
          parameter_filtered_location
        end
      end

    private
      def location_filters
        if request
          request.get_header("action_dispatch.redirect_filter") || []
        else
          []
        end
      end

      def location_filter_match?
        location_filters.any? do |filter|
          if String === filter
            location.include?(filter)
          elsif Regexp === filter
            location.match?(filter)
          end
        end
      end

      def parameter_filtered_location
        uri = Furi.parse(location)
        return FILTERED unless uri.rfc3986?
        filter = request.parameter_filter
        uri.to_s(escape_query_param: ->(name, value) {
          filtered = filter.filter(name => value).first.last
          "#{CGI.escape(name)}=#{filtered}" unless filtered.equal?(value)
        })
      rescue Furi::Error
        FILTERED
      end
    end
  end
end
