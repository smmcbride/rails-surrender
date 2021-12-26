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
            control.history = control.history.dup.push resource_class

            user_include_here = control.local_user_includes
                                       .select { |z| resource_class.reflections.key? z.to_s }
                                       .map { |e| element_from(e) }
            ctrl_include_here = control.local_ctrl_includes
                                       .select { |z| resource_class.reflections.key? z.to_s }
                                       .map { |e| element_from(e) }

            includes = []
            list = user_include_here +
                   ctrl_include_here +
                   resource_class_attributes +
                   resource_class_expands +
                   resource_class_subclass_attributes +
                   resource_class_subclass_expands
            list.flatten!
            list.uniq!
            list.reject! do |x|
              x.klass.in?(control.history) ||
                x.name.in?(control.local_user_excludes) ||
                (x.name.in?(control.local_ctrl_excludes) && !x.name.in?(user_include_here.map(&:name)))
            end

            list.each do |element|
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

          private

          def resource_class_attributes
            resource_class.surrender_attributes
                          .select { |x| x.match /_ids$/ }
                          .map { |y| y.to_s.sub('_ids', '').pluralize }
                          .select { |z| z.in? resource_class.reflections.keys }
                          .map { |e| element_from(e) }
          end

          def resource_class_expands
            resource_class.surrender_expands.map { |e| element_from(e) }
          end

          def resource_class_subclass_attributes
            resource_class.subclasses.map do |sc|
              sc.surrender_attributes
                .select { |x| x.match /_ids$/ }
                .map { |y| y.to_s.sub('_ids', '').pluralize }
                .select { |z| z.in? sc.reflections.keys }
                .map { |e| element_from(e, klass: sc) }
            end
          end

          def resource_class_subclass_expands
            resource_class.subclasses
                          .map do |sc|
              sc.surrender_expands.map { |e| element_from(e, klass: sc) }
            end
          end

          def element_from(item, klass: resource_class)
            Element.new name: item, klass: klass.reflections[item.to_s].klass
          end
        end
      end
    end
  end
end
