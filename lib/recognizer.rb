require "logger"
require "recognizer/cli"
require "recognizer/config"
require "recognizer/librato"
require "recognizer/input"

inputs = File.join(File.dirname(__FILE__), "recognizer", "inputs", "*")
Dir.glob(inputs, &method(:require))

module Recognizer
  def self.run
    cli         = Recognizer::CLI.new
    config      = Recognizer::Config.new(cli.read)
    input_queue = Queue.new

    options = cli.read.merge(config.read)

    logger = Logger.new(STDOUT)

    logger.level = options[:verbose] ? Logger::DEBUG : Logger::INFO

    librato = Recognizer::Librato.new(
      :logger      => logger,
      :options     => options,
      :input_queue => input_queue
    )
    librato.run

    Recognizer::Input::Base.descendants.each do |klass|
      input = klass.new(
        :logger      => logger,
        :options     => options,
        :input_queue => input_queue
      )
      if input.enabled?
        input.run
      end
    end

    loop do
      sleep 30
    end
  end
end
