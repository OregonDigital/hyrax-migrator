# frozen_string_literal: true

Hyrax::Migrator::Engine.routes.draw do
  root 'home#index'

  resources :profiles, only: [:show]

  resources :batches, only: [:show]
end
