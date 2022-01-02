# frozen_string_literal: true

module Rails
  module Surrender
    module Render
      # Container for config structure when rendering or generating the inclusion object.
      class Configuration
        module InclusionMapperLogic
          def expanding_elements
            list = resource_class_surrender_attributes_that_expand +
                   resource_class_surrender_expands +
                   resource_class_subclass_surrender_attributes_that_expand +
                   resource_class_subclass_surrender_expands +
                   user_included_joins_required +
                   ctrl_included_joins_required
                   .flatten.uniq
            list
              .map { |e| element_from(e) }
              .reject do |element|
              element.klass.in?(history) ||
                element.name.in?(local_user_excludes) ||
                (element.name.in?(local_ctrl_excludes) && !element.name.in?(local_user_includes))
            end
          end

          private

          def resource_class_surrender_attributes_that_expand
            resource_class.surrender_attributes
                          .select { |attr| attr.match /_ids$/ }
                          .map { |attr| attr.to_s.sub('_ids', '').pluralize }
                          .select { |include| attribute_type(include).in? %i[expand associate] }
          end

          def resource_class_surrender_expands
            resource_class.surrender_expands
          end

          def resource_class_subclass_surrender_attributes_that_expand
            resource_class.subclasses.map do |subclass|
              subclass.surrender_attributes
                      .select { |attr| attr.match /_ids$/ }
                      .map { |attr| attr.to_s.sub('_ids', '').pluralize }
                      .select { |include| attribute_type(include, resource_class: sc).in? %i[expand associate] }
            end
          end

          def resource_class_subclass_surrender_expands
            resource_class.subclasses.map(&:surrender_expands)
          end

          def user_included_joins_required
            top_level_keys_from(user_include).select { |include| attribute_type(include).in? %i[expand associate] }
          end

          def ctrl_included_joins_required
            top_level_keys_from(ctrl_include).select { |include| attribute_type(include).in? %i[expand associate] }
          end

          def element_from(item)
            item_name = resource_class.reflections.key?(item.to_s) ? item.to_s : item.to_s.sub('_ids', '').pluralize
            item_klass = resource_class.reflections[item_name].klass
            Element.new name: item_name, klass: item_klass, continue: (item.to_s == item_name)
          end
        end
      end
    end
  end
end
