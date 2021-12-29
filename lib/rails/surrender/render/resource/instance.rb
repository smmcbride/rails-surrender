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
            control.class_exclude.push(resource_class.surrender_skip_expands.dup).flatten!.uniq!

            # get to the root subclass for sti models and store that as history
            history_class = superclass_for(resource_class)

            class_history = control.history.dup.push history_class

            included_attrs   = []
            included_expands = []

            control.user_include.each do |i|
              case i
              when String, Symbol # individual attribute, or association
                if resource_class.reflections.keys.include? i.to_s
                  unless resource_class.can_call_expand? i.to_sym
                    raise Error, I18n.t('surrender.error.query_string.include.not_available', params: { a: i })
                  end

                  included_expands << i.to_sym
                elsif resource_class.attribute_names.include?(i) || resource_class.instance_methods.include?(i.to_sym)
                  unless resource_class.can_call_attribute? i.to_sym
                    raise Error, I18n.t('surrender.error.query_string.include.not_available', params: { a: i })
                  end

                  included_attrs << i.to_sym
                else
                  raise Error, I18n.t('surrender.error.query_string.include.invalid', params: { a: i })
                end
              when Hash # expanded attribute with inner details
                included_expands << i
              end
            end

            # ctrl_includes come from the controller and bypass the 'can_call' checks.
            control.ctrl_include.each do |i|
              case i
              when String, Symbol # individual attribute, or association
                if resource_class.reflections.keys.include? i.to_s
                  included_expands << i.to_sym
                elsif resource_class.attribute_names.include?(i) || resource_class.instance_methods.include?(i.to_sym)
                  included_attrs << i.to_sym
                end
              when Hash # expanded attribute with inner details
                included_expands << i
              end
            end

            # Hash to store all the values
            result = {}

            # PLUS all the included attributes and the models default attributes
            included_attrs.push(resource_class.surrender_attributes).flatten!.uniq!

            # MINUS excluded attributes
            included_attrs.reject! { |attr| control.exclude_locally?(attr) }

            included_attrs.each { |a| result[a.to_sym] = resource.send(a) }

            expandings = included_expands
            resource_class.surrender_expands.each do |exp|
              # add the class expansions unless _expandings_ already has a more complex expansion request with this key
              expandings << exp unless expandings.select { |a| a.is_a? Hash }
                                                 .map(&:keys)
                                                 .flatten
                                                 .map(&:to_sym)
                                                 .include? exp.to_sym
            end

            expandings.each do |e|
              e = { e.to_sym => [] } if e.is_a?(Symbol)

              e.each do |key, value|
                next if control.exclude_locally?(key)

                begin
                  nested_resource_class = resource_class.reflections[key.to_s].klass
                rescue NoMethodError
                  nested_resource_class = resource.send(key).class
                end

                # skip classes in history stack to prevent circular rendering.
                next if class_history.include? nested_resource_class

                nested_control = Controller.new(
                  ctrl_include: value, # this is the merge of user_include and ctrl_include from input
                  history: class_history,
                  user_exclude: control.nested_user_excludes[key]  || [],
                  ctrl_exclude: control.nested_ctrl_excludes[key]  || [],
                  class_exclude: control.nested_class_excludes[key] || []
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
            end
            result
          end

          private

          def superclass_for(resource_class)
            resource_class.superclass until resource_class.superclass.in? [ActiveRecord::Base, ApplicationRecord]
          end
        end
      end
    end
  end
end
