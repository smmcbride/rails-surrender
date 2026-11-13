# frozen_string_literal: true

class Book < ApplicationRecord
  belongs_to :author
  belongs_to :prequel, class_name: 'Novel', optional: true
  has_many :chapters

  # Overrides the generated equality filter, so specs can check generation leaves it alone.
  scope :filter_by_genre, ->(genre) { where(genre: genre.downcase) }
  scope :filter_by_long, ->(long) { long ? where(pages: 300..) : where(pages: ...300) }
  scope :sort_by_title_length, ->(direction) { order(Arel.sql("LENGTH(title) #{direction}")) }

  surrenders :id, :title, :genre,
             available: %i[pages published_at created_at chapter_ids author chapters prequel]
end
