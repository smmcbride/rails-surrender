# frozen_string_literal: true

class BooksController < ApplicationController
  def index
    surrender Book.all
  end

  def show
    surrender Book.find(params[:id])
  end

  def unpaginated
    skip_pagination
    surrender Book.all
  end

  def featured
    surrender Book.all, include: [:pages], exclude: [:genre]
  end

  def without_author
    surrender Book.all, exclude: [:author]
  end

  def decorated
    surrender(Book.all) { |data| { books: data } }
  end
end
