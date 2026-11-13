# frozen_string_literal: true

require_relative 'filter'

module Rails
  module Surrender
    # The filters, sorts and page size a request may use to pick a model's records. They apply only at the top of a
    # response, to a relation; nothing filters or sorts the records inside an expand.
    class SelectionMenu
      def initialize(model)
        @model = model
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
    end
  end
end
