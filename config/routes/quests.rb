# Routes for quest and achievement system
Rails.application.routes.draw do
  resources :achievements do
    collection do
      get :target_options
    end
  end
  
  resources :quests do
    resources :highlights
    resources :goals, only: [:create]
    collection do
      get :random
    end
  end
  
  resources :highlights, only: [:new, :create]
  resources :goals, except: [:create, :new]
end