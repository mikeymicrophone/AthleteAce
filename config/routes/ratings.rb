# Routes for the rating system
Rails.application.routes.draw do
  # Base ratings resources
  resources :ratings
  resources :spectrums do
    resources :ratings
  end
  
  # Dynamic routes for all ratable models
  Rails.application.config.ratable_models.each do |model_name|
    resources model_name.underscore.pluralize.to_sym do
      resources :ratings, only: [:new, :create]
    end
  end
end
