# frozen_string_literal: true

require_relative 'helpers/query_param_parser'
require_relative 'helpers/filter_builder'
require_relative 'helpers/pagination_builder'
require_relative 'helpers/sort_builder'

module Rails
  module Surrender
    # Additions to the Rails ActionController to allow surrender's rendering.
    module ControllerAdditions
      def initialize(*args)
        @will_paginate = true
        super
      end

      def surrender(resource, status: 200, reload: true, include: [], exclude: [])
        resource = filter resource if parsed_query_params.filter?

        if parsed_query_params.sort?
          resource = sort resource
          response.headers['X-Sort'] = parsed_query_params.sort.request
        end

        if paginate?
          resource = paginate resource
          response.headers['X-Pagination'] = pagination_headers(resource)
        end

        surrender_response = if parsed_query_params.count?
                               Render::Count.new(resource).parse
                             elsif parsed_query_params.ids?
                               Render::Ids.new(resource).parse
                             else

                               control = Render::Controller.new(
                                 reload_resource: reload,
                                 user_exclude: parsed_query_params.exclude,
                                 user_include: parsed_query_params.include,
                                 ctrl_exclude: exclude,
                                 ctrl_include: include
                               )

                               Render::Resource.render(resource: resource,
                                                       current_ability: current_ability,
                                                       render_control: control)
                             end

        # Allows the calling method to decorate the response data before returning the result
        surrender_response.data = yield surrender_response.data if block_given?

        render(json: surrender_response.json_data, status: status)
      end

      private

      def skip_pagination
        @will_paginate = false
      end

      def filter(resource)
        FilterBuilder.new(resource: resource, filter: parsed_query_params.filter).build!
      end

      def paginate?
        @will_paginate || parsed_query_params.paginate?
      end

      def paginate(resource)
        PaginationBuilder.new(resource: resource, pagination: parsed_query_params.pagination).build!
      end

      def pagination_headers(resource)
        {
          total: resource.total_count,
          page_total: resource.count,
          page: resource.current_page,
          previous_page: resource.prev_page,
          next_page: resource.next_page,
          last_page: resource.total_pages,
          per_page: parsed_query_params.pagination.per,
          offset: resource.offset_value
        }.to_json
      end

      def sort(resource)
        SortBuilder.new(resource: resource, sort: parsed_query_params.sort).build!
      end

      def parsed_query_params
        @parsed_query_params ||= QueryParamParser.new(request.query_parameters.symbolize_keys)
      end
    end
  end
end
