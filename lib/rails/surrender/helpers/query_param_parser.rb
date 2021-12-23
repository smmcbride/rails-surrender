# frozen_string_literal: true

module Rails
  module Surrender
    # parse the requests query_params for surrender's controls and validate the formatting
    class QueryParamParser
      attr_reader :query_params

      COUNT_PARAM = :count
      EXCLUDE_PARAM = :exclude
      FILTER_PARAM = :filter
      IDS_PARAM = :ids
      INCLUDE_PARAM = :include
      SORT_PARAM = :sort
      PAGE_PARAM :page
      PER_PARAM :per

      PER_PAGE_DEFAULT = 50
      PAGE_DEFAULT = 1

      Sort = Struct.new(:request, :direction, :association, :attribute, :scope_method, keyword_init: true)
      Pagination = Struct.new(:page, :per, keyword_init: true)

      def initialize(query_params)
        @query_params = query_params
      end

      def include
        @include ||= parse_yml(query_params[INCLUDE_PARAM], :include)
      end

      def exclude
        @exclude ||= parse_yml(query_params[EXCLUDE_PARAM], :exclude)
      end

      def sort?
        query_params.key? SORT_PARAM
      end

      def sort
        @sort ||= begin
          sort = query_params[SORT_PARAM]

          direction_flag = ['+', '-'].include?(sort[0, 1]) ? sort.slice!(0) : '+'
          direction = direction_flag == '-' ? 'DESC' : 'ASC'

          scope_method = "sort_by_#{sort}".gsub('.', '_').to_sym
          association, attribute = sort_attributes(sort)

          Sort.new(request: query_params[SORT_PARAM], direction: direction, attribute: attribute,
                   association: association, scope_method: scope_method)
        end
      end

      def filter?
        filter_map.present?
      end

      def filter_map
        @filter_map ||= parse_yml(query_params[FILTER_PARAM], :filter)
      end

      def ids?
        query_params.key?(IDS_PARAM)
      end

      def count?
        query_params.key?(COUNT_PARAM)
      end

      def paginate?
        query_params.key? PAGE_PARAM
      end

      def pagination
        @pagination ||= Pagination.new(
          page: query_params[PAGE_PARAM]&.to_i || PAGE_DEFAULT,
          per: query_params[PER_PARAM]&.to_i || PER_PAGE_DEFAULT
        )
      end

      private

      def sort_attributes(sort)
        return sort.split('.') if sort.include? '.'

        [nil, sort]
      end

      def parse_yml(query_string, action)
        query_string ||= '' # empty string in case nil is passed
        Psych.safe_load("[#{query_string.gsub(/(,|:)/, '\1 ')}]")
      rescue StandardError
        raise Error, I18n.t('surrender.error.query_string.incorrect_format', params: { a: action })
      end
    end
  end
end
