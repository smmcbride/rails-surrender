# frozen_string_literal: true

module Rails
  module Surrender
    module Render
      class Count
        attr_reader :resource

        def initialize(resource)
          @resource = resource
        end

        def parse
          count = resource.respond_to?(:count) ? resource.count : 1
          Response.new(data: { count: count })
        end
      end
    end
  end
end
