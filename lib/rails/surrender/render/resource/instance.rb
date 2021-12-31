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
            return nil if resource.nil?

            resource_class = resource.class

            # get to the root subclass for sti models and store that as history
            history_class = superclass_for(resource_class)

            config.history.push history_class

            validate_user_includes!

            result = {}
            config.locally_included_attributes.each { |attr| result[attr.to_sym] = resource.send(attr) }

            config.locally_included_expands.each do |key, value|
              next if config.exclude_locally?(key)

              begin
                nested_resource_class = resource_class.reflections[key.to_s].klass
              rescue NoMethodError
                nested_resource_class = resource.send(key).class
              end

              # skip classes in history stack to prevent circular rendering.
              next if config.history.include? nested_resource_class

              nested_config = Configuration.new(
                resource_class: nested_resource_class,
                ctrl_include: value, # this is the merge of user_include and ctrl_include from input
                history: config.history,
                user_exclude: config.nested_user_excludes[key]  || [],
                ctrl_exclude: config.nested_ctrl_excludes[key]  || []
              )

              if resource.class.reflections[key.to_s].try(:collection?)
                collection = resource.send(key.to_sym).select { |i| ability.can? :read, i }
                result[key.to_sym] =
                  Collection.new(resource: collection, config: nested_config, ability: ability).render
              else
                instance = resource.send(key)
                next if class_history.include? instance.class

                if ability.can?(:read, instance)
                  result[key.to_sym] =
                    Instance.new(resource: instance, config: nested_config, ability: ability).render
                elsif instance.nil?
                  result[key.to_sym] = nil # represent an associated element as null if it's missing
                end
              end
            end
            result
          end

          private

          def validate_user_includes!
            return if config.invalid_local_user_includes.empty?

            raise Error, I18n.t('surrender.error.query_string.include.not_available', param: include)
          end

          def superclass_for(resource_class)
            resource_class.superclass until resource_class.superclass.in? [ActiveRecord::Base, ApplicationRecord]
          end
        end
      end
    end
  end
end
