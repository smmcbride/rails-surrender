# frozen_string_literal: true

module Rails
  module Surrender
    class Render
      def self.render(source, *args)
        opts = args.extract_options!
        @ability = opts[:current_ability]

        render_control = opts[:render_control] || {}

        data =
          if source.nil?
            {}
          elsif source.is_a?(Hash) || source.is_a?(Array)
            source
          elsif source.is_a? ActiveRecord::Relation
            includer = includer(source.klass, render_control)
            render_collection(source.includes(includer), render_control)
          else
            includer = includer(source.class, render_control)

            # Reloading the instance here allows us to take advantage of the eager loading
            # capabilities of ActiveRecord with our 'includer' hash to prevent N+1 queries.
            # This can save a TON of response time when the data sets begin to get large.
            unless render_control[:reload_resource] == false
              source = source.class.includes(includer).find_by_id(source.id)
            end

            render_instance(source, render_control)
          end

        Response.new(data: data)
      end

      # 'includer' is designed to recursively crawl through the model rendering structure and build a hash
      # that ActiveRecord can use to eager load ALL of the data we're going to render, to prevent N+1 queries

      def self.includer(source_class, *args)
        opts = args.extract_options!
        history      = (opts.key?(:history) ? opts[:history] : []).dup.push source_class
        user_include = opts.key?(:user_include) ? opts[:user_include] : []
        user_exclude = opts.key?(:user_exclude) ? opts[:user_exclude] : []
        ctrl_include = opts.key?(:ctrl_include) ? opts[:ctrl_include] : []
        ctrl_exclude = opts.key?(:ctrl_exclude) ? opts[:ctrl_exclude] : []

        ctrl_exclude.reject!(&:nil?)
        user_exclude.reject!(&:nil?)
        ctrl_exclude_here = ctrl_exclude.select { |x| x.is_a?(String) || x.is_a?(Symbol) }.map(&:to_sym)
        user_exclude_here = user_exclude.select { |x| x.is_a?(String) || x.is_a?(Symbol) }.map(&:to_sym)
        ctrl_exclude_next = ctrl_exclude.reject { |x| x.is_a?(String) || x.is_a?(Symbol) }
                                        .reduce({}, :merge)
                                        .symbolize_keys
        user_exclude_next = user_exclude.reject { |x| x.is_a?(String) || x.is_a?(Symbol) }
                                        .reduce({}, :merge)
                                        .symbolize_keys
        user_include_here = user_include.select { |x| x.is_a?(String) || x.is_a?(Symbol) }
                                        .map(&:to_sym)
                                        .uniq
                                        .select { |z| source_class.reflections.key? z.to_s }
                                        .map { |e| { name: e, class: source_class.reflections[e.to_s].klass } }
        ctrl_include_here = ctrl_include.select { |x| x.is_a?(String) || x.is_a?(Symbol) }
                                        .map(&:to_sym)
                                        .uniq
                                        .select { |z| source_class.reflections.key? z.to_s }
                                        .map { |e| { name: e, class: source_class.reflections[e.to_s].klass } }
        user_include_next = user_include.reject { |x| x.is_a?(String) || x.is_a?(Symbol) }
                                        .reduce({}, :merge)
                                        .symbolize_keys
        ctrl_include_next = ctrl_include.reject { |x| x.is_a?(String) || x.is_a?(Symbol) }
                                        .reduce({}, :merge)
                                        .symbolize_keys

        includes = []
        list = user_include_here +
               ctrl_include_here +
               source_class.surrender_attributes
                           .select { |x| x.match /_ids$/ }
                           .map { |y| y.to_s.sub('_ids', '').pluralize }
                           .select { |z| z.in? source_class.reflections.keys }
                           .map { |e| { name: e, class: source_class.reflections[e.to_s].klass } } +
               source_class.surrender_expands
                           .map { |e| { name: e, class: source_class.reflections[e.to_s].klass } } +
               source_class.subclasses
                           .map do |sc|
                               sc.surrender_attributes
                                 .select { |x| x.match /_ids$/ }
                                 .map { |y| y.to_s.sub('_ids', '').pluralize }
                                 .select { |z| z.in? sc.reflections.keys }
                                 .map { |e| { name: e, class: sc.reflections[e.to_s].klass } }
               end +
               source_class.subclasses
                           .map do |sc|
                   sc.surrender_expands.map { |e| { name: e, class: sc.reflections[e.to_s].klass } }
               end
        list.flatten!
        list.uniq!
        list.reject! do |x|
          x[:class].in?(history) ||
            x[:name].in?(user_exclude_here) ||
            (x[:name].in?(ctrl_exclude_here) && !x[:name].in?(user_include_here.map { |k| k[:name] }))
        end

        list.each do |item|
          exp = item[:name]
          resource_class = item[:class]

          nested = includer(
            resource_class,
            user_include: user_include_next[exp] || [],
            ctrl_include: ctrl_include_next[exp] || [],
            user_exclude: user_exclude_next[exp] || [],
            ctrl_exclude: ctrl_exclude_next[exp] || [],
            history: history.dup.push(resource_class)
          )

          if nested.size.zero?
            includes << exp
          else
            includes << { exp => nested }
          end
        end
        includes.sort_by { |x| x.is_a?(Symbol) ? 0 : 1 }
      end

      def self.render_collection(source, *args)
        return nil if source.nil?

        source.map { |x| render_instance(x, *args) }
      end

      def self.render_instance(source, *args)
        return nil if source.nil?

        resource_class = source.class

        opts = args.extract_options!
        history       = opts.key?(:history)      ? opts[:history]      : []
        user_include  = opts.key?(:user_include) ? opts[:user_include] : []
        user_exclude  = opts.key?(:user_exclude) ? opts[:user_exclude] : []
        ctrl_include  = opts.key?(:ctrl_include) ? opts[:ctrl_include] : []
        ctrl_exclude  = opts.key?(:ctrl_exclude) ? opts[:ctrl_exclude] : []

        class_exclude = opts.key?(:class_exclude) ? opts[:class_exclude] : []
        class_exclude.push(resource_class.surrender_skip_expands.dup).flatten!.uniq!

        # get to the root subclass for sti models and store that as history
        history_class = resource_class
        until history_class.superclass == ActiveRecord::Base
          history_class = history_class.superclass
        end

        class_history = history.dup.push history_class

        user_include_here = user_include.select { |x| x.is_a?(String) || x.is_a?(Symbol) }.map(&:to_sym).uniq

        # ctrl_include(here/next) are generally covered by the ctrl_include loop below,
        # so I don't think they're needed here...
        _ctrl_include_here = ctrl_include.select { |x| x.is_a?(String) || x.is_a?(Symbol) }.map(&:to_sym).uniq
        _ctrl_include_next = ctrl_include.reject { |x| x.is_a?(String) || x.is_a?(Symbol) }
                                         .reduce({}, :merge)
                                         .symbolize_keys

        # handle expands that we want to skip
        ctrl_exclude_here = ctrl_exclude.select { |x| x.is_a?(String) || x.is_a?(Symbol) }.map(&:to_sym)
        ctrl_exclude_next = ctrl_exclude.reject { |x| x.is_a?(String) || x.is_a?(Symbol) }
                                        .reduce({}, :merge)
                                        .symbolize_keys
        user_exclude_here = user_exclude.select { |x| x.is_a?(String) || x.is_a?(Symbol) }.map(&:to_sym)
        user_exclude_next = user_exclude.reject { |x| x.is_a?(String) || x.is_a?(Symbol) }
                                        .reduce({}, :merge)
                                        .symbolize_keys
        class_exclude_here = class_exclude.select { |x| x.is_a?(String) || x.is_a?(Symbol) }.map(&:to_sym)
        class_exclude_next = class_exclude.reject { |x| x.is_a?(String) || x.is_a?(Symbol) }
                                          .reduce({}, :merge)
                                          .symbolize_keys
        exclude_here = ctrl_exclude_here.dup.push(user_exclude_here).push(class_exclude_here).flatten.uniq

        included_attrs   = []
        included_expands = []

        user_include.each do |i|
          case i
          when String, Symbol # individual attribute, or association
            if resource_class.reflections.keys.include? i.to_s
              unless resource_class.can_call_expand? i.to_sym
                raise Error, I18n.t('surrender.error.query_string.include.not_available', params: { a: i })
              end

              included_expands << i.to_sym
            elsif resource_class.attribute_names.include?(i) || resource_class.instance_methods.include?(i.to_sym)
              unless resource_class.can_call_attribute? i.to_sym
                raise Error, I18n.t('surrender.error.query_string.include.not_available', params: { a: i })
              end

              included_attrs << i.to_sym
            else
              raise Error, I18n.t('surrender.error.query_string.include.invalid', params: { a: i })
            end
          when Hash # expanded attribute with inner details
            included_expands << i
          end
        end

        # ctrl_includes come from the controller and bypass the 'can_call' checks.
        ctrl_include.each do |i|
          case i
          when String, Symbol # individual attribute, or association
            if resource_class.reflections.keys.include? i.to_s
              included_expands << i.to_sym
            elsif resource_class.attribute_names.include?(i) || resource_class.instance_methods.include?(i.to_sym)
              included_attrs << i.to_sym
            end
          when Hash # expanded attribute with inner details
            included_expands << i
          end
        end

        # Hash to store all the values
        result = {}

        # PLUS all the included attributes and the models default attributes
        included_attrs.push(resource_class.surrender_attributes).flatten!.uniq!

        # MINUS excluded attributes
        included_attrs.reject! do |attr|
          attr.in?(user_exclude_here) || (attr.in?(ctrl_exclude_here) && !attr.in?(user_include_here))
        end

        included_attrs.each do |a|
          result[a.to_sym] = source.send(a)
        end

        expandings = included_expands
        resource_class.surrender_expands.each do |exp|
          # add the class expnsions unless the expandings already has a more complex expansion request with this key
          expandings << exp unless expandings.select { |a| a.is_a? Hash }
                                             .map(&:keys)
                                             .flatten
                                             .map(&:to_sym)
                                             .include? exp.to_sym
        end

        expandings.each do |e|
          e = { e.to_sym => [] } if e.is_a?(Symbol)

          e.each do |key, value|
            next if exclude_here.include?(key) && !user_include_here.include?(key) # Skip excluded expands

            begin
              nested_resource_class = resource_class.reflections[key.to_s].klass
            rescue NoMethodError
              nested_resource_class = source.send(key).class
            end

            # skip classes in history stack to prevent circular rendering.
            next if class_history.include? nested_resource_class

            nested_user_exclude  = user_exclude_next[key]  || []
            nested_ctrl_exclude  = ctrl_exclude_next[key]  || []
            nested_class_exclude = class_exclude_next[key] || []

            if source.class.reflections[key.to_s].try(:collection?)
              collection = source.send(key.to_sym).select { |i| @ability.can? :read, i }
              result[key.to_sym] = render_collection(
                collection,
                ctrl_include: value, # this is the merge of user_include and ctrl_include from input
                history: class_history,
                user_exclude: nested_user_exclude,
                ctrl_exclude: nested_ctrl_exclude,
                class_exclude: nested_class_exclude
              )
            else
              instance = source.send(key)
              next if class_history.include? instance.class

              if @ability.can?(:read, instance)
                result[key.to_sym] = render_instance(
                  instance,
                  ctrl_include: value, # this is the merge of user_include and ctrl_include from input
                  history: class_history,
                  user_exclude: nested_user_exclude,
                  ctrl_exclude: nested_ctrl_exclude,
                  class_exclude: nested_class_exclude
                )
              elsif instance.nil?
                result[key.to_sym] = nil # represent an associated element as null if it's missing
              end
            end
          end
        end
        result
      end
    end
  end
end
