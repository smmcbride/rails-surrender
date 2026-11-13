# frozen_string_literal: true

# Reviews any resource, so specs cover surrender rejecting polymorphic expands.
class Review < ApplicationRecord
  belongs_to :reviewable, polymorphic: true

  surrenders :id, :body, :reviewable
end
