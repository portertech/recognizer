require "rubygems"
require "mixlib/cli"

module Recognizer
  class CLI
    include Mixlib::CLI

    option :config_file,
      :short => "-c CONFIG",
      :long  => "--config CONFIG",
      :default => File.join(File.dirname(__FILE__), "..", "..", "config.json"),
      :description => "The config file path"

    option :help,
      :short => "-h",
      :long => "--help",
      :description => "Show this message",
      :on => :tail,
      :boolean => true,
      :show_options => true,
      :exit => 0

    def read
      parse_options
      config
    end
  end
end
