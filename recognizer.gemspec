$:.push File.expand_path("../lib", __FILE__)
require "recognizer/version"

Gem::Specification.new do |s|
  s.name        = "recognizer"
  s.version     = Recognizer::VERSION
  s.platform    = "java"
  s.authors     = ["Sean Porter"]
  s.email       = ["portertech@gmail.com"]
  s.homepage    = "https://github.com/portertech/recognizer"
  s.summary     = "A Graphite Carbon impostor, sending metrics to Librato Metrics."
  s.description = "A drop-in replacement for Graphite Carbon (TCP & AMQP), sending metrics to Librato Metrics."

  s.rubyforge_project = "recognizer"

  s.files         = Dir.glob("{bin,lib}/**/*") + %w[recognizer.gemspec README.org MIT-LICENSE.txt]
  s.executables   = Dir.glob("bin/**/*").map { |file| File.basename(file) }
  s.require_paths = ["lib"]

  s.add_dependency("json")
  s.add_dependency("jruby-openssl", "0.7.7")
  s.add_dependency("mixlib-cli", "1.2.2")
  s.add_dependency("hot_bunnies", "1.4.0")
  s.add_dependency("librato-metrics", "1.0.3")
end
