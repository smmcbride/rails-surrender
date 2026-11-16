# frozen_string_literal: true

module Rails
  module Surrender
    # What one endpoint accepts: its model's field menu shaped by the controller's include and exclude, and, for a
    # collection, its selection menu.
    class EndpointMenu
      def initialize(model, collection:, include: [], exclude: [], paginate: true)
        @fields = FieldMenu.new(model, asks: Fields::Asks.new(controller_include: include, controller_exclude: exclude))
        @selection = SelectionMenu.new(model, paginate: paginate) if collection
      end

      # A single record has no selection to make, so its selection is null.
      def as_json(*)
        { fields: @fields, selection: @selection }.as_json
      end
    end
  end
end
