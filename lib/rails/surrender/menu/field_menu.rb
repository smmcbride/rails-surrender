# frozen_string_literal: true

require_relative 'field'

module Rails
  module Surrender
    # The fields a request may ask one model for: its default and available fields, nested by expand. It applies
    # wherever the model renders, at the top or inside an expand.
    class FieldMenu
      # `above` holds the base class of every model from the top of the menu down to this one.
      def initialize(model, above: [model.base_class])
        @model = model
        @above = above
      end

      # In the order fields render, with defaults before available fields within each kind. Expands back into a model
      # above are left out, as they never render.
      def fields
        @fields ||= offered_fields.map do |field|
          Field.new(name: field.name, kind: field.kind, default: default?(field), menu: field.menu(above: @above))
        end
      end

      private

      def offered_fields
        (@model.surrender_fields + @model.surrender_available_fields)
          .uniq
          .map { |name| @model.surrender_field(name) }
          .reject { |field| field.circular?(@above) }
          .each_with_index
          .sort_by { |field, position| [field.rank, default?(field) ? 0 : 1, position] }
          .map(&:first)
      end

      def default?(field)
        @model.surrender_fields.include?(field.name)
      end
    end
  end
end
