# frozen_string_literal: true

module Rails
  module Surrender
    # What one endpoint accepts: its model's field menu shaped by the controller's include and exclude, and, for a
    # relation, its selection menu. Rendered instead of the records when a request asks for it.
    class EndpointMenu
      def initialize(resource, include: [], exclude: [], paginate: true)
        model = resource.try(:klass) || (resource.class if resource.is_a?(ActiveRecord::Base))
        @fields = model && FieldMenu.new(model, asks: Fields::Asks.new(controller_include: include,
                                                                       controller_exclude: exclude))
        @selection = SelectionMenu.new(model, paginate: paginate) if resource.is_a?(ActiveRecord::Relation)
      end

      # Nil, hashes and arrays render as given, so no ask applies to them and both parts are null.
      def as_json(*)
        { fields: @fields, selection: @selection }.as_json
      end
    end
  end
end
