COOKBOOKS_PATH="/opt/oneops/inductor/circuit-oneops-1/components/cookbooks"
AZURE_TESTS_PATH="#{COOKBOOKS_PATH}/azuresecgroup/test/integration/add/serverspec/tests"

require_relative 'spec_helper'
require "#{COOKBOOKS_PATH}/azure_base/test/integration/spec_utils"

provider = SpecUtils.new($node).get_provider
if provider =~ /azure/
  require "#{COOKBOOKS_PATH}/azure_base/test/integration/azure_spec_utils"
  Dir.glob("#{AZURE_TESTS_PATH}/*.rb").each {|tst| require tst}
end

