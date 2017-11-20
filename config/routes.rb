Rails.application.routes.draw do
  get 'user/index'

  get 'user/new'

  get 'user/show'

  get 'user/create'

  get 'user/update'

  get 'user/destroy'

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


end

# def upvote
#   @point = Point.find(params[:id])
#   @point.votes += 1
#   redirect_to point_path
# end

# def top_3
#   @top_points = Point.where(likes: 5).limit(3)
# end
