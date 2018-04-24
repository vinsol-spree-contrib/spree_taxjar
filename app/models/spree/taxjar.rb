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
        api_params = refund_params
        SpreeTaxjar::Logger.log(__method__, {order: {id: @order.id, number: @order.number}, reimbursement: {id: @reimbursement.id, number: @reimbursement.number}, api_params: api_params}) if SpreeTaxjar::Logger.logger_enabled?
        api_response = @client.create_refund(api_params)
        SpreeTaxjar::Logger.log(__method__, {order: {id: @order.id, number: @order.number}, reimbursement: {id: @reimbursement.id, number: @reimbursement.number}, api_response: api_response}) if SpreeTaxjar::Logger.logger_enabled?
        api_response
      end
    end

    def create_transaction_for_order
      SpreeTaxjar::Logger.log(__method__, {order: {id: @order.id, number: @order.number}}) if SpreeTaxjar::Logger.logger_enabled?
      if has_nexus?
        api_params = transaction_parameters
        SpreeTaxjar::Logger.log(__method__, {order: {id: @order.id, number: @order.number}, api_params: api_params}) if SpreeTaxjar::Logger.logger_enabled?
        api_response = @client.create_order(api_params)
        SpreeTaxjar::Logger.log(__method__, {order: {id: @order.id, number: @order.number}, api_response: api_response}) if SpreeTaxjar::Logger.logger_enabled?
        api_response
      end
    end

    def delete_transaction_for_order
      SpreeTaxjar::Logger.log(__method__, {order: {id: @order.id, number: @order.number}}) if SpreeTaxjar::Logger.logger_enabled?
      if has_nexus?
        api_response = @client.delete_order(@order.number)
        SpreeTaxjar::Logger.log(__method__, {order: {id: @order.id, number: @order.number}, api_response: api_response}) if SpreeTaxjar::Logger.logger_enabled?
        api_response
      end
    rescue ::Taxjar::Error::NotFound => e
      SpreeTaxjar::Logger.log(__method__, {order: {id: @order.id, number: @order.number}, error_msg: e.message}) if SpreeTaxjar::Logger.logger_enabled?
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
      SpreeTaxjar::Logger.log(__method__, {
        order: {id: @order.id, number: @order.number},
        nexus_regions: nexus_regions,
        address: {state: tax_address_state_abbr, city: tax_address_city, zip: tax_address_zip}
      }) if SpreeTaxjar::Logger.logger_enabled?
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
          shipping: @order.shipment_total + adjustments_total(@order.shipment_adjustments),
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
            unit_price: item.taxable_amount / item.quantity,
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
          amount: @order.total - @order.tax_total,
          shipping: @order.shipment_total + adjustments_total(@order.shipment_adjustments),
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
          shipping: @shipment.cost + adjustments_total(@shipment.adjustments)
        })
      end

      def line_item_params
        @order.line_items.map do |item|
          unit_price = item.taxable_amount / item.quantity
          {
            quantity: item.quantity,
            product_identifier: item.sku,
            description: ActionView::Base.full_sanitizer.sanitize(item.description).try(:truncate, 150),
            unit_price: unit_price,
            sales_tax: item.additional_tax_total,
            discount: discount_weightage(item, unit_price),
            product_tax_code: item.tax_category.try(:tax_code)
          }
        end
      end

      def discount_weightage(item, unit_price)
        return 0 if @order.item_total.zero?
        weightage = @order.adjustments.sum(:amount) / (@order.item_total)
        - weightage * unit_price
      end

      def adjustments_total(adjustments)
        adjustments.select { |adjustment| adjustment.source_type != Spree::TaxRate.to_s }.map(&:amount).sum.to_f
      end


  end
end
