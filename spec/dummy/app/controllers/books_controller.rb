# frozen_string_literal: true

class BooksController < ApplicationController
  surrender_options :featured, include: [:pages], exclude: [:genre]
  surrender_options :unpaginated, paginate: false
  # A collection route that finds a single record.
  surrender_options :bestseller, collection: false
  # Surrenders a hash, which no model shapes.
  surrender_options :summary, menu: false

  def index
    surrender Book.all
  end

  def show
    surrender Book.find(params[:id])
  end

  # A member route the app menu tells is a single record by the id in its path.
  def cover
    surrender Book.find(params[:id])
  end

  def bestseller
    surrender Book.order(:pages).last
  end

  def unpaginated
    surrender Book.all
  end

  # Skips pagination as it runs, which the app menu can't see.
  def skips_pagination
    skip_pagination
    surrender Book.all
  end

  def featured
    surrender Book.all
  end

  # Excludes as it surrenders, which the app menu can't see.
  def without_author
    surrender Book.all, exclude: [:author]
  end

  def decorated
    surrender(Book.all) { |data| { books: data } }
  end

  def summary
    surrender({ shelves: 3 })
  end
end
