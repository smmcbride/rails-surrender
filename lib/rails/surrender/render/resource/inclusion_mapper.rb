# frozen_string_literal: true

module Rails
  module Surrender
    module Render
      class Resource
        # Builds a complete map of the resources needed to fulfill the request, for supplying to ActiveRecord.includes
        class InclusionMapper
          attr_reader :resource_class, :control

          Element = Struct.new(:name, :klass, keyword_init: true)
          # InclusionMapper is designed to recursively crawl through the model rendering structure and build a hash
          # that ActiveRecord can use to eager load ALL of the data we're going to render, to prevent N+1 queries
          def initialize(resource_class:, control:)
            @resource_class = resource_class
            @control = control
          end

          def parse
            control.history.push resource_class
            includes = []

            control.things_that_expand.each do |element|
              item_control = Controller.new(
                resource_class: element.klass,
                user_include: control.nested_user_includes[element.name] || [],
                ctrl_include: control.nested_ctrl_includes[element.name] || [],
                user_exclude: control.nested_user_excludes[element.name] || [],
                ctrl_exclude: control.nested_ctrl_excludes[element.name] || [],
                history: control.history.dup.push(element.klass)
              )

              nested = InclusionMapper.new(resource_class: element.klass, control: item_control).parse

              includes << (nested.size.zero? ? element.name : { element.name => nested })
            end

            includes.sort_by { |x| x.is_a?(Symbol) ? 0 : 1 }
          end
        end
      end
    end
  end
end
