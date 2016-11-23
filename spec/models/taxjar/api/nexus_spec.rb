require 'spec_helper'

describe Taxjar::API::Nexus do

  let(:taxjar_client) { Taxjar::Client.new }

  describe 'Constants' do
    it 'expects to include Taxjar::API::Utils' do
      expect(Taxjar::API::Nexus.include?(Taxjar::API::Utils)).to eq true
    end
  end

  describe '#nexuses' do
    before do
      allow(taxjar_client).to receive(:perform_get_with_array).and_return([{region_code: 'AL'}])
    end
    it 'return nexus by calling #perform_get_with_array' do
      expect(taxjar_client).to receive(:perform_get_with_array).and_return([{region_code: 'AL'}])
    end
    after { taxjar_client.nexuses }
  end

end
