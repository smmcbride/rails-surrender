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

        filter.each do |term|
          scope, value = term.first

          # filter exists on model?
          @resource = @resource.send(filter_method(scope), value) if resource.respond_to?(filter_method(scope))

            # resolved it by appending _id?
          @resource = @resource.send(filter_method_id(scope), value) if resource.respond_to?(filter_method_id(scope))
        end

        # TODO: Why amd I having to use the instance variable here?
        resource
      end

      private

      # prepend filter_by so that only filter_by scope methods are reachable.
      def filter_method(scope)
        "filter_by_#{scope}".gsub('.', '_').to_sym
      end

      def filter_method_id(scope)
        "#{filter_method(scope)}_id".to_sym
      end

    end
  end
end
