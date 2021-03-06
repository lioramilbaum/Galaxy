include_recipe "libarchive::default"
include_recipe "java7::default"

ucd_servers = search(:node, 'role:ucd_server')

if ( ucd_servers.empty? or node[:roles].include?('ucd_server') )
	node.default['UCD']['server_hostname']		= node['ec2']['public_hostname']
	node.default['UCD']['server_private_ips']	= '127.0.0.1'
else
    node.default['UCD']['server_hostname']		= ucd_servers[0].cloud.public_hostname
    node.default['UCD']['server_private_ips']	= ucd_servers[0].cloud.private_ips[0]
end

cookbook_file 'ucd_rsa.pem' do
    path '/home/ubuntu/.ssh/ucd_rsa.pem'
    action :create
    user 'ubuntu'
    mode '0400'
	not_if {node.default['UCD']['server_hostname'] == node['ec2']['public_hostname'] }
end

execute 'download agent.zip' do
  command "scp -o StrictHostKeyChecking=no -i '/home/ubuntu/.ssh/ucd_rsa.pem' ubuntu@#{node['UCD']['server_private_ips']}:/opt/ibm-ucd/server/opt/tomcat/webapps/ROOT/tools/ibm-ucd-agent.zip #{Chef::Config['file_cache_path']}"
  action :run
  creates "#{Chef::Config['file_cache_path']}/agent.zip"
  not_if {node.default['UCD']['server_hostname'] == node['ec2']['public_hostname'] }
end

remote_file "#{Chef::Config['file_cache_path']}/ibm-ucd-agent.zip" do
  source 'file:///opt/ibm-ucd/server/opt/tomcat/webapps/ROOT/tools/ibm-ucd-agent.zip'
  action :create
  only_if {node.default['UCD']['server_hostname'] == node['ec2']['public_hostname'] }
end

libarchive_file "ibm-ucd-agent.zip" do
  path "#{Chef::Config['file_cache_path']}/ibm-ucd-agent.zip"
  extract_to "#{Chef::Config['file_cache_path']}/UCD_AGENT"
  action :extract
end

template "#{Chef::Config['file_cache_path']}/agent.properties" do
	source "agent.properties.erb" 
  	variables (
		lazy {
			{
				:server_hostname => node['UCD']['server_hostname'],
				:agent_hostname => node['ec2']['public_hostname']
			}
		}
	)
  action :create
end

execute 'install-agent-from-file.sh' do
  command "#{Chef::Config['file_cache_path']}/UCD_AGENT/ibm-ucd-agent-install/install-agent-from-file.sh #{Chef::Config['file_cache_path']}/agent.properties"
  action :run
end

execute 'agent start' do
  user 'root'
  command "/opt/ibm-ucd/agent/bin/agent start"
  action :run
end

execute 'sleep' do
  command "sleep 1m"
  action :run
end

template "#{Chef::Config['file_cache_path']}/agent.json" do
	source "agent.json.erb" 
  	variables (
		lazy {
			{
				:agent_hostname => node['ec2']['public_hostname']
			}
		}
	)
	action :create
	notifies :run, 'execute[Configure Agent]', :immediately
	only_if {node.default['UCD']['server_hostname'] == node['ec2']['public_hostname'] }
end

execute 'Configure Agent' do
  command "curl -s -X PUT -u admin:admin  -d @#{Chef::Config['file_cache_path']}/agent.json https://#{node['UCD']['server_hostname']}:8443/cli/systemConfiguration --insecure"
  action :nothing
  only_if {node.default['UCD']['server_hostname'] == node['ec2']['public_hostname'] }
end

execute 'Configure1 Agent' do
  command "curl -s -X PUT -u admin:admin https://#{node['UCD']['server_hostname']}:8443/cli/teamsecurity/tokens?user=admin&expireDate=12-31-2020-00:24"
  action :run
  only_if {node.default['UCD']['server_hostname'] == node['ec2']['public_hostname'] }
end