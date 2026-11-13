# frozen_string_literal: true

require_relative 'field'
require_relative 'filter'

module Rails
  module Surrender
    # Everything a request may ask of one model: its default and available fields, nested by expand, its filters and
    # sorts, and the size of its pages. It is read from the same rules that check requests, so it lists exactly what a
    # request may ask.
    class Menu
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

      def filters
        @model.surrender_filter_columns.map { |name, column| Filter.new(name: name, column: column) }
      end

      def sorts
        @model.surrender_sort_names
      end

      def page_size
        Surrender.page_size
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
