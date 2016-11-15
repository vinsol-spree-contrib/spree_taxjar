require 'spec_helper'

describe Spree::Admin::TaxjarSettingsController, type: :controller do

  let(:user) { mock_model(Spree.user_class).as_null_object }

  before(:each) do
    allow(controller).to receive(:spree_current_user).and_return(user)
    allow(controller).to receive(:authorize!).and_return(true)
    allow(controller).to receive(:authorize_admin).and_return(true)
  end

  describe "GET 'edit'" do

    def send_request
      get :edit
    end

    before do
      send_request
    end

    it "assigns @preferences_api" do
      expect(assigns[:preferences_api]).to eq([:taxjar_api_key])
    end

    it "renders edit template" do
      expect(response).to render_template(:edit)
    end

  end

  describe "PUT 'update'" do

    def send_request
      put :update, taxjar_api_key: 'SAMPLE_API_KEY'
    end

    before do
      send_request
    end

    it "saves taxjar_api_key with passed parameter" do
      expect(Spree::Config[:taxjar_api_key]).to eq 'SAMPLE_API_KEY'
    end

    it "sets flash message to success" do
      expect(flash[:success]).to eq Spree.t(:api_key_updated)
    end

    it "renders edit template" do
      expect(response).to redirect_to(edit_admin_taxjar_settings_path)
    end

  end

end
