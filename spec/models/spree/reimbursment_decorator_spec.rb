require 'spec_helper'

describe Spree::Reimbursement do

  let(:reimbursement) { create(:reimbursement) }
  let(:client) { double(Spree::Taxjar) }

  describe 'Constants' do
    it 'should include Taxable' do
      expect(Spree::Order.include?(Taxable)).to eq true
    end
  end

  describe 'Instance Methods' do
    describe '#remove_tax_for_returned_items' do
      context 'when taxjar_applicable? returns false' do
        it 'should return nil' do
          expect(reimbursement.send(:remove_tax_for_returned_items)).to eq nil
        end
      end
      context 'when taxjar_applicable? return true' do
        context 'when taxjar calculation disabled' do
          before :each do
            Spree::Config[:taxjar_enabled] = false
          end

          it 'tax should be zero' do
            expect(reimbursement).to_not receive(:taxjar_applicable?)
          end

          after { reimbursement.remove_tax_for_returned_items }
        end

        context 'when taxjar calculation enabled' do
          before do
            Spree::Config[:taxjar_enabled] = true
            @order = reimbursement.order
            allow(reimbursement).to receive(:taxjar_applicable?).with(@order).and_return(true)
            allow(Spree::Taxjar).to receive(:new).with(@order, reimbursement).and_return(client)
            allow(client).to receive(:create_refund_transaction_for_order)
          end

          it 'should remive tax for reimbursed items' do
            expect(client).to receive(:create_refund_transaction_for_order)
          end

          after { reimbursement.remove_tax_for_returned_items }
        end
      end
    end

  end

end
