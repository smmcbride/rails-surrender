# frozen_string_literal: true

module Rails
  module Surrender
    # apply pagination directives to the given resource, based on the given pagination controls
    class PaginationBuilder
      attr_reader :resource, :pagination

      def initialize(resource:, pagination:)
        @resource = resource
        @pagination = pagination
      end

      def build!
        return resource unless paginatable?

        resource.page(pagination.page).per(pagination.per)
      end

      def paginatable?
        resource.respond_to?(:page)
      end
    end
  end
end
