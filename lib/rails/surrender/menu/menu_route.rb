# frozen_string_literal: true

module Rails
  module Surrender
    # Where the app menu is served, and whether it is, from config.surrender.menus and menu_path.
    MenuRoute = Data.define(:enabled, :path) do
      def initialize(enabled: false, path: '/surrender_menu')
        path = path.to_s
        raise ArgumentError, "menu_path needs to start with /, not #{path.inspect}" unless path.start_with?('/')

        super
      end

      # Drawn unnamed, so it can't take a route name the app uses.
      def draw(mapper)
        mapper.get(path, to: 'rails/surrender/menus#show', as: nil) if enabled
      end
    end
  end
end
