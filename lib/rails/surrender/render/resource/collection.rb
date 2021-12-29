# frozen_string_literal: true

module Rails
  module Surrender
    module Render
      class Resource
        # Renders a collection resource
        class Collection
          attr_reader :resource, :control, :ability

          def initialize(resource:, control:, ability:)
            @resource = resource
            @control = control
            @ability = ability
          end

          def render
            return nil if resource.nil?

            resource.map { |data| Instance.new(resource: data, control: control, ability: ability).render }
          end
        end
      end
    end
  end
end
