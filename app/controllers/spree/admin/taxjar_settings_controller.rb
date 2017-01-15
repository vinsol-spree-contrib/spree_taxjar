module Spree
  module Admin
    class TaxjarSettingsController < Spree::Admin::BaseController
      def edit
        @preferences_api = [:taxjar_api_key, :taxjar_enabled, :taxjar_debug_enabled]
      end

      def update
        Spree::Config[:taxjar_api_key] = params[:taxjar_api_key]
        Spree::Config[:taxjar_enabled] = params[:taxjar_enabled]
        Spree::Config[:taxjar_debug_enabled] = params[:taxjar_debug_enabled]

        flash[:success] = Spree.t(:taxjar_settings_updated)
        redirect_to edit_admin_taxjar_settings_path
      end

    end
  end
end
