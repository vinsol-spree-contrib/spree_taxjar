require 'spec_helper'

describe Taxable do
  let(:order) { create(:order) }
  let(:tax_category) { create(:tax_category) }
  let(:country) { create(:country) }
  let(:calculator) { Spree::Calculator::TaxjarCalculator.new }

  describe '#taxjar_applicable?' do
    context 'when TaxRate matches tax_zone' do
      before do
        @zone = create(:zone, :name => "Country Zone", :default_tax => false, :zone_members => [])
        @zone.zone_members.create(:zoneable => country)
        @rate = Spree::TaxRate.create(amount: 1, zone: @zone,
                  tax_category: tax_category, calculator: calculator)
        allow(order).to receive_messages :tax_zone => @zone
      end

      it 'should return true' do
        expect(Spree::TaxRate.match(order.tax_zone)).to eq([@rate])
      end
    end

    context 'when TaxRate does not matches tax_zone' do
      before do
        @rate = Spree::TaxRate.create(amount: 1, zone: nil,
                  tax_category: tax_category, calculator: calculator)
      end

      it 'should return false' do
        expect(Spree::TaxRate.match(order.tax_zone)).to eq([])
      end
    end
  end

end
