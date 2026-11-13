# frozen_string_literal: true

require_relative 'filter'

module Rails
  module Surrender
    # The filters, sorts and page size a request may use to pick a model's records. They apply only at the top of a
    # response, to a relation; nothing filters or sorts the records inside an expand.
    class SelectionMenu
      def initialize(model, paginate: true)
        @model = model
        @paginate = paginate
      end

      def filters
        @model.surrender_filter_columns.map { |name, column| Filter.new(name: name, column: column) }
      end

      def sorts
        @model.surrender_sort_names
      end

      # Nil when the controller skips pagination, as its records then come in one piece.
      def page_size
        Surrender.page_size if @paginate
      end

      def as_json(*)
        { filters: filters.to_h { |filter| [filter.name, filter] }, sorts: sorts, page: page_size }.as_json
      end
    end
  end
end
