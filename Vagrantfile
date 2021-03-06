require 'yaml'

current_dir    = File.dirname(File.expand_path(__FILE__))
configs        = YAML.load_file("#{current_dir}/conf/Galaxy.yaml")

# Check for missing plugins
required_plugins = %w( vagrant-aws vagrant-berkshelf vagrant-hostmanager vagrant-omnibus vagrant-reload vagrant-share vagrant-vbguest vagrant-host-shell)
plugin_installed = false
required_plugins.each do |plugin|
  unless Vagrant.has_plugin?(plugin)
    system "vagrant plugin install #{plugin}"
    plugin_installed = true
  end
end

# If new plugins installed, restart Vagrant process
if plugin_installed === true
  exec "/usr/local/bin/vagrant #{ARGV.join' '}"
end

hosts = [
	{
		name: "ucd_server",
		ami: "ami-60a10117",
		instance_type: "t2.small",
		aws_tag: "ucd_server",
		chef_role: "ucd-server",
		environment: "prev"
	},
	{
		name: "ucd_agent",
		ami: "ami-60a10117",
		instance_type: "t2.micro",
		aws_tag: "ucd_agent",
		chef_role: "ucd-agent",
		environment: "curr"
	},
	{
		name: "appscan",
		ami: "ami-60a10117",
		instance_type: "t2.micro",
		aws_tag: "AppScan",
		chef_role: "appscan",
		environment: "curr"
	},
	{
		name: "clm_server",
		ami: "ami-2a207e5d",
		instance_type: "m3.xlarge",
		aws_tag: "clm_server",
		chef_role: "clm-server",
		environment: "curr"
	},
	{
		name: "clm_buildengine",
		ami: "ami-60a10117",
		instance_type: "t2.micro",
		aws_tag: "clm_buildengine",
		chef_role: "clm-buildengine",
		environment: "curr"
	}
]

Vagrant.configure("2") do |config|

	config.berkshelf.berksfile_path = "Berksfile"
	config.berkshelf.enabled = true
	config.hostmanager.enabled = true
	config.hostmanager.manage_host = true
	config.omnibus.chef_version = :latest
	config.vm.synced_folder '.', '/vagrant', type: "rsync", disabled: false
	
	hosts.each do |host|
	
		config.vm.define host[:name] do |node|
		
			node.vm.provider "aws" do |aws, override|
				override.vm.box					= "dummy"
				override.vm.box_url				= "https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box"
			
				aws.access_key_id				= ENV['AWS_ACCESS_KEY']
				aws.secret_access_key			= ENV['AWS_SECRET_KEY']
				aws.keypair_name				= "id_rsa"  
				aws.region						= "eu-west-1"
    			aws.ami							= host[:ami]
   				aws.instance_type				= host[:instance_type]
    			aws.security_groups				= [ 'sg-66dc4703' ]
    			aws.subnet_id					= "subnet-7cf03b25"
    			aws.elastic_ip					= "true"
				aws.block_device_mapping = [
					{
						'DeviceName' => '/dev/sda1',
						'Ebs.VolumeSize' => 100,
						'Ebs.DeleteOnTermination' => true
					}
				]
    			override.ssh.username			= "ubuntu"
    			override.ssh.insert_key			= "true"
    			override.ssh.private_key_path	= "/Users/liora/.ssh/id_rsa.pem"   		
    			aws.tags = {
    		    		'Name' => host[:aws_tag]
    			}
    		end
		
			node.vm.provision :shell, :path => "scripts/bootstrap.sh"
    	
 			node.vm.provision :chef_zero do |chef|    
				chef.environments_path = ["./environments/"]
				chef.environment = host[:environment]
				chef.cookbooks_path = ["./cookbooks/"]
				chef.roles_path = ["./roles/"]
				chef.add_role host[:chef_role]
			end
		end
	end
end