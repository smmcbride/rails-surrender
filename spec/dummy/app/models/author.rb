# frozen_string_literal: true

class Author < ApplicationRecord
  # Declared before the association it names, so specs cover fields being sorted when read.
  surrenders :id, :name, available: %i[created_at book_ids books]

  has_many :books
end
