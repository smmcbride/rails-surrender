# frozen_string_literal: true

module Rails
  module Surrender
    # One GET route whose action surrenders a model, and the menu of what it accepts. The path names its segments as
    # `{id}`, the way API descriptions write them.
    Endpoint = Data.define(:path, :menu) do
      # Nil for a route whose action surrenders no model, as far as the route and its controller tell.
      def self.from_route(route)
        controller = controller_of(route)
        return unless route.verb == 'GET' && controller

        action = route.defaults[:action]
        menu = controller.surrender_options_for(action)
                         .endpoint_menu(model: controller.surrender_model, collection: collection?(route, action))
        new(path: path_of(route), menu: menu) if menu
      end

      # Only controllers that include surrender's additions can surrender. Redirects and mounted apps have none.
      def self.controller_of(route)
        return unless (name = route.defaults[:controller])

        controller = "#{name}_controller".camelize.safe_constantize
        controller if controller.respond_to?(:surrender_options_for)
      end

      # `index` lists records and `show` finds one. Any other action finds one when its path names an id, as a member
      # route's does, and lists records otherwise, as a collection route does.
      def self.collection?(route, action)
        return true if action == 'index'
        return false if action == 'show'

        route.required_parts.exclude?(:id)
      end

      def self.path_of(route)
        route.path.spec.to_s.delete_suffix('(.:format)').gsub(/:(\w+)/, '{\1}')
      end

      private_class_method :controller_of, :collection?, :path_of

      def as_json(*)
        { verb: 'GET', path: path }.merge(menu.as_json).as_json
      end
    end
  end
end
