COOKBOOKS_PATH ||= "/opt/oneops/inductor/circuit-oneops-1/components/cookbooks"

require 'fog/azurerm'
require "#{COOKBOOKS_PATH}/azure_lb/libraries/load_balancer.rb"
require "#{COOKBOOKS_PATH}/azure_base/libraries/utils.rb"

describe 'delete azure lb' do
  before(:each) do
    @spec_utils = AzureSpecUtils.new($node)
  end

  it 'should not exist' do
    lb_svc = AzureNetwork::LoadBalancer.new(@spec_utils.get_azure_creds)
    load_balancer = lb_svc.get(@spec_utils.get_resource_group_name, @spec_utils.get_lb_name)

    expect(load_balancer).to be_nil
  end
end
