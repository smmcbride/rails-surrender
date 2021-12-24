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

        def nested_user_includes
          select_nested_from(user_include)
        end

        private

        def select_locals_from(list)
          list.select { |x| x.is_a?(String) || x.is_a?(Symbol) }.map(&:to_sym).uniq
        end

        def select_nested_from(list)
          list.reject { |x| x.is_a?(String) || x.is_a?(Symbol) }.reduce({}, :merge).symbolize_keys
        end
      end
    end
  end
end
