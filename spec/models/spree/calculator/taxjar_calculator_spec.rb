require 'spec_helper'

describe Spree::Calculator::TaxjarCalculator do

  let!(:country) { create(:country) }
  let!(:zone) { create(:zone, name: "Country Zone", default_tax: true, zone_members: []) }
  let!(:ship_address) { create(:ship_address) }
  let!(:tax_category) { create(:tax_category, tax_rates: []) }
  let!(:rate) { create(:tax_rate, tax_category: tax_category, amount: 0.05, included_in_price: included_in_price) }
  let(:included_in_price) { false }
  let!(:calculator) { Spree::Calculator::TaxjarCalculator.new(calculable: rate) }
  let!(:order) { create(:order,ship_address_id: ship_address.id) }
  let!(:line_item) { create(:line_item, price: 10, quantity: 3, tax_category: tax_category, order_id: order.id) }
  let!(:shipment) { create(:shipment, cost: 15) }
  let!(:taxjar) { double(Taxjar::Client) }
  let(:taxjar_response) { double(Taxjar::Tax) }

  before do
    allow(Taxjar::Client).to receive(:new).with(api_key: 'b9f8755404c74f63a0a7716cca39fae2').and_return(taxjar)
    allow(taxjar).to receive(:tax_for_order).and_return(taxjar_response)
    allow(taxjar_response).to receive(:[]).with('amount_to_collect').and_return(2.0)
  end

  describe ".description" do
    it { expect(calculator.description).to eq(Spree.t(:taxjar_calculator_description)) }
  end

  describe '#compute_order' do
    it { expect(calculator.compute_order(order)).to eq(2.0) }
  end

  describe '#compute_shipment_or_line_item' do
    context 'when rate not included in price' do
      it { expect(calculator.compute_shipment_or_line_item(line_item)).to eq(2.0) }
    end

    context 'when rate included in price' do
      before do
        rate.included_in_price = true
        rate.save
      end
      it { expect(calculator.compute_shipment_or_line_item(line_item)).to eq(0) }
    end
  end

  describe '#rate' do
    it { expect(calculator.send(:rate)).to eq(rate) }
  end

  describe '#deduced_total_by_rate' do
    it { expect(calculator.send(:deduced_total_by_rate, 100, rate)).to eq(5) }
  end

  describe '#set_parameters' do
    before { @parameters = calculator.send(:set_parameters, line_item, order.ship_address) }
    it { expect(@parameters.keys).to match_array([:amount, :shipping, :to_state, :to_zip]) }
    it { expect(@parameters.values).to match_array([line_item.pre_tax_amount, 0, ship_address.state.abbr, ship_address.zipcode]) }
  end

  describe '#cache_key' do
    it { expect(calculator.send(:cache_key, order, line_item, ship_address)).to match_array([order.id, line_item.id, ship_address.state_id, ship_address.zipcode, line_item.pre_tax_amount, :amount_to_collect]) }
  end

end
