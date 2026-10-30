# frozen_string_literal: true

class Book < ApplicationRecord
  belongs_to :author
  has_many :chapters

  scope :filter_by_long, ->(long) { long ? where(pages: 300..) : where(pages: ...300) }
  scope :sort_by_title_length, ->(direction) { order(Arel.sql("LENGTH(title) #{direction}")) }

  surrenders attributes: %i[id title genre],
             available_attributes: %i[pages published_at created_at chapter_ids],
             available_expands: %i[author chapters]
end
