require "json"

module Recognizer
  class Config
    def initialize(options={})
      unless options[:config_file]
        raise "Missing config file path"
      end
      if File.readable?(options[:config_file])
        config_file_contents = File.open(options[:config_file], "r").read
        begin
          @config = JSON.parse(config_file_contents, :symbolize_names => true)
        rescue JSON::ParserError => error
          raise "Config file must be valid JSON: #{error}"
        end
      else
        raise "Config file does not exist or is not readable: #{options[:config_file]}"
      end
      validate
    end

    def validate
      unless @config[:librato][:email] && @config[:librato][:api_key]
        raise "You must provide a Librato Metrics account email and API key"
      end
    end

    def read
      @config
    end
  end
end
