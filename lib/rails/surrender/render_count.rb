# frozen_string_literal: true

module Rails
  module Surrender
    class RenderCount
      def self.render(resource)
        count = resource.respond_to?(:count) ? resource.count : 1
        Response.new(data: { count: count})
      end
    end
  end
end
