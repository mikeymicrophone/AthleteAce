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

  # Application health check
  get "up" => "rails/health#show", as: :rails_health_check

  # PWA manifest and service worker (commented out - uncomment if needed)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Root route
  root "players#index"
end