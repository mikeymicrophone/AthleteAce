# Routes for the rating system
Rails.application.routes.draw do
  # Base ratings resources
  resources :ratings
  resources :spectrums do
    resources :ratings, only: [:index]
  end
  
  # Dynamic routes for all ratable models (the models' own routes live in sports.rb)
  Rails.application.config.ratable_models.each do |model_name|
    resources model_name.underscore.pluralize.to_sym, only: [] do
      resources :ratings, only: [:new, :create] do
        collection do
          get :for_spectrums
        end
      end
    end
  end
end
