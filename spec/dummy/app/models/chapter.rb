# frozen_string_literal: true

class Chapter < ApplicationRecord
  belongs_to :book

  surrenders :id, :title, :position, :book
end
