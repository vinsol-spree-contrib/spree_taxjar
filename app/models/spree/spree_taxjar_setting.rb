module Spree
  class SpreeTaxjarSetting < Preferences::Configuration
    preference :taxjar_enabled, :boolean, default: false
    preference :taxjar_debug_enabled, :boolean, default: false
    preference :taxjar_api_key, :string
  end
end