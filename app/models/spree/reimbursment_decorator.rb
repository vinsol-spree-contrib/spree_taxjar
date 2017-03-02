Spree::Reimbursement.class_eval do
  include Taxable
  include Spree::Reimbursable
end
