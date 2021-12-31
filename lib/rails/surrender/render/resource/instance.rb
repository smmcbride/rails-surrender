# frozen_string_literal: true

module Rails
  module Surrender
    module Render
      class Resource
        # Renders an instance resource
        class Instance
          attr_reader :resource, :control, :ability

          def initialize(resource:, control:, ability:)
            @resource = resource
            @control = control
            @ability = ability
          end

          def render
            return nil if resource.nil?

            resource_class = resource.class

            # get to the root subclass for sti models and store that as history
            history_class = superclass_for(resource_class)

            control.history.push history_class

            validate_user_includes!

            result = {}
            control.locally_included_attributes.each { |attr| result[attr.to_sym] = resource.send(attr) }

            control.locally_included_expands.each do |key, value|
              next if control.exclude_locally?(key)

              begin
                nested_resource_class = resource_class.reflections[key.to_s].klass
              rescue NoMethodError
                nested_resource_class = resource.send(key).class
              end

              # skip classes in history stack to prevent circular rendering.
              next if control.history.include? nested_resource_class

              nested_control = Controller.new(
                resource_class: nested_resource_class,
                ctrl_include: value, # this is the merge of user_include and ctrl_include from input
                history: control.history,
                user_exclude: control.nested_user_excludes[key]  || [],
                ctrl_exclude: control.nested_ctrl_excludes[key]  || []
              )

              if resource.class.reflections[key.to_s].try(:collection?)
                collection = resource.send(key.to_sym).select { |i| ability.can? :read, i }
                result[key.to_sym] =
                  Collection.new(resource: collection, control: nested_control, ability: ability).render
              else
                instance = resource.send(key)
                next if class_history.include? instance.class

                if ability.can?(:read, instance)
                  result[key.to_sym] =
                    Instance.new(resource: instance, control: nested_control, ability: ability).render
                elsif instance.nil?
                  result[key.to_sym] = nil # represent an associated element as null if it's missing
                end
              end
            end
            result
          end

          private

          def validate_user_includes!
            return if control.invalid_local_user_includes.empty?

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
