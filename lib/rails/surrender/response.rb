module Rails
  module Surrender
    class Response
      attr_accessor :data

      def initialize(*args, &block)
        opts = args.extract_options!
        @data = opts[:data]
      end

      def json_data
        ::Oj.dump(data, mode: :compat)
      end
    end
  end
end
