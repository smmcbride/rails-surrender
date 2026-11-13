# frozen_string_literal: true

module Rails
  module Surrender
    class Selection
      # How many records one page holds: the size a request asks for, or the default when it asks for none, capped at
      # the limit. A nil limit leaves pages uncapped.
      PageSize = Data.define(:default, :max) do
        def initialize(default: 50, max: 100)
          check_positive_whole_number('default_per_page', default)
          check_positive_whole_number('max_per_page', max) unless max.nil?
          raise ArgumentError, "default_per_page (#{default}) is larger than max_per_page (#{max})" if max&.<(default)

          super
        end

        def for(requested)
          return default if requested.nil?

          max ? [requested, max].min : requested
        end

        private

        def check_positive_whole_number(setting, value)
          return if value.is_a?(Integer) && value.positive?

          raise ArgumentError, "#{setting} needs a positive whole number, not #{value.inspect}"
        end
      end
    end
  end
end
