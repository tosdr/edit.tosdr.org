Rails.application.routes.draw do

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
  get 'points/:id/review', to: 'points#review', as: "review"
  patch 'points/:id/review', to: 'points#post_review'
  resources :points, only: :index, path: "points/(:scope)", scope: /[a-z\-_]*/, as: :points
  resources :points, except: [:index] do
    resources :comments, only: [:new, :create]
  end

  resources :documents
  post "documents/new", to: "documents#create"
  post "documents/:id/edit", to: "documents#update"

  resources :services, except: [:show]
  resources :services, except: [:index] do
    resources :points, only: [:new, :create]
  end
  get "services/:id/annotate", to: "services#annotate", as: "annotate"
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
