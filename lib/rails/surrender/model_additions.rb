# frozen_string_literal: true

module Rails
  module Surrender
    # Aad methods to the model class to describe how the model renders.
    module ModelAdditions
      def self.included(base)
        attr_accessor :surrender_attributes
        attr_accessor :surrender_expands
        attr_accessor :surrender_available_attributes
        attr_accessor :surrender_available_expands

        base.extend(ClassMethods)
      end

      module ClassMethods
        def surrenders(*args)
          directives = args.extract_options!

          # Run through the various lists of attributes and assign them to the rendering context
          # If the superclass has attributes then consume those as well.
          %w[attributes expands available_attributes available_expands].each do |directive|
            surrender_directive = "surrender_#{directive}"
            list = []
            if superclass.instance_variable_defined?("@#{surrender_directive}")
              list << superclass.instance_variable_get("@#{surrender_directive}")
            end
            list << directives[directive.to_sym] if directives.key?(directive.to_sym)
            instance_variable_set("@#{surrender_directive}", list.flatten.uniq)
          end
        end

        def surrender_attributes
          @surrender_attributes ||= %i[id created_at]
        end

        def surrender_available_attributes
          @surrender_available_attributes ||= []
        end

        def surrender_expands
          @surrender_expands ||= []
        end

        def surrender_available_expands
          @surrender_available_expands ||= []
        end

        def surrender_callable_attributes
          @surrender_callable_attributes ||= (surrender_attributes + surrender_available_attributes).flatten
        end

        def surrender_callable_expands
          @surrender_callable_expands ||= (surrender_expands + surrender_available_expands).flatten
        end

        def can_call_attribute?(attr)
          surrender_callable_attributes.include?(attr.to_sym)
        end

        def can_call_expand?(attr)
          surrender_callable_expands.include?(attr.to_sym)
        end

        def default_response_fields
          [@surrender_attributes.dup << @surrender_expands].flatten.join(', ')
        end

        def available_response_fields
          [@surrender_available_attributes.dup << @surrender_available_expands].flatten.join(', ')
        end
      end
    end
  end
end
