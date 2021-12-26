# frozen_string_literal: true

module Rails
  module Surrender
    module Render
      class Ids
        attr_reader :resource

        def initialize(resource)
          @resource = resource
        end

        def parse
          ids = resource.respond_to?(:ids) ? resource.ids : [resource.id]
          Response.new(data: { ids: ids })
        end
      end
    end
  end
end
