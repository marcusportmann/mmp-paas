# -*- mode: ruby -*-
# # vi: set ft=ruby :

require 'fileutils'
require 'yaml'
require 'getoptlong'


def generate_centos_boot_cloud_config(hostname, dhcp, ip, netmask, gateway, dns_server, dns_search)

centos_boot_cloud_config = """#cloud-config

hostname: '#{hostname}'

centos:
  network:
    interfaces:
      - name: private-network
        match: 'eth0,ens32,ens192,eno16780032'
        dhcp: #{dhcp}
        ip: #{ip}
        netmask: #{netmask}
    gateway: #{gateway}
    dns:
      servers:
        - #{dns_server}
      search:
        - #{dns_search}

"""

end


def generate_hosts_file(provider, servers)

  hosts = """127.0.0.1 localhost
::1 localhost
  
"""

  servers.each do |server|

        if ((not server[provider]['ip'].nil?) && (not server[provider]['ip'].empty?) && (not server[provider]['hostname'].nil?) && (not server[provider]['hostname'].empty?))

          ip = server[provider]['ip']

          if not (ip.index "/").nil?

                ip = ip[0, (ip.index "/")]

          end

          hosts += "%-15.15s" % ip
          hosts += " "
          hosts += server[provider]['hostname']

          if ((not server[provider]['fqdn'].nil?) && (not server[provider]['fqdn'].empty?))
            hosts += " "
            hosts += server[provider]['fqdn']
          end

          hosts += "\n"

    end

  end

  hosts

end


def generate_vsphere_ntp_config()

vsphere_ntp_config = """driftfile /var/lib/ntp/drift

restrict default nomodify notrap nopeer noquery

restrict 127.0.0.1
restrict ::1

server 0.asys.absa.co.za iburst

includefile /etc/ntp/crypto/pw

keys /etc/ntp/keys

disable monitor

"""

end


def generate_vsphere_proxy_config(http_proxy)

vsphere_proxy_config = """export http_proxy=#{http_proxy}
export https_proxy=#{http_proxy}

"""

end






profileName = ''
provider = ''




Vagrant.require_version ">= 1.6.0"

VAGRANTFILE_API_VERSION = '2'
VAGRANT_DEFAULT_PROVIDER = 'vmware_fusion'

if not ENV['VAGRANT_PROVIDER'].nil?
  provider = ENV['VAGRANT_PROVIDER']
end

ARGV.each_with_index do |argument, index|

  if argument and argument.include? '--provider' and argument.include? '=' and (argument.split('=')[0] == "--provider")
    provider = argument.split('=')[1]
    
    if not ENV['VAGRANT_PROVIDER'].nil?
      if not ENV['VAGRANT_PROVIDER'] == provider
        raise "The vagrant provider specified by the command-line argument --provider (%s) does not match the provider specified using the VAGRANT_PROVIDER environment variable (%s)" % [provider, ENV['VAGRANT_PROVIDER']]
      end
    end
  end  

  if argument and argument.include? '--profile' and argument.include? '=' and (argument.split('=')[0] == "--profile")
    profileName = argument.split('=')[1]
  end  

end  

puts "========> #{ARGV.length}"

puts "Using the Vagrant provider: %s" % provider

CONFIG_FILE = 'config.yml'
CONFIG_FILE_PATH = File.join(File.dirname(__FILE__), CONFIG_FILE)

if File.exist?(CONFIG_FILE_PATH)
  puts "Using the configuration file: %s" % CONFIG_FILE_PATH
else
  raise "Failed to find the configuration file (%s)" % CONFIG_FILE_PATH	
end

config_file = YAML.load_file(CONFIG_FILE_PATH)
servers = config_file['servers']

if (profileName.nil? || profileName.empty?)
  raise "Please specify the name of a profile defined in the config.yml file using the --profile=PROFILE_NAME command-line argument"
end

profiles = config_file['profiles']

profile = nil

profiles.each do |tmpProfile|
  if tmpProfile['name'] == profileName
    profile = tmpProfile
  end
end

if !profile
  raise "Failed to find the profile %s in the config.yml file" % profileName
else
  puts "Executing with profile: %s" % profileName
