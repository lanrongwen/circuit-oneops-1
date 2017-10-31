=begin

to run the below tests configure lb in oneops with following listeners and ecvs. so the workorder will have these entries

listeners
  http 80 http 8080
  http 8081 http 8081
  tcp 8082 tcp 8082
  tcp 8083 tcp 8083
  https 8084 https 8084
  https 8085 https 8085

ecv
  8080 GET /
  8082 GET /
  8084 GET /
  8086 GET /
  8087 GET /
  8088 GET /

=end

COOKBOOKS_PATH ||= "/opt/oneops/inductor/circuit-oneops-1/components/cookbooks"

require 'fog/azurerm'
require "#{COOKBOOKS_PATH}/azure_lb/libraries/load_balancer.rb"
require "#{COOKBOOKS_PATH}/azure_base/libraries/utils.rb"

describe 'azure lb' do
  before(:each) do
    @spec_utils = AzureSpecUtils.new($node)
  end

  it 'should exist' do
    lb_svc = AzureNetwork::LoadBalancer.new(@spec_utils.get_azure_creds)
    load_balancer = lb_svc.get(@spec_utils.get_resource_group_name, @spec_utils.get_lb_name)

    expect(load_balancer).not_to be_nil
    expect(load_balancer.name).to eq(@spec_utils.get_lb_name)
  end

  it "has oneops org and assembly tags" do
    tags_from_work_order = Utils.get_resource_tags($node)

    lb_svc = AzureNetwork::LoadBalancer.new(@spec_utils.get_azure_creds)
    load_balancer = lb_svc.get(@spec_utils.get_resource_group_name, @spec_utils.get_lb_name)

    tags_from_work_order.each do |key, value|
      expect(load_balancer.tags).to include(key => value)
    end
  end

  context 'probes' do
    it 'are created using ecvs on lb component. probe protocol is set to backend protocol of a matching listener' do
      lb_svc = AzureNetwork::LoadBalancer.new(@spec_utils.get_azure_creds)
      load_balancer = lb_svc.get(@spec_utils.get_resource_group_name, @spec_utils.get_lb_name)

      probe8080 = load_balancer.probes.detect {|p| p.port == 8080}
      expect(probe8080.protocol).to eq('Http')
      expect(probe8080.request_path).to eq('/')

      probe8082 = load_balancer.probes.detect.detect {|p| p.port == 8082}
      expect(probe8082.protocol).to eq('Tcp')
      expect(probe8082.request_path).to be_nil

      probe8084 = load_balancer.probes.detect.detect {|p| p.port == 8084}
      expect(probe8084.protocol).to eq('Tcp')
      expect(probe8084.request_path).to be_nil
    end
  end


  it 'uses a matching probe for a listener. matching probe = probe that has same port as backendport of listener' do
    lb_svc = AzureNetwork::LoadBalancer.new(@spec_utils.get_azure_creds)
    load_balancer = lb_svc.get(@spec_utils.get_resource_group_name, @spec_utils.get_lb_name)

    #for http listener with backendport 8080
    lb_rule_8080 = load_balancer.load_balancing_rules.detect {|lb_rule| lb_rule.backend_port == 8080}
    lb_rule_8080_probe_name = Hash[*(lb_rule_8080.probe_id.split('/'))[1..-1]]['probes']
    lb_rule_8080_probe = load_balancer.probes.detect {|p| p.name == lb_rule_8080_probe_name}

    expect(lb_rule_8080_probe.protocol).to eq('Http')
    expect(lb_rule_8080_probe.port).to eq(8080)

    #for tcp listener with backendport 8082
    lb_rule_8082 = load_balancer.load_balancing_rules.detect {|lb_rule| lb_rule.backend_port == 8082}
    lb_rule_8082_probe_name = Hash[*(lb_rule_8082.probe_id.split('/'))[1..-1]]['probes']
    lb_rule_8082_probe = load_balancer.probes.detect {|p| p.name == lb_rule_8082_probe_name}

    expect(lb_rule_8082_probe.protocol).to eq('Tcp')
    expect(lb_rule_8082_probe.port).to eq(8082)
    expect(lb_rule_8082_probe.request_path).to be_nil

    #for https listener with backendport 8084
    lb_rule_8084 = load_balancer.load_balancing_rules.detect {|lb_rule| lb_rule.backend_port == 8084}
    lb_rule_8084_probe_name = Hash[*(lb_rule_8084.probe_id.split('/'))[1..-1]]['probes']
    lb_rule_8084_probe = load_balancer.probes.detect {|p| p.name == lb_rule_8084_probe_name}

    expect(lb_rule_8084_probe.protocol).to eq('Tcp')
    expect(lb_rule_8084_probe.port).to eq(8084)
    expect(lb_rule_8084_probe.request_path).to be_nil

  end

  context 'for http listener' do
    it 'uses any user specified http probe if a matching probe is not found' do
      lb_svc = AzureNetwork::LoadBalancer.new(@spec_utils.get_azure_creds)
      load_balancer = lb_svc.get(@spec_utils.get_resource_group_name, @spec_utils.get_lb_name)

      lb_rule_8080 = load_balancer.load_balancing_rules.detect {|lb_rule| lb_rule.backend_port == 8080}
      lb_rule_8080_probe_name = Hash[*(lb_rule_8080.probe_id.split('/'))[1..-1]]['probes']

      #for http listener with backendport 8081
      lb_rule_8081 = load_balancer.load_balancing_rules.detect {|lb_rule| lb_rule.backend_port == 8081}
      lb_rule_8081_probe_name = Hash[*(lb_rule_8081.probe_id.split('/'))[1..-1]]['probes']
      lb_rule_8081_probe = load_balancer.probes.detect {|p| p.name == lb_rule_8081_probe_name}

      expect(lb_rule_8081_probe_name).to eq(lb_rule_8080_probe_name)
      expect(lb_rule_8081_probe.protocol).to eq('Http')
      expect(lb_rule_8081_probe.port).to eq(8080)

    end
  end

  context 'for tcp listener' do
    it 'creates a new tcp probe when no matching probe is found' do

      lb_svc = AzureNetwork::LoadBalancer.new(@spec_utils.get_azure_creds)
      load_balancer = lb_svc.get(@spec_utils.get_resource_group_name, @spec_utils.get_lb_name)

      #for tcp listener with backendport 8082
      lb_rule_8083 = load_balancer.load_balancing_rules.detect {|lb_rule| lb_rule.backend_port == 8083}
      lb_rule_8083_probe_name = Hash[*(lb_rule_8083.probe_id.split('/'))[1..-1]]['probes']
      lb_rule_8083_probe = load_balancer.probes.detect {|p| p.name == lb_rule_8083_probe_name}

      expect(lb_rule_8083_probe.protocol).to eq('Tcp')
      expect(lb_rule_8083_probe.port).to eq(8083)
      expect(lb_rule_8083_probe.request_path).to be_nil
    end
  end

  context 'for https listener' do
    it 'a tcp probe is used' do
      lb_svc = AzureNetwork::LoadBalancer.new(@spec_utils.get_azure_creds)
      load_balancer = lb_svc.get(@spec_utils.get_resource_group_name, @spec_utils.get_lb_name)

      #for https listener with backendport 8084
      lb_rule_8084 = load_balancer.load_balancing_rules.detect {|lb_rule| lb_rule.backend_port == 8084}
      lb_rule_8084_probe_name = Hash[*(lb_rule_8084.probe_id.split('/'))[1..-1]]['probes']
      lb_rule_8084_probe = load_balancer.probes.detect {|p| p.name == lb_rule_8084_probe_name}

      expect(lb_rule_8084_probe.protocol).to eq('Tcp')
      expect(lb_rule_8084_probe.port).to eq(8084)
      expect(lb_rule_8084_probe.request_path).to be_nil
    end

    it 'creates a new tcp probe when no matching probe is found' do
      lb_svc = AzureNetwork::LoadBalancer.new(@spec_utils.get_azure_creds)
      load_balancer = lb_svc.get(@spec_utils.get_resource_group_name, @spec_utils.get_lb_name)

      #for https listener with backendport 8085
      lb_rule_8085 = load_balancer.load_balancing_rules.detect {|lb_rule| lb_rule.backend_port == 8085}
      lb_rule_8085_probe_name = Hash[*(lb_rule_8085.probe_id.split('/'))[1..-1]]['probes']
      lb_rule_8085_probe = load_balancer.probes.detect {|p| p.name == lb_rule_8085_probe_name}

      expect(lb_rule_8085_probe.protocol).to eq('Tcp')
      expect(lb_rule_8085_probe.port).to eq(8085)
      expect(lb_rule_8085_probe.request_path).to be_nil
    end
  end
end