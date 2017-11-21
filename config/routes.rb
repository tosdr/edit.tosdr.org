Rails.application.routes.draw do
  ActiveAdmin.routes(self)
  devise_for :users
  root to: 'pages#home'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get 'my_points', to: 'points#user_points', as: :my_points

  resources :points do
    member do
      put "/is_featured", to: "points#featured", as: :featured
    end
    # collection do # if we dont need the id in the route!
    #   get 'top-3', to: "points#top_3"
    # end
    resources :reasons, only: [:new, :create]
  end
  resources :services
  resources :topics

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :topics, only: [ :index ]
      resources :services, only: [ :index ]
      resources :points, only: [ :index ]
    end
  end
end
