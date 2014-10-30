chef_gem 'systemd-journal'

begin
  require 'systemd/journal'
rescue LoadError => e
  Chef::Application.fatal!("Could not load systemd-journal despite call to chef_gem. Installation failure?")
end

node.default['chef_client']['handler']['journald']['fail_priority'] =
  Systemd::Journal::LOG_ERR

node.default['chef_client']['handler']['journald']['success_priority'] =
 Systemd::Journal::LOG_INFO

include_recipe 'chef_handler'

cookbook_file "#{Chef::Config[:file_cache_path]}/chef-handler-journald.rb" do
  source 'chef-handler-journald.rb'
  mode 0600
end.run_action(:create)

chef_handler 'JournaldHandler' do
  source "#{Chef::Config[:file_cache_path]}/chef-handler-journald.rb"
  arguments [
              :syslog_identifier => node['chef_client']['handler']['journald']['syslog_identifier'],
              :fail_priority     => node['chef_client']['handler']['journald']['fail_priority'],
              :success_priority  => node['chef_client']['handler']['journald']['success_priority'],
              :log_success       => node['chef_client']['handler']['journald']['log_success'],
            ]
  supports :report => true, :exception => true
  action :nothing
end.run_action(:enable)
