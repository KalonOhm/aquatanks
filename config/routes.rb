Rails.application.routes.draw do
  # "species" is uncountable, so the list page's helper is species_index_path
  resources :species
  resources :users, except: [:new] do
    get 'avatar/:variant', action: :avatar, on: :member, as: :avatar
  end
  resources :aquariums do
    member do
      # Uploaded pictures are served through these, not Active Storage's routes (see ApplicationController#send_photo)
      get 'photo/:variant', action: :photo, as: :photo
      # The tank's gallery: view one photo, upload more, delete one, or make one the main photo
      get 'gallery/:photo_id/:variant', action: :gallery_photo, as: :gallery_photo
      post 'gallery', action: :add_gallery_photos, as: :gallery_photos
      delete 'gallery/:photo_id', action: :remove_gallery_photo, as: :remove_gallery_photo
      patch 'gallery/:photo_id/feature', action: :feature_gallery_photo, as: :feature_gallery_photo
      post 'add_species'
      delete 'remove_species'
    end
  end


  root to: "pages#home"
  get '/faq', to: "pages#faq"
  get '/login', to: "sessions#new"
  post '/login', to: "sessions#create"
  delete '/logout', to: "sessions#destroy"
  get '/sign-up', to: "users#new"

  get 'search_species', to: 'species#search'


end
