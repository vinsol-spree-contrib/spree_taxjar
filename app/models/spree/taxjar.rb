module Spree
  class Taxjar

    def initialize(order = nil, reimbursement = nil)
      @order = order
      @reimbursement = reimbursement
      @client = ::Taxjar::Client.new(api_key: Spree::Config[:taxjar_api_key])
    end

    def create_refund_transaction_for_order
      if has_nexus? && !reimbursement_present?
        @client.create_refund(refund_params)
      end
    end

    def create_transaction_for_order
      @client.create_order(transaction_parameters) if has_nexus?
    end

    def delete_transaction_for_order
      @client.delete_order(@order.number) if has_nexus?
    end

    def has_nexus?
      nexus_regions = @client.nexuses
      if nexus_regions.present?
        nexus_states(nexus_regions).include?(@order.ship_address.state.abbr)
      else
        false
      end
    end

    def nexus_states(nexus_regions)
      nexus_regions.map { |record| record[:region_code]}
    end

    def calculate_tax_for_order
      @client.tax_for_order(tax_params)
    end

    private

      def tax_params
        {
          amount: @order.item_total,
          shipping: 0,
          to_state: @order.ship_address.state.abbr,
          to_zip: @order.ship_address.zipcode,
          line_items: taxable_line_items_params
        }
      end

      def taxable_line_items_params
        @order.line_items.map do |item|
          {
            id: item.id,
            quantity: item.quantity,
            unit_price: item.price
          }
        end
      end

      def reimbursement_present?
        @client.list_refunds(from_transaction_date: Date.today - 1, to_transaction_date: Date.today + 1).include?(@reimbursement.number)
      end

      def group_by_line_items
        @reimbursement.return_items.group_by { |item| item.inventory_unit.line_item_id }
      end

      def return_items_params
        group_by_line_items.map do |line_item, return_items|
          item = return_items.first
          {
            quantity: return_items.length,
            product_identifier: item.variant.sku,
            description: ActionView::Base.full_sanitizer.sanitize(item.variant.description).truncate(150),
            unit_price: item.pre_tax_amount
          }
        end
      end

      def refund_params
        address_params.merge({
          transaction_id: @reimbursement.number,
          transaction_reference_id: @order.number,
          transaction_date: @order.completed_at.as_json,
          amount: @reimbursement.return_items.sum(:pre_tax_amount) + @order.shipment_total,
          shipping: @order.shipment_total + @order.adjustment_total - @order.additional_tax_total,
          sales_tax: @reimbursement.return_items.sum(:additional_tax_total),
          line_items: return_items_params
        })
      end

      def transaction_parameters
        address_params.merge({
          transaction_id: @order.number,
          transaction_date: @order.completed_at.as_json,
          amount: @order.total - @order.additional_tax_total,
          shipping: @order.shipment_total + @order.adjustment_total - @order.additional_tax_total,
          sales_tax: @order.additional_tax_total,
          line_items: line_item_params
        })
      end

      def address_params
        {
          to_country: @order.ship_country.iso,
          to_zip: @order.ship_zipcode,
          to_state: @order.ship_state.abbr,
          to_city: @order.ship_city
        }
      end

      def line_item_params
        @order.line_items.map do |item|
          {
            quantity: item.quantity,
            product_identifier: item.sku,
            description: ActionView::Base.full_sanitizer.sanitize(item.description).truncate(150),
            unit_price: item.price,
            sales_tax: item.additional_tax_total
          }
        end
      end

  end
end
