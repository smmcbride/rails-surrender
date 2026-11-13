# frozen_string_literal: true

require_relative 'asks'
require_relative 'attribute'
require_relative 'expand'
require_relative 'id_list'

module Rails
  module Surrender
    module Fields
      # The fields one model renders at one place in the field tree, with a branch below each expand.
      class Node
        attr_reader :branches

        # `above` holds the base class of every model from the top of the tree down to this one.
        def initialize(model, asks, above)
          @model = model
          @asks = asks
          @above = above
          reject_unavailable_request_includes
          @fields = ordered(rendered_fields)
          @branches = @fields.to_h { |field| [field.name, field.branch(asks: asks, above: above)] }.compact
          @variants = { model => self }
        end

        # An STI subclass renders its own fields. Its variant is built when one of its records first appears,
        # because subclasses aren't known before they load in development.
        def for(klass)
          @variants[klass] ||= Node.new(klass, @asks, @above)
        end

        def preloads
          @fields.filter_map(&:preload)
        end

        def render(record, ability)
          @fields.each_with_object({}) do |field, rendered|
            field.write(record, into: rendered, ability: ability, branch: @branches[field.name])
          end
        end

        def to_h
          @fields.to_h { |field| [field.name, field.describe(@branches[field.name])] }
        end

        # Nodes are equal when they render the same fields, so a level loads each association once for all of them.
        def eql?(other)
          other.is_a?(Node) && identity == other.identity
        end

        alias == eql?

        def hash
          identity.hash
        end

        protected

        def identity
          [@model, @asks, @above]
        end

        private

        def reject_unavailable_request_includes
          unavailable = @asks.request_includes.reject { |name| @model.surrenders?(name) }
          return if unavailable.empty?

          raise Error, I18n.t('surrender.error.query_string.include.not_available', param: unavailable)
        end

        def rendered_fields
          (@model.surrender_fields + @asks.controller_includes + @asks.request_includes)
            .uniq
            .reject { |name| @asks.excludes?(name) }
            .map { |name| @model.surrender_field(name) }
            .reject { |field| field.circular?(@above) }
        end

        def ordered(fields)
          fields.each_with_index.sort_by { |field, position| [field.rank, position] }.map(&:first)
        end
      end
    end
  end
end
