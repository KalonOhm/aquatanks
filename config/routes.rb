Rails.application.routes.draw do
  resources :fishes
  resources :users, except: [:new]
  resources :aquariums
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"

  root to: "pages#home"
  
end
