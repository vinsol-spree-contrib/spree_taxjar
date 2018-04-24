require_dependency 'spree/calculator'

module Spree
  class Calculator::TaxjarCalculator < Calculator
    include VatPriceCalculation

    CACHE_EXPIRATION_DURATION = 10.minutes

    def self.description
      Spree.t(:taxjar_calculator_description)
    end

    def compute_order(order)
      raise "Calculate tax for line_item and shipment and not order"
    end

    def compute_line_item(item)
      SpreeTaxjar::Logger.log(__method__, {line_item: {order: {id: item.order.id, number: item.order.number}}}) if SpreeTaxjar::Logger.logger_enabled?
      return 0 unless Spree::Config[:taxjar_enabled]
      if rate.included_in_price
        0
      else
        round_to_two_places(tax_for_item(item))
      end
    end

    def compute_shipment(shipment)
      SpreeTaxjar::Logger.log(__method__, {shipment: {order: {id: shipment.order.id, number: shipment.order.number}}}) if SpreeTaxjar::Logger.logger_enabled?
      return 0 unless Spree::Config[:taxjar_enabled]
      tax_for_shipment(shipment)
    end

    def compute_shipping_rate(shipping_rate)
      return 0 unless Spree::Config[:taxjar_enabled]
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

        rails_cache_key = cache_key(order, shipment, tax_address)

        SpreeTaxjar::Logger.log(__method__, {shipment: {order: {id: shipment.order.id, number: shipment.order.number}}, cache_key: rails_cache_key}) if SpreeTaxjar::Logger.logger_enabled?

        Rails.cache.fetch(rails_cache_key, expires_in: CACHE_EXPIRATION_DURATION) do
          Spree::Taxjar.new(order, nil, shipment).calculate_tax_for_shipment
        end
      end

      def tax_for_item(item)
        order = item.order
        return 0 unless tax_address = order.tax_address

        rails_cache_key = cache_key(order, item, tax_address)

        SpreeTaxjar::Logger.log(__method__, {line_item: {order: {id: item.order.id, number: item.order.number}}, cache_key: rails_cache_key}) if SpreeTaxjar::Logger.logger_enabled?

        ## Test when caching enabled that only 1 API call is sent for an order
        ## should avoid N calls for N line_items
        Rails.cache.fetch(rails_cache_key, expires_in: CACHE_EXPIRATION_DURATION) do
          taxjar_response = Spree::Taxjar.new(order).calculate_tax_for_order
          return 0 unless taxjar_response
          tax_for_current_item = cache_response(taxjar_response, order, tax_address, item)
          tax_for_current_item
        end
      end

      def cache_response(taxjar_response, order, address, item = nil)
        SpreeTaxjar::Logger.log(__method__, {order: {id: order.id, number: order.number}, taxjar_api_advanced_res: taxjar_response}) if SpreeTaxjar::Logger.logger_enabled?
        SpreeTaxjar::Logger.log(__method__, {order: {id: order.id, number: order.number}, taxjar_api_advanced_res: taxjar_response.breakdown.line_items}) if SpreeTaxjar::Logger.logger_enabled?
        ## res is set to faciliate testing as to return computed result from API
        ## for given line_item
        ## better to use Rails.cache.fetch for order and wrapping lookup based on line_item id
        res = nil
        taxjar_response.breakdown.line_items.each do |line_item|
          item_from_db = Spree::LineItem.includes(:adjustments).find_by(id: line_item.id)
          if item && item_from_db.id == item.id
            res = line_item.tax_collectable
          end
          Rails.cache.write(cache_key(order, item_from_db, address), line_item.tax_collectable, expires_in: CACHE_EXPIRATION_DURATION)
        end
        res
      end

      def cache_key(order, item, address)
        if item.is_a?(Spree::LineItem)
          [Spree::LineItem.to_s, order.id, item.id, address.state_id, address.zipcode, item.taxable_amount, :amount_to_collect]
        else
          [Spree::Shipment.to_s, order.id, item.id, address.state_id, address.zipcode, item.cost, item.adjustments.select { |adjustment| adjustment.source_type != Spree::TaxRate.to_s }.map(&:amount).sum.to_f, :amount_to_collect]
        end
      end
  end
end
