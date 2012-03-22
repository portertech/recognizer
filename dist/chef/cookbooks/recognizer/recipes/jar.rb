#
# Cookbook Name:: recognizer
# Recipe:: jar
#
# Copyright 2011, Sean Porter
#
# All rights reserved - Do Not Redistribute
#

include_recipe "java::default"

directory node.recognizer.jar.directory do
  recursive true
end

version_file = File.join(node.recognizer.jar.directory, "VERSION")

remote_file File.join(node.recognizer.jar.directory, "recognizer.jar") do
  source "https://github.com/downloads/portertech/recognizer/recognizer.jar"
  mode "0755"
  not_if { File.exists?(version_file) && File.open(version_file, "r").read.include?(node.recognizer.version) }
  notifies :run, 'execute[recognizer_deployed]', :immediate
end

file version_file do
  content node.recognizer.version
end

node.set.recognizer.service.directory = node.recognizer.jar.directory
node.set.recognizer.service.command = "java -jar #{node.recognizer.jar.directory}/recognizer.jar"
