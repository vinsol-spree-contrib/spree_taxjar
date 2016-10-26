require_dependency 'spree/calculator'

module Spree
  class Calculator::TaxjarCalculator < Calculator
    include VatPriceCalculation

    def self.description
      Spree.t(:taxjar_calculator_description)
    end

    def compute_order(order)
      tax = order.line_items.to_a.sum do |line_item|
        tax_for_item(line_item)
      end
      round_to_two_places(tax)
    end

    def compute_shipment_or_line_item(item)
      if rate.included_in_price
        0
      else
        round_to_two_places(tax_for_item(item))
      end
    end

    alias_method :compute_shipment, :compute_shipment_or_line_item
    alias_method :compute_line_item, :compute_shipment_or_line_item

    def compute_shipping_rate(shipping_rate)
      if rate.included_in_price
        raise Spree.t(:shipping_rate_exception_message)
      else
        0
      end
    end


    private
      def rate
        calculable
      end

      def deduced_total_by_rate(pre_tax_amount, rate)
        round_to_two_places(pre_tax_amount * rate.amount)
      end

      def tax_for_item(item)
        order = item.order
        return 0 unless ship_address = order.shipping_address

        unless Rails.cache.read(cache_key(order, item, ship_address))
          taxjar_response = Spree::Taxjar.new(order).calculate_tax_for_order
          return 0 unless taxjar_response
          cache_response(taxjar_response, order, ship_address)
        end

        Rails.cache.read(cache_key(order, item, ship_address))
      end

      def cache_response(taxjar_response, order, ship_address)
        taxjar_response.breakdown.line_items.each do |line_item|
          item =  Spree::LineItem.find_by(id: line_item.id)
          Rails.cache.write(cache_key(order, item, ship_address), line_item.tax_collectable, expires_in: 10.minutes)
        end
      end

      def set_parameters(item, ship_address)
        @parameters = { amount: item.pre_tax_amount, shipping: 0, to_state: ship_address.state.abbr, to_zip: ship_address.zipcode }
      end

      def cache_key(order, item, ship_address)
        if item.is_a?(Spree::LineItem)
          ['Spree::LineItem', order.id, item.id, ship_address.state.id, ship_address.zipcode, item.amount, :amount_to_collect]
        else
          ['Spree::Shipment', order.id, item.id, ship_address.state.id, ship_address.zipcode, item.cost, :amount_to_collect]
        end
      end
  end
end
