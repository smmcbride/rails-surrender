# frozen_string_literal: true

require_relative '../params/list_param'
require_relative 'page_size'
require_relative 'selected'

module Rails
  module Surrender
    # The records one request renders, picked from a relation by the request's filter, sort and page.
    class Selection
      PAGE_DEFAULT = 1

      # `query_params` are the request's. A controller that skips pagination passes `paginate: false`.
      def initialize(query_params, paginate: true, page_size: Surrender.page_size)
        @params = query_params.to_h.symbolize_keys
        @paginate = paginate
        @page_size = page_size
      end

      def count?
        @params.key?(:count)
      end

      # Only a relation can be filtered, sorted and paged; anything else is selected as it is.
      def apply(resource)
        return Selected.new(records: resource) unless resource.is_a?(ActiveRecord::Relation)

        selected = sorted(filtered(resource))
        return Selected.new(records: selected, sort: sort) unless paged?

        # Surrender's page size limit is the only one, so Kaminari's own limits mustn't shrink the page it reports.
        size = @page_size.for(positive_whole_number(:per))
        paged = selected.page(positive_whole_number(:page) || PAGE_DEFAULT).per(size, max_per_page: size)
        Selected.new(records: paged, unpaged: selected, sort: sort, per: size)
      end

      private

      def filtered(relation)
        Params::ListParam.parse(@params[:filter], param: :filter).reduce(relation) do |filtered, term|
          raise Error, I18n.t('surrender.error.query_string.incorrect_format', param: :filter) unless term.is_a?(Hash)

          term.reduce(filtered) { |narrowed, (name, value)| narrowed.surrender_filter(name, value) }
        end
      end

      def sorted(relation)
        sort ? relation.surrender_sort(sort) : relation
      end

      # A blank sort, as API explorers send for an empty field, means no sort rather than a sort on nothing.
      def sort
        @params[:sort].presence
      end

      # A count response counts the whole selection, so it is never paged.
      def paged?
        @paginate && !count?
      end

      def positive_whole_number(param)
        value = @params[param]
        return if value.nil?
        return value.to_i if value.to_s.match?(/\A[1-9]\d*\z/)

        raise Error, I18n.t('surrender.error.query_string.pagination.invalid', param: param, value: value)
      end
    end
  end
end
