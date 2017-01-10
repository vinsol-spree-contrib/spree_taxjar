module SpreeTaxjar
  class Categories
    class << self
      def update(tax_categories = [])
        tax_categories = default_tax_categories if tax_categories.empty?
        tax_categories.each do |tax_category|
          tax_category_attributes = convert_to_hash(tax_category)
          tax_category_in_db = Spree::TaxCategory.where(name: name(tax_category_attributes)).first
          if tax_category_in_db.present?
            p "TaxCategory:: Update:: #{tax_category_in_db.inspect}"
            tax_category_in_db.update_attributes!(transform(tax_category_attributes))
          else
            new_tax_category = Spree::TaxCategory.create!(transform(tax_category_attributes))
            p "TaxCategory:: Create:: #{new_tax_category.inspect}"
          end
        end
      end

      def refresh
        p "Taxjar:: Categories:: API Call started !!"
        client = ::Taxjar::Client.new(api_key: Spree::Config[:taxjar_api_key])
        tax_categories = client.categories
        p "Taxjar:: Categories:: Update Started"
        update(tax_categories)
      end

      private
        def convert_to_hash(tax_category)
          tax_category.to_h
        end

        def transform(tax_category)
          {name: name(tax_category), tax_code: tax_code(tax_category), description: description(tax_category)}
        end

        def name(tax_category)
          tax_category.fetch(:name)
        end

        def tax_code(tax_category)
          tax_category.fetch(:product_tax_code)
        end

        def description(tax_category)
          tax_category.fetch(:description)
        end

        def default_tax_categories
          [
            {:name=>"Digital Goods", :product_tax_code=>"31000", :description=>"Digital products transferred electronically, meaning obtained by the purchaser by means other than tangible storage media."},
            {:name=>"Clothing", :product_tax_code=>"20010", :description=>" All human wearing apparel suitable for general use"},
            {:name=>"Non-Prescription", :product_tax_code=>"51010", :description=>"Drugs for human use without a prescription"},
            {:name=>"Prescription", :product_tax_code=>"51020", :description=>"Drugs for human use with a prescription"},
            {:name=>"Food & Groceries", :product_tax_code=>"40030", :description=>"Food for humans consumption, unprepared"},
            {:name=>"Other Exempt", :product_tax_code=>"99999", :description=>"Item is exempt"},
            {:name=>"Software as a Service", :product_tax_code=>"30070", :description=>"Pre-written software, delivered electronically, but access remotely."},
            {:name=>"Magazines & Subscriptions", :product_tax_code=>"81300", :description=>"Periodicals, printed, sold by subscription"},
            {:name=>"Books", :product_tax_code=>"81100", :description=>"Books, printed"},
            {:name=>"Magazine", :product_tax_code=>"81310", :description=>"Periodicals, printed, sold individually"},
            {:name=>"Textbook", :product_tax_code=>"81110", :description=>"Textbooks, printed"},
            {:name=>"Religious books", :product_tax_code=>"81120", :description=>"Religious books and manuals, printed"}
          ]
        end
    end
  end
end
