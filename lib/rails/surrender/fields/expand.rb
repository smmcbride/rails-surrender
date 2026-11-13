# frozen_string_literal: true

module Rails
  module Surrender
    module Fields
      # A field that names an association and renders as the nested resource, with the fields of its branch.
      Expand = Data.define(:name, :reflection) do
        def rank
          3
        end

        def kind
          :expand
        end

        def preload
          name
        end

        # Surrender never renders a model inside itself, and STI subclasses count as their base class.
        def circular?(above)
          target.base_class.in?(above)
        end

        def branch(asks:, above:)
          Node.new(target, asks.below(name), above + [target.base_class])
        end

        def menu(above:)
          Menu.new(target, above: above + [target.base_class])
        end

        # The record at the top is never checked against the ability, only the records nested in it.
        def write(record, into:, ability:, branch:)
          value = record.public_send(name)

          if reflection.collection?
            into[name] = value.select { |nested| ability.can?(:read, nested) }
                              .map { |nested| branch.for(nested.class).render(nested, ability) }
          elsif value.nil?
            into[name] = nil
          elsif ability.can?(:read, value)
            into[name] = branch.for(value.class).render(value, ability)
          end
        end

        def describe(branch)
          branch.to_h
        end

        private

        # A polymorphic association has no class until a record loads, but the tree is worked out before any do.
        def target
          if reflection.polymorphic?
            raise ArgumentError,
                  "surrender can't expand the polymorphic association #{reflection.active_record}##{name}"
          end

          reflection.klass
        end
      end
    end
  end
end
