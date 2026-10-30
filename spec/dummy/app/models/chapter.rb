# frozen_string_literal: true

class Chapter < ApplicationRecord
  belongs_to :book

  surrenders attributes: %i[id title position],
             expands: [:book]
end
