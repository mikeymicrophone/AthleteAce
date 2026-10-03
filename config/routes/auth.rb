# Authentication and user-related routes
Rails.application.routes.draw do
  devise_for :aces, controllers: { registrations: "aces/registrations" }
end
