require 'spec_helper'

describe Taxjar::Client do

  describe 'Constants' do
    it 'should include Taxjar::API::Nexus' do
      expect(Taxjar::Client.include?(Taxjar::API::Nexus)).to eq true
    end
  end

end
