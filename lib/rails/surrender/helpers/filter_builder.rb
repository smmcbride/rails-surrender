# frozen_string_literal: true

module Rails
  module Surrender
    # apply filtering directives to the given resource, based on the given filter controls
    class FilterBuilder
      attr_reader :resource, :filter

      def initialize(resource:, filter:)
        @resource = resource
        @filter = filter
      end

      def build!
        return resource unless resource.is_a?(ActiveRecord::Relation)

        # prepend filter_by so that only filter_by scope methods are reachable.
        # make user_id and organization.id resolve to the same scope
        filter.each do |scope, term|
          # filter exists on model?
          return resource.send(filter_method(scope), term) if resource.respond_to?(filter_method(scope))

          # resolved it by appending _id?
          return resource.send(filter_method_id(scope), term) if resource.respond_to?(filter_method_id(scope))

          unless filter_permitted?(scope)
            raise Error, I18n.t('surrender.error.query_string.filter.not_available', params: { a: scope })
          end
        end

        resource
      end

      private

      def filter_permitted?(scope)
        self.class.permitted_filter_names.include?(scope.to_sym)
      end

      def filter_method_id(scope)
        "#{filter_method(scope)}_id".to_sym
      end

      def filter_method(scope)
        "filter_by_#{scope}".gsub('.', '_').to_sym
      end
    end
  end
end
