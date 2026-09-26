# Routes for quest and achievement system
Rails.application.routes.draw do
  resources :achievements do
    collection do
      get :target_options
    end
  end
  
  resources :quests do
    resources :highlights, except: [:index, :show]
    resources :goals, only: [:create]
    collection do
      get :random
    end
  end
  
  resources :highlights, only: [:new, :create]
  resources :goals, only: [:index, :show, :update, :destroy]
end