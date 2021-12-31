# frozen_string_literal: true

module Rails
  module Surrender
    module Render
      class Resource
        # Renders a collection resource
        class Collection
          attr_reader :resource, :config, :ability

          def initialize(resource:, config:, ability:)
            @resource = resource
            @config = config
            @ability = ability
          end

          def render
            return nil if resource.nil?

            resource.map { |data| Instance.new(resource: data, config: config, ability: ability).render }
          end
        end
      end
    end
  end
end
