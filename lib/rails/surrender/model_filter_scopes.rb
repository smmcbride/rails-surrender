# frozen_string_literal: true

module Rails
  module Surrender
    # Adds a filter_by_<column> scope for every column, and filter_by_<name>_to/from/before/after scopes for
    # date and time columns, where <name> drops any _at suffix.
    #
    # The scopes are defined the first time any filter_by_ method is looked up, rather than when the class is
    # defined, so that loading a model never touches the database.
    module ModelFilterScopes
      extend ActiveSupport::Concern

      FILTER_PREFIX = 'filter_by_'

      # Generates the filter scopes on first lookup.
      module ClassMethods
        # Once the scopes are defined they are ordinary methods, so a missing filter falls through to super
        # rather than recursing.
        def respond_to_missing?(name, include_private = false)
          return super unless surrender_filter_name?(name) && surrender_filter_scopes_pending?

          define_surrender_filter_scopes
          respond_to?(name, include_private)
        end

        def method_missing(name, ...)
          return super unless surrender_filter_name?(name) && surrender_filter_scopes_pending?

          define_surrender_filter_scopes
          public_send(name, ...)
        end

        private

        def surrender_filter_name?(name)
          name.start_with?(FILTER_PREFIX)
        end

        def surrender_filter_scopes_pending?
          !@surrender_filter_scopes_defined && surrender_filterable?
        end

        def define_surrender_filter_scopes
          @surrender_filter_scopes_defined = true
          define_surrender_column_scopes
          define_surrender_datetime_scopes
        end

        # ActiveRecord::Base itself is asked whether it responds to scope names while scopes are being defined.
        def surrender_filterable?
          self != ActiveRecord::Base && !abstract_class? && table_exists?
        end

        def define_surrender_column_scopes
          column_names.each do |column|
            scope :"#{FILTER_PREFIX}#{column}", ->(value) { where(column => value) }
          end
        end

        def define_surrender_datetime_scopes
          columns.select { |column| column.type.in? %i[date datetime] }.map(&:name).each do |column|
            name = "#{FILTER_PREFIX}#{column.delete_suffix('_at')}"
            attribute = arel_table[column]

            scope :"#{name}_to", ->(time) { where(attribute.lteq(time)) }
            scope :"#{name}_from", ->(time) { where(attribute.gteq(time)) }
            scope :"#{name}_before", ->(time) { where(attribute.lt(time)) }
            scope :"#{name}_after", ->(time) { where(attribute.gt(time)) }
          end
        end
      end
    end
  end
end
