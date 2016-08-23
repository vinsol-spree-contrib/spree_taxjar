module Spree
  module Admin
    class TaxjarSettingsController < Spree::Admin::BaseController
      def edit
        @preferences_api = [:taxjar_api_key]
      end

      def update
        params.each do |name, value|
          Spree::Config[name] = value if Spree::Config.has_preference? name
        end

        flash[:success] = Spree.t(:api_key_updated)
        redirect_to edit_admin_taxjar_settings_path
      end

    end
  end
end
