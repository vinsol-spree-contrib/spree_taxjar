Spree::Order.class_eval do
  self.state_machine.after_transition to: :complete, do: :capture_taxjar
  self.state_machine.after_transition to: :canceled, do: :delete_taxjar_transaction

  def delete_taxjar_transaction
    return unless is_taxed_using_taxjar?
    Spree::Taxjar.delete_transaction_for_order(self)
  end

  def capture_taxjar
    return unless is_taxed_using_taxjar?
    Spree::Taxjar.create_transaction_for_order(self)
  end

  private
     def is_taxed_using_taxjar?
      Spree::TaxRate.match(self.tax_zone).any? { |rate| rate.calculator_type == "Spree::Calculator::TaxjarCalculator" }
    end
end
