# frozen_string_literal: true

module Rails
  module Surrender
    module Render
      # Renders what a controller surrenders. Records and relations render through a field tree; nil, hashes and
      # arrays have no model to shape them, so they render as given.
      class Resource
        attr_reader :resource, :ability, :asks

        # `asks` holds the keyword arguments of FieldTree.new other than the model.
        def initialize(resource:, ability:, asks: {})
          @resource = resource
          @ability = ability
          @asks = asks
        end

        def parse
          data = case resource
                 when nil then {}
                 when Hash, Array then resource
                 else FieldTree.new(model, **asks).render(resource, ability: ability)
                 end
          Response.new(data: data)
        end

        private

        def model
          resource.try(:klass) || resource.class
        end
      end
    end
  end
end
