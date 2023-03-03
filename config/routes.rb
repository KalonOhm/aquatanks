Rails.application.routes.draw do
  resources :fishes
  resources :users, except: [:new]
  resources :aquariums
  resources :aquariums do 
    member do
      post 'add_fish'
    end
  end


  root to: "pages#home"
  get '/login', to: "sessions#new"
  post '/login', to: "sessions#create"
  delete '/logout', to: "sessions#destroy"
  get '/sign-up', to: "users#new"

  get 'search_fishes', to: 'fishes#search'

  
end
