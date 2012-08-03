$:.push File.expand_path("../lib", __FILE__)

require "rubygems"
require "recognizer/version"

task :default => "test"

task :test  do
  require File.join(File.dirname(__FILE__), 'test', 'helper')
  Dir['test/*_test.rb'].each do |test|
    require File.join(File.dirname(__FILE__), test)
  end
end

task :build do
  system "gem build recognizer.gemspec"
  File.delete("recognizer.jar")
  system "warble executable jar"
end

task :release => :build do
  system "git tag 'v#{Recognizer::VERSION}'"
  system "git push --tags"
  system "gem push recognizer-#{Recognizer::VERSION}.gem"
end
