# frozen_string_literal: true

module Rails
  module Surrender
    module Render
      class Resource
        # Renders an instance resource
        class Instance
          attr_reader :resource, :config, :ability

          def initialize(resource:, config:, ability:)
            @resource = resource
            @config = config
            @ability = ability
          end

          def render
            config.history.push history_class

            result = {}
            config.locally_included_attributes.each { |attr| result[attr.to_sym] = resource.send(attr) }

            config.locally_included_expands.each_key do |key|
              next if config.exclude_locally?(key)

              nested_resource_class = nested_class_for(resource, key)
              next if config.history.include? nested_resource_class

              nested_config = nested_config_for(nested_resource_class, key)

              if resource.class.reflections[key.to_s].try(:collection?)
                collection = resource.send(key.to_sym).select { |i| ability.can? :read, i }
                result[key] = Collection.new(resource: collection, config: nested_config, ability: ability).render
              else
                instance = resource.send(key)
                next if class_history.include? instance.class

                if ability.can?(:read, instance)
                  result[key] = Instance.new(resource: instance, config: nested_config, ability: ability).render
                elsif instance.nil?
                  result[key] = nil # represent an associated element as null if it's missing
                end
              end
            end
            result
          end

          private

          def nested_class_for(resource, key)
            resource.class.reflections[key.to_s].klass
          rescue NoMethodError
            resource.send(key).class
          end

          def nested_config_for(nested_resource_class, key)
            Configuration.new(
              resource_class: nested_resource_class,
              user_include: config.nested_user_includes[key]  || [],
              ctrl_include: config.nested_ctrl_includes[key]  || [],
              user_exclude: config.nested_user_excludes[key]  || [],
              ctrl_exclude: config.nested_ctrl_excludes[key]  || [],
              history: config.history
            )
          end

          # get to the root subclass for sti models and store that as history
          def history_class
            resource.class.superclass until resource.class.superclass.in? [ActiveRecord::Base, ApplicationRecord]
          end
        end
      end
    end
  end
end
