# frozen_string_literal: true

module Rails
  module Surrender
    class Selection
      # Orders a model's records by a request's sort, such as `title`, `-pages` or `author.name`. A leading - sorts
      # descending; a leading + or none sorts ascending.
      module Sorting
        extend ActiveSupport::Concern

        SORT_PREFIX = 'sort_by_'

        # Resolves a request's sort against the model.
        module ClassMethods
          # A sort_by_ scope the model defines wins over its columns, as filter_by_ scopes the model defines win over
          # generated ones. Each scope takes the direction, 'ASC' or 'DESC'.
          def surrender_sort(sort)
            name = sort.strip.delete_prefix('-').delete_prefix('+')
            direction = sort.strip.start_with?('-') ? :desc : :asc
            scope = :"#{SORT_PREFIX}#{name.tr('.', '_')}"

            return public_send(scope, direction.to_s.upcase) if respond_to?(scope)
            return order(name => direction) if attribute_names.include?(name)

            surrender_sort_by_association(name, direction) ||
              raise(Error, I18n.t('surrender.error.query_string.sort.invalid_column', param: sort))
          end

          # The sorts a request may name: the model's columns, the columns of its singular associations, and the sorts
          # it defines.
          def surrender_sort_names
            associated = reflect_on_all_associations.select { |reflection| surrender_sortable?(reflection) }
                                                    .flat_map do |reflection|
              reflection.klass.attribute_names.map { |attribute| "#{reflection.name}.#{attribute}" }
            end
            defined = methods.grep(/\A#{SORT_PREFIX}/o).map { |scope| scope.to_s.delete_prefix(SORT_PREFIX) }.sort
            (attribute_names + associated + defined).uniq
          end

          private

          # `author.name` sorts by the name of each record's author.
          def surrender_sort_by_association(name, direction)
            association, attribute = name.split('.', 2)
            reflection = attribute && reflect_on_association(association)
            return unless reflection && surrender_sortable?(reflection)
            return unless reflection.klass.attribute_names.include?(attribute)

            joins(reflection.name).order(reflection.klass.arel_table[attribute].public_send(direction))
          end

          # Joining an association that holds many records would repeat each record once per associated one. Nothing
          # can name a polymorphic association's class before records load.
          def surrender_sortable?(reflection)
            !reflection.collection? && !reflection.polymorphic?
          end
        end
      end
    end
  end
end
