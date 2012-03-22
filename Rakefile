require 'lib/recognizer/version'

task :build do
  system "gem build recognizer.gemspec"
  system "rm recognizer.jar"
  system "warble executable jar"
end

task :release => :build do
  system "git tag 'v#{Recognizer::VERSION}'"
  system "git push --tags"
  system "gem push recognizer-#{Recognizer::VERSION}.gem"
end
