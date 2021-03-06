include_recipe 'libarchive::default'
include_recipe 'python'

python_pip "setuptools" do
  action :install
end

ENV['LANG'] = 'en_US.UTF-8'
ENV['LANGUAGE'] = 'en_US.UTF-8'
ENV['LC_COLLATE'] = 'C'
ENV['LC_CTYPE'] = 'en_US.UTF-8'

execute 'update' do
	command 'yum -y update'
	action :run
end

execute 'install development tools' do
	command 'yum -y groupinstall "Development Tools"'
	action :run
end

package ['python','python-libs','mysql-devel','python-devel'] do
	action :upgrade
end

package ['akonadi'] do
	action :remove
end

service 'qpidd' do
	action [ :stop ]
end

remote_file "Download engine" do
    path "#{Chef::Config['file_cache_path']}/#{node['UCD']['engine_zip']}"
	source "https://lmbgalaxy.s3.amazonaws.com/IBM/UCD/#{node['UCD']['engine_zip']}"
	action :create
	notifies :extract, 'libarchive_file[unzip UCD engine zip]', :immediately
end

libarchive_file "unzip UCD engine zip" do
  path "#{Chef::Config['file_cache_path']}/#{node['UCD']['engine_zip']}"
  extract_to "#{Chef::Config['file_cache_path']}/UCD_ENGINE"
  action :nothing
  notifies :run, 'execute[UCD Engine Installation]', :immediately
end

execute 'UCD Engine Installation' do
  user 'root'
  cwd "#{Chef::Config['file_cache_path']}/UCD_ENGINE/ibm-ucd-patterns-install/engine-install"
  command "./install.sh -l -a http://#{node['ec2']['public_hostname']}:5000/v2.0 -i #{node['ec2']['public_hostname']} -b 0.0.0.0"
  action :nothing
end

service 'openstack-heat-engine' do
	action [ :start ]
end

service 'openstack-heat-api' do
	action [ :start ]
end

service 'openstack-heat-api-cfn' do
	action [ :start ]
end

service 'openstack-heat-api-cloudwatch' do
	action [ :start ]
end

service 'openstack-keystone' do
	action [ :start ]
end