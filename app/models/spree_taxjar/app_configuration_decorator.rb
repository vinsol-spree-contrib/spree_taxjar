module SpreeTaxjar::AppConfigurationDecorator

  def self.prepended(base)
    base.preference :taxjar_enabled, :boolean, default: false
    base.preference :taxjar_debug_enabled, :boolean, default: false
    base.preference :taxjar_api_key, :string
  end
end

Spree::AppConfiguration.prepend SpreeTaxjar::AppConfigurationDecorator