module Spree
  class Taxjar

    def self.create_refund_transaction_for_order(reimbursement)
      @@reimbursement = reimbursement
      taxjar_client.create_refund(refund_params)
    end

    def self.create_transaction_for_order(order)
      @@order = order
      taxjar_client.create_order(transaction_parameters)
    end

    def self.delete_transaction_for_order(order)
      taxjar_client.delete_order(order.number)
    end

    private

      def self.group_by_line_items
        @@reimbursement.return_items.group_by { |item| item.inventory_unit.line_item_id }
      end

      def self.return_items_params
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

      def self.refund_params
        order =  @@reimbursement.order
        {
          transaction_id: @@reimbursement.number,
          transaction_reference_id: order.number,
          transaction_date: order.completed_at.as_json,
          to_country: order.ship_address.country.iso,
          to_zip: order.ship_address.zipcode,
          to_state: order.ship_address.state.abbr,
          to_city: order.ship_address.city,
          amount: @@reimbursement.return_items.sum(:pre_tax_amount) + order.shipment_total,
          shipping: order.shipment_total,
          sales_tax: @@reimbursement.return_items.sum(:additional_tax_total),
          line_items: return_items_params
        }
      end

      def self.taxjar_client
        ::Taxjar::Client.new(api_key: Spree::Config[:taxjar_api_key])
      end

      def self.transaction_parameters
        {
          transaction_id: @@order.number,
          transaction_date: @@order.completed_at.as_json,
          to_country: @@order.ship_address.country.iso,
          to_zip: @@order.ship_address.zipcode,
          to_state: @@order.ship_address.state.abbr,
          to_city: @@order.ship_address.city,
          amount: @@order.total - @@order.additional_tax_total,
          shipping: @@order.shipment_total,
          sales_tax: @@order.additional_tax_total,
          line_items: line_item_params
        }
      end

      def self.line_item_params
        @@order.line_items.map do |item|
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
