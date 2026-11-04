# frozen_string_literal: true

ActiveRecord::Schema.define do
  self.verbose = false

  create_table :authors do |t|
    t.string :name, null: false
    t.timestamps
  end

  create_table :books do |t|
    t.references :author
    t.references :prequel
    t.string :type
    t.string :title, null: false
    t.string :genre
    t.integer :pages
    t.datetime :published_at
    t.timestamps
  end

  create_table :chapters do |t|
    t.references :book
    t.string :title, null: false
    t.integer :position
    t.timestamps
  end
end
