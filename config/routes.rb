Rails.application.routes.draw do
  resources :fishes
  resources :users, except: [:new]
  resources :aquariums

  root to: "pages#home"
  get '/login', to: "sessions#new"
  post '/login', to: "sessions#create"
  delete '/logout', to: "sessions#destroy"
  get '/sign-up', to: "users#new"
end
