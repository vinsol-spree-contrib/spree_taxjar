module SpreeTaxjar::OrderDecorator

  def self.prepended(base)
    base.include Taxable
    base.state_machine.after_transition to: :complete, do: :capture_taxjar
    base.state_machine.after_transition to: :canceled, do: :delete_taxjar_transaction
    base.state_machine.after_transition to: :resumed, from: :canceled, do: :capture_taxjar
  end


  private

    def delete_taxjar_transaction
      return unless SpreeTaxjar::Config[:taxjar_enabled]
      return unless taxjar_applicable?(self)
      client = Spree::Taxjar.new(self)
      client.delete_transaction_for_order
    end

    def capture_taxjar
      return unless SpreeTaxjar::Config[:taxjar_enabled]
      return unless taxjar_applicable?(self)
      client = Spree::Taxjar.new(self)
      client.create_transaction_for_order
    end
end

Spree::Order.prepend SpreeTaxjar::OrderDecorator