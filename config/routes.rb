Rails.application.routes.draw do
  get 'document/index'

  get 'document/show'

  get 'document/new'

  get 'document/edit'

  ActiveAdmin.routes(self)
  devise_for :users, controllers: {
    sessions: 'users/sessions'
  }, only: [ :destroy ]

  devise_for :users, controllers: {
   :sessions => "users/sessions",
   :registrations => "users/registrations" }

   root to: 'pages#home'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get 'my_points', to: 'points#user_points', as: :my_points

  get 'about', to: 'pages#about'


  get 'points/new', to: 'points#new'
  put 'points/:id/is_featured', to: 'points#featured', as: :featured_point
  resources :points, only: :index, path: "points/(:scope)", scope: /[a-z\-_]*/, as: :points
  resources :points, except: [:index] do
    resources :comments, only: [:new, :create]
  end

  resources :doc_revisions

  resources :services, except: [:show]
  resources :services, except: [:index] do
    resources :points, only: [:new, :create]
  end
  get "services/:id/annotate", to: "services#annotate"
  post "services/:id/annotate", to: "services#quote"

  get "services/:id/(:scope)", to: "services#show", scope: /[a-z\-_]*/

  resources :topics
  resources :cases

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :topics, only: [ :index, :show ]
      resources :services, only: [ :index, :show ]
      resources :points, only: [ :index, :show ]
    end
  end
end
