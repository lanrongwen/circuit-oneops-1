COOKBOOKS_PATH="/opt/oneops/inductor/circuit-oneops-1/components/cookbooks"

require_relative 'spec_helper'
require "#{COOKBOOKS_PATH}/azure_base/test/integration/azure_spec_utils"

provider = AzureSpecUtils.new($node).get_provider
if provider =~ /azure/
  require_relative './azure/add'
end

