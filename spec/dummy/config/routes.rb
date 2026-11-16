# frozen_string_literal: true

Rails.application.routes.draw do
  resources :authors, only: %i[index show]
  # Redirects and other verbs aren't on the app menu.
  get '/library', to: redirect('/books')
  resources :books, only: %i[index show create] do
    collection do
      get :bestseller
      get :unpaginated
      get :skips_pagination
      get :featured
      get :decorated
      get :without_author
      get :summary
    end
    get :cover, on: :member
  end
  resources :chapters, only: %i[index]
end
