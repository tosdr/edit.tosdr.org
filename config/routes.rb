Rails.application.routes.draw do
  devise_for :users
  root to: 'pages#home'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  resources :points do
    put "/is_featured", to: "points#featured", as: :featured
    resources :reasons, only: [:new, :create]
  end
  resources :services
  resources :topics


end
