# frozen_string_literal: true

module Rails
  module Surrender
    # What a controller declares one action surrenders with, through `surrender_options`. `surrender` applies the
    # include, exclude and paginate when the action runs. The app menu reads them all, as it can't run the action to
    # see what it surrenders. `model` and `collection` are nil unless declared, and the app menu then infers them from
    # the route.
    ActionOptions = Data.define(:include, :exclude, :paginate, :model, :collection, :menu)

    # Reopened rather than defined in Data.define's block, so its constant belongs to it.
    class ActionOptions
      DEFAULTS = { include: [], exclude: [], paginate: true, model: nil, collection: nil, menu: true }.freeze

      # An option it doesn't know is refused by Data, as an unknown keyword.
      def initialize(**options)
        options = DEFAULTS.merge(options)
        super(**options, include: Array(options[:include]), exclude: Array(options[:exclude]))
      end

      # With the include and exclude an action passes to `surrender` added to those it declares.
      def adding(include: [], exclude: [])
        with(include: self.include + Array(include), exclude: self.exclude + Array(exclude))
      end

      # What the action accepts, filling in what it doesn't declare with what its controller and route suggest. Nil when
      # the action is left off the menu, or surrenders no model.
      def endpoint_menu(model:, collection:)
        model = self.model || model
        return unless menu && model

        EndpointMenu.new(model, collection: self.collection.nil? ? collection : self.collection,
                                include: include, exclude: exclude, paginate: paginate)
      end
    end
  end
end
