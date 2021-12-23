# frozen_string_literal: true

module Rails
  module Surrender
    module ModelAdditions
      def self.included(base)
        attr_accessor :surrender_attributes
        attr_accessor :surrender_expands
        attr_accessor :surrender_skip_expands
        attr_accessor :surrender_available_attributes
        attr_accessor :surrender_available_expands

        base.extend(ClassMethods)
      end

      module ClassMethods
        def surrenders(*args)
          opts = args.extract_options!

          # Run through the various lists of attributes and assign them to the rendering context
          # If the superclass has attributes then consume those as well.
          %w(attributes expands skip_expands available_attributes available_expands).each do |attr|
            surrender_attr = ['surrender', attr].join('_')
            list = []
            if superclass.instance_variable_defined?("@#{surrender_attr}")
              list << superclass.instance_variable_get("@#{surrender_attr}")
            end
            list << opts[attr.to_sym] if opts.key?(attr.to_sym)
            instance_variable_set("@#{surrender_attr}", list.flatten.uniq)
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

        def surrender_skip_expands
          @surrender_skip_expands ||= []
        end

        def surrender_available_expands
          @surrender_available_expands ||= []
        end

        def can_call_attribute?(attr)
          surrender_attributes.include?(attr.to_sym) || surrender_available_attributes.include?(attr.to_sym)
        end

        def can_call_expand?(attr)
          surrender_expands.include?(attr.to_sym) || surrender_available_expands.include?(attr.to_sym)
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

# Add filter_by_date_(to/from/before/after) methods for all *_at columns
class ActiveRecord::Base
  def self.inherited(child)
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
        scope "filter_by_#{column_base}_to".to_sym,     ->(time) { where("#{child.table_name}.#{column} <= ?", time) }
        scope "filter_by_#{column_base}_from".to_sym,   ->(time) { where("#{child.table_name}.#{column} >= ?", time) }
        scope "filter_by_#{column_base}_before".to_sym, ->(time) { where("#{child.table_name}.#{column} < ?", time) }
        scope "filter_by_#{column_base}_after".to_sym,  ->(time) { where("#{child.table_name}.#{column} > ?", time) }
      end
    rescue StandardError
      # TODO: why are tests failing here!!!
    end
  end
end
