Spree::Reimbursement.class_eval do
  include Taxable

  state_machine = self.state_machines[:reimbursement_status]
  state_machine.after_transition to: [:reimbursed], do: :remove_tax_for_returned_items

  def remove_tax_for_returned_items
    return unless Spree::Config[:taxjar_enabled]
    return unless taxjar_applicable?(order)
    client = Spree::Taxjar.new(order, self)
    client.create_refund_transaction_for_order
  end
end
