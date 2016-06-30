module Taxable
  extend ActiveSupport::Concern

  private
    def taxjar_applicable?(order)
      Spree::TaxRate.match(order.tax_zone).any? { |rate| rate.calculator_type == "Spree::Calculator::TaxjarCalculator" }
    end
end
