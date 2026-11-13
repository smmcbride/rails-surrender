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

        def surrender_fields
          @surrender_fields || DEFAULT_FIELDS
        end

        def surrender_available_fields
          @surrender_available_fields || []
        end

        # Everything a request may ask of the model: its fields, filters and sorts.
        def surrender_menu
          Menu.new(self)
        end

        # Whether a request may include the field: it renders by default or is available.
        def surrenders?(name)
          surrender_callable_fields.include?(name.to_sym)
        end

        # An association expands, a *_ids name of an association is an id list, and anything else is an attribute.
        def surrender_field(name)
          name = name.to_sym
          if (reflection = reflect_on_association(name))
            Fields::Expand.new(name: name, reflection: reflection)
          elsif (association = id_list_association(name))
            Fields::IdList.new(name: name, association: association)
          else
            Fields::Attribute.new(name: name)
          end
        end

        private

        def id_list_association(name)
          return unless name.end_with?('_ids')

          association = name.to_s.delete_suffix('_ids').pluralize.to_sym
          association if reflect_on_association(association)
        end

        # A subclass may make a default of a field its superclass only made available.
        def surrender_callable_fields
          (surrender_fields + surrender_available_fields).uniq
        end

        def inherited_surrender(variable)
          superclass.instance_variable_defined?(variable) ? superclass.instance_variable_get(variable) : []
        end
      end
    end
  end
end
