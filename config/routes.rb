Rottenpotatoes::Application.routes.draw do
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products
  resources :movies do
    member do
      get :director
      get :score
      get :viewed_with
    end
    collection do
      get 'benchmark/:type'
    end
  end
  
  get 'movies/director/:id' => 'movies#director', :as => :movies_director
  get 'movies/score/:id' => 'movies#score', :as => :movies_score
  get 'movies/viewed_with/:id' => 'movies#viewed_with', :as => :movies_viewed_with
  get '/benchmark/:type' => 'movies#benchmark', :as => :benchmark

end
