namespace :spree_taxjar do
  desc 'Load Taxjar Categories'
  task load_categories: :environment do
    SpreeTaxjar::Categories.update
  end

  desc 'Refresh Taxjar Categories'
  task refresh_categories: :environment do
    SpreeTaxjar::Categories.refresh
  end
end
