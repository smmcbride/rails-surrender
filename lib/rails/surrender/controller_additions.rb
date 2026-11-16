# frozen_string_literal: true

module Rails
  module Surrender
    # Additions to the Rails ActionController to allow surrender's rendering.
    module ControllerAdditions
      def self.included(base)
        base.extend(ClassMethods)
        base.class_attribute :surrender_action_options, default: {}, instance_accessor: false
      end

      # What a controller's actions surrender, declared on the class so the app menu can read it without running them.
      module ClassMethods
        # Each action named takes these options, replacing any it was given before, here or in a superclass.
        def surrender_options(*actions, **)
          declared = ActionOptions.new(**)
          self.surrender_action_options = surrender_action_options.merge(actions.to_h { |name| [name.to_s, declared] })
        end

        def surrender_options_for(action)
          surrender_action_options.fetch(action.to_s) { ActionOptions.new }
        end

        # The model named like the controller, such as Book for BooksController, or nil when there's none.
        def surrender_model
          model = controller_name.classify.safe_constantize
          model if model.is_a?(Class) && model < ActiveRecord::Base && !model.abstract_class?
        end
      end

      def initialize(*args)
        @will_paginate = true
        super
      end

      # The include and exclude given here add to those the action declares with `surrender_options`, but only those
      # it declares are on the app menu.
      def surrender(resource, status: 200, include: [], exclude: [], &)
        options = self.class.surrender_options_for(action_name).adding(include: include, exclude: exclude)
        render_selected(resource, status: status, options: options, &)
      end

      private

      def render_selected(resource, status:, options:)
        selection = Selection.new(query_params, paginate: @will_paginate && options.paginate)
        selected = selection.apply(resource)
        response.headers.merge!(selected.headers)

        surrender_response = if selection.count?
                               Response.new(data: { count: selected.count })
                             else
                               Render::Resource.new(resource: selected.records, ability: ability, asks: asks(options))
                                               .parse
                             end

        # Allows the calling method to decorate the response data before returning the result
        surrender_response.data = yield surrender_response.data if block_given?

        render(json: surrender_response.json_data, status: status)
      end

      def asks(options)
        { include: query_params[:include], exclude: query_params[:exclude],
          controller_include: options.include, controller_exclude: options.exclude }
      end

      def ability
        # Apps commonly override CanCanCan's current_ability as a private method.
        return current_ability if respond_to?(:current_ability, true)

        DefaultAbility.new
      end

      # Unlike `surrender_options ..., paginate: false`, this is decided as the action runs, so the app menu can't see
      # it and still lists a page size.
      def skip_pagination
        @will_paginate = false
      end

      def query_params
        request.query_parameters.symbolize_keys
      end
    end
  end
end
