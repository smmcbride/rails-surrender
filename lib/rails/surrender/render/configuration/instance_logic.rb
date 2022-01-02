# frozen_string_literal: true

module Rails
  module Surrender
    module Render
      # Container for config structure when rendering or generating the inclusion object.
      class Configuration
        module InstanceLogic
          def nested_user_includes
            next_level_asks_from(user_include)
          end

          def nested_ctrl_includes
            next_level_asks_from(ctrl_include)
          end

          def nested_user_excludes
            next_level_asks_from(user_exclude)
          end

          def nested_ctrl_excludes
            next_level_asks_from(ctrl_exclude)
          end

          def locally_included_attributes
            [].push(user_included_local_attributes_to_render)
              .push(ctrl_included_attributes)
              .push(resource_class.surrender_attributes)
              .flatten
              .uniq
              .reject { |attr| exclude_locally?(attr) }
          end

          def locally_included_expands
            [].push(local_user_includes.select { |i| attribute_type(i) == :expand })
              .push(local_ctrl_includes.select { |i| attribute_type(i) == :expand })
              .push(resource_class.surrender_expands)
              .flatten.uniq
              .each_with_object({}) { |key, result| result[key.to_sym] = [] }
              .deep_merge(nested_user_includes)
              .deep_merge(nested_ctrl_includes)
          end

          def exclude_locally?(key)
            local_excludes.include?(key) && !local_user_includes.include?(key)
          end

          private

          def local_excludes
            local_ctrl_excludes.dup.push(local_user_excludes).flatten.uniq
          end

          def user_included_attributes
            top_level_keys_from(user_include).select { |include| attribute_type(include).in? %i[include associate] }
          end

          def user_included_local_attributes_to_render
            attrs = user_included_attributes
            unavailable_attrs = (attrs - resource_class.surrender_available_attributes)
            return attrs if unavailable_attrs.empty?

            raise Error, I18n.t('surrender.error.query_string.include.not_available', param: unavailable_attrs)
          end

          def ctrl_included_attributes
            top_level_keys_from(ctrl_include).select { |include| attribute_type(include).in? %i[include associate] }
          end
        end
      end
    end
  end
end
