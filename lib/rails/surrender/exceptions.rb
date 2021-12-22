module Rails
  module Surrender
    class Error < StandardError
      attr_reader :status, :message, :key

      def initialize(*args)
        args = if args.first.is_a? Hash
            args.first
          else
            args.each_with_index.collect { |arg, i| [('a'..'z').to_a[i].to_sym, arg] }.to_h
          end

        @status = args[:status] || 400
        @key = args[:key]
        # prioritize passed message over key translation
        @message = if args.key? :message
                     args[:message]
                   elsif(args.key? :key )
                     I18n.t args[:key], **args[:params]
                     else
                       nil
                   end
      end
    end
  end
end
