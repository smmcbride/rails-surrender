# frozen_string_literal: true

module Rails
  module Surrender
    module Render
      class Resource
        # Builds a complete map of the resources needed to fulfill the request, for supplying to ActiveRecord.includes
        class InclusionMapper
          attr_reader :resource_class, :config

          Element = Struct.new(:name, :klass, keyword_init: true)
          # InclusionMapper is designed to recursively crawl through the model rendering structure and build a hash
          # that ActiveRecord can use to eager load ALL of the data we're going to render, to prevent N+1 queries
          def initialize(resource_class:, config:)
            @resource_class = resource_class
            @config = config
          end

          def parse
            config.history.push resource_class
            includes = []

            config.expanding_elements.each do |element|
              item_config = Configuration.new(
                resource_class: element.klass,
                user_include: config.nested_user_includes[element.name] || [],
                ctrl_include: config.nested_ctrl_includes[element.name] || [],
                user_exclude: config.nested_user_excludes[element.name] || [],
                ctrl_exclude: config.nested_ctrl_excludes[element.name] || [],
                history: config.history.dup.push(element.klass)
              )

              nested = if element.continue
                         InclusionMapper.new(resource_class: element.klass, config: item_config).parse
                       else
                         []
                       end

              includes << (nested.size.zero? ? element.name : { element.name => nested })
            end

            includes.sort_by { |x| x.is_a?(Symbol) ? 0 : 1 }
          end
        end
      end
    end
  end
end
