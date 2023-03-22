Rails.application.routes.draw do
  ActiveAdmin.routes(self)
  devise_for :users, controllers: {
    sessions: 'users/sessions'
  }, only: [:destroy]

  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }

  mount ApplicationInteraction::Base => ''

  root to: 'pages#home'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get 'about', to: 'pages#about'
  get 'flag_spam', to: 'spam#flag_as_spam', as: 'flag_as_spam'

  get 'my_points', to: 'points#user_points', as: :my_points
  get 'points/:id/review', to: 'points#review', as: 'review'
  get 'points/:id/approve', to: 'points#approve', as: 'approve'
  patch 'points/:id/review', to: 'points#post_review'
  resources :points, only: :index
  resources :points, except: [:index] do
    resources :point_comments, only: %i[new create]
  end

  resources :documents do
    resources :document_comments, only: %i[new create]
  end
  post 'documents/new', to: 'documents#create'
  post 'documents/:id/edit', to: 'documents#update'
  post 'documents/:id/crawl', to: 'documents#crawl', as: :document_crawl
  post 'documents/:id/restore_points', to: 'documents#restore_points', as: :document_restore_points

  # api endpoints for vue
  get 'services/list_all', to: 'services#list_all', as: 'list_all_services'

  # traditional rails routes
  resources :services, except: [:show]
  resources :services, except: [:index] do
    resources :points, only: %i[new create]
    resources :service_comments, only: %i[new create]
  end

  # routes for annotation functionality
  get 'services/:id/annotate', to: 'services#annotate', as: 'annotate'
  get 'services/:id/annotate?point_id=:point_id', to: 'services#annotate', as: 'annotate_point'
  post 'services/:id/annotate', to: 'services#quote'

  resources :topics do
    resources :topic_comments, only: %i[new create]
  end

  # api endpoints for vue
  get 'cases/list_all', to: 'cases#list_all', as: 'list_all_cases'
  resources :cases do
    resources :case_comments, only: %i[new create]
  end
end
