# frozen_string_literal: true

module Rails
  module Surrender
    module Render
      class Resource
        class InclusionMapper
          attr_reader :resource_class, :control

          # InclusionMapper is designed to recursively crawl through the model rendering structure and build a hash
          # that ActiveRecord can use to eager load ALL of the data we're going to render, to prevent N+1 queries
          def initialize(resource_class:, control:)
            @resource_class = resource_class
            @control = control
          end

          def includes
            control.history = control.history.dup.push resource_class

            ctrl_exclude_here = control.local_ctrl_excludes
            user_exclude_here = control.local_user_excludes
            ctrl_exclude_next = control.nested_ctrl_excludes
            user_exclude_next = control.nested_user_excludes
            user_include_here = control.local_user_includes
                                       .select { |z| resource_class.reflections.key? z.to_s }
                                       .map { |e| { name: e, class: resource_class.reflections[e.to_s].klass } }
            ctrl_include_here = control.local_ctrl_includes
                                       .select { |z| resource_class.reflections.key? z.to_s }
                                       .map { |e| { name: e, class: resource_class.reflections[e.to_s].klass } }
            user_include_next = control.nested_user_includes
            ctrl_include_next = control.nested_ctrl_includes

            includes = []
            list = user_include_here +
                   ctrl_include_here +
                   resource_class.surrender_attributes
                                 .select { |x| x.match /_ids$/ }
                                 .map { |y| y.to_s.sub('_ids', '').pluralize }
                                 .select { |z| z.in? resource_class.reflections.keys }
                                 .map { |e| { name: e, class: resource_class.reflections[e.to_s].klass } } +
                   resource_class.surrender_expands
                                 .map { |e| { name: e, class: resource_class.reflections[e.to_s].klass } } +
                   resource_class.subclasses
                                 .map do |sc|
                     sc.surrender_attributes
                       .select { |x| x.match /_ids$/ }
                       .map { |y| y.to_s.sub('_ids', '').pluralize }
                       .select { |z| z.in? sc.reflections.keys }
                       .map { |e| { name: e, class: sc.reflections[e.to_s].klass } }
                   end +
                   resource_class.subclasses
                                 .map do |sc|
                     sc.surrender_expands.map { |e| { name: e, class: sc.reflections[e.to_s].klass } }
                   end
            list.flatten!
            list.uniq!
            list.reject! do |x|
              x[:class].in?(control.history) ||
                x[:name].in?(user_exclude_here) ||
                (x[:name].in?(ctrl_exclude_here) && !x[:name].in?(user_include_here.map { |k| k[:name] }))
            end

            list.each do |item|
              exp = item[:name]
              item_class = item[:class]

              item_control = Controller.new(
                resource_class: item_class,
                user_include: user_include_next[exp] || [],
                ctrl_include: ctrl_include_next[exp] || [],
                user_exclude: user_exclude_next[exp] || [],
                ctrl_exclude: ctrl_exclude_next[exp] || [],
                history: control.history.dup.push(item_class)
              )

              nested = InclusionMapper.new(
                resource_class: item_class,
                control: item_control
              ).includes

              includes << if nested.size.zero?
                            exp
                          else
                            { exp => nested }
                          end
            end
            includes.sort_by { |x| x.is_a?(Symbol) ? 0 : 1 }
          end
        end
      end
    end
  end
end
