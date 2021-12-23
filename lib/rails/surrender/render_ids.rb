# frozen_string_literal: true

module Rails
  module Surrender
    class RenderIds
      def self.render(resource)
        ids = resource.respond_to?(:ids) ? resource.ids : [resource.id]
        Response.new(data: { ids: ids })
      end
    end
  end
end
