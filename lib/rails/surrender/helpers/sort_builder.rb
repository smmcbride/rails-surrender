# frozen_string_literal: true

module Rails
  module Surrender
    # apply sort directives to the given resource, based on the given sort controls
    class SortBuilder
      attr_reader :resource, :sort

      def initialize(resource:, sort:)
        @resource = resource
        @sort = sort
      end

      def build!
        return resource unless resource.is_a? ActiveRecord::Relation

        return resource_attribute_order if resource_has_attribute?

        return scope_method_order if resource_has_scope_method?

        return association_attribute_order if resource_has_association_with_attribute?

        raise Error, I18n.t('surrender.error.query_string.sort.invalid_column', param: sort.request)
      end

      private

      def resource_has_attribute?
        resource.klass.attribute_names.include?(sort.attribute)
      end

      def resource_attribute_order
        resource.order(sort.attribute => sort.direction)
      end

      def resource_has_scope_method?
        resource.respond_to?(sort.scope_method)
      end

      def scope_method_order
        resource.send(sort.scope_method, sort.direction)
      end

      def resource_has_association_with_attribute?
        resource.reflections.keys.include?(sort.association) &&
          resource.reflect_on_association(sort.association).klass.attribute_names.include?(sort.attribute)
      end

      def association_attribute_order
        table_name = resource.reflect_on_association(sort.association).klass.table_name
        resource.joins(sort.association.to_sym)
                .order("#{table_name}.#{sort.attribute} #{sort.direction}")
      end
    end
  end
end
