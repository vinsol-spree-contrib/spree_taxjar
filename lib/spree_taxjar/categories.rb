module SpreeTaxjar
  class Categories
    class << self
      def update(categories = [])
        categories = default_categories if categories.empty?
        default_categories.each do |c|
          p = convert_to_hash(c)
          t = Spree::TaxCategory.where(name: name(p)).first
          if t.present?
            p "TaxCategory:: Update:: #{t.inspect}"
            t.update_attributes!(transform(p))
          else
            new_category = Spree::TaxCategory.create!(transform(p))
            p "TaxCategory:: Create:: #{new_category.inspect}"
          end
        end
      end

      def refresh
        p "Taxjar:: Categories:: API Call started !!"
        client = ::Taxjar::Client.new(api_key: Spree::Config[:taxjar_api_key])
        categories = client.categories
        p "Taxjar:: Categories:: Update Started"
        update(categories)
      end

      private
        def convert_to_hash(p)
          p.to_h
        end

        def transform(p)
          {name: name(p), tax_code: tax_code(p), description: description(p)}
        end

        def name(p)
          p.fetch(:name)
        end

        def tax_code(p)
          p.fetch(:product_tax_code)
        end

        def description(p)
          p.fetch(:description)
        end

        def default_categories
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
