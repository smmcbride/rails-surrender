# frozen_string_literal: true

module Rails
  module Surrender
    # Adds methods to the model class to describe how the model renders.
    module ModelAdditions
      def self.included(base)
        base.extend(ClassMethods)
      end

      # A model lists the fields it renders by default, and those a request may add with `include`. Fields that name
      # an association expand into the associated resource; every other field is rendered as an attribute.
      module ClassMethods
        DEFAULT_FIELDS = %i[id created_at].freeze

        # Fields are sorted into attributes and associations when read, not here, because models often call
        # `surrenders` before declaring the associations it names.
        def surrenders(*fields, available: [])
          @surrender_fields = (inherited_surrender(:@surrender_fields) + fields.map(&:to_sym)).uniq
          @surrender_available_fields =
            (inherited_surrender(:@surrender_available_fields) + Array(available).map(&:to_sym)).uniq
        end

        def surrender_attributes
          attributes_among(surrender_fields)
        end

        def surrender_expands
          associations_among(surrender_fields)
        end

        def surrender_callable_attributes
          attributes_among(surrender_callable_fields)
        end

        def surrender_callable_expands
          associations_among(surrender_callable_fields)
        end

        private

        def surrender_fields
          @surrender_fields || DEFAULT_FIELDS
        end

        def surrender_available_fields
          @surrender_available_fields || []
        end

        # A subclass may make a default of a field its superclass only made available.
        def surrender_callable_fields
          (surrender_fields + surrender_available_fields).uniq
        end

        def inherited_surrender(variable)
          superclass.instance_variable_defined?(variable) ? superclass.instance_variable_get(variable) : []
        end

        def attributes_among(fields)
          fields.reject { |field| reflect_on_association(field) }
        end

        def associations_among(fields)
          fields.select { |field| reflect_on_association(field) }
        end
      end
    end
  end
end
