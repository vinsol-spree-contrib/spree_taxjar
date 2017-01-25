require 'spec_helper'

describe Spree::Order do

  let(:order) { create(:order) }
  let(:client) { double(Spree::Taxjar) }

  describe 'Constants' do
    it 'should include Taxable' do
      expect(Spree::Order.include?(Taxable)).to eq true
    end
  end

  describe 'Instance Methods' do
    describe '#delete_taxjar_transaction' do
      context 'when taxjar calculation disabled' do
        before :each do
          Spree::Config[:taxjar_enabled] = false
        end

        it 'tax should be zero' do
          expect(order).to_not receive(:taxjar_applicable?)
        end

        after { order.send(:delete_taxjar_transaction) }
      end

      context 'when taxjar calculation enabled' do
        before :each do
          Spree::Config[:taxjar_enabled] = true
        end

        context 'when taxjar_applicable? returns false' do
          it 'should return nil' do
            expect(order.send(:delete_taxjar_transaction)).to eq nil
          end
        end

        context 'when taxjar_applicable? return true' do
          before do
            allow(order).to receive(:taxjar_applicable?).with(order).and_return(true)
            allow(Spree::Taxjar).to receive(:new).with(order).and_return(client)
            allow(client).to receive(:delete_transaction_for_order)
          end

          it 'should delete transaction for order' do
            expect(client).to receive(:delete_transaction_for_order)
          end

          after { order.send(:delete_taxjar_transaction) }
        end
      end
    end

    describe '#capture_taxjar' do
      context 'when taxjar calculation disabled' do
        before :each do
          Spree::Config[:taxjar_enabled] = false
        end

        it 'tax should be zero' do
          expect(order).to_not receive(:taxjar_applicable?)
        end

        after { order.send(:capture_taxjar) }
      end

      context 'when taxjar calculation enabled' do
        before :each do
          Spree::Config[:taxjar_enabled] = true
        end

        context 'when taxjar_applicable? returns false' do
          it 'should return nil' do
            expect(order.send(:capture_taxjar)).to eq nil
          end
        end

        context 'when taxjar_applicable? return true' do
          before do
            allow(order).to receive(:taxjar_applicable?).with(order).and_return(true)
            allow(Spree::Taxjar).to receive(:new).with(order).and_return(client)
            allow(client).to receive(:create_transaction_for_order)
          end

          it 'should create transaction for order' do
            expect(client).to receive(:create_transaction_for_order)
          end

          after { order.send(:capture_taxjar) }
        end
      end
    end
  end

end
