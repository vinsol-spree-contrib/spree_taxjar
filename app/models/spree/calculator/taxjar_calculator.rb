require_dependency 'spree/calculator'

module Spree
  class Calculator::TaxjarCalculator < Calculator

    CACHE_EXPIRATION_DURATION = 10.minutes

    def self.description
      Spree.t(:taxjar_calculator_description)
    end

    def compute_order(order)
      raise "Calculate tax for line_item and shipment and not order"
    end

    def compute_line_item(item)
      if rate.included_in_price
        0
      else
        round_to_two_places(tax_for_item(item))
      end
    end

    def compute_shipment(item)
      tax_for_shipment(item)
    end

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

      def tax_for_shipment(shipment)
        order = shipment.order
        return 0 unless tax_address = order.tax_address

        Rails.cache.fetch(cache_key(order, shipment, tax_address), expires_in: CACHE_EXPIRATION_DURATION) do
          Spree::Taxjar.new(order, nil, shipment).calculate_tax_for_shipment
        end
      end

      def tax_for_item(item)
        order = item.order
        return 0 unless tax_address = order.tax_address

        unless Rails.cache.read(cache_key(order, item, tax_address))
          taxjar_response = Spree::Taxjar.new(order).calculate_tax_for_order
          return 0 unless taxjar_response
          cache_response(taxjar_response, order, tax_address)
        end

        Rails.cache.read(cache_key(order, item, tax_address))
      end

      def cache_response(taxjar_response, order, address)
        taxjar_response.breakdown.line_items.each do |line_item|
          item =  Spree::LineItem.find_by(id: line_item.id)
          Rails.cache.write(cache_key(order, item, address), line_item.tax_collectable, expires_in: CACHE_EXPIRATION_DURATION)
        end
      end

      def cache_key(order, item, address)
        if item.is_a?(Spree::LineItem)
          ['Spree::LineItem', order.id, item.id, address.state.id, address.zipcode, item.amount, :amount_to_collect]
        else
          ['Spree::Shipment', order.id, item.id, address.state.id, address.zipcode, item.cost, :amount_to_collect]
        end
      end

      def round_to_two_places(amount)
        BigDecimal.new(amount.to_s).round(2, BigDecimal::ROUND_HALF_UP)
      end
  end
end
