Spree::Reimbursement.class_eval do
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
    return unless is_taxed_using_taxjar?
    Spree::Taxjar.create_refund_transaction_for_order(self)
  end

  private
     def is_taxed_using_taxjar?
      Spree::TaxRate.match(order.tax_zone).any? { |rate| rate.calculator_type == "Spree::Calculator::TaxjarCalculator" }
    end
end
