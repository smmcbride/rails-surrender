# frozen_string_literal: true

class AuthorsController < ApplicationController
  def index
    surrender Author.all
  end

  def show
    surrender Author.find(params[:id])
  end
end
