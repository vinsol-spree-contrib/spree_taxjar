module Spree
  class Taxjar

    def initialize(order = nil, reimbursement = nil)
      @order = order
      @reimbursement = reimbursement
      @client = ::Taxjar::Client.new(api_key: Spree::Config[:taxjar_api_key])
    end

    def create_refund_transaction_for_order
      @client.create_refund(refund_params)
    end

    def create_transaction_for_order
      @client.create_order(transaction_parameters)
    end

    def delete_transaction_for_order
      @client.delete_order(@order.number)
    end

    def calculate_tax_for_order(options)
      @client.tax_for_order(options)
    end

    private

      def group_by_line_items
        @reimbursement.return_items.group_by { |item| item.inventory_unit.line_item_id }
      end

      def return_items_params
        group_by_line_items.map do |line_item, return_items|
          item = return_items.first
          {
            quantity: return_items.length,
            product_identifier: item.variant.sku,
            description: item.variant.description.truncate(150),
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
          shipping: @order.shipment_total,
          sales_tax: @reimbursement.return_items.sum(:additional_tax_total),
          line_items: return_items_params
        })
      end

      def transaction_parameters
        address_params.merge({
          transaction_id: @order.number,
          transaction_date: @order.completed_at.as_json,
          amount: @order.total - @order.additional_tax_total,
          shipping: @order.shipment_total,
          sales_tax: @order.additional_tax_total,
          line_items: line_item_params
        })
      end

      def address_params
        {
          to_country: @order.ship_address.country.iso,
          to_zip: @order.ship_address.zipcode,
          to_state: @order.ship_address.state.abbr,
          to_city: @order.ship_address.city
        }
      end

      def line_item_params
        @order.line_items.map do |item|
          {
            quantity: item.quantity,
            product_identifier: item.sku,
            description: item.description.truncate(150),
            unit_price: item.price,
            sales_tax: item.additional_tax_total
          }
        end
      end

  end
end
