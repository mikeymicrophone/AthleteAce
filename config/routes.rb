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
  get "feed/leaders", to: "shout_out_leaderboards#index", as: :shout_out_leaderboard
  resources :feed_posts, path: "feed/posts", only: :show
  resource :wallet, only: [ :show, :create ]
  resources :stripe_purchases, only: :show do
    post :pay, on: :member
  end
  post "stripe/webhook", to: "stripe_webhooks#create"
  resources :shout_outs, only: [ :index, :show, :create ] do
    post :pay, on: :member
    resources :shout_out_reports, path: "reports", only: [ :new, :create ]
    resources :shout_out_reactions, path: "reactions", param: :kind, only: [ :update, :destroy ]
  end
  resources :shout_out_drafts, path: "feed/drafts", except: :show do
    collection { get :targets }
  end
  resources :follows, only: [ :create, :destroy ]
  resources :player_groups
  get "browse", to: "browse#index", as: :browse
  namespace :admin do
    resources :people, only: [ :index, :show, :update ]
    resources :catalog_records, path: "sports-data", only: [ :index, :edit, :update ]
    resources :catalog_edits, only: [ :index, :show, :update ]
  end
  get "admin", to: "admin#index", as: :admin
  resource :shout_out_revenue, path: "admin/revenue", only: :show
  resource :theme_preference, only: :update
  get "search", to: "searches#index", as: :search
  resource :posting_status, only: :show, path: "account/posting"
  resources :ace_profiles, only: :show, path: "moderate/aces" do
    resources :posting_actions, only: :create
  end

  get "moderate", to: "moderation#index", as: :moderation
  get "moderate/log", to: "moderation#log", as: :moderation_log
  resources :escalations, path: "moderate/escalations", only: [ :index, :show, :create, :update ]
  resources :reports, path: "moderate/reports", only: [ :index, :show, :update ]
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
