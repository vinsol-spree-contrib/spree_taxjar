require 'spec_helper'

describe Spree::Taxjar do

  let(:reimbursement) { create(:reimbursement) }
  let!(:ship_address) { create(:ship_address) }
  let(:order) { create(:order, ship_address_id: ship_address.id) }
  let(:client) { double(Taxjar::Client) }

  context 'When reimbursement is not present' do
    let(:spree_taxjar) { Spree::Taxjar.new(order) }
    before do
      allow(::Taxjar::Client).to receive(:new).with(api_key: Spree::Config[:taxjar_api_key]).and_return(client)
    end

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

    describe '#has_nexus?' do
      context 'nexus_regions is not present' do
        before do
          allow(client).to receive(:nexus_regions).and_return([])
        end
        it 'should return false' do
          expect(spree_taxjar.has_nexus?).to eq false
        end
      end

      context 'nexus_regions is present' do
        before do
          allow(client).to receive(:nexus_regions).and_return([{region_code: ship_address.state.abbr}])
        end
        it 'should return false' do
          expect(spree_taxjar.has_nexus?).to eq true
        end
      end
    end

    describe '#nexus_states' do
      context 'nexus_regions is not present' do
        it 'should return region_code for nexus state' do
          expect(spree_taxjar.nexus_states([{region_code: ship_address.state.abbr}])).to eq [ship_address.state.abbr]
        end
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
