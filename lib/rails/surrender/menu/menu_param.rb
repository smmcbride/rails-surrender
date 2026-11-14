# frozen_string_literal: true

module Rails
  module Surrender
    # The query param a request sends to ask for an endpoint menu, and whether the app answers it. While menus are
    # off the name is not reserved, so an app's own param of that name reaches it as usual.
    MenuParam = Data.define(:enabled, :name) do
      def initialize(enabled: false, name: 'menu')
        name = name.to_s
        raise ArgumentError, 'menu_param needs a name' if name.empty?
        raise ArgumentError, "menu_param can't be #{name.inspect}, which surrender already reads" if reserved?(name)

        super
      end

      def asked_in?(query_params)
        enabled && query_params.key?(name.to_sym)
      end

      private

      # A menu named after a param surrender already reads would hide it.
      def reserved?(name)
        %w[include exclude filter sort page per count].include?(name)
      end
    end
  end
end
