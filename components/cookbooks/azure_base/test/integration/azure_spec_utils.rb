class AzureSpecUtils
  def initialize(node)
    @node = node
  end

  def get_app_type
    @node['app_name']
  end
  def get_cloud_name
    cloud_name = @node['workorder']['cloud']['ciName']
    cloud_name
  end
  def get_rfc_ci
    rfcCi = @node['workorder']['rfcCi']
    rfcCi
  end
  def get_ns_path_parts
    rfcCi = get_rfc_ci
    nsPathParts = rfcCi['nsPath'].split("/")
    nsPathParts
  end
  def get_service
    cloud_name = get_cloud_name
    app_type = get_app_type
    svc = case app_type
            when 'lb'
              @node['workorder']['services']['lb'][cloud_name]['ciAttributes']
            when 'fqdn'
              @node['workorder']['services']['dns'][cloud_name]['ciAttributes']
            when 'storage'
              @node['workorder']['services']['storage'][cloud_name]['ciAttributes']
            else
              @node['workorder']['services']['compute'][cloud_name]['ciAttributes']
          end
  end
  def get_resource_group_name
    nsPathParts = get_ns_path_parts
    org = nsPathParts[1]
    assembly = nsPathParts[2]
    environment = nsPathParts[3]

    svc = get_service
    location = svc['location']

    resource_group_name = org[0..15] + '-' + assembly[0..15] + '-' + @node['workorder']['box']['ciId'].to_s + '-' + environment[0..15] + '-' + Utils.abbreviate_location(location)
    resource_group_name
  end
  def get_azure_creds
    cloud_name = get_cloud_name
    app_type = get_app_type
    svc = get_service

    credentials = {
        tenant_id: svc['tenant_id'],
        client_secret: svc['client_secret'],
        client_id: svc['client_id'],
        subscription_id: svc['subscription']
    }

    credentials
  end
  def get_image_id
    #image_id is a calculated attributed. This is calculated in Compute::node_lookup recipe
    os = nil
    ostype = "default-cloud"

    cloud_name = get_cloud_name
    cloud = @node['workorder']['services']['compute'][cloud_name]['ciAttributes']
    rfcCi = get_rfc_ci

    if @node['workorder']['payLoad'].has_key?("os")
      os = @node['workorder']['payLoad']['os'].first
      ostype = os['ciAttributes']['ostype']
    else
      if ostype == "default-cloud"
        ostype = cloud['ostype']
      end
    end

    sizemap = JSON.parse( cloud['sizemap'] )
    imagemap = JSON.parse( cloud['imagemap'] )
    size_id = sizemap[rfcCi["ciAttributes"]["size"]]

    image_id = ''
    if !os.nil? && os['ciAttributes'].has_key?("image_id") && !os['ciAttributes']['image_id'].empty?
      image_id = os['ciAttributes']['image_id']
    else
      image_id = imagemap[ostype]
    end

    image_id
  end
  def set_attributes_on_node_required_for_vm_manager
    @node['image_id'] = get_image_id
    @node['platform-resource-group'] = get_resource_group_name
  end
  def is_express_route_enabled
    set_attributes_on_node_required_for_vm_manager
    vm_manager = AzureCompute::VirtualMachineManager.new(@node)
    express_route_enabled = vm_manager.compute_service['express_route_enabled']

    if(express_route_enabled == "true")
      return true
    else
      false
    end
  end

  def get_server_name
    rfcCi = get_rfc_ci
    nsPathParts = get_ns_path_parts


    server_name = @node['workorder']['box']['ciName']+'-'+nsPathParts[3]+'-'+nsPathParts[2]+'-'+nsPathParts[1]+'-'+ rfcCi["ciId"].to_s
    if(server_name.size > 63)
      server_name = server_name.slice(0,63-(rfcCi["ciId"].to_s.size)-1)+'-'+ rfcCi["ciId"].to_s
    end

    server_name
  end
  def get_lb_name
    platform_name = @node['workorder']['box']['ciName']
    plat_name = platform_name.gsub(/-/, '').downcase
    lb_name = "lb-#{plat_name}"

    lb_name
  end
  def get_azure_rule_definition(resource_group_name, network_security_group_name, rules, node)
    sec_rules = []
    priority = 100
    reg_ex = /(\d+|\*|\d+-\d+)\s(\d+|\*|\d+-\d+)\s([A-Za-z]+|\*)\s\S+/
    rules.each do |item|
      raise "#{item} is not a valid security rule" unless reg_ex.match(item)
      item2 = item.split(' ')
      security_rule_access = Fog::ARM::Network::Models::SecurityRuleAccess::Allow
      security_rule_description = node['secgroup']['description']
      security_rule_source_addres_prefix = item2[3]
      security_rule_destination_port_range = item2[1].to_s
      security_rule_direction = Fog::ARM::Network::Models::SecurityRuleDirection::Inbound
      security_rule_priority = priority
      security_rule_protocol = case item2[2].downcase
        when 'tcp'
          Fog::ARM::Network::Models::SecurityRuleProtocol::Tcp
        when 'udp'
          Fog::ARM::Network::Models::SecurityRuleProtocol::Udp
        else
          Fog::ARM::Network::Models::SecurityRuleProtocol::Asterisk
        end
      security_rule_provisioning_state = nil
      security_rule_destination_addres_prefix = '*'
      security_rule_source_port_range = '*'
      security_rule_name = network_security_group_name + '-' + priority.to_s
      sec_rules << { name: security_rule_name, resource_group: resource_group_name, protocol: security_rule_protocol, network_security_group_name: network_security_group_name, source_port_range: security_rule_source_port_range, destination_port_range: security_rule_destination_port_range, source_address_prefix: security_rule_source_addres_prefix, destination_address_prefix: security_rule_destination_addres_prefix, access: security_rule_access, priority: security_rule_priority, direction: security_rule_direction }
      priority += 100
      end
    sec_rules
  end
end