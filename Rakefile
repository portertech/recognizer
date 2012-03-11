require 'lib/recognizer/version'

task :build do
  system "gem build recognizer.gemspec"
  system "rm recognizer.jar"
  system "warble executable jar"
end

task :release => :build do
  system "gem push recognizer-#{Recognizer::VERSION}"
end
