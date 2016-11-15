require 'spec_helper'

describe Spree::AppConfiguration do
  it 'expects spree config to have taxjar_api_key' do
    expect(Spree::Config).to have_preference(:taxjar_api_key)
  end
end
