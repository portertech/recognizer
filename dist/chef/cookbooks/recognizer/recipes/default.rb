#
# Cookbook Name:: recognizer
# Recipe:: default
#
# Copyright 2011, Sean Porter
#
# All rights reserved - Do Not Redistribute
#

execute "recognizer_deployed" do
  command "true"
  action :nothing
end

case node.recognizer.installation
when "jar"
  include_recipe "recognizer::jar"
when "bundler"
  include_recipe "recognizer::bundler"
end

directory node.recognizer.directory do
  recursive true
end

if node.recognizer.amqp.use_ssl
  node.recognizer.amqp.ssl.cert_chain_file = File.join(node.recognizer.directory, "ssl", "cert.pem")
  node.recognizer.amqp.ssl.private_key_file = File.join(node.recognizer.directory, "ssl", "key.pem")

  ssl = data_bag_item("recognizer", "ssl")

  directory File.join(node.recognizer.directory, "ssl")

  file node.recognizer.amqp.ssl.cert_chain_file do
    content ssl["cert"]
    mode 0644
  end

  file node.recognizer.amqp.ssl.private_key_file do
    content ssl["key"]
    mode 0644
  end
end

user node.recognizer.user do
  comment "metrics user"
  system true
  home node.recognizer.directory
end

directory "/var/log/recognizer" do
  owner node.recognizer.user
  mode 0755
end

file File.join(node.recognizer.directory, "config.json") do
  content Recognizer.generate_config(node)
  mode 0644
end

case node[:platform]
when "ubuntu", "debian"
  template "/etc/init/recognizer.conf" do
    source "upstart.erb"
    variables(
      :directory => node.recognizer.service.directory,
      :command => node.recognizer.service.command,
      :options => "-c #{node.recognizer.directory}/config.json"
    )
    mode 0644
  end

  service "recognizer" do
    provider Chef::Provider::Service::Upstart
    action [:enable, :start]
    subscribes :restart, resources(:file => File.join(node.recognizer.directory, "config.json"), :execute => "recognizer_deployed"), :delayed
  end
end
