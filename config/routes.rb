# AthleteAce Routes
# Routes are split into modular files for better organization

# Load filterable route helper
require_relative 'routes/filterable'

Rails.application.routes.draw do
  # Load modular route files
  draw :auth          # Authentication (Devise)
  draw :sports        # Core sports resources (index/show only)
  draw :locations     # Filterable location resources (auto-generated)
  draw :ratings       # Rating system
  draw :quests        # Quest and achievement system
  draw :games         # Strength training and games
  draw :design        # Design reference pages (not in production)

  get "feed", to: "feed#index", as: :feed
  resource :wallet, only: [ :show, :create ]
  resources :stripe_purchases, only: :show do
    post :pay, on: :member
  end
  post "stripe/webhook", to: "stripe_webhooks#create"
  resources :shout_outs, only: [ :index, :show, :create ] do
    post :pay, on: :member
  end
  resources :shout_out_drafts, path: "feed/drafts", except: :show do
    collection { get :targets }
  end
  resources :follows, only: [ :create, :destroy ]
  resources :player_groups
  get "browse", to: "browse#index", as: :browse
  get "admin", to: "admin#index", as: :admin
  resource :theme_preference, only: :update
  get "search", to: "searches#index", as: :search
  resources :ace_profiles, only: :show, path: "moderate/aces"

  get "moderate", to: "moderation#index", as: :moderation
  get "moderate/log", to: "moderation#log", as: :moderation_log
  get "moderate/:type/:id", to: "moderation#show", as: :moderation_item
  patch "moderate/:type/:id", to: "moderation#update"
  post "moderate/:type/:id/compare", to: "moderation#compare", as: :compare_moderation_item

  # Application health check
  get "up" => "rails/health#show", as: :rails_health_check

  # PWA manifest and service worker (commented out - uncomment if needed)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Root route
  root "home#index"
end
