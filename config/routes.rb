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
    resources :point_comments, only: [:new, :create]
  end

  resources :documents do
    resources :document_comments, only: [:new, :create]
  end
  post "documents/new", to: "documents#create"
  post "documents/:id/edit", to: "documents#update"
  post "documents/:id/crawl", to: "documents#crawl", as: :document_crawl

  resources :services, except: [:show]
  resources :services, except: [:index] do
    resources :points, only: [:new, :create]
    resources :service_comments, only: [:new, :create]
  end
  get "services/:id/annotate", to: "services#annotate", as: "annotate"
  get "services/:id/annotate?point_id=:point_id", to: "services#annotate", as: "annotate_point"
  post "services/:id/annotate", to: "services#quote"

  resources :topics do
    resources :topic_comments, only: [:new, :create]
  end

  resources :cases do
    resources :case_comments, only: [:new, :create]
  end

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :topics, only: [ :index, :show ]
      resources :services, only: [ :index, :show ]
      resources :points, only: [ :index, :show ]
    end
  end
end
