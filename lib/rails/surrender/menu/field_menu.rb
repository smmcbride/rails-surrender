# frozen_string_literal: true

require_relative 'field'

module Rails
  module Surrender
    # The fields a request may ask one model for: its default and available fields, nested by expand. It applies
    # wherever the model renders, at the top or inside an expand. A controller's asks shape it as they shape rendering.
    class FieldMenu
      # `above` holds the base class of every model from the top of the menu down to this one.
      def initialize(model, asks: Fields::Asks.new, above: [model.base_class])
        @model = model
        @asks = asks
        @above = above
      end

      # In the order fields render, with defaults before available fields within each kind. Expands back into a model
      # above are left out, as they never render.
      def fields
        @fields ||= offered_fields.map do |field|
          Field.new(name: field.name, kind: field.kind, default: default?(field.name),
                    menu: field.menu(asks: @asks, above: @above))
        end
      end

      def as_json(*)
        fields.as_json
      end

      private

      # A field the controller includes renders by default even when the model doesn't offer it, but a request may
      # only include what the model offers, so a field the controller excludes stays on the menu only if it's offered.
      def offered_fields
        (@model.surrender_fields + @asks.controller_includes + @model.surrender_available_fields)
          .uniq
          .select { |name| on_menu?(name) }
          .map { |name| @model.surrender_field(name) }
          .reject { |field| field.circular?(@above) }
          .each_with_index
          .sort_by { |field, position| [field.rank, default?(field.name) ? 0 : 1, position] }
          .map(&:first)
      end

      def on_menu?(name)
        default?(name) || @model.surrenders?(name)
      end

      def default?(name)
        defaults.include?(name)
      end

      def defaults
        @defaults ||= (@model.surrender_fields + @asks.controller_includes).reject { |name| @asks.excludes?(name) }
      end
    end
  end
end
