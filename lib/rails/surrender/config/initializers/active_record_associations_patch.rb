# frozen_string_literal: true

ActiveRecord::Associations.class_eval do
  # patching to prevent AssociationNotFoundError.
  # if there is no association just return nil instead
  # Returns the association instance for the given name, instantiating it if it doesn't already exist
  def association(name) # :nodoc:
    association = association_instance_get(name)

    if association.nil?
      reflection = self.class._reflect_on_association(name)
      return nil unless reflection

      # raise AssociationNotFoundError.new(self, name) unless reflection = self.class._reflect_on_association(name)
      association = reflection.association_class.new(self, reflection)
      association_instance_set(name, association)
    end

    association
  end
end

ActiveRecord::Relation.class_eval do
  def eager_loading?
    false
  end
end
