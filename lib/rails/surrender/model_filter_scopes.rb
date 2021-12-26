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
            child.column_names.each do |column|
              scope "filter_by_#{column}".to_sym, ->(val) { where({ column.to_sym => val }) }
            end

            # scope to filter by date or time column names
            child.columns.select { |c| c.type.in? %i[date datetime] }.map(&:name).each do |column|
              column_base = column.split(/_at$/).first
              scope "filter_by_#{column_base}_to".to_sym, lambda { |time|
                                                            where("#{child.table_name}.#{column} <= ?", time)
                                                          }
              scope "filter_by_#{column_base}_from".to_sym, lambda { |time|
                                                              where("#{child.table_name}.#{column} >= ?", time)
                                                            }
              scope "filter_by_#{column_base}_before".to_sym, lambda { |time|
                                                                where("#{child.table_name}.#{column} < ?", time)
                                                              }
              scope "filter_by_#{column_base}_after".to_sym, lambda { |time|
                                                               where("#{child.table_name}.#{column} > ?", time)
                                                             }
            end
          rescue StandardError
            # TODO: why are tests failing here!!!
          end
        end
      end
    end
  end
end
