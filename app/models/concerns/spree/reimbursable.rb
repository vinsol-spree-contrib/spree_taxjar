module Spree
  module Reimbursable
    extend ActiveSupport::Concern

    CALLBACK = StateMachines::Callback.new :after, [:pending, :errored] => :reimbursed, do: :remove_tax_for_returned_items

    included do
      callbacks = state_machines[:reimbursement_status].callbacks[:after]
      callbacks << CALLBACK unless callbacks.include? CALLBACK
    end

    def remove_tax_for_returned_items
      return unless taxjar_applicable?(order)
      client = Spree::Taxjar.new(order, self)
      client.create_refund_transaction_for_order
    end
  end
end
