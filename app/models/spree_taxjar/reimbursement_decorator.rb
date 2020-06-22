module SpreeTaxjar::ReimbursementDecorator

  def self.prepended(base)
    base.include Taxable
    base.state_machine.after_transition to: [:reimbursed], do: :remove_tax_for_returned_items
  end


  def remove_tax_for_returned_items
    return unless SpreeTaxjar::Config[:taxjar_enabled]
    return unless taxjar_applicable?(order)
    client = Spree::Taxjar.new(order, self)
    client.create_refund_transaction_for_order
  end
end
Spree::Reimbursement.prepend SpreeTaxjar::ReimbursementDecorator
