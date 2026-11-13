# frozen_string_literal: true

module Rails
  module Surrender
    class Selection
      # The records a selection picked, and the headers that describe how.
      class Selected
        attr_reader :records

        # `unpaged` holds the records before paging, which a count response counts. `sort` is the sort as requested,
        # and `per` the page size used, each nil when that step didn't apply.
        def initialize(records:, unpaged: records, sort: nil, per: nil)
          @records = records
          @unpaged = unpaged
          @sort = sort
          @per = per
        end

        # A single record, or anything else that can't count itself, counts as one.
        def count
          @unpaged.respond_to?(:count) ? @unpaged.count : 1
        end

        def headers
          headers = {}
          headers['X-Sort'] = @sort if @sort
          headers['X-Pagination'] = pagination.to_json if @per
          headers
        end

        private

        # The size of the page follows from the total, so it doesn't need a query of its own.
        def pagination
          total = records.total_count
          {
            total: total,
            page_total: (total - records.offset_value).clamp(0, records.limit_value),
            page: records.current_page,
            previous_page: records.prev_page,
            next_page: records.next_page,
            last_page: records.total_pages,
            per_page: @per,
            offset: records.offset_value
          }
        end
      end
    end
  end
end
