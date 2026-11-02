Rails.application.routes.draw do
  # "species" is uncountable, so the list page's helper is species_index_path
  resources :species
  resources :users, except: [:new]
  resources :aquariums do
    member do
      post 'add_species'
      delete 'remove_species'
    end
  end


  root to: "pages#home"
  get '/login', to: "sessions#new"
  post '/login', to: "sessions#create"
  delete '/logout', to: "sessions#destroy"
  get '/sign-up', to: "users#new"

  get 'search_species', to: 'species#search'


end
