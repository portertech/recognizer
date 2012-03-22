#
# Cookbook Name:: recognizer
# Recipe:: bundler
#
# Copyright 2011, Sean Porter
#
# All rights reserved - Do Not Redistribute
#

include_recipe "git::default"

gem_package "bundler"

directory File.join(node.recognizer.bundler.directory, "shared/vendor") do
  recursive true
end

execute "bundle" do
  command "bundle install --path vendor --without development"
  cwd File.join(node.recognizer.bundler.directory, "current")
  action :nothing
  notifies :run, 'execute[recognizer_deployed]', :immediate
end

deploy_revision "recognizer" do
  deploy_to node.recognizer.bundler.directory
  repository "git://github.com/portertech/recognizer.git"
  revision "v#{node.recognizer.version}"
  purge_before_symlink Array.new
  create_dirs_before_symlink Array.new
  symlink_before_migrate Hash.new
  symlinks ({"vendor" => "vendor"})
  action File.exists?(File.join(node.recognizer.bundler.directory, "current")) ? :deploy : :force_deploy
  notifies :run, 'execute[bundle]', :immediate
end

node.set.recognizer.service.directory = File.join(node.recognizer.bundler.directory, "current")
node.set.recognizer.service.command = File.join(node.recognizer.bundler.directory, "current", "bin", "recognizer")
