Spree::Reimbursement.class_eval do
  include Taxable

  state_machine :reimbursement_status, initial: :pending do
    after_transition to: :reimbursed, do: :remove_tax_for_returned_items
    event :errored do
      transition to: :errored, from: :pending
    end

    event :reimbursed do
      transition to: :reimbursed, from: [:pending, :errored]
    end
  end

  def remove_tax_for_returned_items
    return unless taxjar_applicable?(order)
    client = Spree::Taxjar.new(order, self)
    client.create_refund_transaction_for_order
  end
end
