Rails.application.routes.draw do
  get 'points/index'

  get 'points/create'

  get 'points/new'

  get 'points/edit'

  get 'points/show'

  get 'points/update'

  get 'points/destroy'

  devise_for :users
  root to: 'pages#home'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  resources :points
end
