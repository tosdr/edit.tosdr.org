Rails.application.routes.draw do
  ActiveAdmin.routes(self)
  devise_for :users
  root to: 'pages#home'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get 'my_points', to: 'points#user_points', as: :my_points

  get 'about', to: 'pages#about'

  get 'points/new', to: 'points#new'
  get 'points/:id/is_featured', to: 'points#featured', as: :featured_point
  resources :points, only: :index, path: "points/(:scope)", scope: /[a-z\-_]*/, as: :points
  resources :points, except: [:index] do
    resources :reasons, only: [:new, :create]
  end

  resources :services, except: [:show]
  get "services/:id/(:scope)", to: "services#show", scope: /[a-z\-_]*/

  resources :topics

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :topics, only: [ :index, :show ]
      resources :services, only: [ :index, :show ]
      resources :points, only: [ :index, :show ]
    end
  end
end
