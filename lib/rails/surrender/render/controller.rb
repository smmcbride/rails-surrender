# frozen_string_literal: true

module Rails
  module Surrender
    module Render
      # Container for control structure when rendering or generating the inclusion object.
      class Controller
        attr_accessor :resource_class,
                      :reload_resource,
                      :user_exclude,
                      :user_include,
                      :ctrl_exclude,
                      :ctrl_include,
                      :class_exclude,
                      :history

        alias reload_resource? reload_resource

        def initialize(
          resource_class: nil,
          reload_resource: false,
          user_exclude: [],
          user_include: [],
          ctrl_exclude: [],
          ctrl_include: [],
          class_exclude: [],
          history: []
        )
          @resource_class = resource_class
          @reload_resource = reload_resource
          @user_exclude = user_exclude.compact
          @user_include = user_include
          @ctrl_exclude = ctrl_exclude.compact
          @ctrl_include = ctrl_include
          @class_exclude = class_exclude
          @history = history
        end

        def local_class_excludes
          select_locals_from(class_exclude)
        end

        def nested_class_excludes
          select_nested_from(class_exclude)
        end

        def local_ctrl_excludes
          select_locals_from(ctrl_exclude)
        end

        def nested_ctrl_excludes
          select_nested_from(ctrl_exclude)
        end

        def local_ctrl_includes
          select_locals_from(ctrl_include)
        end

        def nested_ctrl_includes
          select_nested_from(ctrl_include)
        end

        def local_user_excludes
          select_locals_from(user_exclude)
        end

        def nested_user_excludes
          select_nested_from(user_exclude)
        end

        def local_user_includes
          select_locals_from(user_include)
        end

        def invalid_local_user_includes
          local_user_includes.select { |include| attribute_type(include) == :none }
        end

        def nested_user_includes
          select_nested_from(user_include)
        end

        def nested_includes
          nested_user_includes.deep_merge(nested_ctrl_includes)
        end

        def local_excludes
          local_ctrl_excludes.dup
                             .push(local_user_excludes)
                             .push(local_class_excludes)
                             .flatten.uniq
        end

        def exclude_locally?(key)
          local_excludes.include?(key) && !local_user_includes.include?(key)
        end

        def locally_included_attributes
          [].push(local_user_includes.select { |i| attribute_type(i) == :include })
            .push(local_ctrl_includes.select { |i| attribute_type(i) == :include })
            .push(resource_class.surrender_attributes)
            .flatten
            .uniq
            .reject { |attr| exclude_locally?(attr) }
        end

        def locally_included_expands
          attrs = [].push(local_user_includes.select { |i| attribute_type(i) == :expand })
                    .push(local_ctrl_includes.select { |i| attribute_type(i) == :expand })
                    .push(resource_class.surrender_expands)
                    .flatten.uniq

          nested_includes.each do |key, value|
            attrs.delete(key)
            attrs.push(key => value)
          end

          attrs.map { |attr| attr.is_a?(Symbol) ? { attr => [] } : attr }
        end

        private

        def attribute_type(attr)
          return :expand if resource_class.reflections.keys.include? attr.to_s
          return :include if resource_class.attribute_names.include? attr.to_s
          return :include if resource_class.instance_methods.include? attr.to_s

          :none
        end

        def select_locals_from(list)
          list.map { |x| x.is_a?(Hash) ? x.keys : x }.flatten.map(&:to_sym).uniq
        end

        def select_nested_from(list)
          list.select { |x| x.is_a? Hash }.reduce({}, :merge).symbolize_keys
        end
      end
    end
  end
end
