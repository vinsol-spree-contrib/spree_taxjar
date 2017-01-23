module Spree
  class Taxjar
    attr_reader :client, :order, :reimbursement, :shipment

    def initialize(order = nil, reimbursement = nil, shipment = nil)
      @order = order
      @shipment = shipment
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

    def calculate_tax_for_shipment
      SpreeTaxjar::Logger.log(__method__, {shipment: {order: {id: @shipment.order.id, number: @shipment.order.number}}}) if SpreeTaxjar::Logger.logger_enabled?
      if has_nexus?
        api_params = shipment_tax_params
        SpreeTaxjar::Logger.log(__method__, {shipment: {order: {id: @shipment.order.id, number: @shipment.order.number}, api_params: api_params}}) if SpreeTaxjar::Logger.logger_enabled?
        api_response = @client.tax_for_order(api_params)
        SpreeTaxjar::Logger.log(__method__, {shipment: {order: {id: @shipment.order.id, number: @shipment.order.number}, api_response: api_response}}) if SpreeTaxjar::Logger.logger_enabled?
        api_response.amount_to_collect
      else
        0
      end
    end

    def has_nexus?
      nexus_regions = @client.nexus_regions
      if nexus_regions.present?
        nexus_states(nexus_regions).include?(tax_address_state_abbr)
      else
        false
      end
    end

    def calculate_tax_for_order
      SpreeTaxjar::Logger.log(__method__, {order: {id: @order.id, number: @order.number}}) if SpreeTaxjar::Logger.logger_enabled?
      if has_nexus?
        api_params = tax_params
        SpreeTaxjar::Logger.log(__method__, {order: {id: @order.id, number: @order.number}, api_params: api_params}) if SpreeTaxjar::Logger.logger_enabled?
        api_response = @client.tax_for_order(api_params)
        SpreeTaxjar::Logger.log(__method__, {order: {id: @order.id, number: @order.number}, api_response: api_response}) if SpreeTaxjar::Logger.logger_enabled?
        api_response
      else
        0
      end
    end

    private

      def nexus_states(nexus_regions)
        nexus_regions.map { |record| record.region_code}
      end

      def tax_address_country_iso
        tax_address.country.iso
      end

      def tax_address_state_abbr
        tax_address.state.abbr
      end

      def tax_address_city
        tax_address.city
      end

      def tax_address_zip
        tax_address.zipcode
      end

      def tax_address
        @order.tax_address
      end

      def tax_params
        {
          amount: @order.item_total,
          shipping: @order.shipment_total,
          to_state: tax_address_state_abbr,
          to_zip: tax_address_zip,
          line_items: taxable_line_items_params
        }
      end

      def taxable_line_items_params
        @order.line_items.map do |item|
          {
            id: item.id,
            quantity: item.quantity,
            unit_price: item.price,
            discount: item.promo_total,
            product_tax_code: item.tax_category.try(:tax_code)
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
            unit_price: item.pre_tax_amount,
            product_tax_code: item.variant.tax_category.try(:tax_code)
          }
        end
      end

      def refund_params
        address_params.merge({
          transaction_id: @reimbursement.number,
          transaction_reference_id: @order.number,
          transaction_date: @order.completed_at.as_json,
          amount: @reimbursement.return_items.sum(:pre_tax_amount),
          shipping: 0,
          sales_tax: @reimbursement.return_items.sum(:additional_tax_total),
          line_items: return_items_params
        })
      end

      def transaction_parameters
        address_params.merge({
          transaction_id: @order.number,
          transaction_date: @order.completed_at.as_json,
          amount: @order.item_total + @order.shipment_total,
          shipping: @order.shipment_total,
          sales_tax: @order.additional_tax_total,
          line_items: line_item_params
        })
      end

      def address_params
        {
          to_country: tax_address_country_iso,
          to_zip: tax_address_zip,
          to_state: tax_address_state_abbr,
          to_city: tax_address_city
        }
      end

      def shipment_tax_params
        address_params.merge({
          amount: 0,
          shipping: @shipment.cost
        })
      end

      def line_item_params
        @order.line_items.map do |item|
          {
            quantity: item.quantity,
            product_identifier: item.sku,
            description: ActionView::Base.full_sanitizer.sanitize(item.description).try(:truncate, 150),
            unit_price: item.price,
            sales_tax: item.additional_tax_total,
            discount: item.promo_total,
            product_tax_code: item.tax_category.try(:tax_code)
          }
        end
      end

  end
end
