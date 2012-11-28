require "mixlib/cli"

module Recognizer
  class CLI
    include Mixlib::CLI

    option :config_file,
      :short => "-c CONFIG",
      :long  => "--config CONFIG",
      :description => "The config file path"

    option :verbose,
      :short => "-v",
      :long  => "--verbose",
      :description => "Enable verbose logging",
      :boolean => true,
      :default => false

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
