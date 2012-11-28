$:.push File.expand_path("../lib", __FILE__)

require "rubygems"
require "recognizer/version"

task :default => "test"

task :test  do
  require File.join(File.dirname(__FILE__), 'test', 'helper')
  Dir['test/*_tests.rb'].each do |tests|
    require File.join(File.dirname(__FILE__), tests)
  end
end

task :clean do
  system "rm -rf *.gem *.jar *.tar"
end

task :build => :clean do
  system "gem build recognizer.gemspec"
  system "warble executable jar"
  system "tar -cf recognizer-#{Recognizer::VERSION}.tar recognizer.jar"
end

task :release => :build do
  system "git tag 'v#{Recognizer::VERSION}'"
  system "git push --tags"
  system "gem push recognizer-#{Recognizer::VERSION}-java.gem"
end

