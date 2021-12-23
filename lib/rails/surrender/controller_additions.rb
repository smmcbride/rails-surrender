# frozen_string_literal: true

require_relative 'helpers/yaml_query_parser'

module Rails
  module Surrender
    module ControllerAdditions
      PER_PAGE_OPTIONS = [10, 50, 100].freeze
      PER_PAGE_DEFAULT = 50
      PAGE_DEFAULT     = 1

      COUNT_PARAM = :count
      EXCLUDE_PARAM = :exclude
      FILTER_PARAM = :filter
      IDS_PARAM = :ids
      INCLUDE_PARAM = :include
      SORT_PARAM = :sort

      def self.included(base)
        base.before_action :extract_surrender_parameters
        base.extend ClassMethods

      end

      # permits_filters allows a controller to define filters that can be used within that controller
      module ClassMethods
        def permits_filters *filter_names
          @permitted_filter_names = filter_names
        end

        def permitted_filter_names
          @permitted_filter_names ||= []
        end
      end

      def initialize(*args)
        @will_paginate = true
        super
      end

      def surrender(resource, status: 200)
        resource = filter resource if filter?
        resource = sort resource if sort?

        # Short circuit if count or ids are requested
        render_count(resource) and return if render_count?
        render_ids(resource) and return if render_ids?

        resource = paginate resource

        surrender_response = Render.render( resource,
                                            current_ability: current_ability,
                                            render_control: render_control
        )

        # Allows the calling method to decorate the response data before returning the result
        surrender_response.data = yield surrender_response.data if block_given?

        render(json: surrender_response.json_data, status: status)
      end

      private

      def render_control(opts)
        {
          reload_resource: (opts.key?(:reload_resource) ? opts[:reload_resource] : true),
          user_exclude: api_exclude,
          user_include: api_include,
          ctrl_exclude: (opts.key?(:exclude) ? opts[:exclude] : []),
          ctrl_include: (opts.key?(:include) ? opts[:include] : [])
        }
      end

      def render_count?
        query_params.key?(COUNT_PARAM)
      end

      def render_count(resource)
        count = resource.respond_to?(:count) ? resource.count : 1
        render(json: { count: count }, status: status)
      end

      def render_ids?
        query_params.key?(IDS_PARAM)
      end

      def render_ids(resource)
        ids = resource.respond_to?(:ids) ? resource.ids : [resource.id]
        render(json: ids, status: status)
      end

      def skip_pagination
        @will_paginate = false
      end

      def filter(resource)
        return resource unless resource.is_a?(ActiveRecord::Relation)

        # prepend filter_by so that only filter_by scope methods are reachable.
        # make user_id and organization.id resolve to the same scope
        raise 'need to redo filtering to use filter and not @filter_map'
        filter_map
        @filter_map.each do |scope, term|
          scope_filter_method = "filter_by_#{scope}".gsub('.', '_')
          scope_filter_method_id = scope_filter_method + '_id'
          if resource.respond_to?(scope_filter_method.to_sym) # filter exists on model?
            resource = resource.send(scope_filter_method, term)
          elsif resource.respond_to?(scope_filter_method_id.to_sym) # resolved it by appending _id?
            resource = resource.send(scope_filter_method_id, term)
          elsif !self.class.permitted_filter_names.include?(scope.to_sym) # controller wants this filter?
            raise Error, I18n.t('surrender.error.query_string.filter.not_available', params: { a: scope })
          end
        end
        resource
      end

      def paginate(resource)
        if (@will_paginate || @pagination_requested) && resource.respond_to?(:page)
          resource = resource.page(@page).per(@per)
          # Shove data in headers
          response.headers['X-Pagination'] = {
            total: resource.total_count,
            page_total: resource.count,
            page: resource.current_page,
            previous_page: resource.prev_page,
            next_page: resource.next_page,
            last_page: resource.total_pages,
            per_page: @per,
            offset: resource.offset_value
          }.to_json
        end
        resource
      end

      def sort(resource)
        return resource unless resource.is_a? ActiveRecord::Relation

        response.headers['X-Sort'] = @sort
        direction_flag = ['+', '-'].include?(@sort[0, 1]) ? @sort.slice!(0) : '+'
        sort_direction = direction_flag == '-' ? 'DESC' : 'ASC'
        scope_method = "sort_by_#{@sort}".gsub('.', '_').to_sym

        # prepare for nested sorting
        association = @sort.split('.')[0]
        attribute =   @sort.split('.')[1]

        if resource.klass.attribute_names.include?(@sort)
          # first-order attribute we can send to DB
          resource.order(@sort => sort_direction)
        elsif resource.respond_to?(scope_method)
          # a sort scope is available
          resource.send(scope_method, sort_direction)
        elsif resource.reflections.keys.include?(association) &&
              resource.reflect_on_association(association).klass.attribute_names.include?(attribute)
          # join a second order sort request
          table_name = resource.reflect_on_association(association).klass.table_name
          resource.joins(association.to_sym).order("#{table_name}.#{attribute} #{sort_direction}")
        else
          raise Error, I18n.t('surrender.error.query_string.sort.invalid_column', params: { a: @sort })
        end
      end

      def extract_surrender_parameters
        begin
          @pagination_requested = query_params.key?(:page)
          @page = query_params.delete(:page).try(:to_i) || 1
          @per = query_params.delete(:per) || PER_PAGE_DEFAULT
          @per = PER_PAGE_OPTIONS.include?(@per.to_i) ? @per.to_i : PER_PAGE_DEFAULT
        rescue
          raise Error, I18n.t('surrender.error.query_string.pagination.invalid')
        end
      end

      def sort?
        sort_param.present?
      end

      def sort_param
        YamlQueryParser.parse query_params[SORT_PARAM]
      end

      def filter?
        filter_map.present?
      end

      def filter_map
        YamlQueryParser.parse query_params[FILTER_PARAM]
      end

      def api_include
        YamlQueryParser.parse query_params[INCLUDE_PARAM]
      end

      def api_exclude
        YamlQueryParser.parse query_params[EXCLUDE_PARAM]
      end

      def query_params
        @query_params ||= request.query_parameters.symbolize_keys
      end
    end
  end
end
