# frozen_string_literal: true

module ActionDispatch
  class ParamBuilder
    def self.make_default(param_depth_limit)
      new param_depth_limit
    end

    attr_reader :param_depth_limit

    def initialize(param_depth_limit)
      @param_depth_limit = param_depth_limit
    end

    cattr_accessor :default
    self.default = make_default(100)

    class << self
      delegate :from_query_string, :from_pairs, :from_hash, to: :default

      def ignore_leading_brackets
        ActionDispatch.deprecator.warn <<~MSG
          ActionDispatch::ParamBuilder.ignore_leading_brackets is deprecated and have no effect and will be removed in Rails 8.2.
        MSG

        @ignore_leading_brackets
      end

      def ignore_leading_brackets=(value)
        ActionDispatch.deprecator.warn <<~MSG
          ActionDispatch::ParamBuilder.ignore_leading_brackets is deprecated and have no effect and will be removed in Rails 8.2.
        MSG

        @ignore_leading_brackets = value
      end
    end

    def from_query_string(qs, separator: nil, encoding_template: nil)
      ActiveSupport::URL::QueryParser.new(
        make_params: -> { ActiveSupport::HashWithIndifferentAccess.new },
        depth_limit: param_depth_limit,
        encoding_template: encoding_template,
        coerce_value: ->(v) { ActionDispatch::Http::UploadedFile.new(v) if Hash === v },
        deep_munge: ActionDispatch::Request::Utils.perform_deep_munge,
        separator: separator
      ).parse(qs)
    rescue ArgumentError => e
      raise InvalidParameterError, e.message, e.backtrace
    end

    def from_pairs(pairs, encoding_template: nil)
      ActiveSupport::URL::QueryParser.new(
        make_params: -> { ActiveSupport::HashWithIndifferentAccess.new },
        depth_limit: param_depth_limit,
        encoding_template: encoding_template,
        coerce_value: ->(v) { ActionDispatch::Http::UploadedFile.new(v) if Hash === v },
        deep_munge: ActionDispatch::Request::Utils.perform_deep_munge
      ).parse(pairs)
    rescue ArgumentError => e
      raise InvalidParameterError, e.message, e.backtrace
    end

    def from_hash(hash, encoding_template: nil)
      # Force encodings from encoding template
      hash = Request::Utils::CustomParamEncoder.encode_for_template(hash, encoding_template)

      # Assert valid encoding
      Request::Utils.check_param_encoding(hash)

      # Convert hashes to HWIA (or UploadedFile), and deep-munge nils
      # out of arrays
      hash = Request::Utils.normalize_encode_params(hash)

      hash
    end
  end
end
