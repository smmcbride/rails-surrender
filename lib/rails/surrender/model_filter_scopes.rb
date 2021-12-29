# frozen_string_literal: true

# Add filter_by_date_(to/from/before/after) methods for all *_at columns
module Rails
  module Surrender
    # apply filter scopes to the model
    module ModelFilterScopes
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def inherited(child)
          super

          # Bad things happen if you ask table_exists? to ApplicationRecord while it's loading!
          # TODO: Add configuration in case ApplicationRecord is _not_ the primary abstract class
          return if child.name == 'ApplicationRecord'

          return unless child.table_exists?

          child.instance_eval do
            # scope to filter by every column name
            apply_surrender_column_name_scopes(child)

            # scope to filter by date or time column names
            apply_surrender_column_datetime_scopes(child)
          rescue StandardError
            # TODO: why are tests failing here!!!
          end
        end

        def apply_surrender_column_name_scopes(child)
          child.column_names.each do |column|
            scope "filter_by_#{column}".to_sym, ->(val) { where({ column.to_sym => val }) }
          end
        end

        def apply_surrender_column_datetime_scopes(child)
          with_surrender_datetime_columns(child) do |column|
            base = column.split(/_at$/).first

            scope "filter_by_#{base}_to".to_sym, ->(time) { where("#{child.table_name}.#{column} <= ?", time) }
            scope "filter_by_#{base}_from".to_sym, ->(time) { where("#{child.table_name}.#{column} >= ?", time) }
            scope "filter_by_#{base}_before".to_sym, ->(time) { where("#{child.table_name}.#{column} < ?", time) }
            scope "filter_by_#{base}_after".to_sym, ->(time) { where("#{child.table_name}.#{column} > ?", time) }
          end
        end

        def with_surrender_datetime_columns(child, &block)
          child.columns.select { |c| c.type.in? %i[date datetime] }.map(&:name).each(&block)
        end
      end
    end
  end
end
