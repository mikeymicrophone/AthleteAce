# Authentication and user-related routes
Rails.application.routes.draw do
  devise_for :aces, controllers: { registrations: "aces/registrations", sessions: "aces/sessions" }
  resource :profile, only: [ :show, :edit, :update ]
end
