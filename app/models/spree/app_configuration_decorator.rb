Spree::AppConfiguration.class_eval do
  preference :taxjar_api_key, :string
  preference :taxjar_enabled, :boolean, default: false
  preference :taxjar_debug_enabled, :boolean, default: false
end
