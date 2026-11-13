# frozen_string_literal: true

module Rails
  module Surrender
    class Selection
      # Adds a filter_by_<column> scope for every column, and filter_by_<name>_before/after scopes for date and
      # time columns, where <name> drops any _at suffix. The before/after scopes take a Time or Date, or an ISO 8601
      # string, and raise Rails::Surrender::Error for anything else.
      #
      # The scopes are defined the first time any filter_by_ method is looked up, rather than when the class is
      # defined, so that loading a model never touches the database.
      module Filtering
        extend ActiveSupport::Concern

        FILTER_PREFIX = 'filter_by_'

        # Serializes first-time scope definition across threads, so a concurrent lookup waits for the scopes rather
        # than reporting them missing. It is shared by all models because scopes are defined once per model.
        SCOPES_LOCK = Monitor.new

        # Applies a request's filters, and generates the filter scopes on first lookup.
        module ClassMethods
          # Applies the filter_by_ scope a request's filter names, trying an association's foreign key (`author` for
          # filter_by_author_id) when the name alone has no scope. Only filter_by_ scopes are reachable this way.
          def surrender_filter(name, value)
            scope = surrender_filter_scopes_for(name).find { |candidate| respond_to?(candidate) }
            raise Error, I18n.t('surrender.error.query_string.filter.not_available', param: name) unless scope

            public_send(scope, value)
          end

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

          def surrender_filter_scopes_for(name)
            scope = :"#{FILTER_PREFIX}#{name.to_s.tr('.', '_')}"
            [scope, :"#{scope}_id"]
          end

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
            # Scope bodies run against a relation, which can't call the model's private methods, so they close over it.
            to_time = method(:surrender_filter_time)

            columns.select { |column| column.type.in? %i[date datetime] }.map(&:name).each do |column|
              name = column.delete_suffix('_at')
              attribute = arel_table[column]

              define_surrender_filter_scope("#{name}_before", lambda { |time|
                where(attribute.lt(to_time.call("#{name}_before", time)))
              })
              define_surrender_filter_scope("#{name}_after", lambda { |time|
                where(attribute.gt(to_time.call("#{name}_after", time)))
              })
            end
          end

          # Strict, so a value that is not a time is rejected rather than compared as NULL, which matches nothing.
          # A time without an offset is in the app's time zone.
          def surrender_filter_time(filter, value)
            return value if value.is_a?(Date) || value.acts_like?(:time)

            Time.zone.iso8601(value.to_s)
          rescue ArgumentError
            raise Error, I18n.t('surrender.error.query_string.filter.invalid_time', param: filter, value: value)
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
end
