COOKBOOKS_PATH="/opt/oneops/inductor/circuit-oneops-1/components/cookbooks"

require_relative 'spec_helper'
require "#{COOKBOOKS_PATH}/azure_base/test/integration/azure_spec_utils"

#run the tests
tsts = File.expand_path("tests", File.dirname(__FILE__))
Dir.glob("#{tsts}/*.rb").each {|tst| require tst}


