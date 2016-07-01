Spree::Order.class_eval do
  include Taxable

  delegate :country, :zipcode, :state, :city, to: :ship_address, prefix: 'ship'

  state_machine.after_transition to: :complete, do: :capture_taxjar
  state_machine.after_transition to: :canceled, do: :delete_taxjar_transaction

  def delete_taxjar_transaction
    return unless taxjar_applicable?(self)
    client = Spree::Taxjar.new(self)
    client.delete_transaction_for_order
  end

  def capture_taxjar
    return unless taxjar_applicable?(self)
    client = Spree::Taxjar.new(self)
    client.create_transaction_for_order
  end
end
