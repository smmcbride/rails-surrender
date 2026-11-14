# frozen_string_literal: true

Rails.application.routes.draw do
  resources :authors, only: %i[index show]
  resources :books, only: %i[index show] do
    collection do
      get :unpaginated
      get :featured
      get :decorated
      get :without_author
      get :summary
    end
  end
  resources :chapters, only: %i[index]
end
