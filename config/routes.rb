Rails.application.routes.draw do
  devise_for :users
  root to: 'pages#home'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  resources :points do
    resources :reasons, only: [:new, :create]
  end
  resources :services
  resources :topics
end