end


Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # Always use Vagrant's insecure key
  config.ssh.username = "vagrant"
  config.ssh.insert_key = false
  
  config.vm.synced_folder ".", "/vagrant", disabled: true

  # ------------------------------------------------------------------------------------ 
  # Build the Ansible groups using the enabled servers
  # ------------------------------------------------------------------------------------
	ansible_groups = Hash.new

	servers.each do |server|
		
		if profile['servers'].include?(server['name'])
			server['ansible_groups'].split(/\s*,\s*/).each do |ansible_group|
			
				if !ansible_groups[ansible_group]
					ansible_groups[ansible_group] = []
				end			
			
				ansible_groups[ansible_group] += [server['name']]
			end
		end	
	end

  # ------------------------------------------------------------------------------------ 
  # Save the configuration for the enabled servers in the Ansible variables
  # ------------------------------------------------------------------------------------
  ansible_vars = Hash.new
  
  ansible_vars["servers"] = Hash.new
  ansible_vars["server_names_by_group"] = Hash.new
  
	servers.each do |server|
		if profile['servers'].include?(server['name'])

      server_var = Hash.new
      
			if ((not server[provider]['hostname'].nil?) && (not server[provider]['hostname'].empty?))
        server_var['hostname'] = server[provider]['hostname']
      end
			if ((not server[provider]['fqdn'].nil?) && (not server[provider]['fqdn'].empty?))
        server_var['fqdn'] = server[provider]['fqdn']
      end
			if ((not server[provider]['ip'].nil?) && (not server[provider]['ip'].empty?))
        server_var['ip'] = server[provider]['ip']
      end
			if ((not server[provider]['network'].nil?) && (not server[provider]['network'].empty?))
        server_var['network'] = server[provider]['network']
      end
      
      ansible_vars['servers'][server['name']] = server_var

			server['ansible_groups'].split(/\s*,\s*/).each do |ansible_group|

				if !ansible_vars["server_names_by_group"][ansible_group]
					ansible_vars["server_names_by_group"][ansible_group] = []
				end			
				
				ansible_vars["server_names_by_group"][ansible_group] += [server['name']]

      end

    end
  end  
  
  # ------------------------------------------------------------------------------------ 
  # Add the variables in the config.yml file to the Ansible variables
  # ------------------------------------------------------------------------------------
  variables = config_file['variables']
  
  variables.each do |variable|
  
    if variable['values'].length == 1
      ansible_vars[variable['name']] = variable['values'][0]
    end
    
    if variable['values'].length > 1
      ansible_vars[variable['name']] = []
    
      variable['values'].each do |value|
        ansible_vars[variable['name']] += [value]
      end
    end 
  end
  
  puts "ansible_vars: %s" % ansible_vars 
	
  # ------------------------------------------------------------------------------------ 
  # Virtualbox Configuration
  # ------------------------------------------------------------------------------------
  if provider == "virtualbox"
  
    puts "Using the '%s' provider..." % provider
    
    config.vm.provider "virtualbox" do |virtualbox|
      virtualbox.gui = false
    end    
        
    servers.each do |server|
      if profile['servers'].include?(server['name'])

        puts "Provisioning server: %s" % server['name']

        config.vm.define server['name'] do |server_vm|
          server_vm.vm.provider :virtualbox do |virtualbox, override|
                    
            # NOTE: This box must have been added to Vagrant before executing this project.
            #       
            #       Clone the mmp-packer Git repository and build and add the Vagrant boxes.
            #
            override.vm.box = "mmp/centos72"
        
            override.vm.synced_folder '.', '/vagrant', disabled: true

            override.vm.hostname = server['virtualbox']['fqdn']
            
            override.vm.network "private_network", ip: server['virtualbox']['ip']

            virtualbox.customize ["modifyvm", :id, "--memory", server['virtualbox']['ram'], "--cpus", server['virtualbox']['cpus'], "--cableconnected1", "on", "--cableconnected2", "on"]
            
            # Enable swap if required
            if (not server['virtualbox']['swap'].nil?)
              override.vm.provision "shell", inline: "sudo create-swap-file /swapfile %s" % server['virtualbox']['swap']
            end
            
            # Write out the /etc/hosts file
            override.vm.provision "shell", inline: "sudo cat << EOF > /etc/hosts\n%s\nEOF" %  generate_hosts_file(provider, servers)            

						override.vm.provision "ansible" do |ansible|
		  	  		ansible.playbook = server['ansible_playbook']
		  	  		ansible.groups = ansible_groups		  	  		
		  	  		ansible.extra_vars = ansible_vars
						end     

          end
        end
      end
    end    
  end

  # ------------------------------------------------------------------------------------ 
  # VMware Fusion Configuration
  # ------------------------------------------------------------------------------------
  if provider == "vmware_fusion"
  
    puts "Using the '%s' provider..." % provider
        
    config.vm.provider "vmware_fusion" do |vmware_fusion|
      vmware_fusion.gui = true
    end
    
    servers.each do |server|
      if profile['servers'].include?(server['name']) == true
        config.vm.define server['name'] do |server_vm|
          server_vm.vm.provider :vmware_fusion do |vmware_fusion, override|
          
            # NOTE: This box must have been added to Vagrant before executing this project.
            #       
            #       Clone the mmp-packer Git repository and build and add the Vagrant boxes.
            #
            override.vm.box = "mmp/centos72"
        
            override.vm.synced_folder '.', '/vagrant', disabled: true
            
            # Perform the VMware Fusion specific initialisation     
            vmware_fusion.gui = true
            vmware_fusion.vmx["numvcpus"] = server['vmware_fusion']['cpus']        
            vmware_fusion.vmx["memsize"] = server['vmware_fusion']['ram']
            vmware_fusion.vmx["ethernet0.connectionType"] = "custom"
            vmware_fusion.vmx["ethernet0.virtualDev"] = "vmxnet3"
            vmware_fusion.vmx["ethernet0.vnet"] = "vmnet2"
            vmware_fusion.vmx["guestinfo.centos.config.data.encoding"] = "base64"
            vmware_fusion.vmx["guestinfo.centos.config.data"] = Base64.encode64(generate_centos_boot_cloud_config(server['vmware_fusion']['hostname'], server['vmware_fusion']['dhcp'], server['vmware_fusion']['ip'], server['vmware_fusion']['netmask'], server['vmware_fusion']['gateway'], server['vmware_fusion']['dns_server'], server['vmware_fusion']['dns_search'])).gsub(/\n/, '') 
            
            # Enable swap if required
            if (not server['vmware_fusion']['swap'].nil?)
              override.vm.provision "shell", inline: "sudo create-swap-file /swapfile %s" % server['virtualbox']['swap']
            end
            
            # Write out the /etc/hosts file
            override.vm.provision "shell", inline: "sudo cat << EOF > /etc/hosts\n%s\nEOF" %  generate_hosts_file(provider, servers)   
            
						override.vm.provision "ansible" do |ansible|
		  	  		ansible.playbook = server['ansible_playbook']
		  	  		ansible.groups = ansible_groups
		  	  		ansible.extra_vars = ansible_vars
						end                     
                    
          end
        end
      end
    end    
  end

  # ------------------------------------------------------------------------------------ 
  # vSphere Configuration
  # ------------------------------------------------------------------------------------
  if provider == "vsphere"
        
    puts "Using the '%s' provider..." % provider
        
    config.vm.provider "vsphere" do |vsphere|
      vsphere.user = config_file['providers']['vsphere']['user']
      vsphere.password = config_file['providers']['vsphere']['password']
      vsphere.host = config_file['providers']['vsphere']['host']
      vsphere.insecure = config_file['providers']['vsphere']['insecure']
    end

    servers.each do |server|      
      if profile['servers'].include?(server['name']) == true
        config.vm.define server['name'] do |server_vm|
          server_vm.vm.provider :vsphere do |vsphere, override|

            # NOTE: This box must have been added to Vagrant before executing this project.
            #
            #       Clone the mmp-vagrant Git repository and build and add the Vagrant boxes.
            #
            override.vm.box = "mmp/centos72" 

            override.vm.synced_folder '.', '/vagrant', disabled: true
        
            # Perform the vSphere specific initialisation     
            vsphere.data_center_name = server['vsphere']['datacenter']
            vsphere.compute_resource_name = server['vsphere']['compute_resource']
            vsphere.resource_pool_name = server['vsphere']['resource_pool_name']
            vsphere.vm_base_path = server['vsphere']['vm_base_path']
            vsphere.name = server['name']
            vsphere.template_name = server['vsphere']['template_name']
            vsphere.cpu_count = server['vsphere']['cpus']
            vsphere.memory_mb = server['vsphere']['ram']
            if not server['vsphere']['mac'].nil?
              vsphere.mac = server['vsphere']['mac']
            end
            vsphere.vlan = server['vsphere']['vlan']          
            vsphere.extra_config = {'guestinfo.centos.config.data.encoding' => 'base64', 'guestinfo.centos.config.data' => Base64.encode64(generate_centos_boot_cloud_config(server['vsphere']['hostname'], server['vsphere']['dhcp'], server['vsphere']['ip'], server['vsphere']['netmask'], server['vsphere']['gateway'], server['vsphere']['dns_server'], server['vsphere']['dns_search'])).gsub(/\n/, '') }
        
            # Enable swap if required
            if (not server['vsphere']['swap'].nil?)
              override.vm.provision "shell", inline: "sudo create-swap-file /swapfile %s" % server['virtualbox']['swap']
            end
        
            # Write out the /etc/hosts file
            override.vm.provision "shell", inline: "sudo cat << EOF > /etc/hosts\n%s\nEOF" %  generate_hosts_file(provider, servers)            

            # Setup the NTP configuration for the vSphere provider
            override.vm.provision "shell", inline: "sudo cat << EOF > /tmp/ntp.conf\n%s\nEOF" %  generate_vsphere_ntp_config()
            override.vm.provision "shell", inline: "sudo cp /tmp/ntp.conf /etc/ntp.conf"        

            # Setup the proxy configuration for the vSphere provider if required
            if ((not server['vsphere']['http_proxy'].nil?) && (not server['vsphere']['http_proxy'].empty?))
              override.vm.provision "shell", inline: "sudo cat << EOF > /tmp/proxy.sh\n%s\nEOF" %  generate_vsphere_proxy_config(server['vsphere']['http_proxy'])
              override.vm.provision "shell", inline: "sudo cp /tmp/proxy.sh /etc/profile.d/proxy.sh"        
              override.vm.provision "shell", inline: "sudo chmod a+x /etc/profile.d/proxy.sh"        
            end
        
						override.vm.provision "ansible" do |ansible|
		  	  		ansible.playbook = server['ansible_playbook']
  	  	  		ansible.groups = ansible_groups
		  	  		ansible.extra_vars = ansible_vars
						end                     
        
          end
        end
      end
    end
  end
end  

