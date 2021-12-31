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
        end

        # user include is a list with:
        #   symbols that can be attributs, names that expand, or things that need includes (*_ids)
        #   hashes with one key/value pair.  The hash key is an expansion to include

        # user excludes is a list with
        #   symbols that can be attributs, names that expand, or things that need excludes (*_ids)
        #   hashes with one key/value pair.  The hash key is an expansion to exclude

        # ctrl include is a list with:
        #   symbols that can be attributs, names that expand, or things that need includes (*_ids)
        #   hashes with one key/value pair.  The hask key is an expansion to include

        # ctrl exclude is a list with:
        #   symbols that can be attributs, names that expand, or things that need excludes (*_ids)
        #   hashes with one key/value pair.  The hask key is an expansion to exclude

        # resource_class has
        #   surrender_attributes which is a list of symbols to render
        #   surrender_expands whih is a list of symbols that are expansions
        #   surrender_available_attributes which is a list of attributes the user can request
        #   surrender_available_expands which is a list of expands the user can request
        #
        # history is a llist of class names that have already been called.
        #
        # when building includes:
        #   resource class expands
        #   ++ resourcce class subclass expands
        #   + resource class attributes that expand
        #   + resource class subclass attributes that expand
        #   + user includes attributes that expand
        #   + ctrl includes attributes that expand
        #   - klasses that are in the history
        #   - user exlcudes
        #   - ctrl excludes that are not user includes

        # when rendering we need:
        #   a list of attributes that get rendered
        #   a hash of expansions where the key is the method to exapnd, and the value gets passed to the next iteration

        def things_that_expand
          elements = resource_class_surrender_attributes_that_expand +
                     resource_class_subclass_surrender_attributes_that_expand +
                     resource_class_subclass_surrender_expands +
                     user_includes_that_expand +
                     ctrl_includes_that_expand

          elements.reject! do |element|
            element.klass.in?(history) ||
              element.name.in?(truly_local_user_excludes) ||
              (element.name.in?(truly_local_ctrl_excludes) && !element.name.in?(local_user_includes))
          end

          elements
        end

        def user_includes_that_expand
          local_user_includes.select { |attr| attribute_type(attr) == :expand }
                             .map { |e| element_from(e) }
        end

        def ctrl_includes_that_expand
          local_ctrl_includes.select { |attr| attribute_type(attr) == :expand }
                             .map { |e| element_from(e) }
        end

        def resource_class_surrender_attributes_that_expand
          resource_class.surrender_attributes
                        .select { |attr| attr.match /_ids$/ }
                        .map { |attr| attr.to_s.sub('_ids', '').pluralize }
                        .select { |attr| attribute_type(attr) == :expand }
                        .map { |e| element_from(e) }
        end

        def resource_class_subclass_surrender_attributes_that_expand
          resource_class.subclasses.map do |subclass|
            subclass.surrender_attributes
                    .select { |attr| attr.match /_ids$/ }
                    .map { |attr| attr.to_s.sub('_ids', '').pluralize }
                    .select { |attr| attr.in? subclass.reflections.keys }
                    .map { |e| element_from(e) }
          end
        end

        def resource_class_subclass_surrender_expands
          resource_class.subclasses.map(&:surrender_expands)
                        .map { |e| element_from(e) }
        end

        def truly_local_ctrl_excludes
          select_truly_locals_from(ctrl_exclude)
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

        def truly_local_user_excludes
          select_truly_locals_from(user_exclude)
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

        def invalid_local_user_includes
          local_user_includes.select { |include| attribute_type(include) == :none }
        end

        def nested_user_includes
          select_nested_from(user_include)
        end

        def nested_includes
          nested_user_includes.deep_merge(nested_ctrl_includes)
        end

        def local_excludes
          local_ctrl_excludes.dup
                             .push(local_user_excludes)
                             .flatten.uniq
        end

        def exclude_locally?(key)
          local_excludes.include?(key) && !local_user_includes.include?(key)
        end

        def locally_included_attributes
          [].push(local_user_includes.select { |i| attribute_type(i) == :include })
            .push(local_ctrl_includes.select { |i| attribute_type(i) == :include })
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

        private

        def element_from(item, klass: resource_class)
          Element.new name: item, klass: klass.reflections[item.to_s].klass
        end

        def attribute_type(attr)
          return :expand if resource_class.reflections.keys.include? attr.to_s
          return :include if resource_class.attribute_names.include? attr.to_s
          return :include if resource_class.instance_methods.include? attr.to_s

          :none
        end

        def select_truly_locals_from(list)
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
