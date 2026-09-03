Rails.application.routes.draw do
  get "components/index"
  devise_for :users
  root to: "pages#home"
  resources :reviews, only: [:index]
  resources :go_meal_matches, only: [:index, :show] do
    member do
      patch :like
      patch :reject
      patch :not_visited
      patch :dismiss_rate_prompt
    end
    resource :itinerary, only: [:show]
    resource :review, only: [:new, :create, :edit, :update, :destroy]
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  get "components", to: "components#index"


  # Render dynamic PWA files from app/views/pwa/*
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"

  resource :locations, only: [:show, :create, :update]
  resource :preferences, only: [:show, :edit, :update] do
    get :cuisines
    patch :cuisines, action: :update_cuisines
    post :retry_matches
  end
end
