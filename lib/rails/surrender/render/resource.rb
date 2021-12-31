# frozen_string_literal: true

require_relative 'resource/inclusion_mapper'
require_relative 'resource/collection'
require_relative 'resource/instance'

module Rails
  module Surrender
    module Render
      # Rendering a resource, and it's various nested components, according to the given config params.
      class Resource
        attr_reader :resource, :ability, :config

        def initialize(resource:, ability:, config:)
          @resource = resource
          @ability = ability
          @config  = config
        end

        def parse
          data = case resource
                 when nil? then {}
                 when Hash || Array then resource
                 when ActiveRecord::Relation then collection_data
                 else instance_data
                 end
          Response.new(data: data)
        end

        private

        def collection_data
          includes = InclusionMapper.new(resource_class: resource.klass, config: config).parse
          data = @resource.includes(includes)
          Collection.new(resource: data, config: config, ability: ability).render
        end

        def instance_data
          # Reloading the instance here allows us to take advantage of the eager loading
          # capabilities of ActiveRecord with our 'includes' hash to prevent N+1 queries.
          # This can save a TON of response time when the data sets begin to get large.
          data = if config.reload_resource?
                   includes = InclusionMapper.new(resource_class: resource.class, config: config).parse
                   @resource = resource.class.includes(includes).find_by_id(resource.id)
                 else
                   resource
                 end

          Instance.new(resource: data, config: config, ability: ability).render
        end
      end
    end
  end
end
