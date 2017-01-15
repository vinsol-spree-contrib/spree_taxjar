SpreeTaxjar::Logger = TaxjarHelper::TaxjarLog.new("spree_taxjar", "taxjar_calculator")
SpreeTaxjar::Logger.logger.extend(ActiveSupport::Logger.broadcast(Rails.logger))
