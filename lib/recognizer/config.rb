require "rubygems"
require "json"

require File.join(File.dirname(__FILE__), "patches", "hash")

module Recognizer
  class Config
    def initialize(options={})
      unless options[:config_file]
        raise "Missing config file path"
      end
      if File.readable?(options[:config_file])
        config_file_contents = File.open(options[:config_file], "r").read
        begin
          @config = JSON.parse(config_file_contents)
        rescue JSON::ParserError => error
          raise "Config file must be valid JSON: #{error}"
        end
      else
        raise "Config file does not exist or is not readable: #{options[:config_file]}"
      end
    end

    def read
      @config.symbolize_keys
    end
  end
end
