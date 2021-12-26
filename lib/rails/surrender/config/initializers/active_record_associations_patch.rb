# frozen_string_literal: true
#
# ActiveRecord::Associations.class_eval do
#   # patching to prevent AssociationNotFoundError.
#   # if there is no association just return nil instead
#   def association(name) # :nodoc:
#     super
#   rescue AssociationNotFoundError
#     return nil
#   end
# end
#
# ActiveRecord::Relation.class_eval do
#   def eager_loading?
#     false
#   end
# end
