# frozen_string_literal: true

module Rails
  module Surrender
    # Generate a Response object from the given data
    class Response
      attr_accessor :data

      def initialize(data:)
        @data = data
      end

      def json_data
        ::Oj.dump(data, mode: :compat)
      end
    end
  end
end
