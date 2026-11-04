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

      # Serializes first-time scope definition across threads, so a concurrent lookup waits for the scopes rather
      # than reporting them missing. It is shared by all models because scopes are defined once per model.
      SCOPES_LOCK = Monitor.new

      # Generates the filter scopes on first lookup.
      module ClassMethods
        def respond_to_missing?(name, include_private = false)
          return super unless surrender_filter_name?(name) && surrender_filter_scopes_pending?

          define_surrender_filter_scopes
          surrender_filter_scopes_defined? ? respond_to?(name, include_private) : super
        end

        def method_missing(name, ...)
          return super unless surrender_filter_name?(name) && surrender_filter_scopes_pending?

          define_surrender_filter_scopes
          surrender_filter_scopes_defined? ? public_send(name, ...) : super
        end

        private

        def surrender_filter_name?(name)
          name.start_with?(FILTER_PREFIX)
        end

        def surrender_filter_scopes_pending?
          !surrender_filter_scopes_defined? && surrender_filterable?
        end

        def surrender_filter_scopes_defined?
          @surrender_filter_scopes_defined == true
        end

        # A lookup made while this thread is already defining the scopes returns without them, rather than
        # recursing. The flag is set only once every scope exists, so a failed attempt is retried next lookup.
        def define_surrender_filter_scopes
          SCOPES_LOCK.synchronize do
            return if surrender_filter_scopes_defined? || @surrender_filter_scopes_defining

            begin
              @surrender_filter_scopes_defining = true
              define_surrender_column_scopes
              define_surrender_datetime_scopes
              @surrender_filter_scopes_defined = true
            ensure
              @surrender_filter_scopes_defining = false
            end
          end
        end

        # ActiveRecord::Base itself is asked whether it responds to scope names while scopes are being defined.
        def surrender_filterable?
          self != ActiveRecord::Base && !abstract_class? && table_exists?
        end

        def define_surrender_column_scopes
          column_names.each do |column|
            define_surrender_filter_scope(column, ->(value) { where(column => value) })
          end
        end

        def define_surrender_datetime_scopes
          columns.select { |column| column.type.in? %i[date datetime] }.map(&:name).each do |column|
            name = column.delete_suffix('_at')
            attribute = arel_table[column]

            define_surrender_filter_scope("#{name}_to", ->(time) { where(attribute.lteq(time)) })
            define_surrender_filter_scope("#{name}_from", ->(time) { where(attribute.gteq(time)) })
            define_surrender_filter_scope("#{name}_before", ->(time) { where(attribute.lt(time)) })
            define_surrender_filter_scope("#{name}_after", ->(time) { where(attribute.gt(time)) })
          end
        end

        # Filters the application defines, on this model or a superclass, take precedence over generated ones.
        def define_surrender_filter_scope(name, body)
          scope_name = :"#{FILTER_PREFIX}#{name}"
          return if singleton_class.method_defined?(scope_name) || singleton_class.private_method_defined?(scope_name)

          scope scope_name, body
        end
      end
    end
  end
end
