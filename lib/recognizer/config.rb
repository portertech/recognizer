require "rubygems"
require "json"

module Recognizer
  class Config
    def initialize(options={})
      unless options[:config_file]
        raise "Missing config file path"
      end
      if File.readable?(options[:config_file])
        config_file_contents = File.open(options[:config_file], 'r').read
        config = JSON.parse(config_file_contents)
      else
        raise "Config file does not exist or is not readable: #{options[:config_file]}"
      end
      config
    end
  end
end
