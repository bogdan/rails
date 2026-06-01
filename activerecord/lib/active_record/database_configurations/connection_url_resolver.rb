# frozen_string_literal: true

require "active_support/url"
require "active_support/core_ext/enumerable"
require "active_support/core_ext/hash/reverse_merge"

module ActiveRecord
  class DatabaseConfigurations
    # Expands a connection string into a hash.
    class ConnectionUrlResolver # :nodoc:
      # == Example
      #
      #   url = "postgresql://foo:bar@localhost:9000/foo_test?pool=5&timeout=3000"
      #   ConnectionUrlResolver.new(url).to_hash
      #   # => {
      #     adapter:  "postgresql",
      #     host:     "localhost",
      #     port:     9000,
      #     database: "foo_test",
      #     username: "foo",
      #     password: "bar",
      #     pool:     "5",
      #     timeout:  "3000"
      #   }
      def initialize(url)
        raise "Database URL cannot be empty" if url.blank?
        @url = ActiveSupport::URL.parse(url)
        @adapter = resolved_adapter
      end

      # Converts the given URL to a full connection hash.
      def to_hash
        raw_config.compact_blank
      end

      private
        def query_hash
          @url.query.symbolize_keys
        end

        def raw_config
          if @url.opaque?
            query_hash.merge(
              adapter: @adapter,
              database: unescape(@url.opaque)
            )
          elsif bare_database_name?
            { database: @url.hostname }
          else
            query_hash.reverse_merge(
              adapter: @adapter,
              username: @url.username,
              password: @url.password,
              port: @url.port,
              database: database_from_path,
              host: @url.hostname
            )
          end
        end

        def bare_database_name?
          @url.protocol.nil? && @url.path.nil?
        end

        def resolved_adapter
          adapter = @url.protocol&.tr("-", "_")
          if adapter && ActiveRecord.protocol_adapters[adapter]
            adapter = ActiveRecord.protocol_adapters[adapter]
          end
          adapter
        end

        # Returns name of the database.
        def database_from_path
          if @adapter == "sqlite3"
            # 'sqlite3:/foo' is absolute, because that makes sense. The
            # corresponding relative version, 'sqlite3:foo', is handled
            # elsewhere, as an "opaque".

            unescape(@url.path)
          else
            # Only SQLite uses a filename as the "database" name; for
            # anything else, a leading slash would be silly.

            unescape(@url.path&.delete_prefix("/"))
          end
        end

        def unescape(string)
          return string unless string.is_a?(String)
          ::URI::RFC2396_PARSER.unescape(string)
        end
    end
  end
end
