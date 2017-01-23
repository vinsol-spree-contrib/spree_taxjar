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
  let!(:shipment) { create(:shipment, cost: 15, order: order) }
  let!(:taxjar) { double(Taxjar::Client) }
  let(:taxjar_response) { double(Taxjar::Tax) }

  before do
    Spree::Config[:taxjar_api_key] = '3d5b71689cf70fc393efb6cf2dd3dc9d'
    ## Forcing tests with shipping_address as tax_address
    Spree::Config[:tax_using_ship_address] = true
    allow(Taxjar::Client).to receive(:new).with(api_key: '3d5b71689cf70fc393efb6cf2dd3dc9d').and_return(taxjar)
    allow(taxjar).to receive(:nexus_regions).and_return([])
    allow(taxjar).to receive(:tax_for_order).and_return(taxjar_response)
    allow(taxjar_response).to receive(:[]).with('amount_to_collect').and_return(2.0)
    allow(taxjar_response).to receive_message_chain(:breakdown, :line_items).and_return(order.line_items)
    allow(line_item).to receive(:tax_collectable).and_return(2.0)
  end

  describe ".description" do
    it 'returns the description for the calculator' do
      expect(calculator.description).to eq(Spree.t(:taxjar_calculator_description))
    end
  end

  describe "#compute_order" do
    it 'returns tax for the order upto two decimal places' do
      expect(calculator.compute_order(order)).to eq(2.0)
    end
  end

  describe "#tax_for_item" do
    it 'returns tax for the line_item upto two decimal places' do
      expect(calculator.send(:tax_for_item, line_item)).to eq(2.0)
    end
  end

  describe '#compute_line_item' do
    context 'when taxjar calculation disabled' do
      before :each do
        Spree::Config[:taxjar_enabled] = false
      end

      it 'tax should be zero' do
        expect(calculator.compute_line_item(line_item)).to eq(0)
      end
    end

    context 'when taxjar calculation enabled' do
      before :each do
        Spree::Config[:taxjar_enabled] = true
      end

      context 'when rate not included in price' do
        it 'returns tax for the line_item upto two decimal places' do
          expect(calculator.compute_line_item(line_item)).to eq(2.0)
        end
      end

      context 'when rate included in price' do
        before do
          rate.included_in_price = true
          rate.save!
        end
        it 'returns tax for the line_item upto two decimal places' do
          expect(calculator.compute_line_item(line_item)).to eq(0)
        end
      end
    end
  end

  describe '#compute_shipment' do
    context 'when taxjar calculation disabled' do
      before :each do
        Spree::Config[:taxjar_enabled] = false
      end

      it 'tax should be zero' do
        expect(calculator.compute_shipment(shipment)).to eq(0)
      end
    end

    context 'when taxjar calculation enabled' do
      before :each do
        Spree::Config[:taxjar_enabled] = true
      end

      it 'should return tax on shipping' do
        expect(calculator.compute_shipment(shipment)).to eq(0)
      end
    end
  end

  describe '#compute_shipment_or_line_item' do
    context 'when rate not included in price' do
      it 'returns tax for the line_item/shipment upto two decimal places' do
        expect(calculator.compute_shipment_or_line_item(line_item)).to eq(2.0)
      end
    end

    context 'when rate included in price' do
      before do
        rate.included_in_price = true
        rate.save
      end
      it 'returns tax for the line_item/shipment upto two decimal places' do
        expect(calculator.compute_shipment_or_line_item(line_item)).to eq(0)
      end
    end
  end

  describe '#rate' do
    it 'returns calculable' do
      expect(calculator.send(:rate)).to eq(rate)
    end
  end

  describe '#compute_shipping_rate' do
    context 'when rate included in price' do
      before do
        rate.included_in_price = true
        rate.save
      end
      it 'will raise RuntimeError' do
        expect{ calculator.compute_shipping_rate(line_item)}.to raise_error(RuntimeError)
      end
    end
    context 'when rate not included in price' do
      it 'will return tax for shipping' do
        expect(calculator.compute_shipping_rate(line_item)).to eq(0.0)
      end
    end
  end

  describe '#cache_key' do
    context 'when key is line item' do
      it 'will return cache key for line item' do
        expect(calculator.send(:cache_key, order, line_item, ship_address)).to eq(['Spree::LineItem', order.id, line_item.id, ship_address.state.id, ship_address.zipcode, line_item.amount, :amount_to_collect])
      end
    end
    context 'when key is shipment' do
      it 'will return cache key for line item' do
        expect(calculator.send(:cache_key, order, shipment, ship_address)).to eq(['Spree::Shipment', order.id, shipment.id, ship_address.state.id, ship_address.zipcode, shipment.cost, :amount_to_collect])
      end
    end
  end

  describe '#cache_response' do
    before do
      @line_item = [{}]
      allow(taxjar_response).to receive_message_chain(:breakdown, :line_items).and_return(@line_item)
      allow(@line_item.first).to receive(:id).and_return(line_item.id)
      allow(@line_item.first).to receive(:tax_collectable).and_return(2.0)
    end
    it 'sets Rails cache' do
      calculator.send(:cache_response, taxjar_response, order, ship_address)
      expect(Rails.cache.read(calculator.send(:cache_key, order, line_item, ship_address))).to eq 2.0
    end

    after { calculator.send(:cache_response, taxjar_response, order, ship_address) }

  end
end
