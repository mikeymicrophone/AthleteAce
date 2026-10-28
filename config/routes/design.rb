# Design reference pages for the redesign, kept out of production
Rails.application.routes.draw do
  unless Rails.env.production?
    get "design/tokens" => "design#tokens", as: :design_tokens
  end
end
