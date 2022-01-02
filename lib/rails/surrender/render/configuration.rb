# frozen_string_literal: true

module Rails
  module Surrender
    module Render
      # Container for config structure when rendering or generating the inclusion object.
      class Configuration
        attr_accessor :resource_class,
                      :reload_resource,
                      :user_exclude,
                      :user_include,
                      :ctrl_exclude,
                      :ctrl_include,
                      :history

        alias reload_resource? reload_resource

        Element = Struct.new(:name, :klass, keyword_init: true)

        def initialize(
          resource_class: nil,
          reload_resource: false,
          user_exclude: [],
          user_include: [],
          ctrl_exclude: [],
          ctrl_include: [],
          history: []
        )
          @resource_class = resource_class
          @reload_resource = reload_resource
          @user_exclude = user_exclude.compact
          @user_include = user_include
          @ctrl_exclude = ctrl_exclude.compact
          @ctrl_include = ctrl_include
          @history = history

          validate_user_includes!
        end

        def expanding_elements
          list = resource_class_surrender_attributes_that_expand +
                 resource_class_surrender_expands +
                 resource_class_subclass_surrender_attributes_that_expand +
                 resource_class_subclass_surrender_expands +
                 user_includes_that_expand +
                 ctrl_includes_that_expand
                 .flatten.uniq
          list
            .map { |e| element_from(e) }
            .reject do |element|
            element.klass.in?(history) ||
              element.name.in?(truly_local_user_excludes) ||
              (element.name.in?(truly_local_ctrl_excludes) && !element.name.in?(local_user_includes))
          end
        end

        def nested_user_includes
          select_nested_from(user_include)
        end

        def nested_ctrl_includes
          select_nested_from(ctrl_include)
        end

        def nested_user_excludes
          select_nested_from(user_exclude)
        end

        def nested_ctrl_excludes
          select_nested_from(ctrl_exclude)
        end

        def locally_included_attributes
          [].push(user_include_local_attributes)
            .push(ctrl_include_local_attributes)
            .push(resource_class.surrender_attributes)
            .flatten
            .uniq
            .reject { |attr| exclude_locally?(attr) }
        end

        def locally_included_expands
          local_user_includes.select { |i| attribute_type(i) == :expand }
                             .push(local_ctrl_includes.select { |i| attribute_type(i) == :expand })
                             .push(resource_class.surrender_expands)
                             .flatten.uniq
                             .each_with_object({}) { |key, result| result[key.to_sym] = [] }
                             .deep_merge(nested_includes)
        end

        def exclude_locally?(key)
          local_excludes.include?(key) && !local_user_includes.include?(key)
        end

        private

        def user_includes_that_expand
          local_user_includes.select { |attr| attribute_type(attr) == :expand }
        end

        def ctrl_includes_that_expand
          local_ctrl_includes.select { |attr| attribute_type(attr) == :expand }
        end

        def resource_class_surrender_attributes_that_expand
          resource_class.surrender_attributes
                        .select { |attr| attr.match /_ids$/ }
                        .map { |attr| attr.to_s.sub('_ids', '').pluralize }
                        .select { |attr| attribute_type(attr) == :expand }
        end

        def resource_class_surrender_expands
          resource_class.surrender_expands
        end

        def resource_class_subclass_surrender_attributes_that_expand
          resource_class.subclasses.map do |subclass|
            subclass.surrender_attributes
                    .select { |attr| attr.match /_ids$/ }
                    .map { |attr| attr.to_s.sub('_ids', '').pluralize }
                    .select { |attr| attr.in? subclass.reflections.keys }
          end
        end

        def resource_class_subclass_surrender_expands
          resource_class.subclasses.map(&:surrender_expands)
        end

        def truly_local_ctrl_excludes
          terminating_elements_from(ctrl_exclude)
        end

        def local_ctrl_excludes
          select_locals_from(ctrl_exclude)
        end

        def local_ctrl_includes
          select_locals_from(ctrl_include)
        end

        def truly_local_user_excludes
          terminating_elements_from(user_exclude)
        end

        def local_user_excludes
          select_locals_from(user_exclude)
        end

        def local_user_includes
          select_locals_from(user_include)
        end

        def nested_includes
          nested_user_includes.deep_merge(nested_ctrl_includes)
        end

        def local_excludes
          local_ctrl_excludes.dup.push(local_user_excludes).flatten.uniq
        end

        def user_include_local_attributes
          attrs = local_user_includes.select { |i| attribute_type(i) == :include }
          unavailable_attrs = (attrs - resource_class.surrender_available_attributes)
          return attrs if unavailable_attrs.empty?

          raise Error, I18n.t('surrender.error.query_string.include.not_available', param: unavailable_attrs)
        end

        def ctrl_include_local_attributes
          local_ctrl_includes.select { |i| attribute_type(i) == :include }
        end

        def validate_user_includes!
          return if invalid_local_user_includes.empty?

          raise Error, I18n.t('surrender.error.query_string.include.not_available', param: invalid_local_user_includes)
        end

        def invalid_local_user_includes
          local_user_includes.select { |include| attribute_type(include) == :none }
        end

        def element_from(item)
          Element.new name: item, klass: resource_class.reflections[item.to_s].klass
        end

        def attribute_type(attr)
          return :expand if resource_class.reflections.keys.include? attr.to_s
          return :include if resource_class.attribute_names.include? attr.to_s
          return :include if resource_class.instance_methods.include? attr.to_s

          :none
        end

        def terminating_elements_from(list)
          list.reject { |x| x.is_a?(Hash) }.flatten.map(&:to_sym).uniq
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
