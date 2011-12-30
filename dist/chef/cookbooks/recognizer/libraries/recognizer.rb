module Recognizer
  def self.generate_config(node)
    config = {:version => node.recognizer.version}
    config.merge!(:librato => node.recognizer.librato.to_hash)
    config.merge!(:amqp => node.recognizer.amqp.to_hash.reject { |key, value| %w[use_ssl].include? key })
    JSON.pretty_generate(config)
  end

  def self.find_bin
    bin_path = "/usr/bin/recognizer"
    ENV['PATH'].split(':').each do |path|
      test_path = File.join(path, "recognizer")
      if File.exists?(test_path)
        bin_path = test_path
      end
    end
    bin_path
  end
end
