require 'taxjar/api/utils'

module Taxjar
  module API
    module Nexus
      include Taxjar::API::Utils

      def nexuses(options = {})
        perform_get_with_array("/v2/nexus/regions", :regions, options)
      end

    end
  end
end
