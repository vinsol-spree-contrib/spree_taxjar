require 'spec_helper'

describe Spree::Taxjar do

  let(:reimbursement) { create(:reimbursement) }
  let!(:country) { create(:country) }
  let!(:state) { create(:state, country: country, abbr: "TX") }
  let!(:zone) { create(:zone, name: "Country Zone", default_tax: true, zone_members: []) }
  let!(:ship_address) { create(:ship_address, city: "Adrian", zipcode: "79001", state: state) }
  let!(:tax_category) { create(:tax_category, tax_rates: []) }
  let!(:order) { create(:order,ship_address_id: ship_address.id) }
  let!(:line_item) { create(:line_item, price: 10, quantity: 3, order_id: order.id) }
  let!(:state_al) { create(:state, country: country, abbr: "AL") }
  let!(:ship_address_al) { create(:ship_address, city: "Adrian", zipcode: "79001", state: state_al) }
  let!(:order_al) { create(:order,ship_address_id: ship_address_al.id) }
  let!(:line_item_al) { create(:line_item, price: 10, quantity: 3, order_id: order_al.id) }
  let!(:shipment_al) { create(:shipment, cost: 10, order: order_al) }
  let!(:taxjar_api_key) { Spree::Config[:taxjar_api_key] = '04d828b7374896d7867b03289ea20957' }
  let(:client) { double(Taxjar::Client) }

  let(:spree_taxjar) { Spree::Taxjar.new(order) }

  describe '#has_nexus?' do
    context 'nexus_regions is not present' do
      it 'should return false' do
        VCR.use_cassette "no_nexuses" do
          expect(spree_taxjar.has_nexus?).to eq false
        end
      end
    end

    context 'nexus_regions is present' do
      context 'tax_address is present in nexus regions' do
        it 'should return true' do
          VCR.use_cassette "has_nexuses" do
            expect(spree_taxjar.has_nexus?).to eq true
          end
        end
      end

      context 'tax_address is not present in nexus regions' do
        before :each do
          @spree_taxjar_new = Spree::Taxjar.new(order_al)
        end

        it 'should return false' do
          VCR.use_cassette "has_nexuses" do
            expect(@spree_taxjar_new.has_nexus?).to eq false
          end
        end
      end
    end
  end

  context 'When reimbursement is not present' do
    before :each do
      Spree::Config[:taxjar_api_key] = '04d828b7374896d7867b03289ea20957'
      allow(::Taxjar::Client).to receive(:new).with(api_key: Spree::Config[:taxjar_api_key]).and_return(client)
    end

    let(:spree_taxjar) { Spree::Taxjar.new(order) }

    describe '#initialize' do

      it 'expects spree_taxjar to set instance variable order' do
        expect(spree_taxjar.instance_variable_get(:@order)).to eq order
      end

      it 'expects spree_taxjar to set instance variable client' do
        expect(spree_taxjar.instance_variable_get(:@client)).to eq client
      end

      it 'expects spree_taxjar to set instance variable reimbursement to nil' do
        expect(spree_taxjar.instance_variable_get(:@reimbursement)).to eq nil
      end

    end

    describe '#create_transaction_for_order' do
      context 'when has_nexus? returns false' do
        before do
          allow(spree_taxjar).to receive(:has_nexus?).and_return(false)
        end
        it 'should return nil' do
          expect(spree_taxjar.create_transaction_for_order).to eq nil
        end
      end

      context 'when has_nexus? returns true' do
        before do
          allow(::Taxjar::Client).to receive(:new).with(api_key: Spree::Config[:taxjar_api_key]).and_return(client)
          allow(spree_taxjar).to receive(:has_nexus?).and_return(true)
          allow(client).to receive(:create_order).and_return(true)
        end

        it 'should return create order for the transaction' do
          expect(client).to receive(:create_order).and_return(true)
        end

        after { spree_taxjar.create_transaction_for_order }

      end
    end

    describe '#delete_transaction_for_order' do
      context 'when has_nexus? returns false' do
        before do
          allow(spree_taxjar).to receive(:has_nexus?).and_return(false)
        end
        it 'should return nil' do
          expect(spree_taxjar.delete_transaction_for_order).to eq nil
        end
      end

      context 'when has_nexus? returns true' do
        before do
          @transaction_parameters = {}
          allow(spree_taxjar).to receive(:has_nexus?).and_return(true)
          allow(client).to receive(:delete_order).with(order.number).and_return(true)
        end

        it { expect(spree_taxjar).to receive(:has_nexus?).and_return(true) }

        it 'should return create order for the transaction' do
          expect(client).to receive(:delete_order).with(order.number).and_return(true)
        end
        after { spree_taxjar.delete_transaction_for_order }

      end
    end

    describe '#calculate_tax_for_order' do
      context 'when has_nexus? returns false' do
        before do
          allow(spree_taxjar).to receive(:has_nexus?).and_return(false)
        end
        it 'should return nil' do
          expect(spree_taxjar.calculate_tax_for_order).to eq nil
        end
      end

      context 'when has_nexus? returns true' do
        before do
          allow(spree_taxjar).to receive(:has_nexus?).and_return(true)
          allow(client).to receive(:tax_for_order).and_return(true)
        end

        it { expect(spree_taxjar).to receive(:has_nexus?).and_return(true) }

        it 'should return create order for the transaction' do
          expect(client).to receive(:tax_for_order).and_return(true)
        end
        after { spree_taxjar.calculate_tax_for_order }

      end
    end

  end

  context 'When reimbursement is present' do
    let(:spree_taxjar) { Spree::Taxjar.new(order, reimbursement) }
    before do
      allow(::Taxjar::Client).to receive(:new).with(api_key: Spree::Config[:taxjar_api_key]).and_return(client)
    end

    describe '#create_refund_transaction_for_order' do
      context 'when has_nexus? returns false' do
        before do
          allow(spree_taxjar).to receive(:has_nexus?).and_return(false)
        end
        it 'should return nil' do
          expect(spree_taxjar.create_refund_transaction_for_order).to eq nil
        end
      end

      context 'when reimbursement is present' do
        before do
          allow(spree_taxjar).to receive(:has_nexus?).and_return(true)
          allow(spree_taxjar).to receive(:reimbursement_present?).and_return(true)
        end
        it 'should return nil' do
          expect(spree_taxjar.create_refund_transaction_for_order).to eq nil
        end
      end

      context 'when has_nexus? returns true & reimbursement is not present' do
        before do
          allow(spree_taxjar).to receive(:has_nexus?).and_return(true)
          allow(spree_taxjar).to receive(:reimbursement_present?).and_return(false)
          allow(client).to receive(:create_refund).with(:refund_params).and_return(true)
        end

        it 'should return create order for the transaction' do
          expect(client).to receive(:create_refund).and_return(true)
        end
        after { spree_taxjar.create_refund_transaction_for_order }

      end

    end

  end

end
