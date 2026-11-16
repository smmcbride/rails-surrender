# frozen_string_literal: true

module Rails
  module Surrender
    # Additions to the Rails ActionController to allow surrender's rendering.
    module ControllerAdditions
      def initialize(*args)
        @will_paginate = true
        super
      end

      def surrender(resource, status: 200, include: [], exclude: [], &)
        # Before the selection, which would parse and check the other asks a menu ignores.
        if Surrender.menu_param.asked_in?(query_params)
          render_endpoint_menu(resource, include: include, exclude: exclude)
        else
          render_selected(resource, status: status, include: include, exclude: exclude, &)
        end
      end

      private

      def render_selected(resource, status:, include:, exclude:)
        selection = Selection.new(query_params, paginate: @will_paginate)
        selected = selection.apply(resource)
        response.headers.merge!(selected.headers)

        surrender_response = if selection.count?
                               Response.new(data: { count: selected.count })
                             else
                               asks = { include: query_params[:include], exclude: query_params[:exclude],
                                        controller_include: include, controller_exclude: exclude }
                               Render::Resource.new(resource: selected.records, ability: ability, asks: asks).parse
                             end

        # Allows the calling method to decorate the response data before returning the result
        surrender_response.data = yield surrender_response.data if block_given?

        render(json: surrender_response.json_data, status: status)
      end

      # Never decorated by the block, so every endpoint's menu has the same shape.
      def render_endpoint_menu(resource, include:, exclude:)
        menu = EndpointMenu.new(resource, include: include, exclude: exclude, paginate: @will_paginate)
        render(json: Response.new(data: menu.as_json).json_data)
      end

      def ability
        # Apps commonly override CanCanCan's current_ability as a private method.
        return current_ability if respond_to?(:current_ability, true)

        DefaultAbility.new
      end

      def skip_pagination
        @will_paginate = false
      end

      def query_params
        request.query_parameters.symbolize_keys
      end
    end
  end
end
