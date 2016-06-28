Spree::Core::Engine.routes.draw do
  namespace :admin do
    resource :taxjar_settings
  end
end
