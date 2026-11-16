# frozen_string_literal: true

module Rails
  module Surrender
    # The endpoint menu of every GET route in the app whose action surrenders a model, served at the menu path. It is
    # worked out from the routes and what controllers declare, without running any action.
    class AppMenu
      def initialize(routes)
        @routes = routes
      end

      # In the order the app draws its routes. Rails answers a path with the first route that matches it, so a later
      # route with the same path is left out.
      def endpoints
        @routes.filter_map { |route| Endpoint.from_route(route) }.uniq(&:path)
      end

      def as_json(*)
        { endpoints: endpoints }.as_json
      end
    end
  end
end
