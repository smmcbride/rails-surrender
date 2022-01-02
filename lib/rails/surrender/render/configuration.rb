# frozen_string_literal: true

require_relative 'configuration/inclusion_mapper_logic'
require_relative 'configuration/instance_logic'

module Rails
  module Surrender
    module Render
      # Container for config structure when rendering or generating the inclusion object.
      class Configuration
        include InclusionMapperLogic
        include InstanceLogic

        attr_accessor :resource_class,
                      :reload_resource,
                      :user_exclude,
                      :user_include,
                      :ctrl_exclude,
                      :ctrl_include,
                      :history

        alias reload_resource? reload_resource

        Element = Struct.new(:name, :klass, :continue, keyword_init: true)

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

        private

        def validate_user_includes!
          return if invalid_local_user_includes.empty?

          raise Error, I18n.t('surrender.error.query_string.include.not_available', param: invalid_local_user_includes)
        end

        def invalid_local_user_includes
          local_user_includes.select { |include| attribute_type(include) == :none }
        end

        def local_ctrl_excludes
          top_level_keys_from(ctrl_exclude)
        end

        def local_ctrl_includes
          top_level_keys_from(ctrl_include)
        end

        def local_user_excludes
          top_level_keys_from(user_exclude)
        end

        def local_user_includes
          top_level_keys_from(user_include)
        end

        def attribute_type(attr, klass: resource_class)
          return :expand if klass.reflections.keys.include?(attr.to_s)
          return :associate if klass.reflections.keys.include?(attr.to_s.sub('_ids', '').pluralize)
          return :include if klass.attribute_names.include?(attr.to_s)
          return :include if klass.instance_methods.include?(attr)

          :none
        end

        def top_level_keys_from(list)
          list.map { |x| x.is_a?(Hash) ? x.keys : x }.flatten.map(&:to_sym).uniq
        end

        def next_level_asks_from(list)
          list.select { |x| x.is_a? Hash }.reduce({}, :merge).symbolize_keys
        end
      end
    end
  end
end
