# frozen_string_literal: true

class Author < ApplicationRecord
  has_many :books

  surrenders attributes: %i[id name],
             available_attributes: %i[created_at book_ids],
             available_expands: [:books]
end
